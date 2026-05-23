---
artifact_id: "goals-db-rotation-runbook-v2"
artifact_type: "runbook"
version: "2.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
canonical_path: "goals/runbooks/db-rotation.md"
tier: 2
immutable: false
language_lock: "pt-BR"
prompt_hash: "sha256:db-rotation-v2.0.0"
generated_at: "2026-05-22T09:35:00Z"
domain: "goals"
subdomain: "runbooks"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---

# Rotación de Bases de Datos – v2.0.0

## Estructura

```
agent-db/
├── bash-master-agent-20260522083000.db
├── bash-master-agent-20260522090000.db
└── go-master-agent-20260522084500.db
```

## Script

`python3 goals/scripts/rotate_agent_db.py [--dry-run] [--max-keep N]`

- Verifica que el agente no esté activo (consulta `registry.db`).
- Si está inactivo, conserva las últimas `N` bases y elimina las anteriores.
- En modo `--dry-run`, solo imprime qué eliminaría.

## Cron

```cron
0 3 * * * python3 /ruta/mantis/goals/scripts/rotate_agent_db.py >> goals/logs/rotate.log 2>&1
```
