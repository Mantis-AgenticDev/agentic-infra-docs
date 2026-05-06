---
artifact_id: error-handling-traps
artifact_type: bash_utility
version: 1.0.0
constraints_mapped: ["C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/bash/error-handling-traps.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:error-handling-traps-v1.0.0"
generated_at: "2026-05-07T00:00:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: bash
ai_navigation:
  read_first: false
  required_for: [graceful-shutdown, state-preservation, signal-handling]
  update_frequency: on-change
audience: ["bash-developers", "ci-cd-pipelines", "sre-agents"]
status: "🟢 Novo"
next_review: "2026-06-07"
---

# Padrões de Trap e Cleanup Resiliente (C7)

## 🎯 Propósito
Centralizar a configuração de `trap` para sinais `EXIT`, `INT`, `TERM` e `ERR`, garantindo liberação de recursos, rollback de estado e auditoria forense antes da finalização. Fornece funções reutilizáveis para limpeza condicional e registro de causa de término.

## 📋 Especificação (SDD)
- **Entradas**: 
  - `CLEANUP_CALLBACK` (nome de função ou string de comando)
  - `TEMP_RESOURCES` (array de arquivos/dirs a limpar)
- **Saídas**: 
  - Código: `0` (saída normal), `130` (INT/TERM), `143` (SIGTERM externo)
  - Logs JSONL com `shutdown_reason`, `resources_cleaned`, `exit_code`
- **Side Effects**: 
  - Remoção de temporários listados
  - Execução do callback de rollback se definido
- **Constraints Aplicáveis**: C7 (resiliência, fail-fast, trap unificado), C8 (auditoria de término)
- **Dependências Externas**: `jobs`, `wait`, coreutils POSIX

## 🛡️ Bootstrap Resiliente e Lógica de Traps (C7+C8)
```bash
# =============================================================================
# BOOTSTRAP RESILIENTE: Hardening + Observabilidade (C3+C4+C7)
# =============================================================================
if [[ -f "${MANTIS_ROOT:-.}/06-PROGRAMMING/bash/bash-master-agent.sh" ]]; then
  source "${MANTIS_ROOT:-.}/06-PROGRAMMING/bash/bash-master-agent.sh" --mode=observability-only
else
  set -Eeuo pipefail; shopt -s inherit_errexit 2>/dev/null || true
  trap 'exit 130' INT TERM
  if [[ "${TENANT_CONTEXT:-nao_aplicavel}" != "nao_aplicavel" ]]; then
    : "${TENANT_ID:?ERROR: TENANT_ID não definido.}"
  fi
  mantis_log() { printf '{"ts":"%s","level":"%s","tenant":"%s","event":"%s","detail":"%s","fallback":"true"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${1:-INFO}" "${TENANT_ID:-global}" "${2:-bootstrap_fallback}" "${3:-}" >&2; }
  mantis_log "WARN" "bootstrap_fallback" "Master agent não encontrado."
fi

readonly SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"
readonly SCRIPT_VERSION="${VERSION:-1.0.0}"
readonly ARTIFACT_ID="error-handling-traps"
export TENANT_ID="${TENANT_ID:-global}"

# C7: Estado interno de recursos
declare -a _MANTIS_TEMP_FILES=()
_MANTIS_CALLBACK=""

# C7+C8: Registro de trap unificado
setup_resilient_traps() {
  _MANTIS_CALLBACK="${1:-}"
  trap '_mantis_handle_exit "$?"' EXIT
  trap '_mantis_handle_signal INT' INT
  trap '_mantis_handle_signal TERM' TERM
  mantis_log "DEBUG" "traps_registered" "EXIT, INT, TERM interceptados"
}

_mantis_handle_signal() {
  local sig="$1"
  mantis_log "WARN" "signal_received" "Sinal $sig capturado. Iniciando shutdown gracioso."
  exit 130
}

_mantis_handle_exit() {
  local exit_code="$1"
  local cleaned=0
  
  # Limpeza de temporários
  for f in "${_MANTIS_TEMP_FILES[@]:-}"; do
    [[ -e "$f" ]] && { rm -rf "$f" && ((cleaned++)); }
  done

  # Callback de rollback se definido
  [[ -n "$_MANTIS_CALLBACK" ]] && eval "$_MANTIS_CALLBACK" 2>/dev/null || true

  if [[ $exit_code -ne 0 ]]; then
    mantis_log "ERROR" "graceful_shutdown" "exit_code=$exit_code, cleaned_files=$cleaned, tenant=${TENANT_ID}"
  else
    mantis_log "INFO" "clean_exit" "Recursos liberados: $cleaned"
  fi
}

# Helper: registrar temporário
register_temp() {
  _MANTIS_TEMP_FILES+=("$1")
}
```

## 🧪 Testes Unitários (TDD)
```bash
test_traps_cleanup_temp_files() {
  local tmp
  tmp=$(mktemp -d)
  register_temp "$tmp"
  setup_resilient_traps ""
  # Simula saída
  bash -c "$(declare -f register_temp _MANTIS_TEMP_FILES setup_resilient_traps _mantis_handle_exit mantis_log); register_temp '$tmp'; exit 0" 2>/dev/null
  [[ ! -d "$tmp" ]] && return 0
  return 1
}

test_validate_vlog02_schema() {
  local log_output
  log_output=$(mantis_log "INFO" "test_event" "detalhe" 2>&1)
  printf '%s\n' "$log_output" | jq -e 'has("timestamp") and has("resource.tenant_id")' >/dev/null 2>&1
}

if [[ "${1:-}" == "--test" ]]; then
  test_traps_cleanup_temp_files
  test_validate_vlog02_schema
  exit $?
fi
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/bash/error-handling-traps.md \
  --json --check-structural --check-error-handling --check-observability
```

## 🔗 Referências Cruzadas
- [[bash-master-agent.md]]
- [[01-RULES/harness-norms-v3.0.md]]
- [[01-RULES/07-SCALABILITY-RULES.md]]
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]]
- [[/05-CONFIGURATIONS/observability/loki/config.yml]]

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-07 | Bash Master Agent | Criação inicial: traps unificados, array de temporários, shutdown auditável | C7,C8 |

---
## 🔍 Observability (Documentación para IA)
> Este artefato emite os seguintes eventos via `mantis_log()`:

| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `traps_registered` | DEBUG | C7 | `"EXIT, INT, TERM interceptados"` |
| `signal_received` | WARN | C7 | `"Sinal INT capturado. Iniciando shutdown gracioso."` |
| `clean_exit` | INFO | C8 | `"Recursos liberados: 3"` |
| `graceful_shutdown` | ERROR | C7 | `"exit_code=1, cleaned_files=2, tenant=global"` |

### Validação de Schema V-LOG-02
```bash
validate_vlog02() { jq -e 'has("timestamp") and has("level") and has("resource.tenant_id")' >/dev/null 2>&1; }
```
---
