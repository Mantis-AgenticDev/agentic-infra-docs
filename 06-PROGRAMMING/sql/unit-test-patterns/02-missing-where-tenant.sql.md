<!-- EXPECT: failed -->
# Violación: DML sin tenant_id
```sql
SELECT * FROM users WHERE status = 'active';
```
