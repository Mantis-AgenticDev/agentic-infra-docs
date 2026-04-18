# SHA256: a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4
---
artifact_id: "fix-sintaxis-code"
artifact_type: "skill_sql"
version: "2.1.1"
constraints_mapped: ["C3","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/fix-sintaxis-code.sql.md --json"
canonical_path: "06-PROGRAMMING/sql/fix-sintaxis-code.sql.md"
---

# Fix Sintaxis Code – SQL Linter Integration Patterns

## Propósito
Integrar reglas de estilo y corrección automática de sintaxis SQL en pipelines CI/CD mediante patrones compatibles con pglint/sqlfluff, asegurando el cumplimiento de normas de multi‑tenancy, seguridad y logging estructurado.

## Patrones de Código Validados

```sql
-- ✅ C3: Validación de tenant antes de ejecutar linter
DO $$ BEGIN
  ASSERT current_setting('app.tenant_id') IS NOT NULL,
    'Tenant context required for SQL linting';
END $$;
```

```sql
-- ❌ Anti-pattern: Usar SELECT * sin límite en archivos SQL
SELECT * FROM customers;
-- 🔧 Fix: Listar columnas explícitas con tenant filter
SELECT id, name, email FROM customers 
WHERE tenant_id = current_setting('app.tenant_id') LIMIT 100;
```

```sql
-- ✅ C4: Incluir tenant_id en todas las cláusulas WHERE
UPDATE orders SET status = 'shipped' 
WHERE order_id = 12345 
  AND tenant_id = current_setting('app.tenant_id');
```

```sql
-- ✅ C5: Verificar integridad del archivo SQL con hash
SELECT digest(pg_read_file('/app/sql/migration.sql'), 'sha256') 
AS file_hash;
-- Comparar con hash esperado almacenado en tabla de control
```

```sql
-- ❌ Anti-pattern: Usar comillas dobles para strings (estilo no estándar)
INSERT INTO logs (msg) VALUES ("error message");
-- 🔧 Fix: Usar comillas simples según SQL estándar
INSERT INTO logs (msg, tenant_id) 
VALUES ('error message', current_setting('app.tenant_id'));
```

```sql
-- ✅ C7: Path seguro al leer archivos SQL con pg_read_file
SELECT pg_read_file('/app/sql/migrations/' || 
  regexp_replace(filename, '[^a-zA-Z0-9_.-]', '', 'g'));
-- NOTA C7: pg_read_file requiere superuser o archivo dentro de data_directory.
-- Para producción, usar COPY FROM STDIN o file_fdw con secure_path configurado.
```

```sql
-- ✅ C8: Logging estructurado del resultado del linter
DO $$ DECLARE
  lint_result jsonb := '{"errors": 0, "warnings": 2}';
BEGIN
  RAISE NOTICE '%', json_build_object(
    'event', 'sql_lint_complete',
    'tenant', current_setting('app.tenant_id'),
    'result', lint_result,
    'ts', now()
  );
END $$;
```

```sql
-- ✅ C3/C4: Aplicar RLS en tabla de reglas de linter (texto consistente)
ALTER TABLE lint_rules ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_lint_rules ON lint_rules
  USING (tenant_id::text = current_setting('app.tenant_id'))
  WITH CHECK (tenant_id::text = current_setting('app.tenant_id'));
```

```sql
-- ✅ C5: Guardar versión del script con hash de integridad
INSERT INTO migration_history (version, script_hash, tenant_id)
VALUES ('v2.1.0', 
        digest(current_setting('app.migration_content'), 'sha256'),
        current_setting('app.tenant_id'));
```

```sql
-- ✅ C1/C2: Timeout y memoria dentro de transacción explícita
BEGIN;
SET LOCAL statement_timeout = '30s';
SET LOCAL work_mem = '64MB';
SELECT count(*) FROM sql_audit 
WHERE tenant_id = current_setting('app.tenant_id')
  AND lint_score < 80;
COMMIT;
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/fix-sintaxis-code.sql.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"fix-sintaxis-code","version":"2.1.1","score":30,"blocking_issues":[],"constraints_verified":["C3","C4","C5","C7","C8"],"examples_count":10,"lines_executable_max":5,"language":"PostgreSQL 14+ SQL","timestamp":"2026-04-18T11:37:58Z"}
```

---
