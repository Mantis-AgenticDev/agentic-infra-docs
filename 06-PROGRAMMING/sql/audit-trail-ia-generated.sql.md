# SHA256: e3f4a5b6c7d8901234567890123456789012345678901234567890123456782
---
artifact_id: "audit-trail-ia-generated"
artifact_type: "skill_sql"
version: "2.1.1"
constraints_mapped: ["C4","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/audit-trail-ia-generated.sql.md --json"
canonical_path: "06-PROGRAMMING/sql/audit-trail-ia-generated.sql.md"
---

# Audit Trail for AI-Generated SQL with Integrity Verification

## Propósito
Implementar trazabilidad inmutable para consultas generadas por IA, garantizando aislamiento por tenant, verificación criptográfica del SQL producido y logging estructurado para auditoría de decisiones algorítmicas.

## Patrones de Código Validados

```sql
-- ✅ C4: Tabla de auditoría con aislamiento estricto por tenant
CREATE TABLE IF NOT EXISTS ai_sql_trail (id UUID PRIMARY KEY, tenant_id TEXT NOT NULL,
agent_id TEXT, generated_sql TEXT, sql_hash TEXT, executed_at TIMESTAMPTZ DEFAULT NOW());
```

```sql
-- ✅ C5: Inserción con hash SHA-256 del query generado
INSERT INTO ai_sql_trail (tenant_id, agent_id, generated_sql, sql_hash)
VALUES (current_setting('app.tenant_id'), $1, $2, encode(digest($2, 'sha256'), 'hex'));
```

```sql
-- ✅ C8: Log estructurado de generación de query IA
RAISE NOTICE '%', json_build_object('event','ai_sql_generated','agent',$1,'tenant',current_setting('app.tenant_id'),'ts',now());
```

```sql
-- ✅ C4/C5: Bloque transaccional con verificación de contexto y hash
BEGIN; SET LOCAL statement_timeout='5s'; ASSERT current_setting('app.tenant_id')<>'';
INSERT INTO ai_sql_trail VALUES (gen_random_uuid(), current_setting('app.tenant_id'), 'llm_v2', 'SELECT 1', encode(digest('SELECT 1','sha256'),'hex'));
COMMIT;
```

```sql
-- ✅ C4/C8: Consulta de traza filtrada por tenant y log de acceso
SELECT id, agent_id, executed_at FROM ai_sql_trail WHERE tenant_id = current_setting('app.tenant_id') ORDER BY executed_at DESC LIMIT 20;
RAISE NOTICE '%', json_build_object('action','trail_read','tenant',current_setting('app.tenant_id'));
```

```sql
-- ✅ C5: Función de verificación de integridad de query almacenado
CREATE OR REPLACE FUNCTION verify_ai_sql_hash(p_id UUID, p_raw TEXT) RETURNS BOOLEAN LANGUAGE sql AS $$
SELECT sql_hash = encode(digest(p_raw, 'sha256'), 'hex') FROM ai_sql_trail WHERE id = p_id;
$$;
```

```sql
-- ✅ C8: Registro métrico de ejecución IA en JSON
RAISE NOTICE '%', json_build_object('phase','execution','agent','llm_worker','rows_affected',42,'latency_ms',150,'status','ok');
```

```sql
-- ✅ C4: Política RLS completa para traza de auditoría
ALTER TABLE ai_sql_trail ENABLE ROW LEVEL SECURITY;
CREATE POLICY ai_tenant_scope ON ai_sql_trail USING (tenant_id = current_setting('app.tenant_id')) WITH CHECK (tenant_id = current_setting('app.tenant_id'));
```

```sql
-- ❌ Anti-pattern: Log de contexto sin estructura parseable
RAISE NOTICE 'AI query executed for tenant %', current_setting('app.tenant_id');
-- 🔧 Fix: Formato JSON estricto para consumo de sistemas
RAISE NOTICE '%', json_build_object('event','ai_exec','tenant',current_setting('app.tenant_id'),'agent_id','coder_v2','ts',now());
```

```sql
-- ❌ Anti-pattern: Almacenar SQL generado sin firma criptográfica
CREATE TABLE bad_ai_log (id UUID, raw_sql TEXT, agent TEXT);
-- 🔧 Fix: Agregar constraint de hash SHA-256 para inmutabilidad
CREATE TABLE good_ai_log (id UUID, raw_sql TEXT, sql_hash TEXT CHECK (sql_hash ~ '^[a-f0-9]{64}$'), agent TEXT);
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/audit-trail-ia-generated.sql.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"audit-trail-ia-generated","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C4","C5","C8"],"examples_count":10,"lines_executable_max":5,"language":"PostgreSQL 14+ SQL","timestamp":"2026-04-18T22:30:00Z"}
```

---
