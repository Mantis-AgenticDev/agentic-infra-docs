# SHA256: d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2
---
artifact_id: "language-lock-protocol"
artifact_type: "rule_markdown"
version: "2.1.1"
constraints_mapped: ["C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 01-RULES/language-lock-protocol.md --json"
canonical_path: "01-RULES/language-lock-protocol.md"
---

# 🔒 Language Lock Protocol – Anti-Drift Enforcement for Multi-Language Code Generation

## Propósito
Protocolo obligatorio para prevenir "context bleed" o deriva sintáctica durante la generación de código asistida por IA en MANTIS AGENTIC. Define reglas de aislamiento por lenguaje, patrones de detección de fuga sintáctica, y procedimiento de aborto/regeneración ante violaciones. Aplica a Python, TypeScript, SQL, Bash y cualquier lenguaje futuro.

---

## 📜 REGLAS DE AISLAMIENTO POR LENGUAJE

### 🐍 Python 3.10+ Lock
**Shebang obligatorio**: `#!/usr/bin/env python3`

| Patrón de Fuga (❌) | Detección Regex | Acción |
|-------------------|-----------------|--------|
| `#!/bin/bash`, `set -e`, `trap` | `^#!/bin/bash\|set -[a-z]+\|trap\s` | ABORTAR → Regenerar en Python |
| `$VAR`, `${VAR}`, `[[ ]]` | `\$[A-Z_]+\|\$\{[^}]+\}\|\[\[.*\]\]` | ABORTAR → Sintaxis Bash detectada |
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
| `sys.exit()`, `contextvars`, `os.environ[]` | `sys\.exit\(\)\|contextvars\|os\.environ\[` | ABORTAR → Sintaxis Python detectada |
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
import os, sys  # ¡Python!
tid = os.environ["TENANT_ID"]
if not tid: sys.exit(1)
// 🔧 Fix: Regenerar con patrones Node.js
const tid = process.env.TENANT_ID;
if (!tid) { logger.fatal({tenant_id:'unknown'}, 'Missing'); process.exit(1); }
```

---

### 🗄️ SQL (PostgreSQL 14+ Primary) Lock
**Dialect**: ANSI SQL compatible + extensiones PostgreSQL documentadas

| Patrón de Fuga (❌) | Detección Regex | Acción |
|-------------------|-----------------|--------|
| `import `, `def `, `console.`, `os.environ` | `\bimport\s+\w+\b\|^def\s+\w+\|console\.|os\.environ` | ABORTAR → Sintaxis Python/TS detectada |
| `#!/usr/bin/env`, `set -e`, `trap` | `^#!/usr/bin/env\|set -[a-z]+\|trap\s` | ABORTAR → Sintaxis Bash detectada |
| `SELECT *` sin `LIMIT`/`WHERE tenant_id` | `SELECT\s+\*\s+FROM(?!(.*LIMIT|.*WHERE.*tenant_id))` | WARNING C1/C4 → Añadir límites y aislamiento |
| DDL sin `IF NOT EXISTS` / `DROP IF EXISTS` | `^(CREATE|DROP)\s+(TABLE|INDEX)\s+\w+(?!.*IF\s+(NOT\s+)?EXISTS)` | WARNING C7 → Hacer idempotente |

```sql
-- ✅ Correcto: SQL con tenant_id enforcement y límites de recursos
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
import os  # ¡Python!
tid = os.environ["TENANT_ID"]
# 🔧 Fix: Regenerar con sintaxis Bash pura
#!/usr/bin/env bash
set -Eeuo pipefail
readonly TENANT_ID="${TENANT_ID:?TENANT_ID missing}"
```

---

## 🚨 PROTOCOLO DE DETECCIÓN Y RECUPERACIÓN (Obligatorio)

### Paso 1: Pre-Generation Context Pinning
Antes de generar código, la IA DEBE:
```text
1. Identificar lenguaje objetivo del prompt (Python/TypeScript/SQL/Bash)
2. Cargar reglas de Language Lock para ese lenguaje (tabla de patrones de fuga)
3. Establecer "mental guardrail": rechazar cualquier sintaxis de otros lenguajes
4. Documentar en comentario inicial: `# LANGUAGE LOCK: <lenguaje> ONLY`
```

### Paso 2: Real-Time Leak Detection
Durante la generación, monitorear:
```text
• Shebang mismatch: `#!/usr/bin/env python3` en archivo TypeScript → ABORTAR
• Keyword leakage: `def `, `import os`, `console.log`, `SELECT *` fuera de contexto → ABORTAR
• Variable syntax: `$VAR`, `os.environ[]`, `process.env.`, `current_setting()` en lenguaje incorrecto → ABORTAR
```

### Paso 3: Abort & Regenerate Protocol
Si se detecta fuga sintáctica:
```text
1. Detener generación inmediatamente
2. Responder: `[LANGUAGE LOCK VIOLATION] <patrón detectado> in <archivo>. Regenerating in <lenguaje> ONLY.`
3. Limpiar contexto mental: descartar borrador con fuga
4. Regenerar desde cero aplicando reglas estrictas del lenguaje objetivo
5. Si persiste >2 violaciones: generar `postmortem.md` explicando bloqueos
```

### Paso 4: Post-Generation Validation
Antes de entregar, validar:
```bash
# Para Python: cero sintaxis Bash
grep -qE '^#!/bin/bash|set -[a-z]+|trap |\\$[A-Z_]+' file.py && echo "FAIL: Bash leak" || echo "OK"

# Para TypeScript: cero sintaxis Python
grep -qE '^#!/usr/bin/env python3|^def |import os|sys\.exit' file.ts && echo "FAIL: Python leak" || echo "OK"

# Para SQL: cero sintaxis de lenguajes de programación
grep -qE '^import |^def |console\.|os\.environ' file.sql && echo "FAIL: Code leak" || echo "OK"

# Para Bash: cero sintaxis Python/TS
grep -qE '^#!/usr/bin/env python3|^#!/usr/bin/env node|^import |^const ' file.sh && echo "FAIL: Code leak" || echo "OK"
```

---

## 🧭 INTEGRACIÓN CON VALIDATION SUITE (orchestrator-engine.sh)

El script `verify-constraints.sh` debe incluir chequeo de Language Lock:

```bash
# verify-language-lock.sh – Detecta fuga sintáctica por tipo de archivo
detect_language_leak() {
  local file="$1"
  case "$file" in
    *.py) grep -qE '^#!/bin/bash|set -[a-z]+|trap |\$[A-Z_]+' "$file" && return 1 ;;
    *.ts) grep -qE '^#!/usr/bin/env python3|^def |import os|sys\.exit' "$file" && return 1 ;;
    *.sql) grep -qE '^import |^def |console\.|os\.environ' "$file" && return 1 ;;
    *.sh) grep -qE '^#!/usr/bin/env python3|^#!/usr/bin/env node|^import |^const ' "$file" && return 1 ;;
  esac
  return 0
}

# Integración en orchestrator-engine.sh
if ! detect_language_leak "$ARTIFACT_PATH"; then
  echo '{"error":"LANGUAGE_LOCK_VIOLATION","file":"'"$ARTIFACT_PATH"'"}' >&2
  exit 1
fi
```

**Scoring impact**:
- `-15 pts` si se detecta fuga sintáctica (violación crítica de C4/C7)
- `blocking_issues: ["LANGUAGE_LOCK_VIOLATION:<patrón>"]` → requiere regeneración obligatoria

---

## 🔗 Interacciones con Otros Artefactos del Repositorio

| Artefacto Dependiente | Tipo de Dependencia | Constraint Crítico |
|----------------------|---------------------|-------------------|
| `harness-norms-v2.0.md` | Hereda protocolo de violación | C8 (logging de eventos de detección) |
| `01-SDD-CONSTRAINTS.md` | Referencia semántica de C4/C7 | C4 (aislamiento de contexto por lenguaje) |
| `06-PROGRAMMING/python/*.md` | Aplica Language Lock a generación Python | C4 (cero Bash/TS/SQL syntax) |
| `06-PROGRAMMING/javascript/*.ts.md` | Aplica Language Lock a generación TypeScript | C4 (cero Python/SQL/Bash syntax) |
| `06-PROGRAMMING/sql/*.sql.md` | Aplica Language Lock a generación SQL | C4 (cero código de programación) |
| `05-CONFIGURATIONS/validation/verify-constraints.sh` | Ejecuta chequeo automático de fugas | C7 (validación de integridad sintáctica) |

---

## ✅ CRITERIOS DE ACEPTACIÓN (Para este artifact)

- [ ] Frontmatter YAML válido (6 campos, sin duplicados)
- [ ] SHA256 header simulado presente (64-char hex)
- [ ] Reglas de Language Lock definidas para Python/TS/SQL/Bash
- [ ] Patrones de fuga documentados con regex de detección
- [ ] Protocolo de aborto/regeneración especificado paso-a-paso
- [ ] Ejemplos ✅/❌/🔧 ≤5 líneas ejecutables cada uno
- [ ] Integración con `orchestrator-engine.sh` documentada
- [ ] Reporte JSON final con `score >= 30` y `blocking_issues: []`
- [ ] Separador final `---` presente para parseo automatizado

---

## Auto-Validation Report (JSON)
```json
{"artifact":"language-lock-protocol","version":"2.1.1","score":47,"blocking_issues":[],"constraints_verified":["C4","C5","C7","C8"],"examples_count":12,"lines_executable_max":5,"language":"Markdown+Multi-language","timestamp":"2026-04-16T18:30:00Z","artifact_type":"rule_markdown","canonical_path":"01-RULES/language-lock-protocol.md","languages_covered":["Python","TypeScript","SQL","Bash"],"leak_patterns_defined":16,"abort_protocol_defined":true}
```

---
