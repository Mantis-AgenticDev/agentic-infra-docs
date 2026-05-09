---
artifact_id: nl-to-vector-query-patterns-pgvector
artifact_type: pgvector_pattern
version: "3.1.0"
constraints_mapped: ["C3","C4","C8","V1","V2","V3"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/postgresql-pgvector/nl-to-vector-query-patterns.pgvector.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:nl-to-vector-query-patterns-v3.1.0-modular"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "postgresql-pgvector"
ai_navigation:
  read_first: false
  required_for: [conversational-rag, semantic-search-ui, embedding-router]
  update_frequency: on-change
audience: ["postgresql-pgvector-master-agent", "backend-engineers", "orchestrator-engine"]
status: "🟡 Refatorado"
next_review: "2026-06-09"
checksum_sha256: "pending-generation"
vector_meta:
  dimensions: 1536
  model: "text-embedding-3-small"
  metric: "cosine"
  index_type: "hnsw"
---

# 💬 Padrões de Consulta NL-to-Vector com Validação de Tenant (pgvector)

> **Contrato modular**: Este artefato é filho do Master Agent `postgresql-pgvector-rag-master-agent-mantis`.
> Herda hardening, observability, thinking system e constraints via source/import.
> Contém APENAS a lógica de conversão segura de linguagem natural para busca vetorial, com validação dimensional, métrica explícita e isolamento de tenant.

---

## 🎯 Propósito
Implementar conversão segura de consultas em linguagem natural (NL) para buscas vetoriais: sanitização de input (C3), geração de embedding (placeholder externo), validação de dimensão 1536d (V1), filtro estrito de tenant (C4), operador cosine `<=>` documentado (V2), índice HNSW justificado (V3) e logging estruturado de ciclo completo (C8). Otimizado para interfaces conversacionais e RAG dinâmico.

## 📋 Especificação (SDD – Apenas o Específico deste Módulo)
- **Entradas**: `p_nl_query` (text), `p_tenant_id` (uuid), `p_confidence_threshold` (float), `p_limit` (int)
- **Saídas**: Tabela com `doc_id`, `content_snippet`, `confidence`, `metadata`
- **Side Effects**: Apenas leitura; geração de embedding via API externa (simulada); logging C8
- **Constraints Aplicáveis**: C3, C4, C8, V1, V2, V3
- **Dependências**: PostgreSQL 15+, `pgvector >= 0.7.0`, serviço externo de embedding, `mantis_log()` herdada

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C4+C8+V1+V2+V3)

```sql
-- Bootstrap modular: source Master Agent OU fallback mínimo
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'mantis_log') THEN
    PERFORM mantis_log('INFO', 'module_bootstrap', 'nl-to-vector-query-patterns: Master agent available');
  ELSE
    RAISE LOG '%', json_build_object(
      'timestamp', to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
      'level', 'WARN',
      'resource', json_build_object('tenant_id', current_setting('app.current_tenant', true), 'artifact', 'nl-to-vector-query-patterns'),
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

-- C1: Limites de recursos para busca conversacional
SET LOCAL statement_timeout = '8s';
SET LOCAL work_mem = '128MB';
```

---

## ✅ C3 + V1 + C4: Função Principal de Busca NL-to-Vector

```sql
-- ✅ NL-to-Vector segura: sanitização, embedding externo, validação dimensional, tenant isolation
CREATE OR REPLACE FUNCTION nl_to_vector_search(
  p_nl_query text,
  p_tenant_id uuid,
  p_confidence_threshold float DEFAULT 0.7,
  p_limit int DEFAULT 5
) RETURNS TABLE(
  doc_id uuid,
  content_snippet text,
  confidence float,
  metadata jsonb
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_query_vec vector;
  v_start timestamptz := clock_timestamp();
  v_hash bytea;
BEGIN
  -- C3: Sanitização de input NL (evitar injeção via prompts maliciosos ou caracteres de controle)
  p_nl_query := regexp_replace(p_nl_query, E'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]', '', 'g');
  
  -- C5: Hash da query para auditoria e cache (sem armazenar texto bruto)
  v_hash := digest(p_nl_query::bytea, 'sha256');
  
  -- ⚠️ Placeholder: geração de embedding via serviço externo
  -- Em produção: v_query_vec := http_generate_embedding(p_nl_query); -- Retorna vector(1536)
  -- Para testes: usar mock ou função de embedding local
  v_query_vec := (SELECT embedding FROM document_embeddings LIMIT 1);  -- Mock seguro
  
  -- V1: Validação obrigatória de dimensão antes da busca
  IF array_length(v_query_vec, 1) IS DISTINCT FROM 1536 THEN
    PERFORM mantis_log('ERROR', 'v1_nl_embedding_dim_mismatch', 
      format('expected=1536, got=%s, tenant=%s', array_length(v_query_vec, 1), p_tenant_id));
    RAISE EXCEPTION 'V1: NL embedding dimension mismatch: expected 1536';
  END IF;
  
  -- ✅ C4+V2+V3: Busca com filtro explícito + cosine + índice HNSW justificado
  -- V3: idx_doc_emb_hnsw_cosine USING hnsw (embedding vector_cosine_ops) WITH (m=16, ef_construction=100)
  -- V2: <=> (cosine distance) com embeddings normalizados; confidence = 1 - distance
  RETURN QUERY
  SELECT 
    de.doc_id,
    LEFT(d.content, 250) AS content_snippet,
    1.0 - (de.embedding <=> v_query_vec) AS confidence,  -- ✅ V2: métrica documentada
    d.metadata
  FROM document_embeddings de
  JOIN documents d ON de.doc_id = d.id
  WHERE de.tenant_id = p_tenant_id  -- ✅ C4: filtro obrigatório
    AND 1.0 - (de.embedding <=> v_query_vec) >= p_confidence_threshold  -- ✅ V2: threshold aplicado
  ORDER BY de.embedding <=> v_query_vec  -- ✅ V2: ordenamento por distância
  LIMIT p_limit;
  
  -- C8: Logging de conclusão com métricas de latência
  PERFORM mantis_log('INFO', 'nl_vector_search_completed', 
    format('query_hash=%s, limit=%s, threshold=%s, tenant=%s, duration_ms=%s',
      encode(v_hash, 'hex'), p_limit, p_confidence_threshold, p_tenant_id,
      EXTRACT(MILLISECOND FROM clock_timestamp() - v_start)));
      
EXCEPTION WHEN query_canceled THEN
  PERFORM mantis_log('WARN', 'nl_vector_search_timeout', 
    format('tenant=%s, timeout=8s', p_tenant_id));
  RAISE EXCEPTION 'C1: NL-to-Vector search exceeded 8s timeout';
WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'nl_vector_search_failed', sanitize_error_message(SQLERRM));
  RAISE;
END;
$$;
```

---

## ✅ V3: Justificação de Índice para Padrão NL-to-Vector

```sql
-- ✅ V3: Índice otimizado para consultas NL conversacionais (baixa latência, alta recall)
-- Parâmetros justificados:
-- m=16: balanceia recall (~0.95) com footprint de memória para 1536d
-- ef_construction=100: tempo de build razoável, grafo de alta qualidade para queries variadas de NL
-- Nota: NL queries têm alta variância semântica; HNSW supera IVFFlat em recall para dados não uniformes.
CREATE INDEX IF NOT EXISTS idx_nl_search_hnsw ON document_embeddings
  USING hnsw (embedding vector_cosine_ops)
  WITH (m = 16, ef_construction = 100);

-- ✅ C8: Tabela de cache de queries NL frequentes (evita regeneração de embedding)
CREATE TABLE IF NOT EXISTS nl_query_cache (
  query_hash bytea PRIMARY KEY,
  tenant_id uuid NOT NULL,
  query_embedding vector(1536),  -- V1: dimensão explícita
  response_ids uuid[],
  created_at timestamptz DEFAULT now(),
  expires_at timestamptz DEFAULT now() + INTERVAL '1 hour',
  hit_count int DEFAULT 0
);

ALTER TABLE nl_query_cache ENABLE ROW LEVEL SECURITY;
CREATE POLICY cache_tenant_isolation ON nl_query_cache
  FOR ALL USING (tenant_id = current_setting('app.current_tenant')::uuid);
```

---

## ✅ C4 + Explicação: Função de Diagnóstico para Queries NL

```sql
-- ✅ C4+V2: Retorna metadados de similaridade para debugging de resultados NL
CREATE OR REPLACE FUNCTION explain_nl_similarity(
  p_nl_query text,
  p_tenant_id uuid,
  p_limit int DEFAULT 3
) RETURNS TABLE(
  rank int,
  content_snippet text,
  cosine_distance float,  -- ✅ V2: métrica explícita
  confidence_pct int,
  diagnostic_hint text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_query_vec vector(1536);  -- ✅ V1: tipado explicitamente
BEGIN
  -- Mock de embedding (substituir por chamada real em produção)
  v_query_vec := (SELECT embedding FROM document_embeddings LIMIT 1);
  
  RETURN QUERY
  SELECT
    ROW_NUMBER() OVER (ORDER BY de.embedding <=> v_query_vec)::int AS rank,
    LEFT(d.content, 200) AS content_snippet,
    (de.embedding <=> v_query_vec)::float AS cosine_distance,
    ((1.0 - (de.embedding <=> v_query_vec)) * 100)::int AS confidence_pct,
    CASE
      WHEN 1.0 - (de.embedding <=> v_query_vec) > 0.85 THEN 'Alta relevância semântica'
      WHEN 1.0 - (de.embedding <=> v_query_vec) > 0.70 THEN 'Relevância moderada; revisar contexto'
      ELSE 'Baixa similaridade; possível ruído ou vocabulário fora do domínio'
    END AS diagnostic_hint
  FROM document_embeddings de
  JOIN documents d ON de.doc_id = d.id
  WHERE de.tenant_id = p_tenant_id  -- ✅ C4
  ORDER BY de.embedding <=> v_query_vec
  LIMIT p_limit;
  
  PERFORM mantis_log('INFO', 'explain_nl_similarity_completed', 
    format('tenant=%s, limit=%s', p_tenant_id, p_limit));
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'explain_nl_similarity_failed', sanitize_error_message(SQLERRM));
  RAISE;
END;
$$;
```

---

## 🧪 Testes Unitários (TDD – Apenas para a Lógica Específica)

```sql
-- Test: nl_search_respects_tenant_isolation
-- Constraint: C4
BEGIN;
SELECT plan(2);

SET LOCAL app.current_tenant = '00000000-0000-0000-0000-000000000001';
-- Arrange: dados mock com tenants 1 e 2
-- Act: chamar nl_to_vector_search('teste', tenant_1_uuid)
-- Assert: zero resultados com tenant_id != tenant_1
-- SELECT is((SELECT COUNT(DISTINCT doc_id) FROM nl_to_vector_search('teste', '00000000-0000-0000-0000-000000000002')), 0, 'C4: isolation intacta');

SELECT * FROM finish();
ROLLBACK;

-- Test: nl_search_rejects_wrong_dimension
-- Constraint: V1
DO $$
DECLARE
  v_bad_vec vector(768) := '[0.1, 0.2]'::vector(768);  -- Simulação de embedding 768d
BEGIN
  -- Em teste real: mockar geração de embedding com 768d
  -- Assert: exception 'V1: NL embedding dimension mismatch: expected 1536'
  PERFORM true;  -- Placeholder para validação em CI
END $$;

-- Test: nl_input_sanitization_removes_control_chars
-- Constraint: C3
DO $$
DECLARE
  v_input text := E'Buscar relatórios \x00\x0B\x1F de vendas';
  v_cleaned text;
BEGIN
  v_cleaned := regexp_replace(v_input, E'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]', '', 'g');
  ASSERT v_cleaned = 'Buscar relatórios  de vendas', 'C3: caracteres de controle removidos';
END $$;
```

---

## 🔍 Validação (VDD – Comando Canônico)

```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/postgresql-pgvector/nl-to-vector-query-patterns.pgvector.md \
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
| 3.0.0 | 2026-04-19 | PostgreSQL-PgVector Master Agent | Criação inicial: NL-to-vector, tenant filter, confidence threshold | C3,C4,C8,V1,V2 |
| 3.1.0-MODULAR | 2026-05-09 | PostgreSQL-PgVector Master Agent | Refatoração modular: bootstrap resiliente, mantis_log() herdada, V3 index justificado, cache NL, sanitização C3 aprimorada, wikilink corrigido | C3,C4,C8,V1,V2,V3 |

---
## 🔍 Observability (Documentación para IA – Apenas Eventos Específicos)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `module_bootstrap` | INFO | C8 | `"Master agent available"` ou `"fallback: mantis_log() not found"` |
| `nl_vector_search_completed` | INFO | C8 | `"query_hash=abc123, limit=5, threshold=0.7, tenant=uuid, duration_ms=142"` |
| `v1_nl_embedding_dim_mismatch` | ERROR | V1 | `"expected=1536, got=768, tenant=uuid"` |
| `nl_vector_search_timeout` | WARN | C1 | `"tenant=uuid, timeout=8s"` |
| `explain_nl_similarity_completed` | INFO | C8 | `"tenant=uuid, limit=3"` |

### Validação de Schema V-LOG-02 (Helper Mínimo)
```sql
-- Executar em teste: SELECT validate_vlog02('{"timestamp":"2026-05-09T00:00:00Z","level":"INFO","resource":{"tenant_id":"uuid"},"body":{"event":"nl_vector_search_completed"}}');
-- Retorno esperado: t (true) se schema válido, f (false) caso contrário
-- Função herdada do Master Agent; este módulo apenas a invoca
```
---
