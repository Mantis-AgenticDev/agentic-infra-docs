---
artifact_id: "n8n-trigger-patterns"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C2","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/trigger-patterns.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/trigger-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:trigger-patterns-v1.0.0"
generated_at: "2026-05-24T17:10:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["workflow-triggers", "webhook-setup", "scheduled-automation"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# ⚡ Padrões de Triggers — Webhook, Schedule, App Trigger

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Padronizar a configuração de nós de trigger em workflows n8n, incluindo webhooks com autenticação, schedules com expressões cron e app triggers com polling, garantindo declaração (C2), validação (C5) e observabilidade (C8).

## 📋 Especificação (SDD)
- **Entradas**: Tipo de trigger (webhook, schedule, app), configurações específicas.
- **Saídas**: JSON de nó trigger válido.
- **Constraints Aplicáveis**: C2, C5, C8.

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
trigger_patterns:
  webhook:
    description: "Cria endpoint HTTP que dispara workflow"
    config:
      type: "n8n-nodes-base.webhook"
      parameters:
        httpMethod: "POST"
        path: "my-webhook"
        responseMode: "responseNode"
        options:
          rawBody: true  # Para verificação de assinatura
    authentication:
      none: "Sem autenticação (dev/test)"
      header_auth: "Header com API key"
      basic_auth: "Usuário e senha"
    access_url: "http://localhost:5678/webhook/{path}"
    test_url: "http://localhost:5678/webhook-test/{path}"

  schedule:
    description: "Disparador baseado em tempo (cron)"
    config:
      type: "n8n-nodes-base.scheduleTrigger"
      parameters:
        rule:
          interval:
            - field: "cronExpression"
              expression: "0 9 * * 1-5"
    common_schedules:
      every_hour: "0 * * * *"
      weekdays_9am: "0 9 * * 1-5"
      weekly_sunday: "0 0 * * 0"
      every_15_minutes: "*/15 * * * *"

  app_trigger:
    description: "Polling de eventos de aplicações externas"
    config:
      type: "n8n-nodes-base.githubTrigger"
      parameters:
        owner: "{{$env.GITHUB_OWNER}}"
        repository: "{{$env.GITHUB_REPO}}"
        events: ["issues", "pull_request"]
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_cron_expression_valid() {
  local cron="0 9 * * 1-5"
  python3 -c "
from croniter import croniter
from datetime import datetime
cron = croniter('$cron', datetime.now())
next(cron)
" 2>/dev/null && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && { test_cron_expression_valid && echo "✅" || echo "❌"; exit $?; }
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[workflow-structure-fundamentals.md]]
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]]
