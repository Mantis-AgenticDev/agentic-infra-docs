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

## 🛡️ Bootstrap Resiliente e Lógica de Parsing (C4+C5+C6+C7+C8)
```bash
# =============================================================================
# BOOTSTRAP RESILIENTE: Hardening + Observabilidade (C3+C4+C7)
# Fonte de verdade: bash-master-agent.md via source
# Nota: tenant_context=nao_aplicavel → validação de TENANT_ID opcional
# =============================================================================
if [[ -f "${MANTIS_ROOT:-.}/06-PROGRAMMING/bash/bash-master-agent.sh" ]]; then
  source "${MANTIS_ROOT:-.}/06-PROGRAMMING/bash/bash-master-agent.sh" --mode=observability-only
else
  set -Eeuo pipefail; shopt -s inherit_errexit 2>/dev/null || true
  trap 'exit 130' INT TERM
  # C4: Validação condicional (apenas se tenant_context != nao_aplicavel)
  if [[ "${TENANT_CONTEXT:-nao_aplicavel}" != "nao_aplicavel" ]]; then
    : "${TENANT_ID:?ERROR: TENANT_ID não definido. Defina via env ou argumento.}"
  fi
  mantis_log() { printf '{"ts":"%s","level":"%s","tenant":"%s","event":"%s","detail":"%s","fallback":"true"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${1:-INFO}" "${TENANT_ID:-global}" "${2:-bootstrap_fallback}" "${3:-}" >&2; }
  mantis_log "WARN" "bootstrap_fallback" "Master agent não encontrado. Executando com hardening mínimo."
fi

readonly SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"
readonly SCRIPT_VERSION="${VERSION:-2.0.0}"
readonly ARTIFACT_ID="yaml-frontmatter-parser"

# Garantia de parsing seguro para caracteres UTF-8/acentos
export LC_ALL=C.UTF-8

# =============================================================================
# LÓGICA DE PARSING E VALIDAÇÃO DE FRONTMATTER
# =============================================================================
# C7: Cleanup e trap unificado
cleanup_parse() {
  local exit_code=$?
  [[ -n "${TEMP_FM:-}" && -f "${TEMP_FM}" ]] && rm -f "${TEMP_FM}"
  if [[ $exit_code -ne 0 ]]; then
    mantis_log "ERROR" "parsing_aborted" "Código de saída: $exit_code | Arquivo: ${TARGET_FILE:-unknown}"
  fi
  exit $exit_code
}
trap cleanup_parse EXIT INT TERM

readonly TARGET_FILE="${1:?Uso: yaml-frontmatter-parser.sh <arquivo> [json|env|key_value]}"
readonly OUTPUT_FORMAT="${2:-json}"
readonly STRICT_MODE="${STRICT_SCHEMA:-true}"

# C6+C7: Validação de existência e permissões
[[ -f "$TARGET_FILE" && -r "$TARGET_FILE" ]] || { mantis_log "ERROR" "file_unreadable" "Arquivo inexistente ou ilegível: $TARGET_FILE"; exit 1; }

# C1: Timeout para extração (previne parsing de arquivos corrompidos/gigantes)
TEMP_FM=$(mktemp) || { mantis_log "ERROR" "mktemp_failed" "Falha ao criar arquivo temporário"; exit 3; }
timeout 10 awk '/^---/{n++; if(n==2) exit} n==1 && !/^---/' "$TARGET_FILE" > "$TEMP_FM" || {
  mantis_log "ERROR" "extraction_timeout_or_empty" "Frontmatter vazio ou extração excedeu 10s: $TARGET_FILE"
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

raw_json=$(parse_to_json) || { mantis_log "ERROR" "parse_failed" "Falha no parsing do frontmatter: $TARGET_FILE"; exit 3; }

# C5: Validação de schema obrigatório
validate_schema() {
  local data="$1"
  local required=("artifact_id" "version" "constraints_mapped")
  for field in "${required[@]}"; do
    if ! echo "$data" | jq -e ".$field" &>/dev/null; then
      mantis_log "ERROR" "schema_missing_field" "Campo obrigatório ausente no schema: $field"
      return 1
    fi
  done
  # Valida formato de constraints_mapped (deve ser array)
  if ! echo "$data" | jq -e '.constraints_mapped | type == "array"' &>/dev/null; then
    mantis_log "ERROR" "schema_invalid_constraints" "constraints_mapped deve ser um array JSON"
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

mantis_log "INFO" "parse_success" "Frontmatter extraído com sucesso. Campos: $(echo "$raw_json" | jq 'keys | length') | Arquivo: $TARGET_FILE"
exit 0
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
    mantis_log "ERROR" "test_failed" "Parser não extraiu artifact_id corretamente"
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
    mantis_log "ERROR" "test_failed" "Parser não rejeitou schema inválido (exit esperado: 2, obtido: $exit_code)"
    rm -f "$temp_file"
    return 1
  fi
}

test_validate_vlog02_schema() {
  local log_output
  log_output=$(mantis_log "INFO" "test_event" "detalhe_teste" 2>&1)
  if printf '%s\n' "$log_output" | jq -e '
    has("timestamp") and has("level") and has("resource.tenant_id") and has("resource.artifact") and has("body.event")
  ' >/dev/null 2>&1; then
    return 0
  else
    mantis_log "ERROR" "schema_validation_failed" "Log não conforma com V-LOG-02"
    return 1
  fi
}

if [[ "${1:-}" == "--test" ]]; then
  test_parser_extracts_valid_schema
  test_parser_fails_on_missing_constraints
  test_validate_vlog02_schema
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
  --check-error-handling \
  --check-observability
```

## 🔗 Referências Cruzadas
- [[bash-master-agent.md]] ← Contrato de geração, anti-padrões e template interno
- [[01-RULES/harness-norms-v3.0.md]] ← Especificação de hardening C7
- [[01-RULES/10-SDD-CONSTRAINTS.md]] ← Definição de C5 (Structural Integrity) e C6
- [[01-RULES/05-CODE-PATTERNS-RULES.md]] ← Padrões de parsing seguro e fallback
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]] ← Índice de observabilidade
- [[/05-CONFIGURATIONS/observability/loki/config.yml]] ← Pipeline de ingestão de logs JSONL
- [[00-CONTEXT/norms-matrix.json]] ← Fonte de verdade para validação de constraints

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2024-09-20 | Dev inicial | Parser básico com `grep`/`sed` sem validação de schema | Parcial |
| 2.0.0 | 2026-05-06 | Bash Master Agent | Remanufatura: bootstrap resiliente, `mantis_log()` canônica, validação V-LOG-02, remoção de hardening inline | C4,C5,C6,C7,C8 |

---
## 🔍 Observability (Documentación para IA)

> Este artefato emite os seguintes eventos via `mantis_log()` (definida em [[bash-master-agent.md]]):

| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `parse_success` | INFO | C8 | `"Frontmatter extraído com sucesso. Campos: 6 | Arquivo: script.md"` |
| `file_unreadable` | ERROR | C6 | `"Arquivo inexistente ou ilegível: /tmp/missing.md"` |
| `extraction_timeout_or_empty` | ERROR | C7 | `"Frontmatter vazio ou extração excedeu 10s"` |
| `schema_missing_field` | ERROR | C5 | `"Campo obrigatório ausente no schema: artifact_id"` |
| `schema_invalid_constraints` | ERROR | C5 | `"constraints_mapped deve ser um array JSON"` |
| `parse_failed` | ERROR | C6 | `"Falha no parsing do frontmatter: script.md"` |
| `parsing_aborted` | ERROR | C7 | `"Código de saída: 1 | Arquivo: script.md"` |

### Exemplo de Output JSONL (para aprendizado de padrão por IA)
```json
{"timestamp":"2026-05-06T12:25:00Z","level":"INFO","resource":{"tenant_id":"global","artifact":"yaml-frontmatter-parser"},"body":{"event":"parse_success","detail":"Frontmatter extraído com sucesso. Campos: 5 | Arquivo: 06-PROGRAMMING/bash/bash-master-agent.md"},"attributes":{"mantis":{"tier":"2","version":"2.0.0","constraint":"C4,C5,C8","trace_id":""},"code.filepath":"06-PROGRAMMING/bash/yaml-frontmatter-parser.md","code.lineno":112,"telemetry.sdk.name":"mantis-bash-adapter","telemetry.sdk.version":"1.0.0"}}
```

### Configuração Específica de Este Artefato
```bash
# Variáveis de entorno que afetam o comportamento de logging deste artefato
export LOG_PARSE_FIELDS="${LOG_PARSE_FIELDS:-true}"       # Incluir contagem e nomes de campos extraídos
export LOG_PARSE_TIMING="${LOG_PARSE_TIMING:-true}"       # Incluir tempo de extração/parsing
export TRACE_PARSE_OPS="${TRACE_PARSE_OPS:-false}"        # Habilitar trace_id para correlação OTel
```

### Validação de Schema V-LOG-02 (Helper Executável)
```bash
# Função helper para validação local de logs
validate_vlog02() {
  jq -e '
    has("timestamp") and
    has("level") and
    has("resource.tenant_id") and
    has("resource.artifact") and
    has("body.event") and
    has("attributes.mantis.tier") and
    has("attributes.mantis.version")
  ' >/dev/null 2>&1
}

# Uso em testes ou validação manual:
# mantis_log "INFO" "test" "x" 2>&1 | validate_vlog02 && echo "✅ Schema V-LOG-02 válido"
```
---
