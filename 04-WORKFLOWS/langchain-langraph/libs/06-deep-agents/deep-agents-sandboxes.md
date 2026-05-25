---
artifact_id: "deep-agents-sandboxes"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-sandboxes.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-sandboxes.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-sandboxes-v1.0.0"
generated_at: "2026-05-25T18:30:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-backends-overview"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🏖️ Deep Agents – Sandboxes (Ambientes Isolados)

> **Contrato modular**: Artefato filho do Master Agent. Detalha o uso de sandboxes (Modal, Daytona, Runloop, LangSmith) como backends que fornecem sistemas de arquivos isolados e execução de comandos.

---

## 🎯 Propósito
Permitir que agentes MANTIS executem código e manipulem arquivos em ambientes isolados e seguros, sem acesso ao host.

## 📋 Especificação (SDD)
- **Entradas**: Configuração de sandbox (Modal, Daytona, Runloop, LangSmith).
- **Saídas**: Backend com `execute` e ferramentas de arquivo.
- **Side Effects**: Criação e destruição de sandboxes.
- **Constraints Aplicáveis**: C1 (contrato), C3 (isolamento), C5 (schema), C7 (timeout), C8 (logs).
- **Dependências**: `langchain-modal`, `langchain-daytona`, `langchain-runloop`, `langsmith[sandbox]`.

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

### 1. Modal Sandbox

```python
import modal
from deepagents import create_deep_agent
from langchain_modal import ModalSandbox

app = modal.App.lookup("your-app")
modal_sandbox = modal.Sandbox.create(app=app)
backend = ModalSandbox(sandbox=modal_sandbox)

agent = create_deep_agent(
    model="anthropic:claude-sonnet-4-6",
    system_prompt="Você é um assistente de codificação Python com acesso a sandbox.",
    backend=backend,
)
try:
    result = agent.invoke({
        "messages": [{"role": "user", "content": "Crie um pacote Python e execute pytest"}]
    })
finally:
    modal_sandbox.terminate()
```

### 2. Daytona Sandbox

```python
from daytona import Daytona
from langchain_daytona import DaytonaSandbox

sandbox = Daytona().create()
backend = DaytonaSandbox(sandbox=sandbox)

agent = create_deep_agent(
    model="anthropic:claude-sonnet-4-6",
    system_prompt="Você é um assistente de codificação.",
    backend=backend,
)
try:
    result = agent.invoke({
        "messages": [{"role": "user", "content": "Crie um script Python e execute."}]
    })
finally:
    sandbox.stop()
```

### 3. Runloop Sandbox

```python
from langchain_runloop import RunloopSandbox
from runloop_api_client import RunloopSDK

client = RunloopSDK(bearer_token=os.environ["RUNLOOP_API_KEY"])
devbox = client.devbox.create()
backend = RunloopSandbox(devbox=devbox)

agent = create_deep_agent(model="anthropic:claude-sonnet-4-6", backend=backend)
try:
    result = agent.invoke(...)
finally:
    devbox.shutdown()
```

### 4. LangSmith Sandbox (Private Beta)

```python
from deepagents.backends import LangSmithSandbox
from langsmith.sandbox import SandboxClient

client = SandboxClient()
ls_sandbox = client.create_sandbox()
backend = LangSmithSandbox(sandbox=ls_sandbox)

agent = create_deep_agent(model="anthropic:claude-sonnet-4-6", backend=backend)
try:
    result = agent.invoke(...)
finally:
    client.delete_sandbox(ls_sandbox.name)
```

### 5. Ferramenta `execute`

```python
# Todas as sandboxes fornecem a ferramenta execute, que executa comandos shell
# Exemplo: execute(command="pytest tests/")
```

### 6. Ciclo de Vida

```python
# 1. Criar sandbox
# 2. Criar agente com backend=sandbox
# 3. Invocar agente
# 4. Destruir sandbox (finally)
```

### 7. Segurança

- Sandboxes são isolados do host.
- Não requerem HITL para operações de arquivo (ambiente descartável).
- Sempre destrua a sandbox após o uso para evitar custos.

---

## 🧪 Testes Unitários (TDD)

```python
def test_sandbox_creation():
    # Mock
    pass
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-sandboxes.md --json
```

---

## 🔗 Referências Cruzadas
- [[deep-agents-backends-overview.md]]
- [[langchain-langraph-master-agent.md]]

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-25T18:30:00Z | langchain-langraph-master-agent | Criação inicial: sandboxes | C1,C3,C5,C7,C8 |
