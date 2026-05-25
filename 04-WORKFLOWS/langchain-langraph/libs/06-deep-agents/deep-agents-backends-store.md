---
artifact_id: "deep-agents-backends-store"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-backends-store.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-backends-store.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-backends-store-v1.0.0"
generated_at: "2026-05-25T14:45:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-backends-overview", "deep-agents-memory-long-term"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🗃️ Deep Agents – StoreBackend e ContextHubBackend

> **Contrato modular**: Artefato filho do Master Agent. Detalha o uso de `StoreBackend` para persistência cross‑thread e `ContextHubBackend` para armazenamento no LangSmith Hub, com fábricas de namespace e isolamento multi‑tenant.

---

## 🎯 Propósito
Permitir que agentes MANTIS armazenem dados que persistem entre threads e sessões, viabilizando memória de longo prazo e compartilhamento controlado.

## 📋 Especificação (SDD)
- **Entradas**: `BaseStore`, fábrica de namespace, configuração de Hub.
- **Saídas**: Backend configurado para leitura/escrita cross‑thread.
- **Side Effects**: Dados persistidos no store ou Hub.
- **Constraints Aplicáveis**: C1 (namespace), C3 (proteção de dados), C4 (isolamento multi‑tenant), C5 (schema de store), C7 (conflitos de escrita), C8 (logs).
- **Dependências**: `deepagents`, `langgraph.store.memory`, `langsmith`.

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

### 1. StoreBackend Básico com Namespace por Usuário

```python
from deepagents import create_deep_agent
from deepagents.backends import StoreBackend
from langgraph.store.memory import InMemoryStore

store = InMemoryStore()

agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    backend=StoreBackend(
        namespace=lambda rt: (rt.server_info.user.identity,),
    ),
    store=store,
)
mantis_log("INFO", "store_backend", "StoreBackend configurado com namespace por usuário")
```

### 2. Fábrica de Namespace – Padrões Comuns

```python
# Por usuário (isolamento total)
StoreBackend(namespace=lambda rt: (rt.server_info.user.identity,))

# Por assistente (compartilhado entre usuários do mesmo agente)
StoreBackend(namespace=lambda rt: (rt.server_info.assistant_id,))

# Por thread (escopo de conversa)
StoreBackend(namespace=lambda rt: (rt.execution_info.thread_id,))

# Composto: usuário + assistente
StoreBackend(namespace=lambda rt: (
    rt.server_info.user.identity,
    rt.server_info.assistant_id,
))

# Composto: organização + usuário
StoreBackend(namespace=lambda rt: (
    rt.context.org_id,
    rt.server_info.user.identity,
))
```

### 3. Seed de Dados no Store

```python
from deepagents.backends.utils import create_file_data

# Popular o store com arquivos iniciais
store.put(
    ("user-alice",),
    "/memories/AGENTS.md",
    create_file_data("""## Preferências
- Respostas concisas
- Exemplos em Python
- Formato bullet points"""),
)

store.put(
    ("user-alice",),
    "/memories/project-notes.md",
    create_file_data("""## Projeto Alpha
- Deadline: 30/06/2026
- Stack: Python, LangGraph, PostgreSQL
- Responsável: Alice"""),
)

mantis_log("INFO", "store_seeded", "Memórias iniciais populadas para user-alice")
```

### 4. Acesso aos Dados via Ferramentas do Agente

```python
# O agente acessa os arquivos do store como um sistema de arquivos normal:
# read_file("/memories/AGENTS.md")
# write_file("/memories/new-note.md", "conteúdo")
# edit_file("/memories/AGENTS.md", "old", "new")

# Tudo é automaticamente roteado para o StoreBackend
```

### 5. ContextHubBackend – Persistência no LangSmith Hub

```python
from deepagents.backends import ContextHubBackend

agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    backend=ContextHubBackend("my-agent"),
)
# Requer LANGSMITH_API_KEY definida
# Arquivos são persistidos como commits no Hub repo "my-agent"
```

### 6. Composite com StoreBackend e StateBackend

```python
from deepagents.backends import CompositeBackend, StateBackend, StoreBackend

agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    backend=CompositeBackend(
        default=StateBackend(),  # Dados voláteis (thread-scoped)
        routes={
            "/memories/": StoreBackend(
                namespace=lambda rt: (rt.server_info.user.identity,),
            ),
            "/policies/": StoreBackend(
                namespace=lambda rt: (rt.context.org_id,),
            ),
        },
    ),
    store=InMemoryStore(),  # Em LangSmith Deployment, omitir
)
```

### 7. Permissões de Acesso nos Backends de Store

```python
from deepagents import FilesystemPermission

agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    backend=CompositeBackend(
        default=StateBackend(),
        routes={
            "/memories/": StoreBackend(namespace=lambda rt: (rt.server_info.user.identity,)),
            "/policies/": StoreBackend(namespace=lambda rt: (rt.context.org_id,)),
        },
    ),
    permissions=[
        FilesystemPermission(
            operations=["write"],
            paths=["/policies/**"],
            mode="deny",  # Políticas são somente leitura para o agente
        ),
        FilesystemPermission(
            operations=["read", "write"],
            paths=["/memories/**"],
            mode="allow",
        ),
    ],
)
```

### 8. Sincronização e Conflitos

```python
# StoreBackend usa o BaseStore subjacente.
# Escritas concorrentes podem causar conflitos (last-write-wins).
# Para memórias por usuário, conflitos são raros (1 conversa ativa por vez).
# Para memórias compartilhadas, considere background consolidation.

# Exemplo de verificação de conflito:
def safe_write_to_store(store, namespace, key, content):
    try:
        store.put(namespace, key, content)
        mantis_log("INFO", "store_write", f"Key: {key}")
    except Exception as e:
        mantis_log("ERROR", "store_conflict", f"Key: {key}, Error: {e}")
        # O LLM geralmente consegue recuperar e re-tentar
```

### 9. Migração de BackendContext para Runtime

```python
# ANTES (deprecated, removido em v0.7)
StoreBackend(
    namespace=lambda ctx: (ctx.runtime.context.user_id,),
)

# DEPOIS (recomendado)
StoreBackend(
    namespace=lambda rt: (rt.server_info.user.identity,),
)
```

### 10. StoreBackend em Produção (LangSmith Deployment)

```python
# Em LangSmith Deployment, NÃO passe 'store' – a plataforma provê.
agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    backend=StoreBackend(
        namespace=lambda rt: (rt.server_info.user.identity,),
    ),
    # store NÃO é passado → plataforma injeta automaticamente
)
```

---

## 🧪 Testes Unitários (TDD)

```python
from langgraph.store.memory import InMemoryStore
from deepagents.backends.utils import create_file_data

def test_store_put_get():
    store = InMemoryStore()
    store.put(("test-ns",), "/test.txt", create_file_data("hello"))
    item = store.get(("test-ns",), "/test.txt")
    assert item is not None
    assert item.value["content"] == "hello"

def test_store_namespace_isolation():
    store = InMemoryStore()
    store.put(("user-a",), "/data.txt", create_file_data("A"))
    store.put(("user-b",), "/data.txt", create_file_data("B"))
    assert store.get(("user-a",), "/data.txt").value["content"] == "A"
    assert store.get(("user-b",), "/data.txt").value["content"] == "B"
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-backends-store.md --json
```

---

## 🔗 Referências Cruzadas (Wikilinks Mínimos)
- [[deep-agents-backends-overview.md]]
- [[deep-agents-memory-long-term.md]]
- [[langchain-langraph-master-agent.md]]

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-25T14:45:00Z | langchain-langraph-master-agent | Criação inicial: store backends | C1,C3,C4,C5,C7,C8 |
