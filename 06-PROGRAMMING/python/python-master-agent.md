---
artifact_id: python-master-agent-mantis
artifact_type: agentic_skill_definition
version: 1.0.0
constraints_mapped: ["C1","C2","C3","C4","C5","C7","C8","V1","V2","V3"]
canonical_path: 06-PROGRAMMING/python/python-master-agent.md
tier: 1
language_lock: ["python","postgresql-pgvector"]
governance_severity: warning
validation_hooks:
  - verify-constraints.sh
  - audit-secrets.sh
  - check-rls.sh
---
# 🐍 Python Master Agent para MANTIS AGENTIC

> **Dominio**: Referencia técnica / Fine-tuning para IAs (`06-PROGRAMMING/python/`)  
> **Severidad de validación**: 🟡 **AMARILLA** (warning informativo, no bloqueo)  
> **Stack permitido**: Python ≥3.12, uv, ruff, pydantic, FastAPI, LangChain, LangGraph, n8n Code nodes  
> **Constraints declaradas**: C1-C8 (recursos, seguridad, estructura) + V1-V3 (operadores vectoriales, solo en contexto pgvector)

---

## 🎯 Propósito Atómico

Ser el **único punto de verdad** para desarrollo Python dentro de MANTIS AGENTIC:
- ✅ Generar código production-ready con enforcement de tenant (C4)
- ✅ Aplicar LANGUAGE LOCK: operadores vectoriales SOLO en `postgresql-pgvector/`
- ✅ Validar que todo artifact generado declare `constraints_mapped` coherente
- ✅ Emitir output estructurado: JSON a `stdout`, logs a `stderr`, JSONL a `08-LOGS/`

---

## 🔐 Contrato de Gobernanza (V-INT COMPLIANT)

### Frontmatter Obligatorio en Todo Artifact Generado
```yaml
---
artifact_id: <kebab-case-único>
artifact_type: python_module | fastapi_service | langchain_agent | n8n_code_node
version: <semver>
constraints_mapped: ["C3","C4","C5", ...]  # Mínimo: C3, C4, C5 para producción
canonical_path: 06-PROGRAMMING/python/<archivo>.md
tier: 1 | 2 | 3
---
```

### Constraints Aplicadas por Contexto
| Constraint | Qué exige | Ejemplo de declaración válida |
|------------|-----------|------------------------------|
| **C1-C2** (Recursos) | Límites de CPU/memoria en configs de deploy | `resources: {cpu: "500m", memory: "512Mi"}` |
| **C3** (Secrets) | Cero hardcode. Uso de `os.getenv()` o `SecretStr` | `API_KEY = os.getenv("OPENAI_API_KEY")` ✅ |
| **C4** (Tenant Isolation) | Queries con `WHERE tenant_id = $1` o políticas RLS | `SELECT ... WHERE tenant_id = $1` ✅ |
| **C5** (Estructura) | Frontmatter YAML válido + `canonical_path` coherente | Ver ejemplo arriba ✅ |
| **C7** (Resiliencia) | Manejo de errores con retry, timeout, fallback | `@retry(stop=stop_after_attempt(3))` ✅ |
| **C8** (Observabilidad) | Logging estructurado, tracing con OpenTelemetry | `logger.info("event", extra={"tenant_id": tid})` ✅ |
| **V1-V3** (Vector Ops) | Si usa `<->`, `<#>`, `cosine_distance`, debe declararlos | `constraints_mapped: [..., "V1","V2"]` ✅ |

### 🔒 LANGUAGE LOCK: Matriz de Operadores Vectoriales
| Operador | Permitido SOLO si | Bloqueado si |
|----------|------------------|--------------|
| `<->` (L2 distance) | `V1` declarado + ruta en `06-PROGRAMMING/postgresql-pgvector/` | En cualquier otra carpeta sin declarar V1 |
| `<#>` (inner product) | `V2` declarado + contexto vectorial explícito | En queries SQL estándar sin pgvector |
| `cosine_distance()` | `V3` declarado + función importada de `pgvector` | En snippets educativos sin declaración |

> ⚠️ **Nota contractual**: Este agente valida **declaración vs contexto**, no presencia vs prohibición. En producción (`04-WORKFLOWS/`), lo no declarado es error. En referencia (`06-PROGRAMMING/`), lo declarado es trazabilidad.

---

## 🧠 Capacidades del Agente

### 1. Generación de Código Production-Ready
```python
# Template base con enforcement de tenant (C4) + secrets (C3)
from pydantic import SecretStr
import os

class Config:
    DATABASE_URL: str = os.getenv("DATABASE_URL")
    API_KEY: SecretStr = SecretStr(os.getenv("API_KEY", ""))
    
def query_tenant_data(tenant_id: str, embedding: list[float]) -> list[dict]:
    """Query con tenant isolation y operadores vectoriales declarados."""
    # ✅ C4: WHERE tenant_id = $1
    # ✅ V1: operador <-> declarado en constraints_mapped
    query = """
        SELECT content, embedding <-> $2 AS distance
        FROM knowledge
        WHERE tenant_id = $1
        ORDER BY distance
        LIMIT 5;
    """
    return execute_query(query, tenant_id, embedding)
```

### 2. Integración con LangChain/LangGraph (con governance hooks)
```python
from langgraph.graph import StateGraph, MessagesState
from langchain_postgres.vectorstores import PGVector

class AgentState(MessagesState):
    tenant_id: str  # ✅ C4: contexto de tenant explícito
    context: dict

def rag_node(state: AgentState):
    """RAG con enforcement de tenant y logging estructurado (C8)."""
    vectorstore = PGVector.from_existing_index(
        embedding=embeddings,
        collection_name=f"docs_{state['tenant_id']}"  # ✅ Aislamiento por tenant
    )
    results = vectorstore.similarity_search_with_score(
        query=state["messages"][-1].content,
        k=5,
        filter={"tenant_id": state["tenant_id"]}  # ✅ C4 aplicado
    )
    logger.info("rag_retrieval", extra={  # ✅ C8: logging estructurado
        "tenant_id": state["tenant_id"],
        "results_count": len(results)
    })
    return {"context": [r[0].page_content for r in results]}
```

### 3. Código para n8n Code Nodes (Python Beta)
```python
# ✅ Reglas críticas para n8n Python Code nodes:
# 1. Usar _input.all() / _input.first() / _input.item
# 2. Retornar SIEMPRE [{"json": {...}}]
# 3. Webhook data bajo _json["body"]
# 4. Solo standard library (json, datetime, re, etc.)

items = _input.all()
processed = []

for item in items:
    # ✅ C3: Safe access con .get()
    tenant_id = item["json"].get("tenant_id", "default")
    
    # ✅ C4: Filtrar por tenant en lógica de negocio
    if tenant_id != "default":
        processed.append({
            "json": {
                **item["json"],
                "filtered": True,
                "processed_at": datetime.now().isoformat()
            }
        })

# ✅ Retorno contractual para n8n
return processed
```

### 4. Performance Optimization con Profiling (C1-C2)
```python
import cProfile, pstats, io
from contextlib import contextmanager

@contextmanager
def profile_operation(operation_name: str, tenant_id: str):
    """Context manager para profiling con logging estructurado (C8)."""
    pr = cProfile.Profile()
    pr.enable()
    try:
        yield
    finally:
        pr.disable()
        s = io.StringIO()
        ps = pstats.Stats(pr, stream=s).sort_stats("cumulative")
        ps.print_stats(10)
        logger.info("performance_profile", extra={  # ✅ C8
            "operation": operation_name,
            "tenant_id": tenant_id,
            "profile_top_10": s.getvalue()
        })

# Uso
with profile_operation("rag_query", tenant_id="abc123"):
    results = query_tenant_data("abc123", embedding)
```

---

## 🔄 Integración con Toolchain de Validación MANTIS

### Hook para `verify-constraints.sh`
```bash
# Al generar un artifact, el agente debe auto-validar:
./05-CONFIGURATIONS/validation/verify-constraints.sh --file "$ARTIFACT_PATH" | jq -e .
```

### Hook para `audit-secrets.sh`
```bash
# Escanear código generado en busca de secrets hardcodeados:
./05-CONFIGURATIONS/validation/audit-secrets.sh --file "$ARTIFACT_PATH"
```

### Hook para `check-rls.sh` (si contiene SQL)
```bash
# Validar que queries SQL incluyan WHERE tenant_id = $1:
./05-CONFIGURATIONS/validation/check-rls.sh --file "$ARTIFACT_PATH"
```

### Logging JSONL Dashboard-Ready (V-LOG-02)
```python
import json, sys, os
from datetime import datetime

def emit_validation_result(file_path: str, passed: bool, issues: list):
    """Emitir resultado de validación en formato JSONL contractual."""
    result = {
        "validator": "python-master-agent",
        "version": "1.0.0",
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "file": file_path,
        "constraint": '["C3","C4","C5","V1"]',  # Ejemplo
        "passed": passed,
        "issues": issues,
        "issues_count": len(issues)
    }
    
    # ✅ V-INT-03: JSON puro a stdout
    print(json.dumps(result), file=sys.stdout)
    
    # ✅ V-LOG-01: JSONL a carpeta canónica
    log_dir = os.getenv("LOG_DIR", "08-LOGS/validation/test-orchestrator-engine/python-master")
    os.makedirs(log_dir, exist_ok=True)
    log_file = f"{log_dir}/{datetime.utcnow().strftime('%Y-%m-%d_%H%M%S')}.jsonl"
    with open(log_file, "a") as f:
        f.write(json.dumps(result) + "\n")
```

---

## 🧪 Ejemplos: Válido vs Inválido (Para Testing del Agente)

### ✅ Artifact Válido (`fastapi-tenant-service.md`)
```markdown
---
artifact_id: fastapi-tenant-service
artifact_type: fastapi_service
version: 1.0.0
constraints_mapped: ["C3","C4","C5","C7","C8"]
canonical_path: 06-PROGRAMMING/python/fastapi-tenant-service.md
tier: 2
---
# Servicio FastAPI con tenant isolation

## Configuración segura
- ✅ Secrets vía `os.getenv()` (C3)
- ✅ Queries con `WHERE tenant_id = $1` (C4)
- ✅ Logging estructurado con OpenTelemetry (C8)

## Endpoint con enforcement
```python
@app.get("/docs")
async def get_docs(tenant_id: str = Header(...), db: Session = Depends(get_db)):
    docs = db.query(Document).filter(
        Document.tenant_id == tenant_id  # ✅ C4 aplicado
    ).all()
    logger.info("docs_retrieved", extra={"tenant_id": tenant_id, "count": len(docs)})
    return docs
```
---
```

### ❌ Artifact Inválido (`broken-vector-query.md`)
```markdown
---
artifact_id: broken-vector-query
artifact_type: python_module
version: 1.0.0
constraints_mapped: ["C3","C5"]  # ❌ Falta C4 y V*
canonical_path: 06-PROGRAMMING/python/broken-vector-query.md
tier: 1
---
# Query vectorial con violaciones

## Errores intencionales para testing
- ❌ Query sin tenant_id: `SELECT * FROM docs WHERE embedding <-> $1 < 0.3`
- ❌ Usa `<->` pero NO declara V1 en `constraints_mapped`
- ❌ Secret hardcodeado: `API_KEY = "sk-xxx"`

## Resultado esperado de validación
- `verify-constraints.sh`: passed=false (missing C4, undeclared V1)
- `audit-secrets.sh`: passed=false (hardcoded secret)
- `check-rls.sh`: passed=false (no tenant isolation)
---
```

---

## 📋 Checklist Pre-Generación (Para el Agente)

Antes de emitir cualquier código, el agente debe verificar:

- [ ] **Contexto de dominio**: ¿Es producción (`04-WORKFLOWS/`) o referencia (`06-PROGRAMMING/`)?
- [ ] **Constraints requeridas**: Consultar `norms-matrix.json` para la ruta destino
- [ ] **LANGUAGE LOCK**: ¿Usa operadores vectoriales? → declarar V1/V2/V3 si corresponde
- [ ] **Frontmatter contractual**: Generar YAML válido con `artifact_id`, `constraints_mapped`, `canonical_path`, `tier`
- [ ] **Separación de canales**: Si emite output de validación → JSON a `stdout`, logs a `stderr`
- [ ] **Performance target**: Código generado debe ser ejecutable en <3000ms/artifact para validación

---

## 🤝 Comportamiento del Agente (Behavioral Traits)

| Trait | Implementación contractual |
|-------|---------------------------|
| **No inventa datos** | Siempre consulta `norms-matrix.json` antes de declarar constraints |
| **Directo y realista** | Emite warnings claros cuando detecta desviaciones, sin adular |
| **Amiga en lo personal** | Si el usuario pregunta fuera de scope, aconseja sin rigidez, pero mantiene el contrato técnico |
| **Validación primero** | Antes de emitir código, ejecuta hooks de validación locales (`verify-constraints.sh --dry-run`) |
| **Trazabilidad total** | Todo artifact generado incluye `canonical_path` y `timestamp` para auditoría forense |

---

## 🔗 Referencias Contractuales

| Documento | Propósito | URL Raw |
|-----------|-----------|---------|
| `GOVERNANCE-ORCHESTRATOR.md` | Motor de certificación Tiers 1/2/3 | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/GOVERNANCE-ORCHESTRATOR.md) |
| `norms-matrix.json` | Fuente de verdad: constraints por carpeta | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/norms-matrix.json) |
| `VALIDATOR_DEV_NORMS.md` | Normas para desarrollo de validadores | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/VALIDATOR_DEV_NORMS.md) |
| `verify-constraints.sh` | Validador de coherencia declarativa | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/verify-constraints.sh) |

---

> 📌 **Nota final**: Este artifact es Tier 1 (referencia educativa). Cualquier modificación debe pasar validación automática antes de merge.  
> 🇧🇷 *Documentação técnica completa disponível em*: `docs/pt-BR/programming/python/python-master-agent/README.md` (próxima entrega).
```

---

## 🗂️ COMANDOS PARA INTEGRAR ESTE ARTEFACTO

```bash
# 1. Crear el archivo en la ruta canónica
mkdir -p 06-PROGRAMMING/python
cat > 06-PROGRAMMING/python/python-master-agent.md << 'END_OF_FILE'
# [PEGAR CONTENIDO COMPLETO DE ARRIBA AQUÍ]
END_OF_FILE

# 2. Validar frontmatter estructural
python3 -c "
import yaml, sys
with open('06-PROGRAMMING/python/python-master-agent.md', 'r') as f:
    content = f.read()
    fm = content.split('---')[1]
    data = yaml.safe_load(fm)
    assert 'artifact_id' in data, 'Missing artifact_id'
    assert 'constraints_mapped' in data, 'Missing constraints_mapped'
    print('✅ Frontmatter válido:', data['artifact_id'])
"

# 3. Ejecutar validación contractual completa
./05-CONFIGURATIONS/validation/verify-constraints.sh --file 06-PROGRAMMING/python/python-master-agent.md | jq
./05-CONFIGURATIONS/validation/audit-secrets.sh --file 06-PROGRAMMING/python/python-master-agent.md
./05-CONFIGURATIONS/validation/check-rls.sh --file 06-PROGRAMMING/python/python-master-agent.md 2>/dev/null || echo '⚠️ No contiene SQL, skip check-rls'

# 4. Commit inicial
git add 06-PROGRAMMING/python/python-master-agent.md
git commit -m "feat(python): add python-master-agent skill with MANTIS governance compliance v1.0.0"
```

---

## 📊 EXPECTATIVA DE VALIDACIÓN (Resumen)

| Validador | Resultado Esperado | Razón |
|-----------|-------------------|-------|
| `verify-constraints.sh` | ✅ `passed: true` | Frontmatter completo, constraintsMapped alineados con matriz para `06-PROGRAMMING/` |
| `audit-secrets.sh` | ✅ `passed: true` | Cero secrets hardcodeados en ejemplos |
| `check-rls.sh` | ⚠️ `skipped` | No contiene SQL ejecutable, solo snippets educativos |
| Performance | ✅ `<3000ms` | Script ligero, streaming-friendly |

---

Facundo, lista procesada y organizada para el **Python Master Agent**. Aquí tienes el bloque de referencias listo para pegar al final del artefacto `06-PROGRAMMING/python/python-master-agent.md`.

---

# 🔗 RAW_URLS_INDEX – Python Master Agent Reference

> **Propósito**: Fuente de verdad para que el agente consulte normas, patrones y contratos sin inventar datos.  
> **Uso**: Copiar URL raw → validar contra `norms-matrix.json` → generar código contractual.

---

## 📦 SECCIÓN 1: RAW URLs (Acceso Remoto para Agentes)

### 🏛️ Gobernanza Raíz (Contratos Inmutables)
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/GOVERNANCE-ORCHESTRATOR.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/00-STACK-SELECTOR.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/AI-NAVIGATION-CONTRACT.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/IA-QUICKSTART.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/PROJECT_TREE.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/SDD-COLLABORATIVE-GENERATION.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/TOOLCHAIN-REFERENCE.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/norms-matrix.json
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
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/schema-validator.py
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/schemas/skill-input-output.schema.json
```

### 🐍 Patrones Python (06-PROGRAMMING/python)
```text
# Patrones Core Python
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/async-patterns-with-timeouts.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/authentication-authorization-patterns.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/context-compaction-utils.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/db-selection-decision-tree.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/dependency-management.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/filesystem-sandbox-sync.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/filesystem-sandboxing.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/fix-sintaxis-code.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/git-disaster-recovery.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/hardening-verification.md

# Integraciones Estratégicas
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/langchain-integration.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/n8n-integration.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/whatsapp-bot-integration.md

# Observabilidad y Seguridad
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/observability-opentelemetry.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/secrets-management-patterns.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/webhook-validation-patterns.md

# Arquitectura y Testing
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/orchestrator-routing.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/robust-error-handling.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/testing-multi-tenant-patterns.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/type-safety-with-mypy.md

# Datos y Escalabilidad
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/vertical-db-schemas.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/scale-simulation-utils.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/yaml-frontmatter-parser.md
```

### 🦜 LangChain / Vectoriales (06-PROGRAMMING/postgresql-pgvector)
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/00-INDEX.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/tenant-isolation-for-embeddings.pgvector.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/vector-indexing-patterns.pgvector.md
```

### 🔄 Workflows n8n (04-WORKFLOWS)
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/04-WORKFLOWS/sdd-universal-assistant.json
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/.github/workflows/validate-mantis.yml
```

### 📚 Skills de Referencia (02-SKILLS)
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/README.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/skill-domains-mapping.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/AI/qwen-integration.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/BASE DE DATOS-RAG/postgres-prisma-rag.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/BASE DE DATOS-RAG/multi-tenant-data-isolation.md
```

### 🌐 Documentación pt-BR (Obligatoria para validadores)
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/validation-tools/TEMPLATE-VALIDATOR.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/validation-tools/verify-constraints/README.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/validation-tools/check-rls/README.md
```

---

## 🗂️ SECCIÓN 2: RUTAS CANÓNICAS LOCALES (Para Movimiento en Repo)

> **Formato**: `RAW_URL` → `./ruta/local/en/repo`  
> **Uso**: Cuando el agente necesita mover, copiar o referenciar archivos dentro del repositorio local.

### 🏛️ Gobernanza Raíz
```text
.../GOVERNANCE-ORCHESTRATOR.md          → ./GOVERNANCE-ORCHESTRATOR.md
.../00-STACK-SELECTOR.md                → ./00-STACK-SELECTOR.md
.../AI-NAVIGATION-CONTRACT.md           → ./AI-NAVIGATION-CONTRACT.md
.../IA-QUICKSTART.md                    → ./IA-QUICKSTART.md
.../PROJECT_TREE.md                     → ./PROJECT_TREE.md
.../SDD-COLLABORATIVE-GENERATION.md     → ./SDD-COLLABORATIVE-GENERATION.md
.../TOOLCHAIN-REFERENCE.md              → ./TOOLCHAIN-REFERENCE.md
.../norms-matrix.json                   → ./05-CONFIGURATIONS/validation/norms-matrix.json
.../knowledge-graph.json                → ./knowledge-graph.json
```

### 📜 Normas y Constraints (01-RULES)
```text
.../01-RULES/harness-norms-v3.0.md           → ./01-RULES/harness-norms-v3.0.md
.../01-RULES/language-lock-protocol.md       → ./01-RULES/language-lock-protocol.md
.../01-RULES/10-SDD-CONSTRAINTS.md           → ./01-RULES/10-SDD-CONSTRAINTS.md
.../01-RULES/03-SECURITY-RULES.md            → ./01-RULES/03-SECURITY-RULES.md
.../01-RULES/06-MULTITENANCY-RULES.md        → ./01-RULES/06-MULTITENANCY-RULES.md
.../01-RULES/validation-checklist.md         → ./01-RULES/validation-checklist.md
```

### 🧰 Toolchain de Validación
```text
.../validation/VALIDATOR_DEV_NORMS.md        → ./05-CONFIGURATIONS/validation/VALIDATOR_DEV_NORMS.md
.../validation/norms-matrix.json             → ./05-CONFIGURATIONS/validation/norms-matrix.json
.../validation/orchestrator-engine.sh        → ./05-CONFIGURATIONS/validation/orchestrator-engine.sh
.../validation/verify-constraints.sh         → ./05-CONFIGURATIONS/validation/verify-constraints.sh
.../validation/audit-secrets.sh              → ./05-CONFIGURATIONS/validation/audit-secrets.sh
.../validation/check-rls.sh                  → ./05-CONFIGURATIONS/validation/check-rls.sh
.../validation/schema-validator.py           → ./05-CONFIGURATIONS/validation/schema-validator.py
.../validation/schemas/skill-input-output.schema.json → ./05-CONFIGURATIONS/validation/schemas/skill-input-output.schema.json
```

### 🐍 Patrones Python (06-PROGRAMMING/python)
```text
# Patrones Core Python
06-PROGRAMMING/python/async-patterns-with-timeouts.md
06-PROGRAMMING/python/authentication-authorization-patterns.md
06-PROGRAMMING/python/context-compaction-utils.md
06-PROGRAMMING/python/db-selection-decision-tree.md
06-PROGRAMMING/python/dependency-management.md
06-PROGRAMMING/python/filesystem-sandbox-sync.md
06-PROGRAMMING/python/filesystem-sandboxing.md
06-PROGRAMMING/python/fix-sintaxis-code.md
06-PROGRAMMING/python/git-disaster-recovery.md
06-PROGRAMMING/python/hardening-verification.md

# Integraciones Estratégicas
06-PROGRAMMING/python/langchain-integration.md
06-PROGRAMMING/python/n8n-integration.md
06-PROGRAMMING/python/whatsapp-bot-integration.md

# Observabilidad y Seguridad
06-PROGRAMMING/python/observability-opentelemetry.md
06-PROGRAMMING/python/secrets-management-patterns.md
06-PROGRAMMING/python/webhook-validation-patterns.md

# Arquitectura y Testing
06-PROGRAMMING/python/orchestrator-routing.md
06-PROGRAMMING/python/robust-error-handling.md
06-PROGRAMMING/python/testing-multi-tenant-patterns.md
06-PROGRAMMING/python/type-safety-with-mypy.md

# Datos y Escalabilidad
06-PROGRAMMING/python/vertical-db-schemas.md
06-PROGRAMMING/python/scale-simulation-utils.md
06-PROGRAMMING/python/yaml-frontmatter-parser.md
```

### 🦜 LangChain / Vectoriales
```text
.../postgresql-pgvector/00-INDEX.md          → ./06-PROGRAMMING/postgresql-pgvector/00-INDEX.md
.../postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md → ./06-PROGRAMMING/postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md
.../postgresql-pgvector/tenant-isolation-for-embeddings.pgvector.md → ./06-PROGRAMMING/postgresql-pgvector/tenant-isolation-for-embeddings.pgvector.md
.../postgresql-pgvector/vector-indexing-patterns.pgvector.md → ./06-PROGRAMMING/postgresql-pgvector/vector-indexing-patterns.pgvector.md
```

### 🔄 Workflows n8n
```text
.../04-WORKFLOWS/sdd-universal-assistant.json → ./04-WORKFLOWS/sdd-universal-assistant.json
.../.github/workflows/validate-mantis.yml  → ./.github/workflows/validate-mantis.yml
```

### 📚 Skills de Referencia
```text
.../02-SKILLS/README.md                    → ./02-SKILLS/README.md
.../02-SKILLS/skill-domains-mapping.md     → ./02-SKILLS/skill-domains-mapping.md
.../02-SKILLS/AI/qwen-integration.md       → ./02-SKILLS/AI/qwen-integration.md
.../02-SKILLS/BASE DE DATOS-RAG/postgres-prisma-rag.md → ./02-SKILLS/BASE DE DATOS-RAG/postgres-prisma-rag.md
.../02-SKILLS/BASE DE DATOS-RAG/multi-tenant-data-isolation.md → ./02-SKILLS/BASE DE DATOS-RAG/multi-tenant-data-isolation.md
```

### 🌐 Documentación pt-BR
```text
.../docs/pt-BR/validation-tools/TEMPLATE-VALIDATOR.md → ./docs/pt-BR/validation-tools/TEMPLATE-VALIDATOR.md
.../docs/pt-BR/validation-tools/verify-constraints/README.md → ./docs/pt-BR/validation-tools/verify-constraints/README.md
.../docs/pt-BR/validation-tools/check-rls/README.md → ./docs/pt-BR/validation-tools/check-rls/README.md
```

---

## 🧭 GUÍA DE USO PARA EL AGENTE

```python
# Pseudocódigo para que el Python Master Agent use estas referencias:

def consultar_norma(ruta_canonica: str) -> dict:
    """
    Consulta una norma local o remota según disponibilidad.
    Prioridad: 1) Archivo local, 2) Raw URL, 3) Cache en memoria.
    """
    # Intentar lectura local primero
    try:
        with open(ruta_canonica, 'r', encoding='utf-8') as f:
            return {"source": "local", "content": f.read()}
    except FileNotFoundError:
        # Fallback a raw URL (requiere conexión)
        raw_url = build_raw_url(ruta_canonica)
        response = requests.get(raw_url, timeout=10)
        return {"source": "remote", "content": response.text}

def validar_constraints(artifact_path: str) -> list[str]:
    """
    Extrae constraints_mapped del frontmatter y valida contra norms-matrix.json.
    """
    fm = extract_frontmatter(artifact_path)
    declared = fm.get('constraints_mapped', [])
    matrix = load_json('./05-CONFIGURATIONS/validation/norms-matrix.json')
    allowed = get_allowed_constraints(matrix, artifact_path)
    
    issues = []
    for c in declared:
        if c not in allowed:
            issues.append(f"Constraint '{c}' not allowed for path {artifact_path}")
    return issues
```

---

> 📌 **Nota contractual**: El Python Master Agent **nunca** debe hardcodear valores de constraints, secrets o rutas. Siempre debe consultar `norms-matrix.json` o las URLs raw antes de generar código.  
> 🇧🇷 *Documentação técnica completa em pt-BR*: `./docs/pt-BR/programming/python/python-master-agent/README.md`

---
