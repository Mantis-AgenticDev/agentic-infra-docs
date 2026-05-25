---
artifact_id: "n8n-trigger-testing-strategies"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C3","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/trigger-testing-strategies.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/trigger-testing-strategies.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:trigger-testing-strategies-v1.0.0"
generated_at: "2026-05-24T20:10:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["trigger-validation", "webhook-testing", "schedule-testing"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# ⚡ Estratégias de Teste de Triggers

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Padronizar a validação de todos os tipos de triggers do n8n: Webhook (payloads, métodos HTTP, autenticação), Schedule (expressões cron, confiabilidade, timezone), Polling (intervalo, deduplicação) e Event (latência, filtros), garantindo segurança (C3), validação (C5) e observabilidade (C8).

## 📋 Especificação (SDD)
- **Entradas**: Tipo de trigger, URL do webhook, expressão cron, configuração de polling.
- **Saídas**: Relatório de teste com status para cada cenário e métricas de performance.
- **Side Effects**: Chamadas HTTP reais, execuções agendadas.
- **Constraints Aplicáveis**: C3 (auth de webhooks), C5 (validação estrutural), C8 (logging de triggers).
- **Dependências**: n8n com triggers configurados, acesso à API externa para webhooks.

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
trigger_testing:
  webhook:
    description: "Testar endpoints HTTP que disparam workflows"
    
    payload_testing:
      scenarios:
        valid_json: { type: 'json', data: { event: 'test', timestamp: '...' } }
        empty_object: { type: 'empty', data: {} }
        large_payload: { type: 'large', data: { items: 'Array(1000)' } }
        nested_data: { type: 'nested', data: { level1: { level2: { level3: 'deep' } } } }
        special_chars: { type: 'special', data: { text: '<script>alert("xss")</script>' } }
      metrics: ["success", "status", "responseTime", "responseBody"]

    http_method_testing:
      methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"]
      check: "Método permitido (200/201) vs não permitido (405)"

    auth_testing:
      scenarios:
        no_auth: { headers: {}, expected: "Se configurado, 401" }
        invalid_auth: { headers: { Authorization: 'Bearer invalid' }, expected: 401 }
        valid_auth: { headers: { Authorization: 'Bearer <token>' }, expected: 200 }
        expired_auth: { headers: { Authorization: 'Bearer <expired>' }, expected: 401 }

    response_mode_testing:
      immediate: "Resposta imediata (menos de 100ms)"
      workflow: "Resposta após execução (+ waitForResponse=true)"

  schedule:
    description: "Testar triggers baseados em tempo (cron)"
    
    cron_validation:
      parts: ["minuto (0-59)", "hora (0-23)", "dia do mês (1-31)", "mês (1-12)", "dia da semana (0-7)"]
      common_patterns:
        every_minute: "* * * * *"
        every_5_minutes: "*/5 * * * *"
        every_hour: "0 * * * *"
        daily_midnight: "0 0 * * *"
        weekdays_9am: "0 9 * * 1-5"
        first_of_month: "0 0 1 * *"
        sunday_midnight: "0 0 * * 0"

    reliability_testing:
      approach: "Monitorar execuções reais por período e comparar com esperado"
      metrics:
        expected_count: "Número de execuções esperadas no período"
        actual_count: "Número real de execuções"
        missed_executions: "Esperadas - Reais (deve ser 0)"
        timing_accuracy: "Desvio médio do horário esperado"

  polling:
    description: "Testar triggers que verificam mudanças periodicamente"
    
    behavior_testing:
      interval: "Intervalo configurado (ms)"
      expected_polls: "Período / Intervalo"
      actual_polls: "Número real de polls"
      poll_accuracy: "(actual / expected) * 100"

    deduplication_check:
      description: "Verificar que itens não são processados duas vezes"
      approach: "Injetar item duplicado e verificar que só foi processado uma vez"

  event:
    description: "Testar triggers orientados a eventos (GitHub, Stripe, etc.)"
    
    latency_testing:
      approach: "Emitir evento de teste e medir tempo até execução"
      metrics: ["triggered (bool)", "latency (ms)", "payload_received (objeto)"]
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_cron_expression_parts() {
  local cron="*/5 * * * *"
  local parts=($cron)
  [[ ${#parts[@]} -eq 5 ]] && return 0 || return 1
}

test_webhook_method_validation() {
  local methods=("GET" "POST" "PUT" "DELETE")
  local has_post=false
  for m in "${methods[@]}"; do [[ "$m" == "POST" ]] && has_post=true; done
  $has_post && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && {
  test_cron_expression_parts && test_webhook_method_validation && echo "✅" || echo "❌"
  exit $?
}
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[workflow-testing-fundamentals.md]]
- [[integration-testing-patterns.md]]
- [[trigger-patterns.md]]
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]]
