#!/usr/bin/env python3
"""
---
artifact_id: "goals-check-a2a-contract-py"
artifact_type: "validation_script"
version: "2.0.0"
constraints_mapped: ["C9"]
validation_command: "python3 goals/scripts/check_a2a_contract.py --task-id TASK_ID --agent AGENT"
canonical_path: "goals/scripts/check_a2a_contract.py"
tier: 1
immutable: false
language_lock: "python3"
prompt_hash: "sha256:check-a2a-contract-v2.0.0"
generated_at: "2026-05-22T07:10:00Z"
domain: "goals"
subdomain: "scripts"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Valida el contrato A2A (C9) usando JSON Schema y comprobación de consistencia.
"""

import sys
import argparse
import json
from pathlib import Path
sys.path.append(str(Path(__file__).resolve().parent.parent))
from libs.contract_parser import ContractParser

def main():
    parser = argparse.ArgumentParser(description="Validador de contrato A2A (C9)")
    parser.add_argument("--task-id", required=True, help="ID de la tarea")
    parser.add_argument("--agent", required=True, help="Nombre del agente")
    parser.add_argument("--json", action="store_true", help="Salida JSON")
    args = parser.parse_args()

    base_dir = Path(f"goals/task-{args.task_id}")
    trace_file = base_dir / "context" / "trace.json"
    status_file = base_dir / "artifacts" / args.agent / "status.json"

    cp = ContractParser()
    errors = []

    if not status_file.exists():
        errors.append("status.json ausente")

    if not trace_file.exists():
        errors.append("trace.json ausente")

    if not errors:
        try:
            cp.validate_status(str(status_file))
        except Exception as e:
            errors.append(f"status.json inválido: {e}")

        try:
            cp.validate_trace(str(trace_file))
        except Exception as e:
            errors.append(f"trace.json inválido: {e}")

        if not errors:
            try:
                cp.check_cross_consistency(str(trace_file), str(status_file))
            except Exception as e:
                errors.append(f"Inconsistencia: {e}")

    if args.json:
        output = {"status": "ok" if not errors else "error", "errors": errors}
        print(json.dumps(output, indent=2))
    else:
        if errors:
            print("ERRORES de contrato C9:")
            for e in errors:
                print(f"  - {e}")
        else:
            print("OK: contrato C9 compliant")

    sys.exit(1 if errors else 0)

if __name__ == "__main__":
    main()
