---
artifact_id: "deep-agents-backends-overview"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-backends-overview.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-backends-overview.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-backends-overview-v1.0.0"
generated_at: "2026-05-25T14:15:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-backends-filesystem", "deep-agents-backends-store", "deep-agents-backends-composite"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🗄️ Deep Agents – Backends Overview (Sistemas de Arquivos Virtuais)

> **Contrato modular**: Artefato filho do Master Agent. Apresenta todos os backends de arquivos disponíveis para Deep Agents, com exemplos densos de configuração, casos de uso e integração.

---

## 🎯 Propósito
Fornecer uma visão completa e executável de todos os backends de arquivos (StateBackend, FilesystemBackend, LocalShellBackend, StoreBackend, ContextHubBackend, CompositeBackend, Sandboxes) para que os agentes MANTIS possam ler, escrever e gerenciar arquivos de forma segura e escalável.

## 📋 Especificação (SDD)
- **Entradas**: Escolha de backend, configuração de root_dir, namespace, store.
- **Saídas**: Backend configurado e pronto para uso com `create_deep_agent`.
- **Side Effects**: Persistência em estado, disco, store ou hub.
- **Constraints Aplicáveis**: C1 (protocolo BackendProtocol), C3 (segurança de acesso), C4 (isolamento multi-tenant), C5 (estrutura de arquivos), C7 (tratamento de erros de I/O), C8 (logs de operações).
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

### 1. StateBackend – Padrão (Thread‑Scoped)

```python
from deepagents import create_deep_agent
from deepagents.backends import StateBackend

# Padrão implícito
agent = create_deep_agent(model="google_genai:gemini-3.5-flash")

# Explícito
agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    backend=StateBackend(),
)
mantis_log("INFO", "backend_configured", "StateBackend ativado – thread-scoped")
```

**Características:**
- Arquivos armazenados no estado do grafo LangGraph.
- Persiste entre turnos na mesma thread (via checkpointer).
- Não compartilhado entre threads.
- Ideal para rascunhos e dados intermediários.

### 2. FilesystemBackend – Acesso Real ao Disco

```python
from deepagents.backends import FilesystemBackend

agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    backend=FilesystemBackend(root_dir=".", virtual_mode=True),
)
mantis_log("WARN", "fs_backend_active", "FilesystemBackend com root_dir='.' – use com cautela")
```

**⚠️ Avisos de segurança:**
- `virtual_mode=True` restringe paths com `..`, `~` e absolutos fora do root.
- Nunca use em servidores web ou ambientes multi-tenant sem sandbox.
- Habilite HITL para revisar operações sensíveis.
- Evite expor diretórios com secrets (.env, chaves).

### 3. LocalShellBackend – Acesso ao Shell

```python
from deepagents.backends import LocalShellBackend

agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    backend=LocalShellBackend(
        root_dir=".",
        virtual_mode=True,
        env={"PATH": "/usr/bin:/bin", "HOME": "/home/user"}
    ),
)
mantis_log("CRITICAL", "shell_backend_active", "LocalShellBackend – agent pode executar comandos shell!")
```

**⚠️ Perigo extremo:** Agente pode executar comandos arbitrários no host. Use apenas em desenvolvimento local confiável.

### 4. StoreBackend – Persistência Entre Threads

```python
from deepagents.backends import StoreBackend
from langgraph.store.memory import InMemoryStore

agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    backend=StoreBackend(
        namespace=lambda rt: (rt.server_info.user.identity,),
    ),
    store=InMemoryStore(),  # Em produção, omitir (plataforma provê)
)
mantis_log("INFO", "store_backend", "StoreBackend com namespace por usuário")
```

**Namespaces comuns:**
```python
# Por usuário
StoreBackend(namespace=lambda rt: (rt.server_info.user.identity,))
# Por assistente
StoreBackend(namespace=lambda rt: (rt.server_info.assistant_id,))
# Por thread
StoreBackend(namespace=lambda rt: (rt.execution_info.thread_id,))
# Composto
StoreBackend(namespace=lambda rt: (rt.server_info.user.identity, rt.server_info.assistant_id))
```

### 5. ContextHubBackend – LangSmith Hub

```python
from deepagents.backends import ContextHubBackend

agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    backend=ContextHubBackend("my-agent"),
)
mantis_log("INFO", "contexthub_backend", "ContextHubBackend conectado ao Hub repo 'my-agent'")
```

### 6. CompositeBackend – Roteamento de Paths

```python
from deepagents.backends import CompositeBackend, StateBackend, StoreBackend

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
mantis_log("INFO", "composite_backend", "CompositeBackend com 3 rotas configuradas")
```

**Regras de roteamento:**
- Prefixos mais longos têm precedência.
- `ls`, `glob`, `grep` agregam resultados de todos os backends.
- Paths mantêm os prefixos originais nos resultados.

### 7. Sandboxes – Ambientes Isolados

```python
# Modal
from langchain_modal import ModalSandbox
import modal

app = modal.App.lookup("your-app")
modal_sandbox = modal.Sandbox.create(app=app)
backend = ModalSandbox(sandbox=modal_sandbox)

# Daytona
from daytona import Daytona
from langchain_daytona import DaytonaSandbox

sandbox = Daytona().create()
backend = DaytonaSandbox(sandbox=sandbox)

# Runloop
from langchain_runloop import RunloopSandbox
from runloop_api_client import RunloopSDK

client = RunloopSDK(bearer_token=os.environ["RUNLOOP_API_KEY"])
devbox = client.devbox.create()
backend = RunloopSandbox(devbox=devbox)

agent = create_deep_agent(
    model="anthropic:claude-sonnet-4-6",
    system_prompt="Você é um assistente de codificação com acesso a sandbox.",
    backend=backend,
)
```

### 8. Ferramentas de Arquivos Disponíveis

```python
# Todos os backends expõem estas ferramentas:
# - ls(path) -> lista arquivos/diretórios
# - read_file(path, offset, limit) -> lê conteúdo
# - write_file(path, content) -> cria arquivo
# - edit_file(path, old_string, new_string, replace_all) -> edita
# - glob(pattern, path) -> busca por padrão
# - grep(pattern, path, glob) -> busca textual

# Sandboxes e LocalShellBackend também expõem:
# - execute(command) -> executa comando shell
```

### 9. Protocolo BackendProtocol

```python
from deepagents.backends.protocol import (
    BackendProtocol, WriteResult, EditResult, LsResult,
    ReadResult, GrepResult, GlobResult, FileInfo, GrepMatch, FileData
)

class CustomBackend(BackendProtocol):
    def ls(self, path: str) -> LsResult:
        entries = [FileInfo(path="/exemplo.txt", is_dir=False, size=100)]
        return LsResult(entries=entries)

    def read(self, file_path: str, offset: int = 0, limit: int = 2000) -> ReadResult:
        content = "conteúdo do arquivo"
        return ReadResult(file_data=FileData(content=content, encoding="utf-8"))

    def write(self, file_path: str, content: str) -> WriteResult:
        mantis_log("INFO", "custom_write", f"Arquivo: {file_path}")
        return WriteResult(path=file_path, files_update=None)

    def edit(self, file_path: str, old_string: str, new_string: str, replace_all: bool = False) -> EditResult:
        return EditResult(path=file_path, occurrences=1, files_update=None)

    def grep(self, pattern: str, path: str | None = None, glob: str | None = None) -> GrepResult:
        matches = [GrepMatch(path="/exemplo.txt", line=1, text=f"match: {pattern}")]
        return GrepResult(matches=matches)

    def glob(self, pattern: str, path: str = "/") -> GlobResult:
        return GlobResult(matches=[FileInfo(path="/exemplo.txt")])
```

### 10. Migração de Fábricas para Instâncias (v0.5.0+)

```python
# ANTES (deprecated)
agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    backend=lambda rt: StateBackend(rt),
)

# DEPOIS (recomendado)
agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    backend=StateBackend(),
)

# StoreBackend também
# ANTES: backend=lambda rt: StoreBackend(rt)
# DEPOIS: backend=StoreBackend(namespace=lambda rt: (rt.server_info.user.identity,))
```

---

## 🧪 Testes Unitários (TDD)

```python
import pytest
from deepagents.backends import StateBackend, FilesystemBackend, StoreBackend, CompositeBackend
from deepagents.backends.protocol import WriteResult, EditResult, LsResult, ReadResult

def test_state_backend_creation():
    backend = StateBackend()
    assert backend is not None

def test_filesystem_backend_creation():
    backend = FilesystemBackend(root_dir="/tmp", virtual_mode=True)
    assert backend.root_dir == "/tmp"

def test_composite_backend_routing():
    backend = CompositeBackend(
        default=StateBackend(),
        routes={"/memories/": StateBackend()},
    )
    assert backend.default is not None
    assert "/memories/" in backend.routes

def test_write_result():
    result = WriteResult(path="/test.txt", files_update={"key": "value"})
    assert result.path == "/test.txt"
    assert result.files_update is not None

def test_read_result_error():
    result = ReadResult(error="File not found")
    assert result.error == "File not found"
    assert result.file_data is None
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-backends-overview.md --json
```

---

## 🔗 Referências Cruzadas (Wikilinks Mínimos)
- [[deep-agents-backends-filesystem.md]] ← Próximo: FilesystemBackend
- [[deep-agents-backends-store.md]] ← StoreBackend
- [[deep-agents-backends-composite.md]] ← CompositeBackend
- [[deep-agents-core-customization.md]]
- [[langchain-langraph-master-agent.md]]

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-25T14:15:00Z | langchain-langraph-master-agent | Criação inicial: visão geral de backends | C1,C3,C4,C5,C7,C8 |
