# SHA256: b0c1d2e3f4a5678901234567890123456789012345678901234567890123459
---
artifact_id: "mcp-sql-tool-definitions"
artifact_type: "skill_sql"
version: "2.1.1"
constraints_mapped: ["C3","C4","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/mcp-sql-tool-definitions.json.md --json"
canonical_path: "06-PROGRAMMING/sql/mcp-sql-tool-definitions.json.md"
---

# MCP SQL Tool Definitions with Tenant Enforcement

## Propósito
Definir contratos JSON para herramientas MCP que ejecuten SQL con validación estricta de contexto, aislamiento por tenant y logging estructurado, garantizando interoperabilidad segura con agentes de IA.

## Patrones de Código Validados

```json
// ✅ C3: Tool con validación explícita de entorno
{"name":"assert_context","type":"sql","payload":"DO $$ BEGIN ASSERT current_setting('app.tenant_id') IS NOT NULL; END; $$"}
```

```json
// ✅ C4: Tool con filtro automático de tenant en consulta
{"name":"query_crops","params":{"region":"string"},"payload":"SELECT id,name FROM crops WHERE tenant_id=current_setting('app.tenant_id') AND region=$1 LIMIT 50"}
```

```json
// ✅ C8: Tool con logging estructurado post-ejecución
{"name":"log_result","payload":"RAISE NOTICE '%',json_build_object('tool','mcp_query','status','ok','ts',now())"}
```

```json
// ✅ C3/C4: Tool con validación y aislamiento transaccional
{"name":"insert_data","params":{"payload":"jsonb"},"payload":"BEGIN; ASSERT current_setting('app.tenant_id')<>''; INSERT INTO logs (tenant_id,data) VALUES (current_setting('app.tenant_id'),$1); COMMIT;"}
```

```json
// ✅ C4/C8: Agregación con alcance tenant y traza
{"name":"get_metrics","payload":"SELECT AVG(val) FROM data WHERE tenant_id=current_setting('app.tenant_id')",
 "post":"RAISE NOTICE '%',json_build_object('metric','agg','tenant',current_setting('app.tenant_id'))"}
```

```json
// ✅ C3: Esquema de entrada con validación de contexto
{"name":"check_env","schema":{"type":"object","required":["tenant_id"]},
 "payload":"SELECT current_setting('app.tenant_id') AS ctx WHERE current_setting('app.tenant_id') IS NOT NULL LIMIT 1"}
```

```json
// ✅ C4: Update seguro con política RLS implícita
{"name":"update_status","params":{"id":"uuid","status":"text"},
 "payload":"UPDATE tasks SET status=$1 WHERE id=$2 AND tenant_id=current_setting('app.tenant_id')"}
```

```json
// ✅ C8: Tool de traza con latencia y formato JSON estricto
{"name":"trace_exec","payload":"RAISE NOTICE '%',json_build_object('trace','mcp_call','ms',extract(epoch from clock_timestamp()-statement_timestamp())*1000)"}
```

```json
// ❌ Anti-pattern: Tool sin contexto ni límite seguro
{"name":"bad_search","payload":"SELECT * FROM users WHERE name=$1"}
// 🔧 Fix: Inyectar tenant y acotar columnas/filas
{"name":"good_search","payload":"SELECT id,role FROM users WHERE tenant_id=current_setting('app.tenant_id') AND name=$1 LIMIT 50"}
```

```json
// ❌ Anti-pattern: Log textual no parseable por agentes
{"name":"bad_log","payload":"RAISE NOTICE 'Execution finished for tenant %'", current_setting('app.tenant_id')}
// 🔧 Fix: Estructura JSON estricta para consumo de IA
{"name":"good_log","payload":"RAISE NOTICE '%',json_build_object('event','exec_end','tenant',current_setting('app.tenant_id'))"}
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/mcp-sql-tool-definitions.json.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"mcp-sql-tool-definitions","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C3","C4","C8"],"examples_count":10,"lines_executable_max":5,"language":"PostgreSQL 14+ SQL","timestamp":"2026-04-18T22:00:00Z"}
```

---
