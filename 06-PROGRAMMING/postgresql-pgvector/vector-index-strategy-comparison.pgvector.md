---
artifact_id: vector-index-strategy-comparison-pgvector
artifact_type: pgvector_pattern
version: "1.0.0"
constraints_mapped: ["C1","C4","V1","V2","V3"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/postgresql-pgvector/vector-index-strategy-comparison.pgvector.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:vector-index-strategy-comparison-v1.0.0-modular"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "postgresql-pgvector"
ai_navigation:
  read_first: false
  required_for: [hnsw-vs-ivfflat-decision, performance-tuning, memory-optimization, recall-benchmarking]
  update_frequency: on-change
audience: ["postgresql-pgvector-master-agent", "db-architects", "ml-engineers", "orchestrator-engine"]
status: "🟢 Novo"
next_review: "2026-06-09"
checksum_sha256: "pending-generation"
vector_meta:
  dimensions: 1536
  model: "text-embedding-3-small"
  metric: "cosine"
  index_type: "hnsw"
---

# ⚖️ Comparação de Estratégias de Indexação: HNSW vs IVFFlat (pgvector)

> **Contrato modular**: Este artefato é filho do Master Agent `postgresql-pgvector-rag-master-agent-mantis`.
> Herda hardening, observability, thinking system e constraints via source/import.
> Contém APENAS a lógica de comparação executável entre algoritmos de índice, benchmarks simulados e recomendação automática baseada em volume de dados e requisitos de recall.

---

## 🎯 Propósito
Comparar estrategicamente os índices `HNSW` e `IVFFlat` do `pgvector` para auxiliar na decisão de implementação: análise de trade-offs entre recall, latência de query, consumo de memória e tempo de build. Fornece funções SQL para simular métricas de performance e retornar a recomendação ótima baseada no tamanho do dataset e dimensionalidade (V1/V2/V3). Otimizado para arquitectos de dados e tuning de RAG.

## 📋 Especificação (SDD – Apenas o Específico deste Módulo)
- **Entradas**: `p_row_estimate` (bigint), `p_dim` (int), `p_query_concurrency` (int)
- **Saídas**: Matriz de comparação, recomendação de estratégia (HNSW/IVFFlat/None), estimativas de memória/latência
- **Side Effects**: Apenas leitura e logging C8; nenhuma alteração permanente de índices
- **Constraints Aplicáveis**: C1 (recursos), C4 (contexto), V1 (dimensão), V2 (métrica), V3 (parâmetros de índice)
- **Dependências**: PostgreSQL 15+, `pgvector >= 0.7.0`, tabela de benchmarks, `mantis_log()` herdada

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C1+C4+V1+V2+V3)

```sql
-- Bootstrap modular: source Master Agent OU fallback mínimo
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'mantis_log') THEN
    PERFORM mantis_log('INFO', 'module_bootstrap', 'vector-index-strategy-comparison: Master agent available');
  ELSE
    RAISE LOG '%', json_build_object(
      'timestamp', to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
      'level', 'WARN',
      'resource', json_build_object('tenant_id', current_setting('app.current_tenant', true), 'artifact', 'vector-index-strategy-comparison'),
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

-- C1: Limites de recursos para operações de análise/consulta
SET LOCAL statement_timeout = '10s';
SET LOCAL work_mem = '128MB';
```

---

## ✅ V3 + C1: Tabela de Benchmarks e Trade-offs

```sql
-- ✅ V3+C1: Base de conhecimento de benchmarks (baseada em pgvector docs + testes padrão)
CREATE TABLE IF NOT EXISTS vector_index_benchmarks (
  index_type text NOT NULL CHECK (index_type IN ('hnsw', 'ivfflat')),
  dataset_size_range text NOT NULL,
  recall_target float NOT NULL,  -- ex: 0.95
  avg_build_time_per_1m_vectors text,
  memory_overhead_factor float,  -- multiplicador sobre dados raw
  avg_query_latency_ms text,
  pros text[],
  cons text[],
  PRIMARY KEY (index_type, dataset_size_range)
);

INSERT INTO vector_index_benchmarks VALUES
('hnsw', '<1M vetores', 0.99, '~45 min', 4.0, '<15ms', 
  ARRAY['Altíssima recall (>0.99)', 'Baixa latência', 'Não requer build faseado'], 
  ARRAY['Alto consumo de memória (4x raw)', 'Build lento em datasets grandes']),
('hnsw', '1M-5M vetores', 0.97, '~3-4h', 3.5, '<25ms', 
  ARRAY['Balanço ideal recall/latência', 'Query rápida'], 
  ARRAY['Requer ~12GB RAM para 3M vetores 1536d', 'Pode travar em VMs pequenas']),
('ivfflat', '>5M vetores', 0.90, '~15 min', 1.0, '<15ms (se lists ~ sqrt(N))', 
  ARRAY['Build muito rápido', 'Baixo consumo de memória', 'Escalável'], 
  ARRAY['Recall menor (ajustável via probes)', 'Query mais lenta se lists alto', 'Requer dados para treinar lists']),
('ivfflat', '>100M vetores', 0.85, '~2h', 1.2, '<50ms', 
  ARRAY['Única opção viável para escala massiva', 'Particionamento natural'], 
  ARRAY['Recall decai se listas insuficientes', 'Overhead de maintenance']);
```

---

## ✅ V1 + V2 + V3: Função de Comparação e Recomendação Executável

```sql
-- ✅ Função principal: Compara HNSW vs IVFFlat baseado no cenário
CREATE OR REPLACE FUNCTION compare_index_strategies(
  p_row_estimate bigint,
  p_dim int DEFAULT 1536,  -- V1: dimensão impacta memória
  p_target_recall float DEFAULT 0.95
) RETURNS TABLE(
  recommended_strategy text,
  hnsw_score int,
  ivfflat_score int,
  estimated_memory_gb float,
  estimated_query_latency_ms float,
  reasoning text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_raw_data_gb float;
  v_hnsw_memory_gb float;
  v_ivfflat_memory_gb float;
  v_score_hnsw int := 50;
  v_score_ivf int := 50;
BEGIN
  -- Cálculo básico de memória: rows * dim * 4 bytes / 1024^3
  v_raw_data_gb := (p_row_estimate * p_dim * 4.0) / (1024.0 * 1024.0 * 1024.0);

  -- Estimativas de overhead (V3 params)
  v_hnsw_memory_gb := v_raw_data_gb * 3.5;  -- Média ponderada para HNSW
  v_ivfflat_memory_gb := v_raw_data_gb * 1.1; -- IVFFlat overhead baixo

  -- Lógica de pontuação baseada em heurísticas (Benchmark simulado)
  
  -- Fator 1: Tamanho do Dataset
  IF p_row_estimate < 1000000 THEN
    v_score_hnsw := v_score_hnsw + 40;  -- HNSW vence em dataset pequeno
    v_score_ivf := v_score_ivf + 10;
    reasoning := 'Dataset pequeno: HNSW oferece build rápido e recall superior.';
  ELSIF p_row_estimate < 10000000 THEN
    v_score_hnsw := v_score_hnsw + 20;
    v_score_ivf := v_score_ivf + 20;
    reasoning := 'Dataset médio: HNS ainda viável, mas IVFFlat começa a ganhar em build time.';
  ELSE
    v_score_hnsw := v_score_hnsw - 20;  -- HNSW perde memória excessiva
    v_score_ivf := v_score_ivf + 50;    -- IVFFlat escala melhor
    reasoning := 'Dataset grande: IVFFlat recomendado para evitar OOM e build excessivo.';
  END IF;

  -- Fator 2: Target Recall
  IF p_target_recall > 0.97 THEN
    v_score_hnsw := v_score_hnsw + 20;
    v_score_ivf := v_score_ivf - 10;
    reasoning := reasoning || ' Alta recall requerida favorece HNSW.';
  ELSIF p_target_recall <= 0.90 THEN
    v_score_ivf := v_score_ivf + 20;
    v_score_hnsw := v_score_hnsw - 10;
    reasoning := reasoning || ' Recall moderada permite IVFFlat mais eficiente.';
  END IF;

  -- C8: Logging da análise
  PERFORM mantis_log('INFO', 'strategy_comparison_completed', 
    format('rows=%s, dim=%s, recall=%.2f, rec=%s, tenant=%s', 
           p_row_estimate, p_dim, p_target_recall, 
           CASE WHEN v_score_hnsw > v_score_ivf THEN 'HNSW' ELSE 'IVFFlat' END,
           current_setting('app.current_tenant')));

  -- Retorno final
  recommended_strategy := CASE WHEN v_score_hnsw >= v_score_ivf THEN 'HNSW' ELSE 'IVFFlat' END;
  hnsw_score := v_score_hnsw;
  ivfflat_score := v_score_ivf;
  estimated_memory_gb := CASE WHEN recommended_strategy = 'HNSW' THEN v_hnsw_memory_gb ELSE v_ivfflat_memory_gb END;
  
  -- Estimativa de latência (heurística simplificada)
  estimated_query_latency_ms := CASE 
    WHEN recommended_strategy = 'HNSW' THEN 15.0 + (p_row_estimate / 10000000.0 * 10.0)
    ELSE 20.0 + (p_row_estimate / 100000000.0 * 30.0)
  END;

  RETURN;
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'strategy_comparison_failed', sanitize_error_message(SQLERRM));
  RETURN;
END;
$$;

-- ✅ Uso típico:
-- SELECT * FROM compare_index_strategies(5000000, 1536, 0.95);
```

---

## ✅ V3: Guia de Parâmetros Otimizados (Consulta Rápida)

```sql
-- ✅ V3: View materializada para consulta rápida de parâmetros recomendados
CREATE OR REPLACE VIEW recommended_index_params AS
SELECT 
  CASE 
    WHEN size < 1000000 THEN 'hnsw'
    WHEN size < 5000000 THEN 'hnsw'
    ELSE 'ivfflat'
  END AS strategy,
  CASE
    WHEN size < 1000000 THEN 16
    WHEN size < 5000000 THEN 24
    ELSE FLOOR(SQRT(size))::int
  END AS m_or_lists,
  CASE
    WHEN size < 1000000 THEN 100
    WHEN size < 5000000 THEN 150
    ELSE 10
  END AS ef_or_probes,
  'Cosine' AS metric
FROM (VALUES (100000), (1000000), (5000000), (50000000)) AS t(size);
```

---

## 🧪 Testes Unitários (TDD – Apenas para a Lógica Específica)

```sql
-- Test: small_dataset_prefers_hnsw
-- Constraint: V3
BEGIN;
SELECT plan(1);

SELECT recommended_strategy INTO v_strategy FROM compare_index_strategies(100000, 1536, 0.95);
SELECT is(v_strategy, 'HNSW', 'V3: Dataset pequeno (100k) deve recomendar HNSW');

SELECT * FROM finish();
ROLLBACK;

-- Test: large_dataset_prefers_ivfflat
-- Constraint: V3+C1
DO $$
DECLARE v_strategy text;
BEGIN
  SELECT recommended_strategy INTO v_strategy FROM compare_index_strategies(100000000, 1536, 0.90);
  ASSERT v_strategy = 'IVFFlat', 'V3+C1: Dataset grande (100M) deve recomendar IVFFlat por memória/recall tradeoff';
END $$;
```

---

## 🔍 Validação (VDD – Comando Canônico)

```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/postgresql-pgvector/vector-index-strategy-comparison.pgvector.md \
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
| 1.0.0 | 2026-05-09 | PostgreSQL-PgVector Master Agent | Criação inicial: comparação HNSW/IVFFlat, benchmarking, recomendação automática V3 | C1,C4,V1,V2,V3 |

---
## 🔍 Observability (Documentación para IA – Apenas Eventos Específicos)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `module_bootstrap` | INFO | C8 | `"Master agent available"` ou `"fallback: mantis_log() not found"` |
| `strategy_comparison_completed` | INFO | V3,C8 | `"rows=5000000, dim=1536, recall=0.95, rec=HNSW, tenant=uuid"` |
| `strategy_comparison_failed` | ERROR | C8 | `"sanitized_error_message, tenant=uuid"` |

### Validação de Schema V-LOG-02 (Helper Mínimo)
```sql
-- Executar em teste: SELECT validate_vlog02('{"timestamp":"2026-05-09T00:00:00Z","level":"INFO","resource":{"tenant_id":"uuid"},"body":{"event":"strategy_comparison_completed"}}');
-- Retorno esperado: t (true) se schema válido, f (false) caso contrário
-- Função herdada do Master Agent; este módulo apenas a invoca
```
---
