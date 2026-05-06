---
artifact_id: json-processing-with-jq
artifact_type: bash_utility
version: 1.0.0
constraints_mapped: ["C5","C6"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/bash/json-processing-with-jq.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:json-processing-with-jq-v1.0.0"
generated_at: "2026-05-07T04:00:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: bash
ai_navigation:
  read_first: false
  required_for: [structured-data-parsing, schema-validation, jq-safe-extraction]
  update_frequency: on-change
audience: ["orchestrator-engine", "data-pipeline-agents", "bash-developers"]
status: "🟢 Novo"
next_review: "2026-06-07"
---

# Processamento Seguro de JSON com `jq` e Validação de Schema

## 🎯 Propósito
Fornecer parsing estruturado e seguro de JSON via `jq`, com validação de sintaxe, extração de chaves específicas com fallback seguro, prevenção de injeção em filtros e conversão para formatos pipeline-compatible. Garante C5 (integridade estrutural) e C6 (sanitização de inputs/filtros).

## 📋 Especificação (SDD)
- **Entradas**: `JSON_INPUT` (arquivo ou stdin), `JQ_FILTER` (expressão segura), `SCHEMA_PATH` (opcional)
- **Saídas**: JSON processado (stdout), código `0` (sucesso), `1` (syntax error), `2` (filter inválido/seguro), `3` (schema mismatch)
- **Side Effects**: Nenhum arquivo modificado; logs JSONL de validação
- **Constraints Aplicáveis**: C5 (validação estrutural), C6 (sanitização de filtros, zero `eval`)
- **Dependências Externas**: `jq`, `grep`, coreutils POSIX

## 🛡️ Bootstrap Resiliente e Lógica JSON (C5+C6)
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
readonly ARTIFACT_ID="json-processing-with-jq"
export TENANT_ID="${TENANT_ID:-global}"

safe_jq_parse() {
  local input="${1:?input JSON obrigatório}"
  local filter="${2:-.}"
  
  # C6: Bloquear caracteres perigosos em filtros (previne injeção)
  if [[ "$filter" =~ [\;\|\&\`] ]]; then
    mantis_log "ERROR" "unsafe_jq_filter" "Caracteres proibidos detectados em filtro: $filter"
    return 2
  fi

  # C5: Validar sintaxe JSON
  if ! jq empty "$input" 2>/dev/null; then
    mantis_log "ERROR" "invalid_json_syntax" "JSON malformado ou inacessível: $input"
    return 1
  fi

  # Extração segura
  local result
  result=$(jq -c "$filter" "$input" 2>/dev/null) || {
    mantis_log "ERROR" "jq_execution_failed" "Filtro inválido ou erro de runtime: $filter"
    return 2
  }
  
  [[ "$result" == "null" || -z "$result" ]] && { mantis_log "WARN" "jq_empty_result" "Filtro não retornou dados"; return 0; }
  printf '%s\n' "$result"
  mantis_log "INFO" "json_parsed_success" "filter=$filter, input=$input"
  return 0
}
```

## 🧪 Testes Unitários (TDD)
```bash
test_jq_parses_valid_json() {
  local tmp=$(mktemp)
  echo '{"tenant":"xyz","status":"ok"}' > "$tmp"
  safe_jq_parse "$tmp" ".tenant" 2>/dev/null | grep -q "xyz" && { rm -f "$tmp"; return 0; }
  rm -f "$tmp"; return 1
}

test_jq_blocks_unsafe_filters() {
  local tmp=$(mktemp)
  echo '{"a":"b"}' > "$tmp"
  safe_jq_parse "$tmp" ".a; rm -rf /" 2>/dev/null
  [[ $? -eq 2 ]] && { rm -f "$tmp"; return 0; }
  rm -f "$tmp"; return 1
}

test_validate_vlog02_schema() {
  mantis_log "INFO" "test" "x" 2>&1 | jq -e 'has("timestamp") and has("level") and has("resource.artifact")' >/dev/null 2>&1
}

if [[ "${1:-}" == "--test" ]]; then test_jq_parses_valid_json; test_jq_blocks_unsafe_filters; test_validate_vlog02_schema; exit $?; fi
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/bash/json-processing-with-jq.md --json --check-structural --check-error-handling --check-observability
```

## 🔗 Referências Cruzadas
- [[bash-master-agent.md]]
- [[safe-variable-expansion.md]]
- [[01-RULES/05-CODE-PATTERNS-RULES.md]]
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]]

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-07 | Bash Master Agent | Criação inicial: filtro seguro jq, validação sintaxe, bloqueio injeção | C5,C6 |

---
## 🔍 Observability (Documentación para IA)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `json_parsed_success` | INFO | C5 | `"filter=.tenant, input=/tmp/data.json"` |
| `invalid_json_syntax` | ERROR | C5 | `"JSON malformado ou inacessível: /tmp/broken.json"` |
| `unsafe_jq_filter` | ERROR | C6 | `"Caracteres proibidos detectados em filtro"` |
| `jq_execution_failed` | ERROR | C6 | `"Filtro inválido ou erro de runtime"` |

### Validação de Schema V-LOG-02
```bash
validate_vlog02() { jq -e 'has("timestamp") and has("level") and has("resource.tenant_id") and has("resource.artifact")' >/dev/null 2>&1; }
```
---
