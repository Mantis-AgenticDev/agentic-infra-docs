---
artifact_id: "procedures-general-langchain-sop"
artifact_type: "standard_operating_procedure"
version: "2.3.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
canonical_path: "07-PROCEDURES/general-langchain-sop.md"
tier: 1
immutable: false
requires_human_approval_for_changes: true
audience: ["human-architects","agentic-assistants","orchestrator-engine","ai-engineers","developers"]
language_lock: "pt-BR"
prompt_hash: "sha256:general-langchain-sop-v2.3.0"
generated_at: "2026-05-28T08:00:00Z"
domain: "procedures"
subdomain: "general-langchain"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---

# 📐 Procedimento Operacional Padrão — LangChain/LangGraph: Fundacional e Tradicional

**Objetivo**: Estabelecer o fluxo de trabalho completo para criação, validação, teste e deploy de pipelines e agentes usando as bibliotecas fundacionais (`00-fundacional`) e os padrões tradicionais (`01-langchain-tradicional`) do ecossistema LangChain/LangGraph no domínio `04-WORKFLOWS/langchain-langraph/`.

**Público-alvo**: Arquitetos humanos, agentes mestres, engenheiros de IA, desenvolvedores Python/TypeScript, operadores de infraestrutura.

---

## 1. Visão Geral dos Subdomínios

O domínio `04-WORKFLOWS/langchain-langraph/libs/` contém dois subdomínios iniciais que formam a base de todo o ecossistema:

- **00‑fundacional** (4 skills): Blocos de construção essenciais — LCEL, `create_agent`, `StateGraph`, gerenciamento de dependências.
- **01‑langchain‑tradicional** (12 skills): Padrões clássicos — chains, agentes ReAct, middleware, memória, streaming, deploy.

### 1.1 Conexão com o Ecossistema `goals/`

```mermaid
graph TD
    CEO["🏭 workflows-ceo"] -->|1. Consulta| STACK["00-STACK-SELECTOR.md"]
    STACK -->|2. Resolve motor| LANG["🦜 langchain-langraph-master-agent"]
    LANG -->|3. Carrega skills sob demanda| FUND["00-fundacional (4 skills)"]
    LANG -->|3. Carrega skills sob demanda| TRAD["01-langchain-tradicional (12 skills)"]
    FUND -->|4. Gera artefacto| ART["Artefacto .md com código Python/TS"]
    TRAD -->|4. Gera artefacto| ART
    ART -->|5. Valida| VAL["orchestrator-engine.sh"]
    VAL -->|6. Handoff A2A| STATUS["status.json + trace.json"]
    STATUS -->|7. Consolida| CEO
```

---

## 2. Mapa de Skills e Inter-relações

### 2.1 00‑fundacional (4 skills)

```mermaid
graph TD
    MASTER["🦜 langchain-langraph-master-agent"]:::foundation
    LCEL["langchain-core-concepts.md<br/>LCEL, prompts, modelos, output parsers"]:::core
    AGENT["langgraph-create-agent.md<br/>create_agent(), ferramentas, middleware"]:::core
    GRAPH["langgraph-state-graph-fundamentals.md<br/>StateGraph, nós, arestas, checkpointing"]:::core
    DEPS["langchain-dependencies-management.md<br/>requirements.txt, pyproject.toml"]:::core

    MASTER --> LCEL
    MASTER --> AGENT
    MASTER --> GRAPH
    MASTER --> DEPS

    LCEL --> AGENT
    GRAPH --> AGENT
    DEPS --> LCEL
    DEPS --> GRAPH

    classDef foundation fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:3px
    classDef core fill:#16213e,color:#fff,stroke:#E0AF68,stroke-width:2px
    class MASTER foundation
    class LCEL,AGENT,GRAPH,DEPS core
```

### 2.2 01‑langchain‑tradicional (12 skills)

```mermaid
graph TD
    MASTER["🦜 langchain-langraph-master-agent"]:::foundation
    AGENTS["langchain-agents-orchestration.md<br/>ReAct, Tool Calling"]:::agent
    CHAINS["langchain-chains-orchestration.md<br/>RunnableSequence, Parallel, Branch"]:::chain
    MIDDLEWARE["langchain-custom-middleware.md<br/>wrap_tool_call, before_model"]:::middleware
    HITL["langchain-hitl-middleware.md<br/>HumanInTheLoopMiddleware"]:::middleware
    MEMORY["langchain-memory-systems.md<br/>Buffer, Window, Summary, Vector"]:::memory
    LTM["langchain-long-term-memory.md<br/>InMemoryStore, PostgresStore"]:::memory
    STREAMING["langchain-streaming-patterns.md<br/>.stream(), astream_events"]:::stream
    SDK["langchain-sdk-patterns.md<br/>withFallbacks, SQLiteCache, batch"]:::sdk
    LANGSERVE["langchain-deploy-langserve.md<br/>FastAPI, add_routes"]:::deploy
    EXPRESS["langchain-deploy-express.md<br/>REST/SSE, health checks"]:::deploy
    TS_WF["langchain-ts-workflow-builder.md<br/>Chains, LCEL em TypeScript"]:::ts
    TS_AGENTS["langchain-ts-agents-tools.md<br/>createToolCallingAgent"]:::ts

    MASTER --> AGENTS
    MASTER --> CHAINS
    MASTER --> MIDDLEWARE
    MASTER --> HITL
    MASTER --> MEMORY
    MASTER --> LTM
    MASTER --> STREAMING
    MASTER --> SDK
    MASTER --> LANGSERVE
    MASTER --> EXPRESS
    MASTER --> TS_WF
    MASTER --> TS_AGENTS

    AGENTS --> CHAINS
    AGENTS --> MIDDLEWARE
    MIDDLEWARE --> HITL
    MEMORY --> AGENTS
    MEMORY --> CHAINS
    STREAMING --> AGENTS
    STREAMING --> CHAINS
    SDK --> AGENTS
    LANGSERVE --> AGENTS
    EXPRESS --> TS_AGENTS
    TS_WF --> TS_AGENTS

    classDef foundation fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:3px
    classDef agent fill:#0f3460,color:#fff,stroke:#E0AF68,stroke-width:2px
    classDef chain fill:#16213e,color:#fff,stroke:#7f7f7f,stroke-width:1px
    classDef middleware fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:2px
    classDef memory fill:#16213e,color:#fff,stroke:#E0AF68,stroke-width:2px
    classDef stream fill:#0f3460,color:#fff,stroke:#7f7f7f,stroke-width:1px
    classDef sdk fill:#1a1a2e,color:#fff,stroke:#7f7f7f,stroke-width:1px
    classDef deploy fill:#16213e,color:#fff,stroke:#E0AF68,stroke-width:2px
    classDef ts fill:#0f3460,color:#fff,stroke:#E0AF68,stroke-width:2px

    class MASTER foundation
    class AGENTS agent
    class CHAINS chain
    class MIDDLEWARE,HITL middleware
    class MEMORY,LTM memory
    class STREAMING stream
    class SDK sdk
    class LANGSERVE,EXPRESS deploy
    class TS_WF,TS_AGENTS ts
```

---

## 3. Fluxo de Geração de Artefactos

```mermaid
stateDiagram-v2
    [*] --> Especificação: SDD + perfil de infra + constraints
    Especificação --> Seleção_de_Skills: Carregar 00-fundacional/00-INDEX.md + 01-langchain-tradicional/00-INDEX.md
    Seleção_de_Skills --> Estrutura: Definir State, Nodes, Edges (Graph API) ou entrypoint/task (Functional)
    Estrutura --> Implementação: Escrever lógica Python/TypeScript com bootstrap mantis_log
    Implementação --> Hardening: Aplicar retry, timeout, error handlers
    Hardening --> TDD: Escrever testes AAA (Arrange-Act-Assert)
    TDD --> Validação: orchestrator-engine.sh --json
    Validação --> Aprovado: passed=true + score >= min_score
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
    Master["🦜 langchain-langraph-master-agent"] --> Core["🧠 mantis-core-context.md<br/>Constraints C1-C8"]
    Master --> Rules["📜 harness-norms-v3.0.md<br/>Hardening padrão"]
    Master --> Orchestrator["⚙️ orchestrator-engine/main.go<br/>Validação automatizada"]
    Master --> Modelos["🤖 04-modelos<br/>Integração com LLMs"]
    Master --> DB["🗄️ 05-bases-datos<br/>Persistência e checkpoints"]
    Master --> Swarm["🐝 11-swarm-supervisor<br/>Enxames e supervisores"]
    Master --> N8N["🔄 n8n-master-agent<br/>Automação visual"]
    Master --> LGPD["🛡️ lgpd-guard<br/>Conformidade LGPD"]

    Core -.->|Define C1-C8| Master
    Rules -.->|Hardening| Master
    Orchestrator -.->|Valida artefactos| Master
    Modelos -.->|Fornece LLMs| Master
    DB -.->|Persiste estado| Master
    Swarm -.->|Orquestra agentes| Master
    N8N -.->|Handoff automação| Master
    LGPD -.->|Valida privacidade| Master

    classDef masterStyle fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:4px
    classDef externalStyle fill:#0f3460,color:#fff,stroke:#E0AF68,stroke-width:2px
    classDef govStyle fill:#16213e,color:#fff,stroke:#7f7f7f,stroke-width:1px

    class Master masterStyle
    class Modelos,DB,Swarm,N8N,LGPD externalStyle
    class Core,Rules,Orchestrator govStyle
```

---

## 5. Estrutura de Diretórios

```
04-WORKFLOWS/langchain-langraph/libs/
├── 00-fundacional/
│   ├── langchain-core-concepts.md       # LCEL, prompts, modelos, output parsers, RAG básico
│   ├── langgraph-create-agent.md        # create_agent() com ferramentas e checkpointer
│   ├── langgraph-state-graph-fundamentals.md  # StateGraph, TypedDict, checkpointing
│   └── langchain-dependencies-management.md   # Gestão de dependências
└── 01-langchain-tradicional/
    ├── langchain-agents-orchestration.md      # Agentes ReAct, Tool Calling
    ├── langchain-chains-orchestration.md      # Chains sequenciais e paralelas
    ├── langchain-custom-middleware.md         # Middleware customizado
    ├── langchain-hitl-middleware.md           # Human-in-the-Loop tradicional
    ├── langchain-memory-systems.md            # Buffer, Window, Summary, Vector
    ├── langchain-long-term-memory.md          # InMemoryStore, PostgresStore
    ├── langchain-streaming-patterns.md        # .stream(), astream_events
    ├── langchain-sdk-patterns.md              # Fallbacks, batch, caching
    ├── langchain-deploy-langserve.md          # FastAPI, add_routes, Docker
    ├── langchain-deploy-express.md            # Endpoints REST/SSE, Docker
    ├── langchain-ts-workflow-builder.md       # TypeScript workflow builder
    └── langchain-ts-agents-tools.md           # TypeScript agents e tools
```

---

## 6. Exemplos de Código e Padrões

### 6.1 Pipeline LCEL com RAG (langchain-core-concepts.md)

```python
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-4o", temperature=0)
prompt = ChatPromptTemplate.from_template("Resuma: {texto}")
parser = StrOutputParser()

chain = prompt | model | parser
result = chain.invoke({"texto": "O gato subiu no telhado..."})
print(result)
```

### 6.2 Agente com create_agent (langgraph-create-agent.md)

```python
from langchain.agents import create_agent
from langgraph.checkpoint.memory import InMemorySaver

def buscar_clima(cidade: str) -> str:
    """Busca o clima de uma cidade."""
    return f"Clima em {cidade}: 25°C, ensolarado"

agent = create_agent(
    model="gpt-4o",
    tools=[buscar_clima],
    system_prompt="Você é um assistente prestativo.",
    checkpointer=InMemorySaver()
)

result = agent.invoke({
    "messages": [{"role": "user", "content": "Qual o clima em São Paulo?"}]
})
```

### 6.3 StateGraph com Nós e Arestas (langgraph-state-graph-fundamentals.md)

```python
from typing import TypedDict
from langgraph.graph import StateGraph, START, END

class State(TypedDict):
    contador: int

def incrementar(state: State) -> dict:
    return {"contador": state["contador"] + 1}

def duplicar(state: State) -> dict:
    return {"contador": state["contador"] * 2}

builder = StateGraph(State)
builder.add_node("incrementar", incrementar)
builder.add_node("duplicar", duplicar)
builder.add_edge(START, "incrementar")
builder.add_edge("incrementar", "duplicar")
builder.add_edge("duplicar", END)

graph = builder.compile()
result = graph.invoke({"contador": 5})  # 5 → 6 → 12
print(result["contador"])  # 12
```

### 6.4 Middleware Customizado (langchain-custom-middleware.md)

```python
from langchain.agents.middleware import wrap_tool_call

@wrap_tool_call
def log_tool_call(request, handler):
    print(f"[LOG] Chamando ferramenta: {request.tool_name}")
    response = handler(request)
    print(f"[LOG] Resultado: {response}")
    return response

agent = create_agent(
    "gpt-4o",
    tools=[buscar_clima],
    middleware=[log_tool_call]
)
```

### 6.5 Streaming de Tokens (langchain-streaming-patterns.md)

```python
for chunk in graph.stream(
    {"topic": "programação"},
    stream_mode="messages",
    version="v2"
):
    if chunk["type"] == "messages":
        msg, metadata = chunk["data"]
        if hasattr(msg, "content") and msg.content:
            print(msg.content, end="", flush=True)
```

### 6.6 Deploy com LangServe (langchain-deploy-langserve.md)

```python
from fastapi import FastAPI
from langserve import add_routes

app = FastAPI()
add_routes(app, agent, path="/agent")

# Executar: uvicorn app:app --host 0.0.0.0 --port 8000
```

---

## 7. Processo de Validação

### 7.1 Comandos de Validação por Artefacto

```bash
# Validação de skill individual
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/00-fundacional/langchain-core-concepts.md \
  --json

# Validação completa do subdomínio 00-fundacional
for f in 04-WORKFLOWS/langchain-langraph/libs/00-fundacional/*.md; do
  bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file "$f" --json
done

# Validação completa do subdomínio 01-langchain-tradicional
for f in 04-WORKFLOWS/langchain-langraph/libs/01-langchain-tradicional/*.md; do
  bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file "$f" --json
done
```

### 7.2 Checklist de Validação Manual

| # | Verificação | Constraint | Comando | ✅ Esperado |
|---|---|---|---|---|
| 1 | Frontmatter YAML válido | C5 | `validate-frontmatter.sh` | passed=true |
| 2 | Bootstrap com mantis_log | C8 | `grep 'def mantis_log' <file>` | Encontrado |
| 3 | Testes TDD presentes | C5 | `grep 'def test_' <file>` | ≥3 testes |
| 4 | Wikilinks canônicos | C5 | `check-wikilinks.sh` | Zero quebrados |
| 5 | Código ≥500 linhas | C5 | `wc -l <file>` | ≥500 |
| 6 | Constraints mapeadas | C5 | `grep 'constraints_mapped' <file>` | Lista válida |
| 7 | Sem secrets hardcoded | C3 | `audit-secrets.sh` | Zero violações |
| 8 | Exemplos executáveis | C5 | `python3 -c "..."` | Sem erros de sintaxe |

---

## 8. Troubleshooting

| Sintoma | Causa Provável | Diagnóstico | Solução |
|---------|---------------|-------------|---------|
| `ImportError: cannot import 'create_agent'` | LangChain desatualizado | `pip show langchain` | `pip install -U langchain>=1.0` |
| `StateGraph não compila` | Reducer ausente ou chave incorreta | `graph.get_graph().draw_mermaid_png()` | Verificar TypedDict e Annotated |
| `ToolCall não reconhecido` | Modelo sem suporte a function calling | `model.bind_tools()` | Usar modelo compatível (gpt-4, claude-3) |
| `Streaming sem output` | Modo `messages` requer `version="v2"` | `graph.stream(stream_mode="messages")` | Adicionar `version="v2"` |
| `HITL não pausa` | `interrupt_on` mal configurado | `graph.get_state(config)` | Verificar `interrupt_on` no middleware |
| `Memória não persiste` | Checkpointer ausente | `graph.compile(checkpointer=...)` | Adicionar `InMemorySaver` ou `PostgresSaver` |
| `LangServe não expõe rota` | `langgraph.json` ausente ou inválido | `langgraph dev` | Verificar estrutura do projeto |
| `TypeScript: type errors` | `tsconfig.json` ausente | `tsc --noEmit` | Configurar `tsconfig.json` |

---

## 9. Referências Cruzadas

- [[04-WORKFLOWS/langchain-langraph/langchain-langraph-master-agent.md]] — Master Agent central
- [[04-WORKFLOWS/langchain-langraph/libs/00-fundacional/langchain-core-concepts.md]]
- [[04-WORKFLOWS/langchain-langraph/libs/00-fundacional/langgraph-create-agent.md]]
- [[04-WORKFLOWS/langchain-langraph/libs/00-fundacional/langgraph-state-graph-fundamentals.md]]
- [[04-WORKFLOWS/langchain-langraph/libs/00-fundacional/langchain-dependencies-management.md]]
- [[04-WORKFLOWS/langchain-langraph/libs/01-langchain-tradicional/]] — 12 skills tradicionais
- [[04-WORKFLOWS/workflows-ceo.md]] — CEO de workflows
- [[04-WORKFLOWS/00-STACK-SELECTOR.md]] — Stack Selector
- [[05-CONFIGURATIONS/validation/orchestrator-engine.sh]] — Motor de validação
- [[01-RULES/harness-norms-v3.0.md]] — Hardening padrão
- [[01-RULES/11-A2A-COMMUNICATION-RULES.md]] — Contrato A2A (C9)
- [[07-PROCEDURES/rag-langchain-langraph-sop.md]] — SOP de RAG (próximo)

---

> **Versão 2.3.0** | Procedimento Operacional Padrão dos subdomínios `00-fundacional` e `01-langchain-tradicional` — MANTIS Agentic.
> Aplicável a partir de 2026-05-28.
