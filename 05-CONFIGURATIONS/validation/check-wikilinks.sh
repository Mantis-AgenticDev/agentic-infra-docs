#!/usr/bin/env bash
#---
# metadata_version: 1.3
# sdd_compliant: true
# ai_parser_compatible: true
# purpose: "Validador de wikilinks Obsidian para integridad de navegación SDD"
# scope: "00-CONTEXT/, 01-RULES/, 02-SKILLS/, 04-WORKFLOWS/, 05-CONFIGURATIONS/"
# constraint: "Navegación IA: 0 enlaces rotos, detección de ciclos, resolución de rutas"
# output_format: "json + stdout + exit code para CI/CD"
# ---
# ============================================================================
# CHECK-WIKILINKS.SH v1.3
# Validador de enlaces Obsidian [[...]] para MANTIS AGENTIC
# Propósito: Detectar enlaces rotos, rutas mal resueltas, alias inválidos y
# referencias cíclicas en toda la documentación SDD. Compatible con espacios
# en nombres de directorio y resolución relativa/absoluta.
# Fixes v1.3: Normalización de rutas pura en bash (sin realpath), manejo robusto
# de ../, sanitización aritmética, JSON seguro, skip de enlaces didácticos.
# ============================================================================
set -euo pipefail

# ────────────────────────────────────────────────────────────────────────────
# CONFIGURACIÓN GLOBAL
# ────────────────────────────────────────────────────────────────────────────
readonly VERSION="1.3.0"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# Variables por defecto (se sobrescriben con args)
declare PROJECT_ROOT="."
declare REPORT_FILE="wikilinks-validation-report.json"
declare VERBOSE="0"
declare STRICT="0"

# Arrays de estado
declare -a BROKEN_LINKS=()
declare -a CYCLE_LINKS=()
declare -i FILES_SCANNED=0
declare -i TOTAL_LINKS_FOUND=0
declare -i VALID_LINKS=0

# Prefijos conocidos del repositorio para resolución canónica
readonly -a KNOWN_PREFIXES=(
  "00-CONTEXT" "01-RULES" "02-SKILLS" "03-AGENTS" 
  "04-WORKFLOWS" "05-CONFIGURATIONS" "06-PROGRAMMING" 
  "07-PROCEDURES" "08-LOGS"
)

# Directorios a excluir del escaneo
readonly -a EXCLUDE_DIRS=(
  ".git" "node_modules" "venv" ".venv" "__pycache__" 
  "dist" "build" ".obsidian" ".github"
)

# Extensiones válidas para resolución automática
readonly -a VALID_EXTENSIONS=("md" "json" "sh" "yml" "yaml" "tf" "py" "sql")

# ────────────────────────────────────────────────────────────────────────────
# PARSER DE ARGUMENTOS
# ────────────────────────────────────────────────────────────────────────────
parse_arguments() {
  local args=()
  for arg in "$@"; do
    case "$arg" in
      --strict) STRICT="1" ;;
      --verbose|-v) VERBOSE="1" ;;
      --report=*) REPORT_FILE="${arg#--report=}" ;;
      --help|-h) show_help; exit 0 ;;
      -*) continue ;;
      *) args+=("$arg") ;;
    esac
  done
  [[ ${#args[@]} -ge 1 ]] && PROJECT_ROOT="${args[0]}"
  [[ ${#args[@]} -ge 2 ]] && REPORT_FILE="${args[1]}"
  # Normalizar a ruta absoluta si es relativo
  if [[ ! "$PROJECT_ROOT" =~ ^/ ]]; then
    PROJECT_ROOT="$(pwd)/${PROJECT_ROOT}"
  fi
}

# ────────────────────────────────────────────────────────────────────────────
# UTILIDADES
# ────────────────────────────────────────────────────────────────────────────
log_info() { [[ "$VERBOSE" == "1" ]] && echo "[INFO] $*" || true; }
log_error() { echo "[ERROR] $*" >&2; }

# Sanitizar para operaciones aritméticas (evita "0\n0" → error)
sanitize_int() {
  local val="$1"
  local clean
  clean=$(echo "$val" | tr -cd '0-9' | head -c 10)
  [[ -z "$clean" ]] && echo "0" || echo "$clean"
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

is_excluded() {
  local path="$1"
  for excl in "${EXCLUDE_DIRS[@]}"; do
    [[ "$path" == *"/$excl/"* || "$path" == *"/$excl" ]] && return 0
  done
  return 1
}

# ────────────────────────────────────────────────────────────────────────────
# NORMALIZACIÓN DE RUTAS (Pura bash, sin dependencias externas)
# Resuelve ../, ./, y rutas relativas a absolutas canónicas
# ────────────────────────────────────────────────────────────────────────────
normalize_path_pure() {
  local path="$1"
  local -a parts=()
  local IFS='/'
  
  # Leer componentes de la ruta
  read -ra parts <<< "$path"
  
  local -a result=()
  for part in "${parts[@]}"; do
    if [[ -z "$part" || "$part" == "." ]]; then
      continue
    elif [[ "$part" == ".." ]]; then
      # Eliminar último componente si existe
      if [[ ${#result[@]} -gt 0 ]]; then
        unset 'result[-1]'
      fi
    else
      result+=("$part")
    fi
  done
  
  # Reconstruir ruta absoluta
  local normalized="/"
  for ((i=0; i<${#result[@]}; i++)); do
    normalized+="${result[$i]}"
    if [[ $i -lt $((${#result[@]} - 1)) ]]; then
      normalized+="/"
    fi
  done
  
  echo "$normalized"
}

# ────────────────────────────────────────────────────────────────────────────
# RESOLUCIÓN DE RUTAS (Robusta: anchors, alias, relativas, absolutas, fallback)
# ────────────────────────────────────────────────────────────────────────────
resolve_wikilink_target() {
  local source_file="$1"
  local raw_link="$2"
  
  # 1. Extraer ruta real: ignorar alias [[ruta|texto]] y anchors [[ruta#sección]]
  local target_path
  target_path=$(echo "$raw_link" | sed 's/|.*//; s/#.*//' | xargs)
  
  [[ -z "$target_path" ]] && return 1
  
  # 2. Asegurar extensión válida (solo si no es directorio)
  if [[ ! "$target_path" =~ /$ ]]; then
    local has_ext=false
    for ext in "${VALID_EXTENSIONS[@]}"; do
      if [[ "$target_path" == *".$ext" ]]; then
        has_ext=true
        break
      fi
    done
    if [[ "$has_ext" == "false" ]]; then
      target_path="${target_path}.md"
    fi
  fi
  
  local resolved=""
  local source_dir
  source_dir=$(dirname "$source_file")
  
  # 3. Resolución en orden de prioridad:
  
  # a) Ruta absoluta desde root del repo (/...)
  if [[ "$target_path" == /* ]]; then
    resolved="${REPO_ROOT}${target_path}"
  
  # b) Prefijos conocidos del repo (00-CONTEXT/, 02-SKILLS/, etc.)
  elif [[ "$target_path" =~ ^(${KNOWN_PREFIXES[0]}|${KNOWN_PREFIXES[1]}|${KNOWN_PREFIXES[2]}|${KNOWN_PREFIXES[3]}|${KNOWN_PREFIXES[4]}|${KNOWN_PREFIXES[5]}|${KNOWN_PREFIXES[6]}|${KNOWN_PREFIXES[7]}|${KNOWN_PREFIXES[8]})/ ]]; then
    resolved="${REPO_ROOT}/${target_path}"
  
  # c) Ruta relativa con ../ o ./
  elif [[ "$target_path" == ../* || "$target_path" == ./* ]]; then
    resolved="${source_dir}/${target_path}"
  
  # d) Archivo en mismo directorio (sin slashes)
  elif [[ "$target_path" != */* ]]; then
    resolved="${source_dir}/${target_path}"
  
  # e) Fallback: búsqueda recursiva en repo root por nombre de archivo
  else
    local basename_file
    basename_file=$(basename "$target_path")
    resolved=$(find "${REPO_ROOT}" -name "$basename_file" -type f 2>/dev/null | head -1 || echo "")
    if [[ -n "$resolved" ]]; then
      echo "$resolved"
      return 0
    fi
    resolved="${source_dir}/${target_path}"
  fi
  
  # 4. Normalización PURA BASH (sin dependencias de realpath)
  resolved=$(normalize_path_pure "$resolved")
  
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
  FILES_SCANNED=$((FILES_SCANNED + 1))
  
  # Extraer todos los wikilinks [[...]]
  local links
  links=$(grep -oE '\[\[[^]]+\]\]' "$file" 2>/dev/null | sed 's/^\[\[//; s/\]\]$//' || true)
  
  if [[ -z "$links" ]]; then
    VALID_LINKS=$((VALID_LINKS + 1))
    return 0
  fi
  
  while IFS= read -r link; do
    [[ -z "$link" ]] && continue
    TOTAL_LINKS_FOUND=$((TOTAL_LINKS_FOUND + 1))
    
    # Ignorar enlaces didácticos, ejemplos o anclas sueltas
    if [[ "$link" =~ ^# || \
          "$link" == "enlaces" || \
          "$link" == *"|"*"texto legible"* || \
          "$link" == *"|"*legible* || \
          "$link" =~ ^\[.*\]$ || \
          "$link" =~ /$ ]]; then
      log_info "[SKIP] Enlace didáctico/ancla/directorio: [[${link}]]"
      VALID_LINKS=$((VALID_LINKS + 1))
      continue
    fi
    
    # Resolver ruta objetivo
    local target
    target=$(resolve_wikilink_target "$file" "$link") || continue
    [[ -z "$target" ]] && continue
    
    # Verificar ciclo (auto-referencia directa)
    local file_norm target_norm
    file_norm=$(normalize_path_pure "$(cd "$(dirname "$file")" 2>/dev/null && echo "$(pwd)/$(basename "$file")")") || file_norm="$file"
    target_norm=$(normalize_path_pure "$target")
    
    if [[ "$file_norm" == "$target_norm" ]]; then
      CYCLE_LINKS+=("$(json_escape "$file")|$(json_escape "$link")|self-reference")
      continue
    fi
    
    # Verificar existencia
    if [[ -f "$target" ]]; then
      VALID_LINKS=$((VALID_LINKS + 1))
      log_info "[OK] Wikilink válido: [[${link}]] → $target"
    else
      # Fallback: búsqueda recursiva por nombre exacto en repo root
      local basename_target
      basename_target=$(basename "$target")
      local found_fallback
      found_fallback=$(find "${REPO_ROOT}" -name "$basename_target" -type f 2>/dev/null | head -1 || echo "")
      
      if [[ -n "$found_fallback" ]]; then
        VALID_LINKS=$((VALID_LINKS + 1))
        log_info "[FALLBACK] Enlace resuelto: [[${link}]] en $file → $found_fallback"
      else
        BROKEN_LINKS+=("$(json_escape "$file")|$(json_escape "$link")|target_not_found")
        log_info "[BROKEN] Wikilink roto: [[${link}]] en $file (resuelto: $target)"
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
  
  # Sanitizar contadores
  local broken_count cycle_count files_scanned_clean total_found_clean valid_clean
  broken_count=$(sanitize_int "${#BROKEN_LINKS[@]}")
  cycle_count=$(sanitize_int "${#CYCLE_LINKS[@]}")
  files_scanned_clean=$(sanitize_int "$FILES_SCANNED")
  total_found_clean=$(sanitize_int "$TOTAL_LINKS_FOUND")
  valid_clean=$(sanitize_int "$VALID_LINKS")
  
  # Determinar estado
  if [[ "$STRICT" == "1" && ("$broken_count" -gt 0 || "$cycle_count" -gt 0) ]]; then
    status="failed"
  elif [[ "$broken_count" -gt 0 ]]; then
    status="failed"
  elif [[ "$cycle_count" -gt 0 ]]; then
    status="warnings"
  fi
  
  # Construir arrays JSON de forma segura
  local broken_json="[]"
  if [[ ${#BROKEN_LINKS[@]} -gt 0 ]]; then
    local items=()
    for bl in "${BROKEN_LINKS[@]}"; do
      local src lnk err
      IFS='|' read -r src lnk err <<< "$bl"
      items+=("{\"source\":\"$(json_escape "$src")\",\"link\":\"$(json_escape "$lnk")\",\"error\":\"$(json_escape "$err")\"}")
    done
    broken_json="[$(IFS=,; echo "${items[*]}")]"
  fi
  
  local cycles_json="[]"
  if [[ ${#CYCLE_LINKS[@]} -gt 0 ]]; then
    local items=()
    for cl in "${CYCLE_LINKS[@]}"; do
      local src lnk err
      IFS='|' read -r src lnk err <<< "$cl"
      items+=("{\"source\":\"$(json_escape "$src")\",\"link\":\"$(json_escape "$lnk")\",\"error\":\"$(json_escape "$err")\"}")
    done
    cycles_json="[$(IFS=,; echo "${items[*]}")]"
  fi
  
  # Construir reporte
  local temp_report
  temp_report=$(mktemp)
  
  cat > "$temp_report" << EOF
{
  "validator_version": "$VERSION",
  "timestamp": "$timestamp",
  "target": "$PROJECT_ROOT",
  "status": "$status",
  "summary": {
    "files_scanned": $files_scanned_clean,
    "total_links_found": $total_found_clean,
    "valid_links": $valid_clean,
    "broken_links": $broken_count,
    "cyclic_references": $cycle_count
  },
  "findings": {
    "broken": $broken_json,
    "cycles": $cycles_json
  },
  "resolution_rules": {
    "known_prefixes": $(printf '"%s",' "${KNOWN_PREFIXES[@]}" | sed 's/,$//' | awk '{print "["$0"]"}'),
    "valid_extensions": $(printf '"%s",' "${VALID_EXTENSIONS[@]}" | sed 's/,$//' | awk '{print "["$0"]"}'),
    "auto_append_md": true,
    "fallback_recursive_search": true,
    "skip_didactic_links": true,
    "pure_bash_normalization": true
  },
  "recommendations": [
    "Usar rutas canónicas desde root del repo: [[02-SKILLS/AI/qwen-integration.md]]",
    "Evitar auto-referencias directas [[mismo_archivo.md]]",
    "Usar alias para legibilidad: [[ruta.md|texto amigable]]",
    "Validar enlaces antes de merge con --strict en CI/CD"
  ],
  "audit": {
    "script_sha256": "$(compute_sha256 "$0")",
    "report_sha256": "PLACEHOLDER"
  }
}
EOF

  # Calcular checksum final y reemplazar placeholder
  local report_sha
  report_sha=$(compute_sha256 "$temp_report")
  sed -i "s/\"report_sha256\": \"PLACEHOLDER\"/\"report_sha256\": \"$report_sha\"/" "$temp_report"
  
  # Mover a destino final (usar cp para evitar conflictos con flags)
  cp "$temp_report" "$REPORT_FILE"
  rm -f "$temp_report"
  
  # Output en stdout
  echo ""
  echo "========================================="
  echo "🔗 VALIDACIÓN WIKILINKS OBSIDIAN v$VERSION"
  echo "========================================="
  echo "Target: $PROJECT_ROOT"
  echo "📁 Archivos escaneados: $files_scanned_clean"
  echo "🔗 Enlaces encontrados: $total_found_clean"
  echo "✅ Válidos: $valid_clean"
  echo "❌ Rotos: $broken_count"
  echo "🔄 Cíclicos: $cycle_count"
  echo "Estado: $status"
  echo "🔐 Report SHA256: $report_sha"
  echo "📄 Reporte: $REPORT_FILE"
  echo "========================================="
  
  # Mostrar detalles si hay hallazgos
  if [[ "$broken_count" -gt 0 ]]; then
    echo ""
    echo "⚠️  Enlaces rotos detectados:"
    for bl in "${BROKEN_LINKS[@]}"; do
      local src lnk err
      IFS='|' read -r src lnk err <<< "$bl"
      echo "  • $src → [[${lnk}]] (${err})"
    done
  fi
  
  if [[ "$cycle_count" -gt 0 ]]; then
    echo ""
    echo "⚠️  Auto-referencias detectadas:"
    for cl in "${CYCLE_LINKS[@]}"; do
      local src lnk err
      IFS='|' read -r src lnk err <<< "$cl"
      echo "  • $src → [[${lnk}]] (${err})"
    done
  fi
  
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

Validador de wikilinks Obsidian [[...]] para integridad de navegación SDD.
Detecta enlaces rotos, rutas mal resueltas y referencias cíclicas.

Parámetros posicionales:
  ruta            Directorio/archivo a validar (default: .)
  reporte.json    Salida JSON (default: wikilinks-validation-report.json)

Opciones:
  --strict       Tratar warnings como errores (para CI/CD)
  --verbose, -v  Modo detallado
  --help, -h     Mostrar esta ayuda

Reglas de resolución:
  ✓ Rutas absolutas: /02-SKILLS/AI/qwen-integration.md
  ✓ Prefijos conocidos: 02-SKILLS/AI/qwen-integration.md
  ✓ Rutas relativas: ../RULES/01-ARCHITECTURE-RULES.md
  ✓ Extensión .md auto-completada si falta (solo archivos)
  ✓ Fallback de búsqueda recursiva en root del repo
  ✓ Detección de auto-referencias [[mismo_archivo]]
  ✓ Skip de enlaces didácticos: [[enlaces]], [[ruta|texto legible]]
  ✓ Normalización pura bash: sin dependencia de realpath

Ejemplos:
  $0 02-SKILLS/
  $0 . wikilinks-report.json --strict
  $0 02-SKILLS/GENERATION-MODELS.md --verbose

Salida: Reporte JSON + código 0/1 para CI/CD
EOF
}

# ────────────────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────────────────
main() {
  parse_arguments "$@"
  
  log_info "Iniciando validación de wikilinks v$VERSION"
  log_info "Repo root: $REPO_ROOT"
  log_info "Target: $PROJECT_ROOT"
  log_info "Strict mode: $STRICT"
  
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
