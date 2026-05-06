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
  - Registro de auditoria em stderr via `mantis_log()`
- **Constraints Aplicáveis**: C1 (limite de disco), C4 (isolamento de tenant), C5 (expansão segura de caminhos), C7 (resiliência/trap), C8 (logging estruturado)
- **Dependências Externas**: `mktemp`, `chmod`, `df`, `stat`, `basename`, `date`, `tr`, `grep` (POSIX coreutils)

## 🛡️ Bootstrap Resiliente (Hardening via Source ao Master - C3+C4+C5+C7)
```bash
# =============================================================================
# BOOTSTRAP RESILIENTE: Hardening + Observabilidade (C3+C4+C7)
# Fonte de verdade: bash-master-agent.md via source
# =============================================================================
if [[ -f "${MANTIS_ROOT:-.}/06-PROGRAMMING/bash/bash-master-agent.sh" ]]; then
  source "${MANTIS_ROOT:-.}/06-PROGRAMMING/bash/bash-master-agent.sh" --mode=observability-only
else
  # Fallback minimalista: garante execução segura e auditável se master não estiver disponível
  set -Eeuo pipefail
  shopt -s inherit_errexit 2>/dev/null || true
  trap 'exit 130' INT TERM
  : "${TENANT_ID:?ERROR: TENANT_ID não definido. Defina via env ou argumento.}"
  mantis_log() {
    printf '{"ts":"%s","level":"%s","tenant":"%s","event":"%s","detail":"%s","fallback":"true"}\n' \
      "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      "${1:-INFO}" \
      "${TENANT_ID:-unknown}" \
      "${2:-bootstrap_fallback}" \
      "${3:-}" >&2
  }
  mantis_log "WARN" "bootstrap_fallback" "Master agent não encontrado. Executando com hardening mínimo."
fi

# =============================================================================
# VARIÁVEIS CANÔNICAS DO ARTEFATO (C5: Estrutura)
# =============================================================================
readonly SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_VERSION="${VERSION:-2.0.0}"
readonly LOG_DIR="${LOG_DIR:-08-LOGS/bash}"

# C4: Propagação explícita de tenant_id para subshells
export TENANT_ID="${TENANT_ID:-}"
```

## 🧩 Lógica do Artefato (Sandbox Creation & Validation)
```bash
# =============================================================================
# VALIDAÇÃO DE TENANT & DISCO (C4 + C1)
# =============================================================================
: "${TENANT_ID:?Variável de ambiente TENANT_ID não definida. Abortando para evitar vazamento.}"

if [[ ! "${TENANT_ID}" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  mantis_log "ERROR" "invalid_tenant_format" "Tenant ID contém caracteres inválidos: ${TENANT_ID}"
  exit 3
fi

readonly BASE_DIR="${BASE_SANDBOX_DIR:-/opt/mantis/sandboxes}"
readonly SESSION="${SESSION_ID:-$(date -u +%Y%m%dT%H%M%S)-$$}"
readonly DISK_THRESHOLD="${DISK_THRESHOLD_PERCENT:-90}"

# C1: Validação de espaço em disco antes da criação
readonly CURRENT_USAGE
CURRENT_USAGE=$(df -P "${BASE_DIR}" 2>/dev/null | awk 'NR==2 {gsub(/%/,""); print $5}') || CURRENT_USAGE=0
if [[ "${CURRENT_USAGE}" -ge "${DISK_THRESHOLD}" ]]; then
  mantis_log "ERROR" "disk_threshold_exceeded" "Uso: ${CURRENT_USAGE}% > Limite: ${DISK_THRESHOLD}%"
  exit 2
fi

# =============================================================================
# CRIAÇÃO SEGURA DO SANDBOX (C5 + C7)
# =============================================================================
cleanup() {
  local exit_code=$?
  if [[ -n "${SANDBOX_PATH:-}" && -d "${SANDBOX_PATH}" ]]; then
    if rm -rf "${SANDBOX_PATH}" 2>/dev/null; then
      mantis_log "INFO" "sandbox_cleaned" "Diretório removido: ${SANDBOX_PATH}"
    else
      mantis_log "ERROR" "cleanup_failed" "Falha ao remover: ${SANDBOX_PATH}"
    fi
  fi
  exit $exit_code
}
trap cleanup EXIT INT TERM

# Criação atômica e segura
mkdir -p "${BASE_DIR}/${TENANT_ID}" || { mantis_log "ERROR" "mkdir_base_failed"; exit 1; }
SANDBOX_PATH="$(mktemp -d -p "${BASE_DIR}/${TENANT_ID}" "${SESSION}_XXXXXX")" || { mantis_log "ERROR" "mktemp_failed"; exit 1; }
chmod 0700 "${SANDBOX_PATH}" || { mantis_log "ERROR" "chmod_failed"; exit 1; }

export SANDBOX_PATH
mantis_log "INFO" "sandbox_created" "Rota segura: ${SANDBOX_PATH} | Permissões: 0700 | Tenant: ${TENANT_ID}"
```

## 🧪 Testes Unitários (TDD - Test-Driven Development)
```bash
test_sandbox_creates_isolated_dir_with_correct_perms() {
  # Arrange
  local TEST_TENANT="tenant-test-01"
  local TEST_BASE
  TEST_BASE=$(mktemp -d)
  export TENANT_ID="$TEST_TENANT"
  export BASE_SANDBOX_DIR="$TEST_BASE"

  # Act
  local exit_code=0
  source "${BASH_SOURCE[0]}" 2>/dev/null || exit_code=$?
  local created_path="${SANDBOX_PATH:-}"
  local perms
  perms=$(stat -c "%a" "$created_path" 2>/dev/null || stat -f "%Lp" "$created_path" 2>/dev/null)

  # Assert
  if [[ -d "$created_path" && "$perms" == "700" && "$created_path" == *"$TEST_TENANT"* && "$exit_code" -eq 0 ]]; then
    rm -rf "$TEST_BASE"
    return 0
  else
    mantis_log "ERROR" "test_failed" "Sandbox não criado corretamente (exit: $exit_code, perms: $perms)"
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
    mantis_log "ERROR" "test_failed" "Não rejeitou tenant inválido (esperado: 3, obtido: $exit_code)"
    rm -rf "${BASE_SANDBOX_DIR}"
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
  test_sandbox_creates_isolated_dir_with_correct_perms
  test_sandbox_fails_on_invalid_tenant_format
  test_validate_vlog02_schema
  exit $?
fi
```

## 🔍 Validação (VDD - Validation-Driven Development)
```bash
# Validação completa via orchestrator-engine
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/bash/filesystem-sandboxing.md \
  --json \
  --check-secrets \
  --check-tenant-isolation \
  --check-structural \
  --check-resource-limits \
  --check-error-handling \
  --check-observability

# Validação rápida (headless)
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/bash/filesystem-sandboxing.md \
  --mode headless \
  --checks C4,C5,C7,C8 \
  --json
```

## 🔗 Referências Cruzadas (Wikilinks para Navegação de IA)
- [[bash-master-agent.md]] ← Contrato principal e função `mantis_log()`
- [[01-RULES/harness-norms-v3.0.md]] ← Especificação de hardening
- [[01-RULES/10-SDD-CONSTRAINTS.md]] ← Definição das constraints C1-C8
- [[01-RULES/06-MULTITENANCY-RULES.md]] ← Regras de isolamento por tenant
- [[00-CONTEXT/norms-matrix.json]] ← Fonte de verdade para constraints
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]] ← Índice de observabilidade
- [[/05-CONFIGURATIONS/observability/loki/config.yml]] ← Pipeline de ingestão de logs JSONL

## 📝 Histórico de Revisões (Para CHRONICLE.md Integration)
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2024-09-12 | Dev inicial | Criação básica com `mkdir` e `chmod` | Parcial |
| 2.0.0 | 2026-05-06 | Bash Master Agent | Remanufatura: bootstrap resiliente, `mantis_log()` canônica, validação V-LOG-02, remoção de hardening inline | C1,C4,C5,C7,C8 |

---
## 🔍 Observability (Documentação para IA)

> Este artefato emite os seguintes eventos via `mantis_log()` (definida em [[bash-master-agent.md]]):

| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `sandbox_created` | INFO | C4 | `"Rota segura: /opt/mantis/sandboxes/tenant-xyz/sess_123 \| Permissões: 0700"` |
| `disk_threshold_exceeded` | ERROR | C1 | `"Uso: 92% > Limite: 90%"` |
| `invalid_tenant_format` | ERROR | C4 | `"Tenant ID contém caracteres inválidos: ../escape"` |
| `sandbox_cleaned` | INFO | C7 | `"Diretório removido: /opt/mantis/sandboxes/..."` |
| `cleanup_failed` | ERROR | C7 | `"Falha ao remover diretório temporário"` |

### Exemplo de Output JSONL (para aprendizado de padrão por IA)
```json
{"timestamp":"2026-05-06T12:10:00Z","level":"INFO","resource":{"tenant_id":"tenant-xyz","artifact":"filesystem-sandboxing"},"body":{"event":"sandbox_created","detail":"Rota segura: /opt/mantis/sandboxes/tenant-xyz/sess_123 | Permissões: 0700"},"attributes":{"mantis":{"tier":"2","version":"2.0.0","constraint":"C4,C7","trace_id":""},"code.filepath":"06-PROGRAMMING/bash/filesystem-sandboxing.md","code.lineno":45,"telemetry.sdk.name":"mantis-bash-adapter","telemetry.sdk.version":"1.0.0"}}
```

### Configuração Específica de Este Artefato
```bash
# Variáveis de entorno que afetam o comportamento de logging deste artefato
export LOG_SANDBOX_DETAILS="${LOG_SANDBOX_DETAILS:-true}"  # Incluir rotas completas em logs
export LOG_CHECKSUM="${LOG_CHECKSUM:-false}"               # Incluir hashes SHA-256 de arquivos criados (C8)
export TRACE_SANDBOX_OPS="${TRACE_SANDBOX_OPS:-false}"     # Habilitar trace_id para correlação OTel
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
    has("attributes.mantis.tier")
  ' >/dev/null 2>&1
}

# Uso em testes ou validação manual:
# mantis_log "INFO" "test" "x" 2>&1 | validate_vlog02 && echo "✅ Schema V-LOG-02 válido"
```

---
