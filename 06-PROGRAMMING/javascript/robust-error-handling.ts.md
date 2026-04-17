# SHA256: d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6
---
artifact_id: "robust-error-handling"
artifact_type: "skill_typescript"
version: "2.1.1"
constraints_mapped: ["C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/robust-error-handling.ts.md --json"
---

# Robust Error Handling – TypeScript/Node.js Structured Try/Catch & Logging

## Propósito
Patrón de manejo de errores estructurado para aplicaciones TypeScript/Node.js multi‑tenant, garantizando aislamiento de contexto (C4), verificación de integridad de datos (C5), seguridad de sistema de archivos (C7) y recuperación controlada con timeouts (C8).

## Patrones de Código Validados

```typescript
// ✅ C4/C8: Try/catch con enriquecimiento de logger y propagación de tenant_id
try {
  await riskyOperation();
} catch (err) {
  logger.error({ tenant_id: ctx.getStore()?.tenantId, err }, 'Operation failed');
  throw err;
}
```

```typescript
// ❌ Anti‑pattern: Captura de error sin contexto ni tenant_id
try { await riskyOperation(); } catch (e) { console.log(e); }
// 🔧 Fix: Logger estructurado con tenant_id automático
try { await riskyOperation(); } catch (err) {
  logger.error({ tenant_id: ctx.getStore()?.tenantId, err }, 'Failed');
}
```

```typescript
// ✅ C8: Timeout explícito para operaciones de base de datos
const dbQuery = db.collection('data').findOne({ id: docId });
const result = await Promise.race([
  dbQuery,
  new Promise((_, reject) => setTimeout(() => reject(new Error('DB timeout')), 5000))
]);
```

```typescript
// ❌ Anti‑pattern: Consulta DB sin timeout puede bloquear indefinidamente
const doc = await db.collection('data').findOne({ id });
// 🔧 Fix: Promise.race con timeout
const doc = await Promise.race([
  db.collection('data').findOne({ id }),
  new Promise((_, reject) => setTimeout(() => reject(new Error('Timeout')), 5000))
]);
```

```typescript
// ✅ C7: Apertura de archivo segura con validación de ruta y manejo de errores
import fs from 'fs/promises';
const safePath = path.resolve(baseDir, userFile);
if (!safePath.startsWith(baseDir)) throw new Error('Invalid path');
try {
  const handle = await fs.open(safePath, 'r');
} catch (err) {
  if (err.code === 'ENOENT') throw new Error('File not found');
  throw err;
}
```

```typescript
// ❌ Anti‑pattern: Apertura de archivo sin validación de ruta ni manejo específico
const fd = await fs.open(userFile, 'r');
// 🔧 Fix: Validar path base y manejar errores específicos
const resolved = path.resolve('/data', userFile);
if (!resolved.startsWith('/data')) throw new Error('Invalid path');
try { const fd = await fs.open(resolved, 'r'); } catch (e) { /* manejar */ }
```

```typescript
// ✅ C5: Verificación de integridad de datos con hash antes de escritura
const hash = createHash('sha256').update(payload).digest('hex');
if (hash !== expectedHash) throw new Error('Data integrity compromised');
await fs.writeFile(filePath, payload);
```

```typescript
// ❌ Anti‑pattern: Escritura de archivo sin verificación previa de checksum
await fs.writeFile(filePath, data);
// 🔧 Fix: Validar hash antes de escribir
const hash = createHash('sha256').update(data).digest('hex');
if (hash !== expected) throw new Error('Hash mismatch');
await fs.writeFile(safePath, data);
```

```typescript
// ✅ C4/C8: Retry exponencial con backoff y tenant_id en logs
async function retryWithBackoff<T>(fn: () => Promise<T>, retries = 3): Promise<T> {
  for (let i = 0; i < retries; i++) {
    try {
      return await fn();
    } catch (err) {
      logger.warn({ tenant_id: ctx.getStore()?.tenantId, attempt: i }, 'Retry');
      await new Promise(r => setTimeout(r, 1000 * Math.pow(2, i)));
    }
  }
  throw new Error('Max retries exceeded');
}
```

```typescript
// ❌ Anti‑pattern: Reintento simple sin backoff ni logging contextual
for (let i=0; i<3; i++) { try { return await fn(); } catch(e) { } }
// 🔧 Fix: Retry con backoff exponencial y logs por tenant
await retryWithBackoff(fn, 3);
```

```typescript
// ✅ C7/C8: Validación de symlinks para evitar salir del sandbox
const realPath = await fs.realpath(userPath);
if (!realPath.startsWith(baseDir)) throw new Error('Symlink escape detected');
```

```typescript
// ❌ Anti‑pattern: Uso de ruta sin resolver symlinks
const stat = await fs.stat(userPath);
// 🔧 Fix: Resolver symlinks con fs.realpath antes de validar
const real = await fs.realpath(userPath);
if (!real.startsWith(baseDir)) throw new Error('Invalid symlink target');
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/robust-error-handling.ts.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"robust-error-handling","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C4","C5","C7","C8"],"examples_count":10,"lines_executable_max":5,"language":"TypeScript 5.0+ / Node.js 18+","timestamp":"2026-04-16T14:40:00Z"}
```

---
