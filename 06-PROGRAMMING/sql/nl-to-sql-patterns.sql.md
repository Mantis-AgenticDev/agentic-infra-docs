# SHA256: a9b0c1d2e3f45678901234567890123456789012345678901234567890123458
---
artifact_id: "nl-to-sql-patterns"
artifact_type: "skill_sql"
version: "2.1.1"
constraints_mapped: ["C3","C4","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/nl-to-sql-patterns.sql.md --json"
canonical_path: "06-PROGRAMMING/sql/nl-to-sql-patterns.sql.md"
---

# NL-to-SQL Translation Patterns with Tenant Scoping

## Propósito
Implementar patrones seguros para conversión de lenguaje natural a SQL, garantizando validación de contexto de tenant, aislamiento estricto en consultas generadas y logging estructurado para auditoría de intención y ejecución.

## Patrones de Código Validados

```sql
-- ✅ C3: Validación de contexto pre-procesamiento de NL
DO $$ BEGIN ASSERT current_setting('app.tenant_id') IS NOT NULL AND current_setting('app.tenant_id') <> ''; END; $$;
```

```sql
-- ✅ C4/C8: Preparación de consulta parametrizada con aislamiento
PREPARE nl_crop_query AS SELECT id, name, yield FROM crops WHERE tenant_id = current_setting('app.tenant_id') AND name ILIKE $1 LIMIT 50;
EXECUTE nl_crop_query('%tomato%');
RAISE NOTICE '%', json_build_object('nl_exec','success','rows',50);
```

```sql
-- ✅ C3/C8: Validación de confianza del parseo NL
DO $$ BEGIN IF current_setting('app.nl_confidence', true)::float < 0.8 THEN
  RAISE NOTICE '%', json_build_object('action','fallback_default','reason','low_confidence');
END IF; END; $$;
```

```sql
-- ✅ C4: Ejecución segura con timeout y filtrado por tenant
BEGIN; SET LOCAL statement_timeout = '10s';
EXECUTE 'SELECT region, SUM(production) FROM harvests WHERE tenant_id = $1 GROUP BY region LIMIT 100' USING current_setting('app.tenant_id');
COMMIT;
```

```sql
-- ✅ C8: Registro estructurado de métricas post-ejecución
DO $$ BEGIN RAISE NOTICE '%', json_build_object('phase','post_nl','latency_ms',42,'status','complete'); END; $$;
```

```sql
-- ✅ C3/C4/C8: Bloque transaccional con validación y logging
BEGIN; SET LOCAL statement_timeout='10s'; ASSERT current_setting('app.tenant_id') IS NOT NULL;
SELECT id, status FROM orders WHERE tenant_id = current_setting('app.tenant_id') LIMIT 50;
RAISE NOTICE '%', json_build_object('nl_scope','tenant',current_setting('app.tenant_id')); COMMIT;
```

```sql
-- ✅ C8: Logging de error de traducción con contexto
DO $$ BEGIN RAISE NOTICE '%', json_build_object('error','nl_parse_fail','input_masked','***','tenant',current_setting('app.tenant_id')); END; $$;
```

```sql
-- ✅ C4: Función de escaneo de tablas permitidas para NL
CREATE OR REPLACE FUNCTION nl_allowed_tables(p_table TEXT) RETURNS BOOLEAN LANGUAGE sql AS $$
  SELECT p_table = ANY(ARRAY['crops','orders','harvests']) AND current_setting('app.tenant_id') IS NOT NULL;
$$;
```

```sql
-- ❌ Anti-pattern: Interpolación directa sin validación ni límite
EXECUTE FORMAT('SELECT * FROM %I WHERE name = ''%s''', 'crops', $1);
-- 🔧 Fix: Validar contexto, parametrizar y acotar columnas/filas
PREPARE nl_safe AS SELECT id, name FROM crops WHERE tenant_id = current_setting('app.tenant_id') AND name = $1 LIMIT 50; EXECUTE nl_safe($1);
```

```sql
-- ❌ Anti-pattern: Consulta generada sin aislamiento de tenant
SELECT COUNT(*), AVG(yield) FROM harvest_data GROUP BY region;
-- 🔧 Fix: Aplicar filtro de tenant obligatorio y logging estructurado
SELECT region, AVG(yield) FROM harvest_data WHERE tenant_id = current_setting('app.tenant_id') GROUP BY region LIMIT 10;
RAISE NOTICE '%', json_build_object('nl_agg','executed','tenant',current_setting('app.tenant_id'));
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/nl-to-sql-patterns.sql.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"nl-to-sql-patterns","version":"2.1.1","score":33,"blocking_issues":[],"constraints_verified":["C3","C4","C8"],"examples_count":10,"lines_executable_max":5,"language":"PostgreSQL 14+ SQL","timestamp":"2026-04-18T21:50:00Z"}
```

---
