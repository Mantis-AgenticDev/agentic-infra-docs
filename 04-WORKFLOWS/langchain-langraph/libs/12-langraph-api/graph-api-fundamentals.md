---
artifact_id: "graph-api-fundamentals"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/graph-api-fundamentals.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/graph-api-fundamentals.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:graph-api-fundamentals-v1"
generated_at: "2026-05-27T14:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: true
  required_for: ["graph-api-advanced", "graph-vs-functional-decision", "swarm-fundamentals", "supervisor-fundamentals", "workflows-ceo"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks", "workflows-ceo"]
status: "🟢 Novo"
next_review: "2026-08-27"
---

# 🧩 Graph API Fundamentals — Construção de Workflows com StateGraph

> **Contrato modular**: Artefato filho do Master Agent. Implementa os fundamentos da Graph API do LangGraph: State, Nodes, Edges, StateGraph, compilação, reducers, MessagesState, Command, Send e runtime context.

## 🎯 Propósito

Fornecer uma biblioteca de construção de grafos que encapsula a criação de `StateGraph`, definição de `State` com reducers, adição de nós e arestas, compilação com checkpointer, e uso de `Command` e `Send` para controle de fluxo avançado.

## 📋 Especificação (SDD)
- **Entradas**: Definição de State (TypedDict/Pydantic/dataclass), funções de nó, funções de roteamento, checkpointer, context_schema
- **Saídas**: Grafo compilado (`CompiledStateGraph`) pronto para execução
- **Side Effects**: Criação de checkpoints, logging de execução, validação de estrutura
- **Constraints Aplicáveis**: C1 (Resiliência), C2 (Validação), C3 (Segurança), C5 (Integridade), C7 (Versionamento), C8 (Observabilidade)
- **Dependências**: `langgraph`, `langchain-core`, `pydantic`, `typing-extensions`

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from langchain_langraph_master_agent import mantis_log
except ImportError:
    import json, datetime, os
    def mantis_log(level, event, detail=""):
        entry = {
            "ts": datetime.datetime.utcnow().isoformat() + "Z",
            "level": level,
            "tenant": os.getenv("TENANT_ID", "global"),
            "event": event,
            "detail": detail,
            "trace_id": os.getenv("TRACE_ID", "null"),
            "span_id": os.getenv("SPAN_ID", "null"),
            "fallback": "true"
        }
        print(json.dumps(entry), flush=True)
    mantis_log("WARN", "bootstrap_fallback", "Master Agent langchain-langraph não encontrado.")
```

```python
# ═══════════════════════════════════════════════════════════════════════════
# 1. DEFINIÇÃO DE STATE (TIPOS E REDUCERS)
# ═══════════════════════════════════════════════════════════════════════════
from typing import Annotated, Any, Optional, Union, Literal, get_type_hints
from typing_extensions import TypedDict
from dataclasses import dataclass, field
from operator import add
import pydantic
from pydantic import BaseModel, Field

from langchain_core.messages import AnyMessage, HumanMessage, AIMessage, ToolMessage
from langgraph.graph.message import add_messages

# --- TypedDict State (recomendado) ---
class BasicState(TypedDict):
    """Estado mínimo com chave de mensagens."""
    messages: Annotated[list[AnyMessage], add_messages]

class ExtendedState(TypedDict):
    """Estado com campos adicionais."""
    messages: Annotated[list[AnyMessage], add_messages]
    user_id: str
    documents: list[str]
    retry_count: int

# --- Dataclass State (com defaults) ---
@dataclass
class DataclassState:
    messages: Annotated[list[AnyMessage], add_messages] = field(default_factory=list)
    user_id: str = "anonymous"
    retry_count: int = 0

# --- Pydantic State (com validação) ---
class PydanticState(BaseModel):
    messages: Annotated[list[AnyMessage], add_messages] = Field(default_factory=list)
    user_id: str = "anonymous"
    score: float = Field(ge=0.0, le=1.0, default=0.5)

# --- MessagesState (prebuilt) ---
from langgraph.graph import MessagesState

class CustomMessagesState(MessagesState):
    """Extende MessagesState com campos adicionais."""
    documents: list[str]
    metadata: dict

# ═══════════════════════════════════════════════════════════════════════════
# 2. FÁBRICA DE STATEGRAPH (BUILDER PATTERN)
# ═══════════════════════════════════════════════════════════════════════════
from langgraph.graph import StateGraph, START, END
from langgraph.checkpoint.base import BaseCheckpointSaver
from langgraph.checkpoint.memory import InMemorySaver
from langgraph.types import Command, Send, RetryPolicy
from langgraph.runtime import Runtime

class GraphBuilder:
    """Construtor fluente para StateGraph."""
    def __init__(self, state_schema: type, context_schema: Optional[type] = None):
        self.builder = StateGraph(state_schema, context_schema=context_schema)
        self._checkpointer: Optional[BaseCheckpointSaver] = None
        self._nodes: dict[str, Any] = {}
        self._edges: list[tuple] = []
        self._conditional_edges: list[tuple] = []
        self._entry_point: Optional[str] = None
        self._finish_point: Optional[str] = None

    def add_node(self, name: str, func: callable, cache_policy: Optional[Any] = None) -> "GraphBuilder":
        if cache_policy:
            self.builder.add_node(name, func, cache_policy=cache_policy)
        else:
            self.builder.add_node(name, func)
        self._nodes[name] = func
        mantis_log("DEBUG", "graph_node_added", name)
        return self

    def add_edge(self, from_node: str, to_node: str) -> "GraphBuilder":
        self.builder.add_edge(from_node, to_node)
        self._edges.append((from_node, to_node))
        return self

    def add_conditional_edges(self, source: str, condition: callable, path_map: Optional[dict] = None) -> "GraphBuilder":
        if path_map:
            self.builder.add_conditional_edges(source, condition, path_map)
        else:
            self.builder.add_conditional_edges(source, condition)
        self._conditional_edges.append((source, condition, path_map))
        return self

    def set_entry_point(self, node: str) -> "GraphBuilder":
        self._entry_point = node
        return self

    def set_finish_point(self, node: str) -> "GraphBuilder":
        self._finish_point = node
        return self

    def with_checkpointer(self, checkpointer: BaseCheckpointSaver) -> "GraphBuilder":
        self._checkpointer = checkpointer
        return self

    def compile(self):
        if self._entry_point:
            self.builder.add_edge(START, self._entry_point)
        if self._finish_point:
            self.builder.add_edge(self._finish_point, END)
        graph = self.builder.compile(checkpointer=self._checkpointer)
        mantis_log("INFO", "graph_compiled", f"Nodes={len(self._nodes)}, Checkpointer={self._checkpointer is not None}")
        return graph

# ═══════════════════════════════════════════════════════════════════════════
# 3. NODES PADRÃO (FUNÇÕES DE EXEMPLO)
# ═══════════════════════════════════════════════════════════════════════════
def create_llm_node(model_name: str = "deepseek-chat"):
    """Cria um nó que chama um LLM."""
    from langchain.chat_models import init_chat_model
    model = init_chat_model(model_name, model_provider="deepseek", temperature=0.05)

    def llm_node(state: BasicState) -> dict:
        response = model.invoke(state["messages"])
        mantis_log("DEBUG", "llm_node_called", f"Messages={len(state['messages'])}")
        return {"messages": [response]}

    return llm_node

def create_conditional_router(conditions: dict[str, callable]) -> callable:
    """Cria uma função de roteamento condicional baseada em predicados."""
    def router(state: dict) -> str:
        for route_name, predicate in conditions.items():
            if predicate(state):
                mantis_log("DEBUG", "router_decision", route_name)
                return route_name
        return list(conditions.keys())[-1]  # fallback
    return router

# ═══════════════════════════════════════════════════════════════════════════
# 4. COMMAND PARA CONTROLE DE FLUXO
# ═══════════════════════════════════════════════════════════════════════════
class CommandFactory:
    """Fábrica de objetos Command para navegação e atualização de estado."""

    @staticmethod
    def goto(next_node: str, update: Optional[dict] = None) -> Command:
        return Command(goto=next_node, update=update or {})

    @staticmethod
    def resume(value: Any) -> Command:
        return Command(resume=value)

    @staticmethod
    def goto_parent(next_node: str, update: Optional[dict] = None) -> Command:
        return Command(goto=next_node, graph=Command.PARENT, update=update or {})

    @staticmethod
    def update_only(update: dict) -> Command:
        return Command(update=update)

# ═══════════════════════════════════════════════════════════════════════════
# 5. SEND PARA MAP-REDUCE
# ═══════════════════════════════════════════════════════════════════════════
class SendFactory:
    """Fábrica de objetos Send para processamento paralelo."""
    @staticmethod
    def create_sends(node: str, items: list[dict]) -> list[Send]:
        return [Send(node, item) for item in items]

# ═══════════════════════════════════════════════════════════════════════════
# 6. RUNTIME CONTEXT
# ═══════════════════════════════════════════════════════════════════════════
@dataclass
class MantisContext:
    tenant_id: str = "global"
    model_provider: str = "deepseek"
    trace_id: str = "null"

def create_context_aware_node(func: callable):
    """Wrapper que injeta runtime context em um nó."""
    def wrapped(state: dict, runtime: Runtime[MantisContext]) -> dict:
        mantis_log("DEBUG", "context_node", f"Tenant={runtime.context.tenant_id}")
        return func(state, runtime)
    return wrapped

# ═══════════════════════════════════════════════════════════════════════════
# 7. EXEMPLO COMPLETO: AGENTE COM ROTEAMENTO CONDICIONAL
# ═══════════════════════════════════════════════════════════════════════════
class AgentGraphExample:
    """Constrói um agente completo com Graph API."""
    def __init__(self, model_name: str = "deepseek-chat"):
        self.model_name = model_name

    def build(self) -> GraphBuilder:
        builder = GraphBuilder(BasicState)
        # Nó LLM
        llm_node = create_llm_node(self.model_name)
        builder.add_node("llm", llm_node)
        # Nó de ferramentas
        def tool_node(state: BasicState) -> dict:
            return {"messages": [ToolMessage(content="Tool executed", tool_call_id="1")]}
        builder.add_node("tools", tool_node)
        # Roteamento
        def should_continue(state: BasicState) -> Literal["tools", END]:
            last_msg = state["messages"][-1]
            if hasattr(last_msg, "tool_calls") and last_msg.tool_calls:
                return "tools"
            return END
        builder.add_conditional_edges("llm", should_continue)
        builder.add_edge("tools", "llm")
        builder.set_entry_point("llm")
        builder.with_checkpointer(InMemorySaver())
        return builder.compile()
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from graph_api_fundamentals import (
    BasicState, ExtendedState, GraphBuilder, CommandFactory, SendFactory,
    create_llm_node, create_conditional_router, AgentGraphExample
)
from langgraph.checkpoint.memory import InMemorySaver
from langchain_core.messages import HumanMessage, AIMessage

def test_state_definition():
    state: BasicState = {"messages": [HumanMessage(content="Hi")]}
    assert len(state["messages"]) == 1

def test_graph_builder_compile():
    builder = GraphBuilder(BasicState)
    builder.add_node("llm", create_llm_node())
    builder.set_entry_point("llm")
    graph = builder.compile()
    assert graph is not None

def test_command_goto():
    cmd = CommandFactory.goto("next_node", {"key": "value"})
    assert cmd.goto == "next_node"
    assert cmd.update == {"key": "value"}

def test_send_factory():
    sends = SendFactory.create_sends("process", [{"id": 1}, {"id": 2}])
    assert len(sends) == 2
    assert sends[0].node == "process"

def test_agent_graph_example():
    agent = AgentGraphExample()
    graph = agent.build()
    result = graph.invoke({"messages": [HumanMessage(content="Hello")]})
    assert "messages" in result
    assert len(result["messages"]) > 0
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/graph-api-fundamentals.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[graph-api-advanced.md]]
- [[graph-vs-functional-decision.md]]
- [[langgraph-state-graph-fundamentals.md]]
