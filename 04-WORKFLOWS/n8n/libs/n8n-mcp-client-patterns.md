---
artifact_id: "n8n-mcp-client-patterns"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C3","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/n8n-mcp-client-patterns.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/n8n-mcp-client-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:n8n-mcp-client-patterns-v1.0.0"
generated_at: "2026-05-24T14:20:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["n8n-mcp-consumer", "external-mcp-integration"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🔗 n8n como Cliente MCP — Consumo de Servidores MCP Externos

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Padronizar a configuração de workflows n8n que consomem servidores MCP externos via `MCP Client Tool`, permitindo que fluxos de automação invoquem ferramentas de IA, análises e outros serviços MCP com segurança (C3) e rastreabilidade (C8).

## 📋 Especificação (SDD)
- **Entradas**: URL do servidor MCP, ferramenta a invocar, parâmetros.
- **Saídas**: Dados processados pelo servidor MCP externo.
- **Side Effects**: Chamadas a APIs externas, processamento de dados, notificações.
- **Constraints Aplicáveis**: C3 (autenticação de servidores externos), C5 (validação de resposta), C8 (logging).
- **Dependências**: Servidor MCP externo acessível, credenciais configuradas.

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
mcp_client_patterns:
  architecture:
    description: "Workflow n8n com MCP Client Tool → servidor MCP externo"
    flow: |
      n8n Trigger → MCP Client Tool → External MCP Server → Process Response → Next Nodes

  client_configuration:
    connection:
      server_url: "string (ex: https://mcp.analytics-service.com)"
      authentication:
        type: "apiKey | oauth2 | none"
        apiKey: "{{$credentials.analyticsApiKey}}"
      timeout: 60000  # ms
    
    tool_selection:
      description: "Ferramentas disponíveis são descobertas via protocolo MCP"
      discovery_response:
        tools:
          - name: "generate_daily_report"
            description: "Generate daily analytics report"
            parameters: { type: "object", properties: { date: { type: "string" } } }

    parameter_mapping:
      description: "Mapear dados do workflow para parâmetros da ferramenta"
      examples:
        - workflow_field: "{{DateTime.now().toISODate()}}"
          tool_param: "date"
        - workflow_field: "{{$json.metrics}}"
          tool_param: "metrics"

  best_practices:
    connection_pooling: "Reutilizar conexões MCP quando possível"
    timeout: "Definir timeout adequado (30-60s para operações normais)"
    retry: "Implementar backoff exponencial para falhas transitórias"
    cache: "Cachear respostas de ferramentas caras quando apropriado"
    parallel: "Usar Promise.all para chamadas independentes"
    logging: "Logar todas as interações MCP para debugging"
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_mcp_client_config_has_auth() {
  local config='{"serverUrl":"https://test.mcp.com","authentication":{"type":"apiKey","apiKey":"test"}}'
  python3 -c "
import json; d=json.loads('$config')
assert 'authentication' in d and d['authentication']['type'] in ('apiKey','oauth2','none')
" 2>/dev/null && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && { test_mcp_client_config_has_auth && echo "✅" || echo "❌"; exit $?; }
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[mcp-orchestrator-core.md]]
- [[n8n-mcp-server-patterns.md]]
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]]
