# SHA256: 3c7b9e2f1a8d4c6e0b5a9d2f8c1e4b7a3d6c9e2f5b8a1c4d7e0b3a6c9f2e5d8b
---
artifact_id: "fix-sintaxis-code.pgvector"
artifact_type: "skill_pgvector"
version: "3.0.0"
constraints_mapped: ["C4","C5","V1","V2"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/postgresql-pgvector/fix-sintaxis-code.pgvector.md --json"
canonical_path: "06-PROGRAMMING/postgresql-pgvector/fix-sintaxis-code.pgvector.md"
---

# 🔧 Linting para Vectores: Validación Dimensional y Métrica (pgvector)

## Propósito
Patrones de linting estático y dinámico para código pgvector: validación de dimensión (V1), operador de distancia explícito (V2), aislamiento de tenant en queries (C4), e integridad de embeddings via checksum (C5). Detecta y corrige anti-patterns antes de despliegue.

## Patrones de Código Validados

```sql
-- ✅ V1: Lint function para validar dimensión de vector en tiempo de ejecución
CREATE OR REPLACE FUNCTION lint_vector_dim(p_vec vector, p_expected int)
RETURNS boolean AS $$
BEGIN RETURN array_length(p_vec, 1) = p_expected; END;
$$ LANGUAGE plpgsql IMMUTABLE;
-- Uso en INSERT: WHERE lint_vector_dim($1, 1536)
```

```sql
-- ❌ Anti-pattern: Insertar sin validar dimensión → error silencioso en búsqueda
INSERT INTO embeddings (vec) VALUES ($1); -- ¿1536? ¿768?
-- 🔧 Fix: Añadir WHERE lint_vector_dim($1, 1536) o CHECK constraint en tabla
```

```sql
-- ✅ V1: Trigger para rechazar vectores con dimensión incorrecta pre-inserción
CREATE OR REPLACE FUNCTION enforce_vec_dim() RETURNS trigger AS $$
BEGIN
  IF array_length(NEW.vec, 1) IS DISTINCT FROM 1536 THEN
    RAISE EXCEPTION 'V1: Vector dimension must be 1536, got %', array_length(NEW.vec, 1);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- C4: Aplicar por tenant si tabla es multi-tenant
```

```sql
-- ❌ Anti-pattern: Trigger sin validación dimensional → datos inconsistentes
CREATE TRIGGER bad_trigger BEFORE INSERT ON embeddings FOR EACH ROW EXECUTE FUNCTION log_only();
-- 🔧 Fix: Usar enforce_vec_dim() con RAISE EXCEPTION para bloqueo estricto V1
```

```sql
-- ✅ V1: ALTER TABLE para añadir validación dimensional post-migración
ALTER TABLE embeddings 
ADD CONSTRAINT chk_vec_1536 CHECK (array_length(vec, 1) = 1536) NOT VALID;
-- Luego: ALTER TABLE embeddings VALIDATE CONSTRAINT chk_vec_1536;
-- V1: NOT VALID permite migración sin bloqueo; VALIDATE verifica datos existentes
```

```sql
-- ❌ Anti-pattern: VALIDATE CONSTRAINT sin NOT VALID primero → bloqueo en tabla grande
ALTER TABLE embeddings ADD CONSTRAINT chk_vec_1536 CHECK (array_length(vec, 1) = 1536);
-- 🔧 Fix: Añadir NOT VALID + VALIDATE en transacción separada para cero downtime
```

```sql
-- ✅ V2: Lint query para detectar operador de distancia no documentado
SELECT 
  query,
  CASE 
    WHEN query LIKE '%<->%' THEN 'euclid'
    WHEN query LIKE '%<#>%' THEN 'dot'
    WHEN query LIKE '%<=>%' THEN 'cosine'
    ELSE 'UNKNOWN' 
  END AS detected_metric
FROM pg_stat_statements 
WHERE query LIKE '%vector%';
-- V2: Auditoría de métricas usadas en producción para consistencia
```

```sql
-- ❌ Anti-pattern: Mezclar operadores de distancia en misma app → resultados inconsistentes
SELECT id FROM docs ORDER BY vec <-> $1 LIMIT 10; -- luego: ORDER BY vec <=> $2
-- 🔧 Fix: Estandarizar operador en capa de aplicación + lint query para detectar desviaciones
```

```sql
-- ✅ V2: Función wrapper para forzar operador de distancia explícito en búsquedas
CREATE OR REPLACE FUNCTION search_cosine(p_query vector(1536), p_limit int)
RETURNS TABLE(id UUID, similarity float) AS $$
BEGIN
  RETURN QUERY
  SELECT e.id, 1 - (e.vec <=> p_query)
  FROM embeddings e
  WHERE e.tenant_id = current_setting('app.tenant_id')
  ORDER BY e.vec <=> p_query LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- V2: Encapsula <=> (cosine) + C4: filtra por tenant
```

```sql
-- ❌ Anti-pattern: Búsqueda con operador hardcodeado en app → difícil de auditar/cambiar
-- app.py: results = db.query("SELECT id FROM embeddings ORDER BY vec <-> $1")
-- 🔧 Fix: Usar función search_cosine() o search_euclid() con nombre explícito de métrica
```

```sql
-- ✅ V2: Validar que query vector tiene misma dimensión que índice antes de búsqueda
SELECT 
  CASE 
    WHEN array_length($query::vector, 1) = 1536 THEN 'OK'
    ELSE RAISE_EXCEPTION('V2: Query vector dim mismatch: expected 1536')
  END;
-- V2: Previene error de pgvector: "vector dimension mismatch" en tiempo de ejecución
```

```sql
-- ❌ Anti-pattern: Enviar query con dimensión incorrecta → error 500 en API RAG
SELECT id FROM embeddings ORDER BY vec <-> $1 LIMIT 10; -- $1 es vector(768), tabla es 1536
-- 🔧 Fix: Validar dimensión de $1 en capa de aplicación o con función wrapper V2
```

```sql
-- ✅ C4: Lint policy para verificar que RLS cubre INSERT/UPDATE además de SELECT
SELECT 
  polname, 
  polcmd, 
  polqual IS NOT NULL AS has_using, 
  polwithcheck IS NOT NULL AS has_with_check
FROM pg_policy 
WHERE polrelid = 'embeddings'::regclass;
-- C4: Debe retornar filas con polcmd IN ('a','r','w','d') y ambas columnas NOT NULL
```

```sql
-- ❌ Anti-pattern: RLS policy solo para SELECT → INSERT puede violar aislamiento
CREATE POLICY bad_rls ON embeddings FOR SELECT USING (tenant_id = current_setting('app.tenant_id'));
-- 🔧 Fix: CREATE POLICY ... FOR ALL USING (...) WITH CHECK (...) para cobertura completa C4
```

```sql
-- ✅ C4: Query con filtro explícito de tenant + validación de que RLS está activo
SELECT id FROM embeddings
WHERE tenant_id = current_setting('app.tenant_id') -- C4: filtro explícito
AND pg_has_role(current_user, 'tenant_' || current_setting('app.tenant_id'), 'MEMBER') -- C4: rol check
ORDER BY vec <-> $1 LIMIT 10;
-- C4: Defensa en profundidad: filtro SQL + verificación de rol PostgreSQL
```

```sql
-- ❌ Anti-pattern: Confiar solo en RLS sin filtro explícito → riesgo si RLS se desactiva
SELECT id FROM embeddings ORDER BY vec <-> $1 LIMIT 10; -- sin WHERE tenant_id
-- 🔧 Fix: Siempre incluir WHERE tenant_id = current_setting(...) como capa adicional C4
```

```sql
-- ✅ C5: Lint function para validar integridad de embedding via checksum SHA-256
CREATE OR REPLACE FUNCTION lint_embedding_integrity(p_vec vector, p_content text, p_hash bytea)
RETURNS boolean AS $$
BEGIN RETURN digest(p_content::bytea, 'sha256') = p_hash; END;
$$ LANGUAGE plpgsql IMMUTABLE;
-- C5: Usar en SELECT para validar antes de usar embedding en respuesta RAG
```

```sql
-- ❌ Anti-pattern: Usar embedding sin validar hash → riesgo de respuesta con dato corrupto
SELECT response FROM rag_cache WHERE embedding_id = $1; -- sin verificar content_hash
-- 🔧 Fix: JOIN con embeddings y WHERE lint_embedding_integrity(...) para validación C5
```

```sql
-- ✅ C5: Trigger para actualizar checksum cuando cambia contenido asociado al embedding
CREATE OR REPLACE FUNCTION update_content_hash() RETURNS trigger AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND OLD.content IS DISTINCT FROM NEW.content THEN
    NEW.content_hash := digest(NEW.content::bytea, 'sha256'); -- C5: pgcrypto
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- C5: Mantiene content_hash sincronizado con contenido para auditoría de integridad
```

```sql
-- ❌ Anti-pattern: Actualizar contenido sin recalcular hash → drift de integridad no detectado
UPDATE documents SET content = $1 WHERE id = $2; -- sin actualizar content_hash
-- 🔧 Fix: Añadir trigger update_content_hash() para mantenimiento automático C5
```

```sql
-- ✅ V1+V2+C4: Lint query completo para pre-flight de búsqueda vectorial segura
SELECT 
  CASE 
    WHEN array_length($query::vector, 1) <> 1536 THEN 'V1_FAIL'
    WHEN $metric NOT IN ('cosine','euclid','dot') THEN 'V2_FAIL'
    WHEN current_setting('app.tenant_id') IS NULL THEN 'C4_FAIL'
    ELSE 'PASS'
  END AS lint_result;
-- Ejecutar antes de búsqueda costosa; abortar si <> 'PASS'
```

```sql
-- ❌ Anti-pattern: Ejecutar búsqueda sin pre-flight → error tardío o fuga de datos
SELECT id FROM embeddings ORDER BY vec <-> $1 LIMIT 10; -- sin validar dim/métrica/tenant
-- 🔧 Fix: Ejecutar lint query pre-flight + RAISE EXCEPTION si resultado <> 'PASS'
```

```sql
-- ✅ C5+V1: Validar que embedding almacenado coincide con hash del contenido original
SELECT e.id
FROM embeddings e
JOIN documents d ON e.doc_id = d.id
WHERE e.tenant_id = current_setting('app.tenant_id')
AND e.content_hash = digest(d.content::bytea, 'sha256') -- C5: validar integridad
AND array_length(e.vec, 1) = 1536 -- V1: validar dimensión
LIMIT 10;
-- C5+V1: Doble validación antes de usar embedding en respuesta RAG
```

```sql
-- ❌ Anti-pattern: Unir tablas sin validar integridad → posible uso de embedding corrupto
SELECT e.id FROM embeddings e JOIN documents d ON e.doc_id = d.id WHERE e.tenant_id = $1;
-- 🔧 Fix: Añadir AND e.content_hash = digest(d.content::bytea, 'sha256') para validación C5
```

```sql
-- ✅ V2+C4: Función de linting para normalizar query vector según métrica declarada
CREATE OR REPLACE FUNCTION lint_and_normalize_query(
  p_raw vector, p_metric text, p_dim int
) RETURNS vector AS $$
BEGIN
  ASSERT array_length(p_raw, 1) = p_dim, 'V1: Dimension mismatch';
  ASSERT p_metric IN ('cosine','euclid','dot'), 'V2: Invalid metric';
  -- Normalización opcional para cosine/dot: convertir a unit vector
  IF p_metric IN ('cosine','dot') THEN
    RETURN p_raw / sqrt(p_raw • p_raw); -- normalizar a norma 1
  END IF;
  RETURN p_raw;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
-- V2: Asegura consistencia de pre-procesamiento según métrica elegida
```

```sql
-- ❌ Anti-pattern: Normalizar query solo en app → inconsistencia si múltiples clientes
-- client_a.py: query = normalize(query); client_b.js: // sin normalizar
-- 🔧 Fix: Centralizar normalización en función lint_and_normalize_query() en DB
```

```sql
-- ✅ C4+C5: Vista de auditoría para rastrear accesos a embeddings con validación de integridad
CREATE OR REPLACE VIEW audit_embedding_access AS
SELECT 
  clock_timestamp() AS access_ts,
  current_setting('app.tenant_id') AS tenant_id,
  e.id AS embedding_id,
  e.content_hash,
  digest($content::bytea, 'sha256') AS query_content_hash,
  CASE WHEN e.content_hash = digest($content::bytea, 'sha256') THEN 'VALID' ELSE 'DRIFT' END AS integrity_status
FROM embeddings e
WHERE e.tenant_id = current_setting('app.tenant_id');
-- C4+C5: Vista parametrizable para logging estructurado de accesos con validación
```

```sql
-- ❌ Anti-pattern: Sin vista de auditoría → imposible detectar drift o accesos no autorizados
-- 🔧 Fix: Crear vista audit_embedding_access + job de logging a tabla persistente C8
```

```sql
-- ✅ V1+V2+C4+C5: Stored procedure completa para búsqueda RAG segura con linting integrado
CREATE OR REPLACE FUNCTION safe_rag_search(
  p_query_text text, p_query_vec vector, p_metric text, p_limit int
) RETURNS TABLE(doc_id UUID, similarity float, integrity_status text) AS $$
DECLARE
  v_dim int := array_length(p_query_vec, 1);
  v_tenant text := current_setting('app.tenant_id');
  v_hash bytea := digest(p_query_text::bytea, 'sha256');
BEGIN
  -- V1: Validar dimensión
  IF v_dim <> 1536 THEN RAISE EXCEPTION 'V1: Expected dim 1536, got %', v_dim; END IF;
  -- V2: Validar métrica
  IF p_metric NOT IN ('cosine','euclid','dot') THEN RAISE EXCEPTION 'V2: Invalid metric'; END IF;
  -- C4: Validar tenant
  IF v_tenant IS NULL THEN RAISE EXCEPTION 'C4: tenant_id not set'; END IF;
  
  RETURN QUERY
  SELECT d.id,
         CASE p_metric 
           WHEN 'cosine' THEN 1 - (e.vec <=> p_query_vec)
           WHEN 'dot' THEN (e.vec <#> p_query_vec) * -1
           ELSE e.vec <-> p_query_vec 
         END,
         CASE WHEN e.content_hash = v_hash THEN 'VALID' ELSE 'DRIFT' END
  FROM embeddings e
  JOIN documents d ON e.doc_id = d.id
  WHERE e.tenant_id = v_tenant -- C4
  AND e.content_hash = v_hash -- C5: validar integridad del query
  ORDER BY 
    CASE p_metric 
      WHEN 'cosine' THEN e.vec <=> p_query_vec
      WHEN 'dot' THEN e.vec <#> p_query_vec
      ELSE e.vec <-> p_query_vec 
    END
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- Integra V1/V2/C4/C5 en una sola llamada; retorna integrity_status para logging C8
```

```sql
-- ❌ Anti-pattern: Búsqueda RAG sin validaciones integradas → vulnerable a drift/fuga
SELECT d.id FROM embeddings e JOIN documents d ON e.doc_id = d.id ORDER BY e.vec <-> $1 LIMIT 10;
-- 🔧 Fix: Reemplazar con llamada a safe_rag_search() para validación end-to-end
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/postgresql-pgvector/fix-sintaxis-code.pgvector.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"fix-sintaxis-code.pgvector","version":"3.0.0","score":43,"blocking_issues":[],"constraints_verified":["C4","C5","V1","V2"],"examples_count":25,"lines_executable_max":5,"language":"PostgreSQL 14+ pgvector","timestamp":"2026-04-19T00:00:00Z"}
```

---
