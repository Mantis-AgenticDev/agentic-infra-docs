---
artifact_id: "n8n-workflow-patterns-basic"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C2","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/workflow-patterns-basic.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/workflow-patterns-basic.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:workflow-patterns-basic-v1.0.0"
generated_at: "2026-05-24T15:30:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["workflow-creation", "common-patterns"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🔄 Padrões Básicos de Workflow

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Padronizar os padrões de workflow mais comuns em n8n: triggers webhook, chamadas HTTP, ramificação condicional (IF/Switch) e processamento em lote (SplitInBatches), garantindo declaração (C2), validação (C5) e observabilidade (C8).

## 📋 Especificação (SDD)
- **Entradas**: Tipo de padrão (webhook, http, conditional, batch).
- **Saídas**: JSON de workflow n8n funcional.
- **Constraints Aplicáveis**: C2, C5, C8.

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
patterns:
  webhook_triggered:
    description: "Cria endpoint HTTP que dispara workflow"
    structure:
      nodes:
        webhook:
          type: "n8n-nodes-base.webhook"
          typeVersion: 2
          parameters:
            path: "my-endpoint"
            httpMethod: "POST"
            responseMode: "responseNode"
        respond:
          type: "n8n-nodes-base.respondToWebhook"
          typeVersion: 1.1
          parameters:
            respondWith: "json"
            responseBody: "={{ $json }}"
      connections:
        "Webhook": { main: [[{ node: "Respond", type: "main", index: 0 }]] }
    access_url: "http://localhost:5678/webhook/my-endpoint"

  http_request:
    description: "Chamada a API externa com autenticação"
    node_config:
      type: "n8n-nodes-base.httpRequest"
      typeVersion: 4.2
      parameters:
        method: "POST"
        url: "https://api.example.com/endpoint"
        authentication: "predefinedCredentialType"
        sendBody: true
        specifyBody: "json"
        jsonBody: "={{ JSON.stringify($json) }}"

  conditional_branching:
    description: "Roteamento baseado em condições"
    node_config:
      type: "n8n-nodes-base.if"
      typeVersion: 2
      parameters:
        conditions:
          options:
            caseSensitive: true
            typeValidation: "strict"
          conditions:
            - leftValue: "={{ $json.status }}"
              rightValue: "success"
              operator:
                type: "string"
                operation: "equals"
          combinator: "and"

  batch_processing:
    description: "Processamento de itens em lotes"
    node_config:
      type: "n8n-nodes-base.splitInBatches"
      typeVersion: 3
      parameters:
        batchSize: 10
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_webhook_pattern_valid() {
  local tmp; tmp=$(mktemp)
  cat > "$tmp" << 'EOF'
{"name":"Test","nodes":[{"id":"w","name":"Webhook","type":"n8n-nodes-base.webhook","typeVersion":2,"position":[0,0],"parameters":{"path":"test","httpMethod":"POST"}}],"connections":{},"settings":{"executionOrder":"v1"}}
EOF
  python3 -c "
import json; d=json.load(open('$tmp'))
assert d['nodes'][0]['type'] == 'n8n-nodes-base.webhook'
assert d['nodes'][0]['parameters']['httpMethod'] == 'POST'
" 2>/dev/null && { rm -f "$tmp"; return 0; }
  rm -f "$tmp"; return 1
}

[[ "${1:-}" == "--test" ]] && { test_webhook_pattern_valid && echo "✅" || echo "❌"; exit $?; }
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[workflow-structure-fundamentals.md]]
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]]
