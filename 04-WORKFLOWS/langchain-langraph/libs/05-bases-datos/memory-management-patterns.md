---
artifact_id: "memory-management-patterns"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C5","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/05-bases-datos/memory-management-patterns.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/05-bases-datos/memory-management-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:memory-management-v1"
generated_at: "2026-05-27T17:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["multi-agent-memory", "langgraph-state-graph-fundamentals", "workflows-ceo"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks", "workflows-ceo"]
status: "🟢 Novo"
next_review: "2026-08-27"
---

# 🧩 Memory Management Patterns — Estratégias de Gestão de Contexto e Persistência

> **Contrato modular**: Artefato filho do Master Agent. Implementa padrões de gestão de memória: trim, delete, summarize de mensagens, gerenciamento de checkpoints e integração com múltiplos backends (Postgres, Redis, SQLite, MongoDB, Oracle).

## 🎯 Propósito

Fornecer uma biblioteca de estratégias de memória para agentes LangGraph, permitindo gerenciar contexto de conversas longas, persistir estado em múltiplos backends e implementar memória de longo prazo com busca semântica.

## 📋 Especificação (SDD)
- **Entradas**: State com `messages`, configuração de checkpointer/store, parâmetros de trim/summarize
- **Saídas**: Mensagens gerenciadas, checkpoints criados/consultados/deletados, memórias armazenadas
- **Side Effects**: Escrita/leitura em banco, criação de índices, logging de operações
- **Constraints Aplicáveis**: C1, C2, C3, C5, C6, C7, C8
- **Dependências**: `langgraph-checkpoint`, `langgraph-store`, `langchain-core`

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
# 1. ESTRATÉGIA DE TRIM DE MENSAGENS
# ═══════════════════════════════════════════════════════════════════════════
from langchain_core.messages.utils import trim_messages, count_tokens_approximately
from langchain_core.messages import AnyMessage, HumanMessage, AIMessage, SystemMessage

class MessageTrimmer:
    """Gerencia o trim de histórico de mensagens."""
    def __init__(self, max_tokens: int = 4096, strategy: str = "last"):
        self.max_tokens = max_tokens
        self.strategy = strategy

    def trim(self, messages: list[AnyMessage]) -> list[AnyMessage]:
        trimmed = trim_messages(
            messages,
            strategy=self.strategy,
            token_counter=count_tokens_approximately,
            max_tokens=self.max_tokens,
            start_on="human",
            end_on=("human", "tool"),
        )
        mantis_log("INFO", "messages_trimmed", f"From={len(messages)} To={len(trimmed)}")
        return trimmed

# ═══════════════════════════════════════════════════════════════════════════
# 2. ESTRATÉGIA DE DELETE DE MENSAGENS
# ═══════════════════════════════════════════════════════════════════════════
from langchain_core.messages import RemoveMessage
from langgraph.graph.message import REMOVE_ALL_MESSAGES

class MessageDeleter:
    """Remove mensagens do estado do grafo."""
    @staticmethod
    def delete_earliest(messages: list[AnyMessage], count: int = 2) -> dict:
        ids = [m.id for m in messages[:count] if hasattr(m, 'id')]
        mantis_log("INFO", "messages_deleted", f"Count={len(ids)}")
        return {"messages": [RemoveMessage(id=id) for id in ids]}

    @staticmethod
    def delete_all() -> dict:
        mantis_log("INFO", "all_messages_deleted")
        return {"messages": [RemoveMessage(id=REMOVE_ALL_MESSAGES)]}

    @staticmethod
    def delete_by_id(message_ids: list[str]) -> dict:
        mantis_log("INFO", "messages_deleted_by_id", str(message_ids))
        return {"messages": [RemoveMessage(id=id) for id in message_ids]}

# ═══════════════════════════════════════════════════════════════════════════
# 3. ESTRATÉGIA DE SUMARIZAÇÃO
# ═══════════════════════════════════════════════════════════════════════════
from langchain.chat_models import init_chat_model

class ConversationSummarizer:
    """Sumariza histórico de conversas usando um LLM."""
    def __init__(self, model_name: str = "deepseek-chat"):
        self.model = init_chat_model(model_name, model_provider="deepseek", temperature=0.05)

    def summarize(self, messages: list[AnyMessage], existing_summary: str = "") -> str:
        if existing_summary:
            prompt = f"""Este é um resumo da conversa até agora: {existing_summary}

Estenda o resumo levando em conta as novas mensagens acima. Retorne apenas o resumo atualizado, sem introdução."""
        else:
            prompt = "Crie um resumo conciso da conversa acima. Retorne apenas o resumo, sem introdução."
        summary_messages = messages + [HumanMessage(content=prompt)]
        response = self.model.invoke(summary_messages)
        mantis_log("INFO", "conversation_summarized", f"Length={len(response.content)}")
        return response.content

class SummarizationNode:
    """Nó de grafo que sumariza e trunca mensagens."""
    def __init__(self, model_name: str = "deepseek-chat", keep_last: int = 2):
        self.summarizer = ConversationSummarizer(model_name)
        self.keep_last = keep_last

    def __call__(self, state: dict) -> dict:
        messages = state.get("messages", [])
        existing_summary = state.get("summary", "")
        if len(messages) <= self.keep_last + 2:
            return {}
        new_summary = self.summarizer.summarize(messages[:-self.keep_last], existing_summary)
        delete_ids = [m.id for m in messages[:-self.keep_last] if hasattr(m, 'id')]
        mantis_log("INFO", "summarization_node", f"Kept={self.keep_last}, Deleted={len(delete_ids)}")
        return {
            "summary": new_summary,
            "messages": [RemoveMessage(id=id) for id in delete_ids],
        }

# ═══════════════════════════════════════════════════════════════════════════
# 4. GERENCIADOR DE CHECKPOINTS
# ═══════════════════════════════════════════════════════════════════════════
from langgraph.checkpoint.base import BaseCheckpointSaver

class CheckpointManager:
    """Gerencia visualização e deleção de checkpoints."""
    def __init__(self, checkpointer: BaseCheckpointSaver):
        self.checkpointer = checkpointer

    def get_state(self, thread_id: str, checkpoint_id: Optional[str] = None):
        config = {"configurable": {"thread_id": thread_id}}
        if checkpoint_id:
            config["configurable"]["checkpoint_id"] = checkpoint_id
        state = self.checkpointer.get_tuple(config)
        mantis_log("DEBUG", "checkpoint_retrieved", f"Thread={thread_id}")
        return state

    def get_history(self, thread_id: str) -> list:
        config = {"configurable": {"thread_id": thread_id}}
        history = list(self.checkpointer.list(config))
        mantis_log("INFO", "checkpoint_history", f"Thread={thread_id}, Count={len(history)}")
        return history

    def delete_thread(self, thread_id: str):
        self.checkpointer.delete_thread(thread_id)
        mantis_log("INFO", "thread_deleted", thread_id)

# ═══════════════════════════════════════════════════════════════════════════
# 5. FÁBRICA DE BACKENDS DE PERSISTÊNCIA
# ═══════════════════════════════════════════════════════════════════════════
class PersistenceBackendFactory:
    """Cria checkpointer e store para diferentes backends."""
    @staticmethod
    def create_memory():
        from langgraph.checkpoint.memory import InMemorySaver
        from langgraph.store.memory import InMemoryStore
        return InMemorySaver(), InMemoryStore()

    @staticmethod
    def create_sqlite(db_path: str = "./checkpoints.db"):
        from langgraph.checkpoint.sqlite import SqliteSaver
        return SqliteSaver.from_conn_string(db_path), None

    @staticmethod
    def create_postgres(uri: str):
        from langgraph.checkpoint.postgres import PostgresSaver
        from langgraph.store.postgres import PostgresStore
        return PostgresSaver.from_conn_string(uri), PostgresStore.from_conn_string(uri)

    @staticmethod
    def create_redis(uri: str = "redis://localhost:6379"):
        from langgraph.checkpoint.redis import RedisSaver
        from langgraph.store.redis import RedisStore
        return RedisSaver.from_conn_string(uri), RedisStore.from_conn_string(uri)

    @staticmethod
    def create_mongodb(uri: str = "mongodb://localhost:27017"):
        from langgraph.checkpoint.mongodb import MongoDBSaver
        return MongoDBSaver.from_conn_string(uri), None

# ═══════════════════════════════════════════════════════════════════════════
# 6. MEMÓRIA DE LONGO PRAZO COM BUSCA SEMÂNTICA
# ═══════════════════════════════════════════════════════════════════════════
from langgraph.store.base import BaseStore
import uuid

class LongTermMemoryManager:
    """Gerencia memória de longo prazo com busca semântica."""
    def __init__(self, store: BaseStore, default_namespace: tuple = ("memories",)):
        self.store = store
        self.namespace = default_namespace

    async def store_memory(self, user_id: str, data: dict, key: Optional[str] = None):
        ns = (user_id,) + self.namespace
        memory_key = key or str(uuid.uuid4())
        await self.store.aput(ns, memory_key, data)
        mantis_log("INFO", "long_term_memory_stored", f"User={user_id}, Key={memory_key}")

    async def search_memories(self, user_id: str, query: str, limit: int = 3) -> list:
        ns = (user_id,) + self.namespace
        results = await self.store.asearch(ns, query=query, limit=limit)
        mantis_log("DEBUG", "long_term_memory_search", f"User={user_id}, Results={len(results)}")
        return [{"value": r.value, "score": r.score} for r in results]

    async def delete_memory(self, user_id: str, key: str):
        ns = (user_id,) + self.namespace
        await self.store.adelete(ns, key)
        mantis_log("INFO", "long_term_memory_deleted", f"User={user_id}, Key={key}")

# ═══════════════════════════════════════════════════════════════════════════
# 7. EXEMPLO COMPLETO: GRAFO COM SUMARIZAÇÃO E MEMÓRIA LONGA
# ═══════════════════════════════════════════════════════════════════════════
class MemoryAwareGraphExample:
    """Grafo com sumarização e memória de longo prazo."""
    def __init__(self):
        from langgraph.graph import MessagesState
        class State(MessagesState):
            summary: str

        self.State = State
        self.checkpointer, self.store = PersistenceBackendFactory.create_memory()
        self.summarizer = SummarizationNode(keep_last=3)
        self.model = init_chat_model("deepseek-chat", model_provider="deepseek", temperature=0.05)

    def build(self):
        builder = StateGraph(self.State)
        def call_model(state):
            response = self.model.invoke(state["messages"])
            return {"messages": [response]}

        builder.add_node("summarize", self.summarizer)
        builder.add_node("call_model", call_model)
        builder.add_edge(START, "summarize")
        builder.add_edge("summarize", "call_model")
        builder.add_edge("call_model", END)
        return builder.compile(checkpointer=self.checkpointer, store=self.store)
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from memory_management_patterns import (
    MessageTrimmer, MessageDeleter, ConversationSummarizer,
    CheckpointManager, PersistenceBackendFactory, LongTermMemoryManager,
    MemoryAwareGraphExample
)
from langchain_core.messages import HumanMessage, AIMessage

def test_message_trimmer():
    trimmer = MessageTrimmer(max_tokens=50)
    messages = [HumanMessage(content="Hi " * 100), AIMessage(content="Hello")]
    trimmed = trimmer.trim(messages)
    assert len(trimmed) <= len(messages)

def test_message_deleter_earliest():
    messages = [
        HumanMessage(content="msg1", id="1"),
        AIMessage(content="msg2", id="2"),
        HumanMessage(content="msg3", id="3"),
    ]
    result = MessageDeleter.delete_earliest(messages, 2)
    assert len(result["messages"]) == 2

def test_persistence_factory_memory():
    checkpointer, store = PersistenceBackendFactory.create_memory()
    assert checkpointer is not None
    assert store is not None

def test_memory_aware_graph():
    example = MemoryAwareGraphExample()
    graph = example.build()
    result = graph.invoke(
        {"messages": [{"role": "user", "content": "Hello, remember my name is Bob"}]},
        {"configurable": {"thread_id": "mem-test-1"}},
    )
    assert "messages" in result

@pytest.mark.asyncio
async def test_long_term_memory():
    _, store = PersistenceBackendFactory.create_memory()
    await store.setup()
    manager = LongTermMemoryManager(store)
    await manager.store_memory("user1", {"data": "test memory"})
    results = await manager.search_memories("user1", "test")
    assert len(results) > 0
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/05-bases-datos/memory-management-patterns.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[multi-agent-memory.md]]
- [[langgraph-state-graph-fundamentals.md]]
- [[database-vectorstore-unified.md]]
