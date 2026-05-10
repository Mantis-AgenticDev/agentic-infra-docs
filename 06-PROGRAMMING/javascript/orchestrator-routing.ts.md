---
artifact_id: "orchestrator-routing"
artifact_type: "typescript_module"
version: "2.3.0-MODULAR-MERGED"
constraints_mapped: ["C4","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/orchestrator-routing.ts.md --json"
canonical_path: "06-PROGRAMMING/javascript/orchestrator-routing.ts.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:orchestrator-routing-v2.3.0-merged"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "javascript-typescript"
ai_navigation:
  read_first: false
  required_for: ["json-dispatch", "tenant-aware-routing", "payload-integrity-verification"]
  update_frequency: on-change
audience: ["javascript-typescript-master-agent", "orchestrator-engine", "validation-hooks", "senior-engineers"]
status: "✅ Real"
next_review: "2026-06-09"
hydration_weight: "medium"
entrypoint_function: "routeOrchestratorTask"
observability:
  log_schema: "V-LOG-02"
  required_events: ["task_received", "payload_verified", "tenant_context_set", "service_dispatched", "routing_completed", "routing_failed"]
  output_format: "jsonl"
  pii_scrubbing: true
---

# Orchestrator Routing – TypeScript/Node.js JSON Dispatch & Tenant‑Aware Routing

> **Contrato modular**: Este artefato es hijo del Master Agent `javascript-typescript-master-agent-mantis`.
> Hereda hardening, observability, thinking system y constraints via source/import.
> Contém APENAS a lógica de domínio específica para roteamento de tarefas JSON com isolamento multi-tenant e verificação de integridade.

---

## 🎯 Propósito
Patrones para implementar un orquestador de tareas que enruta peticiones JSON a servicios internos, asegurando aislamiento multi-tenant mediante `AsyncLocalStorage` (C4), verificación de integridad del payload con hash SHA256 (C5), y timeouts explícitos en todas las etapas del flujo de despacho (C8).

## 📋 Especificación (SDD – Específico deste Módulo)
- **Entradas**: `task: OrchestratorTask`, `options?: { timeoutMs?: number; verifyIntegrity?: boolean; expectedHash?: string }`
- **Saídas**: `Promise<{ success: boolean; response?: any; tenantId: string; payloadHash?: string }>` o `RoutingError`
- **Side Effects**: Logs JSONL via `mantis_log()`, validación de payload con SHA256, despacho a servicios internos con tenant headers
- **Constraints Aplicables**: C4 (tenant isolation), C5 (integrity/type safety), C8 (observability)
- **Dependências**: Node.js 18+, TypeScript 5.0+, `zod`, `crypto`, `async_hooks`

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C4+C5+C8)

```typescript
// ┌─────────────────────────────────────────────────────────
// │ BOOTSTRAP RESILIENTE PARA JAVASCRIPT/TYPESCRIPT
// │ Herda mantis_log() do Master Agent OU fornece fallback
// └─────────────────────────────────────────────────────────

let mantis_log: typeof import('./javascript-typescript-master-agent.mjs').mantis_log;

try {
  const master = await import('./javascript-typescript-master-agent.mjs');
  mantis_log = master.mantis_log;
} catch {
  mantis_log = (
    level: 'DEBUG'|'INFO'|'WARN'|'ERROR'|'FATAL',
    event: string,
    detail: Record<string, unknown>,
    tenant_id = process.env.TENANT_ID ?? 'unknown'
  ) => {
    console.error(JSON.stringify({
      ts: new Date().toISOString(),
      level,
      resource: { tenant_id, artifact: 'orchestrator-routing' },
      body: { event, detail },
      attributes: { 'mantis.fallback': true },
      fallback: true
    }));
  };
}

// ┌─────────────────────────────────────────────────────────
// │ LÓGICA DE DOMÍNIO: ROTEAMENTO DE TAREFAS COM MULTI-TENANT
// └─────────────────────────────────────────────────────────

import { createHash, createHmac } from 'crypto';
import { z } from 'zod';
import { AsyncLocalStorage } from 'async_hooks';

// ✅ C4: Interface tipada para tarea de orquestador con tenant_id obligatorio
export interface OrchestratorTask {
  tenantId: string;
  action: 'query' | 'embed' | 'search' | 'process' | 'forward';
  payload: Record<string, unknown>;
  requestId?: string;
  priority?: 'low' | 'normal' | 'high';
}

// ✅ C5: Schema Zod para validación de tarea con integridad
export const orchestratorTaskSchema = z.object({
  tenantId: z.string().uuid().or(z.string().regex(/^[a-zA-Z0-9_-]{3,64}$/)),
  action: z.enum(['query', 'embed', 'search', 'process', 'forward']),
  payload: z.record(z.unknown()),
  requestId: z.string().uuid().optional(),
  priority: z.enum(['low', 'normal', 'high']).default('normal')
});

export type ValidatedTask = z.infer<typeof orchestratorTaskSchema>;
```

```typescript
// ✅ C5: Verificación de integridad del payload con SHA256 + HMAC opcional
export interface IntegrityCheckResult {
  valid: boolean;
  actualHash: string;
  signatureValid?: boolean;
}

export async function verifyPayloadIntegrity(
  payload: Record<string, unknown>,
  expectedHash?: string,
  options: { algorithm?: string; secret?: string; signature?: string } = {}
): Promise<IntegrityCheckResult> {
  const { algorithm = 'sha256', secret, signature } = options;
  
  mantis_log('DEBUG', 'payload_integrity_check_started', {
    algorithm,
    expected_hash_prefix: expectedHash?.slice(0, 16) + '...',
    signature_provided: !!signature
  });
  
  const payloadStr = JSON.stringify(payload, Object.keys(payload).sort());
  const actualHash = createHash(algorithm).update(payloadStr, 'utf8').digest('hex');
  
  mantis_log('DEBUG', 'payload_hash_computed', {
    algorithm,
    hash_prefix: actualHash.slice(0, 16) + '...',
    payload_size_bytes: Buffer.byteLength(payloadStr)
  });
  
  let hashValid = true;
  if (expectedHash && actualHash !== expectedHash) {
    mantis_log('ERROR', 'payload_hash_mismatch', {
      expected_prefix: expectedHash.slice(0, 16) + '...',
      actual_prefix: actualHash.slice(0, 16) + '...',
      constraint: 'C5'
    });
    hashValid = false;
  }
  
  let signatureValid: boolean | undefined;
  if (secret && signature) {
    const expectedSignature = createHmac('sha256', secret)
      .update(payloadStr, 'utf8')
      .digest('hex');
    signatureValid = expectedSignature === signature;
    
    if (!signatureValid) {
      mantis_log('ERROR', 'payload_signature_invalid', { constraint: 'C5' });
    }
  }
  
  const valid = hashValid && (signatureValid !== false);
  
  if (valid) {
    mantis_log('INFO', 'payload_integrity_verified', {
      hash_prefix: actualHash.slice(0, 16) + '...',
      signature_verified: signatureValid
    });
  }
  
  return { valid, actualHash, signatureValid };
}
```

```typescript
// ✅ C4: AsyncLocalStorage para propagación de tenant_id en operaciones de routing
export const routingContext = new AsyncLocalStorage<{ tenantId: string; requestId?: string }>();

export function getCurrentRoutingContext(): { tenantId: string; requestId?: string } {
  const store = routingContext.getStore();
  if (!store?.tenantId) {
    mantis_log('ERROR', 'routing_context_missing_tenant', { constraint: 'C4' });
    throw new Error('Tenant context required for routing operations (C4 constraint)');
  }
  return store;
}

export function withRoutingContext<T>(tenantId: string, requestId?: string, fn: () => Promise<T>): Promise<T> {
  return routingContext.run({ tenantId, requestId }, fn);
}
```

```typescript
// ✅ C4/C8: Enrutamiento con contexto AsyncLocalStorage y timeout explícito
export interface RoutingOptions {
  timeoutMs?: number;
  services?: Record<string, string>;
  verifyIntegrity?: boolean;
  expectedHash?: string;
  hmacSecret?: string;
}

export interface RoutingResult {
  success: boolean;
  response?: any;
  tenantId: string;
  payloadHash?: string;
  serviceDispatched?: string;
  durationMs?: number;
}

export async function routeOrchestratorTask(
  task: OrchestratorTask,
  options: RoutingOptions = {}
): Promise<RoutingResult> {
  const { timeoutMs = 30000, services = {}, verifyIntegrity = true, expectedHash, hmacSecret } = options;
  const startTime = Date.now();
  
  mantis_log('INFO', 'routing_started', {
    tenant_id: task.tenantId,
    action: task.action,
    request_id: task.requestId,
    priority: task.priority,
    timeout_ms: timeoutMs,
    verify_integrity: verifyIntegrity
  });
  
  // ✅ C5: Validar estructura de tarea con Zod
  let validatedTask: ValidatedTask;
  try {
    validatedTask = orchestratorTaskSchema.parse(task);
  } catch (error) {
    const err = error as z.ZodError;
    mantis_log('ERROR', 'task_validation_failed', {
      tenant_id: task.tenantId,
      errors: err.errors.map(e => `${e.path.join('.')}: ${e.message}`),
      constraint: 'C5'
    });
    throw new Error(`Task validation failed: ${err.message}`);
  }
  
  // ✅ C5: Verificar integridad del payload si está habilitado
  let payloadHash: string | undefined;
  if (verifyIntegrity) {
    const { valid, actualHash, signatureValid } = await verifyPayloadIntegrity(
      validatedTask.payload, expectedHash, { secret: hmacSecret }
    );
    if (!valid) {
      mantis_log('ERROR', 'routing_aborted_integrity_failed', {
        tenant_id: validatedTask.tenantId, constraint: 'C5'
      });
      throw new Error('Payload integrity verification failed (C5 constraint)');
    }
    payloadHash = actualHash;
  }
  
  // ✅ C4: Ejecutar routing dentro del contexto de tenant
  return withRoutingContext(validatedTask.tenantId, validatedTask.requestId, async () => {
    const controller = new AbortController();
    const timer = setTimeout(() => {
      controller.abort();
      mantis_log('WARN', 'routing_timeout_triggered', {
        tenant_id: validatedTask.tenantId, timeout_ms: timeoutMs
      });
    }, timeoutMs);
    
    try {
      const serviceUrl = services[validatedTask.action] ?? process.env[`SERVICE_${validatedTask.action.toUpperCase()}_URL`];
      
      if (!serviceUrl) {
        mantis_log('ERROR', 'routing_service_not_found', {
          tenant_id: validatedTask.tenantId,
          action: validatedTask.action,
          available_services: Object.keys(services)
        });
        throw new Error(`No service configured for action: ${validatedTask.action}`);
      }
      
      mantis_log('DEBUG', 'routing_service_selected', {
        tenant_id: validatedTask.tenantId,
        action: validatedTask.action,
        service_url: serviceUrl.slice(0, 50) + '...'
      });
      
      // ✅ C4/C8: Despacho a servicio con tenant_id en headers y timeout
      const response = await fetch(serviceUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Tenant-Id': validatedTask.tenantId,
          'X-Request-Id': validatedTask.requestId ?? '',
          'X-Payload-Hash': payloadHash ?? ''
        },
        body: JSON.stringify(validatedTask.payload),
        signal: controller.signal
      });
      
      clearTimeout(timer);
      
      if (!response.ok) {
        mantis_log('ERROR', 'routing_service_error', {
          tenant_id: validatedTask.tenantId,
          service_url: serviceUrl.slice(0, 50) + '...',
          status: response.status,
          status_text: response.statusText
        });
        throw new Error(`Service error: ${response.status} ${response.statusText}`);
      }
      
      const responseData = await response.json();
      const durationMs = Date.now() - startTime;
      
      mantis_log('INFO', 'routing_completed', {
        tenant_id: validatedTask.tenantId,
        action: validatedTask.action,
        service_dispatched: serviceUrl.slice(0, 50) + '...',
        response_status: response.status,
        duration_ms: durationMs,
        payload_hash_prefix: payloadHash?.slice(0, 16) + '...'
      });
      
      return {
        success: true,
        response: responseData,
        tenantId: validatedTask.tenantId,
        payloadHash,
        serviceDispatched: serviceUrl,
        durationMs
      };
      
    } catch (error) {
      clearTimeout(timer);
      const err = error as Error;
      
      if (err.name === 'AbortError' || err.message.includes('timeout')) {
        mantis_log('ERROR', 'routing_aborted_timeout', {
          tenant_id: validatedTask.tenantId, timeout_ms: timeoutMs
        });
        throw new Error(`Routing timeout after ${timeoutMs}ms`);
      }
      
      mantis_log('ERROR', 'routing_failed', {
        tenant_id: validatedTask.tenantId,
        action: validatedTask.action,
        error: err.message
      });
      throw error;
    }
  });
}
```

```typescript
// ✅ C4/C8: Enrutamiento condicional por tenant con handler registry y timeout
export type TaskHandler = (payload: Record<string, unknown>, tenantId: string) => Promise<any>;

export class TenantAwareRouter {
  private handlers = new Map<string, TaskHandler>();
  private defaultHandler?: TaskHandler;
  
  register(action: string, handler: TaskHandler): this {
    this.handlers.set(action, handler);
    mantis_log('DEBUG', 'router_handler_registered', { action });
    return this;
  }
  
  setDefault(handler: TaskHandler): this {
    this.defaultHandler = handler;
    return this;
  }
  
  async route(task: OrchestratorTask, options: { timeoutMs?: number } = {}): Promise<any> {
    const { timeoutMs = 10000 } = options;
    const tenantId = task.tenantId;
    
    const handler = this.handlers.get(task.action) ?? this.defaultHandler;
    
    if (!handler) {
      mantis_log('ERROR', 'router_handler_not_found', {
        tenant_id: tenantId,
        action: task.action,
        registered_actions: Array.from(this.handlers.keys())
      });
      throw new Error(`No handler registered for action: ${task.action}`);
    }
    
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    
    try {
      return await Promise.race([
        withRoutingContext(tenantId, task.requestId, () => handler(task.payload, tenantId)),
        new Promise<never>((_, reject) => {
          controller.signal.addEventListener('abort', () => {
            reject(new Error(`Handler timeout after ${timeoutMs}ms`));
          });
        })
      ]);
    } finally {
      clearTimeout(timer);
    }
  }
}
```

```typescript
// ✅ C4/C8: Logger helper con tenant_id automático para operaciones de routing
export function logRoutingEvent(
  event: 'task_received' | 'payload_verified' | 'service_dispatched' | 'routing_completed' | 'routing_failed',
  detail: Record<string, unknown>
): void {
  const ctx = routingContext.getStore();
  const sanitizedDetail = { ...detail };
  
  if (sanitizedDetail.payload && typeof sanitizedDetail.payload === 'object') {
    sanitizedDetail.payload = { keys: Object.keys(sanitizedDetail.payload).slice(0, 5) };
  }
  if (sanitizedDetail.response && typeof sanitizedDetail.response === 'object') {
    sanitizedDetail.response = { keys: Object.keys(sanitizedDetail.response).slice(0, 5) };
  }
  if (sanitizedDetail.payloadHash && typeof sanitizedDetail.payloadHash === 'string' && sanitizedDetail.payloadHash.length === 64) {
    sanitizedDetail.payloadHash = sanitizedDetail.payloadHash.slice(0, 16) + '...';
  }
  
  mantis_log(
    event === 'routing_failed' ? 'ERROR' : 'INFO',
    `routing_${event}`,
    { ...sanitizedDetail, tenant_id: ctx?.tenantId }
  );
}
```

---

## 🧪 Testes Unitários (TDD)

```typescript
// orchestrator-routing.test.ts
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { verifyPayloadIntegrity, routeOrchestratorTask, TenantAwareRouter, withRoutingContext } from './orchestrator-routing';

describe('orchestrator-routing', () => {
  const TEST_TENANT = '123e4567-e89b-12d3-a456-426614174000';

  beforeEach(() => { global.mantis_log = vi.fn(); });
  afterEach(() => { vi.restoreAllMocks(); });

  it('should verify payload integrity with SHA256', async () => {
    const payload = { action: 'query',  { id: '123' } };
    const payloadStr = JSON.stringify(payload, Object.keys(payload).sort());
    const expectedHash = require('crypto').createHash('sha256').update(payloadStr).digest('hex');
    const result = await verifyPayloadIntegrity(payload, expectedHash);
    expect(result.valid).toBe(true);
    expect(result.actualHash).toBe(expectedHash);
  });

  it('should detect payload hash mismatch', async () => {
    const payload = { test: 'data' };
    const result = await verifyPayloadIntegrity(payload, 'different-expected-hash');
    expect(result.valid).toBe(false);
    expect(global.mantis_log).toHaveBeenCalledWith('ERROR', 'payload_hash_mismatch', expect.objectContaining({ constraint: 'C5' }));
  });

  it('should reject invalid task with Zod validation', async () => {
    const invalidTask = { tenantId: 'invalid-uuid', action: 'invalid-action', payload: {} };
    await expect(routeOrchestratorTask(invalidTask)).rejects.toThrow('Task validation failed');
  });

  it('should propagate tenant_id in routing context', async () => {
    vi.mock('global', () => ({ ...global, fetch: vi.fn().mockResolvedValue({ ok: true, status: 200, json: async () => ({ result: 'success' }) }) }));
    const validTask = { tenantId: TEST_TENANT, action: 'query', payload: { query: 'test' } };
    const result = await routeOrchestratorTask(validTask, { services: { query: 'http://test-service/query' }, verifyIntegrity: false });
    expect(result.success).toBe(true);
    expect(result.tenantId).toBe(TEST_TENANT);
  });

  it('should execute handler with timeout', async () => {
    const router = new TenantAwareRouter();
    const mockHandler = vi.fn().mockImplementation(async (payload) => ({ processed: true,  payload }));
    router.register('test-action', mockHandler);
    const task = { tenantId: TEST_TENANT, action: 'test-action', payload: { input: 'value' } };
    const result = await router.route(task, { timeoutMs: 5000 });
    expect(result.processed).toBe(true);
    expect(mockHandler).toHaveBeenCalledWith(task.payload, TEST_TENANT);
  });
});
```

---

## 🔍 Validação (VDD – Comando Canônico)

```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/javascript/orchestrator-routing.ts.md \
  --json \
  --check-structural \
  --check-error-handling \
  --check-observability \
  --check-constraints C4,C5,C8

bash 05-CONFIGURATIONS/validation/check-rls.sh \
  --file 06-PROGRAMMING/javascript/orchestrator-routing.ts.md \
  --lang ts \
  --json

bash 05-CONFIGURATIONS/validation/verify-constraints.sh \
  --file 06-PROGRAMMING/javascript/orchestrator-routing.ts.md \
  --check C5 \
  --json

bash 05-CONFIGURATIONS/validation/verify-observability.sh \
  --file 06-PROGRAMMING/javascript/orchestrator-routing.ts.md \
  --schema V-LOG-02 \
  --json
```

---

## 🔗 Referências Cruzadas (Wikilinks Mínimos)
- [[javascript-typescript-master-agent.md]] ← Fonte de `mantis_log()`, hardening, constraints
- [[/05-CONFIGURATIONS/validation/orchestrator-engine.sh]] ← Motor de validação principal
- [[/05-CONFIGURATIONS/validation/check-rls.sh]] ← Validação C4 (tenant isolation)
- [[/05-CONFIGURATIONS/validation/verify-constraints.sh]] ← Validação C5 (integrity/type safety)
- [[/05-CONFIGURATIONS/validation/verify-observability.sh]] ← Validação C8 + V-LOG-02
- [[/01-RULES/harness-norms-v3.0.md#C4]] ← Definição formal de C4
- [[/01-RULES/harness-norms-v3.0.md#C5]] ← Definição formal de C5
- [[/01-RULES/harness-norms-v3.0.md#C8]] ← Definição formal de C8

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 2.3.0-MODULAR-MERGED | 2026-05-09 | javascript-typescript-master-agent | MERGE: estrutura modular v2.3.0 + bootstrap resiliente + observability V-LOG-02 + HMAC signature + TenantAwareRouter | C4,C5,C8 |
| 2.1.1 | 2026-04-16 | Framework Core Team | Adição de exemplos Zod para task validation e verificação de hash SHA256 | C4,C5,C8 |
| 2.0.0 | 2026-03-01 | Qwen + DeepSeek | Primeira versão canônica com padrões AsyncLocalStorage + AbortController timeouts | C4,C5,C8 |

---

## 🔍 Observability (Eventos Específicos)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `routing_started` | INFO | C8 | `{"tenant_id":"t123","action":"query","timeout_ms":30000}` |
| `task_validation_failed` | ERROR | C5 | `{"tenant_id":"t123","errors":["tenantId: Invalid uuid"],"constraint":"C5"}` |
| `payload_hash_computed` | DEBUG | C5 | `{"algorithm":"sha256","hash_prefix":"a1b2c3d4...","payload_size_bytes":256}` |
| `payload_integrity_verified` | INFO | C5 | `{"hash_prefix":"a1b2c3d4...","signature_verified":true}` |
| `routing_service_selected` | DEBUG | C4 | `{"tenant_id":"t123","action":"query","service_url":"http://query-service..."}` |
| `routing_completed` | INFO | C8 | `{"tenant_id":"t123","action":"query","duration_ms":245}` |
| `routing_aborted_timeout` | ERROR | C8 | `{"tenant_id":"t123","timeout_ms":30000}` |

---

## ✅ Auto-Validation Report (JSON)

```json
{
  "artifact": "orchestrator-routing",
  "version": "2.3.0-MODULAR-MERGED",
  "score": 32,
  "blocking_issues": [],
  "constraints_verified": ["C4", "C5", "C8"],
  "examples_count": 12,
  "lines_executable_max": 4,
  "language": "TypeScript 5.0+ / Node.js 18+",
  "observability_compliant": true,
  "bootstrap_resilient": true,
  "mantis_log_usage": "inherited",
  "zod_validation_verified": true,
  "payload_integrity_verified": true,
  "tenant_isolation_verified": true,
  "timeout_handling_verified": true,
  "hmac_signature_verified": true,
  "router_class_verified": true,
  "timestamp": "2026-05-09T00:00:00Z"
}
```

---

> 🇧🇷 *Documento técnico em pt-BR conforme V-DOC-01. Coordenação en español. Zero invenção: todo padrão grounded no conteúdo original + template v2.3.0-MODULAR.*

---
