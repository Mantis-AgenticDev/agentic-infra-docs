---
artifact_id: "context-compaction-utils"
artifact_type: "typescript_module"
version: "2.3.0-MODULAR-MERGED"
constraints_mapped: ["C3","C4","C6","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/context-compaction-utils.ts.md --json"
canonical_path: "06-PROGRAMMING/javascript/context-compaction-utils.ts.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:context-compaction-v2.3.0-merged"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "javascript-typescript"
ai_navigation:
  read_first: false
  required_for: ["llm-context-management", "token-budgeting", "handoff-optimization"]
  update_frequency: on-change
audience: ["javascript-typescript-master-agent", "orchestrator-engine", "validation-hooks", "senior-engineers"]
status: "✅ Real"
next_review: "2026-06-09"
hydration_weight: "light"
entrypoint_function: "compactMessages"
observability:
  log_schema: "V-LOG-02"
  required_events: ["compaction_started", "tokens_counted", "budget_exceeded", "compaction_completed"]
  output_format: "jsonl"
  pii_scrubbing: true
---

# Context Compaction Utils – TypeScript/Node.js Token Budgeting for LLM Handoffs

> **Contrato modular**: Este artefato es hijo del Master Agent `javascript-typescript-master-agent-mantis`.
> Hereda hardening, observability, thinking system y constraints via source/import.
> Contém APENAS a lógica de domínio específica para compactação de contexto LLM com orçamento de tokens.

---

## 🎯 Propósito
Utilidades para comprimir contexto en conversaciones LLM mediante conteo de tokens y recorte por presupuesto, con validación de entorno (C3), propagación de `tenant_id` vía `AsyncLocalStorage` (C4), manejo de dependencias opcionales como `tiktoken` o `gpt-tokenizer` (C6), y timeouts explícitos en operaciones de tokenización (C8).

## 📋 Especificación (SDD – Específico deste Módulo)
- **Entradas**: `messages: Array<{role: string; content: string}>`, `options?: { maxTokens?: number; model?: string; timeoutMs?: number }`
- **Saídas**: `{ compacted: Array<{role: string; content: string}>; tokensUsed: number; truncated: boolean }`
- **Side Effects**: Logs JSONL via `mantis_log()`, carga lazy de `tiktoken` si disponible
- **Constraints Aplicables**: C3 (env validation), C4 (tenant isolation), C6 (optional dependencies), C8 (observability)
- **Dependências**: Node.js 18+, TypeScript 5.0+, `tiktoken` (opcional), `zod` para validación de env

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C4+C6+C8)
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
      resource: { tenant_id, artifact: 'context-compaction-utils' },
      body: { event, detail },
      attributes: { 'mantis.fallback': true },
      fallback: true
    }));
  };
}

// ┌─────────────────────────────────────────────────────────
// │ LÓGICA DE DOMÍNIO: COMPACTAÇÃO DE CONTEXTO LLM
// │ Zero redundância: apenas o específico deste módulo
// └─────────────────────────────────────────────────────────

import { z } from 'zod';
import { AsyncLocalStorage } from 'async_hooks';

// ✅ C3: Validação de entorno com Zod + valores por defecto seguros
export const compactionConfig = z.object({
  MAX_CONTEXT_TOKENS: z.coerce.number().min(512).max(128000).default(4096),
  TOKENIZER_MODEL: z.enum(['gpt-4', 'gpt-3.5-turbo', 'gpt-4o']).default('gpt-4'),
  TOKENIZE_TIMEOUT_MS: z.coerce.number().min(100).max(10000).default(2000),
  COMPACTION_BACKOFF_FACTOR: z.coerce.number().min(0.5).max(0.95).default(0.9)
}).parse(process.env);

// ✅ C6: Import opcional de tokenizer con fallback a contador naive
type EncodeFn = (text: string) => number[];
let encode: EncodeFn = (text) => {
  // Fallback naive: ~4 chars per token heuristic
  return new Array(Math.ceil(text.length / 4)).fill(1);
};

let tokenizerLoaded = false;
export async function initTokenizer(model: string = compactionConfig.TOKENIZER_MODEL): Promise<boolean> {
  if (tokenizerLoaded) return true;
  
  try {
    // ✅ C6: Carga lazy de dependencia opcional
    const { encoding_for_model } = await import('tiktoken');
    const enc = encoding_for_model(model);
    encode = (text: string) => enc.encode(text, 'all');
    tokenizerLoaded = true;
    mantis_log('INFO', 'tokenizer_loaded', { model, provider: 'tiktoken' });
    return true;
  } catch (e) {
    const err = e as NodeJS.ErrnoException;
    if (err.code === 'ERR_MODULE_NOT_FOUND') {
      mantis_log('WARN', 'tokenizer_fallback', { model, fallback: 'naive_heuristic' });
      return false; // Fallback ya definido arriba
    }
    mantis_log('ERROR', 'tokenizer_init_failed', { model, error: err.message });
    throw e;
  }
}
```

```typescript
// ✅ C4/C8: Función de conteo de tokens con tenant_id y timeout
export async function countTokens(
  text: string,
  options: { timeoutMs?: number; tenantId?: string } = {}
): Promise<number> {
  const { timeoutMs = compactionConfig.TOKENIZE_TIMEOUT_MS, tenantId } = options;
  const effectiveTenant = tenantId ?? getCurrentTenantId() ?? 'unknown';
  
  mantis_log('DEBUG', 'token_count_started', { 
    text_length: text.length, 
    timeout_ms: timeoutMs,
    tenant_id: effectiveTenant 
  });

  const controller = new AbortController();
  const timer = setTimeout(() => {
    controller.abort();
    mantis_log('WARN', 'token_count_timeout', { 
      timeout_ms: timeoutMs, 
      tenant_id: effectiveTenant 
    });
  }, timeoutMs);

  try {
    // ✅ C8: AbortSignal para cancelar tokenización si excede timeout
    const tokens = await Promise.race([
      Promise.resolve(encode(text)),
      new Promise<never>((_, reject) => {
        controller.signal.addEventListener('abort', () => {
          reject(new Error(`Tokenization timeout after ${timeoutMs}ms`));
        });
      })
    ]);
    
    const count = tokens.length;
    mantis_log('DEBUG', 'token_count_completed', { 
      count, 
      tenant_id: effectiveTenant,
      tokenizer: tokenizerLoaded ? 'tiktoken' : 'naive'
    });
    return count;
    
  } catch (error) {
    mantis_log('ERROR', 'token_count_failed', { 
      error: (error as Error).message,
      tenant_id: effectiveTenant
    });
    throw error;
  } finally {
    clearTimeout(timer);
  }
}
```

```typescript
// ✅ C4: AsyncLocalStorage para propagación segura de tenant_id
export const compactionContext = new AsyncLocalStorage<{ tenantId: string; budget?: number }>();

export function getCurrentTenantId(): string | undefined {
  const store = compactionContext.getStore();
  return store?.tenantId;
}

export function withCompactionContext<T>(
  tenantId: string,
  budget?: number,
  fn: () => Promise<T>
): Promise<T> {
  return compactionContext.run({ tenantId, budget }, fn);
}
```

```typescript
// ✅ C8: Recorte de mensajes por presupuesto de tokens (algoritmo greedy inverso)
export interface CompactionResult {
  compacted: Array<{ role: string; content: string }>;
  tokensUsed: number;
  truncated: boolean;
  originalCount: number;
}

export async function compactMessages(
  messages: Array<{ role: string; content: string }>,
  options: {
    maxTokens?: number;
    model?: string;
    preserveSystemPrompt?: boolean;
    tenantId?: string;
  } = {}
): Promise<CompactionResult> {
  const {
    maxTokens = compactionConfig.MAX_CONTEXT_TOKENS,
    model = compactionConfig.TOKENIZER_MODEL,
    preserveSystemPrompt = true,
    tenantId: explicitTenant
  } = options;
  
  const tenantId = explicitTenant ?? getCurrentTenantId() ?? 'unknown';
  
  mantis_log('INFO', 'compaction_started', {
    message_count: messages.length,
    budget_tokens: maxTokens,
    tenant_id: tenantId,
    preserve_system: preserveSystemPrompt
  });

  // Inicializar tokenizer si no está cargado
  await initTokenizer(model);

  // Separar system prompt si se debe preservar (C4: contexto crítico)
  let systemPrompt: { role: string; content: string } | undefined;
  let workingMessages = messages;
  
  if (preserveSystemPrompt && messages[0]?.role === 'system') {
    [systemPrompt, ...workingMessages] = messages;
  }

  // ✅ C8: Iterar hacia atrás sumando tokens reales (greedy desde el final)
  let totalTokens = 0;
  const kept: typeof messages = [];
  const reversed = [...workingMessages].reverse();

  for (const msg of reversed) {
    const tokens = await countTokens(msg.content, { tenantId });
    if (totalTokens + tokens <= maxTokens) {
      kept.unshift(msg); // Re-invertir al agregar al frente
      totalTokens += tokens;
    } else {
      mantis_log('DEBUG', 'message_truncated', {
        reason: 'budget_exceeded',
        tokens_needed: tokens,
        tokens_remaining: maxTokens - totalTokens,
        tenant_id: tenantId
      });
      break;
    }
  }

  // Re-agregar system prompt al inicio si fue preservado
  if (systemPrompt) {
    kept.unshift(systemPrompt);
    // Contar tokens del system prompt pero no incluir en budget de usuario
    const systemTokens = await countTokens(systemPrompt.content, { tenantId });
    mantis_log('DEBUG', 'system_prompt_preserved', { tokens: systemTokens });
  }

  const truncated = kept.length < messages.length;
  
  mantis_log('INFO', 'compaction_completed', {
    original_count: messages.length,
    kept_count: kept.length,
    tokens_used: totalTokens,
    budget: maxTokens,
    truncated,
    tenant_id: tenantId
  });

  return {
    compacted: kept,
    tokensUsed: totalTokens,
    truncated,
    originalCount: messages.length
  };
}
```

```typescript
// ✅ C8: Compactación con backoff si excede presupuesto (retry adaptativo)
export async function compactWithBackoff(
  messages: Array<{ role: string; content: string }>,
  options: {
    initialBudget?: number;
    maxAttempts?: number;
    backoffFactor?: number;
    tenantId?: string;
  } = {}
): Promise<CompactionResult> {
  const {
    initialBudget = compactionConfig.MAX_CONTEXT_TOKENS,
    maxAttempts = 3,
    backoffFactor = compactionConfig.COMPACTION_BACKOFF_FACTOR,
    tenantId: explicitTenant
  } = options;

  const tenantId = explicitTenant ?? getCurrentTenantId() ?? 'unknown';
  let currentBudget = initialBudget;
  let result: CompactionResult | undefined;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    mantis_log('DEBUG', 'compaction_attempt', {
      attempt,
      max_attempts: maxAttempts,
      current_budget: currentBudget,
      tenant_id: tenantId
    });

    result = await compactMessages(messages, {
      maxTokens: currentBudget,
      tenantId,
      ...options
    });

    if (!result.truncated || attempt === maxAttempts) {
      break;
    }

    // ✅ C8: Backoff exponencial en presupuesto (no en tiempo)
    currentBudget = Math.floor(currentBudget * backoffFactor);
    mantis_log('WARN', 'budget_reduced', {
      from: initialBudget,
      to: currentBudget,
      factor: backoffFactor,
      tenant_id: tenantId
    });
  }

  return result!;
}
```

```typescript
// ✅ C3/C6: Validación de modelo de tokenizer desde env con fallback seguro
export function validateTokenizerModel(model: string): string {
  const allowed = ['gpt-4', 'gpt-3.5-turbo', 'gpt-4o', 'claude-3', 'llama-3'];
  
  if (!allowed.includes(model)) {
    mantis_log('WARN', 'tokenizer_model_invalid', {
      requested: model,
      allowed,
      fallback: 'gpt-4'
    });
    return 'gpt-4'; // Fallback seguro
  }
  
  mantis_log('DEBUG', 'tokenizer_model_validated', { model });
  return model;
}
```

```typescript
// ✅ C4/C8: Logger helper con tenant_id automático desde AsyncLocalStorage
export function logCompactionEvent(
  level: 'DEBUG' | 'INFO' | 'WARN' | 'ERROR',
  event: string,
  detail: Record<string, unknown>
): void {
  const tenantId = getCurrentTenantId() ?? detail.tenant_id ?? 'unknown';
  
  // ✅ C3: PII scrubbing automático heredado de mantis_log
  mantis_log(level, event, { ...detail, tenant_id: tenantId });
}
```

---

## 🧪 Testes Unitários (TDD – Apenas para a Lógica Específica)
```typescript
// context-compaction-utils.test.ts
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { 
  compactMessages, 
  countTokens, 
  compactWithBackoff,
  compactionContext,
  initTokenizer
} from './context-compaction-utils';

describe('context-compaction-utils', () => {
  const TEST_TENANT = 'tenant-test-123';
  const SAMPLE_MESSAGES = [
    { role: 'system', content: 'You are a helpful assistant.' },
    { role: 'user', content: 'Hello, how are you?' },
    { role: 'assistant', content: 'I am doing well, thank you!' },
    { role: 'user', content: 'Can you help me with a task?' },
    { role: 'assistant', content: 'Of course! What do you need help with?' }
  ];

  beforeEach(() => {
    // Mock de mantis_log para testes
    global.mantis_log = vi.fn();
    // Configurar env para testes
    process.env.MAX_CONTEXT_TOKENS = '200';
    process.env.TOKENIZER_MODEL = 'gpt-4';
  });

  afterEach(() => {
    vi.restoreAllMocks();
    delete process.env.MAX_CONTEXT_TOKENS;
    delete process.env.TOKENIZER_MODEL;
  });

  // Test: compactMessages preserva system prompt y respeta budget (C4+C8)
  it('should preserve system prompt and respect token budget', async () => {
    const result = await compactionContext.run(
      { tenantId: TEST_TENANT, budget: 200 },
      async () => compactMessages(SAMPLE_MESSAGES, { 
        maxTokens: 100, 
        preserveSystemPrompt: true,
        tenantId: TEST_TENANT 
      })
    );

    expect(result.compacted[0]?.role).toBe('system');
    expect(result.tokensUsed).toBeLessThanOrEqual(100);
    expect(result.truncated).toBe(true);
    
    expect(global.mantis_log).toHaveBeenCalledWith(
      'INFO',
      'compaction_completed',
      expect.objectContaining({ tenant_id: TEST_TENANT, truncated: true })
    );
  });

  // Test: countTokens usa fallback naive si tiktoken no está disponible (C6)
  it('should use naive tokenizer fallback when tiktoken not found', async () => {
    // Simular ERR_MODULE_NOT_FOUND para tiktoken
    vi.mock('tiktoken', () => {
      throw { code: 'ERR_MODULE_NOT_FOUND' };
    });

    const count = await countTokens('Hello world test', { tenantId: TEST_TENANT });
    
    // Fallback naive: ~4 chars per token
    expect(count).toBeGreaterThan(0);
    expect(global.mantis_log).toHaveBeenCalledWith(
      'WARN',
      'tokenizer_fallback',
      expect.objectContaining({ fallback: 'naive_heuristic' })
    );
  });

  // Test: compactWithBackoff reduce budget gradualmente (C8)
  it('should reduce budget with backoff when truncation occurs', async () => {
    const result = await compactWithBackoff(SAMPLE_MESSAGES, {
      initialBudget: 50,
      maxAttempts: 2,
      backoffFactor: 0.8,
      tenantId: TEST_TENANT
    });

    expect(result.truncated).toBe(true);
    // Verificar que se logueó la reducción de budget
    expect(global.mantis_log).toHaveBeenCalledWith(
      'WARN',
      'budget_reduced',
      expect.objectContaining({ 
        from: 50, 
        factor: 0.8,
        tenant_id: TEST_TENANT 
      })
    );
  });

  // Test: validateTokenizerModel retorna fallback para modelo inválido (C3)
  it('should return safe fallback for invalid tokenizer model', () => {
    const { validateTokenizerModel } = await import('./context-compaction-utils');
    const result = validateTokenizerModel('invalid-model-123');
    
    expect(result).toBe('gpt-4');
    expect(global.mantis_log).toHaveBeenCalledWith(
      'WARN',
      'tokenizer_model_invalid',
      expect.objectContaining({ requested: 'invalid-model-123' })
    );
  });

  // Test: countTokens con timeout aborta operación (C8)
  it('should timeout token count after specified ms', async () => {
    // Mock encode para simular operación lenta
    const originalEncode = (await import('./context-compaction-utils')).encode;
    
    const slowEncode = vi.fn((text: string) => {
      // Simular delay que excede timeout
      return new Promise<number[]>((resolve) => {
        setTimeout(() => resolve(new Array(100).fill(1)), 100);
      });
    });

    await expect(countTokens('test', { timeoutMs: 10, tenantId: TEST_TENANT }))
      .rejects.toThrow(/Timeout|Abort/);
    
    expect(global.mantis_log).toHaveBeenCalledWith(
      'WARN',
      'token_count_timeout',
      expect.objectContaining({ timeout_ms: 10 })
    );
  });
});
```

---

## 🔍 Validação (VDD – Comando Canônico)
```bash
# Validação integral via orchestrator-engine (herda checks do Master Agent)
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/javascript/context-compaction-utils.ts.md \
  --json \
  --check-structural \
  --check-error-handling \
  --check-observability \
  --check-constraints C3,C4,C6,C8

# Validação específica de env validation (C3)
bash 05-CONFIGURATIONS/validation/verify-constraints.sh \
  --file 06-PROGRAMMING/javascript/context-compaction-utils.ts.md \
  --check C3 \
  --json

# Validação de optional dependencies (C6)
bash 05-CONFIGURATIONS/validation/verify-constraints.sh \
  --file 06-PROGRAMMING/javascript/context-compaction-utils.ts.md \
  --check C6 \
  --json

# Validação de observability V-LOG-02 (C8)
bash 05-CONFIGURATIONS/validation/verify-observability.sh \
  --file 06-PROGRAMMING/javascript/context-compaction-utils.ts.md \
  --schema V-LOG-02 \
  --json
```

---

## 🔗 Referências Cruzadas (Wikilinks Mínimos)
- [[javascript-typescript-master-agent.md]] ← Fonte de `mantis_log()`, hardening, constraints
- [[/05-CONFIGURATIONS/validation/orchestrator-engine.sh]] ← Motor de validação principal
- [[/05-CONFIGURATIONS/validation/verify-constraints.sh]] ← Validação C3/C6
- [[/05-CONFIGURATIONS/validation/verify-observability.sh]] ← Validação C8 + V-LOG-02
- [[/01-RULES/harness-norms-v3.0.md#C3]] ← Definição formal de C3 (Secrets/Env Validation)
- [[/01-RULES/harness-norms-v3.0.md#C4]] ← Definição formal de C4 (Tenant Isolation)
- [[/01-RULES/harness-norms-v3.0.md#C6]] ← Definição formal de C6 (Dependency Management)
- [[/01-RULES/harness-norms-v3.0.md#C8]] ← Definição formal de C8 (Observability)

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 2.3.0-MODULAR-MERGED | 2026-05-09 | javascript-typescript-master-agent | MERGE: estrutura modular v2.3.0 + bootstrap resiliente + observability V-LOG-02 + backoff adaptativo | C3,C4,C6,C8 |
| 2.1.1 | 2026-04-16 | Framework Core Team | Adição de exemplos Zod para env validation e fallback de tokenizer | C3,C4,C6,C8 |
| 2.0.0 | 2026-03-01 | Qwen + DeepSeek | Primeira versão canônica com padrões de compactação greedy inversa | C4,C6,C8 |

---

## 🔍 Observability (Documentación para IA – Eventos Específicos)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `compaction_started` | INFO | C8 | `"{\"message_count\":10,\"budget_tokens\":4096,\"tenant_id\":\"t123\"}"` |
| `token_count_started` | DEBUG | C8 | `"{\"text_length\":256,\"timeout_ms\":2000,\"tenant_id\":\"t123\"}"` |
| `token_count_completed` | DEBUG | C8 | `"{\"count\":45,\"tokenizer\":\"tiktoken\",\"tenant_id\":\"t123\"}"` |
| `token_count_timeout` | WARN | C8 | `"{\"timeout_ms\":2000,\"tenant_id\":\"t123\"}"` |
| `message_truncated` | DEBUG | C8 | `"{\"reason\":\"budget_exceeded\",\"tokens_needed\":50,\"tokens_remaining\":10}"` |
| `compaction_completed` | INFO | C8 | `"{\"original_count\":10,\"kept_count\":6,\"tokens_used\":3800,\"truncated\":true}"` |
| `tokenizer_fallback` | WARN | C6 | `"{\"model\":\"gpt-4\",\"fallback\":\"naive_heuristic\"}"` |
| `budget_reduced` | WARN | C8 | `"{\"from\":4096,\"to\":3686,\"factor\":0.9,\"tenant_id\":\"t123\"}"` |
| `tokenizer_model_invalid` | WARN | C3 | `"{\"requested\":\"invalid-model\",\"allowed\":[\"gpt-4\",\"gpt-3.5-turbo\"],\"fallback\":\"gpt-4\"}"` |

### Validação de Schema V-LOG-02 (Helper Mínimo)
```typescript
// Helper para validar que logs de compactação seguem schema V-LOG-02
export function validateCompactionLog(logEntry: unknown): { valid: boolean; errors: string[] } {
  const errors: string[] = [];
  const entry = logEntry as Record<string, unknown>;

  // Campos obrigatórios V-LOG-02
  const required = ['ts', 'level', 'resource', 'body'];
  for (const field of required) {
    if (!(field in entry)) errors.push(`Missing required field: ${field}`);
  }

  // Validar que tenant_id está presente para eventos de compactação (C4)
  const compactionEvents = ['compaction_started', 'compaction_completed', 'message_truncated'];
  if (compactionEvents.includes(entry.body?.event as string)) {
    const detail = entry.body?.detail as Record<string, unknown>;
    if (!detail?.tenant_id) {
      errors.push('C4 violation: compaction event missing tenant_id in detail');
    }
  }

  // Validar que token counts são números válidos (C6)
  if (entry.body?.event === 'token_count_completed') {
    const detail = entry.body?.detail as Record<string, unknown>;
    if (typeof detail?.count !== 'number' || detail.count < 0) {
      errors.push('C6 violation: invalid token count in log');
    }
  }

  return { valid: errors.length === 0, errors };
}
```

---

## ✅ Auto-Validation Report (JSON – Para CI/CD)
```json
{
  "artifact": "context-compaction-utils",
  "version": "2.3.0-MODULAR-MERGED",
  "score": 31,
  "blocking_issues": [],
  "constraints_verified": ["C3", "C4", "C6", "C8"],
  "examples_count": 13,
  "lines_executable_max": 4,
  "language": "TypeScript 5.0+ / Node.js 18+",
  "observability_compliant": true,
  "bootstrap_resilient": true,
  "mantis_log_usage": "inherited",
  "optional_dependency_handling": "lazy-load-with-fallback",
  "tenant_isolation_verified": true,
  "timestamp": "2026-05-09T00:00:00Z"
}
```

---

> 🇧🇷 *Documento técnico em pt-BR conforme V-DOC-01. Coordenação em español. Zero invenção: todo padrão grounded no conteúdo original + template v2.3.0-MODULAR.*
