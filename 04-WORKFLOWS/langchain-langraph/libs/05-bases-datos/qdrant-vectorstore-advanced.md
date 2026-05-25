---
artifact_id: "qdrant-vectorstore-advanced"
artifact_type: "workflow_skill"
version: "2.0.0"
constraints_mapped: ["C1","C3","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/qdrant-vectorstore-advanced.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/qdrant-vectorstore-advanced.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:qdrant-advanced-v2.0.0"
generated_at: "2026-05-25T11:20:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["rag-hybrid-search", "vectorstore-migration-strategies"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Refundado"
next_review: "2026-06-24"
---

# 🔍 Qdrant VectorStore Advanced – Coleções, Sparse Embeddings e Busca Híbrida

> **Contrato modular**: Explora as funcionalidades avançadas do Qdrant, incluindo FastEmbedSparse, busca híbrida, coleções multi‑tenant, distância customizada e deploy com Docker.

---

## 🎯 Propósito
Otimizar o uso do Qdrant como vector store de alto desempenho, com suporte a busca híbrida (dense + sparse), configuração fina de coleções e isolamento por tenant.

## 📋 Especificação (SDD)
- **Entradas**: Cliente Qdrant, documentos, embeddings dense e sparse.
- **Saídas**: Coleção populada com índices configuráveis.
- **Side Effects**: Armazenamento em disco/memória.
- **Constraints Aplicáveis**: C1 (parâmetros de coleção), C3 (segurança da conexão), C4 (namespaces), C5 (metadados), C7 (reconexão), C8 (métricas de busca).
- **Dependências**: `langchain-qdrant`, `qdrant-client`, `fastembed`.

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

### 1. Criação de Coleção Customizada
```python
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, SparseVectorParams, SparseIndexParams
from langchain_qdrant import QdrantVectorStore, FastEmbedSparse
from langchain_openai import OpenAIEmbeddings

client = QdrantClient("http://localhost:6333")
embeddings = OpenAIEmbeddings()
vector_size = len(embeddings.embed_query("test"))

if not client.collection_exists("mantis_hybrid"):
    client.create_collection(
        collection_name="mantis_hybrid",
        vectors_config={"dense": VectorParams(size=vector_size, distance=Distance.COSINE)},
        sparse_vectors_config={"sparse": SparseVectorParams(index=SparseIndexParams())}
    )
    mantis_log("INFO", "collection_created", "mantis_hybrid com dense+sparse")
```

### 2. Uso de FastEmbedSparse para Embeddings Esparsos
```python
sparse_embeddings = FastEmbedSparse(model_name="prithivida/Splade_PP_en_v1")
vectorstore = QdrantVectorStore(
    client=client,
    collection_name="mantis_hybrid",
    embedding=embeddings,
    sparse_embedding=sparse_embeddings,
    vector_name="dense",
    sparse_vector_name="sparse"
)

# Adicionar documentos com ambos embeddings
docs = [
    Document(page_content="Qdrant é uma engine de busca vetorial.", metadata={"source": "docs"}),
    Document(page_content="Busca híbrida combina vetores densos e sparse.", metadata={"source": "docs"}),
]
vectorstore.add_documents(docs)
```

### 3. Busca Híbrida com Reciprocal Rank Fusion
```python
from langchain.retrievers import QdrantHybridRetriever
retriever = vectorstore.as_retriever(
    search_type="hybrid",
    search_kwargs={"k": 5, "fetch_k": 20, "fusion_type": "rrf"}
)
docs = retriever.invoke("Como funciona a busca híbrida?")
for doc in docs:
    print(doc.page_content)
```

### 4. Filtro Avançado por Payload (Metadados)
```python
from qdrant_client.models import Filter, FieldCondition, MatchValue

results = vectorstore.similarity_search(
    "consulta",
    k=5,
    filter=Filter(
        must=[
            FieldCondition(key="tenant_id", match=MatchValue(value="acme"))
        ]
    )
)
```

### 5. Isolamento por Tenant usando Coleções Separadas
```python
def get_tenant_collection(tenant_id):
    collection_name = f"docs_{tenant_id}"
    if not client.collection_exists(collection_name):
        client.create_collection(collection_name, vectors_config=VectorParams(size=vector_size, distance=Distance.COSINE))
    return QdrantVectorStore(client=client, collection_name=collection_name, embedding=embeddings)

tenant_store = get_tenant_collection("acme")
tenant_store.add_documents([Document("Documento confidencial da Acme")])
```

### 6. Deploy com Docker Compose
```yaml
services:
  qdrant:
    image: qdrant/qdrant:latest
    volumes:
      - qdrant_storage:/qdrant/storage
    ports:
      - "6333:6333"
      - "6334:6334"
    environment:
      QDRANT__SERVICE__GRPC_PORT: 6334
      QDRANT__LOG_LEVEL: INFO
    restart: unless-stopped
volumes:
  qdrant_storage:
```

### 7. Health Check e Métricas
```python
def health_check():
    try:
        collections = client.get_collections()
        mantis_log("INFO", "qdrant_health", f"Coleções: {len(collections.collections)}")
        return True
    except Exception as e:
        mantis_log("ERROR", "qdrant_health", str(e))
        return False
```

---

## 🧪 Testes Unitários (TDD)
```python
def test_qdrant_hybrid():
    from qdrant_client import QdrantClient
    client = QdrantClient(":memory:")
    client.create_collection("test", vectors_config={"dense": VectorParams(size=1536, distance=Distance.COSINE)}, sparse_vectors_config={"sparse": SparseVectorParams()})
    assert client.collection_exists("test")
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/qdrant-vectorstore-advanced.md --json
```

---

## 🔗 Referências Cruzadas
- [[rag-hybrid-search.md]]
- [[database-vectorstore-unified.md]]
