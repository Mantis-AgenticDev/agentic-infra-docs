---
artifact_id: "hello-world-agent"
artifact_type: "agent_definition"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
canonical_path: "goals/templates/hello-world-agent.md"
tier: 2
immutable: false
requires_human_approval_for_changes: false
audience: ["developers", "human-architects"]
language_lock: "pt-BR"
prompt_hash: "sha256:hello-world-agent-v1.0.0"
generated_at: "2026-05-22T10:45:00Z"
domain: "templates"
subdomain: "examples"
agent_role: "hello-world-agent"
agent_specialty: "ejemplo"
skills: ["example", "template"]
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---

# Hello World Agent — Plantilla de Ejemplo

Este agente demuestra la integración mínima con el ecosistema `goals/`.

## Inicialización

```python
from goals.libs.registry_client import RegistryClient
from goals.libs.agent_db_manager import AgentDBManager
from goals.libs.handoff_package import HandoffPackage

registry = RegistryClient()
db = AgentDBManager("hello-world-agent", domain="runtime")
handoff = HandoffPackage()

# Leer meta activa
goal = registry.get_active_goal("goal-hello")
db.log_action("goal_acquired", f"Meta {goal['goal_id']} adquirida")

# Trabajar...
db.update_goal_state(goal['goal_id'], "completed", tokens_used=100, time_used=60)

# Finalizar con handoff A2A
handoff.finalize_status("task-hello", "hello-world-agent", "completed",
                        "artifacts/hello.txt", trace_id=goal['goal_id'],
                        parent_span_id=None)
registry.release_goal(goal['goal_id'], "completed")
```

## Validación

```bash
python3 goals/scripts/check_a2a_contract.py --task-id task-hello --agent hello-world-agent --json
```
