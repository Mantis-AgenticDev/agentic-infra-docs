---
artifact_id: "deep-agents-async-subagents"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-async-subagents.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-async-subagents.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-async-subagents-v1.0.0"
generated_at: "2026-05-25T14:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-subagents-fundamentals", "deep-agents-backends-overview"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🧩 Deep Agents – Subagentes Assíncronos

> **Contrato modular**: Artefato filho do Master Agent. Documenta subagentes assíncronos com `AsyncSubAgent`, gerenciamento de tarefas em background, transporte ASGI/HTTP e ciclo de vida completo.

---

## 🎯 Propósito
Permitir que agentes MANTIS lancem tarefas em background que executam concorrentemente, com capacidade de verificar progresso, enviar instruções e cancelar.

## 📋 Especificação (SDD)
- **Entradas**: Especificação `AsyncSubAgent`, Agent Protocol server.
- **Saídas**: Ferramentas de gerenciamento assíncrono (start, check, update, cancel, list).
- **Side Effects**: Threads isoladas no servidor Agent Protocol.
- **Constraints Aplicáveis**: C1 (contrato de ferramentas), C3 (isolamento), C5 (schema de estado), C7 (resiliência), C8 (tracing), C9 (thread_id).
- **Dependências**: `deepagents>=0.5.0`, `langgraph-sdk`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    import json, datetime, os
    def mantis_log(level, event, detail=""):
        entry = {"ts": datetime.datetime.utcnow().isoformat() + "Z", "level": level, "tenant": os.getenv("TENANT_ID", "global"), "event": event, "detail": detail, "trace_id": os.getenv("TRACE_ID", "null"), "span_id": os.getenv("SPAN_ID", "null"), "fallback": "true"}
        print(json.dumps(entry), flush=True)
```

### 1. Configuração de Subagentes Assíncronos

```python
from deepagents import AsyncSubAgent, create_deep_agent

async_subagents = [
    AsyncSubAgent(
        name="researcher",
        description="Agente de pesquisa para coleta e síntese de informações",
        graph_id="researcher",
    ),
    AsyncSubAgent(
        name="coder",
        description="Agente de codificação para geração e revisão de código",
        graph_id="coder",
        url="https://coder-deployment.langsmith.dev",  # Remoto
    ),
]

agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    subagents=async_subagents,
)
```

### 2. Registro de Grafos no `langgraph.json`

```json
{
  "graphs": {
    "supervisor": "./src/supervisor.py:graph",
    "researcher": "./src/researcher.py:graph",
    "coder": "./src/coder.py:graph"
  }
}
```

### 3. Ferramentas de Gerenciamento Assíncrono

```python
# O AsyncSubAgentMiddleware expõe 5 ferramentas:
# - start_async_task: Inicia uma nova tarefa em background → retorna task_id
# - check_async_task: Verifica status e resultado de uma tarefa
# - update_async_task: Envia novas instruções para uma tarefa em execução
# - cancel_async_task: Cancela uma tarefa em execução
# - list_async_tasks: Lista todas as tarefas rastreadas

config = {"configurable": {"thread_id": "supervisor-session-1"}}

# Supervisor lança tarefa
result = agent.invoke({
    "messages": [{"role": "user", "content": "Pesquise sobre computação quântica e me avise quando terminar."}]
}, config=config)
# Retorna imediatamente com um task_id

# Usuário verifica depois
result = agent.invoke({
    "messages": [{"role": "user", "content": "Como está a pesquisa?"}]
}, config=config)
# Agente chama check_async_task(task_id) e reporta status
```

### 4. Ciclo de Vida Completo

```python
# 1. LAUNCH: start_async_task(agent="researcher", instruction="Pesquisar tópico X")
# Retorna: task_id = "abc123"

# 2. CHECK: check_async_task(task_id="abc123")
# Retorna: {"status": "running"} ou {"status": "success", "result": "..."}

# 3. UPDATE: update_async_task(task_id="abc123", instruction="Adicione foco em aplicações práticas")
# Retorna: confirmação + status atualizado

# 4. CANCEL: cancel_async_task(task_id="abc123")
# Retorna: confirmação de cancelamento

# 5. LIST: list_async_tasks()
# Retorna: todas as tarefas com seus status atuais
```

### 5. Transporte ASGI (Co‑deploy)

```python
async_subagents = [
    AsyncSubAgent(
        name="researcher",
        description="Agente de pesquisa",
        graph_id="researcher",
        # Sem url → usa ASGI (co-deploy)
    ),
]
# Ambos os grafos devem estar no mesmo langgraph.json
```

### 6. Transporte HTTP (Remoto)

```python
async_subagents = [
    AsyncSubAgent(
        name="coder",
        description="Agente de codificação remoto",
        graph_id="coder",
        url="https://coder-deployment.langsmith.dev",
        headers={"X-Custom-Auth": "token-xyz"},  # Headers customizados
    ),
]
```

### 7. Topologia de Deploy Híbrida

```python
async_subagents = [
    AsyncSubAgent(
        name="researcher",
        description="Pesquisador local",
        graph_id="researcher",
        # ASGI (co-deploy)
    ),
    AsyncSubAgent(
        name="coder",
        description="Codificador remoto",
        graph_id="coder",
        url="https://coder-deployment.langsmith.dev",
        # HTTP (remoto)
    ),
]
```

### 8. Gerenciamento de Estado das Tarefas

```python
# O estado das tarefas assíncronas é armazenado em um canal dedicado (async_tasks)
# Isso garante que os task_ids sobrevivam à sumarização de contexto.

# Cada tarefa registra:
# - task_id
# - agent_name
# - thread_id
# - run_id
# - status (pending, running, success, error, cancelled)
# - created_at, last_checked_at, last_updated_at
```

### 9. Tamanho do Worker Pool (Desenvolvimento Local)

```bash
# Aumentar pool para acomodar subagentes concorrentes
langgraph dev --n-jobs-per-worker 10
# 1 supervisor + 3 subagentes = 4 slots mínimos
```

### 10. Troubleshooting: Polling Imediato Após Launch

```python
# Solução: reforçar no system prompt
agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    system_prompt="""...suas instruções...
    Após lançar um subagente assíncrono, SEMPRE retorne o controle ao usuário.
    Nunca chame check_async_task imediatamente após o launch.""",
    subagents=async_subagents,
)
```

### 11. Troubleshooting: Status Desatualizado

```python
# O middleware instrui o modelo que "status de tarefas no histórico estão sempre desatualizados"
# Se ainda ocorrer, adicione:
system_prompt += "Sempre chame check_async_task ou list_async_tasks antes de reportar o status de qualquer tarefa."
```

### 12. Correlação de Traces

```python
# Cada subagente assíncrono gera seu próprio trace no LangSmith.
# O trace do supervisor mostra chamadas para launch, check, update, cancel, list.
# Os traces são vinculados pelo thread_id (task_id).
# Use o task_id para correlacionar traces do supervisor com traces do subagente.
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_async_subagent_spec():
    spec = AsyncSubAgent(
        name="test-agent",
        description="Test agent",
        graph_id="test-graph",
    )
    assert spec.name == "test-agent"
    assert spec.graph_id == "test-graph"

def test_async_subagent_with_url():
    spec = AsyncSubAgent(
        name="remote-agent",
        description="Remote agent",
        graph_id="remote-graph",
        url="https://example.com/deploy",
    )
    assert spec.url == "https://example.com/deploy"
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-async-subagents.md --json
```

---

## 🔗 Referências Cruzadas (Wikilinks Mínimos)
- [[deep-agents-subagents-fundamentals.md]]
- [[deep-agents-backends-overview.md]]
- [[langchain-langraph-master-agent.md]]

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-25T14:00:00Z | langchain-langraph-master-agent | Criação inicial: subagentes assíncronos | C1,C3,C5,C7,C8,C9 |
