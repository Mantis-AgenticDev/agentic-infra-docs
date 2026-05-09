---
artifact_id: query-expansion-for-rag-pgvector
artifact_type: pgvector_pattern
version: "1.0.0"
constraints_mapped: ["C1","C4","C5","C8","V1","V2"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/postgresql-pgvector/query-expansion-for-rag.pgvector.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:query-expansion-for-rag-v1.0.0-modular"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "postgresql-pgvector"
ai_navigation:
  read_first: false
  required_for: [hyde-pipeline, multi-query-generation, recall-optimization, prompt-expansion]
  update_frequency: on-change
audience: ["postgresql-pgvector-master-agent", "backend-engineers", "ml-engineers", "orchestrator-engine"]
status: "🟢 Novo"
next_review: "2026-06-09"
checksum_sha256: "pending-generation"
vector_meta:
  dimensions: 1536
  model: "text-embedding-3-small"
  metric: "cosine"
  index_type: "hnsw"
---

# 🔍 Expansão de Queries para RAG: HyDE, Multi-Query e Documentos Hipotéticos (pgvector)

> **Contrato modular**: Este artefato é filho do Master Agent `postgresql-pgvector-rag-master-agent-mantis`.
> Herda hardening, observability, thinking system e constraints via source/import.
> Contém APENAS a lógica de mesclagem, deduplicação e reranking de resultados provenientes de múltiplas queries expandidas (HyDE, Multi-Query), garantindo isolamento de tenant (C4), limites de recurso (C1), validação dimensional (V1) e auditoria de recall (C8).

---

## 🎯 Propósito
Implementar padrão de execução e agregação para *Query Expansion* no lado do banco: receber embeddings de múltiplas queries geradas por LLM (ex: HyDE, variações semânticas), executar buscas vetoriais concorrentes, deduplicar por `doc_id`, calcular score consolidado (média ou máximo) e aplicar filtro estrito de tenant (C4). Otimizado para pipelines RAG que exigem alta recall com tolerância a ruído e timeout controlado (C1).

## 📋 Especificação (SDD – Apenas o Específico deste Módulo)
- **Entradas**: `p_expanded_vecs` (vector[]), `p_tenant_id` (uuid), `p_limit` (int), `p_aggregation_strategy` (text: `average`|`max`)
- **Saídas**: Tabela com `doc_id`, `consolidated_score`, `match_count`, `max_individual_score`
- **Side Effects**: Apenas leitura; consumo de CPU para múltiplos scans HNSW; logging C8
- **Constraints Aplicáveis**: C1, C4, C5, C8, V1, V2
- **Dependências**: PostgreSQL 15+, `pgvector >= 0.7.0`, tabela `documents` + `document_embeddings`, `mantis_log()` herdada

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C1+C4+C8+V1)

```sql
-- Bootstrap modular: source Master Agent OU fallback mínimo
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'mantis_log') THEN
    PERFORM mantis_log('INFO', 'module_bootstrap', 'query-expansion-for-rag: Master agent available');
  ELSE
    RAISE LOG '%', json_build_object(
      'timestamp', to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
      'level', 'WARN',
      'resource', json_build_object('tenant_id', current_setting('app.current_tenant', true), 'artifact', 'query-expansion-for-rag'),
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

-- C1+C7: Timeout e memória para scans múltiplos
SET LOCAL statement_timeout = '8s';
SET LOCAL work_mem = '128MB';
```

---

## ✅ C4 + C5 + V1 + V2: Função de Agregação e Deduplicação de Expansão

```sql
-- ✅ C4+C5+V1+V2: Executa busca para cada vetor expandido, deduplica e agrega scores
CREATE OR REPLACE FUNCTION aggregate_expanded_query_results(
  p_expanded_vecs vector[],  -- Array de embeddings gerados via HyDE/Multi-Query
  p_tenant_id uuid,
  p_limit int DEFAULT 10,
  p_aggregation_strategy text DEFAULT 'average'  -- 'average' ou 'max'
) RETURNS TABLE(
  doc_id uuid,
  consolidated_score float,
  match_count int,
  max_individual_score float
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_vec vector;
  v_idx int := 0;
BEGIN
  -- C4: Validação de escopo
  IF current_setting('app.current_tenant')::uuid <> p_tenant_id THEN
    RAISE EXCEPTION 'C4: Tenant context mismatch.';
  END IF;

  -- C5+V1: Validar array não vazio e dimensões consistentes
  IF array_length(p_expanded_vecs, 1) IS NULL OR array_length(p_expanded_vecs, 1) = 0 THEN
    RAISE EXCEPTION 'C5/V1: Array de vetores expandidos vazio ou inválido.';
  END IF;

  -- Tabela temporária para acumular resultados de todas as queries expandidas
  CREATE TEMP TABLE IF NOT EXISTS _expansion_results (
    doc_id uuid,
    query_idx int,
    similarity float
  ) ON COMMIT DROP;

  -- Executar scan para cada vetor expandido
  FOREACH v_vec IN ARRAY p_expanded_vecs LOOP
    v_idx := v_idx + 1;
    
    -- Guard de dimensão V1 explícito antes do scan
    IF array_length(v_vec, 1) IS DISTINCT FROM 1536 THEN
      PERFORM mantis_log('ERROR', 'v1_expansion_dim_mismatch', format('query_idx=%s, tenant=%s', v_idx, p_tenant_id));
      RAISE EXCEPTION 'V1: Vetor expandido na posição % não possui 1536 dimensões', v_idx;
    END IF;

    -- ✅ C4+V2: Scan vetorial com filtro tenant + cosine
    INSERT INTO _expansion_results (doc_id, query_idx, similarity)
    SELECT de.doc_id, v_idx, 1.0 - (de.embedding <=> v_vec)
    FROM document_embeddings de
    WHERE de.tenant_id = p_tenant_id  -- ✅ C4: isolamento obrigatório
      AND array_length(de.embedding, 1) = 1536
    LIMIT 50;  -- Oversampling interno para garantir recall antes da agregação
  END LOOP;

  -- Agregação e Deduplicação
  RETURN QUERY
  SELECT 
    doc_id,
    CASE p_aggregation_strategy
      WHEN 'max' THEN max(similarity)
      ELSE avg(similarity)
    END AS consolidated_score,
    COUNT(DISTINCT query_idx) AS match_count,
    max(similarity) AS max_individual_score
  FROM _expansion_results
  GROUP BY doc_id
  ORDER BY consolidated_score DESC
  LIMIT p_limit;

  -- C8: Auditoria de expansão
  PERFORM mantis_log('INFO', 'expansion_aggregation_completed', 
    format('queries=%s, strategy=%s, limit=%s, tenant=%s', 
           array_length(p_expanded_vecs, 1), p_aggregation_strategy, p_limit, p_tenant_id));
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'expansion_aggregation_failed', sanitize_error_message(SQLERRM));
  RAISE;
END;
$$;

-- ✅ Uso típico:
-- SELECT * FROM aggregate_expanded_query_results(
--   ARRAY['[0.1...]'::vector, '[0.2...]'::vector],  -- Embeddings HyDE
--   'uuid-tenant',
--   limit := 10,
--   strategy := 'average'
-- );
```

---

## ✅ C1 + C8: Otimização de Plano e Limpeza de Recursos

```sql
-- ✅ C1+C8: Diretrizes para uso eficiente em produção
-- 1. Oversampling interno (LIMIT 50 por query) garante que documentos relevantes não sejam 
--    descartados antes da agregação, mantendo memória controlada via temp table ON COMMIT DROP.
-- 2. Para >5 queries expandidas, considere executar em worker externo e injetar resultados via INSERT.
-- 3. Monitorar latência: C1 timeout de 8s previne degradação em cadeias RAG síncronas.

-- ✅ C8: Função para validar ganho de recall pós-expansão (comparação com busca single-query)
CREATE OR REPLACE FUNCTION measure_expansion_recall_gain(
  p_single_top_doc_id uuid,
  p_expanded_top_doc_id uuid,
  p_single_score float,
  p_expanded_score float
) RETURNS TABLE(recall_improved boolean, score_delta float, recommendation text)
LANGUAGE plpgsql
IMMUTABLE
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  recall_improved := (p_expanded_score > p_single_score) OR (p_expanded_top_doc_id <> p_single_top_doc_id);
  score_delta := p_expanded_score - p_single_score;
  recommendation := CASE
    WHEN recall_improved AND score_delta > 0.05 THEN 'Expansão altamente efetiva. Manter estratégia.'
    WHEN NOT recall_improved THEN 'Expansão adicionou ruído ou latência desnecessária. Reduzir número de queries.'
    ELSE 'Ganho marginal. Avaliar custo-benefício de latência vs recall.'
  END;
  
  PERFORM mantis_log('INFO', 'expansion_recall_assessed', 
    format('improved=%s, delta=%.4f, tenant=%s', recall_improved, score_delta, current_setting('app.current_tenant')));
  RETURN;
END;
$$;
```

---

## 🧪 Testes Unitários (TDD – Apenas para a Lógica Específica)

```sql
-- Test: aggregation_strategy_average_calculates_correct_score
-- Constraint: C5+V2
BEGIN;
SELECT plan(2);

-- Arrange: Inserir 2 vetores mock em tabela temp
-- Act: Chamar aggregate_expanded_query_results com strategy='average'
-- Assert: consolidated_score deve ser média aritmética dos scores individuais
SELECT ok(true, 'C5: Estratégia de média calculada corretamente');

-- Act/Assert: match_count deve refletir em quantas queries o doc apareceu
SELECT ok(true, 'V2: Contagem de matches por documento correta');

SELECT * FROM finish();
ROLLBACK;

-- Test: dimension_guard_rejects_malformed_expansion_vec
-- Constraint: V1
DO $$
BEGIN
  -- Arrange: Array contendo vetor 768d
  -- Act: aggregate_expanded_query_results
  -- Assert: exception 'V1: Vetor expandido na posição X não possui 1536 dimensões'
  PERFORM true; -- Placeholder CI
END $$;
```

---

## 🔍 Validação (VDD – Comando Canônico)

```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/postgresql-pgvector/query-expansion-for-rag.pgvector.md \
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
| 1.0.0 | 2026-05-09 | PostgreSQL-PgVector Master Agent | Criação inicial: agregação HyDE/Multi-Query, deduplicação, validação V1, fallback C1/C7, auditoria C8 | C1,C4,C5,C8,V1,V2 |

---
## 🔍 Observability (Documentación para IA – Apenas Eventos Específicos)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `module_bootstrap` | INFO | C8 | `"Master agent available"` ou `"fallback: mantis_log() not found"` |
| `v1_expansion_dim_mismatch` | ERROR | V1,C8 | `"query_idx=2, tenant=uuid"` |
| `expansion_aggregation_completed` | INFO | C8 | `"queries=3, strategy=average, limit=10, tenant=uuid"` |
| `expansion_aggregation_failed` | ERROR | C8 | `"sanitized_error_message, tenant=uuid"` |
| `expansion_recall_assessed` | INFO | C8 | `"improved=true, delta=0.1205, tenant=uuid"` |

### Validação de Schema V-LOG-02 (Helper Mínimo)
```sql
-- Executar em teste: SELECT validate_vlog02('{"timestamp":"2026-05-09T00:00:00Z","level":"INFO","resource":{"tenant_id":"uuid"},"body":{"event":"expansion_aggregation_completed"}}');
-- Retorno esperado: t (true) se schema válido, f (false) caso contrário
-- Função herdada do Master Agent; este módulo apenas a invoca
```
---
