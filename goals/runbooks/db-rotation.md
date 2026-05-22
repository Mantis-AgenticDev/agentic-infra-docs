---
artifact_id: "goals-db-rotation-runbook"
artifact_type: "runbook"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
validation_command: "bash goals/scripts/rotate-agent-db.sh --dry-run"
canonical_path: "goals/runbooks/db-rotation.md"
tier: 2
immutable: false
requires_human_approval_for_changes: false
audience: ["master-agents", "sysadmin", "orchestrator-engine"]
human_readable: true
related_files:
  - "goals/scripts/rotate-agent-db.sh"
  - "goals/registry.yaml"
language_lock: "pt-BR"
prompt_hash: "sha256:db-rotation-v1.0.0"
generated_at: "2026-05-22T04:30:00Z"
tenant_context: "nao_aplicavel"
language: "pt-BR"
domain: "goals"
subdomain: "runbooks"
agent_role: "orchestrator-engine"
agent_specialty: "housekeeping"
status: "✅ Estável"
next_review: "2026-06-22"
license: "CC-BY-NC-SA-4.0"
---

# Rotación de Bases de Datos de Agentes — MANTIS Agentic

Cada agente maestro que ejecuta metas persistirá datos de estado, logs y contabilidad en una base SQLite dentro de `agent-db/`. Con el tiempo, estas bases pueden acumularse y consumir espacio. El sistema rota las bases antiguas automáticamente, manteniendo las últimas `N` por agente.

## Estructura de `agent-db/`

Los archivos se nombran con el patrón `<agent-name>-<timestamp>.db`, donde `timestamp` sigue el formato `YYYYMMDDHHMMSS`:

```
agent-db/
├── bash-master-agent-20260522083000.db
├── bash-master-agent-20260522090000.db
├── go-master-agent-20260522084500.db
└── ...
```

Cada vez que un agente inicia una nueva sesión (nueva meta o reanudación tras pausa larga), crea una base nueva con el timestamp actual. La base anterior se conserva para auditoría.

## Script de rotación

El script `goals/scripts/rotate-agent-db.sh` se encarga de eliminar las bases más antiguas, conservando las últimas `MAX_KEEP` (por defecto 5) por cada agente.

### Uso manual

```bash
# Simulación (sin borrar)
bash goals/scripts/rotate-agent-db.sh --dry-run

# Rotación real conservando las últimas 5 bases
bash goals/scripts/rotate-agent-db.sh

# Conservar solo las últimas 3 bases
bash goals/scripts/rotate-agent-db.sh --max-keep 3

# Especificar un directorio de bases distinto
bash goals/scripts/rotate-agent-db.sh --db-dir /ruta/personalizada/agent-db
```

### Funcionamiento interno

1. Lista todos los archivos `.db` en `agent-db/`.
2. Agrupa por prefijo de agente (extraído del nombre base hasta el último guion antes del timestamp).
3. Ordena cada grupo por timestamp descendente (el más reciente primero).
4. Si hay más de `MAX_KEEP` archivos en un grupo, elimina los más antiguos.
5. En modo `--dry-run`, solo imprime qué eliminaría sin ejecutar.

## Integración con cron

Para mantener el directorio limpio sin intervención, se puede añadir una entrada al crontab del usuario que ejecuta MANTIS:

```cron
# Rotar bases de agentes cada día a las 03:00 UTC
0 3 * * * bash /ruta/mantis/goals/scripts/rotate-agent-db.sh >> /var/log/mantis/rotate-db.log 2>&1
```

## Recuperación de bases rotadas

Si se necesita recuperar datos de una base rotada, el historial de metas en `goals/completed.yaml` contiene los resúmenes de contabilidad. Además, cada agente almacena en su base más reciente los datos de la meta actual; solo las bases de sesiones antiguas y cerradas son candidatas a rotación. Si se requiere información completa, se recomienda:

1. Revisar `goals/completed.yaml` para contabilidad agregada.
2. Si la base aún no fue rotada, consultarla directamente con `sqlite3`.
3. Si fue rotada, buscar en backups o en los logs del orquestador (que deberían contener las métricas finales).

## Configuración de `MAX_KEEP`

- **5**: valor por defecto, adecuado para desarrollo activo (conserva ~1 día de sesiones horarias).
- **10**: recomendado si se requiere auditoría fina de cada meta.
- **1**: solo para entornos de CI efímeros donde no se necesita historial local.

---

> **Nota**: Las bases SQLite contienen datos operativos (estado de meta, tokens, tiempo). La rotación no debe ejecutarse mientras un agente está activo. El script no verifica esto automáticamente; coordinar con el orquestador para pausar asignaciones durante la rotación programada.
