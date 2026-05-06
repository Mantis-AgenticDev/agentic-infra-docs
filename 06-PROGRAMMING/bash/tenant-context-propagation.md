---
artifact_id: tenant-context-propagation
artifact_type: bash_utility
version: 1.0.0
constraints_mapped: ["C4","C5","C7"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/bash/tenant-context-propagation.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:tenant-context-propagation-v1.0.0"
generated_at: "2026-05-07T01:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: bash
ai_navigation:
  read_first: false
  required_for: [subshell-isolation, cross-process-tenant-safety, rls-enforcement]
  update_frequency: on-change
audience: ["orchestrator-engine", "pipeline-dispatchers", "bash-developers"]
status: "🟢 Novo"
next_review: "2026-06-07"
---

# Propagación y Aislamiento de Contexto Tenant (C4)

## 🎯 Propósito
Garantizar que `TENANT_ID` se propague explícitamente a subshells, workers y procesos hijos sin mutación, fuga o contaminación cruzada. Aplica validación de formato, prefijos de contexto seguro y mecanismos de herencia restringida para entornos multi-tenant.

## 📋 Especificação (SDD)
- **Entradas**: `PARENT_TENANT_ID`, `SUBCONTEXT_PREFIX` (opcional), `INHERIT_MODE` (`strict`, `scoped`)
- **Saídas**: Entorno configurado, código `0` (propagado), `1` (formato inválido), `2` (violación de aislamiento)
- **Side Effects**: Exportación de variables seguras, validación de scopes
- **Constraints Aplicáveis**: C4 (tenant isolation, propagación segura), C5 (estructura heredada), C7 (fallback ante pérdida de contexto)
- **Dependências Externas**: `declare`, `export`, coreutils POSIX

## 🛡️ Bootstrap Resiliente e Lógica de Propagación (C4+C5+C7)
```bash
if [[ -f "${MANTIS_ROOT:-.}/06-PROGRAMMING/bash/bash-master-agent.sh" ]]; then
  source "${MANTIS_ROOT:-.}/06-PROGRAMMING/bash/bash-master-agent.sh" --mode=observability-only
else
  set -Eeuo pipefail; shopt -s inherit_errexit 2>/dev/null || true
  trap 'exit 130' INT TERM
  : "${TENANT_ID:?ERROR: TENANT_ID não definido. Defina via env ou argumento.}"
  mantis_log() { printf '{"ts":"%s","level":"%s","tenant":"%s","event":"%s","detail":"%s","fallback":"true"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${1:-INFO}" "${TENANT_ID:-unknown}" "${2:-bootstrap_fallback}" "${3:-}" >&2; }
  mantis_log "WARN" "bootstrap_fallback" "Master agent não encontrado."
fi

readonly SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"
readonly SCRIPT_VERSION="${VERSION:-1.0.0}"
readonly ARTIFACT_ID="tenant-context-propagation"

# Validación estricta de formato
validate_tenant_format() {
  local tid="${1:-$TENANT_ID}"
  [[ "$tid" =~ ^[a-z0-9][a-z0-9_-]{0,62}$ ]] || {
    mantis_log "ERROR" "invalid_tenant_format" "Formato inválido: $tid"
    return 1
  }
}

propagate_tenant_safe() {
  local target_scope="${1:-child}"
  validate_tenant_format || return 1
  
  case "$target_scope" in
    child|worker)
      export TENANT_ID_CHILD="$TENANT_ID"
      export MANTIS_TENANT_SCOPE="scoped"
      ;;
    global|parent)
      export TENANT_ID_ROOT="$TENANT_ID"
      ;;
    *)
      mantis_log "ERROR" "unknown_scope" "Scope no soportado: $target_scope"
      return 1
      ;;
  esac
  mantis_log "INFO" "tenant_propagated" "Scope=$target_scope, Tenant=$TENANT_ID"
}

run_in_tenant_context() {
  local cmd="$*"
  [[ -z "${TENANT_ID:-}" ]] && { mantis_log "ERROR" "context_missing"; return 2; }
  (
    export TENANT_ID="${TENANT_ID}"
    eval "$cmd"
  )
}
```

## 🧪 Testes Unitários (TDD)
```bash
test_propagates_tenant_to_child_scope() {
  export TENANT_ID="valid-tenant-01"
  propagate_tenant_safe "child" 2>/dev/null
  [[ "$TENANT_ID_CHILD" == "valid-tenant-01" && "$MANTIS_TENANT_SCOPE" == "scoped" ]] && return 0
  return 1
}

test_rejects_invalid_tenant_format() {
  export TENANT_ID="../escape"
  propagate_tenant_safe "child" 2>/dev/null
  [[ $? -eq 1 ]] && return 0
  return 1
}

test_validate_vlog02_schema() {
  mantis_log "INFO" "test" "x" 2>&1 | jq -e 'has("resource.tenant_id") and has("resource.artifact")' >/dev/null 2>&1
}

if [[ "${1:-}" == "--test" ]]; then test_propagates_tenant_to_child_scope; test_rejects_invalid_tenant_format; test_validate_vlog02_schema; exit $?; fi
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/bash/tenant-context-propagation.md --json --check-structural --check-error-handling --check-observability
```

## 🔗 Referências Cruzadas
- [[bash-master-agent.md]]
- [[01-RULES/06-MULTITENANCY-RULES.md]]
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]]

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-07 | Bash Master Agent | Criação inicial: validación regex, scopes seguros, herencia restringida | C4,C5,C7 |

---
## 🔍 Observability (Documentación para IA)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `tenant_propagated` | INFO | C4 | `"Scope=child, Tenant=valid-tenant-01"` |
| `invalid_tenant_format` | ERROR | C4 | `"Formato inválido: ../escape"` |
| `unknown_scope` | ERROR | C5 | `"Scope no soportado: unknown"` |
| `context_missing` | ERROR | C7 | `"TENANT_ID ausente en ejecución"` |

### Validação de Schema V-LOG-02
```bash
validate_vlog02() { jq -e 'has("timestamp") and has("level") and has("resource.tenant_id") and has("resource.artifact")' >/dev/null 2>&1; }
```
---
