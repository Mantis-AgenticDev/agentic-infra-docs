"""
---
artifact_id: "goals-recursive-test-test-init-registry"
artifact_type: "unit_test"
version: "2.0.0"
canonical_path: "goals/recursive-test/test_init_registry.py"
tier: 2
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Pruebas de inicialización del registry.db.
"""

import pytest
import sqlite3
from goals.scripts.init_registry import init_registry


def test_creates_tables_and_indexes(tmp_path):
    db_path = tmp_path / "registry.db"
    success = init_registry(str(db_path))
    assert success is True
    conn = sqlite3.connect(str(db_path))
    tables = conn.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall()
    table_names = [t[0] for t in tables]
    assert "goals" in table_names
    cols = [c[1] for c in conn.execute("PRAGMA table_info(goals)")]
    for required in ["goal_id", "objective", "status", "lock_version", "heartbeat_at"]:
        assert required in cols
    indexes = conn.execute("SELECT name FROM sqlite_master WHERE type='index'").fetchall()
    index_names = [i[0] for i in indexes]
    assert len(index_names) >= 3
    conn.close()


def test_idempotent(tmp_path):
    db_path = tmp_path / "registry.db"
    assert init_registry(str(db_path)) is True
    assert init_registry(str(db_path)) is True
