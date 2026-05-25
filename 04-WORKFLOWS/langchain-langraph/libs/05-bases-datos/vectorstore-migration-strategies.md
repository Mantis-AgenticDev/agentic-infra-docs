---
artifact_id: "vectorstore-migration-strategies"
artifact_type: "workflow_skill"
version: "2.0.0"
constraints_mapped: ["C1","C2","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/vectorstore-migration-strategies.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/vectorstore-migration-strategies.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:vec-migration-v2.0.0"
generated_at: "2026-05-25T12:10:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["database-vectorstore-unified", "rag-production"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Refundado"
next_review: "2026-06-24"
---

# 🔄 VectorStore Migration Strategies – Backup, Restore e Versionamento de Esquemas

> **Contrato modular**: Procedimentos completos para migrar dados entre vector stores, realizar backups incrementais, verificar integridade e versionar esquemas de índices.

---

## 🎯 Propósito
Garantir que os dados vetoriais possam ser movidos entre ambientes (Chroma → PGVector, Qdrant → Pinecone) e recuperados em caso de desastre, com scripts robustos.

## 📋 Especificação (SDD)
- **Entradas**: Vector store origem, destino.
- **Saídas**: Dados transferidos com integridade verificada.
- **Side Effects**: Escritas no destino, arquivos de backup.
- **Constraints Aplicáveis**: C1 (schema compatível), C2 (reprodutibilidade), C5 (integridade), C7 (retry), C8 (logs).
- **Dependências**: Implementações de vector stores, `tqdm`.

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

### 1. Backup Completo de Chroma para JSON
```python
import json
from langchain_chroma import Chroma

def backup_chroma_to_json(store: Chroma, filepath: str):
    data = store.get(include=["documents", "metadatas", "ids"])
    backup = []
    for i, doc_id in enumerate(data["ids"]):
        backup.append({
            "id": doc_id,
            "content": data["documents"][i],
            "metadata": data["metadatas"][i]
        })
    with open(filepath, "w") as f:
        json.dump(backup, f, indent=2)
    mantis_log("INFO", "backup", f"{len(backup)} documentos salvos em {filepath}")
```

### 2. Restauração de JSON para PGVector
```python
from langchain_postgres import PGVector
from langchain_core.documents import Document

def restore_json_to_pgvector(filepath: str, target_store: PGVector, batch_size=100):
    with open(filepath) as f:
        data = json.load(f)
    for i in range(0, len(data), batch_size):
        batch = data[i:i+batch_size]
        documents = [
            Document(page_content=d["content"], metadata=d.get("metadata", {}))
            for d in batch
        ]
        ids = [d["id"] for d in batch]
        target_store.add_documents(documents, ids=ids)
        mantis_log("INFO", "restore_batch", f"Lote {i//batch_size + 1}: {len(batch)} docs")
```

### 3. Migração Direta entre Duas Stores
```python
def migrate_between_stores(source, target, query_sample="sample", k=10000, batch=100):
    # Obter todos os documentos via busca exaustiva (aproximada)
    all_docs = source.similarity_search(query_sample, k=k)
    for i in range(0, len(all_docs), batch):
        batch_docs = all_docs[i:i+batch]
        target.add_documents(batch_docs)
    mantis_log("INFO", "migrate_direct", f"{len(all_docs)} documentos migrados")
```

### 4. Verificação de Integridade Pós‑Migração
```python
def verify_migration(source, target, test_queries=["teste", "documento", "consulta"], k=5):
    for query in test_queries:
        src_results = {d.page_content[:50] for d in source.similarity_search(query, k=k)}
        tgt_results = {d.page_content[:50] for d in target.similarity_search(query, k=k)}
        overlap = len(src_results & tgt_results) / k
        mantis_log("INFO", "verify", f"Query '{query}': overlap={overlap:.0%}")
        if overlap < 0.5:
            mantis_log("WARN", "low_overlap", f"Possível perda de dados na query '{query}'")
```

### 5. Versionamento de Schema do Índice
```python
def export_index_config(store, filepath):
    """Exporta configuração do índice para versionamento."""
    config = {
        "type": type(store).__name__,
        "parameters": getattr(store, "index_params", {}),
        "embedding_model": "text-embedding-3-small",
        "vector_size": 1536
    }
    with open(filepath, "w") as f:
        json.dump(config, f, indent=2)
```

---

## 🧪 Testes Unitários (TDD)
```python
def test_backup_restore():
    from langchain_chroma import Chroma
    source = Chroma(embedding_function=DeterministicFakeEmbedding(size=128))
    source.add_documents([Document("test1"), Document("test2")], ids=["1", "2"])
    backup_chroma_to_json(source, "/tmp/backup.json")
    target = Chroma(embedding_function=DeterministicFakeEmbedding(size=128))
    restore_json_to_pgvector("/tmp/backup.json", target)  # adaptado
    assert len(target.similarity_search("test", k=10)) == 2
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/vectorstore-migration-strategies.md --json
```

---

## 🔗 Referências Cruzadas
- [[database-vectorstore-unified.md]]
