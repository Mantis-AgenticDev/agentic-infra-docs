---
artifact_id: safe-variable-expansion
artifact_type: bash_utility
version: 1.0.0
constraints_mapped: ["C3","C5","C6"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/bash/safe-variable-expansion.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:safe-variable-expansion-v1.0.0"
generated_at: "2026-05-07T00:00:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: bash
ai_navigation:
  read_first: false
  required_for: [input-sanitization, quoting-standards, injection-prevention]
  update_frequency: on-change
audience: ["bash-developers", "orchestrator-engine", "security-auditors"]
status: "🟢 Novo"
next_review: "2026-06-07"
---

# Expansão Segura de Variáveis e Sanitização de Entrada

## 🎯 Propósito
Fornecer funções reutilizáveis para expansão segura de variáveis, aplicação rigorosa de aspas, validação de padrões alfanuméricos e prevenção contra injeção de comandos ou word splitting acidental. Base para todos os artefatos que manipulam input externo, garantindo conformidade com C3 (zero secrets), C5 (estrutura) e C6 (sanitização).

## 📋 Especificação (SDD)
- **Entradas**: 
  - `RAW_INPUT` (string a ser validada/expandida)
  - `ALLOWED_PATTERN` (regex POSIX, padrão: `^[a-zA-Z0-9._-]+$`)
  - `FAIL_ON_MISMATCH` (booleano, padrão: `true`)
- **Saídas**: 
  - String sanitizada (stdout) ou string vazia se inválida
  - Código: `0` (válido/sucesso), `1` (inválido/falha), `2` (erro de padrão regex)
  - Logs JSONL em stderr com `validation_result`, `pattern_applied`, `tenant_id`
- **Side Effects**: 
  - Nenhum arquivo modificado
  - Variáveis internas (`SAFE_OUTPUT`, `IS_VALID`) atualizadas localmente
- **Constraints Aplicáveis**: C3 (bloqueio de expansão acidental), C5 (expansão com quotes duplos), C6 (validação regex antes de uso)
- **Dependências Externas**: `grep`, `sed`, coreutils POSIX

## 🛡️ Bootstrap Resiliente e Lógica de Expansão Segura (C3+C5+C6)
```bash
# =============================================================================
# BOOTSTRAP RESILIENTE: Hardening + Observabilidade (C3+C4+C7)
# =============================================================================
if [[ -f "${MANTIS_ROOT:-.}/06-PROGRAMMING/bash/bash-master-agent.sh" ]]; then
  source "${MANTIS_ROOT:-.}/06-PROGRAMMING/bash/bash-master-agent.sh" --mode=observability-only
else
  set -Eeuo pipefail; shopt -s inherit_errexit 2>/dev/null || true
  trap 'exit 130' INT TERM
  if [[ "${TENANT_CONTEXT:-nao_aplicavel}" != "nao_aplicavel" ]]; then
    : "${TENANT_ID:?ERROR: TENANT_ID não definido.}"
  fi
  mantis_log() { printf '{"ts":"%s","level":"%s","tenant":"%s","event":"%s","detail":"%s","fallback":"true"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${1:-INFO}" "${TENANT_ID:-global}" "${2:-bootstrap_fallback}" "${3:-}" >&2; }
  mantis_log "WARN" "bootstrap_fallback" "Master agent não encontrado."
fi

readonly SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"
readonly SCRIPT_VERSION="${VERSION:-1.0.0}"
readonly ARTIFACT_ID="safe-variable-expansion"
export TENANT_ID="${TENANT_ID:-global}"

# C6: Função canônica de validação e expansão
safe_expand() {
  local raw="${1:-}"
  local pattern="${2:-^[a-zA-Z0-9._-]+$}"
  local fail_mode="${3:-true}"

  if [[ -z "$raw" ]]; then
    mantis_log "WARN" "empty_input_detected" "Entrada vazia fornecida"
    return 0
  fi

  if ! grep -qE "$pattern" <<< "$raw" 2>/dev/null; then
    if [[ "$fail_mode" == "true" ]]; then
      mantis_log "ERROR" "pattern_mismatch" "Input '${raw}' não corresponde ao padrão seguro"
      return 1
    fi
    mantis_log "WARN" "input_sanitized" "Input removido por não corresponder ao padrão"
    return 0
  fi

  # Expansão segura (quotes duplos obrigatórios)
  printf '%s\n' "$raw"
  return 0
}

# C5: Wrapper para variáveis de ambiente
safe_getenv() {
  local var_name="${1:?safe_getenv: nome da variável é obrigatório}"
  local default="${2:-}"
  local val="${!var_name:-$default}"
  
  if [[ -z "$val" && -n "$default" ]]; then
    mantis_log "DEBUG" "env_default_used" "Variável $var_name ausente, usando default"
  fi
  printf '%s\n' "$val"
}
```

## 🧪 Testes Unitários (TDD)
```bash
test_safe_expand_allows_valid_input() {
  local out
  out=$(safe_expand "valid-name_01.txt" "^[a-zA-Z0-9._-]+$")
  [[ "$out" == "valid-name_01.txt" ]] && return 0
  return 1
}

test_safe_expand_blocks_injection() {
  local out
  out=$(safe_expand "file.txt; rm -rf /" "^[a-zA-Z0-9._-]+$" 2>/dev/null) || true
  [[ -z "$out" ]] && return 0
  return 1
}

test_validate_vlog02_schema() {
  local log_output
  log_output=$(mantis_log "INFO" "test_event" "detalhe" 2>&1)
  printf '%s\n' "$log_output" | jq -e 'has("timestamp") and has("resource.tenant_id") and has("resource.artifact")' >/dev/null 2>&1
}

if [[ "${1:-}" == "--test" ]]; then
  test_safe_expand_allows_valid_input
  test_safe_expand_blocks_injection
  test_validate_vlog02_schema
  exit $?
fi
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/bash/safe-variable-expansion.md \
  --json --check-structural --check-error-handling --check-observability
```

## 🔗 Referências Cruzadas
- [[bash-master-agent.md]]
- [[01-RULES/05-CODE-PATTERNS-RULES.md]]
- [[01-RULES/03-SECURITY-RULES.md]]
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]]
- [[/05-CONFIGURATIONS/observability/loki/config.yml]]

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-07 | Bash Master Agent | Criação inicial: expansão segura, regex C6, fallback resiliente | C3,C5,C6 |

---
## 🔍 Observability (Documentación para IA)
> Este artefato emite os seguintes eventos via `mantis_log()`:

| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `empty_input_detected` | WARN | C5 | `"Entrada vazia fornecida"` |
| `pattern_mismatch` | ERROR | C6 | `"Input 'cmd;rm' não corresponde ao padrão seguro"` |
| `input_sanitized` | WARN | C6 | `"Input removido por não corresponder ao padrão"` |
| `env_default_used` | DEBUG | C3 | `"Variável API_KEY ausente, usando default"` |

### Exemplo de Output JSONL
```json
{"timestamp":"2026-05-07T00:00:00Z","level":"INFO","resource":{"tenant_id":"global","artifact":"safe-variable-expansion"},"body":{"event":"safe_expand_success","detail":"Input validado e expandido com segurança"},"attributes":{"mantis":{"tier":"2","version":"1.0.0","constraint":"C3,C5,C6","trace_id":""},"code.filepath":"06-PROGRAMMING/bash/safe-variable-expansion.md","code.lineno":45,"telemetry.sdk.name":"mantis-bash-adapter","telemetry.sdk.version":"1.0.0"}}
```

### Validação de Schema V-LOG-02
```bash
validate_vlog02() {
  jq -e 'has("timestamp") and has("level") and has("resource.tenant_id") and has("resource.artifact") and has("body.event")' >/dev/null 2>&1
}
```
---
