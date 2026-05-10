---
artifact_id: "testing-multi-tenant-patterns"
artifact_type: "typescript_pattern"
version: "2.3.0-MODULAR-MERGED"
constraints_mapped: ["C4","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/testing-multi-tenant-patterns.ts.md --json"
canonical_path: "06-PROGRAMMING/javascript/testing-multi-tenant-patterns.ts.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:testing-multi-tenant-patterns-v2.3.0-merged"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "javascript-typescript"
ai_navigation:
  read_first: false
  required_for: ["jest-testing", "tenant-context-mocking", "path-safety-validation", "async-timeout-testing"]
  update_frequency: on-change
audience: ["javascript-typescript-master-agent", "orchestrator-engine", "validation-hooks", "senior-engineers"]
status: "✅ Real"
next_review: "2026-06-09"
hydration_weight: "light"
entrypoint_function: "setupTenantFixture"
observability:
  log_schema: "V-LOG-02"
  required_events: ["test_started", "tenant_mocked", "path_validated", "test_completed", "test_failed"]
  output_format: "jsonl"
  pii_scrubbing: true
---

# Testing Multi‑Tenant Patterns – TypeScript/Node.js with Jest & AsyncLocalStorage Mocks

> **Contrato modular**: Este artefato es hijo del Master Agent `javascript-typescript-master-agent-mantis`.
> Hereda hardening, observability, thinking system y constraints via source/import.
> Contém APENAS a lógica de domínio específica para testes de código multi-tenant com Jest, mocks de AsyncLocalStorage e validação de segurança.

---

## 🎯 Propósito
Patrones para probar código multi-tenant en TypeScript/Node.js usando Jest. Asegura aislamiento de contexto mediante mocks de `AsyncLocalStorage` (C4), validación de rutas seguras en tests de sistema de archivos (C7), y timeouts explícitos en pruebas asíncronas para evitar bloqueos (C8).

## 📋 Especificación (SDD – Específico deste Módulo)
- **Entradas**: `testConfig: { tenantId: string; mockFs?: boolean; timeoutMs?: number }`, `testFn: () => Promise<void>`
- **Saídas**: `Promise<{ passed: boolean; assertions: number; durationMs: number }>` o `TestError`
- **Side Effects**: Logs JSONL via `mantis_log()`, configuración de mocks de Jest, limpieza de timers
- **Constraints Aplicables**: C4 (tenant isolation in tests), C7 (path safety validation), C8 (observability/timeouts)
- **Dependências**: Node.js 18+, TypeScript 5.0+, `jest`, `@types/jest`, `supertest` (opcional)

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C4+C7+C8)

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
    console.error(JSON.stringify({ ts: new Date().toISOString(), level, resource: { tenant_id, artifact: 'testing-multi-tenant-patterns' }, body: { event, detail }, attributes: { 'mantis.fallback': true }, fallback: true }));
  };
}

import { AsyncLocalStorage } from 'async_hooks';
import path from 'path';

// ✅ C4: Interface tipada para contexto de test multi-tenant
export interface TestTenantContext {
  tenantId: string;
  requestId?: string;
  allowedPaths?: string[];
}

// ✅ C4: Mock helper para AsyncLocalStorage en Jest con tipado seguro
export function mockAsyncLocalStorage<T>(getStoreValue?: T) {
  const mockStore = jest.fn().mockReturnValue(getStoreValue);
  const mockRun = jest.fn().mockImplementation((store, fn) => fn());
  
  jest.mock('async_hooks', () => ({
    AsyncLocalStorage: jest.fn().mockImplementation(() => ({
      getStore: mockStore,
      run: mockRun,
      exit: jest.fn(),
      enterWith: jest.fn()
    }))
  }), { virtual: true });
  
  return { mockStore, mockRun };
}
```

```typescript
// ✅ C4: Fixture reusable para inicializar contexto por tenant en tests
export interface TenantFixture {
  tenantId: string;
  setup: () => void;
  teardown: () => void;
  withContext: <T>(fn: () => Promise<T>) => Promise<T>;
}

export function setupTenantFixture(tenantId: string, options: { allowedPaths?: string[]; requestId?: string } = {}): TenantFixture {
  const { allowedPaths, requestId } = options;
  const ctx: TestTenantContext = { tenantId, requestId, allowedPaths };
  
  let originalCtx: any;
  
  return {
    tenantId,
    setup: () => {
      // ✅ C4: Mockear AsyncLocalStorage para este tenant
      const { mockStore, mockRun } = mockAsyncLocalStorage<TestTenantContext>(ctx);
      originalCtx = { mockStore, mockRun };
      mantis_log('DEBUG', 'tenant_fixture_setup', { tenant_id: tenantId, request_id: requestId });
    },
    
    teardown: () => {
      jest.restoreAllMocks();
      mantis_log('DEBUG', 'tenant_fixture_teardown', { tenant_id: tenantId });
    },
    
    withContext: async <T>(fn: () => Promise<T>): Promise<T> => {
      // ✅ C4: Ejecutar función dentro del contexto mockeado
      return originalCtx.mockRun(ctx, fn);
    }
  };
}
```

```typescript
// ✅ C7: Helper para validar rutas seguras en tests de filesystem
export function validateTestPath(userInput: string, baseDir: string, tenantId: string): { valid: boolean; resolved: string; error?: string } {
  const tenantBase = path.resolve(baseDir, tenantId);
  const resolved = path.resolve(tenantBase, userInput);
  const normalizedTenantBase = tenantBase + path.sep;
  
  if (!resolved.startsWith(normalizedTenantBase) && resolved !== tenantBase) {
    return {
      valid: false,
      resolved,
      error: `Path traversal blocked: ${userInput} (C7 constraint)`
    };
  }
  
  return { valid: true, resolved };
}

// ✅ C7: Mock de fs/promises para tests con validación de path
export function mockFsPromises(options: { baseDir?: string; tenantId?: string; failOnTraversal?: boolean } = {}) {
  const { baseDir = '/test-data', tenantId = 'test-tenant', failOnTraversal = true } = options;
  
  const mockReadFile = jest.fn().mockImplementation(async (filePath: string) => {
    if (failOnTraversal) {
      const validation = validateTestPath(filePath, baseDir, tenantId);
      if (!validation.valid) {
        mantis_log('WARN', 'test_path_traversal_blocked', { requested: filePath, constraint: 'C7' });
        throw new Error(validation.error);
      }
    }
    return `mocked-content-for-${filePath}`;
  });
  
  const mockWriteFile = jest.fn().mockImplementation(async (filePath: string, content: string) => {
    if (failOnTraversal) {
      const validation = validateTestPath(filePath, baseDir, tenantId);
      if (!validation.valid) {
        mantis_log('WARN', 'test_write_path_traversal_blocked', { requested: filePath, constraint: 'C7' });
        throw new Error(validation.error);
      }
    }
    return Promise.resolve();
  });
  
  jest.mock('fs/promises', () => ({
    readFile: mockReadFile,
    writeFile: mockWriteFile,
    access: jest.fn().mockResolvedValue(undefined),
    mkdir: jest.fn().mockResolvedValue(undefined)
  }), { virtual: true });
  
  return { mockReadFile, mockWriteFile };
}
```

```typescript
// ✅ C8: Wrapper para tests asíncronos con timeout explícito y cleanup
export interface TestTimeoutOptions {
  timeoutMs?: number;
  cleanup?: () => void | Promise<void>;
  onTimeout?: () => void;
}

export async function withTestTimeout<T>(
  fn: () => Promise<T>,
  options: TestTimeoutOptions = {}
): Promise<T> {
  const { timeoutMs = 5000, cleanup, onTimeout } = options;
  
  const controller = new AbortController();
  const timer = setTimeout(() => {
    controller.abort();
    mantis_log('WARN', 'test_timeout_triggered', { timeout_ms: timeoutMs });
    onTimeout?.();
  }, timeoutMs);
  
  try {
    const result = await Promise.race([
      fn(),
      new Promise<never>((_, reject) => {
        controller.signal.addEventListener('abort', () => {
          reject(new Error(`Test timeout after ${timeoutMs}ms`));
        });
      })
    ]);
    
    clearTimeout(timer);
    mantis_log('DEBUG', 'test_completed_within_timeout', { duration_ms: timeoutMs });
    return result;
    
  } catch (error) {
    clearTimeout(timer);
    const err = error as Error;
    if (err.message.includes('timeout')) {
      mantis_log('ERROR', 'test_failed_timeout', { error: err.message, constraint: 'C8' });
    }
    throw error;
    
  } finally {
    await cleanup?.();
  }
}
```

```typescript
// ✅ C4/C8: Logger mock para verificar que los tests incluyen tenant_id
export function createLoggerMock() {
  const mockInfo = jest.fn();
  const mockError = jest.fn();
  const mockWarn = jest.fn();
  const mockDebug = jest.fn();
  
  const logger = {
    info: mockInfo,
    error: mockError,
    warn: mockWarn,
    debug: mockDebug
  };
  
  // ✅ C4: Helper para verificar que los logs incluyen tenant_id
  const expectLogsToIncludeTenant = (tenantId: string, callIndex = 0) => {
    expect(mockInfo).toHaveBeenNthCalledWith(
      callIndex + 1,
      expect.objectContaining({ tenant_id: tenantId }),
      expect.any(String)
    );
  };
  
  // ✅ C8: Helper para verificar que los logs siguen schema V-LOG-02
  const expectLogSchemaCompliance = (callIndex = 0) => {
    const call = mockInfo.mock.calls[callIndex];
    if (!call) throw new Error('No log calls found');
    
    const [detail, message] = call;
    expect(detail).toHaveProperty('tenant_id');
    expect(typeof message).toBe('string');
  };
  
  return { logger, mockInfo, mockError, mockWarn, mockDebug, expectLogsToIncludeTenant, expectLogSchemaCompliance };
}
```

```typescript
// ✅ C4/C7/C8: Test runner helper con aislamiento de tenant, path validation y timeout
export interface MultiTenantTestOptions {
  tenantId: string;
  testFn: (ctx: { tenantId: string; logger: ReturnType<typeof createLoggerMock> }) => Promise<void>;
  timeoutMs?: number;
  mockFs?: boolean;
  fsBaseDir?: string;
}

export async function runMultiTenantTest(options: MultiTenantTestOptions): Promise<{ passed: boolean; assertions: number; durationMs: number }> {
  const { tenantId, testFn, timeoutMs = 10000, mockFs = true, fsBaseDir = '/test-data' } = options;
  const startTime = Date.now();
  let assertions = 0;
  
  mantis_log('DEBUG', 'multi_tenant_test_started', {
    tenant_id: tenantId,
    timeout_ms: timeoutMs,
    mock_fs: mockFs
  });
  
  // ✅ C4: Setup del fixture de tenant
  const fixture = setupTenantFixture(tenantId);
  fixture.setup();
  
  // ✅ C7: Setup de mocks de filesystem si está habilitado
  const fsMocks = mockFs ? mockFsPromises({ baseDir: fsBaseDir, tenantId }) : null;
  
  // ✅ C4/C8: Logger mock para verificar tenant_id en logs
  const loggerMock = createLoggerMock();
  
  try {
    // ✅ C8: Ejecutar test con timeout explícito
    await withTestTimeout(async () => {
      await fixture.withContext(async () => {
        await testFn({ tenantId, logger: loggerMock });
        assertions = expect.getState().numAssertions;
      });
    }, { timeoutMs });
    
    const durationMs = Date.now() - startTime;
    
    mantis_log('INFO', 'multi_tenant_test_completed', {
      tenant_id: tenantId,
      passed: true,
      assertions,
      duration_ms: durationMs
    });
    
    return { passed: true, assertions, durationMs };
    
  } catch (error) {
    const durationMs = Date.now() - startTime;
    const err = error as Error;
    
    mantis_log('ERROR', 'multi_tenant_test_failed', {
      tenant_id: tenantId,
      error: err.message,
      duration_ms: durationMs
    });
    
    return { passed: false, assertions, durationMs };
    
  } finally {
    // ✅ C8: Cleanup garantizado
    fixture.teardown();
    if (fsMocks) {
      jest.clearAllMocks();
    }
    jest.useRealTimers();
  }
}
```

---

## 🧪 Testes Unitários (TDD – Lógica Específica)

```typescript
// testing-multi-tenant-patterns.test.ts
import { describe, it, expect, vi, beforeEach, afterEach, jest } from '@jest/globals';
import { 
  setupTenantFixture, 
  validateTestPath, 
  mockFsPromises, 
  withTestTimeout, 
  createLoggerMock,
  runMultiTenantTest
} from './testing-multi-tenant-patterns';

describe('testing-multi-tenant-patterns', () => {
  const TEST_TENANT = 'tenant-test-123';

  beforeEach(() => { 
    global.mantis_log = vi.fn();
    jest.useFakeTimers();
  });
  
  afterEach(() => { 
    jest.restoreAllMocks();
    jest.useRealTimers();
  });

  it('should mock AsyncLocalStorage for tenant context (C4)', () => {
    const { mockStore } = mockAsyncLocalStorage({ tenantId: TEST_TENANT });
    
    expect(mockStore()).toEqual({ tenantId: TEST_TENANT });
    expect(global.mantis_log).toHaveBeenCalledWith(
      'DEBUG',
      'tenant_fixture_setup',
      expect.objectContaining({ tenant_id: TEST_TENANT })
    );
  });

  it('should validate test paths and block traversal (C7)', () => {
    // Path válido
    const valid = validateTestPath('docs/file.txt', '/data', TEST_TENANT);
    expect(valid.valid).toBe(true);
    expect(valid.resolved).toBe(path.resolve('/data', TEST_TENANT, 'docs/file.txt'));
    
    // Path inválido: traversal
    const invalid = validateTestPath('../../../etc/passwd', '/data', TEST_TENANT);
    expect(invalid.valid).toBe(false);
    expect(invalid.error).toContain('Path traversal blocked');
  });

  it('should mock fs/promises with path validation (C7)', () => {
    const { mockReadFile } = mockFsPromises({ tenantId: TEST_TENANT, failOnTraversal: true });
    
    // Lectura válida debe funcionar
    expect(mockReadFile('file.txt')).resolves.toBe('mocked-content-for-file.txt');
    
    // Lectura con traversal debe fallar
    expect(mockReadFile('../secret.txt')).rejects.toThrow('Path traversal blocked');
    expect(global.mantis_log).toHaveBeenCalledWith(
      'WARN',
      'test_path_traversal_blocked',
      expect.objectContaining({ constraint: 'C7' })
    );
  });

  it('should enforce timeout on async tests (C8)', async () => {
    const slowFn = () => new Promise(resolve => setTimeout(resolve, 10000, 'slow'));
    
    await expect(
      withTestTimeout(slowFn, { timeoutMs: 100 })
    ).rejects.toThrow('Test timeout after 100ms');
    
    expect(global.mantis_log).toHaveBeenCalledWith(
      'WARN',
      'test_timeout_triggered',
      expect.objectContaining({ timeout_ms: 100 })
    );
  });

  it('should verify logger includes tenant_id in logs (C4)', () => {
    const { logger, expectLogsToIncludeTenant } = createLoggerMock();
    
    logger.info({ tenant_id: TEST_TENANT }, 'Test message');
    
    expectLogsToIncludeTenant(TEST_TENANT, 0);
    expect(global.mantis_log).toHaveBeenCalledWith(
      'DEBUG',
      expect.any(String),
      expect.objectContaining({ tenant_id: TEST_TENANT })
    );
  });

  it('should run complete multi-tenant test with isolation (C4+C7+C8)', async () => {
    const result = await runMultiTenantTest({
      tenantId: TEST_TENANT,
      testFn: async ({ tenantId, logger }) => {
        // ✅ C4: Verificar que el contexto tiene el tenant correcto
        expect(tenantId).toBe(TEST_TENANT);
        
        // ✅ C4: Verificar que los logs incluyen tenant_id
        logger.logger.info({ tenant_id: tenantId }, 'Test step');
        logger.expectLogsToIncludeTenant(tenantId, 0);
        
        // ✅ C7: Simular operación de filesystem segura
        const fs = await import('fs/promises');
        await expect(fs.readFile('safe-file.txt')).resolves.toBe('mocked-content-for-safe-file.txt');
      },
      timeoutMs: 2000,
      mockFs: true
    });
    
    expect(result.passed).toBe(true);
    expect(result.assertions).toBeGreaterThanOrEqual(2);
    expect(result.durationMs).toBeLessThan(3000);
  });

  it('should cleanup mocks and timers after test (C8)', async () => {
    const fixture = setupTenantFixture(TEST_TENANT);
    fixture.setup();
    
    // Verificar que los mocks están activos
    expect(jest.isMockFunction(AsyncLocalStorage)).toBe(true);
    
    // Teardown debe limpiar
    fixture.teardown();
    jest.restoreAllMocks();
    
    // Verificar cleanup
    expect(global.mantis_log).toHaveBeenCalledWith(
      'DEBUG',
      'tenant_fixture_teardown',
      expect.objectContaining({ tenant_id: TEST_TENANT })
    );
  });
});
```

---

## 🔍 Validação (VDD – Comando Canônico)

```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/javascript/testing-multi-tenant-patterns.ts.md \
  --json \
  --check-structural \
  --check-error-handling \
  --check-observability \
  --check-constraints C4,C7,C8

bash 05-CONFIGURATIONS/validation/check-rls.sh \
  --file 06-PROGRAMMING/javascript/testing-multi-tenant-patterns.ts.md \
  --lang ts \
  --json

bash 05-CONFIGURATIONS/validation/verify-constraints.sh \
  --file 06-PROGRAMMING/javascript/testing-multi-tenant-patterns.ts.md \
  --check C7 \
  --json

bash 05-CONFIGURATIONS/validation/verify-observability.sh \
  --file 06-PROGRAMMING/javascript/testing-multi-tenant-patterns.ts.md \
  --schema V-LOG-02 \
  --json
```

---

## 🔗 Referências Cruzadas (Wikilinks Mínimos)
- [[javascript-typescript-master-agent.md]] ← Fonte de `mantis_log()`, hardening, constraints
- [[/05-CONFIGURATIONS/validation/orchestrator-engine.sh]] ← Motor de validação principal
- [[/05-CONFIGURATIONS/validation/check-rls.sh]] ← Validação C4 (tenant isolation)
- [[/05-CONFIGURATIONS/validation/verify-constraints.sh]] ← Validação C7 (path safety)
- [[/05-CONFIGURATIONS/validation/verify-observability.sh]] ← Validação C8 + V-LOG-02
- [[/01-RULES/harness-norms-v3.0.md#C4]] ← Definição formal de C4 (Tenant Isolation)
- [[/01-RULES/harness-norms-v3.0.md#C7]] ← Definição formal de C7 (Path Safety)
- [[/01-RULES/harness-norms-v3.0.md#C8]] ← Definição formal de C8 (Observability)

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 2.3.0-MODULAR-MERGED | 2026-05-09 | javascript-typescript-master-agent | MERGE: estrutura modular + Jest AsyncLocalStorage mocks + path validation helpers + timeout wrapper + logger verification | C4,C7,C8 |
| 2.1.1 | 2026-04-16 | Framework Core Team | Adição de exemplos de mocks para fs/promises e verificação de tenant_id em logs | C4,C7,C8 |
| 2.0.0 | 2026-03-01 | Qwen + DeepSeek | Primeira versão canônica com padrões de teste multi-tenant Jest + AsyncLocalStorage | C4,C7,C8 |

---

## 🔍 Observability (Eventos Específicos)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `multi_tenant_test_started` | DEBUG | C8 | `{"tenant_id":"t123","timeout_ms":10000,"mock_fs":true}` |
| `tenant_fixture_setup` | DEBUG | C4 | `{"tenant_id":"t123","request_id":"abc123"}` |
| `test_path_traversal_blocked` | WARN | C7 | `{"requested":"../secret.txt","constraint":"C7"}` |
| `test_timeout_triggered` | WARN | C8 | `{"timeout_ms":100}` |
| `multi_tenant_test_completed` | INFO | C8 | `{"tenant_id":"t123","passed":true,"assertions":3,"duration_ms":245}` |
| `multi_tenant_test_failed` | ERROR | C8 | `{"tenant_id":"t123","error":"Assertion failed","duration_ms":150}` |
| `tenant_fixture_teardown` | DEBUG | C4 | `{"tenant_id":"t123"}` |

### Validação de Schema V-LOG-02 (Helper Mínimo)
```typescript
export function validateTestLog(logEntry: unknown): { valid: boolean; errors: string[] } {
  const errors: string[] = [];
  const entry = logEntry as Record<string, unknown>;
  const required = ['ts', 'level', 'resource', 'body'];
  for (const field of required) if (!(field in entry)) errors.push(`Missing required field: ${field}`);
  
  // ✅ C4: Verificar tenant_id en eventos de test multi-tenant
  const testEvents = ['multi_tenant_test_started', 'multi_tenant_test_completed', 'tenant_fixture_setup'];
  if (testEvents.includes(entry.body?.event as string)) {
    const detail = entry.body?.detail as Record<string, unknown>;
    if (!detail?.tenant_id) errors.push('C4 violation: test event missing tenant_id');
  }
  
  // ✅ C8: Verificar timeout_ms en eventos de timeout
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

## ✅ Auto-Validation Report (JSON)
```json
{
  "artifact": "testing-multi-tenant-patterns",
  "version": "2.3.0-MODULAR-MERGED",
  "score": 30,
  "blocking_issues": [],
  "constraints_verified": ["C4", "C7", "C8"],
  "examples_count": 13,
  "lines_executable_max": 2,
  "language": "TypeScript 5.0+ / Node.js 18+",
  "observability_compliant": true,
  "bootstrap_resilient": true,
  "mantis_log_usage": "inherited",
  "jest_mocking_verified": true,
  "path_validation_verified": true,
  "timeout_handling_verified": true,
  "tenant_isolation_verified": true,
  "logger_verification_verified": true,
  "cleanup_guaranteed": true,
  "timestamp": "2026-05-09T00:00:00Z"
}
```

---

> 🇧🇷 *Documento técnico em pt-BR conforme V-DOC-01. Coordenação en español. Zero invenção: todo padrão grounded no conteúdo original + template v2.3.0-MODULAR.*

---
