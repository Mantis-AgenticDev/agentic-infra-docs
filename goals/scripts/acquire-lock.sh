#!/bin/bash
# ---
# artifact_id: "goals-acquire-lock-sh"
# artifact_type: "operations_script"
# version: "1.0.0"
# constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
# validation_command: "bash goals/scripts/acquire-lock.sh --help"
# canonical_path: "goals/scripts/acquire-lock.sh"
# tier: 2
# immutable: false
# requires_human_approval_for_changes: false
# audience: ["master-agents", "orchestrator-engine"]
# human_readable: false
# language_lock: "bash+python3"
# prompt_hash: "sha256:acquire-lock-v1.0.0"
# generated_at: "2026-05-22T05:30:00Z"
# tenant_context: "nao_aplicavel"
# language: "bash"
# domain: "goals"
# subdomain: "scripts"
# agent_role: "orchestrator-engine"
# agent_specialty: "lock-management"
# status: "✅ Estável"
# next_review: "2026-06-22"
# license: "CC-BY-NC-SA-4.0"
# ---
# Adquisición segura de lock sobre una meta (CAS).
# Uso: acquire-lock.sh --goal-id <uuid> --agent <name> [--registry file] [--ttl seconds]

set -euo pipefail

REGISTRY="goals/registry.yaml"
GOAL_ID=""
AGENT_NAME=""
TTL=3600
JSON_OUT=false

usage() {
  cat <<EOF
Uso: $0 --goal-id <goal-id> --agent <agent-name> [--registry <file>] [--ttl <seconds>] [--json]
Adquiere el lock de una meta en el registry usando CAS atómico.
EOF
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --goal-id) GOAL_ID="$2"; shift 2 ;;
    --agent) AGENT_NAME="$2"; shift 2 ;;
    --registry) REGISTRY="$2"; shift 2 ;;
    --ttl) TTL="$2"; shift 2 ;;
    --json) JSON_OUT=true; shift ;;
    *) usage ;;
  esac
done

if [ -z "$GOAL_ID" ] || [ -z "$AGENT_NAME" ]; then
  usage
fi

if [ ! -f "$REGISTRY" ]; then
  echo "ERROR: registry no encontrado: $REGISTRY"
  exit 1
fi

# Invocamos Python 3 con el script de adquisición CAS
exec python3 <<PYEOF
import sys, yaml, fcntl, uuid, json
from datetime import datetime, timezone

registry_path = "$REGISTRY"
goal_id = "$GOAL_ID"
agent = "$AGENT_NAME"
ttl = int("$TTL")
json_out = "$JSON_OUT" == "true"

def now_iso():
    return datetime.now(timezone.utc).isoformat(timespec='seconds').replace('+00:00', 'Z')

try:
    with open(registry_path, 'r+', encoding='utf-8') as f:
        # Bloquear el archivo para operación atómica
        fcntl.flock(f, fcntl.LOCK_EX)
        try:
            data = yaml.safe_load(f)
            if not data or 'goals' not in data:
                raise ValueError("registry mal formado")
            goals = data['goals']
            target = None
            for g in goals:
                if g.get('goal_id') == goal_id:
                    target = g
                    break
            if not target:
                raise ValueError(f"meta {goal_id} no encontrada")
            # Verificar estado
            status = target.get('status')
            if status not in ('active', 'paused'):
                raise ValueError(f"meta en estado '{status}', no se puede adquirir")
            # Verificar dueño actual
            current_owner = target.get('assigned_agent')
            hb_str = target.get('heartbeat_at')
            if current_owner and current_owner != agent:
                # Verificar si el heartbeat está fresco
                if hb_str:
                    try:
                        hb = datetime.fromisoformat(hb_str.replace('Z', '+00:00'))
                        now = datetime.now(timezone.utc)
                        if (now - hb).total_seconds() < ttl:
                            raise ValueError(f"meta retenida por {current_owner} (heartbeat reciente)")
                    except:
                        pass  # heartbeat inválido, considerar expirado
            # CAS: leer lock_version actual
            lock_version = target.get('lock_version', 0)
            # Actualizar campos
            target['lock_version'] = lock_version + 1
            target['assigned_agent'] = agent
            target['heartbeat_at'] = now_iso()
            target['status'] = 'active'
            # Volcar al archivo
            f.seek(0)
            yaml.safe_dump(data, f, allow_unicode=True, sort_keys=False)
            f.truncate()
            # Éxito
            if json_out:
                print(json.dumps({
                    "status": "ok",
                    "goal_id": goal_id,
                    "agent": agent,
                    "lock_version": target['lock_version'],
                    "heartbeat_at": target['heartbeat_at']
                }))
            else:
                print(f"Lock adquirido: goal={goal_id}, agent={agent}, lock_version={target['lock_version']}")
        finally:
            fcntl.flock(f, fcntl.LOCK_UN)
except Exception as e:
    if json_out:
        print(json.dumps({"status": "error", "message": str(e)}))
    else:
        print(f"ERROR: {e}")
    sys.exit(1)
PYEOF
