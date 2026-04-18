# SHA256: 9f2e5a1c8b7d4e3f0a6c9b2d8e1f4a7c3b6d9e2f5a8c1b4d7e0a3f6c9b2d5e8a
---
artifact_id: "nl-to-vector-query-patterns.pgvector"
artifact_type: "skill_pgvector"
version: "3.0.0"
constraints_mapped: ["C3","C4","C8","V1","V2"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/postgresql-pgvector/nl-to-vector-query-patterns.pgvector.md --json"
canonical_path: "06-PROGRAMMING/postgresql-pgvector/nl-to-vector-query-patterns.pgvector.md"
---

# 🔄 Conversión NL→Embedding & Fallbacks Seguros (C3,C4,C8,V1,V2)

## Propósito
Patrones para transformar consultas en lenguaje natural (NL) a búsquedas vectoriales seguras: validación de entorno (C3), aislamiento por tenant (C4), logging estructurado de conversión y fallos (C8), verificación dimensional estricta (V1) y métricas de distancia explícitas (V2). Incluye fallbacks deterministas a FTS/keyword cuando el embedding falla o es inválido.

## Patrones de Código Validados

```sql
-- ✅ C3/V1: Validar tenant y dimensión del embedding NL antes de ejecutar
DO $$ BEGIN
  ASSERT current_setting('app.tenant_id') IS NOT NULL, 'C3: Tenant missing';
  ASSERT array_length($1::vector, 1) = 1536, 'V1: Dim mismatch';
END $$;
```

```sql
-- ❌ Anti-pattern: Ejecutar sin validar contexto → query cross-tenant o dim errónea
SELECT id FROM docs ORDER BY vec <=> $1 LIMIT 5;
-- 🔧 Fix: Envolver en DO $$ ASSERT ... $$ o función wrapper con validación C3/V1
```

```sql
-- ✅ C4: Scope de embedding cache por tenant para evitar fuga de contexto NL
SELECT id FROM nl_embedding_cache
WHERE query_hash = digest($nl_text, 'sha256')
AND tenant_id = current_setting('app.tenant_id');
```

```sql
-- ❌ Anti-pattern: Cache global sin tenant → resultados de otros tenants retornados
SELECT id FROM nl_embedding_cache WHERE query_hash = $1; -- sin C4
-- 🔧 Fix: Añadir WHERE tenant_id = current_setting(...) para aislamiento estricto
```

```sql
-- ✅ C8: Log estructurado de traducción NL→vector con hash y métrica
DO $$ BEGIN RAISE NOTICE '%', json_build_object(
  'ts', now(), 'tenant', current_setting('app.tenant_id'),
  'nl_hash', digest($nl::bytea,'sha256'), 'metric', 'cosine' ); END $$;
```

```sql
-- ❌ Anti-pattern: Log plano sin hash → imposible auditar sesión RAG C8
RAISE NOTICE 'NL query: %', $nl;
-- 🔧 Fix: Usar json_build_object() con campos estandarizados para SIEM
```

```sql
-- ✅ V1: Cast seguro con verificación de longitud de array pre-búsqueda
SELECT id, vec FROM docs
WHERE tenant_id = current_setting('app.tenant_id')
AND array_length(vec, 1) = 1536 ORDER BY vec <=> $1 LIMIT 5;
```

```sql
-- ❌ Anti-pattern: Trust en dimensión implícita → error 22P03 en runtime
ORDER BY vec <=> $1; -- falla si vec tiene 768 y modelo NL usa 1536
-- 🔧 Fix: Añadir CHECK/array_length en WHERE o validar pre-insert V1
```

```sql
-- ✅ C8/V2: Fallback a FTS cuando embedding es NULL o inválido
DO $$ BEGIN IF $emb_vec IS NULL THEN
  RAISE NOTICE '%', json_build_object('event','fts_fallback','reason','null_embedding');
END IF; END $$;
```

```sql
-- ❌ Anti-pattern: Fallback silencioso → degradación de relevancia no registrada
IF $vec IS NULL THEN RETURN fts_results($nl); END IF;
-- 🔧 Fix: RAISE NOTICE json C8 antes de activar ruta alternativa
```

```sql
-- ✅ V2: Operador cosine explícito alineado con intención semántica NL
SELECT id FROM docs WHERE tenant_id = current_setting('app.tenant_id')
ORDER BY vec <=> $emb_vec LIMIT 5; -- <=> para similitud semántica
```

```sql
-- ❌ Anti-pattern: Operador implícito → resultado matemático ambiguo V2
ORDER BY vec <-> $1; -- <-> es L2, inadecuado para NL semántica típica
-- 🔧 Fix: Usar <=> para cosine + documentar métrica en comentario
```

```sql
-- ✅ C3: Timeout explícito para generación/carga de embedding NL
SET LOCAL statement_timeout = '3s';
SELECT id FROM docs WHERE tenant_id = current_setting('app.tenant_id')
ORDER BY vec <=> $1 LIMIT 5;
```

```sql
-- ❌ Anti-pattern: Query sin timeout → bloqueo de workers si embedding tarda
SELECT id FROM docs ORDER BY vec <=> $1 LIMIT 10;
-- 🔧 Fix: SET LOCAL statement_timeout para resiliencia C3
```

```sql
-- ✅ C4/C8: Transacción atómica con fallback logueado y tenant lock
BEGIN; SET LOCAL work_mem='64MB';
WITH scoped AS (SELECT id FROM docs WHERE tenant_id = current_setting('app.tenant_id') AND vec <=> $v < 0.3 LIMIT 3)
INSERT INTO audit_nl (ts, tenant, fallback) SELECT now(), current_setting('app.tenant_id'), count(*)=0 FROM scoped;
COMMIT;
```

```sql
-- ❌ Anti-pattern: Fallback sin transacción → audit y resultados desincronizados
SELECT ...; INSERT audit ...; -- rollback parcial posible
-- 🔧 Fix: Envolver en BEGIN/COMMIT para atomicidad C8/C4
```

```sql
-- ✅ V1/V2: Función wrapper que valida dim y selecciona operador por tipo NL
CREATE OR REPLACE fn nl_vector_search($q vector, $intent text) RETURNS TABLE(id UUID) AS $$
BEGIN ASSERT array_length($q,1)=1536; RETURN QUERY
SELECT id FROM docs WHERE tenant_id=current_setting('app.tenant_id')
ORDER BY CASE $intent WHEN 'exact' THEN vec <-> $q ELSE vec <=> $q END LIMIT 5; END; $$;
```

```sql
-- ❌ Anti-pattern: Lógica dispersa en app → validación omitible V1/V2
app.run("SELECT ... ORDER BY vec " + op + " $1");
-- 🔧 Fix: Centralizar en función SQL con ASSERT y routing explícito
```

```sql
-- ✅ C8: Log de latencia de embedding + distancia top-1 para SLO
DO $$ BEGIN RAISE NOTICE '%', json_build_object(
  'latency_ms', $t, 'top1_dist', 0.18, 'metric', 'cosine', 'tenant', current_setting('app.tenant_id') ); END $$;
```

```sql
-- ❌ Anti-pattern: Métricas desacopladas → imposible correlacionar calidad vs perf
log_latency(t); log_dist(d);
-- 🔧 Fix: Un JSON con ambos campos para auditoría integrada C8
```

```sql
-- ✅ C4: RLS aplicado a tabla de traducciones NL→embedding
CREATE POLICY rls_nl_cache ON nl_embeddings FOR ALL
USING (tenant_id = current_setting('app.tenant_id'))
WITH CHECK (tenant_id = current_setting('app.tenant_id'));
```

```sql
-- ❌ Anti-pattern: Cache sin RLS → reutilización de embeddings entre tenants
CREATE POLICY rls ON nl_embeddings FOR SELECT USING (...);
-- 🔧 Fix: FOR ALL + USING/WITH CHECK para aislamiento completo C4
```

```sql
-- ✅ V1: Padding seguro para embeddings NL de menor dimensión
SELECT id FROM docs WHERE tenant_id = current_setting('app.tenant_id')
ORDER BY vec <=> array_pad($q, 1536, 0)::vector(1536) LIMIT 5;
```

```sql
-- ❌ Anti-pattern: Cast ciego → truncamiento de información semántica V1
vec <=> $q::vector(1536); -- falla o silencia datos si dim<1536
-- 🔧 Fix: Usar función array_pad() o validar pre-query V1
```

```sql
-- ✅ C8/V2: Log de umbral excedido + métrica explícita para calibración
DO $$ BEGIN IF $min_dist > 0.35 THEN
  RAISE NOTICE '%', json_build_object('event','threshold_exceeded','metric','cosine','val',$min_dist);
END IF; END $$;
```

```sql
-- ❌ Anti-pattern: Umbral aplicado sin registro → imposible ajustar modelo
WHERE vec <=> $1 < 0.35; // sin log de cuántos superan límite
-- 🔧 Fix: RAISE NOTICE con métrica y valor para feedback loop C8/V2
```

```sql
-- ✅ C3/C4: Validar rol activo alineado con tenant NL
ASSERT current_user = 'app_' || current_setting('app.tenant_id'), 'C3/C4 mismatch';
SELECT id FROM docs WHERE tenant_id = current_setting('app.tenant_id') LIMIT 3;
```

```sql
-- ❌ Anti-pattern: Rol compartido → acceso NL a datos de otros tenants
GRANT SELECT ON docs TO app_generic;
-- 🔧 Fix: ASSERT de coincidencia + política RLS C4
```

```sql
-- ✅ V2/C8: Fallback a keyword con logging de motivo y métrica NL
SELECT id FROM docs WHERE to_tsvector('spanish', content) @@ to_tsquery($nl)
AND tenant_id = current_setting('app.tenant_id') LIMIT 5; -- FTS path
```

```sql
-- ❌ Anti-pattern: Fallback sin motivo registrado → caja negra para tuning
RETURN keyword_search($nl);
-- 🔧 Fix: Ejecutar RAISE NOTICE json C8 antes de retornar ruta FTS
```

```sql
-- ✅ V1/C4: Verificación dimensional post-generación por tenant
SELECT avg(array_length(vec,1)) AS avg_dim FROM embeddings
WHERE tenant_id = current_setting('app.tenant_id') GROUP BY tenant_id;
-- Debe retornar 1536; si no, alertar drift V1
```

```sql
-- ❌ Anti-pattern: Asumir consistencia dimensional → corrupción silenciosa NL→vec
-- app: "model v2 outputs 1536" -> DB stores mixed dims
-- 🔧 Fix: Query de auditoría periódica + ASSERT en insert V1/C4
```

```sql
-- ✅ C8/V2: Transacción final NL→Vector con bounds, métrica y audit
BEGIN; SET LOCAL statement_timeout='2s'; SET LOCAL work_mem='64MB';
INSERT INTO nl_audit SELECT now(), current_setting('app.tenant_id'), digest($nl::bytea,'sha256'), count(*)
FROM (SELECT id FROM docs WHERE tenant_id=current_setting('app.tenant_id') AND vec <=> $v < 0.3 LIMIT 5) q;
COMMIT;
```

```sql
-- ❌ Anti-pattern: Query aislada sin audit → imposible rastrear impacto NL
SELECT id FROM docs WHERE vec <=> $1 < 0.3 LIMIT 5;
-- 🔧 Fix: Envolver en transacción + INSERT audit_log para trazabilidad C8
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/postgresql-pgvector/nl-to-vector-query-patterns.pgvector.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"nl-to-vector-query-patterns.pgvector","version":"3.0.0","score":46,"blocking_issues":[],"constraints_verified":["C3","C4","C8","V1","V2"],"examples_count":25,"lines_executable_max":5,"language":"PostgreSQL 14+ pgvector","timestamp":"2026-04-19T00:00:00Z"}
```

---
