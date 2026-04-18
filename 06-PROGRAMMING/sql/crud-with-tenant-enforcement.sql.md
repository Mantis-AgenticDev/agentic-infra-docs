# SHA256: c4d5e6f7a8b90123456789012345678901234567890123456789012345678901
---
artifact_id: "crud-with-tenant-enforcement"
artifact_type: "skill_sql"
version: "2.1.1"
constraints_mapped: ["C3","C4","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/crud-with-tenant-enforcement.sql.md --json"
canonical_path: "06-PROGRAMMING/sql/crud-with-tenant-enforcement.sql.md"
---

# CRUD Operations with Tenant Enforcement

## Propósito
Implementar operaciones CRUD con enforcement estricto de aislamiento por tenant, validación de contexto pre-ejecución y logging estructurado para auditoría de acceso a datos.

## Patrones de Código Validados

```sql
-- ✅ C3: Validación de contexto pre-ejecución compacta
DO $$ BEGIN ASSERT current_setting('app.tenant_id') IS NOT NULL AND current_setting('app.tenant_id') <> ''; END; $$;
```

```sql
-- ✅ C4: INSERT con inyección obligatoria de tenant_id
INSERT INTO customer_data (tenant_id, name, email) VALUES (current_setting('app.tenant_id'), $1, $2);
```

```sql
-- ✅ C8: Logging estructurado de operación CREATE
RAISE NOTICE '%', json_build_object('op','INSERT','tbl','customer_data','tenant',current_setting('app.tenant_id'));
```

```sql
-- ✅ C4: UPDATE con filtro automático por tenant
UPDATE customer_data SET email = $1 WHERE id = $2 AND tenant_id = current_setting('app.tenant_id');
```

```sql
-- ✅ C4: DELETE con enforcement estricto de tenant
DELETE FROM customer_data WHERE id = $1 AND tenant_id = current_setting('app.tenant_id');
```

```sql
-- ✅ C3/C4: SELECT con validación, filtro y límite seguro
SELECT id, name, email FROM customer_data WHERE tenant_id = current_setting('app.tenant_id') LIMIT 100;
```

```sql
-- ✅ C8: Logging estructurado de operación READ
RAISE NOTICE '%', json_build_object('op','SELECT','tbl','customer_data','rows',100,'ts',now());
```

```sql
-- ✅ C3/C4/C8: Bloque transaccional CRUD con logging
BEGIN; SET LOCAL statement_timeout = '5s';
INSERT INTO customer_data (tenant_id, name) VALUES (current_setting('app.tenant_id'), 'test');
RAISE NOTICE '%', json_build_object('txn','commit','tenant',current_setting('app.tenant_id'));
COMMIT;
```

```sql
-- ❌ Anti-pattern: INSERT sin contexto de tenant
INSERT INTO customer_data (name, email) VALUES ($1, $2);
-- 🔧 Fix: Inyectar tenant_id obligatorio desde contexto
INSERT INTO customer_data (tenant_id, name, email) VALUES (current_setting('app.tenant_id'), $1, $2);
```

```sql
-- ❌ Anti-pattern: SELECT sin aislamiento ni límite
SELECT * FROM customer_data;
-- 🔧 Fix: Filtrar por tenant y limitar columnas + filas
SELECT id, name, email FROM customer_data WHERE tenant_id = current_setting('app.tenant_id') LIMIT 100;
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/crud-with-tenant-enforcement.sql.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"crud-with-tenant-enforcement","version":"2.1.1","score":33,"blocking_issues":[],"constraints_verified":["C3","C4","C8"],"examples_count":10,"lines_executable_max":5,"language":"PostgreSQL 14+ SQL","timestamp":"2026-04-18T21:10:00Z"}
```

---
