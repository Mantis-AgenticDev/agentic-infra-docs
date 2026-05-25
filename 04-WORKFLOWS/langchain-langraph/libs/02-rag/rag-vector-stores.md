---
artifact_id: "rag-vector-stores"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/rag-vector-stores.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/rag-vector-stores.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:rag-vector-stores-v1.0.0"
generated_at: "2026-05-24T23:59:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["rag-retrieval-strategies", "rag-hybrid-search", "rag-production"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🗄️ RAG Vector Stores – Armazenamento e Gerenciamento de Vetores

> **Contrato modular**: Define a configuração, uso e boas práticas de vector stores (Chroma, FAISS, Pinecone, Qdrant, pgvector) para o ecossistema MANTIS, garantindo persistência, isolamento multi‑tenant e alta disponibilidade.

---

## 🎯 Propósito
Fornecer um guia executável para escolher, implantar e operar a vector store que alimentará a memória de longo prazo dos agentes MANTIS, assegurando desempenho e conformidade com C4 (tenant isolation).

## 📋 Especificação (SDD)
- **Entradas**: Embeddings (vetores) e documentos chunkados.
- **Saídas**: Vector store populada e configurada para consultas.
- **Side Effects**: Persistência em disco/cloud; custos associados.
- **Constraints Aplicáveis**: C1 (schema de index), C2 (reprodutibilidade via Docker), C3 (proteção de chaves), C4 (tenant_context), C5 (metadados estruturados), C7 (failover), C8 (logs), C9 (trace distribuído).
- **Dependências**: `chromadb`, `faiss-cpu`, `pinecone-client`, `qdrant-client`, `psycopg2-binary`, `pgvector`.

---

## 🛡️ Bootstrap Resiliente (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ... (fallback)
```

### 1. Chroma – Desenvolvimento e Produção Leve
```python
from langchain_chroma import Chroma
from langchain_openai import OpenAIEmbeddings

embeddings = OpenAIEmbeddings()
vectorstore = Chroma.from_documents(
    documents=docs,
    embedding=embeddings,
    persist_directory="./chroma_db",
    collection_name="mantis_knowledge"
)
mantis_log("INFO", "chroma_created", "Chroma persistente criado")
```

### 2. FAISS – Alta Performance Local
```python
from langchain_community.vectorstores import FAISS

vectorstore = FAISS.from_documents(docs, embeddings)
vectorstore.save_local("./faiss_index")
mantis_log("INFO", "faiss_saved", "Índice FAISS salvo em disco")

# Carregar
vectorstore = FAISS.load_local(
    "./faiss_index",
    embeddings,
    allow_dangerous_deserialization=True  # C3: somente em ambiente controlado
)
```

### 3. Pinecone – Produção Gerenciada (Cloud)
```python
import pinecone
from pinecone import Pinecone, ServerlessSpec
from langchain_pinecone import PineconeVectorStore
import os

pc = Pinecone(api_key=os.environ["PINECONE_API_KEY"])
spec = ServerlessSpec(cloud="aws", region="us-east-1")
index_name = "mantis-rag"

if index_name not in pc.list_indexes().names():
    pc.create_index(
        name=index_name,
        dimension=1536,  # deve coincidir com o modelo
        metric="cosine",
        spec=spec
    )
    mantis_log("INFO", "pinecone_index_created", index_name)

vectorstore = PineconeVectorStore.from_documents(
    docs,
    embedding=OpenAIEmbeddings(),
    index_name=index_name
)
```

### 4. Qdrant – Híbrido (Local/Docker) com Filtros Avançados
```python
from langchain_qdrant import QdrantVectorStore
from qdrant_client import QdrantClient

client = QdrantClient("http://localhost:6333")
vectorstore = QdrantVectorStore(client, collection_name="mantis", embedding=OpenAIEmbeddings())
vectorstore.add_documents(docs)
mantis_log("INFO", "qdrant_upsert", f"{len(docs)} documentos no Qdrant")
```

### 5. pgvector – Integração com PostgreSQL (Produção Empresarial)
```python
from langchain_community.vectorstores.pgvector import PGVector

CONN_STRING = "postgresql://user:pass@localhost:5432/mantis"
vectorstore = PGVector.from_documents(
    embedding=embeddings,
    documents=docs,
    collection_name="rag_docs",
    connection_string=CONN_STRING
)
mantis_log("INFO", "pgvector_created", "Documentos indexados no PostgreSQL")
```

### 6. Multi‑Tenancy com Filtros de Tenant (C4)
```python
# Ao adicionar documentos, incluir tenant_id nos metadados
for doc in docs:
    doc.metadata["tenant_id"] = os.getenv("TENANT_ID", "global")

vectorstore = Chroma.from_documents(docs, embeddings, persist_directory="./chroma_mt")

# Na busca, aplicar filtro de tenant
retriever = vectorstore.as_retriever(search_kwargs={
    "k": 5,
    "filter": {"tenant_id": os.getenv("TENANT_ID")}
})
mantis_log("INFO", "multi_tenant_filter", "Filtro de tenant_id ativo")
```

### 7. Docker Compose para Stack de Vector Store
```yaml
# docker-compose.yml
services:
  qdrant:
    image: qdrant/qdrant:latest
    volumes:
      - qdrant_storage:/qdrant/storage
    ports:
      - "6333:6333"
    restart: unless-stopped
  chroma:
    image: chromadb/chroma:latest
    volumes:
      - chroma_data:/chroma/chroma
    ports:
      - "8000:8000"
    restart: unless-stopped
volumes:
  qdrant_storage:
  chroma_data:
```

### 8. Verificação de Saúde da Vector Store
```python
def health_check(vectorstore):
    try:
        result = vectorstore.similarity_search("test", k=1)
        mantis_log("INFO", "vectorstore_health", "ok")
        return True
    except Exception as e:
        mantis_log("ERROR", "vectorstore_health", str(e))
        return False
```

---

## 🧪 Testes Unitários (TDD)
```python
def test_chroma_persist():
    docs = [Document(page_content="teste")]
    store = Chroma.from_documents(docs, OpenAIEmbeddings(), persist_directory="./test_chroma")
    store2 = Chroma(persist_directory="./test_chroma", embedding_function=OpenAIEmbeddings())
    results = store2.similarity_search("teste", k=1)
    assert len(results) == 1
    assert results[0].page_content == "teste"

def test_tenant_isolation():
    # Simular documentos de dois tenants
    d1 = Document(page_content="segredo A", metadata={"tenant_id": "t1"})
    d2 = Document(page_content="segredo B", metadata={"tenant_id": "t2"})
    store = InMemoryVectorStore.from_documents([d1, d2], FakeEmbeddings())
    retriever = store.as_retriever(search_kwargs={"k": 5, "filter": {"tenant_id": "t1"}})
    results = retriever.invoke("segredo")
    assert all(r.metadata["tenant_id"] == "t1" for r in results)
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/rag-vector-stores.md \
  --json --check-structural --check-error-handling --check-observability
```

---

## 🔗 Referências Cruzadas
- [[rag-embeddings.md]]
- [[rag-retrieval-strategies.md]]
- [[langchain-langraph-master-agent.md]]

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal |
|--------|------|-------|------------------|
| 1.0.0 | 2026-05-24T23:59:00Z | langchain-langraph-master-agent | Criação inicial: todas vector stores |
