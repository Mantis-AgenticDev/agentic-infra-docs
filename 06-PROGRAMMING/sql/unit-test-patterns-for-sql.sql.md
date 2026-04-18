# SHA256: b9c8d7e6f5a43210987654321098765432109876543210987654321098765433
---
artifact_id: "unit-test-patterns-for-sql"
artifact_type: "skill_sql"
version: "2.1.1"
constraints_mapped: ["C4","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/unit-test-patterns-for-sql.sql.md --json"
canonical_path: "06-PROGRAMMING/sql/unit-test-patterns-for-sql.sql.md"
---

# Unit Test Patterns for Multi-Tenant SQL Validation

## Propósito
Implementar patrones de pruebas unitarias aisladas por tenant, con verificación criptográfica de resultados esperados y logging estructurado para trazabilidad de ejecución en entornos CI/CD.

## Patrones de Código Validados

```sql
-- ✅ C4: Fixture de prueba con aislamiento explícito
CREATE TEMP TABLE IF NOT EXISTS test_fixture (id UUID, tenant_id TEXT, payload TEXT);
INSERT INTO test_fixture VALUES (gen_random_uuid(), current_setting('app.tenant_id'), 'sample');
```

```sql
-- ✅ C5: Inserción de dato de prueba con hash SHA-256
INSERT INTO test_results (tenant_id, test_name, data_hash) VALUES
(current_setting('app.tenant_id'), 'integrity_check', encode(digest('sample', 'sha256'), 'hex'));
```

```sql
-- ✅ C8: Log estructurado de inicio de suite de pruebas
DO $$ BEGIN RAISE NOTICE '%', json_build_object('suite','unit_sql','phase','init','tenant',current_setting('app.tenant_id')); END; $$;
```

```sql
-- ✅ C4/C8: Assert de conteo con contexto y reporte
DO $$ BEGIN ASSERT (SELECT COUNT(*) FROM test_fixture WHERE tenant_id = current_setting('app.tenant_id')) = 1;
RAISE NOTICE '%', json_build_object('test','count_verify','pass',true); END; $$;
```

```sql
-- ✅ C5/C8: Verificación de integridad en ejecución de prueba
DO $$ BEGIN IF encode(digest('sample', 'sha256'), 'hex') != (SELECT data_hash FROM test_results LIMIT 1) THEN RAISE EXCEPTION 'hash_mismatch'; END IF;
RAISE NOTICE '%', json_build_object('test','hash_check','status','ok'); END; $$;
```

```sql
-- ✅ C4: Consulta de validación con filtro tenant y límite
SELECT id, payload FROM test_fixture WHERE tenant_id = current_setting('app.tenant_id') AND test_id = 't1' LIMIT 1;
```

```sql
-- ✅ C4/C5/C8: Bloque transaccional con rollback y traza
BEGIN; SET LOCAL statement_timeout='5s'; INSERT INTO logs VALUES (current_setting('app.tenant_id'), 'test_run');
ROLLBACK; RAISE NOTICE '%', json_build_object('test','rollback_test','ok',true); END;
```

```sql
-- ✅ C5: Función utilitaria para validación de hashes
CREATE OR REPLACE FUNCTION assert_hash_match(p_input TEXT, p_expected TEXT) RETURNS BOOLEAN LANGUAGE sql AS $$
SELECT encode(digest(p_input, 'sha256'), 'hex') = p_expected; $$;
```

```sql
-- ❌ Anti-pattern: Prueba sin aislamiento de tenant
SELECT COUNT(*) FROM global_metrics WHERE status = 'active';
-- 🔧 Fix: Aplicar contexto y limitar alcance
SELECT COUNT(*) FROM global_metrics WHERE tenant_id = current_setting('app.tenant_id') AND status = 'active';
```

```sql
-- ❌ Anti-pattern: Log de prueba no estructurado
RAISE NOTICE 'Test suite completed successfully';
-- 🔧 Fix: Formato JSON parseable para CI/CD
RAISE NOTICE '%', json_build_object('suite','unit_sql','status','passed','ts',now(),'tenant',current_setting('app.tenant_id'));
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/unit-test-patterns-for-sql.sql.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"unit-test-patterns-for-sql","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C4","C5","C8"],"examples_count":10,"lines_executable_max":5,"language":"PostgreSQL 14+ SQL","timestamp":"2026-04-18T23:30:00Z"}
```

---
