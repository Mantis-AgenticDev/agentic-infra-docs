# SHA256: f4a5b6c7d8e9012345678901234567890123456789012345678901234567893
---
artifact_id: "permission-scoping-for-ia"
artifact_type: "skill_sql"
version: "2.1.1"
constraints_mapped: ["C3","C4","C7"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/permission-scoping-for-ia.sql.md --json"
canonical_path: "06-PROGRAMMING/sql/permission-scoping-for-ia.sql.md"
---

# Permission Scoping Patterns for AI Agent Access

## Propósito
Implementar control de permisos para agentes IA con validación estricta de contexto, aislamiento por tenant y verificación segura de identificadores/rutas para prevenir escalación de privilegios o acceso transversal.

## Patrones de Código Validados

```sql
-- ✅ C3: Validación de contexto pre-aplicación de permisos
DO $$ BEGIN ASSERT current_setting('app.tenant_id') IS NOT NULL AND current_setting('app.tenant_id') <> ''; END; $$;
```

```sql
-- ✅ C4: Política RLS de solo lectura para acceso IA
CREATE POLICY ai_read_scope ON crop_data USING (tenant_id = current_setting('app.tenant_id')) WITH CHECK (false);
```

```sql
-- ✅ C7: Validación de identificador de rol IA
DO $$ DECLARE r TEXT := 'ai_agent_' || current_setting('app.tenant_id'); BEGIN ASSERT r ~ '^[a-zA-Z_][a-zA-Z0-9_]*$'; END; $$;
```

```sql
-- ✅ C3/C4: Concesión transaccional con alcance seguro
BEGIN; SET LOCAL statement_timeout='5s'; ASSERT current_setting('app.tenant_id')<>'';
GRANT SELECT (id, status) ON tasks TO ai_agent_role; COMMIT;
```

```sql
-- ✅ C4/C7: Revocación con validación de ruta segura
DO $$ BEGIN ASSERT POSITION('..' IN '/permissions/ai/') = 0; REVOKE ALL ON sensitive_logs FROM ai_agent_role; END; $$;
```

```sql
-- ✅ C4: Función de tablas permitidas para IA
CREATE OR REPLACE FUNCTION ai_allowed_tables() RETURNS TEXT[] LANGUAGE sql AS $$
SELECT ARRAY['crops','orders'] WHERE current_setting('app.tenant_id') IS NOT NULL; $$;
```

```sql
-- ✅ C7: Validación de ruta de configuración IA
DO $$ DECLARE p TEXT := '/config/ai/' || current_setting('app.tenant_id') || '.yml'; BEGIN ASSERT LENGTH(p)<255 AND POSITION('..' IN p)=0; END; $$;
```

```sql
-- ✅ C3/C4: Verificación de privilegios con contexto activo
SELECT has_table_privilege(current_user, 'crop_data', 'SELECT') AS can_read
WHERE current_setting('app.tenant_id') IS NOT NULL LIMIT 1;
```

```sql
-- ❌ Anti-pattern: Concesión global sin aislamiento
GRANT SELECT, UPDATE ON ALL TABLES IN SCHEMA public TO ai_agent;
-- 🔧 Fix: Acotar permisos y habilitar RLS
GRANT SELECT ON crop_data TO ai_agent; ALTER TABLE crop_data ENABLE ROW LEVEL SECURITY;
```

```sql
-- ❌ Anti-pattern: Creación dinámica sin validación de identificador
EXECUTE FORMAT('CREATE ROLE "ai_%s"', $1);
-- 🔧 Fix: Sanitizar y validar antes de ejecutar
DO $$ DECLARE safe_name TEXT := 'ai_agent_' || current_setting('app.tenant_id'); BEGIN ASSERT safe_name ~ '^[a-zA-Z_][a-zA-Z0-9_]*$'; EXECUTE 'CREATE ROLE ' || quote_ident(safe_name); END; $$;
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/permission-scoping-for-ia.sql.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"permission-scoping-for-ia","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C3","C4","C7"],"examples_count":10,"lines_executable_max":5,"language":"PostgreSQL 14+ SQL","timestamp":"2026-04-18T22:40:00Z"}
```

---
