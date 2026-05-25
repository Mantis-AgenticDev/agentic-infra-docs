---
artifact_id: "n8n-mcp-orchestrator-core"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C2","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/mcp-orchestrator-core.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/mcp-orchestrator-core.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:mcp-orchestrator-core-v1.0.0"
generated_at: "2026-05-24T14:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: true
  required_for: ["mcp-orchestration", "n8n-agentic-workflows"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🧠 MCP Orchestrator Core — Fundamentos do Model Context Protocol

> **Contrato modular**: Este artefato é filho do Master Agent `n8n-master-agent-mantis`.
> Herda hardening, observability, thinking system e constraints via source/import.
> Contém APENAS a lógica de domínio específica para orquestração MCP com n8n.

## 🎯 Propósito
Fornecer os fundamentos canônicos do Model Context Protocol (MCP) para orquestração de agentes IA com n8n, incluindo arquitetura bidireccional, componentes principais e padrões de comunicação, garantindo que toda automação agêntica siga as constraints C2 (IaC declarativo), C5 (validação estrutural) e C8 (observabilidade).

## 📋 Especificação (SDD)
- **Entradas**: Definição de ferramentas MCP (nome, descrição, parâmetros JSON Schema).
- **Saídas**: Workflows n8n com `MCP Server Trigger` ou `MCP Client Tool` configurados.
- **Side Effects**: Execução de workflows via invocação MCP; alteração de estado em sistemas externos.
- **Constraints Aplicáveis**: C2 (declarativo), C5 (integridade estrutural), C8 (logging de execuções).
- **Dependências**: n8n ≥ 1.0 com suporte a MCP; Claude Code/Desktop como cliente de referência.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C5+C8)

> **Regra de ouro**: Fonte o Master Agent para herdar hardening/observability. Se não disponível, este módulo opera como referência canônica independente.

```yaml
# Bootstrap: referência ao Master Agent (n8n-master-agent-mantis)
# Se disponível, herda mantis_log(), constraints e hardening.
# Fallback: este módulo contém as definições mínimas autocontidas.

mcp_fundamentals:
  protocol: "Model Context Protocol (MCP)"
  version: "2024-11-05"
  transport: ["stdio", "HTTP/SSE"]
  
  components:
    server:
      description: "Expõe capacidades (tools, resources, prompts) para clientes IA"
      n8n_implementation: "MCP Server Trigger node"
    client:
      description: "Conecta a servidores MCP e invoca suas capacidades"
      n8n_implementation: "MCP Client Tool node"
    resource:
      description: "Fontes de dados e contexto expostas por servidores MCP"
      examples: ["documents", "database records", "API responses"]
    tool:
      description: "Funções/workflows que agentes IA podem invocar"
      n8n_implementation: "Workflows ativados via MCP Server Trigger"
    prompt:
      description: "Templates de prompt estruturados para interações IA"
      examples: ["system instructions", "context-aware templates"]

  bidirectional_patterns:
    n8n_as_server: "Workflows com MCP Server Trigger → ferramentas para Claude Code"
    n8n_as_client: "Workflows com MCP Client Tool → consomem MCPs externos"
    combined: "n8n orquestra múltiplos MCPs em cadeia com Claude Code como agente"

  key_n8n_nodes:
    mcp_server_trigger:
      role: "Ponto de entrada para invocações MCP"
      config:
        tool_name: "string (ex: create_support_ticket)"
        description: "string (descrição clara para o IA)"
        parameters: "JSON Schema (tipo, propriedades, obrigatórios)"
        authentication: "none | apiKey | oauth2"
    mcp_client_tool:
      role: "Invoca servidores MCP externos"
      config:
        server_url: "string (endpoint MCP)"
        tool: "string (nome da ferramenta)"
        parameters: "objeto (mapeado do workflow)"
        timeout: "número (ms, default 30000)"

  auth_patterns:
    api_key:
      header: "X-API-Key"
      scopes: ["workflows:execute"]
    oauth2:
      grant_types: ["authorization_code", "client_credentials"]
      scopes: ["workflows:read", "workflows:execute"]
    none: "Apenas para uso interno/desenvolvimento"
```

---

## 🧪 Testes Unitários (TDD)

```bash
#!/usr/bin/env bash
# Test: validação de schema de ferramenta MCP
# Constraint: C5 (integridade estrutural)

test_mcp_tool_schema_valid() {
  local tmp; tmp=$(mktemp)
  cat > "$tmp" << 'EOF'
{
  "toolName": "test_tool",
  "description": "A test tool",
  "parameters": {
    "type": "object",
    "properties": {
      "input": {"type": "string"}
    },
    "required": ["input"]
  }
}
EOF
  python3 -c "
import json, jsonschema
schema = json.load(open('$tmp'))
jsonschema.validate(schema, {
  'type': 'object',
  'required': ['toolName', 'description', 'parameters'],
  'properties': {
    'toolName': {'type': 'string'},
    'description': {'type': 'string'},
    'parameters': {
      'type': 'object',
      'required': ['type', 'properties'],
      'properties': {
        'type': {'enum': ['object']},
        'properties': {'type': 'object'}
      }
    }
  }
})
" 2>/dev/null && { rm -f "$tmp"; return 0; }
  rm -f "$tmp"; return 1
}

if [[ "${1:-}" == "--test" ]]; then
  test_mcp_tool_schema_valid && echo "✅ Test passed" || echo "❌ Test failed"
  exit $?
fi
```

---

## 🔍 Validação (VDD)

```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/n8n/libs/mcp-orchestrator-core.md \
  --json \
  --check-structural \
  --check-error-handling \
  --check-observability
```

---

## 🔗 Referências Cruzadas (Wikilinks Mínimos)

- [[n8n-master-agent.md]] ← Fonte de hardening, observability, constraints
- [[claude-code-integration.md]] ← Integração bidireccional Claude Code ↔ n8n
- [[agentic-workflow-patterns.md]] ← Padrões de orquestração multi-agente
- [[/05-CONFIGURATIONS/validation/orchestrator-engine/main.go]] ← Motor de validação
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]] ← Mapeamento constraints


---

## 📝 Histórico de Revisões

| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-24T14:00:00Z | n8n-master-agent | Criação inicial: fundamentos MCP | C2, C5, C8 |

---

## 🔍 Observability (Eventos Específicos)

| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `mcp_tool_invoked` | INFO | C8 | `"Tool=create_ticket, Client=claude-code, Tenant=restaurante_001"` |
| `mcp_tool_failed` | ERROR | C5 | `"Tool=send_email, Reason=INVALID_PARAMETERS, Missing=customerId"` |
| `mcp_server_registered` | INFO | C2 | `"Server=n8n-workflows, Tools=5, Auth=apiKey"` |
