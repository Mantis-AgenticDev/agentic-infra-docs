"""
---
artifact_id: "goals-recursive-test-test-schema-validation"
artifact_type: "unit_test"
version: "2.0.0"
canonical_path: "goals/recursive-test/test_schema_validation.py"
tier: 2
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Pruebas de validación de schemas JSON.
"""

import pytest
import json
import jsonschema
from pathlib import Path


SCHEMAS_DIR = Path(__file__).resolve().parent.parent / "schemas"


def test_status_schema_valid(sample_status):
    schema_path = SCHEMAS_DIR / "status.schema.json"
    with open(schema_path) as f:
        schema = json.load(f)
    jsonschema.validate(instance=sample_status, schema=schema)


def test_status_schema_invalid_status():
    schema_path = SCHEMAS_DIR / "status.schema.json"
    with open(schema_path) as f:
        schema = json.load(f)
    bad = {
        "agent_id": "a", "trace_id": "550e8400-e29b-41d4-a716-446655440000",
        "span_id": "550e8400-e29b-41d4-a716-446655440001", "status": "unknown",
        "output_ref": "o", "timestamp_completed": "2026-01-01T00:00:00Z",
        "a2a_contract_version": "1.0"
    }
    with pytest.raises(jsonschema.ValidationError):
        jsonschema.validate(instance=bad, schema=schema)


def test_trace_schema_valid(sample_trace):
    schema_path = SCHEMAS_DIR / "trace.schema.json"
    with open(schema_path) as f:
        schema = json.load(f)
    jsonschema.validate(instance=sample_trace, schema=schema)


def test_trace_schema_missing_required():
    schema_path = SCHEMAS_DIR / "trace.schema.json"
    with open(schema_path) as f:
        schema = json.load(f)
    bad = {"current_agent": "a", "task_id": "t", "timestamp_injected": "2026-01-01T00:00:00Z"}
    with pytest.raises(jsonschema.ValidationError):
        jsonschema.validate(instance=bad, schema=schema)
