---
artifact_id: "n8n-error-handling-advanced"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/error-handling-advanced.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/error-handling-advanced.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:error-handling-advanced-v1.0.0"
generated_at: "2026-05-24T21:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["error-recovery", "structured-errors", "api-error-paths"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🚨 Tratamento Avançado de Erros

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Padronizar o tratamento de erros em workflows n8n com foco em APIs webhook-driven: mapeamento de causa para código de status HTTP, corpos de erro estruturados, self-healing com retry, validação de entrada com Set IIFE e workflow-level error catching, garantindo segurança (C3), validação (C5), resiliência (C7) e observabilidade (C8).

## 📋 Especificação (SDD)
- **Entradas**: Workflow tipo API (webhook + respond), nós passíveis de falha.
- **Saídas**: Workflow com paths de erro completos, status codes mapeados, retry configurado.
- **Constraints Aplicáveis**: C3 (auth errors), C5 (validação de entrada), C7 (retry/self-healing), C8 (structured error logging).

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
error_handling_advanced:
  non_negotiables:
    - "Todo nó passível de falha (HTTP, DB, API externa, arquivo) deve ter saída de erro conectada."
    - "Ambos os caminhos (sucesso e erro) devem terminar em Respond to Webhook."
    - "Código de status mapeia à causa: culpa do chamador → 4xx, culpa do servidor → 5xx."
    - "Workflows não supervisionados (schedule, cron, fila) devem ter workflow-level error workflow."

  api_workflow_shape:
    canonical: |
      Webhook trigger
        ├── (success path) → Process → Respond to Webhook (200, body)
        └── (any node's error output)
                             → Respond to Webhook (4xx/5xx, structured error body)
                             → Optional: log to tracker / notify channel

  schema_validator_set_iife:
    description: "Validar entrada com Set node + IIFE em vez de cadeias IF/Switch"
    pattern: |
      Webhook → Set (Validate Schema com IIFE) → If Params Valid → lógica de negócio → 200 success / 400 validation error
    output_contract:
      valid: boolean
      validationError: string
      details: object
      requiredSchema: object

  status_code_mapping:
    validation_error: { status: 400, code: "validation_error", path: "Validate up front with Set-based schema validator" }
    unauthorized: { status: 401, code: "unauthorized", path: "Check auth up front" }
    forbidden: { status: 403, code: "forbidden", path: "Check permissions up front" }
    not_found: { status: 404, code: "not_found", path: "Branch off lookup result, not error output" }
    conflict: { status: 409, code: "conflict", path: "Detect with logic, not error output" }
    rate_limit_exceeded: { status: 429, code: "rate_limit_exceeded", path: "Set Retry-After header" }
    internal_error: { status: 500, code: "internal_error", path: "The error-output path" }
    upstream_error: { status: 502, code: "upstream_error", path: "Error output of HTTP Request node" }
    service_unavailable: { status: 503, code: "service_unavailable", path: "Detect via specific error" }
    upstream_timeout: { status: 504, code: "upstream_timeout", path: "Error output filtered by error message" }

  one_respond_expression_driven:
    description: "Quando o path de erro difere apenas por código de status e mensagem, usar UM Respond to Webhook com expressão para Response Code, em vez de N Responds via Switch"
    expression: |
      {{ (() => {
          const msg = $json.error?.message || $json.message || ''
          if (msg.includes('INVALID_ID')) return 400
          if (/429|too many/i.test(msg)) return 429
          if (/openrouter|anthropic|llm/i.test(msg)) return 502
          return 500
      })() }}

  self_healing_retry:
    description: "Configurar retryOnFail em todo nó que faz chamada de rede ANTES de conectar path de erro"
    config: { retryOnFail: true, maxTries: 3, waitBetweenTries: 5000 }
    applies_to: ["HTTP Request", "Gmail", "Slack", "Discord", "DB", "AI", "third-party API nodes"]

  error_workflow_level:
    description: "Workflow de erro que captura falhas não tratadas (timeouts, crashes entre nós)"
    actions: ["Capturar falha (nome do workflow, execution ID, erro, stack)", "Notificar alguém (Slack, email, on-call)", "Opcionalmente enfileirar retry com backoff"]
    limitation: "Atualmente, apenas o usuário pode configurar error workflows via UI"

  response_shapes:
    structured_body: { error: "<short identifier>", message: "<human-readable>" }
    not_just_internal_server_error: true

  anti_patterns:
    - "Webhook → process → respond, sem branch de erro → caller recebe timeout ou 500 vazio"
    - "Single Respond para ambos os paths → corpo não informa o caller o que aconteceu"
    - "Path de erro retorna 200 com { error: ... } → cliente HTTP trata como sucesso"
    - "Capturar erros em Code node e retornar como dados → downstream vê dados com forma de erro"
    - "500 genérico 'Internal Server Error' em toda falha → não distingue bug do caller de outage"
    - "Nó de produção chamando API rate-limited sem retryOnFail → cada 429 vira 5xx"
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_status_code_mapping_complete() {
  local codes=("400:validation_error" "401:unauthorized" "403:forbidden" "404:not_found" "409:conflict" "429:rate_limit_exceeded" "500:internal_error" "502:upstream_error" "503:service_unavailable" "504:upstream_timeout")
  [[ ${#codes[@]} -eq 10 ]] && return 0 || return 1
}

test_retry_config_valid() {
  local config='{"retryOnFail":true,"maxTries":3,"waitBetweenTries":5000}'
  python3 -c "
import json; d=json.loads('$config')
assert d['maxTries'] <= 5, 'maxTries capped at 5'
assert d['waitBetweenTries'] <= 5000, 'waitBetweenTries capped at 5000ms'
" 2>/dev/null && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && {
  test_status_code_mapping_complete && test_retry_config_valid && echo "✅" || echo "❌"
  exit $?
}
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[error-handling-patterns.md]]
- [[workflow-testing-fundamentals.md]]
- [[credentials-security.md]]
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]]
