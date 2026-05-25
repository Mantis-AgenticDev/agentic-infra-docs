---
artifact_id: "goals-disaster-recovery"
artifact_type: "runbook"
version: "2.0.1"
canonical_path: "goals/mcp-deploy/DISASTER-RECOVERY.md"
tier: 2
immutable: false
language_lock: "pt-BR"
prompt_hash: "sha256:disaster-recovery-v2.0.1"
generated_at: "2026-05-23T14:15:00Z"
domain: "goals"
subdomain: "mcp-deploy"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---

# Plan de Recuperación ante Desastres — MANTIS GOALS

> ⚠️ **Nota sobre `/health`**: El endpoint `/health` es público por diseño. No expone datos sensibles (solo versión y timestamp). Es necesario para que Docker y orquestadores verifiquen el estado del contenedor sin autenticación.

## Escenarios y respuestas

| Evento | Acción de recuperación |
|--------|------------------------|
| Contenedor caído | `docker compose -f goals/mcp-deploy/docker-compose.yml up -d` (auto-restart con `unless-stopped`). |
| Corrupción de `registry.db` | Ejecutar `sqlite3 data/registry.db "PRAGMA integrity_check;"`. Si falla, restaurar del backup más reciente. |
| Ataque DDoS | El rate limiter (100 req/min) mitiga. Si persiste, cambiar el puerto o bloquear IPs con `iptables`. |
| Borrado accidental | Restaurar `data/` desde `data/backups/YYYY-MM-DD_HHMM/`. |

## Procedimiento de restauración

```bash
# 1. Detener servicios
docker compose -f goals/mcp-deploy/docker-compose.yml down

# 2. Resguardar datos actuales (por si acaso)
mv data/registry.db data/registry.db.corrupto
mv data/agent-db data/agent-db.corrupto

# 3. Copiar el backup más reciente
cp data/backups/2026-05-22_1200/registry.db data/
cp -r data/backups/2026-05-22_1200/agent-db data/

# 4. Reiniciar servicios
docker compose -f goals/mcp-deploy/docker-compose.yml up -d

# 5. Verificar integridad post-restauración
sqlite3 data/registry.db "PRAGMA integrity_check;" | grep -q "ok" || {
  echo "❌ Backup restaurado pero corrupto. Revirtiendo..."
  mv data/registry.db.corrupto data/registry.db
  exit 1
}
curl -f http://localhost:8080/health || {
  echo "❌ Health check falló. Revisar logs."
  exit 1
}
echo "✅ Restauración exitosa. Servidor operativo."
```

---

## `goals/mcp-deploy/.env.example` (nuevo)

```bash
# Copiá este archivo como .env y configurá tu clave secreta
MANTIS_API_KEY=genera-una-clave-segura-de-al-menos-32-caracteres
```

---

## `goals/mcp-deploy/requirements.txt` (sin cambios)

```
fastapi==0.115.6
uvicorn==0.34.0
slowapi==0.1.9
rich==13.9.4
pyyaml==6.0.2
jsonschema==4.23.0
requests==2.32.3
```

---

## `goals/libs/registry_client.py` (método `_connect` modificado)

```python
def _connect(self) -> sqlite3.Connection:
    conn = sqlite3.connect(str(self.db_path), timeout=30.0)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL;")
    conn.execute("PRAGMA busy_timeout=30000;")
    conn.execute("PRAGMA synchronous=NORMAL;")
    conn.execute("PRAGMA foreign_keys=ON;")
    return conn
```

---

## `goals/libs/agent_db_manager.py` (método `_connect` modificado)

```python
def _connect(self) -> sqlite3.Connection:
    conn = sqlite3.connect(str(self.db_path), timeout=30.0)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL;")
    conn.execute("PRAGMA busy_timeout=30000;")
    conn.execute("PRAGMA synchronous=NORMAL;")
    conn.execute("PRAGMA foreign_keys=ON;")
    return conn
