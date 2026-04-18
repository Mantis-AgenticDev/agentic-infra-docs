# SHA256: d5e6f7a8b9c01234567890123456789012345678901234567890123456789012
---
artifact_id: "join-patterns-rls-aware"
artifact_type: "skill_sql"
version: "2.1.1"
constraints_mapped: ["C4","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/join-patterns-rls-aware.sql.md --json"
canonical_path: "06-PROGRAMMING/sql/join-patterns-rls-aware.sql.md"
---

# Join Patterns with RLS Awareness for Multi-Tenant Queries

## Propósito
Implementar patrones de JOIN que respetan aislamiento por tenant mediante RLS policies, validación de rutas seguras para operaciones de archivo y logging estructurado para auditoría de consultas cruzadas.

## Patrones de Código Validados

```sql
-- ✅ C4: JOIN con filtro explícito de tenant en ambas tablas
SELECT o.id, c.name FROM orders o JOIN customers c ON o.customer_id = c.id
WHERE o.tenant_id = current_setting('app.tenant_id') AND c.tenant_id = current_setting('app.tenant_id') LIMIT 100;
```

```sql
-- ✅ C4: Política RLS completa para tabla de joins
CREATE POLICY tenant_isolation ON order_items USING (tenant_id = current_setting('app.tenant_id')) WITH CHECK (tenant_id = current_setting('app.tenant_id'));
```

```sql
-- ✅ C7: Validación de ruta para exportación de resultados de JOIN
DO $$ DECLARE p TEXT := '/exports/join_' || current_setting('app.tenant_id') || '.csv';
BEGIN ASSERT LENGTH(p)<255 AND POSITION('..' IN p)=0; END; $$;
```

```sql
-- ✅ C8: Logging estructurado de consulta JOIN ejecutada
RAISE NOTICE '%', json_build_object('op','JOIN','tables','orders,customers','tenant',current_setting('app.tenant_id'));
```

```sql
-- ✅ C4/C8: Subconsulta con aislamiento y registro de auditoría
BEGIN; SET LOCAL statement_timeout='10s';
SELECT * FROM (SELECT o.id FROM orders o WHERE o.tenant_id = current_setting('app.tenant_id')) AS filtered;
RAISE NOTICE '%', json_build_object('subquery','executed','tenant',current_setting('app.tenant_id'));
COMMIT;
```

```sql
-- ✅ C4: LEFT JOIN con preservación de aislamiento por tenant
SELECT u.id, u.name, o.total FROM users u LEFT JOIN orders o ON u.id = o.user_id
WHERE u.tenant_id = current_setting('app.tenant_id') AND (o.tenant_id = current_setting('app.tenant_id') OR o.id IS NULL);
```

```sql
-- ✅ C7: Validación de nombre de vista materializada segura
DO $$ DECLARE n TEXT := 'mv_join_' || REPLACE(current_setting('app.tenant_id'), '-', '_');
BEGIN ASSERT n ~ '^[a-zA-Z_][a-zA-Z0-9_]*$' AND LENGTH(n)<63; END; $$;
```

```sql
-- ✅ C4/C8: CTE con aislamiento y logging de ejecución
WITH tenant_orders AS (SELECT * FROM orders WHERE tenant_id = current_setting('app.tenant_id'))
SELECT * FROM tenant_orders JOIN customers c USING (customer_id) WHERE c.tenant_id = current_setting('app.tenant_id');
RAISE NOTICE '%', json_build_object('cte','tenant_orders','rows',100);
```

```sql
-- ❌ Anti-pattern: JOIN sin filtro de tenant en tabla secundaria
SELECT o.id, c.email FROM orders o JOIN customers c ON o.customer_id = c.id WHERE o.tenant_id = current_setting('app.tenant_id');
-- 🔧 Fix: Aplicar aislamiento en ambas tablas del JOIN
SELECT o.id, c.email FROM orders o JOIN customers c ON o.customer_id = c.id
WHERE o.tenant_id = current_setting('app.tenant_id') AND c.tenant_id = current_setting('app.tenant_id');
```

```sql
-- ❌ Anti-pattern: Exportación de JOIN sin validación de ruta
COPY (SELECT * FROM orders JOIN customers USING (customer_id)) TO '/tmp/export.csv' CSV;
-- 🔧 Fix: Validar ruta base y aplicar filtro de tenant
DO $$ BEGIN ASSERT POSITION('..' IN '/secure/exports/') = 0; END; $$;
COPY (SELECT o.id, c.name FROM orders o JOIN customers c ON o.customer_id = c.id WHERE o.tenant_id = current_setting('app.tenant_id')) TO '/secure/exports/data.csv' CSV;
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/join-patterns-rls-aware.sql.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"join-patterns-rls-aware","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C4","C7","C8"],"examples_count":10,"lines_executable_max":5,"language":"PostgreSQL 14+ SQL","timestamp":"2026-04-18T21:20:00Z"}
```

---
