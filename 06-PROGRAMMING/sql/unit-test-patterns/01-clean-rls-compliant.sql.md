<!-- EXPECT: passed -->
# Consulta SQL compliant C4
```sql
SELECT * FROM orders WHERE tenant_id = 'tenant_a';
UPDATE orders SET status = 'done' WHERE tenant_id = 'tenant_b';
DELETE FROM orders WHERE tenant_id = $1;
INSERT INTO orders (tenant_id, product) VALUES ('tenant_c', 'test');
```
