---
artifact_id: "goals-system-readme"
artifact_type: "system_documentation"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/check-a2a-contract.sh --domain goals --json"
canonical_path: "goals/README.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:goals-readme-v1.0.0"
generated_at: "2026-05-21T16:15:00Z"
tenant_context: "nao_aplicavel"
language: "pt-BR"
domain: "goals"
subdomain: "system_docs"
agent_role: "documentador"
agent_specialty: "governança-metas"
ai_navigation:
  read_first: true
  required_for: ["goal-execution", "a2a-handoff", "agent-autonomy"]
  update_frequency: monthly
  compatible_models: ["qwen", "deepseek", "claude", "minimax", "mimo-xiaomi", "gpt-4", "gemini"]
audience: ["master-agents", "orchestrator-engine", "human-architects", "deepseek-auditora"]
status: "✅ Estável"
next_review: "2026-06-20"
license: "CC-BY-NC-SA-4.0"
---

# Sistema de Metas `goals/` — MANTIS Agentic

El sistema `goals/` es el **motor de autonomía** del ecosistema MANTIS. Permite que los agentes maestros persigan objetivos declarativos, se comuniquen entre sí mediante el contrato C9 y mantengan trazabilidad completa sin intervención humana continua.

## Componentes

| Archivo/Carpeta | Propósito |
|-----------------|-----------|
| `registry.yaml` | Registro central de metas activas con prioridades y versionado optimista (CAS). |
| `completed.yaml` | Bitácora append-only de metas finalizadas. |
| `budget.yaml` | Presupuestos de tokens/tiempo por agente. |
| `continuation/default.md` | Prompt canónico de continuación para handoffs A2A. |
| `judge/` | Juez opcional para validación de calidad y decisiones ambiguas. |
| `templates/` | Esquemas base de `trace.json` y `status.json` para handoffs. |
| `scripts/` | Scripts de validación (`validate-registry.py`, `check-a2a-contract.sh`, etc.) y operaciones (`rotate-agent-db.sh`, `health-check-agents.py`). |
| `runbooks/` | Documentación operativa: protocolo de locks, rotación de bases, diagnóstico de fallos C9. |

## Flujo de trabajo básico

1. Se define una meta en `registry.yaml` con prioridad, agente asignado y presupuesto.
2. El agente adquiere la meta (lock CAS sobre el registro) y genera su propia base `agent-db/<agent>.db`.
3. Durante la ejecución, si necesita ayuda de otro agente, emite un handoff C9 con `trace.json`.
4. El nuevo agente retoma usando `continuation/default.md` y `status.json`, validando el contrato con `check-a2a-contract.sh`.
5. Al finalizar, la meta se mueve a `completed.yaml` y se libera el lock.

## Seguridad y gobernanza

- **Lock con TTL**: evita apropiaciones eternas.
- **Versionado optimista**: detecta modificaciones concurrentes en `registry.yaml`.
- **Validación de contracto C9**: `check-a2a-contract.sh` garantiza que cada handoff cumpla la estructura canónica.
- **Rotación de bases**: `scripts/rotate-agent-db.sh` mantiene el espacio controlado.

## Auditoría

Toda acción queda registrada en el `MantisLog` de cada agente y en los archivos de bitácora. La auditora puede revisar la Chronique y las banderas de gobernanza.

---

*Documento generado según normas C1-C9, modo B1, multi-lenguaje. DeepSeek, Auditora Agéntica. 2026-05-21.*

---

