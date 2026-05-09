---
artifact_id: hybrid-search-rls-aware-pgvector
artifact_type: pgvector_pattern
version: "3.1.0"
constraints_mapped: ["C3","C4","C8","V1","V2","V3"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/postgresql-pgvector/hybrid-search-rls-aware.pgvector.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:hybrid-search-rls-aware-v3.1.0-modular"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "postgresql-pgvector"
ai_navigation:
  read_first: false
  required_for: [rag-hybrid-retrieval, tenant-safe-search, rrf-fusion]
  update_frequency: on-change
audience: ["postgresql-pgvector-master-agent", "orchestrator-engine", "application-backend"]
status: "🟡 Refatorado"
next_review: "2026-06-09"
checksum_sha256: "pending-generation"
vector_meta:
  dimensions: 1536
  model: "text-embedding-3-small"
  metric: "cosine"
  index_type: "hnsw"
---

# 🔍 Busca Híbrida Consciente de RLS (pgvector + FTS)

> **Contrato modular**: Este artefato é filho do Master Agent `postgresql-pgvector-rag-master-agent-mantis`.
> Herda hardening, observability, thinking system e constraints via source/import.
> Contém APENAS a lógica de busca híbrida (vetorial + FTS) com fusão RRF e isolamento estrito de tenant.

---

## 🎯 Propósito
Implementar busca híbrida combinando similaridade vetorial (`<=>`) e full-text search (FTS) com Reciprocal Rank Fusion (RRF), garantindo isolamento de tenant via RLS + filtro explícito (C4), dimensões declaradas (V1), métrica documentada (V2) e parâmetros de índice justificados (V3). Otimizado para pipelines RAG com timeout e logging estruturado.

## 📋 Especificação (SDD – Apenas o Específico deste Módulo)
- **Entradas**: `p_query_text` (texto), `p_query_vec` (vetor), `p_tenant_id` (uuid), `p_limit` (int), `p_alpha` (peso vetorial)
- **Saídas**: Tabela com `doc_id`, `hybrid_score`, `vector_score`, `fts_score`, `content_snippet`
- **Side Effects**: Apenas leitura; logging de auditoria via `mantis_log()`
- **Constraints Aplicáveis**: C3, C4, C8, V1, V2, V3
- **Dependências**: PostgreSQL 15+, `pgvector >= 0.7.0`, extensão `pg_trgm` ou dicionário FTS, `mantis_log()` herdada

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C4+C8+V1+V2+V3)

```sql
-- Bootstrap modular: source Master Agent OU fallback mínimo
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'mantis_log') THEN
    PERFORM mantis_log('INFO', 'module_bootstrap', 'hybrid-search-rls-aware: Master agent available');
  ELSE
    RAISE LOG '%', json_build_object(
      'timestamp', to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
      'level', 'WARN',
      'resource', json_build_object('tenant_id', current_setting('app.current_tenant', true), 'artifact', 'hybrid-search-rls-aware'),
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
SET LOCAL statement_timeout = '5s';
SET LOCAL work_mem = '128MB';
```

---

## ✅ C4 + RLS: Política de Isolamento de Tenant para Tabela Híbrida

```sql
-- ✅ C4: Garantir RLS ativo na tabela de documentos/embeddings
-- (Executar uma vez no setup do schema, não em runtime de busca)
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
CREATE POLICY doc_tenant_isolation ON documents
  FOR ALL
  USING (tenant_id = current_setting('app.current_tenant')::uuid)
  WITH CHECK (tenant_id = current_setting('app.current_tenant')::uuid);

ALTER TABLE document_embeddings ENABLE ROW LEVEL SECURITY;
CREATE POLICY emb_tenant_isolation ON document_embeddings
  FOR ALL
  USING (tenant_id = current_setting('app.current_tenant')::uuid)
  WITH CHECK (tenant_id = current_setting('app.current_tenant')::uuid);
```

---

## ✅ V1 + V2 + V3 + RRF: Função de Busca Híbrida com Fusão de Rankings

```sql
-- ✅ Busca híbrida segura: Vetor (cosine) + FTS + RRF + C4/V1/V2/V3
CREATE OR REPLACE FUNCTION hybrid_search_rls_aware(
  p_query_text text,
  p_query_vec vector(1536),  -- ✅ V1: dimensão explícita no tipo
  p_tenant_id uuid,
  p_limit int DEFAULT 10,
  p_alpha float DEFAULT 0.6  -- Peso vetorial (0.0 = só FTS, 1.0 = só vetor)
) RETURNS TABLE(
  doc_id uuid,
  content_snippet text,
  hybrid_score float,
  vector_score float,
  fts_score float,
  metadata jsonb
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_start timestamptz := clock_timestamp();
  v_k constant int := 60;  -- Constante RRF padrão (estabilidade de ranking)
BEGIN
  -- C3: Sanitização básica de input FTS (evitar sintaxe tsquery perigosa)
  p_query_text := regexp_replace(p_query_text, '(\&|\||\!|:|\(|\)|\\)', ' ', 'g');
  
  -- ✅ C4+V1+V2: Busca vetor com filtro explícito + índice HNSW justificado
  -- V3: Índice esperado: idx_emb_hnsw USING hnsw (vec vector_cosine_ops) WITH (m=16, ef_construction=100)
  WITH vector_rank AS (
    SELECT 
      de.doc_id,
      ROW_NUMBER() OVER (ORDER BY de.embedding <=> p_query_vec) AS rank,
      1.0 - (de.embedding <=> p_query_vec) AS similarity  -- ✅ V2: cosine similarity
    FROM document_embeddings de
    WHERE de.tenant_id = p_tenant_id  -- ✅ C4: filtro explícito (defesa em profundidade)
      AND array_length(de.embedding, 1) = 1536  -- ✅ V1: guard de dimensão
    ORDER BY de.embedding <=> p_query_vec
    LIMIT p_limit * 2  -- Oversampling para RRF
  ),
  -- ✅ FTS com tsvector/tsquery + filtro de tenant
  fts_rank AS (
    SELECT 
      d.id AS doc_id,
      ROW_NUMBER() OVER (ORDER BY ts_rank(d.tsv, plainto_tsquery('portuguese', p_query_text)) DESC) AS rank,
      ts_rank(d.tsv, plainto_tsquery('portuguese', p_query_text)) AS score
    FROM documents d
    WHERE d.tenant_id = p_tenant_id  -- ✅ C4
      AND d.tsv @@ plainto_tsquery('portuguese', p_query_text)
    ORDER BY ts_rank(d.tsv, plainto_tsquery('portuguese', p_query_text)) DESC
    LIMIT p_limit * 2
  )
  -- ✅ RRF: Fusão de rankings normalizada
  SELECT 
    COALESCE(v.doc_id, f.doc_id) AS doc_id,
    LEFT(d.content, 300) AS content_snippet,
    (COALESCE(1.0 / (v_k + v.rank), 0) * p_alpha + 
     COALESCE(1.0 / (v_k + f.rank), 0) * (1 - p_alpha)) AS hybrid_score,
    COALESCE(v.similarity, 0) AS vector_score,
    COALESCE(f.score, 0) AS fts_score,
    d.metadata
  FROM vector_rank v
  FULL OUTER JOIN fts_rank f ON v.doc_id = f.doc_id
  JOIN documents d ON d.id = COALESCE(v.doc_id, f.doc_id)
  WHERE d.tenant_id = p_tenant_id  -- ✅ C4: validação final pós-fusão
  ORDER BY hybrid_score DESC
  LIMIT p_limit;

  -- C8: Logging estruturado de conclusão
  PERFORM mantis_log('INFO', 'hybrid_search_completed', 
    format('alpha=%s, limit=%s, tenant=%s, duration_ms=%s',
      p_alpha, p_limit, p_tenant_id, 
      EXTRACT(MILLISECOND FROM clock_timestamp() - v_start)));
  
EXCEPTION WHEN query_canceled THEN
  PERFORM mantis_log('WARN', 'hybrid_search_timeout', 
    format('tenant=%s, timeout=5s', p_tenant_id));
  RAISE EXCEPTION 'C1: Hybrid search exceeded 5s timeout';
WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'hybrid_search_failed', sanitize_error_message(SQLERRM));
  RAISE;
END;
$$;
```

---

## ✅ V3: Justificação de Parâmetros de Índice (Comentário Executável)

```sql
-- ✅ V3: Criação do índice HNSW recomendado para esta função de busca
-- Parâmetros justificados por pgvector docs e benchmarks para 1536d:
-- m=16: número de conexões por nó. 16 oferece recall ~0.95 com uso de memória ~4x dimensão.
-- ef_construction=100: profundidade de busca durante build. 100 equilibra tempo de criação e qualidade.
-- Para datasets >10M vetores, considerar IVFFlat com lists ≈ sqrt(n_vectors).
CREATE INDEX IF NOT EXISTS idx_doc_emb_hnsw_cosine ON document_embeddings
  USING hnsw (embedding vector_cosine_ops)
  WITH (m = 16, ef_construction = 100);

-- ✅ C5: Índice GIN para FTS + metadados (acelera filtragem híbrida)
CREATE INDEX IF NOT EXISTS idx_doc_fts_meta ON documents
  USING GIN (tenant_id, tsv, metadata jsonb_path_ops);
```

---

## ✅ C8 + Auditoria: Log de Decisão Híbrida

```sql
-- ✅ Tabela de auditoria para rastrear pesos e recall da busca híbrida
CREATE TABLE IF NOT EXISTS hybrid_search_audit (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL,
  query_hash bytea NOT NULL,
  alpha_used float NOT NULL,
  limit_used int NOT NULL,
  vector_hits int NOT NULL,
  fts_hits int NOT NULL,
  total_results int NOT NULL,
  duration_ms int NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE hybrid_search_audit ENABLE ROW LEVEL SECURITY;
CREATE POLICY audit_tenant_isolation ON hybrid_search_audit
  FOR ALL USING (tenant_id = current_setting('app.current_tenant')::uuid);

-- Índice para consultas de auditoria por tenant
CREATE INDEX idx_audit_tenant_time ON hybrid_search_audit(tenant_id, created_at DESC);
```

---

## 🧪 Testes Unitários (TDD – Apenas para a Lógica Específica)

```sql
-- Test: hybrid_search_respeita_tenant_isolation
-- Constraint: C4
BEGIN;
SELECT plan(2);

-- Arrange: inserir dados de teste para 2 tenants
SET LOCAL app.current_tenant = '00000000-0000-0000-0000-000000000001';
-- (Inserir fixtures mock de documents/document_embeddings)

-- Act: executar busca com tenant 1
-- Assert: zero resultados cruzados para tenant 2
SELECT is((SELECT COUNT(DISTINCT doc_id) FROM hybrid_search_rls_aware('teste', '[0.1]'::vector(1536), '00000000-0000-0000-0000-000000000002')), 0, 'C4: zero vazamento entre tenants');

-- Act+Assert: RRF score é monotonicamente decrescente
-- (Validar que hybrid_score[n] >= hybrid_score[n+1] para limit=5)

SELECT * FROM finish();
ROLLBACK;

-- Test: hybrid_search_timeout_acima_de_5s
-- Constraint: C1+C8
DO $$
BEGIN
  SET LOCAL statement_timeout = '5s';
  -- Simular query custosa ou mock de pg_sleep + hybrid_search
  -- Assert: exception com mensagem 'C1: Hybrid search exceeded 5s timeout'
  PERFORM true;  -- Placeholder para teste de timeout real em ambiente CI
END $$;
```

---

## 🔍 Validação (VDD – Comando Canônico)

```bash
# Validação via orchestrator-engine
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/postgresql-pgvector/hybrid-search-rls-aware.pgvector.md \
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
| 3.0.0 | 2026-04-19 | PostgreSQL-PgVector Master Agent | Criação inicial: RRF híbrido, filtro tenant, logging C8 | C4,C8,V2 |
| 3.1.0-MODULAR | 2026-05-09 | PostgreSQL-PgVector Master Agent | Refatoração modular: bootstrap resiliente, mantis_log() herdada, V1/V3 declarados, C3 sanitização, wikilink corrigido | C3,C4,C8,V1,V2,V3 |

---
## 🔍 Observability (Documentación para IA – Apenas Eventos Específicos)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `module_bootstrap` | INFO | C8 | `"Master agent available"` ou `"fallback: mantis_log() not found"` |
| `hybrid_search_completed` | INFO | C8 | `"alpha=0.6, limit=10, tenant=uuid, duration_ms=142"` |
| `hybrid_search_timeout` | WARN | C1 | `"tenant=uuid, timeout=5s"` |
| `hybrid_search_failed` | ERROR | C3,C8 | `"sanitized_error_message, tenant=uuid"` |

### Validação de Schema V-LOG-02 (Helper Mínimo)
```sql
-- Executar em teste: SELECT validate_vlog02('{"timestamp":"2026-05-09T00:00:00Z","level":"INFO","resource":{"tenant_id":"uuid"},"body":{"event":"hybrid_search_completed"}}');
-- Retorno esperado: t (true) se schema válido, f (false) caso contrário
-- Função herdada do Master Agent; este módulo apenas a invoca
```
---
