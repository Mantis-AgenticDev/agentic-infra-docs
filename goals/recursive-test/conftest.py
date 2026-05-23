"""
---
artifact_id: "goals-recursive-test-conftest"
artifact_type: "pytest_fixtures"
version: "2.0.0"
canonical_path: "goals/recursive-test/conftest.py"
tier: 2
language_lock: "python3"
prompt_hash: "sha256:conftest-v2.0.0"
generated_at: "2026-05-23T11:10:00Z"
domain: "goals"
subdomain: "recursive-test"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Fixtures comunes con los esquemas REALES de registry.db y agent-db.
"""

import sys, json, sqlite3, uuid, tempfile
from pathlib import Path
from datetime import datetime, timezone, timedelta
from typing import Dict, Generator
from unittest.mock import MagicMock, patch

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

# ---------------------------------------------------------------------------
# ESQUEMAS REALES
# ---------------------------------------------------------------------------
REGISTRY_SCHEMA = """
CREATE TABLE IF NOT EXISTS goals (
    goal_id           TEXT PRIMARY KEY NOT NULL,
    objective         TEXT NOT NULL,
    assigned_agent    TEXT,
    assigned_team     TEXT,
    coordination_strategy TEXT CHECK(coordination_strategy IN ('sequential','parallel','pipeline',NULL)),
    provider          TEXT,
    status            TEXT NOT NULL CHECK(status IN ('active','paused','budget_limited','complete')),
    priority          INTEGER DEFAULT 5,
    token_budget      INTEGER,
    tokens_used       INTEGER DEFAULT 0,
    time_used_seconds INTEGER DEFAULT 0,
    created_at        TEXT NOT NULL,
    updated_at        TEXT NOT NULL,
    next_wakeup       TEXT,
    lock_version      INTEGER DEFAULT 0,
    heartbeat_at      TEXT,
    metrics_json      TEXT DEFAULT '{}'
);
CREATE INDEX IF NOT EXISTS idx_goals_status ON goals(status);
CREATE INDEX IF NOT EXISTS idx_goals_assigned_agent ON goals(assigned_agent);
CREATE INDEX IF NOT EXISTS idx_goals_next_wakeup ON goals(next_wakeup);
"""

AGENT_DB_SCHEMA = """
CREATE TABLE IF NOT EXISTS goal_state (
    goal_id TEXT PRIMARY KEY,
    objective TEXT,
    status TEXT,
    tokens_used INTEGER DEFAULT 0,
    time_used_seconds INTEGER DEFAULT 0,
    last_updated TEXT
);
CREATE TABLE IF NOT EXISTS action_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TEXT NOT NULL,
    action TEXT NOT NULL,
    details TEXT
);
CREATE TABLE IF NOT EXISTS metrics (
    metric_name TEXT PRIMARY KEY,
    metric_value REAL,
    updated_at TEXT
);
"""

# ---------------------------------------------------------------------------
# FIXTURES DE BASE DE DATOS
# ---------------------------------------------------------------------------
@pytest.fixture
def tmp_registry() -> Generator[sqlite3.Connection, None, None]:
    conn = sqlite3.connect(":memory:")
    conn.execute("PRAGMA journal_mode=WAL;")
    conn.executescript(REGISTRY_SCHEMA)
    conn.commit()
    yield conn
    conn.close()

@pytest.fixture
def tmp_agent_db() -> Generator[sqlite3.Connection, None, None]:
    conn = sqlite3.connect(":memory:")
    conn.execute("PRAGMA journal_mode=WAL;")
    conn.executescript(AGENT_DB_SCHEMA)
    conn.commit()
    yield conn
    conn.close()

@pytest.fixture
def populated_registry(tmp_registry: sqlite3.Connection) -> sqlite3.Connection:
    now = datetime.now(timezone.utc).isoformat()
    goals = [
        ("goal-001", "Meta 1", "bash-master-agent", None, None, "deepseek", "active", 3, 50000, 10000, 300, now, now, None, 2, now, '{}'),
        ("goal-002", "Meta 2", "go-master-agent", None, None, "claude", "paused", 5, 200000, 0, 0, now, now, (datetime.now(timezone.utc)+timedelta(hours=5)).isoformat(), 1, None, '{}'),
        ("goal-003", "Meta 3", None, None, None, "gemini", "budget_limited", 4, 10000, 10000, 600, now, now, None, 3, None, '{}'),
        ("goal-004", "Meta 4", "python-master-agent", None, None, "qwen", "complete", 2, 100000, 45000, 1800, now, now, None, 5, None, '{}'),
        ("goal-005", "Meta equipo", None, "bash-master-agent,go-master-agent", "sequential", "deepseek", "active", 1, 300000, 0, 0, now, now, None, 0, now, '{}'),
    ]
    for g in goals:
        tmp_registry.execute(
            "INSERT INTO goals VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)", g
        )
    tmp_registry.commit()
    return tmp_registry

# ---------------------------------------------------------------------------
# FIXTURES JSON
# ---------------------------------------------------------------------------
@pytest.fixture
def sample_trace() -> Dict:
    return {
        "trace_id": "550e8400-e29b-41d4-a716-446655440000",
        "parent_span_id": None,
        "current_agent": "bash-master-agent",
        "task_id": "task-123",
        "timestamp_injected": "2026-05-18T22:00:00Z"
    }

@pytest.fixture
def sample_status(sample_trace) -> Dict:
    return {
        "agent_id": "bash-master-agent",
        "trace_id": sample_trace["trace_id"],
        "span_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
        "parent_span_id": None,
        "status": "completed",
        "output_ref": "artifacts/output.json",
        "next_agent_hint": "go-master-agent",
        "timestamp_completed": "2026-05-18T22:35:00Z",
        "a2a_contract_version": "1.0"
    }

@pytest.fixture
def sample_goal() -> Dict:
    return {
        "goal_id": "goal-test-001",
        "objective": "Probar el sistema",
        "assigned_agent": None,
        "assigned_team": None,
        "coordination_strategy": None,
        "provider": "deepseek",
        "status": "active",
        "priority": 5,
        "token_budget": 100000,
        "tokens_used": 0,
        "time_used_seconds": 0,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "updated_at": datetime.now(timezone.utc).isoformat(),
        "next_wakeup": None,
        "lock_version": 0,
        "heartbeat_at": None,
        "metrics_json": "{}"
    }

# ---------------------------------------------------------------------------
# MOCKS
# ---------------------------------------------------------------------------
@pytest.fixture
def mock_telegram():
    with patch("requests.post") as mock_post:
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"ok": True}
        mock_post.return_value = mock_response
        yield mock_post

@pytest.fixture
def mock_supabase():
    client = MagicMock()
    client.table.return_value.upsert.return_value.execute.return_value = MagicMock()
    return client

@pytest.fixture
def mock_qdrant():
    client = MagicMock()
    client.upsert.return_value = None
    return client

@pytest.fixture
def mock_subprocess():
    with patch("subprocess.run") as m:
        m.return_value.returncode = 0
        m.return_value.stdout = "OK"
        m.return_value.stderr = ""
        yield m
