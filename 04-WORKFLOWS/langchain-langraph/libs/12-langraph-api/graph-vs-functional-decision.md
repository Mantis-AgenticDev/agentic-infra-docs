---
artifact_id: "graph-vs-functional-decision"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/graph-vs-functional-decision.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/graph-vs-functional-decision.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:graph-vs-functional-v1"
generated_at: "2026-05-27T14:30:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["graph-api-fundamentals", "functional-api-fundamentals", "workflows-ceo"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks", "workflows-ceo"]
status: "🟢 Novo"
next_review: "2026-08-27"
---

# 🧩 Graph vs Functional API — Matriz de Decisão e Migração

> **Contrato modular**: Artefato filho do Master Agent. Fornece um sistema de decisão automatizado para escolher entre Graph API e Functional API, com exemplos de migração e combinação.

## 🎯 Propósito

Permitir que o orquestrador (workflows-ceo) e desenvolvedores decidam programaticamente qual API usar com base nas características do workflow, e migrem entre APIs quando necessário.

## 📋 Especificação (SDD)
- **Entradas**: Características do workflow (complexidade, paralelismo, estado, time)
- **Saídas**: Recomendação de API com justificativa
- **Side Effects**: Logging da decisão
- **Constraints Aplicáveis**: C1, C2, C5, C8
- **Dependências**: `graph-api-fundamentals`, `functional-api-fundamentals`

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
# 1. SISTEMA DE DECISÃO AUTOMATIZADO
# ═══════════════════════════════════════════════════════════════════════════
from enum import Enum
from dataclasses import dataclass
from typing import Literal

class APIType(Enum):
    GRAPH = "graph"
    FUNCTIONAL = "functional"
    HYBRID = "hybrid"

@dataclass
class WorkflowCharacteristics:
    """Características do workflow para decisão de API."""
    has_complex_branching: bool = False
    has_parallel_execution: bool = False
    needs_visualization: bool = False
    has_shared_state: bool = False
    team_collaboration: bool = False
    is_linear: bool = True
    has_existing_code: bool = False
    needs_rapid_prototyping: bool = False
    needs_hitl: bool = False
    state_scope_local: bool = True

class APIDecisionEngine:
    """Motor de decisão para escolha de API."""
    def __init__(self):
        self.rules = []

    def analyze(self, chars: WorkflowCharacteristics) -> dict:
        score_graph = 0
        score_functional = 0
        reasons_graph = []
        reasons_functional = []

        # Regras para Graph API
        if chars.has_complex_branching:
            score_graph += 3
            reasons_graph.append("Ramificações complexas")
        if chars.has_parallel_execution:
            score_graph += 3
            reasons_graph.append("Execução paralela")
        if chars.needs_visualization:
            score_graph += 2
            reasons_graph.append("Necessita visualização")
        if chars.has_shared_state:
            score_graph += 2
            reasons_graph.append("Estado compartilhado")
        if chars.team_collaboration:
            score_graph += 1
            reasons_graph.append("Colaboração em equipe")

        # Regras para Functional API
        if chars.has_existing_code:
            score_functional += 3
            reasons_functional.append("Código existente")
        if chars.needs_rapid_prototyping:
            score_functional += 3
            reasons_functional.append("Prototipagem rápida")
        if chars.is_linear:
            score_functional += 2
            reasons_functional.append("Fluxo linear")
        if chars.state_scope_local:
            score_functional += 1
            reasons_functional.append("Estado local")

        # Decisão
        if abs(score_graph - score_functional) <= 2:
            recommendation = APIType.HYBRID
        elif score_graph > score_functional:
            recommendation = APIType.GRAPH
        else:
            recommendation = APIType.FUNCTIONAL

        mantis_log("INFO", "api_decision", f"Graph={score_graph}, Func={score_functional}, Rec={recommendation.value}")
        return {
            "recommendation": recommendation.value,
            "score_graph": score_graph,
            "score_functional": score_functional,
            "reasons_graph": reasons_graph,
            "reasons_functional": reasons_functional,
        }

# ═══════════════════════════════════════════════════════════════════════════
# 2. FÁBRICA DE MIGRAÇÃO ENTRE APIs
# ═══════════════════════════════════════════════════════════════════════════
class APIMigrationFactory:
    """Utilitários para migrar entre Graph API e Functional API."""

    @staticmethod
    def functional_to_graph(tasks: list[callable], state_schema: type) -> "GraphBuilder":
        """Converte um workflow funcional (sequência de tasks) em Graph API."""
        from graph_api_fundamentals import GraphBuilder
        builder = GraphBuilder(state_schema)
        for i, task_fn in enumerate(tasks):
            node_name = f"step_{i+1}"
            builder.add_node(node_name, task_fn)
            if i == 0:
                builder.set_entry_point(node_name)
            else:
                builder.add_edge(f"step_{i}", node_name)
        builder.set_finish_point(f"step_{len(tasks)}")
        return builder.compile()

    @staticmethod
    def graph_to_functional(graph):
        """Converte um grafo simples em workflow funcional."""
        from langgraph.func import entrypoint
        @entrypoint()
        def wrapper(inputs: dict) -> dict:
            return graph.invoke(inputs)
        return wrapper

# ═══════════════════════════════════════════════════════════════════════════
# 3. COMBINAÇÃO DE APIs (HYBRID)
# ═══════════════════════════════════════════════════════════════════════════
class HybridWorkflowBuilder:
    """Constrói workflows que combinam Graph API e Functional API."""
    def __init__(self):
        self.graph_parts = []
        self.functional_parts = []

    def add_graph_component(self, graph):
        self.graph_parts.append(graph)
        return self

    def add_functional_component(self, func):
        self.functional_parts.append(func)
        return self

    def build(self) -> callable:
        """Retorna uma função que orquestra os componentes."""
        def orchestrator(inputs: dict) -> dict:
            result = inputs
            for part in self.graph_parts:
                result = part.invoke(result)
            for part in self.functional_parts:
                result = part.invoke(result)
            return result
        return orchestrator

# ═══════════════════════════════════════════════════════════════════════════
# 4. TABELA DE COMPARAÇÃO (GERAÇÃO DE DOCUMENTAÇÃO)
# ═══════════════════════════════════════════════════════════════════════════
COMPARISON_TABLE = {
    "control_flow": {"graph": "Explícito (arestas)", "functional": "Padrão Python (if/for)"},
    "state_management": {"graph": "Estado compartilhado com reducers", "functional": "Escopo de função"},
    "visualization": {"graph": "Suportada (Mermaid)", "functional": "Não suportada"},
    "parallelism": {"graph": "Nativo (Send)", "functional": "Futures"},
    "checkpointing": {"graph": "A cada superstep", "functional": "Resultados de tasks"},
    "boilerplate": {"graph": "Médio", "functional": "Baixo"},
    "learning_curve": {"graph": "Média", "functional": "Baixa"},
    "best_for": {"graph": "Workflows complexos", "functional": "Workflows lineares / código existente"},
}

def generate_comparison_docs() -> str:
    """Gera documentação da tabela de comparação em markdown."""
    lines = ["| Característica | Graph API | Functional API |", "|---|---|---|"]
    for key, value in COMPARISON_TABLE.items():
        lines.append(f"| {key.replace('_', ' ').title()} | {value['graph']} | {value['functional']} |")
    return "\n".join(lines)
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from graph_vs_functional_decision import (
    APIDecisionEngine, WorkflowCharacteristics, APIType,
    APIMigrationFactory, HybridWorkflowBuilder, generate_comparison_docs
)

def test_decision_graph():
    engine = APIDecisionEngine()
    chars = WorkflowCharacteristics(has_complex_branching=True, has_parallel_execution=True, needs_visualization=True)
    result = engine.analyze(chars)
    assert result["recommendation"] == APIType.GRAPH.value

def test_decision_functional():
    engine = APIDecisionEngine()
    chars = WorkflowCharacteristics(has_existing_code=True, is_linear=True, needs_rapid_prototyping=True)
    result = engine.analyze(chars)
    assert result["recommendation"] == APIType.FUNCTIONAL.value

def test_decision_hybrid():
    engine = APIDecisionEngine()
    chars = WorkflowCharacteristics(has_complex_branching=True, has_existing_code=True)
    result = engine.analyze(chars)
    assert result["recommendation"] == APIType.HYBRID.value

def test_comparison_docs():
    docs = generate_comparison_docs()
    assert "Graph API" in docs
    assert "Functional API" in docs

def test_hybrid_builder():
    builder = HybridWorkflowBuilder()
    # Mock components
    def fake_graph_invoke(inputs):
        return {"graph": "done", **inputs}
    def fake_func_invoke(inputs):
        return {"func": "done", **inputs}
    builder.add_graph_component(type('Graph', (), {'invoke': staticmethod(fake_graph_invoke)}))
    builder.add_functional_component(type('Func', (), {'invoke': staticmethod(fake_func_invoke)}))
    orch = builder.build()
    result = orch({"start": True})
    assert result["graph"] == "done"
    assert result["func"] == "done"
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/graph-vs-functional-decision.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[graph-api-fundamentals.md]]
- [[functional-api-fundamentals.md]]
