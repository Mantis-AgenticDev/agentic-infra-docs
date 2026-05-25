---
artifact_id: "n8n-resource-management"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C4","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/resource-management.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/resource-management.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:resource-management-v1.0.0"
generated_at: "2026-05-24T15:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["mcp-resources", "context-management", "knowledge-exposure"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 📚 Gestão de Recursos MCP

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Padronizar a exposição e o consumo de recursos MCP (documentos, dados, contexto) em workflows n8n, permitindo que agentes IA acessem informações sem invocação de ferramentas, garantindo rastreabilidade (C4), integridade (C5) e observabilidade (C8).

## 📋 Especificação (SDD)
- **Entradas**: URI de recurso, tipo de conteúdo, dados a serem expostos.
- **Saídas**: Recurso MCP configurado e disponível para clientes IA.
- **Side Effects**: Leitura de fontes de dados externas (APIs, bancos, arquivos).
- **Constraints Aplicáveis**: C4 (tenant isolation nos recursos), C5 (validação de schema), C8 (logging de acessos).
- **Dependências**: n8n com MCP Server Trigger, fontes de dados externas.

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
resource_management:
  resource_types:
    documents:
      description: "Documentação, manuais, guias em formato Markdown ou texto"
      examples: ["api-docs/authentication", "guides/deployment"]
    data:
      description: "Dados estruturados em JSON, CSV, ou consultas a bancos"
      examples: ["sales/report?date=today", "users/active"]
    context:
      description: "Configurações, metadados, variáveis de ambiente"
      examples: ["config/app-settings", "environment/variables"]
    templates:
      description: "Templates de prompts, snippets de código, exemplos"
      examples: ["prompts/code-review", "templates/email-response"]

  exposing_resources:
    description: "Workflow n8n com MCP Server Trigger configurado para recursos"
    config_example:
      resources:
        - uri: "resource://api-docs/authentication"
          name: "Documentação da API de Autenticação"
          description: "Documentação completa dos endpoints de autenticação"
          mimeType: "text/markdown"
      workflow_logic: |
        MCP Server Trigger (resource: api-docs/*) 
          → Switch (route by URI) 
          → HTTP Request (fetch from docs repo) 
          → Format and return markdown

  consuming_resources:
    description: "Claude Code lê recursos para obter contexto antes de agir"
    example: |
      User: "Como me autentico na API?"
      Claude Code:
        1. Lê resource://api-docs/authentication
        2. Analisa documentação
        3. Fornece resposta com exemplos de código

  security:
    tenant_isolation:
      description: "Recursos filtrados por tenant_id (C4)"
      implementation: "WHERE tenant_id = current_setting('app.tenant_id')"
    authentication: "Recursos sensíveis exigem autenticação (C3)"
    rate_limiting: "Limitar acesso a recursos pesados (C8)"
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_resource_uri_format() {
  local uri="resource://api-docs/authentication"
  [[ "$uri" =~ ^resource://[a-z0-9-]+/[a-zA-Z0-9/_-]+$ ]] && return 0 || return 1
}

test_resource_config_has_required_fields() {
  local config='{"uri":"resource://test","name":"Test","mimeType":"text/plain"}'
  python3 -c "
import json; d=json.loads('$config')
assert all(k in d for k in ('uri','name','mimeType'))
" 2>/dev/null && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && {
  test_resource_uri_format && test_resource_config_has_required_fields && echo "✅" || echo "❌"
  exit $?
}
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[mcp-orchestrator-core.md]]
- [[n8n-mcp-server-patterns.md]]
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]]
