<!-- EXPECT: passed -->
# Solo comentarios, sin código real de bypass
```sql
-- SET rls = false; (esto es un comentario, no debe activar violación)
SELECT * FROM orders WHERE tenant_id = $1;
```
