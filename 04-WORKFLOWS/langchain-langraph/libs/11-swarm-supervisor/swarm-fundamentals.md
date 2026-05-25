---
artifact_id: "swarm-fundamentals"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/11-swarm-supervisor/swarm-fundamentals.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/11-swarm-supervisor/swarm-fundamentals.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:swarm-fundamentals-v1"
generated_at: "2026-05-27T08:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: true
  required_for: ["swarm-supervisor-patterns", "multi-agent-memory", "multi-agent-streaming", "workflows-ceo"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks", "workflows-ceo"]
status: "🟢 Novo"
next_review: "2026-08-27"
---

# 🧩 Swarm Fundamentals — Enxame Multi-Agente com LangGraph Swarm

> **Contrato modular**: Artefato filho do Master Agent `langchain-langraph-master-agent`. Herda hardening, observability, thinking system e constraints via source/import. Contém APENAS a lógica de domínio específica para construção e operação de enxames multi-agente com `langgraph_swarm`.

## 🎯 Propósito

Fornecer uma fábrica de enxames multi-agente que permite criar, compilar e operacionalizar sistemas onde agentes especializados transferem controle dinamicamente via handoff tools, mantendo memória de agente ativo e integrando-se ao ecossistema MANTIS com logging, observabilidade e resiliência.

## 📋 Especificação (SDD)
- **Entradas**: Lista de agentes (`Pregel`), agente padrão ativo, configuração de memória, schema de estado customizado
- **Saídas**: `CompiledStateGraph` pronto para execução, com roteamento dinâmico e persistência
- **Side Effects**: Criação de `SwarmState`, injeção de handoff tools, registro de métricas de transferência
- **Constraints Aplicáveis**: C1 (Resiliência), C2 (Validação), C3 (Segurança), C5 (Integridade), C7 (Versionamento), C8 (Observabilidade)
- **Dependências**: `langgraph-swarm`, `langgraph`, `langchain-core`, `langgraph-checkpoint`, `pydantic`

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
# 1. IMPORTAÇÕES E CONFIGURAÇÃO DE AMBIENTE
# ═══════════════════════════════════════════════════════════════════════════
import asyncio, os, uuid, time, json, logging
from typing import Optional, Any, Dict, List, Callable, Union, Type, Literal
from dataclasses import dataclass, field
from datetime import datetime, timezone

from langchain_core.messages import HumanMessage, AIMessage, ToolMessage, AnyMessage
from langchain_core.tools import BaseTool
from langchain_core.runnables import RunnableConfig
from langchain.agents import create_agent, AgentState
from langchain.chat_models import init_chat_model, BaseChatModel
from langgraph.graph import StateGraph, MessagesState, START, END
from langgraph.checkpoint.base import BaseCheckpointSaver
from langgraph.checkpoint.memory import InMemorySaver
from langgraph.store.base import BaseStore
from langgraph.store.memory import InMemoryStore
from langgraph.prebuilt import ToolNode
from langgraph.types import Command
from langgraph.pregel import Pregel

from langgraph_swarm import (
    create_handoff_tool,
    create_swarm,
    SwarmState,
    add_active_agent_router,
    get_handoff_destinations,
)
from langgraph_swarm.handoff import METADATA_KEY_HANDOFF_DESTINATION

# ═══════════════════════════════════════════════════════════════════════════
# 2. CONFIGURAÇÃO DE MODELO (DEEPSEEK COMO DEFAULT, AGNÓSTICO)
# ═══════════════════════════════════════════════════════════════════════════
class ModelProvider:
    """Fábrica de modelos com fallback e logging."""
    PROVIDERS = {
        "deepseek": ("deepseek-chat", "deepseek"),
        "openai": ("gpt-4o", "openai"),
        "anthropic": ("claude-sonnet-4-6", "anthropic"),
        "qwen": ("qwen-max", "qwen"),
    }

    @staticmethod
    def get_model(
        provider: str = "deepseek",
        temperature: float = 0.05,
        max_tokens: int = 4096,
        timeout: int = 60,
        max_retries: int = 3
    ) -> BaseChatModel:
        model_name, provider_name = ModelProvider.PROVIDERS.get(provider, ModelProvider.PROVIDERS["deepseek"])
        try:
            model = init_chat_model(
                model=model_name,
                model_provider=provider_name,
                temperature=temperature,
                max_tokens=max_tokens,
                timeout=timeout,
                max_retries=max_retries,
            )
            mantis_log("INFO", "model_initialized", f"Provider={provider_name}, Model={model_name}")
            return model
        except Exception as e:
            mantis_log("ERROR", "model_init_failed", str(e))
            raise

# ═══════════════════════════════════════════════════════════════════════════
# 3. FÁBRICA DE AGENTES INDIVIDUAIS COM HANDOFF AUTOMÁTICO
# ═══════════════════════════════════════════════════════════════════════════
@dataclass
class AgentSpec:
    """Especificação de um agente para o enxame."""
    name: str
    system_prompt: str
    tools: List[Callable] = field(default_factory=list)
    model_provider: str = "deepseek"
    temperature: float = 0.05
    handoff_destinations: List[str] = field(default_factory=list)  # nomes dos agentes para os quais pode transferir
    state_schema: Type = AgentState

class AgentFactory:
    """Constrói agentes individuais compatíveis com swarm."""
    def __init__(self, default_model_provider: str = "deepseek"):
        self.default_provider = default_model_provider

    def create_agent(self, spec: AgentSpec) -> Pregel:
        model = ModelProvider.get_model(spec.model_provider, spec.temperature)
        tools = list(spec.tools)
        for dest in spec.handoff_destinations:
            handoff = create_handoff_tool(
                agent_name=dest,
                description=f"Transferir para {dest}"
            )
            tools.append(handoff)
        agent = create_agent(
            model,
            tools=tools,
            system_prompt=spec.system_prompt,
            name=spec.name,
            state_schema=spec.state_schema,
        )
        mantis_log("INFO", "agent_created", f"Name={spec.name}, Tools={len(tools)}")
        return agent

# ═══════════════════════════════════════════════════════════════════════════
# 4. FÁBRICA DE ENXAMES (SWARM BUILDER)
# ═══════════════════════════════════════════════════════════════════════════
class SwarmBuilder:
    """
    Construtor fluente para enxames multi-agente.
    Encapsula create_swarm, gerencia estado, memória e configuração de deploy.
    """
    def __init__(self, default_active_agent: str):
        self.agents: List[Pregel] = []
        self.default_active = default_active_agent
        self._checkpointer: Optional[BaseCheckpointSaver] = None
        self._store: Optional[BaseStore] = None
        self._state_schema: Type = SwarmState
        self._context_schema: Optional[Type] = None
        self._interrupt_before: List[str] = field(default_factory=list)
        self._interrupt_after: List[str] = field(default_factory=list)

    def add_agent(self, agent: Pregel) -> "SwarmBuilder":
        self.agents.append(agent)
        mantis_log("DEBUG", "swarm_add_agent", agent.name)
        return self

    def add_agents_from_specs(self, specs: List[AgentSpec], factory: Optional[AgentFactory] = None) -> "SwarmBuilder":
        factory = factory or AgentFactory()
        for spec in specs:
            agent = factory.create_agent(spec)
            self.add_agent(agent)
        return self

    def with_checkpointer(self, checkpointer: BaseCheckpointSaver) -> "SwarmBuilder":
        self._checkpointer = checkpointer
        return self

    def with_store(self, store: BaseStore) -> "SwarmBuilder":
        self._store = store
        return self

    def with_state_schema(self, schema: Type) -> "SwarmBuilder":
        self._state_schema = schema
        return self

    def with_context_schema(self, schema: Type) -> "SwarmBuilder":
        self._context_schema = schema
        return self

    def with_interrupts(self, before: List[str] = None, after: List[str] = None) -> "SwarmBuilder":
        if before:
            self._interrupt_before = before
        if after:
            self._interrupt_after = after
        return self

    def build(self) -> StateGraph:
        if not self.agents:
            raise ValueError("Pelo menos um agente é necessário")
        agent_names = [a.name for a in self.agents]
        if self.default_active not in agent_names:
            raise ValueError(f"Agente padrão '{self.default_active}' não está na lista de agentes: {agent_names}")
        builder = create_swarm(
            self.agents,
            default_active_agent=self.default_active,
            state_schema=self._state_schema,
            context_schema=self._context_schema,
        )
        mantis_log("INFO", "swarm_built", f"Agents={agent_names}, Default={self.default_active}")
        return builder

    def compile(self) -> Pregel:
        builder = self.build()
        graph = builder.compile(
            checkpointer=self._checkpointer,
            store=self._store,
            interrupt_before=self._interrupt_before or None,
            interrupt_after=self._interrupt_after or None,
        )
        mantis_log("INFO", "swarm_compiled", f"Checkpointer={self._checkpointer is not None}")
        return graph

# ═══════════════════════════════════════════════════════════════════════════
# 5. GERENCIADOR DE EXECUÇÃO DE ENXAME (RUNTIME)
# ═══════════════════════════════════════════════════════════════════════════
class SwarmRunner:
    """Executa um enxame compilado, gerenciando threads e métricas."""
    def __init__(self, graph: Pregel, default_user_id: str = "default"):
        self.graph = graph
        self.default_user_id = default_user_id
        self._threads: Dict[str, str] = {}  # user_id -> thread_id
        self._metrics = SwarmMetrics()

    def _get_config(self, user_id: str = None, thread_id: str = None) -> RunnableConfig:
        uid = user_id or self.default_user_id
        if thread_id is None:
            thread_id = self._threads.get(uid, str(uuid.uuid4()))
            self._threads[uid] = thread_id
        return {
            "configurable": {
                "thread_id": thread_id,
                "user_id": uid,
            }
        }

    def invoke(self, message: str, user_id: str = None, config: RunnableConfig = None) -> dict:
        cfg = config or self._get_config(user_id)
        start_time = time.time()
        mantis_log("INFO", "swarm_invoke_start", f"User={cfg['configurable'].get('user_id')}")
        result = self.graph.invoke(
            {"messages": [{"role": "user", "content": message}]},
            cfg,
        )
        elapsed = time.time() - start_time
        self._metrics.record_invoke(elapsed, result.get("active_agent", "unknown"))
        mantis_log("INFO", "swarm_invoke_end", f"Elapsed={elapsed:.2f}s, Active={result.get('active_agent')}")
        return result

    async def ainvoke(self, message: str, user_id: str = None, config: RunnableConfig = None) -> dict:
        cfg = config or self._get_config(user_id)
        start_time = time.time()
        mantis_log("INFO", "swarm_ainvoke_start", f"User={cfg['configurable'].get('user_id')}")
        result = await self.graph.ainvoke(
            {"messages": [{"role": "user", "content": message}]},
            cfg,
        )
        elapsed = time.time() - start_time
        self._metrics.record_invoke(elapsed, result.get("active_agent", "unknown"))
        return result

    def stream(self, message: str, user_id: str = None, config: RunnableConfig = None):
        cfg = config or self._get_config(user_id)
        mantis_log("INFO", "swarm_stream_start", f"User={cfg['configurable'].get('user_id')}")
        for chunk in self.graph.stream(
            {"messages": [{"role": "user", "content": message}]},
            cfg,
            stream_mode="values",
            subgraphs=True,
        ):
            yield chunk

    def reset_thread(self, user_id: str = None):
        uid = user_id or self.default_user_id
        self._threads.pop(uid, None)
        mantis_log("INFO", "swarm_thread_reset", f"User={uid}")

# ═══════════════════════════════════════════════════════════════════════════
# 6. MÉTRICAS DE ENXAME (OBSERVABILIDADE C8)
# ═══════════════════════════════════════════════════════════════════════════
@dataclass
class SwarmMetrics:
    total_invocations: int = 0
    total_elapsed: float = 0.0
    handoffs: Dict[str, int] = field(default_factory=dict)  # agente -> contagem
    errors: int = 0
    active_agents: Dict[str, int] = field(default_factory=dict)

    def record_invoke(self, elapsed: float, final_agent: str):
        self.total_invocations += 1
        self.total_elapsed += elapsed
        self.active_agents[final_agent] = self.active_agents.get(final_agent, 0) + 1

    def record_handoff(self, from_agent: str, to_agent: str):
        key = f"{from_agent}->{to_agent}"
        self.handoffs[key] = self.handoffs.get(key, 0) + 1
        mantis_log("DEBUG", "swarm_handoff", f"From={from_agent}, To={to_agent}")

    def record_error(self):
        self.errors += 1

    def report(self) -> dict:
        return {
            "total_invocations": self.total_invocations,
            "avg_elapsed": self.total_elapsed / max(self.total_invocations, 1),
            "handoffs": self.handoffs,
            "errors": self.errors,
            "active_agents": self.active_agents,
        }

# ═══════════════════════════════════════════════════════════════════════════
# 7. HANDOFF TOOL CUSTOMIZÁVEL COM INJEÇÃO DE CONTEXTO MANTIS
# ═══════════════════════════════════════════════════════════════════════════
def create_mantis_handoff_tool(
    *,
    agent_name: str,
    name: Optional[str] = None,
    description: Optional[str] = None,
    include_task_description: bool = False,
    include_tenant_context: bool = True,
) -> BaseTool:
    """
    Handoff tool que injeta contexto do tenant MANTIS e opcionalmente aceita descrição de tarefa.
    """
    from langgraph_swarm.handoff import _normalize_agent_name

    if name is None:
        name = f"transfer_to_{_normalize_agent_name(agent_name)}"
    if description is None:
        description = f"Transferir controle para o agente '{agent_name}'"

    from langchain_core.tools import tool, InjectedToolCallId
    from langgraph.prebuilt import InjectedState
    from typing import Annotated

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
        mantis_log("INFO", "handoff_executed", f"To={agent_name}, Task={task_description}")
        return Command(
            goto=agent_name,
            graph=Command.PARENT,
            update=update,
        )

    handoff_to_agent.metadata = {METADATA_KEY_HANDOFF_DESTINATION: agent_name}
    return handoff_to_agent

# ═══════════════════════════════════════════════════════════════════════════
# 8. EXEMPLO COMPLETO: ENXAME DE ATENDIMENTO MULTI-SERVIÇO
# ═══════════════════════════════════════════════════════════════════════════
def build_customer_service_swarm() -> SwarmRunner:
    """Constrói um enxame de atendimento com agente de voos e hotéis."""
    model = ModelProvider.get_model("deepseek")

    def search_flights(departure: str, arrival: str, date: str) -> str:
        """Busca voos."""
        return f"Voo encontrado: {departure} -> {arrival}, data {date}, companhia Latam, id=1"

    def book_flight(flight_id: str, config: RunnableConfig) -> str:
        """Reserva um voo."""
        user = config["configurable"].get("user_id", "anon")
        mantis_log("INFO", "flight_booked", f"User={user}, Flight={flight_id}")
        return f"Voo {flight_id} reservado com sucesso para {user}"

    def search_hotels(location: str) -> str:
        """Busca hotéis."""
        return f"Hotel encontrado: {location}, Hotel Central, id=1"

    def book_hotel(hotel_id: str, config: RunnableConfig) -> str:
        """Reserva um hotel."""
        user = config["configurable"].get("user_id", "anon")
        mantis_log("INFO", "hotel_booked", f"User={user}, Hotel={hotel_id}")
        return f"Hotel {hotel_id} reservado com sucesso para {user}"

    flight_agent = create_agent(
        model,
        tools=[
            search_flights, book_flight,
            create_mantis_handoff_tool(agent_name="hotel_agent", description="Transferir para agente de hotéis"),
        ],
        system_prompt="Você é um assistente de voos. Pode buscar e reservar voos. Para hotéis, transfira para hotel_agent.",
        name="flight_agent",
    )

    hotel_agent = create_agent(
        model,
        tools=[
            search_hotels, book_hotel,
            create_mantis_handoff_tool(agent_name="flight_agent", description="Transferir para agente de voos"),
        ],
        system_prompt="Você é um assistente de hotéis. Pode buscar e reservar hotéis. Para voos, transfira para flight_agent.",
        name="hotel_agent",
    )

    builder = SwarmBuilder(default_active_agent="flight_agent")
    builder.add_agent(flight_agent).add_agent(hotel_agent)
    builder.with_checkpointer(InMemorySaver()).with_store(InMemoryStore())
    graph = builder.compile()
    return SwarmRunner(graph)
```

```python
# ═══════════════════════════════════════════════════════════════════════════
# 9. INTEGRAÇÃO COM AGENT SERVER (DEPLOY STANDALONE)
# ═══════════════════════════════════════════════════════════════════════════
# Para deploy como Agent Server standalone, o grafo compilado deve ser exposto.
# Exemplo de langgraph.json:
CONFIG_EXAMPLE = """
{
  "dependencies": ["."],
  "graphs": {
    "customer_service_swarm": "./swarm_fundamentals.py:build_customer_service_swarm"
  },
  "env": ".env"
}
"""
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from swarm_fundamentals import (
    SwarmBuilder, AgentFactory, AgentSpec, SwarmRunner, ModelProvider,
    build_customer_service_swarm, SwarmMetrics
)
from langgraph.checkpoint.memory import InMemorySaver
from langchain_core.messages import HumanMessage

def test_swarm_builder_empty_raises():
    builder = SwarmBuilder("agent1")
    with pytest.raises(ValueError):
        builder.build()

def test_swarm_builder_basic():
    from langchain.agents import create_agent
    model = ModelProvider.get_model("deepseek")
    agent = create_agent(model, tools=[], system_prompt="Test", name="agent1")
    builder = SwarmBuilder("agent1")
    builder.add_agent(agent)
    builder.with_checkpointer(InMemorySaver())
    graph = builder.compile()
    assert graph is not None

def test_swarm_metrics():
    metrics = SwarmMetrics()
    metrics.record_invoke(1.5, "agent1")
    metrics.record_handoff("agent1", "agent2")
    assert metrics.total_invocations == 1
    assert metrics.handoffs["agent1->agent2"] == 1

def test_agent_factory():
    factory = AgentFactory()
    spec = AgentSpec(name="test_agent", system_prompt="Be helpful", tools=[], handoff_destinations=["other_agent"])
    agent = factory.create_agent(spec)
    assert agent.name == "test_agent"

def test_customer_service_swarm():
    runner = build_customer_service_swarm()
    result = runner.invoke("Preciso de um voo de POA para SP amanhã")
    assert "messages" in result
    assert len(result["messages"]) > 0
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/11-swarm-supervisor/swarm-fundamentals.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[swarm-supervisor-patterns.md]]
- [[multi-agent-memory.md]]
- [[langgraph-create-agent.md]]
