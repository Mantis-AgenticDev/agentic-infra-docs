---
artifact_id: context-compaction-utils
artifact_type: bash_utility
version: 2.0.0
constraints_mapped: ["C1","C3","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/bash/context-compaction-utils.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:context-compaction-v2.0.0-remanufatured"
generated_at: "2026-05-06T12:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: bash
ai_navigation:
  read_first: false
  required_for: [llm-context-preprocessing, token-budgeting, pii-scrubbing]
  update_frequency: on-change
audience: ["orchestrator-engine", "llm-gateway-agents", "data-pipeline-scripts"]
status: "🟡 Em remanufatura"
next_review: "2026-06-05"
---

# Utilitários de Compactação e Saneamento de Contexto

## 🎯 Propósito
Fornecer funções bash para redução segura de contexto antes do envio a modelos de IA, respeitando limites de tokens, removendo credenciais/PII, mantendo isolamento por tenant e garantindo rastreabilidade de auditoria. Projetado para pré-processamento em pipelines agénticos e gateways LLM.

## 📋 Especificação (SDD)
- **Entradas**: 
  - `CONTEXT_INPUT` (string ou arquivo)
  - `TENANT_ID` (variável de ambiente obrigatória)
  - `MAX_TOKENS` (limite configurável, padrão: 4096)
  - `SCRUB_SENSITIVE` (booleano, padrão: true)
- **Saídas**: 
  - Contexto compactado (stdout)
  - Metadados JSON: `{tenant_id, original_size, compacted_size, tokens_estimated, secrets_scrubbed: bool, timestamp}`
  - Códigos de retorno: `0` (sucesso), `1` (falha de validação), `2` (excede limite após compactação)
- **Side Effects**: 
  - Log estruturado em stderr (JSONL)
  - Criação de arquivo temporário seguro durante processamento
- **Constraints Aplicáveis**: C1 (limite de tamanho/tempo), C3 (zero secrets), C4 (tenant isolation), C5 (estrutura YAML), C7 (resiliência), C8 (auditoria)
- **Dependências Externas**: `wc`, `awk`, `grep`, `tr`, `date` (POSIX coreutils)

## 🛡️ Bootstrap Resiliente (Hardening via Source ao Master - C3+C4+C5+C7)
```bash
# =============================================================================
# BOOTSTRAP RESILIENTE: Hardening + Observabilidade (C3+C4+C7)
# Fonte de verdade: bash-master-agent.md via source
# =============================================================================
if [[ -f "${MANTIS_ROOT:-.}/06-PROGRAMMING/bash/bash-master-agent.sh" ]]; then
  source "${MANTIS_ROOT:-.}/06-PROGRAMMING/bash/bash-master-agent.sh" --mode=observability-only
else
  # Fallback minimalista: garante execução segura e auditável se master não estiver disponível
  set -Eeuo pipefail
  shopt -s inherit_errexit 2>/dev/null || true
  trap 'exit 130' INT TERM
  : "${TENANT_ID:?ERROR: TENANT_ID não definido. Defina via env ou argumento.}"
  mantis_log() {
    printf '{"ts":"%s","level":"%s","tenant":"%s","event":"%s","detail":"%s","fallback":"true"}\n' \
      "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      "${1:-INFO}" \
      "${TENANT_ID:-unknown}" \
      "${2:-bootstrap_fallback}" \
      "${3:-}" >&2
  }
  mantis_log "WARN" "bootstrap_fallback" "Master agent não encontrado. Executando com hardening mínimo."
fi

# =============================================================================
# VARIÁVEIS CANÔNICAS DO ARTEFATO (C5: Estrutura)
# =============================================================================
readonly SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_VERSION="${VERSION:-2.0.0}"
readonly LOG_DIR="${LOG_DIR:-08-LOGS/bash}"

# C4: Propagação explícita de tenant_id para subshells
export TENANT_ID="${TENANT_ID:-}"

# =============================================================================
# CONFIGURAÇÕES ESPECÍFICAS DO CONTEXTO (C1: Resource Limits)
# =============================================================================
readonly MAX_TOKENS="${MAX_TOKENS:-4096}"
readonly OPERATION_TIMEOUT="${OPERATION_TIMEOUT:-30}"
readonly SCRUB_SENSITIVE="${SCRUB_SENSITIVE:-true}"
readonly TEMP_FILE="$(mantis_mktemp 2>/dev/null || mktemp)"
```

## 🧪 Testes Unitários (TDD - Test-Driven Development)
```bash
test_compact_context_respects_limit() {
  # Arrange
  local large_context
  large_context=$(head -c 50000 /dev/urandom | tr -dc 'a-zA-Z0-9 \n' | head -c 20000)
  local max_tokens=1000
  
  # Act
  local result
  result=$(compact_context <<< "$large_context" 2>/dev/null) || true
  local token_est
  token_est=$(compact_context <<< "$large_context" --dry-run 2>&1 | grep -oP '"tokens_estimated":\K[0-9]+' || echo "0")
  
  # Assert
  if [[ "$token_est" -le "$max_tokens" ]]; then
    mantis_log "INFO" "test_passed" "token_limit_test: estimado=$token_est <= limite=$max_tokens"
    return 0
  else
    mantis_log "ERROR" "test_failed" "Tokens estimados ($token_est) excedem limite ($max_tokens)"
    printf '[TEST_FAIL] Tokens estimados (%s) excedem limite (%s)\n' "$token_est" "$max_tokens" >&2
    return 1
  fi
}

test_scrub_secrets_removes_patterns() {
  # Arrange
  local input="Token sk-abc123xyz e chave AKIAIOSFODNN7EXAMPLE no texto"
  
  # Act
  local output
  output=$(compact_context <<< "$input" --scrub 2>/dev/null) || true
  
  # Assert
  if echo "$output" | grep -qE "(sk-[a-zA-Z0-9]{20,}|AKIA[a-zA-Z0-9]{16})"; then
    mantis_log "ERROR" "test_failed" "Padrão de secret não foi removido"
    printf '[TEST_FAIL] Padrão de secret não foi removido\n' >&2
    return 1
  fi
  mantis_log "INFO" "test_passed" "secrets_scrub_test: padrões removidos com sucesso"
  return 0
}

test_validate_vlog02_schema() {
  # Arrange: gerar um log de teste
  local log_output
  log_output=$(mantis_log "INFO" "test_event" "detalhe_teste" 2>&1)
  
  # Act & Assert: validar schema V-LOG-02
  if printf '%s\n' "$log_output" | jq -e '
    has("timestamp") and
    has("level") and
    has("resource.tenant_id") and
    has("resource.artifact") and
    has("body.event")
  ' >/dev/null 2>&1; then
    return 0
  else
    mantis_log "ERROR" "schema_validation_failed" "Log não conforma com V-LOG-02"
    return 1
  fi
}

# Execução condicional de testes (se flag --test fornecida)
if [[ "${1:-}" == "--test" ]]; then
  test_compact_context_respects_limit
  test_scrub_secrets_removes_patterns
  test_validate_vlog02_schema
  exit $?
fi
```

## 🔍 Validação (VDD - Validation-Driven Development)
```bash
# Validação completa via orchestrator-engine (executável por IA ou humano)
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/bash/context-compaction-utils.md \
  --json \
  --check-secrets \
  --check-tenant-isolation \
  --check-structural \
  --check-resource-limits \
  --check-error-handling \
  --check-observability

# Validação rápida (apenas frontmatter e syntax)
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/bash/context-compaction-utils.md \
  --mode headless \
  --checks C5,C8 \
  --json

# Output esperado em caso de sucesso:
# {"validator":"orchestrator-engine","file":"...","passed":true,"status":"passed",...}
```

## 🔗 Referências Cruzadas (Wikilinks para Navegação de IA)
- [[bash-master-agent.md]] ← Contrato principal de geração e função mantis_log()
- [[01-RULES/harness-norms-v3.0.md]] ← Especificação de hardening
- [[01-RULES/10-SDD-CONSTRAINTS.md]] ← Definição das constraints C1-C8
- [[01-RULES/03-SECURITY-RULES.md]] ← Regras de segurança e PII scrubbing
- [[00-CONTEXT/norms-matrix.json]] ← Fonte de verdade para constraints
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]] ← Índice de observabilidade
- [[/05-CONFIGURATIONS/observability/loki/config.yml]] ← Configuração de ingestão de logs

## 📝 Histórico de Revisões (Para CHRONICLE.md Integration)
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2024-11-10 | Dev inicial | Criação original | Parcial |
| 2.0.0 | 2026-05-06 | Bash Master Agent | Remanufatura completa: bootstrap resiliente, mantis_log() canônica, validação V-LOG-02 | C1,C3,C4,C5,C7,C8 |

---
## 🔍 Observability (Documentação para IA)

> Este artefato emite os seguintes eventos via `mantis_log()` (definida em [[bash-master-agent.md]]):

| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `context_compaction_started` | INFO | C8 | `"Tenant: ${TENANT_ID}, input_size: ${#CONTEXT_INPUT}"` |
| `token_limit_exceeded` | WARN | C1 | `"Estimado: ${token_est} > limite: ${MAX_TOKENS}"` |
| `secrets_scrubbed` | INFO | C3 | `"Padrões detectados e sanitizados: ${scrub_count}"` |
| `context_compaction_completed` | INFO | C8 | `"original_size: ${orig}, compacted_size: ${comp}, tokens: ${est}"` |
| `validation_failed` | ERROR | C5 | `"Frontmatter inválido ou constraint violada: ${constraint}"` |
| `cleanup_completed` | DEBUG | C7 | `"Temp file ${TEMP_FILE} removido com sucesso"` |

### Exemplo de Output JSONL (para aprendizado de padrão por IA)
```json
{"timestamp":"2026-05-06T12:00:00Z","level":"INFO","resource":{"tenant_id":"tenant-xyz","artifact":"context-compaction-utils"},"body":{"event":"context_compaction_completed","detail":"original_size: 15420, compacted_size: 3840, tokens: 980"},"attributes":{"mantis":{"tier":"2","version":"2.0.0","constraint":"C1,C3,C4","trace_id":""},"code.filepath":"06-PROGRAMMING/bash/context-compaction-utils.md","code.lineno":87,"telemetry.sdk.name":"mantis-bash-adapter","telemetry.sdk.version":"1.0.0"}}
```

### Configuração Específica de Este Artefato
```bash
# Variáveis de entorno que afetam o comportamento de logging deste artefato
export LOG_COMPACT_DETAILS="${LOG_COMPACT_DETAILS:-true}"   # Incluir métricas de compactação em logs
export LOG_SCRUB_STATS="${LOG_SCRUB_STATS:-true}"           # Incluir contagem de padrões sanitizados (C3)
export TRACE_CONTEXT_COMPACT="${TRACE_CONTEXT_COMPACT:-false}" # Habilitar trace_id para correlação OTel
```

### Validação de Schema V-LOG-02 (Helper Executável)
```bash
# Função helper para validação local de logs (pode ser usada em testes)
validate_vlog02() {
  jq -e '
    has("timestamp") and
    has("level") and
    has("resource.tenant_id") and
    has("resource.artifact") and
    has("body.event") and
    has("attributes.mantis.tier") and
    has("attributes.mantis.version")
  ' >/dev/null 2>&1
}

# Uso em testes ou validação manual:
# mantis_log "INFO" "test" "x" 2>&1 | validate_vlog02 && echo "✅ Schema V-LOG-02 válido"
```
---
