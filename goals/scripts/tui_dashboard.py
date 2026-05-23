#!/usr/bin/env python3
"""
---
artifact_id: "goals-tui-dashboard-py"
artifact_type: "dashboard_script"
version: "2.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
canonical_path: "goals/scripts/tui_dashboard.py"
tier: 2
immutable: false
requires_human_approval_for_changes: false
audience: ["human-architects", "sysadmin"]
language_lock: "python3"
prompt_hash: "sha256:tui-dashboard-v2.0.0"
generated_at: "2026-05-22T12:00:00Z"
domain: "goals"
subdomain: "scripts"
agent_role: "orchestrator-engine"
agent_specialty: "dashboard"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Dashboard TUI interactivo para monitorear metas y agentes en tiempo real.
Uso: python3 goals/scripts/tui_dashboard.py [--refresh 30]
"""

import sys
import time
import argparse
from pathlib import Path
from datetime import datetime, timezone, timedelta

sys.path.append(str(Path(__file__).resolve().parent.parent))
from libs.registry_client import RegistryClient
from libs.agent_db_manager import AgentDBManager

try:
    from rich.console import Console
    from rich.table import Table
    from rich.panel import Panel
    from rich.layout import Layout
    from rich.live import Live
    from rich import box
    from rich.text import Text
    RICH = True
except ImportError:
    print("Instalá rich: pip install rich")
    sys.exit(1)

console = Console()

STATUS_COLORS = {
    "active": "green",
    "paused": "yellow",
    "budget_limited": "red",
    "complete": "blue"
}

def build_dashboard(registry: RegistryClient) -> Layout:
    layout = Layout()
    layout.split_column(
        Layout(name="header", size=3),
        Layout(name="body"),
        Layout(name="footer", size=3)
    )
    
    # Header
    header_text = Text("MANTIS GOALS Dashboard", style="bold cyan")
    header_text.append(f"  |  {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S')} UTC")
    layout["header"].update(Panel(header_text, box=box.HEAVY))
    
    # Body: tabla de metas
    goals_table = Table(title="Metas Activas", box=box.ROUNDED, expand=True)
    goals_table.add_column("Goal ID", style="dim", width=36)
    goals_table.add_column("Objetivo", style="white", width=40)
    goals_table.add_column("Agente", style="cyan", width=20)
    goals_table.add_column("Status", width=15)
    goals_table.add_column("Progreso", width=20)
    goals_table.add_column("Heartbeat", width=20)
    
    now = datetime.now(timezone.utc)
    for status in ["active", "paused", "budget_limited"]:
        goals = registry.list_goals_by_status(status)
        for g in goals:
            color = STATUS_COLORS.get(g["status"], "white")
            status_text = f"[{color}]{g['status']}[/{color}]"
            
            # Progreso
            if g.get("token_budget"):
                pct = min(100, int((g.get("tokens_used", 0) / g["token_budget"]) * 100))
                progress = f"{pct}% ({g.get('tokens_used', 0)}/{g['token_budget']})"
            else:
                progress = f"{g.get('tokens_used', 0)} tokens"
            
            # Heartbeat
            hb = g.get("heartbeat_at")
            if hb:
                hb_dt = datetime.fromisoformat(hb.replace("Z", "+00:00"))
                delta = (now - hb_dt).total_seconds()
                if delta < 300:
                    hb_text = f"[green]vivo ({int(delta)}s)[/green]"
                elif delta < 900:
                    hb_text = f"[yellow]tardío ({int(delta)}s)[/yellow]"
                else:
                    hb_text = f"[red]caído ({int(delta)}s)[/red]"
            else:
                hb_text = "[dim]sin heartbeat[/dim]"
            
            goals_table.add_row(
                g["goal_id"][:8] + "...",
                g["objective"][:38] + ("..." if len(g["objective"]) > 38 else ""),
                g.get("assigned_agent", "sin asignar"),
                status_text,
                progress,
                hb_text
            )
    
    layout["body"].update(goals_table)
    
    # Footer con resumen
    active = len(registry.list_goals_by_status("active"))
    paused = len(registry.list_goals_by_status("paused"))
    budget = len(registry.list_goals_by_status("budget_limited"))
    complete = len(registry.list_goals_by_status("complete"))
    footer_text = Text(f"Activas: [green]{active}[/green] | Pausadas: [yellow]{paused}[/yellow] | Limitadas: [red]{budget}[/red] | Completadas: [blue]{complete}[/blue]")
    footer_text.append("\nCtrl+C para salir")
    layout["footer"].update(Panel(footer_text, box=box.MINIMAL))
    
    return layout

def main():
    parser = argparse.ArgumentParser(description="Dashboard TUI de MANTIS GOALS")
    parser.add_argument("--refresh", type=int, default=30, help="Intervalo de refresco en segundos")
    parser.add_argument("--db-path", default="goals/registry.db")
    args = parser.parse_args()
    
    registry = RegistryClient(args.db_path)
    
    try:
        with Live(build_dashboard(registry), refresh_per_second=1, screen=True) as live:
            while True:
                time.sleep(args.refresh)
                live.update(build_dashboard(registry))
    except KeyboardInterrupt:
        console.print("\n[cyan]Dashboard cerrado.[/cyan]")

if __name__ == "__main__":
    main()
