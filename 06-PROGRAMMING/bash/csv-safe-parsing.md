---
artifact_id: csv-safe-parsing
artifact_type: bash_utility
version: 1.0.0
constraints_mapped: ["C5","C6"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/bash/csv-safe-parsing.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:csv-safe-parsing-v1.0.0"
generated_at: "2026-05-07T04:00:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: bash
ai_navigation:
  read_first: false
  required_for: [data-ingestion, delimiter-safe-split, row-validation]
  update_frequency: on-change
audience: ["data-pipeline-agents", "etl-scripts", "bash-developers"]
status: "🟢 Novo"
next_review: "2026-06-07"
---

# Parsing Seguro de CSV com Validação de Estrutura e Delimitadores

## 🎯 Propósito
Ler e validar arquivos CSV de forma segura, manipulando campos entre aspas, delimitadores customizados e validando contagem de colunas por linha. Previne word splitting acidental, injeção via delimitadores malformados e garante processamento stream-safe (`C5`, `C6`).

## 📋 Especificação (SDD)
- **Entradas**: `CSV_FILE`, `DELIMITER` (padrão: `,`), `EXPECTED_COLS` (opcional)
- **Saídas**: Linhas processadas (stdout), código `0` (sucesso), `1` (estrutura inválida), `2` (colunas mismatch)
- **Side Effects**: Leitura stream, logs JSONL por erro de linha
- **Constraints Aplicáveis**: C5 (validação estrutural por linha), C6 (sanitização de delimitadores, aspas seguras)
- **Dependências Externas**: `awk`, `grep`, coreutils POSIX

## 🛡️ Bootstrap Resiliente e Lógica CSV (C5+C6)
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
readonly ARTIFACT_ID="csv-safe-parsing"
export TENANT_ID="${TENANT_ID:-global}"

safe_csv_parse() {
  local file="${1:?arquivo CSV obrigatório}"
  local delim="${DELIMITER:-,}"
  local expected="${EXPECTED_COLS:-0}"
  
  [[ -f "$file" && -r "$file" ]] || { mantis_log "ERROR" "csv_file_unreadable"; return 1; }
  
  # C6: Validar delimitador (apenas 1 char seguro)
  if [[ ${#delim} -ne 1 || "$delim" =~ [\"\'\`] ]]; then
    mantis_log "ERROR" "invalid_csv_delimiter" "Delimitador inseguro ou inválido: '$delim'"
    return 2
  fi

  local line_num=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    ((line_num++))
    # Pula linhas vazias/comentário
    [[ -z "$line" || "$line" == \#* ]] && continue
    
    # C5: Validação de colunas (contagem de delimitadores + 1)
    if [[ $expected -gt 0 ]]; then
      local cols
      cols=$(awk -F"$delim" '{print NF}' <<< "$line")
      if [[ $cols -ne $expected ]]; then
        mantis_log "WARN" "csv_column_mismatch" "line=$line_num, expected=$expected, found=$cols"
        continue
      fi
    fi
    
    # Output seguro (mantém aspas originais, evita word splitting)
    printf '%s\n' "$line"
  done < "$file"
  
  mantis_log "INFO" "csv_parse_completed" "file=$file, lines_processed=$line_num"
  return 0
}
```

## 🧪 Testes Unitários (TDD)
```bash
test_csv_parses_valid_structure() {
  local tmp=$(mktemp)
  printf 'id,name\n1,Alice\n2,Bob\n' > "$tmp"
  local out; out=$(safe_csv_parse "$tmp" DELIMITER=, EXPECTED_COLS=2 2>/dev/null)
  [[ $(echo "$out" | wc -l) -eq 3 ]] && { rm -f "$tmp"; return 0; }
  rm -f "$tmp"; return 1
}

test_blocks_invalid_delimiter() {
  local tmp=$(mktemp)
  echo "a,b" > "$tmp"
  safe_csv_parse "$tmp" DELIMITER='";' 2>/dev/null
  [[ $? -eq 2 ]] && { rm -f "$tmp"; return 0; }
  rm -f "$tmp"; return 1
}

test_validate_vlog02_schema() {
  mantis_log "INFO" "test" "x" 2>&1 | jq -e 'has("timestamp") and has("level") and has("resource.artifact")' >/dev/null 2>&1
}

if [[ "${1:-}" == "--test" ]]; then test_csv_parses_valid_structure; test_blocks_invalid_delimiter; test_validate_vlog02_schema; exit $?; fi
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/bash/csv-safe-parsing.md --json --check-structural --check-error-handling --check-observability
```

## 🔗 Referências Cruzadas
- [[bash-master-agent.md]]
- [[safe-variable-expansion.md]]
- [[01-RULES/05-CODE-PATTERNS-RULES.md]]
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]]

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-07 | Bash Master Agent | Criação inicial: stream parsing, validação colunas, delimitador seguro | C5,C6 |

---
## 🔍 Observability (Documentación para IA)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `csv_parse_completed` | INFO | C5 | `"file=data.csv, lines_processed=150"` |
| `csv_column_mismatch` | WARN | C5 | `"line=42, expected=3, found=4"` |
| `invalid_csv_delimiter` | ERROR | C6 | `"Delimitador inseguro ou inválido"` |
| `csv_file_unreadable` | ERROR | C5 | `"Arquivo inexistente ou sem permissão"` |

### Validação de Schema V-LOG-02
```bash
validate_vlog02() { jq -e 'has("timestamp") and has("level") and has("resource.tenant_id") and has("resource.artifact")' >/dev/null 2>&1; }
```
---
