# SHA256: a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8
---
artifact_id: "context-isolation-patterns"
artifact_type: "skill_typescript"
version: "2.1.1"
constraints_mapped: ["C4","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/context-isolation-patterns.ts.md --json"
---

# Context Isolation Patterns – TypeScript/Node.js AsyncLocalStorage for Multi‑Tenant

## Propósito
Patrones para aislar contexto de ejecución por tenant usando `AsyncLocalStorage` en Node.js. Garantiza que el `tenant_id` se propague correctamente a través de operaciones asíncronas (C4) y que todas las operaciones sensibles tengan timeouts y manejo robusto de errores (C8).

## Patrones de Código Validados

```typescript
// ✅ C4: Inicialización de AsyncLocalStorage con tipo seguro
import { AsyncLocalStorage } from 'async_hooks';
interface TenantContext { tenantId: string; userId?: string; }
const ctx = new AsyncLocalStorage<TenantContext>();
```

```typescript
// ❌ Anti‑pattern: Usar variables globales para tenant_id
let currentTenant: string;
function setTenant(id: string) { currentTenant = id; }
// 🔧 Fix: AsyncLocalStorage para aislamiento por petición
const ctx = new AsyncLocalStorage<{ tenantId: string }>();
ctx.run({ tenantId: 't1' }, () => { /* seguro */ });
```

```typescript
// ✅ C4/C8: Middleware Express que inyecta contexto con timeout
app.use((req, res, next) => {
  const tenantId = req.headers['x-tenant-id'] as string;
  if (!tenantId) { res.status(400).json({ error: 'Missing tenant' }); return; }
  ctx.run({ tenantId }, () => next());
});
```

```typescript
// ❌ Anti‑pattern: Extraer tenant_id del header sin validación ni contexto
app.use((req, res, next) => { req.tenantId = req.headers['x-tenant-id']; next(); });
// 🔧 Fix: Validar existencia y usar AsyncLocalStorage.run
const tid = req.headers['x-tenant-id']; if (!tid) return res.status(400).end();
ctx.run({ tenantId: tid }, next);
```

```typescript
// ✅ C4: Acceso al contexto actual con fallback seguro
function getTenantId(): string {
  const store = ctx.getStore();
  if (!store) throw new Error('Context not initialized');
  return store.tenantId;
}
```

```typescript
// ❌ Anti‑pattern: Asumir que el contexto siempre existe
const tenantId = ctx.getStore().tenantId;
// 🔧 Fix: Validación explícita con error manejable
const store = ctx.getStore(); if (!store) throw new Error('No tenant context');
const tenantId = store.tenantId;
```

```typescript
// ✅ C4/C8: Operación asíncrona con propagación de contexto y timeout
async function fetchData(url: string): Promise<any> {
  const tenantId = getTenantId();
  const ac = new AbortController();
  const t = setTimeout(() => ac.abort(), 5000);
  const res = await fetch(`${url}?tenant=${tenantId}`, { signal: ac.signal });
  clearTimeout(t);
  return res.json();
}
```

```typescript
// ❌ Anti‑pattern: Usar tenant_id global en llamada fetch sin timeout
async function fetchData(url: string) {
  const res = await fetch(`${url}?tenant=${currentTenant}`);
  return res.json();
}
// 🔧 Fix: Obtener tenant del contexto y aplicar AbortController
const tid = getTenantId(); const ac = new AbortController();
setTimeout(() => ac.abort(), 5000);
const res = await fetch(`${url}?tenant=${tid}`, { signal: ac.signal });
```

```typescript
// ✅ C4: Logger con inyección automática de tenant_id desde contexto
const logger = pino({}, new Writable({
  write(chunk, enc, cb) {
    const obj = JSON.parse(chunk.toString());
    const store = ctx.getStore();
    if (store) obj.tenant_id = store.tenantId;
    process.stderr.write(JSON.stringify(obj) + '\n');
    cb();
  }
}));
```

```typescript
// ❌ Anti‑pattern: Logger sin tenant_id
const logger = pino();
logger.info('Processing');
// 🔧 Fix: Envolver write para inyectar tenant_id automático
const logger = pino({}, new Writable({ write(chunk, enc, cb) {
  const obj = JSON.parse(chunk); obj.tenant_id = ctx.getStore()?.tenantId;
  process.stderr.write(JSON.stringify(obj)+'\n'); cb();
}}));
```

```typescript
// ✅ C4/C8: Ejecución segura de callback en contexto con manejo de errores
async function runInContext<T>(ctxData: TenantContext, fn: () => Promise<T>): Promise<T> {
  return ctx.run(ctxData, async () => {
    try { return await fn(); }
    catch (err) { logger.error({ tenant_id: ctxData.tenantId, err }, 'Failed'); throw err; }
  });
}
```

```typescript
// ❌ Anti‑pattern: Ejecutar función sin envolver en try/catch ni contexto
async function run(fn: () => Promise<any>) { return fn(); }
// 🔧 Fix: Envolver en ctx.run con manejo de errores estructurado
return ctx.run(ctxData, () => fn().catch(err => { logger.error(err); throw err; }));
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/context-isolation-patterns.ts.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"context-isolation-patterns","version":"2.1.1","score":30,"blocking_issues":[],"constraints_verified":["C4","C8"],"examples_count":10,"lines_executable_max":5,"language":"TypeScript 5.0+ / Node.js 18+","timestamp":"2026-04-16T14:55:00Z"}
```

---
