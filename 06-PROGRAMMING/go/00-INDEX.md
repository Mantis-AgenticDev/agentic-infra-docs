---
artifact_id: "00-INDEX-go"
artifact_type: "skill_index"
version: "3.1.0-SELECTIVE"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/go/00-INDEX.md --json"
canonical_path: "06-PROGRAMMING/go/00-INDEX.md"
---

# Go Patterns Master Index – Multi-Tenant Hardening, Concurrency & AI Integration

## 👤 Propósito y Alcance
Índice canónico de navegación para `06-PROGRAMMING/go/`. Documenta 35 artifacts auditados bajo HARNESS NORMS v3.1.0-SELECTIVE, mapea flujos de ejecución para desarrollo backend/concurrente con aislamiento multi-tenant, referencia al **agente master de generación Go**, y proporciona un árbol JSON enriquecido para routing de agentes LLM y pipelines CI/CD.

> 🔑 **Diferenciador crítico**: Este dominio cubre Go 1.21+ con enfoque en:
> - Concurrency safety con goroutines/channels para procesamiento multi-tenant sin race conditions
> - Type safety nativo con interfaces y generics para validación estática de contracts
> - Zero-cost abstractions para observabilidad (C8) y límites de recursos (C1/C2)
> - Integración segura con backends (SQL, pgvector, Python) respetando LANGUAGE LOCK

---

## 🤖 Agente de Generación Disponible

| Agente | Canonical Path | Dominio | Constraints Soportados | Hooks de Validación |
|--------|---------------|---------|----------------------|-------------------|
| **`go-master-agent`** ✅ | `[[06-PROGRAMMING/go/go-master-agent.md]]` | `go,golang,concurrency,microservices` | `C1,C2,C3,C4,C5,C7,C8` | `verify-constraints.sh`, `audit-secrets.sh`, `go-vet-validator.sh`, `golangci-lint-check.sh` |

> ⚠️ **Nota contractual**: Este agente es Tier 1 (referencia educativa). Cualquier módulo generado debe pasar validación automática antes de merge. Documentación técnica en pt-BR: `docs/pt-BR/programming/go/go-master-agent/README.md`.

---

## 📂 Mapeo de Fases y Wikilinks

### FASE 0 – Core Hardening (Pre-flight & Type Safety)
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[hardening-verification.go.md]]` | C3,C4,C5,C7,C8 | Validación de entorno Go, límites de recursos y `go vet` pre-ejecución |
| `[[type-safety-with-generics.go.md]]` | C4,C5,C7,C8 | Generics para contracts type-safe con validación de tenant_id en compile-time |
| `[[error-handling-c7.go.md]]` | C4,C5,C7,C8 | Manejo estructurado de errores con `errors.Join`, logging y recuperación segura |

### FASE 1 – Multi-Tenant Security (Aislamiento en Backend)
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[microservices-tenant-isolation.go.md]]` | C3,C4,C5,C7,C8 | Middleware de aislamiento por tenant con propagación de contexto y cache isolation |
| `[[secrets-management-c3.go.md]]` | C3,C5,C7 | Gestión de secrets via env vars, vault integration y zero hardcode en binarios |
| `[[authentication-authorization-patterns.go.md]]` | C3,C4,C8 | JWT/OAuth2 con claims de tenant_id y validación RBAC en handlers HTTP |
| `[[structured-logging-c8.go.md]]` | C4,C5,C8 | Logging estructurado JSON con correlación de requests y trazabilidad por tenant |

### FASE 2 – Concurrency & Async Patterns
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[async-patterns-with-timeouts.go.md]]` | C1,C4,C7,C8 | Goroutines con context.Context, timeouts y cancellation por tenant |
| `[[resource-limits-c1-c2.go.md]]` | C1,C2,C7 | Limitación de CPU/memoria con `runtime/debug.SetMemoryLimit` y semáforos |
| `[[orchestrator-engine.go.md]]` | C1,C3,C4,C5,C6,C7,C8 | Port del orchestrator bash → Go con explicación línea a línea y validación de constraints |
| `[[filesystem-sandboxing.go.md]]` | C3,C4,C7 | Aislamiento de operaciones de filesystem por tenant con chroot-like patterns |

### FASE 3 – Database & SQL Integration
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[sql-core-patterns.go.md]]` | C3,C4,C8 | Queries parametrizadas con `database/sql`, tenant_id obligatorio y prepared statements |
| `[[db-selection-decision-tree.go.md]]` | C4,C5,C7 | Árbol de decisión para selección de DB (PostgreSQL/MySQL/SQLite) con validación de tenant scoping |
| `[[mysql-mariadb-optimization.go.md]]` | C1,C4,C7 | Optimizaciones específicas para MySQL/MariaDB con límites de recursos por tenant |
| `[[prisma-orm-patterns.go.md]]` | C4,C5,C8 | Patrones Prisma Client Go con generación de tipos y validación de tenant_id en queries |

### FASE 4 – API Clients & External Integrations
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[api-client-management.go.md]]` | C3,C4,C7,C8 | Gestión de clientes HTTP con retry logic, circuit breaker y headers de tenant_id |
| `[[n8n-webhook-handler.go.md]]` | C3,C4,C8 | Handler de webhooks n8n con validación de firma HMAC y scope de tenant |
| `[[webhook-validation-patterns.go.md]]` | C3,C4,C7 | Validación de webhooks entrantes con rate limiting por tenant y replay attack prevention |
| `[[telegram-bot-integration.go.md]]` | C3,C4,C8 | Bot de Telegram con contexto de usuario/tenant y logging estructurado de interacciones |

### FASE 5 – RAG & AI Integrations (LANGUAGE LOCK: Delegación)
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[postgres-pgvector-integration.go.md]]` | C4,C8,V1,V2 | **Delegación controlada**: wrapper Go para llamar a queries pgvector en `postgresql-pgvector/`, NO genera operadores vectoriales directamente |
| `[[rag-ingestion-pipeline.go.md]]` | C1,C4,C7,C8 | Pipeline de ingestión RAG con chunking, límites de recursos y validación de tenant_id en metadatos |
| `[[langchain-style-integration.go.md]]` | C4,C5,C8 | Integración estilo LangChain con chain composition y validación de contexto de tenant |
| `[[supabase-rag-integration.go.md]]` | C3,C4,C8 | Integración con Supabase Vector con autenticación tenant-scoped y logging de queries |

### FASE 6 – Observability & Deployment
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[observability-opentelemetry.go.md]]` | C7,C8 | Instrumentación OpenTelemetry con atributos de tenant_id y métricas por servicio |
| `[[static-dashboard-generator.go.md]]` | C1,C4,C7 | Generador de dashboards estáticos con límites de recursos y aislamiento de datos por tenant |
| `[[saas-deployment-zip-auto.go.md]]` | C1,C3,C4,C7 | Despliegue automático SaaS con empaquetado ZIP, validación de integridad y rollback por tenant |
| `[[git-disaster-recovery.go.md]]` | C3,C5,C7 | Recuperación ante desastres Git con validación de firmas GPG y aislamiento de branches por tenant |

### FASE 7 – Testing & Validation
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[testing-multi-tenant-patterns.go.md]]` | C4,C5,C8 | Patrones de testing con `testing.T`, fixtures aisladas por tenant y mocks de API tenant-scoped |
| `[[scale-simulation-utils.go.md]]` | C1,C2,C7 | Utilidades para simulación de carga con límites de recursos y métricas de escalabilidad por tenant |
| `[[testing-multi-tenant-patterns.go.md]]` | C4,C5,C8 | Patrones de testing con `testing.T`, fixtures aisladas por tenant y mocks de API tenant-scoped |

---

## 🔗 Interacciones con el Repositorio
- **`05-CONFIGURATIONS/validation/`**: Todos los artifacts son validados por `orchestrator-engine.sh`. Los scripts `verify-constraints.sh`, `go-vet-validator.sh` y `golangci-lint-check.sh` consumen el JSON de este índice.
- **`01-RULES/`**: Las normas `harness-norms-v3.0.md`, `language-lock-protocol.md` y `06-MULTITENANCY-RULES.md` definen los constraints C1-C8 aplicados.
- **`06-PROGRAMMING/postgresql-pgvector/`**: Carpeta hermana con LANGUAGE LOCK estricto. **Delegación obligatoria**: queries vectoriales deben generarse en `postgresql-pgvector/`, no aquí. Este dominio solo contiene wrappers de llamada.
- **`06-PROGRAMMING/python/`**: Para lógica de backend pesada o embedding generation, usar `python/` y consumir via gRPC/HTTP desde este dominio.
- **`06-PROGRAMMING/sql/`**: Para queries SQL puras (sin vectores), delegar a `sql/` y consumir via `database/sql` o query builder desde Go.
- **`08-LOGS/`**: Los handlers de logging estructurado (C8) en Go alimentan dashboards y generan entradas en `failed-attempts/` si fallan validaciones de tenant isolation.
- **`go-master-agent.md`**: Punto único de generación para nuevos artifacts Go. Consulta este índice ANTES de emitir módulos para asegurar coherencia con patrones existentes.

---

## ⚠️ Reglas Críticas de LANGUAGE LOCK para go/

```text
🚫 PROHIBIDO en esta carpeta:
• Importación o uso directo de operadores pgvector: import "github.com/pgvector/pgvector-go", <->, <#>, <=>, vector(n)
• Queries SQL embebidas con sintaxis de extensión pgvector (CREATE EXTENSION vector, USING hnsw, etc.)
• Constraints vectoriales V1/V2/V3 en constraints_mapped del frontmatter (excepto en postgres-pgvector-integration.go.md que es wrapper de delegación)
• Generación directa de código con operadores vectoriales; solo se permiten wrappers que deleguen a postgresql-pgvector/

✅ REQUERIDO en esta carpeta:
• artifact_type: "go_module" | "go_pattern" | "go_microservice" | "go_cli" (NUNCA "skill_pgvector")
• constraints_mapped: SOLO valores de C1-C8 (V* bloqueado por LANGUAGE LOCK, excepto delegación controlada)
• Módulos que interactúan con DB deben validar tenant_id en queries o usar context con scope de tenant
• validation_command que referencie orchestrator-engine.sh con canonical_path correcto
• Agente master: consultar norms-matrix.json antes de declarar constraints en módulos generados
• Concurrency safety: usar context.Context para cancellation y timeout propagation en goroutines
• Comments pedagógicos: incluir `// 👇 EXPLICACIÓN:` en español para facilitar aprendizaje
```

---

## 🤖 JSON TREE ENRIQUECIDO PARA IA (Metadatos + Dependencias + Prioridad de Normas)

```json
{
 "index_metadata": {
 "artifact_id": "00-INDEX-go",
 "artifact_type": "skill_index",
 "version": "3.1.0-SELECTIVE",
 "canonical_path": "06-PROGRAMMING/go/00-INDEX.md",
 "language_lock_status": "enforced",
 "vector_constraints_applied": false,
 "generated_timestamp": "2026-01-27T00:00:00Z",
 "master_agent": "go-master-agent"
 },
 "artifacts": [
 {
 "artifact_id": "go-master-agent",
 "file": "go-master-agent.md",
 "canonical_path": "06-PROGRAMMING/go/go-master-agent.md",
 "artifact_type": "agentic_skill_definition",
 "tier": 1,
 "constraints_mapped": ["C1","C2","C3","C4","C5","C7","C8"],
 "language_lock": ["go","golang","concurrency","microservices"],
 "validation_hooks": ["verify-constraints.sh", "audit-secrets.sh", "go-vet-validator.sh", "golangci-lint-check.sh"],
 "examples_count": 15,
 "score_baseline": 94,
 "dependencies": {
 "validators": ["verify-constraints.sh", "audit-secrets.sh", "go-vet-validator.sh", "golangci-lint-check.sh"],
 "norms": ["harness-norms-v3.0.md", "10-SDD-CONSTRAINTS.md", "language-lock-protocol.md", "06-MULTITENANCY-RULES.md"],
 "config": ["norms-matrix.json", "skill-template.md", "go.mod", ".golangci.yml"]
 },
 "dependents": ["all go artifacts"],
 "norms_priority": {
 "execution_order": ["C4", "C3", "C5", "C7", "C8", "C1", "C2"],
 "blocking_constraints": ["C3", "C4"],
 "rationale": "Security (C3) and tenant isolation (C4) are foundational for Go module generation"
 },
 "interactions": {
 "with_validation": "Emits JSON to stdout, logs to stderr, JSONL to 08-LOGS/ per V-INT-03",
 "with_config": "Consults norms-matrix.json before declaring constraints in generated modules",
 "with_programming": "Delegates vector operations to postgresql-pgvector/, SQL to sql/, embedding logic to python/ per LANGUAGE LOCK"
 }
 },
 {
 "artifact_id": "hardening-verification",
 "file": "hardening-verification.go.md",
 "canonical_path": "06-PROGRAMMING/go/hardening-verification.go.md",
 "constraints_mapped": ["C3","C4","C5","C7","C8"],
 "examples_count": 10,
 "score_baseline": 90,
 "dependencies": {
 "validators": ["verify-constraints.sh", "go-vet-validator.sh"],
 "norms": ["harness-norms-v3.0.md", "10-SDD-CONSTRAINTS.md"],
 "templates": ["skill-template.md"]
 },
 "dependents": ["all phase-1 to phase-7 artifacts"],
 "norms_priority": {
 "execution_order": ["C4", "C3", "C7", "C5", "C8"],
 "blocking_constraints": ["C4", "C3"],
 "rationale": "Pre-flight validation must confirm tenant isolation and security before any Go module execution"
 },
 "interactions": {
 "with_validation": "Provides baseline checks consumed by orchestrator-engine.sh",
 "with_config": "References norms-matrix.json for constraint routing logic",
 "with_programming": "NO interaction with postgresql-pgvector/ due to LANGUAGE LOCK"
 }
 },
 {
 "artifact_id": "microservices-tenant-isolation",
 "file": "microservices-tenant-isolation.go.md",
 "canonical_path": "06-PROGRAMMING/go/microservices-tenant-isolation.go.md",
 "constraints_mapped": ["C3","C4","C5","C7","C8"],
 "examples_count": 12,
 "score_baseline": 93,
 "dependencies": {
 "validators": ["verify-constraints.sh", "audit-secrets.sh"],
 "norms": ["harness-norms-v3.0.md#C4", "06-MULTITENANCY-RULES.md"],
 "security_refs": ["03-SECURITY-RULES.md"]
 },
 "dependents": ["sql-core-patterns", "api-client-management", "observability-opentelemetry"],
 "norms_priority": {
 "execution_order": ["C4", "C8", "C3", "C7", "C5"],
 "blocking_constraints": ["C4"],
 "rationale": "Middleware isolation is the enforcement mechanism for C4 in Go microservices; must be validated first"
 },
 "interactions": {
 "with_validation": "verify-constraints.sh validates tenant_id propagation in context.Context examples",
 "with_config": "Aligns with multi-tenant rules in 06-MULTITENANCY-RULES.md",
 "with_programming": "Context patterns consumed by HTTP handlers before DB/API calls"
 }
 },
 {
 "artifact_id": "secrets-management-c3",
 "file": "secrets-management-c3.go.md",
 "canonical_path": "06-PROGRAMMING/go/secrets-management-c3.go.md",
 "constraints_mapped": ["C3","C5","C7"],
 "examples_count": 10,
 "score_baseline": 91,
 "dependencies": {
 "validators": ["audit-secrets.sh", "verify-constraints.sh"],
 "norms": ["harness-norms-v3.0.md#C3"],
 "templates": [".env.example", "go.mod"]
 },
 "dependents": ["microservices-tenant-isolation", "api-client-management"],
 "norms_priority": {
 "execution_order": ["C3", "C7", "C5"],
 "blocking_constraints": ["C3"],
 "rationale": "Secrets handling is security-critical; must pass before structural checks"
 },
 "interactions": {
 "with_validation": "audit-secrets.sh validates zero hardcode secrets in examples",
 "with_config": "References .env.example for placeholder patterns",
 "with_programming": "Secrets patterns consumed by application config loading at build time"
 }
 },
 {
 "artifact_id": "sql-core-patterns",
 "file": "sql-core-patterns.go.md",
 "canonical_path": "06-PROGRAMMING/go/sql-core-patterns.go.md",
 "constraints_mapped": ["C3","C4","C8"],
 "examples_count": 14,
 "score_baseline": 94,
 "dependencies": {
 "validators": ["verify-constraints.sh", "go-vet-validator.sh"],
 "norms": ["harness-norms-v3.0.md#C4"],
 "templates": ["skill-template.md"]
 },
 "dependents": ["mysql-mariadb-optimization", "prisma-orm-patterns", "rag-ingestion-pipeline"],
 "norms_priority": {
 "execution_order": ["C4", "C3", "C8"],
 "blocking_constraints": ["C4"],
 "rationale": "DB queries are the primary attack surface; tenant enforcement in WHERE clauses is non-negotiable"
 },
 "interactions": {
 "with_validation": "verify-constraints.sh validates tenant_id filter in all query examples",
 "with_config": "Parametrization patterns align with database/sql best practices",
 "with_programming": "Core query template consumed by application service layer"
 }
 },
 {
 "artifact_id": "postgres-pgvector-integration",
 "file": "postgres-pgvector-integration.go.md",
 "canonical_path": "06-PROGRAMMING/go/postgres-pgvector-integration.go.md",
 "constraints_mapped": ["C4","C8"],
 "examples_count": 8,
 "score_baseline": 89,
 "dependencies": {
 "validators": ["verify-constraints.sh", "go-vet-validator.sh"],
 "norms": ["harness-norms-v3.0.md#C4", "language-lock-protocol.md"],
 "delegation_refs": ["postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md"]
 },
 "dependents": ["rag-ingestion-pipeline", "supabase-rag-integration"],
 "norms_priority": {
 "execution_order": ["C4", "C8"],
 "blocking_constraints": ["C4"],
 "rationale": "Wrapper must enforce tenant isolation before delegating vector operations to postgresql-pgvector/"
 },
 "interactions": {
 "with_validation": "verify-constraints.sh validates that NO vector operators are generated directly, only delegation calls",
 "with_config": "Delegation patterns align with norms-matrix.json for cross-domain routing",
 "with_programming": "Wrapper pattern consumed by RAG pipeline before calling vector search in postgresql-pgvector/"
 }
 }
 ],
 "dependency_graph": {
 "validation_layer": {
 "orchestrator-engine.sh": ["all artifacts"],
 "verify-constraints.sh": ["all artifacts"],
 "audit-secrets.sh": ["secrets-management-c3", "microservices-tenant-isolation", "go-master-agent"],
 "go-vet-validator.sh": ["hardening-verification", "sql-core-patterns", "go-master-agent"],
 "golangci-lint-check.sh": ["type-safety-with-generics", "error-handling-c7", "go-master-agent"]
 },
 "norms_layer": {
 "harness-norms-v3.0.md": ["all artifacts"],
 "10-SDD-CONSTRAINTS.md": ["all artifacts"],
 "language-lock-protocol.md": ["all artifacts"],
 "06-MULTITENANCY-RULES.md": ["microservices-tenant-isolation", "sql-core-patterns", "authentication-authorization-patterns"],
 "norms-matrix.json": ["all artifacts", "go-master-agent"]
 },
 "config_layer": {
 "skill-template.md": ["all artifacts"],
 ".env.example": ["secrets-management-c3", "microservices-tenant-isolation"],
 "go.mod": ["hardening-verification", "saas-deployment-zip-auto"],
 ".golangci.yml": ["type-safety-with-generics", "go-master-agent"]
 }
 },
 "norms_execution_priority": {
 "global_order": ["C4", "C3", "C7", "C5", "C8", "C1", "C2", "C6"],
 "rationale": "C4 (tenant isolation) is foundational; security (C3) and concurrency safety (C7) precede structural (C5) and observability (C8) checks",
 "blocking_set": ["C3", "C4", "C7"],
 "non_blocking_set": ["C1", "C2", "C5", "C6", "C8"],
 "selective_v_logic": {
 "applies_to": "postgresql-pgvector/ ONLY",
 "trigger": "artifact_type == 'skill_pgvector' AND content has pgvector operators",
 "exclusion": "go/ ALWAYS excludes V1/V2/V3 per LANGUAGE LOCK (except postgres-pgvector-integration.go.md which is delegation wrapper only)"
 }
 },
 "language_lock_enforcement": {
 "folder": "06-PROGRAMMING/go/",
 "prohibited_patterns": ["import.*pgvector|cosine_distance|l2_distance|hamming_distance|vector\\(|<->[^a-zA-Z]|<#>[^a-zA-Z]|USING\\s+(hnsw|ivfflat)"],
 "required_artifact_types": ["go_module", "go_pattern", "go_microservice", "go_cli"],
 "prohibited_constraints": ["V1", "V2", "V3"],
 "delegation_exception": {
 "file": "postgres-pgvector-integration.go.md",
 "allowed": "wrapper calls only, NO direct vector operator generation",
 "validation": "must reference postgresql-pgvector/ artifacts via canonical_path"
 },
 "validation_script": "validate-skill-integrity.sh --check-language-lock",
 "failure_action": "exit 2 with message 'LANGUAGE LOCK VIOLATION: pgvector imports/operators not allowed in Go domain'"
 },
 "ai_navigation_hints": {
 "for_generation": "Read go-master-agent.md AND this index BEFORE generating new Go artifacts. Include `// 👇 EXPLICACIÓN:` comments in Spanish for pedagogy.",
 "for_validation": "Use norms_execution_priority: validate C4 before allowing DB/API calls in examples; use go-vet for static analysis",
 "for_migration": "Consult dependency_graph before modifying shared patterns; concurrency changes may require downstream updates",
 "for_debugging": "Check language_lock_enforcement if pgvector operators appear in go/ artifacts; delegate to postgresql-pgvector/",
 "for_master_agent": "Agent must consult norms-matrix.json before declaring constraints; emit JSON to stdout, logs to stderr, JSONL to 08-LOGS/; delegate vector/SQL/embedding logic to appropriate domains; include pedagogical comments in Spanish"
 }
}
```

---

## 🔗 RAW_URLS_INDEX – Patrones Go Disponibles

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
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/go-vet-validator.sh
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/golangci-lint-check.sh
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/schemas/skill-input-output.schema.json
```

### 🐹 Patrones Go Core (06-PROGRAMMING/go)
```text
# Índice y Agente Master
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/00-INDEX.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/go-master-agent.md

# Fase 0: Core Hardening
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/hardening-verification.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/type-safety-with-generics.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/error-handling-c7.go.md

# Fase 1: Multi-Tenant Security
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/microservices-tenant-isolation.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/secrets-management-c3.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/authentication-authorization-patterns.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/structured-logging-c8.go.md

# Fase 2: Concurrency & Async
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/async-patterns-with-timeouts.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/resource-limits-c1-c2.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/orchestrator-engine.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/filesystem-sandboxing.go.md

# Fase 3: Database & SQL
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/sql-core-patterns.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/db-selection-decision-tree.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/mysql-mariadb-optimization.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/prisma-orm-patterns.go.md

# Fase 4: API Clients & Integrations
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/api-client-management.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/n8n-webhook-handler.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/webhook-validation-patterns.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/telegram-bot-integration.go.md

# Fase 5: RAG & AI (Delegación)
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/postgres-pgvector-integration.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/rag-ingestion-pipeline.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/langchain-style-integration.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/supabase-rag-integration.go.md

# Fase 6: Observability & Deployment
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/observability-opentelemetry.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/static-dashboard-generator.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/saas-deployment-zip-auto.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/git-disaster-recovery.go.md

# Fase 7: Testing
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/testing-multi-tenant-patterns.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/scale-simulation-utils.go.md
```

### 🔗 Referencias de Dominios Hermanos (Para Delegación)
```text
# SQL puro (delegar queries sin vectores)
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/00-INDEX.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/crud-with-tenant-enforcement.sql.md

# Python (delegar lógica de backend pesada)
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/00-INDEX.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/python-sqlalchemy-tenant-enforcement.py.md

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
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/validation-tools/go-vet-validator/README.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/validation-tools/golangci-lint-check/README.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/programming/go/go-master-agent/README.md
```

---

## 🗂️ RUTAS CANÓNICAS LOCALES – Patrones Go (Para Acceso en Repo)

> **Formato**: `RAW_URL` → `./ruta/local/en/repo`

### 🐹 Patrones Go Core
```text
# Índice y Agente Master
06-PROGRAMMING/go/00-INDEX.md
06-PROGRAMMING/go/go-master-agent.md

# Fase 0: Core Hardening
06-PROGRAMMING/go/hardening-verification.go.md
06-PROGRAMMING/go/type-safety-with-generics.go.md
06-PROGRAMMING/go/error-handling-c7.go.md

# Fase 1: Multi-Tenant Security
06-PROGRAMMING/go/microservices-tenant-isolation.go.md
06-PROGRAMMING/go/secrets-management-c3.go.md
06-PROGRAMMING/go/authentication-authorization-patterns.go.md
06-PROGRAMMING/go/structured-logging-c8.go.md

# Fase 2: Concurrency & Async
06-PROGRAMMING/go/async-patterns-with-timeouts.go.md
06-PROGRAMMING/go/resource-limits-c1-c2.go.md
06-PROGRAMMING/go/orchestrator-engine.go.md
06-PROGRAMMING/go/filesystem-sandboxing.go.md

# Fase 3: Database & SQL
06-PROGRAMMING/go/sql-core-patterns.go.md
06-PROGRAMMING/go/db-selection-decision-tree.go.md
06-PROGRAMMING/go/mysql-mariadb-optimization.go.md
06-PROGRAMMING/go/prisma-orm-patterns.go.md

# Fase 4: API Clients & Integrations
06-PROGRAMMING/go/api-client-management.go.md
06-PROGRAMMING/go/n8n-webhook-handler.go.md
06-PROGRAMMING/go/webhook-validation-patterns.go.md
06-PROGRAMMING/go/telegram-bot-integration.go.md

# Fase 5: RAG & AI (Delegación)
06-PROGRAMMING/go/postgres-pgvector-integration.go.md
06-PROGRAMMING/go/rag-ingestion-pipeline.go.md
06-PROGRAMMING/go/langchain-style-integration.go.md
06-PROGRAMMING/go/supabase-rag-integration.go.md

# Fase 6: Observability & Deployment
06-PROGRAMMING/go/observability-opentelemetry.go.md
06-PROGRAMMING/go/static-dashboard-generator.go.md
06-PROGRAMMING/go/saas-deployment-zip-auto.go.md
06-PROGRAMMING/go/git-disaster-recovery.go.md

# Fase 7: Testing
06-PROGRAMMING/go/testing-multi-tenant-patterns.go.md
06-PROGRAMMING/go/scale-simulation-utils.go.md
```

### 🔗 Referencias de Dominios Hermanos (Para Delegación)
```text
# SQL puro
06-PROGRAMMING/sql/00-INDEX.md
06-PROGRAMMING/sql/crud-with-tenant-enforcement.sql.md

# Python
06-PROGRAMMING/python/00-INDEX.md
06-PROGRAMMING/python/python-sqlalchemy-tenant-enforcement.py.md

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
docs/pt-BR/validation-tools/go-vet-validator/README.md
docs/pt-BR/validation-tools/golangci-lint-check/README.md
docs/pt-BR/programming/go/go-master-agent/README.md
```

---

## 🧭 GUÍA DE USO PARA EL AGENTE GO

```go
// Pseudocódigo: Cómo consultar patrones disponibles en Go
// (Implementado en el agente, no en Go puro para evitar circularidad)

type PatternReference struct {
    RawURL            string
    CanonicalPath     string
    Domain            string
    LanguageLock      []string
    ConstraintsDefault []string
    VectorOpsAllowed  bool // 🔑 Flag crítico para routing
}

func ConsultarPatronGo(nombrePatron string) PatternReference {
    baseRaw := "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/"
    baseLocal := "./06-PROGRAMMING/go/"
    
    isMaster := nombrePatron == "go-master-agent"
    extension := ".go.md"
    if isMaster {
        extension = ".md"
    }
    filename := nombrePatron + extension
    
    return PatternReference{
        RawURL:            baseRaw + "06-PROGRAMMING/go/" + filename,
        CanonicalPath:     baseLocal + filename,
        Domain:            "06-PROGRAMMING/go/",
        LanguageLock:      []string{"go", "golang", "concurrency", "microservices"},
        ConstraintsDefault: []string{"C3", "C4", "C5"}, // Mínimo para producción
        VectorOpsAllowed:  false, // 🔒 CERO operadores de pgvector en este dominio
    }
}

// Validación de constraints antes de emitir módulo
func ValidarConstraintsGo(artifactPath string) []string {
    fm := ExtractFrontmatter(artifactPath)
    declared := fm["constraints_mapped"].([]string)
    content := LoadFile(artifactPath)
    matrix := LoadJSON("./05-CONFIGURATIONS/validation/norms-matrix.json")
    allowed := GetAllowedConstraints(matrix, artifactPath)
    
    var issues []string
    
    // Verificar constraints declarados vs permitidos
    for _, c := range declared {
        if !Contains(allowed, c) {
            issues = append(issues, fmt.Sprintf("constraint '%s' not allowed for path %s", c, artifactPath))
        }
    }
    
    // C4: Validar que hay tenant_id en queries DB o context propagation
    if strings.Contains(content, "db.Query") || strings.Contains(content, "db.Exec") {
        if !strings.Contains(content, "tenant_id") && !strings.Contains(content, "Context") {
            issues = append(issues, "C4 missing: DB call lacks tenant_id propagation (WHERE clause or context)")
        }
    }
    
    // C3: Zero hardcode secrets
    if regexp.MustCompile(`API_KEY\s*=\s*['"][^'"]+['"]|password\s*:\s*['"][^'"]+['"]`).MatchString(content) {
        issues = append(issues, "C3 violation: hardcoded secret detected")
    }
    
    return issues
}

// Detección de LANGUAGE LOCK: operadores vectoriales prohibidos
func ContieneOperadoresVectoriales(code string) bool {
    patterns := []string{
        `import.*pgvector`, `cosine_distance`, `l2_distance`, `hamming_distance`,
        `vector\(\d+\)`, `<->[^a-zA-Z]`, `<#>[^a-zA-Z]`, `USING\s+(hnsw|ivfflat)`,
    }
    for _, pattern := range patterns {
        if regexp.MustCompile(pattern).MatchString(code) {
            return true
        }
    }
    return false
}

// Delegación por dominio según LANGUAGE LOCK
func DelegarPorDominio(query string, context map[string]interface{}) string {
    if ContieneOperadoresVectoriales(query) {
        // 🔄 Delegar a postgresql-pgvector/
        fmt.Fprintln(os.Stderr, "LANGUAGE LOCK: Vector operators not allowed in Go domain. Use postgresql-pgvector/")
        return DelegarADominio("06-PROGRAMMING/postgresql-pgvector/", query, context)
    } else if EsQuerySQLPura(query) {
        // 🔄 Delegar a sql/
        return DelegarADominio("06-PROGRAMMING/sql/", query, context)
    } else if EsLogicaBackendPesada(query) {
        // 🔄 Delegar a python/
        return DelegarADominio("06-PROGRAMMING/python/", query, context)
    } else {
        // ✅ Permitido: generar código Go estándar con tenant isolation
        return GenerarModuloGo(query, context)
    }
}

// Ejemplo de uso en el agente:
func main() {
    pattern := ConsultarPatronGo("sql-core-patterns")
    issues := ValidarConstraintsGo(pattern.CanonicalPath)
    if len(issues) > 0 {
        fmt.Fprintf(os.Stderr, "Validation failed: %v\n", issues)
        os.Exit(1)
    }
    // Generar módulo seguro...
}
```

---

## 📋 INSTRUCCIONES DE INTEGRACIÓN (Actualizadas)

### Paso 1: Agregar al final del agente
Pegar los bloques de referencias justo antes de la sección `## Limitations` en:
- `06-PROGRAMMING/go/go-master-agent.md`

### Paso 2: Actualizar el comportamiento del agente
En la sección `## Comportamiento del Agente` o `## Behavioral Traits`, agregar:

```markdown
| Trait | Implementación contractual |
|-------|---------------------------|
| **Consulta patrones antes de generar** | Antes de emitir módulo Go, el agente debe consultar la lista de patrones disponibles en `06-PROGRAMMING/go/` para asegurar coherencia con el repositorio |
| **Acceso dual** | Usar ruta canónica (`./06-PROGRAMMING/go/...`) para acceso local, o raw URL para acceso remoto si el archivo no existe localmente |
| **LANGUAGE LOCK automático** | Si el usuario solicita operadores vectoriales (`import "pgvector"`, `cosine_distance`, `<->`), el agente debe delegar a `06-PROGRAMMING/postgresql-pgvector/` y NO generar código con vectores en su dominio |
| **Concurrency safety primero** | Priorizar `context.Context` para cancellation/timeout propagation en goroutines; incluir validación de tenant_id en queries DB |
| **Pedagogía en español** | Incluir `// 👇 EXPLICACIÓN: ...` en comentarios para facilitar aprendizaje, manteniendo código compilable ≤5 líneas por ejemplo |
| **Valida constraints antes de emitir** | Ejecutar `ValidarConstraintsGo()` antes de emitir cualquier artifact para asegurar coherencia con `norms-matrix.json` |
| **Emite logs estructurados** | JSON a `stdout`, logs humanos a `stderr`, JSONL a `08-LOGS/validation/...` per V-INT-03 y V-LOG-02 |
```

### Paso 3: Validar con `verify-constraints.sh`
```bash
# Validar que el agente mismo cumple con su propio contrato
./05-CONFIGURATIONS/validation/verify-constraints.sh --file 06-PROGRAMMING/go/go-master-agent.md | jq

# Validación adicional con toolchain Go específica
./05-CONFIGURATIONS/validation/go-vet-validator.sh --file 06-PROGRAMMING/go/go-master-agent.md
./05-CONFIGURATIONS/validation/golangci-lint-check.sh --file 06-PROGRAMMING/go/go-master-agent.md

# Verificar que NO hay imports de pgvector (LANGUAGE LOCK)
grep -E 'import.*pgvector|cosine_distance|<->' 06-PROGRAMMING/go/go-master-agent.md && echo "❌ VIOLATION" || echo "✅ OK"
```

---

> 📌 **Nota final**: Este índice es Tier 1 (referencia contractual). Cualquier modificación debe pasar validación automática antes de merge.  
> 🇧🇷 *Documentação técnica completa disponível em*: `docs/pt-BR/programming/go/00-INDEX/README.md` (próxima entrega).
```

---

## ✅ Resumen de Cambios Aplicados

| Sección | Cambio | Justificación Contractual |
|---------|--------|-------------------------|
| `version` en frontmatter | `2.0.0` → `3.1.0-SELECTIVE` | Semver: cambio menor por adición de agente master + alineación con dossier MANTIS |
| `canonical_path` | Mantenido correcto | Consistencia con patrón de artifacts canónicos |
| Nueva sección `🤖 Agente de Generación Disponible` | Tabla con referencia al `go-master-agent` | Trazabilidad explícita de herramientas de generación per V-INT-01 |
| Tabla de artifacts | Agregada fila implícita para `go-master-agent.md` en JSON TREE | Navegación estructurada per V-INT-01 |
| Interacciones | Agregada referencia al agente master + reglas de delegación a otros dominios | Mapa de dependencias completo per C6 |
| JSON TREE | Nuevo objeto `go-master-agent` con dependencias, normas_priority, interactions | Metadatos enriquecidos para IA navigation per AI-NAVIGATION-CONTRACT |
| RAW_URLS_INDEX | Agregada URL raw del agente master + doc pt-BR + referencias de delegación | Fuente de verdad para consulta sin inventar datos per SDD-COLLABORATIVE-GENERATION |
| RUTAS CANÓNICAS | Agregada ruta local del agente master + doc pt-BR | Acceso dual local/remoto per protocolo de handover |
| GUÍA DE USO | Actualizado pseudocódigo Go para detectar LANGUAGE LOCK y validar constraints | Coherencia en resolución de rutas y enforcement de constraints |
| INSTRUCCIONES DE INTEGRACIÓN | Agregado trait "Pedagogía en español" + validación de constraints | Alineación con V-INT-03 y V-LOG-02 + best practices pedagógicas del repositorio |

---
