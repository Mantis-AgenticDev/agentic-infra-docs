---
artifact_id: "n8n-sub-workflow-patterns"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C2","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/sub-workflow-patterns.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/sub-workflow-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:sub-workflow-v1.0.0"
generated_at: "2026-05-24T17:50:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["workflow-modularity", "reusable-components"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🧩 Padrões de Sub-Workflows — Execute Workflow Node

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Padronizar a modularização de workflows n8n usando o nó Execute Workflow, permitindo a reutilização de lógica comum e a composição de fluxos complexos, garantindo declaração (C2), validação (C5) e observabilidade (C8).

## 📋 Especificação (SDD)
- **Entradas**: Workflow principal, ID do sub-workflow, dados a passar.
- **Saídas**: Dados processados pelo sub-workflow.
- **Constraints Aplicáveis**: C2, C5, C8.

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
sub_workflow_patterns:
  execute_workflow_node:
    description: "Invoca outro workflow como sub-rotina"
    config:
      type: "n8n-nodes-base.executeWorkflow"
      parameters:
        source: "database"  # ou 'local' para workflow no mesmo n8n
        workflowId: "order-processing-workflow-id"
        mode: "each"  # 'each' para cada item, 'once' para lote
        options:
          waitForSubWorkflow: true  # true = síncrono, false = dispara e esquece

  use_cases:
    validation: "Extrair validação de dados para sub-workflow reutilizável"
    notification: "Centralizar lógica de notificação (Slack, Email, SMS)"
    enrichment: "Enriquecer dados com APIs externas em workflow separado"
    processing: "Processar pedidos, pagamentos, faturas em workflows isolados"

  best_practices:
    - "Limitar sub-workflows a 1 responsabilidade (Single Responsibility)"
    - "Passar dados mínimos entre workflows (evitar payloads grandes)"
    - "Usar waitForSubWorkflow=true para operações síncronas"
    - "Usar tags para organizar workflows por domínio"
    - "Documentar a interface de entrada/saída do sub-workflow"
    - "Manter sub-workflows em estado 'active' para invocação"
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_execute_workflow_config() {
  local config='{"source":"database","workflowId":"wf-123","mode":"each","options":{"waitForSubWorkflow":true}}'
  python3 -c "
import json; d=json.loads('$config')
assert d['source'] in ('database','local')
assert d['mode'] in ('each','once')
" 2>/dev/null && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && { test_execute_workflow_config && echo "✅" || echo "❌"; exit $?; }
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[workflow-structure-fundamentals.md]]
- [[error-handling-patterns.md]]
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]]
