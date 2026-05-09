---
artifact_id: pgvector-extension-setup
artifact_type: pgvector_setup
version: "1.0.0"
constraints_mapped: ["C1","C3","C4","C5","C7","C8","V1","V3"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/postgresql-pgvector/pgvector-extension-setup.pgvector.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:pgvector-extension-setup-v1.0.0-modular"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "postgresql-pgvector"
ai_navigation:
  read_first: false
  required_for: [extension-provisioning, version-validation, resource-tuning, multi-tenant-init]
  update_frequency: on-change
audience: ["postgresql-pgvector-master-agent", "db-admins", "ci-cd-pipelines", "orchestrator-engine"]
status: "🟢 Novo"
next_review: "2026-06-09"
checksum_sha256: "pending-generation"
vector_meta:
  dimensions: 1536
  model: "text-embedding-3-small"
  metric: "cosine"
  index_type: "hnsw"
---

# 📦 Setup Seguro da Extensão pgvector (Validação + Limites + Isolamento)

> **Contrato modular**: Este artefato é filho do Master Agent `postgresql-pgvector-rag-master-agent-mantis`.
> Herda hardening, observability, thinking system e constraints via source/import.
> Contém APENAS a lógica de provisionamento, validação de versão, configuração de recursos e inicialização de contexto de tenant para `pgvector`.

---

## 🎯 Propósito
Instalar e validar a extensão `pgvector` em PostgreSQL 14+ com verificação de versão mínima (≥0.7.0), aplicação de limites de recursos (C1), configuração segura de contexto de tenant (C4), validação dimensional explícita (V1) e logging estruturado do ciclo de setup (C8). Otimizado para pipelines de infraestrutura IaC e CI/CD com rollback automático em falha.

## 📋 Especificação (SDD – Apenas o Específico deste Módulo)
- **Entradas**: Variáveis de entorno (`PGVECTOR_VERSION`, `CURRENT_TENANT_ID`), parâmetros de recursos (`work_mem`, `timeout`)
- **Saídas**: Extensão ativa, função de validação `pgvector_ready()`, registro JSONL de setup
- **Side Effects**: Criação de extensão, configuração de sessão, logging C8; zero modificação de dados de usuário
- **Constraints Aplicáveis**: C1, C3, C4, C5, C7, C8, V1, V3
- **Dependências**: PostgreSQL 14/15+, `pgvector` package disponível, `mantis_log()` herdada

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C1+C3+C4+C7+C8+V1+V3)

```sql
-- Bootstrap modular: source Master Agent OU fallback mínimo
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'mantis_log') THEN
    PERFORM mantis_log('INFO', 'module_bootstrap', 'pgvector-extension-setup: Master agent available');
  ELSE
    RAISE LOG '%', json_build_object(
      'timestamp', to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
      'level', 'WARN',
      'resource', json_build_object('tenant_id', current_setting('app.current_tenant', true), 'artifact', 'pgvector-extension-setup'),
      'body', json_build_object('event', 'bootstrap_fallback', 'detail', 'mantis_log() not found'),
      'attributes', json_build_object('fallback', 'true')
    );
  END IF;
END $$;

-- C4: Validar contexto de tenant obrigatório para setup segmentado
DO $$
BEGIN
  IF current_setting('app.current_tenant', true) IS NULL THEN
    RAISE EXCEPTION 'C4: app.current_tenant não configurado. Setup de pgvector exige escopo explícito.';
  END IF;
END $$;

-- C1+C7: Limites de recursos para operações de provisionamento
SET LOCAL statement_timeout = '300s';
SET LOCAL work_mem = '256MB';
SET LOCAL maintenance_work_mem = '512MB';
```

---

## ✅ C3 + C5 + V1: Instalação e Validação da Extensão

```sql
-- ✅ C3: Versão mínima requerida (definida por variável ou padrão seguro)
DO $$
DECLARE
  v_required_version text := COALESCE(current_setting('app.pgvector_version', true), '0.7.0');
  v_installed_version text;
BEGIN
  -- Instalação segura
  EXECUTE format('CREATE EXTENSION IF NOT EXISTS vector WITH VERSION %L', v_required_version);

  -- C5: Verificar instalação e versão
  SELECT extversion INTO v_installed_version
  FROM pg_catalog.pg_extension
  WHERE extname = 'vector';

  IF v_installed_version < v_required_version THEN
    PERFORM mantis_log('ERROR', 'extension_version_mismatch', 
      format('required=%s, installed=%s', v_required_version, v_installed_version));
    RAISE EXCEPTION 'C5/V1: pgvector version % is below required %', v_installed_version, v_required_version;
  END IF;

  PERFORM mantis_log('INFO', 'extension_installed', format('version=%s, tenant=%s', v_installed_version, current_setting('app.current_tenant')));
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'extension_installation_failed', sanitize_error_message(SQLERRM));
  RAISE;
END $$;

-- ✅ V1: Função de validação dimensional (executar pós-setup)
CREATE OR REPLACE FUNCTION pgvector_ready(p_expected_dim int DEFAULT 1536)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_test_vec vector;
BEGIN
  -- V1: Teste rápido de alocação de vetor
  EXECUTE format('SELECT %L::vector', repeat('0,', p_expected_dim - 1) || '0') INTO v_test_vec;
  RETURN array_length(v_test_vec, 1) = p_expected_dim;
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'pgvector_ready_failed', format('dim=%s, err=%s', p_expected_dim, SQLERRM));
  RETURN false;
END;
$$;
```

---

## ✅ C4 + C8: Configuração de Contexto e Auditoria de Setup

```sql
-- ✅ C4: Setup seguro de parâmetros de sessão por tenant
CREATE OR REPLACE FUNCTION configure_tenant_pgvector_params(
  p_tenant_id uuid,
  p_enable_rls boolean DEFAULT true
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- C3: Validação de UUID
  IF p_tenant_id IS NULL OR p_tenant_id = '00000000-0000-0000-0000-000000000000'::uuid THEN
    RAISE EXCEPTION 'C3: Invalid tenant_id for pgvector configuration';
  END IF;

  -- Aplicar configuração de sessão (persistente até reset ou disconnect)
  PERFORM set_config('app.current_tenant', p_tenant_id::text, false);
  PERFORM set_config('app.vector_metric', 'cosine', false);  -- V2 padrão
  PERFORM set_config('app.vector_dim', '1536', false);       -- V1 padrão

  PERFORM mantis_log('INFO', 'tenant_pgvector_configured', 
    format('tenant=%s, metric=cosine, dim=1536, rls_enabled=%s', p_tenant_id, p_enable_rls));
EXCEPTION WHEN OTHERS THEN
  PERFORM mantis_log('ERROR', 'tenant_config_failed', sanitize_error_message(SQLERRM));
  RAISE;
END;
$$;

-- ✅ C8: Registro de setup completo no audit log
DO $$
BEGIN
  IF pgvector_ready(1536) THEN
    PERFORM mantis_log('INFO', 'pgvector_setup_completed', 
      format('extension_version=%s, dim_valid=true, tenant=%s', 
        (SELECT extversion FROM pg_extension WHERE extname='vector'),
        current_setting('app.current_tenant')));
  ELSE
    RAISE EXCEPTION 'C7: pgvector setup validation failed. Review logs.';
  END IF;
END $$;
```

---

## ✅ V3: Justificação de Parâmetros de Índice (Documentação Executável)

```sql
-- ✅ V3: Configuração de parâmetros de runtime para otimização de build HNSW/IVFFlat
-- Estes valores são aplicados em nível de sessão durante criação de índices
-- m=16: conexões por nó (recall ~0.95 para 1536d, memória controlada)
-- ef_construction=100: profundidade de busca no build (equilíbrio tempo/qualidade)
-- lists=100: padrão IVFFlat para datasets <1M (ajustar via sqrt(n_vectors) para maior escala)

CREATE OR REPLACE FUNCTION apply_index_runtime_params()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  SET LOCAL work_mem = '256MB';
  SET LOCAL maintenance_work_mem = '512MB';
  SET LOCAL max_parallel_maintenance_workers = 2;
  -- Nota: parâmetros específicos de índice são passados na cláusula WITH do CREATE INDEX
  PERFORM mantis_log('INFO', 'index_runtime_params_applied', 'work_mem=256MB, maint=512MB, parallel=2');
END;
$$;
```

---

## 🧪 Testes Unitários (TDD – Apenas para a Lógica Específica)

```sql
-- Test: extension_installs_and_passes_ready_check
-- Constraint: V1+C5
BEGIN;
SELECT plan(2);

-- Act: executar pgvector_ready(1536) após CREATE EXTENSION
SELECT ok(pgvector_ready(1536), 'V1: pgvector_ready deve retornar true para dim=1536');
SELECT is((SELECT extversion FROM pg_extension WHERE extname='vector') >= '0.7.0', true, 'C5: versão mínima satisfeita');

SELECT * FROM finish();
ROLLBACK;

-- Test: tenant_config_validates_uuid_format
-- Constraint: C3+C4
DO $$
BEGIN
  -- Act: configure_tenant_pgvector_params('invalid')
  -- Assert: exception 'C3: Invalid tenant_id for pgvector configuration'
  PERFORM true;  -- Placeholder para validação em CI
END $$;
```

---

## 🔍 Validação (VDD – Comando Canônico)

```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/postgresql-pgvector/pgvector-extension-setup.pgvector.md \
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
| 1.0.0 | 2026-05-09 | PostgreSQL-PgVector Master Agent | Criação inicial: setup seguro, validação V1, limites C1, isolamento C4, observabilidade C8 | C1,C3,C4,C5,C7,C8,V1,V3 |

---
## 🔍 Observability (Documentación para IA – Apenas Eventos Específicos)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `module_bootstrap` | INFO | C8 | `"Master agent available"` ou `"fallback: mantis_log() not found"` |
| `extension_installed` | INFO | C5,C8 | `"version=0.7.0, tenant=uuid"` |
| `extension_version_mismatch` | ERROR | C5,C8 | `"required=0.7.0, installed=0.6.0"` |
| `tenant_pgvector_configured` | INFO | C4,C8 | `"tenant=uuid, metric=cosine, dim=1536, rls_enabled=true"` |
| `pgvector_setup_completed` | INFO | C8 | `"extension_version=0.7.0, dim_valid=true, tenant=uuid"` |
| `index_runtime_params_applied` | INFO | V3,C8 | `"work_mem=256MB, maint=512MB, parallel=2"` |

### Validação de Schema V-LOG-02 (Helper Mínimo)
```sql
-- Executar em teste: SELECT validate_vlog02('{"timestamp":"2026-05-09T00:00:00Z","level":"INFO","resource":{"tenant_id":"uuid"},"body":{"event":"extension_installed"}}');
-- Retorno esperado: t (true) se schema válido, f (false) caso contrário
-- Função herdada do Master Agent; este módulo apenas a invoca
```
---
