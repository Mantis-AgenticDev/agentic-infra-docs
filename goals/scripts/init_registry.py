#!/usr/bin/env python3
"""
---
artifact_id: "goals-init-registry-py"
artifact_type: "initialization_script"
version: "2.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
canonical_path: "goals/scripts/init_registry.py"
tier: 2
immutable: false
requires_human_approval_for_changes: false
audience: ["orchestrator-engine", "human-architects"]
language_lock: "python3"
prompt_hash: "sha256:init-registry-v2.0.0"
generated_at: "2026-05-22T06:00:00Z"
tenant_context: "nao_aplicavel"
language: "python3"
domain: "goals"
subdomain: "scripts"
agent_role: "orchestrator-engine"
agent_specialty: "initialization"
status: "✅ Estável"
next_review: "2026-06-22"
license: "CC-BY-NC-SA-4.0"
---
Inicializa el registry.db con el esquema canónico MANTIS.
Uso: python3 goals/scripts/init_registry.py [--db-path PATH]
"""

import sqlite3
import sys
import argparse
import logging
from pathlib import Path

LOG_DIR = Path("goals/logs")
LOG_DIR.mkdir(parents=True, exist_ok=True)
LOG_FILE = LOG_DIR / "init_registry.log"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
    handlers=[
        logging.FileHandler(LOG_FILE, encoding="utf-8"),
        logging.StreamHandler(sys.stderr),
    ],
)
logger = logging.getLogger("init_registry")

SCHEMA_SQL = """
CREATE TABLE IF NOT EXISTS goals (
    goal_id           TEXT PRIMARY KEY NOT NULL,
    objective         TEXT NOT NULL,
    assigned_agent    TEXT,
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

try:
    from rich.console import Console
    from rich.table import Table
    from rich.panel import Panel
    from rich import box
    RICH = True
    console = Console()
except ImportError:
    RICH = False

def tui_title(text: str) -> None:
    if RICH:
        console.print(Panel(text, style="bold cyan", box=box.HEAVY))
    else:
        print(f"\n{'='*60}\n  {text}\n{'='*60}")

def tui_success(text: str) -> None:
    if RICH:
        console.print(f"[green]✔[/green] {text}")
    else:
        print(f"[OK]    {text}")

def tui_error(text: str) -> None:
    if RICH:
        console.print(f"[red]✖[/red] {text}")
    else:
        print(f"[ERROR] {text}")

def tui_table(headers: list, rows: list) -> None:
    if RICH:
        table = Table(title="Esquema de registry.db", box=box.ROUNDED)
        for h in headers:
            table.add_column(h, style="bold yellow")
        for row in rows:
            table.add_row(*[str(c) for c in row])
        console.print(table)
    else:
        print(f"\n{' | '.join(headers)}")
        print("-" * 40)
        for row in rows:
            print(f"{' | '.join(str(c) for c in row)}")

def init_registry(db_path: str) -> bool:
    db_file = Path(db_path)
    db_file.parent.mkdir(parents=True, exist_ok=True)
    try:
        conn = sqlite3.connect(str(db_file))
        conn.execute("PRAGMA journal_mode=WAL;")
        conn.execute("PRAGMA foreign_keys=ON;")
        conn.executescript(SCHEMA_SQL)
        conn.commit()
        cursor = conn.cursor()
        cursor.execute("PRAGMA table_info(goals);")
        columns = cursor.fetchall()
        rows = [[col[1], col[2], "NOT NULL" if col[4] else "", str(col[5])] for col in columns]
        tui_table(["Columna", "Tipo", "Nullable", "Default"], rows)
        conn.close()
        logger.info(f"registry.db inicializado correctamente en {db_path}")
        return True
    except Exception as e:
        logger.error(f"Error al inicializar registry.db: {e}")
        tui_error(str(e))
        return False

def main():
    parser = argparse.ArgumentParser(description="Inicializa el registry.db del sistema GOALS MANTIS.")
    parser.add_argument("--db-path", default="goals/registry.db", help="Ruta al archivo de base de datos")
    args = parser.parse_args()
    tui_title("🔧 Inicialización de MANTIS GOALS Registry")
    success = init_registry(args.db_path)
    if success:
        tui_success("registry.db inicializado correctamente.")
        sys.exit(0)
    else:
        tui_error("Falló la inicialización. Revisa goals/logs/init_registry.log")
        sys.exit(1)

if __name__ == "__main__":
    main()
