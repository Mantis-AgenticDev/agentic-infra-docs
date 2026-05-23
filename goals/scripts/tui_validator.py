#!/usr/bin/env python3
"""
---
artifact_id: "goals-tui-validator-py"
artifact_type: "validation_script"
version: "2.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
canonical_path: "goals/scripts/tui_validator.py"
tier: 2
immutable: false
requires_human_approval_for_changes: false
audience: ["human-architects", "orchestrator-engine"]
language_lock: "python3"
prompt_hash: "sha256:tui-validator-v2.0.0"
generated_at: "2026-05-22T13:00:00Z"
domain: "goals"
subdomain: "scripts"
agent_role: "orchestrator-engine"
agent_specialty: "validation-tui"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Menú TUI interactivo para todas las validaciones y mantenimiento de GOALS.
Uso: python3 goals/scripts/tui_validator.py
"""

import sys
import subprocess
from pathlib import Path

try:
    from rich.console import Console
    from rich.panel import Panel
    from rich.table import Table
    from rich.prompt import Prompt, Confirm
    from rich import box
    RICH = True
    console = Console()
except ImportError:
    print("Instalá rich: pip install rich")
    sys.exit(1)

SCRIPTS_DIR = Path(__file__).resolve().parent

def run_script(script_name: str, args: list = None) -> int:
    """Ejecuta un script Python del mismo directorio y muestra su salida."""
    script_path = SCRIPTS_DIR / script_name
    if not script_path.exists():
        console.print(f"[red]✖ Script no encontrado: {script_name}[/red]")
        return 1
    cmd = ["python3", str(script_path)] + (args or [])
    console.print(f"[dim]Ejecutando: {' '.join(cmd)}[/dim]")
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode == 0:
        console.print(f"[green]✔ {script_name} completado correctamente[/green]")
    else:
        console.print(f"[red]✖ {script_name} falló (código {result.returncode})[/red]")
    if result.stdout:
        console.print(result.stdout)
    if result.stderr:
        console.print(f"[yellow]stderr:[/yellow]\n{result.stderr}")
    return result.returncode

def menu_validate_registry():
    console.clear()
    console.print(Panel("Validar registry.db", style="bold cyan", box=box.HEAVY))
    run_script("validate_registry.py")

def menu_check_a2a():
    console.clear()
    console.print(Panel("Validar Contrato A2A (C9)", style="bold cyan", box=box.HEAVY))
    task_id = Prompt.ask("Ingresá el task-id")
    agent = Prompt.ask("Ingresá el nombre del agente")
    json_out = Confirm.ask("¿Salida JSON?", default=True)
    args = ["--task-id", task_id, "--agent", agent]
    if json_out:
        args.append("--json")
    run_script("check_a2a_contract.py", args)

def menu_health_check():
    console.clear()
    console.print(Panel("Health Check de Agentes", style="bold cyan", box=box.HEAVY))
    timeout = Prompt.ask("Timeout de heartbeat (minutos)", default="15")
    json_out = Confirm.ask("¿Salida JSON?", default=False)
    args = ["--timeout", timeout]
    if json_out:
        args.append("--json")
    run_script("health_check_agents.py", args)

def menu_rotate_db():
    console.clear()
    console.print(Panel("Rotar Bases de Datos de Agentes", style="bold cyan", box=box.HEAVY))
    dry_run = Confirm.ask("¿Simulación (dry-run)?", default=True)
    max_keep = Prompt.ask("Bases a conservar por agente", default="5")
    args = ["--max-keep", max_keep]
    if dry_run:
        args.append("--dry-run")
    run_script("rotate_agent_db.py", args)

def menu_compact_logs():
    console.clear()
    console.print(Panel("Compactar Logs Antiguos", style="bold cyan", box=box.HEAVY))
    days = Prompt.ask("Comprimir logs con más de X días", default="30")
    dry_run = Confirm.ask("¿Simulación (dry-run)?", default=True)
    args = ["--days", days]
    if dry_run:
        args.append("--dry-run")
    run_script("compact_logs.py", args)

def menu_view_logs():
    console.clear()
    console.print(Panel("Últimas líneas de logs", style="bold cyan", box=box.HEAVY))
    log_dir = Path("goals/logs")
    if not log_dir.exists():
        console.print("[yellow]No hay carpeta de logs.[/yellow]")
        return
    log_files = sorted(log_dir.glob("*.log"))
    if not log_files:
        console.print("[yellow]No hay archivos de log.[/yellow]")
        return
    
    table = Table(title="Archivos de log", box=box.ROUNDED)
    table.add_column("Archivo", style="cyan")
    table.add_column("Tamaño", style="dim")
    for lf in log_files:
        size = lf.stat().st_size
        table.add_row(lf.name, f"{size} bytes")
    console.print(table)
    
    choice = Prompt.ask("Nombre del archivo a ver (vacío para volver)")
    if choice:
        log_path = log_dir / choice
        if log_path.exists():
            console.print(log_path.read_text(encoding="utf-8")[-2000:])
        else:
            console.print(f"[red]Archivo no encontrado: {choice}[/red]")

def menu_init_registry():
    console.clear()
    console.print(Panel("Inicializar registry.db", style="bold cyan", box=box.HEAVY))
    if Path("goals/registry.db").exists():
        overwrite = Confirm.ask("registry.db ya existe. ¿Sobrescribir?", default=False)
        if not overwrite:
            console.print("[yellow]Cancelado.[/yellow]")
            return
    run_script("init_registry.py")

def menu_init_agent_db():
    console.clear()
    console.print(Panel("Inicializar Base de Agente", style="bold cyan", box=box.HEAVY))
    agent_id = Prompt.ask("Agent ID (ej. bash-master-agent)")
    domain = Prompt.ask("Dominio", choices=["programming", "configurations", "docs", "agents", "workflow", "runtime"], default="programming")
    run_script("init_agent_db.py", ["--agent-id", agent_id, "--domain", domain])

def main():
    while True:
        console.clear()
        console.print(Panel(
            "[bold cyan]🛡️ MANTIS GOALS — Menú de Validación[/bold cyan]\n\n"
            "1. Validar registry.db\n"
            "2. Validar contrato A2A (C9)\n"
            "3. Health check de agentes\n"
            "4. Rotar bases de datos\n"
            "5. Compactar logs antiguos\n"
            "6. Ver logs\n"
            "7. Inicializar registry.db\n"
            "8. Inicializar base de agente\n"
            "0. Salir",
            box=box.HEAVY
        ))
        
        choice = Prompt.ask("Elegí una opción", choices=["0", "1", "2", "3", "4", "5", "6", "7", "8"], default="0")
        
        if choice == "0":
            console.print("[cyan]¡Hasta luego![/cyan]")
            sys.exit(0)
        elif choice == "1":
            menu_validate_registry()
        elif choice == "2":
            menu_check_a2a()
        elif choice == "3":
            menu_health_check()
        elif choice == "4":
            menu_rotate_db()
        elif choice == "5":
            menu_compact_logs()
        elif choice == "6":
            menu_view_logs()
        elif choice == "7":
            menu_init_registry()
        elif choice == "8":
            menu_init_agent_db()
        
        Prompt.ask("\n[dim]Presioná Enter para continuar...[/dim]")

if __name__ == "__main__":
    main()
