"""
---
artifact_id: "goals-recursive-test-test-rotate-agent-db"
artifact_type: "unit_test"
version: "2.0.0"
canonical_path: "goals/recursive-test/test_rotate_agent_db.py"
tier: 2
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Pruebas de rotación de bases de datos de agentes.
"""

import pytest
import time
from pathlib import Path
from goals.scripts.rotate_agent_db import rotate, is_agent_active
from goals.libs.registry_client import RegistryClient


def test_is_agent_active_no_active_goals(tmp_path, monkeypatch):
    # Mockear RegistryClient para devolver lista vacía
    monkeypatch.setattr(
        "goals.scripts.rotate_agent_db.RegistryClient",
        lambda *a, **kw: type("MockReg", (), {"list_goals_for_agent": lambda self, agent: []})()
    )
    assert is_agent_active(None, "test-agent") is False


def test_rotate_dry_run(tmp_path):
    agent_dir = tmp_path / "programming"
    agent_dir.mkdir(parents=True)
    for i in range(7):
        db = agent_dir / f"bash-master-agent-20260522{i:02d}0000.db"
        db.touch()
    rotate(str(tmp_path), max_keep=5, dry_run=True)
    # En dry-run no se borra nada
    remaining = list(agent_dir.glob("*.db"))
    assert len(remaining) == 7


def test_rotate_removes_old(tmp_path):
    agent_dir = tmp_path / "programming"
    agent_dir.mkdir(parents=True)
    for i in range(7):
        db = agent_dir / f"bash-master-agent-20260522{i:02d}0000.db"
        db.touch()
    rotate(str(tmp_path), max_keep=5, dry_run=False)
    remaining = list(agent_dir.glob("*.db"))
    assert len(remaining) == 5
