"""
---
artifact_id: "goals-recursive-test-test-log-reader"
artifact_type: "unit_test"
version: "2.0.0"
canonical_path: "goals/recursive-test/test_log_reader.py"
tier: 2
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Pruebas del lector de logs.
"""

import pytest
from pathlib import Path
from goals.libs.log_reader import LogReader


@pytest.fixture
def log_dir(tmp_path):
    logs = tmp_path / "logs"
    logs.mkdir()
    (logs / "app.log").write_text("L1 inicio\nL2 proceso\nL3 fin\n")
    (logs / "error.log").write_text("E1 timeout\nE2 conexión\n")
    return str(logs)


def test_read_latest(log_dir):
    reader = LogReader(log_dir=log_dir)
    lines = reader.read_latest("app.log", lines=2)
    assert len(lines) == 2
    assert "L3" in lines[-1]


def test_read_latest_more_than_file(log_dir):
    reader = LogReader(log_dir=log_dir)
    lines = reader.read_latest("app.log", lines=10)
    assert len(lines) == 3


def test_read_latest_nonexistent(log_dir):
    reader = LogReader(log_dir=log_dir)
    lines = reader.read_latest("no-existe.log")
    assert lines == []


def test_search_specific_file(log_dir):
    reader = LogReader(log_dir=log_dir)
    results = reader.search("timeout", log_name="error.log")
    assert len(results) == 1
    assert "timeout" in results[0]


def test_search_all_files(log_dir):
    reader = LogReader(log_dir=log_dir)
    results = reader.search("inicio")
    assert len(results) == 1


def test_search_no_match(log_dir):
    reader = LogReader(log_dir=log_dir)
    results = reader.search("inexistente")
    assert results == []
