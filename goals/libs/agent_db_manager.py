---
artifact_id: "goals-libs-agent-db-manager"
artifact_type: "library"
version: "2.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
canonical_path: "goals/libs/agent_db_manager.py"
tier: 2
immutable: false
language_lock: "python3"
prompt_hash: "sha256:agent-db-manager-v2.0.0"
generated_at: "2026-05-22T10:15:00Z"
domain: "goals"
subdomain: "libs"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Gestor Singleton de la base de datos de un agente. Garantiza que solo el dueño
pueda escribir en ella y proporciona métodos seguros para registrar acciones,
métricas y estado de metas.
"""

import sqlite3
import logging
from pathlib import Path
from datetime import datetime, timezone
from typing import Optional, List, Dict

logger = logging.getLogger("agent_db_manager")

class AgentDBManager:
    def __init__(self, agent_id: str, db_dir: str = "goals/agent-db", domain: Optional[str] = None):
        self.agent_id = agent_id
        self.db_dir = Path(db_dir)
        self.domain = domain or self._detect_domain(agent_id)
        self.db_path = self.db_dir / self.domain / f"{agent_id}.db"
        
        if not self.db_path.exists():
            raise FileNotFoundError(
                f"Base de datos no encontrada: {self.db_path}. "
                f"Ejecute init_agent_db.py --agent-id {agent_id} --domain {self.domain}"
            )
        
        self._validate_ownership()
    
    def _detect_domain(self, agent_id: str) -> str:
        """Infiera el dominio a partir del nombre del agente."""
        if any(kw in agent_id for kw in ['bash', 'go', 'javascript', 'typescript', 'python', 'sql', 'yaml', 'json', 'pgvector', 'rag']):
            return "programming"
        if any(kw in agent_id for kw in ['docker', 'pipeline', 'terraform']):
            return "configurations"
        if any(kw in agent_id for kw in ['doc', 'api-doc', 'code-doc', 'diagram', 'deployment', 'user-guide', 'adr', 'event-catalog', 'explainer', 'i18n', 'audit', 'link-validator', 'freshness', 'audience', 'coverage', 'agent-instruction', 'security-scanner', 'accessibility', 'license', 'onboarding', 'search-optimizer', 'feedback']):
            return "docs"
        if any(kw in agent_id for kw in ['qa', 'cicd', 'agents-ceo']):
            return "agents"
        if any(kw in agent_id for kw in ['n8n', 'langchain', 'workflow']):
            return "workflow"
        if any(kw in agent_id for kw in ['deepseek', 'hermes', 'antigravity', 'paperclip', 'codex']):
            return "runtime"
        return "runtime"  # default
    
    def _validate_ownership(self) -> None:
        """Verifica que el agente que abre la base sea el dueño legítimo."""
        # El dueño se determina por el nombre del archivo: <agent_id>.db
        if self.db_path.stem != self.agent_id:
            raise PermissionError(
                f"Violación de Singleton: el agente '{self.agent_id}' intentó acceder "
                f"a la base '{self.db_path.stem}', que pertenece a otro agente."
            )
        logger.info(f"Acceso concedido a {self.db_path}")
    
    def _connect(self) -> sqlite3.Connection:
        conn = sqlite3.connect(str(self.db_path))
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA journal_mode=WAL;")
        return conn
    
    def log_action(self, action: str, details: str = "") -> None:
        """Registra una acción en el action_log."""
        now = datetime.now(timezone.utc).isoformat()
        with self._connect() as conn:
            conn.execute(
                "INSERT INTO action_log (timestamp, action, details) VALUES (?, ?, ?)",
                (now, action, details)
            )
            conn.commit()
    
    def update_goal_state(self, goal_id: str, status: str, tokens_used: int = 0, time_used: int = 0) -> None:
        """Actualiza el estado de una meta en la DB del agente."""
        now = datetime.now(timezone.utc).isoformat()
        with self._connect() as conn:
            conn.execute(
                """INSERT OR REPLACE INTO goal_state (goal_id, objective, status, tokens_used, time_used_seconds, last_updated)
                   VALUES (?, ?, ?, ?, ?, ?)""",
                (goal_id, "", status, tokens_used, time_used, now)
            )
            conn.commit()
    
    def get_goal_state(self, goal_id: str) -> Optional[Dict]:
        """Obtiene el estado de una meta."""
        with self._connect() as conn:
            row = conn.execute("SELECT * FROM goal_state WHERE goal_id = ?", (goal_id,)).fetchone()
            return dict(row) if row else None
    
    def update_metric(self, name: str, value: float) -> None:
        """Actualiza una métrica del agente."""
        now = datetime.now(timezone.utc).isoformat()
        with self._connect() as conn:
            conn.execute(
                "INSERT OR REPLACE INTO metrics (metric_name, metric_value, updated_at) VALUES (?, ?, ?)",
                (name, value, now)
            )
            conn.commit()
    
    def get_metrics(self) -> Dict[str, float]:
        """Obtiene todas las métricas del agente."""
        with self._connect() as conn:
            rows = conn.execute("SELECT metric_name, metric_value FROM metrics").fetchall()
            return {row["metric_name"]: row["metric_value"] for row in rows}
    
    def get_recent_actions(self, limit: int = 20) -> List[Dict]:
        """Obtiene las últimas acciones registradas."""
        with self._connect() as conn:
            rows = conn.execute(
                "SELECT * FROM action_log ORDER BY id DESC LIMIT ?", (limit,)
            ).fetchall()
            return [dict(r) for r in rows]
