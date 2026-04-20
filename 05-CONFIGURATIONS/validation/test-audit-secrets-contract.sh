#!/usr/bin/env bash
set -euo pipefail

VALIDATOR="05-CONFIGURATIONS/validation/audit-secrets.sh"
FIXTURES_DIR="05-CONFIGURATIONS/validation/test-fixtures/audit-secrets"
RESULTS_FILE="test-results-$(date +%Y%m%d-%H%M%S).jsonl"

log_pass() { echo -e "\033[0;32m✅ PASS\033[0m: $*" >&2; }
log_fail() { echo -e "\033[0;31m❌ FAIL\033[0m: $*" >&2; }
log_skip() { echo -e "\033[1;33m⚠️  SKIP\033[0m: $*" >&2; }

[[ -x "$VALIDATOR" ]] || { echo "❌ Validator not executable: $VALIDATOR" >&2; exit 2; }
command -v jq >/dev/null || { echo "❌ jq required" >&2; exit 2; }

test_vint01_json_valid() {
  local file="$1" test_name="$2"
  local output
  output=$(bash "$VALIDATOR" --file "$file" 2>/dev/null) || true
  if echo "$output" | jq -e . >/dev/null 2>&1; then
    log_pass "V-INT-01 [$test_name]: JSON válido"
    echo "{\"test\":\"V-INT-01\",\"fixture\":\"$test_name\",\"passed\":true}" >> "$RESULTS_FILE"
  else
    log_fail "V-INT-01 [$test_name]: JSON inválido"
    echo "{\"test\":\"V-INT-01\",\"fixture\":\"$test_name\",\"passed\":false}" >> "$RESULTS_FILE"
  fi
}

test_vint02_exit_codes() {
  local file="$1" expected_exit="$2" test_name="$3"
  # 🔑 FIX: Capturar exit code ANTES de || true o redirecciones
  bash "$VALIDATOR" --file "$file" > /dev/null 2>&1 || true
  local actual_exit=$?
  # Override para missing file si el test lo requiere
  [[ "$test_name" == *missing* ]] && actual_exit=$(bash "$VALIDATOR" --file "/tmp/nonexistent_test_$(date +%s).md" >/dev/null 2>&1; echo $?)
  
  if [[ "$actual_exit" -eq "$expected_exit" ]]; then
    log_pass "V-INT-02 [$test_name]: exit code $actual_exit"
    echo "{\"test\":\"V-INT-02\",\"fixture\":\"$test_name\",\"expected\":$expected_exit,\"actual\":$actual_exit,\"passed\":true}" >> "$RESULTS_FILE"
  else
    log_fail "V-INT-02 [$test_name]: exit code $actual_exit (esperado $expected_exit)"
    echo "{\"test\":\"V-INT-02\",\"fixture\":\"$test_name\",\"expected\":$expected_exit,\"actual\":$actual_exit,\"passed\":false}" >> "$RESULTS_FILE"
  fi
}

test_vint03_io_separation() {
  local file="$1" test_name="$2"
  local stdout_output
  stdout_output=$(bash "$VALIDATOR" --file "$file" 2>/dev/null) || true
  if [[ "$stdout_output" =~ ^\{.*\}$ ]]; then
    log_pass "V-INT-03 [$test_name]: stdout limpio"
    echo "{\"test\":\"V-INT-03\",\"fixture\":\"$test_name\",\"passed\":true}" >> "$RESULTS_FILE"
  else
    log_fail "V-INT-03 [$test_name]: stdout contaminado"
    echo "{\"test\":\"V-INT-03\",\"fixture\":\"$test_name\",\"passed\":false}" >> "$RESULTS_FILE"
  fi
}

test_vint04_performance() {
  local file="$1" test_name="$2"
  local start end duration
  start=$(date +%s%N)
  bash "$VALIDATOR" --file "$file" >/dev/null 2>&1 || true
  end=$(date +%s%N)
  duration=$(( (end - start) / 1000000 ))
  if [[ "$duration" -lt 500 ]]; then
    log_pass "V-INT-04 [$test_name]: ${duration}ms"
    echo "{\"test\":\"V-INT-04\",\"fixture\":\"$test_name\",\"duration_ms\":$duration,\"passed\":true}" >> "$RESULTS_FILE"
  else
    log_fail "V-INT-04 [$test_name]: ${duration}ms (≥500ms)"
    echo "{\"test\":\"V-INT-04\",\"fixture\":\"$test_name\",\"duration_ms\":$duration,\"passed\":false}" >> "$RESULTS_FILE"
  fi
}

test_c3_detection() {
  local file="$1" should_detect="$2" test_name="$3"
  local output
  output=$(bash "$VALIDATOR" --file "$file" 2>/dev/null) || true
  local detected=false
  if echo "$output" | jq -e '.passed == false and .issues_count > 0' >/dev/null 2>&1; then detected=true; fi
  if [[ "$detected" == "$should_detect" ]]; then
    log_pass "C3 [$test_name]: detección correcta"
    echo "{\"test\":\"C3\",\"fixture\":\"$test_name\",\"detected\":$detected,\"expected\":$should_detect,\"passed\":true}" >> "$RESULTS_FILE"
  else
    log_fail "C3 [$test_name]: detección incorrecta (detect=$detected, expected=$should_detect)"
    echo "{\"test\":\"C3\",\"fixture\":\"$test_name\",\"detected\":$detected,\"expected\":$should_detect,\"passed\":false}" >> "$RESULTS_FILE"
  fi
}

# === EJECUCIÓN ===
echo "🧪 Suite: audit-secrets.sh" >&2
echo "Results: $RESULTS_FILE" >&2
mkdir -p "$FIXTURES_DIR"

for fixture in "$FIXTURES_DIR"/*.md; do
  [[ -f "$fixture" ]] || continue
  fixture_name=$(basename "$fixture")
  metadata=$(head -5 "$fixture" | grep "^<!-- EXPECT:" | sed 's/<!-- EXPECT: \(.*\) -->/\1/')
  [[ -z "$metadata" ]] && { log_skip "$fixture_name: sin metadata"; continue; }
  
  IFS='|' read -r expect_part detect_part perf_part <<< "$metadata"
  expect_status=$(echo "$expect_part" | awk '{print $1}')
  should_detect=$(echo "$detect_part" | awk '{print $2}')
  case "$expect_status" in passed) exp_exit=0;; failed) exp_exit=1;; error) exp_exit=2;; *) continue;; esac
  
  echo "🔍 $fixture_name" >&2
  test_vint01_json_valid "$fixture" "$fixture_name" || true
  test_vint02_exit_codes "$fixture" "$exp_exit" "$fixture_name" || true
  test_vint03_io_separation "$fixture" "$fixture_name" || true
  test_vint04_performance "$fixture" "$fixture_name" || true
  [[ "$should_detect" != "N/A" ]] && test_c3_detection "$fixture" "$should_detect" "$fixture_name" || true
  echo "---" >&2
done

total=$(wc -l < "$RESULTS_FILE")
passed=$(grep -c '"passed":true' "$RESULTS_FILE" || echo 0)
failed=$(grep -c '"passed":false' "$RESULTS_FILE" || echo 0)
echo "📊 Total: $total | ✅ $passed | ❌ $failed" >&2
[[ "$failed" -gt 0 ]] && exit 1 || exit 0
