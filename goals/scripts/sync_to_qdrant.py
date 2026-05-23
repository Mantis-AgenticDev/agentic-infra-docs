#!/usr/bin/env python3
"""
---
artifact_id: "goals-sync-to-qdrant-py"
artifact_type: "sync_script"
version: "2.0.0"
canonical_path: "goals/scripts/sync_to_qdrant.py"
tier: 2
immutable: false
language_lock: "python3"
prompt_hash: "sha256:sync-to-qdrant-v2.0.0"
generated_at: "2026-05-22T14:40:00Z"
domain: "goals"
subdomain: "scripts"
agent_role: "orchestrator-engine"
agent_specialty: "sync"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Sincroniza registry.db a Qdrant (modo local free).
Uso: python3 goals/scripts/sync_to_qdrant.py [--config goals/sync-config.yaml] [--once]
"""

import sys
import os
import time
import logging
import argparse
from pathlib import Path
from datetime import datetime, timezone

import yaml

sys.path.append(str(Path(__file__).resolve().parent.parent))
from libs.registry_client import RegistryClient

LOG_DIR = Path("goals/logs")
LOG_DIR.mkdir(parents=True, exist_ok=True)
LOG_FILE = LOG_DIR / "sync_qdrant.log"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
    handlers=[logging.FileHandler(LOG_FILE, encoding="utf-8"), logging.StreamHandler(sys.stderr)],
)
logger = logging.getLogger("sync_qdrant")

try:
    from qdrant_client import QdrantClient
    from qdrant_client.http.models import Distance, VectorParams, PointStruct
    QDRANT_AVAILABLE = True
except ImportError:
    QDRANT_AVAILABLE = False
    logger.warning("qdrant-client no instalado. Ejecutá: pip install qdrant-client")

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

class QdrantSyncer:
    def __init__(self, config_path: str):
        with open(config_path, "r", encoding="utf-8") as f:
            self.config = yaml.safe_load(f)
        self.qdrant_cfg = self.config.get("qdrant", {})
        self.enabled = self.qdrant_cfg.get("enabled", False)
        self.collection_name = self.qdrant_cfg.get("collection_name", "mantis_goals")
        self.vector_size = self.qdrant_cfg.get("vector_size", 1536)
        self.registry = RegistryClient()
        self.client = None
        if self.enabled and QDRANT_AVAILABLE:
            url = self.qdrant_cfg.get("url", os.getenv("QDRANT_URL", "http://localhost:6333"))
            self.client = QdrantClient(url=url)
            self._ensure_collection()
            logger.info("Cliente Qdrant inicializado")

    def _ensure_collection(self):
        try:
            self.client.get_collection(self.collection_name)
        except Exception:
            self.client.create_collection(
                collection_name=self.collection_name,
                vectors_config=VectorParams(size=self.vector_size, distance=Distance.COSINE),
            )
            logger.info(f"Colección {self.collection_name} creada")

    def sync_goals(self) -> int:
        if not self.client:
            logger.warning("Qdrant no configurado")
            return 0
        count = 0
        goals = []
        for status in ["active", "paused", "budget_limited", "complete"]:
            goals.extend(self.registry.list_goals_by_status(status))
        points = []
        for goal in goals:
            # Simulación de embedding: vector aleatorio (en producción usar un modelo de embeddings)
            vector = [0.0] * self.vector_size
            # La primera posición es un hash simple para distinguir documentos
            vector[0] = hash(goal["objective"]) % 1000 / 1000.0
            payload = {
                "goal_id": goal["goal_id"],
                "objective": goal["objective"],
                "status": goal["status"],
                "assigned_agent": goal.get("assigned_agent", ""),
            }
            point_id = hash(goal["goal_id"]) % (10**9)
            points.append(PointStruct(id=point_id, vector=vector, payload=payload))
            count += 1
        if points:
            try:
                self.client.upsert(collection_name=self.collection_name, points=points)
                logger.info(f"Qdrant: {count} puntos sincronizados")
            except Exception as e:
                logger.error(f"Error upsert a Qdrant: {e}")
                return 0
        return count

    def run(self, once: bool, interval: int):
        if not self.enabled:
            tui_error("Sincronización Qdrant deshabilitada en sync-config.yaml")
            return
        while True:
            synced = self.sync_goals()
            tui_success(f"Qdrant: {synced} puntos sincronizados")
            if once:
                break
            time.sleep(interval)

def main():
    parser = argparse.ArgumentParser(description="Sincroniza GOALS a Qdrant")
    parser.add_argument("--config", default="goals/sync-config.yaml")
    parser.add_argument("--once", action="store_true", help="Ejecutar una sola vez y salir")
    args = parser.parse_args()
    tui_title("🔍 Sincronización a Qdrant — MANTIS GOALS")
    syncer = QdrantSyncer(args.config)
    interval = syncer.qdrant_cfg.get("sync_interval_seconds", 300)
    syncer.run(args.once, interval)

if __name__ == "__main__":
    main()
