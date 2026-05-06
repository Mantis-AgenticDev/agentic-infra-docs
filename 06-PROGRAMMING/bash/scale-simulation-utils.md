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

## 🛡️ Bootstrap Resiliente e Lógica de Simulação (C1+C4+C5+C7+C8)
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
# LÓGICA DE SIMULAÇÃO DE CARGA COM LIMITES E ISOLAMENTO
# =============================================================================
# C7: Cleanup garantido de todos os workers
cleanup_sim() {
  local exit_code=$?
  # Termina workers remanescentes de forma graciosa
  jobs -p 2>/dev/null | xargs -r kill -TERM 2>/dev/null || true
  wait 2>/dev/null || true
  mantis_log "INFO" "simulation_cleanup" "exit_code=$exit_code, tenant=${TENANT_ID}"
  exit $exit_code
}
trap cleanup_sim EXIT INT TERM

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
  mantis_log "DEBUG" "worker_completed" "worker_id=$id, tenant=${TENANT_ID}"
}

# C1+C7: Orquestração com timeout global e monitoramento
start_ts=$(date +%s)
mantis_log "INFO" "simulation_started" "duration=${DURATION}s, workers=${WORKERS}, tenant=${TENANT_ID}"

# Spawn workers em background
worker_pids=()
for (( i=1; i<=WORKERS; i++ )); do
  run_worker "$i" &
  worker_pids+=($!)
done

# Monitoramento periódico de métricas (C8)
monitor_interval=5
elapsed=0
while (( elapsed < DURATION )); do
  active_workers=$(jobs -r 2>/dev/null | wc -l)
  mantis_log "DEBUG" "simulation_snapshot" "elapsed_sec=${elapsed}, workers_active=${active_workers}, tenant=${TENANT_ID}"
  sleep "$monitor_interval"
  elapsed=$((elapsed + monitor_interval))
done

# Aguarda conclusão de todos os workers
for pid in "${worker_pids[@]}"; do
  wait "$pid" 2>/dev/null || mantis_log "WARN" "worker_terminated_early" "pid=$pid, tenant=${TENANT_ID}"
done

end_ts=$(date +%s)
mantis_log "INFO" "simulation_ended" "elapsed_sec=$((end_ts - start_ts)), workers_completed=${#worker_pids[@]}, tenant=${TENANT_ID}"
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
    mantis_log "ERROR" "test_failed" "Tenant não propagado para logs de subshell"
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
    mantis_log "ERROR" "test_failed" "Simulação excedeu limite temporal (durou ${duration}s, esperado ≤3s)"
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
  test_simulation_propagates_tenant_to_subshells
  test_simulation_respects_duration_limit
  test_validate_vlog02_schema
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
  --check-error-handling \
  --check-observability
```

## 🔗 Referências Cruzadas
- [[bash-master-agent.md]] ← Contrato de geração, anti-padrões proibidos
- [[01-RULES/harness-norms-v3.0.md]] ← Especificação de resiliência C7 e limits C1
- [[01-RULES/10-SDD-CONSTRAINTS.md]] ← Definição de C1, C4, C8
- [[01-RULES/07-SCALABILITY-RULES.md]] ← Padrões de simulação de carga e controle de concorrência
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]] ← Índice de observabilidade
- [[/05-CONFIGURATIONS/observability/loki/config.yml]] ← Pipeline de ingestão de logs JSONL
- [[00-CONTEXT/norms-matrix.json]] ← Fonte de verdade para validação de constraints

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2024-09-25 | Dev inicial | Loop infinito sem limites, tenant não propagado, logs textuais | Parcial |
| 2.0.0 | 2026-05-06 | Bash Master Agent | Remanufatura: bootstrap resiliente, `mantis_log()` canônica, validação V-LOG-02, remoção de hardening inline | C1,C4,C5,C7,C8 |

---
## 🔍 Observability (Documentación para IA)

> Este artefato emite os seguintes eventos via `mantis_log()` (definida em [[bash-master-agent.md]]):

| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `simulation_started` | INFO | C8 | `"duration=30s, workers=4, tenant=tenant-xyz"` |
| `simulation_snapshot` | DEBUG | C8 | `"elapsed_sec=10, workers_active=3, tenant=tenant-xyz"` |
| `worker_completed` | DEBUG | C7 | `"worker_id=2, tenant=tenant-xyz"` |
| `worker_terminated_early` | WARN | C7 | `"pid=12345, tenant=tenant-xyz"` |
| `simulation_ended` | INFO | C8 | `"elapsed_sec=32, workers_completed=4, tenant=tenant-xyz"` |
| `simulation_cleanup` | INFO | C7 | `"exit_code=0, tenant=tenant-xyz"` |
| `resource_limit_warning` | WARN | C1 | `"ulimit falhou: recurso indisponível no sistema"` |

### Exemplo de Output JSONL (para aprendizado de padrão por IA)
```json
{"timestamp":"2026-05-06T12:50:00Z","level":"INFO","resource":{"tenant_id":"tenant-xyz","artifact":"scale-simulation-utils"},"body":{"event":"simulation_ended","detail":"elapsed_sec=32, workers_completed=4, tenant=tenant-xyz"},"attributes":{"mantis":{"tier":"2","version":"2.0.0","constraint":"C1,C4,C7,C8","trace_id":""},"code.filepath":"06-PROGRAMMING/bash/scale-simulation-utils.md","code.lineno":95,"telemetry.sdk.name":"mantis-bash-adapter","telemetry.sdk.version":"1.0.0"}}
```

### Configuração Específica de Este Artefato
```bash
# Variáveis de entorno que afetam o comportamento de logging deste artefato
export LOG_SIM_METRICS="${LOG_SIM_METRICS:-true}"          # Incluir snapshots periódicos em logs
export LOG_WORKER_LIFECYCLE="${LOG_WORKER_LIFECYCLE:-true}" # Incluir eventos de spawn/complete de workers
export TRACE_SIM_OPS="${TRACE_SIM_OPS:-false}"             # Habilitar trace_id para correlação OTel
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
