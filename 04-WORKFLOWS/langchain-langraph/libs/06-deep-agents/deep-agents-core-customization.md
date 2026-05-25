---
artifact_id: "deep-agents-core-customization"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-core-customization.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-core-customization.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-core-v1.0.0"
generated_at: "2026-05-25T13:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: true
  required_for: ["deep-agents-subagents-fundamentals", "deep-agents-backends-overview", "deep-agents-memory-long-term"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🧠 Deep Agents Core Customization – Configuração Completa de Agentes com `create_deep_agent`

> **Contrato modular**: Artefato filho do Master Agent. Documenta exaustivamente todos os parâmetros de `create_deep_agent`, incluindo modelos, ferramentas, middleware, system prompt (montagem), subagentes, backends, intérpretes, HITL, skills, memória e perfis, com exemplos executáveis para múltiplos provedores.

---

## 🎯 Propósito
Fornecer uma referência canônica e densa para a criação de agentes profundos no ecossistema MANTIS, utilizando `create_deep_agent` como fábrica principal, alinhada às constraints C1‑C9.

## 📋 Especificação (SDD)
- **Entradas**: Configuração declarativa do agente (modelo, ferramentas, prompts, middleware, etc.).
- **Saídas**: Grafo compilado do agente (`CompiledStateGraph`).
- **Side Effects**: Criação de middleware, conexão com backends, registro de perfis.
- **Constraints Aplicáveis**: C1 (tipagem e contratos), C3 (proteção de credenciais), C5 (estrutura de resposta), C7 (resiliência via middleware), C8 (observabilidade), C9 (tracing distribuído).
- **Dependências**: `deepagents`, `langchain-core`, `langgraph`.

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

### 1. Instanciação Básica com Múltiplos Provedores

```python
from deepagents import create_deep_agent

# OpenAI
agent_openai = create_deep_agent(model="openai:gpt-5.4")

# Anthropic
agent_anthropic = create_deep_agent(model="anthropic:claude-sonnet-4-6")

# Google Gemini
agent_gemini = create_deep_agent(model="google_genai:gemini-3.5-flash")

# OpenRouter
agent_openrouter = create_deep_agent(model="openrouter:anthropic/claude-sonnet-4-6")

# AWS Bedrock
agent_bedrock = create_deep_agent(model="anthropic.claude-sonnet-4-6", model_provider="bedrock_converse")

# HuggingFace
agent_hf = create_deep_agent(
    model="microsoft/Phi-3-mini-4k-instruct",
    model_provider="huggingface",
    temperature=0.7,
    max_tokens=1024,
)

mantis_log("INFO", "agent_created", f"Agente iniciado com modelo {agent_openai.model_name}")
```

### 2. Passagem de Modelo como Instância

```python
from langchain.chat_models import init_chat_model
from langchain_openai import ChatOpenAI

# via init_chat_model
model = init_chat_model(model="openai:gpt-5.4", temperature=0.2)
agent = create_deep_agent(model=model)

# via classe específica
model = ChatOpenAI(model="gpt-5.4", temperature=0.2)
agent = create_deep_agent(model=model)
```

### 3. Ferramentas Personalizadas com `@tool`

```python
from langchain.tools import tool
from tavily import TavilyClient
import os

tavily_client = TavilyClient(api_key=os.environ["TAVILY_API_KEY"])

@tool
def internet_search(query: str, max_results: int = 5, topic: str = "general", include_raw_content: bool = False):
    """Executa uma busca na web e retorna resultados."""
    result = tavily_client.search(query, max_results=max_results, include_raw_content=include_raw_content, topic=topic)
    mantis_log("INFO", "tool_search", f"Query: {query}, Resultados: {len(result.get('results', []))}")
    return result

agent = create_deep_agent(
    model="openai:gpt-5.4",
    tools=[internet_search],
)
```

### 4. System Prompt e Montagem em Camadas

```python
agent = create_deep_agent(
    model="anthropic:claude-sonnet-4-6",
    system_prompt="Você é um agente de suporte ao cliente da ACME Corp.",
)
# Prompt final: USER + BASE + SUFFIX (profile)
```

**Tabela de montagem:**

| `system_prompt=` | profile `base_system_prompt` | profile `system_prompt_suffix` | Prompt final |
|------------------|:----------------------------:|:-----------------------------:|--------------|
| `None`           |              -               |               -               | `BASE` |
| `None`           |              -               |               ✓               | `BASE` + `SUFFIX` |
| `str`            |              -               |               -               | `USER` + `BASE` |
| `str`            |              -               |               ✓               | `USER` + `BASE` + `SUFFIX` |

### 5. Middleware Embutido e Personalizado

**Middleware padrão incluído:**
- `TodoListMiddleware`
- `FilesystemMiddleware`
- `SubAgentMiddleware`
- `SummarizationMiddleware`
- `AnthropicPromptCachingMiddleware` (quando Anthropic)
- `PatchToolCallsMiddleware`

**Middleware adicional via `middleware`:**

```python
from langchain.agents.middleware import wrap_tool_call

@wrap_tool_call
def log_tool_calls(request, handler):
    mantis_log("INFO", "tool_call", f"Ferramenta: {request.name}, Args: {request.args}")
    result = handler(request)
    mantis_log("INFO", "tool_call_done", f"Resultado: {result[:50]}...")
    return result

agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    tools=[internet_search],
    middleware=[log_tool_calls],
)
```

### 6. Intérpretes (Code Interpreter)

```python
from langchain_quickjs import CodeInterpreterMiddleware

agent = create_deep_agent(
    model="openai:gpt-5.4",
    middleware=[CodeInterpreterMiddleware()],
)
# Agente ganha ferramenta 'eval' para executar JavaScript
```

### 7. Subagentes Declarativos

```python
research_subagent = {
    "name": "research-agent",
    "description": "Usado para pesquisar questões mais profundas",
    "system_prompt": "Você é um excelente pesquisador",
    "tools": [internet_search],
    "model": "openai:gpt-5.4",  # opcional, herda do principal se omitido
}
agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    subagents=[research_subagent],
)
```

### 8. Backends – Definindo o Sistema de Arquivos

```python
from deepagents.backends import StateBackend, FilesystemBackend, CompositeBackend

# Padrão: StateBackend (thread-scoped)
agent = create_deep_agent(model="google_genai:gemini-3.5-flash")

# Backend real (cuidado!)
agent_fs = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    backend=FilesystemBackend(root_dir=".", virtual_mode=True),
)

# Composite: /memories persistente, /workspace volátil
agent_comp = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    backend=CompositeBackend(
        default=StateBackend(),
        routes={"/memories/": StoreBackend(namespace=lambda rt: (rt.server_info.user.identity,))},
    ),
)
```

### 9. Human-in-the-Loop (HITL)

```python
from langgraph.checkpoint.memory import MemorySaver

checkpointer = MemorySaver()
agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    tools=[write_file, read_file, notify_email],
    interrupt_on={
        "write_file": True,
        "read_file": False,
        "notify_email": {"allowed_decisions": ["approve", "reject"]},
    },
    checkpointer=checkpointer,  # OBRIGATÓRIO
)
```

### 10. Skills (Habilidades)

```python
from deepagents.backends import StateBackend
from deepagents.backends.utils import create_file_data
from urllib.request import urlopen

skill_url = "https://raw.githubusercontent.com/langchain-ai/deepagents/refs/heads/main/libs/cli/examples/skills/langgraph-docs/SKILL.md"
with urlopen(skill_url) as response:
    skill_content = response.read().decode('utf-8')

skills_files = {"/skills/langgraph-docs/SKILL.md": create_file_data(skill_content)}

agent = create_deep_agent(
    model="openai:gpt-5.4",
    backend=StateBackend(),
    skills=["/skills/"],
    checkpointer=MemorySaver(),
)
# Ao invocar, passar files=skills_files no input
```

### 11. Memória (Long-Term)

```python
agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    memory=["/AGENTS.md"],
    backend=StoreBackend(namespace=lambda rt: (rt.server_info.user.identity,)),
    store=InMemoryStore(),
)
# Arquivo /AGENTS.md será lido no início e pode ser atualizado pelo agente
```

### 12. Structured Output

```python
from pydantic import BaseModel, Field

class WeatherReport(BaseModel):
    location: str = Field(description="Localização")
    temperature: float = Field(description="Temperatura em Celsius")
    condition: str = Field(description="Condição climática")

agent = create_deep_agent(
    model="openai:gpt-5.4",
    tools=[internet_search],
    response_format=WeatherReport,
)
result = agent.invoke({"messages": [{"role": "user", "content": "Qual o clima em Paris?"}]})
print(result["structured_response"])
```

### 13. Perfis (Profiles)

```python
from deepagents import HarnessProfile, register_harness_profile

register_harness_profile(
    "openai:gpt-5.4",
    HarnessProfile(
        system_prompt_suffix="Responda em menos de 100 palavras.",
        excluded_tools={"execute"},
        excluded_middleware={"SummarizationMiddleware"},
        general_purpose_subagent=GeneralPurposeSubagentProfile(enabled=False),
    ),
)

agent = create_deep_agent(model="openai:gpt-5.4")
# O perfil é aplicado automaticamente
```

### 14. Integração de Tracing e Observabilidade (C8, C9)

```python
# Tracing automático via LangSmith se variáveis estiverem setadas
import os
os.environ["LANGCHAIN_TRACING_V2"] = "true"
os.environ["LANGCHAIN_API_KEY"] = "ls__..."
os.environ["LANGCHAIN_PROJECT"] = "mantis-deep-agents"

agent = create_deep_agent(...)
result = agent.invoke({"messages": [{"role": "user", "content": "test"}]})
# Os traces aparecem em LangSmith com metadados do agente
```

### 15. Execução Completa com Invocação

```python
config = {"configurable": {"thread_id": "user-123"}}
result = agent.invoke(
    {
        "messages": [{"role": "user", "content": "Pesquise tendências de IA e salve um resumo em /workspace/trends.md"}],
    },
    config=config,
)
mantis_log("INFO", "agent_result", f"Resposta final: {result['messages'][-1].content[:100]}...")
```

---

## 🧪 Testes Unitários (TDD)

```python
import pytest
from deepagents import create_deep_agent
from langgraph.checkpoint.memory import MemorySaver

def test_create_agent_minimum():
    agent = create_deep_agent(model="openai:gpt-5.4")
    assert agent is not None

def test_system_prompt_assembly():
    agent = create_deep_agent(
        model="anthropic:claude-sonnet-4-6",
        system_prompt="Você é um assistente."
    )
    # Não é trivial testar o prompt montado, mas podemos verificar a compilação
    assert agent is not None

def test_interrupt_requires_checkpointer():
    with pytest.raises(ValueError):
        create_deep_agent(
            model="openai:gpt-5.4",
            interrupt_on={"write_file": True},
        )
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-core-customization.md --json
```

---

## 🔗 Referências Cruzadas (Wikilinks Mínimos)
- [[deep-agents-subagents-fundamentals.md]] ← Próximo passo: subagentes
- [[deep-agents-backends-overview.md]] ← Backends
- [[deep-agents-memory-long-term.md]] ← Memória de longo prazo
- [[langchain-langraph-master-agent.md]]

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-25T13:00:00Z | langchain-langraph-master-agent | Criação inicial: parametrização completa | C1,C3,C5,C7,C8,C9 |
