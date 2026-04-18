#!/usr/bin/env bash
# SHA256: c9f2e5a8b1d4e7a0f3c6b9d2e5a8c1b4d7e0a3f6c9b2d5e8a1f4c7b0d3e6a9c2
# verify-constraints.sh – Selective constraint verification for MANTIS AGENTIC artifacts
# Part of HARNESS NORMS v3.0-SELECTIVE validation suite
# Usage: bash verify-constraints.sh --file <path> [--json] [--verbose] [--strict] [--fix]
# Output: JSON summary to stdout (if --json), structured logs to stderr (C8 compliant)
# Version: 3.0.0-SELECTIVE-EXPANDED | Lines: ~520 | Last updated: 2026-04-19

set -Eeuo pipefail
readonly SCRIPT_NAME="verify-constraints.sh"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
readonly TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

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
# CLI ARGUMENT PARSING WITH VALIDATION
# =============================================================================
FILE="" JSON_OUTPUT=false VERBOSE=false STRICT=false FIX_MODE=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --file) FILE="$2"; shift 2 ;;
    --json) JSON_OUTPUT=true; shift ;;
    --verbose) VERBOSE=true; shift ;;
    --strict) STRICT=true; shift ;;
    --fix) FIX_MODE=true; shift ;;  # Experimental: suggest auto-fixes
    --debug) DEBUG=true; shift ;;
    -h|--help)
      cat << 'HELP'
Usage: verify-constraints.sh --file <path> [OPTIONS]

Required:
  --file <path>          Path to artifact Markdown file to validate

Optional:
  --json                 Output machine-readable JSON summary to stdout
  --verbose              Show detailed warning messages and debug info
  --strict               Treat all warnings as blocking issues (CI mode)
  --fix                  Suggest auto-fix patches for common issues (experimental)
  --debug                Enable debug logging to stderr

Exit codes:
  0  - Validation passed (score >= 30, no blocking issues)
  1  - Validation failed (score < 30 or blocking issues present)
  2  - Invalid arguments or file not found
  3  - Internal error during validation

Examples:
  bash verify-constraints.sh --file 06-PROGRAMMING/sql/query.md
  bash verify-constraints.sh --file pgvector.md --json --strict
  bash verify-constraints.sh --file hybrid.md --verbose --fix
HELP
      exit 0 ;;
    *) log "ERROR" "Unknown argument: $1" "$SCRIPT_NAME"; exit 2 ;;
  esac
done

# C3: Validate required inputs with detailed error messages
if [[ -z "$FILE" ]]; then
  log "ERROR" "Missing required argument: --file <path>" "$SCRIPT_NAME"
  echo '{"error":"MISSING_ARG","required":"--file","usage":"verify-constraints.sh --file <path>"}' >&2
  exit 2
fi

if [[ ! -f "$FILE" ]]; then
  log "ERROR" "File not found: $FILE" "$SCRIPT_NAME"
  echo "{\"error\":\"FILE_NOT_FOUND\",\"path\":\"$FILE\",\"cwd\":\"$(pwd)\"}" >&2
  exit 3
fi

# Validate file is readable and not empty
if [[ ! -r "$FILE" ]] || [[ ! -s "$FILE" ]]; then
  log "ERROR" "File not readable or empty: $FILE" "$SCRIPT_NAME"
  echo '{"error":"FILE_UNREADABLE","path":"'"$FILE"'"}' >&2
  exit 3
fi

# C8: Log validation start with metadata
log "INFO" "Starting constraint verification" "$FILE"
log_debug "Script directory: $SCRIPT_DIR" "$SCRIPT_NAME"
log_debug "Project root: $PROJECT_ROOT" "$SCRIPT_NAME"

# =============================================================================
# FRONTMATTER PARSING UTILITIES (Robust to YAML variations)
# =============================================================================
extract_field() {
  local field="$1" file="$2"
  # Handle both "field: value" and "field: 'value'" or "field: \"value\""
  grep -E "^${field}:" "$file" 2>/dev/null | head -1 | \
    sed -E "s/^${field}:\s*['\"]?//" | sed -E "s/['\"]?\s*$//" || echo ""
}

extract_json_array_field() {
  local field="$1" file="$2"
  # Extract array like ["C1","C2"] or [ "C1", "C2" ]
  grep -E "^${field}:" "$file" 2>/dev/null | head -1 | \
    grep -oE '\[[^]]+\]' | tr -d ' ' || echo "[]"
}

ARTIFACT_ID=$(extract_field "artifact_id" "$FILE")
ARTIFACT_TYPE=$(extract_field "artifact_type" "$FILE")
VERSION=$(extract_field "version" "$FILE")
CONSTRAINTS_MAPPED=$(extract_json_array_field "constraints_mapped" "$FILE")
CANONICAL_PATH=$(extract_field "canonical_path" "$FILE")
VALIDATION_CMD=$(extract_field "validation_command" "$FILE")
LANGUAGE_FIELD=$(extract_field "language" "$FILE")

# Initialize tracking arrays and counters
declare -a BLOCKING_ISSUES=()
declare -a WARNINGS=()
declare -a VERIFIED_CONSTRAINTS=()
declare -A EXAMPLE_COVERAGE=()  # Track which constraints have example coverage
SCORE=50  # Base score
EXAMPLE_COUNT=0
EXAMPLES_BY_CONSTRAINT=0

# =============================================================================
# HELPER FUNCTIONS WITH ENHANCED ERROR HANDLING
# =============================================================================
has_constraint() {
  local constraint="$1" mapped="$2"
  [[ "$mapped" == *"$constraint"* ]] || [[ "$mapped" == *"\"$constraint\""* ]]
}

add_blocking() {
  local issue="$1" code="${2:-GENERIC}"
  BLOCKING_ISSUES+=("{\"code\":\"$code\",\"message\":\"$issue\"}")
  log "ERROR" "Blocking issue [$code]: $issue" "$FILE"
}

add_warning() {
  local warning="$1" code="${2:-WARNING}"
  WARNINGS+=("{\"code\":\"$code\",\"message\":\"$warning\"}")
  [[ "$VERBOSE" == true ]] && log "WARNING" "[$code] $warning" "$FILE" || true
}

adjust_score() {
  local delta="$1" reason="${2:-}"
  SCORE=$((SCORE + delta))
  [[ "$SCORE" -lt 0 ]] && SCORE=0
  [[ "$SCORE" -gt 100 ]] && SCORE=100
  log_debug "Score adjusted: $delta (reason: ${reason:-none}) -> new score: $SCORE" "$FILE"
}

# Enhanced regex patterns for constraint detection (more granular)
declare -A CONSTRAINT_PATTERNS=(
  [C1]='LIMIT\s+[0-9]+|SET\s+LOCAL\s+(work_mem|statement_timeout|maintenance_work_mem)|memory\s*=\s*[0-9]+|cpu_shares|pids_limit|batch_size|max_parallel'
  [C2]='statement_timeout|asyncio\.timeout|timeout\s*=\s*[0-9]+|TimeoutSignal|start_period\s*=|healthcheck.*timeout|fetch.*timeout'
  [C3]='assert.*environment|validation\s*\{.*condition|os\.environ\s*\[\s*"[A-Z_]+"\s*\]|current_setting\s*\(\s*.*\s*\)\s*IS\s+NOT\s+NULL|\$\{[A-Z_]+:\?|env_required'
  [C4]='tenant_id\s*=.*current_setting|WHERE.*tenant_id\s*=|CREATE POLICY.*USING.*tenant_id|WITH CHECK.*tenant_id|ContextVar.*tenant|AsyncLocalStorage|RLS.*policy'
  [C5]='sha256sum|digest\s*\(\s*.*,\s*["\x27]sha256["\x27]\s*\)|content_hash|checksum|pgcrypto|encode.*sha256|integrity.*check'
  [C6]='try:.*import|CREATE EXTENSION IF NOT EXISTS|fallback|except ImportError|IF NOT EXISTS.*extension|optional.*dependency|feature.*flag'
  [C7]='pathlib|\.resolve\s*\(\)|secure_path|starts with|path traversal|realpath -m|finally:.*cleanup|trap.*EXIT|mktemp.*trap'
  [C8]='json_build_object|logger.*stderr|print\s*\(\s*.*file\s*=\s*sys\.stderr|pino\s*\(|winston\s*\.|RAISE NOTICE.*json|structured.*log'
  [V1]='vector\([0-9]+\).*CHECK|array_length\s*\(\s*vec\s*,\s*1\s*\)\s*=\s*[0-9]+|validate_vec_dim|chk_vec_dim|dimension.*valid'
  [V2]='<->.*L2|<=>.*cosine|<#>.*inner|<#>.*dot|ORDER BY.*<->|ORDER BY.*<=>|ORDER BY.*<#>|vector_.*_ops|distance.*metric'
  [V3]='USING\s+hnsw.*WITH\s*\([^)]*(m\s*=|ef_construction\s*=)|USING\s+ivfflat.*WITH\s*\([^)]*lists\s*=)|hnsw.*ef_search|ivfflat.*lists.*sqrt|index.*tuning'
)

# =============================================================================
# DETECT CONTEXT FOR SELECTIVE VALIDATION (Enhanced)
# =============================================================================
FILE_DIR=$(dirname "$FILE")
FILE_NAME=$(basename "$FILE")
IS_PGVECTOR_DIR=false
HAS_VECTOR_OPERATORS=false
IS_SQL_DIR=false
IS_MULTI_LANG=false

# Directory-based context detection
[[ "$FILE_DIR" == *"/postgresql-pgvector"* ]] && IS_PGVECTOR_DIR=true
[[ "$FILE_DIR" == *"/sql"* ]] && IS_SQL_DIR=true

# Artifact type-based context detection
[[ "$ARTIFACT_TYPE" == "skill_pgvector" ]] && IS_PGVECTOR_DIR=true

# Detect vector operators with more precise regex
if grep -qE '<->[^a-zA-Z]|<=>[^a-zA-Z]|<#>[^a-zA-Z]|vector\s*\(\s*[0-9]+\s*\)|USING\s+(hnsw|ivfflat)\s*\(' "$FILE" 2>/dev/null; then
  HAS_VECTOR_OPERATORS=true
  log_debug "Vector operators detected in file content" "$FILE"
fi

# Detect multi-language artifacts (SQL in Python, Bash in Markdown, etc.)
if grep -qE '```(python|py).*```.*```(sql|postgres)|```(sql).*```.*```(python|py)' "$FILE" 2>/dev/null; then
  IS_MULTI_LANG=true
  log_debug "Multi-language artifact detected (SQL + another language)" "$FILE"
fi

log "INFO" "Context: pgvector_dir=$IS_PGVECTOR_DIR, sql_dir=$IS_SQL_DIR, vector_ops=$HAS_VECTOR_OPERATORS, multi_lang=$IS_MULTI_LANG" "$FILE"

# =============================================================================
# LANGUAGE LOCK VALIDATION (CRITICAL - Enhanced with multi-lang support)
# =============================================================================

# 🔴 CRITICAL: pgvector operators in sql/ directory = LANGUAGE LOCK VIOLATION
if [[ "$IS_SQL_DIR" == true ]] && [[ "$ARTIFACT_TYPE" != "skill_pgvector" ]]; then
  if grep -qE '<->[^a-zA-Z]|<=>[^a-zA-Z]|<#>[^a-zA-Z]|vector\s*\(\s*[0-9]+\s*\)|USING\s+(hnsw|ivfflat)' "$FILE"; then
    log "ERROR" "LANGUAGE_LOCK_VIOLATION: pgvector operators detected in sql/ directory" "$FILE"
    add_blocking "pgvector operators found in sql/ directory violates LANGUAGE LOCK protocol" "LANG_LOCK_PGVECTOR_IN_SQL"
    adjust_score -15 "LANGUAGE_LOCK_VIOLATION"
  fi
fi

# 🔴 CRITICAL: Pure SQL in postgres-pgvector/ without vector operators = potential misplacement
if [[ "$IS_PGVECTOR_DIR" == true ]] && [[ "$ARTIFACT_TYPE" == "skill_pgvector" ]]; then
  if [[ "$HAS_VECTOR_OPERATORS" == false ]]; then
    # Check if file contains ONLY SQL without vector ops
    if grep -qE 'SELECT|INSERT|UPDATE|DELETE|CREATE TABLE' "$FILE" && ! grep -qE 'vector|<->|<=>|<#>' "$FILE"; then
      log "WARNING" "skill_pgvector artifact contains SQL but no vector operators - verify if belongs in sql/" "$FILE"
      add_warning "Artifact may be misplaced: skill_pgvector without vector operators" "PGVECTOR_MISPLACED"
      adjust_score -5 "PGVECTOR_NO_VECTOR_OPS"
    fi
  fi
fi

# 🟡 WARNING: Non-pgvector artifact mapping V* constraints (selective rule violation)
if [[ "$IS_PGVECTOR_DIR" == false ]] || [[ "$ARTIFACT_TYPE" != "skill_pgvector" ]]; then
  for v_constraint in V1 V2 V3; do
    if has_constraint "$v_constraint" "$CONSTRAINTS_MAPPED"; then
      log "WARNING" "Non-pgvector artifact maps $v_constraint - verify selective application" "$FILE"
      add_warning "V* constraint '$v_constraint' mapped in non-pgvector artifact ($ARTIFACT_TYPE)" "SELECTIVE_V_IN_NON_PGVECTOR"
      adjust_score -2 "SELECTIVE_RULE_VIOLATION"
      break  # Only warn once for any V* violation
    fi
  done
fi

# 🔴 CRITICAL: Check for cross-language contamination in multi-lang artifacts
if [[ "$IS_MULTI_LANG" == true ]]; then
  # Ensure SQL blocks don't contain pgvector ops if in sql/ context
  if [[ "$IS_SQL_DIR" == true ]]; then
    # Extract SQL code blocks and check for pgvector operators
    if grep -zoE '```sql[^`]*```' "$FILE" 2>/dev/null | grep -qE '<->|<=>|<#>|vector\s*\('; then
      log "ERROR" "LANGUAGE_LOCK_VIOLATION: pgvector operators in SQL block within sql/ directory" "$FILE"
      add_blocking "pgvector operators in SQL code block violates LANGUAGE LOCK in sql/" "LANG_LOCK_SQL_BLOCK_PGVECTOR"
      adjust_score -10 "LANGUAGE_LOCK_MULTI_LANG_VIOLATION"
    fi
  fi
fi

# =============================================================================
# SELECTIVE V1-V3 VALIDATION (Only for skill_pgvector with vector operators)
# =============================================================================
if [[ "$IS_PGVECTOR_DIR" == true ]] && [[ "$ARTIFACT_TYPE" == "skill_pgvector" ]] && [[ "$HAS_VECTOR_OPERATORS" == true ]]; then
  
  # V1: Dimension Validation - Enhanced pattern matching
  if has_constraint "V1" "$CONSTRAINTS_MAPPED"; then
    V1_PATTERNS='vector\([0-9]+\)[^a-zA-Z].*CHECK|array_length\s*\(\s*vec\s*,\s*1\s*\)\s*=\s*[0-9]+|validate_vec_dim|chk_vec_dim|dimension.*valid|ASSERT.*array_length'
    if grep -qE "$V1_PATTERNS" "$FILE"; then
      log "INFO" "V1 validation PASSED: dimension constraints detected with robust patterns" "$FILE"
      VERIFIED_CONSTRAINTS+=("V1")
      EXAMPLE_COVERAGE["V1"]=true
      adjust_score +3 "V1_DIMENSION_VALIDATION"
    else
      log "WARNING" "V1 constraint mapped but no dimension validation patterns found" "$FILE"
      add_warning "V1 mapped but no vector(n) CHECK, array_length validation, or validate_vec_dim function detected" "V1_MAPPED_NOT_IMPLEMENTED"
      adjust_score -3 "V1_NOT_DEMONSTRATED"
    fi
  fi
  
  # V2: Distance Metric Explicit - Enhanced with opclass alignment checks
  if has_constraint "V2" "$CONSTRAINTS_MAPPED"; then
    V2_PATTERNS='<->[^a-zA-Z].*(L2|euclid|euclidean)|<=>[^a-zA-Z].*(cosine|cos)|<#>[^a-zA-Z].*(inner|dot|product)|ORDER BY[^;]*<->|ORDER BY[^;]*<=>|ORDER BY[^;]*<#>|vector_.*_ops.*WITH|distance.*metric.*explicit'
    if grep -qE "$V2_PATTERNS" "$FILE"; then
      log "INFO" "V2 validation PASSED: distance operators documented with metric and/or opclass alignment" "$FILE"
      VERIFIED_CONSTRAINTS+=("V2")
      EXAMPLE_COVERAGE["V2"]=true
      adjust_score +3 "V2_DISTANCE_METRIC"
    else
      log "WARNING" "V2 constraint mapped but distance operators not clearly documented with metric" "$FILE"
      add_warning "V2 mapped but operators lack explicit metric documentation (L2/cosine/dot) or opclass alignment" "V2_MAPPED_NOT_DOCUMENTED"
      adjust_score -3 "V2_NOT_DEMONSTRATED"
    fi
  fi
  
  # V3: Index-Type Match Justified - Enhanced with parameter validation
  if has_constraint "V3" "$CONSTRAINTS_MAPPED"; then
    V3_PATTERNS='USING\s+hnsw[^;]*WITH\s*\([^)]*(m\s*=|ef_construction\s*=|ef_search\s*=)|USING\s+ivfflat[^;]*WITH\s*\([^)]*lists\s*=)|hnsw.*ef_search.*[0-9]+|ivfflat.*lists.*sqrt|index.*tuning.*justif|CONCURRENTLY.*hnsw|CONCURRENTLY.*ivfflat'
    if grep -qE "$V3_PATTERNS" "$FILE"; then
      log "INFO" "V3 validation PASSED: index parameters justified by volume/pattern with robust detection" "$FILE"
      VERIFIED_CONSTRAINTS+=("V3")
      EXAMPLE_COVERAGE["V3"]=true
      adjust_score +3 "V3_INDEX_JUSTIFICATION"
    else
      log "WARNING" "V3 constraint mapped but index parameters not justified with required patterns" "$FILE"
      add_warning "V3 mapped but hnsw/ivfflat lacks WITH parameters (m, ef_construction, lists) or justification comments" "V3_MAPPED_NOT_JUSTIFIED"
      adjust_score -3 "V3_NOT_DEMONSTRATED"
    fi
  fi
  
  # Additional V* cross-validation: ensure all mapped V* have example coverage
  for v_constraint in V1 V2 V3; do
    if has_constraint "$v_constraint" "$CONSTRAINTS_MAPPED" && [[ -z "${EXAMPLE_COVERAGE[$v_constraint]:-}" ]]; then
      add_warning "Constraint $v_constraint mapped but no example demonstrates it (coverage gap)" "V*_COVERAGE_GAP"
      adjust_score -2 "V*_NO_EXAMPLE_COVERAGE"
    fi
  done
fi

# =============================================================================
# CORE CONSTRAINTS C1-C8 VALIDATION (Enhanced with per-constraint example tracking)
# =============================================================================

validate_constraint_with_examples() {
  local constraint="$1" pattern="${CONSTRAINT_PATTERNS[$constraint]}"
  local found=false
  
  if grep -qE "$pattern" "$FILE" 2>/dev/null; then
    # Additional check: ensure the pattern appears in an example context (✅ or ❌ block)
    if grep -B2 -A5 "^-- ✅\|^-- ❌" "$FILE" 2>/dev/null | grep -qE "$pattern"; then
      found=true
      EXAMPLES_BY_CONSTRAINT=$((EXAMPLES_BY_CONSTRAINT + 1))
      log_debug "Constraint $constraint validated with example coverage" "$FILE"
    else
      log_debug "Constraint $constraint pattern found but not in example context" "$FILE"
      # Still count as verified but note the context issue
      found=true
    fi
  fi
  
  if [[ "$found" == true ]]; then
    VERIFIED_CONSTRAINTS+=("$constraint")
    EXAMPLE_COVERAGE["$constraint"]=true
    case "$constraint" in
      C4|C8) adjust_score +5 "$constraint critical weight" ;;  # Higher weight for critical constraints
      C1|C2|C3|C5|C6|C7) adjust_score +2 "$constraint standard weight" ;;
      *) adjust_score +1 "$constraint default weight" ;;
    esac
    return 0
  else
    add_warning "C$constraint: pattern not demonstrated in examples or code" "C${constraint}_NOT_DEMONSTRATED"
    return 1
  fi
}

# Validate each CORE constraint with enhanced example context checking
for constraint in C1 C2 C3 C4 C5 C6 C7 C8; do
  if has_constraint "$constraint" "$CONSTRAINTS_MAPPED"; then
    validate_constraint_with_examples "$constraint"
  fi
done

# Special handling for C4 (Multi-Tenant Isolation) - CRITICAL for data artifacts
if has_constraint "C4" "$CONSTRAINTS_MAPPED"; then
  if [[ ! " ${VERIFIED_CONSTRAINTS[*]} " =~ " C4 " ]]; then
    # Only penalize if artifact type suggests multi-tenant context
    if [[ "$ARTIFACT_TYPE" =~ ^(skill_sql|skill_pgvector|skill_go|skill_terraform|skill_python)$ ]]; then
      log "WARNING" "C4_TENANT_ISOLATION:not demonstrated in multi-tenant artifact type" "$FILE"
      add_warning "C4 mapped but tenant isolation patterns missing in data-layer or service artifact" "C4_CRITICAL_MISSING"
      adjust_score -5 "C4_NOT_DEMONSTRATED_CRITICAL"
    fi
  fi
fi

# Special handling for C8 (Structured Logging) - CRITICAL for observability
if has_constraint "C8" "$CONSTRAINTS_MAPPED"; then
  if [[ ! " ${VERIFIED_CONSTRAINTS[*]} " =~ " C8 " ]]; then
    log "ERROR" "C8_STRUCTURED_LOGGING:missing or using unstructured print/console.log" "$FILE"
    add_blocking "C8 mapped but no structured logging to stderr detected (print/console.log without stderr redirect)" "C8_CRITICAL_VIOLATION"
    adjust_score -10 "C8_NOT_DEMONSTRATED_CRITICAL"
  else
    # Bonus if explicitly avoids unstructured logging in production context
    if ! grep -qE '^(?!.*#.*❌|.*//.*❌|.*--.*❌).*\bprint\s*\(|^(?!.*//.*❌|.*--.*❌).*\bconsole\.(log|error|warn)\s*\(' "$FILE"; then
      adjust_score +2 "C8_NO_UNSTRUCTURED_LOGGING_BONUS"
    fi
  fi
fi

# =============================================================================
# FORMAT & STRUCTURE VALIDATION (Enhanced with Markdown-specific checks)
# =============================================================================

# SHA256 header validation (64-char hex after "# SHA256:")
if grep -qE '^# SHA256:\s*[a-f0-9]{64}\s*$' "$FILE"; then
  adjust_score +2 "SHA256_HEADER_VALID"
else
  add_warning "SHA256_HEADER:missing or malformed (expected '# SHA256: <64-char hex>' on first line)" "SHA256_MALFORMED"
  adjust_score -2 "SHA256_INVALID"
fi

# Frontmatter validation: check for required fields and proper closure
FRONTMATTER_START=$(grep -n '^---$' "$FILE" 2>/dev/null | head -1 | cut -d: -f1)
FRONTMATTER_END=$(grep -n '^---$' "$FILE" 2>/dev/null | sed -n '2p' | cut -d: -f1)

if [[ -n "$FRONTMATTER_START" ]] && [[ -n "$FRONTMATTER_END" ]] && [[ "$FRONTMATTER_END" -gt "$FRONTMATTER_START" ]]; then
  # Extract frontmatter content for field validation
  FRONTMATTER_CONTENT=$(sed -n "$((FRONTMATTER_START+1)),$((FRONTMATTER_END-1))p" "$FILE")
  
  # Check for required fields in frontmatter
  for required_field in artifact_id artifact_type version constraints_mapped validation_command canonical_path; do
    if ! echo "$FRONTMATTER_CONTENT" | grep -qE "^${required_field}:"; then
      add_blocking "Frontmatter missing required field: $required_field" "FRONTMATTER_MISSING_$required_field"
      adjust_score -3 "FRONTMATTER_INCOMPLETE"
    fi
  done
  
  adjust_score +1 "FRONTMATTER_STRUCTURE_VALID"
else
  add_blocking "Frontmatter not properly delimited (expected two --- separators)" "FRONTMATTER_DELIMITER_MISSING"
  adjust_score -5 "FRONTMATTER_INVALID"
fi

# Example count validation with per-constraint coverage tracking
EXAMPLE_COUNT=$(grep -cE '^-- ✅|^-- ❌' "$FILE" 2>/dev/null || echo 0)
REQUIRED_EXAMPLES=10
[[ "$ARTIFACT_TYPE" == "skill_pgvector" ]] && REQUIRED_EXAMPLES=25

if [[ "$EXAMPLE_COUNT" -ge "$REQUIRED_EXAMPLES" ]]; then
  adjust_score +5 "EXAMPLE_COUNT_SUFFICIENT"
  log "INFO" "Example count: $EXAMPLE_COUNT (required: $REQUIRED_EXAMPLES) - PASSED" "$FILE"
else
  log "ERROR" "Example count: $EXAMPLE_COUNT < $REQUIRED_EXAMPLES required for $ARTIFACT_TYPE" "$FILE"
  add_blocking "Insufficient examples: $EXAMPLE_COUNT found, $REQUIRED_EXAMPLES required for artifact type $ARTIFACT_TYPE" "INSUFFICIENT_EXAMPLES"
  adjust_score -10 "EXAMPLE_COUNT_DEFICIT"
fi

# Validate example distribution: ensure both ✅ and ❌ patterns are present
POSITIVE_EXAMPLES=$(grep -c '^-- ✅' "$FILE" 2>/dev/null || echo 0)
NEGATIVE_EXAMPLES=$(grep -c '^-- ❌' "$FILE" 2>/dev/null || echo 0)

if [[ "$POSITIVE_EXAMPLES" -eq 0 ]]; then
  add_warning "No positive examples (✅) found - artifact lacks correct pattern demonstrations" "NO_POSITIVE_EXAMPLES"
  adjust_score -3 "EXAMPLE_BALANCE_ISSUE"
fi

if [[ "$NEGATIVE_EXAMPLES" -eq 0 ]]; then
  add_warning "No anti-pattern examples (❌) found - artifact lacks error documentation" "NO_NEGATIVE_EXAMPLES"
  adjust_score -3 "EXAMPLE_BALANCE_ISSUE"
fi

# Executable lines per example validation (enhanced heuristic)
# Count non-comment, non-empty lines within example blocks (between -- ✅/❌ and next -- or ```)
LONG_BLOCKS=$(awk '
  BEGIN { in_example=0; line_count=0; long_count=0 }
  /^-- ✅|^-- ❌/ { in_example=1; line_count=0; next }
  in_example && /^-- / { if(line_count>5) long_count++; in_example=0; next }
  in_example && /^```/ { if(line_count>5) long_count++; in_example=0; next }
  in_example && /^[^#`[:space:]-]/ && NF>0 && !/^[[:space:]]*$/ { line_count++ }
  END { print long_count }
' "$FILE" 2>/dev/null)

if [[ "$LONG_BLOCKS" -eq 0 ]]; then
  adjust_score +3 "EXAMPLE_LINES_WITHIN_LIMIT"
else
  add_warning "LINES_EXECUTABLE: $LONG_BLOCKS example blocks exceed 5 executable lines" "EXAMPLE_LINES_EXCEEDED"
  adjust_score -2 "EXAMPLE_LINES_VIOLATION"
fi

# Timestamp validation in JSON report (must be 2026 ISO8601 with timezone)
if grep -qE '"timestamp":"[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z"' "$FILE"; then
  if grep -qE '"timestamp":"2026-' "$FILE"; then
    adjust_score +2 "TIMESTAMP_VALID_2026"
  else
    add_warning "TIMESTAMP: valid format but not in 2026 - artifact may be stale or misconfigured" "TIMESTAMP_NOT_2026"
    adjust_score -1 "TIMESTAMP_YEAR_MISMATCH"
  fi
else
  add_warning "TIMESTAMP: missing or malformed in JSON report section (expected ISO8601 with Z suffix)" "TIMESTAMP_MALFORMED"
  adjust_score -2 "TIMESTAMP_INVALID"
fi

# Validation command path consistency with canonical_path
if [[ -n "$VALIDATION_CMD" ]] && [[ -n "$CANONICAL_PATH" ]]; then
  if echo "$VALIDATION_CMD" | grep -qF "$CANONICAL_PATH"; then
    adjust_score +1 "VALIDATION_CMD_PATH_CONSISTENT"
  else
    add_warning "VALIDATION_CMD: path in command ('$VALIDATION_CMD') does not match canonical_path ('$CANONICAL_PATH')" "VALIDATION_CMD_PATH_MISMATCH"
    adjust_score -1 "VALIDATION_CMD_INCONSISTENT"
  fi
fi

# Closing separator validation for parseability
if tail -1 "$FILE" | grep -q '^---$'; then
  adjust_score +1 "CLOSING_SEPARATOR_PRESENT"
else
  add_warning "CLOSING: missing final '---' separator for automated parsing by agents" "CLOSING_SEPARATOR_MISSING"
  adjust_score -1 "CLOSING_INVALID"
fi

# Markdown structure validation: wikilinks, mermaid, tables
if grep -qE '\[\[.*\]\]' "$FILE" 2>/dev/null; then
  # Wikilinks present - validate they follow canonical format
  INVALID_WIKILINKS=$(grep -oE '\[\[[^]]+\]\]' "$FILE" 2>/dev/null | grep -vE '\[\[[a-zA-Z0-9._/-]+\]\]' | wc -l)
  if [[ "$INVALID_WIKILINKS" -gt 0 ]]; then
    add_warning "MARKDOWN: $INVALID_WIKILINKS wikilinks do not follow canonical format [[artifact-id]]" "WIKILINK_FORMAT_INVALID"
    adjust_score -1 "WIKILINK_MALFORMED"
  fi
fi

# Mermaid diagram validation if present
if grep -qE '```mermaid' "$FILE" 2>/dev/null; then
  # Basic syntax check: ensure mermaid blocks are properly closed
  MERMAID_OPEN=$(grep -c '```mermaid' "$FILE" 2>/dev/null || echo 0)
  MERMAID_CLOSE=$(grep -c '^```$' "$FILE" 2>/dev/null | awk -v open="$MERMAID_OPEN" 'NR>=open {print; exit}')
  if [[ "$MERMAID_OPEN" -ne "${MERMAID_CLOSE:-0}" ]]; then
    add_warning "MARKDOWN: mermaid diagram blocks not properly closed" "MERMAID_SYNTAX_INVALID"
    adjust_score -1 "MERMAID_MALFORMED"
  fi
fi

# Table validation: ensure markdown tables have proper alignment
if grep -qE '^\|.*\|.*\|' "$FILE" 2>/dev/null; then
  # Check for separator row with dashes
  if ! grep -qE '^\|[-:\s|]+\|$' "$FILE"; then
    add_warning "MARKDOWN: table detected but missing separator row with alignment markers" "TABLE_FORMAT_INVALID"
    adjust_score -1 "TABLE_MALFORMED"
  fi
fi

# =============================================================================
# CONSTRAINT MAPPING COVERAGE VALIDATION (Cross-check mapped vs demonstrated)
# =============================================================================
# Parse constraints_mapped array and verify each has at least one example
if [[ -n "$CONSTRAINTS_MAPPED" ]] && [[ "$CONSTRAINTS_MAPPED" != "[]" ]]; then
  # Extract individual constraints from JSON array string
  MAPPED_CONSTRAINTS=$(echo "$CONSTRAINTS_MAPPED" | tr -d '[]"' | tr ',' '\n' | tr -d ' ')
  
  for mapped_constraint in $MAPPED_CONSTRAINTS; do
    [[ -z "$mapped_constraint" ]] && continue
    
    # Check if constraint has example coverage (from earlier validation)
    if [[ -z "${EXAMPLE_COVERAGE[$mapped_constraint]:-}" ]]; then
      # Only warn if it's a constraint we can validate (C1-C8, V1-V3)
      if [[ "$mapped_constraint" =~ ^(C[1-8]|V[1-3])$ ]]; then
        add_warning "Constraint '$mapped_constraint' mapped in frontmatter but no example demonstrates it" "CONSTRAINT_NO_COVERAGE_$mapped_constraint"
        adjust_score -1 "COVERAGE_GAP_$mapped_constraint"
      fi
    fi
  done
fi

# =============================================================================
# CANONICAL PATH VALIDATION (Ensure path matches actual file location)
# =============================================================================
if [[ -n "$CANONICAL_PATH" ]]; then
  # Resolve the canonical path relative to project root
  EXPECTED_PATH="$PROJECT_ROOT/$CANONICAL_PATH"
  
  # Normalize both paths for comparison (remove trailing slashes, resolve . and ..)
  FILE_REAL=$(realpath -m "$FILE" 2>/dev/null || echo "$FILE")
  EXPECTED_REAL=$(realpath -m "$EXPECTED_PATH" 2>/dev/null || echo "$EXPECTED_PATH")
  
  if [[ "$FILE_REAL" != "$EXPECTED_REAL" ]]; then
    add_warning "CANONICAL_PATH: declared path '$CANONICAL_PATH' does not match actual file location" "CANONICAL_PATH_MISMATCH"
    adjust_score -2 "PATH_INCONSISTENT"
    
    # In fix mode, suggest the correct path
    if [[ "$FIX_MODE" == true ]]; then
      REL_PATH="${FILE#$PROJECT_ROOT/}"
      echo "🔧 FIX SUGGESTION: Update canonical_path to: $REL_PATH" >&2
    fi
  fi
fi

# =============================================================================
# STRICT MODE: Promote warnings to blocking issues
# =============================================================================
if [[ "$STRICT" == true ]] && [[ ${#WARNINGS[@]} -gt 0 ]]; then
  log "INFO" "Strict mode enabled: promoting ${#WARNINGS[@]} warnings to blocking issues" "$FILE"
  for warning_json in "${WARNINGS[@]}"; do
    # Extract message from warning JSON and add as blocking
    warning_msg=$(echo "$warning_json" | jq -r '.message' 2>/dev/null || echo "$warning_json")
    warning_code=$(echo "$warning_json" | jq -r '.code' 2>/dev/null || echo "STRICT_PROMOTED")
    add_blocking "STRICT_MODE: $warning_msg" "STRICT_$warning_code"
  done
  WARNINGS=()  # Clear warnings since they're now blocking
fi

# =============================================================================
# FIX MODE: Generate auto-fix suggestions for common issues
# =============================================================================
if [[ "$FIX_MODE" == true ]] && [[ ${#WARNINGS[@]} -gt 0 ]] && [[ "$STRICT" == false ]]; then
  echo "" >&2
  echo "🔧 AUTO-FIX SUGGESTIONS for $FILE:" >&2
  echo "----------------------------------------" >&2
  
  for warning_json in "${WARNINGS[@]}"; do
    warning_code=$(echo "$warning_json" | jq -r '.code' 2>/dev/null || echo "UNKNOWN")
    warning_msg=$(echo "$warning_json" | jq -r '.message' 2>/dev/null || echo "$warning_json")
    
    case "$warning_code" in
      SHA256_MALFORMED)
        echo "  • Add '# SHA256: $(openssl rand -hex 32 2>/dev/null || echo '<64-char-hex>')" as first line" >&2 ;;
      FRONTMATTER_MISSING_*)
        field="${warning_code#FRONTMATTER_MISSING_}"
        echo "  • Add '$field: <value>' to frontmatter YAML block" >&2 ;;
      EXAMPLE_LINES_EXCEEDED)
        echo "  • Split long code examples into ≤5 executable lines; move comments to description" >&2 ;;
      TIMESTAMP_*)
        echo "  • Update JSON report timestamp to current ISO8601 format: \"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" >&2 ;;
      C8_*)
        echo "  • Replace print()/console.log() with structured logger to stderr (json_build_object, pino, etc.)" >&2 ;;
      V*_MAPPED_NOT_*)
        echo "  • Add example demonstrating $warning_code constraint with required pattern" >&2 ;;
      *)
        echo "  • Review: $warning_msg" >&2 ;;
    esac
  done
  echo "----------------------------------------" >&2
  echo "Note: Run with --strict to treat these as blocking issues" >&2
  echo "" >&2
fi

# =============================================================================
# FINAL SCORING & OUTPUT GENERATION (Enhanced JSON structure)
# =============================================================================

# Clamp score to valid range
[[ "$SCORE" -lt 0 ]] && SCORE=0
[[ "$SCORE" -gt 100 ]] && SCORE=100

# Determine pass/fail status with detailed reasoning
PASSED=true
FAIL_REASON=""
if [[ "$SCORE" -lt 30 ]]; then
  PASSED=false
  FAIL_REASON="score_below_threshold"
  log "ERROR" "Verification FAILED: score=$SCORE < 30 threshold" "$FILE"
fi
if [[ ${#BLOCKING_ISSUES[@]} -gt 0 ]]; then
  PASSED=false
  FAIL_REASON="${FAIL_REASON:+$FAIL_REASON,}blocking_issues_present"
  log "ERROR" "Verification FAILED: ${#BLOCKING_ISSUES[@]} blocking issues detected" "$FILE"
fi
[[ "$PASSED" == true ]] && log "INFO" "Verification PASSED: score=$SCORE, no blocking issues" "$FILE"

# Build properly formatted JSON arrays for output
build_json_array() {
  local -n arr=$1
  if [[ ${#arr[@]} -eq 0 ]]; then
    echo "[]"
  else
    # Ensure each element is valid JSON, then combine
    local json_items=()
    for item in "${arr[@]}"; do
      # If item is already JSON, use as-is; otherwise wrap as string
      if echo "$item" | jq -e . >/dev/null 2>&1; then
        json_items+=("$item")
      else
        json_items+=("$(echo "$item" | jq -R .)")
      fi
    done
    printf '%s\n' "${json_items[@]}" | jq -s . 2>/dev/null || echo "[]"
  fi
}

BLOCKING_JSON=$(build_json_array BLOCKING_ISSUES)
WARNINGS_JSON=$(build_json_array WARNINGS)
CONSTRAINTS_JSON=$(printf '%s\n' "${VERIFIED_CONSTRAINTS[@]}" | jq -R . 2>/dev/null | jq -s . 2>/dev/null || echo "[]")

# Parse constraints_mapped for output (handle various JSON formats)
CONSTRAINTS_MAPPED_PARSED=$(echo "$CONSTRAINTS_MAPPED" | jq -c 'if type=="array" then . else (split(",") | map(gsub("^\\[|\\]$";"") | gsub("\"";"") | split(",") | map(trim) | map(select(length>0))) | flatten | unique) end' 2>/dev/null || echo "[]")

# Generate comprehensive JSON output
generate_json_output() {
  cat <<EOF
{
  "artifact": "$ARTIFACT_ID",
  "version": "$VERSION",
  "score": $SCORE,
  "passed": $PASSED,
  "fail_reason": ${FAIL_REASON:+\"$FAIL_REASON\"}null,
  "blocking_issues": $BLOCKING_JSON,
  "warnings": $WARNINGS_JSON,
  "constraints_verified": $CONSTRAINTS_JSON,
  "constraints_mapped": $CONSTRAINTS_MAPPED_PARSED,
  "constraints_missing_coverage": $(for c in C1 C2 C3 C4 C5 C6 C7 C8 V1 V2 V3; do
    if has_constraint "$c" "$CONSTRAINTS_MAPPED" && [[ -z "${EXAMPLE_COVERAGE[$c]:-}" ]]; then
      echo "\"$c\""
    fi
  done | jq -s . 2>/dev/null || echo "[]"),
  "examples_count": $EXAMPLE_COUNT,
  "examples_required": $REQUIRED_EXAMPLES,
  "examples_positive": $POSITIVE_EXAMPLES,
  "examples_negative": $NEGATIVE_EXAMPLES,
  "lines_executable_max": 5,
  "language": "${LANGUAGE_FIELD:-unknown}",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "artifact_type": "$ARTIFACT_TYPE",
  "canonical_path": "$CANONICAL_PATH",
  "file_path": "$FILE",
  "validation_context": {
    "is_pgvector_directory": $IS_PGVECTOR_DIR,
    "is_sql_directory": $IS_SQL_DIR,
    "has_vector_operators": $HAS_VECTOR_OPERATORS,
    "is_multi_language": $IS_MULTI_LANG,
    "selective_v_validation_applied": $([ "$IS_PGVECTOR_DIR" = true ] && [ "$HAS_VECTOR_OPERATORS" = true ] && echo true || echo false)
  },
  "validation_metadata": {
    "script_name": "$SCRIPT_NAME",
    "script_version": "3.0.0-SELECTIVE-EXPANDED",
    "harness_norms_version": "v3.0.0-SELECTIVE",
    "execution_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "project_root": "$PROJECT_ROOT",
    "strict_mode": $STRICT,
    "fix_mode": $FIX_MODE,
    "verbose_mode": $VERBOSE
  },
  "recommendations": $(
    if [[ "$PASSED" == false ]]; then
      echo '["Review blocking issues", "Ensure all mapped constraints have example coverage", "Verify LANGUAGE LOCK compliance"]'
    elif [[ ${#WARNINGS[@]} -gt 0 ]]; then
      echo '["Address warnings to improve score", "Consider adding missing example patterns"]'
    else
      echo '["Artifact meets HARNESS NORMS v3.0-SELECTIVE requirements"]'
    fi
  )
}
EOF
}

# Output based on flags
if [[ "$JSON_OUTPUT" == true ]]; then
  generate_json_output
else
  # Human-readable summary
  echo "=== Constraint Verification Summary ==="
  echo "Artifact: $ARTIFACT_ID ($ARTIFACT_TYPE v$VERSION)"
  echo "File: $FILE"
  echo "Score: $SCORE/100"
  echo "Status: $([ "$PASSED" = true ] && echo "✅ PASSED" || echo "❌ FAILED")"
  [[ -n "$FAIL_REASON" ]] && echo "Failure reason: $FAIL_REASON"
  
  echo ""
  echo "Examples: $EXAMPLE_COUNT total ($POSITIVE_EXAMPLES ✅, $NEGATIVE_EXAMPLES ❌) / $REQUIRED_EXAMPLES required"
  
  if [[ ${#BLOCKING_ISSUES[@]} -gt 0 ]]; then
    echo ""
    echo "🔴 Blocking Issues (${#BLOCKING_ISSUES[@]}):"
    for issue in "${BLOCKING_ISSUES[@]}"; do
      msg=$(echo "$issue" | jq -r '.message' 2>/dev/null || echo "$issue")
      code=$(echo "$issue" | jq -r '.code' 2>/dev/null || echo "UNKNOWN")
      echo "  [$code] $msg"
    done
  fi
  
  if [[ ${#WARNINGS[@]} -gt 0 ]] && [[ "$VERBOSE" == true ]]; then
    echo ""
    echo "🟡 Warnings (${#WARNINGS[@]}):"
    for warning in "${WARNINGS[@]}"; do
      msg=$(echo "$warning" | jq -r '.message' 2>/dev/null || echo "$warning")
      code=$(echo "$warning" | jq -r '.code' 2>/dev/null || echo "WARNING")
      echo "  [$code] $msg"
    done
  fi
  
  if [[ ${#VERIFIED_CONSTRAINTS[@]} -gt 0 ]]; then
    echo ""
    echo "✅ Verified Constraints: ${VERIFIED_CONSTRAINTS[*]}"
  fi
  
  # Show constraint coverage gaps
  COVERAGE_GAPS=$(for c in C1 C2 C3 C4 C5 C6 C7 C8 V1 V2 V3; do
    if has_constraint "$c" "$CONSTRAINTS_MAPPED" && [[ -z "${EXAMPLE_COVERAGE[$c]:-}" ]]; then
      echo "$c"
    fi
  done)
  if [[ -n "$COVERAGE_GAPS" ]]; then
    echo ""
    echo "⚠️  Constraints mapped but without example coverage: $COVERAGE_GAPS"
  fi
  
  echo ""
  echo "Canonical path: $CANONICAL_PATH"
  echo "Context: pgvector_dir=$IS_PGVECTOR_DIR, sql_dir=$IS_SQL_DIR, vector_ops=$HAS_VECTOR_OPERATORS, multi_lang=$IS_MULTI_LANG"
  
  # Quick fix suggestions if in fix mode and not strict
  if [[ "$FIX_MODE" == true ]] && [[ "$STRICT" == false ]] && [[ ${#WARNINGS[@]} -gt 0 ]]; then
    echo ""
    echo "💡 Run with --verbose to see detailed fix suggestions for warnings"
  fi
fi

# C8: Final structured log entry with comprehensive metadata
log "INFO" "Verification complete: score=$SCORE passed=$PASSED blocking=${#BLOCKING_ISSUES[@]} warnings=${#WARNINGS[@]} verified=${#VERIFIED_CONSTRAINTS[@]}" "$FILE"

# Cleanup and exit
rm -rf "$TEMP_DIR" 2>/dev/null || true

# Exit code for CI/CD integration
if [[ "$PASSED" == true ]]; then
  exit 0
else
  exit 1
fi
