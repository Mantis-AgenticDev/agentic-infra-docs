<!-- EXPECT: failed -->
# Varias violaciones C4
```sql
SELECT * FROM orders WHERE status = 'pending';
-- SET rls = false;
JOIN users u ON o.user_id = u.id;
```
