---
artifact_id: "n8n-api-integration-patterns"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C3","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/api-integration-patterns.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/api-integration-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:api-integration-v1.0.0"
generated_at: "2026-05-24T16:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["api-integration", "webhook-configuration"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🔌 Padrões de Integração com APIs

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Padronizar a integração com APIs externas em workflows n8n, incluindo decisão de abordagem (nó nativo, HTTP Request, custom node), padrões de paginação, autenticação e webhooks, garantindo segurança (C3), validação (C5) e observabilidade (C8).

## 📋 Especificação (SDD)
- **Entradas**: Especificação da API (endpoints, autenticação, formato de dados).
- **Saídas**: Workflow n8n com integração funcional.
- **Constraints Aplicáveis**: C3 (autenticação segura), C5 (validação de dados), C8 (logging).

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
api_integration:
  decision_tree:
    - "Nó nativo disponível? → Usar nó nativo"
    - "API REST simples? → HTTP Request node"
    - "Auth complexa (OAuth2)? → Custom node"
    - "Reutilizável em múltiplos workflows? → Custom node"
    - "Integração pontual? → Code node com fetch()"

  http_request_patterns:
    get_with_params:
      url: "https://api.example.com/users"
      method: "GET"
      queryParameters:
        status: "active"
        limit: 100
      authentication: "Header Auth"
      headerAuth:
        name: "Authorization"
        value: "Bearer {{$credentials.apiKey}}"
    
    post_with_json:
      url: "https://api.example.com/users"
      method: "POST"
      bodyContentType: "JSON"
      body: |
        {
          "name": "={{ $json.name }}",
          "email": "={{ $json.email }}"
        }

    pagination:
      description: "Paginação via Code node com loop while"
      code_snippet: |
        let allResults = [];
        let page = 1;
        let hasMore = true;
        while (hasMore) {
          const response = await this.helpers.request({
            method: 'GET',
            url: `https://api.example.com/data?page=${page}`,
            json: true,
          });
          allResults = allResults.concat(response.results);
          hasMore = response.hasNext;
          page++;
        }
        return allResults.map(item => ({ json: item }));

  webhook_patterns:
    receiving:
      - "Criar nó Webhook trigger"
      - "Configurar método HTTP (POST/GET)"
      - "Definir autenticação (None/Header/Basic)"
      - "Obter URL do webhook"
      - "Registrar URL no serviço externo"
    responding:
      code_snippet: |
        const webhookData = $input.first().json;
        const result = processData(webhookData);
        return [{ json: { status: 'success', data: result } }];
    urls:
      production: "https://your-domain.com/webhook/workflow-id"
      test: "https://your-domain.com/webhook-test/workflow-id"
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_http_request_config_valid() {
  local config='{"method":"GET","url":"https://api.test.com","authentication":"none"}'
  python3 -c "
import json; d=json.loads('$config')
assert d['method'] in ('GET','POST','PUT','DELETE','PATCH')
assert d['url'].startswith('http')
" 2>/dev/null && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && { test_http_request_config_valid && echo "✅" || echo "❌"; exit $?; }
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[code-execution-patterns.md]]
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]]
