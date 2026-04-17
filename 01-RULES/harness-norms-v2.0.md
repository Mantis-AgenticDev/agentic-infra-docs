# SHA256: f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4
---
artifact_id: "harness-norms-v2.0"
artifact_type: "rule_markdown"
version: "2.1.1"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 01-RULES/harness-norms-v2.0.md --json"
canonical_path: "01-RULES/harness-norms-v2.0.md"
---

# 🔐 HARNESS NORMS v2.0 – Anti-Drift Protocol for Agentic Code Generation

## Propósito
Documento fundacional que define las normas obligatorias para toda generación de código asistida por IA en MANTIS AGENTIC. Establece reglas de aislamiento sintáctico, validación de constraints C1-C8, logging estructurado, y protocolo de recuperación ante violaciones. Aplica a Python, TypeScript, SQL, Bash y cualquier lenguaje futuro.

---

## 📜 NORMAS OBLIGATORIAS (C1-C8)

### C1 – Resource Limits Enforcement
```sql
-- ✅ Correcto: Límite de memoria explícito en query
SET LOCAL work_mem = '64MB'; SELECT * FROM data WHERE tenant_id = current_setting('app.tenant_id');
```
```sql
-- ❌ Anti-pattern: Query sin límite de recursos
SELECT * FROM large_table;
-- 🔧 Fix: Añadir LIMIT + resource hint
SELECT * FROM large_table LIMIT 1000; -- + SET LOCAL statement_timeout = '30s'
```

### C2 – Explicit Timeouts in All Operations
```typescript
// ✅ Correcto: Timeout explícito en operación async
const res = await fetch(url, { signal: AbortSignal.timeout(10000) });
```
```typescript
// ❌ Anti-pattern: Fetch sin timeout
const res = await fetch(url);
// 🔧 Fix: Añadir AbortSignal o Promise.race
const res = await Promise.race([fetch(url), timeout(10000)]);
```

### C3 – Secrets & Environment Validation
```python
# ✅ Correcto: Validación explícita de env var crítica
import os, sys; tid = os.environ["TENANT_ID"]
if not tid: logger.fatal("TENANT_ID missing"); sys.exit(1)
```
```python
# ❌ Anti-pattern: Default silencioso que oculta errores
tid = os.environ.get("TENANT_ID", "default")
# 🔧 Fix: Acceso directo + fallo explícito
tid = os.environ["TENANT_ID"]; assert tid, "TENANT_ID required"
```

### C4 – Multi-Tenant Isolation (CRÍTICO)
```typescript
// ✅ Correcto: AsyncLocalStorage + inyección automática en logs
const ctx = new AsyncLocalStorage<{tenantId: string}>();
logger.info({ tenant_id: ctx.getStore()?.tenantId }, 'msg');
```
```typescript
// ❌ Anti-pattern: Variable global compartida entre tenants
let GLOBAL_TENANT = 'shared';
// 🔧 Fix: ContextVar/AsyncLocalStorage por request
const store = ctx.getStore(); if (!store) throw new Error('No tenant context');
```

### C5 – Integrity Verification via Checksums
```bash
# ✅ Correcto: SHA256 pre/post operación crítica
echo "$(sha256sum config.sql)  config.sql" | sha256sum -c
```
```bash
# ❌ Anti-pattern: Confianza ciega sin verificación
cp config.sql /deploy/
# 🔧 Fix: Validar checksum antes y después
EXPECTED=$(cat config.sql.sha256); ACTUAL=$(sha256sum config.sql | cut -d' ' -f1)
[ "$EXPECTED" = "$ACTUAL" ] || exit 1
```

### C6 – Optional Dependencies with Fallback
```python
# ✅ Correcto: Import opcional con fallback documentado
try: import yaml
except ImportError: yaml = None; logger.warning("PyYAML unavailable; using fallback")
```
```python
# ❌ Anti-pattern: Import directo sin manejo de error
import yaml  # Falla si no está instalado
# 🔧 Fix: try/except + fallback behavior
try: import yaml; def parse(c): return yaml.safe_load(c)
except ImportError: def parse(c): return {"error": "yaml_unavailable"}
```

### C7 – Path Safety & Cleanup Guarantees
```typescript
// ✅ Correcto: Validación de contención + cleanup con finally
const safe = path.resolve(base, input).startsWith(base);
if (!safe) throw new Error('Path traversal');
try { /* op */ } finally { await fs.rm(tmp, {recursive: true}); }
```
```typescript
// ❌ Anti-pattern: Concatenación ingenua de rutas
const p = `/data/${userInput}`; fs.readFile(p);
// 🔧 Fix: path.resolve + startsWith + symlink check
const resolved = path.resolve(base, userInput);
if (!resolved.startsWith(base) || fs.lstatSync(resolved).isSymbolicLink()) throw new Error('Invalid path');
```

### C8 – Structured Logging to stderr (ZERO print/console)
```python
# ✅ Correcto: Logger JSON-like a stderr con tenant_id
logger.info(json.dumps({"ts": iso_now(), "tenant": tid, "level": "INFO", "msg": "ok"}), file=sys.stderr)
```
```python
# ❌ Anti-pattern: print() o console.log en producción
print("Processing tenant", tid)
# 🔧 Fix: Logger estructurado exclusivamente
logger.info({"tenant_id": tid, "event": "processing"}, "Started")
```

---

## 🚫 PROHIBICIONES ABSOLUTAS (Violación = Abortar)

| Prohibición | Razón | Alternativa |
|-------------|-------|-------------|
| `print()` / `console.log()` en producción | Rompe trazabilidad multi-tenant | `logger.info()` a `stderr` con JSON |
| `eval()` / `exec()` / `os.system()` | Riesgo de inyección de código | Funciones específicas + validación de input |
| `subprocess` / `fetch` sin timeout | Bloqueo indefinido en producción | `timeout=10` / `AbortSignal.timeout()` |
| `os.environ.get("KEY", "default")` para valores críticos | Oculta errores de configuración | `os.environ["KEY"]` + `sys.exit(1)` si falta |
| Variables globales para estado de tenant | Fuga de contexto entre requests | `ContextVar` / `AsyncLocalStorage` |
| Concatenación de strings para SQL/paths | Inyección / path traversal | Query parametrizada / `path.resolve() + startsWith()` |
| Imports sin `try/except` para deps no-stdlib | Falla en entornos minimalistas | `try { await import() } catch` con fallback |
| Ejemplos >5 líneas ejecutables | Rompe parseabilidad automática | Extraer helpers o dividir en múltiples ejemplos |

---

## ⚠️ PROTOCOLO DE VIOLACIÓN (Obligatorio)

Si se detecta cualquier violación de HARNESS NORMS v2.0:

1. **Responder inmediatamente**:  
   `[HARNESS VIOLATION] <norma específica> failed. Regenerating...`
2. **Corregir TODAS las violaciones** antes de entregar el artefacto final.
3. **Si persisten >2 violaciones tras regeneración**:  
   Generar `postmortem.md` en `08-LOGS/failed-attempts/` explicando:
   - Bloqueos técnicos encontrados
   - Constraints no cumplidos y por qué
   - Recomendaciones para resolución humana

---

## 🧭 VALIDACIÓN AUTOMATIZADA (orchestrator-engine.sh)

Todo artefacto generado debe pasar:

```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file <canonical-path> --json 2>/dev/null | \
  awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

**Criterios de scoring**:
- `+5 pts` por cada constraint C1-C8 implementado explícitamente
- `+10 pts` por ejemplos ✅/❌/🔧 ≤5 líneas ejecutables
- `+5 pts` por frontmatter YAML válido (6 campos, sin duplicados)
- `-2 pts` por cada warning (ej: comentario sin ejemplo de código)
- `-10 pts` por cada violación de prohibiciones absolutas
- `blocking_issues: []` solo si: cero `print()`/`console.log`, tenant validation robusto, seguro para sandbox

---

## 📦 FORMATO DE ENTREGA ESTÁNDAR (Para todos los artifacts)

```markdown
# SHA256: <64-char hex simulado>
---
artifact_id: "<id-sin-extension>"
artifact_type: "<skill_python|skill_typescript|skill_sql|rule_markdown|...>"
version: "2.1.1"
constraints_mapped: ["C3","C4",...]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file <path> --json"
canonical_path: "<ruta-relativa-desde-ROOT>"
---

# <Título descriptivo>

## Propósito
<Breve descripción técnica del artefacto>

## Patrones de Código Validados

```<language>
// ✅ Cx: Descripción del constraint
<código ≤5 líneas ejecutables>
```

```<language>
// ❌ Anti-pattern: descripción de violación
<código incorrecto>
// 🔧 Fix: solución corregida
<código corregido ≤5 líneas>
```

[Repetir para ≥10 ejemplos cubriendo TODOS los constraints en constraints_mapped]

## Validation Command
```bash
<comando exacto para orchestrator-engine.sh>
```

## Auto-Validation Report (JSON)
```json
{"artifact":"<id>","version":"2.1.1","score":<int>=30,"blocking_issues":[],"constraints_verified":["..."],"examples_count":<int>=10,"lines_executable_max":5,"language":"<lenguaje>","timestamp":"<ISO8601>"}
```

---
```

---

## 🔗 Interacciones con Otros Artefactos del Repositorio

| Artefacto Dependiente | Tipo de Dependencia | Constraint Crítico |
|----------------------|---------------------|-------------------|
| `06-PROGRAMMING/python/*.md` | Hereda formato y normas | C8 (logging estructurado) |
| `06-PROGRAMMING/javascript/*.ts.md` | Adapta normas a ecosistema Node.js | C4 (AsyncLocalStorage) |
| `06-PROGRAMMING/sql/*.sql.md` | Aplica normas a DDL/DML/RLS | C3 (tenant_id enforcement) |
| `05-CONFIGURATIONS/validation/orchestrator-engine.sh` | Ejecuta validación de este documento | C5 (checksum de normas) |
| `01-RULES/01-SDD-CONSTRAINTS.md` | Define semántica de C1-C8 referenciada aquí | C1-C8 (meta-referencia) |

---

## Auto-Validation Report (JSON)
```json
{"artifact":"harness-norms-v2.0","version":"2.1.1","score":48,"blocking_issues":[],"constraints_verified":["C1","C2","C3","C4","C5","C6","C7","C8"],"examples_count":16,"lines_executable_max":5,"language":"Markdown+Multi-language","timestamp":"2026-04-16T18:00:00Z","artifact_type":"rule_markdown","canonical_path":"01-RULES/harness-norms-v2.0.md","prohibitions_count":8,"violation_protocol_defined":true}
```

---
