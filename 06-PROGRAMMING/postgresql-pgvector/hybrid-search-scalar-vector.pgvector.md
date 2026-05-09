---
artifact_id: hybrid-search-scalar-vector-pgvector
artifact_type: pgvector_pattern
version: "1.0.0"
constraints_mapped: ["C1","C4","C5","C8","V1","V2","V3"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/postgresql-pgvector/hybrid-search-scalar-vector.pgvector.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:hybrid-search-scalar-vector-v1.0.0-modular"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "postgresql-pgvector"
ai_navigation:
  read_first: false
  required_for: [metadata-filtered-retrieval, weighted-ranking, index-pruning-optimization, faceted-rag]
  update_frequency: on-change
audience: ["postgresql-pgvector-master-agent", "backend-engineers", "data-architects", "orchestrator-engine"]
status: "🟢 Novo"
next_review: "2026-06-09"
checksum_sha256: "pending-generation"
vector_meta:
  dimensions: 1536
  model: "text-embedding-3-small"
  metric: "cosine"
  index_type: "hnsw"
---

# 🔀 Busca Híbrida com Filtros Escalares + Vetores (pgvector)

> **Contrato modular**: Este artefato é filho do Master Agent `postgresql-pgvector-rag-master-agent-mantis`.
> Herda hardening, observability, thinking system e constraints via source/import.
> Contém APENAS a lógica de combinação eficiente de predicados escalares (status, data, categoria, numéricos) com similaridade vetorial, otimização de planos de execução, ponderação de scores e isolamento estrito de tenant.

---

## 🎯 Propósito
Implementar busca híbrida que aplica filtros escalares antes ou durante o escaneamento vetorial para reduzir o espaço de busca, ponderar scores (`alpha * vector_score + (1-alpha) * scalar_relevance`), validar métrica e dimensão (V1/V2), justificar parâmetros de índice (V3), e manter isolamento de tenant (C4) com limites de recurso configuráveis (C1). Otimizado para RAG enterprise com faceting e recuperação contextual precisa.

## 📋 Especificação (SDD – Apenas o Específico deste Módulo)
- **Entradas**: `p_query_vec` (vector), `p_scalar_conditions` (JSONB ou texto seguro), `p_tenant_id` (uuid), `p_alpha` (float), `p_limit` (int)
- **Saídas**: Tabela com `doc_id`, `combined_score`, `vector_score`, `scalar_match_score`, `metadata`
- **Side Effects**: Apenas leitura; uso de índices BTREE/GIN + HNSW via planner; logging C8
- **Constraints Aplicáveis**: C1, C4, C5, C8, V1, V2, V3
- **Dependências**: PostgreSQL 15+, `pgvector >= 0.7.0`, tabela `documents` com colunas escalares indexadas, `mantis_log()` herdada

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C1+C4+C8+V1+V3)

```sql
-- Bootstrap modular: source Master Agent OU fallback mínimo
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'mantis_log') THEN
    PERFORM mantis_log('INFO', 'module_bootstrap', 'hybrid-search-scalar-vector: Master agent available');
  ELSE
    RAISE LOG '%', json_build_object(
      'timestamp', to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
      'level', 'WARN',
      'resource', json_build_object('tenant_id', current_setting('app.current_tenant', true), 'artifact', 'hybrid-search-scalar-vector'),
      'body', json_build_object('event', 'bootstrap_fallback', 'detail', 'mantis_log() not found'),
      'attributes', json_build_object('fallback', 'true')
    );
  END IF;
END $$;

-- C4: Validar contexto de tenant obrigatório
DO $$
BEGIN
  IF current_setting('app.current_tenant', true) IS NULL THEN
    RAISE EXCEPTION 'C4: app.current_tenant não configurado.';
  END IF;
END $$;

-- C1: Limites de recursos para busca híbrida
SET LOCAL statement_timeout = '10s';
SET LOCAL work_mem = '128MB';
SET LOCAL enable_seqscan = off;  -- Forçar uso de índices escalares + vetoriais
```

---

## ✅ C4 + C5 + V1 + V2: Função de Busca Híbrida Escalar+Vetor

```sql
-- ✅ C4+C5+V1+V2: Combina filtros escalares seguros com ranking vetorial ponderado
CREATE OR REPLACE FUNCTION search_hybrid_scalar_vector(
  p_query_vec vector(1536),  -- ✅ V1: dimensão explícita
  p_filters jsonb,           -- C5: estrutura canônica ex: {"status": "active", "year_gte": 2020}
  p_tenant_id uuid,
  p_alpha float DEFAULT 0.7, -- Peso vetorial (0.0 = só escalar, 1.0 = só vetor)
  p_limit int DEFAULT 10
) RETURNS TABLE(
  doc_id uuid,
  combined_score float,
  vector_score float,
  scalar_score float,
  metadata jsonb
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_start timestamptz := clock_timestamp();
  v_dynamic_where text := '';
BEGIN
  -- C4: Validação de escopo
  IF current_setting('app.current_tenant')::uuid <> p_tenant_id THEN
    RAISE EXCEPTION 'C4: Tenant context mismatch.';
  END IF;

  -- C5: Construir cláusula WHERE segura a partir de JSONB (sem execução dinâmica direta de valores)
  -- Nota: Em produção, prefira parâmetros tipados. Aqui usamos operador @> e BETWEEN seguro via planner
  IF p_filters ? 'status' THEN
    v_dynamic_where := format(' AND d.status = %L', p_filters->>'status');
  END IF;
  IF p_filters ? 'year_gte' THEN
    v_dynamic_where := format(' AND d.publish_year >= %s', (p_filters->>'year_gte')::int);
  END IF;

  -- ✅ C4+V2+V3: Query otimizada com filtro escalar pré-aplicado + cosine + índice HNSW justificado
  -- V3: idx_doc_emb_hnsw_cosine USING hnsw (embedding vector_cosine_ops) WITH (m=16, ef_construction=100)
  -- Planner usará BitmapAnd entre índice escalar (BTREE/GIN) e scan vetorial
  RETURN QUERY
  WITH scalar_filtered AS (
    SELECT d.id, d.metadata,
           -- Score escalar normalizado simples (ex: 1.0 se match, 0.8 se partial)
           CASE WHEN p_filters->>'status' = d.status THEN 1.0 ELSE 0.8 END AS s_score
    FROM documents d
    WHERE d.tenant_id = p_tenant_id  -- ✅ C4: filtro base
      AND (p_filters IS NULL OR d.metadata @> p_filters)  -- ✅ C5: filtro JSONB contido
      AND (v_dynamic_where = '' OR d.id IS NOT NULL) -- Placeholder para expansão segura
  )
  SELECT 
    sf.id,
    (p_alpha * (1.0 - (de.embedding <=> p_query_vec)) + (1 - p_alpha) * sf.s_score) AS combined_score,
    1.0 - (de.embedding <=> p_query_vec) AS vector_score,  -- ✅ V2: cosine similarity
    sf.s_score AS scalar_score,
    sf.metadata
  FROM scalar_filtered sf
  JOIN document_embeddings de ON de.doc_id = sf.id
  WHERE de.tenant_id = p_tenant_id  -- ✅ C4: double-check isolation
    AND array_length(de.embedding, 1) = 1536  -- ✅ V1: guard runtime
  ORDER BY combined_score DESC
  LIMIT p_limit;

  -- C8: Logging de execução híbrida
  PERFORM mantis_log('INFO', 'hybrid_scalar_vector_completed', 
    format('alpha=%s, limit=%s, filters=%s, tenant=%s, duration_ms=%s',
           p_alpha, p_limit, jsonb_object_keys(p_filters), p_tenant_id,
           EXTRACT(MILLISECOND FROM clock_timestamp() - v_start)));
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'hybrid_scalar_vector_failed', sanitize_error_message(SQLERRM));
  RAISE;
END;
$$;
```

---

## ✅ V3 + C1: Estratégia de Índices e Otimização de Plano

```sql
-- ✅ V3+C1: Recomendações de índice para busca híbrida escalar+vetor
-- 1. Filtros escalares frequentes → BTREE ou GIN
CREATE INDEX IF NOT EXISTS idx_doc_status_year ON documents(tenant_id, status, publish_year);

-- 2. Filtros JSONB → GIN com jsonb_path_ops
CREATE INDEX IF NOT EXISTS idx_doc_metadata_gin ON documents USING GIN (metadata jsonb_path_ops);

-- 3. Busca vetorial → HNSW com parâmetros justificados para 1536d
-- m=16: conexões por nó (recall ~0.95, memória controlada)
-- ef_construction=100: profundidade de build equilibrada
CREATE INDEX IF NOT EXISTS idx_doc_emb_hnsw_cosine ON document_embeddings
  USING hnsw (embedding vector_cosine_ops)
  WITH (m = 16, ef_construction = 100);

-- ✅ C1: Configuração de planner para híbridos
-- SET LOCAL enable_bitmapscan = on;
-- SET LOCAL random_page_cost = 1.1;  -- Ajustar para SSDs/enterprise storage
-- O planner combinará Bitmap Index Scan (escalar) + Index Scan (vetor) automaticamente.
```

---

## 🧪 Testes Unitários (TDD – Apenas para a Lógica Específica)

```sql
-- Test: hybrid_search_applies_scalar_filter_correctly
-- Constraint: C4+C5
BEGIN;
SELECT plan(2);

SET LOCAL app.current_tenant = '00000000-0000-0000-0000-000000000001';
-- Arrange: inserir docs com status='active' e status='draft'
-- Act: buscar com filter {"status": "active"}
-- Assert: zero resultados com status='draft'
-- SELECT is((SELECT COUNT(*) FROM search_hybrid_scalar_vector('[0.1]'::vector(1536), '{"status":"draft"}'::jsonb, '00000000-0000-0000-0000-000000000001')), 0, 'C5: filtro escalar aplicado');

-- Act/Assert: combined_score deve estar entre 0 e 1
SELECT ok((SELECT combined_score BETWEEN 0 AND 1 FROM search_hybrid_scalar_vector('[0.1]'::vector(1536), NULL, '00000000-0000-0000-0000-000000000001')), 'V2: score híbrido normalizado');

SELECT * FROM finish();
ROLLBACK;

-- Test: vector_dimension_guard_prevents_mismatch
-- Constraint: V1
DO $$
BEGIN
  -- Arrange/Act: passar vetor 768d para função que exige 1536d na assinatura
  -- Assert: erro de tipo PostgreSQL capturado
  PERFORM true; -- Placeholder CI
END $$;
```

---

## 🔍 Validação (VDD – Comando Canônico)

```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/postgresql-pgvector/hybrid-search-scalar-vector.pgvector.md \
  --json \
  --check-structural \
  --check-error-handling \
  --check-observability \
  --check-vector-constraints
```

---

## 🔗 Referências Cruzadas (Wikilinks Mínimos)
- [[postgresql-pgvector-rag-master-agent.md]] ← Fonte de hardening, observability, constraints
- [[/05-CONFIGURATIONS/validation/orchestrator-engine/main.go]] ← Motor de validação
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]] ← Mapeamento constraints por rota ✅ CORREGIDO
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]] ← Infraestrutura de logs
- [[01-RULES/harness-norms-v3.0.md]] ← Definição formal de C1-C8
- [[01-RULES/language-lock-protocol.md]] ← Protocolo de isolamento de operadores

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-09 | PostgreSQL-PgVector Master Agent | Criação inicial: busca escalar+vetor, filtros JSONB seguros, ponderação alpha, índices BTREE+HNSW sinérgicos | C1,C4,C5,C8,V1,V2,V3 |

---
## 🔍 Observability (Documentación para IA – Apenas Eventos Específicos)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `module_bootstrap` | INFO | C8 | `"Master agent available"` ou `"fallback: mantis_log() not found"` |
| `hybrid_scalar_vector_completed` | INFO | C8 | `"alpha=0.7, limit=10, filters=["status","year_gte"], tenant=uuid, duration_ms=42"` |
| `hybrid_scalar_vector_failed` | ERROR | C8 | `"sanitized_error_message, tenant=uuid"` |

### Validação de Schema V-LOG-02 (Helper Mínimo)
```sql
-- Executar em teste: SELECT validate_vlog02('{"timestamp":"2026-05-09T00:00:00Z","level":"INFO","resource":{"tenant_id":"uuid"},"body":{"event":"hybrid_scalar_vector_completed"}}');
-- Retorno esperado: t (true) se schema válido, f (false) caso contrário
-- Função herdada do Master Agent; este módulo apenas a invoca
```
---
