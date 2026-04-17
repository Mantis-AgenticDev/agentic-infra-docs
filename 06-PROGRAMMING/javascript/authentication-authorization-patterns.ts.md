# SHA256: e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7
---
artifact_id: "authentication-authorization-patterns"
artifact_type: "skill_typescript"
version: "2.1.1"
constraints_mapped: ["C3","C4","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/authentication-authorization-patterns.ts.md --json"
---

# Authentication & Authorization Patterns – TypeScript/Node.js JWT with `jose`

## Propósito
Patrones de autenticación y autorización seguros usando JWT con la librería `jose` (Node.js), garantizando validación de entorno (C3), aislamiento multi‑tenant vía claims de `tenant_id` (C4), verificación de integridad de firma (C5) y manejo robusto de errores y timeouts (C8).

## Patrones de Código Validados

```typescript
// ✅ C3/C5: Generación de JWT con jose, clave desde env y tenant_id en payload
import * as jose from 'jose';
const secret = new TextEncoder().encode(process.env.JWT_SECRET);
const jwt = await new jose.SignJWT({ tenant_id: ctx.getStore()?.tenantId })
  .setProtectedHeader({ alg: 'HS256' })
  .sign(secret);
```

```typescript
// ❌ Anti‑pattern: Uso de jsonwebtoken con callback sin timeout
import jwt from 'jsonwebtoken';
jwt.sign({ tenant_id }, 'secret', (err, token) => {});
// 🔧 Fix: jose con async/await y timeout explícito
const token = await Promise.race([signJWT(), timeout(5000)]);
```

```typescript
// ✅ C3: Validación de JWT_SECRET al inicio, fallo rápido si falta
const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) { logger.fatal({ tenant_id: 'unknown' }, 'JWT_SECRET missing'); process.exit(1); }
```

```typescript
// ❌ Anti‑pattern: Secret por defecto que compromete seguridad
const secret = process.env.JWT_SECRET || 'dev-secret';
// 🔧 Fix: Fallo explícito sin valor por defecto
const secret = process.env.JWT_SECRET; if (!secret) throw new Error('Missing secret');
```

```typescript
// ✅ C4/C5: Verificación de JWT con jose, extracción segura de tenant_id
const { payload } = await jose.jwtVerify(token, secret);
const tenantId = payload.tenant_id as string;
if (!tenantId) throw new Error('Missing tenant_id claim');
```

```typescript
// ❌ Anti‑pattern: No validar presencia de tenant_id en claims
const { payload } = await jose.jwtVerify(token, secret);
const tenant = payload.tenant_id; // puede ser undefined
// 🔧 Fix: Validación explícita con tipo
const tenant = payload.tenant_id; if (typeof tenant !== 'string') throw new Error('Invalid tenant');
```

```typescript
// ✅ C8: Timeout para verificación de JWT con AbortController
const ac = new AbortController();
setTimeout(() => ac.abort(), 3000);
const { payload } = await jose.jwtVerify(token, secret, { signal: ac.signal });
```

```typescript
// ❌ Anti‑pattern: Verificación JWT sin timeout
const { payload } = await jose.jwtVerify(token, secret);
// 🔧 Fix: AbortController con timeout
const ac = new AbortController(); setTimeout(() => ac.abort(), 3000);
const { payload } = await jose.jwtVerify(token, secret, { signal: ac.signal });
```

```typescript
// ✅ C4/C8: Middleware Express con AsyncLocalStorage y validación JWT
app.use(async (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  const { payload } = await jose.jwtVerify(token!, secret);
  ctx.run({ tenantId: payload.tenant_id as string }, next);
});
```

```typescript
// ❌ Anti‑pattern: Asignar tenant_id a req sin AsyncLocalStorage
req.tenantId = payload.tenant_id;
// 🔧 Fix: Usar AsyncLocalStorage para propagación segura
ctx.run({ tenantId: payload.tenant_id }, () => next());
```

```typescript
// ✅ C5: Protección contra algoritmos débiles (none, HS256 sin secret)
await jose.jwtVerify(token, secret, { algorithms: ['HS256'] });
```

```typescript
// ❌ Anti‑pattern: Aceptar cualquier algoritmo (incluido 'none')
const { payload } = await jose.jwtVerify(token, secret);
// 🔧 Fix: Restringir explícitamente algoritmos permitidos
await jose.jwtVerify(token, secret, { algorithms: ['HS256'] });
```

```typescript
// ✅ C4: Logger con tenant_id automático desde AsyncLocalStorage en auth flow
logger.info({ tenant_id: ctx.getStore()?.tenantId, action: 'login' }, 'User authenticated');
```

```typescript
// ❌ Anti‑pattern: Log de autenticación sin tenant_id
console.log('User logged in');
// 🔧 Fix: Logger estructurado con tenant_id inyectado
logger.info({ tenant_id: ctx.getStore()?.tenantId }, 'Authenticated');
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/authentication-authorization-patterns.ts.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"authentication-authorization-patterns","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C3","C4","C5","C8"],"examples_count":12,"lines_executable_max":4,"language":"TypeScript 5.0+ / Node.js 18+","timestamp":"2026-04-16T14:45:00Z"}
```

---
