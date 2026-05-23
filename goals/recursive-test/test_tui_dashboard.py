"""
---
artifact_id: "goals-recursive-test-test-tui-dashboard"
artifact_type: "unit_test"
version: "2.0.0"
canonical_path: "goals/recursive-test/test_tui_dashboard.py"
tier: 2
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Pruebas del dashboard TUI.
"""

import pytest
from goals.libs.registry_client import RegistryClient
from goals.scripts.tui_dashboard import build_dashboard


def test_build_dashboard_returns_layout(populated_registry):
    client = RegistryClient(populated_registry)
    layout = build_dashboard(client)
    assert layout is not None
    # El layout de rich tiene estructura interna
    assert hasattr(layout, "render")


def test_build_dashboard_empty(tmp_registry):
    client = RegistryClient(tmp_registry)
    layout = build_dashboard(client)
    assert layout is not None
