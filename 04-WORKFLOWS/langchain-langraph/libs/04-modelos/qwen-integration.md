---
artifact_id: "qwen-integration"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/qwen-integration.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/qwen-integration.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:qwen-integration-v1.0.0"
generated_at: "2026-05-25T07:50:00Z"
tenant_context: "obrigatorio"
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

# 🇶 ChatQwen Integration – Modelos Qwen com LangChain

> **Contrato modular**: Integração completa com os modelos Qwen (qwen-flash, qwen-max, qwen-vl-max) via `ChatQwen`, incluindo tool calling e suporte a visão.

---

## 🎯 Propósito
Adicionar os modelos Qwen ao leque de opções dos agentes MANTIS, com destaque para visão e custo‑benefício.

## 📋 Especificação (SDD)
- **Entradas**: `DASHSCOPE_API_KEY`, modelo (`qwen-flash`, `qwen-vl-max-latest`).
- **Saídas**: Respostas textuais, tool calls, descrições de imagens/vídeos.
- **Constraints**: C1, C3, C5, C7, C8.
- **Dependências**: `langchain-qwq`.

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
from langchain_qwq import ChatQwen
llm = ChatQwen(model="qwen-flash", max_tokens=3000)
messages = [("system", "Você é um tradutor."), ("human", "I love programming.")]
ai_msg = llm.invoke(messages)
print(ai_msg.content)
```

### 2. Tool Calling
```python
@tool
def multiply(first_int: int, second_int: int) -> int:
    """Multiplica dois inteiros."""
    return first_int * second_int

llm_with_tools = llm.bind_tools([multiply])
msg = llm_with_tools.invoke("Quanto é 5 vezes 42?")
print(msg.tool_calls)
```

### 3. Visão (Imagem e Vídeo)
```python
model_vl = ChatQwen(model="qwen-vl-max-latest")
message = HumanMessage(content=[
    {"type": "image_url", "image_url": {"url": "https://example.com/image.png"}},
    {"type": "text", "text": "O que você vê na imagem?"}
])
response = model_vl.invoke([message])

# Vídeo
message_video = HumanMessage(content=[
    {"type": "video_url", "video_url": {"url": "https://example.com/video.mp4"}},
    {"type": "text", "text": "Descreva o vídeo."}
])
```

---

## 🧪 Testes Unitários (TDD)
```python
def test_qwen_basic():
    m = ChatQwen(model="qwen-flash")
    assert m.model_name == "qwen-flash"
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/qwen-integration.md --json
```

---

## 🔗 Referências Cruzadas
- [[multi-model-openrouter-integration.md]]
