---
artifact_id: "sqlite-checkpoint-saver"
artifact_type: "workflow_skill"
version: "2.0.0"
constraints_mapped: ["C1","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/sqlite-checkpoint-saver.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/sqlite-checkpoint-saver.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:sqlite-checkpoint-v2.0.0"
generated_at: "2026-05-25T11:30:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["langgraph-state-graph-fundamentals", "postgres-checkpoint-saver"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Refundado"
next_review: "2026-06-24"
---

# 🗃️ SqliteSaver – Checkpointing Local Avançado com SQLite

> **Contrato modular**: Documenta o uso avançado de `SqliteSaver` e `AsyncSqliteSaver`, incluindo serde customizado, backup, migração para Postgres e múltiplos threads.

---

## 🎯 Propósito
Permitir que agentes MANTIS salvem e restaurem estado de execução localmente com SQLite, cobrindo cenários de desenvolvimento, testes e migração.

## 📋 Especificação (SDD)
- **Entradas**: Conexão SQLite, configuração de serde.
- **Saídas**: Estado persistido e recuperável.
- **Side Effects**: Escritas no banco SQLite.
- **Constraints Aplicáveis**: C1 (schema de checkpoint), C5 (integridade), C7 (thread‑safety via lock), C8 (logs), C9 (thread_id).
- **Dependências**: `langgraph`, `sqlite3`, `aiosqlite`.

---

## 🛡️ Bootstrap (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    import json, datetime, os
    def mantis_log(level, event, detail=""):
        entry = {"ts": datetime.datetime.utcnow().isoformat() + "Z", "level": level, "tenant": os.getenv("TENANT_ID", "global"), "event": event, "detail": detail, "trace_id": os.getenv("TRACE_ID", "null"), "span_id": os.getenv("SPAN_ID", "null"), "fallback": "true"}
        print(json.dumps(entry), flush=True)
```

### 1. Configuração Básica com Serde Customizado
```python
import sqlite3
from langgraph.checkpoint.sqlite import SqliteSaver
from langgraph.serde.jsonplus import JsonPlusSerializer

conn = sqlite3.connect("checkpoints.sqlite", check_same_thread=False)
checkpointer = SqliteSaver(conn, serde=JsonPlusSerializer())
graph = builder.compile(checkpointer=checkpointer)
config = {"configurable": {"thread_id": "user-123"}}
graph.invoke(3, config)
mantis_log("INFO", "checkpoint_saved", f"Thread: {config['configurable']['thread_id']}")
```

### 2. Recuperação de Estado e Navegação Temporal
```python
# Obter estado atual
state = graph.get_state(config)
print(f"Valores: {state.values}")

# Listar checkpoints de uma thread
checkpoints = checkpointer.list(config)
for cp in checkpoints:
    print(f"Checkpoint: {cp.checkpoint_id}, timestamp: {cp.checkpoint['ts']}")

# Navegar para checkpoint específico
from langgraph.types import Checkpoint
specific = checkpointer.get_tuple({"configurable": {"thread_id": "user-123", "checkpoint_id": "..."}})
```

### 3. AsyncSqliteSaver para Operações Assíncronas
```python
import aiosqlite
from langgraph.checkpoint.sqlite.aio import AsyncSqliteSaver

async def async_checkpoint():
    conn = await aiosqlite.connect("async_checkpoints.sqlite")
    checkpointer = AsyncSqliteSaver(conn)
    await checkpointer.setup()
    config = {"configurable": {"thread_id": "async-1"}}
    await checkpointer.aput(config, {"checkpoint_id": "1"}, {"values": 42})
    state = await checkpointer.aget_tuple(config)
    mantis_log("INFO", "async_state", str(state.values))
```

### 4. Backup e Migração para PostgresSaver
```python
def backup_sqlite_to_postgres(sqlite_saver, pg_saver):
    threads = sqlite_saver.list()
    for thread in threads:
        config = {"configurable": {"thread_id": thread.thread_id}}
        checkpoint = sqlite_saver.get_tuple(config)
        pg_saver.put(config, checkpoint.checkpoint, checkpoint.values)
    mantis_log("INFO", "backup", f"{len(threads)} threads migradas para PostgreSQL")
```

### 5. Configuração de Lock e Thread‑Safety
- SqliteSaver implementa lock interno; `check_same_thread=False` é necessário para uso multi‑thread.
- Use WAL mode para melhor concorrência:
```sql
PRAGMA journal_mode=WAL;
```

---

## 🧪 Testes Unitários (TDD)
```python
def test_sqlite_saver():
    conn = sqlite3.connect(":memory:")
    saver = SqliteSaver(conn)
    saver.setup()
    config = {"configurable": {"thread_id": "test"}}
    saver.put(config, {"checkpoint_id": "1"}, {"values": 42})
    state = saver.get_tuple(config)
    assert state.values == 42
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/sqlite-checkpoint-saver.md --json
```

---

## 🔗 Referências Cruzadas
- [[langgraph-state-graph-fundamentals.md]]
