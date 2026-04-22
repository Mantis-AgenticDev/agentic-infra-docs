#!/usr/bin/env bash
# VALIDATOR_DEPENDENCIES: jq>=1.6, bash>=5.0, awk, date
# EXECUTION_PROFILE: <3000ms, <64MB RAM, streaming IO
# SCOPE: internal-validation-only - static analysis for C4 compliance
set -o pipefail

readonly VALIDATOR_NAME="check-rls.sh"
readonly VALIDATOR_VERSION="3.2.5"
readonly CONSTRAINT="C4"
readonly NORMS_FILE="05-CONFIGURATIONS/validation/norms-matrix.json"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
readonly DEFAULT_LOG_DIR="$REPO_ROOT/08-LOGS/validation/test-orchestrator-engine/check-rls"

MODE="file"; TARGET=""
LOG_DIR="$DEFAULT_LOG_DIR"
LOG_FILE=""   # Si se define, se usará en lugar de generar uno nuevo con timestamp

while [[ $# -gt 0 ]]; do
  case "$1" in
    --file) MODE="file"; TARGET="$2"; shift 2 ;;
    --dir)  MODE="dir"; TARGET="$2"; shift 2 ;;
    --log-dir) LOG_DIR="$2"; shift 2 ;;
    --log-file) LOG_FILE="$2"; shift 2 ;;
    -h|--help) echo "Uso: $0 [--file <ruta>|--dir <ruta>] [--log-dir <ruta>] [--log-file <ruta>]"; exit 0 ;;
    *) echo "Error: Flag desconocido: $1" >&2; exit 2 ;;
  esac
done
[[ -z "$TARGET" ]] && { echo "Error: Se requiere --file o --dir" >&2; exit 2; }

mkdir -p "$LOG_DIR"
# Si no se especificó --log-file, generar uno con timestamp
if [[ -z "$LOG_FILE" ]]; then
  LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d_%H%M%S).jsonl"
fi

log() { echo "[check-rls] $*" >&2; }

# ===== Cargar excepciones desde norms-matrix.json =====
declare -A C4_EXCEPTIONS
if [[ -f "$NORMS_FILE" ]]; then
  while IFS='|' read -r pattern exc_type; do
    [[ -n "$pattern" && -n "$exc_type" ]] && C4_EXCEPTIONS["$pattern|$exc_type"]=1
  done < <(jq -r 'to_entries[] | select(.value.c4_exceptions) | .key as $k | .value.c4_exceptions[] | "\($k)|\(.)"' "$NORMS_FILE" 2>/dev/null || true)
fi

is_exception() {
  local filepath="$1" pattern="$2"
  [[ -n "${C4_EXCEPTIONS["$filepath|$pattern"]}" ]] && return 0
  for key in "${!C4_EXCEPTIONS[@]}"; do
    local key_path="${key%%|*}"
    local key_exc="${key#*|}"
    if [[ "$key_exc" == "$pattern" ]] && [[ "$filepath" == *"$key_path"* || "$key_path" == *"$filepath"* ]]; then
      return 0
    fi
  done
  return 1
}

extract_sql_with_lines() {
  awk '
    /^[[:space:]]*```sql/ { in_block=1; sql_line=0; next }
    in_block && /^[[:space:]]*```/ { in_block=0; next }
    in_block { sql_line++; print sql_line ":" $0 }
  ' "$1"
}

build_issue() {
  local category="$1" severity="$2" line_num="$3" snippet="$4"
  local desc=""
  case "$category" in
    explicit_bypass) desc="Bypass explícito de RLS (SET rls = false)" ;;
    explicit_bypass_marker) desc="Marcador de bypass (-- bypass-rls)" ;;
    missing_tenant_filter) desc="DML sin tenant_id" ;;
    missing_join_scoping) desc="JOIN sin scoping cruzado por tenant_id" ;;
    *) desc="Violación de Constraint C4" ;;
  esac
  local snippet_escaped=$(printf '%s' "$snippet" | jq -Rs '. | if length > 200 then .[0:200] + "..." else . end')
  jq -n -c --arg c "$CONSTRAINT" --arg cat "$category" --arg d "$desc" --arg s "$severity" --argjson l "$line_num" --argjson snip "$snippet_escaped" \
    '{constraint:$c,category:$cat,description:$d,severity:$s,line:$l,snippet:$snip}'
}

emit_file_json() {
  local file="$1" passed="$2" issues_json="$3" issues_count="$4" elapsed_ms="$5" warning="${6:-}"
  local perf_ok="true"; [[ $elapsed_ms -gt 3000 ]] && perf_ok="false"
  jq -n -c --arg v "$VALIDATOR_NAME" --arg ver "$VALIDATOR_VERSION" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg f "$file" --arg c "$CONSTRAINT" \
    --argjson p "$passed" --argjson i "$issues_json" --argjson cnt "$issues_count" --argjson perf "$elapsed_ms" --argjson perf_ok "$perf_ok" --arg warn "$warning" \
    '{validator:$v,version:$ver,timestamp:$ts,file:$f,constraint:$c,passed:$p,issues:$i,issues_count:$cnt,performance_ms:$perf,performance_ok:$perf_ok} + (if $warn!="" then {warning:$warn} else {} end)'
}

validate_file() {
  local file="$1"
  local start_ms=$(date +%s%3N)
  
  if [[ ! -f "$file" ]]; then
    local elapsed=$(( $(date +%s%3N) - start_ms ))
    emit_file_json "$file" false "[]" 0 "$elapsed" "file_not_found"
    return 2
  fi

  local rel_path="${file#${REPO_ROOT}/}"
  local sql_lines=$(extract_sql_with_lines "$file")
  
  if [[ -z "$sql_lines" ]]; then
    local elapsed=$(( $(date +%s%3N) - start_ms ))
    emit_file_json "$file" true "[]" 0 "$elapsed" "no_sql_block"
    return 0
  fi

  local -a issues=()
  local line_num line_content

  while IFS=':' read -r line_num line_content; do
    [[ -z "$line_content" ]] && continue
    local is_comment=false
    [[ "$line_content" =~ ^[[:space:]]*-- ]] && is_comment=true

    if ! $is_comment && [[ "$line_content" =~ SET[[:space:]]+rls[[:space:]]*=[[:space:]]*false ]]; then
      is_exception "$rel_path" "explicit_bypass" && continue
      issues+=("$(build_issue "explicit_bypass" "CRITICAL" "$line_num" "$line_content")")
      continue
    fi

    if [[ "$line_content" =~ ^[[:space:]]*--[[:space:]]*bypass-rls ]]; then
      is_exception "$rel_path" "explicit_bypass" && continue
      issues+=("$(build_issue "explicit_bypass_marker" "CRITICAL" "$line_num" "$line_content")")
      continue
    fi

    if ! $is_comment && [[ "$line_content" =~ (SELECT|INSERT|UPDATE|DELETE) ]]; then
      if [[ ! "$line_content" =~ tenant_id ]]; then
        is_exception "$rel_path" "missing_tenant_filter" && continue
        issues+=("$(build_issue "missing_tenant_filter" "CRITICAL" "$line_num" "$line_content")")
      fi
    fi

    if ! $is_comment && [[ "$line_content" =~ [[:space:]]JOIN[[:space:]] ]]; then
      if [[ ! "$line_content" =~ tenant_id ]]; then
        is_exception "$rel_path" "missing_join_scoping" && continue
        issues+=("$(build_issue "missing_join_scoping" "HIGH" "$line_num" "$line_content")")
      fi
    fi
  done <<< "$sql_lines"

  local elapsed=$(( $(date +%s%3N) - start_ms ))
  local passed=false
  local issues_count=${#issues[@]}
  [[ $issues_count -eq 0 ]] && passed=true

  local issues_json="[]"
  [[ $issues_count -gt 0 ]] && issues_json=$(printf '%s\n' "${issues[@]}" | jq -s '.')

  emit_file_json "$file" "$passed" "$issues_json" "$issues_count" "$elapsed"
  [[ "$passed" == "true" ]] && return 0 || return 1
}

# === MAIN ===
log "Iniciando $VALIDATOR_NAME v$VALIDATOR_VERSION"

if [[ "$MODE" == "file" ]]; then
  result=$(validate_file "$TARGET")
  exit_code=$?
  echo "$result"
  echo "$result" >> "$LOG_FILE"
  exit "$exit_code"
else
  total=$(find "$TARGET" -type f -name "*.md" 2>/dev/null | wc -l)
  processed=0; passed=0; failed=0; errors=0
  failed_files=()

  while IFS= read -r -d '' file; do
    ((processed++))
    printf "[%3d/%3d] %s " "$processed" "$total" "${file#$REPO_ROOT/}" >&2
    result=$(validate_file "$file")
    exit_code=$?
    echo "$result" >> "$LOG_FILE"
    case $exit_code in
      0) ((passed++)); echo "✅" >&2 ;;
      1) ((failed++)); echo "❌" >&2; failed_files+=("$file") ;;
      *) ((errors++)); echo "⚠️" >&2 ;;
    esac
  done < <(find "$TARGET" -type f -name "*.md" -print0 2>/dev/null)

  echo "" >&2
  log "Resumen: $processed procesados | ✅ $passed | ❌ $failed | ⚠️ $errors"
  if [[ ${#failed_files[@]} -gt 0 ]]; then
    log "Archivos con errores:"
    for f in "${failed_files[@]}"; do
      log "  ❌ $f"
      grep "\"file\":\"$f\"" "$LOG_FILE" | jq -r '.issues[] | "    Línea \(.line): \(.description) [\(.severity)]\n      \(.snippet)"' 2>/dev/null | while IFS= read -r line; do
        log "    $line"
      done
    done
  fi

  [[ $failed -eq 0 && $errors -eq 0 ]] && exit 0 || exit 1
fi
