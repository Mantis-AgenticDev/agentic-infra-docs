"""
---
artifact_id: "goals-recursive-test-test-handoff-package"
artifact_type: "unit_test"
version: "2.0.0"
canonical_path: "goals/recursive-test/test_handoff_package.py"
tier: 2
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Pruebas del empaquetador A2A (HandoffPackage).
"""

import pytest
import json
from pathlib import Path
from goals.libs.handoff_package import HandoffPackage


def test_create_context(tmp_path):
    pkg = HandoffPackage(task_dir_base=str(tmp_path))
    trace_path = pkg.create_context("task-001", "bash-master-agent")
    assert Path(trace_path).exists()
    with open(trace_path) as f:
        data = json.load(f)
    assert data["current_agent"] == "bash-master-agent"
    assert data["task_id"] == "task-001"
    assert "trace_id" in data


def test_create_context_with_parent(tmp_path):
    pkg = HandoffPackage(task_dir_base=str(tmp_path))
    trace_path = pkg.create_context("task-002", "go-master-agent", parent_span_id="span-abc")
    with open(trace_path) as f:
        data = json.load(f)
    assert data["parent_span_id"] == "span-abc"


def test_finalize_status(tmp_path):
    pkg = HandoffPackage(task_dir_base=str(tmp_path))
    trace_path = pkg.create_context("task-003", "bash-master-agent")
    with open(trace_path) as f:
        trace = json.load(f)
    status_path = pkg.finalize_status(
        "task-003", "bash-master-agent", "completed",
        "artifacts/output.txt", trace["trace_id"], None, "go-master-agent"
    )
    assert Path(status_path).exists()
    with open(status_path) as f:
        data = json.load(f)
    assert data["status"] == "completed"
    assert data["agent_id"] == "bash-master-agent"
    assert data["a2a_contract_version"] == "1.0"


def test_finalize_status_failed(tmp_path):
    pkg = HandoffPackage(task_dir_base=str(tmp_path))
    trace_path = pkg.create_context("task-004", "test-agent")
    with open(trace_path) as f:
        trace = json.load(f)
    status_path = pkg.finalize_status(
        "task-004", "test-agent", "failed",
        "artifacts/error.log", trace["trace_id"], None
    )
    with open(status_path) as f:
        data = json.load(f)
    assert data["status"] == "failed"
