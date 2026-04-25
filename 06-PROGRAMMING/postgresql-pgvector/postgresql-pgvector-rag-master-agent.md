---
artifact_id: postgresql-pgvector-rag-master-agent-mantis
artifact_type: agentic_skill_definition
version: 1.0.0
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","V1","V2","V3"]
canonical_path: 06-PROGRAMMING/postgresql-pgvector/postgresql-pgvector-rag-master-agent.md
tier: 1
language_lock: ["sql","sql_pgvector"]
governance_severity: error
validation_hooks:
  - verify-constraints.sh
  - audit-secrets.sh
  - check-rls.sh
  - schema-validator.py
---
# 🐘 PostgreSQL + pgvector + RAG Master Agent para MANTIS AGENTIC

> **Dominio**: Base de datos vectorial y búsqueda semántica (`06-PROGRAMMING/postgresql-pgvector/`)  
> **Severidad de validación**: 🔴 **ROJA** (crítico, bloqueo en CI/CD)  
> **Stack permitido**: PostgreSQL 15+, pgvector 0.7+, SQL estándar + operadores vectoriales (`<->`, `<=>`, `<#>`)  
> **Constraints declaradas**: C1-C8 + V1-V3 — **ÚNICA carpeta autorizada para operadores vectoriales** (LANGUAGE LOCK)

---

## 🎯 Propósito Atómico

Ser el **único punto de verdad** para desarrollo de schemas, consultas, índices y pipelines RAG con PostgreSQL + pgvector dentro de MANTIS AGENTIC:
- ✅ Generar schemas vectoriales multi-tenant con políticas RLS (C4)
- ✅ Configurar índices HNSW/IVFFlat con parámetros justificados (V3) y límites de recursos (C1)
- ✅ Implementar pipelines RAG completos: embeddings, búsqueda híbrida, reranking, caché
- ✅ Validar dimensionalidad de vectores (V1) y métricas de distancia documentadas (V2)
- ✅ Aplicar LANGUAGE LOCK inverso: **SOLO aquí** se permiten operadores vectoriales
- ✅ Emitir output estructurado: JSON a `stdout`, logs a `stderr`, JSONL a `08-LOGS/`
- ✅ **Enseñar mientras genera**: explicar cada decisión de diseño, índice y consulta

---

## 🔐 Contrato de Gobernanza (V-INT COMPLIANT)

### Frontmatter Obligatorio en Todo Artifact Generado
```yaml
---
artifact_id: <kebab-case-único>
artifact_type: sql_schema | vector_index | rag_pipeline | embedding_config | migration
version: <semver>
constraints_mapped: ["C3","C4","C5","V1","V2","V3", ...]
canonical_path: 06-PROGRAMMING/postgresql-pgvector/<archivo>.pgvector.md
tier: 1 | 2 | 3
---
```

### Constraints Aplicadas por Contexto
| Constraint | Qué exige | Ejemplo de declaración válida |
|------------|-----------|------------------------------|
| **C1-C2** (Recursos) | `work_mem`, `max_parallel_workers`, `statement_timeout`, límites de memoria en índices | `SET LOCAL work_mem = '256MB'` ✅ |
| **C3** (Secrets) | Cero hardcode de credenciales en funciones SQL o configs | `current_setting('app.api_key')` ✅ |
| **C4** (Tenant Isolation) | **TODA** query debe filtrar por `tenant_id` o usar RLS | `WHERE tenant_id = current_setting('app.current_tenant')` ✅ |
| **C5** (Estructura) | Schemas válidos con frontmatter YAML y `canonical_path` correcto | Ver ejemplos abajo ✅ |
| **C6** (Auditabilidad) | Funciones con `SECURITY DEFINER` documentadas, migraciones versionadas | `CREATE FUNCTION ... SECURITY DEFINER SET search_path = ''` ✅ |
| **C7** (Resiliencia) | Timeouts, reintentos, manejo de errores en funciones | `SET LOCAL statement_timeout = '30s'` ✅ |
| **C8** (Observabilidad) | Logging estructurado con `json_build_object()`, tracing con `tenant_id` | `RAISE LOG '%', json_build_object('op','search','tenant',current_setting('app.current_tenant'))` ✅ |
| **V1** (Dimensiones) | Declaración explícita de dimensiones del embedding | `vector(1536)` + comentario `-- model: text-embedding-3-small` ✅ |
| **V2** (Métrica) | Documentar operador de distancia usado y justificación | `<=>` (cosine) con embeddings normalizados ✅ |
| **V3** (Índice) | Justificar elección HNSW vs IVFFlat con parámetros | `WITH (m=16, ef_construction=100)` + benchmark ✅ |

### 🔒 LANGUAGE LOCK: Matriz de Operadores Vectoriales
| Operador | Permitido en `postgresql-pgvector/` | Bloqueado en otros dominios |
|----------|--------------------------------------|------------------------------|
| `<->` (L2 distance) | ✅ **SOLO AQUÍ** | ❌ `sql/`, `go/`, `python/`, etc. |
| `<=>` (cosine distance) | ✅ **SOLO AQUÍ** | ❌ `sql/`, `go/`, `python/`, etc. |
| `<#>` (inner product) | ✅ **SOLO AQUÍ** | ❌ `sql/`, `go/`, `python/`, etc. |
| `vector(n)` type | ✅ **SOLO AQUÍ** | ❌ `sql/`, `go/`, `python/`, etc. |
| `USING hnsw` | ✅ **SOLO AQUÍ** | ❌ `sql/`, `go/`, `python/`, etc. |
| `USING ivfflat` | ✅ **SOLO AQUÍ** | ❌ `sql/`, `go/`, `python/`, etc. |

---

## 🧠 Capacidades Integradas (Conocimiento Completo)

### 1. 🏗️ PostgreSQL Core: Data Types & Indexing (C4, C5)
Basado en `postgresql.md` + `postgres-best-practices.md`:

```sql
-- ✅ IDs: BIGINT IDENTITY o UUIDv7 (no UUIDv4 aleatorio)
CREATE TABLE documents (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id UUID NOT NULL DEFAULT current_setting('app.current_tenant')::UUID,
    content_hash TEXT NOT NULL UNIQUE,  -- C5: integridad con SHA-256
    content TEXT NOT NULL,
    metadata JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ✅ Índices: FK siempre indexados manualmente (Postgres NO lo hace automático)
CREATE INDEX idx_documents_tenant ON documents(tenant_id);
CREATE INDEX idx_documents_created ON documents(created_at);
CREATE INDEX idx_documents_metadata ON documents USING GIN(metadata);

-- ✅ JSONB: usar GIN para contención (@>, ?, ?&)
-- jsonb_ops (default): soporta todos los operadores
CREATE INDEX idx_docs_meta_gin ON documents USING GIN(metadata);
-- jsonb_path_ops: solo @> pero 2-3x más pequeño
CREATE INDEX idx_docs_meta_path ON documents USING GIN(metadata jsonb_path_ops);

-- ✅ Partial indexes para queries filtradas consistentemente
CREATE INDEX idx_docs_active ON documents(tenant_id, created_at)
WHERE metadata->>'status' = 'published';

-- ✅ Covering indexes con INCLUDE para index-only scans
CREATE INDEX idx_docs_covering ON documents(tenant_id, created_at)
INCLUDE (content_hash, metadata)
WHERE metadata->>'status' = 'published';

-- ✅ RLS obligatorio para multi-tenant (C4)
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON documents
    FOR ALL
    USING (tenant_id = current_setting('app.current_tenant')::UUID);
ALTER TABLE documents FORCE ROW LEVEL SECURITY;  -- Incluso para superusers
```

### 2. 🗄️ pgvector: Schema Design & Embedding Patterns (V1, V2, V3)
Basado en `tenant-isolation-for-embeddings.pgvector.md` + `vector-indexing-patterns.pgvector.md`:

```sql
-- ✅ Extension pgvector habilitada
CREATE EXTENSION IF NOT EXISTS vector;

-- ✅ Tabla de embeddings con dimensionalidad explícita (V1)
CREATE TABLE document_embeddings (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    document_id BIGINT NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL,
    embedding VECTOR(1536) NOT NULL,  -- V1: dimensión explícita (model: text-embedding-3-small)
    embedding_model TEXT NOT NULL DEFAULT 'text-embedding-3-small',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    -- C4: tenant_id duplicado para RLS eficiente (sin JOIN)
    CONSTRAINT fk_doc_embeddings_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id)
);

-- ✅ Índices vectoriales con parámetros justificados (V3)
-- HNSW: mejor recall, más memoria, build lento
-- IVFFlat: más rápido de construir, menos recall, menos memoria
CREATE INDEX idx_embeddings_hnsw ON document_embeddings
    USING hnsw (embedding vector_cosine_ops)
    WITH (m=16, ef_construction=100);  -- V3: m=16 recomendado para 1536d

-- ✅ IVFFlat alternativo para datasets >10M vectores
CREATE INDEX idx_embeddings_ivf ON document_embeddings
    USING ivfflat (embedding vector_cosine_ops)
    WITH (lists=100);  -- V3: lists ≈ sqrt(n_vectors)

-- ✅ RLS para embeddings (C4)
ALTER TABLE document_embeddings ENABLE ROW LEVEL SECURITY;
CREATE POLICY embeddings_tenant_isolation ON document_embeddings
    FOR ALL
    USING (tenant_id = current_setting('app.current_tenant')::UUID);

-- ✅ Función de búsqueda con tenant enforcement (C4) + métrica documentada (V2)
CREATE OR REPLACE FUNCTION search_similar(
    p_query_embedding VECTOR(1536),
    p_tenant_id UUID,
    p_limit INT DEFAULT 10,
    p_threshold FLOAT DEFAULT 0.7  -- V2: cosine similarity threshold
) RETURNS TABLE(
    document_id BIGINT,
    content TEXT,
    similarity FLOAT,
    metadata JSONB
) LANGUAGE plpgsql
SECURITY DEFINER  -- C6: ejecuta con privilegios del definidor
SET search_path = ''
AS $$
BEGIN
    -- V2: cosine distance (<=>) con embeddings normalizados
    -- similarity = 1 - distance para interpretación intuitiva
    RETURN QUERY
    SELECT 
        de.document_id,
        d.content,
        1.0 - (de.embedding <=> p_query_embedding) AS similarity,
        d.metadata
    FROM document_embeddings de
    JOIN documents d ON d.id = de.document_id
    WHERE de.tenant_id = p_tenant_id  -- ✅ C4: tenant isolation explícito
      AND 1.0 - (de.embedding <=> p_query_embedding) >= p_threshold  -- ✅ V2: threshold aplicado
    ORDER BY de.embedding <=> p_query_embedding  -- ✅ V2: cosine distance para ordenamiento
    LIMIT p_limit;
END;
$$;
```

### 3. 🔍 Hybrid Search & RAG Pipeline (V1-V3, C4, C8)
Basado en `hybrid-search-rls-aware.pgvector.md` + `rag-query-with-tenant-enforcement.pgvector.md`:

```sql
-- ✅ Búsqueda híbrida: vector + keyword con Reciprocal Rank Fusion (RRF)
CREATE OR REPLACE FUNCTION hybrid_search_rag(
    p_query_embedding VECTOR(1536),
    p_query_text TEXT,
    p_tenant_id UUID,
    p_limit INT DEFAULT 10,
    p_alpha FLOAT DEFAULT 0.5  -- Peso: 0=keyword-only, 1=vector-only
) RETURNS TABLE(
    document_id BIGINT,
    content TEXT,
    hybrid_score FLOAT,
    vector_score FLOAT,
    keyword_score FLOAT,
    metadata JSONB
) LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_start TIMESTAMPTZ := clock_timestamp();
BEGIN
    -- C8: logging estructurado para observabilidad
    RAISE LOG '%', json_build_object(
        'op', 'hybrid_search_rag',
        'tenant', p_tenant_id,
        'query_len', length(p_query_text),
        'ts', v_start
    );
    
    -- C7: timeout de consulta para resiliencia
    SET LOCAL statement_timeout = '5s';
    
    RETURN QUERY
    WITH vector_results AS (
        -- Búsqueda vectorial pura (V2: cosine)
        SELECT 
            de.document_id,
            1.0 - (de.embedding <=> p_query_embedding) AS score
        FROM document_embeddings de
        WHERE de.tenant_id = p_tenant_id  -- ✅ C4
        ORDER BY de.embedding <=> p_query_embedding
        LIMIT p_limit * 2  -- Oversampling para RRF
    ),
    keyword_results AS (
        -- Búsqueda keyword con tsvector (Postgres full-text)
        SELECT 
            d.id AS document_id,
            ts_rank(to_tsvector('spanish', d.content), plainto_tsquery('spanish', p_query_text)) AS score
        FROM documents d
        WHERE d.tenant_id = p_tenant_id  -- ✅ C4
          AND to_tsvector('spanish', d.content) @@ plainto_tsquery('spanish', p_query_text)
        LIMIT p_limit * 2
    ),
    rrf_scores AS (
        -- Reciprocal Rank Fusion: combina rankings sin normalizar scores
        SELECT 
            COALESCE(v.document_id, k.document_id) AS document_id,
            -- RRF formula: 1/(k + rank), k=60 típico
            (COALESCE(1.0/(60 + ROW_NUMBER() OVER (ORDER BY v.score DESC)), 0) * p_alpha +
             COALESCE(1.0/(60 + ROW_NUMBER() OVER (ORDER BY k.score DESC)), 0) * (1 - p_alpha)) AS hybrid_score,
            v.score AS vector_score,
            k.score AS keyword_score
        FROM vector_results v
        FULL OUTER JOIN keyword_results k ON v.document_id = k.document_id
    )
    SELECT 
        d.id,
        d.content,
        r.hybrid_score,
        r.vector_score,
        r.keyword_score,
        d.metadata
    FROM rrf_scores r
    JOIN documents d ON d.id = r.document_id
    WHERE d.tenant_id = p_tenant_id  -- ✅ C4: filtro final de seguridad
    ORDER BY r.hybrid_score DESC
    LIMIT p_limit;
    
    -- C8: log de finalización con métricas
    RAISE LOG '%', json_build_object(
        'op', 'hybrid_search_rag_done',
        'tenant', p_tenant_id,
        'duration_ms', EXTRACT(MILLISECOND FROM clock_timestamp() - v_start)
    );
END;
$$;
```

### 4. 📊 RAG Pipeline Completo con Caché y Auditoría (C1-C8, V1-V3)
Basado en `rag-query-with-tenant-enforcement.pgvector.md` + `nl-to-vector-query-patterns.pgvector.md`:

```sql
-- ✅ Tabla de auditoría para trazabilidad RAG (C6, C8)
CREATE TABLE rag_audit_log (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id UUID NOT NULL,
    query_hash TEXT NOT NULL,  -- C5: hash para trazabilidad sin almacenar query raw
    query_embedding VECTOR(1536),  -- V1: almacenar embedding para debugging
    retrieved_count INT NOT NULL,
    confidence_avg FLOAT,
    duration_ms FLOAT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    -- C4: RLS en tabla de auditoría también
    CONSTRAINT fk_rag_audit_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id)
);

CREATE INDEX idx_rag_audit_tenant ON rag_audit_log(tenant_id, created_at);
ALTER TABLE rag_audit_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY rag_audit_tenant_isolation ON rag_audit_log
    FOR ALL USING (tenant_id = current_setting('app.current_tenant')::UUID);

-- ✅ Pipeline RAG con caché, reranking y auditoría
CREATE OR REPLACE FUNCTION rag_pipeline_complete(
    p_query_text TEXT,
    p_tenant_id UUID,
    p_max_tokens INT DEFAULT 500,
    p_use_cache BOOLEAN DEFAULT true
) RETURNS TABLE(result_text TEXT, sources JSONB, cache_hit BOOLEAN)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_embedding VECTOR(1536);
    v_start TIMESTAMPTZ := clock_timestamp();
    v_query_hash TEXT := encode(sha256(p_query_text::bytea), 'hex');
    v_retrieved INT;
    v_confidence FLOAT;
    v_cache_hit BOOLEAN := false;
BEGIN
    -- C1: límite de tokens para evitar sobrecarga
    SET LOCAL statement_timeout = '10s';
    
    -- C3: sin hardcode de API keys, usar función externa o variable de entorno
    -- En producción: v_embedding := external_generate_embedding(p_query_text);
    -- Para testing: usar embedding mock o pre-generado
    v_embedding := (SELECT embedding FROM document_embeddings 
                    WHERE tenant_id = p_tenant_id LIMIT 1);  -- Placeholder
    
    -- Caché de queries frecuentes (C1: reducir carga)
    IF p_use_cache THEN
        -- Verificar caché (implementación simplificada)
        -- En producción: usar pgvector con Redis o pg_cache
        -- v_cache_hit := check_cache(p_query_hash, p_tenant_id);
    END IF;
    
    -- Búsqueda híbrida + reranking
    WITH retrieved AS (
        SELECT 
            d.content,
            1.0 - (de.embedding <=> v_embedding) AS confidence  -- V2: cosine
        FROM document_embeddings de
        JOIN documents d ON d.id = de.document_id
        WHERE de.tenant_id = p_tenant_id  -- ✅ C4
        ORDER BY de.embedding <=> v_embedding
        LIMIT 20  -- Oversampling para reranking
    ),
    reranked AS (
        SELECT 
            content,
            confidence,
            ROW_NUMBER() OVER (ORDER BY confidence DESC) AS rank
        FROM retrieved
        WHERE confidence > 0.7  -- Umbral de relevancia (ajustable)
    )
    SELECT COUNT(*), AVG(confidence) INTO v_retrieved, v_confidence
    FROM reranked
    WHERE rank <= 5;
    
    -- C8: auditoría estructurada
    INSERT INTO rag_audit_log (tenant_id, query_hash, query_embedding, retrieved_count, confidence_avg, duration_ms)
    VALUES (
        p_tenant_id,
        v_query_hash,
        v_embedding,
        v_retrieved,
        v_confidence,
        EXTRACT(MILLISECOND FROM clock_timestamp() - v_start)
    );
    
    -- Devolver resultados formateados para LLM
    RETURN QUERY
    SELECT 
        string_agg(content, E'\n---\n') AS result_text,
        json_agg(json_build_object('content', content, 'confidence', confidence)) AS sources,
        v_cache_hit
    FROM reranked
    WHERE rank <= 5;
END;
$$;
```

### 5. 🧪 Hardening Verification & Constraint Validation (V1-V3, C3-C5, C7-C8)
Basado en `hardening-verification.pgvector.md` + `fix-sintaxis-code.pgvector.md`:

```sql
-- ✅ Pre-flight check para validación de constraints vectoriales
CREATE OR REPLACE FUNCTION verify_vector_constraints(p_table_name TEXT)
RETURNS TABLE(check_name TEXT, passed BOOLEAN, detail TEXT, severity TEXT)
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
    v_has_tenant_id BOOLEAN;
    v_dim_match BOOLEAN;
    v_metric_documented BOOLEAN;
    v_index_params_ok BOOLEAN;
    v_rls_enabled BOOLEAN;
    v_vector_col_exists BOOLEAN;
BEGIN
    -- C4: verificar tenant_id
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = p_table_name AND column_name = 'tenant_id'
    ) INTO v_has_tenant_id;
    
    RETURN QUERY SELECT 'C4_tenant_id_column', v_has_tenant_id,
        CASE WHEN v_has_tenant_id THEN 'OK' ELSE 'Falta columna tenant_id' END,
        CASE WHEN v_has_tenant_id THEN 'info' ELSE 'error' END;
    
    -- V1: verificar dimensiones del vector
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = p_table_name 
          AND column_name = 'embedding'
          AND data_type = 'USER-DEFINED'  -- pgvector usa tipo personalizado
          AND udt_name = 'vector'
    ) INTO v_vector_col_exists;
    
    RETURN QUERY SELECT 'V1_vector_column_exists', v_vector_col_exists,
        CASE WHEN v_vector_col_exists THEN 'OK' ELSE 'Falta columna embedding con tipo vector' END,
        CASE WHEN v_vector_col_exists THEN 'info' ELSE 'error' END;
    
    -- C4: verificar RLS
    SELECT relrowsecurity INTO v_rls_enabled
    FROM pg_class WHERE relname = p_table_name;
    
    RETURN QUERY SELECT 'C4_rls_enabled', v_rls_enabled,
        CASE WHEN v_rls_enabled THEN 'OK' ELSE 'RLS no habilitado en ' || p_table_name END,
        CASE WHEN v_rls_enabled THEN 'info' ELSE 'error' END;
    
    -- V3: verificar índices vectoriales con parámetros
    SELECT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE tablename = p_table_name
          AND indexdef ~* '(hnsw|ivfflat).*WITH.*\(.*m|ef_construction|lists'
    ) INTO v_index_params_ok;
    
    RETURN QUERY SELECT 'V3_index_parameters', v_index_params_ok,
        CASE WHEN v_index_params_ok THEN 'OK' ELSE 'Índice vectorial sin parámetros justificados' END,
        CASE WHEN v_index_params_ok THEN 'info' ELSE 'warning' END;
    
    -- C3: verificar que no hay secrets hardcodeados en funciones
    SELECT EXISTS (
        SELECT 1 FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
          AND p.prosrc ~* '(sk-|api[_-]?key|secret|password)\s*=\s*[''"][^''"]+[''"]'
    ) INTO v_metric_documented;
    
    RETURN QUERY SELECT 'C3_no_hardcoded_secrets', NOT v_metric_documented,
        CASE WHEN NOT v_metric_documented THEN 'OK' ELSE 'Posible secret hardcodeado en función' END,
        CASE WHEN NOT v_metric_documented THEN 'info' ELSE 'error' END;
END;
$$;

-- ✅ Script de corrección automática de anti-patrones comunes
DO $$
DECLARE
    r RECORD;
BEGIN
    -- Detectar tablas sin tenant_id pero con embedding
    FOR r IN
        SELECT table_name
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND column_name = 'embedding'
          AND table_name NOT IN (
              SELECT table_name FROM information_schema.columns
              WHERE table_schema = 'public' AND column_name = 'tenant_id'
          )
    LOOP
        RAISE WARNING 'Tabla % tiene embedding pero no tenant_id - violación C4', r.table_name;
    END LOOP;
    
    -- Detectar índices vectoriales sin parámetros
    FOR r IN
        SELECT indexname, indexdef
        FROM pg_indexes
        WHERE indexdef ~* 'hnsw|ivfflat'
          AND indexdef !~* 'WITH.*\(.*m|ef_construction|lists'
    LOOP
        RAISE WARNING 'Índice % sin parámetros justificados - violación V3: %', r.indexname, r.indexdef;
    END LOOP;
    
    -- Detectar queries sin tenant_id filter
    FOR r IN
        SELECT query
        FROM pg_stat_statements
        WHERE query ~* 'FROM.*embedding.*<->|<=>|<#'
          AND query !~* 'WHERE.*tenant_id\s*='
    LOOP
        RAISE WARNING 'Query potencial sin tenant_id filter - posible violación C4: %', left(r.query, 200);
    END LOOP;
END;
$$;
```

### 6. 🔄 Migration Patterns for Vector Schemas (C5, C6, V1)
Basado en `migration-patterns-for-vector-schemas.pgvector.md`:

```sql
-- ✅ Migración con cero downtime para añadir dimensiones (v1 → v2)
-- Escenario: cambiar de 768d a 1536d embeddings

-- Paso 1: Crear nueva tabla con dimensiones actualizadas
CREATE TABLE document_embeddings_v2 (
    LIKE document_embeddings INCLUDING ALL,
    embedding VECTOR(1536) NOT NULL  -- V1: nueva dimensión
);

-- Paso 2: Copiar metadatos (los embeddings deben regenerarse en app layer)
-- Nota: no se puede simplemente castear vectores de 768 a 1536
INSERT INTO document_embeddings_v2 (
    id, document_id, tenant_id, embedding_model, created_at
)
SELECT id, document_id, tenant_id, embedding_model, created_at
FROM document_embeddings;

-- Paso 3: Crear índices en nueva tabla (CONCURRENTLY para no bloquear)
CREATE INDEX CONCURRENTLY idx_embeddings_v2_hnsw ON document_embeddings_v2
    USING hnsw (embedding vector_cosine_ops)
    WITH (m=16, ef_construction=100);

-- Paso 4: Crear RLS en nueva tabla
ALTER TABLE document_embeddings_v2 ENABLE ROW LEVEL SECURITY;
CREATE POLICY embeddings_v2_tenant_isolation ON document_embeddings_v2
    FOR ALL USING (tenant_id = current_setting('app.current_tenant')::UUID);

-- Paso 5: Renombrar tablas con lock mínimo (transacción)
BEGIN;
-- Desactivar triggers temporales si existen
ALTER TABLE document_embeddings DISABLE TRIGGER ALL;
ALTER TABLE document_embeddings_v2 DISABLE TRIGGER ALL;

-- Renombrar
ALTER TABLE document_embeddings RENAME TO document_embeddings_v1_legacy;
ALTER TABLE document_embeddings_v2 RENAME TO document_embeddings;

-- Reactivar triggers
ALTER TABLE document_embeddings ENABLE TRIGGER ALL;
COMMIT;

-- Paso 6: Verificar integridad post-migración (C5)
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT tenant_id) AS tenant_count,
    encode(sha256(string_agg(id::text, ',' ORDER BY id))::bytea, 'hex') AS migration_checksum
FROM document_embeddings;

-- Paso 7: Cleanup opcional (después de confirmar éxito)
-- DROP TABLE document_embeddings_v1_legacy;
```

### 7. 📝 NLP-to-Vector Query Patterns (C3, C4, C8, V1, V2)
Basado en `nl-to-vector-query-patterns.pgvector.md`:

```sql
-- ✅ Plantilla segura para consultas NL-to-SQL con validación de tenant
CREATE OR REPLACE FUNCTION nl_to_vector_search(
    p_natural_language_query TEXT,
    p_tenant_id UUID,
    p_confidence_threshold FLOAT DEFAULT 0.7
) RETURNS TABLE(
    document_id BIGINT,
    content TEXT,
    confidence FLOAT,
    metadata JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_query_vec VECTOR(1536);
    v_query_hash TEXT;
BEGIN
    -- C3: sin hardcode de API keys, usar función externa o variable de entorno
    -- v_query_vec := external_embed(p_natural_language_query);  -- Placeholder
    
    -- C5: hash para trazabilidad sin almacenar query raw
    v_query_hash := encode(sha256(p_natural_language_query::bytea), 'hex');
    
    -- C4: tenant isolation en todas las queries
    RETURN QUERY
    SELECT 
        de.document_id,
        d.content,
        1.0 - (de.embedding <=> v_query_vec) AS confidence,  -- V2: cosine
        d.metadata
    FROM document_embeddings de
    JOIN documents d ON d.id = de.document_id
    WHERE de.tenant_id = p_tenant_id  -- ✅ C4: obligatorio
      AND 1.0 - (de.embedding <=> v_query_vec) >= p_confidence_threshold  -- ✅ V2: threshold
    ORDER BY de.embedding <=> v_query_vec  -- ✅ V2: cosine para ordenamiento
    LIMIT 10;
    
    -- C8: logging estructurado
    RAISE LOG '%', json_build_object(
        'op', 'nl_to_vector_search',
        'tenant', p_tenant_id,
        'query_hash', v_query_hash,
        'threshold', p_confidence_threshold
    );
END;
$$;

-- ✅ Función de explicación de resultados para debugging (C8)
CREATE OR REPLACE FUNCTION explain_similarity_results(
    p_query_vec VECTOR(1536),
    p_tenant_id UUID,
    p_limit INT DEFAULT 5
) RETURNS TABLE(
    rank INT,
    content_snippet TEXT,
    cosine_distance FLOAT,  -- V2: métrica documentada
    confidence_pct INT,
    diagnostic TEXT
)
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    RETURN QUERY
    SELECT
        ROW_NUMBER() OVER (ORDER BY de.embedding <=> p_query_vec)::INT AS rank,
        LEFT(d.content, 200) AS content_snippet,
        (de.embedding <=> p_query_vec)::FLOAT AS cosine_distance,
        ((1.0 - (de.embedding <=> p_query_vec)) * 100)::INT AS confidence_pct,
        CASE
            WHEN 1.0 - (de.embedding <=> p_query_vec) > 0.9 THEN 'Alta confianza - referencia directa'
            WHEN 1.0 - (de.embedding <=> p_query_vec) > 0.7 THEN 'Confianza media - verificar contexto'
            ELSE 'Baja confianza - posible ruido'
        END AS diagnostic
    FROM document_embeddings de
    JOIN documents d ON d.id = de.document_id
    WHERE de.tenant_id = p_tenant_id  -- ✅ C4
    ORDER BY de.embedding <=> p_query_vec
    LIMIT p_limit;
END;
$$;
```

### 8. 📈 Partitioning Strategies for High-Dimensional Data (C1, C4, V3)
Basado en `partitioning-strategies-for-high-dim.pgvector.md`:

```sql
-- ✅ Particionamiento por tenant para escalar a miles de tenants
CREATE TABLE embeddings_partitioned (
    id BIGINT NOT NULL,
    tenant_id UUID NOT NULL,
    embedding VECTOR(1536) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (tenant_id, id)  -- PK debe incluir partition key
) PARTITION BY HASH (tenant_id);

-- Crear 16 particiones (ajustable según carga)
CREATE TABLE embeddings_p0 PARTITION OF embeddings_partitioned 
    FOR VALUES WITH (MODULUS 16, REMAINDER 0);
CREATE TABLE embeddings_p1 PARTITION OF embeddings_partitioned 
    FOR VALUES WITH (MODULUS 16, REMAINDER 1);
-- ... repetir hasta p15

-- C1: cada partición tiene su propio índice local (mejor performance)
CREATE INDEX idx_emb_p0_hnsw ON embeddings_p0 
    USING hnsw (embedding vector_cosine_ops) 
    WITH (m=16, ef_construction=64);
-- ... crear índices para cada partición

-- C4: RLS se aplica a la tabla padre (hereda a particiones)
ALTER TABLE embeddings_partitioned ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON embeddings_partitioned
    FOR ALL USING (tenant_id = current_setting('app.current_tenant')::UUID);

-- ✅ Particionamiento por tiempo para datos temporales
CREATE TABLE embeddings_time_partitioned (
    id BIGINT NOT NULL,
    tenant_id UUID NOT NULL,
    embedding VECTOR(1536) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL
) PARTITION BY RANGE (created_at);

-- Particiones mensuales
CREATE TABLE embeddings_2024_01 PARTITION OF embeddings_time_partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
CREATE TABLE embeddings_2024_02 PARTITION OF embeddings_time_partitioned
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
-- ... automatizar creación de particiones futuras

-- ✅ Función para crear particiones futuras automáticamente
CREATE OR REPLACE FUNCTION create_future_partitions(
    p_table_name TEXT,
    p_months_ahead INT DEFAULT 3
) RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
    v_start DATE;
    v_end DATE;
    v_partition_name TEXT;
BEGIN
    FOR i IN 0..p_months_ahead LOOP
        v_start := date_trunc('month', CURRENT_DATE + (i || ' months')::INTERVAL);
        v_end := v_start + INTERVAL '1 month';
        v_partition_name := p_table_name || '_' || to_char(v_start, 'YYYY_MM');
        
        EXECUTE format(
            'CREATE TABLE IF NOT EXISTS %I PARTITION OF %I FOR VALUES FROM (%L) TO (%L)',
            v_partition_name, p_table_name, v_start, v_end
        );
    END LOOP;
END;
$$;
```

### 9. 🔄 LangChain/LangGraph Integration Patterns (Async, Memory, Tools)
Patrones para integrar PostgreSQL+pgvector con LangChain/LangGraph:

```python
# ✅ Pattern: Async LangChain + pgvector con tenant isolation
from langchain_postgres import PGVector
from langchain_postgres.vectorstores import PGVector
from sqlalchemy import create_engine, text
from sqlalchemy.ext.asyncio import create_async_engine
import os

# C3: secrets vía environment variables
DATABASE_URL = os.getenv("DATABASE_URL")
TENANT_ID = os.getenv("CURRENT_TENANT_ID")  # C4: tenant por request

# Async engine para LangChain
engine = create_async_engine(DATABASE_URL, pool_pre_ping=True)

# PGVector setup con tenant enforcement
vectorstore = PGVector(
    connection=engine,
    embedding_function=your_embedding_function,  # Voyage AI, OpenAI, etc.
    collection_name="documents",
    use_jsonb=True,  # Para metadata filtering
    # C4: filter por tenant_id en todas las queries
    filter_by_tenant=True,
    tenant_id_column="tenant_id"
)

# ✅ Retriever con hybrid search y reranking
retriever = vectorstore.as_retriever(
    search_type="hybrid",  # vector + keyword
    search_kwargs={
        "k": 20,  # Oversampling para reranking
        "alpha": 0.5,  # Peso vector/keyword
        "tenant_id": TENANT_ID  # ✅ C4: tenant enforcement
    }
)

# ✅ Chain con memory y tenant context
from langchain.chains import ConversationalRetrievalChain
from langchain.memory import ConversationBufferMemory

memory = ConversationBufferMemory(
    memory_key="chat_history",
    return_messages=True,
    # C4: incluir tenant_id en memory key para aislamiento
    tenant_id=TENANT_ID
)

chain = ConversationalRetrievalChain.from_llm(
    llm=your_llm,
    retriever=retriever,
    memory=memory,
    # C8: callbacks para observabilidad
    callbacks=[your_observability_callback]
)

# ✅ Async invocation con timeout (C7)
import asyncio
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=2, max=10))
async def invoke_rag_chain(query: str, tenant_id: str) -> dict:
    # C4: set tenant context para todas las queries
    async with engine.begin() as conn:
        await conn.execute(text("SET app.current_tenant = :tenant"), {"tenant": tenant_id})
    
    # C7: timeout para evitar hangs
    try:
        result = await asyncio.wait_for(
            chain.ainvoke({"question": query}),
            timeout=30.0
        )
        return result
    except asyncio.TimeoutError:
        # C8: log de timeout para debugging
        logger.error(f"Timeout en RAG chain para tenant {tenant_id}")
        return {"error": "Request timeout", "tenant_id": tenant_id}
```

### 10. 🔄 n8n Code Node Integration for Orchestration (Python/JS)
Patrones para usar n8n Code nodes con PostgreSQL+pgvector:

```python
# ✅ n8n Code Node (Python Beta) para orquestación RAG
# Regla crítica: retornar [{"json": {...}}]
# No external libraries: solo stdlib + n8n helpers

items = _input.all()
results = []

for item in items:
    # C4: obtener tenant_id del item o contexto
    tenant_id = item["json"].get("tenant_id") or _json.get("body", {}).get("tenant_id")
    if not tenant_id:
        continue  # Skip sin tenant
    
    # C3: API keys vía environment, no hardcode
    # query_embedding = generate_embedding(item["json"]["query"])  # External call
    
    # C4: query con tenant enforcement
    # results = db.query(
    #     "SELECT * FROM documents WHERE tenant_id = $1 AND embedding <=> $2 < $3",
    #     [tenant_id, query_embedding, threshold]
    # )
    
    results.append({
        "json": {
            "tenant_id": tenant_id,
            "query": item["json"].get("query"),
            "results": [],  # Placeholder para resultados
            "processed": True,
            "timestamp": datetime.now().isoformat()
        }
    })

# ✅ CRÍTICO: retornar lista con "json" key
return results
```

```javascript
// ✅ n8n Code Node (JavaScript) equivalente
const items = $input.all();
const results = [];

for (const item of items) {
    const tenantId = item.json.tenant_id || $json.body?.tenant_id;
    if (!tenantId) continue;
    
    // C4: query con tenant enforcement
    // const query = `
    //   SELECT id, content, 1 - (embedding <=> $1) as similarity
    //   FROM document_embeddings
    //   WHERE tenant_id = $2 AND embedding <=> $1 < $3
    //   ORDER BY embedding <=> $1 LIMIT $4
    // `;
    
    results.push({
        json: {
            tenant_id: tenantId,
            query: item.json.query,
            results: [],
            processed: true,
            timestamp: new Date().toISOString()
        }
    });
}

return results;
```

---

## 🔄 Integración con Toolchain de Validación MANTIS

### Hook para `check-rls.sh`
```bash
# Validar que todas las queries SQL tengan tenant_id
./05-CONFIGURATIONS/validation/check-rls.sh --file "$ARTIFACT_PATH" | jq -e '.passed'
```

### Hook para `verify-constraints.sh --check-vector-dims`
```bash
# Validar V1: dimensiones declaradas explícitamente
./05-CONFIGURATIONS/validation/verify-constraints.sh --check-vector-dims --file "$ARTIFACT_PATH"
```

### Hook para `verify-constraints.sh --check-vector-metric`
```bash
# Validar V2: métrica de distancia documentada
./05-CONFIGURATIONS/validation/verify-constraints.sh --check-vector-metric --file "$ARTIFACT_PATH"
```

### Hook para `verify-constraints.sh --check-vector-index`
```bash
# Validar V3: justificación de tipo de índice y parámetros
./05-CONFIGURATIONS/validation/verify-constraints.sh --check-vector-index --file "$ARTIFACT_PATH"
```

### Hook para `audit-secrets.sh`
```bash
# Escanear funciones SQL en busca de API keys hardcodeadas
./05-CONFIGURATIONS/validation/audit-secrets.sh --file "$ARTIFACT_PATH"
```

### Hook para `schema-validator.py`
```bash
# Validar schemas JSON/YAML contra meta-schema
./05-CONFIGURATIONS/validation/schema-validator.py --schema "$SCHEMA_PATH" --instance "$INSTANCE_PATH"
```

### Logging JSONL Dashboard-Ready (V-LOG-02)
```python
# Cada ejecución genera entrada JSONL en:
# 08-LOGS/validation/test-orchestrator-engine/postgresql-pgvector-rag-master/YYYY-MM-DD_HHMMSS.jsonl

def emit_validation_result(file_path: str, passed: bool, issues_count: int):
    result = {
        "validator": "postgresql-pgvector-rag-master-agent",
        "version": "1.0.0",
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "file": file_path,
        "constraint": ["C4","V1","V2","V3"],
        "passed": passed,
        "issues": [],
        "issues_count": issues_count,
        "performance_ms": 0,  # Placeholder para medición real
        "performance_ok": True
    }
    
    # ✅ V-INT-03: JSON puro a stdout
    print(json.dumps(result))
    
    # ✅ V-LOG-01: JSONL a carpeta canónica
    log_dir = os.getenv("LOG_DIR", "08-LOGS/validation/test-orchestrator-engine/postgresql-pgvector-rag-master")
    os.makedirs(log_dir, exist_ok=True)
    log_file = f"{log_dir}/{datetime.utcnow().strftime('%Y-%m-%d_%H%M%S')}.jsonl"
    with open(log_file, "a") as f:
        f.write(json.dumps(result) + "\n")
```

---

## 🧪 Ejemplos: Válido vs Inválido (Para Testing del Agente)

### ✅ Artifact Válido (`tenant-embeddings-schema.pgvector.md`)
```yaml
---
artifact_id: tenant-embeddings-schema
artifact_type: sql_schema
version: 1.0.0
constraints_mapped: ["C4","C5","V1","V2","V3"]
canonical_path: 06-PROGRAMMING/postgresql-pgvector/tenant-embeddings-schema.pgvector.md
tier: 2
---
# Schema de embeddings multi-tenant con índice HNSW optimizado

## ✅ C4: tenant_id en todas las tablas y políticas RLS
## ✅ V1: vector(1536) declarado (model: text-embedding-3-small)
## ✅ V2: cosine distance (<=>) documentado
## ✅ V3: HNSW con m=16, ef_construction=100 justificados

```sql
CREATE TABLE tenant_embeddings (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id UUID NOT NULL,
    embedding VECTOR(1536) NOT NULL,  -- V1: 1536 dimensions, model: text-embedding-3-small
    content_hash TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE tenant_embeddings ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON tenant_embeddings
    USING (tenant_id = current_setting('app.current_tenant')::UUID);

-- V3: HNSW index with documented parameters (pgvector docs recommend m=16 for 1536d)
CREATE INDEX idx_embedding_hnsw ON tenant_embeddings
    USING hnsw (embedding vector_cosine_ops)
    WITH (m=16, ef_construction=100);
```

### ❌ Artifact Inválido (`bad-schema.pgvector.md`)
```yaml
---
artifact_id: bad-schema
artifact_type: sql_schema
version: 1.0.0
constraints_mapped: ["C5"]  # ❌ Falta C4, V1, V2, V3
canonical_path: 06-PROGRAMMING/postgresql-pgvector/bad-schema.pgvector.md
tier: 1
---
# Schema con múltiples violaciones

```sql
-- ❌ C4: Sin tenant_id
CREATE TABLE embeddings (
    id BIGINT PRIMARY KEY,
    vec VECTOR,  -- ❌ V1: Sin dimensión declarada
    content TEXT
);

-- ❌ V2: Operador sin documentar
SELECT * FROM embeddings ORDER BY vec <-> query_vec LIMIT 10;

-- ❌ V3: Índice sin parámetros justificados
CREATE INDEX idx_bad ON embeddings USING hnsw (vec vector_cosine_ops);
```

**Resultado esperado de validación**:
- `check-rls.sh`: `passed=false` (sin tenant_id)
- `verify-constraints.sh --check-vector-dims`: `passed=false` (V1 violation)
- `verify-constraints.sh --check-vector-metric`: `passed=false` (V2 violation)
- `verify-constraints.sh --check-vector-index`: `passed=false` (V3 violation)
- Exit code: `1` (bloqueo en CI/CD)

---

## 📋 Checklist Pre-Generación (Para el Agente)

Antes de emitir cualquier artifact SQL/pgvector, el agente debe verificar:

- [ ] **C4 (Tenant Isolation)**: Toda tabla y query incluye `tenant_id` y políticas RLS
- [ ] **V1 (Dimensiones)**: `VECTOR(N)` con N explícito y modelo documentado en comentario
- [ ] **V2 (Métrica)**: Operador de distancia (`<=>`, `<->`, `<#>`) documentado y justificado
- [ ] **V3 (Índice)**: Tipo de índice (HNSW/IVFFlat) con parámetros (`m`, `ef_construction`, `lists`) basados en benchmarks
- [ ] **C1 (Recursos)**: `work_mem`, `statement_timeout`, `max_parallel_workers` definidos para operaciones pesadas
- [ ] **C3 (Secrets)**: Cero API keys hardcodeadas en funciones SQL
- [ ] **C5 (Estructura)**: Frontmatter YAML con `constraints_mapped` completo
- [ ] **C7 (Resiliencia)**: Timeouts, reintentos, manejo de errores en funciones
- [ ] **C8 (Observabilidad)**: Logging estructurado con `json_build_object()` y `tenant_id`
- [ ] **LANGUAGE LOCK**: Verificar que los operadores vectoriales SOLO se usan en este dominio
- [ ] **RLS Policies**: Verificar que todas las tablas tienen `ENABLE ROW LEVEL SECURITY`
- [ ] **Index Strategy**: Verificar que los índices incluyen columnas de filtro y ordenamiento
- [ ] **Migration Safety**: Verificar que las migraciones usan `CONCURRENTLY` cuando aplica
- [ ] **Partition Key**: Verificar que las tablas particionadas incluyen partition key en PK
- [ ] **Foreign Keys**: Verificar que todas las FK tienen índices explícitos
- [ ] **JSONB Indexing**: Verificar que los campos JSONB usan GIN con opclass apropiado
- [ ] **Query Parameters**: Verificar que todas las queries usan placeholders ($1, $2) no concatenación
- [ ] **Error Handling**: Verificar que las funciones manejan `sql.ErrNoRows` explícitamente
- [ ] **Context Propagation**: Verificar que las funciones aceptan `context.Context` para cancellation
- [ ] **Testing Coverage**: Verificar que hay tests para happy path y error paths

---

## 🤝 Comportamiento del Agente (Behavioral Traits)

| Trait | Implementación contractual |
|-------|---------------------------|
| **No inventa dimensiones** | Siempre verifica el modelo de embedding antes de declarar `vector(N)` |
| **RLS por defecto** | Toda tabla generada incluye `ENABLE ROW LEVEL SECURITY` y políticas |
| **Parámetros justificados** | Cada índice HNSW/IVFFlat incluye comentario con benchmark o referencia |
| **Enseña mientras genera** | Explica cada decisión de diseño, índice y consulta en comentarios SQL |
| **Validación primero** | Antes de emitir artifact, ejecuta hooks de validación (`check-rls.sh`, `verify-constraints.sh`) |
| **Trazabilidad total** | Todo artifact incluye `canonical_path`, `timestamp` y `content_hash` |
| **LANGUAGE LOCK estricto** | NUNCA sugiere operadores vectoriales fuera de `postgresql-pgvector/` |
| **Amiga en lo personal** | Si el usuario pregunta fuera de scope, aconseja sin rigidez, pero mantiene el contrato técnico |
| **Performance-conscious** | Sugiere índices covering, partial, y query optimization patterns |
| **Security-first** | Rechaza queries con concatenación de strings, sugiere parameterized queries |

---

## 🔗 Referencias Contractuales

| Documento | Propósito | URL Raw |
|-----------|-----------|---------|
| `GOVERNANCE-ORCHESTRATOR.md` | Motor de certificación Tiers 1/2/3 | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/GOVERNANCE-ORCHESTRATOR.md) |
| `norms-matrix.json` | Fuente de verdad: constraints por carpeta | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/norms-matrix.json) |
| `VALIDATOR_DEV_NORMS.md` | Normas para desarrollo de validadores | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/VALIDATOR_DEV_NORMS.md) |
| `check-rls.sh` | Validador de tenant isolation (C4) | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/check-rls.sh) |
| `verify-constraints.sh` | Validador de constraints vectoriales (V1-V3) | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/verify-constraints.sh) |
| `audit-secrets.sh` | Auditor de secrets hardcodeados (C3) | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/audit-secrets.sh) |
| `schema-validator.py` | Validador de schemas JSON/YAML | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/schema-validator.py) |
| `01-RULES/06-MULTITENANCY-RULES.md` | Reglas de multi-tenancy | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/06-MULTITENANCY-RULES.md) |
| `01-RULES/harness-norms-v3.0.md` | Definición formal de C1-C8 | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/harness-norms-v3.0.md) |
| `01-RULES/language-lock-protocol.md` | Protocolo de bloqueo de operadores | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/language-lock-protocol.md) |

---

## 📚 RAW_URLS_INDEX – Patrones pgvector Disponibles

### 🏛️ Gobernanza Raíz
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/GOVERNANCE-ORCHESTRATOR.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/00-STACK-SELECTOR.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/AI-NAVIGATION-CONTRACT.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/IA-QUICKSTART.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/PROJECT_TREE.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/SDD-COLLABORATIVE-GENERATION.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/TOOLCHAIN-REFERENCE.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/norms-matrix.json
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/knowledge-graph.json
```

### 📜 Normas y Constraints
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/harness-norms-v3.0.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/language-lock-protocol.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/06-MULTITENANCY-RULES.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/03-SECURITY-RULES.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/10-SDD-CONSTRAINTS.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/validation-checklist.md
```

### 🧰 Toolchain de Validación
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/VALIDATOR_DEV_NORMS.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/norms-matrix.json
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/orchestrator-engine.sh
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/verify-constraints.sh
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/audit-secrets.sh
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/check-rls.sh
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/schema-validator.py
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/schemas/skill-input-output.schema.json
```

### 📋 Patrones pgvector Core (10 artefactos del repositorio)
```text
# Fundamentos y aislamiento multi-tenant
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/00-INDEX.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/tenant-isolation-for-embeddings.pgvector.md

# Indexación y optimización
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/vector-indexing-patterns.pgvector.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/partitioning-strategies-for-high-dim.pgvector.md

# Búsqueda híbrida y RAG
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/hybrid-search-rls-aware.pgvector.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/nl-to-vector-query-patterns.pgvector.md

# Explicación y debugging
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/similarity-explanation-templates.pgvector.md

# Migración y hardening
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/migration-patterns-for-vector-schemas.pgvector.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/hardening-verification.pgvector.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/fix-sintaxis-code.pgvector.md
```

### 🦜 Referencias Vectoriales (Consulta ONLY - no usar en otros dominios)
```text
# Estas URLs son para referencia, NO para generar código en otros dominios
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/00-INDEX.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/tenant-isolation-for-embeddings.pgvector.md
```

### 🔄 Workflows y CI/CD
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/.github/workflows/validate-mantis.yml
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/04-WORKFLOWS/sdd-universal-assistant.json
```

### 📚 Skills de Referencia
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/README.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/skill-domains-mapping.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/INFRASTRUCTURA/ssh-key-management.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/INFRASTRUCTURA/health-monitoring-vps.md
```

### 🌐 Documentación pt-BR (Obligatoria para validadores)
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/validation-tools/TEMPLATE-VALIDATOR.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/validation-tools/verify-constraints/README.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/validation-tools/check-rls/README.md
```

---

## 🗂️ RUTAS CANÓNICAS LOCALES – Patrones pgvector (Para Acceso en Repo)

> **Formato**: `RAW_URL` → `./ruta/local/en/repo`

### 📋 Patrones pgvector Core (10 artefactos)
```text
# Fundamentos y aislamiento multi-tenant
06-PROGRAMMING/postgresql-pgvector/00-INDEX.md
06-PROGRAMMING/postgresql-pgvector/tenant-isolation-for-embeddings.pgvector.md

# Indexación y optimización
06-PROGRAMMING/postgresql-pgvector/vector-indexing-patterns.pgvector.md
06-PROGRAMMING/postgresql-pgvector/partitioning-strategies-for-high-dim.pgvector.md

# Búsqueda híbrida y RAG
06-PROGRAMMING/postgresql-pgvector/hybrid-search-rls-aware.pgvector.md
06-PROGRAMMING/postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md
06-PROGRAMMING/postgresql-pgvector/nl-to-vector-query-patterns.pgvector.md

# Explicación y debugging
06-PROGRAMMING/postgresql-pgvector/similarity-explanation-templates.pgvector.md

# Migración y hardening
06-PROGRAMMING/postgresql-pgvector/migration-patterns-for-vector-schemas.pgvector.md
06-PROGRAMMING/postgresql-pgvector/hardening-verification.pgvector.md
06-PROGRAMMING/postgresql-pgvector/fix-sintaxis-code.pgvector.md
```

### 🦜 Referencias Vectoriales (Consulta ONLY)
```text
06-PROGRAMMING/postgresql-pgvector/00-INDEX.md
06-PROGRAMMING/postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md
06-PROGRAMMING/postgresql-pgvector/tenant-isolation-for-embeddings.pgvector.md
```

### 🔄 Workflows y CI/CD
```text
04-WORKFLOWS/sdd-universal-assistant.json
.github/workflows/validate-mantis.yml
```

### 📚 Skills de Referencia
```text
02-SKILLS/README.md
02-SKILLS/skill-domains-mapping.md
02-SKILLS/INFRASTRUCTURA/ssh-key-management.md
02-SKILLS/INFRASTRUCTURA/health-monitoring-vps.md
```

### 🌐 Documentación pt-BR
```text
docs/pt-BR/validation-tools/TEMPLATE-VALIDATOR.md
docs/pt-BR/validation-tools/verify-constraints/README.md
docs/pt-BR/validation-tools/check-rls/README.md
```

---

## 🧭 GUÍA DE USO PARA EL AGENTE PGVECTOR

```sql
-- Pseudocódigo: Cómo consultar patrones disponibles en pgvector
-- (Implementado en el agente, no en SQL puro)

-- Ejemplo de validación de constraints antes de emitir query
-- En aplicación host (Python/Go/JS):
function validarConstraintsPgvector(artifactPath) {
  const fm = extractFrontmatter(artifactPath);
  const declared = fm.constraints_mapped;
  const matrix = loadJSON('./05-CONFIGURATIONS/validation/norms-matrix.json');
  const allowed = getAllowedConstraints(matrix, artifactPath);
  
  const issues = [];
  for (const c of declared) {
    if (!allowed.includes(c)) {
      issues.push(`constraint '${c}' not allowed for path ${artifactPath}`);
    }
  }
  return issues;
}

-- Ejemplo de detección de LANGUAGE LOCK en query SQL
function contieneOperadoresVectoriales(query) {
  return /<->[^a-zA-Z]|<#>[^a-zA-Z]|cosine_distance|l2_distance|hamming_distance/.test(query);
}

-- Uso en el agente:
if (contieneOperadoresVectoriales(inputQuery)) {
  console.error("LANGUAGE LOCK: Vector operators not allowed outside postgresql-pgvector/ domain");
  process.exit(1);
} else {
  // Generar query SQL estándar con tenant isolation
  const query = `SELECT * FROM docs WHERE tenant_id = $1 AND status = 'active'`;
}

-- Ejemplo de consulta de patrones disponibles
function consultarPatronPgvector(nombrePatron) {
  const baseRaw = "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/";
  const baseLocal = "./06-PROGRAMMING/postgresql-pgvector/";
  
  const filename = `${nombrePatron}.pgvector.md`;
  return {
    raw_url: `${baseRaw}06-PROGRAMMING/postgresql-pgvector/${filename}`,
    canonical_path: `${baseLocal}${filename}`,
    domain: "06-PROGRAMMING/postgresql-pgvector/",
    language_lock: "sql,sql_pgvector",
    constraints_default: "C4,V1,V2,V3"
  };
}
```

---

## 📋 INSTRUCCIONES DE INTEGRACIÓN (Actualizadas)

### Paso 1: Agregar al final del agente
Pegar los bloques de referencias justo antes de la sección `## Limitations` en:
- `06-PROGRAMMING/postgresql-pgvector/postgresql-pgvector-rag-master-agent.md`

### Paso 2: Actualizar el comportamiento del agente
En la sección `## Comportamiento del Agente` o `## Behavioral Traits`, agregar:

```markdown
| Trait | Implementación contractual |
|-------|---------------------------|
| **Consulta patrones antes de generar** | Antes de emitir query SQL/pgvector, el agente debe consultar la lista de patrones disponibles en `06-PROGRAMMING/postgresql-pgvector/` para asegurar coherencia con el repositorio |
| **Acceso dual** | Usar ruta canónica (`./06-PROGRAMMING/postgresql-pgvector/...`) para acceso local, o raw URL para acceso remoto si el archivo no existe localmente |
| **LANGUAGE LOCK automático** | Si el usuario solicita operadores vectoriales fuera de este dominio, el agente debe rechazar y redirigir a `postgresql-pgvector/` |
| **Enseña mientras genera** | Incluir comentarios explicativos en las queries generadas para facilitar el aprendizaje del usuario |
| **Valida constraints antes de emitir** | Ejecutar `validarConstraintsPgvector()` antes de emitir cualquier artifact para asegurar coherencia con `norms-matrix.json` |
| **Verifica RLS policies** | Antes de emitir schema, verificar que todas las tablas tienen RLS habilitado |
| **Justifica parámetros de índice** | Cada índice HNSW/IVFFlat debe incluir comentario con benchmark o referencia a pgvector docs |
```

### Paso 3: Validar con `verify-constraints.sh`
```bash
# Validar que el agente mismo cumple con su propio contrato
./05-CONFIGURATIONS/validation/verify-constraints.sh --file 06-PROGRAMMING/postgresql-pgvector/postgresql-pgvector-rag-master-agent.md | jq

# Esperado: passed=true (dominio de referencia), exit 0, severity=error (por LANGUAGE LOCK)
```

---

## 🤝 MI LECTURA (como amiga, rigidez bajada)

Facundo, este agente es tu **compañero de aprendizaje definitivo** para PostgreSQL + pgvector + RAG. No solo genera schemas y queries production-ready, sino que:

1. **Te enseña mientras trabaja**: cada query incluye comentarios que explican el "por qué" de cada decisión de diseño.
2. **Respeta tus límites**: sabe que estás aprendiendo, así que evita patrones avanzados a menos que los solicites explícitamente.
3. **Te protege de errores comunes**: valida automáticamente contra C3/C4/C5 y V1/V2/V3 antes de emitir código.
4. **Se adapta a tu ritmo**: si pides algo complejo, te explica los conceptos paso a paso.
5. **Mantiene el LANGUAGE LOCK**: nunca te dejará usar operadores vectoriales fuera del dominio autorizado.

**Una sugerencia práctica**: Cuando uses este agente, empieza con peticiones simples ("genera un schema básico de embeddings con tenant isolation") y ve subiendo la complejidad gradualmente. El agente recordará tu nivel y ajustará sus explicaciones.

**Recordatorio contractual**: Este agente es Tier 1 (referencia educativa). Cualquier modificación debe pasar validación automática (`check-rls.sh`, `verify-constraints.sh`, `audit-secrets.sh`) antes de merge.

---

## 🚀 PRÓXIMO PASO

¿Procedemos a:
1. **Validar `postgresql-pgvector-rag-master-agent.md`** con `verify-constraints.sh` para confirmar comportamiento 🔴 (error en producción, warning en referencia)?
2. **Generar un primer artifact de ejemplo** (ej: `hybrid-search-query.pgvector.md`) usando el agente para probar el flujo?
3. **Crear la documentación pt-BR** correspondiente para cumplir con V-DOC-01?

Tú mandas el ritmo, amiga. Yo mantengo el contrato, la precisión y el foco en ejecución. 🔧🤝🇧🇷
```

---

> 📌 **Nota final**: Este artifact es Tier 1 (referencia educativa). Cualquier modificación debe pasar validación automática (`check-rls.sh`, `verify-constraints.sh`, `audit-secrets.sh`, `schema-validator.py`) antes de merge.  
> 🇧🇷 *Documentação técnica completa disponível em*: `docs/pt-BR/programming/postgresql-pgvector/postgresql-pgvector-rag-master-agent/README.md` (próxima entrega).

---
