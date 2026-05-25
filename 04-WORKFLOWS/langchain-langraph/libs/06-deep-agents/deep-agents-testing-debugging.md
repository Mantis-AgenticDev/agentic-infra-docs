---
artifact_id: "deep-agents-testing-debugging"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-testing-debugging.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-testing-debugging.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-testing-v1.0.0"
generated_at: "2026-05-25T20:30:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-core-customization"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🧪 Deep Agents – Testes e Debugging

> **Contrato modular**: Artefato filho do Master Agent. Cobre estratégias de teste unitário, teste de integração, mock de ferramentas, time travel com checkpoints e debugging com LangSmith.

---

## 🎯 Propósito
Garantir a qualidade e a confiabilidade dos agentes MANTIS através de testes automatizados e ferramentas de depuração.

## 📋 Especificação (SDD)
- **Entradas**: Agente configurado, casos de teste, checkpointer.
- **Saídas**: Resultados de testes, traces de debug.
- **Side Effects**: Nenhum em produção.
- **Constraints Aplicáveis**: C1 (assertividade), C5 (cobertura de testes), C7 (recuperação de estado), C8 (logs), C9 (tracing).
- **Dependências**: `pytest`, `langsmith`, `langgraph`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Teste Unitário de Ferramenta

```python
from langchain.tools import tool

@tool
def add(a: int, b: int) -> int:
    return a + b

def test_add_tool():
    result = add.invoke({"a": 2, "b": 3})
    assert result == 5
```

### 2. Mock de Ferramenta com `unittest.mock`

```python
from unittest.mock import AsyncMock, patch

@pytest.mark.asyncio
async def test_agent_with_mock_tool():
    with patch('mymodule.internet_search') as mock_search:
        mock_search.return_value = "Mocked results"
        agent = create_deep_agent(model="openai:gpt-5.4", tools=[internet_search])
        result = await agent.ainvoke({"messages": [{"role": "user", "content": "search"}]})
        assert mock_search.called
```

### 3. Teste de Estado com Checkpointer

```python
def test_checkpoint_state():
    checkpointer = MemorySaver()
    agent = create_deep_agent(model="openai:gpt-5.4", checkpointer=checkpointer)
    config = {"configurable": {"thread_id": "test"}}
    agent.invoke({"messages": [{"role": "user", "content": "Meu nome é Test"}]}, config=config)
    result = agent.invoke({"messages": [{"role": "user", "content": "Qual meu nome?"}]}, config=config)
    assert "Test" in result["messages"][-1].content
```

### 4. Time Travel com Checkpoints

```python
# Retornar a um checkpoint anterior para depurar
state = agent.get_state(config)
# state.values contém o estado no último checkpoint
```

### 5. LangSmith Tracing para Debug

```python
import os
os.environ["LANGCHAIN_TRACING_V2"] = "true"
os.environ["LANGCHAIN_API_KEY"] = "ls__..."
# Todos os runs são automaticamente traceados no LangSmith
```

### 6. Assertividade em Testes de Agente

```python
def test_agent_uses_correct_tool():
    agent = create_deep_agent(model="openai:gpt-5.4", tools=[calculator])
    result = agent.invoke({"messages": [{"role": "user", "content": "Quanto é 2+2?"}]})
    # Verificar que o tool_call foi feito
    tool_calls = [msg for msg in result["messages"] if hasattr(msg, 'tool_calls')]
    assert len(tool_calls) > 0
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_tool_invocation():
    @tool
    def greet(name: str) -> str:
        return f"Hello {name}"
    assert greet.invoke({"name": "World"}) == "Hello World"
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-testing-debugging.md --json
```

---

## 🔗 Referências Cruzadas
- [[deep-agents-core-customization.md]]
