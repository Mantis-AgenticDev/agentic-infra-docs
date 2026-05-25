---
artifact_id: "a2a-distributed-tracing"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C5","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/a2a-distributed-tracing.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/a2a-distributed-tracing.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:a2a-distributed-tracing-v1.0.0"
generated_at: "2026-05-26T04:30:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["a2a-protocol-core", "a2a-multi-agent-conversation"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-26"
---

# 🔍 A2A Distributed Tracing – Trazabilidade Multi‑Agente

> **Contrato modular**: Artefato filho do Master Agent. Documenta como configurar tracing distribuído para conversas multi‑agente usando o protocolo A2A, com mapeamento de `contextId` para `thread_id` e integração com LangSmith e OpenTelemetry.

---

## 🎯 Propósito
Garantir que todas as interações entre agentes MANTIS sejam rastreáveis em um único thread no LangSmith, facilitando auditoria, depuração e otimização do swarm.

## 📋 Especificação (SDD)
- **Entradas**: contextId, thread_id, configuração de tracing.
- **Saídas**: Traces agrupados no LangSmith.
- **Side Effects**: Envio de spans para LangSmith.
- **Constraints Aplicáveis**: C1 (mapeamento contextId→thread_id), C5 (schema de metadata), C8 (observabilidade), C9 (tracing distribuído).
- **Dependências**: `langsmith`, `opentelemetry`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Mapeamento contextId → thread_id no Servidor

```python
# O Agent Server do LangGraph faz automaticamente:
# contextId (A2A) → thread_id (LangSmith)
# Isso agrupa todas as mensagens de uma conversa em um único thread.
```

### 2. Propagação de thread_id no Cliente

```python
import uuid

async def send_with_tracing(session, url, text, context_id=None, task_id=None):
    # Gerar thread_id se for a primeira mensagem
    if not context_id:
        thread_id = str(uuid.uuid4())
    else:
        thread_id = context_id  # Usar contextId como thread_id

    message = {
        "role": "user",
        "parts": [{"kind": "text", "text": text}],
        "messageId": str(uuid.uuid4()),
    }
    if context_id:
        message["contextId"] = context_id
    if task_id:
        message["taskId"] = task_id

    payload = {
        "jsonrpc": "2.0",
        "id": str(uuid.uuid4()),
        "method": "message/send",
        "params": {"message": message},
        "metadata": {"thread_id": thread_id},  # Propagar thread_id
    }

    async with session.post(url, json=payload) as response:
        result = await response.json()
        returned_context_id = result.get("result", {}).get("contextId") or context_id
        mantis_log("INFO", "trace_propagated", f"contextId: {returned_context_id}, thread_id: {thread_id}")
        return result, returned_context_id, thread_id
```

### 3. Extração de thread_id em Agentes Não‑LangGraph (FastAPI)

```python
from fastapi import FastAPI, Request
from langsmith.integrations.otel import configure as configure_otel
from opentelemetry import trace

configure_otel(project_name="mantis-a2a")
tracer = trace.get_tracer(__name__)

app = FastAPI()

@app.middleware("http")
async def set_thread_id_middleware(request: Request, call_next):
    thread_id = None
    if request.method == "POST":
        body_bytes = await request.body()
        if body_bytes:
            try:
                body = json.loads(body_bytes)
                thread_id = body.get("metadata", {}).get("thread_id")
                mantis_log("INFO", "thread_id_extracted", f"Thread: {thread_id}")
            except Exception:
                pass
            async def receive():
                return {"type": "http.request", "body": body_bytes}
            request._receive = receive

    with tracer.start_as_current_span("agent") as span:
        if thread_id:
            span.set_attribute("langsmith.metadata.thread_id", thread_id)
        return await call_next(request)
```

### 4. Configuração do LangSmith

```python
import os
os.environ["LANGSMITH_API_KEY"] = "ls__..."
os.environ["LANGSMITH_PROJECT"] = "mantis-a2a"
# Todos os agentes devem usar o mesmo projeto para traces unificados.
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_thread_id_propagation():
    payload = {"metadata": {"thread_id": "test-thread-123"}}
    assert payload["metadata"]["thread_id"] == "test-thread-123"
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/a2a-distributed-tracing.md --json
```

---

## 🔗 Referências Cruzadas
- [[a2a-protocol-core.md]]
- [[a2a-multi-agent-conversation.md]]
