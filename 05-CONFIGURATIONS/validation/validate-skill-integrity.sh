#!/usr/bin/env bash
# SHA256: $(sha256sum "$0" 2>/dev/null | awk '{print $1}')
# ---
# artifact_id: "validate-skill-integrity"
# artifact_type: "skill_bash"
# version: "3.0.0-CONTRACTUAL"
# constraints_mapped: ["C5","C8"]
# canonical_path: "05-CONFIGURATIONS/validation/validate-skill-integrity.sh"
# ---
# validate-skill-integrity.sh (v3.0-CONTRACTUAL)
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
  jq -n \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg val "${SCRIPT_NAME%.sh}" \
    --arg ver "$VERSION" \
    --arg file "$FILE" \
    '{validator: $val, version: $ver, timestamp: $ts, file: $file, passed: false, issues: ["FILE_NOT_FOUND"], issues_count: 1, performance_ms: 0}'
  exit 2
fi

log_err "INFO" "Starting skill integrity validation for: $FILE"

declare -a ISSUES=()

# Las Skills deben tener una sección de descripción o propósito.
# Asumimos que deben poseer un H1 y contenido.
if ! grep -qE '^# ' "$FILE" 2>/dev/null; then
  ISSUES+=("MISSING_H1_TITLE")
fi

# Las Skills de código deben poseer bloques de código
ARTIFACT_TYPE=$(grep -E "^#?[[:space:]]*artifact_type:" "$FILE" 2>/dev/null | head -1 | \
    sed -E "s/^#?[[:space:]]*artifact_type:[[:space:]]*//" | \
    sed -E "s/['\"]//g" | sed -E "s/[[:space:]]*$//" || echo "")

if [[ "$ARTIFACT_TYPE" == "skill_"* ]]; then
    if ! grep -q '\`\`\`' "$FILE" 2>/dev/null; then
      ISSUES+=("MISSING_CODE_BLOCKS")
    fi
fi

PASSED=true
if [[ ${#ISSUES[@]} -gt 0 ]]; then
  PASSED=false
fi

END_MS=$(date +%s%3N 2>/dev/null || echo 0)
ELAPSED_MS=$((END_MS - START_MS))
[[ "$ELAPSED_MS" -lt 0 ]] && ELAPSED_MS=0

ISSUES_JSON=$(printf '%s\n' "${ISSUES[@]}" | jq -R . 2>/dev/null | jq -s . 2>/dev/null || echo "[]")

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

mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$(date -u +%Y-%m-%d).jsonl"
echo "$OUTPUT_JSON" >> "$LOG_FILE"

if [[ "$PASSED" == true ]]; then
  exit 0
else
  exit 1
fi
