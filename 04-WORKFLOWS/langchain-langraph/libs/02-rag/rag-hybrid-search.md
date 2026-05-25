---
artifact_id: "rag-hybrid-search"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/rag-hybrid-search.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/rag-hybrid-search.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:rag-hybrid-search-v1.0.0"
generated_at: "2026-05-25T00:20:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["rag-advanced-patterns", "rag-production"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🔀 RAG Hybrid Search – Combinação de Busca Densa e Esparsa (BM25)

> **Contrato modular**: Implementa busca híbrida (dense + sparse) usando Qdrant e re‑ranqueamento RRF, maximizando a cobertura e a precisão.

---

## 🎯 Propósito
Superar as limitações da busca puramente vetorial adicionando busca por palavras‑chave (BM25), resultando em melhor recall para consultas factuais e específicas.

## 📋 Especificação (SDD)
- **Entradas**: Vector store híbrida configurada (ex: Qdrant com sparse vectors), consulta.
- **Saídas**: Lista de documentos combinada via Reciprocal Rank Fusion (RRF).
- **Side Effects**: Nenhum.
- **Constraints**: C1 (estrutura de índice), C3 (proteção de chaves), C5 (formato de saída), C7 (fallback), C8 (métricas de busca).
- **Dependências**: `qdrant-client`, `fastembed` (BM25), `langchain-qdrant`.

---

## 🛡️ Bootstrap (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ... (fallback)
```

### 1. Configuração da Coleção Híbrida no Qdrant
```python
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, SparseVectorParams

client = QdrantClient("http://localhost:6333")
client.create_collection(
    collection_name="hybrid_docs",
    vectors_config={"dense": VectorParams(size=1024, distance=Distance.COSINE)},
    sparse_vectors_config={"sparse": SparseVectorParams()}
)
mantis_log("INFO", "hybrid_collection", "Coleção híbrida criada no Qdrant")
```

### 2. Indexação de Documentos com Vetores Densos e Esparsos
```python
from langchain_qdrant import QdrantVectorStore, FastEmbedSparse
from langchain_openai import OpenAIEmbeddings

# Embedding denso
dense_embeddings = OpenAIEmbeddings(model="text-embedding-3-small", dimensions=1024)
# Embedding esparso (BM25)
sparse_embeddings = FastEmbedSparse(model_name="prithivida/Splade_PP_en_v1")

vectorstore = QdrantVectorStore(
    client=client,
    collection_name="hybrid_docs",
    embedding=dense_embeddings,
    sparse_embedding=sparse_embeddings,
    vector_name="dense",
    sparse_vector_name="sparse"
)
vectorstore.add_documents(docs)
mantis_log("INFO", "hybrid_upsert", f"{len(docs)} documentos indexados")
```

### 3. Busca Híbrida com RRF
```python
retriever = vectorstore.as_retriever(
    search_type="hybrid",  # Ativa busca híbrida
    search_kwargs={
        "k": 5,
        "fetch_k": 20,
        "fusion_type": "rrf"  # Reciprocal Rank Fusion
    }
)
docs = retriever.invoke("como implementar segurança?")
mantis_log("INFO", "hybrid_search", f"{len(docs)} docs via RRF")
```

### 4. Implementação Manual do RRF (Caso o Retriever Não Suporte)
```python
def reciprocal_rank_fusion(dense_results, sparse_results, k=60, top_n=5):
    scores = {}
    for rank, doc in enumerate(dense_results):
        scores[doc.page_content] = scores.get(doc.page_content, 0) + 1 / (k + rank)
    for rank, doc in enumerate(sparse_results):
        scores[doc.page_content] = scores.get(doc.page_content, 0) + 1 / (k + rank)
    ranked = sorted(scores.items(), key=lambda x: x[1], reverse=True)
    return [content for content, _ in ranked[:top_n]]

# Exemplo de uso
dense_docs = dense_retriever.invoke(query)
sparse_docs = sparse_retriever.invoke(query)
fused_docs = reciprocal_rank_fusion(dense_docs, sparse_docs)
mantis_log("INFO", "manual_rrf", f"{len(fused_docs)} documentos fusionados")
```

### 5. Combinação com Re‑ranking Final
```python
def hybrid_with_rerank(query: str):
    # Busca híbrida
    hybrid_docs = retriever.invoke(query)
    # Re‑ranking com CrossEncoder
    ranked = local_rerank(query, hybrid_docs, top_n=3)
    mantis_log("INFO", "hybrid_reranked", f"{len(ranked)} docs após re‑ranking")
    return ranked
```

---

## 🧪 Testes Unitários (TDD)
```python
def test_rrf_combines():
    dense = [Document("A"), Document("B")]
    sparse = [Document("B"), Document("C")]
    fused = reciprocal_rank_fusion(dense, sparse)
    assert len(fused) == 3  # A,B,C
    assert fused[0] in ["A", "B", "C"]
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/rag-hybrid-search.md --json
```

---

## 🔗 Referências Cruzadas
- [[rag-vector-stores.md]]
- [[rag-retrieval-strategies.md]]
