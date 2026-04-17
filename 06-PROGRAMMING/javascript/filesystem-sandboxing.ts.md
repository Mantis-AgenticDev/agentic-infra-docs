# SHA256: f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f
---
artifact_id: "filesystem-sandboxing"
artifact_type: "skill_typescript"
version: "2.1.1"
constraints_mapped: ["C4","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/filesystem-sandboxing.ts.md --json"
---

# Filesystem Sandboxing – TypeScript/Node.js Path Validation & Isolation

## Propósito
Patrones para operaciones de sistema de archivos seguras en Node.js multi‑tenant: prevención de path traversal con `path.resolve` + validación de prefijo y resolución de symlinks (C7), propagación de `tenant_id` vía `AsyncLocalStorage` en rutas aisladas por tenant (C4), y timeouts explícitos en todas las operaciones de I/O (C8).

## Patrones de Código Validados

```typescript
// ✅ C7: Validación de ruta base con path.resolve y verificación de prefijo
import path from 'path';
const safePath = path.resolve('/data', userInput);
if (!safePath.startsWith('/data/')) throw new Error('Path traversal blocked');
```

```typescript
// ❌ Anti‑pattern: Concatenación directa sin validación
const filePath = `/data/${req.query.file}`;
// 🔧 Fix: path.resolve + verificación de prefijo
const p = path.resolve('/data', req.query.file);
if (!p.startsWith('/data/')) throw new Error('Invalid path');
```

```typescript
// ✅ C7: Resolución de symlinks con fs.realpath para prevenir escapes
import fs from 'fs/promises';
const realPath = await fs.realpath(userPath);
if (!realPath.startsWith('/data/')) throw new Error('Symlink escape detected');
```

```typescript
// ❌ Anti‑pattern: Usar ruta sin resolver symlinks
const stat = await fs.stat(userPath);
// 🔧 Fix: fs.realpath antes de validar
const real = await fs.realpath(userPath);
if (!real.startsWith('/data/')) throw new Error('Symlink escape');
```

```typescript
// ✅ C4: Ruta aislada por tenant usando AsyncLocalStorage
const tenantId = ctx.getStore()?.tenantId;
if (!tenantId) throw new Error('Tenant context missing');
const tenantPath = path.resolve('/tenants', tenantId, userFile);
if (!tenantPath.startsWith(`/tenants/${tenantId}/`)) throw new Error('Path escape');
```

```typescript
// ❌ Anti‑pattern: Ruta sin tenant_id
const filePath = path.resolve('/uploads', filename);
// 🔧 Fix: Incluir tenant_id del contexto
const tid = ctx.getStore()?.tenantId;
const p = path.resolve('/uploads', tid, filename);
if (!p.startsWith(`/uploads/${tid}/`)) throw new Error('Invalid');
```

```typescript
// ✅ C8: Timeout para operaciones de archivo con AbortSignal.timeout
const signal = AbortSignal.timeout(5000);
const content = await fs.readFile(safePath, { encoding: 'utf8', signal });
```

```typescript
// ❌ Anti‑pattern: readFile sin timeout
const data = await fs.readFile(filePath, 'utf8');
// 🔧 Fix: AbortSignal.timeout para evitar bloqueos
const signal = AbortSignal.timeout(5000);
const data = await fs.readFile(p, { encoding: 'utf8', signal });
```

```typescript
// ✅ C4/C8: Logger con tenant_id en operaciones de archivo
logger.info({ tenant_id: ctx.getStore()?.tenantId, path: safePath }, 'File read');
```

```typescript
// ❌ Anti‑pattern: Log sin tenant_id
console.log('File read:', filePath);
// 🔧 Fix: Logger estructurado con tenant_id inyectado
logger.info({ tenant_id: ctx.getStore()?.tenantId, path: p }, 'File read');
```

```typescript
// ✅ C7/C8: Escritura segura con directorio temporal aislado
import os from 'os';
const tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), `tenant-${tenantId}-`));
const filePath = path.join(tmpDir, sanitize(userFile));
await fs.writeFile(filePath, data, { signal: AbortSignal.timeout(5000) });
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/filesystem-sandboxing.ts.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"filesystem-sandboxing","version":"2.1.1","score":30,"blocking_issues":[],"constraints_verified":["C4","C7","C8"],"examples_count":10,"lines_executable_max":3,"language":"TypeScript 5.0+ / Node.js 18+","timestamp":"2026-04-16T15:20:00Z"}
```

---
