---
artifact_id: "n8n-mcp-server-patterns"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C3","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/n8n-mcp-server-patterns.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/n8n-mcp-server-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:n8n-mcp-server-patterns-v1.0.0"
generated_at: "2026-05-24T14:10:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["n8n-mcp-server-exposure", "workflow-as-tool"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🔌 n8n como Servidor MCP — Exposição de Workflows como Ferramentas

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Padronizar a configuração de workflows n8n como servidores MCP, expondo ferramentas, recursos e prompts que agentes IA (Claude Code, Claude Desktop) podem invocar com segurança (C3) e rastreabilidade (C8).

## 📋 Especificação (SDD)
- **Entradas**: Definição de ferramenta (nome, parâmetros JSON Schema), workflow n8n.
- **Saídas**: Workflow com `MCP Server Trigger` configurado e documentado.
- **Side Effects**: Execução de lógica de negócio (APIs, DBs, notificações) via invocação MCP.
- **Constraints Aplicáveis**: C3 (autenticação obrigatória em produção), C5 (validação de schema), C8 (logging).
- **Dependências**: n8n com MCP habilitado (`N8N_MCP_ENABLED=true`).

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
mcp_server_patterns:
  architecture:
    description: "Workflow n8n ativado por MCP Server Trigger → ferramenta IA"
    flow: |
      Claude Code → MCP Tool Call → MCP Server Trigger → Workflow Logic → Response

  trigger_configuration:
    tool_definition:
      name: "string (ex: create_support_ticket)"
      description: "string (quando usar, o que faz, o que retorna)"
      parameters:
        type: "object"
        properties: {}  # JSON Schema dos parâmetros
        required: []    # Lista de campos obrigatórios
    
    auth_profiles:
      none:
        use: "desenvolvimento interno apenas"
        config: { authenticationType: "none" }
      api_key:
        use: "produção com clientes internos"
        config:
          authenticationType: "apiKey"
          apiKeyHeader: "X-API-Key"
          requiredScopes: ["workflows:execute"]
      oauth2:
        use: "produção com clientes externos"
        config:
          authenticationType: "oauth2"
          authorizationUrl: "https://auth.company.com/oauth/authorize"
          tokenUrl: "https://auth.company.com/oauth/token"
          scopes: ["workflows:read", "workflows:execute"]

  response_format:
    success:
      schema:
        type: "object"
        properties:
          success: { type: "boolean" }
          data: { type: "object" }
          timestamp: { type: "string", format: "date-time" }
    error:
      schema:
        type: "object"
        properties:
          error:
            type: "object"
            properties:
              code: { type: "string" }
              message: { type: "string" }
              details: { type: "object" }

  deployment:
    docker_compose_snippet: |
      services:
        n8n:
          image: n8nio/n8n:latest
          environment:
            - N8N_MCP_ENABLED=true
            - N8N_MCP_PORT=8080
            - N8N_BASIC_AUTH_ACTIVE=true
            - N8N_BASIC_AUTH_USER=admin
            - N8N_BASIC_AUTH_PASSWORD=${N8N_PASSWORD}
          ports:
            - "5678:5678"
            - "8080:8080"
          volumes:
            - n8n_data:/home/node/.n8n
          restart: unless-stopped
    
    kubernetes_snippet: |
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: n8n-mcp-server
      spec:
        replicas: 3
        template:
          spec:
            containers:
            - name: n8n
              image: n8nio/n8n:latest
              env:
              - name: N8N_MCP_ENABLED
                value: "true"
              resources:
                requests: { memory: "512Mi", cpu: "500m" }
                limits: { memory: "1Gi", cpu: "1000m" }
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_mcp_trigger_config_valid() {
  local tmp; tmp=$(mktemp)
  cat > "$tmp" << 'EOF'
{
  "toolName": "create_task",
  "description": "Create a task in Todoist",
  "parameters": {
    "type": "object",
    "properties": {
      "title": {"type": "string"},
      "due_date": {"type": "string", "format": "date-time"}
    },
    "required": ["title"]
  }
}
EOF
  python3 -c "
import json; d=json.load(open('$tmp'))
assert 'toolName' in d and 'parameters' in d
assert 'required' in d['parameters']
assert d['parameters']['type'] == 'object'
" 2>/dev/null && { rm -f "$tmp"; return 0; }
  rm -f "$tmp"; return 1
}

[[ "${1:-}" == "--test" ]] && { test_mcp_trigger_config_valid && echo "✅" || echo "❌"; exit $?; }
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[mcp-orchestrator-core.md]]
- [[claude-code-integration.md]]
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]]
