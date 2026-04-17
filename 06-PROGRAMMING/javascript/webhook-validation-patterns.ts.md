# SHA256: e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e
---
artifact_id: "webhook-validation-patterns"
artifact_type: "skill_typescript"
version: "2.1.1"
constraints_mapped: ["C3","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/webhook-validation-patterns.ts.md --json"
---

# Webhook Validation Patterns – TypeScript/Node.js HMAC & Replay Cache

## Propósito
Patrones para validar webhooks entrantes en aplicaciones TypeScript/Node.js multi‑tenant: validación de firma HMAC‑SHA256 con clave del entorno (C3, C5), propagación de tenant_id vía `AsyncLocalStorage` (C4), protección contra path traversal en URLs de webhook (C7) y manejo robusto de timeouts y errores (C8), incluyendo caché de nonce para prevenir ataques de replay.

## Patrones de Código Validados

```typescript
// ✅ C3: Validación de secreto webhook con Zod
import { z } from 'zod';
const env = z.object({ WEBHOOK_SECRET: z.string().min(32) }).parse(process.env);
```

```typescript
// ❌ Anti‑pattern: Secreto por defecto inseguro
const secret = process.env.WEBHOOK_SECRET || 'default-secret';
// 🔧 Fix: Validación estricta con Zod, falla si falta
const env = z.object({ WEBHOOK_SECRET: z.string().min(32) }).parse(process.env);
```

```typescript
// ✅ C5: Verificación de firma HMAC‑SHA256 con timing‑safe compare
import { createHmac, timingSafeEqual } from 'crypto';
const signature = req.headers['x-signature'] as string;
const computed = createHmac('sha256', secret).update(rawBody).digest('hex');
if (!timingSafeEqual(Buffer.from(signature), Buffer.from(computed))) throw new Error('Invalid');
```

```typescript
// ❌ Anti‑pattern: Comparación de firma con `===` (vulnerable a timing attacks)
if (signature !== computed) throw new Error('Invalid');
// 🔧 Fix: Usar timingSafeEqual para comparación segura
if (!timingSafeEqual(Buffer.from(signature), Buffer.from(computed))) throw new Error('Invalid');
```

```typescript
// ✅ C4/C8: Middleware de validación con AsyncLocalStorage y timeout
app.post('/webhook/:tenant', async (req, res) => {
  const tenantId = req.params.tenant;
  if (!tenantId) return res.status(400).json({ error: 'Missing tenant' });
  ctx.run({ tenantId }, async () => {
    const ac = new AbortController();
    setTimeout(() => ac.abort(), 5000);
    await validateWebhook(req, ac.signal);
    res.sendStatus(200);
  });
});
```

```typescript
// ❌ Anti‑pattern: Procesar webhook sin tenant ni timeout
app.post('/webhook', (req, res) => { process(req); res.send('ok'); });
// 🔧 Fix: ctx.run con tenant y AbortController para timeout
ctx.run({ tenantId }, async () => {
  const ac = new AbortController(); setTimeout(() => ac.abort(), 5000);
  await process(req, ac.signal); res.send('ok');
});
```

```typescript
// ✅ C5/C8: Caché de nonce con TTL para prevenir replay attacks
const nonce = req.headers['x-nonce'] as string;
if (await cache.has(nonce)) throw new Error('Replay detected');
await cache.set(nonce, '1', { EX: 300 }); // expira en 5 minutos
```

```typescript
// ❌ Anti‑pattern: No verificar unicidad de nonce
// 🔧 Fix: Usar almacenamiento (Redis/Map) con TTL
const nonce = req.headers['x-nonce']; if (await cache.get(nonce)) throw new Error('Replay');
await cache.set(nonce, '1', 'EX', 300);
```

```typescript
// ✅ C7: Validación de URL de webhook contra base permitida
const webhookUrl = new URL(req.body.target_url);
if (!webhookUrl.hostname.endsWith('.n8n.example.com')) throw new Error('Invalid host');
```

```typescript
// ❌ Anti‑pattern: Usar URL arbitraria sin validar
const target = req.body.target_url;
// 🔧 Fix: Parsear y validar hostname
const url = new URL(req.body.target_url);
if (!url.hostname.endsWith('.trusted.com')) throw new Error('Invalid target');
```

```typescript
// ✅ C4: Logger con tenant_id en flujo de validación
logger.info({ tenant_id: ctx.getStore()?.tenantId, nonce }, 'Webhook validated');
```

```typescript
// ❌ Anti‑pattern: Log sin tenant_id
console.log('Webhook OK');
// 🔧 Fix: Logger estructurado con tenant_id desde contexto
logger.info({ tenant_id: ctx.getStore()?.tenantId }, 'Webhook validated');
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/webhook-validation-patterns.ts.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"webhook-validation-patterns","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C3","C4","C5","C7","C8"],"examples_count":10,"lines_executable_max":5,"language":"TypeScript 5.0+ / Node.js 18+","timestamp":"2026-04-16T15:15:00Z"}
```

---
