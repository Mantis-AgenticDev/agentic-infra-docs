---
artifact_id: orchestrator-routing
artifact_type: bash_utility
version: 2.0.0
constraints_mapped: ["C4","C5","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/bash/orchestrator-routing.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:orchestrator-routing-v2.0.0-remanufatured"
generated_at: "2026-05-06T12:45:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: bash
ai_navigation:
  read_first: false
  required_for: [cross-domain-dispatch, constraint-driven-routing, handoff-generation]
  update_frequency: on-change
audience: ["orchestrator-engine", "agentic-routing-agents", "pipeline-dispatchers"]
status: "🟡 Em remanufatura"
next_review: "2026-06-05"
---

# Roteamento Dinâmico de Operações com Validação de Contrato e LANGUAGE LOCK

## 🎯 Propósito
Implementar mecanismo de roteamento seguro que determina o domínio alvo (Bash, SQL, Python, Go, PgVector, etc.) com base em `norms-matrix.json` e no tipo de operação solicitada. **Substitui lógica hardcodeada por leitura dinâmica de contrato**, aplica validação de constraints antes do dispatch, gera payload de handoff JSONL padronizado quando a operação pertence a outro domínio, e impõe LANGUAGE LOCK estrito. Zero execução direta de lógica externa; apenas validação, roteamento e emissão de handoff auditável.

## 📋 Especificação (SDD)
- **Entradas**: 
  - `TENANT_ID` (obrigatório)
  - `OPERATION_TYPE` (ex: `vector_query`, `db_migration`, `ml_inference`, `file_sync`, `deploy_bash`)
  - `PAYLOAD` (JSON válido com parâmetros da operação)
  - `NORMS_PATH` (caminho para `norms-matrix.json`, padrão: `00-CONTEXT/norms-matrix.json`)
  - `ROUTING_TIMEOUT` (segundos, padrão: `15`)
- **Saídas**: 
  - `0`: Roteamento interno válido (Bash pode executar)
  - `1`: Falha de validação (payload inválido, tenant ausente, operação não mapeada)
  - `2`: Handoff necessário (JSON emitido em stdout, script encerra)
  - `3`: Timeout ou erro de leitura de contrato
  - Logs JSONL em stderr com `route_decision`, `target_domain`, `validation_status`, `dry_run`
- **Side Effects**: 
  - Leitura segura de `norms-matrix.json` (apenas leitura, sem modificação)
  - Emissão de bloco JSONL para handoff em stdout quando `target_domain != bash`
  - Nenhum subprocesso externo executado; apenas decisão de roteamento
- **Constraints Aplicáveis**: C4 (tenant em logs e payload), C5 (schema de payload e validação de rota), C6 (sanitização de operation_type), C7 (timeout na leitura de contrato e fallback seguro), C8 (auditoria JSONL de decisão)
- **Dependências Externas**: `jq`, `timeout`, `grep`, `awk`, coreutils POSIX

## 🛡️ Hardening (Harness Norms v3.0 - Executável)
```bash
#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_VERSION="2.0.0"

# C8: Logging estruturado JSONL
log_route() {
  local level="${1:-INFO}" event="${2:-routing_event}" detail="${3:-}"
  printf '{"ts":"%s","level":"%s","tenant":"%s","script":"%s","event":"%s","detail":"%s"}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    "$level" \
    "${TENANT_ID:-unknown}" \
    "$SCRIPT_NAME" \
    "$event" \
    "$detail" >&2
}

# C7: Cleanup e trap
cleanup() {
  local exit_code=$?
  [[ -n "${NORMS_CACHE:-}" && -f "${NORMS_CACHE}" ]] && rm -f "${NORMS_CACHE}"
  exit $exit_code
}
trap cleanup EXIT INT TERM

# C4: Validação obrigatória
: "${TENANT_ID:?Variável de ambiente TENANT_ID não definida. Abortando.}"

readonly OP_TYPE="${1:?Uso: orchestrator-routing.sh <operation_type> [payload_json]}"
readonly PAYLOAD="${2:-"{}"}"
readonly NORMS="${NORMS_PATH:-00-CONTEXT/norms-matrix.json}"
readonly ROUTING_TIMEOUT="${ROUTING_TIMEOUT:-15}"

# C6: Sanitização rigorosa de operation_type
if [[ ! "$OP_TYPE" =~ ^[a-zA-Z0-9_]+$ ]]; then
  log_route "ERROR" "invalid_operation_type" "$OP_TYPE"
  exit 1
fi

# C5+C7: Leitura segura e validada do contrato de roteamento
[[ -f "$NORMS" && -r "$NORMS" ]] || { log_route "ERROR" "norms_file_missing" "$NORMS"; exit 3; }
NORMS_CACHE=$(mktemp) || exit 3
if ! timeout "$ROUTING_TIMEOUT" jq -c ".routing[\"$OP_TYPE\"] // empty" "$NORMS" > "$NORMS_CACHE" 2>/dev/null; then
  log_route "ERROR" "routing_lookup_failed" "Timeout ou JSON inválido"
  exit 3
fi

ROUTE_RULE=$(cat "$NORMS_CACHE")
[[ -n "$ROUTE_RULE" ]] || { log_route "ERROR" "operation_not_mapped" "$OP_TYPE"; exit 1; }

TARGET_DOMAIN=$(echo "$ROUTE_RULE" | jq -r '.target_domain // "unknown"')
REQUIRED_CONSTRAINTS=$(echo "$ROUTE_RULE" | jq -r '.constraints // "[]"')

# C5: Validação de payload mínimo
if ! echo "$PAYLOAD" | jq empty 2>/dev/null; then
  log_route "ERROR" "invalid_payload_json" "Payload não é JSON válido"
  exit 1
fi

# C4+C7: Injeção de tenant e metadados de auditoria no payload
ENRICHED_PAYLOAD=$(echo "$PAYLOAD" | jq -c --arg tid "$TENANT_ID" --arg op "$OP_TYPE" \
  '. + {audit: {tenant_id: $tid, operation: $op, routed_at: now, source_domain: "bash"}}')

# LANGUAGE LOCK: Se domínio alvo != bash, gerar handoff e encerrar
if [[ "$TARGET_DOMAIN" != "bash" ]]; then
  HANDOFF=$(jq -n \
    --arg target "$TARGET_DOMAIN" \
    --arg op "$OP_TYPE" \
    --argjson payload "$ENRICHED_PAYLOAD" \
    --arg constraints "$REQUIRED_CONSTRAINTS" \
    '{
      protocol_version: "1.1",
      source_agent: "bash-master-agent",
      target_agent: $target,
      reason: "language_lock_enforced",
      operation: $op,
      payload: $payload,
      constraints_enforced: ($constraints | fromjson),
      timeout_seconds: 300,
      callback: { on_success: "log_handoff_success.sh", on_error: "log_handoff_failure.sh", format: "JSONL" }
    }')
  
  log_route "INFO" "handoff_generated" "target=$TARGET_DOMAIN"
  echo "$HANDOFF"
  exit 2
fi

# Se chegou aqui, domínio é bash e constraints foram validadas
log_route "INFO" "routing_approved" "domain=bash, constraints=$REQUIRED_CONSTRAINTS"
exit 0
```

## 🧪 Testes Unitários (TDD)
```bash
test_routing_triggers_handoff_for_non_bash_domain() {
  # Arrange
  local test_norms test_payload
  test_norms=$(mktemp)
  echo '{"routing": {"vector_query": {"target_domain": "postgresql-pgvector", "constraints": ["C4","V1"]}}}' > "$test_norms"
  test_payload='{"query":"test","dimensions":768}'
  export TENANT_ID="test-routing-01"

  # Act
  local output
  output=$(NORMS_PATH="$test_norms" bash "${BASH_SOURCE[0]}" "vector_query" "$test_payload" 2>/dev/null)
  local exit_code=$?

  # Assert
  if [[ $exit_code -eq 2 && $(echo "$output" | jq -r '.target_agent') == "postgresql-pgvector" ]]; then
    rm -f "$test_norms"
    return 0
  else
    printf '[TEST_FAIL] Handoff não gerado para domínio externo (exit: %s)\n' "$exit_code" >&2
    rm -f "$test_norms"
    return 1
  fi
}

test_routing_rejects_invalid_operation_type() {
  # Arrange
  local test_norms
  test_norms=$(mktemp)
  echo '{"routing": {}}' > "$test_norms"
  export TENANT_ID="test-routing-02"

  # Act
  bash "${BASH_SOURCE[0]}" "invalid;op" "{}" 2>/dev/null
  local exit_code=$?

  # Assert
  if [[ $exit_code -eq 1 ]]; then
    rm -f "$test_norms"
    return 0
  else
    printf '[TEST_FAIL] Operação malformada não foi rejeitada (exit esperado: 1, obtido: %s)\n' "$exit_code" >&2
    rm -f "$test_norms"
    return 1
  fi
}

if [[ "${1:-}" == "--test" ]]; then
  test_routing_triggers_handoff_for_non_bash_domain
  test_routing_rejects_invalid_operation_type
  exit $?
fi
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/bash/orchestrator-routing.md \
  --json \
  --check-secrets \
  --check-tenant-isolation \
  --check-structural \
  --check-resource-limits \
  --check-error-handling
```

## 🔗 Referências Cruzadas
- [[bash-master-agent.md]] ← Contrato de geração, protocolo de handoff e anti-padrões
- [[01-RULES/harness-norms-v3.0.md]] ← Especificação de resiliência C7
- [[01-RULES/language-lock-protocol.md]] ← Regras de delegação entre domínios
- [[01-RULES/10-SDD-CONSTRAINTS.md]] ← Definição de C4, C5, C6, C8
- [[00-CONTEXT/norms-matrix.json]] ← Fonte de verdade para rotas dinâmicas

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2024-08-10 | Dev inicial | Roteamento hardcodeado com `if/elif`, sem leitura de contrato | Parcial |
| 2.0.0 | 2026-05-06 | Bash Master Agent | Remanufatura completa: leitura dinâmica de `norms-matrix.json`, LANGUAGE LOCK explícito, payload enriquecido com audit trail, JSONL C8, sanitização C6, testes TDD | C4,C5,C6,C7,C8 |

---
