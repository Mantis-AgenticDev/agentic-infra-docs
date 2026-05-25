---
artifact_id: "postgres-checkpoint-saver"
artifact_type: "workflow_skill"
version: "2.0.0"
constraints_mapped: ["C1","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/postgres-checkpoint-saver.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/postgres-checkpoint-saver.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:postgres-checkpoint-v2.0.0"
generated_at: "2026-05-25T11:40:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["langgraph-state-graph-fundamentals", "agents-swarm-coordination"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Refundado"
next_review: "2026-06-24"
---

# 🐘 PostgresSaver – Checkpointing Empresarial com PostgreSQL

> **Contrato modular**: Detalha o uso do `PostgresSaver` para armazenar checkpoints em PostgreSQL, com suporte a pipeline, serde customizado, lock distribuído e monitoramento.

---

## 🎯 Propósito
Prover uma solução robusta de checkpointing para produção, aproveitando a confiabilidade e escalabilidade do PostgreSQL.

## 📋 Especificação (SDD)
- **Entradas**: Conexão psycopg, configuração de pipeline.
- **Saídas**: Estado do grafo persistido.
- **Side Effects**: Escritas no PostgreSQL.
- **Constraints Aplicáveis**: C1 (schema), C5 (serialização), C7 (resiliência), C8 (logs), C9 (trace).
- **Dependências**: `langgraph`, `psycopg2`.

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

### 1. Inicialização com Pipeline
```python
from langgraph.checkpoint.postgres import PostgresSaver
from psycopg_pool import ConnectionPool

pool = ConnectionPool("postgresql://user:pass@localhost:5432/mantis", min_size=2, max_size=10)
checkpointer = PostgresSaver(conn=pool)
checkpointer.setup()
graph = builder.compile(checkpointer=checkpointer)
```

### 2. Configuração de Serde Customizado
```python
from langgraph.serde import SerializerProtocol
import msgpack

class MsgPackSerializer(SerializerProtocol):
    def dumps(self, obj):
        return msgpack.packb(obj)
    def loads(self, data):
        return msgpack.unpackb(data)

checkpointer = PostgresSaver.from_conn_string(
    "postgresql://...",
    serde=MsgPackSerializer()
)
```

### 3. Operações Básicas de Checkpoint
```python
config = {"configurable": {"thread_id": "thread-1"}}
checkpointer.put(config, {"checkpoint_id": "1"}, {"values": {"step": 1}})
state = checkpointer.get_tuple(config)
mantis_log("INFO", "checkpoint_get", f"Step: {state.values['step']}")
```

### 4. Listagem e Poda de Threads Antigas
```python
# Listar todas as threads
all_threads = checkpointer.list()
for thread in all_threads:
    if thread.checkpoint["ts"] < datetime.datetime.utcnow() - datetime.timedelta(days=30):
        checkpointer.delete_thread(thread.config)
        mantis_log("INFO", "thread_purged", thread.thread_id)
```

### 5. Monitoramento com Métricas
```python
from prometheus_client import Counter
checkpoint_operations = Counter('pg_checkpoint_ops', 'Operações de checkpoint', ['op'])

@checkpoint_operations.labels(op='put').count_exceptions()
def safe_put(config, chkp, values):
    checkpointer.put(config, chkp, values)
```

---

## 🧪 Testes Unitários (TDD)
```python
def test_postgres_saver():
    conn = psycopg2.connect("dbname=test user=test password=test")
    saver = PostgresSaver(conn)
    saver.setup()
    config = {"configurable": {"thread_id": "1"}}
    saver.put(config, {"checkpoint_id": "1"}, {"values": "ok"})
    assert saver.get_tuple(config).values == "ok"
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/postgres-checkpoint-saver.md --json
```

---

## 🔗 Referências Cruzadas
- [[sqlite-checkpoint-saver.md]]
