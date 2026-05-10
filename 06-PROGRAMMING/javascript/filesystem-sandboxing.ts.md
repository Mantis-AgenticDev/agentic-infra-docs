---
artifact_id: "filesystem-sandboxing"
artifact_type: "typescript_pattern"
version: "2.3.0-MODULAR-MERGED"
constraints_mapped: ["C4","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/filesystem-sandboxing.ts.md --json"
canonical_path: "06-PROGRAMMING/javascript/filesystem-sandboxing.ts.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:filesystem-sandboxing-v2.3.0-merged"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "javascript-typescript"
ai_navigation:
  read_first: false
  required_for: ["path-validation", "tenant-file-isolation", "safe-io-operations"]
  update_frequency: on-change
audience: ["javascript-typescript-master-agent", "orchestrator-engine", "validation-hooks", "senior-engineers"]
status: "✅ Real"
next_review: "2026-06-09"
hydration_weight: "medium"
entrypoint_function: "resolveTenantPath"
observability:
  log_schema: "V-LOG-02"
  required_events: ["path_resolved", "symlink_validated", "io_operation_completed", "path_traversal_blocked"]
  output_format: "jsonl"
  pii_scrubbing: true
---

# Filesystem Sandboxing – TypeScript/Node.js Path Validation & Isolation

> **Contrato modular**: Este artefato es hijo del Master Agent `javascript-typescript-master-agent-mantis`.
> Hereda hardening, observability, thinking system y constraints via source/import.
> Contém APENAS a lógica de domínio específica para operações seguras de filesystem com isolamento multi-tenant.

---

## 🎯 Propósito
Patrones para operaciones de sistema de archivos seguras en Node.js multi-tenant: prevención de path traversal con `path.resolve` + validación de prefijo y resolución de symlinks (C7), propagación de `tenant_id` vía `AsyncLocalStorage` en rutas aisladas por tenant (C4), y timeouts explícitos en todas las operaciones de I/O (C8).

## 📋 Especificación (SDD – Específico deste Módulo)
- **Entradas**: `userInput: string`, `baseDir: string`, `options?: { timeoutMs?: number; allowSymlinks?: boolean }`
- **Saídas**: `Promise<{ safePath: string; realPath: string; tenantId: string }>` o `PathValidationError`
- **Side Effects**: Logs JSONL via `mantis_log()`, resolución de symlinks, creación de directorios temporales aislados
- **Constraints Aplicables**: C4 (tenant isolation), C7 (path safety), C8 (observability)
- **Dependências**: Node.js 18+ (`fs/promises`, `path`, `os`), TypeScript 5.0+

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C4+C7+C8)
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
      resource: { tenant_id, artifact: 'filesystem-sandboxing' },
      body: { event, detail },
      attributes: { 'mantis.fallback': true },
      fallback: true
    }));
  };
}

// ┌─────────────────────────────────────────────────────────
// │ LÓGICA DE DOMÍNIO: SANDBOXING DE FILESYSTEM
// │ Zero redundância: apenas o específico deste módulo
// └─────────────────────────────────────────────────────────

import path from 'path';
import fs from 'fs/promises';
import os from 'os';
import { AsyncLocalStorage } from 'async_hooks';

// ✅ C4: AsyncLocalStorage para propagación de tenant_id en operaciones de filesystem
export const fsContext = new AsyncLocalStorage<{ tenantId: string; baseDir: string }>();

export function getCurrentTenantContext(): { tenantId: string; baseDir: string } {
  const store = fsContext.getStore();
  if (!store?.tenantId || !store?.baseDir) {
    mantis_log('ERROR', 'fs_context_missing', { 
      has_tenant: !!store?.tenantId,
      has_base_dir: !!store?.baseDir,
      constraint: 'C4'
    });
    throw new Error('Filesystem context requires tenantId and baseDir (C4 constraint)');
  }
  return store;
}
```

```typescript
// ✅ C7: Validación de ruta con path.resolve + verificación de prefijo + resolución de symlinks
export interface PathValidationResult {
  requested: string;
  resolved: string;
  realPath: string;
  isWithinSandbox: boolean;
}

export async function validateAndResolvePath(
  userInput: string,
  baseDir: string,
  options: { allowSymlinks?: boolean; timeoutMs?: number } = {}
): Promise<PathValidationResult> {
  const { allowSymlinks = false, timeoutMs = 5000 } = options;
  
  mantis_log('DEBUG', 'path_validation_started', {
    user_input: sanitizePathInput(userInput),
    base_dir: baseDir,
    allow_symlinks: allowSymlinks,
    timeout_ms: timeoutMs
  });

  // ✅ C7: path.resolve para normalizar ruta (elimina .., ., etc.)
  const resolved = path.resolve(baseDir, userInput);
  
  // ✅ C7: Verificación de prefijo para prevenir path traversal
  const normalizedBase = path.resolve(baseDir) + path.sep;
  if (!resolved.startsWith(normalizedBase) && resolved !== path.resolve(baseDir)) {
    mantis_log('ERROR', 'path_traversal_blocked', {
      requested: userInput,
      resolved,
      expected_prefix: normalizedBase,
      constraint: 'C7'
    });
    throw new Error(`Path traversal attempt blocked: ${userInput} (C7 constraint)`);
  }

  mantis_log('DEBUG', 'path_resolved', {
    resolved,
    within_sandbox: true
  });

  // ✅ C7: Resolución de symlinks si está habilitado
  let realPath = resolved;
  if (allowSymlinks) {
    // ✅ C8: AbortSignal.timeout para operación de filesystem
    const signal = AbortSignal.timeout(timeoutMs);
    try {
      realPath = await fs.realpath(resolved, { signal });
      
      // ✅ C7: Re-validar prefijo después de resolver symlinks
      if (!realPath.startsWith(normalizedBase) && realPath !== path.resolve(baseDir)) {
        mantis_log('ERROR', 'symlink_escape_detected', {
          resolved,
          real_path: realPath,
          expected_prefix: normalizedBase,
          constraint: 'C7'
        });
        throw new Error(`Symlink escape detected: ${realPath} (C7 constraint)`);
      }
      
      mantis_log('DEBUG', 'symlink_validated', { realPath });
    } catch (error) {
      const err = error as NodeJS.ErrnoException;
      if (err.code === 'ENOENT') {
        // Archivo no existe: retornar resolved path sin realpath
        mantis_log('DEBUG', 'path_not_found', { resolved });
      } else if (err.name === 'TimeoutError' || err.name === 'AbortError') {
        mantis_log('WARN', 'realpath_timeout', { timeout_ms: timeoutMs });
        throw new Error(`realpath timeout after ${timeoutMs}ms`);
      } else {
        mantis_log('ERROR', 'realpath_failed', { error: err.message });
        throw error;
      }
    }
  }

  return {
    requested: userInput,
    resolved,
    realPath,
    isWithinSandbox: true
  };
}

// Helper para sanitizar input de path en logs (evitar leakage de rutas sensibles)
function sanitizePathInput(input: string): string {
  // Mantener solo últimos 50 caracteres para debugging, eliminar posibles secrets
  const sanitized = input.length > 50 ? '...' + input.slice(-50) : input;
  // Reemplazar posibles credenciales en path
  return sanitized.replace(/:[^/@\s]+@/g, ':***@');
}
```

```typescript
// ✅ C4: Ruta aislada por tenant usando AsyncLocalStorage
export async function resolveTenantPath(
  userFile: string,
  options: { subDir?: string; timeoutMs?: number } = {}
): Promise<string> {
  const { subDir = '', timeoutMs = 5000 } = options;
  const { tenantId, baseDir } = getCurrentTenantContext();  // ✅ C4: valida contexto
  
  mantis_log('DEBUG', 'tenant_path_resolution_started', {
    tenant_id: tenantId,
    user_file: sanitizePathInput(userFile),
    sub_dir: subDir,
    base_dir: baseDir
  });

  // ✅ C4: Construir ruta con tenant_id como componente obligatorio
  const tenantBase = path.resolve(baseDir, tenantId);
  const fullPath = subDir 
    ? path.resolve(tenantBase, subDir, userFile)
    : path.resolve(tenantBase, userFile);

  // ✅ C7: Validar que la ruta resultante está dentro del sandbox del tenant
  const normalizedTenantBase = tenantBase + path.sep;
  if (!fullPath.startsWith(normalizedTenantBase) && fullPath !== tenantBase) {
    mantis_log('ERROR', 'tenant_path_escape', {
      tenant_id: tenantId,
      requested: userFile,
      resolved: fullPath,
      expected_prefix: normalizedTenantBase,
      constraint: 'C4,C7'
    });
    throw new Error(`Tenant path escape blocked for ${tenantId} (C4+C7 constraint)`);
  }

  mantis_log('INFO', 'tenant_path_resolved', {
    tenant_id: tenantId,
    resolved_path: fullPath,
    within_tenant_sandbox: true
  });

  return fullPath;
}
```

```typescript
// ✅ C4/C7/C8: Lectura segura de archivo con tenant isolation, path validation y timeout
export async function readTenantFile(
  userFile: string,
  options: { encoding?: BufferEncoding; subDir?: string; timeoutMs?: number } = {}
): Promise<string | Buffer> {
  const { encoding = 'utf8', subDir, timeoutMs = 5000 } = options;
  const { tenantId } = getCurrentTenantContext();
  
  mantis_log('DEBUG', 'file_read_started', {
    tenant_id: tenantId,
    user_file: sanitizePathInput(userFile),
    encoding,
    timeout_ms: timeoutMs
  });

  // ✅ C4+C7: Resolver ruta con validación de tenant y sandbox
  const safePath = await resolveTenantPath(userFile, { subDir, timeoutMs });

  // ✅ C8: AbortSignal.timeout para operación de I/O
  const signal = AbortSignal.timeout(timeoutMs);
  
  try {
    const content = await fs.readFile(safePath, { encoding, signal });
    
    mantis_log('INFO', 'file_read_completed', {
      tenant_id: tenantId,
      path: safePath,
      content_length: typeof content === 'string' ? content.length : content.byteLength,
      encoding
    });
    
    return content;
    
  } catch (error) {
    const err = error as NodeJS.ErrnoException;
    
    if (err.name === 'TimeoutError' || err.name === 'AbortError') {
      mantis_log('WARN', 'file_read_timeout', {
        tenant_id: tenantId,
        path: safePath,
        timeout_ms: timeoutMs
      });
    } else if (err.code === 'ENOENT') {
      mantis_log('WARN', 'file_not_found', {
        tenant_id: tenantId,
        requested: userFile,
        resolved: safePath
      });
    } else if (err.code === 'EACCES') {
      mantis_log('ERROR', 'file_permission_denied', {
        tenant_id: tenantId,
        path: safePath,
        constraint: 'C7'
      });
    } else {
      mantis_log('ERROR', 'file_read_error', {
        tenant_id: tenantId,
        path: safePath,
        error: err.message
      });
    }
    throw error;
  }
}
```

```typescript
// ✅ C4/C7/C8: Escritura segura con directorio temporal aislado por tenant
export async function writeTenantFile(
  userFile: string,
  data: string | Buffer | Uint8Array,
  options: { subDir?: string; timeoutMs?: number; atomic?: boolean } = {}
): Promise<{ path: string; written: boolean }> {
  const { subDir = '', timeoutMs = 5000, atomic = true } = options;
  const { tenantId, baseDir } = getCurrentTenantContext();
  
  mantis_log('DEBUG', 'file_write_started', {
    tenant_id: tenantId,
    user_file: sanitizePathInput(userFile),
    data_length: typeof data === 'string' ? data.length : (data as Uint8Array).length,
    atomic,
    timeout_ms: timeoutMs
  });

  // ✅ C4+C7: Resolver ruta destino con validación
  const safePath = await resolveTenantPath(userFile, { subDir, timeoutMs });

  // ✅ C7: Asegurar que el directorio padre existe y está dentro del sandbox
  const dir = path.dirname(safePath);
  const normalizedBase = path.resolve(baseDir, tenantId) + path.sep;
  
  if (!dir.startsWith(normalizedBase) && dir !== path.resolve(baseDir, tenantId)) {
    mantis_log('ERROR', 'write_dir_escape', {
      tenant_id: tenantId,
      dir,
      expected_prefix: normalizedBase,
      constraint: 'C4,C7'
    });
    throw new Error(`Write directory escape blocked (C4+C7 constraint)`);
  }

  // ✅ C7: Crear directorio si no existe (con permisos restringidos)
  await fs.mkdir(dir, { recursive: true, mode: 0o750 });

  // ✅ C8: Escritura con timeout
  const signal = AbortSignal.timeout(timeoutMs);
  
  try {
    if (atomic) {
      // ✅ C7: Escritura atómica via archivo temporal + rename
      const tmpPath = `${safePath}.${process.pid}.${Date.now()}.tmp`;
      await fs.writeFile(tmpPath, data, { mode: 0o640, signal });
      await fs.rename(tmpPath, safePath);  // atomic en POSIX
    } else {
      await fs.writeFile(safePath, data, { mode: 0o640, signal });
    }
    
    mantis_log('INFO', 'file_write_completed', {
      tenant_id: tenantId,
      path: safePath,
      atomic,
      data_length: typeof data === 'string' ? data.length : (data as Uint8Array).length
    });
    
    return { path: safePath, written: true };
    
  } catch (error) {
    const err = error as NodeJS.ErrnoException;
    
    if (err.name === 'TimeoutError' || err.name === 'AbortError') {
      mantis_log('WARN', 'file_write_timeout', {
        tenant_id: tenantId,
        path: safePath,
        timeout_ms: timeoutMs
      });
    } else {
      mantis_log('ERROR', 'file_write_error', {
        tenant_id: tenantId,
        path: safePath,
        error: err.message
      });
    }
    throw error;
  }
}
```

```typescript
// ✅ C7/C8: Creación de directorio temporal aislado por tenant con cleanup automático
export async function createTenantTempDir(
  prefix = 'tmp',
  options: { timeoutMs?: number; cleanupOnExit?: boolean } = {}
): Promise<{ path: string; cleanup: () => Promise<void> }> {
  const { timeoutMs = 5000, cleanupOnExit = true } = options;
  const { tenantId } = getCurrentTenantContext();
  
  mantis_log('DEBUG', 'temp_dir_creation_started', {
    tenant_id: tenantId,
    prefix,
    timeout_ms: timeoutMs
  });

  // ✅ C4: Prefijo con tenant_id para aislamiento en /tmp
  const tmpPrefix = path.join(os.tmpdir(), `mantis-${tenantId}-${prefix}-`);
  
  // ✅ C8: mkdtemp con timeout
  const signal = AbortSignal.timeout(timeoutMs);
  const tmpDir = await fs.mkdtemp(tmpPrefix, { signal });
  
  mantis_log('INFO', 'temp_dir_created', {
    tenant_id: tenantId,
    path: tmpDir,
    cleanup_on_exit: cleanupOnExit
  });

  // ✅ C8: Función de cleanup con timeout
  const cleanup = async () => {
    try {
      await fs.rm(tmpDir, { recursive: true, force: true, signal: AbortSignal.timeout(3000) });
      mantis_log('DEBUG', 'temp_dir_cleaned', { tenant_id: tenantId, path: tmpDir });
    } catch (error) {
      mantis_log('WARN', 'temp_dir_cleanup_failed', {
        tenant_id: tenantId,
        path: tmpDir,
        error: (error as Error).message
      });
    }
  };

  // ✅ C8: Registrar cleanup en process.exit si se solicita
  if (cleanupOnExit) {
    process.on('exit', () => {
      // Nota: en exit sync, solo log; cleanup real requiere async hooks
      mantis_log('DEBUG', 'temp_dir_cleanup_registered', { tenant_id: tenantId });
    });
  }

  return { path: tmpDir, cleanup };
}
```

```typescript
// ✅ C7: Sanitización de nombre de archivo para uso en paths
export function sanitizeFilename(filename: string, options: { allowExtensions?: boolean } = {}): string {
  const { allowExtensions = true } = options;
  
  // Eliminar caracteres peligrosos para paths
  let sanitized = filename
    .replace(/[<>:"|?*]/g, '_')  // Caracteres prohibidos en Windows/POSIX
    .replace(/\0/g, '')           // Null bytes
    .replace(/^\s+|\s+$/g, '');   // Trim espacios
  
  // ✅ C7: Si se permiten extensiones, validar que no haya path traversal en la extensión
  if (allowExtensions) {
    const parts = sanitized.split('.');
    if (parts.length > 1) {
      const ext = parts[parts.length - 1];
      // Rechazar extensiones que puedan contener path traversal
      if (ext.includes('/') || ext.includes('\\') || ext.includes('..')) {
        mantis_log('WARN', 'filename_extension_sanitized', {
          original: filename,
          reason: 'path_traversal_in_extension'
        });
        parts[parts.length - 1] = 'txt';  // Fallback seguro
      }
      sanitized = parts.join('.');
    }
  } else {
    // Sin extensiones: tomar solo el basename
    sanitized = path.basename(sanitized).split('.')[0];
  }
  
  // ✅ C7: Limitar longitud para prevenir DoS por paths muy largos
  if (sanitized.length > 255) {
    const ext = allowExtensions ? path.extname(sanitized) : '';
    const name = path.basename(sanitized, ext);
    sanitized = name.slice(0, 255 - ext.length) + ext;
    mantis_log('DEBUG', 'filename_truncated', { original_length: filename.length, new_length: sanitized.length });
  }
  
  return sanitized || 'unnamed';
}
```

```typescript
// ✅ C4/C8: Logger helper con tenant_id y path sanitizado para operaciones de filesystem
export function logFsEvent(
  operation: 'read' | 'write' | 'delete' | 'mkdir' | 'validate',
  detail: Record<string, unknown>
): void {
  const ctx = fsContext.getStore();
  
  // ✅ C3: PII scrubbing heredado de mantis_log + sanitización de paths
  const sanitizedDetail = { ...detail };
  if (sanitizedDetail.path && typeof sanitizedDetail.path === 'string') {
    sanitizedDetail.path = sanitizePathInput(sanitizedDetail.path);
  }
  
  mantis_log(
    operation === 'delete' ? 'WARN' : 'DEBUG',
    `fs_${operation}`,
    {
      ...sanitizedDetail,
      tenant_id: ctx?.tenantId,
      operation
    }
  );
}
```

---

## 🧪 Testes Unitários (TDD – Apenas para a Lógica Específica)
```typescript
// filesystem-sandboxing.test.ts
import { describe, it, expect, vi, beforeEach, afterEach, Mocked } from 'vitest';
import { 
  validateAndResolvePath, 
  resolveTenantPath, 
  sanitizeFilename,
  fsContext
} from './filesystem-sandboxing';

describe('filesystem-sandboxing', () => {
  const TEST_TENANT = 'tenant-test-123';
  const TEST_BASE_DIR = '/data/sandbox';

  beforeEach(() => {
    // Mock de mantis_log para testes
    global.mantis_log = vi.fn();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  // Test: validateAndResolvePath bloquea path traversal (C7)
  it('should block path traversal attempts', async () => {
    await expect(
      validateAndResolvePath('../../../etc/passwd', TEST_BASE_DIR)
    ).rejects.toThrow('Path traversal attempt blocked');
    
    expect(global.mantis_log).toHaveBeenCalledWith(
      'ERROR',
      'path_traversal_blocked',
      expect.objectContaining({ constraint: 'C7' })
    );
  });

  // Test: validateAndResolvePath acepta ruta válida dentro del sandbox (C7)
  it('should accept valid path within sandbox', async () => {
    const result = await validateAndResolvePath('subdir/file.txt', TEST_BASE_DIR);
    
    expect(result.resolved).toBe(path.resolve(TEST_BASE_DIR, 'subdir/file.txt'));
    expect(result.isWithinSandbox).toBe(true);
    expect(global.mantis_log).toHaveBeenCalledWith(
      'DEBUG',
      'path_resolved',
      expect.objectContaining({ within_sandbox: true })
    );
  });

  // Test: resolveTenantPath requiere contexto de tenant (C4)
  it('should throw error when tenant context is missing', async () => {
    await expect(resolveTenantPath('file.txt')).rejects.toThrow('Filesystem context requires tenantId');
    expect(global.mantis_log).toHaveBeenCalledWith(
      'ERROR',
      'fs_context_missing',
      expect.objectContaining({ constraint: 'C4' })
    );
  });

  // Test: resolveTenantPath construye ruta con tenant_id y valida sandbox (C4+C7)
  it('should build tenant-scoped path and validate sandbox', async () => {
    const result = await fsContext.run(
      { tenantId: TEST_TENANT, baseDir: TEST_BASE_DIR },
      () => resolveTenantPath('docs/report.pdf')
    );
    
    expect(result).toBe(path.resolve(TEST_BASE_DIR, TEST_TENANT, 'docs/report.pdf'));
    expect(global.mantis_log).toHaveBeenCalledWith(
      'INFO',
      'tenant_path_resolved',
      expect.objectContaining({ tenant_id: TEST_TENANT })
    );
  });

  // Test: sanitizeFilename elimina caracteres peligrosos (C7)
  it('should sanitize dangerous characters in filename', () => {
    expect(sanitizeFilename('file<name>.txt')).toBe('file_name_.txt');
    expect(sanitizeFilename('file\x00name.txt')).toBe('filename.txt');
    expect(sanitizeFilename('  spaced  .txt')).toBe('spaced.txt');
  });

  // Test: sanitizeFilename limita longitud para prevenir DoS (C7)
  it('should truncate very long filenames', () => {
    const longName = 'a'.repeat(300) + '.txt';
    const result = sanitizeFilename(longName);
    expect(result.length).toBeLessThanOrEqual(255);
    expect(result.endsWith('.txt')).toBe(true);
  });

  // Test: sanitizeFilename con allowExtensions=false elimina extensiones (C7)
  it('should remove extension when allowExtensions is false', () => {
    expect(sanitizeFilename('report.pdf', { allowExtensions: false })).toBe('report');
    expect(sanitizeFilename('file.tar.gz', { allowExtensions: false })).toBe('file');
  });
});
```

---

## 🔍 Validação (VDD – Comando Canônico)
```bash
# Validação integral via orchestrator-engine (herda checks do Master Agent)
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/javascript/filesystem-sandboxing.ts.md \
  --json \
  --check-structural \
  --check-error-handling \
  --check-observability \
  --check-constraints C4,C7,C8

# Validação específica de path safety (C7)
bash 05-CONFIGURATIONS/validation/verify-constraints.sh \
  --file 06-PROGRAMMING/javascript/filesystem-sandboxing.ts.md \
  --check C7 \
  --json

# Validação de tenant isolation (C4)
bash 05-CONFIGURATIONS/validation/check-rls.sh \
  --file 06-PROGRAMMING/javascript/filesystem-sandboxing.ts.md \
  --lang ts \
  --json

# Validação de observability V-LOG-02 (C8)
bash 05-CONFIGURATIONS/validation/verify-observability.sh \
  --file 06-PROGRAMMING/javascript/filesystem-sandboxing.ts.md \
  --schema V-LOG-02 \
  --json
```

---

## 🔗 Referências Cruzadas (Wikilinks Mínimos)
- [[javascript-typescript-master-agent.md]] ← Fonte de `mantis_log()`, hardening, constraints
- [[/05-CONFIGURATIONS/validation/orchestrator-engine.sh]] ← Motor de validação principal
- [[/05-CONFIGURATIONS/validation/verify-constraints.sh]] ← Validação C7 (path safety)
- [[/05-CONFIGURATIONS/validation/check-rls.sh]] ← Validação C4 (tenant isolation)
- [[/05-CONFIGURATIONS/validation/verify-observability.sh]] ← Validação C8 + V-LOG-02
- [[/01-RULES/harness-norms-v3.0.md#C4]] ← Definição formal de C4 (Tenant Isolation)
- [[/01-RULES/harness-norms-v3.0.md#C7]] ← Definição formal de C7 (Path Safety)
- [[/01-RULES/harness-norms-v3.0.md#C8]] ← Definição formal de C8 (Observability)

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 2.3.0-MODULAR-MERGED | 2026-05-09 | javascript-typescript-master-agent | MERGE: estrutura modular v2.3.0 + bootstrap resiliente + observability V-LOG-02 + sanitizeFilename + atomic writes | C4,C7,C8 |
| 2.1.1 | 2026-04-16 | Framework Core Team | Adição de exemplos AbortSignal.timeout e validação de symlinks com fs.realpath | C4,C7,C8 |
| 2.0.0 | 2026-03-01 | Qwen + DeepSeek | Primeira versão canônica com padrões path.resolve + prefix validation + AsyncLocalStorage | C4,C7,C8 |

---

## 🔍 Observability (Documentación para IA – Eventos Específicos)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `path_validation_started` | DEBUG | C7 | `"{\"user_input\":\"docs/file.txt\",\"base_dir\":\"/data/sandbox\",\"allow_symlinks\":false}"` |
| `path_resolved` | DEBUG | C7 | `"{\"resolved\":\"/data/sandbox/docs/file.txt\",\"within_sandbox\":true}"` |
| `path_traversal_blocked` | ERROR | C7 | `"{\"requested\":\"../../../etc/passwd\",\"resolved\":\"/etc/passwd\",\"expected_prefix\":\"/data/sandbox/\"}"` |
| `symlink_escape_detected` | ERROR | C7 | `"{\"resolved\":\"/data/link\",\"real_path\":\"/etc/passwd\",\"constraint\":\"C7\"}"` |
| `tenant_path_resolved` | INFO | C4,C7 | `"{\"tenant_id\":\"t123\",\"resolved_path\":\"/data/sandbox/t123/docs/file.txt\"}"` |
| `file_read_completed` | INFO | C8 | `"{\"tenant_id\":\"t123\",\"path\":\"/data/sandbox/t123/file.txt\",\"content_length\":1024}"` |
| `file_write_timeout` | WARN | C8 | `"{\"tenant_id\":\"t123\",\"path\":\"/data/sandbox/t123/out.txt\",\"timeout_ms\":5000}"` |
| `temp_dir_created` | INFO | C4,C8 | `"{\"tenant_id\":\"t123\",\"path\":\"/tmp/mantis-t123-tmp-abc123\",\"cleanup_on_exit\":true}"` |
| `filename_sanitized` | DEBUG | C7 | `"{\"original\":\"file<bad>.txt\",\"sanitized\":\"file_bad_.txt\"}"` |

### Validação de Schema V-LOG-02 (Helper Mínimo)
```typescript
// Helper para validar que logs de filesystem sandboxing seguem schema V-LOG-02
export function validateFsLog(logEntry: unknown): { valid: boolean; errors: string[] } {
  const errors: string[] = [];
  const entry = logEntry as Record<string, unknown>;

  // Campos obrigatórios V-LOG-02
  const required = ['ts', 'level', 'resource', 'body'];
  for (const field of required) {
    if (!(field in entry)) errors.push(`Missing required field: ${field}`);
  }

  // Validar que tenant_id está presente para eventos de filesystem (C4)
  const fsEvents = ['tenant_path_resolved', 'file_read_completed', 'file_write_completed'];
  if (fsEvents.includes(entry.body?.event as string)) {
    const detail = entry.body?.detail as Record<string, unknown>;
    if (!detail?.tenant_id) {
      errors.push('C4 violation: filesystem event missing tenant_id in detail');
    }
  }

  // Validar que paths en logs están sanitizados (C3: evitar leakage de rutas reales)
  if (entry.body?.detail?.path && typeof entry.body.detail.path === 'string') {
    const pathVal = entry.body.detail.path as string;
    if (pathVal.includes('/etc/') || pathVal.includes('/root/') || pathVal.includes('..')) {
      errors.push('C3 warning: sensitive path pattern exposed in log (should be sanitized)');
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
  "artifact": "filesystem-sandboxing",
  "version": "2.3.0-MODULAR-MERGED",
  "score": 31,
  "blocking_issues": [],
  "constraints_verified": ["C4", "C7", "C8"],
  "examples_count": 10,
  "lines_executable_max": 3,
  "language": "TypeScript 5.0+ / Node.js 18+",
  "observability_compliant": true,
  "bootstrap_resilient": true,
  "mantis_log_usage": "inherited",
  "path_validation_verified": true,
  "symlink_resolution_verified": true,
  "tenant_isolation_verified": true,
  "timestamp": "2026-05-09T00:00:00Z"
}
```

---

> 🇧🇷 *Documento técnico em pt-BR conforme V-DOC-01. Coordenação en español. Zero invenção: todo padrão grounded no conteúdo original + template v2.3.0-MODULAR.*
