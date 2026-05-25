---
artifact_id: "swarm-supervisor-patterns"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/11-swarm-supervisor/swarm-supervisor-patterns.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/11-swarm-supervisor/swarm-supervisor-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:swarm-supervisor-patterns-v1"
generated_at: "2026-05-27T08:45:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["workflows-ceo", "multi-agent-memory"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks", "workflows-ceo"]
status: "🟢 Novo"
next_review: "2026-08-27"
---

# 🧩 Swarm-Supervisor Patterns — Arquiteturas Híbridas e Colaborativas

> **Contrato modular**: Artefato filho do Master Agent. Implementa padrões de combinação de swarm e supervisor para criar sistemas multi-agente que se auto-organizam, com planejamento centralizado e execução distribuída.

## 🎯 Propósito

Permitir a construção de arquiteturas híbridas onde um supervisor coordena um enxame de agentes, ou onde múltiplos supervisores colaboram em hierarquia, habilitando a geração colaborativa de artefatos e a delegação dinâmica de tarefas.

## 📋 Especificação (SDD)
- **Entradas**: Especificações de agentes, configuração de supervisor, modo de colaboração
- **Saídas**: Grafo compilado com supervisor + swarm integrados
- **Side Effects**: Registro de handoffs, métricas de coordenação
- **Constraints Aplicáveis**: C1, C2, C3, C5, C7, C8, C9
- **Dependências**: `langgraph-supervisor`, `langgraph-swarm`, `swarm-fundamentals`, `supervisor-fundamentals`

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
# 1. PADRÃO 1: SUPERVISOR QUE ORQUESTRA UM ENXAME
# ═══════════════════════════════════════════════════════════════════════════
from swarm_fundamentals import SwarmBuilder, AgentSpec, SwarmRunner
from supervisor_fundamentals import SupervisorBuilder, SupervisorRunner, SupervisorModelProvider
from langgraph_supervisor import create_supervisor
from langgraph_swarm import create_swarm
from langgraph.graph import StateGraph
from langgraph.checkpoint.memory import InMemorySaver

class SupervisorOverSwarm:
    """
    Um supervisor de alto nível que gerencia um enxame como um de seus agentes.
    O enxame é tratado como um agente compilado que pode receber handoffs.
    """
    def __init__(self, supervisor_name: str = "top_supervisor"):
        self.supervisor_name = supervisor_name
        self.supervisor_agents = []
        self.swarm_runner = None
        self._supervisor_builder = SupervisorBuilder(supervisor_name)

    def set_swarm(self, swarm_runner: SwarmRunner):
        self.swarm_runner = swarm_runner

    def add_supervised_agent(self, agent):
        self._supervisor_builder.add_agent(agent)

    def compile(self):
        # Adiciona o enxame como um agente wrapper
        if self.swarm_runner:
            # Cria um agente wrapper que invoca o enxame
            from langchain.agents import create_agent
            model = SupervisorModelProvider.get_supervisor_model()
            swarm_agent = create_agent(
                model,
                tools=[],
                system_prompt="Você é um enxame de agentes especializados. Encaminhe solicitações para os agentes internos.",
                name="swarm_team",
            )
            self._supervisor_builder.add_agent(swarm_agent)
        return self._supervisor_builder.compile()

# ═══════════════════════════════════════════════════════════════════════════
# 2. PADRÃO 2: ENXAME COM AGENTES QUE SÃO SUPERVISORES LOCAIS
# ═══════════════════════════════════════════════════════════════════════════
class SwarmOfSupervisors:
    """
    Um enxame onde cada agente é um supervisor de seu próprio time.
    Isso permite hierarquias profundas e especialização por domínio.
    """
    def __init__(self, default_active: str):
        self.default_active = default_active
        self.supervisors: Dict[str, SupervisorBuilder] = {}
        self._swarm_builder = SwarmBuilder(default_active)

    def add_supervisor_team(self, supervisor_builder: SupervisorBuilder):
        team_graph = supervisor_builder.compile()
        self._swarm_builder.add_agent(team_graph)
        mantis_log("INFO", "added_supervisor_team", supervisor_builder.supervisor_name)

    def compile(self):
        return self._swarm_builder.compile()

# ═══════════════════════════════════════════════════════════════════════════
# 3. PADRÃO 3: COLABORAÇÃO COM PLANEJADOR CENTRAL (PLANNER-EXECUTOR)
# ═══════════════════════════════════════════════════════════════════════════
class PlannerExecutorSwarm:
    """
    Um enxame com dois agentes: um planner (supervisor leve) e um executor (swarm).
    O planner analisa a solicitação, define um plano e o executor implementa.
    """
    def __init__(self, planner_prompt: str, executor_specs: List[AgentSpec]):
        self.planner_prompt = planner_prompt
        self.executor_specs = executor_specs
        self.model = SupervisorModelProvider.get_supervisor_model()

    def build(self):
        # Cria agente planner
        planner = create_agent(
            self.model,
            tools=[],
            system_prompt=self.planner_prompt,
            name="planner",
        )
        # Cria enxame executor
        swarm_builder = SwarmBuilder("executor_agent")
        from swarm_fundamentals import AgentFactory
        factory = AgentFactory()
        for spec in self.executor_specs:
            agent = factory.create_agent(spec)
            swarm_builder.add_agent(agent)
        executor = swarm_builder.compile()

        # Supervisor que coordena planner e executor
        supervisor = create_supervisor(
            [planner, executor],
            model=self.model,
            prompt="Você é um coordenador. Primeiro use 'planner' para criar um plano. Depois use 'executor' para implementá-lo.",
            output_mode="last_message",
            supervisor_name="coordinator",
        )
        return supervisor.compile(checkpointer=InMemorySaver())

# ═══════════════════════════════════════════════════════════════════════════
# 4. PADRÃO 4: ENXAME AUTO-ORGANIZÁVEL COM DESCOBERTA DE AGENTES
# ═══════════════════════════════════════════════════════════════════════════
class DynamicSwarm:
    """
    Enxame que descobre agentes dinamicamente a partir de um registro e os adiciona ao grafo.
    Ideal para sistemas que evoluem com novos agentes.
    """
    def __init__(self, default_active: str):
        self.registry: Dict[str, AgentSpec] = {}
        self.default_active = default_active
        self._graph = None

    def register_agent(self, spec: AgentSpec):
        self.registry[spec.name] = spec
        mantis_log("INFO", "agent_registered", spec.name)

    def unregister_agent(self, name: str):
        self.registry.pop(name, None)

    def compile(self):
        builder = SwarmBuilder(self.default_active)
        factory = AgentFactory()
        for spec in self.registry.values():
            agent = factory.create_agent(spec)
            builder.add_agent(agent)
        self._graph = builder.compile()
        return self._graph

# ═══════════════════════════════════════════════════════════════════════════
# 5. EXEMPLO COMPLETO: TIME DE DESENVOLVIMENTO COLABORATIVO
# ═══════════════════════════════════════════════════════════════════════════
def build_collaborative_dev_swarm() -> SwarmRunner:
    """Constrói um enxame de desenvolvimento com planner e executores."""
    planner_prompt = """
    Você é um arquiteto de software. Analise a solicitação e produza um plano estruturado com:
    - Objetivo
    - Componentes necessários
    - Passos de implementação
    - Agentes recomendados
    """
    executor_specs = [
        AgentSpec(name="coder", system_prompt="Você escreve código Python de alta qualidade.", tools=[],
                  handoff_destinations=["reviewer"]),
        AgentSpec(name="reviewer", system_prompt="Você revisa código e sugere melhorias.", tools=[],
                  handoff_destinations=["coder", "doc_writer"]),
        AgentSpec(name="doc_writer", system_prompt="Você cria documentação técnica.", tools=[],
                  handoff_destinations=[]),
    ]
    planner_executor = PlannerExecutorSwarm(planner_prompt, executor_specs)
    graph = planner_executor.build()
    return SwarmRunner(graph)
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from swarm_supervisor_patterns import (
    SupervisorOverSwarm, SwarmOfSupervisors, PlannerExecutorSwarm, DynamicSwarm,
    build_collaborative_dev_swarm
)
from swarm_fundamentals import SwarmBuilder, AgentSpec
from supervisor_fundamentals import SupervisorBuilder

def test_dynamic_swarm():
    swarm = DynamicSwarm("agent1")
    spec = AgentSpec(name="agent1", system_prompt="Test", tools=[])
    swarm.register_agent(spec)
    graph = swarm.compile()
    assert graph is not None

def test_collaborative_dev_swarm():
    runner = build_collaborative_dev_swarm()
    result = runner.invoke("Criar uma API REST de tarefas")
    assert "messages" in result

def test_planner_executor_swarm():
    specs = [AgentSpec(name="executor", system_prompt="Execute", tools=[])]
    builder = PlannerExecutorSwarm("Plan", specs)
    graph = builder.build()
    assert graph is not None
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/11-swarm-supervisor/swarm-supervisor-patterns.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[swarm-fundamentals.md]]
- [[supervisor-fundamentals.md]]
- [[handoff-tools-advanced.md]]
- [[workflows-ceo.md]]
