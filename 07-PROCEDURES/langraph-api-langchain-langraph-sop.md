---
artifact_id: "procedures-langgraph-api-sop"
artifact_type: "standard_operating_procedure"
version: "2.3.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
canonical_path: "07-PROCEDURES/langraph-api-langchain-langraph-sop.md"
tier: 1
immutable: false
requires_human_approval_for_changes: true
audience: ["human-architects","agentic-assistants","orchestrator-engine","ai-engineers","graph-developers"]
language_lock: "pt-BR"
prompt_hash: "sha256:langgraph-api-sop-v2.3.0"
generated_at: "2026-05-28T13:30:00Z"
domain: "procedures"
subdomain: "langgraph-api"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---

# ⚙️ Procedimento Operacional Padrão — LangChain/LangGraph: APIs do Runtime

**Objetivo**: Estabelecer o fluxo de trabalho completo para construção de grafos, uso da Functional API, streaming, HITL, tolerância a falhas e operação do runtime Pregel usando as 12 skills do subdomínio `12-langgraph-api` no ecossistema LangChain/LangGraph dentro de `04-WORKFLOWS/langchain-langraph/`.

**Público-alvo**: Arquitetos humanos, agentes mestres, engenheiros de IA, desenvolvedores Python, operadores de runtime.

---

## 1. Visão Geral do Subdomínio

O subdomínio `12-langgraph-api` contém **12 skills** que expõem as APIs e o runtime do LangGraph:

| # | Skill | Propósito |
|---|-------|-----------|
| 1 | `graph-api-fundamentals.md` | StateGraph, nós, arestas, Command, Send |
| 2 | `functional-api-fundamentals.md` | @entrypoint, @task, short-term memory |
| 3 | `graph-vs-functional-decision.md` | Matriz de decisão entre APIs |
| 4 | `graph-api-advanced.md` | Múltiplos schemas, Overwrite, caching |
| 5 | `functional-api-advanced.md` | HITL, streaming, retry, timeout, caching |
| 6 | `streaming-api-fundamentals.md` | Stream modes, v2 format, filtros |
| 7 | `streaming-api-advanced.md` | Subgrafo, modelos arbitrários, diagnóstico |
| 8 | `interrupts-patterns.md` | HITL com interrupt(), múltiplos interrupts |
| 9 | `pregel-runtime-channels.md` | Pregel engine e canais de estado |
| 10 | `durable-execution-graceful-shutdown.md` | Execução durável e graceful shutdown |
| 11 | `fault-tolerance-patterns.md` | Retry, timeout e error handlers |
| 12 | `event-streaming-v3-api.md` | Event streaming v3 com projeções tipadas |

### 1.1 Conexão com o Ecossistema `goals/`

```mermaid
graph TD
    CEO["🏭 workflows-ceo"] -->|1. Consulta| STACK["00-STACK-SELECTOR.md"]
    STACK -->|2. Resolve motor| LANG["🦜 langchain-langraph-master-agent"]
    LANG -->|3. Seleciona domínio| API["12-langgraph-api (12 skills)"]
    API -->|4. Gera artefacto| ART["Artefacto .md com API do runtime"]
    ART -->|5. Valida| VAL["orchestrator-engine.sh"]
    VAL -->|6. Handoff A2A| STATUS["status.json + trace.json"]
    STATUS -->|7. Consolida| CEO
```

---

## 2. Mapa de Skills e Inter-relações

```mermaid
graph TD
    MASTER["🦜 langchain-langraph-master-agent"]:::foundation

    subgraph "APIs de Construção"
        GRAPH_FUND["graph-api-fundamentals.md"]:::core
        FUNC_FUND["functional-api-fundamentals.md"]:::core
        DECISION["graph-vs-functional-decision.md"]:::core
    end

    subgraph "APIs Avançadas"
        GRAPH_ADV["graph-api-advanced.md"]:::advanced
        FUNC_ADV["functional-api-advanced.md"]:::advanced
    end

    subgraph "Streaming"
        STREAM_FUND["streaming-api-fundamentals.md"]:::streaming
        STREAM_ADV["streaming-api-advanced.md"]:::streaming
        EVENT_V3["event-streaming-v3-api.md"]:::streaming
    end

    subgraph "HITL e Resiliência"
        INTERRUPTS["interrupts-patterns.md"]:::hitl
        DURABLE["durable-execution-graceful-shutdown.md"]:::resilience
        FAULT["fault-tolerance-patterns.md"]:::resilience
    end

    subgraph "Runtime"
        PREGEL["pregel-runtime-channels.md"]:::runtime
    end

    MASTER --> GRAPH_FUND
    MASTER --> FUNC_FUND
    MASTER --> DECISION
    MASTER --> GRAPH_ADV
    MASTER --> FUNC_ADV
    MASTER --> STREAM_FUND
    MASTER --> STREAM_ADV
    MASTER --> EVENT_V3
    MASTER --> INTERRUPTS
    MASTER --> DURABLE
    MASTER --> FAULT
    MASTER --> PREGEL

    GRAPH_FUND --> GRAPH_ADV
    FUNC_FUND --> FUNC_ADV
    DECISION --> GRAPH_FUND
    DECISION --> FUNC_FUND
    GRAPH_ADV --> PREGEL
    FUNC_ADV --> INTERRUPTS
    STREAM_FUND --> STREAM_ADV
    STREAM_ADV --> EVENT_V3
    INTERRUPTS --> DURABLE
    FAULT --> DURABLE
    PREGEL --> FAULT

    classDef foundation fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:3px
    classDef core fill:#16213e,color:#fff,stroke:#E0AF68,stroke-width:2px
    classDef advanced fill:#0f3460,color:#fff,stroke:#E0AF68,stroke-width:2px
    classDef streaming fill:#1a1a2e,color:#fff,stroke:#7f7f7f,stroke-width:1px
    classDef hitl fill:#16213e,color:#fff,stroke:#E0AF68,stroke-width:2px
    classDef resilience fill:#0f3460,color:#fff,stroke:#7f7f7f,stroke-width:1px
    classDef runtime fill:#16213e,color:#fff,stroke:#E0AF68,stroke-width:2px

    class MASTER foundation
    class GRAPH_FUND,FUNC_FUND,DECISION core
    class GRAPH_ADV,FUNC_ADV advanced
    class STREAM_FUND,STREAM_ADV,EVENT_V3 streaming
    class INTERRUPTS hitl
    class DURABLE,FAULT resilience
    class PREGEL runtime
```

---

## 3. Fluxo de Geração de Artefacto da API

```mermaid
stateDiagram-v2
    [*] --> Especificação: Requisitos do grafo/workflow
    Especificação --> Seleção_de_Skills: Carregar 12-langgraph-api/00-INDEX.md
    Seleção_de_Skills --> Decisão: Escolher Graph API ou Functional API
    Decisão --> Construção: Implementar nós/tasks com state
    Construção --> Avançado: Adicionar schemas múltiplos, Overwrite
    Avançado --> Streaming: Configurar modos de stream
    Streaming --> HITL: Adicionar interrupts se necessário
    HITL --> Resiliência: Aplicar retry, timeout, error handlers
    Resiliência --> Runtime: Configurar Pregel e canais
    Runtime --> Validação: orchestrator-engine.sh --json
    Validação --> Aprovado: passed=true
    Validação --> Rejeitado: passed=false
    Rejeitado --> Diagnóstico: Ler issues_by_severity
    Diagnóstico --> Correção: Aplicar fix_hint
    Correção --> Validação
    Aprovado --> Registro: status.json + CHRONICLE.md
    Registro --> [*]
```

---

## 4. Conexão com Outros Domínios

```mermaid
graph LR
    API["⚙️ 12-langgraph-api<br/>12 skills"] --> Master["🦜 langchain-langraph-master-agent"]
    Master --> Fund["📐 00-fundacional<br/>StateGraph básico"]
    Master --> Modelos["🤖 04-modelos<br/>LLMs"]
    Master --> DB["🗄️ 05-bases-datos<br/>Checkpointers"]
    Master --> Swarm["🐝 11-swarm-supervisor<br/>Enxames"]
    Master --> OPS["🚀 08-operaciones-langsmith<br/>Deploy"]

    Fund -.->|Base dos grafos| API
    Modelos -.->|Fornece LLMs| API
    DB -.->|Persiste checkpoints| API
    Swarm -.->|Orquestra com API| API
    OPS -.->|Deploy dos grafos| API

    classDef apiStyle fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:4px
    classDef depStyle fill:#0f3460,color:#fff,stroke:#E0AF68,stroke-width:2px

    class API apiStyle
    class Master,Fund,Modelos,DB,Swarm,OPS depStyle
```

---

## 5. Estrutura de Diretórios

```
04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/
├── graph-api-fundamentals.md             # StateGraph, nós, arestas
├── functional-api-fundamentals.md        # @entrypoint, @task
├── graph-vs-functional-decision.md       # Matriz de decisão
├── graph-api-advanced.md                 # Múltiplos schemas
├── functional-api-advanced.md            # HITL, streaming, retry
├── streaming-api-fundamentals.md         # Stream modes, v2
├── streaming-api-advanced.md             # Subgrafo, diagnóstico
├── interrupts-patterns.md                # HITL com interrupt
├── pregel-runtime-channels.md            # Pregel e canais
├── durable-execution-graceful-shutdown.md # Execução durável
├── fault-tolerance-patterns.md           # Retry, timeout
└── event-streaming-v3-api.md             # Event streaming v3
```

---

## 6. Exemplos de Código e Padrões

### 6.1 StateGraph com Command (graph-api-fundamentals.md)

```python
from langgraph.graph import StateGraph, START, END
from langgraph.types import Command
from typing_extensions import TypedDict, Literal

class State(TypedDict):
    contador: int

def node_a(state: State) -> Command[Literal["node_b", END]]:
    if state["contador"] > 5:
        return Command(goto=END)
    return Command(goto="node_b", update={"contador": state["contador"] + 1})

builder = StateGraph(State)
builder.add_node("node_a", node_a)
builder.add_edge(START, "node_a")
graph = builder.compile()
```

### 6.2 Functional API com @entrypoint (functional-api-fundamentals.md)

```python
from langgraph.func import entrypoint, task
from langgraph.checkpoint.memory import InMemorySaver

@task
def processar(dado: str) -> str:
    return dado.upper()

@entrypoint(checkpointer=InMemorySaver())
def workflow(dados: dict) -> dict:
    resultado = processar(dados["input"]).result()
    return {"output": resultado}
```

### 6.3 Decisão Graph vs Functional (graph-vs-functional-decision.md)

```python
from graph_vs_functional_decision import APIDecisionEngine, WorkflowCharacteristics

engine = APIDecisionEngine()
chars = WorkflowCharacteristics(
    has_complex_branching=True,
    has_parallel_execution=True,
    needs_visualization=True
)
result = engine.analyze(chars)
# result["recommendation"] == "graph"
```

### 6.4 Interrupt para HITL (interrupts-patterns.md)

```python
from langgraph.types import interrupt, Command

def approval_node(state):
    decision = interrupt({"question": "Aprovar?", "details": state["action"]})
    return {"status": "approved" if decision else "rejected"}

# Executar até o interrupt
config = {"configurable": {"thread_id": "1"}}
result = graph.invoke({"action": "transferir R$500"}, config, version="v2")

# Retomar com resposta
graph.invoke(Command(resume=True), config, version="v2")
```

### 6.5 Tolerância a Falhas (fault-tolerance-patterns.md)

```python
from langgraph.types import RetryPolicy, TimeoutPolicy
from langgraph.errors import NodeError

builder.add_node(
    "call_api",
    call_api,
    retry_policy=RetryPolicy(max_attempts=3, retry_on=ConnectionError),
    timeout=TimeoutPolicy(run_timeout=30),
    error_handler=compensation_handler
)
```

### 6.6 Event Streaming v3 (event-streaming-v3-api.md)

```python
stream = graph.stream_events(inputs, version="v3")

for message in stream.messages:
    print(message.text, end="", flush=True)

final_state = stream.output
```

---

## 7. Processo de Validação

### 7.1 Comandos de Validação por Artefacto

```bash
# Validação de skill individual
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/graph-api-fundamentals.md \
  --json

# Validação completa do subdomínio 12-langgraph-api
for f in 04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/*.md; do
  bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file "$f" --json
done
```

### 7.2 Checklist de Validação

| # | Verificação | Constraint | Comando | ✅ Esperado |
|---|---|---|---|---|
| 1 | Frontmatter YAML válido | C5 | `validate-frontmatter.sh` | passed=true |
| 2 | Bootstrap com mantis_log | C8 | `grep 'def mantis_log' <file>` | Encontrado |
| 3 | Testes TDD presentes | C5 | `grep 'def test_' <file>` | ≥3 testes |
| 4 | State/entrypoint definido | C5 | `grep 'State\|@entrypoint\|@task' <file>` | Explícito |
| 5 | Streaming configurado | C8 | `grep 'stream\|stream_events' <file>` | Modo documentado |
| 6 | HITL com interrupt | C7 | `grep 'interrupt\|Command.resume' <file>` | Presente se aplicável |
| 7 | Retry/timeout configurado | C1 | `grep 'RetryPolicy\|TimeoutPolicy' <file>` | Se API externa |
| 8 | Sem secrets hardcoded | C3 | `audit-secrets.sh` | Zero violações |

---

## 8. Troubleshooting

| Sintoma | Causa Provável | Diagnóstico | Solução |
|---------|---------------|-------------|---------|
| `StateGraph não compila` | Schema inválido | `builder.compile()` | Verificar TypedDict e reducers |
| `@task não executa` | Chamado fora de entrypoint | `task_function()` | Invocar apenas dentro de @entrypoint |
| `Stream v2 sem output` | `version="v2"` ausente | `graph.stream(..., version="v2")` | Adicionar parâmetro |
| `Interrupt não pausa` | Checkpointer ausente | `graph.compile(checkpointer=...)` | Adicionar checkpointer |
| `Retry não ocorre` | Exceção não está em `retry_on` | `RetryPolicy(retry_on=...)` | Expandir lista de exceções |
| `Event streaming v3 não funciona` | LangGraph < 1.2 | `pip show langgraph` | Atualizar para >=1.2 |
| `Graceful shutdown não drena` | RunControl não passado | `graph.invoke(..., control=control)` | Passar RunControl |

---

## 9. Referências Cruzadas

- [[04-WORKFLOWS/langchain-langraph/langchain-langraph-master-agent.md]]
- [[04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/graph-api-fundamentals.md]]
- [[04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/functional-api-fundamentals.md]]
- [[04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/graph-vs-functional-decision.md]]
- [[04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/streaming-api-fundamentals.md]]
- [[04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/streaming-api-advanced.md]]
- [[04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/event-streaming-v3-api.md]]
- [[04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/interrupts-patterns.md]]
- [[04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/durable-execution-graceful-shutdown.md]]
- [[04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/fault-tolerance-patterns.md]]
- [[04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/pregel-runtime-channels.md]]
- [[04-WORKFLOWS/workflows-ceo.md]]
- [[04-WORKFLOWS/00-STACK-SELECTOR.md]]
- [[05-CONFIGURATIONS/validation/orchestrator-engine.sh]]
- [[07-PROCEDURES/swarm-supervisor-langchain-langraph-sop.md]]
- [[07-PROCEDURES/langchain-langraph-master-agent-sop.md]]

---

> **Versão 2.3.0** | Procedimento Operacional Padrão do subdomínio `12-langgraph-api` — MANTIS Agentic.
> Aplicável a partir de 2026-05-28.
