---
artifact_id: "deep-agents-model-integration"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-model-integration.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-model-integration.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-model-integration-v1.0.0"
generated_at: "2026-05-25T20:15:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-core-customization"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🤖 Deep Agents – Integração de Modelos (OpenAI, Anthropic, Gemini, OpenRouter, Ollama)

> **Contrato modular**: Artefato filho do Master Agent. Mostra como integrar todos os provedores de LLM suportados em Deep Agents, com exemplos de configuração e boas práticas para cada um.

---

## 🎯 Propósito
Permitir que agentes MANTIS usem qualquer modelo de LLM disponível, com configurações otimizadas por provedor.

## 📋 Especificação (SDD)
- **Entradas**: Nome do modelo, credenciais.
- **Saídas**: Modelo configurado para uso em `create_deep_agent`.
- **Side Effects**: Conexão com APIs externas.
- **Constraints Aplicáveis**: C1 (formato provider:model), C3 (proteção de API keys), C5 (schema de resposta), C7 (retry), C8 (logs de uso).
- **Dependências**: `langchain-openai`, `langchain-anthropic`, `langchain-google-genai`, `langchain-openrouter`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    import json, datetime, os
    def mantis_log(level, event, detail=""):
        entry = {"ts": datetime.datetime.utcnow().isoformat() + "Z", "level": level, "tenant": os.getenv("TENANT_ID", "global"), "event": event, "detail": detail, "trace_id": os.getenv("TRACE_ID", "null"), "span_id": os.getenv("SPAN_ID", "null"), "fallback": "true"}
        print(json.dumps(entry), flush=True)
```

### 1. OpenAI

```python
from deepagents import create_deep_agent
import os

agent = create_deep_agent(model="openai:gpt-5.4")
# Ou com instância personalizada
from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5.4", temperature=0.2)
agent = create_deep_agent(model=model)
```

### 2. Anthropic

```python
agent = create_deep_agent(model="anthropic:claude-sonnet-4-6")
# Ou via classe
from langchain_anthropic import ChatAnthropic
model = ChatAnthropic(model="claude-sonnet-4-6", temperature=0.3)
agent = create_deep_agent(model=model)
```

### 3. Google Gemini

```python
agent = create_deep_agent(model="google_genai:gemini-3.5-flash")
# Ou via classe
from langchain_google_genai import ChatGoogleGenerativeAI
model = ChatGoogleGenerativeAI(model="gemini-3.5-flash")
agent = create_deep_agent(model=model)
```

### 4. OpenRouter

```python
agent = create_deep_agent(model="openrouter:anthropic/claude-sonnet-4-6")
```

### 5. AWS Bedrock

```python
agent = create_deep_agent(
    model="anthropic.claude-sonnet-4-6",
    model_provider="bedrock_converse",
)
```

### 6. HuggingFace

```python
agent = create_deep_agent(
    model="microsoft/Phi-3-mini-4k-instruct",
    model_provider="huggingface",
    temperature=0.7,
    max_tokens=1024,
)
```

### 7. Ollama (Modelos Locais)

```python
agent = create_deep_agent(model="ollama:llama3.1")
```

### 8. Fireworks

```python
agent = create_deep_agent(model="fireworks:accounts/fireworks/models/llama-v3p1-70b-instruct")
```

### 9. Baseten

```python
agent = create_deep_agent(model="baseten:zai-org/GLM-5")
```

### 10. Seleção Dinâmica de Modelo

```python
def create_agent_for_task(task: str):
    if "code" in task.lower():
        return create_deep_agent(model="anthropic:claude-sonnet-4-6")
    elif "research" in task.lower():
        return create_deep_agent(model="google_genai:gemini-3.5-flash")
    else:
        return create_deep_agent(model="openai:gpt-5.4")
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_model_string_format():
    assert "openai:gpt-5.4"  # Formato provider:model
    assert "anthropic:claude-sonnet-4-6"
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-model-integration.md --json
```

---

## 🔗 Referências Cruzadas
- [[deep-agents-core-customization.md]]
