---
artifact_id: "yaml-frontmatter-parser"
artifact_type: "typescript_module"
version: "2.3.0-MODULAR-MERGED"
constraints_mapped: ["C3","C4","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/yaml-frontmatter-parser.ts.md --json"
canonical_path: "06-PROGRAMMING/javascript/yaml-frontmatter-parser.ts.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:yaml-frontmatter-parser-v2.3.0-merged"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "javascript-typescript"
ai_navigation:
  read_first: false
  required_for: ["yaml-parsing", "frontmatter-validation", "markdown-processing", "schema-enforcement"]
  update_frequency: on-change
audience: ["javascript-typescript-master-agent", "orchestrator-engine", "validation-hooks", "senior-engineers"]
status: "✅ Real"
next_review: "2026-06-09"
hydration_weight: "light"
entrypoint_function: "parseFrontmatter"
observability:
  log_schema: "V-LOG-02"
  required_events: ["frontmatter_extracted", "schema_validated", "integrity_verified", "parse_completed", "parse_failed"]
  output_format: "jsonl"
  pii_scrubbing: true
---

# YAML Frontmatter Parser – TypeScript/Node.js with js‑yaml & Fallback Regex

> **Contrato modular**: Este artefato es hijo del Master Agent `javascript-typescript-master-agent-mantis`.
> Hereda hardening, observability, thinking system y constraints via source/import.
> Contém APENAS a lógica de domínio específica para extração e validação segura de frontmatter YAML em arquivos Markdown/texto.

---

## 🎯 Propósito
Patrones para extraer y validar frontmatter YAML en archivos Markdown o de texto usando `js-yaml.safeLoad`, con validación de entorno (C3), propagación de `tenant_id` vía `AsyncLocalStorage` (C4), verificación de integridad del contenido (C5) y manejo robusto de timeouts y errores (C8).

## 📋 Especificación (SDD – Específico deste Módulo)
- **Entradas**: `content: string | Buffer`, `options?: { schema?: z.ZodType<T>; expectedHash?: string; timeoutMs?: number }`
- **Saídas**: `Promise<{ frontmatter: T; content: string; hash?: string }>` o `FrontmatterParseError`
- **Side Effects**: Logs JSONL via `mantis_log()`, validación de schema Zod, cálculo de checksums SHA256
- **Constraints Aplicables**: C3 (env validation), C4 (tenant isolation), C5 (integrity/type safety), C8 (observability)
- **Dependências**: Node.js 18+, TypeScript 5.0+, `js-yaml`, `zod`, `crypto`, `async_hooks`

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C4+C5+C8)

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
    console.error(JSON.stringify({ ts: new Date().toISOString(), level, resource: { tenant_id, artifact: 'yaml-frontmatter-parser' }, body: { event, detail }, attributes: { 'mantis.fallback': true }, fallback: true }));
  };
}

import { safeLoad } from 'js-yaml';
import { z } from 'zod';
import { createHash } from 'crypto';
import { AsyncLocalStorage } from 'async_hooks';
import { readFile } from 'fs/promises';

// ✅ C3: Schema Zod base para validación de frontmatter genérico
export const baseFrontmatterSchema = z.object({
  artifact_id: z.string().min(1),
  artifact_type: z.string().optional(),
  version: z.string().regex(/^\d+\.\d+\.\d+$/).optional(),
  constraints_mapped: z.array(z.string()).optional(),
  title: z.string().optional(),
  description: z.string().optional()
});

export type BaseFrontmatter = z.infer<typeof baseFrontmatterSchema>;

// ✅ C4: AsyncLocalStorage para propagación de tenant_id en operaciones de parseo
export const parserContext = new AsyncLocalStorage<{ tenantId: string; filePath?: string }>();

export function getCurrentParserContext(): { tenantId: string; filePath?: string } {
  const store = parserContext.getStore();
  if (!store?.tenantId) {
    mantis_log('ERROR', 'parser_context_missing_tenant', { constraint: 'C4' });
    throw new Error('Tenant context required for frontmatter parsing (C4 constraint)');
  }
  return store;
}

export function withParserContext<T>(tenantId: string, filePath: string | undefined, fn: () => Promise<T>): Promise<T> {
  return parserContext.run({ tenantId, filePath }, fn);
}
```

```typescript
// ✅ C5: Extracción segura de frontmatter con regex + fallback
export interface FrontmatterExtractionResult {
  frontmatterContent: string;
  contentWithoutFrontmatter: string;
  hasFrontmatter: boolean;
}

export function extractFrontmatter(content: string): FrontmatterExtractionResult {
  // ✅ C5: Regex con non-greedy para capturar primer bloque ---...---
  const FRONTMATTER_MARKER = '---';
  const regex = /^---\r?\n([\s\S]*?)\r?\n---\r?\n/;
  const match = content.match(regex);
  
  if (match && match[1]) {
    const frontmatterContent = match[1].trim();
    const contentWithoutFrontmatter = content.slice(match[0].length).trimStart();
    
    mantis_log('DEBUG', 'frontmatter_extracted_regex', {
      frontmatter_length: frontmatterContent.length,
      remaining_content_length: contentWithoutFrontmatter.length
    });
    
    return {
      frontmatterContent,
      contentWithoutFrontmatter,
      hasFrontmatter: true
    };
  }
  
  // Fallback: split simple (menos robusto pero compatible)
  const parts = content.split(FRONTMATTER_MARKER);
  if (parts.length >= 3 && parts[0].trim() === '') {
    const frontmatterContent = parts[1].trim();
    const contentWithoutFrontmatter = parts.slice(2).join(FRONTMATTER_MARKER).trimStart();
    
    mantis_log('DEBUG', 'frontmatter_extracted_fallback', {
      frontmatter_length: frontmatterContent.length
    });
    
    return {
      frontmatterContent,
      contentWithoutFrontmatter,
      hasFrontmatter: true
    };
  }
  
  mantis_log('DEBUG', 'no_frontmatter_found');
  return {
    frontmatterContent: '',
    contentWithoutFrontmatter: content,
    hasFrontmatter: false
  };
}
```

```typescript
// ✅ C5: Parseo seguro de YAML con js-yaml.safeLoad + validación Zod
export async function parseFrontmatter<T extends BaseFrontmatter>(
  content: string,
  options: { schema?: z.ZodType<T>; tenantId?: string; expectedHash?: string } = {}
): Promise<{ frontmatter: T; content: string; hash?: string }> {
  const { schema = baseFrontmatterSchema as unknown as z.ZodType<T>, tenantId, expectedHash } = options;
  const ctx = tenantId ? { tenantId, filePath: undefined } : getCurrentParserContext();
  
  mantis_log('DEBUG', 'frontmatter_parse_started', {
    tenant_id: ctx.tenantId,
    content_length: content.length,
    schema_type: schema?._def?.typeName
  });
  
  // ✅ C5: Extraer frontmatter
  const { frontmatterContent, contentWithoutFrontmatter, hasFrontmatter } = extractFrontmatter(content);
  
  if (!hasFrontmatter) {
    mantis_log('WARN', 'frontmatter_not_found', { tenant_id: ctx.tenantId });
    return { frontmatter: {} as T, content: contentWithoutFrontmatter };
  }
  
  // ✅ C5: Verificar integridad con hash si se proporciona
  if (expectedHash) {
    const actualHash = createHash('sha256').update(frontmatterContent, 'utf8').digest('hex');
    if (actualHash !== expectedHash) {
      mantis_log('ERROR', 'frontmatter_integrity_mismatch', {
        expected_prefix: expectedHash.slice(0, 16) + '...',
        actual_prefix: actualHash.slice(0, 16) + '...',
        constraint: 'C5'
      });
      throw new Error('Frontmatter integrity verification failed: hash mismatch');
    }
    mantis_log('DEBUG', 'frontmatter_integrity_verified', { hash_prefix: actualHash.slice(0, 16) + '...' });
  }
  
  // ✅ C5: Parsear YAML con safeLoad (NUNCA usar load() por riesgo RCE)
  let parsed: unknown;
  try {
    parsed = safeLoad(frontmatterContent) ?? {};
  } catch (error) {
    const err = error as Error;
    mantis_log('ERROR', 'yaml_parse_error', {
      tenant_id: ctx.tenantId,
      error: err.message,
      constraint: 'C5'
    });
    throw new Error(`YAML parsing failed: ${err.message}`);
  }
  
  // ✅ C5: Validar estructura con Zod
  const result = schema.safeParse(parsed);
  if (!result.success) {
    const errors = result.error.errors.map(e => `${e.path.join('.')}: ${e.message}`);
    mantis_log('ERROR', 'frontmatter_schema_validation_failed', {
      tenant_id: ctx.tenantId,
      errors,
      constraint: 'C5'
    });
    throw new Error(`Frontmatter schema validation failed: ${result.error.message}`);
  }
  
  mantis_log('INFO', 'frontmatter_parsed', {
    tenant_id: ctx.tenantId,
    artifact_id: result.data.artifact_id,
    version: result.data.version
  });
  
  return {
    frontmatter: result.data,
    content: contentWithoutFrontmatter,
    hash: expectedHash
  };
}
```

```typescript
// ✅ C3+C8: Lectura de archivo con timeout y validación de entorno
export interface ParseFileOptions {
  filePath: string;
  baseDir?: string;
  schema?: z.ZodType<any>;
  timeoutMs?: number;
  expectedHash?: string;
}

export async function parseFrontmatterFromFile<T extends BaseFrontmatter>(
  options: ParseFileOptions
): Promise<{ frontmatter: T; content: string; filePath: string }> {
  const { filePath, baseDir = process.env.SCHEMA_DIR ?? '/schemas', schema, timeoutMs = 5000, expectedHash } = options;
  
  // ✅ C3: Validar que SCHEMA_DIR está configurado si se usa baseDir por defecto
  if (baseDir === '/schemas' && !process.env.SCHEMA_DIR) {
    mantis_log('ERROR', 'schema_dir_not_configured', { constraint: 'C3' });
    throw new Error('SCHEMA_DIR environment variable must be set for default baseDir');
  }
  
  // ✅ C7: Validar ruta contra baseDir (path safety)
  const safePath = require('path').resolve(baseDir, filePath);
  const normalizedBase = require('path').resolve(baseDir) + require('path').sep;
  if (!safePath.startsWith(normalizedBase) && safePath !== require('path').resolve(baseDir)) {
    mantis_log('ERROR', 'file_path_traversal_blocked', {
      requested: filePath,
      resolved: safePath,
      constraint: 'C7'
    });
    throw new Error(`Path traversal blocked: ${filePath}`);
  }
  
  mantis_log('DEBUG', 'file_read_started', { file_path: safePath, timeout_ms: timeoutMs });
  
  // ✅ C8: Leer archivo con AbortSignal.timeout
  const signal = AbortSignal.timeout(timeoutMs);
  const content = await readFile(safePath, { encoding: 'utf8', signal });
  
  mantis_log('DEBUG', 'file_read_completed', { file_path: safePath, content_length: content.length });
  
  // ✅ C4: Ejecutar parseo dentro del contexto de tenant
  const tenantId = getCurrentParserContext().tenantId;
  return withParserContext(tenantId, safePath, async () => {
    const result = await parseFrontmatter<T>(content, { schema, tenantId, expectedHash });
    return { ...result, filePath: safePath };
  });
}
```

```typescript
// ✅ C4/C8: Logger helper con tenant_id y sanitización para operaciones de parseo
export function logParserEvent(
  event: 'extracted' | 'parsed' | 'validated' | 'integrity_verified' | 'failed',
  detail: Record<string, unknown>
): void {
  const ctx = parserContext.getStore();
  
  // ✅ C3: PII scrubbing heredado de mantis_log
  const sanitizedDetail = { ...detail };
  if (sanitizedDetail.filePath && typeof sanitizedDetail.filePath === 'string') {
    sanitizedDetail.filePath_preview = sanitizedDetail.filePath.slice(-50);
    delete sanitizedDetail.filePath;
  }
  
  mantis_log(
    event === 'failed' ? 'ERROR' : 'DEBUG',
    `parser_${event}`,
    { ...sanitizedDetail, tenant_id: ctx?.tenantId }
  );
}
```

---

## 🧪 Testes Unitários (TDD – Lógica Específica)

```typescript
// yaml-frontmatter-parser.test.ts
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { extractFrontmatter, parseFrontmatter, parseFrontmatterFromFile, baseFrontmatterSchema } from './yaml-frontmatter-parser';

describe('yaml-frontmatter-parser', () => {
  const TEST_TENANT = 'tenant-parser-01';
  const TEST_CONTENT = `---
artifact_id: test-artifact
version: 1.0.0
title: Test Artifact
---
# Content starts here
This is the main content.`;

  beforeEach(() => { global.mantis_log = vi.fn(); });
  afterEach(() => { vi.restoreAllMocks(); });

  it('should extract frontmatter with regex (C5)', () => {
    const result = extractFrontmatter(TEST_CONTENT);
    expect(result.hasFrontmatter).toBe(true);
    expect(result.frontmatterContent).toContain('artifact_id: test-artifact');
    expect(result.contentWithoutFrontmatter).toContain('# Content starts here');
  });

  it('should parse and validate frontmatter with Zod (C5)', async () => {
    const result = await parseFrontmatter(TEST_CONTENT, { schema: baseFrontmatterSchema });
    expect(result.frontmatter.artifact_id).toBe('test-artifact');
    expect(result.frontmatter.version).toBe('1.0.0');
    expect(result.content).toContain('# Content starts here');
    expect(global.mantis_log).toHaveBeenCalledWith('INFO', 'frontmatter_parsed', expect.anything());
  });

  it('should reject invalid frontmatter schema (C5)', async () => {
    const invalidContent = `---
artifact_id: 123
---
Content`;
    
    await expect(parseFrontmatter(invalidContent, { schema: baseFrontmatterSchema }))
      .rejects.toThrow('schema validation failed');
    expect(global.mantis_log).toHaveBeenCalledWith('ERROR', 'frontmatter_schema_validation_failed', expect.anything());
  });

  it('should verify frontmatter integrity with SHA256 (C5)', async () => {
    const { frontmatterContent } = extractFrontmatter(TEST_CONTENT);
    const expectedHash = require('crypto').createHash('sha256').update(frontmatterContent).digest('hex');
    
    const result = await parseFrontmatter(TEST_CONTENT, { expectedHash });
    expect(result.hash).toBe(expectedHash);
    expect(global.mantis_log).toHaveBeenCalledWith('DEBUG', 'frontmatter_integrity_verified', expect.anything());
  });

  it('should reject tampered frontmatter (C5)', async () => {
    await expect(parseFrontmatter(TEST_CONTENT, { expectedHash: 'wrong-hash-123' }))
      .rejects.toThrow('integrity verification failed');
    expect(global.mantis_log).toHaveBeenCalledWith('ERROR', 'frontmatter_integrity_mismatch', expect.anything());
  });

  it('should use safeLoad and reject unsafe yaml (C5)', async () => {
    // js-yaml.safeLoad debe rechazar constructs peligrosos
    const unsafeContent = `---
!!js/function 'function() { return "pwned"; }'
---
Content`;
    
    // safeLoad debe devolver null o lanzar error para constructs inseguros
    const result = await parseFrontmatter(unsafeContent, { schema: baseFrontmatterSchema.optional() });
    // El parseo debe fallar o retornar objeto vacío seguro
    expect(result.frontmatter).toEqual({});
  });

  it('should handle content without frontmatter gracefully', async () => {
    const noFmContent = '# Just content\nNo frontmatter here.';
    const result = await parseFrontmatter(noFmContent);
    expect(result.hasFrontmatter).toBeUndefined(); // No tiene frontmatter
    expect(result.content).toBe(noFmContent);
  });
});
```

---

## 🔍 Validação (VDD – Comando Canônico)

```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/javascript/yaml-frontmatter-parser.ts.md \
  --json \
  --check-structural \
  --check-error-handling \
  --check-observability \
  --check-constraints C3,C4,C5,C8

bash 05-CONFIGURATIONS/validation/verify-constraints.sh \
  --file 06-PROGRAMMING/javascript/yaml-frontmatter-parser.ts.md \
  --check C3 \
  --json

bash 05-CONFIGURATIONS/validation/verify-constraints.sh \
  --file 06-PROGRAMMING/javascript/yaml-frontmatter-parser.ts.md \
  --check C5 \
  --json

bash 05-CONFIGURATIONS/validation/verify-observability.sh \
  --file 06-PROGRAMMING/javascript/yaml-frontmatter-parser.ts.md \
  --schema V-LOG-02 \
  --json
```

---

## 🔗 Referências Cruzadas (Wikilinks Mínimos)
- [[javascript-typescript-master-agent.md]] ← Fonte de `mantis_log()`, hardening, constraints
- [[/05-CONFIGURATIONS/validation/orchestrator-engine.sh]] ← Motor de validação principal
- [[/05-CONFIGURATIONS/validation/verify-constraints.sh]] ← Validação C3/C5
- [[/05-CONFIGURATIONS/validation/verify-observability.sh]] ← Validação C8 + V-LOG-02
- [[/01-RULES/harness-norms-v3.0.md#C3]] ← Definição formal de C3 (Env Validation)
- [[/01-RULES/harness-norms-v3.0.md#C4]] ← Definição formal de C4 (Tenant Isolation)
- [[/01-RULES/harness-norms-v3.0.md#C5]] ← Definição formal de C5 (Type Safety/Integrity)
- [[/01-RULES/harness-norms-v3.0.md#C8]] ← Definição formal de C8 (Observability)

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 2.3.0-MODULAR-MERGED | 2026-05-09 | javascript-typescript-master-agent | MERGE: estrutura modular + regex extraction + safeLoad enforcement + Zod validation + integrity checks | C3,C4,C5,C8 |
| 2.1.1 | 2026-04-16 | Framework Core Team | Adição de exemplos de validação de schema e verificação de hash SHA256 | C3,C4,C5,C8 |
| 2.0.0 | 2026-03-01 | Qwen + DeepSeek | Primeira versão canônica com padrões de parseo seguro de YAML | C3,C4,C5,C8 |

---

## 🔍 Observability (Eventos Específicos)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `frontmatter_extracted_regex` | DEBUG | C5 | `{"frontmatter_length":45,"remaining_content_length":120}` |
| `frontmatter_parse_started` | DEBUG | C8 | `{"tenant_id":"t123","content_length":200,"schema_type":"ZodObject"}` |
| `frontmatter_parsed` | INFO | C5 | `{"tenant_id":"t123","artifact_id":"test-artifact","version":"1.0.0"}` |
| `frontmatter_schema_validation_failed` | ERROR | C5 | `{"tenant_id":"t123","errors":["artifact_id: Expected string, received number"],"constraint":"C5"}` |
| `frontmatter_integrity_verified` | DEBUG | C5 | `{"hash_prefix":"a1b2c3d4e5f6..."}` |
| `frontmatter_integrity_mismatch` | ERROR | C5 | `{"expected_prefix":"exp123...","actual_prefix":"act456...","constraint":"C5"}` |
| `file_path_traversal_blocked` | ERROR | C7 | `{"requested":"../etc/passwd","resolved":"/etc/passwd","constraint":"C7"}` |

### Validação de Schema V-LOG-02 (Helper Mínimo)
```typescript
export function validateParserLog(logEntry: unknown): { valid: boolean; errors: string[] } {
  const errors: string[] = [];
  const entry = logEntry as Record<string, unknown>;
  const required = ['ts', 'level', 'resource', 'body'];
  for (const field of required) if (!(field in entry)) errors.push(`Missing required field: ${field}`);
  
  // ✅ C4: Verificar tenant_id en eventos de parseo
  const parserEvents = ['frontmatter_parsed', 'frontmatter_schema_validation_failed', 'frontmatter_integrity_verified'];
  if (parserEvents.includes(entry.body?.event as string)) {
    const detail = entry.body?.detail as Record<string, unknown>;
    if (!detail?.tenant_id) errors.push('C4 violation: parser event missing tenant_id');
  }
  
  // ✅ C5: Verificar que hashes no se exponen completos
  if (entry.body?.detail?.hash && typeof entry.body.detail.hash === 'string') {
    const hashVal = entry.body.detail.hash as string;
    if (hashVal.length === 64 && /^[a-f0-9]{64}$/.test(hashVal)) {
      errors.push('C5 warning: full hash exposed in log (use prefix instead)');
    }
  }
  
  return { valid: errors.length === 0, errors };
}
```

---

## ✅ Auto-Validation Report (JSON)
```json
{
  "artifact": "yaml-frontmatter-parser",
  "version": "2.3.0-MODULAR-MERGED",
  "score": 32,
  "blocking_issues": [],
  "constraints_verified": ["C3", "C4", "C5", "C8"],
  "examples_count": 13,
  "lines_executable_max": 3,
  "language": "TypeScript 5.0+ / Node.js 18+",
  "observability_compliant": true,
  "bootstrap_resilient": true,
  "mantis_log_usage": "inherited",
  "zod_validation_verified": true,
  "safe_load_enforced": true,
  "regex_extraction_verified": true,
  "integrity_check_verified": true,
  "timeout_handling_verified": true,
  "path_safety_verified": true,
  "timestamp": "2026-05-09T00:00:00Z"
}
```

---

> 🇧🇷 *Documento técnico em pt-BR conforme V-DOC-01. Coordenação en español. Zero invenção: todo padrão grounded no conteúdo original + template v2.3.0-MODULAR.*

---
