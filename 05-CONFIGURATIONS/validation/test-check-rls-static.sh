#!/usr/bin/env bash
# test-check-rls-static.sh - Suite de pruebas estáticas para check-rls.sh
set -o pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
VALIDATOR="$REPO_ROOT/05-CONFIGURATIONS/validation/check-rls.sh"
FIXTURES_DIR="$REPO_ROOT/06-PROGRAMMING/sql/unit-test-patterns"
LOG_DIR="$REPO_ROOT/08-LOGS/validation/test-orchestrator-engine/check-rls"

mkdir -p "$LOG_DIR"
TEST_LOG_FILE="$LOG_DIR/test-run-$(date +%Y%m%d_%H%M%S).jsonl"

declare -A EXPECTED=(
  ["01-clean-rls-compliant.sql.md"]=0
  ["02-missing-where-tenant.sql.md"]=1
  ["03-bypass-comment.sql.md"]=0
  ["04-edge-special-chars.sql.md"]=0
  ["05-multi-violations.sql.md"]=1
  ["06-large-stress.sql.md"]=0
  ["07-missing-file-error.sql.md"]=2
  ["08-context-exception.sql.md"]=0
)

total=0; passed=0; failed=0

for fixture in "${!EXPECTED[@]}"; do
  file="$FIXTURES_DIR/$fixture"
  ((total++))
  if [[ "${EXPECTED[$fixture]}" -eq 2 ]]; then
    result=$("$VALIDATOR" --file "/tmp/does_not_exist_$$.sql.md" --log-file "$TEST_LOG_FILE" 2>/dev/null)
    exit_code=$?
  else
    result=$("$VALIDATOR" --file "$file" --log-file "$TEST_LOG_FILE" 2>/dev/null)
    exit_code=$?
  fi
  
  if [[ $exit_code -eq ${EXPECTED[$fixture]} ]]; then
    echo "✅ $fixture (exit $exit_code)"
    ((passed++))
  else
    echo "❌ $fixture: esperado ${EXPECTED[$fixture]}, obtuvo $exit_code"
    ((failed++))
  fi
  
  # Mostrar errores desde el log recién escrito (última línea del archivo)
  if [[ $exit_code -eq 1 ]]; then
    tail -1 "$TEST_LOG_FILE" | jq -r '.issues[] | "  🔴 Línea \(.line): \(.description)\n     \(.snippet)"' 2>/dev/null
  fi
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Resultados: $passed/$total pasaron"
echo "Logs guardados en: $TEST_LOG_FILE"
[[ $failed -eq 0 ]] && exit 0 || exit 1
