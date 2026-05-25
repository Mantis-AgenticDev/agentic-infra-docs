---
artifact_id: "multi-model-openrouter-integration"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/multi-model-openrouter-integration.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/multi-model-openrouter-integration.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:openrouter-core-v1.0.0"
generated_at: "2026-05-25T06:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["openrouter-provider-routing", "openrouter-structured-output", "model-tracing-sessions"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🌐 Multi‑Model OpenRouter Integration – Hub Unificado de Modelos

> **Contrato modular**: Define o uso do `ChatOpenRouter` como ponto único de acesso a dezenas de modelos (OpenAI, Anthropic, Google, Meta, DeepSeek, Qwen, etc.) com seleção dinâmica, fallback e rastreamento.

---

## 🎯 Propósito
Permitir que agentes MANTIS escolham o melhor modelo para cada tarefa (custo, latência, capacidade) sem alterar código, usando OpenRouter como camada de abstração.

## 📋 Especificação (SDD)
- **Entradas**: API key do OpenRouter, nome do modelo, parâmetros de geração.
- **Saídas**: Resposta do modelo com metadados de uso e tracing.
- **Side Effects**: Chamadas HTTP, custos variáveis.
- **Constraints**: C1 (tipagem e schema), C3 (proteção da API key), C5 (contrato de saída), C7 (retry e fallback), C8 (logs de tokens), C9 (trace distribuído).
- **Dependências**: `langchain-openrouter`, `pydantic`.

---

## 🛡️ Bootstrap (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    import json, datetime, os
    def mantis_log(level, event, detail=""):
        entry = {"ts": datetime.datetime.utcnow().isoformat() + "Z", "level": level, "tenant": os.getenv("TENANT_ID", "global"), "event": event, "detail": detail, "trace_id": os.getenv("TRACE_ID", "null"), "span_id": os.getenv("SPAN_ID", "null"), "fallback": "true"}
        print(json.dumps(entry), flush=True)
```

### 1. Configuração Básica
```python
from langchain_openrouter import ChatOpenRouter
import os

model = ChatOpenRouter(
    model="anthropic/claude-sonnet-4.5",
    temperature=0,
    max_tokens=1024,
    max_retries=2,
    openrouter_api_key=os.getenv("OPENROUTER_API_KEY"),
)
```

### 2. Lista Dinâmica de Modelos
```python
# O OpenRouter oferece centenas de modelos; podemos listar via API
import requests

def list_available_models():
    resp = requests.get("https://openrouter.ai/api/v1/models")
    return [m["id"] for m in resp.json()["data"]]
```

### 3. Invocação Simples com Tracing Automático
```python
messages = [("system", "Você é um assistente MANTIS."), ("human", "Explique C1.")]
ai_msg = model.invoke(messages)
mantis_log("INFO", "openrouter_call", f"Tokens: {ai_msg.usage_metadata}")
```

### 4. Tool Calling Unificado
```python
from pydantic import BaseModel, Field

class GetWeather(BaseModel):
    """Obtém o clima atual em uma localização"""
    location: str = Field(description="Cidade e estado, ex: San Francisco, CA")

model_with_tools = model.bind_tools([GetWeather])
ai_msg = model_with_tools.invoke("qual o clima em São Paulo?")
print(ai_msg.tool_calls)
```

### 5. Estrutura de Resposta e Metadados
- `response_metadata` contém `model_name`, `id`, `finish_reason`, `model_provider`.
- `usage_metadata` inclui `input_tokens`, `output_tokens`, `total_tokens` e detalhes de cache/reasoning.

### 6. Streaming Assíncrono
```python
async for chunk in model.astream("Conte uma história curta."):
    print(chunk.text, end="", flush=True)
```

### 7. Cache de Prompt (Economia)
```python
long_system = "Você é um assistente. " * 200
messages = [
    ("system", [{"type": "text", "text": long_system, "cache_control": {"type": "ephemeral"}}]),
    ("human", "Diga oi.")
]
# Primeira chamada grava cache; segunda lê, reduzindo custo
```

---

## 🧪 Testes Unitários (TDD)
```python
def test_openrouter_model_creation():
    m = ChatOpenRouter(model="openai/gpt-4.1", temperature=0)
    assert m.model_name == "openai/gpt-4.1"
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/multi-model-openrouter-integration.md --json
```

---

## 🔗 Referências Cruzadas
- [[model-tracing-sessions.md]]
- [[openrouter-provider-routing.md]]
