<!-- EXPECT: passed | DETECT: false | PERF: <500ms -->
# SQL con Caracteres Especiales (compliant C4)

```sql
-- Comentario con comillas: "tenant_id = 'abc'" no es código real
SELECT name FROM users WHERE email = 'user@"example".com' AND tenant_id = $1;

-- Ruta con paréntesis en string
INSERT INTO logs (path, tenant_id) VALUES ('/data/(backup)/file.sql', $2);

-- Backslash en string literal
UPDATE config SET value = 'C:\\Users\\tenant\\config' WHERE key = 'path' AND tenant_id = $1;
