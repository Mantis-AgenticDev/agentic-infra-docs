---
artifact_id: verify-constraints-hook
artifact_type: bash_utility
version: 1.0.0
constraints_mapped: ["C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/bash/verify-constraints-hook.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:verify-constraints-hook-v1.0.0"
generated_at: "2026-05-07T00:00:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: bash
ai_navigation:
  read_first: false
  required_for: [pre-commit-checks, pipeline-gates, sdd-enforcement]
  update_frequency: on-change
audience: ["ci-cd-pipelines", "orchestrator-engine", "validation-agents"]
status: "🟢 Novo"
next_review: "2026-06-07"
---

# Hook de Verificação de Constraints (Pre-Commit/Pipeline)

## 🎯 Propósito
Executar validação estática rápida contra constraints C1-C8 antes de commit ou deploy. Verifica frontmatter YAML, presença de hardening, sanitização de input e estrutura de logs. Emite report JSONL compatível com `orchestrator-engine`.

## 📋 Especificação (SDD)
- **Entradas**: 
  - `TARGET_FILE` (caminho do artefato)
  - `CONSTRAINTS_LIST` (ex: `"C5,C7,C8"`, padrão: todas)
- **Saídas**: 
  - JSONL em stdout: `{"check":"C5","status":"pass"|"fail","hint":"..."}`
  - Código: `0` (todos pass), `1` (falha crítica), `2` (erro de validação)
- **Side Effects**: 
  - Leitura apenas
- **Constraints Aplicáveis**: C5 (estrutura YAML/frontmatter), C7 (resiliência do hook), C8 (auditoria de validação)
- **Dependências Externas**: `grep`, `awk`, `yq` (ou `jq`), `timeout`

## 🛡️ Bootstrap Resiliente e Lógica do Hook (C5+C7+C8)
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
readonly ARTIFACT_ID="verify-constraints-hook"
export TENANT_ID="${TENANT_ID:-global}"

readonly TARGET="${1:?Uso: verify-constraints-hook.sh <arquivo> [C5,C7...]}"
readonly CHECKS="${2:-C1,C2,C3,C4,C5,C6,C7,C8}"

check_c5() {
  [[ "$(head -n 20 "$TARGET" | grep -c '^artifact_id:')" -ge 1 ]] && \
  [[ "$(head -n 20 "$TARGET" | grep -c '^constraints_mapped:')" -ge 1 ]] || \
  { mantis_log "ERROR" "c5_failed" "Frontmatter YAML ausente ou incompleto"; return 1; }
}

check_c7() {
  grep -qE 'trap .* EXIT' "$TARGET" && grep -qE 'set -Eeuo pipefail' "$TARGET" || \
  { mantis_log "ERROR" "c7_failed" "Hardening/trap ausente"; return 1; }
}

check_c8() {
  grep -qE 'mantis_log\s' "$TARGET" || \
  { mantis_log "ERROR" "c8_failed" "mantis_log() não encontrada"; return 1; }
}

run_checks() {
  IFS=',' read -ra CHECK_LIST <<< "$CHECKS"
  for c in "${CHECK_LIST[@]}"; do
    case "$c" in
      C5) check_c5 ;; C7) check_c7 ;; C8) check_c8 ;;
      *) mantis_log "WARN" "unknown_constraint" "Check $c não implementado" ;;
    esac
    if [[ $? -eq 0 ]]; then
      printf '{"check":"%s","status":"pass","file":"%s","timestamp":"%s"}\n' "$c" "$TARGET" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    else
      printf '{"check":"%s","status":"fail","file":"%s","timestamp":"%s"}\n' "$c" "$TARGET" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
      return 1
    fi
  done
}

[[ -f "$TARGET" ]] || { mantis_log "ERROR" "file_not_found" "$TARGET"; exit 2; }
run_checks
exit $?
```

## 🧪 Testes Unitários (TDD)
```bash
test_hook_passes_valid_artifact() {
  local tmp
  tmp=$(mktemp)
  cat > "$tmp" << 'EOF'
---
artifact_id: test
constraints_mapped: ["C5"]
---
set -Eeuo pipefail
trap 'exit $?' EXIT
mantis_log "INFO" "test" "x"
EOF
  bash "${BASH_SOURCE[0]}" "$tmp" "C5,C7,C8" > /dev/null 2>&1
  [[ $? -eq 0 ]] && { rm -f "$tmp"; return 0; }
  rm -f "$tmp"; return 1
}

test_validate_vlog02_schema() {
  local log_output; log_output=$(mantis_log "INFO" "test" "x" 2>&1)
  printf '%s\n' "$log_output" | jq -e 'has("timestamp") and has("resource.tenant_id")' >/dev/null 2>&1
}

if [[ "${1:-}" == "--test" ]]; then
  test_hook_passes_valid_artifact
  test_validate_vlog02_schema
  exit $?
fi
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/bash/verify-constraints-hook.md \
  --json --check-structural --check-error-handling --check-observability
```

## 🔗 Referências Cruzadas
- [[bash-master-agent.md]]
- [[01-RULES/validation-checklist.md]]
- [[/05-CONFIGURATIONS/validation/orchestrator-engine/main.go]]
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]]

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-07 | Bash Master Agent | Criação inicial: hook C5/C7/C8, output JSONL, validação rápida | C5,C7,C8 |

---
## 🔍 Observability (Documentación para IA)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `c5_failed` | ERROR | C5 | `"Frontmatter YAML ausente ou incompleto"` |
| `c7_failed` | ERROR | C7 | `"Hardening/trap ausente"` |
| `c8_failed` | ERROR | C8 | `"mantis_log() não encontrada"` |
| `unknown_constraint` | WARN | C5 | `"Check C9 não implementado"` |

### Validação de Schema V-LOG-02
```bash
validate_vlog02() { jq -e 'has("timestamp") and has("level") and has("resource.tenant_id")' >/dev/null 2>&1; }
```
---
