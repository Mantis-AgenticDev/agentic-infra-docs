---
artifact_id: "deep-agents-acp-integration"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-acp-integration.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-acp-integration.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-acp-v1.0.0"
generated_at: "2026-05-25T16:45:00Z"
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

# 🔌 Deep Agents – ACP (Agent Client Protocol)

> **Contrato modular**: Artefato filho do Master Agent. Documenta como expor Deep Agents via ACP para integração com editores de código (Zed, JetBrains, VS Code, Neovim), usando servidor stdio e biblioteca `deepagents-acp`.

---

## 🎯 Propósito
Permitir que agentes MANTIS sejam usados como assistentes de codificação diretamente em IDEs, recebendo contexto do projeto e enviando atualizações em tempo real.

## 📋 Especificação (SDD)
- **Entradas**: Agente Deep Agent, configuração de servidor ACP.
- **Saídas**: Servidor ACP rodando em stdio.
- **Side Effects**: Conexão com editores.
- **Constraints Aplicáveis**: C1 (protocolo ACP), C3 (segurança da comunicação), C5 (schema de mensagens), C7 (reconexão), C8 (logs).
- **Dependências**: `deepagents-acp`, `acp`.

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

### 1. Servidor ACP Mínimo

```python
import asyncio
from acp import run_agent
from deepagents import create_deep_agent
from langgraph.checkpoint.memory import MemorySaver
from deepagents_acp.server import AgentServerACP

async def main():
    agent = create_deep_agent(
        model="google_genai:gemini-3.5-flash",
        system_prompt="Você é um assistente de codificação prestativo.",
        checkpointer=MemorySaver(),
    )
    server = AgentServerACP(agent)
    await run_agent(server)

if __name__ == "__main__":
    asyncio.run(main())
```

### 2. Configuração no Zed

```json
{
  "agent_servers": {
    "DeepAgents": {
      "type": "custom",
      "command": "/caminho/absoluto/para/run_demo_agent.sh"
    }
  }
}
```

### 3. Exemplo de Agente de Codificação

```python
from deepagents import create_deep_agent
from deepagents.backends import FilesystemBackend

agent = create_deep_agent(
    model="anthropic:claude-sonnet-4-6",
    system_prompt="Você é um engenheiro de software sênior.",
    backend=FilesystemBackend(root_dir=".", virtual_mode=True),
    checkpointer=MemorySaver(),
)
```

### 4. Uso com Toad (Gerenciador de Processos)

```bash
toad acp "python path/to/your_server.py" .
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_acp_server_creation():
    agent = create_deep_agent(model="openai:gpt-5.4")
    server = AgentServerACP(agent)
    assert server is not None
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-acp-integration.md --json
```

---

## 🔗 Referências Cruzadas
- [[deep-agents-core-customization.md]]
- [[langchain-langraph-master-agent.md]]

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-25T16:45:00Z | langchain-langraph-master-agent | Criação inicial: ACP | C1,C3,C5,C7,C8 |
