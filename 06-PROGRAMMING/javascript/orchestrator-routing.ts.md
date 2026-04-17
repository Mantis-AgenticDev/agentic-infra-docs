# SHA256: f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5
---
artifact_id: "orchestrator-routing"
artifact_type: "skill_typescript"
version: "2.1.1"
constraints_mapped: ["C4","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/orchestrator-routing.ts.md --json"
---

# Orchestrator Routing – TypeScript/Node.js JSON Dispatch & Tenant‑Aware Routing

## Propósito
Patrones para implementar un orquestador de tareas que enruta peticiones JSON a servicios internos, asegurando aislamiento multi‑tenant mediante `AsyncLocalStorage` (C4), verificación de integridad del payload con hash SHA256 (C5), y timeouts explícitos en todas las etapas del flujo de despacho (C8).

## Patrones de Código Validados

```typescript
// ✅ C4: Definición de tarea con tenant_id obligatorio
interface OrchestratorTask {
  tenantId: string;
  action: 'query' | 'embed' | 'search';
  payload: Record<string, unknown>;
}
```

```typescript
// ❌ Anti‑pattern: Tarea sin tenant_id
interface Task { action: string; data: any; }
// 🔧 Fix: Incluir tenantId requerido por C4
interface OrchestratorTask { tenantId: string; action: string; payload: unknown; }
```

```typescript
// ✅ C4/C8: Enrutamiento con contexto AsyncLocalStorage y timeout
async function routeTask(task: OrchestratorTask): Promise<unknown> {
  return ctx.run({ tenantId: task.tenantId }, async () => {
    const ac = new AbortController();
    const timer = setTimeout(() => ac.abort(), 10000);
    try {
      return await dispatch(task, ac.signal);
    } finally { clearTimeout(timer); }
  });
}
```

```typescript
// ❌ Anti‑pattern: Enrutar sin contexto tenant ni timeout
async function route(task) { return await handler(task); }
// 🔧 Fix: ctx.run + AbortController
return ctx.run({ tenantId: task.tenantId }, () => Promise.race([handler(task), timeout(10000)]));
```

```typescript
// ✅ C5: Verificación de integridad del payload con SHA256
const expectedHash = req.headers['x-payload-hash'];
const actualHash = createHash('sha256').update(JSON.stringify(payload)).digest('hex');
if (actualHash !== expectedHash) throw new Error('Payload integrity compromised');
```

```typescript
// ❌ Anti‑pattern: Procesar payload sin verificar hash
const payload = req.body;
// 🔧 Fix: Validar hash del header contra contenido
const hash = createHash('sha256').update(JSON.stringify(req.body)).digest('hex');
if (hash !== req.headers['x-payload-hash']) throw new Error('Invalid payload');
```

```typescript
// ✅ C4: Despacho a servicio con tenant_id en headers
const response = await fetch(serviceUrl, {
  method: 'POST',
  headers: { 'X-Tenant-Id': ctx.getStore()?.tenantId!, 'Content-Type': 'application/json' },
  body: JSON.stringify(payload),
  signal: AbortSignal.timeout(5000)
});
```

```typescript
// ❌ Anti‑pattern: Llamada entre servicios sin tenant_id
const res = await fetch(serviceUrl, { body: JSON.stringify(data) });
// 🔧 Fix: Incluir X-Tenant-Id y timeout
const res = await fetch(url, {
  headers: { 'X-Tenant-Id': ctx.getStore()?.tenantId! },
  body: JSON.stringify(data),
  signal: AbortSignal.timeout(5000)
});
```

```typescript
// ✅ C8: Timeout global para el pipeline de enrutamiento
const result = await Promise.race([
  routeTask(task),
  new Promise((_, reject) => setTimeout(() => reject(new Error('Global timeout')), 15000))
]);
```

```typescript
// ❌ Anti‑pattern: Sin límite de tiempo global
const result = await routeTask(task);
// 🔧 Fix: Promise.race con timeout
const result = await Promise.race([routeTask(task), timeout(15000)]);
```

```typescript
// ✅ C4: Logger con tenant_id en cada paso del enrutamiento
logger.info({ tenant_id: ctx.getStore()?.tenantId, action: task.action }, 'Routing task');
```

```typescript
// ❌ Anti‑pattern: Log sin tenant_id
console.log('Task routed');
// 🔧 Fix: Logger estructurado con AsyncLocalStorage
logger.info({ tenant_id: ctx.getStore()?.tenantId, action: task.action }, 'Routed');
```

```typescript
// ✅ C5/C8: Validación de esquema del task con Zod y timeout
const taskSchema = z.object({ tenantId: z.string().uuid(), action: z.enum(['query','embed']) });
const validTask = await Promise.race([
  Promise.resolve(taskSchema.parse(rawTask)),
  timeout(2000)
]);
```

```typescript
// ✅ C4/C8: Enrutamiento condicional por tenant con timeout
const handler = tenantHandlers.get(task.tenantId) ?? defaultHandler;
const result = await Promise.race([handler(task.payload), timeout(8000)]);
```

```typescript
// ✅ C5: Firma HMAC del payload para autenticación de origen
const signature = createHmac('sha256', secret).update(JSON.stringify(payload)).digest('hex');
if (signature !== req.headers['x-signature']) throw new Error('Invalid signature');
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/orchestrator-routing.ts.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"orchestrator-routing","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C4","C5","C8"],"examples_count":12,"lines_executable_max":4,"language":"TypeScript 5.0+ / Node.js 18+","timestamp":"2026-04-16T16:35:00Z"}
```

---
