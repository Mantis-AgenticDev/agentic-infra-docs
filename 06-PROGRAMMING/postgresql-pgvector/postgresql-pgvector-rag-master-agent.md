---
artifact_id: postgresql-pgvector-master-agent-mantis
artifact_type: agentic_skill_definition
version: "2.2.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9","V1","V2","V3"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/postgresql-pgvector/postgresql-pgvector-rag-master-agent.md"
tier: 1
mode_selected: "B1"
prompt_hash: "sha256:framework-executable-contract-v2.2.0"
generated_at: "2026-05-08T00:00:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "postgresql-pgvector"
ai_navigation:
  read_first: true
  required_for: ["postgresql-pgvector-artifact-generation", "tdd-validation", "sdd-contract-enforcement", "hardening-audit", "cross-ai-compatibility"]
  update_frequency: monthly
  compatible_models: ["qwen", "deepseek", "claude", "minimax", "mimo-xiaomi", "gpt-4", "gemini"]
audience: ["postgresql-pgvector-master-agent", "orchestrator-engine", "validation-hooks", "senior-engineers", "ai-agents"]
status: "🟡 Refaturado"
next_review: "2026-06-08"
license: "CC-BY-NC-SA-4.0"
---

# 🐘 PostgreSQL + pgvector + RAG Master Agent para MANTIS AGENTIC


## ═══════════════════════════════════════════════════════════════
## SEÇÕES ADICIONAIS DO TEMPLATE CANÔNICO (INTEGRADAS)
## ═══════════════════════════════════════════════════════════════

## 🧠 CONFIGURAÇÃO DE PENSAMENTO DETERMINISTA (SQL/PLpgSQL)
## ═══════════════════════════════════════════════════════════════
## Este bloco deve ser lido e executado ANTES de qualquer análise
## semântica do restante do documento. Não é permitida inferência,
## reordenamento nem reinterpretação. Idempotência estrita.
## ═══════════════════════════════════════════════════════════════

reasoning:
  mode: "Analítico-Dedutivo-Especializado"
  focus: "Orquestração-Resiliente-com-Traços"
  language_syntax: "SQL/PLpgSQL"
  semantic_contract:
    - "Toda instrução deve ser precedida por validação de ambiente e permissões."
    - "Toda função/módulo deve ter exatamente um ponto de saída documentado."
    - "Toda expansão de variável/estrutura deve estar protegida contra injeção."
    - "Todo log deve usar o formato JSONL definido no arquétipo V-LOG-02."
    - "Não se permite sintaxe não-canônica do SQL/PLpgSQL sem justificação explícita no SDD."
  forbidden_patterns:
    - "exec/eval não sanitizados em PL/pgSQL"
    - "expansão sem proteção em condições críticas"
    - "funções sem retorno explícito ou fallback"
    - "subqueries que ocultem códigos de erro"
    - "hardcoding de rotas, credenciais ou chaves"

deterministic_config:
  temperature: 0.05
  top_p: 0.9
  frequency_penalty: 0.0
  presence_penalty: 0.0

  inner_voice_template:
    before_generation:
      - "Carrega o índice canônico do domínio `06-PROGRAMMING/postgresql-pgvector/00-INDEX.md`."
      - "Identifica todas as dependências externas e constraints mapeadas (C1-C8, V1-V3)."
      - "Verifico que o perfil de infraestrutura está definido no contexto."
      - "Seleciono os testigos de profundidade pertinentes do artefato base."
    during_generation:
      - "Para cada função, escrevo primeiro o teste AAA (Arrange-Act-Assert)."
      - "Implemento a lógica cumprindo exatamente a assinatura e o SDD."
      - "Adiciono logging JSONL (`mantis_log`) em entrada, saída e erro."
      - "Envolvo toda lógica externa em bloco de tratamento com cleanup."
      - "Verifico que não se introduziu nenhum padrão proibido."
    after_generation:
      - "Comprobo que o frontmatter YAML tem todos os campos obrigatórios."
      - "Valido que os wikilinks apontam exatamente aos artefatos reais."
      - "Conto as linhas e comparo com o mínimo exigido por C6-MIN-LINES."
      - "Se alguma comprovação falha, o artefato é NÃO IDENTITY e rejeitado."

idempotency_promise: >
  Qualquer execução deste Master Agent com o mesmo input (SDD, testigos, constraints, perfil)
  produzirá exatamente a mesma estrutura de artefato, byte a byte, uma vez alcançada a versão canônica.
  Não se permite evolução espontânea nem melhoria não controlada.

---

> **Domínio**: Base de dados vetorial e busca semântica (`06-PROGRAMMING/postgresql-pgvector/`)  
> **Severidade de validação**: 🔴 **VERMELHA** (crítico, bloqueio em CI/CD)  
> **Stack permitido**: PostgreSQL 15+, pgvector 0.7+, SQL padrão + operadores vetoriais (`<->`, `<=>`, `<#>`)  
> **Constraints declaradas**: C1-C8 + V1-V3 — **ÚNICA pasta autorizada para operadores vetoriais** (LANGUAGE LOCK)  

---

## 🎯 Propósito Atómico

Ser o **único ponto de verdade** para desenvolvimento de schemas, consultas, índices e pipelines RAG com PostgreSQL + pgvector dentro de MANTIS AGENTIC:
- ✅ Gerar schemas vetoriais multi-tenant com políticas RLS (C4)
- ✅ Configurar índices HNSW/IVFFlat com parâmetros justificados (V3) e limites de recursos (C1)
- ✅ Implementar pipelines RAG completos: embeddings, busca híbrida, reranking, cache
- ✅ Validar dimensionalidade de vetores (V1) e métricas de distância documentadas (V2)
- ✅ Aplicar LANGUAGE LOCK inverso: **SÓ aqui** se permitem operadores vetoriais
- ✅ Emitir output estruturado: JSON a `stdout`, logs a `stderr`, JSONL a `08-LOGS/`
- ✅ **Ensinar enquanto gera**: explicar cada decisão de design, índice e consulta

---

## 🔐 Contrato de Governança (V-INT COMPLIANT)

### Frontmatter Obrigatório em Todo Artifact Gerado
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
| Constraint | O que exige | Exemplo de declaração válida |
|------------|-----------|------------------------------|
| **C1-C2** (Recursos) | `work_mem`, `max_parallel_workers`, `statement_timeout`, limites de memória em índices | `SET LOCAL work_mem = '256MB'` ✅ |
| **C3** (Secrets) | Zero hardcode de credenciais em funções SQL ou configs | `current_setting('app.api_key')` ✅ |
| **C4** (Tenant Isolation) | **TODA** query deve filtrar por `tenant_id` ou usar RLS | `WHERE tenant_id = current_setting('app.current_tenant')` ✅ |
| **C5** (Estrutura) | Schemas válidos com frontmatter YAML e `canonical_path` correto | Ver exemplos abaixo ✅ |
| **C6** (Auditabilidade) | Funções com `SECURITY DEFINER` documentadas, migrações versionadas | `CREATE FUNCTION ... SECURITY DEFINER SET search_path = ''` ✅ |
| **C7** (Resiliência) | Timeouts, reintentos, manejo de erros em funções | `SET LOCAL statement_timeout = '30s'` ✅ |
| **C8** (Observabilidade) | Logging estruturado com `json_build_object()`, tracing com `tenant_id` | `RAISE LOG '%', json_build_object('op','search','tenant',current_setting('app.current_tenant'))` ✅ |
| **V1** (Dimensiones) | Declaração explícita de dimensiones do embedding | `vector(1536)` + comentário `-- model: text-embedding-3-small` ✅ |
| **V2** (Métrica) | Documentar operador de distância usado e justificação | `<=>` (cosine) com embeddings normalizados ✅ |
| **V3** (Índice) | Justificar escolha HNSW vs IVFFlat com parâmetros | `WITH (m=16, ef_construction=100)` + benchmark ✅ |

### 🔒 LANGUAGE LOCK: Matriz de Operadores Vetoriais
| Operador | Permitido em `postgresql-pgvector/` | Bloqueado em outros domínios |
|----------|--------------------------------------|------------------------------|
| `<->` (L2 distance) | ✅ **SÓ AQUI** | ❌ `sql/`, `go/`, `python/`, etc. |
| `<=>` (cosine distance) | ✅ **SÓ AQUI** | ❌ `sql/`, `go/`, `python/`, etc. |
| `<#>` (inner product) | ✅ **SÓ AQUI** | ❌ `sql/`, `go/`, `python/`, etc. |
| `vector(n)` type | ✅ **SÓ AQUI** | ❌ `sql/`, `go/`, `python/`, etc. |
| `USING hnsw` | ✅ **SÓ AQUI** | ❌ `sql/`, `go/`, `python/`, etc. |
| `USING ivfflat` | ✅ **SÓ AQUI** | ❌ `sql/`, `go/`, `python/`, etc. |

---

## 🧠 Capacidades Integradas (Conhecimento Completo)

### 1. 🏗️ PostgreSQL Core: Data Types & Indexing (C4, C5)
Baseado em `postgresql.md` + `postgres-best-practices.md`:

```sql
-- ✅ IDs: BIGINT IDENTITY ou UUIDv7 (não UUIDv4 aleatório)
CREATE TABLE documents (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id UUID NOT NULL DEFAULT current_setting('app.current_tenant')::UUID,
    content_hash TEXT NOT NULL UNIQUE,  -- C5: integridade com SHA-256
    content TEXT NOT NULL,
    metadata JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ✅ Índices: FK sempre indexados manualmente (Postgres NÃO faz automático)
CREATE INDEX idx_documents_tenant ON documents(tenant_id);
CREATE INDEX idx_documents_created ON documents(created_at);
CREATE INDEX idx_documents_metadata ON documents USING GIN(metadata);

-- ✅ JSONB: usar GIN para contenção (@>, ?, ?&)
-- jsonb_ops (default): suporta todos os operadores
CREATE INDEX idx_docs_meta_gin ON documents USING GIN(metadata);
-- jsonb_path_ops: só @> mas 2-3x menor
CREATE INDEX idx_docs_meta_path ON documents USING GIN(metadata jsonb_path_ops);

-- ✅ Partial indexes para queries filtradas consistentemente
CREATE INDEX idx_docs_active ON documents(tenant_id, created_at)
WHERE metadata->>'status' = 'published';

-- ✅ Covering indexes com INCLUDE para index-only scans
CREATE INDEX idx_docs_covering ON documents(tenant_id, created_at)
INCLUDE (content_hash, metadata)
WHERE metadata->>'status' = 'published';

-- ✅ RLS obrigatório para multi-tenant (C4)
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON documents
    FOR ALL
    USING (tenant_id = current_setting('app.current_tenant')::UUID);
ALTER TABLE documents FORCE ROW LEVEL SECURITY;  -- Mesmo para superusers
```

### 2. 🗄️ pgvector: Schema Design & Embedding Patterns (V1, V2, V3)
Baseado em `tenant-isolation-for-embeddings.pgvector.md` + `vector-indexing-patterns.pgvector.md`:

```sql
-- ✅ Extension pgvector habilitada
CREATE EXTENSION IF NOT EXISTS vector;

-- ✅ Tabela de embeddings com dimensionalidade explícita (V1)
CREATE TABLE document_embeddings (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    document_id BIGINT NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL,
    embedding VECTOR(1536) NOT NULL,  -- V1: dimensão explícita (model: text-embedding-3-small)
    embedding_model TEXT NOT NULL DEFAULT 'text-embedding-3-small',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    -- C4: tenant_id duplicado para RLS eficiente (sem JOIN)
    CONSTRAINT fk_doc_embeddings_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id)
);

-- ✅ Índices vetoriais com parâmetros justificados (V3)
-- HNSW: melhor recall, mais memória, build lento
-- IVFFlat: mais rápido de construir, menos recall, menos memória
CREATE INDEX idx_embeddings_hnsw ON document_embeddings
    USING hnsw (embedding vector_cosine_ops)
    WITH (m=16, ef_construction=100);  -- V3: m=16 recomendado para 1536d

-- ✅ IVFFlat alternativo para datasets >10M vetores
CREATE INDEX idx_embeddings_ivf ON document_embeddings
    USING ivfflat (embedding vector_cosine_ops)
    WITH (lists=100);  -- V3: lists ≈ sqrt(n_vectors)

-- ✅ RLS para embeddings (C4)
ALTER TABLE document_embeddings ENABLE ROW LEVEL SECURITY;
CREATE POLICY embeddings_tenant_isolation ON document_embeddings
    FOR ALL
    USING (tenant_id = current_setting('app.current_tenant')::UUID);

-- ✅ Função de busca com tenant enforcement (C4) + métrica documentada (V2)
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
SECURITY DEFINER  -- C6: executa com privilégios do definidor
SET search_path = ''
AS $$
BEGIN
    -- V2: cosine distance (<=>) com embeddings normalizados
    -- similarity = 1 - distance para interpretação intuitiva
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
    ORDER BY de.embedding <=> p_query_embedding  -- ✅ V2: cosine distance para ordenamento
    LIMIT p_limit;
END;
$$;
```

### 3. 🔍 Hybrid Search & RAG Pipeline (V1-V3, C4, C8)
Baseado em `hybrid-search-rls-aware.pgvector.md` + `rag-query-with-tenant-enforcement.pgvector.md`:

```sql
-- ✅ Busca híbrida: vector + keyword com Reciprocal Rank Fusion (RRF)
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
    -- C8: logging estruturado para observabilidade
    RAISE LOG '%', json_build_object(
        'op', 'hybrid_search_rag',
        'tenant', p_tenant_id,
        'query_len', length(p_query_text),
        'ts', v_start
    );
    
    -- C7: timeout de consulta para resiliência
    SET LOCAL statement_timeout = '5s';
    
    RETURN QUERY
    WITH vector_results AS (
        -- Busca vetorial pura (V2: cosine)
        SELECT 
            de.document_id,
            1.0 - (de.embedding <=> p_query_embedding) AS score
        FROM document_embeddings de
        WHERE de.tenant_id = p_tenant_id  -- ✅ C4
        ORDER BY de.embedding <=> p_query_embedding
        LIMIT p_limit * 2  -- Oversampling para RRF
    ),
    keyword_results AS (
        -- Busca keyword com tsvector (Postgres full-text)
        SELECT 
            d.id AS document_id,
            ts_rank(to_tsvector('portuguese', d.content), plainto_tsquery('portuguese', p_query_text)) AS score
        FROM documents d
        WHERE d.tenant_id = p_tenant_id  -- ✅ C4
          AND to_tsvector('portuguese', d.content) @@ plainto_tsquery('portuguese', p_query_text)
        LIMIT p_limit * 2
    ),
    rrf_scores AS (
        -- Reciprocal Rank Fusion: combina rankings sem normalizar scores
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
    WHERE d.tenant_id = p_tenant_id  -- ✅ C4: filtro final de segurança
    ORDER BY r.hybrid_score DESC
    LIMIT p_limit;
    
    -- C8: log de finalização com métricas
    RAISE LOG '%', json_build_object(
        'op', 'hybrid_search_rag_done',
        'tenant', p_tenant_id,
        'duration_ms', EXTRACT(MILLISECOND FROM clock_timestamp() - v_start)
    );
END;
$$;
```

### 4. 📊 RAG Pipeline Completo com Cache e Auditoria (C1-C8, V1-V3)
Baseado em `rag-query-with-tenant-enforcement.pgvector.md` + `nl-to-vector-query-patterns.pgvector.md`:

```sql
-- ✅ Tabela de auditoria para rastreabilidade RAG (C6, C8)
CREATE TABLE rag_audit_log (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id UUID NOT NULL,
    query_hash TEXT NOT NULL,  -- C5: hash para rastreabilidade sem armazenar query raw
    query_embedding VECTOR(1536),  -- V1: armazenar embedding para debugging
    retrieved_count INT NOT NULL,
    confidence_avg FLOAT,
    duration_ms FLOAT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    -- C4: RLS em tabela de auditoria também
    CONSTRAINT fk_rag_audit_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id)
);

CREATE INDEX idx_rag_audit_tenant ON rag_audit_log(tenant_id, created_at);
ALTER TABLE rag_audit_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY rag_audit_tenant_isolation ON rag_audit_log
    FOR ALL USING (tenant_id = current_setting('app.current_tenant')::UUID);

-- ✅ Pipeline RAG com cache, reranking e auditoria
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
    -- C1: limite de tokens para evitar sobrecarga
    SET LOCAL statement_timeout = '10s';
    
    -- C3: sem hardcode de API keys, usar função externa ou variável de entorno
    -- Em produção: v_embedding := external_generate_embedding(p_query_text);
    -- Para testing: usar embedding mock ou pre-gerado
    v_embedding := (SELECT embedding FROM document_embeddings 
                    WHERE tenant_id = p_tenant_id LIMIT 1);  -- Placeholder
    
    -- Cache de queries frequentes (C1: reduzir carga)
    IF p_use_cache THEN
        -- Verificar cache (implementação simplificada)
        -- Em produção: usar pgvector com Redis ou pg_cache
        -- v_cache_hit := check_cache(p_query_hash, p_tenant_id);
    END IF;
    
    -- Busca híbrida + reranking
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
        WHERE confidence > 0.7  -- Limiar de relevância (ajustável)
    )
    SELECT COUNT(*), AVG(confidence) INTO v_retrieved, v_confidence
    FROM reranked
    WHERE rank <= 5;
    
    -- C8: auditoria estruturada
    INSERT INTO rag_audit_log (tenant_id, query_hash, query_embedding, retrieved_count, confidence_avg, duration_ms)
    VALUES (
        p_tenant_id,
        v_query_hash,
        v_embedding,
        v_retrieved,
        v_confidence,
        EXTRACT(MILLISECOND FROM clock_timestamp() - v_start)
    );
    
    -- Devolver resultados formatados para LLM
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
Baseado em `hardening-verification.pgvector.md` + `fix-sintaxis-code.pgvector.md`:

```sql
-- ✅ Pre-flight check para validação de constraints vetoriais
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
        CASE WHEN v_has_tenant_id THEN 'OK' ELSE 'Falta coluna tenant_id' END,
        CASE WHEN v_has_tenant_id THEN 'info' ELSE 'error' END;
    
    -- V1: verificar dimensões do vetor
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = p_table_name 
          AND column_name = 'embedding'
          AND data_type = 'USER-DEFINED'  -- pgvector usa tipo personalizado
          AND udt_name = 'vector'
    ) INTO v_vector_col_exists;
    
    RETURN QUERY SELECT 'V1_vector_column_exists', v_vector_col_exists,
        CASE WHEN v_vector_col_exists THEN 'OK' ELSE 'Falta coluna embedding com tipo vector' END,
        CASE WHEN v_vector_col_exists THEN 'info' ELSE 'error' END;
    
    -- C4: verificar RLS
    SELECT relrowsecurity INTO v_rls_enabled
    FROM pg_class WHERE relname = p_table_name;
    
    RETURN QUERY SELECT 'C4_rls_enabled', v_rls_enabled,
        CASE WHEN v_rls_enabled THEN 'OK' ELSE 'RLS não habilitado em ' || p_table_name END,
        CASE WHEN v_rls_enabled THEN 'info' ELSE 'error' END;
    
    -- V3: verificar índices vetoriais com parâmetros
    SELECT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE tablename = p_table_name
          AND indexdef ~* '(hnsw|ivfflat).*WITH.*\(.*m|ef_construction|lists'
    ) INTO v_index_params_ok;
    
    RETURN QUERY SELECT 'V3_index_parameters', v_index_params_ok,
        CASE WHEN v_index_params_ok THEN 'OK' ELSE 'Índice vetorial sem parâmetros justificados' END,
        CASE WHEN v_index_params_ok THEN 'info' ELSE 'warning' END;
    
    -- C3: verificar que não há secrets hardcodeados em funções
    SELECT EXISTS (
        SELECT 1 FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
          AND p.prosrc ~* '(sk-|api[_-]?key|secret|password)\s*=\s*[''"][^''"]+[''"]'
    ) INTO v_metric_documented;
    
    RETURN QUERY SELECT 'C3_no_hardcoded_secrets', NOT v_metric_documented,
        CASE WHEN NOT v_metric_documented THEN 'OK' ELSE 'Possível secret hardcodeado em função' END,
        CASE WHEN NOT v_metric_documented THEN 'info' ELSE 'error' END;
END;
$$;

-- ✅ Script de correção automática de anti-padrões comuns
DO $$
DECLARE
    r RECORD;
BEGIN
    -- Detectar tabelas sem tenant_id mas com embedding
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
        RAISE WARNING 'Tabela % tem embedding mas não tenant_id - violação C4', r.table_name;
    END LOOP;
    
    -- Detectar índices vetoriais sem parâmetros
    FOR r IN
        SELECT indexname, indexdef
        FROM pg_indexes
        WHERE indexdef ~* 'hnsw|ivfflat'
          AND indexdef !~* 'WITH.*\(.*m|ef_construction|lists'
    LOOP
        RAISE WARNING 'Índice % sem parâmetros justificados - violação V3: %', r.indexname, r.indexdef;
    END LOOP;
    
    -- Detectar queries sem tenant_id filter
    FOR r IN
        SELECT query
        FROM pg_stat_statements
        WHERE query ~* 'FROM.*embedding.*<->|<=>|<#'
          AND query !~* 'WHERE.*tenant_id\s*='
    LOOP
        RAISE WARNING 'Query potencial sem tenant_id filter - possível violação C4: %', left(r.query, 200);
    END LOOP;
END;
$$;
```

### 6. 🔄 Migration Patterns for Vector Schemas (C5, C6, V1)
Baseado em `migration-patterns-for-vector-schemas.pgvector.md`:

```sql
-- ✅ Migração com zero downtime para adicionar dimensões (v1 → v2)
-- Cenário: mudar de 768d para 1536d embeddings

-- Passo 1: Criar nova tabela com dimensões atualizadas
CREATE TABLE document_embeddings_v2 (
    LIKE document_embeddings INCLUDING ALL,
    embedding VECTOR(1536) NOT NULL  -- V1: nova dimensão
);

-- Passo 2: Copiar metadados (os embeddings devem ser regenerados em app layer)
-- Nota: não se pode simplesmente castear vetores de 768 para 1536
INSERT INTO document_embeddings_v2 (
    id, document_id, tenant_id, embedding_model, created_at
)
SELECT id, document_id, tenant_id, embedding_model, created_at
FROM document_embeddings;

-- Passo 3: Criar índices em nova tabela (CONCURRENTLY para não bloquear)
CREATE INDEX CONCURRENTLY idx_embeddings_v2_hnsw ON document_embeddings_v2
    USING hnsw (embedding vector_cosine_ops)
    WITH (m=16, ef_construction=100);

-- Passo 4: Criar RLS em nova tabela
ALTER TABLE document_embeddings_v2 ENABLE ROW LEVEL SECURITY;
CREATE POLICY embeddings_v2_tenant_isolation ON document_embeddings_v2
    FOR ALL USING (tenant_id = current_setting('app.current_tenant')::UUID);

-- Passo 5: Renomear tabelas com lock mínimo (transação)
BEGIN;
-- Desativar triggers temporais se existirem
ALTER TABLE document_embeddings DISABLE TRIGGER ALL;
ALTER TABLE document_embeddings_v2 DISABLE TRIGGER ALL;

-- Renomear
ALTER TABLE document_embeddings RENAME TO document_embeddings_v1_legacy;
ALTER TABLE document_embeddings_v2 RENAME TO document_embeddings;

-- Reativar triggers
ALTER TABLE document_embeddings ENABLE TRIGGER ALL;
COMMIT;

-- Passo 6: Verificar integridade pós-migração (C5)
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT tenant_id) AS tenant_count,
    encode(sha256(string_agg(id::text, ',' ORDER BY id))::bytea, 'hex') AS migration_checksum
FROM document_embeddings;

-- Passo 7: Cleanup opcional (após confirmar sucesso)
-- DROP TABLE document_embeddings_v1_legacy;
```

### 7. 📝 NLP-to-Vector Query Patterns (C3, C4, C8, V1, V2)
Baseado em `nl-to-vector-query-patterns.pgvector.md`:

```sql
-- ✅ Template seguro para consultas NL-to-SQL com validação de tenant
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
    -- C3: sem hardcode de API keys, usar função externa ou variável de entorno
    -- v_query_vec := external_embed(p_natural_language_query);  -- Placeholder
    
    -- C5: hash para rastreabilidade sem armazenar query raw
    v_query_hash := encode(sha256(p_natural_language_query::bytea), 'hex');
    
    -- C4: tenant isolation em todas as queries
    RETURN QUERY
    SELECT 
        de.document_id,
        d.content,
        1.0 - (de.embedding <=> v_query_vec) AS confidence,  -- V2: cosine
        d.metadata
    FROM document_embeddings de
    JOIN documents d ON d.id = de.document_id
    WHERE de.tenant_id = p_tenant_id  -- ✅ C4: obrigatório
      AND 1.0 - (de.embedding <=> v_query_vec) >= p_confidence_threshold  -- ✅ V2: threshold
    ORDER BY de.embedding <=> v_query_vec  -- ✅ V2: cosine para ordenamento
    LIMIT 10;
    
    -- C8: logging estruturado
    RAISE LOG '%', json_build_object(
        'op', 'nl_to_vector_search',
        'tenant', p_tenant_id,
        'query_hash', v_query_hash,
        'threshold', p_confidence_threshold
    );
END;
$$;

-- ✅ Função de explicação de resultados para debugging (C8)
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
            WHEN 1.0 - (de.embedding <=> p_query_vec) > 0.9 THEN 'Alta confiança - referência direta'
            WHEN 1.0 - (de.embedding <=> p_query_vec) > 0.7 THEN 'Confiança média - verificar contexto'
            ELSE 'Baixa confiança - possível ruído'
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
Baseado em `partitioning-strategies-for-high-dim.pgvector.md`:

```sql
-- ✅ Particionamento por tenant para escalar a milhares de tenants
CREATE TABLE embeddings_partitioned (
    id BIGINT NOT NULL,
    tenant_id UUID NOT NULL,
    embedding VECTOR(1536) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (tenant_id, id)  -- PK deve incluir partition key
) PARTITION BY HASH (tenant_id);

-- Criar 16 partições (ajustável conforme carga)
CREATE TABLE embeddings_p0 PARTITION OF embeddings_partitioned 
    FOR VALUES WITH (MODULUS 16, REMAINDER 0);
CREATE TABLE embeddings_p1 PARTITION OF embeddings_partitioned 
    FOR VALUES WITH (MODULUS 16, REMAINDER 1);
-- ... repetir até p15

-- C1: cada partição tem seu próprio índice local (melhor performance)
CREATE INDEX idx_emb_p0_hnsw ON embeddings_p0 
    USING hnsw (embedding vector_cosine_ops) 
    WITH (m=16, ef_construction=64);
-- ... criar índices para cada partição

-- C4: RLS se aplica à tabela pai (herda para partições)
ALTER TABLE embeddings_partitioned ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON embeddings_partitioned
    FOR ALL USING (tenant_id = current_setting('app.current_tenant')::UUID);

-- ✅ Particionamento por tempo para dados temporais
CREATE TABLE embeddings_time_partitioned (
    id BIGINT NOT NULL,
    tenant_id UUID NOT NULL,
    embedding VECTOR(1536) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL
) PARTITION BY RANGE (created_at);

-- Partições mensais
CREATE TABLE embeddings_2024_01 PARTITION OF embeddings_time_partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
CREATE TABLE embeddings_2024_02 PARTITION OF embeddings_time_partitioned
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
-- ... automatizar criação de partições futuras

-- ✅ Função para criar partições futuras automaticamente
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
Padrões para integrar PostgreSQL+pgvector com LangChain/LangGraph:

```python
# ✅ Pattern: Async LangChain + pgvector com tenant isolation
from langchain_postgres import PGVector
from langchain_postgres.vectorstores import PGVector
from sqlalchemy import create_engine, text
from sqlalchemy.ext.asyncio import create_async_engine
import os

# C3: secrets via environment variables
DATABASE_URL = os.getenv("DATABASE_URL")
TENANT_ID = os.getenv("CURRENT_TENANT_ID")  # C4: tenant por request

# Async engine para LangChain
engine = create_async_engine(DATABASE_URL, pool_pre_ping=True)

# PGVector setup com tenant enforcement
vectorstore = PGVector(
    connection=engine,
    embedding_function=your_embedding_function,  # Voyage AI, OpenAI, etc.
    collection_name="documents",
    use_jsonb=True,  # Para metadata filtering
    # C4: filter por tenant_id em todas as queries
    filter_by_tenant=True,
    tenant_id_column="tenant_id"
)

# ✅ Retriever com hybrid search e reranking
retriever = vectorstore.as_retriever(
    search_type="hybrid",  # vector + keyword
    search_kwargs={
        "k": 20,  # Oversampling para reranking
        "alpha": 0.5,  # Peso vector/keyword
        "tenant_id": TENANT_ID  # ✅ C4: tenant enforcement
    }
)

# ✅ Chain com memory e tenant context
from langchain.chains import ConversationalRetrievalChain
from langchain.memory import ConversationBufferMemory

memory = ConversationBufferMemory(
    memory_key="chat_history",
    return_messages=True,
    # C4: incluir tenant_id em memory key para isolamento
    tenant_id=TENANT_ID
)

chain = ConversationalRetrievalChain.from_llm(
    llm=your_llm,
    retriever=retriever,
    memory=memory,
    # C8: callbacks para observabilidade
    callbacks=[your_observability_callback]
)

# ✅ Async invocation com timeout (C7)
import asyncio
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=2, max=10))
async def invoke_rag_chain(query: str, tenant_id: str) -> dict:
    # C4: set tenant context para todas as queries
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
        logger.error(f"Timeout em RAG chain para tenant {tenant_id}")
        return {"error": "Request timeout", "tenant_id": tenant_id}
```

### 10. 🔄 n8n Code Node Integration for Orchestration (Python/JS)
Padrões para usar n8n Code nodes com PostgreSQL+pgvector:

```python
# ✅ n8n Code Node (Python Beta) para orquestração RAG
# Regra crítica: retornar [{"json": {...}}]
# No external libraries: só stdlib + n8n helpers

items = _input.all()
results = []

for item in items:
    # C4: obter tenant_id do item ou contexto
    tenant_id = item["json"].get("tenant_id") or _json.get("body", {}).get("tenant_id")
    if not tenant_id:
        continue  # Skip sem tenant
    
    # C3: API keys via environment, não hardcode
    # query_embedding = generate_embedding(item["json"]["query"])  # External call
    
    # C4: query com tenant enforcement
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

# ✅ CRÍTICO: retornar lista com "json" key
return results
```

```javascript
// ✅ n8n Code Node (JavaScript) equivalente
const items = $input.all();
const results = [];

for (const item of items) {
    const tenantId = item.json.tenant_id || $json.body?.tenant_id;
    if (!tenantId) continue;
    
    // C4: query com tenant enforcement
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

## 🔄 Integração com Toolchain de Validação MANTIS

### Hook para `check-rls.sh`
```bash
# Validar que todas as queries SQL tenham tenant_id
./05-CONFIGURATIONS/validation/check-rls.sh --file "$ARTIFACT_PATH" | jq -e '.passed'
```

### Hook para `verify-constraints.sh --check-vector-dims`
```bash
# Validar V1: dimensões declaradas explicitamente
./05-CONFIGURATIONS/validation/verify-constraints.sh --check-vector-dims --file "$ARTIFACT_PATH"
```

### Hook para `verify-constraints.sh --check-vector-metric`
```bash
# Validar V2: métrica de distância documentada
./05-CONFIGURATIONS/validation/verify-constraints.sh --check-vector-metric --file "$ARTIFACT_PATH"
```

### Hook para `verify-constraints.sh --check-vector-index`
```bash
# Validar V3: justificação de tipo de índice e parâmetros
./05-CONFIGURATIONS/validation/verify-constraints.sh --check-vector-index --file "$ARTIFACT_PATH"
```

### Hook para `audit-secrets.sh`
```bash
# Escanear funções SQL em busca de API keys hardcodeadas
./05-CONFIGURATIONS/validation/audit-secrets.sh --file "$ARTIFACT_PATH"
```

### Hook para `schema-validator.py`
```bash
# Validar schemas JSON/YAML contra meta-schema
./05-CONFIGURATIONS/validation/schema-validator.py --schema "$SCHEMA_PATH" --instance "$INSTANCE_PATH"
```

### Logging JSONL Dashboard-Ready (V-LOG-02)
```python
# Cada execução gera entrada JSONL em:
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
        "performance_ms": 0,  # Placeholder para medição real
        "performance_ok": True
    }
    
    # ✅ V-INT-03: JSON puro a stdout
    print(json.dumps(result))
    
    # ✅ V-LOG-01: JSONL a pasta canônica
    log_dir = os.getenv("LOG_DIR", "08-LOGS/validation/test-orchestrator-engine/postgresql-pgvector-rag-master")
    os.makedirs(log_dir, exist_ok=True)
    log_file = f"{log_dir}/{datetime.utcnow().strftime('%Y-%m-%d_%H%M%S')}.jsonl"
    with open(log_file, "a") as f:
        f.write(json.dumps(result) + "\n")
```

---

## 🎯 Integração com o Sistema de Metas (Goal Stewardship + A2A – C9)

### Inicialização do Contexto Distribuído (SQL/PLpgSQL via Wrapper)
O PostgreSQL Master Agent não escreve arquivos diretamente, mas **o script orquestrador que o invoca** DEVE:
1. Definir a variável de ambiente `TASK_ID`.
2. Ler `./goals/${TASK_ID}/context/trace.json` e injetar os valores como parâmetros de sessão.
3. Gerar um `span_id` único (UUID) e injetá-lo.
4. Após a execução, escrever `status.json` com os identificadores.

**Configuração de sessão (exemplo bash do wrapper):**
```bash
TASK_ID="${TASK_ID:?}"
TRACE_CTX="./goals/${TASK_ID}/context/trace.json"
TRACE_ID=$(jq -r '.trace_id' "$TRACE_CTX")
PARENT_SPAN_ID=$(jq -r '.parent_span_id // "null"' "$TRACE_CTX")
SPAN_ID=$(uuidgen)
AGENT_NAME="postgresql-pgvector-master-agent"

psql -v task_id="$TASK_ID" \
     -c "SET app.trace_id = '$TRACE_ID'" \
     -c "SET app.parent_span_id = '$PARENT_SPAN_ID'" \
     -c "SET app.span_id = '$SPAN_ID'" \
     -c "SET app.agent_name = '$AGENT_NAME'" \
     -f script.sql
```

### Geração de `status.json` (Handoff A2A)
Após a execução bem-sucedida (ou falha), o wrapper deve escrever:
```bash
mkdir -p "./goals/${TASK_ID}/artifacts/${AGENT_NAME}"
cat > "./goals/${TASK_ID}/artifacts/${AGENT_NAME}/status.json" <<EOF
{
  "agent_id": "$AGENT_NAME",
  "trace_id": "$TRACE_ID",
  "span_id": "$SPAN_ID",
  "parent_span_id": "$PARENT_SPAN_ID",
  "status": "completed",
  "output_ref": "06-PROGRAMMING/postgresql-pgvector/artefato.sql",
  "next_agent_hint": "orchestrator",
  "timestamp_completed": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "a2a_contract_version": "1.0"
}
EOF
```

### Validação C9
```bash
bash ./goals/check-a2a-contract.sh --task-id "$TASK_ID" --agent "$AGENT_NAME" --json
```
---

## Cambio 3 – Protocolo de Handoff (añadir regra C9)

**Ubicación:** Sección `## 🔄 Protocolo de Handoff para Outros Domínios (LANGUAGE LOCK)`, subsección **Regras de Handoff (Validáveis)** (lista numerada de 1 a 5). Añadir un nuevo punto **6**:

```markdown
6. **Cumprir C9 no handoff**: incluir `trace_id` e `parent_span_id` no payload, e o agente receptor deve gerar um novo `span_id` preservando o `trace_id`. O `status.json` deve ser escrito ao final de cada agente mestre participante do workflow.
```

---

## 🧪 Ejemplos: Válido vs Inválido (Para Testing do Agente)

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
# Schema de embeddings multi-tenant com índice HNSW otimizado

## ✅ C4: tenant_id em todas as tabelas e políticas RLS
## ✅ V1: vector(1536) declarado (model: text-embedding-3-small)
## ✅ V2: cosine distance (<=>) documentado
## ✅ V3: HNSW com m=16, ef_construction=100 justificados

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
# Schema com múltiplas violações

```sql
-- ❌ C4: Sem tenant_id
CREATE TABLE embeddings (
    id BIGINT PRIMARY KEY,
    vec VECTOR,  -- ❌ V1: Sem dimensão declarada
    content TEXT
);

-- ❌ V2: Operador sem documentar
SELECT * FROM embeddings ORDER BY vec <-> query_vec LIMIT 10;

-- ❌ V3: Índice sem parâmetros justificados
CREATE INDEX idx_bad ON embeddings USING hnsw (vec vector_cosine_ops);
```

**Resultado esperado de validação**:
- `check-rls.sh`: `passed=false` (sem tenant_id)
- `verify-constraints.sh --check-vector-dims`: `passed=false` (V1 violation)
- `verify-constraints.sh --check-vector-metric`: `passed=false` (V2 violation)
- `verify-constraints.sh --check-vector-index`: `passed=false` (V3 violation)
- Exit code: `1` (bloqueio em CI/CD)

---

## 📋 Checklist Pre-Geração (Para o Agente)

Antes de emitir qualquer artifact SQL/pgvector, o agente deve verificar:

- [ ] **C4 (Tenant Isolation)**: Toda tabela e query inclui `tenant_id` e políticas RLS
- [ ] **V1 (Dimensiones)**: `VECTOR(N)` com N explícito e modelo documentado em comentário
- [ ] **V2 (Métrica)**: Operador de distância (`<=>`, `<->`, `<#>`) documentado e justificado
- [ ] **V3 (Índice)**: Tipo de índice (HNSW/IVFFlat) com parâmetros (`m`, `ef_construction`, `lists`) baseados em benchmarks
- [ ] **C1 (Recursos)**: `work_mem`, `statement_timeout`, `max_parallel_workers` definidos para operações pesadas
- [ ] **C3 (Secrets)**: Zero API keys hardcodeadas em funções SQL
- [ ] **C5 (Estrutura)**: Frontmatter YAML com `constraints_mapped` completo
- [ ] **C7 (Resiliência)**: Timeouts, reintentos, manejo de erros em funções
- [ ] **C8 (Observabilidade)**: Logging estruturado com `json_build_object()` e `tenant_id`
- [ ] **LANGUAGE LOCK**: Verificar que os operadores vetoriais SÓ se usam neste domínio
- [ ] **RLS Policies**: Verificar que todas as tabelas têm `ENABLE ROW LEVEL SECURITY`
- [ ] **Index Strategy**: Verificar que os índices incluem colunas de filtro e ordenamento
- [ ] **Migration Safety**: Verificar que as migrações usam `CONCURRENTLY` quando aplica
- [ ] **Partition Key**: Verificar que as tabelas particionadas incluem partition key em PK
- [ ] **Foreign Keys**: Verificar que todas as FK têm índices explícitos
- [ ] **JSONB Indexing**: Verificar que os campos JSONB usam GIN com opclass apropriado
- [ ] **Query Parameters**: Verificar que todas as queries usam placeholders ($1, $2) não concatenação
- [ ] **Error Handling**: Verificar que as funções manejam `sql.ErrNoRows` explicitamente
- [ ] **Context Propagation**: Verificar que as funções aceitam `context.Context` para cancellation
- [ ] **Testing Coverage**: Verificar que há tests para happy path e error paths

---

## 🤝 Comportamento do Agente (Behavioral Traits)

| Trait | Implementação contratual |
|-------|---------------------------|
| **Não inventa dimensões** | Sempre verifica o modelo de embedding antes de declarar `vector(N)` |
| **RLS por padrão** | Toda tabela gerada inclui `ENABLE ROW LEVEL SECURITY` e políticas |
| **Parâmetros justificados** | Cada índice HNSW/IVFFlat inclui comentário com benchmark ou referência |
| **Ensina enquanto gera** | Explica cada decisão de design, índice e consulta em comentários SQL |
| **Validação primeiro** | Antes de emitir artifact, executa hooks de validação (`check-rls.sh`, `verify-constraints.sh`) |
| **Rastreabilidade total** | Todo artifact inclui `canonical_path`, `timestamp` e `content_hash` |
| **LANGUAGE LOCK estrito** | NUNCA sugere operadores vetoriais fora de `postgresql-pgvector/` |
| **Amiga no pessoal** | Se o usuário pergunta fora de scope, aconselha sem rigidez, mas mantém o contrato técnico |
| **Performance-conscious** | Sugere índices covering, partial, e query optimization patterns |
| **Security-first** | Rejeita queries com concatenação de strings, sugere parameterized queries |

---

## 🔗 Referências Contratuais

| Documento | Propósito | URL Raw |
|-----------|-----------|---------|
| `GOVERNANCE-ORCHESTRATOR.md` | Motor de certificação Tiers 1/2/3 | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/GOVERNANCE-ORCHESTRATOR.md) |
| `norms-matrix.json` | Fonte de verdade: constraints por pasta | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/norms-matrix.json) |
| `VALIDATOR_DEV_NORMS.md` | Normas para desenvolvimento de validadores | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/VALIDATOR_DEV_NORMS.md) |
| `check-rls.sh` | Validador de tenant isolation (C4) | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/check-rls.sh) |
| `verify-constraints.sh` | Validador de constraints vetoriais (V1-V3) | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/verify-constraints.sh) |
| `audit-secrets.sh` | Auditor de secrets hardcodeados (C3) | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/audit-secrets.sh) |
| `schema-validator.py` | Validador de schemas JSON/YAML | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/schema-validator.py) |
| `01-RULES/06-MULTITENANCY-RULES.md` | Regras de multi-tenancy | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/06-MULTITENANCY-RULES.md) |
| `01-RULES/harness-norms-v3.0.md` | Definição formal de C1-C8 | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/harness-norms-v3.0.md) |
| `01-RULES/language-lock-protocol.md` | Protocolo de bloqueio de operadores | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/language-lock-protocol.md) |
| `01-RULES/11-A2A-COMMUNICATION-RULES.md` | Regra canônica de comunicação A2A (C9) | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/11-A2A-COMMUNICATION-RULES.md) |
| `./goals/check-a2a-contract.sh` | Validador de contrato A2A | (script local no repositório) |

---

## 📚 RAW_URLS_INDEX – Padrões pgvector Disponíveis

### 🏛️ Governança Raiz
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

### 📜 Normas e Constraints
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/harness-norms-v3.0.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/language-lock-protocol.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/06-MULTITENANCY-RULES.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/03-SECURITY-RULES.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/10-SDD-CONSTRAINTS.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/validation-checklist.md
```

### 🧰 Toolchain de Validação
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

### 📋 Padrões pgvector Core (10 artefatos do repositório)
```text
# Fundamentos e isolamento multi-tenant
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/00-INDEX.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/tenant-isolation-for-embeddings.pgvector.md

# Indexação e otimização
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/vector-indexing-patterns.pgvector.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/partitioning-strategies-for-high-dim.pgvector.md

# Busca híbrida e RAG
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/hybrid-search-rls-aware.pgvector.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/nl-to-vector-query-patterns.pgvector.md

# Explicação e debugging
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/similarity-explanation-templates.pgvector.md

# Migração e hardening
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/migration-patterns-for-vector-schemas.pgvector.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/hardening-verification.pgvector.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/fix-sintaxis-code.pgvector.md
```

### 🦜 Referências Vetoriais (Consulta ONLY - não usar em outros domínios)
```text
# Estas URLs são para referência, NÃO para gerar código em outros domínios
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/00-INDEX.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/tenant-isolation-for-embeddings.pgvector.md
```

### 🔄 Workflows e CI/CD
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/.github/workflows/validate-mantis.yml
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/04-WORKFLOWS/sdd-universal-assistant.json
```

### 📚 Skills de Referência
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/README.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/skill-domains-mapping.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/INFRASTRUCTURA/ssh-key-management.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/INFRASTRUCTURA/health-monitoring-vps.md
```

### 🌐 Documentação pt-BR (Obrigatória para validadores)
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/validation-tools/TEMPLATE-VALIDATOR.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/validation-tools/verify-constraints/README.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/validation-tools/check-rls/README.md
```

---

## 🗂️ ROTAS CANÔNICAS LOCAIS – Padrões pgvector (Para Acesso em Repo)

> **Formato**: `RAW_URL` → `./rota/local/en/repo`

### 📋 Padrões pgvector Core (10 artefatos)
```text
# Fundamentos e isolamento multi-tenant
06-PROGRAMMING/postgresql-pgvector/00-INDEX.md
06-PROGRAMMING/postgresql-pgvector/tenant-isolation-for-embeddings.pgvector.md

# Indexação e otimização
06-PROGRAMMING/postgresql-pgvector/vector-indexing-patterns.pgvector.md
06-PROGRAMMING/postgresql-pgvector/partitioning-strategies-for-high-dim.pgvector.md

# Busca híbrida e RAG
06-PROGRAMMING/postgresql-pgvector/hybrid-search-rls-aware.pgvector.md
06-PROGRAMMING/postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md
06-PROGRAMMING/postgresql-pgvector/nl-to-vector-query-patterns.pgvector.md

# Explicação e debugging
06-PROGRAMMING/postgresql-pgvector/similarity-explanation-templates.pgvector.md

# Migração e hardening
06-PROGRAMMING/postgresql-pgvector/migration-patterns-for-vector-schemas.pgvector.md
06-PROGRAMMING/postgresql-pgvector/hardening-verification.pgvector.md
06-PROGRAMMING/postgresql-pgvector/fix-sintaxis-code.pgvector.md
```

### 🦜 Referências Vetoriais (Consulta ONLY)
```text
06-PROGRAMMING/postgresql-pgvector/00-INDEX.md
06-PROGRAMMING/postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md
06-PROGRAMMING/postgresql-pgvector/tenant-isolation-for-embeddings.pgvector.md
```

### 🔄 Workflows e CI/CD
```text
04-WORKFLOWS/sdd-universal-assistant.json
.github/workflows/validate-mantis.yml
```

### 📚 Skills de Referência
```text
02-SKILLS/README.md
02-SKILLS/skill-domains-mapping.md
02-SKILLS/INFRASTRUCTURA/ssh-key-management.md
02-SKILLS/INFRASTRUCTURA/health-monitoring-vps.md
```

### 🌐 Documentação pt-BR
```text
docs/pt-BR/validation-tools/TEMPLATE-VALIDATOR.md
docs/pt-BR/validation-tools/verify-constraints/README.md
docs/pt-BR/validation-tools/check-rls/README.md
```

---

## 🧭 GUIA DE USO PARA O AGENTE PGVECTOR

```sql
-- Pseudocódigo: Como consultar padrões disponíveis em pgvector
-- (Implementado no agente, não em SQL puro)

-- Exemplo de validação de constraints antes de emitir query
-- Em aplicação host (Python/Go/JS):
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

-- Exemplo de detecção de LANGUAGE LOCK em query SQL
function contemOperadoresVetoriais(query) {
  return /<->[^a-zA-Z]|<#>[^a-zA-Z]|cosine_distance|l2_distance|hamming_distance/.test(query);
}

-- Uso no agente:
if (contemOperadoresVetoriais(inputQuery)) {
  console.error("LANGUAGE LOCK: Vector operators not allowed outside postgresql-pgvector/ domain");
  process.exit(1);
} else {
  // Gerar query SQL padrão com tenant isolation
  const query = `SELECT * FROM docs WHERE tenant_id = $1 AND status = 'active'`;
}

-- Exemplo de consulta de padrões disponíveis
function consultarPadraoPgvector(nomePadrao) {
  const baseRaw = "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/";
  const baseLocal = "./06-PROGRAMMING/postgresql-pgvector/";
  
  const filename = `${nomePadrao}.pgvector.md`;
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


## 🛡️ Hardening (Harness Norms v3.0 - Executável)
> **Propósito**: Implementação específica do domínio SQL/PLpgSQL com validação de entrada, fallback seguro, EXCEPTION handling, zero EXECUTE dinâmico não sanitizado.

### Validação de Entrada em Funções PL/pgSQL
```sql
-- ✅ Função helper para validar parâmetros de entrada (C3, C5)
CREATE OR REPLACE FUNCTION validate_input(
    p_param_name TEXT,
    p_param_value TEXT,
    p_allowed_pattern TEXT DEFAULT '.*',
    p_max_length INT DEFAULT 1000
) RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    -- C3: Rejeitar strings com possíveis injeções SQL
    IF p_param_value ~* '(;|--|/\*|\*/|''|")' THEN
        RAISE WARNING 'Input % contém caracteres potencialmente perigosos', p_param_name;
        RETURN FALSE;
    END IF;
    
    -- C5: Validar comprimento máximo
    IF length(p_param_value) > p_max_length THEN
        RAISE WARNING 'Input % excede comprimento máximo (% > %)', p_param_name, length(p_param_value), p_max_length;
        RETURN FALSE;
    END IF;
    
    -- C5: Validar padrão regex se fornecido
    IF p_allowed_pattern != '.*' AND p_param_value !~ p_allowed_pattern THEN
        RAISE WARNING 'Input % não corresponde ao padrão esperado: %', p_param_name, p_allowed_pattern;
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
EXCEPTION WHEN OTHERS THEN
    -- C7: Fallback seguro em caso de erro de validação
    RAISE WARNING 'Erro ao validar input %: %', p_param_name, SQLERRM;
    RETURN FALSE;
END;
$$;
```

### Fallback Seguro e EXCEPTION Handling Estruturado
```sql
-- ✅ Template de função com tratamento de erros estruturado (C7)
CREATE OR REPLACE FUNCTION safe_vector_operation(
    p_operation TEXT,
    p_input VECTOR(1536),
    p_tenant_id UUID
) RETURNS TABLE(result TEXT, success BOOLEAN, error_detail TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_result TEXT;
    v_start TIMESTAMPTZ := clock_timestamp();
BEGIN
    -- C4: Validar tenant_id antes de qualquer operação
    IF NOT validate_input('tenant_id', p_tenant_id::TEXT, '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', 36) THEN
        RETURN QUERY SELECT 'Invalid tenant_id'::TEXT, FALSE, 'tenant_id validation failed'::TEXT;
        RETURN;
    END IF;
    
    -- C7: Timeout configurável para operações pesadas
    SET LOCAL statement_timeout = '30s';
    
    -- Lógica principal da operação
    BEGIN
        -- Exemplo: operação vetorial segura
        SELECT format('Operation % completed', p_operation) INTO v_result;
        
        -- C8: Logging estruturado de sucesso
        RAISE LOG '%', json_build_object(
            'op', 'safe_vector_operation',
            'tenant', p_tenant_id,
            'operation', p_operation,
            'status', 'success',
            'duration_ms', EXTRACT(MILLISECOND FROM clock_timestamp() - v_start)
        );
        
        RETURN QUERY SELECT v_result, TRUE, NULL::TEXT;
        
    EXCEPTION
        WHEN query_canceled THEN
            -- C7: Tratamento específico para timeout
            RETURN QUERY SELECT 'Operation timed out'::TEXT, FALSE, 'statement_timeout exceeded'::TEXT;
        WHEN insufficient_privilege THEN
            -- C4: Tratamento para violação de tenant isolation
            RETURN QUERY SELECT 'Permission denied'::TEXT, FALSE, 'tenant isolation violation'::TEXT;
        WHEN OTHERS THEN
            -- C7: Fallback genérico com sanitização de erro
            RETURN QUERY SELECT 
                'Operation failed'::TEXT, 
                FALSE, 
                regexp_replace(SQLERRM, '(password|token|api_key|secret)[=:][^[:space:]]+', '\1=***REDACTED***', 'gi')::TEXT;
    END;
END;
$$;
```

### Zero EXECUTE Dinâmico Não Sanitizado
```sql
-- ✅ Pattern seguro para dynamic SQL em PL/pgSQL (C3, C5)
CREATE OR REPLACE FUNCTION safe_dynamic_query(
    p_table_name TEXT,
    p_column_name TEXT,
    p_filter_value TEXT,
    p_tenant_id UUID
) RETURNS TABLE(id BIGINT, content TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_safe_table TEXT;
    v_safe_column TEXT;
    v_query TEXT;
BEGIN
    -- C3: Validar nomes de tabela e coluna contra whitelist
    IF p_table_name NOT IN ('documents', 'document_embeddings', 'rag_audit_log') THEN
        RAISE EXCEPTION 'Tabela % não permitida em dynamic query', p_table_name;
    END IF;
    
    IF p_column_name NOT IN ('content', 'metadata', 'embedding_model') THEN
        RAISE EXCEPTION 'Coluna % não permitida em dynamic query', p_column_name;
    END IF;
    
    -- C5: Sanitizar para dynamic SQL seguro
    v_safe_table := quote_ident(p_table_name);
    v_safe_column := quote_ident(p_column_name);
    
    -- C4: Incluir tenant_id filter obrigatório
    v_query := format(
        'SELECT id, content FROM %I WHERE %I = $1 AND tenant_id = $2',
        v_safe_table, v_safe_column
    );
    
    -- Executar query parametrizada (nunca concatenar valores diretamente)
    RETURN QUERY EXECUTE v_query USING p_filter_value, p_tenant_id;
    
EXCEPTION WHEN OTHERS THEN
    -- C7: Logging de erro com sanitização
    RAISE LOG '%', json_build_object(
        'op', 'safe_dynamic_query',
        'error', regexp_replace(SQLERRM, '(password|token|api_key)', '\1=***', 'gi'),
        'tenant', p_tenant_id
    );
    RAISE;
END;
$$;
```

### Resource Limits e Timeouts Configuráveis (C1, C7)
```sql
-- ✅ Função para aplicar limites de recursos por operação (C1)
CREATE OR REPLACE FUNCTION apply_resource_limits(
    p_operation_type TEXT,
    p_tenant_id UUID
) RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_work_mem TEXT;
    v_statement_timeout TEXT;
    v_max_parallel_workers INT;
BEGIN
    -- C1: Definir limites baseados no tipo de operação
    CASE p_operation_type
        WHEN 'vector_index_build' THEN
            v_work_mem := '512MB';
            v_statement_timeout := '300s';
            v_max_parallel_workers := 4;
        WHEN 'rag_query' THEN
            v_work_mem := '128MB';
            v_statement_timeout := '30s';
            v_max_parallel_workers := 2;
        WHEN 'embedding_insert' THEN
            v_work_mem := '256MB';
            v_statement_timeout := '60s';
            v_max_parallel_workers := 2;
        ELSE
            v_work_mem := '64MB';
            v_statement_timeout := '15s';
            v_max_parallel_workers := 1;
    END CASE;
    
    -- Aplicar limites para esta sessão
    EXECUTE format('SET LOCAL work_mem = %L', v_work_mem);
    EXECUTE format('SET LOCAL statement_timeout = %L', v_statement_timeout);
    EXECUTE format('SET LOCAL max_parallel_workers_per_gather = %L', v_max_parallel_workers);
    
    -- C8: Logging dos limites aplicados
    RAISE LOG '%', json_build_object(
        'op', 'apply_resource_limits',
        'tenant', p_tenant_id,
        'operation', p_operation_type,
        'work_mem', v_work_mem,
        'statement_timeout', v_statement_timeout,
        'max_parallel_workers', v_max_parallel_workers
    );
END;
$$;
```

---

## 🔍 Observability Integration (OpenTelemetry Native)

> **Propósito**: Definir a função canônica `mantis_log()` em PL/pgSQL e seu mapeamento à infraestrutura de observabilidade do projeto MANTIS.

### Função Canônica: `mantis_log()` (V-LOG-02 + C8 + PII Scrubbing)
```sql
-- Assinatura canônica atualizada (definida aqui, herdada por todos os artefatos)
CREATE OR REPLACE FUNCTION mantis_log(
  p_level TEXT DEFAULT 'INFO',        -- DEBUG|INFO|WARN|ERROR|FATAL
  p_event TEXT DEFAULT 'unknown',     -- Nome do evento (ex: "vector_index_created")
  p_detail TEXT DEFAULT ''            -- Descrição livre ou JSON stringificado
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER  -- ✅ C6: executa com privilégios do definidor
SET search_path = ''  -- ✅ C6: evitar injeção via search_path
AS $$
DECLARE
  v_sanitized_detail TEXT;
  v_tenant_id UUID;
  v_artifact_id TEXT;
  v_trace_id TEXT;
BEGIN
  -- C3: Sanitização automática de dados sensíveis (PII Scrubbing)
  v_sanitized_detail := regexp_replace(
    p_detail,
    '(password|token|api_key|secret|key|auth)[=:][^[:space:]]+',
    '\1=***REDACTED***',
    'gi'
  );
  
  -- Variáveis de contexto (obrigatórias no entorno do artefato)
  v_tenant_id := current_setting('app.current_tenant', true)::UUID;
  v_artifact_id := current_setting('app.artifact_id', true);
  v_trace_id := current_setting('app.trace_id', true);
  
  -- V-LOG-02: Schema JSONL completo para Loki/Grafana + OTel mappable
  RAISE LOG '%', json_build_object(
    'timestamp', to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
    'level', p_level,
    'resource', json_build_object(
      'tenant_id', COALESCE(v_tenant_id, 'unknown'),
      'artifact', COALESCE(v_artifact_id, 'unknown')
    ),
    'body', json_build_object(
      'event', p_event,
      'detail', v_sanitized_detail
    ),
    'attributes', json_build_object(
      'mantis', json_build_object(
          'tier', current_setting('app.tier', true),
          'version', current_setting('app.version', true),
          'constraint', current_setting('app.constraint', true),
          'trace_id', COALESCE(v_trace_id, ''),
          'span_id', current_setting('app.span_id', true),
          'parent_span_id', current_setting('app.parent_span_id', true)
      ),
      'code.filepath', current_setting('app.code.filepath', true),
      'code.lineno', current_setting('app.code.lineno', true),
      'telemetry.sdk.name', 'mantis-plpgsql-adapter',
      'telemetry.sdk.version', '1.0.0'
    )
  );
EXCEPTION WHEN OTHERS THEN
  -- Fallback resiliente (C7): log mínimo se schema completo falhar
  RAISE LOG '{"ts":"%s","level":"%s","event":"%s","fallback":"true","error":"%s"}',
    to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
    'ERROR',
    'mantis_log_failed',
    SQLERRM;
END;
$$;
```

### Validação de Schema V-LOG-02 (Helper Executável)

> **Propósito**: Permitir validação local de logs antes de ingestão em Loki. Executável por IA ou humano.

```sql
-- Função helper para validar schema V-LOG-02 (pode ser chamada em testes)
CREATE OR REPLACE FUNCTION validate_vlog02(p_json TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
  v_doc JSONB;
BEGIN
  v_doc := p_json::JSONB;
  
  RETURN 
    v_doc ? 'timestamp' AND
    v_doc ? 'level' AND
    v_doc->'resource' ? 'tenant_id' AND
    v_doc->'resource' ? 'artifact' AND
    v_doc->'body' ? 'event' AND
    v_doc->'attributes'->'mantis' ? 'tier' AND
    v_doc->'attributes'->'mantis' ? 'version' AND
    v_doc->>'timestamp' ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$' AND
    v_doc->>'level' IN ('DEBUG','INFO','WARN','ERROR','FATAL');
EXCEPTION WHEN OTHERS THEN
  RETURN FALSE;
END;
$$;

-- Uso em testes unitários:
-- SELECT validate_vlog02('{"timestamp":"2026-05-08T00:00:00Z","level":"INFO","resource":{"tenant_id":"uuid"},"body":{"event":"test"}}');
```

### Stub de Bootstrap para `mantis_log()` (Fallback Resiliente - C7)

> **Propósito**: Garantir que artefatos filhos possam emitir logs auditáveis mesmo se a função principal não estiver disponível.

```sql
-- Inserir no início de cada artefato filho (após BEGIN, antes de lógica)
DO $$
BEGIN
  -- Tentar usar a função canônica se existir
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'mantis_log') THEN
    PERFORM mantis_log('INFO', 'bootstrap', 'Master agent function available');
  ELSE
    -- Fallback minimalista: logging funcional sem dependências externas
    RAISE LOG '{"ts":"%s","level":"%s","tenant":"%s","event":"%s","detail":"%s","fallback":"true"}',
      to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
      'WARN',
      COALESCE(current_setting('app.current_tenant', true), 'unknown'),
      'bootstrap_fallback',
      'mantis_log() não encontrada. Logging em modo degradado.';
  END IF;
END $$;
```

### Mapeo a OpenTelemetry (OTLP)
| Campo JSONL | Atributo OTel | Propósito em Dashboards |
|-------------|-------------|------------------------|
| `timestamp` | `time_unix_nano` | Ordenamento temporal em traces/logs |
| `resource.tenant_id` | `resource.attributes["tenant.id"]` | Filtrado e isolamento por tenant |
| `resource.artifact` | `resource.attributes["mantis.artifact"]` | Correlação com artefato gerador |
| `body.event` | `body` (log) ou `attributes["event.name"]` (trace) | Identificação do tipo de evento |
| `attributes.mantis.constraint` | `attributes["mantis.constraint"]` | Auditoria de cumprimento contratual |
| `attributes.mantis.trace_id` | `trace_id` | Correlação em traces distribuídos |
| `attributes.code.filepath/lineno` | `code.filepath` / `code.lineno` | Debugging preciso em traces distribuídos |

### Configuração por Variáveis de Entorno
```sql
-- Variáveis reconhecidas por mantis_log() (documentadas para IA)
-- Definir via SET app.* ou em connection string:
-- SET app.current_tenant = 'uuid';
-- SET app.artifact_id = 'pgvector-extension-setup';
-- SET app.trace_id = 'otel-trace-xyz';
-- SET app.tier = '2';
-- SET app.version = '2.2.0';
-- SET app.constraint = 'C4,V1,V3';
-- SET app.code.filepath = '06-PROGRAMMING/postgresql-pgvector/extension-setup.pgvector.md';
-- SET app.code.lineno = '42';
```

### Referencias a Infraestructura Existente
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]] ← Índice de observabilidade
- [[/05-CONFIGURATIONS/observability/loki/config.yml]] ← Configuração de ingestão de logs
- [[/05-CONFIGURATIONS/observability/otel-tracing-config.yaml]] ← Configuração de traces OTLP
- [[/05-CONFIGURATIONS/observability/grafana/dashboards/core-postgresql-pgvector.json]] ← Dashboard principal
- [[/05-CONFIGURATIONS/observability/alerts/vector-alerts.yml]] ← Alertas baseadas em logs

---

## 🔍 Observability (Documentación para IA)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `vector_index_created` | INFO | C8,V3 | `"index=idx_embeddings_hnsw, dims=1536, metric=cosine"` |
| `rls_policy_applied` | INFO | C4 | `"table=tenant_embeddings, policy=tenant_isolation"` |
| `embedding_validation_failed` | ERROR | V1 | `"expected_dims=1536, got=768, model=text-embedding-3-small"` |
| `query_timeout_exceeded` | WARN | C7 | `"query_id=rag-search-xyz, duration_ms=32000, limit_ms=30000"` |
| `secret_detected_in_query` | ERROR | C3 | `"pattern=api_key=sk-*, line=42, artifact=rag-query.pgvector.md"` |
| `migration_completed` | INFO | C6,C8 | `"from_version=1.0, to_version=2.0, tenant_id=uuid, duration_ms=1250"` |

### Validação de Schema V-LOG-02
```sql
-- Executar em teste: SELECT validate_vlog02('{"timestamp":"2026-05-08T00:00:00Z","level":"INFO","resource":{"tenant_id":"uuid"},"body":{"event":"test"}}');
-- Retorno esperado: t (true) se schema válido, f (false) caso contrário
```

---

## 🔗 Grafo de Inter-relações: Domínio postgresql-pgvector MANTIS
*(Estrutura topológica estratificada por Tiers. Todos os 22 artefatos mapeados com cores opacas para legibilidade.)*

```mermaid
---
config:
  theme: base
  themeVariables:
    primaryColor: '#1a1a2e'
    primaryTextColor: '#ffffff'
    primaryBorderColor: '#E0AF68'
    lineColor: '#E0AF68'
    secondaryColor: '#16213e'
    tertiaryColor: '#0f3460'
    fontSize: '14px'
---
graph TD
  %% Class Definitions (Inmutables por Tier)
  classDef foundation fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:3px
  classDef security fill:#16213e,color:#fff,stroke:#E0AF68,stroke-width:2px
  classDef operations fill:#0f3460,color:#fff,stroke:#E0AF68,stroke-width:2px
  classDef integration fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:2px,stroke-dasharray: 5 5
  classDef existing fill:#2a2a4e,color:#fff,stroke:#7f7f7f,stroke-width:1px
  
  %% Nodo Central
  MASTER["🧠 postgresql-pgvector-rag-master-agent.md<br/>(Fonte de Verdade)"]:::foundation

  %% Tier M0: Fundamentos Críticos (4 artefatos)
  M0_SETUP["📦 pgvector-extension-setup.pgvector.md<br/>(Setup seguro da extensão)"]:::foundation
  M0_DIMS["📐 embedding-dimension-selection.pgvector.md<br/>(Seleção de dimensões)"]:::foundation
  M0_INDEX["⚙️ vector-index-strategy-comparison.pgvector.md<br/>(HNSW vs IVFFlat)"]:::foundation
  M0_VERIFY["✅ hardening-verification.pgvector.md<br/>(Verificação de constraints)"]:::foundation

  %% Tier M1: Segurança/Tenant (4 artefatos existentes)
  M1_ISOLATION["🔒 tenant-isolation-for-embeddings.pgvector.md<br/>(Isolamento multi-tenant)"]:::security
  M1_RLS["👤 rag-query-with-tenant-enforcement.pgvector.md<br/>(Enforcement de tenant em RAG)"]:::security
  M1_METADATA["🏷️ vector-metadata-tenant-scoping.pgvector.md<br/>(Filtrado por metadados + tenant)"]:::security
  M1_FIX["🔧 fix-syntax-code.pgvector.md<br/>(Correção de anti-padrões sintáticos)"]:::security

  %% Tier M2: Operações/Índices (5 artefatos existentes + 2 planejados)
  M2_INDEXING["🔍 vector-indexing-patterns.pgvector.md<br/>(Padrões de indexação HNSW/IVFFlat)"]:::operations
  M2_PARTITION["📊 partitioning-strategies-for-high-dim.pgvector.md<br/>(Particionamento por tenant/dimensão)"]:::operations
  M2_BATCH["⚡ embedding-batch-insert-optimization.pgvector.md<br/>(Inserção em lote com COPY)"]:::operations
  M2_UPDATE["🔄 embedding-update-strategies.pgvector.md<br/>(Upsert, reindex, versionamento)"]:::operations
  M2_PIPELINE["🔗 embedding-generation-pipeline.pgvector.md<br/>(Pipeline async com retry/timeout)"]:::operations
  M2_HYBRID["🔀 hybrid-search-scalar-vector.pgvector.md<br/>(Filtros escalares + vetores)"]:::operations
  M2_RERANK["🎯 reranking-post-filtering.pgvector.md<br/>(Cross-encoder pós-filtrado)"]:::operations

  %% Tier M3: Integração/RAG (4 artefatos existentes + 3 planejados)
  M3_HYBRID_RLS["🔍 hybrid-search-rls-aware.pgvector.md<br/>(Busca híbrida com RLS)"]:::integration
  M3_NL2SQL["💬 nl-to-vector-query-patterns.pgvector.md<br/>(NL-to-SQL com validação de tenant)"]:::integration
  M3_EXPLAIN["📝 similarity-explanation-templates.pgvector.md<br/>(Explicabilidade de similaridade)"]:::integration
  M3_MIGRATION["🚚 migration-patterns-for-vector-schemas.pgvector.md<br/>(Migração com zero downtime)"]:::integration
  M3_EXPANSION["🔍 query-expansion-for-rag.pgvector.md<br/>(HyDE, multi-query, documentos hipotéticos)"]:::integration
  M3_MULTIVEC["🧩 multi-vector-representation.pgvector.md<br/>(Chunking, ColBERT-style, late interaction)"]:::integration
  M3_INDEX["📚 00-INDEX.md<br/>(Índice canônico do domínio)"]:::integration

  %% Topologia de Dependências (Obrigatória)
  MASTER --> M0_SETUP
  MASTER --> M0_DIMS
  MASTER --> M0_INDEX
  MASTER --> M0_VERIFY
  
  M0_SETUP --> M1_ISOLATION
  M0_DIMS --> M0_INDEX
  M0_INDEX --> M2_INDEXING
  M0_VERIFY --> M1_FIX
  
  M1_ISOLATION --> M1_RLS
  M1_ISOLATION --> M1_METADATA
  M1_RLS --> M3_HYBRID_RLS
  M1_METADATA --> M2_HYBRID
  
  M2_INDEXING --> M2_PARTITION
  M2_INDEXING --> M2_BATCH
  M2_BATCH --> M2_UPDATE
  M2_PIPELINE --> M2_BATCH
  M2_HYBRID --> M2_RERANK
  
  M3_HYBRID_RLS --> M3_NL2SQL
  M3_NL2SQL --> M3_EXPANSION
  M3_EXPANSION --> M3_MULTIVEC
  M3_MIGRATION --> M2_PARTITION
  M3_EXPLAIN --> M3_NL2SQL
  
  M2_INDEXING --> M3_INDEX
  M1_ISOLATION --> M3_INDEX
  MASTER --> M3_INDEX

  %% Estilo Central
  style MASTER fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:4px

  %% Regra de Instanciação (Comentário para IA)
  %% • Cores opacas (#1a1a2e, #16213e, #0f3460, #2a2a4e) garantem legibilidade do texto branco
  %% • Setas sólidas = dependências obrigatórias de carga de contexto
  %% • Setas tracejadas = handoff para outros domínios (ver grafo LANGUAGE LOCK)
  %% • Nunca remover nós ou arestas sem revisão de arquitetura
```

---

## 🧭 Fluxo de Trabalho do Agente SQL/PLpgSQL
*(Pipeline SDD/TDD/VDD estandarizado. Bloqueia generación si qualquer estágio falhar na validação JSON.)*

```mermaid
---
config:
  theme: base
  themeVariables:
    primaryColor: '#1a1a2e'
    primaryTextColor: '#ffffff'
    primaryBorderColor: '#E0AF68'
    lineColor: '#E0AF68'
    secondaryColor: '#16213e'
    tertiaryColor: '#0f3460'
    fontSize: '14px'
---
stateDiagram-v2
  [*] --> Especificação: norms-matrix.json + prompt + raw URLs
  Especificação --> Geração: postgresql-pgvector Master Agent (este documento)
  Geração --> Frontmatter: Adicionar contrato YAML obrigatório
  Frontmatter --> Hardening: Inserir SQL/PLpgSQL-specific hardening, EXCEPTION handling, timeouts
  Hardening --> TDD: Adicionar testes unitários padrão Arrange-Act-Assert
  TDD --> Validação: orchestrator-engine --json --checks C1-C8,V1-V3
  Validação --> Aprovado: passed=true
  Validação --> Rejeitado: passed=false
  Rejeitado --> Diagnóstico: Ler issues_by_severity no output JSON
  Diagnóstico --> Correção: Aplicar fix_hint por constraint violada
  Correção --> Validação
  Aprovado --> Registro: CHRONICLE.md + git commit com hash
  Registro --> [*]

  note right of Validação
    Output JSON esperado:
    {
      "validator": "orchestrator-engine",
      "file": "06-PROGRAMMING/postgresql-pgvector/...",
      "passed": true,
      "constraints_checked": ["C1","C3","C4","C5","C7","V1","V2","V3"],
      "performance_ms": 142.7
    }
  end note

  classDef process fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:2px
  class Especificação,Geração,Frontmatter,Hardening,TDD,Validação,Aprovado,Rejeitado,Diagnóstico,Correção,Registro process
```

---

## 🔗 Conexões com Outros Domínios (LANGUAGE LOCK)
*(Protocolo de handoff explícito. Sólidas = dependências internas do framework. Tracejadas = handoff para outros master agents.)*

```mermaid
---
config:
  theme: base
  themeVariables:
    primaryColor: '#1a1a2e'
    primaryTextColor: '#ffffff'
    primaryBorderColor: '#E0AF68'
    lineColor: '#E0AF68'
    secondaryColor: '#16213e'
    tertiaryColor: '#0f3460'
    fontSize: '14px'
---
graph LR
  Master["🧠 postgresql-pgvector-rag-master-agent.md<br/>Domínio: postgresql-pgvector"] --> Core["🧠 mantis-core-context.md<br/>Constraints C1-C8"]
  Master --> Rules["📜 harness-norms-v3.0.md<br/>Hardening padrão"]
  Master --> Orchestrator["⚙️ orchestrator-engine/main.go<br/>Validação automatizada"]
  Master --> ExtPython["🐍 python/<br/>Lógica complexa de embedding"]
  Master --> ExtGo["🔷 go/<br/>Microserviços de alta performance"]
  Master --> ExtBash["🐚 bash/<br/>Orquestração e validação de shell"]

  Core -.->|Define contrato C1-C8| Master
  Rules -.->|Especifica hardening mínimo| Master
  Orchestrator -.->|Valida artefatos via JSON| Master
  ExtPython -.->|Recebe handoff de geração de embeddings| Master
  ExtGo -.->|Recebe handoff de serviços de busca distribuída| Master
  ExtBash -.->|Recebe handoff de validação e deployment| Master

  %% LANGUAGE LOCK: postgresql-pgvector NÃO gera código destes domínios
  %% Handoff explícito via bloco JSON documentado no template interno

  style Master fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:4px
  style Core fill:#16213e,color:#fff,stroke:#7f7f7f,stroke-width:1px
  style Rules fill:#16213e,color:#fff,stroke:#7f7f7f,stroke-width:1px
  style Orchestrator fill:#16213e,color:#fff,stroke:#7f7f7f,stroke-width:1px
  style ExtPython fill:#0f3460,color:#fff,stroke:#7f7f7f,stroke-width:1px,stroke-dasharray: 3 3
  style ExtGo fill:#0f3460,color:#fff,stroke:#7f7f7f,stroke-width:1px,stroke-dasharray: 3 3
  style ExtBash fill:#0f3460,color:#fff,stroke:#7f7f7f,stroke-width:1px,stroke-dasharray: 3 3
```

---

### 📐 Mapeo de Instanciação por Domínio (Para os 7 Master Agents)

| Placeholder | `bash` | `python` | `go` | `javascript` | `yaml-json-schema` | `sql` | `postgresql-pgvector` |
|-------------|--------|----------|------|--------------|-------------------|-------|----------------------|
| `{DOMAIN}` | `bash` | `python` | `go` | `javascript` | `yaml-json-schema` | `sql` | `postgresql-pgvector` |
| `{LANGUAGE}` | `Bash` | `Python` | `Go` | `JavaScript/TypeScript` | `YAML/JSON` | `SQL` | `PLpgSQL/SQL` |
| `M2_JSON`/`M2_YAML` | `json-processing-with-jq.md` / `yaml-processing-with-yq.md` | `pydantic-schema-validator.md` / `toml-config-parser.md` | `go-json-unmarshal.md` / `yaml-decoder-strict.md` | `json-ajv-validation.md` / `yaml-parser-safe.md` | `schema-draft7-validator.md` / `json-path-query.md` | `jsonb-operators.md` / `yaml-to-sql-migration.md` | `vector-json-metadata.md` / `pg-yaml-config.md` |
| `Ext*` Handoffs | `python`, `go`, `postgresql-pgvector` | `bash`, `go`, `sql` | `bash`, `python`, `postgresql-pgvector` | `python`, `bash`, `sql` | `bash`, `python`, `sql` | `bash`, `go`, `postgresql-pgvector` | `bash`, `python`, `go` |

---

## 🔄 Protocolo de Handoff para Outros Domínios (LANGUAGE LOCK)
### Quando Delegar (Regra Imutável)
- 🚫 SQL/PLpgSQL NUNCA gera código de domínios externos sem handoff JSON.
- ✅ SQL/PLpgSQL PODE gerar orquestração, validação estática, wrappers seguros e logging.

### Regras de Handoff (Validáveis)
1. Incluir `tenant_id` no payload (C4)
2. Especificar `timeout_seconds` (C1)
3. Documentar `expected_output` (C5)
4. Zero hardcode de secrets (C3)
5. Registrar handoff em log estruturado (C8)

## 📊 Métricas de Qualidade do Agente SQL/PLpgSQL
| Métrica | Meta | Como Medir | Ferramenta |
|---------|------|-----------|-----------|
| Pass Rate em Validação | ≥95% | `orchestrator-engine --json` | orchestrator-engine |
| Tempo Médio de Validação | ≤200ms | `performance_ms` nos logs | Prometheus/Grafana |
| Taxa de Handoff Correto | 100% | Auditoria de blocos `HANDOFF_JSON` | audit-handoff-hook.sh |
| Zero Secrets em Produção | 100% | `audit-secrets.sh` | audit-secrets.sh |
| Compliance V1/V2/V3 | 100% | `verify-constraints.sh --check-vector-*` | verify-constraints.sh |

## 🚫 Anti-Padrões – O Que Nunca Gerar (Lista Executável)
*(Específico do domínio SQL/PLpgSQL. Proibido: EXECUTE dinâmico não sanitizado, variáveis sem proteção, logs textuais, ausência de EXCEPTION handling.)*
- ❌ `EXECUTE format('SELECT * FROM %I', user_input)` sem validação de whitelist
- ❌ `CREATE INDEX ... USING hnsw (...)` sem parámetros `m`, `ef_construction` documentados (V3)
- ❌ `VECTOR` sem dimensão explícita `VECTOR(1536)` (V1)
- ❌ Operador `<=>` sem documentação da métrica (cosine, l2, inner_product) (V2)
- ❌ Queries sem `WHERE tenant_id = $1` ou política RLS (C4)
- ❌ API keys hardcoded em funções SQL (C3)
- ❌ Logging com `RAISE NOTICE` sem schema JSONL V-LOG-02 (C8)

## 📋 Checklist de Geração – Antes de Commit (Executável)
1. ✅ Frontmatter YAML válido (C5)
2. ✅ Hardening mínimo aplicado (C7)
3. ✅ Validação de tenant presente (se aplicável) (C4)
4. ✅ `mantis_log()` implementada e validada (C8)
5. ✅ Tests TDD passam (`--test` flag)
6. ✅ `orchestrator-engine --json` retorna `passed: true`
7. ✅ Constraints vetoriais V1/V2/V3 declaradas e justificadas
8. ✅ LANGUAGE LOCK verificado: zero operadores vetoriais fora deste domínio
9. ✅ Contexto A2A inicializado: `trace_id` e `span_id` definidos via parâmetros de sessão (C9).
10. ✅ `status.json` escrito pelo script wrapper após a execução (C9).
11. ✅ Validação C9 via `./goals/check-a2a-contract.sh` executada com sucesso (exit 0).


## 🗓️ Integração com CHRONICLE.md (Auditoria Distribuída)
### Formato de Registro Padrão (JSONL)
```json
{"timestamp":"2026-05-08T00:00:00Z","event":"artifact_regenerated","artifact_id":"postgresql-pgvector-master-agent-mantis","version":"2.2.0","author":"postgresql-pgvector-master-agent","constraints":["C1","C2","C3","C4","C5","C6","C7","C8","V1","V2","V3"],"validation_passed":true,"hash":"sha256:framework-executable-contract-v2.2.0","next_review":"2026-06-08","ai_compatibility":["qwen","deepseek","claude","minimax","mimo-xiaomi"],"notes":"Remanufatura com grafos Mermaid completos, observabilidade V-LOG-02, e 22 artefatos mapeados"}
```
### Comandos de Consulta Úteis
```bash
grep '"artifact_id":"postgresql-pgvector-master-agent-mantis"' CHRONICLE.md | jq -s
bash 05-CONFIGURATIONS/scripts/verify-chronicle-hashes.sh --artifact postgresql-pgvector-master-agent-mantis
```

## 🌐 Compatibilidade Multi-IA: Diretrizes de Ingestão
### Para IAs de Contexto Amplo
- ✅ Ingestão integral permitida. Mermaid e YAML renderizáveis nativamente.
### Para IAs de Contexto Restrito
- ⚠️ Priorizar: Frontmatter, Template Interno, Anti-Padrões, Bloco de Pensamento.
### Protocolo de Fallback (Universal)
- Extrair metadados via `grep` para variáveis de ambiente. Validar constraints via `orchestrator-engine` headless.

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-01 | PostgreSQL-PgVector Master Agent | Criação inicial: padrões RAG, tenant isolation, índices HNSW | C4,V1,V2,V3 |
| 2.2.0 | 2026-05-08 | PostgreSQL-PgVector Master Agent (Remanufatura) | Integração template canônico: deterministic_config, mantis_log() PL/pgSQL, 3 grafos Mermaid com 22 artefatos, observabilidade V-LOG-02, hardening executável | C1-C8,V1-V3 |

---

## 🔍 Observability (Documentación para IA)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `artifact_regenerated` | INFO | C8 | `"version=2.2.0, artifacts_mapped=22, graphs_updated=3"` |
| `mantis_log_validated` | INFO | C8,V-LOG-02 | `"schema=V-LOG-02, fields=9, pii_scrubbing=active"` |
| `mermaid_graph_rendered` | INFO | C5 | `"graph=inter-relations, nodes=22, edges=35, colors=opaque"` |
| `language_lock_verified` | INFO | LANGUAGE-LOCK | `"domain=postgresql-pgvector, vector_operators=isolated"` |

### Validação de Schema V-LOG-02
```sql
-- Executar em teste: SELECT validate_vlog02('{"timestamp":"2026-05-08T00:00:00Z","level":"INFO","resource":{"tenant_id":"uuid"},"body":{"event":"test"}}');
-- Retorno esperado: t (true) se schema válido, f (false) caso contrário
```
---
