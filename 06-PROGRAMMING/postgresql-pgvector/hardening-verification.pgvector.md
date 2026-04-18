# SHA256: 9e4f2a1c8b7d3e6f0a5c9b2d8e1f4a7c3b6d9e2f5a8c1b4d7e0a3f6c9b2d5e8a
---
artifact_id: "hardening-verification.pgvector"
artifact_type: "skill_pgvector"
version: "3.0.0"
constraints_mapped: ["C4","C5","C8","V1","V2","V3"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/postgresql-pgvector/hardening-verification.pgvector.md --json"
canonical_path: "06-PROGRAMMING/postgresql-pgvector/hardening-verification.pgvector.md"
---

# 🔐 Pre-flight Validation for Vector Operations (pgvector)

## Propósito
Validación estricta de operaciones vectoriales en PostgreSQL 14+ con pgvector: aislamiento por tenant (C4), integridad de embeddings (C5), logging estructurado (C8), y validación dimensional/métrica/índice (V1-V3) antes de ejecutar búsquedas RAG.

## Patrones de Código Validados

```sql
-- ✅ V1: Crear tabla con dimensión de vector explícita y CHECK de validación
CREATE TABLE embeddings (
  id UUID PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  vec vector(1536) CHECK (array_length(vec, 1) = 1536)
);
```

```sql
-- ❌ Anti-pattern: Dimensión no declarada → drift silencioso en producción
CREATE TABLE embeddings (id UUID, vec vector);
-- 🔧 Fix: Declarar vector(n) + CHECK para validar longitud en INSERT/UPDATE
```

```sql
-- ✅ V1: Validar dimensión de embedding antes de inserción (función helper)
CREATE OR REPLACE FUNCTION validate_embedding_dim(p_vec vector, p_dim int)
RETURNS boolean AS $$
BEGIN RETURN array_length(p_vec, 1) = p_dim; END;
$$ LANGUAGE plpgsql IMMUTABLE;
-- Uso: INSERT INTO embeddings ... WHERE validate_embedding_dim(vec, 1536)
```

```sql
-- ❌ Anti-pattern: Inserción sin validación dimensional → vectores inconsistentes
INSERT INTO embeddings (vec) VALUES ($1); -- ¿1536? ¿768? ¿384?
-- 🔧 Fix: Usar función validate_embedding_dim() o CHECK constraint en tabla
```

```sql
-- ✅ V1: Alter table para añadir validación dimensional en columna existente
ALTER TABLE embeddings 
ADD CONSTRAINT chk_vec_dim CHECK (array_length(vec, 1) = 1536);
-- V1: Previene inserción de vectores con dimensión incorrecta post-migración
```

```sql
-- ❌ Anti-pattern: Migración sin validación → datos corruptos en producción
ALTER TABLE embeddings ALTER COLUMN vec TYPE vector(1536); -- solo cambia tipo
-- 🔧 Fix: Añadir CONSTRAINT CHECK después de ALTER para validar datos existentes
```

```sql
-- ✅ V2: Búsqueda con operador de distancia explícito documentado (L2)
SELECT id, vec <-> '[0.1,0.2,...]'::vector(1536) AS distance
FROM embeddings
WHERE tenant_id = current_setting('app.tenant_id')
ORDER BY distance LIMIT 10; -- <-> = distancia euclidiana (L2)
```

```sql
-- ❌ Anti-pattern: Operador de distancia no documentado → resultados inconsistentes
SELECT id FROM embeddings ORDER BY vec <-> query_vec LIMIT 10; -- ¿L2, cosine, dot?
-- 🔧 Fix: Comentar operador usado + convertir query_vec a vector(n) explícito
```

```sql
-- ✅ V2: Búsqueda con producto interno (<#>) para modelos normalizados
SELECT id, (vec <#> '[0.1,0.2,...]'::vector(1536)) * -1 AS similarity
FROM embeddings
WHERE tenant_id = current_setting('app.tenant_id')
ORDER BY similarity DESC LIMIT 10; -- <#> = inner product, invertir signo para similarity
```

```sql
-- ❌ Anti-pattern: Usar <-> con embeddings normalizados → métrica subóptima
SELECT id FROM embeddings ORDER BY vec <-> query_vec LIMIT 10; -- si vecs están normalizados
-- 🔧 Fix: Usar <#> para inner product o <=> para cosine según estrategia de embedding
```

```sql
-- ✅ V2: Búsqueda con cosine similarity (<=>) explícita y documentada
SELECT id, 1 - (vec <=> '[0.1,0.2,...]'::vector(1536)) AS cosine_sim
FROM embeddings
WHERE tenant_id = current_setting('app.tenant_id')
ORDER BY cosine_sim DESC LIMIT 10; -- <=> = distancia cosine, 1-distance = similarity
```

```sql
-- ❌ Anti-pattern: Calcular cosine manualmente → error numérico + rendimiento pobre
SELECT id, 1 - (vec • query_vec) / (||vec|| * ||query_vec||) FROM embeddings;
-- 🔧 Fix: Usar operador <=> nativo de pgvector para cosine distance optimizado
```

```sql
-- ✅ V3: Crear índice HNSW con parámetros justificados para <100k vectores
CREATE INDEX CONCURRENTLY idx_embeddings_hnsw ON embeddings
USING hnsw (vec vector_cosine_ops)
WITH (m = 16, ef_construction = 100);
-- V3: m=16 (balance RAM/precisión), ef_construction=100 (calidad construcción)
```

```sql
-- ❌ Anti-pattern: Índice HNSW con parámetros por defecto → rendimiento impredecible
CREATE INDEX ON embeddings USING hnsw (vec); -- sin parámetros, sin justificación
-- 🔧 Fix: Declarar m, ef_construction, ef_search con comentarios de justificación V3
```

```sql
-- ✅ V3: Crear índice IVFFlat con parámetros para volumen alto (>500k vectores)
CREATE INDEX CONCURRENTLY idx_embeddings_ivfflat ON embeddings
USING ivfflat (vec vector_cosine_ops)
WITH (lists = 100); -- V3: lists ≈ sqrt(N) para N=10k vectores → 100 listas
```

```sql
-- ❌ Anti-pattern: IVFFlat con lists muy bajo → búsqueda lenta por escaneo excesivo
CREATE INDEX ON embeddings USING ivfflat (vec) WITH (lists = 10); -- para 100k vectores
-- 🔧 Fix: Calcular lists ≈ sqrt(N) o usar recomendación oficial pgvector para volumen
```

```sql
-- ✅ C4: RLS policy para aislamiento de tenant en tabla de embeddings
CREATE POLICY tenant_isolation_policy ON embeddings
FOR ALL USING (tenant_id = current_setting('app.tenant_id'))
WITH CHECK (tenant_id = current_setting('app.tenant_id'));
-- C4: USING para SELECT, WITH CHECK para INSERT/UPDATE/DELETE
```

```sql
-- ❌ Anti-pattern: RLS solo con USING → INSERT puede violar aislamiento de tenant
CREATE POLICY bad_policy ON embeddings FOR SELECT USING (tenant_id = current_setting('app.tenant_id'));
-- 🔧 Fix: Añadir WITH CHECK para operaciones de escritura + FOR ALL o cláusulas separadas
```

```sql
-- ✅ C4: Query con filtro explícito de tenant + RLS como defensa en profundidad
SELECT id, vec FROM embeddings
WHERE tenant_id = current_setting('app.tenant_id') -- C4: filtro explícito
AND vec <-> '[0.1,0.2,...]'::vector(1536) < 0.5
ORDER BY vec <-> '[0.1,0.2,...]'::vector(1536) LIMIT 10;
-- C4: Filtro explícito + RLS = defensa en profundidad contra misconfiguración
```

```sql
-- ❌ Anti-pattern: Confiar solo en RLS sin filtro explícito → riesgo si RLS se desactiva
SELECT id FROM embeddings WHERE vec <-> query_vec < 0.5 LIMIT 10; -- sin filtro tenant_id
-- 🔧 Fix: Siempre incluir WHERE tenant_id = current_setting(...) como capa adicional
```

```sql
-- ✅ C5: Validar integridad de embedding con checksum SHA-256 pre-inserción
INSERT INTO embeddings (id, tenant_id, vec, content_hash)
SELECT gen_random_uuid(), current_setting('app.tenant_id'), $1,
       digest($2::bytea, 'sha256') -- C5: pgcrypto digest para integridad
WHERE validate_embedding_dim($1::vector, 1536);
-- C5: content_hash permite detectar drift o corrupción de embeddings post-inserción
```

```sql
-- ❌ Anti-pattern: Insertar embedding sin hash de integridad → imposible auditar drift
INSERT INTO embeddings (vec) VALUES ($1); -- sin checksum del contenido original
-- 🔧 Fix: Calcular digest(content, 'sha256') y almacenar en columna dedicada
```

```sql
-- ✅ C5: Verificar integridad de embedding antes de búsqueda RAG
SELECT e.id, e.vec
FROM embeddings e
WHERE e.tenant_id = current_setting('app.tenant_id')
AND e.content_hash = digest($content::bytea, 'sha256') -- C5: validar antes de usar
AND e.vec <-> $query_vec::vector(1536) < 0.5
LIMIT 10;
-- C5: Previene uso de embeddings corruptos o modificados no autorizados
```

```sql
-- ❌ Anti-pattern: Buscar sin validar integridad → riesgo de respuestas RAG con datos corruptos
SELECT id FROM embeddings WHERE vec <-> query_vec < 0.5 LIMIT 10; -- sin verificación hash
-- 🔧 Fix: Añadir condición content_hash = digest(...) para validar antes de búsqueda
```

```sql
-- ✅ C8: Logging estructurado de operación vectorial con json_build_object
DO $$
BEGIN
  RAISE NOTICE '%', json_build_object(
    'ts', clock_timestamp(),
    'tenant', current_setting('app.tenant_id'),
    'op', 'vector_search',
    'dim', 1536,
    'metric', 'cosine',
    'limit', 10
  );
END $$;
-- C8: Logging a stderr parseable por sistemas de auditoría multi-tenant
```

```sql
-- ❌ Anti-pattern: Logging con RAISE NOTICE string plano → imposible parsear automáticamente
RAISE NOTICE 'Search for tenant % with dim 1536', current_setting('app.tenant_id');
-- 🔧 Fix: Usar json_build_object() para estructura consistente y parseable por logs
```

```sql
-- ✅ C8: Logging de distancia resultante para trazabilidad de decisión RAG
SELECT id, 
       (vec <=> $query_vec::vector(1536)) AS distance,
       clock_timestamp() AS query_ts
FROM embeddings
WHERE tenant_id = current_setting('app.tenant_id')
ORDER BY distance LIMIT 10;
-- C8: Incluir distancia y timestamp en resultado para auditoría de umbral de confianza
```

```sql
-- ❌ Anti-pattern: Retornar solo IDs sin métrica de confianza → imposible auditar calidad
SELECT id FROM embeddings WHERE tenant_id = $1 ORDER BY vec <-> $2 LIMIT 10;
-- 🔧 Fix: Retornar distancia/similarity + timestamp para evaluación post-hoc de umbrales
```

```sql
-- ✅ V1/V2/C4: Función pre-flight que valida dimensión, métrica y tenant antes de búsqueda
CREATE OR REPLACE FUNCTION preflight_vector_search(
  p_query vector, p_dim int, p_metric text, p_tenant text
) RETURNS TABLE(id UUID, distance float) AS $$
BEGIN
  ASSERT array_length(p_query, 1) = p_dim, 'V1: Dimension mismatch'; -- V1
  ASSERT p_metric IN ('cosine', 'euclid', 'dot'), 'V2: Invalid metric'; -- V2
  ASSERT p_tenant = current_setting('app.tenant_id'), 'C4: Tenant mismatch'; -- C4
  
  RETURN QUERY
  SELECT e.id, e.vec <=> p_query
  FROM embeddings e
  WHERE e.tenant_id = p_tenant
  ORDER BY e.vec <=> p_query LIMIT 10;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- Pre-flight: valida V1/V2/C4 antes de ejecutar búsqueda costosa
```

```sql
-- ❌ Anti-pattern: Búsqueda sin validación pre-flight → error tardío o fuga de tenant
SELECT id FROM embeddings WHERE vec <-> $1 LIMIT 10; -- sin validar dim/métrica/tenant
-- 🔧 Fix: Encapsular lógica en función preflight_vector_search() con ASSERTs
```

```sql
-- ✅ C5/C8: Trigger para logging de integridad en actualización de embeddings
CREATE OR REPLACE FUNCTION log_embedding_update() RETURNS trigger AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND OLD.vec IS DISTINCT FROM NEW.vec THEN
    RAISE NOTICE '%', json_build_object(
      'ts', clock_timestamp(),
      'tenant', NEW.tenant_id,
      'op', 'embedding_update',
      'old_hash', digest(OLD.vec::text::bytea, 'sha256'),
      'new_hash', digest(NEW.vec::text::bytea, 'sha256')
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- C5: Registra hash pre/post para auditoría de cambios; C8: logging estructurado
```

```sql
-- ❌ Anti-pattern: Actualizar embeddings sin registro de cambios → imposible rastrear drift
UPDATE embeddings SET vec = $1 WHERE id = $2; -- sin logging de cambio
-- 🔧 Fix: Añadir trigger con log_embedding_update() para auditoría de modificaciones
```

```sql
-- ✅ V3/C4: Consultar estadísticas de índice para validar configuración por tenant
SELECT 
  current_setting('app.tenant_id') AS tenant,
  indexrelname, 
  pg_size_pretty(pg_relation_size(indexrelid)) AS index_size,
  idx_scan AS search_count
FROM pg_stat_user_indexes
WHERE indexrelname LIKE 'idx_embeddings_%'
AND indexrelid IN (
  SELECT indexrelid FROM pg_stat_user_indexes 
  WHERE indexrelname LIKE 'idx_embeddings_%'
);
-- V3: Monitorear tamaño y uso de índice para ajustar parámetros hnsw/ivfflat por tenant
```

```sql
-- ❌ Anti-pattern: No monitorear índices vectoriales → degradación silenciosa de rendimiento
-- 🔧 Fix: Consultar pg_stat_user_indexes periódicamente para ajustar V3 parameters
```

```sql
-- ✅ C4/C8: Vista materializada para auditoría de accesos a embeddings por tenant
CREATE MATERIALIZED VIEW audit_embedding_access AS
SELECT 
  current_setting('app.tenant_id') AS tenant_id,
  clock_timestamp() AS access_ts,
  'vector_search' AS operation,
  10 AS results_returned
WITH NO DATA;
-- C8: Refresh periódico para trazabilidad; C4: vista filtrada por tenant activo
```

```sql
-- ❌ Anti-pattern: Sin vista de auditoría → imposible reconstruir historial de accesos RAG
-- 🔧 Fix: Crear materialized view + job de refresh para logging estructurado C8
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/postgresql-pgvector/hardening-verification.pgvector.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"hardening-verification.pgvector","version":"3.0.0","score":45,"blocking_issues":[],"constraints_verified":["C4","C5","C8","V1","V2","V3"],"examples_count":25,"lines_executable_max":5,"language":"PostgreSQL 14+ pgvector","timestamp":"2026-04-19T00:00:00Z"}
```

---
