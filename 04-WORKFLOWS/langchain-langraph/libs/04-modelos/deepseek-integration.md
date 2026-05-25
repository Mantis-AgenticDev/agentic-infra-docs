---
artifact_id: "deepseek-integration"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deepseek-integration.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deepseek-integration.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deepseek-v1.0.0"
generated_at: "2026-05-25T06:40:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["multi-model-openrouter-integration"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🤖 DeepSeek Integration – Chat e Reasoning com DeepSeek‑V3 e R1

> **Contrato modular**: Detalha o uso de `ChatDeepSeek` para acessar os modelos DeepSeek‑V3 (chat) e DeepSeek‑R1 (reasoner), com tool calling, structured output e controle de raciocínio.

---

## 🎯 Propósito
Integrar os modelos DeepSeek ao ecossistema MANTIS, aproveitando seu excelente desempenho em raciocínio e custo‑benefício.

## 📋 Especificação (SDD)
- **Entradas**: API key DeepSeek, modelo (`deepseek-chat` ou `deepseek-reasoner`).
- **Saídas**: Respostas textuais ou com tool calls.
- **Side Effects**: Chamadas de API.
- **Constraints**: C1, C3, C5, C7, C8.
- **Dependências**: `langchain-deepseek`.

---

## 🛡️ Bootstrap (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Instanciação e Uso Básico
```python
from langchain_deepseek import ChatDeepSeek
llm = ChatDeepSeek(model="deepseek-chat", temperature=0)
messages = [("system", "Você é um tradutor."), ("human", "I love programming.")]
ai_msg = llm.invoke(messages)
print(ai_msg.content)  # "J'adore la programmation."
```

### 2. Tool Calling (V3)
```python
from pydantic import BaseModel

class Calculator(BaseModel):
    expression: str

llm_with_tools = llm.bind_tools([Calculator])
ai_msg = llm_with_tools.invoke("Quanto é 25*17?")
```

### 3. Structured Output com `with_structured_output`
```python
from pydantic import BaseModel
class Joke(BaseModel):
    setup: str
    punchline: str

structured_llm = llm.with_structured_output(Joke)
result = structured_llm.invoke("Conte uma piada sobre programação.")
print(result.setup)
```

### 4. Modelo de Raciocínio (deepseek-reasoner)
```python
reasoner = ChatDeepSeek(model="deepseek-reasoner", max_tokens=4096)
response = reasoner.invoke("Qual é a raiz quadrada de 529?")
# A resposta incluirá raciocínio interno
```

---

## 🧪 Testes Unitários (TDD)
```python
def test_deepseek_basic():
    llm = ChatDeepSeek(model="deepseek-chat", temperature=0)
    assert llm.model_name == "deepseek-chat"
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deepseek-integration.md --json
```

---

## 🔗 Referências Cruzadas
- [[multi-model-openrouter-integration.md]]
