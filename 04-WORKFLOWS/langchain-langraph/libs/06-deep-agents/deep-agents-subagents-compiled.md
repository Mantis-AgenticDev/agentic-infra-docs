---
artifact_id: "deep-agents-subagents-compiled"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-subagents-compiled.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-subagents-compiled.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-subagents-compiled-v1.0.0"
generated_at: "2026-05-25T23:15:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-subagents-advanced"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🧩 Deep Agents – CompiledSubAgent e Grafos Customizados

> **Contrato modular**: Artefato filho do Master Agent. Explora o uso de `CompiledSubAgent` para criar subagentes com grafos LangGraph customizados, incluindo integração com `create_agent` e padrões StateGraph.

---

## 🎯 Propósito
Permitir que agentes MANTIS usem grafos LangGraph arbitrários como subagentes, maximizando a flexibilidade e o reuso de componentes.

## 📋 Especificação (SDD)
- **Entradas**: Grafo LangGraph compilado, especificação do subagente.
- **Saídas**: Subagente integrado ao agente principal.
- **Side Effects**: Execução de grafos customizados.
- **Constraints Aplicáveis**: C1 (contrato de Runnable), C3 (isolamento), C5 (schema de estado), C7 (falha isolada), C8 (tracing), C9 (trace_id).
- **Dependências**: `langgraph`, `langchain.agents`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. CompiledSubAgent com `create_agent`

```python
from deepagents import create_deep_agent, CompiledSubAgent
from langchain.agents import create_agent

custom_graph = create_agent(
    model="openai:gpt-5.4",
    tools=[specialized_tool],
    prompt="Você é um agente especializado em análise de dados.",
)

compiled_subagent = CompiledSubAgent(
    name="data-analyzer",
    description="Analisa dados complexos e retorna insights.",
    runnable=custom_graph,
)

agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    subagents=[compiled_subagent],
)
```

### 2. Grafo Customizado com StateGraph

```python
from langgraph.graph import StateGraph, MessagesState, START, END
from langgraph.prebuilt import ToolNode, tools_condition
from typing import TypedDict, Annotated

class CustomState(MessagesState):
    analysis_results: list
    current_stage: str

def build_custom_graph(tools, model):
    def call_model(state: CustomState):
        response = model.bind_tools(tools).invoke(state["messages"])
        return {"messages": response}

    def analyze_results(state: CustomState):
        results = [m for m in state["messages"] if hasattr(m, 'tool_calls')]
        return {"analysis_results": results, "current_stage": "done"}

    builder = StateGraph(CustomState)
    builder.add_node("call_model", call_model)
    builder.add_node("tools", ToolNode(tools))
    builder.add_node("analyze", analyze_results)
    builder.add_edge(START, "call_model")
    builder.add_conditional_edges("call_model", tools_condition)
    builder.add_edge("tools", "call_model")
    builder.add_edge("call_model", "analyze")
    builder.add_edge("analyze", END)
    return builder.compile()

graph = build_custom_graph([fetch_data, clean_data], model)
subagent = CompiledSubAgent(name="processor", description="Processa dados", runnable=graph)
```

### 3. Requisitos do Grafo para Subagente

```python
# O grafo DEVE ter uma chave de estado chamada "messages"
# para que o SubAgentMiddleware possa injetar e extrair mensagens.

class ValidSubagentState(TypedDict):
    messages: Annotated[list, add_messages]  # Obrigatório
    custom_field: str  # Opcional
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_compiled_subagent():
    graph = create_agent(model="openai:gpt-5.4", tools=[], prompt="Test")
    sub = CompiledSubAgent(name="test", description="test", runnable=graph)
    assert sub.name == "test"
    assert sub.runnable is not None
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-subagents-compiled.md --json
```

---

## 🔗 Referências Cruzadas
- [[deep-agents-subagents-advanced.md]]
