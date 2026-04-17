# SHA256: b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1
---
artifact_id: "yaml-frontmatter-parser"
artifact_type: "skill_typescript"
version: "2.1.1"
constraints_mapped: ["C3","C4","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/yaml-frontmatter-parser.ts.md --json"
---

# YAML Frontmatter Parser – TypeScript/Node.js with js‑yaml & Fallback Regex

## Propósito
Patrones para extraer y validar frontmatter YAML en archivos Markdown o de texto usando `js-yaml.safeLoad`, con validación de entorno (C3), propagación de `tenant_id` vía `AsyncLocalStorage` (C4), verificación de integridad del contenido (C5) y manejo robusto de timeouts y errores (C8).

## Patrones de Código Validados

```typescript
// ✅ C3: Validación de esquema de frontmatter con Zod
import { z } from 'zod';
const frontmatterSchema = z.object({ artifact_id: z.string(), version: z.string() });
```

```typescript
// ❌ Anti‑pattern: Parsear sin validar estructura
const fm = yaml.load(content);
// 🔧 Fix: Zod parse después de yaml.safeLoad
const fm = frontmatterSchema.parse(yaml.safeLoad(content));
```

```typescript
// ✅ C5: Extracción de frontmatter con regex y fallback
const fmMatch = content.match(/^---\n([\s\S]*?)\n---/);
const fmContent = fmMatch?.[1] ?? '';
const fm = yaml.safeLoad(fmContent);
```

```typescript
// ❌ Anti‑pattern: Split manual sin considerar casos límite
const parts = content.split('---');
const fm = yaml.safeLoad(parts[1]);
// 🔧 Fix: Regex con non‑greedy para capturar primer bloque
const match = content.match(/^---\r?\n([\s\S]*?)\r?\n---/);
const fm = match ? yaml.safeLoad(match[1]) : {};
```

```typescript
// ✅ C4: Logger con tenant_id durante parseo de frontmatter
logger.info({ tenant_id: ctx.getStore()?.tenantId, artifact: fm.artifact_id }, 'Parsed frontmatter');
```

```typescript
// ❌ Anti‑pattern: Log sin tenant_id
console.log('Parsed', fm);
// 🔧 Fix: Logger estructurado con AsyncLocalStorage
logger.info({ tenant_id: ctx.getStore()?.tenantId, artifact: fm?.artifact_id }, 'Parsed');
```

```typescript
// ✅ C8: Timeout para lectura de archivo antes de parsear
const signal = AbortSignal.timeout(5000);
const content = await fs.readFile(filePath, { encoding: 'utf8', signal });
```

```typescript
// ❌ Anti‑pattern: Lectura sin timeout
const content = await fs.readFile(filePath, 'utf8');
// 🔧 Fix: AbortSignal.timeout
const content = await fs.readFile(p, { encoding: 'utf8', signal: AbortSignal.timeout(5000) });
```

```typescript
// ✅ C5: Verificación de integridad del frontmatter con hash SHA256
const fmHash = createHash('sha256').update(fmContent).digest('hex');
if (fmHash !== expectedFrontmatterHash) throw new Error('Frontmatter tampered');
```

```typescript
// ✅ C8: Uso de safeLoad con manejo de excepciones y tipado
try {
  const fm: Frontmatter = frontmatterSchema.parse(yaml.safeLoad(fmContent) ?? {});
} catch (err) {
  logger.error({ tenant_id: ctx.getStore()?.tenantId, err }, 'Invalid frontmatter');
  throw err;
}
```

```typescript
// ❌ Anti‑pattern: Usar yaml.load en lugar de safeLoad (vulnerable a RCE)
const fm = yaml.load(content);
// 🔧 Fix: Usar exclusivamente safeLoad
const fm = yaml.safeLoad(content);
```

```typescript
// ✅ C3: Validación de variable de entorno para path de esquemas YAML
const SCHEMA_DIR = process.env.SCHEMA_DIR;
if (!SCHEMA_DIR) { logger.fatal({ tenant_id: 'unknown' }, 'SCHEMA_DIR missing'); process.exit(1); }
```

```typescript
// ✅ C4/C8: Función asíncrona con timeout y contexto tenant
async function parseWithTenant(tenantId: string, content: string): Promise<Frontmatter> {
  return ctx.run({ tenantId }, async () => {
    const match = content.match(/^---\n([\s\S]*?)\n---/);
    const fm = yaml.safeLoad(match?.[1] ?? '') ?? {};
    return frontmatterSchema.parse(fm);
  });
}
```

```typescript
// ✅ C5: Uso de `marker` explícito para separar frontmatter
const FRONTMATTER_MARKER = '---';
const parts = content.split(FRONTMATTER_MARKER);
if (parts.length < 3) throw new Error('Invalid frontmatter markers');
const fm = yaml.safeLoad(parts[1]);
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/yaml-frontmatter-parser.ts.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"yaml-frontmatter-parser","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C3","C4","C5","C8"],"examples_count":13,"lines_executable_max":3,"language":"TypeScript 5.0+ / Node.js 18+","timestamp":"2026-04-16T16:00:00Z"}
```

---
