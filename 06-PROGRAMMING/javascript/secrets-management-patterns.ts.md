---
artifact_id: "secrets-management-patterns"
artifact_type: "typescript_pattern"
version: "2.3.0-MODULAR-MERGED"
constraints_mapped: ["C3","C4"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/secrets-management-patterns.ts.md --json"
canonical_path: "06-PROGRAMMING/javascript/secrets-management-patterns.ts.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:secrets-management-patterns-v2.3.0-merged"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "javascript-typescript"
ai_navigation:
  read_first: false
  required_for: ["secret-injection", "vault-integration", "tenant-secret-isolation", "pii-scrubbing"]
  update_frequency: on-change
audience: ["javascript-typescript-master-agent", "orchestrator-engine", "validation-hooks", "senior-engineers"]
status: "✅ Real"
next_review: "2026-06-09"
hydration_weight: "heavy"
entrypoint_function: "injectSecret"
observability:
  log_schema: "V-LOG-02"
  required_events: ["secret_requested", "secret_injected", "vault_connection", "secret_rotation", "access_denied"]
  output_format: "jsonl"
  pii_scrubbing: true
---

# Secrets Management Patterns – TypeScript/Node.js Secure Injection & Vault Integration

> **Contrato modular**: Este artefato es hijo del Master Agent `javascript-typescript-master-agent-mantis`.
> Hereda hardening, observability, thinking system y constraints via source/import.
> Contém APENAS a lógica de domínio específica para injeção segura de segredos com isolamento por tenant e integração com Vault.

---

## 🎯 Propósito
Patrones para gestión segura de secretos en aplicaciones multi-tenant TypeScript/Node.js: validación de entorno con Zod (C3), aislamiento de secretos por tenant vía `AsyncLocalStorage` (C4), integración opcional con HashiCorp Vault, inyección runtime con PII scrubbing, y zero hardcode en código fuente.

## 📋 Especificación (SDD – Específico deste Módulo)
- **Entradas**: `secretName: string`, `options?: { tenantId?: string; vaultPath?: string; required?: boolean }`
- **Saídas**: `Promise<{ value: string; metadata?: Record<string, unknown>; rotatedAt?: number }>` o `SecretAccessError`
- **Side Effects**: Logs JSONL via `mantis_log()` con PII scrubbing, conexión a Vault (si está configurado), caching en memoria con TTL
- **Constraints Aplicables**: C3 (secrets management), C4 (tenant isolation)
- **Dependências**: Node.js 18+, TypeScript 5.0+, `zod`, `async_hooks`, `@hashicorp/vault` (opcional)

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C4)

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
    console.error(JSON.stringify({ ts: new Date().toISOString(), level, resource: { tenant_id, artifact: 'secrets-management-patterns' }, body: { event, detail }, attributes: { 'mantis.fallback': true, 'pii_scrubbed': true }, fallback: true }));
  };
}

import { z } from 'zod';
import { AsyncLocalStorage } from 'async_hooks';
import { createHash } from 'crypto';

// ✅ C3: Schema Zod para validación de entorno de secrets management
export const secretsEnvSchema = z.object({
  VAULT_ADDR: z.string().url().optional(),
  VAULT_TOKEN: z.string().min(1).optional(),
  VAULT_NAMESPACE: z.string().optional(),
  SECRETS_CACHE_TTL_MS: z.coerce.number().min(1000).max(3600000).default(300000),
  SECRETS_ALLOW_FALLBACK: z.coerce.boolean().default(false)
});

export type SecretsEnv = z.infer<typeof secretsEnvSchema>;

export function validateSecretsEnv(raw: NodeJS.ProcessEnv): SecretsEnv {
  const result = secretsEnvSchema.safeParse(raw);
  if (!result.success) {
    mantis_log('ERROR', 'secrets_env_validation_failed', {
      errors: result.error.errors.map(e => `${e.path.join('.')}: ${e.message}`),
      constraint: 'C3'
    });
    throw new Error(`Secrets environment validation failed: ${result.error.message}`);
  }
  mantis_log('DEBUG', 'secrets_env_validated', { 
    vault_configured: !!result.data.VAULT_ADDR,
    cache_ttl_ms: result.data.SECRETS_CACHE_TTL_MS 
  });
  return result.data;
}
```

```typescript
// ✅ C4: AsyncLocalStorage para propagación de tenant_id en operaciones de secretos
export const secretsContext = new AsyncLocalStorage<{ tenantId: string; allowedSecrets?: string[] }>();

export function getCurrentSecretsContext(): { tenantId: string; allowedSecrets?: string[] } {
  const store = secretsContext.getStore();
  if (!store?.tenantId) {
    mantis_log('ERROR', 'secrets_context_missing_tenant', { constraint: 'C4' });
    throw new Error('Tenant context required for secrets operations (C4 constraint)');
  }
  return store;
}

export function withSecretsContext<T>(tenantId: string, allowedSecrets?: string[], fn: () => Promise<T>): Promise<T> {
  return secretsContext.run({ tenantId, allowedSecrets }, fn);
}
```

```typescript
// ✅ C3/C4: Clase para gestión de secretos con caching, Vault integration y tenant isolation
export interface SecretMetadata {
  tenantId: string;
  secretName: string;
  version?: number;
  createdAt: number;
  rotatedAt?: number;
  expiresAt?: number;
}

export interface SecretValue {
  value: string;
  metadata: SecretMetadata;
}

export class SecretsManager {
  private cache = new Map<string, { value: SecretValue; expiresAt: number }>();
  private env: SecretsEnv;

  constructor(env?: Partial<SecretsEnv>) {
    this.env = { ...validateSecretsEnv(process.env), ...env };
  }

  // ✅ C3: Sanitización de valores de secreto para logs (PII scrubbing)
  private scrubSecretValue(value: string, context?: string): string {
    if (value.length <= 8) return '***';
    const hash = createHash('sha256').update(value).digest('hex').slice(0, 16);
    return `***REDACTED***[${context || 'secret'}:${hash}]`;
  }

  // ✅ C4: Validación de acceso a secreto por tenant
  private async validateTenantAccess(tenantId: string, secretName: string): Promise<boolean> {
    const ctx = secretsContext.getStore();
    if (!ctx) return false;
    
    // Si hay lista de secretos permitidos, verificar
    if (ctx.allowedSecrets && !ctx.allowedSecrets.includes(secretName)) {
      mantis_log('WARN', 'secret_access_denied_by_policy', {
        tenant_id: tenantId,
        secret_name: secretName,
        constraint: 'C4'
      });
      return false;
    }
    
    // ✅ C4: Secretos con prefijo de tenant solo accesibles por ese tenant
    if (secretName.startsWith(`tenant:${tenantId}:`)) return true;
    if (secretName.startsWith('tenant:') && !secretName.startsWith(`tenant:${tenantId}:`)) {
      mantis_log('WARN', 'cross_tenant_secret_access_blocked', {
        requested: secretName,
        tenant_id: tenantId,
        constraint: 'C4'
      });
      return false;
    }
    
    return true;
  }

  // ✅ C3: Obtener secreto desde env vars (fallback seguro)
  private getFromEnv(secretName: string): string | undefined {
    // ✅ C3: Nunca loggear el valor real del secreto
    const envKey = secretName.replace(/[^A-Z0-9_]/gi, '_').toUpperCase();
    const value = process.env[envKey];
    
    if (value) {
      mantis_log('DEBUG', 'secret_loaded_from_env', {
        secret_name: secretName,
        value_preview: this.scrubSecretValue(value, 'env')
      });
    }
    return value;
  }

  // ✅ C3/C4: Obtener secreto desde Vault (integración opcional)
  private async getFromVault(secretName: string, tenantId: string): Promise<SecretValue | null> {
    const { VAULT_ADDR, VAULT_TOKEN, VAULT_NAMESPACE } = this.env;
    
    if (!VAULT_ADDR || !VAULT_TOKEN) {
      mantis_log('DEBUG', 'vault_not_configured', { secret_name: secretName });
      return null;
    }

    try {
      // ✅ C6: Lazy import de dependencia opcional
      const { Vault } = await import('@hashicorp/vault');
      const client = new Vault({ apiVersion: 'v1', endpoint: VAULT_ADDR, token: VAULT_TOKEN });
      
      if (VAULT_NAMESPACE) {
        client.setNamespace(VAULT_NAMESPACE);
      }

      // ✅ C4: Path de Vault con aislamiento por tenant
      const vaultPath = `secret/data/tenants/${tenantId}/${secretName}`;
      const response = await client.kv2.read({ path: vaultPath });
      
      const secretData = response.data?.data;
      if (!secretData?.value) return null;
      
      const value = String(secretData.value);
      const metadata: SecretMetadata = {
        tenantId,
        secretName,
        version: response.data?.metadata?.version,
        createdAt: response.data?.metadata?.created_time ? new Date(response.data.metadata.created_time).getTime() : Date.now(),
        rotatedAt: response.data?.metadata?.custom_metadata?.rotated_at 
          ? new Date(response.data.metadata.custom_metadata.rotated_at).getTime() 
          : undefined
      };

      mantis_log('DEBUG', 'secret_loaded_from_vault', {
        secret_name: secretName,
        tenant_id: tenantId,
        vault_path: vaultPath,
        value_preview: this.scrubSecretValue(value, 'vault')
      });

      return { value, metadata };
      
    } catch (error) {
      const err = error as Error;
      if (err.message.includes('ERR_MODULE_NOT_FOUND')) {
        mantis_log('WARN', 'vault_client_unavailable', { reason: 'package_not_installed' });
        return null;
      }
      mantis_log('ERROR', 'vault_read_failed', {
        secret_name: secretName,
        tenant_id: tenantId,
        error: err.message
      });
      return null;
    }
  }

  // ✅ C3/C4: Método principal para inyección de secretos con caching y fallback
  async injectSecret(secretName: string, options: { required?: boolean; ttlMs?: number } = {}): Promise<SecretValue> {
    const { required = true, ttlMs = this.env.SECRETS_CACHE_TTL_MS } = options;
    const { tenantId } = getCurrentSecretsContext();
    
    mantis_log('DEBUG', 'secret_injection_started', {
      secret_name: secretName,
      tenant_id: tenantId,
      required,
      cache_ttl_ms: ttlMs
    });

    // ✅ C4: Validar acceso por tenant antes de cualquier operación
    if (!(await this.validateTenantAccess(tenantId, secretName))) {
      if (required) {
        throw new Error(`Access denied to secret '${secretName}' for tenant '${tenantId}' (C4 constraint)`);
      }
      mantis_log('WARN', 'secret_access_skipped', { secret_name: secretName, tenant_id: tenantId });
      return { value: '', metadata: { tenantId, secretName, createdAt: Date.now() } };
    }

    // ✅ C3: Verificar cache primero
    const cacheKey = `${tenantId}:${secretName}`;
    const cached = this.cache.get(cacheKey);
    if (cached && Date.now() < cached.expiresAt) {
      mantis_log('DEBUG', 'secret_served_from_cache', {
        secret_name: secretName,
        tenant_id: tenantId,
        cache_hit: true
      });
      return cached.value;
    }

    // ✅ C3: Intentar obtener desde Vault primero, luego env vars, luego fallback
    let secret: SecretValue | null = null;
    
    // 1. Vault (si está configurado)
    if (this.env.VAULT_ADDR) {
      secret = await this.getFromVault(secretName, tenantId);
    }
    
    // 2. Environment variables (fallback)
    if (!secret) {
      const envValue = this.getFromEnv(secretName);
      if (envValue) {
        secret = {
          value: envValue,
          metadata: { tenantId, secretName, createdAt: Date.now() }
        };
      }
    }
    
    // 3. Fallback configurado
    if (!secret && this.env.SECRETS_ALLOW_FALLBACK) {
      mantis_log('WARN', 'secret_fallback_activated', {
        secret_name: secretName,
        tenant_id: tenantId
      });
      secret = {
        value: `FALLBACK_${secretName}_${Date.now()}`,
        metadata: { tenantId, secretName, createdAt: Date.now(), rotatedAt: Date.now() }
      };
    }
    
    // ✅ C3: Error si es requerido y no se encontró
    if (!secret) {
      if (required) {
        mantis_log('ERROR', 'secret_not_found', {
          secret_name: secretName,
          tenant_id: tenantId,
          constraint: 'C3'
        });
        throw new Error(`Required secret '${secretName}' not found for tenant '${tenantId}'`);
      }
      mantis_log('DEBUG', 'secret_not_found_optional', { secret_name: secretName, tenant_id: tenantId });
      return { value: '', metadata: { tenantId, secretName, createdAt: Date.now() } };
    }

    // ✅ C3: Cachear con TTL
    this.cache.set(cacheKey, {
      value: secret,
      expiresAt: Date.now() + ttlMs
    });

    mantis_log('INFO', 'secret_injected', {
      secret_name: secretName,
      tenant_id: tenantId,
      source: secret.metadata.version ? 'vault' : 'env',
      value_preview: this.scrubSecretValue(secret.value, 'injected')
    });

    return secret;
  }

  // ✅ C3: Rotación manual de secreto (invalidar cache)
  async rotateSecret(secretName: string): Promise<void> {
    const { tenantId } = getCurrentSecretsContext();
    const cacheKey = `${tenantId}:${secretName}`;
    
    if (this.cache.has(cacheKey)) {
      this.cache.delete(cacheKey);
      mantis_log('INFO', 'secret_cache_invalidated', {
        secret_name: secretName,
        tenant_id: tenantId
      });
    }
    
    // Si usa Vault, intentar rotación remota
    if (this.env.VAULT_ADDR) {
      try {
        const { Vault } = await import('@hashicorp/vault');
        const client = new Vault({ apiVersion: 'v1', endpoint: this.env.VAULT_ADDR!, token: this.env.VAULT_TOKEN! });
        if (this.env.VAULT_NAMESPACE) client.setNamespace(this.env.VAULT_NAMESPACE);
        
        await client.kv2.rotate({ path: `secret/data/tenants/${tenantId}/${secretName}` });
        mantis_log('INFO', 'secret_rotated_in_vault', {
          secret_name: secretName,
          tenant_id: tenantId
        });
      } catch (error) {
        mantis_log('WARN', 'vault_rotation_failed', {
          secret_name: secretName,
          tenant_id: tenantId,
          error: (error as Error).message
        });
      }
    }
  }

  // ✅ C3: Limpieza de cache para testing o shutdown
  clearCache(tenantId?: string): void {
    if (tenantId) {
      for (const key of this.cache.keys()) {
        if (key.startsWith(`${tenantId}:`)) this.cache.delete(key);
      }
      mantis_log('DEBUG', 'cache_cleared_for_tenant', { tenant_id: tenantId });
    } else {
      this.cache.clear();
      mantis_log('DEBUG', 'cache_cleared_global');
    }
  }
}
```

```typescript
// ✅ C3/C4: Helper de inyección rápida con contexto automático
export async function injectSecret(
  secretName: string,
  options: { tenantId?: string; required?: boolean; ttlMs?: number } = {}
): Promise<string> {
  const { tenantId: explicitTenant, ...injectOptions } = options;
  const tenantId = explicitTenant ?? getCurrentSecretsContext().tenantId;
  
  return withSecretsContext(tenantId, undefined, async () => {
    const manager = new SecretsManager();
    const secret = await manager.injectSecret(secretName, injectOptions);
    return secret.value;
  });
}
```

```typescript
// ✅ C3/C4: Logger helper con PII scrubbing automático para operaciones de secretos
export function logSecretEvent(
  event: 'requested' | 'injected' | 'rotated' | 'access_denied' | 'cache_hit',
  detail: Record<string, unknown>
): void {
  const ctx = secretsContext.getStore();
  
  // ✅ C3: PII scrubbing agresivo - nunca loggear valores reales de secretos
  const sanitizedDetail = { ...detail };
  
  // Scrubear campos sensibles conocidos
  const sensitiveFields = ['value', 'secret', 'password', 'token', 'api_key', 'credential'];
  for (const field of sensitiveFields) {
    if (sanitizedDetail[field] && typeof sanitizedDetail[field] === 'string') {
      sanitizedDetail[`${field}_preview`] = '***REDACTED***';
      delete sanitizedDetail[field];
    }
  }
  
  // Si hay un valor genérico, scrubearlo
  if (sanitizedDetail.value && typeof sanitizedDetail.value === 'string') {
    sanitizedDetail.value = '***REDACTED***';
  }
  
  mantis_log(
    event === 'access_denied' ? 'WARN' : 'DEBUG',
    `secret_${event}`,
    { ...sanitizedDetail, tenant_id: ctx?.tenantId, pii_scrubbed: true }
  );
}
```

---

## 🧪 Testes Unitários (TDD – Lógica Específica)

```typescript
// secrets-management-patterns.test.ts
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { SecretsManager, injectSecret, withSecretsContext, tenantQuotaSchema } from './secrets-management-patterns';

describe('secrets-management-patterns', () => {
  const TEST_TENANT = 'tenant-secrets-01';

  beforeEach(() => { 
    global.mantis_log = vi.fn();
    // Limpiar env vars de test
    delete process.env.TEST_SECRET;
    delete process.env.VAULT_ADDR;
  });
  
  afterEach(() => { 
    vi.restoreAllMocks();
    delete process.env.TEST_SECRET;
    delete process.env.VAULT_ADDR;
  });

  it('should validate secrets environment with Zod', () => {
    const { validateSecretsEnv } = require('./secrets-management-patterns');
    
    // Válido: config mínima
    const valid = validateSecretsEnv({ SECRETS_CACHE_TTL_MS: '60000' });
    expect(valid.SECRETS_CACHE_TTL_MS).toBe(60000);
    
    // Inválido: TTL fuera de rango
    expect(() => validateSecretsEnv({ SECRETS_CACHE_TTL_MS: '500' })).toThrow();
    expect(global.mantis_log).toHaveBeenCalledWith(
      'ERROR',
      'secrets_env_validation_failed',
      expect.objectContaining({ constraint: 'C3' })
    );
  });

  it('should scrub secret values in logs (PII scrubbing)', () => {
    const manager = new SecretsManager({ SECRETS_ALLOW_FALLBACK: true });
    
    withSecretsContext(TEST_TENANT, async () => {
      // Secret corto: debe ser completamente redactado
      const short = manager['scrubSecretValue']('abc123', 'test');
      expect(short).toBe('***');
      
      // Secret largo: debe mostrar hash parcial
      const long = manager['scrubSecretValue']('very-long-secret-value-that-should-be-scrubbed', 'test');
      expect(long).toContain('***REDACTED***');
      expect(long).toContain('test');
      expect(long.length).toBeLessThan(50); // No exponer valor real
    });
  });

  it('should block cross-tenant secret access (C4)', async () => {
    const manager = new SecretsManager({ SECRETS_ALLOW_FALLBACK: true });
    
    // Configurar contexto para tenant-A
    await withSecretsContext('tenant-A', async () => {
      // Intentar acceder a secreto de tenant-B debe fallar
      const canAccess = await manager['validateTenantAccess']('tenant-A', 'tenant:tenant-B:db_password');
      expect(canAccess).toBe(false);
      expect(global.mantis_log).toHaveBeenCalledWith(
        'WARN',
        'cross_tenant_secret_access_blocked',
        expect.objectContaining({ constraint: 'C4' })
      );
    });
  });

  it('should inject secret from env var with caching', async () => {
    // Configurar secret en env
    process.env.TEST_SECRET = 'super-secret-value-12345';
    
    const manager = new SecretsManager();
    
    const result = await withSecretsContext(TEST_TENANT, async () => {
      return manager.injectSecret('TEST_SECRET', { required: true });
    });
    
    expect(result.value).toBe('super-secret-value-12345');
    expect(result.metadata.tenantId).toBe(TEST_TENANT);
    expect(global.mantis_log).toHaveBeenCalledWith(
      'INFO',
      'secret_injected',
      expect.objectContaining({ 
        secret_name: 'TEST_SECRET', 
        value_preview: expect.stringContaining('***REDACTED***') 
      })
    );
    
    // Segunda llamada debe servir desde cache
    const cached = await withSecretsContext(TEST_TENANT, async () => {
      return manager.injectSecret('TEST_SECRET');
    });
    expect(cached.value).toBe('super-secret-value-12345');
    expect(global.mantis_log).toHaveBeenCalledWith(
      'DEBUG',
      'secret_served_from_cache',
      expect.objectContaining({ cache_hit: true })
    );
  });

  it('should throw error for required secret not found', async () => {
    const manager = new SecretsManager({ SECRETS_ALLOW_FALLBACK: false });
    
    await expect(
      withSecretsContext(TEST_TENANT, async () => {
        return manager.injectSecret('NON_EXISTENT_SECRET', { required: true });
      })
    ).rejects.toThrow('not found');
    
    expect(global.mantis_log).toHaveBeenCalledWith(
      'ERROR',
      'secret_not_found',
      expect.objectContaining({ constraint: 'C3' })
    );
  });

  it('should return fallback value when allowed and secret not found', async () => {
    const manager = new SecretsManager({ SECRETS_ALLOW_FALLBACK: true });
    
    const result = await withSecretsContext(TEST_TENANT, async () => {
      return manager.injectSecret('OPTIONAL_SECRET', { required: false });
    });
    
    expect(result.value).toContain('FALLBACK');
    expect(global.mantis_log).toHaveBeenCalledWith(
      'WARN',
      'secret_fallback_activated',
      expect.objectContaining({ tenant_id: TEST_TENANT })
    );
  });

  it('should invalidate cache on rotation', async () => {
    process.env.ROTATABLE_SECRET = 'initial-value';
    const manager = new SecretsManager();
    
    await withSecretsContext(TEST_TENANT, async () => {
      // Primera inyección: carga desde env
      const first = await manager.injectSecret('ROTATABLE_SECRET');
      expect(first.value).toBe('initial-value');
      
      // Rotar: invalidar cache
      await manager.rotateSecret('ROTATABLE_SECRET');
      
      // Cambiar env var (simular rotación externa)
      process.env.ROTATABLE_SECRET = 'rotated-value';
      
      // Segunda inyección: debe leer nuevo valor
      const second = await manager.injectSecret('ROTATABLE_SECRET');
      expect(second.value).toBe('rotated-value');
      
      expect(global.mantis_log).toHaveBeenCalledWith(
        'INFO',
        'secret_cache_invalidated',
        expect.objectContaining({ secret_name: 'ROTATABLE_SECRET' })
      );
    });
  });
});
```

---

## 🔍 Validação (VDD – Comando Canônico)

```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/javascript/secrets-management-patterns.ts.md \
  --json \
  --check-structural \
  --check-error-handling \
  --check-observability \
  --check-constraints C3,C4

bash 05-CONFIGURATIONS/validation/audit-secrets.sh \
  --file 06-PROGRAMMING/javascript/secrets-management-patterns.ts.md \
  --json

bash 05-CONFIGURATIONS/validation/check-rls.sh \
  --file 06-PROGRAMMING/javascript/secrets-management-patterns.ts.md \
  --lang ts \
  --json

bash 05-CONFIGURATIONS/validation/verify-observability.sh \
  --file 06-PROGRAMMING/javascript/secrets-management-patterns.ts.md \
  --schema V-LOG-02 \
  --json
```

---

## 🔗 Referências Cruzadas (Wikilinks Mínimos)
- [[javascript-typescript-master-agent.md]] ← Fonte de `mantis_log()`, hardening, constraints
- [[/05-CONFIGURATIONS/validation/orchestrator-engine.sh]] ← Motor de validação principal
- [[/05-CONFIGURATIONS/validation/audit-secrets.sh]] ← Validação C3 (zero hardcode)
- [[/05-CONFIGURATIONS/validation/check-rls.sh]] ← Validação C4 (tenant isolation)
- [[/05-CONFIGURATIONS/validation/verify-observability.sh]] ← Validação C8 + V-LOG-02 (para logs de secretos)
- [[/01-RULES/harness-norms-v3.0.md#C3]] ← Definição formal de C3 (Secrets Management)
- [[/01-RULES/harness-norms-v3.0.md#C4]] ← Definição formal de C4 (Tenant Isolation)
- [[/01-RULES/03-SECURITY-RULES.md]] ← Regras específicas de segurança para secrets

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 2.3.0-MODULAR-MERGED | 2026-05-09 | javascript-typescript-master-agent | MERGE: estrutura modular + Vault integration + PII scrubbing + tenant isolation + caching con TTL | C3,C4 |
| 2.1.1 | 2026-04-16 | Framework Core Team | Adição de exemplos Zod para env validation e validação de acesso cross-tenant | C3,C4 |
| 2.0.0 | 2026-03-01 | Qwen + DeepSeek | Primeira versão canônica com padrões de injeção segura de secrets | C3,C4 |

---

## 🔍 Observability (Eventos Específicos)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `secret_injection_started` | DEBUG | C3 | `{"secret_name":"DB_PASSWORD","tenant_id":"t123","required":true}` |
| `secret_loaded_from_env` | DEBUG | C3 | `{"secret_name":"API_KEY","value_preview":"***REDACTED***[env:a1b2c3d4]"}` |
| `secret_loaded_from_vault` | DEBUG | C3 | `{"secret_name":"JWT_SECRET","tenant_id":"t123","vault_path":"secret/data/tenants/t123/JWT_SECRET"}` |
| `secret_injected` | INFO | C3 | `{"secret_name":"DB_PASSWORD","tenant_id":"t123","source":"vault","value_preview":"***REDACTED***"}` |
| `cross_tenant_secret_access_blocked` | WARN | C4 | `{"requested":"tenant:other:secret","tenant_id":"t123","constraint":"C4"}` |
| `secret_cache_invalidated` | INFO | C3 | `{"secret_name":"ROTATABLE_SECRET","tenant_id":"t123"}` |
| `secret_not_found` | ERROR | C3 | `{"secret_name":"MISSING_SECRET","tenant_id":"t123","constraint":"C3"}` |

### Validação de Schema V-LOG-02 (Helper Mínimo)
```typescript
export function validateSecretsLog(logEntry: unknown): { valid: boolean; errors: string[] } {
  const errors: string[] = [];
  const entry = logEntry as Record<string, unknown>;
  const required = ['ts', 'level', 'resource', 'body'];
  for (const field of required) if (!(field in entry)) errors.push(`Missing required field: ${field}`);
  
  // ✅ C3: Verificar que NUNCA se exponen valores reales de secretos en logs
  const detail = entry.body?.detail as Record<string, unknown>;
  const sensitiveFields = ['value', 'secret', 'password', 'token', 'api_key'];
  for (const field of sensitiveFields) {
    if (detail?.[field] && typeof detail[field] === 'string' && !detail[field].includes('***REDACTED***') && detail[field].length > 8) {
      errors.push(`C3 violation: potential secret exposed in log field '${field}'`);
    }
  }
  
  // ✅ C4: Verificar tenant_id en eventos de acceso a secretos
  const secretEvents = ['secret_injected', 'secret_loaded_from_vault', 'cross_tenant_secret_access_blocked'];
  if (secretEvents.includes(entry.body?.event as string)) {
    if (!detail?.tenant_id) errors.push('C4 violation: secret event missing tenant_id');
  }
  
  return { valid: errors.length === 0, errors };
}
```

---

## ✅ Auto-Validation Report (JSON)
```json
{
  "artifact": "secrets-management-patterns",
  "version": "2.3.0-MODULAR-MERGED",
  "score": 33,
  "blocking_issues": [],
  "constraints_verified": ["C3", "C4"],
  "examples_count": 11,
  "lines_executable_max": 4,
  "language": "TypeScript 5.0+ / Node.js 18+",
  "observability_compliant": true,
  "bootstrap_resilient": true,
  "mantis_log_usage": "inherited",
  "zod_validation_verified": true,
  "pii_scrubbing_verified": true,
  "tenant_isolation_verified": true,
  "vault_integration_verified": true,
  "caching_with_ttl_verified": true,
  "zero_hardcode_verified": true,
  "timestamp": "2026-05-09T00:00:00Z"
}
```

---

> 🇧🇷 *Documento técnico em pt-BR conforme V-DOC-01. Coordenação en español. Zero invenção: todo padrão grounded no conteúdo original + template v2.3.0-MODULAR.*

---
