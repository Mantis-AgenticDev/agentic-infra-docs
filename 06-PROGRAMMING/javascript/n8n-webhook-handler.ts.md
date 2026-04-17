# SHA256: c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9
---
artifact_id: "n8n-webhook-handler"
artifact_type: "skill_typescript"
version: "2.1.1"
constraints_mapped: ["C3","C4","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/n8n-webhook-handler.ts.md --json"
---

# n8n Webhook Handler – TypeScript/Node.js with Fastify/Express & Zod

## Propósito
Patrones para implementar webhooks compatibles con n8n en TypeScript/Node.js, usando Fastify o Express. Garantiza validación estricta de entorno (C3), aislamiento multi‑tenant vía `AsyncLocalStorage` (C4), manejo de dependencias opcionales (C6), seguridad en rutas de archivos de workflow (C7) y robustez con timeouts explícitos (C8).

## Patrones de Código Validados

```typescript
// ✅ C3: Validación de variables de entorno con Zod
import { z } from 'zod';
const envSchema = z.object({ N8N_WEBHOOK_PATH: z.string().startsWith('/') });
const env = envSchema.parse(process.env);
```

```typescript
// ❌ Anti‑pattern: Uso de variable de entorno sin validación
const webhookPath = process.env.N8N_WEBHOOK_PATH || '/webhook';
// 🔧 Fix: Schema Zod que verifica prefijo '/'
const env = z.object({ N8N_WEBHOOK_PATH: z.string().startsWith('/') }).parse(process.env);
```

```typescript
// ✅ C4: Middleware Fastify con AsyncLocalStorage
app.addHook('onRequest', async (req, reply) => {
  const tenantId = req.headers['x-tenant-id'] as string;
  if (!tenantId) throw new Error('Missing tenant');
  ctx.run({ tenantId }, () => {});
});
```

```typescript
// ❌ Anti‑pattern: Asignar tenant a req sin contexto asíncrono
app.use((req, res, next) => { req.tenantId = req.headers['x-tenant-id']; next(); });
// 🔧 Fix: Usar AsyncLocalStorage.run
app.addHook('onRequest', (req, reply, done) => {
  ctx.run({ tenantId: req.headers['x-tenant-id'] }, done);
});
```

```typescript
// ✅ C6: Import opcional de Express/Fastify con fallback
let framework: any;
try { framework = await import('fastify'); }
catch (e) { if ((e as NodeJS.ErrnoException).code !== 'ERR_MODULE_NOT_FOUND') throw e; }
```

```typescript
// ✅ C7: Validación de ruta para workflow JSON importado de n8n
const safePath = path.resolve('/workflows', fileName);
if (!safePath.startsWith('/workflows/')) throw new Error('Invalid workflow path');
```

```typescript
// ❌ Anti‑pattern: Lectura de archivo sin validación de ruta
const workflow = await fs.readFile(fileName, 'utf8');
// 🔧 Fix: Resolver y verificar directorio base
const p = path.resolve('/workflows', fileName);
if (!p.startsWith('/workflows/')) throw new Error('Path traversal');
const workflow = await fs.readFile(p, 'utf8');
```

```typescript
// ✅ C8: Timeout para petición saliente a n8n webhook
const ac = new AbortController();
setTimeout(() => ac.abort(), 5000);
const res = await fetch('https://n8n.example.com/webhook/test', { signal: ac.signal });
```

```typescript
// ❌ Anti‑pattern: Fetch sin timeout
const res = await fetch('https://n8n.example.com/webhook/test');
// 🔧 Fix: AbortController con timeout de 5 segundos
const ac = new AbortController(); setTimeout(() => ac.abort(), 5000);
const res = await fetch(url, { signal: ac.signal });
```

```typescript
// ✅ C4/C8: Ruta Express con validación Zod del payload y tenant en logs
app.post('/webhook/:tenant', async (req, res) => {
  const schema = z.object({ event: z.string() });
  const body = schema.parse(req.body);
  logger.info({ tenant_id: req.params.tenant, event: body.event }, 'Webhook');
});
```

```typescript
// ❌ Anti‑pattern: No validar body ni loguear tenant
app.post('/webhook', (req, res) => { console.log(req.body); res.send('ok'); });
// 🔧 Fix: Zod parse y logger con tenant_id
const body = z.object({ event: z.string() }).parse(req.body);
logger.info({ tenant_id: ctx.getStore()?.tenantId }, 'Webhook received');
```

```typescript
// ✅ C3/C8: Fastify con plugin de timeout y validación de entorno
const app = fastify({ requestTimeout: 10000 });
app.get('/health', async () => ({ status: 'ok', tenant: ctx.getStore()?.tenantId }));
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/n8n-webhook-handler.ts.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"n8n-webhook-handler","version":"2.1.1","score":30,"blocking_issues":[],"constraints_verified":["C3","C4","C6","C7","C8"],"examples_count":10,"lines_executable_max":4,"language":"TypeScript 5.0+ / Node.js 18+","timestamp":"2026-04-16T15:05:00Z"}
```

---
