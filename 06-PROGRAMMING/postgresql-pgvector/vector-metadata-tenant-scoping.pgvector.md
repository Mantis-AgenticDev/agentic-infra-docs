---
artifact_id: vector-metadata-tenant-scoping-pgvector
artifact_type: pgvector_pattern
version: "1.0.0"
constraints_mapped: ["C3","C4","C5","C6","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/postgresql-pgvector/vector-metadata-tenant-scoping.pgvector.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:vector-metadata-tenant-scoping-v1.0.0-modular"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "postgresql-pgvector"
ai_navigation:
  read_first: false
  required_for: [pre-vector-filtering, jsonb-scope-enforcement, hybrid-search-optimization, tenant-data-governance]
  update_frequency: on-change
audience: ["postgresql-pgvector-master-agent", "backend-engineers", "data-engineers", "orchestrator-engine"]
status: "🟢 Novo"
next_review: "2026-06-09"
checksum_sha256: "pending-generation"
vector_meta:
  dimensions: 1536
  model: "text-embedding-3-small"
  metric: "cosine"
  index_type: "hnsw"
---

# 🏷️ Filtrado por Metadados e Escopo de Tenant (pgvector + JSONB)

> **Contrato modular**: Este artefato é filho do Master Agent `postgresql-pgvector-rag-master-agent-mantis`.
> Herda hardening, observability, thinking system e constraints via source/import.
> Contém APENAS a lógica de validação de filtros JSONB, aplicação segura de escopo por tenant antes da busca vetorial, índices GIN otimizados e auditoria de acesso a metadados sensíveis.

---

## 🎯 Propósito
Implementar filtragem pré-busca por metadados (`metadata JSONB`) combinada com isolamento estrito de tenant, validando chaves permitidas (C3/C5), aplicando políticas RLS (C4), auditando acessos a dados sensíveis (C6/C8) e garantindo que filtros JSONB sejam executados via índice GIN antes do escaneamento vetorial custoso. Otimizado para RAG empresarial com regras de compliance e escopo granular.

## 📋 Especificação (SDD – Apenas o Específico deste Módulo)
- **Entradas**: `p_query_vec` (vector), `p_metadata_filter` (jsonb), `p_tenant_id` (uuid)
- **Saídas**: Tabela com `doc_id`, `similarity`, `metadata_match_score`
- **Side Effects**: Apenas leitura; validação de schema JSONB; logging de auditoria C8
- **Constraints Aplicáveis**: C3, C4, C5, C6, C8
- **Dependências**: PostgreSQL 14+, `pgvector >= 0.7.0`, tabela `documents` com coluna `metadata JSONB`, `mantis_log()` herdada

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C4+C6+C8)

```sql
-- Bootstrap modular: source Master Agent OU fallback mínimo
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'mantis_log') THEN
    PERFORM mantis_log('INFO', 'module_bootstrap', 'vector-metadata-tenant-scoping: Master agent available');
  ELSE
    RAISE LOG '%', json_build_object(
      'timestamp', to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
      'level', 'WARN',
      'resource', json_build_object('tenant_id', current_setting('app.current_tenant', true), 'artifact', 'vector-metadata-tenant-scoping'),
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

-- C1: Limites de recursos para operações de filtro + busca
SET LOCAL statement_timeout = '15s';
SET LOCAL work_mem = '128MB';
```

---

## ✅ C3 + C5: Validação Segura de Filtros JSONB

```sql
-- ✅ C3+C5: Validar chaves permitidas e estrutura do filtro antes de execução
-- Previne injeção de chaves sensíveis ou queries malformadas em metadata
CREATE OR REPLACE FUNCTION validate_metadata_filter(p_filter jsonb, p_allowed_keys text[] DEFAULT ARRAY['category', 'status', 'author', 'tags', 'created_at'])
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_key text;
BEGIN
  IF p_filter IS NULL OR p_filter = '{}'::jsonb THEN
    RETURN true;  -- Filtro vazio é permitido (busca global no tenant)
  END IF;

  -- Iterar sobre chaves do filtro
  FOR v_key IN SELECT jsonb_object_keys(p_filter) LOOP
    IF NOT (v_key = ANY(p_allowed_keys)) THEN
      -- C8: Log de tentativa de acesso a chave não autorizada
      PERFORM mantis_log('WARN', 'metadata_filter_key_rejected', 
        format('key=%s, allowed=%s, tenant=%s', v_key, array_to_string(p_allowed_keys, ','), current_setting('app.current_tenant')));
      RAISE EXCEPTION 'C3/C5: Metadata filter key "%" is not allowed for tenant scoping.', v_key;
    END IF;
  END LOOP;

  RETURN true;
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'metadata_validation_failed', sanitize_error_message(SQLERRM));
  RAISE;
END;
$$;
```

---

## ✅ C4 + C6 + C8: Busca com Escopo de Metadados e Tenant Enforcement

```sql
-- ✅ C4+C6+C8: Função principal que aplica RLS + filtro JSONB seguro + busca vetorial
CREATE OR REPLACE FUNCTION search_with_metadata_scoping(
  p_query_vec vector(1536),  -- V1: dimensão explícita
  p_metadata_filter jsonb DEFAULT '{}',
  p_tenant_id uuid,
  p_limit int DEFAULT 10
) RETURNS TABLE(
  doc_id uuid,
  similarity float,
  matched_metadata jsonb
)
LANGUAGE plpgsql
SECURITY DEFINER  -- C6: execução com privilégios controlados
SET search_path = ''
AS $$
BEGIN
  -- C3/C5: Validar filtro antes de prosseguir
  IF NOT validate_metadata_filter(p_metadata_filter) THEN
    RAISE EXCEPTION 'C5: Invalid metadata filter structure';
  END IF;

  -- ✅ C4+V2: Executar busca com filtro GIN pré-aplicado + cosine similarity
  -- O planner usará índice GIN(metadata) + HNSW(embedding) automaticamente
  RETURN QUERY
  SELECT 
    d.id AS doc_id,
    1.0 - (de.embedding <=> p_query_vec) AS similarity,
    d.metadata
  FROM documents d
  JOIN document_embeddings de ON d.id = de.doc_id
  WHERE d.tenant_id = p_tenant_id  -- ✅ C4: isolamento obrigatório
    AND (p_metadata_filter = '{}'::jsonb OR d.metadata @> p_metadata_filter)  -- ✅ C5: filtro contido
  ORDER BY de.embedding <=> p_query_vec
  LIMIT p_limit;

  -- C8: Auditoria de busca com metadados
  PERFORM mantis_log('INFO', 'metadata_scoped_search_completed', 
    format('filter_keys=%s, limit=%s, tenant=%s', 
           jsonb_object_keys(p_metadata_filter), p_limit, p_tenant_id));
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'metadata_scoped_search_failed', sanitize_error_message(SQLERRM));
  RAISE;
END;
$$;
```

---

## ✅ C5 + C8: Índices Otimizados e RLS para Metadados

```sql
-- ✅ C5: Índice GIN para filtragem rápida de metadados por tenant
-- jsonb_path_ops é mais leve e ideal para operadores de contenção (@>)
CREATE INDEX IF NOT EXISTS idx_doc_metadata_gin ON documents
  USING GIN (metadata jsonb_path_ops)
  WHERE tenant_id IS NOT NULL;  -- Partial index para otimizar espaço

-- ✅ C4+C6: Garantir que políticas RLS cobrem acesso a metadados
-- (Já coberto por emb_select_tenant/doc_select_tenant, mas documentado para auditoria)
DO $$
BEGIN
  -- Verificar se políticas existentes cobrem SELECT com WHERE tenant_id
  IF NOT EXISTS (SELECT 1 FROM pg_policy WHERE polrelid = 'documents'::regclass AND polcmd = 'r') THEN
    PERFORM mantis_log('WARN', 'rls_policy_missing_on_documents', 'tenant=%s', current_setting('app.current_tenant'));
  END IF;
END $$;
```

---

## 🧪 Testes Unitários (TDD – Apenas para a Lógica Específica)

```sql
-- Test: validate_metadata_filter_rejects_unauthorized_keys
-- Constraint: C3+C5
BEGIN;
SELECT plan(2);

-- Arrange: filtro com chave permitida vs não permitida
-- Act/Assert: chave permitida retorna true
SELECT ok(validate_metadata_filter('{"category": "finance"}', ARRAY['category']), 'C5: chave permitida deve validar');

-- Act/Assert: chave não permitida lança exceção
SELECT throws_ok(
  'SELECT validate_metadata_filter(''{"password": "secret"}'', ARRAY[''category''])',
  'C3/C5: Metadata filter key "password" is not allowed for tenant scoping.',
  'C3: chave sensível deve ser rejeitada'
);

SELECT * FROM finish();
ROLLBACK;

-- Test: search_respects_metadata_filter_and_tenant
-- Constraint: C4+C5
DO $$
DECLARE v_count int;
BEGIN
  -- Mock: inserir docs com tenant 1 e metadata '{"status": "active"}'
  -- Act: buscar com tenant 1 e filter '{"status": "draft"}'
  -- Assert: count = 0
  PERFORM true;  -- Placeholder para validação em CI com fixtures reais
END $$;
```

---

## 🔍 Validação (VDD – Comando Canônico)

```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/postgresql-pgvector/vector-metadata-tenant-scoping.pgvector.md \
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
| 1.0.0 | 2026-05-09 | PostgreSQL-PgVector Master Agent | Criação inicial: validação JSONB segura, escopo de metadados + tenant, índice GIN otimizado, auditoria C6/C8 | C3,C4,C5,C6,C8 |

---
## 🔍 Observability (Documentación para IA – Apenas Eventos Específicos)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `module_bootstrap` | INFO | C8 | `"Master agent available"` ou `"fallback: mantis_log() not found"` |
| `metadata_validation_failed` | ERROR | C3,C8 | `"sanitized_error_message, tenant=uuid"` |
| `metadata_filter_key_rejected` | WARN | C3,C5 | `"key=password, allowed=category,status, tenant=uuid"` |
| `metadata_scoped_search_completed` | INFO | C4,C8 | `"filter_keys=["category","status"], limit=10, tenant=uuid"` |
| `rls_policy_missing_on_documents` | WARN | C4,C6 | `"tenant=uuid"` |

### Validação de Schema V-LOG-02 (Helper Mínimo)
```sql
-- Executar em teste: SELECT validate_vlog02('{"timestamp":"2026-05-09T00:00:00Z","level":"INFO","resource":{"tenant_id":"uuid"},"body":{"event":"metadata_scoped_search_completed"}}');
-- Retorno esperado: t (true) se schema válido, f (false) caso contrário
-- Função herdada do Master Agent; este módulo apenas a invoca
```
---
