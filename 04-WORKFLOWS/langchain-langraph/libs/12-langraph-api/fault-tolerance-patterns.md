---
artifact_id: "fault-tolerance-patterns"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/fault-tolerance-patterns.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/fault-tolerance-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:fault-tolerance-v1"
generated_at: "2026-05-27T18:45:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["durable-execution-graceful-shutdown", "graph-api-advanced", "workflows-ceo"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks", "workflows-ceo"]
status: "🟢 Novo"
next_review: "2026-08-27"
---

# 🧩 Fault Tolerance Patterns — Retry, Timeout e Error Handlers

> **Contrato modular**: Artefato filho do Master Agent. Implementa padrões de tolerância a falhas: `RetryPolicy`, `TimeoutPolicy`, `error_handler`, defaults de nó e inspeção de estado de retry.

## 🎯 Propósito

Permitir que os agentes resistam a falhas transitórias (APIs lentas, timeouts de rede) e se recuperem de erros de forma controlada, usando políticas de retry, timeouts por nó e handlers de erro com compensação.

## 📋 Especificação (SDD)
- **Entradas**: Configuração de `RetryPolicy`, `TimeoutPolicy`, `error_handler`, `set_node_defaults`
- **Saídas**: Execução resiliente com retentativas e recuperação de falhas
- **Side Effects**: Logging de retries, timeouts e handlers de erro
- **Constraints Aplicáveis**: C1, C2, C3, C5, C7, C8
- **Dependências**: `langgraph` (>=1.2), `langgraph-checkpoint`

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
# 1. CONFIGURAÇÃO DE RETRY POLICY
# ═══════════════════════════════════════════════════════════════════════════
from typing import Optional, Sequence, Callable
from langgraph.types import RetryPolicy, default_retry_on
from langgraph.graph import StateGraph, START, END
from typing_extensions import TypedDict

class RetryConfigurator:
    """Fabrica e aplica políticas de retry em nós."""
    @staticmethod
    def create_default() -> RetryPolicy:
        return RetryPolicy(max_attempts=3)

    @staticmethod
    def create_with_custom_exceptions(retry_on: Sequence[type[Exception]] = None) -> RetryPolicy:
        if retry_on:
            return RetryPolicy(max_attempts=3, retry_on=retry_on)
        return RetryPolicy(max_attempts=3)

    @staticmethod
    def create_custom_logic(condition: Callable[[Exception], bool]) -> RetryPolicy:
        return RetryPolicy(max_attempts=3, retry_on=condition)

    @staticmethod
    def apply_to_node(builder: StateGraph, node_name: str, func: callable, retry_policy: RetryPolicy):
        builder.add_node(node_name, func, retry_policy=retry_policy)
        mantis_log("INFO", "retry_policy_applied", f"Node={node_name}, MaxAttempts={retry_policy.max_attempts}")

# ═══════════════════════════════════════════════════════════════════════════
# 2. CONFIGURAÇÃO DE TIMEOUT POLICY
# ═══════════════════════════════════════════════════════════════════════════
from datetime import timedelta
from langgraph.types import TimeoutPolicy

class TimeoutConfigurator:
    """Fabrica e aplica políticas de timeout em nós."""
    @staticmethod
    def simple_timeout(seconds: float) -> TimeoutPolicy:
        return TimeoutPolicy(run_timeout=seconds)

    @staticmethod
    def idle_timeout(seconds: float, refresh_on: str = "auto") -> TimeoutPolicy:
        return TimeoutPolicy(idle_timeout=seconds, refresh_on=refresh_on)

    @staticmethod
    def apply_to_node(builder: StateGraph, node_name: str, func: callable, timeout: TimeoutPolicy):
        builder.add_node(node_name, func, timeout=timeout)
        mantis_log("INFO", "timeout_applied", f"Node={node_name}, Run={timeout.run_timeout}, Idle={timeout.idle_timeout}")

# ═══════════════════════════════════════════════════════════════════════════
# 3. ERROR HANDLER COM COMANDO DE COMPENSAÇÃO
# ═══════════════════════════════════════════════════════════════════════════
from langgraph.errors import NodeError
from langgraph.types import Command

class ErrorHandlerFactory:
    """Cria handlers de erro para nós com diferentes estratégias de compensação."""
    @staticmethod
    def create_log_only_handler():
        def handler(state: dict, error: NodeError) -> dict:
            mantis_log("ERROR", "node_failed", f"Node={error.node}, Error={str(error.error)}")
            return {"status": f"failed: {error.error}"}
        return handler

    @staticmethod
    def create_compensate_handler(compensation_node: str):
        def handler(state: dict, error: NodeError) -> Command:
            mantis_log("ERROR", "node_compensated", f"Node={error.node}, Goto={compensation_node}")
            return Command(
                update={"status": f"compensated_after_{error.node}: {error.error}"},
                goto=compensation_node,
            )
        return handler

    @staticmethod
    def create_retry_then_handler_handler(max_retries: int, fallback_node: str):
        retry_policy = RetryPolicy(max_attempts=max_retries)
        error_handler = ErrorHandlerFactory.create_compensate_handler(fallback_node)
        return retry_policy, error_handler

# ═══════════════════════════════════════════════════════════════════════════
# 4. GRAPH DEFAULTS (set_node_defaults)
# ═══════════════════════════════════════════════════════════════════════════
class GraphDefaultsConfigurator:
    """Aplica defaults de nó em um grafo."""
    @staticmethod
    def apply_all_defaults(builder: StateGraph, retry_policy: Optional[RetryPolicy] = None,
                           timeout: Optional[TimeoutPolicy] = None, error_handler: Optional[callable] = None):
        builder.set_node_defaults(
            retry_policy=retry_policy or RetryPolicy(max_attempts=3),
            timeout=timeout or TimeoutPolicy(run_timeout=30),
            error_handler=error_handler or ErrorHandlerFactory.create_log_only_handler(),
        )
        mantis_log("INFO", "node_defaults_applied")
        return builder

# ═══════════════════════════════════════════════════════════════════════════
# 5. INSPEÇÃO DE ESTADO DE RETRY
# ═══════════════════════════════════════════════════════════════════════════
from langgraph.runtime import Runtime

class RetryStateInspector:
    """Nó que inspeciona o estado de retry e adapta comportamento."""
    @staticmethod
    def create_adaptive_node(primary_call: callable, fallback_call: callable):
        def node(state: dict, runtime: Runtime) -> dict:
            if runtime.execution_info.node_attempt > 1:
                mantis_log("WARN", "fallback_used", f"Attempt={runtime.execution_info.node_attempt}")
                return fallback_call(state)
            return primary_call(state)
        return node

# ═══════════════════════════════════════════════════════════════════════════
# 6. EXEMPLO COMPLETO: GRAFO COM RETRY, TIMEOUT E ERROR HANDLER
# ═══════════════════════════════════════════════════════════════════════════
class FaultTolerantGraphExample:
    """Demonstra um grafo com políticas de tolerância a falhas."""
    def __init__(self):
        self.checkpointer = InMemorySaver()

    def build(self):
        class ExampleState(TypedDict):
            status: str

        def primary_node(state: ExampleState) -> dict:
            raise RuntimeError("API gateway timeout")
        def fallback_node(state: ExampleState) -> dict:
            return {"status": "completed_via_fallback"}
        def finalize_node(state: ExampleState) -> dict:
            return {"status": state["status"] + " final"}

        builder = StateGraph(ExampleState)
        builder.add_node("primary", primary_node,
                         retry_policy=RetryPolicy(max_attempts=2, retry_on=ConnectionError),
                         error_handler=ErrorHandlerFactory.create_compensate_handler("fallback"))
        builder.add_node("fallback", fallback_node)
        builder.add_node("finalize", finalize_node)
        builder.add_edge(START, "primary")
        builder.add_edge("fallback", "finalize")
        builder.add_edge("finalize", END)
        return builder.compile(checkpointer=self.checkpointer)
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from fault_tolerance_patterns import (
    RetryConfigurator, TimeoutConfigurator, ErrorHandlerFactory,
    GraphDefaultsConfigurator, FaultTolerantGraphExample
)
from langgraph.types import RetryPolicy, TimeoutPolicy
from langgraph.graph import StateGraph, START, END
from typing_extensions import TypedDict

class SimpleState(TypedDict):
    value: int

def test_retry_policy_creation():
    policy = RetryConfigurator.create_default()
    assert policy.max_attempts == 3

def test_error_handler_log_only():
    handler = ErrorHandlerFactory.create_log_only_handler()
    from langgraph.errors import NodeError
    result = handler({"status": "ok"}, NodeError(node="test", error=ValueError("test")))
    assert "failed" in result["status"]

def test_graph_defaults():
    builder = StateGraph(SimpleState)
    builder.add_node("node", lambda s: s)
    builder.add_edge(START, "node")
    builder.add_edge("node", END)
    GraphDefaultsConfigurator.apply_all_defaults(builder)
    graph = builder.compile()
    assert graph is not None

def test_fault_tolerant_graph():
    example = FaultTolerantGraphExample()
    graph = example.build()
    config = {"configurable": {"thread_id": "ft-test"}}
    result = graph.invoke({"status": "start"}, config)
    assert "compensated" in result["status"] or "fallback" in result["status"]
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/fault-tolerance-patterns.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[durable-execution-graceful-shutdown.md]]
- [[graph-api-advanced.md]]
