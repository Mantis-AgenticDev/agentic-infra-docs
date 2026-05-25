---
artifact_id: "streaming-api-fundamentals"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/streaming-api-fundamentals.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/streaming-api-fundamentals.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:streaming-api-fundamentals-v1"
generated_at: "2026-05-27T16:15:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["streaming-api-advanced", "graph-api-fundamentals", "functional-api-fundamentals", "workflows-ceo"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks", "workflows-ceo"]
status: "🟢 Novo"
next_review: "2026-08-27"
---

# 🧩 Streaming API Fundamentals — Stream Modes, v2 Format e Filtros

> **Contrato modular**: Artefato filho do Master Agent. Implementa a API de streaming do LangGraph: modos `values`, `updates`, `messages`, `custom`, formato v2 com `StreamPart`, e filtros por tags e nodos.

## 🎯 Propósito

Fornecer uma biblioteca de streaming completa que encapsula todos os modos de stream do LangGraph, o novo formato unificado v2, e utilitários de filtro para construir UIs reativas e sistemas de monitoramento em tempo real.

## 📋 Especificação (SDD)
- **Entradas**: Grafo compilado, input, config, lista de `stream_mode`, `version="v2"`
- **Saídas**: Iterator de `StreamPart` tipados, com `type`, `ns` e `data`
- **Side Effects**: Emissão de tokens LLM, atualizações de estado, dados customizados
- **Constraints Aplicáveis**: C1, C2, C5, C8
- **Dependências**: `langgraph`, `langchain-core`

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
# 1. STREAM PART TYPES (FORMATO v2)
# ═══════════════════════════════════════════════════════════════════════════
from typing import TypedDict, Union, Literal, Any, Optional, Iterator, AsyncIterator
from langgraph.types import (
    StreamPart,
    ValuesStreamPart,
    UpdatesStreamPart,
    MessagesStreamPart,
    CustomStreamPart,
    CheckpointStreamPart,
    TasksStreamPart,
    DebugStreamPart,
)
from langgraph.pregel import Pregel

class StreamMode:
    VALUES = "values"
    UPDATES = "updates"
    MESSAGES = "messages"
    CUSTOM = "custom"
    CHECKPOINTS = "checkpoints"
    TASKS = "tasks"
    DEBUG = "debug"

# ═══════════════════════════════════════════════════════════════════════════
# 2. STREAMER UNIFICADO COM V2
# ═══════════════════════════════════════════════════════════════════════════
class UnifiedStreamer:
    """Encapsula todos os modos de streaming com formato v2."""
    def __init__(self, graph: Pregel):
        self.graph = graph

    def stream(
        self,
        inputs: dict,
        config: Optional[dict] = None,
        stream_modes: List[str] = None,
        subgraphs: bool = False,
    ) -> Iterator[StreamPart]:
        """Stream síncrono com formato v2."""
        modes = stream_modes or [StreamMode.UPDATES]
        for chunk in self.graph.stream(
            inputs,
            config=config,
            stream_mode=modes,
            version="v2",
            subgraphs=subgraphs,
        ):
            mantis_log("DEBUG", "stream_chunk", f"Type={chunk['type']}")
            yield chunk

    async def astream(
        self,
        inputs: dict,
        config: Optional[dict] = None,
        stream_modes: List[str] = None,
        subgraphs: bool = False,
    ) -> AsyncIterator[StreamPart]:
        """Stream assíncrono com formato v2."""
        modes = stream_modes or [StreamMode.UPDATES]
        async for chunk in self.graph.astream(
            inputs,
            config=config,
            stream_mode=modes,
            version="v2",
            subgraphs=subgraphs,
        ):
            yield chunk

# ═══════════════════════════════════════════════════════════════════════════
# 3. FILTROS DE STREAM
# ═══════════════════════════════════════════════════════════════════════════
class StreamFilter:
    """Filtros para processar chunks de stream por tipo, nodo e tags."""

    @staticmethod
    def by_type(chunk: StreamPart, expected_type: str) -> bool:
        return chunk["type"] == expected_type

    @staticmethod
    def by_node(chunk: StreamPart, node_name: str) -> bool:
        if chunk["type"] == StreamMode.MESSAGES:
            _, metadata = chunk["data"]
            return metadata.get("langgraph_node") == node_name
        if chunk["type"] == StreamMode.UPDATES:
            return node_name in chunk["data"]
        return False

    @staticmethod
    def by_tag(chunk: StreamPart, tag: str) -> bool:
        if chunk["type"] == StreamMode.MESSAGES:
            _, metadata = chunk["data"]
            return tag in metadata.get("tags", [])
        return False

    @staticmethod
    def by_namespace(chunk: StreamPart, ns: tuple) -> bool:
        return chunk.get("ns", ()) == ns

class StreamCollector:
    """Coleta e categoriza chunks de stream."""
    def __init__(self):
        self.values = []
        self.updates = []
        self.messages = []
        self.custom = []
        self.checkpoints = []
        self.tasks = []
        self.debug = []

    def collect(self, chunk: StreamPart):
        chunk_type = chunk["type"]
        if chunk_type == StreamMode.VALUES:
            self.values.append(chunk["data"])
        elif chunk_type == StreamMode.UPDATES:
            self.updates.append(chunk["data"])
        elif chunk_type == StreamMode.MESSAGES:
            self.messages.append(chunk["data"])
        elif chunk_type == StreamMode.CUSTOM:
            self.custom.append(chunk["data"])
        elif chunk_type == StreamMode.CHECKPOINTS:
            self.checkpoints.append(chunk["data"])
        elif chunk_type == StreamMode.TASKS:
            self.tasks.append(chunk["data"])
        elif chunk_type == StreamMode.DEBUG:
            self.debug.append(chunk["data"])

    def get_last_message_content(self) -> Optional[str]:
        for msg_tuple in reversed(self.messages):
            msg, _ = msg_tuple
            if hasattr(msg, "content") and msg.content:
                return msg.content
        return None

# ═══════════════════════════════════════════════════════════════════════════
# 4. STREAMING DE LLM TOKENS (MESSAGES MODE)
# ═══════════════════════════════════════════════════════════════════════════
class LLMTokenStreamer:
    """Streamer especializado para tokens de LLM com filtros."""
    def __init__(self, graph: Pregel):
        self.graph = graph

    def stream_tokens(
        self,
        inputs: dict,
        config: Optional[dict] = None,
        filter_node: Optional[str] = None,
        filter_tag: Optional[str] = None,
        exclude_nostream: bool = True,
    ) -> Iterator[str]:
        """Stream de tokens com filtros opcionais."""
        for chunk in self.graph.stream(
            inputs,
            config=config,
            stream_mode=StreamMode.MESSAGES,
            version="v2",
        ):
            if chunk["type"] != StreamMode.MESSAGES:
                continue
            msg, metadata = chunk["data"]

            if exclude_nostream and "nostream" in metadata.get("tags", []):
                continue
            if filter_node and metadata.get("langgraph_node") != filter_node:
                continue
            if filter_tag and filter_tag not in metadata.get("tags", []):
                continue

            if hasattr(msg, "content") and msg.content:
                mantis_log("DEBUG", "llm_token", f"Node={metadata.get('langgraph_node')}, Tag={metadata.get('tags')}")
                yield msg.content

# ═══════════════════════════════════════════════════════════════════════════
# 5. CUSTOM STREAMING
# ═══════════════════════════════════════════════════════════════════════════
from langgraph.config import get_stream_writer

def create_custom_stream_node(func: callable):
    """Wrapper que injeta stream writer para dados customizados."""
    def wrapped(state: dict):
        writer = get_stream_writer()
        mantis_log("DEBUG", "custom_stream_writer_ready")
        return func(state, writer)
    return wrapped

# ═══════════════════════════════════════════════════════════════════════════
# 6. EXEMPLO COMPLETO: GRAFO COM MÚLTIPLOS MODOS DE STREAM
# ═══════════════════════════════════════════════════════════════════════════
class StreamingExampleGraph:
    """Grafo de exemplo que demonstra todos os modos de stream."""
    def __init__(self):
        from langgraph.graph import StateGraph, START, END
        from typing import TypedDict
        from langchain.chat_models import init_chat_model

        self.model = init_chat_model("deepseek-chat", model_provider="deepseek", temperature=0.05)

        class JokeState(TypedDict):
            topic: str
            joke: str

        def generate_joke(state: JokeState):
            writer = get_stream_writer()
            writer({"status": "Generating joke..."})
            response = self.model.invoke([{"role": "user", "content": f"Tell a joke about {state['topic']}"}])
            return {"joke": response.content}

        builder = StateGraph(JokeState)
        builder.add_node("generate_joke", generate_joke)
        builder.add_edge(START, "generate_joke")
        builder.add_edge("generate_joke", END)
        self.graph = builder.compile()

    def run_demo(self):
        streamer = UnifiedStreamer(self.graph)
        collector = StreamCollector()
        for chunk in streamer.stream(
            {"topic": "programming"},
            stream_modes=[StreamMode.UPDATES, StreamMode.CUSTOM, StreamMode.MESSAGES],
        ):
            collector.collect(chunk)
        return {
            "updates_count": len(collector.updates),
            "custom_count": len(collector.custom),
            "messages_count": len(collector.messages),
        }
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from streaming_api_fundamentals import (
    UnifiedStreamer, StreamFilter, StreamCollector, LLMTokenStreamer,
    StreamingExampleGraph, StreamMode
)

def test_stream_filter_by_type():
    chunk = {"type": "values", "ns": (), "data": {"key": "val"}}
    assert StreamFilter.by_type(chunk, "values")
    assert not StreamFilter.by_type(chunk, "updates")

def test_stream_collector():
    collector = StreamCollector()
    collector.collect({"type": "values", "ns": (), "data": {"foo": "bar"}})
    collector.collect({"type": "updates", "ns": (), "data": {"node": {"key": "val"}}})
    assert len(collector.values) == 1
    assert len(collector.updates) == 1

def test_example_graph():
    graph = StreamingExampleGraph()
    result = graph.run_demo()
    assert result["updates_count"] > 0
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/streaming-api-fundamentals.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[streaming-api-advanced.md]]
- [[graph-api-fundamentals.md]]
- [[functional-api-fundamentals.md]]
