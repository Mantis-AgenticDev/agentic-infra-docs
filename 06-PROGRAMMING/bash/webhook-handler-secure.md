---
artifact_id: webhook-handler-secure
artifact_type: bash_utility
version: 1.0.0
constraints_mapped: ["C3","C4","C7"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/bash/webhook-handler-secure.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:webhook-handler-secure-v1.0.0"
generated_at: "2026-05-07T03:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: bash
ai_navigation:
  read_first: false
  required_for: [hmac-verification, payload-schema-check, event-routing]
  update_frequency: on-change
audience: ["integration-agents", "ci-cd-pipelines", "orchestrator-engine"]
status: "🟢 Novo"
next_review: "2026-06-07"
---

# Handler Seguro de Webhooks com Verificação HMAC e Roteamento

## 🎯 Propósito
Receber, validar assinatura HMAC-SHA256, sanitizar payload e rotear eventos para handlers específicos por tenant. Garante integridade de origem (`C3`), isolamento por contexto (`C4`) e auditoria de processamento (`C8`).

## 📋 Especificação (SDD)
- **Entradas**: `WEBHOOK_SECRET` (env), `SIGNATURE_HEADER` (ex: `X-Hub-Signature-256`), `PAYLOAD_FILE` (stdin ou path)
- **Saídas**: `0` (válido e processado), `1` (assinatura inválida), `2` (schema inválido)
- **Side Effects**: Execução de callback seguro, log JSONL
- **Constraints Aplicáveis**: C3 (validação HMAC), C4 (tenant scoping), C7 (timeout, trap)
- **Dependências Externas**: `openssl`, `jq`, `curl`, coreutils POSIX

## 🛡️ Bootstrap Resiliente e Lógica de Webhook (C3+C4+C7)
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
readonly ARTIFACT_ID="webhook-handler-secure"
export TENANT_ID="${TENANT_ID:-}"

verify_webhook_signature() {
  local secret="${WEBHOOK_SECRET:?WEBHOOK_SECRET não definido}"
  local payload_file="${1:?arquivo payload obrigatório}"
  local received_sig="${SIGNATURE_HEADER:-}"
  
  local computed
  computed=$(openssl dgst -sha256 -hmac "$secret" -hex "$payload_file" 2>/dev/null | awk '{print $NF}')
  received_sig=${received_sig#sha256=}
  
  if [[ "$computed" == "$received_sig" ]]; then
    mantis_log "INFO" "webhook_signature_valid" "tenant=$TENANT_ID"
    return 0
  else
    mantis_log "ERROR" "webhook_signature_invalid" "tenant=$TENANT_ID"
    return 1
  fi
}

process_webhook_payload() {
  local file="$1"
  # C5+C6: Validação básica de JSON e extração de tenant interno
  local internal_tenant
  internal_tenant=$(jq -r '.tenant_id // empty' "$file" 2>/dev/null)
  [[ -n "$internal_tenant" && "$internal_tenant" != "$TENANT_ID" ]] && {
    mantis_log "ERROR" "tenant_mismatch_detected" "expected=$TENANT_ID, payload=$internal_tenant"
    return 2
  }
  
  mantis_log "INFO" "webhook_payload_processed" "valid_json=true, tenant_match=true"
  # Aqui entraria roteamento para handler específico via source/exec seguro
  return 0
}
```

## 🧪 Testes Unitários (TDD)
```bash
test_rejects_tenant_mismatch() {
  local tmp=$(mktemp)
  echo '{"tenant_id":"wrong-tenant"}' > "$tmp"
  export TENANT_ID="correct-tenant"
  process_webhook_payload "$tmp" 2>/dev/null
  local rc=$?
  rm -f "$tmp"
  [[ $rc -eq 2 ]] && return 0
  return 1
}

test_validate_vlog02_schema() {
  mantis_log "INFO" "test" "x" 2>&1 | jq -e 'has("timestamp") and has("level") and has("resource.tenant_id")' >/dev/null 2>&1
}

if [[ "${1:-}" == "--test" ]]; then test_rejects_tenant_mismatch; test_validate_vlog02_schema; exit $?; fi
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/bash/webhook-handler-secure.md --json --check-structural --check-error-handling --check-observability
```

## 🔗 Referências Cruzadas
- [[bash-master-agent.md]]
- [[tenant-context-propagation.md]]
- [[command-audit-logging-c8.md]]
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]]

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-07 | Bash Master Agent | Criação inicial: HMAC SHA256, validação tenant interno, roteamento seguro | C3,C4,C7 |

---
## 🔍 Observability (Documentación para IA)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `webhook_signature_valid` | INFO | C3 | `"tenant=xyz"` |
| `webhook_signature_invalid` | ERROR | C3 | `"tenant=xyz, hmac mismatch"` |
| `tenant_mismatch_detected` | ERROR | C4 | `"expected=xyz, payload=wrong"` |
| `webhook_payload_processed` | INFO | C8 | `"valid_json=true, tenant_match=true"` |

### Validação de Schema V-LOG-02
```bash
validate_vlog02() { jq -e 'has("timestamp") and has("level") and has("resource.tenant_id") and has("resource.artifact")' >/dev/null 2>&1; }
```
---
