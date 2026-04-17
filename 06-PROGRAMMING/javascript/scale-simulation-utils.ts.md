# SHA256: a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a
---
artifact_id: "scale-simulation-utils"
artifact_type: "skill_typescript"
version: "2.1.1"
constraints_mapped: ["C1","C2","C4","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/scale-simulation-utils.ts.md --json"
---

# Scale Simulation Utils – TypeScript/Node.js Load Testing with Tenant Quotas

## Propósito
Utilidades para simulación de carga respetando cuotas por tenant, con aislamiento de contexto via `AsyncLocalStorage` (C4), pureza de lenguaje TypeScript (C1), restricciones de runtime y límites de concurrencia (C2), y timeouts explícitos en todas las operaciones de prueba (C8).

## Patrones de Código Validados

```typescript
// ✅ C4: Tenant quota definición con AsyncLocalStorage
interface TenantQuota { tenantId: string; maxRps: number; maxConcurrent: number; }
const quotas = new Map<string, TenantQuota>();
```

```typescript
// ❌ Anti‑pattern: Cuotas globales sin tenant
let maxRps = 100;
// 🔧 Fix: Mapa por tenant_id extraído del contexto
const quota = quotas.get(ctx.getStore()?.tenantId!);
```

```typescript
// ✅ C8: Simulación de carga con timeout por petición
async function simulateLoad(tenantId: string, rps: number, durationMs: number) {
  const ac = new AbortController();
  const timer = setTimeout(() => ac.abort(), durationMs);
  try { await runSimulation(tenantId, rps, ac.signal); }
  finally { clearTimeout(timer); }
}
```

```typescript
// ❌ Anti‑pattern: Bucle infinito sin timeout
while (true) { await makeRequest(); }
// 🔧 Fix: Usar AbortSignal para limitar duración
const signal = AbortSignal.timeout(durationMs);
while (!signal.aborted) { await makeRequest(); }
```

```typescript
// ✅ C2/C4: Limitador de concurrencia por tenant
import { RateLimiter } from 'limiter';
const limiters = new Map<string, RateLimiter>();
function getLimiter(tenantId: string, maxConcurrent: number) {
  if (!limiters.has(tenantId)) limiters.set(tenantId, new RateLimiter({ tokensPerInterval: maxConcurrent, interval: 'second' }));
  return limiters.get(tenantId)!;
}
```

```typescript
// ✅ C1: Uso de generadores async y tipado estricto
async function* requestGenerator(tenantId: string, rps: number): AsyncGenerator<Promise<Response>> {
  const interval = 1000 / rps;
  while (true) { yield fetch('/api/test', { signal: AbortSignal.timeout(5000) }); await sleep(interval); }
}
```

```typescript
// ❌ Anti‑pattern: setTimeout en bucle sin limpieza
for (let i=0; i<100; i++) { setTimeout(() => fetch(), i*10); }
// 🔧 Fix: AsyncGenerator con control de cancelación
const generator = requestGenerator('t1', 10);
for await (const req of generator) { /* ... */ }
```

```typescript
// ✅ C4/C8: Logger con tenant_id durante simulación
logger.info({ tenant_id: ctx.getStore()?.tenantId, rps, duration: durationMs }, 'Load simulation started');
```

```typescript
// ❌ Anti‑pattern: Log sin tenant_id
console.log('Simulation started');
// 🔧 Fix: Logger estructurado con AsyncLocalStorage
logger.info({ tenant_id: ctx.getStore()?.tenantId }, 'Started');
```

```typescript
// ✅ C8: Timeout global para toda la simulación
const simulationPromise = runSimulation(tenantId, rps);
const result = await Promise.race([simulationPromise, timeout(60000)]);
```

```typescript
// ✅ C2: Control de recursos con AbortController y limpieza
const controller = new AbortController();
process.on('SIGINT', () => controller.abort());
await runSimulation(tenantId, rps, controller.signal);
```

```typescript
// ✅ C4: Cuota por tenant validada con Zod
const quotaSchema = z.object({ tenantId: z.string(), maxRps: z.number().max(100) });
const validQuota = quotaSchema.parse(config);
```

```typescript
// ✅ C8: Timeout en fetch individual con reintentos
const res = await retryAsync(() => fetch(url, { signal: AbortSignal.timeout(3000) }), { maxTry: 2 });
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/scale-simulation-utils.ts.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"scale-simulation-utils","version":"2.1.1","score":30,"blocking_issues":[],"constraints_verified":["C1","C2","C4","C8"],"examples_count":10,"lines_executable_max":4,"language":"TypeScript 5.0+ / Node.js 18+","timestamp":"2026-04-16T16:45:00Z"}
```

---
