#!/usr/bin/env bash
# SHA256: $(sha256sum "$0" 2>/dev/null | awk '{print $1}')
# ---
# artifact_id: "validate-frontmatter"
# artifact_type: "skill_bash"
# version: "3.0.0-CONTRACTUAL"
# constraints_mapped: ["C5","C8"]
# canonical_path: "05-CONFIGURATIONS/validation/validate-frontmatter.sh"
# ---
# validate-frontmatter.sh (v3.0-CONTRACTUAL)
# HARNESS NORMS v3.0 | Zero-Trust Validation Gate

set -euo pipefail

START_MS=$(date +%s%3N 2>/dev/null || echo 0)
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VERSION="3.0.0-CONTRACTUAL"

# Directorio de Logs
readonly LOG_DIR="$PROJECT_ROOT/08-LOGS/validation/test-orchestrator-engine/${SCRIPT_NAME%.sh}"

# ==========================================
# C8: LOGGING A STDERR
# ==========================================
log_err() {
  local level="${1:-INFO}" msg="${2:-}"
  printf '{"ts":"%s","level":"%s","script":"%s","msg":"%s"}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$level" "$SCRIPT_NAME" "$msg" >&2
}

FILE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --file) FILE="$2"; shift 2 ;;
    *) shift ;; # Ignore other args
  esac
done

if [[ -z "$FILE" || ! -f "$FILE" ]]; then
  log_err "ERROR" "File not provided or not found."
  # Return minimal JSON
  jq -n \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg val "${SCRIPT_NAME%.sh}" \
    --arg ver "$VERSION" \
    --arg file "$FILE" \
    '{validator: $val, version: $ver, timestamp: $ts, file: $file, passed: false, issues: ["FILE_NOT_FOUND"], issues_count: 1, performance_ms: 0}'
  exit 2
fi

log_err "INFO" "Starting frontmatter validation for: $FILE"

extract_field() {
  local field="$1" file="$2"
  grep -E "^#?[[:space:]]*${field}:" "$file" 2>/dev/null | head -1 | \
    sed -E "s/^#?[[:space:]]*${field}:[[:space:]]*//" | \
    sed -E "s/['\"]//g" | sed -E "s/[[:space:]]*$//" || echo ""
}

declare -a ISSUES=()

# Validaciones Básicas de Estructura
ARTIFACT_ID=$(extract_field "artifact_id" "$FILE")
ARTIFACT_TYPE=$(extract_field "artifact_type" "$FILE")
VERSION_FIELD=$(extract_field "version" "$FILE")
CANONICAL_PATH=$(extract_field "canonical_path" "$FILE")

if [[ -z "$ARTIFACT_ID" ]]; then ISSUES+=("MISSING_ARTIFACT_ID"); fi
if [[ -z "$ARTIFACT_TYPE" ]]; then ISSUES+=("MISSING_ARTIFACT_TYPE"); fi
if [[ -z "$VERSION_FIELD" ]]; then ISSUES+=("MISSING_VERSION"); fi
if [[ -z "$CANONICAL_PATH" ]]; then ISSUES+=("MISSING_CANONICAL_PATH"); fi

# Semver check
if [[ -n "$VERSION_FIELD" && ! "$VERSION_FIELD" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]]; then
  ISSUES+=("INVALID_SEMVER")
fi

PASSED=true
if [[ ${#ISSUES[@]} -gt 0 ]]; then
  PASSED=false
fi

END_MS=$(date +%s%3N 2>/dev/null || echo 0)
ELAPSED_MS=$((END_MS - START_MS))
[[ "$ELAPSED_MS" -lt 0 ]] && ELAPSED_MS=0

# JSON Array construction for jq
ISSUES_JSON=$(printf '%s\n' "${ISSUES[@]}" | jq -R . 2>/dev/null | jq -s . 2>/dev/null || echo "[]")

# Generar JSON de Output para orchestrator-engine
OUTPUT_JSON=$(jq -n \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg val "${SCRIPT_NAME%.sh}" \
  --arg ver "$VERSION" \
  --arg file "$FILE" \
  --argjson passed "$PASSED" \
  --argjson issues "$ISSUES_JSON" \
  --arg count "${#ISSUES[@]}" \
  --arg ms "$ELAPSED_MS" \
  '{validator: $val, version: $ver, timestamp: $ts, file: $file, passed: $passed, issues: $issues, issues_count: ($count | tonumber), performance_ms: ($ms | tonumber)}'
)

echo "$OUTPUT_JSON"

# Registrar en el archivo JSONL
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$(date -u +%Y-%m-%d).jsonl"
echo "$OUTPUT_JSON" >> "$LOG_FILE"

if [[ "$PASSED" == true ]]; then
  exit 0
else
  exit 1
fi
