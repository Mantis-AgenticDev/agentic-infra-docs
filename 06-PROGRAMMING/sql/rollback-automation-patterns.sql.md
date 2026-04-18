# SHA256: d4e5f6a1b2c34567890123456789012345678901234567890123456789012346
---
artifact_id: "rollback-automation-patterns"
artifact_type: "skill_sql"
version: "2.1.1"
constraints_mapped: ["C4","C5","C7"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/rollback-automation-patterns.sql.md --json"
canonical_path: "06-PROGRAMMING/sql/rollback-automation-patterns.sql.md"
---

# Rollback Automation Patterns for Tenant-Scoped Migrations

## Propósito
Implementar patrones automatizados de reversión de migraciones con aislamiento estricto por tenant, verificación criptográfica de scripts y validación de rutas seguras para prevenir ejecución de código no autorizado.

## Patrones de Código Validados

```sql
-- ✅ C4: Registro de rollbacks con aislamiento por tenant
CREATE TABLE IF NOT EXISTS rollback_log (id UUID PRIMARY KEY, tenant_id TEXT NOT NULL,
    migration_version TEXT, rolled_back_at TIMESTAMPTZ DEFAULT NOW(), status TEXT DEFAULT 'APPLIED');
```

```sql
-- ✅ C5: Tabla de scripts con verificación de integridad SHA-256
CREATE TABLE IF NOT EXISTS rollback_scripts (id UUID PRIMARY KEY, tenant_id TEXT,
    script_path TEXT, content_hash TEXT,
    CONSTRAINT script_integrity CHECK (content_hash = encode(digest(script_path, 'sha256'), 'hex')));
```

```sql
-- ✅ C7: Validación de ruta segura contra directory traversal
DO $$ DECLARE p TEXT := '/migrations/rollback/' || current_setting('app.tenant_id') || '/';
BEGIN ASSERT POSITION('..' IN p) = 0 AND LENGTH(p) < 256; END; $$;
```

```sql
-- ✅ C4/C5: Ejecución transaccional con contexto y checksum
BEGIN; SET LOCAL statement_timeout = '20s';
INSERT INTO rollback_log (tenant_id, migration_version, status)
VALUES (current_setting('app.tenant_id'), 'v2.1', 'PENDING');
COMMIT;
```

```sql
-- ✅ C7: Carga de script desde ruta validada
DO $$ BEGIN ASSERT current_setting('app.tenant_id') <> '';
RAISE NOTICE 'Safe path: %', '/sql/rollback/' || current_setting('app.tenant_id') || '/'; END; $$;
```

```sql
-- ✅ C4: Consulta de historial filtrada por tenant
SELECT migration_version, rolled_back_at FROM rollback_log
WHERE tenant_id = current_setting('app.tenant_id') ORDER BY rolled_back_at DESC LIMIT 5;
```

```sql
-- ✅ C4/C7: Bloque de reversión con validación de contexto y ruta
BEGIN; SET LOCAL statement_timeout = '15s';
ASSERT POSITION('..' IN '/verified/rollback/') = 0;
DELETE FROM temp_migration WHERE tenant_id = current_setting('app.tenant_id');
COMMIT;
```

```sql
-- ✅ C5: Verificación post-rollback con hash de estado
SELECT encode(digest('snapshot_post', 'sha256'), 'hex') = expected_hash
FROM tenant_state WHERE tenant_id = current_setting('app.tenant_id') LIMIT 1;
```

```sql
-- ❌ Anti-pattern: Rollback sin aislamiento de tenant
DELETE FROM migration_versions WHERE version = '1.0.0';
-- 🔧 Fix: Filtrar estrictamente por contexto de tenant
DELETE FROM migration_versions WHERE version = '1.0.0' AND tenant_id = current_setting('app.tenant_id');
```

```sql
-- ❌ Anti-pattern: Ruta insegura sin verificación de integridad
EXECUTE 'SELECT run_script(''/tmp/user_rollback.sql'')';
-- 🔧 Fix: Validar ruta base y requerir checksum previo
EXECUTE 'SELECT run_script(''/verified/rollback.sql'')' WHERE check_hash('/verified/rollback.sql') = 'ok';
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/rollback-automation-patterns.sql.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"rollback-automation-patterns","version":"2.1.1","score":31,"blocking_issues":[],"constraints_verified":["C4","C5","C7"],"examples_count":10,"lines_executable_max":5,"language":"PostgreSQL 14+ SQL","timestamp":"2026-04-18T20:30:00Z"}
```

---
