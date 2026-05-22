---
artifact_id: "goals-c9-failure-diagnosis-runbook"
artifact_type: "runbook"
version: "1.0.0"
constraints_mapped: ["C9"]
validation_command: "bash goals/scripts/check-a2a-contract.sh --task-id $TASK_ID --agent $AGENT_NAME --json"
canonical_path: "goals/runbooks/c9-failure-diagnosis.md"
tier: 1
immutable: false
requires_human_approval_for_changes: true
audience: ["master-agents", "orchestrator-engine", "human-architects"]
human_readable: true
related_files:
  - "01-RULES/11-A2A-COMMUNICATION-RULES.md"
  - "goals/scripts/check-a2a-contract.sh"
  - "goals/templates/trace.json"
  - "goals/templates/status.json"
language_lock: "pt-BR"
prompt_hash: "sha256:c9-failure-diagnosis-v1.0.0"
generated_at: "2026-05-22T05:00:00Z"
tenant_context: "nao_aplicavel"
language: "pt-BR"
domain: "goals"
subdomain: "runbooks"
agent_role: "todos"
agent_specialty: "a2a-troubleshooting"
status: "✅ Estável"
next_review: "2026-06-22"
license: "CC-BY-NC-SA-4.0"
---

# Diagnóstico de Fallos A2A (C9) — MANTIS Agentic

Cuando un handoff entre agentes maestros falla la validación C9, el sistema bloquea la transferencia para proteger la integridad de la traza. Este runbook permite diagnosticar y corregir el fallo rápidamente, sin comprometer la cadena de agentes.

## Impacto de un fallo C9

- **Handoff bloqueado**: el siguiente agente no recibe el contexto y no puede iniciar.
- **Meta detenida**: si es una cadena secuencial, toda la meta queda en pausa hasta resolver.
- **Posible corrupción de traza**: si se fuerza el handoff sin validar, se pierde la rastreabilidad entre agentes.

## Categorías de fallo

| Categoría | Severidad | Síntoma | Causa probable |
|-----------|-----------|---------|----------------|
| `status.json` ausente | Crítica | El agente finalizó pero no generó el archivo | Error del agente, cierre forzoso, fallo de escritura |
| `trace_id` inconsistente | Crítica | El `trace_id` del `status.json` no coincide con el del `trace.json` original | El agente usó un `trace_id` incorrecto o corrompió el archivo |
| `span_id` duplicado | Alta | Dos agentes generaron el mismo `span_id` | Colisión de UUID (extremadamente raro) o reutilización de contexto sin regenerar |
| `span_id` o `trace_id` con formato inválido | Alta | No es un UUID v4 válido | Error de generación en el agente |
| `status` no es `completed` ni `failed` | Alta | El agente escribió un estado no estándar | Bug en el agente |
| `parent_span_id` no coincide | Alta | El `parent_span_id` no apunta al `span_id` real del agente anterior | El orquestador pasó mal el contexto |
| Campos opcionales faltantes | Baja | `a2a_contract_version`, `next_agent_hint` ausentes | Omisión menor, no bloqueante |
| `agent_id` no coincide con `--agent` | Baja | El `status.json` fue escrito por un agente distinto al esperado | Error de configuración o reasignación |

## Flujo de diagnóstico

### 1. Ejecutar el validador

```bash
bash goals/scripts/check-a2a-contract.sh --task-id <id> --agent <agent-name> --json
```

El script retorna un JSON con `status`, `errors` y `warnings`. Guardar esta salida.

### 2. Clasificar la severidad

- Si hay **errores críticos** (`status.json` ausente, `trace_id` inconsistente): **no continuar**. El handoff debe bloquearse.
- Si hay **errores altos** (`span_id` inválido, `status` no estándar): **bloquear** y solicitar reejecución del agente anterior o regeneración del contexto.
- Si solo hay **warnings** (campos opcionales faltantes, `agent_id` divergente): **permitir** el handoff con advertencia, registrar el incidente.

### 3. Diagnóstico por categoría

#### `status.json` ausente

```bash
# Verificar si el directorio de artefactos existe
ls -la goals/task-<id>/artifacts/<agent>/

# Verificar si el agente dejó logs
cat goals/task-<id>/artifacts/<agent>/*.log 2>/dev/null || echo "sin logs"

# Verificar si el agente sigue activo (heartbeat)
python3 goals/scripts/health-check-agents.py --json | jq '.unhealthy_agents[] | select(.goal_id == "<goal_id>")'
```

**Acción correctiva**:
1. Si el agente sigue activo, esperar a que termine y genere `status.json`.
2. Si el agente falló (status `failed` en registry), reasignar la meta o regenerar el contexto.
3. Si el agente desapareció sin dejar rastro, tratar como agente caído y reasignar con nuevo `trace.json`.

#### `trace_id` inconsistente

```bash
# Comparar trace_id en ambos archivos
echo "trace.json: $(jq -r '.trace_id' goals/task-<id>/context/trace.json)"
echo "status.json: $(jq -r '.trace_id' goals/task-<id>/artifacts/<agent>/status.json)"
```

**Acción correctiva**:
1. Si el `status.json` tiene un `trace_id` distinto pero válido, el agente usó un contexto equivocado. Regenerar `trace.json` con el `trace_id` correcto (el del `status.json`) y reiniciar el handoff.
2. Si el `status.json` tiene un `trace_id` inválido, el agente corrompió el contexto. Rechazar el `status.json` y reejecutar el agente con el `trace.json` original.

#### `span_id` duplicado o inválido

```bash
# Verificar unicidad del span_id en toda la cadena
grep -r "span_id" goals/task-<id>/ --include="*.json"
```

**Acción correctiva**:
1. Si es duplicado, regenerar el `span_id` en el `status.json` (operación manual controlada).
2. Si es inválido, el agente debe reejecutar la generación del `span_id` (no se puede parchear manualmente).

#### `parent_span_id` no coincide

```bash
# Trazar la cadena completa
cat goals/task-<id>/context/trace.json | jq '.'
cat goals/task-<id>/artifacts/<agent-anterior>/status.json | jq '.span_id'
cat goals/task-<id>/artifacts/<agent-actual>/status.json | jq '.parent_span_id'
```

**Acción correctiva**:
1. Corregir el `parent_span_id` en el `trace.json` del agente actual para que coincida con el `span_id` real del agente anterior.
2. Verificar que el orquestador esté propagando correctamente los `span_id` entre handoffs.

## Herramientas de diagnóstico

| Herramienta | Propósito |
|-------------|-----------|
| `check-a2a-contract.sh` | Validación primaria del contrato |
| `jq` | Inspección y manipulación de JSON |
| `health-check-agents.py` | Verificar si el agente emisor sigue vivo |
| `grep -r` en `goals/task-<id>/` | Rastrear todos los archivos de la tarea |
| Logs del orquestador | Ver el historial de handoffs intentados |

## Ejemplo de sesión de diagnóstico

```bash
$ bash goals/scripts/check-a2a-contract.sh --task-id task-456 --agent js-ts-agent --json
{
  "status": "error",
  "errors": [
    "trace_id inconsistente entre trace.json y status.json",
    "parent_span_id ausente en status.json"
  ]
}

# Inspeccionar
$ jq -r '.trace_id' goals/task-456/context/trace.json
550e8400-e29b-41d4-a716-446655440000

$ jq -r '.trace_id' goals/task-456/artifacts/js-ts-agent/status.json
660e8400-e29b-41d4-a716-446655440001

# Diagnóstico: el agente usó otro trace_id. Posible reutilización de contexto viejo.
# Acción: regenerar trace.json con el trace_id del status.json
$ cat > goals/task-456/context/trace.json <<EOF
{"trace_id":"660e8400-e29b-41d4-a716-446655440001","parent_span_id":"...","current_agent":"js-ts-agent","task_id":"task-456","timestamp_injected":"2026-05-22T05:00:00Z"}
EOF

# Revalidar
$ bash goals/scripts/check-a2a-contract.sh --task-id task-456 --agent js-ts-agent --json
{"status":"ok","message":"C9 compliant"}
```

---

> **Nota**: Ningún agente debe intentar "saltarse" una validación C9 fallida. Si el fallo persiste tras tres intentos de corrección, se debe escalar al arquitecto humano. La integridad de la traza es más importante que la velocidad de ejecución.
