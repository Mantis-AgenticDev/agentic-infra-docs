---
artifact_id: "graph-api-advanced"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/graph-api-advanced.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/graph-api-advanced.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:graph-api-advanced-v1"
generated_at: "2026-05-27T14:45:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["graph-api-fundamentals", "swarm-supervisor-patterns", "workflows-ceo"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks", "workflows-ceo"]
status: "🟢 Novo"
next_review: "2026-08-27"
---

# 🧩 Graph API Advanced — Múltiplos Esquemas, Overwrite, Caching e Recursion

> **Contrato modular**: Artefato filho do Master Agent. Implementa padrões avançados da Graph API: múltiplos schemas de estado, PrivateState, Overwrite, node caching e recursion limit proativo.

## 🎯 Propósito

Estender a Graph API com padrões para sistemas complexos: separação de Input/Output/Private state, bypass de reducers com `Overwrite`, cache de nós e gerenciamento proativo de recursion limit.

## 📋 Especificação (SDD)
- **Entradas**: Definições de InputState, OutputState, PrivateState, CachePolicy, RemainingSteps
- **Saídas**: Grafo compilado com múltiplos schemas, cache e recursion handling
- **Side Effects**: Criação de canais privados, logging de cache hits, métricas de recursion
- **Constraints Aplicáveis**: C1, C2, C3, C5, C7, C8
- **Dependências**: `langgraph`, `graph-api-fundamentals`

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
# 1. MÚLTIPLOS ESQUEMAS DE ESTADO
# ═══════════════════════════════════════════════════════════════════════════
from typing_extensions import TypedDict
from langgraph.graph import StateGraph, START, END

class InputState(TypedDict):
    user_input: str

class OutputState(TypedDict):
    graph_output: str

class OverallState(TypedDict):
    foo: str
    user_input: str
    graph_output: str

class PrivateState(TypedDict):
    bar: str

class MultiSchemaGraphBuilder:
    """Constrói grafos com Input/Output/Private schemas."""
    def __init__(self):
        self.builder = StateGraph(OverallState, input_schema=InputState, output_schema=OutputState)

    def add_nodes(self):
        def node_1(state: InputState) -> OverallState:
            return {"foo": state["user_input"] + " name"}
        def node_2(state: OverallState) -> PrivateState:
            return {"bar": state["foo"] + " is"}
        def node_3(state: PrivateState) -> OutputState:
            return {"graph_output": state["bar"] + " Agent"}

        self.builder.add_node("node_1", node_1)
        self.builder.add_node("node_2", node_2)
        self.builder.add_node("node_3", node_3)
        self.builder.add_edge(START, "node_1")
        self.builder.add_edge("node_1", "node_2")
        self.builder.add_edge("node_2", "node_3")
        self.builder.add_edge("node_3", END)
        return self

    def compile(self):
        graph = self.builder.compile()
        mantis_log("INFO", "multi_schema_graph_compiled")
        return graph

# ═══════════════════════════════════════════════════════════════════════════
# 2. OVERWRITE PARA BYPASS DE REDUCERS
# ═══════════════════════════════════════════════════════════════════════════
from langgraph.types import Overwrite
from typing import Annotated

class OverwriteState(TypedDict):
    messages: Annotated[list, add_messages]
    config: dict  # sem reducer → overwrite padrão

class OverwriteExample:
    """Demonstra uso de Overwrite para substituir listas sem reducer."""
    @staticmethod
    def build():
        builder = StateGraph(OverwriteState)

        def append_node(state: OverwriteState) -> dict:
            return {"messages": [AIMessage(content="Appended")]}

        def overwrite_node(state: OverwriteState) -> dict:
            # Usa Overwrite para substituir toda a lista
            return {"messages": Overwrite([HumanMessage(content="Reset")])}

        builder.add_node("append", append_node)
        builder.add_node("overwrite", overwrite_node)
        builder.add_edge(START, "append")
        builder.add_edge("append", "overwrite")
        builder.add_edge("overwrite", END)
        return builder.compile()

# ═══════════════════════════════════════════════════════════════════════════
# 3. NODE CACHING COM CACHEPOLICY
# ═══════════════════════════════════════════════════════════════════════════
from langgraph.types import CachePolicy
from langgraph.cache.memory import InMemoryCache
import hashlib, pickle

class CacheableGraph:
    """Grafo com suporte a cache de nós."""
    def __init__(self):
        self.cache = InMemoryCache()

    def build(self):
        class CacheState(TypedDict):
            x: int
            result: int

        builder = StateGraph(CacheState)

        def expensive_node(state: CacheState) -> dict:
            time.sleep(1)
            mantis_log("INFO", "expensive_computed", str(state["x"]))
            return {"result": state["x"] * 2}

        builder.add_node("expensive", expensive_node, cache_policy=CachePolicy(ttl=60))
        builder.set_entry_point("expensive")
        builder.set_finish_point("expensive")
        return builder.compile(cache=self.cache)

# ═══════════════════════════════════════════════════════════════════════════
# 4. RECURSION LIMIT PROATIVO COM REMAININGSTEPS
# ═══════════════════════════════════════════════════════════════════════════
from langgraph.managed import RemainingSteps
from langgraph.errors import GraphRecursionError

class RecursionAwareState(TypedDict):
    messages: Annotated[list, add_messages]
    remaining_steps: RemainingSteps

class RecursionAwareGraph:
    """Grafo que monitora e reage ao recursion limit."""
    def build(self):
        builder = StateGraph(RecursionAwareState)

        def agent_node(state: RecursionAwareState) -> dict:
            remaining = state["remaining_steps"]
            mantis_log("DEBUG", "recursion_check", f"Remaining={remaining}")
            if remaining <= 3:
                return {"messages": [AIMessage(content="Aproaching limit, wrapping up...")]}
            return {"messages": [AIMessage(content="Processing...")]}

        def router(state: RecursionAwareState) -> Literal["agent", END]:
            if state["remaining_steps"] <= 2:
                mantis_log("WARN", "recursion_fallback")
                return END
            return "agent"

        builder.add_node("agent", agent_node)
        builder.add_edge(START, "agent")
        builder.add_conditional_edges("agent", router)
        return builder.compile()

# ═══════════════════════════════════════════════════════════════════════════
# 5. METADATA DE EXECUÇÃO
# ═══════════════════════════════════════════════════════════════════════════
from langchain_core.runnables import RunnableConfig

class MetadataInspector:
    """Extrai e loga metadados de execução do grafo."""
    @staticmethod
    def log_metadata(config: RunnableConfig):
        metadata = config.get("metadata", {})
        mantis_log("INFO", "graph_metadata", json.dumps({
            "step": metadata.get("langgraph_step"),
            "node": metadata.get("langgraph_node"),
            "triggers": metadata.get("langgraph_triggers"),
            "path": metadata.get("langgraph_path"),
        }))
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from graph_api_advanced import (
    MultiSchemaGraphBuilder, OverwriteExample, CacheableGraph, RecursionAwareGraph
)

def test_multi_schema():
    builder = MultiSchemaGraphBuilder().add_nodes()
    graph = builder.compile()
    result = graph.invoke({"user_input": "My"})
    assert result["graph_output"] == "My name is Agent"

def test_overwrite():
    graph = OverwriteExample.build()
    result = graph.invoke({"messages": [HumanMessage(content="Original")]})
    assert result["messages"][-1].content == "Reset"

def test_cacheable_graph():
    graph = CacheableGraph().build()
    r1 = graph.invoke({"x": 5})
    r2 = graph.invoke({"x": 5})
    assert r1["result"] == 10
    assert r2["result"] == 10

def test_recursion_aware():
    graph = RecursionAwareGraph().build()
    result = graph.invoke({"messages": []}, {"recursion_limit": 5})
    assert len(result["messages"]) > 0
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/graph-api-advanced.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[graph-api-fundamentals.md]]
- [[swarm-supervisor-patterns.md]]
