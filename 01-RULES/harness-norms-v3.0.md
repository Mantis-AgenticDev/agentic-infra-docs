# 🔐 HARNESS NORMS v3.0-SELECTIVE – Anti-Drift Protocol + Vector/RAG Audit (Conditional)

**Versión**: 3.0.0-SELECTIVE | **Fecha**: 2026-04-19 | **Modo**: CORE + VECTOR-OPTIONAL

---

## 🎯 Propósito Actualizado

Documento fundacional para generación de código asistida por IA en MANTIS AGENTIC. Establece:

1. **Normas CORE (C1-C8)**: Obligatorias para **TODOS** los artifacts, sin excepción.
2. **Normas VECTOR (V1-V3)**: Aplicables **SELECTIVAMENTE** solo cuando:
   - El artifact está en `06-PROGRAMMING/postgresql-pgvector/`
   - Se trabaja con operadores `pgvector` (`<->`, `<#>`, `<=>`, `vector(n)`, `hnsw`, `ivfflat`)
   - Se implementan funcionalidades RAG/embedding/search semántico

> 🚫 **NO aplicar V1-V3 a**: SQL puro (`sql/`), YAML/JSON schemas, servicios Go MCP, infraestructura no-vectorial. Evitar sobreingeniería.

---

## 📜 NORMAS CORE – OBLIGATORIAS PARA TODOS (C1-C8)

### C1 – Resource Limits Enforcement
```sql
-- ✅ Correcto: Límite explícito en query
SET LOCAL work_mem = '64MB'; SELECT id FROM data WHERE tenant_id = current_setting('app.tenant_id') LIMIT 1000;
```
```sql
-- ❌ Anti-pattern: Query sin límite
SELECT * FROM large_table;
-- 🔧 Fix: Añadir LIMIT + resource hint
SELECT * FROM large_table LIMIT 1000; -- + SET LOCAL statement_timeout = '30s'
```

### C2 – Explicit Timeouts in All Operations
```python
# ✅ Correcto: Timeout en operación crítica
import asyncio; async with asyncio.timeout(10): await process()
```
```python
# ❌ Anti-pattern: Operación sin timeout
await process()  # Puede bloquear indefinidamente
# 🔧 Fix: Envolver en contexto con timeout
async with asyncio.timeout(10): await process()
```

### C3 – Secrets & Environment Validation
```python
# ✅ Correcto: Validación explícita + fallo claro
import os, sys
tid = os.environ["TENANT_ID"]  # KeyError si falta
assert tid and len(tid) >= 3, "TENANT_ID: min 3 chars, alfanumérico"
```
```python
# ❌ Anti-pattern: Default silencioso
tid = os.environ.get("TENANT_ID", "default")  # Oculta error de config
# 🔧 Fix: Acceso directo + assert
tid = os.environ["TENANT_ID"]; assert tid, "TENANT_ID required"
```

### C4 – Multi-Tenant Isolation (CRÍTICO)
```sql
-- ✅ Correcto: Filtro explícito + RLS como defensa en profundidad
SELECT * FROM data WHERE tenant_id = current_setting('app.tenant_id');
-- + Política RLS: USING (tenant_id = current_setting('app.tenant_id'))
```
```sql
-- ❌ Anti-pattern: Query sin contexto de tenant
SELECT * FROM data;  # Riesgo de fuga cross-tenant
-- 🔧 Fix: Siempre incluir WHERE tenant_id = current_setting(...)
```

### C5 – Integrity Verification via Checksums
```bash
# ✅ Correcto: SHA256 pre/post operación crítica
echo "$(sha256sum config.sql) config.sql" | sha256sum -c
```
```bash
# ❌ Anti-pattern: Confianza ciega sin verificación
cp config.sql /deploy/  # ¿Se corrompió en tránsito?
# 🔧 Fix: Validar checksum antes y después
```

### C6 – Optional Dependencies with Fallback
```python
# ✅ Correcto: Import opcional con fallback documentado
try: import yaml
except ImportError: yaml = None; logger.warning("PyYAML unavailable; using JSON fallback")
```
```python
# ❌ Anti-pattern: Import directo sin manejo de error
import yaml  # Falla si no está instalado en entorno minimalista
# 🔧 Fix: try/except + comportamiento de fallback
```

### C7 – Path Safety & Cleanup Guarantees
```python
# ✅ Correcto: Validación de contención + cleanup con finally
from pathlib import Path
safe_path = (base / user_input).resolve()
assert str(safe_path).startswith(str(base.resolve())), "Path traversal detected"
try: process(safe_path)
finally: cleanup_temp()
```
```python
# ❌ Anti-pattern: Concatenación ingenua de rutas
path = f"/data/{user_input}"  # Riesgo: ../../etc/passwd
# 🔧 Fix: pathlib + resolve() + startsWith()
```

### C8 – Structured Logging to stderr (ZERO print/console)
```python
# ✅ Correcto: Logger JSON a stderr con campos estandarizados
import json, sys, datetime
log = {"ts": datetime.datetime.utcnow().isoformat(), "tenant": tid, "level": "INFO", "msg": "ok"}
print(json.dumps(log), file=sys.stderr)
```
```python
# ❌ Anti-pattern: print() en producción
print(f"Processing {tid}")  # Rompe trazabilidad, no parseable
# 🔧 Fix: Logger estructurado exclusivamente a stderr
```

---

## 🧠 NORMAS VECTOR – SELECTIVAS (Solo en postgres-pgvector/)

> ⚠️ **Aplicación condicional**: V1-V3 solo son obligatorias cuando el artifact:
> 1. Está en `06-PROGRAMMING/postgresql-pgvector/`
> 2. Usa operadores `pgvector` o tipo `vector(n)`
> 3. Implementa búsqueda semántica, RAG o manejo de embeddings

### V1 – Dimension Validation (Condicional)
```sql
-- ✅ Correcto (SOLO en postgres-pgvector/): Dimensión explícita + CHECK
CREATE TABLE embeddings (id UUID, vec vector(1536) CHECK (array_length(vec, 1) = 1536));
```
```sql
-- ❌ Anti-pattern (en cualquier contexto): Dimensión implícita
CREATE TABLE embeddings (id UUID, vec vector);  # ¿768? ¿1536? ¿384?
-- 🔧 Fix: Declarar vector(n) + CONSTRAINT CHECK para validación V1
```
> 📌 **Nota selectiva**: En `06-PROGRAMMING/sql/` está PROHIBIDO usar `vector(n)`. Usar tipos nativos de PostgreSQL.

### V2 – Distance Metric Explicit (Condicional)
```sql
-- ✅ Correcto (SOLO en postgres-pgvector/): Operador documentado y alineado con opclass
SELECT id FROM docs ORDER BY vec <=> $1 LIMIT 10;  -- <=> = cosine, coincide con vector_cosine_ops
```
```sql
-- ❌ Anti-pattern: Operador ambiguo o mismatch con índice
ORDER BY vec <-> $1;  -- ¿L2? ¿Cosine? ¿Índice usa cosine_ops?
-- 🔧 Fix: Comentar operador + alinear con opclass del índice: l2_ops↔<->, cosine_ops↔<=>, ip_ops↔<#>
```
> 📌 **Nota selectiva**: En archivos fuera de `postgres-pgvector/`, si se menciona "vector" debe ser como comentario documental, no como código ejecutable.

### V3 – Index-Type Match Justified (Condicional)
```sql
-- ✅ Correcto (SOLO en postgres-pgvector/): Parámetros de índice justificados por volumen/patrón
CREATE INDEX CONCURRENTLY idx_hnsw ON docs USING hnsw (vec vector_cosine_ops) WITH (m=16, ef_construction=100);
-- Comentario V3: m=16/ef=100 para <100k vectores en VPS 4GB
```
```sql
-- ❌ Anti-pattern: Índice con parámetros por defecto sin justificación
CREATE INDEX ON docs USING hnsw (vec);  # ¿Por qué hnsw? ¿Por qué no ivfflat?
-- 🔧 Fix: Documentar criterio de selección + parámetros explícitos con justificación V3
```
> 📌 **Nota selectiva**: En `sql/`, `yaml-json-schema/`, `go/`: prohibido crear índices con `USING hnsw/ivfflat`. Solo permitido en `postgres-pgvector/`.

---

## 🚫 PROHIBICIONES ABSOLUTAS (Violación = Abortar + Postmortem)

| Prohibición | Ámbito | Alternativa |
|-------------|--------|-------------|
| `print()` / `console.log()` en producción | **Todos** | `logger.info()` a `stderr` con JSON |
| `eval()` / `exec()` / `os.system()` | **Todos** | Funciones específicas + validación |
| `subprocess` / `fetch` sin timeout | **Todos** | `timeout=10` / `AbortSignal.timeout()` |
| `os.environ.get("KEY", "default")` para valores críticos | **Todos** | `os.environ["KEY"]` + `assert` |
| Variables globales para estado de tenant | **Todos** | `ContextVar` / `AsyncLocalStorage` |
| Concatenación de strings para SQL/paths | **Todos** | Query parametrizada / `pathlib.resolve()` |
| Imports sin `try/except` para deps no-stdlib | **Todos** | `try { await import() } catch` con fallback |
| Ejemplos >5 líneas ejecutables | **Todos** | Extraer helpers o dividir ejemplos |
| **`vector(n)`, `<->`, `<#>`, `<=>`, `hnsw`, `ivfflat` en `sql/`** | **LANGUAGE LOCK** | Mover a `postgres-pgvector/` |
| **SQL puro en `postgres-pgvector/` sin operadores vectoriales** | **LANGUAGE LOCK** | Mover a `sql/` |
| **Aplicar V1-V3 a artifacts no-vectoriales** | **SELECTIVE SCOPE** | Usar solo C1-C8 |

---

## 📦 FORMATO DE ENTREGA ESTÁNDAR (v3.0-SELECTIVE)

```markdown
# SHA256: <64-char hex simulado>
---
artifact_id: "<id-sin-extension>"
artifact_type: "skill_sql" | "skill_pgvector" | "skill_yaml" | "skill_go" | "skill_index"
version: "3.0.0"
constraints_mapped: ["C2","C3","C4", "V1", "V2"]  # Incluir V* SOLO si aplica
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file <path> --json"
canonical_path: "06-PROGRAMMING/<carpeta>/<filename>.<ext>.md"
---

# <Título del artifact>

## Propósito
<1-2 frases técnicas>

## Patrones de Código Validados

```sql
-- ✅ C4/V2: Descripción del constraint aplicado
<≤5 líneas ejecutables>
```

```sql
-- ❌ Anti-pattern: descripción de violación
<código incorrecto>
-- 🔧 Fix: solución corregida (≤5 líneas)
```

[Repetir para ≥10 ejemplos (≥25 si artifact_type == skill_pgvector)]

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file <path> --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"<id>","version":"3.0.0","score":<int>,"blocking_issues":[],"constraints_verified":["C2","C4","V1"],"examples_count":<int>,"lines_executable_max":5,"language":"PostgreSQL 14+ pgvector","timestamp":"<ISO8601-2026>"}
```

---
```

> 📌 **Regla de oro para `constraints_mapped`**: 
> - Si `artifact_type` es `skill_pgvector` → incluir V1/V2/V3 según uso real en código
> - Si `artifact_type` es `skill_sql`, `skill_yaml`, `skill_go` → **NUNCA** incluir V*; solo C1-C8 aplicables

---

## 🔍 PROTOCOLO DE VALIDACIÓN SELECTIVA

```bash
# 1. Detectar tipo de artifact
TYPE=$(grep '^artifact_type:' <file>.md | awk '{print $2}' | tr -d '"')

# 2. Si es skill_pgvector, validar V1-V3 + C1-C8
if [ "$TYPE" = "skill_pgvector" ]; then
  # Verificar que V* están en constraints_mapped si se usan operadores pgvector
  grep -q '<->\|<=>\|<#>\|vector(' <file>.md && \
  grep -q '"V[123]"' <file>.md || echo "❌ V-constraint missing for pgvector artifact"
fi

# 3. Si NO es skill_pgvector, verificar que NO hay fuga de operadores vectoriales
if [ "$TYPE" != "skill_pgvector" ]; then
  grep -qE '<->|<=>|<#>|vector\(|hnsw|ivfflat' <file>.md && \
  echo "❌ LANGUAGE LOCK violation: pgvector operators in $TYPE artifact" || echo "✅ No vector leak"
fi

# 4. Ejecutar orchestrator estándar (aplica a todos)
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file <file>.md --json
```

---

## 🔄 PROTOCOLO DE RECUPERACIÓN ANTE VIOLACIONES

```yaml
violacion_detectada:
  tipo: "CORE" | "VECTOR" | "LANGUAGE_LOCK"
  accion:
    - "Detener generación inmediatamente"
    - "Registrar en 08-LOGS/failed-attempts/postmortem-<timestamp>.md"
    - "Si CORE o LANGUAGE_LOCK: corregir y reintentar (máx. 3 iteraciones)"
    - "Si VECTOR en artifact no-pgvector: mover archivo a postgres-pgvector/ o eliminar operadores"
    - "Si persiste >2 violaciones: notificar a maintainer con diff + contexto"

score_umbrales:
  minimo_aprobatorio: 30
  optimo: 45
  accion_por_score:
    "<30": "RECHAZAR + postmortem"
    "30-44": "APROBAR con nota de mejora"
    ">=45": "APROBAR + marcar como referencia"
```

---

## 🗂️ MAPEO DE CARPETAS Y APLICACIÓN DE NORMAS

| Carpeta | artifact_type | C1-C8 | V1-V3 | Notas |
|---------|--------------|-------|-------|-------|
| `06-PROGRAMMING/sql/` | `skill_sql` | ✅ Obligatorio | ❌ Prohibido | SQL puro PostgreSQL 14+, sin pgvector |
| `06-PROGRAMMING/postgresql-pgvector/` | `skill_pgvector` | ✅ Obligatorio | ✅ Obligatorio si usa vectores | Único lugar permitido para operadores vectoriales |
| `06-PROGRAMMING/yaml-json-schema/` | `skill_yaml` | ✅ Obligatorio | ❌ No aplica | Validación de esquemas, sin lógica vectorial |
| `06-PROGRAMMING/go/` | `skill_go` | ✅ Obligatorio | ❌ No aplica | Servicios MCP, sin operadores SQL vectoriales |
| `05-CONFIGURATIONS/validation/` | `skill_bash` | ✅ Obligatorio | ❌ No aplica | Scripts de orquestación, sin lógica de dominio |
| `05-CONFIGURATIONS/terraform/` | `skill_terraform` | ✅ Obligatorio | ⚠️ Solo si despliega Qdrant/pgvector | V1-V3 aplican solo a recursos vectoriales explícitos |

---

## 🎯 CHECKLIST PRE-ENTREGA (Auto-verificación mental)

```text
[ ] ¿El artifact_type coincide con la carpeta? (LANGUAGE LOCK)
[ ] ¿constraints_mapped incluye V* SOLO si es skill_pgvector y usa operadores vectoriales?
[ ] ¿Cada ejemplo tiene ≤5 líneas ejecutables?
[ ] ¿Ejemplos count: ≥10 (general) o ≥25 (skill_pgvector)?
[ ] ¿Timestamp en JSON report es año 2026, formato ISO8601?
[ ] ¿Cierre con --- para parseo automatizado?
[ ] ¿SHA256 simulado en encabezado?
[ ] ¿Validation command apunta al path canónico correcto?
[ ] Si es skill_pgvector: ¿operadores <->/<= >/vector(n) están documentados con V2/V3?
[ ] Si NO es skill_pgvector: ¿CERO operadores vectoriales en código ejecutable?

Si alguna respuesta es NO → corregir antes de emitir artifact.
```

---

> **Nota final para el equipo**: Esta versión 3.0-SELECTIVE preserva el rigor de las normas CORE (C1-C8) para todos los artifacts, mientras introduce flexibilidad inteligente para las normas vectoriales (V1-V3). El objetivo es evitar sobreingeniería: no forzar complejidad vectorial donde no se necesita, pero mantener excelencia técnica donde sí aplica. La estructura de carpetas y el LANGUAGE LOCK son la barrera que hace posible esta selectividad sin sacrificar consistencia.

**Checksum simulado del documento**:  
`SHA256: e9f2a5c8b1d4e7a0f3c6b9d2e5a8c1b4d7e0a3f6c9b2d5e8a1f4c7b0d3e6a9c2`

---
✅ **HARNESS NORMS v3.0-SELECTIVE generado. Listo para reemplazar v2.0 en 01-RULES/.**
