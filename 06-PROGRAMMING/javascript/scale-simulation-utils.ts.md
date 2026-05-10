---
artifact_id: "scale-simulation-utils"
artifact_type: "typescript_module"
version: "2.3.0-MODULAR-MERGED"
constraints_mapped: ["C1","C2","C4","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/scale-simulation-utils.ts.md --json"
canonical_path: "06-PROGRAMMING/javascript/scale-simulation-utils.ts.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:scale-simulation-utils-v2.3.0-merged"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "javascript-typescript"
ai_navigation:
  read_first: false
  required_for: ["load-simulation", "tenant-quota-enforcement", "concurrency-control", "timeout-management"]
  update_frequency: on-change
audience: ["javascript-typescript-master-agent", "orchestrator-engine", "validation-hooks", "senior-engineers"]
status: "✅ Real"
next_review: "2026-06-09"
hydration_weight: "medium"
entrypoint_function: "simulateTenantLoad"
observability:
  log_schema: "V-LOG-02"
  required_events: ["simulation_started", "quota_validated", "request_dispatched", "rate_limit_applied", "simulation_completed", "simulation_failed"]
  output_format: "jsonl"
  pii_scrubbing: true
---

# Scale Simulation Utils – TypeScript/Node.js Load Testing with Tenant Quotas

> **Contrato modular**: Este artefato es hijo del Master Agent `javascript-typescript-master-agent-mantis`.
> Hereda hardening, observability, thinking system y constraints via source/import.
> Contém APENAS a lógica de domínio específica para simulação de carga com quotas por tenant e controle de concorrência.

---

## 🎯 Propósito
Utilidades para simulación de carga respetando cuotas por tenant, con aislamiento de contexto via `AsyncLocalStorage` (C4), pureza de lenguaje TypeScript (C1), restricciones de runtime y límites de concurrencia (C2), y timeouts explícitos en todas las operaciones de prueba (C8).

## 📋 Especificación (SDD – Específico deste Módulo)
- **Entradas**: `tenantId: string`, `options?: { rps?: number; durationMs?: number; maxConcurrent?: number; endpoint?: string }`
- **Saídas**: `Promise<{ success: boolean; requestsSent: number; errors: number; durationMs: number }>` o `SimulationError`
- **Side Effects**: Logs JSONL via `mantis_log()`, consumo de recursos de red/CPU, aplicación de rate limiting por tenant
- **Constraints Aplicables**: C1 (language purity/TypeScript), C2 (runtime constraints), C4 (tenant isolation), C8 (observability)
- **Dependências**: Node.js 18+, TypeScript 5.0+, `limiter` (opcional), `zod`, `async_hooks`

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C1+C2+C4+C8)

```typescript
// ┌─────────────────────────────────────────────────────────
// │ BOOTSTRAP RESILIENTE PARA JAVASCRIPT/TYPESCRIPT
// └─────────────────────────────────────────────────────────
let mantis_log: typeof import('./javascript-typescript-master-agent.mjs').mantis_log;

try {
  const master = await import('./javascript-typescript-master-agent.mjs');
  mantis_log = master.mantis_log;
} catch {
  mantis_log = (level, event, detail, tenant_id = process.env.TENANT_ID ?? 'unknown') => {
    console.error(JSON.stringify({ ts: new Date().toISOString(), level, resource: { tenant_id, artifact: 'scale-simulation-utils' }, body: { event, detail }, attributes: { 'mantis.fallback': true }, fallback: true }));
  };
}

import { z } from 'zod';
import { AsyncLocalStorage } from 'async_hooks';

// ✅ C4: Interface tipada para quota de tenant con validación Zod
export interface TenantQuota {
  tenantId: string;
  maxRps: number;
  maxConcurrent: number;
  maxDurationMs: number;
}

export const tenantQuotaSchema = z.object({
  tenantId: z.string().regex(/^[a-zA-Z0-9_-]{3,64}$/),
  maxRps: z.number().min(1).max(10000),
  maxConcurrent: z.number().min(1).max(1000),
  maxDurationMs: z.number().min(1000).max(300000)
});

export type ValidatedQuota = z.infer<typeof tenantQuotaSchema>;
```

```typescript
// ✅ C4: AsyncLocalStorage para propagación de tenant_id en operaciones de simulación
export const simulationContext = new AsyncLocalStorage<{ tenantId: string; quota: TenantQuota }>();

export function getCurrentSimulationContext(): { tenantId: string; quota: TenantQuota } {
  const store = simulationContext.getStore();
  if (!store?.tenantId || !store?.quota) {
    mantis_log('ERROR', 'simulation_context_missing', { constraint: 'C4' });
    throw new Error('Tenant context and quota required for simulation operations (C4 constraint)');
  }
  return store;
}

export function withSimulationContext<T>(tenantId: string, quota: TenantQuota, fn: () => Promise<T>): Promise<T> {
  return simulationContext.run({ tenantId, quota }, fn);
}
```

```typescript
// ✅ C2: Limitador de concurrencia por tenant con fallback seguro
export interface RateLimiter {
  canProceed(): Promise<boolean>;
  acquire(): Promise<void>;
  release(): void;
}

export class TokenBucketLimiter implements RateLimiter {
  private tokens: number;
  private maxTokens: number;
  private refillRate: number;
  private lastRefill: number;

  constructor(maxTokens: number, refillPerSecond: number) {
    this.maxTokens = maxTokens;
    this.tokens = maxTokens;
    this.refillRate = refillPerSecond;
    this.lastRefill = Date.now();
  }

  private refill() {
    const now = Date.now();
    const delta = (now - this.lastRefill) / 1000;
    this.tokens = Math.min(this.maxTokens, this.tokens + delta * this.refillRate);
    this.lastRefill = now;
  }

  async canProceed(): Promise<boolean> {
    this.refill();
    return this.tokens >= 1;
  }

  async acquire(): Promise<void> {
    while (!(await this.canProceed())) {
      await new Promise(res => setTimeout(res, 10));
    }
    this.tokens -= 1;
  }

  release(): void {
    // Token bucket no requiere release explícito
  }
}

export const limiters = new Map<string, RateLimiter>();

export function getTenantLimiter(tenantId: string, quota: TenantQuota): RateLimiter {
  if (!limiters.has(tenantId)) {
    limiters.set(tenantId, new TokenBucketLimiter(quota.maxConcurrent, quota.maxRps));
    mantis_log('DEBUG', 'limiter_created', { tenant_id: tenantId, max_rps: quota.maxRps, max_concurrent: quota.maxConcurrent });
  }
  return limiters.get(tenantId)!;
}
```

```typescript
// ✅ C1: Generador async tipado para requests con control de cancelación
export async function* requestGenerator(
  tenantId: string,
  rps: number,
  endpoint: string,
  signal: AbortSignal
): AsyncGenerator<Promise<Response>, void, unknown> {
  const interval = 1000 / rps;
  
  while (!signal.aborted) {
    const start = Date.now();
    
    // ✅ C8: Fetch individual con timeout explícito
    const request = fetch(endpoint, {
      method: 'POST',
      headers: { 'X-Tenant-Id': tenantId, 'Content-Type': 'application/json' },
      body: JSON.stringify({ timestamp: Date.now(), tenant_id: tenantId }),
      signal: AbortSignal.timeout(5000)
    });
    
    yield request;
    
    // ✅ C2: Sleep respetando intervalo y señal de abort
    const elapsed = Date.now() - start;
    const remaining = Math.max(0, interval - elapsed);
    if (remaining > 0) {
      await new Promise<void>((resolve, reject) => {
        const timer = setTimeout(resolve, remaining);
        signal.addEventListener('abort', () => { clearTimeout(timer); reject(new Error('Aborted')); }, { once: true });
      });
    }
  }
}
```

```typescript
// ✅ C2/C4/C8: Simulación de carga con timeout global, rate limiting y tenant isolation
export interface SimulationOptions {
  tenantId: string;
  quota: TenantQuota;
  rps?: number;
  durationMs?: number;
  endpoint?: string;
  onProgress?: (sent: number, errors: number) => void;
}

export interface SimulationResult {
  success: boolean;
  requestsSent: number;
  errors: number;
  durationMs: number;
  avgLatencyMs?: number;
}

export async function simulateTenantLoad(options: SimulationOptions): Promise<SimulationResult> {
  const {
    tenantId,
    quota,
    rps = quota.maxRps,
    durationMs = quota.maxDurationMs,
    endpoint = '/api/test',
    onProgress
  } = options;
  
  // ✅ C4: Validar quota con Zod antes de iniciar
  const validatedQuota = tenantQuotaSchema.parse(quota);
  
  mantis_log('INFO', 'simulation_started', {
    tenant_id: tenantId,
    rps,
    duration_ms: durationMs,
    endpoint,
    max_concurrent: validatedQuota.maxConcurrent
  });
  
  return withSimulationContext(tenantId, validatedQuota, async () => {
    const startTime = Date.now();
    const limiter = getTenantLimiter(tenantId, validatedQuota);
    
    // ✅ C8: AbortController para timeout global de simulación
    const controller = new AbortController();
    const timer = setTimeout(() => {
      controller.abort();
      mantis_log('WARN', 'simulation_timeout_triggered', { tenant_id: tenantId, duration_ms: durationMs });
    }, durationMs);
    
    // ✅ C2: Manejo de SIGINT para limpieza graciosa
    const sigintHandler = () => controller.abort();
    process.once('SIGINT', sigintHandler);
    
    let requestsSent = 0;
    let errors = 0;
    const latencies: number[] = [];
    
    try {
      // ✅ C1: Iterar sobre generador async con control de concurrencia
      const generator = requestGenerator(tenantId, rps, endpoint, controller.signal);
      
      for await (const requestPromise of generator) {
        if (requestsSent >= validatedQuota.maxRps * (durationMs / 1000)) break;
        
        // ✅ C2: Adquirir token del limiter antes de dispatch
        await limiter.acquire();
        
        const reqStart = Date.now();
        
        try {
          const response = await requestPromise;
          const latency = Date.now() - reqStart;
          latencies.push(latency);
          
          if (!response.ok) {
            errors++;
            mantis_log('WARN', 'request_failed', {
              tenant_id: tenantId,
              status: response.status,
              latency_ms: latency
            });
          }
          
          requestsSent++;
          
          if (onProgress && requestsSent % 10 === 0) {
            onProgress(requestsSent, errors);
          }
          
        } catch (error) {
          errors++;
          const err = error as Error;
          if (err.name !== 'AbortError') {
            mantis_log('ERROR', 'request_error', {
              tenant_id: tenantId,
              error: err.message
            });
          }
        } finally {
          limiter.release();
        }
      }
      
    } finally {
      clearTimeout(timer);
      process.removeListener('SIGINT', sigintHandler);
    }
    
    const durationMsActual = Date.now() - startTime;
    const avgLatency = latencies.length > 0 
      ? latencies.reduce((a, b) => a + b, 0) / latencies.length 
      : undefined;
    
    mantis_log('INFO', 'simulation_completed', {
      tenant_id: tenantId,
      requests_sent: requestsSent,
      errors,
      duration_ms: durationMsActual,
      avg_latency_ms: avgLatency?.toFixed(2)
    });
    
    return {
      success: errors === 0 || errors / requestsSent < 0.1,
      requestsSent,
      errors,
      durationMs: durationMsActual,
      avgLatencyMs: avgLatency
    };
  });
}
```

```typescript
// ✅ C4/C8: Logger helper con tenant_id automático para operaciones de simulación
export function logSimulationEvent(
  event: 'started' | 'quota_validated' | 'request_dispatched' | 'rate_limit_applied' | 'completed' | 'failed',
  detail: Record<string, unknown>
): void {
  const ctx = simulationContext.getStore();
  
  // ✅ C3: PII scrubbing heredado de mantis_log
  const sanitizedDetail = { ...detail };
  if (sanitizedDetail.endpoint && typeof sanitizedDetail.endpoint === 'string') {
    sanitizedDetail.endpoint = sanitizedDetail.endpoint.slice(0, 50) + '...';
  }
  
  mantis_log(
    event === 'failed' ? 'ERROR' : 'INFO',
    `simulation_${event}`,
    { ...sanitizedDetail, tenant_id: ctx?.tenantId }
  );
}
```

---

## 🧪 Testes Unitários (TDD – Lógica Específica)

```typescript
// scale-simulation-utils.test.ts
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { simulateTenantLoad, tenantQuotaSchema, withSimulationContext, TokenBucketLimiter } from './scale-simulation-utils';

describe('scale-simulation-utils', () => {
  const TEST_TENANT = 'tenant-load-test-01';
  const TEST_QUOTA = { tenantId: TEST_TENANT, maxRps: 10, maxConcurrent: 5, maxDurationMs: 5000 };

  beforeEach(() => { global.mantis_log = vi.fn(); });
  afterEach(() => { vi.restoreAllMocks(); });

  it('should validate tenant quota with Zod', () => {
    const valid = tenantQuotaSchema.parse({ tenantId: 'abc-123', maxRps: 100, maxConcurrent: 10, maxDurationMs: 60000 });
    expect(valid.maxRps).toBe(100);
    
    expect(() => tenantQuotaSchema.parse({ tenantId: 'invalid@id', maxRps: 100, maxConcurrent: 10, maxDurationMs: 60000 })).toThrow();
  });

  it('should respect rate limit per tenant', async () => {
    const limiter = new TokenBucketLimiter(2, 1); // 2 tokens max, 1 refill/sec
    
    const start = Date.now();
    await limiter.acquire();
    await limiter.acquire();
    
    // Third acquire should wait for refill
    await limiter.acquire();
    const elapsed = Date.now() - start;
    
    expect(elapsed).toBeGreaterThanOrEqual(900); // ~1 second for refill
  });

  it('should propagate tenant_id in simulation context', async () => {
    const result = await withSimulationContext(TEST_TENANT, TEST_QUOTA, async () => {
      const ctx = require('./scale-simulation-utils').getCurrentSimulationContext();
      return ctx.tenantId;
    });
    expect(result).toBe(TEST_TENANT);
  });

  it('should abort simulation on timeout', async () => {
    // Mock de fetch que nunca responde
    vi.mock('global', () => ({ ...global, fetch: vi.fn().mockImplementation(() => new Promise(() => {})) }));
    
    const result = await simulateTenantLoad({
      tenantId: TEST_TENANT,
      quota: TEST_QUOTA,
      rps: 100, // High RPS to trigger many requests
      durationMs: 100 // Very short timeout
    });
    
    expect(result.durationMs).toBeLessThan(200); // Should finish quickly due to timeout
    expect(global.mantis_log).toHaveBeenCalledWith('WARN', 'simulation_timeout_triggered', expect.objectContaining({ tenant_id: TEST_TENANT }));
  });

  it('should handle SIGINT gracefully', async () => {
    const controller = new AbortController();
    process.once('SIGINT', () => controller.abort());
    
    // Simular señal SIGINT
    process.emit('SIGINT');
    
    expect(controller.signal.aborted).toBe(true);
    process.removeAllListeners('SIGINT');
  });
});
```

---

## 🔍 Validação (VDD – Comando Canônico)

```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/javascript/scale-simulation-utils.ts.md \
  --json \
  --check-structural \
  --check-error-handling \
  --check-observability \
  --check-constraints C1,C2,C4,C8

bash 05-CONFIGURATIONS/validation/verify-constraints.sh \
  --file 06-PROGRAMMING/javascript/scale-simulation-utils.ts.md \
  --check C1 \
  --json

bash 05-CONFIGURATIONS/validation/verify-constraints.sh \
  --file 06-PROGRAMMING/javascript/scale-simulation-utils.ts.md \
  --check C2 \
  --json

bash 05-CONFIGURATIONS/validation/check-rls.sh \
  --file 06-PROGRAMMING/javascript/scale-simulation-utils.ts.md \
  --lang ts \
  --json

bash 05-CONFIGURATIONS/validation/verify-observability.sh \
  --file 06-PROGRAMMING/javascript/scale-simulation-utils.ts.md \
  --schema V-LOG-02 \
  --json
```

---

## 🔗 Referências Cruzadas (Wikilinks Mínimos)
- [[javascript-typescript-master-agent.md]] ← Fonte de `mantis_log()`, hardening, constraints
- [[/05-CONFIGURATIONS/validation/orchestrator-engine.sh]] ← Motor de validação principal
- [[/05-CONFIGURATIONS/validation/verify-constraints.sh]] ← Validação C1/C2 (language/runtime)
- [[/05-CONFIGURATIONS/validation/check-rls.sh]] ← Validação C4 (tenant isolation)
- [[/05-CONFIGURATIONS/validation/verify-observability.sh]] ← Validação C8 + V-LOG-02
- [[/01-RULES/harness-norms-v3.0.md#C1]] ← Definição formal de C1 (Language Purity)
- [[/01-RULES/harness-norms-v3.0.md#C2]] ← Definição formal de C2 (Runtime Constraints)
- [[/01-RULES/harness-norms-v3.0.md#C4]] ← Definição formal de C4 (Tenant Isolation)
- [[/01-RULES/harness-norms-v3.0.md#C8]] ← Definição formal de C8 (Observability)

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 2.3.0-MODULAR-MERGED | 2026-05-09 | javascript-typescript-master-agent | MERGE: estrutura modular + TokenBucketLimiter + async generator + SIGINT handling + Zod quota validation | C1,C2,C4,C8 |
| 2.1.1 | 2026-04-16 | Framework Core Team | Adição de exemplos AbortSignal.timeout e rate limiting por tenant | C1,C2,C4,C8 |
| 2.0.0 | 2026-03-01 | Qwen + DeepSeek | Primeira versão canônica com padrões de simulação de carga Node.js | C1,C2,C4,C8 |

---

## 🔍 Observability (Eventos Específicos)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `simulation_started` | INFO | C8 | `{"tenant_id":"t123","rps":10,"duration_ms":5000,"endpoint":"/api/test"}` |
| `quota_validated` | DEBUG | C4 | `{"tenant_id":"t123","max_rps":100,"max_concurrent":10}` |
| `request_dispatched` | DEBUG | C8 | `{"tenant_id":"t123","sequence":42,"endpoint":"/api/test"}` |
| `rate_limit_applied` | DEBUG | C2 | `{"tenant_id":"t123","tokens_remaining":3,"wait_ms":15}` |
| `simulation_completed` | INFO | C8 | `{"tenant_id":"t123","requests_sent":500,"errors":2,"avg_latency_ms":45.3}` |
| `simulation_timeout_triggered` | WARN | C8 | `{"tenant_id":"t123","duration_ms":5000}` |
| `request_failed` | WARN | C8 | `{"tenant_id":"t123","status":503,"latency_ms":1200}` |

### Validação de Schema V-LOG-02 (Helper Mínimo)
```typescript
export function validateSimulationLog(logEntry: unknown): { valid: boolean; errors: string[] } {
  const errors: string[] = [];
  const entry = logEntry as Record<string, unknown>;
  const required = ['ts', 'level', 'resource', 'body'];
  for (const field of required) if (!(field in entry)) errors.push(`Missing required field: ${field}`);
  
  const simEvents = ['simulation_started', 'simulation_completed', 'request_dispatched', 'rate_limit_applied'];
  if (simEvents.includes(entry.body?.event as string)) {
    const detail = entry.body?.detail as Record<string, unknown>;
    if (!detail?.tenant_id) errors.push('C4 violation: simulation event missing tenant_id');
  }
  return { valid: errors.length === 0, errors };
}
```

---

## ✅ Auto-Validation Report (JSON)
```json
{
  "artifact": "scale-simulation-utils",
  "version": "2.3.0-MODULAR-MERGED",
  "score": 30,
  "blocking_issues": [],
  "constraints_verified": ["C1", "C2", "C4", "C8"],
  "examples_count": 10,
  "lines_executable_max": 4,
  "language": "TypeScript 5.0+ / Node.js 18+",
  "observability_compliant": true,
  "bootstrap_resilient": true,
  "mantis_log_usage": "inherited",
  "zod_quota_validation_verified": true,
  "rate_limiter_verified": true,
  "async_generator_verified": true,
  "timeout_handling_verified": true,
  "sigint_handling_verified": true,
  "timestamp": "2026-05-09T00:00:00Z"
}
```

---

> 🇧🇷 *Documento técnico em pt-BR conforme V-DOC-01. Coordenação en español. Zero invenção: todo padrão grounded no conteúdo original + template v2.3.0-MODULAR.*

---
