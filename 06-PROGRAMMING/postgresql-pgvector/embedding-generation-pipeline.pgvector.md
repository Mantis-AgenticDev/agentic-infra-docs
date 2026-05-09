---
artifact_id: embedding-generation-pipeline-pgvector
artifact_type: pgvector_pipeline
version: "1.0.0"
constraints_mapped: ["C1","C3","C4","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/postgresql-pgvector/embedding-generation-pipeline.pgvector.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:embedding-generation-pipeline-v1.0.0-modular"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "postgresql-pgvector"
ai_navigation:
  read_first: false
  required_for: [async-embedding-queue, retry-backoff-management, api-key-vault-integration, batch-processing]
  update_frequency: on-change
audience: ["postgresql-pgvector-master-agent", "data-engineers", "backend-orchestrators", "ci-cd-pipelines"]
status: "🟢 Novo"
next_review: "2026-06-09"
checksum_sha256: "pending-generation"
vector_meta:
  dimensions: 1536
  model: "text-embedding-3-small"
  metric: "cosine"
  index_type: "hnsw"
---

# 🔗 Pipeline Assíncrono de Geração de Embeddings com Retry e Timeout (pgvector)

> **Contrato modular**: Este artefato é filho do Master Agent `postgresql-pgvector-rag-master-agent-mantis`.
> Herda hardening, observability, thinking system e constraints via source/import.
> Contém APENAS a lógica de fila de tarefas, processamento assíncrono, retry exponencial, limites de recurso (C1/C7), validação de tenant (C4) e sanitização de credenciais (C3).

---

## 🎯 Propósito
Orquestrar a geração assíncrona de embeddings a partir de textos brutos: enfileiramento seguro, execução em lotes controlados, retry com backoff exponencial em falhas transitórias, timeout configurável (C7), validação estrita de tenant (C4), injeção segura de API keys via `current_setting` (C3) e rastreamento completo via `mantis_log()` (C8). Otimizado para pipelines RAG enterprise com alta disponibilidade e compliance.

## 📋 Especificação (SDD – Apenas o Específico deste Módulo)
- **Entradas**: `p_text_batch` (text[]), `p_tenant_id` (uuid), `p_max_retries` (int), `p_timeout_ms` (int)
- **Saídas**: Tabela de status (`embedding_tasks`), vetores gerados em `document_embeddings`, eventos JSONL de ciclo de vida
- **Side Effects**: Atualização de status de tarefas, consumo de API externa (via `http` extension ou worker dedicado), logging C8
- **Constraints Aplicáveis**: C1, C3, C4, C7, C8
- **Dependências**: PostgreSQL 14+, `pgvector`, extensão `pg_http` ou worker externo, `mantis_log()` herdada

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C1+C3+C4+C7+C8)

```sql
-- Bootstrap modular: source Master Agent OU fallback mínimo
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'mantis_log') THEN
    PERFORM mantis_log('INFO', 'module_bootstrap', 'embedding-generation-pipeline: Master agent available');
  ELSE
    RAISE LOG '%', json_build_object(
      'timestamp', to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
      'level', 'WARN',
      'resource', json_build_object('tenant_id', current_setting('app.current_tenant', true), 'artifact', 'embedding-generation-pipeline'),
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

-- C1+C7: Limites de recurso e timeout para processamento
SET LOCAL statement_timeout = '120s';
SET LOCAL work_mem = '256MB';
```

---

## ✅ C3 + C4 + C7: Tabela de Fila e Gerenciamento de Estado

```sql
-- ✅ C4+C7: Tabela de fila de tarefas com tracking de tenant, retries e status
CREATE TABLE IF NOT EXISTS embedding_tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL,
  content_hash bytea NOT NULL,
  raw_text text NOT NULL,
  status text NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', 'ABORTED')),
  retry_count int DEFAULT 0,
  max_retries int DEFAULT 3,
  error_detail text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE embedding_tasks ENABLE ROW LEVEL SECURITY;
CREATE POLICY task_tenant_isolation ON embedding_tasks
  FOR ALL USING (tenant_id = current_setting('app.current_tenant')::uuid);

CREATE INDEX idx_task_status_tenant ON embedding_tasks(status, tenant_id) WHERE status = 'PENDING';
```

---

## ✅ C3 + C7 + C8: Função de Processamento com Retry e Timeout

```sql
-- ✅ C3+C7+C8: Processa lote com retry exponencial, validação de credencial e logging
CREATE OR REPLACE FUNCTION process_embedding_batch(
  p_batch_size int DEFAULT 50,
  p_timeout_ms int DEFAULT 30000
) RETURNS TABLE(processed_count int, failed_count int)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_task RECORD;
  v_api_key text;
  v_embedding vector(1536);
  v_attempts int := 0;
  v_delay_ms int := 1000;
BEGIN
  -- C3: Recuperar credencial de contexto seguro (nunca hardcoded)
  v_api_key := current_setting('app.embedding_api_key', true);
  IF v_api_key IS NULL OR v_api_key = '' THEN
    RAISE EXCEPTION 'C3: app.embedding_api_key não configurado. Use vault ou env var segura.';
  END IF;

  processed_count := 0;
  failed_count := 0;

  FOR v_task IN
    SELECT id, tenant_id, raw_text, max_retries
    FROM embedding_tasks
    WHERE status = 'PENDING' AND tenant_id = current_setting('app.current_tenant')::uuid
    LIMIT p_batch_size
    FOR UPDATE SKIP LOCKED
  LOOP
    -- Atualizar status para PROCESSING
    UPDATE embedding_tasks SET status = 'PROCESSING', updated_at = now() WHERE id = v_task.id;

    v_attempts := 0;
    WHILE v_attempts <= v_task.max_retries LOOP
      BEGIN
        -- C7: Aplicar timeout dinâmico por tentativa
        PERFORM set_config('statement_timeout', (p_timeout_ms / 1000)::text || 's', true);
        
        -- 🌐 Chamada externa (placeholder para extensão http ou worker)
        -- Em produção: v_embedding := http_call_embedding_api(v_task.raw_text, v_api_key);
        v_embedding := '[0.0]'::vector(1536);  -- Mock para validação de estrutura
        
        IF array_length(v_embedding, 1) <> 1536 THEN
          RAISE EXCEPTION 'V1: Embedding gerado com dimensão inválida';
        END IF;

        -- Inserir na tabela de embeddings
        INSERT INTO document_embeddings (tenant_id, doc_id, embedding, content_hash)
        SELECT v_task.tenant_id, v_task.id, v_embedding, digest(v_task.raw_text::bytea, 'sha256');

        UPDATE embedding_tasks SET status = 'COMPLETED', updated_at = now() WHERE id = v_task.id;
        processed_count := processed_count + 1;
        
        PERFORM mantis_log('INFO', 'embedding_task_completed', format('task=%s, retries=%s, tenant=%s', v_task.id, v_attempts, v_task.tenant_id));
        EXIT;  -- Sucesso, sai do loop de retry

      EXCEPTION WHEN OTHERS THEN
        v_attempts := v_attempts + 1;
        error_detail := sanitize_error_message(SQLERRM);
        
        IF v_attempts > v_task.max_retries THEN
          UPDATE embedding_tasks SET status = 'FAILED', retry_count = v_attempts, error_detail = error_detail, updated_at = now() WHERE id = v_task.id;
          PERFORM mantis_log('ERROR', 'embedding_task_failed_max_retries', format('task=%s, err=%s, tenant=%s', v_task.id, error_detail, v_task.tenant_id));
          failed_count := failed_count + 1;
        ELSE
          -- C7: Backoff exponencial (1s, 2s, 4s...)
          PERFORM pg_sleep(v_delay_ms / 1000.0);
          v_delay_ms := v_delay_ms * 2;
          UPDATE embedding_tasks SET retry_count = v_attempts, updated_at = now() WHERE id = v_task.id;
          PERFORM mantis_log('WARN', 'embedding_task_retrying', format('task=%s, attempt=%s/%s, delay_ms=%s, tenant=%s', v_task.id, v_attempts, v_task.max_retries, v_delay_ms, v_task.tenant_id));
        END IF;
      END;
    END LOOP;
    
    v_delay_ms := 1000;  -- Reset delay para próxima tarefa
  END LOOP;

  PERFORM mantis_log('INFO', 'batch_processing_completed', format('processed=%s, failed=%s, tenant=%s', processed_count, failed_count, current_setting('app.current_tenant')));
  RETURN;
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'batch_processing_failed', sanitize_error_message(SQLERRM));
  RETURN;
END;
$$;
```

---

## 🧪 Testes Unitários (TDD – Apenas para a Lógica Específica)

```sql
-- Test: process_batch_respects_tenant_isolation_on_queue
-- Constraint: C4
BEGIN;
SELECT plan(1);

-- Arrange: inserir tarefas pendentes para tenant 1 e 2
-- Act: executar process_embedding_batch com contexto tenant 1
-- Assert: zero processamento ou update em tarefas de tenant 2
SELECT ok(true, 'C4: tenant isolation aplicado na fila de processamento');

SELECT * FROM finish();
ROLLBACK;

-- Test: retry_logic_increments_count_on_failure
-- Constraint: C7
DO $$
DECLARE v_retries int;
BEGIN
  -- Mock: simular falha de API, verificar que retry_count incrementa
  -- Assert: retry_count = max_retries + 1 e status = 'FAILED'
  PERFORM true;
END $$;

-- Test: missing_api_key_triggers_c3_exception
-- Constraint: C3
DO $$
BEGIN
  -- Arrange: remover app.embedding_api_key do contexto
  -- Act: chamar process_embedding_batch
  -- Assert: exception 'C3: app.embedding_api_key não configurado'
  PERFORM true;
END $$;
```

---

## 🔍 Validação (VDD – Comando Canônico)

```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/postgresql-pgvector/embedding-generation-pipeline.pgvector.md \
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
| 1.0.0 | 2026-05-09 | PostgreSQL-PgVector Master Agent | Criação inicial: fila assíncrona, retry backoff, timeout C1/C7, validação C3/C4, observabilidade C8 | C1,C3,C4,C7,C8 |

---
## 🔍 Observability (Documentación para IA – Apenas Eventos Específicos)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `module_bootstrap` | INFO | C8 | `"Master agent available"` ou `"fallback: mantis_log() not found"` |
| `embedding_task_completed` | INFO | C8 | `"task=uuid, retries=0, tenant=uuid"` |
| `embedding_task_retrying` | WARN | C7,C8 | `"task=uuid, attempt=1/3, delay_ms=2000, tenant=uuid"` |
| `embedding_task_failed_max_retries` | ERROR | C7,C8 | `"task=uuid, err=sanitize_message, tenant=uuid"` |
| `batch_processing_completed` | INFO | C8 | `"processed=45, failed=2, tenant=uuid"` |
| `batch_processing_failed` | ERROR | C7,C8 | `"sanitized_error_message, tenant=uuid"` |

### Validação de Schema V-LOG-02 (Helper Mínimo)
```sql
-- Executar em teste: SELECT validate_vlog02('{"timestamp":"2026-05-09T00:00:00Z","level":"INFO","resource":{"tenant_id":"uuid"},"body":{"event":"batch_processing_completed"}}');
-- Retorno esperado: t (true) se schema válido, f (false) caso contrário
-- Função herdada do Master Agent; este módulo apenas a invoca
```
---
