#!/usr/bin/env python3
"""
---
artifact_id: "goals-sync-to-supabase-py"
artifact_type: "sync_script"
version: "2.0.0"
canonical_path: "goals/scripts/sync_to_supabase.py"
tier: 2
immutable: false
language_lock: "python3"
prompt_hash: "sha256:sync-to-supabase-v2.0.0"
generated_at: "2026-05-22T14:35:00Z"
domain: "goals"
subdomain: "scripts"
agent_role: "orchestrator-engine"
agent_specialty: "sync"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Sincroniza registry.db a Supabase (free tier compatible).
Uso: python3 goals/scripts/sync_to_supabase.py [--config goals/sync-config.yaml] [--once]
"""

import sys
import os
import time
import json
import logging
import argparse
from pathlib import Path
from datetime import datetime, timezone

import yaml

sys.path.append(str(Path(__file__).resolve().parent.parent))
from libs.registry_client import RegistryClient

LOG_DIR = Path("goals/logs")
LOG_DIR.mkdir(parents=True, exist_ok=True)
LOG_FILE = LOG_DIR / "sync_supabase.log"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
    handlers=[logging.FileHandler(LOG_FILE, encoding="utf-8"), logging.StreamHandler(sys.stderr)],
)
logger = logging.getLogger("sync_supabase")

try:
    from supabase import create_client, Client
    SUPA_AVAILABLE = True
except ImportError:
    SUPA_AVAILABLE = False
    logger.warning("supabase-py no instalado. Ejecutá: pip install supabase")

try:
    from rich.console import Console
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
        print(f"[OK] {text}")

def tui_error(text: str) -> None:
    if RICH:
        console.print(f"[red]✖[/red] {text}")
    else:
        print(f"[ERROR] {text}")

class SupabaseSyncer:
    def __init__(self, config_path: str):
        with open(config_path, "r", encoding="utf-8") as f:
            self.config = yaml.safe_load(f)
        self.supabase_cfg = self.config.get("supabase", {})
        self.enabled = self.supabase_cfg.get("enabled", False)
        self.table_prefix = self.supabase_cfg.get("table_prefix", "mantis_")
        self.registry = RegistryClient()
        self.client: Client = None
        if self.enabled and SUPA_AVAILABLE:
            url = self.supabase_cfg.get("url", os.getenv("SUPABASE_URL", ""))
            key = self.supabase_cfg.get("anon_key", os.getenv("SUPABASE_ANON_KEY", ""))
            if url and key:
                self.client = create_client(url, key)
                logger.info("Cliente Supabase inicializado")
            else:
                logger.error("Faltan credenciales de Supabase")

    def sync_goals(self) -> int:
        """Sube todas las metas activas a Supabase. Retorna el número de registros sincronizados."""
        if not self.client:
            logger.warning("Supabase no configurado")
            return 0
        count = 0
        goals = []
        for status in ["active", "paused", "budget_limited", "complete"]:
            goals.extend(self.registry.list_goals_by_status(status))
        for goal in goals:
            row = {
                "goal_id": goal["goal_id"],
                "objective": goal["objective"],
                "assigned_agent": goal.get("assigned_agent"),
                "status": goal["status"],
                "priority": goal.get("priority", 5),
                "token_budget": goal.get("token_budget"),
                "tokens_used": goal.get("tokens_used", 0),
                "time_used_seconds": goal.get("time_used_seconds", 0),
                "next_wakeup": goal.get("next_wakeup"),
                "updated_at": datetime.now(timezone.utc).isoformat(),
            }
            try:
                self.client.table(f"{self.table_prefix}goals").upsert(row, on_conflict="goal_id").execute()
                count += 1
            except Exception as e:
                logger.error(f"Error sincronizando goal {goal['goal_id']}: {e}")
        logger.info(f"Sincronizados {count} registros a Supabase")
        return count

    def run(self, once: bool, interval: int):
        if not self.enabled:
            tui_error("Sincronización deshabilitada en sync-config.yaml")
            return
        while True:
            synced = self.sync_goals()
            tui_success(f"Supabase: {synced} metas sincronizadas")
            if once:
                break
            time.sleep(interval)

def main():
    parser = argparse.ArgumentParser(description="Sincroniza GOALS a Supabase")
    parser.add_argument("--config", default="goals/sync-config.yaml")
    parser.add_argument("--once", action="store_true", help="Ejecutar una sola vez y salir")
    args = parser.parse_args()
    tui_title("☁️ Sincronización a Supabase — MANTIS GOALS")
    syncer = SupabaseSyncer(args.config)
    interval = syncer.supabase_cfg.get("sync_interval_seconds", 300)
    syncer.run(args.once, interval)

if __name__ == "__main__":
    main()
