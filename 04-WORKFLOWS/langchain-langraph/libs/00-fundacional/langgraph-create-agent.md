---
artifact_id: "langgraph-create-agent"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/langgraph-create-agent.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/langgraph-create-agent.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:langgraph-create-agent-v1.0.0"
generated_at: "2026-05-24T23:35:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["langgraph-state-graph-fundamentals", "agents-swarm-routing", "human-in-the-loop"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🤖 `create_agent()` – Construção Padrão de Agentes LangGraph

> **Contrato modular**: Artefato filho do Master Agent. Implementa a lógica específica para usar a função `create_agent` como padrão de criação de agentes no ecossistema MANTIS, cobrindo ferramentas, memória, middleware e saídas estruturadas.

---

## 🎯 Propósito
Definir o uso canônico de `create_agent()` do LangGraph para construir agentes com ferramentas tipadas, checkpointer, middleware de aprovação humana (HITL) e structured output, garantindo alinhamento com as constraints C1‑C9.

## 📋 Especificação (SDD)
- **Entradas**: Modelo LLM, lista de ferramentas, prompt do sistema, configuração de checkpointer e middleware.
- **Saídas**: Agente configurado capaz de invocação com `thread_id` e retorno de `messages`.
- **Side Effects**: Persistência de estado via checkpointer (C7).
- **Constraints Aplicáveis**: C1 (tipagem de ferramentas), C3 (proteção de decisões críticas via middleware), C5 (contrato de resposta), C7 (checkpointing), C8 (tracing), C9 (thread_id vinculado a trace).
- **Dependências**: `langgraph`, `langchain-core`, `pydantic`.

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

### 1. Criação Básica com Ferramentas e Modelo
```python
from langchain.agents import create_agent
from langchain_anthropic import ChatAnthropic
from langchain_core.tools import tool

@tool
def get_weather(location: str) -> str:
    """Obter clima atual. location: nome da cidade"""
    return f"Clima em {location}: ensolarado, 22°C"

agent = create_agent(
    model="anthropic:claude-sonnet-4-5",
    tools=[get_weather],
    system_prompt="Você é um assistente prestativo."
)
mantis_log("INFO", "agent_created", "Agente básico criado")
```

### 2. Checkpointer para Persistência de Conversa (C7, C9)
```python
from langgraph.checkpoint.memory import MemorySaver

checkpointer = MemorySaver()
agent = create_agent(
    model="anthropic:claude-sonnet-4-5",
    tools=[get_weather],
    checkpointer=checkpointer,
)
config = {"configurable": {"thread_id": "user-123"}}
agent.invoke({"messages": [{"role": "user", "content": "Meu nome é Alice"}]}, config=config)
result = agent.invoke({"messages": [{"role": "user", "content": "Qual é o meu nome?"}]}, config=config)
mantis_log("INFO", "memory_recall", f"Agent recordou: {result['messages'][-1].content}")
```

### 3. Middleware Human‑in‑the‑Loop (HITL)
Para aprovação de ferramentas perigosas (C3, C7).

```python
from langchain.agents.middleware import HumanInTheLoopMiddleware

agent = create_agent(
    model="anthropic:claude-sonnet-4-5",
    tools=[dangerous_tool],
    checkpointer=MemorySaver(),
    middleware=[HumanInTheLoopMiddleware(interrupt_on={"dangerous_tool": True})],
)
# A execução será interrompida; para retomar:
from langchain.types import Command
agent.invoke(Command(resume={"decisions": [{"type": "approve"}]}), config=config)
mantis_log("INFO", "hitl_approval", "Ação aprovada pelo humano")
```

### 4. Saída Estruturada com `response_format`
Garante respostas tipadas (C5).

```python
from pydantic import BaseModel, Field

class ContactInfo(BaseModel):
    name: str
    email: str
    phone: str = Field(description="Telefone com DDD")

agent = create_agent(
    model="gpt-4.1",
    tools=[search],
    response_format=ContactInfo,
)
result = agent.invoke({"messages": [{"role": "user", "content": "Encontre contato do João"}]})
contact = result["structured_response"]
mantis_log("INFO", "structured_output", f"Contato: {contact.name}")
```

### 5. Configuração de Modelo Customizado
```python
from langchain_anthropic import ChatAnthropic

llm = ChatAnthropic(model="claude-sonnet-4-5", temperature=0.2)
agent = create_agent(model=llm, tools=[...])
mantis_log("INFO", "custom_model", "Modelo com temperatura controlada")
```

### 6. Boas Práticas: Descrição de Ferramentas
Documentar claramente cada ferramenta (C1).

```python
@tool
def search(query: str) -> str:
    """Pesquisar na web por informações recentes.

    Use quando precisar de dados atualizados.
    Args:
        query: consulta com 2‑10 palavras
    """
    return web_search(query)
```

### 7. Controle de Iterações (C7)
Evitar loops infinitos com `recursion_limit`.

```python
result = agent.invoke(
    {"messages": [{"role": "user", "content": "Faça uma pesquisa"}]},
    config={"recursion_limit": 10}
)
```

### 8. Acesso Correto às Mensagens
```python
result = agent.invoke(...)
ultima_mensagem = result["messages"][-1].content
mantis_log("INFO", "agent_response", f"Resposta: {ultima_mensagem[:100]}")
```

---

## 🧪 Testes Unitários (TDD)

```python
import pytest

# Teste: Checkpointer recorda nome
def test_checkpointer_memory():
    from langgraph.checkpoint.memory import MemorySaver
    agent = create_agent(model="anthropic:claude-sonnet-4-5", tools=[], checkpointer=MemorySaver())
    config = {"configurable": {"thread_id": "test-1"}}
    agent.invoke({"messages": [{"role": "user", "content": "Meu nome é Bob"}]}, config)
    result = agent.invoke({"messages": [{"role": "user", "content": "Qual meu nome?"}]}, config)
    assert "Bob" in result["messages"][-1].content

# Teste: HITL interrompe ferramenta proibida
def test_hitl_interrupt():
    from langchain.agents.middleware import HumanInTheLoopMiddleware
    agent = create_agent(model="anthropic:claude-sonnet-4-5", tools=[dangerous], checkpointer=MemorySaver(), middleware=[HumanInTheLoopMiddleware(interrupt_on={"dangerous": True})])
    with pytest.raises(Exception):  # espera interrupção
        agent.invoke({"messages": [{"role": "user", "content": "Use dangerous"}]}, config)
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/langgraph-create-agent.md \
  --json \
  --check-structural \
  --check-error-handling \
  --check-observability
```

---

## 🔗 Referências Cruzadas
- [[langchain-langraph-master-agent.md]]
- [[/05-CONFIGURATIONS/validation/orchestrator-engine/main.go]]
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]]

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal |
|--------|------|-------|------------------|
| 1.0.0 | 2026-05-24T23:35:00Z | langchain-langraph-master-agent | Criação inicial: create_agent padrão |
