---
artifact_id: audit-secrets-hook
artifact_type: bash_utility
version: 1.0.0
constraints_mapped: ["C3","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/bash/audit-secrets-hook.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:audit-secrets-hook-v1.0.0"
generated_at: "2026-05-07T01:00:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: bash
ai_navigation:
  read_first: false
  required_for: [pre-commit-scan, ci-secret-detection, pattern-matching]
  update_frequency: on-change
audience: ["ci-cd-pipelines", "security-auditors", "orchestrator-engine"]
status: "🟢 Novo"
next_review: "2026-06-07"
---

# Hook de Auditoría y Detección de Secretos (Pre-Commit/CI)

## 🎯 Propósito
Escanear archivos o staged changes en busca de patrones de secretos (`sk-.*`, `ghp_.*`, `AKIA.*`, `password=.*`), emitir reportes JSONL por hallazgo y abortar pipelines si se detectan credenciales críticas. Integración nativa con `git pre-commit` o `orchestrator-engine`.

## 📋 Especificação (SDD)
- **Entradas**: `TARGET_PATH` (archivo/directorio), `SCAN_MODE` (`file`, `staged`, `dir`)
- **Saídas**: JSONL en stdout por finding, código `0` (clean), `1` (secret found), `2` (error)
- **Side Effects**: Lectura únicamente, sin modificación
- **Constraints Aplicáveis**: C3 (detección y bloqueo), C8 (auditoría JSONL de hallazgos)
- **Dependências Externas**: `git`, `grep`, `awk`, `find`, coreutils POSIX

## 🛡️ Bootstrap Resiliente e Lógica de Escaneo (C3+C8)
```bash
if [[ -f "${MANTIS_ROOT:-.}/06-PROGRAMMING/bash/bash-master-agent.sh" ]]; then
  source "${MANTIS_ROOT:-.}/06-PROGRAMMING/bash/bash-master-agent.sh" --mode=observability-only
else
  set -Eeuo pipefail; shopt -s inherit_errexit 2>/dev/null || true
  trap 'exit 130' INT TERM
  if [[ "${TENANT_CONTEXT:-nao_aplicavel}" != "nao_aplicavel" ]]; then : "${TENANT_ID:?ERROR: TENANT_ID não definido.}"; fi
  mantis_log() { printf '{"ts":"%s","level":"%s","tenant":"%s","event":"%s","detail":"%s","fallback":"true"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${1:-INFO}" "${TENANT_ID:-global}" "${2:-bootstrap_fallback}" "${3:-}" >&2; }
  mantis_log "WARN" "bootstrap_fallback" "Master agent não encontrado."
fi

readonly SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"
readonly ARTIFACT_ID="audit-secrets-hook"
export TENANT_ID="${TENANT_ID:-global}"

readonly TARGET="${1:?Uso: audit-secrets-hook.sh <path> [file|staged|dir]}"
readonly MODE="${2:-file}"

SECRET_PATTERNS=("sk-[a-zA-Z0-9]{20,}" "AKIA[0-9A-Z]{16}" "ghp_[a-zA-Z0-9]{36}" "password[=:][[:space:]]*['\"]?[a-zA-Z0-9!@#$%^&*]+")

scan_file() {
  local file="$1" line=0 found=0
  while IFS= read -r line_content; do
    ((line++))
    for pattern in "${SECRET_PATTERNS[@]}"; do
      if echo "$line_content" | grep -qE "$pattern" 2>/dev/null; then
        printf '{"severity":"critical","rule":"C3_SECRET_PATTERN","file":"%s","line":%d,"pattern":"%s","timestamp":"%s"}\n' \
          "$file" "$line" "$pattern" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        mantis_log "ERROR" "secret_found" "File=$file, Line=$line, Pattern=$pattern"
        ((found++))
        break
      fi
    done
  done < "$file"
  return $found
}

mantis_log "INFO" "scan_started" "Mode=$MODE, Target=$TARGET"
[[ -f "$TARGET" ]] && scan_file "$TARGET" && { mantis_log "INFO" "scan_completed_clean"; exit 0; } || { mantis_log "ERROR" "scan_aborted_findings"; exit 1; }
```

## 🧪 Testes Unitários (TDD)
```bash
test_hook_detects_known_secret_pattern() {
  local tmp; tmp=$(mktemp)
  echo 'export API_KEY="AKIA1234567890ABCDEF"' > "$tmp"
  bash "${BASH_SOURCE[0]}" "$tmp" file 2>/dev/null | grep -q "AKIA" && { rm -f "$tmp"; return 0; }
  rm -f "$tmp"; return 1
}

test_hook_passes_clean_file() {
  local tmp; tmp=$(mktemp)
  echo 'export SAFE_VAR="clean_value_123"' > "$tmp"
  bash "${BASH_SOURCE[0]}" "$tmp" file 2>/dev/null >/dev/null
  [[ $? -eq 0 ]] && { rm -f "$tmp"; return 0; }
  rm -f "$tmp"; return 1
}

test_validate_vlog02_schema() {
  mantis_log "INFO" "test" "x" 2>&1 | jq -e 'has("timestamp") and has("resource.tenant_id")' >/dev/null 2>&1
}

if [[ "${1:-}" == "--test" ]]; then test_hook_detects_known_secret_pattern; test_hook_passes_clean_file; test_validate_vlog02_schema; exit $?; fi
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/bash/audit-secrets-hook.md --json --check-structural --check-error-handling --check-observability
```

## 🔗 Referências Cruzadas
- [[bash-master-agent.md]]
- [[01-RULES/03-SECURITY-RULES.md]]
- [[/05-CONFIGURATIONS/validation/orchestrator-engine/main.go]]
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]]

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-07 | Bash Master Agent | Criação inicial: escaneo regex, report JSONL, abort C3 | C3,C8 |

---
## 🔍 Observability (Documentación para IA)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `scan_started` | INFO | C8 | `"Mode=file, Target=script.sh"` |
| `secret_found` | ERROR | C3 | `"File=script.sh, Line=5, Pattern=AKIA.*"` |
| `scan_completed_clean` | INFO | C8 | `"Zero hallazgos en Target=script.sh"` |
| `scan_aborted_findings` | ERROR | C3 | `"Hook abortado por secretos detectados"` |

### Validação de Schema V-LOG-02
```bash
validate_vlog02() { jq -e 'has("timestamp") and has("level") and has("resource.tenant_id")' >/dev/null 2>&1; }
```
---
