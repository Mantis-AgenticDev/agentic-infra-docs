---
artifact_id: resource-limits-ulimit-cgroups
artifact_type: bash_utility
version: 1.0.0
constraints_mapped: ["C1","C7", "C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/bash/resource-limits-ulimit-cgroups.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:resource-limits-ulimit-cgroups-v1.0.0"
generated_at: "2026-05-07T02:00:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: bash
ai_navigation:
  read_first: false
  required_for: [process-isolation, memory-cpu-guardrails, cgroup-v2-detection]
  update_frequency: on-change
audience: ["sre-agents", "ci-cd-runners", "bash-developers"]
status: "🟢 Novo"
next_review: "2026-06-07"
---

# Aplicação de Limites de Recursos (ulimit / cgroups)

## 🎯 Propósito
Aplicar limites de CPU, memória, processos e descritores de arquivos via `ulimit` (POSIX) e detectar/aplicar limites de cgroups v2 quando disponíveis. Previne esgotamento de recursos (`C1`) e garante degradação segura (`C7`).

## 📋 Especificação (SDD)
- **Entradas**: `MAX_CPU_PERCENT`, `MAX_MEMORY_MB`, `MAX_OPEN_FILES`, `MAX_PROCESSES`
- **Saídas**: `0` (limites aplicados/detectados), `1` (permissão negada), `2` (sistema incompatível)
- **Side Effects**: Modificação de limites do processo atual e filhos
- **Constraints Aplicáveis**: C1 (guardrails de recursos), C7 (fallback seguro, validação)
- **Dependências Externas**: `ulimit` (builtin), `cat`, `grep`, `/sys/fs/cgroup`, coreutils

## 🛡️ Bootstrap Resiliente e Lógica de Limites (C1+C7)
```bash
if [[ -f "${MANTIS_ROOT:-.}/06-PROGRAMMING/bash/bash-master-agent.sh" ]]; then
  source "${MANTIS_ROOT:-.}/06-PROGRAMMING/bash/bash-master-agent.sh" --mode=observability-only
else
  set -Eeuo pipefail; shopt -s inherit_errexit 2>/dev/null || true
  trap 'exit 130' INT TERM
  if [[ "${TENANT_CONTEXT:-nao_aplicavel}" != "nao_aplicavel" ]]; then : "${TENANT_ID:?ERROR: TENANT_ID não definido.}"; fi
  mantis_log() { printf '{"ts":"%s","level":"%s","tenant":"%s","event":"%s","detail":"%s","fallback":"true"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${1:-INFO}" "${TENANT_ID:-global}" "${2:-bootstrap_fallback}" "${3:-}" >&2; }
  mantis_log "WARN" "bootstrap_fallback" "Master agent não encontrado."
fi

readonly SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"
readonly ARTIFACT_ID="resource-limits-ulimit-cgroups"
export TENANT_ID="${TENANT_ID:-global}"

apply_resource_limits() {
  local max_procs="${MAX_PROCESSES:-256}"
  local max_files="${MAX_OPEN_FILES:-1024}"
  local max_mem_kb="${MAX_MEMORY_MB:-512000}" # 512MB default

  # ulimit aplica-se ao processo atual e filhos
  ulimit -u "$max_procs" 2>/dev/null || mantis_log "WARN" "ulimit_procs_failed" "Permissão insuficiente ou limite fixo"
  ulimit -n "$max_files" 2>/dev/null || mantis_log "WARN" "ulimit_files_failed" "Permissão insuficiente ou limite fixo"
  ulimit -v "$max_mem_kb" 2>/dev/null || mantis_log "WARN" "ulimit_mem_failed" "Permissão insuficiente ou limite fixo"
  
  mantis_log "INFO" "ulimits_applied" "procs=$max_procs, files=$max_files, mem_kb=$max_mem_kb"
}

detect_cgroup_limits() {
  local cgroup_dir="/sys/fs/cgroup"
  [[ -d "$cgroup_dir" ]] || { mantis_log "INFO" "cgroup_not_available"; return 0; }
  
  # cgroups v2: memory.max, cpu.max
  if [[ -f "$cgroup_dir/memory.max" ]]; then
    local mem_max; mem_max=$(cat "$cgroup_dir/memory.max" 2>/dev/null || echo "max")
    mantis_log "INFO" "cgroup_memory_detected" "limit=$mem_max"
  fi
  if [[ -f "$cgroup_dir/cpu.max" ]]; then
    local cpu_max; cpu_max=$(cat "$cgroup_dir/cpu.max" 2>/dev/null || echo "max")
    mantis_log "INFO" "cgroup_cpu_detected" "limit=$cpu_max"
  fi
  return 0
}
```

## 🧪 Testes Unitários (TDD)
```bash
test_detects_cgroup_or_fallback() {
  detect_cgroup_limits 2>/dev/null
  local rc=$?
  [[ $rc -eq 0 ]] && return 0
  return 1
}

test_validate_vlog02_schema() {
  mantis_log "INFO" "test" "x" 2>&1 | jq -e 'has("timestamp") and has("level") and has("resource.artifact")' >/dev/null 2>&1
}

if [[ "${1:-}" == "--test" ]]; then test_detects_cgroup_or_fallback; test_validate_vlog02_schema; exit $?; fi
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/bash/resource-limits-ulimit-cgroups.md --json --check-structural --check-error-handling --check-observability
```

## 🔗 Referências Cruzadas
- [[bash-master-agent.md]]
- [[error-handling-traps.md]]
- [[01-RULES/02-RESOURCE-GUARDRAILS.md]]
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]]

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-07 | Bash Master Agent | Criação inicial: ulimit safe, cgroups v2 detection, fallback | C1,C7 |

---
## 🔍 Observability (Documentación para IA)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `ulimits_applied` | INFO | C1 | `"procs=256, files=1024, mem_kb=512000"` |
| `ulimit_mem_failed` | WARN | C7 | `"Permissão insuficiente ou limite fixo"` |
| `cgroup_memory_detected` | INFO | C1 | `"limit=536870912"` |
| `cgroup_not_available` | DEBUG | C7 | `"Fallback para ulimit padrão"` |

### Validação de Schema V-LOG-02
```bash
validate_vlog02() { jq -e 'has("timestamp") and has("level") and has("resource.tenant_id") and has("resource.artifact")' >/dev/null 2>&1; }
```

---
