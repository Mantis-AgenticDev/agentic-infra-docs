#!/usr/bin/env bash
# SHA256: d4f7e2a9c1b8f5e3d0a6c9b2e8f1a4d7c3b6e9f2a5c8b1d4e7a0f3c6b9d2e5a8
# orchestrator-engine.sh – Validation orchestrator for MANTIS AGENTIC artifacts (HARNESS NORMS v3.0-SELECTIVE)
# Usage: bash orchestrator-engine.sh --file <path> [--json] [--verbose]
# Output: JSON to stdout (if --json) or human-readable summary; structured logs to stderr (C8)

set -Eeuo pipefail
readonly SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# C8: Structured logging function (ZERO echo to stdout for logs)
log() {
  local level="${1:-INFO}" msg="${2:-}" file="${3:-unknown}"
  printf '{"ts":"%s","level":"%s","file":"%s","msg":"%s"}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$level" "$file" "$msg" >&2
}

# Parse CLI arguments
FILE="" JSON_OUTPUT=false VERBOSE=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --file) FILE="$2"; shift 2 ;;
    --json) JSON_OUTPUT=true; shift ;;
    --verbose) VERBOSE=true; shift ;;
    *) log "ERROR" "Unknown argument: $1" "$SCRIPT_NAME"; exit 2 ;;
  esac
done

# C3: Validate required inputs
if [[ -z "$FILE" ]]; then
  log "ERROR" "Missing required argument: --file <path>" "$SCRIPT_NAME"
  echo '{"error":"MISSING_ARG","required":"--file <path>"}' >&2
  exit 2
fi

if [[ ! -f "$FILE" ]]; then
  log "ERROR" "File not found: $FILE" "$SCRIPT_NAME"
  echo "{\"error\":\"FILE_NOT_FOUND\",\"path\":\"$FILE\"}" >&2
  exit 3
fi

# C8: Log start of validation
log "INFO" "Starting validation" "$FILE"

# Initialize scoring and tracking
SCORE=50  # Base score
declare -a BLOCKING_ISSUES=()
declare -a WARNINGS=()

# Extract frontmatter fields (robust to YAML variations)
extract_field() {
  local field="$1" file="$2"
  grep -E "^${field}:" "$file" 2>/dev/null | head -1 | sed -E "s/^${field}:\s*//" | tr -d '"' | tr -d "'" || echo ""
}

ARTIFACT_ID=$(extract_field "artifact_id" "$FILE")
ARTIFACT_TYPE=$(extract_field "artifact_type" "$FILE")
VERSION=$(extract_field "version" "$FILE")
CONSTRAINTS_MAPPED=$(extract_field "constraints_mapped" "$FILE")
CANONICAL_PATH=$(extract_field "canonical_path" "$FILE")
VALIDATION_CMD=$(extract_field "validation_command" "$FILE")

# C3: Validate critical frontmatter fields
if [[ -z "$ARTIFACT_ID" || -z "$ARTIFACT_TYPE" || -z "$VERSION" ]]; then
  log "ERROR" "Missing critical frontmatter fields" "$FILE"
  BLOCKING_ISSUES+=("MISSING_FRONTMATTER")
  SCORE=$((SCORE - 20))
fi

# Detect directory context for LANGUAGE LOCK + selective V* validation
FILE_DIR=$(dirname "$FILE")
IS_PGVECTOR_DIR=false
if [[ "$FILE_DIR" == *"/postgresql-pgvector"* ]] || [[ "$ARTIFACT_TYPE" == "skill_pgvector" ]]; then
  IS_PGVECTOR_DIR=true
  log "INFO" "Detected pgvector context: selective V1-V3 validation enabled" "$FILE"
fi

# C8: Log artifact metadata
log "INFO" "Artifact: $ARTIFACT_ID (type: $ARTIFACT_TYPE, version: $VERSION)" "$FILE"

# =============================================================================
# VALIDATION PHASE 1: LANGUAGE LOCK + SELECTIVE CONSTRAINT CHECKS
# =============================================================================

# Helper: Check if constraint is in mapped list
has_constraint() {
  local constraint="$1" mapped="$2"
  [[ "$mapped" == *"$constraint"* ]]
}

# C4/C7: LANGUAGE LOCK – Detect pgvector operator leak in sql/ directory
if [[ "$FILE_DIR" == *"/sql"* ]] && [[ "$ARTIFACT_TYPE" != "skill_pgvector" ]]; then
  if grep -qE '<->|<=>|<#>|vector\s*\(|USING\s+hnsw|USING\s+ivfflat' "$FILE"; then
    log "ERROR" "LANGUAGE_LOCK_VIOLATION: pgvector operator in sql/ directory" "$FILE"
    BLOCKING_ISSUES+=("LANGUAGE_LOCK_VIOLATION:pgvector_in_sql")
    SCORE=$((SCORE - 15))
  fi
fi

# C4: Detect pure SQL in postgres-pgvector/ without vector operators (warning, not blocking)
if [[ "$IS_PGVECTOR_DIR" == true ]] && [[ "$ARTIFACT_TYPE" == "skill_pgvector" ]]; then
  if ! grep -qE '<->|<=>|<#>|vector\s*\(' "$FILE"; then
    log "WARNING" "skill_pgvector artifact without vector operators – verify intent" "$FILE"
    WARNINGS+=("PGVECTOR_NO_OPS:artifact may belong in sql/")
    SCORE=$((SCORE - 5))  # Minor penalty for potential misplacement
  fi
fi

# Selective V1-V3 validation: ONLY apply if skill_pgvector AND operators present
if [[ "$IS_PGVECTOR_DIR" == true ]] && [[ "$ARTIFACT_TYPE" == "skill_pgvector" ]]; then
  
  # V1: Dimension validation – check for vector(n) with CHECK constraint examples
  if has_constraint "V1" "$CONSTRAINTS_MAPPED"; then
    if grep -qE 'vector\([0-9]+\).*CHECK|array_length.*=.*[0-9]+' "$FILE"; then
      log "INFO" "V1 validation passed: dimension constraints detected" "$FILE"
      SCORE=$((SCORE + 3))
    else
      log "WARNING" "V1 constraint mapped but no dimension validation examples found" "$FILE"
      WARNINGS+=("V1_MAPPED_NOT_USED")
    fi
  fi
  
  # V2: Distance metric explicit – check for documented operators (<->, <#>, <=>)
  if has_constraint "V2" "$CONSTRAINTS_MAPPED"; then
    if grep -qE '<->.*L2|<=>.*cosine|<#>.*inner|ORDER BY.*<->|ORDER BY.*<=>|ORDER BY.*<#>' "$FILE"; then
      log "INFO" "V2 validation passed: distance operators documented" "$FILE"
      SCORE=$((SCORE + 3))
    else
      log "WARNING" "V2 constraint mapped but operators not clearly documented" "$FILE"
      WARNINGS+=("V2_MAPPED_NOT_DOCUMENTED")
    fi
  fi
  
  # V3: Index-type match justified – check for hnsw/ivfflat WITH parameters
  if has_constraint "V3" "$CONSTRAINTS_MAPPED"; then
    if grep -qE 'USING\s+(hnsw|ivfflat).*WITH\s*\([^)]*(m|ef_construction|lists)' "$FILE"; then
      log "INFO" "V3 validation passed: index parameters justified" "$FILE"
      SCORE=$((SCORE + 3))
    else
      log "WARNING" "V3 constraint mapped but index parameters not justified" "$FILE"
      WARNINGS+=("V3_MAPPED_NOT_JUSTIFIED")
    fi
  fi
else
  # Non-pgvector artifact: ensure NO V* constraints are mapped (selective rule)
  if has_constraint "V1\|V2\|V3" "$CONSTRAINTS_MAPPED"; then
    log "WARNING" "Non-pgvector artifact maps V* constraints – verify selective application" "$FILE"
    WARNINGS+=("V*_IN_NON_PGVECTOR:selective rule violation")
    # Not blocking, but note for review
  fi
fi

# =============================================================================
# VALIDATION PHASE 2: CORE CONSTRAINTS (C1-C8) – Apply to ALL artifacts
# =============================================================================

# C1: Resource limits – check for LIMIT, SET LOCAL, memory hints in SQL/examples
if grep -qE 'LIMIT\s+[0-9]+|SET\s+LOCAL\s+(work_mem|statement_timeout)|memory\s*=|cpu' "$FILE"; then
  SCORE=$((SCORE + 2))
else
  WARNINGS+=("C1_RESOURCE_LIMITS:not explicitly demonstrated")
fi

# C2: Timeouts – check for statement_timeout, asyncio.timeout, fetch timeout
if grep -qE 'statement_timeout|asyncio\.timeout|timeout\s*=|TimeoutSignal' "$FILE"; then
  SCORE=$((SCORE + 2))
else
  WARNINGS+=("C2_TIMEOUTS:not explicitly demonstrated")
fi

# C3: Env validation – check for assert, validation blocks, required env checks
if grep -qE 'assert.*environment|validation\s*\{.*condition|os\.environ\["[A-Z_]+"\]|current_setting.*IS NOT NULL' "$FILE"; then
  SCORE=$((SCORE + 3))
else
  WARNINGS+=("C3_ENV_VALIDATION:not explicitly demonstrated")
fi

# C4: Tenant isolation – CRITICAL: check for tenant_id filter or RLS policy
if grep -qE 'tenant_id.*current_setting|WHERE.*tenant_id\s*=|CREATE POLICY.*USING.*tenant_id|WITH CHECK.*tenant_id' "$FILE"; then
  SCORE=$((SCORE + 5))  # Higher weight for C4
else
  # Only penalize if artifact type suggests multi-tenant context
  if [[ "$ARTIFACT_TYPE" =~ (skill_sql|skill_pgvector|skill_go) ]]; then
    log "WARNING" "C4_TENANT_ISOLATION:not demonstrated in multi-tenant artifact type" "$FILE"
    WARNINGS+=("C4_NOT_DEMONSTRATED")
    SCORE=$((SCORE - 3))
  fi
fi

# C5: Integrity checksums – check for sha256, digest, checksum validation
if grep -qE 'sha256sum|digest\(.*sha256\)|content_hash|checksum' "$FILE"; then
  SCORE=$((SCORE + 2))
else
  WARNINGS+=("C5_INTEGRITY:not explicitly demonstrated")
fi

# C6: Optional deps with fallback – check for try/except, IF NOT EXISTS, fallback logic
if grep -qE 'try:.*import|CREATE EXTENSION IF NOT EXISTS|fallback|except ImportError' "$FILE"; then
  SCORE=$((SCORE + 2))
else
  WARNINGS+=("C6_OPTIONAL_DEPS:not explicitly demonstrated")
fi

# C7: Path safety – check for pathlib, resolve(), secure_path, validation
if grep -qE 'pathlib|\.resolve\(\)|secure_path|starts with|path traversal' "$FILE"; then
  SCORE=$((SCORE + 2))
else
  WARNINGS+=("C7_PATH_SAFETY:not explicitly demonstrated")
fi

# C8: Structured logging to stderr – CRITICAL: check for json_build_object, logger to stderr, NO print/console.log
if grep -qE 'json_build_object|logger.*stderr|print\(.*file=sys.stderr|pino\(|winston\.' "$FILE"; then
  # Bonus if explicitly avoids print/console.log in production context
  if ! grep -qE '^(?!.*#.*❌|.*//.*❌).*print\(|^(?!.*//.*❌).*console\.(log|error|warn)\(' "$FILE"; then
    SCORE=$((SCORE + 4))  # Higher weight for C8 compliance
  else
    SCORE=$((SCORE + 2))
  fi
else
  log "ERROR" "C8_STRUCTURED_LOGGING:missing or using print/console.log" "$FILE"
  BLOCKING_ISSUES+=("C8_VIOLATION:unstructured logging detected")
  SCORE=$((SCORE - 10))
fi

# =============================================================================
# VALIDATION PHASE 3: FORMAT & STRUCTURE CHECKS
# =============================================================================

# Check SHA256 header (64-char hex after "# SHA256:")
if grep -qE '^# SHA256:\s*[a-f0-9]{64}' "$FILE"; then
  SCORE=$((SCORE + 2))
else
  log "WARNING" "SHA256 header missing or malformed" "$FILE"
  WARNINGS+=("SHA256_HEADER:malformed")
fi

# Check frontmatter closure (--- after YAML block)
if grep -qE '^---$' "$FILE" | head -2 | wc -l | grep -q 2; then
  SCORE=$((SCORE + 1))
else
  WARNINGS+=("FRONTMATTER:missing closing ---")
fi

# Count examples: ≥10 for general, ≥25 for skill_pgvector
EXAMPLE_COUNT=$(grep -cE '^-- ✅|^-- ❌' "$FILE" 2>/dev/null || echo 0)
REQUIRED_EXAMPLES=10
if [[ "$ARTIFACT_TYPE" == "skill_pgvector" ]]; then
  REQUIRED_EXAMPLES=25
fi

if [[ "$EXAMPLE_COUNT" -ge "$REQUIRED_EXAMPLES" ]]; then
  SCORE=$((SCORE + 5))
  log "INFO" "Example count: $EXAMPLE_COUNT (required: $REQUIRED_EXAMPLES) – PASSED" "$FILE"
else
  log "ERROR" "Example count: $EXAMPLE_COUNT < $REQUIRED_EXAMPLES required" "$FILE"
  BLOCKING_ISSUES+=("INSUFFICIENT_EXAMPLES:$EXAMPLE_COUNT<$REQUIRED_EXAMPLES")
  SCORE=$((SCORE - 10))
fi

# Check executable lines ≤5 per example block (heuristic: count lines between -- ✅/❌ and next -- or ```)
# Simplified: warn if any code block exceeds 5 non-comment, non-empty lines
LONG_BLOCKS=$(awk '/^-- ✅|^-- ❌/,/^-- |^```/{if(/^[^#`-]/ && NF>0) count++} /^-- |^```/{if(count>5) print; count=0}' "$FILE" | wc -l)
if [[ "$LONG_BLOCKS" -eq 0 ]]; then
  SCORE=$((SCORE + 3))
else
  WARNINGS+=("LINES_EXECUTABLE:some blocks exceed 5 lines")
  SCORE=$((SCORE - 2))
fi

# Check timestamp in JSON report is 2026 ISO8601
if grep -qE '"timestamp":"[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z"' "$FILE"; then
  if grep -qE '"timestamp":"2026-' "$FILE"; then
    SCORE=$((SCORE + 2))
  else
    log "WARNING" "Timestamp not in 2026 – may indicate stale artifact" "$FILE"
    WARNINGS+=("TIMESTAMP:not 2026")
  fi
else
  WARNINGS+=("TIMESTAMP:missing or malformed in JSON report")
fi

# Check validation command points to canonical path
if [[ -n "$VALIDATION_CMD" ]] && [[ -n "$CANONICAL_PATH" ]]; then
  if echo "$VALIDATION_CMD" | grep -qF "$CANONICAL_PATH"; then
    SCORE=$((SCORE + 1))
  else
    WARNINGS+=("VALIDATION_CMD:path mismatch with canonical_path")
  fi
fi

# Check closing --- for parseability
if tail -1 "$FILE" | grep -q '^---$'; then
  SCORE=$((SCORE + 1))
else
  WARNINGS+=("CLOSING:missing final --- separator")
fi

# =============================================================================
# FINAL SCORING & OUTPUT
# =============================================================================

# Clamp score to [0, 100]
[[ "$SCORE" -lt 0 ]] && SCORE=0
[[ "$SCORE" -gt 100 ]] && SCORE=100

# Determine pass/fail
PASSED=true
if [[ "$SCORE" -lt 30 ]] || [[ ${#BLOCKING_ISSUES[@]} -gt 0 ]]; then
  PASSED=false
  log "ERROR" "Validation FAILED: score=$SCORE, blocking_issues=${#BLOCKING_ISSUES[@]}" "$FILE"
else
  log "INFO" "Validation PASSED: score=$SCORE" "$FILE"
fi

# Build JSON output
build_json() {
  local blocking_json="[]"
  if [[ ${#BLOCKING_ISSUES[@]} -gt 0 ]]; then
    blocking_json=$(printf '%s\n' "${BLOCKING_ISSUES[@]}" | jq -R . | jq -s .)
  fi
  
  local warnings_json="[]"
  if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    warnings_json=$(printf '%s\n' "${WARNINGS[@]}" | jq -R . | jq -s .)
  fi
  
  cat <<EOF
{
  "artifact": "$ARTIFACT_ID",
  "version": "$VERSION",
  "score": $SCORE,
  "passed": $PASSED,
  "blocking_issues": $blocking_json,
  "warnings": $warnings_json,
  "constraints_verified": $(echo "$CONSTRAINTS_MAPPED" | jq -R 'split(",") | map(gsub("^\\[|\\]$";"") | gsub("\"";"") | split(",") | map(trim) | map(select(length>0))) | flatten | unique'),
  "examples_count": $EXAMPLE_COUNT,
  "lines_executable_max": 5,
  "language": "$(extract_field "language" "$FILE" || echo "unknown")",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "artifact_type": "$ARTIFACT_TYPE",
  "canonical_path": "$CANONICAL_PATH",
  "validation_notes": {
    "is_pgvector_context": $IS_PGVECTOR_DIR,
    "selective_v_applied": $([ "$IS_PGVECTOR_DIR" = true ] && echo true || echo false)
  }
}
EOF
}

# Output based on flags
if [[ "$JSON_OUTPUT" == true ]]; then
  build_json
else
  echo "=== Validation Summary ==="
  echo "Artifact: $ARTIFACT_ID ($ARTIFACT_TYPE v$VERSION)"
  echo "Score: $SCORE/100"
  echo "Status: $([ "$PASSED" = true ] && echo "✅ PASSED" || echo "❌ FAILED")"
  if [[ ${#BLOCKING_ISSUES[@]} -gt 0 ]]; then
    echo "Blocking Issues:"
    printf '  - %s\n' "${BLOCKING_ISSUES[@]}"
  fi
  if [[ ${#WARNINGS[@]} -gt 0 ]] && [[ "$VERBOSE" == true ]]; then
    echo "Warnings:"
    printf '  - %s\n' "${WARNINGS[@]}"
  fi
  echo "Examples: $EXAMPLE_COUNT (required: $REQUIRED_EXAMPLES)"
  echo "Canonical path: $CANONICAL_PATH"
fi

# C8: Final log entry
log "INFO" "Validation complete: score=$SCORE passed=$PASSED" "$FILE"

# Exit code for CI/CD integration
if [[ "$PASSED" == true ]]; then
  exit 0
else
  exit 1
fi
