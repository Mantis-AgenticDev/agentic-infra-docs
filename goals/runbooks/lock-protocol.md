---
artifact_id: "goals-lock-protocol-runbook-v2"
artifact_type: "runbook"
version: "2.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
canonical_path: "goals/runbooks/lock-protocol.md"
tier: 2
immutable: false
language_lock: "pt-BR"
prompt_hash: "sha256:lock-protocol-v2.0.0"
generated_at: "2026-05-22T09:30:00Z"
domain: "goals"
subdomain: "runbooks"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---

# Protocolo de Adquisición de Locks (CAS) – v2.0.0

Cada meta en `registry.db` está protegida por **CAS atómico vía SQLite**.

## Estructura en `registry.db`

| Columna | Propósito |
|---------|-----------|
| `lock_version` | Entero incremental. |
| `heartbeat_at` | Último ping del agente dueño (ISO 8601). |
| `assigned_agent` | Agente que posee el lock. |

## Adquisición

El método `RegistryClient.acquire_goal()` ejecuta una única sentencia SQL atómica:

```sql
UPDATE goals SET status = 'active', assigned_agent = ?, heartbeat_at = ?, lock_version = lock_version + 1
WHERE goal_id = ? AND lock_version = ? AND status IN ('active','paused')
AND (assigned_agent IS NULL OR assigned_agent = ? OR heartbeat_at < ?);
```

Si `sqlite3_changes()` retorna 0, el CAS falló (otro agente la tomó o la versión cambió). El agente debe reintentar.

## Heartbeat

El agente refresca `heartbeat_at` periódicamente con otra sentencia CAS ligera. Si el heartbeat expira (> TTL), el `health_check_agents.py` puede reasignar la meta.

## Liberación

`RegistryClient.release_goal()` actualiza el estado a `paused` o `complete`, limpia `heartbeat_at` e incrementa la versión.

---

*Documento generado según C1-C9.*
