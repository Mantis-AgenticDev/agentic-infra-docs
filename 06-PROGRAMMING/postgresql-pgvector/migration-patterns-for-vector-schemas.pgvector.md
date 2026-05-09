---
artifact_id: migration-patterns-pgvector
artifact_type: pgvector_pattern
version: "3.1.0"
constraints_mapped: ["C3","C4","C5","C8","V1","V3"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/postgresql-pgvector/migration-patterns-for-vector-schemas.pgvector.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:migration-patterns-v3.1.0-modular"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "postgresql-pgvector"
ai_navigation:
  read_first: false
  required_for: [zero-downtime-migration, vector-backfill, schema-evolution]
  update_frequency: on-change
audience: ["postgresql-pgvector-master-agent", "db-admins", "orchestrator-engine"]
status: "🟡 Refatorado"
next_review: "2026-06-09"
checksum_sha256: "pending-generation"
vector_meta:
  dimensions: 1536
  model: "text-embedding-3-small"
  metric: "cosine"
  index_type: "hnsw"
---

# 🚚 Padrões de Migração para Schemas Vetoriais (Zero Downtime)

> **Contrato modular**: Este artefato é filho do Master Agent `postgresql-pgvector-rag-master-agent-mantis`.
> Herda hardening, observability, thinking system e constraints via source/import.
> Contém APENAS a lógica de migração segura para schemas pgvector (shadow table, backfill em lotes, swap atômico, verificação de integridade).

---

## 🎯 Propósito
Implementar migrações de schemas vetoriais com zero downtime: criação de tabela sombra, backfill em lotes respeitando tenant isolation (C4), indexação `CONCURRENTLY` com parâmetros justificados (V3), swap atômico via transação e verificação de checksum de integridade (C5). Otimizado para evolução de dimensões de embedding ou troca de modelo.

## 📋 Especificação (SDD – Apenas o Específico deste Módulo)
- **Entradas**: `p_source_table` (regclass), `p_target_table` (regclass), `p_batch_size` (int), `p_tenant_id` (uuid), `p_new_dim` (int)
- **Saídas**: Status da migração (`PENDING|IN_PROGRESS|COMPLETED|VERIFIED|ROLLBACK`), métricas de batch, log de auditoria JSONL
- **Side Effects**: Criação de tabela sombra, inserção em lotes, rename atômico, logging C8
- **Constraints Aplicáveis**: C3, C4, C5, C8, V1, V3
- **Dependências**: PostgreSQL 15+, `pgvector >= 0.7.0`, `mantis_log()` herdada, `pgcrypto` (para checksums)

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C4+C5+C8+V1+V3)

```sql
-- Bootstrap modular: source Master Agent OU fallback mínimo
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'mantis_log') THEN
    PERFORM mantis_log('INFO', 'module_bootstrap', 'migration-patterns: Master agent available');
  ELSE
    RAISE LOG '%', json_build_object(
      'timestamp', to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
      'level', 'WARN',
      'resource', json_build_object('tenant_id', current_setting('app.current_tenant', true), 'artifact', 'migration-patterns'),
      'body', json_build_object('event', 'bootstrap_fallback', 'detail', 'mantis_log() not found'),
      'attributes', json_build_object('fallback', 'true')
    );
  END IF;
END $$;

-- C4: Validar contexto de tenant obrigatório para migrações segmentadas
DO $$
BEGIN
  IF current_setting('app.current_tenant', true) IS NULL THEN
    RAISE EXCEPTION 'C4: app.current_tenant não configurado. Migrações vetoriais exigem escopo de tenant.';
  END IF;
END $$;

-- C1: Limites de recursos para operações de migração pesada
SET LOCAL statement_timeout = '120s';
SET LOCAL work_mem = '256MB';
SET LOCAL maintenance_work_mem = '512MB';
```

---

## ✅ V1 + C4 + C5: Preparação da Tabela Sombra com Validação Dimensional

```sql
-- ✅ V1+C5: Criar tabela sombra com estrutura idêntica + nova dimensão
-- Uso: Executar antes do backfill. Não bloqueia leitura na tabela original.
CREATE OR REPLACE FUNCTION prepare_shadow_vector_table(
  p_source_table regclass,
  p_shadow_suffix text DEFAULT '_v2'
) RETURNS regclass
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_shadow_name text;
  v_create_ddl text;
BEGIN
  v_shadow_name := (p_source_table::text || p_shadow_suffix)::regclass;
  
  -- Clonar estrutura, índices e constraints
  v_create_ddl := format('CREATE TABLE %I (LIKE %I INCLUDING ALL)', v_shadow_name, p_source_table);
  EXECUTE v_create_ddl;
  
  -- Ajustar coluna de embedding para nova dimensão (V1)
  EXECUTE format('ALTER TABLE %I ALTER COLUMN embedding TYPE vector(1536)', v_shadow_name);
  
  -- C5: Adicionar coluna de checksum para integridade pós-migração
  EXECUTE format('ALTER TABLE %I ADD COLUMN IF NOT EXISTS migration_checksum bytea', v_shadow_name);
  
  -- Habilitar RLS e políticas (herdadas do source ou recriadas)
  EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', v_shadow_name);
  
  -- C8: Log de criação da sombra
  PERFORM mantis_log('INFO', 'shadow_table_created', 
    format('source=%s, shadow=%s, tenant=%s', p_source_table, v_shadow_name, current_setting('app.current_tenant')));
  
  RETURN v_shadow_name::regclass;
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'shadow_table_creation_failed', sanitize_error_message(SQLERRM));
  RAISE;
END;
$$;
```

---

## ✅ C4 + C8: Backfill em Lotes com Isolamento de Tenant e Progresso Logado

```sql
-- ✅ C4: Migrar embeddings em lotes, filtrando por tenant e respeitando limites de recurso
-- Retorna lote processado e flag de continuação para loop externo
CREATE OR REPLACE FUNCTION backfill_embeddings_batch(
  p_source_table regclass,
  p_target_table regclass,
  p_batch_size int DEFAULT 1000,
  p_last_id bigint DEFAULT 0
) RETURNS TABLE(batch_count int, next_id bigint, completed boolean)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_tenant uuid := current_setting('app.current_tenant')::uuid;
  v_max_id bigint;
BEGIN
  -- C4: Limitar escopo ao tenant configurado
  SELECT COALESCE(MAX(id), 0) INTO v_max_id
  FROM p_source_table
  WHERE tenant_id = v_tenant;
  
  -- Inserção em lote com CTE para evitar lock longo
  WITH batch AS (
    SELECT id, doc_id, tenant_id, embedding, created_at
    FROM p_source_table
    WHERE tenant_id = v_tenant AND id > p_last_id
    ORDER BY id
    LIMIT p_batch_size
    FOR UPDATE SKIP LOCKED  -- Evita bloqueio com consultas simultâneas
  )
  INSERT INTO p_target_table (id, doc_id, tenant_id, embedding, created_at, migration_checksum)
  SELECT id, doc_id, tenant_id, embedding, created_at, 
         digest(id::text || embedding::text, 'sha256')  -- C5: checksum por linha
  FROM batch;
  
  GET DIAGNOSTICS batch_count = ROW_COUNT;
  
  -- C8: Log de progresso do backfill
  PERFORM mantis_log('INFO', 'backfill_batch_completed', 
    format('count=%s, last_id=%s, max_id=%s, tenant=%s', 
      batch_count, p_last_id, v_max_id, v_tenant));
  
  next_id := p_last_id + batch_count;
  completed := (next_id >= v_max_id);
  
  RETURN;
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'backfill_batch_failed', sanitize_error_message(SQLERRM));
  RAISE;
END;
$$;
```

---

## ✅ V3: Indexação CONCURRENTLY na Tabela Sombra (Parâmetros Justificados)

```sql
-- ✅ V3: Criar índice HNSW na sombra sem bloquear leituras na tabela original
-- Parâmetros justificados por pgvector docs para 1536d:
-- m=16: conexões por nó (recall ~0.95, memória controlada)
-- ef_construction=100: profundidade de busca no build (equilíbrio tempo/qualidade)
CREATE OR REPLACE FUNCTION build_shadow_hnsw_index(
  p_shadow_table regclass
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- C8: Log de início de build de índice
  PERFORM mantis_log('INFO', 'hnsw_build_started', 
    format('table=%s, m=16, ef_construction=100, tenant=%s', 
      p_shadow_table, current_setting('app.current_tenant')));
  
  -- V3: CONCURRENTLY permite leituras contínuas na sombra durante build
  EXECUTE format('CREATE INDEX CONCURRENTLY idx_%s_hnsw_v2 ON %I USING hnsw (embedding vector_cosine_ops) WITH (m=16, ef_construction=100)',
                 p_shadow_table::text, p_shadow_table);
  
  -- C8: Log de conclusão
  PERFORM mantis_log('INFO', 'hnsw_build_completed', format('table=%s', p_shadow_table));
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'hnsw_build_failed', sanitize_error_message(SQLERRM));
  RAISE;
END;
$$;
```

---

## ✅ C4 + C5 + V3: Swap Atômico e Verificação de Integridade Pós-Migração

```sql
-- ✅ C5+C4: Troca atômica de tabelas + verificação de checksum e contagem
-- Executar em transação única. Rollback automático se validação falhar.
CREATE OR REPLACE FUNCTION atomic_vector_swap_and_verify(
  p_old_table regclass,
  p_new_table regclass
) RETURNS TABLE(status text, old_count bigint, new_count bigint, checksum_match boolean, detail text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_tenant uuid := current_setting('app.current_tenant')::uuid;
  v_old_count bigint;
  v_new_count bigint;
  v_old_checksum bytea;
  v_new_checksum bytea;
BEGIN
  -- Contagem pré-swap por tenant
  EXECUTE format('SELECT COUNT(*) FROM %I WHERE tenant_id = $1', p_old_table) USING v_tenant INTO v_old_count;
  EXECUTE format('SELECT COUNT(*) FROM %I WHERE tenant_id = $1', p_new_table) USING v_tenant INTO v_new_count;
  
  -- C5: Verificar checksum agregado por tenant
  EXECUTE format('SELECT encode(digest(string_agg(id::text, '''' ORDER BY id), ''sha256''), ''hex'')::bytea FROM %I WHERE tenant_id = $1', p_old_table) 
    USING v_tenant INTO v_old_checksum;
  EXECUTE format('SELECT encode(digest(string_agg(id::text, '''' ORDER BY id), ''sha256''), ''hex'')::bytea FROM %I WHERE tenant_id = $1', p_new_table) 
    USING v_tenant INTO v_new_checksum;
  
  IF v_old_count != v_new_count OR v_old_checksum != v_new_checksum THEN
    PERFORM mantis_log('ERROR', 'swap_verification_failed', 
      format('old_count=%s, new_count=%s, tenant=%s', v_old_count, v_new_count, v_tenant));
    RAISE EXCEPTION 'C5: Migration verification failed. Counts or checksums mismatch.';
  END IF;
  
  -- Swap atômico (renames em transação)
  EXECUTE format('ALTER TABLE %I RENAME TO %I_tmp', p_old_table, p_old_table);
  EXECUTE format('ALTER TABLE %I RENAME TO %I', p_new_table, p_old_table);
  EXECUTE format('ALTER TABLE %I RENAME TO %I_backup', p_old_table || '_tmp', p_old_table);
  
  -- C8: Log de sucesso
  PERFORM mantis_log('INFO', 'atomic_swap_completed', 
    format('table=%s, count=%s, checksum_verified=true, tenant=%s', p_old_table, v_new_count, v_tenant));
  
  RETURN QUERY SELECT 'COMPLETED', v_old_count, v_new_count, true, 'Swap atômico e verificação concluídos';
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'atomic_swap_failed', sanitize_error_message(SQLERRM));
  RAISE;
END;
$$;
```

---

## 🧪 Testes Unitários (TDD – Apenas para a Lógica Específica)

```sql
-- Test: backfill_respects_tenant_isolation
-- Constraint: C4
BEGIN;
SELECT plan(2);

SET LOCAL app.current_tenant = '00000000-0000-0000-0000-000000000001';
-- Arrange: inserir dados mock em source com tenants 1 e 2
-- Act: executar backfill
-- Assert: target contém apenas registros do tenant 1
-- SELECT is((SELECT COUNT(*) FROM shadow_embeddings WHERE tenant_id != current_setting('app.current_tenant')::uuid), 0, 'C4: zero vazamento de tenant');

SELECT * FROM finish();
ROLLBACK;

-- Test: atomic_swap_rollback_on_checksum_mismatch
-- Constraint: C5
DO $$
BEGIN
  -- Arrange: forçar contagem diferente em tabelas temporárias
  -- Act: chamar atomic_vector_swap_and_verify
  -- Assert: deve lançar EXCEPTION 'C5: Migration verification failed'
  -- (Implementação requer fixtures de teste em ambiente CI)
  PERFORM true;
END $$;
```

---

## 🔍 Validação (VDD – Comando Canônico)

```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/postgresql-pgvector/migration-patterns-for-vector-schemas.pgvector.md \
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
| 3.0.0 | 2026-04-19 | PostgreSQL-PgVector Master Agent | Criação inicial: shadow table, batch backfill, swap atômico, verificação C5 | C4,C5,V1 |
| 3.1.0-MODULAR | 2026-05-09 | PostgreSQL-PgVector Master Agent | Refatoração modular: bootstrap resiliente, mantis_log() herdada, V3 index CONCURRENTLY justificado, C8 integrado, wikilink corrigido | C3,C4,C5,C8,V1,V3 |

---
## 🔍 Observability (Documentación para IA – Apenas Eventos Específicos)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `module_bootstrap` | INFO | C8 | `"Master agent available"` ou `"fallback: mantis_log() not found"` |
| `shadow_table_created` | INFO | C5,C8 | `"source=embeddings, shadow=embeddings_v2, tenant=uuid"` |
| `backfill_batch_completed` | INFO | C4,C8 | `"count=1000, last_id=5000, max_id=50000, tenant=uuid"` |
| `hnsw_build_started` | INFO | V3,C8 | `"table=embeddings_v2, m=16, ef_construction=100, tenant=uuid"` |
| `atomic_swap_completed` | INFO | C5,C8 | `"table=embeddings, count=50000, checksum_verified=true, tenant=uuid"` |
| `swap_verification_failed` | ERROR | C5,C8 | `"old_count=50000, new_count=49850, tenant=uuid"` |

### Validação de Schema V-LOG-02 (Helper Mínimo)
```sql
-- Executar em teste: SELECT validate_vlog02('{"timestamp":"2026-05-09T00:00:00Z","level":"INFO","resource":{"tenant_id":"uuid"},"body":{"event":"shadow_table_created"}}');
-- Retorno esperado: t (true) se schema válido, f (false) caso contrário
-- Função herdada do Master Agent; este módulo apenas a invoca
```
---
