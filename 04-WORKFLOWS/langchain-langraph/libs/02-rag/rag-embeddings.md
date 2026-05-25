---
artifact_id: "rag-embeddings"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/rag-embeddings.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/rag-embeddings.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:rag-embeddings-v1.0.0"
generated_at: "2026-05-24T23:58:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["rag-vector-stores", "rag-retrieval-strategies", "rag-hybrid-search"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🧮 RAG Embeddings – Modelos, Dimensionalidade e Otimização

> **Contrato modular**: Detalha a seleção, uso e boas práticas de modelos de embedding para RAG, incluindo OpenAI, HuggingFace, Cohere e modelos locais, com foco em consistência e custo.

---

## 🎯 Propósito
Garantir que os embeddings utilizados sejam compatíveis, eficientes e de alta qualidade, servindo como base para uma recuperação precisa no ecossistema MANTIS.

## 📋 Especificação (SDD)
- **Entradas**: Textos a serem vetorizados, escolha do modelo.
- **Saídas**: Vetores (listas de floats) prontos para indexação e busca.
- **Side Effects**: Chamadas de API que podem incorrer em custos.
- **Constraints Aplicáveis**: C1 (dimensionalidade fixa), C3 (não expor API keys), C5 (validação de saída), C7 (retry em falhas), C8 (rastreio de uso).
- **Dependências**: `langchain-openai`, `sentence-transformers`, `cohere`, `huggingface_hub`.

---

## 🛡️ Bootstrap Resiliente (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ... (fallback)
```

### 1. Modelos OpenAI
```python
from langchain_openai import OpenAIEmbeddings

# Modelo padrão (text-embedding-3-small)
embeddings = OpenAIEmbeddings(model="text-embedding-3-small", dimensions=1536)

# Modelo grande com redução de dimensionalidade (economia de custo)
embeddings_large = OpenAIEmbeddings(model="text-embedding-3-large", dimensions=256)

# Batch para eficiência
texts = ["doc1", "doc2", "doc3"]
vectors = embeddings.embed_documents(texts)
mantis_log("INFO", "openai_embeddings", f"{len(vectors)} vetores gerados, dim={len(vectors[0])}")
```

### 2. Modelos HuggingFace (Locais, Sem Custo de API)
```python
from langchain_huggingface import HuggingFaceEmbeddings

# Modelo leve e rápido (384 dims)
embeddings_fast = HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2")

# Modelo de alta qualidade (1024 dims) – recomendado MANTIS
embeddings_bge = HuggingFaceEmbeddings(model_name="BAAI/bge-large-en-v1.5")

# Com GPU
embeddings_gpu = HuggingFaceEmbeddings(
    model_name="intfloat/multilingual-e5-large",
    model_kwargs={"device": "cuda"},
    encode_kwargs={"normalize_embeddings": True}
)
mantis_log("INFO", "local_embeddings", f"Modelo {embeddings_bge.model_name} carregado")
```

### 3. Cohere (API) e Sentence Transformers
```python
# Cohere (API)
from langchain_cohere import CohereEmbeddings
embeddings_cohere = CohereEmbeddings(model="embed-english-v3.0")

# Sentence Transformers puro (sem langchain)
from sentence_transformers import SentenceTransformer
model = SentenceTransformer("BAAI/bge-large-en-v1.5")
embeddings = model.encode(["texto1", "texto2"], batch_size=32, show_progress_bar=True)
mantis_log("INFO", "sbert_encode", f"{len(embeddings)} vetores, dim={embeddings.shape[1]}")
```

### 4. Tabela Comparativa de Modelos
| Modelo | Dims | Custo (aprox) | Qualidade | Velocidade |
|--------|------|---------------|-----------|------------|
| text-embedding-3-small | 1536 | $0.02/1M tokens | Boa | Rápida |
| text-embedding-3-large | 3072 (256) | $0.13/1M tokens | Excelente | Média |
| all-MiniLM-L6-v2 | 384 | Grátis (local) | Boa | Muito rápida |
| BAAI/bge-large-en-v1.5 | 1024 | Grátis (local) | Ótima | Média |
| embed-english-v3.0 (Cohere) | 1024 | $0.10/1M tokens | Excelente | Rápida |
| E5-large-v2 | 1024 | Grátis (local) | Excelente | Lenta |

### 5. Consistência entre Indexação e Consulta – O Erro Fatal
```python
# ❌ ERRADO: embeddings diferentes para indexar e consultar
index_embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
query_embeddings = OpenAIEmbeddings(model="text-embedding-3-large")
# Resultado: vetores de dimensões diferentes -> erro de similaridade

# ✅ CERTO: mesmo modelo sempre
embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
vectorstore = Chroma(embedding_function=embeddings, ...)
retriever = vectorstore.as_retriever()  # usa a mesma função de embedding
mantis_log("INFO", "embedding_consistency", "Mesmo modelo para index e query")
```

### 6. Cache de Embeddings para Economia
```python
from langchain.embeddings import CacheBackedEmbeddings
from langchain.storage import LocalFileStore

store = LocalFileStore("./embedding_cache")
cached_embeddings = CacheBackedEmbeddings.from_bytes_store(
    underlying_embeddings=embeddings,
    document_embedding_cache=store,
    namespace="openai-embeddings"
)
# Agora, textos idênticos não serão re-embedidos, poupando chamadas de API
mantis_log("INFO", "embedding_cache", "Cache de embeddings ativado")
```

### 7. Processamento em Lote e Resiliência
```python
import time
def embed_with_retry(texts, embeddings, batch_size=50, max_retries=3):
    all_vectors = []
    for i in range(0, len(texts), batch_size):
        batch = texts[i:i+batch_size]
        for attempt in range(max_retries):
            try:
                vectors = embeddings.embed_documents(batch)
                all_vectors.extend(vectors)
                break
            except Exception as e:
                mantis_log("ERROR", "embed_failed", f"Lote {i//batch_size}: {e}")
                if attempt == max_retries - 1:
                    raise
                time.sleep(2 ** attempt)
    mantis_log("INFO", "embed_batch_done", f"{len(all_vectors)} vetores gerados")
    return all_vectors
```

---

## 🧪 Testes Unitários (TDD)
```python
def test_embedding_dimensions():
    emb = OpenAIEmbeddings(model="text-embedding-3-small", dimensions=256)
    vec = emb.embed_query("teste")
    assert len(vec) == 256

def test_cache_backed_embeddings():
    store = LocalFileStore("./test_cache")
    cached = CacheBackedEmbeddings.from_bytes_store(OpenAIEmbeddings(), store)
    vec1 = cached.embed_query("teste")
    vec2 = cached.embed_query("teste")
    # Ambas devem retornar o mesmo (possivelmente do cache)
    assert len(vec1) == len(vec2)
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/rag-embeddings.md \
  --json --check-structural --check-error-handling
```

---

## 🔗 Referências Cruzadas
- [[rag-vector-stores.md]]
- [[rag-fundamentals.md]]

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal |
|--------|------|-------|------------------|
| 1.0.0 | 2026-05-24T23:58:00Z | langchain-langraph-master-agent | Criação inicial: todos modelos de embedding |
