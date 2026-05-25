---
artifact_id: "langchain-long-term-memory"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/langchain-long-term-memory.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/langchain-long-term-memory.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:langchain-long-term-memory-v1.0.0"
generated_at: "2026-05-26T14:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["langchain-hitl-middleware", "langchain-agents-orchestration"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-26"
---

# 🧠 LangChain Long‑Term Memory – Memória Persistente com Stores

> **Contrato modular**: Artefato filho do Master Agent. Ensina a adicionar memória de longo prazo a agentes LangChain tradicionais (`create_agent`) usando `InMemoryStore` e `PostgresStore`, com leitura/escrita via ferramentas, namespaces e busca semântica por embeddings.

---

## 🎯 Propósito
Permitir que agentes MANTIS tradicionais armazenem e recuperem informações entre sessões e conversas, usando o sistema de stores do LangGraph (`BaseStore`) com suporte a embeddings para busca semântica.

## 📋 Especificação (SDD)
- **Entradas**: Store configurada (`InMemoryStore` ou `PostgresStore`), namespace, chave, dados JSON.
- **Saídas**: Agente capaz de persistir e consultar memórias.
- **Side Effects**: Escritas persistentes no store.
- **Constraints Aplicáveis**: C1 (schema de dados), C3 (proteção de dados pessoais), C5 (formato JSON), C7 (retry em falhas de store), C8 (logs de acesso), C9 (correlação com thread_id).
- **Dependências**: `langgraph.store.memory`, `langgraph.store.postgres`.

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

### 1. Configuração de Store (InMemory e PostgreSQL)

```python
from langgraph.store.memory import InMemoryStore

store = InMemoryStore()
agent = create_agent("claude-sonnet-4-6", tools=[], store=store)

# PostgreSQL
from langgraph.store.postgres import PostgresStore
DB_URI = "postgresql://postgres:postgres@localhost:5432/postgres?sslmode=disable"
with PostgresStore.from_conn_string(DB_URI) as store:
    store.setup()
    agent = create_agent("claude-sonnet-4-6", tools=[], store=store)
```

### 2. Ferramenta de Leitura de Memória

```python
from dataclasses import dataclass
from langchain.tools import ToolRuntime, tool

@dataclass
class Context:
    user_id: str

@tool
def get_user_info(runtime: ToolRuntime[Context]) -> str:
    """Busca informações do usuário na memória de longo prazo."""
    assert runtime.store is not None
    user_id = runtime.context.user_id
    item = runtime.store.get(("users",), user_id)
    if item:
        mantis_log("INFO", "memory_read", f"User: {user_id}")
        return str(item.value)
    return "Usuário desconhecido"

agent = create_agent(
    "claude-sonnet-4-6",
    tools=[get_user_info],
    store=store,
    context_schema=Context,
)
```

### 3. Ferramenta de Escrita de Memória

```python
@tool
def save_user_info(user_info: dict, runtime: ToolRuntime[Context]) -> str:
    """Salva informações do usuário na memória de longo prazo."""
    assert runtime.store is not None
    user_id = runtime.context.user_id
    runtime.store.put(("users",), user_id, user_info)
    mantis_log("INFO", "memory_write", f"User: {user_id}")
    return "Informações salvas com sucesso."
```

### 4. Organização com Namespaces e Keys

```python
# Namespace = ("users",)  → agrupa dados de usuários
# Key = user_id           → identifica o registro

store.put(("users",), "user_123", {"name": "John", "language": "English"})
store.put(("users",), "user_456", {"name": "Maria", "language": "Português"})

# Recuperação
item = store.get(("users",), "user_123")
print(item.value)  # {"name": "John", "language": "English"}
```

### 5. Busca Semântica com Embeddings

```python
from langgraph.store.base import IndexConfig
from langchain_openai import OpenAIEmbeddings

embeddings = OpenAIEmbeddings()

def embed_fn(texts):
    return embeddings.embed_documents(texts)

store = InMemoryStore(
    index=IndexConfig(embed=embed_fn, dims=1536)
)

# Busca semântica por similaridade
items = store.search(
    ("users",),
    query="preferências de idioma",
    filter={"language": "Português"},
)
```

### 6. Exemplo Completo: Agente com Memória Persistente

```python
from langchain.agents import create_agent
from langgraph.store.memory import InMemoryStore
from dataclasses import dataclass
from langchain.tools import ToolRuntime, tool

store = InMemoryStore()
store.put(("users",), "alice", {"name": "Alice", "preferences": "respostas concisas"})

@dataclass
class Context:
    user_id: str

@tool
def get_preferences(runtime: ToolRuntime[Context]) -> str:
    assert runtime.store is not None
    item = runtime.store.get(("users",), runtime.context.user_id)
    return item.value.get("preferences", "") if item else ""

agent = create_agent(
    "openai:gpt-5.4",
    tools=[get_preferences],
    store=store,
    context_schema=Context,
)

result = agent.invoke(
    {"messages": [{"role": "user", "content": "Quais são minhas preferências?"}]},
    context=Context(user_id="alice"),
)
```

---

## 🧪 Testes Unitários (TDD)

```python
from langgraph.store.memory import InMemoryStore

def test_store_put_get():
    store = InMemoryStore()
    store.put(("test",), "key1", {"data": 42})
    item = store.get(("test",), "key1")
    assert item.value == {"data": 42}

def test_store_search():
    store = InMemoryStore()
    store.put(("test",), "a", {"lang": "pt"})
    store.put(("test",), "b", {"lang": "en"})
    items = store.search(("test",), filter={"lang": "pt"})
    assert len(items) == 1
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/langchain-long-term-memory.md --json
```

---

## 🔗 Referências Cruzadas
- [[langchain-hitl-middleware.md]]
- [[langchain-agents-orchestration.md]]
