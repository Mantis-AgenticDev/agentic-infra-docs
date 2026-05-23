#!/usr/bin/env python3
"""
---
artifact_id: "goals-team-orchestrator-py"
artifact_type: "orchestration_script"
version: "2.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
canonical_path: "goals/scripts/team_orchestrator.py"
tier: 2
immutable: false
requires_human_approval_for_changes: false
audience: ["orchestrator-engine", "master-agents", "human-architects"]
language_lock: "python3"
prompt_hash: "sha256:team-orchestrator-v2.0.0"
generated_at: "2026-05-22T14:10:00Z"
domain: "goals"
subdomain: "scripts"
agent_role: "orchestrator-engine"
agent_specialty: "team-coordination"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Orquestador de equipos de agentes. Divide metas en sub-metas y coordina handoffs A2A.
Uso: python3 goals/scripts/team_orchestrator.py --goal-id <id> [--db-path PATH]
"""

import sys
import argparse
import uuid
import logging
from pathlib import Path
from datetime import datetime, timezone
from typing import List, Dict, Optional

sys.path.append(str(Path(__file__).resolve().parent.parent))
from libs.registry_client import RegistryClient
from libs.handoff_package import HandoffPackage

LOG_DIR = Path("goals/logs")
LOG_DIR.mkdir(parents=True, exist_ok=True)
LOG_FILE = LOG_DIR / "team_orchestrator.log"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
    handlers=[
        logging.FileHandler(LOG_FILE, encoding="utf-8"),
        logging.StreamHandler(sys.stderr),
    ],
)
logger = logging.getLogger("team_orchestrator")

try:
    from rich.console import Console
    from rich.table import Table
    from rich.panel import Panel
    from rich.progress import Progress, SpinnerColumn, TextColumn
    from rich.prompt import Prompt, Confirm
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

class TeamOrchestrator:
    def __init__(self, registry: RegistryClient, handoff: HandoffPackage):
        self.registry = registry
        self.handoff = handoff

    def get_team_goal(self, goal_id: str) -> Optional[Dict]:
        goal = self.registry.get_active_goal(goal_id)
        if not goal:
            return None
        if not goal.get("assigned_team"):
            logger.warning(f"La meta {goal_id} no tiene assigned_team")
        return goal

    def split_goal(self, goal: Dict) -> List[Dict]:
        """Divide la meta en sub-metas según la estrategia y los agentes del equipo."""
        team = [a.strip() for a in goal.get("assigned_team", "").split(",") if a.strip()]
        strategy = goal.get("coordination_strategy", "sequential")
        sub_goals = []
        for i, agent in enumerate(team):
            sub = {
                "parent_goal_id": goal["goal_id"],
                "sub_goal_id": f"{goal['goal_id']}-sub-{i+1}",
                "objective": f"[Sub-meta {i+1}/{len(team)}] {goal['objective']} (agente: {agent})",
                "assigned_agent": agent,
                "status": "pending",
                "dependencies": [f"{goal['goal_id']}-sub-{j}" for j in range(i)] if strategy == "sequential" else [],
            }
            sub_goals.append(sub)
        return sub_goals

    def execute_sequential(self, goal: Dict, sub_goals: List[Dict]) -> bool:
        """Ejecuta sub-metas en orden secuencial con handoffs A2A."""
        trace_id = str(uuid.uuid4())
        parent_span_id = None

        for sub in sub_goals:
            tui_info(f"Ejecutando: {sub['sub_goal_id']} → {sub['assigned_agent']}")
            # Crear trace.json para el agente
            task_id = sub["sub_goal_id"]
            self.handoff.create_context(task_id, sub["assigned_agent"], parent_span_id=parent_span_id)
            # Simulación de ejecución (en producción, el agente externo leería este trace y escribiría status)
            tui_info(f"Trace creado en goals/task-{task_id}/context/trace.json")
            tui_info(f"Esperando a que {sub['assigned_agent']} complete...")
            # Aquí iría la lógica de espera o callback
            # Por ahora, simulamos que el agente completó y leemos su status.json
            status_path = Path(f"goals/task-{task_id}/artifacts/{sub['assigned_agent']}/status.json")
            if status_path.exists():
                import json
                with open(status_path, "r") as f:
                    status_data = json.load(f)
                parent_span_id = status_data.get("span_id")
                sub["status"] = "completed"
                tui_success(f"{sub['assigned_agent']} completó (span_id={parent_span_id[:8]}...)")
            else:
                logger.error(f"status.json no encontrado para {sub['sub_goal_id']}")
                sub["status"] = "failed"
                return False
        return True

    def execute_parallel(self, goal: Dict, sub_goals: List[Dict]) -> bool:
        """Ejecuta sub-metas en paralelo (simulado, sin concurrencia real)."""
        trace_id = str(uuid.uuid4())
        results = []
        for sub in sub_goals:
            task_id = sub["sub_goal_id"]
            self.handoff.create_context(task_id, sub["assigned_agent"], parent_span_id=None)
            tui_info(f"Disparado en paralelo: {sub['sub_goal_id']} → {sub['assigned_agent']}")
        # Simulación: todos completan
        for sub in sub_goals:
            sub["status"] = "completed"
        return all(s["status"] == "completed" for s in sub_goals)

    def execute_pipeline(self, goal: Dict, sub_goals: List[Dict]) -> bool:
        """Pipeline: similar a secuencial pero con solapamiento (simplificado)."""
        return self.execute_sequential(goal, sub_goals)

    def orchestrate(self, goal_id: str) -> bool:
        goal = self.get_team_goal(goal_id)
        if not goal:
            tui_info(f"Meta {goal_id} no encontrada o no es de equipo")
            return False

        strategy = goal.get("coordination_strategy", "sequential")
        sub_goals = self.split_goal(goal)

        if not sub_goals:
            tui_info("No se pudieron generar sub-metas (equipo vacío)")
            return False

        tui_table("Sub-metas generadas",
                  ["Sub-Goal ID", "Agente", "Dependencias"],
                  [[s["sub_goal_id"], s["assigned_agent"], ", ".join(s["dependencies"]) or "ninguna"] for s in sub_goals])

        if RICH and not Confirm.ask("¿Ejecutar sub-metas?", default=True):
            return False

        if strategy == "sequential":
            success = self.execute_sequential(goal, sub_goals)
        elif strategy == "parallel":
            success = self.execute_parallel(goal, sub_goals)
        elif strategy == "pipeline":
            success = self.execute_pipeline(goal, sub_goals)
        else:
            logger.error(f"Estrategia desconocida: {strategy}")
            return False

        if success:
            self.registry.release_goal(goal_id, "completed")
            tui_success(f"Meta {goal_id} completada por el equipo")
        else:
            self.registry.release_goal(goal_id, "paused")
            tui_info(f"Meta {goal_id} pausada por fallo en sub-metas")
        return success

def main():
    parser = argparse.ArgumentParser(description="Orquestador de equipos de agentes MANTIS")
    parser.add_argument("--goal-id", required=True, help="ID de la meta de equipo")
    parser.add_argument("--db-path", default="goals/registry.db")
    args = parser.parse_args()

    tui_title("👥 Orquestador de Equipos — MANTIS GOALS")
    registry = RegistryClient(args.db_path)
    handoff = HandoffPackage()
    orchestrator = TeamOrchestrator(registry, handoff)
    success = orchestrator.orchestrate(args.goal_id)
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
