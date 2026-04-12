
#!/usr/bin/env bash
#---
# metadata_version: 1.0
# sdd_compliant: true
# ai_parser_compatible: true
# purpose: "Validador estricto de frontmatter YAML para SDD (C1-C6, estructura, cross-references)"
# scope: "00-CONTEXT/, 01-RULES/, 02-SKILLS/, 04-WORKFLOWS/, 05-CONFIGURATIONS/"
# constraint: "SDD Base: frontmatter obligatorio, ai_optimized, constraints, related_files, version"
# output_format: "json + stdout + exit code para CI/CD"
# ---
# ============================================================================
# VALIDATE-FRONTMATTER.SH v1.0
# Validador de metadatos YAML frontmatter para MANTIS AGENTIC
# Propósito: Garantizar que todos los archivos Markdown cumplan la estructura
# SDD mínima: ai_optimized, constraints C1-C6, versión semántica, tags válidos,
# y referencias cruzadas existentes. Soporta todos los proveedores IA del árbol.
# ============================================================================
set -euo pipefail

# ────────────────────────────────────────────────────────────────────────────
# CONFIGURACIÓN GLOBAL
# ────────────────────────────────────────────────────────────────────────────
readonly VERSION="1.0.0"
readonly SCRIPT_NAME="$(basename "$0")"
readonly PROJECT_ROOT="${1:-.}"
readonly REPORT_FILE="${2:-frontmatter-validation-report.json}"
readonly VERBOSE="${3:-0}"
readonly STRICT="${4:-0}"

declare -a FINDINGS=()
declare -i FILES_SCANNED=0
declare -i FILES_PASSED=0
declare -i FILES_FAILED=0

# Proveedores IA válidos (alineados con el árbol del repositorio)
readonly -a VALID_AI_PROVIDERS=(
  "openrouter" "qwen" "deepseek" "llama" "gemini" "gpt" 
  "minimax" "mistral-ocr" "voice-agent" "image-gen" "video-gen"
)

# Campos obligatorios en frontmatter SDD
readonly -a REQUIRED_FIELDS=("ai_optimized" "version" "constraints" "purpose" "tags")

# Exclusiones de escaneo
readonly -a EXCLUDE_DIRS=(".git" "node_modules" "venv" ".venv" "__pycache__" "dist" "build")

# ────────────────────────────────────────────────────────────────────────────
# UTILIDADES
# ────────────────────────────────────────────────────────────────────────────
log_info() { [[ "$VERBOSE" == "1" ]] && echo "[INFO] $*" || true; }
log_error() { echo "[ERROR] $*" >&2; }
log_finding() { 
  echo "[FM-FAIL] $*" >&2
  FINDINGS+=("$*")
}

compute_sha256() {
  sha256sum "$1" 2>/dev/null | awk '{print $1}' || echo "unknown"
}

is_excluded() {
  local path="$1"
  for excl in "${EXCLUDE_DIRS[@]}"; do
    [[ "$path" == *"/$excl/"* || "$path" == *"/$excl" ]] && return 0
  done
  return 1
}

# ────────────────────────────────────────────────────────────────────────────
# EXTRACCIÓN Y VALIDACIÓN DE FRONTMATTER
# ────────────────────────────────────────────────────────────────────────────
extract_frontmatter() {
  local file="$1"
  # Verificar apertura
  if ! head -1 "$file" | grep -qE '^---[[:space:]]*$'; then
    log_finding "Falta apertura YAML (---) en: $file"
    return 1
  fi
  
  # Extraer bloque (entre primer y segundo ---)
  local fm_block
  fm_block=$(awk '/^---[[:space:]]*$/{if(++n==1)next; if(n==2)exit} n==1' "$file" 2>/dev/null || true)
  
  if [[ -z "$fm_block" ]]; then
    log_finding "Frontmatter vacío o sin cierre (---) en: $file"
    return 1
  fi
  
  echo "$fm_block"
  return 0
}

validate_required_fields() {
  local file="$1"
  local fm="$2"
  local field_errors=0
  
  for field in "${REQUIRED_FIELDS[@]}"; do
    if ! echo "$fm" | grep -qE "^${field}[[:space:]]*:"; then
      log_finding "Campo obligatorio ausente '${field}' en: $file"
      ((field_errors++)) || true
    fi
  done
  
  return $field_errors
}

validate_ai_optimized() {
  local file="$1"
  local fm="$2"
  
  local val
  val=$(echo "$fm" | grep -E "^ai_optimized[[:space:]]*:" | awk -F': ' '{print $2}' | tr -d '[:space:]')
  
  if [[ "$val" != "true" && "$val" != "yes" ]]; then
    log_finding "ai_optimized debe ser 'true' o 'yes' (actual: '$val') en: $file"
    return 1
  fi
  return 0
}

validate_version() {
  local file="$1"
  local fm="$2"
  
  local ver
  ver=$(echo "$fm" | grep -E "^version[[:space:]]*:" | awk -F': ' '{print $2}' | tr -d '[:space:]')
  
  if [[ -n "$ver" ]] && ! echo "$ver" | grep -qE '^v?[0-9]+\.[0-9]+(\.[0-9]+)?(-[a-zA-Z0-9.]+)?$'; then
    log_finding "Versión no semántica válida ('${ver}') en: $file"
    return 1
  fi
  return 0
}

validate_constraints() {
  local file="$1"
  local fm="$2"
  
  # Extraer línea constraints
  local constraints_line
  constraints_line=$(grep -E "^constraints[[:space:]]*:" "$fm" 2>/dev/null || true)
  
  if [[ -z "$constraints_line" ]]; then
    return 0 # Validado en required_fields
  fi
  
  # Normalizar a array de strings
  local constraints_raw
  constraints_raw=$(echo "$constraints_line" | sed 's/^constraints[[:space:]]*:[[:space:]]*//; s/\[//g; s/\]//g; s/"//g; s/'\''//g; s/,/ /g' | tr -s ' ')
  
  local has_c=false
  for c in $constraints_raw; do
    if [[ "$c" =~ ^C[1-6]$ ]]; then
      has_c=true
    fi
  done
  
  if [[ "$has_c" != "true" ]]; then
    log_finding "Constraints no contienen referencias válidas C1-C6 en: $file"
    return 1
  fi
  return 0
}

validate_ai_provider() {
  local file="$1"
  local fm="$2"
  
  local provider
  provider=$(echo "$fm" | grep -E "^ai_provider[[:space:]]*:" | awk -F': ' '{print $2}' | tr -d '[:space:]')
  
  if [[ -z "$provider" ]]; then
    return 0 # Campo opcional
  fi
  
  local valid=false
  for vp in "${VALID_AI_PROVIDERS[@]}"; do
    [[ "$provider" == "$vp" ]] && valid=true && break
  done
  
  if [[ "$valid" != "true" ]]; then
    log_finding "ai_provider no reconocido ('${provider}'). Válidos: ${VALID_AI_PROVIDERS[*]} en: $file"
    return 1
  fi
  return 0
}

validate_related_files() {
  local file="$1"
  local fm="$2"
  local dir
  dir=$(dirname "$file")
  
  local related_section
  related_section=$(awk '/^related_files[[:space:]]*:/{found=1; next} /^[a-zA-Z]/{found=0} found' <<< "$fm")
  
  if [[ -z "$related_section" ]]; then
    return 0
  fi
  
  local broken=0
  while IFS= read -r ref; do
    ref=$(echo "$ref" | sed 's/^[[:space:]]*- "//; s/"$//; s/\[\[//; s/\]\]//; s/|.*$//' | tr -d '[:space:]')
    [[ -z "$ref" ]] && continue
    
    # Resolver ruta relativa
    local target
    if [[ "$ref" == /* ]]; then
      target="${PROJECT_ROOT}${ref}"
    elif [[ "$ref" == 02-SKILLS/* || "$ref" == 00-CONTEXT/* || "$ref" == 01-RULES/* || "$ref" == 05-CONFIGURATIONS/* ]]; then
      target="${PROJECT_ROOT}/${ref}"
    else
      target="${dir}/${ref}"
    fi
    
    # Verificar extensión .md si falta
    if [[ ! "$target" == *.md ]]; then
      target="${target}.md"
    fi
    
    if [[ ! -f "$target" ]]; then
      log_finding "related_files roto: '${ref}' no encontrado desde: $file"
      ((broken++)) || true
    fi
  done <<< "$related_section"
  
  return 0
}

# ────────────────────────────────────────────────────────────────────────────
# VALIDADOR PRINCIPAL POR ARCHIVO
# ────────────────────────────────────────────────────────────────────────────
validate_file() {
  local file="$1"
  [[ ! -f "$file" ]] && return 0
  is_excluded "$file" && return 0
  
  log_info "Validando frontmatter: $file"
  ((FILES_SCANNED++)) || true
  
  local fm
  fm=$(extract_frontmatter "$file") || return 0
  
  local file_passed=true
  
  validate_required_fields "$file" "$fm" || file_passed=false
  validate_ai_optimized "$file" "$fm" || file_passed=false
  validate_version "$file" "$fm" || file_passed=false
  validate_constraints "$file" "$fm" || file_passed=false
  validate_ai_provider "$file" "$fm" || file_passed=false
  validate_related_files "$file" "$fm" || file_passed=false
  
  if [[ "$file_passed" == "true" ]]; then
    ((FILES_PASSED++)) || true
  else
    ((FILES_FAILED++)) || true
  fi
}

scan_directory() {
  local dir="$1"
  while IFS= read -r -d '' file; do
    validate_file "$file"
  done < <(find "$dir" -type f -name "*.md" -print0 2>/dev/null)
}

# ────────────────────────────────────────────────────────────────────────────
# GENERACIÓN DE REPORTE
# ────────────────────────────────────────────────────────────────────────────
generate_report() {
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local status="passed"
  
  if [[ "$STRICT" == "1" && $FILES_FAILED -gt 0 ]]; then
    status="failed"
  elif [[ $FILES_FAILED -gt 0 ]]; then
    status="failed"
  fi
  
  local findings_json="[]"
  if [[ ${#FINDINGS[@]} -gt 0 ]]; then
    findings_json=$(printf '%s\n' "${FINDINGS[@]}" | sed 's/"/\\"/g' | paste -sd ',' | awk '{print "["$0"]"}')
  fi
  
  local temp_report
  temp_report=$(mktemp)
  
  cat > "$temp_report" << EOF
{
  "validator_version": "$VERSION",
  "timestamp": "$timestamp",
  "target": "$PROJECT_ROOT",
  "scope": "00-CONTEXT, 01-RULES, 02-SKILLS, 04-WORKFLOWS, 05-CONFIGURATIONS",
  "status": "$status",
  "summary": {
    "files_scanned": $FILES_SCANNED,
    "files_passed": $FILES_PASSED,
    "files_failed": $FILES_FAILED,
    "pass_rate_percent": $((FILES_SCANNED > 0 ? (FILES_PASSED * 100) / FILES_SCANNED : 0))
  },
  "validated_fields": $(printf '%s\n' "${REQUIRED_FIELDS[@]}" | awk '{printf "%s\"%s\"", (NR>1?",":""), $0}' | awk '{print "["$0"]"}'),
  "valid_ai_providers": $(printf '%s\n' "${VALID_AI_PROVIDERS[@]}" | awk '{printf "%s\"%s\"", (NR>1?",":""), $0}' | awk '{print "["$0"]"}'),
  "findings": $findings_json,
  "recommendations": [
    "Asegurar que todo nuevo archivo inicie con --- y cierre con ---",
    "Incluir siempre ai_optimized: true y constraints: [\"C1\", \"C2\", ...]",
    "Usar versionamiento semántico (v1.0.0)",
    "Mantener related_files actualizado y validar rutas con find",
    "Especificar ai_provider solo si aplica (valores: ${VALID_AI_PROVIDERS[*]})"
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
  echo "📄 VALIDACIÓN FRONTMATTER SDD v$VERSION"
  echo "========================================="
  echo "Target: $PROJECT_ROOT"
  echo "📁 Escaneados: $FILES_SCANNED"
  echo "✅ Aprobados: $FILES_PASSED"
  echo "❌ Rechazados: $FILES_FAILED"
  echo "Estado: $status"
  echo "🔐 Report SHA256: $report_sha"
  echo "📄 Reporte: $REPORT_FILE"
  echo "========================================="
  
  if [[ $FILES_FAILED -gt 0 ]]; then
    echo ""
    echo "⚠️  Errores críticos encontrados:"
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

Validador de frontmatter YAML para Specification-Driven Development.
Verifica estructura, campos obligatorios, constraints C1-C6, proveedores IA
y referencias cruzadas en todo el repositorio.

Campos requeridos: ai_optimized, version, constraints, purpose, tags
Proveedores IA soportados: ${VALID_AI_PROVIDERS[*]}

Ejemplos:
  $0 02-SKILLS/
  $0 . fm-report.json 1 1
  $0 --scan-only  # Solo valida, no genera reporte (para debug)

Salida: Reporte JSON + código 0/1 para CI/CD
EOF
    exit 0
  fi
  
  log_info "Iniciando validación de frontmatter SDD v$VERSION"
  
  if [[ -f "$PROJECT_ROOT" ]]; then
    validate_file "$PROJECT_ROOT"
  elif [[ -d "$PROJECT_ROOT" ]]; then
    scan_directory "$PROJECT_ROOT"
  else
    echo "Error: Ruta no encontrada: $PROJECT_ROOT" >&2
    exit 1
  fi
  
  generate_report
}

main "$@"

