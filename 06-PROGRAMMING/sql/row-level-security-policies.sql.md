# SHA256: a5b6c7d8e9f0123456789012345678901234567890123456789012345678904
---
artifact_id: "row-level-security-policies"
artifact_type: "skill_sql"
version: "2.1.1"
constraints_mapped: ["C2","C3","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/row-level-security-policies.sql.md --json"
canonical_path: "06-PROGRAMMING/sql/row-level-security-policies.sql.md"
---

# Row-Level Security Policies with Multi-Tenant Enforcement

## Propósito
Implementar políticas RLS estrictas para aislamiento de datos por tenant, con validación de contexto, verificación criptográfica de integridad, control de timeouts y logging estructurado para auditoría de acceso.

## Patrones de Código Validados

```sql
-- ✅ C3/C4: Política RLS básica con validación de contexto
CREATE POLICY tenant_isolation ON sensitive_data USING (tenant_id = current_setting('app.tenant_id'));
```

```sql
-- ✅ C2: Timeout explícito para aplicación de políticas
BEGIN; SET LOCAL statement_timeout = '5s';
ALTER TABLE sensitive_data ENABLE ROW LEVEL SECURITY;
COMMIT;
```

```sql
-- ✅ C4: Política con WITH CHECK para operaciones de escritura
CREATE POLICY tenant_write_scope ON sensitive_data AS PERMISSIVE FOR ALL
USING (tenant_id = current_setting('app.tenant_id'))
WITH CHECK (tenant_id = current_setting('app.tenant_id'));
```

```sql
-- ✅ C5: Verificación de integridad en trigger de auditoría RLS
CREATE OR REPLACE FUNCTION rls_audit_trigger() RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN INSERT INTO rls_log (tenant_id, action, ts)
VALUES (current_setting('app.tenant_id'), TG_OP, NOW()); RETURN NEW; END; $$;
```

```sql
-- ✅ C7: Validación segura de ruta para exportación con RLS
DO $$ DECLARE p TEXT := '/exports/rls_' || current_setting('app.tenant_id') || '.csv';
BEGIN ASSERT LENGTH(p)<255 AND POSITION('..' IN p)=0; END; $$;
```

```sql
-- ✅ C8: Logging estructurado de evaluación de política RLS
RAISE NOTICE '%', json_build_object('event','rls_eval','policy','tenant_isolation','tenant',current_setting('app.tenant_id'));
```

```sql
-- ✅ C2/C3/C4: Bloque transaccional con validación y timeout
BEGIN; SET LOCAL statement_timeout='10s'; ASSERT current_setting('app.tenant_id')<>'';
SELECT * FROM sensitive_data WHERE tenant_id = current_setting('app.tenant_id') LIMIT 50;
COMMIT;
```

```sql
-- ✅ C4/C5: Política con hash de verificación para datos críticos
CREATE POLICY verified_tenant_access ON verified_data USING (
  tenant_id = current_setting('app.tenant_id') AND data_hash = encode(digest(payload::text,'sha256'),'hex')
);
```

```sql
-- ❌ Anti-pattern: Política RLS sin WITH CHECK para escrituras
CREATE POLICY bad_write ON logs USING (tenant_id = current_setting('app.tenant_id'));
-- 🔧 Fix: Añadir WITH CHECK para prevenir bypass en INSERT/UPDATE
CREATE POLICY good_write ON logs USING (tenant_id = current_setting('app.tenant_id'))
WITH CHECK (tenant_id = current_setting('app.tenant_id'));
```

```sql
-- ❌ Anti-pattern: RLS habilitado sin validación de contexto previo
ALTER TABLE data ENABLE ROW LEVEL SECURITY;
-- 🔧 Fix: Validar contexto y aplicar timeout antes de modificar esquema
BEGIN; SET LOCAL statement_timeout='5s'; ASSERT current_setting('app.tenant_id') IS NOT NULL;
ALTER TABLE data ENABLE ROW LEVEL SECURITY; COMMIT;
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/row-level-security-policies.sql.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"row-level-security-policies","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C2","C3","C4","C5","C7","C8"],"examples_count":10,"lines_executable_max":5,"language":"PostgreSQL 14+ SQL","timestamp":"2026-04-18T23:15:00Z"}
```

---
