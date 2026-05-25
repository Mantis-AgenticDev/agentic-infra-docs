---
artifact_id: "gemini-context-caching"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/gemini-context-caching.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/gemini-context-caching.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:gemini-context-cache-v1.0.0"
generated_at: "2026-05-25T07:40:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["gemini-tool-calling-built-in", "cost-optimization"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# ⚡ Gemini Context Caching – Cache de Arquivos e Instruções

> **Contrato modular**: Ensina a usar o context caching do Gemini para reduzir custos e latência ao reutilizar arquivos e system prompts grandes.

---

## 🎯 Propósito
Permitir que agentes MANTIS façam uso eficiente de grandes contextos (PDFs, vídeos) sem reenviá-los a cada requisição.

## 📋 Especificação (SDD)
- **Entradas**: Arquivo ou conteúdo a ser cacheado.
- **Saídas**: Cache criado, referenciado via nome.
- **Constraints**: C1 (TTL e nomenclatura), C3 (dados sensíveis em cache), C7 (falha na criação do cache).
- **Dependências**: `google-genai`.

---

## 🛡️ Bootstrap (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Cache de um Único Arquivo
```python
import time
from google import genai
from google.genai import types

client = genai.Client()
file = client.files.upload(file="manual.pdf")
while file.state.name == "PROCESSING":
    time.sleep(2)
    file = client.files.get(name=file.name)

cache = client.caches.create(
    model="gemini-3.5-flash",
    config=types.CreateCachedContentConfig(
        display_name="manual",
        system_instruction="Você é um especialista no manual.",
        contents=[file],
        ttl="3600s",
    ),
)

# Uso com LangChain
llm = ChatGoogleGenerativeAI(model="gemini-3.5-flash", cached_content=cache.name)
```

### 2. Cache de Múltiplos Arquivos
```python
contents = [
    Content(role="user", parts=[
        Part.from_uri(file_uri=file1.uri, mime_type=file1.mime_type),
        Part.from_uri(file_uri=file2.uri, mime_type=file2.mime_type),
    ])
]
cache = client.caches.create(model=..., config=CreateCachedContentConfig(contents=contents, ttl="300s"))
```

---

## 🧪 Testes Unitários (TDD)
```python
# Teste de criação de cache mock
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/gemini-context-caching.md --json
```

---

## 🔗 Referências Cruzadas
- [[gemini-tool-calling-built-in.md]]
- [[cost-optimization.md]]
