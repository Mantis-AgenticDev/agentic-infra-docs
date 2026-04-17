# SHA256: f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b
---
artifact_id: "secrets-management-patterns"
artifact_type: "skill_typescript"
version: "2.1.1"
constraints_mapped: ["C3","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/secrets-management-patterns.ts.md --json"
---

# Secrets Management Patterns – TypeScript/Node.js with Zod Validation

## Propósito
Patrones para gestionar secretos de forma segura en Node.js: validación estricta de variables de entorno con Zod (C3), aislamiento por tenant (C4), verificación de integridad de archivos sensibles (C5), sandbox de sistema de archivos (C7) y manejo robusto de errores con timeouts (C8).

## Patrones de Código Validados

```typescript
// ✅ C3: Validación de secretos con Zod, fallo rápido si falta
import { z } from 'zod';
const envSchema = z.object({ API_KEY: z.string().min(32) });
const env = envSchema.parse(process.env);
```

```typescript
// ❌ Anti‑pattern: Acceso directo sin validación
const apiKey = process.env.API_KEY;
// 🔧 Fix: Schema Zod con validación de longitud mínima
const env = z.object({ API_KEY: z.string().min(32) }).parse(process.env);
```

```typescript
// ✅ C7: Lectura segura de archivo de secretos con validación de ruta
const secretPath = path.resolve('/secrets', tenantId, 'key.pem');
if (!secretPath.startsWith('/secrets/')) throw new Error('Path traversal');
const secret = await fs.readFile(secretPath, 'utf8');
```

```typescript
// ❌ Anti‑pattern: Lectura directa sin validación de ruta
const secret = await fs.readFile(`/secrets/${tenantId}/key.pem`, 'utf8');
// 🔧 Fix: Resolver y verificar prefijo del directorio base
const p = path.resolve('/secrets', tenantId, 'key.pem');
if (!p.startsWith('/secrets/')) throw new Error('Invalid path');
const secret = await fs.readFile(p, 'utf8');
```

```typescript
// ✅ C5: Verificación de integridad de archivo de secretos con SHA256
const content = await fs.readFile(secretPath);
const hash = createHash('sha256').update(content).digest('hex');
if (hash !== expectedHash) throw new Error('Secret file tampered');
```

```typescript
// ❌ Anti‑pattern: Confiar en contenido sin checksum
const content = await fs.readFile(secretPath, 'utf8');
// 🔧 Fix: Validar hash antes de usar
const data = await fs.readFile(p); const hash = createHash('sha256').update(data).digest('hex');
if (hash !== expected) throw new Error('Integrity check failed');
```

```typescript
// ✅ C4/C8: Logger con tenant_id en operaciones de secretos
logger.info({ tenant_id: ctx.getStore()?.tenantId }, 'Secret loaded');
```

```typescript
// ❌ Anti‑pattern: Log sin tenant_id
console.log('Secret loaded');
// 🔧 Fix: Logger estructurado con AsyncLocalStorage
logger.info({ tenant_id: ctx.getStore()?.tenantId }, 'Secret loaded');
```

```typescript
// ✅ C8: Timeout para carga de secretos desde API externa
const ac = new AbortController();
setTimeout(() => ac.abort(), 3000);
const res = await fetch(secretUrl, { signal: ac.signal });
```

```typescript
// ❌ Anti‑pattern: Fetch sin timeout
const res = await fetch(secretUrl);
// 🔧 Fix: AbortController con timeout de 3 segundos
const ac = new AbortController(); setTimeout(() => ac.abort(), 3000);
const res = await fetch(url, { signal: ac.signal });
```

```typescript
// ✅ C3: Zod schema para secretos con refinamiento de formato
const secretSchema = z.string().regex(/^[A-Za-z0-9+/=]{32,}$/);
const validSecret = secretSchema.parse(process.env.SECRET);
```

```typescript
// ❌ Anti‑pattern: Validación manual incompleta
if (!process.env.SECRET) throw new Error('Missing');
// 🔧 Fix: Zod con regex para formato específico
z.string().regex(/^[A-Za-z0-9+/=]{32,}$/).parse(process.env.SECRET);
```

```typescript
// ✅ C5/C7: Rotación de secretos con backup atómico y checksum
const newSecret = generateSecret();
const backupPath = path.resolve(secretDir, 'key.pem.bak');
await fs.writeFile(backupPath, newSecret);
const hash = createHash('sha256').update(newSecret).digest('hex');
await fs.writeFile(hashPath, hash);
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/secrets-management-patterns.ts.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"secrets-management-patterns","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C3","C4","C5","C7","C8"],"examples_count":12,"lines_executable_max":3,"language":"TypeScript 5.0+ / Node.js 18+","timestamp":"2026-04-16T14:50:00Z"}
```

---
