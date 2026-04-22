<!-- EXPECT: passed -->
# SQL con caracteres especiales, pero compliant
```sql
SELECT name FROM users WHERE email = 'user@example.com' AND tenant_id = $1;
INSERT INTO logs (path, tenant_id) VALUES ('/data/(backup)/file.sql', $2);
```
