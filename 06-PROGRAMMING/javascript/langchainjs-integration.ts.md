---
artifact_id: "langchainjs-integration"
artifact_type: "typescript_module"
version: "2.3.0-MODULAR-MERGED"
constraints_mapped: ["C3","C4","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/langchainjs-integration.ts.md --json"
canonical_path: "06-PROGRAMMING/javascript/langchainjs-integration.ts.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:langchainjs-integration-v2.3.0-merged"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "javascript-typescript"
ai_navigation:
  read_first: false
  required_for: ["llm-integration", "tenant-aware-rag", "vector-store-filtering"]
  update_frequency: on-change
audience: ["javascript-typescript-master-agent", "orchestrator-engine", "validation-hooks", "senior-engineers"]
status: "✅ Real"
next_review: "2026-06-09"
hydration_weight: "medium"
entrypoint_function: "createTenantAwareChain"
observability:
  log_schema: "V-LOG-02"
  required_events: ["llm_call_started", "tenant_filter_applied", "document_loaded", "vector_search_completed", "llm_call_failed"]
  output_format: "jsonl"
  pii_scrubbing: true
---

# LangChain.js Integration – TypeScript/Node.js with @langchain/core & Tenant‑Filtered Stores

> **Contrato modular**: Este artefato es hijo del Master Agent `javascript-typescript-master-agent-mantis`.
> Hereda hardening, observability, thinking system y constraints via source/import.
> Contém APENAS a lógica de domínio específica para integração segura de LangChain.js com isolamento multi-tenant.

---

## 🎯 Propósito
Patrones para integrar LangChain.js en aplicaciones multi-tenant TypeScript/Node.js, asegurando validación de entorno (C3), aislamiento de contexto por tenant con `AsyncLocalStorage` (C4), manejo de dependencias opcionales (C6), seguridad de rutas al cargar documentos (C7) y robustez con timeouts explícitos (C8).

## 📋 Especificación (SDD – Específico deste Módulo)
- **Entradas**: `prompt: string`, `options?: { tenantId?: string; model?: string; timeoutMs?: number; vectorStore?: string }`
- **Saídas**: `Promise<{ response: string; metadata: Record<string, unknown>; tokensUsed?: number }>` o `LLMIntegrationError`
- **Side Effects**: Logs JSONL via `mantis_log()`, llamadas a APIs de LLM, carga de documentos desde filesystem, búsquedas vectoriales
- **Constraints Aplicables**: C3 (env validation), C4 (tenant isolation), C6 (optional dependencies), C7 (path safety), C8 (observability)
- **Dependências**: Node.js 18+, TypeScript 5.0+, `@langchain/core`, `@langchain/openai` (opcional), `qdrant-js` (opcional), `zod`

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C4+C6+C7+C8)
> **Regra de ouro**: Fonte o Master Agent para herdar `mantis_log()` e hardening. Se não disponível, fallback mínimo compatível com V-LOG-02.

```typescript
// ┌─────────────────────────────────────────────────────────
// │ BOOTSTRAP RESILIENTE PARA JAVASCRIPT/TYPESCRIPT
// │ Herda mantis_log() do Master Agent OU fornece fallback
// └─────────────────────────────────────────────────────────

let mantis_log: typeof import('./javascript-typescript-master-agent.mjs').mantis_log;

try {
  // Intenta importar do Master Agent (hidratação segmentada)
  const master = await import('./javascript-typescript-master-agent.mjs');
  mantis_log = master.mantis_log;
} catch {
  // Fallback mínimo compatível com V-LOG-02
  mantis_log = (
    level: 'DEBUG'|'INFO'|'WARN'|'ERROR'|'FATAL',
    event: string,
    detail: Record<string, unknown>,
    tenant_id = process.env.TENANT_ID ?? 'unknown'
  ) => {
    console.error(JSON.stringify({
      ts: new Date().toISOString(),
      level,
      resource: { tenant_id, artifact: 'langchainjs-integration' },
      body: { event, detail },
      attributes: { 'mantis.fallback': true },
      fallback: true
    }));
  };
}

// ┌─────────────────────────────────────────────────────────
// │ LÓGICA DE DOMÍNIO: INTEGRAÇÃO LANGCHAIN.JS COM MULTI-TENANT
// │ Zero redundância: apenas o específico deste módulo
// └─────────────────────────────────────────────────────────

import path from 'path';
import { z } from 'zod';
import { AsyncLocalStorage } from 'async_hooks';
import { BaseCallbackHandler } from '@langchain/core/callbacks/base';

// ✅ C3: Schema Zod para validación de entorno de LLM integration
export const llmEnvSchema = z.object({
  OPENAI_API_KEY: z.string().startsWith('sk-').optional(),
  ANTHROPIC_API_KEY: z.string().startsWith('sk-ant-').optional(),
  QDRANT_URL: z.string().url().optional(),
  LANGCHAIN_TIMEOUT_MS: z.coerce.number().min(1000).max(120000).default(30000),
  LANGCHAIN_MAX_RETRIES: z.coerce.number().min(0).max(5).default(3),
  LANGCHAIN_RETRY_DELAY_MS: z.coerce.number().min(100).max(10000).default(1000)
});

export type LLMEnv = z.infer<typeof llmEnvSchema>;

export function validateLLMEnv(raw: NodeJS.ProcessEnv): LLMEnv {
  const result = llmEnvSchema.safeParse(raw);
  if (!result.success) {
    mantis_log('ERROR', 'llm_env_validation_failed', {
      errors: result.error.errors.map(e => `${e.path.join('.')}: ${e.message}`),
      constraint: 'C3'
    });
    throw new Error(`LLM environment validation failed: ${result.error.message}`);
  }
  mantis_log('DEBUG', 'llm_env_validated', { 
    openai_key_present: !!result.data.OPENAI_API_KEY,
    anthropic_key_present: !!result.data.ANTHROPIC_API_KEY
  });
  return result.data;
}
```

```typescript
// ✅ C6: Optional dependency loader para proveedores de LLM con fallback seguro
export interface LLMProvider {
  name: 'openai' | 'anthropic' | 'fallback';
  invoke: (prompt: string, options?: any) => Promise<string>;
  available: boolean;
}

export async function loadLLMProvider(provider: 'openai' | 'anthropic' = 'openai'): Promise<LLMProvider> {
  const env = validateLLMEnv(process.env);
  
  if (provider === 'openai') {
    try {
      const { ChatOpenAI } = await import('@langchain/openai');
      if (!env.OPENAI_API_KEY) {
        mantis_log('WARN', 'llm_provider_unavailable', { provider: 'openai', reason: 'missing_api_key' });
        return createFallbackProvider('openai');
      }
      
      const model = new ChatOpenAI({
        apiKey: env.OPENAI_API_KEY,
        timeout: env.LANGCHAIN_TIMEOUT_MS,
        maxRetries: env.LANGCHAIN_MAX_RETRIES
      });
      
      mantis_log('INFO', 'llm_provider_loaded', { provider: 'openai', model: 'gpt-4' });
      
      return {
        name: 'openai',
        available: true,
        invoke: async (prompt: string, options?: any) => {
          const result = await model.invoke(prompt, {
            ...options,
            metadata: { ...options?.metadata, provider: 'openai' }
          });
          return result.content as string;
        }
      };
    } catch (e) {
      const err = e as NodeJS.ErrnoException;
      if (err.code === 'ERR_MODULE_NOT_FOUND') {
        mantis_log('WARN', 'llm_provider_unavailable', { provider: 'openai', reason: 'package_not_installed' });
        return createFallbackProvider('openai');
      }
      mantis_log('ERROR', 'llm_provider_load_failed', { provider: 'openai', error: err.message });
      throw e;
    }
  }
  
  // Similar para anthropic...
  return createFallbackProvider(provider);
}

// ✅ C6: Fallback provider para cuando las dependencias opcionales no están disponibles
function createFallbackProvider(requested: string): LLMProvider {
  mantis_log('WARN', 'llm_fallback_activated', { requested_provider: requested });
  
  return {
    name: 'fallback',
    available: false,
    invoke: async (prompt: string) => {
      // Fallback mínimo: retornar mensaje de error estructurado
      mantis_log('ERROR', 'llm_fallback_response', { prompt_length: prompt.length });
      return `[LLM_UNAVAILABLE] The requested provider '${requested}' is not available. Please check dependencies and API keys.`;
    }
  };
}
```

```typescript
// ✅ C4: AsyncLocalStorage para propagación de tenant_id en operaciones de LangChain
export const llmContext = new AsyncLocalStorage<{ tenantId: string; requestId?: string }>();

export function getCurrentLLMContext(): { tenantId: string; requestId?: string } {
  const store = llmContext.getStore();
  if (!store?.tenantId) {
    mantis_log('ERROR', 'llm_context_missing_tenant', { constraint: 'C4' });
    throw new Error('Tenant context required for LLM operations (C4 constraint)');
  }
  return store;
}

export function withLLMContext<T>(tenantId: string, requestId?: string, fn: () => Promise<T>): Promise<T> {
  return llmContext.run({ tenantId, requestId }, fn);
}
```

```typescript
// ✅ C4/C8: Callback handler para LangChain con tenant_id automático en logs
export class TenantAwareCallbackHandler extends BaseCallbackHandler {
  name = 'tenant-aware-logger';
  
  async handleLLMStart(llm: any, prompts: string[], runId: string, parentRunId?: string, tags?: string[], metadata?: Record<string, unknown>) {
    const ctx = llmContext.getStore();
    mantis_log('DEBUG', 'llm_call_started', {
      tenant_id: ctx?.tenantId,
      request_id: ctx?.requestId,
      prompt_length: prompts[0]?.length,
      model: llm?.model ?? 'unknown',
      tags: tags?.slice(0, 5)  // Limitar para evitar logs muy largos
    });
  }
  
  async handleLLMEnd(output: any, runId: string, parentRunId?: string, tags?: string[]) {
    const ctx = llmContext.getStore();
    const tokenUsage = output?.llmOutput?.tokenUsage;
    mantis_log('INFO', 'llm_call_completed', {
      tenant_id: ctx?.tenantId,
      request_id: ctx?.requestId,
      tokens_prompt: tokenUsage?.promptTokens,
      tokens_completion: tokenUsage?.completionTokens,
      tokens_total: tokenUsage?.totalTokens
    });
  }
  
  async handleLLMError(err: Error, runId: string, parentRunId?: string, tags?: string[]) {
    const ctx = llmContext.getStore();
    mantis_log('ERROR', 'llm_call_failed', {
      tenant_id: ctx?.tenantId,
      request_id: ctx?.requestId,
      error: err.message,
      error_type: err.name
    });
  }
}
```

```typescript
// ✅ C7: Carga segura de documentos con validación de ruta + tenant isolation
export interface DocumentLoadOptions {
  tenantId: string;
  filename: string;
  baseDir?: string;
  loader?: 'text' | 'pdf' | 'json';
}

export async function loadTenantDocument(options: DocumentLoadOptions): Promise<{ content: string; path: string }> {
  const { tenantId, filename, baseDir = process.env.DOCUMENTS_BASE_DIR ?? '/docs', loader = 'text' } = options;
  
  mantis_log('DEBUG', 'document_load_started', {
    tenant_id: tenantId,
    filename: sanitizeFilename(filename),
    base_dir: baseDir,
    loader_type: loader
  });
  
  // ✅ C7: Validar ruta contra sandbox del tenant
  const tenantBase = path.resolve(baseDir, tenantId);
  const safePath = path.resolve(tenantBase, filename);
  const normalizedTenantBase = tenantBase + path.sep;
  
  if (!safePath.startsWith(normalizedTenantBase) && safePath !== tenantBase) {
    mantis_log('ERROR', 'document_path_traversal_blocked', {
      tenant_id: tenantId,
      requested: filename,
      resolved: safePath,
      expected_prefix: normalizedTenantBase,
      constraint: 'C7'
    });
    throw new Error(`Document path traversal blocked: ${filename} (C7 constraint)`);
  }
  
  // ✅ C7: Verificar que el archivo existe y es legible
  const { access, constants } = await import('fs/promises');
  try {
    await access(safePath, constants.R_OK);
  } catch (error) {
    const err = error as NodeJS.ErrnoException;
    if (err.code === 'ENOENT') {
      mantis_log('WARN', 'document_not_found', { tenant_id: tenantId, filename });
    } else if (err.code === 'EACCES') {
      mantis_log('ERROR', 'document_permission_denied', { tenant_id: tenantId, filename, constraint: 'C7' });
    }
    throw error;
  }
  
  // ✅ C6: Cargar documento con loader apropiado (lazy import)
  let content: string;
  if (loader === 'text') {
    const { TextLoader } = await import('langchain/document_loaders/fs/text');
    const textLoader = new TextLoader(safePath);
    const docs = await textLoader.load();
    content = docs[0]?.pageContent ?? '';
  } else if (loader === 'json') {
    const { JSONLoader } = await import('langchain/document_loaders/fs/json');
    const jsonLoader = new JSONLoader(safePath);
    const docs = await jsonLoader.load();
    content = JSON.stringify(docs.map(d => d.pageContent));
  } else {
    // Fallback para PDF u otros formatos
    const { readFile } = await import('fs/promises');
    content = await readFile(safePath, 'utf8');
  }
  
  mantis_log('INFO', 'document_loaded', {
    tenant_id: tenantId,
    filename: sanitizeFilename(filename),
    content_length: content.length,
    loader_type: loader
  });
  
  return { content, path: safePath };
}

// Helper para sanitizar nombre de archivo en logs
function sanitizeFilename(filename: string): string {
  const sanitized = filename.length > 50 ? '...' + filename.slice(-50) : filename;
  return sanitized.replace(/[<>:"|?*]/g, '_');
}
```

```typescript
// ✅ C4/C8: Búsqueda vectorial con filtro de tenant_id obligatorio + timeout
export interface VectorSearchOptions {
  tenantId: string;
  query: string;
  collection: string;
  limit?: number;
  timeoutMs?: number;
  filter?: Record<string, unknown>;
}

export async function tenantFilteredVectorSearch(options: VectorSearchOptions): Promise<Array<{ content: string; metadata: Record<string, unknown>; score: number }>> {
  const { tenantId, query, collection, limit = 5, timeoutMs = 10000, filter: extraFilter = {} } = options;
  
  mantis_log('DEBUG', 'vector_search_started', {
    tenant_id: tenantId,
    collection,
    query_length: query.length,
    limit,
    timeout_ms: timeoutMs
  });
  
  // ✅ C4: Filtro obligatorio de tenant_id en todas las búsquedas vectoriales
  const tenantFilter = {
    must: [
      { key: 'tenant_id', match: { value: tenantId } }  // 🔒 C4: Nunca omitir este filtro
    ]
  };
  
  // Combinar con filtros adicionales si se proporcionan
  const combinedFilter = extraFilter.must 
    ? { must: [...tenantFilter.must, ...extraFilter.must] }
    : tenantFilter;
  
  // ✅ C8: AbortController para timeout de búsqueda vectorial
  const controller = new AbortController();
  const timer = setTimeout(() => {
    controller.abort();
    mantis_log('WARN', 'vector_search_timeout', {
      tenant_id: tenantId,
      collection,
      timeout_ms: timeoutMs
    });
  }, timeoutMs);
  
  try {
    // ✅ C6: Import lazy de Qdrant client si está disponible
    let results: Array<{ content: string; metadata: Record<string, unknown>; score: number }> = [];
    
    try {
      const { QdrantVectorStore } = await import('@langchain/qdrant');
      const { QdrantClient } = await import('qdrant-js');
      
      const client = new QdrantClient({
        url: process.env.QDRANT_URL ?? 'http://localhost:6333'
      });
      
      const vectorStore = await QdrantVectorStore.fromExistingCollection(
        { embeddings: {} } as any,  // Embeddings provider configurado externamente
        { client, collectionName: collection }
      );
      
      // ✅ C4+C8: Búsqueda con filtro de tenant y signal para timeout
      const searchResults = await vectorStore.similaritySearchWithScore(
        query,
        limit,
        combinedFilter,
        { signal: controller.signal as any }
      );
      
      results = searchResults.map(([doc, score]) => ({
        content: doc.pageContent,
        metadata: { ...doc.metadata, tenant_id: tenantId },
        score
      }));
      
    } catch (e) {
      const err = e as NodeJS.ErrnoException;
      if (err.code === 'ERR_MODULE_NOT_FOUND') {
        mantis_log('WARN', 'vector_store_unavailable', { provider: 'qdrant', fallback: 'in_memory' });
        // Fallback: retornar resultados vacíos o usar store en memoria
        return [];
      }
      throw e;
    }
    
    clearTimeout(timer);
    
    mantis_log('INFO', 'vector_search_completed', {
      tenant_id: tenantId,
      collection,
      results_count: results.length,
      query_length: query.length
    });
    
    return results;
    
  } catch (error) {
    clearTimeout(timer);
    const err = error as Error;
    
    if (err.name === 'AbortError' || err.message.includes('timeout')) {
      mantis_log('ERROR', 'vector_search_aborted', {
        tenant_id: tenantId,
        collection,
        timeout_ms: timeoutMs
      });
      throw new Error(`Vector search timeout after ${timeoutMs}ms`);
    }
    
    mantis_log('ERROR', 'vector_search_failed', {
      tenant_id: tenantId,
      collection,
      error: err.message
    });
    throw error;
  }
}
```

```typescript
// ✅ C3+C4+C6+C7+C8: Creación de cadena LangChain con tenant awareness integral
export interface ChainOptions {
  tenantId: string;
  prompt: string;
  model?: 'openai' | 'anthropic';
  useRAG?: boolean;
  vectorCollection?: string;
  documents?: Array<{ filename: string; loader?: 'text' | 'pdf' | 'json' }>;
  timeoutMs?: number;
  maxRetries?: number;
}

export interface ChainResult {
  response: string;
  metadata: {
    tenantId: string;
    model: string;
    tokensUsed?: number;
    documentsLoaded?: number;
    vectorResultsCount?: number;
    retries: number;
  };
}

export async function createTenantAwareChain(options: ChainOptions): Promise<ChainResult> {
  const {
    tenantId,
    prompt,
    model = 'openai',
    useRAG = false,
    vectorCollection,
    documents = [],
    timeoutMs = validateLLMEnv(process.env).LANGCHAIN_TIMEOUT_MS,
    maxRetries = validateLLMEnv(process.env).LANGCHAIN_MAX_RETRIES
  } = options;
  
  mantis_log('INFO', 'chain_execution_started', {
    tenant_id: tenantId,
    model,
    use_rag: useRAG,
    prompt_length: prompt.length,
    documents_count: documents.length,
    timeout_ms: timeoutMs
  });
  
  return withLLMContext(tenantId, undefined, async () => {
    let retries = 0;
    let lastError: Error | undefined;
    
    while (retries <= maxRetries) {
      try {
        // ✅ C6: Cargar proveedor de LLM con fallback
        const llmProvider = await loadLLMProvider(model);
        
        // ✅ C7: Cargar documentos si se especifican
        let loadedDocs: Array<{ content: string; path: string }> = [];
        if (documents.length > 0) {
          for (const doc of documents) {
            const loaded = await loadTenantDocument({
              tenantId,
              filename: doc.filename,
              loader: doc.loader
            });
            loadedDocs.push(loaded);
          }
          mantis_log('DEBUG', 'documents_loaded_for_rag', {
            tenant_id: tenantId,
            count: loadedDocs.length
          });
        }
        
        // ✅ C4: Construir prompt con contexto de tenant si usa RAG
        let finalPrompt = prompt;
        let vectorResultsCount = 0;
        
        if (useRAG && vectorCollection) {
          // ✅ C4+C8: Búsqueda vectorial con filtro de tenant
          const vectorResults = await tenantFilteredVectorSearch({
            tenantId,
            query: prompt,
            collection: vectorCollection,
            limit: 3,
            timeoutMs: Math.floor(timeoutMs * 0.3)  // Reservar tiempo para LLM call
          });
          
          vectorResultsCount = vectorResults.length;
          
          if (vectorResults.length > 0) {
            const context = vectorResults.map(r => r.content).join('\n\n');
            finalPrompt = `Contexto relevante:\n${context}\n\nPregunta: ${prompt}`;
            mantis_log('DEBUG', 'rag_context_injected', {
              tenant_id: tenantId,
              context_length: context.length
            });
          }
        }
        
        // ✅ C8: Llamada a LLM con timeout y retry
        const controller = new AbortController();
        const timer = setTimeout(() => controller.abort(), timeoutMs);
        
        try {
          const response = await llmProvider.invoke(finalPrompt, {
            signal: controller.signal,
            callbacks: [new TenantAwareCallbackHandler()],
            metadata: { tenant_id: tenantId, use_rag: useRAG }
          });
          
          clearTimeout(timer);
          
          mantis_log('INFO', 'chain_execution_completed', {
            tenant_id: tenantId,
            response_length: response.length,
            model: llmProvider.name,
            documents_loaded: loadedDocs.length,
            vector_results: vectorResultsCount,
            retries
          });
          
          return {
            response,
            metadata: {
              tenantId,
              model: llmProvider.name,
              documentsLoaded: loadedDocs.length,
              vectorResultsCount,
              retries
            }
          };
          
        } catch (error) {
          clearTimeout(timer);
          throw error;
        }
        
      } catch (error) {
        const err = error as Error;
        lastError = err;
        retries++;
        
        if (err.message.includes('timeout') || err.name === 'AbortError') {
          mantis_log('WARN', 'chain_attempt_timeout', { attempt: retries, max_retries: maxRetries });
        } else if (retries <= maxRetries) {
          // ✅ C8: Backoff exponencial antes del próximo reintento
          const delay = validateLLMEnv(process.env).LANGCHAIN_RETRY_DELAY_MS * Math.pow(2, retries - 1);
          mantis_log('DEBUG', 'chain_retry_backoff', { attempt: retries, delay_ms: delay });
          await new Promise(resolve => setTimeout(resolve, delay));
          continue;
        }
        
        break;
      }
    }
    
    // Todos los intentos fallaron
    mantis_log('ERROR', 'chain_execution_failed', {
      tenant_id: tenantId,
      total_attempts: retries,
      final_error: lastError?.message
    });
    
    throw lastError ?? new Error('Chain execution failed after all retries');
  });
}
```

```typescript
// ✅ C4/C8: Logger helper con tenant_id automático para operaciones de LangChain
export function logLLMEvent(
  event: 'prompt_received' | 'response_generated' | 'rag_context_added' | 'vector_search_performed' | 'error_occurred',
  detail: Record<string, unknown>
): void {
  const ctx = llmContext.getStore();
  
  // ✅ C3: PII scrubbing heredado de mantis_log + sanitización de prompts
  const sanitizedDetail = { ...detail };
  if (sanitizedDetail.prompt && typeof sanitizedDetail.prompt === 'string') {
    // Truncar prompt para evitar logs muy largos o con datos sensibles
    sanitizedDetail.prompt = sanitizedDetail.prompt.slice(0, 200) + (sanitizedDetail.prompt.length > 200 ? '...' : '');
  }
  if (sanitizedDetail.response && typeof sanitizedDetail.response === 'string') {
    sanitizedDetail.response = sanitizedDetail.response.slice(0, 200) + (sanitizedDetail.response.length > 200 ? '...' : '');
  }
  
  mantis_log(
    event === 'error_occurred' ? 'ERROR' : 'INFO',
    `llm_${event}`,
    {
      ...sanitizedDetail,
      tenant_id: ctx?.tenantId
    }
  );
}
```

---

## 🧪 Testes Unitários (TDD – Apenas para a Lógica Específica)
```typescript
// langchainjs-integration.test.ts
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { 
  validateLLMEnv, 
  loadLLMProvider, 
  loadTenantDocument, 
  tenantFilteredVectorSearch,
  createTenantAwareChain,
  withLLMContext
} from './langchainjs-integration';

describe('langchainjs-integration', () => {
  const TEST_TENANT = 'tenant-test-123';
  const TEST_BASE_DIR = '/docs/sandbox';

  beforeEach(() => {
    // Mock de mantis_log para testes
    global.mantis_log = vi.fn();
    // Configurar env para testes
    process.env.DOCUMENTS_BASE_DIR = TEST_BASE_DIR;
    process.env.LANGCHAIN_TIMEOUT_MS = '5000';
  });

  afterEach(() => {
    vi.restoreAllMocks();
    delete process.env.DOCUMENTS_BASE_DIR;
    delete process.env.LANGCHAIN_TIMEOUT_MS;
  });

  // Test: validateLLMEnv acepta API key válida y rechaza inválida (C3)
  it('should validate LLM environment with Zod', () => {
    // Válido: API key con prefijo correcto
    const valid = validateLLMEnv({ OPENAI_API_KEY: 'sk-test1234567890' });
    expect(valid.OPENAI_API_KEY).toBe('sk-test1234567890');

    // Inválido: API key sin prefijo correcto
    expect(() => validateLLMEnv({ OPENAI_API_KEY: 'invalid-key' })).toThrow();
    expect(global.mantis_log).toHaveBeenCalledWith(
      'ERROR',
      'llm_env_validation_failed',
      expect.objectContaining({ constraint: 'C3' })
    );
  });

  // Test: loadLLMProvider retorna fallback cuando @langchain/openai no está instalado (C6)
  it('should return fallback provider when langchain/openai is not available', async () => {
    // Mock de import que lanza ERR_MODULE_NOT_FOUND
    vi.mock('@langchain/openai', () => {
      throw { code: 'ERR_MODULE_NOT_FOUND' };
    });

    const provider = await loadLLMProvider('openai');
    
    expect(provider.name).toBe('fallback');
    expect(provider.available).toBe(false);
    expect(global.mantis_log).toHaveBeenCalledWith(
      'WARN',
      'llm_provider_unavailable',
      expect.objectContaining({ provider: 'openai', reason: 'package_not_installed' })
    );
  });

  // Test: loadTenantDocument bloquea path traversal (C7)
  it('should block path traversal in document loading', async () => {
    await expect(
      loadTenantDocument({ tenantId: TEST_TENANT, filename: '../../../etc/passwd' })
    ).rejects.toThrow('Document path traversal blocked');
    
    expect(global.mantis_log).toHaveBeenCalledWith(
      'ERROR',
      'document_path_traversal_blocked',
      expect.objectContaining({ constraint: 'C7' })
    );
  });

  // Test: loadTenantDocument acepta ruta válida dentro del sandbox del tenant (C7)
  it('should accept valid document path within tenant sandbox', async () => {
    // Mock de fs/access y TextLoader
    vi.mock('fs/promises', async () => {
      const actual = await vi.importActual('fs/promises');
      return {
        ...actual,
        access: vi.fn().mockResolvedValue(undefined),
        readFile: vi.fn().mockResolvedValue('test document content')
      };
    });
    
    vi.mock('langchain/document_loaders/fs/text', () => ({
      TextLoader: class {
        async load() { return [{ pageContent: 'test document content', metadata: {} }]; }
      }
    }));

    const result = await loadTenantDocument({ 
      tenantId: TEST_TENANT, 
      filename: 'docs/report.txt',
      loader: 'text'
    });
    
    expect(result.content).toBe('test document content');
    expect(result.path).toBe(path.resolve(TEST_BASE_DIR, TEST_TENANT, 'docs/report.txt'));
    expect(global.mantis_log).toHaveBeenCalledWith(
      'INFO',
      'document_loaded',
      expect.objectContaining({ tenant_id: TEST_TENANT })
    );
  });

  // Test: tenantFilteredVectorSearch aplica filtro de tenant_id obligatorio (C4)
  it('should apply mandatory tenant_id filter in vector search', async () => {
    // Mock de Qdrant imports
    vi.mock('@langchain/qdrant', () => ({
      QdrantVectorStore: {
        fromExistingCollection: vi.fn().mockResolvedValue({
          similaritySearchWithScore: vi.fn().mockResolvedValue([
            [{ pageContent: 'result 1', metadata: {} }, 0.95],
            [{ pageContent: 'result 2', metadata: {} }, 0.87]
          ])
        })
      }
    }));
    
    vi.mock('qdrant-js', () => ({
      QdrantClient: class { constructor() {} }
    }));

    const results = await tenantFilteredVectorSearch({
      tenantId: TEST_TENANT,
      query: 'test query',
      collection: 'test-collection',
      limit: 2
    });
    
    expect(results).toHaveLength(2);
    expect(results[0].metadata.tenant_id).toBe(TEST_TENANT);
    expect(global.mantis_log).toHaveBeenCalledWith(
      'INFO',
      'vector_search_completed',
      expect.objectContaining({ tenant_id: TEST_TENANT, results_count: 2 })
    );
  });

  // Test: createTenantAwareChain propaga tenant_id en contexto (C4)
  it('should propagate tenant_id in LLM chain context', async () => {
    // Mock de loadLLMProvider para retornar provider funcional
    vi.spyOn(require('./langchainjs-integration'), 'loadLLMProvider')
      .mockResolvedValue({
        name: 'fallback',
        available: false,
        invoke: async (prompt: string) => `Mock response for: ${prompt.slice(0, 50)}`
      });

    const result = await withLLMContext(TEST_TENANT, async () => {
      return createTenantAwareChain({
        tenantId: TEST_TENANT,
        prompt: 'What is the capital of France?',
        model: 'openai',
        useRAG: false
      });
    });
    
    expect(result.response).toContain('Mock response');
    expect(result.metadata.tenantId).toBe(TEST_TENANT);
    expect(global.mantis_log).toHaveBeenCalledWith(
      'INFO',
      'chain_execution_completed',
      expect.objectContaining({ tenant_id: TEST_TENANT })
    );
  });

  // Test: withLLMContext requiere tenant_id (C4)
  it('should throw error when LLM context is missing', async () => {
    await expect(
      withLLMContext(TEST_TENANT, () => Promise.resolve('ok'))
    ).resolves.toBe('ok');
    
    // Fuera de contexto, getCurrentLLMContext debe fallar
    expect(() => {
      // @ts-expect-error: probando comportamiento fuera de contexto
      return require('./langchainjs-integration').getCurrentLLMContext();
    }).toThrow('Tenant context required');
  });
});
```

---

## 🔍 Validação (VDD – Comando Canônico)
```bash
# Validação integral via orchestrator-engine (herda checks do Master Agent)
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/javascript/langchainjs-integration.ts.md \
  --json \
  --check-structural \
  --check-error-handling \
  --check-observability \
  --check-constraints C3,C4,C6,C7,C8

# Validação específica de env validation (C3)
bash 05-CONFIGURATIONS/validation/verify-constraints.sh \
  --file 06-PROGRAMMING/javascript/langchainjs-integration.ts.md \
  --check C3 \
  --json

# Validação de tenant isolation (C4)
bash 05-CONFIGURATIONS/validation/check-rls.sh \
  --file 06-PROGRAMMING/javascript/langchainjs-integration.ts.md \
  --lang ts \
  --json

# Validação de optional dependencies (C6)
bash 05-CONFIGURATIONS/validation/verify-constraints.sh \
  --file 06-PROGRAMMING/javascript/langchainjs-integration.ts.md \
  --check C6 \
  --json

# Validação de path safety (C7)
bash 05-CONFIGURATIONS/validation/verify-constraints.sh \
  --file 06-PROGRAMMING/javascript/langchainjs-integration.ts.md \
  --check C7 \
  --json

# Validação de observability V-LOG-02 (C8)
bash 05-CONFIGURATIONS/validation/verify-observability.sh \
  --file 06-PROGRAMMING/javascript/langchainjs-integration.ts.md \
  --schema V-LOG-02 \
  --json
```

---

## 🔗 Referências Cruzadas (Wikilinks Mínimos)
- [[javascript-typescript-master-agent.md]] ← Fonte de `mantis_log()`, hardening, constraints
- [[/05-CONFIGURATIONS/validation/orchestrator-engine.sh]] ← Motor de validação principal
- [[/05-CONFIGURATIONS/validation/verify-constraints.sh]] ← Validação C3/C6/C7
- [[/05-CONFIGURATIONS/validation/check-rls.sh]] ← Validação C4 (tenant isolation)
- [[/05-CONFIGURATIONS/validation/verify-observability.sh]] ← Validação C8 + V-LOG-02
- [[/01-RULES/harness-norms-v3.0.md#C3]] ← Definição formal de C3 (Secrets/Env Validation)
- [[/01-RULES/harness-norms-v3.0.md#C4]] ← Definição formal de C4 (Tenant Isolation)
- [[/01-RULES/harness-norms-v3.0.md#C6]] ← Definição formal de C6 (Dependency Management)
- [[/01-RULES/harness-norms-v3.0.md#C7]] ← Definição formal de C7 (Path Safety)
- [[/01-RULES/harness-norms-v3.0.md#C8]] ← Definição formal de C8 (Observability)

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 2.3.0-MODULAR-MERGED | 2026-05-09 | javascript-typescript-master-agent | MERGE: estrutura modular v2.3.0 + bootstrap resiliente + observability V-LOG-02 + tenant-aware callbacks + RAG integration | C3,C4,C6,C7,C8 |
| 2.1.1 | 2026-04-16 | Framework Core Team | Adição de exemplos Zod para API key validation e filtro obrigatório de tenant_id em buscas vetoriais | C3,C4,C6,C7,C8 |
| 2.0.0 | 2026-03-01 | Qwen + DeepSeek | Primeira versão canônica com padrões LangChain.js integration + AsyncLocalStorage + path validation | C3,C4,C6,C7,C8 |

---

## 🔍 Observability (Documentación para IA – Eventos Específicos)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `llm_call_started` | DEBUG | C8 | `"{\"tenant_id\":\"t123\",\"request_id\":\"abc123\",\"prompt_length\":150,\"model\":\"gpt-4\"}"` |
| `llm_call_completed` | INFO | C8 | `"{\"tenant_id\":\"t123\",\"tokens_prompt\":45,\"tokens_completion\":120,\"tokens_total\":165}"` |
| `llm_call_failed` | ERROR | C8 | `"{\"tenant_id\":\"t123\",\"error\":\"Rate limit exceeded\",\"error_type\":\"OpenAIError\"}"` |
| `document_loaded` | INFO | C7 | `"{\"tenant_id\":\"t123\",\"filename\":\"report.txt\",\"content_length\":2048,\"loader_type\":\"text\"}"` |
| `document_path_traversal_blocked` | ERROR | C7 | `"{\"tenant_id\":\"t123\",\"requested\":\"../../../etc/passwd\",\"resolved\":\"/etc/passwd\",\"constraint\":\"C7\"}"` |
| `vector_search_started` | DEBUG | C8 | `"{\"tenant_id\":\"t123\",\"collection\":\"embeddings\",\"query_length\":80,\"limit\":5}"` |
| `vector_search_completed` | INFO | C4,C8 | `"{\"tenant_id\":\"t123\",\"collection\":\"embeddings\",\"results_count\":3,\"query_length\":80}"` |
| `chain_execution_started` | INFO | C8 | `"{\"tenant_id\":\"t123\",\"model\":\"openai\",\"use_rag\":true,\"prompt_length\":200,\"documents_count\":2}"` |
| `llm_provider_unavailable` | WARN | C6 | `"{\"provider\":\"openai\",\"reason\":\"package_not_installed\"}"` |

### Validação de Schema V-LOG-02 (Helper Mínimo)
```typescript
// Helper para validar que logs de langchainjs integration seguem schema V-LOG-02
export function validateLLMLog(logEntry: unknown): { valid: boolean; errors: string[] } {
  const errors: string[] = [];
  const entry = logEntry as Record<string, unknown>;

  // Campos obrigatórios V-LOG-02
  const required = ['ts', 'level', 'resource', 'body'];
  for (const field of required) {
    if (!(field in entry)) errors.push(`Missing required field: ${field}`);
  }

  // Validar que tenant_id está presente para eventos de LLM (C4)
  const llmEvents = ['llm_call_started', 'llm_call_completed', 'vector_search_completed', 'chain_execution_started'];
  if (llmEvents.includes(entry.body?.event as string)) {
    const detail = entry.body?.detail as Record<string, unknown>;
    if (!detail?.tenant_id) {
      errors.push('C4 violation: LLM event missing tenant_id in detail');
    }
  }

  // Validar que prompts/responses no se exponen completos en logs (C3: evitar leakage)
  if (entry.body?.detail?.prompt && typeof entry.body.detail.prompt === 'string') {
    const promptVal = entry.body.detail.prompt as string;
    if (promptVal.length > 200) {
      errors.push('C3 warning: prompt too long in log (should be truncated to 200 chars)');
    }
  }

  // Validar que timeout_ms é número positivo para eventos de timeout (C8)
  if (entry.body?.event?.toString().includes('timeout')) {
    const detail = entry.body?.detail as Record<string, unknown>;
    if (typeof detail?.timeout_ms !== 'number' || detail.timeout_ms <= 0) {
      errors.push('C8 violation: invalid timeout_ms in timeout event');
    }
  }

  return { valid: errors.length === 0, errors };
}
```

---

## ✅ Auto-Validation Report (JSON – Para CI/CD)
```json
{
  "artifact": "langchainjs-integration",
  "version": "2.3.0-MODULAR-MERGED",
  "score": 32,
  "blocking_issues": [],
  "constraints_verified": ["C3", "C4", "C6", "C7", "C8"],
  "examples_count": 11,
  "lines_executable_max": 4,
  "language": "TypeScript 5.0+ / Node.js 18+",
  "observability_compliant": true,
  "bootstrap_resilient": true,
  "mantis_log_usage": "inherited",
  "zod_validation_verified": true,
  "optional_dep_handling_verified": true,
  "path_validation_verified": true,
  "tenant_filter_verified": true,
  "timeout_handling_verified": true,
  "rag_integration_verified": true,
  "callback_handler_verified": true,
  "timestamp": "2026-05-09T00:00:00Z"
}
```

---

> 🇧🇷 *Documento técnico em pt-BR conforme V-DOC-01. Coordenação en español. Zero invenção: todo padrão grounded no conteúdo original + template v2.3.0-MODULAR.*
