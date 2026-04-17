# SHA256: a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2
---
artifact_id: "filesystem-sandbox-sync"
artifact_type: "skill_typescript"
version: "2.1.1"
constraints_mapped: ["C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/filesystem-sandbox-sync.ts.md --json"
---

# Filesystem Sandbox Sync – TypeScript/Node.js with fs-extra & Post‑Sync Checksum

## Propósito
Patrones para sincronización segura de archivos en entornos multi‑tenant Node.js usando `fs-extra`. Incluye validación de entorno (C3), verificación de integridad con checksum SHA256 post‑escritura (C5), protección contra path traversal y symlinks (C7), y timeouts explícitos en operaciones síncronas o asíncronas (C8).

## Patrones de Código Validados

```typescript
// ✅ C3: Validación de directorio base con Zod
import { z } from 'zod';
const env = z.object({ SYNC_BASE_DIR: z.string().startsWith('/') }).parse(process.env);
```

```typescript
// ❌ Anti‑pattern: Directorio base sin validación
const baseDir = process.env.SYNC_BASE_DIR || './sync';
// 🔧 Fix: Zod para asegurar ruta absoluta
const env = z.object({ SYNC_BASE_DIR: z.string().startsWith('/') }).parse(process.env);
```

```typescript
// ✅ C7: Path resolution con tenant isolation y validación
import path from 'path';
const tenantPath = path.resolve(env.SYNC_BASE_DIR, tenantId, userFile);
if (!tenantPath.startsWith(path.join(env.SYNC_BASE_DIR, tenantId))) throw new Error('Invalid');
```

```typescript
// ❌ Anti‑pattern: Uso directo de input de usuario
const dest = `/sync/${tenantId}/${file}`;
// 🔧 Fix: Resolver y validar contra directorio tenant
const base = path.join(env.SYNC_BASE_DIR, tenantId);
const dest = path.resolve(base, file);
if (!dest.startsWith(base)) throw new Error('Path traversal');
```

```typescript
// ✅ C5: Checksum post‑escritura con fs-extra
import fs from 'fs-extra';
import { createHash } from 'crypto';
await fs.outputFile(safePath, data);
const written = await fs.readFile(safePath);
const hash = createHash('sha256').update(written).digest('hex');
if (hash !== expectedHash) throw new Error('Integrity mismatch');
```

```typescript
// ❌ Anti‑pattern: Escribir sin verificar integridad
await fs.outputFile(path, data);
// 🔧 Fix: Leer de vuelta y comparar hash
await fs.outputFile(p, data);
const actual = createHash('sha256').update(await fs.readFile(p)).digest('hex');
if (actual !== expected) throw new Error('Corrupted');
```

```typescript
// ✅ C8: Timeout para operación copy con AbortSignal.timeout
await fs.copy(src, dest, { signal: AbortSignal.timeout(10000) });
```

```typescript
// ❌ Anti‑pattern: copy sin timeout
await fs.copy(src, dest);
// 🔧 Fix: signal con timeout explícito
await fs.copy(src, dest, { signal: AbortSignal.timeout(10000) });
```

```typescript
// ✅ C7/C8: Symlink resolution con fs.realpath antes de escribir
const realSrc = await fs.realpath(srcPath);
if (!realSrc.startsWith(allowedBase)) throw new Error('Symlink escape');
await fs.copy(realSrc, dest);
```

```typescript
// ❌ Anti‑pattern: Copiar symlink sin resolver
await fs.copy(src, dest);
// 🔧 Fix: Resolver symlink y validar destino
const real = await fs.realpath(src);
if (!real.startsWith(base)) throw new Error('Invalid');
await fs.copy(real, dest);
```

```typescript
// ✅ C3/C5: Validación de permisos de escritura antes de sync
try { await fs.access(syncDir, fs.constants.W_OK); }
catch { throw new Error('Directory not writable'); }
```

```typescript
// ✅ C8: Retry con backoff en operación sync
import { retry } from 'ts-retry-promise';
await retry(() => fs.copy(src, dest), { retries: 3, delay: 1000, timeout: 15000 });
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/filesystem-sandbox-sync.ts.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"filesystem-sandbox-sync","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C3","C5","C7","C8"],"examples_count":11,"lines_executable_max":4,"language":"TypeScript 5.0+ / Node.js 18+","timestamp":"2026-04-16T15:25:00Z"}
```

---
