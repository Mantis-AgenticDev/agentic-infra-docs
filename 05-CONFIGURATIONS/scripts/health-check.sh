#!/usr/bin/env bash
# ---
# artifact_id: health-check-mantis
# artifact_type: monitoring_script
# version: 2.0.0-COMPREHENSIVE
# constraints_mapped: ["C4","C5","C7","C8"]
# canonical_path: 05-CONFIGURATIONS/scripts/health-check.sh
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
# checksum_sha256: "0643ac32702d67bf24ab62c8cad9fb40aed5f1fdd232bb6b208a2fa7b694ff12"
# ---
set -euo pipefail

# [CONSTRAINT_MAP]
# C4: Trazabilidad de estado via JSON output & timestamps
# C5: Validación estricta de endpoints, timeouts y retries
# C7: Trigger de rollback si health < threshold post-deploy
# C8: Calidad mínima: DB, API, Vector search deben responder OK

# [GLOBALS]
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ENV="${1:-dev}"
readonly TIMEOUT="${2:-10}"
readonly RETRIES="${3:-3}"
readonly BACKUP_DIR="${SCRIPT_DIR}/../.tmp/health-checks"
readonly REPORT_FILE="${BACKUP_DIR}/health-$(date +%Y%m%d_%H%M%S).json"
mkdir -p "$BACKUP_DIR"

# [ENV LOAD]
if [[ -f "${SCRIPT_DIR}/../environment/.env.${ENV}" ]]; then
  set -a; source "${SCRIPT_DIR}/../environment/.env.${ENV}"; set +a
fi

API_URL="${API_URL:-http://localhost:4000}"
DB_URL="${DATABASE_URL:-postgres://localhost:5432}"
QDRANT_URL="${QDRANT_ENDPOINT:-http://localhost:6333}"

# [LOGGING & JSON BUILDER]
declare -A RESULTS
log() { printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1"; }
add_result() { RESULTS["$1"]="$(jq -n --arg s "$2" --arg t "$3" '{status:$s, timestamp:$t})'; }

# [RETRY WRAPPER]
check_with_retry() {
  local name="$1" cmd="$2"
  for i in $(seq 1 "$RETRIES"); do
    if eval "$cmd" >/dev/null 2>&1; then
      add_result "$name" "ok" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
      return 0
    fi
    log "⏳ $name: intento $i/$RETRIES fallido. Reintentando en 2s..."
    sleep 2
  done
  add_result "$name" "fail" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  return 1
}

# [CHECKS]
# API HTTP Health
check_with_retry "api" "curl -sf --max-time $TIMEOUT ${API_URL}/health/ready | jq -e '.status == \"ok\"'" || true

# PostgreSQL Readiness (extract host from DB_URL)
DB_HOST=$(echo "$DB_URL" | grep -oP '(?<=://)[^:]+(?=:)')
DB_PORT=$(echo "$DB_URL" | grep -oP '(?<=:)\d+' | head -n1)
check_with_retry "postgres" "pg_isready -h ${DB_HOST} -p ${DB_PORT} -t $TIMEOUT" || true

# Qdrant Vector Search (V3 performance gate)
if [[ -n "$QDRANT_URL" && "$QDRANT_URL" != "null" ]]; then
  check_with_retry "qdrant" "curl -sf --max-time $TIMEOUT ${QDRANT_URL}/healthz | jq -e '.title == \"qdrant - vector search engine\"'" || true
else
  add_result "qdrant" "skipped" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
fi

# [REPORT & EXIT CODE]
FAIL_COUNT=0
JSON_REPORT="{"
for key in "${!RESULTS[@]}"; do
  JSON_REPORT+="\"$key\":${RESULTS[$key]},"
  [[ "${RESULTS[$key]}" == *"fail"* ]] && ((FAIL_COUNT++)) || true
done
JSON_REPORT="${JSON_REPORT%,}}"
JSON_REPORT+=",\"environment\":\"$ENV\",\"fail_count\":$FAIL_COUNT,\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"

echo "$JSON_REPORT" | jq . > "$REPORT_FILE"
log "📄 Reporte generado: $REPORT_FILE"

if [[ $FAIL_COUNT -gt 0 ]]; then
  log "❌ HEALTH_CHECK_FAIL: $FAIL_COUNT servicio(s) inestables. Trigger C7 rollback recomendado."
  exit 1
fi

log "✅ HEALTH_CHECK_PASS: Todos los servicios operativos."
exit 0


---
