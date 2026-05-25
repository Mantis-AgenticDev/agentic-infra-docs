---
artifact_id: "rag-multi-modal"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/rag-multi-modal.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/rag-multi-modal.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:rag-multimodal-v1.0.0"
generated_at: "2026-05-25T00:25:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["file-processing", "integration-postgres-pgvector"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🖼️ RAG Multi‑Modal – Documentos com Imagens, Tabelas e Gráficos

> **Contrato modular**: Expande o RAG para processar e recuperar informações de documentos multi‑modais (PDF com imagens, tabelas) usando técnicas de extração visual e embeddings multi‑modais.

---

## 🎯 Propósito
Permitir que agentes MANTIS respondam a perguntas que dependem de conteúdo visual (gráficos, tabelas) extraindo e indexando esses elementos ao lado do texto.

## 📋 Especificação (SDD)
- **Entradas**: PDFs com imagens/tabelas, consulta potencialmente descrevendo elementos visuais.
- **Saídas**: Resposta que referencia ou descreve o conteúdo visual.
- **Side Effects**: Armazenamento de descrições textuais de imagens no vector store.
- **Constraints**: C1 (tipos de metadados), C5 (estrutura de descrição), C7 (fallback se extração falhar), C8 (logs).
- **Dependências**: `unstructured`, `pytesseract`, `Pillow`, `langchain-community`.

---

## 🛡️ Bootstrap (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ... (fallback)
```

### 1. Extração de Elementos de PDF com `unstructured`
```python
from unstructured.partition.pdf import partition_pdf

elements = partition_pdf(
    filename="relatorio_anual.pdf",
    extract_images_in_pdf=True,
    strategy="hi_res",
    infer_table_structure=True
)
mantis_log("INFO", "pdf_elements", f"Elementos extraídos: {len(elements)}")
```

### 2. Gerando Descrições de Imagens
```python
import base64
from PIL import Image
import io

def generate_image_description(image_bytes):
    # Converte para base64 e chama modelo multimodal (ex: GPT-4o)
    img_base64 = base64.b64encode(image_bytes).decode()
    response = llm_multimodal.invoke([
        {"role": "user", "content": [
            {"type": "text", "text": "Descreva detalhadamente esta imagem."},
            {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{img_base64}"}}
        ]}
    ])
    return response.content

# Exemplo de integração
for element in elements:
    if element.category == "Image":
        desc = generate_image_description(element.metadata.attachment)
        element.metadata["image_description"] = desc
        mantis_log("INFO", "image_desc", desc[:50])
```

### 3. Indexação de Tabelas como Texto Estruturado
```python
def table_to_text(table_element):
    # Converte tabela HTML/markdown do unstructured em texto legível
    if hasattr(table_element, 'metadata') and 'text_as_html' in table_element.metadata:
        return table_element.metadata['text_as_html']
    return str(table_element)

for element in elements:
    if element.category == "Table":
        text_repr = table_to_text(element)
        element.text = text_repr
        mantis_log("INFO", "table_indexed", f"Tabela: {text_repr[:50]}...")
```

### 4. Fluxo Completo de Ingestão Multi‑Modal
```python
def ingest_multimodal_pdf(pdf_path):
    raw_elements = partition_pdf(pdf_path, extract_images_in_pdf=True, strategy="hi_res")
    documents = []
    for el in raw_elements:
        metadata = {"source": pdf_path, "type": el.category}
        content = ""
        if el.category == "Image":
            desc = generate_image_description(el.metadata.attachment)
            content = f"[Imagem]: {desc}"
            metadata["image_description"] = desc
        elif el.category == "Table":
            content = f"[Tabela]:\n{table_to_text(el)}"
        else:
            content = el.text
        documents.append(Document(page_content=content, metadata=metadata))
    # Chunking e indexação normais...
    splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=150)
    chunks = splitter.split_documents(documents)
    vectorstore.add_documents(chunks)
    mantis_log("INFO", "multimodal_ingest", f"{len(chunks)} chunks indexados")
```

### 5. Consulta Multi‑Modal
```python
def multimodal_query(question: str, retriever, llm_multimodal):
    docs = retriever.invoke(question)
    # Se algum documento for imagem, incluir referência
    context_parts = []
    for doc in docs:
        if doc.metadata.get("type") == "Image":
            context_parts.append(f"[Descrição de imagem]: {doc.page_content}")
        else:
            context_parts.append(doc.page_content)
    context = "\n\n".join(context_parts)
    prompt = f"Contexto:\n{context}\n\nPergunta: {question}\nResposta:"
    return llm_multimodal.invoke(prompt).content
```

---

## 🧪 Testes Unitários (TDD)
```python
def test_image_description_generation():
    # Teste com imagem fake (1x1 pixel)
    img = Image.new('RGB', (1,1))
    buf = io.BytesIO()
    img.save(buf, 'JPEG')
    # Assume llm_multimodal mock
    desc = generate_image_description(buf.getvalue())
    assert isinstance(desc, str)
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/rag-multi-modal.md --json
```

---

## 🔗 Referências Cruzadas
- [[rag-chunking-strategies.md]]
- [[file-processing.md]]
