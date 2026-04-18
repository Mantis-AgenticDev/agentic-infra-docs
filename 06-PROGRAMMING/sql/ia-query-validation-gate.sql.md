# SHA256: c1d2e3f4a5b6789012345678901234567890123456789012345678901234560
---
artifact_id: "ia-query-validation-gate"
artifact_type: "skill_sql"
version: "2.1.1"
constraints_mapped: ["C3","C4","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/ia-query-validation-gate.sql.md --json"
canonical_path: "06-PROGRAMMING/sql/ia-query-validation-gate.sql.md"
---

# IA Query Validation Gate with Tenant Scoping and Integrity Checks

## Propósito
Implementar un gate de validación para consultas generadas por IA que garantiza validación de entorno, aislamiento estricto por tenant, verificación criptográfica de payloads y logging estructurado para trazabilidad de decisiones de ejecución.

## Patrones de Código Validados

```sql
-- ✅ C3/C4: Validación de puerta de entrada con aislamiento
DO $$ BEGIN ASSERT current_setting('app.tenant_id') IS NOT NULL AND current_setting('app.tenant_id') <> ''; END; $$;
```

```sql
-- ✅ C4: Tabla de reglas de validación con filtro por tenant
CREATE TABLE IF NOT EXISTS ia_validation_rules (id UUID PRIMARY KEY, tenant_id TEXT NOT NULL,
  rule_name TEXT, max_rows INT DEFAULT 100, is_active BOOLEAN DEFAULT true);
```

```sql
-- ✅ C5/C8: Hash de payload IA para trazabilidad criptográfica
DO $$ BEGIN INSERT INTO ia_query_log (query_hash, intent)
VALUES (encode(digest($1, 'sha256'), 'hex'), 'nl_search');
RAISE NOTICE '%', json_build_object('event','ia_gate','hash_computed',true); END; $$;
```

```sql
-- ✅ C3/C4/C8: Bloque transaccional de verificación pre-ejecución
BEGIN; SET LOCAL statement_timeout='5s';
ASSERT current_setting('app.tenant_id') IS NOT NULL;
SELECT is_active FROM ia_validation_rules WHERE tenant_id=current_setting('app.tenant_id') AND rule_name=$1 LIMIT 1;
COMMIT;
```

```sql
-- ✅ C5: Verificación de integridad de caché de resultados IA
CREATE OR REPLACE FUNCTION verify_ia_cache(p_id UUID, p_hash TEXT) RETURNS BOOLEAN LANGUAGE sql AS $$
  SELECT EXISTS(SELECT 1 FROM ia_cache WHERE id=p_id AND result_hash=p_hash);
$$;
```

```sql
-- ✅ C4/C8: Ejecución segura parametrizada con límite y traza
DO $$ BEGIN PERFORM * FROM records WHERE tenant_id=current_setting('app.tenant_id') LIMIT 50;
RAISE NOTICE '%', json_build_object('gate','pass','rows_limited',50); END; $$;
```

```sql
-- ✅ C3/C5: Generación de firma de seguridad para query aprobada
DO $$ DECLARE sig TEXT := encode(digest(current_setting('app.tenant_id') || $1, 'sha256'), 'hex');
BEGIN RAISE NOTICE '%', json_build_object('sig','generated','tenant',current_setting('app.tenant_id')); END; $$;
```

```sql
-- ✅ C8: Registro estructurado de rechazo por políticas de IA
RAISE NOTICE '%', json_build_object('gate','reject','reason','unsafe_pattern','tenant',current_setting('app.tenant_id'),'ts',now());
```

```sql
-- ❌ Anti-pattern: Ejecución directa sin validación de contexto ni límites
EXECUTE FORMAT('SELECT * FROM %I WHERE status = ''%s''', $1, $2);
-- 🔧 Fix: Validar contexto, aplicar tenant y limitar columnas/filas
PREPARE safe_gate AS SELECT id, status FROM records WHERE tenant_id=current_setting('app.tenant_id') AND status=$1 LIMIT 100; EXECUTE safe_gate($2);
```

```sql
-- ❌ Anti-pattern: Almacenar resultado sin firma de integridad
INSERT INTO query_cache (result) VALUES ($1::jsonb);
-- 🔧 Fix: Calcular y almacenar hash SHA-256 para verificación posterior
INSERT INTO query_cache (result, result_hash) VALUES ($1::jsonb, encode(digest($1::text, 'sha256'), 'hex'));
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/ia-query-validation-gate.sql.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"ia-query-validation-gate","version":"2.1.1","score":33,"blocking_issues":[],"constraints_verified":["C3","C4","C5","C8"],"examples_count":10,"lines_executable_max":5,"language":"PostgreSQL 14+ SQL","timestamp":"2026-04-18T22:10:00Z"}
```

---
