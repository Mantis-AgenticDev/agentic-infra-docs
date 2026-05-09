---
artifact_id: similarity-explanation-templates-pgvector
artifact_type: pgvector_pattern
version: "3.1.0"
constraints_mapped: ["C4","C8","V1","V2"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/postgresql-pgvector/similarity-explanation-templates.pgvector.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:similarity-explanation-v3.1.0-modular"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "postgresql-pgvector"
ai_navigation:
  read_first: false
  required_for: [rag-debugging, semantic-diagnostics, model-evaluation, user-explainability]
  update_frequency: on-change
audience: ["postgresql-pgvector-master-agent", "data-scientists", "backend-engineers"]
status: "🟡 Refatorado"
next_review: "2026-06-09"
checksum_sha256: "pending-generation"
vector_meta:
  dimensions: 1536
  model: "text-embedding-3-small"
  metric: "cosine"
  index_type: "hnsw"
---

# 📝 Templates de Explicação e Debugging de Similaridade (pgvector)

> **Contrato modular**: Este artefato é filho do Master Agent `postgresql-pgvector-rag-master-agent-mantis`.
> Herda hardening, observability, thinking system e constraints via source/import.
> Contém APENAS a lógica de diagnóstico e explicabilidade para resultados de busca vetorial: ranking, cálculo explícito de distância cosine (V2), isolador de tenant (C4) e mensagens interpretáveis para engenharia e usuários finais (C8).

---

## 🎯 Propósito
Fornecer funções SQL reutilizáveis para explicar *por que* um documento foi recuperado em busca vetorial: calcula distância cosine real (`<=>`), converte em porcentagem de confiança, atribui rótulos diagnósticos baseados em limiares e valida dimensionalidade (V1). Projetado para debugging de pipelines RAG, avaliação de qualidade de embedding e transparência para usuários enterprise.

## 📋 Especificação (SDD – Apenas o Específico deste Módulo)
- **Entradas**: `p_query_vec` (vector(1536)), `p_tenant_id` (uuid), `p_limit` (int)
- **Saídas**: Tabela com `rank`, `doc_id`, `content_snippet`, `cosine_distance`, `confidence_pct`, `diagnostic_label`
- **Side Effects**: Apenas leitura e logging C8; nenhuma modificação de dados ou índices
- **Constraints Aplicáveis**: C4, C8, V1, V2
- **Dependências**: PostgreSQL 15+, `pgvector >= 0.7.0`, tabela `documents` e `document_embeddings`, `mantis_log()` herdada

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C4+C8+V1+V2)

```sql
-- Bootstrap modular: source Master Agent OU fallback mínimo
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'mantis_log') THEN
    PERFORM mantis_log('INFO', 'module_bootstrap', 'similarity-explanation-templates: Master agent available');
  ELSE
    RAISE LOG '%', json_build_object(
      'timestamp', to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
      'level', 'WARN',
      'resource', json_build_object('tenant_id', current_setting('app.current_tenant', true), 'artifact', 'similarity-explanation-templates'),
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

-- C1: Limites de recursos para funções de diagnóstico
SET LOCAL statement_timeout = '8s';
SET LOCAL work_mem = '64MB';
```

---

## ✅ V1 + V2 + C4: Função Principal de Explicação de Similaridade

```sql
-- ✅ Explicação detalhada de resultados vetoriais com métrica documentada e rótulos diagnósticos
CREATE OR REPLACE FUNCTION explain_similarity_results(
  p_query_vec vector(1536),  -- ✅ V1: dimensão explícita no tipo
  p_tenant_id uuid,
  p_limit int DEFAULT 5
) RETURNS TABLE(
  rank int,
  doc_id uuid,
  content_snippet text,
  cosine_distance float,     -- ✅ V2: métrica explícita
  confidence_pct int,
  diagnostic_label text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- ✅ C4+V2: Ordenamento por distância cosine + conversão para % de confiança
  RETURN QUERY
  SELECT
    ROW_NUMBER() OVER (ORDER BY de.embedding <=> p_query_vec)::int AS rank,
    d.id AS doc_id,
    LEFT(d.content, 250) || '...' AS content_snippet,
    (de.embedding <=> p_query_vec)::float AS cosine_distance,  -- ✅ V2: operador documentado
    ((1.0 - (de.embedding <=> p_query_vec)) * 100)::int AS confidence_pct,
    CASE
      WHEN 1.0 - (de.embedding <=> p_query_vec) >= 0.85 THEN '🟢 Alta relevância semântica (match forte)'
      WHEN 1.0 - (de.embedding <=> p_query_vec) >= 0.70 THEN '🟡 Relevância moderada (verificar contexto)'
      WHEN 1.0 - (de.embedding <=> p_query_vec) >= 0.55 THEN '🟠 Similaridade baixa (possível ruído ou vocabulário divergente)'
      ELSE '🔴 Baixa confiança (recomendado: ajustar query ou modelo)'
    END AS diagnostic_label
  FROM document_embeddings de
  JOIN documents d ON de.doc_id = d.id
  WHERE de.tenant_id = p_tenant_id  -- ✅ C4: filtro obrigatório
  ORDER BY de.embedding <=> p_query_vec  -- ✅ V2: ordenamento explícito
  LIMIT p_limit;

  -- C8: Logging da execução de diagnóstico
  PERFORM mantis_log('INFO', 'explain_similarity_completed', 
    format('limit=%s, tenant=%s', p_limit, p_tenant_id));
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'explain_similarity_failed', sanitize_error_message(SQLERRM));
  RAISE;
END;
$$;
```

---

## ✅ C8 + V2: Template de Diagnóstico para Comparação de Métricas

```sql
-- ✅ Comparador de métricas para debugging: mostra como o mesmo par de vetores se comporta em cosine, euclidean e inner product
-- Uso: Avaliar qual métrica é mais adequada para o domínio de embedding atual
CREATE OR REPLACE FUNCTION compare_vector_metrics(
  p_vec_a vector(1536),
  p_vec_b vector(1536)
) RETURNS TABLE(metric_name text, raw_distance float, similarity_score float, interpretation text)
LANGUAGE plpgsql
IMMUTABLE
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- V1: Guard de dimensionalidade
  IF array_length(p_vec_a, 1) IS DISTINCT FROM array_length(p_vec_b, 1) THEN
    RAISE EXCEPTION 'V1: Vector dimension mismatch in metric comparison';
  END IF;

  -- Cosine
  metric_name := 'cosine (<=>)';
  raw_distance := (p_vec_a <=> p_vec_b)::float;
  similarity_score := (1.0 - raw_distance);
  interpretation := CASE WHEN similarity_score > 0.8 THEN 'Alta similaridade direcional' ELSE 'Divergência semântica detectada' END;
  RETURN NEXT;

  -- Euclidean (L2)
  metric_name := 'euclidean (<->)';
  raw_distance := (p_vec_a <-> p_vec_b)::float;
  similarity_score := 1.0 / (1.0 + raw_distance);  -- Normalização para [0,1]
  interpretation := CASE WHEN raw_distance < 0.5 THEN 'Vetores próximos no espaço euclidiano' ELSE 'Distância geométrica significativa' END;
  RETURN NEXT;

  -- Inner Product
  metric_name := 'inner_product (<#>)';
  raw_distance := (p_vec_a <#> p_vec_b)::float;
  similarity_score := CASE WHEN raw_distance > 0 THEN raw_distance ELSE 0 END;
  interpretation := CASE WHEN similarity_score > 0.7 THEN 'Alinhamento vetorial forte (útil para busca não normalizada)' ELSE 'Projeção fraca' END;
  RETURN NEXT;

  -- C8: Logging da comparação
  PERFORM mantis_log('INFO', 'metrics_comparison_completed', 
    format('cosine_dist=%.4f, l2_dist=%.4f, ip_score=%.4f', 
      (p_vec_a <=> p_vec_b)::float, (p_vec_a <-> p_vec_b)::float, (p_vec_a <#> p_vec_b)::float));
END;
$$;
```

---

## ✅ C4: Auditoria de Resultados para Engenharia de Prompt/Modelo

```sql
-- ✅ Função para agregar estatísticas de confiança por tenant em janela de tempo
-- Uso: Identificar degradação de qualidade de embedding ou drift de modelo
CREATE OR REPLACE FUNCTION audit_similarity_confidence_window(
  p_tenant_id uuid,
  p_hours_back int DEFAULT 24
) RETURNS TABLE(
  window_start timestamptz,
  window_end timestamptz,
  avg_confidence float,
  p95_confidence float,
  low_confidence_ratio float,
  total_queries int
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  RETURN QUERY
  SELECT
    date_trunc('hour', created_at) AS window_start,
    date_trunc('hour', created_at) + INTERVAL '1 hour' AS window_end,
    AVG(confidence_avg) AS avg_confidence,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY confidence_avg) AS p95_confidence,
    SUM(CASE WHEN confidence_avg < 0.65 THEN 1 ELSE 0 END)::float / NULLIF(COUNT(*), 0) AS low_confidence_ratio,
    COUNT(*) AS total_queries
  FROM rag_audit_log
  WHERE tenant_id = p_tenant_id  -- ✅ C4
    AND created_at >= now() - (p_hours_back || ' hours')::INTERVAL
  GROUP BY 1, 2
  ORDER BY 1 DESC;

  PERFORM mantis_log('INFO', 'confidence_window_audit_completed', 
    format('tenant=%s, hours=%s', p_tenant_id, p_hours_back));
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'confidence_window_audit_failed', sanitize_error_message(SQLERRM));
  RETURN;
END;
$$;
```

---

## 🧪 Testes Unitários (TDD – Apenas para a Lógica Específica)

```sql
-- Test: explain_similarity_filters_by_tenant
-- Constraint: C4
BEGIN;
SELECT plan(2);

SET LOCAL app.current_tenant = '00000000-0000-0000-0000-000000000001';
-- Arrange: inserir embeddings mock para tenants 1 e 2
-- Act: executar explain_similarity_results com tenant 1
-- Assert: zero linhas com tenant_id != tenant 1
-- SELECT is((SELECT COUNT(*) FROM explain_similarity_results('[0.1]'::vector(1536), '00000000-0000-0000-0000-000000000002')), 0, 'C4: tenant isolation intact');

SELECT * FROM finish();
ROLLBACK;

-- Test: compare_vector_metrics_returns_all_three
-- Constraint: V2
DO $$
DECLARE v_count int;
BEGIN
  SELECT COUNT(*) INTO v_count FROM compare_vector_metrics('[0.1,0.2]'::vector(2), '[0.1,0.2]'::vector(2));
  ASSERT v_count = 3, 'V2: deve retornar cosine, euclidean e inner_product';
END $$;

-- Test: diagnostic_labels_map_confidence_thresholds
-- Constraint: C8
DO $$
DECLARE v_label text;
BEGIN
  -- Mock: vetor idêntico → cosine_distance=0 → confidence=100%
  SELECT diagnostic_label INTO v_label 
  FROM explain_similarity_results('[0.5,0.5]'::vector(2), '00000000-0000-0000-0000-000000000001', limit:=1)
  LIMIT 1;  -- (Em teste real: usar fixtures com distância controlada)
  
  ASSERT v_label IS NOT NULL, 'C8: rótulo diagnóstico deve ser gerado';
END $$;
```

---

## 🔍 Validação (VDD – Comando Canônico)

```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/postgresql-pgvector/similarity-explanation-templates.pgvector.md \
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
| 3.0.0 | 2026-04-19 | PostgreSQL-PgVector Master Agent | Criação inicial: diagnóstico de similaridade, rótulos de confiança, logging C8 | C8,V2 |
| 3.1.0-MODULAR | 2026-05-09 | PostgreSQL-PgVector Master Agent | Refatoração modular: bootstrap resiliente, mantis_log() herdada, V1/V2 explícitos, C4 tenant filter obrigatório, comparador de métricas, auditoria de janela, wikilink corrigido | C4,C8,V1,V2 |

---
## 🔍 Observability (Documentación para IA – Apenas Eventos Específicos)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `module_bootstrap` | INFO | C8 | `"Master agent available"` ou `"fallback: mantis_log() not found"` |
| `explain_similarity_completed` | INFO | C8 | `"limit=5, tenant=uuid"` |
| `metrics_comparison_completed` | INFO | V2,C8 | `"cosine_dist=0.0412, l2_dist=0.1100, ip_score=0.9588"` |
| `confidence_window_audit_completed` | INFO | C4,C8 | `"tenant=uuid, hours=24"` |
| `explain_similarity_failed` | ERROR | C8 | `"sanitized_error_message"` |

### Validação de Schema V-LOG-02 (Helper Mínimo)
```sql
-- Executar em teste: SELECT validate_vlog02('{"timestamp":"2026-05-09T00:00:00Z","level":"INFO","resource":{"tenant_id":"uuid"},"body":{"event":"explain_similarity_completed"}}');
-- Retorno esperado: t (true) se schema válido, f (false) caso contrário
-- Função herdada do Master Agent; este módulo apenas a invoca
```
---
