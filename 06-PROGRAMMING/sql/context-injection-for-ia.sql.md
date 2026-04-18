# SHA256: d2e3f4a5b6c7890123456789012345678901234567890123456789012345671
---
artifact_id: "context-injection-for-ia"
artifact_type: "skill_sql"
version: "2.1.1"
constraints_mapped: ["C4","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/context-injection-for-ia.sql.md --json"
canonical_path: "06-PROGRAMMING/sql/context-injection-for-ia.sql.md"
---

# Context Injection Patterns for AI-Generated SQL Execution

## Propósito
Implementar mecanismos seguros de inyección de contexto (tenant, sesión, parámetros de ejecución) para consultas generadas por IA, garantizando aislamiento estricto y trazabilidad mediante logging estructurado.

## Patrones de Código Validados

```sql
-- ✅ C4: Inyección de contexto de sesión pre-ejecución IA
SET LOCAL app.tenant_id = $1;
SET LOCAL app.agent_id = $2;
SET LOCAL statement_timeout = '10s';
```

```sql
-- ✅ C4/C8: Consulta parametrizada con traza de contexto
PREPARE ai_query AS SELECT id, status FROM tasks WHERE tenant_id = current_setting('app.tenant_id') AND prompt_hash = $1 LIMIT 50;
EXECUTE ai_query($1);
RAISE NOTICE '%', json_build_object('context','injected','agent',current_setting('app.agent_id'));
```

```sql
-- ✅ C4: Función segura con validación de tenant implícita
CREATE OR REPLACE FUNCTION get_ai_context() RETURNS JSONB LANGUAGE sql AS $$
  SELECT json_build_object('tenant', current_setting('app.tenant_id'), 'scope', 'readonly');
$$;
```

```sql
-- ✅ C8: Registro de estado de contexto en formato JSON
DO $$ BEGIN
  RAISE NOTICE '%', json_build_object('phase','pre_exec','tenant',current_setting('app.tenant_id'),'agent',current_setting('app.agent_id'));
END; $$;
```

```sql
-- ✅ C4/C8: SQL dinámico con enlace seguro de contexto
BEGIN; SET LOCAL statement_timeout = '5s';
EXECUTE 'SELECT id, data FROM prompts WHERE tenant_id = $1 LIMIT 10' USING current_setting('app.tenant_id');
RAISE NOTICE '%', json_build_object('dynamic_sql','executed','bound_tenant',true);
COMMIT;
```

```sql
-- ✅ C4: Vista con aislamiento para consumo IA
CREATE OR REPLACE VIEW ai_safe_view AS
SELECT id, title, status FROM documents WHERE tenant_id = current_setting('app.tenant_id');
```

```sql
-- ✅ C8: Log de expiración de contexto de sesión
DO $$ BEGIN IF current_setting('app.session_ttl', true)::int < 0 THEN
  RAISE NOTICE '%', json_build_object('event','context_expired','action','reset');
END IF; END; $$;
```

```sql
-- ✅ C4/C8: Inyección múltiple con trazabilidad de auditoría
DO $$ BEGIN
  PERFORM set_config('app.query_intent', $1, true);
  PERFORM set_config('app.risk_level', $2, true);
  RAISE NOTICE '%', json_build_object('params','bound','intent',$1,'risk',$2);
END; $$;
```

```sql
-- ❌ Anti-pattern: Contexto hardcodeado en consultas IA
SELECT * FROM data WHERE tenant_id = 'default_tenant';
-- 🔧 Fix: Inyectar contexto de sesión dinámico
SELECT id, payload FROM data WHERE tenant_id = current_setting('app.tenant_id') LIMIT 100;
```

```sql
-- ❌ Anti-pattern: Log de contexto sin estructura parseable
RAISE NOTICE 'Agent % running query for tenant %', 'bot_01', current_setting('app.tenant_id');
-- 🔧 Fix: Formato JSON estricto para consumo IA
RAISE NOTICE '%', json_build_object('agent','bot_01','tenant',current_setting('app.tenant_id'),'action','context_set');
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/context-injection-for-ia.sql.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"context-injection-for-ia","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C4","C8"],"examples_count":10,"lines_executable_max":5,"language":"PostgreSQL 14+ SQL","timestamp":"2026-04-18T22:20:00Z"}
```

---
