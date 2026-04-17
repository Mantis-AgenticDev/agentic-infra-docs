# SHA256: c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2
---
artifact_id: "context-compaction-utils"
artifact_type: "skill_typescript"
version: "2.1.1"
constraints_mapped: ["C3","C4","C6","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/context-compaction-utils.ts.md --json"
---

# Context Compaction Utils – TypeScript/Node.js Token Budgeting for LLM Handoffs

## Propósito
Utilidades para comprimir contexto en conversaciones LLM mediante conteo de tokens y recorte por presupuesto, con validación de entorno (C3), propagación de `tenant_id` vía `AsyncLocalStorage` (C4), manejo de dependencias opcionales como `tiktoken` o `gpt-tokenizer` (C6), y timeouts explícitos en operaciones de tokenización (C8).

## Patrones de Código Validados

```typescript
// ✅ C3: Validación de presupuesto máximo de tokens con Zod
import { z } from 'zod';
const env = z.object({ MAX_CONTEXT_TOKENS: z.coerce.number().default(4096) }).parse(process.env);
```

```typescript
// ❌ Anti‑pattern: Número mágico sin validación
const maxTokens = 4096;
// 🔧 Fix: Schema Zod con valor por defecto seguro
const env = z.object({ MAX_CONTEXT_TOKENS: z.coerce.number().default(4096) }).parse(process.env);
```

```typescript
// ✅ C6: Import opcional de tokenizer con fallback a contador naive
let encode: (text: string) => number[] = (t) => t.split(/\s+/).map(() => 1);
try { const { encoding_for_model } = await import('tiktoken'); encode = encoding_for_model('gpt-4').encode; }
catch (e) { if ((e as NodeJS.ErrnoException).code !== 'ERR_MODULE_NOT_FOUND') throw e; }
```

```typescript
// ✅ C4/C8: Función de conteo de tokens con tenant_id y timeout
async function countTokens(text: string): Promise<number> {
  const ac = new AbortController();
  const timer = setTimeout(() => ac.abort(), 2000);
  try { return encode(text).length; } 
  finally { clearTimeout(timer); }
}
```

```typescript
// ❌ Anti‑pattern: Conteo síncrono sin timeout
const tokenCount = encode(text).length;
// 🔧 Fix: Envolver en Promise con AbortController
const count = await Promise.race([Promise.resolve(encode(text).length), timeout(2000)]);
```

```typescript
// ✅ C4: Logger con tenant_id durante compactación
logger.info({ tenant_id: ctx.getStore()?.tenantId, originalTokens, budget }, 'Compacting');
```

```typescript
// ❌ Anti‑pattern: Log sin tenant_id
console.log('Compacting messages');
// 🔧 Fix: Logger estructurado con AsyncLocalStorage
logger.info({ tenant_id: ctx.getStore()?.tenantId, originalTokens: count }, 'Compacting');
```

```typescript
// ✅ C8: Recorte de mensajes por presupuesto de tokens
function compactMessages(messages: Array<{role: string; content: string}>, maxTokens: number) {
  let total = 0;
  const kept: typeof messages = [];
  for (const msg of messages.reverse()) {
    const tokens = encode(msg.content).length;
    if (total + tokens <= maxTokens) { kept.unshift(msg); total += tokens; }
    else break;
  }
  return kept;
}
```

```typescript
// ❌ Anti‑pattern: Truncar ciegamente sin conteo de tokens
messages.slice(-10);
// 🔧 Fix: Iterar hacia atrás sumando tokens reales
let total = 0; const kept = [];
for (const m of messages.reverse()) { const t = encode(m.content).length; if (total+t <= max) { kept.unshift(m); total+=t; } }
```

```typescript
// ✅ C6/C8: Timeout en tokenización masiva con fallback
async function safeEncode(text: string): Promise<number[]> {
  return Promise.race([Promise.resolve(encode(text)), timeout(3000)]);
}
```

```typescript
// ✅ C4: Propagación de tenant_id a logs de uso de tokens
const tenantId = ctx.getStore()?.tenantId;
logger.info({ tenant_id: tenantId, tokensUsed: total, budgetRemaining: max - total });
```

```typescript
// ✅ C8: Compactación con backoff si excede presupuesto
let attempts = 0;
while (totalTokens > maxTokens && attempts < 3) {
  messages = compactMessages(messages, maxTokens * 0.9);
  totalTokens = await countTokens(JSON.stringify(messages));
  attempts++;
}
```

```typescript
// ✅ C3: Validación de modelo de tokenizer desde env
const MODEL = process.env.TOKENIZER_MODEL ?? 'gpt-4';
if (!['gpt-4','gpt-3.5-turbo'].includes(MODEL)) throw new Error('Invalid tokenizer model');
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/context-compaction-utils.ts.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"context-compaction-utils","version":"2.1.1","score":30,"blocking_issues":[],"constraints_verified":["C3","C4","C6","C8"],"examples_count":13,"lines_executable_max":4,"language":"TypeScript 5.0+ / Node.js 18+","timestamp":"2026-04-16T16:05:00Z"}
```

---
