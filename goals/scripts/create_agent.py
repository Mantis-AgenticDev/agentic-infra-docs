#!/usr/bin/env python3
"""
---
artifact_id: "goals-create-agent-py"
artifact_type: "initialization_script"
version: "2.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
canonical_path: "goals/scripts/create_agent.py"
tier: 2
immutable: false
requires_human_approval_for_changes: false
audience: ["human-architects", "orchestrator-engine"]
language_lock: "python3"
prompt_hash: "sha256:create-agent-v2.0.0"
generated_at: "2026-05-23T10:00:00Z"
domain: "goals"
subdomain: "scripts"
agent_role: "orchestrator-engine"
agent_specialty: "agent-creation"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Crea un nuevo agente en el ecosistema MANTIS.
Uso: python3 goals/scripts/create_agent.py --agent-id <id> --domain <domain> [--skills skill1,skill2]
"""

import sys
import argparse
import logging
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent))
from libs.registry_client import RegistryClient
from scripts.init_agent_db import init_agent_db

LOG_DIR = Path("goals/logs")
LOG_DIR.mkdir(parents=True, exist_ok=True)
LOG_FILE = LOG_DIR / "create_agent.log"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
    handlers=[
        logging.FileHandler(LOG_FILE, encoding="utf-8"),
        logging.StreamHandler(sys.stderr),
    ],
)
logger = logging.getLogger("create_agent")

try:
    from rich.console import Console
    from rich.panel import Panel
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

def create_agent(agent_id: str, domain: str, skills: list = None):
    registry = RegistryClient()
    
    # 1. Inicializar base de datos del agente
    tui_title(f"🔧 Creando agente: {agent_id}")
    db_path = init_agent_db(agent_id, domain, "goals/agent-db")
    if not db_path:
        tui_error("No se pudo crear la base de datos del agente")
        return False
    tui_success(f"Base de datos creada en {db_path}")
    
    # 2. Registrar en registry.db (si no existe ya)
    # Nota: el registro real de metas se hace al asignar una meta; aquí solo registramos la existencia.
    logger.info(f"Agente {agent_id} listo para usar en dominio {domain}")
    
    # 3. Crear skill YAML para Hermes si aplica
    if skills:
        hermes_skill_dir = Path("runtimes/hermes/skills")
        hermes_skill_dir.mkdir(parents=True, exist_ok=True)
        skill_yaml = hermes_skill_dir / f"{agent_id}.yaml"
        if not skill_yaml.exists():
            import yaml
            skill_data = {
                "skill": {
                    "name": agent_id,
                    "description": f"Agente {agent_id} del dominio {domain}",
                    "trigger": f"Tareas de {domain}",
                    "agent_db": f"../../goals/agent-db/{domain}/{agent_id}.db",
                    "constraints": ["C1", "C2", "C5", "C9"],
                    "skills": skills,
                }
            }
            with open(skill_yaml, "w") as f:
                yaml.dump(skill_data, f)
            tui_success(f"Skill YAML creado en {skill_yaml}")
    
    tui_success(f"Agente {agent_id} creado exitosamente.")
    return True

def main():
    parser = argparse.ArgumentParser(description="Crea un nuevo agente en el ecosistema MANTIS")
    parser.add_argument("--agent-id", required=True, help="ID canónico del agente (ej. mi-nuevo-agente)")
    parser.add_argument("--domain", required=True, choices=["programming","configurations","docs","agents","workflow","runtime"], help="Dominio al que pertenece")
    parser.add_argument("--skills", default="", help="Lista de skills separadas por coma")
    args = parser.parse_args()
    
    skills_list = [s.strip() for s in args.skills.split(",") if s.strip()] if args.skills else None
    success = create_agent(args.agent_id, args.domain, skills_list)
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
