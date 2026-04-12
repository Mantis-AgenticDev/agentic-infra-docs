
#!/usr/bin/env bash
#---
# metadata_version: 1.0
# sdd_compliant: true
# ai_parser_compatible: true
# purpose: "Validación de Row-Level Security y aislamiento multi-tenant (C4)"
# scope: "02-SKILLS/BASE-DE-DATOS-RAG/, 05-CONFIGURATIONS/, scripts SQL, Prisma, n8n JSON"
# constraint: "C4: tenant_id obligatorio en todas las consultas y políticas RLS"
# output_format: "json + stdout + exit code para CI/CD"
# ---
# ============================================================================
# CHECK-RLS.SH v1.0
# Validador de aislamiento multi-tenant y políticas RLS (Constraint C4)
# Propósito: Garantizar que todas las consultas SQL, esquemas ORM, workflows
# de automatización y políticas de seguridad filtren explícitamente por tenant_id.
# Detecta fugas de datos cross-tenant y políticas RLS incompletas.
# ============================================================================
set -euo pipefail

# ────────────────────────────────────────────────────────────────────────────
# CONFIGURACIÓN GLOBAL
# ────────────────────────────────────────────────────────────────────────────
readonly VERSION="1.0.0"
readonly SCRIPT_NAME="$(basename "$0")"
readonly PROJECT_ROOT="${1:-.}"
readonly REPORT_FILE="${2:-rls-validation-report.json}"
readonly VERBOSE="${3:-0}"
readonly STRICT="${4:-0}"

declare -a FINDINGS=()
declare -i FILES_SCANNED=0
declare -i QUERIES_CHECKED=0
declare -i POLICIES_VERIFIED=0
declare -i C4_VIOLATIONS=0

# Patrones de exención válidos (C4 BYPASS explícito)
readonly -a EXEMPTION_PATTERNS=(
  "-- C4_EXEMPT"
  "-- C4_BYPASS"
  "-- CROSS_TENANT_AGG"
  "-- SYSTEM_MIGRATION"
  "// C4_EXEMPT"
  "/* C4_BYPASS */"
  "C4_EXEMPT=true"
)

# Keywords de tenant válidos
readonly -a TENANT_KEYWORDS=(
  "tenant_id" "tenantId" "ctx.tenant_id" "tenant.id"
  "current_tenant" "app.current_tenant_id" "metadata.tenant"
  "\\\$\\{tenant_id\\}" "\\\$\\{tenantId\\}"
)

# ────────────────────────────────────────────────────────────────────────────
# UTILIDADES
# ────────────────────────────────────────────────────────────────────────────
log_info() { [[ "$VERBOSE" == "1" ]] && echo "[INFO] $*" || true; }
log_warn() { echo "[WARN] $*" >&2; }
log_error() { echo "[ERROR] $*" >&2; }
log_finding() { 
  echo "[C4-FINDING] $*" >&2
  FINDINGS+=("$*")
  ((C4_VIOLATIONS++)) || true
}

is_exempt() {
  local line="$1"
  for pattern in "${EXEMPTION_PATTERNS[@]}"; do
    if echo "$line" | grep -qiE "$pattern"; then
      return 0
    fi
  done
  return 1
}

contains_tenant() {
  local text="$1"
  for kw in "${TENANT_KEYWORDS[@]}"; do
    if echo "$text" | grep -qiE "$kw"; then
      return 0
    fi
  done
  return 1
}

compute_sha256() {
  sha256sum "$1" 2>/dev/null | awk '{print $1}' || echo "unknown"
}

# ────────────────────────────────────────────────────────────────────────────
# VALIDACIÓN 1: SQL FILES (DML & RLS POLICIES)
# ────────────────────────────────────────────────────────────────────────────
validate_sql_file() {
  local file="$1"
  [[ ! -f "$file" ]] && return 0
  log_info "Validando SQL: $file"
  ((FILES_SCANNED++)) || true

  # 1. Detectar tablas creadas sin ENABLE ROW LEVEL SECURITY
  local tables_created
  tables_created=$(grep -ioE 'CREATE TABLE [a-z_0-9]+' "$file" 2>/dev/null || true)
  if [[ -n "$tables_created" ]]; then
    while IFS= read -r table_stmt; do
      local tbl_name
      tbl_name=$(echo "$table_stmt" | awk '{print $3}')
      if ! grep -qiE "ALTER TABLE ${tbl_name} ENABLE ROW LEVEL SECURITY|ENABLE ROW LEVEL SECURITY" "$file"; then
        log_finding "Tabla sin RLS activado: $tbl_name en $file"
      fi
    done <<< "$tables_created"
  fi

  # 2. Validar políticas RLS
  local policies
  policies=$(grep -nEi 'CREATE POLICY' "$file" 2>/dev/null || true)
  if [[ -n "$policies" ]]; then
    while IFS=: read -r line_num policy_line; do
      ((POLICIES_VERIFIED++)) || true
      # Buscar USING o WITH CHECK en las siguientes 15 líneas
      local policy_block
      policy_block=$(sed -n "${line_num},$((line_num+15))p" "$file")
      if ! echo "$policy_block" | grep -qiE 'tenant_id|tenantId|current_tenant'; then
        log_finding "Política RLS sin filtro tenant_id (línea $line_num): $file"
      fi
    done <<< "$policies"
  fi

  # 3. Validar consultas DML (SELECT/INSERT/UPDATE/DELETE)
  # Extraer bloques hasta punto y coma o nueva línea de declaración
  awk '
  BEGIN { IGNORECASE=1; in_query=0; query=""; start_line=0 }
  /^[[:space:]]*(SELECT|INSERT|UPDATE|DELETE|FROM|WHERE|JOIN|SET|VALUES)/ {
    if (!in_query) { start_line=NR; query="" }
    in_query=1
    query = query " " $0
  }
  /;/ && in_query {
    print start_line "|" query
    in_query=0; query=""
  }
  END {
    if (in_query && query != "") print start_line "|" query
  }
  ' "$file" 2>/dev/null | while IFS='|' read -r line_num query_text; do
    ((QUERIES_CHECKED++)) || true
    
    # Saltar consultas de sistema o metadatos
    if echo "$query_text" | grep -qiE 'information_schema|pg_catalog|pg_extension|version|current_setting'; then
      continue
    fi
    
    # Verificar exención
    local context
    context=$(sed -n "$((line_num-2)),$((line_num+2))p" "$file" 2>/dev/null || true)
    if is_exempt "$context"; then
      continue
    fi
    
    # Verificar presencia de tenant
    if ! contains_tenant "$query_text"; then
      # Verificar si es un JOIN implícito o subquery con tenant
      if ! echo "$query_text" | grep -qiE 'JOIN.*tenant|IN.*SELECT.*tenant|EXISTS.*tenant'; then
        log_finding "Consulta DML sin filtro tenant_id (línea ~$line_num): $file"
      fi
    fi
  done
}

# ────────────────────────────────────────────────────────────────────────────
# VALIDACIÓN 2: PRISMA SCHEMA
# ────────────────────────────────────────────────────────────────────────────
validate_prisma_file() {
  local file="$1"
  [[ ! -f "$file" ]] && return 0
  log_info "Validando Prisma: $file"
  ((FILES_SCANNED++)) || true

  # Extraer bloques de modelo
  awk '
  BEGIN { in_model=0; model_name=""; model_content="" }
  /^model [A-Za-z_]+/ { in_model=1; model_name=$2; model_content=$0 "\n"; next }
  in_model && /^}/ { 
    print model_name "|" model_content 
    in_model=0; model_name=""; model_content=""
    next 
  }
  in_model { model_content = model_content $0 "\n" }
  ' "$file" 2>/dev/null | while IFS='|' read -r model_name content; do
    if ! echo "$content" | grep -qiE 'tenant_id|tenantId|tenant\s+String'; then
      log_finding "Modelo Prisma sin campo tenant: $model_name en $file"
    fi
    # Verificar índice en tenant
    if echo "$content" | grep -qiE 'tenant_id|tenantId'; then
      if ! echo "$content" | grep -qiE '@@index|@@unique.*tenant'; then
        log_finding "Modelo con tenant pero sin índice: $model_name en $file"
      fi
    fi
  done
}

# ────────────────────────────────────────────────────────────────────────────
# VALIDACIÓN 3: N8N / JSON WORKFLOWS
# ────────────────────────────────────────────────────────────────────────────
validate_json_workflow() {
  local file="$1"
  [[ ! -f "$file" ]] && return 0
  log_info "Validando Workflow JSON: $file"
  ((FILES_SCANNED++)) || true

  # Buscar nodos de base de datos con queries
  grep -nEi '"query"|"sql"|"operation".*:.*"executeQuery"' "$file" 2>/dev/null | while IFS=: read -r line_num match; do
    ((QUERIES_CHECKED++)) || true
    
    # Extraer contexto de 20 líneas
    local ctx
    ctx=$(sed -n "$((line_num-5)),$((line_num+20))p" "$file")
    
    if is_exempt "$ctx"; then continue; fi
    
    if ! contains_tenant "$ctx"; then
      log_finding "Nodo DB sin mapeo tenant_id (línea ~$line_num): $file"
    fi
  done
}

# ────────────────────────────────────────────────────────────────────────────
# MOTOR DE ESCANEO
# ────────────────────────────────────────────────────────────────────────────
scan_file() {
  local file="$1"
  [[ ! -f "$file" ]] && return 0
  
  local ext="${file##*.}"
  local basename
  basename=$(basename "$file")
  
  case "$ext" in
    sql) validate_sql_file "$file" ;;
    prisma) validate_prisma_file "$file" ;;
    json) 
      # Solo workflows n8n o configs DB
      if echo "$basename" | grep -qiE 'n8n|workflow|pipeline'; then
        validate_json_workflow "$file"
      elif grep -qiE '"query"|"sql"' "$file" 2>/dev/null; then
        validate_json_workflow "$file"
      fi
      ;;
    md) 
      # Documentación con bloques de código SQL
      if grep -qEi '(SELECT|INSERT|UPDATE|DELETE|CREATE POLICY)' "$file" 2>/dev/null; then
        # Extraer bloques markdown y validarlos como SQL
        grep -zoP '```sql\n\K[\s\S]*?(?=\n```)' "$file" 2>/dev/null | \
        tr '\0' '\n' > "/tmp/_rls_check_$$.sql"
        validate_sql_file "/tmp/_rls_check_$$.sql"
        rm -f "/tmp/_rls_check_$$.sql"
      fi
      ;;
  esac
}

scan_directory() {
  local dir="$1"
  log_info "Escaneando directorio RLS/C4: $dir"
  
  while IFS= read -r -d '' file; do
    scan_file "$file"
  done < <(find "$dir" -type f \( -name "*.sql" -o -name "*.prisma" -o -name "*.json" -o -name "*.md" \) -print0 2>/dev/null)
}

# ────────────────────────────────────────────────────────────────────────────
# GENERACIÓN DE REPORTE
# ────────────────────────────────────────────────────────────────────────────
generate_report() {
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local status="passed"
  
  if [[ "$STRICT" == "1" && $C4_VIOLATIONS -gt 0 ]]; then
    status="failed"
  elif [[ $C4_VIOLATIONS -gt 0 ]]; then
    status="failed"
  fi
  
  local findings_json="[]"
  if [[ ${#FINDINGS[@]} -gt 0 ]]; then
    findings_json=$(printf '%s\n' "${FINDINGS[@]}" | paste -sd ',' | sed 's/}{/},{/g' | sed 's/"/\\"/g')
    # Fix JSON escaping for internal quotes if any
    findings_json="[${findings_json//\"/\\\"}]"
  fi
  
  local temp_report
  temp_report=$(mktemp)
  
  cat > "$temp_report" << EOF
{
  "validator_version": "$VERSION",
  "timestamp": "$timestamp",
  "constraint": "C4",
  "target": "$PROJECT_ROOT",
  "status": "$status",
  "summary": {
    "files_scanned": $FILES_SCANNED,
    "queries_checked": $QUERIES_CHECKED,
    "rls_policies_verified": $POLICIES_VERIFIED,
    "c4_violations": $C4_VIOLATIONS
  },
  "findings": $findings_json,
  "tenant_keywords_validated": ["tenant_id", "tenantId", "ctx.tenant_id", "current_tenant", "app.current_tenant_id"],
  "recommendations": [
    "Aplicar ALTER TABLE ... ENABLE ROW LEVEL SECURITY en todas las tablas multi-tenant",
    "Añadir campo tenant_id con índice a todos los modelos Prisma/ORM",
    "Configurar políticas RLS: CREATE POLICY tenant_isolation ON table USING (tenant_id = current_setting('app.current_tenant_id')::uuid)",
    "Inyectar tenant_id desde contexto de request en n8n/APIs",
    "Documentar excepciones C4 explícitamente con -- C4_EXEMPT"
  ],
  "audit": {
    "script_sha256": "$(compute_sha256 "$0")",
    "report_sha256": "PLACEHOLDER"
  }
}
EOF

  local report_sha
  report_sha=$(compute_sha256 "$temp_report")
  sed -i "s/\"report_sha256\": \"PLACEHOLDER\"/\"report_sha256\": \"$report_sha\"/" "$temp_report"
  mv "$temp_report" "$REPORT_FILE"
  
  echo ""
  echo "========================================="
  echo "🛡️  VALIDACIÓN RLS / C4 v$VERSION"
  echo "========================================="
  echo "Target: $PROJECT_ROOT"
  echo "Archivos escaneados: $FILES_SCANNED"
  echo "Consultas verificadas: $QUERIES_CHECKED"
  echo "Políticas RLS validadas: $POLICIES_VERIFIED"
  echo "🔴 Violaciones C4: $C4_VIOLATIONS"
  echo "Estado: $status"
  echo "🔐 Report SHA256: $report_sha"
  echo "📄 Reporte: $REPORT_FILE"
  echo "========================================="
  
  if [[ $C4_VIOLATIONS -gt 0 ]]; then
    echo ""
    echo "⚠️  Requiere corrección antes de merge:"
    for f in "${FINDINGS[@]}"; do
      echo "  • $f"
    done
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
Uso: $0 [ruta] [reporte.json] [verbose:0/1] [strict:0/1]

Validador de Row-Level Security y aislamiento multi-tenant (Constraint C4).
Verifica SQL, Prisma, n8n y documentación para garantizar tenant_id obligatorio.

Parámetros:
  ruta            Directorio/archivo a validar (default: .)
  reporte.json    Salida JSON (default: rls-validation-report.json)
  verbose:0/1     Modo detallado
  strict:0/1      Fail on warnings

Reglas C4 aplicadas:
  ✓ Todas las tablas con ENABLE ROW LEVEL SECURITY
  ✓ Políticas CREATE POLICY con USING/USING tenant_id
  ✓ Consultas DML con WHERE/JOIN tenant_id
  ✓ Modelos ORM con campo tenant_id + índice
  ✓ Workflows n8n con interpolación de tenant
  ✓ Exenciones explícitas: -- C4_EXEMPT

Ejemplos:
  $0 02-SKILLS/BASE\ DE\ DATOS-RAG/
  $0 . rls-report.json 1 1
  $0 --pre-commit

Salida: Reporte JSON + código 0/1 para CI/CD
EOF
    exit 0
  fi
  
  if [[ "${1:-}" == "--pre-commit" ]]; then
    log_info "Modo pre-commit: escaneando archivos DB modificados"
    local files
    files=$(git diff --cached --name-only 2>/dev/null | grep -E '\.(sql|prisma|json|md)$' || true)
    if [[ -n "$files" ]]; then
      while IFS= read -r f; do [[ -f "$f" ]] && scan_file "$f"; done <<< "$files"
    fi
    generate_report
    exit $?
  fi
  
  log_info "Iniciando validación RLS C4 v$VERSION"
  
  if [[ -f "$PROJECT_ROOT" ]]; then
    scan_file "$PROJECT_ROOT"
  elif [[ -d "$PROJECT_ROOT" ]]; then
    scan_directory "$PROJECT_ROOT"
  else
    log_error "Ruta no encontrada: $PROJECT_ROOT"
    exit 1
  fi
  
  generate_report
}

main "$@"

