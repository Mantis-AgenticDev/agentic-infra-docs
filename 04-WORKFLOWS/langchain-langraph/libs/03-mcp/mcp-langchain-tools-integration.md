---
artifact_id: "mcp-langchain-tools-integration"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/mcp-langchain-tools-integration.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/mcp-langchain-tools-integration.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:mcp-langchain-tools-v1.0.0"
generated_at: "2026-05-25T03:30:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["tools-mcp-integration", "agents-swarm-architecture", "tools-custom"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🔗 MCP ↔ LangChain Tools Integration – Conversão e Uso Avançado

> **Contrato modular**: Documenta como converter ferramentas MCP em ferramentas LangChain, usá-las em agentes e fluxos StateGraph, e manipular artefatos de retorno como conteúdo estruturado e multimodal.

---

## 🎯 Propósito
Integrar profundamente o ecossistema MCP com LangChain/LangGraph, permitindo que agentes MANTIS utilizem ferramentas de múltiplos servidores como se fossem nativas.

## 📋 Especificação (SDD)
- **Entradas**: Servidores MCP configurados, sessões ativas.
- **Saídas**: Ferramentas LangChain compatíveis com agentes e ToolNode.
- **Side Effects**: Execução remota de ferramentas.
- **Constraints Aplicáveis**: C1 (conversão de schema), C3 (segurança), C5 (tipagem), C7 (tratamento de falhas), C8 (tracing), C9 (trace distribuído).
- **Dependências**: `langchain-mcp-adapters`, `langchain-core`.

---

## 🛡️ Bootstrap (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Conversão Básica com `load_mcp_tools`
```python
from langchain_mcp_adapters.tools import load_mcp_tools
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

server_params = StdioServerParameters(command="python", args=["server.py"])
async with stdio_client(server_params) as (read, write):
    async with ClientSession(read, write) as session:
        await session.initialize()
        tools = await load_mcp_tools(session)
        # tools já são ferramentas LangChain
        agent = create_agent("openai:gpt-4.1", tools)
```

### 2. Uso com StateGraph e ToolNode
```python
from langgraph.prebuilt import ToolNode, tools_condition

tools = await client.get_tools()

def call_model(state: MessagesState):
    response = model.bind_tools(tools).invoke(state["messages"])
    return {"messages": response}

builder = StateGraph(MessagesState)
builder.add_node("call_model", call_model)
builder.add_node("tools", ToolNode(tools))
builder.add_conditional_edges("call_model", tools_condition)
builder.add_edge("tools", "call_model")
graph = builder.compile()
```

### 3. Acessando Conteúdo Estruturado (Artifacts)
```python
result = await agent.ainvoke({"messages": [{"role": "user", "content": "get data"}]})
for msg in result["messages"]:
    if isinstance(msg, ToolMessage) and hasattr(msg, 'artifact'):
        structured_data = msg.artifact.get("structured_content")
        mantis_log("INFO", "artifact_received", json.dumps(structured_data))
```

### 4. Interceptor para Enriquecer Ferramentas
```python
async def add_retry_to_mcp_tools(request: MCPToolCallRequest, handler):
    for attempt in range(3):
        try:
            return await handler(request)
        except Exception as e:
            mantis_log("WARN", "mcp_retry", f"Tentativa {attempt+1}: {e}")
            await asyncio.sleep(2 ** attempt)
    raise

client = MultiServerMCPClient({...}, tool_interceptors=[add_retry_to_mcp_tools])
```

### 5. Ferramentas MCP como Funções LangChain Customizadas
```python
# Também é possível criar uma LangChain tool que encapsula uma chamada MCP manual
from langchain_core.tools import tool

@tool
async def mcp_weather_tool(city: str) -> str:
    """Consulta o clima via MCP."""
    async with client.session("weather") as session:
        result = await session.call_tool("get_weather", {"city": city})
        return result.content[0].text
```

### 6. Tratamento de Erros e Timeout
```python
from tenacity import retry, stop_after_attempt, wait_fixed

@retry(stop=stop_after_attempt(3), wait=wait_fixed(2))
async def robust_mcp_call(tool_name, args):
    return await client.call_tool(tool_name, args)
```

---

## 🧪 Testes Unitários (TDD)
```python
@pytest.mark.asyncio
async def test_load_mcp_tools():
    # Com um servidor MCP mock
    ...
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/mcp-langchain-tools-integration.md --json
```

---

## 🔗 Referências Cruzadas
- [[mcp-client-multi-server.md]]
- [[tools-mcp-integration.md]]
