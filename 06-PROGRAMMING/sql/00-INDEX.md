# SHA256: f1e2d3c4b5a6987012345678901234567890123456789012345678901234569
---
artifact_id: "00-INDEX"
artifact_type: "skill_sql"
version: "2.1.1"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/00-INDEX.md --json"
canonical_path: "06-PROGRAMMING/sql/00-INDEX.md"
---

# SQL Patterns Master Index – Multi-Tenant Hardening & AI Integration

## 👤 Propósito y Alcance
Índice canónico de navegación para `06-PROGRAMMING/sql/`. Documenta 25 artifacts auditados bajo HARNESS NORMS v2.1.1, mapea flujos de ejecución, interacciones con otros directorios del repositorio y proporciona un árbol JSON enriquecido para routing de agentes LLM y pipelines CI/CD.

## 📂 Mapeo de Fases y Wikilinks

### FASE 0 – Core Hardening (Pre-flight & Syntax)
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| [[hardening-verification.sql.md]] | C3,C4,C5,C7,C8 | Validación de entorno, límites de recursos y integridad pre-ejecución |
| [[fix-sintaxis-code.sql.md]] | C3,C4,C5,C7,C8 | Integración con linters (`pglint`/`sqlfluff`) y corrección automática |
| [[robust-error-handling.sql.md]] | C4,C5,C7,C8 | Manejo transaccional de fallos, `SAVEPOINT` y recuperación segura |

### FASE 1 – Multi-Tenant Security (Aislamiento)
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| [[row-level-security-policies.sql.md]] | C3,C4,C5,C7,C8 | Políticas RLS dinámicas con `USING`/`WITH CHECK` por tenant |
| [[tenant-context-injection.sql.md]] | C3,C4,C8 | Inyección segura de `app.tenant_id` y validación de sesión |
| [[column-encryption-patterns.sql.md]] | C3,C5,C7 | Encriptación `pgcrypto`, hashes SHA-256 y gestión de claves |
| [[audit-logging-triggers.sql.md]] | C4,C5,C8 | Triggers de auditoría inmutables y logging estructurado JSON |

### FASE 2 – CI/CD & Migrations (Versionado)
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| [[migration-versioning-patterns.sql.md]] | C4,C5,C7,C8 | Control de versiones, checksums y aplicación por tenant |
| [[schema-diff-validation.sql.md]] | C5,C7,C8 | Comparación criptográfica de esquemas y detección de drift |
| [[rollback-automation-patterns.sql.md]] | C4,C5,C7 | Reversión segura con validación de rutas y límites transaccionales |
| [[partitioning-strategies.sql.md]] | C1,C4,C7 | Particionamiento declarativo RANGE/LIST con gestión de memoria |
| [[backup-restore-tenant-scoped.sql.md]] | C3,C5,C7 | Backup/restore por tenant con verificación de integridad |

### FASE 3 – Query Patterns & IA-Assist (Consultas)
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| [[crud-with-tenant-enforcement.sql.md]] | C3,C4,C8 | Operaciones CRUD parametrizadas con aislamiento obligatorio |
| [[join-patterns-rls-aware.sql.md]] | C4,C7,C8 | JOINs seguros, CTEs con scope de tenant y prevención de cross-leak |
| [[aggregation-multi-tenant-safe.sql.md]] | C4,C5,C8 | Agregaciones (`SUM`, `AVG`, `COUNT`) con hash de resultados |
| [[query-explanation-templates.sql.md]] | C8 | Plantillas de `EXPLAIN` y logging de latencia para auditoría |
| [[nl-to-sql-patterns.sql.md]] | C3,C4,C8 | Conversión NL→SQL con validación de confianza y timeouts |

### FASE 4 – MCP/IA Tooling (Integración)
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| [[mcp-sql-tool-definitions.json.md]] | C3,C4,C8 | Contratos JSON para herramientas MCP con inyección de contexto |
| [[ia-query-validation-gate.sql.md]] | C3,C4,C5,C8 | Gate de aprobación de queries IA con firma criptográfica |
| [[context-injection-for-ia.sql.md]] | C4,C8 | Gestión de sesión `app.*` y vistas seguras para consumo IA |
| [[audit-trail-ia-generated.sql.md]] | C4,C5,C8 | Traza inmutable de SQL generado por LLM con verificación de hash |
| [[permission-scoping-for-ia.sql.md]] | C3,C4,C7 | Control de privilegios granular y validación de identificadores |

### FASE 5 – Testing & Validation (Verificación)
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| [[unit-test-patterns-for-sql.sql.md]] | C4,C5,C8 | Pruebas unitarias aisladas, fixtures y asserts de hash |
| [[integration-test-fixtures.sql.md]] | C3,C4,C7 | Carga masiva segura, validación de rutas y rollback automático |
| [[constraint-validation-tests.sql.md]] | C4,C5,C7 | Verificación de `CHECK`, `NOT NULL` y reportes de integridad |

## 🔗 Interacciones con el Repositorio
- **`05-CONFIGURATIONS/validation/`**: Todos los artifacts son validados por `orchestrator-engine.sh`. Los scripts `verify-constraints.sh` y `validate-skill-integrity.sh` consumen el JSON de este índice.
- **`01-RULES/`**: Las normas `harness-norms-v2.0.md`, `language-lock-protocol.md` y `06-MULTITENANCY-RULES.md` definen los constraints C1-C8 aplicados.
- **`06-PROGRAMMING/postgresql-pgvector/`**: Carpeta hermana con LANGUAGE LOCK estricto. Cero interacción directa; aislamiento de vectores (`<->`, `hnsw`) garantizado.
- **`08-LOGS/`**: Los triggers y logging estructurado (C8) alimentan dashboards en `sql-audit-dashboard-realtime.md` y generan entradas en `failed-attempts/` si fallan validaciones.

---

## 🤖 AI-Enriched Dependency & Priority Tree (JSON)
```json
{
  "index_metadata": {
    "version": "2.1.1",
    "generated_at": "2026-04-18T23:55:00Z",
    "total_artifacts": 25,
    "canonical_path": "06-PROGRAMMING/sql/00-INDEX.md",
    "harness_norms": "v2.1.1-AUDIT"
  },
  "execution_priority_queue": [
    {"priority": 1, "phase": 0, "norms": ["C3","C5","C7"], "reason": "Pre-flight validation required before any DML/DDL execution"},
    {"priority": 2, "phase": 1, "norms": ["C4","C3"], "reason": "Tenant isolation must be enforced before query patterns"},
    {"priority": 3, "phase": 2, "norms": ["C4","C5"], "reason": "Migration/backup integrity verified before schema drift"},
    {"priority": 4, "phase": 3, "norms": ["C4","C8"], "reason": "Query patterns rely on established RLS and context injection"},
    {"priority": 5, "phase": 4, "norms": ["C3","C5","C8"], "reason": "IA tooling requires hardened patterns and validation gates"},
    {"priority": 6, "phase": 5, "norms": ["C4","C5","C7"], "reason": "Testing validates all upstream constraints before deployment"}
  ],
  "artifacts_graph": [
    {"id": "hardening-verification.sql.md", "phase": 0, "constraints": ["C3","C4","C5","C7","C8"], "priority": 1, "dependencies": ["01-RULES/harness-norms-v2.0.md"], "interactions": "Validates all downstream SQL patterns"},
    {"id": "fix-sintaxis-code.sql.md", "phase": 0, "constraints": ["C3","C4","C5","C7","C8"], "priority": 1, "dependencies": ["05-CONFIGURATIONS/validation/verify-constraints.sh"], "interactions": "Feeds linter results to CI/CD pipelines"},
    {"id": "robust-error-handling.sql.md", "phase": 0, "constraints": ["C4","C5","C7","C8"], "priority": 1, "dependencies": ["01-RULES/10-SDD-CONSTRAINTS.md"], "interactions": "Wraps transactional safety for Phase 1-4"},
    {"id": "row-level-security-policies.sql.md", "phase": 1, "constraints": ["C3","C4","C5","C7","C8"], "priority": 2, "dependencies": ["hardening-verification.sql.md"], "interactions": "Enforces multi-tenant boundaries for all DML"},
    {"id": "tenant-context-injection.sql.md", "phase": 1, "constraints": ["C3","C4","C8"], "priority": 2, "dependencies": ["row-level-security-policies.sql.md"], "interactions": "Provides `app.tenant_id` propagation to sessions"},
    {"id": "column-encryption-patterns.sql.md", "phase": 1, "constraints": ["C3","C5","C7"], "priority": 2, "dependencies": ["tenant-context-injection.sql.md"], "interactions": "Secures PII before RLS evaluation"},
    {"id": "audit-logging-triggers.sql.md", "phase": 1, "constraints": ["C4","C5","C8"], "priority": 2, "dependencies": ["row-level-security-policies.sql.md"], "interactions": "Captures RLS hits/misses for compliance"},
    {"id": "migration-versioning-patterns.sql.md", "phase": 2, "constraints": ["C4","C5","C7","C8"], "priority": 3, "dependencies": ["hardening-verification.sql.md"], "interactions": "Tracks schema state across deployments"},
    {"id": "schema-diff-validation.sql.md", "phase": 2, "constraints": ["C5","C7","C8"], "priority": 3, "dependencies": ["migration-versioning-patterns.sql.md"], "interactions": "Detects drift before CI/CD merge"},
    {"id": "rollback-automation-patterns.sql.md", "phase": 2, "constraints": ["C4","C5","C7"], "priority": 3, "dependencies": ["migration-versioning-patterns.sql.md"], "interactions": "Provides idempotent reversal paths"},
    {"id": "partitioning-strategies.sql.md", "phase": 2, "constraints": ["C1","C4","C7"], "priority": 3, "dependencies": ["row-level-security-policies.sql.md"], "interactions": "Optimizes query performance on large tenant datasets"},
    {"id": "backup-restore-tenant-scoped.sql.md", "phase": 2, "constraints": ["C3","C5","C7"], "priority": 3, "dependencies": ["tenant-context-injection.sql.md"], "interactions": "Ensures scoped data portability"},
    {"id": "crud-with-tenant-enforcement.sql.md", "phase": 3, "constraints": ["C3","C4","C8"], "priority": 4, "dependencies": ["row-level-security-policies.sql.md", "tenant-context-injection.sql.md"], "interactions": "Core DML template for application layer"},
    {"id": "join-patterns-rls-aware.sql.md", "phase": 3, "constraints": ["C4","C7","C8"], "priority": 4, "dependencies": ["crud-with-tenant-enforcement.sql.md"], "interactions": "Prevents cross-tenant data leakage in complex queries"},
    {"id": "aggregation-multi-tenant-safe.sql.md", "phase": 3, "constraints": ["C4","C5","C8"], "priority": 4, "dependencies": ["crud-with-tenant-enforcement.sql.md"], "interactions": "Generates tenant-scoped metrics with integrity hashes"},
    {"id": "query-explanation-templates.sql.md", "phase": 3, "constraints": ["C8"], "priority": 4, "dependencies": ["partitioning-strategies.sql.md"], "interactions": "Provides execution plan auditing for CI/CD"},
    {"id": "nl-to-sql-patterns.sql.md", "phase": 3, "constraints": ["C3","C4","C8"], "priority": 4, "dependencies": ["ia-query-validation-gate.sql.md"], "interactions": "Translates natural language to safe, tenant-scoped SQL"},
    {"id": "mcp-sql-tool-definitions.json.md", "phase": 4, "constraints": ["C3","C4","C8"], "priority": 5, "dependencies": ["crud-with-tenant-enforcement.sql.md"], "interactions": "Defines MCP tool contracts for IA agents"},
    {"id": "ia-query-validation-gate.sql.md", "phase": 4, "constraints": ["C3","C4","C5","C8"], "priority": 5, "dependencies": ["mcp-sql-tool-definitions.json.md"], "interactions": "Blocks unsafe LLM-generated queries before execution"},
    {"id": "context-injection-for-ia.sql.md", "phase": 4, "constraints": ["C4","C8"], "priority": 5, "dependencies": ["tenant-context-injection.sql.md"], "interactions": "Manages IA session variables safely"},
    {"id": "audit-trail-ia-generated.sql.md", "phase": 4, "constraints": ["C4","C5","C8"], "priority": 5, "dependencies": ["ia-query-validation-gate.sql.md"], "interactions": "Logs all IA interactions for compliance"},
    {"id": "permission-scoping-for-ia.sql.md", "phase": 4, "constraints": ["C3","C4","C7"], "priority": 5, "dependencies": ["row-level-security-policies.sql.md"], "interactions": "Restricts IA agent privileges to read-only scopes"},
    {"id": "unit-test-patterns-for-sql.sql.md", "phase": 5, "constraints": ["C4","C5","C8"], "priority": 6, "dependencies": ["crud-with-tenant-enforcement.sql.md"], "interactions": "Validates individual patterns in isolation"},
    {"id": "integration-test-fixtures.sql.md", "phase": 5, "constraints": ["C3","C4","C7"], "priority": 6, "dependencies": ["unit-test-patterns-for-sql.sql.md"], "interactions": "Loads cross-phase test data safely"},
    {"id": "constraint-validation-tests.sql.md", "phase": 5, "constraints": ["C4","C5","C7"], "priority": 6, "dependencies": ["schema-diff-validation.sql.md"], "interactions": "Verifies schema constraints before production push"}
  ],
  "norms_hierarchy": {
    "C1": {"name": "resource_limits", "priority": "low", "applies_to": ["partitioning", "ci-cd"]},
    "C2": {"name": "timeouts", "priority": "medium", "applies_to": ["transactions", "migrations"]},
    "C3": {"name": "env_validation", "priority": "high", "applies_to": ["pre-flight", "context-injection", "gates"]},
    "C4": {"name": "tenant_isolation", "priority": "critical", "applies_to": ["all-dml", "rls", "backups"]},
    "C5": {"name": "integrity_crypto", "priority": "critical", "applies_to": ["encryption", "checksums", "audit-trails"]},
    "C6": {"name": "optional_deps", "priority": "low", "applies_to": ["extensions", "fallbacks"]},
    "C7": {"name": "path_safety", "priority": "high", "applies_to": ["imports", "exports", "fixtures"]},
    "C8": {"name": "structured_logging", "priority": "medium", "applies_to": ["audit", "monitoring", "ia-traces"]}
  }
}
```

---
