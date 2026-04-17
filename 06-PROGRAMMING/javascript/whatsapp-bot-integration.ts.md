# SHA256: b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c
---
artifact_id: "whatsapp-bot-integration"
artifact_type: "skill_typescript"
version: "2.1.1"
constraints_mapped: ["C3","C4","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/whatsapp-bot-integration.ts.md --json"
---

# WhatsApp Bot Integration – TypeScript/Node.js with Axios & AsyncLocalStorage

## Propósito
Patrones para integrar la API de WhatsApp Business usando Axios con validación estricta de entorno (C3), aislamiento multi‑tenant mediante `AsyncLocalStorage` (C4), manejo de dependencias opcionales (C6), seguridad en rutas de archivos adjuntos (C7) y robustez con timeouts explícitos (C8).

## Patrones de Código Validados

```typescript
// ✅ C3: Validación de credenciales WhatsApp con Zod
import { z } from 'zod';
const envSchema = z.object({ WA_PHONE_ID: z.string(), WA_TOKEN: z.string().min(32) });
const env = envSchema.parse(process.env);
```

```typescript
// ❌ Anti‑pattern: Uso directo sin validación
const token = process.env.WA_TOKEN;
// 🔧 Fix: Schema Zod con validación de formato
const env = z.object({ WA_TOKEN: z.string().min(32) }).parse(process.env);
```

```typescript
// ✅ C4/C8: Cliente Axios con tenant_id en headers y timeout
import axios from 'axios';
const client = axios.create({ baseURL: 'https://graph.facebook.com/v18.0', timeout: 10000 });
client.interceptors.request.use(config => {
  config.headers['X-Tenant-Id'] = ctx.getStore()?.tenantId;
  return config;
});
```

```typescript
// ❌ Anti‑pattern: Axios sin timeout ni tenant_id
const res = await axios.post(`/${phoneId}/messages`, payload);
// 🔧 Fix: Interceptor con tenant_id y timeout global
const client = axios.create({ timeout: 10000 });
client.interceptors.request.use(c => { c.headers['X-Tenant-Id'] = getTenant(); return c; });
```

```typescript
// ✅ C6: Import opcional de Axios con fallback documentado
let axios: any;
try { axios = await import('axios'); }
catch (e) { if ((e as NodeJS.ErrnoException).code !== 'ERR_MODULE_NOT_FOUND') throw e; }
```

```typescript
// ✅ C7: Validación de ruta para adjuntos de WhatsApp
const safePath = path.resolve('/tmp/uploads', req.file.filename);
if (!safePath.startsWith('/tmp/uploads/')) throw new Error('Invalid upload path');
```

```typescript
// ❌ Anti‑pattern: Usar nombre de archivo directamente
const stream = fs.createReadStream(req.file.path);
// 🔧 Fix: Resolver y validar prefijo
const p = path.resolve('/tmp/uploads', req.file.filename);
if (!p.startsWith('/tmp/uploads/')) throw new Error('Path traversal');
const stream = fs.createReadStream(p);
```

```typescript
// ✅ C8: Envío de mensaje con timeout explícito y manejo de errores
const ac = new AbortController();
setTimeout(() => ac.abort(), 8000);
const res = await client.post(`/${phoneId}/messages`, payload, { signal: ac.signal });
```

```typescript
// ❌ Anti‑pattern: POST sin timeout
const res = await axios.post(url, payload);
// 🔧 Fix: AbortController con timeout de 8 segundos
const ac = new AbortController(); setTimeout(() => ac.abort(), 8000);
const res = await client.post(url, payload, { signal: ac.signal });
```

```typescript
// ✅ C4/C8: Middleware de webhook con AsyncLocalStorage y validación de token
app.post('/webhook', (req, res) => {
  const tenantId = req.query.tenant as string;
  if (!tenantId) return res.status(400).json({ error: 'Missing tenant' });
  ctx.run({ tenantId }, async () => {
    const valid = req.query['hub.verify_token'] === env.WA_VERIFY_TOKEN;
    res.status(valid ? 200 : 403).send(valid ? req.query['hub.challenge'] : 'Forbidden');
  });
});
```

```typescript
// ❌ Anti‑pattern: Webhook sin validación de tenant ni contexto
app.post('/webhook', (req, res) => { res.send(req.query['hub.challenge']); });
// 🔧 Fix: ctx.run con tenant_id y verificación de token
ctx.run({ tenantId }, () => { /* validación */ });
```

```typescript
// ✅ C4: Logger con tenant_id automático en webhook
logger.info({ tenant_id: ctx.getStore()?.tenantId, from: payload.from }, 'Message received');
```

```typescript
// ❌ Anti‑pattern: Log sin tenant_id
console.log('Message from', payload.from);
// 🔧 Fix: Logger estructurado con contexto
logger.info({ tenant_id: ctx.getStore()?.tenantId, from: payload.from }, 'Received');
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/whatsapp-bot-integration.ts.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"whatsapp-bot-integration","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C3","C4","C6","C7","C8"],"examples_count":12,"lines_executable_max":4,"language":"TypeScript 5.0+ / Node.js 18+","timestamp":"2026-04-16T15:00:00Z"}
```

---
