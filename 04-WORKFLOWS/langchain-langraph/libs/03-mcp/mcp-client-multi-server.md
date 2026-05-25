---
artifact_id: "mcp-client-multi-server"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/mcp-client-multi-server.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/mcp-client-multi-server.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:mcp-client-multi-server-v1.0.0"
generated_at: "2026-05-25T01:10:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["tools-mcp-integration", "agents-swarm-architecture"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🔌 MCP Client Multi‑Server – Conexão, Sessões e Autenticação

> **Contrato modular**: Documenta o uso de `MultiServerMCPClient` para conectar a múltiplos servidores MCP, gerenciar sessões, passar headers de autenticação e carregar ferramentas em agentes LangChain/LangGraph.

---

## 🎯 Propósito
Permitir que agentes MANTIS consumam ferramentas de diversos servidores MCP simultaneamente, com isolamento de sessão e segurança.

## 📋 Especificação (SDD)
- **Entradas**: Configuração de servidores MCP (stdio/HTTP), credenciais.
- **Saídas**: Lista de ferramentas LangChain prontas para uso em agentes.
- **Side Effects**: Conexões de rede, subprocessos.
- **Constraints**: C1 (contrato de ferramentas), C3 (proteção de headers), C5 (schema), C7 (fallback), C8 (logs), C9 (rastreio).
- **Dependências**: `langchain-mcp-adapters`, `mcp`.

---

## 🛡️ Bootstrap (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ... (fallback)
```

### 1. MultiServerMCPClient Básico
```python
from langchain_mcp_adapters.client import MultiServerMCPClient
from langchain.agents import create_agent

client = MultiServerMCPClient({
    "math": {
        "transport": "stdio",
        "command": "python",
        "args": ["/path/to/math_server.py"]
    },
    "weather": {
        "transport": "http",
        "url": "http://localhost:8000/mcp"
    }
})
tools = await client.get_tools()
agent = create_agent("claude-sonnet-4-6", tools)
```

### 2. Passagem de Headers (Auth)
```python
client = MultiServerMCPClient({
    "weather": {
        "transport": "http",
        "url": "http://localhost:8000/mcp",
        "headers": {
            "Authorization": "Bearer YOUR_TOKEN",
            "X-Tenant-ID": os.getenv("TENANT_ID", "global")
        }
    }
})
```

### 3. Sessões Stateful
```python
async with client.session("math") as session:
    tools = await load_mcp_tools(session)
    agent = create_agent("google_genai:gemini-3.5-flash", tools)
    # A sessão persiste, permitindo estado entre chamadas
```

### 4. Autenticação Customizada (httpx.Auth)
```python
from httpx import Auth

class BearerAuth(Auth):
    def __init__(self, token):
        self.token = token
    def auth_flow(self, request):
        request.headers["Authorization"] = f"Bearer {self.token}"
        yield request

client = MultiServerMCPClient({
    "secure_svc": {
        "transport": "http",
        "url": "http://localhost:8000/mcp",
        "auth": BearerAuth(os.getenv("SERVICE_TOKEN"))
    }
})
```

### 5. Filtragem de Ferramentas (C3)
```python
# No lado do cliente, filtrar ferramentas perigosas
dangerous = ["delete_all", "shutdown"]
tools = [t for t in await client.get_tools() if t.name not in dangerous]
```

### 6. Integração com LangGraph StateGraph
```python
from langgraph.prebuilt import ToolNode, tools_condition
tools = await client.get_tools()
graph = StateGraph(MessagesState)
graph.add_node("call_model", call_model)
graph.add_node("tools", ToolNode(tools))
graph.add_conditional_edges("call_model", tools_condition)
# ...
```

---

## 🧪 Testes Unitários (TDD)
```python
@pytest.mark.asyncio
async def test_multi_client_gets_tools():
    client = MultiServerMCPClient({...})
    tools = await client.get_tools()
    assert len(tools) > 0
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/mcp-client-multi-server.md --json
```

---

## 🔗 Referências Cruzadas
- [[mcp-server-fundamentals.md]]
- [[tools-mcp-integration.md]]
