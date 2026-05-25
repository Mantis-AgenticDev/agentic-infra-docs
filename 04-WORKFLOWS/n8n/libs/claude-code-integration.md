---
artifact_id: "n8n-claude-code-integration"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C3","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/claude-code-integration.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/claude-code-integration.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:claude-code-integration-v1.0.0"
generated_at: "2026-05-24T14:30:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["claude-code-connection", "ai-assistant-tools"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🤖 Integração Claude Code ↔ n8n

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Padronizar a conexão bidireccional entre Claude Code e n8n, permitindo que Claude Code descubra e invoque workflows n8n como ferramentas, e que workflows n8n chamem Claude via MCP para processamento de linguagem natural (C3, C5, C8).

## 📋 Especificação (SDD)
- **Entradas**: Configuração `mcp_config.json` do Claude Code, workflow n8n com MCP Server Trigger.
- **Saídas**: Integração funcional onde Claude Code invoca ferramentas n8n e recebe respostas.
- **Side Effects**: Execução de automações de negócio via comandos de linguagem natural.
- **Constraints Aplicáveis**: C3 (API keys nunca em texto plano), C5 (validação de ferramentas), C8 (logging).
- **Dependências**: Claude Code/Desktop com suporte a MCP, n8n com MCP Server Trigger.

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
claude_code_integration:
  prerequisites:
    - "n8n rodando (self-hosted ou cloud)"
    - "Workflow com MCP Server Trigger configurado"
    - "Claude Code com capacidade de cliente MCP"

  configuration_steps:
    step_1_create_workflow:
      description: "Criar workflow n8n com MCP Server Trigger"
      example_tool: "create_task"
    step_2_get_mcp_url:
      description: "n8n expõe servidores MCP em https://your-n8n.com/mcp"
    step_3_configure_claude:
      description: "Adicionar entrada em mcp_config.json"
      config_snippet:
        mcpServers:
          n8n-workflows:
            url: "https://your-n8n-instance.com/mcp"
            apiKey: "your-n8n-api-key"
            description: "n8n workflow automation tools"
            tools: ["create_task", "send_email", "create_support_ticket"]

  patterns:
    pattern_1_claude_triggers_n8n:
      description: "Claude Code invoca ferramenta MCP → n8n executa workflow"
      flow: "User → Claude → MCP Tool Call → n8n MCP Server → Workflow → Response"
    pattern_2_n8n_calls_claude:
      description: "n8n invoca Claude via MCP para processamento IA"
      flow: "n8n Trigger → MCP Client Tool → Claude API → AI Processing → Next Nodes"
    pattern_3_agentic_workflow:
      description: "Combinação dos dois padrões para orquestração complexa"
      example: |
        1. User pede análise de vendas
        2. Claude chama n8n tool: get_sales_data()
        3. n8n busca dados do banco
        4. Claude analisa dados
        5. Claude chama n8n tool: generate_report(analysis)
        6. n8n cria PDF e envia por email
        7. Claude confirma ao usuário

  security:
    api_key_management:
      description: "API keys nunca em texto plano (C3)"
      storage: "Variáveis de ambiente ou cofre de credenciais"
      rotation: "Rotação a cada 90 dias"
    https_only:
      description: "TLS obrigatório em produção"
    rate_limiting:
      max_requests: 100
      window_ms: 60000
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_claude_config_schema_valid() {
  local config='{"mcpServers":{"n8n":{"url":"https://n8n.com/mcp","apiKey":"test","tools":["create_task"]}}}'
  python3 -c "
import json; d=json.loads('$config')
assert 'mcpServers' in d
for name, srv in d['mcpServers'].items():
    assert 'url' in srv and 'tools' in srv
" 2>/dev/null && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && { test_claude_config_schema_valid && echo "✅" || echo "❌"; exit $?; }
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[mcp-orchestrator-core.md]]
- [[n8n-mcp-server-patterns.md]]
- [[n8n-mcp-client-patterns.md]]
- [[agentic-workflow-patterns.md]]
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]]
