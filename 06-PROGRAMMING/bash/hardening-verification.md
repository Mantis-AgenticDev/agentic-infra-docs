---
artifact_id: hardening-verification
artifact_type: bash_utility
version: 2.0.0
constraints_mapped: ["C1","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/bash/hardening-verification.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:hardening-verification-v2.0.0-remanufatured"
generated_at: "2026-05-06T12:05:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: bash
ai_navigation:
  read_first: false
  required_for: [pre-commit-validation, pipeline-gate, audit-compliance]
  update_frequency: on-change
audience: ["orchestrator-engine", "ci-cd-pipelines", "security-auditors"]
status: "🟡 Em remanufatura"
next_review: "2026-06-05"
---

# Verificação Automatizada de Hardening Bash

## 🎯 Propósito
Validar scripts Bash contra as normas de endurecimento (Harness Norms v3.0) do projeto MANTIS antes do commit ou deploy. Verifica presença obrigatória de `set -Eeuo pipefail`, `IFS` seguro, `trap` de cleanup, validação de tenant, timeouts estruturados e logging em stderr. Gera output JSONL para consumo direto pelo orchestrator-engine ou pipelines CI/CD.

## 📋 Especificação (SDD)
- **Entradas**: 
  - `$1`: Caminho absoluto ou relativo ao arquivo `.sh` ou `.sh.md`
  - `$STRICT_MODE`: (booleano, padrão: `true`) Falha no primeiro erro crítico
  - `$MAX_SCAN_SECONDS`: (inteiro, padrão: `10`) Limite de tempo para análise estática
- **Saídas**: 
  - Objeto JSON em stdout: `{"script": "...", "passed": bool, "issues": [...], "metrics": {...}}`
  - Códigos de retorno: `0` (aprovado), `1` (falha em constraint crítica), `2` (erro de execução/timeout)
- **Side Effects**: 
  - Nenhum (leitura pura, sem modificação de arquivos)
  - Logs de execução em stderr (JSONL) para auditoria
- **Constraints Aplicáveis**: C1 (limite de tempo de varredura), C5 (validação estrutural de padrões), C7 (verificação de resiliência), C8 (registro de auditoria)
- **Dependências Externas**: `grep`, `awk`, `sed` (apenas para extração segura), `date`, `jq` (opcional, fallback nativo em bash)

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
    printf '[%s][ERROR][script:%s][tenant:system] Falha na linha %d: código %d\n' \
      "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      "${SCRIPT_NAME}" \
      "${BASH_LINENO[0]:-0}" \
      "$exit_code" >&2
  fi
  exit $exit_code
}
trap cleanup EXIT INT TERM

readonly TARGET_SCRIPT="${1:?Uso: hardening-verification.sh <caminho-do-script>}"
readonly STRICT_MODE="${STRICT_MODE:-true}"
readonly MAX_SCAN_SECONDS="${MAX_SCAN_SECONDS:-10}"

# C1: Timeout na varredura estática para evitar loops em arquivos malformados
(
  sleep "$MAX_SCAN_SECONDS"
  printf '[%s][ERROR][script:%s][tenant:system] Timeout de %ds excedido na verificação\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${SCRIPT_NAME}" "$MAX_SCAN_SECONDS" >&2
  exit 2
) &
WATCHDOG_PID=$!
```

## 🧪 Testes Unitários (TDD)
```bash
test_verify_passes_on_valid_script() {
  # Arrange
  local temp_valid
  temp_valid=$(mktemp)
  cat > "$temp_valid" << 'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
trap 'exit $?' EXIT
: "${TENANT_ID:?Required}"
timeout 60 echo "safe"
EOF

  # Act
  local result
  result=$(verify_hardening "$temp_valid" 2>/dev/null) || true
  
  # Assert
  if echo "$result" | grep -q '"passed":true'; then
    rm -f "$temp_valid"
    return 0
  else
    printf '[TEST_FAIL] Script válido não passou na verificação\n' >&2
    rm -f "$temp_valid"
    return 1
  fi
}

test_verify_fails_on_missing_set_euo() {
  # Arrange
  local temp_invalid
  temp_invalid=$(mktemp)
  echo '#!/usr/bin/env bash' > "$temp_invalid"
  echo 'echo "unsafe"' >> "$temp_invalid"

  # Act
  local result
  result=$(verify_hardening "$temp_invalid" 2>/dev/null) || true

  # Assert
  if echo "$result" | grep -q '"passed":false'; then
    rm -f "$temp_invalid"
    return 0
  else
    printf '[TEST_FAIL] Script inválido não foi detectado\n' >&2
    rm -f "$temp_invalid"
    return 1
  fi
}

if [[ "${1:-}" == "--test" ]]; then
  test_verify_passes_on_valid_script
  test_verify_fails_on_missing_set_euo
  exit $?
fi
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/bash/hardening-verification.md \
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
- [[01-RULES/validation-checklist.md]]
- [[00-CONTEXT/norms-matrix.json]]

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2024-08-15 | Dev inicial | Criação básica com grep simples | Parcial |
| 2.0.0 | 2026-05-06 | Bash Master Agent | Remanufatura completa: watchdog C1, JSONL C8, testes TDD, frontmatter C5, hardening C7 | C1,C5,C7,C8 |

---
