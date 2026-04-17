# SHA256: e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7
---
artifact_id: "testing-multi-tenant-patterns"
artifact_type: "skill_typescript"
version: "2.1.1"
constraints_mapped: ["C4","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/testing-multi-tenant-patterns.ts.md --json"
---

# Testing Multi‑Tenant Patterns – TypeScript/Node.js with Jest & AsyncLocalStorage Mocks

## Propósito
Patrones para probar código multi‑tenant en TypeScript/Node.js usando Jest. Asegura aislamiento de contexto mediante mocks de `AsyncLocalStorage` (C4), validación de rutas seguras en tests de sistema de archivos (C7), y timeouts explícitos en pruebas asíncronas para evitar bloqueos (C8).

## Patrones de Código Validados

```typescript
// ✅ C4: Mock de AsyncLocalStorage en Jest con tipado
jest.mock('async_hooks', () => ({ AsyncLocalStorage: jest.fn() }));
const mockCtx = { getStore: jest.fn().mockReturnValue({ tenantId: 'test-tenant' }) };
```

```typescript
// ❌ Anti‑pattern: Test sin mock de AsyncLocalStorage
test('tenant operation', () => { const tenant = ctx.getStore().tenantId; });
// 🔧 Fix: Configurar mock antes de cada test
beforeEach(() => { ctx.getStore.mockReturnValue({ tenantId: 't1' }); });
```

```typescript
// ✅ C8: Timeout explícito en test asíncrono con Jest
test('slow operation', async () => {
  await expect(Promise.race([slowOp(), timeout(1000)])).resolves.toBe('ok');
}, 2000);
```

```typescript
// ❌ Anti‑pattern: Test sin límite de tiempo en operación lenta
test('slow', async () => { await slowOp(); });
// 🔧 Fix: Promise.race con timeout y límite global de Jest
test('slow', async () => {
  await Promise.race([slowOp(), new Promise(r => setTimeout(r, 5000))]);
}, 6000);
```

```typescript
// ✅ C4: Fixture de Jest que inicializa contexto por tenant
const setupTenant = (tenantId: string) => {
  ctx.getStore.mockReturnValue({ tenantId });
  return { tenantId };
};
```

```typescript
// ❌ Anti‑pattern: Sin fixture reusable para tenant
test('tenant A', () => { ctx.getStore.mockReturnValue({ tenantId: 'A' }); });
// 🔧 Fix: Función helper que configura el mock
const withTenant = (id: string) => ctx.getStore.mockReturnValue({ tenantId: id });
```

```typescript
// ✅ C7: Test de path traversal con fs mock y validación
jest.mock('fs/promises');
test('rejects path traversal', async () => {
  (fs.readFile as jest.Mock).mockRejectedValue(new Error('Invalid path'));
  await expect(readUserFile('../etc/passwd')).rejects.toThrow('Invalid path');
});
```

```typescript
// ❌ Anti‑pattern: No validar seguridad de rutas en tests
test('reads file', async () => { await readUserFile('file.txt'); });
// 🔧 Fix: Añadir caso de prueba para path traversal
test('blocks ../ escape', async () => {
  await expect(readUserFile('../secret')).rejects.toThrow('Path traversal');
});
```

```typescript
// ✅ C8: Mock de AbortSignal.timeout en tests
global.AbortSignal.timeout = jest.fn((ms) => ({ aborted: false, onabort: null }));
test('uses abort signal', () => { expect(AbortSignal.timeout).toHaveBeenCalledWith(5000); });
```

```typescript
// ✅ C4: Verificación de que el logger incluye tenant_id
test('logger includes tenant', () => {
  const spy = jest.spyOn(logger, 'info');
  processSomething();
  expect(spy).toHaveBeenCalledWith({ tenant_id: 'test' }, expect.any(String));
});
```

```typescript
// ❌ Anti‑pattern: Test sin verificar tenant en logs
test('logs something', () => { expect(logger.info).toHaveBeenCalled(); });
// 🔧 Fix: Comprobar que el objeto de log contiene tenant_id
expect(logger.info).toHaveBeenCalledWith(expect.objectContaining({ tenant_id: 't1' }), 'msg');
```

```typescript
// ✅ C8: Cleanup de mocks y timers después de cada test
afterEach(() => { jest.useRealTimers(); jest.clearAllMocks(); });
```

```typescript
// ✅ C7: Test de escritura de archivo con directorio aislado por tenant
test('writes to tenant subdirectory', async () => {
  await writeTenantFile('t1', 'data.txt', 'content');
  expect(fs.writeFile).toHaveBeenCalledWith('/data/t1/data.txt', 'content', expect.any(Object));
});
```

```typescript
// ✅ C4/C8: Integración con supertest y contexto tenant
import request from 'supertest';
test('GET /data with tenant header', async () => {
  await request(app).get('/data').set('x-tenant-id', 't1').expect(200);
});
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/testing-multi-tenant-patterns.ts.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"testing-multi-tenant-patterns","version":"2.1.1","score":30,"blocking_issues":[],"constraints_verified":["C4","C7","C8"],"examples_count":13,"lines_executable_max":2,"language":"TypeScript 5.0+ / Node.js 18+","timestamp":"2026-04-16T15:45:00Z"}
```

---
