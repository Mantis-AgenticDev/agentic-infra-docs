---
artifact_id: "deep-agents-memory-long-term"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C4","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-memory-long-term.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-memory-long-term.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-memory-v1.0.0"
generated_at: "2026-05-25T15:30:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-backends-store", "deep-agents-memory-scopes"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🧠 Deep Agents – Memória de Longo Prazo

> **Contrato modular**: Artefato filho do Master Agent. Documenta como implementar memória persistente entre sessões usando arquivos AGENTS.md e StoreBackend, com escopos por usuário, agente e organização, e consolidação em background.

---

## 🎯 Propósito
Permitir que agentes MANTIS aprendam e evoluam através de conversas, armazenando preferências, fatos e políticas em arquivos de memória que persistem entre sessões.

## 📋 Especificação (SDD)
- **Entradas**: Arquivos de memória, backend StoreBackend, namespace.
- **Saídas**: Agente capaz de ler/atualizar memórias.
- **Side Effects**: Escritas no store.
- **Constraints Aplicáveis**: C1 (formato AGENTS.md), C3 (proteção de dados pessoais), C4 (isolamento de usuários), C5 (schema de arquivos), C7 (conflitos de escrita), C8 (auditoria), C9 (thread_id).
- **Dependências**: `deepagents`, `langgraph.store`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    import json, datetime, os
    def mantis_log(level, event, detail=""):
        entry = {"ts": datetime.datetime.utcnow().isoformat() + "Z", "level": level, "tenant": os.getenv("TENANT_ID", "global"), "event": event, "detail": detail, "trace_id": os.getenv("TRACE_ID", "null"), "span_id": os.getenv("SPAN_ID", "null"), "fallback": "true"}
        print(json.dumps(entry), flush=True)
```

### 1. Memória por Agente (Compartilhada entre Usuários)

```python
from deepagents import create_deep_agent
from deepagents.backends import CompositeBackend, StateBackend, StoreBackend
from langgraph.store.memory import InMemoryStore

agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    memory=["/memories/AGENTS.md"],
    skills=["/skills/"],
    backend=CompositeBackend(
        default=StateBackend(),
        routes={
            "/memories/": StoreBackend(namespace=lambda rt: (rt.server_info.assistant_id,)),
            "/skills/": StoreBackend(namespace=lambda rt: (rt.server_info.assistant_id,)),
        },
    ),
    store=InMemoryStore(),
)
```

### 2. Memória por Usuário (Isolada)

```python
agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    memory=["/memories/preferences.md"],
    backend=CompositeBackend(
        default=StateBackend(),
        routes={
            "/memories/": StoreBackend(namespace=lambda rt: (rt.server_info.user.identity,)),
        },
    ),
    store=InMemoryStore(),
)
```

### 3. Seed de Memória Inicial

```python
from deepagents.backends.utils import create_file_data

store = InMemoryStore()
store.put(
    ("my-agent",),
    "/memories/AGENTS.md",
    create_file_data("""## Estilo de Resposta
- Respostas concisas
- Use exemplos de código quando possível
- Prefira Python para exemplos"""),
)
```

### 4. Memória de Organização (Políticas Compartilhadas)

```python
agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    memory=[
        "/memories/preferences.md",
        "/policies/compliance.md",
    ],
    backend=CompositeBackend(
        default=StateBackend(),
        routes={
            "/memories/": StoreBackend(namespace=lambda rt: (rt.server_info.user.identity,)),
            "/policies/": StoreBackend(namespace=lambda rt: (rt.context.org_id,)),
        },
    ),
    permissions=[
        FilesystemPermission(operations=["write"], paths=["/policies/**"], mode="deny"),
    ],
)
```

### 5. Memória Episódica (Busca em Conversas Passadas)

```python
from langgraph_sdk import get_client
from langchain.tools import tool, ToolRuntime

client = get_client(url="<DEPLOYMENT_URL>")

@tool
async def search_past_conversations(query: str, runtime: ToolRuntime) -> str:
    """Busca conversas passadas por contexto relevante."""
    user_id = runtime.server_info.user.identity
    threads = await client.threads.search(metadata={"user_id": user_id}, limit=5)
    results = []
    for thread in threads:
        history = await client.threads.get_history(thread_id=thread["thread_id"])
        results.append(history)
    return str(results)
```

### 6. Consolidação em Background (Cron Job)

```python
# Agente de consolidação (definido em consolidation_agent.py)
from deepagents import create_deep_agent
from datetime import datetime, timedelta, timezone

@tool
async def search_recent_conversations(query: str, runtime: ToolRuntime) -> str:
    user_id = runtime.server_info.user.identity
    since = datetime.now(timezone.utc) - timedelta(hours=6)
    threads = await sdk_client.threads.search(
        metadata={"user_id": user_id},
        updated_after=since.isoformat(),
        limit=20,
    )
    # ... processa threads

agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    system_prompt="Revise conversas recentes e atualize o arquivo de memória do usuário.",
    tools=[search_recent_conversations],
)
```

```python
# Registro do cron job
cron_job = await client.crons.create(
    assistant_id="consolidation_agent",
    schedule="0 */6 * * *",
    input={"messages": [{"role": "user", "content": "Consolidate recent memories."}]},
)
```

### 7. Read‑Only vs Writable Memory

```python
# Memória writable (padrão): agente pode editar via edit_file
# Memória read-only: use permissões para negar escritas
permissions=[
    FilesystemPermission(operations=["write"], paths=["/policies/**"], mode="deny"),
    FilesystemPermission(operations=["read", "write"], paths=["/memories/**"], mode="allow"),
]
```

### 8. Múltiplos Agentes no Mesmo Deploy

```python
StoreBackend(
    namespace=lambda rt: (
        rt.server_info.assistant_id,
        rt.server_info.user.identity,
    ),
)
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_memory_file_seed():
    store = InMemoryStore()
    store.put(("agent",), "/memories/test.md", create_file_data("hello"))
    item = store.get(("agent",), "/memories/test.md")
    assert item.value["content"] == "hello"

def test_user_isolation():
    store = InMemoryStore()
    store.put(("alice",), "/prefs.md", create_file_data("Alice preferences"))
    store.put(("bob",), "/prefs.md", create_file_data("Bob preferences"))
    assert "Alice" in store.get(("alice",), "/prefs.md").value["content"]
    assert "Bob" in store.get(("bob",), "/prefs.md").value["content"]
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-memory-long-term.md --json
```

---

## 🔗 Referências Cruzadas
- [[deep-agents-backends-store.md]]
- [[deep-agents-memory-scopes.md]]
