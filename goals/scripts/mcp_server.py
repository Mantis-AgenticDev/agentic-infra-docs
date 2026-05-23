#!/usr/bin/env python3
"""
---
artifact_id: "goals-mcp-server-py"
artifact_type: "mcp_server"
version: "2.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
canonical_path: "goals/scripts/mcp_server.py"
tier: 2
immutable: false
language_lock: "python3"
prompt_hash: "sha256:mcp-server-v2.0.0"
generated_at: "2026-05-22T09:50:00Z"
domain: "goals"
subdomain: "scripts"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Servidor MCP básico para exponer el registry.db a sistemas externos.
"""

import sys
import json
from pathlib import Path
sys.path.append(str(Path(__file__).resolve().parent.parent))
from libs.registry_client import RegistryClient

def handle_request(request: dict) -> dict:
    method = request.get("method")
    params = request.get("params", {})
    registry = RegistryClient()

    if method == "get_active_goal":
        goal = registry.get_active_goal(params["goal_id"])
        return {"result": goal}
    elif method == "list_goals":
        goals = registry.list_goals_by_status(params.get("status", "active"))
        return {"result": goals}
    elif method == "acquire_goal":
        ok = registry.acquire_goal(params["goal_id"], params["agent"], params["expected_version"])
        return {"result": ok}
    elif method == "release_goal":
        ok = registry.release_goal(params["goal_id"], params["status"], params.get("tokens", 0), params.get("time", 0))
        return {"result": ok}
    else:
        return {"error": f"Método desconocido: {method}"}

if __name__ == "__main__":
    # Modo stdin/stdout simple para MCP
    for line in sys.stdin:
        try:
            req = json.loads(line.strip())
            resp = handle_request(req)
            print(json.dumps(resp), flush=True)
        except Exception as e:
            print(json.dumps({"error": str(e)}), flush=True)
