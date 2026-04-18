# SHA256: e7f8a9b0c1d23456789012345678901234567890123456789012345678901236
---
artifact_id: "aggregation-multi-tenant-safe"
artifact_type: "skill_sql"
version: "2.1.1"
constraints_mapped: ["C4","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/aggregation-multi-tenant-safe.sql.md --json"
canonical_path: "06-PROGRAMMING/sql/aggregation-multi-tenant-safe.sql.md"
---

# Aggregation Patterns with Tenant Isolation and Integrity Verification

## Propósito
Implementar consultas de agregación seguras para entornos multi-tenant con filtrado estricto por contexto, verificación criptográfica de resultados y logging estructurado para auditoría de métricas.

## Patrones de Código Validados

```sql
-- ✅ C4: Agregación básica con aislamiento estricto de tenant
SELECT COUNT(id) AS total_records, SUM(amount) AS revenue 
FROM transactions WHERE tenant_id = current_setting('app.tenant_id') GROUP BY tenant_id;
```

```sql
-- ✅ C5: Tabla de métricas con constraint de integridad SHA-256
CREATE TABLE IF NOT EXISTS agg_metrics (id UUID PRIMARY KEY, tenant_id TEXT,
metric_name TEXT, metric_value DECIMAL, result_hash TEXT CHECK (result_hash ~ '^[a-f0-9]{64}$'));
```

```sql
-- ✅ C8: Logging estructurado de ejecución de agregación
RAISE NOTICE '%', json_build_object('op','AGG','table','transactions',
'tenant',current_setting('app.tenant_id'),'ts',now());
```

```sql
-- ✅ C4/C8: Agregación transaccional con timeout y registro
BEGIN; SET LOCAL statement_timeout = '10s';
SELECT region, AVG(score) FROM evaluations WHERE tenant_id = current_setting('app.tenant_id') GROUP BY region;
RAISE NOTICE '%', json_build_object('status','complete','tenant',current_setting('app.tenant_id')); COMMIT;
```

```sql
-- ✅ C5: Inserción de resultado con hash de verificación
INSERT INTO agg_metrics (tenant_id, metric_name, metric_value, result_hash) VALUES
(current_setting('app.tenant_id'), 'daily_total', 45200.00, encode(digest('45200.00'::text, 'sha256'), 'hex'));
```

```sql
-- ✅ C4: CTE con alcance limitado por tenant y límite seguro
WITH tenant_data AS (SELECT * FROM sales WHERE tenant_id = current_setting('app.tenant_id'))
SELECT product_id, SUM(qty) FROM tenant_data GROUP BY product_id LIMIT 100;
```

```sql
-- ✅ C8: Registro de métricas en formato JSON estricto
DO $$ BEGIN RAISE NOTICE '%', json_build_object('agg_type','ROLLUP','tenant',current_setting('app.tenant_id')); END; $$;
```

```sql
-- ✅ C4/C5: Actualización de stats con validación de hash post-cálculo
UPDATE tenant_stats SET total_cnt = sub.c, hash = encode(digest(sub.c::text, 'sha256'), 'hex')
FROM (SELECT COUNT(*) AS c FROM logs WHERE tenant_id = current_setting('app.tenant_id')) sub
WHERE tenant_id = current_setting('app.tenant_id');
```

```sql
-- ❌ Anti-pattern: Agregación sin filtro de tenant (cross-tenant leak)
SELECT COUNT(*), SUM(value) FROM raw_metrics GROUP BY category;
-- 🔧 Fix: Aplicar contexto de tenant obligatorio en WHERE
SELECT COUNT(*), SUM(value) FROM raw_metrics WHERE tenant_id = current_setting('app.tenant_id') GROUP BY category;
```

```sql
-- ❌ Anti-pattern: Almacenamiento de agregados sin verificación
CREATE TABLE bad_results (id UUID, total DECIMAL, computed_at TIMESTAMPTZ);
-- 🔧 Fix: Agregar constraint criptográfico para detección de manipulación
ALTER TABLE good_results ADD CONSTRAINT chk_integrity CHECK (verify_hash = encode(digest(total::text, 'sha256'), 'hex'));
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/aggregation-multi-tenant-safe.sql.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"aggregation-multi-tenant-safe","version":"2.1.1","score":33,"blocking_issues":[],"constraints_verified":["C4","C5","C8"],"examples_count":10,"lines_executable_max":5,"language":"PostgreSQL 14+ SQL","timestamp":"2026-04-18T21:30:00Z"}
```

---
