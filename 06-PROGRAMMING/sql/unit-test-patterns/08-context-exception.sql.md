<!-- EXPECT: passed -->
# Este archivo será ignorado por excepción en normas-matrix.json
```sql
-- En producción esto estaría prohibido, pero aquí es solo documentación.
-- SET rls = false;
-- SELECT * FROM orders;
SELECT * FROM orders WHERE tenant_id = $1;
```
