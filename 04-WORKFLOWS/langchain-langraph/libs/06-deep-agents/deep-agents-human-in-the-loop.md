---
artifact_id: "deep-agents-human-in-the-loop"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-human-in-the-loop.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-human-in-the-loop.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-hitl-v1.0.0"
generated_at: "2026-05-25T16:30:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-core-customization", "deep-agents-backends-filesystem"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🛑 Deep Agents – Human‑in‑the‑Loop (Aprovação Humana)

> **Contrato modular**: Artefato filho do Master Agent. Detalha o uso de `interrupt_on` e `HumanInTheLoopMiddleware` para pausar a execução de ferramentas sensíveis e exigir aprovação, edição ou rejeição humana.

---

## 🎯 Propósito
Permitir que agentes MANTIS solicitem validação humana antes de executar operações críticas, garantindo segurança e conformidade.

## 📋 Especificação (SDD)
- **Entradas**: Configuração `interrupt_on`, checkpointer.
- **Saídas**: Execução pausada até decisão humana.
- **Side Effects**: Estado do grafo salvo no checkpointer.
- **Constraints Aplicáveis**: C1 (schema de decisão), C3 (proteção de operações), C5 (rastreabilidade), C7 (resiliência), C8 (logs), C9 (thread_id).
- **Dependências**: `deepagents`, `langgraph.checkpoint`.

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

### 1. Configuração Básica de Interrupção

```python
from deepagents import create_deep_agent
from langgraph.checkpoint.memory import MemorySaver

checkpointer = MemorySaver()

agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    tools=[write_file, execute_sql, read_file],
    interrupt_on={
        "write_file": True,
        "execute_sql": {"allowed_decisions": ["approve", "reject"]},
        "read_file": False,
    },
    checkpointer=checkpointer,  # OBRIGATÓRIO
)
```

### 2. Fluxo Completo de Aprovação

```python
from langgraph.types import Command

config = {"configurable": {"thread_id": "session-1"}}

# Passo 1: Agente propõe write_file – execução pausa
result = agent.invoke({
    "messages": [{"role": "user", "content": "Escreva configuração em /prod.yaml"}]
}, config=config)

# Passo 2: Verificar interrupções
state = agent.get_state(config)
if state.next:
    mantis_log("INFO", "hitl_pending", "Aguardando aprovação humana")

# Passo 3: Aprovar e retomar
result = agent.invoke(
    Command(resume={"decisions": [{"type": "approve"}]}),
    config=config,
)
```

### 3. Tipos de Decisão

```python
# approve – aprova a execução da ferramenta
Command(resume={"decisions": [{"type": "approve"}]})

# reject – rejeita com feedback
Command(resume={"decisions": [{"type": "reject", "message": "Execute os testes primeiro"}]})

# edit – modifica os argumentos antes de executar
Command(resume={"decisions": [{
    "type": "edit",
    "edited_action": {
        "name": "execute_sql",
        "args": {"query": "DELETE FROM users WHERE last_login < '2020-01-01' LIMIT 100"},
    },
}]})
```

### 4. Interrupção em Subagentes

```python
agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    subagents=[
        {
            "name": "code-deployer",
            "description": "Implanta código em produção",
            "system_prompt": "Você implanta código após testes passarem.",
            "tools": [run_tests, deploy_to_prod],
            "interrupt_on": {"deploy_to_prod": True},
        }
    ],
    checkpointer=MemorySaver(),
)
```

### 5. Erro Comum: Falta de Checkpointer

```python
# ❌ ERRADO: interrupt_on sem checkpointer
agent = create_deep_agent(interrupt_on={"write_file": True})
# ❌ Levanta ValueError

# ✅ CORRETO
agent = create_deep_agent(interrupt_on={"write_file": True}, checkpointer=MemorySaver())
```

### 6. Erro Comum: Falta de thread_id

```python
# ❌ ERRADO: não é possível retomar sem thread_id
agent.invoke({"messages": [...]})

# ✅ CORRETO
config = {"configurable": {"thread_id": "session-1"}}
agent.invoke({...}, config=config)
# Retomar com Command usando mesmo config
agent.invoke(Command(resume={"decisions": [{"type": "approve"}]}), config=config)
```

---

## 🧪 Testes Unitários (TDD)

```python
import pytest
from deepagents import create_deep_agent
from langgraph.checkpoint.memory import MemorySaver

def test_hitl_requires_checkpointer():
    with pytest.raises(ValueError):
        create_deep_agent(model="openai:gpt-5.4", interrupt_on={"write_file": True})

def test_hitl_with_checkpointer():
    agent = create_deep_agent(
        model="openai:gpt-5.4",
        interrupt_on={"write_file": True},
        checkpointer=MemorySaver(),
    )
    assert agent is not None
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-human-in-the-loop.md --json
```

---

## 🔗 Referências Cruzadas
- [[deep-agents-core-customization.md]]
- [[deep-agents-backends-filesystem.md]]
- [[langchain-langraph-master-agent.md]]

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-25T16:30:00Z | langchain-langraph-master-agent | Criação inicial: HITL | C1,C3,C5,C7,C8,C9 |
