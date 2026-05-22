#!/bin/bash
# ---
# artifact_id: "goals-check-a2a-contract-sh"
# artifact_type: "validation_script"
# version: "1.0.0"
# constraints_mapped: ["C9"]
# validation_command: "bash goals/scripts/check-a2a-contract.sh --task-id $TASK_ID --agent $AGENT_NAME --json"
# canonical_path: "goals/scripts/check-a2a-contract.sh"
# tier: 1
# immutable: false
# requires_human_approval_for_changes: true
# audience: ["orchestrator-engine", "master-agents", "human-architects"]
# human_readable: false
# language_lock: "bash"
# prompt_hash: "sha256:check-a2a-contract-v1.0.0"
# generated_at: "2026-05-22T03:30:00Z"
# tenant_context: "nao_aplicavel"
# language: "bash"
# domain: "goals"
# subdomain: "scripts"
# agent_role: "orchestrator-engine"
# agent_specialty: "a2a-validation"
# status: "✅ Estável"
# next_review: "2026-06-22"
# license: "CC-BY-NC-SA-4.0"
# ---
# Valida el contrato A2A (C9) para un handoff.
# Uso: check-a2a-contract.sh --task-id <id> --agent <agent-name> [--json]

set -euo pipefail

TASK_ID=""
AGENT_NAME=""
JSON_OUT=false
TRACE_FILE=""
STATUS_FILE=""

usage() {
  echo "Uso: $0 --task-id <id> --agent <agent-name> [--json]"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --task-id) TASK_ID="$2"; shift 2 ;;
    --agent) AGENT_NAME="$2"; shift 2 ;;
    --json) JSON_OUT=true; shift ;;
    *) usage ;;
  esac
done

if [ -z "$TASK_ID" ] || [ -z "$AGENT_NAME" ]; then
  usage
fi

BASE_DIR="./goals/task-${TASK_ID}"
TRACE_FILE="${BASE_DIR}/context/trace.json"
STATUS_FILE="${BASE_DIR}/artifacts/${AGENT_NAME}/status.json"

# Verificar existencia de status.json
if [ ! -f "$STATUS_FILE" ]; then
  if $JSON_OUT; then
    echo '{"status":"error","message":"status.json ausente"}'
  else
    echo "ERROR: status.json no encontrado en $STATUS_FILE"
  fi
  exit 1
fi

# Verificar existencia de trace.json (si existe, para consistencia)
TRACE_TRACE_ID=""
if [ -f "$TRACE_FILE" ]; then
  TRACE_TRACE_ID=$(jq -r '.trace_id // empty' "$TRACE_FILE")
fi

# Extraer campos de status.json
STATUS_TRACE_ID=$(jq -r '.trace_id // empty' "$STATUS_FILE")
SPAN_ID=$(jq -r '.span_id // empty' "$STATUS_FILE")
PARENT_SPAN_ID=$(jq -r '.parent_span_id // empty' "$STATUS_FILE")
STATUS=$(jq -r '.status // empty' "$STATUS_FILE")
OUTPUT_REF=$(jq -r '.output_ref // empty' "$STATUS_FILE")
A2A_VERSION=$(jq -r '.a2a_contract_version // empty' "$STATUS_FILE")
AGENT_ID_STATUS=$(jq -r '.agent_id // empty' "$STATUS_FILE")

errors=()
warnings=()

# Campos obligatorios
[[ -z "$STATUS_TRACE_ID" ]] && errors+=("trace_id ausente en status.json")
[[ -z "$SPAN_ID" ]] && errors+=("span_id ausente en status.json")
[[ -z "$STATUS" ]] && errors+=("status ausente en status.json")
[[ -z "$OUTPUT_REF" ]] && errors+=("output_ref ausente en status.json")

# Validar formato UUID para trace_id y span_id
uuid_regex='^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
if [[ -n "$STATUS_TRACE_ID" && ! "$STATUS_TRACE_ID" =~ $uuid_regex ]]; then
  errors+=("trace_id no es UUID válido: $STATUS_TRACE_ID")
fi
if [[ -n "$SPAN_ID" && ! "$SPAN_ID" =~ $uuid_regex ]]; then
  errors+=("span_id no es UUID válido: $SPAN_ID")
fi

# Validar status
if [[ -n "$STATUS" && "$STATUS" != "completed" && "$STATUS" != "failed" ]]; then
  errors+=("status debe ser 'completed' o 'failed', no '$STATUS'")
fi

# Consistencia de trace_id con trace.json si existe
if [[ -n "$TRACE_TRACE_ID" && -n "$STATUS_TRACE_ID" && "$TRACE_TRACE_ID" != "$STATUS_TRACE_ID" ]]; then
  errors+=("trace_id inconsistente entre trace.json ($TRACE_TRACE_ID) y status.json ($STATUS_TRACE_ID)")
fi

# Coincidencia de agent_id con el nombre de agente proporcionado
if [[ -n "$AGENT_ID_STATUS" && "$AGENT_ID_STATUS" != "$AGENT_NAME" ]]; then
  warnings+=("agent_id en status.json ($AGENT_ID_STATUS) no coincide con --agent ($AGENT_NAME)")
fi

# Validar parent_span_id (si existe, debe ser UUID o null)
if [[ -n "$PARENT_SPAN_ID" && "$PARENT_SPAN_ID" != "null" && ! "$PARENT_SPAN_ID" =~ $uuid_regex ]]; then
  warnings+=("parent_span_id no es un UUID válido ni null: $PARENT_SPAN_ID")
fi

# Versión del contrato
if [[ -z "$A2A_VERSION" ]]; then
  warnings+=("a2a_contract_version ausente")
fi

if [ ${#errors[@]} -gt 0 ]; then
  if $JSON_OUT; then
    echo "{\"status\":\"error\",\"errors\":$(printf '%s\n' "${errors[@]}" | jq -R . | jq -s .)}"
  else
    echo "ERRORES de contrato C9:"
    for e in "${errors[@]}"; do echo "  - $e"; done
  fi
  exit 1
fi

if $JSON_OUT; then
  warn_json="[]"
  if [ ${#warnings[@]} -gt 0 ]; then
    warn_json=$(printf '%s\n' "${warnings[@]}" | jq -R . | jq -s .)
  fi
  echo "{\"status\":\"ok\",\"message\":\"C9 compliant\",\"warnings\":$warn_json}"
else
  echo "OK: contrato C9 compliant"
  if [ ${#warnings[@]} -gt 0 ]; then
    echo "Advertencias:"
    for w in "${warnings[@]}"; do echo "  - $w"; done
  fi
fi
exit 0
