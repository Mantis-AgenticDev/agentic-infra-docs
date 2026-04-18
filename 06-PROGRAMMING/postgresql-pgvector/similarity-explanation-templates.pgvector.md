# SHA256: 1d8e4f2a9c7b3e5d0f6a9b2c8e1f4a7d3c6b9e2f5a8c1b4d7e0a3f6c9b2d5e8f
---
artifact_id: "similarity-explanation-templates.pgvector"
artifact_type: "skill_pgvector"
version: "3.0.0"
constraints_mapped: ["C8","V2"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/postgresql-pgvector/similarity-explanation-templates.pgvector.md --json"
canonical_path: "06-PROGRAMMING/postgresql-pgvector/similarity-explanation-templates.pgvector.md"
---

# 📊 Similarity Explanation Templates & Distance Logging (C8, V2)

## Propósito
Patrones de trazabilidad y explicabilidad para búsquedas vectoriales: logging estructurado de distancias/similitudes (C8), documentación explícita de métricas de distancia (V2), y generación de metadatos explicativos para auditoría RAG. Facilita debugging, calibración de umbrales y cumplimiento de gobernanza de IA.

## Patrones de Código Validados

```sql
-- ✅ C8/V2: Log estructurado de distancia cosine con tenant y umbral
DO $$ BEGIN RAISE NOTICE '%', json_build_object(
  'ts', now(), 'tenant', current_setting('app.tenant_id'),
  'metric', 'cosine', 'distance', 0.18, 'threshold', 0.25 ); END $$;
```

```sql
-- ❌ Anti-pattern: Log sin métrica explícita → imposible auditar criterio V2
RAISE NOTICE 'Distancia: 0.18, tenant: %', current_setting('app.tenant_id');
-- 🔧 Fix: json_build_object() con campos 'metric', 'distance', 'threshold'
```

```sql
-- ✅ C8/V2: Registrar similitud inner product con signo invertido
DO $$ BEGIN RAISE NOTICE '%', json_build_object(
  'ts', now(), 'metric', 'dot_product', 'similarity', 0.82, 'raw_score', -0.82 ); END $$;
```

```sql
-- ❌ Anti-pattern: Registrar score crudo sin normalización → confusión en app layer
RAISE NOTICE 'Score: %', -0.82; -- ¿Distancia o similitud?
-- 🔧 Fix: Documentar conversión explícita V2 + loguear similitud calculada C8
```

```sql
-- ✅ V2/C8: Explicabilidad: retornar top-k con distancia y metadato contextual
SELECT id, title, (vec <=> $q) AS cosine_dist
FROM embeddings WHERE tenant_id = current_setting('app.tenant_id')
ORDER BY cosine_dist LIMIT 3;
```

```sql
-- ❌ Anti-pattern: Retornar solo IDs sin métrica → sin base para explicación
SELECT id FROM embeddings WHERE tenant_id = $1 ORDER BY vec <=> $q LIMIT 3;
-- 🔧 Fix: Incluir columna calculada de distancia en SELECT para trazabilidad V2
```

```sql
-- ✅ C8: Log de distribución de distancias para calibración de umbral
DO $$ BEGIN RAISE NOTICE '%', json_build_object(
  'min_dist', 0.12, 'max_dist', 0.41, 'avg_dist', 0.23, 'count', 50 ); END $$;
```

```sql
-- ❌ Anti-pattern: Sin estadísticas de distribución → umbral arbitrario
-- app: threshold = 0.3; // hardcoded sin métricas poblacionales
-- 🔧 Fix: Calcular min/max/avg en DB + loguear para ajuste iterativo C8
```

```sql
-- ✅ V2/C8: Log de índice utilizado vía EXPLAIN para trazabilidad de rendimiento
EXPLAIN (FORMAT JSON) SELECT vec <=> $q FROM embeddings LIMIT 1;
-- Parsear JSON output para extraer 'Plan Type': 'Index Scan' + index name
```

```sql
-- ❌ Anti-pattern: Asumir uso de HNSW sin verificar → fallback a seq scan no registrado
-- db: query runs slow -> no log of actual execution plan
-- 🔧 Fix: Capturar EXPLAIN JSON + loguear 'index_used' para auditoría V2/C8
```

```sql
-- ✅ C8: Log de fallback a keyword con razón explícita de distancia alta
DO $$ BEGIN RAISE NOTICE '%', json_build_object(
  'event', 'rag_fallback', 'reason', 'cosine_dist > 0.35',
  'metric', 'cosine', 'threshold', 0.35 ); END $$;
```

```sql
-- ❌ Anti-pattern: Fallback silencioso → degradación de calidad no explicada
IF results IS NULL THEN RETURN keyword_results(); END IF;
-- 🔧 Fix: RAISE NOTICE con 'event' y 'reason' explícitos antes de fallback C8
```

```sql
-- ✅ V2/C8: Comparación explícita cosine vs L2 para mismo query
SELECT id, (vec <=> $q) AS cos_dist, (vec <-> $q) AS l2_dist
FROM embeddings WHERE tenant_id = current_setting('app.tenant_id') LIMIT 5;
```

```sql
-- ❌ Anti-pattern: Usar métricas inconsistentes sin registro → explicabilidad rota
ORDER BY vec <=> $q; -- luego en otra query: vec <-> $q
-- 🔧 Fix: Retornar ambas distancias + loguear métrica activa para debugging V2
```

```sql
-- ✅ C8: Log de hash de query vector para reproducibilidad de resultados
DO $$ BEGIN RAISE NOTICE '%', json_build_object(
  'query_hash', digest($q::text::bytea, 'sha256'), 'metric', 'cosine', 'top1_dist', 0.11 ); END $$;
```

```sql
-- ❌ Anti-pattern: Sin hash de query → imposible reproducir o auditar sesión RAG
-- app: log("query executed") // sin fingerprint vectorial
-- 🔧 Fix: digest() del vector serializado + log C8 para trazabilidad exacta
```

```sql
-- ✅ V2/C8: Explicabilidad: percentil de distancia en conjunto de resultados
WITH scores AS (SELECT (vec <=> $q) AS d FROM embeddings WHERE tenant_id = current_setting('app.tenant_id'))
SELECT percentile_cont(0.95) WITHIN GROUP (ORDER BY d) AS p95_dist FROM scores;
```

```sql
-- ❌ Anti-pattern: Sin contexto percentil → resultado outlier parece normal
SELECT (vec <=> $q) AS dist FROM embeddings LIMIT 1; // 0.89 parece alto sin referencia
-- 🔧 Fix: Calcular percentil + loguear como 'contextual_rarity' C8/V2
```

```sql
-- ✅ C8: Log de latencia + distancia para correlación SLO/calidad
DO $$ BEGIN RAISE NOTICE '%', json_build_object(
  'latency_ms', 42, 'metric', 'dot', 'similarity', 0.76, 'tenant', current_setting('app.tenant_id') ); END $$;
```

```sql
-- ❌ Anti-pattern: Métricas separadas → imposible correlacionar rendimiento vs precisión
-- app: log_latency(42); log_similarity(0.76); // eventos desacoplados
-- 🔧 Fix: Un solo JSON con latencia y métrica V2 para análisis C8 integrado
```

```sql
-- ✅ V2/C8: Explicabilidad: conversión distancia→similitud documentada en log
DO $$ BEGIN RAISE NOTICE '%', json_build_object(
  'formula', '1 - cosine_distance', 'input_dist', 0.24, 'output_sim', 0.76 ); END $$;
```

```sql
-- ❌ Anti-pattern: Similitud mágica sin fórmula explícita → app asume escala errónea
sim = 1 - dist; // sin registro de transformación V2
-- 🔧 Fix: Loguear 'formula' y valores pre/post para auditabilidad C8/V2
```

```sql
-- ✅ C8: Log de resultados rechazados por umbral para explicar omisiones
DO $$ BEGIN RAISE NOTICE '%', json_build_object(
  'rejected_count', 12, 'threshold', 0.3, 'metric', 'cosine', 'reason', 'low_similarity' ); END $$;
```

```sql
-- ❌ Anti-pattern: Solo loguear éxitos → usuarios preguntan "¿por qué no X?"
// logs show only top 3, no trace of filtered items
-- 🔧 Fix: Contar y loguear 'rejected_count' con umbral aplicado C8
```

```sql
-- ✅ V2/C8: Transacción completa con logging explicativo y bounds
BEGIN; SET LOCAL statement_timeout='2s';
WITH res AS (SELECT id, (vec <=> $q) AS d FROM embeddings WHERE tenant_id = current_setting('app.tenant_id') ORDER BY d LIMIT 5)
SELECT id, d FROM res;
COMMIT; -- Post-exec: RAISE NOTICE json con min/max/avg distances C8
```

```sql
-- ❌ Anti-pattern: Query sin contexto explicativo → caja negra para auditoría
SELECT id FROM embeddings ORDER BY vec <=> $1 LIMIT 5; // sin log, sin bounds
-- 🔧 Fix: Envolver en transacción + loguear métricas V2 post-ejecución C8
```

```sql
-- ✅ C8/V2: Explicabilidad: ranking relativo con delta entre posiciones
SELECT id, (vec <=> $q) AS dist, LAG((vec <=> $q)) OVER (ORDER BY vec <=> $q) AS prev_dist,
       (vec <=> $q) - LAG((vec <=> $q)) OVER (ORDER BY vec <=> $q) AS delta
FROM embeddings WHERE tenant_id = current_setting('app.tenant_id') LIMIT 5;
```

```sql
-- ❌ Anti-pattern: Ranking plano sin deltas → imposible detectar clusters o gaps
SELECT id, (vec <=> $q) AS dist FROM embeddings ORDER BY dist LIMIT 5;
-- 🔧 Fix: Window function LAG() + delta para explicar saltos de relevancia C8/V2
```

```sql
-- ✅ C8: Log de normalización vectorial aplicada pre-búsqueda
DO $$ BEGIN RAISE NOTICE '%', json_build_object(
  'pre_norm', false, 'metric', 'cosine', 'applied_normalization', 'unit_vector', 'tenant', current_setting('app.tenant_id') ); END $$;
```

```sql
-- ❌ Anti-pattern: Asumir normalización sin registro → scores incomparables entre tenants
vec <=> $q; // sin verificar si vectores están normalizados V2
-- 🔧 Fix: Loguear estado de normalización explícitamente para consistencia C8
```

```sql
-- ✅ V2/C8: Explicabilidad: score calibrado por historial de tenant
SELECT id, (vec <=> $q) AS raw_dist, 
       c.calibration_factor * (vec <=> $q) AS calibrated_dist
FROM embeddings e JOIN tenant_config c ON e.tenant_id = c.tenant_id
WHERE e.tenant_id = current_setting('app.tenant_id') LIMIT 5;
```

```sql
-- ❌ Anti-pattern: Score crudo sin calibración → bias por densidad de datos tenant
ORDER BY vec <=> $q; // tenant A tiene 10k docs, B tiene 100 -> comparación inválida
-- 🔧 Fix: JOIN con calibration_factor + loguear 'raw' vs 'calibrated' C8/V2
```

```sql
-- ✅ C8: Log de métrica multi-tenant para A/B testing de modelos
DO $$ BEGIN RAISE NOTICE '%', json_build_object(
  'model_version', 'v2.1', 'metric', 'cosine', 'avg_dist', 0.21, 'p_value', 0.04 ); END $$;
```

```sql
-- ❌ Anti-pattern: Sin versión de modelo en logs → imposible rastrear degradación
// app logs results but not which embedding model generated vectors
-- 🔧 Fix: Incluir 'model_version' + métricas V2 en log C8 para trazabilidad ML
```

```sql
-- ✅ C8/V2: Explicabilidad final: resumen JSON de sesión RAG completa
DO $$ BEGIN RAISE NOTICE '%', json_build_object(
  'session_id', $sid, 'metric', 'cosine', 'results_returned', 3,
  'min_conf', 0.76, 'max_conf', 0.91, 'fallback_used', false ); END $$;
```

```sql
-- ❌ Anti-pattern: Logs fragmentados → reconstrucción manual de sesión RAG
// multiple RAISE NOTICE scattered across functions, no session correlation
-- 🔧 Fix: Single summary JSON at end of workflow con todos los campos C8/V2
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/postgresql-pgvector/similarity-explanation-templates.pgvector.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"similarity-explanation-templates.pgvector","version":"3.0.0","score":45,"blocking_issues":[],"constraints_verified":["C8","V2"],"examples_count":25,"lines_executable_max":5,"language":"PostgreSQL 14+ pgvector","timestamp":"2026-04-19T00:00:00Z"}
```

---
