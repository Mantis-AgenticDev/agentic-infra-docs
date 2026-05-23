"""
---
artifact_id: "goals-recursive-test-test-team-orchestrator"
artifact_type: "unit_test"
version: "2.0.0"
canonical_path: "goals/recursive-test/test_team_orchestrator.py"
tier: 2
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Pruebas del orquestador de equipos.
"""

import pytest
from goals.libs.registry_client import RegistryClient
from goals.libs.handoff_package import HandoffPackage
from goals.scripts.team_orchestrator import TeamOrchestrator


def test_get_team_goal(populated_registry):
    client = RegistryClient(populated_registry)
    handoff = HandoffPackage()
    orch = TeamOrchestrator(client, handoff)
    goal = orch.get_team_goal("goal-005")
    assert goal is not None
    assert goal["assigned_team"] == "bash-master-agent,go-master-agent"
    assert goal["coordination_strategy"] == "sequential"


def test_split_goal_sequential(populated_registry):
    client = RegistryClient(populated_registry)
    handoff = HandoffPackage()
    orch = TeamOrchestrator(client, handoff)
    goal = orch.get_team_goal("goal-005")
    sub_goals = orch.split_goal(goal)
    assert len(sub_goals) == 2
    assert sub_goals[0]["assigned_agent"] == "bash-master-agent"
    assert sub_goals[1]["assigned_agent"] == "go-master-agent"
    assert sub_goals[1]["dependencies"] == [sub_goals[0]["sub_goal_id"]]


def test_get_team_goal_not_team(populated_registry):
    client = RegistryClient(populated_registry)
    handoff = HandoffPackage()
    orch = TeamOrchestrator(client, handoff)
    goal = orch.get_team_goal("goal-001")
    assert goal is not None
    assert goal.get("assigned_team") is None
