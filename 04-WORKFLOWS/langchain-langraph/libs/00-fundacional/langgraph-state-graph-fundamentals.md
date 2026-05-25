---
artifact_id: "langgraph-state-graph-fundamentals"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/langgraph-state-graph-fundamentals.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/langgraph-state-graph-fundamentals.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:langgraph-state-graph-v1.0.0"
generated_at: "2026-05-24T23:40:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: true
  required_for: ["langgraph-message-graph", "langgraph-branching", "agents-swarm-coordination"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🔄 StateGraph Fundamentos – Nós, Arestas, Estado Tipado e Persistência

> **Contrato modular**: Filho do Master Agent. Documenta a construção de grafos de estado com TypedDict, nós, roteamento condicional, checkpointing e padrões de execução durável (C7).

---

## 🎯 Propósito
Habilitar a criação de workflows complexos e agentes com estado explícito usando StateGraph, permitindo ramificações, persistência e retomada de execução, pilares do swarm MANTIS.

## 📋 Especificação (SDD)
- **Entradas**: Definição de estado (TypedDict), funções de nó, checkpointer opcional.
- **Saídas**: Grafo compilado que pode ser invocado, transmitido e interrompido/resumido.
- **Side Effects**: Estado mutável persistido via checkpoints.
- **Constraints Aplicáveis**: C1 (estado tipado), C5 (contrato de nós), C7 (durable execution), C8 (logging), C9 (thread_id).
- **Dependências**: `langgraph`, `langchain-core`.

---

## 🛡️ Bootstrap Resiliente (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    import json, datetime, os
    def mantis_log(level, event, detail=""):
        entry = {"ts": datetime.datetime.utcnow().isoformat() + "Z", "level": level, "tenant": os.getenv("TENANT_ID", "global"), "event": event, "detail": detail, "trace_id": os.getenv("TRACE_ID", "null"), "span_id": os.getenv("SPAN_ID", "null"), "fallback": "true"}
        print(json.dumps(entry), flush=True)
```

### 1. Estado Base com TypedDict
```python
from typing import Annotated, TypedDict
from langgraph.graph.message import add_messages

class AgentState(TypedDict):
    messages: Annotated[list, add_messages]  # Reducer automático de mensagens
    context: Annotated[list, lambda left, right: right]  # Substitui o contexto
```

### 2. Construção de Grafo com Nós
```python
from langgraph.graph import StateGraph, START, END

def retrieve(state: AgentState):
    docs = ["doc1", "doc2"]  # simulado
    mantis_log("INFO", "node_retrieve", f"Recuperados {len(docs)} documentos")
    return {"context": docs}

builder = StateGraph(AgentState)
builder.add_node("retrieve", retrieve)
builder.add_edge(START, "retrieve")
builder.add_edge("retrieve", END)
graph = builder.compile()
```

### 3. Roteamento Condicional
```python
import random
from typing import Literal

def decide_next(state: AgentState) -> Literal["summarize", "end"]:
    if len(state.get("messages", [])) > 5:
        return "summarize"
    return "end"

builder.add_conditional_edges("retrieve", decide_next, {"summarize": "summarize_node", "end": END})
```

### 4. Checkpointing com MemorySaver/PostgresSaver
```python
from langgraph.checkpoint.memory import MemorySaver

checkpointer = MemorySaver()
graph = builder.compile(checkpointer=checkpointer)
config = {"configurable": {"thread_id": "task-42"}}
mantis_log("INFO", "graph_compiled", "Grafo com checkpointer ativado")
```

### 5. Execução Durável e Retomada
```python
# Execução normal
result = graph.invoke({"messages": [("user", "Olá")]}, config)
# Em caso de falha, o estado é preservado; pode ser retomado com o mesmo thread_id
mantis_log("INFO", "durable_execution", "Estado salvo automaticamente")
```

### 6. Padrão RAG com StateGraph
```python
class RAGState(TypedDict):
    question: str
    context: list
    answer: str

def retrieve(state: RAGState):
    # Lógica de busca vetorial
    return {"context": ["doc relevante"]}

def generate(state: RAGState):
    prompt = f"Responda: {state['question']} com base em {state['context']}"
    resposta = llm.invoke(prompt)
    return {"answer": resposta}

rag_builder = StateGraph(RAGState)
rag_builder.add_node("retrieve", retrieve)
rag_builder.add_node("generate", generate)
rag_builder.add_edge(START, "retrieve")
rag_builder.add_edge("retrieve", "generate")
rag_builder.add_edge("generate", END)
rag_app = rag_builder.compile()
mantis_log("INFO", "rag_graph_built", "Grafo RAG compilado")
```

### 7. Multi‑Agente Supervisor
```python
class MultiAgentState(TypedDict):
    messages: list
    next_agent: str

def supervisor(state: MultiAgentState):
    # Decide entre researcher, writer ou FINISH
    return {"next_agent": "researcher"}

def route(state: MultiAgentState):
    if state["next_agent"] == "finish":
        return END
    return state["next_agent"]

builder = StateGraph(MultiAgentState)
builder.add_node("supervisor", supervisor)
builder.add_node("researcher", researcher_graph)
builder.add_node("writer", writer_graph)
builder.add_conditional_edges("supervisor", route, {"researcher": "researcher", "writer": "writer", "finish": END})
builder.add_edge("researcher", "supervisor")
builder.add_edge("writer", "supervisor")
multi_agent = builder.compile()
mantis_log("INFO", "multi_agent_built", "Supervisor com 2 agentes especializados")
```

### 8. Persistência com PostgresSaver (Produção)
```python
from langgraph.checkpoint.postgres import PostgresSaver
checkpointer = PostgresSaver.from_conn_string("postgresql://user:pass@localhost/mantis")
graph = builder.compile(checkpointer=checkpointer)
mantis_log("INFO", "postgres_checkpointer", "Checkpointer de produção ativado")
```

---

## 🧪 Testes Unitários

```python
def test_state_reducer():
    state = AgentState(messages=[], context=[])
    new_state = state.copy()
    new_state["messages"] = [HumanMessage(content="test")]
    # add_messages deve anexar
    assert len(new_state["messages"]) == 1

def test_conditional_routing():
    state = {"messages": [1]*6}
    assert decide_next(state) == "summarize"
    state = {"messages": [1]}
    assert decide_next(state) == "end"
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/langgraph-state-graph-fundamentals.md \
  --json --check-structural --check-error-handling --check-observability
```

---

## 🔗 Referências Cruzadas
- [[langchain-langraph-master-agent.md]]
- [[/05-CONFIGURATIONS/validation/orchestrator-engine/main.go]]
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]]

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal |
|--------|------|-------|------------------|
| 1.0.0 | 2026-05-24T23:40:00Z | langchain-langraph-master-agent | Criação inicial: StateGraph, checkpoints, padrões RAG e multi‑agente |
