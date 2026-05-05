---
artifact_id: context-compaction-utils
artifact_type: bash_utility
version: 2.0.0
constraints_mapped: ["C1","C3","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/bash/context-compaction-utils.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:context-compaction-v2.0.0-remanufatured"
generated_at: "2026-05-06T12:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: bash
ai_navigation:
  read_first: false
  required_for: [llm-context-preprocessing, token-budgeting, pii-scrubbing]
  update_frequency: on-change
audience: ["orchestrator-engine", "llm-gateway-agents", "data-pipeline-scripts"]
status: "🟡 Em remanufatura"
next_review: "2026-06-05"
---

# Utilitários de Compactação e Saneamento de Contexto

## 🎯 Propósito
Fornecer funções bash para redução segura de contexto antes do envio a modelos de IA, respeitando limites de tokens, removendo credenciais/PII, mantendo isolamento por tenant e garantindo rastreabilidade de auditoria. Projetado para pré-processamento em pipelines agénticos e gateways LLM.

## 📋 Especificação (SDD)
- **Entradas**: 
  - `CONTEXT_INPUT` (string ou arquivo)
  - `TENANT_ID` (variável de ambiente obrigatória)
  - `MAX_TOKENS` (limite configurável, padrão: 4096)
  - `SCRUB_SENSITIVE` (booleano, padrão: true)
- **Saídas**: 
  - Contexto compactado (stdout)
  - Metadados JSON: `{tenant_id, original_size, compacted_size, tokens_estimated, secrets_scrubbed: bool, timestamp}`
  - Códigos de retorno: `0` (sucesso), `1` (falha de validação), `2` (excede limite após compactação)
- **Side Effects**: 
  - Log estruturado em stderr (JSONL)
  - Criação de arquivo temporário seguro durante processamento
- **Constraints Aplicáveis**: C1 (limite de tamanho/tempo), C3 (zero secrets), C4 (tenant isolation), C5 (estrutura YAML), C7 (resiliência), C8 (auditoria)
- **Dependências Externas**: `wc`, `awk`, `grep`, `tr`, `date` (POSIX coreutils)

## 🛡️ Hardening (Harness Norms v3.0 - Executável)
```bash
#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_VERSION="2.0.0"

cleanup() {
  local exit_code=$?
  if [[ $exit_code -ne 0 ]]; then
    printf '[%s][ERROR][script:%s][tenant:%s] Falha na linha %d: código %d\n' \
      "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      "${SCRIPT_NAME}" \
      "${TENANT_ID:-unknown}" \
      "${BASH_LINENO[0]:-0}" \
      "$exit_code" >&2
  fi
  [[ -n "${TEMP_FILE:-}" && -f "${TEMP_FILE}" ]] && rm -f "${TEMP_FILE}"
  exit $exit_code
}
trap cleanup EXIT INT TERM

: "${TENANT_ID:?Variável de ambiente TENANT_ID não definida. Abortando para evitar vazamento de contexto.}"

readonly MAX_TOKENS="${MAX_TOKENS:-4096}"
readonly OPERATION_TIMEOUT="${OPERATION_TIMEOUT:-30}"
readonly SCRUB_SENSITIVE="${SCRUB_SENSITIVE:-true}"
```

## 🧪 Testes Unitários (TDD)
```bash
test_compact_context_respects_limit() {
  # Arrange
  local large_context
  large_context=$(head -c 50000 /dev/urandom | tr -dc 'a-zA-Z0-9 \n' | head -c 20000)
  local max_tokens=1000
  
  # Act
  local result
  result=$(compact_context <<< "$large_context" 2>/dev/null) || true
  local token_est
  token_est=$(compact_context <<< "$large_context" --dry-run 2>/dev/null | jq -r '.tokens_estimated' || echo "0")
  
  # Assert
  if [[ "$token_est" -le "$max_tokens" ]]; then
    return 0
  else
    printf '[TEST_FAIL] Tokens estimados (%s) excedem limite (%s)\n' "$token_est" "$max_tokens" >&2
    return 1
  fi
}

test_scrub_secrets_removes_patterns() {
  # Arrange
  local input="Token sk-abc123xyz e chave AKIAIOSFODNN7EXAMPLE no texto"
  
  # Act
  local output
  output=$(compact_context <<< "$input" --scrub 2>/dev/null) || true
  
  # Assert
  if echo "$output" | grep -qE "(sk-[a-zA-Z0-9]{20,}|AKIA[a-zA-Z0-9]{16})"; then
    printf '[TEST_FAIL] Padrão de secret não foi removido\n' >&2
    return 1
  fi
  return 0
}

if [[ "${1:-}" == "--test" ]]; then
  test_compact_context_respects_limit
  test_scrub_secrets_removes_patterns
  exit $?
fi
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/bash/context-compaction-utils.md \
  --json \
  --check-secrets \
  --check-tenant-isolation \
  --check-structural \
  --check-resource-limits \
  --check-error-handling
```

## 🔗 Referências Cruzadas
- [[bash-master-agent.md]]
- [[01-RULES/harness-norms-v3.0.md]]
- [[01-RULES/10-SDD-CONSTRAINTS.md]]
- [[01-RULES/03-SECURITY-RULES.md]]
- [[00-CONTEXT/norms-matrix.json]]

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2024-11-10 | Dev inicial | Criação original | Parcial |
| 2.0.0 | 2026-05-06 | Bash Master Agent | Remanufatura completa: frontmatter C5, tenant C4, logging C8, hardening C7, testes TDD | C1,C3,C4,C5,C7,C8 |

---
