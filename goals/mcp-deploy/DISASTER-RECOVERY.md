---
artifact_id: "goals-disaster-recovery"
artifact_type: "runbook"
version: "2.0.0"
canonical_path: "goals/mcp-deploy/DISASTER-RECOVERY.md"
tier: 2
immutable: false
language_lock: "pt-BR"
prompt_hash: "sha256:disaster-recovery-v2.0.0"
generated_at: "2026-05-22T15:40:00Z"
domain: "goals"
subdomain: "mcp-deploy"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---

# Plan de Recuperación ante Desastres — MANTIS GOALS

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
```

## Verificación

```bash
curl http://localhost:8080/health
# Esperado: {"status":"ok","version":"2.0.0",...}
```
