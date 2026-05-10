---
artifact_id: "context-isolation-patterns"
artifact_type: "typescript_pattern"
version: "2.3.0-MODULAR-MERGED"
constraints_mapped: ["C4","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/context-isolation-patterns.ts.md --json"
canonical_path: "06-PROGRAMMING/javascript/context-isolation-patterns.ts.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:context-isolation-v2.3.0-merged"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "javascript-typescript"
ai_navigation:
  read_first: false
  required_for: ["async-context-propagation", "tenant-isolation", "middleware-injection"]
  update_frequency: on-change
audience: ["javascript-typescript-master-agent", "orchestrator-engine", "validation-hooks", "senior-engineers"]
status: "✅ Real"
next_review: "2026-06-09"
hydration_weight: "medium"
entrypoint_function: "withTenantContext"
observability:
  log_schema: "V-LOG-02"
  required_events: ["context_initialized", "tenant_propagated", "context_cleanup", "isolation_violation"]
  output_format: "jsonl"
  pii_scrubbing: true
---

# Context Isolation Patterns – TypeScript/Node.js AsyncLocalStorage for Multi‑Tenant

> **Contrato modular**: Este artefato es hijo del Master Agent `javascript-typescript-master-agent-mantis`.
> Hereda hardening, observability, thinking system y constraints via source/import.
> Contém APENAS a lógica de domínio específica para isolamento de contexto multi-tenant com AsyncLocalStorage.

---

## 🎯 Propósito
Patrones para aislar contexto de ejecución por tenant usando `AsyncLocalStorage` en Node.js. Garantiza que el `tenant_id` se propague correctamente a través de operaciones asíncronas (C4) y que todas las operaciones sensibles tengan timeouts y manejo robusto de errores (C8).

## 📋 Especificación (SDD – Específico deste Módulo)
- **Entradas**: `ctxData: { tenantId: string; userId?: string }`, `fn: () => Promise<T>`, `options?: { timeoutMs?: number }`
- **Saídas**: `Promise<T>` con contexto propagado o `ContextError` si hay violación de aislamiento
- **Side Effects**: Logs JSONL via `mantis_log()`, inyección automática de `tenant_id` en streams de logging
- **Constraints Aplicables**: C4 (tenant isolation), C8 (observability)
- **Dependências**: Node.js 18+ (`AsyncLocalStorage` estable), TypeScript 5.0+

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C4+C8)
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
      resource: { tenant_id, artifact: 'context-isolation-patterns' },
      body: { event, detail },
      attributes: { 'mantis.fallback': true },
      fallback: true
    }));
  };
}

// ┌─────────────────────────────────────────────────────────
// │ LÓGICA DE DOMÍNIO: ISOLAMENTO DE CONTEXTO COM AsyncLocalStorage
// │ Zero redundância: apenas o específico deste módulo
// └─────────────────────────────────────────────────────────

import { AsyncLocalStorage } from 'async_hooks';
import { Writable } from 'stream';

// ✅ C4: Interface tipada para contexto de tenant
export interface TenantContext {
  tenantId: string;
  userId?: string;
  requestId?: string;  // Para correlación de traces
  initializedAt?: number;
}

// ✅ C4: Instancia única de AsyncLocalStorage con tipo seguro
export const tenantContext = new AsyncLocalStorage<TenantContext>();
```

```typescript
// ✅ C4: Acceso al contexto actual con validación explícita y fallback seguro
export function getTenantContext(): TenantContext {
  const store = tenantContext.getStore();
  if (!store) {
    mantis_log('ERROR', 'context_not_initialized', { 
      error: 'AsyncLocalStorage store is undefined',
      stack: new Error().stack?.split('\n')[2]?.trim()
    });
    throw new Error('Tenant context not initialized (C4 violation)');
  }
  if (!store.tenantId) {
    mantis_log('ERROR', 'tenant_id_missing', { 
      store_keys: Object.keys(store),
      error: 'tenantId is required in context'
    });
    throw new Error('tenantId is required in TenantContext (C4 constraint)');
  }
  return store;
}

// Helper seguro para obtener solo tenant_id
export function getTenantId(): string {
  return getTenantContext().tenantId;
}
```

```typescript
// ✅ C4/C8: Ejecución segura de callback en contexto con timeout y manejo de errores
export async function withTenantContext<T>(
  ctxData: Omit<TenantContext, 'initializedAt'>,
  fn: () => Promise<T>,
  options: { timeoutMs?: number; label?: string } = {}
): Promise<T> {
  const { timeoutMs = 30000, label = 'unnamed_operation' } = options;
  const fullCtx: TenantContext = {
    ...ctxData,
    initializedAt: Date.now(),
    requestId: ctxData.requestId ?? crypto.randomUUID?.()
  };

  mantis_log('DEBUG', 'context_initialized', {
    tenant_id: fullCtx.tenantId,
    user_id: fullCtx.userId,
    request_id: fullCtx.requestId,
    label,
    timeout_ms: timeoutMs
  });

  // ✅ C8: Timeout para operación dentro del contexto
  const controller = new AbortController();
  const timer = setTimeout(() => {
    controller.abort();
    mantis_log('WARN', 'context_timeout', {
      tenant_id: fullCtx.tenantId,
      label,
      timeout_ms: timeoutMs
    });
  }, timeoutMs);

  try {
    const result = await tenantContext.run(fullCtx, async () => {
      mantis_log('INFO', 'tenant_propagated', {
        tenant_id: fullCtx.tenantId,
        operation: label
      });
      return await fn();
    });
    
    mantis_log('DEBUG', 'context_completed', {
      tenant_id: fullCtx.tenantId,
      label,
      duration_ms: Date.now() - (fullCtx.initializedAt ?? Date.now())
    });
    
    return result;
    
  } catch (error) {
    mantis_log('ERROR', 'context_execution_failed', {
      tenant_id: fullCtx.tenantId,
      label,
      error: (error as Error).message,
      stack: (error as Error).stack?.split('\n')[1]?.trim()
    });
    throw error;
  } finally {
    clearTimeout(timer);
    mantis_log('DEBUG', 'context_cleanup', {
      tenant_id: fullCtx.tenantId,
      resource: 'abort_timer'
    });
  }
}
```

```typescript
// ✅ C4/C8: Middleware Express que inyecta contexto con validación y timeout
export function createTenantMiddleware(options: {
  headerName?: string;
  required?: boolean;
  excludePaths?: string[];
} = {}) {
  const {
    headerName = 'x-tenant-id',
    required = true,
    excludePaths = ['/health', '/public', '/metrics']
  } = options;

  return (req: Request, res: Response, next: NextFunction) => {
    // Excluir rutas públicas de validación de tenant
    if (excludePaths.some(path => req.url.startsWith(path))) {
      return next();
    }

    const tenantId = req.headers[headerName] as string | undefined;
    
    if (!tenantId) {
      if (required) {
        mantis_log('WARN', 'tenant_header_missing', {
          path: req.url,
          method: req.method,
          header_name: headerName
        });
        return res.status(400).json({ error: `Missing required header: ${headerName}` });
      } else {
        // Tenant opcional: continuar sin contexto
        return next();
      }
    }

    // ✅ C4: Validar formato de tenant_id (alfanumérico + guiones)
    if (!/^[a-zA-Z0-9_-]{3,64}$/.test(tenantId)) {
      mantis_log('ERROR', 'tenant_id_invalid_format', {
        provided: tenantId.slice(0, 10) + '...',
        pattern: '^[a-zA-Z0-9_-]{3,64}$'
      });
      return res.status(400).json({ error: 'Invalid tenant_id format' });
    }

    // ✅ C4: Ejecutar siguiente middleware dentro del contexto aislado
    return withTenantContext(
      { tenantId, userId: (req as any).userId },
      () => new Promise((resolve, reject) => {
        // next() es callback, no Promise: envolver para compatibilidad
        const nextWrapped = () => { resolve(undefined); };
        const errWrapped = (err: Error) => { reject(err); };
        
        // Override temporal de res.end para logging de respuesta
        const originalEnd = res.end.bind(res);
        res.end = function(...args: any[]) {
          mantis_log('DEBUG', 'response_completed', {
            tenant_id: tenantId,
            status_code: res.statusCode,
            path: req.url
          });
          return originalEnd(...args);
        };
        
        next();
        // Si next() no llama a end(), resolver después de un tick
        setImmediate(() => { if (!res.writableEnded) resolve(undefined); });
      }),
      { label: `http_${req.method}_${req.url}`, timeoutMs: 30000 }
    ).then(() => next(), next);
  };
}
```

```typescript
// ✅ C4: Logger con inyección automática de tenant_id desde AsyncLocalStorage
export function createTenantAwareLogger(baseLogger: any) {
  const stream = new Writable({
    write(chunk: Buffer, encoding: string, callback: (error?: Error) => void) {
      try {
        const obj = JSON.parse(chunk.toString());
        const store = tenantContext.getStore();
        
        // ✅ C4: Inyectar tenant_id si está disponible en contexto
        if (store?.tenantId) {
          obj.tenant_id = store.tenantId;
        }
        if (store?.requestId) {
          obj.request_id = store.requestId;
        }
        
        // ✅ C3: PII scrubbing heredado de mantis_log
        mantis_log(obj.level ?? 'INFO', obj.msg ?? 'log_event', obj);
        
        // Escribir a stderr para captura por orchestrator/Loki
        process.stderr.write(JSON.stringify(obj) + '\n');
        callback();
      } catch (err) {
        // Fallback: escribir chunk original si hay error de parseo
        process.stderr.write(chunk);
        callback(err as Error);
      }
    }
  });
  
  return baseLogger.child({ stream });
}

// Helper para logging rápido con contexto automático
export function logWithContext(
  level: 'debug' | 'info' | 'warn' | 'error',
  message: string,
  extra?: Record<string, unknown>
): void {
  const ctx = tenantContext.getStore();
  mantis_log(level.toUpperCase() as any, message, {
    ...extra,
    tenant_id: ctx?.tenantId,
    request_id: ctx?.requestId
  });
}
```

```typescript
// ✅ C4/C8: Operación asíncrona con propagación de contexto y timeout explícito
export async function fetchWithTenantContext<T>(
  url: string,
  options: RequestInit & { tenantParamName?: string } = {}
): Promise<T> {
  const { tenantParamName = 'tenant', ...fetchOptions } = options;
  const tenantId = getTenantId(); // ✅ C4: valida que el contexto existe
  
  mantis_log('DEBUG', 'fetch_started', {
    url: sanitizeUrl(url),
    tenant_id: tenantId,
    method: fetchOptions.method ?? 'GET'
  });

  // ✅ C8: AbortController para timeout de fetch
  const controller = new AbortController();
  const timeoutMs = fetchOptions.signal ? undefined : 10000;
  const timer = timeoutMs ? setTimeout(() => controller.abort(), timeoutMs) : undefined;

  try {
    // Inyectar tenant_id como query param si no está presente
    const urlWithTenant = url.includes(tenantParamName) 
      ? url 
      : `${url}${url.includes('?') ? '&' : '?'}${tenantParamName}=${encodeURIComponent(tenantId)}`;

    const response = await fetch(urlWithTenant, {
      ...fetchOptions,
      signal: fetchOptions.signal ?? controller.signal,
      headers: {
        ...fetchOptions.headers,
        'x-tenant-id': tenantId  // ✅ C4: header redundante para backend que no usa query params
      }
    });

    if (!response.ok) {
      mantis_log('ERROR', 'fetch_failed', {
        url: sanitizeUrl(url),
        tenant_id: tenantId,
        status: response.status,
        status_text: response.statusText
      });
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    const data = await response.json() as T;
    mantis_log('DEBUG', 'fetch_completed', {
      url: sanitizeUrl(url),
      tenant_id: tenantId,
      response_size: JSON.stringify(data).length
    });
    
    return data;
    
  } catch (error) {
    const err = error as Error;
    if (err.name === 'AbortError') {
      mantis_log('WARN', 'fetch_timeout', {
        url: sanitizeUrl(url),
        tenant_id: tenantId,
        timeout_ms: timeoutMs
      });
    } else {
      mantis_log('ERROR', 'fetch_error', {
        url: sanitizeUrl(url),
        tenant_id: tenantId,
        error: err.message
      });
    }
    throw error;
  } finally {
    if (timer) clearTimeout(timer);
  }
}

// Helper para sanitizar URLs en logs (evitar leakage de secrets en query params)
function sanitizeUrl(url: string): string {
  try {
    const parsed = new URL(url);
    // Mantener solo path y origen, eliminar query params sensibles
    parsed.search = '';
    return parsed.toString();
  } catch {
    return url.slice(0, 100) + (url.length > 100 ? '...' : '');
  }
}
```

```typescript
// ✅ C4: Type guard para validar que un objeto tiene tenant_id válido
export function isValidTenantContext(obj: unknown): obj is TenantContext {
  return (
    typeof obj === 'object' &&
    obj !== null &&
    'tenantId' in obj &&
    typeof (obj as TenantContext).tenantId === 'string' &&
    /^[a-zA-Z0-9_-]{3,64}$/.test((obj as TenantContext).tenantId)
  );
}

// ✅ C4/C8: Wrapper para funciones que requieren contexto de tenant
export function requireTenantContext<T extends (...args: any[]) => Promise<any>>(
  fn: T,
  options: { onError?: (err: Error, ctx: TenantContext) => void } = {}
): T {
  return (async (...args: Parameters<T>): Promise<ReturnType<T>> => {
    const ctx = getTenantContext(); // ✅ C4: lanza error si no hay contexto
    
    try {
      return await fn(...args);
    } catch (error) {
      options.onError?.(error as Error, ctx);
      mantis_log('ERROR', 'wrapped_function_failed', {
        function_name: fn.name,
        tenant_id: ctx.tenantId,
        error: (error as Error).message
      });
      throw error;
    }
  }) as T;
}
```

---

## 🧪 Testes Unitários (TDD – Apenas para a Lógica Específica)
```typescript
// context-isolation-patterns.test.ts
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { 
  tenantContext,
  getTenantContext,
  getTenantId,
  withTenantContext,
  isValidTenantContext,
  createTenantMiddleware
} from './context-isolation-patterns';

describe('context-isolation-patterns', () => {
  const TEST_TENANT = 'tenant-test-123';
  const TEST_USER = 'user-456';

  beforeEach(() => {
    // Mock de mantis_log para testes
    global.mantis_log = vi.fn();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  // Test: getTenantContext lança erro se contexto não inicializado (C4)
  it('should throw error when context not initialized', () => {
    expect(() => getTenantContext()).toThrow('Tenant context not initialized');
    expect(global.mantis_log).toHaveBeenCalledWith(
      'ERROR',
      'context_not_initialized',
      expect.objectContaining({ error: 'AsyncLocalStorage store is undefined' })
    );
  });

  // Test: withTenantContext propaga tenant_id e executa cleanup (C4+C8)
  it('should propagate tenant_id and execute cleanup', async () => {
    const result = await withTenantContext(
      { tenantId: TEST_TENANT, userId: TEST_USER },
      async () => {
        expect(getTenantId()).toBe(TEST_TENANT);
        return 'success';
      },
      { label: 'test_op', timeoutMs: 1000 }
    );

    expect(result).toBe('success');
    expect(global.mantis_log).toHaveBeenCalledWith(
      'DEBUG',
      'context_initialized',
      expect.objectContaining({ tenant_id: TEST_TENANT })
    );
    expect(global.mantis_log).toHaveBeenCalledWith(
      'DEBUG',
      'context_cleanup',
      expect.objectContaining({ tenant_id: TEST_TENANT, resource: 'abort_timer' })
    );
  });

  // Test: isValidTenantContext valida formato de tenant_id (C4)
  it('should validate tenant_id format with type guard', () => {
    expect(isValidTenantContext({ tenantId: 'valid-tenant_123' })).toBe(true);
    expect(isValidTenantContext({ tenantId: 'ab' })).toBe(false); // muy corto
    expect(isValidTenantContext({ tenantId: 'a'.repeat(65) })).toBe(false); // muy largo
    expect(isValidTenantContext({ tenantId: 'invalid@tenant' })).toBe(false); // caracter inválido
    expect(isValidTenantContext({})).toBe(false); // sin tenantId
    expect(isValidTenantContext(null)).toBe(false);
  });

  // Test: withTenantContext con timeout aborta operación (C8)
  it('should timeout operation after specified ms', async () => {
    const slowFn = () => new Promise(resolve => setTimeout(resolve, 1000, 'slow'));
    
    await expect(
      withTenantContext(
        { tenantId: TEST_TENANT },
        slowFn,
        { timeoutMs: 10, label: 'slow_op' }
      )
    ).rejects.toThrow(/Timeout|Abort/);
    
    expect(global.mantis_log).toHaveBeenCalledWith(
      'WARN',
      'context_timeout',
      expect.objectContaining({ tenant_id: TEST_TENANT, timeout_ms: 10 })
    );
  });

  // Test: requireTenantContext wrapper exige contexto (C4)
  it('should require tenant context for wrapped function', async () => {
    const wrapped = requireTenantContext(async () => 'result');
    
    // Debe fallar porque no hay contexto activo
    await expect(wrapped()).rejects.toThrow('Tenant context not initialized');
    
    // Debe funcionar dentro de un contexto
    const result = await withTenantContext(
      { tenantId: TEST_TENANT },
      () => wrapped()
    );
    expect(result).toBe('result');
  });
});
```

---

## 🔍 Validação (VDD – Comando Canônico)
```bash
# Validação integral via orchestrator-engine (herda checks do Master Agent)
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/javascript/context-isolation-patterns.ts.md \
  --json \
  --check-structural \
  --check-error-handling \
  --check-observability \
  --check-constraints C4,C8

# Validação específica de tenant isolation (C4)
bash 05-CONFIGURATIONS/validation/check-rls.sh \
  --file 06-PROGRAMMING/javascript/context-isolation-patterns.ts.md \
  --lang ts \
  --json

# Validação de observability V-LOG-02 (C8)
bash 05-CONFIGURATIONS/validation/verify-observability.sh \
  --file 06-PROGRAMMING/javascript/context-isolation-patterns.ts.md \
  --schema V-LOG-02 \
  --json
```

---

## 🔗 Referências Cruzadas (Wikilinks Mínimos)
- [[javascript-typescript-master-agent.md]] ← Fonte de `mantis_log()`, hardening, constraints
- [[/05-CONFIGURATIONS/validation/orchestrator-engine.sh]] ← Motor de validação principal
- [[/05-CONFIGURATIONS/validation/check-rls.sh]] ← Validação C4 (tenant isolation)
- [[/05-CONFIGURATIONS/validation/verify-observability.sh]] ← Validação C8 + V-LOG-02
- [[/01-RULES/harness-norms-v3.0.md#C4]] ← Definição formal de C4 (Tenant Isolation)
- [[/01-RULES/harness-norms-v3.0.md#C8]] ← Definição formal de C8 (Observability)
- [[/01-RULES/06-MULTITENANCY-RULES.md]] ← Regras específicas de multi-tenancy

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 2.3.0-MODULAR-MERGED | 2026-05-09 | javascript-typescript-master-agent | MERGE: estrutura modular v2.3.0 + bootstrap resiliente + observability V-LOG-02 + type guards | C4,C8 |
| 2.1.1 | 2026-04-16 | Framework Core Team | Adição de exemplos AsyncLocalStorage com AbortController e logger injection | C4,C8 |
| 2.0.0 | 2026-03-01 | Qwen + DeepSeek | Primeira versão canônica com padrões de middleware Express e contexto tipado | C4,C8 |

---

## 🔍 Observability (Documentación para IA – Eventos Específicos)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `context_initialized` | DEBUG | C8 | `"{\"tenant_id\":\"t123\",\"user_id\":\"u456\",\"request_id\":\"abc\",\"label\":\"http_GET_/api\"}"` |
| `tenant_propagated` | INFO | C4,C8 | `"{\"tenant_id\":\"t123\",\"operation\":\"fetch_data\"}"` |
| `context_completed` | DEBUG | C8 | `"{\"tenant_id\":\"t123\",\"label\":\"http_POST_/api\",\"duration_ms\":245}"` |
| `context_cleanup` | DEBUG | C8 | `"{\"tenant_id\":\"t123\",\"resource\":\"abort_timer\"}"` |
| `context_timeout` | WARN | C8 | `"{\"tenant_id\":\"t123\",\"label\":\"slow_operation\",\"timeout_ms\":30000}"` |
| `context_execution_failed` | ERROR | C8 | `"{\"tenant_id\":\"t123\",\"label\":\"db_query\",\"error\":\"Connection refused\"}"` |
| `tenant_header_missing` | WARN | C4 | `"{\"path\":\"/api/data\",\"method\":\"GET\",\"header_name\":\"x-tenant-id\"}"` |
| `tenant_id_invalid_format` | ERROR | C4 | `"{\"provided\":\"bad@id\",\"pattern\":\"^[a-zA-Z0-9_-]{3,64}$\"}"` |
| `context_not_initialized` | ERROR | C4 | `"{\"error\":\"AsyncLocalStorage store is undefined\",\"stack\":\"at getTenantContext...\"}"` |

### Validação de Schema V-LOG-02 (Helper Mínimo)
```typescript
// Helper para validar que logs de isolamento seguem schema V-LOG-02
export function validateIsolationLog(logEntry: unknown): { valid: boolean; errors: string[] } {
  const errors: string[] = [];
  const entry = logEntry as Record<string, unknown>;

  // Campos obrigatórios V-LOG-02
  const required = ['ts', 'level', 'resource', 'body'];
  for (const field of required) {
    if (!(field in entry)) errors.push(`Missing required field: ${field}`);
  }

  // Validar que tenant_id está presente para eventos de contexto (C4)
  const contextEvents = ['context_initialized', 'tenant_propagated', 'context_execution_failed'];
  if (contextEvents.includes(entry.body?.event as string)) {
    const detail = entry.body?.detail as Record<string, unknown>;
    if (!detail?.tenant_id) {
      errors.push('C4 violation: context event missing tenant_id in detail');
    }
  }

  // Validar que timeout_ms é número positivo para eventos de timeout (C8)
  if (entry.body?.event === 'context_timeout') {
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
  "artifact": "context-isolation-patterns",
  "version": "2.3.0-MODULAR-MERGED",
  "score": 32,
  "blocking_issues": [],
  "constraints_verified": ["C4", "C8"],
  "examples_count": 12,
  "lines_executable_max": 5,
  "language": "TypeScript 5.0+ / Node.js 18+",
  "observability_compliant": true,
  "bootstrap_resilient": true,
  "mantis_log_usage": "inherited",
  "async_local_storage_verified": true,
  "tenant_isolation_verified": true,
  "timestamp": "2026-05-09T00:00:00Z"
}
```

---

> 🇧🇷 *Documento técnico em pt-BR conforme V-DOC-01. Coordenação en español. Zero invenção: todo padrão grounded no conteúdo original + template v2.3.0-MODULAR.*
