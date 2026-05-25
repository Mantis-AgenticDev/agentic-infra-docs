---
artifact_id: "deep-agents-middleware-custom"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-middleware-custom.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-middleware-custom.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-middleware-custom-v1.0.0"
generated_at: "2026-05-25T19:30:00Z"
tenant_context: "obrigatorio"
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

# 🧩 Deep Agents – Middleware Customizado

> **Contrato modular**: Artefato filho do Master Agent. Ensina a criar middleware personalizado para Deep Agents, incluindo hooks de tool call, interceptação de estado e injeção de ferramentas.

---

## 🎯 Propósito
Permitir que agentes MANTIS tenham comportamentos customizados injetados via middleware, como logging avançado, rate limiting, autorização e transformação de respostas.

## 📋 Especificação (SDD)
- **Entradas**: Classes ou funções de middleware.
- **Saídas**: Middleware registrado no agente.
- **Side Effects**: Interceptação de chamadas.
- **Constraints Aplicáveis**: C1 (interface AgentMiddleware), C3 (segurança), C5 (schema), C7 (não quebrar fluxo), C8 (logs).
- **Dependências**: `langchain.agents.middleware`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Middleware de Logging com `wrap_tool_call`

```python
from langchain.agents.middleware import wrap_tool_call

@wrap_tool_call
def log_tool_calls(request, handler):
    mantis_log("INFO", "tool_call_start", f"{request.name}: {request.args}")
    result = handler(request)
    mantis_log("INFO", "tool_call_end", f"{request.name}: {result[:100]}...")
    return result

agent = create_deep_agent(
    model="openai:gpt-5.4",
    tools=[...],
    middleware=[log_tool_calls],
)
```

### 2. Middleware de Rate Limiting

```python
import time
from langchain.agents.middleware import AgentMiddleware

class RateLimitMiddleware(AgentMiddleware):
    def __init__(self, max_calls_per_minute=10):
        self.calls = []
        self.max_calls = max_calls_per_minute

    def before_agent(self, state, runtime):
        now = time.time()
        self.calls = [t for t in self.calls if now - t < 60]
        if len(self.calls) >= self.max_calls:
            raise Exception("Rate limit exceeded")
        self.calls.append(now)
        return None
```

### 3. Middleware de Autorização

```python
class AuthMiddleware(AgentMiddleware):
    def before_agent(self, state, runtime):
        user = runtime.context.get("user_role")
        if user != "admin":
            # Remove ferramentas perigosas
            return {"tools": [t for t in state.get("tools", []) if not t.name.startswith("admin_")]}
        return None
```

### 4. Middleware que Adiciona Ferramentas Dinamicamente

```python
class DynamicToolMiddleware(AgentMiddleware):
    def __init__(self, tools):
        self.tools = tools

    def before_agent(self, state, runtime):
        existing_tools = state.get("tools", [])
        return {"tools": existing_tools + self.tools}
```

### 5. Uso de `AgentMiddleware` com Estado

```python
class CounterMiddleware(AgentMiddleware):
    def before_agent(self, state, runtime):
        count = state.get("call_count", 0)
        mantis_log("INFO", "call_count", f"Chamada #{count+1}")
        return {"call_count": count + 1}
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_wrap_tool_call():
    @wrap_tool_call
    def interceptor(request, handler):
        return handler(request)
    assert interceptor is not None
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-middleware-custom.md --json
```

---

## 🔗 Referências Cruzadas
- [[deep-agents-core-customization.md]]
