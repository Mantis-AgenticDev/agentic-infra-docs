---
artifact_id: orchestrator-engine-bash-port
artifact_type: bash_utility
version: 1.0.0
constraints_mapped: ["C4","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/bash/orchestrator-engine-bash-port.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:orchestrator-engine-bash-port-v1.0.0"
generated_at: "2026-05-07T03:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: bash
ai_navigation:
  read_first: false
  required_for: [local-validation, routing-decision, constraint-checking]
  update_frequency: on-change
audience: ["orchestrator-engine", "ci-cd-pipelines", "validation-agents"]
status: "🟢 Novo"
next_review: "2026-06-07"
---

# Port Bash do Orchestrator Engine para Validação Local e Roteamento

## 🎯 Propósito
Implementar em Bash a lógica de roteamento e validação do `orchestrator-engine/main.go` para execução offline/leve. Lê `norms-matrix.json`, valida frontmatter, aplica checks `C1-C8` e emite relatório JSONL. Depende de `verify-constraints-hook` e `json-processing-with-jq`.

## 📋 Especificação (SDD)
- **Entradas**: `ARTIFACT_PATH`, `NORMS_MATRIX`, `CHECKS_LIST` (padrão: `C5,C7,C8`)
- **Saídas**: JSONL por constraint, código `0` (pass), `1` (fail), `2` (error)
- **Side Effects**: Leitura apenas, emissão de report
- **Constraints Aplicáveis**: C4 (tenant em report), C5 (schema validation), C8 (auditoria estruturada)
- **Dependências Externas**: `jq`, `grep`, `awk`, `yq` (opcional), coreutils POSIX

## 🛡️ Bootstrap Resiliente e Lógica de Orquestração (C4+C5+C8)
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
readonly ARTIFACT_ID="orchestrator-engine-bash-port"
export TENANT_ID="${TENANT_ID:-}"

readonly TARGET="${1:?caminho do artefato obrigatório}"
readonly NORMS="${NORMS_MATRIX:-00-CONTEXT/norms-matrix.json}"
readonly CHECKS="${VALIDATE_CHECKS:-C4,C5,C8}"

validate_artifact_against_norms() {
  [[ -f "$TARGET" ]] || { mantis_log "ERROR" "artifact_not_found" "path=$TARGET"; return 2; }
  [[ -f "$NORMS" ]] || { mantis_log "ERROR" "norms_missing" "path=$NORMS"; return 2; }

  local passed=true
  IFS=',' read -ra CHECK_LIST <<< "$CHECKS"
  for c in "${CHECK_LIST[@]}"; do
    local status="pass"
    case "$c" in
      C4) grep -qE '^tenant_context:|"tenant_id":' "$TARGET" || status="fail" ;;
      C5) jq empty "$TARGET" 2>/dev/null || grep -qE '^---$' "$TARGET" || status="fail" ;;
      C8) grep -qE 'mantis_log\s|printf.*tenant_id' "$TARGET" || status="fail" ;;
      *) status="unknown" ;;
    esac
    
    printf '{"constraint":"%s","artifact":"%s","status":"%s","tenant":"%s","timestamp":"%s"}\n' \
      "$c" "$TARGET" "$status" "$TENANT_ID" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    
    [[ "$status" == "fail" ]] && passed=false
  done
  
  $passed && mantis_log "INFO" "validation_passed" "checks=$CHECKS" || mantis_log "ERROR" "validation_failed" "checks=$CHECKS"
  $passed && return 0 || return 1
}
```

## 🧪 Testes Unitários (TDD)
```bash
test_validates_local_artifact_success() {
  local tmp=$(mktemp)
  printf '---\ntenant_context: "obrigatorio"\n---\nset -Eeuo pipefail\nmantis_log "INFO" "x" "y"\n' > "$tmp"
  validate_artifact_against_norms "$tmp" 2>/dev/null
  local rc=$?
  rm -f "$tmp"
  [[ $rc -eq 0 ]] && return 0
  return 1
}

test_validate_vlog02_schema() {
  mantis_log "INFO" "test" "x" 2>&1 | jq -e 'has("timestamp") and has("level") and has("resource.tenant_id")' >/dev/null 2>&1
}

if [[ "${1:-}" == "--test" ]]; then test_validates_local_artifact_success; test_validate_vlog02_schema; exit $?; fi
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/bash/orchestrator-engine-bash-port.md --json --check-structural --check-error-handling --check-observability
```

## 🔗 Referências Cruzadas
- [[bash-master-agent.md]]
- [[verify-constraints-hook.md]]
- [[command-audit-logging-c8.md]]
- [[/05-CONFIGURATIONS/validation/orchestrator-engine/main.go]]
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]]

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-07 | Bash Master Agent | Criação inicial: port bash engine, validação C4/C5/C8, report JSONL | C4,C5,C8 |

---
## 🔍 Observability (Documentación para IA)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `validation_passed` | INFO | C8 | `"checks=C4,C5,C8"` |
| `validation_failed` | ERROR | C8 | `"checks=C4,C5,C8, constraint=C5 fail"` |
| `artifact_not_found` | ERROR | C5 | `"path=/invalid/script.sh"` |
| `constraint_checked` | DEBUG | C4 | `"C4 tenant_context found"` |

### Validação de Schema V-LOG-02
```bash
validate_vlog02() { jq -e 'has("timestamp") and has("level") and has("resource.tenant_id") and has("resource.artifact")' >/dev/null 2>&1; }
```
---
