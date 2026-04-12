```bash
#!/usr/bin/env bash
#---
# metadata_version: 1.0
# sdd_compliant: true
# ai_parser_compatible: true
# purpose: "Validador de wikilinks Obsidian para integridad de navegación SDD"
# scope: "00-CONTEXT/, 01-RULES/, 02-SKILLS/, 04-WORKFLOWS/, 05-CONFIGURATIONS/"
# constraint: "Navegación IA: 0 enlaces rotos, detección de ciclos, resolución de rutas"
# output_format: "json + stdout + exit code para CI/CD"
# ---
# ============================================================================
# CHECK-WIKILINKS.SH v1.0
# Validador de enlaces Obsidian [[...]] para MANTIS AGENTIC
# Propósito: Detectar enlaces rotos, rutas mal resueltas, alias inválidos y
# referencias cíclicas en toda la documentación SDD. Compatible con espacios
# en nombres de directorio y resolución relativa/absoluta.
# ============================================================================
set -euo pipefail

# ────────────────────────────────────────────────────────────────────────────
# CONFIGURACIÓN GLOBAL
# ────────────────────────────────────────────────────────────────────────────
readonly VERSION="1.0.0"
readonly SCRIPT_NAME="$(basename "$0")"
readonly PROJECT_ROOT="${1:-.}"
readonly REPORT_FILE="${2:-wikilinks-validation-report.json}"
readonly VERBOSE="${3:-0}"
readonly STRICT="${4:-0}"

declare -a BROKEN_LINKS=()
declare -a CYCLE_LINKS=()
declare -i FILES_SCANNED=0
declare -i TOTAL_LINKS_FOUND=0
declare -i VALID_LINKS=0

# Directorios válidos para resolución automática
readonly -a KNOWN_PREFIXES=("00-CONTEXT" "01-RULES" "02-SKILLS" "04-WORKFLOWS" "05-CONFIGURATIONS")

# Directorios a excluir
readonly -a EXCLUDE_DIRS=(".git" "node_modules" "venv" ".venv" "__pycache__" "dist" "build" ".obsidian")

# ────────────────────────────────────────────────────────────────────────────
# UTILIDADES
# ────────────────────────────────────────────────────────────────────────────
log_info() { [[ "$VERBOSE" == "1" ]] && echo "[INFO] $*" || true; }
log_error() { echo "[ERROR] $*" >&2; }

is_excluded() {
  local path="$1"
  for excl in "${EXCLUDE_DIRS[@]}"; do
    [[ "$path" == *"/$excl/"* || "$path" == *"/$excl" ]] && return 0
  done
  return 1
}

json_escape() {
  local str="$1"
  str="${str//\\/\\\\}"
  str="${str//\"/\\\"}"
  str="${str//$'\n'/\\n}"
  str="${str//$'\t'/\\t}"
  echo "$str"
}

compute_sha256() {
  sha256sum "$1" 2>/dev/null | awk '{print $1}' || echo "unknown"
}

# ────────────────────────────────────────────────────────────────────────────
# RESOLUCIÓN DE RUTAS
# ────────────────────────────────────────────────────────────────────────────
resolve_wikilink_target() {
  local source_file="$1"
  local raw_link="$2"
  
  # Extraer ruta real (ignorar alias [[ruta|alias]])
  local target_path
  target_path=$(echo "$raw_link" | sed 's/|.*//' | tr -d '[:space:]')
  
  [[ -z "$target_path" ]] && return 1
  
  # Asegurar extensión .md
  if [[ ! "$target_path" == *.md ]]; then
    target_path="${target_path}.md"
  fi
  
  local resolved=""
  local source_dir
  source_dir=$(dirname "$source_file")
  
  # 1. Ruta absoluta desde root del repo
  if [[ "$target_path" == /* ]]; then
    resolved="${PROJECT_ROOT}${target_path}"
  # 2. Ruta con prefijo conocido (02-SKILLS/, etc.)
  elif [[ "$target_path" =~ ^(${KNOWN_PREFIXES[0]}|${KNOWN_PREFIXES[1]}|${KNOWN_PREFIXES[2]}|${KNOWN_PREFIXES[3]}|${KNOWN_PREFIXES[4]})/ ]]; then
    resolved="${PROJECT_ROOT}/${target_path}"
  # 3. Ruta relativa al archivo fuente
  else
    resolved="${source_dir}/${target_path}"
  fi
  
  # Normalizar ruta (resolver .., ./)
  if command -v realpath &>/dev/null; then
    resolved=$(realpath -m "$resolved" 2>/dev/null || echo "$resolved")
  else
    resolved=$(cd "$(dirname "$resolved")" 2>/dev/null && echo "$(pwd)/$(basename "$resolved")" || echo "$resolved")
  fi
  
  echo "$resolved"
  return 0
}

# ────────────────────────────────────────────────────────────────────────────
# VALIDACIÓN POR ARCHIVO
# ────────────────────────────────────────────────────────────────────────────
validate_file_wikilinks() {
  local file="$1"
  [[ ! -f "$file" ]] && return 0
  is_excluded "$file" && return 0
  
  log_info "Escaneando wikilinks: $file"
  ((FILES_SCANNED++)) || true
  
  # Extraer todos los wikilinks [[...]]
  local links
  links=$(grep -oE '\[\[[^]]+\]\]' "$file" 2>/dev/null | sed 's/^\[\[//; s/\]\]$//' || true)
  
  if [[ -z "$links" ]]; then
    return 0
  fi
  
  while IFS= read -r link; do
    ((TOTAL_LINKS_FOUND++)) || true
    
    # Resolver ruta objetivo
    local target
    target=$(resolve_wikilink_target "$file" "$link") || continue
    
    # 1. Verificar ciclo (auto-referencia directa)
    if [[ "$(realpath -m "$file" 2>/dev/null || echo "$file")" == "$(realpath -m "$target" 2>/dev/null || echo "$target")" ]]; then
      CYCLE_LINKS+=("$(json_escape "$file")|$(json_escape "$link")|self-reference")
      continue
    fi
    
    # 2. Verificar existencia
    if [[ -f "$target" ]]; then
      ((VALID_LINKS++)) || true
    else
      # Intentar búsqueda recursiva en directorio base como fallback
      local found_fallback
      found_fallback=$(find "${PROJECT_ROOT}" -name "$(basename "$target")" -type f 2>/dev/null | head -1 || true)
      
      if [[ -n "$found_fallback" ]]; then
        ((VALID_LINKS++)) || true
        log_info "[WARN] Enlace resuelto por fallback: [[${link}]] en $file → $found_fallback"
      else
        BROKEN_LINKS+=("$(json_escape "$file")|$(json_escape "$link")|target_not_found")
      fi
    fi
  done <<< "$links"
}

scan_directory() {
  local dir="$1"
  while IFS= read -r -d '' file; do
    validate_file_wikilinks "$file"
  done < <(find "$dir" -type f -name "*.md" -print0 2>/dev/null)
}

# ────────────────────────────────────────────────────────────────────────────
# GENERACIÓN DE REPORTE JSON
# ────────────────────────────────────────────────────────────────────────────
generate_report() {
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local status="passed"
  
  if [[ "$STRICT" == "1" && (${#BROKEN_LINKS[@]} -gt 0 || ${#CYCLE_LINKS[@]} -gt 0) ]]; then
    status="failed"
  elif [[ ${#BROKEN_LINKS[@]} -gt 0 ]]; then
    status="failed"
  elif [[ ${#CYCLE_LINKS[@]} -gt 0 ]]; then
    status="warnings"
  fi
  
  # Construir arrays JSON
  local broken_json="[]"
  if [[ ${#BROKEN_LINKS[@]} -gt 0 ]]; then
    broken_json=$(printf '{"source":"%s","link":"%s","error":"%s"}\n' "${BROKEN_LINKS[@]//|/","}" | paste -sd ',' | sed 's/}{/},{/g')
    broken_json="[${broken_json}]"
  fi
  
  local cycles_json="[]"
  if [[ ${#CYCLE_LINKS[@]} -gt 0 ]]; then
    cycles_json=$(printf '{"source":"%s","link":"%s","error":"%s"}\n' "${CYCLE_LINKS[@]//|/","}" | paste -sd ',' | sed 's/}{/},{/g')
    cycles_json="[${cycles_json}]"
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
    "files_scanned": $FILES_SCANNED,
    "total_links_found": $TOTAL_LINKS_FOUND,
    "valid_links": $VALID_LINKS,
    "broken_links": ${#BROKEN_LINKS[@]},
    "cyclic_references": ${#CYCLE_LINKS[@]}
  },
  "findings": {
    "broken": $broken_json,
    "cycles": $cycles_json
  },
  "resolution_rules": {
    "known_prefixes": $(printf '"%s",' "${KNOWN_PREFIXES[@]}" | sed 's/,$//' | awk '{print "["$0"]"}'),
    "auto_append_md": true,
    "fallback_recursive_search": true
  },
  "recommendations": [
    "Actualizar rutas relativas a rutas canónicas desde root del repo",
    "Eliminar auto-referencias directas [[mismo_archivo]]",
    "Usar alias [[ruta.md|texto legible]] para mejorar legibilidad sin afectar resolución",
    "Validar enlaces antes de merge con este script en modo --strict"
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
  echo "🔗 VALIDACIÓN WIKILINKS OBSIDIAN v$VERSION"
  echo "========================================="
  echo "Target: $PROJECT_ROOT"
  echo "📁 Archivos escaneados: $FILES_SCANNED"
  echo "🔗 Enlaces encontrados: $TOTAL_LINKS_FOUND"
  echo "✅ Válidos: $VALID_LINKS"
  echo "❌ Rotos: ${#BROKEN_LINKS[@]}"
  echo "🔄 Cíclicos: ${#CYCLE_LINKS[@]}"
  echo "Estado: $status"
  echo "🔐 Report SHA256: $report_sha"
  echo "📄 Reporte: $REPORT_FILE"
  echo "========================================="
  
  if [[ ${#BROKEN_LINKS[@]} -gt 0 ]]; then
    echo ""
    echo "⚠️  Enlaces rotos detectados:"
    for bl in "${BROKEN_LINKS[@]}"; do
      local src lnk err
      IFS='|' read -r src lnk err <<< "$bl"
      echo "  • $src → [[${lnk}]] (${err})"
    done
  fi
  
  if [[ ${#CYCLE_LINKS[@]} -gt 0 ]]; then
    echo ""
    echo "⚠️  Auto-referencias detectadas:"
    for cl in "${CYCLE_LINKS[@]}"; do
      local src lnk err
      IFS='|' read -r src lnk err <<< "$cl"
      echo "  • $src → [[${lnk}]] (${err})"
    done
  fi
  
  if [[ "$status" == "failed" ]]; then
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

Validador de wikilinks Obsidian [[...]] para integridad de navegación SDD.
Detecta enlaces rotos, rutas mal resueltas y referencias cíclicas.

Parámetros:
  ruta            Directorio/archivo a validar (default: .)
  reporte.json    Salida JSON (default: wikilinks-validation-report.json)
  verbose:0/1     Modo detallado
  strict:0/1      Fail on warnings (ciclos) o errores (rotos)

Reglas de resolución:
  ✓ Rutas absolutas: /02-SKILLS/AI/qwen-integration.md
  ✓ Prefijos conocidos: 02-SKILLS/AI/qwen-integration.md
  ✓ Rutas relativas: ../RULES/01-ARCHITECTURE-RULES.md
  ✓ Extensión .md auto-completada si falta
  ✓ Fallback de búsqueda recursiva en root
  ✓ Detección de auto-referencias [[mismo_archivo]]

Ejemplos:
  $0 02-SKILLS/
  $0 . wikilinks-report.json 1 1
  $0 --scan-only  # Dry-run (muestra solo stats)

Salida: Reporte JSON + código 0/1 para CI/CD
EOF
    exit 0
  fi
  
  log_info "Iniciando validación de wikilinks v$VERSION"
  
  if [[ -f "$PROJECT_ROOT" ]]; then
    validate_file_wikilinks "$PROJECT_ROOT"
  elif [[ -d "$PROJECT_ROOT" ]]; then
    scan_directory "$PROJECT_ROOT"
  else
    echo "Error: Ruta no encontrada: $PROJECT_ROOT" >&2
    exit 1
  fi
  
  generate_report
}

main "$@"
```
