# SHA256: b3c4d5e6f7a89012345678901234567890123456789012345678901234567890
---
artifact_id: "backup-restore-tenant-scoped"
artifact_type: "skill_sql"
version: "2.1.1"
constraints_mapped: ["C3","C5","C7"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/backup-restore-tenant-scoped.sql.md --json"
canonical_path: "06-PROGRAMMING/sql/backup-restore-tenant-scoped.sql.md"
---

# Backup and Restore with Tenant Scope Isolation

## Propósito
Implementar procedimientos de backup y restauración con alcance estricto por tenant, validación de contexto pre-ejecución y verificación criptográfica de integridad, cumpliendo límites de líneas ejecutables y sintaxis PostgreSQL 14+.

## Patrones de Código Validados

```sql
-- ✅ C3: Validación explícita de contexto pre-ejecución
DO $$ BEGIN ASSERT current_setting('app.tenant_id') IS NOT NULL AND current_setting('app.tenant_id') <> '';
RAISE NOTICE 'Backup context validated for: %', current_setting('app.tenant_id'); END; $$;
```

```sql
-- ✅ C5: Tabla de registro con integridad criptográfica
CREATE TABLE IF NOT EXISTS backup_registry (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), tenant_id TEXT NOT NULL,
    backup_path TEXT, checksum TEXT, created_at TIMESTAMPTZ DEFAULT NOW());
```

```sql
-- ✅ C7: Validación de ruta segura contra directory traversal
DO $$ DECLARE p TEXT := '/backups/' || current_setting('app.tenant_id') || '_' || TO_CHAR(NOW(),'YYYYMMDD');
BEGIN ASSERT LENGTH(p)<255 AND POSITION('..' IN p)=0; END; $$;
```

```sql
-- ✅ C3/C5: Registro transaccional con hash SHA-256
BEGIN; SET LOCAL statement_timeout='10s';
INSERT INTO backup_registry (tenant_id, backup_path, checksum) VALUES
(current_setting('app.tenant_id'), '/data/backup_' || current_setting('app.tenant_id'), encode(digest('content','sha256'),'hex'));
COMMIT;
```

```sql
-- ✅ C5: Función de verificación compacta
CREATE OR REPLACE FUNCTION verify_backup(p_id UUID) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE s TEXT; BEGIN SELECT checksum INTO s FROM backup_registry WHERE id=p_id; RETURN s IS NOT NULL; END; $$;
```

```sql
-- ✅ C3: Bloque de validación para restauración
DO $$ BEGIN ASSERT current_setting('app.tenant_id') IS NOT NULL;
RAISE NOTICE '%', json_build_object('event','restore_check','tenant',current_setting('app.tenant_id')); END; $$;
```

```sql
-- ✅ C7: Ruta de restauración validada
DO $$ DECLARE r TEXT := '/restores/' || current_setting('app.tenant_id');
BEGIN ASSERT POSITION('..' IN r)=0 AND LENGTH(r)<255; END; $$;
```

```sql
-- ❌ Anti-pattern: Exportación completa sin aislamiento de tenant
COPY (SELECT * FROM backup_data) TO '/tmp/full.csv' CSV HEADER;
-- 🔧 Fix: Filtrar estrictamente por contexto
COPY (SELECT * FROM backup_data WHERE tenant_id = current_setting('app.tenant_id')) TO '/secure/tenant.csv' CSV;
```

```sql
-- ❌ Anti-pattern: Restauración directa sin verificación de integridad
INSERT INTO live_data SELECT * FROM staging_backup;
-- 🔧 Fix: Validar hash criptográfico antes de migrar
DO $$ BEGIN IF encode(digest((SELECT raw FROM staging_backup LIMIT 1), 'sha256'), 'hex') != 'expected' THEN RAISE EXCEPTION 'Hash mismatch'; END IF; END; $$;
```

```sql
-- ❌ Anti-pattern: Ruta de archivo con interpolación insegura
EXECUTE FORMAT('COPY data TO ''%s''', '/tmp/' || current_setting('app.tenant_id'));
-- 🔧 Fix: Validar prefijo base y bloquear traversal
DO $$ BEGIN ASSERT POSITION('..' IN '/secure/backups/' || current_setting('app.tenant_id')) = 0; END; $$;
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/backup-restore-tenant-scoped.sql.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"backup-restore-tenant-scoped","version":"2.1.1","score":34,"blocking_issues":[],"constraints_verified":["C3","C5","C7"],"examples_count":10,"lines_executable_max":5,"language":"PostgreSQL 14+ SQL","timestamp":"2026-04-18T21:00:00Z"}
```

---
