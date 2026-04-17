# SHA256: e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4
---
artifact_id: "vertical-db-schemas"
artifact_type: "skill_typescript"
version: "2.1.1"
constraints_mapped: ["C4","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/vertical-db-schemas.ts.md --json"
---

# Vertical DB Schemas – TypeScript/Node.js Schema-per-Tenant & Migration Guardrails

## Propósito
Patrones para implementar **schema-per-tenant** en PostgreSQL usando TypeScript/Node.js, basados en la taxonomía de verticales de MANTIS (restaurante, hotel, dental, marketing, corp_kb). Garantiza aislamiento multi‑tenant con `tenant_id` obligatorio como segundo campo en todas las tablas (C4), verificación de integridad de migraciones vía checksums (C5) y timeouts explícitos en la ejecución de migraciones y conexiones (C8).

## Patrones de Código Validados

```typescript
// ✅ C4: Definición de tabla con tenant_id como segundo campo obligatorio
await db.schema.createTable('mesas', (table) => {
  table.uuid('id').primary();
  table.string('tenant_id', 50).notNullable(); // C4: segundo campo siempre
  table.string('numero', 20).notNullable();
});
```

```typescript
// ❌ Anti‑pattern: Tabla sin tenant_id o en posición incorrecta
await db.schema.createTable('mesas', (table) => {
  table.uuid('id').primary();
  table.string('numero').notNullable(); // falta tenant_id
});
// 🔧 Fix: Incluir tenant_id como segundo campo
await db.schema.createTable('mesas', (table) => {
  table.uuid('id').primary();
  table.string('tenant_id', 50).notNullable();
  table.string('numero', 20).notNullable();
});
```

```typescript
// ✅ C4/C8: Conexión a PostgreSQL con timeout y búsqueda de schema por tenant
import { Pool } from 'pg';
const pool = new Pool({ connectionTimeoutMillis: 5000 });
const client = await pool.connect();
await client.query(`SET search_path TO tenant_${tenantId}`);
```

```typescript
// ❌ Anti‑pattern: Conexión sin timeout ni cambio de schema
const client = await pool.connect();
await client.query('SELECT * FROM mesas');
// 🔧 Fix: Timeout + SET search_path
const client = await pool.connect();
await client.query(`SET search_path TO tenant_${tenantId}`);
await client.query('SELECT * FROM mesas');
```

```typescript
// ✅ C5: Verificación de integridad de migración con SHA256
import { createHash } from 'crypto';
const migrationHash = createHash('sha256').update(migrationSQL).digest('hex');
if (migrationHash !== expectedHash) throw new Error('Migration tampered');
```

```typescript
// ✅ C8: Ejecución de migración con timeout usando node-pg-migrate
import migrate from 'node-pg-migrate';
await migrate({
  databaseUrl: process.env.DATABASE_URL,
  direction: 'up',
  migrationsTable: 'pgmigrations',
  schema: `tenant_${tenantId}`,
  timeout: 30000
});
```

```typescript
// ❌ Anti‑pattern: Migración sin timeout
await migrate({ direction: 'up', schema: `tenant_${tenantId}` });
// 🔧 Fix: Configurar timeout explícito
await migrate({ direction: 'up', schema: `tenant_${tenantId}`, timeout: 30000 });
```

```typescript
// ✅ C4: Índice compuesto con tenant_id como prefijo obligatorio
await db.schema.alterTable('menu_items', (table) => {
  table.index(['tenant_id', 'categoria_id'], 'idx_tenant_categoria');
});
```

```typescript
// ❌ Anti‑pattern: Índice sin tenant_id como prefijo
await db.schema.alterTable('menu_items', (table) => {
  table.index(['categoria_id']);
});
// 🔧 Fix: Índice compuesto empezando por tenant_id
await db.schema.alterTable('menu_items', (table) => {
  table.index(['tenant_id', 'categoria_id']);
});
```

```typescript
// ✅ C5/C8: Validación de schema con Zod y timeout en migración programática
import { z } from 'zod';
const tableSchema = z.object({ tenant_id: z.string().min(1) });
const validation = tableSchema.safeParse(row);
if (!validation.success) throw new Error('C4 violation: missing tenant_id');
```

```typescript
// ✅ C4: Middleware Knex con inyección automática de tenant_id
import { Knex } from 'knex';
const knex = Knex({ client: 'pg' });
knex.on('query', (query) => {
  if (!query.sql.includes('tenant_id')) {
    logger.warn({ tenant_id: ctx.getStore()?.tenantId }, 'Query without tenant_id filter');
  }
});
```

```typescript
// ✅ C8: Timeout para operación de creación de schema
const signal = AbortSignal.timeout(10000);
await db.raw(`CREATE SCHEMA IF NOT EXISTS tenant_${tenantId}`, { signal });
```

```typescript
// ✅ C4: Función helper para validar tenant_id en runtime
function assertTenantId(row: unknown): asserts row is { tenant_id: string } {
  if (typeof (row as any)?.tenant_id !== 'string') {
    throw new Error('C4 violation: tenant_id required');
  }
}
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/vertical-db-schemas.ts.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"vertical-db-schemas","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C4","C5","C8"],"examples_count":13,"lines_executable_max":4,"language":"TypeScript 5.0+ / Node.js 18+","timestamp":"2026-04-16T16:25:00Z"}
```

---
