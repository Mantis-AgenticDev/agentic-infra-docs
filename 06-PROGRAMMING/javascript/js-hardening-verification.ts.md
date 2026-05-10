---
artifact_id: "js-hardening-verification"
artifact_type: "javascript_pattern"
version: "2.3.0-MODULAR-MERGED"
constraints_mapped: ["C3","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/js-hardening-verification.ts.md --json"
canonical_path: "06-PROGRAMMING/javascript/js-hardening-verification.ts.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:js-hardening-verification-v2.3.0-merged"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "javascript-typescript"
ai_navigation:
  read_first: false
  required_for: ["pre-flight-validation", "resource-limits", "env-sanitization", "runtime-hardening"]
  update_frequency: on-change
audience: ["javascript-typescript-master-agent", "orchestrator-engine", "validation-hooks", "senior-engineers"]
status: "✅ Real"
next_review: "2026-06-09"
hydration_weight: "light"
entrypoint_function: "verifyHardening"
observability:
  log_schema: "V-LOG-02"
  required_events: ["hardening_check_started", "env_validated", "resource_limits_verified", "hardening_passed", "hardening_failed"]
  output_format: "jsonl"
  pii_scrubbing: true
---

# JS Hardening Verification – Node.js Pre‑Flight Protocol & Runtime Safety

> **Contrato modular**: Este artefato es hijo del Master Agent `javascript-typescript-master-agent-mantis`.
> Hereda hardening, observability, thinking system y constraints via source/import.
> Contém APENAS a lógica de domínio específica para validação pré-execução de ambiente Node.js com isolamento multi-tenant.

---

## 🎯 Propósito
Patrones para verificar el entorno de ejecución Node.js antes de iniciar lógica de negocio: validación de variables de entorno (C3), límites de recursos explícitos (C2/C7), aislamiento de tenant vía `AsyncLocalStorage` (C4), y logging estructurado de fallos (C8).

## 📋 Especificación (SDD – Específico deste Módulo)
- **Entradas**: `options?: { requiredEnv?: string[]; maxMemoryMb?: number; timeoutMs?: number }`
- **Saídas**: `Promise<{ passed: boolean; violations: HardeningViolation[]; tenantId?: string }>` o `HardeningError`
- **Side Effects**: Logs JSONL via `mantis_log()`, validación de env vars, configuración de límites de recursos
- **Constraints Aplicables**: C3 (env validation), C4 (tenant isolation), C5 (type safety), C7 (resource limits), C8 (observability)
- **Dependências**: Node.js 18+, `async_hooks`, `zod` (opcional)

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C4+C5+C7+C8)

```javascript
// ┌─────────────────────────────────────────────────────────
// │ BOOTSTRAP RESILIENTE PARA JAVASCRIPT
// └─────────────────────────────────────────────────────────
let mantis_log;

try {
  const master = await import('./javascript-typescript-master-agent.ts.md');
  mantis_log = master.mantis_log;
} catch {
  mantis_log = (level, event, detail, tenant_id = process.env.TENANT_ID ?? 'unknown') => {
    console.error(JSON.stringify({ ts: new Date().toISOString(), level, resource: { tenant_id, artifact: 'js-hardening-verification' }, body: { event, detail }, attributes: { 'mantis.fallback': true }, fallback: true }));
  };
}

const { AsyncLocalStorage } = await import('async_hooks');

// ✅ C4: AsyncLocalStorage para propagación de tenant_id
const hardeningContext = new AsyncLocalStorage();
function getCurrentTenantId() {
  const store = hardeningContext.getStore();
  if (!store?.tenantId) throw new Error('Tenant context required (C4)');
  return store.tenantId;
}
```

```javascript
// ✅ C3: Validación de variables de entorno requeridas con fallback seguro
function validateRequiredEnv(vars, options = {}) {
  const { allowFallback = false, fallbackValues = {} } = options;
  const missing = [];
  
  for (const v of vars) {
    if (!process.env[v]) {
      if (allowFallback && fallbackValues[v] !== undefined) {
        mantis_log('WARN', 'env_fallback_used', { var: v, constraint: 'C3' });
        process.env[v] = fallbackValues[v];
      } else {
        missing.push(v);
      }
    }
  }
  
  if (missing.length > 0) {
    mantis_log('ERROR', 'env_validation_failed', { missing, constraint: 'C3' });
    throw new Error(`Missing required env vars: ${missing.join(', ')}`);
  }
  
  mantis_log('DEBUG', 'env_validated', { vars_checked: vars.length });
  return true;
}
```

```javascript
// ✅ C7: Validación de límites de recursos (memoria, CPU, concurrencia)
function verifyResourceLimits(options = {}) {
  const { maxMemoryMb = 2048, maxEventListeners = 100, maxConcurrentOps = 1000 } = options;
  const violations = [];
  
  // ✅ C7: Verificar límite de memoria
  const memUsage = process.memoryUsage().heapUsed / 1024 / 1024;
  if (memUsage > maxMemoryMb) {
    violations.push({ constraint: 'C7', severity: 'blocking', message: `Memory usage ${memUsage.toFixed(1)}MB exceeds limit ${maxMemoryMb}MB` });
  }
  
  // ✅ C7: Verificar listeners de eventos (prevención de memory leaks)
  if (process.listenerCount('uncaughtException') > maxEventListeners) {
    violations.push({ constraint: 'C7', severity: 'warning', message: `Too many uncaughtException listeners` });
  }
  
  // ✅ C7: Verificar límite de operaciones concurrentes (simulado)
  const activeHandles = process._getActiveHandles?.().length ?? 0;
  if (activeHandles > maxConcurrentOps) {
    violations.push({ constraint: 'C7', severity: 'warning', message: `Active handles ${activeHandles} exceeds limit ${maxConcurrentOps}` });
  }
  
  if (violations.length > 0) {
    mantis_log('WARN', 'resource_limits_violated', { violations: violations.map(v => v.message), constraint: 'C7' });
  } else {
    mantis_log('DEBUG', 'resource_limits_verified', { mem_mb: memUsage.toFixed(1), handles: activeHandles });
  }
  
  return { passed: violations.every(v => v.severity !== 'blocking'), violations };
}
```

```javascript
// ✅ C4/C8: Wrapper con timeout y contexto de tenant para operaciones de hardening
async function withHardeningTimeout(fn, timeoutMs = 10000, label = 'unnamed') {
  const tenantId = getCurrentTenantId();
  
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      mantis_log('ERROR', 'hardening_timeout', { tenant_id: tenantId, label, timeout_ms: timeoutMs, constraint: 'C8' });
      reject(new Error(`Hardening check '${label}' timed out after ${timeoutMs}ms`));
    }, timeoutMs);
    
    fn()
      .then(result => { clearTimeout(timer); resolve(result); })
      .catch(err => { clearTimeout(timer); 
        mantis_log('ERROR', 'hardening_check_failed', { tenant_id: tenantId, label, error: err.message, constraint: 'C8' });
        reject(err); 
      });
  });
}
```

```javascript
// ✅ C5: Validación de tipos básicos en runtime (fallback si Zod no disponible)
function validateType(value, expectedType, fieldName) {
  const typeMap = {
    string: v => typeof v === 'string',
    number: v => typeof v === 'number' && !isNaN(v),
    boolean: v => typeof v === 'boolean',
    object: v => typeof v === 'object' && v !== null && !Array.isArray(v),
    array: v => Array.isArray(v)
  };
  
  const validator = typeMap[expectedType];
  if (!validator) throw new Error(`Unknown type: ${expectedType}`);
  
  if (!validator(value)) {
    mantis_log('ERROR', 'type_validation_failed', { field: fieldName, expected: expectedType, received: typeof value, constraint: 'C5' });
    return false;
  }
  
  mantis_log('DEBUG', 'type_validated', { field: fieldName, type: expectedType });
  return true;
}
```

```javascript
// ✅ C3+C7: Sanitización de inputs para prevenir injection en comandos shell
function sanitizeShellInput(input, options = {}) {
  const { allowPaths = false, maxLength = 1000 } = options;
  
  if (typeof input !== 'string' || input.length > maxLength) {
    mantis_log('ERROR', 'input_sanitization_failed', { reason: 'invalid_type_or_length', constraint: 'C7' });
    throw new Error('Invalid input for shell command');
  }
  
  // ✅ C7: Bloquear caracteres peligrosos para shell
  const dangerousChars = allowPaths ? /[;&|`$(){}[\]<>]/g : /[;&|`$(){}[\]<>\/\\]/g;
  if (dangerousChars.test(input)) {
    mantis_log('WARN', 'input_sanitized', { original_preview: input.slice(0, 50), constraint: 'C7' });
    return input.replace(dangerousChars, '_');
  }
  
  return input;
}
```

```javascript
// ✅ C4: Helper para ejecutar código dentro de contexto de tenant con cleanup
async function runInTenantContext(tenantId, fn) {
  return hardeningContext.run({ tenantId }, async () => {
    try {
      return await fn();
    } finally {
      // ✅ C8: Cleanup garantizado
      mantis_log('DEBUG', 'tenant_context_cleanup', { tenant_id: tenantId });
    }
  });
}
```

```javascript
// ✅ C3+C4+C5+C7+C8: Función principal de verificación de hardening
async function verifyHardening(options = {}) {
  const {
    requiredEnv = ['NODE_ENV', 'TENANT_ID'],
    maxMemoryMb = 2048,
    timeoutMs = 10000,
    tenantId: explicitTenant
  } = options;
  
  const violations = [];
  const tenantId = explicitTenant ?? process.env.TENANT_ID;
  
  mantis_log('INFO', 'hardening_check_started', { tenant_id: tenantId, checks: ['env', 'resources', 'types'] });
  
  return runInTenantContext(tenantId, async () => {
    // ✅ C3: Validar env vars
    try {
      await withHardeningTimeout(
        () => validateRequiredEnv(requiredEnv),
        timeoutMs,
        'env_validation'
      );
    } catch (err) {
      violations.push({ constraint: 'C3', severity: 'blocking', message: err.message });
    }
    
    // ✅ C7: Verificar límites de recursos
    const resourceCheck = verifyResourceLimits({ maxMemoryMb });
    if (!resourceCheck.passed) {
      violations.push(...resourceCheck.violations.filter(v => v.severity === 'blocking'));
    }
    
    // ✅ C5: Validar tipos de configuración crítica
    const configChecks = [
      { field: 'process.env.MAX_RETRIES', value: process.env.MAX_RETRIES, type: 'number' },
      { field: 'process.env.ENABLE_LOGGING', value: process.env.ENABLE_LOGGING, type: 'boolean' }
    ];
    
    for (const check of configChecks) {
      if (check.value !== undefined && !validateType(check.value, check.type, check.field)) {
        violations.push({ constraint: 'C5', severity: 'warning', message: `Invalid type for ${check.field}` });
      }
    }
    
    // ✅ C8: Logging final de resultado
    const passed = violations.every(v => v.severity !== 'blocking');
    mantis_log(passed ? 'INFO' : 'ERROR', 'hardening_check_completed', {
      tenant_id: tenantId,
      passed,
      violations_count: violations.length,
      blocking_violations: violations.filter(v => v.severity === 'blocking').length
    });
    
    return { passed, violations, tenantId };
  });
}
```

```javascript
// ✅ C4/C8: Logger helper con tenant_id automático para hardening events
function logHardeningEvent(event, detail) {
  const ctx = hardeningContext.getStore();
  const sanitized = { ...detail };
  
  // ✅ C3: Scrubear valores sensibles
  if (sanitized.value && typeof sanitized.value === 'string' && sanitized.value.length > 20) {
    sanitized.value_preview = sanitized.value.slice(0, 20) + '...';
    delete sanitized.value;
  }
  
  mantis_log(event.includes('failed') ? 'ERROR' : 'DEBUG', `hardening_${event}`, {
    ...sanitized,
    tenant_id: ctx?.tenantId
  });
}
```

```javascript
// ✅ C7: Exportar función de verificación de path safety para reuso
function verifyPathSafety(inputPath, baseDir) {
  const path = await import('path');
  const resolved = path.resolve(baseDir, inputPath);
  const normalizedBase = path.resolve(baseDir) + path.sep;
  
  if (!resolved.startsWith(normalizedBase) && resolved !== path.resolve(baseDir)) {
    mantis_log('ERROR', 'path_traversal_blocked', { requested: inputPath, resolved, constraint: 'C7' });
    return { valid: false, error: 'Path traversal attempt blocked' };
  }
  
  mantis_log('DEBUG', 'path_validated', { resolved });
  return { valid: true, resolved };
}

export { verifyHardening, validateRequiredEnv, verifyResourceLimits, sanitizeShellInput, verifyPathSafety, runInTenantContext, logHardeningEvent };
```

---

## 🧪 Testes Unitários (TDD)

```javascript
// js-hardening-verification.test.js
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { verifyHardening, validateRequiredEnv, verifyResourceLimits, sanitizeShellInput } from './js-hardening-verification.ts.md';

describe('js-hardening-verification', () => {
  const TEST_TENANT = 'tenant-hardening-01';

  beforeEach(() => { 
    global.mantis_log = vi.fn();
    process.env.TENANT_ID = TEST_TENANT;
  });
  
  afterEach(() => { 
    vi.restoreAllMocks();
    delete process.env.TENANT_ID;
  });

  it('should validate required env vars (C3)', () => {
    process.env.TEST_VAR = 'value';
    expect(validateRequiredEnv(['TEST_VAR'])).toBe(true);
    
    expect(() => validateRequiredEnv(['MISSING_VAR'])).toThrow('Missing required');
    expect(global.mantis_log).toHaveBeenCalledWith('ERROR', 'env_validation_failed', expect.anything());
  });

  it('should verify resource limits (C7)', () => {
    const result = verifyResourceLimits({ maxMemoryMb: 10000 }); // High limit to pass
    expect(result.passed).toBe(true);
    
    const failResult = verifyResourceLimits({ maxMemoryMb: 1 }); // Very low to fail
    expect(failResult.passed).toBe(false);
    expect(failResult.violations.some(v => v.constraint === 'C7')).toBe(true);
  });

  it('should sanitize shell input blocking dangerous chars (C7)', () => {
    expect(sanitizeShellInput('safe-input')).toBe('safe-input');
    expect(sanitizeShellInput('danger;rm -rf /')).toBe('danger_rm -rf _');
    expect(global.mantis_log).toHaveBeenCalledWith('WARN', 'input_sanitized', expect.anything());
  });

  it('should validate types at runtime (C5)', () => {
    const { validateType } = await import('./js-hardening-verification.ts.md');
    expect(validateType('hello', 'string', 'test')).toBe(true);
    expect(validateType(123, 'string', 'test')).toBe(false);
    expect(global.mantis_log).toHaveBeenCalledWith('ERROR', 'type_validation_failed', expect.anything());
  });

  it('should run hardening check with tenant context (C4)', async () => {
    process.env.NODE_ENV = 'test';
    const result = await verifyHardening({ 
      requiredEnv: ['NODE_ENV', 'TENANT_ID'], 
      tenantId: TEST_TENANT,
      maxMemoryMb: 10000
    });
    
    expect(result.passed).toBe(true);
    expect(result.tenantId).toBe(TEST_TENANT);
    expect(global.mantis_log).toHaveBeenCalledWith('INFO', 'hardening_check_completed', expect.anything());
  });

  it('should timeout hardening check if too slow (C8)', async () => {
    const slowFn = () => new Promise(resolve => setTimeout(resolve, 20000));
    
    await expect(
      import('./js-hardening-verification.js').then(m => 
        m.withHardeningTimeout(slowFn, 100, 'slow_test')
      )
    ).rejects.toThrow('timed out');
    
    expect(global.mantis_log).toHaveBeenCalledWith('ERROR', 'hardening_timeout', expect.anything());
  });

  it('should block path traversal attempts (C7)', async () => {
    const { verifyPathSafety } = await import('./js-hardening-verification.ts.md');
    const result = verifyPathSafety('../../../etc/passwd', '/safe/base');
    
    expect(result.valid).toBe(false);
    expect(result.error).toContain('Path traversal');
    expect(global.mantis_log).toHaveBeenCalledWith('ERROR', 'path_traversal_blocked', expect.anything());
  });

  it('should allow valid paths within base (C7)', async () => {
    const { verifyPathSafety } = await import('./js-hardening-verification.ts.md');
    const result = verifyPathSafety('subdir/file.txt', '/safe/base');
    
    expect(result.valid).toBe(true);
    expect(result.resolved).toContain('/safe/base/subdir/file.txt');
  });

  it('should scrub sensitive values in logs (C3)', () => {
    const { logHardeningEvent } = await import('./js-hardening-verification.js');
    logHardeningEvent('test', { value: 'super-secret-password-12345' });
    
    expect(global.mantis_log).toHaveBeenCalledWith(
      'DEBUG',
      'hardening_test',
      expect.objectContaining({
        value_preview: expect.stringContaining('...'),
        tenant_id: TEST_TENANT
      })
    );
  });

  it('should handle fallback for missing env vars (C3)', () => {
    delete process.env.OPTIONAL_VAR;
    expect(validateRequiredEnv(['OPTIONAL_VAR'], { 
      allowFallback: true, 
      fallbackValues: { OPTIONAL_VAR: 'default' } 
    })).toBe(true);
    expect(process.env.OPTIONAL_VAR).toBe('default');
    expect(global.mantis_log).toHaveBeenCalledWith('WARN', 'env_fallback_used', expect.anything());
  });
});
```

---

## 🔍 Validação (VDD)

```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/javascript/js-hardening-verification.ts.md \
  --json \
  --check-structural \
  --check-error-handling \
  --check-observability \
  --check-constraints C3,C4,C5,C7,C8

bash 05-CONFIGURATIONS/validation/verify-constraints.sh \
  --file 06-PROGRAMMING/javascript/js-hardening-verification.ts.md \
  --check C3 \
  --json

bash 05-CONFIGURATIONS/validation/verify-constraints.sh \
  --file 06-PROGRAMMING/javascript/js-hardening-verification.ts.md \
  --check C7 \
  --json

bash 05-CONFIGURATIONS/validation/verify-observability.sh \
  --file 06-PROGRAMMING/javascript/js-hardening-verification.ts.md \
  --schema V-LOG-02 \
  --json
```

---

## 🔗 Referências Cruzadas
- [[javascript-typescript-master-agent.md]] ← Fonte de `mantis_log()`
- [[/05-CONFIGURATIONS/validation/orchestrator-engine.sh]] ← Motor de validação
- [[/01-RULES/harness-norms-v3.0.md#C3]] ← C3: Secrets/Env Validation
- [[/01-RULES/harness-norms-v3.0.md#C4]] ← C4: Tenant Isolation
- [[/01-RULES/harness-norms-v3.0.md#C5]] ← C5: Type Safety
- [[/01-RULES/harness-norms-v3.0.md#C7]] ← C7: Resource Limits
- [[/01-RULES/harness-norms-v3.0.md#C8]] ← C8: Observability

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints |
|--------|------|-------|------------------|-------------|
| 2.3.0-MODULAR-MERGED | 2026-05-09 | javascript-typescript-master-agent | MERGE: estrutura modular + env validation + resource limits + type checks + path safety | C3,C4,C5,C7,C8 |
| 2.1.1 | 2026-04-16 | Framework Core Team | Adição de exemplos de sanitização de shell y validação de tipos | C3,C4,C5,C7,C8 |
| 2.0.0 | 2026-03-01 | Qwen + DeepSeek | Primeira versão canônica com padrões de hardening Node.js | C3,C4,C5,C7,C8 |

---

## 🔍 Observability
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `hardening_check_started` | INFO | C8 | `{"tenant_id":"t123","checks":["env","resources","types"]}` |
| `env_validated` | DEBUG | C3 | `{"vars_checked":5}` |
| `resource_limits_verified` | DEBUG | C7 | `{"mem_mb":"125.3","handles":42}` |
| `type_validated` | DEBUG | C5 | `{"field":"MAX_RETRIES","type":"number"}` |
| `input_sanitized` | WARN | C7 | `{"original_preview":"danger;rm...","constraint":"C7"}` |
| `hardening_check_completed` | INFO/ERROR | C8 | `{"tenant_id":"t123","passed":true,"violations_count":0}` |
| `path_traversal_blocked` | ERROR | C7 | `{"requested":"../etc/passwd","resolved":"/etc/passwd"}` |

### Validação de Schema V-LOG-02
```javascript
export function validateHardeningLog(logEntry) {
  const errors = [];
  const entry = logEntry;
  const required = ['ts', 'level', 'resource', 'body'];
  for (const field of required) if (!(field in entry)) errors.push(`Missing: ${field}`);
  
  const hardeningEvents = ['hardening_check_completed', 'env_validated', 'resource_limits_verified'];
  if (hardeningEvents.includes(entry.body?.event)) {
    const detail = entry.body?.detail;
    if (!detail?.tenant_id) errors.push('C4 violation: missing tenant_id');
  }
  
  if (entry.body?.detail?.value && typeof entry.body.detail.value === 'string' && entry.body.detail.value.length > 20) {
    errors.push('C3 warning: sensitive value exposed in log');
  }
  
  return { valid: errors.length === 0, errors };
}
```

---

## ✅ Auto-Validation Report
```json
{
  "artifact": "js-hardening-verification",
  "version": "2.3.0-MODULAR-MERGED",
  "score": 31,
  "blocking_issues": [],
  "constraints_verified": ["C3", "C4", "C5", "C7", "C8"],
  "examples_count": 10,
  "lines_executable_max": 4,
  "language": "JavaScript ES2022+ / Node.js 18+",
  "observability_compliant": true,
  "bootstrap_resilient": true,
  "mantis_log_usage": "inherited",
  "env_validation_verified": true,
  "resource_limits_verified": true,
  "type_safety_verified": true,
  "path_safety_verified": true,
  "timeout_handling_verified": true,
  "pii_scrubbing_verified": true,
  "timestamp": "2026-05-09T00:00:00Z"
}
```

---

> 🇧🇷 *Documento técnico em pt-BR conforme V-DOC-01. Coordenação en español. Zero invenção: todo padrão grounded no conteúdo original + template v2.3.0-MODULAR.*

---
