#!/usr/bin/env bash
#---
# metadata_version: 2.0
# sdd_compliant: true
# ai_parser_compatible: true
# purpose: "Validación de frontmatter YAML obligatorio y estructura de metadatos (Constraint C5)"
# constraint: "C5: Metadatos canónicos, rutas relativas válidas, versión semver, propósito documentado"
# output_format: "json + stdout + exit code para CI/CD"
# ---
# ============================================================================
# VALIDATE-FRONTMATTER.SH v2.0.2 — EXTRACTOR POSIX-COMPLIANT
# Fix crítico: Parser agnóstico a \r\n, espacios variables y versiones de awk.
# ============================================================================
set -euo pipefail

readonly VERSION="2.0.2"
readonly SCRIPT_NAME="$(basename "$0")"
readonly PROJECT_ROOT="${1:-.}"
readonly REPORT_FILE="${2:-frontmatter-validation-report.json}"
readonly VERBOSE="${3:-0}"
readonly STRICT="${4:-0}"

declare -a FAILURES=()
declare -a WARNINGS=()
declare -i FILES_CHECKED=0
declare -i PASSED=0
declare -i FAILED=0

# ────────────────────────────────────────────────────────────────────────────
# UTILIDADES
# ────────────────────────────────────────────────────────────────────────────
log_info() { [[ "$VERBOSE" == "1" ]] && echo "[INFO] $*" || true; }
log_fail() { echo "[FM-FAIL] $*" >&2; FAILURES+=("$*"); }
log_warn() { echo "[FM-WARN] $*" >&2; WARNINGS+=("$*"); }

# 🔍 Extraer bloque frontmatter (robusto a #---, # ---, \r, shebang previo)
extract_frontmatter() {
  local file="$1"
  local ext="${file##*.}"
  local tmp_fm
  tmp_fm=$(mktemp)
  
  # Eliminar \r y extraer primer bloque entre delimitadores
  tr -d '\r' < "$file" | awk -v ext="$ext" '
    BEGIN { count=0; in_fm=0 }
    {
      if (ext ~ /sh|bash/) {
        if ($0 ~ /^#[[:space:]]*---/) { count++; next }
      } else {
        if ($0 ~ /^---/) { count++; next }
      }
      
      if (count == 1) { in_fm = 1 }
      if (count == 2) { exit }
      
      if (in_fm) {
        if (ext ~ /sh|bash/) sub(/^#[[:space:]]*/, "")
        print
      }
    }
  ' > "$tmp_fm" 2>/dev/null || true
  
  echo "$tmp_fm"
}

# 🔍 Obtener valor YAML de una clave
get_yaml_value() {
  local fm_file="$1"
  local key="$2"
  
  grep -m1 "^${key}:" "$fm_file" 2>/dev/null | \
    sed "s/^${key}:[[:space:]]*//" | \
    sed 's/^["'"'"']//; s/["'"'"']$//' | \
    sed 's/[[:space:]]*$//'
}

# 🔍 Validar versión semver estricta
validate_semver() {
  local ver="$1"
  [[ "$ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

# 🔍 Resolver ruta relativa contra el root del repo
resolve_path() {
  local rel_path="$1"
  local base_dir
  base_dir=$(cd "$(dirname "$PROJECT_ROOT")" && pwd)
  
  [[ "$rel_path" != /* ]] && rel_path="${base_dir}/${rel_path}"
  echo "$rel_path"
}

# ────────────────────────────────────────────────────────────────────────────
# VALIDACIÓN POR ARCHIVO
# ────────────────────────────────────────────────────────────────────────────
validate_file() {
  local file="$1"
  local ext="${file##*.}"
  
  # Extensiones que NO requieren frontmatter por defecto
  local skip_exts=("tf" "tfvars" "json" "yml" "yaml" "log" "gitignore")
  for skip in "${skip_exts[@]}"; do
    [[ "$ext" == "$skip" ]] && return 0
  done
  
  ((FILES_CHECKED++)) || true
  log_info "Validando frontmatter: $file"
  
  local fm_file
  fm_file=$(extract_frontmatter "$file")
  
  if [[ ! -s "$fm_file" ]]; then
    log_fail "Falta apertura YAML (--- o # ---) en: $file"
    rm -f "$fm_file"
    ((FAILED++)) || true
    return 1
  fi
  
  local file_passed=true
  
  # 1. Campo obligatorio: purpose
  local purpose
  purpose=$(get_yaml_value "$fm_file" "purpose")
  if [[ -z "$purpose" ]]; then
    log_fail "Campo obligatorio ausente 'purpose' en: $file"
    file_passed=false
  fi
  
  # 2. Versión semver válida
  local version
  version=$(get_yaml_value "$fm_file" "version")
  if [[ -n "$version" ]] && ! validate_semver "$version"; then
    log_fail "Versión no semántica válida ('$version') en: $file"
    file_passed=false
  fi
  
  # 3. related_files (validar existencia)
  local rel_files
  rel_files=$(grep -A100 "^related_files:" "$fm_file" 2>/dev/null | sed -n '/^- /p' | sed 's/^- //' | sed 's/["'"'"']//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  
  if [[ -n "$rel_files" ]]; then
    while IFS= read -r ref; do
      [[ -z "$ref" ]] && continue
      local resolved
      resolved=$(resolve_path "$ref")
      if [[ ! -f "$resolved" ]]; then
        log_fail "related_files roto: '$ref' no encontrado desde: $file"
        file_passed=false
      fi
    done <<< "$rel_files"
  fi
  
  rm -f "$fm_file"
  
  if [[ "$file_passed" == "true" ]]; then
    ((PASSED++)) || true
  else
    ((FAILED++)) || true
  fi
}

# ────────────────────────────────────────────────────────────────────────────
# ESCANEO Y REPORTE
# ────────────────────────────────────────────────────────────────────────────
scan_dir() {
  local dir="${1:-.}"
  while IFS= read -r -d '' file; do
    validate_file "$file"
  done < <(find "$dir" -type f \( -name "*.md" -o -name "*.sh" -o -name "*.bash" \) -print0 2>/dev/null)
}

generate_report() {
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  local status="passed"
  [[ $FAILED -gt 0 ]] && status="failed"
  
  local failures_json="[]"
  if [[ ${#FAILURES[@]} -gt 0 ]]; then
    failures_json=$(printf '%s\n' "${FAILURES[@]}" | jq -R -s -c 'split("\n") | map(select(length > 0))' 2>/dev/null || echo "[]")
  fi
  
  local temp_report
  temp_report=$(mktemp)
  
  cat > "$temp_report" << EOF
{
  "validator_version": "$VERSION",
  "timestamp": "$timestamp",
  "target": "$PROJECT_ROOT",
  "status": "$status",
  "summary": {
    "files_checked": $FILES_CHECKED,
    "passed": $PASSED,
    "failed": $FAILED,
    "warnings": ${#WARNINGS[@]}
  },
  "failures": $failures_json,
  "recommendations": [
    "Añadir 'purpose' descriptivo al frontmatter",
    "Usar formato semver estricto: version: 1.0.0",
    "Verificar rutas en related_files contra PROJECT_TREE.md",
    "Para .sh usar '# ---' comentado, para .md usar '---' puro"
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
  
  echo ""
  echo "========================================="
  echo "📄 VALIDACIÓN FRONTMATTER SDD v$VERSION"
  echo "========================================="
  echo "Target: $PROJECT_ROOT"
  echo "📁 Escaneados: $FILES_CHECKED"
  echo "✅ Aprobados: $PASSED"
  echo "❌ Rechazados: $FAILED"
  echo "⚠️ Advertencias: ${#WARNINGS[@]}"
  echo "Estado: $status"
  echo "🔐 Report SHA256: $report_sha"
  echo "📄 Reporte: $REPORT_FILE"
  echo "========================================="
  
  [[ $FAILED -gt 0 ]] && {
    echo ""; echo "⚠️  Errores críticos encontrados:"
    printf '  • %s\n' "${FAILURES[@]}"
  }
  
  [[ "$status" == "failed" && "$STRICT" == "1" ]] && exit 1
  exit 0
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo "Uso: $0 [ruta|archivo] [reporte.json] [verbose:0/1] [strict:0/1]"
    echo "Valida frontmatter YAML en .md y .sh (usa # ---). Omite .tf/.json/.yml."
    exit 0
  fi
  
  log_info "Iniciando validación de frontmatter SDD v$VERSION"
  
  if [[ -f "$PROJECT_ROOT" ]]; then
    validate_file "$PROJECT_ROOT"
  elif [[ -d "$PROJECT_ROOT" ]]; then
    scan_dir "$PROJECT_ROOT"
  else
    echo "[ERROR] Ruta no encontrada: $PROJECT_ROOT" >&2
    exit 1
  fi
  
  generate_report
}

main "$@"
