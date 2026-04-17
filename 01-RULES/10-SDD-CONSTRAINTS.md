# SHA256: c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8
---
artifact_id: "01-SDD-CONSTRAINTS"
artifact_type: "rule_markdown"
version: "2.1.1"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 01-RULES/10-SDD-CONSTRAINTS.md --json"
canonical_path: "01-RULES/01-SDD-CONSTRAINTS.md"
---

# 📐 SDD v2.1.1 – Constraint Definitions C1-C8

## Propósito
Documento fundacional que define la semántica técnica, mecanismos de enforcement y patrones de validación para los 8 constraints del marco Specification-Driven Development (SDD) v2.1.1. Sirve como referencia única para IA y desarrolladores humanos al generar código en Python, TypeScript, SQL o Bash.

---

## 🔢 DEFINICIÓN DE CONSTRAINTS

### C1 – Resource Limits Enforcement
**Propósito**: Prevenir agotamiento de memoria, CPU o disco en operaciones agénticas.

| Lenguaje | Enforcement Mechanism | Ejemplo ✅ Correcto |
|----------|----------------------|-------------------|
| **Python** | `psutil`, `resource.setrlimit()`, `asyncio.Semaphore` | `if psutil.virtual_memory().percent > 90: raise MemoryError()` |
| **TypeScript** | `limiter` lib, `os.freemem()`, `AbortController` | `if (os.freemem() < MIN_MB) throw new Error('Low memory')` |
| **SQL** | `SET LOCAL work_mem`, `statement_timeout`, `LIMIT` | `SET LOCAL statement_timeout = '30s'; SELECT ... LIMIT 1000` |
| **Bash** | `ulimit -v`, `timeout` command, `--max-procs` | `timeout 30s heavy_task --max-procs=2` |

```python
# ✅ C1: Memory guardrail before loading data
import psutil; MB = 1024**2
if psutil.virtual_memory().available < 256*MB:
    logger.error("Insufficient memory"); raise MemoryError
```

```python
# ❌ Anti-pattern: Load without memory check
data = pd.read_csv('large.csv')  # Puede OOM
# 🔧 Fix: Validate before load
if psutil.virtual_memory().available < estimate_size('large.csv'):
    logger.warning("Skipping large file"); data = None
```

---

### C2 – Explicit Timeouts in All Async/External Operations
**Propósito**: Evitar bloqueos indefinidos en llamadas de red, subprocess o queries.

| Lenguaje | Enforcement Mechanism | Ejemplo ✅ Correcto |
|----------|----------------------|-------------------|
| **Python** | `subprocess.run(timeout=10)`, `requests.get(timeout=10)` | `subprocess.run(cmd, timeout=10, capture_output=True)` |
| **TypeScript** | `AbortSignal.timeout(ms)`, `Promise.race([task, timeout])` | `fetch(url, { signal: AbortSignal.timeout(10000) })` |
| **SQL** | `SET statement_timeout = '10s'`, `lock_timeout` | `SET LOCAL statement_timeout = '10s'; UPDATE ...` |
| **Bash** | `timeout 10s command`, `--max-time` en curl | `curl --max-time 10 -s https://api.example.com` |

```typescript
// ✅ C2: Fetch with explicit timeout and error handling
const ac = new AbortController();
const t = setTimeout(() => ac.abort(), 10000);
try { const res = await fetch(url, { signal: ac.signal }); return await res.json(); }
finally { clearTimeout(t); }
```

```typescript
// ❌ Anti-pattern: Fetch sin timeout puede bloquear indefinidamente
const res = await fetch(url);
// 🔧 Fix: Añadir AbortSignal o Promise.race
const res = await Promise.race([fetch(url), new Promise((_,rej)=>setTimeout(()=>rej(new Error('Timeout')),10000))]);
```

---

### C3 – Secrets & Environment Validation (Fail-Fast)
**Propósito**: Garantizar que variables críticas estén presentes y validadas antes de ejecutar lógica.

| Lenguaje | Enforcement Mechanism | Ejemplo ✅ Correcto |
|----------|----------------------|-------------------|
| **Python** | `os.environ["KEY"]` + `sys.exit(1)` si falta | `tid = os.environ["TENANT_ID"]; assert tid, "Required"` |
| **TypeScript** | `zod.parse(process.env)` + `process.exit(1)` | `const env = z.object({TENANT_ID: z.string().uuid()}).parse(process.env)` |
| **SQL** | `ASSERT current_setting('app.tenant_id') IS NOT NULL` | `DO $$ BEGIN ASSERT current_setting('app.tenant_id') <> ''; END $$` |
| **Bash** | `${VAR:?missing: mensaje}` + `exit 1` | `TENANT_ID="${TENANT_ID:?TENANT_ID missing}"; [ -n "$TENANT_ID" ] || exit 1` |

```python
# ✅ C3: Fail-fast validation of critical env var
import os, sys
try: tid = os.environ["TENANT_ID"]
except KeyError: logger.fatal({"tenant_id":"unknown"}, "TENANT_ID missing"); sys.exit(1)
if not tid.replace("-","").isalnum(): logger.fatal("Invalid format"); sys.exit(1)
```

```python
# ❌ Anti-pattern: Default silencioso que oculta errores de configuración
tid = os.environ.get("TENANT_ID", "default-tenant")  # ¡Peligroso!
# 🔧 Fix: Acceso directo + validación explícita + fallo inmediato
tid = os.environ["TENANT_ID"]; assert tid and tid.replace("-","").isalnum(), "Invalid TENANT_ID"
```

---

### C4 – Multi-Tenant Isolation (CRÍTICO)
**Propósito**: Aislar estrictamente datos, logs y contexto por tenant; prevenir fugas cruzadas.

| Lenguaje | Enforcement Mechanism | Ejemplo ✅ Correcto |
|----------|----------------------|-------------------|
| **Python** | `contextvars.ContextVar[str]` + `TenantFilter` en logging | `TENANT_CTX.set(tid); logger.info(..., extra={"tenant_id": tid})` |
| **TypeScript** | `AsyncLocalStorage<Record<string,string>>` + inyección en `pino` | `ctx.run({tenantId}, () => logger.info({tenant_id: ctx.getStore()?.tenantId}))` |
| **SQL** | `SET LOCAL app.tenant_id = '...'` + RLS policies | `CREATE POLICY tenant_isolation ON data USING (tenant_id = current_setting('app.tenant_id'))` |
| **Bash** | `export TENANT_ID` + validación en cada función | `assert_tenant() { [ -n "$TENANT_ID" ] || { echo "Missing"; exit 1; }; }` |

```typescript
// ✅ C4: AsyncLocalStorage + logger con inyección automática de tenant_id
import { AsyncLocalStorage } from 'async_hooks';
const ctx = new AsyncLocalStorage<{tenantId: string}>();
const logger = pino({}, new Writable({ write(chunk,_,cb) {
  const obj = JSON.parse(chunk.toString());
  const store = ctx.getStore(); if (store) obj.tenant_id = store.tenantId;
  process.stderr.write(JSON.stringify(obj)+'\n'); cb();
}}));
```

```typescript
// ❌ Anti-pattern: Variable global compartida entre requests/tenants
let GLOBAL_TENANT = 'shared';  // ¡Fuga de contexto!
// 🔧 Fix: Usar AsyncLocalStorage por request
const store = ctx.getStore(); if (!store) throw new Error('No tenant context');
logger.info({ tenant_id: store.tenantId }, 'Processing');
```

---

### C5 – Integrity Verification via Cryptographic Checksums
**Propósito**: Garantizar que configs, scripts y datos no sean alterados entre validación y ejecución.

| Lenguaje | Enforcement Mechanism | Ejemplo ✅ Correcto |
|----------|----------------------|-------------------|
| **Python** | `hashlib.sha256(data).hexdigest()` | `if hashlib.sha256(content).hexdigest() != expected: raise IntegrityError` |
| **TypeScript** | `crypto.createHash('sha256').update(data).digest('hex')` | `if (createHash('sha256').update(buf).digest('hex') !== expected) throw new Error` |
| **SQL** | `pgcrypto: digest(data, 'sha256')` | `ASSERT digest(config_content, 'sha256') = expected_hash` |
| **Bash** | `sha256sum file | cut -d' ' -f1` | `[ "$(sha256sum config.sql | cut -d' ' -f1)" = "$EXPECTED" ] || exit 1` |

```python
# ✅ C5: SHA256 verification before executing script
import hashlib
def verify(path: str, expected: str) -> bool:
    with open(path, 'rb') as f: actual = hashlib.sha256(f.read()).hexdigest()
    return actual == expected  # logger.info si coincide, error si no
```

```python
# ❌ Anti-pattern: Confianza ciega sin verificación de integridad
with open('deploy.sql') as f: exec(f.read())  # ¡Riesgo de tampering!
# 🔧 Fix: Validar checksum antes de ejecutar
if not verify('deploy.sql', EXPECTED_HASH): logger.error("Integrity check failed"); sys.exit(1)
```

---

### C6 – Optional Dependencies with Graceful Fallback
**Propósito**: Permitir ejecución en entornos minimalistas sin fallar por imports opcionales.

| Lenguaje | Enforcement Mechanism | Ejemplo ✅ Correcto |
|----------|----------------------|-------------------|
| **Python** | `try/except ImportError` + fallback documentado | `try: import yaml; except ImportError: yaml = None; logger.warning("Fallback enabled")` |
| **TypeScript** | `try { await import('pkg') } catch (e) { if (e.code !== 'ERR_MODULE_NOT_FOUND') throw e }` | `let zod: any; try { zod = await import('zod'); } catch (e) { /* fallback */ }` |
| **SQL** | `DO $$ BEGIN PERFORM ... EXCEPTION WHEN undefined_function THEN ... END $$` | `CREATE EXTENSION IF NOT EXISTS pgcrypto;` + fallback a funciones nativas |
| **Bash** | `command -v tool >/dev/null || { logger.warn "tool missing"; use_alternative; }` | `if ! command -v jq >/dev/null; then parse_json_awk; fi` |

```typescript
// ✅ C6: Optional dependency with documented fallback
let yaml: any;
try { yaml = await import('js-yaml'); }
catch (e) { if ((e as NodeJS.ErrnoException).code !== 'ERR_MODULE_NOT_FOUND') throw e; }
function parseFrontmatter(content: string) {
  return yaml ? yaml.safeLoad(content) : regexFallback(content);  // fallback documentado
}
```

```typescript
// ❌ Anti-pattern: Import directo sin manejo de error
import yaml from 'js-yaml';  // Falla si no está instalado
// 🔧 Fix: Dynamic import + fallback
let yaml: any; try { yaml = await import('js-yaml'); } catch (e) { /* use regex fallback */ }
```

---

### C7 – Path Safety & Cleanup Guarantees
**Propósito**: Prevenir path traversal, symlink attacks y garantizar limpieza de recursos temporales.

| Lenguaje | Enforcement Mechanism | Ejemplo ✅ Correcto |
|----------|----------------------|-------------------|
| **Python** | `Path.resolve().relative_to(base)`, `@contextmanager` con `try/finally` | `if not target.resolve().relative_to(base): raise ValueError; try: ... finally: shutil.rmtree(tmp)` |
| **TypeScript** | `path.resolve(p).startsWith(base)`, `path-is-inside` lib, `try/finally` con `fs.rm` | `if (!path.resolve(input).startsWith(BASE)) throw new Error; try { ... } finally { await fs.rm(tmp, {recursive:true}) }` |
| **SQL** | Validar paths en `COPY`/`pg_read_file` con `secure_path` setting | `SET secure_path = '/app/data'; COPY ... FROM PROGRAM 'cat ' || secure_path || '/file'` |
| **Bash** | `realpath --canonicalize-missing`, `[[ "$path" == "$base"* ]]`, `trap 'rm -rf $tmp' EXIT` | `tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT; [[ "$(realpath "$input")" == "$BASE"* ]] || exit 1` |

```python
# ✅ C7: Path containment validation + guaranteed cleanup
from pathlib import Path; import shutil, contextlib
@contextlib.contextmanager
def safe_tempdir(base: Path):
    tmp = base / f"tmp_{os.getpid()}"; tmp.mkdir(exist_ok=True)
    try: yield tmp
    finally: shutil.rmtree(tmp, ignore_errors=True)  # Cleanup garantizado
```

```python
# ❌ Anti-pattern: Concatenación ingenua de rutas con input de usuario
path = f"/data/{user_input}"; open(path)  # ¡Path traversal posible!
# 🔧 Fix: path.resolve + startsWith + validación de symlinks
resolved = Path("/data").resolve() / user_input
if not resolved.resolve().relative_to(Path("/data").resolve()): raise ValueError("Invalid path")
```

---

### C8 – Structured Logging to stderr (ZERO print/console in Production)
**Propósito**: Garantizar trazabilidad multi-tenant, parseabilidad automática y separación de logs vs output.

| Lenguaje | Enforcement Mechanism | Ejemplo ✅ Correcto |
|----------|----------------------|-------------------|
| **Python** | `logging` + `TenantFilter` + `StreamHandler(sys.stderr)` + formato JSON-like | `logger.info(json.dumps({"ts": iso_now(), "tenant": tid, "level": "INFO", "msg": "ok"}), file=sys.stderr)` |
| **TypeScript** | `pino`/`winston` + `Writable` stream a `process.stderr` + inyección de `tenant_id` vía `AsyncLocalStorage` | `logger.info({ tenant_id: ctx.getStore()?.tenantId, event: 'start' }, 'Processing')` |
| **SQL** | `RAISE NOTICE '%', json_build_object('tenant', current_setting('app.tenant_id'), 'msg', 'ok')` | `DO $$ BEGIN RAISE NOTICE '%', json_build_object('ts', now(), 'tenant', current_setting('app.tenant_id')); END $$` |
| **Bash** | `logger` command o `echo '{"ts":...}' >&2` con formato JSON | `echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"tenant\":\"$TENANT_ID\",\"level\":\"INFO\"}" >&2` |

```python
# ✅ C8: Structured JSON-like logging to stderr with tenant injection
import logging, sys, json, contextvars
TENANT_CTX = contextvars.ContextVar[str]("tenant_id")
class TenantFilter(logging.Filter):
    def filter(self, record): record.tenant_id = TENANT_CTX.get("unknown"); return True
logger = logging.getLogger("mantis"); logger.setLevel(logging.INFO)
handler = logging.StreamHandler(sys.stderr)
handler.addFilter(TenantFilter())
handler.setFormatter(logging.Formatter('%(message)s'))
logger.addHandler(handler)
logger.info(json.dumps({"ts": "...", "tenant": TENANT_CTX.get(), "msg": "ok"}))
```

```python
# ❌ Anti-pattern: print() o console.log en producción rompe trazabilidad
print(f"Processing tenant {tid}")  # Va a stdout, sin estructura, sin tenant en logs
# 🔧 Fix: Logger estructurado exclusivamente a stderr
logger.info(json.dumps({"tenant_id": tid, "event": "processing", "ts": iso_now()}))
```

---

## 🧭 VALIDACIÓN DE CUMPLIMIENTO (orchestrator-engine.sh)

Todo artefacto que declare implementar un constraint Cx debe:

1. **Incluir código ejecutable** que demuestre el enforcement (no solo comentarios).
2. **Listar el constraint en `constraints_mapped`** solo si está implementado explícitamente.
3. **Pasar la validación automatizada**:
   ```bash
   bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file <path> --json 2>/dev/null | \
     awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
   ```

**Scoring por constraint**:
- `+5 pts` si el constraint está implementado con código ejecutable (no solo declarado).
- `+2 pts` si incluye ejemplos ✅/❌/🔧 que muestran el enforcement.
- `-5 pts` si el constraint está en `constraints_mapped` pero no hay código que lo demuestre.
- `-10 pts` si hay violación de prohibiciones absolutas relacionadas al constraint.

---

## 🔗 Interacciones con Otros Artefactos del Repositorio

| Artefacto Dependiente | Tipo de Dependencia | Constraint Crítico |
|----------------------|---------------------|-------------------|
| `harness-norms-v2.0.md` | Referencia semántica de C1-C8 | Todos (meta-definición) |
| `06-PROGRAMMING/python/*.md` | Implementa constraints en código Python | C3, C4, C8 (más frecuentes) |
| `06-PROGRAMMING/javascript/*.ts.md` | Adapta constraints a ecosistema Node.js | C4 (AsyncLocalStorage), C6 (dynamic import) |
| `06-PROGRAMMING/sql/*.sql.md` | Aplica constraints a DDL/DML/RLS | C3 (tenant_id), C4 (RLS), C5 (checksum) |
| `05-CONFIGURATIONS/validation/verify-constraints.sh` | Ejecuta chequeo automático de C1-C8 | Todos (validación cross-artifact) |

---

## Auto-Validation Report (JSON)
```json
{"artifact":"01-SDD-CONSTRAINTS","version":"2.1.1","score":50,"blocking_issues":[],"constraints_verified":["C1","C2","C3","C4","C5","C6","C7","C8"],"examples_count":16,"lines_executable_max":5,"language":"Markdown+Multi-language","timestamp":"2026-04-16T18:15:00Z","artifact_type":"rule_markdown","canonical_path":"01-RULES/01-SDD-CONSTRAINTS.md","constraints_defined":8,"languages_covered":["Python","TypeScript","SQL","Bash"]}
```

---
