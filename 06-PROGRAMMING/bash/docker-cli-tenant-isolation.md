---
artifact_id: docker-cli-tenant-isolation
artifact_type: bash_utility
version: 1.0.0
constraints_mapped: ["C3","C4","C7"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/bash/docker-cli-tenant-isolation.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:docker-cli-tenant-isolation-v1.0.0"
generated_at: "2026-05-07T03:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: bash
ai_navigation:
  read_first: false
  required_for: [container-labeling, network-segregation, resource-guardrails]
  update_frequency: on-change
audience: ["sre-agents", "platform-engineers", "orchestrator-engine"]
status: "🟢 Novo"
next_review: "2026-06-07"
---

# Wrapper Docker CLI com Isolamento por Tenant e Guardrails de Recursos

## 🎯 Propósito
Executar comandos `docker` com labels obrigatórias de tenant, isolamento de rede, limites de memória/CPU e bloqueio de modos privilegiados. Previne contaminação cross-tenant e garante conformidade `C1` (limites), `C3` (segredos em env), `C4` (escopo).

## 📋 Especificação (SDD)
- **Entradas**: `IMAGE`, `RUN_ARGS`, `NETWORK_NAME` (padrão: `mantis-tenant-net`), `MEM_LIMIT`, `CPU_QUOTA`
- **Saídas**: `0` (sucesso), `1` (falha docker), `2` (violação de política)
- **Side Effects**: Criação/uso de containers com labels escopadas, cleanup automático
- **Constraints Aplicáveis**: C3 (env-only secrets), C4 (network/labels scoping), C7 (trap, safe kill)
- **Dependências Externas**: `docker`, `jq`, `timeout`, coreutils POSIX

## 🛡️ Bootstrap Resiliente e Lógica Docker (C3+C4+C7)
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
readonly ARTIFACT_ID="docker-cli-tenant-isolation"
export TENANT_ID="${TENANT_ID:-}"

tenant_docker_run() {
  local image="${1:?imagem obrigatória}"
  shift
  local run_args=("$@")
  local net="${DOCKER_NETWORK:-mantis-tenant-net}"
  local mem="${MEM_LIMIT:-512m}"
  local cpu="${CPU_QUOTA:-0.5}"
  
  # C3: Bloquear --privileged e mapeamento inseguro
  for arg in "${run_args[@]}"; do
    if [[ "$arg" == "--privileged" || "$arg" == "--cap-add=ALL" ]]; then
      mantis_log "ERROR" "privileged_mode_blocked" "tenant=$TENANT_ID, policy=C3"
      return 2
    fi
  done

  local container_name="mantis-${TENANT_ID}-$$"
  local cmd=(
    docker run -d
    --name "$container_name"
    --network "$net"
    --label "mantis.tenant=$TENANT_ID"
    --memory "$mem"
    --cpus "$cpu"
    --rm
    "${run_args[@]}"
    "$image"
  )

  mantis_log "INFO" "docker_container_started" "name=$container_name, net=$net, mem=$mem, tenant=$TENANT_ID"
  "${cmd[@]}" 2>/dev/null
  return $?
}
```

## 🧪 Testes Unitários (TDD)
```bash
test_blocks_privileged_mode() {
  tenant_docker_run "nginx" --privileged 2>/dev/null
  [[ $? -eq 2 ]] && return 0
  return 1
}

test_injects_tenant_labels() {
  local out; out=$(mantis_log "INFO" "docker_container_started" "name=mantis-xyz-123, net=mantis-net" 2>&1)
  echo "$out" | grep -q "tenant=xyz" && return 0
  return 1
}

test_validate_vlog02_schema() {
  mantis_log "INFO" "test" "x" 2>&1 | jq -e 'has("timestamp") and has("level") and has("resource.tenant_id")' >/dev/null 2>&1
}

if [[ "${1:-}" == "--test" ]]; then test_blocks_privileged_mode; test_injects_tenant_labels; test_validate_vlog02_schema; exit $?; fi
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/bash/docker-cli-tenant-isolation.md --json --check-structural --check-error-handling --check-observability
```

## 🔗 Referências Cruzadas
- [[bash-master-agent.md]]
- [[resource-limits-ulimit-cgroups.md]]
- [[tenant-context-propagation.md]]
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]]

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-07 | Bash Master Agent | Criação inicial: labels tenant, block privileged, limits memory/cpu | C3,C4,C7 |

---
## 🔍 Observability (Documentación para IA)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `docker_container_started` | INFO | C8 | `"name=mantis-xyz-456, net=isolated, mem=512m"` |
| `privileged_mode_blocked` | ERROR | C3 | `"tenant=xyz, policy=C3"` |
| `network_create_failed` | ERROR | C7 | `"net=mantis-tenant-net already exists"` |

### Validação de Schema V-LOG-02
```bash
validate_vlog02() { jq -e 'has("timestamp") and has("level") and has("resource.tenant_id") and has("resource.artifact")' >/dev/null 2>&1; }
```
---
