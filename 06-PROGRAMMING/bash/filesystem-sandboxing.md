---
artifact_id: filesystem-sandboxing
artifact_type: bash_utility
version: 2.0.0
constraints_mapped: ["C1","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/bash/filesystem-sandboxing.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:filesystem-sandboxing-v2.0.0-remanufatured"
generated_at: "2026-05-06T12:10:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: bash
ai_navigation:
  read_first: false
  required_for: [tenant-isolation, safe-execution, temp-data-management]
  update_frequency: on-change
audience: ["orchestrator-engine", "deployment-scripts", "data-processing-agents"]
status: "🟡 Em remanufatura"
next_review: "2026-06-05"
---

# Isolamento de Sistema de Arquivos por Tenant (Sandboxing)

## 🎯 Propósito
Criar e gerenciar espaços de trabalho temporários isolados por `TENANT_ID`, impedindo vazamento de dados entre tenants, garantindo permissões restritas (`0700`), validando espaço em disco antes da criação e assegurando limpeza automática em caso de sucesso, falha ou interrupção. Projetado para pipelines agénticos, processamento de dados sensíveis e execução segura de scripts multi-tenant.

## 📋 Especificação (SDD)
- **Entradas**: 
  - `TENANT_ID` (variável de ambiente obrigatória, alfanumérico + hífen)
  - `BASE_SANDBOX_DIR` (opcional, padrão: `/opt/mantis/sandboxes`)
  - `SESSION_ID` (opcional, padrão: UUID v4 ou timestamp seguro)
  - `DISK_THRESHOLD_PERCENT` (opcional, padrão: `90`)
- **Saídas**: 
  - Exporta `SANDBOX_PATH` para o ambiente pai
  - Output JSONL em stderr com eventos de criação, validação e cleanup
  - Códigos de retorno: `0` (sucesso), `1` (falha de criação/permissão), `2` (espaço insuficiente), `3` (tenant inválido)
- **Side Effects**: 
  - Criação de diretório com permissões `0700`
  - Remoção automática via `trap` em `EXIT`, `INT`, `TERM`
  - Registro de auditoria em stderr
- **Constraints Aplicáveis**: C1 (limite de disco), C4 (isolamento de tenant), C5 (expansão segura de caminhos), C7 (resiliência/trap), C8 (logging estruturado)
- **Dependências Externas**: `mktemp`, `chmod`, `df`, `stat`, `basename`, `date`, `tr`, `grep` (POSIX coreutils)

## 🛡️ Hardening (Harness Norms v3.0 - Executável)
```bash
#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_VERSION="2.0.0"

# C8: Logging estruturado JSONL em stderr
log_sandbox() {
  local level="${1:-INFO}"
  local event="${2:-unknown}"
  local detail="${3:-}"
  printf '{"ts":"%s","level":"%s","tenant":"%s","script":"%s","event":"%s","detail":"%s"}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    "$level" \
    "${TENANT_ID:-unknown}" \
    "$SCRIPT_NAME" \
    "$event" \
    "$detail" >&2
}

# C7: Cleanup automático em qualquer sinal de saída
cleanup() {
  local exit_code=$?
  if [[ -n "${SANDBOX_PATH:-}" && -d "${SANDBOX_PATH}" ]]; then
    rm -rf "${SANDBOX_PATH}" 2>/dev/null && log_sandbox "INFO" "sandbox_cleaned" "${SANDBOX_PATH}" || \
    log_sandbox "ERROR" "cleanup_failed" "${SANDBOX_PATH}"
  fi
  exit $exit_code
}
trap cleanup EXIT INT TERM

# C4: Validação obrigatória de contexto de tenant
: "${TENANT_ID:?Variável de ambiente TENANT_ID não definida. Abortando.}"

# C5: Validação de formato para evitar path traversal ou injeção
if [[ ! "${TENANT_ID}" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  log_sandbox "ERROR" "invalid_tenant_format" "${TENANT_ID}"
  exit 3
fi

readonly BASE_DIR="${BASE_SANDBOX_DIR:-/opt/mantis/sandboxes}"
readonly SESSION="${SESSION_ID:-$(date -u +%Y%m%dT%H%M%S)-$$}"
readonly DISK_THRESHOLD="${DISK_THRESHOLD_PERCENT:-90}"
readonly SANDBOX_PATH="${BASE_DIR}/${TENANT_ID}/${SESSION}"

# C1: Validação de espaço em disco antes da criação
readonly CURRENT_USAGE
CURRENT_USAGE=$(df -P "${BASE_DIR}" 2>/dev/null | awk 'NR==2 {gsub(/%/,""); print $5}') || CURRENT_USAGE=0
if [[ "${CURRENT_USAGE}" -ge "${DISK_THRESHOLD}" ]]; then
  log_sandbox "ERROR" "disk_threshold_exceeded" "Uso: ${CURRENT_USAGE}% > Limite: ${DISK_THRESHOLD}%"
  exit 2
fi

# C5+C7: Criação atômica e segura do sandbox
mkdir -p "${BASE_DIR}/${TENANT_ID}" || { log_sandbox "ERROR" "mkdir_base_failed"; exit 1; }
SANDBOX_PATH="$(mktemp -d -p "${BASE_DIR}/${TENANT_ID}" "${SESSION}_XXXXXX")" || { log_sandbox "ERROR" "mktemp_failed"; exit 1; }
chmod 0700 "${SANDBOX_PATH}" || { log_sandbox "ERROR" "chmod_failed"; exit 1; }

export SANDBOX_PATH
log_sandbox "INFO" "sandbox_created" "${SANDBOX_PATH}"
```

## 🧪 Testes Unitários (TDD)
```bash
test_sandbox_creates_isolated_dir_with_correct_perms() {
  # Arrange
  local TEST_TENANT="tenant-test-01"
  local TEST_BASE
  TEST_BASE=$(mktemp -d)
  export TENANT_ID="$TEST_TENANT"
  export BASE_SANDBOX_DIR="$TEST_BASE"

  # Act
  source "${BASH_SOURCE[0]}" 2>/dev/null || true
  local created_path="${SANDBOX_PATH:-}"
  local perms
  perms=$(stat -c "%a" "$created_path" 2>/dev/null || stat -f "%Lp" "$created_path" 2>/dev/null)

  # Assert
  if [[ -d "$created_path" && "$perms" == "700" && "$created_path" == *"$TEST_TENANT"* ]]; then
    rm -rf "$TEST_BASE"
    return 0
  else
    printf '[TEST_FAIL] Sandbox não criado com permissões 0700 ou tenant não isolado\n' >&2
    rm -rf "$TEST_BASE"
    return 1
  fi
}

test_sandbox_fails_on_invalid_tenant_format() {
  # Arrange
  export TENANT_ID="tenant/../invalid"
  export BASE_SANDBOX_DIR="$(mktemp -d)"

  # Act
  local exit_code=0
  source "${BASH_SOURCE[0]}" 2>/dev/null || exit_code=$?

  # Assert
  if [[ "$exit_code" -eq 3 ]]; then
    rm -rf "${BASE_SANDBOX_DIR}"
    return 0
  else
    printf '[TEST_FAIL] Script não rejeitou tenant com path traversal (código esperado: 3, obtido: %s)\n' "$exit_code" >&2
    rm -rf "${BASE_SANDBOX_DIR}"
    return 1
  fi
}

if [[ "${1:-}" == "--test" ]]; then
  test_sandbox_creates_isolated_dir_with_correct_perms
  test_sandbox_fails_on_invalid_tenant_format
  exit $?
fi
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/bash/filesystem-sandboxing.md \
  --json \
  --check-secrets \
  --check-tenant-isolation \
  --check-structural \
  --check-resource-limits \
  --check-error-handling
```

## 🔗 Referências Cruzadas
- [[bash-master-agent.md]]
- [[01-RULES/harness-norms-v3.0.md]]
- [[01-RULES/10-SDD-CONSTRAINTS.md]]
- [[01-RULES/06-MULTITENANCY-RULES.md]]
- [[00-CONTEXT/norms-matrix.json]]

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2024-09-12 | Dev inicial | Criação básica com `mkdir` e `chmod` | Parcial |
| 2.0.0 | 2026-05-06 | Bash Master Agent | Remanufatura completa: validação C4 de tenant, check C1 de disco, trap C7, JSONL C8, testes TDD | C1,C4,C5,C7,C8 |

---
