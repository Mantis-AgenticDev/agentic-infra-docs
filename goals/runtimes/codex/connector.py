#!/usr/bin/env python3
"""
---
artifact_id: "runtimes-codex-connector"
artifact_type: "runtime_connector"
version: "2.0.0"
canonical_path: "runtimes/codex/connector.py"
tier: 2
immutable: false
language_lock: "python3"
prompt_hash: "sha256:codex-connector-v2.0.0"
generated_at: "2026-05-22T11:15:00Z"
domain: "runtimes"
subdomain: "codex"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Conector entre Codex CLI y el ecosistema GOALS MANTIS.
"""

import sys
from pathlib import Path
sys.path.append(str(Path(__file__).resolve().parent.parent.parent / "goals"))
from libs.registry_client import RegistryClient
from libs.prompt_builder import PromptBuilder
from libs.handoff_package import HandoffPackage

class CodexConnector:
    def __init__(self):
        self.registry = RegistryClient()
        self.builder = PromptBuilder(self.registry)
        self.handoff = HandoffPackage()

    def get_task_prompt(self, goal_id: str, agent: str) -> str:
        return self.builder.build_continuation_prompt(goal_id, agent)

    def finalize_task(self, task_id: str, agent: str, success: bool, output: str):
        status = "completed" if success else "failed"
        self.handoff.finalize_status(task_id, agent, status, output, "trace-id-placeholder", None)
        self.registry.release_goal(task_id, status)
