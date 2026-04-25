<!-- EXPECT: passed | DETECT: false | PERF: <500ms -->
# Comentario que parece bypass (pero es documentación)

```sql
-- Ejemplo de bypass para tests (NO USAR EN PRODUCCIÓN):
-- Nota: comando antiguo SET rls = false está desactivado
-- -- bypass-rls: este comentario no debe activar la regla

-- ✅ Query real con RLS correcto
SELECT * FROM orders WHERE tenant_id = $1;
```
