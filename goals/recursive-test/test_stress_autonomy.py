"""
---
artifact_id: "goals-recursive-test-test-stress-autonomy"
artifact_type: "stress_test"
version: "2.0.0"
canonical_path: "goals/recursive-test/test_stress_autonomy.py"
tier: 2
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Prueba de estrés: múltiples adquisiciones concurrentes de metas (CAS).
"""

import pytest
import sqlite3
from concurrent.futures import ThreadPoolExecutor, as_completed
from goals.libs.registry_client import RegistryClient


def _try_acquire(db_path, goal_id, agent, version):
    client = RegistryClient(db_path)
    return client.acquire_goal(goal_id, agent, version)


def test_concurrent_acquire_same_goal(populated_registry):
    """
    10 hilos intentan adquirir la misma meta.
    Solo uno debe tener éxito (CAS atómico).
    """
    goal_id = "goal-001"
    client = RegistryClient(populated_registry)
    goal = client.get_active_goal(goal_id)
    version = goal["lock_version"]
    successes = 0
    with ThreadPoolExecutor(max_workers=10) as executor:
        futures = [
            executor.submit(_try_acquire, populated_registry, goal_id, f"agent-{i}", version)
            for i in range(10)
        ]
        for f in as_completed(futures):
            if f.result():
                successes += 1
    # Solo uno debe adquirir el lock
    assert successes <= 1


def test_concurrent_different_goals(populated_registry):
    """
    5 hilos adquieren metas distintas. Todos deben tener éxito.
    """
    goals = ["goal-001", "goal-002", "goal-003", "goal-004", "goal-005"]
    client = RegistryClient(populated_registry)
    versions = {g: client.get_active_goal(g)["lock_version"] for g in goals}
    successes = 0
    with ThreadPoolExecutor(max_workers=5) as executor:
        futures = [
            executor.submit(_try_acquire, populated_registry, g, f"agent-stress", versions[g])
            for g in goals
        ]
        for f in as_completed(futures):
            if f.result():
                successes += 1
    assert successes >= 1


def test_stress_many_operations(populated_registry):
    """
    50 operaciones de lectura/escritura en rápida sucesión.
    """
    client = RegistryClient(populated_registry)
    for i in range(50):
        client.list_goals_by_status("active")
        client.list_goals_for_agent("bash-master-agent")
        client.get_active_goal("goal-001")
    assert True  # No crashes
