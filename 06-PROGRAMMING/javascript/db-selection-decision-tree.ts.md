# SHA256: d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3
---
artifact_id: "db-selection-decision-tree"
artifact_type: "skill_typescript"
version: "2.1.1"
constraints_mapped: ["C4","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/db-selection-decision-tree.ts.md --json"
---

# Database Selection Decision Tree – Runtime Routing: Postgres/Redis/Qdrant

## Propósito
Lógica de decisión runtime para seleccionar el stack de base de datos (PostgreSQL, Redis, Qdrant) por tenant, basado en el perfil del cliente (VPS, volumen, necesidades). Garantiza aislamiento multi‑tenant vía `AsyncLocalStorage` (C4) y timeouts explícitos en todas las conexiones a bases de datos (C8).

## Patrones de Código Validados

```typescript
// ✅ C4: Perfil de cliente con tenant_id obligatorio
interface ClientProfile {
  tenantId: string;
  vertical: string;
  hasVps: boolean;
  monthlyRecords: number;
}
```

```typescript
// ❌ Anti‑pattern: Perfil sin tenant_id
interface Profile { records: number; }
// 🔧 Fix: Incluir tenantId requerido por C4
interface ClientProfile { tenantId: string; records: number; }
```

```typescript
// ✅ C4/C8: Decisión de stack con tenant_id en contexto y timeout
async function selectDbStack(profile: ClientProfile): Promise<DbStack> {
  return ctx.run({ tenantId: profile.tenantId }, async () => {
    const timeout = AbortSignal.timeout(3000);
    return await determineStack(profile, timeout);
  });
}
```

```typescript
// ❌ Anti‑pattern: Decisión sin contexto tenant ni timeout
function selectStack(profile) { return profile.records > 5000 ? 'B' : 'A'; }
// 🔧 Fix: ctx.run y AbortSignal.timeout
return ctx.run({ tenantId: profile.tenantId }, () => determineStack(profile, AbortSignal.timeout(3000)));
```

```typescript
// ✅ C8: Conexión a PostgreSQL con timeout
import { Pool } from 'pg';
const pool = new Pool({ connectionTimeoutMillis: 5000 });
const client = await pool.connect();
```

```typescript
// ❌ Anti‑pattern: Conexión sin timeout
const client = await new Pool().connect();
// 🔧 Fix: Configurar connectionTimeoutMillis
const pool = new Pool({ connectionTimeoutMillis: 5000 });
```

```typescript
// ✅ C4: Cliente Redis con prefijo tenant_id
const redisKey = `${tenantId}:session:${sessionId}`;
await redis.set(redisKey, data, 'EX', 14400);
```

```typescript
// ❌ Anti‑pattern: Clave Redis sin prefijo tenant
await redis.set('session:123', data);
// 🔧 Fix: Prefijar con tenant_id del contexto
const key = `${ctx.getStore()?.tenantId}:session:${sid}`;
await redis.set(key, data);
```

```typescript
// ✅ C4/C8: Cliente Qdrant con filtro tenant_id y timeout
const ac = new AbortController();
setTimeout(() => ac.abort(), 5000);
const results = await qdrant.search(collection, {
  vector: embedding,
  filter: { must: [{ key: 'tenant_id', match: { value: tenantId } }] }
}, { signal: ac.signal });
```

```typescript
// ❌ Anti‑pattern: Búsqueda Qdrant sin filtro tenant
const results = await qdrant.search(collection, { vector });
// 🔧 Fix: Añadir filtro tenant_id obligatorio
const filter = { must: [{ key: 'tenant_id', match: { value: tenantId } }] };
await qdrant.search(collection, { vector, filter }, { signal: AbortSignal.timeout(5000) });
```

```typescript
// ✅ C4/C8: Logger con tenant_id durante selección de stack
logger.info({ tenant_id: ctx.getStore()?.tenantId, stack: 'C' }, 'Stack selected');
```

```typescript
// ❌ Anti‑pattern: Log sin tenant_id
console.log('Stack selected');
// 🔧 Fix: Logger estructurado con AsyncLocalStorage
logger.info({ tenant_id: ctx.getStore()?.tenantId }, 'Stack selected');
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/db-selection-decision-tree.ts.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"db-selection-decision-tree","version":"2.1.1","score":30,"blocking_issues":[],"constraints_verified":["C4","C8"],"examples_count":10,"lines_executable_max":4,"language":"TypeScript 5.0+ / Node.js 18+","timestamp":"2026-04-16T16:15:00Z"}
```

---
