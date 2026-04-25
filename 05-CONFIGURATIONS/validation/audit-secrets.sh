#!/usr/bin/env bash
# VALIDATOR_DEPENDENCIES: bash>=5.0, jq>=1.6
# EXECUTION_PROFILE: <50ms/artifact, <64MB RAM, streaming IO, 1 jq call total
# SCOPE: internal-validation-only
# INTERFACE_VERSION: v3.1-CONTRACTUAL  # ← Single file mode + logging centralizado diario
# Canonical: [[05-CONFIGURATIONS/validation/audit-secrets.sh]]

set -uo pipefail

START_MS=$(date +%s%3N 2>/dev/null || echo 0)
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VERSION="3.1.0-CONTRACTUAL"

# === CONFIGURACIÓN GLOBAL ===
readonly LOG_DIR="$PROJECT_ROOT/08-LOGS/validation/test-orchestrator-engine/${SCRIPT_NAME%.sh}"
readonly LOG_FILE="$LOG_DIR/$(date -u +%Y-%m-%d).jsonl"

declare -a FINDINGS_JSON=()
declare -a EXCLUSION_PATTERNS=("changeme" "your-" "xxx" "REDACTED" "<" ">" "null" "undefined" "pattern" "example_" "my_" "dummy_" "tutorial" "docs")

readonly -a SECRET_PATTERNS=(
  "API_KEY~sk-[a-zA-Z0-9_-]{10,}~OpenAI/Anthropic key prefix~CRITICAL"
  "API_KEY~ghp_[a-zA-Z0-9]{36,}~GitHub personal token~CRITICAL"
  "API_KEY~gho_[a-zA-Z0-9]{36,}~GitHub OAuth token~CRITICAL"
  "API_KEY~ghs_[a-zA-Z0-9]{36,}~GitHub server token~CRITICAL"
  "DB_PASSWORD~password[[:space:]]*[=:][[:space:]]*['\"]?[a-zA-Z0-9@#$%^&*!]{8,}~Hardcoded DB password~CRITICAL"
  "AWS_CRED~AKIA[0-9A-Z]{16}~AWS Access Key ID~CRITICAL"
  "AWS_CRED~aws_secret_access_key[[:space:]]*[=:][[:space:]]*['\"]?[a-zA-Z0-9/+=]{40}~AWS Secret Key~CRITICAL"
  "JWT_SECRET~jwt_secret[[:space:]]*[=:][[:space:]]*['\"]?[a-zA-Z0-9]{16,}~JWT signing secret~HIGH"
  "ENCRYPTION_KEY~encryption_key[[:space:]]*[=:][[:space:]]*['\"]?[a-zA-Z0-9]{16,}~Encryption key~HIGH"
  "WEBHOOK_URL~https://hooks\.slack\.com/services/T[A-Z0-9]+/B[A-Z0-9]+/[A-Za-z0-9]+~Slack webhook~HIGH"
  "PRIVATE_KEY~-----BEGIN (RSA|EC|OPENSSH) PRIVATE KEY-----~Private key block~CRITICAL"
)

# === LOGGING HUMANO A STDERR ===
log_err() {
  local level="${1:-INFO}" msg="${2:-}"
  printf '{"ts":"%s","level":"%s","script":"%s","msg":"%s"}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$level" "$SCRIPT_NAME" "$msg" >&2
}

mkdir -p "$LOG_DIR" 2>/dev/null || true

# === FUNCIONES DE VALIDACIÓN ===
is_excluded() {
  local line="$1" lower="${1,,}"
  [[ "$line" =~ ^[[:space:]]*# ]] && return 0
  [[ "$line" =~ ^[[:space:]]*// ]] && return 0
  [[ "$line" =~ ^[[:space:]]*\* ]] && return 0
  for p in "${EXCLUSION_PATTERNS[@]}"; do
    [[ "$lower" == *"$p"* ]] && return 0
  done
  return 1
}

add_finding() {
  local raw="$6"
  raw="${raw//\\/\\\\}"; raw="${raw//\"/\\\"}"; raw="${raw:0:120}"
  FINDINGS_JSON+=("$(jq -n -c \
    --arg c "$3" --arg d "$4" --arg s "$5" \
    --argjson l "$2" --arg sn "$raw" \
    '{constraint:"C3",category:$c,description:$d,severity:$s,line:$l,snippet:$sn}')")
}

load_context() {
  local file="$1"
  local norms="$PROJECT_ROOT/05-CONFIGURATIONS/validation/norms-matrix.json"
  [[ -f "$norms" ]] || return 0
  local folder=$(dirname "$file" | sed "s|^$PROJECT_ROOT/||")
  local exc
  exc=$(jq -r --arg f "$folder" '.[$f].c3_exceptions // [] | .[]' "$norms" 2>/dev/null || true)
  while IFS= read -r e; do [[ -n "$e" ]] && EXCLUSION_PATTERNS+=("$e"); done <<< "$exc"
}

scan_stream() {
  local file="$1" strict="${2:-0}" ln=0
  [[ ! -r "$file" ]] && return 2
  while IFS= read -r line || [[ -n "$line" ]]; do
    ((ln++))
    is_excluded "$line" && continue
    for entry in "${SECRET_PATTERNS[@]}"; do
      IFS='~' read -r cat pat desc sev <<< "$entry"
      if [[ "$line" =~ $pat ]]; then
        add_finding "$file" "$ln" "$cat" "$desc" "$sev" "$line"
        [[ "$sev" == "CRITICAL" && "$strict" == "1" ]] && return 1
      fi
    done
  done < "$file"
  return 0
}

FILE=""
STRICT="0"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --file|-f) FILE="$2"; shift 2 ;;
    --strict|-s) STRICT="1"; shift ;;
    *) shift ;;
  esac
done

if [[ -z "$FILE" || ! -f "$FILE" ]]; then
  log_err "ERROR" "File not found: $FILE"
  jq -n -c \
    --arg v "${SCRIPT_NAME%.sh}" --arg ver "$VERSION" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg f "$FILE" \
    '{validator:$v,version:$ver,timestamp:$ts,file:$f,passed:false,issues:["FILE_NOT_FOUND"],issues_count:1,performance_ms:0}'
  exit 2
fi

log_err "INFO" "Starting audit-secrets validation for: $FILE"

load_context "$FILE"
scan_stream "$FILE" "$STRICT"
rc=$?

PASSED=true
[[ $rc -eq 2 ]] && PASSED=false
[[ ${#FINDINGS_JSON[@]} -gt 0 ]] && PASSED=false

END_MS=$(date +%s%3N 2>/dev/null || echo 0)
ELAPSED_MS=$((END_MS - START_MS))
[[ "$ELAPSED_MS" -lt 0 ]] && ELAPSED_MS=0

ISSUES_JSON="[]"
[[ ${#FINDINGS_JSON[@]} -gt 0 ]] && ISSUES_JSON=$(printf '%s\n' "${FINDINGS_JSON[@]}" | jq -s -c '.')

OUTPUT_JSON=$(jq -n -c \
  --arg v "${SCRIPT_NAME%.sh}" --arg ver "$VERSION" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg f "$FILE" \
  --arg c "C3" \
  --argjson passed "$PASSED" \
  --argjson issues "$ISSUES_JSON" --argjson count "${#FINDINGS_JSON[@]}" \
  --arg ms "$ELAPSED_MS" \
  '{validator:$v,version:$ver,timestamp:$ts,file:$f,constraint:$c,passed:$passed,issues:$issues,issues_count:($count | tonumber),performance_ms:($ms | tonumber)}'
)

echo "$OUTPUT_JSON"
echo "$OUTPUT_JSON" >> "$LOG_FILE"

if [[ "$PASSED" == true ]]; then
  exit 0
else
  exit 1
fi
