#!/usr/bin/env python3
"""
---
artifact_id: "goals-health-check-agents-py"
artifact_type: "monitoring_script"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
validation_command: "python3 goals/scripts/health-check-agents.py"
canonical_path: "goals/scripts/health-check-agents.py"
tier: 2
immutable: false
requires_human_approval_for_changes: false
audience: ["orchestrator-engine", "sysadmin", "observability-pipeline"]
human_readable: false
language_lock: "python3"
prompt_hash: "sha256:health-check-agents-v1.0.0"
generated_at: "2026-05-22T03:25:00Z"
tenant_context: "nao_aplicavel"
language: "python3"
domain: "goals"
subdomain: "scripts"
agent_role: "orchestrator-engine"
agent_specialty: "monitoring"
status: "✅ Estável"
next_review: "2026-06-22"
license: "CC-BY-NC-SA-4.0"
---
Verifica heartbeats de agentes leyendo registry.yaml y reporta agentes caídos.
"""

import sys
import yaml
import argparse
from datetime import datetime, timezone, timedelta
from pathlib import Path

DEFAULT_HEARTBEAT_TIMEOUT_MINUTES = 15

def main():
    parser = argparse.ArgumentParser(description='Health check de agentes MANTIS')
    parser.add_argument('--registry', default='goals/registry.yaml',
                        help='Ruta al registry.yaml')
    parser.add_argument('--timeout', type=int, default=DEFAULT_HEARTBEAT_TIMEOUT_MINUTES,
                        help='Timeout en minutos para considerar un agente caído')
    parser.add_argument('--json', action='store_true', help='Salida en formato JSON')
    args = parser.parse_args()

    reg_path = Path(args.registry)
    if not reg_path.exists():
        print(f"ERROR: registry no encontrado: {args.registry}")
        sys.exit(1)

    with open(reg_path, 'r', encoding='utf-8') as f:
        data = yaml.safe_load(f)

    now = datetime.now(timezone.utc)
    unhealthy = []

    for goal in data.get('goals', []):
        if goal.get('status') not in ('active', 'paused', 'budget_limited'):
            continue
        agent = goal.get('assigned_agent', 'unknown')
        heartbeat_str = goal.get('heartbeat_at')
        if not heartbeat_str:
            unhealthy.append({'agent': agent, 'goal_id': goal.get('goal_id'), 'reason': 'sin heartbeat'})
            continue
        try:
            heartbeat = datetime.fromisoformat(heartbeat_str.replace('Z', '+00:00'))
        except ValueError:
            unhealthy.append({'agent': agent, 'goal_id': goal.get('goal_id'), 'reason': 'heartbeat inválido'})
            continue
        if now - heartbeat > timedelta(minutes=args.timeout):
            unhealthy.append({'agent': agent, 'goal_id': goal.get('goal_id'),
                              'reason': f'último heartbeat {heartbeat.isoformat()}, hace más de {args.timeout} min'})

    if args.json:
        import json
        print(json.dumps({'unhealthy_agents': unhealthy}, indent=2))
    else:
        if unhealthy:
            print("Agentes no saludables:")
            for u in unhealthy:
                print(f"  - {u['agent']} (goal {u['goal_id']}): {u['reason']}")
        else:
            print("Todos los agentes activos tienen heartbeat reciente.")

    sys.exit(0 if not unhealthy else 1)

if __name__ == '__main__':
    main()
