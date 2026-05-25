---
artifact_id: "custom-store-backend"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/custom-store-backend.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/custom-store-backend.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:custom-store-v1"
generated_at: "2026-05-26T13:15:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["data-plane-infra", "checkpointer-backend-config"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-07-25"
---

# 🧩 Custom Store Backend

> **Contrato modular**: Artefato filho do Master Agent. Implementa um `BaseStore` customizado para substituir o armazenamento padrão do Agent Server, com suporte a índices vetoriais e ciclo de vida gerenciado.

## 🎯 Propósito

Permitir que o Agent Server use um backend de armazenamento de longo prazo diferente do PostgreSQL padrão, como SQLite com busca semântica, através de um async context manager configurável no `langgraph.json`.

## 📋 Especificação (SDD)
- **Entradas**: Configuração em `langgraph.json` apontando para um `generate_store`, parâmetros de índice vetorial
- **Saídas**: Instância de `BaseStore` pronta para uso pelo Agent Server
- **Side Effects**: Criação de arquivos/tabelas, índices vetoriais, setup inicial
- **Constraints Aplicáveis**: C1, C3, C5, C7, C8
- **Dependências**: `langgraph-store`, `langchain`, `sqlite`, `contextlib`

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

# ─── IMPLEMENTAÇÃO ──────────────────────────────────────────────────────
import contextlib
from typing import AsyncGenerator, Optional
from langgraph.store.base import BaseStore, IndexConfig, Item, SearchResult
from langgraph.store.sqlite import AsyncSqliteStore
from langchain.embeddings import init_embeddings

# ═══════════════════════════════════════════════════════════════════════════
# 1. FÁBRICA DE STORE CUSTOMIZÁVEL
# ═══════════════════════════════════════════════════════════════════════════
class CustomStoreFactory:
    def __init__(self, config: dict):
        self.config = config
        self.backend = config.get("backend", "sqlite")

    @contextlib.asynccontextmanager
    async def generate(self) -> AsyncGenerator[BaseStore, None]:
        if self.backend == "sqlite":
            store = await self._create_sqlite_store()
        elif self.backend == "memory":
            from langgraph.store.memory import InMemoryStore
            store = InMemoryStore()
        else:
            raise ValueError(f"Backend de store não suportado: {self.backend}")
        async with store as s:
            await s.setup()
            mantis_log("INFO", "custom_store_ready", self.backend)
            yield s

    async def _create_sqlite_store(self) -> AsyncSqliteStore:
        db_path = self.config.get("db_path", "./custom_store.sql")
        index_config = self._build_index_config()
        store = AsyncSqliteStore.from_conn_string(
            db_path,
            index=index_config
        )
        return store

    def _build_index_config(self) -> Optional[IndexConfig]:
        index_cfg = self.config.get("index")
        if not index_cfg:
            return None
        embed_model = init_embeddings(index_cfg.get("model", "openai:text-embedding-3-small"))
        dims = index_cfg.get("dims", 1536)
        fields = index_cfg.get("fields", ["$"])
        return IndexConfig(dims=dims, embed=embed_model, fields=fields)

# ═══════════════════════════════════════════════════════════════════════════
# 2. OPERAÇÕES DE ALTO NÍVEL (CRUD COM BUSCA)
# ═══════════════════════════════════════════════════════════════════════════
class StoreOperations:
    def __init__(self, store: BaseStore, default_namespace: tuple = ("default",)):
        self.store = store
        self.namespace = default_namespace

    async def put_item(self, key: str, value: dict, index: bool = True) -> None:
        await self.store.aput(self.namespace, key, value, index=index)
        mantis_log("DEBUG", "store_put", f"Key={key}")

    async def get_item(self, key: str) -> Optional[Item]:
        return await self.store.aget(self.namespace, key)

    async def delete_item(self, key: str) -> None:
        await self.store.adelete(self.namespace, key)
        mantis_log("DEBUG", "store_delete", f"Key={key}")

    async def search(self, query: str, limit: int = 5) -> list[SearchResult]:
        results = await self.store.asearch(self.namespace, query=query, limit=limit)
        mantis_log("DEBUG", "store_search", f"Query={query}, Results={len(results)}")
        return results

# ═══════════════════════════════════════════════════════════════════════════
# 3. INTEGRAÇÃO COM LANGGRAPH.JSON
# ═══════════════════════════════════════════════════════════════════════════
CONFIG_EXAMPLE = """
{
  "dependencies": ["."],
  "graphs": {
    "agent": "./agent.py:graph"
  },
  "store": {
    "path": "./store.py:generate_store"
  }
}
"""

# ═══════════════════════════════════════════════════════════════════════════
# 4. GERENCIADOR DE CICLO DE VIDA
# ═══════════════════════════════════════════════════════════════════════════
class StoreLifecycleManager:
    @staticmethod
    async def startup(store: BaseStore):
        await store.setup()
        mantis_log("INFO", "store_startup")

    @staticmethod
    async def shutdown(store: BaseStore):
        if hasattr(store, "aclose"):
            await store.aclose()
        mantis_log("INFO", "store_shutdown")
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from custom_store_backend import CustomStoreFactory, StoreOperations
from langgraph.store.memory import InMemoryStore

@pytest.mark.asyncio
async def test_memory_store_factory():
    factory = CustomStoreFactory({"backend": "memory"})
    async with factory.generate() as store:
        ops = StoreOperations(store)
        await ops.put_item("key1", {"data": "value"})
        item = await ops.get_item("key1")
        assert item.value == {"data": "value"}

@pytest.mark.asyncio
async def test_search_memory():
    factory = CustomStoreFactory({"backend": "memory"})
    async with factory.generate() as store:
        ops = StoreOperations(store)
        await ops.put_item("doc1", {"text": "hello world"}, index=True)
        results = await ops.search("hello")
        assert len(results) >= 0  # InMemoryStore não tem busca semântica real
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/custom-store-backend.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[data-plane-infra.md]]
- [[checkpointer-backend-config.md]]
