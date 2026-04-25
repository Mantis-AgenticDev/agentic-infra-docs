#!/usr/bin/env bash
# VALIDATOR_DEPENDENCIES: jq>=1.6, bash>=5.0, awk, date
# EXECUTION_PROFILE: <3000ms, <64MB RAM, streaming IO
# SCOPE: internal-validation-only - static analysis for C4 compliance
# INTERFACE_VERSION: v3.3-CONTRACTUAL
set -euo pipefail

START_MS=$(date +%s%3N 2>/dev/null || echo 0)
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

readonly VALIDATOR_NAME="${SCRIPT_NAME%.sh}"
readonly VALIDATOR_VERSION="3.3.0-CONTRACTUAL"
readonly CONSTRAINT="C4"
readonly NORMS_FILE="$PROJECT_ROOT/05-CONFIGURATIONS/validation/norms-matrix.json"
readonly LOG_DIR="$PROJECT_ROOT/08-LOGS/validation/test-orchestrator-engine/${VALIDATOR_NAME}"
readonly LOG_FILE="$LOG_DIR/$(date -u +%Y-%m-%d).jsonl"

log_err() {
  local level="${1:-INFO}" msg="${2:-}"
  printf '{"ts":"%s","level":"%s","script":"%s","msg":"%s"}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$level" "$SCRIPT_NAME" "$msg" >&2
}

FILE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --file|-f) FILE="$2"; shift 2 ;;
    *) shift ;;
  esac
done

if [[ -z "$FILE" || ! -f "$FILE" ]]; then
  log_err "ERROR" "File not found: $FILE"
  jq -n -c \
    --arg v "$VALIDATOR_NAME" --arg ver "$VALIDATOR_VERSION" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg f "$FILE" \
    '{validator:$v,version:$ver,timestamp:$ts,file:$f,passed:false,issues:["FILE_NOT_FOUND"],issues_count:1,performance_ms:0}'
  exit 2
fi

log_err "INFO" "Starting check-rls validation for: $FILE"
mkdir -p "$LOG_DIR" 2>/dev/null || true

# ===== Cargar excepciones desde norms-matrix.json =====
declare -A C4_EXCEPTIONS
if [[ -f "$NORMS_FILE" ]]; then
  while IFS='|' read -r pattern exc_type; do
    [[ -n "$pattern" && -n "$exc_type" ]] && C4_EXCEPTIONS["$pattern|$exc_type"]=1
  done < <(jq -r 'to_entries[] | select(.value.c4_exceptions) | .key as $k | .value.c4_exceptions[] | "\($k)|\(.)"' "$NORMS_FILE" 2>/dev/null || true)
fi

is_exception() {
  local filepath="$1" pattern="$2"
  [[ -n "${C4_EXCEPTIONS["$filepath|$pattern"]-}" ]] && return 0
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

rel_path="${FILE#${PROJECT_ROOT}/}"
sql_lines=$(extract_sql_with_lines "$FILE")

declare -a issues=()

if [[ -n "$sql_lines" ]]; then
  while IFS=':' read -r line_num line_content; do
    [[ -z "$line_content" ]] && continue
    is_comment=false
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
fi

END_MS=$(date +%s%3N 2>/dev/null || echo 0)
ELAPSED_MS=$((END_MS - START_MS))
[[ "$ELAPSED_MS" -lt 0 ]] && ELAPSED_MS=0

PASSED=true
[[ ${#issues[@]} -gt 0 ]] && PASSED=false

ISSUES_JSON="[]"
[[ ${#issues[@]} -gt 0 ]] && ISSUES_JSON=$(printf '%s\n' "${issues[@]}" | jq -s '.')

OUTPUT_JSON=$(jq -n -c \
  --arg v "$VALIDATOR_NAME" \
  --arg ver "$VALIDATOR_VERSION" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg f "$FILE" \
  --arg c "$CONSTRAINT" \
  --argjson p "$PASSED" \
  --argjson i "$ISSUES_JSON" \
  --argjson cnt "${#issues[@]}" \
  --argjson perf "$ELAPSED_MS" \
  --argjson perf_ok "$([ $ELAPSED_MS -gt 3000 ] && echo false || echo true)" \
  '{validator:$v,version:$ver,timestamp:$ts,file:$f,constraint:$c,passed:$p,issues:$i,issues_count:$cnt,performance_ms:$perf,performance_ok:$perf_ok}'
)

echo "$OUTPUT_JSON"
echo "$OUTPUT_JSON" >> "$LOG_FILE"

if [[ "$PASSED" == true ]]; then
  exit 0
else
  exit 1
fi
