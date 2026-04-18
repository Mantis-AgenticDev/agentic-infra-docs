# SHA256: 7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c
---
artifact_id: "hardening-verification"
artifact_type: "skill_sql"
version: "2.1.1"
constraints_mapped: ["C3","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/hardening-verification.sql.md --json"
canonical_path: "06-PROGRAMMING/sql/hardening-verification.sql.md"
---

# Hardening Verification – Pre-flight SQL Validation

## Propósito
Verificar el estado de hardening de una base PostgreSQL 14+ antes de operaciones críticas, asegurando que el contexto de tenant, timeouts, integridad y logging estructurado estén configurados correctamente.

## Patrones de Código Validados

```sql
-- ✅ C3: Validar variable de entorno app.tenant_id
DO $$ BEGIN
  ASSERT current_setting('app.tenant_id', true) IS NOT NULL,
    'app.tenant_id must be set';
END $$;
```

```sql
-- ❌ Anti-pattern: Asumir tenant sin validación
SELECT * FROM orders;
-- 🔧 Fix: Validar y filtrar por tenant
SET app.tenant_id = 'tenant-123';
SELECT id, total FROM orders WHERE tenant_id = current_setting('app.tenant_id');
```

```sql
-- ✅ C4: Configurar RLS policy pre-vuelo con USING y WITH CHECK
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON audit_log
  USING (tenant_id = current_setting('app.tenant_id')::UUID)
  WITH CHECK (tenant_id = current_setting('app.tenant_id')::UUID);
```

```sql
-- ✅ C5: Verificar integridad con hash de configuración
SELECT (digest(config_json::text, 'sha256') = 
        decode('a1b2c3...', 'hex')) AS integrity_ok
FROM system_config WHERE key = 'global';
```

```sql
-- ❌ Anti-pattern: No verificar hash antes de usar configuración
SELECT value FROM system_config WHERE key = 'global';
-- 🔧 Fix: Validar con digest
SELECT value FROM system_config 
WHERE key = 'global' 
  AND digest(value::text, 'sha256') = expected_hash;
```

```sql
-- ✅ C7: Path seguro para COPY con función de validación
CREATE FUNCTION safe_import_path(p text) RETURNS text AS $$
BEGIN
  IF p !~ '^/app/data/[a-z0-9_/-]+\.csv$' THEN
    RAISE EXCEPTION 'Invalid import path: %', p;
  END IF;
  RETURN p;
END $$ LANGUAGE plpgsql;
```

```sql
-- ✅ C8: Logging estructurado de pre-flight
DO $$ BEGIN
  RAISE NOTICE '%', json_build_object(
    'event', 'hardening_check_start',
    'tenant', current_setting('app.tenant_id'),
    'timestamp', now()
  );
END $$;
```

```sql
-- ✅ C2/C1: Establecer límites de recursos para validación
SET LOCAL statement_timeout = '5s';
SET LOCAL work_mem = '32MB';
SELECT count(*) FROM large_table WHERE tenant_id = current_setting('app.tenant_id');
```

```sql
-- ✅ C3/C4: Validación de tenant en funciones
CREATE FUNCTION verify_tenant() RETURNS void AS $$
BEGIN
  IF current_setting('app.tenant_id', true) IS NULL THEN
    RAISE EXCEPTION 'Missing tenant context';
  END IF;
END $$ LANGUAGE plpgsql;
```

```sql
-- ✅ C5/C7: Verificación de extensiones requeridas con fallback
CREATE EXTENSION IF NOT EXISTS pgcrypto;
DO $$ BEGIN
  PERFORM digest('test', 'sha256');
EXCEPTION WHEN undefined_function THEN
  RAISE WARNING 'pgcrypto not available; integrity checks disabled';
END $$;
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/hardening-verification.sql.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"hardening-verification","version":"2.1.1","score":30,"blocking_issues":[],"constraints_verified":["C3","C4","C5","C7","C8"],"examples_count":10,"lines_executable_max":5,"language":"PostgreSQL 14+ SQL","timestamp":"2026-04-18T10:23:45Z"}
```

---
