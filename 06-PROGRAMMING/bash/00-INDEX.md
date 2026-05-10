---
artifact_id: "bash-index-mantis"
artifact_type: "skill_index"
version: "2.2.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/bash/00-INDEX.md --json"
canonical_path: "06-PROGRAMMING/bash/00-INDEX.md"
tier: 1
mode_selected: "B1"
prompt_hash: "sha256:framework-executable-contract-v2.2.0"
generated_at: "2026-05-08T00:00:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "bash"
ai_navigation:
  read_first: true
  required_for: ["bash-artifact-generation", "tdd-validation", "sdd-contract-enforcement", "hardening-audit", "cross-ai-compatibility"]
  update_frequency: monthly
  compatible_models: ["qwen", "deepseek", "claude", "minimax", "mimo-xiaomi", "gpt-4", "gemini"]
audience: ["bash-master-agent", "orchestrator-engine", "validation-hooks", "senior-engineers", "ai-agents"]
status: "✅ Estável"
next_review: "2026-06-08"
license: "CC-BY-NC-SA-4.0"
---

# Bash Patterns Master Index – Multi-Tenant Hardening, Shell Security & Automation

## 👤 Propósito y Alcance
Índice canónico de navegación para `06-PROGRAMMING/bash/`. Documenta 32 artifacts auditados bajo HARNESS NORMS v3.1.0-SELECTIVE, mapea flujos de ejecución para scripting/automatización con aislamiento multi-tenant, referencia al **agente master de generación Bash**, y proporciona un árbol JSON enriquecido para routing de agentes LLM y pipelines CI/CD.

> 🔑 **Diferenciador crítico**: Este dominio cubre Bash 5.x+ con enfoque en:
> - Shell security hardening: `set -euo pipefail`, quoting seguro, validación de inputs
> - Resource limits (C1/C2): timeouts, ulimits, cgroups integration para scripts multi-tenant
> - Tenant isolation (C4): propagación de `TENANT_ID` via env vars, aislamiento de filesystem/temp files
> - Observability (C8): logging estructurado JSON desde shell, trazabilidad de comandos ejecutados
> - Integración segura con otros dominios respetando LANGUAGE LOCK

---

## 🤖 Agente de Generación Disponible

| Agente | Canonical Path | Dominio | Constraints Soportados | Hooks de Validación |
|--------|---------------|---------|----------------------|-------------------|
| **`bash-master-agent`** ✅ | `[[06-PROGRAMMING/bash/bash-master-agent.md]]` | `bash,shell,automation,cli` | `C1,C2,C3,C4,C5,C7,C8` | `verify-constraints.sh`, `audit-secrets.sh`, `shellcheck-validator.sh`, `bash-syntax-check.sh` |

> ⚠️ **Nota contractual**: Este agente es Tier 1 (referencia educativa). Cualquier script generado debe pasar validación automática antes de merge. Documentación técnica en pt-BR: `docs/pt-BR/programming/bash/bash-master-agent/README.md`.

---

## 📂 Mapeo de Fases y Wikilinks

### FASE 0 – Core Hardening (Pre-flight & Shell Security)
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[bash-hardening-verification.md]]` | C3,C4,C5,C7,C8 | Validación de entorno shell, `set -euo pipefail`, límites de recursos pre-ejecución |
| `[[safe-variable-expansion.md]]` | C3,C4,C5,C7 | Quoting seguro, `${VAR:?missing}`, prevención de word splitting e injection |
| `[[error-handling-traps.md]]` | C4,C5,C7,C8 | Manejo de errores con `trap`, cleanup de temp files y logging estructurado |

### FASE 1 – Multi-Tenant Security (Aislamiento en Shell)
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[tenant-context-propagation.md]]` | C3,C4,C5,C7,C8 | Propagación segura de `TENANT_ID` via env vars, validación de scope en subshells |
| `[[filesystem-isolation-per-tenant.md]]` | C3,C4,C7 | Aislamiento de directorios de trabajo, temp files con `mktemp -d` y cleanup con trap |
| `[[secrets-in-shell-c3.md]]` | C3,C5,C7 | Gestión de secrets: zero hardcode, lectura desde vault/env, masking en logs |
| `[[command-audit-logging-c8.md]]` | C4,C5,C8 | Logging estructurado JSON de comandos ejecutados con correlación por tenant |

### FASE 2 – Resource Management & Concurrency
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[timeout-and-retry-patterns.md]]` | C1,C4,C7,C8 | Timeouts con `timeout` cmd, retry con backoff exponencial y cancellation por tenant |
| `[[resource-limits-ulimit-cgroups.md]]` | C1,C2,C7 | Limitación de CPU/memoria con `ulimit`, cgroups v2 y validación pre-ejecución |
| `[[parallel-execution-safe.md]]` | C1,C4,C7 | Ejecución paralela con `xargs -P`, semáforos via flock y aislamiento de outputs por tenant |
| `[[orchestrator-engine-bash-port.md]]` | C1,C3,C4,C5,C6,C7,C8 | Port del orchestrator principal → Bash modular con validación de constraints línea a línea |

### FASE 3 – Filesystem & Data Operations
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[safe-file-operations.md]]` | C3,C4,C5,C7 | Operaciones de archivo con validación de paths, atomic writes y rollback en error |
| `[[json-processing-with-jq.md]]` | C4,C5,C7,C8 | Procesamiento seguro de JSON con `jq`, validación de schema y tenant scoping en queries |
| `[[yaml-processing-with-yq.md]]` | C4,C5,C7 | Procesamiento de YAML con `yq`, validación de estructura y propagación de contexto tenant |
| `[[csv-safe-parsing.md]]` | C4,C5,C7 | Parsing seguro de CSV con manejo de comas en campos, quoting y validación de columnas |

### FASE 4 – API & External Integrations
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[curl-with-tenant-headers.md]]` | C3,C4,C7,C8 | Wrapper de `curl` con inyección automática de `X-Tenant-ID`, retry logic y logging |
| `[[webhook-handler-secure.md]]` | C3,C4,C7 | Handler de webhooks con validación de firma HMAC, rate limiting y replay attack prevention |
| `[[git-operations-tenant-scoped.md]]` | C3,C4,C5,C7 | Operaciones Git con aislamiento de worktrees, validación de firmas GPG y scope por tenant |
| `[[docker-cli-tenant-isolation.md]]` | C1,C3,C4,C7 | Ejecución segura de Docker CLI con límites de recursos, user namespace y aislamiento de volúmenes |

### FASE 5 – Validation Hooks & CI/CD
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[verify-constraints-hook.md]]` | C1,C3,C4,C5,C6,C7,C8 | Hook de validación de constraints C1-C8 con output JSON/JSONL per V-INT-03/V-LOG-02 |
| `[[audit-secrets-hook.md]]` | C3,C5,C7 | Hook de detección de secretos hardcodeados con patrones regex y reporting estructurado |
| `[[check-rls-hook.md]]` | C4,C5,C8 | Hook de validación de aislamiento multi-tenant en artifacts SQL con análisis estático |
| `[[validate-frontmatter-hook.md]]` | C5,C6,C8 | Hook de validación de frontmatter YAML con schema JSON y reporting de errores |

### FASE 6 – Observability & Deployment
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[structured-logging-json.md]]` | C4,C5,C8 | Logging estructurado JSON desde shell con campos tenant_id, timestamp, command, status |
| `[[health-check-endpoint.md]]` | C7,C8 | Endpoint de health check con métricas Prometheus-ready y validación de dependencias |
| `[[deployment-rollback-safe.md]]` | C3,C4,C5,C7 | Despliegue con validación pre/post, snapshot de estado y rollback automático en error |
| `[[backup-tenant-scoped.md]]` | C3,C4,C5,C7 | Backup de datos con aislamiento por tenant, verificación de integridad y logging estructurado |

### FASE 7 – Testing & Validation
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[bash-unit-test-patterns.md]]` | C4,C5,C8 | Patrones de testing con `bats-core`, fixtures aisladas por tenant y mocks de comandos |
| `[[integration-test-fixtures.md]]` | C3,C4,C7 | Fixtures de integración con setup/teardown seguro, validación de rutas y rollback automático |
| `[[fuzzing-inputs-security.md]]` | C3,C7,C8 | Fuzzing de inputs de script con detección de command injection, path traversal y tenant leakage |

---

## 🔗 Interacciones con el Repositorio
- **`05-CONFIGURATIONS/validation/`**: Todos los artifacts son validados por `orchestrator-engine.sh`. Los hooks `verify-constraints.sh`, `audit-secrets.sh`, etc. son generados desde este dominio.
- **`01-RULES/`**: Las normas `harness-norms-v3.0.md`, `language-lock-protocol.md` y `06-MULTITENANCY-RULES.md` definen los constraints C1-C8 aplicados.
- **`06-PROGRAMMING/postgresql-pgvector/`**: Carpeta hermana con LANGUAGE LOCK estricto. **Delegación obligatoria**: queries vectoriales deben generarse en `postgresql-pgvector/`, no aquí.
- **`06-PROGRAMMING/sql/`, `python/`, `go/`**: Para lógica de dominio específica, delegar a estos dominios y consumir via CLI/API desde Bash.
- **`08-LOGS/`**: Los handlers de logging estructurado (C8) en Bash alimentan dashboards y generan entradas en `failed-attempts/` si fallan validaciones.
- **`bash-master-agent.md`**: Punto único de generación para nuevos artifacts Bash. Consulta este índice ANTES de emitir scripts para asegurar coherencia con patrones existentes.

---

## ⚠️ Reglas Críticas de LANGUAGE LOCK para bash/

```text
🚫 PROHIBIDO en esta carpeta:
• Invocación directa de operadores pgvector: psql -c "SELECT ... <-> ...", importación de extensiones vectoriales
• Queries SQL embebidas con sintaxis de extensión pgvector (CREATE EXTENSION vector, USING hnsw, etc.)
• Constraints vectoriales V1/V2/V3 en constraints_mapped del frontmatter
• Generación directa de código con operadores vectoriales; solo se permiten wrappers que deleguen a postgresql-pgvector/

✅ REQUERIDO en esta carpeta:
• artifact_type: "bash_script" | "bash_pattern" | "bash_cli" | "bash_validation_hook" (NUNCA "skill_pgvector")
• constraints_mapped: SOLO valores de C1-C8 (V* bloqueado por LANGUAGE LOCK)
• Scripts de producción deben incluir `set -euo pipefail`, validación de TENANT_ID y quoting seguro
• validation_command que referencie orchestrator-engine.sh con canonical_path correcto
• Agente master: consultar norms-matrix.json antes de declarar constraints en scripts generados
• Shell security: usar `shellcheck` patterns, validación de inputs con regex seguro, prevención de injection
• Comments pedagógicos: incluir `# 👇 EXPLICACIÓN:` en español para facilitar aprendizaje
```

---


## 🔗 RAW_URLS_INDEX – Patrones Bash Disponibles

> **Propósito**: Fuente de verdad para que el agente consulte patrones, normas y contratos sin inventar datos.

### 🏛️ Gobernanza Raíz (Contratos Inmutables)
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/GOVERNANCE-ORCHESTRATOR.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/00-STACK-SELECTOR.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/AI-NAVIGATION-CONTRACT.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/IA-QUICKSTART.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/PROJECT_TREE.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/SDD-COLLABORATIVE-GENERATION.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/TOOLCHAIN-REFERENCE.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/norms-matrix.json
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/knowledge-graph.json
```

### 📜 Normas y Constraints (01-RULES)
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/harness-norms-v3.0.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/language-lock-protocol.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/10-SDD-CONSTRAINTS.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/03-SECURITY-RULES.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/06-MULTITENANCY-RULES.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/validation-checklist.md
```

### 🧰 Toolchain de Validación (05-CONFIGURATIONS/validation)
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/VALIDATOR_DEV_NORMS.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/norms-matrix.json
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/orchestrator-engine.sh
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/verify-constraints.sh
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/audit-secrets.sh
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/shellcheck-validator.sh
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/bash-syntax-check.sh
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/schemas/skill-input-output.schema.json
```

### 🐚 Patrones Bash Core (06-PROGRAMMING/bash)
```text
# Índice y Agente Master
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/00-INDEX.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/bash-master-agent.md

# Fase 0: Core Hardening
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/bash-hardening-verification.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/safe-variable-expansion.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/error-handling-traps.md

# Fase 1: Multi-Tenant Security
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/tenant-context-propagation.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/filesystem-isolation-per-tenant.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/secrets-in-shell-c3.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/command-audit-logging-c8.md

# Fase 2: Resource Management
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/timeout-and-retry-patterns.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/resource-limits-ulimit-cgroups.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/parallel-execution-safe.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/orchestrator-engine-bash-port.md

# Fase 3: Filesystem & Data
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/safe-file-operations.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/json-processing-with-jq.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/yaml-processing-with-yq.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/csv-safe-parsing.md

# Fase 4: API & External Integrations
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/curl-with-tenant-headers.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/webhook-handler-secure.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/git-operations-tenant-scoped.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/docker-cli-tenant-isolation.md

# Fase 5: Validation Hooks
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/verify-constraints-hook.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/audit-secrets-hook.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/check-rls-hook.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/validate-frontmatter-hook.md

# Fase 6: Observability & Deployment
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/structured-logging-json.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/health-check-endpoint.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/deployment-rollback-safe.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/backup-tenant-scoped.md

# Fase 7: Testing
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/bash-unit-test-patterns.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/integration-test-fixtures.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/fuzzing-inputs-security.md
```

### 🔗 Referencias de Dominios Hermanos (Para Delegación)
```text
# SQL puro (delegar queries sin vectores)
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/00-INDEX.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/crud-with-tenant-enforcement.sql.md

# Python (delegar lógica de backend)
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/00-INDEX.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/python-sqlalchemy-tenant-enforcement.py.md

# Go (delegar microservicios/concurrencia)
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/00-INDEX.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/sql-core-patterns.go.md

# pgvector/RAG (delegar operaciones vectoriales)
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/00-INDEX.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md

# YAML/JSON Schema (delegar definiciones de config)
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/yaml-json-schema/00-INDEX.md
```

### 🔄 Workflows y CI/CD
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/.github/workflows/validate-mantis.yml
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/04-WORKFLOWS/sdd-universal-assistant.json
```

### 📚 Skills de Referencia
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/README.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/skill-domains-mapping.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/INFRASTRUCTURA/ssh-key-management.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/INFRASTRUCTURA/health-monitoring-vps.md
```

### 🌐 Documentación pt-BR (Obligatoria para validadores)
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/validation-tools/TEMPLATE-VALIDATOR.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/validation-tools/verify-constraints/README.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/validation-tools/shellcheck-validator/README.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/validation-tools/bash-syntax-check/README.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/programming/bash/bash-master-agent/README.md
```

---

## 🗂️ RUTAS CANÓNICAS LOCALES – Patrones Bash (Para Acceso en Repo)

> **Formato**: `RAW_URL` → `./ruta/local/en/repo`

### 🐚 Patrones Bash Core
```text
# Índice y Agente Master
06-PROGRAMMING/bash/00-INDEX.md
06-PROGRAMMING/bash/bash-master-agent.md

# Fase 0: Core Hardening
06-PROGRAMMING/bash/bash-hardening-verification.md
06-PROGRAMMING/bash/safe-variable-expansion.md
06-PROGRAMMING/bash/error-handling-traps.md

# Fase 1: Multi-Tenant Security
06-PROGRAMMING/bash/tenant-context-propagation.md
06-PROGRAMMING/bash/filesystem-isolation-per-tenant.md
06-PROGRAMMING/bash/secrets-in-shell-c3.md
06-PROGRAMMING/bash/command-audit-logging-c8.md

# Fase 2: Resource Management
06-PROGRAMMING/bash/timeout-and-retry-patterns.md
06-PROGRAMMING/bash/resource-limits-ulimit-cgroups.md
06-PROGRAMMING/bash/parallel-execution-safe.md
06-PROGRAMMING/bash/orchestrator-engine-bash-port.md

# Fase 3: Filesystem & Data
06-PROGRAMMING/bash/safe-file-operations.md
06-PROGRAMMING/bash/json-processing-with-jq.md
06-PROGRAMMING/bash/yaml-processing-with-yq.md
06-PROGRAMMING/bash/csv-safe-parsing.md

# Fase 4: API & External Integrations
06-PROGRAMMING/bash/curl-with-tenant-headers.md
06-PROGRAMMING/bash/webhook-handler-secure.md
06-PROGRAMMING/bash/git-operations-tenant-scoped.md
06-PROGRAMMING/bash/docker-cli-tenant-isolation.md

# Fase 5: Validation Hooks
06-PROGRAMMING/bash/verify-constraints-hook.md
06-PROGRAMMING/bash/audit-secrets-hook.md
06-PROGRAMMING/bash/check-rls-hook.md
06-PROGRAMMING/bash/validate-frontmatter-hook.md

# Fase 6: Observability & Deployment
06-PROGRAMMING/bash/structured-logging-json.md
06-PROGRAMMING/bash/health-check-endpoint.md
06-PROGRAMMING/bash/deployment-rollback-safe.md
06-PROGRAMMING/bash/backup-tenant-scoped.md

# Fase 7: Testing
06-PROGRAMMING/bash/bash-unit-test-patterns.md
06-PROGRAMMING/bash/integration-test-fixtures.md
06-PROGRAMMING/bash/fuzzing-inputs-security.md
```

### 🔗 Referencias de Dominios Hermanos (Para Delegación)
```text
# SQL puro
06-PROGRAMMING/sql/00-INDEX.md
06-PROGRAMMING/sql/crud-with-tenant-enforcement.sql.md

# Python
06-PROGRAMMING/python/00-INDEX.md
06-PROGRAMMING/python/python-sqlalchemy-tenant-enforcement.py.md

# Go
06-PROGRAMMING/go/00-INDEX.md
06-PROGRAMMING/go/sql-core-patterns.go.md

# pgvector/RAG
06-PROGRAMMING/postgresql-pgvector/00-INDEX.md
06-PROGRAMMING/postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md

# YAML/JSON Schema
06-PROGRAMMING/yaml-json-schema/00-INDEX.md
```

### 🔄 Workflows y CI/CD
```text
04-WORKFLOWS/sdd-universal-assistant.json
.github/workflows/validate-mantis.yml
```

### 📚 Skills de Referencia
```text
02-SKILLS/README.md
02-SKILLS/skill-domains-mapping.md
02-SKILLS/INFRASTRUCTURA/ssh-key-management.md
02-SKILLS/INFRASTRUCTURA/health-monitoring-vps.md
```

### 🌐 Documentación pt-BR
```text
docs/pt-BR/validation-tools/TEMPLATE-VALIDATOR.md
docs/pt-BR/validation-tools/verify-constraints/README.md
docs/pt-BR/validation-tools/shellcheck-validator/README.md
docs/pt-BR/validation-tools/bash-syntax-check/README.md
docs/pt-BR/programming/bash/bash-master-agent/README.md
```

---

## 🧭 GUÍA DE USO PARA EL AGENTE BASH

```bash
#!/usr/bin/env bash
# Pseudocódigo: Cómo consultar patrones disponibles en Bash
# (Implementado en el agente, no en Bash puro para evitar circularidad)

# Estructura de referencia de patrón
declare -A PATTERN_REF=(
  [raw_url]=""
  [canonical_path]=""
  [domain]="06-PROGRAMMING/bash/"
  [language_lock]="bash,shell,automation,cli"
  [constraints_default]="C3,C4,C5"
  [vector_ops_allowed]="false"
)

consultar_patron_bash() {
  local nombre_patron="$1"
  local base_raw="https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/"
  local base_local="./06-PROGRAMMING/bash/"
  
  local is_master=0
  [[ "$nombre_patron" == "bash-master-agent" ]] && is_master=1
  
  local extension=".md"
  [[ $is_master -eq 1 ]] && extension=".md"
  
  local filename="${nombre_patron}${extension}"
  
  PATTERN_REF[raw_url]="${base_raw}06-PROGRAMMING/bash/${filename}"
  PATTERN_REF[canonical_path]="${base_local}${filename}"
  
  # Retorna como JSON para consumo del agente
  jq -n \
    --arg raw "${PATTERN_REF[raw_url]}" \
    --arg path "${PATTERN_REF[canonical_path]}" \
    --arg domain "${PATTERN_REF[domain]}" \
    --arg lock "${PATTERN_REF[language_lock]}" \
    --arg constraints "${PATTERN_REF[constraints_default]}" \
    --argjson vector_ops "${PATTERN_REF[vector_ops_allowed]}" \
    '{raw_url:$raw, canonical_path:$path, domain:$domain, language_lock:$lock, constraints_default:($constraints|split(",")), vector_ops_allowed:$vector_ops}'
}

# Validación de constraints antes de emitir script
validar_constraints_bash() {
  local artifact_path="$1"
  local issues=()
  
  # Extraer frontmatter y constraints declarados
  local declared_constraints
  declared_constraints=$(extract_frontmatter_constraints "$artifact_path")
  
  # Cargar constraints permitidos desde norms-matrix.json
  local allowed_constraints
  allowed_constraints=$(jq -r --arg path "$artifact_path" '.matrix_by_location[$path].constraints // []' ./05-CONFIGURATIONS/validation/norms-matrix.json)
  
  # Verificar cada constraint declarado
  for c in $declared_constraints; do
    if ! echo "$allowed_constraints" | jq -e --arg c "$c" 'index($c)' > /dev/null; then
      issues+=("constraint '$c' not allowed for path $artifact_path")
    fi
  done
  
  # C4: Validar propagación de TENANT_ID en scripts que llaman a DB/API
  if grep -qE '(psql|mysql|curl|httpie)' "$artifact_path"; then
    if ! grep -qE '(\$TENANT_ID|\$\{TENANT_ID\}|X-Tenant-ID)' "$artifact_path"; then
      issues+=("C4 missing: script calls external service without TENANT_ID propagation")
    fi
  fi
  
  # C3: Zero hardcode secrets
  if grep -qE 'API_KEY\s*=\s*['\''"][^'\''"]+['\''"]|password\s*:\s*['\''"][^'\''"]+['\''"]' "$artifact_path"; then
    issues+=("C3 violation: hardcoded secret detected")
  fi
  
  # Retornar issues como JSON array
  printf '%s\n' "${issues[@]}" | jq -R -s -c 'split("\n") | map(select(length > 0))'
}

# Detección de LANGUAGE LOCK: operadores vectoriales prohibidos
contiene_operadores_vectoriales() {
  local code="$1"
  grep -qE 'psql.*<->|<#>|<=>|CREATE EXTENSION vector|cosine_distance|l2_distance|vector\(' <<< "$code"
}

# Delegación por dominio según LANGUAGE LOCK
delegar_por_dominio() {
  local query="$1"
  local context="$2"
  
  if contiene_operadores_vectoriales "$query"; then
    # 🔄 Delegar a postgresql-pgvector/
    echo "LANGUAGE LOCK: Vector operators not allowed in Bash domain. Use postgresql-pgvector/" >&2
    delegar_a_dominio "06-PROGRAMMING/postgresql-pgvector/" "$query" "$context"
  elif es_query_sql_pura "$query"; then
    # 🔄 Delegar a sql/
    delegar_a_dominio "06-PROGRAMMING/sql/" "$query" "$context"
  elif es_logica_backend_pesada "$query"; then
    # 🔄 Delegar a python/ o go/
    delegar_a_dominio "06-PROGRAMMING/python/" "$query" "$context"
  else
    # ✅ Permitido: generar script Bash estándar con tenant isolation
    generar_script_bash "$query" "$context"
  fi
}

# Ejemplo de uso en el agente:
main() {
  local pattern_json
  pattern_json=$(consultar_patron_bash "verify-constraints-hook")
  
  local canonical_path
  canonical_path=$(echo "$pattern_json" | jq -r '.canonical_path')
  
  local issues
  issues=$(validar_constraints_bash "$canonical_path")
  
  if [[ $(echo "$issues" | jq 'length') -gt 0 ]]; then
    echo "Validation failed: $issues" >&2
    exit 1
  fi
  
  # Generar script seguro...
}
```

---

## 📋 INSTRUCCIONES DE INTEGRACIÓN (Actualizadas)

### Paso 1: Agregar al final del agente
Pegar los bloques de referencias justo antes de la sección `## Limitations` en:
- `06-PROGRAMMING/bash/bash-master-agent.md`

### Paso 2: Actualizar el comportamiento del agente
En la sección `## Comportamiento del Agente` o `## Behavioral Traits`, agregar:

```markdown
| Trait | Implementación contractual |
|-------|---------------------------|
| **Consulta patrones antes de generar** | Antes de emitir script Bash, el agente debe consultar la lista de patrones disponibles en `06-PROGRAMMING/bash/` para asegurar coherencia con el repositorio |
| **Acceso dual** | Usar ruta canónica (`./06-PROGRAMMING/bash/...`) para acceso local, o raw URL para acceso remoto si el archivo no existe localmente |
| **LANGUAGE LOCK automático** | Si el usuario solicita operadores vectoriales (`psql -c "SELECT ... <-> ..."`, `CREATE EXTENSION vector`), el agente debe delegar a `06-PROGRAMMING/postgresql-pgvector/` y NO generar scripts con vectores en su dominio |
| **Shell security primero** | Priorizar `set -euo pipefail`, quoting seguro con `"${VAR}"`, validación de inputs con regex seguro y prevención de command injection |
| **Pedagogía en español** | Incluir `# 👇 EXPLICACIÓN: ...` en comentarios para facilitar aprendizaje, manteniendo scripts ejecutables ≤5 líneas por ejemplo |
| **Valida constraints antes de emitir** | Ejecutar `validar_constraints_bash()` antes de emitir cualquier artifact para asegurar coherencia con `norms-matrix.json` |
| **Emite logs estructurados** | JSON a `stdout`, logs humanos a `stderr`, JSONL a `08-LOGS/validation/...` per V-INT-03 y V-LOG-02 |
```

### Paso 3: Validar con `verify-constraints.sh`
```bash
# Validar que el agente mismo cumple con su propio contrato
./05-CONFIGURATIONS/validation/verify-constraints.sh --file 06-PROGRAMMING/bash/bash-master-agent.md | jq

# Validación adicional con toolchain Bash específica
./05-CONFIGURATIONS/validation/shellcheck-validator.sh --file 06-PROGRAMMING/bash/bash-master-agent.md
./05-CONFIGURATIONS/validation/bash-syntax-check.sh --file 06-PROGRAMMING/bash/bash-master-agent.md

# Verificar que NO hay operadores vectoriales (LANGUAGE LOCK)
grep -E 'psql.*<->|CREATE EXTENSION vector|cosine_distance' 06-PROGRAMMING/bash/bash-master-agent.md && echo "❌ VIOLATION" || echo "✅ OK"
```

---

> 📌 **Nota final**: Este índice es Tier 1 (referencia contractual). Cualquier modificación debe pasar validación automática antes de merge.  
> 🇧🇷 *Documentação técnica completa disponível em*: `docs/pt-BR/programming/bash/00-INDEX/README.md` (próxima entrega).

---

## 🧭 STACKSELECTOR CANÓNICO – Hidratación Segmentada para Master Agent
<!-- STACKSELECTOR_JSONL_START -->
```jsonl
{"artifact_id":"bash-master-agent","canonical_path":"06-PROGRAMMING/bash/bash-master-agent.md","function_human":"Núcleo de orquestación Bash: contiene mantis_log() V-LOG-02, bootstrap resiliente, hardening base y protocolo de handoff a otros dominios","constraints":["C1","C2","C3","C4","C5","C7","C8"],"dependencies":[],"hydration_weight":"heavy","entrypoint_function":"mantis_log","validation_command":"bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {} --checks C3,C4,C5,C7,C8 --json","vectorizable":false,"tenant_context_required":true}
{"artifact_id":"bash-hardening-verification","canonical_path":"06-PROGRAMMING/bash/bash-hardening-verification.md","function_human":"Validación pre-flight de entorno shell: verifica set -euo pipefail, límites de recursos y cumplimiento de constraints antes de ejecutar scripts","constraints":["C3","C4","C5","C7","C8"],"dependencies":["bash-master-agent"],"hydration_weight":"light","entrypoint_function":"verify_hardening_pre_flight","validation_command":"bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {} --checks C3,C4,C7 --json","vectorizable":false,"tenant_context_required":true}
{"artifact_id":"safe-variable-expansion","canonical_path":"06-PROGRAMMING/bash/safe-variable-expansion.md","function_human":"Expansión segura de variables: previene word splitting, command injection y leakage mediante quoting riguroso y ${VAR:?missing}","constraints":["C3","C4","C5","C6","C7"],"dependencies":["bash-master-agent"],"hydration_weight":"light","entrypoint_function":"safe_expand","validation_command":"bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {} --checks C3,C5,C6 --json","vectorizable":false,"tenant_context_required":false}
{"artifact_id":"error-handling-traps","canonical_path":"06-PROGRAMMING/bash/error-handling-traps.md","function_human":"Manejo unificado de errores: implementa trap para EXIT/INT/TERM, cleanup de recursos y logging estructurado en fallos","constraints":["C4","C5","C7","C8"],"dependencies":["bash-master-agent","safe-variable-expansion"],"hydration_weight":"light","entrypoint_function":"setup_error_trap","validation_command":"bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {} --checks C7,C8 --json","vectorizable":false,"tenant_context_required":false}
{"artifact_id":"tenant-context-propagation","canonical_path":"06-PROGRAMMING/bash/tenant-context-propagation.md","function_human":"Propagación segura de TENANT_ID: garantiza que el identificador de tenant se herede en subshells, pipes y llamadas externas","constraints":["C3","C4","C5","C7","C8"],"dependencies":["bash-master-agent","safe-variable-expansion"],"hydration_weight":"light","entrypoint_function":"propagate_tenant_context","validation_command":"bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {} --checks C4,C8 --json","vectorizable":false,"tenant_context_required":true}
{"artifact_id":"filesystem-isolation-per-tenant","canonical_path":"06-PROGRAMMING/bash/filesystem-isolation-per-tenant.md","function_human":"Aislamiento de filesystem por tenant: crea directorios de trabajo efímeros con mktemp -d y valida path escape","constraints":["C3","C4","C5","C7"],"dependencies":["tenant-context-propagation","safe-variable-expansion"],"hydration_weight":"medium","entrypoint_function":"create_tenant_workspace","validation_command":"bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {} --checks C4,C5 --json","vectorizable":false,"tenant_context_required":true}
{"artifact_id":"secrets-in-shell-c3","canonical_path":"06-PROGRAMMING/bash/secrets-in-shell-c3.md","function_human":"Gestión segura de secrets en shell: cero hardcode, lectura desde env/vault, masking automático en logs","constraints":["C3","C5","C7"],"dependencies":["bash-master-agent","safe-variable-expansion"],"hydration_weight":"light","entrypoint_function":"load_secret_safe","validation_command":"bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {} --checks C3,C5 --json","vectorizable":false,"tenant_context_required":false}
{"artifact_id":"command-audit-logging-c8","canonical_path":"06-PROGRAMMING/bash/command-audit-logging-c8.md","function_human":"Auditoría de comandos ejecutados: logging estructurado JSONL con correlación por tenant y scrubbing de PII","constraints":["C4","C5","C6","C8"],"dependencies":["bash-master-agent","tenant-context-propagation"],"hydration_weight":"light","entrypoint_function":"audit_command_exec","validation_command":"bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {} --checks C6,C8 --json","vectorizable":false,"tenant_context_required":true}
{"artifact_id":"timeout-and-retry-patterns","canonical_path":"06-PROGRAMMING/bash/timeout-and-retry-patterns.md","function_human":"Patrones de timeout y retry: timeout cmd con backoff exponencial, jitter y cancellation por tenant","constraints":["C1","C4","C7","C8"],"dependencies":["bash-master-agent","tenant-context-propagation"],"hydration_weight":"light","entrypoint_function":"run_with_retry","validation_command":"bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {} --checks C1,C7 --json","vectorizable":false,"tenant_context_required":true}
{"artifact_id":"resource-limits-ulimit-cgroups","canonical_path":"06-PROGRAMMING/bash/resource-limits-ulimit-cgroups.md","function_human":"Limitación de recursos por script: ulimit para CPU/memoria, integración con cgroups v2 y validación pre-ejecución","constraints":["C1","C2","C7","C8"],"dependencies":["bash-master-agent"],"hydration_weight":"medium","entrypoint_function":"apply_resource_limits","validation_command":"bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {} --checks C1,C2,C7 --json","vectorizable":false,"tenant_context_required":false}
{"artifact_id":"parallel-execution-safe","canonical_path":"06-PROGRAMMING/bash/parallel-execution-safe.md","function_human":"Ejecución paralela segura: pool de workers con xargs -P, semáforos via flock y aislamiento de outputs por tenant","constraints":["C1","C4","C7"],"dependencies":["resource-limits-ulimit-cgroups","tenant-context-propagation"],"hydration_weight":"medium","entrypoint_function":"run_parallel_safe","validation_command":"bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {} --checks C1,C4,C7 --json","vectorizable":false,"tenant_context_required":true}
{"artifact_id":"orchestrator-engine-bash-port","canonical_path":"06-PROGRAMMING/bash/orchestrator-engine-bash-port.md","function_human":"Port Bash del orchestrator principal: validación de constraints C1-C8 línea a línea con output JSONL","constraints":["C1","C3","C4","C5","C6","C7","C8"],"dependencies":["bash-master-agent","verify-constraints-hook"],"hydration_weight":"heavy","entrypoint_function":"validate_artifact_constraints","validation_command":"bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {} --checks C5,C8 --json","vectorizable":false,"tenant_context_required":false}
{"artifact_id":"safe-file-operations","canonical_path":"06-PROGRAMMING/bash/safe-file-operations.md","function_human":"Operaciones atómicas de archivo: validación de paths, escritura staging + rename y rollback en error","constraints":["C3","C4","C5","C7"],"dependencies":["safe-variable-expansion","error-handling-traps"],"hydration_weight":"light","entrypoint_function":"atomic_write_file","validation_command":"bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {} --checks C4,C5 --json","vectorizable":false,"tenant_context_required":true}
{"artifact_id":"json-processing-with-jq","canonical_path":"06-PROGRAMMING/bash/json-processing-with-jq.md","function_human":"Procesamiento seguro de JSON con jq: validación de schema, quoting de inputs y tenant scoping en queries","constraints":["C4","C5","C6","C7","C8"],"dependencies":["safe-variable-expansion","bash-master-agent"],"hydration_weight":"light","entrypoint_function":"parse_json_safe","validation_command":"bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {} --checks C5,C6 --json","vectorizable":false,"tenant_context_required":false}
{"artifact_id":"yaml-processing-with-yq","canonical_path":"06-PROGRAMMING/bash/yaml-processing-with-yq.md","function_human":"Procesamiento de YAML con yq: validación de estructura, fallback graceful y propagación de contexto tenant","constraints":["C4","C5","C7"],"dependencies":["safe-variable-expansion","bash-master-agent"],"hydration_weight":"light","entrypoint_function":"parse_yaml_safe","validation_command":"bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {} --checks C5 --json","vectorizable":false,"tenant_context_required":false}
{"artifact_id":"csv-safe-parsing","canonical_path":"06-PROGRAMMING/bash/csv-safe-parsing.md","function_human":"Parsing seguro de CSV: manejo de comas en campos, quoting RFC4180 y validación de columnas esperadas","constraints":["C4","C5","C6","C7"],"dependencies":["safe-variable-expansion"],"hydration_weight":"light","entrypoint_function":"parse_csv_line","validation_command":"bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {} --checks C5,C6 --json","vectorizable":false,"tenant_context_required":false}
{"artifact_id":"curl-with-tenant-headers","canonical_path":"06-PROGRAMMING/bash/curl-with-tenant-headers.md","function_human":"Wrapper seguro para curl: inyección automática de X-Tenant-ID, retry con backoff y logging estructurado","constraints":["C1","C3","C4","C7","C8"],"dependencies":["bash-master-agent","timeout-and-retry-patterns","tenant-context-propagation"],"hydration_weight":"light","entrypoint_function":"curl_tenant_safe","validation_command":"bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {} --checks C3,C4,C8 --json","vectorizable":false,"tenant_context_required":true}
{"artifact_id":"webhook-handler-secure","canonical_path":"06-PROGRAMMING/bash/webhook-handler-secure.md","function_human":"Handler de webhooks con validación HMAC: verificación de firma, rate limiting y prevención de replay attacks","constraints":["C3","C4","C7"],"dependencies":["secrets-in-shell-c3","tenant-context-propagation"],"hydration_weight":"medium","entrypoint_function":"handle_webhook_hmac","validation_command":"bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {} --checks C3,C4 --json","vectorizable":false,"tenant_context_required":true}
{"artifact_id":"git-operations-tenant-scoped","canonical_path":"06-PROGRAMMING/bash/git-operations-tenant-scoped.md","function_human":"Operaciones Git aisladas por tenant: worktrees efímeros, validación de firmas GPG y scope de configuración","constraints":["C3","C4","C5","C7"],"dependencies":["tenant-context-propagation","filesystem-isolation-per-tenant"],"hydration_weight":"medium","entrypoint_function":"git_tenant_op","validation_command":"bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {} --checks C4,C5 --json","vectorizable":false,"tenant_context_required":true}
{"artifact_id":"docker-cli-tenant-isolation","canonical_path":"06-PROGRAMMING/bash/docker-cli-tenant-isolation.md","function_human":"Ejecución segura de Docker CLI: user namespace, límites de recursos por contenedor y aislamiento de volúmenes","constraints":["C1","C3","C4","C7"],"dependencies":["resource-limits-ulimit-cgroups","tenant-context-propagation"],"hydration_weight":"medium","entrypoint_function":"docker_tenant_run","validation_command":"bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {} --checks C1,C4 --json","vectorizable":false,"tenant_context_required":true}
{"artifact_id":"verify-constraints-hook","canonical_path":"06-PROGRAMMING/bash/verify-constraints-hook.md","function_human":"Hook de validación de constraints C1-C8: output JSON/JSONL per V-INT-03/V-LOG-02 para CI/CD","constraints":["C1","C3","C4","C5","C6","C7","C8"],"dependencies":["bash-master-agent","orchestrator-engine-bash-port"],"hydration_weight":"light","entrypoint_function":"validate_constraints_artifact","validation_command":"bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {} --checks C5,C8 --json","vectorizable":false,"tenant_context_required":false}
{"artifact_id":"audit-secrets-hook","canonical_path":"06-PROGRAMMING/bash/audit-secrets-hook.md","function_human":"Hook de detección de secrets hardcodeados: patrones regex para API keys, passwords y tokens con reporting estructurado","constraints":["C3","C5","C7","C8"],"dependencies":["bash-master-agent","secrets-in-shell-c3"],"hydration_weight":"light","entrypoint_function":"scan_for_hardcoded_secrets","validation_command":"bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {} --checks C3,C8 --json","vectorizable":false,"tenant_context_required":false}
{"artifact_id":"check-rls-hook","canonical_path":"06-PROGRAMMING/bash/check-rls-hook.md","function_human":"Hook de validación de aislamiento multi-tenant en SQL: análisis estático de queries para detectar leakage de contexto","constraints":["C4","C5","C8"],"dependencies":["tenant-context-propagation"],"hydration_weight":"light","entrypoint_function":"validate_tenant_scope_sql","validation_command":"bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {} --checks C4,C8 --json","vectorizable":false,"tenant_context_required":true}
{"artifact_id":"validate-frontmatter-hook","canonical_path":"06-PROGRAMMING/bash/validate-frontmatter-hook.md","function_human":"Hook de validación de frontmatter YAML: schema JSON, campos obligatorios y reporting de errores canónicos","constraints":["C5","C6","C8"],"dependencies":["bash-master-agent","yaml-processing-with-yq"],"hydration_weight":"light","entrypoint_function":"validate_frontmatter_schema","validation_command":"bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {} --checks C5,C6 --json","vectorizable":false,"tenant_context_required":false}
{"artifact_id":"structured-logging-json","canonical_path":"06-PROGRAMMING/bash/structured-logging-json.md","function_human":"Logging estructurado JSON desde shell: campos tenant_id, timestamp, command, status con correlación para Loki/OTel","constraints":["C4","C5","C8"],"dependencies":["bash-master-agent","tenant-context-propagation"],"hydration_weight":"light","entrypoint_function":"emit_structured_log","validation_command":"bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {} --checks C8 --json","vectorizable":false,"tenant_context_required":true}
{"artifact_id":"health-check-endpoint","canonical_path":"06-PROGRAMMING/bash/health-check-endpoint.md","function_human":"Endpoint de health check con métricas Prometheus-ready: validación de dependencias y estado de recursos","constraints":["C7","C8"],"dependencies":["bash-master-agent","structured-logging-json"],"hydration_weight":"light","entrypoint_function":"emit_health_metrics","validation_command":"bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {} --checks C7,C8 --json","vectorizable":false,"tenant_context_required":false}
{"artifact_id":"deployment-rollback-safe","canonical_path":"06-PROGRAMMING/bash/deployment-rollback-safe.md","function_human":"Despliegue con validación pre/post: snapshot de estado, verificación de integridad y rollback automático en error","constraints":["C3","C4","C5","C7"],"dependencies":["safe-file-operations","error-handling-traps"],"hydration_weight":"medium","entrypoint_function":"deploy_with_rollback","validation_command":"bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {} --checks C4,C5,C7 --json","vectorizable":false,"tenant_context_required":true}
{"artifact_id":"backup-tenant-scoped","canonical_path":"06-PROGRAMMING/bash/backup-tenant-scoped.md","function_human":"Backup de datos con aislamiento por tenant: verificación de integridad, logging estructurado y cleanup seguro","constraints":["C3","C4","C5","C7"],"dependencies":["filesystem-isolation-per-tenant","structured-logging-json"],"hydration_weight":"medium","entrypoint_function":"backup_tenant_data","validation_command":"bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {} --checks C4,C5 --json","vectorizable":false,"tenant_context_required":true}
{"artifact_id":"bash-unit-test-patterns","canonical_path":"06-PROGRAMMING/bash/bash-unit-test-patterns.md","function_human":"Patrones de testing con bats-core: fixtures aisladas por tenant, mocks de comandos y assertions canónicas","constraints":["C4","C5","C8"],"dependencies":["bash-master-agent","tenant-context-propagation"],"hydration_weight":"light","entrypoint_function":"setup_bats_fixture","validation_command":"bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {} --checks C5,C8 --json","vectorizable":false,"tenant_context_required":false}
{"artifact_id":"integration-test-fixtures","canonical_path":"06-PROGRAMMING/bash/integration-test-fixtures.md","function_human":"Fixtures de integración con setup/teardown seguro: validación de rutas, aislamiento de estado y rollback automático","constraints":["C3","C4","C7"],"dependencies":["filesystem-isolation-per-tenant","error-handling-traps"],"hydration_weight":"medium","entrypoint_function":"setup_integration_fixture","validation_command":"bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {} --checks C4,C7 --json","vectorizable":false,"tenant_context_required":true}
{"artifact_id":"fuzzing-inputs-security","canonical_path":"06-PROGRAMMING/bash/fuzzing-inputs-security.md","function_human":"Fuzzing de inputs de script: detección de command injection, path traversal y tenant leakage con reporting estructurado","constraints":["C3","C6","C7","C8"],"dependencies":["safe-variable-expansion","command-audit-logging-c8"],"hydration_weight":"medium","entrypoint_function":"fuzz_input_safe","validation_command":"bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {} --checks C3,C6,C8 --json","vectorizable":false,"tenant_context_required":false}
```
<!-- STACKSELECTOR_JSONL_END -->

---
