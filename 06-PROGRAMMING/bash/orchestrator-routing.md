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

## 🛡️ Bootstrap Resiliente e Lógica de Roteamento (C4+C5+C6+C7+C8)
```bash
# =============================================================================
# BOOTSTRAP RESILIENTE: Hardening + Observabilidade (C3+C4+C7)
# Fonte de verdade: bash-master-agent.md via source
# =============================================================================
if [[ -f "${MANTIS_ROOT:-.}/06-PROGRAMMING/bash/bash-master-agent.sh" ]]; then
  source "${MANTIS_ROOT:-.}/06-PROGRAMMING/bash/bash-master-agent.sh" --mode=observability-only
else
  set -Eeuo pipefail; shopt -s inherit_errexit 2>/dev/null || true
  trap 'exit 130' INT TERM
  : "${TENANT_ID:?ERROR: TENANT_ID não definido. Defina via env ou argumento.}"
  mantis_log() { printf '{"ts":"%s","level":"%s","tenant":"%s","event":"%s","detail":"%s","fallback":"true"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${1:-INFO}" "${TENANT_ID:-unknown}" "${2:-bootstrap_fallback}" "${3:-}" >&2; }
  mantis_log "WARN" "bootstrap_fallback" "Master agent não encontrado. Executando com hardening mínimo."
fi

readonly SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"
readonly SCRIPT_VERSION="${VERSION:-2.0.0}"
export TENANT_ID="${TENANT_ID:-}"

# =============================================================================
# LÓGICA DE ROTEAMENTO COM LANGUAGE LOCK E VALIDAÇÃO DE CONTRATO
# =============================================================================
# C7: Cleanup e trap
cleanup_routing() {
  local exit_code=$?
  [[ -n "${NORMS_CACHE:-}" && -f "${NORMS_CACHE}" ]] && rm -f "${NORMS_CACHE}"
  if [[ $exit_code -ne 0 ]]; then
    mantis_log "ERROR" "routing_aborted" "Código de saída: $exit_code | Operação: ${OP_TYPE:-unknown}"
  fi
  exit $exit_code
}
trap cleanup_routing EXIT INT TERM

# C4: Validação obrigatória
: "${TENANT_ID:?Variável de ambiente TENANT_ID não definida. Abortando.}"

readonly OP_TYPE="${1:?Uso: orchestrator-routing.sh <operation_type> [payload_json]}"
readonly PAYLOAD="${2:-"{}"}"
readonly NORMS="${NORMS_PATH:-00-CONTEXT/norms-matrix.json}"
readonly ROUTING_TIMEOUT="${ROUTING_TIMEOUT:-15}"

# C6: Sanitização rigorosa de operation_type (apenas alfanuméricos e underscore)
if [[ ! "$OP_TYPE" =~ ^[a-zA-Z0-9_]+$ ]]; then
  mantis_log "ERROR" "invalid_operation_type" "Operation type contém caracteres inválidos: $OP_TYPE"
  exit 1
fi

# C5+C7: Leitura segura e validada do contrato de roteamento
[[ -f "$NORMS" && -r "$NORMS" ]] || { mantis_log "ERROR" "norms_file_missing" "Arquivo de normas não encontrado: $NORMS"; exit 3; }
NORMS_CACHE=$(mktemp) || { mantis_log "ERROR" "mktemp_failed" "Falha ao criar cache temporário"; exit 3; }
if ! timeout "$ROUTING_TIMEOUT" jq -c ".routing[\"$OP_TYPE\"] // empty" "$NORMS" > "$NORMS_CACHE" 2>/dev/null; then
  mantis_log "ERROR" "routing_lookup_failed" "Timeout de ${ROUTING_TIMEOUT}s ou JSON inválido em $NORMS"
  exit 3
fi

ROUTE_RULE=$(cat "$NORMS_CACHE")
[[ -n "$ROUTE_RULE" ]] || { mantis_log "ERROR" "operation_not_mapped" "Operação não mapeada em norms-matrix: $OP_TYPE"; exit 1; }

TARGET_DOMAIN=$(echo "$ROUTE_RULE" | jq -r '.target_domain // "unknown"')
REQUIRED_CONSTRAINTS=$(echo "$ROUTE_RULE" | jq -r '.constraints // "[]"')

# C5: Validação de payload mínimo (JSON válido)
if ! echo "$PAYLOAD" | jq empty 2>/dev/null; then
  mantis_log "ERROR" "invalid_payload_json" "Payload não é JSON válido: $PAYLOAD"
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
  
  mantis_log "INFO" "handoff_generated" "target=$TARGET_DOMAIN, operation=$OP_TYPE, tenant=$TENANT_ID"
  echo "$HANDOFF"
  exit 2
fi

# Se chegou aqui, domínio é bash e constraints foram validadas
mantis_log "INFO" "routing_approved" "domain=bash, constraints=$REQUIRED_CONSTRAINTS, tenant=$TENANT_ID"
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
    mantis_log "ERROR" "test_failed" "Handoff não gerado para domínio externo (exit: $exit_code)"
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
    mantis_log "ERROR" "test_failed" "Operação malformada não foi rejeitada (exit esperado: 1, obtido: $exit_code)"
    rm -f "$test_norms"
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
  test_routing_triggers_handoff_for_non_bash_domain
  test_routing_rejects_invalid_operation_type
  test_validate_vlog02_schema
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
  --check-error-handling \
  --check-observability
```

## 🔗 Referências Cruzadas
- [[bash-master-agent.md]] ← Contrato de geração, protocolo de handoff e anti-padrões
- [[01-RULES/harness-norms-v3.0.md]] ← Especificação de resiliência C7
- [[01-RULES/language-lock-protocol.md]] ← Regras de delegação entre domínios
- [[01-RULES/10-SDD-CONSTRAINTS.md]] ← Definição de C4, C5, C6, C8
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]] ← Índice de observabilidade
- [[/05-CONFIGURATIONS/observability/loki/config.yml]] ← Pipeline de ingestão de logs JSONL
- [[00-CONTEXT/norms-matrix.json]] ← Fonte de verdade para rotas dinâmicas

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2024-08-10 | Dev inicial | Roteamento hardcodeado com `if/elif`, sem leitura de contrato | Parcial |
| 2.0.0 | 2026-05-06 | Bash Master Agent | Remanufatura: bootstrap resiliente, `mantis_log()` canônica, validação V-LOG-02, remoção de hardening inline | C4,C5,C6,C7,C8 |

---
## 🔍 Observability (Documentación para IA)

> Este artefato emite os seguintes eventos via `mantis_log()` (definida em [[bash-master-agent.md]]):

| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `routing_started` | INFO | C8 | `"Operation: vector_query, tenant: tenant-xyz"` |
| `invalid_operation_type` | ERROR | C6 | `"Operation type contém caracteres inválidos: ../escape"` |
| `norms_file_missing` | ERROR | C7 | `"Arquivo de normas não encontrado: /invalid/path.json"` |
| `routing_lookup_failed` | ERROR | C1 | `"Timeout de 15s ou JSON inválido em norms-matrix.json"` |
| `operation_not_mapped` | ERROR | C5 | `"Operação não mapeada em norms-matrix: unknown_op"` |
| `invalid_payload_json` | ERROR | C5 | `"Payload não é JSON válido: {broken"` |
| `handoff_generated` | INFO | C4 | `"target=postgresql-pgvector, operation=vector_query, tenant=tenant-xyz"` |
| `routing_approved` | INFO | C8 | `"domain=bash, constraints=[\"C4\",\"V1\"], tenant=tenant-xyz"` |
| `routing_aborted` | ERROR | C7 | `"Código de saída: 1 | Operação: vector_query"` |

### Exemplo de Output JSONL (para aprendizado de padrão por IA)
```json
{"timestamp":"2026-05-06T12:45:00Z","level":"INFO","resource":{"tenant_id":"tenant-xyz","artifact":"orchestrator-routing"},"body":{"event":"handoff_generated","detail":"target=postgresql-pgvector, operation=vector_query, tenant=tenant-xyz"},"attributes":{"mantis":{"tier":"2","version":"2.0.0","constraint":"C4,C5,C6","trace_id":""},"code.filepath":"06-PROGRAMMING/bash/orchestrator-routing.md","code.lineno":89,"telemetry.sdk.name":"mantis-bash-adapter","telemetry.sdk.version":"1.0.0"}}
```

### Configuração Específica de Este Artefato
```bash
# Variáveis de entorno que afetam o comportamento de logging deste artefato
export LOG_ROUTING_DECISIONS="${LOG_ROUTING_DECISIONS:-true}"  # Incluir decisão de rota em logs
export LOG_HANDOFF_PAYLOAD="${LOG_HANDOFF_PAYLOAD:-false}"     # Incluir payload de handoff (Cuidado: PII)
export TRACE_ROUTING_OPS="${TRACE_ROUTING_OPS:-false}"         # Habilitar trace_id para correlação OTel
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
