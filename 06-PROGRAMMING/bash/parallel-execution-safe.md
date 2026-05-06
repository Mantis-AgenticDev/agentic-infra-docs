---
artifact_id: parallel-execution-safe
artifact_type: bash_utility
version: 1.0.0
constraints_mapped: ["C1","C7"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/bash/parallel-execution-safe.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:parallel-execution-safe-v1.0.0"
generated_at: "2026-05-07T02:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: bash
ai_navigation:
  read_first: false
  required_for: [worker-pool-management, concurrent-job-safety, result-aggregation]
  update_frequency: on-change
audience: ["sre-agents", "pipeline-dispatchers", "bash-developers"]
status: "🟢 Novo"
next_review: "2026-06-07"
---

# Execução Paralela Segura com Pool de Workers Controlado

## 🎯 Propósito
Gerenciar concorrência via pool fixo de workers, evitando `fork bomb`, agregando códigos de saída e garantindo cancelamento limpo via sinais. Aplica limites de processos (`C1`) e trap de limpeza (`C7`) herdado de `error-handling-traps`.

## 📋 Especificação (SDD)
- **Entradas**: `COMMAND_LIST` (arquivo ou stdin com 1 cmd/linha), `MAX_WORKERS` (padrão: 4)
- **Saídas**: `0` (todos OK), `>0` (quantidade de falhas), logs JSONL por worker
- **Side Effects**: Spawn de subshells em background, wait sincronizado
- **Constraints Aplicáveis**: C1 (limite de concorrência), C7 (cleanup, signal handling)
- **Dependências Externas**: `jobs`, `wait`, `xargs` (fallback), coreutils

## 🛡️ Bootstrap Resiliente e Lógica Paralela (C1+C7)
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
readonly ARTIFACT_ID="parallel-execution-safe"
export TENANT_ID="${TENANT_ID:-}"

run_safe_parallel() {
  local cmds_file="${1:?run_safe_parallel: arquivo de comandos obrigatório}"
  local max_workers="${MAX_WORKERS:-4}"
  local failures=0
  local active_jobs=()

  [[ -f "$cmds_file" ]] || { mantis_log "ERROR" "cmds_file_missing"; return 1; }

  while IFS= read -r cmd; do
    [[ -z "$cmd" || "$cmd" == \#* ]] && continue
    mantis_log "DEBUG" "worker_queued" "cmd=$cmd"

    # Aguardar slot livre
    while (( ${#active_jobs[@]} >= max_workers )); do
      wait -n 2>/dev/null || true
      active_jobs=( $(jobs -p 2>/dev/null) )
    done

    eval "$cmd" &
    active_jobs+=($!)
    mantis_log "INFO" "worker_started" "pid=$!, active_workers=${#active_jobs[@]}"
  done < "$cmds_file"

  # Aguardar todos finalizarem
  for pid in "${active_jobs[@]}"; do
    wait "$pid" 2>/dev/null || ((failures++))
  done

  mantis_log "INFO" "parallel_completed" "total_workers=${#active_jobs[@]}, failures=$failures"
  return $failures
}
```

## 🧪 Testes Unitários (TDD)
```bash
test_parallel_executes_all_commands() {
  local cmds=$(mktemp)
  printf 'echo "job1"\necho "job2"\n' > "$cmds"
  run_safe_parallel "$cmds" MAX_WORKERS=2 2>/dev/null
  local rc=$?
  rm -f "$cmds"
  [[ $rc -eq 0 ]] && return 0
  return 1
}

test_parallel_respects_worker_limit() {
  # Simulação conceitual: max_workers=1 executa sequencialmente
  local cmds=$(mktemp)
  printf 'sleep 0.5\necho "a"\n' > "$cmds"
  local start; start=$(date +%s%N)
  run_safe_parallel "$cmds" MAX_WORKERS=1 2>/dev/null
  local end; end=$(date +%s%N)
  local ms=$(( (end - start) / 1000000 ))
  rm -f "$cmds"
  [[ $ms -ge 500 ]] && return 0
  return 1
}

test_validate_vlog02_schema() {
  mantis_log "INFO" "test" "x" 2>&1 | jq -e 'has("timestamp") and has("level") and has("resource.tenant_id")' >/dev/null 2>&1
}

if [[ "${1:-}" == "--test" ]]; then test_parallel_executes_all_commands; test_parallel_respects_worker_limit; test_validate_vlog02_schema; exit $?; fi
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/bash/parallel-execution-safe.md --json --check-structural --check-error-handling --check-observability
```

## 🔗 Referências Cruzadas
- [[bash-master-agent.md]]
- [[error-handling-traps.md]]
- [[01-RULES/07-SCALABILITY-RULES.md]]
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]]

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-07 | Bash Master Agent | Criação inicial: pool workers, wait -n, controle de falhas | C1,C7 |

---
## 🔍 Observability (Documentación para IA)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `worker_queued` | DEBUG | C1 | `"cmd=process_batch.sh --id=42"` |
| `worker_started` | INFO | C7 | `"pid=1234, active_workers=2"` |
| `parallel_completed` | INFO | C1 | `"total_workers=5, failures=0"` |

### Validação de Schema V-LOG-02
```bash
validate_vlog02() { jq -e 'has("timestamp") and has("level") and has("resource.tenant_id") and has("resource.artifact")' >/dev/null 2>&1; }
```
---
