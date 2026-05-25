---
artifact_id: "deep-agents-advanced-orchestration"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-advanced-orchestration.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-advanced-orchestration.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-advanced-orchestration-v1.0.0"
generated_at: "2026-05-25T20:45:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-subagents-fundamentals", "deep-agents-async-subagents"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🧠 Deep Agents – Orquestração Avançada (Swarm, Hierarquia, Eventos)

> **Contrato modular**: Artefato filho do Master Agent. Explora padrões avançados de orquestração com múltiplos agentes: swarm, hierarquia, pipelines, eventos e coordenação com A2A.

---

## 🎯 Propósito
Permitir que agentes MANTIS coordenem múltiplos subagentes em padrões complexos, incluindo arquiteturas swarm, pipelines de processamento e coordenação baseada em eventos.

## 📋 Especificação (SDD)
- **Entradas**: Definições de subagentes, orquestrador.
- **Saídas**: Sistema multi‑agente coordenado.
- **Side Effects**: Execução paralela e distribuída.
- **Constraints Aplicáveis**: C1 (contrato de coordenação), C5 (schema de comunicação), C7 (tolerância a falhas), C8 (tracing), C9 (trace_id).
- **Dependências**: `deepagents`, `langgraph`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Padrão Supervisor‑Worker

```python
subagents = [
    {"name": "researcher", "description": "Pesquisador", "system_prompt": "Pesquise e retorne dados.", "tools": [web_search]},
    {"name": "analyst", "description": "Analista", "system_prompt": "Analise dados e gere insights.", "tools": [analyze_data]},
    {"name": "writer", "description": "Escritor", "system_prompt": "Escreva relatórios.", "tools": [write_file]},
]

agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    system_prompt="""Você é um supervisor. Para cada tarefa:
    1. Delegue pesquisa ao researcher.
    2. Passe resultados para o analyst.
    3. Envie insights para o writer.
    Coordene as dependências.""",
    subagents=subagents,
)
```

### 2. Padrão Pipeline (Encadeamento)

```python
# Define uma sequência fixa de subagentes
pipeline_agent = create_deep_agent(
    model="anthropic:claude-sonnet-4-6",
    system_prompt="""Execute as etapas em ordem:
    1. task(agent='collector', instruction='...')
    2. task(agent='processor', instruction='...')
    3. task(agent='validator', instruction='...')
    Cada etapa depende do resultado da anterior.""",
    subagents=[...],
)
```

### 3. Padrão Swarm (Paralelo)

```python
# Subagentes assíncronos para execução paralela
async_subagents = [
    AsyncSubAgent(name="researcher-1", description="Pesquisador 1", graph_id="researcher"),
    AsyncSubAgent(name="researcher-2", description="Pesquisador 2", graph_id="researcher"),
    AsyncSubAgent(name="analyst", description="Analista", graph_id="analyst"),
]

swarm_agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    system_prompt="""Divida tarefas grandes em subtarefas.
    Lance múltiplos pesquisadores em paralelo.
    Consolide resultados com o analyst.""",
    subagents=async_subagents,
)
```

### 4. Coordenação com Eventos (Pub/Sub)

```python
# Usando Redis para notificar agentes
import redis.asyncio as redis

@tool
async def notify_agent(agent_name: str, message: str) -> str:
    r = redis.Redis()
    await r.publish(f"agent:{agent_name}", message)
    return f"Notificação enviada para {agent_name}"

@tool
async def wait_for_event(event_type: str, timeout: int = 30) -> str:
    r = redis.Redis()
    pubsub = r.pubsub()
    await pubsub.subscribe(f"events:{event_type}")
    # Aguarda mensagem com timeout
    return "Evento recebido"
```

### 5. Protocolo A2A (Agent‑to‑Agent)

```python
# Definir um protocolo de handoff entre agentes
A2A_HANDOFF_SCHEMA = {
    "agent_from": "string",
    "agent_to": "string",
    "task_id": "string",
    "trace_id": "string",
    "span_id": "string",
    "payload": "dict",
}

@tool
def handoff_to_agent(target_agent: str, task: str, trace_id: str) -> str:
    """Passa o controle para outro agente."""
    payload = {
        "agent_from": "supervisor",
        "agent_to": target_agent,
        "task": task,
        "trace_id": trace_id,
        "timestamp": datetime.datetime.utcnow().isoformat(),
    }
    mantis_log("INFO", "a2a_handoff", json.dumps(payload))
    return json.dumps(payload)
```

### 6. Tolerância a Falhas no Swarm

```python
system_prompt="""Se um subagente falhar:
1. Registre o erro.
2. Tente novamente com um subagente alternativo.
3. Se todos falharem, reporte ao usuário com o diagnóstico."""
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_supervisor_creation():
    agent = create_deep_agent(
        model="openai:gpt-5.4",
        subagents=[{"name": "w", "description": "d", "system_prompt": "p", "tools": []}],
    )
    assert agent is not None
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-advanced-orchestration.md --json
```

---

## 🔗 Referências Cruzadas
- [[deep-agents-subagents-fundamentals.md]]
- [[deep-agents-async-subagents.md]]
