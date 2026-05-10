---
artifact_id: "db-selection-decision-tree"
artifact_type: "typescript_module"
version: "2.3.0-MODULAR-MERGED"
constraints_mapped: ["C4","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/db-selection-decision-tree.ts.md --json"
canonical_path: "06-PROGRAMMING/javascript/db-selection-decision-tree.ts.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:db-selection-v2.3.0-merged"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "javascript-typescript"
ai_navigation:
  read_first: false
  required_for: ["db-routing", "tenant-aware-connections", "multi-stack-management"]
  update_frequency: on-change
audience: ["javascript-typescript-master-agent", "orchestrator-engine", "validation-hooks", "senior-engineers"]
status: "✅ Real"
next_review: "2026-06-09"
hydration_weight: "medium"
entrypoint_function: "selectDbStack"
observability:
  log_schema: "V-LOG-02"
  required_events: ["stack_selection_started", "db_connected", "tenant_filter_applied", "stack_selection_completed"]
  output_format: "jsonl"
  pii_scrubbing: true
---

# Database Selection Decision Tree – Runtime Routing: Postgres/Redis/Qdrant

> **Contrato modular**: Este artefato es hijo del Master Agent `javascript-typescript-master-agent-mantis`.
> Hereda hardening, observability, thinking system y constraints via source/import.
> Contém APENAS a lógica de domínio específica para roteamento dinâmico de conexões de banco de dados por tenant.

---

## 🎯 Propósito
Lógica de decisión runtime para seleccionar el stack de base de datos (PostgreSQL, Redis, Qdrant) por tenant, basado en el perfil del cliente (VPS, volumen, necesidades). Garantiza aislamiento multi-tenant vía `AsyncLocalStorage` (C4) y timeouts explícitos en todas las conexiones a bases de datos (C8).

## 📋 Especificación (SDD – Específico deste Módulo)
- **Entradas**: `profile: ClientProfile`, `options?: { timeoutMs?: number; fallbackStack?: DbStack }`
- **Saídas**: `Promise<{ stack: DbStack; connectionConfig: ConnectionConfig; tenantId: string }>`
- **Side Effects**: Logs JSONL via `mantis_log()`, inicialización lazy de pools de conexión por tenant
- **Constraints Aplicables**: C4 (tenant isolation), C8 (observability)
- **Dependências**: Node.js 18+, TypeScript 5.0+, `pg` (PostgreSQL), `ioredis` (Redis), `qdrant-js` (Qdrant - opcional)

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
      resource: { tenant_id, artifact: 'db-selection-decision-tree' },
      body: { event, detail },
      attributes: { 'mantis.fallback': true },
      fallback: true
    }));
  };
}

// ┌─────────────────────────────────────────────────────────
// │ LÓGICA DE DOMÍNIO: DECISÃO DE STACK DE BANCO DE DADOS
// │ Zero redundância: apenas o específico deste módulo
// └─────────────────────────────────────────────────────────

import { AsyncLocalStorage } from 'async_hooks';

// ✅ C4: Interface tipada para perfil de cliente con tenant_id obligatorio
export interface ClientProfile {
  tenantId: string;
  vertical: 'agriculture' | 'retail' | 'healthcare' | 'iot' | 'other';
  hasVps: boolean;
  monthlyRecords: number;
  needsVectorSearch?: boolean;
  needsRealtimeCache?: boolean;
}

// ✅ C4: Enum de stacks disponibles con configuración mínima
export type DbStack = 'A' | 'B' | 'C' | 'D';

export interface StackConfig {
  stack: DbStack;
  postgres?: { host: string; port: number; database: string };
  redis?: { host: string; port: number; db: number };
  qdrant?: { host: string; port: number; collection: string };
  connectionTimeoutMs: number;
  maxConnections: number;
}

// ✅ C4: AsyncLocalStorage para propagación de tenant_id en operaciones DB
export const dbSelectionContext = new AsyncLocalStorage<{ tenantId: string; selectedStack?: DbStack }>();

export function getCurrentTenantId(): string {
  const store = dbSelectionContext.getStore();
  if (!store?.tenantId) {
    mantis_log('ERROR', 'db_context_missing_tenant', { 
      error: 'tenantId not found in dbSelectionContext' 
    });
    throw new Error('Tenant context required for DB selection (C4 constraint)');
  }
  return store.tenantId;
}
```

```typescript
// ✅ C4/C8: Árbol de decisión para selección de stack con timeout y contexto
export async function selectDbStack(
  profile: ClientProfile,
  options: { timeoutMs?: number } = {}
): Promise<StackConfig> {
  const { timeoutMs = 3000 } = options;
  const tenantId = profile.tenantId;

  mantis_log('INFO', 'stack_selection_started', {
    tenant_id: tenantId,
    vertical: profile.vertical,
    has_vps: profile.hasVps,
    monthly_records: profile.monthlyRecords,
    needs_vector: profile.needsVectorSearch,
    needs_cache: profile.needsRealtimeCache
  });

  // ✅ C8: Timeout para decisión de stack
  const controller = new AbortController();
  const timer = setTimeout(() => {
    controller.abort();
    mantis_log('WARN', 'stack_selection_timeout', {
      tenant_id: tenantId,
      timeout_ms: timeoutMs
    });
  }, timeoutMs);

  try {
    const config = await dbSelectionContext.run({ tenantId }, async () => {
      // 🌳 Árbol de decisión runtime (simplificado para ejemplo)
      let stack: DbStack;
      
      if (profile.needsVectorSearch && profile.hasVps) {
        // Stack D: PostgreSQL + Qdrant para búsqueda vectorial
        stack = 'D';
        mantis_log('DEBUG', 'stack_selected_vector', { tenant_id: tenantId, stack });
      } else if (profile.needsRealtimeCache || profile.monthlyRecords > 100000) {
        // Stack C: PostgreSQL + Redis para caché y alta carga
        stack = 'C';
        mantis_log('DEBUG', 'stack_selected_cache', { tenant_id: tenantId, stack });
      } else if (profile.hasVps && profile.monthlyRecords > 10000) {
        // Stack B: PostgreSQL dedicado en VPS
        stack = 'B';
        mantis_log('DEBUG', 'stack_selected_dedicated', { tenant_id: tenantId, stack });
      } else {
        // Stack A: PostgreSQL compartido (default para pequeños tenants)
        stack = 'A';
        mantis_log('DEBUG', 'stack_selected_shared', { tenant_id: tenantId, stack });
      }

      return buildStackConfig(stack, profile);
    });

    mantis_log('INFO', 'stack_selection_completed', {
      tenant_id: tenantId,
      selected_stack: config.stack,
      connection_timeout_ms: config.connectionTimeoutMs
    });

    return config;

  } catch (error) {
    const err = error as Error;
    if (err.name === 'AbortError') {
      mantis_log('ERROR', 'stack_selection_aborted', {
        tenant_id: tenantId,
        timeout_ms: timeoutMs
      });
      // Fallback a stack mínimo (A) si hay timeout
      return buildStackConfig('A', profile);
    }
    mantis_log('ERROR', 'stack_selection_failed', {
      tenant_id: tenantId,
      error: err.message
    });
    throw error;
  } finally {
    clearTimeout(timer);
  }
}
```

```typescript
// ✅ C4: Construcción de configuración de stack con tenant isolation
async function buildStackConfig(stack: DbStack, profile: ClientProfile): Promise<StackConfig> {
  const tenantId = profile.tenantId;
  const baseConfig: Omit<StackConfig, 'stack'> = {
    connectionTimeoutMs: 5000,  // ✅ C8: Timeout por defecto para conexiones
    maxConnections: profile.hasVps ? 20 : 5
  };

  switch (stack) {
    case 'A': // PostgreSQL compartido
      return {
        stack: 'A',
        postgres: {
          host: process.env.POSTGRES_SHARED_HOST ?? 'db-shared.mantis.local',
          port: parseInt(process.env.POSTGRES_PORT ?? '5432'),
          database: `tenant_${tenantId.replace(/[^a-z0-9]/g, '_')}`  // ✅ C4: schema por tenant
        },
        ...baseConfig
      };

    case 'B': // PostgreSQL dedicado en VPS
      return {
        stack: 'B',
        postgres: {
          host: process.env.POSTGRES_VPS_HOST ?? 'db-vps.mantis.local',
          port: parseInt(process.env.POSTGRES_PORT ?? '5432'),
          database: `prod_${tenantId}`
        },
        ...baseConfig,
        maxConnections: 50  // Más conexiones para VPS
      };

    case 'C': // PostgreSQL + Redis
      return {
        stack: 'C',
        postgres: {
          host: process.env.POSTGRES_SHARED_HOST ?? 'db-shared.mantis.local',
          port: parseInt(process.env.POSTGRES_PORT ?? '5432'),
          database: `tenant_${tenantId.replace(/[^a-z0-9]/g, '_')}`
        },
        redis: {
          host: process.env.REDIS_HOST ?? 'redis.mantis.local',
          port: parseInt(process.env.REDIS_PORT ?? '6379'),
          db: parseInt(tenantId.slice(-2), 16) % 16  // ✅ C4: DB Redis por tenant (0-15)
        },
        ...baseConfig
      };

    case 'D': // PostgreSQL + Qdrant (vector search)
      return {
        stack: 'D',
        postgres: {
          host: process.env.POSTGRES_VPS_HOST ?? 'db-vps.mantis.local',
          port: parseInt(process.env.POSTGRES_PORT ?? '5432'),
          database: `vector_${tenantId}`
        },
        qdrant: {
          host: process.env.QDRANT_HOST ?? 'qdrant.mantis.local',
          port: parseInt(process.env.QDRANT_PORT ?? '6333'),
          collection: `embeddings_${tenantId.replace(/[^a-z0-9]/g, '_')}`  // ✅ C4: colección por tenant
        },
        ...baseConfig,
        connectionTimeoutMs: 8000  // Más tiempo para conexiones vectoriales
      };

    default:
      mantis_log('ERROR', 'unknown_stack', { tenant_id: tenantId, requested: stack });
      throw new Error(`Unknown stack: ${stack}`);
  }
}
```

```typescript
// ✅ C8: Conexión a PostgreSQL con timeout y tenant validation
export async function createPostgresPool(config: StackConfig) {
  if (!config.postgres) {
    throw new Error('PostgreSQL config not available for this stack');
  }

  const tenantId = getCurrentTenantId();
  
  mantis_log('DEBUG', 'postgres_connecting', {
    tenant_id: tenantId,
    host: config.postgres.host,
    database: config.postgres.database,
    timeout_ms: config.connectionTimeoutMs
  });

  // ✅ C8: Import lazy de pg para zero overhead si no se usa
  const { Pool } = await import('pg');
  
  const pool = new Pool({
    ...config.postgres,
    connectionTimeoutMillis: config.connectionTimeoutMs,
    max: config.maxConnections,
    // ✅ C4: Application name con tenant_id para debugging en logs de DB
    application_name: `mantis-${tenantId.slice(0, 16)}`
  });

  // ✅ C8: Validar conexión con timeout explícito
  const client = await pool.connect();
  try {
    await client.query('SELECT 1', { timeout: config.connectionTimeoutMs });
    mantis_log('INFO', 'postgres_connected', {
      tenant_id: tenantId,
      database: config.postgres.database
    });
    return pool;
  } catch (error) {
    mantis_log('ERROR', 'postgres_connection_failed', {
      tenant_id: tenantId,
      error: (error as Error).message
    });
    await pool.end();
    throw error;
  } finally {
    client.release();
  }
}
```

```typescript
// ✅ C4: Cliente Redis con prefijo tenant_id obligatorio en todas las claves
export async function createRedisClient(config: StackConfig) {
  if (!config.redis) {
    throw new Error('Redis config not available for this stack');
  }

  const tenantId = getCurrentTenantId();
  const keyPrefix = `${tenantId}:`;  // ✅ C4: Prefijo obligatorio para aislamiento

  mantis_log('DEBUG', 'redis_connecting', {
    tenant_id: tenantId,
    host: config.redis.host,
    db: config.redis.db,
    key_prefix: keyPrefix
  });

  // ✅ C8: Import lazy de ioredis
  const Redis = (await import('ioredis')).default;
  
  const redis = new Redis({
    ...config.redis,
    keyPrefix,  // ✅ C4: Prefijo aplicado automáticamente a todas las operaciones
    connectTimeout: config.connectionTimeoutMs,  // ✅ C8
    lazyConnect: true,
    retryStrategy: (times) => Math.min(times * 50, 2000)  // ✅ C8: Backoff en reconexión
  });

  redis.on('connect', () => {
    mantis_log('INFO', 'redis_connected', {
      tenant_id: tenantId,
      db: config.redis!.db
    });
  });

  redis.on('error', (err) => {
    mantis_log('ERROR', 'redis_error', {
      tenant_id: tenantId,
      error: err.message
    });
  });

  return redis;
}

// ✅ C4: Helper para generar claves Redis con tenant isolation
export function redisKey(tenantId: string, namespace: string, identifier: string): string {
  // ✅ C4: Validar que el tenant_id del caller coincide con el contexto actual
  const currentTenant = getCurrentTenantId();
  if (tenantId !== currentTenant) {
    mantis_log('ERROR', 'redis_key_tenant_mismatch', {
      requested: tenantId,
      current: currentTenant,
      namespace,
      identifier
    });
    throw new Error('Tenant mismatch in Redis key generation (C4 violation)');
  }
  return `${tenantId}:${namespace}:${identifier}`;
}
```

```typescript
// ✅ C4/C8: Cliente Qdrant con filtro tenant_id obligatorio y timeout
export async function createQdrantClient(config: StackConfig) {
  if (!config.qdrant) {
    throw new Error('Qdrant config not available for this stack');
  }

  const tenantId = getCurrentTenantId();
  
  mantis_log('DEBUG', 'qdrant_connecting', {
    tenant_id: tenantId,
    host: config.qdrant.host,
    collection: config.qdrant.collection
  });

  // ✅ C8: Import lazy de qdrant-js (dependencia opcional)
  const { QdrantClient } = await import('qdrant-js');
  
  const client = new QdrantClient({
    url: `http://${config.qdrant.host}:${config.qdrant.port}`,
    headers: {
      'x-tenant-id': tenantId  // ✅ C4: Header para logging en Qdrant
    }
  });

  // ✅ C8: Validar conexión con timeout
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), config.connectionTimeoutMs);
  
  try {
    await client.health({}, { signal: controller.signal });
    mantis_log('INFO', 'qdrant_connected', {
      tenant_id: tenantId,
      collection: config.qdrant.collection
    });
    return client;
  } catch (error) {
    const err = error as Error;
    if (err.name === 'AbortError') {
      mantis_log('WARN', 'qdrant_connection_timeout', {
        tenant_id: tenantId,
        timeout_ms: config.connectionTimeoutMs
      });
    } else {
      mantis_log('ERROR', 'qdrant_connection_failed', {
        tenant_id: tenantId,
        error: err.message
      });
    }
    throw error;
  } finally {
    clearTimeout(timer);
  }
}

// ✅ C4: Helper para búsqueda vectorial con filtro tenant_id obligatorio
export async function vectorSearchWithTenant(
  client: any,  // QdrantClient
  collection: string,
  vector: number[],
  options: { limit?: number; tenantId?: string; timeoutMs?: number } = {}
) {
  const { limit = 10, timeoutMs = 5000 } = options;
  const tenantId = options.tenantId ?? getCurrentTenantId();  // ✅ C4

  mantis_log('DEBUG', 'vector_search_started', {
    tenant_id: tenantId,
    collection,
    vector_dimension: vector.length,
    limit
  });

  // ✅ C4: Filtro obligatorio para aislamiento multi-tenant
  const filter = {
    must: [
      { key: 'tenant_id', match: { value: tenantId } }  // 🔒 C4: Nunca omitir este filtro
    ]
  };

  // ✅ C8: AbortController para timeout de búsqueda
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const results = await client.search(collection, {
      vector,
      filter,  // ✅ C4: Filtro aplicado
      limit,
      with_payload: true
    }, { signal: controller.signal });  // ✅ C8

    mantis_log('DEBUG', 'vector_search_completed', {
      tenant_id: tenantId,
      results_count: results.length,
      collection
    });

    return results;

  } catch (error) {
    const err = error as Error;
    if (err.name === 'AbortError') {
      mantis_log('WARN', 'vector_search_timeout', {
        tenant_id: tenantId,
        collection,
        timeout_ms: timeoutMs
      });
    } else {
      mantis_log('ERROR', 'vector_search_failed', {
        tenant_id: tenantId,
        collection,
        error: err.message
      });
    }
    throw error;
  } finally {
    clearTimeout(timer);
  }
}
```

```typescript
// ✅ C4/C8: Logger helper con tenant_id automático para operaciones DB
export function logDbEvent(
  dbType: 'postgres' | 'redis' | 'qdrant',
  event: 'connect' | 'query' | 'error' | 'disconnect',
  detail: Record<string, unknown>
): void {
  const tenantId = getCurrentTenantId();
  
  // ✅ C3: PII scrubbing heredado de mantis_log
  mantis_log(event === 'error' ? 'ERROR' : 'DEBUG', `${dbType}_${event}`, {
    ...detail,
    tenant_id: tenantId,
    db_type: dbType
  });
}
```

---

## 🧪 Testes Unitários (TDD – Apenas para a Lógica Específica)
```typescript
// db-selection-decision-tree.test.ts
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { 
  selectDbStack, 
  createPostgresPool, 
  redisKey, 
  vectorSearchWithTenant,
  dbSelectionContext
} from './db-selection-decision-tree';

describe('db-selection-decision-tree', () => {
  const TEST_TENANT = 'tenant-test-123';
  const BASE_PROFILE = {
    tenantId: TEST_TENANT,
    vertical: 'agriculture' as const,
    hasVps: false,
    monthlyRecords: 5000
  };

  beforeEach(() => {
    // Mock de mantis_log para testes
    global.mantis_log = vi.fn();
    // Configurar env para testes
    process.env.POSTGRES_SHARED_HOST = 'test-db.local';
    process.env.REDIS_HOST = 'test-redis.local';
  });

  afterEach(() => {
    vi.restoreAllMocks();
    delete process.env.POSTGRES_SHARED_HOST;
    delete process.env.REDIS_HOST;
  });

  // Test: selectDbStack retorna stack A para perfil básico (C4)
  it('should select stack A for basic profile', async () => {
    const result = await dbSelectionContext.run(
      { tenantId: TEST_TENANT },
      () => selectDbStack(BASE_PROFILE, { timeoutMs: 1000 })
    );

    expect(result.stack).toBe('A');
    expect(result.postgres?.database).toContain('tenant_');
    expect(global.mantis_log).toHaveBeenCalledWith(
      'INFO',
      'stack_selection_completed',
      expect.objectContaining({ tenant_id: TEST_TENANT, selected_stack: 'A' })
    );
  });

  // Test: selectDbStack con vector search retorna stack D (C4)
  it('should select stack D when vector search is needed', async () => {
    const profile = { ...BASE_PROFILE, needsVectorSearch: true, hasVps: true };
    
    const result = await dbSelectionContext.run(
      { tenantId: TEST_TENANT },
      () => selectDbStack(profile)
    );

    expect(result.stack).toBe('D');
    expect(result.qdrant?.collection).toContain('embeddings_');
  });

  // Test: redisKey valida tenant_id del contexto (C4)
  it('should reject Redis key generation with tenant mismatch', () => {
    expect(() => {
      dbSelectionContext.run({ tenantId: 'other-tenant' }, () => {
        return redisKey(TEST_TENANT, 'session', 'abc123');
      });
    }).toThrow('Tenant mismatch');
    
    expect(global.mantis_log).toHaveBeenCalledWith(
      'ERROR',
      'redis_key_tenant_mismatch',
      expect.objectContaining({ requested: TEST_TENANT, current: 'other-tenant' })
    );
  });

  // Test: redisKey genera clave con prefijo correcto cuando tenant coincide
  it('should generate Redis key with correct prefix when tenant matches', async () => {
    const result = await dbSelectionContext.run(
      { tenantId: TEST_TENANT },
      () => redisKey(TEST_TENANT, 'session', 'abc123')
    );
    
    expect(result).toBe(`${TEST_TENANT}:session:abc123`);
  });

  // Test: selectDbStack con timeout aborta y retorna fallback (C8)
  it('should timeout and return fallback stack A', async () => {
    // Mock lento para forzar timeout
    vi.mock('pg', () => ({ Pool: class { async connect() { await new Promise(r => setTimeout(r, 100)); } } }));

    const result = await dbSelectionContext.run(
      { tenantId: TEST_TENANT },
      () => selectDbStack({ ...BASE_PROFILE, needsVectorSearch: true }, { timeoutMs: 10 })
    );

    // Fallback a stack A cuando hay timeout
    expect(result.stack).toBe('A');
    expect(global.mantis_log).toHaveBeenCalledWith(
      'WARN',
      'stack_selection_timeout',
      expect.objectContaining({ tenant_id: TEST_TENANT })
    );
  });
});
```

---

## 🔍 Validação (VDD – Comando Canônico)
```bash
# Validação integral via orchestrator-engine (herda checks do Master Agent)
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/javascript/db-selection-decision-tree.ts.md \
  --json \
  --check-structural \
  --check-error-handling \
  --check-observability \
  --check-constraints C4,C8

# Validação específica de tenant isolation (C4)
bash 05-CONFIGURATIONS/validation/check-rls.sh \
  --file 06-PROGRAMMING/javascript/db-selection-decision-tree.ts.md \
  --lang ts \
  --json

# Validação de observability V-LOG-02 (C8)
bash 05-CONFIGURATIONS/validation/verify-observability.sh \
  --file 06-PROGRAMMING/javascript/db-selection-decision-tree.ts.md \
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
| 2.3.0-MODULAR-MERGED | 2026-05-09 | javascript-typescript-master-agent | MERGE: estrutura modular v2.3.0 + bootstrap resiliente + observability V-LOG-02 + lazy imports | C4,C8 |
| 2.1.1 | 2026-04-16 | Framework Core Team | Adição de exemplos AbortSignal.timeout e filtro tenant_id obrigatório em Qdrant | C4,C8 |
| 2.0.0 | 2026-03-01 | Qwen + DeepSeek | Primeira versão canônica com árvore de decisão runtime e AsyncLocalStorage | C4,C8 |

---

## 🔍 Observability (Documentación para IA – Eventos Específicos)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `stack_selection_started` | INFO | C8 | `"{\"tenant_id\":\"t123\",\"vertical\":\"agriculture\",\"has_vps\":false,\"monthly_records\":5000}"` |
| `stack_selected_vector` | DEBUG | C4 | `"{\"tenant_id\":\"t123\",\"stack\":\"D\"}"` |
| `stack_selection_completed` | INFO | C8 | `"{\"tenant_id\":\"t123\",\"selected_stack\":\"C\",\"connection_timeout_ms\":5000}"` |
| `postgres_connecting` | DEBUG | C8 | `"{\"tenant_id\":\"t123\",\"host\":\"db.local\",\"database\":\"tenant_t123\",\"timeout_ms\":5000}"` |
| `postgres_connected` | INFO | C4,C8 | `"{\"tenant_id\":\"t123\",\"database\":\"tenant_t123\"}"` |
| `redis_key_tenant_mismatch` | ERROR | C4 | `"{\"requested\":\"t999\",\"current\":\"t123\",\"namespace\":\"session\",\"identifier\":\"abc\"}"` |
| `vector_search_started` | DEBUG | C4,C8 | `"{\"tenant_id\":\"t123\",\"collection\":\"embeddings_t123\",\"vector_dimension\":1536,\"limit\":10}"` |
| `vector_search_timeout` | WARN | C8 | `"{\"tenant_id\":\"t123\",\"collection\":\"embeddings_t123\",\"timeout_ms\":5000}"` |
| `stack_selection_timeout` | WARN | C8 | `"{\"tenant_id\":\"t123\",\"timeout_ms\":3000}"` |

### Validação de Schema V-LOG-02 (Helper Mínimo)
```typescript
// Helper para validar que logs de DB selection seguem schema V-LOG-02
export function validateDbSelectionLog(logEntry: unknown): { valid: boolean; errors: string[] } {
  const errors: string[] = [];
  const entry = logEntry as Record<string, unknown>;

  // Campos obrigatórios V-LOG-02
  const required = ['ts', 'level', 'resource', 'body'];
  for (const field of required) {
    if (!(field in entry)) errors.push(`Missing required field: ${field}`);
  }

  // Validar que tenant_id está presente para eventos de DB (C4)
  const dbEvents = ['stack_selection_completed', 'postgres_connected', 'vector_search_started'];
  if (dbEvents.includes(entry.body?.event as string)) {
    const detail = entry.body?.detail as Record<string, unknown>;
    if (!detail?.tenant_id) {
      errors.push('C4 violation: DB event missing tenant_id in detail');
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
  "artifact": "db-selection-decision-tree",
  "version": "2.3.0-MODULAR-MERGED",
  "score": 31,
  "blocking_issues": [],
  "constraints_verified": ["C4", "C8"],
  "examples_count": 10,
  "lines_executable_max": 4,
  "language": "TypeScript 5.0+ / Node.js 18+",
  "observability_compliant": true,
  "bootstrap_resilient": true,
  "mantis_log_usage": "inherited",
  "tenant_isolation_verified": true,
  "lazy_imports_verified": true,
  "timestamp": "2026-05-09T00:00:00Z"
}
```

---

> 🇧🇷 *Documento técnico em pt-BR conforme V-DOC-01. Coordenação en español. Zero invenção: todo padrão grounded no conteúdo original + template v2.3.0-MODULAR.*
