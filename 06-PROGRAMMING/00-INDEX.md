---
artifact_id: "00-INDEX-programming"
artifact_type: "domain_index"
version: "3.1.0-SELECTIVE"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/00-INDEX.md --json"
canonical_path: "06-PROGRAMMING/00-INDEX.md"
---

# 🗂️ 06-PROGRAMMING – Índice Maestro Agregador

> **Propósito**: Punto único de navegación para todos los dominios de programación en MANTIS AGENTIC.  
> **Alcance**: 7 lenguajes, 182 artifacts (reales + planificados), LANGUAGE LOCK estricto, validación automatizada.  
> **Estado**: ✅ Contractual | 🔧 Roadmap de completitud en progreso | 🚫 Sin documentación pt-BR aún (deuda técnica pendiente)

---

## 1. 🎯 PROPÓSITO Y ALCANCE (Explicado para humanos)

Este índice sirve como **mapa de navegación** para:

| Usuario | Beneficio |
|---------|-----------|
| **Desarrollador humano** | Encontrar rápidamente el artifact correcto para su lenguaje y caso de uso, sin navegar carpetas manualmente |
| **Agente LLM (IA)** | Routing preciso de generación de código: saber qué dominio puede generar qué tipo de artifact |
| **Validador automatizado** | Ejecutar `orchestrator-engine.sh` con el `canonical_path` correcto para validar constraints |
| **Revisor de gobernanza** | Auditar que los artifacts generados respetan LANGUAGE LOCK y constraints C1-C8 + V1-V3 |

> 🔑 **Principio de continuidad prospectiva**: Este índice referencia tanto artifacts físicamente presentes como artifacts **planificados para generación en la iteración actual**, asegurando coherencia entre documentación y roadmap sin necesidad de regenerar índices dos veces.

---

## 2. 🔗 NAVEGACIÓN HUMANA – WIKILINKS CANÓNICOS

### 2.1 Acceso Rápido por Lenguaje

| Lenguaje | Índice Específico | Master Agent | Artifacts (Real+Planificado) |
|----------|------------------|--------------|-----------------------------|
| **SQL** | `[[sql/00-INDEX.md]]` | `[[sql/sql-master-agent.md]]` | 26 |
| **Python** | `[[python/00-INDEX.md]]` | `[[python/python-master-agent.md]]` | 28 |
| **PostgreSQL + pgvector** | `[[postgresql-pgvector/00-INDEX.md]]` | `[[postgresql-pgvector/postgresql-pgvector-rag-master-agent.md]]` | 22 ✅ Vectores |
| **JavaScript/TypeScript** | `[[javascript/00-INDEX.md]]` | `[[javascript/javascript-typescript-master-agent.md]]` | 28 |
| **Go** | `[[go/00-INDEX.md]]` | `[[go/go-master-agent.md]]` | 36 |
| **Bash** | `[[bash/00-INDEX.md]]` | `[[bash/bash-master-agent.md]]` | 32 |
| **YAML/JSON Schema** | `[[yaml-json-schema/00-INDEX.md]]` | `[[yaml-json-schema/yaml-json-schema-master-agent.md]]` | 10 |

### 2.2 Interacciones Críticas entre Lenguajes

#### Tabla de Dependencias Cruzadas

| Origen → Destino | Caso de Uso | Ejemplo de Artifact |
|-----------------|-------------|-------------------|
| `python/` → `sql/` | ORM genera queries SQL | `python-sqlalchemy-tenant-enforcement.py.md` llama a patrones de `crud-with-tenant-enforcement.sql.md` |
| `go/` → `postgresql-pgvector/` | Wrapper Go para búsqueda vectorial | `postgres-pgvector-integration.go.md` delega a `rag-query-with-tenant-enforcement.pgvector.md` |
| `javascript/` → `python/` | Frontend consume API de backend | `js-fetch-with-tenant-enforcement.ts.md` llama a endpoints generados en `python/` |
| `bash/` → `go/` | Script CLI ejecuta binario Go | `orchestrator-routing.md` invoca `orchestrator-engine.go.md` |
| `yaml-json-schema/` → `todos` | Definición de contratos compartidos | `environment-config-schema-patterns.yaml.md` valida configs en todos los dominios |

> ⚠️ **LANGUAGE LOCK RESUMEN**:
> - ✅ **Solo `postgresql-pgvector/`** puede usar: `<->`, `<#>`, `<=>`, `vector(n)`, `USING hnsw`, `V1/V2/V3`
> - 🚫 **Todos los demás dominios** deben delegar operaciones vectoriales a `postgresql-pgvector/`
> - 🔄 **Delegación obligatoria**: SQL puro → `sql/`, lógica Python → `python/`, microservicios → `go/`, frontend → `javascript/`, scripts → `bash/`, schemas → `yaml-json-schema/`

---

## 3. 🛡️ APLICACIÓN DE NORMAS POR LENGUAJE (C1-C8 + V1-V3)

### 3.1 Matriz de Constraints por Lenguaje

| Constraint | SQL | Python | pgvector | JS/TS | Go | Bash | YAML | Descripción |
|------------|-----|--------|----------|-------|----|------|------|-------------|
| **C1** Resource Limits | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | CPU/memoria/tiempo |
| **C2** Performance Budgets | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Latencia/throughput |
| **C3** Zero Hardcode Secrets | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Cero secrets en código |
| **C4** Tenant Isolation | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | `WHERE tenant_id=$1` |
| **C5** Structural Integrity | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Frontmatter válido |
| **C6** Auditability | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Logging estructurado |
| **C7** Resilience | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Manejo de errores |
| **C8** Observability | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Métricas/tracing |
| **V1** Vector Dimensions | 🚫 | 🚫 | ✅ | 🚫 | 🚫 | 🚫 | 🚫 | `vector(n)` explícito |
| **V2** Vector Metric | 🚫 | 🚫 | ✅ | 🚫 | 🚫 | 🚫 | 🚫 | `cosine_distance` documentada |
| **V3** Vector Index | 🚫 | 🚫 | ✅ | 🚫 | 🚫 | 🚫 | 🚫 | `hnsw.m` justificado |

### 3.2 Orden de Ejecución de Normas (Prioridad)

```text
🔴 BLOQUEANTES (fallar = rechazo inmediato):
1. C4 Tenant Isolation → Sin tenant_id, no hay artifact
2. C3 Zero Hardcode Secrets → Secretos expuestos = seguridad crítica
3. V1 Vector Dimensions (solo pgvector) → Dimensiones no declaradas = schema drift

🟡 VALIDACIÓN ESTRUCTURAL (warning si falla, pero permite corrección):
4. C5 Structural Integrity → Frontmatter mal formado
5. C7 Resilience → Manejo de errores ausente
6. C6 Auditability → Logging incompleto

🔵 OBSERVABILIDAD Y OPTIMIZACIÓN (mejora continua):
7. C8 Observability → Métricas faltantes
8. C1 Resource Limits → Límites no declarados
9. C2 Performance Budgets → Benchmarks ausentes
10. V2/V3 (solo pgvector) → Métrica/índice no documentado
```

---

## 4. 🧭 PROTOCOLO DE NAVEGACIÓN PARA IA (PASO A PASO)

```python
# Pseudocódigo: Routing de generación de artifacts por lenguaje
def generar_artifact(lenguaje: str, tipo: str, contexto: dict) -> str:
    # Paso 1: Validar LANGUAGE LOCK
    if tipo == "vector_query" and lenguaje != "postgresql-pgvector":
        return delegar_a("postgresql-pgvector/", tipo, contexto)
    
    # Paso 2: Consultar índice del dominio
    index_path = f"06-PROGRAMMING/{lenguaje}/00-INDEX.md"
    catalogo = cargar_catalogo(index_path)  # Desde JSON TREE
    
    # Paso 3: Verificar si artifact ya existe (evitar duplicación)
    if tipo in catalogo["artifacts_catalogue"]:
        return cargar_artifact_existente(tipo, lenguaje)
    
    # Paso 4: Generar nuevo artifact con constraints del dominio
    constraints = catalogo["constraints_allowed"]
    return agente_master[lenguaje].generar(tipo, contexto, constraints)

# Ejemplo de uso:
# generar_artifact("python", "crud_with_tenant", {"table": "docs", "fields": ["id", "content"]})
# → Consulta python/00-INDEX.md → Valida C1-C8 → Genera python-crud-patterns.py.md
```

---

## 5. 🚫 ANTI-PATRONES (DECISIONES PROHIBIDAS)

| Anti-patrón | Por qué está prohibido | Alternativa correcta |
|-------------|----------------------|---------------------|
| `SELECT * FROM docs WHERE id = 1` en cualquier lenguaje | 🚫 Falta `tenant_id` (viola C4) | `SELECT * FROM docs WHERE tenant_id = $1 AND id = $2` |
| `API_KEY = "sk-..."` hardcodeado en código | 🚫 Viola C3 (secrets expuestos) | Leer desde env var: `os.getenv("API_KEY")` |
| `CREATE EXTENSION vector;` en `sql/` o `python/` | 🚫 Viola LANGUAGE LOCK (vectores solo en pgvector) | Delegar a `postgresql-pgvector/pgvector-extension-setup.pgvector.md` |
| `vector(1536)` sin declarar V1 en frontmatter | 🚫 Viola V1 (dimensiones no documentadas) | Agregar `constraints_mapped: ["V1"]` en frontmatter |
| Generar artifact sin consultar `00-INDEX.md` primero | 🚫 Riesgo de duplicación o incoherencia | Siempre leer índice antes de generar |
| Usar `<->` en query SQL puro | 🚫 Operador vectorial en dominio no permitido | Delegar a `postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md` |

---

## 6. 📚 GLOSARIO PARA PRINCIPIANTES

| Término | Definición | Ejemplo |
|---------|-----------|---------|
| **Artifact** | Unidad atómica de código/documentación con frontmatter contractual | `crud-with-tenant-enforcement.sql.md` |
| **LANGUAGE LOCK** | Regla que restringe ciertos operadores/patrones a dominios específicos | `<->` solo en `postgresql-pgvector/` |
| **Constraint (C1-C8, V1-V3)** | Norma de gobernanza que debe cumplirse para validar un artifact | C4 = `WHERE tenant_id = $1` obligatorio |
| **Master Agent** | Agente LLM especializado en generar artifacts para un dominio | `sql-master-agent.md` |
| **Canonical Path** | Ruta única y verificable para un artifact, usada en validación | `06-PROGRAMMING/sql/crud-with-tenant-enforcement.sql.md` |
| **Delegación** | Redirigir generación de código al dominio correcto según LANGUAGE LOCK | Query vectorial → `postgresql-pgvector/` |
| **Frontmatter Contractual** | Bloque YAML inicial con metadatos obligatorios para validación | `artifact_id`, `constraints_mapped`, `canonical_path` |

---

## 7. 🔗 REFERENCIAS CANÓNICAS (WIKILINKS)

### Gobernanza Raíz
```text
[[GOVERNANCE-ORCHESTRATOR.md]] ← Motor de certificación de artifacts
[[00-STACK-SELECTOR.md]] ← Selector de stack tecnológico por caso de uso
[[AI-NAVIGATION-CONTRACT.md]] ← Contrato de navegación para agentes LLM
[[SDD-COLLABORATIVE-GENERATION.md]] ← Protocolo de generación colaborativa
```

### Toolchain de Validación
```text
[[05-CONFIGURATIONS/validation/orchestrator-engine.sh]] ← Validador principal
[[05-CONFIGURATIONS/validation/verify-constraints.sh]] ← Hook de constraints C1-C8 + V1-V3
[[05-CONFIGURATIONS/validation/audit-secrets.sh]] ← Detección de secrets hardcodeados
[[05-CONFIGURATIONS/validation/check-rls.sh]] ← Validación de aislamiento multi-tenant
[[05-CONFIGURATIONS/validation/vector-schema-validator.py]] ← Validación de constraints vectoriales (V1-V3)
```

### Normas y Constraints
```text
[[01-RULES/harness-norms-v3.0.md]] ← Contrato base de normas
[[01-RULES/language-lock-protocol.md]] ← Reglas de aislamiento por dominio
[[01-RULES/10-SDD-CONSTRAINTS.md]] ← Definiciones técnicas de C1-C8 + V1-V3
[[01-RULES/06-MULTITENANCY-RULES.md]] ← Reglas de aislamiento multi-tenant
```

### Índices por Dominio (Wikilinks directos)
```text
[[sql/00-INDEX.md]] • [[python/00-INDEX.md]] • [[postgresql-pgvector/00-INDEX.md]]
[[javascript/00-INDEX.md]] • [[go/00-INDEX.md]] • [[bash/00-INDEX.md]] • [[yaml-json-schema/00-INDEX.md]]
```

---

## 8. 🧪 SANDBOX DE PRUEBA (OPCIONAL)

```bash
# 🔍 Validar un artifact individual
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/sql/crud-with-tenant-enforcement.sql.md \
  --json | jq '.passed, .issues'

# 📊 Validar todo un dominio
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/python/ \
  --json 2>/dev/null | jq '.summary'

# 🔐 Verificar LANGUAGE LOCK (cero vectores en dominios no permitidos)
for domain in sql python javascript go bash yaml-json-schema; do
  grep -rE '<->|<#>|<=>|vector\(' 06-PROGRAMMING/$domain/ --include="*.md" && \
  echo "❌ VIOLATION in $domain" || echo "✅ OK: $domain"
done

# 🧭 Probar routing de IA (pseudocódigo ejecutable)
python3 -c "
import json, sys
sys.path.append('05-CONFIGURATIONS/validation')
from orchestrator_utils import load_index
index = load_index('06-PROGRAMMING/00-INDEX.md')
print(f'Dominios disponibles: {[d[\"domain\"] for d in index[\"domains\"]]}')
print(f'Vectores permitidos en: {[d[\"domain\"] for d in index[\"domains\"] if d[\"vector_ops_allowed\"]]}')
"
```

---

## 9. 📦 METADATOS DE EXPANSIÓN (PARA FUTURAS VERSIONES)

```json
{
  "expansion_roadmap": {
    "v3.2.0": {
      "nuevos_dominios": ["rust/", "java/", "csharp/"],
      "nuevos_constraints": ["C9: Cost Awareness", "C10: Carbon Footprint"],
      "nuevos_hooks": ["carbon-footprint-check.sh", "cost-estimator.py"]
    },
    "v3.3.0": {
      "integraciones_externas": ["GitHub Actions templates", "GitLab CI snippets"],
      "soporte_multilenguaje_docs": ["pt-BR", "en", "es"]
    }
  },
  "deuda_tecnica_pendiente": {
    "documentacion_pt_br": {
      "estado": "pendiente",
      "artifacts_afectados": 182,
      "prioridad": "media",
      "estimacion_horas": 45
    },
    "validacion_cruzada_filesystem": {
      "estado": "en progreso",
      "descripcion": "Script para verificar que cada wikilink en índices apunta a archivo físico existente",
      "prioridad": "alta"
    }
  },
  "metricas_actuales": {
    "total_artifacts_catalogados": 182,
    "artifacts_fisicamente_presentes": 141,
    "artifacts_planificados_iteracion_actual": 41,
    "coverage_indices": "100%",
    "language_lock_violations_detectadas": 0
  }
}
```

---

## 🤖 JSON TREE – Metadatos para IA Navigation (Catálogo Completo)

```json
{
 "index_metadata": {
 "artifact_id": "00-INDEX-programming",
 "artifact_type": "domain_index",
 "version": "3.1.0-SELECTIVE",
 "canonical_path": "06-PROGRAMMING/00-INDEX.md",
 "generated_timestamp": "2026-01-27T00:00:00Z",
 "total_domains": 7,
 "total_artifacts_catalogued": 182,
 "language_lock_enforced": true,
 "generation_mode": "prospective_with_roadmap"
 },
 "domains": [
 {
 "domain": "sql",
 "path": "06-PROGRAMMING/sql/",
 "master_agent": "sql-master-agent.md",
 "artifact_count": 26,
 "constraints_allowed": ["C1","C2","C3","C4","C5","C6","C7","C8"],
 "vector_ops_allowed": false,
 "file_pattern": "*.sql.md",
 "validation_hooks": ["verify-constraints.sh", "audit-secrets.sh", "check-rls.sh"],
 "artifacts_catalogue": [
 "sql-master-agent.md",
 "hardening-verification.sql.md",
 "fix-sintaxis-code.sql.md",
 "robust-error-handling.sql.md",
 "row-level-security-policies.sql.md",
 "tenant-context-injection.sql.md",
 "column-encryption-patterns.sql.md",
 "audit-logging-triggers.sql.md",
 "migration-versioning-patterns.sql.md",
 "schema-diff-validation.sql.md",
 "rollback-automation-patterns.sql.md",
 "partitioning-strategies.sql.md",
 "backup-restore-tenant-scoped.sql.md",
 "crud-with-tenant-enforcement.sql.md",
 "join-patterns-rls-aware.sql.md",
 "aggregation-multi-tenant-safe.sql.md",
 "query-explanation-templates.sql.md",
 "nl-to-sql-patterns.sql.md",
 "mcp-sql-tool-definitions.json.md",
 "ia-query-validation-gate.sql.md",
 "context-injection-for-ia.sql.md",
 "audit-trail-ia-generated.sql.md",
 "permission-scoping-for-ia.sql.md",
 "unit-test-patterns-for-sql.sql.md",
 "integration-test-fixtures.sql.md",
 "constraint-validation-tests.sql.md"
 ]
 },
 {
 "domain": "python",
 "path": "06-PROGRAMMING/python/",
 "master_agent": "python-master-agent.md",
 "artifact_count": 28,
 "constraints_allowed": ["C1","C2","C3","C4","C5","C6","C7","C8"],
 "vector_ops_allowed": false,
 "file_pattern": "*.py.md",
 "validation_hooks": ["verify-constraints.sh", "audit-secrets.sh", "pylint-validator.py"],
 "artifacts_catalogue": [
 "python-master-agent.md",
 "async-patterns-with-timeouts.md",
 "authentication-authorization-patterns.md",
 "context-compaction-utils.md",
 "db-selection-decision-tree.md",
 "dependency-management.md",
 "filesystem-sandbox-sync.md",
 "filesystem-sandboxing.md",
 "fix-sintaxis-code.md",
 "git-disaster-recovery.md",
 "hardening-verification.md",
 "langchain-integration.md",
 "n8n-integration.md",
 "observability-opentelemetry.md",
 "orchestrator-routing.md",
 "robust-error-handling.md",
 "scale-simulation-utils.md",
 "secrets-management-patterns.md",
 "testing-multi-tenant-patterns.md",
 "type-safety-with-mypy.md",
 "vertical-db-schemas.md",
 "webhook-validation-patterns.md",
 "whatsapp-bot-integration.md",
 "yaml-frontmatter-parser.md",
 "python-hardening-verification.py.md",
 "python-linter-integration.py.md",
 "python-exception-handling.py.md",
 "python-tenant-context-manager.py.md"
 ]
 },
 {
 "domain": "postgresql-pgvector",
 "path": "06-PROGRAMMING/postgresql-pgvector/",
 "master_agent": "postgresql-pgvector-rag-master-agent.md",
 "artifact_count": 22,
 "constraints_allowed": ["C1","C2","C3","C4","C5","C6","C7","C8","V1","V2","V3"],
 "vector_ops_allowed": true,
 "file_pattern": "*.pgvector.md",
 "validation_hooks": ["verify-constraints.sh", "audit-secrets.sh", "check-rls.sh", "vector-schema-validator.py"],
 "artifacts_catalogue": [
 "postgresql-pgvector-rag-master-agent.md",
 "fix-sintaxis-code.pgvector.md",
 "hardening-verification.pgvector.md",
 "hybrid-search-rls-aware.pgvector.md",
 "migration-patterns-for-vector-schemas.pgvector.md",
 "nl-to-vector-query-patterns.pgvector.md",
 "partitioning-strategies-for-high-dim.pgvector.md",
 "rag-query-with-tenant-enforcement.pgvector.md",
 "similarity-explanation-templates.pgvector.md",
 "tenant-isolation-for-embeddings.pgvector.md",
 "vector-indexing-patterns.pgvector.md",
 "pgvector-extension-setup.pgvector.md",
 "embedding-dimension-selection.pgvector.md",
 "vector-index-strategy-comparison.pgvector.md",
 "vector-metadata-tenant-scoping.pgvector.md",
 "embedding-generation-pipeline.pgvector.md",
 "embedding-batch-insert-optimization.pgvector.md",
 "embedding-update-strategies.pgvector.md",
 "hybrid-search-scalar-vector.pgvector.md",
 "reranking-post-filtering.pgvector.md",
 "query-expansion-for-rag.pgvector.md",
 "multi-vector-representation.pgvector.md"
 ]
 },
 {
 "domain": "javascript",
 "path": "06-PROGRAMMING/javascript/",
 "master_agent": "javascript-typescript-master-agent.md",
 "artifact_count": 28,
 "constraints_allowed": ["C1","C2","C3","C4","C5","C6","C7","C8"],
 "vector_ops_allowed": false,
 "file_pattern": "*.{js,ts}.md",
 "validation_hooks": ["verify-constraints.sh", "audit-secrets.sh", "eslint-validator.js", "tsc-strict-check.sh"],
 "artifacts_catalogue": [
 "javascript-typescript-master-agent.md",
 "async-patterns-with-timeouts.ts.md",
 "authentication-authorization-patterns.ts.md",
 "context-compaction-utils.ts.md",
 "context-isolation-patterns.ts.md",
 "db-selection-decision-tree.ts.md",
 "dependency-management.ts.md",
 "filesystem-sandbox-sync.ts.md",
 "filesystem-sandboxing.ts.md",
 "fix-sintaxis-code.ts.md",
 "git-disaster-recovery.ts.md",
 "hardening-verification.ts.md",
 "langchainjs-integration.ts.md",
 "n8n-webhook-handler.ts.md",
 "observability-opentelemetry.ts.md",
 "orchestrator-routing.ts.md",
 "robust-error-handling.ts.md",
 "scale-simulation-utils.ts.md",
 "secrets-management-patterns.ts.md",
 "testing-multi-tenant-patterns.ts.md",
 "type-safety-with-typescript.ts.md",
 "vertical-db-schemas.ts.md",
 "webhook-validation-patterns.ts.md",
 "whatsapp-bot-integration.ts.md",
 "yaml-frontmatter-parser.ts.md",
 "js-hardening-verification.js.md",
 "ts-strict-mode-enforcement.ts.md",
 "js-error-boundaries-patterns.js.md"
 ]
 },
 {
 "domain": "go",
 "path": "06-PROGRAMMING/go/",
 "master_agent": "go-master-agent.md",
 "artifact_count": 36,
 "constraints_allowed": ["C1","C2","C3","C4","C5","C6","C7","C8"],
 "vector_ops_allowed": false,
 "file_pattern": "*.go.md",
 "validation_hooks": ["verify-constraints.sh", "audit-secrets.sh", "go-vet-validator.sh", "golangci-lint-check.sh"],
 "artifacts_catalogue": [
 "go-master-agent.md",
 "api-client-management.go.md",
 "async-patterns-with-timeouts.go.md",
 "authentication-authorization-patterns.go.md",
 "context-compaction-utils.go.md",
 "db-selection-decision-tree.go.md",
 "dependency-management.go.md",
 "error-handling-c7.go.md",
 "filesystem-sandbox-sync.go.md",
 "filesystem-sandboxing.go.md",
 "git-disaster-recovery.go.md",
 "hardening-verification.go.md",
 "langchain-style-integration.go.md",
 "mcp-server-patterns.go.md",
 "microservices-tenant-isolation.go.md",
 "mysql-mariadb-optimization.go.md",
 "n8n-webhook-handler.go.md",
 "observability-opentelemetry.go.md",
 "orchestrator-engine.go.md",
 "postgres-pgvector-integration.go.md",
 "prisma-orm-patterns.go.md",
 "rag-ingestion-pipeline.go.md",
 "resource-limits-c1-c2.go.md",
 "saas-deployment-zip-auto.go.md",
 "scale-simulation-utils.go.md",
 "secrets-management-c3.go.md",
 "sql-core-patterns.go.md",
 "static-dashboard-generator.go.md",
 "structured-logging-c8.go.md",
 "supabase-rag-integration.go.md",
 "telegram-bot-integration.go.md",
 "testing-multi-tenant-patterns.go.md",
 "type-safety-with-generics.go.md",
 "webhook-validation-patterns.go.md",
 "whatsapp-bot-integration.go.md",
 "yaml-frontmatter-parser.go.md"
 ]
 },
 {
 "domain": "bash",
 "path": "06-PROGRAMMING/bash/",
 "master_agent": "bash-master-agent.md",
 "artifact_count": 32,
 "constraints_allowed": ["C1","C2","C3","C4","C5","C6","C7","C8"],
 "vector_ops_allowed": false,
 "file_pattern": "*.sh.md",
 "validation_hooks": ["verify-constraints.sh", "audit-secrets.sh", "shellcheck-validator.sh", "bash-syntax-check.sh"],
 "artifacts_catalogue": [
 "bash-master-agent.md",
 "context-compaction-utils.md",
 "filesystem-sandbox-sync.md",
 "filesystem-sandboxing.md",
 "fix-sintaxis-code.md",
 "git-disaster-recovery.md",
 "hardening-verification.md",
 "orchestrator-routing.md",
 "robust-error-handling.md",
 "scale-simulation-utils.md",
 "yaml-frontmatter-parser.md",
 "bash-hardening-verification.sh.md",
 "safe-variable-expansion.sh.md",
 "error-handling-traps.sh.md",
 "tenant-context-propagation.sh.md",
 "filesystem-isolation-per-tenant.sh.md",
 "secrets-in-shell-c3.sh.md",
 "command-audit-logging-c8.sh.md",
 "timeout-and-retry-patterns.sh.md",
 "resource-limits-ulimit-cgroups.sh.md",
 "parallel-execution-safe.sh.md",
 "orchestrator-engine-bash-port.sh.md",
 "safe-file-operations.sh.md",
 "json-processing-with-jq.sh.md",
 "yaml-processing-with-yq.sh.md",
 "csv-safe-parsing.sh.md",
 "curl-with-tenant-headers.sh.md",
 "webhook-handler-secure.sh.md",
 "git-operations-tenant-scoped.sh.md",
 "docker-cli-tenant-isolation.sh.md",
 "verify-constraints-hook.sh.md",
 "audit-secrets-hook.sh.md"
 ]
 },
 {
 "domain": "yaml-json-schema",
 "path": "06-PROGRAMMING/yaml-json-schema/",
 "master_agent": "yaml-json-schema-master-agent.md",
 "artifact_count": 10,
 "constraints_allowed": ["C1","C2","C3","C4","C5","C6","C7","C8"],
 "vector_ops_allowed": false,
 "file_pattern": "*.yaml.md",
 "validation_hooks": ["verify-constraints.sh", "audit-secrets.sh", "schema-validator.py"],
 "artifacts_catalogue": [
 "yaml-json-schema-master-agent.md",
 "dynamic-schema-generation.yaml.md",
 "environment-config-schema-patterns.yaml.md",
 "json-pointer-jq-integration.yaml.md",
 "json-schema-draft7-draft2020-migration.yaml.md",
 "multi-tenant-schema-isolation.yaml.md",
 "schema-testing-with-promptfoo.yaml.md",
 "schema-validation-patterns.yaml.md",
 "schema-versioning-strategies.yaml.md",
 "yaml-security-hardening.yaml.md"
 ]
 }
 ],
 "language_lock_enforcement": {
 "vector_domain": "postgresql-pgvector/",
 "prohibited_in_others": ["<->", "<#>", "<=>", "vector\\(", "cosine_distance", "l2_distance", "USING\\s+(hnsw|ivfflat)", "CREATE EXTENSION vector"],
 "delegation_matrix": {
 "sql_pure": "06-PROGRAMMING/sql/",
 "python_logic": "06-PROGRAMMING/python/",
 "go_microservices": "06-PROGRAMMING/go/",
 "js_frontend": "06-PROGRAMMING/javascript/",
 "bash_automation": "06-PROGRAMMING/bash/",
 "yaml_config": "06-PROGRAMMING/yaml-json-schema/",
 "vector_rag": "06-PROGRAMMING/postgresql-pgvector/"
 }
 },
 "ai_navigation_hints": {
 "for_routing": "Use 'domains[].vector_ops_allowed' to determine if vector queries can be generated in a domain",
 "for_validation": "Consult 'validation_hooks' per domain to run appropriate constraint checks",
 "for_generation": "Reference 'artifacts_catalogue' to avoid duplicating existing patterns; delegate per 'delegation_matrix'",
 "for_debugging": "If artifact not found in filesystem but listed in catalogue, check generation roadmap status"
 }
}
```

---

> 📌 **Nota final**: Este índice es Tier 1 (referencia contractual). Cualquier modificación debe pasar validación automática antes de merge.  
> 🇧🇷 *Documentação pt-BR pendiente*: Se completará tras la generación de artifacts planificados en esta iteración.
```

---
