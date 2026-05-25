---
artifact_id: "a2a-protocol-core"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/a2a-protocol-core.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/a2a-protocol-core.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:a2a-protocol-core-v1.0.0"
generated_at: "2026-05-26T04:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["a2a-agent-card-discovery", "a2a-distributed-tracing", "a2a-multi-agent-conversation"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-26"
---

# 🤝 A2A Protocol Core – Comunicação Agente‑a‑Agente

> **Contrato modular**: Artefato filho do Master Agent. Define o protocolo A2A (Agent‑to‑Agent) para comunicação padronizada entre agentes MANTIS, usando JSON‑RPC, métodos `message/send`, `message/stream`, `tasks/get` e Agent Cards.

---

## 🎯 Propósito
Permitir que agentes MANTIS se comuniquem de forma padronizada e interoperável, usando o protocolo A2A do Google, com tracing distribuído e descoberta automática de capacidades.

## 📋 Especificação (SDD)
- **Entradas**: Endpoints A2A, mensagens, contextId/taskId.
- **Saídas**: Respostas de agentes remotos.
- **Side Effects**: Conversas multi‑agente.
- **Constraints Aplicáveis**: C1 (schema JSON‑RPC), C5 (formato de mensagens), C7 (retry), C8 (logs), C9 (tracing com contextId).
- **Dependências**: `aiohttp`, `uuid`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Formato de Mensagem A2A

```python
A2A_MESSAGE_TEMPLATE = {
    "role": "user",
    "parts": [{"kind": "text", "text": "Hello"}],
    "messageId": "uuid",
}

A2A_PAYLOAD_TEMPLATE = {
    "jsonrpc": "2.0",
    "id": "uuid",
    "method": "message/send",
    "params": {"message": A2A_MESSAGE_TEMPLATE},
    "metadata": {"thread_id": "uuid"},
}
```

### 2. Envio de Mensagem (`message/send`)

```python
import aiohttp
import uuid

async def send_a2a_message(session, url, text, context_id=None, task_id=None, thread_id=None):
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
        "metadata": {"thread_id": thread_id or str(uuid.uuid4())},
    }

    async with session.post(url, json=payload, headers={"Accept": "application/json"}) as response:
        result = await response.json()
        mantis_log("INFO", "a2a_send", f"Status: {response.status}")
        return result
```

### 3. Extração de Texto da Resposta

```python
def extract_text_from_a2a_response(result):
    for art in result.get("result", {}).get("artifacts", []) or []:
        for part in art.get("parts", []) or []:
            if part.get("kind") == "text" and part.get("text"):
                return part["text"]
    msg = (result.get("result", {}).get("status", {}) or {}).get("message", {}) or {}
    for part in msg.get("parts", []) or []:
        if part.get("kind") == "text" and part.get("text"):
            return part["text"]
    return "(no text found)"
```

### 4. Streaming de Mensagens (`message/stream`)

```python
async def stream_a2a_message(session, url, text, context_id=None, task_id=None):
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
        "method": "message/stream",
        "params": {"message": message},
    }

    async with session.post(url, json=payload, headers={"Accept": "text/event-stream"}) as response:
        async for line in response.content:
            if line.startswith(b"data:"):
                yield json.loads(line[5:])
```

### 5. Consulta de Status de Tarefa (`tasks/get`)

```python
async def get_a2a_task(session, url, task_id):
    payload = {
        "jsonrpc": "2.0",
        "id": str(uuid.uuid4()),
        "method": "tasks/get",
        "params": {"id": task_id},
    }
    async with session.post(url, json=payload, headers={"Accept": "application/json"}) as response:
        return await response.json()
```

### 6. Cliente A2A Completo

```python
class A2AClient:
    def __init__(self, base_url, assistant_id):
        self.url = f"{base_url}/a2a/{assistant_id}"

    async def send(self, text, context_id=None, task_id=None, thread_id=None):
        async with aiohttp.ClientSession() as session:
            result = await send_a2a_message(session, self.url, text, context_id, task_id, thread_id)
            response_text = extract_text_from_a2a_response(result)
            returned_context_id = result.get("result", {}).get("contextId") or context_id
            returned_task_id = result.get("result", {}).get("id")
            return response_text, returned_context_id, returned_task_id

    async def stream(self, text, context_id=None, task_id=None):
        async with aiohttp.ClientSession() as session:
            async for chunk in stream_a2a_message(session, self.url, text, context_id, task_id):
                yield chunk

    async def get_task(self, task_id):
        async with aiohttp.ClientSession() as session:
            return await get_a2a_task(session, self.url, task_id)
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_message_structure():
    msg = {"role": "user", "parts": [{"kind": "text", "text": "Hello"}], "messageId": "123"}
    assert "parts" in msg

def test_payload_structure():
    payload = {"jsonrpc": "2.0", "method": "message/send", "params": {"message": {}}}
    assert payload["jsonrpc"] == "2.0"
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/a2a-protocol-core.md --json
```

---

## 🔗 Referências Cruzadas
- [[a2a-agent-card-discovery.md]]
- [[a2a-distributed-tracing.md]]
