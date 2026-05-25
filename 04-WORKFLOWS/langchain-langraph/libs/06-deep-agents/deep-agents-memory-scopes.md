---
artifact_id: "deep-agents-memory-scopes"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C4","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-memory-scopes.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-memory-scopes.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-memory-scopes-v1.0.0"
generated_at: "2026-05-25T17:45:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-memory-long-term", "deep-agents-memory-consolidation"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🧠 Deep Agents – Memória por Escopos (Usuário, Agente, Organização)

> **Contrato modular**: Artefato filho do Master Agent. Detalha os diferentes escopos de memória de longo prazo em Deep Agents, com exemplos práticos de namespace, seed de dados e isolamento.

---

## 🎯 Propósito
Permitir que agentes MANTIS implementem memória persistente com isolamento correto entre usuários, agentes e organizações, usando `StoreBackend` e namespaces.

## 📋 Especificação (SDD)
- **Entradas**: Configuração de `StoreBackend`, fábrica de namespace, arquivos de memória.
- **Saídas**: Agente com memória isolada por escopo.
- **Side Effects**: Escritas no `BaseStore`.
- **Constraints Aplicáveis**: C1 (formato de namespace), C3 (proteção de dados pessoais), C4 (isolamento estrito), C5 (schema de arquivos), C7 (conflitos de escrita), C8 (auditoria), C9 (thread_id).
- **Dependências**: `deepagents`, `langgraph.store`.

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

### 1. Memória com Escopo de Agente (Compartilhada entre Todos os Usuários)

```python
from deepagents import create_deep_agent
from deepagents.backends import CompositeBackend, StateBackend, StoreBackend
from langgraph.store.memory import InMemoryStore
from deepagents.backends.utils import create_file_data

store = InMemoryStore()
# Seed: memória compartilhada do agente
store.put(
    ("my-agent",),
    "/memories/AGENTS.md",
    create_file_data("""## Identidade do Agente
- Nome: MANTIS Assistant
- Especialidade: Automação de workflows empresariais
- Tom: Profissional e conciso"""),
)

agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    memory=["/memories/AGENTS.md"],
    backend=CompositeBackend(
        default=StateBackend(),
        routes={
            "/memories/": StoreBackend(namespace=lambda rt: (rt.server_info.assistant_id,)),
        },
    ),
    store=store,
)
```

### 2. Memória com Escopo de Usuário (Isolada por Usuário)

```python
store = InMemoryStore()
# Seed: preferências do usuário Alice
store.put(
    ("user-alice",),
    "/memories/preferences.md",
    create_file_data("""## Preferências
- Respostas em bullet points
- Exemplos em Python
- Explicações detalhadas"""),
)
store.put(
    ("user-bob",),
    "/memories/preferences.md",
    create_file_data("""## Preferências
- Respostas em parágrafos
- Exemplos em TypeScript
- Explicações concisas"""),
)

agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    memory=["/memories/preferences.md"],
    backend=CompositeBackend(
        default=StateBackend(),
        routes={
            "/memories/": StoreBackend(namespace=lambda rt: (rt.server_info.user.identity,)),
        },
    ),
    store=store,
)
```

### 3. Memória com Escopo de Organização (Políticas Corporativas)

```python
store = InMemoryStore()
store.put(
    ("org-acme",),
    "/policies/compliance.md",
    create_file_data("""## Políticas de Compliance
- Nunca divulgar preços internos
- Sempre incluir disclaimer em conselhos financeiros
- Dados de clientes devem ser anonimizados em logs"""),
)

agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    memory=["/memories/preferences.md", "/policies/compliance.md"],
    backend=CompositeBackend(
        default=StateBackend(),
        routes={
            "/memories/": StoreBackend(namespace=lambda rt: (rt.server_info.user.identity,)),
            "/policies/": StoreBackend(namespace=lambda rt: (rt.context.org_id,)),
        },
    ),
    permissions=[
        FilesystemPermission(operations=["write"], paths=["/policies/**"], mode="deny"),
    ],
    store=store,
)
```

### 4. Combinação de Escopos (Usuário + Assistente)

```python
StoreBackend(
    namespace=lambda rt: (rt.server_info.assistant_id, rt.server_info.user.identity),
)
```

### 5. Escopo por Thread (Conversa Única)

```python
StoreBackend(
    namespace=lambda rt: (rt.execution_info.thread_id,),
)
```

### 6. Múltiplos Agentes no Mesmo Deploy

```python
StoreBackend(
    namespace=lambda rt: (rt.server_info.assistant_id, rt.server_info.user.identity),
)
```

### 7. Populando Memória via API (Store API)

```python
from langgraph_sdk import get_client
client = get_client(url="<DEPLOYMENT_URL>")

await client.store.put_item(
    ("org-acme",),
    "/compliance.md",
    create_file_data("""## Regras
- Regra 1
- Regra 2"""),
)
```

### 8. Read‑Only vs Writable por Escopo

```python
permissions=[
    FilesystemPermission(operations=["write"], paths=["/policies/**"], mode="deny"),
    FilesystemPermission(operations=["read", "write"], paths=["/memories/**"], mode="allow"),
]
```

### 9. Verificação de Isolamento

```python
def verify_isolation(store):
    alice_prefs = store.get(("user-alice",), "/memories/preferences.md")
    bob_prefs = store.get(("user-bob",), "/memories/preferences.md")
    assert alice_prefs.value["content"] != bob_prefs.value["content"]
    mantis_log("INFO", "isolation_verified", "Alice e Bob têm memórias diferentes")
```

### 10. Troubleshooting: Namespace Incorreto

```python
# ❌ ERRADO: Todos os usuários compartilham a mesma memória
StoreBackend(namespace=lambda rt: ("memories",))

# ✅ CORRETO: Cada usuário tem sua própria memória
StoreBackend(namespace=lambda rt: (rt.server_info.user.identity,))
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_user_isolation():
    store = InMemoryStore()
    store.put(("alice",), "/prefs.md", create_file_data("Alice"))
    store.put(("bob",), "/prefs.md", create_file_data("Bob"))
    assert store.get(("alice",), "/prefs.md").value["content"] == "Alice"
    assert store.get(("bob",), "/prefs.md").value["content"] == "Bob"

def test_org_readonly():
    from deepagents import FilesystemPermission
    perm = FilesystemPermission(operations=["write"], paths=["/policies/**"], mode="deny")
    assert perm.mode == "deny"
    assert perm.operations == ["write"]
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-memory-scopes.md --json
```

---

## 🔗 Referências Cruzadas (Wikilinks Mínimos)
- [[deep-agents-memory-long-term.md]]
- [[deep-agents-memory-consolidation.md]]
- [[deep-agents-backends-store.md]]
- [[langchain-langraph-master-agent.md]]

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-25T17:45:00Z | langchain-langraph-master-agent | Criação inicial: escopos de memória | C1,C3,C4,C5,C7,C8,C9 |
