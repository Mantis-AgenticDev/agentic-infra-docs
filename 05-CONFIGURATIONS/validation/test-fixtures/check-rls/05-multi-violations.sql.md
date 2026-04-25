<!-- EXPECT: failed | DETECT: true | SEVERITY: CRITICAL+HIGH -->
# Multi-violaciones C4

```sql
SELECT * FROM orders WHERE status = 'pending';
-- SET rls = false;
JOIN users u ON o.user_id = u.id;
```
