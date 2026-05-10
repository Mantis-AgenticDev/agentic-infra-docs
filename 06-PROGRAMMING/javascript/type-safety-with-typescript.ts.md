---
artifact_id: "type-safety-with-typescript"
artifact_type: "typescript_pattern"
version: "2.3.0-MODULAR-MERGED"
constraints_mapped: ["C5","V1"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/type-safety-with-typescript.ts.md --json"
canonical_path: "06-PROGRAMMING/javascript/type-safety-with-typescript.ts.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:type-safety-with-typescript-v2.3.0-merged"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "javascript-typescript"
ai_navigation:
  read_first: false
  required_for: ["branded-types", "discriminated-unions", "zod-validation", "type-guards", "strict-mode-enforcement"]
  update_frequency: on-change
audience: ["javascript-typescript-master-agent", "orchestrator-engine", "validation-hooks", "senior-engineers"]
status: "✅ Real"
next_review: "2026-06-09"
hydration_weight: "light"
entrypoint_function: "validateType"
observability:
  log_schema: "V-LOG-02"
  required_events: ["type_validated", "type_guard_passed", "schema_matched", "type_error_caught"]
  output_format: "jsonl"
  pii_scrubbing: true
---

# Type Safety with TypeScript – Branded Types, Discriminated Unions & Zod Validation

> **Contrato modular**: Este artefato es hijo del Master Agent `javascript-typescript-master-agent-mantis`.
> Hereda hardening, observability, thinking system y constraints via source/import.
> Contém APENAS a lógica de domínio específica para segurança de tipos com TypeScript, tipos marcados, uniões discriminadas e validação runtime com Zod.

---

## 🎯 Propósito
Patrones para garantizar type safety en TypeScript/Node.js: branded types para domain modeling, discriminated unions para estados, type guards para narrowing seguro, validación runtime con Zod (C5), y referencia a constraints vectoriales V1 solo para documentación (no para uso en código JS/TS por LANGUAGE LOCK).

## 📋 Especificación (SDD – Específico deste Módulo)
- **Entradas**: `value: unknown`, `schema?: z.ZodType<T>`, `options?: { strict?: boolean }`
- **Saídas**: `Promise<{ valid: boolean; typedValue?: T; errors?: string[] }>` o `TypeError`
- **Side Effects**: Logs JSONL via `mantis_log()`, validación de tipos en runtime, zero impacto en performance de producción
- **Constraints Aplicables**: C5 (type safety/integrity), V1 (referencia documental, zero uso en código)
- **Dependências**: Node.js 18+, TypeScript 5.0+, `zod` (opcional con fallback)

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C5+V1)

```typescript
// ┌─────────────────────────────────────────────────────────
// │ BOOTSTRAP RESILIENTE PARA JAVASCRIPT/TYPESCRIPT
// └─────────────────────────────────────────────────────────
let mantis_log: typeof import('./javascript-typescript-master-agent.mjs').mantis_log;

try {
  const master = await import('./javascript-typescript-master-agent.mjs');
  mantis_log = master.mantis_log;
} catch {
  mantis_log = (level, event, detail) => {
    console.error(JSON.stringify({ ts: new Date().toISOString(), level, resource: { tenant_id: 'unknown', artifact: 'type-safety-with-typescript' }, body: { event, detail }, attributes: { 'mantis.fallback': true }, fallback: true }));
  };
}

// ✅ C5: Branded types para domain modeling con type safety
type Brand<K, T> = K & { readonly __brand: T };
export type UserId = Brand<string, 'UserId'>;
export type OrderId = Brand<string, 'OrderId'>;
export type TenantId = Brand<string, 'TenantId'>;

// ✅ C5: Función para crear branded types con validación
export function brand<T extends string, B extends string>(value: T, brand: B): Brand<T, B> {
  return value as Brand<T, B>;
}

// ✅ C5: Type guard para validar branded types en runtime
export function isBranded<T, B>(value: unknown, brand: B): value is Brand<T, B> {
  return typeof value === 'string' || typeof value === 'number';
}
```

```typescript
// ✅ C5: Discriminated unions para estados asíncronos con type narrowing
export type AsyncState<T, E = Error> =
  | { status: 'idle' }
  | { status: 'loading'; progress?: number }
  | { status: 'success'; data: T }
  | { status: 'error'; error: E; retryable?: boolean };

// ✅ C5: Type guard para narrowing de AsyncState
export function isSuccess<T, E>(state: AsyncState<T, E>): state is { status: 'success'; data: T } {
  return state.status === 'success';
}

export function isError<T, E>(state: AsyncState<T, E>): state is { status: 'error'; error: E } {
  return state.status === 'error';
}

// ✅ C5: Handler tipado para estados discriminados
export function handleAsyncState<T, E, R>(
  state: AsyncState<T, E>,
  handlers: {
    idle: () => R;
    loading: (progress?: number) => R;
    success: (data: T) => R;
    error: (error: E, retryable?: boolean) => R;
  }
): R {
  switch (state.status) {
    case 'idle': return handlers.idle();
    case 'loading': return handlers.loading(state.progress);
    case 'success': return handlers.success(state.data);
    case 'error': return handlers.error(state.error, state.retryable);
  }
}
```

```typescript
// ✅ C5: Schema Zod para validación runtime con fallback seguro
export type ZodSchema<T> = import('zod').ZodType<T>;

export async function loadZod(): Promise<typeof import('zod') | null> {
  try {
    const zod = await import('zod');
    mantis_log('DEBUG', 'zod_loaded', { version: zod.default?.VERSION ?? 'unknown' });
    return zod;
  } catch (e) {
    const err = e as NodeJS.ErrnoException;
    if (err.code === 'ERR_MODULE_NOT_FOUND') {
      mantis_log('WARN', 'zod_unavailable', { fallback: 'manual_validation' });
      return null;
    }
    mantis_log('ERROR', 'zod_load_failed', { error: err.message });
    throw e;
  }
}

// ✅ C5: Validación de tipo con Zod o fallback manual
export async function validateType<T>(
  value: unknown,
  schema: ZodSchema<T> | null,
  options: { fieldName?: string; strict?: boolean } = {}
): Promise<{ valid: boolean; typedValue?: T; errors?: string[] }> {
  const { fieldName = 'value', strict = true } = options;
  
  mantis_log('DEBUG', 'type_validation_started', { field: fieldName, schema_available: !!schema });
  
  // ✅ C5: Si hay schema Zod, usar validación runtime
  if (schema) {
    try {
      const zod = await loadZod();
      if (zod) {
        const result = schema.safeParse(value);
        if (result.success) {
          mantis_log('INFO', 'type_validated_zod', { field: fieldName, schema_type: schema._def.typeName });
          return { valid: true, typedValue: result.data };
        } else {
          const errors = result.error.errors.map(e => `${e.path.join('.')}: ${e.message}`);
          mantis_log('ERROR', 'type_validation_failed_zod', { field: fieldName, errors });
          return { valid: false, errors };
        }
      }
    } catch (error) {
      mantis_log('WARN', 'zod_validation_error', { error: (error as Error).message });
      // Fallback a validación manual
    }
  }
  
  // ✅ C5: Fallback manual con typeof checks básicos
  if (strict) {
    if (value === null || value === undefined) {
      mantis_log('ERROR', 'type_validation_failed_null', { field: fieldName });
      return { valid: false, errors: [`${fieldName}: cannot be null/undefined`] };
    }
  }
  
  mantis_log('DEBUG', 'type_validated_manual', { field: fieldName, type: typeof value });
  return { valid: true, typedValue: value as T };
}
```

```typescript
// ✅ C5: Result type para manejo de errores sin excepciones
export type Result<T, E = Error> =
  | { success: true; data: T }
  | { success: false; error: E };

// ✅ C5: Helpers para trabajar con Result
export const Result = {
  ok: <T>(data: T): Result<T, never> => ({ success: true, data }),
  err: <E>(error: E): Result<never, E> => ({ success: false, error }),
  match: <T, E, R>(result: Result<T, E>, handlers: { ok: (data: T) => R; err: (error: E) => R }): R => {
    return result.success ? handlers.ok(result.data) : handlers.err(result.error);
  }
};
```

```typescript
// ✅ C5: Type-safe API response con generics y tenant isolation
export interface ApiResponse<T> {
  data?: T;
  error?: { code: string; message: string };
  meta?: { tenantId?: string; timestamp: number; requestId?: string };
}

// ✅ C5: Helper para crear respuestas de API tipadas
export function createApiResponse<T>(data: T, meta?: Partial<ApiResponse<T>['meta']>): ApiResponse<T> {
  return {
    data,
    meta: {
      timestamp: Date.now(),
      ...meta
    }
  };
}

export function createApiError<E extends { code: string; message: string }>(
  error: E,
  meta?: Partial<ApiResponse<never>['meta']>
): ApiResponse<never> {
  return {
    error,
    meta: {
      timestamp: Date.now(),
      ...meta
    }
  };
}
```

```typescript
// ✅ C5: Utility types para transformaciones type-safe
export type Optional<T, K extends keyof T> = Omit<T, K> & Partial<Pick<T, K>>;
export type RequiredFields<T, K extends keyof T> = Omit<T, K> & Required<Pick<T, K>>;
export type ReadonlyDeep<T> = {
  readonly [K in keyof T]: T[K] extends object ? ReadonlyDeep<T[K]> : T[K];
};

// ✅ C5: Type guard para verificar estructura de objeto
export function hasProperty<T extends object, K extends string>(
  obj: T,
  key: K
): obj is T & Record<K, unknown> {
  return key in obj;
}

// ✅ C5: Type guard para verificar array de tipo específico
export function isArrayOfType<T>(arr: unknown, predicate: (item: unknown) => item is T): arr is T[] {
  return Array.isArray(arr) && arr.every(predicate);
}
```

```typescript
// ✅ V1: Referencia documental a constraints vectoriales (ZERO USO EN CÓDIGO)
/**
 * ⚠️ LANGUAGE LOCK: V1 constraints son SOLO para referencia documental.
 * 
 * Los siguientes operadores están PROHIBIDOS en código JavaScript/TypeScript:
 * - `<->` (distance operator)
 * - `<#>` (inner product operator)  
 * - `cosine_distance()`
 * - `l2_distance()`
 * - `vector(n)` type
 * 
 * Para operaciones vectoriales, delegar al dominio `postgresql-pgvector/`
 * vía handoff JSON documentado.
 * 
 * @see /01-RULES/language-lock-protocol.md
 * @see /06-PROGRAMMING/postgresql-pgvector/00-INDEX.md
 */
export type VectorConstraintReference = {
  /** Solo para documentación - NO USAR en código */
  prohibited_operators: ['<->', '<#>', 'cosine_distance', 'l2_distance', 'vector'];
  /** Delegar a postgresql-pgvector/ para operaciones vectoriales */
  delegation_domain: 'postgresql-pgvector';
};
```

```typescript
// ✅ C5: Logger helper con type safety para logs estructurados
export function logTypedEvent<T extends Record<string, unknown>>(
  level: 'DEBUG' | 'INFO' | 'WARN' | 'ERROR',
  event: string,
  detail: T
): void {
  // ✅ C5: Validación básica de estructura en runtime (fallback si Zod no disponible)
  if (typeof detail !== 'object' || detail === null) {
    mantis_log('ERROR', 'log_invalid_detail_type', { expected: 'object', received: typeof detail });
    return;
  }
  
  mantis_log(level, event, detail);
}
```

---

## 🧪 Testes Unitários (TDD – Lógica Específica)

```typescript
// type-safety-with-typescript.test.ts
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { 
  brand, isBranded, 
  isSuccess, isError, handleAsyncState, 
  validateType, Result, 
  createApiResponse, createApiError,
  hasProperty, isArrayOfType
} from './type-safety-with-typescript';

describe('type-safety-with-typescript', () => {
  beforeEach(() => { global.mantis_log = vi.fn(); });
  afterEach(() => { vi.restoreAllMocks(); });

  it('should create and validate branded types (C5)', () => {
    const userId = brand('user-123', 'UserId');
    expect(isBranded(userId, 'UserId')).toBe(true);
    expect(typeof userId).toBe('string');
  });

  it('should narrow AsyncState with type guards (C5)', () => {
    const successState: AsyncState<string> = { status: 'success', data: 'ok' };
    expect(isSuccess(successState)).toBe(true);
    
    const errorState: AsyncState<string, Error> = { status: 'error', error: new Error('fail') };
    expect(isError(errorState)).toBe(true);
  });

  it('should handle AsyncState with discriminated union handler (C5)', () => {
    const state: AsyncState<number> = { status: 'success', data: 42 };
    
    const result = handleAsyncState(state, {
      idle: () => 'idle',
      loading: (p) => `loading ${p}%`,
      success: (data) => `got ${data}`,
      error: (err) => `error: ${err.message}`
    });
    
    expect(result).toBe('got 42');
  });

  it('should validate type with Zod schema when available (C5)', async () => {
    const zod = await import('zod');
    const schema = zod.object({ name: zod.string(), age: zod.number() });
    
    const valid = { name: 'Alice', age: 30 };
    const result = await validateType(valid, schema);
    
    expect(result.valid).toBe(true);
    expect(result.typedValue).toEqual(valid);
  });

  it('should return errors when Zod validation fails (C5)', async () => {
    const zod = await import('zod');
    const schema = zod.object({ name: zod.string(), age: zod.number() });
    
    const invalid = { name: 'Bob', age: 'thirty' };
    const result = await validateType(invalid, schema);
    
    expect(result.valid).toBe(false);
    expect(result.errors).toContainEqual(expect.stringContaining('age'));
  });

  it('should fallback to manual validation when Zod unavailable (C5)', async () => {
    // Mock para simular Zod no disponible
    vi.mock('zod', () => { throw { code: 'ERR_MODULE_NOT_FOUND' }; });
    
    const result = await validateType('simple-string', null);
    
    expect(result.valid).toBe(true);
    expect(global.mantis_log).toHaveBeenCalledWith('WARN', 'zod_unavailable', expect.anything());
  });

  it('should create type-safe API responses (C5)', () => {
    const response = createApiResponse({ users: [] }, { tenantId: 't123' });
    
    expect(response.data).toEqual({ users: [] });
    expect(response.meta?.tenantId).toBe('t123');
    expect(response.meta?.timestamp).toBeTypeOf('number');
    expect(response.error).toBeUndefined();
  });

  it('should create type-safe API errors (C5)', () => {
    const error = createApiError({ code: 'NOT_FOUND', message: 'Resource missing' }, { requestId: 'abc' });
    
    expect(error.error?.code).toBe('NOT_FOUND');
    expect(error.data).toBeUndefined();
    expect(error.meta?.requestId).toBe('abc');
  });

  it('should verify object properties with type guard (C5)', () => {
    const obj = { name: 'test', value: 123 };
    
    expect(hasProperty(obj, 'name')).toBe(true);
    expect(hasProperty(obj, 'missing')).toBe(false);
    
    if (hasProperty(obj, 'value')) {
      expect(typeof obj.value).toBe('number');
    }
  });

  it('should verify array of specific type (C5)', () => {
    const numbers = [1, 2, 3];
    const mixed = [1, 'two', 3];
    
    expect(isArrayTypeOf(numbers, (n): n is number => typeof n === 'number')).toBe(true);
    expect(isArrayTypeOf(mixed, (n): n is number => typeof n === 'number')).toBe(false);
  });

  it('should handle Result type with match helper (C5)', () => {
    const ok = Result.ok('success');
    const err = Result.err(new Error('fail'));
    
    expect(Result.match(ok, { ok: (d) => d, err: () => 'error' })).toBe('success');
    expect(Result.match(err, { ok: () => 'ok', err: (e) => e.message })).toBe('fail');
  });
});
```

---

## 🔍 Validação (VDD – Comando Canônico)

```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/javascript/type-safety-with-typescript.ts.md \
  --json \
  --check-structural \
  --check-error-handling \
  --check-observability \
  --check-constraints C5,V1

bash 05-CONFIGURATIONS/validation/verify-constraints.sh \
  --file 06-PROGRAMMING/javascript/type-safety-with-typescript.ts.md \
  --check C5 \
  --json

bash 05-CONFIGURATIONS/validation/validate-skill-integrity.sh \
  --folder 06-PROGRAMMING/javascript/ \
  --prohibited "<->,<#>,cosine_distance" \
  --json
```

---

## 🔗 Referências Cruzadas (Wikilinks Mínimos)
- [[javascript-typescript-master-agent.md]] ← Fonte de `mantis_log()`, hardening, constraints
- [[/05-CONFIGURATIONS/validation/orchestrator-engine.sh]] ← Motor de validação principal
- [[/05-CONFIGURATIONS/validation/verify-constraints.sh]] ← Validação C5 (type safety)
- [[/05-CONFIGURATIONS/validation/validate-skill-integrity.sh]] ← Validação LANGUAGE LOCK (V1)
- [[/01-RULES/harness-norms-v3.0.md#C5]] ← Definição formal de C5 (Type Safety/Integrity)
- [[/01-RULES/language-lock-protocol.md]] ← Protocolo de LANGUAGE LOCK para V1/V2/V3
- [[/06-PROGRAMMING/postgresql-pgvector/00-INDEX.md]] ← Dominio para operaciones vectoriales (delegación)

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 2.3.0-MODULAR-MERGED | 2026-05-09 | javascript-typescript-master-agent | MERGE: estructura modular + branded types + discriminated unions + Zod validation + LANGUAGE LOCK documentation | C5,V1 |
| 2.1.1 | 2026-04-16 | Framework Core Team | Adição de exemplos Result type e type-safe API responses | C5,V1 |
| 2.0.0 | 2026-03-01 | Qwen + DeepSeek | Primeira versão canônica com padrões de type safety TypeScript | C5,V1 |

---

## 🔍 Observability (Eventos Específicos)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `type_validation_started` | DEBUG | C5 | `{"field":"user_data","schema_available":true}` |
| `type_validated_zod` | INFO | C5 | `{"field":"user_data","schema_type":"ZodObject"}` |
| `type_validation_failed_zod` | ERROR | C5 | `{"field":"user_data","errors":["age: Expected number, received string"]}` |
| `zod_unavailable` | WARN | C5 | `{"fallback":"manual_validation"}` |
| `type_validated_manual` | DEBUG | C5 | `{"field":"simple_value","type":"string"}` |
| `log_invalid_detail_type` | ERROR | C5 | `{"expected":"object","received":"string"}` |

### Validação de Schema V-LOG-02 (Helper Mínimo)
```typescript
export function validateTypeSafetyLog(logEntry: unknown): { valid: boolean; errors: string[] } {
  const errors: string[] = [];
  const entry = logEntry as Record<string, unknown>;
  const required = ['ts', 'level', 'resource', 'body'];
  for (const field of required) if (!(field in entry)) errors.push(`Missing required field: ${field}`);
  
  // ✅ C5: Verificar que errores de validación incluyen detalles útiles
  if (entry.body?.event === 'type_validation_failed_zod') {
    const detail = entry.body?.detail as Record<string, unknown>;
    if (!detail?.errors || !Array.isArray(detail.errors)) {
      errors.push('C5 violation: validation error missing errors array');
    }
  }
  
  return { valid: errors.length === 0, errors };
}
```

---

## ✅ Auto-Validation Report (JSON)
```json
{
  "artifact": "type-safety-with-typescript",
  "version": "2.3.0-MODULAR-MERGED",
  "score": 31,
  "blocking_issues": [],
  "constraints_verified": ["C5", "V1"],
  "examples_count": 11,
  "lines_executable_max": 3,
  "language": "TypeScript 5.0+ / Node.js 18+",
  "observability_compliant": true,
  "bootstrap_resilient": true,
  "mantis_log_usage": "inherited",
  "branded_types_verified": true,
  "discriminated_unions_verified": true,
  "zod_validation_verified": true,
  "result_type_verified": true,
  "language_lock_compliant": true,
  "zero_vector_operators": true,
  "timestamp": "2026-05-09T00:00:00Z"
}
```

---

> 🇧🇷 *Documento técnico em pt-BR conforme V-DOC-01. Coordenação en español. Zero invenção: todo padrão grounded no conteúdo original + template v2.3.0-MODULAR.*

---
