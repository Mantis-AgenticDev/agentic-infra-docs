---
artifact_id: "database-vectorstore-unified"
artifact_type: "workflow_skill"
version: "2.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/database-vectorstore-unified.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/database-vectorstore-unified.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:db-vectorstore-unified-v2.0.0"
generated_at: "2026-05-25T11:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: true
  required_for: ["postgresql-pgvector-enterprise", "qdrant-vectorstore-advanced", "rag-vector-stores"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Refundado"
next_review: "2026-06-24"
---

# 🗄️ Database & VectorStore Unified – Interface Unificada e Ciclo de Vida Completo

> **Contrato modular**: Define o uso canônico da interface de vector stores do LangChain, abrangendo múltiplas implementações com exemplos densos de código, operações CRUD, filtros, batch e async.

---

## 🎯 Propósito
Fornecer uma camada de abstração padronizada para que agentes MANTIS possam usar qualquer vector store (InMemory, Chroma, FAISS, Qdrant, Pinecone, PGVector, Milvus, etc.) sem alterar a lógica de negócio, com exemplos práticos e comparativos.

## 📋 Especificação (SDD)
- **Entradas**: Documentos, embeddings, configuração da store.
- **Saídas**: Vector store populada e consultável.
- **Side Effects**: Persistência em disco/cloud.
- **Constraints Aplicáveis**: C1 (contrato de interface), C3 (proteção de dados), C5 (metadados), C7 (fallback), C8 (logs de operações).
- **Dependências**: `langchain-core`, `langchain-openai`, `chromadb`, `faiss-cpu`, `qdrant-client`, `langchain-postgres`.

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

### 1. Interface Unificada com Seleção Dinâmica de Backend
```python
from langchain_core.vectorstores import InMemoryVectorStore
from langchain_openai import OpenAIEmbeddings
from langchain_core.documents import Document
import os

class VectorStoreFactory:
    @staticmethod
    def create(profile: str = "development", **kwargs):
        embeddings = kwargs.get("embeddings", OpenAIEmbeddings())
        if profile == "production":
            from langchain_postgres import PGVector
            return PGVector(
                embeddings=embeddings,
                collection_name=kwargs.get("collection", "mantis_docs"),
                connection=os.getenv("DATABASE_URL", "postgresql://localhost/mantis"),
                use_jsonb=True
            )
        elif profile == "staging":
            from langchain_qdrant import QdrantVectorStore
            from qdrant_client import QdrantClient
            client = QdrantClient(url=os.getenv("QDRANT_URL", "http://localhost:6333"))
            return QdrantVectorStore(
                client=client,
                collection_name=kwargs.get("collection", "mantis_docs"),
                embedding=embeddings
            )
        elif profile == "local":
            from langchain_chroma import Chroma
            return Chroma(
                embedding_function=embeddings,
                persist_directory=kwargs.get("path", "./chroma_db")
            )
        else:
            return InMemoryVectorStore(embedding=embeddings)

vectorstore = VectorStoreFactory.create("development")
mantis_log("INFO", "store_created", f"Backend: {type(vectorstore).__name__}")
```

### 2. Adição de Documentos em Lote com IDs e Metadados
```python
docs = [
    Document(page_content="LangChain é um framework para LLMs.", metadata={"source": "docs", "page": 1}),
    Document(page_content="RAG significa Retrieval Augmented Generation.", metadata={"source": "docs", "page": 2}),
    Document(page_content="MANTIS usa C1-C9 para governança.", metadata={"source": "internal", "page": 3}),
]
ids = [f"doc_{i}" for i in range(len(docs))]
vectorstore.add_documents(documents=docs, ids=ids)
mantis_log("INFO", "docs_added", f"{len(docs)} documentos inseridos")
```

### 3. Busca por Similaridade com Filtros
```python
# Busca simples
results = vectorstore.similarity_search("O que é LangChain?", k=2)
# Busca com filtro de metadados
filtered = vectorstore.similarity_search("governança", k=3, filter={"source": "internal"})
# Busca com score
from langchain_core.vectorstores import VectorStore
if hasattr(vectorstore, "similarity_search_with_score"):
    scored = vectorstore.similarity_search_with_score("RAG", k=2)
    for doc, score in scored:
        print(f"Score: {score:.4f} | {doc.page_content[:50]}...")
```

### 4. Delete e Atualização
```python
# Delete por ID
vectorstore.delete(ids=["doc_0"])
# Em stores como Chroma, é possível delete por filtro
if hasattr(vectorstore, "delete"):
    vectorstore.delete(filter={"source": "internal"})
```

### 5. Operações Assíncronas (onde suportado)
```python
import asyncio

async def async_operations():
    if hasattr(vectorstore, 'aadd_documents'):
        await vectorstore.aadd_documents(documents=docs, ids=ids)
    if hasattr(vectorstore, 'asimilarity_search'):
        results = await vectorstore.asimilarity_search("consulta", k=3)
        return results
```

### 6. Tabela Comparativa de Capacidades
| Store | Persistência | Async | Filtro | Multi‑Tenant | Delete por ID |
|-------|--------------|-------|--------|--------------|---------------|
| InMemory | ❌ | ✅ | ✅ | ❌ | ✅ |
| Chroma | Disco | ✅ | ✅ | ✅ | ✅ |
| FAISS | Disco | ❌ | ❌ | ❌ | ✅ (via índice) |
| Qdrant | Disco/Cloud | ✅ | ✅ (payload) | ✅ (collection) | ✅ |
| PGVector | PostgreSQL | ✅ | ✅ (JSONB) | ✅ (RLS) | ✅ |
| Pinecone | Cloud | ✅ | ✅ | ❌ | ✅ |
| Milvus | Disco/Cloud | ✅ | ✅ | ✅ | ✅ |

### 7. Transição Dinâmica entre Backends (ex: desenvolvimento → produção)
```python
def migrate_store(source, target, batch_size=50):
    all_docs = source.get(include=["documents", "metadatas"])
    for i in range(0, len(all_docs["documents"]), batch_size):
        batch = [
            Document(page_content=all_docs["documents"][j], metadata=all_docs["metadatas"][j])
            for j in range(i, min(i+batch_size, len(all_docs["documents"])))
        ]
        target.add_documents(batch)
    mantis_log("INFO", "migrate", f"{len(all_docs['documents'])} documentos migrados")
```

---

## 🧪 Testes Unitários (TDD)
```python
from langchain_core.embeddings import DeterministicFakeEmbedding

def test_inmemory_add_search():
    store = InMemoryVectorStore(embedding=DeterministicFakeEmbedding(size=128))
    store.add_documents([Document("teste")], ids=["1"])
    results = store.similarity_search("teste", k=1)
    assert len(results) == 1
    assert results[0].page_content == "teste"

def test_factory_creation():
    store = VectorStoreFactory.create("development")
    assert isinstance(store, InMemoryVectorStore)
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/database-vectorstore-unified.md --json
```

---

## 🔗 Referências Cruzadas
- [[postgresql-pgvector-enterprise.md]]
- [[qdrant-vectorstore-advanced.md]]
