---
artifact_id: "deep-agents-deployment-production"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-deployment-production.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-deployment-production.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-deployment-production-v1.0.0"
generated_at: "2026-05-25T19:15:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-core-customization"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🚀 Deep Agents – Deploy em Produção (LangSmith Deployment)

> **Contrato modular**: Artefato filho do Master Agent. Guia para implantar Deep Agents em produção usando LangSmith Deployment, com configuração de `langgraph.json`, variáveis de ambiente, cron jobs e isolamento multi‑tenant.

---

## 🎯 Propósito
Permitir que agentes MANTIS sejam implantados em ambiente de produção gerenciado, com escalabilidade, observabilidade e segurança.

## 📋 Especificação (SDD)
- **Entradas**: Arquivo `langgraph.json`, variáveis de ambiente, store configurado.
- **Saídas**: Agente acessível via API.
- **Side Effects**: Deploy no LangSmith.
- **Constraints Aplicáveis**: C1 (schema de deploy), C2 (versionamento), C3 (segredos), C4 (multi‑tenant), C5 (configuração), C7 (resiliência), C8 (logs), C9 (tracing).
- **Dependências**: `langgraph-sdk`, `langsmith`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Estrutura de `langgraph.json`

```json
{
  "dependencies": ["."],
  "graphs": {
    "agent": "./agent.py:agent",
    "consolidation_agent": "./consolidation_agent.py:agent"
  },
  "env": ".env"
}
```

### 2. Script do Agente (`agent.py`)

```python
from deepagents import create_deep_agent
from deepagents.backends import CompositeBackend, StateBackend, StoreBackend
from langgraph.store.memory import InMemoryStore

agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    memory=["/memories/AGENTS.md"],
    backend=CompositeBackend(
        default=StateBackend(),
        routes={
            "/memories/": StoreBackend(namespace=lambda rt: (rt.server_info.user.identity,)),
        },
    ),
    # store é injetado automaticamente pela plataforma
)
```

### 3. Variáveis de Ambiente

```bash
LANGSMITH_API_KEY=ls__...
LANGSMITH_PROJECT=mantis-agentic
GOOGLE_API_KEY=...
OPENAI_API_KEY=...
```

### 4. Deploy via LangSmith CLI

```bash
pip install -U langsmith-cli
langsmith deploy
```

### 5. Invocação do Agente Deployado

```python
from langgraph_sdk import get_client

client = get_client(url="<DEPLOYMENT_URL>")
thread = await client.threads.create()
await client.runs.create(
    thread_id=thread["thread_id"],
    assistant_id="agent",
    input={"messages": [{"role": "user", "content": "Hello"}]},
)
```

### 6. Configuração de Cron Jobs

```python
cron_job = await client.crons.create(
    assistant_id="consolidation_agent",
    schedule="0 */6 * * *",
    input={"messages": [{"role": "user", "content": "Consolidate recent memories."}]},
)
```

### 7. Autenticação Multi‑Usuário

```python
StoreBackend(
    namespace=lambda rt: (rt.server_info.user.identity,),
)
# rt.server_info.user.identity é preenchido automaticamente com o usuário autenticado.
```

### 8. Isolamento de Organização

```python
StoreBackend(
    namespace=lambda rt: (rt.context.org_id, rt.server_info.user.identity),
)
```

### 9. Escalabilidade

- O LangSmith gerencia automaticamente a escalabilidade dos workers.
- Para desenvolvimento local, ajustar `--n-jobs-per-worker`.

### 10. Monitoramento e Tracing

- Tracing automático via LangSmith.
- Métricas de latência, tokens e erros disponíveis no dashboard.

---

## 🧪 Testes Unitários (TDD)

```python
def test_deploy_config():
    config = {"graphs": {"agent": "./agent.py:agent"}}
    assert "agent" in config["graphs"]
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-deployment-production.md --json
```

---

## 🔗 Referências Cruzadas
- [[deep-agents-core-customization.md]]
