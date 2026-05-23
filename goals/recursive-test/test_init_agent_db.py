"""
---
artifact_id: "goals-recursive-test-test-init-agent-db"
artifact_type: "unit_test"
version: "2.0.0"
canonical_path: "goals/recursive-test/test_init_agent_db.py"
tier: 2
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Pruebas de inicialización de base de datos de agente.
"""

import pytest
import sqlite3
from goals.scripts.init_agent_db import init_agent_db


def test_creates_tables(tmp_path):
    db_path = init_agent_db("test-agent", "runtime", str(tmp_path))
    assert db_path is not None
    conn = sqlite3.connect(db_path)
    tables = [r[0] for r in conn.execute("SELECT name FROM sqlite_master WHERE type='table'")]
    for required in ["goal_state", "action_log", "metrics"]:
        assert required in tables
    conn.close()


def test_idempotent(tmp_path):
    p1 = init_agent_db("test-agent", "runtime", str(tmp_path))
    p2 = init_agent_db("test-agent", "runtime", str(tmp_path))
    assert p1 == p2


def test_creates_in_correct_domain_folder(tmp_path):
    db_path = init_agent_db("bash-master-agent", "programming", str(tmp_path))
    assert "programming" in db_path
    assert "bash-master-agent.db" in db_path
