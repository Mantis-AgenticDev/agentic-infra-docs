#!/usr/bin/env python3
"""
---
artifact_id: "goals-validate-registry-py"
artifact_type: "validation_script"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
validation_command: "python3 goals/scripts/validate-registry.py --file goals/registry.yaml"
canonical_path: "goals/scripts/validate-registry.py"
tier: 2
immutable: false
requires_human_approval_for_changes: false
audience: ["orchestrator-engine", "master-agents", "human-architects"]
human_readable: false
language_lock: "python3"
prompt_hash: "sha256:validate-registry-v1.0.0"
generated_at: "2026-05-22T03:15:00Z"
tenant_context: "nao_aplicavel"
language: "python3"
domain: "goals"
subdomain: "scripts"
agent_role: "orchestrator-engine"
agent_specialty: "validation"
status: "✅ Estável"
next_review: "2026-06-22"
license: "CC-BY-NC-SA-4.0"
---
Valida la estructura del registry.yaml y otros archivos YAML de goals.
"""

import sys
import yaml
import argparse
import uuid
from datetime import datetime
from pathlib import Path

REQUIRED_GOAL_FIELDS = {
    'goal_id': str,
    'objective': str,
    'assigned_agent': str,
    'provider': str,
    'status': str,
    'token_budget': (int, type(None)),
    'tokens_used': int,
    'time_used_seconds': int,
    'created_at': str,
    'updated_at': str,
    'next_wakeup': (str, type(None)),
    'lock_version': int,
    'heartbeat_at': str,
    'metrics': dict,
}

VALID_STATUSES = {'active', 'paused', 'budget_limited', 'complete'}

def validate_goal(goal, index):
    errors = []
    for field, ftype in REQUIRED_GOAL_FIELDS.items():
        if field not in goal:
            errors.append(f"goal[{index}]: falta campo '{field}'")
            continue
        value = goal[field]
        if not isinstance(value, ftype):
            if isinstance(ftype, tuple):
                if not any(isinstance(value, t) for t in ftype):
                    errors.append(f"goal[{index}]: tipo incorrecto para '{field}'")
            else:
                errors.append(f"goal[{index}]: tipo incorrecto para '{field}'")
    if goal.get('status') not in VALID_STATUSES:
        errors.append(f"goal[{index}]: status inválido '{goal.get('status')}'")
    # Validate UUID format for goal_id
    try:
        uuid.UUID(goal.get('goal_id', ''))
    except ValueError:
        errors.append(f"goal[{index}]: goal_id no es UUID válido")
    # Validate ISO 8601 timestamps
    for ts_field in ['created_at', 'updated_at', 'heartbeat_at']:
        if ts_field in goal:
            try:
                datetime.fromisoformat(goal[ts_field].replace('Z', '+00:00'))
            except ValueError:
                errors.append(f"goal[{index}]: {ts_field} no es ISO 8601 válido")
    if goal.get('next_wakeup') is not None:
        try:
            datetime.fromisoformat(goal['next_wakeup'].replace('Z', '+00:00'))
        except ValueError:
            errors.append(f"goal[{index}]: next_wakeup no es ISO 8601 válido")
    return errors

def main():
    parser = argparse.ArgumentParser(description='Valida archivos YAML de goals')
    parser.add_argument('--file', required=True, help='Ruta al archivo YAML')
    args = parser.parse_args()

    filepath = Path(args.file)
    if not filepath.exists():
        print(f"ERROR: archivo no encontrado: {args.file}")
        sys.exit(1)

    with open(filepath, 'r', encoding='utf-8') as f:
        try:
            data = yaml.safe_load(f)
        except yaml.YAMLError as e:
            print(f"ERROR: YAML inválido: {e}")
            sys.exit(1)

    if not isinstance(data, dict):
        print("ERROR: el archivo no contiene un diccionario YAML")
        sys.exit(1)

    if 'goals' not in data:
        print("ERROR: falta la clave 'goals'")
        sys.exit(1)

    goals = data['goals']
    if not isinstance(goals, list):
        print("ERROR: 'goals' debe ser una lista")
        sys.exit(1)

    all_errors = []
    for i, goal in enumerate(goals):
        all_errors.extend(validate_goal(goal, i))

    if all_errors:
        for err in all_errors:
            print(f"ERROR: {err}")
        sys.exit(1)
    else:
        print("OK: archivo válido")
        sys.exit(0)

if __name__ == '__main__':
    main()
