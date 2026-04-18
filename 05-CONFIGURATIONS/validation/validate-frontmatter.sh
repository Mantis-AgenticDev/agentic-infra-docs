#!/usr/bin/env bash
# SHA256: c8f3e9a2b1d7f4e6a0c5b9d2e8f1a4c7b3d6e9f2a5c8b1d4e7a0f3c6b9d2e5a8
---
artifact_id: "validate-frontmatter"
artifact_type: "skill_bash"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C3","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/validation/validate-frontmatter.sh --json"
canonical_path: "05-CONFIGURATIONS/validation/validate-frontmatter.sh"
---
# validate-frontmatter.sh – Frontmatter YAML validation for MANTIS AGENTIC artifacts (C5 + selective V*)
# HARNESS NORMS v3.0-SELECTIVE compliant | LANGUAGE LOCK: Bash only, zero pgvector operators
# Usage: bash validate-frontmatter.sh --file <path> [--json] [--verbose] [--strict]
# Output: JSON summary to stdout (if --json), structured logs to stderr (C8)

set -Eeuo pipefail
readonly SCRIPT_NAME="validate-frontmatter.sh"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly VERSION="3.0.0-SELECTIVE"

# =============================================================================
# C8: STRUCTURED LOGGING (ZERO echo to stdout for logs)
# =============================================================================
log() {
  local level="${1:-INFO}" msg="${2:-}" file="${3:-unknown}"
  printf '{"ts":"%s","level":"%s","script":"%s","file":"%s","msg":"%s"}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$level" "$SCRIPT_NAME" "$file" "$msg" >&2
}

log_debug() { [[ "${DEBUG:-false}" == "true" ]] && log "DEBUG" "$1" "$2" || true; }

# =============================================================================
# CLI ARGUMENT PARSING
# =============================================================================
FILE="" JSON_OUTPUT=false VERBOSE=false STRICT=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --file) FILE="$2"; shift 2 ;;
    --json) JSON_OUTPUT=true; shift ;;
    --verbose) VERBOSE=true; shift ;;
    --strict) STRICT=true; shift ;;
    -h|--help)
      cat << 'HELP'
Usage: validate-frontmatter.sh --file <path> [OPTIONS]

Validates frontmatter YAML structure per HARNESS NORMS v3.0-SELECTIVE.

Required:
  --file <path>    Path to Markdown/Bash file to validate

Optional:
  --json           Output machine-readable JSON summary
  --verbose        Show detailed warnings
  --strict         Treat warnings as blocking issues

Exit codes:
  0  - Validation passed
  1  - Validation failed (warnings in strict mode or errors)
  2  - Invalid arguments or file not found
HELP
      exit 0 ;;
    *) log "ERROR" "Unknown argument: $1" "$SCRIPT_NAME"; exit 2 ;;
  esac
done

# C3: Validate required inputs
if [[ -z "$FILE" ]]; then
  log "ERROR" "Missing required argument: --file <path>" "$SCRIPT_NAME"
  echo '{"error":"MISSING_ARG","required":"--file"}' >&2
  exit 2
fi

if [[ ! -f "$FILE" ]]; then
  log "ERROR" "File not found: $FILE" "$SCRIPT_NAME"
  echo "{\"error\":\"FILE_NOT_FOUND\",\"path\":\"$FILE\"}" >&2
  exit 3
fi

log "INFO" "Starting frontmatter validation" "$FILE"

# =============================================================================
# FRONTMATTER PARSING (Robust to #--- for Bash, --- for Markdown)
# =============================================================================
extract_field() {
  local field="$1" file="$2"
  # Handle both YAML and commented YAML (# field: value)
  grep -E "^#?[[:space:]]*${field}:" "$file" 2>/dev/null | head -1 | \
    sed -E "s/^#?[[:space:]]*${field}:[[:space:]]*//" | \
    sed -E "s/['\"]//g" | sed -E "s/[[:space:]]*$//" || echo ""
}

extract_array_field() {
  local field="$1" file="$2"
  # Extract array like ["C1","C2"] or [ "C1", "C2" ]
  grep -E "^#?[[:space:]]*${field}:" "$file" 2>/dev/null | head -1 | \
    grep -oE '\[[^]]+\]' | tr -d ' ' || echo "[]"
}

ARTIFACT_ID=$(extract_field "artifact_id" "$FILE")
ARTIFACT_TYPE=$(extract_field "artifact_type" "$FILE")
VERSION_FIELD=$(extract_field "version" "$FILE")
CONSTRAINTS_MAPPED=$(extract_array_field "constraints_mapped" "$FILE")
CANONICAL_PATH=$(extract_field "canonical_path" "$FILE")

# =============================================================================
# CONTEXT DETECTION FOR SELECTIVE VALIDATION
# =============================================================================
FILE_DIR=$(dirname "$FILE")
IS_PGVECTOR_DIR=false
[[ "$FILE_DIR" == *"/postgresql-pgvector"* ]] && IS_PGVECTOR_DIR=true
[[ "$ARTIFACT_TYPE" == "skill_pgvector" ]] && IS_PGVECTOR_DIR=true

HAS_VECTOR_OPS=false
if grep -qE '<->|<=>|<#>|vector\s*\(|USING\s+hnsw|USING\s+ivfflat' "$FILE" 2>/dev/null; then
  HAS_VECTOR_OPS=true
fi

# =============================================================================
# TRACKING & SCORING
# =============================================================================
declare -a WARNINGS=()
declare -a ERRORS=()
declare -A CONSTRAINT_COVERAGE=()
CHECKS_PASSED=0
CHECKS_TOTAL=0
EXAMPLES_FOUND=0
SCORE=50

add_warning() {
  local msg="$1" code="${2:-WARNING}"
  WARNINGS+=("{\"code\":\"$code\",\"message\":\"$msg\"}")
  [[ "$VERBOSE" == true ]] && log "WARNING" "[$code] $msg" "$FILE" || true
}

add_error() {
  local msg="$1" code="${3:-ERROR}"
  ERRORS+=("{\"code\":\"$code\",\"message\":\"$msg\"}")
  log "ERROR" "[$code] $msg" "$FILE"
}

adjust_score() {
  local delta="$1"
  SCORE=$((SCORE + delta))
  [[ "$SCORE" -lt 0 ]] && SCORE=0
  [[ "$SCORE" -gt 100 ]] && SCORE=100
}

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

# C5: Validate frontmatter delimiters (--- or # --- for Bash)
validate_frontmatter_delimiters() {
  local file="$1"
  local ext="${file##*.}"
  
  CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
  if [[ "$ext" == "sh" || "$ext" == "bash" ]]; then
    # Bash files use commented frontmatter: # ---
    if grep -qE '^#[[:space:]]*---$' "$file" && grep -cE '^#[[:space:]]*---$' "$file" | grep -q 2; then
      CHECKS_PASSED=$((CHECKS_PASSED + 1))
      adjust_score +2
      log_debug "Bash frontmatter delimiters valid" "$file"
    else
      add_error "Bash file missing commented frontmatter delimiters (# ---)" "FM_DELIMITER_BASH"
      adjust_score -5
    fi
  else
    # Markdown/YAML files use plain ---
    if grep -qE '^---$' "$file" && grep -cE '^---$' "$file" | grep -q 2; then
      CHECKS_PASSED=$((CHECKS_PASSED + 1))
      adjust_score +2
      log_debug "Markdown frontmatter delimiters valid" "$file"
    else
      add_error "File missing frontmatter delimiters (---)" "FM_DELIMITER_MD"
      adjust_score -5
    fi
  fi
}

# C5: Validate required frontmatter fields
validate_required_fields() {
  local file="$1"
  local required_fields=("artifact_id" "artifact_type" "version" "constraints_mapped" "validation_command" "canonical_path")
  
  for field in "${required_fields[@]}"; do
    CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
    local value
    value=$(extract_field "$field" "$file")
    if [[ -n "$value" ]]; then
      CHECKS_PASSED=$((CHECKS_PASSED + 1))
      log_debug "Frontmatter field '$field' present: $value" "$file"
    else
      add_error "Missing required frontmatter field: $field" "MISSING_FM_$field"
      adjust_score -3
    fi
  done
}

# C5: Validate version is semver
validate_semver() {
  local file="$1"
  local version
  version=$(extract_field "version" "$file")
  
  CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
  if [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]]; then
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
    adjust_score +2
    log_debug "Version is valid semver: $version" "$file"
  else
    add_warning "Version '$version' is not valid semver (expected X.Y.Z)" "INVALID_SEMVER"
    adjust_score -2
  fi
}

# C5: Validate constraints_mapped array format
validate_constraints_mapped() {
  local file="$1"
  local mapped
  mapped=$(extract_array_field "constraints_mapped" "$file")
  
  CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
  # Check if it looks like a JSON array with constraint codes
  if [[ "$mapped" =~ ^\[.*\]$ ]] && echo "$mapped" | grep -qE '"C[1-8]"|"V[1-3]"'; then
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
    adjust_score +2
    log_debug "constraints_mapped format valid: $mapped" "$file"
  else
    add_warning "constraints_mapped format invalid or empty" "INVALID_CONSTRAINTS_MAPPED"
    adjust_score -2
  fi
}

# C5: Validate canonical_path consistency with actual file location
validate_canonical_path() {
  local file="$1"
  local canonical
  canonical=$(extract_field "canonical_path" "$file")
  
  [[ -z "$canonical" ]] && return
  
  CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
  local expected_path="${PROJECT_ROOT}/${canonical}"
  local file_real
  file_real=$(realpath -m "$file" 2>/dev/null || echo "$file")
  local expected_real
  expected_real=$(realpath -m "$expected_path" 2>/dev/null || echo "$expected_path")
  
  if [[ "$file_real" == "$expected_real" ]]; then
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
    adjust_score +2
    log_debug "canonical_path matches actual location" "$file"
  else
    add_warning "canonical_path mismatch: declared '$canonical' vs actual '$file'" "PATH_MISMATCH"
    adjust_score -2
  fi
}

# C5: Validate validation_command references canonical_path
validate_validation_command() {
  local file="$1"
  local cmd
  cmd=$(extract_field "validation_command" "$file")
  local canonical
  canonical=$(extract_field "canonical_path" "$file")
  
  [[ -z "$cmd" || -z "$canonical" ]] && return
  
  CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
  if echo "$cmd" | grep -qF "$canonical"; then
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
    adjust_score +1
    log_debug "validation_command references canonical_path" "$file"
  else
    add_warning "validation_command does not reference canonical_path" "CMD_PATH_MISMATCH"
    adjust_score -1
  fi
}

# C5: Validate example count (≥10 general, ≥25 for skill_pgvector)
validate_examples() {
  local file="$1"
  EXAMPLES_FOUND=$(grep -cE '^-- ✅|^-- ❌' "$file" 2>/dev/null || echo "0")
  local required=10
  [[ "$ARTIFACT_TYPE" == "skill_pgvector" ]] && required=25
  
  CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
  if [[ "$EXAMPLES_FOUND" -ge "$required" ]]; then
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
    adjust_score +5
    log "INFO" "Example count: $EXAMPLES_FOUND (required: $required) - PASSED" "$file"
  else
    add_error "Insufficient examples: $EXAMPLES_FOUND found, $required required for $ARTIFACT_TYPE" "INSUFFICIENT_EXAMPLES"
    adjust_score -10
  fi
}

# C5: Validate constraint coverage (each mapped constraint has at least one example)
validate_constraint_coverage() {
  local file="$1"
  local mapped
  mapped=$(echo "$CONSTRAINTS_MAPPED" | tr -d '[]"' | tr ',' '\n' | tr -d ' ')
  
  for constraint in $mapped; do
    [[ -z "$constraint" || ! "$constraint" =~ ^(C[1-8]|V[1-3])$ ]] && continue
    
    CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
    # Check if constraint appears in example context (✅/❌ block)
    if grep -B2 -A5 '^-- ✅\|^-- ❌' "$file" 2>/dev/null | grep -qE "$constraint[[:space:]]*:"; then
      CHECKS_PASSED=$((CHECKS_PASSED + 1))
      CONSTRAINT_COVERAGE["$constraint"]=true
      log_debug "Constraint $constraint has example coverage" "$file"
    else
      add_warning "Constraint '$constraint' mapped but no example demonstrates it" "CONSTRAINT_NO_COVERAGE_$constraint"
      adjust_score -1
    fi
  done
}

# Selective V1-V3 validation: NOT applicable for this script (skill_bash)
# But we validate that V* are NOT incorrectly mapped
validate_selective_vector_constraints() {
  local file="$1"
  
  # This is a bash validation script, NOT a pgvector skill
  # V1-V3 should NEVER be mapped here
  if echo "$CONSTRAINTS_MAPPED" | grep -qE '"V1"|"V2"|"V3"'; then
    add_error "V* constraints incorrectly mapped in skill_bash artifact" "SELECTIVE_V_VIOLATION"
    adjust_score -5
  else
    CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
    log_debug "V* correctly excluded from non-pgvector artifact" "$file"
  fi
}

# LANGUAGE LOCK: Detect pgvector operators in this bash script (should never happen)
validate_language_lock() {
  local file="$1"
  
  # This script is in validation/, not postgresql-pgvector/
  # pgvector operators are PROHIBITED here
  if grep -qE '<->|<=>|<#>|vector\s*\(|USING\s+hnsw|USING\s+ivfflat' "$file"; then
    add_error "LANGUAGE LOCK VIOLATION: pgvector operators detected in validation script" "LANG_LOCK_VIOLATION"
    adjust_score -15
    return 1
  fi
  return 0
}

# C8: Validate that this script itself uses structured logging
validate_script_structured_logging() {
  local file="$1"
  
  CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
  # This script should use log() function that outputs JSON to stderr
  if grep -qE 'printf.*json.*>&2|log\(\).*stderr' "$file"; then
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
    adjust_score +4
    log_debug "Script uses structured logging to stderr" "$file"
  else
    add_warning "Script may not use structured logging consistently" "C8_SCRIPT_SELF_CHECK"
    adjust_score -2
  fi
}

# =============================================================================
# MAIN VALIDATION FLOW
# =============================================================================
main() {
  log "INFO" "Validating frontmatter: $ARTIFACT_ID (type: $ARTIFACT_TYPE)" "$FILE"
  
  # 1. LANGUAGE LOCK check (blocking)
  if ! validate_language_lock "$FILE"; then
    generate_report false
    exit 1
  fi
  
  # 2. Frontmatter delimiter validation (C5)
  validate_frontmatter_delimiters "$FILE"
  
  # 3. Required fields validation (C5)
  validate_required_fields "$FILE"
  
  # 4. Semver validation (C5)
  validate_semver "$FILE"
  
  # 5. constraints_mapped format validation (C5)
  validate_constraints_mapped "$FILE"
  
  # 6. canonical_path consistency (C5/C7)
  validate_canonical_path "$FILE"
  
  # 7. validation_command references canonical_path (C5)
  validate_validation_command "$FILE"
  
  # 8. Example count validation (C5)
  validate_examples "$FILE"
  
  # 9. Constraint coverage validation (C5)
  validate_constraint_coverage "$FILE"
  
  # 10. Selective V* validation (should be excluded for skill_bash)
  validate_selective_vector_constraints "$FILE"
  
  # 11. Script self-check for structured logging (C8)
  validate_script_structured_logging "$FILE"
  
  # 12. Strict mode: promote warnings to errors
  if [[ "$STRICT" == true ]] && [[ ${#WARNINGS[@]} -gt 0 ]]; then
    for warning in "${WARNINGS[@]}"; do
      ERRORS+=("$warning")
    done
    WARNINGS=()
  fi
  
  # 13. Final scoring and status
  [[ "$SCORE" -lt 0 ]] && SCORE=0
  [[ "$SCORE" -gt 100 ]] && SCORE=100
  
  local passed=true
  if [[ "$SCORE" -lt 30 ]] || [[ ${#ERRORS[@]} -gt 0 ]]; then
    passed=false
    log "ERROR" "Validation FAILED: score=$SCORE, errors=${#ERRORS[@]}" "$FILE"
  else
    log "INFO" "Validation PASSED: score=$SCORE" "$FILE"
  fi
  
  generate_report "$passed"
  
  [[ "$passed" == true ]] && exit 0 || exit 1
}

# =============================================================================
# JSON REPORT GENERATION
# =============================================================================
generate_report() {
  local passed="$1"
  
  local warnings_json="[]"
  if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    warnings_json=$(printf '%s\n' "${WARNINGS[@]}" | jq -R . 2>/dev/null | jq -s . 2>/dev/null || echo "[]")
  fi
  
  local errors_json="[]"
  if [[ ${#ERRORS[@]} -gt 0 ]]; then
    errors_json=$(printf '%s\n' "${ERRORS[@]}" | jq -R . 2>/dev/null | jq -s . 2>/dev/null || echo "[]")
  fi
  
  local coverage_json="{}"
  if [[ ${#CONSTRAINT_COVERAGE[@]} -gt 0 ]]; then
    coverage_json=$(for k in "${!CONSTRAINT_COVERAGE[@]}"; do echo "\"$k\":true"; done | paste -sd, | sed 's/^/{/;s/$/}/')
  fi
  
  local json_output
  json_output=$(cat <<EOF
{
  "artifact": "$ARTIFACT_ID",
  "artifact_type": "$ARTIFACT_TYPE",
  "version": "$VERSION_FIELD",
  "validator_version": "$VERSION",
  "score": $SCORE,
  "passed": $passed,
  "errors": $errors_json,
  "warnings": $warnings_json,
  "constraints_mapped": $(echo "$CONSTRAINTS_MAPPED" | jq -c . 2>/dev/null || echo "[]"),
  "constraints_covered": $coverage_json,
  "examples_found": $EXAMPLES_FOUND,
  "canonical_path": "$CANONICAL_PATH",
  "file_path": "$FILE",
  "validation_context": {
    "is_pgvector_directory": false,
    "has_vector_operators": false,
    "selective_v_applied": false,
    "language_lock_enforced": true
  },
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
)
  
  if [[ "$JSON_OUTPUT" == true ]]; then
    echo "$json_output"
  else
    echo "=== Frontmatter Validation Summary ==="
    echo "Artifact: $ARTIFACT_ID ($ARTIFACT_TYPE v$VERSION_FIELD)"
    echo "Score: $SCORE/100"
    echo "Status: $([ "$passed" = true ] && echo "✅ PASSED" || echo "❌ FAILED")"
    echo "Examples: $EXAMPLES_FOUND"
    if [[ ${#ERRORS[@]} -gt 0 ]]; then
      echo "Errors:"
      printf '  - %s\n' "${ERRORS[@]}"
    fi
    if [[ ${#WARNINGS[@]} -gt 0 ]] && [[ "$VERBOSE" == true ]]; then
      echo "Warnings:"
      printf '  - %s\n' "${WARNINGS[@]}"
    fi
  fi
  
  # C8: Final structured log
  log "INFO" "Validation complete: score=$SCORE passed=$passed errors=${#ERRORS[@]} warnings=${#WARNINGS[@]}" "$FILE"
}

# =============================================================================
# ENTRY POINT
# =============================================================================
main
