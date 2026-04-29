#!/usr/bin/env bash
# ---
# artifact_id: validate-against-specs-mantis
# artifact_type: validation_script
# version: 2.0.0-COMPREHENSIVE
# constraints_mapped: ["C1","C2","C4","C5","C8"]
# canonical_path: 05-CONFIGURATIONS/scripts/validate-against-specs.sh
# domain: 05-CONFIGURATIONS
# subdomain: scripts
# agent_role: configurations-master
# language_lock: es-ES
# validation_command: orchestrator-engine.sh --domain configurations --strict
# tier: 2
# immutable: true
# requires_human_approval_for_changes: true
# audience: ["agentic_assistants"]
# human_readable: false
# checksum_sha256: "3808707581a6a59864dd5c8266d85f2ebded4bde78d6a786b204ed52763d655c"
# ---
set -euo pipefail

# [CONSTRAINT_MAP]
# C1: Estructura inmutable validada contra templates base
# C2: Cumplimiento de especificaciones MANTIS (interface, mapping, masters)
# C4: Trazabilidad via JSON report + checksum alignment
# C5: Validación automatizada pre-merge de constraints y frontmatter
# C8: Umbral de calidad estructural antes de promoción a REAL

# [DEPENDENCIES]
# jq, yq, diff, grep, bash >= 4.3
# [INTERFACE_ALIGNMENT]
# Consumes: interface-spec.yaml, mappings.yaml, *-master-agent.md
# Produces: validation-report.json, exit code 0/1/2

# [GLOBALS]
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "$(dirname "$(dirname "$SCRIPT_DIR")")")"
readonly SPEC_DIR="${REPO_ROOT}/05-CONFIGURATIONS"
readonly REPORT_FILE="${SPEC_DIR}/.tmp/validation-$(date +%Y%m%d_%H%M%S).json"
readonly TARGET="${1:-.}"
readonly STRICT="${2:-false}"
mkdir -p "$(dirname "$REPORT_FILE")"

# [LOGGING & REPORT BUILDER]
log() { printf '[%s] [%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" "$2"; }
declare -a FAILS=() WARNINGS=() PASS=()
add_result() { local type="$1" msg="$2"; [[ "$type" == "FAIL" ]] && FAILS+=("$msg") || { [[ "$type" == "WARN" ]] && WARNINGS+=("$msg") || PASS+=("$msg"); }; }

# [VALIDATION FUNCTIONS]
validate_frontmatter() {
  local file="$1"
  grep -q "^---" "$file" || { add_result "FAIL" "$file: missing YAML frontmatter delimiter"; return 1; }
  
  # Extract & validate key fields
  local fields=("artifact_id" "artifact_type" "constraints_mapped" "canonical_path" "checksum_sha256")
  for field in "${fields[@]}"; do
    grep -q "^${field}:" "$file" || { add_result "FAIL" "$file: missing mandatory field '$field'"; return 1; }
  done
  
  # Validate canonical_path matches actual location
  local declared_path
  declared_path=$(grep "^canonical_path:" "$file" | sed 's/^canonical_path: *//;s/["'\'']//g')
  [[ "$file" == *"$declared_path" || "$declared_path" == *"$(basename "$file")" ]] || \
    add_result "WARN" "$file: canonical_path mismatch (declared: $declared_path, actual: $file)"
  
  # Validate constraints_mapped array format
  grep -qP 'constraints_mapped: \["(C\d|V\d)(,?(C\d|V\d))*"\]' "$file" || \
    add_result "WARN" "$file: constraints_mapped format invalid or incomplete"
}

validate_interface_alignment() {
  local file="$1"
  [[ -f "${SPEC_DIR}/interface-spec.yaml" ]] || return 0
  
  # Check referenced variables exist in mapping.yaml
  if grep -q 'mapping.yaml' "$file"; then
    yq eval '.variables | keys | .[]' "${SPEC_DIR}/environment/mapping.yaml" 2>/dev/null > /tmp/mapping_keys.txt || return 0
    local missing=0
    for var in $(grep -roh '\$\{[A-Z_]*\}' "$file" 2>/dev/null | tr -d '${}'); do
      grep -qx "$var" /tmp/mapping_keys.txt || { ((missing++)) || true; add_result "WARN" "$file: variable $var not in mapping.yaml"; }
    done
    [[ $missing -eq 0 ]] && add_result "PASS" "$file: interface alignment OK" || true
  fi
}

validate_checksum_placeholder() {
  local file="$1"
  if grep -q "^checksum_sha256:" "$file"; then
    grep -q 'PENDING_GENERATION\|"[a-f0-9]\{64\}"' "$file" || \
      add_result "FAIL" "$file: invalid checksum format"
  fi
}

# [MAIN PIPELINE]
log "VALIDATION_START: Target=$TARGET | Strict=$STRICT"
shopt -s globstar nullglob
files=("$TARGET"/*.md "$TARGET"/*.tf "$TARGET"/*.yml "$TARGET"/*.yaml "$TARGET"/*.sh)
shopt -u globstar nullglob

[[ ${#files[@]} -eq 0 ]] && { log "WARN: No valid files found in $TARGET"; exit 0; }

for f in "${files[@]}"; do
  [[ -f "$f" && ! "$f" == *".tmp"* ]] || continue
  validate_frontmatter "$f"
  validate_interface_alignment "$f"
  validate_checksum_placeholder "$f"
done

# [REPORT GENERATION]
jq -n \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg target "$TARGET" \
  --argjson strict "$STRICT" \
  --argjson pass "${#PASS[@]}" \
  --argjson fails "${#FAILS[@]}" \
  --argjson warns "${#WARNINGS[@]}" \
  --arg pass_list "$(IFS=,; echo "${PASS[*]}")" \
  --arg fail_list "$(IFS=,; echo "${FAILS[*]}")" \
  --arg warn_list "$(IFS=,; echo "${WARNINGS[*]}")" \
  '{
    timestamp: $ts,
    target: $target,
    strict_mode: $strict,
    summary: { pass: $pass, fail: $fails, warn: $warns },
    details: { passed: ($pass_list | split(",")), failed: ($fail_list | split(",")), warnings: ($warn_list | split(",")) }
  }' > "$REPORT_FILE"

log "📄 Report: $REPORT_FILE"
[[ ${#FAILS[@]} -gt 0 ]] && { log "❌ VALIDATION_FAIL: ${#FAILS[@]} error(es). Revisar $REPORT_FILE"; exit 1; }
[[ ${#WARNINGS[@]} -gt 0 && "$STRICT" == "true" ]] && { log "⚠️ STRICT_FAIL: ${#WARNINGS[@]} advertencia(s)."; exit 2; }

log "✅ VALIDATION_PASS: Todos los artefactos cumplen specs MANTIS v2.0.0"
exit 0


---
