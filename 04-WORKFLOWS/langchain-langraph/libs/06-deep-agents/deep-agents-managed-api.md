---
artifact_id: "deep-agents-managed-api"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-managed-api.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-managed-api.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-managed-api-v1.0.0"
generated_at: "2026-05-26T03:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-mcp-server-management", "deep-agents-streaming-managed", "deep-agents-threads-lifecycle"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-26"
---

# 🏭 Deep Agents – Managed Deep Agents API (LangSmith)

> **Contrato modular**: Artefato filho do Master Agent. Documenta a API REST completa de Managed Deep Agents no LangSmith: criação, leitura, atualização e exclusão de agentes gerenciados, estrutura canônica do projeto e versionamento via Context Hub.

---

## 🎯 Propósito
Permitir que o ecossistema MANTIS crie, opere e gerencie agentes profundos diretamente via API REST no LangSmith, sem necessidade de infraestrutura própria, com versionamento automático e integração nativa com tracing.

## 📋 Especificação (SDD)
- **Entradas**: Definição do agente (`AGENTS.md`, `skills/`, `subagents/`, `tools.json`), credenciais LangSmith.
- **Saídas**: Agente gerenciado criado, atualizado ou consultado via API.
- **Side Effects**: Criação de recursos no LangSmith (agentes, threads, runs).
- **Constraints Aplicáveis**: C1 (contrato REST), C2 (versionamento via Context Hub), C3 (proteção de API keys), C5 (schema de payload), C7 (retry em falhas HTTP), C8 (logs de operações), C9 (tracing automático).
- **Dependências**: `httpx`, `requests`, `langsmith`.

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

### 1. Configuração do Ambiente

```python
import os

LANGSMITH_API_KEY = os.getenv("LANGSMITH_API_KEY")
LANGSMITH_API_URL = os.getenv("LANGSMITH_API_URL", "https://api.smith.langchain.com")
DEEPAGENTS_BASE_URL = f"{LANGSMITH_API_URL}/v1/deepagents"
HEADERS = {"X-Api-Key": LANGSMITH_API_KEY, "Content-Type": "application/json"}
```

### 2. Estrutura Canônica do Projeto

```python
# Arquivos que definem um agente gerenciado:
# AGENTS.md       – instruções do agente
# skills/         – habilidades carregáveis sob demanda
# subagents/      – definições de subagentes para delegação
# tools.json      – configuração de ferramentas MCP e interrupt_config

# Exemplo de AGENTS.md
AGENTS_MD_EXAMPLE = """## Instruções
Você é um assistente de pesquisa cuidadoso. Busque fontes, mantenha notas
e retorne respostas concisas com citações.
"""
```

### 3. Criação de um Agente Gerenciado

```python
import httpx

def create_managed_agent(name, description, model_id, instructions, tools_config):
    response = httpx.post(
        f"{DEEPAGENTS_BASE_URL}/agents",
        headers=HEADERS,
        json={
            "name": name,
            "description": description,
            "runtime": {"model": {"model_id": model_id}},
            "instructions": instructions,
            "tools": tools_config,
        },
    )
    response.raise_for_status()
    agent_id = response.json()["id"]
    mantis_log("INFO", "agent_created", f"ID: {agent_id}, Nome: {name}")
    return agent_id

# Exemplo
tools_config = {
    "tools": [
        {
            "name": "tavily_search",
            "mcp_server_url": "https://mcp.tavily.com/mcp/",
            "mcp_server_name": "tavily",
            "display_name": "tavily_search",
        }
    ],
    "interrupt_config": {
        "https://mcp.tavily.com/mcp/::tavily_search::tavily": False
    },
}

agent_id = create_managed_agent(
    name="research-assistant",
    description="Assistente de pesquisa que busca na web e resume fontes.",
    model_id="anthropic:claude-sonnet-4-6",
    instructions=AGENTS_MD_EXAMPLE,
    tools_config=tools_config,
)
```

### 4. Consulta de Agentes

```python
def list_agents():
    response = httpx.get(f"{DEEPAGENTS_BASE_URL}/agents", headers=HEADERS)
    response.raise_for_status()
    agents = response.json()
    mantis_log("INFO", "agents_listed", f"Total: {len(agents)}")
    return agents

def get_agent(agent_id):
    response = httpx.get(f"{DEEPAGENTS_BASE_URL}/agents/{agent_id}", headers=HEADERS)
    response.raise_for_status()
    agent = response.json()
    mantis_log("INFO", "agent_retrieved", f"ID: {agent_id}")
    return agent
```

### 5. Atualização de um Agente

```python
def update_agent(agent_id, description, model_id, instructions, tools_config):
    response = httpx.patch(
        f"{DEEPAGENTS_BASE_URL}/agents/{agent_id}",
        headers=HEADERS,
        json={
            "description": description,
            "runtime": {"model": {"model_id": model_id}},
            "instructions": instructions,
            "tools": tools_config,
        },
    )
    response.raise_for_status()
    mantis_log("INFO", "agent_updated", f"ID: {agent_id}")
    return response.json()
```

### 6. Exclusão de um Agente

```python
def delete_agent(agent_id):
    response = httpx.delete(f"{DEEPAGENTS_BASE_URL}/agents/{agent_id}", headers=HEADERS)
    response.raise_for_status()
    mantis_log("WARN", "agent_deleted", f"ID: {agent_id}")
```

### 7. Criação de Thread

```python
def create_thread(agent_id, test_run=False, skip_memory_protection=False):
    response = httpx.post(
        f"{DEEPAGENTS_BASE_URL}/threads",
        headers=HEADERS,
        json={
            "agent_id": agent_id,
            "options": {
                "test_run": test_run,
                "skip_memory_write_protection": skip_memory_protection,
            },
        },
    )
    response.raise_for_status()
    thread_id = response.json()["id"]
    mantis_log("INFO", "thread_created", f"Thread: {thread_id}, Agent: {agent_id}")
    return thread_id
```

### 8. Execução de um Run com Streaming

```python
def stream_run(thread_id, agent_id, messages, stream_modes=None):
    if stream_modes is None:
        stream_modes = ["values", "updates", "messages-tuple"]
    with httpx.stream(
        "POST",
        f"{DEEPAGENTS_BASE_URL}/threads/{thread_id}/runs/stream",
        headers={**HEADERS, "Accept": "text/event-stream"},
        json={
            "agent_id": agent_id,
            "messages": messages,
            "stream_mode": stream_modes,
            "stream_subgraphs": True,
        },
        timeout=None,
    ) as response:
        response.raise_for_status()
        for line in response.iter_lines():
            if line:
                yield line
```

### 9. Cliente Completo com Retry e Logging

```python
from tenacity import retry, stop_after_attempt, wait_exponential

class ManagedDeepAgentsClient:
    def __init__(self, api_key=None, base_url=None):
        self.api_key = api_key or os.getenv("LANGSMITH_API_KEY")
        self.base_url = base_url or "https://api.smith.langchain.com/v1/deepagents"
        self.headers = {"X-Api-Key": self.api_key, "Content-Type": "application/json"}

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(min=1, max=10))
    def _request(self, method, path, **kwargs):
        response = httpx.request(method, f"{self.base_url}{path}", headers=self.headers, **kwargs)
        response.raise_for_status()
        return response.json()

    def create_agent(self, name, description, model_id, instructions, tools_config):
        return self._request("POST", "/agents", json={
            "name": name,
            "description": description,
            "runtime": {"model": {"model_id": model_id}},
            "instructions": instructions,
            "tools": tools_config,
        })

    def get_agent(self, agent_id):
        return self._request("GET", f"/agents/{agent_id}")

    def list_agents(self):
        return self._request("GET", "/agents")

    def update_agent(self, agent_id, **kwargs):
        return self._request("PATCH", f"/agents/{agent_id}", json=kwargs)

    def delete_agent(self, agent_id):
        self._request("DELETE", f"/agents/{agent_id}")

    def create_thread(self, agent_id):
        return self._request("POST", "/threads", json={"agent_id": agent_id})

    def stream_run(self, thread_id, agent_id, messages):
        return stream_run(thread_id, agent_id, messages)
```

### 10. Versionamento Automático (Context Hub)

```python
# Cada criação ou atualização de agente gera um novo commit no Context Hub.
# O campo 'revision' na resposta contém o hash do commit.
# Para acessar o histórico de versões:
def get_agent_revisions(agent_id):
    agent = get_agent(agent_id)
    revision = agent.get("revision")
    mantis_log("INFO", "agent_revision", f"ID: {agent_id}, Revision: {revision}")
    return revision
```

---

## 🧪 Testes Unitários (TDD)

```python
import pytest
from unittest.mock import patch

def test_create_agent_payload():
    payload = {
        "name": "test-agent",
        "runtime": {"model": {"model_id": "openai:gpt-5.4"}},
        "instructions": "Test instructions",
        "tools": {"tools": [], "interrupt_config": {}},
    }
    assert "name" in payload
    assert "runtime" in payload

@patch('httpx.post')
def test_create_managed_agent(mock_post):
    mock_post.return_value.status_code = 200
    mock_post.return_value.json.return_value = {"id": "agent-123"}
    agent_id = create_managed_agent(
        "test", "desc", "openai:gpt-5.4", "instructions", {"tools": [], "interrupt_config": {}}
    )
    assert agent_id == "agent-123"
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-managed-api.md --json
```

---

## 🔗 Referências Cruzadas
- [[deep-agents-mcp-server-management.md]]
- [[deep-agents-streaming-managed.md]]
- [[deep-agents-threads-lifecycle.md]]
- [[langchain-langraph-master-agent.md]]

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-26T03:00:00Z | langchain-langraph-master-agent | Criação inicial: Managed Deep Agents API | C1,C2,C3,C5,C7,C8,C9 |
