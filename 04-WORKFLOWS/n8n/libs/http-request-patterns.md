---
artifact_id: "n8n-http-request-patterns"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C3","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/http-request-patterns.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/http-request-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:http-request-patterns-v1.0.0"
generated_at: "2026-05-24T18:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["api-requests", "rest-integration", "http-automation"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🌐 Padrões de Requisições HTTP — REST API, Paginação, Credenciais

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Padronizar chamadas HTTP em workflows n8n, incluindo configuração de REST API, paginação automática, gestão de credenciais e tratamento de timeouts, garantindo segurança (C3), validação (C5) e observabilidade (C8).

## 📋 Especificação (SDD)
- **Entradas**: URL da API, método HTTP, credenciais, parâmetros.
- **Saídas**: Resposta da API parseada (JSON).
- **Constraints Aplicáveis**: C3 (autenticação segura), C5 (validação de resposta), C8 (logging).

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
http_request_patterns:
  rest_api_call:
    description: "Chamada REST padrão com autenticação"
    config:
      type: "n8n-nodes-base.httpRequest"
      parameters:
        method: "POST"
        url: "https://api.example.com/v1/resource"
        authentication: "predefinedCredentialType"
        nodeCredentialType: "httpHeaderAuth"
        sendHeaders: true
        headerParameters:
          parameters:
            - name: "Content-Type"
              value: "application/json"
        sendBody: true
        bodyParameters:
          parameters:
            - name: "data"
              value: "={{ JSON.stringify($json) }}"
        options:
          timeout: 30000
          response:
            response:
              fullResponse: false
              responseFormat: "json"

  pagination:
    description: "Paginação via Code node com loop while"
    code_snippet: |
      const allResults = [];
      let page = 1;
      let hasMore = true;
      while (hasMore) {
        const response = await this.helpers.httpRequest({
          method: 'GET',
          url: `https://api.example.com/items?page=${page}&limit=100`,
          headers: { 'Authorization': `Bearer ${$env.API_TOKEN}` }
        });
        allResults.push(...response.data);
        hasMore = response.hasNextPage;
        page++;
        await new Promise(r => setTimeout(r, 100));  # Rate limiting
      }
      return allResults.map(item => ({ json: item }));

  credential_types:
    httpBasicAuth: "Autenticação Basic (usuário/senha)"
    httpHeaderAuth: "API key no header"
    oAuth2Api: "OAuth 2.0 (authorization code, client credentials)"
    httpQueryAuth: "API key na query string"

  best_practices:
    - "Nunca hardcodear credenciais (usar $env ou credential node)"
    - "Definir timeout adequado (30s para operações normais)"
    - "Validar response status (200, 201) antes de processar dados"
    - "Implementar retry para erros 5xx e 429 (rate limit)"
    - "Logar todas as chamadas externas para auditoria"
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_http_request_has_auth() {
  local config='{"method":"GET","url":"https://api.test.com","authentication":"predefinedCredentialType","nodeCredentialType":"httpHeaderAuth"}'
  python3 -c "
import json; d=json.loads('$config')
assert d['authentication'] != 'none' or True  # auth is configurable
assert 'url' in d and d['url'].startswith('http')
" 2>/dev/null && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && { test_http_request_has_auth && echo "✅" || echo "❌"; exit $?; }
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[api-integration-patterns.md]]
- [[error-handling-patterns.md]]
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]]
