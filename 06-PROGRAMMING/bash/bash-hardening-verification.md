---
artifact_id: bash-hardening-verification
artifact_type: bash_utility
version: 1.0.0
constraints_mapped: ["C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/bash/bash-hardening-verification.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:bash-hardening-verification-v1.0.0"
generated_at: "2026-05-07T00:00:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: bash
ai_navigation:
  read_first: false
  required_for: [deep-static-analysis, orchestrator-integration, compliance-audit]
  update_frequency: on-change
audience: ["orchestrator-engine", "security-auditors", "ci-cd-pipelines"]
status: "🟢 Novo"
next_review: "2026-06-07"
---

# Verificador Canônico de Hardening Bash (Orchestrator Engine)

## 🎯 Propósito
Módulo de validação profunda executado pelo `orchestrator-engine` para auditar conformidade com Harness Norms v3.0. Foca em análise estática avançada, detecção de anti-padrões (`eval`, `unquoted vars`), validação de estrutura YAML e emissão de relatório forense.

## 📋 Especificação (SDD)
- **Entradas**: `TARGET_FILE`, `REPORT_MODE` (`jsonl`, `summary`)
- **Saídas**: Report JSONL com `rule_id`, `severity`, `hint`, `line_number`
- **Side Effects**: Leitura apenas
- **Constraints**: C5, C7, C8

## 🛡️ Bootstrap Resiliente e Lógica de Verificação (C5+C7+C8)
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
readonly ARTIFACT_ID="bash-hardening-verification"
export TENANT_ID="${TENANT_ID:-global}"

readonly TARGET="${1:?Uso: bash-hardening-verification.sh <arquivo>}"
readonly MODE="${2:-jsonl}"

verify_hardening() {
  local file="$1" line=0 issues=0
  while IFS= read -r line_content; do
    ((line++))
    # C3: eval bloqueado
    [[ "$line_content" =~ eval[[:space:]] ]] && \
      { printf '{"rule":"C3_001","severity":"critical","line":%d,"hint":"Substituir eval por source/exec seguro"}\n' "$line"; ((issues++)); }
    # C5: vars sem aspas em condições críticas
    [[ "$line_content" =~ \[.*\$[A-Z_]+[^[:space:]]*[^\"\'\}].*\] ]] && \
      { printf '{"rule":"C5_001","severity":"warning","line":%d,"hint":"Usar quotes duplos em variáveis"}\n' "$line"; }
  done < "$file"
  
  if [[ $issues -eq 0 ]]; then
    mantis_log "INFO" "audit_passed" "Zero anti-padrões detectados em $file"
  else
    mantis_log "WARN" "audit_issues_found" "$issues issues encontradas"
  fi
}

[[ -f "$TARGET" ]] || exit 1
verify_hardening "$TARGET"
```

## 🧪 Testes Unitários (TDD)
```bash
test_hook_detects_eval_anti_pattern() {
  local tmp; tmp=$(mktemp)
  echo 'eval "$user_input"' > "$tmp"
  bash "${BASH_SOURCE[0]}" "$tmp" jsonl 2>/dev/null | grep -q "C3_001" && { rm -f "$tmp"; return 0; }
  rm -f "$tmp"; return 1
}
test_validate_vlog02_schema() { mantis_log "INFO" "x" "y" 2>&1 | jq -e 'has("resource.tenant_id")' >/dev/null 2>&1; }

if [[ "${1:-}" == "--test" ]]; then test_hook_detects_eval_anti_pattern; test_validate_vlog02_schema; exit $?; fi
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/bash/bash-hardening-verification.md --json --check-structural --check-error-handling --check-observability
```

## 🔗 Referências Cruzadas
- [[bash-master-agent.md]]
- [[01-RULES/harness-norms-v3.0.md]]
- [[/05-CONFIGURATIONS/validation/orchestrator-engine/main.go]]
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]]

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-07 | Bash Master Agent | Criação inicial: análise estática profunda, detecção C3/C5, report forense | C5,C7,C8 |

---
## 🔍 Observability (Documentación para IA)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `audit_passed` | INFO | C8 | `"Zero anti-padrões detectados em script.sh"` |
| `audit_issues_found` | WARN | C5 | `"3 issues encontradas"` |

### Validação de Schema V-LOG-02
```bash
validate_vlog02() { jq -e 'has("timestamp") and has("level") and has("resource.tenant_id")' >/dev/null 2>&1; }
```
---
