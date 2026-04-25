---
artifact_id: "00-INDEX-bash"
artifact_type: "skill_index"
version: "3.1.0-SELECTIVE"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/bash/00-INDEX.md --json"
canonical_path: "06-PROGRAMMING/bash/00-INDEX.md"
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
| `[[bash-hardening-verification.sh.md]]` | C3,C4,C5,C7,C8 | Validación de entorno shell, `set -euo pipefail`, límites de recursos pre-ejecución |
| `[[safe-variable-expansion.sh.md]]` | C3,C4,C5,C7 | Quoting seguro, `${VAR:?missing}`, prevención de word splitting e injection |
| `[[error-handling-traps.sh.md]]` | C4,C5,C7,C8 | Manejo de errores con `trap`, cleanup de temp files y logging estructurado |

### FASE 1 – Multi-Tenant Security (Aislamiento en Shell)
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[tenant-context-propagation.sh.md]]` | C3,C4,C5,C7,C8 | Propagación segura de `TENANT_ID` via env vars, validación de scope en subshells |
| `[[filesystem-isolation-per-tenant.sh.md]]` | C3,C4,C7 | Aislamiento de directorios de trabajo, temp files con `mktemp -d` y cleanup con trap |
| `[[secrets-in-shell-c3.sh.md]]` | C3,C5,C7 | Gestión de secrets: zero hardcode, lectura desde vault/env, masking en logs |
| `[[command-audit-logging-c8.sh.md]]` | C4,C5,C8 | Logging estructurado JSON de comandos ejecutados con correlación por tenant |

### FASE 2 – Resource Management & Concurrency
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[timeout-and-retry-patterns.sh.md]]` | C1,C4,C7,C8 | Timeouts con `timeout` cmd, retry con backoff exponencial y cancellation por tenant |
| `[[resource-limits-ulimit-cgroups.sh.md]]` | C1,C2,C7 | Limitación de CPU/memoria con `ulimit`, cgroups v2 y validación pre-ejecución |
| `[[parallel-execution-safe.sh.md]]` | C1,C4,C7 | Ejecución paralela con `xargs -P`, semáforos via flock y aislamiento de outputs por tenant |
| `[[orchestrator-engine-bash-port.sh.md]]` | C1,C3,C4,C5,C6,C7,C8 | Port del orchestrator principal → Bash modular con validación de constraints línea a línea |

### FASE 3 – Filesystem & Data Operations
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[safe-file-operations.sh.md]]` | C3,C4,C5,C7 | Operaciones de archivo con validación de paths, atomic writes y rollback en error |
| `[[json-processing-with-jq.sh.md]]` | C4,C5,C7,C8 | Procesamiento seguro de JSON con `jq`, validación de schema y tenant scoping en queries |
| `[[yaml-processing-with-yq.sh.md]]` | C4,C5,C7 | Procesamiento de YAML con `yq`, validación de estructura y propagación de contexto tenant |
| `[[csv-safe-parsing.sh.md]]` | C4,C5,C7 | Parsing seguro de CSV con manejo de comas en campos, quoting y validación de columnas |

### FASE 4 – API & External Integrations
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[curl-with-tenant-headers.sh.md]]` | C3,C4,C7,C8 | Wrapper de `curl` con inyección automática de `X-Tenant-ID`, retry logic y logging |
| `[[webhook-handler-secure.sh.md]]` | C3,C4,C7 | Handler de webhooks con validación de firma HMAC, rate limiting y replay attack prevention |
| `[[git-operations-tenant-scoped.sh.md]]` | C3,C4,C5,C7 | Operaciones Git con aislamiento de worktrees, validación de firmas GPG y scope por tenant |
| `[[docker-cli-tenant-isolation.sh.md]]` | C1,C3,C4,C7 | Ejecución segura de Docker CLI con límites de recursos, user namespace y aislamiento de volúmenes |

### FASE 5 – Validation Hooks & CI/CD
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[verify-constraints-hook.sh.md]]` | C1,C3,C4,C5,C6,C7,C8 | Hook de validación de constraints C1-C8 con output JSON/JSONL per V-INT-03/V-LOG-02 |
| `[[audit-secrets-hook.sh.md]]` | C3,C5,C7 | Hook de detección de secretos hardcodeados con patrones regex y reporting estructurado |
| `[[check-rls-hook.sh.md]]` | C4,C5,C8 | Hook de validación de aislamiento multi-tenant en artifacts SQL con análisis estático |
| `[[validate-frontmatter-hook.sh.md]]` | C5,C6,C8 | Hook de validación de frontmatter YAML con schema JSON y reporting de errores |

### FASE 6 – Observability & Deployment
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[structured-logging-json.sh.md]]` | C4,C5,C8 | Logging estructurado JSON desde shell con campos tenant_id, timestamp, command, status |
| `[[health-check-endpoint.sh.md]]` | C7,C8 | Endpoint de health check con métricas Prometheus-ready y validación de dependencias |
| `[[deployment-rollback-safe.sh.md]]` | C3,C4,C5,C7 | Despliegue con validación pre/post, snapshot de estado y rollback automático en error |
| `[[backup-tenant-scoped.sh.md]]` | C3,C4,C5,C7 | Backup de datos con aislamiento por tenant, verificación de integridad y logging estructurado |

### FASE 7 – Testing & Validation
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[bash-unit-test-patterns.sh.md]]` | C4,C5,C8 | Patrones de testing con `bats-core`, fixtures aisladas por tenant y mocks de comandos |
| `[[integration-test-fixtures.sh.md]]` | C3,C4,C7 | Fixtures de integración con setup/teardown seguro, validación de rutas y rollback automático |
| `[[fuzzing-inputs-security.sh.md]]` | C3,C7,C8 | Fuzzing de inputs de script con detección de command injection, path traversal y tenant leakage |

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

## 🤖 JSON TREE ENRIQUECIDO PARA IA (Metadatos + Dependencias + Prioridad de Normas)

```json
{
 "index_metadata": {
 "artifact_id": "00-INDEX-bash",
 "artifact_type": "skill_index",
 "version": "3.1.0-SELECTIVE",
 "canonical_path": "06-PROGRAMMING/bash/00-INDEX.md",
 "language_lock_status": "enforced",
 "vector_constraints_applied": false,
 "generated_timestamp": "2026-01-27T00:00:00Z",
 "master_agent": "bash-master-agent"
 },
 "artifacts": [
 {
 "artifact_id": "bash-master-agent",
 "file": "bash-master-agent.md",
 "canonical_path": "06-PROGRAMMING/bash/bash-master-agent.md",
 "artifact_type": "agentic_skill_definition",
 "tier": 1,
 "constraints_mapped": ["C1","C2","C3","C4","C5","C7","C8"],
 "language_lock": ["bash","shell","automation","cli"],
 "validation_hooks": ["verify-constraints.sh", "audit-secrets.sh", "shellcheck-validator.sh", "bash-syntax-check.sh"],
 "examples_count": 15,
 "score_baseline": 93,
 "dependencies": {
 "validators": ["verify-constraints.sh", "audit-secrets.sh", "shellcheck-validator.sh", "bash-syntax-check.sh"],
 "norms": ["harness-norms-v3.0.md", "10-SDD-CONSTRAINTS.md", "language-lock-protocol.md", "06-MULTITENANCY-RULES.md"],
 "config": ["norms-matrix.json", "skill-template.md"]
 },
 "dependents": ["all bash artifacts"],
 "norms_priority": {
 "execution_order": ["C4", "C3", "C5", "C7", "C8", "C1", "C2"],
 "blocking_constraints": ["C3", "C4"],
 "rationale": "Security (C3) and tenant isolation (C4) are foundational for shell script generation"
 },
 "interactions": {
 "with_validation": "Emits JSON to stdout, logs to stderr, JSONL to 08-LOGS/ per V-INT-03",
 "with_config": "Consults norms-matrix.json before declaring constraints in generated scripts",
 "with_programming": "Delegates vector operations to postgresql-pgvector/, SQL to sql/, backend logic to python/go/ per LANGUAGE LOCK"
 }
 },
 {
 "artifact_id": "bash-hardening-verification",
 "file": "bash-hardening-verification.sh.md",
 "canonical_path": "06-PROGRAMMING/bash/bash-hardening-verification.sh.md",
 "constraints_mapped": ["C3","C4","C5","C7","C8"],
 "examples_count": 10,
 "score_baseline": 90,
 "dependencies": {
 "validators": ["verify-constraints.sh", "shellcheck-validator.sh"],
 "norms": ["harness-norms-v3.0.md", "10-SDD-CONSTRAINTS.md"],
 "templates": ["skill-template.md"]
 },
 "dependents": ["all phase-1 to phase-7 artifacts"],
 "norms_priority": {
 "execution_order": ["C4", "C3", "C7", "C5", "C8"],
 "blocking_constraints": ["C4", "C3"],
 "rationale": "Pre-flight validation must confirm tenant isolation and shell security before any script execution"
 },
 "interactions": {
 "with_validation": "Provides baseline checks consumed by orchestrator-engine.sh",
 "with_config": "References norms-matrix.json for constraint routing logic",
 "with_programming": "NO interaction with postgresql-pgvector/ due to LANGUAGE LOCK"
 }
 },
 {
 "artifact_id": "tenant-context-propagation",
 "file": "tenant-context-propagation.sh.md",
 "canonical_path": "06-PROGRAMMING/bash/tenant-context-propagation.sh.md",
 "constraints_mapped": ["C3","C4","C5","C7","C8"],
 "examples_count": 12,
 "score_baseline": 92,
 "dependencies": {
 "validators": ["verify-constraints.sh", "audit-secrets.sh"],
 "norms": ["harness-norms-v3.0.md#C4", "06-MULTITENANCY-RULES.md"],
 "security_refs": ["03-SECURITY-RULES.md"]
 },
 "dependents": ["curl-with-tenant-headers", "filesystem-isolation-per-tenant", "command-audit-logging-c8"],
 "norms_priority": {
 "execution_order": ["C4", "C8", "C3", "C7", "C5"],
 "blocking_constraints": ["C4"],
 "rationale": "Context propagation is the enforcement mechanism for C4 in shell scripts; must be validated first"
 },
 "interactions": {
 "with_validation": "verify-constraints.sh validates TENANT_ID propagation in subshell examples",
 "with_config": "Aligns with multi-tenant rules in 06-MULTITENANCY-RULES.md",
 "with_programming": "Context patterns consumed by scripts before calling external commands/APIs"
 }
 },
 {
 "artifact_id": "secrets-in-shell-c3",
 "file": "secrets-in-shell-c3.sh.md",
 "canonical_path": "06-PROGRAMMING/bash/secrets-in-shell-c3.sh.md",
 "constraints_mapped": ["C3","C5","C7"],
 "examples_count": 10,
 "score_baseline": 91,
 "dependencies": {
 "validators": ["audit-secrets.sh", "verify-constraints.sh"],
 "norms": ["harness-norms-v3.0.md#C3"],
 "templates": [".env.example"]
 },
 "dependents": ["tenant-context-propagation", "curl-with-tenant-headers"],
 "norms_priority": {
 "execution_order": ["C3", "C7", "C5"],
 "blocking_constraints": ["C3"],
 "rationale": "Secrets handling is security-critical; must pass before structural checks"
 },
 "interactions": {
 "with_validation": "audit-secrets.sh validates zero hardcode secrets in examples",
 "with_config": "References .env.example for placeholder patterns",
 "with_programming": "Secrets patterns consumed by scripts at runtime via env vars"
 }
 },
 {
 "artifact_id": "verify-constraints-hook",
 "file": "verify-constraints-hook.sh.md",
 "canonical_path": "06-PROGRAMMING/bash/verify-constraints-hook.sh.md",
 "constraints_mapped": ["C1","C3","C4","C5","C6","C7","C8"],
 "examples_count": 14,
 "score_baseline": 94,
 "dependencies": {
 "validators": ["shellcheck-validator.sh", "bash-syntax-check.sh"],
 "norms": ["harness-norms-v3.0.md", "10-SDD-CONSTRAINTS.md"],
 "templates": ["skill-template.md"]
 },
 "dependents": ["audit-secrets-hook", "check-rls-hook", "validate-frontmatter-hook"],
 "norms_priority": {
 "execution_order": ["C4", "C3", "C5", "C7", "C8", "C1", "C6"],
 "blocking_constraints": ["C3", "C4"],
 "rationale": "Validation hooks are foundational for CI/CD; must enforce tenant isolation and security first"
 },
 "interactions": {
 "with_validation": "Hook validates other artifacts; self-validation via bash-syntax-check.sh",
 "with_config": "Parametrization patterns align with norms-matrix.json for constraint routing",
 "with_programming": "Core validation template consumed by orchestrator-engine.sh pipeline"
 }
 }
 ],
 "dependency_graph": {
 "validation_layer": {
 "orchestrator-engine.sh": ["all artifacts"],
 "verify-constraints.sh": ["all artifacts"],
 "audit-secrets.sh": ["secrets-in-shell-c3", "tenant-context-propagation", "bash-master-agent"],
 "shellcheck-validator.sh": ["bash-hardening-verification", "verify-constraints-hook", "bash-master-agent"],
 "bash-syntax-check.sh": ["safe-variable-expansion", "error-handling-traps", "bash-master-agent"]
 },
 "norms_layer": {
 "harness-norms-v3.0.md": ["all artifacts"],
 "10-SDD-CONSTRAINTS.md": ["all artifacts"],
 "language-lock-protocol.md": ["all artifacts"],
 "06-MULTITENANCY-RULES.md": ["tenant-context-propagation", "filesystem-isolation-per-tenant", "curl-with-tenant-headers"],
 "norms-matrix.json": ["all artifacts", "bash-master-agent"]
 },
 "config_layer": {
 "skill-template.md": ["all artifacts"],
 ".env.example": ["secrets-in-shell-c3", "tenant-context-propagation"]
 }
 },
 "norms_execution_priority": {
 "global_order": ["C4", "C3", "C7", "C5", "C8", "C1", "C2", "C6"],
 "rationale": "C4 (tenant isolation) is foundational; security (C3) and shell safety (C7) precede structural (C5) and observability (C8) checks",
 "blocking_set": ["C3", "C4", "C7"],
 "non_blocking_set": ["C1", "C2", "C5", "C6", "C8"],
 "selective_v_logic": {
 "applies_to": "postgresql-pgvector/ ONLY",
 "trigger": "artifact_type == 'skill_pgvector' AND content has pgvector operators",
 "exclusion": "bash/ ALWAYS excludes V1/V2/V3 per LANGUAGE LOCK"
 }
 },
 "language_lock_enforcement": {
 "folder": "06-PROGRAMMING/bash/",
 "prohibited_patterns": ["psql.*<->|<#>|<=>", "CREATE EXTENSION vector", "cosine_distance|l2_distance|hamming_distance", "vector\\("],
 "required_artifact_types": ["bash_script", "bash_pattern", "bash_cli", "bash_validation_hook"],
 "prohibited_constraints": ["V1", "V2", "V3"],
 "validation_script": "validate-skill-integrity.sh --check-language-lock",
 "failure_action": "exit 2 with message 'LANGUAGE LOCK VIOLATION: pgvector operators not allowed in Bash domain'"
 },
 "ai_navigation_hints": {
 "for_generation": "Read bash-master-agent.md AND this index BEFORE generating new Bash artifacts. Include `# 👇 EXPLICACIÓN:` comments in Spanish for pedagogy.",
 "for_validation": "Use norms_execution_priority: validate C4 before allowing external command calls in examples; use shellcheck for static analysis",
 "for_migration": "Consult dependency_graph before modifying shared patterns; shell changes may require downstream script updates",
 "for_debugging": "Check language_lock_enforcement if pgvector operators appear in bash/ artifacts; delegate to postgresql-pgvector/",
 "for_master_agent": "Agent must consult norms-matrix.json before declaring constraints; emit JSON to stdout, logs to stderr, JSONL to 08-LOGS/; delegate vector/SQL/backend logic to appropriate domains; include pedagogical comments in Spanish"
 }
}
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
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/bash-hardening-verification.sh.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/safe-variable-expansion.sh.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/error-handling-traps.sh.md

# Fase 1: Multi-Tenant Security
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/tenant-context-propagation.sh.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/filesystem-isolation-per-tenant.sh.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/secrets-in-shell-c3.sh.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/command-audit-logging-c8.sh.md

# Fase 2: Resource Management
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/timeout-and-retry-patterns.sh.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/resource-limits-ulimit-cgroups.sh.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/parallel-execution-safe.sh.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/orchestrator-engine-bash-port.sh.md

# Fase 3: Filesystem & Data
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/safe-file-operations.sh.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/json-processing-with-jq.sh.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/yaml-processing-with-yq.sh.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/csv-safe-parsing.sh.md

# Fase 4: API & External Integrations
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/curl-with-tenant-headers.sh.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/webhook-handler-secure.sh.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/git-operations-tenant-scoped.sh.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/docker-cli-tenant-isolation.sh.md

# Fase 5: Validation Hooks
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/verify-constraints-hook.sh.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/audit-secrets-hook.sh.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/check-rls-hook.sh.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/validate-frontmatter-hook.sh.md

# Fase 6: Observability & Deployment
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/structured-logging-json.sh.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/health-check-endpoint.sh.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/deployment-rollback-safe.sh.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/backup-tenant-scoped.sh.md

# Fase 7: Testing
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/bash-unit-test-patterns.sh.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/integration-test-fixtures.sh.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/fuzzing-inputs-security.sh.md
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
06-PROGRAMMING/bash/bash-hardening-verification.sh.md
06-PROGRAMMING/bash/safe-variable-expansion.sh.md
06-PROGRAMMING/bash/error-handling-traps.sh.md

# Fase 1: Multi-Tenant Security
06-PROGRAMMING/bash/tenant-context-propagation.sh.md
06-PROGRAMMING/bash/filesystem-isolation-per-tenant.sh.md
06-PROGRAMMING/bash/secrets-in-shell-c3.sh.md
06-PROGRAMMING/bash/command-audit-logging-c8.sh.md

# Fase 2: Resource Management
06-PROGRAMMING/bash/timeout-and-retry-patterns.sh.md
06-PROGRAMMING/bash/resource-limits-ulimit-cgroups.sh.md
06-PROGRAMMING/bash/parallel-execution-safe.sh.md
06-PROGRAMMING/bash/orchestrator-engine-bash-port.sh.md

# Fase 3: Filesystem & Data
06-PROGRAMMING/bash/safe-file-operations.sh.md
06-PROGRAMMING/bash/json-processing-with-jq.sh.md
06-PROGRAMMING/bash/yaml-processing-with-yq.sh.md
06-PROGRAMMING/bash/csv-safe-parsing.sh.md

# Fase 4: API & External Integrations
06-PROGRAMMING/bash/curl-with-tenant-headers.sh.md
06-PROGRAMMING/bash/webhook-handler-secure.sh.md
06-PROGRAMMING/bash/git-operations-tenant-scoped.sh.md
06-PROGRAMMING/bash/docker-cli-tenant-isolation.sh.md

# Fase 5: Validation Hooks
06-PROGRAMMING/bash/verify-constraints-hook.sh.md
06-PROGRAMMING/bash/audit-secrets-hook.sh.md
06-PROGRAMMING/bash/check-rls-hook.sh.md
06-PROGRAMMING/bash/validate-frontmatter-hook.sh.md

# Fase 6: Observability & Deployment
06-PROGRAMMING/bash/structured-logging-json.sh.md
06-PROGRAMMING/bash/health-check-endpoint.sh.md
06-PROGRAMMING/bash/deployment-rollback-safe.sh.md
06-PROGRAMMING/bash/backup-tenant-scoped.sh.md

# Fase 7: Testing
06-PROGRAMMING/bash/bash-unit-test-patterns.sh.md
06-PROGRAMMING/bash/integration-test-fixtures.sh.md
06-PROGRAMMING/bash/fuzzing-inputs-security.sh.md
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
  
  local extension=".sh.md"
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
```

---
