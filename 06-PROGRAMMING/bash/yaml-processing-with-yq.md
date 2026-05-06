---
artifact_id: yaml-processing-with-yq
artifact_type: bash_utility
version: 1.0.0
constraints_mapped: ["C5","C6"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/bash/yaml-processing-with-yq.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:yaml-processing-with-yq-v1.0.0"
generated_at: "2026-05-07T04:00:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: bash
ai_navigation:
  read_first: false
  required_for: [config-parsing, yq-safe-extraction, yaml-to-json-conversion]
  update_frequency: on-change
audience: ["orchestrator-engine", "config-management-agents", "bash-developers"]
status: "🟢 Novo"
next_review: "2026-06-07"
---

# Processamento Seguro de YAML com `yq` e Fallback Nativo

## 🎯 Propósito
Extrair e validar dados YAML de forma segura utilizando `yq` (ou parser fallback), garantindo integridade estrutural (`C5`), sanitização de paths de extração (`C6`) e conversão segura para JSON para pipelines downstream.

## 📋 Especificação (SDD)
- **Entradas**: `YAML_FILE`, `YQ_PATH` (ex: `.config.database.host`), `OUTPUT_FORMAT` (`json` ou `raw`)
- **Saídas**: Dados extraídos, código `0` (sucesso), `1` (arquivo inválido), `2` (path inválido), `3` (`yq` indisponível + fallback falhou)
- **Side Effects**: Leitura apenas, logs JSONL
- **Constraints Aplicáveis**: C5 (estrutura YAML válida), C6 (sanitização de paths, zero injeção)
- **Dependências Externas**: `yq` (recomendado), `awk`/`sed` (fallback), `jq`, coreutils POSIX

## 🛡️ Bootstrap Resiliente e Lógica YAML (C5+C6)
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
readonly ARTIFACT_ID="yaml-processing-with-yq"
export TENANT_ID="${TENANT_ID:-global}"

safe_yq_parse() {
  local file="${1:?arquivo YAML obrigatório}"
  local path="${2:-.}"
  local fmt="${3:-json}"
  
  [[ -f "$file" && -r "$file" ]] || { mantis_log "ERROR" "yaml_file_unreadable" "path=$file"; return 1; }
  
  # C6: Sanitizar path (apenas letras, números, pontos, hífens, colchetes)
  if [[ ! "$path" =~ ^[a-zA-Z0-9._\-\[\]\"]+$ ]]; then
    mantis_log "ERROR" "unsafe_yq_path" "Path contém caracteres inválidos: $path"
    return 2
  fi

  # Primário: yq
  if command -v yq &>/dev/null; then
    if [[ "$fmt" == "json" ]]; then
      yq eval "$path" -o json "$file" 2>/dev/null || { mantis_log "ERROR" "yq_execution_failed"; return 2; }
    else
      yq eval "$path" "$file" 2>/dev/null || { mantis_log "ERROR" "yq_execution_failed"; return 2; }
    fi
    mantis_log "INFO" "yq_parse_success" "path=$path, file=$file"
    return 0
  fi
  
  mantis_log "WARN" "yq_missing_fallback" "Usando parser básico (limitado a chaves simples)"
  # Fallback básico para YAML plano
  grep -E "^${path//[.\[\]]/\\ }: " "$file" | awk -F': ' '{print $2}' | tr -d '"' || {
    mantis_log "ERROR" "fallback_parse_failed"; return 3;
  }
}
```

## 🧪 Testes Unitários (TDD)
```bash
test_yq_parses_valid_yaml() {
  local tmp=$(mktemp)
  printf 'database:\n  host: "db.internal"\n  port: 5432\n' > "$tmp"
  safe_yq_parse "$tmp" ".database.host" 2>/dev/null | grep -q "db.internal" && { rm -f "$tmp"; return 0; }
  rm -f "$tmp"; return 1
}

test_blocks_unsafe_yaml_paths() {
  local tmp=$(mktemp)
  echo "key: value" > "$tmp"
  safe_yq_parse "$tmp" "; rm -rf /" 2>/dev/null
  [[ $? -eq 2 ]] && { rm -f "$tmp"; return 0; }
  rm -f "$tmp"; return 1
}

test_validate_vlog02_schema() {
  mantis_log "INFO" "test" "x" 2>&1 | jq -e 'has("timestamp") and has("level") and has("resource.artifact")' >/dev/null 2>&1
}

if [[ "${1:-}" == "--test" ]]; then test_yq_parses_valid_yaml; test_blocks_unsafe_yaml_paths; test_validate_vlog02_schema; exit $?; fi
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/bash/yaml-processing-with-yq.md --json --check-structural --check-error-handling --check-observability
```

## 🔗 Referências Cruzadas
- [[bash-master-agent.md]]
- [[json-processing-with-jq.md]]
- [[safe-variable-expansion.md]]
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]]

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-07 | Bash Master Agent | Criação inicial: yq seguro, path sanitization, fallback nativo | C5,C6 |

---
## 🔍 Observability (Documentación para IA)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `yq_parse_success` | INFO | C5 | `"path=.database.host, file=config.yaml"` |
| `unsafe_yq_path` | ERROR | C6 | `"Path contém caracteres inválidos"` |
| `yq_missing_fallback` | WARN | C7 | `"Usando parser básico (limitado)"` |
| `yaml_file_unreadable` | ERROR | C5 | `"path=/missing.yaml"` |

### Validação de Schema V-LOG-02
```bash
validate_vlog02() { jq -e 'has("timestamp") and has("level") and has("resource.tenant_id") and has("resource.artifact")' >/dev/null 2>&1; }
```
---
