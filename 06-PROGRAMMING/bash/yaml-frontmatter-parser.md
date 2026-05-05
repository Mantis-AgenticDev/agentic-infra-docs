---
artifact_id: yaml-frontmatter-parser
artifact_type: bash_utility
version: 2.0.0
constraints_mapped: ["C4","C5","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/bash/yaml-frontmatter-parser.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:yaml-frontmatter-parser-v2.0.0-remanufatured"
generated_at: "2026-05-06T12:25:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: bash
ai_navigation:
  read_first: false
  required_for: [contract-validation, metadata-extraction, sdd-compliance]
  update_frequency: on-change
audience: ["orchestrator-engine", "artifact-generators", "validation-hooks"]
status: "🟡 Em remanufatura"
next_review: "2026-06-05"
---

# Parser Seguro de Frontmatter YAML com Validação de Schema

## 🎯 Propósito
Extrair e validar metadados YAML de artefatos Markdown/Shell de forma segura, garantindo conformidade com o contrato SDD (C5), propagação auditável de contexto (C4/C8) e fallback nativo quando `yq` não está disponível. Projetado para ingestão por orchestrator-engine, validadores de pipeline e agentes geradores que necessitam de leitura confiável de `artifact_id`, `constraints_mapped`, `version` e demais campos contratuais.

## 📋 Especificação (SDD)
- **Entradas**: 
  - `$1`: Caminho absoluto ou relativo ao arquivo `.md` ou `.sh.md`
  - `$OUTPUT_FORMAT`: `json` (padrão), `env`, `key_value`
  - `$STRICT_SCHEMA`: `true` (padrão) ou `false` (modo relaxado)
- **Saídas**: 
  - Objeto JSON ou variáveis exportadas para ambiente pai
  - Códigos: `0` (válido), `1` (arquivo ausente/ilegível), `2` (schema inválido), `3` (erro de parsing/timeout)
  - Logs JSONL em stderr com `tenant_id`, `file`, `parsed_fields`, `validation_status`
- **Side Effects**: 
  - Criação de arquivo temporário seguro durante extração
  - Nenhum dado modificado; operação puramente de leitura
- **Constraints Aplicáveis**: C4 (contexto de tenant em logs), C5 (validação estrutural de frontmatter), C6 (sanitização de entrada), C7 (resiliência com timeout e trap), C8 (auditoria JSONL)
- **Dependências Externas**: `awk`, `grep`, `sed`, `jq` (obrigatório), `yq` (opcional), coreutils POSIX

## 🛡️ Hardening (Harness Norms v3.0 - Executável)
```bash
#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
export LC_ALL=C.UTF-8  # Garante parsing seguro de caracteres UTF-8/acentos

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_VERSION="2.0.0"

# C8: Logging estruturado JSONL em stderr
log_parser() {
  local level="${1:-INFO}"
  local event="${2:-parse_event}"
  local detail="${3:-}"
  printf '{"ts":"%s","level":"%s","tenant":"%s","script":"%s","event":"%s","detail":"%s"}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    "$level" \
    "${TENANT_ID:-unknown}" \
    "$SCRIPT_NAME" \
    "$event" \
    "$detail" >&2
}

# C7: Cleanup e trap unificado
cleanup() {
  local exit_code=$?
  [[ -n "${TEMP_FM:-}" && -f "${TEMP_FM}" ]] && rm -f "${TEMP_FM}"
  if [[ $exit_code -ne 0 ]]; then
    log_parser "ERROR" "parser_failed" "Código de saída: $exit_code"
  fi
  exit $exit_code
}
trap cleanup EXIT INT TERM

readonly TARGET_FILE="${1:?Uso: yaml-frontmatter-parser.sh <arquivo> [json|env|key_value]}"
readonly OUTPUT_FORMAT="${2:-json}"
readonly STRICT_MODE="${STRICT_SCHEMA:-true}"

# C6+C7: Validação de existência e permissões
[[ -f "$TARGET_FILE" && -r "$TARGET_FILE" ]] || { log_parser "ERROR" "file_unreadable" "$TARGET_FILE"; exit 1; }

# C1: Timeout para extração (previne parsing de arquivos corrompidos/gigantes)
TEMP_FM=$(mktemp) || { log_parser "ERROR" "mktemp_failed"; exit 3; }
timeout 10 awk '/^---/{n++; if(n==2) exit} n==1 && !/^---/' "$TARGET_FILE" > "$TEMP_FM" || {
  log_parser "ERROR" "extraction_timeout_or_empty"
  exit 3
}

# Parsing com yq (primário) ou fallback nativo awk+jq
parse_to_json() {
  if command -v yq &>/dev/null; then
    yq eval '.' -o json "$TEMP_FM" 2>/dev/null
  else
    # Fallback seguro: ignora comentários, converte chave:valor para JSON
    grep -E '^[a-zA-Z_][a-zA-Z0-9_]*:' "$TEMP_FM" | \
    sed 's/^\([a-zA-Z_][a-zA-Z0-9_]*\):[[:space:]]*\(.*\)/\1 "\2"/' | \
    awk 'BEGIN{printf "{"} NR>1{printf ","} {printf "\"%s\":%s", $1, $2} END{printf "}"}'
  fi
}

raw_json=$(parse_to_json) || { log_parser "ERROR" "parse_failed"; exit 3; }

# C5: Validação de schema obrigatório
validate_schema() {
  local data="$1"
  local required=("artifact_id" "version" "constraints_mapped")
  for field in "${required[@]}"; do
    if ! echo "$data" | jq -e ".$field" &>/dev/null; then
      log_parser "ERROR" "schema_missing_field" "$field"
      return 1
    fi
  done
  # Valida formato de constraints_mapped (deve ser array)
  if ! echo "$data" | jq -e '.constraints_mapped | type == "array"' &>/dev/null; then
    log_parser "ERROR" "schema_invalid_constraints" "constraints_mapped must be array"
    return 1
  fi
  return 0
}

if [[ "$STRICT_MODE" == "true" ]]; then
  validate_schema "$raw_json" || exit 2
fi

# Output conforme formato solicitado
case "$OUTPUT_FORMAT" in
  env)    echo "$raw_json" | jq -r 'to_entries[] | "export \(.key)=\(.value | @sh)"' ;;
  key_value) echo "$raw_json" | jq -r 'to_entries[] | "\(.key)=\(.value)"' ;;
  json|*) echo "$raw_json" | jq '.' ;;
esac

log_parser "INFO" "parse_success" "Fields: $(echo "$raw_json" | jq 'keys | length')"
```

## 🧪 Testes Unitários (TDD)
```bash
test_parser_extracts_valid_schema() {
  # Arrange
  local temp_file
  temp_file=$(mktemp)
  cat > "$temp_file" << 'EOF'
---
artifact_id: test-artifact
version: "1.0.0"
constraints_mapped: ["C3","C5"]
tenant_context: "nao_aplicavel"
---
# Conteúdo ignorado
EOF

  # Act
  local output
  output=$(bash "${BASH_SOURCE[0]}" "$temp_file" json 2>/dev/null) || true

  # Assert
  if echo "$output" | jq -e '.artifact_id == "test-artifact"' &>/dev/null; then
    rm -f "$temp_file"
    return 0
  else
    printf '[TEST_FAIL] Parser não extraiu artifact_id corretamente\n' >&2
    rm -f "$temp_file"
    return 1
  fi
}

test_parser_fails_on_missing_constraints() {
  # Arrange
  local temp_file
  temp_file=$(mktemp)
  cat > "$temp_file" << 'EOF'
---
artifact_id: broken-artifact
version: "1.0.0"
---
EOF

  # Act
  bash "${BASH_SOURCE[0]}" "$temp_file" json 2>/dev/null
  local exit_code=$?

  # Assert
  if [[ $exit_code -eq 2 ]]; then
    rm -f "$temp_file"
    return 0
  else
    printf '[TEST_FAIL] Parser não rejeitou schema inválido (exit esperado: 2, obtido: %s)\n' "$exit_code" >&2
    rm -f "$temp_file"
    return 1
  fi
}

if [[ "${1:-}" == "--test" ]]; then
  test_parser_extracts_valid_schema
  test_parser_fails_on_missing_constraints
  exit $?
fi
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/bash/yaml-frontmatter-parser.md \
  --json \
  --check-secrets \
  --check-tenant-isolation \
  --check-structural \
  --check-resource-limits \
  --check-error-handling
```

## 🔗 Referências Cruzadas
- [[bash-master-agent.md]] ← Contrato de geração, anti-padrões e template interno
- [[01-RULES/harness-norms-v3.0.md]] ← Especificação de hardening C7
- [[01-RULES/10-SDD-CONSTRAINTS.md]] ← Definição de C5 (Structural Integrity) e C6
- [[01-RULES/05-CODE-PATTERNS-RULES.md]] ← Padrões de parsing seguro e fallback
- [[00-CONTEXT/norms-matrix.json]] ← Fonte de verdade para validação de constraints

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2024-09-20 | Dev inicial | Parser básico com `grep`/`sed` sem validação de schema | Parcial |
| 2.0.0 | 2026-05-06 | Bash Master Agent | Remanufatura completa: timeout C1, validação C5 rigorosa, JSONL C8, fallback UTF-8, testes TDD | C4,C5,C6,C7,C8 |

---
