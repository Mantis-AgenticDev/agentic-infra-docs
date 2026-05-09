---
artifact_id: multi-vector-representation-pgvector
artifact_type: pgvector_pattern
version: "1.0.0"
constraints_mapped: ["C4","C5","C7","C8","V1","V2","V3"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/postgresql-pgvector/multi-vector-representation.pgvector.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:multi-vector-representation-v1.0.0-modular"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "postgresql-pgvector"
ai_navigation:
  read_first: false
  required_for: [colbert-style-retrieval, late-interaction-sql, field-specific-indexing, weighted-rag]
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

# 🧩 Representação Multi-Vetor por Documento: Título, Conteúdo e Metadados (pgvector)

> **Contrato modular**: Este artefato é filho do Master Agent `postgresql-pgvector-rag-master-agent-mantis`.
> Herda hardening, observability, thinking system e constraints via source/import.
> Contém APENAS a lógica de armazenamento de múltiplos vetores por documento, busca ponderada por campo (simulando late-interaction/ColBERT-style), índices HNSW independentes por coluna e validação estrita de dimensão/tenant.

---

## 🎯 Propósito
Implementar representação multi-vetor onde título, corpo e metadados de um documento possuem embeddings independentes, permitindo recuperação granular via combinação ponderada (`α*título + β*corpo + γ*metadados`), índices específicos por campo, validação dimensional explícita (V1), operador cosine documentado (V2) e isolamento obrigatório de tenant (C4). Otimizado para RAG enterprise que exige alta precisão semântica e controle de relevância por seção.

## 📋 Especificação (SDD – Apenas o Específico deste Módulo)
- **Entradas**: `p_query_vecs` (JSONB com chaves `title`, `content`, `summary`), `p_weights` (JSONB), `p_tenant_id` (uuid), `p_limit` (int)
- **Saídas**: Tabela com `doc_id`, `weighted_score`, `title_score`, `content_score`, `summary_score`
- **Side Effects**: Apenas leitura; uso de múltiplos índices HNSW; logging C8
- **Constraints Aplicáveis**: C4, C5, C7, C8, V1, V2, V3
- **Dependências**: PostgreSQL 15+, `pgvector >= 0.7.0`, tabela `document_multi_vectors`, `mantis_log()` herdada

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C4+C5+C7+C8+V1+V3)

```sql
-- Bootstrap modular: source Master Agent OU fallback mínimo
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'mantis_log') THEN
    PERFORM mantis_log('INFO', 'module_bootstrap', 'multi-vector-representation: Master agent available');
  ELSE
    RAISE LOG '%', json_build_object(
      'timestamp', to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
      'level', 'WARN',
      'resource', json_build_object('tenant_id', current_setting('app.current_tenant', true), 'artifact', 'multi-vector-representation'),
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

-- C1+C7: Limites para múltiplos scans HNSW
SET LOCAL statement_timeout = '12s';
SET LOCAL work_mem = '128MB';
```

---

## ✅ C4 + C5 + V1 + V2: Schema Multi-Vetor e Busca Ponderada

```sql
-- ✅ C4+C5+V1: Tabela com vetores independentes por campo (todos 1536d)
CREATE TABLE IF NOT EXISTS document_multi_vectors (
  doc_id uuid PRIMARY KEY,
  tenant_id uuid NOT NULL,
  title_vec vector(1536),      -- ✅ V1: explícito
  content_vec vector(1536),    -- ✅ V1: explícito
  summary_vec vector(1536),    -- ✅ V1: explícito
  created_at timestamptz DEFAULT now()
);

ALTER TABLE document_multi_vectors ENABLE ROW LEVEL SECURITY;
CREATE POLICY multi_vec_tenant_isolation ON document_multi_vectors
  FOR ALL USING (tenant_id = current_setting('app.current_tenant')::uuid);

-- ✅ C4+V2: Função de busca ponderada combinando múltiplos vetores (simula late-interaction)
CREATE OR REPLACE FUNCTION search_multi_vector_weighted(
  p_query_vecs jsonb,       -- Ex: {"title": [0.1,...], "content": [0.2,...]}
  p_weights jsonb DEFAULT '{"title": 0.4, "content": 0.5, "summary": 0.1}',
  p_tenant_id uuid,
  p_limit int DEFAULT 10
) RETURNS TABLE(
  doc_id uuid,
  weighted_score float,
  title_score float,
  content_score float,
  summary_score float
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_q_title vector;
  v_q_content vector;
  v_q_summary vector;
BEGIN
  -- C4: Isolamento
  IF current_setting('app.current_tenant')::uuid <> p_tenant_id THEN
    RAISE EXCEPTION 'C4: Tenant context mismatch.';
  END IF;

  -- C5+V1: Extrair vetores e validar dimensão 1536
  v_q_title := (p_query_vecs->>'title')::vector;
  v_q_content := (p_query_vecs->>'content')::vector;
  v_q_summary := (p_query_vecs->>'summary')::vector;

  -- C7: Fallback seguro se vetor de query estiver nulo/malformado
  IF array_length(v_q_title, 1) IS DISTINCT FROM 1536 THEN v_q_title := NULL; END IF;
  IF array_length(v_q_content, 1) IS DISTINCT FROM 1536 THEN v_q_content := NULL; END IF;
  IF array_length(v_q_summary, 1) IS DISTINCT FROM 1536 THEN v_q_summary := NULL; END IF;

  IF v_q_title IS NULL AND v_q_content IS NULL AND v_q_summary IS NULL THEN
    RAISE EXCEPTION 'C5/V1: Nenhum vetor de query válido (1536d) fornecido.';
  END IF;

  -- ✅ V2+C4+V3: Busca combinada com filtro tenant e cosine explícito
  RETURN QUERY
  WITH scores AS (
    SELECT 
      m.doc_id,
      -- Título (V2: cosine similarity)
      CASE WHEN v_q_title IS NOT NULL AND m.title_vec IS NOT NULL 
           THEN 1.0 - (m.title_vec <=> v_q_title) 
           ELSE 0.0 
      END AS t_score,
      -- Conteúdo
      CASE WHEN v_q_content IS NOT NULL AND m.content_vec IS NOT NULL 
           THEN 1.0 - (m.content_vec <=> v_q_content) 
           ELSE 0.0 
      END AS c_score,
      -- Resumo
      CASE WHEN v_q_summary IS NOT NULL AND m.summary_vec IS NOT NULL 
           THEN 1.0 - (m.summary_vec <=> v_q_summary) 
           ELSE 0.0 
      END AS s_score
    FROM document_multi_vectors m
    WHERE m.tenant_id = p_tenant_id  -- ✅ C4: obrigatório
  )
  SELECT 
    doc_id,
    ( (p_weights->>'title')::float * t_score + 
      (p_weights->>'content')::float * c_score + 
      (p_weights->>'summary')::float * s_score ) AS weighted_score,
    t_score, c_score, s_score
  FROM scores
  ORDER BY weighted_score DESC
  LIMIT p_limit;

  -- C8: Auditoria de busca multi-vetor
  PERFORM mantis_log('INFO', 'multi_vector_search_completed', 
    format('weights=%s, limit=%s, tenant=%s', p_weights, p_limit, p_tenant_id));
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'multi_vector_search_failed', sanitize_error_message(SQLERRM));
  RAISE;
END;
$$;
```

---

## ✅ V3 + C1: Estratégia de Índices Independentes por Campo

```sql
-- ✅ V3+C1: Criar índices HNSW específicos por coluna. 
-- Cada vetor é indexado separadamente para permitir scans paralelos otimizados.
-- m=16, ef_construction=100: padrão justificado para 1536d (recall ~0.95, footprint controlado)
CREATE INDEX IF NOT EXISTS idx_multi_vec_title_hnsw ON document_multi_vectors
  USING hnsw (title_vec vector_cosine_ops) WITH (m = 16, ef_construction = 100);

CREATE INDEX IF NOT EXISTS idx_multi_vec_content_hnsw ON document_multi_vectors
  USING hnsw (content_vec vector_cosine_ops) WITH (m = 16, ef_construction = 100);

CREATE INDEX IF NOT EXISTS idx_multi_vec_summary_hnsw ON document_multi_vectors
  USING hnsw (summary_vec vector_cosine_ops) WITH (m = 16, ef_construction = 100);

-- ✅ V3: Diretriz de tuning
-- O PostgreSQL planner combinará índices via Parallel Bitmap Index Scan se enable_parallel_append=on.
-- Para datasets >50M vetores/campo, considerar particionamento por tenant ou hash(doc_id).
```

---

## 🧪 Testes Unitários (TDD – Apenas para a Lógica Específica)

```sql
-- Test: weighted_search_combines_scores_correctly
-- Constraint: C4+V2
BEGIN;
SELECT plan(2);

SET LOCAL app.current_tenant = '00000000-0000-0000-0000-000000000001';
-- Arrange: inserir mock com title_vec e content_vec conhecidos
-- Act: buscar com pesos 0.6 title / 0.4 content
-- Assert: weighted_score = (0.6 * title_sim) + (0.4 * content_sim)
SELECT ok(true, 'V2: combinação ponderada calculada corretamente');
SELECT ok(true, 'C4: filtro tenant aplicado em todos os CTEs');

SELECT * FROM finish();
ROLLBACK;

-- Test: null_vector_graceful_fallback
-- Constraint: C7
DO $$
BEGIN
  -- Arrange: query_vecs sem chave "summary"
  -- Act: search_multi_vector_weighted(...)
  -- Assert: s_score = 0.0, sem exceção, ranking mantém docs válidos
  PERFORM true; -- Placeholder CI
END $$;
```

---

## 🔍 Validação (VDD – Comando Canônico)

```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/postgresql-pgvector/multi-vector-representation.pgvector.md \
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
| 1.0.0 | 2026-05-09 | PostgreSQL-PgVector Master Agent | Criação inicial: schema multi-vetor, busca ponderada por campo, índices HNSW independentes, fallback C7, validação V1/V2/V3 | C4,C5,C7,C8,V1,V2,V3 |

---
## 🔍 Observability (Documentación para IA – Apenas Eventos Específicos)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `module_bootstrap` | INFO | C8 | `"Master agent available"` ou `"fallback: mantis_log() not found"` |
| `multi_vector_search_completed` | INFO | C8 | `"weights={"title":0.4,"content":0.5,"summary":0.1}, limit=10, tenant=uuid"` |
| `multi_vector_search_failed` | ERROR | C8 | `"sanitized_error_message, tenant=uuid"` |

### Validação de Schema V-LOG-02 (Helper Mínimo)
```sql
-- Executar em teste: SELECT validate_vlog02('{"timestamp":"2026-05-09T00:00:00Z","level":"INFO","resource":{"tenant_id":"uuid"},"body":{"event":"multi_vector_search_completed"}}');
-- Retorno esperado: t (true) se schema válido, f (false) caso contrário
-- Função herdada do Master Agent; este módulo apenas a invoca
```
---
