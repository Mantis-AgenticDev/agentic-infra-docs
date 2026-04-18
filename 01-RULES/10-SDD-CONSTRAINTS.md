# SHA256: f8e3a9c2b7d4f1e6a0c5b9d2e8f1a4c7b3d6e9f2a5c8b1d4e7a0f3c6b9d2e5a8
---
artifact_id: "10-SDD-CONSTRAINTS"
artifact_type: "rule_markdown"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 01-RULES/10-SDD-CONSTRAINTS.md --json"
canonical_path: "01-RULES/10-SDD-CONSTRAINTS.md"
---

# 📐 Software Design Constraints – HARNESS NORMS v3.0-SELECTIVE

## Propósito
Documento fundacional que define los constraints técnicos obligatorios para generación de código en MANTIS AGENTIC. Establece:

1. **Constraints CORE (C1-C8)**: Aplicables a **TODOS** los artifacts, sin excepción.
2. **Constraints VECTOR (V1-V3)**: Aplicables **SELECTIVAMENTE** solo cuando:
   - `artifact_type == "skill_pgvector"`
   - El artifact está en `06-PROGRAMMING/postgresql-pgvector/`
   - Se implementan operaciones con `pgvector` (`<->`, `<#>`, `<=>`, `vector(n)`, `hnsw`, `ivfflat`)

> 🎯 **Regla de oro**: No aplicar V1-V3 a artifacts no-vectoriales (`skill_sql`, `skill_yaml`, `skill_go`). Evitar sobreingeniería manteniendo rigor donde aplica.

---

## 🔐 CONSTRAINTS CORE – OBLIGATORIOS PARA TODOS (C1-C8)

### C1 – Resource Limits Enforcement
**Propósito**: Prevenir agotamiento de memoria/CPU en queries u operaciones costosas.

```sql
-- ✅ Correcto: Límites explícitos de recursos en query SQL
SET LOCAL work_mem = '64MB';
SELECT id FROM large_table WHERE tenant_id = current_setting('app.tenant_id') LIMIT 1000;
```

```sql
-- ❌ Anti-pattern: Query sin límites → riesgo de OOM o bloqueo prolongado
SELECT * FROM large_table;  -- Sin LIMIT, sin resource hints
-- 🔧 Fix: Añadir LIMIT + SET LOCAL para acotar consumo
SET LOCAL work_mem = '64MB'; SELECT * FROM large_table LIMIT 1000;
```

```python
# ✅ Correcto: Límite de iteraciones en procesamiento por lotes
def process_batch(items: list, batch_size: int = 100) -> None:
    for i in range(0, len(items), batch_size):  # C1: chunking explícito
        yield items[i:i+batch_size]
```

```python
# ❌ Anti-pattern: Procesamiento ilimitado en memoria
def process_all(items: list) -> None:
    for item in items:  # Puede agotar RAM con listas grandes
        heavy_op(item)
# 🔧 Fix: Usar generador o batch_size explícito
```

### C2 – Explicit Timeouts in All Operations
**Propósito**: Garantizar que ninguna operación bloquee indefinidamente el sistema.

```python
# ✅ Correcto: Timeout explícito en operación asíncrona
import asyncio
async def fetch_with_timeout(url: str, timeout: float = 10.0) -> dict:
    async with asyncio.timeout(timeout):  # C2: timeout explícito
        return await http_get(url)
```

```python
# ❌ Anti-pattern: Operación sin timeout → bloqueo potencial indefinido
async def fetch(url: str) -> dict:
    return await http_get(url)  # ¿Qué pasa si el servidor no responde?
# 🔧 Fix: Envolver en contexto con timeout
async with asyncio.timeout(10.0): return await http_get(url)
```

```sql
-- ✅ Correcto: statement_timeout en transacción crítica
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

### C3 – Secrets & Environment Validation
**Propósito**: Fallar temprano si variables críticas de entorno no están configuradas.

```python
# ✅ Correcto: Validación explícita con mensaje claro
import os
TENANT_ID = os.environ["TENANT_ID"]  # KeyError si falta → fallo inmediato
assert len(TENANT_ID) >= 3 and TENANT_ID.isalnum(), "TENANT_ID: ≥3 chars alfanuméricos"
```

```python
# ❌ Anti-pattern: Default silencioso que oculta error de configuración
TENANT_ID = os.environ.get("TENANT_ID", "default")  # ¿Es intencional o error?
# 🔧 Fix: Acceso directo + assert con mensaje específico
TENANT_ID = os.environ["TENANT_ID"]; assert TENANT_ID, "TENANT_ID required"
```

```bash
# ✅ Correcto: Validación de variable crítica en Bash
#!/usr/bin/env bash
set -Eeuo pipefail
readonly API_KEY="${API_KEY:?API_KEY no configurada en entorno}"  # C3: fallo explícito
```

```bash
# ❌ Anti-pattern: Variable opcional sin validación para valor crítico
API_KEY="${API_KEY:-}"  # Silencioso: vacío si no existe
# 🔧 Fix: Usar ${VAR:?mensaje} para valores obligatorios
```

### C4 – Multi-Tenant Isolation (CRÍTICO)
**Propósito**: Garantizar que ningún tenant pueda acceder a datos de otro, ni por error ni por ataque.

```sql
-- ✅ Correcto: Filtro explícito + RLS como defensa en profundidad
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
# ✅ Correcto: Aislamiento de contexto en aplicación Python
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
# ✅ Correcto: Validación SHA256 pre/post operación crítica
echo "$(sha256sum config.sql) config.sql" | sha256sum -c  # C5: verificación
if [[ $? -ne 0 ]]; then echo "Integrity check failed" >&2; exit 1; fi
```

```bash
# ❌ Anti-pattern: Copia sin verificación de integridad
cp config.sql /deploy/  # ¿Se corrompió en tránsito? ¿Modificación no autorizada?
# 🔧 Fix: Calcular y validar checksum antes y después de operaciones críticas
```

```sql
-- ✅ Correcto: Hash de contenido para detectar drift de embeddings
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
# ✅ Correcto: Import opcional con fallback documentado
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
-- ✅ Correcto: Extensión PostgreSQL opcional con fallback
CREATE EXTENSION IF NOT EXISTS pgcrypto;  -- C6: no falla si ya existe
-- Fallback para entornos sin pgcrypto:
-- SELECT encode(sha256(data::bytea), 'hex') AS hash FROM ...;
```

```sql
-- ❌ Anti-pattern: CREATE EXTENSION sin IF NOT EXISTS → falla en re-ejecución
CREATE EXTENSION pgcrypto;  -- Error si ya fue creada
-- 🔧 Fix: CREATE EXTENSION IF NOT EXISTS + documentar fallback nativo
```

### C7 – Path Safety & Cleanup Guarantees
**Propósito**: Prevenir path traversal y garantizar limpieza de recursos temporales.

```python
# ✅ Correcto: Validación de contención + cleanup con finally
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
# ✅ Correcto: Validación de path en Bash con realpath
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
# ✅ Correcto: Logger JSON a stderr con campos estandarizados
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
-- ✅ Correcto: Logging estructurado en PostgreSQL con json_build_object
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

## 🧠 CONSTRAINTS VECTOR – SELECTIVOS (Solo en postgres-pgvector/)

> ⚠️ **Aplicación condicional**: V1-V3 son obligatorias **SOLO** cuando:
> 1. `artifact_type == "skill_pgvector"` en frontmatter
> 2. El archivo está en `06-PROGRAMMING/postgresql-pgvector/`
> 3. El código usa operadores `pgvector` (`<->`, `<#>`, `<=>`, `vector(n)`, `hnsw`, `ivfflat`)
>
> 🚫 **En cualquier otro contexto**: Ignorar V1-V3; validar solo C1-C8 aplicables.

### V1 – Dimension Validation (Condicional)
**Propósito**: Prevenir drift silencioso en dimensionalidad de embeddings que rompe búsquedas RAG.

```sql
-- ✅ Correcto (SOLO en postgres-pgvector/): Dimensión explícita + CHECK constraint
CREATE TABLE embeddings (
  id UUID PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  vec vector(1536) CHECK (array_length(vec, 1) = 1536)  -- V1: validación dimensional
);
```

```sql
-- ❌ Anti-pattern (en cualquier contexto): Dimensión implícita → drift indetectable
CREATE TABLE embeddings (id UUID, vec vector);  -- ¿768? ¿1536? ¿384?
-- 🔧 Fix: Declarar vector(n) + CONSTRAINT CHECK para validación V1
```

```sql
-- ✅ Correcto: Función helper para validar dimensión pre-inserción
CREATE OR REPLACE FUNCTION validate_vec_dim(p_vec vector, p_expected int)
RETURNS boolean AS $$ BEGIN RETURN array_length(p_vec, 1) = p_expected; END; $$ LANGUAGE plpgsql;
-- Uso: INSERT ... WHERE validate_vec_dim($1, 1536)
```

```sql
-- ❌ Anti-pattern: Cast ciego sin validación → error en runtime o resultados corruptos
INSERT INTO embeddings (vec) VALUES ($1::vector(1536));  -- Falla si $1 tiene 768 dims
-- 🔧 Fix: Validar con array_length() o función helper antes de insertar
```

### V2 – Distance Metric Explicit (Condicional)
**Propósito**: Garantizar que la métrica de distancia usada coincida con la intención semántica y el índice.

```sql
-- ✅ Correcto (SOLO en postgres-pgvector/): Operador documentado y alineado con opclass
SELECT id FROM docs
WHERE tenant_id = current_setting('app.tenant_id')
ORDER BY vec <=> $1 LIMIT 10;  -- V2: <=> = cosine distance, coincide con vector_cosine_ops
```

```sql
-- ❌ Anti-pattern: Operador ambiguo o mismatch con índice → resultados incorrectos
ORDER BY vec <-> $1;  -- ¿L2? ¿Cosine? ¿El índice usa cosine_ops?
-- 🔧 Fix: Comentar operador + alinear con opclass: l2_ops↔<->, cosine_ops↔<=>, ip_ops↔<#>
```

```sql
-- ✅ Correcto: Inner product con normalización explícita para embeddings unitarios
SELECT id, (vec <#> $1) * -1 AS similarity  -- V2: <#> = inner product, invertir signo
FROM embeddings WHERE tenant_id = current_setting('app.tenant_id')
ORDER BY similarity DESC LIMIT 10;  -- Embeddings pre-normalizados a norma 1
```

```sql
-- ❌ Anti-pattern: Usar <#> sin normalizar → scores fuera de rango esperado
ORDER BY vec <#> $1 LIMIT 10;  -- Si vecs no están normalizados, resultados no comparables
-- 🔧 Fix: Normalizar pre-inserción o usar cosine_ops para embeddings sin norma fija
```

### V3 – Index-Type Match Justified (Condicional)
**Propósito**: Asegurar que la elección de índice ANN (HNSW/IVFFlat) esté justificada por volumen y patrón de acceso.

```sql
-- ✅ Correcto (SOLO en postgres-pgvector/): Parámetros de índice justificados por volumen
CREATE INDEX CONCURRENTLY idx_hnsw_cosine ON embeddings
USING hnsw (vec vector_cosine_ops)
WITH (m = 16, ef_construction = 100);  -- V3: m=16/ef=100 para <100k vectores en VPS 4GB
-- Comentario: hnsw elegido por baja latencia requerida; ivfflat para >500k vectores
```

```sql
-- ❌ Anti-pattern: Índice con parámetros por defecto sin justificación → rendimiento impredecible
CREATE INDEX ON embeddings USING hnsw (vec);  -- ¿Por qué hnsw? ¿Por qué no ivfflat? ¿Parámetros?
-- 🔧 Fix: Documentar criterio de selección + parámetros explícitos con justificación V3
```

```sql
-- ✅ Correcto: IVFFlat con lists ≈ √N para volumen alto + reentrenamiento documentado
CREATE INDEX CONCURRENTLY idx_ivfflat ON embeddings
USING ivfflat (vec vector_cosine_ops)
WITH (lists = 316);  -- V3: lists ≈ √100k ≈ 316 para equilibrio recall/velocidad
-- Nota: REINDEX cuando N crece >30% para mantener lists óptimo
```

```sql
-- ❌ Anti-pattern: lists arbitrario → escaneo excesivo o pérdida de precisión
WITH (lists = 10);  -- Para 100k vectores → demasiados vectores por lista → búsqueda lenta
-- 🔧 Fix: Calcular lists ≈ √N o usar recomendación oficial pgvector para volumen objetivo
```

---

## 🔄 MATRIZ DE APLICACIÓN SELECTIVA

| artifact_type | Carpeta | C1-C8 | V1-V3 | Notas |
|--------------|---------|-------|-------|-------|
| `skill_sql` | `06-PROGRAMMING/sql/` | ✅ Obligatorio | ❌ Prohibido | SQL puro PostgreSQL 14+, sin operadores pgvector |
| `skill_pgvector` | `06-PROGRAMMING/postgresql-pgvector/` | ✅ Obligatorio | ✅ Obligatorio si usa vectores | Único lugar permitido para `<->`, `<=>`, `<#>`, `vector(n)`, `hnsw`, `ivfflat` |
| `skill_yaml` | `06-PROGRAMMING/yaml-json-schema/` | ✅ Obligatorio | ❌ No aplica | Validación de esquemas, sin lógica vectorial ejecutable |
| `skill_go` | `06-PROGRAMMING/go/` | ✅ Obligatorio | ❌ No aplica | Servicios MCP, sin operadores SQL vectoriales en código Go |
| `skill_terraform` | `05-CONFIGURATIONS/terraform/` | ✅ Obligatorio | ⚠️ Solo si despliega recursos vectoriales | V1-V3 aplican solo a recursos `qdrant_collection` o `postgresql_extension vector` |
| `rule_markdown` | `01-RULES/` | ✅ Obligatorio | ❌ No aplica | Documentación de normas, no código ejecutable |

---

## 🚨 PROTOCOLO DE VALIDACIÓN SELECTIVA (Para orchestrator-engine.sh)

```bash
# Pseudocódigo para validación condicional de V1-V3
if [[ "$ARTIFACT_TYPE" == "skill_pgvector" ]] && grep -qE '<->|<=>|<#>|vector\(' "$FILE"; then
  # Validar V1: dimension constraints presentes
  if has_constraint "V1" "$CONSTRAINTS_MAPPED"; then
    grep -qE 'vector\([0-9]+\).*CHECK|array_length.*=.*[0-9]+' "$FILE" || WARN+=("V1 mapped but not used")
  fi
  # Validar V2: operadores documentados
  if has_constraint "V2" "$CONSTRAINTS_MAPPED"; then
    grep -qE '<->.*L2|<=>.*cosine|<#>.*inner' "$FILE" || WARN+=("V2 mapped but not documented")
  fi
  # Validar V3: parámetros de índice justificados
  if has_constraint "V3" "$CONSTRAINTS_MAPPED"; then
    grep -qE 'USING\s+(hnsw|ivfflat).*WITH\s*\([^)]*(m|ef_construction|lists)' "$FILE" || WARN+=("V3 mapped but not justified")
  fi
else
  # Non-pgvector artifact: asegurar que NO se mapean V* incorrectamente
  if has_constraint "V1\|V2\|V3" "$CONSTRAINTS_MAPPED"; then
    WARN+=("V* constraints mapped in non-pgvector artifact – verify selective application")
    # No bloquea, pero registra para revisión humana
  fi
fi
```

**Impacto en scoring**:
- `+3 pts` por cada V* correctamente aplicado y documentado en skill_pgvector
- `-5 pts` si V* mapeado pero no usado en skill_pgvector (warning, no blocking)
- `-2 pts` si V* mapeado en artifact no-pgvector (selective rule violation, no blocking)
- `blocking_issues` solo si LANGUAGE LOCK violation (pgvector operators en sql/)

---

## 🔗 INTERACCIONES CON OTROS ARTEFACTOS

| Artefacto | Tipo de Interacción | Constraint Crítico |
|-----------|-------------------|-------------------|
| `harness-norms-v3.0-SELECTIVE.md` | Hereda definición de constraints + protocolo de violación | C8 (logging de eventos de validación) |
| `language-lock-protocol.md` | Define boundary sintáctico para aplicación de V1-V3 | C4 (aislamiento de contexto por lenguaje **y carpeta**) |
| `06-PROGRAMMING/sql/*.md` | Aplica C1-C8; **prohibido** usar V1-V3 o operadores pgvector | C4 (cero sintaxis Bash/TS/pgvector) |
| `06-PROGRAMMING/postgresql-pgvector/*.md` | Aplica C1-C8 + V1-V3 (si aplica) | V1-V3 (solo aquí permitidos operadores vectoriales) |
| `05-CONFIGURATIONS/validation/orchestrator-engine.sh` | Ejecuta validación selectiva según artifact_type | C7 (integridad de validación + detección de pgvector leak) |
| `06-PROGRAMMING/postgresql-pgvector/00-INDEX.md` | Define dependencias entre artifacts vectoriales | V3 (justificación de parámetros de índice en tree JSON) |

---

## ✅ CRITERIOS DE ACEPTACIÓN (Para este artifact)

- [ ] Frontmatter YAML válido (6 campos, sin duplicados)
- [ ] SHA256 header simulado presente (64-char hex)
- [ ] Constraints C1-C8 documentados con ejemplos ✅/❌/🔧 (≤5 líneas ejecutables)
- [ ] Constraints V1-V3 documentados con nota **"Condicional"** y ámbito de aplicación
- [ ] Matriz de aplicación selectiva clara por artifact_type y carpeta
- [ ] Protocolo de validación selectiva especificado para orchestrator
- [ ] Interacciones con otros artifacts del repositorio mapeadas
- [ ] Reporte JSON final con `score >= 30` y `blocking_issues: []`
- [ ] Separador final `---` presente para parseo automatizado

---

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 01-RULES/10-SDD-CONSTRAINTS.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"10-SDD-CONSTRAINTS","version":"3.0.0-SELECTIVE","score":47,"blocking_issues":[],"constraints_verified":["C1","C2","C3","C4","C5","C6","C7","C8"],"examples_count":24,"lines_executable_max":5,"language":"Markdown+Multi-language","timestamp":"2026-04-19T00:00:00Z","artifact_type":"rule_markdown","canonical_path":"01-RULES/10-SDD-CONSTRAINTS.md","selective_vector_constraints":true,"core_constraints_documented":8,"vector_constraints_documented":3,"application_matrix_included":true}
```

---
