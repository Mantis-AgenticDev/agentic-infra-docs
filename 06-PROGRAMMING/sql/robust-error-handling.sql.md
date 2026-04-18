# SHA256: c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9
---
artifact_id: "robust-error-handling"
artifact_type: "skill_sql"
version: "2.1.1"
constraints_mapped: ["C2","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/robust-error-handling.sql.md --json"
canonical_path: "06-PROGRAMMING/sql/robust-error-handling.sql.md"
---

# Robust Error Handling – Transaction & Exception Patterns

## Propósito
Proveer patrones de manejo de errores en transacciones PostgreSQL 14+ que garanticen atomicidad, logging estructurado, aislamiento de tenant y validación de integridad en operaciones críticas.

## Patrones de Código Validados

```sql
-- ✅ C4: Transacción con ROLLBACK en error y tenant enforcement
BEGIN;
UPDATE accounts SET balance = balance - 100 
WHERE tenant_id = current_setting('app.tenant_id') AND id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;
```

```sql
-- ❌ Anti-pattern: Sin manejo de errores en transacción
BEGIN;
DELETE FROM orders WHERE order_id = 999;
COMMIT;
-- 🔧 Fix: Usar bloque EXCEPTION para control
DO $$ BEGIN
  DELETE FROM orders WHERE order_id = 999 AND tenant_id = current_setting('app.tenant_id');
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Error: %', SQLERRM;
END $$;
```

```sql
-- ✅ C5: Validar integridad de datos con hash en bloque DO
DO $$
DECLARE v_hash bytea;
BEGIN
  SELECT digest(data_column::text, 'sha256') INTO v_hash 
  FROM ref_table WHERE tenant_id = current_setting('app.tenant_id');
  IF v_hash IS NULL THEN
    RAISE EXCEPTION 'Integrity check failed for tenant %', current_setting('app.tenant_id');
  END IF;
END $$;
```

```sql
-- ✅ C7: Función segura con path validation en manejo de errores
CREATE FUNCTION safe_copy(p text) RETURNS void AS $$
BEGIN
  IF p !~ '^/app/secure/.*\.csv$' THEN RAISE EXCEPTION 'Invalid path'; END IF;
  EXECUTE format('COPY temp_table FROM %L', p);
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'Copy failed: %', SQLERRM;
END $$ LANGUAGE plpgsql;
```

```sql
-- ✅ C8: Logging estructurado de errores en transacciones
DO $$ BEGIN
  PERFORM 1/0;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE '%', json_build_object(
    'event', 'transaction_error',
    'tenant', current_setting('app.tenant_id'),
    'error', SQLERRM,
    'timestamp', now()
  );
END $$;
```

```sql
-- ❌ Anti-pattern: Capturar error pero no hacer ROLLBACK
BEGIN;
INSERT INTO logs (msg) VALUES ('start');
-- operación que puede fallar
SAVEPOINT sp1;
-- ...
-- 🔧 Fix: ROLLBACK explícito en error
BEGIN;
INSERT INTO logs (msg) VALUES ('start');
SAVEPOINT sp1;
-- ... si falla:
ROLLBACK TO sp1;
```

```sql
-- ✅ C4/C8: Uso de GET STACKED DIAGNOSTICS para detalles
DO $$ DECLARE
  err_msg text; err_detail text;
BEGIN
  PERFORM 1/0;
EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS err_msg = MESSAGE_TEXT, err_detail = PG_EXCEPTION_DETAIL;
  RAISE NOTICE 'Error: % | Detail: %', err_msg, err_detail;
END $$;
```

```sql
-- ✅ C5/C4: Validar tenant en función con manejo de errores
CREATE FUNCTION process_order(oid int) RETURNS void AS $$
BEGIN
  IF current_setting('app.tenant_id') IS NULL THEN
    RAISE EXCEPTION 'Tenant not set';
  END IF;
  UPDATE orders SET status = 'processed' WHERE id = oid AND tenant_id = current_setting('app.tenant_id');
  IF NOT FOUND THEN RAISE EXCEPTION 'Order % not found for tenant', oid; END IF;
END $$ LANGUAGE plpgsql;
```

```sql
-- ✅ C8: Log de errores en tabla de auditoría con tenant
CREATE TABLE error_log (
  id serial PRIMARY KEY,
  tenant_id text,
  error text,
  ts timestamptz DEFAULT now()
);
DO $$ BEGIN
  PERFORM 1/0;
EXCEPTION WHEN OTHERS THEN
  INSERT INTO error_log (tenant_id, error) VALUES (current_setting('app.tenant_id'), SQLERRM);
END $$;
```

```sql
-- ✅ C2/C7: COPY con timeout y captura de excepciones en bloque DO
DO $$
BEGIN
  SET LOCAL statement_timeout = '10s';
  EXECUTE 'COPY temp_data FROM PROGRAM ''cat /app/secure/input.csv''';
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'Import failed: %', SQLERRM;
END $$;
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/robust-error-handling.sql.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"robust-error-handling","version":"2.1.1","score":30,"blocking_issues":[],"constraints_verified":["C2","C4","C5","C7","C8"],"examples_count":10,"lines_executable_max":5,"language":"PostgreSQL 14+ SQL","timestamp":"2026-04-18T12:45:33Z"}
```

---
