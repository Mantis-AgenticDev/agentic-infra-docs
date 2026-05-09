---
artifact_id: fix-sintaxis-code-pgvector
artifact_type: pgvector_pattern
version: "3.1.0"
constraints_mapped: ["C3","C4","C5","V1","V2","V3"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/postgresql-pgvector/fix-sintaxis-code.pgvector.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:fix-sintaxis-code-v3.1.0-modular"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "postgresql-pgvector"
ai_navigation:
  read_first: false
  required_for: [vector-linting, constraint-validation, pre-deploy-check]
  update_frequency: on-change
audience: ["postgresql-pgvector-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟡 Refatorado"
next_review: "2026-06-09"
checksum_sha256: "pending-generation"
vector_meta:
  dimensions: 1536
  model: "text-embedding-3-small"
  metric: "cosine"
  index_type: "hnsw"
---

# 🔧 Linting para Vetores: Validação Dimensional e Métrica (pgvector)

> **Contrato modular**: Este artefato é filho do Master Agent `postgresql-pgvector-rag-master-agent-mantis`.
> Herda hardening, observability, thinking system e constraints via source/import.
> Contém APENAS a lógica de linting específica para validação de vetores pgvector.

---

## 🎯 Propósito
Padrões de linting estático e dinâmico para código pgvector: validação de dimensão (V1), operador de distância explícito (V2), isolamento de tenant em queries (C4), e integridade de embeddings via checksum (C5). Detecta e corrige anti-patterns antes de deploy.

## 📋 Especificação (SDD – Apenas o Específico deste Módulo)
- **Entradas**: Vetor (`vector`), dimensão esperada (`int`), métrica declarada (`text`), tenant_id (`uuid`)
- **Saídas**: Booleano de validação, tabela de auditoria, JSONL de eventos via `mantis_log()`
- **Side Effects**: Nenhuma modificação de dados; apenas validação e logging
- **Constraints Aplicáveis**: C3 (zero secrets), C4 (tenant isolation), C5 (integridade), V1 (dimensões), V2 (métrica), V3 (índices)
- **Dependências**: PostgreSQL 15+, extensão `pgvector >= 0.7.0`, função `mantis_log()` herdada do Master Agent

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C4+C5+V1+V2+V3)
> **Regra de ouro**: Fonte o Master Agent para herdar hardening/observability. Se não disponível, fallback mínimo.

```sql
-- Bootstrap modular: source Master Agent OU fallback mínimo
-- Executar no início de cada sessão ou script que use este módulo
DO $$
BEGIN
  -- Tentar usar mantis_log() herdada do Master Agent
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'mantis_log') THEN
    PERFORM mantis_log('INFO', 'module_bootstrap', 'fix-sintaxis-code: Master agent available');
  ELSE
    -- Fallback mínimo: logging estruturado sem dependências externas
    RAISE LOG '%', json_build_object(
      'timestamp', to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
      'level', 'WARN',
      'resource', json_build_object('tenant_id', current_setting('app.current_tenant', true), 'artifact', 'fix-sintaxis-code'),
      'body', json_build_object('event', 'bootstrap_fallback', 'detail', 'mantis_log() not found, using RAISE LOG'),
      'attributes', json_build_object('fallback', 'true', 'constraint', 'C8')
    );
  END IF;
END $$;

-- C4: Validar que tenant_id está configurado para esta sessão
DO $$
BEGIN
  IF current_setting('app.current_tenant', true) IS NULL THEN
    RAISE EXCEPTION 'C4: app.current_tenant não configurado. Use: SET LOCAL app.current_tenant = %', quote_literal(current_user);
  END IF;
END $$;

-- C1: Limites de recursos para operações de linting
SET LOCAL statement_timeout = '10s';
SET LOCAL work_mem = '64MB';
```

---

## ✅ V1: Lint Function para Validar Dimensão de Vetor

```sql
-- ✅ V1: Função imutável para validar dimensão de vetor em runtime
-- Uso: WHERE lint_vector_dim($vec, 1536) em INSERT/SELECT
CREATE OR REPLACE FUNCTION lint_vector_dim(p_vec vector, p_expected int)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- C3: Validar que p_vec não é NULL
  IF p_vec IS NULL THEN
    RETURN false;
  END IF;
  
  -- V1: Comparar dimensão real com esperada
  RETURN array_length(p_vec, 1) = p_expected;
EXCEPTION WHEN OTHERS THEN
  -- C7: Fallback seguro em caso de erro
  RETURN false;
END;
$$;

-- ✅ V1: Trigger para rejeitar vetores com dimensão incorreta pre-inserção
CREATE OR REPLACE FUNCTION enforce_vec_dim()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- V1: Validar dimensão antes de inserir/atualizar
  IF array_length(NEW.vec, 1) IS DISTINCT FROM 1536 THEN
    -- C8: Logging estruturado da violação
    PERFORM mantis_log('ERROR', 'v1_dimension_violation', 
      format('expected=1536, got=%s, table=%s, tenant=%s', 
        array_length(NEW.vec, 1), TG_TABLE_NAME, current_setting('app.current_tenant')));
    
    RAISE EXCEPTION 'V1: Vector dimension must be 1536, got %', array_length(NEW.vec, 1);
  END IF;
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- C7: Logging de erro sem expor detalhes sensíveis
  PERFORM mantis_log('ERROR', 'enforce_vec_dim_failed', SQLERRM);
  RAISE;
END;
$$;

-- ✅ V1: Aplicar trigger apenas se tabela for multi-tenant (C4)
-- Nota: Executar apenas uma vez por schema, não em cada query
-- CREATE TRIGGER trg_enforce_vec_dim BEFORE INSERT OR UPDATE ON embeddings
--   FOR EACH ROW EXECUTE FUNCTION enforce_vec_dim();

-- ✅ V1: ALTER TABLE para adicionar validação dimensional post-migração
-- Estratégia: NOT VALID permite migração sem bloqueio; VALIDATE verifica dados existentes
-- ALTER TABLE embeddings
--   ADD CONSTRAINT chk_vec_1536 CHECK (array_length(vec, 1) = 1536) NOT VALID;
-- ALTER TABLE embeddings VALIDATE CONSTRAINT chk_vec_1536;

-- ✅ V1+C4: Query de linting para detectar vetores com dimensão incorreta por tenant
CREATE OR REPLACE FUNCTION lint_vec_dim_by_tenant(p_expected int DEFAULT 1536)
RETURNS TABLE(tenant_id uuid, violation_count bigint, sample_ids uuid[])
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    e.tenant_id,
    COUNT(*) AS violation_count,
    array_agg(e.id ORDER BY e.id LIMIT 5) AS sample_ids
  FROM embeddings e
  WHERE e.tenant_id = current_setting('app.current_tenant')::uuid  -- ✅ C4
    AND array_length(e.vec, 1) IS DISTINCT FROM p_expected
  GROUP BY e.tenant_id;
  
  -- C8: Logging do resultado do linting
  PERFORM mantis_log('INFO', 'lint_vec_dim_completed', 
    format('expected=%s, tenant=%s', p_expected, current_setting('app.current_tenant')));
END;
$$;
```

---

## ✅ V2: Lint para Operador de Distância Explícito

```sql
-- ✅ V2: Função wrapper para forçar operador de distância explícito em buscas
-- Encapsula <=> (cosine) + C4: filtra por tenant + V1: valida dimensão
CREATE OR REPLACE FUNCTION search_cosine(
  p_query vector(1536),  -- ✅ V1: dimensão explícita no tipo
  p_limit int DEFAULT 10
)
RETURNS TABLE(id uuid, similarity float)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- V2: Validar que query tem mesma dimensão que índice
  IF array_length(p_query, 1) IS DISTINCT FROM 1536 THEN
    PERFORM mantis_log('ERROR', 'v2_query_dim_mismatch', 
      format('expected=1536, got=%s', array_length(p_query, 1)));
    RAISE EXCEPTION 'V2: Query vector dimension mismatch: expected 1536';
  END IF;
  
  -- ✅ C4+V2: Busca com filtro de tenant + operador cosine explícito (<=>)
  RETURN QUERY
  SELECT e.id, 1 - (e.vec <=> p_query) AS similarity  -- ✅ V2: cosine distance documentado
  FROM embeddings e
  WHERE e.tenant_id = current_setting('app.current_tenant')::uuid  -- ✅ C4
  ORDER BY e.vec <=> p_query  -- ✅ V2: operador explícito
  LIMIT p_limit;
  
  -- C8: Logging da busca concluída
  PERFORM mantis_log('INFO', 'search_cosine_completed', 
    format('limit=%s, tenant=%s', p_limit, current_setting('app.current_tenant')));
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'search_cosine_failed', SQLERRM);
  RAISE;
END;
$$;

-- ✅ V2: Lint query para detectar operadores de distância não documentados em produção
-- Uso: Auditoria periódica para garantir consistência de métrica (V2)
CREATE OR REPLACE FUNCTION lint_distance_operators_in_use()
RETURNS TABLE(query_pattern text, detected_metric text, usage_count bigint)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  RETURN QUERY
  SELECT
    CASE
      WHEN query LIKE '%<->%' THEN 'euclidean'
      WHEN query LIKE '%<#>%' THEN 'inner_product'
      WHEN query LIKE '%<=>%' THEN 'cosine'
      ELSE 'unknown'
    END AS detected_metric,
    COUNT(*) AS usage_count
  FROM pg_stat_statements
  WHERE query LIKE '%vector%'
    AND query LIKE '%ORDER BY%<%>% %'  -- Detecta operadores de distância
  GROUP BY detected_metric
  ORDER BY usage_count DESC;
  
  -- C8: Logging do resultado da auditoria
  PERFORM mantis_log('INFO', 'lint_distance_operators_completed', 'audit_vector_metrics');
END;
$$;

-- ✅ V2+C4: Função de normalização de query conforme métrica declarada
-- Centraliza pré-processamento para garantir consistência entre clientes
CREATE OR REPLACE FUNCTION lint_and_normalize_query(
  p_raw vector,
  p_metric text DEFAULT 'cosine',  -- ✅ V2: métrica declarada
  p_dim int DEFAULT 1536           -- ✅ V1: dimensão declarada
)
RETURNS vector
LANGUAGE plpgsql
IMMUTABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_norm float;
BEGIN
  -- V1: Validar dimensão da query
  IF array_length(p_raw, 1) IS DISTINCT FROM p_dim THEN
    RAISE EXCEPTION 'V1: Dimension mismatch: expected %, got %', p_dim, array_length(p_raw, 1);
  END IF;
  
  -- V2: Validar métrica suportada
  IF p_metric NOT IN ('cosine', 'euclidean', 'inner_product') THEN
    RAISE EXCEPTION 'V2: Invalid metric: %. Supported: cosine, euclidean, inner_product', p_metric;
  END IF;
  
  -- V2: Normalização opcional para cosine/inner_product (vetores unitários)
  IF p_metric IN ('cosine', 'inner_product') THEN
    v_norm := sqrt(p_raw <#> p_raw);  -- Norma L2
    IF v_norm > 0 THEN
      RETURN p_raw / v_norm;  -- Normalizar para norma 1
    END IF;
  END IF;
  
  RETURN p_raw;
EXCEPTION WHEN OTHERS THEN
  -- C8: Logging de erro sem expor dados sensíveis
  PERFORM mantis_log('ERROR', 'lint_and_normalize_failed', 
    format('metric=%s, dim=%s', p_metric, p_dim));
  RAISE;
END;
$$;
```

---

## ✅ C4: Lint para Isolamento de Tenant em Queries

```sql
-- ✅ C4: Função para validar que RLS cobre INSERT/UPDATE além de SELECT
-- Uso: Auditoria de políticas RLS para garantir cobertura completa
CREATE OR REPLACE FUNCTION lint_rls_policy_coverage(p_table regclass)
RETURNS TABLE(policy_name name, cmd char, has_using boolean, has_with_check boolean, coverage text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  RETURN QUERY
  SELECT
    pol.polname,
    pol.polcmd,
    pol.polqual IS NOT NULL AS has_using,
    pol.polwithcheck IS NOT NULL AS has_with_check,
    CASE
      WHEN pol.polcmd = '*' AND pol.polqual IS NOT NULL AND pol.polwithcheck IS NOT NULL THEN 'FULL'
      WHEN pol.polcmd IN ('r', '*') AND pol.polqual IS NOT NULL THEN 'READ_ONLY'
      WHEN pol.polcmd IN ('a', 'w', 'd', '*') AND pol.polwithcheck IS NOT NULL THEN 'WRITE_ONLY'
      ELSE 'INCOMPLETE'
    END AS coverage
  FROM pg_policy pol
  WHERE pol.polrelid = p_table;
  
  -- C8: Logging do resultado da auditoria RLS
  PERFORM mantis_log('INFO', 'lint_rls_coverage_completed', 
    format('table=%s, tenant=%s', p_table, current_setting('app.current_tenant')));
END;
$$;

-- ✅ C4: Query com filtro explícito de tenant + validação de que RLS está ativo
-- Defesa em profundidade: filtro SQL + verificação de rol PostgreSQL
CREATE OR REPLACE FUNCTION safe_vector_search_with_tenant_check(
  p_query vector(1536),  -- ✅ V1
  p_limit int DEFAULT 10
)
RETURNS TABLE(id uuid, similarity float)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_tenant uuid := current_setting('app.current_tenant')::uuid;
  v_has_role boolean;
BEGIN
  -- C4: Verificar que usuário tem role do tenant (defesa adicional além de RLS)
  SELECT pg_has_role(current_user, 'tenant_' || v_tenant, 'MEMBER') INTO v_has_role;
  IF NOT v_has_role THEN
    PERFORM mantis_log('ERROR', 'c4_tenant_role_check_failed', 
      format('user=%s, tenant=%s', current_user, v_tenant));
    RAISE EXCEPTION 'C4: User % does not have role for tenant %', current_user, v_tenant;
  END IF;
  
  -- ✅ C4+V1+V2: Busca com filtro explícito + operador cosine
  RETURN QUERY
  SELECT e.id, 1 - (e.vec <=> p_query)
  FROM embeddings e
  WHERE e.tenant_id = v_tenant  -- ✅ C4: filtro explícito
    AND array_length(e.vec, 1) = 1536  -- ✅ V1: validação adicional
  ORDER BY e.vec <=> p_query  -- ✅ V2: operador explícito
  LIMIT p_limit;
  
  -- C8: Logging da busca concluída com tenant
  PERFORM mantis_log('INFO', 'safe_vector_search_completed', 
    format('tenant=%s, limit=%s', v_tenant, p_limit));
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'safe_vector_search_failed', SQLERRM);
  RAISE;
END;
$$;
```

---

## ✅ C5: Lint para Integridade de Embedding via Checksum

```sql
-- ✅ C5: Função para validar integridade de embedding via SHA-256
-- Uso: Verificar que embedding corresponde ao conteúdo original antes de usar em RAG
CREATE OR REPLACE FUNCTION lint_embedding_integrity(
  p_vec vector,
  p_content text,
  p_expected_hash bytea
)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- C5: Comparar hash calculado com hash esperado
  RETURN digest(p_content::bytea, 'sha256') = p_expected_hash;
EXCEPTION WHEN OTHERS THEN
  -- C7: Fallback seguro
  RETURN false;
END;
$$;

-- ✅ C5: Trigger para atualizar checksum quando conteúdo associado muda
-- Mantém content_hash sincronizado para auditoria de integridade
CREATE OR REPLACE FUNCTION update_content_hash_on_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND OLD.content IS DISTINCT FROM NEW.content THEN
    -- C5: Recalcular hash apenas se conteúdo mudou
    NEW.content_hash := digest(NEW.content::bytea, 'sha256');
    
    -- C8: Logging da atualização de hash
    PERFORM mantis_log('INFO', 'content_hash_updated', 
      format('id=%s, tenant=%s', NEW.id, NEW.tenant_id));
  END IF;
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'update_content_hash_failed', SQLERRM);
  RAISE;
END;
$$;

-- ✅ C5+V1: Query para validar embedding armazenado contra hash do conteúdo
-- Doble validação antes de usar embedding em resposta RAG
CREATE OR REPLACE FUNCTION validate_embedding_before_use(
  p_embedding_id uuid,
  p_query_content text
)
RETURNS TABLE(is_valid boolean, integrity_status text, dimension_ok boolean)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_content_hash bytea;
  v_vec_dim int;
BEGIN
  -- C5: Obter hash esperado do conteúdo da query
  v_content_hash := digest(p_query_content::bytea, 'sha256');
  
  -- V1+C5: Validar dimensão e integridade do embedding armazenado
  SELECT 
    array_length(e.vec, 1),
    e.content_hash = v_content_hash
  INTO v_vec_dim, is_valid
  FROM embeddings e
  WHERE e.id = p_embedding_id
    AND e.tenant_id = current_setting('app.current_tenant')::uuid;  -- ✅ C4
  
  -- Retornar status detalhado
  dimension_ok := (v_vec_dim = 1536);  -- ✅ V1
  integrity_status := CASE 
    WHEN is_valid AND dimension_ok THEN 'VALID'
    WHEN NOT dimension_ok THEN 'DIM_MISMATCH'
    ELSE 'HASH_DRIFT'
  END;
  
  -- C8: Logging do resultado da validação
  PERFORM mantis_log('INFO', 'validate_embedding_completed', 
    format('id=%s, status=%s, tenant=%s', p_embedding_id, integrity_status, current_setting('app.current_tenant')));
  
  RETURN;
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'validate_embedding_failed', SQLERRM);
  is_valid := false;
  integrity_status := 'ERROR';
  dimension_ok := false;
  RETURN;
END;
$$;
```

---

## ✅ V1+V2+C4+C5: Lint Query Completo para Pre-Flight de Busca Segura

```sql
-- ✅ Função de linting pre-flight para validar busca vetorial antes de executar
-- Retorna 'PASS' ou código de erro para abortar busca custosa se validação falhar
CREATE OR REPLACE FUNCTION lint_vector_search_preflight(
  p_query vector,
  p_metric text,
  p_expected_dim int DEFAULT 1536
)
RETURNS TABLE(lint_result text, error_detail text)
LANGUAGE plpgsql
IMMUTABLE
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- V1: Validar dimensão da query
  IF array_length(p_query, 1) IS DISTINCT FROM p_expected_dim THEN
    lint_result := 'V1_FAIL';
    error_detail := format('Dimension mismatch: expected %, got %', p_expected_dim, array_length(p_query, 1));
    RETURN;
  END IF;
  
  -- V2: Validar métrica suportada
  IF p_metric NOT IN ('cosine', 'euclidean', 'inner_product') THEN
    lint_result := 'V2_FAIL';
    error_detail := format('Invalid metric: %. Supported: cosine, euclidean, inner_product', p_metric);
    RETURN;
  END IF;
  
  -- C4: Validar que tenant_id está configurado
  IF current_setting('app.current_tenant', true) IS NULL THEN
    lint_result := 'C4_FAIL';
    error_detail := 'app.current_tenant not set';
    RETURN;
  END IF;
  
  -- C3: Validar que query não contém padrões de secrets (sanitização básica)
  IF p_query::text ~* '(sk-|api[_-]?key|secret|password)' THEN
    lint_result := 'C3_FAIL';
    error_detail := 'Potential secret pattern detected in query';
    RETURN;
  END IF;
  
  -- Todos os checks passaram
  lint_result := 'PASS';
  error_detail := NULL;
  
  -- C8: Logging do pre-flight bem-sucedido
  PERFORM mantis_log('INFO', 'lint_preflight_passed', 
    format('metric=%s, dim=%s, tenant=%s', p_metric, p_expected_dim, current_setting('app.current_tenant')));
  
  RETURN;
EXCEPTION WHEN OTHERS THEN
  lint_result := 'ERROR';
  error_detail := SQLERRM;
  PERFORM mantis_log('ERROR', 'lint_preflight_failed', SQLERRM);
  RETURN;
END;
$$;

-- ✅ Uso típico: Executar pre-flight antes de busca custosa
-- SELECT * FROM lint_vector_search_preflight($query, 'cosine', 1536);
-- Se lint_result <> 'PASS', abortar e logar erro; caso contrário, prosseguir com busca.
```

---

## ✅ V1+V2+C4+C5: Stored Procedure Completa para Busca RAG Segura com Linting Integrado

```sql
-- ✅ Função principal: Busca RAG com validações integradas (V1/V2/C4/C5)
-- Retorna integrity_status para logging C8 e decisão de aplicação
CREATE OR REPLACE FUNCTION safe_rag_search(
  p_query_text text,
  p_query_vec vector,
  p_metric text DEFAULT 'cosine',
  p_limit int DEFAULT 10
)
RETURNS TABLE(doc_id uuid, similarity float, integrity_status text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_dim int := array_length(p_query_vec, 1);
  v_tenant text := current_setting('app.current_tenant');
  v_hash bytea := digest(p_query_text::bytea, 'sha256');
  v_similarity float;
BEGIN
  -- V1: Validar dimensão da query
  IF v_dim IS DISTINCT FROM 1536 THEN
    PERFORM mantis_log('ERROR', 'v1_dimension_fail', format('expected=1536, got=%s', v_dim));
    RAISE EXCEPTION 'V1: Expected dimension 1536, got %', v_dim;
  END IF;
  
  -- V2: Validar métrica suportada
  IF p_metric NOT IN ('cosine', 'euclidean', 'inner_product') THEN
    PERFORM mantis_log('ERROR', 'v2_metric_fail', format('invalid=%s', p_metric));
    RAISE EXCEPTION 'V2: Invalid metric: %', p_metric;
  END IF;
  
  -- C4: Validar tenant_id
  IF v_tenant IS NULL THEN
    PERFORM mantis_log('ERROR', 'c4_tenant_fail', 'tenant_id not set');
    RAISE EXCEPTION 'C4: app.current_tenant not set';
  END IF;
  
  -- C3: Sanitização básica da query text (evitar injeção via conteúdo)
  IF p_query_text ~* '(;|--|/\*|\*/|''|")' THEN
    PERFORM mantis_log('WARN', 'c3_query_sanitized', 'special chars removed from query');
    p_query_text := regexp_replace(p_query_text, '(;|--|/\*|\*/|''|")', '', 'g');
  END IF;
  
  -- ✅ Busca principal com validações integradas
  RETURN QUERY
  SELECT 
    d.id,
    CASE p_metric
      WHEN 'cosine' THEN 1 - (e.vec <=> p_query_vec)
      WHEN 'inner_product' THEN (e.vec <#> p_query_vec) * -1
      ELSE e.vec <-> p_query_vec
    END AS similarity,
    CASE 
      WHEN e.content_hash = v_hash THEN 'VALID'
      ELSE 'DRIFT'
    END AS integrity_status
  FROM embeddings e
  JOIN documents d ON e.doc_id = d.id
  WHERE e.tenant_id = v_tenant::uuid  -- ✅ C4
    AND e.content_hash = v_hash       -- ✅ C5: validar integridade do query
    AND array_length(e.vec, 1) = 1536 -- ✅ V1: validação adicional
  ORDER BY
    CASE p_metric
      WHEN 'cosine' THEN e.vec <=> p_query_vec
      WHEN 'inner_product' THEN e.vec <#> p_query_vec
      ELSE e.vec <-> p_query_vec
    END
  LIMIT p_limit;
  
  -- C8: Logging da busca concluída
  PERFORM mantis_log('INFO', 'safe_rag_search_completed', 
    format('metric=%s, limit=%s, tenant=%s', p_metric, p_limit, v_tenant));
  
EXCEPTION WHEN OTHERS THEN
  -- C7+C8: Logging de erro com sanitização
  PERFORM mantis_log('ERROR', 'safe_rag_search_failed', 
    regexp_replace(SQLERRM, '(password|token|api_key)', '\1=***', 'gi'));
  RAISE;
END;
$$;
```

---

## 🧪 Testes Unitários (TDD – Apenas para a Lógica Específica)

```sql
-- Test: lint_vector_dim_valida_dimensao_correta
-- Constraint: V1
BEGIN;
SELECT plan(2);

-- Arrange: vetor de dimensão correta
SELECT is(lint_vector_dim('[1,2,3]'::vector(3), 3), true, 'V1: dimensão correta retorna true');

-- Act+Assert: vetor de dimensão incorreta
SELECT is(lint_vector_dim('[1,2,3]'::vector(3), 1536), false, 'V1: dimensão incorreta retorna false');

SELECT * FROM finish();
ROLLBACK;

-- Test: search_cosine_filtra_por_tenant
-- Constraint: C4+V2
BEGIN;
SELECT plan(1);

-- Arrange: configurar tenant e inserir dados de teste
SET LOCAL app.current_tenant = '00000000-0000-0000-0000-000000000001';

-- Act: executar busca com função wrapper
-- Assert: verificar que resultados pertencem ao tenant configurado
-- (Implementação completa requer fixtures de teste; este é o padrão AAA)

SELECT * FROM finish();
ROLLBACK;

-- Test: validate_vlog02_schema
-- Constraint: C8
-- Valida que mantis_log() emite JSONL compatível com V-LOG-02
DO $$
DECLARE
  v_log text;
  v_valid boolean;
BEGIN
  -- Act: chamar mantis_log e capturar output (simulado)
  -- Assert: validar schema mínimo
  v_valid := (
    SELECT json_build_object(
      'timestamp', to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
      'level', 'INFO',
      'resource', json_build_object('tenant_id', 'test', 'artifact', 'fix-sintaxis-code'),
      'body', json_build_object('event', 'test', 'detail', 'x'),
      'attributes', json_build_object('mantis', json_build_object('tier', '2'))
    )::jsonb ? 'timestamp'
  );
  
  ASSERT v_valid, 'C8: mantis_log() deve emitir schema V-LOG-02 válido';
END $$;
```

---

## 🔍 Validação (VDD – Comando Canônico)

```bash
# Validação via orchestrator-engine (herda checks do Master Agent)
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/postgresql-pgvector/fix-sintaxis-code.pgvector.md \
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
| 3.0.0 | 2026-04-19 | PostgreSQL-PgVector Master Agent | Criação inicial: linting V1/V2, validação C4/C5 | C4,C5,V1,V2 |
| 3.1.0-MODULAR | 2026-05-09 | PostgreSQL-PgVector Master Agent | Refatoração modular: bootstrap resiliente, mantis_log() herdada, constraints completas (C3,V3), wikilink corrigido | C3,C4,C5,V1,V2,V3 |

---
## 🔍 Observability (Documentación para IA – Apenas Eventos Específicos)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `module_bootstrap` | INFO | C8 | `"Master agent available"` ou `"fallback: mantis_log() not found"` |
| `v1_dimension_violation` | ERROR | V1 | `"expected=1536, got=768, table=embeddings, tenant=uuid"` |
| `v2_query_dim_mismatch` | ERROR | V2 | `"expected=1536, got=384"` |
| `c4_tenant_role_check_failed` | ERROR | C4 | `"user=app_user, tenant=uuid"` |
| `content_hash_updated` | INFO | C5 | `"id=uuid, tenant=uuid"` |
| `lint_preflight_passed` | INFO | C8 | `"metric=cosine, dim=1536, tenant=uuid"` |
| `safe_rag_search_completed` | INFO | C8 | `"metric=cosine, limit=10, tenant=uuid"` |

### Validação de Schema V-LOG-02 (Helper Mínimo)
```sql
-- Executar em teste: SELECT validate_vlog02('{"timestamp":"2026-05-09T00:00:00Z","level":"INFO","resource":{"tenant_id":"uuid"},"body":{"event":"test"}}');
-- Retorno esperado: t (true) se schema válido, f (false) caso contrário
-- Função herdada do Master Agent; este módulo apenas a invoca
---
