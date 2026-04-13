#!/usr/bin/env bash
#---
# metadata_version: 1.1
# sdd_compliant: true
# ai_parser_compatible: true
# purpose: "Validador maestro de integridad SDD para MANTIS AGENTIC"
# dependencies: "bash 4+, grep, awk, sed, sha256sum, find, python3 (opcional)"
# validation_scope: "markdown, json, sql, yaml, docker-compose, tf"
# constraints_enforced: ["C1","C2","C3","C4","C5","C6"]
# output_format: "json + stdout + exit code"
# ---
# ============================================================================
# VALIDATE-SKILL-INTEGRITY.SH v1.1
# Script maestro modular para validación SDD en MANTIS AGENTIC
# Propósito: Validar estructura, constraints C1-C6, tenant-awareness,
# seguridad, y generar reporte con checksum SHA256 para auditoría (C5).
# Fixes v1.1: parsing de args robusto, resolución de rutas canónicas,
# sanitización aritmética, schema path absoluto, wikilinks con fallback.
# ============================================================================
set -euo pipefail

# ────────────────────────────────────────────────────────────────────────────
# CONFIGURACIÓN GLOBAL
# ────────────────────────────────────────────────────────────────────────────
readonly VERSION="1.1.0"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# Variables por defecto (se sobrescriben con args)
declare PROJECT_ROOT="."
declare REPORT_FILE="skill-validation-report.json"
declare VERBOSE="0"
declare STRICT="0"

# Arrays de estado
declare -a ERRORS=()
declare -a WARNINGS=()
declare -a PASSED=()
declare -i CHECKS_TOTAL=0
declare -i CHECKS_PASSED=0

# Constraints C1-C6
readonly CONSTRAINTS=("C1" "C2" "C3" "C4" "C5" "C6")

# ────────────────────────────────────────────────────────────────────────────
# PARSER DE ARGUMENTOS (Robusto: separa flags de paths)
# ────────────────────────────────────────────────────────────────────────────
parse_arguments() {
  local args=()
  for arg in "$@"; do
    case "$arg" in
      --strict) STRICT="1" ;;
      --verbose|-v) VERBOSE="1" ;;
      --report=*) REPORT_FILE="${arg#--report=}" ;;
      --help|-h) show_help; exit 0 ;;
      -*) continue ;; # Ignorar flags no reconocidos
      *) args+=("$arg") ;; # Paths válidos
    esac
  done
  
  # Asignar paths posicionales
  [[ ${#args[@]} -ge 1 ]] && PROJECT_ROOT="${args[0]}"
  [[ ${#args[@]} -ge 2 ]] && REPORT_FILE="${args[1]}"
  
  # Normalizar PROJECT_ROOT a ruta absoluta si es relativo
  if [[ ! "$PROJECT_ROOT" =~ ^/ ]]; then
    PROJECT_ROOT="$(pwd)/${PROJECT_ROOT}"
  fi
}

# ────────────────────────────────────────────────────────────────────────────
# UTILIDADES
# ────────────────────────────────────────────────────────────────────────────
log_info() { [[ "$VERBOSE" == "1" ]] && echo "[INFO] $*" || true; }
log_warn() { echo "[WARN] $*" >&2; WARNINGS+=("$*"); CHECKS_TOTAL=$((CHECKS_TOTAL + 1)); }
log_error() { echo "[ERROR] $*" >&2; ERRORS+=("$*"); CHECKS_TOTAL=$((CHECKS_TOTAL + 1)); }
log_pass() { 
  [[ "$VERBOSE" == "1" ]] && echo "[PASS] $*" || true
  PASSED+=("$*"); CHECKS_PASSED=$((CHECKS_PASSED + 1)); CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
}

# Sanitizar para operaciones aritméticas (evita "0\n0" → error)
sanitize_int() {
  local val="$1"
  echo "$val" | tr -cd '0-9' | head -c 10
}

compute_sha256() {
  local file="$1"
  if [[ -f "$file" ]]; then
    sha256sum "$file" 2>/dev/null | awk '{print $1}' || echo "unknown"
  else
    echo "file_not_found"
  fi
}

# ────────────────────────────────────────────────────────────────────────────
# VALIDACIÓN 1: FRONTMATTER YAML OBLIGATORIO (SDD Base)
# ────────────────────────────────────────────────────────────────────────────
validate_frontmatter() {
  local file="$1"
  [[ ! -f "$file" ]] && return 0
  [[ ! "$file" =~ \.md$ ]] && return 0

  log_info "Validando frontmatter: $file"

  # 1. Apertura y cierre de frontmatter
  if ! head -1 "$file" | grep -q '^---$'; then
    log_error "Falta apertura de frontmatter YAML en: $file"
    return 1
  fi

  # Extraer bloque frontmatter
  local fm_content
  fm_content=$(sed -n '/^---$/,/^---$/p' "$file" | head -n -1 | tail -n +2)

  # 2. Campo ai_optimized: true
  if ! echo "$fm_content" | grep -qE '^ai_optimized:\s*(true|yes)$'; then
    log_error "Frontmatter sin 'ai_optimized: true' en: $file"
    return 1
  fi
  log_pass "ai_optimized: true presente"

  # 3. Campo constraints con C1-C6
  if ! echo "$fm_content" | grep -qE '^constraints:\s*\[.*C[1-6].*\]$'; then
    log_warn "Frontmatter sin constraints C1-C6 mapeados explícitamente: $file"
  else
    log_pass "Constraints C1-C6 referenciados en frontmatter"
  fi

  # 4. Campo related_files con wikilinks válidos
  if echo "$fm_content" | grep -q '^related_files:'; then
    local related
    related=$(echo "$fm_content" | grep -A10 '^related_files:' | grep -cE '^\s*-\s*"\[\[' || echo 0)
    if [[ $(sanitize_int "$related") -gt 0 ]]; then
      log_pass "related_files con formato Obsidian válido"
    fi
  fi

  return 0
}

# ────────────────────────────────────────────────────────────────────────────
# VALIDACIÓN 2: WIKILINKS OBSIDIAN VÁLIDOS (Navegación IA)
# ────────────────────────────────────────────────────────────────────────────
check_wikilinks() {
  local file="$1"
  [[ ! -f "$file" ]] && return 0
  [[ ! "$file" =~ \.md$ ]] && return 0

  log_info "Verificando wikilinks Obsidian: $file"

  # Extraer todos los wikilinks [[...]]
  local links
  links=$(grep -oE '\[\[[^]]+\]\]' "$file" 2>/dev/null | sed 's/\[\[//g; s/\]\]//g' || true)

  if [[ -z "$links" ]]; then
    log_pass "Sin wikilinks para validar (no crítico)"
    return 0
  fi

  local broken=0
  local base_dir
  base_dir=$(dirname "$file")

  while IFS= read -r link; do
    [[ -z "$link" ]] && continue
    
    # Ignorar enlaces didácticos o anclas
    if [[ "$link" =~ ^# || "$link" == "enlaces" || "$link" == *"|"*"texto legible"* ]]; then
      log_pass "Wikilink ignorado (didáctico/ancla): [[${link}]]"
      continue
    fi

    # Extraer ruta real (sin alias ni anclas)
    local target_path
    target_path=$(echo "$link" | cut -d'|' -f1 | sed 's/#.*//' | xargs)
    [[ -z "$target_path" ]] && continue

    # Asegurar extensión
    if [[ ! "$target_path" =~ \.(md|json|sh|yml|yaml|tf|py)$ ]]; then
      target_path="${target_path}.md"
    fi

    local resolved=""
    
    # Resolución en orden de prioridad:
    # 1) Ruta absoluta desde root del repo
    if [[ "$target_path" == /* ]]; then
      resolved="${REPO_ROOT}${target_path}"
    
    # 2) Prefijos conocidos del repo
    elif [[ "$target_path" =~ ^(00-CONTEXT|01-RULES|02-SKILLS|03-AGENTS|04-WORKFLOWS|05-CONFIGURATIONS|06-PROGRAMMING|07-PROCEDURES|08-LOGS)/ ]]; then
      resolved="${REPO_ROOT}/${target_path}"
    
    # 3) Ruta relativa con ../ o ./
    elif [[ "$target_path" == ../* || "$target_path" == ./* ]]; then
      resolved="${base_dir}/${target_path}"
    
    # 4) Archivo en mismo directorio
    elif [[ "$target_path" != */* ]]; then
      resolved="${base_dir}/${target_path}"
    
    # 5) Fallback: búsqueda recursiva
    else
      local basename_file
      basename_file=$(basename "$target_path")
      resolved=$(find "${REPO_ROOT}" -name "$basename_file" -type f 2>/dev/null | head -1 || echo "")
      if [[ -n "$resolved" ]]; then
        log_pass "Wikilink resuelto por fallback: [[${link}]] → $resolved"
        continue
      fi
      resolved="${base_dir}/${target_path}"
    fi

    # Verificar existencia
    if [[ -f "$resolved" ]]; then
      log_pass "Wikilink válido: [[${link}]]"
    else
      log_warn "Wikilink roto: [[${link}]] en $file (resuelto: $resolved)"
      broken=$((broken + 1))
    fi
  done <<< "$links"

  # Sanitizar broken antes de comparar
  local broken_clean
  broken_clean=$(sanitize_int "$broken")
  
  if [[ -n "$broken_clean" && "$broken_clean" -gt 0 ]]; then
    log_error "$broken_clean wikilinks rotos detectados en: $file"
    return 1
  fi

  # Verificar ciclos simples
  if grep -qE "\[\[$(basename "$file")\]\]" "$file"; then
    log_warn "Posible ciclo: archivo se enlaza a sí mismo: $file"
  fi

  return 0
}

# ────────────────────────────────────────────────────────────────────────────
# VALIDACIÓN 3: CONSTRAINTS C1-C6 EXPLÍCITOS EN EJEMPLOS (Hardening)
# ────────────────────────────────────────────────────────────────────────────
verify_constraints() {
  local file="$1"
  [[ ! -f "$file" ]] && return 0

  log_info "Verificando constraints C1-C6 en ejemplos: $file"

  # Buscar secciones de ejemplo
  local examples
  examples=$(grep -c '^### Ejemplo [0-9]' "$file" 2>/dev/null || echo 0)
  local examples_clean
  examples_clean=$(sanitize_int "$examples")

  if [[ "$examples_clean" -lt 5 ]]; then
    log_warn "Mínimo 5 ejemplos recomendados, encontrados: $examples_clean en $file"
  else
    log_pass "Número de ejemplos ≥5: $examples_clean"
  fi

  # Verificar presencia explícita de cada constraint
  for constraint in "${CONSTRAINTS[@]}"; do
    if grep -qE "(^|[[:space:]])${constraint}([[:space:]]|:|,|\]|$)" "$file"; then
      log_pass "Constraint $constraint referenciado explícitamente"
    else
      # C6 tiene excepción documentada para Llama (open-weight)
      if [[ "$constraint" == "C6" ]] && grep -qi "llama.*open-weight\|exception.*C6\|c6_exception_documented" "$file"; then
        log_pass "C6: excepción documentada para modelo open-weight"
      else
        log_warn "Constraint $constraint no encontrado explícitamente en: $file"
      fi
    fi
  done

  # Validaciones específicas por constraint
  grep -qE '(timeout|connectionLimit|maxResults|memory:\s*[0-9]+M|mem_limit)' "$file" && \
    log_pass "C1: patrones de límite de recursos presentes" || \
    log_warn "C1: límites de recursos no explícitos"

  grep -qE "(cpus:|cpu_limit|timeout:|EXECUTIONS_MAX_CONCURRENT|nice |ionice )" "$file" && \
    log_pass "C2: límites de CPU/concurrencia referenciados" || \
    log_warn "C2: aislamiento de CPU no explícito"

  grep -qE '(process\.env\.|os\.getenv\(|\$\{[A-Z_]+\}|docker.*--env-file|age -r|vault)' "$file" && \
    log_pass "C3: gestión segura de secretos presente" || \
    log_warn "C3: gestión de secretos no explícita"

  if grep -qiE '(tenant_id|tenantId|ctx\.tenant|current_tenant|X-Tenant-ID|WHERE.*tenant|filter.*tenant)' "$file"; then
    log_pass "C4: tenant_id presente en contexto ejecutable"
  else
    log_error "C4 VIOLADO: tenant_id no encontrado en consultas/filtros: $file"
    return 1
  fi

  grep -qiE '(sha256|checksum|audit_hash|backup.*enc|age -r|verify.*integrity)' "$file" && \
    log_pass "C5: patrones de backup+verificación presentes" || \
    log_warn "C5: auditoría de integridad no explícita"

  if grep -qiE '(openrouter\.ai|api\.openai\.com|cloud.*inference|provider.*cloud)'; then
    log_pass "C6: inferencia cloud-only referenciada"
  elif grep -qiE '(llama.*local|c6_exception_documented.*true|open.*weight.*exception)'; then
    log_pass "C6: excepción documentada para inferencia local"
  else
    log_warn "C6: inferencia cloud/local no documentada explícitamente"
  fi

  return 0
}

# ────────────────────────────────────────────────────────────────────────────
# VALIDACIÓN 4: AUDITORÍA DE SECRETOS (C3 - Cero Hardcode)
# ────────────────────────────────────────────────────────────────────────────
audit_secrets() {
  local file="$1"
  [[ ! -f "$file" ]] && return 0

  log_info "Auditoría de secretos (C3): $file"

  local patterns=(
    'sk-[a-zA-Z0-9]{20,}'
    'ghp_[a-zA-Z0-9]{36}'
    'gho_[a-zA-Z0-9]{36}'
    'password\s*=\s*["\x27][^"\x27]{8,}'
    'api_key\s*=\s*["\x27][^"\x27]{16,}'
    'secret\s*=\s*["\x27][^"\x27]{16,}'
    'Bearer\s+[a-zA-Z0-9._-]{20,}'
  )

  local found_secrets=0
  for pattern in "${patterns[@]}"; do
    if grep -E "$pattern" "$file" 2>/dev/null | grep -v -E '(ENV_VAR|\$\{|XXXX|TODO|PLACEHOLDER|your_key_here|<[^>]+>|\$\([A-Z_]+\))' > /dev/null 2>&1; then
      log_error "Posible credencial hardcodeada detectada (patrón: $pattern) en: $file"
      found_secrets=$((found_secrets + 1))
    fi
  done

  if [[ "$found_secrets" -eq 0 ]]; then
    log_pass "C3: cero credenciales hardcodeadas detectadas"
    return 0
  else
    log_error "C3 VIOLADO: $found_secrets posibles secretos expuestos en: $file"
    return 1
  fi
}

# ────────────────────────────────────────────────────────────────────────────
# VALIDACIÓN 5: ESQUEMA JSON PARA OUTPUTS DE IA (Determinismo)
# ────────────────────────────────────────────────────────────────────────────
validate_schema() {
  local file="$1"
  [[ ! -f "$file" ]] && return 0
  
  # Resolución robusta de schema path (absoluta desde repo root)
  local schema_path="${REPO_ROOT}/05-CONFIGURATIONS/validation/schemas/skill-input-output.schema.json"
  
  if [[ ! -f "$schema_path" ]]; then
    # Intentar ruta relativa desde script
    schema_path="${SCRIPT_DIR}/schemas/skill-input-output.schema.json"
  fi
  
  if [[ ! -f "$schema_path" ]]; then
    log_warn "Schema skill-input-output.schema.json no encontrado en rutas esperadas"
    return 0
  fi

  log_info "Validando output contra JSON Schema: $file"

  # Extraer bloques JSON
  local json_blocks
  json_blocks=$(grep -zoP '```json\n\K[\s\S]*?(?=\n```)' "$file" 2>/dev/null || true)

  if [[ -z "$json_blocks" ]]; then
    log_pass "Sin bloques JSON para validar contra schema"
    return 0
  fi

  # Validar con python3 + jsonschema
  if command -v python3 &>/dev/null; then
    while IFS= read -r -d '' block; do
      if ! python3 -c "
import json, sys
from jsonschema import validate, ValidationError
schema = json.load(open('$schema_path'))
try:
    validate(instance=json.loads('''$block'''), schema=schema)
    sys.exit(0)
except ValidationError as e:
    print(f'Schema error: {e.message}', file=sys.stderr)
    sys.exit(1)
except json.JSONDecodeError as e:
    print(f'JSON parse error: {e}', file=sys.stderr)
    sys.exit(1)
" 2>/dev/null; then
        log_warn "Bloque JSON no válido contra schema en: $file"
      else
        log_pass "Bloque JSON válido contra schema"
      fi
    done < <(printf '%s\0' "$json_blocks")
  else
    log_warn "Python3 no disponible, validación de schema omitida"
  fi

  return 0
}

# ────────────────────────────────────────────────────────────────────────────
# VALIDACIÓN 6: INTEGRIDAD POST-GENERACIÓN (C5 - Checksum SHA256)
# ────────────────────────────────────────────────────────────────────────────
validate_integrity_checksum() {
  local file="$1"
  [[ ! -f "$file" ]] && return 0

  log_info "Generando checksum SHA256 para auditoría (C5): $file"

  local checksum
  checksum=$(compute_sha256 "$file")

  # Verificar archivo .sha256 companion
  local checksum_file="${file}.sha256"
  if [[ -f "$checksum_file" ]]; then
    if sha256sum -c "$checksum_file" &>/dev/null; then
      log_pass "Checksum verificado exitosamente"
    else
      log_error "Verificación de checksum FALLIDA para: $file"
      return 1
    fi
  else
    log_info "Checksum generado (sin archivo .sha256 para verificación): $checksum"
  fi

  echo "$checksum"
  return 0
}

# ────────────────────────────────────────────────────────────────────────────
# MOTOR DE EJECUCIÓN MODULAR
# ────────────────────────────────────────────────────────────────────────────
run_validations() {
  local target="$1"

  if [[ -f "$target" ]]; then
    log_info "=== Validando archivo: $target ==="

    validate_frontmatter "$target" || true
    check_wikilinks "$target" || true
    verify_constraints "$target" || true
    audit_secrets "$target" || true
    validate_schema "$target" || true
    validate_integrity_checksum "$target" || true

  elif [[ -d "$target" ]]; then
    log_info "=== Escaneando directorio: $target ==="

    while IFS= read -r -d '' file; do
      [[ "$file" == *".git"* ]] && continue
      [[ "$file" == *"node_modules"* ]] && continue
      run_validations "$file"
    done < <(find "$target" -type f \( -name "*.md" -o -name "*.json" -o -name "*.sql" -o -name "*.yml" -o -name "*.yaml" -o -name "*.tf" -o -name "*.sh" \) -print0 2>/dev/null)
  else
    log_error "Ruta no encontrada: $target"
    return 1
  fi
}

# ────────────────────────────────────────────────────────────────────────────
# GENERACIÓN DE REPORTE JSON CON CHECKSUM (C5)
# ────────────────────────────────────────────────────────────────────────────
generate_report() {
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local status="passed"
  
  # Determinar estado
  [[ ${#ERRORS[@]} -gt 0 ]] && status="failed"
  [[ "$STRICT" == "1" && ${#WARNINGS[@]} -gt 0 ]] && status="failed"

  # Sanitizar contadores para aritmética
  local total_clean passed_clean warnings_clean errors_clean
  total_clean=$(sanitize_int "$CHECKS_TOTAL")
  passed_clean=$(sanitize_int "$CHECKS_PASSED")
  warnings_clean=$(sanitize_int "${#WARNINGS[@]}")
  errors_clean=$(sanitize_int "${#ERRORS[@]}")
  
  # Evitar división por cero
  local pass_rate="0.00"
  if [[ "$total_clean" -gt 0 ]]; then
    pass_rate=$(awk "BEGIN {printf \"%.2f\", ($passed_clean/$total_clean)*100}" 2>/dev/null || echo "0.00")
  fi

  # Crear reporte temporal
  local temp_report
  temp_report=$(mktemp)

  # Construir arrays JSON manualmente
  local errors_json="[]"
  local warnings_json="[]"
  
  if [[ ${#ERRORS[@]} -gt 0 ]]; then
    errors_json=$(printf '%s\n' "${ERRORS[@]}" | awk '{printf "%s\"%s\"", (NR>1?",":""), $0}' | sed 's/"/\\"/g' | awk '{print "["$0"]"}')
  fi
  if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    warnings_json=$(printf '%s\n' "${WARNINGS[@]}" | awk '{printf "%s\"%s\"", (NR>1?",":""), $0}' | sed 's/"/\\"/g' | awk '{print "["$0"]"}')
  fi

  # Construir JSON del reporte
  cat > "$temp_report" << EOF
{
  "validator_version": "$VERSION",
  "timestamp": "$timestamp",
  "target": "$PROJECT_ROOT",
  "status": "$status",
  "summary": {
    "total_checks": $total_clean,
    "passed": $passed_clean,
    "warnings": $warnings_clean,
    "errors": $errors_clean,
    "pass_rate": $pass_rate
  },
  "constraints_validated": ["C1","C2","C3","C4","C5","C6"],
  "details": {
    "errors": $errors_json,
    "warnings": $warnings_json,
    "passed_checks_count": ${#PASSED[@]}
  },
  "audit": {
    "report_sha256": "PLACEHOLDER",
    "validation_script_sha256": "$(compute_sha256 "$0")"
  }
}
EOF

  # Calcular checksum final y reemplazar placeholder
  local report_checksum
  report_checksum=$(compute_sha256 "$temp_report")
  sed -i "s/\"report_sha256\": \"PLACEHOLDER\"/\"report_sha256\": \"$report_checksum\"/" "$temp_report"

  # Mover a destino final (usar cp para evitar conflictos con flags)
  cp "$temp_report" "$REPORT_FILE"
  rm -f "$temp_report"

  # Output en stdout
  echo ""
  echo "========================================="
  echo "📊 REPORTE DE VALIDACIÓN SDD v$VERSION"
  echo "========================================="
  echo "Target: $PROJECT_ROOT"
  echo "Estado: $status"
  echo "✅ Pasaron: $passed_clean / $total_clean checks"
  echo "⚠️  Advertencias: $warnings_clean"
  echo "❌ Errores: $errors_clean"
  echo "🔐 Report SHA256: $report_checksum"
  echo "📄 Reporte guardado: $REPORT_FILE"
  echo "========================================="

  # Código de salida para CI/CD
  if [[ "$status" == "failed" ]]; then
    exit 1
  fi
  exit 0
}

# ────────────────────────────────────────────────────────────────────────────
# HELP
# ────────────────────────────────────────────────────────────────────────────
show_help() {
  cat << EOF
Uso: $0 [ruta] [reporte.json] [opciones]

Validador maestro de integridad SDD para MANTIS AGENTIC.

Parámetros posicionales:
  ruta_archivo_o_directorio  Ruta a validar (default: .)
  reporte.json               Archivo de salida JSON (default: skill-validation-report.json)

Opciones:
  --strict       Tratar warnings como errores (para CI/CD)
  --verbose, -v  Modo detallado
  --help, -h     Mostrar esta ayuda

Ejemplos:
  $0 02-SKILLS/AI/qwen-integration.md
  $0 02-SKILLS/ validation-report.json --strict
  $0 . --report=ci-report.json --verbose

Validaciones ejecutadas:
  ✓ Frontmatter YAML obligatorio (ai_optimized, constraints C1-C6)
  ✓ Wikilinks Obsidian válidos (resolución canónica + fallback)
  ✓ Constraints C1-C6 explícitos en ejemplos
  ✓ Auditoría de secretos (C3: cero hardcode)
  ✓ tenant_id obligatorio en consultas (C4)
  ✓ Validación contra JSON Schema para outputs IA
  ✓ Checksum SHA256 para auditoría (C5)

Salida:
  - Reporte JSON con estado, métricas y checksum SHA256
  - Código de salida: 0 (éxito) / 1 (fallos críticos)
EOF
}

# ────────────────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────────────────
main() {
  parse_arguments "$@"
  
  log_info "Iniciando validador SDD v$VERSION"
  log_info "Repo root: $REPO_ROOT"
  log_info "Target: $PROJECT_ROOT"
  log_info "Constraints activos: ${CONSTRAINTS[*]}"
  log_info "Strict mode: $STRICT"

  run_validations "$PROJECT_ROOT"
  generate_report
}

main "$@"
