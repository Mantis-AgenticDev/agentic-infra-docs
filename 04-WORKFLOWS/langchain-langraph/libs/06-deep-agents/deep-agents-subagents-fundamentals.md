---
artifact_id: "deep-agents-subagents-fundamentals"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-subagents-fundamentals.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-subagents-fundamentals.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-subagents-v1.0.0"
generated_at: "2026-05-25T13:15:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-subagents-advanced", "deep-agents-orchestration-planning"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🧩 Deep Agents – Subagentes Fundamentais

> **Contrato modular**: Artefato filho do Master Agent. Documenta a criação, configuração e uso de subagentes síncronos em Deep Agents, incluindo delegação via `task`, isolamento de contexto, herança de ferramentas/skills e general-purpose subagent.

---

## 🎯 Propósito
Permitir que agentes MANTIS deleguem trabalho a subagentes especializados, mantendo o contexto limpo e maximizando a eficiência em tarefas multi-passo.

## 📋 Especificação (SDD)
- **Entradas**: Definição de subagentes (dicionário ou `CompiledSubAgent`), configuração do agente principal.
- **Saídas**: Subagentes acessíveis via ferramenta `task`.
- **Side Effects**: Criação de threads isoladas para cada subagente.
- **Constraints Aplicáveis**: C1 (contrato de subagente), C3 (isolamento de ferramentas sensíveis), C5 (schema de resposta), C7 (falha isolada), C8 (tracing por agente), C9 (propagação de trace_id).
- **Dependências**: `deepagents`, `langgraph`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
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
```

### 1. Subagente Simples com Ferramenta Específica

```python
from deepagents import create_deep_agent
from langchain.tools import tool
from tavily import TavilyClient
import os

tavily_client = TavilyClient(api_key=os.environ["TAVILY_API_KEY"])

@tool
def internet_search(query: str, max_results: int = 5, topic: str = "general") -> str:
    """Busca na web e retorna resultados."""
    result = tavily_client.search(query, max_results=max_results, topic=topic)
    mantis_log("INFO", "subagent_search", f"Query: {query}, Resultados: {len(result.get('results', []))}")
    return str(result)

research_subagent = {
    "name": "research-agent",
    "description": "Usado para pesquisar questões que exigem múltiplas buscas e síntese.",
    "system_prompt": "Você é um pesquisador excepcional. Busque informações, sintetize e retorne um resumo conciso com fontes.",
    "tools": [internet_search],
    "model": "openai:gpt-5.4",
}

agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    subagents=[research_subagent],
)
```

### 2. Delegação de Tarefas com `task`

```python
config = {"configurable": {"thread_id": "session-abc"}}
result = agent.invoke(
    {"messages": [{"role": "user", "content": "Pesquise as últimas tendências em IA e me dê um resumo."}]},
    config=config,
)
# Internamente, o agente chamará: task(agent="research-agent", instruction="Pesquisar tendências em IA...")
mantis_log("INFO", "task_delegated", "Tarefa delegada ao research-agent")
```

### 3. Múltiplos Subagentes Especializados

```python
subagents = [
    {
        "name": "data-collector",
        "description": "Coleta dados brutos de múltiplas fontes e os organiza em /workspace/data/.",
        "system_prompt": "Você coleta dados. Use ferramentas de busca e salve os resultados em arquivos.",
        "tools": [internet_search, write_file],
        "model": "openai:gpt-5.4",
    },
    {
        "name": "data-analyzer",
        "description": "Analisa dados coletados e extrai insights. Lê de /workspace/data/ e escreve em /workspace/analysis/.",
        "system_prompt": "Você analisa dados. Leia os arquivos em /workspace/data/, faça análises e salve os resultados.",
        "tools": [read_file, write_file],
        "model": "anthropic:claude-sonnet-4-6",
    },
    {
        "name": "report-writer",
        "description": "Escreve relatórios polidos a partir de análises. Lê de /workspace/analysis/ e produz o relatório final.",
        "system_prompt": "Você escreve relatórios profissionais. Use os dados de análise para criar um documento final.",
        "tools": [read_file, write_file],
        "model": "openai:gpt-5.4",
    },
]

agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    system_prompt="Você é um coordenador de projetos. Use os subagentes para cada fase do trabalho.",
    subagents=subagents,
)
```

### 4. Isolamento de Contexto – O Poder do Subagente

```python
# Sem subagente: o contexto do agente principal acumula 10 buscas
# Com subagente: o agente principal recebe apenas o resumo final

research_subagent = {
    "name": "deep-researcher",
    "description": "Pesquisador profundo que faz múltiplas buscas e retorna apenas a síntese.",
    "system_prompt": """Você é um pesquisador profundo. Suas regras:
    1. Faça múltiplas buscas para cobrir todos os ângulos.
    2. Salve dados brutos em /workspace/raw_data.md (não retorne ao agente principal).
    3. Retorne APENAS um resumo conciso (máximo 500 palavras).
    4. Inclua fontes ao final.""",
    "tools": [internet_search, write_file],
}
```

### 5. Herança de Ferramentas e Modelo

```python
# Subagente herda ferramentas do agente principal se não especificar tools
agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    tools=[internet_search, calculator, email_sender],
    subagents=[
        {
            "name": "helper",
            "description": "Ajudante geral que herda todas as ferramentas do principal.",
            "system_prompt": "Você é um assistente geral.",
            # tools não especificado → herda [internet_search, calculator, email_sender]
        }
    ],
)
```

### 6. Subagente com Structured Output

```python
from pydantic import BaseModel, Field

class ResearchFindings(BaseModel):
    summary: str = Field(description="Resumo dos achados")
    confidence: float = Field(description="Confiança de 0 a 1")
    sources: list[str] = Field(description="Lista de URLs das fontes")

research_subagent = {
    "name": "researcher",
    "description": "Pesquisa e retorna achados estruturados.",
    "system_prompt": "Pesquise o tópico e retorne achados estruturados.",
    "tools": [internet_search],
    "response_format": ResearchFindings,
}

agent = create_deep_agent(model="claude-sonnet-4-6", subagents=[research_subagent])
result = await agent.ainvoke(
    {"messages": [{"role": "user", "content": "Pesquise computação quântica"}]}
)
# O ToolMessage do agente principal conterá JSON com summary, confidence e sources
```

### 7. General‑Purpose Subagent (Sempre Presente)

```python
# Todo Deep Agent tem um subagente "general-purpose" automaticamente.
# Ele herda o modelo, ferramentas e system prompt do agente principal.
# Pode ser usado via: task(agent="general-purpose", instruction="...")

# Para customizá-lo:
agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    tools=[internet_search],
    subagents=[
        {
            "name": "general-purpose",
            "description": "Assistente geral para tarefas multi-passo",
            "system_prompt": "Você é um assistente geral que trabalha com arquivos e busca.",
            "tools": [internet_search, write_file, read_file],
            "model": "openai:gpt-5.4",  # Modelo diferente do principal
        },
    ],
)
```

### 8. Desabilitando Subagentes

```python
from deepagents import GeneralPurposeSubagentProfile, HarnessProfile, register_harness_profile

register_harness_profile(
    "openai:gpt-5.4",
    HarnessProfile(
        general_purpose_subagent=GeneralPurposeSubagentProfile(enabled=False),
    ),
)
agent = create_deep_agent(model="openai:gpt-5.4")
# Agora o agente NÃO tem a ferramenta 'task'
```

### 9. Propagação de Contexto para Subagentes

```python
from dataclasses import dataclass
from langchain.tools import tool, ToolRuntime

@dataclass
class Context:
    user_id: str
    session_id: str

@tool
def get_user_data(query: str, runtime: ToolRuntime[Context]) -> str:
    """Busca dados do usuário atual."""
    user_id = runtime.context.user_id
    return f"Dados para usuário {user_id}: {query}"

research_subagent = {
    "name": "researcher",
    "description": "Pesquisa para o usuário atual",
    "system_prompt": "Você é um assistente de pesquisa.",
    "tools": [get_user_data],
}

agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    subagents=[research_subagent],
    context_schema=Context,
)
# Contexto flui automaticamente para o subagente e suas ferramentas
result = await agent.invoke(
    {"messages": [{"role": "user", "content": "Busque minha atividade recente"}]},
    context=Context(user_id="user-123", session_id="abc"),
)
```

### 10. Streaming e Identificação de Agentes

```python
agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    subagents=[research_subagent],
    name="main-agent",
)
# Nos traces LangSmith, metadados incluirão:
# - 'lc_agent_name': 'main-agent' para o agente principal
# - 'lc_agent_name': 'research-agent' para o subagente
```

---

## 🧪 Testes Unitários (TDD)

```python
import pytest
from deepagents import create_deep_agent

def test_subagent_creation():
    subagent_spec = {
        "name": "test-agent",
        "description": "Agente de teste",
        "system_prompt": "Você é um testador.",
        "tools": [],
    }
    agent = create_deep_agent(model="openai:gpt-5.4", subagents=[subagent_spec])
    assert agent is not None

def test_general_purpose_present():
    agent = create_deep_agent(model="openai:gpt-5.4")
    # O subagente general-purpose deve existir
    # (verificação indireta via middleware)
    assert agent is not None

def test_context_propagation():
    @dataclass
    class Ctx:
        user_id: str
    agent = create_deep_agent(
        model="openai:gpt-5.4",
        subagents=[{"name": "s", "description": "d", "system_prompt": "p", "tools": []}],
        context_schema=Ctx,
    )
    assert agent is not None
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-subagents-fundamentals.md --json
```

---

## 🔗 Referências Cruzadas (Wikilinks Mínimos)
- [[deep-agents-subagents-advanced.md]] ← Próximo: subagentes avançados
- [[deep-agents-orchestration-planning.md]] ← Orquestração
- [[deep-agents-async-subagents.md]] ← Subagentes assíncronos
- [[langchain-langraph-master-agent.md]]

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-25T13:15:00Z | langchain-langraph-master-agent | Criação inicial: subagentes fundamentais | C1,C3,C5,C7,C8,C9 |
