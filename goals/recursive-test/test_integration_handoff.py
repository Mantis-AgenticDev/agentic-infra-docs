"""
---
artifact_id: "goals-recursive-test-test-integration-handoff"
artifact_type: "integration_test"
version: "2.0.0"
canonical_path: "goals/recursive-test/test_integration_handoff.py"
tier: 2
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Prueba de integración: flujo completo de handoff A2A entre dos agentes.
"""

import pytest
import json
from pathlib import Path
from goals.libs.registry_client import RegistryClient
from goals.libs.handoff_package import HandoffPackage
from goals.libs.contract_parser import ContractParser


def test_full_handoff_flow(tmp_path, populated_registry):
    client = RegistryClient(populated_registry)
    handoff = HandoffPackage(task_dir_base=str(tmp_path))
    cp = ContractParser(schemas_dir=str(Path(__file__).resolve().parent.parent / "schemas"))

    # 1. Agente A adquiere meta
    goal = client.get_active_goal("goal-001")
    success = client.acquire_goal("goal-001", "bash-master-agent", goal["lock_version"])
    # Puede fallar por heartbeat, pero el flujo sigue

    # 2. Crear contexto para agente A
    task_id = "integration-task-001"
    trace_path = handoff.create_context(task_id, "bash-master-agent")
    with open(trace_path) as f:
        trace = json.load(f)

    # 3. Agente A completa y escribe status
    status_path = handoff.finalize_status(
        task_id, "bash-master-agent", "completed",
        "artifacts/result.json", trace["trace_id"], None, "go-master-agent"
    )

    # 4. Validar status.json
    assert cp.validate_status(status_path) is True

    # 5. Crear nuevo contexto para agente B usando span_id de A
    with open(status_path) as f:
        status_a = json.load(f)

    trace_path_b = handoff.create_context(
        "integration-task-002", "go-master-agent", parent_span_id=status_a["span_id"]
    )
    with open(trace_path_b) as f:
        trace_b = json.load(f)

    assert trace_b["parent_span_id"] == status_a["span_id"]

    # 6. Agente B completa
    status_path_b = handoff.finalize_status(
        "integration-task-002", "go-master-agent", "completed",
        "artifacts/final.json", trace_b["trace_id"], status_a["span_id"]
    )

    # 7. Validar consistencia cruzada
    cp.check_cross_consistency(trace_path_b, status_path_b)

    # 8. Liberar meta
    client.release_goal("goal-001", "completed", tokens_used=5000, time_used=300)
    final = client.get_active_goal("goal-001")
    assert final["status"] == "completed"
