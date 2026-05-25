---
artifact_id: "langchain-custom-middleware"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/langchain-custom-middleware.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/langchain-custom-middleware.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:langchain-custom-middleware-v1.0.0"
generated_at: "2026-05-26T14:30:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["langchain-hitl-middleware"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-26"
---

# ⛓️ LangChain Custom Middleware – Hooks de Tool Calls e Modelo

> **Contrato modular**: Artefato filho do Master Agent. Ensina a criar middleware customizado para agentes LangChain com `wrap_tool_call`, `before_model`, `after_model`, `before_agent`, `after_agent`. Padrões de retry, guard e logging.

---

## 🎯 Propósito
Permitir que agentes MANTIS tradicionais tenham comportamentos customizados injetados via hooks de middleware, como retry automático, bloqueio de ferramentas perigosas e logging detalhado.

## 📋 Especificação (SDD)
- **Entradas**: Funções decoradas com hooks de middleware.
- **Saídas**: Middleware registrado no agente.
- **Side Effects**: Interceptação de tool calls e modelo.
- **Constraints Aplicáveis**: C1 (interface de hooks), C3 (bloqueio de ferramentas), C5 (preservação de estado), C7 (retry), C8 (logs).
- **Dependências**: `langchain.agents.middleware`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. `wrap_tool_call` – Retry Automático

```python
from langchain.agents.middleware import wrap_tool_call

@wrap_tool_call
def retry_middleware(request, handler):
    for attempt in range(3):
        try:
            return handler(request)
        except Exception:
            if attempt == 2:
                raise
```

### 2. `wrap_tool_call` – Guard (Bloqueio)

```python
@wrap_tool_call
def guard_middleware(request, handler):
    if request.tool_call["name"] == "dangerous_tool":
        return "Esta ferramenta está desabilitada."
    return handler(request)
```

### 3. `before_model` e `after_model` – Logging

```python
from langchain.agents.middleware import before_model, after_model

@before_model
def log_before(state, runtime):
    mantis_log("INFO", "model_call", f"Mensagens: {len(state['messages'])}")

@after_model
def log_after(state, runtime):
    mantis_log("INFO", "model_done", "Modelo respondeu")
```

### 4. `before_agent` e `after_agent` – Injeção de Estado

```python
from langchain.agents.middleware import before_agent, after_agent

@before_agent
def inject_context(state, runtime):
    return {"context_loaded": True}

@after_agent
def cleanup(state, runtime):
    return {"context_loaded": False}
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_wrap_tool_call():
    @wrap_tool_call
    def dummy(request, handler):
        return handler(request)
    assert dummy is not None
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/langchain-custom-middleware.md --json
```

---

## 🔗 Referências Cruzadas
- [[langchain-hitl-middleware.md]]
