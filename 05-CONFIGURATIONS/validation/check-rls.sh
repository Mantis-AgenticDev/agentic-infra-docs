#!/usr/bin/env bash
#---
# metadata_version: 2.0
# sdd_compliant: true
# ai_parser_compatible: true
# purpose: "Validación de Row-Level Security / tenant_id en queries SQL (Constraint C4)"
# constraint: "C4: Multi-tenant isolation via RLS policies o WHERE tenant_id=?"
# output_format: "json + stdout + exit code para CI/CD"
# ---
# ============================================================================
# CHECK-RLS.SH v2.0.0 — PRODUCTION READY
# Fix crítico: grep con -F -- para evitar interpretación de flags en patrones SQL
# ============================================================================
set -euo pipefail

readonly VERSION="2.0.0"
readonly SCRIPT_NAME="$(basename "$0")"
readonly PROJECT_ROOT="${1:-.}"
readonly REPORT_FILE="${2:-rls-validation-report.json}"
readonly VERBOSE="${3:-0}"
readonly STRICT="${4:-0}"

declare -a FINDINGS=()
declare -i FILES_SCANNED=0
declare -i QUERIES_CHECKED=0
declare -i RLS_POLICIES_VALIDATED=0
declare -i C4_VIOLATIONS=0

# ────────────────────────────────────────────────────────────────────────────
# UTILIDADES (CORREGIDAS: grep seguro con -F --)
# ────────────────────────────────────────────────────────────────────────────
log_info() { [[ "$VERBOSE" == "1" ]] && echo "[INFO] $*" || true; }
log_warn() { echo "[WARN] $*" >&2; }
log_error() { echo "[ERROR] $*" >&2; }
log_finding() { 
  echo "[C4-FINDING] $*" >&2
  FINDINGS+=("$*")
  ((C4_VIOLATIONS++)) || true
}

# 🔍 Extraer bloques SQL de archivos Markdown
extract_sql_blocks() {
  local file="$1"
  local tmp_file
  tmp_file=$(mktemp --suffix=.sql)
  
  # Extraer contenido entre ```sql y ``` (o ```postgres, ```mysql, etc.)
  awk '
    /^```(sql|postgres|mysql|psql|sqlite)?$/ { in_block=1; next }
    /^```$/ { in_block=0; next }
    in_block { print }
  ' "$file" > "$tmp_file" 2>/dev/null || true
  
  echo "$tmp_file"
}

# 🔍 Verificar si una línea es comentario de exención C4 (CORREGIDO: grep -F --)
is_c4_exempt() {
  local line="$1"
  # Patrones de exención válidos (comentarios SQL)
  local -a exempt_patterns=(
    "-- C4_EXEMPT"
    "-- C4_BYPASS"
    "-- CROSS_TENANT_AGG"
    "-- SYSTEM_MIGRATION"
    "-- C4: global table"
    "-- C4: read-only reference"
    "-- C4: aggregation layer"
    "-- C4: system config"
  )
  
  for pattern in "${exempt_patterns[@]}"; do
    # 🔐 CORRECCIÓN CRÍTICA: grep -F para fixed string, -- para end of options
    if echo "$line" | grep -F -q -- "$pattern" 2>/dev/null; then
      return 0
    fi
  done
  return 1
}

# 🔍 Verificar si query tiene filtro tenant_id
has_tenant_filter() {
  local query="$1"
  
  # Patrones válidos de filtrado multi-tenant
  local -a valid_patterns=(
    "WHERE.*tenant_id"
    "WHERE.*tenantId"
    "AND.*tenant_id"
    "AND.*tenantId"
    "JOIN.*ON.*tenant_id"
    "RLS.*POLICY.*tenant"
    "ALTER TABLE.*ENABLE ROW LEVEL SECURITY"
    "CREATE POLICY.*USING.*tenant_id"
  )
  
  for pattern in "${valid_patterns[@]}"; do
    if echo "$query" | grep -qiE -- "$pattern" 2>/dev/null; then
      return 0
    fi
  done
  return 1
}

# 🔍 Verificar si tabla tiene RLS activado (Postgres)
has_rls_policy() {
  local sql_block="$1"
  local table_name="$2"
  
  # Buscar ENABLE ROW LEVEL SECURITY o CREATE POLICY para esta tabla
  if echo "$sql_block" | grep -qiE -- "(ALTER TABLE ${table_name}.*ENABLE ROW LEVEL SECURITY|CREATE POLICY.*ON ${table_name}.*USING.*tenant)" 2>/dev/null; then
    return 0
  fi
  return 1
}

# ────────────────────────────────────────────────────────────────────────────
# MOTOR DE VALIDACIÓN C4
# ────────────────────────────────────────────────────────────────────────────
validate_sql_file() {
  local file="$1"
  local sql_file
  sql_file=$(extract_sql_blocks "$file")
  
  [[ ! -s "$sql_file" ]] && { rm -f "$sql_file"; return 0; }
  
  ((FILES_SCANNED++)) || true
  log_info "Validando RLS/C4 en: $file (SQL extraído: $sql_file)"
  
  local line_num=0
  local in_ddl=false
  local current_table=""
  
  while IFS= read -r line || [[ -n "$line" ]]; do
    ((line_num++)) || true
    
    # Saltar líneas vacías o comentarios puros
    [[ -z "${line// }" || "$line" =~ ^[[:space:]]*-- ]] && continue
    
    # 🔐 Verificar exenciones C4 (CORREGIDO: grep seguro)
    if is_c4_exempt "$line"; then
      log_info "Línea $line_num: exención C4 detectada, saltando validación"
      continue
    fi
    
    # Detectar CREATE TABLE para tracking de RLS
    if echo "$line" | grep -qiE -- '^CREATE TABLE[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)' 2>/dev/null; then
      current_table=$(echo "$line" | grep -oiE -- 'CREATE TABLE[[:space:]]+\K[a-zA-Z_][a-zA-Z0-9_]*' | head -1)
      in_ddl=true
      continue
    fi
    
    # Si estamos en DDL, verificar RLS al cerrar la tabla
    if [[ "$in_ddl" == "true" && "$line" == *");" ]]; then
      if [[ -n "$current_table" ]]; then
        if ! has_rls_policy "$(cat "$sql_file")" "$current_table"; then
          log_finding "Tabla sin RLS activado: $current_table en $sql_file"
        else
          ((RLS_POLICIES_VALIDATED++)) || true
        fi
        current_table=""
      fi
      in_ddl=false
      continue
    fi
    
    # Validar queries DML (SELECT, INSERT, UPDATE, DELETE)
    if echo "$line" | grep -qiE -- '^(SELECT|INSERT|UPDATE|DELETE)[[:space:]]' 2>/dev/null; then
      ((QUERIES_CHECKED++)) || true
      
      if ! has_tenant_filter "$line"; then
        log_finding "Consulta DML sin filtro tenant_id (línea ~$line_num): $sql_file"
      fi
    fi
    
  done < "$sql_file"
  
  rm -f "$sql_file"
}

# ────────────────────────────────────────────────────────────────────────────
# GENERACIÓN DE REPORTE JSON SEGURO
# ────────────────────────────────────────────────────────────────────────────
generate_report() {
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  local status="passed"
  if [[ $C4_VIOLATIONS -gt 0 ]]; then
    status="failed"
    [[ "$STRICT" != "1" ]] && status="warnings"
  fi
  
  # Construir array de findings (seguro)
  local findings_json="[]"
  if [[ ${#FINDINGS[@]} -gt 0 ]]; then
    if command -v jq &>/dev/null; then
      findings_json=$(printf '%s\n' "${FINDINGS[@]}" | jq -R -s -c 'split("\n") | map(select(length > 0))' 2>/dev/null || echo "[]")
    else
      findings_json="["
      local first=true
      for f in "${FINDINGS[@]}"; do
        local escaped
        escaped=$(echo "$f" | sed 's/"/\\"/g')
        if [[ "$first" == "true" ]]; then
          findings_json+="\"$escaped\""
          first=false
        else
          findings_json+=",\"$escaped\""
        fi
      done
      findings_json+="]"
    fi
  fi
  
  # Calcular checksum
  local temp_report
  temp_report=$(mktemp)
  
  cat > "$temp_report" << EOF
{
  "validator_version": "$VERSION",
  "timestamp": "$timestamp",
  "target": "$PROJECT_ROOT",
  "constraint": "C4",
  "status": "$status",
  "summary": {
    "files_scanned": $FILES_SCANNED,
    "queries_checked": $QUERIES_CHECKED,
    "rls_policies_validated": $RLS_POLICIES_VALIDATED,
    "c4_violations": $C4_VIOLATIONS
  },
  "findings": $findings_json,
  "recommendations": [
    "Añadir WHERE tenant_id=? a todas las queries DML multi-tenant",
    "Activar RLS con ALTER TABLE ... ENABLE ROW LEVEL SECURITY en Postgres",
    "Documentar exenciones C4 con -- C4_EXEMPT cuando aplique",
    "Usar políticas RLS granulares: CREATE POLICY ... USING (tenant_id = current_setting('app.current_tenant'))"
  ],
  "audit": {
    "script_sha256": "$(sha256sum "$0" 2>/dev/null | awk '{print $1}' || echo 'unknown')",
    "report_sha256": "PLACEHOLDER"
  }
}
EOF

  local report_sha
  report_sha=$(sha256sum "$temp_report" 2>/dev/null | awk '{print $1}' || echo 'unknown')
  sed -i "s/\"report_sha256\": \"PLACEHOLDER\"/\"report_sha256\": \"$report_sha\"/" "$temp_report"
  
  mv "$temp_report" "$REPORT_FILE"
  
  # Output en stdout
  echo ""
  echo "========================================="
  echo "🛡️  VALIDACIÓN RLS / C4 v$VERSION"
  echo "========================================="
  echo "Target: $PROJECT_ROOT"
  echo "Archivos escaneados: $FILES_SCANNED"
  echo "Consultas verificadas: $QUERIES_CHECKED"
  echo "Políticas RLS validadas: $RLS_POLICIES_VALIDATED"
  echo "🔴 Violaciones C4: $C4_VIOLATIONS"
  echo "Estado: $status"
  echo "🔐 Report SHA256: $report_sha"
  echo "📄 Reporte: $REPORT_FILE"
  echo "========================================="
  
  if [[ ${#FINDINGS[@]} -gt 0 ]]; then
    echo ""
    echo "⚠️  Requiere corrección antes de merge:"
    for finding in "${FINDINGS[@]}"; do
      echo "  • $finding"
    done
  fi
  
  # Código de salida para CI/CD
  if [[ "$status" == "failed" ]]; then
    exit 1
  elif [[ "$status" == "warnings" && "$STRICT" == "1" ]]; then
    exit 1
  fi
  exit 0
}

# ────────────────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────────────────
main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    cat << EOF
Uso: $0 [archivo|directorio] [reporte.json] [verbose:0/1] [strict:0/1]

Validación de Row-Level Security / tenant_id (Constraint C4) para MANTIS AGENTIC.
Detecta queries SQL sin filtro multi-tenant y tablas sin políticas RLS.

Parámetros:
  archivo|dir       Archivo .md con SQL o directorio a escanear (default: .)
  reporte.json      Archivo de salida JSON (default: rls-validation-report.json)
  verbose:0/1       Modo detallado (default: 0)
  strict:0/1        Tratar warnings como errores en CI/CD (default: 0)

Exenciones C4 válidas (comentarios SQL):
  -- C4_EXEMPT              # Tabla global/no multi-tenant
  -- C4_BYPASS              # Query de sistema/admin
  -- CROSS_TENANT_AGG       # Agregación cross-tenant documentada
  -- SYSTEM_MIGRATION       # Script de migración temporal

Ejemplos:
  $0 02-SKILLS/BASE\ DE\ DATOS-RAG/vertical-db-schemas.md
  $0 . rls-report.json 1 1
  $0 02-SKILLS/BASE\ DE\ DATOS-RAG/ --strict

Integración CI/CD:
  ./check-rls.sh 02-SKILLS/ rls-report.json 0 1 || echo "C4 violations detected"

Salida:
  - Reporte JSON con hallazgos, métricas y checksum SHA256
  - Código de salida: 0 (passed) / 1 (failed o warnings en strict mode)
EOF
    exit 0
  fi
  
  log_info "Iniciando validación RLS/C4 v$VERSION"
  
  if [[ -f "$PROJECT_ROOT" ]]; then
    validate_sql_file "$PROJECT_ROOT"
  elif [[ -d "$PROJECT_ROOT" ]]; then
    while IFS= read -r -d '' file; do
      [[ "$file" == *.md ]] && validate_sql_file "$file"
    done < <(find "$PROJECT_ROOT" -type f -name "*.md" -print0 2>/dev/null)
  else
    log_error "Ruta no encontrada: $PROJECT_ROOT"
    exit 1
  fi
  
  generate_report
}

main "$@"
