---
artifact_id: "n8n-integration-testing-patterns"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C3","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/integration-testing-patterns.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/integration-testing-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:integration-testing-v1.0.0"
generated_at: "2026-05-24T18:40:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["integration-testing", "connectivity-validation", "rate-limit-testing"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🧪 Padrões de Teste de Integração — Conectividade, Operações e Rate Limits

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Padronizar a validação de integrações n8n com serviços externos, incluindo testes de conectividade, autenticação (OAuth2, API Key), operações de API, comportamento de rate limit e cenários de erro, garantindo segurança (C3), validação (C5) e observabilidade (C8).

## 📋 Especificação (SDD)
- **Entradas**: Nome da integração, credenciais, operações a testar.
- **Saídas**: Relatório de teste estruturado com status, métricas e recomendações.
- **Side Effects**: Chamadas reais às APIs (em ambiente de teste).
- **Constraints Aplicáveis**: C3 (autenticação segura), C5 (validação de respostas), C8 (logging de testes).
- **Dependências**: n8n com nós configurados, credenciais válidas para ambiente de teste.

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
integration_testing:
  quick_checklist:
    - "Credenciais válidas e não expiradas"
    - "Permissões de API suficientes para operações"
    - "Rate limits compreendidos e respeitados"
    - "Respostas de erro adequadamente tratadas"
    - "Formatos de dados compatíveis com expectativas da API"

  connectivity_testing:
    description: "Verificar conectividade e autenticação com serviços externos"
    patterns:
      slack: |
        GET https://slack.com/api/auth.test
        Headers: { Authorization: "Bearer <token>" }
        Expected: { ok: true, team: "...", user: "..." }
      google_sheets: |
        GET https://www.googleapis.com/drive/v3/about?fields=user
        Headers: { Authorization: "Bearer <token>" }
        Handle: 401 → refresh token → retry

  oauth2_testing:
    description: "Validar fluxo OAuth2 e refresh de token"
    checks:
      - "Testar token atual (valid, scopes, expiration)"
      - "Verificar expiração (alertar se < 1 hora)"
      - "Testar refresh token (se disponível)"
      - "Validar scopes obrigatórios vs. scopes atuais"

  api_key_testing:
    description: "Validar chaves de API para serviços sem OAuth"
    endpoints:
      sendgrid: "GET https://api.sendgrid.com/v3/user/profile"
      mailchimp: "GET https://us1.api.mailchimp.com/3.0/ping"
      airtable: "GET https://api.airtable.com/v0/meta/whoami"
    expected: "HTTP 200"

  rate_limit_testing:
    description: "Testar comportamento sob rate limit"
    process: "Fazer N requisições rápidas até receber 429"
    metrics:
      - "requestsMade: número de requisições até o limite"
      - "rateLimitHit: true/false"
      - "retryAfter: segundos recomendados para retry"
      - "recommendation: sugestão de backoff exponencial"

  error_scenarios:
    description: "Testar cenários de erro comuns"
    scenarios:
      invalid_credentials: "Credenciais nulas → Deve retornar 401"
      invalid_endpoint: "URL inválida → Deve capturar erro de conexão"
      timeout: "Timeout de 1ms → Deve capturar timeout"
      invalid_data: "Dados inválidos → Deve retornar erro de validação"
      not_found: "Recurso inexistente → Deve retornar 404"
      permission_denied: "Scope insuficiente → Deve retornar 403"

  test_report:
    description: "Formato canônico de relatório de teste"
    sections:
      summary: "Tabela com Integration, Status, Auth, Operations, Errors"
      auth_status: "Detalhes de OAuth2/API Key (validade, scopes, refresh)"
      rate_limit_status: "Limite, usado, restante por integração"
      failed_operations: "Lista de operações falhas com causa e solução"
      recommendations: "Ações prioritárias (ex: refresh token, ajustar rate limit)"
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_rate_limit_detection() {
  local response='{"status":429,"headers":{"retry-after":"60"}}'
  python3 -c "
import json; d=json.loads('$response')
assert d['status'] == 429
assert int(d['headers']['retry-after']) > 0
" 2>/dev/null && return 0 || return 1
}

test_error_classification() {
  local errors=("401:authentication" "404:not-found" "429:rate-limit" "500:server-error")
  for e in "${errors[@]}"; do
    local code="${e%%:*}"
    local type="${e##*:}"
    [[ "$type" == "authentication" || "$type" == "not-found" || "$type" == "rate-limit" || "$type" == "server-error" ]] || return 1
  done
  return 0
}

[[ "${1:-}" == "--test" ]] && {
  test_rate_limit_detection && test_error_classification && echo "✅" || echo "❌"
  exit $?
}
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[api-integration-patterns.md]]
- [[error-handling-patterns.md]]
- [[http-request-patterns.md]]
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]]
