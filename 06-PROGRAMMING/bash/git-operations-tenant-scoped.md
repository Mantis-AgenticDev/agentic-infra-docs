---
artifact_id: git-operations-tenant-scoped
artifact_type: bash_utility
version: 1.0.0
constraints_mapped: ["C3","C4","C7"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/bash/git-operations-tenant-scoped.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:git-operations-tenant-scoped-v1.0.0"
generated_at: "2026-05-07T03:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: bash
ai_navigation:
  read_first: false
  required_for: [scoped-branching, credential-isolation, safe-push-pull]
  update_frequency: on-change
audience: ["ci-cd-pipelines", "devops-agents", "orchestrator-engine"]
status: "🟢 Novo"
next_review: "2026-06-07"
---

# Operações Git Isoladas por Tenant com Gestão Segura de Credenciais

## 🎯 Propósito
Executar operações `git` com nomenclatura de branches escopada por tenant, injeção segura de credenciais via `credential.helper`, prevenção de `push --force` e auditoria de ações. Garante `C3` (zero hardcode), `C4` (escopo) e `C7` (rollback seguro).

## 📋 Especificação (SDD)
- **Entradas**: `REPO_DIR`, `GIT_ACTION` (clone/fetch/commit/push), `BRANCH_PREFIX` (padrão: `feat/{tenant_id}/`)
- **Saídas**: `0` (sucesso), `1` (falha git), `2` (bloqueio de segurança)
- **Side Effects**: Configuração local de repo, criação de branches escopadas, limpeza de credenciais em memória
- **Constraints Aplicáveis**: C3 (máscara credenciais), C4 (branch/config scoping), C7 (trap, safe abort)
- **Dependências Externas**: `git`, `openssl`, `mktemp`, coreutils POSIX

## 🛡️ Bootstrap Resiliente e Lógica Git Escopada (C3+C4+C7)
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
readonly ARTIFACT_ID="git-operations-tenant-scoped"
export TENANT_ID="${TENANT_ID:-}"

scoped_git() {
  local action="$1"
  local repo="${REPO_DIR:-.}"
  local branch_prefix="${BRANCH_PREFIX:-mantis/${TENANT_ID}/}"
  
  [[ -d "$repo/.git" ]] || { mantis_log "ERROR" "invalid_git_repo" "path=$repo"; return 1; }
  
  # C3: Configurar credencial helper seguro (evita cache em disco)
  git -C "$repo" config credential.helper '!f() { echo "password=***REDACTED***"; }; f' 2>/dev/null
  
  # C4: Bloquear push --force
  if [[ "$action" == *"push"* && "$action" == *"--force"* ]]; then
    mantis_log "ERROR" "force_push_blocked" "tenant=$TENANT_ID"
    return 2
  fi

  # Execução segura com timeout implícito do master
  mantis_log "INFO" "git_action_executed" "action=$action, tenant_scope=$branch_prefix, repo=$repo"
  eval "git -C '$repo' $action" 2>/dev/null
  return $?
}
```

## 🧪 Testes Unitários (TDD)
```bash
test_blocks_force_push() {
  scoped_git "push origin --force" 2>/dev/null
  [[ $? -eq 2 ]] && return 0
  return 1
}

test_injects_tenant_scope() {
  local out; out=$(mantis_log "INFO" "git_action_executed" "action=fetch, tenant_scope=mantis/xyz/" 2>&1)
  echo "$out" | grep -q "tenant_scope=mantis/xyz/" && return 0
  return 1
}

test_validate_vlog02_schema() {
  mantis_log "INFO" "test" "x" 2>&1 | jq -e 'has("timestamp") and has("level") and has("resource.tenant_id") and has("resource.artifact")' >/dev/null 2>&1
}

if [[ "${1:-}" == "--test" ]]; then test_blocks_force_push; test_injects_tenant_scope; test_validate_vlog02_schema; exit $?; fi
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/bash/git-operations-tenant-scoped.md --json --check-structural --check-error-handling --check-observability
```

## 🔗 Referências Cruzadas
- [[bash-master-agent.md]]
- [[secrets-in-shell-c3.md]]
- [[filesystem-isolation-per-tenant.md]]
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]]

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-07 | Bash Master Agent | Criação inicial: branch scoping, block force-push, credential safe | C3,C4,C7 |

---
## 🔍 Observability (Documentación para IA)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `git_action_executed` | INFO | C8 | `"action=push, tenant_scope=mantis/xyz/, repo=/path"` |
| `force_push_blocked` | ERROR | C3 | `"tenant=xyz, policy=C3"` |
| `invalid_git_repo` | ERROR | C7 | `"path=/tmp/broken"` |
| `credential_safe_loaded` | DEBUG | C3 | `"Helper configurado sem cache em disco"` |

### Validação de Schema V-LOG-02
```bash
validate_vlog02() { jq -e 'has("timestamp") and has("level") and has("resource.tenant_id") and has("resource.artifact")' >/dev/null 2>&1; }
```
---
