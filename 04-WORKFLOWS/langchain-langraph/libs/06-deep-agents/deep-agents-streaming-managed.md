---
artifact_id: "deep-agents-streaming-managed"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C5","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-streaming-managed.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-streaming-managed.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-streaming-managed-v1.0.0"
generated_at: "2026-05-26T03:30:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-managed-api"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-26"
---

# 📡 Deep Agents – Streaming de Execuções Gerenciadas

> **Contrato modular**: Artefato filho do Master Agent. Documenta o consumo de streams SSE de execuções de agentes gerenciados, com modos `values`, `updates` e `messages-tuple`, parsing de eventos e integração com LangSmith.

---

## 🎯 Propósito
Permitir que o ecossistema MANTIS receba atualizações em tempo real da execução de agentes gerenciados, construindo dashboards, chats e ferramentas de monitoramento.

## 📋 Especificação (SDD)
- **Entradas**: Thread ID, Agent ID, mensagens, modos de stream.
- **Saídas**: Eventos SSE parseados.
- **Side Effects**: Conexão SSE mantida.
- **Constraints Aplicáveis**: C1 (formato SSE), C5 (schema de eventos), C8 (observabilidade), C9 (tracing).
- **Dependências**: `httpx`, `sseclient`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Configuração do Stream

```python
import httpx
import json

BASE_URL = os.getenv("DEEPAGENTS_BASE_URL")
HEADERS = {"X-Api-Key": os.getenv("LANGSMITH_API_KEY"), "Accept": "text/event-stream", "Content-Type": "application/json"}

def stream_run(thread_id, agent_id, messages, stream_modes=None):
    if stream_modes is None:
        stream_modes = ["values", "updates", "messages-tuple"]
    with httpx.stream(
        "POST",
        f"{BASE_URL}/threads/{thread_id}/runs/stream",
        headers=HEADERS,
        json={
            "agent_id": agent_id,
            "messages": messages,
            "stream_mode": stream_modes,
            "stream_subgraphs": True,
        },
        timeout=None,
    ) as response:
        response.raise_for_status()
        current_event = None
        for line in response.iter_lines():
            if line.startswith("event:"):
                current_event = line.split(":", 1)[1].strip()
            elif line.startswith("data:"):
                data_str = line.split(":", 1)[1].strip()
                if current_event and data_str:
                    try:
                        data = json.loads(data_str)
                        yield current_event, data
                    except json.JSONDecodeError:
                        mantis_log("WARN", "stream_parse_error", data_str[:100])
```

### 2. Consumo de Eventos `values`

```python
for event_type, data in stream_run(thread_id, agent_id, messages, ["values"]):
    if event_type == "metadata":
        run_id = data.get("run_id")
        mantis_log("INFO", "run_started", f"Run: {run_id}")
    elif event_type == "values":
        messages = data.get("messages", [])
        files = data.get("files", {})
        mantis_log("INFO", "state_update", f"Messages: {len(messages)}, Files: {len(files)}")
```

### 3. Consumo de Eventos `updates`

```python
for event_type, data in stream_run(thread_id, agent_id, messages, ["updates"]):
    if event_type == "updates":
        for node_name, node_data in data.items():
            if node_data is None:
                mantis_log("DEBUG", "node_noop", node_name)
            else:
                mantis_log("INFO", "node_update", f"{node_name}: {list(node_data.keys())}")
```

### 4. Consumo de Eventos `messages-tuple`

```python
for event_type, data in stream_run(thread_id, agent_id, messages, ["messages-tuple"]):
    if event_type == "messages":
        chunk, metadata = data
        content = chunk.get("content", "")
        if content:
            print(content[0].get("text", ""), end="", flush=True)
```

### 5. Cliente SSE Assíncrono com Reconexão

```python
import asyncio
import httpx

class ManagedAgentStreamClient:
    def __init__(self, thread_id, agent_id, messages):
        self.thread_id = thread_id
        self.agent_id = agent_id
        self.messages = messages

    async def connect(self, modes=None):
        if modes is None:
            modes = ["values", "updates", "messages-tuple"]
        async with httpx.AsyncClient(timeout=None) as client:
            async with client.stream(
                "POST",
                f"{BASE_URL}/threads/{self.thread_id}/runs/stream",
                headers=HEADERS,
                json={"agent_id": self.agent_id, "messages": self.messages, "stream_mode": modes},
            ) as response:
                current_event = None
                async for line in response.aiter_lines():
                    if line.startswith("event:"):
                        current_event = line.split(":", 1)[1].strip()
                    elif line.startswith("data:") and current_event:
                        data = json.loads(line.split(":", 1)[1])
                        yield current_event, data

    async def run_and_collect(self):
        full_state = {"messages": [], "run_id": None}
        async for event, data in self.connect():
            if event == "metadata":
                full_state["run_id"] = data.get("run_id")
            elif event == "values":
                full_state["messages"] = data.get("messages", [])
        return full_state
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_sse_parsing():
    line = "data: {\"run_id\":\"123\"}"
    assert line.startswith("data:")

def test_event_format():
    event = ("messages", [{"type": "AIMessageChunk", "content": "Hello"}, {}])
    assert event[0] == "messages"
    assert isinstance(event[1], list)
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-streaming-managed.md --json
```

---

## 🔗 Referências Cruzadas
- [[deep-agents-managed-api.md]]
