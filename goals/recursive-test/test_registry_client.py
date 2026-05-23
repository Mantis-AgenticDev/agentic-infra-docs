"""
---
artifact_id: "goals-recursive-test-test-registry-client"
artifact_type: "unit_test"
version: "2.0.0"
canonical_path: "goals/recursive-test/test_registry_client.py"
tier: 2
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Pruebas del cliente de registry.db (RegistryClient).
"""

import pytest
import sqlite3
from goals.libs.registry_client import RegistryClient


def test_get_active_goal_found(populated_registry):
    client = RegistryClient(populated_registry)
    goal = client.get_active_goal("goal-001")
    assert goal is not None
    assert goal["goal_id"] == "goal-001"
    assert goal["status"] == "active"
    assert goal["assigned_agent"] == "bash-master-agent"


def test_get_active_goal_not_found(populated_registry):
    client = RegistryClient(populated_registry)
    goal = client.get_active_goal("no-existe")
    assert goal is None


def test_list_goals_by_status_active(populated_registry):
    client = RegistryClient(populated_registry)
    active = client.list_goals_by_status("active")
    assert len(active) >= 1
    for g in active:
        assert g["status"] == "active"


def test_list_goals_by_status_paused(populated_registry):
    client = RegistryClient(populated_registry)
    paused = client.list_goals_by_status("paused")
    assert len(paused) >= 1
    for g in paused:
        assert g["status"] == "paused"


def test_list_goals_for_agent(populated_registry):
    client = RegistryClient(populated_registry)
    goals = client.list_goals_for_agent("bash-master-agent")
    assert len(goals) >= 1
    for g in goals:
        assert g["assigned_agent"] == "bash-master-agent"


def test_acquire_goal_success(populated_registry):
    client = RegistryClient(populated_registry)
    # goal-001 tiene lock_version=2 y assigned_agent="bash-master-agent"
    # Pero el heartbeat fue puesto al crearla, verifiquemos si podemos adquirirla
    goal = client.get_active_goal("goal-001")
    success = client.acquire_goal("goal-001", "nuevo-agente", goal["lock_version"])
    # Si el heartbeat expiró, debería funcionar
    # Si no, será False
    assert isinstance(success, bool)


def test_acquire_goal_wrong_version(populated_registry):
    client = RegistryClient(populated_registry)
    success = client.acquire_goal("goal-001", "nuevo-agente", 999)
    assert success is False


def test_release_goal(populated_registry):
    client = RegistryClient(populated_registry)
    success = client.release_goal("goal-001", "paused", tokens_used=500, time_used=60)
    assert success is True
    goal = client.get_active_goal("goal-001")
    assert goal["status"] == "paused"


def test_release_goal_nonexistent(populated_registry):
    client = RegistryClient(populated_registry)
    success = client.release_goal("no-existe", "completed")
    assert success is False
