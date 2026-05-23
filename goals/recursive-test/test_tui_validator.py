"""
---
artifact_id: "goals-recursive-test-test-tui-validator"
artifact_type: "unit_test"
version: "2.0.0"
canonical_path: "goals/recursive-test/test_tui_validator.py"
tier: 2
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Pruebas del menú TUI de validación.
"""

import pytest
import subprocess
from pathlib import Path
from goals.scripts.tui_validator import run_script


def test_run_script_success(tmp_path, monkeypatch):
    monkeypatch.setattr(subprocess, "run", lambda *a, **kw: type("R", (), {"returncode": 0, "stdout": "OK", "stderr": ""})())
    result = run_script("validate_registry.py", ["--db-path", str(tmp_path / "test.db")])
    assert result == 0


def test_run_script_failure(tmp_path, monkeypatch):
    monkeypatch.setattr(subprocess, "run", lambda *a, **kw: type("R", (), {"returncode": 1, "stdout": "", "stderr": "error"})())
    result = run_script("validate_registry.py")
    assert result == 1


def test_run_script_not_found():
    result = run_script("no-existe.py")
    assert result == 1
