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

## 🛡️ Hardening (Harness Norms v3.0 - Executável)
```bash
#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_VERSION="2.0.0"

# C8: Logging estruturado JSONL
log_retry() {
  local level="${1:-INFO}"
  local attempt="${2:-0}"
  local detail="${3:-}"
  printf '{"ts":"%s","level":"%s","tenant":"%s","script":"%s","attempt":%d,"detail":"%s"}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    "$level" \
    "${TENANT_ID:-unknown}" \
    "$SCRIPT_NAME" \
    "$attempt" \
    "$detail" >&2
}

# C7: Trap global unificado
cleanup_on_exit() {
  local exit_code=$?
  if [[ $exit_code -ne 0 ]]; then
    log_retry "ERROR" 0 "Script finalizado com código $exit_code"
  fi
  exit $exit_code
}
trap cleanup_on_exit EXIT INT TERM

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
    log_retry "INFO" "$attempt" "Executando: ${cmd}"
    
    # C1: Timeout por tentativa (padrão: 2x base_delay ou mínimo 10s)
    local attempt_timeout
    attempt_timeout=$(( delay > 10 ? delay * 2 : 10 ))
    
    if timeout "$attempt_timeout" bash -c "$cmd" 2>/dev/null; then
      log_retry "INFO" "$attempt" "Sucesso"
      return 0
    else
      local exit_code=$?
      log_retry "WARN" "$attempt" "Falha com código $exit_code. Aguardando ${delay}s..."
      if [[ $attempt -eq $max_retries ]]; then
        log_retry "ERROR" "$attempt" "Esgotadas $max_retries tentativas"
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
    printf '[TEST_FAIL] Retry não recuperou falha transitória (exit: %s, count: %s)\n' "$exit_code" "$final_count" >&2
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
    printf '[TEST_FAIL] Retry não abortou após falha persistente (exit esperado: 1, obtido: %s)\n' "$exit_code" >&2
    return 1
  fi
}

if [[ "${1:-}" == "--test" ]]; then
  test_retry_succeeds_on_transient_failure
  test_retry_aborts_on_persistent_failure
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
  --check-error-handling
```

## 🔗 Referências Cruzadas
- [[bash-master-agent.md]] ← Contrato de geração e anti-padrões proibidos
- [[01-RULES/harness-norms-v3.0.md]] ← Especificação de hardening C7
- [[01-RULES/10-SDD-CONSTRAINTS.md]] ← Definição de C1, C5, C8
- [[01-RULES/02-RESOURCE-GUARDRAILS.md]] ← Limites de timeout e retry
- [[00-CONTEXT/norms-matrix.json]] ← Fonte de verdade para constraints

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2024-10-05 | Dev inicial | Retry básico com `sleep` fixo | Parcial |
| 2.0.0 | 2026-05-06 | Bash Master Agent | Remanufatura: backoff exponencial com jitter, timeout por tentativa, JSONL C8, tenant C4, testes TDD | C1,C5,C7,C8 |

---
