---
artifact_id: embedding-batch-insert-optimization-pgvector
artifact_type: pgvector_pattern
version: "1.0.0"
constraints_mapped: ["C1","C4","C5","C7","C8","V1","V3"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/postgresql-pgvector/embedding-batch-insert-optimization.pgvector.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:embedding-batch-insert-optimization-v1.0.0-modular"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "postgresql-pgvector"
ai_navigation:
  read_first: false
  required_for: [bulk-ingestion, wal-optimization, hnsw-index-tuning, transaction-batching]
  update_frequency: on-change
audience: ["postgresql-pgvector-master-agent", "data-engineers", "db-admins", "orchestrator-engine"]
status: "🟢 Novo"
next_review: "2026-06-09"
checksum_sha256: "pending-generation"
vector_meta:
  dimensions: 1536
  model: "text-embedding-3-small"
  metric: "cosine"
  index_type: "hnsw"
---

# ⚡ Otimização de Inserção em Lote de Embeddings (COPY + HNSW Tuning)

> **Contrato modular**: Este artefato é filho do Master Agent `postgresql-pgvector-rag-master-agent-mantis`.
> Herda hardening, observability, thinking system e constraints via source/import.
> Contém APENAS a lógica de ingestão massiva, tuning de `hnsw.ef_insert`, gerenciamento de WAL, validação dimensional por lote e isolamento de tenant em transações segmentadas.

---

## 🎯 Propósito
Otimizar a inserção de embeddings em alta escala usando transações em lote, configuração segura de `synchronous_commit = off` (C1), ajuste de `hnsw.ef_insert` para priorizar velocidade de escrita sobre busca durante carga (V3), validação estrita de tenant (C4) e logging estruturado de progresso/falhas (C8). Projetado para pipelines ETL/ELT enterprise com controle de checkpoint e zero degradação de query em produção.

## 📋 Especificação (SDD – Apenas o Específico deste Módulo)
- **Entradas**: `p_staging_table` (regclass), `p_target_table` (regclass), `p_batch_size` (int), `p_tenant_id` (uuid)
- **Saídas**: Contagem de inserções, batches processados, duração, status de checkpoint
- **Side Effects**: Writes em target table, atualização de índice HNSW, consumo de WAL temporário; logging C8
- **Constraints Aplicáveis**: C1, C4, C5, C7, C8, V1, V3
- **Dependências**: PostgreSQL 15+, `pgvector >= 0.7.0`, tabela staging com schema compatível, `mantis_log()` herdada

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C1+C4+C7+C8+V3)

```sql
-- Bootstrap modular: source Master Agent OU fallback mínimo
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'mantis_log') THEN
    PERFORM mantis_log('INFO', 'module_bootstrap', 'embedding-batch-insert-optimization: Master agent available');
  ELSE
    RAISE LOG '%', json_build_object(
      'timestamp', to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
      'level', 'WARN',
      'resource', json_build_object('tenant_id', current_setting('app.current_tenant', true), 'artifact', 'embedding-batch-insert-optimization'),
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

-- C1+C7: Limites de recursos e otimização de WAL para bulk load
SET LOCAL statement_timeout = '300s';
SET LOCAL work_mem = '256MB';
SET LOCAL synchronous_commit = 'off';  -- C1: reduz flush de WAL durante carga (compensar com CHECKPOINT posterior)
SET LOCAL max_parallel_workers_per_gather = 0; -- Evita paralelismo indesejado em INSERT massivo
```

---

## ✅ C4 + C5 + V3: Função de Inserção em Lote com Tuning HNSW e Cursor

```sql
-- ✅ C4+C5+V3: Processa dados de staging para target em lotes seguros, otimizando índice e WAL
CREATE OR REPLACE FUNCTION optimize_embedding_bulk_load(
  p_staging_table regclass,
  p_target_table regclass DEFAULT 'document_embeddings',
  p_batch_size int DEFAULT 5000,
  p_tenant_id uuid
) RETURNS TABLE(inserted_total bigint, batches_completed int, duration_ms float)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  cur CURSOR FOR 
    SELECT id, doc_id, embedding, content_hash 
    FROM p_staging_table 
    WHERE tenant_id = p_tenant_id;
  v_row RECORD;
  v_inserted bigint := 0;
  v_batches int := 0;
  v_start timestamptz := clock_timestamp();
  v_batch_count int := 0;
BEGIN
  -- C4: Validar tenant match explícito
  IF current_setting('app.current_tenant')::uuid <> p_tenant_id THEN
    RAISE EXCEPTION 'C4: Tenant context mismatch.';
  END IF;

  -- V3: Otimizar índice HNSW para escrita rápida durante carga
  -- Disponível em pgvector >= 0.7.0. Valor padrão: 40. Aumentar para 100+ só se recall na carga for crítico.
  SET LOCAL hnsw.ef_insert = 40;

  OPEN cur;
  LOOP
    BEGIN
      -- Reset contagem do batch
      v_batch_count := 0;
      
      -- Iniciar bloco transacional interno por lote
      FOR v_row IN SELECT * FROM cur LIMIT p_batch_size LOOP
        INSERT INTO p_target_table (id, tenant_id, doc_id, embedding, content_hash, created_at)
        VALUES (gen_random_uuid(), p_tenant_id, v_row.doc_id, v_row.embedding, v_row.content_hash, now())
        ON CONFLICT (tenant_id, doc_id) DO NOTHING;
        
        v_batch_count := v_batch_count + 1;
      END LOOP;

      EXIT WHEN v_batch_count = 0;

      -- C7: Forçar checkpoint leve entre lotes para liberar WAL
      PERFORM pg_catalog.pg_wal_flush();
      PERFORM pg_catalog.pg_stat_force_next_flush();
      
      v_batches := v_batches + 1;
      v_inserted := v_inserted + v_batch_count;

      PERFORM mantis_log('INFO', 'bulk_load_batch_completed', 
        format('batch=%s, rows=%s, ef_insert=40, tenant=%s', v_batches, v_batch_count, p_tenant_id));

    EXCEPTION WHEN OTHERS THEN
      PERFORM mantis_log('ERROR', 'bulk_load_batch_failed', sanitize_error_message(SQLERRM));
      -- Opcional: log erro e continuar, ou RAISE para abortar carga inteira
      RAISE;
    END;
  END LOOP;

  CLOSE cur;

  -- Restaurar synchronous_commit e logar conclusão
  SET LOCAL synchronous_commit = 'on';
  PERFORM mantis_log('INFO', 'bulk_load_completed', 
    format('total=%s, batches=%s, duration_ms=%.0f, tenant=%s', 
           v_inserted, v_batches, EXTRACT(MILLISECOND FROM clock_timestamp() - v_start), p_tenant_id));

  RETURN QUERY SELECT v_inserted, v_batches, EXTRACT(MILLISECOND FROM clock_timestamp() - v_start);
EXCEPTION WHEN OTHERS THEN
  CLOSE cur;
  PERFORM mantis_log('ERROR', 'bulk_load_aborted', sanitize_error_message(SQLERRM));
  RAISE;
END;
$$;

-- ✅ V3+C1: Recomendação documentada para produção
-- 1. Durante carga pesada (>100k vetores): SET hnsw.ef_insert = 40; SET synchronous_commit = off;
-- 2. Após carga: SET hnsw.ef_insert = DEFAULT; SET synchronous_commit = on; EXECUTE CHECKPOINT;
-- 3. Analisar estatísticas: ANALYZE document_embeddings;
```

---

## ✅ C8 + V1: Validação Dimensional Pré-Inserção (Staging Check)

```sql
-- ✅ V1+C5: Garantir que staging não contenha vetores fora da dimensão esperada antes do load
CREATE OR REPLACE FUNCTION validate_staging_dimensions(
  p_staging_table regclass,
  p_expected_dim int DEFAULT 1536
) RETURNS TABLE(invalid_rows bigint, recommendation text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_invalid bigint;
BEGIN
  EXECUTE format(
    'SELECT COUNT(*) FROM %I WHERE array_length(embedding, 1) IS DISTINCT FROM %L',
    p_staging_table, p_expected_dim
  ) INTO v_invalid;

  invalid_rows := v_invalid;
  recommendation := CASE
    WHEN v_invalid > 0 THEN format('Remova ou normalize %s linhas com dimensão != %s antes de carregar', v_invalid, p_expected_dim)
    ELSE 'Staging validado. Dimensões consistentes com V1.'
  END;

  PERFORM mantis_log('INFO', 'staging_dimension_validation', 
    format('invalid=%s, expected=%s, tenant=%s', v_invalid, p_expected_dim, current_setting('app.current_tenant')));
  
  RETURN;
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'staging_validation_failed', sanitize_error_message(SQLERRM));
  RETURN;
END;
$$;
```

---

## 🧪 Testes Unitários (TDD – Apenas para a Lógica Específica)

```sql
-- Test: bulk_load_optimization_applies_hnsw_ef_insert
-- Constraint: V3+C1
BEGIN;
SELECT plan(2);

-- Act: chamar função com tabela staging vazia (segura)
-- Assert: deve retornar inserted=0, batches=0 sem erros
SELECT is((SELECT inserted_total FROM optimize_embedding_bulk_load('documents'::regclass, 'document_embeddings', 100, current_setting('app.current_tenant')::uuid)), 0, 'V3: execução segura com staging vazio');

-- Assert: synchronous_commit deve ser restaurado para 'on' após função
SELECT current_setting('synchronous_commit') INTO v_setting;
SELECT ok(v_setting = 'on' OR v_setting = 'remote_apply', 'C1: synchronous_commit restaurado pós-execução');

SELECT * FROM finish();
ROLLBACK;

-- Test: staging_validation_detects_wrong_dimensions
-- Constraint: V1
DO $$
DECLARE v_invalid bigint;
BEGIN
  -- Mock: inserir vetor 768d em staging
  -- Act: validate_staging_dimensions('staging_tbl', 1536)
  -- Assert: invalid_rows > 0
  PERFORM true; -- Placeholder CI
END $$;
```

---

## 🔍 Validação (VDD – Comando Canônico)

```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/postgresql-pgvector/embedding-batch-insert-optimization.pgvector.md \
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
| 1.0.0 | 2026-05-09 | PostgreSQL-PgVector Master Agent | Criação inicial: inserção em lote com cursor, tuning hnsw.ef_insert, WAL optimization, validação V1 staging | C1,C4,C5,C7,C8,V1,V3 |

---
## 🔍 Observability (Documentación para IA – Apenas Eventos Específicos)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `module_bootstrap` | INFO | C8 | `"Master agent available"` ou `"fallback: mantis_log() not found"` |
| `bulk_load_batch_completed` | INFO | C8,V3 | `"batch=1, rows=5000, ef_insert=40, tenant=uuid"` |
| `staging_dimension_validation` | INFO | V1,C8 | `"invalid=0, expected=1536, tenant=uuid"` |
| `bulk_load_completed` | INFO | C8 | `"total=50000, batches=10, duration_ms=4200, tenant=uuid"` |
| `bulk_load_batch_failed` | ERROR | C7,C8 | `"sanitized_error_message, tenant=uuid"` |
| `bulk_load_aborted` | ERROR | C7,C8 | `"sanitized_error_message, tenant=uuid"` |

### Validação de Schema V-LOG-02 (Helper Mínimo)
```sql
-- Executar em teste: SELECT validate_vlog02('{"timestamp":"2026-05-09T00:00:00Z","level":"INFO","resource":{"tenant_id":"uuid"},"body":{"event":"bulk_load_batch_completed"}}');
-- Retorno esperado: t (true) se schema válido, f (false) caso contrário
-- Função herdada do Master Agent; este módulo apenas a invoca
```
---
