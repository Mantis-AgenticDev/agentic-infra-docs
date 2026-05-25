---
artifact_id: "n8n-workflow-structure-fundamentals"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C2","C5"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/workflow-structure-fundamentals.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/workflow-structure-fundamentals.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:workflow-structure-fundamentals-v1.0.0"
generated_at: "2026-05-24T15:20:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["workflow-creation", "workflow-structure", "n8n-api-usage"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 📐 Estrutura de Workflows n8n — Fundamentos

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Padronizar a estrutura JSON de workflows n8n, a configuração de nós, conexões e o uso da API REST, garantindo que toda automação seja declarativa (C2) e validável estruturalmente (C5).

## 📋 Especificação (SDD)
- **Entradas**: Definição de workflow (nome, nós, conexões, configurações).
- **Saídas**: JSON de workflow n8n válido.
- **Constraints Aplicáveis**: C2 (declarativo), C5 (validação estrutural).
- **Dependências**: n8n com API REST habilitada (`N8N_API_KEY`).

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
workflow_structure:
  core_json:
    required_fields: ["name", "nodes", "connections", "settings"]
    settings:
      executionOrder: "v1"  # padrão canônico

  node_structure:
    required_fields: ["id", "name", "type", "typeVersion", "position", "parameters"]
    optional_fields: ["credentials", "webhookId", "notes"]
    id_format: "string único (UUID recomendado)"
    name_format: "Display Name legível"
    type_format: "n8n-nodes-base.<node_type>"
    position_format: "[x, y] coordenadas no canvas"

  connection_structure:
    format: |
      {
        "Source Node Name": {
          "main": [
            [{"node": "Target Node Name", "type": "main", "index": 0}]
          ]
        }
      }
    types:
      main: "Fluxo principal de dados"
      error: "Roteamento de falhas"

  rest_api:
    base_url: "http://localhost:5678/api/v1"
    headers:
      - "X-N8N-API-KEY: <api_key>"
      - "Content-Type: application/json"
    
    endpoints:
      list: "GET /workflows"
      get: "GET /workflows/{id}"
      create: "POST /workflows"
      update: "PUT /workflows/{id}"
      delete: "DELETE /workflows/{id}"
      activate: "POST /workflows/{id}/activate"
      deactivate: "POST /workflows/{id}/deactivate"
      executions: "GET /executions?workflowId={id}"

  expression_syntax:
    current_field: "={{ $json.field }}"
    nested_field: "={{ $json.body.param }}"
    node_output: "={{ $('Node Name').item.json.field }}"
    first_item: "={{ $input.first().json }}"
    all_items: "={{ $input.all() }}"
    to_json_string: "={{ JSON.stringify($json) }}"

  common_node_types:
    webhook: "n8n-nodes-base.webhook"
    http_request: "n8n-nodes-base.httpRequest"
    respond_webhook: "n8n-nodes-base.respondToWebhook"
    if_condition: "n8n-nodes-base.if"
    switch: "n8n-nodes-base.switch"
    set_data: "n8n-nodes-base.set"
    code: "n8n-nodes-base.code"
    split_batches: "n8n-nodes-base.splitInBatches"
    merge: "n8n-nodes-base.merge"
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_workflow_json_valid() {
  local tmp; tmp=$(mktemp)
  cat > "$tmp" << 'EOF'
{"name":"Test","nodes":[],"connections":{},"settings":{"executionOrder":"v1"}}
EOF
  python3 -c "
import json; d=json.load(open('$tmp'))
assert all(k in d for k in ('name','nodes','connections','settings'))
assert d['settings']['executionOrder'] == 'v1'
" 2>/dev/null && { rm -f "$tmp"; return 0; }
  rm -f "$tmp"; return 1
}

[[ "${1:-}" == "--test" ]] && { test_workflow_json_valid && echo "✅" || echo "❌"; exit $?; }
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[workflow-patterns-basic.md]]
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]]
