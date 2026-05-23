#!/usr/bin/env python3
"""
---
artifact_id: "goals-mcp-server"
artifact_type: "api_server"
version: "2.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
canonical_path: "goals/mcp-deploy/server.py"
tier: 2
immutable: false
language_lock: "python3"
prompt_hash: "sha256:mcp-server-v2.0.0"
generated_at: "2026-05-22T15:10:00Z"
domain: "goals"
subdomain: "mcp-deploy"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
API HTTP para el ecosistema GOALS MANTIS. Autenticación por API Key y rate limiting.
"""

import os
import sys
import uuid
import logging
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

from fastapi import FastAPI, HTTPException, Header, Request
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

# Agregar goals/ al path para importar las libs
sys.path.append(str(Path(__file__).resolve().parent.parent))
from libs.registry_client import RegistryClient

# ---------------------------------------------------------------------------
# Configuración de logging
# ---------------------------------------------------------------------------
LOG_DIR = Path(os.getenv("MANTIS_LOG_DIR", "goals/logs"))
LOG_DIR.mkdir(parents=True, exist_ok=True)
LOG_FILE = LOG_DIR / "mcp_server.log"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
    handlers=[logging.FileHandler(LOG_FILE, encoding="utf-8")],
)
logger = logging.getLogger("mcp_server")

# ---------------------------------------------------------------------------
# FastAPI app
# ---------------------------------------------------------------------------
app = FastAPI(
    title="MANTIS GOALS MCP Server",
    version="2.0.0",
    description="API HTTP para coordinar metas y agentes del ecosistema MANTIS",
)

# Rate limiter: 100 requests/minuto por IP
limiter = Limiter(key_func=get_remote_address, default_limits=["100/minute"])
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# ---------------------------------------------------------------------------
# Autenticación
# ---------------------------------------------------------------------------
API_KEY = os.getenv("MANTIS_API_KEY", "change-me-in-production")

def verify_api_key(x_api_key: str = Header(...)):
    if x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="API Key inválida")
    return x_api_key

# ---------------------------------------------------------------------------
# Cliente del registry
# ---------------------------------------------------------------------------
DB_PATH = os.getenv("MANTIS_DB_PATH", "goals/registry.db")
registry = RegistryClient(DB_PATH)

# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------
@app.get("/health")
async def health():
    """Health check público (sin autenticación)."""
    return {"status": "ok", "version": "2.0.0", "timestamp": datetime.now(timezone.utc).isoformat()}

@app.get("/goals/{goal_id}")
async def get_goal(goal_id: str, api_key: str = Header(...)):
    """Obtiene una meta por ID."""
    verify_api_key(api_key)
    goal = registry.get_active_goal(goal_id)
    if not goal:
        raise HTTPException(status_code=404, detail="Meta no encontrada")
    return goal

@app.get("/goals")
async def list_goals(status: Optional[str] = "active", api_key: str = Header(...)):
    """Lista metas por estado."""
    verify_api_key(api_key)
    return registry.list_goals_by_status(status)

@app.post("/goals/acquire")
async def acquire_goal(request: dict, api_key: str = Header(...)):
    """Adquiere una meta con CAS atómico."""
    verify_api_key(api_key)
    goal_id = request.get("goal_id")
    agent = request.get("agent")
    version = request.get("expected_version", 0)
    if not goal_id or not agent:
        raise HTTPException(status_code=400, detail="goal_id y agent son obligatorios")
    success = registry.acquire_goal(goal_id, agent, version)
    return {"goal_id": goal_id, "acquired": success}

@app.post("/goals/release")
async def release_goal(request: dict, api_key: str = Header(...)):
    """Libera una meta."""
    verify_api_key(api_key)
    goal_id = request.get("goal_id")
    status = request.get("status", "completed")
    tokens = request.get("tokens_used", 0)
    time_used = request.get("time_used", 0)
    if not goal_id:
        raise HTTPException(status_code=400, detail="goal_id es obligatorio")
    success = registry.release_goal(goal_id, status, tokens, time_used)
    return {"goal_id": goal_id, "released": success}

@app.post("/goals/agent/log")
async def agent_log_action(request: dict, api_key: str = Header(...)):
    """Registra una acción de un agente en su DB local."""
    verify_api_key(api_key)
    # En producción, esto llamaría a AgentDBManager
    agent = request.get("agent")
    action = request.get("action")
    details = request.get("details", "")
    logger.info(f"[{agent}] {action}: {details}")
    return {"status": "logged"}

# ---------------------------------------------------------------------------
# Arranque
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("MANTIS_PORT", "8080"))
    uvicorn.run(app, host="0.0.0.0", port=port)
```

---

## 4. `goals/mcp-deploy/backup.py`

```python
#!/usr/bin/env python3
"""
---
artifact_id: "goals-mcp-backup"
artifact_type: "backup_script"
version: "2.0.0"
canonical_path: "goals/mcp-deploy/backup.py"
tier: 2
immutable: false
language_lock: "python3"
prompt_hash: "sha256:backup-v2.0.0"
generated_at: "2026-05-22T15:20:00Z"
domain: "goals"
subdomain: "mcp-deploy"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Script de backup horario del registry.db y agent-db/.
Uso: python3 backup.py [--backup-dir DIR] [--data-dir DIR] [--keep-days 30]
"""

import os
import sys
import shutil
import sqlite3
import argparse
import logging
from pathlib import Path
from datetime import datetime, timezone, timedelta

BACKUP_DIR = Path(os.getenv("MANTIS_BACKUP_DIR", "goals/backups"))
DATA_DIR = Path(os.getenv("MANTIS_DATA_DIR", "goals/data"))
LOG_DIR = Path(os.getenv("MANTIS_LOG_DIR", "goals/logs"))
LOG_FILE = LOG_DIR / "backup.log"

LOG_DIR.mkdir(parents=True, exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
    handlers=[logging.FileHandler(LOG_FILE, encoding="utf-8"), logging.StreamHandler(sys.stderr)],
)
logger = logging.getLogger("backup")

def integrity_check(db_path: Path) -> bool:
    try:
        conn = sqlite3.connect(str(db_path))
        result = conn.execute("PRAGMA integrity_check;").fetchone()
        conn.close()
        return result[0] == "ok"
    except Exception as e:
        logger.error(f"Error chequeando integridad: {e}")
        return False

def backup(data_dir: str, backup_dir: str, keep_days: int):
    data_path = Path(data_dir)
    backup_path = Path(backup_dir)
    
    if not data_path.exists():
        logger.error(f"Directorio de datos no encontrado: {data_path}")
        return
    
    registry_db = data_path / "registry.db"
    if not registry_db.exists():
        logger.warning("registry.db no existe aún, omitiendo backup")
        return
    
    if not integrity_check(registry_db):
        logger.error("registry.db falló chequeo de integridad. ABORTANDO backup.")
        return
    
    now = datetime.now(timezone.utc)
    timestamp = now.strftime("%Y-%m-%d_%H%M")
    dest = backup_path / timestamp
    dest.mkdir(parents=True, exist_ok=True)
    
    shutil.copy2(str(registry_db), str(dest / "registry.db"))
    logger.info(f"Backup: registry.db → {dest}")
    
    agent_db_dir = data_path / "agent-db"
    if agent_db_dir.exists():
        dest_agent = dest / "agent-db"
        shutil.copytree(str(agent_db_dir), str(dest_agent), dirs_exist_ok=True)
        logger.info(f"Backup: agent-db/ → {dest_agent}")
    
    cutoff = now - timedelta(days=keep_days)
    for old in sorted(backup_path.iterdir()):
        if old.is_dir() and old.name != timestamp:
            try:
                old_date = datetime.strptime(old.name[:10], "%Y-%m-%d")
                if old_date.replace(tzinfo=timezone.utc) < cutoff:
                    shutil.rmtree(str(old))
                    logger.info(f"Backup eliminado (antiguo): {old.name}")
            except ValueError:
                continue

def main():
    parser = argparse.ArgumentParser(description="Backup horario de MANTIS GOALS")
    parser.add_argument("--data-dir", default=str(DATA_DIR), help="Directorio de datos")
    parser.add_argument("--backup-dir", default=str(BACKUP_DIR), help="Directorio de backups")
    parser.add_argument("--keep-days", type=int, default=30, help="Días de retención")
    args = parser.parse_args()
    backup(args.data_dir, args.backup_dir, args.keep_days)

if __name__ == "__main__":
    main()
