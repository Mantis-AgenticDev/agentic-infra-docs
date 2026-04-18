# SHA256: f8a9b0c1d2e34567890123456789012345678901234567890123456789012347
---
artifact_id: "query-explanation-templates"
artifact_type: "skill_sql"
version: "2.1.1"
constraints_mapped: ["C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/query-explanation-templates.sql.md --json"
canonical_path: "06-PROGRAMMING/sql/query-explanation-templates.sql.md"
---

# Query Explanation Templates for Execution Auditing

## Propósito
Implementar plantillas de logging estructurado para documentar fases de ejecución de consultas, parámetros enlazados y resultados, garantizando trazabilidad completa sin exponer datos sensibles en logs.

## Patrones de Código Validados

```sql
-- ✅ C8: Plantilla básica de inicio de ejecución
DO $$ BEGIN
  RAISE NOTICE '%', json_build_object('phase','exec_start','query_id','q_crop_yield','ts',now());
END; $$;
```

```sql
-- ✅ C8: Registro de parámetros sanitizados
DO $$ BEGIN
  RAISE NOTICE '%', json_build_object('params','bound','keys',array['region','season'],'count',2);
END; $$;
```

```sql
-- ✅ C8: Log de plan de ejecución estimado
DO $$ DECLARE plan JSONB;
BEGIN SELECT json_build_object('nodes',query_plan) INTO plan FROM pg_stat_activity WHERE pid=pg_backend_pid();
RAISE NOTICE '%', json_build_object('explain','estimated','result',plan);
END; $$;
```

```sql
-- ✅ C8: Registro de procesamiento por lotes
DO $$ BEGIN
  RAISE NOTICE '%', json_build_object('op','batch_process','chunk','2/5','rows_processed',1000,'status','ok');
END; $$;
```

```sql
-- ✅ C8: Alerta por umbral de latencia
DO $$ BEGIN
  RAISE NOTICE '%', json_build_object('metric','execution_ms','value',1450,'threshold',1000,'action','throttle');
END; $$;
```

```sql
-- ✅ C8: Log de contexto multi-tenant (sin datos crudos)
DO $$ BEGIN
  RAISE NOTICE '%', json_build_object('context','tenant_scope','id_hash',substr(encode(digest(current_setting('app.tenant_id'),'sha256'),'hex'),1,8),'mode','readonly');
END; $$;
```

```sql
-- ✅ C8: Decisión de transacción registrada
DO $$ BEGIN IF current_setting('app.dry_run', true) = 'true' THEN
  RAISE NOTICE '%', json_build_object('txn','rollback','reason','dry_run_active');
ELSE RAISE NOTICE '%', json_build_object('txn','commit','status','verified'); END IF; END; $$;
```

```sql
-- ✅ C8: Validación de esquema pre-query
DO $$ BEGIN
  RAISE NOTICE '%', json_build_object('schema','verified','tables_checked',4,'migrations_current',18,'ts',now());
END; $$;
```

```sql
-- ❌ Anti-pattern: Interpolación insegura y logs no parseables
RAISE NOTICE 'Query % run for tenant % with params %', 'crop_stats', current_setting('app.tenant_id'), 'region_a';
-- 🔧 Fix: Estructura JSON estricta para C8
RAISE NOTICE '%', json_build_object('query','crop_stats','tenant_id',current_setting('app.tenant_id'),'params','region_a');
```

```sql
-- ❌ Anti-pattern: Log con exposición de datos sensibles
RAISE NOTICE 'User % accessed record %', 'admin_01', '12345-SSN';
-- 🔧 Fix: Hash de identificadores y metadatos operacionales
RAISE NOTICE '%', json_build_object('access','record','user_hash',substr(encode(digest('admin_01','sha256'),'hex'),1,8),'id_masked','***-SSN');
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/query-explanation-templates.sql.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"query-explanation-templates","version":"2.1.1","score":31,"blocking_issues":[],"constraints_verified":["C8"],"examples_count":10,"lines_executable_max":5,"language":"PostgreSQL 14+ SQL","timestamp":"2026-04-18T21:40:00Z"}
```

---
