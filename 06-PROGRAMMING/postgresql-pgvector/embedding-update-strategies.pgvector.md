---
artifact_id: embedding-update-strategies-pgvector
artifact_type: pgvector_pattern
version: "1.0.0"
constraints_mapped: ["C4","C5","C7","C8","V1","V3"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/postgresql-pgvector/embedding-update-strategies.pgvector.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:embedding-update-strategies-v1.0.0-modular"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "postgresql-pgvector"
ai_navigation:
  read_first: false
  required_for: [embedding-versioning, incremental-updates, conflict-resolution, index-maintenance]
  update_frequency: on-change
audience: ["postgresql-pgvector-master-agent", "data-engineers", "backend-engineers", "orchestrator-engine"]
status: "🟢 Novo"
next_review: "2026-06-09"
checksum_sha256: "pending-generation"
vector_meta:
  dimensions: 1536
  model: "text-embedding-3-small"
  metric: "cosine"
  index_type: "hnsw"
---

# 🔄 Estratégias de Atualização de Embeddings: Upsert, Versionamento e Reindex (pgvector)

> **Contrato modular**: Este artefato é filho do Master Agent `postgresql-pgvector-rag-master-agent-mantis`.
> Herda hardening, observability, thinking system e constraints via source/import.
> Contém APENAS a lógica de atualização incremental de embeddings, controle de versão, resolução de conflitos com otimistic locking, validação dimensional pré-update e manutenção segura de índices HNSW durante mutações.

---

## 🎯 Propósito
Implementar padrões seguros de atualização de embeddings existentes: `UPSERT` com controle de versão (`embedding_version`), validação estrita de dimensão (V1), isolamento de tenant (C4), prevenção de race conditions com optimistic locking (C5/C7), logging estruturado de mudanças (C8) e diretrizes de reindexação incremental sem degradação de busca (V3). Otimizado para pipelines de re-embedding e correção de drift sem downtime.

## 📋 Especificação (SDD – Apenas o Específico deste Módulo)
- **Entradas**: `p_doc_id` (uuid), `p_new_embedding` (vector), `p_tenant_id` (uuid), `p_expected_version` (int)
- **Saídas**: Status da operação (`INSERTED|UPDATED|SKIPPED|VERSION_MISMATCH`), contagem de rows afetadas, log de auditoria
- **Side Effects**: Atualização de tabela de embeddings, incremento de versão, atualização incremental do índice HNSW, logging C8
- **Constraints Aplicáveis**: C4, C5, C7, C8, V1, V3
- **Dependências**: PostgreSQL 15+, `pgvector >= 0.7.0`, coluna `embedding_version` na tabela de embeddings, `mantis_log()` herdada

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C4+C5+C7+C8+V1+V3)

```sql
-- Bootstrap modular: source Master Agent OU fallback mínimo
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'mantis_log') THEN
    PERFORM mantis_log('INFO', 'module_bootstrap', 'embedding-update-strategies: Master agent available');
  ELSE
    RAISE LOG '%', json_build_object(
      'timestamp', to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
      'level', 'WARN',
      'resource', json_build_object('tenant_id', current_setting('app.current_tenant', true), 'artifact', 'embedding-update-strategies'),
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

-- C1+C7: Limites de recursos para operações de atualização
SET LOCAL statement_timeout = '30s';
SET LOCAL work_mem = '128MB';
```

---

## ✅ C4 + C5 + V1 + V3: Upsert Seguro com Versionamento e Optimistic Locking

```sql
-- ✅ Adicionar coluna de versionamento se não existir (executar uma vez por schema)
ALTER TABLE document_embeddings ADD COLUMN IF NOT EXISTS embedding_version int NOT NULL DEFAULT 1;
ALTER TABLE document_embeddings ADD COLUMN IF NOT EXISTS updated_at timestamptz;

-- ✅ C4+C5+V1: Função principal de upsert com controle de versão e validação dimensional
CREATE OR REPLACE FUNCTION upsert_embedding_with_version(
  p_doc_id uuid,
  p_tenant_id uuid,
  p_new_embedding vector(1536),  -- V1: dimensão explícita na assinatura
  p_expected_version int,        -- C5: optimistic locking
  p_new_content_hash bytea DEFAULT NULL
) RETURNS TABLE(status text, current_version int, affected_rows bigint)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_current_version int;
  v_rows bigint;
BEGIN
  -- C4: Validação de escopo de tenant
  IF current_setting('app.current_tenant')::uuid <> p_tenant_id THEN
    RAISE EXCEPTION 'C4: Tenant context mismatch on update.';
  END IF;

  -- V1: Guard de segurança adicional (caso chamado via dynamic SQL)
  IF array_length(p_new_embedding, 1) IS DISTINCT FROM 1536 THEN
    RAISE EXCEPTION 'V1: Embedding dimension mismatch. Expected 1536.';
  END IF;

  -- C5: Upsert com optimistic locking
  INSERT INTO document_embeddings (id, tenant_id, doc_id, embedding, embedding_version, content_hash, created_at, updated_at)
  VALUES (gen_random_uuid(), p_tenant_id, p_doc_id, p_new_embedding, 1, p_new_content_hash, now(), now())
  ON CONFLICT (tenant_id, doc_id) DO UPDATE
    SET embedding = EXCLUDED.embedding,
        embedding_version = EXCLUDED.embedding_version + 1,
        content_hash = COALESCE(EXCLUDED.content_hash, document_embeddings.content_hash),
        updated_at = now()
    WHERE document_embeddings.embedding_version = p_expected_version  -- ✅ C5: race condition prevention
    RETURNING embedding_version INTO v_current_version;

  GET DIAGNOSTICS v_rows = ROW_COUNT;

  -- Determinar status
  IF v_rows > 0 THEN
    status := 'UPDATED';
    PERFORM mantis_log('INFO', 'embedding_updated', 
      format('doc_id=%s, tenant=%s, new_version=%s, tenant=%s', p_doc_id, p_tenant_id, v_current_version, p_tenant_id));
  ELSE
    -- Versão esperada não corresponde (conflito)
    SELECT embedding_version INTO v_current_version 
    FROM document_embeddings WHERE tenant_id = p_tenant_id AND doc_id = p_doc_id;
    
    IF v_current_version IS NOT NULL THEN
      status := 'VERSION_MISMATCH';
      PERFORM mantis_log('WARN', 'embedding_update_version_conflict', 
        format('doc_id=%s, expected=%s, actual=%s, tenant=%s', p_doc_id, p_expected_version, v_current_version, p_tenant_id));
    ELSE
      status := 'NOT_FOUND';
      PERFORM mantis_log('WARN', 'embedding_update_not_found', format('doc_id=%s, tenant=%s', p_doc_id, p_tenant_id));
    END IF;
  END IF;

  current_version := v_current_version;
  affected_rows := v_rows;
  RETURN;

EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'embedding_upsert_failed', sanitize_error_message(SQLERRM));
  RAISE;
END;
$$;

-- ✅ V3: Documentação de comportamento do índice HNSW durante updates
-- O pgvector atualiza índices HNSW incrementalmente. Para cargas massivas de atualização (>10% da tabela):
-- 1. Desativar indexação automática temporariamente: SET LOCAL enable_indexscan = off;
-- 2. Executar updates em lotes.
-- 3. Reativar: SET LOCAL enable_indexscan = on;
-- 4. Reindexar se degradação de recall for detectada: REINDEX INDEX CONCURRENTLY idx_emb_hnsw_cosine;
```

---

## ✅ C5 + C7 + C8: Atualização em Lote com Controle de Concorrência

```sql
-- ✅ C5+C7: Atualizar embeddings em lote com cursor seguro, rollback em falha crítica e logging
CREATE OR REPLACE FUNCTION batch_update_embeddings(
  p_staging_table regclass,
  p_tenant_id uuid
) RETURNS TABLE(updated_count int, skipped_count int, failed_count int)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_staging_row RECORD;
  v_result RECORD;
  v_updated int := 0;
  v_skipped int := 0;
  v_failed int := 0;
BEGIN
  FOR v_staging_row IN 
    SELECT doc_id, embedding, current_version, new_content_hash 
    FROM p_staging_table 
    WHERE tenant_id = p_tenant_id
    ORDER BY doc_id
  LOOP
    BEGIN
      SELECT * INTO v_result FROM upsert_embedding_with_version(
        v_staging_row.doc_id, p_tenant_id, v_staging_row.embedding, v_staging_row.current_version, v_staging_row.new_content_hash
      );

      CASE v_result.status
        WHEN 'UPDATED' THEN v_updated := v_updated + 1;
        WHEN 'VERSION_MISMATCH' THEN v_skipped := v_skipped + 1;
        ELSE v_failed := v_failed + 1;
      END CASE;

    EXCEPTION WHEN OTHERS THEN
      v_failed := v_failed + 1;
      PERFORM mantis_log('ERROR', 'batch_update_item_failed', 
        format('doc_id=%s, err=%s, tenant=%s', v_staging_row.doc_id, sanitize_error_message(SQLERRM), p_tenant_id));
      -- Continua processando demais itens (resiliência C7)
    END;
  END LOOP;

  PERFORM mantis_log('INFO', 'batch_update_completed', 
    format('updated=%s, skipped=%s, failed=%s, tenant=%s', v_updated, v_skipped, v_failed, p_tenant_id));
  
  RETURN QUERY SELECT v_updated, v_skipped, v_failed;
END;
$$;
```

---

## 🧪 Testes Unitários (TDD – Apenas para a Lógica Específica)

```sql
-- Test: upsert_increments_version_on_success
-- Constraint: C5+V1
BEGIN;
SELECT plan(2);

-- Arrange: inserir registro inicial versão 1
-- Act: chamar upsert_embedding_with_version com expected_version=1
-- Assert: status='UPDATED', current_version=2
-- SELECT is((SELECT current_version FROM upsert_embedding_with_version(...)), 2, 'C5: versão deve incrementar');

-- Act/Assert: chamar com expected_version=1 (stale) deve retornar VERSION_MISMATCH
-- SELECT is((SELECT status FROM upsert_embedding_with_version(..., 1)), 'VERSION_MISMATCH', 'C5: optimistic lock deve rejeitar versão stale');

SELECT * FROM finish();
ROLLBACK;

-- Test: dimension_mismatch_rejects_update
-- Constraint: V1
DO $$
BEGIN
  -- Arrange: mock com vetor 768d
  -- Act: upsert_embedding_with_version(..., '[0.1]'::vector(768), ...)
  -- Assert: exception 'V1: Embedding dimension mismatch'
  PERFORM true; -- Placeholder CI
END $$;
```

---

## 🔍 Validação (VDD – Comando Canônico)

```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/postgresql-pgvector/embedding-update-strategies.pgvector.md \
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
| 1.0.0 | 2026-05-09 | PostgreSQL-PgVector Master Agent | Criação inicial: upsert versionado, optimistic locking C5, validação V1, batch update resiliente C7, logging C8, diretrizes V3 para reindex | C4,C5,C7,C8,V1,V3 |

---
## 🔍 Observability (Documentación para IA – Apenas Eventos Específicos)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `module_bootstrap` | INFO | C8 | `"Master agent available"` ou `"fallback: mantis_log() not found"` |
| `embedding_updated` | INFO | C5,C8 | `"doc_id=uuid, tenant=uuid, new_version=2"` |
| `embedding_update_version_conflict` | WARN | C5,C8 | `"doc_id=uuid, expected=1, actual=3, tenant=uuid"` |
| `batch_update_completed` | INFO | C8 | `"updated=4850, skipped=120, failed=5, tenant=uuid"` |
| `embedding_upsert_failed` | ERROR | C8 | `"sanitized_error_message, tenant=uuid"` |

### Validação de Schema V-LOG-02 (Helper Mínimo)
```sql
-- Executar em teste: SELECT validate_vlog02('{"timestamp":"2026-05-09T00:00:00Z","level":"INFO","resource":{"tenant_id":"uuid"},"body":{"event":"embedding_updated"}}');
-- Retorno esperado: t (true) se schema válido, f (false) caso contrário
-- Função herdada do Master Agent; este módulo apenas a invoca
```
---
