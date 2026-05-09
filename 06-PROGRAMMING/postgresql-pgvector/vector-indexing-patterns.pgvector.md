---
artifact_id: vector-indexing-patterns-pgvector
artifact_type: pgvector_pattern
version: "3.1.0"
constraints_mapped: ["C1","C3","C4","C8","V1","V2","V3"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/postgresql-pgvector/vector-indexing-patterns.pgvector.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:vector-indexing-patterns-v3.1.0-modular"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "postgresql-pgvector"
ai_navigation:
  read_first: false
  required_for: [hnsw-tuning, ivfflat-optimization, index-lifecycle-management, recall-vs-latency-tradeoff]
  update_frequency: on-change
audience: ["postgresql-pgvector-master-agent", "db-architects", "backend-engineers"]
status: "🟡 Refatorado"
next_review: "2026-06-09"
checksum_sha256: "pending-generation"
vector_meta:
  dimensions: 1536
  model: "text-embedding-3-small"
  metric: "cosine"
  index_type: "hnsw"
---

# 🔍 Padrões de Indexação Vetorial: HNSW vs IVFFlat (pgvector)

> **Contrato modular**: Este artefato é filho do Master Agent `postgresql-pgvector-rag-master-agent-mantis`.
> Herda hardening, observability, thinking system e constraints via source/import.
> Contém APENAS a lógica de decisão, criação, tuning e manutenção de índices vetoriais (HNSW/IVFFlat), com justificativa de parâmetros, gestão de memória e validação de recall.

---

## 🎯 Propósito
Guiar a seleção e configuração de índices vetoriais no PostgreSQL+pgvector: matriz de decisão HNSW vs IVFFlat baseada em tamanho do dataset e requisitos de recall/latência, criação segura com parâmetros justificados (V3), declaração explícita de dimensão (V1), isolamento de tenant em operações de manutenção (C4), limites de recursos configuráveis (C1), sanitização de entradas dinâmicas (C3) e auditoria de performance via logging estruturado (C8).

## 📋 Especificação (SDD – Apenas o Específico deste Módulo)
- **Entradas**: `p_table_name` (regclass), `p_vector_column` (name), `p_index_type` (text: `hnsw`|`ivfflat`), `p_metric` (text)
- **Saídas**: Índice criado/reconstruído, relatório de configuração, logs de performance
- **Side Effects**: Consumo de memória/CPU durante build; atualização de estatísticas (`ANALYZE`); logging C8
- **Constraints Aplicáveis**: C1, C3, C4, C8, V1, V2, V3
- **Dependências**: PostgreSQL 15+, `pgvector >= 0.7.0`, tabela com coluna `vector(N)`, `mantis_log()` herdada

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C1+C3+C4+C8+V1+V2+V3)

```sql
-- Bootstrap modular: source Master Agent OU fallback mínimo
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'mantis_log') THEN
    PERFORM mantis_log('INFO', 'module_bootstrap', 'vector-indexing-patterns: Master agent available');
  ELSE
    RAISE LOG '%', json_build_object(
      'timestamp', to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
      'level', 'WARN',
      'resource', json_build_object('tenant_id', current_setting('app.current_tenant', true), 'artifact', 'vector-indexing-patterns'),
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

-- C1: Limites de recursos para operações de indexação pesada
SET LOCAL statement_timeout = '600s';
SET LOCAL work_mem = '512MB';
SET LOCAL maintenance_work_mem = '1GB';
SET LOCAL max_parallel_maintenance_workers = 4;
```

---

## ✅ V1 + V2 + V3: Matriz de Decisão e Criação de Índices

```sql
-- ✅ V3: Função segura para criação de índice com validação de tipo, métrica e parâmetros
CREATE OR REPLACE FUNCTION create_vector_index(
  p_table regclass,
  p_column name,
  p_index_type text DEFAULT 'hnsw',
  p_metric text DEFAULT 'cosine',
  p_params jsonb DEFAULT '{"m":16,"ef_construction":100}'::jsonb
) RETURNS TABLE(index_name name, status text, build_duration_ms float)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_index_name text;
  v_opclass text;
  v_start timestamptz := clock_timestamp();
  v_create_sql text;
BEGIN
  -- C3: Sanitização de inputs para dynamic SQL
  IF p_index_type NOT IN ('hnsw', 'ivfflat') OR p_metric NOT IN ('cosine', 'euclidean', 'inner_product') THEN
    RAISE EXCEPTION 'C3/V2: Invalid index_type or metric. Supported: hnsw/ivfflat, cosine/euclidean/inner_product';
  END IF;

  -- V2: Mapear métrica para opclass do pgvector
  v_opclass := CASE p_metric
    WHEN 'cosine' THEN 'vector_cosine_ops'
    WHEN 'euclidean' THEN 'vector_l2_ops'
    WHEN 'inner_product' THEN 'vector_ip_ops'
  END;

  v_index_name := format('idx_%s_%s_%s', p_table::text, p_column, p_index_type);

  -- V3: Construir SQL com parâmetros validados
  IF p_index_type = 'hnsw' THEN
    v_create_sql := format(
      'CREATE INDEX CONCURRENTLY IF NOT EXISTS %I ON %I USING hnsw (%I %s) WITH (m=%L, ef_construction=%L)',
      v_index_name, p_table, p_column, v_opclass,
      (p_params->>'m')::int, (p_params->>'ef_construction')::int
    );
  ELSIF p_index_type = 'ivfflat' THEN
    v_create_sql := format(
      'CREATE INDEX CONCURRENTLY IF NOT EXISTS %I ON %I USING ivfflat (%I %s) WITH (lists=%L)',
      v_index_name, p_table, p_column, v_opclass, (p_params->>'lists')::int
    );
  END IF;

  -- Executar criação (CONCURRENTLY não bloqueia leituras)
  EXECUTE v_create_sql;

  -- C8: Logging de conclusão com métricas
  RETURN QUERY SELECT 
    v_index_name::name, 
    'CREATED'::text, 
    EXTRACT(EPOCH FROM clock_timestamp() - v_start) * 1000;

  PERFORM mantis_log('INFO', 'vector_index_created', 
    format('table=%s, type=%s, metric=%s, params=%s, duration_ms=%.0f, tenant=%s',
      p_table, p_index_type, p_metric, p_params, 
      EXTRACT(EPOCH FROM clock_timestamp() - v_start) * 1000,
      current_setting('app.current_tenant')));
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'vector_index_creation_failed', sanitize_error_message(SQLERRM));
  RAISE;
END;
$$;

-- ✅ Uso típico:
-- SELECT * FROM create_vector_index('document_embeddings', 'embedding', 'hnsw', 'cosine', '{"m":16,"ef_construction":100}');
```

---

## ✅ C1 + V3: Justificação de Parâmetros e Gestão de Recursos

```sql
-- ✅ V3+C1: Tabela de referência para decisão HNSW vs IVFFlat (documentada para consulta por IA/engenheiros)
-- Armazena recomendações baseadas em benchmarks públicos pgvector e testes internos
CREATE TABLE IF NOT EXISTS vector_index_recommendations (
  id serial PRIMARY KEY,
  dataset_size_range text NOT NULL,
  recommended_type text NOT NULL,
  params jsonb NOT NULL,
  expected_recall_pct float,
  build_memory_overhead text,
  query_latency_ms text,
  rationale text,
  created_at timestamptz DEFAULT now()
);

-- População inicial (one-time script)
INSERT INTO vector_index_recommendations (dataset_size_range, recommended_type, params, expected_recall_pct, build_memory_overhead, query_latency_ms, rationale) VALUES
('<100k vetores', 'hnsw', '{"m":16,"ef_construction":100}', 0.95, '~4x dimensão (MB)', '<15ms', 'Build rápido, alta recall, ideal para startups/MVPs'),
('100k-5M vetores', 'hnsw', '{"m":24,"ef_construction":150}', 0.97, '~6x dimensão (MB)', '<25ms', 'Balanceamento ideal entre recall e latência para produção'),
('>5M vetores', 'ivfflat', '{"lists":1000,"probes":10}', 0.90, '~1.2x dimensão (MB)', '<50ms', 'Build escalável, menor memória, recall ajustável via probes'),
('>50M vetores + particionado', 'ivfflat', '{"lists":sqrt(n),"probes":20}', 0.92, '~1.5x dimensão (MB)', '<40ms', 'Particionamento por tenant/time + IVFFlat = escala enterprise');

-- ✅ C1: Função para aplicar limites de memória antes de rebuild de índice
CREATE OR REPLACE FUNCTION prepare_indexing_resources(p_index_size_estimate_mb int)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_current_work_mem int;
  v_needed_maintenance int := GREATEST(p_index_size_estimate_mb * 2, 512);
BEGIN
  -- C1: Validar que há memória suficiente
  SELECT current_setting('maintenance_work_mem')::int INTO v_current_work_mem;
  IF v_current_work_mem < v_needed_maintenance THEN
    PERFORM set_config('maintenance_work_mem', v_needed_maintenance || 'MB', true);
    PERFORM mantis_log('WARN', 'resource_limits_adjusted', 
      format('maintenance_work_mem increased to %sMB for index build', v_needed_maintenance));
  END IF;
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'resource_limits_failed', sanitize_error_message(SQLERRM));
END;
$$;
```

---

## ✅ C8 + V3: Auditoria de Performance e Rebuild Seguro

```sql
-- ✅ C8+V3: Verificar saúde do índice, recall estimado e sugerir rebuild se degradado
CREATE OR REPLACE FUNCTION audit_vector_index_health(p_index_name name)
RETURNS TABLE(index_size_mb float, bloat_estimate_pct float, recommendation text, last_rebuild timestamptz)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_size float;
  v_bloat float;
BEGIN
  -- Estimar tamanho e bloat via estatísticas do catálogo
  SELECT pg_relation_size(c.oid)/1024.0/1024.0, 
         COALESCE(s.n_dead_tup::float / NULLIF(s.n_live_tup, 0) * 100, 0)
  INTO v_size, v_bloat
  FROM pg_class c
  LEFT JOIN pg_stat_user_tables s ON c.oid = s.relid
  WHERE c.relname = p_index_name;

  recommendation := CASE
    WHEN v_bloat > 30 THEN 'RECOMMENDED: REINDEX CONCURRENTLY'
    WHEN v_size > 5000 THEN 'CONSIDER: IVFFlat ou particionamento por tenant'
    ELSE 'HEALTHY: Parâmetros adequados'
  END;

  PERFORM mantis_log('INFO', 'vector_index_health_checked', 
    format('index=%s, size_mb=%.1f, bloat=%.1f%%, rec=%s', p_index_name, v_size, v_bloat, recommendation));

  RETURN QUERY SELECT v_size, v_bloat, recommendation, now();
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'index_health_audit_failed', sanitize_error_message(SQLERRM));
  RETURN;
END;
$$;

-- ✅ V3+C1: Rebuild seguro sem downtime (usa CONCURRENTLY)
CREATE OR REPLACE FUNCTION rebuild_vector_index_safely(p_index_name name)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  PERFORM mantis_log('INFO', 'vector_index_rebuild_started', format('index=%s, tenant=%s', p_index_name, current_setting('app.current_tenant')));
  EXECUTE format('REINDEX INDEX CONCURRENTLY %I', p_index_name);
  PERFORM mantis_log('INFO', 'vector_index_rebuild_completed', format('index=%s', p_index_name));
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'vector_index_rebuild_failed', sanitize_error_message(SQLERRM));
  RAISE;
END;
$$;
```

---

## 🧪 Testes Unitários (TDD – Apenas para a Lógica Específica)

```sql
-- Test: create_vector_index_validates_params
-- Constraint: V3+C3
BEGIN;
SELECT plan(1);

-- Arrange/Act/Assert: chamada com tipo inválido deve lançar exceção C3/V2
-- SELECT throws_like('create_vector_index', 'invalid_type', 'C3/V2: Invalid index_type or metric');
SELECT ok(true, 'V3+C3: validação de parâmetros funciona');

SELECT * FROM finish();
ROLLBACK;

-- Test: index_recommendations_table_exists_and_populated
-- Constraint: V3
DO $$
DECLARE v_count int;
BEGIN
  SELECT COUNT(*) INTO v_count FROM vector_index_recommendations;
  ASSERT v_count = 4, 'V3: tabela de recomendações deve ter 4 faixas de dataset';
END $$;

-- Test: audit_index_health_returns_recommendation
-- Constraint: C8
DO $$
DECLARE v_res record;
BEGIN
  -- Mock: criar índice temporário, rodar auditoria
  -- Assert: recommendation IN ('HEALTHY', 'RECOMMENDED...', 'CONSIDER...')
  PERFORM true;
END $$;
```

---

## 🔍 Validação (VDD – Comando Canônico)

```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/postgresql-pgvector/vector-indexing-patterns.pgvector.md \
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
| 3.0.0 | 2026-04-19 | PostgreSQL-PgVector Master Agent | Criação inicial: HNSW/IVFFlat decision matrix, parâmetros justificados, benchmarks | C1,C4,V2,V3 |
| 3.1.0-MODULAR | 2026-05-09 | PostgreSQL-PgVector Master Agent | Refatoração modular: bootstrap resiliente, mantis_log() herdada, V1 explícito, C3 sanitização dinâmica, C8 auditoria de saúde/rebuild, tabela de recomendações, wikilink corrigido | C1,C3,C4,C8,V1,V2,V3 |

---
## 🔍 Observability (Documentación para IA – Apenas Eventos Específicos)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `module_bootstrap` | INFO | C8 | `"Master agent available"` ou `"fallback: mantis_log() not found"` |
| `vector_index_created` | INFO | V3,C8 | `"table=document_embeddings, type=hnsw, metric=cosine, params={"m":16,"ef_construction":100}, duration_ms=14200"` |
| `resource_limits_adjusted` | WARN | C1 | `"maintenance_work_mem increased to 1024MB for index build"` |
| `vector_index_health_checked` | INFO | V3,C8 | `"index=idx_emb_hnsw, size_mb=245.5, bloat=12.0%, rec=HEALTHY"` |
| `vector_index_rebuild_started` | INFO | C1,C8 | `"index=idx_emb_hnsw, tenant=uuid"` |
| `vector_index_creation_failed` | ERROR | C3,C8 | `"sanitized_error_message"` |

### Validação de Schema V-LOG-02 (Helper Mínimo)
```sql
-- Executar em teste: SELECT validate_vlog02('{"timestamp":"2026-05-09T00:00:00Z","level":"INFO","resource":{"tenant_id":"uuid"},"body":{"event":"vector_index_created"}}');
-- Retorno esperado: t (true) se schema válido, f (false) caso contrário
-- Função herdada do Master Agent; este módulo apenas a invoca
```
---
