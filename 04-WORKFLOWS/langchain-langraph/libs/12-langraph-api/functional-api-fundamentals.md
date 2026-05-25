---
artifact_id: "functional-api-fundamentals"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/functional-api-fundamentals.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/functional-api-fundamentals.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:functional-api-fundamentals-v1"
generated_at: "2026-05-27T14:15:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: true
  required_for: ["functional-api-advanced", "graph-vs-functional-decision", "workflows-ceo"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks", "workflows-ceo"]
status: "🟢 Novo"
next_review: "2026-08-27"
---

# 🧩 Functional API Fundamentals — Workflows com @entrypoint e @task

> **Contrato modular**: Artefato filho do Master Agent. Implementa a Functional API do LangGraph: decorators `@entrypoint` e `@task`, short-term memory, serialização, determinismo e idempotência.

## 🎯 Propósito

Fornecer uma biblioteca que permite adicionar persistência, memória e HITL a código Python existente com mínimas alterações, usando `@entrypoint` e `@task`.

## 📋 Especificação (SDD)
- **Entradas**: Funções Python comuns, configuração de checkpointer/store, parâmetros de retry/timeout
- **Saídas**: Workflow compilado (`Pregel`) com suporte a invoke/stream
- **Side Effects**: Criação de checkpoints, logging de execução de tasks
- **Constraints Aplicáveis**: C1, C2, C3, C5, C7, C8
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
# 1. DEFINIÇÃO DE TASKS E ENTRYPOINTS
# ═══════════════════════════════════════════════════════════════════════════
import time, asyncio
from typing import Any, Optional, Callable
from langgraph.func import entrypoint, task
from langgraph.checkpoint.memory import InMemorySaver
from langgraph.types import Command, interrupt, RetryPolicy, StreamWriter
from langgraph.store.base import BaseStore
from langgraph.store.memory import InMemoryStore
from langgraph.config import get_stream_writer

# --- Task simples ---
@task
def slow_computation(x: int) -> int:
    """Simula operação demorada."""
    time.sleep(0.5)
    mantis_log("DEBUG", "slow_computation_done", str(x))
    return x * 2

# --- Task com retry ---
@task(retry_policy=RetryPolicy(retry_on=ValueError, max_attempts=3))
def fallible_task(data: str) -> str:
    """Task que pode falhar e ser retentada."""
    if not data:
        raise ValueError("Dados vazios")
    return data.upper()

# --- Entrypoint com checkpointer ---
checkpointer = InMemorySaver()
store = InMemoryStore()

@entrypoint(checkpointer=checkpointer, store=store)
def simple_workflow(inputs: dict) -> dict:
    """Workflow simples com uma task."""
    result = slow_computation(inputs["value"]).result()
    return {"result": result}

# ═══════════════════════════════════════════════════════════════════════════
# 2. SHORT-TERM MEMORY (PERSISTÊNCIA ENTRE INVOCAÇÕES)
# ═══════════════════════════════════════════════════════════════════════════
@entrypoint(checkpointer=InMemorySaver())
def accumulator(number: int, *, previous: Any = None) -> int:
    """Acumula valores entre invocações usando 'previous'."""
    previous = previous or 0
    total = number + previous
    mantis_log("INFO", "accumulator", f"Input={number}, Previous={previous}, Total={total}")
    return total

@entrypoint(checkpointer=InMemorySaver())
def decoupled_workflow(value: int, *, previous: Any = None) -> entrypoint.final[int, int]:
    """Retorna 'previous' mas salva 'value * 2' no checkpoint."""
    previous = previous or 0
    mantis_log("INFO", "decoupled", f"Return={previous}, Save={value * 2}")
    return entrypoint.final(value=previous, save=value * 2)

# ═══════════════════════════════════════════════════════════════════════════
# 3. EXECUÇÃO PARALELA DE TASKS
# ═══════════════════════════════════════════════════════════════════════════
@task
async def async_api_call(endpoint: str) -> dict:
    """Simula chamada de API assíncrona."""
    await asyncio.sleep(0.3)
    return {"endpoint": endpoint, "status": "ok"}

@entrypoint(checkpointer=InMemorySaver())
async def parallel_workflow(endpoints: list[str]) -> list[dict]:
    """Executa múltiplas chamadas de API em paralelo."""
    futures = [async_api_call(ep) for ep in endpoints]
    results = [await f for f in futures]
    mantis_log("INFO", "parallel_done", f"Endpoints={len(results)}")
    return results

# ═══════════════════════════════════════════════════════════════════════════
# 4. PARÂMETROS INJETÁVEIS
# ═══════════════════════════════════════════════════════════════════════════
@entrypoint(checkpointer=InMemorySaver(), store=InMemoryStore())
def workflow_with_injection(
    inputs: dict,
    *,
    previous: Any = None,
    store: BaseStore,
    writer: StreamWriter,
) -> dict:
    """Workflow que usa parâmetros injetáveis."""
    writer(f"Processing {inputs}")
    mantis_log("INFO", "injection_workflow", f"Previous={previous}")
    return {"processed": True}

# ═══════════════════════════════════════════════════════════════════════════
# 5. GERENCIAMENTO DE EFEITOS COLATERAIS (CORRETO)
# ═══════════════════════════════════════════════════════════════════════════
@task
def write_to_file(filename: str, content: str) -> str:
    """Task que encapsula side effect de escrita em arquivo."""
    with open(filename, "w") as f:
        f.write(content)
    mantis_log("INFO", "file_written", filename)
    return f"Written to {filename}"

@entrypoint(checkpointer=InMemorySaver())
def safe_workflow(data: str) -> str:
    """Workflow que usa task para side effect seguro."""
    result = write_to_file("/tmp/output.txt", data).result()
    return result

# ═══════════════════════════════════════════════════════════════════════════
# 6. FÁBRICA DE WORKFLOWS FUNCIONAIS
# ═══════════════════════════════════════════════════════════════════════════
class FunctionalWorkflowFactory:
    """Cria workflows funcionais com configuração padrão."""
    def __init__(self, checkpointer_backend: str = "memory"):
        self.checkpointer = InMemorySaver() if checkpointer_backend == "memory" else None
        self.store = InMemoryStore()

    def create_chain(self, tasks: list[Callable]) -> Callable:
        """Cria um entrypoint que encadeia tasks sequencialmente."""
        @entrypoint(checkpointer=self.checkpointer, store=self.store)
        def chain(inputs: dict) -> dict:
            result = inputs
            for t in tasks:
                task_result = t(result).result() if callable(t) else t(result)
                if isinstance(task_result, dict):
                    result.update(task_result)
                else:
                    result["output"] = task_result
            return result
        return chain

    def create_parallel(self, tasks: list[Callable]) -> Callable:
        """Cria um entrypoint que executa tasks em paralelo."""
        @entrypoint(checkpointer=self.checkpointer, store=self.store)
        def parallel(inputs: dict) -> list:
            futures = [t(inputs) for t in tasks]
            return [f.result() for f in futures]
        return parallel
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from functional_api_fundamentals import (
    simple_workflow, accumulator, decoupled_workflow, fallible_task,
    FunctionalWorkflowFactory, slow_computation
)

def test_simple_workflow():
    result = simple_workflow.invoke({"value": 5})
    assert result["result"] == 10

def test_accumulator():
    config = {"configurable": {"thread_id": "test-acc"}}
    r1 = accumulator.invoke(1, config)
    r2 = accumulator.invoke(2, config)
    assert r1 == 1
    assert r2 == 3

def test_decoupled_workflow():
    config = {"configurable": {"thread_id": "test-dec"}}
    r1 = decoupled_workflow.invoke(3, config)
    r2 = decoupled_workflow.invoke(1, config)
    assert r1 == 0
    assert r2 == 6

def test_fallible_task():
    result = fallible_task("hello")
    assert result == "HELLO"
    with pytest.raises(ValueError):
        fallible_task("")

def test_functional_factory():
    factory = FunctionalWorkflowFactory()
    chain = factory.create_chain([slow_computation])
    result = chain.invoke({"value": 3})
    assert result["output"] == 6
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/functional-api-fundamentals.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[functional-api-advanced.md]]
- [[graph-vs-functional-decision.md]]
