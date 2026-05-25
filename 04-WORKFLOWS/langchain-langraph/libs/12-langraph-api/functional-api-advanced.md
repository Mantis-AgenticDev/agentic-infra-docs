---
artifact_id: "functional-api-advanced"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/functional-api-advanced.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/functional-api-advanced.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:functional-api-advanced-v1"
generated_at: "2026-05-27T15:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["functional-api-fundamentals", "graph-vs-functional-decision", "workflows-ceo"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks", "workflows-ceo"]
status: "🟢 Novo"
next_review: "2026-08-27"
---

# 🧩 Functional API Advanced — HITL, Streaming, Retry, Timeout e Caching

> **Contrato modular**: Artefato filho do Master Agent. Implementa padrões avançados da Functional API: human-in-the-loop com `interrupt`, streaming custom, retry policies, timeouts, caching de tasks e `entrypoint.final`.

## 🎯 Propósito

Estender a Functional API com capacidades de produção: intervenção humana, streaming de dados customizados, políticas de retry e timeout, cache de resultados e desacoplamento de retorno/checkpoint.

## 📋 Especificação (SDD)
- **Entradas**: Configuração de `RetryPolicy`, `CachePolicy`, `timeout`, `interrupt`, `StreamWriter`
- **Saídas**: Workflows resilientes com HITL, streaming e cache
- **Side Effects**: Interrupção para input humano, logging de retries, escrita de stream custom
- **Constraints Aplicáveis**: C1, C2, C3, C5, C7, C8
- **Dependências**: `langgraph`, `functional-api-fundamentals`

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
# 1. HUMAN-IN-THE-LOOP COM INTERRUPT
# ═══════════════════════════════════════════════════════════════════════════
from langgraph.func import entrypoint, task
from langgraph.checkpoint.memory import InMemorySaver
from langgraph.types import Command, interrupt, StreamWriter

checkpointer = InMemorySaver()

@task
def step_1(input_query: str) -> str:
    """Primeira etapa: processa input."""
    return f"{input_query} bar"

@task
def human_feedback(input_query: str) -> str:
    """Solicita feedback humano."""
    feedback = interrupt(f"Please provide feedback for: {input_query}")
    mantis_log("INFO", "human_feedback_received", str(feedback))
    return f"{input_query} {feedback}"

@task
def step_3(input_query: str) -> str:
    """Etapa final."""
    return f"{input_query} qux"

@entrypoint(checkpointer=checkpointer)
def hitl_workflow(input_query: str) -> str:
    """Workflow com intervenção humana."""
    result_1 = step_1(input_query).result()
    result_2 = human_feedback(result_1).result()
    result_3 = step_3(result_2).result()
    return result_3

# ═══════════════════════════════════════════════════════════════════════════
# 2. STREAMING CUSTOM
# ═══════════════════════════════════════════════════════════════════════════
@entrypoint(checkpointer=InMemorySaver())
def streaming_workflow(inputs: dict, writer: StreamWriter) -> dict:
    """Workflow que emite dados customizados via streaming."""
    writer("Starting processing...")
    writer(f"Input received: {inputs}")
    result = inputs.get("value", 0) * 2
    writer(f"Result computed: {result}")
    mantis_log("INFO", "streaming_workflow_done", str(result))
    return {"result": result}

# ═══════════════════════════════════════════════════════════════════════════
# 3. RETRY POLICIES
# ═══════════════════════════════════════════════════════════════════════════
from langgraph.errors import NodeTimeoutError

class RetryableWorkflow:
    """Workflow com políticas de retry e timeout."""
    def __init__(self):
        self.attempts = 0

    def create_tasks(self):
        @task(retry_policy=RetryPolicy(retry_on=ValueError, max_attempts=3))
        def flaky_task(data: str) -> str:
            self.attempts += 1
            if self.attempts < 2:
                raise ValueError("Falha simulada")
            mantis_log("INFO", "flaky_task_succeeded", f"Attempt={self.attempts}")
            return f"Success after {self.attempts} attempts"

        @task(timeout=2.0, retry_policy=RetryPolicy(retry_on=NodeTimeoutError, max_attempts=2))
        async def timeout_task() -> str:
            await asyncio.sleep(3)
            return "Done"

        @entrypoint(checkpointer=InMemorySaver())
        def retry_workflow(data: str) -> str:
            return flaky_task(data).result()

        return retry_workflow

# ═══════════════════════════════════════════════════════════════════════════
# 4. CACHING DE TASKS
# ═══════════════════════════════════════════════════════════════════════════
from langgraph.types import CachePolicy
from langgraph.cache.memory import InMemoryCache

class CacheableWorkflow:
    """Workflow com cache de resultados de tasks."""
    def build(self):
        @task(cache_policy=CachePolicy(ttl=120))
        def cached_computation(x: int) -> int:
            time.sleep(0.5)
            mantis_log("INFO", "cached_computation_executed", str(x))
            return x * 2

        @entrypoint(checkpointer=InMemorySaver(), cache=InMemoryCache())
        def cached_workflow(inputs: dict) -> dict:
            result1 = cached_computation(inputs["x"]).result()
            result2 = cached_computation(inputs["x"]).result()
            return {"result1": result1, "result2": result2}

        return cached_workflow

# ═══════════════════════════════════════════════════════════════════════════
# 5. INTEGRAÇÃO COM GRAPH API
# ═══════════════════════════════════════════════════════════════════════════
from langgraph.graph import StateGraph

class GraphFunctionalIntegration:
    """Demonstra integração entre Functional API e Graph API."""
    def build(self):
        # Graph API component
        class GraphState(TypedDict):
            value: int

        def double_node(state: GraphState) -> dict:
            return {"value": state["value"] * 2}

        graph_builder = StateGraph(GraphState)
        graph_builder.add_node("double", double_node)
        graph_builder.set_entry_point("double")
        graph_builder.set_finish_point("double")
        subgraph = graph_builder.compile()

        # Functional API component
        @entrypoint(checkpointer=InMemorySaver())
        def integrated_workflow(x: int) -> dict:
            graph_result = subgraph.invoke({"value": x})
            mantis_log("INFO", "integration_step", f"Graph result={graph_result}")
            return {"bar": graph_result["value"]}

        return integrated_workflow

# ═══════════════════════════════════════════════════════════════════════════
# 6. FÁBRICA DE WORKFLOWS COM HITL CONFIGURÁVEL
# ═══════════════════════════════════════════════════════════════════════════
class HITLWorkflowFactory:
    """Cria workflows com pontos de intervenção humana configuráveis."""
    def __init__(self):
        self.interrupt_points = []

    def add_interrupt(self, task_name: str, prompt: str):
        self.interrupt_points.append({"task": task_name, "prompt": prompt})
        return self

    def build(self) -> callable:
        @entrypoint(checkpointer=InMemorySaver())
        def dynamic_hitl(inputs: dict) -> dict:
            result = inputs
            for point in self.interrupt_points:
                feedback = interrupt(point["prompt"])
                result[point["task"]] = feedback
                mantis_log("INFO", "dynamic_hitl", f"Task={point['task']}, Feedback={feedback}")
            return result
        return dynamic_hitl
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from functional_api_advanced import (
    hitl_workflow, streaming_workflow, RetryableWorkflow,
    CacheableWorkflow, GraphFunctionalIntegration, HITLWorkflowFactory
)
from langgraph.types import Command

def test_streaming_workflow():
    config = {"configurable": {"thread_id": "stream-1"}}
    chunks = list(streaming_workflow.stream({"value": 5}, config, stream_mode="custom"))
    assert len(chunks) > 0

def test_retry_workflow():
    wf = RetryableWorkflow().create_tasks()
    result = wf.invoke("test")
    assert "Success" in result

def test_cacheable_workflow():
    wf = CacheableWorkflow().build()
    result = wf.invoke({"x": 5})
    assert result["result1"] == 10
    assert result["result2"] == 10

def test_integration():
    wf = GraphFunctionalIntegration().build()
    result = wf.invoke(5)
    assert result["bar"] == 10

def test_hitl_factory():
    factory = HITLWorkflowFactory()
    factory.add_interrupt("review", "Approve?")
    wf = factory.build()
    # Teste sem interrupção real (apenas verifica que o grafo é criado)
    assert wf is not None
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/functional-api-advanced.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[functional-api-fundamentals.md]]
- [[graph-api-fundamentals.md]]
- [[graph-vs-functional-decision.md]]
