---
artifact_id: "openrouter-structured-output"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/openrouter-structured-output.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/openrouter-structured-output.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:openrouter-structured-v1.0.0"
generated_at: "2026-05-25T06:20:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["agents-single", "rag-advanced-patterns"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🧾 OpenRouter Structured Output – Respostas Tipadas e Agentes

> **Contrato modular**: Demonstra como obter saídas estruturadas com `ChatOpenRouter` usando `with_structured_output` e `ProviderStrategy`, essencial para agentes que precisam de dados parseáveis.

---

## 🎯 Propósito
Garantir que os agentes MANTIS recebam respostas em formatos previsíveis (Pydantic), facilitando a integração com outros sistemas.

## 📋 Especificação (SDD)
- **Entradas**: Definição de schema Pydantic.
- **Saídas**: Instâncias do modelo Pydantic validadas.
- **Constraints**: C1 (schema), C5 (integridade), C7 (fallback se parsing falhar).
- **Dependências**: `langchain-openrouter`, `pydantic`.

---

## 🛡️ Bootstrap (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. `with_structured_output` com JSON Schema
```python
from pydantic import BaseModel, Field

class Movie(BaseModel):
    title: str
    year: int
    director: str
    rating: float

model = ChatOpenRouter(model="openai/gpt-5.4")
structured_model = model.with_structured_output(Movie, method="json_schema")
response = structured_model.invoke("Dê detalhes do filme Inception")
print(response.title)
```

### 2. Modo Strict
```python
structured_model = model.with_structured_output(Movie, method="json_schema", strict=True)
```

### 3. Uso com `create_agent` e `ProviderStrategy`
```python
from langchain.agents import create_agent
from langchain.agents.structured_output import ProviderStrategy

agent = create_agent(
    model="openrouter:openai/gpt-5.4",
    tools=[weather_tool],
    response_format=ProviderStrategy(Weather),
)
result = agent.invoke({"messages": [{"role": "user", "content": "Clima em SF?"}]})
print(result["structured_response"])
```

---

## 🧪 Testes Unitários (TDD)
```python
def test_structured_output():
    m = ChatOpenRouter(model="openai/gpt-5.4")
    sm = m.with_structured_output(Movie, method="json_schema")
    res = sm.invoke("Inception")
    assert res.title == "Inception"
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/openrouter-structured-output.md --json
```

---

## 🔗 Referências Cruzadas
- [[agents-single.md]]
