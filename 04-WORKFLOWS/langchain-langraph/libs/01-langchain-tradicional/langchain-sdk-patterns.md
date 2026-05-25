---
artifact_id: "langchain-sdk-patterns"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/langchain-sdk-patterns.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/langchain-sdk-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:langchain-sdk-patterns-v1.0.0"
generated_at: "2026-05-26T16:30:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["langchain-streaming-patterns"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-26"
---

# 🧩 LangChain SDK Patterns – Structured Output, Fallbacks, Batch e Caching

> **Contrato modular**: Artefato filho do Master Agent. Documenta padrões de produção essenciais: structured output com Zod, provider fallbacks, async batch, caching com SQLite e RunnableLambda.

---

## 🎯 Propósito
Garantir que agentes MANTIS tradicionais usem padrões robustos de código para produção, incluindo saídas tipadas, fallback entre provedores e processamento em lote.

## 📋 Especificação (SDD)
- **Entradas**: Modelos, schemas Zod, configurações de cache.
- **Saídas**: Código resiliente e tipado.
- **Side Effects**: Cache em disco.
- **Constraints Aplicáveis**: C1 (tipagem), C3 (proteção), C5 (schema), C7 (fallback), C8 (logs).
- **Dependências**: `langchain`, `zod`, `sqlite3`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Structured Output com Zod (Python)

```python
from pydantic import BaseModel, Field
from langchain_openai import ChatOpenAI

class ContactInfo(BaseModel):
    name: str = Field(description="Nome completo")
    email: str = Field(pattern=r"^[^@]+@[^@]+\.[^@]+$")
    phone: str

llm = ChatOpenAI(model="gpt-4o-mini")
structured_llm = llm.with_structured_output(ContactInfo)
result = structured_llm.invoke("Extraia: John Doe, john@example.com, (555) 123-4567")
```

### 2. Provider Fallbacks

```python
from langchain_openai import ChatOpenAI
from langchain_anthropic import ChatAnthropic

primary = ChatOpenAI(model="gpt-4o", max_retries=2, timeout=10)
fallback = ChatAnthropic(model="claude-sonnet-4-20250514")
robust_model = primary.with_fallbacks([fallback])
chain = prompt | robust_model | StrOutputParser()
```

### 3. Async Batch com Concorrência

```python
from langchain_openai import ChatOpenAI
chain = ChatPromptTemplate.from_template("Resuma: {text}") | ChatOpenAI(model="gpt-4o-mini") | StrOutputParser()

texts = ["Artigo 1...", "Artigo 2...", "Artigo 3..."]
inputs = [{"text": t} for t in texts]
results = await chain.abatch(inputs, config={"max_concurrency": 5})
```

### 4. Caching com SQLite

```python
from langchain_community.cache import SQLiteCache
from langchain_core.globals import set_llm_cache

set_llm_cache(SQLiteCache(database_path=".langchain_cache.db"))
# Chamadas idênticas subsequentes usarão cache
```

### 5. RunnableLambda para Lógica Customizada

```python
from langchain_core.runnables import RunnableLambda

clean_input = RunnableLambda(lambda x: {"text": x["text"].strip().lower()})
add_metadata = RunnableLambda(lambda result: {"answer": result, "timestamp": datetime.now().isoformat()})

chain = clean_input | prompt | llm | StrOutputParser() | add_metadata
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_structured_output():
    llm = ChatOpenAI(model="gpt-4o-mini")
    structured = llm.with_structured_output(ContactInfo)
    assert structured is not None
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/langchain-sdk-patterns.md --json
```

---

## 🔗 Referências Cruzadas
- [[langchain-streaming-patterns.md]]
