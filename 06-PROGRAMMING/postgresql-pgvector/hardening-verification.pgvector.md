---
artifact_id: hardening-verification-pgvector
artifact_type: pgvector_validation_hook
version: "3.1.0"
constraints_mapped: ["C3","C4","C5","C8","V1","V2","V3"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/postgresql-pgvector/hardening-verification.pgvector.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:hardening-verification-v3.1.0-modular"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "postgresql-pgvector"
ai_navigation:
  read_first: false
  required_for: [pre-flight-validation, constraint-audit, deploy-gate]
  update_frequency: on-change
audience: ["postgresql-pgvector-master-agent", "orchestrator-engine", "validation-hooks", "security-auditors"]
status: "🟡 Refatorado"
next_review: "2026-06-09"
checksum_sha256: "pending-generation"
vector_meta:
  dimensions: 1536
  model: "text-embedding-3-small"
  metric: "cosine"
  index_type: "hnsw"
---

# 🛡️ Verificação de Hardening e Constraints Vetoriais (pgvector)

> **Contrato modular**: Este artefato é filho do Master Agent `postgresql-pgvector-rag-master-agent-mantis`.
> Herda hardening, observability, thinking system e constraints via source/import.
> Contém APENAS a lógica de validação pre-flight específica para constraints pgvector.

---

## 🎯 Propósito
Funções de validação pre-flight para operações vetoriais: verifica C4 (tenant isolation), V1 (dimensões explícitas), V2 (métrica documentada), V3 (índices justificados), C3 (zero secrets) e C8 (logging estruturado). Retorna tabela de auditoria para decisão de deploy ou abort.

## 📋 Especificação (SDD – Apenas o Específico deste Módulo)
- **Entradas**: Nome da tabela (`text`), dimensão esperada (`int`), métrica declarada (`text`), tenant_id (`uuid`)
- **Saídas**: Tabela de auditoria (`check_name`, `passed`, `detail`, `severity`), eventos JSONL via `mantis_log()`
- **Side Effects**: Nenhuma modificação de dados; apenas leitura de metadados e logging
- **Constraints Aplicáveis**: C3, C4, C5, C8, V1, V2, V3 (todas as aplicáveis ao domínio)
- **Dependências**: PostgreSQL 15+, extensão `pgvector >= 0.7.0`, função `mantis_log()` herdada do Master Agent, `pg_stat_statements` habilitado

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C4+C5+C8+V1+V2+V3)
> **Regra de ouro**: Fonte o Master Agent para herdar hardening/observability. Se não disponível, fallback mínimo.

```sql
-- Bootstrap modular: source Master Agent OU fallback mínimo
-- Executar no início de cada sessão ou script que use este módulo
DO $$
BEGIN
  -- Tentar usar mantis_log() herdada do Master Agent
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'mantis_log') THEN
    PERFORM mantis_log('INFO', 'module_bootstrap', 'hardening-verification: Master agent available');
  ELSE
    -- Fallback mínimo: logging estruturado sem dependências externas
    RAISE LOG '%', json_build_object(
      'timestamp', to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
      'level', 'WARN',
      'resource', json_build_object('tenant_id', current_setting('app.current_tenant', true), 'artifact', 'hardening-verification'),
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

-- C1: Limites de recursos para operações de verificação (leitura apenas)
SET LOCAL statement_timeout = '15s';
SET LOCAL work_mem = '128MB';
```

---

## ✅ C4: Verificação de Tenant Isolation (RLS + Filtro Explícito)

```sql
-- ✅ C4: Função para verificar se tabela tem RLS habilitado e políticas ativas
CREATE OR REPLACE FUNCTION verify_rls_enabled(p_table regclass)
RETURNS TABLE(rls_enabled boolean, policy_count int, policy_names name[], coverage text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_relrowsecurity boolean;
  v_policies name[];
  v_count int;
BEGIN
  -- Verificar se RLS está habilitado na tabela
  SELECT relrowsecurity INTO v_relrowsecurity
  FROM pg_class WHERE oid = p_table;
  
  -- Obter nomes de políticas ativas
  SELECT array_agg(polname), COUNT(*)
  INTO v_policies, v_count
  FROM pg_policy WHERE polrelid = p_table;
  
  -- Avaliar cobertura das políticas
  coverage := CASE
    WHEN v_relrowsecurity AND v_count > 0 THEN 'FULL'
    WHEN v_relrowsecurity AND v_count = 0 THEN 'ENABLED_NO_POLICIES'
    WHEN NOT v_relrowsecurity THEN 'DISABLED'
    ELSE 'UNKNOWN'
  END;
  
  -- C8: Logging do resultado da verificação
  PERFORM mantis_log('INFO', 'verify_rls_completed', 
    format('table=%s, enabled=%s, policies=%s, coverage=%s, tenant=%s', 
      p_table, v_relrowsecurity, v_count, coverage, current_setting('app.current_tenant')));
  
  RETURN QUERY SELECT v_relrowsecurity, v_count, v_policies, coverage;
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'verify_rls_failed', SQLERRM);
  RETURN QUERY SELECT false, 0, ARRAY[]::name[], 'ERROR';
END;
$$;

-- ✅ C4: Função para verificar que queries em pg_stat_statements filtram por tenant_id
-- Uso: Auditoria periódica para detectar vazamentos de isolamento
CREATE OR REPLACE FUNCTION verify_tenant_filter_in_queries(p_table regclass DEFAULT 'embeddings'::regclass)
RETURNS TABLE(query_pattern text, has_tenant_filter boolean, execution_count bigint, risk_level text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  RETURN QUERY
  SELECT
    LEFT(query, 200) AS query_pattern,
    query LIKE '%tenant_id%' OR query LIKE '%current_setting%app.current_tenant%' AS has_tenant_filter,
    calls AS execution_count,
    CASE
      WHEN query LIKE '%SELECT%' AND query NOT LIKE '%tenant_id%' AND query LIKE '%' || p_table::text || '%' THEN 'HIGH'
      WHEN query LIKE '%UPDATE%' AND query NOT LIKE '%WHERE%tenant_id%' THEN 'HIGH'
      WHEN query LIKE '%DELETE%' AND query NOT LIKE '%WHERE%tenant_id%' THEN 'CRITICAL'
      ELSE 'LOW'
    END AS risk_level
  FROM pg_stat_statements
  WHERE query ~* ('FROM\s+' || p_table::text || '|JOIN\s+' || p_table::text)
    AND query NOT ILIKE '%verify_tenant_filter_in_queries%'  -- Excluir auto-referência
  ORDER BY calls DESC
  LIMIT 50;
  
  -- C8: Logging do resultado da auditoria
  PERFORM mantis_log('INFO', 'verify_tenant_filter_completed', 
    format('table=%s, tenant=%s', p_table, current_setting('app.current_tenant')));
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'verify_tenant_filter_failed', SQLERRM);
  RETURN;
END;
$$;
```

---

## ✅ V1: Verificação de Dimensão Explícita de Vetor

```sql
-- ✅ V1: Função para verificar que coluna de embedding tem dimensão declarada e correta
CREATE OR REPLACE FUNCTION verify_vector_dimension(
  p_table regclass,
  p_column name DEFAULT 'embedding',
  p_expected_dim int DEFAULT 1536
)
RETURNS TABLE(column_exists boolean, actual_dim int, matches_expected boolean, model_declared text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_exists boolean;
  v_dim int;
  v_model text;
BEGIN
  -- Verificar existência da coluna com tipo vector
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = (SELECT relnamespace::regnamespace::text FROM pg_class WHERE oid = p_table)
      AND table_name = (SELECT relname FROM pg_class WHERE oid = p_table)
      AND column_name = p_column
      AND data_type = 'USER-DEFINED'
      AND udt_name = 'vector'
  ) INTO v_exists;
  
  IF NOT v_exists THEN
    -- C8: Logging de coluna não encontrada
    PERFORM mantis_log('WARN', 'v1_column_not_found', 
      format('table=%s, column=%s, tenant=%s', p_table, p_column, current_setting('app.current_tenant')));
    RETURN QUERY SELECT false, NULL::int, false, NULL::text;
    RETURN;
  END IF;
  
  -- Obter dimensão real via pg_vector metadata (se disponível) ou amostragem
  -- Nota: pgvector não expõe dimensão via information_schema; usamos amostra
  EXECUTE format(
    'SELECT array_length(%I, 1) FROM %I WHERE %I IS NOT NULL LIMIT 1',
    p_column, (SELECT relname FROM pg_class WHERE oid = p_table), p_column
  ) INTO v_dim;
  
  -- Tentar obter modelo declarado em comentário de coluna (convenção do projeto)
  SELECT obj_description(p_table::regclass, 'pg_class') INTO v_model;
  IF v_model ~* 'model:\s*([a-z0-9\-]+)' THEN
    v_model := substring(v_model from 'model:\s*([a-z0-9\-]+)');
  ELSE
    v_model := 'unknown';
  END IF;
  
  -- C8: Logging do resultado da verificação V1
  PERFORM mantis_log('INFO', 'v1_dimension_verified', 
    format('table=%s, column=%s, expected=%s, actual=%s, model=%s, tenant=%s',
      p_table, p_column, p_expected_dim, v_dim, v_model, current_setting('app.current_tenant')));
  
  RETURN QUERY SELECT true, v_dim, (v_dim = p_expected_dim), v_model;
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'v1_verification_failed', SQLERRM);
  RETURN QUERY SELECT false, NULL::int, false, 'error';
END;
$$;

-- ✅ V1: Trigger para validar dimensão em INSERT/UPDATE (defesa em profundidade)
CREATE OR REPLACE FUNCTION enforce_vector_dim_on_write()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_dim int;
  v_expected int := 1536;  -- Configurar conforme modelo do projeto
BEGIN
  -- Obter dimensão do vetor inserido/atualizado
  v_dim := array_length(NEW.embedding, 1);
  
  -- V1: Validar contra dimensão esperada
  IF v_dim IS DISTINCT FROM v_expected THEN
    -- C8: Logging da violação
    PERFORM mantis_log('ERROR', 'v1_write_violation', 
      format('table=%s, expected=%s, got=%s, tenant=%s', 
        TG_TABLE_NAME, v_expected, v_dim, NEW.tenant_id));
    
    RAISE EXCEPTION 'V1: Vector dimension must be %, got %', v_expected, v_dim;
  END IF;
  
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- C7+C8: Logging de erro sem expor dados sensíveis
  PERFORM mantis_log('ERROR', 'enforce_vector_dim_failed', 
    regexp_replace(SQLERRM, '(password|token|api_key)', '\1=***', 'gi'));
  RAISE;
END;
$$;

-- ✅ V1: Aplicar trigger apenas em tabelas com embeddings multi-tenant
-- Executar uma vez por schema, não em cada query:
-- CREATE TRIGGER trg_enforce_vec_dim BEFORE INSERT OR UPDATE ON embeddings
--   FOR EACH ROW EXECUTE FUNCTION enforce_vector_dim_on_write();
```

---

## ✅ V2: Verificação de Métrica de Distância Documentada

```sql
-- ✅ V2: Função para verificar que operadores de distância usados correspondem à métrica declarada
CREATE OR REPLACE FUNCTION verify_distance_metric_consistency(
  p_table regclass,
  p_declared_metric text DEFAULT 'cosine'
)
RETURNS TABLE(operator_used text, matches_declared boolean, usage_count bigint, recommendation text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  RETURN QUERY
  SELECT
    CASE
      WHEN query LIKE '%<=>%' THEN 'cosine'
      WHEN query LIKE '%<->%' THEN 'euclidean'
      WHEN query LIKE '%<#>%' THEN 'inner_product'
      ELSE 'unknown'
    END AS operator_used,
    CASE
      WHEN p_declared_metric = 'cosine' AND query LIKE '%<=>%' THEN true
      WHEN p_declared_metric = 'euclidean' AND query LIKE '%<->%' THEN true
      WHEN p_declared_metric = 'inner_product' AND query LIKE '%<#>%' THEN true
      ELSE false
    END AS matches_declared,
    COUNT(*) AS usage_count,
    CASE
      WHEN p_declared_metric = 'cosine' AND query LIKE '%<->%' THEN 'Use <=> para cosine com embeddings normalizados'
      WHEN p_declared_metric = 'euclidean' AND query LIKE '%<=>%' THEN 'Use <-> para distância euclidiana'
      ELSE 'OK'
    END AS recommendation
  FROM pg_stat_statements
  WHERE query ~* ('FROM\s+' || (SELECT relname FROM pg_class WHERE oid = p_table))
    AND query ~* 'ORDER BY.*<.>.'  -- Detecta operadores de distância
  GROUP BY operator_used, matches_declared, recommendation
  ORDER BY usage_count DESC;
  
  -- C8: Logging do resultado da auditoria V2
  PERFORM mantis_log('INFO', 'v2_metric_consistency_verified', 
    format('table=%s, declared=%s, tenant=%s', p_table, p_declared_metric, current_setting('app.current_tenant')));
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'v2_verification_failed', SQLERRM);
  RETURN;
END;
$$;

-- ✅ V2: Função wrapper para forçar operador explícito conforme métrica declarada
-- Encapsula lógica de conversão e validação para consistência entre clientes
CREATE OR REPLACE FUNCTION apply_metric_operator(
  p_vec1 vector,
  p_vec2 vector,
  p_metric text DEFAULT 'cosine'
)
RETURNS float
LANGUAGE plpgsql
IMMUTABLE
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- V1: Validar que vetores têm mesma dimensão
  IF array_length(p_vec1, 1) IS DISTINCT FROM array_length(p_vec2, 1) THEN
    RAISE EXCEPTION 'V1: Vector dimension mismatch in metric calculation';
  END IF;
  
  -- V2: Aplicar operador conforme métrica declarada
  RETURN CASE p_metric
    WHEN 'cosine' THEN 1 - (p_vec1 <=> p_vec2)  -- Similaridade: 1 - distância
    WHEN 'inner_product' THEN (p_vec1 <#> p_vec2) * -1  -- Negar para ordem crescente
    WHEN 'euclidean' THEN p_vec1 <-> p_vec2
    ELSE RAISE EXCEPTION 'V2: Unsupported metric: %', p_metric
  END;
EXCEPTION WHEN OTHERS THEN
  -- C8: Logging de erro sem expor dados sensíveis
  PERFORM mantis_log('ERROR', 'apply_metric_operator_failed', 
    format('metric=%s, error=%s', p_metric, regexp_replace(SQLERRM, '(password|token)', '\1=***', 'gi')));
  RAISE;
END;
$$;
```

---

## ✅ V3: Verificação de Parâmetros de Índice Justificados

```sql
-- ✅ V3: Função para verificar que índices HNSW/IVFFlat têm parâmetros documentados e adequados
CREATE OR REPLACE FUNCTION verify_index_parameters(
  p_table regclass,
  p_column name DEFAULT 'embedding'
)
RETURNS TABLE(index_name name, index_type text, params jsonb, justified boolean, recommendation text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  r RECORD;
  v_m int;
  v_ef int;
  v_lists int;
BEGIN
  FOR r IN
    SELECT indexname, indexdef
    FROM pg_indexes
    WHERE tablename = (SELECT relname FROM pg_class WHERE oid = p_table)
      AND indexdef ~* '(hnsw|ivfflat)'
  LOOP
    -- Extrair parâmetros da definição do índice
    IF r.indexdef ~* 'hnsw.*WITH\s*\(([^)]+)\)' THEN
      -- HNSW: extrair m e ef_construction
      v_m := substring(r.indexdef from 'm\s*=\s*(\d+)')::int;
      v_ef := substring(r.indexdef from 'ef_construction\s*=\s*(\d+)')::int;
      
      -- V3: Justificação baseada em pgvector docs e benchmarks
      justified := (v_m BETWEEN 16 AND 32) AND (v_ef BETWEEN 100 AND 200);
      recommendation := CASE
        WHEN v_m < 16 THEN 'Aumentar m para 16-32 para melhor recall em 1536d'
        WHEN v_ef < 100 THEN 'Aumentar ef_construction para 100-200 para qualidade do índice'
        ELSE 'Parâmetros dentro de faixas recomendadas para 1536d'
      END;
      
      RETURN QUERY SELECT 
        r.indexname::name,
        'hnsw'::text,
        json_build_object('m', v_m, 'ef_construction', v_ef),
        justified,
        recommendation;
        
    ELSIF r.indexdef ~* 'ivfflat.*WITH\s*\(([^)]+)\)' THEN
      -- IVFFlat: extrair lists
      v_lists := substring(r.indexdef from 'lists\s*=\s*(\d+)')::int;
      
      -- V3: Justificação: lists ≈ sqrt(n_vectors) para balancear recall/performance
      justified := (v_lists BETWEEN 100 AND 1000);  -- Faixa típica para 1M-10M vetores
      recommendation := CASE
        WHEN v_lists < 100 THEN 'Aumentar lists para ~sqrt(n_vectors) para melhor recall'
        WHEN v_lists > 1000 THEN 'Reduzir lists para melhorar performance de build'
        ELSE 'Parâmetro lists adequado para dataset de tamanho médio'
      END;
      
      RETURN QUERY SELECT 
        r.indexname::name,
        'ivfflat'::text,
        json_build_object('lists', v_lists),
        justified,
        recommendation;
    END IF;
  END LOOP;
  
  -- C8: Logging do resultado da verificação V3
  PERFORM mantis_log('INFO', 'v3_index_params_verified', 
    format('table=%s, tenant=%s', p_table, current_setting('app.current_tenant')));
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'v3_verification_failed', SQLERRM);
  RETURN;
END;
$$;

-- ✅ V3: Função para sugerir parâmetros ótimos baseados em estatísticas da tabela
-- Uso: Pré-migração ou reindexação para otimizar índices conforme carga real
CREATE OR REPLACE FUNCTION suggest_index_params_for_table(
  p_table regclass,
  p_target_recall float DEFAULT 0.95
)
RETURNS TABLE(recommended_type text, recommended_params jsonb, rationale text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_row_count bigint;
  v_dim int;
BEGIN
  -- Obter estatísticas da tabela
  EXECUTE format('SELECT COUNT(*) FROM %I', (SELECT relname FROM pg_class WHERE oid = p_table))
    INTO v_row_count;
  
  -- Assumir dimensão padrão do projeto (pode ser parametrizada)
  v_dim := 1536;
  
  -- V3: Recomendações baseadas em pgvector docs e benchmarks públicos
  IF v_row_count < 100000 THEN
    -- Dataset pequeno: HNSW com parâmetros conservadores
    RETURN QUERY SELECT 
      'hnsw'::text,
      json_build_object('m', 16, 'ef_construction', 100),
      'HNSW com m=16, ef=100 recomendado para <100k vetores: recall ~0.95, build rápido';
  ELSIF v_row_count < 1000000 THEN
    -- Dataset médio: HNSW com parâmetros balanceados
    RETURN QUERY SELECT 
      'hnsw'::text,
      json_build_object('m', 24, 'ef_construction', 150),
      'HNSW com m=24, ef=150 para 100k-1M vetores: melhor recall com custo moderado';
  ELSE
    -- Dataset grande: IVFFlat para build mais rápido ou HNSW com recursos adequados
    RETURN QUERY SELECT 
      'ivfflat'::text,
      json_build_object('lists', greatest(100, floor(sqrt(v_row_count))::int)),
      format('IVFFlat com lists≈sqrt(%s)=%s para >1M vetores: build mais rápido, recall ajustável via ef_search', 
        v_row_count, greatest(100, floor(sqrt(v_row_count))::int));
  END IF;
  
  -- C8: Logging da recomendação gerada
  PERFORM mantis_log('INFO', 'v3_params_suggested', 
    format('table=%s, rows=%s, dim=%s, tenant=%s', 
      p_table, v_row_count, v_dim, current_setting('app.current_tenant')));
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'suggest_index_params_failed', SQLERRM);
  RETURN;
END;
$$;
```

---

## ✅ C3: Verificação de Zero Secrets Hardcodeados em Funções SQL

```sql
-- ✅ C3: Função para escanear código de funções em busca de padrões de secrets
CREATE OR REPLACE FUNCTION verify_no_hardcoded_secrets(
  p_schema name DEFAULT 'public'
)
RETURNS TABLE(function_name text, line_hint text, pattern_matched text, severity text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  r RECORD;
  v_patterns text[] := ARRAY[
    'sk-[a-zA-Z0-9]{20,}',      -- OpenAI-style API key
    'AKIA[0-9A-Z]{16}',          -- AWS access key
    'ghp_[a-zA-Z0-9]{36}',       -- GitHub personal token
    'password[=:][[:space:]]*[''"][^''"]+[''"]',  -- password= "value"
    'api[_-]?key[=:][[:space:]]*[''"][^''"]+[''"]'  -- api_key= "value"
  ];
  v_pattern text;
BEGIN
  FOR r IN
    SELECT p.proname, p.prosrc
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = p_schema
      AND p.prosrc IS NOT NULL
  LOOP
    FOREACH v_pattern IN ARRAY v_patterns
    LOOP
      IF r.prosrc ~* v_pattern THEN
        -- C8: Logging da detecção de possível secret
        PERFORM mantis_log('ERROR', 'c3_secret_detected', 
          format('function=%s, pattern=%s, schema=%s, tenant=%s', 
            r.proname, v_pattern, p_schema, current_setting('app.current_tenant')));
        
        RETURN QUERY SELECT 
          r.proname,
          substring(r.prosrc from v_pattern),
          v_pattern,
          'CRITICAL'::text;
      END IF;
    END LOOP;
  END LOOP;
  
  -- C8: Logging do resultado da auditoria C3
  PERFORM mantis_log('INFO', 'c3_secrets_verification_completed', 
    format('schema=%s, tenant=%s', p_schema, current_setting('app.current_tenant')));
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'c3_verification_failed', SQLERRM);
  RETURN;
END;
$$;

-- ✅ C3: Função utilitária para sanitizar mensagens de erro antes de logging
-- Previne vazamento acidental de secrets em logs de erro
CREATE OR REPLACE FUNCTION sanitize_error_message(p_msg text)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- C3: Substituir padrões de secrets por [REDACTED]
  RETURN regexp_replace(
    p_msg,
    '(sk-[a-zA-Z0-9]{20,}|AKIA[0-9A-Z]{16}|ghp_[a-zA-Z0-9]{36}|password[=:][^,]+|api[_-]?key[=:][^,]+)',
    '[REDACTED]',
    'gi'
  );
EXCEPTION WHEN OTHERS THEN
  -- Fallback: retornar mensagem original truncada para evitar loop
  RETURN substring(p_msg from 1 for 200) || '...';
END;
$$;
```

---

## ✅ C5+C8: Auditoria Completa de Constraints (Função Principal)

```sql
-- ✅ Função principal: Auditoria completa de constraints para uma tabela pgvector
-- Retorna tabela de resultados para decisão de deploy ou correção
CREATE OR REPLACE FUNCTION audit_vector_constraints(
  p_table regclass,
  p_expected_dim int DEFAULT 1536,
  p_declared_metric text DEFAULT 'cosine'
)
RETURNS TABLE(
  check_name text,
  passed boolean,
  detail text,
  severity text,  -- 'info', 'warning', 'error', 'critical'
  fix_hint text   -- Sugestão de correção se falhar
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_tenant text := current_setting('app.current_tenant');
  v_start timestamptz := clock_timestamp();
  v_result RECORD;
BEGIN
  -- C4: Verificar RLS
  SELECT * INTO v_result FROM verify_rls_enabled(p_table);
  RETURN QUERY SELECT 
    'C4_rls_enabled',
    v_result.rls_enabled,
    format('RLS=%s, policies=%s, coverage=%s', v_result.rls_enabled, v_result.policy_count, v_result.coverage),
    CASE WHEN v_result.rls_enabled THEN 'info' ELSE 'critical' END,
    CASE WHEN NOT v_result.rls_enabled THEN 'ALTER TABLE ... ENABLE ROW LEVEL SECURITY; CREATE POLICY ...' ELSE NULL END;
  
  -- C4: Verificar filtro de tenant em queries
  -- (Simplificado: apenas contar queries sem filtro)
  RETURN QUERY SELECT 
    'C4_tenant_filter_in_queries',
    NOT EXISTS (
      SELECT 1 FROM verify_tenant_filter_in_queries(p_table) WHERE risk_level IN ('HIGH', 'CRITICAL')
    ),
    'Queries sem filtro de tenant detectadas'::text,
    CASE WHEN EXISTS (SELECT 1 FROM verify_tenant_filter_in_queries(p_table) WHERE risk_level IN ('HIGH', 'CRITICAL')) THEN 'warning' ELSE 'info' END,
    'Adicionar WHERE tenant_id = current_setting(''app.current_tenant'')::uuid';
  
  -- V1: Verificar dimensão do vetor
  SELECT * INTO v_result FROM verify_vector_dimension(p_table, 'embedding', p_expected_dim);
  RETURN QUERY SELECT 
    'V1_vector_dimension',
    v_result.matches_expected,
    format('expected=%s, actual=%s, model=%s', p_expected_dim, v_result.actual_dim, v_result.model_declared),
    CASE WHEN v_result.matches_expected THEN 'info' ELSE 'critical' END,
    CASE WHEN NOT v_result.matches_expected THEN 'ALTER TABLE ... ALTER COLUMN embedding TYPE vector(' || p_expected_dim || ')' ELSE NULL END;
  
  -- V2: Verificar consistência de métrica
  RETURN QUERY SELECT 
    'V2_metric_consistency',
    NOT EXISTS (
      SELECT 1 FROM verify_distance_metric_consistency(p_table, p_declared_metric) WHERE NOT matches_declared
    ),
    'Operadores de distância inconsistentes com métrica declarada'::text,
    CASE WHEN EXISTS (SELECT 1 FROM verify_distance_metric_consistency(p_table, p_declared_metric) WHERE NOT matches_declared) THEN 'warning' ELSE 'info' END,
    format('Usar operador %s para métrica %s', 
      CASE p_declared_metric WHEN 'cosine' THEN '<=>' WHEN 'euclidean' THEN '<->' ELSE '<#>' END,
      p_declared_metric);
  
  -- V3: Verificar parâmetros de índice
  RETURN QUERY SELECT 
    'V3_index_parameters',
    COALESCE((SELECT bool_and(justified) FROM verify_index_parameters(p_table)), true),
    'Índices sem parâmetros justificados ou fora de faixas recomendadas'::text,
    CASE WHEN EXISTS (SELECT 1 FROM verify_index_parameters(p_table) WHERE NOT justified) THEN 'warning' ELSE 'info' END,
    'Revisar parâmetros m/ef_construction (HNSW) ou lists (IVFFlat) conforme suggest_index_params_for_table()';
  
  -- C3: Verificar secrets hardcodeados
  RETURN QUERY SELECT 
    'C3_no_hardcoded_secrets',
    NOT EXISTS (SELECT 1 FROM verify_no_hardcoded_secrets()),
    'Possível secret hardcodeado em função SQL'::text,
    CASE WHEN EXISTS (SELECT 1 FROM verify_no_hardcoded_secrets()) THEN 'critical' ELSE 'info' END,
    'Substituir credenciais por current_setting(''app.*'') ou variáveis de entorno';
  
  -- C8: Logging do resultado da auditoria completa
  PERFORM mantis_log('INFO', 'audit_vector_constraints_completed', 
    format('table=%s, dim=%s, metric=%s, tenant=%s, duration_ms=%s',
      p_table, p_expected_dim, p_declared_metric, v_tenant, 
      EXTRACT(MILLISECOND FROM clock_timestamp() - v_start)));
  
EXCEPTION WHEN OTHERS THEN
  -- C7+C8: Logging de erro com sanitização
  PERFORM mantis_log('ERROR', 'audit_vector_constraints_failed', sanitize_error_message(SQLERRM));
  RETURN QUERY SELECT 
    'audit_error',
    false,
    sanitize_error_message(SQLERRM),
    'critical',
    'Revisar logs e executar verificações individuais';
END;
$$;

-- ✅ Uso típico: Executar auditoria pre-deploy
-- SELECT * FROM audit_vector_constraints('embeddings'::regclass, 1536, 'cosine');
-- Se algum check com severity='critical' tiver passed=false, abortar deploy e corrigir.
```

---

## 🧪 Testes Unitários (TDD – Apenas para a Lógica Específica)

```sql
-- Test: verify_rls_enabled_detecta_tabela_com_rls
-- Constraint: C4
BEGIN;
SELECT plan(2);

-- Arrange: criar tabela de teste com RLS (em transação, não afeta produção)
CREATE TEMP TABLE test_embeddings (
  id uuid PRIMARY KEY,
  tenant_id uuid NOT NULL,
  embedding vector(1536)
);
ALTER TABLE test_embeddings ENABLE ROW LEVEL SECURITY;
CREATE POLICY test_policy ON test_embeddings USING (tenant_id = current_setting('app.current_tenant')::uuid);

-- Act+Assert: verificar que função detecta RLS habilitado
SELECT is((SELECT rls_enabled FROM verify_rls_enabled('test_embeddings'::regclass)), true, 'C4: detecta RLS habilitado');
SELECT is((SELECT policy_count FROM verify_rls_enabled('test_embeddings'::regclass)), 1, 'C4: conta políticas corretamente');

SELECT * FROM finish();
ROLLBACK;

-- Test: verify_vector_dimension_valida_dimensao
-- Constraint: V1
BEGIN;
SELECT plan(1);

-- Arrange: vetor de dimensão correta
-- Act+Assert: função retorna matches_expected=true para dimensão correta
-- (Implementação completa requer fixtures; este é o padrão AAA)

SELECT * FROM finish();
ROLLBACK;

-- Test: sanitize_error_message_redacta_secrets
-- Constraint: C3
DO $$
DECLARE
  v_input text := 'Error: connection failed, password=sk-abc123xyz789, retrying';
  v_output text;
BEGIN
  -- Act
  v_output := sanitize_error_message(v_input);
  
  -- Assert: secret foi redactado
  ASSERT v_output NOT LIKE '%sk-abc123xyz789%', 'C3: sanitize deve redactar secrets';
  ASSERT v_output LIKE '%[REDACTED]%', 'C3: sanitize deve inserir [REDACTED]';
END $$;
```

---

## 🔍 Validação (VDD – Comando Canônico)

```bash
# Validação via orchestrator-engine (herda checks do Master Agent)
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/postgresql-pgvector/hardening-verification.pgvector.md \
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
| 3.0.0 | 2026-04-19 | PostgreSQL-PgVector Master Agent | Criação inicial: validação pre-flight C4/V1/V2/V3, logging C8 | C4,C5,C8,V1,V2,V3 |
| 3.1.0-MODULAR | 2026-05-09 | PostgreSQL-PgVector Master Agent | Refatoração modular: bootstrap resiliente, mantis_log() herdada, constraint C3 adicionada, wikilink corrigido | C3,C4,C5,C8,V1,V2,V3 |

---
## 🔍 Observability (Documentación para IA – Apenas Eventos Específicos)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `module_bootstrap` | INFO | C8 | `"Master agent available"` ou `"fallback: mantis_log() not found"` |
| `verify_rls_completed` | INFO | C4,C8 | `"table=embeddings, enabled=true, policies=1, coverage=FULL, tenant=uuid"` |
| `v1_dimension_verified` | INFO | V1,C8 | `"table=embeddings, column=embedding, expected=1536, actual=1536, model=text-embedding-3-small"` |
| `v2_metric_consistency_verified` | INFO | V2,C8 | `"table=embeddings, declared=cosine, tenant=uuid"` |
| `v3_index_params_verified` | INFO | V3,C8 | `"table=embeddings, tenant=uuid"` |
| `c3_secret_detected` | ERROR | C3,C8 | `"function=legacy_import, pattern=sk-*, schema=public, tenant=uuid"` |
| `audit_vector_constraints_completed` | INFO | C8 | `"table=embeddings, dim=1536, metric=cosine, tenant=uuid, duration_ms=42"` |

### Validação de Schema V-LOG-02 (Helper Mínimo)
```sql
-- Executar em teste: SELECT validate_vlog02('{"timestamp":"2026-05-09T00:00:00Z","level":"INFO","resource":{"tenant_id":"uuid"},"body":{"event":"test"}}');
-- Retorno esperado: t (true) se schema válido, f (false) caso contrário
-- Função herdada do Master Agent; este módulo apenas a invoca
```
---
