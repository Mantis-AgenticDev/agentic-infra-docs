#!/usr/bin/env bash
#---
# metadata_version: 2.0.1
# sdd_compliant: true
# ai_parser_compatible: true
# purpose: "Validación general contra especificaciones SDD (estructura, constraints, ejemplos)"
# ---
set -uo pipefail

readonly VERSION="2.0.1"
readonly TARGET="${1:-.}"
readonly REPORT_FILE="${2:-validation-report.json}"

declare -i PASSED=0
declare -i WARNINGS=0
declare -i ERRORS=0
declare -a FINDINGS=()

log_info() { echo "[INFO] $*" >&2; }

record_check() {
  local name="$1"
  local severity="$2"
  case "$severity" in
    0) ((PASSED++)) ;;
    1) ((WARNINGS++)); FINDINGS+=("[WARN] $name") ;;
    2) ((ERRORS++)); FINDINGS+=("[ERROR] $name") ;;
  esac
}

validate_file() {
  local file="$1"
  local ext="${file##*.}"
  
  log_info "Validando especificaciones: $file"
  
  [[ ! -f "$file" ]] && { record_check "Archivo no encontrado" 2; return; }
  [[ ! -s "$file" ]] && { record_check "Archivo vacío" 2; return; }
  record_check "Archivo válido y no vacío" 0
  
  # 1. Shebang (solo scripts)
  if [[ "$ext" == "sh" || "$ext" == "bash" ]]; then
    head -1 "$file" | grep -q "^#!/" && record_check "Shebang presente" 0 || record_check "Shebang ausente" 1
  fi
  
  # 2. Metadatos/Frontmatter
  grep -qE "^---$|^# ---$" "$file" 2>/dev/null && record_check "Bloque de metadatos presente" 0 || record_check "Bloque de metadatos ausente" 1
  
  # 3. Constraints C1-C8
  for c in C1 C2 C3 C4 C5 C6 C7 C8; do
    grep -qE "$c[:\[]" "$file" 2>/dev/null && record_check "$c referenciado" 0 || record_check "$c no referenciado" 1
  done
  
  # 🔐 4. Conteo de ejemplos (BLINDADO contra \r, espacios y grep sin match)
  local raw_count
  raw_count=$(grep -cE '(✅|❌|🔧)' "$file" 2>/dev/null || true)
  local examples="${raw_count//[^0-9]/}"
  [[ -z "$examples" ]] && examples=0

  if (( examples >= 5 )); then
    record_check "Ejemplos suficientes (≥5)" 0
  elif (( examples > 0 )); then
    record_check "Ejemplos insuficientes ($examples/5)" 1
  else
    record_check "Sin ejemplos documentados" 1
  fi
  
  # 5. Validation Command
  grep -qE "validation_command:" "$file" 2>/dev/null && record_check "validation_command declarado" 0 || record_check "validation_command ausente" 1
  
  # 6. Determinismo
  grep -qE "date\s|uuidgen|timestamp" "$file" 2>/dev/null && record_check "Posible no-determinismo" 1 || record_check "Determinismo verificado" 0
}

generate_report() {
  local total=$((PASSED + WARNINGS + ERRORS))
  local status="passed"
  
  if (( ERRORS > 0 )); then
    status="failed"
  elif (( total == 0 )); then
    status="skipped"
  elif (( PASSED == 0 && WARNINGS > 0 )); then
    status="partial"
  fi
  
  local findings_json="[]"
  if (( ${#FINDINGS[@]} > 0 )); then
    findings_json=$(printf '%s\n' "${FINDINGS[@]}" | jq -R -s -c 'split("\n") | map(select(length>0))' 2>/dev/null || echo "[]")
  fi

  cat > "$REPORT_FILE" << EOF
{
  "validator_version": "$VERSION",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "target": "$TARGET",
  "status": "$status",
  "summary": { "passed": $PASSED, "warnings": $WARNINGS, "errors": $ERRORS, "total": $total },
  "findings": $findings_json
}
EOF

  echo ""
  echo "========================================="
  echo "📊 REPORTE DE VALIDACIÓN SDD v$VERSION"
  echo "========================================="
  echo "Estado: $status"
  echo "✅ Pasaron: $PASSED"
  echo "⚠️  Advertencias: $WARNINGS"
  echo "❌ Errores: $ERRORS"
  echo "📄 Reporte: $REPORT_FILE"
  echo "========================================="
  
  [[ "$status" == "failed" ]] && exit 1
  exit 0
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo "Uso: $0 [archivo] [reporte.json]"
    exit 0
  fi

  log_info "Iniciando validador SDD v$VERSION"
  
  if [[ -f "$TARGET" ]]; then
    validate_file "$TARGET"
  elif [[ -d "$TARGET" ]]; then
    find "$TARGET" -type f \( -name "*.md" -o -name "*.sh" -o -name "*.tf" -o -name "*.yml" -o -name "*.yaml" \) -print0 2>/dev/null | \
    while IFS= read -r -d '' f; do validate_file "$f"; done
  else
    echo "[ERROR] Ruta no encontrada: $TARGET" >&2; exit 1
  fi
  
  generate_report
}

main "$@"
