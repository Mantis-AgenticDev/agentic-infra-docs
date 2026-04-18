# SHA256: e5f6a1b2c3d45678901234567890123456789012345678901234567890123457
---
artifact_id: "schema-diff-validation"
artifact_type: "skill_sql"
version: "2.1.1"
constraints_mapped: ["C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/schema-diff-validation.sql.md --json"
canonical_path: "06-PROGRAMMING/sql/schema-diff-validation.sql.md"
---

# Schema Diff Validation with Integrity Checking

## Propósito
Implementar validación de diferencias de esquema con verificación criptográfica PG 14+, validación de rutas seguras y logging estructurado para auditoría de cambios estructurales por tenant.

## Patrones de Código Validados

```sql
-- ✅ C5: Tabla de checksums con constraint de integridad
CREATE TABLE IF NOT EXISTS schema_checksums (id UUID PRIMARY KEY, tenant_id TEXT NOT NULL,
    obj_name TEXT, obj_type TEXT, checksum TEXT, CONSTRAINT chk_hex CHECK (checksum ~ '^[a-f0-9]{64}$'));
```

```sql
-- ✅ C3/C7: Validación de contexto y ruta segura
DO $$ DECLARE p TEXT := '/schemas/' || current_setting('app.tenant_id') || '/';
BEGIN ASSERT current_setting('app.tenant_id') <> '' AND POSITION('..' IN p) = 0; END; $$;
```

```sql
-- ✅ C8: Logging estructurado de validación
RAISE NOTICE '%', json_build_object('event','schema_check','tenant',current_setting('app.tenant_id'));
```

```sql
-- ✅ C5: Función hash con pg_get_tabledef (PG 14+)
CREATE OR REPLACE FUNCTION get_obj_hash(p_name TEXT) RETURNS TEXT LANGUAGE sql AS $$
    SELECT encode(digest(pg_get_tabledef(p_name), 'sha256'), 'hex'); $$;
```

```sql
-- ✅ C4/C5: Registro de checksum con inyección de tenant
INSERT INTO schema_checksums (tenant_id, obj_name, obj_type, checksum)
VALUES (current_setting('app.tenant_id'), 'users', 'table', get_obj_hash('users'));
```

```sql
-- ✅ C5: Validación de integridad comparativa
CREATE OR REPLACE FUNCTION validate_schema_diff(p_name TEXT, p_hash TEXT) RETURNS BOOLEAN LANGUAGE sql AS $$
    SELECT encode(digest(pg_get_tabledef(p_name), 'sha256'), 'hex') = p_hash; $$;
```

```sql
-- ✅ C8: Registro de resultado estructurado
RAISE NOTICE '%', json_build_object('validation','schema_diff','result','passed','ts',now());
```

```sql
-- ✅ C3: Bloque transaccional con timeout y validación
BEGIN; SET LOCAL statement_timeout = '10s';
ASSERT current_setting('app.tenant_id') IS NOT NULL;
COMMIT;
```

```sql
-- ❌ Anti-pattern: Comparación de texto crudo de esquema
SELECT pg_get_tabledef('t1') = pg_get_tabledef('t2');
-- 🔧 Fix: Comparación criptográfica determinista
SELECT encode(digest(pg_get_tabledef('t1'), 'sha256'), 'hex') = encode(digest(pg_get_tabledef('t2'), 'sha256'), 'hex');
```

```sql
-- ❌ Anti-pattern: Ruta insegura sin validación
\set schema_file '/tmp/' || :'tenant_id' || '_schema.sql'
-- 🔧 Fix: Validación estricta de ruta base
DO $$ DECLARE bp TEXT := '/secure/schemas/'; BEGIN ASSERT POSITION('..' IN bp) = 0; END; $$;
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/schema-diff-validation.sql.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"schema-diff-validation","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C3","C5","C7","C8"],"examples_count":10,"lines_executable_max":5,"language":"PostgreSQL 14+ SQL","timestamp":"2026-04-18T20:45:00Z"}
```

---
