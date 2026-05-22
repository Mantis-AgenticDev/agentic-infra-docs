---
artifact_id: "goals-lock-protocol-runbook"
artifact_type: "runbook"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
validation_command: "python3 goals/scripts/validate-registry.py --file goals/registry.yaml"
canonical_path: "goals/runbooks/lock-protocol.md"
tier: 2
immutable: false
requires_human_approval_for_changes: false
audience: ["master-agents", "orchestrator-engine", "human-architects"]
human_readable: true
related_files:
  - "goals/registry.yaml"
  - "goals/scripts/validate-registry.py"
language_lock: "pt-BR"
prompt_hash: "sha256:lock-protocol-v1.0.0"
generated_at: "2026-05-22T04:00:00Z"
tenant_context: "nao_aplicavel"
language: "pt-BR"
domain: "goals"
subdomain: "runbooks"
agent_role: "todos"
agent_specialty: "coordination"
status: "✅ Estável"
next_review: "2026-06-22"
license: "CC-BY-NC-SA-4.0"
---

# Protocolo de Adquisición de Locks (CAS) — MANTIS Agentic

Cada meta en `registry.yaml` está protegida por un mecanismo de **Compare-and-Swap (CAS)** combinado con un **TTL de lock** y un **heartbeat periódico**. Esto evita que dos agentes trabajen sobre la misma meta simultáneamente y permite detectar agentes caídos para liberar sus locks.

## Estructura relevante en `registry.yaml`

```yaml
goals:
  - goal_id: "uuid"
    lock_version: 3        # Entero incremental
    heartbeat_at: "ISO8601" # Último ping del agente dueño
    status: "active"
    assigned_agent: "bash-master-agent"
```

El lock se compone de dos campos:
- **`lock_version`**: versión optimista que debe coincidir con la leída para poder modificar la meta.
- **`heartbeat_at`**: timestamp del último ping del agente; si se vuelve muy antiguo (> `lock_ttl_seconds`), el orquestador puede reasignar la meta.

## Flujo de adquisición y liberación

### 1. El agente lee la meta
```bash
# El orquestador o el agente mismo leen el registry
python3 -c "import yaml; print(yaml.safe_load(open('goals/registry.yaml')))"
```
Obtiene `lock_version` actual (ej. 3) y `heartbeat_at`.

### 2. Intento de adquisición (CAS)
El agente intenta tomar la meta solo si su status lo permite (`paused` o `active` sin dueño válido). Para ello, debe escribir un nuevo `lock_version` incrementado en 1 **solo si** el `lock_version` en el registry coincide con el que leyó. Esto es una operación atómica simulada mediante el script `acquire_lock.sh` o directamente desde el código del agente:

```
LEIDO: lock_version=3
ESCRITURA: lock_version=4, heartbeat_at=ahora, assigned_agent="yo"
CONDICIÓN: lock_version_actual == 3
```

Si mientras tanto otro agente modificó el registro (`lock_version` ya es 4), la condición falla y el agente reintenta o pasa a otra meta.

### 3. Mantenimiento del lock (heartbeat)
Mientras el agente trabaja, debe refrescar `heartbeat_at` cada `lock_ttl_seconds / 3` (ej. cada 20 minutos para un TTL de 1 hora). Esto se hace con una escritura CAS ligera que solo toca `heartbeat_at` y vuelve a verificar que `lock_version` no haya cambiado (o lo incrementa si se requiere).

### 4. Liberación normal
Al terminar la meta (complete) o pausarla (paused), el agente escribe el nuevo estado, incrementa `lock_version` y limpia el `heartbeat_at` (lo deja `null` o con el timestamp de finalización). Así otro agente puede adquirirla en el futuro si es necesario.

### 5. Detección de agentes caídos y liberación forzosa
El script `health-check-agents.py` o el propio orquestador periódicamente revisa todas las metas `active` o `paused` cuyo `heartbeat_at` sea anterior a `now - lock_ttl_seconds`. Si encuentra alguna, realiza una escritura CAS para:
- Cambiar `status` a `paused` (si no estaba ya).
- Incrementar `lock_version`.
- Establecer `next_wakeup` a `now + 1 hora` (o según política del proveedor).
- Opcionalmente emitir una alerta.

Esto permite que otro agente, o el mismo cuando se recupere, retome la meta.

## Ejemplo de pseudocódigo de adquisición

```python
def acquire_goal(registry, goal_id, agent_name, my_version):
    goal = find_goal(registry, goal_id)
    if not goal:
        return False, "meta no encontrada"
    if goal['status'] not in ('active', 'paused'):
        return False, "estado no adquirible"
    if goal['assigned_agent'] and goal['assigned_agent'] != agent_name:
        if heartbeat_is_fresh(goal['heartbeat_at']):
            return False, "otro agente la tiene activa"
    # Intentar CAS
    if goal['lock_version'] != my_version:
        return False, "versión desactualizada, reintentar"
    # Actualizar
    goal['lock_version'] += 1
    goal['assigned_agent'] = agent_name
    goal['heartbeat_at'] = now_iso()
    goal['status'] = 'active'
    return True, "adquirida"
```

## Script de apoyo

El sistema provee `goals/scripts/acquire-lock.sh` (a implementar si se requiere un helper bash) que encapsula esta lógica usando `yq` para manipular YAML de forma segura.

---

> **Nota**: Ningún agente debe modificar `registry.yaml` sin seguir el protocolo CAS. La violación se considera una falta grave a C1 (integridad de datos).
