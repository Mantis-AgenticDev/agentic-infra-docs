#!/usr/bin/env bash
# VALIDATOR_DEPENDENCIES: bash>=4.0,jq>=1.6,awk,grep,sed,mkdir,date
# VALIDATOR_PURPOSE: Verify frontmatter constraints_mapped alignment + LANGUAGE LOCK enforcement
# SHA256: $(openssl rand -hex 32 2>/dev/null || echo "0000000000000000000000000000000000000000000000000000000000000000")
# verify-constraints.sh – v3.0.0-SELECTIVE-CONTRACTUAL

set -Eeuo pipefail
readonly SCRIPT_NAME="verify-constraints.sh"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly LOG_DIR="$PROJECT_ROOT/08-LOGS/validation/test-orchestrator-engine/verify-constraints"
readonly MATRIX_FILE="$SCRIPT_DIR/norms-matrix.json"
START_MS=$(date +%s%3N)

mkdir -p "$LOG_DIR"
readonly LOG_FILE="$LOG_DIR/$(date -u +%Y-%m-%d).jsonl"

# C8: Logging functions (ONLY to stderr)
log() {
  local level="${1:-INFO}" msg="${2:-}" file="${3:-unknown}"
  printf '{"ts":"%s","level":"%s","script":"%s","file":"%s","msg":"%s"}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$level" "$SCRIPT_NAME" "$file" "$msg" >&2
}

FILE=""
JSON_OUTPUT=false
TEST_MODE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --file) FILE="$2"; shift 2 ;;
    --json) JSON_OUTPUT=true; shift ;;
    --test-mode) TEST_MODE=true; shift ;;
    -h|--help)
      cat << 'HELP'
Usage: verify-constraints.sh --file <path> [--json] [--test-mode]
HELP
      exit 0 ;;
    *) log "ERROR" "Unknown argument: $1"; exit 2 ;;
  esac
done

if [[ -z "$FILE" || ! -f "$FILE" ]]; then
  log "ERROR" "Missing or invalid file: $FILE"
  exit 2
fi

# Parsing utilities
extract_field() {
  local field="$1" file="$2"
  grep -E "^${field}:" "$file" 2>/dev/null | head -1 | \
    sed -E "s/^${field}:\s*['\"]?//" | sed -E "s/['\"]?\s*$//" || echo ""
}
extract_json_array_field() {
  local field="$1" file="$2"
  grep -E "^${field}:" "$file" 2>/dev/null | head -1 | \
    grep -oE '\[[^]]+\]' | tr -d ' ' || echo "[]"
}

ARTIFACT_ID=$(extract_field "artifact_id" "$FILE")
ARTIFACT_TYPE=$(extract_field "artifact_type" "$FILE")
CONSTRAINTS_MAPPED=$(extract_json_array_field "constraints_mapped" "$FILE")
CANONICAL_PATH=$(extract_field "canonical_path" "$FILE")

declare -a ISSUES=()
PASSED=true
EXIT_CODE=0

add_issue() {
  local code="$1" msg="$2" severity="$3" pat="${4:-}"
  ISSUES+=("$(jq -n --arg c "$code" --arg m "$msg" --arg s "$severity" --arg p "$pat" \
    '{code: $c, message: $m, severity: $s, pattern_matched: $p}')")
  if [[ "$severity" == "error" ]]; then
    PASSED=false
    EXIT_CODE=1
  fi
  log "WARN" "[$severity] $code: $msg" "$FILE"
}

# 1. Frontmatter Validation
if [[ -z "$ARTIFACT_ID" || -z "$CANONICAL_PATH" || -z "$CONSTRAINTS_MAPPED" ]]; then
  add_issue "FRONTMATTER_INCOMPLETE" "Missing required fields (artifact_id, canonical_path, constraints_mapped)" "error" ""
fi

# 2. Context resolution and Anti-Pattern checks
# We use simple string matching to determine domain
DOMAIN_SEVERITY="error"
if [[ "$FILE" =~ /02-EDUCATIONAL/ || "$FILE" =~ /03-PATTERNS/ || "$FILE" =~ /04-RESEARCH/ || "$FILE" =~ /02-SKILLS/ ]]; then
  DOMAIN_SEVERITY="warning"
fi

if grep -qiE 'password|sk-[a-zA-Z0-9]{20}|anti-pattern' "$FILE"; then
  add_issue "ANTI_PATTERN_DETECTED" "Anti-pattern or hardcoded secret detected" "$DOMAIN_SEVERITY" "anti-pattern"
fi

# 3. LANGUAGE LOCK Validation
IS_PGVECTOR=false
[[ "$FILE" == *"/postgresql-pgvector/"* ]] && IS_PGVECTOR=true

if grep -qE '<->|<=>|<#>|cosine_distance|vector\([0-9]+\)' "$FILE" 2>/dev/null; then
  if [[ "$IS_PGVECTOR" == false ]]; then
    add_issue "LANGUAGE_LOCK_VIOLATION" "Vector operators (V1-V3) found outside postgresql-pgvector/" "error" "vector_operator"
  fi
fi

# Finalizing JSON output
END_MS=$(date +%s%3N)
ELAPSED_MS=$((END_MS - START_MS))

# Format issues array properly for jq
ISSUES_JSON=$(printf '%s\n' "${ISSUES[@]}" | jq -s . 2>/dev/null || echo "[]")
ISSUES_COUNT=$(echo "$ISSUES_JSON" | jq 'length')

FINAL_JSON=$(jq -n \
  --arg val "verify-constraints.sh" \
  --arg ver "3.0.0" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg f "$FILE" \
  --arg c "C5|LANGUAGE_LOCK" \
  --argjson p "$PASSED" \
  --argjson iss "$ISSUES_JSON" \
  --argjson ic "$ISSUES_COUNT" \
  '{validator: $val, version: $ver, timestamp: $ts, file: $f, constraint: $c, passed: $p, issues: $iss, issues_count: $ic}')

# Write to stdout if requested, otherwise human readable to stderr
if [[ "$JSON_OUTPUT" == true ]]; then
  echo "$FINAL_JSON"
else
  echo "=== Constraint Verification Summary ===" >&2
  echo "File: $FILE" >&2
  echo "Passed: $PASSED" >&2
  echo "Issues: $ISSUES_COUNT" >&2
  if [[ "$ISSUES_COUNT" -gt 0 ]]; then
    echo "$FINAL_JSON" | jq -r '.issues[] | "  [\(.severity)] \(.code): \(.message)"' >&2
  fi
  echo "Elapsed: ${ELAPSED_MS}ms" >&2
fi

# Write JSONL log (V-LOG)
jq -c \
  --argjson ms "$ELAPSED_MS" \
  --argjson ok $([ "$ELAPSED_MS" -lt 3000 ] && echo true || echo false) \
  '. + {performance_ms: $ms, performance_ok: $ok}' <<< "$FINAL_JSON" >> "$LOG_FILE"

exit "$EXIT_CODE"
