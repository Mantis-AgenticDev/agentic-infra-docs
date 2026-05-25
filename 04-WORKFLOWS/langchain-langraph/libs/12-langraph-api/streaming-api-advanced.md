---
artifact_id: "streaming-api-advanced"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C5","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/streaming-api-advanced.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/streaming-api-advanced.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:streaming-api-advanced-v1"
generated_at: "2026-05-27T16:30:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["streaming-api-fundamentals", "graph-api-advanced", "workflows-ceo"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks", "workflows-ceo"]
status: "🟢 Novo"
next_review: "2026-08-27"
---

# 🧩 Streaming API Advanced — Subgrafo, Modelos Arbitrários, Migração v1→v2 e Debug

> **Contrato modular**: Artefato filho do Master Agent. Implementa padrões avançados de streaming: subgrafo streaming, streaming de modelos não-LangChain, migração v1→v2, e modos `checkpoints`, `tasks` e `debug`.

## 🎯 Propósito

Estender a API de streaming com capacidades de produção: streaming de subgrafos, integração com APIs de LLM arbitrárias (não-LangChain), migração automatizada v1→v2, e streaming de checkpoints/tasks para depuração avançada.

## 📋 Especificação (SDD)
- **Entradas**: Grafo com subgrafos, modelo arbitrário, configuração de checkpointer
- **Saídas**: Stream de subgrafos, tokens de qualquer API, eventos de checkpoint/task
- **Side Effects**: Logging de namespaces, métricas de subgrafo
- **Constraints Aplicáveis**: C1, C2, C5, C8, C9
- **Dependências**: `langgraph`, `langchain-core`, `streaming-api-fundamentals`

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
# 1. SUBGRAPH STREAMING
# ═══════════════════════════════════════════════════════════════════════════
from typing import TypedDict, Optional, Iterator, AsyncIterator
from langgraph.graph import StateGraph, START, END
from langgraph.pregel import Pregel
from streaming_api_fundamentals import UnifiedStreamer, StreamMode, StreamCollector

class SubgraphStreamer:
    """Streamer especializado para grafos com subgrafos."""
    def __init__(self, parent_graph: Pregel):
        self.graph = parent_graph

    def stream_with_subgraphs(self, inputs: dict, config: Optional[dict] = None) -> Iterator[dict]:
        """Stream incluindo outputs de subgrafos."""
        for chunk in self.graph.stream(
            inputs,
            config=config,
            stream_mode=[StreamMode.UPDATES, StreamMode.VALUES],
            version="v2",
            subgraphs=True,
        ):
            ns = chunk.get("ns", ())
            if ns:
                mantis_log("DEBUG", "subgraph_chunk", f"Namespace={ns}")
            yield {"namespace": ns, "type": chunk["type"], "data": chunk["data"]}

class SubgraphMetrics:
    """Coleta métricas de execução de subgrafos."""
    def __init__(self):
        self.subgraph_calls = {}
        self.subgraph_events = 0

    def record(self, namespace: tuple):
        if namespace:
            key = "->".join(namespace)
            self.subgraph_calls[key] = self.subgraph_calls.get(key, 0) + 1
        self.subgraph_events += 1

    def report(self) -> dict:
        return {
            "total_events": self.subgraph_events,
            "subgraph_calls": self.subgraph_calls,
        }

# ═══════════════════════════════════════════════════════════════════════════
# 2. STREAMING DE MODELOS ARBITRÁRIOS (NÃO-LANGCHAIN)
# ═══════════════════════════════════════════════════════════════════════════
import asyncio
from langgraph.config import get_stream_writer

class ArbitraryModelStreamer:
    """Integra qualquer API de LLM com o sistema de streaming do LangGraph."""
    def __init__(self, stream_fn: callable):
        """
        Args:
            stream_fn: Função async que recebe (messages, model_name) e faz yield de chunks.
        """
        self.stream_fn = stream_fn

    def create_streaming_node(self, model_name: str):
        """Cria um nó de grafo que faz streaming de um modelo arbitrário."""
        def node(state: dict) -> dict:
            writer = get_stream_writer()
            messages = state.get("messages", [])
            full_response = ""
            # Executa a função de streaming de forma síncrona dentro do nó
            import asyncio
            async def _stream():
                nonlocal full_response
                async for chunk in self.stream_fn(messages, model_name):
                    content = chunk.get("content", "")
                    full_response += content
                    writer({"custom_llm_chunk": chunk})
            try:
                loop = asyncio.get_event_loop()
                if loop.is_running():
                    import nest_asyncio
                    nest_asyncio.apply()
                asyncio.run(_stream())
            except RuntimeError:
                asyncio.run(_stream())
            mantis_log("INFO", "arbitrary_model_done", model_name)
            return {"messages": [{"role": "assistant", "content": full_response}]}
        return node

# ═══════════════════════════════════════════════════════════════════════════
# 3. MIGRAÇÃO v1 → v2
# ═══════════════════════════════════════════════════════════════════════════
class StreamMigrationHelper:
    """Utilitários para migrar código de streaming v1 para v2."""

    @staticmethod
    def migrate_stream_call(old_code: str) -> str:
        """Analisa código v1 e sugere alterações para v2."""
        suggestions = []
        if "stream_mode=" in old_code and "version=" not in old_code:
            suggestions.append("Adicionar version='v2' ao método stream()")
        if "for mode, chunk in graph.stream" in old_code:
            suggestions.append("Substituir 'for mode, chunk' por 'for chunk' e usar chunk['type']")
        if "subgraphs=True" in old_code and "version=" not in old_code:
            suggestions.append("Com v2, o formato é unificado; verificar chunk['ns'] para subgrafos")
        return suggestions

    @staticmethod
    def convert_v1_to_v2(v1_output) -> dict:
        """Converte uma saída v1 para o formato v2 StreamPart."""
        if isinstance(v1_output, tuple):
            if len(v1_output) == 2:
                mode_or_ns, data = v1_output
                return {"type": mode_or_ns if isinstance(mode_or_ns, str) else "updates", "ns": mode_or_ns if isinstance(mode_or_ns, tuple) else (), "data": data}
            elif len(v1_output) == 3:
                ns, mode, data = v1_output
                return {"type": mode, "ns": ns, "data": data}
        return {"type": "updates", "ns": (), "data": v1_output}

# ═══════════════════════════════════════════════════════════════════════════
# 4. CHECKPOINTS E TASKS STREAMING
# ═══════════════════════════════════════════════════════════════════════════
from langgraph.checkpoint.memory import InMemorySaver

class DiagnosticStreamer:
    """Stream de checkpoints e tasks para diagnóstico avançado."""
    def __init__(self, graph: Pregel, checkpointer=None):
        self.graph = graph
        self.checkpointer = checkpointer or InMemorySaver()

    def stream_checkpoints(self, inputs: dict, config: dict) -> Iterator[dict]:
        """Stream de eventos de checkpoint."""
        for chunk in self.graph.stream(
            inputs,
            config=config,
            stream_mode=StreamMode.CHECKPOINTS,
            version="v2",
        ):
            if chunk["type"] == StreamMode.CHECKPOINTS:
                mantis_log("DEBUG", "checkpoint_event", str(chunk["data"].get("config", {}).get("configurable", {}).get("checkpoint_id", "")))
                yield chunk["data"]

    def stream_tasks(self, inputs: dict, config: dict) -> Iterator[dict]:
        """Stream de eventos de task (start/finish)."""
        for chunk in self.graph.stream(
            inputs,
            config=config,
            stream_mode=StreamMode.TASKS,
            version="v2",
        ):
            if chunk["type"] == StreamMode.TASKS:
                yield chunk["data"]

    def stream_debug(self, inputs: dict, config: dict) -> Iterator[dict]:
        """Stream de debug (combina checkpoints + tasks + metadata)."""
        for chunk in self.graph.stream(
            inputs,
            config=config,
            stream_mode=StreamMode.DEBUG,
            version="v2",
        ):
            if chunk["type"] == StreamMode.DEBUG:
                yield chunk["data"]

# ═══════════════════════════════════════════════════════════════════════════
# 5. EXEMPLO COMPLETO: SUBGRAFO COM STREAMING DIAGNÓSTICO
# ═══════════════════════════════════════════════════════════════════════════
class SubgraphStreamingExample:
    """Demonstra streaming de subgrafo com diagnóstico."""
    def __init__(self):
        class SubState(TypedDict):
            foo: str
            bar: str

        def sub_node_1(state: SubState) -> dict:
            return {"bar": "bar"}

        def sub_node_2(state: SubState) -> dict:
            return {"foo": state["foo"] + state["bar"]}

        sub_builder = StateGraph(SubState)
        sub_builder.add_node("sub_node_1", sub_node_1)
        sub_builder.add_node("sub_node_2", sub_node_2)
        sub_builder.add_edge(START, "sub_node_1")
        sub_builder.add_edge("sub_node_1", "sub_node_2")
        self.subgraph = sub_builder.compile()

        class ParentState(TypedDict):
            foo: str

        def parent_node(state: ParentState) -> dict:
            return {"foo": "hi! " + state["foo"]}

        builder = StateGraph(ParentState)
        builder.add_node("parent_node", parent_node)
        builder.add_node("child", self.subgraph)
        builder.add_edge(START, "parent_node")
        builder.add_edge("parent_node", "child")
        self.graph = builder.compile(checkpointer=InMemorySaver())

    def run_demo(self) -> dict:
        streamer = SubgraphStreamer(self.graph)
        metrics = SubgraphMetrics()
        results = []
        for chunk in streamer.stream_with_subgraphs({"foo": "foo"}, {"configurable": {"thread_id": "demo-1"}}):
            metrics.record(chunk["namespace"])
            results.append(chunk)
        return {"chunks": len(results), "metrics": metrics.report()}
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from streaming_api_advanced import (
    SubgraphStreamer, SubgraphMetrics, ArbitraryModelStreamer,
    StreamMigrationHelper, DiagnosticStreamer, SubgraphStreamingExample
)

def test_subgraph_metrics():
    metrics = SubgraphMetrics()
    metrics.record(("parent:1", "child:2"))
    metrics.record(("parent:1", "child:2"))
    assert metrics.subgraph_events == 2
    assert "parent:1->child:2" in metrics.subgraph_calls

def test_migration_v1_single():
    result = StreamMigrationHelper.convert_v1_to_v2({"node": {"key": "val"}})
    assert result["type"] == "updates"
    assert result["data"] == {"node": {"key": "val"}}

def test_migration_v1_tuple():
    result = StreamMigrationHelper.convert_v1_to_v2(("updates", {"node": {"key": "val"}}))
    assert result["type"] == "updates"
    assert result["ns"] == ()

def test_subgraph_example():
    example = SubgraphStreamingExample()
    result = example.run_demo()
    assert result["chunks"] > 0
    assert result["metrics"]["subgraph_calls"]
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/streaming-api-advanced.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[streaming-api-fundamentals.md]]
- [[graph-api-fundamentals.md]]
- [[functional-api-advanced.md]]
