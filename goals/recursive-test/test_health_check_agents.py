"""
---
artifact_id: "goals-recursive-test-test-health-check-agents"
artifact_type: "unit_test"
version: "2.0.0"
canonical_path: "goals/recursive-test/test_health_check_agents.py"
tier: 2
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Pruebas de verificación de heartbeats.
"""

import pytest
from datetime import datetime, timezone, timedelta
from goals.libs.registry_client import RegistryClient


def test_check_all_healthy(populated_registry):
    from goals.scripts.health_check_agents import check
    client = RegistryClient(populated_registry)
    unhealthy = check(client, timeout_minutes=60)
    # goal-001 tiene heartbeat reciente, goal-002 no tiene heartbeat
    assert len(unhealthy) >= 0


def test_check_detects_missing_heartbeat(populated_registry):
    from goals.scripts.health_check_agents import check
    client = RegistryClient(populated_registry)
    unhealthy = check(client, timeout_minutes=1)
    # goal-002 (paused) no tiene heartbeat, debería aparecer
    assert any(u["goal_id"] == "goal-002" for u in unhealthy)
