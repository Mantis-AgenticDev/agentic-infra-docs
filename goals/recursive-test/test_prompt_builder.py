"""
---
artifact_id: "goals-recursive-test-test-prompt-builder"
artifact_type: "unit_test"
version: "2.0.0"
canonical_path: "goals/recursive-test/test_prompt_builder.py"
tier: 2
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Pruebas del constructor de prompts.
"""

import pytest
from goals.libs.prompt_builder import PromptBuilder
from goals.libs.registry_client import RegistryClient


def test_build_continuation_prompt(populated_registry):
    client = RegistryClient(populated_registry)
    builder = PromptBuilder(client)
    prompt = builder.build_continuation_prompt("goal-001", "bash-master-agent")
    assert "Meta 1" in prompt
    assert "goal-001" in prompt
    assert "tokens" in prompt.lower()


def test_build_continuation_prompt_nonexistent(populated_registry):
    client = RegistryClient(populated_registry)
    builder = PromptBuilder(client)
    prompt = builder.build_continuation_prompt("no-existe", "test-agent")
    assert "Error" in prompt


def test_build_handoff_prompt(populated_registry):
    client = RegistryClient(populated_registry)
    builder = PromptBuilder(client)
    prompt = builder.build_handoff_prompt("goal-001", "bash-master-agent", "go-master-agent")
    assert "go-master-agent" in prompt
    assert "bash-master-agent" in prompt
    assert "Meta 1" in prompt


def test_build_handoff_prompt_nonexistent(populated_registry):
    client = RegistryClient(populated_registry)
    builder = PromptBuilder(client)
    prompt = builder.build_handoff_prompt("no-existe", "a", "b")
    assert "Error" in prompt
