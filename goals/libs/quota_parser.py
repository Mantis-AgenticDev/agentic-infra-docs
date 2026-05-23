---
artifact_id: "goals-libs-quota-parser"
artifact_type: "library"
version: "2.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
canonical_path: "goals/libs/quota_parser.py"
tier: 2
immutable: false
language_lock: "python3"
prompt_hash: "sha256:quota-parser-v2.0.0"
generated_at: "2026-05-22T06:50:00Z"
domain: "goals"
subdomain: "libs"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Lee las políticas de recarga y calcula el próximo next_wakeup.
"""

import yaml
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Optional

class QuotaParser:
    def __init__(self, policies_path: str = "goals/provider-policies.yaml"):
        self.policies_path = Path(policies_path)
        if not self.policies_path.exists():
            raise FileNotFoundError(f"Archivo de políticas no encontrado: {policies_path}")
        with open(self.policies_path, "r", encoding="utf-8") as f:
            self.policies = yaml.safe_load(f)

    def get_next_wakeup(self, provider: str, current_status: str = "paused") -> Optional[str]:
        """Calcula el next_wakeup según la política del proveedor."""
        policy = self.policies.get("providers", {}).get(provider)
        if not policy:
            return None
        now = datetime.now(timezone.utc)
        if policy["window"] == "fixed":
            # Ventana fija: siguiente medianoche UTC o la hora indicada
            reset_time = policy.get("reset_time_utc", "00:00")
            hour, minute = map(int, reset_time.split(":"))
            next_reset = now.replace(hour=hour, minute=minute, second=0, microsecond=0)
            if next_reset <= now:
                next_reset += timedelta(days=1)
            # Añadir margen de seguridad
            return (next_reset + timedelta(minutes=policy.get("safety_margin_minutes", 30))).isoformat()
        elif policy["window"] == "rolling":
            # Ventana rodante: desde ahora + intervalo
            interval_hours = policy.get("interval_hours", 5)
            return (now + timedelta(hours=interval_hours, minutes=policy.get("safety_margin_minutes", 5))).isoformat()
        elif policy["window"] == "weekly":
            # Semanal (lunes siguiente)
            days_until_monday = (7 - now.weekday()) % 7
            if days_until_monday == 0 and now.hour >= policy.get("reset_hour_utc", 0):
                days_until_monday = 7
            next_monday = now.replace(hour=policy.get("reset_hour_utc", 0), minute=0, second=0, microsecond=0) + timedelta(days=days_until_monday)
            return (next_monday + timedelta(minutes=30)).isoformat()
        return None
