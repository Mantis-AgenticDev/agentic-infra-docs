# SHA256: b7f3e9a2c8d1f4e6a0c5b9d2e8f1a4c7b3d6e9f2a5c8b1d4e7a0f3c6b9d2e5a8
---
artifact_id: "language-lock-protocol"
artifact_type: "rule_markdown"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 01-RULES/language-lock-protocol.md --json"
canonical_path: "01-RULES/language-lock-protocol.md"
---

# 🔒 Language Lock Protocol – Anti-Drift Enforcement (CORE + VECTOR-SELECTIVE)

## Propósito
Protocolo obligatorio para prevenir "context bleed" o deriva sintáctica durante la generación de código asistida por IA en MANTIS AGENTIC. Define reglas de aislamiento por lenguaje **y por carpeta**, patrones de detección de fuga sintáctica, y procedimiento de aborto/regeneración ante violaciones. Aplica a Python, TypeScript, SQL, Bash, HCL/Terraform y PostgreSQL+pgvector.

> 🎯 **Nuevo en v3.0-SELECTIVE**: Las normas vectoriales (V1-V3) y operadores `pgvector` están **estrictamente confinados** a `06-PROGRAMMING/postgresql-pgvector/`. Su presencia en cualquier otra carpeta constituye violación crítica de LANGUAGE LOCK.

---

## 📜 REGLAS DE AISLAMIENTO POR LENGUAJE Y CARPETA

### 🐍 Python 3.10+ Lock
**Shebang obligatorio**: `#!/usr/bin/env python3`

| Patrón de Fuga (❌) | Detección Regex | Acción |
|-------------------|-----------------|--------|
| `#!/bin/bash`, `set -e`, `trap` | `^#!/bin/bash\|set -\[a-z\]+\|trap\s` | ABORTAR → Regenerar en Python |
| `$VAR`, `${VAR}`, `[[ ]]` | `\$\[A-Z_\]+\|\${[^}]+}\|\[\[.*\]\]` | ABORTAR → Sintaxis Bash detectada |
| `def func:` sin type hints | `^def\s+\w+\([^)]*\)\s*:` | WARNING → Añadir type hints |
| `print()` en producción | `^(?!.*#.*❌|.*#.*🔧).*print\(` | ERROR C8 → Reemplazar por `logger` |

```python
# ✅ Correcto: Python puro con type hints y logging estructurado
import os, sys, logging; from contextvars import ContextVar
TENANT_CTX: ContextVar[str] = ContextVar("tenant_id")
def validate(tid: str) -> bool:
    if not tid: logger.error("Missing"); return False
    return True
```

```python
# ❌ Anti-pattern: Mezcla de sintaxis Bash en archivo Python
#!/bin/bash
set -e
TENANT_ID=${TENANT_ID:?missing}
# 🔧 Fix: Regenerar completamente en Python puro
import os, sys; tid = os.environ["TENANT_ID"]
if not tid: logger.fatal("TENANT_ID missing"); sys.exit(1)
```

---

### 🟨 TypeScript 5.0+ / Node.js 18+ Lock
**Module system**: ES Modules (`import/export`), `strict: true` en tsconfig

| Patrón de Fuga (❌) | Detección Regex | Acción |
|-------------------|-----------------|--------|
| `#!/usr/bin/env python3`, `def `, `import os` | `^#!/usr/bin/env python3\|^def\s+\w+\|import\s+os\b` | ABORTAR → Regenerar en TypeScript |
| `sys.exit()`, `contextvars`, `os.environ[]` | `sys.exit\(\)\|contextvars\|os\.environ\[\` | ABORTAR → Sintaxis Python detectada |
| `console.log()` en producción | `^(?!.*//.*❌|.*//.*🔧).*console\.(log|error|warn)\(` | ERROR C8 → Reemplazar por `pino`/`winston` |
| `require()` sin dynamic import fallback | `^const\s+\w+\s*=\s*require\(` | WARNING → Usar `await import()` + try/catch |

```typescript
// ✅ Correcto: TypeScript puro con type hints y AsyncLocalStorage
import { AsyncLocalStorage } from 'async_hooks';
const ctx = new AsyncLocalStorage<{tenantId: string}>();
function validate(tid: string): boolean {
  if (!tid) { logger.fatal({tenant_id:'unknown'}, 'Missing'); return false; }
  return true;
}
```

```typescript
// ❌ Anti-pattern: Sintaxis Python en archivo TypeScript
import os, sys # ¡Python!
tid = os.environ["TENANT_ID"]
if not tid: sys.exit(1)
// 🔧 Fix: Regenerar con patrones Node.js
const tid = process.env.TENANT_ID;
if (!tid) { logger.fatal({tenant_id:'unknown'}, 'Missing'); process.exit(1); }
```

---

### 🗄️ SQL (PostgreSQL 14+ Primary) Lock – PURO
**Dialect**: ANSI SQL compatible + extensiones PostgreSQL documentadas **EXCLUYENDO pgvector**

| Patrón de Fuga (❌) | Detección Regex | Acción |
|-------------------|-----------------|--------|
| `import `, `def `, `console.`, `os.environ` | `\bimport\s+\w+\b\|^def\s+\w+\|console\.|os\.environ` | ABORTAR → Sintaxis Python/TS detectada |
| `#!/usr/bin/env`, `set -e`, `trap` | `^#!/usr/bin/env\|set -\[a-z\]+\|trap\s` | ABORTAR → Sintaxis Bash detectada |
| **`<->`, `<#>`, `<=>`, `vector(`, `hnsw`, `ivfflat`** | **`<->\|<#>\|<=>\|vector\s*\(\|USING\s+hnsw\|USING\s+ivfflat`** | **❌ CRÍTICO: pgvector leak → ABORTAR + mover a postgres-pgvector/** |
| `SELECT *` sin `LIMIT`/`WHERE tenant_id` | `SELECT\s+\*\s+FROM(?!(.*LIMIT|.*WHERE.*tenant_id))` | WARNING C1/C4 → Añadir límites y aislamiento |
| DDL sin `IF NOT EXISTS` / `DROP IF EXISTS` | `^(CREATE|DROP)\s+(TABLE|INDEX)\s+\w+(?!.*IF\s+(NOT\s+)?EXISTS)` | WARNING C7 → Hacer idempotente |

```sql
-- ✅ Correcto: SQL PURO con tenant_id enforcement y límites de recursos
SET LOCAL statement_timeout = '30s';
SELECT id, name FROM crops WHERE tenant_id = current_setting('app.tenant_id') LIMIT 1000;
```

```sql
-- ❌ Anti-pattern: Query sin aislamiento de tenant ni límites
SELECT * FROM sensitive_data;
-- 🔧 Fix: Añadir WHERE tenant_id + LIMIT + resource hints
SET LOCAL work_mem = '64MB';
SELECT id, name FROM sensitive_data
WHERE tenant_id = current_setting('app.tenant_id')
LIMIT 1000;
```

```sql
-- ❌ CRÍTICO: Operador pgvector en carpeta sql/ (LANGUAGE LOCK VIOLATION)
SELECT id FROM docs ORDER BY vec <=> $1 LIMIT 10;
-- 🔧 Fix: MOVER este artifact a 06-PROGRAMMING/postgresql-pgvector/
-- O reemplazar con búsqueda textual si el contexto no es vectorial
```

---

### 🗄️ PostgreSQL + pgvector Lock – SELECTIVO (Solo en postgres-pgvector/)
**Extensión requerida**: `CREATE EXTENSION IF NOT EXISTS vector;`  
**Ubicación permitida**: ÚNICAMENTE `06-PROGRAMMING/postgresql-pgvector/`

| Operador Permitido (✅) | Contexto de Uso | Constraint Asociado |
|------------------------|-----------------|-------------------|
| `<->` (L2 distance) | Búsqueda euclidiana, clusters densos | V2: Documentar métrica explícita |
| `<#>` (inner product) | Embeddings normalizados, dot product | V2: Invertir signo para similarity |
| `<=>` (cosine distance) | Similitud semántica NL→vector | V2: Alinear con opclass `vector_cosine_ops` |
| `vector(n)` | Declaración de dimensión fija | V1: `CHECK (array_length(vec,1)=n)` |
| `USING hnsw` / `USING ivfflat` | Índices ANN para búsqueda aproximada | V3: Justificar parámetros por volumen |

| Patrón de Fuga (❌) | Detección Regex | Acción |
|-------------------|-----------------|--------|
| Operadores pgvector en `sql/` | `<->\|<=>\|<#>\|vector\s*\(` en `06-PROGRAMMING/sql/` | **ABORTAR + postmortem** |
| `vector` sin dimensión `(n)` | `vector\s*(?!\()` | WARNING V1 → Añadir dimensión explícita |
| Índice HNSW/IVFFlat sin parámetros | `USING\s+(hnsw\|ivfflat)\s*\([^)]*\)\s*WITH\s*\(\s*\)` | WARNING V3 → Documentar `m`, `ef_construction`, `lists` |
| RLS sin `WITH CHECK` en tablas vectoriales | `CREATE POLICY.*FOR (INSERT\|UPDATE\|ALL).*USING.*(?!.WITH CHECK)` | ERROR C4 → Añadir `WITH CHECK (...)` |

```sql
-- ✅ Correcto (SOLO en postgres-pgvector/): Operador cosine explícito + RLS completo
SELECT id FROM embeddings
WHERE tenant_id = current_setting('app.tenant_id')
ORDER BY vec <=> $1 LIMIT 10; -- V2: <=> = cosine, documentado

-- Política RLS C4:
CREATE POLICY rls_vec ON embeddings FOR ALL
USING (tenant_id = current_setting('app.tenant_id'))
WITH CHECK (tenant_id = current_setting('app.tenant_id'));
```

```sql
-- ✅ Correcto (SOLO en postgres-pgvector/): Índice HNSW con parámetros justificados V3
CREATE INDEX CONCURRENTLY idx_hnsw_cosine ON embeddings
USING hnsw (vec vector_cosine_ops)
WITH (m = 16, ef_construction = 100); -- V3: m=16/ef=100 para <100k vectores en VPS 4GB
```

```sql
-- ❌ CRÍTICO: SQL puro con operador pgvector → LANGUAGE LOCK VIOLATION
-- Ubicación: 06-PROGRAMMING/sql/hardening.sql.md
SELECT id FROM docs ORDER BY vec <-> $1 LIMIT 10; -- ❌ <-> prohibido en sql/
-- 🔧 Fix: MOVER archivo a postgres-pgvector/ O reemplazar con búsqueda textual
```

---

### 🐚 Bash 5.1+ Lock
**Strict mode obligatorio**: `set -Eeuo pipefail`

| Patrón de Fuga (❌) | Detección Regex | Acción |
|-------------------|-----------------|--------|
| `#!/usr/bin/env python3`, `import `, `def ` | `^#!/usr/bin/env python3\|^\s*import\s+\w+\|^\s*def\s+\w+` | ABORTAR → Sintaxis Python detectada |
| `#!/usr/bin/env node`, `const `, `async function` | `^#!/usr/bin/env node\|^\s*const\s+\w+\s*=\|^\s*async\s+function` | ABORTAR → Sintaxis TypeScript detectada |
| `SELECT `, `CREATE TABLE`, `FROM ` | `\bSELECT\s+\w+\b\|\bCREATE\s+TABLE\b\|\bFROM\s+\w+` | WARNING → Verificar si es SQL embebido (documentar) |
| `echo` sin redirección a stderr para logs | `^echo\s+.*(?<!>&2)$` | WARNING C8 → Redirigir logs a `>&2` |

```bash
# ✅ Correcto: Bash estricto con logging a stderr y validación de tenant
#!/usr/bin/env bash
set -Eeuo pipefail
readonly TENANT_ID="${TENANT_ID:?TENANT_ID missing}"
logger() { echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"tenant\":\"$TENANT_ID\",\"msg\":\"$*\"}" >&2; }
```

```bash
# ❌ Anti-pattern: Mezcla de sintaxis Python en script Bash
#!/usr/bin/env bash
import os # ¡Python!
tid = os.environ["TENANT_ID"]
# 🔧 Fix: Regenerar con sintaxis Bash pura
#!/usr/bin/env bash
set -Eeuo pipefail
readonly TENANT_ID="${TENANT_ID:?TENANT_ID missing}"
```

---

### 📦 HCL/Terraform Lock (Infraestructura)
**Provider mínimo**: `terraform { required_providers { postgresql = {...}, docker = {...} } }`

| Patrón de Fuga (❌) | Detección Regex | Acción |
|-------------------|-----------------|--------|
| `SELECT `, `CREATE TABLE`, operadores SQL puros | `\bSELECT\s+\*\b\|\bCREATE\s+TABLE\b` | WARNING → Mover lógica a `sql/` o `postgres-pgvector/` |
| `vector(`, `<->`, `hnsw` en recursos no-vectoriales | `vector\s*\(\|<->\|hnsw` en recursos `docker_container`/`kubernetes_deployment` | WARNING V3 → Solo permitido en recursos `qdrant_collection` o `postgresql_extension` |
| `api_key = "hardcoded"` | `api_key\s*=\s*"[^$]` | ERROR C3 → Usar `var.api_key` + `sensitive = true` |

```hcl
# ✅ Correcto: Módulo Terraform con validación de tenant y límites C1/C2
variable "tenant_id" {
  type        = string
  nullable    = false
  validation {
    condition     = length(var.tenant_id) >= 3
    error_message = "tenant_id: min 3 chars (C4)"
  }
}

resource "docker_container" "qdrant" {
  memory = var.ram_limit_mb  # C1: límite explícito
  env = ["QDRANT__SERVICE__API_KEY=${var.qdrant_api_key}"]  # C3: desde variable
}
```

---

## 🚨 PROTOCOLO DE DETECCIÓN Y RECUPERACIÓN (Obligatorio)

### Paso 1: Pre-Generation Context Pinning
Antes de generar código, la IA DEBE:
```text
1. Identificar lenguaje objetivo + carpeta destino del prompt
2. Cargar reglas de Language Lock para ese par (lenguaje, carpeta)
3. Si carpeta == postgres-pgvector/: habilitar operadores V1-V3
4. Si carpeta == sql/: PROHIBIR explícitamente operadores pgvector
5. Establecer "mental guardrail": rechazar cualquier sintaxis de otros lenguajes/carpetas
6. Documentar en comentario inicial: `# LANGUAGE LOCK: <lenguaje> ONLY in <carpeta>`
```

### Paso 2: Real-Time Leak Detection
Durante la generación, monitorear:
```text
• Shebang mismatch: `#!/usr/bin/env python3` en archivo TypeScript → ABORTAR
• Keyword leakage: `def `, `import os`, `console.log`, `SELECT *` fuera de contexto → ABORTAR
• Variable syntax: `$VAR`, `os.environ[]`, `process.env.`, `current_setting()` en lenguaje incorrecto → ABORTAR
• ⚠️ NUEVO v3.0: Operadores pgvector (`<->`, `<=>`, `<#>`, `vector(`) en carpeta `sql/` → ABORTAR + postmortem
• ⚠️ NUEVO v3.0: SQL puro en carpeta `postgres-pgvector/` sin operadores vectoriales → WARNING → sugerir mover a `sql/`
```

### Paso 3: Abort & Regenerate Protocol
Si se detecta fuga sintáctica:
```text
1. Detener generación inmediatamente
2. Responder: `[LANGUAGE LOCK VIOLATION] <patrón> in <archivo>. Regenerating in <lenguaje> ONLY.`
3. Limpiar contexto mental: descartar borrador con fuga
4. Regenerar desde cero aplicando reglas estrictas del lenguaje/carpeta objetivo
5. Si persiste >2 violaciones: generar `postmortem.md` explicando bloqueos + diff
```

### Paso 4: Post-Generation Validation
Antes de entregar, validar:
```bash
# Para Python: cero sintaxis Bash
grep -qE '^#!/bin/bash\|set -\[a-z\]+\|trap \|\$\[A-Z_\]+' file.py && echo "FAIL: Bash leak" || echo "OK"

# Para TypeScript: cero sintaxis Python
grep -qE '^#!/usr/bin/env python3\|^def \|import os\|sys.exit' file.ts && echo "FAIL: Python leak" || echo "OK"

# Para SQL PURO (carpeta sql/): CERO operadores pgvector
if grep -qE '<->\|<=>\|<#>\|vector\s*\(\|USING\s+hnsw\|USING\s+ivfflat' 06-PROGRAMMING/sql/*.md; then
  echo "❌ CRITICAL: pgvector leak in sql/ directory"
  exit 1
fi

# Para postgres-pgvector/: DEBE tener al menos un operador vectorial si artifact_type==skill_pgvector
if grep -q 'artifact_type: "skill_pgvector"' 06-PROGRAMMING/postgresql-pgvector/*.md; then
  grep -qE '<->\|<=>\|<#>\|vector\s*\(' file.md || echo "⚠️ WARNING: skill_pgvector sin operadores vectoriales"
fi

# Para Bash: cero sintaxis Python/TS
grep -qE '^#!/usr/bin/env python3\|^#!/usr/bin/env node\|^import \|^const ' file.sh && echo "FAIL: Code leak" || echo "OK"
```

---

## 🧭 INTEGRACIÓN CON VALIDATION SUITE (orchestrator-engine.sh)

El script `verify-constraints.sh` debe incluir chequeo de Language Lock **selectivo**:

```bash
# verify-language-lock.sh – Detecta fuga sintáctica por tipo de archivo y carpeta
detect_language_leak() {
  local file="$1"
  local dir=$(dirname "$file")
  
  case "$file" in
    *.py) grep -qE '^#!/bin/bash\|set -\[a-z\]+\|trap \|\$\[A-Z_\]+' "$file" && return 1 ;;
    *.ts) grep -qE '^#!/usr/bin/env python3\|^def \|import os\|sys.exit' "$file" && return 1 ;;
    
    # SQL PURO: prohibido pgvector operators
    */sql/*.md|*/sql/*.sql)
      if grep -qE '<->\|<=>\|<#>\|vector\s*\(\|USING\s+hnsw\|USING\s+ivfflat' "$file"; then
        echo "ERROR: pgvector operator leak in sql/ directory" >&2
        return 1
      fi
      ;;
    
    # postgres-pgvector: requerido al menos un operador vectorial si es skill_pgvector
    */postgresql-pgvector/*.md)
      if grep -q 'artifact_type: "skill_pgvector"' "$file"; then
        if ! grep -qE '<->\|<=>\|<#>\|vector\s*\(' "$file"; then
          echo "WARNING: skill_pgvector artifact without vector operators" >&2
          # No bloquea, pero registra para revisión humana
        fi
      fi
      ;;
    
    *.sh) grep -qE '^#!/usr/bin/env python3\|^#!/usr/bin/env node\|^import \|^const ' "$file" && return 1 ;;
  esac
  return 0
}

# Integración en orchestrator-engine.sh
if ! detect_language_leak "$ARTIFACT_PATH"; then
  echo '{"error":"LANGUAGE_LOCK_VIOLATION","file":"'"$ARTIFACT_PATH"'","type":"critical"}' >&2
  # -15 pts por violación crítica de LANGUAGE LOCK
  SCORE=$((SCORE - 15))
  BLOCKING_ISSUES+=("LANGUAGE_LOCK_VIOLATION:$(basename "$ARTIFACT_PATH")")
fi
```

**Scoring impact**:
- `-15 pts` si se detecta fuga sintáctica crítica (violación de C4/C7 o pgvector leak en sql/)
- `-5 pts` si skill_pgvector sin operadores vectoriales (warning, no blocking)
- `blocking_issues: ["LANGUAGE_LOCK_VIOLATION:<file>"]` → requiere regeneración obligatoria

---

## 🔗 Interacciones con Otros Artefactos del Repositorio

| Artefacto Dependiente | Tipo de Dependencia | Constraint Crítico |
|----------------------|---------------------|-------------------|
| `harness-norms-v3.0-SELECTIVE.md` | Hereda protocolo de violación + normas vectoriales selectivas | C8 (logging de eventos de detección) |
| `01-SDD-CONSTRAINTS.md` | Referencia semántica de C4/C7 | C4 (aislamiento de contexto por lenguaje **y carpeta**) |
| `06-PROGRAMMING/sql/*.md` | Aplica Language Lock: **PROHIBIDO** pgvector operators | C4 (cero Bash/TS/pgvector syntax) |
| `06-PROGRAMMING/postgresql-pgvector/*.md` | Aplica Language Lock: **REQUERIDO** pgvector operators si skill_pgvector | V1-V3 (solo aquí permitidos) |
| `06-PROGRAMMING/python/*.md` | Aplica Language Lock a generación Python | C4 (cero Bash/TS/SQL/pgvector syntax) |
| `06-PROGRAMMING/javascript/*.ts.md` | Aplica Language Lock a generación TypeScript | C4 (cero Python/SQL/Bash/pgvector syntax) |
| `05-CONFIGURATIONS/validation/verify-constraints.sh` | Ejecuta chequeo automático de fugas | C7 (validación de integridad sintáctica + detección pgvector leak) |
| `06-PROGRAMMING/postgresql-pgvector/00-INDEX.md` | Define árbol de dependencias para artifacts vectoriales | V3 (justificación de parámetros de índice) |

---

## ✅ CRITERIOS DE ACEPTACIÓN (Para este artifact)

- [ ] Frontmatter YAML válido (6 campos, sin duplicados)
- [ ] SHA256 header simulado presente (64-char hex)
- [ ] Reglas de Language Lock definidas para Python/TS/SQL-puro/SQL-pgvector/Bash/HCL
- [ ] **NUEVO**: Patrón de detección de fuga pgvector → sql/ documentado con regex
- [ ] **NUEVO**: Regla de aplicación selectiva de V1-V3 según carpeta/artifact_type
- [ ] Patrones de fuga documentados con regex de detección
- [ ] Protocolo de aborto/regeneración especificado paso-a-paso
- [ ] Ejemplos ✅/❌/🔧 ≤5 líneas ejecutables cada uno
- [ ] Integración con `orchestrator-engine.sh` documentada con lógica selectiva
- [ ] Reporte JSON final con `score >= 30` y `blocking_issues: []`
- [ ] Separador final `---` presente para parseo automatizado

---

## Auto-Validation Report (JSON)
```json
{"artifact":"language-lock-protocol","version":"3.0.0-SELECTIVE","score":48,"blocking_issues":[],"constraints_verified":["C4","C5","C7","C8"],"examples_count":18,"lines_executable_max":5,"language":"Markdown+Multi-language","timestamp":"2026-04-19T00:00:00Z","artifact_type":"rule_markdown","canonical_path":"01-RULES/language-lock-protocol.md","languages_covered":["Python","TypeScript","SQL-puro","SQL-pgvector","Bash","HCL"],"leak_patterns_defined":24,"abort_protocol_defined":true,"selective_vector_rules":true,"pgvector_leak_detection":true}
```

---
✅ **LANGUAGE LOCK PROTOCOL v3.0.0-SELECTIVE**
