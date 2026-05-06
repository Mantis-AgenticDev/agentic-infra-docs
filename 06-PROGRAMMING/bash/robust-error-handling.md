---
artifact_id: robust-error-handling
artifact_type: bash_utility
version: 2.0.0
constraints_mapped: ["C1","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/bash/robust-error-handling.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:robust-error-handling-v2.0.0-remanufatured"
generated_at: "2026-05-06T12:15:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: bash
ai_navigation:
  read_first: false
  required_for: [resilient-pipelines, retry-orchestration, fault-tolerant-scripts]
  update_frequency: on-change
audience: ["orchestrator-engine", "ci-cd-pipelines", "data-ingestion-agents"]
status: "🟡 Em remanufatura"
next_review: "2026-06-05"
---

# Tratamento Robusto de Erros e Retry com Backoff Exponencial

## 🎯 Propósito
Fornecer funções reutilizáveis para captura estruturada de falhas, retry com backoff exponencial e degradação graciosa em scripts Bash. Garante que erros transitórios (rede, I/O, lock de recursos) sejam tratados sem interrupção catastrófica, respeitando limites de tempo, mantendo isolamento por tenant e registrando cada tentativa para auditoria forense.

## 📋 Especificação (SDD)
- **Entradas**: 
  - `TENANT_ID` (obrigatório)
  - `MAX_RETRIES` (padrão: `3`)
  - `BASE_DELAY_SEC` (padrão: `2`)
  - `COMMAND_OR_FUNCTION` (string ou referência a função)
- **Saídas**: 
  - `0` (sucesso na primeira tentativa ou após retries)
  - `1` (falha persistente após esgotar retries)
  - `2` (timeout ou violação de limite de recurso)
  - Logs JSONL em stderr com `attempt`, `delay`, `error_code`, `tenant_id`
- **Side Effects**: 
  - Pausa controlada (`sleep`) entre tentativas
  - Atualização de variável de estado `RETRY_STATE` (local ao script)
  - Nenhum arquivo modificado; operação puramente executiva
- **Constraints Aplicáveis**: C1 (timeout/delay controlado), C5 (estrutura de funções e variáveis), C7 (resiliência/fail-fast), C8 (auditoria de tentativas)
- **Dependências Externas**: `date`, `sleep`, `bc` (ou fallback aritmética bash pura), coreutils POSIX

## 🛡️ Bootstrap Resiliente e Lógica de Retry (C1+C5+C7+C8)
```bash
# =============================================================================
# BOOTSTRAP RESILIENTE: Hardening + Observabilidade (C3+C4+C7)
# Fonte de verdade: bash-master-agent.md via source
# =============================================================================
if [[ -f "${MANTIS_ROOT:-.}/06-PROGRAMMING/bash/bash-master-agent.sh" ]]; then
  source "${MANTIS_ROOT:-.}/06-PROGRAMMING/bash/bash-master-agent.sh" --mode=observability-only
else
  set -Eeuo pipefail; shopt -s inherit_errexit 2>/dev/null || true
  trap 'exit 130' INT TERM
  : "${TENANT_ID:?ERROR: TENANT_ID não definido. Defina via env ou argumento.}"
  mantis_log() { printf '{"ts":"%s","level":"%s","tenant":"%s","event":"%s","detail":"%s","fallback":"true"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${1:-INFO}" "${TENANT_ID:-unknown}" "${2:-bootstrap_fallback}" "${3:-}" >&2; }
  mantis_log "WARN" "bootstrap_fallback" "Master agent não encontrado. Executando com hardening mínimo."
fi

readonly SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"
readonly SCRIPT_VERSION="${VERSION:-2.0.0}"
export TENANT_ID="${TENANT_ID:-}"

# =============================================================================
# LÓGICA DE RETRY COM BACKOFF EXPONENCIAL E OBSERVABILIDADE
# =============================================================================
# C7: Trap global unificado
cleanup_retry() {
  local exit_code=$?
  if [[ $exit_code -ne 0 ]]; then
    mantis_log "ERROR" "retry_aborted" "Script finalizado com código $exit_code | Tenant: ${TENANT_ID}"
  fi
  exit $exit_code
}
trap cleanup_retry EXIT INT TERM

# C4: Validação de contexto
: "${TENANT_ID:?Variável de ambiente TENANT_ID não definida. Abortando.}"

# C7+C1: Função de retry com backoff exponencial seguro
execute_with_retry() {
  local max_retries="${MAX_RETRIES:-3}"
  local base_delay="${BASE_DELAY_SEC:-2}"
  local cmd="$*"
  local attempt=1
  local delay=$base_delay

  while [[ $attempt -le $max_retries ]]; do
    mantis_log "INFO" "retry_attempt" "attempt=$attempt, command=${cmd}, tenant=${TENANT_ID}"
    
    # C1: Timeout por tentativa (padrão: 2x base_delay ou mínimo 10s)
    local attempt_timeout
    attempt_timeout=$(( delay > 10 ? delay * 2 : 10 ))
    
    if timeout "$attempt_timeout" bash -c "$cmd" 2>/dev/null; then
      mantis_log "INFO" "retry_success" "attempt=$attempt, total_attempts=$attempt, tenant=${TENANT_ID}"
      return 0
    else
      local exit_code=$?
      mantis_log "WARN" "retry_failed" "attempt=$attempt, error_code=$exit_code, next_delay=${delay}s, tenant=${TENANT_ID}"
      if [[ $attempt -eq $max_retries ]]; then
        mantis_log "ERROR" "retry_exhausted" "Esgotadas $max_retries tentativas para comando: ${cmd}"
        return 1
      fi
      sleep "$delay"
      # Backoff exponencial com jitter mínimo para evitar thundering herd
      delay=$(( delay * 2 + RANDOM % 2 ))
    fi
    ((attempt++))
  done
  return 1
}
```

## 🧪 Testes Unitários (TDD)
```bash
test_retry_succeeds_on_transient_failure() {
  # Arrange
  local attempt_file
  attempt_file=$(mktemp)
  echo 0 > "$attempt_file"
  
  # Simula comando que falha 2 vezes e passa na 3ª
  local test_cmd="count=\$(cat $attempt_file); count=\$((count+1)); echo \$count > $attempt_file; [[ \$count -ge 3 ]]"
  local MAX_RETRIES=3
  local BASE_DELAY_SEC=0  # Accelerated for test
  
  # Act
  execute_with_retry "$test_cmd"
  local exit_code=$?
  local final_count
  final_count=$(cat "$attempt_file")
  
  # Assert
  if [[ $exit_code -eq 0 && $final_count -eq 3 ]]; then
    rm -f "$attempt_file"
    return 0
  else
    mantis_log "ERROR" "test_failed" "Retry não recuperou falha transitória (exit: $exit_code, count: $final_count)"
    rm -f "$attempt_file"
    return 1
  fi
}

test_retry_aborts_on_persistent_failure() {
  # Arrange
  local test_cmd="exit 1"
  local MAX_RETRIES=2
  local BASE_DELAY_SEC=0
  
  # Act
  execute_with_retry "$test_cmd"
  local exit_code=$?
  
  # Assert
  if [[ $exit_code -eq 1 ]]; then
    return 0
  else
    mantis_log "ERROR" "test_failed" "Retry não abortou após falha persistente (exit esperado: 1, obtido: $exit_code)"
    return 1
  fi
}

test_validate_vlog02_schema() {
  local log_output
  log_output=$(mantis_log "INFO" "test_event" "detalhe_teste" 2>&1)
  if printf '%s\n' "$log_output" | jq -e '
    has("timestamp") and has("level") and has("resource.tenant_id") and has("resource.artifact") and has("body.event")
  ' >/dev/null 2>&1; then
    return 0
  else
    mantis_log "ERROR" "schema_validation_failed" "Log não conforma com V-LOG-02"
    return 1
  fi
}

if [[ "${1:-}" == "--test" ]]; then
  test_retry_succeeds_on_transient_failure
  test_retry_aborts_on_persistent_failure
  test_validate_vlog02_schema
  exit $?
fi
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/bash/robust-error-handling.md \
  --json \
  --check-secrets \
  --check-tenant-isolation \
  --check-structural \
  --check-resource-limits \
  --check-error-handling \
  --check-observability
```

## 🔗 Referências Cruzadas
- [[bash-master-agent.md]] ← Contrato de geração e anti-padrões proibidos
- [[01-RULES/harness-norms-v3.0.md]] ← Especificação de hardening C7
- [[01-RULES/10-SDD-CONSTRAINTS.md]] ← Definição de C1, C5, C8
- [[01-RULES/02-RESOURCE-GUARDRAILS.md]] ← Limites de timeout e retry
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]] ← Índice de observabilidade
- [[/05-CONFIGURATIONS/observability/loki/config.yml]] ← Pipeline de ingestão de logs JSONL
- [[00-CONTEXT/norms-matrix.json]] ← Fonte de verdade para constraints

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2024-10-05 | Dev inicial | Retry básico com `sleep` fixo | Parcial |
| 2.0.0 | 2026-05-06 | Bash Master Agent | Remanufatura: bootstrap resiliente, `mantis_log()` canônica, validação V-LOG-02, remoção de hardening inline | C1,C5,C7,C8 |

---
## 🔍 Observability (Documentación para IA)

> Este artefato emite os seguintes eventos via `mantis_log()` (definida em [[bash-master-agent.md]]):

| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `retry_attempt` | INFO | C8 | `"attempt=1, command=curl https://api.example.com, tenant=tenant-xyz"` |
| `retry_success` | INFO | C7 | `"attempt=2, total_attempts=2, tenant=tenant-xyz"` |
| `retry_failed` | WARN | C7 | `"attempt=1, error_code=124, next_delay=4s, tenant=tenant-xyz"` |
| `retry_exhausted` | ERROR | C1 | `"Esgotadas 3 tentativas para comando: curl https://api.example.com"` |
| `retry_aborted` | ERROR | C7 | `"Script finalizado com código 1 | Tenant: tenant-xyz"` |
| `bootstrap_fallback` | WARN | C7 | `"Master agent não encontrado. Executando com hardening mínimo."` |

### Exemplo de Output JSONL (para aprendizado de padrão por IA)
```json
{"timestamp":"2026-05-06T12:15:00Z","level":"INFO","resource":{"tenant_id":"tenant-xyz","artifact":"robust-error-handling"},"body":{"event":"retry_success","detail":"attempt=2, total_attempts=2, tenant=tenant-xyz"},"attributes":{"mantis":{"tier":"2","version":"2.0.0","constraint":"C1,C7,C8","trace_id":""},"code.filepath":"06-PROGRAMMING/bash/robust-error-handling.md","code.lineno":67,"telemetry.sdk.name":"mantis-bash-adapter","telemetry.sdk.version":"1.0.0"}}
```

### Configuração Específica de Este Artefato
```bash
# Variáveis de entorno que afetam o comportamento de logging deste artefato
export LOG_RETRY_ATTEMPTS="${LOG_RETRY_ATTEMPTS:-true}"      # Incluir contagem de tentativas em logs
export LOG_RETRY_DELAYS="${LOG_RETRY_DELAYS:-true}"          # Incluir delays de backoff em logs
export TRACE_RETRY_OPS="${TRACE_RETRY_OPS:-false}"           # Habilitar trace_id para correlação OTel
```

### Validação de Schema V-LOG-02 (Helper Executável)
```bash
# Função helper para validação local de logs
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
