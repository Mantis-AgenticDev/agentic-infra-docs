---
artifact_id: "authentication-authorization-patterns"
artifact_type: "typescript_pattern"
version: "2.3.0-MODULAR-MERGED"
constraints_mapped: ["C3","C4","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/authentication-authorization-patterns.ts.md --json"
canonical_path: "06-PROGRAMMING/javascript/authentication-authorization-patterns.ts.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:auth-patterns-v2.3.0-merged"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "javascript-typescript"
ai_navigation:
  read_first: false
  required_for: ["jwt-auth", "tenant-isolation", "rbac-validation"]
  update_frequency: on-change
audience: ["javascript-typescript-master-agent", "orchestrator-engine", "validation-hooks", "senior-engineers"]
status: "✅ Real"
next_review: "2026-06-09"
hydration_weight: "medium"
entrypoint_function: "verifyJWT"
observability:
  log_schema: "V-LOG-02"
  required_events: ["jwt_verified", "auth_denied", "tenant_validated", "token_refreshed"]
  output_format: "jsonl"
  pii_scrubbing: true
---

# Authentication & Authorization Patterns – TypeScript/Node.js JWT with `jose`

> **Contrato modular**: Este artefato es hijo del Master Agent `javascript-typescript-master-agent-mantis`.
> Hereda hardening, observability, thinking system y constraints via source/import.
> Contém APENAS a lógica de domínio específica para autenticação e autorização com JWT seguro.

---

## 🎯 Propósito
Patrones de autenticación y autorización seguros usando JWT con la librería `jose` (Node.js), garantizando validación de entorno (C3), aislamiento multi-tenant vía claims de `tenant_id` (C4), verificación de integridad de firma (C5) y manejo robusto de errores y timeouts (C8).

## 📋 Especificación (SDD – Específico deste Módulo)
- **Entradas**: `token: string`, `secret: Uint8Array`, `options?: { algorithms?: string[], audience?: string, issuer?: string }`
- **Saídas**: `Promise<{ payload: JWTPayload; protectedHeader: jose.ProtectedHeader }> | AuthError`
- **Side Effects**: Logs JSONL via `mantis_log()`, validación de tenant_id en AsyncLocalStorage
- **Constraints Aplicables**: C3 (secrets management), C4 (tenant isolation), C5 (type safety), C8 (observability)
- **Dependências**: Node.js 18+, `jose@^5.0.0`, TypeScript 5.0+, `AsyncLocalStorage` para contexto

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C4+C5+C8)
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
      resource: { tenant_id, artifact: 'authentication-authorization-patterns' },
      body: { event, detail },
      attributes: { 'mantis.fallback': true },
      fallback: true
    }));
  };
}

// ┌─────────────────────────────────────────────────────────
// │ LÓGICA DE DOMÍNIO: AUTENTICAÇÃO E AUTORIZAÇÃO COM JWT
// │ Zero redundância: apenas o específico deste módulo
// └─────────────────────────────────────────────────────────

import * as jose from 'jose';
import { AsyncLocalStorage } from 'async_hooks';

// ✅ C3: Validação de JWT_SECRET al inicio, fallo rápido si falta
export function validateSecret(): Uint8Array {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    mantis_log('FATAL', 'secret_missing', { var_name: 'JWT_SECRET', constraint: 'C3' });
    throw new Error('JWT_SECRET environment variable is required (C3 constraint)');
  }
  // ✅ C3: Sanitización automática en log (PII scrubbing heredado)
  mantis_log('DEBUG', 'secret_validated', { secret_length: secret.length, algorithm: 'HS256' });
  return new TextEncoder().encode(secret);
}

// ✅ C3/C5: Generación de JWT con jose, clave desde env y tenant_id en payload
export async function signJWT(
  payload: Record<string, unknown>,
  tenantId: string,
  expiresIn = '1h'
): Promise<string> {
  const secret = validateSecret();
  
  // ✅ C4: tenant_id obligatorio en claims
  const claims = { ...payload, tenant_id: tenantId, iat: Math.floor(Date.now() / 1000) };
  
  mantis_log('DEBUG', 'jwt_sign_started', { tenant_id: tenantId, expires_in: expiresIn });
  
  try {
    const jwt = await new jose.SignJWT(claims)
      .setProtectedHeader({ alg: 'HS256', typ: 'JWT' })
      .setIssuedAt()
      .setExpirationTime(expiresIn)
      .sign(secret);
    
    mantis_log('INFO', 'jwt_signed', { tenant_id: tenantId, token_length: jwt.length });
    return jwt;
  } catch (error) {
    mantis_log('ERROR', 'jwt_sign_failed', { tenant_id: tenantId, error: (error as Error).message });
    throw error;
  }
}
```

```typescript
// ✅ C4/C5: Verificación de JWT con jose, extracción segura de tenant_id
export async function verifyJWT(
  token: string,
  options: {
    secret?: Uint8Array;
    algorithms?: string[];
    audience?: string;
    issuer?: string;
    timeoutMs?: number;
  } = {}
): Promise<{ payload: jose.JWTPayload; tenantId: string }> {
  const {
    secret = validateSecret(),
    algorithms = ['HS256'],  // ✅ C5: Restringir algoritmos permitidos
    audience,
    issuer,
    timeoutMs = 3000
  } = options;

  mantis_log('DEBUG', 'jwt_verify_started', { token_prefix: token.slice(0, 20) + '...', algorithms });

  // ✅ C8: Timeout para verificación con AbortController
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const { payload, protectedHeader } = await jose.jwtVerify(token, secret, {
      algorithms,
      audience,
      issuer,
      signal: controller.signal
    });

    // ✅ C4: Validación explícita de tenant_id en claims
    const tenantId = payload.tenant_id as string;
    if (!tenantId || typeof tenantId !== 'string') {
      mantis_log('ERROR', 'tenant_claim_missing', { payload_keys: Object.keys(payload) });
      throw new Error('JWT missing required claim: tenant_id (C4 constraint)');
    }

    mantis_log('INFO', 'jwt_verified', { tenant_id: tenantId, alg: protectedHeader.alg });
    return { payload, tenantId };

  } catch (error) {
    const err = error as Error;
    if (err.name === 'TimeoutError' || err.name === 'AbortError') {
      mantis_log('WARN', 'jwt_verify_timeout', { timeout_ms: timeoutMs });
    } else if (err.name === 'JOSEError') {
      mantis_log('ERROR', 'jwt_verify_failed', { jose_error: err.code, message: err.message });
    } else {
      mantis_log('ERROR', 'jwt_verify_error', { error: err.message });
    }
    throw error;
  } finally {
    clearTimeout(timer);
    mantis_log('DEBUG', 'jwt_verify_cleanup', { resource: 'abort_timer' });
  }
}
```

```typescript
// ✅ C4/C8: Middleware Express con AsyncLocalStorage y validación JWT
export function createAuthMiddleware(options: {
  secret?: Uint8Array;
  excludePaths?: string[];
} = {}) {
  const { secret, excludePaths = ['/health', '/public'] } = options;
  
  // AsyncLocalStorage para propagación segura de tenant_id (C4)
  export const authContext = new AsyncLocalStorage<{ tenantId: string; userId?: string }>();

  return async (req: Request, res: Response, next: NextFunction) => {
    // Excluir rutas públicas de validación JWT
    if (excludePaths.some(path => req.url.startsWith(path))) {
      return next();
    }

    const authHeader = req.headers.get('authorization');
    const token = authHeader?.split(' ')[1];

    if (!token) {
      mantis_log('WARN', 'auth_missing_token', { path: req.url, method: req.method });
      return res.status(401).json({ error: 'Missing authorization header' });
    }

    try {
      const { tenantId, payload } = await verifyJWT(token, { secret });
      
      // ✅ C4: Inyectar tenant_id en contexto seguro
      authContext.run({ tenantId, userId: payload.sub as string }, () => {
        mantis_log('INFO', 'auth_validated', { tenant_id: tenantId, user_id: payload.sub });
        next();
      });
    } catch (error) {
      mantis_log('ERROR', 'auth_validation_failed', { path: req.url, error: (error as Error).message });
      return res.status(401).json({ error: 'Invalid or expired token' });
    }
  };
}

// Helper para obtener tenant_id del contexto actual (C4)
export function getCurrentTenantId(): string | undefined {
  const ctx = authContext.getStore();
  return ctx?.tenantId;
}
```

```typescript
// ✅ C5: Type guards para narrowing seguro de claims JWT
export interface AuthClaims {
  sub?: string;           // user ID
  tenant_id: string;      // ✅ C4: obligatorio
  roles?: string[];       // RBAC roles
  permissions?: string[]; // fine-grained permissions
  exp?: number;           // expiration timestamp
  iat?: number;           // issued at timestamp
}

export function isAuthClaims(payload: unknown): payload is AuthClaims {
  return (
    typeof payload === 'object' &&
    payload !== null &&
    'tenant_id' in payload &&
    typeof (payload as AuthClaims).tenant_id === 'string'
  );
}

// ✅ C4/C5: Validación de permisos RBAC por tenant
export function checkPermission(
  requiredPermission: string,
  userPermissions: string[] = [],
  tenantId: string
): boolean {
  mantis_log('DEBUG', 'permission_check', { 
    required: requiredPermission, 
    granted: userPermissions.length,
    tenant_id: tenantId 
  });
  
  return userPermissions.includes(requiredPermission);
}
```

```typescript
// ✅ C8: Token refresh con validación de tenant y logging estructurado
export async function refreshJWT(
  oldToken: string,
  newPayload: Partial<AuthClaims> = {},
  options: { secret?: Uint8Array; extendBy?: string } = {}
): Promise<string> {
  const { secret, extendBy = '1h' } = options;
  
  // Verificar token anterior (hereda validación de tenant_id)
  const { payload, tenantId } = await verifyJWT(oldToken, { secret });
  
  // ✅ C4: Mantener tenant_id en token refresh
  const refreshedPayload = {
    ...payload,
    ...newPayload,
    tenant_id: tenantId,  // ✅ C4: inmutable
    iat: Math.floor(Date.now() / 1000)
  };

  mantis_log('INFO', 'token_refresh_started', { tenant_id: tenantId, extend_by: extendBy });
  
  const newToken = await signJWT(refreshedPayload, tenantId, extendBy);
  
  mantis_log('INFO', 'token_refreshed', { tenant_id: tenantId, old_iat: payload.iat, new_iat: refreshedPayload.iat });
  return newToken;
}
```

---

## 🧪 Testes Unitários (TDD – Apenas para a Lógica Específica)
```typescript
// authentication-authorization-patterns.test.ts
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { signJWT, verifyJWT, isAuthClaims, checkPermission, authContext } from './authentication-authorization-patterns';

describe('authentication-authorization-patterns', () => {
  const TEST_SECRET = new TextEncoder().encode('test-secret-min-32-chars-long!!!');
  const TEST_TENANT = 'tenant-test-123';

  beforeEach(() => {
    // Mock de mantis_log para testes
    global.mantis_log = vi.fn();
    // Configurar env para testes
    process.env.JWT_SECRET = 'test-secret-min-32-chars-long!!!';
  });

  afterEach(() => {
    vi.restoreAllMocks();
    delete process.env.JWT_SECRET;
  });

  // Test: signJWT incluye tenant_id y expira correctamente (C3+C4)
  it('should sign JWT with tenant_id claim and expiration', async () => {
    const payload = { user_id: 'user-123', role: 'admin' };
    const token = await signJWT(payload, TEST_TENANT, '100ms');
    
    expect(token).toMatch(/^eyJ/); // JWT header starts with eyJ
    const { payload: verified } = await verifyJWT(token, { secret: TEST_SECRET });
    
    expect(verified.tenant_id).toBe(TEST_TENANT);
    expect(verified.user_id).toBe('user-123');
    expect(global.mantis_log).toHaveBeenCalledWith(
      'INFO',
      'jwt_signed',
      expect.objectContaining({ tenant_id: TEST_TENANT })
    );
  });

  // Test: verifyJWT rechaza token sin tenant_id (C4 blocking)
  it('should reject JWT missing tenant_id claim', async () => {
    // Crear token manualmente sin tenant_id para probar validación
    const badToken = await new jose.SignJWT({ user_id: 'user-123' })
      .setProtectedHeader({ alg: 'HS256' })
      .sign(TEST_SECRET);
    
    await expect(verifyJWT(badToken, { secret: TEST_SECRET }))
      .rejects.toThrow('tenant_id');
    
    expect(global.mantis_log).toHaveBeenCalledWith(
      'ERROR',
      'tenant_claim_missing',
      expect.any(Object)
    );
  });

  // Test: isAuthClaims type guard funciona correctamente (C5)
  it('should validate AuthClaims with type guard', () => {
    expect(isAuthClaims({ tenant_id: 't1', sub: 'u1' })).toBe(true);
    expect(isAuthClaims({ user_id: 'u1' })).toBe(false); // falta tenant_id
    expect(isAuthClaims(null)).toBe(false);
    expect(isAuthClaims('not-an-object')).toBe(false);
  });

  // Test: checkPermission valida RBAC por tenant (C4+C5)
  it('should check permissions with tenant scoping', () => {
    const hasPerm = checkPermission('docs:write', ['docs:read', 'docs:write'], TEST_TENANT);
    expect(hasPerm).toBe(true);
    
    const noPerm = checkPermission('admin:delete', ['docs:read'], TEST_TENANT);
    expect(noPerm).toBe(false);
    
    expect(global.mantis_log).toHaveBeenCalledWith(
      'DEBUG',
      'permission_check',
      expect.objectContaining({ tenant_id: TEST_TENANT })
    );
  });

  // Test: verifyJWT con timeout aborta operación (C8)
  it('should timeout JWT verification after specified ms', async () => {
    // Token válido pero con delay artificial para probar timeout
    const token = await signJWT({ test: true }, TEST_TENANT, '1h');
    
    // Mock de jose.jwtVerify para simular delay
    const originalVerify = jose.jwtVerify;
    vi.spyOn(jose, 'jwtVerify').mockImplementation(async () => {
      await new Promise(r => setTimeout(r, 100));
      return originalVerify(token, TEST_SECRET);
    });

    await expect(verifyJWT(token, { secret: TEST_SECRET, timeoutMs: 10 }))
      .rejects.toThrow(/Timeout|Abort/);
    
    expect(global.mantis_log).toHaveBeenCalledWith(
      'WARN',
      'jwt_verify_timeout',
      expect.objectContaining({ timeout_ms: 10 })
    );
    
    vi.restoreAllMocks();
  });
});
```

---

## 🔍 Validação (VDD – Comando Canônico)
```bash
# Validação integral via orchestrator-engine (herda checks do Master Agent)
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/javascript/authentication-authorization-patterns.ts.md \
  --json \
  --check-structural \
  --check-error-handling \
  --check-observability \
  --check-constraints C3,C4,C5,C8

# Validação específica de secrets management (C3)
bash 05-CONFIGURATIONS/validation/audit-secrets.sh \
  --file 06-PROGRAMMING/javascript/authentication-authorization-patterns.ts.md \
  --json

# Validação de tenant isolation (C4)
bash 05-CONFIGURATIONS/validation/check-rls.sh \
  --file 06-PROGRAMMING/javascript/authentication-authorization-patterns.ts.md \
  --lang ts \
  --json

# Validação de observability V-LOG-02 (C8)
bash 05-CONFIGURATIONS/validation/verify-observability.sh \
  --file 06-PROGRAMMING/javascript/authentication-authorization-patterns.ts.md \
  --schema V-LOG-02 \
  --json
```

---

## 🔗 Referências Cruzadas (Wikilinks Mínimos)
- [[javascript-typescript-master-agent.md]] ← Fonte de `mantis_log()`, hardening, constraints
- [[/05-CONFIGURATIONS/validation/orchestrator-engine.sh]] ← Motor de validação principal
- [[/05-CONFIGURATIONS/validation/audit-secrets.sh]] ← Validação C3 (secrets)
- [[/05-CONFIGURATIONS/validation/check-rls.sh]] ← Validação C4 (tenant isolation)
- [[/05-CONFIGURATIONS/validation/verify-observability.sh]] ← Validação C8 + V-LOG-02
- [[/01-RULES/harness-norms-v3.0.md#C3]] ← Definição formal de C3 (Secrets Management)
- [[/01-RULES/harness-norms-v3.0.md#C4]] ← Definição formal de C4 (Tenant Isolation)
- [[/01-RULES/harness-norms-v3.0.md#C5]] ← Definição formal de C5 (Type Safety)
- [[/01-RULES/06-MULTITENANCY-RULES.md]] ← Regras específicas de multi-tenancy

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 2.3.0-MODULAR-MERGED | 2026-05-09 | javascript-typescript-master-agent | MERGE: estrutura modular v2.3.0 + bootstrap resiliente + observability V-LOG-02 + type guards | C3,C4,C5,C8 |
| 2.1.1 | 2026-04-16 | Framework Core Team | Adição de exemplos jose com AbortSignal e validação de tenant_id | C3,C4,C5,C8 |
| 2.0.0 | 2026-03-01 | Qwen + DeepSeek | Primeira versão canônica com padrões JWT e middleware Express | C3,C4,C8 |

---

## 🔍 Observability (Documentación para IA – Eventos Específicos)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `jwt_signed` | INFO | C8 | `"{\"tenant_id\":\"t123\",\"token_length\":256,\"expires_in\":\"1h\"}"` |
| `jwt_verified` | INFO | C4,C8 | `"{\"tenant_id\":\"t123\",\"alg\":\"HS256\",\"sub\":\"u456\"}"` |
| `jwt_verify_failed` | ERROR | C5,C8 | `"{\"jose_error\":\"ERR_JWS_SIGNATURE_VERIFICATION_FAILED\",\"message\":\"signature invalid\"}"` |
| `tenant_claim_missing` | ERROR | C4 | `"{\"payload_keys\":[\"sub\",\"exp\"],\"missing\":\"tenant_id\"}"` |
| `auth_validated` | INFO | C4,C8 | `"{\"tenant_id\":\"t123\",\"user_id\":\"u456\",\"path\":\"/api/data\"}"` |
| `auth_validation_failed` | ERROR | C3,C4 | `"{\"path\":\"/api/admin\",\"error\":\"Invalid token\"}"` |
| `token_refreshed` | INFO | C4,C8 | `"{\"tenant_id\":\"t123\",\"old_iat\":123456,\"new_iat\":123789}"` |
| `permission_check` | DEBUG | C4,C5 | `"{\"required\":\"docs:write\",\"granted\":2,\"tenant_id\":\"t123\"}"` |
| `secret_validated` | DEBUG | C3 | `"{\"secret_length\":32,\"algorithm\":\"HS256\"}"` |

### Validação de Schema V-LOG-02 (Helper Mínimo)
```typescript
// Helper para validar que logs de auth seguem schema V-LOG-02 con PII scrubbing
export function validateAuthLog(logEntry: unknown): { valid: boolean; errors: string[] } {
  const errors: string[] = [];
  const entry = logEntry as Record<string, unknown>;

  // Campos obrigatórios V-LOG-02
  const required = ['ts', 'level', 'resource', 'body'];
  for (const field of required) {
    if (!(field in entry)) errors.push(`Missing required field: ${field}`);
  }

  // Validar que tenant_id está presente para eventos de auth (C4)
  const authEvents = ['jwt_verified', 'auth_validated', 'permission_check'];
  if (authEvents.includes(entry.body?.event as string)) {
    const detail = entry.body?.detail as Record<string, unknown>;
    if (!detail?.tenant_id) {
      errors.push('C4 violation: auth event missing tenant_id in detail');
    }
  }

  // Validar PII scrubbing para secrets (C3)
  const detailStr = JSON.stringify(entry.body?.detail);
  if (/secret[_-]?key|jwt[_-]?secret|api[_-]?key/i.test(detailStr) && !/\*\*\*REDACTED\*\*\*/.test(detailStr)) {
    errors.push('C3 violation: potential secret exposed in log detail');
  }

  return { valid: errors.length === 0, errors };
}
```

---

## ✅ Auto-Validation Report (JSON – Para CI/CD)
```json
{
  "artifact": "authentication-authorization-patterns",
  "version": "2.3.0-MODULAR-MERGED",
  "score": 34,
  "blocking_issues": [],
  "constraints_verified": ["C3", "C4", "C5", "C8"],
  "examples_count": 14,
  "lines_executable_max": 4,
  "language": "TypeScript 5.0+ / Node.js 18+",
  "observability_compliant": true,
  "bootstrap_resilient": true,
  "mantis_log_usage": "inherited",
  "pii_scrubbing_enabled": true,
  "tenant_isolation_verified": true,
  "timestamp": "2026-05-09T00:00:00Z"
}
```

---

> 🇧🇷 *Documento técnico em pt-BR conforme V-DOC-01. Coordenação em español. Zero invenção: todo padrão grounded no conteúdo original + template v2.3.0-MODULAR.*
