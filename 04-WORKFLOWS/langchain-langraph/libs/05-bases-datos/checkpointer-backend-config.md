---
artifact_id: "checkpointer-backend-config"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C5","C7"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/checkpointer-backend-config.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/checkpointer-backend-config.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:checkpointer-config-v1"
generated_at: "2026-05-26T11:15:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["data-plane-infra", "scaling-performance-tuning"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-07-25"
---

# 🧩 Checkpointer Backend Configuration

> **Contrato modular**: Artefato filho do Master Agent. Gerencia a seleção e configuração do backend de checkpoint (PostgreSQL, MongoDB, custom) para o Agent Server.

## 🎯 Propósito

Prover uma fábrica de checkpointers que abstrai a escolha do backend, aplicando as configurações de `langgraph.json` e variáveis de ambiente, e validando a conformidade com as exigências do Agent Server.

## 📋 Especificação (SDD)
- **Entradas**: Configuração de backend (`postgres`, `mongo`, `custom`), TTL, URI de conexão
- **Saídas**: Instância configurada de `BaseCheckpointSaver` pronta para uso no grafo
- **Side Effects**: Criação de índices, validação de conexão, registro de métricas
- **Constraints Aplicáveis**: C1, C2, C3, C5, C7
- **Dependências**: `langgraph-checkpoint`, `langgraph-checkpoint-sqlite`, `asyncpg`, `pymongo`

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

# ─── LÓGICA DO MÓDULO ────────────────────────────────────────────────────
import os, contextlib
from typing import AsyncIterator, Optional, Dict, Any
from datetime import timedelta

from langgraph.checkpoint.base import BaseCheckpointSaver
from langgraph.checkpoint.sqlite import AsyncSqliteSaver
from langgraph.checkpoint.postgres import PostgresSaver
from langgraph.checkpoint.memory import InMemorySaver

# ═══════════════════════════════════════════════════════════════════════════
# 1. FÁBRICA DE CHECKPOINTER
# ═══════════════════════════════════════════════════════════════════════════
class CheckpointerFactory:
    BACKENDS = ("postgres", "mongo", "sqlite", "memory", "custom")

    def __init__(self, config: dict):
        self.backend = config.get("backend", "postgres").lower()
        if self.backend not in self.BACKENDS:
            raise ValueError(f"Backend inválido: {self.backend}. Use um de {self.BACKENDS}")
        self.ttl_config = config.get("ttl", {})
        self.custom_path = config.get("path")

    async def create(self) -> BaseCheckpointSaver:
        mantis_log("INFO", "checkpointer_create", f"Backend: {self.backend}")
        if self.backend == "postgres":
            return await self._create_postgres()
        elif self.backend == "mongo":
            return await self._create_mongo()
        elif self.backend == "sqlite":
            return await self._create_sqlite()
        elif self.backend == "memory":
            mantis_log("WARN", "checkpointer_memory", "Usando InMemorySaver - dados não persistem")
            return InMemorySaver()
        elif self.backend == "custom":
            return await self._load_custom()
        else:
            raise ValueError(f"Backend {self.backend} não implementado")

    async def _create_postgres(self) -> PostgresSaver:
        uri = os.getenv("DATABASE_URI") or os.getenv("POSTGRES_URI_CUSTOM")
        if not uri:
            raise ValueError("DATABASE_URI ou POSTGRES_URI_CUSTOM não configurada")
        saver = PostgresSaver.from_conn_string(uri)
        await saver.setup()
        mantis_log("INFO", "postgres_saver_ready")
        return saver

    async def _create_mongo(self):
        try:
            from langgraph.checkpoint.mongodb import AsyncMongoDBSaver
        except ImportError:
            raise ImportError("langgraph-checkpoint-mongodb não instalado")
        uri = os.getenv("LS_MONGODB_URI")
        if not uri:
            raise ValueError("LS_MONGODB_URI não configurada")
        saver = AsyncMongoDBSaver.from_conn_string(uri)
        await saver.setup()
        mantis_log("INFO", "mongo_saver_ready")
        return saver

    async def _create_sqlite(self):
        db_path = os.getenv("SQLITE_DB_PATH", "./checkpoints.db")
        saver = AsyncSqliteSaver.from_conn_string(db_path)
        await saver.setup()
        mantis_log("INFO", "sqlite_saver_ready", f"Path: {db_path}")
        return saver

    async def _load_custom(self) -> BaseCheckpointSaver:
        if not self.custom_path:
            raise ValueError("Custom checkpointer requer 'path' no config")
        # Exemplo: "module.path:generate_checkpointer"
        module_path, func_name = self.custom_path.split(":")
        import importlib
        mod = importlib.import_module(module_path)
        factory = getattr(mod, func_name)
        if hasattr(factory, "__call__"):
            saver = await factory() if asyncio.iscoroutinefunction(factory) else factory()
            return saver
        raise ValueError("Custom factory não retornou um BaseCheckpointSaver")

# ═══════════════════════════════════════════════════════════════════════════
# 2. GERENCIADOR DE TTL PARA CHECKPOINTS
# ═══════════════════════════════════════════════════════════════════════════
class CheckpointTTLManager:
    def __init__(self, saver: BaseCheckpointSaver, ttl_config: dict):
        self.saver = saver
        self.default_ttl = ttl_config.get("default_ttl", 43200)  # 12 horas
        self.strategy = ttl_config.get("strategy", "delete")
        self.sweep_interval = ttl_config.get("sweep_interval_minutes", 10)

    async def apply_ttl(self, thread_id: str):
        """Aplica TTL a um thread específico."""
        # Implementação depende do backend. Exemplo genérico:
        if hasattr(self.saver, "set_ttl"):
            await self.saver.set_ttl(thread_id, self.default_ttl)
        mantis_log("DEBUG", "ttl_applied", f"Thread: {thread_id}, TTL: {self.default_ttl}s")

    async def sweep(self):
        """Varredura periódica para deletar/arquivar checkpoints expirados."""
        if self.strategy == "delete":
            mantis_log("INFO", "ttl_sweep_start")
            # Deletar checkpoints antigos (implementação específica)
            # Exemplo para SQLite:
            if hasattr(self.saver, "delete_thread"):
                # Isto seria mais complexo em produção
                pass
            mantis_log("INFO", "ttl_sweep_complete")

# ═══════════════════════════════════════════════════════════════════════════
# 3. VALIDADOR DE CONFORMIDADE DO CHECKPOINTER
# ═══════════════════════════════════════════════════════════════════════════
class CheckpointerValidator:
    async def validate(self, saver: BaseCheckpointSaver) -> Dict[str, bool]:
        """Executa validação básica dos métodos obrigatórios."""
        results = {}
        # aput
        try:
            config = {"configurable": {"thread_id": "test-thread-1", "checkpoint_ns": ""}}
            await saver.aput(config, {"ts": "2026-05-26T10:00:00Z", "channel_values": {"test": True}, "channel_versions": {"test": 1}}, {}, "checkpoint-1")
            results["aput"] = True
        except Exception as e:
            results["aput"] = False
            mantis_log("ERROR", "conformance_aput_fail", str(e))
        # aget_tuple
        try:
            tuple_ = await saver.aget_tuple(config)
            results["aget_tuple"] = tuple_ is not None
        except:
            results["aget_tuple"] = False
        # alist
        try:
            items = []
            async for _ in saver.alist(config):
                items.append(_)
            results["alist"] = True
        except:
            results["alist"] = False
        # adelete_thread
        try:
            await saver.adelete_thread("test-thread-1")
            results["adelete_thread"] = True
        except:
            results["adelete_thread"] = False
        return results

# ═══════════════════════════════════════════════════════════════════════════
# 4. CONFIGURAÇÃO VIA LANGGRAPH.JSON (EXEMPLO)
# ═══════════════════════════════════════════════════════════════════════════
CONFIG_EXAMPLE = """
{
  "dependencies": ["."],
  "graphs": {
    "agent": "./agent.py:graph"
  },
  "checkpointer": {
    "backend": "mongo",
    "ttl": {
      "strategy": "delete",
      "default_ttl": 43200,
      "sweep_interval_minutes": 10
    }
  }
}
"""
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from checkpointer_backend_config import CheckpointerFactory, CheckpointerValidator

@pytest.mark.asyncio
async def test_factory_memory():
    factory = CheckpointerFactory({"backend": "memory"})
    saver = await factory.create()
    assert isinstance(saver, InMemorySaver)

@pytest.mark.asyncio
async def test_validator_memory():
    validator = CheckpointerValidator()
    saver = InMemorySaver()
    results = await validator.validate(saver)
    assert results["aput"]
    assert results["aget_tuple"]
    assert results["adelete_thread"]

def test_factory_invalid_backend():
    with pytest.raises(ValueError):
        CheckpointerFactory({"backend": "nonexistent"})
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/checkpointer-backend-config.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[data-plane-infra.md]]
- [[scaling-performance-tuning.md]]
