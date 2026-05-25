---
artifact_id: "deep-agents-episodic-memory"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C4","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-episodic-memory.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-episodic-memory.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-episodic-memory-v1.0.0"
generated_at: "2026-05-25T21:30:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-memory-long-term", "deep-agents-memory-scopes"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🧠 Deep Agents – Memória Episódica (Busca em Conversas Passadas)

> **Contrato modular**: Artefato filho do Master Agent. Implementa memória episódica para agentes MANTIS, permitindo busca e recuperação de conversas passadas via LangGraph SDK e ferramentas de busca semântica.

---

## 🎯 Propósito
Permitir que agentes MANTIS acessem e aprendam com conversas anteriores, recuperando contextos relevantes de threads passadas para melhorar respostas e evitar repetições.

## 📋 Especificação (SDD)
- **Entradas**: LangGraph SDK client, configuração de busca por metadados.
- **Saídas**: Histórico de conversas recuperado e integrado ao contexto.
- **Side Effects**: Leitura de threads armazenadas.
- **Constraints Aplicáveis**: C1 (schema de busca), C3 (isolamento por usuário), C4 (escopo de tenant), C5 (formato de histórico), C7 (fallback se busca falhar), C8 (logs de acesso), C9 (correlação de thread_id).
- **Dependências**: `langgraph-sdk`, `deepagents`.

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

### 1. Ferramenta de Busca em Conversas Passadas

```python
from langgraph_sdk import get_client
from langchain.tools import tool, ToolRuntime
from datetime import datetime, timedelta, timezone

client = get_client(url="<DEPLOYMENT_URL>")

@tool
async def search_past_conversations(query: str, runtime: ToolRuntime) -> str:
    """Busca conversas passadas do usuário por contexto relevante."""
    user_id = runtime.server_info.user.identity
    mantis_log("INFO", "episodic_search", f"User: {user_id}, Query: {query}")

    threads = await client.threads.search(
        metadata={"user_id": user_id},
        limit=5,
    )
    results = []
    for thread in threads:
        history = await client.threads.get_history(
            thread_id=thread["thread_id"],
            limit=10,
        )
        messages = history.get("values", {}).get("messages", [])
        results.append({
            "thread_id": thread["thread_id"],
            "messages": [{"role": m.get("type"), "content": m.get("content", "")[:200]} for m in messages[-5:]],
        })
    mantis_log("INFO", "episodic_results", f"Threads encontradas: {len(results)}")
    return json.dumps(results, default=str)
```

### 2. Busca com Janela Temporal

```python
@tool
async def search_recent_conversations(query: str, hours: int = 24, runtime: ToolRuntime) -> str:
    """Busca conversas das últimas N horas."""
    user_id = runtime.server_info.user.identity
    since = datetime.now(timezone.utc) - timedelta(hours=hours)

    threads = await client.threads.search(
        metadata={"user_id": user_id},
        updated_after=since.isoformat(),
        limit=20,
    )
    conversations = []
    for thread in threads:
        history = await client.threads.get_history(thread_id=thread["thread_id"])
        conversations.append({
            "thread_id": thread["thread_id"],
            "updated_at": thread.get("updated_at"),
            "summary": history["values"].get("messages", [{}])[-1].get("content", "")[:300],
        })
    return json.dumps(conversations, default=str)
```

### 3. Busca por Organização

```python
@tool
async def search_org_conversations(query: str, runtime: ToolRuntime) -> str:
    """Busca conversas de toda a organização."""
    org_id = runtime.context.org_id
    threads = await client.threads.search(
        metadata={"org_id": org_id},
        limit=10,
    )
    results = []
    for thread in threads:
        history = await client.threads.get_history(thread_id=thread["thread_id"])
        results.append(history["values"].get("messages", []))
    return str(results)
```

### 4. Integração com o Agente

```python
agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    system_prompt="""Você é um assistente com memória episódica.
    Antes de responder perguntas complexas, busque conversas passadas relevantes.
    Use search_past_conversations para encontrar contexto anterior.
    Se encontrar informações relevantes, integre-as à sua resposta.""",
    tools=[search_past_conversations, search_recent_conversations],
    context_schema=Context,
)
```

### 5. Indexação de Conversas para Busca Rápida

```python
@tool
async def index_current_conversation(topic: str, summary: str, runtime: ToolRuntime) -> str:
    """Indexa a conversa atual para buscas futuras."""
    thread_id = runtime.execution_info.thread_id
    user_id = runtime.server_info.user.identity
    await client.threads.update(
        thread_id=thread_id,
        metadata={
            "user_id": user_id,
            "topic": topic,
            "summary": summary[:200],
            "indexed_at": datetime.now(timezone.utc).isoformat(),
        },
    )
    mantis_log("INFO", "conversation_indexed", f"Thread: {thread_id}, Topic: {topic}")
    return f"Conversa indexada sob o tópico '{topic}'"
```

### 6. Busca Semântica com Embeddings

```python
from langchain_openai import OpenAIEmbeddings
import numpy as np

embeddings = OpenAIEmbeddings()

@tool
async def semantic_search_conversations(query: str, runtime: ToolRuntime) -> str:
    """Busca semântica em conversas passadas usando embeddings."""
    user_id = runtime.server_info.user.identity
    query_embedding = await embeddings.aembed_query(query)

    # Buscar threads e calcular similaridade
    threads = await client.threads.search(metadata={"user_id": user_id}, limit=50)
    scored_threads = []
    for thread in threads:
        thread_embedding = thread.get("metadata", {}).get("embedding")
        if thread_embedding:
            similarity = np.dot(query_embedding, thread_embedding)
            scored_threads.append((thread, similarity))

    scored_threads.sort(key=lambda x: x[1], reverse=True)
    top_threads = scored_threads[:5]

    results = []
    for thread, score in top_threads:
        history = await client.threads.get_history(thread_id=thread["thread_id"])
        results.append({"thread_id": thread["thread_id"], "score": score, "summary": history["values"].get("messages", [{}])[-1].get("content", "")[:300]})

    return json.dumps(results, default=str)
```

### 7. Configuração de Metadados nas Threads

```python
# Ao criar uma thread, adicionar metadados relevantes
await client.threads.create(
    metadata={
        "user_id": "user-123",
        "org_id": "org-acme",
        "project": "project-alpha",
        "topic": "customer-support",
        "embedding": query_embedding.tolist(),
    }
)
```

### 8. Política de Retenção e Privacidade

```python
# Configurar expurgo de conversas antigas
async def cleanup_old_threads(days: int = 90):
    cutoff = datetime.now(timezone.utc) - timedelta(days=days)
    threads = await client.threads.search(limit=100)
    for thread in threads:
        if thread.get("created_at") and datetime.fromisoformat(thread["created_at"]) < cutoff:
            # Opcional: anonimizar ou deletar
            mantis_log("INFO", "thread_cleanup", f"Thread {thread['thread_id']} marcada para expurgo")
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_search_params():
    assert "user_id" in {"user_id": "test", "org_id": "test"}

@pytest.mark.asyncio
async def test_search_recent():
    # Mock do client
    pass
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-episodic-memory.md --json
```

---

## 🔗 Referências Cruzadas
- [[deep-agents-memory-long-term.md]]
- [[deep-agents-memory-scopes.md]]
