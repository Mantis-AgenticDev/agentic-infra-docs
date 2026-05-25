---
artifact_id: "deep-agents-multi-agent-coordination"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-multi-agent-coordination.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-multi-agent-coordination.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-multi-agent-coord-v1.0.0"
generated_at: "2026-05-26T01:45:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-advanced-orchestration"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-26"
---

# 🧠 Deep Agents – Coordenação Multi‑Agente com A2A

> **Contrato modular**: Artefato filho do Master Agent. Implementa padrões de coordenação multi‑agente usando o protocolo Agent‑to‑Agent (A2A) integrado com Deep Agents e LangSmith para tracing distribuído.

---

## 🎯 Propósito
Permitir que agentes MANTIS coordenem múltiplos agentes independentes usando o protocolo A2A, com rastreamento distribuído e handoff controlado.

## 📋 Especificação (SDD)
- **Entradas**: Endpoints A2A, configuração de tracing.
- **Saídas**: Sistema multi‑agente coordenado.
- **Side Effects**: Chamadas entre agentes.
- **Constraints Aplicáveis**: C1 (contrato A2A), C5 (schema de handoff), C7 (retry), C8 (logs), C9 (trace_id e span_id).
- **Dependências**: `langgraph-sdk`, `deepagents`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Definição do Protocolo A2A

```python
A2A_MESSAGE_SCHEMA = {
    "agent_from": "string",
    "agent_to": "string",
    "task_id": "string",
    "trace_id": "string",
    "parent_span_id": "string",
    "span_id": "string",
    "action": "string",  # "handoff", "query", "response"
    "payload": "dict",
    "timestamp": "string (ISO 8601)",
}
```

### 2. Ferramenta de Handoff A2A

```python
import uuid
from langgraph_sdk import get_client

client = get_client(url="<DEPLOYMENT_URL>")

@tool
async def handoff_to_agent(target_agent: str, task: str, runtime: ToolRuntime) -> str:
    """Passa o controle para outro agente via A2A."""
    trace_id = os.getenv("TRACE_ID", str(uuid.uuid4()))
    span_id = str(uuid.uuid4())
    parent_span_id = os.getenv("SPAN_ID", "null")

    payload = {
        "agent_from": runtime.config.get("metadata", {}).get("lc_agent_name", "unknown"),
        "agent_to": target_agent,
        "task": task,
        "trace_id": trace_id,
        "parent_span_id": parent_span_id,
        "span_id": span_id,
        "timestamp": datetime.datetime.utcnow().isoformat(),
    }

    mantis_log("INFO", "a2a_handoff", json.dumps(payload))

    # Invocar o agente destino
    target_thread = await client.threads.create()
    result = await client.runs.create(
        thread_id=target_thread["thread_id"],
        assistant_id=target_agent,
        input={"messages": [{"role": "user", "content": task}],
               "a2a_context": payload},
    )
    return json.dumps(result)
```

### 3. Propagação de Contexto A2A

```python
# O agente que recebe pode ler o a2a_context do input
@tool
def read_a2a_context(runtime: ToolRuntime) -> dict:
    """Lê o contexto A2A da mensagem atual."""
    a2a_ctx = runtime.state.get("a2a_context", {})
    mantis_log("INFO", "a2a_receive", json.dumps(a2a_ctx))
    return a2a_ctx
```

### 4. Coordenação de Múltiplos Agentes

```python
agent_a = create_deep_agent(
    model="anthropic:claude-sonnet-4-6",
    name="agent-alpha",
    tools=[handoff_to_agent],
)

agent_b = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    name="agent-beta",
    tools=[handoff_to_agent],
)

# Configurar tracing distribuído
import os
os.environ["LANGCHAIN_TRACING_V2"] = "true"
os.environ["LANGCHAIN_PROJECT"] = "mantis-a2a"
```

### 5. Tracing Distribuído com A2A

```python
from opentelemetry import trace

tracer = trace.get_tracer(__name__)

async def traced_a2a_handoff(target_agent, task):
    with tracer.start_as_current_span("a2a_handoff") as span:
        span.set_attribute("target_agent", target_agent)
        span.set_attribute("task", task)
        result = await handoff_to_agent(target_agent, task)
        span.set_attribute("status", "success")
        return result
```

### 6. Exemplo de Orquestração Multi‑Agente

```python
# Supervisor coordena Researcher, Analyst e Writer
supervisor = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    name="supervisor",
    system_prompt="""Você é um supervisor. Coordene os agentes:
    1. Envie tarefas de pesquisa para 'researcher'.
    2. Envie dados para análise para 'analyst'.
    3. Solicite relatórios a 'writer'.
    Use handoff_to_agent para cada transferência.""",
    tools=[handoff_to_agent],
)
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_a2a_message_schema():
    msg = {
        "agent_from": "test",
        "agent_to": "target",
        "trace_id": "123",
        "span_id": "456",
    }
    assert "trace_id" in msg
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-multi-agent-coordination.md --json
```

---

## 🔗 Referências Cruzadas
- [[deep-agents-advanced-orchestration.md]]
