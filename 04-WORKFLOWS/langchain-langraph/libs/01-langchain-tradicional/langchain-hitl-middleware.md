---
artifact_id: "langchain-hitl-middleware"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/langchain-hitl-middleware.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/langchain-hitl-middleware.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:langchain-hitl-middleware-v1.0.0"
generated_at: "2026-05-26T14:15:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["langchain-custom-middleware"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-26"
---

# 🛑 LangChain HITL Middleware – Aprovação Humana em Ferramentas

> **Contrato modular**: Artefato filho do Master Agent. Documenta o uso de `HumanInTheLoopMiddleware` com `create_agent` do LangChain tradicional, incluindo `interrupt_on`, `Command(resume=...)`, per‑tool policies e aprovação/edição/rejeição.

---

## 🎯 Propósito
Permitir que agentes MANTIS tradicionais pausem antes de executar ferramentas sensíveis, aguardando decisão humana (aprovar, editar ou rejeitar) via `HumanInTheLoopMiddleware`.

## 📋 Especificação (SDD)
- **Entradas**: Configuração `interrupt_on`, checkpointer.
- **Saídas**: Agente que pausa para decisão humana.
- **Side Effects**: Estado salvo no checkpointer.
- **Constraints Aplicáveis**: C1 (schema de decisão), C3 (proteção de operações), C5 (rastreabilidade), C7 (resiliência), C8 (logs), C9 (thread_id).
- **Dependências**: `langchain.agents`, `langgraph.checkpoint`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ... (fallback padrão)
```

### 1. Configuração Básica

```python
from langchain.agents import create_agent
from langchain.agents.middleware import HumanInTheLoopMiddleware
from langgraph.checkpoint.memory import MemorySaver
from langchain.tools import tool

@tool
def send_email(to: str, subject: str, body: str) -> str:
    """Envia um email."""
    return f"Email enviado para {to}"

agent = create_agent(
    model="gpt-4.1",
    tools=[send_email],
    checkpointer=MemorySaver(),
    middleware=[
        HumanInTheLoopMiddleware(
            interrupt_on={"send_email": {"allowed_decisions": ["approve", "edit", "reject"]}}
        )
    ],
)
```

### 2. Fluxo de Aprovação

```python
from langgraph.types import Command

config = {"configurable": {"thread_id": "session-1"}}

result1 = agent.invoke(
    {"messages": [{"role": "user", "content": "Envie email para john@example.com"}]},
    config=config,
)

if "__interrupt__" in result1:
    print(f"Aguardando aprovação: {result1['__interrupt__']}")

# Aprovar
result2 = agent.invoke(
    Command(resume={"decisions": [{"type": "approve"}]}),
    config=config,
)
```

### 3. Editar Argumentos

```python
result2 = agent.invoke(
    Command(resume={"decisions": [{
        "type": "edit",
        "edited_action": {
            "name": "send_email",
            "args": {"to": "alice@company.com", "subject": "Reunião", "body": "..."}
        }
    }]}),
    config=config,
)
```

### 4. Rejeitar com Feedback

```python
result2 = agent.invoke(
    Command(resume={"decisions": [{
        "type": "reject",
        "feedback": "Não é permitido enviar emails sem aprovação do gerente."
    }]}),
    config=config,
)
```

### 5. Políticas por Ferramenta

```python
agent = create_agent(
    model="gpt-4.1",
    tools=[send_email, read_email, delete_email],
    checkpointer=MemorySaver(),
    middleware=[
        HumanInTheLoopMiddleware(
            interrupt_on={
                "send_email": {"allowed_decisions": ["approve", "edit", "reject"]},
                "delete_email": {"allowed_decisions": ["approve", "reject"]},
                "read_email": False,
            }
        )
    ],
)
```

### 6. Erros Comuns

```python
# ❌ SEM checkpointer
agent = create_agent(model="gpt-4.1", tools=[send_email], middleware=[HumanInTheLoopMiddleware({...})])

# ✅ COM checkpointer
agent = create_agent(
    model="gpt-4.1", tools=[send_email],
    checkpointer=MemorySaver(),
    middleware=[HumanInTheLoopMiddleware({...})]
)

# ❌ SEM thread_id
agent.invoke(input)

# ✅ COM thread_id
agent.invoke(input, config={"configurable": {"thread_id": "user-123"}})
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_hitl_requires_checkpointer():
    with pytest.raises(ValueError):
        create_agent(model="gpt-4.1", tools=[], middleware=[HumanInTheLoopMiddleware({})])
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/langchain-hitl-middleware.md --json
```

---

## 🔗 Referências Cruzadas
- [[langchain-custom-middleware.md]]
- [[langchain-long-term-memory.md]]
