---
artifact_id: "rag-chunking-strategies"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/rag-chunking-strategies.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/rag-chunking-strategies.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:rag-chunking-v1.0.0"
generated_at: "2026-05-24T23:57:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["rag-fundamentals", "rag-advanced-patterns", "rag-multi-modal"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# ✂️ RAG Chunking Strategies – Estratégias de Segmentação de Documentos

> **Contrato modular**: Artefato filho do Master Agent. Aborda todas as técnicas de chunking (recursive, token‑aware, semântico, code‑aware, markdown) com exemplos e parâmetros otimizados para RAG.

---

## 🎯 Propósito
Garantir que os documentos sejam divididos em chunks de tamanho ideal, preservando contexto, evitando cortes semânticos e maximizando a qualidade da recuperação para agentes MANTIS.

## 📋 Especificação (SDD)
- **Entradas**: Documentos brutos (PDF, HTML, texto, código), configuração de tamanho e overlap.
- **Saídas**: Lista de `Document` com conteúdo e metadados de chunk.
- **Side Effects**: Pode modificar atributos de metadados (ex: `chunk_index`).
- **Constraints Aplicáveis**: C1 (tamanho determinístico), C5 (estrutura de saída), C7 (fallback se splitter falhar).
- **Dependências**: `langchain_text_splitters`, `tiktoken` (para token-aware).

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ... (mesmo fallback)
```

### 1. RecursiveCharacterTextSplitter – O Canivete Suíço
```python
from langchain_text_splitters import RecursiveCharacterTextSplitter

splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000,          # Tamanho em caracteres
    chunk_overlap=200,        # 20% de overlap
    length_function=len,
    separators=["\n\n", "\n", ". ", " ", ""],  # Hierarquia de splits
    is_separator_regex=False
)

documents = splitter.create_documents([texto_longo])
mantis_log("INFO", "recursive_split", f"{len(documents)} chunks criados")
```

### 2. TokenTextSplitter – Para Modelos com Limite Exato de Tokens
```python
from langchain_text_splitters import TokenTextSplitter

splitter = TokenTextSplitter(
    chunk_size=512,       # tokens
    chunk_overlap=50,
    encoding_name="cl100k_base"  # OpenAI
)
chunks = splitter.split_documents(docs)
```

### 3. SemanticChunker – Agrupamento por Significado (Experimental)
```python
from langchain_experimental.text_splitter import SemanticChunker
from langchain_openai import OpenAIEmbeddings

embeddings = OpenAIEmbeddings()
splitter = SemanticChunker(
    embeddings=embeddings,
    breakpoint_threshold_type="percentile",  # "standard_deviation", "interquartile"
    breakpoint_threshold_amount=90  # alto = menos chunks
)
semantic_chunks = splitter.split_documents(docs)
mantis_log("INFO", "semantic_chunks", f"{len(semantic_chunks)} chunks semânticos")
```

### 4. Code Splitters (Python, JS, Markdown, etc.)
```python
from langchain_text_splitters import (
    PythonCodeTextSplitter,
    RecursiveCharacterTextSplitter,
    Language
)

python_splitter = RecursiveCharacterTextSplitter.from_language(
    language=Language.PYTHON,
    chunk_size=500,
    chunk_overlap=50
)
py_chunks = python_splitter.split_documents(python_docs)

# Markdown com cabeçalhos
from langchain_text_splitters import MarkdownHeaderTextSplitter

headers_to_split_on = [
    ("#", "h1"),
    ("##", "h2"),
    ("###", "h3"),
]
md_splitter = MarkdownHeaderTextSplitter(headers_to_split_on=headers_to_split_on)
md_chunks = md_splitter.split_text(markdown_text)
mantis_log("INFO", "md_chunks", f"{len(md_chunks)} chunks markdown")
```

### 5. Combinando Splitters: Pré‑Split por Página, Depois Recursive
```python
from langchain_community.document_loaders import PyPDFLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter

loader = PyPDFLoader("relatorio.pdf")
pages = loader.load()  # Cada página como um documento

text_splitter = RecursiveCharacterTextSplitter(chunk_size=800, chunk_overlap=100)
chunks = []
for i, page in enumerate(pages):
    page_chunks = text_splitter.split_documents([page])
    for c in page_chunks:
        c.metadata["page"] = i  # Mantém rastreabilidade
    chunks.extend(page_chunks)
mantis_log("INFO", "page_split", f"{len(pages)} páginas, {len(chunks)} chunks")
```

### 6. Boas Práticas de Tamanho e Overlap

| Tipo de Documento | Tamanho Recomendado | Overlap | Comentário |
|-------------------|---------------------|---------|-------------|
| Texto corrido (artigos) | 800–1200 chars | 20% | Recursive com overlap |
| Código | 500–800 chars | 10% | Linguagem específica |
| Documentação técnica | 1000–1500 chars | 200 chars | Markdown header-aware |
| PDF com muitas tabelas | 1500–2000 chars | 300 chars | Evitar split no meio de tabelas |

### 7. Pipeline de Ingestão Robusta com Verificação
```python
def ingest_with_chunking(source_loader, chunk_size=1000, overlap=200):
    docs = source_loader.load()
    mantis_log("INFO", "ingest_load", f"{len(docs)} documentos")
    splitter = RecursiveCharacterTextSplitter(
        chunk_size=chunk_size,
        chunk_overlap=overlap,
        separators=["\n\n", "\n", ". ", " ", ""]
    )
    chunks = splitter.split_documents(docs)
    # Verificação de integridade
    if not chunks:
        mantis_log("ERROR", "no_chunks", "Nenhum chunk gerado. Aumente chunk_size ou revise loader.")
        return []
    # Adicionar metadados de chunk
    for i, chunk in enumerate(chunks):
        chunk.metadata["chunk_index"] = i
        chunk.metadata["chunk_size"] = len(chunk.page_content)
    mantis_log("INFO", "ingest_complete", f"{len(chunks)} chunks com metadados")
    return chunks
```

### 8. Antipadrões e Correções
```python
# ERRADO: chunks muito pequenos perdem contexto
splitter = RecursiveCharacterTextSplitter(chunk_size=50)

# CERTO: mínimo de ~300 chars
splitter = RecursiveCharacterTextSplitter(chunk_size=500)

# ERRADO: sem overlap, quebra fluxo semântico
splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=0)

# CERTO: 10-20% de overlap
splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200)
```

---

## 🧪 Testes Unitários (TDD)
```python
def test_recursive_splitter_creates_chunks():
    text = "Frase um. Frase dois. Frase três." * 100
    splitter = RecursiveCharacterTextSplitter(chunk_size=50, chunk_overlap=5)
    chunks = splitter.split_text(text)
    assert len(chunks) > 1
    assert all(len(c) <= 50 for c in chunks)

def test_metadata_preservation():
    doc = Document(page_content="Conteúdo", metadata={"fonte": "teste"})
    splitter = RecursiveCharacterTextSplitter(chunk_size=10, chunk_overlap=0)
    chunks = splitter.split_documents([doc])
    for c in chunks:
        assert c.metadata["fonte"] == "teste"
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/rag-chunking-strategies.md \
  --json --check-structural --check-error-handling
```

---

## 🔗 Referências Cruzadas
- [[rag-fundamentals.md]]
- [[rag-embeddings.md]]
- [[langchain-langraph-master-agent.md]]

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal |
|--------|------|-------|------------------|
| 1.0.0 | 2026-05-24T23:57:00Z | langchain-langraph-master-agent | Criação inicial: todas estratégias de chunking |
