
---
artifact_id: "event-streaming-v3-api"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C5","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/event-streaming-v3-api.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/event-streaming-v3-api.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:event-streaming-v3-v1"
generated_at: "2026-05-27T19:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["streaming-api-fundamentals", "streaming-api-advanced", "workflows-ceo"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks", "workflows-ceo"]
status: "🟢 Novo"
next_review: "2026-08-27"
---

# 🧩 Event Streaming v3 API — Projeções Tipadas e Stream Transformers

> **Contrato modular**: Artefato filho do Master Agent. Implementa a nova API de event streaming (`stream_events` v3) com projeções tipadas (`messages`, `values`, `subgraphs`, `output`), `StreamTransformer` customizado e canais.

## 🎯 Propósito

Fornecer uma biblioteca para streaming de última geração em LangGraph, usando o modelo de event streaming recomendado para novas aplicações, com suporte a consumo concorrente, projeções customizadas e integração com o protocolo Agent.

## 📋 Especificação (SDD)
- **Entradas**: Grafo compilado, input, `version="v3"`, `transformers`
- **Saídas**: `RunStream` com projeções `messages`, `values`, `subgraphs`, `output`, `extensions`
- **Side Effects**: Emissão de eventos de protocolo, logging de métricas de stream
- **Constraints Aplicáveis**: C1, C2, C5, C8, C9
- **Dependências**: `langgraph` (>=1.2), `langchain-protocol`

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
# 1. STREAM BÁSICO COM PROJEÇÕES
# ═══════════════════════════════════════════════════════════════════════════
from langgraph.pregel import Pregel
from langgraph.types import StreamPart
import asyncio

class EventStreamV3:
    """Encapsula a API stream_events v3."""
    def __init__(self, graph: Pregel):
        self.graph = graph

    def stream_messages(self, inputs: dict, config: dict = None):
        stream = self.graph.stream_events(inputs, config=config, version="v3")
        for message in stream.messages:
            text = str(message.text)
            mantis_log("DEBUG", "stream_message", text[:50])
            yield text

    def stream_values(self, inputs: dict, config: dict = None):
        stream = self.graph.stream_events(inputs, config=config, version="v3")
        for snapshot in stream.values:
            yield snapshot
        final = stream.output
        yield {"final": final}

    def stream_subgraphs(self, inputs: dict, config: dict = None):
        stream = self.graph.stream_events(inputs, config=config, version="v3")
        for subgraph in stream.subgraphs:
            mantis_log("DEBUG", "subgraph_detected", f"Name={subgraph.graph_name}, Path={subgraph.path}")
            for msg in subgraph.messages:
                yield {"subgraph": subgraph.graph_name, "text": str(msg.text)}

    async def astream_concurrent(self, inputs: dict, config: dict = None):
        stream = await self.graph.astream_events(inputs, config=config, version="v3")
        async def consume_messages():
            async for message in stream.messages:
                print(f"[msg] {str(message.text)[:30]}")
        async def consume_subgraphs():
            async for subgraph in stream.subgraphs:
                print(f"[sub] {subgraph.graph_name}")
        await asyncio.gather(consume_messages(), consume_subgraphs())

# ═══════════════════════════════════════════════════════════════════════════
# 2. STREAM TRANSFORMER CUSTOMIZADO
# ═══════════════════════════════════════════════════════════════════════════
from langgraph.stream import ProtocolEvent, StreamChannel, StreamTransformer
from typing import TypedDict

class ToolActivity(TypedDict):
    name: str
    status: str

class ToolActivityTransformer(StreamTransformer):
    required_stream_modes = ("tools",)

    def __init__(self, scope: tuple = ()):
        super().__init__(scope)
        self.activity = StreamChannel[ToolActivity]("tool_activity")

    def init(self) -> dict:
        return {"tool_activity": self.activity}

    def process(self, event: ProtocolEvent) -> bool:
        if event["method"] != "tools":
            return True
        data = event["params"]["data"]
        if isinstance(data, dict) and data.get("tool_name") and data.get("event"):
            status = "error" if data["event"] == "tool-error" else "started"
            self.activity.push({"name": data["tool_name"], "status": status})
        return True

class CustomEventStream:
    """Stream com transformer customizado de atividade de ferramentas."""
    def __init__(self, graph: Pregel):
        self.graph = graph

    def stream_with_tool_activity(self, inputs: dict, config: dict = None):
        stream = self.graph.stream_events(
            inputs, config=config, version="v3",
            transformers=[ToolActivityTransformer],
        )
        tool_activities = []
        for activity in stream.extensions.get("tool_activity", []):
            tool_activities.append(activity)
        return {"messages": [str(m.text) for m in stream.messages], "tools": tool_activities}

# ═══════════════════════════════════════════════════════════════════════════
# 3. INTERRUPTS E RETOMADA
# ═══════════════════════════════════════════════════════════════════════════
from langgraph.types import Command
from langgraph.checkpoint.memory import InMemorySaver

class InterruptStreamV3:
    """Gerencia interrupts com a API v3."""
    def __init__(self, graph):
        self.graph = graph

    def stream_until_interrupt(self, inputs: dict, config: dict):
        stream = self.graph.stream_events(inputs, config=config, version="v3")
        for message in stream.messages:
            yield {"type": "message", "text": str(message.text)}
        if stream.interrupted:
            mantis_log("INFO", "stream_interrupted", str(stream.interrupts))
            yield {"type": "interrupt", "payload": stream.interrupts}

    def resume_after_interrupt(self, resume_value, config: dict):
        stream = self.graph.stream_events(
            Command(resume=resume_value), config=config, version="v3"
        )
        for message in stream.messages:
            yield {"type": "message", "text": str(message.text)}
        yield {"type": "final", "output": stream.output}

# ═══════════════════════════════════════════════════════════════════════════
# 4. CONSUMO DE EVENTOS BRUTOS (PROTOCOL EVENTS)
# ═══════════════════════════════════════════════════════════════════════════
class RawProtocolEventStreamer:
    """Expõe eventos de protocolo brutos para debugging."""
    def __init__(self, graph: Pregel):
        self.graph = graph

    def stream_raw(self, inputs: dict, config: dict = None):
        stream = self.graph.stream_events(inputs, config=config, version="v3")
        events = []
        for event in stream:
            events.append({
                "seq": event["seq"],
                "method": event["method"],
                "namespace": event["params"]["namespace"],
                "data": str(event["params"]["data"])[:100],
            })
        return events

# ═══════════════════════════════════════════════════════════════════════════
# 5. EXEMPLO COMPLETO: GRAFO COM STREAMING V3
# ═══════════════════════════════════════════════════════════════════════════
class EventStreamingExampleGraph:
    """Demonstra streaming v3 com grafo simples."""
    def __init__(self):
        from langgraph.graph import StateGraph, START, END
        from langchain.chat_models import init_chat_model
        self.model = init_chat_model("deepseek-chat", model_provider="deepseek", temperature=0.05)

        class JokeState(TypedDict):
            topic: str
            joke: str

        def generate_joke(state: JokeState):
            response = self.model.invoke([{"role": "user", "content": f"Tell a joke about {state['topic']}"}])
            return {"joke": response.content}

        builder = StateGraph(JokeState)
        builder.add_node("generate_joke", generate_joke)
        builder.add_edge(START, "generate_joke")
        builder.add_edge("generate_joke", END)
        self.graph = builder.compile(checkpointer=InMemorySaver())

    def run_demo(self) -> dict:
        stream = self.graph.stream_events({"topic": "cats"}, version="v3")
        messages = []
        for message in stream.messages:
            messages.append(str(message.text))
        return {"joke": "".join(messages)}
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from event_streaming_v3_api import (
    EventStreamV3, ToolActivityTransformer, CustomEventStream,
    InterruptStreamV3, EventStreamingExampleGraph
)

def test_event_streaming_example():
    example = EventStreamingExampleGraph()
    result = example.run_demo()
    assert "joke" in result
    assert len(result["joke"]) > 0

def test_tool_activity_transformer():
    transformer = ToolActivityTransformer()
    projections = transformer.init()
    assert "tool_activity" in projections

def test_custom_event_stream():
    example = EventStreamingExampleGraph()
    streamer = CustomEventStream(example.graph)
    result = streamer.stream_with_tool_activity({"topic": "dogs"})
    assert "messages" in result
    assert "tools" in result

def test_raw_protocol_stream():
    example = EventStreamingExampleGraph()
    raw_streamer = RawProtocolEventStreamer(example.graph)
    events = raw_streamer.stream_raw({"topic": "cats"})
    assert len(events) > 0
    assert "method" in events[0]
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/event-streaming-v3-api.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[streaming-api-fundamentals.md]]
- [[streaming-api-advanced.md]]
- [[graph-api-fundamentals.md]]
