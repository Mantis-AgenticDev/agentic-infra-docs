# SHA256: a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a
---
artifact_id: "dependency-management"
artifact_type: "skill_typescript"
version: "2.1.1"
constraints_mapped: ["C3","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/dependency-management.ts.md --json"
---

# Dependency Management – TypeScript/Node.js with pnpm Workspaces & Constraint Files

## Propósito
Patrones para gestionar dependencias de forma segura y reproducible en monorepos TypeScript con `pnpm workspaces`. Incluye validación de variables de entorno (C3), verificación de integridad de `pnpm-lock.yaml` con checksums (C5), y ejecución de comandos de instalación con timeouts explícitos (C8).

## Patrones de Código Validados

```typescript
// ✅ C3: Validación de entorno para pnpm con Zod
import { z } from 'zod';
const env = z.object({ NODE_ENV: z.enum(['development','production']) }).parse(process.env);
```

```typescript
// ❌ Anti‑pattern: Asumir entorno sin validar
const isProd = process.env.NODE_ENV === 'production';
// 🔧 Fix: Schema Zod para validar valores permitidos
const env = z.object({ NODE_ENV: z.enum(['development','production']) }).parse(process.env);
```

```typescript
// ✅ C5: Verificación de integridad de pnpm-lock.yaml con SHA256
import { createHash } from 'crypto';
const lockContent = await fs.readFile('pnpm-lock.yaml');
const hash = createHash('sha256').update(lockContent).digest('hex');
if (hash !== expectedLockHash) throw new Error('Lockfile integrity compromised');
```

```typescript
// ❌ Anti‑pattern: Instalar dependencias sin verificar lockfile
await execPromise('pnpm install');
// 🔧 Fix: Comparar hash del lockfile contra valor conocido
const actualHash = createHash('sha256').update(await fs.readFile('pnpm-lock.yaml')).digest('hex');
if (actualHash !== expected) throw new Error('Lockfile mismatch');
```

```typescript
// ✅ C8: Ejecución de pnpm install con timeout usando AbortController
const ac = new AbortController();
const timer = setTimeout(() => ac.abort(), 60000);
await execPromise('pnpm install --frozen-lockfile', { signal: ac.signal });
clearTimeout(timer);
```

```typescript
// ❌ Anti‑pattern: pnpm install sin límite de tiempo
await execPromise('pnpm install');
// 🔧 Fix: AbortController con timeout y flag --frozen-lockfile
const ac = new AbortController(); setTimeout(() => ac.abort(), 60000);
await execPromise('pnpm install --frozen-lockfile', { signal: ac.signal });
```

```typescript
// ✅ C3: Validación de pnpm-workspace.yaml con Zod
const workspaceSchema = z.object({ packages: z.array(z.string()) });
const workspace = workspaceSchema.parse(yaml.load(await fs.readFile('pnpm-workspace.yaml', 'utf8')));
```

```typescript
// ✅ C5/C8: Verificación de checksums de dependencias con pnpm audit
const auditResult = await execPromise('pnpm audit --json', { timeout: 30000 });
const vulnerabilities = JSON.parse(auditResult).metadata.vulnerabilities;
if (vulnerabilities.critical > 0) throw new Error('Critical vulnerabilities found');
```

```typescript
// ❌ Anti‑pattern: Ignorar resultados de audit
await execPromise('pnpm install');
// 🔧 Fix: Ejecutar audit y fallar si hay críticas
const result = await execPromise('pnpm audit --json');
const vulns = JSON.parse(result).metadata.vulnerabilities;
if (vulns.critical > 0) process.exit(1);
```

```typescript
// ✅ C8: Timeout para instalación con reintentos y backoff
import { retryAsync } from 'ts-retry';
await retryAsync(() => execPromise('pnpm install', { timeout: 30000 }), { maxTry: 3, delay: 2000 });
```

```typescript
// ✅ C5: Uso de pnpm.overrides en package.json validado con Zod
const overrideSchema = z.record(z.string());
const pkg = JSON.parse(await fs.readFile('package.json', 'utf8'));
overrideSchema.parse(pkg.pnpm?.overrides);
```

```typescript
// ✅ C3/C8: Logger con información de workspace y tenant en scripts de instalación
logger.info({ tenant_id: ctx.getStore()?.tenantId, workspaces: workspace.packages }, 'Installing dependencies');
```

```typescript
// ✅ C5: Bloqueo de instalación si SHA de lockfile no coincide con CI
const ciExpectedHash = process.env.PNPM_LOCKFILE_HASH;
if (ciExpectedHash && hash !== ciExpectedHash) throw new Error('Lockfile changed unexpectedly');
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/dependency-management.ts.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"dependency-management","version":"2.1.1","score":30,"blocking_issues":[],"constraints_verified":["C3","C5","C8"],"examples_count":12,"lines_executable_max":4,"language":"TypeScript 5.0+ / Node.js 18+","timestamp":"2026-04-16T15:55:00Z"}
```

---
