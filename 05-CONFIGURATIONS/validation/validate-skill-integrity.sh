#!/usr/bin/env bash
#---
# metadata_version: 2.1
# sdd_compliant: true
# ai_parser_compatible: true
# purpose: "Validación de integridad estructural de skills SDD (Constraint C5) - BUGFIX"
# ---
set -uo pipefail  # Quitamos 'set -e' para que 'grep' sin hallazgos no mate el script

readonly VERSION="2.0.1"
readonly SCRIPT_NAME="$(basename "$0")"
readonly TARGET="${1:-.}"
readonly REPORT_FILE="${2:-skill-validation-report.json}"

# 🔍 Detectar root del repo (fallback a pwd si no es git repo)
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

declare -a WARNINGS=()
declare -a ERRORS=()
declare -i CHECKS_PASSED=0
declare -i CHECKS_TOTAL=0
declare -i EXAMPLES_FOUND=0
declare -i BROKEN_LINKS=0

echo "🚀 Iniciando validación SDD v$VERSION en: $TARGET"

# ────────────────────────────────────────────────────────────────────────────
# FUNCIONES SEGURAS
# ────────────────────────────────────────────────────────────────────────────

# 🔍 Contar ejemplos (seguro si no hay match)
count_examples() {
  local file="$1"
  local count
  count=$(grep -cE '(✅|❌|🔧)' "$file" 2>/dev/null || echo "0")
  echo "$count"
}

# 🔍 Verificar campo en frontmatter (seguro si no hay match)
has_field() {
  local file="$1"
  local key="$2"
  grep -qE "^${key}:" "$file" 2>/dev/null || grep -qE "^# ${key}:" "$file" 2>/dev/null
}

# 🔍 Resolver wikilink [[ruta]]
resolve_wikilink() {
  local link="$1"
  local raw="${link#[[}"
  raw="${raw%]]}"
  raw=$(echo "$raw" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  
  [[ -z "$raw" ]] && return 0
  
  local resolved
  if [[ "$raw" == /* ]]; then
    resolved="${REPO_ROOT}${raw}"
  else
    # Si TARGET es un archivo, usamos su directorio como base
    local base_dir
    base_dir=$(dirname "$(realpath -m "$TARGET")")
    resolved="${base_dir}/${raw}"
  fi
  
  realpath -m "$resolved" 2>/dev/null || echo "$resolved"
}

# ────────────────────────────────────────────────────────────────────────────
# VALIDACIÓN
# ────────────────────────────────────────────────────────────────────────────
validate_skill() {
  local file="$1"
  local basename
  basename=$(basename "$file")
  
  echo "📄 Analizando: $basename"

  # 1. Frontmatter mínimo
  CHECKS_TOTAL=$((CHECKS_TOTAL + 2))
  if has_field "$file" "ai_optimized"; then
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
  else
    WARNINGS+=("Frontmatter sin 'ai_optimized'")
  fi
  if has_field "$file" "validation_command"; then
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
  else
    WARNINGS+=("Frontmatter sin 'validation_command'")
  fi
  
  # 2. Wikilinks canónicos (Regex corregido)
  # Extraemos [[...]] asegurando que no sean vacíos
  local wikilinks
  wikilinks=$(grep -oE '\[\[.+\]\]' "$file" 2>/dev/null | sort -u || true)
  
  if [[ -n "$wikilinks" ]]; then
    while IFS= read -r link; do
      [[ -z "$link" ]] && continue
      local resolved
      resolved=$(resolve_wikilink "$link")
      
      # Ignorar si parece directorio (termina en /) o URL
      [[ "$resolved" == */ ]] && continue
      [[ "$resolved" == http* ]] && continue
      
      if [[ -f "$resolved" ]]; then
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
      else
        WARNINGS+=("Wikilink roto: $link → $resolved")
        BROKEN_LINKS=$((BROKEN_LINKS + 1))
      fi
    done <<< "$wikilinks"
  fi
  
  # 3. Conteo de ejemplos
  EXAMPLES_FOUND=$(count_examples "$file")
  CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
  if [[ $EXAMPLES_FOUND -ge 5 ]]; then
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
  else
    WARNINGS+=("Ejemplos insuficientes: $EXAMPLES_FOUND/5")
  fi
  
  # 4. Validación contextual C1-C6 (Solo archivos técnicos, no índices)
  if [[ "$basename" != *INDEX* && "$basename" != *README* ]]; then
    for c in C1 C2 C3 C4 C5 C6; do
      CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
      if grep -qE "$c[:\[]" "$file" 2>/dev/null; then
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
      else
        WARNINGS+=("Constraint $c no referenciado")
      fi
    done
  fi
}

# ────────────────────────────────────────────────────────────────────────────
# REPORTE
# ────────────────────────────────────────────────────────────────────────────
generate_report() {
  local status="passed"
  [[ ${#WARNINGS[@]} -gt 0 && $CHECKS_PASSED -lt $CHECKS_TOTAL ]] && status="warnings"
  
  cat > "$REPORT_FILE" << EOF
{
  "validator_version": "$VERSION",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "target": "$TARGET",
  "status": "$status",
  "summary": {
    "checks_passed": $CHECKS_PASSED,
    "checks_total": $CHECKS_TOTAL,
    "examples_found": $EXAMPLES_FOUND,
    "broken_links": $BROKEN_LINKS,
    "warnings": ${#WARNINGS[@]}
  }
}
EOF

  echo "========================================="
  echo "📊 REPORTE FINAL SDD v$VERSION"
  echo "========================================="
  echo "✅ Checks: $CHECKS_PASSED / $CHECKS_TOTAL"
  echo "🔗 Links rotos: $BROKEN_LINKS"
  echo "⚠️  Advertencias: ${#WARNINGS[@]}"
  echo "📄 Reporte: $REPORT_FILE"
  echo "========================================="
}

# ────────────────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────────────────
if [[ -f "$TARGET" ]]; then
  validate_skill "$TARGET"
elif [[ -d "$TARGET" ]]; then
  find "$TARGET" -type f -name "*.md" -print0 2>/dev/null | while IFS= read -r -d '' file; do
    validate_skill "$file"
  done
else
  echo "❌ Ruta no encontrada: $TARGET"
  exit 1
fi

generate_report
