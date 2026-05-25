---
artifact_id: "durable-execution-graceful-shutdown"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/durable-execution-graceful-shutdown.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/durable-execution-graceful-shutdown.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:durable-execution-v1"
generated_at: "2026-05-27T18:30:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["graph-api-advanced", "functional-api-advanced", "fault-tolerance-patterns", "workflows-ceo"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks", "workflows-ceo"]
status: "🟢 Novo"
next_review: "2026-08-27"
---

# 🧩 Durable Execution & Graceful Shutdown — Execução Resiliente com Tolerância a Interrupções

> **Contrato modular**: Artefato filho do Master Agent. Implementa padrões de execução durável: modos de durabilidade, encapsulamento de side effects em tasks, apagado graceful com `RunControl` e reanudação após falhas.

## 🎯 Propósito

Garantir que workflows LangGraph possam ser pausados e retomados de forma confiável, mesmo após interrupções do sistema ou intervenção humana, preservando o progresso e evitando re-execução de trabalho já concluído.

## 📋 Especificação (SDD)
- **Entradas**: Grafo com checkpointer, configuração de durabilidade, `RunControl`
- **Saídas**: Execução resiliente com capacidade de pausa/retomada, estado salvo em checkpoints
- **Side Effects**: Salvamento de checkpoints, sinal de drain, reanudação a partir do último checkpoint
- **Constraints Aplicáveis**: C1, C2, C3, C5, C7, C8
- **Dependências**: `langgraph`, `langgraph-checkpoint`

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
# 1. MODOS DE DURABILIDADE
# ═══════════════════════════════════════════════════════════════════════════
from typing import Literal
from langgraph.graph import StateGraph, START, END
from langgraph.checkpoint.memory import InMemorySaver
from typing_extensions import TypedDict

class DurabilityManager:
    """Configura e aplica modos de durabilidade na execução de grafos."""
    MODES = ("exit", "async", "sync")

    def __init__(self, graph):
        self.graph = graph

    def invoke_with_durability(self, inputs: dict, config: dict, mode: Literal["exit", "async", "sync"] = "async") -> dict:
        mantis_log("INFO", "durability_invoke", f"Mode={mode}")
        return self.graph.invoke(inputs, config, durability=mode)

    def stream_with_durability(self, inputs: dict, config: dict, mode: Literal["exit", "async", "sync"] = "async"):
        for chunk in self.graph.stream(inputs, config, durability=mode):
            yield chunk

# ═══════════════════════════════════════════════════════════════════════════
# 2. ENCAPSULAMENTO DE SIDE EFFECTS EM TASKS
# ═══════════════════════════════════════════════════════════════════════════
import time, requests
from langgraph.func import task

class TaskWrapper:
    """Encapsula operações com side effects em tasks para garantir durabilidade."""
    @staticmethod
    def create_api_task(url: str):
        @task
        def _fetch() -> str:
            response = requests.get(url, timeout=10)
            return response.text[:200]
        return _fetch

    @staticmethod
    def create_file_write_task(filename: str, content: str):
        @task
        def _write() -> str:
            with open(filename, "w") as f:
                f.write(content)
            return f"Written to {filename}"
        return _write

    @staticmethod
    def create_non_deterministic_task():
        import random
        @task
        def _random() -> int:
            return random.randint(1, 100)
        return _random

# ═══════════════════════════════════════════════════════════════════════════
# 3. GRACEFUL SHUTDOWN COM RUNCONTROL
# ═══════════════════════════════════════════════════════════════════════════
import signal
from langgraph.runtime import RunControl
from langgraph.errors import GraphDrained

class GracefulShutdownManager:
    """Gerencia apagado graceful de execuções de grafos."""
    def __init__(self, graph):
        self.graph = graph
        self.control = RunControl()

    def setup_signal_handler(self):
        signal.signal(signal.SIGTERM, lambda *_: self.control.request_drain("sigterm"))
        signal.signal(signal.SIGINT, lambda *_: self.control.request_drain("sigint"))
        mantis_log("INFO", "signal_handlers_setup", "SIGTERM, SIGINT")

    def invoke_with_drain(self, inputs: dict, config: dict) -> dict:
        try:
            result = self.graph.invoke(inputs, config, control=self.control)
            mantis_log("INFO", "graph_completed_normally")
            return result
        except GraphDrained as e:
            mantis_log("WARN", "graph_drained", f"Reason={e.reason}")
            raise

    def resume_after_drain(self, config: dict) -> dict:
        mantis_log("INFO", "resume_after_drain", str(config))
        return self.graph.invoke(None, config)

# ═══════════════════════════════════════════════════════════════════════════
# 4. NÓ COM INSPEÇÃO DE DRAIN STATE
# ═══════════════════════════════════════════════════════════════════════════
from langgraph.runtime import Runtime

class DrainAwareNode:
    """Nó que verifica estado de drain antes de executar trabalho pesado."""
    @staticmethod
    def create():
        def drain_aware(state: dict, runtime: Runtime) -> dict:
            if runtime.drain_requested:
                mantis_log("WARN", "drain_detected_in_node", runtime.drain_reason)
                return {"status": "skipped", "reason": runtime.drain_reason}
            time.sleep(2)
            return {"status": "completed"}
        return drain_aware

# ═══════════════════════════════════════════════════════════════════════════
# 5. EXEMPLO COMPLETO: WORKFLOW DURÁVEL COM TASKS
# ═══════════════════════════════════════════════════════════════════════════
class DurableWorkflowExample:
    """Demonstra workflow durável com tasks e graceful shutdown."""
    def __init__(self):
        self.checkpointer = InMemorySaver()

    def build(self):
        class DurableState(TypedDict):
            data: str
            processed: str

        fetch_task = TaskWrapper.create_api_task("https://example.com")

        def process_node(state: DurableState) -> dict:
            result = fetch_task().result()
            mantis_log("INFO", "api_fetched", f"Length={len(result)}")
            return {"processed": result[:50]}

        builder = StateGraph(DurableState)
        builder.add_node("process", DrainAwareNode.create())
        builder.add_node("fetch", process_node)
        builder.add_edge(START, "process")
        builder.add_edge("process", "fetch")
        builder.add_edge("fetch", END)
        return builder.compile(checkpointer=self.checkpointer)
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from durable_execution_graceful_shutdown import (
    DurabilityManager, TaskWrapper, GracefulShutdownManager, DurableWorkflowExample
)
from langgraph.graph import StateGraph, START, END
from langgraph.checkpoint.memory import InMemorySaver
from typing_extensions import TypedDict

class SimpleState(TypedDict):
    value: int

@pytest.fixture
def simple_graph():
    def node(state: SimpleState) -> dict:
        return {"value": state["value"] + 1}
    builder = StateGraph(SimpleState)
    builder.add_node("node", node)
    builder.add_edge(START, "node")
    builder.add_edge("node", END)
    return builder.compile(checkpointer=InMemorySaver())

def test_durability_modes(simple_graph):
    mgr = DurabilityManager(simple_graph)
    config = {"configurable": {"thread_id": "dur-test"}}
    result = mgr.invoke_with_durability({"value": 0}, config, mode="sync")
    assert result["value"] == 1

def test_graceful_shutdown_setup(simple_graph):
    mgr = GracefulShutdownManager(simple_graph)
    mgr.setup_signal_handler()
    assert mgr.control is not None

def test_durable_workflow_example():
    wf = DurableWorkflowExample()
    graph = wf.build()
    config = {"configurable": {"thread_id": "durable-1"}}
    result = graph.invoke({"data": "test"}, config)
    assert "processed" in result
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/durable-execution-graceful-shutdown.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[graph-api-advanced.md]]
- [[functional-api-advanced.md]]
- [[fault-tolerance-patterns.md]]
