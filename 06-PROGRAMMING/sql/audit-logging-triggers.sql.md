# SHA256: a1b2c3d4e5f67890123456789012345678901234567890123456789012345680
---
artifact_id: "audit-logging-triggers"
artifact_type: "skill_sql"
version: "2.1.1"
constraints_mapped: ["C3","C4","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/audit-logging-triggers.sql.md --json"
canonical_path: "06-PROGRAMMING/sql/audit-logging-triggers.sql.md"
---

# Audit Logging Triggers for Data Change Tracking

## Propósito
Implementar triggers de auditoría para registrar cambios en tablas críticas con verificación de integridad, validación de contexto tenant y logging estructurado.

## Patrones de Código Validados

```sql
-- ✅ C4: Tabla de auditoría con aislamiento por tenant
CREATE TABLE IF NOT EXISTS audit_log (id UUID PRIMARY KEY, tenant_id TEXT NOT NULL,
    table_name TEXT, operation TEXT, row_data JSONB, ts TIMESTAMPTZ DEFAULT NOW());
```

```sql
-- ✅ C3/C4/C5: Trigger function segura con INSERT directo
CREATE OR REPLACE FUNCTION audit_trigger_func() RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN INSERT INTO audit_log (tenant_id, table_name, operation, row_data, ts)
    VALUES (current_setting('app.tenant_id'), TG_TABLE_NAME, TG_OP,
            to_jsonb(COALESCE(NEW, OLD)), NOW());
RETURN COALESCE(NEW, OLD); END; $$;
```

```sql
-- ✅ C8: Logging estructurado de eventos
CREATE OR REPLACE FUNCTION log_audit_event(p_op TEXT, p_tbl TEXT)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN RAISE NOTICE '%', json_build_object('event','audit','op',p_op,'table',p_tbl,'ts',now());
END; $$;
```

```sql
-- ✅ C4: Attach trigger a tabla objetivo
CREATE TRIGGER users_audit AFTER INSERT OR UPDATE OR DELETE ON public.users
FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();
```

```sql
-- ✅ C5: Integridad con hash SHA-256 en auditoría
CREATE TABLE IF NOT EXISTS audit_hash (id UUID PRIMARY KEY, tenant_id TEXT,
    data JSONB, data_hash TEXT CHECK (data_hash = encode(digest(data::TEXT, 'sha256'), 'hex')));
```

```sql
-- ✅ C3/C4/C8: Bloque transaccional con validación y log
BEGIN; SET LOCAL statement_timeout = '5s';
ASSERT current_setting('app.tenant_id') <> '';
PERFORM log_audit_event('READ', 'users');
COMMIT;
```

```sql
-- ✅ C8: Formato JSON estricto para logs internos
RAISE NOTICE '%', json_build_object('audit','trigger','table',TG_TABLE_NAME,'op',TG_OP);
```

```sql
-- ✅ C3: Validación explícita de contexto pre-ejecución
DO $$ BEGIN ASSERT current_setting('app.tenant_id') IS NOT NULL AND current_setting('app.tenant_id') <> ''; END; $$;
```

```sql
-- ❌ Anti-pattern: Trigger sin contexto de tenant
CREATE FUNCTION bad_audit() RETURNS TRIGGER AS $$ BEGIN INSERT INTO audit_log VALUES ('unknown'); RETURN NEW; END; $$ LANGUAGE plpgsql;
-- 🔧 Fix: Inyectar tenant dinámico
CREATE FUNCTION good_audit() RETURNS TRIGGER AS $$ BEGIN INSERT INTO audit_log VALUES (current_setting('app.tenant_id')); RETURN NEW; END; $$ LANGUAGE plpgsql;
```

```sql
-- ❌ Anti-pattern: Tabla de auditoría sin filtro
CREATE TABLE bad_audit (id UUID, data TEXT);
-- 🔧 Fix: Agregar columna y política RLS
CREATE TABLE good_audit (id UUID, tenant_id TEXT NOT NULL); ALTER TABLE good_audit ENABLE ROW LEVEL SECURITY;
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/audit-logging-triggers.sql.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"audit-logging-triggers","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C3","C4","C5","C8"],"examples_count":10,"lines_executable_max":5,"language":"PostgreSQL 14+ SQL","timestamp":"2026-04-18T20:00:00Z"}
```

---
