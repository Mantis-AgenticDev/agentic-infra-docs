---
artifact_id: "goals-c9-failure-diagnosis-runbook-v2"
artifact_type: "runbook"
version: "2.0.0"
constraints_mapped: ["C9"]
canonical_path: "goals/runbooks/c9-failure-diagnosis.md"
tier: 1
immutable: false
language_lock: "pt-BR"
prompt_hash: "sha256:c9-failure-v2.0.0"
generated_at: "2026-05-22T09:40:00Z"
domain: "goals"
subdomain: "runbooks"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---

# Diagnóstico de Fallos A2A (C9) – v2.0.0

## Herramienta principal

```bash
python3 goals/scripts/check_a2a_contract.py --task-id <id> --agent <agent> [--json]
```

## Flujo de diagnóstico

1. Ejecutar el validador. Si hay errores, clasificar según la salida.
2. **`status.json` ausente**: el agente no finalizó. Verificar heartbeat con `health_check_agents.py`.
3. **JSON inválido**: el archivo no cumple el JSON Schema (`goals/schemas/status.schema.json`). Revisar manualmente.
4. **Inconsistencia de `trace_id`**: el `trace_id` de `status.json` no coincide con `trace.json`. Usar `contract_parser.py` para diagnóstico.

## Recuperación

- Si el agente sigue activo, esperar.
- Si falló, reasignar la meta con nuevo `trace.json` generado por `HandoffPackage.create_context()`.
