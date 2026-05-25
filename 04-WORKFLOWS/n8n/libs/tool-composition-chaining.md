---
artifact_id: "n8n-tool-composition-chaining"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/tool-composition-chaining.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/tool-composition-chaining.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:tool-composition-v1.0.0"
generated_at: "2026-05-24T14:50:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["tool-chaining", "parallel-execution", "workflow-composition"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# ⛓️ Composição e Encadeamento de Ferramentas MCP

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Padronizar técnicas de composição de ferramentas MCP em workflows n8n, incluindo chamadas sequenciais, execução paralela e padrões de orquestração complexos, garantindo integridade (C5) e observabilidade (C8).

## 📋 Especificação (SDD)
- **Entradas**: Lista de ferramentas MCP a serem invocadas, dependências entre elas.
- **Saídas**: Workflow n8n com múltiplos nós `MCP Client Tool` encadeados.
- **Side Effects**: Execução coordenada de múltiplas ferramentas em sistemas externos.
- **Constraints Aplicáveis**: C5 (validação de sequência), C8 (logging de cada etapa).
- **Dependências**: Servidores MCP externos configurados.

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
tool_composition:
  sequential_chaining:
    description: "Ferramentas executadas em ordem, output de uma é input da próxima"
    example: "Processamento de pedido"
    flow: |
      get_order(orderId) → check_inventory(items) 
        → [if available] process_payment(orderId, amount) 
          → create_shipment(orderId, address) 
          → send_email(customer, 'order_confirmed')
        → [if not available] create_purchase_order(items) 
          → send_email(customer, 'order_delayed')

  parallel_execution:
    description: "Ferramentas independentes executadas simultaneamente"
    example: "Enriquecimento de perfil de cliente"
    flow: |
      Promise.all([
        get_customer_orders(customerId),
        get_support_history(customerId),
        get_social_data(customerId),
        get_email_metrics(customerId)
      ]) → merge data → update_crm(customerId, profile)

  conditional_routing:
    description: "Roteamento baseado em resultado de ferramenta anterior"
    example: "Análise de risco de pagamento"
    flow: |
      analyze_payment_risk(payment) 
        → [risk > 0.7] flag_for_review(orderId) + notify_fraud_team(orderId)
        → [risk <= 0.7] auto_approve(orderId) + trigger_fulfillment(orderId)

  error_handling:
    description: "Tratamento de falhas em cadeias de ferramentas"
    strategies:
      retry: "Re-tentativa com backoff exponencial (max 3 tentativas)"
      fallback: "Ferramenta alternativa quando a primária falha"
      compensate: "Ação compensatória para reverter efeitos parciais"
      dead_letter: "Encaminhar para fila de revisão manual"

  best_practices:
    minimize_calls: "Agrupar operações quando possível"
    webhooks: "Usar webhooks para operações longas"
    async: "Não bloquear em operações lentas"
    idempotency: "Garantir que chamadas repetidas não causem efeitos duplicados"
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_sequential_chain_pattern() {
  local chain=("get_order" "check_inventory" "process_payment" "send_email")
  [[ "${#chain[@]}" -eq 4 ]] && return 0 || return 1
}

test_parallel_pattern() {
  local tools=("get_orders" "get_tickets" "get_social" "get_metrics")
  [[ "${#tools[@]}" -eq 4 ]] && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && { 
  test_sequential_chain_pattern && test_parallel_pattern && echo "✅" || echo "❌"
  exit $?
}
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[mcp-orchestrator-core.md]]
- [[agentic-workflow-patterns.md]]
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]]
