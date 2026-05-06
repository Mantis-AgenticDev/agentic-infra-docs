---
artifact_id: timeout-and-retry-patterns
artifact_type: bash_utility
version: 1.0.0
constraints_mapped: ["C1","C7"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/bash/timeout-and-retry-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:timeout-and-retry-patterns-v1.0.0"
generated_at: "2026-05-07T02:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: bash
ai_navigation:
  read_first: false
  required_for: [fault-tolerant-execution, backoff-control, circuit-breaker-logic]
  update_frequency: on-change
audience: ["orchestrator-engine", "sre-agents", "bash-developers"]
status: "🟢 Novo"
next_review: "2026-06-07"
---

# Padrões de Timeout e Retry com Backoff Exponencial Seguro

## 🎯 Propósito
Fornecer execução resiliente de comandos externos com limite estrito por tentativa (`C1`), backoff exponencial com jitter para evitar `thundering herd` e abort controlado após esgotar retries (`C7`). Integrado ao trap de `error-handling-traps` para limpeza de estado.

## 📋 Especificação (SDD)
- **Entradas**: `COMMAND` (string), `MAX_RETRIES` (padrão: 3), `BASE_DELAY_SEC` (padrão: 2), `TIMEOUT_PER_ATTEMPT_SEC` (padrão: 30)
- **Saídas**: `0` (sucesso), `1` (falha persistente), `2` (timeout irrecoverável)
- **Side Effects**: Pausas controladas (`sleep`), logs JSONL por tentativa
- **Constraints Aplicáveis**: C1 (limites temporais), C7 (resiliência, backoff, trap)
- **Dependências Externas**: `timeout`, `sleep`, coreutils POSIX

## 🛡️ Bootstrap Resiliente e Lógica de Retry (C1+C7)
```bash
if [[ -f "${MANTIS_ROOT:-.}/06-PROGRAMMING/bash/bash-master-agent.sh" ]]; then
  source "${MANTIS_ROOT:-.}/06-PROGRAMMING/bash/bash-master-agent.sh" --mode=observability-only
else
  set -Eeuo pipefail; shopt -s inherit_errexit 2>/dev/null || true
  trap 'exit 130' INT TERM
  : "${TENANT_ID:?ERROR: TENANT_ID não definido.}"
  mantis_log() { printf '{"ts":"%s","level":"%s","tenant":"%s","event":"%s","detail":"%s","fallback":"true"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${1:-INFO}" "${TENANT_ID:-unknown}" "${2:-bootstrap_fallback}" "${3:-}" >&2; }
  mantis_log "WARN" "bootstrap_fallback" "Master agent não encontrado."
fi

readonly SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"
readonly ARTIFACT_ID="timeout-and-retry-patterns"
export TENANT_ID="${TENANT_ID:-}"

execute_with_retry_and_timeout() {
  local cmd="${1:?execute_with_retry_and_timeout: comando obrigatório}"
  local max_retries="${MAX_RETRIES:-3}"
  local base_delay="${BASE_DELAY_SEC:-2}"
  local timeout_sec="${TIMEOUT_PER_ATTEMPT_SEC:-30}"
  local attempt=1 delay=$base_delay

  while (( attempt <= max_retries )); do
    mantis_log "INFO" "retry_attempt" "attempt=$attempt/$max_retries, cmd=$cmd"
    
    if timeout "$timeout_sec" eval "$cmd" >/dev/null 2>&1; then
      mantis_log "INFO" "retry_succeeded" "attempt=$attempt, duration_within_limits"
      return 0
    else
      local rc=$?
      mantis_log "WARN" "attempt_failed" "attempt=$attempt, exit_code=$rc, backoff=${delay}s"
      
      (( attempt == max_retries )) && { mantis_log "ERROR" "retries_exhausted" "Comando falhou após $max_retries tentativas"; return 1; }
      sleep "$delay"
      # Backoff exponencial + jitter aleatório (0-1s)
      delay=$(( (delay * 2) + RANDOM % 2 ))
    fi
    ((attempt++))
  done
  return 1
}
```

## 🧪 Testes Unitários (TDD)
```bash
test_retry_succeeds_on_third_attempt() {
  local counter_file=$(mktemp)
  echo 0 > "$counter_file"
  local cmd='n=$(cat '"$counter_file"'); n=$((n+1)); echo $n > '"$counter_file"'; [[ $n -ge 3 ]]'
  execute_with_retry_and_timeout "$cmd" 2>/dev/null
  local final=$(cat "$counter_file")
  rm -f "$counter_file"
  [[ $final -eq 3 ]] && return 0
  return 1
}

test_retry_aborts_after_max_attempts() {
  execute_with_retry_and_timeout "exit 5" MAX_RETRIES=2 BASE_DELAY_SEC=0 TIMEOUT_PER_ATTEMPT_SEC=1 2>/dev/null
  [[ $? -eq 1 ]] && return 0
  return 1
}

test_validate_vlog02_schema() {
  mantis_log "INFO" "test" "x" 2>&1 | jq -e 'has("timestamp") and has("level") and has("resource.tenant_id") and has("resource.artifact")' >/dev/null 2>&1
}

if [[ "${1:-}" == "--test" ]]; then test_retry_succeeds_on_third_attempt; test_retry_aborts_after_max_attempts; test_validate_vlog02_schema; exit $?; fi
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/bash/timeout-and-retry-patterns.md --json --check-structural --check-error-handling --check-observability
```

## 🔗 Referências Cruzadas
- [[bash-master-agent.md]]
- [[error-handling-traps.md]]
- [[01-RULES/02-RESOURCE-GUARDRAILS.md]]
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]]

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-07 | Bash Master Agent | Criação inicial: backoff exponencial, timeout por tentativa, jitter | C1,C7 |

---
## 🔍 Observability (Documentación para IA)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `retry_attempt` | INFO | C1 | `"attempt=1/3, cmd=curl -s http://api"` |
| `attempt_failed` | WARN | C7 | `"attempt=1, exit_code=124, backoff=4s"` |
| `retry_succeeded` | INFO | C7 | `"attempt=2, duration_within_limits"` |
| `retries_exhausted` | ERROR | C1 | `"Comando falhou após 3 tentativas"` |

### Validação de Schema V-LOG-02
```bash
validate_vlog02() { jq -e 'has("timestamp") and has("level") and has("resource.tenant_id") and has("resource.artifact")' >/dev/null 2>&1; }
```
---
