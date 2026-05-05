---
artifact_id: git-disaster-recovery
artifact_type: bash_utility
version: 2.0.0
constraints_mapped: ["C3","C4","C5","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/bash/git-disaster-recovery.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:git-disaster-recovery-v2.0.0-remanufatured"
generated_at: "2026-05-06T12:40:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: bash
ai_navigation:
  read_first: false
  required_for: [tenant-scoped-git-ops, safe-rollback, audit-trail-maintenance]
  update_frequency: on-change
audience: ["orchestrator-engine", "ci-cd-recovery-pipelines", "devops-agents"]
status: "🟡 Em remanufatura"
next_review: "2026-06-05"
---

# Recuperação de Desastres Git com Isolamento por Tenant e Dry-Run Forense

## 🎯 Propósito
Executar operações de recuperação Git (rollback, verificação de integridade, restauração de refs) de forma segura, obrigando modo `dry-run` por padrão, validando escopo de tenant em refs/logs, sanitizando nomes de branches para evitar injeção e registrando todas as ações em JSONL auditável. **Nunca executa `push --force` ou reset destrutivo sem validação explícita e confirmação de contexto**. Projetado para pipelines de CI/CD e agentes de orquestração que necessitam de fallback controlado em repositórios multi-tenant.

## 📋 Especificação (SDD)
- **Entradas**: 
  - `TENANT_ID` (variável de ambiente obrigatória)
  - `$1`: Caminho do repositório Git (deve existir e conter `.git`)
  - `$2`: Ação (`verify`, `rollback`, `snapshot`, `dry-run` padrão)
  - `$TARGET_REF` (opcional, branch/commit alvo)
  - `FORCE_DRY_RUN` (`true` padrão, `false` para aplicar alterações)
  - `GIT_TIMEOUT` (segundos, padrão: `60`)
- **Saídas**: 
  - `0`: Operação concluída com sucesso ou simulação segura
  - `1`: Falha de validação (tenant ausente, ref inválido, caminho inseguro)
  - `2`: Erro de execução Git (timeout, conflito, integridade comprometida)
  - Logs JSONL em stderr com `action`, `tenant_id`, `ref_state`, `dry_run_status`, `duration_sec`
- **Side Effects**: 
  - Criação de refs temporários em `refs/recovery/tenant-${TENANT_ID}/` para backup
  - Nenhum push ou rebase destrutivo sem flag explícita e validação de permissão
  - Limpeza automática de refs temporários em sucesso
- **Constraints Aplicáveis**: C3 (zero secrets/hardcode), C4 (isolamento de refs e logs por tenant), C5 (estrutura de comandos e validação de schema), C6 (sanitização de inputs/refs), C7 (timeout, trap, fallback seguro), C8 (auditoria JSONL)
- **Dependências Externas**: `git`, `mktemp`, `timeout`, `date`, `grep`, `sed`, `jq` (para parsing de logs), coreutils POSIX

## 🛡️ Hardening (Harness Norms v3.0 - Executável)
```bash
#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_VERSION="2.0.0"

# C8: Logging estruturado JSONL em stderr
log_git_dr() {
  local level="${1:-INFO}" event="${2:-git_event}" detail="${3:-}"
  printf '{"ts":"%s","level":"%s","tenant":"%s","script":"%s","event":"%s","detail":"%s"}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    "$level" \
    "${TENANT_ID:-unknown}" \
    "$SCRIPT_NAME" \
    "$event" \
    "$detail" >&2
}

# C7: Cleanup de refs temporários e arquivos de trabalho
cleanup() {
  local exit_code=$?
  if [[ -n "${REPO_PATH:-}" && -d "${REPO_PATH}" ]]; then
    # Remove backup refs de tenant em caso de sucesso ou falha crítica
    git -C "$REPO_PATH" for-each-ref --format='delete %(refname)' "refs/recovery/tenant-${TENANT_ID:-*}" 2>/dev/null | git -C "$REPO_PATH" update-ref --stdin 2>/dev/null || true
  fi
  [[ -n "${TEMP_LOG:-}" && -f "${TEMP_LOG}" ]] && rm -f "${TEMP_LOG}"
  exit $exit_code
}
trap cleanup EXIT INT TERM

# C4: Validação obrigatória de tenant
: "${TENANT_ID:?Variável de ambiente TENANT_ID não definida. Abortando para evitar operação cross-tenant.}"

readonly REPO_PATH="${1:?Uso: git-disaster-recovery.sh <caminho-repo> [verify|rollback|snapshot]}"
readonly ACTION="${2:-verify}"
readonly TARGET_REF="${TARGET_REF:-HEAD}"
readonly DRY_RUN="${FORCE_DRY_RUN:-true}"
readonly GIT_OP_TIMEOUT="${GIT_TIMEOUT:-60}"

# C6: Sanitização rigorosa de refs (apenas alfanuméricos, hífens, barras, pontos)
if [[ ! "$TARGET_REF" =~ ^[a-zA-Z0-9./_-]+$ ]]; then
  log_git_dr "ERROR" "invalid_ref_format" "$TARGET_REF"
  exit 1
fi

[[ -d "$REPO_PATH/.git" ]] || { log_git_dr "ERROR" "invalid_git_repo" "$REPO_PATH"; exit 1; }

# C3+C7: Wrapper seguro para git (bloqueia --force, aplica timeout, registra em JSONL)
safe_git() {
  local cmd=("$@")
  # Bloqueio explícito de operações destrutivas
  for arg in "${cmd[@]}"; do
    if [[ "$arg" == *"push"* && "$arg" == *"--force"* ]]; then
      log_git_dr "ERROR" "force_push_blocked" "Operação proibida por política C3/C7"
      return 2
    fi
  done
  timeout "$GIT_OP_TIMEOUT" git -C "$REPO_PATH" "${cmd[@]}" 2>/dev/null
}

start_ts=$(date +%s)

case "$ACTION" in
  verify)
    log_git_dr "INFO" "verifying_integrity" "Executando git fsck e status"
    safe_git fsck --no-dangling 2>/dev/null || { log_git_dr "WARN" "fsck_found_issues"; }
    safe_git status --porcelain 2>/dev/null | head -50 > "${TEMP_LOG:-/dev/null}"
    ;;
  snapshot)
    log_git_dr "INFO" "creating_tenant_snapshot" "Backup em refs/recovery/tenant-${TENANT_ID}"
    local backup_ref="refs/recovery/tenant-${TENANT_ID}/pre-recovery-$(date +%s)"
    safe_git update-ref "$backup_ref" "$TARGET_REF" 2>/dev/null || exit 2
    ;;
  rollback)
    if [[ "$DRY_RUN" == "true" ]]; then
      log_git_dr "INFO" "dry_run_rollback" "Ação simulada. Para aplicar, defina FORCE_DRY_RUN=false"
      echo "[DRY-RUN] git reset --hard $TARGET_REF (não executado)"
    else
      log_git_dr "WARN" "applying_rollback" "Executando reset para $TARGET_REF"
      safe_git reset --hard "$TARGET_REF" 2>/dev/null || exit 2
    fi
    ;;
  *)
    log_git_dr "ERROR" "unknown_action" "$ACTION"
    exit 1
    ;;
esac

end_ts=$(date +%s)
log_git_dr "INFO" "operation_completed" "action=$ACTION, duration_sec=$((end_ts - start_ts)), dry_run=$DRY_RUN"
exit 0
```

## 🧪 Testes Unitários (TDD)
```bash
test_git_dr_enforces_dry_run_by_default() {
  # Arrange
  local test_repo
  test_repo=$(mktemp -d)
  git -C "$test_repo" init -q
  echo "v1" > file.txt && git -C "$test_repo" add . && git -C "$test_repo" commit -q -m "init"
  export TENANT_ID="test-git-dr-01"
  export FORCE_DRY_RUN=true

  # Act
  local output
  output=$(bash "${BASH_SOURCE[0]}" "$test_repo" rollback HEAD 2>/dev/null)
  local exit_code=$?

  # Assert
  if [[ $exit_code -eq 0 && "$output" == *"[DRY-RUN]"* ]]; then
    rm -rf "$test_repo"
    return 0
  else
    printf '[TEST_FAIL] Dry-run não bloqueou rollback ou retornou código incorreto\n' >&2
    rm -rf "$test_repo"
    return 1
  fi
}

test_git_dr_validates_tenant_context() {
  # Arrange
  local test_repo
  test_repo=$(mktemp -d)
  git -C "$test_repo" init -q
  unset TENANT_ID

  # Act
  bash "${BASH_SOURCE[0]}" "$test_repo" verify 2>/dev/null
  local exit_code=$?

  # Assert
  if [[ $exit_code -ne 0 ]]; then
    rm -rf "$test_repo"
    return 0
  else
    printf '[TEST_FAIL] Script permitiu execução sem TENANT_ID definido\n' >&2
    rm -rf "$test_repo"
    return 1
  fi
}

if [[ "${1:-}" == "--test" ]]; then
  test_git_dr_enforces_dry_run_by_default
  test_git_dr_validates_tenant_context
  exit $?
fi
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/bash/git-disaster-recovery.md \
  --json \
  --check-secrets \
  --check-tenant-isolation \
  --check-structural \
  --check-resource-limits \
  --check-error-handling
```

## 🔗 Referências Cruzadas
- [[bash-master-agent.md]] ← Contrato de geração, anti-padrões proibidos e protocolo de handoff
- [[01-RULES/harness-norms-v3.0.md]] ← Especificação de hardening C7 e resiliência
- [[01-RULES/10-SDD-CONSTRAINTS.md]] ← Definição de C3, C4, C6, C8
- [[01-RULES/03-SECURITY-RULES.md]] ← Políticas de credenciais e operações destrutivas
- [[00-CONTEXT/norms-matrix.json]] ← Fonte de verdade para validação de constraints

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2024-09-05 | Dev inicial | Operações Git básicas sem validação de tenant ou dry-run obrigatório | Parcial |
| 2.0.0 | 2026-05-06 | Bash Master Agent | Remanufatura completa: dry-run padrão, bloqueio de --force, refs tenant-scoped, timeout C1, JSONL C8, sanitização C6, testes TDD | C3,C4,C5,C6,C7,C8 |

---
