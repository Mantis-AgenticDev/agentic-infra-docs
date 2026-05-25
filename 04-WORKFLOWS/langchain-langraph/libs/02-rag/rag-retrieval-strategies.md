---
artifact_id: "rag-retrieval-strategies"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/rag-retrieval-strategies.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/rag-retrieval-strategies.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:rag-retrieval-v1.0.0"
generated_at: "2026-05-25T00:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["rag-advanced-patterns", "rag-hybrid-search", "agents-single"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🔎 RAG Retrieval Strategies – Estratégias de Recuperação e Re‑ranqueamento

> **Contrato modular**: Explora todos os algoritmos de recuperação (similarity, MMR, threshold, multi‑query, contextual compression) e re‑ranqueamento, com exemplos prontos para produção.

---

## 🎯 Propósito
Maximizar a relevância e a diversidade dos documentos recuperados, garantindo que o contexto passado ao LLM seja o mais útil possível, usando técnicas de ponta.

## 📋 Especificação (SDD)
- **Entradas**: Vector store populada, consulta do usuário.
- **Saídas**: Lista de documentos mais relevantes, possivelmente re‑ranqueados.
- **Side Effects**: Nenhum.
- **Constraints Aplicáveis**: C1 (parâmetros de busca), C5 (formato dos documentos), C7 (fallback se nenhum resultado), C8 (rastreio de métricas de busca).
- **Dependências**: `langchain-core`, `cohere` (para re‑ranking), `sentence-transformers`.

---

## 🛡️ Bootstrap Resiliente (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ... (fallback)
```

### 1. Retriever Padrão (Similaridade de Cosseno)
```python
retriever = vectorstore.as_retriever(search_kwargs={"k": 5})
docs = retriever.invoke("consulta")
```

### 2. MMR (Maximal Marginal Relevance) – Diversidade
```python
retriever = vectorstore.as_retriever(
    search_type="mmr",
    search_kwargs={
        "k": 5,
        "fetch_k": 20,        # busca mais para depois diversificar
        "lambda_mult": 0.5    # 0 = máxima diversidade, 1 = máxima similaridade
    }
)
docs = retriever.invoke("consulta")
mantis_log("INFO", "mmr_retrieval", f"MMR retornou {len(docs)} docs")
```

### 3. Similarity Score Threshold – Apenas Resultados Relevantes
```python
retriever = vectorstore.as_retriever(
    search_type="similarity_score_threshold",
    search_kwargs={"score_threshold": 0.7, "k": 5}
)
docs = retriever.invoke("consulta")
# Se nenhum doc atingir o threshold, lista vazia → fallback
if not docs:
    mantis_log("WARN", "low_score", "Nenhum documento acima do threshold")
```

### 4. Multi‑Query Retrieval – Expansão de Consulta
```python
from langchain.retrievers.multi_query import MultiQueryRetriever
from langchain_openai import ChatOpenAI

llm = ChatOpenAI(model="gpt-4.1", temperature=0)
retriever = MultiQueryRetriever.from_llm(
    retriever=vectorstore.as_retriever(),
    llm=llm
)
# Gera várias versões da consulta e combina resultados
docs = retriever.invoke("melhores práticas de segurança em APIs")
mantis_log("INFO", "multi_query", f"{len(docs)} docs únicos")
```

### 5. Contextual Compression – Comprimir Documentos Longos
```python
from langchain.retrievers import ContextualCompressionRetriever
from langchain.retrievers.document_compressors import LLMChainExtractor

compressor = LLMChainExtractor.from_llm(llm)
compression_retriever = ContextualCompressionRetriever(
    base_compressor=compressor,
    base_retriever=vectorstore.as_retriever(search_kwargs={"k": 10})
)
compressed_docs = compression_retriever.invoke("consulta")
# Cada documento terá apenas as partes relevantes extraídas
mantis_log("INFO", "compression", f"{len(compressed_docs)} docs comprimidos")
```

### 6. Re‑ranking com Cohere ou Modelo Local
```python
import cohere
co = cohere.Client(os.getenv("COHERE_API_KEY"))

def rerank_with_cohere(query: str, docs: list, top_n: int = 5):
    texts = [d.page_content for d in docs]
    response = co.rerank(model="rerank-english-v3.0", query=query, documents=texts, top_n=top_n)
    ranked_docs = [docs[r.index] for r in response.results]
    mantis_log("INFO", "rerank_cohere", f"{len(ranked_docs)} docs re-ranqueados")
    return ranked_docs

# Alternativa local com CrossEncoder
from sentence_transformers import CrossEncoder
cross_encoder = CrossEncoder("cross-encoder/ms-marco-MiniLM-L-6-v2")

def local_rerank(query: str, docs: list, top_n: int = 5):
    pairs = [[query, d.page_content] for d in docs]
    scores = cross_encoder.predict(pairs)
    ranked = sorted(zip(docs, scores), key=lambda x: x[1], reverse=True)
    return [doc for doc, _ in ranked[:top_n]]
```

### 7. Self‑Query Retrieval – Metadados Dinâmicos
```python
from langchain.retrievers.self_query.base import SelfQueryRetriever
from langchain.chains.query_constructor.base import AttributeInfo

metadata_field_info = [
    AttributeInfo(name="source", description="Fonte do documento", type="string"),
    AttributeInfo(name="date", description="Data de publicação", type="string"),
]
retriever = SelfQueryRetriever.from_llm(
    llm, vectorstore, document_content_description="Artigos técnicos",
    metadata_field_info=metadata_field_info
)
# Consulta: "documentos sobre IA depois de 2023" → filtra metadados automaticamente
docs = retriever.invoke("documentos sobre IA depois de 2023")
```

### 8. Estratégia de Fallback em Cascata
```python
def cascading_retrieval(query: str):
    # Tenta MMR primeiro
    retriever_mmr = vectorstore.as_retriever(search_type="mmr", search_kwargs={"k": 5, "fetch_k": 15})
    docs = retriever_mmr.invoke(query)
    if docs:
        return docs
    # Fallback para similaridade pura
    retriever_sim = vectorstore.as_retriever(search_kwargs={"k": 3})
    docs = retriever_sim.invoke(query)
    mantis_log("WARN", "mmr_empty_fallback", "Usando similaridade pura")
    return docs
```

---

## 🧪 Testes Unitários (TDD)
```python
def test_mmr_returns_docs():
    docs = retriever_mmr.invoke("teste")
    assert len(docs) <= 5
    # Verifica diversidade (simplificado)
    contents = [d.page_content for d in docs]
    assert len(set(contents)) == len(contents)  # sem duplicados

def test_threshold_fallback():
    retriever = vectorstore.as_retriever(search_type="similarity_score_threshold", search_kwargs={"score_threshold": 0.99})
    docs = retriever.invoke("consulta aleatória")
    assert len(docs) == 0  # não deve achar nada
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/rag-retrieval-strategies.md \
  --json --check-structural --check-error-handling
```

---

## 🔗 Referências Cruzadas
- [[rag-advanced-patterns.md]]
- [[rag-vector-stores.md]]

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal |
|--------|------|-------|------------------|
| 1.0.0 | 2026-05-25T00:00:00Z | langchain-langraph-master-agent | Criação inicial: todas estratégias de retrieval |
