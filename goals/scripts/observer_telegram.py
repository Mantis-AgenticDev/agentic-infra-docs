#!/usr/bin/env python3
"""
---
artifact_id: "goals-observer-telegram-py"
artifact_type: "monitoring_script"
version: "2.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
canonical_path: "goals/scripts/observer_telegram.py"
tier: 2
immutable: false
requires_human_approval_for_changes: false
audience: ["human-architects", "orchestrator-engine"]
language_lock: "python3"
prompt_hash: "sha256:observer-telegram-v2.0.0"
generated_at: "2026-05-22T12:35:00Z"
domain: "goals"
subdomain: "scripts"
agent_role: "orchestrator-engine"
agent_specialty: "observer"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Observer del ecosistema GOALS. Notifica eventos a Telegram y permite comandos.
Uso: python3 goals/scripts/observer_telegram.py [--config goals/observer-config.yaml]
"""

import sys
import time
import json
import logging
import argparse
from pathlib import Path
from datetime import datetime, timezone, timedelta
from typing import Dict, List, Optional

import yaml
import requests

sys.path.append(str(Path(__file__).resolve().parent.parent))
from libs.registry_client import RegistryClient

LOG_DIR = Path("goals/logs")
LOG_DIR.mkdir(parents=True, exist_ok=True)
LOG_FILE = LOG_DIR / "observer_telegram.log"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
    handlers=[
        logging.FileHandler(LOG_FILE, encoding="utf-8"),
        logging.StreamHandler(sys.stderr),
    ],
)
logger = logging.getLogger("observer_telegram")

# ---------------------------------------------------------------------------
# Clase principal
# ---------------------------------------------------------------------------
class TelegramObserver:
    def __init__(self, config_path: str):
        with open(config_path, "r", encoding="utf-8") as f:
            self.config = yaml.safe_load(f)
        
        self.telegram_cfg = self.config.get("telegram", {})
        self.bot_token = self.telegram_cfg.get("bot_token", "")
        self.chat_id = self.telegram_cfg.get("chat_id", "")
        self.enabled = self.telegram_cfg.get("enabled", False)
        self.poll_interval = self.config.get("poll_interval_seconds", 60)
        self.notify = self.config.get("notify", {})
        self.commands_enabled = self.config.get("commands_enabled", False)
        self.state_file = Path(self.config.get("state_file", "goals/logs/observer_state.json"))
        
        self.registry = RegistryClient()
        self.previous_state: Dict[str, Dict] = {}
        self.last_command_offset: int = 0
        self._load_state()

    def _load_state(self) -> None:
        if self.state_file.exists():
            with open(self.state_file, "r", encoding="utf-8") as f:
                self.previous_state = json.load(f)

    def _save_state(self, current: Dict[str, Dict]) -> None:
        self.state_file.parent.mkdir(parents=True, exist_ok=True)
        with open(self.state_file, "w", encoding="utf-8") as f:
            json.dump(current, f, indent=2, default=str)
        self.previous_state = current

    def send_message(self, text: str) -> bool:
        if not self.enabled or not self.bot_token or not self.chat_id:
            logger.info(f"[NOTIFICACIÓN] {text}")
            return False
        try:
            url = f"https://api.telegram.org/bot{self.bot_token}/sendMessage"
            resp = requests.post(url, json={
                "chat_id": self.chat_id,
                "text": text,
                "parse_mode": "Markdown",
                "disable_notification": False
            }, timeout=10)
            if resp.status_code == 200:
                logger.info(f"Mensaje enviado a Telegram: {text[:80]}")
                return True
            else:
                logger.error(f"Error Telegram: {resp.status_code} {resp.text}")
                return False
        except Exception as e:
            logger.error(f"Error al enviar mensaje: {e}")
            return False

    def _fetch_all_goals(self) -> Dict[str, Dict]:
        goals = {}
        for status in ["active", "paused", "budget_limited", "complete"]:
            for g in self.registry.list_goals_by_status(status):
                goals[g["goal_id"]] = g
        return goals

    def detect_events(self, current: Dict[str, Dict]) -> List[str]:
        events = []
        now = datetime.now(timezone.utc)

        for goal_id, goal in current.items():
            prev = self.previous_state.get(goal_id)

            # goal.started
            if prev is None and goal["status"] == "active":
                if self.notify.get("goal_started", True):
                    events.append(f"🚀 *Meta iniciada*\nID: `{goal_id[:8]}...`\nObjetivo: {goal['objective'][:100]}\nAgente: {goal.get('assigned_agent', 'sin asignar')}")

            if prev:
                # goal.completed
                if prev["status"] != "complete" and goal["status"] == "complete":
                    if self.notify.get("goal_completed", True):
                        tokens = goal.get("tokens_used", 0)
                        time_used = goal.get("time_used_seconds", 0)
                        events.append(f"✅ *Meta completada*\nID: `{goal_id[:8]}...`\nObjetivo: {goal['objective'][:100]}\nTokens usados: {tokens}\nTiempo: {time_used}s")

                # goal.paused_budget
                elif prev["status"] != "budget_limited" and goal["status"] == "budget_limited":
                    if self.notify.get("goal_paused_budget", True):
                        next_wakeup = goal.get("next_wakeup", "desconocido")
                        events.append(f"⏳ *Meta limitada por presupuesto*\nID: `{goal_id[:8]}...`\nObjetivo: {goal['objective'][:100]}\nPróxima reactivación: {next_wakeup}")

                # goal.error (paused sin next_wakeup)
                elif prev["status"] != "paused" and goal["status"] == "paused" and not goal.get("next_wakeup"):
                    if self.notify.get("goal_error", True):
                        events.append(f"⚠️ *Meta pausada sin fecha de reactivación*\nID: `{goal_id[:8]}...`\nObjetivo: {goal['objective'][:100]}")

                # Progreso
                if goal.get("token_budget") and goal["status"] == "active":
                    pct = int((goal.get("tokens_used", 0) / goal["token_budget"]) * 100)
                    prev_pct = 0
                    if prev.get("token_budget"):
                        prev_pct = int((prev.get("tokens_used", 0) / prev["token_budget"]) * 100)
                    milestones = self.notify.get("goal_progress_pct", [25, 50, 75])
                    for m in milestones:
                        if prev_pct < m <= pct:
                            events.append(f"📊 *Meta al {m}%*\nID: `{goal_id[:8]}...`\nProgreso: {pct}% ({goal.get('tokens_used', 0)}/{goal['token_budget']} tokens)")

                # agent.heartbeat_lost
                if goal["status"] == "active" and goal.get("heartbeat_at"):
                    hb = datetime.fromisoformat(goal["heartbeat_at"].replace("Z", "+00:00"))
                    if (now - hb) > timedelta(minutes=15):
                        prev_hb_ok = True
                        if prev.get("heartbeat_at"):
                            prev_hb_dt = datetime.fromisoformat(prev["heartbeat_at"].replace("Z", "+00:00"))
                            prev_hb_ok = (now - prev_hb_dt) <= timedelta(minutes=15)
                        if prev_hb_ok and self.notify.get("agent_heartbeat_lost", True):
                            events.append(f"💔 *Agente sin heartbeat*\nID: `{goal_id[:8]}...`\nAgente: {goal.get('assigned_agent', 'desconocido')}")

        return events

    def process_commands(self) -> None:
        if not self.commands_enabled or not self.enabled:
            return
        try:
            url = f"https://api.telegram.org/bot{self.bot_token}/getUpdates"
            params = {"offset": self.last_command_offset + 1, "timeout": 5}
            resp = requests.get(url, params=params, timeout=10)
            if resp.status_code != 200:
                return
            updates = resp.json().get("result", [])
            for upd in updates:
                self.last_command_offset = max(self.last_command_offset, upd["update_id"])
                msg = upd.get("message", {})
                text = msg.get("text", "")
                chat_id = msg.get("chat", {}).get("id")
                if str(chat_id) != str(self.chat_id):
                    continue
                if text.startswith("/status"):
                    self._cmd_status()
                elif text.startswith("/pause"):
                    parts = text.split()
                    if len(parts) > 1:
                        self._cmd_pause(parts[1])
                elif text.startswith("/resume"):
                    parts = text.split()
                    if len(parts) > 1:
                        self._cmd_resume(parts[1])
        except Exception as e:
            logger.error(f"Error procesando comandos: {e}")

    def _cmd_status(self) -> None:
        active = len(self.registry.list_goals_by_status("active"))
        paused = len(self.registry.list_goals_by_status("paused"))
        budget = len(self.registry.list_goals_by_status("budget_limited"))
        complete = len(self.registry.list_goals_by_status("complete"))
        self.send_message(f"📊 *Resumen MANTIS GOALS*\n🟢 Activas: {active}\n🟡 Pausadas: {paused}\n🔴 Limitadas: {budget}\n🔵 Completadas: {complete}")

    def _cmd_pause(self, goal_id: str) -> None:
        goal = self.registry.get_active_goal(goal_id)
        if goal:
            self.registry.release_goal(goal_id, "paused")
            self.send_message(f"⏸️ Meta pausada: `{goal_id[:8]}...`")
        else:
            self.send_message(f"❌ Meta no encontrada: `{goal_id}`")

    def _cmd_resume(self, goal_id: str) -> None:
        goal = self.registry.get_active_goal(goal_id)
        if goal and goal["status"] == "paused":
            self.registry.acquire_goal(goal_id, goal.get("assigned_agent", ""), goal.get("lock_version", 0))
            self.send_message(f"▶️ Meta reanudada: `{goal_id[:8]}...`")
        else:
            self.send_message(f"❌ No se puede reanudar: `{goal_id}`")

    def run(self) -> None:
        logger.info("Observer Telegram iniciado")
        if self.enabled:
            logger.info(f"Notificaciones habilitadas para chat {self.chat_id}")
        else:
            logger.info("Notificaciones deshabilitadas. Edita observer-config.yaml para habilitarlas.")
        try:
            while True:
                current = self._fetch_all_goals()
                events = self.detect_events(current)
                for event in events:
                    self.send_message(event)
                self._save_state(current)
                self.process_commands()
                time.sleep(self.poll_interval)
        except KeyboardInterrupt:
            logger.info("Observer detenido.")

def main():
    parser = argparse.ArgumentParser(description="Observer Telegram de MANTIS GOALS")
    parser.add_argument("--config", default="goals/observer-config.yaml")
    args = parser.parse_args()
    observer = TelegramObserver(args.config)
    observer.run()

if __name__ == "__main__":
    main()
