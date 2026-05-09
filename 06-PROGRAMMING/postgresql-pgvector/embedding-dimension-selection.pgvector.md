---
artifact_id: embedding-dimension-selection-pgvector
artifact_type: pgvector_guide
version: "1.0.0"
constraints_mapped: ["C4","C5","V1","V2"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/postgresql-pgvector/embedding-dimension-selection.pgvector.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:embedding-dimension-selection-v1.0.0-modular"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "postgresql-pgvector"
ai_navigation:
  read_first: false
  required_for: [model-selection, memory-estimation, recall-vs-latency-tuning, schema-design]
  update_frequency: on-change
audience: ["postgresql-pgvector-master-agent", "ml-engineers", "db-architects", "orchestrator-engine"]
status: "🟢 Novo"
next_review: "2026-06-09"
checksum_sha256: "pending-generation"
vector_meta:
  dimensions: 1536
  model: "text-embedding-3-small"
  metric: "cosine"
  index_type: "hnsw"
---

# 📐 Seleção de Dimensões de Embedding: Modelo, Recurso e Trade-offs (pgvector)

> **Contrato modular**: Este artefato é filho do Master Agent `postgresql-pgvector-rag-master-agent-mantis`.
> Herda hardening, observability, thinking system e constraints via source/import.
> Contém APENAS a lógica de decisão dimensional, cálculo de footprint de memória, validação de compatibilidade com modelo e recomendações de índice baseadas em dimensão.

---

## 🎯 Propósito
Fornecer guia executável e funções SQL para seleção de dimensões de embedding (384, 768, 1536, 3072) conforme modelo de embedding e caso de uso, com cálculo de memória por vetor (float32 = 4 bytes/dim), impacto em recall/latência, validação de compatibilidade com operador de métrica (V2) e aplicação de contexto de tenant (C4). Otimizado para design de schema e tuning de infraestrutura RAG enterprise.

## 📋 Especificação (SDD – Apenas o Específico deste Módulo)
- **Entradas**: `p_model_name` (text), `p_target_dim` (int), `p_row_estimate` (bigint)
- **Saídas**: Matriz de decisão, cálculo de memória (MB), validação booleana, recomendações de índice
- **Side Effects**: Apenas leitura e logging C8; nenhuma criação de tabela ou índice permanente
- **Constraints Aplicáveis**: C4, C5, V1, V2 (C8 herdada via `mantis_log()`)
- **Dependências**: PostgreSQL 14+, `pgvector >= 0.7.0`, tabela de referência `embedding_model_specs`, `mantis_log()` herdada

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C4+C5+V1+V2)

```sql
-- Bootstrap modular: source Master Agent OU fallback mínimo
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'mantis_log') THEN
    PERFORM mantis_log('INFO', 'module_bootstrap', 'embedding-dimension-selection: Master agent available');
  ELSE
    RAISE LOG '%', json_build_object(
      'timestamp', to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
      'level', 'WARN',
      'resource', json_build_object('tenant_id', current_setting('app.current_tenant', true), 'artifact', 'embedding-dimension-selection'),
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

-- C1: Limites de recursos para operações de cálculo/consulta
SET LOCAL statement_timeout = '10s';
SET LOCAL work_mem = '64MB';
```

---

## ✅ C5 + V1: Tabela de Referência de Modelos e Dimensões

```sql
-- ✅ C5: Especificações canônicas de modelos (populada uma vez; referência para IA/engenheiros)
CREATE TABLE IF NOT EXISTS embedding_model_specs (
  model_name text PRIMARY KEY,
  dimensions int NOT NULL,
  recommended_metric text NOT NULL DEFAULT 'cosine',
  memory_per_vector_bytes int GENERATED ALWAYS AS (dimensions * 4) STORED,  -- float32
  recall_tier text,  -- "standard", "high", "ultra"
  typical_use_cases text[],
  hnsw_m_recommendation int,
  hnsw_ef_construction_recommendation int,
  created_at timestamptz DEFAULT now()
);

-- Dados de referência (benchmarks públicos + documentação de provedores)
INSERT INTO embedding_model_specs (model_name, dimensions, recommended_metric, recall_tier, typical_use_cases, hnsw_m_recommendation, hnsw_ef_construction_recommendation) VALUES
('text-embedding-3-small', 1536, 'cosine', 'high', ARRAY['RAG empresarial', 'busca semântica', 'classificação de documentos'], 16, 100),
('text-embedding-3-large', 3072, 'cosine', 'ultra', ARRAY['pesquisa acadêmica', 'análise legal', 'finanças de alta precisão'], 24, 150),
('nomic-embed-text-v1.5', 768, 'cosine', 'standard', ARRAY['IoT edge', 'chatbots leves', 'categorização rápida'], 12, 80),
('bge-small-en-v1.5', 384, 'cosine', 'standard', ARRAY['mobile apps', 'classificação rápida', 'filtros de spam'], 8, 64),
('all-MiniLM-L6-v2', 384, 'cosine', 'standard', ARRAY['dev environments', 'prototipagem', 'busca local'], 8, 64)
ON CONFLICT (model_name) DO NOTHING;
```

---

## ✅ V1 + V2 + C4: Função de Validação e Recomendação Dimensional

```sql
-- ✅ V1+V2: Validar se dimensão e métrica são compatíveis com modelo selecionado
CREATE OR REPLACE FUNCTION validate_and_recommend_dimension(
  p_model_name text,
  p_proposed_dim int,
  p_proposed_metric text DEFAULT 'cosine'
) RETURNS TABLE(
  is_compatible boolean,
  recommended_dim int,
  memory_per_vector_mb float,
  index_recommendation text,
  warning_message text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_spec RECORD;
  v_memory_bytes int;
BEGIN
  SELECT * INTO v_spec FROM embedding_model_specs WHERE model_name = p_model_name;
  
  IF NOT FOUND THEN
    RETURN QUERY SELECT 
      false, 
      COALESCE(v_spec.dimensions, 1536),
      0.0,
      'Modelo não reconhecido. Usando padrão 1536d.',
      'Modelo não encontrado na tabela de referência. Verificar documentação do provedor.';
    RETURN;
  END IF;

  is_compatible := (p_proposed_dim = v_spec.dimensions);
  recommended_dim := v_spec.dimensions;
  v_memory_bytes := v_spec.dimensions * 4;  -- float32
  memory_per_vector_mb := v_memory_bytes::float / (1024.0 * 1024.0);

  -- V2: Validar métrica
  IF p_proposed_metric <> v_spec.recommended_metric THEN
    warning_message := format('Métrica proposta (%s) difere da recomendada para %s (%s). Impacto em recall esperado.', 
                              p_proposed_metric, p_model_name, v_spec.recommended_metric);
  ELSE
    warning_message := NULL;
  END IF;

  -- V3: Recomendação de índice baseada em dimensão
  index_recommendation := format(
    'HNSW com m=%s, ef_construction=%s | Memória estimada: %.2f MB por 1M vetores',
    v_spec.hnsw_m_recommendation, 
    v_spec.hnsw_ef_construction_recommendation,
    memory_per_vector_mb * 1000000.0
  );

  -- C8: Logging da avaliação
  PERFORM mantis_log('INFO', 'dimension_recommendation_generated', 
    format('model=%s, proposed_dim=%s, compatible=%s, tenant=%s', 
           p_model_name, p_proposed_dim, is_compatible, current_setting('app.current_tenant')));

  RETURN;
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'dimension_validation_failed', sanitize_error_message(SQLERRM));
  RETURN;
END;
$$;

-- ✅ Uso típico:
-- SELECT * FROM validate_and_recommend_dimension('text-embedding-3-small', 1536, 'cosine');
```

---

## ✅ C5 + C4: Calculadora de Footprint de Memória para Planejamento

```sql
-- ✅ C5+C4: Estimar consumo total de RAM para tabela de embeddings + índice HNSW
CREATE OR REPLACE FUNCTION estimate_embedding_storage_footprint(
  p_estimated_rows bigint,
  p_dimensions int DEFAULT 1536,
  p_hnsw_overhead_factor float DEFAULT 4.0  -- HNSW overhead típico para 1536d
) RETURNS TABLE(
  raw_vector_data_mb float,
  index_overhead_mb float,
  total_estimated_mb float,
  total_estimated_gb float,
  recommendation text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_raw_mb float;
  v_index_mb float;
BEGIN
  -- Cálculo base: rows * dimensions * 4 bytes (float32)
  v_raw_mb := (p_estimated_rows * p_dimensions * 4.0) / (1024.0 * 1024.0);
  v_index_mb := v_raw_mb * p_hnsw_overhead_factor;

  total_estimated_mb := v_raw_mb + v_index_mb;
  total_estimated_gb := total_estimated_mb / 1024.0;

  recommendation := CASE
    WHEN total_estimated_gb > 50 THEN 'Considere IVFFlat, particionamento ou compressão (bit/half-precision)'
    WHEN total_estimated_gb > 10 THEN 'HNSW viável, mas monitore work_mem e maintenance_work_mem'
    ELSE 'HNSW otimizado para esta escala. Parâmetros padrão recomendados.'
  END;

  PERFORM mantis_log('INFO', 'memory_footprint_estimated', 
    format('rows=%s, dim=%s, total_gb=%.2f, rec=%s, tenant=%s', 
           p_estimated_rows, p_dimensions, total_estimated_gb, recommendation, current_setting('app.current_tenant')));

  RETURN;
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'footprint_estimation_failed', sanitize_error_message(SQLERRM));
  RETURN;
END;
$$;

-- ✅ Uso típico:
-- SELECT * FROM estimate_embedding_storage_footprint(5000000, 1536, 4.0);
```

---

## 🧪 Testes Unitários (TDD – Apenas para a Lógica Específica)

```sql
-- Test: validate_and_recommend_dimension_returns_compatible_true_for_exact_match
-- Constraint: V1
BEGIN;
SELECT plan(2);

-- Arrange/Act
SELECT is_compatible INTO v_result FROM validate_and_recommend_dimension('text-embedding-3-small', 1536, 'cosine');

-- Assert
SELECT ok(v_result, 'V1: dimensão 1536 deve ser compatível com text-embedding-3-small');
SELECT ok((SELECT memory_per_vector_mb FROM validate_and_recommend_dimension('bge-small-en-v1.5', 384, 'cosine')) > 0, 'C5: cálculo de memória deve retornar valor positivo');

SELECT * FROM finish();
ROLLBACK;

-- Test: estimate_footprint_returns_correct_scale_recommendation
-- Constraint: C5
DO $$
DECLARE v_rec text;
BEGIN
  SELECT recommendation INTO v_rec FROM estimate_embedding_storage_footprint(100, 1536);
  ASSERT v_rec LIKE '%HNSW otimizado%', 'C5: escala pequena deve recomendar HNSW padrão';
END $$;
```

---

## 🔍 Validação (VDD – Comando Canônico)

```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/postgresql-pgvector/embedding-dimension-selection.pgvector.md \
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
| 1.0.0 | 2026-05-09 | PostgreSQL-PgVector Master Agent | Criação inicial: seleção dimensional, cálculo de memória, validação V1/V2, recomendações de índice | C4,C5,V1,V2 |

---
## 🔍 Observability (Documentación para IA – Apenas Eventos Específicos)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `module_bootstrap` | INFO | C8 | `"Master agent available"` ou `"fallback: mantis_log() not found"` |
| `dimension_recommendation_generated` | INFO | V1,V2,C8 | `"model=text-embedding-3-small, proposed_dim=1536, compatible=true, tenant=uuid"` |
| `memory_footprint_estimated` | INFO | C5,C8 | `"rows=5000000, dim=1536, total_gb=28.61, rec=HNSW viável..., tenant=uuid"` |
| `dimension_validation_failed` | ERROR | C8 | `"sanitized_error_message, tenant=uuid"` |

### Validação de Schema V-LOG-02 (Helper Mínimo)
```sql
-- Executar em teste: SELECT validate_vlog02('{"timestamp":"2026-05-09T00:00:00Z","level":"INFO","resource":{"tenant_id":"uuid"},"body":{"event":"dimension_recommendation_generated"}}');
-- Retorno esperado: t (true) se schema válido, f (false) caso contrário
-- Função herdada do Master Agent; este módulo apenas a invoca
```
---
