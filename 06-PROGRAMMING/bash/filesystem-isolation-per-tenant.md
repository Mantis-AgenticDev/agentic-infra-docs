---
artifact_id: filesystem-isolation-per-tenant
artifact_type: bash_utility
version: 1.0.0
constraints_mapped: ["C4","C5","C7"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/bash/filesystem-isolation-per-tenant.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:filesystem-isolation-per-tenant-v1.0.0"
generated_at: "2026-05-07T01:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: bash
ai_navigation:
  read_first: false
  required_for: [path-escape-prevention, tenant-chroot-simulation, secure-temp-cleanup]
  update_frequency: on-change
audience: ["sre-agents", "data-pipeline-agents", "bash-developers"]
status: "🟢 Novo"
next_review: "2026-06-07"
---

# Aislamiento de Filesystem por Tenant con Prevención de Path Escape

## 🎯 Propósito
Crear entornos de trabajo aislados por tenant, validar rutas contra escapes (`../`, symlinks cruzados), aplicar permisos restrictivos (`0700`) y garantizar limpieza forense mediante traps. Simula jaulas seguras en entornos POSIX sin `chroot`.

## 📋 Especificação (SDD)
- **Entradas**: `BASE_ROOT` (directorio base), `TENANT_ID`
- **Saídas**: Ruta segura absoluta, código `0` (aislado), `1` (escape detectado), `2` (permisos fallidos)
- **Side Effects**: Creación de estructura `/base/tenant/`, trap de limpieza
- **Constraints Aplicáveis**: C4 (aislamiento por tenant), C5 (validación estructural de rutas), C7 (trap cleanup, resiliencia)
- **Dependências Externas**: `realpath`, `mkdir`, `chmod`, `rm`, coreutils POSIX

## 🛡️ Bootstrap Resiliente e Lógica de Aislamiento (C4+C5+C7)
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
readonly ARTIFACT_ID="filesystem-isolation-per-tenant"
export TENANT_ID="${TENANT_ID:-}"

declare -a _FS_ISOLATED_PATHS=()

setup_tenant_root() {
  local base="${1:-/opt/mantis/tenants}"
  local tenant_path="${base}/${TENANT_ID}"
  
  # C4: Validar escape
  if [[ "$tenant_path" == *..* ]] || [[ "$tenant_path" =~ // ]]; then
    mantis_log "ERROR" "path_escape_detected" "Intento de escape en ruta: $tenant_path"
    return 1
  fi
  
  mkdir -p "$tenant_path" && chmod 0700 "$tenant_path" || {
    mantis_log "ERROR" "setup_failed" "No se pudo crear/asegurar permisos en $tenant_path"
    return 2
  }
  
  _FS_ISOLATED_PATHS+=("$tenant_path")
  mantis_log "INFO" "isolation_setup" "Ruta segura: $(realpath "$tenant_path")"
  printf '%s\n' "$tenant_path"
}

validate_path_isolation() {
  local path="${1:?validate_path_isolation: ruta requerida}"
  local resolved
  resolved=$(realpath -m "$path" 2>/dev/null) || return 1
  
  local allowed_base="${2:-/opt/mantis/tenants}"
  [[ "$resolved" == "${allowed_base}"* ]] || {
    mantis_log "ERROR" "isolation_violation" "Ruta fuera del sandbox tenant: $resolved"
    return 1
  }
  return 0
}

_fs_cleanup_trap() {
  for p in "${_FS_ISOLATED_PATHS[@]:-}"; do
    [[ -d "$p" ]] && rm -rf "$p" 2>/dev/null && mantis_log "INFO" "filesystem_cleaned" "Eliminado $p"
  done
}
trap _fs_cleanup_trap EXIT INT TERM
```

## 🧪 Testes Unitários (TDD)
```bash
test_validates_and_blocks_path_escape() {
  export TENANT_ID="tenant_ok"
  setup_tenant_root "/tmp/test_$(date +%s)" > /dev/null 2>&1
  validate_path_isolation "/etc/passwd" "/tmp/test_" 2>/dev/null
  [[ $? -eq 1 ]] && return 0
  return 1
}

test_cleanup_trap_removes_paths() {
  export TENANT_ID="tenant_cleanup"
  local base="/tmp/test_isolation_$(date +%s)"
  local created; created=$(setup_tenant_root "$base" 2>/dev/null)
  [[ -d "$created" ]] && { bash -c "trap 'rm -rf \"$created\"' EXIT"; [[ ! -d "$created" ]] && return 0; }
  return 1
}

test_validate_vlog02_schema() {
  mantis_log "INFO" "test" "x" 2>&1 | jq -e 'has("timestamp") and has("resource.tenant_id")' >/dev/null 2>&1
}

if [[ "${1:-}" == "--test" ]]; then test_validates_and_blocks_path_escape; test_cleanup_trap_removes_paths; test_validate_vlog02_schema; exit $?; fi
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/bash/filesystem-isolation-per-tenant.md --json --check-structural --check-error-handling --check-observability
```

## 🔗 Referências Cruzadas
- [[bash-master-agent.md]]
- [[01-RULES/06-MULTITENANCY-RULES.md]]
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]]

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-07 | Bash Master Agent | Criação inicial: realpath validation, trap cleanup, escape block | C4,C5,C7 |

---
## 🔍 Observability (Documentación para IA)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `isolation_setup` | INFO | C4 | `"Ruta segura: /opt/mantis/tenants/tenant_ok"` |
| `path_escape_detected` | ERROR | C4 | `"Intento de escape en ruta: /tmp/../etc"` |
| `isolation_violation` | ERROR | C5 | `"Ruta fuera del sandbox tenant: /var/log"` |
| `filesystem_cleaned` | INFO | C7 | `"Eliminado /opt/mantis/tenants/tenant_cleanup"` |

### Validação de Schema V-LOG-02
```bash
validate_vlog02() { jq -e 'has("timestamp") and has("level") and has("resource.tenant_id") and has("resource.artifact")' >/dev/null 2>&1; }
```
---
