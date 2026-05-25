---
artifact_id: "multi-agent-memory"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C5","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/11-swarm-supervisor/multi-agent-memory.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/11-swarm-supervisor/multi-agent-memory.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:multi-agent-memory-v1"
generated_at: "2026-05-27T09:30:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["swarm-fundamentals", "supervisor-fundamentals", "swarm-supervisor-patterns"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks", "workflows-ceo"]
status: "🟢 Novo"
next_review: "2026-08-27"
---

# 🧩 Multi-Agent Memory — Memória Compartilhada em Swarms e Supervisores

> **Contrato modular**: Artefato filho do Master Agent. Implementa integração de memória de curto e longo prazo em sistemas multi-agente, com checkpointing, store compartilhado e políticas de retenção.

## 🎯 Propósito

Garantir que enxames e supervisores mantenham contexto entre sessões e entre agentes, usando `BaseCheckpointSaver` para memória de thread e `BaseStore` para memória de longo prazo cross-thread, com suporte a namespaces e busca semântica.

## 📋 Especificação (SDD)
- **Entradas**: Configuração de checkpointer (Postgres, SQLite, Memory), store (InMemory, PostgresStore), TTL
- **Saídas**: Grafo compilado com persistência habilitada, funções de acesso à memória
- **Side Effects**: Criação de tabelas/índices, salvamento de checkpoints, logging de operações de memória
- **Constraints Aplicáveis**: C1, C2, C3, C5, C6, C7, C8
- **Dependências**: `langgraph-checkpoint`, `langgraph-checkpoint-postgres`, `langgraph-checkpoint-sqlite`, `langgraph-store`

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
# 1. FÁBRICA DE CHECKPOINTERS
# ═══════════════════════════════════════════════════════════════════════════
from langgraph.checkpoint.base import BaseCheckpointSaver
from langgraph.checkpoint.memory import InMemorySaver
from langgraph.checkpoint.sqlite import SqliteSaver, AsyncSqliteSaver
from langgraph.checkpoint.postgres import PostgresSaver, AsyncPostgresSaver

class CheckpointerFactory:
    @staticmethod
    def create(backend: str = "memory", **kwargs) -> BaseCheckpointSaver:
        if backend == "memory":
            return InMemorySaver()
        elif backend == "sqlite":
            path = kwargs.get("path", "./checkpoints.db")
            return SqliteSaver.from_conn_string(path)
        elif backend == "postgres":
            uri = kwargs.get("uri", os.getenv("DATABASE_URI", "postgresql://localhost:5432/langgraph"))
            return PostgresSaver.from_conn_string(uri)
        else:
            raise ValueError(f"Backend de checkpointer não suportado: {backend}")

# ═══════════════════════════════════════════════════════════════════════════
# 2. FÁBRICA DE STORES (MEMÓRIA DE LONGO PRAZO)
# ═══════════════════════════════════════════════════════════════════════════
from langgraph.store.base import BaseStore
from langgraph.store.memory import InMemoryStore

class StoreFactory:
    @staticmethod
    def create(backend: str = "memory", **kwargs) -> BaseStore:
        if backend == "memory":
            return InMemoryStore()
        elif backend == "sqlite":
            from langgraph.store.sqlite import SqliteStore
            path = kwargs.get("path", "./store.db")
            return SqliteStore.from_conn_string(path)
        elif backend == "postgres":
            from langgraph.store.postgres import PostgresStore
            uri = kwargs.get("uri", os.getenv("DATABASE_URI", "postgresql://localhost:5432/langgraph"))
            return PostgresStore.from_conn_string(uri)
        else:
            raise ValueError(f"Backend de store não suportado: {backend}")

# ═══════════════════════════════════════════════════════════════════════════
# 3. INTEGRAÇÃO COM SWARM E SUPERVISOR
# ═══════════════════════════════════════════════════════════════════════════
from langgraph_swarm import create_swarm
from langgraph_supervisor import create_supervisor

class MemoryAwareSwarmBuilder:
    """Constrói um enxame com memória de curto e longo prazo."""
    def __init__(self, agents, default_active: str):
        self.agents = agents
        self.default_active = default_active
        self._checkpointer = None
        self._store = None

    def with_checkpointer(self, backend: str = "memory", **kwargs):
        self._checkpointer = CheckpointerFactory.create(backend, **kwargs)
        mantis_log("INFO", "memory_checkpointer_set", backend)
        return self

    def with_store(self, backend: str = "memory", **kwargs):
        self._store = StoreFactory.create(backend, **kwargs)
        mantis_log("INFO", "memory_store_set", backend)
        return self

    def compile(self):
        builder = create_swarm(self.agents, default_active_agent=self.default_active)
        return builder.compile(checkpointer=self._checkpointer, store=self._store)

# ═══════════════════════════════════════════════════════════════════════════
# 4. GERENCIADOR DE MEMÓRIA COMPARTILHADA (CROSS-AGENT)
# ═══════════════════════════════════════════════════════════════════════════
class SharedMemoryManager:
    """API para leitura/escrita de memória compartilhada entre agentes."""
    def __init__(self, store: BaseStore, default_namespace: tuple = ("agents",)):
        self.store = store
        self.namespace = default_namespace

    async def remember(self, agent_name: str, key: str, value: dict):
        full_key = f"{agent_name}:{key}"
        await self.store.aput(self.namespace, full_key, value)
        mantis_log("DEBUG", "memory_stored", f"Agent={agent_name}, Key={key}")

    async def recall(self, agent_name: str, key: str) -> Optional[dict]:
        full_key = f"{agent_name}:{key}"
        item = await self.store.aget(self.namespace, full_key)
        if item:
            mantis_log("DEBUG", "memory_recalled", f"Agent={agent_name}, Key={key}")
            return item.value
        return None

    async def search(self, query: str, limit: int = 5) -> list:
        results = await self.store.asearch(self.namespace, query=query, limit=limit)
        return [r.value for r in results]

# ═══════════════════════════════════════════════════════════════════════════
# 5. POLÍTICA DE RETENÇÃO E TTL
# ═══════════════════════════════════════════════════════════════════════════
class MemoryRetentionPolicy:
    def __init__(self, default_ttl_seconds: int = 86400):
        self.default_ttl = default_ttl_seconds

    def apply_to_thread(self, checkpointer: BaseCheckpointSaver, thread_id: str, ttl: int = None):
        ttl = ttl or self.default_ttl
        if hasattr(checkpointer, "set_ttl"):
            checkpointer.set_ttl(thread_id, ttl)
            mantis_log("INFO", "retention_set", f"Thread={thread_id}, TTL={ttl}s")
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from multi_agent_memory import CheckpointerFactory, StoreFactory, MemoryAwareSwarmBuilder, SharedMemoryManager
from langgraph.checkpoint.memory import InMemorySaver
from langgraph.store.memory import InMemoryStore
from langchain.agents import create_agent
from langchain.chat_models import init_chat_model

@pytest.fixture
def dummy_agent():
    model = init_chat_model("deepseek-chat", model_provider="deepseek", temperature=0)
    return create_agent(model, tools=[], system_prompt="Test", name="agent1")

def test_checkpointer_factory_memory():
    cp = CheckpointerFactory.create("memory")
    assert isinstance(cp, InMemorySaver)

def test_store_factory_memory():
    store = StoreFactory.create("memory")
    assert isinstance(store, InMemoryStore)

def test_memory_aware_swarm(dummy_agent):
    builder = MemoryAwareSwarmBuilder([dummy_agent], "agent1")
    builder.with_checkpointer("memory").with_store("memory")
    graph = builder.compile()
    assert graph is not None

@pytest.mark.asyncio
async def test_shared_memory():
    store = InMemoryStore()
    await store.setup()
    manager = SharedMemoryManager(store)
    await manager.remember("agent1", "key1", {"data": "value"})
    val = await manager.recall("agent1", "key1")
    assert val["data"] == "value"
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/11-swarm-supervisor/multi-agent-memory.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[swarm-fundamentals.md]]
- [[supervisor-fundamentals.md]]
