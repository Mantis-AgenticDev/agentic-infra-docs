---
artifact_id: "multi-agent-streaming"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C5","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/11-swarm-supervisor/multi-agent-streaming.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/11-swarm-supervisor/multi-agent-streaming.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:multi-agent-streaming-v1"
generated_at: "2026-05-27T09:45:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["swarm-fundamentals", "supervisor-fundamentals", "swarm-supervisor-patterns"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks", "workflows-ceo"]
status: "🟢 Novo"
next_review: "2026-08-27"
---

# 🧩 Multi-Agent Streaming — Observabilidade em Tempo Real para Enxames

> **Contrato modular**: Artefato filho do Master Agent. Implementa streaming de tokens, eventos de handoff e mudanças de estado em sistemas multi-agente, integrando com o sistema de logging MANTIS.

## 🎯 Propósito

Permitir monitoramento em tempo real da execução de enxames e supervisores, capturando tokens de LLM, transições de agente ativo, mensagens de handoff e métricas de performance.

## 📋 Especificação (SDD)
- **Entradas**: Grafo compilado, modo de streaming (`values`, `updates`, `messages`, `custom`), callbacks
- **Saídas**: Stream de eventos tipados, métricas agregadas
- **Side Effects**: Logging de eventos, atualização de dashboards
- **Constraints Aplicáveis**: C1, C5, C8, C9
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
# 1. STREAMER DE ENXAME MULTI-MODO
# ═══════════════════════════════════════════════════════════════════════════
from typing import AsyncIterator, Iterator, Dict, Any, Optional
from langgraph.pregel import Pregel

class SwarmStreamer:
    """Encapsula diferentes modos de streaming para um grafo multi-agente."""
    def __init__(self, graph: Pregel):
        self.graph = graph

    def stream_values(self, input_msg: str, config: dict, subgraphs: bool = True):
        """Stream de valores completos do estado a cada passo."""
        for chunk in self.graph.stream(
            {"messages": [{"role": "user", "content": input_msg}]},
            config,
            stream_mode="values",
            subgraphs=subgraphs,
        ):
            mantis_log("DEBUG", "stream_values", str(list(chunk.keys())[:3]))
            yield chunk

    def stream_updates(self, input_msg: str, config: dict, subgraphs: bool = True):
        """Stream de atualizações incrementais (nós)."""
        for chunk in self.graph.stream(
            {"messages": [{"role": "user", "content": input_msg}]},
            config,
            stream_mode="updates",
            subgraphs=subgraphs,
        ):
            yield chunk

    def stream_messages(self, input_msg: str, config: dict):
        """Stream de tokens de LLM (modo messages)."""
        for msg, metadata in self.graph.stream(
            {"messages": [{"role": "user", "content": input_msg}]},
            config,
            stream_mode="messages",
        ):
            mantis_log("DEBUG", "stream_message_token", f"Node={metadata.get('langgraph_node')}")
            yield msg, metadata

    def stream_events(self, input_msg: str, config: dict):
        """Stream de eventos brutos."""
        for event in self.graph.stream(
            {"messages": [{"role": "user", "content": input_msg}]},
            config,
            stream_mode="events",
        ):
            yield event

# ═══════════════════════════════════════════════════════════════════════════
# 2. COLETOR DE MÉTRICAS DE STREAMING
# ═══════════════════════════════════════════════════════════════════════════
import time
from collections import defaultdict

class StreamingMetrics:
    def __init__(self):
        self.start_time = None
        self.end_time = None
        self.node_executions = defaultdict(int)
        self.handoffs = []
        self.total_tokens = 0

    def start(self):
        self.start_time = time.time()

    def record_node(self, node_name: str):
        self.node_executions[node_name] += 1

    def record_handoff(self, from_agent: str, to_agent: str):
        self.handoffs.append((from_agent, to_agent))
        mantis_log("INFO", "streaming_handoff", f"{from_agent} -> {to_agent}")

    def record_tokens(self, count: int):
        self.total_tokens += count

    def stop(self):
        self.end_time = time.time()

    def report(self) -> dict:
        return {
            "elapsed": self.end_time - self.start_time if self.end_time else 0,
            "node_executions": dict(self.node_executions),
            "handoffs": self.handoffs,
            "total_tokens": self.total_tokens,
        }

# ═══════════════════════════════════════════════════════════════════════════
# 3. CALLBACK DE HANDOFF
# ═══════════════════════════════════════════════════════════════════════════
from langchain_core.callbacks import BaseCallbackHandler

class HandoffCallback(BaseCallbackHandler):
    """Callback que detecta handoffs e registra métricas."""
    def __init__(self, metrics: StreamingMetrics):
        self.metrics = metrics

    def on_tool_start(self, serialized, input_str, **kwargs):
        if "transfer_to" in serialized.get("name", ""):
            self.metrics.record_handoff("current", serialized["name"])

    def on_llm_new_token(self, token: str, **kwargs):
        self.metrics.record_tokens(1)

# ═══════════════════════════════════════════════════════════════════════════
# 4. STREAMER COM CALLBACKS E MÉTRICAS INTEGRADAS
# ═══════════════════════════════════════════════════════════════════════════
class InstrumentedSwarmStreamer:
    def __init__(self, graph: Pregel):
        self.graph = graph
        self.metrics = StreamingMetrics()

    def stream_with_metrics(self, input_msg: str, config: dict, mode: str = "values"):
        self.metrics.start()
        callbacks = [HandoffCallback(self.metrics)]
        # Adiciona callbacks ao config
        cfg = {**config, "callbacks": callbacks}
        if mode == "values":
            chunks = self.graph.stream(
                {"messages": [{"role": "user", "content": input_msg}]},
                cfg,
                stream_mode="values",
                subgraphs=True,
            )
        elif mode == "updates":
            chunks = self.graph.stream(
                {"messages": [{"role": "user", "content": input_msg}]},
                cfg,
                stream_mode="updates",
                subgraphs=True,
            )
        else:
            chunks = self.graph.stream(
                {"messages": [{"role": "user", "content": input_msg}]},
                cfg,
                stream_mode=mode,
            )
        for chunk in chunks:
            if "messages" in chunk:
                self.metrics.record_tokens(len(str(chunk["messages"])))
            yield chunk
        self.metrics.stop()
        mantis_log("INFO", "stream_metrics", str(self.metrics.report()))
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from multi_agent_streaming import SwarmStreamer, StreamingMetrics, InstrumentedSwarmStreamer
from swarm_fundamentals import build_customer_service_swarm

def test_streaming_metrics():
    metrics = StreamingMetrics()
    metrics.start()
    metrics.record_node("flight_agent")
    metrics.record_handoff("flight_agent", "hotel_agent")
    metrics.stop()
    report = metrics.report()
    assert report["node_executions"]["flight_agent"] == 1
    assert len(report["handoffs"]) == 1

def test_instrumented_streamer():
    runner = build_customer_service_swarm()
    streamer = InstrumentedSwarmStreamer(runner.graph)
    config = {"configurable": {"thread_id": "1", "user_id": "u1"}}
    chunks = list(streamer.stream_with_metrics("Olá", config))
    assert len(chunks) > 0
    assert streamer.metrics.total_tokens > 0
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/11-swarm-supervisor/multi-agent-streaming.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[swarm-fundamentals.md]]
- [[supervisor-fundamentals.md]]
- [[telemetry-export-collector.md]]
