---
artifact_id: "mcp-prompts-management"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/mcp-prompts-management.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/mcp-prompts-management.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:mcp-prompts-v1.0.0"
generated_at: "2026-05-25T04:10:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["mcp-server-fundamentals", "agents-single"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 📝 MCP Prompts Management – Templates Reutilizáveis e Dinâmicos

> **Contrato modular**: Define como criar, expor e consumir prompts no protocolo MCP, permitindo que servidores ofereçam templates de instruções prontos para LLMs.

---

## 🎯 Propósito
Padronizar a criação de prompts reutilizáveis que agentes MANTIS possam carregar dinamicamente, reduzindo duplicação e garantindo consistência nas interações.

## 📋 Especificação (SDD)
- **Entradas**: Definição de prompt (nome, argumentos, template).
- **Saídas**: Mensagens formatadas prontas para serem injetadas em um modelo.
- **Side Effects**: Nenhum.
- **Constraints Aplicáveis**: C1 (schema do prompt), C5 (estrutura de saída), C7 (tratamento de argumentos inválidos), C8 (rastreio de uso).
- **Dependências**: `fastmcp`, `mcp`.

---

## 🛡️ Bootstrap (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Prompt Simples (Sem Argumentos)
```python
@mcp.prompt()
def summarize() -> list[dict]:
    """Template para resumir texto."""
    mantis_log("INFO", "prompt_loaded", "summarize")
    return [
        {"role": "system", "content": "Você é um assistente de resumos."},
        {"role": "user", "content": "Resuma o seguinte texto em até 3 frases."}
    ]
```

### 2. Prompt com Argumentos
```python
@mcp.prompt()
def code_review(language: str, focus: str = "security") -> list[dict]:
    """Template para revisão de código."""
    mantis_log("INFO", "prompt_loaded", f"code_review lang={language}, focus={focus}")
    return [
        {"role": "system", "content": f"Você é um revisor de código {language}."},
        {"role": "user", "content": f"Revise o código abaixo com foco em {focus}."}
    ]
```

### 3. Carregando Prompts no Cliente
```python
from langchain_mcp_adapters.client import MultiServerMCPClient

client = MultiServerMCPClient({...})

# Carregar prompt simples
messages = await client.get_prompt("server_name", "summarize")
for msg in messages:
    print(f"{msg.type}: {msg.content}")

# Carregar prompt com argumentos
messages = await client.get_prompt(
    "server_name",
    "code_review",
    arguments={"language": "python", "focus": "performance"}
)
```

### 4. Usando Prompt em um Fluxo de Agente
```python
from langchain.agents import create_agent

prompt_messages = await client.get_prompt("assistant", "customer_support", arguments={"product": "MANTIS"})
system_prompt = prompt_messages[0].content  # ou combinar conforme necessário

agent = create_agent(model="claude-sonnet-4-6", tools=[], system_prompt=system_prompt)
```

### 5. Prompts Dinâmicos Baseados em Contexto
- O servidor pode gerar o template com base em dados em tempo real.
```python
@mcp.prompt()
async def incident_report(incident_id: str) -> list[dict]:
    """Gera prompt para análise de incidente."""
    incident = await db.get_incident(incident_id)
    if not incident:
        raise ValueError(f"Incidente {incident_id} não encontrado")
    mantis_log("INFO", "prompt_generated", f"incident_report {incident_id}")
    return [
        {"role": "system", "content": "Você é um analista de incidentes."},
        {"role": "user", "content": f"Analise o incidente: {json.dumps(incident)}"}
    ]
```

### 6. Segurança: Validação de Argumentos
- Use Pydantic para validar argumentos de entrada.
```python
from pydantic import BaseModel, Field

class CodeReviewArgs(BaseModel):
    language: str = Field(..., pattern="^(python|java|go)$")
    focus: str = Field(default="security", pattern="^(security|performance|style)$")

@mcp.prompt()
async def safe_code_review(args: CodeReviewArgs) -> list[dict]:
    # args já validado
    ...
```

---

## 🧪 Testes Unitários (TDD)
```python
def test_summarize_prompt():
    messages = summarize()
    assert len(messages) == 2
    assert messages[0]["role"] == "system"

def test_code_review_prompt():
    messages = code_review("python", "security")
    assert "python" in messages[0]["content"]
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/mcp-prompts-management.md --json
```

---

## 🔗 Referências Cruzadas
- [[mcp-server-fundamentals.md]]
- [[mcp-resource-management.md]]
