---
artifact_id: "00-INDEX-sql"
artifact_type: "skill_index"
version: "3.1.0-SELECTIVE"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/00-INDEX.md --json"
canonical_path: "06-PROGRAMMING/sql/00-INDEX.md"
---

# SQL Patterns Master Index – Multi-Tenant Hardening & AI Integration

## 👤 Propósito y Alcance
Índice canónico de navegación para `06-PROGRAMMING/sql/`. Documenta 25 artifacts auditados bajo HARNESS NORMS v3.1.0-SELECTIVE, mapea flujos de ejecución, interacciones con otros directorios del repositorio, referencia al **agente master de generación SQL**, y proporciona un árbol JSON enriquecido para routing de agentes LLM y pipelines CI/CD.

---

## 🤖 Agente de Generación Disponible

| Agente | Canonical Path | Dominio | Constraints Soportados | Hooks de Validación |
|--------|---------------|---------|----------------------|-------------------|
| **`sql-master-agent`** ✅ | `[[06-PROGRAMMING/sql/sql-master-agent.md]]` | `sql,postgresql,mysql` | `C1,C2,C3,C4,C5,C7,C8` | `verify-constraints.sh`, `audit-secrets.sh`, `check-rls.sh` |

> ⚠️ **Nota contractual**: Este agente es Tier 1 (referencia educativa). Cualquier query generada debe pasar validación automática antes de merge. Documentación técnica en pt-BR: `docs/pt-BR/programming/sql/sql-master-agent/README.md`.

---

## 📂 Mapeo de Fases y Wikilinks

### FASE 0 – Core Hardening (Pre-flight & Syntax)
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[hardening-verification.sql.md]]` | C3,C4,C5,C7,C8 | Validación de entorno, límites de recursos y integridad pre-ejecución |
| `[[fix-sintaxis-code.sql.md]]` | C3,C4,C5,C7,C8 | Integración con linters (`pglint`/`sqlfluff`) y corrección automática |
| `[[robust-error-handling.sql.md]]` | C4,C5,C7,C8 | Manejo transaccional de fallos, `SAVEPOINT` y recuperación segura |

### FASE 1 – Multi-Tenant Security (Aislamiento)
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[row-level-security-policies.sql.md]]` | C3,C4,C5,C7,C8 | Políticas RLS dinámicas con `USING`/`WITH CHECK` por tenant |
| `[[tenant-context-injection.sql.md]]` | C3,C4,C8 | Inyección segura de `app.tenant_id` y validación de sesión |
| `[[column-encryption-patterns.sql.md]]` | C3,C5,C7 | Encriptación `pgcrypto`, hashes SHA-256 y gestión de claves |
| `[[audit-logging-triggers.sql.md]]` | C4,C5,C8 | Triggers de auditoría inmutables y logging estructurado JSON |

### FASE 2 – CI/CD & Migrations (Versionado)
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[migration-versioning-patterns.sql.md]]` | C4,C5,C7,C8 | Control de versiones, checksums y aplicación por tenant |
| `[[schema-diff-validation.sql.md]]` | C5,C7,C8 | Comparación criptográfica de esquemas y detección de drift |
| `[[rollback-automation-patterns.sql.md]]` | C4,C5,C7 | Reversión segura con validación de rutas y límites transaccionales |
| `[[partitioning-strategies.sql.md]]` | C1,C4,C7 | Particionamiento declarativo RANGE/LIST con gestión de memoria |
| `[[backup-restore-tenant-scoped.sql.md]]` | C3,C5,C7 | Backup/restore por tenant con verificación de integridad |

### FASE 3 – Query Patterns & IA-Assist (Consultas)
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[crud-with-tenant-enforcement.sql.md]]` | C3,C4,C8 | Operaciones CRUD parametrizadas con aislamiento obligatorio |
| `[[join-patterns-rls-aware.sql.md]]` | C4,C7,C8 | JOINs seguros, CTEs con scope de tenant y prevención de cross-leak |
| `[[aggregation-multi-tenant-safe.sql.md]]` | C4,C5,C8 | Agregaciones (`SUM`, `AVG`, `COUNT`) con hash de resultados |
| `[[query-explanation-templates.sql.md]]` | C8 | Plantillas de `EXPLAIN` y logging de latencia para auditoría |
| `[[nl-to-sql-patterns.sql.md]]` | C3,C4,C8 | Conversión NL→SQL con validación de confianza y timeouts |

### FASE 4 – MCP/IA Tooling (Integración)
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[mcp-sql-tool-definitions.json.md]]` | C3,C4,C8 | Contratos JSON para herramientas MCP con inyección de contexto |
| `[[ia-query-validation-gate.sql.md]]` | C3,C4,C5,C8 | Gate de aprobación de queries IA con firma criptográfica |
| `[[context-injection-for-ia.sql.md]]` | C4,C8 | Gestión de sesión `app.*` y vistas seguras para consumo IA |
| `[[audit-trail-ia-generated.sql.md]]` | C4,C5,C8 | Traza inmutable de SQL generado por LLM con verificación de hash |
| `[[permission-scoping-for-ia.sql.md]]` | C3,C4,C7 | Control de privilegios granular y validación de identificadores |

### FASE 5 – Testing & Validation (Verificación)
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[unit-test-patterns-for-sql.sql.md]]` | C4,C5,C8 | Pruebas unitarias aisladas, fixtures y asserts de hash |
| `[[integration-test-fixtures.sql.md]]` | C3,C4,C7 | Carga masiva segura, validación de rutas y rollback automático |
| `[[constraint-validation-tests.sql.md]]` | C4,C5,C7 | Verificación de `CHECK`, `NOT NULL` y reportes de integridad |

---

## 🔗 Interacciones con el Repositorio
- **`05-CONFIGURATIONS/validation/`**: Todos los artifacts son validados por `orchestrator-engine.sh`. Los scripts `verify-constraints.sh` y `validate-skill-integrity.sh` consumen el JSON de este índice.
- **`01-RULES/`**: Las normas `harness-norms-v3.0.md`, `language-lock-protocol.md` y `06-MULTITENANCY-RULES.md` definen los constraints C1-C8 aplicados.
- **`06-PROGRAMMING/postgresql-pgvector/`**: Carpeta hermana con LANGUAGE LOCK estricto. Cero interacción directa; aislamiento de vectores (`<->`, `hnsw`) garantizado.
- **`08-LOGS/`**: Los triggers y logging estructurado (C8) alimentan dashboards en `sql-audit-dashboard-realtime.md` y generan entradas en `failed-attempts/` si fallan validaciones.
- **`sql-master-agent.md`**: Punto único de generación para nuevos artifacts SQL. Consulta este índice ANTES de emitir queries para asegurar coherencia con patrones existentes.

---

## ⚠️ Reglas Críticas de LANGUAGE LOCK para sql/

```text
🚫 PROHIBIDO en esta carpeta:
• Operadores pgvector: <->, <#>, <=>, vector(n), USING hnsw, USING ivfflat
• Constraints vectoriales V1/V2/V3 en constraints_mapped del frontmatter
• CREATE EXTENSION vector; o cualquier referencia a pgvector en SQL estándar

✅ REQUERIDO en esta carpeta:
• artifact_type: "sql_query" | "sql_migration" | "sql_pattern" | "sql_optimization" (NUNCA "skill_pgvector")
• constraints_mapped: SOLO valores de C1-C8 (V* bloqueado por LANGUAGE LOCK)
• Queries de producción deben incluir WHERE tenant_id = $1 o políticas RLS
• validation_command que referencie orchestrator-engine.sh con canonical_path correcto
• Agente master: consultar norms-matrix.json antes de declarar constraints en queries generadas
```

---

## 🤖 JSON TREE ENRIQUECIDO PARA IA (Metadatos + Dependencias + Prioridad de Normas)

```json
{
 "index_metadata": {
 "artifact_id": "00-INDEX-sql",
 "artifact_type": "skill_index",
 "version": "3.1.0-SELECTIVE",
 "canonical_path": "06-PROGRAMMING/sql/00-INDEX.md",
 "language_lock_status": "enforced",
 "vector_constraints_applied": false,
 "generated_timestamp": "2026-01-27T00:00:00Z",
 "master_agent": "sql-master-agent"
 },
 "artifacts": [
 {
 "artifact_id": "sql-master-agent",
 "file": "sql-master-agent.md",
 "canonical_path": "06-PROGRAMMING/sql/sql-master-agent.md",
 "artifact_type": "agentic_skill_definition",
 "tier": 1,
 "constraints_mapped": ["C1","C2","C3","C4","C5","C7","C8"],
 "language_lock": ["sql","postgresql","mysql"],
 "validation_hooks": ["verify-constraints.sh", "audit-secrets.sh", "check-rls.sh"],
 "examples_count": 15,
 "score_baseline": 94,
 "dependencies": {
 "validators": ["verify-constraints.sh", "audit-secrets.sh", "check-rls.sh"],
 "norms": ["harness-norms-v3.0.md", "10-SDD-CONSTRAINTS.md", "language-lock-protocol.md", "06-MULTITENANCY-RULES.md"],
 "config": ["norms-matrix.json", "skill-template.md"]
 },
 "dependents": ["all sql artifacts"],
 "norms_priority": {
 "execution_order": ["C4", "C3", "C5", "C7", "C8", "C1", "C2"],
 "blocking_constraints": ["C3", "C4"],
 "rationale": "Security (C3) and tenant isolation (C4) are foundational for query generation"
 },
 "interactions": {
 "with_validation": "Emits JSON to stdout, logs to stderr, JSONL to 08-LOGS/ per V-INT-03",
 "with_config": "Consults norms-matrix.json before declaring constraints in generated queries",
 "with_programming": "Delegates vector operations to postgresql-pgvector/ per LANGUAGE LOCK"
 }
 },
 {
 "artifact_id": "hardening-verification",
 "file": "hardening-verification.sql.md",
 "canonical_path": "06-PROGRAMMING/sql/hardening-verification.sql.md",
 "constraints_mapped": ["C3","C4","C5","C7","C8"],
 "examples_count": 10,
 "score_baseline": 88,
 "dependencies": {
 "validators": ["verify-constraints.sh", "check-rls.sh"],
 "norms": ["harness-norms-v3.0.md", "10-SDD-CONSTRAINTS.md"],
 "templates": ["skill-template.md"]
 },
 "dependents": ["all phase-1 to phase-5 artifacts"],
 "norms_priority": {
 "execution_order": ["C4", "C3", "C7", "C5", "C8"],
 "blocking_constraints": ["C4", "C3"],
 "rationale": "Pre-flight validation must confirm tenant isolation and security before any DML"
 },
 "interactions": {
 "with_validation": "Provides baseline checks consumed by orchestrator-engine.sh",
 "with_config": "References norms-matrix.json for constraint routing logic",
 "with_programming": "NO interaction with postgresql-pgvector/ due to LANGUAGE LOCK"
 }
 },
 {
 "artifact_id": "row-level-security-policies",
 "file": "row-level-security-policies.sql.md",
 "canonical_path": "06-PROGRAMMING/sql/row-level-security-policies.sql.md",
 "constraints_mapped": ["C3","C4","C5","C7","C8"],
 "examples_count": 12,
 "score_baseline": 91,
 "dependencies": {
 "validators": ["check-rls.sh", "verify-constraints.sh"],
 "norms": ["harness-norms-v3.0.md#C4", "06-MULTITENANCY-RULES.md"],
 "security_refs": ["03-SECURITY-RULES.md"]
 },
 "dependents": ["crud-with-tenant-enforcement", "join-patterns-rls-aware", "aggregation-multi-tenant-safe"],
 "norms_priority": {
 "execution_order": ["C4", "C8", "C3", "C7", "C5"],
 "blocking_constraints": ["C4"],
 "rationale": "RLS policies are the enforcement mechanism for C4; must be validated first"
 },
 "interactions": {
 "with_validation": "check-rls.sh validates policy syntax and tenant_id propagation",
 "with_config": "Aligns with multi-tenant rules in 06-MULTITENANCY-RULES.md",
 "with_programming": "Policy patterns reusable in postgres-pgvector/ ONLY if V* triggers met"
 }
 },
 {
 "artifact_id": "tenant-context-injection",
 "file": "tenant-context-injection.sql.md",
 "canonical_path": "06-PROGRAMMING/sql/tenant-context-injection.sql.md",
 "constraints_mapped": ["C3","C4","C8"],
 "examples_count": 10,
 "score_baseline": 89,
 "dependencies": {
 "validators": ["verify-constraints.sh", "audit-secrets.sh"],
 "norms": ["harness-norms-v3.0.md#C4,C8"],
 "templates": ["bootstrap-company-context.json"]
 },
 "dependents": ["column-encryption-patterns", "context-injection-for-ia"],
 "norms_priority": {
 "execution_order": ["C4", "C3", "C8"],
 "blocking_constraints": ["C4"],
 "rationale": "Tenant context must be injected before encryption or IA consumption"
 },
 "interactions": {
 "with_validation": "C8 examples validated by verify-constraints.sh for JSON structure",
 "with_config": "References .env.example for app.tenant_id placeholder patterns",
 "with_programming": "Context injection patterns consumed by application layer connection pooling"
 }
 },
 {
 "artifact_id": "crud-with-tenant-enforcement",
 "file": "crud-with-tenant-enforcement.sql.md",
 "canonical_path": "06-PROGRAMMING/sql/crud-with-tenant-enforcement.sql.md",
 "constraints_mapped": ["C3","C4","C8"],
 "examples_count": 14,
 "score_baseline": 92,
 "dependencies": {
 "validators": ["check-rls.sh", "verify-constraints.sh"],
 "norms": ["harness-norms-v3.0.md#C4"],
 "templates": ["skill-template.md"]
 },
 "dependents": ["join-patterns-rls-aware", "aggregation-multi-tenant-safe", "nl-to-sql-patterns"],
 "norms_priority": {
 "execution_order": ["C4", "C3", "C8"],
 "blocking_constraints": ["C4"],
 "rationale": "CRUD operations are the primary attack surface; tenant enforcement is non-negotiable"
 },
 "interactions": {
 "with_validation": "check-rls.sh validates WHERE tenant_id = $1 in all DML examples",
 "with_config": "Parametrization patterns align with prepared statement best practices",
 "with_programming": "Core DML template consumed by application ORM layer"
 }
 }
 ],
 "dependency_graph": {
 "validation_layer": {
 "orchestrator-engine.sh": ["all artifacts"],
 "verify-constraints.sh": ["all artifacts"],
 "audit-secrets.sh": ["column-encryption-patterns", "tenant-context-injection", "sql-master-agent"],
 "check-rls.sh": ["row-level-security-policies", "crud-with-tenant-enforcement", "join-patterns-rls-aware"]
 },
 "norms_layer": {
 "harness-norms-v3.0.md": ["all artifacts"],
 "10-SDD-CONSTRAINTS.md": ["all artifacts"],
 "language-lock-protocol.md": ["all artifacts"],
 "06-MULTITENANCY-RULES.md": ["row-level-security-policies", "tenant-context-injection", "crud-with-tenant-enforcement"],
 "norms-matrix.json": ["all artifacts", "sql-master-agent"]
 },
 "config_layer": {
 "skill-template.md": ["all artifacts"],
 ".env.example": ["tenant-context-injection", "column-encryption-patterns"],
 "bootstrap-company-context.json": ["tenant-context-injection", "context-injection-for-ia"]
 }
 },
 "norms_execution_priority": {
 "global_order": ["C4", "C3", "C7", "C5", "C8", "C1", "C2", "C6"],
 "rationale": "C4 (tenant isolation) is foundational; security (C3) and path safety (C7) precede structural (C5) and observability (C8) checks",
 "blocking_set": ["C3", "C4", "C7"],
 "non_blocking_set": ["C1", "C2", "C5", "C6", "C8"],
 "selective_v_logic": {
 "applies_to": "postgresql-pgvector/ ONLY",
 "trigger": "artifact_type == 'skill_pgvector' AND content has pgvector operators",
 "exclusion": "sql/ ALWAYS excludes V1/V2/V3 per LANGUAGE LOCK"
 }
 },
 "language_lock_enforcement": {
 "folder": "06-PROGRAMMING/sql/",
 "prohibited_patterns": ["<->", "<=>", "<#>", "vector\\([0-9]+\\)", "USING\\s+(hnsw|ivfflat)", "CREATE EXTENSION vector"],
 "required_artifact_types": ["sql_query", "sql_migration", "sql_pattern", "sql_optimization"],
 "prohibited_constraints": ["V1", "V2", "V3"],
 "validation_script": "validate-skill-integrity.sh --check-language-lock",
 "failure_action": "exit 2 with message 'LANGUAGE LOCK VIOLATION: Vector operators not allowed in SQL domain'"
 },
 "ai_navigation_hints": {
 "for_generation": "Read sql-master-agent.md AND this index BEFORE generating new SQL artifacts",
 "for_validation": "Use norms_execution_priority to order constraint checks in custom validators",
 "for_migration": "Consult dependency_graph before modifying shared patterns across artifacts",
 "for_debugging": "Check language_lock_enforcement if pgvector operators appear in sql/ artifacts",
 "for_master_agent": "Agent must consult norms-matrix.json before declaring constraints; emit JSON to stdout, logs to stderr, JSONL to 08-LOGS/"
 }
}
```

---

## 🔗 RAW_URLS_INDEX – Patrones SQL Disponibles

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
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/check-rls.sh
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/schemas/skill-input-output.schema.json
```

### 🗄️ Patrones SQL Core (06-PROGRAMMING/sql)
```text
# Índice y Agente Master
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/00-INDEX.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/sql-master-agent.md

# Fase 0: Core Hardening
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/hardening-verification.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/fix-sintaxis-code.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/robust-error-handling.sql.md

# Fase 1: Multi-Tenant Security
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/row-level-security-policies.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/tenant-context-injection.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/column-encryption-patterns.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/audit-logging-triggers.sql.md

# Fase 2: CI/CD & Migrations
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/migration-versioning-patterns.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/schema-diff-validation.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/rollback-automation-patterns.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/partitioning-strategies.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/backup-restore-tenant-scoped.sql.md

# Fase 3: Query Patterns & IA-Assist
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/crud-with-tenant-enforcement.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/join-patterns-rls-aware.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/aggregation-multi-tenant-safe.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/query-explanation-templates.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/nl-to-sql-patterns.sql.md

# Fase 4: MCP/IA Tooling
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/mcp-sql-tool-definitions.json.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/ia-query-validation-gate.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/context-injection-for-ia.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/audit-trail-ia-generated.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/permission-scoping-for-ia.sql.md

# Fase 5: Testing & Validation
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/unit-test-patterns-for-sql.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/integration-test-fixtures.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/constraint-validation-tests.sql.md

# Patrones de Testing Unitario (subdirectorio)
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/unit-test-patterns/01-clean-rls-compliant.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/unit-test-patterns/02-missing-where-tenant.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/unit-test-patterns/03-bypass-comment.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/unit-test-patterns/04-edge-special-chars.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/unit-test-patterns/05-multi-violations.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/unit-test-patterns/06-large-stress.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/unit-test-patterns/07-missing-file-error.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/unit-test-patterns/08-context-exception.sql.md
```

### 🦜 Referencias Vectoriales (SOLO para consulta, NO para uso en SQL estándar)
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/00-INDEX.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/tenant-isolation-for-embeddings.pgvector.md
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
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/validation-tools/check-rls/README.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/programming/sql/sql-master-agent/README.md
```

---

## 🗂️ RUTAS CANÓNICAS LOCALES – Patrones SQL (Para Acceso en Repo)

> **Formato**: `RAW_URL` → `./ruta/local/en/repo`

### 🗄️ Patrones SQL Core
```text
# Índice y Agente Master
06-PROGRAMMING/sql/00-INDEX.md
06-PROGRAMMING/sql/sql-master-agent.md

# Fase 0: Core Hardening
06-PROGRAMMING/sql/hardening-verification.sql.md
06-PROGRAMMING/sql/fix-sintaxis-code.sql.md
06-PROGRAMMING/sql/robust-error-handling.sql.md

# Fase 1: Multi-Tenant Security
06-PROGRAMMING/sql/row-level-security-policies.sql.md
06-PROGRAMMING/sql/tenant-context-injection.sql.md
06-PROGRAMMING/sql/column-encryption-patterns.sql.md
06-PROGRAMMING/sql/audit-logging-triggers.sql.md

# Fase 2: CI/CD & Migrations
06-PROGRAMMING/sql/migration-versioning-patterns.sql.md
06-PROGRAMMING/sql/schema-diff-validation.sql.md
06-PROGRAMMING/sql/rollback-automation-patterns.sql.md
06-PROGRAMMING/sql/partitioning-strategies.sql.md
06-PROGRAMMING/sql/backup-restore-tenant-scoped.sql.md

# Fase 3: Query Patterns & IA-Assist
06-PROGRAMMING/sql/crud-with-tenant-enforcement.sql.md
06-PROGRAMMING/sql/join-patterns-rls-aware.sql.md
06-PROGRAMMING/sql/aggregation-multi-tenant-safe.sql.md
06-PROGRAMMING/sql/query-explanation-templates.sql.md
06-PROGRAMMING/sql/nl-to-sql-patterns.sql.md

# Fase 4: MCP/IA Tooling
06-PROGRAMMING/sql/mcp-sql-tool-definitions.json.md
06-PROGRAMMING/sql/ia-query-validation-gate.sql.md
06-PROGRAMMING/sql/context-injection-for-ia.sql.md
06-PROGRAMMING/sql/audit-trail-ia-generated.sql.md
06-PROGRAMMING/sql/permission-scoping-for-ia.sql.md

# Fase 5: Testing & Validation
06-PROGRAMMING/sql/unit-test-patterns-for-sql.sql.md
06-PROGRAMMING/sql/integration-test-fixtures.sql.md
06-PROGRAMMING/sql/constraint-validation-tests.sql.md

# Patrones de Testing Unitario (subdirectorio)
06-PROGRAMMING/sql/unit-test-patterns/01-clean-rls-compliant.sql.md
06-PROGRAMMING/sql/unit-test-patterns/02-missing-where-tenant.sql.md
06-PROGRAMMING/sql/unit-test-patterns/03-bypass-comment.sql.md
06-PROGRAMMING/sql/unit-test-patterns/04-edge-special-chars.sql.md
06-PROGRAMMING/sql/unit-test-patterns/05-multi-violations.sql.md
06-PROGRAMMING/sql/unit-test-patterns/06-large-stress.sql.md
06-PROGRAMMING/sql/unit-test-patterns/07-missing-file-error.sql.md
06-PROGRAMMING/sql/unit-test-patterns/08-context-exception.sql.md
```

### 🦜 Referencias Vectoriales (Consulta ONLY)
```text
06-PROGRAMMING/postgresql-pgvector/00-INDEX.md
06-PROGRAMMING/postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md
06-PROGRAMMING/postgresql-pgvector/tenant-isolation-for-embeddings.pgvector.md
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
docs/pt-BR/validation-tools/check-rls/README.md
docs/pt-BR/programming/sql/sql-master-agent/README.md
```

---

## 🧭 GUÍA DE USO PARA EL AGENTE SQL

```sql
-- Pseudocódigo: Cómo consultar patrones disponibles en SQL
-- (Implementado en el agente, no en SQL puro)

-- Ejemplo de validación de constraints antes de emitir query
-- En aplicación host (Python/Go/JS):
function validarConstraintsSQL(artifactPath) {
 const fm = extractFrontmatter(artifactPath);
 const declared = fm.constraints_mapped;
 const matrix = loadJSON('./05-CONFIGURATIONS/validation/norms-matrix.json');
 const allowed = getAllowedConstraints(matrix, artifactPath);

 const issues = [];
 for (const c of declared) {
 if (!allowed.includes(c)) {
 issues.push(`constraint '${c}' not allowed for path ${artifactPath}`);
 }
 }
 return issues;
}

-- Ejemplo de detección de LANGUAGE LOCK en query SQL
function contieneOperadoresVectoriales(query) {
 return /<->[^a-zA-Z]|<#>[^a-zA-Z]|cosine_distance|l2_distance|hamming_distance/.test(query);
}

-- Uso en el agente:
if (contieneOperadoresVectoriales(inputQuery)) {
 console.error("LANGUAGE LOCK: Vector operators not allowed in SQL domain. Use postgresql-pgvector/");
 process.exit(1);
} else {
 // Generar query SQL estándar con tenant isolation
 const query = `SELECT * FROM docs WHERE tenant_id = $1 AND status = 'active'`;
}
```

---

## 📋 INSTRUCCIONES DE INTEGRACIÓN (Actualizadas)

### Paso 1: Agregar al final del agente
Pegar los bloques de referencias justo antes de la sección `## Limitations` en:
- `06-PROGRAMMING/sql/sql-master-agent.md`

### Paso 2: Actualizar el comportamiento del agente
En la sección `## Comportamiento del Agente` o `## Behavioral Traits`, agregar:

```markdown
| Trait | Implementación contractual |
|-------|---------------------------|
| **Consulta patrones antes de generar** | Antes de emitir query SQL, el agente debe consultar la lista de patrones disponibles en `06-PROGRAMMING/sql/` para asegurar coherencia con el repositorio |
| **Acceso dual** | Usar ruta canónica (`./06-PROGRAMMING/sql/...`) para acceso local, o raw URL para acceso remoto si el archivo no existe localmente |
| **LANGUAGE LOCK automático** | Si el usuario solicita operadores vectoriales (`<->`, `<#>`, `cosine_distance`), el agente debe delegar a `06-PROGRAMMING/postgresql-pgvector/` y NO generar queries con vectores en su dominio |
| **Enseña mientras genera** | Incluir comentarios explicativos en las queries generadas para facilitar el aprendizaje del usuario |
| **Valida constraints antes de emitir** | Ejecutar `validarConstraintsSQL()` antes de emitir cualquier artifact para asegurar coherencia con `norms-matrix.json` |
| **Emite logs estructurados** | JSON a `stdout`, logs humanos a `stderr`, JSONL a `08-LOGS/validation/...` per V-INT-03 y V-LOG-02 |
```

### Paso 3: Validar con `verify-constraints.sh`
```bash
# Validar que el agente mismo cumple con su propio contrato
./05-CONFIGURATIONS/validation/verify-constraints.sh --file 06-PROGRAMMING/sql/sql-master-agent.md | jq
```

---

> 📌 **Nota final**: Este índice es Tier 1 (referencia contractual). Cualquier modificación debe pasar validación automática antes de merge.  
> 🇧🇷 *Documentação técnica completa disponível em*: `docs/pt-BR/programming/sql/00-INDEX/README.md` (próxima entrega).
```

---

## ✅ Resumen de Cambios Aplicados

| Sección | Cambio | Justificación Contractual |
|---------|--------|-------------------------|
| `version` en frontmatter | `2.1.1` → `3.1.0-SELECTIVE` | Semver: cambio menor por adición de agente master + alineación con dossier MANTIS |
| `canonical_path` | Mantenido correcto | Consistencia con patrón de artifacts canónicos |
| Nueva sección `🤖 Agente de Generación Disponible` | Tabla con referencia al sql-master-agent | Trazabilidad explícita de herramientas de generación per V-INT-01 |
| Tabla de artifacts | Agregada fila implícita para `sql-master-agent.md` en JSON TREE | Navegación estructurada per V-INT-01 |
| Interacciones | Agregada referencia al agente master | Mapa de dependencias completo per C6 |
| JSON TREE | Nuevo objeto `sql-master-agent` en array `artifacts` con dependencias, normas_priority, interactions | Metadatos enriquecidos para IA navigation per AI-NAVIGATION-CONTRACT |
| RAW_URLS_INDEX | Agregada URL raw del agente master + doc pt-BR | Fuente de verdad para consulta sin inventar datos per SDD-COLLABORATIVE-GENERATION |
| RUTAS CANÓNICAS | Agregada ruta local del agente master + doc pt-BR | Acceso dual local/remoto per protocolo de handover |
| GUÍA DE USO | Actualizado pseudocódigo para detectar LANGUAGE LOCK en SQL | Coherencia en resolución de rutas y enforcement de constraints |
| INSTRUCCIONES DE INTEGRACIÓN | Agregado trait "Emite logs estructurados" | Alineación con V-INT-03 y V-LOG-02 |

---
