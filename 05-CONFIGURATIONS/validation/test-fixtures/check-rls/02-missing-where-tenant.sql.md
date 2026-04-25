<!-- EXPECT: failed | DETECT: true | SEVERITY: CRITICAL -->
# Violación C4

```sql
SELECT * FROM users WHERE status = 'active';
```
