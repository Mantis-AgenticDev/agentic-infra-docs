---
artifact_id: "deep-agents-backends-filesystem"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-backends-filesystem.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-backends-filesystem.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-backends-fs-v1.0.0"
generated_at: "2026-05-25T14:30:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-backends-overview", "deep-agents-backends-composite"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🗂️ Deep Agents – FilesystemBackend e LocalShellBackend

> **Contrato modular**: Artefato filho do Master Agent. Detalha o uso de `FilesystemBackend` e `LocalShellBackend` com todas as opções de segurança, virtual_mode, políticas de acesso e padrões de uso.

---

## 🎯 Propósito
Permitir que agentes MANTIS acessem o sistema de arquivos real de forma controlada, com camadas de segurança e políticas de restrição.

## 📋 Especificação (SDD)
- **Entradas**: `root_dir` absoluto, flag `virtual_mode`, variáveis de ambiente.
- **Saídas**: Backend configurado com ferramentas de arquivo (+ shell para LocalShellBackend).
- **Side Effects**: Leitura/escrita real no disco; execução de comandos shell.
- **Constraints Aplicáveis**: C1 (paths seguros), C3 (proteção de secrets), C5 (validação de paths), C7 (timeout de comandos), C8 (logs de operações).
- **Dependências**: `deepagents`, `pathlib`.

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

### 1. Configuração Básica do FilesystemBackend

```python
from deepagents import create_deep_agent
from deepagents.backends import FilesystemBackend

agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    backend=FilesystemBackend(
        root_dir="/home/user/projects",
        virtual_mode=True,
    ),
)
mantis_log("INFO", "fs_backend", "FilesystemBackend configurado com root_dir=/home/user/projects")
```

### 2. Virtual Mode – Sandbox de Paths

```python
# virtual_mode=True:
# - Bloqueia '..' (path traversal)
# - Bloqueia '~' (home directory)
# - Bloqueia paths absolutos fora do root_dir
# - Normaliza todos os paths sob root_dir

backend = FilesystemBackend(
    root_dir="/safe/workspace",
    virtual_mode=True,
)

# Comportamento:
# "/workspace/file.txt" → "/safe/workspace/workspace/file.txt" (erro se não existir)
# "../etc/passwd" → bloqueado
# "~/secrets" → bloqueado
```

### 3. CompositeBackend com FilesystemBackend (Padrão Recomendado)

```python
from deepagents.backends import CompositeBackend, StateBackend

agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    backend=CompositeBackend(
        default=StateBackend(),
        routes={
            "/workspace/": FilesystemBackend(
                root_dir="/path/to/project",
                virtual_mode=True,
            ),
        },
    ),
)
mantis_log("INFO", "composite_fs", "Composite: /workspace/ → disco, demais → estado")
```

**Por que Composite?** Dados internos do agente (offloaded tool results, conversation history) são escritos em `/large_tool_results/` e `/conversation_history/`. Com Composite, esses paths vão para StateBackend (efêmero), não poluindo o disco.

### 4. HITL para Operações Sensíveis

```python
from langgraph.checkpoint.memory import MemorySaver

checkpointer = MemorySaver()

agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    backend=FilesystemBackend(root_dir=".", virtual_mode=True),
    interrupt_on={
        "write_file": True,    # Aprovar escritas
        "edit_file": True,     # Aprovar edições
        "read_file": False,    # Leituras sem interrupção
    },
    checkpointer=checkpointer,
)
```

### 5. LocalShellBackend – Shell no Host

```python
from deepagents.backends import LocalShellBackend

agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    backend=LocalShellBackend(
        root_dir=".",
        virtual_mode=True,
        env={"PATH": "/usr/bin:/bin", "HOME": "/home/user"},
        timeout=120,          # Timeout por comando (segundos)
        max_output_bytes=100000,  # Limite de saída
    ),
)
mantis_log("CRITICAL", "shell_backend", "LocalShellBackend ativo – comandos shell permitidos!")
```

### 6. Configuração de Timeout e Limites

```python
backend = LocalShellBackend(
    root_dir="/workspace",
    virtual_mode=True,
    timeout=60,               # 60 segundos por comando
    max_output_bytes=50000,   # 50KB de saída máxima
    env={
        "PATH": "/usr/bin:/bin:/usr/local/bin",
        "PYTHONPATH": "/workspace",
        "NODE_ENV": "development",
    },
    inherit_env=True,         # Herda variáveis do processo pai
)
```

### 7. Políticas de Acesso com Subclasse

```python
from deepagents.backends.filesystem import FilesystemBackend
from deepagents.backends.protocol import WriteResult, EditResult

class GuardedBackend(FilesystemBackend):
    def __init__(self, *, deny_prefixes: list[str], **kwargs):
        super().__init__(**kwargs)
        self.deny_prefixes = [p if p.endswith("/") else p + "/" for p in deny_prefixes]

    def write(self, file_path: str, content: str) -> WriteResult:
        if any(file_path.startswith(p) for p in self.deny_prefixes):
            mantis_log("SECURITY", "write_blocked", f"Path bloqueado: {file_path}")
            return WriteResult(error=f"Escritas não permitidas em {file_path}")
        return super().write(file_path, content)

    def edit(self, file_path: str, old_string: str, new_string: str, replace_all: bool = False) -> EditResult:
        if any(file_path.startswith(p) for p in self.deny_prefixes):
            return EditResult(error=f"Edições não permitidas em {file_path}")
        return super().edit(file_path, old_string, new_string, replace_all)

backend = GuardedBackend(
    root_dir="/workspace",
    virtual_mode=True,
    deny_prefixes=["/workspace/.env", "/workspace/secrets/", "/workspace/prod/"],
)
```

### 8. Wrapper Genérico de Políticas

```python
from deepagents.backends.protocol import BackendProtocol, WriteResult, EditResult

class PolicyWrapper(BackendProtocol):
    def __init__(self, inner: BackendProtocol, deny_prefixes: list[str] | None = None):
        self.inner = inner
        self.deny_prefixes = [p if p.endswith("/") else p + "/" for p in (deny_prefixes or [])]

    def _deny(self, path: str) -> bool:
        return any(path.startswith(p) for p in self.deny_prefixes)

    def ls(self, path: str) -> LsResult:
        return self.inner.ls(path)

    def read(self, file_path: str, offset: int = 0, limit: int = 2000) -> ReadResult:
        return self.inner.read(file_path, offset=offset, limit=limit)

    def grep(self, pattern: str, path: str | None = None, glob: str | None = None) -> GrepResult:
        return self.inner.grep(pattern, path, glob)

    def glob(self, pattern: str, path: str = "/") -> GlobResult:
        return self.inner.glob(pattern, path)

    def write(self, file_path: str, content: str) -> WriteResult:
        if self._deny(file_path):
            return WriteResult(error=f"Escritas não permitidas em {file_path}")
        return self.inner.write(file_path, content)

    def edit(self, file_path: str, old_string: str, new_string: str, replace_all: bool = False) -> EditResult:
        if self._deny(file_path):
            return EditResult(error=f"Edições não permitidas em {file_path}")
        return self.inner.edit(file_path, old_string, new_string, replace_all)

# Uso com qualquer backend
wrapped_fs = PolicyWrapper(
    FilesystemBackend(root_dir="/workspace", virtual_mode=True),
    deny_prefixes=["/workspace/secrets/"],
)
```

### 9. Execução de Comandos com Tratamento de Erros

```python
# O LocalShellBackend executa comandos via subprocess
# Exemplo de uso interno (não chamado diretamente pelo usuário, mas pelo agente):
import subprocess

def safe_execute(command: str, timeout: int = 120, max_output: int = 100000) -> str:
    try:
        result = subprocess.run(
            command,
            shell=True,
            capture_output=True,
            text=True,
            timeout=timeout,
            cwd="/workspace",
            env={"PATH": "/usr/bin:/bin"},
        )
        output = result.stdout + result.stderr
        mantis_log("INFO", "command_executed", f"Comando: {command[:50]}, Exit: {result.returncode}")
        if len(output) > max_output:
            output = output[:max_output] + "\n... (output truncado)"
        return output
    except subprocess.TimeoutExpired:
        mantis_log("ERROR", "command_timeout", f"Timeout: {command[:50]}")
        return f"Erro: comando excedeu {timeout}s"
    except Exception as e:
        mantis_log("ERROR", "command_failed", str(e))
        return f"Erro: {e}"
```

### 10. Boas Práticas e Recomendações Finais

```python
# ✅ SEMPRE use virtual_mode=True
# ✅ SEMPRE envolva em CompositeBackend com StateBackend como default
# ✅ SEMPRE habilite HITL para write_file e edit_file
# ✅ SEMPRE configure timeout em LocalShellBackend
# ✅ NUNCA use LocalShellBackend em produção
# ✅ NUNCA exponha diretórios com secrets (.env, chaves SSH, tokens)

# Configuração canônica recomendada:
agent = create_deep_agent(
    model="openai:gpt-5.4",
    backend=CompositeBackend(
        default=StateBackend(),
        routes={"/workspace/": FilesystemBackend(root_dir="/safe/project", virtual_mode=True)},
    ),
    interrupt_on={"write_file": True, "edit_file": True},
    checkpointer=MemorySaver(),
)
```

---

## 🧪 Testes Unitários (TDD)

```python
import tempfile, os
from deepagents.backends.filesystem import FilesystemBackend
from deepagents.backends.protocol import ReadResult, WriteResult

def test_virtual_mode_blocks_parent():
    with tempfile.TemporaryDirectory() as tmp:
        backend = FilesystemBackend(root_dir=tmp, virtual_mode=True)
        result = backend.write("../outside.txt", "data")
        assert result.error is not None  # Deve ser bloqueado

def test_read_write_cycle():
    with tempfile.TemporaryDirectory() as tmp:
        backend = FilesystemBackend(root_dir=tmp, virtual_mode=False)
        write_result = backend.write("/test.txt", "conteúdo")
        assert write_result.error is None
        read_result = backend.read("/test.txt")
        assert read_result.file_data.content == "conteúdo"
        assert read_result.file_data.encoding == "utf-8"

def test_guarded_backend_blocks():
    with tempfile.TemporaryDirectory() as tmp:
        backend = GuardedBackend(root_dir=tmp, deny_prefixes=["/tmp/secrets"])
        # Testa bloqueio
        # ...
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-backends-filesystem.md --json
```

---

## 🔗 Referências Cruzadas (Wikilinks Mínimos)
- [[deep-agents-backends-overview.md]]
- [[deep-agents-backends-composite.md]]
- [[langchain-langraph-master-agent.md]]

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-25T14:30:00Z | langchain-langraph-master-agent | Criação inicial: filesystem backends | C1,C3,C5,C7,C8 |
