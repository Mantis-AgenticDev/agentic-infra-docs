---
artifact_id: "deep-agents-threads-lifecycle"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-threads-lifecycle.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-threads-lifecycle.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-threads-lifecycle-v1.0.0"
generated_at: "2026-05-26T03:45:00Z"
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

# 🧵 Deep Agents – Ciclo de Vida de Threads

> **Contrato modular**: Artefato filho do Master Agent. Detalha a criação, retenção, recuperação e gerenciamento de threads em Managed Deep Agents, incluindo vinculação com `contextId` de A2A e testes paralelos.

---

## 🎯 Propósito
Permitir que o ecossistema MANTIS gerencie conversas de longa duração com estado persistente, criando, recuperando e monitorando threads de execução de agentes.

## 📋 Especificação (SDD)
- **Entradas**: Agent ID, configurações de thread.
- **Saídas**: Thread criada e executável.
- **Side Effects**: Estado persistido no LangSmith.
- **Constraints Aplicáveis**: C1 (schema de thread), C5 (persistência), C7 (retry), C8 (logs), C9 (thread_id).
- **Dependências**: `httpx`, `langsmith`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Criação de Thread

```python
def create_thread(agent_id, test_run=False, skip_memory_protection=False):
    response = httpx.post(
        f"{BASE_URL}/threads",
        headers=HEADERS,
        json={
            "agent_id": agent_id,
            "options": {
                "test_run": test_run,
                "skip_memory_write_protection": skip_memory_protection,
            },
        },
    )
    response.raise_for_status()
    thread = response.json()
    mantis_log("INFO", "thread_created", f"ID: {thread['id']}")
    return thread
```

### 2. Listagem de Threads

```python
def list_threads(agent_id=None):
    params = {"agent_id": agent_id} if agent_id else {}
    response = httpx.get(f"{BASE_URL}/threads", headers=HEADERS, params=params)
    response.raise_for_status()
    threads = response.json()
    mantis_log("INFO", "threads_listed", f"Total: {len(threads)}")
    return threads
```

### 3. Recuperação de Estado da Thread

```python
def get_thread_state(thread_id):
    response = httpx.get(f"{BASE_URL}/threads/{thread_id}", headers=HEADERS)
    response.raise_for_status()
    state = response.json()
    mantis_log("INFO", "thread_state", f"ID: {thread_id}")
    return state
```

### 4. Execução de Run em Thread Existente

```python
def run_thread(thread_id, agent_id, messages, wait=True):
    response = httpx.post(
        f"{BASE_URL}/threads/{thread_id}/runs",
        headers=HEADERS,
        json={"agent_id": agent_id, "messages": messages},
    )
    response.raise_for_status()
    run = response.json()
    mantis_log("INFO", "run_started", f"Run: {run.get('id')}, Thread: {thread_id}")
    return run
```

### 5. Paralelismo de Threads

```python
import asyncio

async def run_parallel_threads(agent_id, tasks):
    async def run_single(task):
        thread = create_thread(agent_id)
        return stream_run(thread["id"], agent_id, [{"role": "user", "content": task}])

    results = await asyncio.gather(*[run_single(t) for t in tasks])
    return results
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_thread_creation():
    payload = {"agent_id": "agent-123", "options": {"test_run": False}}
    assert "agent_id" in payload
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-threads-lifecycle.md --json
```

---

## 🔗 Referências Cruzadas
- [[deep-agents-managed-api.md]]
