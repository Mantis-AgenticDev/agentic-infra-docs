---
artifact_id: langchain-langraph-workflows-domain
artifact_type: domain_readme
version: 1.0.0
constraints_mapped: ["C3","C4","C5","V1","V2","V3"]
canonical_path: 04-WORKFLOWS/langchain-langraph/README.md
tier: 2
language_lock: ["python","javascript","postgresql-pgvector"]
governance_severity: error
---
# 🦜🔗 LangChain / LangGraph Workflows

> **Dominio**: Producción (Tier 2/3)  
> **Severidad de validación**: 🔴 **ROJA** (bloqueo inmediato en CI/CD)  
> **Stack permitido**: Python ≥3.10, JavaScript/TypeScript ≥18, PostgreSQL + pgvector  
> **Constraints requeridas**: `C3`, `C4`, `C5` + `V1`/`V2`/`V3` si usa operadores vectoriales

---

## 🎯 Propósito del Dominio

Almacenar **workflows exportados o definiciones de agentes** basados en LangChain/LangGraph que estén listos para:
- ✅ Integración en pipelines de producción (`04-WORKFLOWS/`)
- ✅ Certificación como Tier 2 (código validado) o Tier 3 (paquete desplegable)
- ✅ Despliegue automatizado vía `packager-assisted.sh` + Terraform

Este dominio **NO** es para:
- ❌ Tutoriales educativos (usar `02-SKILLS/AI/`)
- ❌ Experimentación sin garantías (usar `09-TEST-SANDBOX/qwen/`)
- ❌ Patrones genéricos de código (usar `06-PROGRAMMING/python/`)

---

## 🔐 Reglas de Gobernanza (Aplicadas por `verify-constraints.sh`)

Cualquier artifact en esta carpeta debe cumplir estrictamente:

### ✅ Frontmatter Obligatorio (C5)
```yaml
---
artifact_id: <identificador-único-kebab-case>
artifact_type: langgraph_workflow | langchain_agent | rag_pipeline
version: <semver>
constraints_mapped: ["C3","C4","C5", ...]  # Mínimo: C3, C4, C5
canonical_path: 04-WORKFLOWS/langchain-langraph/<archivo>.md
tier: 2 | 3
---
```

### ✅ Constraints Declarativas
| Constraint | Qué exige | Ejemplo de declaración válida |
|------------|-----------|------------------------------|
| **C3** (Secrets) | Cero credenciales hardcodeadas. Uso de `${VAR}` o `SecretStr` | `os.getenv("OPENAI_API_KEY")` ✅ / `"sk-xxx"` ❌ |
| **C4** (Tenant Isolation) | Queries con `WHERE tenant_id = $1` o políticas RLS | `SELECT ... WHERE tenant_id = $1 AND ...` ✅ |
| **C5** (Estructura) | Frontmatter YAML válido + `canonical_path` coherente | Ver ejemplo arriba ✅ |
| **V1/V2/V3** (Vector Ops) | Si usa `<->`, `<#>`, `cosine_distance`, debe declararlos | `constraints_mapped: [..., "V1","V2"]` ✅ |

### 🔒 LANGUAGE LOCK: Operadores Vectoriales
| Operador | Permitido SOLO si | Bloqueado si |
|----------|------------------|--------------|
| `<->` (L2 distance) | `V1` declarado + ruta en `allowed_paths` de `norms-matrix.json` | Sin declarar V1 o fuera de `postgresql-pgvector/` |
| `<#>` (inner product) | `V2` declarado + contexto vectorial explícito | En queries SQL estándar sin pgvector |
| `cosine_distance()` | `V3` declarado + función importada de `pgvector` | En snippets educativos sin declaración |

> ⚠️ **Nota contractual**: `verify-constraints.sh` valida **declaración vs contexto**, no presencia vs prohibición. En producción (`04-WORKFLOWS/`), lo no declarado es error. En referencia (`02-SKILLS/`), lo declarado es trazabilidad.

---

## 📁 Estructura Canónica Sugerida

```
04-WORKFLOWS/langchain-langraph/
├── .gitkeep                                  # Tracking de carpeta vacía
├── README.md                                 # Este archivo
├── agent-whatsapp-rag.json                   # Workflow exportado de LangGraph
├── agent-whatsapp-rag.json.md                # Frontmatter + documentación del workflow
├── rag-pipeline-multi-tenant.py.md           # Patrón Python con enforcement de tenant
├── test-validator/                           # Fixtures de prueba (excluir de prod)
│   ├── .gitkeep
│   ├── workflow-valid.md                     # ✅ Esperado: passed=true, exit 0
│   └── workflow-invalid.md                   # ❌ Esperado: passed=false, exit 1
└── templates/
    ├── langgraph-agent-template.md           # Plantilla base para nuevos agentes
    └── rag-query-template.sql.md             # Query RAG con tenant enforcement
```

---

## 🧪 Ejemplos: Válido vs Inválido

### ✅ Workflow Válido (`agent-whatsapp-rag.json.md`)
```markdown
---
artifact_id: whatsapp-rag-agent-langgraph
artifact_type: langgraph_workflow
version: 1.0.0
constraints_mapped: ["C3","C4","C5","V1","V2"]
canonical_path: 04-WORKFLOWS/langchain-langraph/agent-whatsapp-rag.json.md
tier: 2
---
# Agente RAG para WhatsApp con LangGraph

## Configuración segura
- ✅ Secrets vía `os.getenv()` (C3)
- ✅ Queries con `WHERE tenant_id = $1` (C4)
- ✅ Operadores vectoriales declarados (V1,V2)

## Query vectorial con enforcement
```python
from langchain_postgres.vectorstores import PGVector

results = PGVector.similarity_search_with_score(
    query=embedding,
    k=5,
    filter={"tenant_id": tenant_id}  # ✅ Tenant isolation aplicado
)
```

## SQL subyacente (generado por pgvector)
```sql
SELECT content, embedding <-> $1 AS distance
FROM knowledge
WHERE tenant_id = $2  -- ✅ C4 cumplido
ORDER BY distance
LIMIT 5;
```
---
```

### ❌ Workflow Inválido (`workflow-invalid.md`)
```markdown
---
artifact_id: whatsapp-rag-agent-broken
artifact_type: langgraph_workflow
version: 1.0.0
constraints_mapped: ["C3","C5"]  # ❌ Falta C4 y V*
canonical_path: 04-WORKFLOWS/langchain-langraph/workflow-invalid.md
tier: 2
---
# Agente con violaciones críticas

## Errores intencionales para testing
- ❌ Query sin tenant_id: `SELECT * FROM docs WHERE embedding <-> $1 < 0.3`
- ❌ Secret hardcodeado: `OPENAI_API_KEY = "sk-xxx"`
- ❌ Usa `<->` pero NO declara V1/V2 en `constraints_mapped`

## Resultado esperado de validación
- `passed: false`
- `issues_count: 3`
- `exit code: 1` (bloqueo en CI/CD)
---
```

---

## 🔄 Integración con Toolchain de Validación

### Pipeline CI/CD (`.github/workflows/validate-mantis.yml`)
```yaml
- name: Validate langchain-langraph artifacts
  run: |
    for file in 04-WORKFLOWS/langchain-langraph/*.md; do
      ./05-CONFIGURATIONS/validation/verify-constraints.sh --file "$file" | jq -e .
    done
```

### Orchestrator Engine (`orchestrator-engine.sh`)
```bash
# Consulta norms-matrix.json para esta ruta
MATRIX_RULES=$(jq -r '.["04-WORKFLOWS/langchain-langraph/"]' norms-matrix.json)

# Ejecuta validadores en orden contractual
./verify-constraints.sh --file "$ARTIFACT"  # C5 + LANGUAGE LOCK
./audit-secrets.sh --file "$ARTIFACT"       # C3
./check-rls.sh --file "$ARTIFACT"           # C4 (si contiene SQL)
```

### Logs Dashboard-Ready (V-LOG-02)
Cada ejecución genera una entrada JSONL en:
```
08-LOGS/validation/test-orchestrator-engine/verify-constraints/YYYY-MM-DD_HHMMSS.jsonl
```

Ejemplo de entrada:
```json
{
  "validator":"verify-constraints.sh",
  "version":"3.0.0-CONTRACTUAL",
  "timestamp":"2026-01-22T15:45:00Z",
  "file":"04-WORKFLOWS/langchain-langraph/agent-whatsapp-rag.json.md",
  "constraint":"[\"C3\",\"C4\",\"C5\",\"V1\",\"V2\"]",
  "passed":true,
  "issues":[],
  "issues_count":0,
  "performance_ms":187,
  "performance_ok":true
}
```

---

## 🚀 Checklist Pre-Merge (Obligatorio)

Antes de abrir un PR con cambios en este dominio:

- [ ] Frontmatter YAML válido y completo (usa `yamllint` o `python -c "import yaml; yaml.safe_load(open('file.md'))"`)
- [ ] `constraints_mapped` incluye al menos `["C3","C4","C5"]`
- [ ] Si usa vectores: declara `V1`/`V2`/`V3` según operadores presentes
- [ ] Cero secrets hardcodeados (ejecuta `./audit-secrets.sh --file <archivo>`)
- [ ] Queries SQL/ORM incluyen `tenant_id` en filtros (ejecuta `./check-rls.sh --file <archivo>`)
- [ ] `canonical_path` coincide con la ubicación real del archivo
- [ ] `tier` es coherente: 2 para código validado, 3 para paquete desplegable
- [ ] Ejecuta `./verify-constraints.sh --file <archivo>` y verifica `passed: true`

---

## 🤝 Contribución y Mantenimiento

### Para agregar un nuevo workflow:
1. Copia `templates/langgraph-agent-template.md`
2. Completa frontmatter con tus constraints reales
3. Implementa lógica respetando C3/C4/C5 + LANGUAGE LOCK
4. Ejecuta validadores locales antes de commit
5. Abre PR con descripción clara de cambios y constraints aplicadas

### Para reportar un falso positivo:
1. Verifica que `constraints_mapped` esté correctamente declarado
2. Revisa `norms-matrix.json` para confirmar reglas de la ruta
3. Si persiste, abre issue con:
   - Output completo de `verify-constraints.sh --file <archivo>`
   - Fragmento relevante del artifact
   - Expectativa vs comportamiento observado

---

## 🔗 Referencias Contractuales

| Documento | Propósito | URL Raw |
|-----------|-----------|---------|
| `GOVERNANCE-ORCHESTRATOR.md` | Motor de certificación Tiers 1/2/3 | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/GOVERNANCE-ORCHESTRATOR.md) |
| `norms-matrix.json` | Fuente de verdad: constraints por carpeta | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/norms-matrix.json) |
| `VALIDATOR_DEV_NORMS.md` | Normas para desarrollo de validadores | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/VALIDATOR_DEV_NORMS.md) |
| `verify-constraints.sh` | Validador de coherencia declarativa | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/verify-constraints.sh) |

---

> 📌 **Nota final**: Este README es un artifact Tier 2. Cualquier modificación debe pasar validación automática antes de merge.  
> 🇧🇷 *Documentação técnica completa disponível em*: `docs/pt-BR/workflows/langchain-langraph/README.md` (próxima entrega).


---
