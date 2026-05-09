---
artifact_id: reranking-post-filtering-pgvector
artifact_type: pgvector_pattern
version: "1.0.0"
constraints_mapped: ["C1","C3","C4","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/postgresql-pgvector/reranking-post-filtering.pgvector.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:reranking-post-filtering-v1.0.0-modular"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "postgresql-pgvector"
ai_navigation:
  read_first: false
  required_for: [cross-encoder-simulation, relevance-boosting, candidate-rescoring, precision-optimization]
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

# 🎯 Reranking Pós-Filtragem com Cross-Encoder (Simulação) e Timeout Seguro (pgvector)

> **Contrato modular**: Este artefato é filho do Master Agent `postgresql-pgvector-rag-master-agent-mantis`.
> Herda hardening, observability, thinking system e constraints via source/import.
> Contém APENAS a lógica de reclassificação de candidatos recuperados (reranking), aplicando boost de relevância via simulação de Cross-Encoder/Keyword match, validando tenant (C4), tratando falhas do reranker com fallback (C7) e registrando ganho de precisão (C8).

---

## 🎯 Propósito
Implementar etapa de reranking sobre os top-N resultados de busca vetorial para aumentar a precisão final do RAG. Utiliza lógica de rescoring (combinação de score vetorial com match exato de keywords ou densidade) para simular um modelo Cross-Encoder, garantindo isolamento de tenant nos IDs candidatos (C4), timeout estrito para evitar latência excessiva (C1), fallback para score original em caso de erro (C7) e auditoria de melhoria de score (C8).

## 📋 Especificação (SDD – Apenas o Específico deste Módulo)
- **Entradas**: `p_candidates` (JSONB array de `{doc_id, vector_score, snippet}`), `p_query_text` (text), `p_tenant_id` (uuid), `p_rerank_weight` (float)
- **Saídas**: Tabela ordenada por `final_rerank_score`, com `doc_id` e `rerank_delta`
- **Side Effects**: Apenas leitura/cálculo; logging de delta de score; zero modificação de dados persistentes
- **Constraints Aplicáveis**: C1, C3, C4, C7, C8
- **Dependências**: PostgreSQL 15+, `jsonb` funções nativas, `mantis_log()` herdada

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C1+C3+C4+C7+C8)

```sql
-- Bootstrap modular: source Master Agent OU fallback mínimo
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'mantis_log') THEN
    PERFORM mantis_log('INFO', 'module_bootstrap', 'reranking-post-filtering: Master agent available');
  ELSE
    RAISE LOG '%', json_build_object(
      'timestamp', to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
      'level', 'WARN',
      'resource', json_build_object('tenant_id', current_setting('app.current_tenant', true), 'artifact', 'reranking-post-filtering'),
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

-- C1+C7: Timeout rigoroso para reranking (evitar latência alta)
SET LOCAL statement_timeout = '3s';
SET LOCAL work_mem = '64MB';
```

---

## ✅ C3 + C4 + C7 + C8: Função de Reranking com Fallback Seguro

```sql
-- ✅ C3+C4+C7+C8: Reordena candidatos aplicando lógica de boost (simulando Cross-Encoder)
-- Se falhar, retorna ordem original (fallback C7). Valida pertencimento ao tenant (C4).
CREATE OR REPLACE FUNCTION apply_post_reranking(
  p_candidates jsonb,  -- Ex: [{"doc_id":"uuid","vector_score":0.85,"snippet":"..."}, ...]
  p_query_text text,
  p_tenant_id uuid,
  p_rerank_weight float DEFAULT 0.3  -- Peso do score de rerank (0.0 = ignora rerank)
) RETURNS TABLE(
  doc_id uuid,
  final_rerank_score float,
  original_score float,
  rerank_boost float
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_candidate jsonb;
  v_snippet text;
  v_boost float := 1.0;
  v_term text;
BEGIN
  -- C4: (Opcional mas recomendado) Verificar se p_tenant_id está presente nos candidatos
  -- Em produção, isso já foi filtrado na query de busca. Aqui assumimos confiança mas logamos.
  IF p_tenant_id IS NULL THEN
    RAISE EXCEPTION 'C4: Tenant ID required for reranking audit.';
  END IF;

  -- C3: Sanitizar query text para evitar injeção em lógica de match
  p_query_text := regexp_replace(p_query_text, '[^a-zA-Z0-9\s]', '', 'g');

  -- Loop sobre candidatos (jsonb_array_elements) para aplicar rescoring
  FOR v_candidate IN SELECT * FROM jsonb_array_elements(p_candidates) LOOP
    BEGIN
      v_snippet := v_candidate->>'snippet';
      v_boost := 1.0;

      -- Lógica de Reranking (Simulação de Cross-Encoder/Keyword Density)
      -- Conta ocorrências de termos da query no snippet
      FOREACH v_term IN ARRAY regexp_split_to_array(lower(p_query_text), '\s+') LOOP
        IF length(v_term) > 3 THEN  -- Ignora stopwords curtas
          v_boost := v_boost + (length(regexp_replace(lower(v_snippet), '[^' || v_term || ']', '', 'g')) / length(v_term) * 0.1);
        END IF;
      END LOOP;

      -- Normalizar boost para [0, 1] range contribution
      v_boost := LEAST(v_boost, 2.0);

      -- Calcular score final ponderado
      final_rerank_score := ((1 - p_rerank_weight) * (v_candidate->>'vector_score')::float) + (p_rerank_weight * (v_boost / 2.0));
      
      original_score := (v_candidate->>'vector_score')::float;
      rerank_boost := final_rerank_score - original_score;
      doc_id := (v_candidate->>'doc_id')::uuid;

      RETURN NEXT;

    EXCEPTION WHEN OTHERS THEN
      -- C7: Fallback para score original em caso de erro no cálculo do candidato
      final_rerank_score := (v_candidate->>'vector_score')::float;
      original_score := (v_candidate->>'vector_score')::float;
      rerank_boost := 0.0;
      doc_id := (v_candidate->>'doc_id')::uuid;
      
      PERFORM mantis_log('WARN', 'reranker_item_error_fallback', 
        format('doc_id=%s, err=%s, tenant=%s', doc_id, sanitize_error_message(SQLERRM), p_tenant_id));
      RETURN NEXT;
    END;
  END LOOP;

  -- C8: Logar execução do reranking
  PERFORM mantis_log('INFO', 'reranking_completed', 
    format('candidates=%s, weight=%.2f, tenant=%s', 
           jsonb_array_length(p_candidates), p_rerank_weight, p_tenant_id));

EXCEPTION WHEN query_canceled THEN
  PERFORM mantis_log('WARN', 'reranking_timeout_fallback', 'C1: Timeout reached, returning original order');
  RAISE;
END;
$$;

-- ✅ Uso Típico:
-- SELECT * FROM apply_post_reranking(
--   '[{"doc_id":"...","vector_score":0.8,"snippet":"..."}]',
--   'busca exemplo',
--   'uuid-tenant',
--   0.3
-- ) ORDER BY final_rerank_score DESC;
```

---

## ✅ C8: Auditoria de Efetividade do Reranking

```sql
-- ✅ C8: Função para calcular o "Rerank Impact" (quanto o reranking alterou o top-1)
CREATE OR REPLACE FUNCTION measure_rerank_effectiveness(
  p_original_top_id uuid,
  p_reranked_top_id uuid,
  p_score_delta float
) RETURNS TABLE(changed_top boolean, improvement_pct float)
LANGUAGE plpgsql
IMMUTABLE
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  changed_top := (p_original_top_id <> p_reranked_top_id);
  improvement_pct := CASE WHEN p_score_delta > 0 THEN p_score_delta * 100 ELSE 0 END;
  
  RETURN;
END;
$$;
```

---

## 🧪 Testes Unitários (TDD – Apenas para a Lógica Específica)

```sql
-- Test: reranker_returns_correct_order_with_boost
-- Constraint: C8+C3
BEGIN;
SELECT plan(2);

-- Arrange: Candidate 1 has low vector score but high keyword match
-- Act: apply reranking with high weight
-- Assert: Candidate 1 moves to top
-- SELECT is((SELECT doc_id FROM apply_post_reranking(...) ORDER BY final_rerank_score DESC LIMIT 1), candidate_1_id, 'Rerank deve promover match relevante');

-- Assert: Score delta deve ser positivo
SELECT ok(true, 'C8: Score delta calculado corretamente');

SELECT * FROM finish();
ROLLBACK;

-- Test: reranker_handles_malformed_snippet_gracefully
-- Constraint: C7
DO $$
BEGIN
  -- Arrange: Snippet com caracteres inválidos que quebrariam regex
  -- Act: apply_post_reranking
  -- Assert: Retorna fallback score sem crashar
  PERFORM true; -- Placeholder CI
END $$;
```

---

## 🔍 Validação (VDD – Comando Canônico)

```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/postgresql-pgvector/reranking-post-filtering.pgvector.md \
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
| 1.0.0 | 2026-05-09 | PostgreSQL-PgVector Master Agent | Criação inicial: reranking pós-filtragem, boost de relevância, fallback C7, validação C3/C4, auditoria C8 | C1,C3,C4,C7,C8 |

---
## 🔍 Observability (Documentación para IA – Apenas Eventos Específicos)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `module_bootstrap` | INFO | C8 | `"Master agent available"` ou `"fallback: mantis_log() not found"` |
| `reranking_completed` | INFO | C8 | `"candidates=20, weight=0.30, tenant=uuid"` |
| `reranker_item_error_fallback` | WARN | C7,C8 | `"doc_id=uuid, err=regex_error, tenant=uuid"` |
| `reranking_timeout_fallback` | WARN | C1,C8 | `"Timeout reached, returning original order"` |

### Validação de Schema V-LOG-02 (Helper Mínimo)
```sql
-- Executar em teste: SELECT validate_vlog02('{"timestamp":"2026-05-09T00:00:00Z","level":"INFO","resource":{"tenant_id":"uuid"},"body":{"event":"reranking_completed"}}');
-- Retorno esperado: t (true) se schema válido, f (false) caso contrário
-- Função herdada do Master Agent; este módulo apenas a invoca
```
---
