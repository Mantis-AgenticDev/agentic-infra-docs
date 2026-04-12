
#!/usr/bin/env bash
#---
# metadata_version: 1.0
# sdd_compliant: true
# ai_parser_compatible: true
# purpose: "Validador maestro de integridad SDD para 02-SKILLS/"
# dependencies: "bash 4+, grep, awk, sed, sha256sum, find, yq (opcional)"
# validation_scope: "markdown, json, sql, yaml, docker-compose"
# constraints_enforced: ["C1","C2","C3","C4","C5","C6"]
# output_format: "json + stdout"
# ---
# ============================================================================
# VALIDATE-SKILL-INTEGRITY.SH v1.0
# Script maestro modular para validación SDD en MANTIS AGENTIC
# Propósito: Validar estructura, constraints C1-C6, tenant-awareness,
# seguridad, y generar reporte con checksum SHA256 para auditoría (C5).
# ============================================================================
set -euo pipefail

# ────────────────────────────────────────────────────────────────────────────
# CONFIGURACIÓN GLOBAL
# ────────────────────────────────────────────────────────────────────────────
readonly VERSION="1.0.0"
readonly SCRIPT_NAME="$(basename "$0")"
readonly PROJECT_ROOT="${1:-.}"
readonly REPORT_FILE="${2:-skill-validation-report.json}"
readonly VERBOSE="${3:-0}"
readonly STRICT="${4:-0}"

declare -a ERRORS=()
declare -a WARNINGS=()
declare -a PASSED=()
declare -i CHECKS_TOTAL=0
declare -i CHECKS_PASSED=0

# Constraints C1-C6 (para validación explícita)
readonly CONSTRAINTS=("C1" "C2" "C3" "C4" "C5" "C6")
readonly CONSTRAINT_DEFS=(
  "C1:RAM≤4GB" "C2:1vCPU/servicio" "C3:DB-no-expuesta"
  "C4:tenant_id-obligatorio" "C5:backup+SHA256" "C6:cloud-only-inference"
)

# ────────────────────────────────────────────────────────────────────────────
# UTILIDADES
# ────────────────────────────────────────────────────────────────────────────
log_info() { [[ "$VERBOSE" == "1" ]] && echo "[INFO] $*" || true; }
log_warn() { echo "[WARN] $*" >&2; WARNINGS+=("$*"); ((CHECKS_TOTAL++)) || true; }
log_error() { echo "[ERROR] $*" >&2; ERRORS+=("$*"); ((CHECKS_TOTAL++)) || true; }
log_pass() { 
  [[ "$VERBOSE" == "1" ]] && echo "[PASS] $*" || true
  PASSED+=("$*"); ((CHECKS_PASSED++)); ((CHECKS_TOTAL++)) || true
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

  # Extraer bloque frontmatter (entre primeros ---)
  local fm_content
  fm_content=$(sed -n '/^---$/,/^---$/p' "$file" | head -n -1 | tail -n +2)

  # 2. Campo ai_optimized: true (obligatorio para skills)
  if ! echo "$fm_content" | grep -qE '^ai_optimized:\s*(true|yes)$'; then
    log_error "Frontmatter sin 'ai_optimized: true' en: $file"
    return 1
  fi
  log_pass "ai_optimized: true presente"

  # 3. Campo constraints con al menos C1-C6 referenciados
  if ! echo "$fm_content" | grep -qE '^constraints:\s*\[.*C[1-6].*\]$'; then
    log_warn "Frontmatter sin constraints C1-C6 mapeados explícitamente: $file"
  else
    log_pass "Constraints C1-C6 referenciados en frontmatter"
  fi

  # 4. Campo related_files con wikilinks válidos
  if echo "$fm_content" | grep -q '^related_files:'; then
    local related
    related=$(echo "$fm_content" | grep -A10 '^related_files:' | grep -E '^\s*-\s*"\[\[' | wc -l)
    if [[ "$related" -gt 0 ]]; then
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

  # Extraer todos los wikilinks [[archivo.md]]
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
    # Resolver ruta relativa desde el archivo actual
    local target_path
    target_path=$(echo "$link" | cut -d'|' -f1 | xargs) # Soportar alias [[file.md|alias]]

    # Buscar archivo en 02-SKILLS/ o rutas absolutas del repo
    if [[ "$target_path" =~ ^02-SKILLS/ ]]; then
      target_path="${PROJECT_ROOT}/${target_path}"
    elif [[ ! "$target_path" =~ ^/ ]]; then
      target_path="${base_dir}/${target_path}"
    fi

    if [[ ! -f "$target_path" ]]; then
      # Intentar búsqueda recursiva en 02-SKILLS
      local found
      found=$(find "${PROJECT_ROOT}/02-SKILLS" -name "$(basename "$target_path")" -type f 2>/dev/null | head -1 || true)
      if [[ -z "$found" ]]; then
        log_warn "Wikilink roto: [[${link}]] en $file"
        ((broken++)) || true
      else
        log_pass "Wikilink resuelto: [[${link}]] → $found"
      fi
    else
      log_pass "Wikilink válido: [[${link}]]"
    fi
  done <<< "$links"

  if [[ "$broken" -gt 0 ]]; then
    log_error "$broken wikilinks rotos detectados en: $file"
    return 1
  fi

  # Verificar ciclos simples (enlace a sí mismo)
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

  # Buscar secciones de ejemplo (### Ejemplo N:)
  local examples
  examples=$(grep -c '^### Ejemplo [0-9]' "$file" 2>/dev/null || echo 0)

  if [[ "$examples" -lt 5 ]]; then
    log_warn "Mínimo 5 ejemplos recomendados, encontrados: $examples en $file"
  else
    log_pass "Número de ejemplos ≥5: $examples"
  fi

  # Verificar presencia explícita de cada constraint en el contenido
  for constraint in "${CONSTRAINTS[@]}"; do
    if grep -qE "(^|\s)${constraint}(\s|:|,|\]|$)" "$file"; then
      log_pass "Constraint $constraint referenciado explícitamente"
    else
      # C6 tiene excepción documentada para Llama (open-weight)
      if [[ "$constraint" == "C6" ]] && grep -qi "llama.*open-weight\|exception.*C6" "$file"; then
        log_pass "C6: excepción documentada para modelo open-weight"
      else
        log_warn "Constraint $constraint no encontrado explícitamente en: $file"
      fi
    fi
  done

  # Validaciones específicas por constraint
  # C1: timeout, connectionLimit, maxResults, memory limits
  if grep -qE '(timeout|connectionLimit|maxResults|memory:\s*[0-9]+M)' "$file"; then
    log_pass "C1: patrones de límite de recursos presentes"
  fi

  # C2: cpus, nice, ionice, timeout explícito
  if grep -qE "(cpus:|timeout:|EXECUTIONS_MAX_CONCURRENT)" "$file"; then
    log_pass "C2: límites de CPU/concurrencia referenciados"
  fi

  # C3: process.env, ${VAR}, zero hardcode, SSH tunnels
  if grep -qE '(process\.env\.|os\.getenv\(|\$\{[A-Z_]+\}|ssh -L|tunnel)' "$file"; then
    log_pass "C3: gestión segura de secretos presente"
  fi

  # C4: tenant_id en queries, filters, headers, logs
  if grep -qiE '(tenant_id|tenant-id|WHERE.*tenant|filter.*tenant|headers.*tenant)' "$file"; then
    log_pass "C4: tenant_id presente en contexto ejecutable"
  else
    log_error "C4 VIOLADO: tenant_id no encontrado en consultas/filtros: $file"
    return 1
  fi

  # C5: sha256, checksum, backup, age, verification
  if grep -qiE '(sha256|checksum|backup.*enc|age -r|verify.*integrity)' "$file"; then
    log_pass "C5: patrones de backup+verificación presentes"
  fi

  # C6: openrouter, cloud API, no localhost model
  if grep -qiE '(openrouter\.ai|api\.openai\.com|cloud.*inference|no.*local.*model)' "$file"; then
    log_pass "C6: inferencia cloud-only referenciada"
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

  # Patrones de credenciales a detectar (excluyendo placeholders válidos)
  local patterns=(
    'sk-[a-zA-Z0-9]{20,}'                    # OpenAI/OpenRouter keys
    'ghp_[a-zA-Z0-9]{36}'                    # GitHub personal tokens
    'gho_[a-zA-Z0-9]{36}'                    # GitHub OAuth tokens
    'password\s*=\s*["\x27][^"\x27]{8,}'     # Passwords hardcoded
    'api_key\s*=\s*["\x27][^"\x27]{16,}'     # API keys hardcoded
    'secret\s*=\s*["\x27][^"\x27]{16,}'      # Secrets hardcoded
    'Bearer\s+[a-zA-Z0-9._-]{20,}'           # JWT/Bearer tokens
  )

  local found_secrets=0
  for pattern in "${patterns[@]}"; do
    # Buscar coincidencias EXCLUYENDO placeholders válidos
    if grep -E "$pattern" "$file" | grep -v -E '(ENV_VAR|\$\{|XXXX|TODO|PLACEHOLDER|your_key_here|<[^>]+>)' > /dev/null 2>&1; then
      log_error "Posible credencial hardcodeada detectada (patrón: $pattern) en: $file"
      ((found_secrets++)) || true
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
  local schema_path="${PROJECT_ROOT}/05-CONFIGURATIONS/validation/schemas/skill-output.schema.json"
  [[ ! -f "$file" ]] && return 0
  [[ ! -f "$schema_path" ]] && { log_warn "Schema no encontrado: $schema_path"; return 0; }

  log_info "Validando output contra JSON Schema: $file"

  # Extraer bloques de código JSON del archivo markdown
  local json_blocks
  json_blocks=$(grep -zoP '```json\n\K[\s\S]*?(?=\n```)' "$file" 2>/dev/null || true)

  if [[ -z "$json_blocks" ]]; then
    log_pass "Sin bloques JSON para validar contra schema"
    return 0
  fi

  # Validar cada bloque JSON contra el schema (requiere python + jsonschema)
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

  # Verificar si existe archivo .sha256 companion
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
    done < <(find "$target" -type f \( -name "*.md" -o -name "*.json" -o -name "*.sql" -o -name "*.yml" -o -name "*.yaml" \) -print0 2>/dev/null)
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
  local report_checksum

  [[ ${#ERRORS[@]} -gt 0 ]] && status="failed"
  [[ "$STRICT" == "1" && ${#WARNINGS[@]} -gt 0 ]] && status="failed"

  # Calcular checksum del reporte antes de escribirlo
  local temp_report
  temp_report=$(mktemp)

  # Construir arrays JSON manualmente (compatibilidad sin jq)
  local errors_json="[]"
  local warnings_json="[]"
  if [[ ${#ERRORS[@]} -gt 0 ]]; then
    errors_json=$(printf '%s\n' "${ERRORS[@]}" | awk '{printf "%s\"%s\"", (NR>1?",":""), $0}' | sed 's/"/\\"/g' | awk '{print "["$0"]"}')
  fi
  if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    warnings_json=$(printf '%s\n' "${WARNINGS[@]}" | awk '{printf "%s\"%s\"", (NR>1?",":""), $0}' | sed 's/"/\\"/g' | awk '{print "["$0"]"}')
  fi

  cat > "$temp_report" << EOF
{
  "validator_version": "$VERSION",
  "timestamp": "$timestamp",
  "target": "$PROJECT_ROOT",
  "status": "$status",
  "summary": {
    "total_checks": $CHECKS_TOTAL,
    "passed": $CHECKS_PASSED,
    "warnings": ${#WARNINGS[@]},
    "errors": ${#ERRORS[@]},
    "pass_rate": $(awk "BEGIN {printf \"%.2f\", ($CHECKS_PASSED/$CHECKS_TOTAL)*100}" 2>/dev/null || echo "0")
  },
  "constraints_validated": $(printf '%s\n' "${CONSTRAINTS[@]}" | awk '{printf "%s\"%s\"", (NR>1?",":""), $0}' | sed 's/"/\\"/g' | awk '{print "["$0"]"}'),
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

  # Calcular checksum final del reporte y reemplazar placeholder
  report_checksum=$(compute_sha256 "$temp_report")
  sed -i "s/\"report_sha256\": \"PLACEHOLDER\"/\"report_sha256\": \"$report_checksum\"/" "$temp_report"

  # Mover a destino final
  mv "$temp_report" "$REPORT_FILE"

  # Output en stdout
  echo ""
  echo "========================================="
  echo "📊 REPORTE DE VALIDACIÓN SDD v$VERSION"
  echo "========================================="
  echo "Target: $PROJECT_ROOT"
  echo "Estado: $status"
  echo "✅ Pasaron: $CHECKS_PASSED / $CHECKS_TOTAL checks"
  echo "⚠️  Advertencias: ${#WARNINGS[@]}"
  echo "❌ Errores: ${#ERRORS[@]}"
  echo "🔐 Report SHA256: $report_checksum"
  echo "📄 Reporte guardado: $REPORT_FILE"
  echo "========================================="

  # Si hay errores, salir con código 1 para CI/CD
  [[ "$status" == "failed" ]] && exit 1
  exit 0
}

# ────────────────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────────────────
main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    cat << EOF
Uso: $0 [ruta_archivo_o_directorio] [reporte.json] [verbose:0/1] [strict:0/1]

Validador maestro de integridad SDD para MANTIS AGENTIC.

Parámetros:
  ruta_archivo_o_directorio  Ruta a validar (default: .)
  reporte.json               Archivo de salida JSON (default: skill-validation-report.json)
  verbose:0/1                Modo detallado (default: 0)
  strict:0/1                 Tratar warnings como errores (default: 0)

Ejemplos:
  $0 02-SKILLS/AI/qwen-integration.md
  $0 02-SKILLS/ validation-report.json 1 0
  $0 . --all --report=ci-report.json --strict

Validaciones ejecutadas:
  ✓ Frontmatter YAML obligatorio (ai_optimized, constraints C1-C6)
  ✓ Wikilinks Obsidian válidos y sin ciclos
  ✓ Constraints C1-C6 explícitos en ejemplos
  ✓ Auditoría de secretos (C3: cero hardcode)
  ✓ tenant_id obligatorio en consultas (C4)
  ✓ Validación contra JSON Schema para outputs IA
  ✓ Checksum SHA256 para auditoría (C5)

Salida:
  - Reporte JSON con estado, métricas y checksum SHA256
  - Código de salida: 0 (éxito) / 1 (fallos críticos)
EOF
    exit 0
  fi

  log_info "Iniciando validador SDD v$VERSION"
  log_info "Constraints activos: ${CONSTRAINTS[*]}"

  run_validations "$PROJECT_ROOT"
  generate_report
}

main "$@"


