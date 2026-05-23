---
artifact_id: "goals-libs-registry-client"
artifact_type: "library"
version: "2.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
canonical_path: "goals/libs/registry_client.py"
tier: 2
immutable: false
language_lock: "python3"
prompt_hash: "sha256:registry-client-v2.0.0"
generated_at: "2026-05-22T06:20:00Z"
domain: "goals"
subdomain: "libs"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Cliente ligero para leer/escribir el registry.db sin exponer SQL a los agentes.
"""

import sqlite3
from pathlib import Path
from typing import Optional, List, Dict
from datetime import datetime, timezone

class RegistryClient:
    def __init__(self, db_path: str = "goals/registry.db"):
        self.db_path = Path(db_path)
        if not self.db_path.exists():
            raise FileNotFoundError(f"registry.db no encontrado en {db_path}. Ejecute init_registry.py primero.")

    def _connect(self) -> sqlite3.Connection:
        conn = sqlite3.connect(str(self.db_path))
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA journal_mode=WAL;")
        return conn

    def get_active_goal(self, goal_id: str) -> Optional[Dict]:
        with self._connect() as conn:
            row = conn.execute("SELECT * FROM goals WHERE goal_id = ?", (goal_id,)).fetchone()
            return dict(row) if row else None

    def list_goals_by_status(self, status: str) -> List[Dict]:
        with self._connect() as conn:
            rows = conn.execute("SELECT * FROM goals WHERE status = ? ORDER BY priority ASC", (status,)).fetchall()
            return [dict(r) for r in rows]

    def list_goals_for_agent(self, agent_name: str) -> List[Dict]:
        with self._connect() as conn:
            rows = conn.execute("SELECT * FROM goals WHERE assigned_agent = ?", (agent_name,)).fetchall()
            return [dict(r) for r in rows]

    def acquire_goal(self, goal_id: str, agent: str, expected_version: int, ttl_seconds: int = 3600) -> bool:
        now = datetime.now(timezone.utc).isoformat(timespec='seconds').replace('+00:00', 'Z')
        timeout = datetime.now(timezone.utc).isoformat(timespec='seconds').replace('+00:00', 'Z')
        with self._connect() as conn:
            conn.execute("""
                UPDATE goals
                SET status = 'active',
                    assigned_agent = ?,
                    heartbeat_at = ?,
                    lock_version = lock_version + 1
                WHERE goal_id = ?
                  AND lock_version = ?
                  AND status IN ('active','paused')
                  AND (assigned_agent IS NULL OR assigned_agent = ? OR heartbeat_at < ?)
            """, (agent, now, goal_id, expected_version, agent, timeout))
            return conn.total_changes > 0

    def release_goal(self, goal_id: str, new_status: str, tokens_used: int = 0, time_used: int = 0) -> bool:
        now = datetime.now(timezone.utc).isoformat(timespec='seconds').replace('+00:00', 'Z')
        with self._connect() as conn:
            conn.execute("""
                UPDATE goals
                SET status = ?,
                    tokens_used = tokens_used + ?,
                    time_used_seconds = time_used_seconds + ?,
                    updated_at = ?,
                    heartbeat_at = NULL
                WHERE goal_id = ?
            """, (new_status, tokens_used, time_used, now, goal_id))
            return conn.total_changes > 0


