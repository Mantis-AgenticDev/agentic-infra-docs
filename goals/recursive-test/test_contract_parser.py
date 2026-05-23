"""
---
artifact_id: "goals-recursive-test-test-contract-parser"
artifact_type: "unit_test"
version: "2.0.0"
canonical_path: "goals/recursive-test/test_contract_parser.py"
tier: 2
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Pruebas del validador de contratos A2A (C9).
"""

import pytest
import json
from pathlib import Path
from goals.libs.contract_parser import ContractParser


def test_validate_status_valid(tmp_path, sample_status):
    status_path = tmp_path / "status.json"
    status_path.write_text(json.dumps(sample_status))
    cp = ContractParser(schemas_dir=str(Path(__file__).resolve().parent.parent / "schemas"))
    assert cp.validate_status(str(status_path)) is True


def test_validate_status_missing_field(tmp_path):
    bad = {"agent_id": "a", "trace_id": "t", "span_id": "s", "status": "completed"}
    status_path = tmp_path / "status.json"
    status_path.write_text(json.dumps(bad))
    cp = ContractParser(schemas_dir=str(Path(__file__).resolve().parent.parent / "schemas"))
    with pytest.raises(Exception):
        cp.validate_status(str(status_path))


def test_validate_trace_valid(tmp_path, sample_trace):
    trace_path = tmp_path / "trace.json"
    trace_path.write_text(json.dumps(sample_trace))
    cp = ContractParser(schemas_dir=str(Path(__file__).resolve().parent.parent / "schemas"))
    assert cp.validate_trace(str(trace_path)) is True


def test_check_cross_consistency_match(tmp_path, sample_trace, sample_status):
    trace_path = tmp_path / "trace.json"
    status_path = tmp_path / "status.json"
    sample_status["trace_id"] = sample_trace["trace_id"]
    trace_path.write_text(json.dumps(sample_trace))
    status_path.write_text(json.dumps(sample_status))
    cp = ContractParser(schemas_dir=str(Path(__file__).resolve().parent.parent / "schemas"))
    assert cp.check_cross_consistency(str(trace_path), str(status_path)) is True


def test_check_cross_consistency_mismatch(tmp_path, sample_trace, sample_status):
    trace_path = tmp_path / "trace.json"
    status_path = tmp_path / "status.json"
    status_path.write_text(json.dumps(sample_status))
    trace_path.write_text(json.dumps(sample_trace))
    cp = ContractParser(schemas_dir=str(Path(__file__).resolve().parent.parent / "schemas"))
    with pytest.raises(ValueError):
        cp.check_cross_consistency(str(trace_path), str(status_path))
