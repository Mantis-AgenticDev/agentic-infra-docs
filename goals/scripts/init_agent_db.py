#!/usr/bin/env python3
"""
---
artifact_id: "goals-init-agent-db-py"
artifact_type: "initialization_script"
version: "2.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
canonical_path: "goals/scripts/init_agent_db.py"
tier: 2
immutable: false
requires_human_approval_for_changes: false
audience: ["orchestrator-engine", "human-architects"]
language_lock: "python3"
prompt_hash: "sha256:init-agent-db-v2.0.0"
generated_at: "2026-05-22T10:00:00Z"
domain: "goals"
subdomain: "scripts"
agent_role: "orchestrator-engine"
agent_specialty: "initialization"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Inicializa la base de datos SQLite de un agente con el esquema estándar.
Uso: python3 goals/scripts/init_agent_db.py --agent-id <id> [--domain <domain>] [--db-dir <dir>]
"""

import sqlite3
import sys
import argparse
import logging
from pathlib import Path

LOG_DIR = Path("goals/logs")
LOG_DIR.mkdir(parents=True, exist_ok=True)
LOG_FILE = LOG_DIR / "init_agent_db.log"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
    handlers=[
        logging.FileHandler(LOG_FILE, encoding="utf-8"),
        logging.StreamHandler(sys.stderr),
    ],
)
logger = logging.getLogger("init_agent_db")

SCHEMA_SQL = """
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

try:
    from rich.console import Console
    from rich.panel import Panel
    from rich.table import Table
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

def tui_table(title: str, headers: list, rows: list) -> None:
    if RICH:
        table = Table(title=title, box=box.ROUNDED)
        for h in headers:
            table.add_column(h, style="bold yellow")
        for row in rows:
            table.add_row(*[str(c) for c in row])
        console.print(table)
    else:
        print(f"\n{title}")
        print(" | ".join(headers))
        print("-" * 40)
        for row in rows:
            print(" | ".join(str(c) for c in row))

def init_agent_db(agent_id: str, domain: str, db_dir: str) -> str:
    domain_dir = Path(db_dir) / domain
    domain_dir.mkdir(parents=True, exist_ok=True)
    db_path = domain_dir / f"{agent_id}.db"
    
    if db_path.exists():
        logger.info(f"La base {db_path} ya existe. Verificando esquema...")
        conn = sqlite3.connect(str(db_path))
        conn.execute("PRAGMA journal_mode=WAL;")
        conn.executescript(SCHEMA_SQL)
        conn.commit()
        conn.close()
        logger.info(f"Esquema verificado en {db_path}")
        return str(db_path)
    
    conn = sqlite3.connect(str(db_path))
    conn.execute("PRAGMA journal_mode=WAL;")
    conn.executescript(SCHEMA_SQL)
    conn.commit()
    
    # Mostrar tablas creadas
    cursor = conn.cursor()
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;")
    tables = [row[0] for row in cursor.fetchall()]
    conn.close()
    
    logger.info(f"Base de datos creada: {db_path} con tablas: {', '.join(tables)}")
    return str(db_path)

def main():
    parser = argparse.ArgumentParser(description="Inicializa la base de datos de un agente MANTIS.")
    parser.add_argument("--agent-id", required=True, help="ID canónico del agente (ej. bash-master-agent)")
    parser.add_argument("--domain", default="programming",
                       choices=["programming", "configurations", "docs", "agents", "workflow", "runtime"],
                       help="Dominio al que pertenece el agente")
    parser.add_argument("--db-dir", default="goals/agent-db", help="Directorio raíz de bases de datos")
    args = parser.parse_args()
    
    tui_title("🔧 Inicialización de Base de Datos de Agente")
    print(f"Agente: {args.agent_id}")
    print(f"Dominio: {args.domain}")
    print(f"Directorio: {args.db_dir}")
    
    try:
        db_path = init_agent_db(args.agent_id, args.domain, args.db_dir)
        tui_success(f"Base de datos lista en {db_path}")
        sys.exit(0)
    except Exception as e:
        logger.error(f"Error al inicializar DB del agente: {e}")
        tui_error(str(e))
        sys.exit(1)

if __name__ == "__main__":
    main()
