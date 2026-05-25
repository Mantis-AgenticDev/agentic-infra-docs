---
artifact_id: "langchain-agents-orchestration"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/langchain-agents-orchestration.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/langchain-agents-orchestration.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:langchain-agents-orchestration-v1.0.0"
generated_at: "2026-05-26T17:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["langchain-chains-orchestration", "langchain-memory-systems"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-26"
---

# 🤖 LangChain Agents Orchestration – Agentes ReAct, Tool Calling e Execução

> **Contrato modular**: Artefato filho do Master Agent. Explora a criação e execução de agentes LangChain tradicionais: ReAct, Tool Calling, Conversational, Zero‑Shot e LangGraph ReAct Agent, com AgentExecutor e memória.

---

## 🎯 Propósito
Permitir que agentes MANTIS tradicionais utilizem ferramentas de forma autônoma, escolhendo quais invocar, com controle de iterações e capacidade de manter conversas com estado.

## 📋 Especificação (SDD)
- **Entradas**: Modelo LLM, lista de ferramentas, prompt do agente.
- **Saídas**: Agente configurado e executor (`AgentExecutor`).
- **Side Effects**: Chamadas a ferramentas externas.
- **Constraints Aplicáveis**: C1 (definição de ferramentas), C5 (formato de resposta), C7 (limite de iterações e retry), C8 (logs de execução), C9 (thread_id opcional).
- **Dependências**: `langchain.agents`, `langgraph.prebuilt`, `langchain_core.tools`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    import json, datetime, os
    def mantis_log(level, event, detail=""):
        entry = {"ts": datetime.datetime.utcnow().isoformat() + "Z", "level": level, "tenant": os.getenv("TENANT_ID", "global"), "event": event, "detail": detail, "trace_id": os.getenv("TRACE_ID", "null"), "span_id": os.getenv("SPAN_ID", "null"), "fallback": "true"}
        print(json.dumps(entry), flush=True)
```

### 1. Definição de Ferramentas

```python
from langchain_core.tools import tool

@tool
def search_tool(query: str) -> str:
    """Busca informações na web."""
    return f"Resultados para: {query}"

@tool
def calculator_tool(expression: str) -> str:
    """Avalia uma expressão matemática."""
    try:
        return str(eval(expression))
    except:
        return "Expressão inválida"

tools = [search_tool, calculator_tool]
```

### 2. Agente ReAct com AgentExecutor

```python
from langchain.agents import create_react_agent, AgentExecutor
from langchain import hub

prompt = hub.pull("hwchase17/react")
agent = create_react_agent(ChatOpenAI(model="gpt-4o-mini"), tools, prompt)

executor = AgentExecutor(
    agent=agent,
    tools=tools,
    verbose=True,
    max_iterations=5,
    handle_parsing_errors=True,
)

result = executor.invoke({"input": "Quanto é 25 * 4? E busque o significado desse número."})
mantis_log("INFO", "agent_result", result["output"])
```

### 3. Agente Tool Calling (OpenAI Functions)

```python
from langchain.agents import create_tool_calling_agent

prompt = ChatPromptTemplate.from_messages([
    ("system", "Você é um assistente útil."),
    ("human", "{input}"),
    MessagesPlaceholder("agent_scratchpad"),
])

agent = create_tool_calling_agent(llm, tools, prompt)
executor = AgentExecutor(agent=agent, tools=tools, verbose=True)
result = executor.invoke({"input": "Calcule 15% de 85"})
```

### 4. Agente LangGraph ReAct (Moderno)

```python
from langgraph.prebuilt import create_react_agent
from langgraph.checkpoint.memory import MemorySaver

memory = MemorySaver()
agent = create_react_agent(llm, tools, checkpointer=memory)

config = {"configurable": {"thread_id": "user-123"}}
for chunk in agent.stream(
    {"messages": [("user", "Busque LangChain e calcule 2+2")]},
    config=config,
    stream_mode="values"
):
    chunk["messages"][-1].pretty_print()
```

### 5. Agente Conversacional com Memória

```python
from langchain.agents import create_conversational_retrieval_agent
from langchain.memory import ConversationBufferMemory

memory = ConversationBufferMemory(memory_key="chat_history", return_messages=True)
conversational_agent = create_conversational_retrieval_agent(llm, tools, verbose=True)

result1 = conversational_agent.invoke({"input": "Meu nome é Alice"})
result2 = conversational_agent.invoke({"input": "Qual é o meu nome?"})
```

### 6. Agente Zero‑Shot (Legado)

```python
from langchain.agents import initialize_agent, AgentType, load_tools

tools = load_tools(["serpapi", "llm-math"], llm=llm)
agent = initialize_agent(tools, llm, agent=AgentType.ZERO_SHOT_REACT_DESCRIPTION, verbose=True, max_iterations=3)
result = agent.run("Qual é a população de Tóquio e esse número dividido por 2?")
```

### 7. Structured Chat Agent

```python
from langchain.agents import create_structured_chat_agent
from pydantic import BaseModel, Field

class SearchInput(BaseModel):
    query: str = Field(description="Consulta de busca")
    max_results: int = Field(default=5, description="Máximo de resultados")

@tool(args_schema=SearchInput)
def structured_search(query: str, max_results: int = 5) -> str:
    return f"Encontrados {max_results} resultados para: {query}"

prompt = hub.pull("hwchase17/structured-chat-agent")
agent = create_structured_chat_agent(llm, [structured_search], prompt)
executor = AgentExecutor(agent=agent, tools=[structured_search], verbose=True)
```

### 8. Troubleshooting de Agentes

```python
# ❌ Muitas iterações → aumentar max_iterations ou melhorar o prompt.
# ❌ Ferramenta não encontrada → verificar se o nome coincide.
# ❌ Erro de parsing → usar handle_parsing_errors=True.
# ❌ Missing agent_scratchpad → adicionar MessagesPlaceholder("agent_scratchpad").
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_react_agent_creation():
    prompt = hub.pull("hwchase17/react")
    agent = create_react_agent(ChatOpenAI(model="gpt-4o-mini"), [calculator_tool], prompt)
    assert agent is not None

def test_agent_executor():
    agent = create_react_agent(ChatOpenAI(model="gpt-4o-mini"), [calculator_tool], hub.pull("hwchase17/react"))
    executor = AgentExecutor(agent=agent, tools=[calculator_tool], max_iterations=1)
    result = executor.invoke({"input": "2+2"})
    assert result["output"] is not None
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/langchain-agents-orchestration.md --json
```

---

## 🔗 Referências Cruzadas
- [[langchain-chains-orchestration.md]]
- [[langchain-memory-systems.md]]
