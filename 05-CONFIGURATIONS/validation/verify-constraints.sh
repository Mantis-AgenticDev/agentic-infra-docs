#!/usr/bin/env bash
#---
# metadata_version: 1.0
# sdd_compliant: true
# ai_parser_compatible: true
# purpose: "Validación explícita de constraints C1-C6 en ejemplos y código"
# constraint: "C1:RAM≤4GB | C2:1vCPU | C3:No-Hardcode | C4:tenant_id | C5:SHA256 | C6:Cloud-Only"
# output_format: "json + stdout + exit code"
# ---
set -euo pipefail

readonly VERSION="1.0.0"
readonly PROJECT_ROOT="${1:-.}"
readonly REPORT_FILE="${2:-constraints-verify-report.json}"
readonly VERBOSE="${3:-0}"
readonly STRICT="${4:-0}"

declare -a FAILURES=()
declare -i FILES_CHECKED=0
declare -i CONSTRAINTS_PASSED=0

log_info() { [[ "$VERBOSE" == "1" ]] && echo "[INFO] $*" || true; }
log_fail() { echo "[C-FAIL] $*" >&2; FAILURES+=("$*"); }

validate_c1() {
  local file="$1"
  grep -qE '(timeout_ms|memory_limit|shm_size|mem_limit|max_connections|EXECUTIONS_MAX_CONCURRENT)' "$file" && return 0
  log_fail "C1: Sin límites de recursos explícitos en $file"
  return 1
}

validate_c2() {
  local file="$1"
  grep -qE '(cpus:|cpu_limit|nice |ionice |concurrency_limit|rate_limit)' "$file" && return 0
  log_fail "C2: Sin aislamiento de CPU/concurrencia en $file"
  return 1
}

validate_c3() {
  local file="$1"
  # Si pasa audit-secrets.sh, se asume C3 OK. Aquí validamos presencia de gestión segura
  grep -qE '(process\.env\.|os\.getenv\(|\$\{[A-Z_]+\}|docker.*--env-file|age -r|vault)' "$file" && return 0
  log_fail "C3: Sin gestión segura de secretos en $file"
  return 1
}

validate_c4() {
  local file="$1"
  grep -qiE '(tenant_id|ctx\.tenant|current_tenant|X-Tenant-ID|RLS.*tenant)' "$file" && return 0
  log_fail "C4: Sin aislamiento multi-tenant en $file"
  return 1
}

validate_c5() {
  local file="$1"
  grep -qiE '(sha256|checksum|audit_hash|backup.*enc|age -r|verify.*integrity)' "$file" && return 0
  log_fail "C5: Sin trazabilidad de integridad en $file"
  return 1
}

validate_c6() {
  local file="$1"
  # Excepción explícita para Llama/open-weight
  if grep -qiE '(openrouter|api\.openai|cloud.*inference|provider.*cloud)' "$file"; then return 0; fi
  if grep -qiE '(llama.*local|c6_exception_documented.*true|open.*weight.*exception)' "$file"; then return 0; fi
  log_fail "C6: Sin inferencia cloud documentada o excepción válida en $file"
  return 1
}

check_file() {
  local file="$1"
  [[ ! -f "$file" || "$file" == *".git"* ]] && return 0
  ((FILES_CHECKED++)) || true
  
  local file_ok=true
  validate_c1 "$file" || file_ok=false
  validate_c2 "$file" || file_ok=false
  validate_c3 "$file" || file_ok=false
  validate_c4 "$file" || file_ok=false
  validate_c5 "$file" || file_ok=false
  validate_c6 "$file" || file_ok=false

  if [[ "$file_ok" == "true" ]]; then
    ((CONSTRAINTS_PASSED++)) || true
  fi
}

scan_dir() {
  while IFS= read -r -d '' f; do check_file "$f"; done < <(find "${1:-.}" -type f \( -name "*.md" -o -name "*.tf" -o -name "*.yml" -o -name "*.py" -o -name "*.sh" \) -print0 2>/dev/null)
}

generate_report() {
  local status="passed"
  [[ ${#FAILURES[@]} -gt 0 && "$STRICT" == "1" ]] && status="failed"
  [[ ${#FAILURES[@]} -gt 0 ]] && status="failed"

  cat > "$REPORT_FILE" << EOF
{
  "validator_version": "$VERSION",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "target": "$PROJECT_ROOT",
  "status": "$status",
  "summary": {
    "files_checked": $FILES_CHECKED,
    "constraints_passed": $CONSTRAINTS_PASSED,
    "failures_count": ${#FAILURES[@]}
  },
  "failures": $(printf '%s\n' "${FAILURES[@]}" | sed 's/"/\\"/g' | paste -sd ',' | awk '{print "["$0"]"}'),
  "audit": { "script_sha256": "$(sha256sum "$0" | awk '{print $1}')" }
}
EOF

  echo "✅ Constraints C1-C6: $CONSTRAINTS_PASSED/$FILES_CHECKED OK | 📄 $REPORT_FILE"
  [[ "$status" == "failed" ]] && exit 1
  exit 0
}

main() {
  log_info "Verificando constraints C1-C6 v$VERSION"
  scan_dir "$PROJECT_ROOT"
  generate_report
}
main "$@"
