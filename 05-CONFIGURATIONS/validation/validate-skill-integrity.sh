#!/usr/bin/env bash
# SHA256: f9e2a5c8b1d4e7a0f3c6b9d2e5a8c1b4d7e0a3f6c9b2d5e8a1f4c7b0d3e6a9c2
---
artifact_id: "validate-skill-integrity"
artifact_type: "skill_bash"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C3","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/validation/validate-skill-integrity.sh --json"
canonical_path: "05-CONFIGURATIONS/validation/validate-skill-integrity.sh"
---
# validate-skill-integrity.sh – Structural integrity validation for MANTIS AGENTIC skills (C5 + selective V*)
# HARNESS NORMS v3.0-SELECTIVE compliant | LANGUAGE LOCK: Bash only, zero pgvector operators
# Usage: bash validate-skill-integrity.sh --file <path> [--json] [--verbose] [--strict]
# Output: JSON summary to stdout (if --json), structured logs to stderr (C8)

set -Eeuo pipefail
readonly SCRIPT_NAME="validate-skill-integrity.sh"
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
Usage: validate-skill-integrity.sh --file <path> [OPTIONS]

Validates structural integrity of skill artifacts per HARNESS NORMS v3.0-SELECTIVE.

Required:
  --file <path>    Path to skill Markdown file to validate

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

log "INFO" "Starting skill integrity validation" "$FILE"

# =============================================================================
# FRONTMATTER PARSING
# =============================================================================
extract_field() {
  local field="$1" file="$2"
  grep -E "^${field}:" "$file" 2>/dev/null | head -1 | sed -E "s/^${field}:\s*['\"]?//" | sed -E "s/['\"]?\s*$//" || echo ""
}

ARTIFACT_ID=$(extract_field "artifact_id" "$FILE")
ARTIFACT_TYPE=$(extract_field "artifact_type" "$FILE")
VERSION_FIELD=$(extract_field "version" "$FILE")
CONSTRAINTS_MAPPED=$(extract_field "constraints_mapped" "$FILE")
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
BROKEN_LINKS=0
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

# C5: Count examples (✅/❌/🔧 patterns)
count_examples() {
  local file="$1"
  grep -cE '^-- ✅|^-- ❌' "$file" 2>/dev/null || echo "0"
}

# C5: Verify frontmatter required fields
validate_frontmatter() {
  local file="$1"
  local required_fields=("artifact_id" "artifact_type" "version" "constraints_mapped" "validation_command" "canonical_path")
  
  for field in "${required_fields[@]}"; do
    CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
    if grep -qE "^${field}:" "$file" 2>/dev/null; then
      CHECKS_PASSED=$((CHECKS_PASSED + 1))
      log_debug "Frontmatter field '$field' present" "$file"
    else
      add_error "Missing required frontmatter field: $field" "MISSING_FRONTMATTER_$field"
      adjust_score -3
    fi
  done
}

# C5: Validate wikilinks [[path]] resolution
validate_wikilinks() {
  local file="$1"
  local wikilinks
  wikilinks=$(grep -oE '\[\[[^]]+\]\]' "$file" 2>/dev/null | sort -u || true)
  
  if [[ -n "$wikilinks" ]]; then
    while IFS= read -r link; do
      [[ -z "$link" ]] && continue
      local raw="${link#[[}"
      raw="${raw%]]}"
      raw=$(echo "$raw" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
      
      [[ -z "$raw" || "$raw" == */ || "$raw" == http* ]] && continue
      
      local resolved
      if [[ "$raw" == /* ]]; then
        resolved="${PROJECT_ROOT}${raw}"
      else
        local base_dir
        base_dir=$(dirname "$(realpath -m "$FILE")")
        resolved="${base_dir}/${raw}"
      fi
      
      resolved=$(realpath -m "$resolved" 2>/dev/null || echo "$resolved")
      
      CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
      if [[ -f "$resolved" ]]; then
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
        log_debug "Wikilink resolved: $link → $resolved" "$file"
      else
        add_warning "Wikilink may be broken: $link → $resolved" "BROKEN_WIKILINK"
        BROKEN_LINKS=$((BROKEN_LINKS + 1))
        adjust_score -1
      fi
    done <<< "$wikilinks"
  fi
}

# C5: Validate example count (≥10 general, ≥25 for skill_pgvector)
validate_examples() {
  local file="$1"
  EXAMPLES_FOUND=$(count_examples "$file")
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

# Selective V1-V3 validation for pgvector artifacts only
validate_vector_constraints() {
  local file="$1"
  
  # Only apply V* validation if pgvector context AND operators present
  if [[ "$IS_PGVECTOR_DIR" == true ]] && [[ "$HAS_VECTOR_OPS" == true ]]; then
    
    # V1: Dimension validation patterns
    if echo "$CONSTRAINTS_MAPPED" | grep -q "V1"; then
      CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
      if grep -qE 'vector\([0-9]+\).*CHECK|array_length.*=.*[0-9]+|validate_vec_dim' "$file"; then
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
        CONSTRAINT_COVERAGE["V1"]=true
        adjust_score +3
        log "INFO" "V1 validation passed: dimension constraints detected" "$file"
      else
        add_warning "V1 mapped but no dimension validation patterns found" "V1_NO_COVERAGE"
        adjust_score -3
      fi
    fi
    
    # V2: Distance metric documentation
    if echo "$CONSTRAINTS_MAPPED" | grep -q "V2"; then
      CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
      if grep -qE '<->.*L2|<=>.*cosine|<#>.*inner|ORDER BY.*<->|ORDER BY.*<=>|ORDER BY.*<#>' "$file"; then
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
        CONSTRAINT_COVERAGE["V2"]=true
        adjust_score +3
        log "INFO" "V2 validation passed: distance operators documented" "$file"
      else
        add_warning "V2 mapped but distance operators not clearly documented" "V2_NO_COVERAGE"
        adjust_score -3
      fi
    fi
    
    # V3: Index justification patterns
    if echo "$CONSTRAINTS_MAPPED" | grep -q "V3"; then
      CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
      if grep -qE 'USING\s+hnsw.*WITH|USING\s+ivfflat.*WITH|CONCURRENTLY.*hnsw|CONCURRENTLY.*ivfflat' "$file"; then
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
        CONSTRAINT_COVERAGE["V3"]=true
        adjust_score +3
        log "INFO" "V3 validation passed: index parameters justified" "$file"
      else
        add_warning "V3 mapped but index parameters not justified" "V3_NO_COVERAGE"
        adjust_score -3
      fi
    fi
  else
    # Non-pgvector artifact: ensure V* not incorrectly mapped
    if echo "$CONSTRAINTS_MAPPED" | grep -qE 'V1|V2|V3'; then
      add_warning "V* constraints mapped in non-pgvector artifact ($ARTIFACT_TYPE)" "SELECTIVE_V_VIOLATION"
      adjust_score -2
    fi
  fi
}

# LANGUAGE LOCK: Detect pgvector operators in non-pgvector directories
validate_language_lock() {
  local file="$1"
  local file_dir
  file_dir=$(dirname "$file")
  
  # pgvector operators prohibited in sql/, yaml-json-schema/, go/
  if [[ "$file_dir" == *"/sql"* || "$file_dir" == *"/yaml-json-schema"* || "$file_dir" == *"/go"* ]]; then
    if grep -qE '<->|<=>|<#>|vector\s*\(|USING\s+hnsw|USING\s+ivfflat' "$file"; then
      add_error "LANGUAGE LOCK VIOLATION: pgvector operators detected in $file_dir" "LANG_LOCK_VIOLATION"
      adjust_score -15
      return 1
    fi
  fi
  return 0
}

# C8: Validate structured logging patterns in examples
validate_structured_logging() {
  local file="$1"
  
  # Check if C8 is mapped and if examples use structured logging
  if echo "$CONSTRAINTS_MAPPED" | grep -q "C8"; then
    CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
    if grep -qE 'json_build_object|logger.*stderr|print\(.*file=sys.stderr|RAISE NOTICE.*json' "$file"; then
      CHECKS_PASSED=$((CHECKS_PASSED + 1))
      adjust_score +4
      log "INFO" "C8 validation passed: structured logging patterns detected" "$file"
    else
      add_warning "C8 mapped but no structured logging patterns found in examples" "C8_NO_COVERAGE"
      adjust_score -2
    fi
  fi
}

# =============================================================================
# MAIN VALIDATION FLOW
# =============================================================================
main() {
  log "INFO" "Validating artifact: $ARTIFACT_ID (type: $ARTIFACT_TYPE)" "$FILE"
  
  # 1. LANGUAGE LOCK check (blocking)
  if ! validate_language_lock "$FILE"; then
    generate_report
    exit 1
  fi
  
  # 2. Frontmatter validation (C5)
  validate_frontmatter "$FILE"
  
  # 3. Example count validation (C5)
  validate_examples "$FILE"
  
  # 4. Wikilink resolution (C5)
  validate_wikilinks "$FILE"
  
  # 5. Constraint coverage validation (C5)
  validate_constraint_coverage "$FILE"
  
  # 6. Selective V1-V3 validation (if applicable)
  validate_vector_constraints "$FILE"
  
  # 7. Structured logging validation (C8)
  validate_structured_logging "$FILE"
  
  # 8. Canonical path consistency check
  if [[ -n "$CANONICAL_PATH" ]]; then
    local expected_path="${PROJECT_ROOT}/${CANONICAL_PATH}"
    local file_real
    file_real=$(realpath -m "$FILE" 2>/dev/null || echo "$FILE")
    local expected_real
    expected_real=$(realpath -m "$expected_path" 2>/dev/null || echo "$expected_path")
    
    if [[ "$file_real" != "$expected_real" ]]; then
      add_warning "canonical_path mismatch: declared '$CANONICAL_PATH' vs actual '$FILE'" "PATH_MISMATCH"
      adjust_score -2
    fi
  fi
  
  # 9. Strict mode: promote warnings to errors
  if [[ "$STRICT" == true ]] && [[ ${#WARNINGS[@]} -gt 0 ]]; then
    for warning in "${WARNINGS[@]}"; do
      ERRORS+=("$warning")
    done
    WARNINGS=()
  fi
  
  # 10. Final scoring and status
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
    coverage_json=$(for k in "${!CONSTRAINT_COVERAGE[@]}"; do echo "\"$k\":${CONSTRAINT_COVERAGE[$k]}"; done | paste -sd, | sed 's/^/{/;s/$/}/')
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
  "constraints_mapped": $(echo "$CONSTRAINTS_MAPPED" | jq -R 'split(",") | map(gsub("^\\[|\\]$";"") | gsub("\"";"") | split(",") | map(trim) | map(select(length>0))) | flatten | unique' 2>/dev/null || echo "[]"),
  "constraints_covered": $coverage_json,
  "examples_found": $EXAMPLES_FOUND,
  "broken_links": $BROKEN_LINKS,
  "canonical_path": "$CANONICAL_PATH",
  "file_path": "$FILE",
  "validation_context": {
    "is_pgvector_directory": $IS_PGVECTOR_DIR,
    "has_vector_operators": $HAS_VECTOR_OPS,
    "selective_v_applied": $([ "$IS_PGVECTOR_DIR" = true ] && [ "$HAS_VECTOR_OPS" = true ] && echo true || echo false)
  },
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
)
  
  if [[ "$JSON_OUTPUT" == true ]]; then
    echo "$json_output"
  else
    echo "=== Skill Integrity Validation Summary ==="
    echo "Artifact: $ARTIFACT_ID ($ARTIFACT_TYPE v$VERSION_FIELD)"
    echo "Score: $SCORE/100"
    echo "Status: $([ "$passed" = true ] && echo "✅ PASSED" || echo "❌ FAILED")"
    echo "Examples: $EXAMPLES_FOUND"
    echo "Broken links: $BROKEN_LINKS"
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
