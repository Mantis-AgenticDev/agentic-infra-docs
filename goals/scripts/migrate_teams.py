#!/usr/bin/env python3
"""
---
artifact_id: "goals-migrate-teams-py"
artifact_type: "migration_script"
version: "2.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
canonical_path: "goals/scripts/migrate_teams.py"
tier: 2
immutable: false
requires_human_approval_for_changes: false
audience: ["orchestrator-engine", "human-architects"]
language_lock: "python3"
prompt_hash: "sha256:migrate-teams-v2.0.0"
generated_at: "2026-05-22T14:00:00Z"
domain: "goals"
subdomain: "scripts"
agent_role: "orchestrator-engine"
agent_specialty: "migration"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Agrega las columnas assigned_team y coordination_strategy a registry.db.
Uso: python3 goals/scripts/migrate_teams.py [--db-path PATH]
"""

import sqlite3
import sys
import argparse
import logging
from pathlib import Path

LOG_DIR = Path("goals/logs")
LOG_DIR.mkdir(parents=True, exist_ok=True)
LOG_FILE = LOG_DIR / "migrate_teams.log"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
    handlers=[
        logging.FileHandler(LOG_FILE, encoding="utf-8"),
        logging.StreamHandler(sys.stderr),
    ],
)
logger = logging.getLogger("migrate_teams")

try:
    from rich.console import Console
    from rich.panel import Panel
    from rich import box
    RICH = True
    console = Console()
except ImportError:
    RICH = False

MIGRATION_SQL = """
ALTER TABLE goals ADD COLUMN assigned_team TEXT;
ALTER TABLE goals ADD COLUMN coordination_strategy TEXT CHECK(coordination_strategy IN ('sequential', 'parallel', 'pipeline', NULL));
"""

def tui_title(text: str) -> None:
    if RICH:
        console.print(Panel(text, style="bold cyan", box=box.HEAVY))
    else:
        print(f"\n{'='*60}\n  {text}\n{'='*60}")

def tui_success(text: str) -> None:
    if RICH:
        console.print(f"[green]✔[/green] {text}")
    else:
        print(f"[OK] {text}")

def tui_error(text: str) -> None:
    if RICH:
        console.print(f"[red]✖[/red] {text}")
    else:
        print(f"[ERROR] {text}")

def migrate(db_path: str) -> bool:
    db_file = Path(db_path)
    if not db_file.exists():
        logger.error(f"registry.db no encontrado en {db_path}")
        return False
    try:
        conn = sqlite3.connect(str(db_file))
        conn.execute("PRAGMA journal_mode=WAL;")
        conn.executescript(MIGRATION_SQL)
        conn.commit()
        conn.close()
        logger.info("Migración de equipos aplicada correctamente")
        return True
    except sqlite3.OperationalError as e:
        if "duplicate column" in str(e).lower():
            logger.info("Las columnas ya existen, nada que migrar")
            return True
        logger.error(f"Error al migrar: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description="Migra registry.db para soporte de equipos")
    parser.add_argument("--db-path", default="goals/registry.db")
    args = parser.parse_args()
    tui_title("🔧 Migración de Equipos — MANTIS GOALS")
    if migrate(args.db_path):
        tui_success("Migración completada.")
        sys.exit(0)
    else:
        tui_error("Falló la migración.")
        sys.exit(1)

if __name__ == "__main__":
    main()
