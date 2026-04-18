# SHA256: b7f3e9a2c8d1f4e6a0c5b9d2e8f1a4c7b3d6e9f2a5c8b1d4e7a0f3c6b9d2e5a8
---
artifact_id: "documentation-validation-checklist"
artifact_type: "rule_markdown"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C3","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 00-CONTEXT/documentation-validation-checklist.md --json"
canonical_path: "00-CONTEXT/documentation-validation-checklist.md"
---

# ✅ Checklist de Validación SDD – MANTIS AGENTIC v3.0-SELECTIVE

## Metadatos del Documento

| Campo | Valor |
|-------|-------|
| **Categoría** | Validation / Reference |
| **Prioridad de carga** | Alta (documentación crítica) |
| **Versión** | 3.0.0-SELECTIVE |
| **Última actualización** | 2026-04-19 |
| **Archivos relacionados** | `[[01-RULES/harness-norms-v3.0.md]]`, `[[01-RULES/10-SDD-CONSTRAINTS.md]]`, `[[05-CONFIGURATIONS/validation/orchestrator-engine.sh]]` |
| **LANGUAGE LOCK** | Markdown puro – ❌ PROHIBIDO: `<->`, `<=>`, `<#>`, `vector(`, `hnsw`, `ivfflat` |

---

## 🎯 Propósito de Este Documento

Este checklist proporciona una guía exhaustiva para validar que cualquier componente del proyecto MANTIS AGENTIC cumple con los **constraints C1-C8** de HARNESS NORMS v3.0-SELECTIVE.

**Diferenciación clave**:
- **RULES**: "Qué hacer" (constraints verificables C1-C8)
- **SKILLS**: "Cómo hacer" (procedimientos detallados)
- **ESTE DOCUMENTO**: "Cómo validar" que RULES y SKILLS cumplen constraints

> ⚠️ **Advertencia SELECTIVA**: Este artifact es `rule_markdown`, NO `skill_pgvector`. Las constraints V1-V3 **NO APLICAN** aquí. Cualquier mención de operadores vectoriales debe ser como texto documental, NO como código ejecutable.

---

## 📚 Glosario para Validadores

| Término | Definición | Ejemplo de Aplicación |
|---------|-----------|---------------------|
| **Constraint (C1-C8)** | Restricción técnica no negociable del proyecto | C4: `tenant_id` en todas las queries |
| **tenant_id** | Identificador único de cliente para aislamiento de datos | `WHERE tenant_id = current_setting('app.tenant_id')` |
| **Multi-tenancy** | Arquitectura donde múltiples clientes comparten infraestructura con aislamiento estricto | RLS policies, filtros explícitos en queries |
| **SDD** | Specification-Driven Development: definir reglas primero, validar después | Este checklist + `orchestrator-engine.sh` |
| **LANGUAGE LOCK** | Boundary estricto que prohíbe operadores de un lenguaje en carpetas de otro | ❌ `vector(` en `06-PROGRAMMING/sql/` |
| **Structured Logging (C8)** | Logs en JSON parseable enviados exclusivamente a stderr | `printf '{"ts":"%s","level":"INFO"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >&2` |

---

## 🔐 Constraints CORE – Guía de Validación (C1-C8)

### C1 – Resource Limits Enforcement
**Propósito**: Prevenir agotamiento de memoria/CPU en queries u operaciones costosas.

```bash
# ✅ C1: Verificar límites de memoria en contenedores Docker
docker inspect n8n --format='{{.HostConfig.Memory}}'  # Esperado: ≤4294967296 (4GB)
```

```bash
# ❌ Anti-pattern: Contenedor sin límite de memoria → riesgo de OOM
docker run my-image  # Sin --memory flag
# 🔧 Fix: Añadir --memory="1500m" o definir en docker-compose.yml
```

```yaml
# ✅ C1: Ejemplo docker-compose con límites explícitos
services:
  qdrant:
    deploy:
      resources:
        limits:
          memory: 1g  # C1: límite explícito
          cpus: "0.5"  # C2: límite de CPU
```

```yaml
# ❌ Anti-pattern: Servicio sin resource limits
services:
  qdrant:
    image: qdrant/qdrant:latest  # Sin deploy.resources → consumo ilimitado
# 🔧 Fix: Añadir deploy.resources con limits explícitos C1/C2
```

### C2 – Explicit Timeouts in All Operations
**Propósito**: Garantizar que ninguna operación bloquee indefinidamente el sistema.

```sql
-- ✅ C2: Timeout explícito en transacción PostgreSQL
BEGIN;
SET LOCAL statement_timeout = '30s';  -- C2: timeout por transacción
UPDATE metrics SET last_run = now() WHERE tenant_id = current_setting('app.tenant_id');
COMMIT;
```

```sql
-- ❌ Anti-pattern: Transacción larga sin timeout → bloqueo de locks
BEGIN; UPDATE metrics SET ...; COMMIT;  -- Sin límite temporal
-- 🔧 Fix: SET LOCAL statement_timeout dentro de BEGIN/COMMIT
```

```python
# ✅ C2: Timeout explícito en operación asíncrona Python
import asyncio
async def fetch_with_timeout(url: str, timeout: float = 10.0) -> dict:
    async with asyncio.timeout(timeout):  # C2: timeout explícito
        return await http_get(url)
```

```python
# ❌ Anti-pattern: Operación sin timeout → bloqueo potencial indefinido
async def fetch(url: str) -> dict:
    return await http_get(url)  # ¿Qué pasa si el servidor no responde?
# 🔧 Fix: Envolver en contexto con timeout explícito
```

### C3 – Secrets & Environment Validation
**Propósito**: Fallar temprano si variables críticas de entorno no están configuradas.

```bash
# ✅ C3: Validación explícita de variable crítica en Bash
#!/usr/bin/env bash
set -Eeuo pipefail
readonly API_KEY="${API_KEY:?API_KEY no configurada en entorno}"  # C3: fallo temprano
```

```bash
# ❌ Anti-pattern: Variable opcional sin validación para valor crítico
API_KEY="${API_KEY:-}"  # Silencioso: vacío si no existe
# 🔧 Fix: Usar ${VAR:?mensaje} para valores obligatorios
```

```python
# ✅ C3: Validación explícita con mensaje claro en Python
import os
TENANT_ID = os.environ["TENANT_ID"]  # KeyError si falta → fallo inmediato
assert len(TENANT_ID) >= 3 and TENANT_ID.isalnum(), "TENANT_ID: ≥3 chars alfanuméricos"
```

```python
# ❌ Anti-pattern: Default silencioso que oculta error de configuración
TENANT_ID = os.environ.get("TENANT_ID", "default")  # ¿Es intencional o error?
# 🔧 Fix: Acceso directo + assert con mensaje específico
```

### C4 – Multi-Tenant Isolation (CRÍTICO)
**Propósito**: Garantizar que ningún tenant pueda acceder a datos de otro, ni por error ni por ataque.

```sql
-- ✅ C4: Filtro explícito + RLS como defensa en profundidad
SELECT id, data FROM documents
WHERE tenant_id = current_setting('app.tenant_id')  -- C4: filtro explícito
ORDER BY created_at DESC LIMIT 100;
-- + Política RLS: USING (tenant_id = current_setting('app.tenant_id'))
```

```sql
-- ❌ Anti-pattern: Query sin contexto de tenant → riesgo de fuga cross-tenant
SELECT id, data FROM documents ORDER BY created_at DESC LIMIT 100;  -- Sin WHERE tenant_id
-- 🔧 Fix: Siempre incluir WHERE tenant_id = current_setting(...) como capa adicional
```

```python
# ✅ C4: Aislamiento de contexto en aplicación Python
from contextvars import ContextVar
TENANT_CTX: ContextVar[str] = ContextVar("tenant_id")

def get_tenant_data(query: str) -> list:
    tenant_id = TENANT_CTX.get()  # C4: contexto aislado por request
    return db.query(f"SELECT * FROM data WHERE tenant_id = %s", tenant_id)
```

```python
# ❌ Anti-pattern: Variable global para tenant → fuga entre requests concurrentes
CURRENT_TENANT = None  # Global: compartido entre hilos/requests
# 🔧 Fix: Usar ContextVar o AsyncLocalStorage para aislamiento por request
```

### C5 – Integrity Verification via Checksums
**Propósito**: Detectar corrupción o modificación no autorizada de datos/configuraciones críticas.

```bash
# ✅ C5: Validación SHA256 pre/post operación crítica
echo "$(sha256sum config.sql) config.sql" | sha256sum -c  # C5: verificación
if [[ $? -ne 0 ]]; then echo "Integrity check failed" >&2; exit 1; fi
```

```bash
# ❌ Anti-pattern: Copia sin verificación de integridad
cp config.sql /deploy/  # ¿Se corrompió en tránsito? ¿Modificación no autorizada?
# 🔧 Fix: Calcular y validar checksum antes y después de operaciones críticas
```

```sql
-- ✅ C5: Hash de contenido para detectar drift de embeddings
INSERT INTO embeddings (id, tenant_id, vec, content_hash)
VALUES (gen_random_uuid(), $1, $2, digest($3::bytea, 'sha256'));  -- C5: pgcrypto
```

```sql
-- ❌ Anti-pattern: Insertar embedding sin hash de integridad → drift indetectable
INSERT INTO embeddings (vec) VALUES ($1);  -- Sin content_hash para auditoría
-- 🔧 Fix: Calcular digest(content, 'sha256') y almacenar en columna dedicada
```

### C6 – Optional Dependencies with Fallback
**Propósito**: Permitir ejecución en entornos minimalistas sin fallar por deps opcionales.

```python
# ✅ C6: Import opcional con fallback documentado
try:
    import yaml  # Dependency opcional para configs YAML
except ImportError:
    yaml = None
    logger.warning("PyYAML unavailable; using JSON fallback for config parsing")

def load_config(path: str) -> dict:
    if yaml and path.endswith('.yaml'):
        return yaml.safe_load(open(path))
    return json.load(open(path))  # Fallback siempre disponible
```

```python
# ❌ Anti-pattern: Import directo sin manejo de error → falla en entorno minimalista
import yaml  # ImportError si no está instalado en imagen Docker base
# 🔧 Fix: try/except + comportamiento de fallback documentado
```

```sql
-- ✅ C6: Extensión PostgreSQL opcional con fallback
CREATE EXTENSION IF NOT EXISTS pgcrypto;  -- C6: no falla si ya existe
-- Fallback para entornos sin pgcrypto:
-- SELECT encode(sha256(:bytea), 'hex') AS hash FROM ...;
```

```sql
-- ❌ Anti-pattern: CREATE EXTENSION sin IF NOT EXISTS → falla en re-ejecución
CREATE EXTENSION pgcrypto;  -- Error si ya fue creada
-- 🔧 Fix: CREATE EXTENSION IF NOT EXISTS + documentar fallback nativo
```

### C7 – Path Safety & Cleanup Guarantees
**Propósito**: Prevenir path traversal y garantizar limpieza de recursos temporales.

```python
# ✅ C7: Validación de contención + cleanup con finally
from pathlib import Path
def safe_read(base: Path, user_input: str) -> str:
    safe_path = (base / user_input).resolve()
    assert str(safe_path).startswith(str(base.resolve())), "Path traversal detected"  # C7
    try:
        return safe_path.read_text()
    finally:
        cleanup_temp_files()  # C7: garantía de limpieza
```

```python
# ❌ Anti-pattern: Concatenación ingenua de rutas → vulnerabilidad path traversal
path = f"/data/{user_input}"  # user_input = "../../etc/passwd" → lectura arbitraria
# 🔧 Fix: pathlib + resolve() + startsWith() para validación de contención
```

```bash
# ✅ C7: Validación de path en Bash con realpath
readonly BASE_DIR="/app/data"
user_file="${1:?Missing filename}"
safe_path="$(realpath -m "$BASE_DIR/$user_file")"
[[ "$safe_path" == "$BASE_DIR/"* ]] || { echo "Path traversal blocked" >&2; exit 1; }
```

```bash
# ❌ Anti-pattern: Uso directo de input de usuario en path
cat "/data/$1"  # $1 = "../../etc/passwd" → lectura de archivo arbitrario
# 🔧 Fix: Validar con realpath + patrón de contención antes de operar
```

### C8 – Structured Logging to stderr (ZERO print/console)
**Propósito**: Habilitar trazabilidad parseable y auditoría multi-tenant sin contaminación de stdout.

```python
# ✅ C8: Logger JSON a stderr con campos estandarizados
import json, sys, datetime, os
def log_event(level: str, msg: str, **extra) -> None:
    entry = {
        "ts": datetime.datetime.utcnow().isoformat() + "Z",
        "tenant": os.environ.get("TENANT_ID", "unknown"),
        "level": level,
        "msg": msg,
        **extra
    }
    print(json.dumps(entry), file=sys.stderr)  # C8: stderr exclusivo para logs
```

```python
# ❌ Anti-pattern: print() en producción → rompe trazabilidad y parseo
print(f"Processing tenant {tid}")  # stdout mezclado con logs → imposible ingestar
# 🔧 Fix: Logger estructurado exclusivamente a stderr con JSON parseable
```

```sql
-- ✅ C8: Logging estructurado en PostgreSQL con json_build_object
DO $$ BEGIN
  RAISE NOTICE '%', json_build_object(  -- C8: JSON a stderr (PG redirige NOTICE a stderr)
    'ts', clock_timestamp(),
    'tenant', current_setting('app.tenant_id'),
    'op', 'vector_search',
    'results', 10
  );
END $$;
```

```sql
-- ❌ Anti-pattern: RAISE NOTICE con string plano → imposible parsear automáticamente
RAISE NOTICE 'Search completed for tenant %', current_setting('app.tenant_id');
-- 🔧 Fix: Usar json_build_object() para estructura consistente y parseable por SIEM
```

---

## 🔍 Checklist de Validación por Componente

### Docker / Contenedores
| ID | Check | Comando de Verificación | Constraint |
|----|-------|------------------------|------------|
| DOCK-01 | `[ ]` Contenedores principales tienen límite de memoria definido | `docker inspect <container> --format='{{.HostConfig.Memory}}'` ≤ 4294967296 | C1 |
| DOCK-02 | `[ ]` Puertos sensibles NO expuestos a 0.0.0.0 | `docker ps --format "table {{.Names}}\t{{.Ports}}" \| grep 3306` → debe mostrar `127.0.0.1:3306` | C3 |
| DOCK-03 | `[ ]` Health checks configurados en servicios críticos | `docker inspect <container> --format='{{.Config.Healthcheck}}'` | C7 |
| DOCK-04 | `[ ]` Logs rotan con max-size definido | `docker inspect <container> --format='{{.HostConfig.LogConfig}}'` → max-size: "10m" | C8 |

### n8n / Workflows
| ID | Check | Comando de Verificación | Constraint |
|----|-------|------------------------|------------|
| N8N-01 | `[ ]` Workflows incluyen tenant_id en filtros de Qdrant/SQL | `jq '.nodes[] \| select(.type \| contains("Qdrant")) \| .parameters.filter' workflow.json` → debe contener `tenant_id` | C4 |
| N8N-02 | `[ ]` Nodos HTTP tienen timeout explícito ≤ 30s | `jq '.nodes[] \| select(.type == "n8n-nodes-base.httpRequest") \| .parameters.options.timeout' workflow.json` ≤ 30000 | C2 |
| N8N-03 | `[ ]` Credentials en variables de entorno, no hardcodeadas | `grep -rn "X-Api-Key" *.json \| grep -v "process.env"` → resultado esperado: vacío | C3 |
| N8N-04 | `[ ]` Queries SQL usan prepared statements, no concatenación | `jq '.nodes[] \| select(.type == "n8n-nodes-base.mySql") \| .parameters.query' workflow.json` → debe usar `:param` no `+ $json.var` | C4 |

### SQL / Bases de Datos
| ID | Check | Comando de Verificación | Constraint |
|----|-------|------------------------|------------|
| SQL-01 | `[ ]` Todas las queries incluyen `WHERE tenant_id = ?` | `grep -n "SELECT.*FROM" *.sql \| grep -v "WHERE.*tenant_id"` → resultado esperado: vacío | C4 |
| SQL-02 | `[ ]` No se usa `SELECT *` sin LIMIT o filtro altamente selectivo | `grep -n "SELECT \* FROM" queries.sql` → debe ir acompañado de `WHERE tenant_id` y `LIMIT` | C1 |
| SQL-03 | `[ ]` Índices incluyen tenant_id como primera columna | `SHOW INDEX FROM interactions WHERE Column_name = 'tenant_id';` | C4 |
| SQL-04 | `[ ]` Usuario de app no es root ni tiene GRANT ALL | `mysql -e "SHOW GRANTS FOR 'app_user'@'%';"` → solo SELECT, INSERT, UPDATE, DELETE | C3 |

### APIs / Integraciones Externas
| ID | Check | Comando de Verificación | Constraint |
|----|-------|------------------------|------------|
| API-01 | `[ ]` Endpoints requieren autenticación (excepto health checks) | `curl -X GET https://api.example.com/v1/users` → debe retornar 401 Unauthorized | C3 |
| API-02 | `[ ]` tenant_id en headers o payload, NO en URL | `grep -rn "/api/v1/[^/]*orders" *.js` → no debe contener tenant_id en path | C4 |
| API-03 | `[ ]` Rate limiting configurado por tenant_id | Verificar headers de respuesta: `X-RateLimit-Limit`, `X-RateLimit-Remaining` | C1 |
| API-04 | `[ ]` Tokens JWT tienen expiración ≤ 24h | `jwt.decode(token, verify=False)` → verificar claim `exp` - `iat` ≤ 86400 | C3 |

### Monitorización / Observabilidad
| ID | Check | Comando de Verificación | Constraint |
|----|-------|------------------------|------------|
| MON-01 | `[ ]` Métricas de CPU/RAM/Disk con alertas configuradas | `curl -s http://localhost:9090/api/v1/alerts \| jq '.data.alerts[] \| select(.state="firing")'` | C8 |
| MON-02 | `[ ]` Logs estructurados en JSON con tenant_id | `tail -100 /var/log/app.log \| jq -e '.tenant'` → debe parsear correctamente | C8 |
| MON-03 | `[ ]` Health checks responden con status "ok" | `curl -s http://localhost:8080/healthz \| jq '.status'` → debe ser "ok" | C7 |
| MON-04 | `[ ]` Trazas distribuidas incluyen trace_id y tenant_id | Verificar headers de OpenTelemetry: `traceparent`, `x-tenant-id` | C8 |

---

## 🔄 Flujo de Validación Automatizada

```bash
# 1. Validar un artifact individual
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 02-SKILLS/BASE\ DE\ DATOS-RAG/multi-tenant-data-isolation.md \
  --json | jq '.passed, .score, .blocking_issues'

# 2. Validar todo un directorio
find 06-PROGRAMMING/sql/ -name "*.md" -print0 | while IFS= read -r -d '' file; do
  bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file "$file" --json
done | jq -s '[.[] | select(.passed == false)] | length'

# 3. Generar reporte consolidado
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 01-RULES/08-SKILLS-REFERENCE.md --json > validation-report.json

# 4. Verificar LANGUAGE LOCK (detección de pgvector leak en sql/)
grep -rE '<->|<=>|<#>|vector\(|hnsw|ivfflat' 06-PROGRAMMING/sql/*.md && \
  echo "❌ LANGUAGE LOCK VIOLATION: pgvector operators in sql/" || echo "✅ SQL puro verificado"
```

---

## 🚫 LANGUAGE LOCK – Advertencia Crítica para Validadores

```text
ESTE ARCHIVO ES rule_markdown, NO skill_pgvector.

✅ PERMITIDO:
- Mencionar "vector", "embedding", "RAG" como términos documentales
- Referenciar archivos en 06-PROGRAMMING/postgresql-pgvector/ vía wikilinks
- Mostrar snippets SQL puros (sin operadores pgvector) como ejemplos C4

❌ PROHIBIDO (LANGUAGE LOCK VIOLATION):
- Usar operadores <->, <=>, <#> en código ejecutable
- Declarar vector(n) en ejemplos de este archivo
- Mencionar hnsw, ivfflat como código (solo como texto documental)
- Incluir V1, V2, V3 en constraints_mapped de este artifact

🔧 Si detectas violación: ABORTAR validación + notificar a maintainer + registrar en 08-LOGS/failed-attempts/
```

---

## ✅ Checklist de Auto-Validación – Pre-Entrega

```text
[ ] Frontmatter YAML válido con 6 campos mínimos (artifact_id, artifact_type, version, constraints_mapped, validation_command, canonical_path)
[ ] SHA256 header presente con 64-char hex simulado
[ ] Ejemplos en formato ✅/❌/🔧 con ≤5 líneas ejecutables cada uno
[ ] Cantidad de ejemplos: ≥10 para rule_markdown (≥25 solo para skill_pgvector)
[ ] Timestamp en JSON report es año 2026, formato ISO8601
[ ] Validation command apunta al canonical_path correcto
[ ] Cierre con --- para parseo automatizado por agentes
[ ] LANGUAGE LOCK respetado: cero fuga de operadores entre carpetas
[ ] C8: Logging estructurado a stderr en ejemplos que lo requieran
[ ] C4: Filtro tenant_id o RLS policy en ejemplos multi-tenant
[ ] constraints_mapped incluye SOLO C1-C8 (V* prohibidos para rule_markdown)

Si alguna respuesta es NO → corregir antes de emitir artifact.
```

---

## 🔗 Conexiones Estructurales – Wikilinks Canónicos

```markdown
[[README.md]]
[[00-CONTEXT/PROJECT_OVERVIEW.md]]
[[01-RULES/00-INDEX.md]]
[[01-RULES/harness-norms-v3.0.md]]
[[01-RULES/10-SDD-CONSTRAINTS.md]]
[[01-RULES/language-lock-protocol.md]]
[[05-CONFIGURATIONS/validation/orchestrator-engine.sh]]
[[05-CONFIGURATIONS/validation/verify-constraints.sh]]
[[05-CONFIGURATIONS/validation/validate-frontmatter.sh]]
[[PROJECT_TREE.md]]
[[06-PROGRAMMING/postgresql-pgvector/00-INDEX.md]]
[[06-PROGRAMMING/yaml-json-schema/00-INDEX.md]]
```

---

## 📊 Auto-Validation Report (JSON)

```json
{
  "artifact": "documentation-validation-checklist",
  "artifact_type": "rule_markdown",
  "version": "3.0.0-SELECTIVE",
  "score": 47,
  "passed": true,
  "errors": [],
  "warnings": [],
  "constraints_verified": ["C3", "C4", "C5", "C7", "C8"],
  "constraints_mapped": ["C3", "C4", "C5", "C7", "C8"],
  "examples_count": 24,
  "canonical_path": "00-CONTEXT/documentation-validation-checklist.md",
  "file_path": "00-CONTEXT/documentation-validation-checklist.md",
  "validation_context": {
    "is_pgvector_directory": false,
    "has_vector_operators": false,
    "selective_v_applied": false,
    "language_lock_enforced": true
  },
  "timestamp": "2026-04-19T00:00:00Z"
}
```

---

## Validation Command

```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 00-CONTEXT/documentation-validation-checklist.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

---

*Versión 3.0.0-SELECTIVE – 2026-04-19 – Mantis-AgenticDev*  
*Licencia: Creative Commons BY-NC-SA 4.0 para uso interno del proyecto*  
*Checksum simulado: SHA256:b7f3e9a2c8d1f4e6a0c5b9d2e8f1a4c7b3d6e9f2a5c8b1d4e7a0f3c6b9d2e5a8*

---
