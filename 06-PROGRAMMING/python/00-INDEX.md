---
artifact_id: "00-INDEX-python"
artifact_type: "skill_index"
version: "3.1.0-SELECTIVE"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/python/00-INDEX.md --json"
canonical_path: "06-PROGRAMMING/python/00-INDEX.md"
---

# Python Patterns Master Index – Multi-Tenant Hardening & AI Integration

## 👤 Propósito y Alcance
Índice canónico de navegación para `06-PROGRAMMING/python/`. Documenta 28 artifacts auditados bajo HARNESS NORMS v3.1.0-SELECTIVE, mapea flujos de ejecución, interacciones con otros directorios del repositorio, referencia al **agente master de generación Python**, y proporciona un árbol JSON enriquecido para routing de agentes LLM y pipelines CI/CD.

---

## 🤖 Agente de Generación Disponible

| Agente | Canonical Path | Dominio | Constraints Soportados | Hooks de Validación |
|--------|---------------|---------|----------------------|-------------------|
| **`python-master-agent`** ✅ | `[[06-PROGRAMMING/python/python-master-agent.md]]` | `python,asyncio,fastapi,pydantic` | `C1,C2,C3,C4,C5,C7,C8` | `verify-constraints.sh`, `audit-secrets.sh`, `pylint-validator.py` |

> ⚠️ **Nota contractual**: Este agente es Tier 1 (referencia educativa). Cualquier módulo generado debe pasar validación automática antes de merge. Documentación técnica en pt-BR: `docs/pt-BR/programming/python/python-master-agent/README.md`.

---

## 📂 Mapeo de Fases y Wikilinks

### FASE 0 – Core Hardening (Pre-flight & Syntax)
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[python-hardening-verification.py.md]]` | C3,C4,C5,C7,C8 | Validación de entorno, límites de recursos y type-checking pre-ejecución |
| `[[python-linter-integration.py.md]]` | C3,C4,C5,C7,C8 | Integración con `pylint`, `flake8`, `black` y corrección automática |
| `[[python-exception-handling.py.md]]` | C4,C5,C7,C8 | Manejo estructurado de excepciones, logging y recuperación segura |

### FASE 1 – Multi-Tenant Security (Aislamiento)
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[python-tenant-context-manager.py.md]]` | C3,C4,C5,C7,C8 | Context manager para inyección segura de `tenant_id` en sesiones DB |
| `[[python-rbac-decorators.py.md]]` | C3,C4,C8 | Decoradores RBAC con validación de permisos por tenant |
| `[[python-secrets-management.py.md]]` | C3,C5,C7 | Gestión de secrets via `python-decouple`, env vars y vault integration |
| `[[python-audit-logging.py.md]]` | C4,C5,C8 | Logging estructurado JSON con trazabilidad por tenant |

### FASE 2 – CI/CD & Testing (Versionado)
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[python-pytest-tenant-isolation.py.md]]` | C4,C5,C7,C8 | Fixtures de pytest con aislamiento de tenant y rollback automático |
| `[[python-mock-strategies.py.md]]` | C5,C7,C8 | Estrategias de mocking para tests unitarios sin dependencia externa |
| `[[python-type-hinting-protocols.py.md]]` | C4,C5,C8 | Protocolos TypedDict/Protocol para validación estática de interfaces |
| `[[python-deployment-docker.py.md]]` | C1,C4,C7 | Dockerfile optimizado con límites de recursos y usuario no-root |
| `[[python-health-checks.py.md]]` | C7,C8 | Endpoints de health check con métricas Prometheus-ready |

### FASE 3 – Query Patterns & IA-Assist (Consultas)
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[python-sqlalchemy-tenant-enforcement.py.md]]` | C3,C4,C8 | ORM patterns con `tenant_id` obligatorio en todos los queries |
| `[[python-async-db-pooling.py.md]]` | C4,C7,C8 | Connection pooling async con scope de tenant y timeout management |
| `[[python-aggregation-safe.py.md]]` | C4,C5,C8 | Agregaciones (`sum`, `avg`, `count`) con validación de scope tenant |
| `[[python-query-explain-templates.py.md]]` | C8 | Plantillas para logging de `EXPLAIN` y métricas de latencia |
| `[[python-nl-to-query-patterns.py.md]]` | C3,C4,C8 | Conversión NL→Query con validación de confianza y rate limiting |

### FASE 4 – MCP/IA Tooling (Integración)
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[python-mcp-tool-definitions.py.md]]` | C3,C4,C8 | Definición de herramientas MCP con inyección de contexto de tenant |
| `[[python-ia-query-validation-gate.py.md]]` | C3,C4,C5,C8 | Gate de aprobación de queries IA con firma criptográfica y audit trail |
| `[[python-context-injection-for-ia.py.md]]` | C4,C8 | Gestión de sesión `app.*` y vistas seguras para consumo IA |
| `[[python-audit-trail-ia-generated.py.md]]` | C4,C5,C8 | Traza inmutable de código generado por LLM con verificación de hash |
| `[[python-permission-scoping-for-ia.py.md]]` | C3,C4,C7 | Control de privilegios granular y validación de identificadores |

### FASE 5 – Testing & Validation (Verificación)
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[python-unit-test-patterns.py.md]]` | C4,C5,C8 | Patrones de tests unitarios aislados, fixtures y asserts de integridad |
| `[[python-integration-test-fixtures.py.md]]` | C3,C4,C7 | Carga masiva segura, validación de rutas y rollback automático |
| `[[python-constraint-validation-tests.py.md]]` | C4,C5,C7 | Verificación de validadores Pydantic y reportes de integridad |
| `[[python-fuzzing-security-tests.py.md]]` | C3,C7,C8 | Fuzzing de inputs con detección de vulnerabilidades OWASP-top10 |

---

## 🔗 Interacciones con el Repositorio
- **`05-CONFIGURATIONS/validation/`**: Todos los artifacts son validados por `orchestrator-engine.sh`. Los scripts `verify-constraints.sh` y `validate-skill-integrity.sh` consumen el JSON de este índice.
- **`01-RULES/`**: Las normas `harness-norms-v3.0.md`, `language-lock-protocol.md` y `06-MULTITENANCY-RULES.md` definen los constraints C1-C8 aplicados.
- **`06-PROGRAMMING/postgresql-pgvector/`**: Carpeta hermana con LANGUAGE LOCK estricto. Cero interacción directa; aislamiento de vectores (`<->`, `hnsw`) garantizado.
- **`08-LOGS/`**: Los handlers de logging estructurado (C8) alimentan dashboards en `python-audit-dashboard-realtime.md` y generan entradas en `failed-attempts/` si fallan validaciones.
- **`python-master-agent.md`**: Punto único de generación para nuevos artifacts Python. Consulta este índice ANTES de emitir módulos para asegurar coherencia con patrones existentes.

---

## ⚠️ Reglas Críticas de LANGUAGE LOCK para python/

```text
🚫 PROHIBIDO en esta carpeta:
• Importación de operadores pgvector: from pgvector import <->, cosine_distance, l2_distance
• Uso de extensiones vectoriales: CREATE EXTENSION vector; o referencias a pgvector en código Python
• Constraints vectoriales V1/V2/V3 en constraints_mapped del frontmatter

✅ REQUERIDO en esta carpeta:
• artifact_type: "python_module" | "python_script" | "python_pattern" | "python_optimization" (NUNCA "skill_pgvector")
• constraints_mapped: SOLO valores de C1-C8 (V* bloqueado por LANGUAGE LOCK)
• Módulos de producción deben incluir validación de tenant_id en queries DB o usar context managers con scope de tenant
• validation_command que referencie orchestrator-engine.sh con canonical_path correcto
• Agente master: consultar norms-matrix.json antes de declarar constraints en módulos generados
```

---

## 🤖 JSON TREE ENRIQUECIDO PARA IA (Metadatos + Dependencias + Prioridad de Normas)

```json
{
 "index_metadata": {
 "artifact_id": "00-INDEX-python",
 "artifact_type": "skill_index",
 "version": "3.1.0-SELECTIVE",
 "canonical_path": "06-PROGRAMMING/python/00-INDEX.md",
 "language_lock_status": "enforced",
 "vector_constraints_applied": false,
 "generated_timestamp": "2026-01-27T00:00:00Z",
 "master_agent": "python-master-agent"
 },
 "artifacts": [
 {
 "artifact_id": "python-master-agent",
 "file": "python-master-agent.md",
 "canonical_path": "06-PROGRAMMING/python/python-master-agent.md",
 "artifact_type": "agentic_skill_definition",
 "tier": 1,
 "constraints_mapped": ["C1","C2","C3","C4","C5","C7","C8"],
 "language_lock": ["python","asyncio","fastapi","pydantic"],
 "validation_hooks": ["verify-constraints.sh", "audit-secrets.sh", "pylint-validator.py"],
 "examples_count": 15,
 "score_baseline": 93,
 "dependencies": {
 "validators": ["verify-constraints.sh", "audit-secrets.sh", "pylint-validator.py", "mypy"],
 "norms": ["harness-norms-v3.0.md", "10-SDD-CONSTRAINTS.md", "language-lock-protocol.md", "06-MULTITENANCY-RULES.md"],
 "config": ["norms-matrix.json", "skill-template.md", "pyproject.toml"]
 },
 "dependents": ["all python artifacts"],
 "norms_priority": {
 "execution_order": ["C4", "C3", "C5", "C7", "C8", "C1", "C2"],
 "blocking_constraints": ["C3", "C4"],
 "rationale": "Security (C3) and tenant isolation (C4) are foundational for module generation"
 },
 "interactions": {
 "with_validation": "Emits JSON to stdout, logs to stderr, JSONL to 08-LOGS/ per V-INT-03",
 "with_config": "Consults norms-matrix.json before declaring constraints in generated modules",
 "with_programming": "Delegates vector operations to postgresql-pgvector/ per LANGUAGE LOCK"
 }
 },
 {
 "artifact_id": "python-hardening-verification",
 "file": "python-hardening-verification.py.md",
 "canonical_path": "06-PROGRAMMING/python/python-hardening-verification.py.md",
 "constraints_mapped": ["C3","C4","C5","C7","C8"],
 "examples_count": 10,
 "score_baseline": 89,
 "dependencies": {
 "validators": ["verify-constraints.sh", "pylint-validator.py"],
 "norms": ["harness-norms-v3.0.md", "10-SDD-CONSTRAINTS.md"],
 "templates": ["skill-template.md"]
 },
 "dependents": ["all phase-1 to phase-5 artifacts"],
 "norms_priority": {
 "execution_order": ["C4", "C3", "C7", "C5", "C8"],
 "blocking_constraints": ["C4", "C3"],
 "rationale": "Pre-flight validation must confirm tenant isolation and security before any module execution"
 },
 "interactions": {
 "with_validation": "Provides baseline checks consumed by orchestrator-engine.sh",
 "with_config": "References norms-matrix.json for constraint routing logic",
 "with_programming": "NO interaction with postgresql-pgvector/ due to LANGUAGE LOCK"
 }
 },
 {
 "artifact_id": "python-tenant-context-manager",
 "file": "python-tenant-context-manager.py.md",
 "canonical_path": "06-PROGRAMMING/python/python-tenant-context-manager.py.md",
 "constraints_mapped": ["C3","C4","C5","C7","C8"],
 "examples_count": 12,
 "score_baseline": 92,
 "dependencies": {
 "validators": ["verify-constraints.sh", "audit-secrets.sh"],
 "norms": ["harness-norms-v3.0.md#C4", "06-MULTITENANCY-RULES.md"],
 "security_refs": ["03-SECURITY-RULES.md"]
 },
 "dependents": ["python-sqlalchemy-tenant-enforcement", "python-async-db-pooling", "python-aggregation-safe"],
 "norms_priority": {
 "execution_order": ["C4", "C8", "C3", "C7", "C5"],
 "blocking_constraints": ["C4"],
 "rationale": "Context manager is the enforcement mechanism for C4; must be validated first"
 },
 "interactions": {
 "with_validation": "verify-constraints.sh validates tenant_id propagation in __enter__/__exit__",
 "with_config": "Aligns with multi-tenant rules in 06-MULTITENANCY-RULES.md",
 "with_programming": "Context patterns reusable in postgres-pgvector/ ONLY if V* triggers met"
 }
 },
 {
 "artifact_id": "python-secrets-management",
 "file": "python-secrets-management.py.md",
 "canonical_path": "06-PROGRAMMING/python/python-secrets-management.py.md",
 "constraints_mapped": ["C3","C5","C7"],
 "examples_count": 10,
 "score_baseline": 90,
 "dependencies": {
 "validators": ["audit-secrets.sh", "verify-constraints.sh"],
 "norms": ["harness-norms-v3.0.md#C3"],
 "templates": [".env.example", "pyproject.toml"]
 },
 "dependents": ["python-tenant-context-manager", "python-context-injection-for-ia"],
 "norms_priority": {
 "execution_order": ["C3", "C7", "C5"],
 "blocking_constraints": ["C3"],
 "rationale": "Secrets handling is security-critical; must pass before structural checks"
 },
 "interactions": {
 "with_validation": "audit-secrets.sh validates zero hardcode secrets in examples",
 "with_config": "References .env.example for placeholder patterns",
 "with_programming": "Secrets patterns consumed by application layer config loading"
 }
 },
 {
 "artifact_id": "python-sqlalchemy-tenant-enforcement",
 "file": "python-sqlalchemy-tenant-enforcement.py.md",
 "canonical_path": "06-PROGRAMMING/python/python-sqlalchemy-tenant-enforcement.py.md",
 "constraints_mapped": ["C3","C4","C8"],
 "examples_count": 14,
 "score_baseline": 93,
 "dependencies": {
 "validators": ["verify-constraints.sh", "pylint-validator.py"],
 "norms": ["harness-norms-v3.0.md#C4"],
 "templates": ["skill-template.md"]
 },
 "dependents": ["python-async-db-pooling", "python-aggregation-safe", "python-nl-to-query-patterns"],
 "norms_priority": {
 "execution_order": ["C4", "C3", "C8"],
 "blocking_constraints": ["C4"],
 "rationale": "ORM queries are the primary attack surface; tenant enforcement is non-negotiable"
 },
 "interactions": {
 "with_validation": "verify-constraints.sh validates tenant_id filter in all query examples",
 "with_config": "Parametrization patterns align with SQLAlchemy best practices",
 "with_programming": "Core ORM template consumed by application service layer"
 }
 }
 ],
 "dependency_graph": {
 "validation_layer": {
 "orchestrator-engine.sh": ["all artifacts"],
 "verify-constraints.sh": ["all artifacts"],
 "audit-secrets.sh": ["python-secrets-management", "python-tenant-context-manager", "python-master-agent"],
 "pylint-validator.py": ["python-hardening-verification", "python-sqlalchemy-tenant-enforcement", "python-master-agent"],
 "mypy": ["python-type-hinting-protocols", "python-sqlalchemy-tenant-enforcement"]
 },
 "norms_layer": {
 "harness-norms-v3.0.md": ["all artifacts"],
 "10-SDD-CONSTRAINTS.md": ["all artifacts"],
 "language-lock-protocol.md": ["all artifacts"],
 "06-MULTITENANCY-RULES.md": ["python-tenant-context-manager", "python-sqlalchemy-tenant-enforcement", "python-rbac-decorators"],
 "norms-matrix.json": ["all artifacts", "python-master-agent"]
 },
 "config_layer": {
 "skill-template.md": ["all artifacts"],
 ".env.example": ["python-secrets-management", "python-tenant-context-manager"],
 "pyproject.toml": ["python-hardening-verification", "python-deployment-docker"],
 "pyproject.toml": ["python-master-agent"]
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
 "exclusion": "python/ ALWAYS excludes V1/V2/V3 per LANGUAGE LOCK"
 }
 },
 "language_lock_enforcement": {
 "folder": "06-PROGRAMMING/python/",
 "prohibited_patterns": ["from pgvector import", "cosine_distance", "l2_distance", "hamming_distance", "vector\\("],
 "required_artifact_types": ["python_module", "python_script", "python_pattern", "python_optimization"],
 "prohibited_constraints": ["V1", "V2", "V3"],
 "validation_script": "validate-skill-integrity.sh --check-language-lock",
 "failure_action": "exit 2 with message 'LANGUAGE LOCK VIOLATION: pgvector imports not allowed in Python domain'"
 },
 "ai_navigation_hints": {
 "for_generation": "Read python-master-agent.md AND this index BEFORE generating new Python artifacts",
 "for_validation": "Use norms_execution_priority to order constraint checks in custom validators",
 "for_migration": "Consult dependency_graph before modifying shared patterns across artifacts",
 "for_debugging": "Check language_lock_enforcement if pgvector imports appear in python/ artifacts",
 "for_master_agent": "Agent must consult norms-matrix.json before declaring constraints; emit JSON to stdout, logs to stderr, JSONL to 08-LOGS/"
 }
}
```

---

## 🔗 RAW_URLS_INDEX – Patrones Python Disponibles

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
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/pylint-validator.py
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/schemas/skill-input-output.schema.json
```

### 🐍 Patrones Python Core (06-PROGRAMMING/python)
```text
# Índice y Agente Master
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/00-INDEX.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/python-master-agent.md

# Fase 0: Core Hardening
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/python-hardening-verification.py.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/python-linter-integration.py.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/python-exception-handling.py.md

# Fase 1: Multi-Tenant Security
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/python-tenant-context-manager.py.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/python-rbac-decorators.py.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/python-secrets-management.py.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/python-audit-logging.py.md

# Fase 2: CI/CD & Testing
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/python-pytest-tenant-isolation.py.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/python-mock-strategies.py.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/python-type-hinting-protocols.py.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/python-deployment-docker.py.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/python-health-checks.py.md

# Fase 3: Query Patterns & IA-Assist
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/python-sqlalchemy-tenant-enforcement.py.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/python-async-db-pooling.py.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/python-aggregation-safe.py.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/python-query-explain-templates.py.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/python-nl-to-query-patterns.py.md

# Fase 4: MCP/IA Tooling
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/python-mcp-tool-definitions.py.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/python-ia-query-validation-gate.py.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/python-context-injection-for-ia.py.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/python-audit-trail-ia-generated.py.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/python-permission-scoping-for-ia.py.md

# Fase 5: Testing & Validation
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/python-unit-test-patterns.py.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/python-integration-test-fixtures.py.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/python-constraint-validation-tests.py.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/python-fuzzing-security-tests.py.md
```

### 🦜 Referencias Vectoriales (SOLO para consulta, NO para uso en Python estándar)
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
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/validation-tools/pylint-validator/README.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/programming/python/python-master-agent/README.md
```

---

## 🗂️ RUTAS CANÓNICAS LOCALES – Patrones Python (Para Acceso en Repo)

> **Formato**: `RAW_URL` → `./ruta/local/en/repo`

### 🐍 Patrones Python Core
```text
# Índice y Agente Master
06-PROGRAMMING/python/00-INDEX.md
06-PROGRAMMING/python/python-master-agent.md

# Fase 0: Core Hardening
06-PROGRAMMING/python/python-hardening-verification.py.md
06-PROGRAMMING/python/python-linter-integration.py.md
06-PROGRAMMING/python/python-exception-handling.py.md

# Fase 1: Multi-Tenant Security
06-PROGRAMMING/python/python-tenant-context-manager.py.md
06-PROGRAMMING/python/python-rbac-decorators.py.md
06-PROGRAMMING/python/python-secrets-management.py.md
06-PROGRAMMING/python/python-audit-logging.py.md

# Fase 2: CI/CD & Testing
06-PROGRAMMING/python/python-pytest-tenant-isolation.py.md
06-PROGRAMMING/python/python-mock-strategies.py.md
06-PROGRAMMING/python/python-type-hinting-protocols.py.md
06-PROGRAMMING/python/python-deployment-docker.py.md
06-PROGRAMMING/python/python-health-checks.py.md

# Fase 3: Query Patterns & IA-Assist
06-PROGRAMMING/python/python-sqlalchemy-tenant-enforcement.py.md
06-PROGRAMMING/python/python-async-db-pooling.py.md
06-PROGRAMMING/python/python-aggregation-safe.py.md
06-PROGRAMMING/python/python-query-explain-templates.py.md
06-PROGRAMMING/python/python-nl-to-query-patterns.py.md

# Fase 4: MCP/IA Tooling
06-PROGRAMMING/python/python-mcp-tool-definitions.py.md
06-PROGRAMMING/python/python-ia-query-validation-gate.py.md
06-PROGRAMMING/python/python-context-injection-for-ia.py.md
06-PROGRAMMING/python/python-audit-trail-ia-generated.py.md
06-PROGRAMMING/python/python-permission-scoping-for-ia.py.md

# Fase 5: Testing & Validation
06-PROGRAMMING/python/python-unit-test-patterns.py.md
06-PROGRAMMING/python/python-integration-test-fixtures.py.md
06-PROGRAMMING/python/python-constraint-validation-tests.py.md
06-PROGRAMMING/python/python-fuzzing-security-tests.py.md
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
docs/pt-BR/validation-tools/pylint-validator/README.md
docs/pt-BR/programming/python/python-master-agent/README.md
```

---

## 🧭 GUÍA DE USO PARA EL AGENTE PYTHON

```python
# Pseudocódigo: Cómo consultar patrones disponibles en Python
# (Implementado en el agente, no en Python puro para evitar circularidad)

def consultar_patron_python(nombre_patron: str) -> dict:
    base_raw = "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/"
    base_local = "./06-PROGRAMMING/python/"
    
    filename = f"{nombre_patron}.py.md" if nombre_patron == "python-master-agent" else f"{nombre_patron}.py.md"
    return {
        "raw_url": f"{base_raw}06-PROGRAMMING/python/{filename}",
        "canonical_path": f"{base_local}{filename}",
        "domain": "06-PROGRAMMING/python/",
        "language_lock": "python,asyncio,fastapi,pydantic",  # 🔒 CERO imports de pgvector
        "constraints_default": "C3,C4,C5",  # Mínimo para producción
    }

# Ejemplo de validación de constraints antes de emitir módulo
def validar_constraints_python(artifact_path: str) -> list:
    fm = extract_frontmatter(artifact_path)
    declared = fm.get("constraints_mapped", [])
    matrix = load_json("./05-CONFIGURATIONS/validation/norms-matrix.json")
    allowed = get_allowed_constraints(matrix, artifact_path)
    
    issues = []
    for c in declared:
        if c not in allowed:
            issues.append(f"constraint '{c}' not allowed for path {artifact_path}")
    return issues

# Ejemplo de detección de LANGUAGE LOCK en código Python
def contiene_imports_pgvector(code: str) -> bool:
    return bool(re.search(r'from\s+pgvector\s+import|import\s+pgvector|cosine_distance|l2_distance', code))

# Uso en el agente:
if contiene_imports_pgvector(input_code):
    print("LANGUAGE LOCK: pgvector imports not allowed in Python domain. Use postgresql-pgvector/", file=sys.stderr)
    sys.exit(1)
else:
    # Generar módulo Python estándar con tenant isolation
    module = """
from sqlalchemy import select
from app.context import get_tenant_id

def get_active_docs(session, user_id: str):
    tenant_id = get_tenant_id()
    return session.execute(
        select(Doc).where(Doc.tenant_id == tenant_id, Doc.status == 'active')
    )
"""
```

---

## 📋 INSTRUCCIONES DE INTEGRACIÓN (Actualizadas)

### Paso 1: Agregar al final del agente
Pegar los bloques de referencias justo antes de la sección `## Limitations` en:
- `06-PROGRAMMING/python/python-master-agent.md`

### Paso 2: Actualizar el comportamiento del agente
En la sección `## Comportamiento del Agente` o `## Behavioral Traits`, agregar:

```markdown
| Trait | Implementación contractual |
|-------|---------------------------|
| **Consulta patrones antes de generar** | Antes de emitir módulo Python, el agente debe consultar la lista de patrones disponibles en `06-PROGRAMMING/python/` para asegurar coherencia con el repositorio |
| **Acceso dual** | Usar ruta canónica (`./06-PROGRAMMING/python/...`) para acceso local, o raw URL para acceso remoto si el archivo no existe localmente |
| **LANGUAGE LOCK automático** | Si el usuario solicita imports de pgvector (`from pgvector import`, `cosine_distance`), el agente debe delegar a `06-PROGRAMMING/postgresql-pgvector/` y NO generar código con vectores en su dominio |
| **Enseña mientras genera** | Incluir docstrings y type hints explicativos en los módulos generados para facilitar el aprendizaje del usuario |
| **Valida constraints antes de emitir** | Ejecutar `validar_constraints_python()` antes de emitir cualquier artifact para asegurar coherencia con `norms-matrix.json` |
| **Emite logs estructurados** | JSON a `stdout`, logs humanos a `stderr`, JSONL a `08-LOGS/validation/...` per V-INT-03 y V-LOG-02 |
```

### Paso 3: Validar con `verify-constraints.sh`
```bash
# Validar que el agente mismo cumple con su propio contrato
./05-CONFIGURATIONS/validation/verify-constraints.sh --file 06-PROGRAMMING/python/python-master-agent.md | jq
```

---

> 📌 **Nota final**: Este índice es Tier 1 (referencia contractual). Cualquier modificación debe pasar validación automática antes de merge.  
> 🇧🇷 *Documentação técnica completa disponível em*: `docs/pt-BR/programming/python/00-INDEX/README.md` (próxima entrega).
```

---
