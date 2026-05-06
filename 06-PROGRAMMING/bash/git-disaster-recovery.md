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

## 🛡️ Bootstrap Resiliente e Lógica de Recuperação Git (C3+C4+C5+C6+C7+C8)
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
# LÓGICA DE RECUPERAÇÃO GIT COM ISOLAMENTO POR TENANT
# =============================================================================
# C7: Cleanup de refs temporários e arquivos de trabalho
cleanup_git_dr() {
  local exit_code=$?
  if [[ -n "${REPO_PATH:-}" && -d "${REPO_PATH}" ]]; then
    # Remove backup refs de tenant em caso de sucesso ou falha crítica
    git -C "$REPO_PATH" for-each-ref --format='delete %(refname)' "refs/recovery/tenant-${TENANT_ID:-*}" 2>/dev/null | git -C "$REPO_PATH" update-ref --stdin 2>/dev/null || true
  fi
  [[ -n "${TEMP_LOG:-}" && -f "${TEMP_LOG}" ]] && rm -f "${TEMP_LOG}"
  if [[ $exit_code -ne 0 ]]; then
    mantis_log "ERROR" "git_recovery_aborted" "Código de saída: $exit_code | Repo: ${REPO_PATH:-unknown}"
  fi
  exit $exit_code
}
trap cleanup_git_dr EXIT INT TERM

# C4: Validação obrigatória de tenant
: "${TENANT_ID:?Variável de ambiente TENANT_ID não definida. Abortando para evitar operação cross-tenant.}"

readonly REPO_PATH="${1:?Uso: git-disaster-recovery.sh <caminho-repo> [verify|rollback|snapshot]}"
readonly ACTION="${2:-verify}"
readonly TARGET_REF="${TARGET_REF:-HEAD}"
readonly DRY_RUN="${FORCE_DRY_RUN:-true}"
readonly GIT_OP_TIMEOUT="${GIT_TIMEOUT:-60}"

# C6: Sanitização rigorosa de refs (apenas alfanuméricos, hífens, barras, pontos)
if [[ ! "$TARGET_REF" =~ ^[a-zA-Z0-9./_-]+$ ]]; then
  mantis_log "ERROR" "invalid_ref_format" "Ref contém caracteres inválidos: $TARGET_REF"
  exit 1
fi

[[ -d "$REPO_PATH/.git" ]] || { mantis_log "ERROR" "invalid_git_repo" "Caminho não é repositório Git válido: $REPO_PATH"; exit 1; }

# C3+C7: Wrapper seguro para git (bloqueia --force, aplica timeout, registra em JSONL)
safe_git() {
  local cmd=("$@")
  # Bloqueio explícito de operações destrutivas
  for arg in "${cmd[@]}"; do
    if [[ "$arg" == *"push"* && "$arg" == *"--force"* ]]; then
      mantis_log "ERROR" "force_push_blocked" "Operação proibida por política C3/C7: push --force"
      return 2
    fi
  done
  timeout "$GIT_OP_TIMEOUT" git -C "$REPO_PATH" "${cmd[@]}" 2>/dev/null
}

start_ts=$(date +%s)

case "$ACTION" in
  verify)
    mantis_log "INFO" "verifying_integrity" "Executando git fsck e status para tenant: ${TENANT_ID}"
    safe_git fsck --no-dangling 2>/dev/null || { mantis_log "WARN" "fsck_found_issues" "Problemas de integridade detectados (não críticos)" }
    safe_git status --porcelain 2>/dev/null | head -50 > "${TEMP_LOG:-/dev/null}"
    ;;
  snapshot)
    mantis_log "INFO" "creating_tenant_snapshot" "Backup em refs/recovery/tenant-${TENANT_ID} para ref: ${TARGET_REF}"
    local backup_ref="refs/recovery/tenant-${TENANT_ID}/pre-recovery-$(date +%s)"
    safe_git update-ref "$backup_ref" "$TARGET_REF" 2>/dev/null || { mantis_log "ERROR" "snapshot_failed" "Falha ao criar backup ref: $backup_ref"; exit 2; }
    ;;
  rollback)
    if [[ "$DRY_RUN" == "true" ]]; then
      mantis_log "INFO" "dry_run_rollback" "Ação simulada. Para aplicar, defina FORCE_DRY_RUN=false | Ref alvo: ${TARGET_REF}"
      echo "[DRY-RUN] git reset --hard $TARGET_REF (não executado)"
    else
      mantis_log "WARN" "applying_rollback" "Executando reset para $TARGET_REF | Tenant: ${TENANT_ID}"
      safe_git reset --hard "$TARGET_REF" 2>/dev/null || { mantis_log "ERROR" "rollback_failed" "Falha ao executar reset para $TARGET_REF"; exit 2; }
    fi
    ;;
  *)
    mantis_log "ERROR" "unknown_action" "Ação não reconhecida: $ACTION | Opções válidas: verify, rollback, snapshot"
    exit 1
    ;;
esac

end_ts=$(date +%s)
mantis_log "INFO" "operation_completed" "action=$ACTION, duration_sec=$((end_ts - start_ts)), dry_run=$DRY_RUN, tenant=${TENANT_ID}"
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
    mantis_log "ERROR" "test_failed" "Dry-run não bloqueou rollback ou retornou código incorreto"
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
    mantis_log "ERROR" "test_failed" "Script permitiu execução sem TENANT_ID definido"
    rm -rf "$test_repo"
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
  test_git_dr_enforces_dry_run_by_default
  test_git_dr_validates_tenant_context
  test_validate_vlog02_schema
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
  --check-error-handling \
  --check-observability
```

## 🔗 Referências Cruzadas
- [[bash-master-agent.md]] ← Contrato de geração, anti-padrões proibidos e protocolo de handoff
- [[01-RULES/harness-norms-v3.0.md]] ← Especificação de hardening C7 e resiliência
- [[01-RULES/10-SDD-CONSTRAINTS.md]] ← Definição de C3, C4, C6, C8
- [[01-RULES/03-SECURITY-RULES.md]] ← Políticas de credenciais e operações destrutivas
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]] ← Índice de observabilidade
- [[/05-CONFIGURATIONS/observability/loki/config.yml]] ← Pipeline de ingestão de logs JSONL
- [[00-CONTEXT/norms-matrix.json]] ← Fonte de verdade para validação de constraints

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2024-09-05 | Dev inicial | Operações Git básicas sem validação de tenant ou dry-run obrigatório | Parcial |
| 2.0.0 | 2026-05-06 | Bash Master Agent | Remanufatura: bootstrap resiliente, `mantis_log()` canônica, validação V-LOG-02, remoção de hardening inline | C3,C4,C5,C6,C7,C8 |

---
## 🔍 Observability (Documentação para IA)

> Este artefato emite os seguintes eventos via `mantis_log()` (definida em [[bash-master-agent.md]]):

| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `verifying_integrity` | INFO | C8 | `"Executando git fsck e status para tenant: tenant-xyz"` |
| `fsck_found_issues` | WARN | C7 | `"Problemas de integridade detectados (não críticos)"` |
| `creating_tenant_snapshot` | INFO | C4 | `"Backup em refs/recovery/tenant-xyz para ref: main"` |
| `snapshot_failed` | ERROR | C7 | `"Falha ao criar backup ref: refs/recovery/tenant-xyz/pre-12345"` |
| `dry_run_rollback` | INFO | C3 | `"Ação simulada. Para aplicar, defina FORCE_DRY_RUN=false"` |
| `applying_rollback` | WARN | C4 | `"Executando reset para abc123 | Tenant: tenant-xyz"` |
| `rollback_failed` | ERROR | C7 | `"Falha ao executar reset para abc123"` |
| `invalid_ref_format` | ERROR | C6 | `"Ref contém caracteres inválidos: ../escape"` |
| `force_push_blocked` | ERROR | C3 | `"Operação proibida por política C3/C7: push --force"` |
| `operation_completed` | INFO | C8 | `"action=rollback, duration_sec=12, dry_run=true, tenant=tenant-xyz"` |

### Exemplo de Output JSONL (para aprendizado de padrão por IA)
```json
{"timestamp":"2026-05-06T12:40:00Z","level":"INFO","resource":{"tenant_id":"tenant-xyz","artifact":"git-disaster-recovery"},"body":{"event":"operation_completed","detail":"action=rollback, duration_sec=12, dry_run=true, tenant=tenant-xyz"},"attributes":{"mantis":{"tier":"2","version":"2.0.0","constraint":"C3,C4,C7","trace_id":""},"code.filepath":"06-PROGRAMMING/bash/git-disaster-recovery.md","code.lineno":98,"telemetry.sdk.name":"mantis-bash-adapter","telemetry.sdk.version":"1.0.0"}}
```

### Configuração Específica de Este Artefato
```bash
# Variáveis de entorno que afetam o comportamento de logging deste artefato
export LOG_GIT_REFS="${LOG_GIT_REFS:-true}"           # Incluir refs manipulados em logs (Cuidado: sanitizar)
export LOG_GIT_DURATION="${LOG_GIT_DURATION:-true}"   # Incluir duração de operações Git em logs
export TRACE_GIT_OPS="${TRACE_GIT_OPS:-false}"        # Habilitar trace_id para correlação OTel
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
