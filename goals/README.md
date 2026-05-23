---
artifact_id: "goals-system-readme-v2"
artifact_type: "system_documentation"
version: "2.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
validation_command: "python3 goals/scripts/check_a2a_contract.py --help"
canonical_path: "goals/README.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:goals-readme-v2.0.0"
generated_at: "2026-05-22T09:00:00Z"
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
  compatible_models: ["qwen", "deepseek", "claude", "minimax", "mimo-xiaomi", "gpt-4", "gemini", "grok"]
audience: ["master-agents", "orchestrator-engine", "human-architects", "deepseek-auditora"]
status: "✅ Estável"
next_review: "2026-07-22"
license: "CC-BY-NC-SA-4.0"
---

# Sistema de Metas `goals/` — MANTIS Agentic v2.0.0

El sistema `goals/` es el **motor de autonomía** del ecosistema MANTIS. Permite que los agentes maestros persigan objetivos declarativos, se comuniquen entre sí mediante el contrato C9 y mantengan trazabilidad completa sin intervención humana continua.

## Novedades en v2.0.0

- **`registry.db` (SQLite)** reemplaza a `registry.yaml`. ACID real, CAS atómico, cero riesgo de corrupción.
- **Librerías `libs/`** para segmentación de contexto, hidratación bajo demanda y parsing de contratos.
- **Esquemas JSON** en `schemas/` para validación estricta de `status.json`, `trace.json` y salida del juez.
- **`provider-policies.yaml`** centraliza las políticas de recarga de cada proveedor IA.
- **Runtimes** desacoplados en `runtimes/` con configuración propia para cada sistema (Hermes, Claude Code, Antigravity, etc.).
- **Scripts 100% Python** con TUI amigable (gracias a `rich`) y logs en `goals/logs/`.

## Estructura

```
goals/
├── registry.db                   # BD transaccional (CAS, heartbeats, presupuestos)
├── completed.yaml                # Bitácora append-only de metas finalizadas
├── budget.yaml                   # Presupuestos por agente
├── provider-policies.yaml        # Políticas de recarga por proveedor (2026)
├── logs/                         # Logs de auditoría y validación
├── agent-db/                     # Bases SQLite individuales por agente (Singleton)
├── schemas/                      # JSON Schemas (status, trace, judge-output)
├── scripts/                      # Scripts Python del sistema
│   ├── init_registry.py          # Inicializa registry.db
│   ├── check_a2a_contract.py     # Validador C9
│   ├── rotate_agent_db.py        # Rotación segura de bases
│   ├── health_check_agents.py    # Heartbeats
│   └── validate_registry.py      # Integridad de registry.db
├── libs/                         # Librerías de segmentación/hidratación
│   ├── registry_client.py        # Cliente SQLite sin SQL expuesto
│   ├── context_segmenter.py      # Trocea el contexto para evitar pérdida
│   ├── prompt_builder.py         # Construye prompts mínimos
│   ├── contract_parser.py        # Valida trace/status con JSON Schema
│   ├── quota_parser.py           # Calcula next_wakeup
│   ├── handoff_package.py        # Empaqueta contexto A2A
│   └── log_reader.py             # Lee logs estructurados
├── templates/                    # trace.json y status.json base
├── continuation/default.md       # Prompt de continuación (sin lógica de cuotas)
├── judge/                        # Juez de calidad (config + prompt)
└── runbooks/                     # Documentación operativa
```

## Flujo de trabajo básico

1. Se inserta una meta en `registry.db` (vía `RegistryClient` o manualmente).
2. El agente adquiere la meta con `acquire_goal` (CAS atómico sobre SQLite).
3. El agente trabaja y escribe su progreso en `goals/agent-db/<agent>.db`.
4. Al finalizar, emite `status.json` (validado con `check_a2a_contract.py`) y libera la meta.
5. Si se agota el presupuesto, el `QuotaParser` calcula `next_wakeup` y la meta se pausa.
6. El dashboard o el observer notifican al humano vía Telegram.

## Integración con runtimes

Cada runtime (Hermes, Codex, Antigravity, etc.) tiene su configuración en `runtimes/<sistema>/`. Un `connector.py` traduce las metas del `registry.db` al formato nativo del sistema y viceversa. Ver `runtimes/*/MANTIS-PROTOCOL.md` para más detalles.

---

*Documento generado según normas C1-C9, modo B1, multi-lenguaje. DeepSeek, Auditora Agéntica. 2026-05-22.*
