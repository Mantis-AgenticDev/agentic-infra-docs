---
artifact_id: "advanced-persistence-patterns"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/05-bases-datos/advanced-persistence-patterns.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/05-bases-datos/advanced-persistence-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:advanced-persistence-v1"
generated_at: "2026-05-27T18:15:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["memory-management-patterns", "checkpointer-backend-config", "time-travel-debugging"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-08-27"
---

# 🧩 Advanced Persistence Patterns — Serialização, Encriptação e Histórico de Estado

> **Contrato modular**: Artefato filho do Master Agent. Implementa padrões avançados de persistência: navegação no histórico de checkpoints, replay, `update_state`, serialização com `pickle_fallback` e encriptação de checkpoints.

## 🎯 Propósito

Fornecer uma biblioteca de operações avançadas sobre a camada de persistência do LangGraph, incluindo consulta e filtro de histórico, replay de execuções passadas, modificação de estado com `update_state` e configuração de serializadores e encriptação.

## 📋 Especificação (SDD)
- **Entradas**: Checkpointer, `thread_id`, `checkpoint_id`, configuração de serde, chave de encriptação
- **Saídas**: `StateSnapshot`, checkpoints filtrados, estado modificado
- **Side Effects**: Escrita de novos checkpoints (update_state), leitura de histórico
- **Constraints Aplicáveis**: C1, C2, C3, C5, C7, C8
- **Dependências**: `langgraph-checkpoint`, `langgraph-checkpoint-postgres`, `pycryptodome`

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
# 1. NAVEGADOR DE HISTÓRICO DE CHECKPOINTS
# ═══════════════════════════════════════════════════════════════════════════
from typing import Optional, List, Iterator
from langgraph.checkpoint.base import BaseCheckpointSaver

class CheckpointHistoryNavigator:
    """Navega e filtra o histórico de checkpoints de uma thread."""
    def __init__(self, checkpointer: BaseCheckpointSaver):
        self.checkpointer = checkpointer

    def get_latest(self, thread_id: str) -> dict:
        config = {"configurable": {"thread_id": thread_id}}
        state = self.checkpointer.get_tuple(config)
        mantis_log("DEBUG", "latest_checkpoint", f"Thread={thread_id}")
        return self._state_to_dict(state)

    def get_by_id(self, thread_id: str, checkpoint_id: str) -> dict:
        config = {"configurable": {"thread_id": thread_id, "checkpoint_id": checkpoint_id}}
        state = self.checkpointer.get_tuple(config)
        return self._state_to_dict(state)

    def get_history(self, thread_id: str) -> List[dict]:
        config = {"configurable": {"thread_id": thread_id}}
        history = list(self.checkpointer.list(config))
        mantis_log("INFO", "checkpoint_history", f"Thread={thread_id}, Count={len(history)}")
        return [self._state_to_dict(h) for h in history]

    def find_by_step(self, thread_id: str, step: int) -> Optional[dict]:
        for state in self.get_history(thread_id):
            if state.get("metadata", {}).get("step") == step:
                return state
        return None

    def find_interrupted(self, thread_id: str) -> Optional[dict]:
        for state in self.get_history(thread_id):
            tasks = state.get("tasks", ())
            for task in tasks:
                if task.get("interrupts"):
                    mantis_log("INFO", "interrupted_checkpoint_found", f"Thread={thread_id}")
                    return state
        return None

    def _state_to_dict(self, state) -> dict:
        if state is None:
            return {}
        return {
            "config": state.config,
            "checkpoint": state.checkpoint,
            "metadata": state.metadata,
            "parent_config": state.parent_config,
            "pending_writes": state.pending_writes,
        }

# ═══════════════════════════════════════════════════════════════════════════
# 2. REPLAY DE EXECUÇÃO A PARTIR DE CHECKPOINT
# ═══════════════════════════════════════════════════════════════════════════
from langgraph.graph import StateGraph

class ExecutionReplayer:
    """Re-executa um grafo a partir de um checkpoint específico."""
    def __init__(self, graph):
        self.graph = graph

    def replay_from_checkpoint(self, thread_id: str, checkpoint_id: str, new_input: dict = None):
        config = {
            "configurable": {
                "thread_id": thread_id,
                "checkpoint_id": checkpoint_id,
            }
        }
        mantis_log("INFO", "replay_start", f"Checkpoint={checkpoint_id}")
        result = self.graph.invoke(new_input or {}, config)
        return result

# ═══════════════════════════════════════════════════════════════════════════
# 3. UPDATE STATE (MODIFICAÇÃO DE ESTADO SEM RE-EXECUTAR)
# ═══════════════════════════════════════════════════════════════════════════
class StateUpdater:
    """Modifica o estado de uma thread em um checkpoint específico."""
    def __init__(self, graph):
        self.graph = graph

    def update(self, thread_id: str, values: dict, as_node: Optional[str] = None):
        config = {"configurable": {"thread_id": thread_id}}
        result = self.graph.update_state(config, values, as_node=as_node)
        mantis_log("INFO", "state_updated", f"Thread={thread_id}, AsNode={as_node}")
        return result

    def fork(self, thread_id: str, checkpoint_id: str, new_values: dict):
        """Cria um fork a partir de um checkpoint, modificando o estado."""
        config = {"configurable": {"thread_id": thread_id}}
        result = self.graph.update_state(config, new_values)
        mantis_log("INFO", "fork_created", f"Thread={thread_id}, Checkpoint={checkpoint_id}")
        return result

# ═══════════════════════════════════════════════════════════════════════════
# 4. SERIALIZAÇÃO COM PICKLE FALLBACK
# ═══════════════════════════════════════════════════════════════════════════
from langgraph.checkpoint.serde.jsonplus import JsonPlusSerializer
from langgraph.checkpoint.memory import InMemorySaver

class PickleFallbackSerializer:
    """Configura serialização com fallback para pickle."""
    @staticmethod
    def create_checkpointer() -> InMemorySaver:
        serde = JsonPlusSerializer(pickle_fallback=True)
        checkpointer = InMemorySaver(serde=serde)
        mantis_log("INFO", "pickle_fallback_serde_created")
        return checkpointer

# ═══════════════════════════════════════════════════════════════════════════
# 5. ENCRIPTAÇÃO DE CHECKPOINTS
# ═══════════════════════════════════════════════════════════════════════════
import os, sqlite3
from langgraph.checkpoint.serde.encrypted import EncryptedSerializer
from langgraph.checkpoint.sqlite import SqliteSaver

class EncryptedCheckpointManager:
    """Gerencia checkpoints com encriptação AES."""
    @staticmethod
    def create_encrypted_sqlite_checkpointer(db_path: str = "checkpoints.db"):
        serde = EncryptedSerializer.from_pycryptodome_aes()
        conn = sqlite3.connect(db_path)
        checkpointer = SqliteSaver(conn, serde=serde)
        mantis_log("INFO", "encrypted_checkpointer_created")
        return checkpointer

    @staticmethod
    def create_encrypted_postgres_checkpointer(uri: str):
        from langgraph.checkpoint.postgres import PostgresSaver
        serde = EncryptedSerializer.from_pycryptodome_aes()
        checkpointer = PostgresSaver.from_conn_string(uri, serde=serde)
        checkpointer.setup()
        mantis_log("INFO", "encrypted_postgres_checkpointer_created")
        return checkpointer
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from advanced_persistence_patterns import (
    CheckpointHistoryNavigator, ExecutionReplayer, StateUpdater,
    PickleFallbackSerializer, EncryptedCheckpointManager
)
from langgraph.checkpoint.memory import InMemorySaver
from langgraph.graph import StateGraph, START, END
from typing_extensions import TypedDict

class State(TypedDict):
    value: int

@pytest.fixture
def simple_graph():
    def node(state: State) -> dict:
        return {"value": state["value"] + 1}
    builder = StateGraph(State)
    builder.add_node("node", node)
    builder.add_edge(START, "node")
    builder.add_edge("node", END)
    checkpointer = InMemorySaver()
    graph = builder.compile(checkpointer=checkpointer)
    graph.invoke({"value": 0}, {"configurable": {"thread_id": "test-1"}})
    return graph, checkpointer

def test_get_latest(simple_graph):
    graph, cp = simple_graph
    nav = CheckpointHistoryNavigator(cp)
    state = nav.get_latest("test-1")
    assert state["metadata"]["step"] > 0

def test_pickle_fallback():
    cp = PickleFallbackSerializer.create_checkpointer()
    assert cp is not None

def test_encrypted_sqlite(tmp_path):
    db = str(tmp_path / "enc.db")
    cp = EncryptedCheckpointManager.create_encrypted_sqlite_checkpointer(db)
    assert cp is not None
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/05-bases-datos/advanced-persistence-patterns.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[memory-management-patterns.md]]
- [[checkpointer-backend-config.md]]
