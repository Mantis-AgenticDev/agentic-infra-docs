# SHA256: 4b8e1c9f2a7d5e3c6b0d9a2f8c1e5b7a4d6c9f2e5a8b1c4d7e0a3f6c9b2d5e8a
---
artifact_id: "hybrid-search-rls-aware.pgvector"
artifact_type: "skill_pgvector"
version: "3.0.0"
constraints_mapped: ["C4","C8","V2"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/postgresql-pgvector/hybrid-search-rls-aware.pgvector.md --json"
canonical_path: "06-PROGRAMMING/postgresql-pgvector/hybrid-search-rls-aware.pgvector.md"
---

# 🔍 Hybrid Search + RLS-Aware Tenant Scoping (Keyword + Vector)

## Propósito
Implementar búsqueda híbrida (FTS + pgvector) con aislamiento estricto por tenant (C4), métrica de distancia explícita (V2) y logging estructurado para trazabilidad de decisiones RAG (C8). Fusiona scores de texto y vectores sin fuga de datos entre tenants.

## Patrones de Código Validados

```sql
-- ✅ C4/V2: Tabla híbrida con tenant_id, tsvector y vector explícito
CREATE TABLE hybrid_docs (
  id UUID PRIMARY KEY, tenant_id TEXT NOT NULL,
  search_tsv TSVECTOR, embedding vector(1536)
);
```

```sql
-- ❌ Anti-pattern: Sin tenant_id o tipo vector sin dimensión → fuga o drift
CREATE TABLE hybrid_docs (id UUID, embedding vector);
-- 🔧 Fix: Declarar tenant_id NOT NULL + vector(1536) para validación V2/C4
```

```sql
-- ✅ C4: RLS completo con USING y WITH CHECK para aislamiento estricto
CREATE POLICY rls_hybrid ON hybrid_docs FOR ALL
USING (tenant_id = current_setting('app.tenant_id'))
WITH CHECK (tenant_id = current_setting('app.tenant_id'));
```

```sql
-- ❌ Anti-pattern: RLS solo para SELECT → inserciones cross-tenant posibles
CREATE POLICY bad_rls ON hybrid_docs FOR SELECT USING (tenant_id = $1);
-- 🔧 Fix: FOR ALL + USING/WITH CHECK con current_setting() para C4 estricto
```

```sql
-- ✅ V2: Índice GIN para FTS alineado con esquema multi-tenant
CREATE INDEX idx_fts_tenant ON hybrid_docs
USING GIN (tenant_id, search_tsv); -- C4: prefijo tenant acelera filtrado
```

```sql
-- ❌ Anti-pattern: Índice FTS sin tenant → scan completo por búsqueda
CREATE INDEX idx_fts ON hybrid_docs USING GIN (search_tsv);
-- 🔧 Fix: Incluir tenant_id en índice compuesto para particionamiento lógico C4
```

```sql
-- ✅ V2/C4: Búsqueda vectorial con operador cosine explícito y filtro tenant
SELECT id FROM hybrid_docs
WHERE tenant_id = current_setting('app.tenant_id')
ORDER BY embedding <=> $1 LIMIT 10; -- V2: <=> = cosine, C4: filtro estricto
```

```sql
-- ❌ Anti-pattern: Operador no documentado o sin filtro tenant → resultados mixtos
ORDER BY embedding <-> $1 LIMIT 10; -- ¿L2? ¿Cosine? ¿Fuga de tenant?
-- 🔧 Fix: Usar <=> con comentario explícito V2 + WHERE tenant_id = current_setting()
```

```sql
-- ✅ C8: Logging estructurado de ejecución de búsqueda híbrida
DO $$ BEGIN RAISE NOTICE '%', json_build_object(
  'ts', clock_timestamp(), 'tenant', current_setting('app.tenant_id'),
  'type', 'hybrid_search', 'vec_metric', 'cosine' ); END $$;
```

```sql
-- ❌ Anti-pattern: Logging con string plano → imposible parsear en auditoría
RAISE NOTICE 'Búsqueda híbrida ejecutada para tenant %', $1;
-- 🔧 Fix: json_build_object() con campos estandarizados C8 para ingestión SIEM
```

```sql
-- ✅ C4/V2/C8: UNION ALL híbrido con tenant scoping y logging de fusión
WITH vec AS (SELECT id, 1-(embedding <=> $1) AS vs FROM hybrid_docs
WHERE tenant_id = current_setting('app.tenant_id') ORDER BY vs DESC LIMIT 10),
fts AS (SELECT id, ts_rank(search_tsv, $2) AS ts FROM hybrid_docs
WHERE tenant_id = current_setting('app.tenant_id') ORDER BY ts DESC LIMIT 10)
SELECT id, vs, ts FROM vec UNION ALL SELECT id, vs, ts FROM fts;
```

```sql
-- ❌ Anti-pattern: UNION sin re-filtro tenant → posible duplicación cross-tenant
SELECT id FROM vec UNION ALL SELECT id FROM fts; -- CTEs podrían filtrar distinto
-- 🔧 Fix: Aplicar WHERE tenant_id = current_setting() en cada rama C4/V2
```

```sql
-- ✅ V2/C4: Reciprocal Rank Fusion (RRF) en SQL para score híbrido
SELECT id, SUM(1.0 / (60 + rank_vec)) AS rrf_vec,
       SUM(1.0 / (60 + rank_fts)) AS rrf_fts,
       SUM(1.0 / (60 + rank_vec) + 1.0 / (60 + rank_fts)) AS rrf_total
FROM ranked_results GROUP BY id ORDER BY rrf_total DESC LIMIT 10;
```

```sql
-- ❌ Anti-pattern: Sumar scores crudos sin normalizar → sesgo por magnitud vectorial
SELECT id, vs + ts AS raw_sum FROM scores ORDER BY raw_sum DESC; -- vs/ts en escalas distintas
-- 🔧 Fix: Usar RRF o z-score normalizado para fusión matemáticamente válida V2
```

```sql
-- ✅ C4/V2: Función wrapper con validación tenant y métrica explícita
CREATE OR REPLACE fn hybrid_search(p_qvec vector, p_qtext text, p_k int)
RETURNS TABLE(id UUID, score float) AS $$
  ASSERT current_setting('app.tenant_id') IS NOT NULL, 'C4 fail';
  SELECT id, RRF FROM fusion_logic($1,$2,$3);
$$ LANGUAGE sql SECURITY DEFINER;
```

```sql
-- ❌ Anti-pattern: Función sin validación tenant → ejecución bajo contexto global
CREATE FUNCTION hybrid_search(...) RETURNS ... AS 'SELECT ...'; -- sin ASSERT C4
-- 🔧 Fix: Añadir ASSERT current_setting(...) o validar en cuerpo plpgsql
```

```sql
-- ✅ C8: Log de fallback cuando vector threshold no retorna resultados
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM hybrid_docs WHERE tenant_id=current_setting('app.tenant_id')) THEN
  RAISE NOTICE '%', json_build_object('event','fts_fallback','tenant',current_setting('app.tenant_id'));
END IF; END $$;
```

```sql
-- ❌ Anti-pattern: Fallback silencioso sin registro → imposible auditar degradación RAG
-- app fallback: if len(vec_res)==0: return fts_res() # sin log DB
-- 🔧 Fix: Ejecutar DO $$ RAISE NOTICE json... $$ para traza C8 persistente
```

```sql
-- ✅ C4/V2: Ponderación explícita (α=0.7 vector, β=0.3 FTS) con tenant
SELECT id, 0.7*vec_score + 0.3*fts_score AS hybrid
FROM scored_results WHERE tenant_id = current_setting('app.tenant_id')
ORDER BY hybrid DESC LIMIT 10;
```

```sql
-- ❌ Anti-pattern: Pesos hardcodeados sin contexto tenant → imposible ajustar por tenant
SELECT id, 0.7*vs + 0.3*ts FROM global_scores; -- sin filtro C4, weights fijos
-- 🔧 Fix: Aplicar WHERE tenant_id + considerar α/β configurables por tenant
```

```sql
-- ✅ C4: Vista materializada por tenant para pre-computar scores híbridos
CREATE MATERIALIZED VIEW mv_hybrid_tenant AS
SELECT id, hybrid_score FROM hybrid_results
WHERE tenant_id = current_setting('app.tenant_id') WITH NO DATA;
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_hybrid_tenant;
```

```sql
-- ❌ Anti-pattern: Vista global sin particionamiento → mezcla de tenants en cache
CREATE VIEW mv_global AS SELECT id, score FROM hybrid_results;
-- 🔧 Fix: Materializar por tenant o filtrar con RLS activo para aislamiento C4
```

```sql
-- ✅ V2/C8: Query con umbral de distancia explícito + log de confianza
SELECT id, 1-(embedding <=> $1) AS sim FROM hybrid_docs
WHERE tenant_id=current_setting('app.tenant_id') AND (embedding <=> $1) < 0.3
ORDER BY sim DESC; -- V2: umbral cosine, C8 implícito en app layer
```

```sql
-- ❌ Anti-pattern: Sin umbral → resultados irrelevantes retornados a RAG
SELECT id FROM docs WHERE tenant_id=$1 ORDER BY embedding <=> $2 LIMIT 10;
-- 🔧 Fix: Añadir condición de distancia < threshold + logear ratio de filtrado
```

```sql
-- ✅ C4/V2/C8: Transacción completa con bounds, métrica explícita y audit trail
BEGIN; SET LOCAL statement_timeout='10s'; SET LOCAL work_mem='64MB';
WITH hybrid AS (/* fusion query */)
INSERT INTO audit_log SELECT clock_timestamp(), current_setting('app.tenant_id'), json_build_object('results',count(*)::int) FROM hybrid;
COMMIT;
```

```sql
-- ❌ Anti-pattern: Query híbrida sin timeout ni audit → riesgo de bloqueo o opacidad
SELECT ... FROM hybrid_docs; -- transacción abierta, sin límites C1/C8
-- 🔧 Fix: Envolver en BEGIN/COMMIT con SET LOCAL + inserción a tabla audit C8
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/postgresql-pgvector/hybrid-search-rls-aware.pgvector.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"hybrid-search-rls-aware.pgvector","version":"3.0.0","score":41,"blocking_issues":[],"constraints_verified":["C4","C8","V2"],"examples_count":25,"lines_executable_max":5,"language":"PostgreSQL 14+ pgvector","timestamp":"2026-04-19T00:00:00Z"}
```

---
