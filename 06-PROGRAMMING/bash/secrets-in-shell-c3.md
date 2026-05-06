---
artifact_id: secrets-in-shell-c3
artifact_type: bash_utility
version: 1.0.0
constraints_mapped: ["C3","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/bash/secrets-in-shell-c3.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:secrets-in-shell-c3-v1.0.0"
generated_at: "2026-05-07T01:00:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: bash
ai_navigation:
  read_first: false
  required_for: [credential-management, zero-hardcode, secret-masking]
  update_frequency: on-change
audience: ["bash-developers", "security-auditors", "ci-cd-pipelines"]
status: "🟢 Novo"
next_review: "2026-06-07"
---

# Gestión Segura de Secretos y Prevención de Hardcode (C3)

## 🎯 Propósito
Proveer funciones para carga segura de credenciales desde variables de entorno o vaults externos, detección y bloqueo de secretos hardcodeados, y enmascaramiento automático en logs. Garantiza cumplimiento estricto de C3 (Zero Secrets) en ejecución y auditoría.

## 📋 Especificação (SDD)
- **Entradas**: `SECRET_NAME` (nombre de la variable/clave), `PATTERN_REGEX` (opcional, para validación de formato)
- **Saídas**: Valor desenmascarado (solo en memoria segura), string `***REDACTED***` en logs, código `0` (válido), `1` (hardcode detectado), `2` (formato inválido)
- **Side Effects**: Ninguna escritura en disco; enmascaramiento en stdout/stderr
- **Constraints Aplicáveis**: C3 (zero hardcode, masking), C5 (estructura segura), C8 (auditoría de acceso)
- **Dependências Externas**: `grep`, `sed`, `awk`, coreutils POSIX

## 🛡️ Bootstrap Resiliente e Lógica de Gestão de Secretos (C3+C5+C8)
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
readonly ARTIFACT_ID="secrets-in-shell-c3"
export TENANT_ID="${TENANT_ID:-global}"

# Patrones comunes de hardcode a bloquear
HARDCODE_PATTERNS=("sk-[a-zA-Z0-9]{20,}" "AKIA[0-9A-Z]{16}" "ghp_[a-zA-Z0-9]{36}" "password[=:]['\"]")

mask_secret() {
  local val="${1:?mask_secret: valor requerido}"
  printf '%s\n' "$val" | sed -E "s/(${HARDCODE_PATTERNS[*]})/**REDACTED***/gI"
}

load_secure_env() {
  local key="${1:?load_secure_env: chave obrigatória}"
  local val="${!key:-}"
  
  # Verificar si parece hardcode en script (bloquear si contiene comillas o patrones fijos)
  if [[ "$val" =~ (\"|\'|\=.*=) ]] || [[ -n "$val" && "$val" == *"${HARDCODE_PATTERNS[0]}"* ]]; then
    mantis_log "ERROR" "hardcode_detected" "Posible secreto hardcodeado en $key"
    return 1
  fi
  
  # Validar formato si se pasa regex
  if [[ -n "${2:-}" ]] && ! [[ "$val" =~ $2 ]]; then
    mantis_log "ERROR" "invalid_secret_format" "El secreto en $key no cumple el patrón esperado"
    return 2
  fi
  
  mantis_log "DEBUG" "secret_loaded_securely" "Cargado $key desde entorno seguro"
  printf '%s\n' "$val"
}
```

## 🧪 Testes Unitários (TDD)
```bash
test_masking_redacts_known_patterns() {
  local out; out=$(mask_secret "token=sk-abc123xyz4567890abcdef")
  [[ "$out" == "token=**REDACTED***" ]] && return 0
  return 1
}

test_load_secure_env_blocks_hardcode() {
  local API_KEY="\"hardcoded_value\""
  load_secure_env "API_KEY" >/dev/null 2>&1
  [[ $? -eq 1 ]] && return 0
  return 1
}

test_validate_vlog02_schema() {
  mantis_log "INFO" "test" "x" 2>&1 | jq -e 'has("timestamp") and has("resource.tenant_id")' >/dev/null 2>&1
}

if [[ "${1:-}" == "--test" ]]; then test_masking_redacts_known_patterns; test_load_secure_env_blocks_hardcode; test_validate_vlog02_schema; exit $?; fi
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/bash/secrets-in-shell-c3.md --json --check-structural --check-error-handling --check-observability
```

## 🔗 Referências Cruzadas
- [[bash-master-agent.md]]
- [[01-RULES/03-SECURITY-RULES.md]]
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]]
- [[/05-CONFIGURATIONS/observability/loki/config.yml]]

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-07 | Bash Master Agent | Criação inicial: detección hardcode, masking C3, carga segura | C3,C5,C8 |

---
## 🔍 Observability (Documentación para IA)
> Este artefato emite os seguintes eventos via `mantis_log()`:

| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `secret_loaded_securely` | DEBUG | C8 | `"Cargado DB_PASSWORD desde entorno seguro"` |
| `hardcode_detected` | ERROR | C3 | `"Posible secreto hardcodeado en API_KEY"` |
| `invalid_secret_format` | ERROR | C3 | `"El secreto no cumple el patrón esperado"` |

### Validação de Schema V-LOG-02
```bash
validate_vlog02() { jq -e 'has("timestamp") and has("level") and has("resource.tenant_id") and has("resource.artifact")' >/dev/null 2>&1; }
```
---
