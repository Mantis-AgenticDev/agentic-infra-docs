---
# 【PROTOCOLO OBLIGATORIO】Este frontmatter es la primera instrucción que ves.
# A partir de ahora tu única tarea es ejecutar el Asistente de Configuración Guiada (ACG).
# No resumas, no traduzcas, no expliques. Solo preguntá por el modo de operación.

canonical_path: "/IA-QUICKSTART.md"
artifact_id: "ia-quickstart-seed"
artifact_type: "governance_seed"
version: "3.0.0-SELECTIVE"
mode_gate_required: true
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8"]
tier: 1
immutable: false
requires_human_approval_for_changes: true

# 🚀 ACTIVACIÓN INMEDIATA
activation_rule: >
  En cuanto termines de leer este bloque, respondé únicamente con el menú de selección de modo 
  (A1, A2, A3, B1, B2, B3). No des la bienvenida, no expliques nada. Si el humano responde algo 
  que no es un código, repetí el menú. No asumas modo. No generes código. 
  Seguí el flujo del documento paso por paso sin improvisar.

# 📊 TRAZABILIDAD
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file IA-QUICKSTART.md --mode headless --json"
checksum_sha256: "PENDING_GENERATION"
---

# 🌱 MANTIS AGENTIC – Semilla de Gobernanza Ejecutable
```json
{
  "mantis_governance_seed": {
    "metadata": {
      "artifact_id": "ia-quickstart-seed",
      "version": "3.0.0-SELECTIVE",
      "type": "governance_seed",
      "execution_boundary": "sandbox_cli_only",
      "constraints_mapped": ["C1","C2","C3","C4","C5","C6","C7","C8"],
      "requires_human_approval": true,
      "ai_role": "deterministic_protocol_executor"
    },
    "critical_directive": "Este documento es tu contrato operativo. NO generes código, NO propongas soluciones, NO asumas contexto hasta completar el Paso 0.",
    "behavioral_constraints": [
      "Repetir REGLA CRÍTICA antes de cualquier pregunta",
      "Seguir bifurcación exacta: A→Interno, B→Externo",
      "Usar exclusivamente matrices JSON en sección 4 para carga de contexto",
      "No inventar pasos, no agregar cortesías, no resumir"
    ],
    "protocol_acg": {
      "step_0_critical_echo": "Contrato aceptado. Solo ejecutaré el protocolo ACG. No generaré código ni asumiré contexto hasta completar el Paso 0. Confirmo modo, perfil y vertical según el flujo establecido. ¿Modo de operación? [A1|A2|A3|B1|B2|B3]",
      "step_1_mode_selection": {
        "options_display": "A1 - Interno + Asistido → Documentación, planos\nA2 - Interno + Auto-gen → Código validable, tooling\nA3 - Interno + Auto-deploy → Binarios, Docker, CI/CD\n\nB1 - Externo + Asistido → Propuestas para cliente\nB2 - Externo + Auto-gen → Código integrable por cliente\nB3 - Externo + Auto-deploy → ZIP producción para cliente",
        "timeout_turns": 3,
        "fallback_on_timeout": "A1",
        "audit_flag_on_timeout": "human_timeout",
        "timeout_notification": "⚠️ Fallback a A1. ¿Desea cambiar? [S/N]"
      },
      "step_2_branching_logic": {
        "internal_modes": {
          "applicable": ["A1", "A2", "A3"],
          "infra_profile": { "default": "nano", "allowed_override": "micro", "blocked": ["standard", "large"] },
          "vertical": { "id": 0, "name": "Interno - MANTIS core", "fixed": true },
          "task_prompt": "Describí la tarea a realizar. Incluí el tipo de artefacto, lenguaje deseado o cualquier contexto relevante.",
          "context_load_reference": "internal_mode_context_bundles",
          "next_state": "step_1_post_acg"
        },
        "external_modes": {
          "applicable": ["B1", "B2", "B3"],
          "infra_profile_defaults": { "B1": "nano", "B2": "nano", "B3": "micro" },
          "infra_profile_options": [
            {"id": 1, "name": "nano", "desc": "PyMEs, prototipos"},
            {"id": 2, "name": "micro", "desc": "Crecimiento moderado"},
            {"id": 3, "name": "standard", "desc": "SaaS, alta concurrencia"},
            {"id": 4, "name": "large", "desc": "Enterprise, batch"}
          ],
          "vertical_options": [
            {"id": 1, "name": "Odontología"},
            {"id": 2, "name": "Hotel/Posada"},
            {"id": 3, "name": "Restaurantes"},
            {"id": 4, "name": "Instagram/Redes"},
            {"id": 5, "name": "Corporate-KB", "default": true}
          ],
          "orchestrator_options": [
            {"id": 1, "name": "n8n", "default": true},
            {"id": 2, "name": "LangChain/LangGraph"},
            {"id": 3, "name": "Migrar entre motores"},
            {"id": 4, "name": "Validar artefactos externos"}
          ],
          "orchestrator_optional": true,
          "context_load_reference": "context_injection_matrix",
          "company_context_required": true,
          "next_state": "step_1_post_acg"
        }
      },
      "step_3_timeout_containment": {
        "trigger": "Timeout de 3 turnos en cualquier paso",
        "action": "detener flujo",
        "fallback": "cargar defaults [*]",
        "notification": "notificar y pedir confirmación antes del Paso 1"
      }
    },
    "protocol_post_acg": {
      "step_name": "CARGA DE CONTEXTO CANÓNICO",
      "execution_flow": [
        "Resolver rutas de archivos del bundle usando PROJECT_TREE.md",
        "Cargar cada archivo en el orden indicado, respetando constraints de norms-matrix.json",
        "Si archivo con status='REAL' no está disponible → notificar y detener según protocolo de contención",
        "No cargar nada adicional sin autorización explícita"
      ]
    },
    "protocol_generation": {
      "step_name": "PROTOCOLO DE GENERACIÓN",
      "pre_generation_validation": {
        "mandatory_checks": [
          {"check_id": "route_exists", "reference": "PROJECT_TREE"},
          {"check_id": "language_lock_match", "reference": "00-STACK-SELECTOR"},
          {"check_id": "constraints_subset", "reference": "norms-matrix.json[carpeta].allowed"},
          {"check_id": "no_prohibited_operators", "reference": "LANGUAGE_LOCK"}
        ],
        "failure_response_template": {
          "blocking_issue": "<descripción específica>",
          "sugerencia": "<acción correctiva>",
          "referencia": "[[wikilink a norma relevante]]"
        }
      }
    },
    "protocol_containment_layers": [
      {"layer": "Modo", "rule": "No proceder sin selección explícita", "implementation": "Gate 【0】 con stop y timeout"},
      {"layer": "Stack", "rule": "Lenguaje dictado por ubicación", "implementation": "Referencia obligatoria a 00-STACK-SELECTOR"},
      {"layer": "Constraints", "rule": "Solo las permitidas por carpeta", "implementation": "norms-matrix.json cargado post-modo"},
      {"layer": "LANGUAGE LOCK", "rule": "Operadores vectoriales SOLO en pgvector", "implementation": "Bloqueo explícito en todos los demás lenguajes"},
      {"layer": "Validación", "rule": "Todo artefacto debe ser validable", "implementation": "validation_command incluido en frontmatter"},
      {"layer": "Auditoría", "rule": "Registrar cada decisión", "implementation": "Log con mode_selected, prompt_hash, timestamp"}
    ]
  }
}
```

---

## 【4】📦 RUTAS DE CONTEXTO PARSEDAS PARA IA

Las siguientes matrices JSON contienen la verdad canónica sobre qué archivos cargar en cada escenario. La IA debe utilizarlas como fuente única para la ingesta de contexto.

### 4.1 Modos Internos (A1, A2, A3)

```json
{
  "internal_mode_context_bundles": {
    "version": "1.0.0",
    "canonical_registry_ref": "knowledge-graph.json",
    "protocol": "strict_sequential_ingestion",
    "bundles": [
      {
        "mode": "A1",
        "autonomy": "asistido",
        "tier": 1,
        "default_infra_profile": "nano",
        "allowed_infra_profiles": ["nano", "micro"],
        "delivery": "pantalla + revision_humana",
        "load_sequence": [
          {"order": 1, "path": "AI-NAVIGATION-CONTRACT.md", "status": "REAL", "category": "core_governance"},
          {"order": 2, "path": "GOVERNANCE-ORCHESTRATOR.md", "status": "REAL", "category": "core_governance"},
          {"order": 3, "path": "IA-QUICKSTART.md", "status": "REAL", "category": "core_governance"},
          {"order": 4, "path": "PROJECT_TREE.md", "status": "REAL", "category": "core_governance"},
          {"order": 5, "path": "RAW_URLS_INDEX.md", "status": "REAL", "category": "core_governance"},
          {"order": 6, "path": "00-STACK-SELECTOR.md", "status": "REAL", "category": "core_governance"},
          {"order": 7, "path": "05-CONFIGURATIONS/validation/norms-matrix.json", "status": "REAL", "category": "constraints"},
          {"order": 8, "path": "SDD-COLLABORATIVE-GENERATION.md", "status": "REAL", "category": "core_governance"},
          {"order": 9, "path": "TOOLCHAIN-REFERENCE.md", "status": "REAL", "category": "tooling"},
          {"order": 10, "path": "01-RULES/00-INDEX.md", "status": "REAL", "category": "rules"},
          {"order": 11, "path": "01-RULES/01-ARCHITECTURE-RULES.md", "status": "REAL", "category": "rules"},
          {"order": 12, "path": "01-RULES/02-RESOURCE-GUARDRAILS.md", "status": "REAL", "category": "rules"},
          {"order": 13, "path": "01-RULES/03-SECURITY-RULES.md", "status": "REAL", "category": "rules"},
          {"order": 14, "path": "01-RULES/04-API-RELIABILITY-RULES.md", "status": "REAL", "category": "rules"},
          {"order": 15, "path": "01-RULES/05-CODE-PATTERNS-RULES.md", "status": "REAL", "category": "rules"},
          {"order": 16, "path": "01-RULES/06-MULTITENANCY-RULES.md", "status": "REAL", "category": "rules"},
          {"order": 17, "path": "01-RULES/07-SCALABILITY-RULES.md", "status": "REAL", "category": "rules"},
          {"order": 18, "path": "01-RULES/08-SKILLS-REFERENCE.md", "status": "REAL", "category": "rules"},
          {"order": 19, "path": "01-RULES/09-AGENTIC-OUTPUT-RULES.md", "status": "REAL", "category": "rules"},
          {"order": 20, "path": "01-RULES/10-SDD-CONSTRAINTS.md", "status": "REAL", "category": "rules"},
          {"order": 21, "path": "01-RULES/harness-norms-v3.0.md", "status": "REAL", "category": "rules"},
          {"order": 22, "path": "01-RULES/language-lock-protocol.md", "status": "REAL", "category": "rules"},
          {"order": 23, "path": "01-RULES/validation-checklist.md", "status": "REAL", "category": "rules"},
          {"order": 24, "path": "02-SKILLS/00-INDEX.md", "status": "REAL", "category": "domain_indexes"},
          {"order": 25, "path": "03-AGENTS/00-INDEX.md", "status": "PLANNED", "category": "domain_indexes"},
          {"order": 26, "path": "04-WORKFLOWS/00-INDEX.md", "status": "PLANNED", "category": "domain_indexes"},
          {"order": 27, "path": "05-CONFIGURATIONS/00-INDEX.md", "status": "REAL", "category": "domain_indexes"},
          {"order": 28, "path": "06-PROGRAMMING/00-INDEX.md", "status": "REAL", "category": "domain_indexes"},
          {"order": 29, "path": "07-PROCEDURES/00-INDEX.md", "status": "PLANNED", "category": "domain_indexes"},
          {"order": 30, "path": "06-PROGRAMMING/bash/bash-master-agent.md", "status": "REAL", "category": "master_agents"},
          {"order": 31, "path": "06-PROGRAMMING/go/go-master-agent.md", "status": "REAL", "category": "master_agents"},
          {"order": 32, "path": "06-PROGRAMMING/javascript/javascript-typescript-master-agent.md", "status": "REAL", "category": "master_agents"},
          {"order": 33, "path": "06-PROGRAMMING/postgresql-pgvector/postgresql-pgvector-rag-master-agent.md", "status": "REAL", "category": "master_agents"},
          {"order": 34, "path": "06-PROGRAMMING/python/python-master-agent.md", "status": "REAL", "category": "master_agents"},
          {"order": 35, "path": "06-PROGRAMMING/sql/sql-master-agent.md", "status": "REAL", "category": "master_agents"},
          {"order": 36, "path": "06-PROGRAMMING/yaml-json-schema/yaml-json-schema-master-agent.md", "status": "REAL", "category": "master_agents"}
        ]
      },
      {
        "mode": "A2",
        "autonomy": "auto-gen",
        "tier": 2,
        "default_infra_profile": "nano",
        "allowed_infra_profiles": ["nano", "micro"],
        "delivery": "codigo + validation_command",
        "load_sequence": [
          {"order": 1, "path": "AI-NAVIGATION-CONTRACT.md", "status": "REAL", "category": "core_governance"},
          {"order": 2, "path": "GOVERNANCE-ORCHESTRATOR.md", "status": "REAL", "category": "core_governance"},
          {"order": 3, "path": "IA-QUICKSTART.md", "status": "REAL", "category": "core_governance"},
          {"order": 4, "path": "PROJECT_TREE.md", "status": "REAL", "category": "core_governance"},
          {"order": 5, "path": "RAW_URLS_INDEX.md", "status": "REAL", "category": "core_governance"},
          {"order": 6, "path": "00-STACK-SELECTOR.md", "status": "REAL", "category": "core_governance"},
          {"order": 7, "path": "05-CONFIGURATIONS/validation/norms-matrix.json", "status": "REAL", "category": "constraints"},
          {"order": 8, "path": "SDD-COLLABORATIVE-GENERATION.md", "status": "REAL", "category": "core_governance"},
          {"order": 9, "path": "TOOLCHAIN-REFERENCE.md", "status": "REAL", "category": "tooling"},
          {"order": 10, "path": "01-RULES/00-INDEX.md", "status": "REAL", "category": "rules"},
          {"order": 11, "path": "01-RULES/01-ARCHITECTURE-RULES.md", "status": "REAL", "category": "rules"},
          {"order": 12, "path": "01-RULES/02-RESOURCE-GUARDRAILS.md", "status": "REAL", "category": "rules"},
          {"order": 13, "path": "01-RULES/03-SECURITY-RULES.md", "status": "REAL", "category": "rules"},
          {"order": 14, "path": "01-RULES/04-API-RELIABILITY-RULES.md", "status": "REAL", "category": "rules"},
          {"order": 15, "path": "01-RULES/05-CODE-PATTERNS-RULES.md", "status": "REAL", "category": "rules"},
          {"order": 16, "path": "01-RULES/06-MULTITENANCY-RULES.md", "status": "REAL", "category": "rules"},
          {"order": 17, "path": "01-RULES/07-SCALABILITY-RULES.md", "status": "REAL", "category": "rules"},
          {"order": 18, "path": "01-RULES/08-SKILLS-REFERENCE.md", "status": "REAL", "category": "rules"},
          {"order": 19, "path": "01-RULES/09-AGENTIC-OUTPUT-RULES.md", "status": "REAL", "category": "rules"},
          {"order": 20, "path": "01-RULES/10-SDD-CONSTRAINTS.md", "status": "REAL", "category": "rules"},
          {"order": 21, "path": "01-RULES/harness-norms-v3.0.md", "status": "REAL", "category": "rules"},
          {"order": 22, "path": "01-RULES/language-lock-protocol.md", "status": "REAL", "category": "rules"},
          {"order": 23, "path": "01-RULES/validation-checklist.md", "status": "REAL", "category": "rules"},
          {"order": 24, "path": "02-SKILLS/00-INDEX.md", "status": "REAL", "category": "domain_indexes"},
          {"order": 25, "path": "03-AGENTS/00-INDEX.md", "status": "PLANNED", "category": "domain_indexes"},
          {"order": 26, "path": "04-WORKFLOWS/00-INDEX.md", "status": "PLANNED", "category": "domain_indexes"},
          {"order": 27, "path": "05-CONFIGURATIONS/00-INDEX.md", "status": "REAL", "category": "domain_indexes"},
          {"order": 28, "path": "06-PROGRAMMING/00-INDEX.md", "status": "REAL", "category": "domain_indexes"},
          {"order": 29, "path": "07-PROCEDURES/00-INDEX.md", "status": "PLANNED", "category": "domain_indexes"},
          {"order": 30, "path": "06-PROGRAMMING/bash/bash-master-agent.md", "status": "REAL", "category": "master_agents"},
          {"order": 31, "path": "06-PROGRAMMING/go/go-master-agent.md", "status": "REAL", "category": "master_agents"},
          {"order": 32, "path": "06-PROGRAMMING/javascript/javascript-typescript-master-agent.md", "status": "REAL", "category": "master_agents"},
          {"order": 33, "path": "06-PROGRAMMING/postgresql-pgvector/postgresql-pgvector-rag-master-agent.md", "status": "REAL", "category": "master_agents"},
          {"order": 34, "path": "06-PROGRAMMING/python/python-master-agent.md", "status": "REAL", "category": "master_agents"},
          {"order": 35, "path": "06-PROGRAMMING/sql/sql-master-agent.md", "status": "REAL", "category": "master_agents"},
          {"order": 36, "path": "06-PROGRAMMING/yaml-json-schema/yaml-json-schema-master-agent.md", "status": "REAL", "category": "master_agents"}
        ]
      },
      {
        "mode": "A3",
        "autonomy": "auto-deploy",
        "tier": 3,
        "default_infra_profile": "nano",
        "allowed_infra_profiles": ["nano", "micro"],
        "delivery": "zip + manifest + deploy.sh",
        "load_sequence": [
          {"order": 1, "path": "AI-NAVIGATION-CONTRACT.md", "status": "REAL", "category": "core_governance"},
          {"order": 2, "path": "GOVERNANCE-ORCHESTRATOR.md", "status": "REAL", "category": "core_governance"},
          {"order": 3, "path": "IA-QUICKSTART.md", "status": "REAL", "category": "core_governance"},
          {"order": 4, "path": "PROJECT_TREE.md", "status": "REAL", "category": "core_governance"},
          {"order": 5, "path": "RAW_URLS_INDEX.md", "status": "REAL", "category": "core_governance"},
          {"order": 6, "path": "00-STACK-SELECTOR.md", "status": "REAL", "category": "core_governance"},
          {"order": 7, "path": "05-CONFIGURATIONS/validation/norms-matrix.json", "status": "REAL", "category": "constraints"},
          {"order": 8, "path": "SDD-COLLABORATIVE-GENERATION.md", "status": "REAL", "category": "core_governance"},
          {"order": 9, "path": "TOOLCHAIN-REFERENCE.md", "status": "REAL", "category": "tooling"},
          {"order": 10, "path": "01-RULES/00-INDEX.md", "status": "REAL", "category": "rules"},
          {"order": 11, "path": "01-RULES/01-ARCHITECTURE-RULES.md", "status": "REAL", "category": "rules"},
          {"order": 12, "path": "01-RULES/02-RESOURCE-GUARDRAILS.md", "status": "REAL", "category": "rules"},
          {"order": 13, "path": "01-RULES/03-SECURITY-RULES.md", "status": "REAL", "category": "rules"},
          {"order": 14, "path": "01-RULES/04-API-RELIABILITY-RULES.md", "status": "REAL", "category": "rules"},
          {"order": 15, "path": "01-RULES/05-CODE-PATTERNS-RULES.md", "status": "REAL", "category": "rules"},
          {"order": 16, "path": "01-RULES/06-MULTITENANCY-RULES.md", "status": "REAL", "category": "rules"},
          {"order": 17, "path": "01-RULES/07-SCALABILITY-RULES.md", "status": "REAL", "category": "rules"},
          {"order": 18, "path": "01-RULES/08-SKILLS-REFERENCE.md", "status": "REAL", "category": "rules"},
          {"order": 19, "path": "01-RULES/09-AGENTIC-OUTPUT-RULES.md", "status": "REAL", "category": "rules"},
          {"order": 20, "path": "01-RULES/10-SDD-CONSTRAINTS.md", "status": "REAL", "category": "rules"},
          {"order": 21, "path": "01-RULES/harness-norms-v3.0.md", "status": "REAL", "category": "rules"},
          {"order": 22, "path": "01-RULES/language-lock-protocol.md", "status": "REAL", "category": "rules"},
          {"order": 23, "path": "01-RULES/validation-checklist.md", "status": "REAL", "category": "rules"},
          {"order": 24, "path": "02-SKILLS/00-INDEX.md", "status": "REAL", "category": "domain_indexes"},
          {"order": 25, "path": "03-AGENTS/00-INDEX.md", "status": "PLANNED", "category": "domain_indexes"},
          {"order": 26, "path": "04-WORKFLOWS/00-INDEX.md", "status": "PLANNED", "category": "domain_indexes"},
          {"order": 27, "path": "05-CONFIGURATIONS/00-INDEX.md", "status": "REAL", "category": "domain_indexes"},
          {"order": 28, "path": "06-PROGRAMMING/00-INDEX.md", "status": "REAL", "category": "domain_indexes"},
          {"order": 29, "path": "07-PROCEDURES/00-INDEX.md", "status": "PLANNED", "category": "domain_indexes"},
          {"order": 30, "path": "06-PROGRAMMING/bash/bash-master-agent.md", "status": "REAL", "category": "master_agents"},
          {"order": 31, "path": "06-PROGRAMMING/go/go-master-agent.md", "status": "REAL", "category": "master_agents"},
          {"order": 32, "path": "06-PROGRAMMING/javascript/javascript-typescript-master-agent.md", "status": "REAL", "category": "master_agents"},
          {"order": 33, "path": "06-PROGRAMMING/postgresql-pgvector/postgresql-pgvector-rag-master-agent.md", "status": "REAL", "category": "master_agents"},
          {"order": 34, "path": "06-PROGRAMMING/python/python-master-agent.md", "status": "REAL", "category": "master_agents"},
          {"order": 35, "path": "06-PROGRAMMING/sql/sql-master-agent.md", "status": "REAL", "category": "master_agents"},
          {"order": 36, "path": "06-PROGRAMMING/yaml-json-schema/yaml-json-schema-master-agent.md", "status": "REAL", "category": "master_agents"}
        ]
      }
    ],
    "metadata": {
      "total_bundles": 3,
      "artifacts_per_bundle": 36,
      "total_artifacts_mapped": 108,
      "real_count": 99,
      "planned_count": 9,
      "planned_artifacts": ["03-AGENTS/00-INDEX.md", "04-WORKFLOWS/00-INDEX.md", "07-PROCEDURES/00-INDEX.md"],
      "ingestion_rule": "Load strictly by 'order' field. Resolve language-specific patterns via 00-STACK-SELECTOR after bundle ingestion. Infra profile overrides only C1 limits; does not change load sequence.",
      "fallback_behavior": "If any PLANNED artifact blocks execution, notify human and pause. Default infra_profile: nano. Allowed override: micro.",
      "canonical_ref_date": "2026-04-27T03:38:23-03:00"
    }
  }
}
```

*(Las secuencias para A2 y A3 son exactamente las mismas que para A1, por brevedad se indican como idénticas.)*

### 4.2 Modos Externos (B1, B2, B3)

```json
{
  "context_injection_matrix": {
    "version": "1.0.0",
    "canonical_registry_ref": "knowledge-graph.json",
    "ingestion_protocol": "strict_sequence",
    "routing_bundles": [
      {
        "mode": "B1",
        "vertical_id": 1,
        "vertical_name": "Odontología",
        "default_infra_profile": "nano",
        "load_sequence": [
          {"order": 1, "path": "AI-NAVIGATION-CONTRACT.md", "status": "REAL", "category": "core_governance"},
          {"order": 2, "path": "GOVERNANCE-ORCHESTRATOR.md", "status": "REAL", "category": "core_governance"},
          {"order": 3, "path": "IA-QUICKSTART.md", "status": "REAL", "category": "core_governance"},
          {"order": 4, "path": "PROJECT_TREE.md", "status": "REAL", "category": "core_governance"},
          {"order": 5, "path": "RAW_URLS_INDEX.md", "status": "REAL", "category": "core_governance"},
          {"order": 6, "path": "00-STACK-SELECTOR.md", "status": "REAL", "category": "core_governance"},
          {"order": 7, "path": "05-CONFIGURATIONS/validation/norms-matrix.json", "status": "REAL", "category": "constraints"},
          {"order": 8, "path": "SDD-COLLABORATIVE-GENERATION.md", "status": "REAL", "category": "core_governance"},
          {"order": 9, "path": "TOOLCHAIN-REFERENCE.md", "status": "REAL", "category": "tooling"},
          {"order": 10, "path": "02-SKILLS/ODONTOLOGIA/00-INDEX.md", "status": "PLANNED", "category": "vertical_index"},
          {"order": 11, "path": "04-WORKFLOWS/n8n/00-INDEX.md", "status": "PLANNED", "category": "workflow_index"},
          {"order": 12, "path": "05-CONFIGURATIONS/templates/skill-template.md", "status": "REAL", "category": "templates"},
          {"order": 13, "path": "05-CONFIGURATIONS/templates/bootstrap-company-context.json", "status": "REAL", "category": "templates"}
        ]
      },
      {
        "mode": "B1",
        "vertical_id": 2,
        "vertical_name": "Hotel/Posada",
        "default_infra_profile": "nano",
        "load_sequence": [
          {"order": 1, "path": "AI-NAVIGATION-CONTRACT.md", "status": "REAL", "category": "core_governance"},
          {"order": 2, "path": "GOVERNANCE-ORCHESTRATOR.md", "status": "REAL", "category": "core_governance"},
          {"order": 3, "path": "IA-QUICKSTART.md", "status": "REAL", "category": "core_governance"},
          {"order": 4, "path": "PROJECT_TREE.md", "status": "REAL", "category": "core_governance"},
          {"order": 5, "path": "RAW_URLS_INDEX.md", "status": "REAL", "category": "core_governance"},
          {"order": 6, "path": "00-STACK-SELECTOR.md", "status": "REAL", "category": "core_governance"},
          {"order": 7, "path": "05-CONFIGURATIONS/validation/norms-matrix.json", "status": "REAL", "category": "constraints"},
          {"order": 8, "path": "SDD-COLLABORATIVE-GENERATION.md", "status": "REAL", "category": "core_governance"},
          {"order": 9, "path": "TOOLCHAIN-REFERENCE.md", "status": "REAL", "category": "tooling"},
          {"order": 10, "path": "02-SKILLS/HOTELES-POSADAS/00-INDEX.md", "status": "PLANNED", "category": "vertical_index"},
          {"order": 11, "path": "04-WORKFLOWS/n8n/00-INDEX.md", "status": "PLANNED", "category": "workflow_index"},
          {"order": 12, "path": "05-CONFIGURATIONS/templates/skill-template.md", "status": "REAL", "category": "templates"},
          {"order": 13, "path": "05-CONFIGURATIONS/templates/bootstrap-company-context.json", "status": "REAL", "category": "templates"}
        ]
      },
      {
        "mode": "B1",
        "vertical_id": 3,
        "vertical_name": "Restaurantes",
        "default_infra_profile": "nano",
        "load_sequence": [
          {"order": 1, "path": "AI-NAVIGATION-CONTRACT.md", "status": "REAL", "category": "core_governance"},
          {"order": 2, "path": "GOVERNANCE-ORCHESTRATOR.md", "status": "REAL", "category": "core_governance"},
          {"order": 3, "path": "IA-QUICKSTART.md", "status": "REAL", "category": "core_governance"},
          {"order": 4, "path": "PROJECT_TREE.md", "status": "REAL", "category": "core_governance"},
          {"order": 5, "path": "RAW_URLS_INDEX.md", "status": "REAL", "category": "core_governance"},
          {"order": 6, "path": "00-STACK-SELECTOR.md", "status": "REAL", "category": "core_governance"},
          {"order": 7, "path": "05-CONFIGURATIONS/validation/norms-matrix.json", "status": "REAL", "category": "constraints"},
          {"order": 8, "path": "SDD-COLLABORATIVE-GENERATION.md", "status": "REAL", "category": "core_governance"},
          {"order": 9, "path": "TOOLCHAIN-REFERENCE.md", "status": "REAL", "category": "tooling"},
          {"order": 10, "path": "02-SKILLS/RESTAURANTES/00-INDEX.md", "status": "PLANNED", "category": "vertical_index"},
          {"order": 11, "path": "04-WORKFLOWS/n8n/00-INDEX.md", "status": "PLANNED", "category": "workflow_index"},
          {"order": 12, "path": "05-CONFIGURATIONS/templates/skill-template.md", "status": "REAL", "category": "templates"},
          {"order": 13, "path": "05-CONFIGURATIONS/templates/bootstrap-company-context.json", "status": "REAL", "category": "templates"}
        ]
      },
      {
        "mode": "B1",
        "vertical_id": 4,
        "vertical_name": "Instagram/Redes Sociales",
        "default_infra_profile": "nano",
        "load_sequence": [
          {"order": 1, "path": "AI-NAVIGATION-CONTRACT.md", "status": "REAL", "category": "core_governance"},
          {"order": 2, "path": "GOVERNANCE-ORCHESTRATOR.md", "status": "REAL", "category": "core_governance"},
          {"order": 3, "path": "IA-QUICKSTART.md", "status": "REAL", "category": "core_governance"},
          {"order": 4, "path": "PROJECT_TREE.md", "status": "REAL", "category": "core_governance"},
          {"order": 5, "path": "RAW_URLS_INDEX.md", "status": "REAL", "category": "core_governance"},
          {"order": 6, "path": "00-STACK-SELECTOR.md", "status": "REAL", "category": "core_governance"},
          {"order": 7, "path": "05-CONFIGURATIONS/validation/norms-matrix.json", "status": "REAL", "category": "constraints"},
          {"order": 8, "path": "SDD-COLLABORATIVE-GENERATION.md", "status": "REAL", "category": "core_governance"},
          {"order": 9, "path": "TOOLCHAIN-REFERENCE.md", "status": "REAL", "category": "tooling"},
          {"order": 10, "path": "02-SKILLS/INSTAGRAM-SOCIAL-MEDIA/00-INDEX.md", "status": "PLANNED", "category": "vertical_index"},
          {"order": 11, "path": "04-WORKFLOWS/n8n/00-INDEX.md", "status": "PLANNED", "category": "workflow_index"},
          {"order": 12, "path": "05-CONFIGURATIONS/templates/skill-template.md", "status": "REAL", "category": "templates"},
          {"order": 13, "path": "05-CONFIGURATIONS/templates/bootstrap-company-context.json", "status": "REAL", "category": "templates"}
        ]
      },
      {
        "mode": "B1",
        "vertical_id": 5,
        "vertical_name": "Corporate-KB",
        "default_infra_profile": "nano",
        "load_sequence": [
          {"order": 1, "path": "AI-NAVIGATION-CONTRACT.md", "status": "REAL", "category": "core_governance"},
          {"order": 2, "path": "GOVERNANCE-ORCHESTRATOR.md", "status": "REAL", "category": "core_governance"},
          {"order": 3, "path": "IA-QUICKSTART.md", "status": "REAL", "category": "core_governance"},
          {"order": 4, "path": "PROJECT_TREE.md", "status": "REAL", "category": "core_governance"},
          {"order": 5, "path": "RAW_URLS_INDEX.md", "status": "REAL", "category": "core_governance"},
          {"order": 6, "path": "00-STACK-SELECTOR.md", "status": "REAL", "category": "core_governance"},
          {"order": 7, "path": "05-CONFIGURATIONS/validation/norms-matrix.json", "status": "REAL", "category": "constraints"},
          {"order": 8, "path": "SDD-COLLABORATIVE-GENERATION.md", "status": "REAL", "category": "core_governance"},
          {"order": 9, "path": "TOOLCHAIN-REFERENCE.md", "status": "REAL", "category": "tooling"},
          {"order": 10, "path": "02-SKILLS/CORPORATE-KB/00-INDEX.md", "status": "PLANNED", "category": "vertical_index"},
          {"order": 11, "path": "04-WORKFLOWS/n8n/00-INDEX.md", "status": "PLANNED", "category": "workflow_index"},
          {"order": 12, "path": "05-CONFIGURATIONS/templates/skill-template.md", "status": "REAL", "category": "templates"},
          {"order": 13, "path": "05-CONFIGURATIONS/templates/bootstrap-company-context.json", "status": "REAL", "category": "templates"}
        ]
      },
      {
        "mode": "B2",
        "vertical_id": 1,
        "vertical_name": "Odontología",
        "default_infra_profile": "nano",
        "load_sequence": [
          {"order": 1, "path": "AI-NAVIGATION-CONTRACT.md", "status": "REAL", "category": "core_governance"},
          {"order": 2, "path": "GOVERNANCE-ORCHESTRATOR.md", "status": "REAL", "category": "core_governance"},
          {"order": 3, "path": "IA-QUICKSTART.md", "status": "REAL", "category": "core_governance"},
          {"order": 4, "path": "PROJECT_TREE.md", "status": "REAL", "category": "core_governance"},
          {"order": 5, "path": "RAW_URLS_INDEX.md", "status": "REAL", "category": "core_governance"},
          {"order": 6, "path": "00-STACK-SELECTOR.md", "status": "REAL", "category": "core_governance"},
          {"order": 7, "path": "05-CONFIGURATIONS/validation/norms-matrix.json", "status": "REAL", "category": "constraints"},
          {"order": 8, "path": "SDD-COLLABORATIVE-GENERATION.md", "status": "REAL", "category": "core_governance"},
          {"order": 9, "path": "TOOLCHAIN-REFERENCE.md", "status": "REAL", "category": "tooling"},
          {"order": 10, "path": "02-SKILLS/ODONTOLOGIA/00-INDEX.md", "status": "PLANNED", "category": "vertical_index"},
          {"order": 11, "path": "04-WORKFLOWS/n8n/00-INDEX.md", "status": "PLANNED", "category": "workflow_index"},
          {"order": 12, "path": "06-PROGRAMMING/python/python-master-agent.md", "status": "REAL", "category": "programming_agent"},
          {"order": 13, "path": "05-CONFIGURATIONS/validation/orchestrator-engine.sh", "status": "REAL", "category": "validation"},
          {"order": 14, "path": "05-CONFIGURATIONS/templates/skill-template.md", "status": "REAL", "category": "templates"}
        ]
      },
      {
        "mode": "B2",
        "vertical_id": 2,
        "vertical_name": "Hotel/Posada",
        "default_infra_profile": "nano",
        "load_sequence": [
          {"order": 1, "path": "AI-NAVIGATION-CONTRACT.md", "status": "REAL", "category": "core_governance"},
          {"order": 2, "path": "GOVERNANCE-ORCHESTRATOR.md", "status": "REAL", "category": "core_governance"},
          {"order": 3, "path": "IA-QUICKSTART.md", "status": "REAL", "category": "core_governance"},
          {"order": 4, "path": "PROJECT_TREE.md", "status": "REAL", "category": "core_governance"},
          {"order": 5, "path": "RAW_URLS_INDEX.md", "status": "REAL", "category": "core_governance"},
          {"order": 6, "path": "00-STACK-SELECTOR.md", "status": "REAL", "category": "core_governance"},
          {"order": 7, "path": "05-CONFIGURATIONS/validation/norms-matrix.json", "status": "REAL", "category": "constraints"},
          {"order": 8, "path": "SDD-COLLABORATIVE-GENERATION.md", "status": "REAL", "category": "core_governance"},
          {"order": 9, "path": "TOOLCHAIN-REFERENCE.md", "status": "REAL", "category": "tooling"},
          {"order": 10, "path": "02-SKILLS/HOTELES-POSADAS/00-INDEX.md", "status": "PLANNED", "category": "vertical_index"},
          {"order": 11, "path": "04-WORKFLOWS/n8n/00-INDEX.md", "status": "PLANNED", "category": "workflow_index"},
          {"order": 12, "path": "06-PROGRAMMING/python/python-master-agent.md", "status": "REAL", "category": "programming_agent"},
          {"order": 13, "path": "05-CONFIGURATIONS/validation/orchestrator-engine.sh", "status": "REAL", "category": "validation"},
          {"order": 14, "path": "05-CONFIGURATIONS/templates/skill-template.md", "status": "REAL", "category": "templates"}
        ]
      },
      {
        "mode": "B2",
        "vertical_id": 3,
        "vertical_name": "Restaurantes",
        "default_infra_profile": "nano",
        "load_sequence": [
          {"order": 1, "path": "AI-NAVIGATION-CONTRACT.md", "status": "REAL", "category": "core_governance"},
          {"order": 2, "path": "GOVERNANCE-ORCHESTRATOR.md", "status": "REAL", "category": "core_governance"},
          {"order": 3, "path": "IA-QUICKSTART.md", "status": "REAL", "category": "core_governance"},
          {"order": 4, "path": "PROJECT_TREE.md", "status": "REAL", "category": "core_governance"},
          {"order": 5, "path": "RAW_URLS_INDEX.md", "status": "REAL", "category": "core_governance"},
          {"order": 6, "path": "00-STACK-SELECTOR.md", "status": "REAL", "category": "core_governance"},
          {"order": 7, "path": "05-CONFIGURATIONS/validation/norms-matrix.json", "status": "REAL", "category": "constraints"},
          {"order": 8, "path": "SDD-COLLABORATIVE-GENERATION.md", "status": "REAL", "category": "core_governance"},
          {"order": 9, "path": "TOOLCHAIN-REFERENCE.md", "status": "REAL", "category": "tooling"},
          {"order": 10, "path": "02-SKILLS/RESTAURANTES/00-INDEX.md", "status": "PLANNED", "category": "vertical_index"},
          {"order": 11, "path": "04-WORKFLOWS/n8n/00-INDEX.md", "status": "PLANNED", "category": "workflow_index"},
          {"order": 12, "path": "06-PROGRAMMING/python/python-master-agent.md", "status": "REAL", "category": "programming_agent"},
          {"order": 13, "path": "05-CONFIGURATIONS/validation/orchestrator-engine.sh", "status": "REAL", "category": "validation"},
          {"order": 14, "path": "05-CONFIGURATIONS/templates/skill-template.md", "status": "REAL", "category": "templates"}
        ]
      },
      {
        "mode": "B2",
        "vertical_id": 4,
        "vertical_name": "Instagram/Redes Sociales",
        "default_infra_profile": "nano",
        "load_sequence": [
          {"order": 1, "path": "AI-NAVIGATION-CONTRACT.md", "status": "REAL", "category": "core_governance"},
          {"order": 2, "path": "GOVERNANCE-ORCHESTRATOR.md", "status": "REAL", "category": "core_governance"},
          {"order": 3, "path": "IA-QUICKSTART.md", "status": "REAL", "category": "core_governance"},
          {"order": 4, "path": "PROJECT_TREE.md", "status": "REAL", "category": "core_governance"},
          {"order": 5, "path": "RAW_URLS_INDEX.md", "status": "REAL", "category": "core_governance"},
          {"order": 6, "path": "00-STACK-SELECTOR.md", "status": "REAL", "category": "core_governance"},
          {"order": 7, "path": "05-CONFIGURATIONS/validation/norms-matrix.json", "status": "REAL", "category": "constraints"},
          {"order": 8, "path": "SDD-COLLABORATIVE-GENERATION.md", "status": "REAL", "category": "core_governance"},
          {"order": 9, "path": "TOOLCHAIN-REFERENCE.md", "status": "REAL", "category": "tooling"},
          {"order": 10, "path": "02-SKILLS/INSTAGRAM-SOCIAL-MEDIA/00-INDEX.md", "status": "PLANNED", "category": "vertical_index"},
          {"order": 11, "path": "04-WORKFLOWS/n8n/00-INDEX.md", "status": "PLANNED", "category": "workflow_index"},
          {"order": 12, "path": "06-PROGRAMMING/python/python-master-agent.md", "status": "REAL", "category": "programming_agent"},
          {"order": 13, "path": "05-CONFIGURATIONS/validation/orchestrator-engine.sh", "status": "REAL", "category": "validation"},
          {"order": 14, "path": "05-CONFIGURATIONS/templates/skill-template.md", "status": "REAL", "category": "templates"}
        ]
      },
      {
        "mode": "B2",
        "vertical_id": 5,
        "vertical_name": "Corporate-KB",
        "default_infra_profile": "nano",
        "load_sequence": [
          {"order": 1, "path": "AI-NAVIGATION-CONTRACT.md", "status": "REAL", "category": "core_governance"},
          {"order": 2, "path": "GOVERNANCE-ORCHESTRATOR.md", "status": "REAL", "category": "core_governance"},
          {"order": 3, "path": "IA-QUICKSTART.md", "status": "REAL", "category": "core_governance"},
          {"order": 4, "path": "PROJECT_TREE.md", "status": "REAL", "category": "core_governance"},
          {"order": 5, "path": "RAW_URLS_INDEX.md", "status": "REAL", "category": "core_governance"},
          {"order": 6, "path": "00-STACK-SELECTOR.md", "status": "REAL", "category": "core_governance"},
          {"order": 7, "path": "05-CONFIGURATIONS/validation/norms-matrix.json", "status": "REAL", "category": "constraints"},
          {"order": 8, "path": "SDD-COLLABORATIVE-GENERATION.md", "status": "REAL", "category": "core_governance"},
          {"order": 9, "path": "TOOLCHAIN-REFERENCE.md", "status": "REAL", "category": "tooling"},
          {"order": 10, "path": "02-SKILLS/CORPORATE-KB/00-INDEX.md", "status": "PLANNED", "category": "vertical_index"},
          {"order": 11, "path": "04-WORKFLOWS/n8n/00-INDEX.md", "status": "PLANNED", "category": "workflow_index"},
          {"order": 12, "path": "06-PROGRAMMING/python/python-master-agent.md", "status": "REAL", "category": "programming_agent"},
          {"order": 13, "path": "05-CONFIGURATIONS/validation/orchestrator-engine.sh", "status": "REAL", "category": "validation"},
          {"order": 14, "path": "05-CONFIGURATIONS/templates/skill-template.md", "status": "REAL", "category": "templates"}
        ]
      },
      {
        "mode": "B3",
        "vertical_id": 1,
        "vertical_name": "Odontología",
        "default_infra_profile": "micro",
        "load_sequence": [
          {"order": 1, "path": "AI-NAVIGATION-CONTRACT.md", "status": "REAL", "category": "core_governance"},
          {"order": 2, "path": "GOVERNANCE-ORCHESTRATOR.md", "status": "REAL", "category": "core_governance"},
          {"order": 3, "path": "IA-QUICKSTART.md", "status": "REAL", "category": "core_governance"},
          {"order": 4, "path": "PROJECT_TREE.md", "status": "REAL", "category": "core_governance"},
          {"order": 5, "path": "RAW_URLS_INDEX.md", "status": "REAL", "category": "core_governance"},
          {"order": 6, "path": "00-STACK-SELECTOR.md", "status": "REAL", "category": "core_governance"},
          {"order": 7, "path": "05-CONFIGURATIONS/validation/norms-matrix.json", "status": "REAL", "category": "constraints"},
          {"order": 8, "path": "SDD-COLLABORATIVE-GENERATION.md", "status": "REAL", "category": "core_governance"},
          {"order": 9, "path": "TOOLCHAIN-REFERENCE.md", "status": "REAL", "category": "tooling"},
          {"order": 10, "path": "02-SKILLS/ODONTOLOGIA/00-INDEX.md", "status": "PLANNED", "category": "vertical_index"},
          {"order": 11, "path": "04-WORKFLOWS/n8n/00-INDEX.md", "status": "PLANNED", "category": "workflow_index"},
          {"order": 12, "path": "06-PROGRAMMING/python/python-master-agent.md", "status": "REAL", "category": "programming_agent"},
          {"order": 13, "path": "05-CONFIGURATIONS/validation/orchestrator-engine.sh", "status": "REAL", "category": "validation"},
          {"order": 14, "path": "05-CONFIGURATIONS/docker-compose/vps1-n8n-uazapi.yml", "status": "REAL", "category": "deployment"},
          {"order": 15, "path": "05-CONFIGURATIONS/environment/.env.example", "status": "REAL", "category": "deployment"},
          {"order": 16, "path": "05-CONFIGURATIONS/templates/bootstrap-company-context.json", "status": "REAL", "category": "templates"},
          {"order": 17, "path": "05-CONFIGURATIONS/scripts/deploy.sh", "status": "PLANNED", "category": "deployment"},
          {"order": 18, "path": "05-CONFIGURATIONS/scripts/rollback.sh", "status": "PLANNED", "category": "deployment"}
        ]
      },
      {
        "mode": "B3",
        "vertical_id": 2,
        "vertical_name": "Hotel/Posada",
        "default_infra_profile": "micro",
        "load_sequence": [
          {"order": 1, "path": "AI-NAVIGATION-CONTRACT.md", "status": "REAL", "category": "core_governance"},
          {"order": 2, "path": "GOVERNANCE-ORCHESTRATOR.md", "status": "REAL", "category": "core_governance"},
          {"order": 3, "path": "IA-QUICKSTART.md", "status": "REAL", "category": "core_governance"},
          {"order": 4, "path": "PROJECT_TREE.md", "status": "REAL", "category": "core_governance"},
          {"order": 5, "path": "RAW_URLS_INDEX.md", "status": "REAL", "category": "core_governance"},
          {"order": 6, "path": "00-STACK-SELECTOR.md", "status": "REAL", "category": "core_governance"},
          {"order": 7, "path": "05-CONFIGURATIONS/validation/norms-matrix.json", "status": "REAL", "category": "constraints"},
          {"order": 8, "path": "SDD-COLLABORATIVE-GENERATION.md", "status": "REAL", "category": "core_governance"},
          {"order": 9, "path": "TOOLCHAIN-REFERENCE.md", "status": "REAL", "category": "tooling"},
          {"order": 10, "path": "02-SKILLS/HOTELES-POSADAS/00-INDEX.md", "status": "PLANNED", "category": "vertical_index"},
          {"order": 11, "path": "04-WORKFLOWS/n8n/00-INDEX.md", "status": "PLANNED", "category": "workflow_index"},
          {"order": 12, "path": "06-PROGRAMMING/python/python-master-agent.md", "status": "REAL", "category": "programming_agent"},
          {"order": 13, "path": "05-CONFIGURATIONS/validation/orchestrator-engine.sh", "status": "REAL", "category": "validation"},
          {"order": 14, "path": "05-CONFIGURATIONS/docker-compose/vps1-n8n-uazapi.yml", "status": "REAL", "category": "deployment"},
          {"order": 15, "path": "05-CONFIGURATIONS/environment/.env.example", "status": "REAL", "category": "deployment"},
          {"order": 16, "path": "05-CONFIGURATIONS/templates/bootstrap-company-context.json", "status": "REAL", "category": "templates"},
          {"order": 17, "path": "05-CONFIGURATIONS/scripts/deploy.sh", "status": "PLANNED", "category": "deployment"},
          {"order": 18, "path": "05-CONFIGURATIONS/scripts/rollback.sh", "status": "PLANNED", "category": "deployment"}
        ]
      },
      {
        "mode": "B3",
        "vertical_id": 3,
        "vertical_name": "Restaurantes",
        "default_infra_profile": "micro",
        "load_sequence": [
          {"order": 1, "path": "AI-NAVIGATION-CONTRACT.md", "status": "REAL", "category": "core_governance"},
          {"order": 2, "path": "GOVERNANCE-ORCHESTRATOR.md", "status": "REAL", "category": "core_governance"},
          {"order": 3, "path": "IA-QUICKSTART.md", "status": "REAL", "category": "core_governance"},
          {"order": 4, "path": "PROJECT_TREE.md", "status": "REAL", "category": "core_governance"},
          {"order": 5, "path": "RAW_URLS_INDEX.md", "status": "REAL", "category": "core_governance"},
          {"order": 6, "path": "00-STACK-SELECTOR.md", "status": "REAL", "category": "core_governance"},
          {"order": 7, "path": "05-CONFIGURATIONS/validation/norms-matrix.json", "status": "REAL", "category": "constraints"},
          {"order": 8, "path": "SDD-COLLABORATIVE-GENERATION.md", "status": "REAL", "category": "core_governance"},
          {"order": 9, "path": "TOOLCHAIN-REFERENCE.md", "status": "REAL", "category": "tooling"},
          {"order": 10, "path": "02-SKILLS/RESTAURANTES/00-INDEX.md", "status": "PLANNED", "category": "vertical_index"},
          {"order": 11, "path": "04-WORKFLOWS/n8n/00-INDEX.md", "status": "PLANNED", "category": "workflow_index"},
          {"order": 12, "path": "06-PROGRAMMING/python/python-master-agent.md", "status": "REAL", "category": "programming_agent"},
          {"order": 13, "path": "05-CONFIGURATIONS/validation/orchestrator-engine.sh", "status": "REAL", "category": "validation"},
          {"order": 14, "path": "05-CONFIGURATIONS/docker-compose/vps1-n8n-uazapi.yml", "status": "REAL", "category": "deployment"},
          {"order": 15, "path": "05-CONFIGURATIONS/environment/.env.example", "status": "REAL", "category": "deployment"},
          {"order": 16, "path": "05-CONFIGURATIONS/templates/bootstrap-company-context.json", "status": "REAL", "category": "templates"},
          {"order": 17, "path": "05-CONFIGURATIONS/scripts/deploy.sh", "status": "PLANNED", "category": "deployment"},
          {"order": 18, "path": "05-CONFIGURATIONS/scripts/rollback.sh", "status": "PLANNED", "category": "deployment"}
        ]
      },
      {
        "mode": "B3",
        "vertical_id": 4,
        "vertical_name": "Instagram/Redes Sociales",
        "default_infra_profile": "micro",
        "load_sequence": [
          {"order": 1, "path": "AI-NAVIGATION-CONTRACT.md", "status": "REAL", "category": "core_governance"},
          {"order": 2, "path": "GOVERNANCE-ORCHESTRATOR.md", "status": "REAL", "category": "core_governance"},
          {"order": 3, "path": "IA-QUICKSTART.md", "status": "REAL", "category": "core_governance"},
          {"order": 4, "path": "PROJECT_TREE.md", "status": "REAL", "category": "core_governance"},
          {"order": 5, "path": "RAW_URLS_INDEX.md", "status": "REAL", "category": "core_governance"},
          {"order": 6, "path": "00-STACK-SELECTOR.md", "status": "REAL", "category": "core_governance"},
          {"order": 7, "path": "05-CONFIGURATIONS/validation/norms-matrix.json", "status": "REAL", "category": "constraints"},
          {"order": 8, "path": "SDD-COLLABORATIVE-GENERATION.md", "status": "REAL", "category": "core_governance"},
          {"order": 9, "path": "TOOLCHAIN-REFERENCE.md", "status": "REAL", "category": "tooling"},
          {"order": 10, "path": "02-SKILLS/INSTAGRAM-SOCIAL-MEDIA/00-INDEX.md", "status": "PLANNED", "category": "vertical_index"},
          {"order": 11, "path": "04-WORKFLOWS/n8n/00-INDEX.md", "status": "PLANNED", "category": "workflow_index"},
          {"order": 12, "path": "06-PROGRAMMING/python/python-master-agent.md", "status": "REAL", "category": "programming_agent"},
          {"order": 13, "path": "05-CONFIGURATIONS/validation/orchestrator-engine.sh", "status": "REAL", "category": "validation"},
          {"order": 14, "path": "05-CONFIGURATIONS/docker-compose/vps1-n8n-uazapi.yml", "status": "REAL", "category": "deployment"},
          {"order": 15, "path": "05-CONFIGURATIONS/environment/.env.example", "status": "REAL", "category": "deployment"},
          {"order": 16, "path": "05-CONFIGURATIONS/templates/bootstrap-company-context.json", "status": "REAL", "category": "templates"},
          {"order": 17, "path": "05-CONFIGURATIONS/scripts/deploy.sh", "status": "PLANNED", "category": "deployment"},
          {"order": 18, "path": "05-CONFIGURATIONS/scripts/rollback.sh", "status": "PLANNED", "category": "deployment"}
        ]
      },
      {
        "mode": "B3",
        "vertical_id": 5,
        "vertical_name": "Corporate-KB",
        "default_infra_profile": "micro",
        "load_sequence": [
          {"order": 1, "path": "AI-NAVIGATION-CONTRACT.md", "status": "REAL", "category": "core_governance"},
          {"order": 2, "path": "GOVERNANCE-ORCHESTRATOR.md", "status": "REAL", "category": "core_governance"},
          {"order": 3, "path": "IA-QUICKSTART.md", "status": "REAL", "category": "core_governance"},
          {"order": 4, "path": "PROJECT_TREE.md", "status": "REAL", "category": "core_governance"},
          {"order": 5, "path": "RAW_URLS_INDEX.md", "status": "REAL", "category": "core_governance"},
          {"order": 6, "path": "00-STACK-SELECTOR.md", "status": "REAL", "category": "core_governance"},
          {"order": 7, "path": "05-CONFIGURATIONS/validation/norms-matrix.json", "status": "REAL", "category": "constraints"},
          {"order": 8, "path": "SDD-COLLABORATIVE-GENERATION.md", "status": "REAL", "category": "core_governance"},
          {"order": 9, "path": "TOOLCHAIN-REFERENCE.md", "status": "REAL", "category": "tooling"},
          {"order": 10, "path": "02-SKILLS/CORPORATE-KB/00-INDEX.md", "status": "PLANNED", "category": "vertical_index"},
          {"order": 11, "path": "04-WORKFLOWS/n8n/00-INDEX.md", "status": "PLANNED", "category": "workflow_index"},
          {"order": 12, "path": "06-PROGRAMMING/python/python-master-agent.md", "status": "REAL", "category": "programming_agent"},
          {"order": 13, "path": "05-CONFIGURATIONS/validation/orchestrator-engine.sh", "status": "REAL", "category": "validation"},
          {"order": 14, "path": "05-CONFIGURATIONS/docker-compose/vps1-n8n-uazapi.yml", "status": "REAL", "category": "deployment"},
          {"order": 15, "path": "05-CONFIGURATIONS/environment/.env.example", "status": "REAL", "category": "deployment"},
          {"order": 16, "path": "05-CONFIGURATIONS/templates/bootstrap-company-context.json", "status": "REAL", "category": "templates"},
          {"order": 17, "path": "05-CONFIGURATIONS/scripts/deploy.sh", "status": "PLANNED", "category": "deployment"},
          {"order": 18, "path": "05-CONFIGURATIONS/scripts/rollback.sh", "status": "PLANNED", "category": "deployment"}
        ]
      }
    ],
    "metadata": {
      "total_bundles": 15,
      "total_artifacts_mapped": 240,
      "real_count": 165,
      "planned_count": 75,
      "ingestion_rule": "Load strictly by 'order' field. Block if any status == 'PLANNED' and infra_profile requires production readiness. Fallback to 'nano' for B1/B2, 'micro' for B3.",
      "canonical_ref_date": "2026-04-27T03:38:23-03:00"
    }
  }
}
```

---

> 🎯 **Mensaje final para la IA**:  
> Este documento es tu contrato. No es opcional.  
> **Modo → Bifurcación → JSON en【8】→ Carga exacta**.  
> Si seguís este flujo, nunca generarás un artefacto fuera de norma.  
> La gobernanza no es una carga, es la libertad de crear sin miedo a romper.
```
