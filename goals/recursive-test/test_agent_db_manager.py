"""
---
artifact_id: "goals-recursive-test-test-agent-db-manager"
artifact_type: "unit_test"
version: "2.0.0"
canonical_path: "goals/recursive-test/test_agent_db_manager.py"
tier: 2
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Pruebas del gestor Singleton de base de datos de agente.
"""

import pytest
from pathlib import Path
from goals.libs.agent_db_manager import AgentDBManager


def test_singleton_rejects_wrong_agent(tmp_path):
    agent_dir = tmp_path / "programming"
    agent_dir.mkdir(parents=True)
    db_file = agent_dir / "agent-A.db"
    db_file.touch()
    # Esto debería fallar porque el archivo se llama agent-A.db pero el agente es agent-B
    with pytest.raises(PermissionError):
        AgentDBManager("agent-B", db_dir=str(tmp_path), domain="programming")


def test_log_action_persists(tmp_path):
    agent_dir = tmp_path / "runtime"
    agent_dir.mkdir(parents=True)
    from goals.scripts.init_agent_db import init_agent_db
    init_agent_db("test-agent", "runtime", str(tmp_path))
    mgr = AgentDBManager("test-agent", db_dir=str(tmp_path), domain="runtime")
    mgr.log_action("step_1", "inicio de prueba")
    actions = mgr.get_recent_actions(limit=10)
    assert len(actions) >= 1
    assert actions[0]["action"] == "step_1"


def test_update_goal_state(tmp_path):
    agent_dir = tmp_path / "runtime"
    agent_dir.mkdir(parents=True)
    from goals.scripts.init_agent_db import init_agent_db
    init_agent_db("test-agent", "runtime", str(tmp_path))
    mgr = AgentDBManager("test-agent", db_dir=str(tmp_path), domain="runtime")
    mgr.update_goal_state("g-1", "active", tokens_used=500, time_used=30)
    state = mgr.get_goal_state("g-1")
    assert state is not None
    assert state["status"] == "active"
    assert state["tokens_used"] == 500


def test_update_metric(tmp_path):
    agent_dir = tmp_path / "runtime"
    agent_dir.mkdir(parents=True)
    from goals.scripts.init_agent_db import init_agent_db
    init_agent_db("test-agent", "runtime", str(tmp_path))
    mgr = AgentDBManager("test-agent", db_dir=str(tmp_path), domain="runtime")
    mgr.update_metric("success_rate", 0.95)
    metrics = mgr.get_metrics()
    assert "success_rate" in metrics
    assert metrics["success_rate"] == 0.95


def test_get_recent_actions_empty(tmp_path):
    agent_dir = tmp_path / "runtime"
    agent_dir.mkdir(parents=True)
    from goals.scripts.init_agent_db import init_agent_db
    init_agent_db("test-agent", "runtime", str(tmp_path))
    mgr = AgentDBManager("test-agent", db_dir=str(tmp_path), domain="runtime")
    actions = mgr.get_recent_actions(limit=5)
    assert actions == []
