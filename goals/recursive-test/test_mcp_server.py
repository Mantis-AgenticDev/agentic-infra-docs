"""
---
artifact_id: "goals-recursive-test-test-mcp-server"
artifact_type: "unit_test"
version: "2.0.0"
canonical_path: "goals/recursive-test/test_mcp_server.py"
tier: 2
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Pruebas del servidor MCP.
"""

import pytest
import json
from pathlib import Path
from goals.scripts.mcp_server import handle_request


def test_handle_get_active_goal(populated_registry, monkeypatch):
    # Mockear RegistryClient en mcp_server
    monkeypatch.setattr(
        "goals.scripts.mcp_server.RegistryClient",
        lambda: type("MockReg", (), {
            "get_active_goal": lambda self, gid: {
                "goal_id": gid, "objective": "Test", "status": "active"
            }
        })()
    )
    resp = handle_request({"method": "get_active_goal", "params": {"goal_id": "goal-001"}})
    assert "result" in resp
    assert resp["result"]["goal_id"] == "goal-001"


def test_handle_unknown_method():
    resp = handle_request({"method": "metodo_inexistente"})
    assert "error" in resp


def test_handle_list_goals(populated_registry, monkeypatch):
    monkeypatch.setattr(
        "goals.scripts.mcp_server.RegistryClient",
        lambda: type("MockReg", (), {
            "list_goals_by_status": lambda self, status: [{"goal_id": "g1", "status": status}]
        })()
    )
    resp = handle_request({"method": "list_goals", "params": {"status": "active"}})
    assert "result" in resp
    assert len(resp["result"]) >= 1
