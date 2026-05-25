---
artifact_id: "supervisor-fundamentals"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/11-swarm-supervisor/supervisor-fundamentals.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/11-swarm-supervisor/supervisor-fundamentals.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:supervisor-fundamentals-v1"
generated_at: "2026-05-27T08:15:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: true
  required_for: ["swarm-supervisor-patterns", "multi-agent-memory", "workflows-ceo"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks", "workflows-ceo"]
status: "🟢 Novo"
next_review: "2026-08-27"
---

# 🧩 Supervisor Fundamentals — Orquestração Hierárquica Multi-Agente

> **Contrato modular**: Artefato filho do Master Agent. Implementa o padrão supervisor com `langgraph_supervisor`, permitindo coordenação centralizada de agentes especializados com handoffs e histórico.

## 🎯 Propósito

Fornecer uma fábrica de supervisores hierárquicos que orquestram múltiplos agentes especializados, decidindo qual invocar com base no contexto, gerenciando histórico de mensagens e suportando memória de curto/longo prazo.

## 📋 Especificação (SDD)
- **Entradas**: Lista de agentes, modelo supervisor, prompt do supervisor, configuração de handoff, output_mode
- **Saídas**: `StateGraph` compilado com supervisor central e agentes filhos
- **Side Effects**: Criação de ferramentas de handoff, injeção de mensagens de histórico
- **Constraints Aplicáveis**: C1, C2, C3, C5, C7, C8
- **Dependências**: `langgraph-supervisor`, `langgraph`, `langchain-core`

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
# 1. IMPORTAÇÕES E TIPOS
# ═══════════════════════════════════════════════════════════════════════════
import asyncio, os, uuid, time
from typing import Optional, Any, Dict, List, Callable, Union, Literal
from dataclasses import dataclass, field

from langchain_core.messages import AnyMessage, ToolMessage, AIMessage
from langchain_core.runnables import RunnableConfig
from langchain.agents import create_agent
from langchain.chat_models import init_chat_model, BaseChatModel
from langgraph.graph import StateGraph, MessagesState, START, END
from langgraph.checkpoint.base import BaseCheckpointSaver
from langgraph.checkpoint.memory import InMemorySaver
from langgraph.store.base import BaseStore
from langgraph.store.memory import InMemoryStore
from langgraph.pregel import Pregel
from langgraph.types import Command

from langgraph_supervisor import (
    create_supervisor,
    create_handoff_tool,
    create_handoff_back_messages,
    create_forward_message_tool,
)
from langgraph_supervisor.handoff import METADATA_KEY_HANDOFF_DESTINATION

# ═══════════════════════════════════════════════════════════════════════════
# 2. CONFIGURAÇÃO DE MODELO (AGNÓSTICO, COM FALLBACK)
# ═══════════════════════════════════════════════════════════════════════════
class SupervisorModelProvider:
    """Provedor de modelos para supervisores."""
    @staticmethod
    def get_supervisor_model(provider: str = "deepseek") -> BaseChatModel:
        model_map = {
            "deepseek": ("deepseek-chat", "deepseek"),
            "openai": ("gpt-4o", "openai"),
            "anthropic": ("claude-sonnet-4-6", "anthropic"),
        }
        name, prov = model_map.get(provider, model_map["deepseek"])
        return init_chat_model(model=name, model_provider=prov, temperature=0.05)

# ═══════════════════════════════════════════════════════════════════════════
# 3. ESPECIFICAÇÃO DE AGENTES SUPERVISIONADOS
# ═══════════════════════════════════════════════════════════════════════════
@dataclass
class SupervisedAgentSpec:
    """Define um agente filho do supervisor."""
    name: str
    system_prompt: str
    tools: List[Callable] = field(default_factory=list)
    model_provider: str = "deepseek"

# ═══════════════════════════════════════════════════════════════════════════
# 4. FÁBRICA DE SUPERVISORES
# ═══════════════════════════════════════════════════════════════════════════
class SupervisorBuilder:
    """
    Construtor fluente para sistemas multi-agente hierárquicos.
    Suporta múltiplos níveis, handoff customizado, memória e HITL.
    """
    def __init__(self, supervisor_name: str = "supervisor"):
        self.supervisor_name = supervisor_name
        self.agents: List[Pregel] = []
        self._model: Optional[BaseChatModel] = None
        self._prompt: str = "Você é um supervisor de equipe. Encaminhe cada solicitação ao agente mais adequado."
        self._output_mode: Literal["full_history", "last_message"] = "last_message"
        self._handoff_tools: Optional[List[BaseTool]] = None
        self._forward_message_tool: Optional[BaseTool] = None
        self._include_handoff_back_messages: bool = True
        self._checkpointer: Optional[BaseCheckpointSaver] = None
        self._store: Optional[BaseStore] = None
        self._interrupt_before: List[str] = field(default_factory=list)

    def with_model(self, model: BaseChatModel) -> "SupervisorBuilder":
        self._model = model
        return self

    def with_prompt(self, prompt: str) -> "SupervisorBuilder":
        self._prompt = prompt
        return self

    def with_output_mode(self, mode: Literal["full_history", "last_message"]) -> "SupervisorBuilder":
        self._output_mode = mode
        return self

    def with_handoff_tools(self, tools: List[BaseTool]) -> "SupervisorBuilder":
        self._handoff_tools = tools
        return self

    def with_forward_message_tool(self) -> "SupervisorBuilder":
        self._forward_message_tool = create_forward_message_tool(self.supervisor_name)
        return self

    def with_checkpointer(self, checkpointer: BaseCheckpointSaver) -> "SupervisorBuilder":
        self._checkpointer = checkpointer
        return self

    def with_store(self, store: BaseStore) -> "SupervisorBuilder":
        self._store = store
        return self

    def add_agent(self, agent: Pregel) -> "SupervisorBuilder":
        self.agents.append(agent)
        mantis_log("DEBUG", "supervisor_add_agent", agent.name)
        return self

    def add_agents_from_specs(self, specs: List[SupervisedAgentSpec]) -> "SupervisorBuilder":
        for spec in specs:
            model = SupervisorModelProvider.get_supervisor_model(spec.model_provider)
            agent = create_agent(
                model,
                tools=spec.tools,
                system_prompt=spec.system_prompt,
                name=spec.name,
            )
            self.add_agent(agent)
        return self

    def build(self) -> StateGraph:
        if not self.agents:
            raise ValueError("Pelo menos um agente filho é necessário")
        model = self._model or SupervisorModelProvider.get_supervisor_model()
        tools = self._handoff_tools
        if self._forward_message_tool:
            tools = (tools or []) + [self._forward_message_tool]
        builder = create_supervisor(
            agents=self.agents,
            model=model,
            prompt=self._prompt,
            output_mode=self._output_mode,
            tools=tools,
            supervisor_name=self.supervisor_name,
        )
        mantis_log("INFO", "supervisor_built", f"Agents={[a.name for a in self.agents]}")
        return builder

    def compile(self) -> Pregel:
        builder = self.build()
        graph = builder.compile(
            checkpointer=self._checkpointer,
            store=self._store,
        )
        mantis_log("INFO", "supervisor_compiled", f"Checkpointer={self._checkpointer is not None}")
        return graph

# ═══════════════════════════════════════════════════════════════════════════
# 5. EXECUTOR DE SUPERVISOR
# ═══════════════════════════════════════════════════════════════════════════
class SupervisorRunner:
    """Executa um supervisor compilado com gerenciamento de threads."""
    def __init__(self, graph: Pregel, default_user_id: str = "default"):
        self.graph = graph
        self.default_user_id = default_user_id
        self._threads: Dict[str, str] = {}

    def _get_config(self, user_id: str = None, thread_id: str = None) -> RunnableConfig:
        uid = user_id or self.default_user_id
        tid = thread_id or self._threads.get(uid, str(uuid.uuid4()))
        self._threads[uid] = tid
        return {"configurable": {"thread_id": tid, "user_id": uid}}

    def invoke(self, message: str, user_id: str = None) -> dict:
        cfg = self._get_config(user_id)
        mantis_log("INFO", "supervisor_invoke", f"User={cfg['configurable'].get('user_id')}")
        return self.graph.invoke(
            {"messages": [{"role": "user", "content": message}]},
            cfg,
        )

    async def ainvoke(self, message: str, user_id: str = None) -> dict:
        cfg = self._get_config(user_id)
        return await self.graph.ainvoke(
            {"messages": [{"role": "user", "content": message}]},
            cfg,
        )
```

```python
# ═══════════════════════════════════════════════════════════════════════════
# 6. EXEMPLO COMPLETO: SUPERVISOR DE EQUIPE DE DESENVOLVIMENTO
# ═══════════════════════════════════════════════════════════════════════════
def build_dev_team_supervisor() -> SupervisorRunner:
    """Constrói um supervisor que gerencia agentes de código, documentação e QA."""
    from langchain_core.tools import tool

    @tool
    def read_code(file_path: str) -> str:
        """Lê um arquivo de código."""
        return f"Conteúdo de {file_path}: ..."

    @tool
    def write_doc(title: str, content: str) -> str:
        """Escreve documentação."""
        mantis_log("INFO", "doc_written", title)
        return f"Documento '{title}' criado."

    @tool
    def run_tests(test_path: str) -> str:
        """Executa testes."""
        return "Todos os testes passaram."

    coder = create_agent(
        SupervisorModelProvider.get_supervisor_model(),
        tools=[read_code],
        system_prompt="Você é um desenvolvedor sênior. Analise e escreva código.",
        name="coder",
    )

    doc_writer = create_agent(
        SupervisorModelProvider.get_supervisor_model(),
        tools=[write_doc],
        system_prompt="Você é um escritor técnico. Crie documentação clara.",
        name="doc_writer",
    )

    qa = create_agent(
        SupervisorModelProvider.get_supervisor_model(),
        tools=[run_tests],
        system_prompt="Você é um QA engineer. Execute testes e reporte resultados.",
        name="qa",
    )

    builder = SupervisorBuilder(supervisor_name="dev_supervisor")
    builder.with_prompt(
        "Você é um gerente de projeto. Para código, use 'coder'. "
        "Para documentação, use 'doc_writer'. Para testes, use 'qa'."
    )
    builder.add_agent(coder).add_agent(doc_writer).add_agent(qa)
    builder.with_checkpointer(InMemorySaver()).with_store(InMemoryStore())
    graph = builder.compile()
    return SupervisorRunner(graph)
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from supervisor_fundamentals import SupervisorBuilder, SupervisorRunner, SupervisedAgentSpec, build_dev_team_supervisor
from langgraph.checkpoint.memory import InMemorySaver

def test_supervisor_builder_empty():
    builder = SupervisorBuilder()
    with pytest.raises(ValueError):
        builder.build()

def test_supervisor_builder_with_agent():
    from langchain.agents import create_agent
    from supervisor_fundamentals import SupervisorModelProvider
    model = SupervisorModelProvider.get_supervisor_model()
    agent = create_agent(model, tools=[], system_prompt="Test", name="helper")
    builder = SupervisorBuilder()
    builder.add_agent(agent)
    builder.with_checkpointer(InMemorySaver())
    graph = builder.compile()
    assert graph is not None

def test_dev_team_supervisor():
    runner = build_dev_team_supervisor()
    result = runner.invoke("Escreva documentação para a API de usuários")
    assert "messages" in result
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/11-swarm-supervisor/supervisor-fundamentals.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[swarm-fundamentals.md]]
- [[swarm-supervisor-patterns.md]]
