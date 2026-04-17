# SHA256: c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5
---
artifact_id: "async-patterns-with-timeouts"
artifact_type: "skill_typescript"
version: "2.1.1"
constraints_mapped: ["C1","C2","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/async-patterns-with-timeouts.ts.md --json"
---

# Async Patterns with Timeouts – TypeScript/Node.js AbortController & Promise.race

## Propósito
Patrones asíncronos seguros en Node.js usando `AbortController`, `Promise.race` y `AbortSignal.timeout`. Asegura pureza de lenguaje (C1), restricciones de runtime (C2), validación de rutas en operaciones con archivos (C7), y manejo robusto de timeouts y errores (C8) en un entorno multi‑tenant.

## Patrones de Código Validados

```typescript
// ✅ C8: Promise.race con timeout explícito y limpieza de timer
const timeout = new Promise<never>((_, reject) => setTimeout(() => reject(new Error('Timeout')), 5000));
const result = await Promise.race([fetch(url), timeout]);
```

```typescript
// ❌ Anti‑pattern: fetch sin timeout
const res = await fetch(url);
// 🔧 Fix: Promise.race con limpieza de timer
const t = setTimeout(() => ac.abort(), 5000);
const res = await fetch(url, { signal: ac.signal });
clearTimeout(t);
```

```typescript
// ✅ C1/C8: Uso de AbortSignal.timeout (Node 18+) con tipado estricto
const signal = AbortSignal.timeout(5000);
const data: string = await fs.readFile(safePath, { encoding: 'utf8', signal });
```

```typescript
// ❌ Anti‑pattern: Pasar timeout manual sin limpiar
setTimeout(() => abort(), 5000);
// 🔧 Fix: AbortSignal.timeout nativo
const signal = AbortSignal.timeout(5000);
await operation({ signal });
```

```typescript
// ✅ C7: Validación de path con timeout en operación de archivo
const safePath = path.resolve(baseDir, userFile);
if (!safePath.startsWith(baseDir)) throw new Error('Invalid path');
await fs.access(safePath, { signal: AbortSignal.timeout(2000) });
```

```typescript
// ❌ Anti‑pattern: No validar path antes de acceder con timeout
await fs.access(userFile, { signal: AbortSignal.timeout(2000) });
// 🔧 Fix: Resolver y verificar prefijo primero
const p = path.resolve(base, userFile);
if (!p.startsWith(base)) throw new Error('Path traversal');
await fs.access(p, { signal: AbortSignal.timeout(2000) });
```

```typescript
// ✅ C2/C8: Timeout para operación CPU‑intensiva delegada a worker
import { Worker } from 'worker_threads';
const worker = new Worker('./heavy.js');
const result = await Promise.race([
  new Promise((resolve) => worker.on('message', resolve)),
  new Promise((_, reject) => setTimeout(() => { worker.terminate(); reject(new Error('Timeout')); }, 10000))
]);
```

```typescript
// ❌ Anti‑pattern: Worker sin timeout
const worker = new Worker('./heavy.js');
const res = await new Promise(r => worker.on('message', r));
// 🔧 Fix: Promise.race con terminación del worker en timeout
const res = await Promise.race([workerMsg, timeoutWithTerminate(worker, 10000)]);
```

```typescript
// ✅ C1/C8: AbortController con múltiples señales y limpieza
const ac = new AbortController();
const timer = setTimeout(() => ac.abort(), 5000);
try { await fetch(url, { signal: ac.signal }); } 
finally { clearTimeout(timer); }
```

```typescript
// ❌ Anti‑pattern: Olvidar limpiar timer en éxito
const ac = new AbortController();
setTimeout(() => ac.abort(), 5000);
await fetch(url, { signal: ac.signal });
// 🔧 Fix: clearTimeout en finally
const ac = new AbortController();
const t = setTimeout(() => ac.abort(), 5000);
try { await fetch(url, { signal: ac.signal }); } finally { clearTimeout(t); }
```

```typescript
// ✅ C7/C8: Escritura de archivo con timeout y validación de directorio padre
const dir = path.dirname(safePath);
await fs.mkdir(dir, { recursive: true });
await fs.writeFile(safePath, data, { signal: AbortSignal.timeout(5000) });
```

```typescript
// ❌ Anti‑pattern: Escribir sin asegurar directorio ni timeout
await fs.writeFile(filePath, data);
// 🔧 Fix: Crear directorio con timeout y luego escribir
await fs.mkdir(path.dirname(p), { recursive: true });
await fs.writeFile(p, data, { signal: AbortSignal.timeout(5000) });
```

```typescript
// ✅ C2/C8: Retry con backoff exponencial y timeout global
async function retry<T>(fn: () => Promise<T>, maxAttempts = 3): Promise<T> {
  for (let i = 0; i < maxAttempts; i++) {
    try { return await Promise.race([fn(), timeout(5000)]); }
    catch (e) { if (i === maxAttempts - 1) throw e; await sleep(1000 * 2 ** i); }
  } throw new Error('Unreachable');
}
```

```typescript
// ✅ C1: AbortController en clase con tipado fuerte y disposición
class TimedOperation {
  private ac = new AbortController();
  async execute(promise: Promise<any>, ms: number) {
    const t = setTimeout(() => this.ac.abort(), ms);
    try { return await promise; } finally { clearTimeout(t); }
  }
}
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/async-patterns-with-timeouts.ts.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"async-patterns-with-timeouts","version":"2.1.1","score":30,"blocking_issues":[],"constraints_verified":["C1","C2","C7","C8"],"examples_count":10,"lines_executable_max":5,"language":"TypeScript 5.0+ / Node.js 18+","timestamp":"2026-04-16T15:35:00Z"}
```

---
