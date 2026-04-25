---
artifact_id: "00-INDEX-postgresql-pgvector"
artifact_type: "skill_index"
version: "3.1.0-SELECTIVE"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","V1","V2","V3"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/postgresql-pgvector/00-INDEX.md --json"
canonical_path: "06-PROGRAMMING/postgresql-pgvector/00-INDEX.md"
---

# PostgreSQL + pgvector RAG Master Index – Multi-Tenant Vector Search & AI Integration

## 👤 Propósito y Alcance
Índice canónico de navegación para `06-PROGRAMMING/postgresql-pgvector/`. Documenta 22 artifacts auditados bajo HARNESS NORMS v3.1.0-SELECTIVE, mapea flujos de ejecución para búsqueda vectorial con aislamiento multi-tenant, referencia al **agente master de generación RAG/pgvector**, y proporciona un árbol JSON enriquecido para routing de agentes LLM y pipelines CI/CD.

> 🔑 **Diferenciador crítico**: Este es el **ÚNICO dominio** del repositorio donde están permitidos:
> - Constraints vectoriales: `V1` (dimensiones explícitas), `V2` (métrica documentada), `V3` (parámetros de índice justificados)
> - Operadores pgvector: `<->`, `<#>`, `<=>`, `vector(n)`, `USING hnsw`, `USING ivfflat`
> - Extensiones: `CREATE EXTENSION vector;`

---

## 🤖 Agente de Generación Disponible

| Agente | Canonical Path | Dominio | Constraints Soportados | Hooks de Validación |
|--------|---------------|---------|----------------------|-------------------|
| **`postgresql-pgvector-rag-master-agent`** ✅ | `[[06-PROGRAMMING/postgresql-pgvector/postgresql-pgvector-rag-master-agent.md]]` | `postgresql,pgvector,rag,embeddings` | `C1,C2,C3,C4,C5,C7,C8,V1,V2,V3` | `verify-constraints.sh`, `audit-secrets.sh`, `check-rls.sh`, `vector-schema-validator.py` |

> ⚠️ **Nota contractual**: Este agente es Tier 1 (referencia educativa). Cualquier query vectorial generada debe pasar validación automática antes de merge. Documentación técnica en pt-BR: `docs/pt-BR/programming/postgresql-pgvector/postgresql-pgvector-rag-master-agent/README.md`.

---

## 📂 Mapeo de Fases y Wikilinks

### FASE 0 – Vector Foundation (Setup & Configuration)
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[pgvector-extension-setup.pgvector.md]]` | C1,C3,C4,V1,V3 | Instalación segura de extensión con validación de versión y límites de recursos |
| `[[embedding-dimension-selection.pgvector.md]]` | C4,V1,V2 | Selección de dimensiones (384/768/1536) con justificación por caso de uso |
| `[[vector-index-strategy-comparison.pgvector.md]]` | C1,C7,V2,V3 | Comparativa HNSW vs IVFFlat con benchmarks de latencia/memoria |

### FASE 1 – Multi-Tenant Vector Isolation (Aislamiento)
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[tenant-isolation-for-embeddings.pgvector.md]]` | C3,C4,C8,V1 | Estrategias de aislamiento: schema-per-tenant vs row-level con tenant_id |
| `[[rag-query-with-tenant-enforcement.pgvector.md]]` | C3,C4,C8,V1,V2 | Query RAG con `WHERE tenant_id = $1` + búsqueda por similitud coseno |
| `[[vector-metadata-tenant-scoping.pgvector.md]]` | C4,C5,C8 | Metadatos vectoriales con scope de tenant para filtrado pre-búsqueda |

### FASE 2 – Embedding Generation & Management
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[embedding-generation-pipeline.pgvector.md]]` | C1,C4,C7,V1 | Pipeline async con límites de CPU/memoria y retry con backoff |
| `[[embedding-batch-insert-optimization.pgvector.md]]` | C1,C7,V3 | Inserción masiva con COPY, tuning de `hnsw.ef_insert` y checkpointing |
| `[[embedding-update-strategies.pgvector.md]]` | C4,C5,C7 | Estrategias para re-embeddings: incremental vs full reindex con tenant scoping |

### FASE 3 – RAG Query Patterns (Consultas)
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[hybrid-search-scalar-vector.pgvector.md]]` | C4,C5,C8,V2 | Búsqueda híbrida: filtros SQL + similitud vectorial con ponderación configurable |
| `[[reranking-post-filtering.pgvector.md]]` | C4,C7,C8,V2 | Post-procesamiento con cross-encoder y límites de timeout por tenant |
| `[[query-expansion-for-rag.pgvector.md]]` | C4,C8,V2 | Expansión de queries con sinónimos y validación de relevancia por contexto de tenant |
| `[[multi-vector-representation.pgvector.md]]` | C4,V1,V3 | Representación múltiple por documento: título/contenido/metadatos con índices separados |

### FASE 4 – Performance & Observability
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[vector-query-latency-monitoring.pgvector.md]]` | C7,C8,V2 | Métricas Prometheus para p95/p99 de consultas vectoriales por tenant |
| `[[hnsw-tuning-production.pgvector.md]]` | C1,C7,V3 | Ajuste de `hnsw.m`, `hnsw.ef_search` con validación de trade-off precisión/latencia |
| `[[vector-cache-strategies.pgvector.md]]` | C1,C4,C7 | Cache de embeddings frecuentes con invalidación por tenant y TTL configurable |

### FASE 5 – Testing & Validation
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[vector-similarity-unit-tests.pgvector.md]]` | C4,C5,V2 | Tests de similitud con casos borde: vectores cero, dimensiones mismatch, tenant leakage |
| `[[rag-evaluation-metrics.pgvector.md]]` | C8,V2 | Métricas de evaluación RAG: hit-rate, MRR, NDCG con reporting por tenant |
| `[[drift-detection-embeddings.pgvector.md]]` | C5,C8,V1 | Detección de drift en distribuciones de embeddings con alertas por desviación estadística |

---

## 🔗 Interacciones con el Repositorio
- **`05-CONFIGURATIONS/validation/`**: Todos los artifacts son validados por `orchestrator-engine.sh`. Los scripts `verify-constraints.sh`, `check-rls.sh` y `vector-schema-validator.py` consumen el JSON de este índice.
- **`01-RULES/`**: Las normas `harness-norms-v3.0.md`, `language-lock-protocol.md` y `10-SDD-CONSTRAINTS.md` definen los constraints C1-C8 + V1-V3 aplicados.
- **`06-PROGRAMMING/sql/`**: Carpeta hermana con LANGUAGE LOCK estricto. **Delegación obligatoria**: queries SQL sin vectores deben generarse en `sql/`, no aquí.
- **`06-PROGRAMMING/python/`**: Para lógica de aplicación (embedding generation, API wrappers), usar `python/` y delegar solo la query vectorial final a este dominio.
- **`08-LOGS/`**: Los handlers de logging estructurado (C8) alimentan dashboards en `vector-query-latency-monitoring.pgvector.md` y generan entradas en `failed-attempts/` si fallan validaciones de tenant isolation.
- **`postgresql-pgvector-rag-master-agent.md`**: Punto único de generación para nuevos artifacts pgvector. Consulta este índice ANTES de emitir queries vectoriales para asegurar coherencia con patrones existentes y enforcement de V1-V3.

---

## ⚠️ Reglas Críticas de LANGUAGE LOCK para postgresql-pgvector/

```text
✅ PERMITIDO (y requerido para operaciones vectoriales) en esta carpeta:
• Operadores pgvector: <-> (cosine), <#> (inner product), <=> (L2 distance)
• Tipos y funciones: vector(n), cosine_distance(), l2_distance(), inner_product()
• Índices vectoriales: USING hnsw (con hnsw.m, hnsw.ef_search), USING ivfflat (con ivfflat.lists)
• Extensiones: CREATE EXTENSION vector; (solo en migrations, no en queries runtime)
• Constraints vectoriales en frontmatter: V1, V2, V3 (SOLO en este dominio)

🚫 PROHIBIDO en esta carpeta:
• Queries SQL puras sin operadores vectoriales (delegar a 06-PROGRAMMING/sql/)
• Lógica de aplicación Python/JS (delegar a 06-PROGRAMMING/python/ o javascript/)
• Schemas YAML/JSON sin referencia a vectores (delegar a 06-PROGRAMMING/yaml-json-schema/)

✅ REQUERIDO en esta carpeta:
• artifact_type: "pgvector_query" | "pgvector_migration" | "pgvector_pattern" | "rag_pipeline"
• constraints_mapped: DEBE incluir V1 si se usa vector(n), V2 si se usa operador de distancia, V3 si se configura índice
• Todas las queries vectoriales deben incluir WHERE tenant_id = $1 o políticas RLS equivalentes
• Documentar explícitamente: dimensiones del vector, métrica de distancia, parámetros de índice
• validation_command que referencie orchestrator-engine.sh con canonical_path correcto
• Agente master: consultar norms-matrix.json antes de declarar constraints V* en queries generadas
```

---

## 🤖 JSON TREE ENRIQUECIDO PARA IA (Metadatos + Dependencias + Prioridad de Normas)

```json
{
 "index_metadata": {
 "artifact_id": "00-INDEX-postgresql-pgvector",
 "artifact_type": "skill_index",
 "version": "3.1.0-SELECTIVE",
 "canonical_path": "06-PROGRAMMING/postgresql-pgvector/00-INDEX.md",
 "language_lock_status": "enforced_vector_allowed",
 "vector_constraints_applied": true,
 "generated_timestamp": "2026-01-27T00:00:00Z",
 "master_agent": "postgresql-pgvector-rag-master-agent"
 },
 "artifacts": [
 {
 "artifact_id": "postgresql-pgvector-rag-master-agent",
 "file": "postgresql-pgvector-rag-master-agent.md",
 "canonical_path": "06-PROGRAMMING/postgresql-pgvector/postgresql-pgvector-rag-master-agent.md",
 "artifact_type": "agentic_skill_definition",
 "tier": 1,
 "constraints_mapped": ["C1","C2","C3","C4","C5","C7","C8","V1","V2","V3"],
 "language_lock": ["postgresql","pgvector","rag","embeddings"],
 "validation_hooks": ["verify-constraints.sh", "audit-secrets.sh", "check-rls.sh", "vector-schema-validator.py"],
 "examples_count": 15,
 "score_baseline": 95,
 "dependencies": {
 "validators": ["verify-constraints.sh", "audit-secrets.sh", "check-rls.sh", "vector-schema-validator.py"],
 "norms": ["harness-norms-v3.0.md", "10-SDD-CONSTRAINTS.md", "language-lock-protocol.md", "06-MULTITENANCY-RULES.md"],
 "config": ["norms-matrix.json", "skill-template.md", "pgvector-config.json"]
 },
 "dependents": ["all pgvector artifacts"],
 "norms_priority": {
 "execution_order": ["C4", "V1", "V2", "C3", "V3", "C7", "C8", "C5"],
 "blocking_constraints": ["C3", "C4", "V1"],
 "rationale": "Tenant isolation (C4) and explicit vector dimensions (V1) are foundational for vector query generation"
 },
 "interactions": {
 "with_validation": "Emits JSON to stdout, logs to stderr, JSONL to 08-LOGS/ per V-INT-03",
 "with_config": "Consults norms-matrix.json before declaring V* constraints; validates vector ops are ONLY in this domain",
 "with_programming": "Delegates non-vector SQL to sql/, embedding logic to python/ per LANGUAGE LOCK"
 }
 },
 {
 "artifact_id": "tenant-isolation-for-embeddings",
 "file": "tenant-isolation-for-embeddings.pgvector.md",
 "canonical_path": "06-PROGRAMMING/postgresql-pgvector/tenant-isolation-for-embeddings.pgvector.md",
 "constraints_mapped": ["C3","C4","C8","V1"],
 "examples_count": 12,
 "score_baseline": 93,
 "dependencies": {
 "validators": ["check-rls.sh", "verify-constraints.sh", "vector-schema-validator.py"],
 "norms": ["harness-norms-v3.0.md#C4", "06-MULTITENANCY-RULES.md", "10-SDD-CONSTRAINTS.md#V1"],
 "security_refs": ["03-SECURITY-RULES.md"]
 },
 "dependents": ["rag-query-with-tenant-enforcement", "vector-metadata-tenant-scoping", "hybrid-search-scalar-vector"],
 "norms_priority": {
 "execution_order": ["C4", "V1", "C8", "C3"],
 "blocking_constraints": ["C4", "V1"],
 "rationale": "Vector queries without tenant_id enforcement (C4) or explicit dimensions (V1) risk data leakage and schema drift"
 },
 "interactions": {
 "with_validation": "check-rls.sh validates tenant_id propagation in vector WHERE clauses",
 "with_config": "Aligns with multi-tenant rules in 06-MULTITENANCY-RULES.md for vector data",
 "with_programming": "Isolation patterns consumed by application layer before calling vector search"
 }
 },
 {
 "artifact_id": "rag-query-with-tenant-enforcement",
 "file": "rag-query-with-tenant-enforcement.pgvector.md",
 "canonical_path": "06-PROGRAMMING/postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md",
 "constraints_mapped": ["C3","C4","C8","V1","V2"],
 "examples_count": 14,
 "score_baseline": 94,
 "dependencies": {
 "validators": ["verify-constraints.sh", "check-rls.sh", "vector-schema-validator.py"],
 "norms": ["harness-norms-v3.0.md#C4", "10-SDD-CONSTRAINTS.md#V1,V2"],
 "templates": ["skill-template.md"]
 },
 "dependents": ["hybrid-search-scalar-vector", "reranking-post-filtering", "query-expansion-for-rag"],
 "norms_priority": {
 "execution_order": ["C4", "V1", "V2", "C8", "C3"],
 "blocking_constraints": ["C4", "V1"],
 "rationale": "RAG queries must enforce tenant isolation (C4) and declare vector dimensions (V1) before metric selection (V2)"
 },
 "interactions": {
 "with_validation": "vector-schema-validator.py checks cosine_distance() usage matches V2 metric declaration",
 "with_config": "Parametrization patterns align with prepared statement best practices for vector queries",
 "with_programming": "Core RAG template consumed by application service layer for semantic search"
 }
 },
 {
 "artifact_id": "embedding-dimension-selection",
 "file": "embedding-dimension-selection.pgvector.md",
 "canonical_path": "06-PROGRAMMING/postgresql-pgvector/embedding-dimension-selection.pgvector.md",
 "constraints_mapped": ["C4","V1","V2"],
 "examples_count": 10,
 "score_baseline": 91,
 "dependencies": {
 "validators": ["vector-schema-validator.py", "verify-constraints.sh"],
 "norms": ["10-SDD-CONSTRAINTS.md#V1,V2"],
 "templates": ["embedding-models-reference.json"]
 },
 "dependents": ["pgvector-extension-setup", "rag-query-with-tenant-enforcement", "multi-vector-representation"],
 "norms_priority": {
 "execution_order": ["V1", "V2", "C4"],
 "blocking_constraints": ["V1"],
 "rationale": "Vector dimension declaration (V1) is foundational; metric selection (V2) depends on dimension choice"
 },
 "interactions": {
 "with_validation": "vector-schema-validator.py enforces vector(n) syntax matches declared dimension in V1",
 "with_config": "References embedding-models-reference.json for model→dimension mapping",
 "with_programming": "Dimension selection patterns inform application embedding generation pipeline"
 }
 },
 {
 "artifact_id": "hnsw-tuning-production",
 "file": "hnsw-tuning-production.pgvector.md",
 "canonical_path": "06-PROGRAMMING/postgresql-pgvector/hnsw-tuning-production.pgvector.md",
 "constraints_mapped": ["C1","C7","V3"],
 "examples_count": 11,
 "score_baseline": 92,
 "dependencies": {
 "validators": ["verify-constraints.sh", "vector-schema-validator.py"],
 "norms": ["harness-norms-v3.0.md#C1,C7", "10-SDD-CONSTRAINTS.md#V3"],
 "benchmarks": ["hnsw-benchmark-results.json"]
 },
 "dependents": ["vector-query-latency-monitoring", "vector-cache-strategies"],
 "norms_priority": {
 "execution_order": ["V3", "C7", "C1"],
 "blocking_constraints": ["V3"],
 "rationale": "Index parameter justification (V3) must precede resource budget validation (C7) for HNSW tuning"
 },
 "interactions": {
 "with_validation": "vector-schema-validator.py checks hnsw.m/ef_search values are documented per V3",
 "with_config": "Tuning patterns align with docker-compose resource limits (C1)",
 "with_programming": "HNSW parameters consumed by migration scripts for index creation"
 }
 }
 ],
 "dependency_graph": {
 "validation_layer": {
 "orchestrator-engine.sh": ["all artifacts"],
 "verify-constraints.sh": ["all artifacts"],
 "audit-secrets.sh": ["pgvector-extension-setup", "embedding-generation-pipeline"],
 "check-rls.sh": ["tenant-isolation-for-embeddings", "rag-query-with-tenant-enforcement"],
 "vector-schema-validator.py": ["all pgvector artifacts", "postgresql-pgvector-rag-master-agent"]
 },
 "norms_layer": {
 "harness-norms-v3.0.md": ["all artifacts"],
 "10-SDD-CONSTRAINTS.md": ["all artifacts"],
 "language-lock-protocol.md": ["all artifacts"],
 "06-MULTITENANCY-RULES.md": ["tenant-isolation-for-embeddings", "rag-query-with-tenant-enforcement"],
 "norms-matrix.json": ["all artifacts", "postgresql-pgvector-rag-master-agent"]
 },
 "config_layer": {
 "skill-template.md": ["all artifacts"],
 "pgvector-config.json": ["pgvector-extension-setup", "hnsw-tuning-production"],
 "embedding-models-reference.json": ["embedding-dimension-selection", "multi-vector-representation"]
 }
 },
 "norms_execution_priority": {
 "global_order": ["C4", "V1", "V2", "C3", "V3", "C7", "C8", "C5"],
 "rationale": "C4 (tenant isolation) is foundational; V1 (dimensions) and V2 (metric) must be declared before vector operations; C3 (secrets) and V3 (index params) follow; then performance (C7) and observability (C8)",
 "blocking_set": ["C3", "C4", "V1"],
 "non_blocking_set": ["C1", "C2", "C5", "C6", "C7", "C8", "V2", "V3"],
 "selective_v_logic": {
 "applies_to": "postgresql-pgvector/ ONLY",
 "trigger": "artifact_type IN ['pgvector_query', 'pgvector_migration', 'pgvector_pattern', 'rag_pipeline'] AND content has pgvector operators",
 "exclusion": "All other domains (sql/, python/, yaml-json-schema/) ALWAYS exclude V1/V2/V3 per LANGUAGE LOCK"
 }
 },
 "language_lock_enforcement": {
 "folder": "06-PROGRAMMING/postgresql-pgvector/",
 "required_patterns": ["<->|<#>|<=>", "vector\\([0-9]+\\)", "(cosine_distance|l2_distance|inner_product)\\("],
 "required_artifact_types": ["pgvector_query", "pgvector_migration", "pgvector_pattern", "rag_pipeline"],
 "required_constraints": ["V1 if vector(n) used", "V2 if distance operator used", "V3 if index params configured"],
 "delegation_rules": {
 "to_sql_domain": "Pure SQL queries without vector operators",
 "to_python_domain": "Embedding generation logic, API wrappers, application business logic",
 "to_yaml_domain": "Schema definitions without vector references"
 },
 "validation_script": "validate-skill-integrity.sh --check-language-lock --allow-vector-ops",
 "failure_action": "exit 2 with message 'LANGUAGE LOCK VIOLATION: Vector operations only allowed in postgresql-pgvector/'"
 },
 "ai_navigation_hints": {
 "for_generation": "Read postgresql-pgvector-rag-master-agent.md AND this index BEFORE generating new pgvector artifacts. Confirm V1/V2/V3 are declared if using vector ops.",
 "for_validation": "Use norms_execution_priority: validate C4/V1 before allowing vector operators in query examples",
 "for_migration": "Consult dependency_graph before modifying shared patterns; vector index changes (V3) may require re-embedding",
 "for_debugging": "If vector operators appear outside postgresql-pgvector/, check language_lock_enforcement and delegate to correct domain",
 "for_master_agent": "Agent MUST consult norms-matrix.json before declaring V* constraints; emit JSON to stdout, logs to stderr, JSONL to 08-LOGS/; delegate non-vector logic to appropriate domains"
 }
}
```

---

## 🔗 RAW_URLS_INDEX – Patrones pgvector/RAG Disponibles

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
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/vector-schema-validator.py
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/schemas/skill-input-output.schema.json
```

### 🧠 Patrones pgvector/RAG Core (06-PROGRAMMING/postgresql-pgvector)
```text
# Índice y Agente Master
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/00-INDEX.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/postgresql-pgvector-rag-master-agent.md

# Fase 0: Vector Foundation
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/pgvector-extension-setup.pgvector.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/embedding-dimension-selection.pgvector.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/vector-index-strategy-comparison.pgvector.md

# Fase 1: Multi-Tenant Vector Isolation
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/tenant-isolation-for-embeddings.pgvector.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/vector-metadata-tenant-scoping.pgvector.md

# Fase 2: Embedding Generation & Management
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/embedding-generation-pipeline.pgvector.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/embedding-batch-insert-optimization.pgvector.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/embedding-update-strategies.pgvector.md

# Fase 3: RAG Query Patterns
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/hybrid-search-scalar-vector.pgvector.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/reranking-post-filtering.pgvector.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/query-expansion-for-rag.pgvector.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/multi-vector-representation.pgvector.md

# Fase 4: Performance & Observability
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/vector-query-latency-monitoring.pgvector.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/hnsw-tuning-production.pgvector.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/vector-cache-strategies.pgvector.md

# Fase 5: Testing & Validation
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/vector-similarity-unit-tests.pgvector.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/rag-evaluation-metrics.pgvector.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/drift-detection-embeddings.pgvector.md
```

### 🔗 Referencias de Dominios Hermanos (Para Delegación)
```text
# SQL puro (delegar queries sin vectores)
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/00-INDEX.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/crud-with-tenant-enforcement.sql.md

# Python (delegar lógica de aplicación)
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/00-INDEX.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/python-sqlalchemy-tenant-enforcement.py.md

# YAML/JSON Schema (delegar definiciones sin vectores)
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
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/validation-tools/check-rls/README.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/validation-tools/vector-schema-validator/README.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/programming/postgresql-pgvector/postgresql-pgvector-rag-master-agent/README.md
```

---

## 🗂️ RUTAS CANÓNICAS LOCALES – Patrones pgvector/RAG (Para Acceso en Repo)

> **Formato**: `RAW_URL` → `./ruta/local/en/repo`

### 🧠 Patrones pgvector/RAG Core
```text
# Índice y Agente Master
06-PROGRAMMING/postgresql-pgvector/00-INDEX.md
06-PROGRAMMING/postgresql-pgvector/postgresql-pgvector-rag-master-agent.md

# Fase 0: Vector Foundation
06-PROGRAMMING/postgresql-pgvector/pgvector-extension-setup.pgvector.md
06-PROGRAMMING/postgresql-pgvector/embedding-dimension-selection.pgvector.md
06-PROGRAMMING/postgresql-pgvector/vector-index-strategy-comparison.pgvector.md

# Fase 1: Multi-Tenant Vector Isolation
06-PROGRAMMING/postgresql-pgvector/tenant-isolation-for-embeddings.pgvector.md
06-PROGRAMMING/postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md
06-PROGRAMMING/postgresql-pgvector/vector-metadata-tenant-scoping.pgvector.md

# Fase 2: Embedding Generation & Management
06-PROGRAMMING/postgresql-pgvector/embedding-generation-pipeline.pgvector.md
06-PROGRAMMING/postgresql-pgvector/embedding-batch-insert-optimization.pgvector.md
06-PROGRAMMING/postgresql-pgvector/embedding-update-strategies.pgvector.md

# Fase 3: RAG Query Patterns
06-PROGRAMMING/postgresql-pgvector/hybrid-search-scalar-vector.pgvector.md
06-PROGRAMMING/postgresql-pgvector/reranking-post-filtering.pgvector.md
06-PROGRAMMING/postgresql-pgvector/query-expansion-for-rag.pgvector.md
06-PROGRAMMING/postgresql-pgvector/multi-vector-representation.pgvector.md

# Fase 4: Performance & Observability
06-PROGRAMMING/postgresql-pgvector/vector-query-latency-monitoring.pgvector.md
06-PROGRAMMING/postgresql-pgvector/hnsw-tuning-production.pgvector.md
06-PROGRAMMING/postgresql-pgvector/vector-cache-strategies.pgvector.md

# Fase 5: Testing & Validation
06-PROGRAMMING/postgresql-pgvector/vector-similarity-unit-tests.pgvector.md
06-PROGRAMMING/postgresql-pgvector/rag-evaluation-metrics.pgvector.md
06-PROGRAMMING/postgresql-pgvector/drift-detection-embeddings.pgvector.md
```

### 🔗 Referencias de Dominios Hermanos (Para Delegación)
```text
# SQL puro
06-PROGRAMMING/sql/00-INDEX.md
06-PROGRAMMING/sql/crud-with-tenant-enforcement.sql.md

# Python
06-PROGRAMMING/python/00-INDEX.md
06-PROGRAMMING/python/python-sqlalchemy-tenant-enforcement.py.md

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
docs/pt-BR/validation-tools/check-rls/README.md
docs/pt-BR/validation-tools/vector-schema-validator/README.md
docs/pt-BR/programming/postgresql-pgvector/postgresql-pgvector-rag-master-agent/README.md
```

---

## 🧭 GUÍA DE USO PARA EL AGENTE PGVECTOR/RAG

```python
# Pseudocódigo: Cómo consultar patrones disponibles en pgvector/RAG
# (Implementado en el agente, no en Python puro para evitar circularidad)

def consultar_patron_pgvector(nombre_patron: str) -> dict:
    base_raw = "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/"
    base_local = "./06-PROGRAMMING/postgresql-pgvector/"
    
    filename = f"{nombre_patron}.pgvector.md" if nombre_patron != "postgresql-pgvector-rag-master-agent" else f"{nombre_patron}.md"
    return {
        "raw_url": f"{base_raw}06-PROGRAMMING/postgresql-pgvector/{filename}",
        "canonical_path": f"{base_local}{filename}",
        "domain": "06-PROGRAMMING/postgresql-pgvector/",
        "language_lock": "postgresql,pgvector,rag,embeddings",  # ✅ ÚNICO dominio con operadores vectoriales
        "constraints_default": "C3,C4,C8,V1,V2",  # Mínimo para RAG en producción
        "vector_ops_allowed": True,  # 🔑 Flag crítico para routing
    }

# Ejemplo de validación de constraints vectoriales antes de emitir query
def validar_constraints_pgvector(artifact_path: str) -> list:
    fm = extract_frontmatter(artifact_path)
    declared = fm.get("constraints_mapped", [])
    content = load_file(artifact_path)
    
    issues = []
    
    # V1: Si hay vector(n), debe estar declarado
    if re.search(r'vector\(\d+\)', content) and "V1" not in declared:
        issues.append("V1 missing: vector(n) used but V1 not in constraints_mapped")
    
    # V2: Si hay operador de distancia, debe estar declarado
    if re.search(r'(cosine_distance|l2_distance|inner_product)\(', content) and "V2" not in declared:
        issues.append("V2 missing: distance operator used but V2 not in constraints_mapped")
    
    # V3: Si hay parámetros de índice, debe estar justificado
    if re.search(r'hnsw\.(m|ef_search)|ivfflat\.lists', content) and "V3" not in declared:
        issues.append("V3 missing: index params configured but V3 not in constraints_mapped")
    
    # C4: Todas las queries vectoriales deben tener tenant_id
    if re.search(r'(SELECT|INSERT|UPDATE).*vector', content, re.I):
        if not re.search(r'WHERE.*tenant_id\s*=', content):
            issues.append("C4 missing: vector query lacks WHERE tenant_id = $1 clause")
    
    return issues

# Ejemplo de delegación por LANGUAGE LOCK
def delegar_por_dominio(query: str, context: dict) -> str:
    if contiene_operadores_vectoriales(query):
        # ✅ Permitido: estamos en dominio correcto
        return generar_query_pgvector(query, context)
    elif es_query_sql_pura(query):
        # 🔄 Delegar a sql/
        return delegar_a_dominio("06-PROGRAMMING/sql/", query, context)
    elif es_logica_aplicacion(query):
        # 🔄 Delegar a python/
        return delegar_a_dominio("06-PROGRAMMING/python/", query, context)
    else:
        raise ValueError("LANGUAGE LOCK: No matching domain for query pattern")
```

---

## 📋 INSTRUCCIONES DE INTEGRACIÓN (Actualizadas)

### Paso 1: Agregar al final del agente
Pegar los bloques de referencias justo antes de la sección `## Limitations` en:
- `06-PROGRAMMING/postgresql-pgvector/postgresql-pgvector-rag-master-agent.md`

### Paso 2: Actualizar el comportamiento del agente
En la sección `## Comportamiento del Agente` o `## Behavioral Traits`, agregar:

```markdown
| Trait | Implementación contractual |
|-------|---------------------------|
| **Consulta patrones antes de generar** | Antes de emitir query pgvector, el agente debe consultar la lista de patrones disponibles en `06-PROGRAMMING/postgresql-pgvector/` para asegurar coherencia con el repositorio |
| **Acceso dual** | Usar ruta canónica (`./06-PROGRAMMING/postgresql-pgvector/...`) para acceso local, o raw URL para acceso remoto si el archivo no existe localmente |
| **LANGUAGE LOCK inverso** | Este es el ÚNICO dominio donde operadores vectoriales (`<->`, `<#>`, `cosine_distance`, `vector(n)`) están permitidos. Si el usuario solicita queries SQL puras o lógica de aplicación, delegar a `sql/` o `python/` respectivamente |
| **Validación V1/V2/V3 obligatoria** | Antes de emitir cualquier artifact con operadores vectoriales, validar que: V1 está declarado si se usa `vector(n)`, V2 si se usa operador de distancia, V3 si se configuran parámetros de índice |
| **Enseña mientras genera** | Incluir comentarios explicativos sobre dimensiones, métrica de distancia y parámetros de índice en las queries generadas |
| **Valida constraints antes de emitir** | Ejecutar `validar_constraints_pgvector()` antes de emitir cualquier artifact para asegurar coherencia con `norms-matrix.json` |
| **Emite logs estructurados** | JSON a `stdout`, logs humanos a `stderr`, JSONL a `08-LOGS/validation/...` per V-INT-03 y V-LOG-02 |
```

### Paso 3: Validar con `verify-constraints.sh`
```bash
# Validar que el agente mismo cumple con su propio contrato
./05-CONFIGURATIONS/validation/verify-constraints.sh \
  --file 06-PROGRAMMING/postgresql-pgvector/postgresql-pgvector-rag-master-agent.md \
  --check-vector-dims --check-vector-metric --check-vector-index | jq
```

---

> 📌 **Nota final**: Este índice es Tier 1 (referencia contractual). Cualquier modificación debe pasar validación automática antes de merge.  
> 🇧🇷 *Documentação técnica completa disponível em*: `docs/pt-BR/programming/postgresql-pgvector/00-INDEX/README.md` (próxima entrega).
```

---

## ✅ Resumen de Cambios Aplicados

| Sección | Cambio | Justificación Contractual |
|---------|--------|-------------------------|
| `constraints_mapped` en frontmatter | Agregados `V1,V2,V3` | Único dominio donde constraints vectoriales están permitidos per `language-lock-protocol.md` |
| `version` | `2.0.0` → `3.1.0-SELECTIVE` | Semver: cambio menor por adición de agente master + alineación con dossier MANTIS |
| Nueva sección `🤖 Agente de Generación Disponible` | Tabla con referencia al `postgresql-pgvector-rag-master-agent` | Trazabilidad explícita de herramientas de generación per V-INT-01 |
| LANGUAGE LOCK rules | **Invertidas**: este dominio PERMITE operadores vectoriales, otros los prohíben | Coherencia con `language-lock-protocol.md`: aislamiento de responsabilidades por dominio |
| JSON TREE | Nuevo objeto `postgresql-pgvector-rag-master-agent` con `vector_constraints_applied: true` | Metadatos enriquecidos para IA navigation per AI-NAVIGATION-CONTRACT |
| RAW_URLS_INDEX | Agregada URL raw del agente master + doc pt-BR + referencias de delegación | Fuente de verdad para consulta sin inventar datos per SDD-COLLABORATIVE-GENERATION |
| GUÍA DE USO | Funciones `validar_constraints_pgvector()` y `delegar_por_dominio()` | Coherencia en resolución de rutas y enforcement de constraints vectoriales |
| INSTRUCCIONES DE INTEGRACIÓN | Agregado trait "Validación V1/V2/V3 obligatoria" | Alineación con V-INT-03 y V-LOG-02 + enforcement de constraints vectoriales |

---
