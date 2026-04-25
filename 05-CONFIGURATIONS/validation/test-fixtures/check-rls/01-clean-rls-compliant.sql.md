<!-- EXPECT: passed | DETECT: false | PERF: <500ms -->
# Consulta SQL con RLS Compliant (C4)

```sql
-- ✅ Policy correcta con tenant scoping
CREATE POLICY tenant_isolation_policy ON orders
  USING (tenant_id = current_setting('app.current_tenant'));

-- ✅ Query con filtro explícito de tenant
SELECT id, total, created_at 
FROM orders 
WHERE tenant_id = $1 AND status = 'active';

-- ✅ JOIN multi-tenant con filtro cruzado
SELECT o.id, u.name 
FROM orders o
JOIN users u ON o.user_id = u.id AND u.tenant_id = o.tenant_id
WHERE o.tenant_id = $1;
```
