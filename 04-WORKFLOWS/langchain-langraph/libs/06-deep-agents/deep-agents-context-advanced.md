---
artifact_id: "deep-agents-context-advanced"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-context-advanced.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-context-advanced.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-context-adv-v1.0.0"
generated_at: "2026-05-26T01:30:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-context-engineering"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-26"
---

# 📐 Deep Agents – Contexto Avançado (Token Trimming e Offloading)

> **Contrato modular**: Artefato filho do Master Agent. Técnicas avançadas de gestão de contexto: token trimming, offloading para arquivos, compressão de mensagens e estratégias de contexto compartilhado.

---

## 🎯 Propósito
Garantir que agentes MANTIS operem dentro de limites de tokens sem perder informações críticas, usando técnicas avançadas de compressão e offloading.

## 📋 Especificação (SDD)
- **Entradas**: Histórico de mensagens, configuração de offloading.
- **Saídas**: Contexto otimizado para o LLM.
- **Side Effects**: Arquivos offloaded no backend.
- **Constraints Aplicáveis**: C1 (limites), C5 (preservação), C7 (recuperação), C8 (logs).
- **Dependências**: `deepagents`, `tiktoken`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Token Counting com Tiktoken

```python
import tiktoken

def count_tokens(text: str, model: str = "gpt-4") -> int:
    encoding = tiktoken.encoding_for_model(model)
    return len(encoding.encode(text))

def count_message_tokens(messages: list) -> int:
    total = 0
    for msg in messages:
        if isinstance(msg, dict):
            total += count_tokens(msg.get("content", ""))
        else:
            total += count_tokens(msg.content)
    return total
```

### 2. Trimming Inteligente de Histórico

```python
def trim_history(messages: list, max_tokens: int = 8000) -> list:
    total = count_message_tokens(messages)
    if total <= max_tokens:
        return messages
    # Mantém system prompt + últimas N mensagens
    system_msgs = [m for m in messages if m.get("role") == "system"]
    chat_msgs = [m for m in messages if m.get("role") != "system"]
    while total > max_tokens and len(chat_msgs) > 2:
        removed = chat_msgs.pop(1)  # Remove a segunda mais antiga
        total -= count_tokens(removed.get("content", ""))
    return system_msgs + chat_msgs
```

### 3. Offloading para Arquivos

```python
def offload_large_messages(state, backend, max_size=2000):
    messages = state.get("messages", [])
    new_messages = []
    for i, msg in enumerate(messages):
        content = msg.content if hasattr(msg, 'content') else msg.get("content", "")
        if len(content) > max_size:
            file_path = f"/large_tool_results/msg_{i}.txt"
            backend.write(file_path, content)
            msg.content = f"[Conteúdo offloaded para {file_path}]"
            mantis_log("INFO", "offload", file_path)
        new_messages.append(msg)
    return new_messages
```

### 4. Compressão de Mensagens com LLM Barato

```python
def compress_message(content: str, model="openai:gpt-4.1-mini") -> str:
    prompt = f"Resuma o seguinte texto em até 200 palavras:\n\n{content}"
    response = cheap_llm.invoke(prompt)
    return response.content
```

### 5. Contexto Compartilhado com Subagentes

```python
# Subagentes herdam o contexto do pai via runtime context.
# Para passar dados adicionais, use o parâmetro 'context' na invocação.
@dataclass
class Context:
    user_id: str
    project_context: str  # Contexto extra do projeto

agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    context_schema=Context,
)
result = agent.invoke(
    {"messages": [...]},
    context=Context(user_id="123", project_context="Detalhes do projeto..."),
)
```

### 6. Estratégia de Sumarização Customizada

```python
from langchain.agents.middleware.summarization import SummarizationMiddleware

agent = create_deep_agent(
    model="openai:gpt-5.4",
    middleware=[
        SummarizationMiddleware(
            model="openai:gpt-4.1-mini",
            max_tokens=4000,
            max_summary_tokens=500,
        ),
    ],
)
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_count_tokens():
    tokens = count_tokens("Hello world")
    assert tokens > 0

def test_trim_history():
    msgs = [{"role": "user", "content": "A" * 10000}]
    trimmed = trim_history(msgs, max_tokens=100)
    assert len(trimmed) <= 2
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-context-advanced.md --json
```

---

## 🔗 Referências Cruzadas
- [[deep-agents-context-engineering.md]]
