---
artifact_id: "deep-agents-backends-composite"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-backends-composite.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-backends-composite.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-backends-composite-v1.0.0"
generated_at: "2026-05-25T15:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-backends-overview", "deep-agents-permissions"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🧩 Deep Agents – CompositeBackend e Roteamento Avançado

> **Contrato modular**: Artefato filho do Master Agent. Explora o `CompositeBackend` para rotear diferentes paths para diferentes backends, com padrões de isolamento, permissões e boas práticas.

---

## 🎯 Propósito
Permitir que agentes MANTIS tenham múltiplos backends de arquivos em um único sistema de arquivos virtual, roteando paths específicos para backends específicos.

## 📋 Especificação (SDD)
- **Entradas**: Mapa de rotas (path → backend), backend default.
- **Saídas**: Backend composto que agrega operações de múltiplos backends.
- **Side Effects**: Operações roteadas para o backend correto.
- **Constraints Aplicáveis**: C1 (protocolo de roteamento), C3 (isolamento de backends), C4 (multi‑tenant), C5 (agregação de resultados), C7 (falha isolada por backend), C8 (logs de roteamento).
- **Dependências**: `deepagents`.

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

### 1. Configuração Básica do CompositeBackend

```python
from deepagents import create_deep_agent
from deepagents.backends import CompositeBackend, StateBackend, FilesystemBackend, StoreBackend
from langgraph.store.memory import InMemoryStore

agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    backend=CompositeBackend(
        default=StateBackend(),
        routes={
            "/memories/": StoreBackend(
                namespace=lambda rt: (rt.server_info.user.identity,),
            ),
            "/workspace/": FilesystemBackend(
                root_dir="/data/projects",
                virtual_mode=True,
            ),
        },
    ),
    store=InMemoryStore(),
)
```

### 2. Regras de Roteamento

```python
# Prefixos mais longos têm precedência:
# "/memories/projects/" → rota específica
# "/memories/" → rota geral

backend = CompositeBackend(
    default=StateBackend(),
    routes={
        "/memories/": StoreBackend(namespace=lambda rt: ("memories",)),
        "/memories/projects/": StoreBackend(namespace=lambda rt: ("projects",)),
    },
)
# "/memories/projects/notes.md" → rota "/memories/projects/"
# "/memories/AGENTS.md" → rota "/memories/"
# "/workspace/temp.txt" → default StateBackend
```

### 3. Agregação de Listagens

```python
# ls, glob, grep agregam resultados de TODOS os backends
# e preservam os prefixos de path originais.

# Exemplo de ls("/"):
# StateBackend: ["/large_tool_results/", "/conversation_history/"]
# StoreBackend: ["/memories/AGENTS.md", "/memories/notes.md"]
# FilesystemBackend: ["/workspace/project.py", "/workspace/README.md"]
# Resultado agregado: todos os paths acima
```

### 4. Composite com Sandbox

```python
from deepagents.backends import CompositeBackend, StateBackend, StoreBackend

# Sandbox como default (execução de código), mas memórias em Store
composite = CompositeBackend(
    default=sandbox_backend,  # Modal, Daytona, etc.
    routes={
        "/memories/": StoreBackend(namespace=lambda rt: (rt.server_info.user.identity,)),
    },
)

agent = create_deep_agent(
    model="anthropic:claude-sonnet-4-6",
    backend=composite,
    store=InMemoryStore(),
)
```

### 5. Permissões com CompositeBackend e Sandbox

```python
# Quando o default é um sandbox, permissões DEVEM ser scoped a uma rota conhecida
agent = create_deep_agent(
    model="anthropic:claude-sonnet-4-6",
    backend=CompositeBackend(
        default=sandbox_backend,
        routes={"/memories/": memories_backend},
    ),
    permissions=[
        FilesystemPermission(
            operations=["write"],
            paths=["/memories/**"],
            mode="deny",
        ),
    ],
)
# Isso funciona: permissões scoped a /memories/
```

### 6. Erro: Permissões Fora das Rotas

```python
# ISSO LEVANTA NotImplementedError:
# Permissões que incluem paths fora de qualquer rota (ex: "/workspace/**")
# quando o default é um sandbox.
try:
    agent = create_deep_agent(
        model="anthropic:claude-sonnet-4-6",
        backend=CompositeBackend(
            default=sandbox_backend,
            routes={"/memories/": memories_backend},
        ),
        permissions=[
            FilesystemPermission(operations=["write"], paths=["/workspace/**"], mode="deny"),
        ],
    )
except NotImplementedError:
    mantis_log("ERROR", "permission_error", "Permissões devem ser scoped a rotas conhecidas")
```

### 7. Composite para Desenvolvimento Local (Padrão Recomendado)

```python
agent = create_deep_agent(
    model="openai:gpt-5.4",
    backend=CompositeBackend(
        default=StateBackend(),  # Dados internos efêmeros
        routes={
            "/workspace/": FilesystemBackend(
                root_dir="/home/dev/project",
                virtual_mode=True,
            ),
            "/memories/": StoreBackend(
                namespace=lambda rt: (rt.server_info.user.identity,),
            ),
        },
    ),
    store=InMemoryStore(),
    interrupt_on={"write_file": True, "edit_file": True},
    checkpointer=MemorySaver(),
)
```

### 8. Composite para Produção (LangSmith Deployment)

```python
agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    backend=CompositeBackend(
        default=StateBackend(),
        routes={
            "/memories/": StoreBackend(
                namespace=lambda rt: (rt.server_info.user.identity,),
            ),
            "/policies/": StoreBackend(
                namespace=lambda rt: (rt.context.org_id,),
            ),
        },
    ),
    # store é injetado pela plataforma
)
```

### 9. Implementação de Roteamento Customizado

```python
class LoggingCompositeBackend(CompositeBackend):
    def _resolve_backend(self, path: str):
        backend = super()._resolve_backend(path)
        mantis_log("DEBUG", "route_resolved", f"Path: {path} → {type(backend).__name__}")
        return backend

    def write(self, file_path: str, content: str) -> WriteResult:
        mantis_log("INFO", "composite_write", f"Escrevendo em {file_path}")
        return super().write(file_path, content)

    def read(self, file_path: str, offset: int = 0, limit: int = 2000) -> ReadResult:
        mantis_log("INFO", "composite_read", f"Lendo {file_path}")
        return super().read(file_path, offset, limit)
```

### 10. Troubleshooting de Rotas

```python
# Verificar para qual backend um path será roteado:
def debug_route(backend: CompositeBackend, path: str):
    resolved = backend._resolve_backend(path)
    print(f"Path: {path}")
    print(f"Backend: {type(resolved).__name__}")
    return resolved

# Exemplo:
debug_route(composite, "/memories/AGENTS.md")   # → StoreBackend
debug_route(composite, "/workspace/main.py")    # → FilesystemBackend
debug_route(composite, "/temp/scratch.txt")     # → StateBackend (default)
```

---

## 🧪 Testes Unitários (TDD)

```python
from deepagents.backends import CompositeBackend, StateBackend, StoreBackend
from deepagents.backends.protocol import WriteResult, ReadResult

def test_composite_routing():
    state = StateBackend()
    store = StoreBackend(namespace=lambda rt: ("test",))
    composite = CompositeBackend(
        default=state,
        routes={"/memories/": store},
    )
    # Verificar que default é StateBackend
    assert isinstance(composite.default, StateBackend)
    # Verificar rota
    assert "/memories/" in composite.routes

def test_composite_write_to_default():
    composite = CompositeBackend(default=StateBackend())
    result = composite.write("/test.txt", "data")
    assert result.error is None
    assert result.path == "/test.txt"
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-backends-composite.md --json
```

---

## 🔗 Referências Cruzadas (Wikilinks Mínimos)
- [[deep-agents-backends-overview.md]]
- [[deep-agents-backends-filesystem.md]]
- [[deep-agents-backends-store.md]]
- [[deep-agents-permissions.md]]
- [[langchain-langraph-master-agent.md]]

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-25T15:00:00Z | langchain-langraph-master-agent | Criação inicial: composite backend | C1,C3,C4,C5,C7,C8 |
