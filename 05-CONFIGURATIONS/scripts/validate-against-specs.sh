#!/usr/bin/env bash
#---
# metadata_version: 1.0
# sdd_compliant: true
# ai_parser_compatible: true
# purpose: "Validador SDD para constraints C1-C6, tenant-awareness y estructura"
# dependencies: "bash 4+, grep, awk, sed, sha256sum"
# validation_scope: "markdown, json, sql, yaml, docker-compose"
# strict_mode_default: false
# ---
# ============================================================================
# VALIDATE-AGAINST-SPECS.SH v1.0
# Validador SDD para MANTIS AGENTIC
# Propósito: Verificar cumplimiento de constraints C1-C6, estructura SDD,
#           tenant-awareness, seguridad y límites de recursos.
# Dependencias: bash 4+, grep, awk, sed, sha256sum, find (Ubuntu base)
# ============================================================================
set -euo pipefail

# ────────────────────────────────────────────────────────────────────────────
# CONFIGURACIÓN GLOBAL
# ────────────────────────────────────────────────────────────────────────────
readonly VERSION="1.0.0"
readonly SCRIPT_NAME="$(basename "$0")"
readonly PROJECT_ROOT="${1:-.}"
readonly REPORT_FILE="${2:-validation-report.json}"
readonly VERBOSE="${3:-0}"
readonly STRICT="${4:-0}" # 1 = warnings become errors

declare -a ERRORS=()
declare -a WARNINGS=()
declare -a PASSED=()

# ────────────────────────────────────────────────────────────────────────────
# UTILIDADES
# ────────────────────────────────────────────────────────────────────────────
log_info()  { echo "[INFO]  $*"; }
log_warn()  { echo "[WARN]  $*" >&2; WARNINGS+=("$*"); }
log_error() { echo "[ERROR] $*" >&2; ERRORS+=("$*"); }
log_pass()  { [[ "$VERBOSE" == "1" ]] && echo "[PASS]  $*"; PASSED+=("$*"); }

compute_sha() {
  sha256sum "$1" 2>/dev/null | awk '{print $1}' || echo "unknown"
}

# ────────────────────────────────────────────────────────────────────────────
# VALIDACIÓN: ESTRUCTURA MARKDOWN (SDD)
# ────────────────────────────────────────────────────────────────────────────
validate_markdown_structure() {
  local file="$1"
  [[ ! -f "$file" ]] && return 0

  # 1. Frontmatter YAML obligatorio
  if ! head -1 "$file" | grep -q '^---$'; then
    log_error "Falta apertura de frontmatter YAML: $file"
    return 1
  fi

  # 2. Code fences balanceados
  local fences
  fences=$(grep -c '```' "$file" 2>/dev/null || echo 0)
  if (( fences % 2 != 0 )); then
    log_error "Code fences desbalanceados ($fences): $file"
    return 1
  fi
  log_pass "Code fences balanceados: $file"

  # 3. Tablas Markdown válidas (deben tener separador |---|)
  if grep -q '|.*|.*|' "$file"; then
    if ! grep -q '|.*[-:|]*.*|' "$file"; then
      log_warn "Posible tabla sin separador Markdown: $file"
    else
      log_pass "Formato tabla válido: $file"
    fi
  fi

  # 4. Sin secrets hardcodeados (patrón seguro)
  if grep -E '(sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{36}|password=|api_key=|secret=)' "$file" | grep -v -E '(ENV_VAR|\$\{|XXXX|TODO|PLACEHOLDER)' > /dev/null; then
    log_error "Posible secret hardcodeado detectado: $file"
    return 1
  fi
  log_pass "Sin secrets expuestos: $file"
}

# ────────────────────────────────────────────────────────────────────────────
# VALIDACIÓN: TENANT-AWARENESS (C4)
# ────────────────────────────────────────────────────────────────────────────
validate_tenant_awareness() {
  local file="$1"
  [[ ! -f "$file" ]] && return 0

  # Solo aplica a archivos de infra, rules, SQL o workflows
  if [[ "$file" =~ (infrastructure|RULES|\.sql|workflow\.json) ]]; then
    if ! grep -qi 'tenant_id' "$file"; then
      log_error "Constraint C4 violado: Falta tenant_id en ejemplos/spec: $file"
      return 1
    fi
    log_pass "Tenant_id presente: $file"

    # Validar que no esté comentado en ejemplos críticos
    if grep -q 'WHERE.*tenant_id' "$file" || grep -q '"tenant_id"' "$file"; then
      log_pass "tenant_id en contexto ejecutable: $file"
    else
      log_warn "tenant_id encontrado, pero no en query/filtro ejecutable: $file"
    fi
  fi
}

# ────────────────────────────────────────────────────────────────────────────
# VALIDACIÓN: RECURSOS (C1, C2)
# ────────────────────────────────────────────────────────────────────────────
validate_resource_limits() {
  local file="$1"
  [[ ! -f "$file" ]] && return 0

  if [[ "$file" =~ docker-compose ]] || [[ "$file" =~ \.yml$ ]]; then
    # Verificar memory limit para n8n (C1: máx 1.5GB)
    if grep -q 'n8n' "$file"; then
      if ! grep -qE 'memory:\s*"?1[0-9]{2,}M"?|memory:\s*"?1\.?[0-9]?G"?|deploy:\s*resources:\s*limits:\s*memory' "$file"; then
        log_warn "n8n detectado sin límite de memoria explícito (C1): $file"
      else
        log_pass "Límite de memoria n8n verificado: $file"
      fi
    fi

    # Verificar CPU limit (C2: 1 vCPU)
    if grep -q 'cpus:' "$file" || grep -q 'deploy:' "$file"; then
      log_pass "Límite CPU configurado: $file"
    else
      log_warn "Sin límite CPU explícito (C2): $file"
    fi
  fi
}

# ────────────────────────────────────────────────────────────────────────────
# VALIDACIÓN: SEGURIDAD (C3, C6)
# ────────────────────────────────────────────────────────────────────────────
validate_security() {
  local file="$1"
  [[ ! -f "$file" ]] && return 0

  # C3: MySQL/Qdrant nunca expuestos a 0.0.0.0
  if grep -qE '(mysql|qdrant|mariadb|postgres)' "$file"; then
    if grep -E 'ports:' -A5 "$file" | grep -qE '^\s*-?\s*"?(0\.0\.0\.0|3306|6333|8000):?'; then
      log_error "Constraint C3 violado: Puerto de BD/vector expuesto públicamente: $file"
      return 1
    fi
    log_pass "Puertos BD protegidos (C3): $file"
  fi

  # C6: No modelos locales
  if grep -qiE '(ollama|localai|llamacpp|huggingface.*local|transformers.*pipeline)' "$file"; then
    log_warn "Posible modelo local detectado (C6): $file"
  fi
}

# ────────────────────────────────────────────────────────────────────────────
# VALIDACIÓN: PATRONES N8N (PREPARADO PARA 05-CODE-PATTERNS)
# ────────────────────────────────────────────────────────────────────────────
validate_n8n_patterns() {
  local file="$1"
  [[ ! -f "$file" || ! "$file" =~ \.json$ ]] && return 0

  # Verificar estructura mínima de workflow n8n
  if ! grep -q '"nodes"' "$file" || ! grep -q '"connections"' "$file"; then
    log_warn "Estructura n8n incompleta (faltan nodes/connections): $file"
    return 1
  fi

  # Timeout explícito en HTTP Request (API-001)
  if grep -q '"type":\s*"n8n-nodes-base.httpRequest"' "$file"; then
    if ! grep -q '"timeout"' "$file"; then
      log_error "Nodo HTTP sin timeout explícito: $file"
      return 1
    fi
    log_pass "Timeout HTTP configurado: $file"
  fi

  # tenant_id en headers o parameters
  if grep -q '"headers"' "$file" || grep -q '"parameters"' "$file"; then
    if ! grep -q '"tenant_id"' "$file" && ! grep -q 'tenant_id' "$file"; then
      log_warn "Workflow n8n sin referencia visible a tenant_id: $file"
    fi
  fi
}

# ────────────────────────────────────────────────────────────────────────────
# VALIDACIÓN: SQL (PREPARADO PARA 05/08)
# ────────────────────────────────────────────────────────────────────────────
validate_sql_patterns() {
  local file="$1"
  [[ ! -f "$file" || ! "$file" =~ \.sql$ ]] && return 0

  # tenant_id obligatorio en WHERE/JOIN
  if grep -qiE '(WHERE|JOIN|INSERT|UPDATE)' "$file"; then
    if ! grep -qi 'tenant_id' "$file"; then
      log_error "Consulta SQL sin tenant_id (C4): $file"
      return 1
    fi
  fi

  # Prepared statements
  if grep -qiE "(WHERE\s+[a-z_]+\s*=\s*'[^']+'" "$file"; then
    log_warn "Posible SQL sin prepared statements (usar ? o $N): $file"
  else
    log_pass "Formato SQL seguro detectado: $file"
  fi
}

# ────────────────────────────────────────────────────────────────────────────
# MOTOR DE EJECUCIÓN
# ────────────────────────────────────────────────────────────────────────────
run_validations() {
  local target="$1"
  
  if [[ -f "$target" ]]; then
    log_info "Validando archivo: $target"
    validate_markdown_structure "$target" || true
    validate_tenant_awareness "$target" || true
    validate_resource_limits "$target" || true
    validate_security "$target" || true
    validate_n8n_patterns "$target" || true
    validate_sql_patterns "$target" || true
  elif [[ -d "$target" ]]; then
    log_info "Escaneando directorio: $target"
    while IFS= read -r -d '' file; do
      [[ "$file" == *".git"* ]] && continue
      run_validations "$file"
    done < <(find "$target" -type f \( -name "*.md" -o -name "*.json" -o -name "*.sql" -o -name "*.yml" -o -name "*.yaml" -o -name "*.sh" \) -print0)
  else
    log_error "Ruta no encontrada: $target"
    exit 1
  fi
}

# ────────────────────────────────────────────────────────────────────────────
# REPORTE Y SALIDA
# ────────────────────────────────────────────────────────────────────────────
generate_report() {
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local status="passed"
  [[ ${#ERRORS[@]} -gt 0 ]] && status="failed"
  [[ "$STRICT" == "1" && ${#WARNINGS[@]} -gt 0 ]] && status="failed"

  # Construir JSON manual (sin jq para compatibilidad mínima)
  cat > "$REPORT_FILE" << EOF
{
  "validator_version": "$VERSION",
  "timestamp": "$timestamp",
  "target": "$PROJECT_ROOT",
  "status": "$status",
  "summary": {
    "passed": ${#PASSED[@]},
    "warnings": ${#WARNINGS[@]},
    "errors": ${#ERRORS[@]}
  },
  "details": {
    "errors": $(printf '%s\n' "${ERRORS[@]}" | jq -R . | jq -s . 2>/dev/null || printf '[]'),
    "warnings": $(printf '%s\n' "${WARNINGS[@]}" | jq -R . | jq -s . 2>/dev/null || printf '[]'),
    "passed_checks": ${#PASSED[@]}
  }
}
EOF

  echo ""
  echo "========================================="
  echo "📊 REPORTE DE VALIDACIÓN SDD v$VERSION"
  echo "========================================="
  echo "Estado: $status"
  echo "✅ Pasaron: ${#PASSED[@]}"
  echo "⚠️  Advertencias: ${#WARNINGS[@]}"
  echo "❌ Errores: ${#ERRORS[@]}"
  echo "📄 Reporte: $REPORT_FILE"
  echo "========================================="
  
  [[ "$status" == "failed" ]] && exit 1
  exit 0
}

# ────────────────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────────────────
main() {
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Uso: $0 [ruta_archivo_o_directorio] [report.json] [verbose:0/1] [strict:0/1]"
    echo "Ejemplo: $0 ./01-RULES/ sdd-report.json 1 0"
    exit 0
  fi

  log_info "Iniciando validador SDD v$VERSION"
  run_validations "$PROJECT_ROOT"
  generate_report
}

main "$@"

