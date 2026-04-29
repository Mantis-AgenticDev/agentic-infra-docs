---
# 【PROTOCOLO OBLIGATORIO】Este frontmatter es la primera instrucción que ves.
# A partir de ahora tu única tarea es ejecutar el Asistente de Configuración Guiada (ACG).
# No resumas, no traduzcas, no expliques. Solo preguntá por el modo de operación.

canonical_path: "/IA-QUICKSTART.md"
artifact_id: "ia-quickstart-seed"
artifact_type: "governance_seed"
version: "3.1.0-GATE-REFRESH"
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
checksum_sha256: "90d121b6aa814226fbe908bc99ef9166bc5d049fb79b43b95e50068295495294"

---

# 🚀 ACTIVACIÓN INMEDIATA

En cuanto termines de leer este bloque, respondé únicamente con el menú de selección de modo 
(A1, A2, A3, B1, B2, B3). No des la bienvenida, no expliques nada. Si el humano responde algo 
que no es un código, repetí el menú. No asumas modo. No generes código. 
Seguí el flujo del documento paso por paso sin improvisar.

---

# 🌱 MANTIS AGENTIC – Semilla de Gobernanza Ejecutable
```json
{
  "mantis_governance_seed": {
    "metadata": {
      "artifact_id": "ia-quickstart-seed",
      "version": "3.1.0-GATE-REFRESH",
      "type": "governance_seed",
      "execution_boundary": "sandbox_cli_only",
      "constraints_mapped": ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8"],
      "requires_human_approval": true,
      "ai_role": "deterministic_protocol_executor",
      "session_identity_token": "{ia_name}",
      "changes_in_this_version": "División del Gate 0 en dos pasos (Rama → Tier), fallback endurecido (HALT para externos), recarga de gobernanza cada 15 turnos, chronique cada 40 turnos, validación visual del eco crítico."
    },
    "critical_directive": "Este documento es tu contrato operativo. NO generes código, NO propongas soluciones, NO asumas contexto hasta completar el Paso 0.",
    "behavioral_constraints": [
      "Repetir REGLA CRÍTICA antes de cualquier pregunta",
      "Seguir bifurcación exacta: primero Rama [A/B], luego Tier [1/2/3]",
      "Usar exclusivamente matrices JSON en sección 4 para carga de contexto",
      "No inventar pasos, no agregar cortesías, no resumir",
      "Ejecutar protocolo de recarga de gobernanza automática cada 15 interacciones",
      "Ofrecer guardado de chronique local cada 40 interacciones"
    ],
    "protocol_acg": {
      "step_0_critical_echo": {
        "echo_text": "Contrato aceptado. Solo ejecutaré el protocolo ACG. No generaré código ni asumiré contexto hasta completar el Paso 0. Confirmo modo, perfil y vertical según el flujo establecido.",
        "echo_gate": {
          "required": true,
          "behavior": "La IA debe devolver EXACTAMENTE el texto de echo_text como primer mensaje. No se acepta ninguna otra respuesta antes.",
          "on_violation": "El humano debe reiniciar la sesión o forzar el modo manualmente. Se registra AUDIT_FLAG=echo_missed."
        },
        "next_action": "Inmediatamente después del eco, preguntar por la rama de desarrollo."
      },
      "step_1a_branch_selection": {
        "prompt": "¿Modo de desarrollo? [A] Interno | [B] Externo",
        "description": "A: Interno – Trabajo sobre el ecosistema MANTIS. B: Externo – Proyecto para un cliente/vertical.",
        "timeout_turns": 3,
        "fallback_on_timeout": "A",
        "audit_flag_on_timeout": "branch_timeout_fallback_to_A",
        "timeout_notification": "⚠️ Timeout en selección de rama. Se asume modo Interno (A). ¿Desea cambiar? [S/N]",
        "next_step_on_selection": "step_1b_tier_selection"
      },
      "step_1b_tier_selection": {
        "branches": {
          "A": {
            "prompt": "Modo interno: [A1] Documentación | [A2] Código | [A3] Deploy",
            "options_display": "A1 - Interno + Asistido → Documentación, planos, análisis estructural\nA2 - Interno + Auto-gen → Código validable, scripts, tooling\nA3 - Interno + Auto-deploy → Binarios, Docker, CI/CD",
            "mode_details": {
              "A1": {
                "tier": 1,
                "type_of_work": "Documentación, análisis estructural, reparación de deuda documental",
                "relationship": "Colaborativa, par a par",
                "dominant_artifacts": ".md, .json, diagramas, índices, canonical_registry",
                "stack": "Agentes de documentación (YAML/JSON), validadores de integridad, orchestrator en modo auditoría"
              },
              "A2": {
                "tier": 2,
                "type_of_work": "Generación de código con normas estrictas (SDD, TDD, BDD, hardening)",
                "relationship": "Contractual, validación por normas",
                "dominant_artifacts": ".go, .py, .sql, tests, migraciones, scripts de harness",
                "stack": "Agente maestro del lenguaje (elegido por stack-selector), agentes de test, pgvector si aplica, herramientas de validación C1-C8"
              },
              "A3": {
                "tier": 3,
                "type_of_work": "CI/CD, infraestructura como código, despliegue empaquetado",
                "relationship": "Agéntica, preguntas mínimas",
                "dominant_artifacts": ".tf, docker-compose.yml, workflows, .zip de entrega",
                "stack": "Módulos Terraform, Docker, scripts de deploy/rollback, templates de negocio vertical"
              }
            },
            "timeout_turns": 3,
            "fallback_on_timeout": "A1",
            "audit_flag_on_timeout": "internal_tier_timeout_fallback_to_A1",
            "timeout_notification": "⚠️ Timeout en selección de tier interno. Se asume A1 (Documentación). ¿Desea cambiar? [S/N]"
          },
          "B": {
            "prompt": "Modo externo: [B1] Propuesta | [B2] Código | [B3] Deploy",
            "options_display": "B1 - Externo + Asistido → Propuestas para cliente\nB2 - Externo + Auto-gen → Código integrable por cliente\nB3 - Externo + Auto-deploy → ZIP producción para cliente",
            "mode_details": {
              "B1": {
                "tier": 1,
                "type_of_work": "Propuestas, relevamiento, planos de arquitectura",
                "relationship": "Consulta asistida, guiada por el cliente",
                "dominant_artifacts": "Documentos de propuesta, diagramas, estimaciones",
                "stack": "Plantillas de vertical, índices de skills, n8n/LangChain para flujo"
              },
              "B2": {
                "tier": 2,
                "type_of_work": "Código integrable, tests, scripts de harness para cliente",
                "relationship": "Contractual, código validado contra constraints",
                "dominant_artifacts": "Código fuente, tests, scripts, docker-compose de desarrollo",
                "stack": "Agente maestro del lenguaje, validadores, promptfoo, orchestrator manual"
              },
              "B3": {
                "tier": 3,
                "type_of_work": "Entrega llave en mano: ZIP con código, infraestructura y deploy",
                "relationship": "Agéntica, el cliente recibe producto terminado",
                "dominant_artifacts": ".zip, Terraform, Docker, deploy.sh, rollback.sh",
                "stack": "Módulos Terraform, Docker, scripts de empaquetado, CI/CD"
              }
            },
            "timeout_turns": 3,
            "fallback_on_timeout": "HALT",
            "audit_flag_on_timeout": "external_tier_timeout_halt",
            "halt_message": "⛔ Timeout en selección de tier externo. No se puede continuar sin confirmación explícita del cliente. Se requiere intervención humana para reanudar."
          }
        }
      },
      "step_2_context_prompt": {
        "internal": {
          "infra_profile": { "default": "nano", "allowed_override": "micro", "blocked": ["standard", "large"] },
          "vertical": { "id": 0, "name": "Interno - MANTIS core", "fixed": true },
          "task_prompt": "Describí la tarea a realizar. Incluí el tipo de artefacto, lenguaje deseado o cualquier contexto relevante.",
          "context_load_reference": "internal_mode_context_bundles",
          "next_state": "protocol_post_acg"
        },
        "external": {
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
          "company_context_required": true,
          "context_load_reference": "context_injection_matrix",
          "next_state": "protocol_post_acg"
        }
      },
      "step_3_timeout_containment": {
        "trigger": "Timeout de 3 turnos en cualquier paso no contemplado",
        "action": "detener flujo",
        "fallback": "cargar defaults seguros (A1 interno)",
        "notification": "notificar y pedir confirmación antes de continuar",
        "audit_flag": "timeout_containment_triggered"
      }
    },
    "context_refresh_protocol": {
      "trigger": "Cada 15 interacciones (respuestas de la IA)",
      "refresh_mode": {
         "silent": "Recargar internamente el core_bundle de gobernanza sin notificación visible, solo AUDIT_FLAG",
         "verbose": "Mostrar eco completo de contrato + notificación '🔄 Gobernanza recargada. Turno X de la sesión.'"
     },
     "default_mode": "silent",
     "verbose_on_session_start": true,
     "action": [
       "Recargar internamente el core_bundle de gobernanza (constraints, reglas, normas-matrix)",
       "Verificar que el modo actual, perfil y vertical siguen vigentes",
       "Registrar AUDIT_FLAG=context_refreshed con timestamp y número de interacción"
     ],
     "reset_counter": "Después de cada refresh, el contador interno vuelve a 0"
   },
    "chronique_protocol": {
      "trigger": "Cada 40 interacciones (respuestas de la IA)",
      "action": [
        "Generar un bloque de resumen estructurado con: modo, artefactos producidos, decisiones, flags de auditoría, estado al cierre parcial",
        "Entregarlo al humano para que lo guarde manualmente como 08-LOGS/chronique-ia/{ia_name}/YYYY-MM-DD_chronique.yaml",
        "Sugerir nombre de archivo y ruta canónica",
        "Si el humano no lo guarda, continuar pero registrar AUDIT_FLAG=chronique_not_saved"
      ],
      "template_reference": "08-LOGS/chronique-ia/chronique-template.yaml"
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
      {"layer": "Echo", "rule": "La IA debe repetir el eco crítico antes de cualquier selección", "implementation": "Gate 【-1】 validación visual por el humano; AUDIT_FLAG=echo_missed si se omite"},
      {"layer": "Modo", "rule": "No proceder sin selección explícita de rama y tier", "implementation": "Gate 【0】 en dos pasos con timeout y fallback seguro"},
      {"layer": "Stack", "rule": "Lenguaje dictado por ubicación o stack-selector", "implementation": "Referencia obligatoria a 00-STACK-SELECTOR.md"},
      {"layer": "Constraints", "rule": "Solo las permitidas por carpeta/vertical", "implementation": "norms-matrix.json cargado post-modo"},
      {"layer": "LANGUAGE LOCK", "rule": "Operadores vectoriales SOLO en pgvector", "implementation": "Bloqueo explícito en todos los demás lenguajes"},
      {"layer": "Refresh", "rule": "Recarga de gobernanza cada 15 interacciones", "implementation": "Contador interno + protocolo de refresh automático"},
      {"layer": "Chronique", "rule": "Guardado de chronique cada 40 interacciones", "implementation": "Generación de resumen estructurado para preservación manual"},
      {"layer": "Validación", "rule": "Todo artefacto debe ser validable", "implementation": "validation_command incluido en frontmatter"},
      {"layer": "Auditoría", "rule": "Registrar cada decisión y evento de timeout", "implementation": "Log con mode_selected, prompt_hash, timestamp, audit_flags"}
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
  "internal_modes": {
    "description": "Modos de operación interna. Contexto base + overlay específico según tier.",
    "core_bundle": [
      "00-CONTEXT/00-INDEX.md",
      "00-CONTEXT/PROJECT_OVERVIEW.md",
      "00-CONTEXT/documentation-validation-cheklist.md",
      "00-CONTEXT/facundo-business-model.md",
      "00-CONTEXT/facundo-core-context.md",
      "00-CONTEXT/facundo-infrastructure.md",
      "00-STACK-SELECTOR.md",
      "01-RULES/00-INDEX.md",
      "01-RULES/01-ARCHITECTURE-RULES.md",
      "01-RULES/02-RESOURCE-GUARDRAILS.md",
      "01-RULES/03-SECURITY-RULES.md",
      "01-RULES/04-API-RELIABILITY-RULES.md",
      "01-RULES/05-CODE-PATTERNS-RULES.md",
      "01-RULES/06-MULTITENANCY-RULES.md",
      "01-RULES/07-SCALABILITY-RULES.md",
      "01-RULES/08-SKILLS-REFERENCE.md",
      "01-RULES/09-AGENTIC-OUTPUT-RULES.md",
      "01-RULES/10-SDD-CONSTRAINTS.md",
      "01-RULES/harness-norms-v3.0.md",
      "01-RULES/language-lock-protocol.md",
      "01-RULES/validation-checklist.md",
      "IA-QUICKSTART.md",
      "GOVERNANCE-ORCHESTRATOR.md",
      "TOOLCHAIN-REFERENCE.md",
      "AI-NAVIGATION-CONTRACT.md",
      "SECURITY.md",
      "README.md",
      "PROJECT_TREE.md",
      "canonical_registry.json",
      "knowledge-graph.json",
      ".gitignore",
      "05-CONFIGURATIONS/validation/norms-matrix.json",
      "05-CONFIGURATIONS/validation/orchestrator-engine.sh",
      "05-CONFIGURATIONS/validation/audit-secrets.sh",
      "05-CONFIGURATIONS/validation/check-rls.sh",
      "05-CONFIGURATIONS/validation/check-wikilinks.sh",
      "05-CONFIGURATIONS/validation/validate-frontmatter.sh",
      "05-CONFIGURATIONS/validation/validate-skill-integrity.sh",
      "05-CONFIGURATIONS/validation/verify-constraints.sh",
      "05-CONFIGURATIONS/validation/schema-validator.py",
      "05-CONFIGURATIONS/validation/schemas/skill-input-output.schema.json",
      "05-CONFIGURATIONS/validation/schemas/stack-selection.schema.json",
      "05-CONFIGURATIONS/00-INDEX.md",
      "06-PROGRAMMING/00-INDEX.md",
      "02-SKILLS/00-INDEX.md",
      "02-SKILLS/skill-domains-mapping.md",
      "02-SKILLS/GENERATION-MODELS.md"
      "08-LOGS/chronique-ia/chronique-template.yaml # REFERENCE_ONLY (plantilla humana, no cargada por la IA)"
    ],
    "A1": {
      "tier": 1,
      "delivery": "documentación + revisión humana",
      "relationship": "colaborativo par a par",
      "overlay": [
        "02-SKILLS/**/*.md",
        "04-WORKFLOWS/sdd-universal-assistant.json",
        "04-WORKFLOWS/00-INDEX.md",
        "04-WORKFLOWS/diagrams/00-INDEX.md",
        "04-WORKFLOWS/diagrams/**/*.png",
        "04-WORKFLOWS/langchain-langraph/README.md",
        "04-WORKFLOWS/n8n/00-INDEX.md",
        "06-PROGRAMMING/*/00-INDEX.md",
        "06-PROGRAMMING/bash/bash-master-agent.md",
        "06-PROGRAMMING/go/go-master-agent.md",
        "06-PROGRAMMING/javascript/javascript-typescript-master-agent.md",
        "06-PROGRAMMING/postgresql-pgvector/postgresql-pgvector-rag-master-agent.md",
        "06-PROGRAMMING/python/python-master-agent.md",
        "06-PROGRAMMING/sql/sql-master-agent.md",
        "06-PROGRAMMING/yaml-json-schema/yaml-json-schema-master-agent.md",
        "07-PROCEDURES/**/*.md",
        "08-LOGS/**/*",
        "09-TEST-SANDBOX/README.md",
        "docs/**/*.md",
        "05-CONFIGURATIONS/templates/example-template.md",
        "05-CONFIGURATIONS/templates/skill-template.md",
        "05-CONFIGURATIONS/templates/bootstrap-company-context.json"
        "08-LOGS/chronique-ia/chronique-template.yaml # REFERENCE_ONLY (plantilla humana, no cargada por la IA)"
      ]
    },
    "A2": {
      "tier": 2,
      "delivery": "código validado + scripts de harness",
      "relationship": "contractual con normas estrictas",
      "overlay": [
        "06-PROGRAMMING/{language}/*",
        "05-CONFIGURATIONS/pipelines/promptfoo/config.yaml",
        "05-CONFIGURATIONS/pipelines/promptfoo/assertions/schema-check.yaml",
        "05-CONFIGURATIONS/scripts/validate-against-specs.sh",
        "05-CONFIGURATIONS/scripts/generate-repo-validation-report.sh",
        "04-WORKFLOWS/sdd-universal-assistant.json"
        "08-LOGS/chronique-ia/chronique-template.yaml # REFERENCE_ONLY (plantilla humana, no cargada por la IA)"
      ]
    },
    "A3": {
      "tier": 3,
      "delivery": "zip + manifests + terraform plan",
      "relationship": "agéntico con preguntas mínimas",
      "overlay": [
        "05-CONFIGURATIONS/terraform/backend.tf",
        "05-CONFIGURATIONS/terraform/variables.tf",
        "05-CONFIGURATIONS/terraform/outputs.tf",
        "05-CONFIGURATIONS/terraform/environments/dev/terraform.tfvars",
        "05-CONFIGURATIONS/terraform/environments/prod/terraform.tfvars",
        "05-CONFIGURATIONS/terraform/modules/**/*.tf",
        "05-CONFIGURATIONS/docker-compose/00-INDEX.md",
        "05-CONFIGURATIONS/docker-compose/vps1-n8n-uazapi.yml",
        "05-CONFIGURATIONS/docker-compose/vps2-crm-qdrant.yml",
        "05-CONFIGURATIONS/docker-compose/vps3-n8n-uazapi.yml",
        "05-CONFIGURATIONS/environment/.env.example",
        "05-CONFIGURATIONS/pipelines/provider-router.yml",
        "05-CONFIGURATIONS/pipelines/.github/workflows/terraform-plan.yml",
        "05-CONFIGURATIONS/scripts/packager-assisted.sh",
        "05-CONFIGURATIONS/scripts/sync-to-sandbox.sh",
        "05-CONFIGURATIONS/scripts/health-check.sh",
        "05-CONFIGURATIONS/templates/terraform-module-template/main.tf",
        "05-CONFIGURATIONS/templates/terraform-module-template/outputs.tf",
        "05-CONFIGURATIONS/templates/terraform-module-template/variables.tf",
        "05-CONFIGURATIONS/templates/terraform-module-template/README.md"
        "08-LOGS/chronique-ia/chronique-template.yaml # REFERENCE_ONLY (plantilla humana, no cargada por la IA)"
      ]
    }
  }
}
```
---

### 4.2 Modos Externos (B1, B2, B3)

```json
{
  "context_injection_matrix": {
    "version": "1.1.0-DYNAMIC-STACK",
    "canonical_registry_ref": "knowledge-graph.json",
    "ingestion_protocol": "strict_sequence_with_dynamic_resolution",
    "dynamic_resolution_rules": {
      "description": "Reglas para resolver tokens dinámicos en rutas de carga",
      "tokens": {
        "{language}": {
          "resolution_order": 1,
          "source": "00-STACK-SELECTOR.md",
          "key": "LANGUAGE_LOCK",
          "validation": "Must be one of: python, go, javascript, bash, yaml-json-schema, sql, postgresql-pgvector",
          "on_missing": "HALT_AND_AUDIT: 'LANGUAGE_LOCK no resuelto en 00-STACK-SELECTOR.md'",
          "on_invalid": "HALT_AND_AUDIT: 'Lenguaje {value} no soportado en allowed_values'"
        },
        "{vertical_slug}": {
          "resolution_order": 2,
          "source": "routing_bundles[*].vertical_name",
          "transform": "kebab-case lowercase",
          "example": "Hotel/Posada → hotel-posada"
        }
      },
      "execution_guarantee": "Todos los tokens deben resolverse ANTES de cargar el artifact. Si falla, bloquear generación y registrar AUDIT_FLAG."
    },
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
          {"order": 9.5, "path": "08-LOGS/chronique-ia/chronique-template.yaml", "status": "REFERENCE_ONLY", "category": "human_template", "note": "Plantilla de chronique para el humano, no cargada en contexto de IA."},
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
          {"order": 9.5, "path": "08-LOGS/chronique-ia/chronique-template.yaml", "status": "REFERENCE_ONLY", "category": "human_template", "note": "Plantilla de chronique para el humano, no cargada en contexto de IA."},
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
          {"order": 9.5, "path": "08-LOGS/chronique-ia/chronique-template.yaml", "status": "REFERENCE_ONLY", "category": "human_template", "note": "Plantilla de chronique para el humano, no cargada en contexto de IA."},
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
          {"order": 9.5, "path": "08-LOGS/chronique-ia/chronique-template.yaml", "status": "REFERENCE_ONLY", "category": "human_template", "note": "Plantilla de chronique para el humano, no cargada en contexto de IA."},
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
          {"order": 9.5, "path": "08-LOGS/chronique-ia/chronique-template.yaml", "status": "REFERENCE_ONLY", "category": "human_template", "note": "Plantilla de chronique para el humano, no cargada en contexto de IA."},
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
          {"order": 9.5, "path": "08-LOGS/chronique-ia/chronique-template.yaml", "status": "REFERENCE_ONLY", "category": "human_template", "note": "Plantilla de chronique para el humano, no cargada en contexto de IA."},
          {"order": 10, "path": "02-SKILLS/ODONTOLOGIA/00-INDEX.md", "status": "PLANNED", "category": "vertical_index"},
          {"order": 11, "path": "04-WORKFLOWS/n8n/00-INDEX.md", "status": "PLANNED", "category": "workflow_index"},
          {"order": 12, "path": "06-PROGRAMMING/{language}/{language}-master-agent.md", "status": "REAL", "category": "programming_agent", "dynamic_resolution": {"token": "{language}", "source_file": "00-STACK-SELECTOR.md", "source_key": "LANGUAGE_LOCK", "fallback_behavior": "error_with_audit", "allowed_values": ["python", "go", "javascript", "bash", "yaml-json-schema", "sql", "postgresql-pgvector"]}},
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
          {"order": 9.5, "path": "08-LOGS/chronique-ia/chronique-template.yaml", "status": "REFERENCE_ONLY", "category": "human_template", "note": "Plantilla de chronique para el humano, no cargada en contexto de IA."},
          {"order": 10, "path": "02-SKILLS/HOTELES-POSADAS/00-INDEX.md", "status": "PLANNED", "category": "vertical_index"},
          {"order": 11, "path": "04-WORKFLOWS/n8n/00-INDEX.md", "status": "PLANNED", "category": "workflow_index"},
          {"order": 12, "path": "06-PROGRAMMING/{language}/{language}-master-agent.md", "status": "REAL", "category": "programming_agent", "dynamic_resolution": {"token": "{language}", "source_file": "00-STACK-SELECTOR.md", "source_key": "LANGUAGE_LOCK", "fallback_behavior": "error_with_audit", "allowed_values": ["python", "go", "javascript", "bash", "yaml-json-schema", "sql", "postgresql-pgvector"]}},
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
          {"order": 9.5, "path": "08-LOGS/chronique-ia/chronique-template.yaml", "status": "REFERENCE_ONLY", "category": "human_template", "note": "Plantilla de chronique para el humano, no cargada en contexto de IA."},
          {"order": 10, "path": "02-SKILLS/RESTAURANTES/00-INDEX.md", "status": "PLANNED", "category": "vertical_index"},
          {"order": 11, "path": "04-WORKFLOWS/n8n/00-INDEX.md", "status": "PLANNED", "category": "workflow_index"},
          {"order": 12, "path": "06-PROGRAMMING/{language}/{language}-master-agent.md", "status": "REAL", "category": "programming_agent", "dynamic_resolution": {"token": "{language}", "source_file": "00-STACK-SELECTOR.md", "source_key": "LANGUAGE_LOCK", "fallback_behavior": "error_with_audit", "allowed_values": ["python", "go", "javascript", "bash", "yaml-json-schema", "sql", "postgresql-pgvector"]}},
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
          {"order": 9.5, "path": "08-LOGS/chronique-ia/chronique-template.yaml", "status": "REFERENCE_ONLY", "category": "human_template", "note": "Plantilla de chronique para el humano, no cargada en contexto de IA."},
          {"order": 10, "path": "02-SKILLS/INSTAGRAM-SOCIAL-MEDIA/00-INDEX.md", "status": "PLANNED", "category": "vertical_index"},
          {"order": 11, "path": "04-WORKFLOWS/n8n/00-INDEX.md", "status": "PLANNED", "category": "workflow_index"},
          {"order": 12, "path": "06-PROGRAMMING/{language}/{language}-master-agent.md", "status": "REAL", "category": "programming_agent", "dynamic_resolution": {"token": "{language}", "source_file": "00-STACK-SELECTOR.md", "source_key": "LANGUAGE_LOCK", "fallback_behavior": "error_with_audit", "allowed_values": ["python", "go", "javascript", "bash", "yaml-json-schema", "sql", "postgresql-pgvector"]}},
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
          {"order": 9.5, "path": "08-LOGS/chronique-ia/chronique-template.yaml", "status": "REFERENCE_ONLY", "category": "human_template", "note": "Plantilla de chronique para el humano, no cargada en contexto de IA."},
          {"order": 10, "path": "02-SKILLS/CORPORATE-KB/00-INDEX.md", "status": "PLANNED", "category": "vertical_index"},
          {"order": 11, "path": "04-WORKFLOWS/n8n/00-INDEX.md", "status": "PLANNED", "category": "workflow_index"},
          {"order": 12, "path": "06-PROGRAMMING/{language}/{language}-master-agent.md", "status": "REAL", "category": "programming_agent", "dynamic_resolution": {"token": "{language}", "source_file": "00-STACK-SELECTOR.md", "source_key": "LANGUAGE_LOCK", "fallback_behavior": "error_with_audit", "allowed_values": ["python", "go", "javascript", "bash", "yaml-json-schema", "sql", "postgresql-pgvector"]}},
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
          {"order": 9.5, "path": "08-LOGS/chronique-ia/chronique-template.yaml", "status": "REFERENCE_ONLY", "category": "human_template", "note": "Plantilla de chronique para el humano, no cargada en contexto de IA."},
          {"order": 10, "path": "02-SKILLS/ODONTOLOGIA/00-INDEX.md", "status": "PLANNED", "category": "vertical_index"},
          {"order": 11, "path": "04-WORKFLOWS/n8n/00-INDEX.md", "status": "PLANNED", "category": "workflow_index"},
          {"order": 12, "path": "06-PROGRAMMING/{language}/{language}-master-agent.md", "status": "REAL", "category": "programming_agent", "dynamic_resolution": {"token": "{language}", "source_file": "00-STACK-SELECTOR.md", "source_key": "LANGUAGE_LOCK", "fallback_behavior": "error_with_audit", "allowed_values": ["python", "go", "javascript", "bash", "yaml-json-schema", "sql", "postgresql-pgvector"]}},
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
          {"order": 9.5, "path": "08-LOGS/chronique-ia/chronique-template.yaml", "status": "REFERENCE_ONLY", "category": "human_template", "note": "Plantilla de chronique para el humano, no cargada en contexto de IA."},
          {"order": 10, "path": "02-SKILLS/HOTELES-POSADAS/00-INDEX.md", "status": "PLANNED", "category": "vertical_index"},
          {"order": 11, "path": "04-WORKFLOWS/n8n/00-INDEX.md", "status": "PLANNED", "category": "workflow_index"},
          {"order": 12, "path": "06-PROGRAMMING/{language}/{language}-master-agent.md", "status": "REAL", "category": "programming_agent", "dynamic_resolution": {"token": "{language}", "source_file": "00-STACK-SELECTOR.md", "source_key": "LANGUAGE_LOCK", "fallback_behavior": "error_with_audit", "allowed_values": ["python", "go", "javascript", "bash", "yaml-json-schema", "sql", "postgresql-pgvector"]}},
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
          {"order": 9.5, "path": "08-LOGS/chronique-ia/chronique-template.yaml", "status": "REFERENCE_ONLY", "category": "human_template", "note": "Plantilla de chronique para el humano, no cargada en contexto de IA."},
          {"order": 10, "path": "02-SKILLS/RESTAURANTES/00-INDEX.md", "status": "PLANNED", "category": "vertical_index"},
          {"order": 11, "path": "04-WORKFLOWS/n8n/00-INDEX.md", "status": "PLANNED", "category": "workflow_index"},
          {"order": 12, "path": "06-PROGRAMMING/{language}/{language}-master-agent.md", "status": "REAL", "category": "programming_agent", "dynamic_resolution": {"token": "{language}", "source_file": "00-STACK-SELECTOR.md", "source_key": "LANGUAGE_LOCK", "fallback_behavior": "error_with_audit", "allowed_values": ["python", "go", "javascript", "bash", "yaml-json-schema", "sql", "postgresql-pgvector"]}},
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
          {"order": 9.5, "path": "08-LOGS/chronique-ia/chronique-template.yaml", "status": "REFERENCE_ONLY", "category": "human_template", "note": "Plantilla de chronique para el humano, no cargada en contexto de IA."},
          {"order": 10, "path": "02-SKILLS/INSTAGRAM-SOCIAL-MEDIA/00-INDEX.md", "status": "PLANNED", "category": "vertical_index"},
          {"order": 11, "path": "04-WORKFLOWS/n8n/00-INDEX.md", "status": "PLANNED", "category": "workflow_index"},
          {"order": 12, "path": "06-PROGRAMMING/{language}/{language}-master-agent.md", "status": "REAL", "category": "programming_agent", "dynamic_resolution": {"token": "{language}", "source_file": "00-STACK-SELECTOR.md", "source_key": "LANGUAGE_LOCK", "fallback_behavior": "error_with_audit", "allowed_values": ["python", "go", "javascript", "bash", "yaml-json-schema", "sql", "postgresql-pgvector"]}},
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
          {"order": 9.5, "path": "08-LOGS/chronique-ia/chronique-template.yaml", "status": "REFERENCE_ONLY", "category": "human_template", "note": "Plantilla de chronique para el humano, no cargada en contexto de IA."},
          {"order": 10, "path": "02-SKILLS/CORPORATE-KB/00-INDEX.md", "status": "PLANNED", "category": "vertical_index"},
          {"order": 11, "path": "04-WORKFLOWS/n8n/00-INDEX.md", "status": "PLANNED", "category": "workflow_index"},
          {"order": 12, "path": "06-PROGRAMMING/{language}/{language}-master-agent.md", "status": "REAL", "category": "programming_agent", "dynamic_resolution": {"token": "{language}", "source_file": "00-STACK-SELECTOR.md", "source_key": "LANGUAGE_LOCK", "fallback_behavior": "error_with_audit", "allowed_values": ["python", "go", "javascript", "bash", "yaml-json-schema", "sql", "postgresql-pgvector"]}},
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
      "ingestion_rule": "Load strictly by 'order' field. Resolve dynamic tokens BEFORE loading artifact. Block if any status == 'PLANNED' and infra_profile requires production readiness. Fallback to 'nano' for B1/B2, 'micro' for B3.",
      "canonical_ref_date": "2026-04-29T12:00:00-03:00",
      "patch_applied": "Problema-3-Dynamic-Stack-Resolution",
      "patch_author": "Mantis AgenticDev SDD-COLLABORATIVE-GENERATION",
      "validation_command": "jq '.context_injection_matrix.routing_bundles[] | select(.mode==\"B2\" or .mode==\"B3\") | .load_sequence[] | select(.category==\"programming_agent\") | .path' IA-QUICKSTART.md | grep -v '{language}' && echo '❌ Hardcode detectado' || echo '✅ Todos los master-agents son dinámicos'"
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
