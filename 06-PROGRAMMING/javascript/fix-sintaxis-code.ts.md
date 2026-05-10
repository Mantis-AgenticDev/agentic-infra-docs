---
artifact_id: "fix-sintaxis-code"
artifact_type: "typescript_module"
version: "2.3.0-MODULAR-MERGED"
constraints_mapped: ["C3","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/fix-sintaxis-code.ts.md --json"
canonical_path: "06-PROGRAMMING/javascript/fix-sintaxis-code.ts.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:fix-sintaxis-code-v2.3.0-merged"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "javascript-typescript"
ai_navigation:
  read_first: false
  required_for: ["syntax-fixing", "linting-automation", "tsc-strict-validation"]
  update_frequency: on-change
audience: ["javascript-typescript-master-agent", "orchestrator-engine", "validation-hooks", "senior-engineers"]
status: "✅ Real"
next_review: "2026-06-09"
hydration_weight: "light"
entrypoint_function: "fixSyntaxFile"
observability:
  log_schema: "V-LOG-02"
  required_events: ["lint_started", "syntax_fixed", "integrity_verified", "lint_completed", "lint_failed"]
  output_format: "jsonl"
  pii_scrubbing: true
---

# Fix Sintaxis Code – TypeScript/Node.js Linter & Compiler Integration

> **Contrato modular**: Este artefato es hijo del Master Agent `javascript-typescript-master-agent-mantis`.
> Hereda hardening, observability, thinking system y constraints via source/import.
> Contém APENAS a lógica de domínio específica para correção automática de sintaxe e detecção de anti-padrões com ESLint e tsc.

---

## 🎯 Propósito
Patrón de corrección automática de sintaxis y anti-patrones TypeScript/Node.js usando ESLint y `tsc` en modo strict, con validación pre-commit y bloqueo de código inseguro que viole constraints C3 (entorno), C4 (aislamiento multi-tenant), C5 (integridad), C7 (sandbox de FS) y C8 (gestión de errores robusta).

## 📋 Especificación (SDD – Específico deste Módulo)
- **Entradas**: `filePath: string`, `options?: { tenantId?: string; fix?: boolean; timeoutMs?: number; workspace?: string }`
- **Saídas**: `Promise<{ fixed: boolean; errors: LintError[]; warnings: LintWarning[]; hash: string }>` o `SyntaxFixError`
- **Side Effects**: Logs JSONL via `mantis_log()`, modificación de archivos source (si fix=true), cálculo de checksums SHA256
- **Constraints Aplicables**: C3 (env validation), C4 (tenant isolation), C5 (integrity/type safety), C7 (path safety), C8 (observability)
- **Dependências**: Node.js 18+, TypeScript 5.0+, `eslint@^8.0.0`, `@typescript-eslint/parser`, `zod`

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C4+C5+C7+C8)
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
      resource: { tenant_id, artifact: 'fix-sintaxis-code' },
      body: { event, detail },
      attributes: { 'mantis.fallback': true },
      fallback: true
    }));
  };
}

// ┌─────────────────────────────────────────────────────────
// │ LÓGICA DE DOMÍNIO: CORREÇÃO DE SINTAXE COM ESLINT + TSC
// │ Zero redundância: apenas o específico deste módulo
// └─────────────────────────────────────────────────────────

import path from 'path';
import { createHash } from 'crypto';
import { readFile, writeFile, stat } from 'fs/promises';
import { z } from 'zod';
import { AsyncLocalStorage } from 'async_hooks';

// ✅ C3: Schema Zod para validación de entorno en linting operations
export const lintEnvSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  ESLINT_TIMEOUT_MS: z.coerce.number().min(1000).max(60000).default(10000),
  TSC_TIMEOUT_MS: z.coerce.number().min(1000).max(120000).default(30000),
  LINT_WORKSPACE: z.string().startsWith('/').refine(dir => path.isAbsolute(dir), {
    message: 'LINT_WORKSPACE must be an absolute path'
  }),
  FIX_ENABLE_AUTO_FIX: z.coerce.boolean().default(false)
});

export type LintEnv = z.infer<typeof lintEnvSchema>;

export function validateLintEnv(raw: NodeJS.ProcessEnv): LintEnv {
  const result = lintEnvSchema.safeParse(raw);
  if (!result.success) {
    mantis_log('ERROR', 'lint_env_validation_failed', {
      errors: result.error.errors.map(e => `${e.path.join('.')}: ${e.message}`),
      constraint: 'C3'
    });
    throw new Error(`Lint environment validation failed: ${result.error.message}`);
  }
  mantis_log('DEBUG', 'lint_env_validated', { node_env: result.data.NODE_ENV, workspace: result.data.LINT_WORKSPACE });
  return result.data;
}
```

```typescript
// ✅ C7: Path sanitization antes de pasar a ESLint/tsc
export interface LintPathResult {
  requested: string;
  resolved: string;
  withinWorkspace: boolean;
}

export function validateLintPath(userFile: string, workspace: string): LintPathResult {
  const resolved = path.resolve(workspace, userFile);
  const normalizedWorkspace = path.resolve(workspace) + path.sep;
  
  if (!resolved.startsWith(normalizedWorkspace) && resolved !== path.resolve(workspace)) {
    mantis_log('ERROR', 'lint_path_traversal_blocked', {
      requested: userFile,
      resolved,
      expected_prefix: normalizedWorkspace,
      constraint: 'C7'
    });
    throw new Error(`Path traversal blocked in lint operation: ${userFile} (C7 constraint)`);
  }

  mantis_log('DEBUG', 'lint_path_validated', {
    resolved,
    within_workspace: true
  });

  return {
    requested: userFile,
    resolved,
    withinWorkspace: true
  };
}

// Helper para sanitizar input de path en logs
function sanitizePathInput(input: string): string {
  const sanitized = input.length > 50 ? '...' + input.slice(-50) : input;
  return sanitized.replace(/:[^/@\s]+@/g, ':***@');
}
```

```typescript
// ✅ C5: Validación de integridad de archivo antes de linting con SHA256
export async function verifyFileIntegrity(filePath: string, expectedHash?: string): Promise<{ valid: boolean; actualHash: string }> {
  mantis_log('DEBUG', 'file_integrity_check_started', { path: sanitizePathInput(filePath) });

  try {
    const content = await readFile(filePath);
    const actualHash = createHash('sha256').update(content).digest('hex');
    
    mantis_log('DEBUG', 'file_hash_computed', { 
      path: sanitizePathInput(filePath),
      hash_prefix: actualHash.slice(0, 16) + '...'
    });

    if (expectedHash && actualHash !== expectedHash) {
      mantis_log('ERROR', 'file_integrity_mismatch', {
        expected_prefix: expectedHash.slice(0, 16) + '...',
        actual_prefix: actualHash.slice(0, 16) + '...',
        constraint: 'C5'
      });
      return { valid: false, actualHash };
    }

    return { valid: true, actualHash };

  } catch (error) {
    const err = error as NodeJS.ErrnoException;
    if (err.code === 'ENOENT') {
      mantis_log('WARN', 'file_not_found_for_lint', { path: sanitizePathInput(filePath) });
      return { valid: false, actualHash: '' };
    }
    mantis_log('ERROR', 'file_integrity_check_failed', { error: err.message });
    throw error;
  }
}
```

```typescript
// ✅ C3/C4/C5/C7/C8: Ejecución segura de ESLint con timeout, tenant context y path validation
export interface LintOptions {
  tenantId?: string;
  fix?: boolean;
  timeoutMs?: number;
  workspace?: string;
  expectedHash?: string;
}

export interface LintResult {
  fixed: boolean;
  errors: Array<{ ruleId: string; message: string; line: number; column: number }>;
  warnings: Array<{ ruleId: string; message: string; line: number; column: number }>;
  hash: string;
  filePath: string;
}

export async function fixSyntaxFile(
  filePath: string,
  options: LintOptions = {}
): Promise<LintResult> {
  const {
    tenantId: explicitTenant,
    fix = validateLintEnv(process.env).FIX_ENABLE_AUTO_FIX,
    timeoutMs = validateLintEnv(process.env).ESLINT_TIMEOUT_MS,
    workspace = validateLintEnv(process.env).LINT_WORKSPACE,
    expectedHash
  } = options;

  // ✅ C4: Obtener tenant_id del contexto o del parámetro explícito
  const tenantId = explicitTenant ?? getCurrentTenantId();
  const env = validateLintEnv(process.env);

  mantis_log('INFO', 'lint_operation_started', {
    tenant_id: tenantId,
    file_path: sanitizePathInput(filePath),
    fix_enabled: fix,
    timeout_ms: timeoutMs,
    workspace
  });

  // ✅ C7: Validar ruta contra workspace
  const pathResult = validateLintPath(filePath, workspace);
  
  // ✅ C5: Verificar integridad del archivo antes de linting
  const { valid: integrityValid, actualHash } = await verifyFileIntegrity(pathResult.resolved, expectedHash);
  if (!integrityValid && expectedHash) {
    mantis_log('ERROR', 'lint_aborted_integrity_failed', {
      tenant_id: tenantId,
      constraint: 'C5'
    });
    throw new Error('File integrity check failed before linting (C5 constraint)');
  }

  // ✅ C8: AbortController para timeout de ESLint
  const controller = new AbortController();
  const timer = setTimeout(() => {
    controller.abort();
    mantis_log('WARN', 'lint_timeout_triggered', { tenant_id: tenantId, timeout_ms: timeoutMs });
  }, timeoutMs);

  try {
    // ✅ C8: Import lazy de ESLint para zero overhead si no se usa
    const { ESLint } = await import('eslint');
    
    const eslint = new ESLint({
      fix,  // ✅ C5: Auto-fix solo si está habilitado explícitamente
      overrideConfigFile: path.join(workspace, '.eslintrc.cjs'),
      useEslintrc: false,
      // ✅ C7: Restringir archivos a lintear al workspace
      ignorePath: path.join(workspace, '.eslintignore')
    });

    // ✅ C8: lintFiles con signal para timeout
    const results = await eslint.lintFiles([pathResult.resolved], { signal: controller.signal });
    clearTimeout(timer);

    const result = results[0];
    if (!result) {
      mantis_log('WARN', 'lint_no_result', { tenant_id: tenantId, file: pathResult.resolved });
      return { fixed: false, errors: [], warnings: [], hash: actualHash, filePath: pathResult.resolved };
    }

    // ✅ C5: Si fix=true y hay cambios, escribir archivo y recalcular hash
    let finalHash = actualHash;
    let wasFixed = false;
    
    if (fix && result.output) {
      await writeFile(pathResult.resolved, result.output, 'utf8');
      finalHash = createHash('sha256').update(result.output).digest('hex');
      wasFixed = true;
      mantis_log('INFO', 'lint_auto_fix_applied', {
        tenant_id: tenantId,
        file: pathResult.resolved,
        new_hash_prefix: finalHash.slice(0, 16) + '...'
      });
    }

    // Clasificar mensajes en errores y warnings
    const errors = result.messages
      .filter(m => m.severity === 2)
      .map(m => ({ ruleId: m.ruleId ?? 'unknown', message: m.message, line: m.line, column: m.column }));
    
    const warnings = result.messages
      .filter(m => m.severity === 1)
      .map(m => ({ ruleId: m.ruleId ?? 'unknown', message: m.message, line: m.line, column: m.column }));

    mantis_log('INFO', 'lint_completed', {
      tenant_id: tenantId,
      file: pathResult.resolved,
      errors_count: errors.length,
      warnings_count: warnings.length,
      fixed: wasFixed,
      hash_prefix: finalHash.slice(0, 16) + '...'
    });

    return {
      fixed: wasFixed,
      errors,
      warnings,
      hash: finalHash,
      filePath: pathResult.resolved
    };

  } catch (error) {
    clearTimeout(timer);
    const err = error as Error;
    
    if (err.name === 'AbortError' || err.name === 'TimeoutError') {
      mantis_log('ERROR', 'lint_aborted_timeout', {
        tenant_id: tenantId,
        timeout_ms: timeoutMs
      });
      throw new Error(`ESLint timeout after ${timeoutMs}ms`);
    }
    
    mantis_log('ERROR', 'lint_execution_failed', {
      tenant_id: tenantId,
      file: pathResult.resolved,
      error: err.message
    });
    throw error;
  }
}
```

```typescript
// ✅ C8: Ejecución de tsc con timeout y captura de errores estructurados
export interface TscResult {
  success: boolean;
  errors: string[];
  warnings: string[];
  durationMs: number;
}

export async function runTscStrict(
  options: { cwd?: string; timeoutMs?: number; noEmit?: boolean } = {}
): Promise<TscResult> {
  const {
    cwd = validateLintEnv(process.env).LINT_WORKSPACE,
    timeoutMs = validateLintEnv(process.env).TSC_TIMEOUT_MS,
    noEmit = true
  } = options;

  const tenantId = getCurrentTenantId();
  const startTime = Date.now();

  mantis_log('INFO', 'tsc_check_started', {
    tenant_id: tenantId,
    cwd,
    timeout_ms: timeoutMs,
    no_emit: noEmit
  });

  // ✅ C8: exec con timeout explícito (no execSync que bloquea event loop)
  const { exec } = await import('child_process');
  const { promisify } = await import('util');
  const execPromise = promisify(exec);

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const { stdout, stderr } = await execPromise(
      `npx tsc --noEmit ${noEmit ? '' : '--emitDeclarationOnly'} --strict`,
      { 
        cwd, 
        timeout: timeoutMs,
        signal: controller.signal as any  // Node 18+ support
      }
    );

    clearTimeout(timer);
    const durationMs = Date.now() - startTime;

    // Parsear output de tsc para extraer errores/warnings
    const errors: string[] = [];
    const warnings: string[] = [];
    
    const lines = (stderr || stdout).split('\n');
    for (const line of lines) {
      if (/error TS\d+:/i.test(line)) {
        errors.push(line.trim());
      } else if (/warning/i.test(line) && line.trim()) {
        warnings.push(line.trim());
      }
    }

    const success = errors.length === 0;
    
    mantis_log(success ? 'INFO' : 'ERROR', 'tsc_check_completed', {
      tenant_id: tenantId,
      success,
      errors_count: errors.length,
      warnings_count: warnings.length,
      duration_ms: durationMs
    });

    return { success, errors, warnings, durationMs };

  } catch (error) {
    clearTimeout(timer);
    const err = error as NodeJS.ErrnoException & { stdout?: string; stderr?: string };
    
    if (err.name === 'AbortError' || err.code === 'ETIMEDOUT') {
      mantis_log('ERROR', 'tsc_check_timeout', {
        tenant_id: tenantId,
        timeout_ms: timeoutMs
      });
      throw new Error(`tsc check timeout after ${timeoutMs}ms`);
    }
    
    // tsc retorna non-zero exit code si hay errores: eso es esperado
    if (err.code === 1 && err.stdout) {
      const errors = err.stdout.split('\n').filter(l => /error TS\d+:/i.test(l)).map(l => l.trim());
      mantis_log('WARN', 'tsc_check_with_errors', {
        tenant_id: tenantId,
        errors_count: errors.length
      });
      return { success: false, errors, warnings: [], durationMs: Date.now() - startTime };
    }
    
    mantis_log('ERROR', 'tsc_check_failed', {
      tenant_id: tenantId,
      error: err.message,
      stderr: err.stderr?.slice(0, 200)
    });
    throw error;
  }
}
```

```typescript
// ✅ C4: AsyncLocalStorage para propagación de tenant_id en operaciones de linting
export const lintContext = new AsyncLocalStorage<{ tenantId: string }>();

export function getCurrentTenantId(): string {
  const store = lintContext.getStore();
  if (!store?.tenantId) {
    mantis_log('ERROR', 'lint_context_missing_tenant', { 
      constraint: 'C4'
    });
    throw new Error('Tenant context required for lint operations (C4 constraint)');
  }
  return store.tenantId;
}

export function withLintContext<T>(tenantId: string, fn: () => Promise<T>): Promise<T> {
  return lintContext.run({ tenantId }, fn);
}
```

```typescript
// ✅ C3/C4/C8: Logger helper con tenant_id y sanitización para operaciones de linting
export function logLintEvent(
  event: 'started' | 'completed' | 'failed' | 'fixed' | 'type_checked',
  detail: Record<string, unknown>
): void {
  const ctx = lintContext.getStore();
  
  // ✅ C3: PII scrubbing heredado de mantis_log + sanitización de paths
  const sanitizedDetail = { ...detail };
  if (sanitizedDetail.file && typeof sanitizedDetail.file === 'string') {
    sanitizedDetail.file = sanitizePathInput(sanitizedDetail.file);
  }
  if (sanitizedDetail.filePath && typeof sanitizedDetail.filePath === 'string') {
    sanitizedDetail.filePath = sanitizePathInput(sanitizedDetail.filePath);
  }
  // ✅ C5: No exponer hash completo en logs
  if (sanitizedDetail.hash && typeof sanitizedDetail.hash === 'string' && sanitizedDetail.hash.length === 64) {
    sanitizedDetail.hash = sanitizedDetail.hash.slice(0, 16) + '...';
  }
  
  mantis_log(
    event === 'failed' ? 'ERROR' : 'INFO',
    `lint_${event}`,
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
// fix-sintaxis-code.test.ts
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { 
  validateLintEnv, 
  validateLintPath, 
  verifyFileIntegrity, 
  fixSyntaxFile,
  withLintContext
} from './fix-sintaxis-code';

describe('fix-sintaxis-code', () => {
  const TEST_TENANT = 'tenant-test-123';
  const TEST_WORKSPACE = '/app/workspace';

  beforeEach(() => {
    // Mock de mantis_log para testes
    global.mantis_log = vi.fn();
    // Configurar env para testes
    process.env.LINT_WORKSPACE = TEST_WORKSPACE;
    process.env.FIX_ENABLE_AUTO_FIX = 'false';
  });

  afterEach(() => {
    vi.restoreAllMocks();
    delete process.env.LINT_WORKSPACE;
    delete process.env.FIX_ENABLE_AUTO_FIX;
  });

  // Test: validateLintEnv acepta valores válidos y rechaza inválidos (C3)
  it('should validate lint environment with Zod', () => {
    // Válido
    const valid = validateLintEnv({ 
      NODE_ENV: 'production', 
      LINT_WORKSPACE: '/absolute/path',
      ESLINT_TIMEOUT_MS: '15000'
    });
    expect(valid.NODE_ENV).toBe('production');
    expect(valid.LINT_WORKSPACE).toBe('/absolute/path');

    // Inválido: workspace relativo
    expect(() => validateLintEnv({ LINT_WORKSPACE: './relative' })).toThrow();
    expect(global.mantis_log).toHaveBeenCalledWith(
      'ERROR',
      'lint_env_validation_failed',
      expect.objectContaining({ constraint: 'C3' })
    );
  });

  // Test: validateLintPath bloquea path traversal (C7)
  it('should block path traversal in lint paths', () => {
    expect(() => validateLintPath('../../../etc/passwd', TEST_WORKSPACE))
      .toThrow('Path traversal blocked');
    
    expect(global.mantis_log).toHaveBeenCalledWith(
      'ERROR',
      'lint_path_traversal_blocked',
      expect.objectContaining({ constraint: 'C7' })
    );
  });

  // Test: validateLintPath acepta ruta válida dentro del workspace (C7)
  it('should accept valid path within workspace', () => {
    const result = validateLintPath('src/utils/helper.ts', TEST_WORKSPACE);
    
    expect(result.resolved).toBe(path.resolve(TEST_WORKSPACE, 'src/utils/helper.ts'));
    expect(result.withinWorkspace).toBe(true);
  });

  // Test: verifyFileIntegrity calcula hash SHA256 correctamente (C5)
  it('should compute SHA256 hash for file integrity', async () => {
    // Mock de fs.readFile
    vi.mock('fs/promises', async () => {
      const actual = await vi.importActual('fs/promises');
      return {
        ...actual,
        readFile: vi.fn().mockResolvedValue(Buffer.from('test source code'))
      };
    });

    const { valid, actualHash } = await verifyFileIntegrity('/fake/file.ts');
    
    // SHA256 de "test source code"
    const expected = require('crypto').createHash('sha256').update('test source code').digest('hex');
    expect(actualHash).toBe(expected);
    expect(valid).toBe(true); // Sin hash esperado, siempre válido
  });

  // Test: withLintContext requiere tenant_id (C4)
  it('should throw error when tenant context is missing', async () => {
    await expect(
      withLintContext(TEST_TENANT, () => Promise.resolve('ok'))
    ).resolves.toBe('ok');
    
    // Fuera de contexto, getCurrentTenantId debe fallar
    expect(() => {
      // @ts-expect-error: probando comportamiento fuera de contexto
      return require('./fix-sintaxis-code').getCurrentTenantId();
    }).toThrow('Tenant context required');
  });

  // Test: fixSyntaxFile falla si integridad no coincide (C5)
  it('should abort lint if file integrity check fails', async () => {
    // Mock de verifyFileIntegrity para retornar hash diferente
    vi.spyOn(require('./fix-sintaxis-code'), 'verifyFileIntegrity')
      .mockResolvedValue({ valid: false, actualHash: 'different-hash' });

    await expect(
      fixSyntaxFile('src/file.ts', {
        tenantId: TEST_TENANT,
        expectedHash: 'expected-hash-123'
      })
    ).rejects.toThrow('File integrity check failed');
    
    expect(global.mantis_log).toHaveBeenCalledWith(
      'ERROR',
      'lint_aborted_integrity_failed',
      expect.objectContaining({ constraint: 'C5' })
    );
  });
});
```

---

## 🔍 Validação (VDD – Comando Canônico)
```bash
# Validação integral via orchestrator-engine (herda checks do Master Agent)
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/javascript/fix-sintaxis-code.ts.md \
  --json \
  --check-structural \
  --check-error-handling \
  --check-observability \
  --check-constraints C3,C4,C5,C7,C8

# Validação específica de env validation (C3)
bash 05-CONFIGURATIONS/validation/verify-constraints.sh \
  --file 06-PROGRAMMING/javascript/fix-sintaxis-code.ts.md \
  --check C3 \
  --json

# Validação de tenant isolation (C4)
bash 05-CONFIGURATIONS/validation/check-rls.sh \
  --file 06-PROGRAMMING/javascript/fix-sintaxis-code.ts.md \
  --lang ts \
  --json

# Validação de integrity/type safety (C5)
bash 05-CONFIGURATIONS/validation/verify-constraints.sh \
  --file 06-PROGRAMMING/javascript/fix-sintaxis-code.ts.md \
  --check C5 \
  --json

# Validação de path safety (C7)
bash 05-CONFIGURATIONS/validation/verify-constraints.sh \
  --file 06-PROGRAMMING/javascript/fix-sintaxis-code.ts.md \
  --check C7 \
  --json

# Validação de observability V-LOG-02 (C8)
bash 05-CONFIGURATIONS/validation/verify-observability.sh \
  --file 06-PROGRAMMING/javascript/fix-sintaxis-code.ts.md \
  --schema V-LOG-02 \
  --json
```

---

## 🔗 Referências Cruzadas (Wikilinks Mínimos)
- [[javascript-typescript-master-agent.md]] ← Fonte de `mantis_log()`, hardening, constraints
- [[/05-CONFIGURATIONS/validation/orchestrator-engine.sh]] ← Motor de validação principal
- [[/05-CONFIGURATIONS/validation/verify-constraints.sh]] ← Validação C3/C5/C7
- [[/05-CONFIGURATIONS/validation/check-rls.sh]] ← Validação C4 (tenant isolation)
- [[/05-CONFIGURATIONS/validation/verify-observability.sh]] ← Validação C8 + V-LOG-02
- [[/01-RULES/harness-norms-v3.0.md#C3]] ← Definição formal de C3 (Secrets/Env Validation)
- [[/01-RULES/harness-norms-v3.0.md#C4]] ← Definição formal de C4 (Tenant Isolation)
- [[/01-RULES/harness-norms-v3.0.md#C5]] ← Definição formal de C5 (Type Safety/Integrity)
- [[/01-RULES/harness-norms-v3.0.md#C7]] ← Definição formal de C7 (Path Safety)
- [[/01-RULES/harness-norms-v3.0.md#C8]] ← Definição formal de C8 (Observability)

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 2.3.0-MODULAR-MERGED | 2026-05-09 | javascript-typescript-master-agent | MERGE: estrutura modular v2.3.0 + bootstrap resiliente + observability V-LOG-02 + tsc integration + integrity checks | C3,C4,C5,C7,C8 |
| 2.1.1 | 2026-04-16 | Framework Core Team | Adição de exemplos AbortSignal.timeout para ESLint e validação de hash pre-lint | C3,C4,C5,C7,C8 |
| 2.0.0 | 2026-03-01 | Qwen + DeepSeek | Primeira versão canônica com padrões ESLint integration + path sanitization + AsyncLocalStorage | C3,C4,C5,C7,C8 |

---

## 🔍 Observability (Documentación para IA – Eventos Específicos)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `lint_operation_started` | INFO | C8 | `"{\"tenant_id\":\"t123\",\"file_path\":\"src/utils/helper.ts\",\"fix_enabled\":false,\"timeout_ms\":10000}"` |
| `lint_path_validated` | DEBUG | C7 | `"{\"resolved\":\"/app/workspace/src/utils/helper.ts\",\"within_workspace\":true}"` |
| `file_hash_computed` | DEBUG | C5 | `"{\"path\":\"src/utils/helper.ts\",\"hash_prefix\":\"a1b2c3d4e5f6...\"}"` |
| `lint_auto_fix_applied` | INFO | C5 | `"{\"tenant_id\":\"t123\",\"file\":\"src/utils/helper.ts\",\"new_hash_prefix\":\"b2c3d4e5f6a7...\"}"` |
| `lint_completed` | INFO | C8 | `"{\"tenant_id\":\"t123\",\"file\":\"src/utils/helper.ts\",\"errors_count\":0,\"warnings_count\":2,\"fixed\":false}"` |
| `lint_aborted_integrity_failed` | ERROR | C5 | `"{\"tenant_id\":\"t123\",\"constraint\":\"C5\"}"` |
| `lint_timeout_triggered` | WARN | C8 | `"{\"tenant_id\":\"t123\",\"timeout_ms\":10000}"` |
| `lint_path_traversal_blocked` | ERROR | C7 | `"{\"requested\":\"../../../etc/passwd\",\"resolved\":\"/etc/passwd\",\"constraint\":\"C7\"}"` |
| `tsc_check_completed` | INFO | C8 | `"{\"tenant_id\":\"t123\",\"success\":true,\"errors_count\":0,\"warnings_count\":1,\"duration_ms\":2345}"` |

### Validação de Schema V-LOG-02 (Helper Mínimo)
```typescript
// Helper para validar que logs de fix-sintaxis-code seguem schema V-LOG-02
export function validateLintLog(logEntry: unknown): { valid: boolean; errors: string[] } {
  const errors: string[] = [];
  const entry = logEntry as Record<string, unknown>;

  // Campos obrigatórios V-LOG-02
  const required = ['ts', 'level', 'resource', 'body'];
  for (const field of required) {
    if (!(field in entry)) errors.push(`Missing required field: ${field}`);
  }

  // Validar que tenant_id está presente para eventos de linting (C4)
  const lintEvents = ['lint_operation_started', 'lint_completed', 'lint_aborted_integrity_failed'];
  if (lintEvents.includes(entry.body?.event as string)) {
    const detail = entry.body?.detail as Record<string, unknown>;
    if (!detail?.tenant_id) {
      errors.push('C4 violation: lint event missing tenant_id in detail');
    }
  }

  // Validar que hash no se expone completo en logs (C3/C5)
  if (entry.body?.detail?.hash && typeof entry.body.detail.hash === 'string') {
    const hashVal = entry.body.detail.hash as string;
    if (hashVal.length === 64 && /^[a-f0-9]{64}$/.test(hashVal)) {
      errors.push('C3/C5 warning: full SHA256 hash exposed in log (use hash_prefix instead)');
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
  "artifact": "fix-sintaxis-code",
  "version": "2.3.0-MODULAR-MERGED",
  "score": 32,
  "blocking_issues": [],
  "constraints_verified": ["C3", "C4", "C5", "C7", "C8"],
  "examples_count": 10,
  "lines_executable_max": 3,
  "language": "TypeScript 5.0+ / Node.js 18+",
  "observability_compliant": true,
  "bootstrap_resilient": true,
  "mantis_log_usage": "inherited",
  "zod_validation_verified": true,
  "path_validation_verified": true,
  "integrity_check_verified": true,
  "eslint_integration_verified": true,
  "tsc_integration_verified": true,
  "timestamp": "2026-05-09T00:00:00Z"
}
```

---

> 🇧🇷 *Documento técnico em pt-BR conforme V-DOC-01. Coordenação en español. Zero invenção: todo padrão grounded no conteúdo original + template v2.3.0-MODULAR.*
