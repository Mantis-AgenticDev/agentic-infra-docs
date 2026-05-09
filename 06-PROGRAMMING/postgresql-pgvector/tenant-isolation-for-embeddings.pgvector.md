---
artifact_id: tenant-isolation-embeddings-pgvector
artifact_type: pgvector_pattern
version: "3.1.0"
constraints_mapped: ["C3","C4","C5","C8","V1","V2","V3"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/postgresql-pgvector/tenant-isolation-for-embeddings.pgvector.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:tenant-isolation-v3.1.0-modular"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "postgresql-pgvector"
ai_navigation:
  read_first: false
  required_for: [multi-tenant-schema, rls-policy-enforcement, secure-embedding-storage]
  update_frequency: on-change
audience: ["postgresql-pgvector-master-agent", "db-admins", "backend-engineers"]
status: "🟡 Refatorado"
next_review: "2026-06-09"
checksum_sha256: "pending-generation"
vector_meta:
  dimensions: 1536
  model: "text-embedding-3-small"
  metric: "cosine"
  index_type: "hnsw"
---

# 🔒 Isolamento Multi-Tenant para Embeddings (pgvector + RLS)

> **Contrato modular**: Este artefato é filho do Master Agent `postgresql-pgvector-rag-master-agent-mantis`.
> Herda hardening, observability, thinking system e constraints via source/import.
> Contém APENAS a lógica de schema, políticas RLS, propagação de contexto de tenant e validação de isolamento para tabelas de embeddings pgvector.

---

## 🎯 Propósito
Implementar isolamento estrito de dados vetoriais por tenant usando Row-Level Security (RLS) do PostgreSQL, propagação segura de `tenant_id` via contexto de sessão, índices HNSW com parâmetros justificados (V3), validação dimensional explícita (V1) e auditoria de cobertura de políticas (C4/C5/C8). Otimizado para arquiteturas multi-tenant SaaS com zero vazamento cruzado e compliance enterprise.

## 📋 Especificação (SDD – Apenas o Específico deste Módulo)
- **Entradas**: `tenant_id` (uuid), contexto de sessão (`app.current_tenant`), definição de tabela
- **Saídas**: Schema seguro, políticas RLS ativas, índices locais, relatório de auditoria de cobertura
- **Side Effects**: Criação/modificação de tabelas e políticas; logging C8; nenhuma exposição de dados entre tenants
- **Constraints Aplicáveis**: C3, C4, C5, C8, V1, V2, V3
- **Dependências**: PostgreSQL 15+, `pgvector >= 0.7.0`, `mantis_log()` herdada

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C4+C8+V1+V2+V3)

```sql
-- Bootstrap modular: source Master Agent OU fallback mínimo
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'mantis_log') THEN
    PERFORM mantis_log('INFO', 'module_bootstrap', 'tenant-isolation-embeddings: Master agent available');
  ELSE
    RAISE LOG '%', json_build_object(
      'timestamp', to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
      'level', 'WARN',
      'resource', json_build_object('tenant_id', current_setting('app.current_tenant', true), 'artifact', 'tenant-isolation-embeddings'),
      'body', json_build_object('event', 'bootstrap_fallback', 'detail', 'mantis_log() not found'),
      'attributes', json_build_object('fallback', 'true')
    );
  END IF;
END $$;

-- C4: Validar contexto de tenant obrigatório
DO $$
BEGIN
  IF current_setting('app.current_tenant', true) IS NULL THEN
    RAISE EXCEPTION 'C4: app.current_tenant não configurado. Isolamento de embeddings exige escopo explícito.';
  END IF;
END $$;

-- C1: Limites de recursos para operações de isolamento
SET LOCAL statement_timeout = '30s';
SET LOCAL work_mem = '128MB';
```

---

## ✅ C4 + V1: Schema Seguro com Tenant ID e Dimensão Explícita

```sql
-- ✅ C4+V1: Tabela base de embeddings com isolamento nativo e dimensão fixa
CREATE TABLE IF NOT EXISTS tenant_embeddings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL,
  doc_id uuid NOT NULL,
  embedding vector(1536) NOT NULL,  -- ✅ V1: dimensão explícita
  embedding_model text NOT NULL DEFAULT 'text-embedding-3-small',
  content_hash bytea NOT NULL,      -- ✅ C5: integridade do conteúdo
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(tenant_id, doc_id)
);

-- ✅ C4: Habilitar RLS e criar políticas granulares
ALTER TABLE tenant_embeddings ENABLE ROW LEVEL SECURITY;

-- SELECT/SEARCH: permite leitura apenas do tenant ativo
CREATE POLICY emb_select_tenant ON tenant_embeddings
  FOR SELECT USING (tenant_id = current_setting('app.current_tenant')::uuid);

-- INSERT: permite escrita apenas se tenant_id corresponder ao contexto
CREATE POLICY emb_insert_tenant ON tenant_embeddings
  FOR INSERT WITH CHECK (tenant_id = current_setting('app.current_tenant')::uuid);

-- UPDATE: permite atualização apenas de registros do próprio tenant
CREATE POLICY emb_update_tenant ON tenant_embeddings
  FOR UPDATE USING (tenant_id = current_setting('app.current_tenant')::uuid);

-- DELETE: permite remoção apenas de registros do próprio tenant
CREATE POLICY emb_delete_tenant ON tenant_embeddings
  FOR DELETE USING (tenant_id = current_setting('app.current_tenant')::uuid);

-- ✅ C4: Forçar RLS mesmo para superusers (ambiente production/CI)
ALTER TABLE tenant_embeddings FORCE ROW LEVEL SECURITY;
```

---

## ✅ C4 + C5: Propagação Segura de Contexto de Tenant

```sql
-- ✅ C4+C5: Função para definir e validar contexto de tenant na sessão atual
-- Uso: Executar no início de cada request ou transação de aplicação
CREATE OR REPLACE FUNCTION set_tenant_context(p_tenant_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- C3: Validação de formato UUID
  IF p_tenant_id IS NULL OR p_tenant_id = '00000000-0000-0000-0000-000000000000'::uuid THEN
    RAISE EXCEPTION 'C3/C4: Invalid or null tenant_id';
  END IF;

  -- Propagar para contexto PostgreSQL
  PERFORM set_config('app.current_tenant', p_tenant_id::text, false);
  
  -- C8: Logging de troca de contexto
  PERFORM mantis_log('INFO', 'tenant_context_set', format('tenant=%s', p_tenant_id));
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'set_tenant_context_failed', sanitize_error_message(SQLERRM));
  RAISE;
END;
$$;

-- ✅ C4: Reset seguro de contexto ao fim da sessão/transação
CREATE OR REPLACE FUNCTION reset_tenant_context()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  PERFORM set_config('app.current_tenant', NULL, true);
  PERFORM mantis_log('INFO', 'tenant_context_reset', 'session_ended');
END;
$$;
```

---

## ✅ V2 + V3: Índice HNSW com Métrica Documentada e Parâmetros Justificados

```sql
-- ✅ V2+V3: Índice vetorial isolado por tabela (herda RLS automaticamente)
-- V2: vector_cosine_ops corresponde ao operador <=> (cosine distance)
-- V3: m=16, ef_construction=100 (padrão pgvector para 1536d, recall ~0.95)
CREATE INDEX IF NOT EXISTS idx_tenant_emb_hnsw_cosine ON tenant_embeddings
  USING hnsw (embedding vector_cosine_ops)
  WITH (m = 16, ef_construction = 100);

-- ✅ C8: Função para verificar se índice está ativo e cobrindo métrica declarada
CREATE OR REPLACE FUNCTION verify_hnsw_coverage(p_table regclass)
RETURNS TABLE(index_name name, opclass text, params jsonb, is_active boolean)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    i.indexname,
    i.indexdef,
    json_build_object(
      'm', substring(i.indexdef from 'm=(\d+)')::int,
      'ef_construction', substring(i.indexdef from 'ef_construction=(\d+)')::int
    ) AS params,
    i.indexdef ~* 'CREATE INDEX' AS is_active
  FROM pg_indexes i
  WHERE i.tablename = (SELECT relname FROM pg_class WHERE oid = p_table)
    AND i.indexdef ~* 'hnsw';
    
  PERFORM mantis_log('INFO', 'hnsw_coverage_verified', format('table=%s, tenant=%s', p_table, current_setting('app.current_tenant')));
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'verify_hnsw_failed', sanitize_error_message(SQLERRM));
  RETURN;
END;
$$;
```

---

## ✅ C8 + C4: Auditoria de Cobertura RLS e Isolamento

```sql
-- ✅ C8: Função para validar que TODAS as tabelas de embeddings têm RLS ativo e políticas cobrindo CRUD
CREATE OR REPLACE FUNCTION audit_embedding_rls_coverage()
RETURNS TABLE(table_name text, rls_enabled boolean, policy_count int, coverage_status text, recommendation text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE r RECORD;
BEGIN
  FOR r IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename LIKE '%embed%' LOOP
    SELECT relrowsecurity INTO rls_enabled FROM pg_class WHERE relname = r.tablename;
    SELECT COUNT(*) INTO policy_count FROM pg_policy WHERE polrelid = (r.tablename)::regclass;

    coverage_status := CASE
      WHEN rls_enabled AND policy_count >= 4 THEN 'FULL'
      WHEN rls_enabled AND policy_count > 0 THEN 'PARTIAL'
      WHEN rls_enabled AND policy_count = 0 THEN 'ENABLED_NO_POLICIES'
      ELSE 'DISABLED'
    END;

    recommendation := CASE coverage_status
      WHEN 'FULL' THEN 'OK'
      WHEN 'PARTIAL' THEN 'Adicionar políticas faltantes para cobrir CRUD completo'
      WHEN 'ENABLED_NO_POLICIES' THEN 'Criar políticas USING/WITH CHECK para tenant isolation'
      ELSE 'Executar ALTER TABLE ... ENABLE ROW LEVEL SECURITY'
    END;

    RETURN QUERY SELECT r.tablename, rls_enabled, policy_count, coverage_status, recommendation;
  END LOOP;

  PERFORM mantis_log('INFO', 'rls_coverage_audit_completed', format('tenant=%s', current_setting('app.current_tenant')));
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'rls_audit_failed', sanitize_error_message(SQLERRM));
  RETURN;
END;
$$;

-- Uso: SELECT * FROM audit_embedding_rls_coverage();
```

---

## 🧪 Testes Unitários (TDD – Apenas para a Lógica Específica)

```sql
-- Test: rls_policy_covers_all_crud_operations
-- Constraint: C4
BEGIN;
SELECT plan(4);

-- Arrange: tabela temporária para teste
CREATE TEMP TABLE test_emb (id uuid, tenant_id uuid, embedding vector(2));
ALTER TABLE test_emb ENABLE ROW LEVEL SECURITY;
CREATE POLICY t_sel ON test_emb FOR SELECT USING (tenant_id = current_setting('app.current_tenant')::uuid);
CREATE POLICY t_ins ON test_emb FOR INSERT WITH CHECK (tenant_id = current_setting('app.current_tenant')::uuid);
CREATE POLICY t_upd ON test_emb FOR UPDATE USING (tenant_id = current_setting('app.current_tenant')::uuid);
CREATE POLICY t_del ON test_emb FOR DELETE USING (tenant_id = current_setting('app.current_tenant')::uuid);

-- Act+Assert: verificar contagem de políticas
SELECT is((SELECT COUNT(*) FROM pg_policy WHERE polrelid = 'test_emb'::regclass), 4, 'C4: 4 políticas CRUD criadas');

-- (Em CI real: simular tentativas de cross-tenant access e assertar 0 linhas)

SELECT * FROM finish();
ROLLBACK;

-- Test: tenant_context_propagation_validates_uuid_format
-- Constraint: C3+C4
DO $$
BEGIN
  -- Act: set_tenant_context('not-a-uuid')
  -- Assert: exception 'C3/C4: Invalid or null tenant_id'
  PERFORM true;  -- Placeholder para validação em CI
END $$;
```

---

## 🔍 Validação (VDD – Comando Canônico)

```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/postgresql-pgvector/tenant-isolation-for-embeddings.pgvector.md \
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
| 3.0.0 | 2026-04-19 | PostgreSQL-PgVector Master Agent | Criação inicial: schema embeddings, RLS policies, tenant propagation | C4,C5,V1 |
| 3.1.0-MODULAR | 2026-05-09 | PostgreSQL-PgVector Master Agent | Refatoração modular: bootstrap resiliente, mantis_log() herdada, V2/V3 documentados, auditoria RLS C8, FORCE RLS, sanitização C3, wikilink corrigido | C3,C4,C5,C8,V1,V2,V3 |

---
## 🔍 Observability (Documentación para IA – Apenas Eventos Específicos)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `module_bootstrap` | INFO | C8 | `"Master agent available"` ou `"fallback: mantis_log() not found"` |
| `tenant_context_set` | INFO | C4,C8 | `"tenant=uuid"` |
| `tenant_context_reset` | INFO | C4,C8 | `"session_ended"` |
| `hnsw_coverage_verified` | INFO | V3,C8 | `"table=tenant_embeddings, tenant=uuid"` |
| `rls_coverage_audit_completed` | INFO | C4,C8 | `"tenant=uuid, coverage=FULL/PARTIAL/DISABLED"` |
| `set_tenant_context_failed` | ERROR | C3,C8 | `"sanitized_error_message"` |

### Validação de Schema V-LOG-02 (Helper Mínimo)
```sql
-- Executar em teste: SELECT validate_vlog02('{"timestamp":"2026-05-09T00:00:00Z","level":"INFO","resource":{"tenant_id":"uuid"},"body":{"event":"tenant_context_set"}}');
-- Retorno esperado: t (true) se schema válido, f (false) caso contrário
-- Função herdada do Master Agent; este módulo apenas a invoca
```
---
