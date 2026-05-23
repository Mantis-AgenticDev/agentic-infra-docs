---
artifact_id: "goals-libs-handoff-package"
artifact_type: "library"
version: "2.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
canonical_path: "goals/libs/handoff_package.py"
tier: 2
immutable: false
language_lock: "python3"
prompt_hash: "sha256:handoff-package-v2.0.0"
generated_at: "2026-05-22T06:55:00Z"
domain: "goals"
subdomain: "libs"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Empaqueta el contexto para handoffs A2A (trace + status + contexto mínimo).
"""

import json
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

class HandoffPackage:
    def __init__(self, task_dir_base: str = "goals/tasks"):
        self.task_dir_base = Path(task_dir_base)

    def create_context(self, task_id: str, current_agent: str, parent_span_id: Optional[str] = None) -> str:
        """Crea el archivo trace.json en context/ de la tarea."""
        context_dir = self.task_dir_base / task_id / "context"
        context_dir.mkdir(parents=True, exist_ok=True)
        trace = {
            "trace_id": str(uuid.uuid4()),
            "parent_span_id": parent_span_id,
            "current_agent": current_agent,
            "task_id": task_id,
            "timestamp_injected": datetime.now(timezone.utc).isoformat()
        }
        trace_path = context_dir / "trace.json"
        with open(trace_path, "w") as f:
            json.dump(trace, f, indent=2)
        return str(trace_path)

    def finalize_status(self, task_id: str, agent_id: str, status: str, output_ref: str, trace_id: str, parent_span_id: Optional[str], next_agent_hint: Optional[str] = None) -> str:
        """Escribe el status.json final del agente."""
        artifacts_dir = self.task_dir_base / task_id / "artifacts" / agent_id
        artifacts_dir.mkdir(parents=True, exist_ok=True)
        span_id = str(uuid.uuid4())
        status_data = {
            "agent_id": agent_id,
            "trace_id": trace_id,
            "span_id": span_id,
            "parent_span_id": parent_span_id,
            "status": status,
            "output_ref": output_ref,
            "next_agent_hint": next_agent_hint or "",
            "timestamp_completed": datetime.now(timezone.utc).isoformat(),
            "a2a_contract_version": "1.0"
        }
        status_path = artifacts_dir / "status.json"
        with open(status_path, "w") as f:
            json.dump(status_data, f, indent=2)
        return str(status_path)
