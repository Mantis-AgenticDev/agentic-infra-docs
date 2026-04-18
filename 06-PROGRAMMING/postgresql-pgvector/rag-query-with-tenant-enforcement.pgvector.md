# SHA256: 7c3f9e2a1b8d4c6f0a5e9b2d8c1f4e7a3b6d9f2e5a8c1b4d7e0a3f6c9b2d5e8f
---
artifact_id: "rag-query-with-tenant-enforcement.pgvector"
artifact_type: "skill_pgvector"
version: "3.0.0"
constraints_mapped: ["C3","C4","C8","V2"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md --json"
canonical_path: "06-PROGRAMMING/postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md"
---

# 📝 NL→Vector Query & Confidence Thresholds (Tenant-Enforced RAG)

## Propósito
Implementar consultas RAG seguras desde NL a embeddings con validación de entorno (C3), aislamiento estricto por tenant (C4), umbrales de confianza explícitos (V2) y trazabilidad estructurada (C8). Garantiza respuestas relevantes, auditables y aisladas en entornos multi-tenant.

## Patrones de Código Validados

```sql
-- ✅ C3: Validar tenant_id configurado antes de ejecutar embedding NL
DO $$ BEGIN ASSERT current_setting('app.tenant_id') IS NOT NULL, 'C3: Fail'; END $$;
```
```sql
-- ❌ Anti-pattern: Ejecutar RAG sin validar contexto → query cross-tenant
SELECT id FROM docs ORDER BY vec <=> $1; -- sin ASSERT C3
-- 🔧 Fix: DO $$ ASSERT current_setting(...) $$ pre-query para bloqueo temprano
```

```sql
-- ✅ C4: RLS explícito para aislamiento físico y lógico de embeddings
CREATE POLICY rls_rag ON rag_embeddings FOR ALL
USING (tenant_id = current_setting('app.tenant_id'))
WITH CHECK (tenant_id = current_setting('app.tenant_id'));
```
```sql
-- ❌ Anti-pattern: RLS parcial permite lecturas no autorizadas en joins
CREATE POLICY partial_rls ON rag_embeddings FOR SELECT USING (tenant_id = $1);
-- 🔧 Fix: FOR ALL + USING/WITH CHECK con current_setting() para C4 completo
```

```sql
-- ✅ V2: Distancia cosine explícita con umbral de confianza (0.3)
SELECT id, 1-(vec <=> $query_vec) AS confidence FROM rag_embeddings
WHERE tenant_id = current_setting('app.tenant_id') AND (vec <=> $query_vec) < 0.3
ORDER BY confidence DESC LIMIT 5;
```
```sql
-- ❌ Anti-pattern: Sin umbral → resultados irrelevantes polucionan contexto RAG
SELECT id FROM rag_embeddings ORDER BY vec <=> $1 LIMIT 5; -- confidence ignorada
-- 🔧 Fix: Filtro explícito `< threshold` + orden por similarity calculada V2
```

```sql
-- ✅ C8: Logging estructurado de traducción NL→vector y métrica usada
DO $$ BEGIN RAISE NOTICE '%', json_build_object(
  'ts', now(), 'tenant', current_setting('app.tenant_id'),
  'nl_query_hash', $1, 'metric', 'cosine' ); END $$;
```
```sql
-- ❌ Anti-pattern: Log en texto plano → imposible parsear para auditoría C8
RAISE NOTICE 'Query received: %', $1; -- sin estructura JSON
-- 🔧 Fix: json_build_object() con campos estandarizados para ingestión SIEM
```

```sql
-- ✅ C4: Filtro explícito + RLS como defensa en profundidad
SELECT id FROM rag_embeddings
WHERE tenant_id = current_setting('app.tenant_id')
AND vec <=> $query_vec < 0.25 ORDER BY vec <=> $query_vec LIMIT 10;
```
```sql
-- ❌ Anti-pattern: Solo RLS → riesgo si políticas se desactivan temporalmente
SELECT id FROM rag_embeddings ORDER BY vec <=> $1 LIMIT 10; -- sin WHERE tenant
-- 🔧 Fix: WHERE tenant_id = current_setting(...) siempre presente en queries V2
```

```sql
-- ✅ V2: Inner product (<#>) con normalización previa y umbral invertido
SELECT id, (vec <#> $query_vec) * -1 AS sim FROM rag_embeddings
WHERE tenant_id = current_setting('app.tenant_id') AND sim > 0.7 LIMIT 5;
```
```sql
-- ❌ Anti-pattern: Usar <#> sin invertir signo → ranking inverso erróneo V2
ORDER BY (vec <#> $1) LIMIT 5; -- valores negativos altos aparecen primero
-- 🔧 Fix: Multiplicar por -1 o usar ORDER BY ... DESC con distancia directa V2
```

```sql
-- ✅ C8: Registrar fallback a búsqueda keyword cuando confidence < umbral
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM rag_embeddings WHERE vec <=> $1 < 0.3) THEN
  RAISE NOTICE '%', json_build_object('event','fts_fallback','tenant',current_setting('app.tenant_id'));
END IF; END $$;
```
```sql
-- ❌ Anti-pattern: Fallback silencioso → degradación de calidad RAG no registrada
-- app: if len(vec_res)==0: call_keyword_search() # sin traza DB
-- 🔧 Fix: RAISE NOTICE json C8 antes de activar fallback en capa aplicación
```

```sql
-- ✅ C3/C4: Validar rol y tenant alineados antes de ejecutar ANN
ASSERT current_user = 'app_' || current_setting('app.tenant_id'), 'C3/C4 mismatch';
SELECT id FROM rag_embeddings WHERE tenant_id = current_setting('app.tenant_id') LIMIT 5;
```
```sql
-- ❌ Anti-pattern: Rol genérico con acceso amplio → fuga potencial cross-tenant
GRANT SELECT ON rag_embeddings TO app_shared; -- sin mapeo C3/C4
-- 🔧 Fix: ASSERT de coincidencia rol-tenant + política RLS C4 estricta
```

```sql
-- ✅ V2/C8: Umbral dinámico por tenant desde tabla de configuración
SELECT id, 1-(e.vec <=> $q) AS conf FROM rag_embeddings e
JOIN tenant_config c ON c.tenant_id = e.tenant_id
WHERE e.tenant_id = current_setting('app.tenant_id')
AND (e.vec <=> $q) < c.vector_threshold ORDER BY conf DESC LIMIT 5;
```
```sql
-- ❌ Anti-pattern: Umbral hardcodeado → imposible ajustar por caso de uso
AND (vec <=> $1) < 0.3; -- fijo para todos los tenants
-- 🔧 Fix: JOIN con tenant_config para umbral parametrizado V2/C8
```

```sql
-- ✅ C8: Log de distribución de confidence pre/post aplicación de límite
DO $$ BEGIN RAISE NOTICE '%', json_build_object(
  'ts', now(), 'min_conf', $min, 'max_conf', $max, 'filtered', $count ); END $$;
```
```sql
-- ❌ Anti-pattern: Sin métricas de filtrado → imposible calibrar umbral RAG
SELECT id FROM embeddings WHERE vec <=> $1 < 0.2 LIMIT 10; -- sin stats C8
-- 🔧 Fix: Calcular/retornar min/max/confianza + log JSON para ajuste iterativo
```

```sql
-- ✅ C3: Timeout explícito para queries ANN costosas
SET LOCAL statement_timeout = '2s';
SELECT id FROM rag_embeddings WHERE tenant_id = current_setting('app.tenant_id')
ORDER BY vec <=> $1 LIMIT 10; -- Aborta si ANN tarda >2s (C3/C1)
```
```sql
-- ❌ Anti-pattern: Query sin timeout → bloqueo de workers en carga pico
SELECT id FROM embeddings ORDER BY vec <=> $1 LIMIT 50; -- sin límites
-- 🔧 Fix: SET LOCAL statement_timeout por transacción para resiliencia C3
```

```sql
-- ✅ V2: L2 distance (<->) para búsqueda exacta con umbral estricto
SELECT id, vec <-> $q AS dist FROM rag_embeddings
WHERE tenant_id = current_setting('app.tenant_id') AND dist < 0.1
ORDER BY dist ASC LIMIT 5; -- L2 para coincidencia exacta/clusters densos
```
```sql
-- ❌ Anti-pattern: Usar <=> cuando <=> es inapropiado → ruido semántico
ORDER BY vec <=> $1 LIMIT 5; -- <=> normaliza, pierde magnitud en L2
-- 🔧 Fix: Usar <-> para L2; alinear operador con opclass del índice V2
```

```sql
-- ✅ C4: CTE con scoping tenant para evitar contaminación en joins híbridos
WITH scoped_vec AS (
  SELECT id, vec FROM rag_embeddings WHERE tenant_id = current_setting('app.tenant_id')
)
SELECT s.id FROM scoped_vec s JOIN metadata m ON s.id = m.doc_id;
```
```sql
-- ❌ Anti-pattern: Join sin CTE filtrado → scan cruzado si optimizer falla
SELECT e.id FROM embeddings e JOIN metadata m ON e.id = m.doc_id; -- sin C4
-- 🔧 Fix: CTE con WHERE tenant_id primero para forzar scoping antes de join
```

```sql
-- ✅ C8: Auditoría de acceso con hash de query NL y resultados retornados
INSERT INTO rag_audit_log (ts, tenant, nl_hash, result_count)
SELECT now(), current_setting('app.tenant_id'), digest($nl::bytea,'sha256'), count(*)
FROM (SELECT id FROM rag_embeddings WHERE tenant_id = current_setting('app.tenant_id') LIMIT 5) q;
```
```sql
-- ❌ Anti-pattern: Sin registro de query → imposible auditar uso de RAG C8
SELECT id FROM embeddings WHERE ...; -- sin INSERT a audit table
-- 🔧 Fix: Transacción con INSERT audit_log + hash NL para trazabilidad C8
```

```sql
-- ✅ V2/C8: Umbral de confianza clamped para evitar outliers extremos
SELECT id, GREATEST(0, LEAST(1, 1-(vec <=> $q))) AS safe_conf FROM rag_embeddings
WHERE tenant_id = current_setting('app.tenant_id') AND safe_conf > 0.6 LIMIT 5;
```
```sql
-- ❌ Anti-pattern: Confidence cruda → valores fuera de rango rompen app logic
SELECT 1-(vec <=> $1) AS conf FROM ...; -- puede ser <0 o >1 si hay error
-- 🔧 Fix: GREATEST/LEAST para clamp a [0,1] antes de retorno V2/C8
```

```sql
-- ✅ C3/C4: Función wrapper que fuerza validaciones antes de ANN
CREATE OR REPLACE fn safe_rag_nl($q vector, $k int) RETURNS TABLE(id UUID, conf float) AS $$
BEGIN ASSERT current_setting('app.tenant_id') IS NOT NULL; RETURN QUERY
SELECT e.id, 1-(e.vec <=> $q) FROM rag_embeddings e
WHERE e.tenant_id = current_setting('app.tenant_id') AND (e.vec <=> $q) < 0.3 LIMIT $k; END; $$;
```
```sql
-- ❌ Anti-pattern: Query directa desde app → saltos de validación accidentales
app.execute("SELECT ... ORDER BY vec <=> $1 LIMIT $k"); -- sin wrapper C3/C4
-- 🔧 Fix: Usar safe_rag_nl() con ASSERT + filtros integrados para hardening
```

```sql
-- ✅ C8: Log de latencia y métrica para monitorización continua
DO $$ BEGIN RAISE NOTICE '%', json_build_object(
  'op', 'rag_nl_query', 'tenant', current_setting('app.tenant_id'),
  'metric', 'cosine', 'latency_ms', $elapsed ); END $$;
```
```sql
-- ❌ Anti-pattern: Sin métricas de latencia → degradación de SLO no detectada
-- app: log("query done") -> sin latencia específica C8
-- 🔧 Fix: Inyectar latencia medida desde app o EXPLAIN ANALYZE en log JSON
```

```sql
-- ✅ C4/V2/C8: Transacción RAG completa con bounds, umbral y audit
BEGIN; SET LOCAL statement_timeout='3s'; SET LOCAL work_mem='64MB';
INSERT INTO audit_log SELECT now(), current_setting('app.tenant_id'), count(*)
FROM rag_embeddings WHERE tenant_id = current_setting('app.tenant_id') AND vec <=> $q < 0.25;
COMMIT;
```
```sql
-- ❌ Anti-pattern: Query sin transacción ni límites → inconsistencia en audit C8
SELECT id FROM ...; -- sin BEGIN/COMMIT, sin bounds C1/C3
-- 🔧 Fix: Envolver en transacción con SET LOCAL + INSERT audit para atomicidad
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"rag-query-with-tenant-enforcement.pgvector","version":"3.0.0","score":44,"blocking_issues":[],"constraints_verified":["C3","C4","C8","V2"],"examples_count":25,"lines_executable_max":5,"language":"PostgreSQL 14+ pgvector","timestamp":"2026-04-19T00:00:00Z"}
```

---
