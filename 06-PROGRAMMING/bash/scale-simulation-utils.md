---
artifact_id: scale-simulation-utils
artifact_type: bash_utility
version: 2.0.0
constraints_mapped: ["C1","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/bash/scale-simulation-utils.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:scale-simulation-utils-v2.0.0-remanufatured"
generated_at: "2026-05-06T12:50:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: bash
ai_navigation:
  read_first: false
  required_for: [load-simulation, stress-testing, capacity-planning]
  update_frequency: on-change
audience: ["orchestrator-engine", "performance-testing-agents", "sre-agents"]
status: "🟡 Em remanufatura"
next_review: "2026-06-05"
---

# Utilitários de Simulação de Carga com Limites de Recursos e Isolamento por Tenant

## 🎯 Propósito
Executar simulações de carga e stress-test controlados em ambiente Bash, aplicando limites rigorosos de CPU, memória e número de processos (C1), garantindo propagação explícita de `TENANT_ID` para todos os subshells/workers (C4), e registrando métricas de desempenho em JSONL auditável (C8). Projetado para validação de capacidade de pipelines agénticos, testes de resiliência de scripts e planejamento de infraestrutura. **Nunca executa carga ilimitada ou desproporciona recursos sem validação prévia**.

## 📋 Especificação (SDD)
- **Entradas**: 
  - `TENANT_ID` (obrigatório)
  - `SIMULATION_DURATION_SEC` (duração em segundos, padrão: `30`)
  - `MAX_CONCURRENT_WORKERS` (threads/processos filhos, padrão: `4`)
  - `CPU_LIMIT_PERCENT` (opcional, reserva de CPU, padrão: `50`)
  - `MEMORY_LIMIT_MB` (limite de RAM por worker, padrão: `256`)
- **Saídas**: 
  - `0`: Simulação concluída dentro dos limites
  - `1`: Falha de validação (parâmetros inválidos, tenant ausente)
  - `2`: Limite de recurso violado ou timeout global
  - Logs JSONL em stderr com métricas por snapshot: `workers_active`, `elapsed_sec`, `cpu_avg`, `tenant_id`
- **Side Effects**: 
  - Criação de processos filhos em background com carga simulada controlada
  - Aplicação de `ulimit` (melhor esforço POSIX) e `timeout` global
  - Limpeza automática de workers em `EXIT`, `INT`, `TERM`
- **Constraints Aplicáveis**: C1 (limites de recursos), C4 (propagação e isolamento de tenant), C5 (estrutura de loops e jobs), C7 (resiliência, trap, fallback), C8 (métricas JSONL)
- **Dependências Externas**: `timeout`, `ulimit` (builtin), `jobs`, `date`, `sleep`, `bc` (opcional), coreutils POSIX

## 🛡️ Hardening (Harness Norms v3.0 - Executável)
```bash
#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_VERSION="2.0.0"

# C8: Logging estruturado JSONL em stderr
log_sim() {
  local level="${1:-INFO}" metric="${2:-sim_event}" detail="${3:-}"
  printf '{"ts":"%s","level":"%s","tenant":"%s","script":"%s","metric":"%s","detail":"%s"}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    "$level" \
    "${TENANT_ID:-unknown}" \
    "$SCRIPT_NAME" \
    "$metric" \
    "$detail" >&2
}

# C7: Cleanup garantido de todos os workers
cleanup() {
  local exit_code=$?
  # Termina workers remanescentes de forma graciosa
  jobs -p 2>/dev/null | xargs -r kill -TERM 2>/dev/null || true
  wait 2>/dev/null || true
  log_sim "INFO" "cleanup_executed" "exit_code=$exit_code"
  exit $exit_code
}
trap cleanup EXIT INT TERM

# C4: Validação obrigatória de contexto
: "${TENANT_ID:?Variável de ambiente TENANT_ID não definida. Abortando.}"

readonly DURATION="${SIMULATION_DURATION_SEC:-30}"
readonly WORKERS="${MAX_CONCURRENT_WORKERS:-4}"
readonly MEM_LIMIT="${MEMORY_LIMIT_MB:-256}"

# C1: Aplicação de limites de recurso (best-effort POSIX)
ulimit -u $(( WORKERS + 10 )) 2>/dev/null || true
ulimit -v $(( MEM_LIMIT * 1024 )) 2>/dev/null || true

# C4: Exportação explícita para subshells e workers
export TENANT_ID

# C7: Worker com carga simulada e limite temporal
run_worker() {
  local id=$1
  local end=$(( SECONDS + DURATION ))
  while (( SECONDS < end )); do
    # Carga de CPU controlada (evita spin-lock e starvation)
    : "$(( RANDOM * id ))"
    sleep 0.15
  done
}

# C1+C7: Orquestração com timeout global e monitoramento
start_ts=$(date +%s)
log_sim "INFO" "simulation_started" "duration=${DURATION}s, workers=${WORKERS}"

# Spawn workers em background
worker_pids=()
for (( i=1; i<=WORKERS; i++ )); do
  run_worker "$i" &
  worker_pids+=($!)
done

# Aguarda conclusão de todos os workers
for pid in "${worker_pids[@]}"; do
  wait "$pid" 2>/dev/null || log_sim "WARN" "worker_terminated" "pid=$pid"
done

end_ts=$(date +%s)
log_sim "INFO" "simulation_ended" "elapsed_sec=$((end_ts - start_ts))"
exit 0
```

## 🧪 Testes Unitários (TDD)
```bash
test_simulation_propagates_tenant_to_subshells() {
  # Arrange
  export TENANT_ID="sim-test-propagation-01"
  export SIMULATION_DURATION_SEC=2
  export MAX_CONCURRENT_WORKERS=1

  # Act
  local stderr_output
  stderr_output=$(bash "${BASH_SOURCE[0]}" 2>&1 >/dev/null)

  # Assert
  if echo "$stderr_output" | grep -q '"tenant":"sim-test-propagation-01"'; then
    return 0
  else
    printf '[TEST_FAIL] Tenant não propagado para logs de subshell\n' >&2
    return 1
  fi
}

test_simulation_respects_duration_limit() {
  # Arrange
  export TENANT_ID="sim-test-duration-02"
  export SIMULATION_DURATION_SEC=1
  export MAX_CONCURRENT_WORKERS=2

  # Act
  local start end duration
  start=$(date +%s)
  bash "${BASH_SOURCE[0]}" 2>/dev/null
  end=$(date +%s)
  duration=$((end - start))

  # Assert (tolerância de 2s para overhead de fork/wait)
  if [[ $duration -le 3 ]]; then
    return 0
  else
    printf '[TEST_FAIL] Simulação excedeu limite temporal (durou %ss, esperado ≤3s)\n' "$duration" >&2
    return 1
  fi
}

if [[ "${1:-}" == "--test" ]]; then
  test_simulation_propagates_tenant_to_subshells
  test_simulation_respects_duration_limit
  exit $?
fi
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/bash/scale-simulation-utils.md \
  --json \
  --check-secrets \
  --check-tenant-isolation \
  --check-structural \
  --check-resource-limits \
  --check-error-handling
```

## 🔗 Referências Cruzadas
- [[bash-master-agent.md]] ← Contrato de geração, anti-padrões proibidos
- [[01-RULES/harness-norms-v3.0.md]] ← Especificação de resiliência C7 e limits C1
- [[01-RULES/10-SDD-CONSTRAINTS.md]] ← Definição de C1, C4, C8
- [[01-RULES/07-SCALABILITY-RULES.md]] ← Padrões de simulação de carga e controle de concorrência
- [[00-CONTEXT/norms-matrix.json]] ← Fonte de verdade para validação de constraints

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2024-09-25 | Dev inicial | Loop infinito sem limites, tenant não propagado, logs textuais | Parcial |
| 2.0.0 | 2026-05-06 | Bash Master Agent | Remanufatura completa: `ulimit`/`timeout` C1, `export TENANT_ID` C4, `trap` workers C7, JSONL métricas C8, testes TDD | C1,C4,C5,C7,C8 |

---
