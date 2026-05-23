"""
---
artifact_id: "goals-recursive-test-test-validate-registry"
artifact_type: "unit_test"
version: "2.0.0"
canonical_path: "goals/recursive-test/test_validate_registry.py"
tier: 2
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Pruebas de validación de integridad del registry.db.
"""

import pytest
from goals.scripts.validate_registry import validate
from goals.libs.registry_client import RegistryClient


def test_valid_registry(populated_registry):
    client = RegistryClient(populated_registry)
    errors = validate(client)
    assert errors == []


def test_valid_registry_empty(tmp_registry):
    client = RegistryClient(tmp_registry)
    errors = validate(client)
    assert errors == []
