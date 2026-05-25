---
artifact_id: "mcp-testing-strategies"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/mcp-testing-strategies.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/mcp-testing-strategies.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:mcp-testing-v1.0.0"
generated_at: "2026-05-25T02:30:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["agents-swarm-testing", "tools-mcp-integration"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🧪 MCP Testing Strategies – Mocks, Integração e Validação de Contratos

> **Contrato modular**: Define a abordagem de testes para servidores e clientes MCP, incluindo testes unitários com mocks, testes de integração com servidores reais e verificação de conformidade.

---

## 🎯 Propósito
Garantir a qualidade e a conformidade das implementações MCP, assegurando que ferramentas, recursos e prompts se comportem como esperado em todos os cenários.

## 📋 Especificação (SDD)
- **Entradas**: Servidor MCP, ferramentas, configuração de cliente.
- **Saídas**: Resultados de testes.
- **Side Effects**: Nenhum em produção.
- **Constraints Aplicáveis**: C1 (contrato de ferramenta), C5 (schema), C7 (fallback), C8 (logs de teste).
- **Dependências**: `pytest`, `pytest-asyncio`, `unittest.mock`.

---

## 🛡️ Bootstrap (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Teste Unitário de Ferramenta Isolada
```python
import pytest
from server import add

def test_add_positive():
    assert add(2, 3) == 5

def test_add_negative():
    assert add(-1, 1) == 0

def test_add_type_error():
    with pytest.raises(TypeError):
        add("a", 2)
```

### 2. Mock de Cliente MCP
```python
from unittest.mock import AsyncMock, patch
from langchain_mcp_adapters.client import MultiServerMCPClient

@pytest.mark.asyncio
async def test_multi_client_mock():
    with patch('langchain_mcp_adapters.client.stdio_client') as mock_stdio:
        mock_session = AsyncMock()
        mock_session.list_tools.return_value = [MockTool("test_tool")]
        client = MultiServerMCPClient({"test": {"transport": "stdio", "command": "echo"}})
        tools = await client.get_tools()
        assert len(tools) == 1
        assert tools[0].name == "test_tool"
```

### 3. Teste de Integração com Servidor Real
```python
@pytest.mark.asyncio
async def test_real_server():
    client = MultiServerMCPClient({
        "math": {
            "transport": "stdio",
            "command": "python",
            "args": ["tests/fixtures/math_server.py"]
        }
    })
    tools = await client.get_tools()
    agent = create_agent("openai:gpt-4.1", tools)
    response = await agent.ainvoke({"messages": "quanto é 3+5?"})
    assert "8" in response["messages"][-1].content
```

### 4. Teste de Interceptor
```python
from langchain_mcp_adapters.interceptors import MCPToolCallRequest

@pytest.mark.asyncio
async def test_retry_interceptor():
    call_count = 0
    async def flaky_handler(req):
        nonlocal call_count
        call_count += 1
        if call_count < 3:
            raise ConnectionError("fail")
        return "success"

    result = await retry_interceptor(MockRequest(), flaky_handler, max_retries=3, delay=0)
    assert result == "success"
    assert call_count == 3
```

### 5. Validação de Schema com Pydantic
```python
def test_invalid_transfer_input():
    with pytest.raises(ValidationError):
        TransferInput(from_account="A", to_account="A", amount=100)
```

### 6. Teste de Resiliência (Timeout)
```python
@pytest.mark.asyncio
async def test_timeout():
    with patch('httpx.AsyncClient.get', side_effect=asyncio.TimeoutError):
        result = await fetch_external_data("http://slow.example.com")
        assert "tempo limite" in result.lower()
```

---

## 🧪 Execução de Testes
```bash
pytest tests/mcp/ -v --cov=server --cov-report=term-missing
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/mcp-testing-strategies.md --json
```

---

## 🔗 Referências Cruzadas
- [[mcp-server-fundamentals.md]]
- [[agents-swarm-testing.md]]
