---
artifact_id: "n8n-error-handling-patterns"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/error-handling-patterns.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/error-handling-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:error-handling-v1.0.0"
generated_at: "2026-05-24T17:40:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["error-recovery", "workflow-resilience", "alerting"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🛡️ Padrões de Tratamento de Erros — Error Trigger, Retry, Stop

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Padronizar o tratamento de erros em workflows n8n, incluindo captura com Error Trigger, re-tentativas com backoff, e parada controlada com StopAndError, garantindo resiliência (C7), validação (C5) e observabilidade (C8).

## 📋 Especificação (SDD)
- **Entradas**: Configuração de nós com risco de falha, estratégia de retry.
- **Saídas**: Workflow resiliente com paths de erro documentados.
- **Constraints Aplicáveis**: C5 (validação), C7 (rollback/resiliência), C8 (logging de erros).

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
error_handling:
  error_trigger:
    description: "Captura falhas de qualquer workflow e dispara ações de recuperação"
    config:
      type: "n8n-nodes-base.errorTrigger"
      parameters: {}
    alert_actions:
      slack: |
        channel: "#alerts"
        text: "Workflow failed: {{ $json.workflow.name }}\nError: {{ $json.execution.error.message }}"
      email: "Notificar equipe de plantão"
      pagerduty: "Acionar engenheiro on-call"

  retry_on_fail:
    description: "Re-tentativa automática com backoff exponencial"
    config:
      retryOnFail: true
      maxTries: 3
      waitBetweenTries: 1000  # ms, dobrar a cada tentativa
    applies_to: ["HTTP Request", "Database", "API calls"]

  stop_and_error:
    description: "Parada controlada com mensagem de erro estruturada"
    config:
      type: "n8n-nodes-base.stopAndError"
      parameters:
        errorMessage: "Invalid input: {{ $json.error }}"
    use_when: "Validação crítica falha, dados inválidos, estado inconsistente"

  best_practices:
    - "Sempre adicionar Error Trigger para workflows críticos"
    - "Usar retryOnFail em chamadas de rede (HTTP, DB)"
    - "Adicionar validação com IF antes de operações destrutivas"
    - "Logar erros com contexto (workflow ID, execution ID, timestamp)"
    - "Notificar humanos apenas para falhas críticas (evitar fadiga de alerta)"
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_error_trigger_configured() {
  local workflow='{"nodes":[{"name":"Error Trigger","type":"n8n-nodes-base.errorTrigger"}]}'
  python3 -c "
import json; d=json.loads('$workflow')
assert any(n['type'] == 'n8n-nodes-base.errorTrigger' for n in d['nodes'])
" 2>/dev/null && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && { test_error_trigger_configured && echo "✅" || echo "❌"; exit $?; }
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[workflow-patterns-basic.md]]
- [[control-flow-patterns.md]]
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]]
