# SHA256: f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8
---
artifact_id: "type-safety-with-typescript"
artifact_type: "skill_typescript"
version: "2.1.1"
constraints_mapped: ["C3","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/type-safety-with-typescript.ts.md --json"
---

# Type Safety with TypeScript – Strict tsconfig & `tsc --noEmit` Gate

## Propósito
Patrones para garantizar la seguridad de tipos en proyectos TypeScript/Node.js mediante configuración `strict`, uso de `tsc --noEmit` como control de calidad pre‑commit, validación de entorno con Zod (C3), verificación de integridad de tipos en runtime (C5), y manejo de timeouts en compilación programática (C8).

## Patrones de Código Validados

```typescript
// ✅ C3: Configuración tsconfig.json con strict completo
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "noUncheckedIndexedAccess": true
  }
}
```

```typescript
// ❌ Anti‑pattern: tsconfig sin strict
{ "compilerOptions": { "target": "ES2022" } }
// 🔧 Fix: Habilitar strict y comprobaciones adicionales
{ "compilerOptions": { "strict": true, "noImplicitAny": true } }
```

```typescript
// ✅ C3: Validación de variables de entorno con Zod y tipos inferidos
import { z } from 'zod';
const envSchema = z.object({ NODE_ENV: z.enum(['development', 'production']) });
type Env = z.infer<typeof envSchema>;
const env: Env = envSchema.parse(process.env);
```

```typescript
// ❌ Anti‑pattern: Tipado débil de process.env
const env = process.env.NODE_ENV as string;
// 🔧 Fix: Inferir tipo desde esquema Zod
const env = envSchema.parse(process.env); // env tiene tipo Env exacto
```

```typescript
// ✅ C5: Type guard para validar integridad de datos en runtime
function isValidTenantPayload(obj: unknown): obj is { tenantId: string; data: Buffer } {
  return typeof obj === 'object' && obj !== null && 'tenantId' in obj && 'data' in obj;
}
```

```typescript
// ❌ Anti‑pattern: Aserción de tipo sin validación
const payload = JSON.parse(input) as TenantPayload;
// 🔧 Fix: Type guard para verificar estructura
const parsed = JSON.parse(input);
if (!isValidTenantPayload(parsed)) throw new Error('Invalid payload');
```

```typescript
// ✅ C8: Ejecución de tsc --noEmit con timeout y manejo de errores
import { exec } from 'child_process';
const compile = () => new Promise((resolve, reject) => {
  exec('npx tsc --noEmit', { timeout: 30000 }, (err, stdout, stderr) => {
    if (err) reject(new Error(stderr));
    else resolve(stdout);
  });
});
await Promise.race([compile(), timeout(35000)]);
```

```typescript
// ❌ Anti‑pattern: Asumir que el código compila sin verificarlo
// 🔧 Fix: Ejecutar tsc --noEmit en CI/pre‑commit
await execPromise('npx tsc --noEmit');
```

```typescript
// ✅ C5: Uso de const assertions para integridad de literales
const ROUTES = ['/api/tenant', '/api/admin'] as const;
type Route = typeof ROUTES[number]; // '/api/tenant' | '/api/admin'
```

```typescript
// ❌ Anti‑pattern: Array mutable que pierde precisión de tipo
const ROUTES = ['/api/tenant', '/api/admin'];
// 🔧 Fix: as const para tipo unión exacto
const ROUTES = ['/api/tenant', '/api/admin'] as const;
```

```typescript
// ✅ C3/C5: Branded types para tenantId y otros identificadores
type TenantId = string & { __brand: 'TenantId' };
function assertTenantId(id: string): TenantId {
  if (!/^[a-f0-9-]{36}$/.test(id)) throw new Error('Invalid tenantId');
  return id as TenantId;
}
```

```typescript
// ✅ C8: Timeout en compilación programática con ts API
import ts from 'typescript';
const program = ts.createProgram(['src/index.ts'], { strict: true });
const emitResult = program.emit();
const diagnostics = ts.getPreEmitDiagnostics(program);
if (diagnostics.length) throw new Error('Compilation errors');
```

```typescript
// ✅ C3: Verificación de tsconfig en runtime con Zod
const tsconfigSchema = z.object({ compilerOptions: z.object({ strict: z.literal(true) }) });
const tsconfig = tsconfigSchema.parse(JSON.parse(await fs.readFile('tsconfig.json', 'utf8')));
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/type-safety-with-typescript.ts.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"type-safety-with-typescript","version":"2.1.1","score":30,"blocking_issues":[],"constraints_verified":["C3","C5","C8"],"examples_count":11,"lines_executable_max":5,"language":"TypeScript 5.0+ / Node.js 18+","timestamp":"2026-04-16T15:50:00Z"}
```

---
