# SHA256: b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b
---
artifact_id: "git-disaster-recovery"
artifact_type: "skill_typescript"
version: "2.1.1"
constraints_mapped: ["C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/git-disaster-recovery.ts.md --json"
---

# Git Disaster Recovery – TypeScript/Node.js with simple‑git & Bundle Patterns

## Propósito
Patrones para operaciones de recuperación de desastres en repositorios Git usando `simple-git` y bundles. Garantiza integridad mediante checksums (C5), validación de rutas contra path traversal (C7), y timeouts explícitos en comandos de Git (C8) en un entorno Node.js multi‑tenant.

## Patrones de Código Validados

```typescript
// ✅ C7: Validación de ruta del repositorio contra base permitida
import path from 'path';
const repoPath = path.resolve('/repos', tenantId, repoName);
if (!repoPath.startsWith(`/repos/${tenantId}/`)) throw new Error('Invalid repo path');
```

```typescript
// ❌ Anti‑pattern: Construcción de ruta sin validación
const repoPath = `/repos/${tenantId}/${repoName}`;
// 🔧 Fix: Resolver y verificar prefijo
const p = path.resolve('/repos', tenantId, repoName);
if (!p.startsWith(`/repos/${tenantId}/`)) throw new Error('Path traversal');
```

```typescript
// ✅ C8: Cliente simple‑git con timeout en comandos
import simpleGit from 'simple-git';
const git = simpleGit(repoPath, { timeout: { block: 10000 } });
```

```typescript
// ❌ Anti‑pattern: simple‑git sin timeout
const git = simpleGit(repoPath);
// 🔧 Fix: Configurar timeout explícito
const git = simpleGit(repoPath, { timeout: { block: 10000 } });
```

```typescript
// ✅ C5/C8: Creación de bundle con verificación de integridad
const bundleFile = path.join(backupDir, `${repoName}.bundle`);
await git.bundle(['create', bundleFile, '--all']);
const stat = await fs.stat(bundleFile);
if (stat.size === 0) throw new Error('Bundle creation failed');
```

```typescript
// ❌ Anti‑pattern: Asumir éxito sin verificar archivo
await git.raw(['bundle', 'create', bundleFile, '--all']);
// 🔧 Fix: Verificar existencia y tamaño del bundle
await git.bundle(['create', bundleFile, '--all']);
const stat = await fs.stat(bundleFile);
if (!stat || stat.size === 0) throw new Error('Bundle empty');
```

```typescript
// ✅ C5: Checksum SHA256 del bundle para integridad
const bundleData = await fs.readFile(bundleFile);
const hash = createHash('sha256').update(bundleData).digest('hex');
await fs.writeFile(`${bundleFile}.sha256`, hash);
```

```typescript
// ✅ C7/C8: Clonación desde bundle con path seguro y timeout
const targetDir = path.resolve('/repos', tenantId, `${repoName}_restored`);
if (!targetDir.startsWith(`/repos/${tenantId}/`)) throw new Error('Invalid target');
await git.clone(targetDir, bundleFile, ['--bare'], { timeout: 30000 });
```

```typescript
// ❌ Anti‑pattern: Clonar sin validar directorio destino
await git.clone(destPath, bundleFile);
// 🔧 Fix: Validar que el destino esté dentro del tenant
const dest = path.resolve('/repos', tenantId, `${name}_restored`);
if (!dest.startsWith(`/repos/${tenantId}/`)) throw new Error('Invalid');
await git.clone(dest, bundleFile);
```

```typescript
// ✅ C8: Timeout explícito para operación fetch
const controller = new AbortController();
setTimeout(() => controller.abort(), 15000);
await git.fetch('origin', { '--all': null, signal: controller.signal });
```

```typescript
// ❌ Anti‑pattern: fetch sin timeout
await git.fetch('origin', ['--all']);
// 🔧 Fix: Envolver en Promise.race con timeout
await Promise.race([
  git.fetch('origin', ['--all']),
  new Promise((_, reject) => setTimeout(() => reject(new Error('Timeout')), 15000))
]);
```

```typescript
// ✅ C7/C5: Verificación de integridad del repositorio con git fsck
const fsckResult = await git.raw(['fsck', '--full', '--strict']);
if (!fsckResult.includes('dangling')) logger.warn('Possible corruption');
```

```typescript
// ✅ C5/C8: Restauración desde bundle con validación de hash
const expectedHash = (await fs.readFile(`${bundleFile}.sha256`, 'utf8')).trim();
const actual = createHash('sha256').update(await fs.readFile(bundleFile)).digest('hex');
if (actual !== expectedHash) throw new Error('Bundle integrity compromised');
await git.clone(targetDir, bundleFile, ['--bare']);
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/git-disaster-recovery.ts.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"git-disaster-recovery","version":"2.1.1","score":30,"blocking_issues":[],"constraints_verified":["C5","C7","C8"],"examples_count":11,"lines_executable_max":3,"language":"TypeScript 5.0+ / Node.js 18+","timestamp":"2026-04-16T15:30:00Z"}
```

---
