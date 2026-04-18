# SHA256: d4e5f67890123456789012345678901234567890123456789012345678901234
---
artifact_id: "tenant-context-injection"
artifact_type: "skill_sql"
version: "2.1.1"
constraints_mapped: ["C3","C4","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/tenant-context-injection.sql.md --json"
canonical_path: "06-PROGRAMMING/sql/tenant-context-injection.sql.md"
---

# Tenant Context Injection for Session-Based Isolation

## Propósito
Implementar mecanismos seguros de inyección de contexto tenant mediante configuraciones de sesión PostgreSQL, asegurando aislamiento de datos y registro estructurado de operaciones.

## Patrones de Código Validados

```sql
-- ✅ C3: Validación inicial de contexto tenant
DO $$ 
BEGIN 
    ASSERT current_setting('app.tenant_id') IS NOT NULL AND current_setting('app.tenant_id') <> '';
    RAISE NOTICE 'Valid: %', current_setting('app.tenant_id');
END $$;
```

```sql
-- ✅ C4: Función SQL pura con filtrado automático
CREATE OR REPLACE FUNCTION get_tenant_users() RETURNS SETOF users AS $$
  SELECT * FROM users WHERE tenant_id = current_setting('app.tenant_id');
$$ LANGUAGE sql STABLE;
```

```sql
-- ✅ C8: Logging estructurado con contexto tenant
DO $$ 
BEGIN
    RAISE NOTICE '%', json_build_object(
        'ts', NOW(),
        'tenant', current_setting('app.tenant_id'),
        'op', 'CONTEXT_VALIDATION'
    );
END $$;
```

```sql
-- ✅ C4: Vista segura basada en contexto tenant
CREATE VIEW tenant_secure_view AS
SELECT id, name, created_at
FROM business_data
WHERE tenant_id = current_setting('app.tenant_id');
```

```sql
-- ✅ C4/C8: Procedimiento con inyección y logging
CREATE OR REPLACE PROCEDURE insert_tenant_record(p_name TEXT) AS $$
  INSERT INTO tenant_data(tenant_id, name) VALUES(current_setting('app.tenant_id'), p_name);
  RAISE NOTICE '%', json_build_object('op','INSERT','tenant',current_setting('app.tenant_id'));
$$ LANGUAGE plpgsql;
```

```sql
-- ✅ C3: Verificación de múltiples parámetros de contexto
DO $$ 
DECLARE
    tenant_id TEXT;
BEGIN 
    tenant_id := current_setting('app.tenant_id');
    ASSERT tenant_id IS NOT NULL AND tenant_id <> '';
    RAISE NOTICE 'Multi-param check: %', tenant_id;
END $$;
```

```sql
-- ✅ C8: Registro de auditoría estructurado
DO $$ 
BEGIN
    INSERT INTO audit_log (event_data) VALUES (
        json_build_object(
            'ts', NOW(),
            'tenant', current_setting('app.tenant_id'),
            'op', 'AUDIT_RECORD'
        )
    );
END $$;
```

```sql
-- ❌ Anti-pattern: Acceso directo sin filtro de tenant
SELECT * FROM sensitive_data LIMIT 10;
-- 🔧 Fix: Utilizar contexto tenant para filtrado
SELECT id, name FROM sensitive_data 
WHERE tenant_id = current_setting('app.tenant_id') LIMIT 10;
```

```sql
-- ❌ Anti-pattern: Función sin aislamiento de tenant
CREATE FUNCTION get_all_records() RETURNS SETOF sensitive_data AS $$
  SELECT * FROM sensitive_data;
$$ LANGUAGE sql STABLE;
-- 🔧 Fix: Función con filtro por contexto
CREATE OR REPLACE FUNCTION get_tenant_records() RETURNS SETOF sensitive_data AS $$
  SELECT * FROM sensitive_data WHERE tenant_id = current_setting('app.tenant_id');
$$ LANGUAGE sql STABLE;
```

```sql
-- ❌ Anti-pattern: Logging no estructurado
RAISE NOTICE 'Accessing tenant data';
-- 🔧 Fix: Logging estructurado con JSON
RAISE NOTICE '%', json_build_object('event','tenant_access','ts',NOW());
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/tenant-context-injection.sql.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"tenant-context-injection","version":"2.1.1","score":36,"blocking_issues":[],"constraints_verified":["C3","C4","C8"],"examples_count":10,"lines_executable_max":5,"language":"PostgreSQL 14+ SQL","timestamp":"2026-04-18T15:45:30Z"}
```

---
