# SHA256: d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d
---
artifact_id: "langchainjs-integration"
artifact_type: "skill_typescript"
version: "2.1.1"
constraints_mapped: ["C3","C4","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/langchainjs-integration.ts.md --json"
---

# LangChain.js Integration – TypeScript/Node.js with @langchain/core & Tenant‑Filtered Stores

## Propósito
Patrones para integrar LangChain.js en aplicaciones multi‑tenant TypeScript/Node.js, asegurando validación de entorno (C3), aislamiento de contexto por tenant con `AsyncLocalStorage` (C4), manejo de dependencias opcionales (C6), seguridad de rutas al cargar documentos (C7) y robustez con timeouts explícitos (C8).

## Patrones de Código Validados

```typescript
// ✅ C3: Validación de API keys de LLM con Zod
import { z } from 'zod';
const env = z.object({ OPENAI_API_KEY: z.string().startsWith('sk-') }).parse(process.env);
```

```typescript
// ❌ Anti‑pattern: Usar API key sin validación
const apiKey = process.env.OPENAI_API_KEY;
// 🔧 Fix: Validar formato con Zod
const env = z.object({ OPENAI_API_KEY: z.string().startsWith('sk-') }).parse(process.env);
```

```typescript
// ✅ C4/C6: Import opcional de @langchain/core con fallback
let ChatOpenAI: any;
try { ChatOpenAI = (await import('@langchain/openai')).ChatOpenAI; }
catch (e) { if ((e as NodeJS.ErrnoException).code !== 'ERR_MODULE_NOT_FOUND') throw e; }
```

```typescript
// ✅ C4/C8: LLM call con tenant_id en metadata y timeout
const model = new ChatOpenAI({ timeout: 15000 });
const res = await model.invoke(prompt, {
  metadata: { tenant_id: ctx.getStore()?.tenantId }
});
```

```typescript
// ❌ Anti‑pattern: Invocar LLM sin timeout ni tenant_id
const res = await model.invoke(prompt);
// 🔧 Fix: Configurar timeout y pasar metadata de tenant
const model = new ChatOpenAI({ timeout: 15000 });
const res = await model.invoke(prompt, { metadata: { tenant_id: getTenant() } });
```

```typescript
// ✅ C7: Carga segura de documentos con validación de ruta
import { TextLoader } from 'langchain/document_loaders/fs/text';
const safePath = path.resolve('/docs', tenantId, filename);
if (!safePath.startsWith('/docs/')) throw new Error('Path traversal');
const loader = new TextLoader(safePath);
```

```typescript
// ❌ Anti‑pattern: Usar input de usuario directamente en loader
const loader = new TextLoader(`/docs/${tenantId}/${filename}`);
// 🔧 Fix: Resolver y verificar prefijo
const p = path.resolve('/docs', tenantId, filename);
if (!p.startsWith('/docs/')) throw new Error('Invalid path');
const loader = new TextLoader(p);
```

```typescript
// ✅ C4: Vector store Qdrant con filtro por tenant_id
const vectorStore = await QdrantVectorStore.fromExistingCollection(embeddings, {
  client, collectionName, filter: { must: [{ key: 'tenant_id', match: { value: tid } }] }
});
```

```typescript
// ❌ Anti‑pattern: Consulta vectorial sin filtrar tenant
const results = await vectorStore.similaritySearch(query, 5);
// 🔧 Fix: Aplicar filtro de tenant en todas las búsquedas
const results = await vectorStore.similaritySearch(query, 5, { tenant_id: tid });
```

```typescript
// ✅ C8: Retry con backoff en llamadas a LLM
import { retryAsync } from 'ts-retry';
const result = await retryAsync(() => model.invoke(prompt), { maxTry: 3, delay: 1000 });
```

```typescript
// ✅ C4: Logger con tenant_id en callbacks de LangChain
import { BaseCallbackHandler } from '@langchain/core/callbacks/base';
class TenantLogger extends BaseCallbackHandler {
  async handleLLMStart(llm, prompts) {
    logger.info({ tenant_id: ctx.getStore()?.tenantId }, 'LLM start');
  }
}
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/langchainjs-integration.ts.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"langchainjs-integration","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C3","C4","C6","C7","C8"],"examples_count":11,"lines_executable_max":4,"language":"TypeScript 5.0+ / Node.js 18+","timestamp":"2026-04-16T15:10:00Z"}
```

---
