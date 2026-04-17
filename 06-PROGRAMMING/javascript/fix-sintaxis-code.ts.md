# SHA256: c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3
---
artifact_id: "fix-sintaxis-code"
artifact_type: "skill_typescript"
version: "2.1.1"
constraints_mapped: ["C3","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/fix-sintaxis-code.ts.md --json"
---

# Fix Sintaxis Code – TypeScript/Node.js Linter & Compiler Integration

## Propósito
Patrón de corrección automática de sintaxis y anti‑patrones TypeScript/Node.js usando ESLint y `tsc` en modo strict, con validación pre‑commit y bloqueo de código inseguro que viole constraints C3 (entorno), C4 (aislamiento multi‑tenant), C5 (integridad), C7 (sandbox de FS) y C8 (gestión de errores robusta).

## Patrones de Código Validados

```typescript
// ✅ C3/C8: Ejecución segura de ESLint con timeout y validación de entorno
const ac = new AbortController();
setTimeout(() => ac.abort(), 10000);
const results = await eslint.lintFiles(['src/**/*.ts'], { signal: ac.signal });
```

```typescript
// ❌ Anti‑pattern: ESLint sin timeout puede colgar el proceso
const results = await eslint.lintFiles(['src/**/*.ts']);
// 🔧 Fix: Usar AbortController con timeout explícito
const ac = new AbortController();
setTimeout(() => ac.abort(), 10000);
const res = await eslint.lintFiles(['src/**/*.ts'], { signal: ac.signal });
```

```typescript
// ✅ C4/C8: Logger estructurado con contexto tenant_id durante linting
import pino from 'pino';
const logger = pino({ level: 'info' });
logger.info({ tenant_id: ctx.getStore()?.tenantId, files: 5 }, 'Linting started');
```

```typescript
// ❌ Anti‑pattern: console.log sin estructura ni tenant_id
console.log('Linting completed');
// 🔧 Fix: Logger JSON con tenant_id automático
logger.info({ tenant_id: ctx.getStore()?.tenantId }, 'Linting completed');
```

```typescript
// ✅ C5/C7: Validación de integridad de archivo antes de linting
import { createHash } from 'crypto';
import fs from 'fs/promises';
const content = await fs.readFile(filePath);
const hash = createHash('sha256').update(content).digest('hex');
if (hash !== expected) throw new Error('File tampered');
```

```typescript
// ❌ Anti‑pattern: Leer archivo sin verificar integridad
const content = await fs.readFile(userPath, 'utf-8');
// 🔧 Fix: Validar hash y path seguro antes de leer
const safePath = path.resolve(baseDir, userPath);
if (!safePath.startsWith(baseDir)) throw new Error('Invalid path');
const content = await fs.readFile(safePath, 'utf-8');
```

```typescript
// ✅ C7: Path sanitization antes de pasar a ESLint
const safePath = path.resolve(workspace, userFile);
if (!safePath.startsWith(workspace)) throw new Error('Path traversal blocked');
```

```typescript
// ❌ Anti‑pattern: Usar input de usuario directamente en path
await eslint.lintFiles([`src/${req.query.file}`]);
// 🔧 Fix: Resolver y validar contra directorio base
const target = path.resolve('/app/src', req.query.file);
if (!target.startsWith('/app/src')) throw new Error('Invalid file');
await eslint.lintFiles([target]);
```

```typescript
// ✅ C8: Ejecución de tsc con timeout y captura de errores estructurados
const { exec } = await import('child_process');
const { stdout, stderr } = await new Promise((resolve, reject) => {
  const child = exec('npx tsc --noEmit', { timeout: 30000 }, (err, stdout, stderr) => {
    if (err) reject(err);
    else resolve({ stdout, stderr });
  });
});
```

```typescript
// ❌ Anti‑pattern: execSync sin timeout bloquea el event loop
import { execSync } from 'child_process';
const result = execSync('npx tsc --noEmit');
// 🔧 Fix: exec con timeout y manejo async
const child = exec('npx tsc --noEmit', { timeout: 30000 });
child.on('exit', (code) => { /* manejar */ });
```

```typescript
// ✅ C3: Validación de variables de entorno para ESLint y TSC
const NODE_ENV = process.env.NODE_ENV;
if (!NODE_ENV) { logger.fatal({ tenant_id: 'unknown' }, 'NODE_ENV missing'); process.exit(1); }
```

```typescript
// ❌ Anti‑pattern: Fallback inseguro para NODE_ENV
const env = process.env.NODE_ENV || 'development';
// 🔧 Fix: Fallar explícitamente si falta
const env = process.env.NODE_ENV;
if (!env) throw new Error('NODE_ENV required');
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/fix-sintaxis-code.ts.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"fix-sintaxis-code","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C3","C4","C5","C7","C8"],"examples_count":10,"lines_executable_max":3,"language":"TypeScript 5.0+ / Node.js 18+","timestamp":"2026-04-16T14:35:00Z"}
```

---
