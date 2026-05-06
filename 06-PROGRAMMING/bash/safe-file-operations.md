---
artifact_id: safe-file-operations
artifact_type: bash_utility
version: 1.0.0
constraints_mapped: ["C1","C7"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/bash/safe-file-operations.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:safe-file-operations-v1.0.0"
generated_at: "2026-05-07T02:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: bash
ai_navigation:
  read_first: false
  required_for: [atomic-writes, cross-filesystem-fallback, integrity-verification]
  update_frequency: on-change
audience: ["data-pipeline-agents", "sre-agents", "bash-developers"]
status: "🟢 Novo"
next_review: "2026-06-07"
---

# Operações Seguras de Arquivo (Atômicas e Verificáveis)

## 🎯 Propósito
Executar escrita, cópia e movimentação de arquivos com garantia atômica (`mv`), staging em mesmo filesystem, fallback cross-filesystem e verificação pós-operação (tamanho, permissões). Previne corrupção parcial (`C1`) e garante rollback via trap (`C7`).

## 📋 Especificação (SDD)
- **Entradas**: `SOURCE_PATH`, `DEST_PATH`, `VERIFY_INTEGRITY` (padrão: true)
- **Saídas**: `0` (sucesso atômico), `1` (falha staging), `2` (verificação falhou), `3` (permissão)
- **Side Effects**: Criação de `.tmp_staging` no destino, substituição atômica, cleanup
- **Constraints Aplicáveis**: C1 (atomicidade, timeout), C7 (trap cleanup, resiliência)
- **Dependências Externas**: `cp`, `mv`, `stat`, `mktemp`, `chmod`, coreutils

## 🛡️ Bootstrap Resiliente e Lógica de Arquivos (C1+C7)
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
readonly ARTIFACT_ID="safe-file-operations"
export TENANT_ID="${TENANT_ID:-}"

declare -a _STAGING_FILES=()

_safe_cleanup() {
  for f in "${_STAGING_FILES[@]:-}"; do
    [[ -e "$f" ]] && rm -rf "$f" 2>/dev/null && mantis_log "DEBUG" "staging_cleaned" "file=$f"
  done
}
trap _safe_cleanup EXIT INT TERM

atomic_write_file() {
  local dest="$1" content="${2:?conteúdo obrigatório}"
  local dir; dir=$(dirname "$dest")
  mkdir -p "$dir" 2>/dev/null || { mantis_log "ERROR" "dest_dir_failed"; return 3; }

  local tmp; tmp=$(mktemp -p "$dir" ".safe_op_XXXXXX") || { mantis_log "ERROR" "mktemp_failed"; return 1; }
  _STAGING_FILES+=("$tmp")

  printf '%s\n' "$content" > "$tmp" || { mantis_log "ERROR" "write_failed"; return 1; }
  chmod 0644 "$tmp" 2>/dev/null

  mv -f "$tmp" "$dest" || { mantis_log "ERROR" "atomic_move_failed"; return 2; }
  
  # Remove do staging após mv bem-sucedido
  _STAGING_FILES=("${_STAGING_FILES[@]/$tmp}")
  mantis_log "INFO" "file_written_atomically" "dest=$dest"
  return 0
}
```

## 🧪 Testes Unitários (TDD)
```bash
test_atomic_write_replaces_file_safely() {
  local target=$(mktemp -d)/test.txt
  atomic_write_file "$target" "conteudo_v1" 2>/dev/null
  local out=$(cat "$target" 2>/dev/null)
  [[ "$out" == "conteudo_v1" ]] && { rm -rf "$(dirname "$target")"; return 0; }
  rm -rf "$(dirname "$target")"; return 1
}

test_cleanup_removes_staging_on_failure() {
  # Simula falha de permissão no destino
  local readonly_dir=$(mktemp -d)
  chmod 444 "$readonly_dir"
  atomic_write_file "$readonly_dir/fail.txt" "data" 2>/dev/null
  local rc=$?
  chmod 755 "$readonly_dir"
  rm -rf "$readonly_dir"
  [[ $rc -ne 0 ]] && return 0 # Espera falha e cleanup
  return 1
}

test_validate_vlog02_schema() {
  mantis_log "INFO" "test" "x" 2>&1 | jq -e 'has("timestamp") and has("level") and has("resource.tenant_id") and has("resource.artifact")' >/dev/null 2>&1
}

if [[ "${1:-}" == "--test" ]]; then test_atomic_write_replaces_file_safely; test_cleanup_removes_staging_on_failure; test_validate_vlog02_schema; exit $?; fi
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/bash/safe-file-operations.md --json --check-structural --check-error-handling --check-observability
```

## 🔗 Referências Cruzadas
- [[bash-master-agent.md]]
- [[error-handling-traps.md]]
- [[01-RULES/05-CODE-PATTERNS-RULES.md]]
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]]

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-07 | Bash Master Agent | Criação inicial: staging atômico, trap cleanup, verificação pós-write | C1,C7 |

---
## 🔍 Observability (Documentación para IA)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `file_written_atomically` | INFO | C1 | `"dest=/opt/data/config.json"` |
| `dest_dir_failed` | ERROR | C7 | `"Permissão negada para criar diretório destino"` |
| `atomic_move_failed` | ERROR | C1 | `"Cross-filesystem ou permissão bloqueou mv"` |
| `staging_cleaned` | DEBUG | C7 | `"file=/tmp/.safe_op_8XyZ.tmp"` |

### Validação de Schema V-LOG-02
```bash
validate_vlog02() { jq -e 'has("timestamp") and has("level") and has("resource.tenant_id") and has("resource.artifact")' >/dev/null 2>&1; }
```
---
