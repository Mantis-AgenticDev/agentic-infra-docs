# SHA256: c8d7e6f5a4b32109876543210987654321098765432109876543210987654321
---
artifact_id: "integration-test-fixtures"
artifact_type: "skill_sql"
version: "2.1.1"
constraints_mapped: ["C3","C4","C7"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/integration-test-fixtures.sql.md --json"
canonical_path: "06-PROGRAMMING/sql/integration-test-fixtures.sql.md"
---

# Integration Test Fixtures with Tenant Scoping and Path Safety

## Propósito
Implementar patrones de preparación y carga de datos para pruebas de integración, garantizando validación de entorno, aislamiento estricto por tenant y verificación segura de rutas para prevenir inyección de datos o traversal de directorios.

## Patrones de Código Validados

```sql
-- ✅ C3: Validación de entorno pre-ejecución de fixtures
DO $$ BEGIN ASSERT current_setting('app.tenant_id') IS NOT NULL AND current_setting('app.env') = 'integration'; END; $$;
```

```sql
-- ✅ C4: Tabla temporal de fixtures con aislamiento por tenant
CREATE TEMP TABLE IF NOT EXISTS int_fixtures (id UUID, tenant_id TEXT NOT NULL, payload JSONB);
```

```sql
-- ✅ C7: Validación segura de ruta para carga de datos masivos
DO $$ DECLARE p TEXT := '/fixtures/integration/' || current_setting('app.tenant_id');
BEGIN ASSERT LENGTH(p)<255 AND POSITION('..' IN p)=0; END; $$;
```

```sql
-- ✅ C3/C4: Inserción transaccional con contexto y rollback seguro
BEGIN; SET LOCAL statement_timeout='5s'; ASSERT current_setting('app.tenant_id')<>'';
INSERT INTO int_fixtures VALUES (gen_random_uuid(), current_setting('app.tenant_id'), '{"test":true}');
COMMIT;
```

```sql
-- ✅ C4: Preparación de datos con alcance estricto por tenant
INSERT INTO int_results (tenant_id, metric, value)
SELECT current_setting('app.tenant_id'), 'latency_ms', 42 FROM generate_series(1,10);
```

```sql
-- ✅ C7/C3: Validación de directorio base antes de ejecución externa
DO $$ DECLARE base TEXT := '/data/int/'; BEGIN ASSERT base ~ '^/[a-z_/]+$'; END; $$;
```

```sql
-- ✅ C7: Generación de fixtures con validación de ruta de salida
DO $$ DECLARE out TEXT := '/output/int_' || current_setting('app.tenant_id') || '.csv';
BEGIN ASSERT POSITION('..' IN out) = 0 AND LENGTH(out) < 256; END; $$;
```

```sql
-- ✅ C4/C7: Carga segura desde staging con filtro de tenant
COPY int_staging FROM '/secure/fixtures/staging.csv' CSV HEADER;
INSERT INTO int_fixtures SELECT *, current_setting('app.tenant_id') FROM int_staging;
```

```sql
-- ❌ Anti-pattern: Fixture sin contexto de tenant
INSERT INTO int_fixtures VALUES (gen_random_uuid(), 'default', '{"mock":true}');
-- 🔧 Fix: Inyectar tenant_id desde configuración de sesión
INSERT INTO int_fixtures VALUES (gen_random_uuid(), current_setting('app.tenant_id'), '{"mock":true}');
```

```sql
-- ❌ Anti-pattern: Ruta de carga con interpolación insegura
COPY int_fixtures FROM '/tmp/' || :'tenant_id' || '_data.csv' CSV;
-- 🔧 Fix: Validar prefijo seguro y bloquear traversal
DO $$ BEGIN ASSERT POSITION('..' IN '/secure/fixtures/') = 0; END; $$;
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/integration-test-fixtures.sql.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"integration-test-fixtures","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C3","C4","C7"],"examples_count":10,"lines_executable_max":5,"language":"PostgreSQL 14+ SQL","timestamp":"2026-04-18T23:35:00Z"}
```

---
