#!/usr/bin/env python3
"""
---
artifact_id: "goals-compact-logs-py"
artifact_type: "operations_script"
version: "2.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
canonical_path: "goals/scripts/compact_logs.py"
tier: 2
immutable: false
requires_human_approval_for_changes: false
audience: ["sysadmin", "orchestrator-engine"]
language_lock: "python3"
prompt_hash: "sha256:compact-logs-v2.0.0"
generated_at: "2026-05-22T13:10:00Z"
domain: "goals"
subdomain: "scripts"
agent_role: "orchestrator-engine"
agent_specialty: "housekeeping"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Comprime y rota logs antiguos de goals/logs/.
Uso: python3 goals/scripts/compact_logs.py [--days 30] [--dry-run]
"""

import sys
import gzip
import shutil
import logging
import argparse
from pathlib import Path
from datetime import datetime, timezone, timedelta

LOG_DIR = Path("goals/logs")
LOG_DIR.mkdir(parents=True, exist_ok=True)
LOG_FILE = LOG_DIR / "compact_logs.log"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
    handlers=[
        logging.FileHandler(LOG_FILE, encoding="utf-8"),
        logging.StreamHandler(sys.stderr),
    ],
)
logger = logging.getLogger("compact_logs")

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

def tui_info(text: str) -> None:
    if RICH:
        console.print(f"[cyan]ℹ[/cyan] {text}")
    else:
        print(f"[INFO] {text}")

def tui_success(text: str) -> None:
    if RICH:
        console.print(f"[green]✔[/green] {text}")
    else:
        print(f"[OK] {text}")

def compact_logs(log_dir: str, days: int, dry_run: bool) -> None:
    log_path = Path(log_dir)
    if not log_path.exists():
        logger.info(f"Directorio {log_dir} no existe, nada que compactar")
        return

    cutoff = datetime.now(timezone.utc) - timedelta(days=days)
    compressed_count = 0
    deleted_count = 0

    for log_file in sorted(log_path.glob("*.log")):
        if log_file.name == "compact_logs.log":
            continue
        mtime = datetime.fromtimestamp(log_file.stat().st_mtime, tz=timezone.utc)
        if mtime < cutoff:
            gz_path = log_file.with_suffix(".log.gz")
            if dry_run:
                logger.info(f"[DRY-RUN] Comprimiría: {log_file.name} → {gz_path.name}")
                compressed_count += 1
            else:
                with open(log_file, "rb") as f_in:
                    with gzip.open(str(gz_path), "wb") as f_out:
                        shutil.copyfileobj(f_in, f_out)
                log_file.unlink()
                logger.info(f"Comprimido: {log_file.name} → {gz_path.name}")
                compressed_count += 1

    for old_gz in sorted(log_path.glob("*.log.gz")):
        mtime = datetime.fromtimestamp(old_gz.stat().st_mtime, tz=timezone.utc)
        if mtime < cutoff - timedelta(days=days * 2):
            if dry_run:
                logger.info(f"[DRY-RUN] Eliminaría: {old_gz.name}")
                deleted_count += 1
            else:
                old_gz.unlink()
                logger.info(f"Eliminado comprimido antiguo: {old_gz.name}")
                deleted_count += 1

    tui_info(f"Comprimidos: {compressed_count} | Eliminados: {deleted_count}")

def main():
    parser = argparse.ArgumentParser(description="Compacta logs antiguos de GOALS")
    parser.add_argument("--days", type=int, default=30, help="Días de antigüedad para comprimir")
    parser.add_argument("--dry-run", action="store_true", help="Simular sin ejecutar cambios")
    parser.add_argument("--log-dir", default="goals/logs", help="Directorio de logs")
    args = parser.parse_args()

    tui_title("📦 Compactación de Logs de MANTIS GOALS")
    compact_logs(args.log_dir, args.days, args.dry_run)
    tui_success("Compactación finalizada.")

if __name__ == "__main__":
    main()
