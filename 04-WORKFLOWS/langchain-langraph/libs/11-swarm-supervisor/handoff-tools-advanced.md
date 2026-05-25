---
artifact_id: "handoff-tools-advanced"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/11-swarm-supervisor/handoff-tools-advanced.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/11-swarm-supervisor/handoff-tools-advanced.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:handoff-advanced-v1"
generated_at: "2026-05-27T08:30:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["swarm-supervisor-patterns", "multi-agent-memory", "workflows-ceo"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks", "workflows-ceo"]
status: "🟢 Novo"
next_review: "2026-08-27"
---

# 🧩 Handoff Tools Avançadas — Passagem de Contexto e Tarefas entre Agentes

> **Contrato modular**: Artefato filho do Master Agent. Implementa ferramentas de transferência de controle com injeção de estado, descrição de tarefa, e metadados de tenant, permitindo handoffs ricos e rastreáveis entre agentes.

## 🎯 Propósito

Fornecer um conjunto de fábricas de handoff tools que vão além da transferência simples, incluindo: passagem de descrição de tarefa, injeção de tenant_id, metadados de rastreamento, handoff condicional, e integração com o sistema de logging MANTIS.

## 📋 Especificação (SDD)
- **Entradas**: `agent_name`, `name`, `description`, `include_task_description`, `include_tenant_context`, `custom_fields`
- **Saídas**: `BaseTool` compatível com LangGraph swarm/supervisor
- **Side Effects**: Geração de `ToolMessage`, atualização de estado, logging de handoff
- **Constraints Aplicáveis**: C1 (Resiliência), C2 (Validação), C3 (Segurança), C5 (Integridade), C7 (Versionamento), C8 (Observabilidade)
- **Dependências**: `langgraph-swarm`, `langgraph-supervisor`, `langchain-core`, `pydantic`

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from langchain_langraph_master_agent import mantis_log
except ImportError:
    import json, datetime, os
    def mantis_log(level, event, detail=""):
        entry = {
            "ts": datetime.datetime.utcnow().isoformat() + "Z",
            "level": level,
            "tenant": os.getenv("TENANT_ID", "global"),
            "event": event,
            "detail": detail,
            "trace_id": os.getenv("TRACE_ID", "null"),
            "span_id": os.getenv("SPAN_ID", "null"),
            "fallback": "true"
        }
        print(json.dumps(entry), flush=True)
    mantis_log("WARN", "bootstrap_fallback", "Master Agent langchain-langraph não encontrado.")
```

```python
# ═══════════════════════════════════════════════════════════════════════════
# 1. HANDOFF COM DESCRIÇÃO DE TAREFA E CONTEXTO DE TENANT
# ═══════════════════════════════════════════════════════════════════════════
from typing import Annotated, Optional, Any
from langchain_core.tools import BaseTool, tool, InjectedToolCallId
from langchain_core.messages import ToolMessage
from langgraph.prebuilt import InjectedState
from langgraph.types import Command
from langgraph_swarm.handoff import _normalize_agent_name, METADATA_KEY_HANDOFF_DESTINATION

def create_context_handoff_tool(
    *,
    agent_name: str,
    name: Optional[str] = None,
    description: Optional[str] = None,
    include_task_description: bool = True,
    include_tenant_context: bool = True,
    extra_fields: Optional[dict] = None,
) -> BaseTool:
    """
    Cria uma ferramenta de handoff que injeta contexto adicional no estado.

    Args:
        agent_name: Nome do agente destino (node name).
        name: Nome da tool (padrão: transfer_to_<agent_name>).
        description: Descrição da tool para o LLM.
        include_task_description: Se True, aceita argumento `task_description` do LLM.
        include_tenant_context: Se True, adiciona `tenant_id` ao estado.
        extra_fields: Campos extras fixos a serem adicionados ao estado.
    """
    if name is None:
        name = f"transfer_to_{_normalize_agent_name(agent_name)}"
    if description is None:
        description = f"Transferir controle para o agente '{agent_name}'"
    if extra_fields is None:
        extra_fields = {}

    @tool(name, description=description)
    def handoff_to_agent(
        state: Annotated[Any, InjectedState],
        tool_call_id: Annotated[str, InjectedToolCallId],
        task_description: Annotated[Optional[str], "Descrição detalhada da tarefa para o próximo agente"] = None,
    ) -> Command:
        tool_message = ToolMessage(
            content=f"Transferido com sucesso para {agent_name}",
            name=name,
            tool_call_id=tool_call_id,
        )
        messages = state.get("messages", [])
        update = {
            "messages": [*messages, tool_message],
            "active_agent": agent_name,
        }
        if include_task_description and task_description:
            update["task_description"] = task_description
        if include_tenant_context:
            update["tenant_id"] = os.getenv("TENANT_ID", "global")
        update.update(extra_fields)
        mantis_log("INFO", "context_handoff", f"To={agent_name}, Task={task_description}, Extra={extra_fields}")
        return Command(
            goto=agent_name,
            graph=Command.PARENT,
            update=update,
        )

    handoff_to_agent.metadata = {METADATA_KEY_HANDOFF_DESTINATION: agent_name}
    return handoff_to_agent

# ═══════════════════════════════════════════════════════════════════════════
# 2. HANDOFF COM VALIDAÇÃO DE PERMISSÃO (C3)
# ═══════════════════════════════════════════════════════════════════════════
def create_permissioned_handoff_tool(
    *,
    agent_name: str,
    allowed_roles: list[str],
    name: Optional[str] = None,
    description: Optional[str] = None,
) -> BaseTool:
    """
    Handoff tool que verifica se o agente atual tem permissão para transferir.
    Utiliza o campo 'role' no estado para decidir.
    """
    if name is None:
        name = f"transfer_to_{_normalize_agent_name(agent_name)}"
    if description is None:
        description = f"Transferir para {agent_name} (requer permissão: {allowed_roles})"

    @tool(name, description=description)
    def permissioned_handoff(
        state: Annotated[Any, InjectedState],
        tool_call_id: Annotated[str, InjectedToolCallId],
    ) -> Command:
        current_role = state.get("role", "user")
        if current_role not in allowed_roles:
            mantis_log("WARN", "handoff_permission_denied", f"Role={current_role}, Required={allowed_roles}")
            return Command(
                update={
                    "messages": [*state.get("messages", []),
                                 ToolMessage(content="Permissão negada para transferência.", name=name, tool_call_id=tool_call_id)]
                }
            )
        tool_message = ToolMessage(
            content=f"Transferido com sucesso para {agent_name}",
            name=name,
            tool_call_id=tool_call_id,
        )
        mantis_log("INFO", "permissioned_handoff", f"To={agent_name}, Role={current_role}")
        return Command(
            goto=agent_name,
            graph=Command.PARENT,
            update={
                "messages": [*state.get("messages", []), tool_message],
                "active_agent": agent_name,
            }
        )

    permissioned_handoff.metadata = {METADATA_KEY_HANDOFF_DESTINATION: agent_name}
    return permissioned_handoff

# ═══════════════════════════════════════════════════════════════════════════
# 3. HANDOFF COM RETRY E FALLBACK (C1)
# ═══════════════════════════════════════════════════════════════════════════
def create_retry_handoff_tool(
    *,
    agent_name: str,
    max_retries: int = 2,
    fallback_agent: Optional[str] = None,
    name: Optional[str] = None,
    description: Optional[str] = None,
) -> BaseTool:
    """
    Handoff que tenta transferir e, em caso de falha, redireciona para fallback_agent.
    A lógica de retry depende do runtime; aqui adicionamos metadados para o executor.
    """
    if name is None:
        name = f"transfer_to_{_normalize_agent_name(agent_name)}"
    if description is None:
        desc = f"Transferir para {agent_name}"
        if fallback_agent:
            desc += f" (fallback: {fallback_agent})"
        description = desc

    @tool(name, description=description)
    def retry_handoff(
        state: Annotated[Any, InjectedState],
        tool_call_id: Annotated[str, InjectedToolCallId],
    ) -> Command:
        tool_message = ToolMessage(
            content=f"Transferido com sucesso para {agent_name}",
            name=name,
            tool_call_id=tool_call_id,
        )
        update = {
            "messages": [*state.get("messages", []), tool_message],
            "active_agent": agent_name,
            "_handoff_retry": {"target": agent_name, "max_retries": max_retries, "fallback": fallback_agent},
        }
        mantis_log("INFO", "retry_handoff", f"To={agent_name}, Fallback={fallback_agent}")
        return Command(
            goto=agent_name,
            graph=Command.PARENT,
            update=update,
        )

    retry_handoff.metadata = {METADATA_KEY_HANDOFF_DESTINATION: agent_name}
    return retry_handoff

# ═══════════════════════════════════════════════════════════════════════════
# 4. HANDOFF COM MENSAGEM DE CONTEXTO PERSONALIZADA
# ═══════════════════════════════════════════════════════════════════════════
def create_message_handoff_tool(
    *,
    agent_name: str,
    message_template: str = "Transferindo para {agent_name}. Contexto: {context}",
    name: Optional[str] = None,
    description: Optional[str] = None,
) -> BaseTool:
    """
    Handoff que permite ao LLM preencher um campo 'context' que é injetado na mensagem de transferência.
    """
    if name is None:
        name = f"transfer_to_{_normalize_agent_name(agent_name)}"
    if description is None:
        description = f"Transferir para {agent_name} com mensagem de contexto personalizada"

    @tool(name, description=description)
    def message_handoff(
        state: Annotated[Any, InjectedState],
        tool_call_id: Annotated[str, InjectedToolCallId],
        context: Annotated[str, "Contexto adicional para o próximo agente"] = "",
    ) -> Command:
        content = message_template.format(agent_name=agent_name, context=context)
        tool_message = ToolMessage(content=content, name=name, tool_call_id=tool_call_id)
        mantis_log("INFO", "message_handoff", f"To={agent_name}, Context={context}")
        return Command(
            goto=agent_name,
            graph=Command.PARENT,
            update={
                "messages": [*state.get("messages", []), tool_message],
                "active_agent": agent_name,
            }
        )

    message_handoff.metadata = {METADATA_KEY_HANDOFF_DESTINATION: agent_name}
    return message_handoff

# ═══════════════════════════════════════════════════════════════════════════
# 5. FÁBRICA DE HANDOFFS COM FLUENT API
# ═══════════════════════════════════════════════════════════════════════════
class HandoffToolBuilder:
    """Construtor fluente para ferramentas de handoff customizadas."""
    def __init__(self, agent_name: str):
        self.agent_name = agent_name
        self._name = None
        self._description = None
        self._include_task = True
        self._include_tenant = True
        self._extra_fields = {}
        self._permission_roles = None
        self._retry_config = None
        self._message_template = None

    def with_name(self, name: str) -> "HandoffToolBuilder":
        self._name = name
        return self

    def with_description(self, desc: str) -> "HandoffToolBuilder":
        self._description = desc
        return self

    def without_task_description(self) -> "HandoffToolBuilder":
        self._include_task = False
        return self

    def without_tenant_context(self) -> "HandoffToolBuilder":
        self._include_tenant = False
        return self

    def with_extra_fields(self, fields: dict) -> "HandoffToolBuilder":
        self._extra_fields = fields
        return self

    def with_permission(self, roles: list[str]) -> "HandoffToolBuilder":
        self._permission_roles = roles
        return self

    def with_retry(self, max_retries: int, fallback: str = None) -> "HandoffToolBuilder":
        self._retry_config = {"max_retries": max_retries, "fallback": fallback}
        return self

    def with_message_template(self, template: str) -> "HandoffToolBuilder":
        self._message_template = template
        return self

    def build(self) -> BaseTool:
        if self._permission_roles:
            return create_permissioned_handoff_tool(
                agent_name=self.agent_name,
                allowed_roles=self._permission_roles,
                name=self._name,
                description=self._description,
            )
        if self._retry_config:
            return create_retry_handoff_tool(
                agent_name=self.agent_name,
                max_retries=self._retry_config["max_retries"],
                fallback_agent=self._retry_config["fallback"],
                name=self._name,
                description=self._description,
            )
        if self._message_template:
            return create_message_handoff_tool(
                agent_name=self.agent_name,
                message_template=self._message_template,
                name=self._name,
                description=self._description,
            )
        return create_context_handoff_tool(
            agent_name=self.agent_name,
            name=self._name,
            description=self._description,
            include_task_description=self._include_task,
            include_tenant_context=self._include_tenant,
            extra_fields=self._extra_fields,
        )
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from handoff_tools_advanced import (
    create_context_handoff_tool,
    create_permissioned_handoff_tool,
    HandoffToolBuilder,
)
from langchain_core.messages import HumanMessage, AIMessage

def test_context_handoff_includes_tenant():
    tool = create_context_handoff_tool(agent_name="target", include_tenant_context=True)
    state = {"messages": []}
    result = tool.invoke({"state": state, "tool_call_id": "1"})
    # result is a Command; check update
    assert "tenant_id" in result.update
    assert result.goto == "target"

def test_permissioned_handoff_denied():
    tool = create_permissioned_handoff_tool(agent_name="admin", allowed_roles=["admin"])
    state = {"messages": [], "role": "user"}
    result = tool.invoke({"state": state, "tool_call_id": "2"})
    # Should not goto, no active_agent change
    assert result.goto == "__pregel_task" or result.goto is None  # depends; main: it didn't set goto=admin
    # We can check update for error message
    assert any("Permissão negada" in m.content for m in result.update.get("messages", []))

def test_builder_default():
    tool = HandoffToolBuilder("agentX").build()
    state = {"messages": []}
    result = tool.invoke({"state": state, "tool_call_id": "3"})
    assert result.goto == "agentX"
    assert "tenant_id" in result.update

def test_builder_with_permission():
    tool = HandoffToolBuilder("admin").with_permission(["admin"]).build()
    state = {"messages": [], "role": "admin"}
    result = tool.invoke({"state": state, "tool_call_id": "4"})
    assert result.goto == "admin"
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/11-swarm-supervisor/handoff-tools-advanced.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[swarm-fundamentals.md]]
- [[supervisor-fundamentals.md]]
- [[swarm-supervisor-patterns.md]]
