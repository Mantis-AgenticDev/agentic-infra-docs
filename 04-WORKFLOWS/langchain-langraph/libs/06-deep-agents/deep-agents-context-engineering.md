---
artifact_id: "deep-agents-context-engineering"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-context-engineering.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-context-engineering-v1.0.0"
generated_at: "2026-05-25T19:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-core-customization", "deep-agents-deployment-production"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 📐 Deep Agents – Context Engineering (Gestão de Contexto)

> **Contrato modular**: Artefato filho do Master Agent. Detalha técnicas para gerenciar o contexto do agente: sumarização automática, offloading para arquivos, limites de tokens e estratégias para evitar estouro de janela.

---

## 🎯 Propósito
Garantir que agentes MANTIS operem dentro dos limites de contexto dos modelos, mantendo desempenho e evitando perda de informações críticas.

## 📋 Especificação (SDD)
- **Entradas**: Configuração de `SummarizationMiddleware`, limites de tokens.
- **Saídas**: Agente que gerencia automaticamente o tamanho do histórico.
- **Side Effects**: Resumos gerados e armazenados; arquivos offloaded.
- **Constraints Aplicáveis**: C1 (limites configuráveis), C5 (preservação de informações), C7 (recuperação de contexto), C8 (logs de sumarização).
- **Dependências**: `deepagents`, `langchain.agents.middleware`.

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

### 1. Sumarização Automática com SummarizationMiddleware

```python
from deepagents import create_deep_agent

# SummarizationMiddleware incluído por padrão.
# Ele condensa o histórico de mensagens quando o contexto se aproxima do limite.
# Para modelos Anthropic, AnthropicPromptCachingMiddleware também é adicionado.

agent = create_deep_agent(model="anthropic:claude-sonnet-4-6")
# O agente automaticamente resume quando necessário.
```

### 2. Configurar Comportamento de Sumarização

```python
from langchain.agents.middleware.summarization import SummarizationMiddleware

# Configuração explícita
agent = create_deep_agent(
    model="openai:gpt-5.4",
    middleware=[
        SummarizationMiddleware(
            model="openai:gpt-5.4",  # Modelo para gerar resumos
            max_tokens=8000,          # Limiar para acionar sumarização
            max_summary_tokens=2000,  # Tamanho máximo do resumo
        ),
    ],
)
```

### 3. Offloading de Grandes Saídas para Arquivos

```python
# Arquivos de saída de ferramentas grandes são automaticamente movidos para
# o backend (ex: StateBackend) e substituídos por uma referência.
# O agente pode ler o arquivo depois com read_file.

agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    backend=StateBackend(),
)
# Saída de uma busca web com 50KB será salva em /large_tool_results/ e referenciada.
```

### 4. Estratégia de Offloading Manual via Prompt

```python
system_prompt="""Quando você receber grandes quantidades de dados:
1. Salve os dados brutos em /workspace/data.txt usando write_file.
2. Processe e analise os dados.
3. Retorne apenas o resumo da análise.

Isso mantém o contexto limpo e evita estouro de tokens."""
```

### 5. Monitoramento de Uso de Tokens

```python
from langchain_anthropic import ChatAnthropic

llm = ChatAnthropic(model="claude-sonnet-4-6")
agent = create_deep_agent(model=llm)

# Após cada invocação, é possível verificar usage_metadata
result = agent.invoke({"messages": [{"role": "user", "content": "Pesquise sobre IA"}]})
last_msg = result["messages"][-1]
if hasattr(last_msg, 'usage_metadata'):
    tokens = last_msg.usage_metadata
    mantis_log("INFO", "token_usage", f"Input: {tokens.get('input_tokens')}, Output: {tokens.get('output_tokens')}")
```

### 6. Contexto Compartilhado com Subagentes

```python
# Subagentes têm seu próprio contexto isolado.
# O agente principal pode passar instruções e receber resumos.
# Para passar contexto adicional, use o parâmetro `context` na invocação.

@dataclass
class Context:
    user_id: str
    project_id: str

agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    context_schema=Context,
    subagents=[...],
)
result = agent.invoke(
    {"messages": [...]},
    context=Context(user_id="user-123", project_id="proj-456"),
)
```

### 7. Histórico de Conversa Longo: Estratégias

```python
# 1. Sumarização (automática)
# 2. Subagentes para isolar trabalhos detalhados
# 3. Offloading para arquivos
# 4. Uso de memory de longo prazo para fatos recorrentes
# 5. Limitar número de ferramentas expostas
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_summarization_middleware():
    mw = SummarizationMiddleware(model="openai:gpt-5.4")
    assert mw is not None

def test_context_schema():
    @dataclass
    class Ctx:
        user_id: str
    agent = create_deep_agent(model="openai:gpt-5.4", context_schema=Ctx)
    assert agent is not None
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-context-engineering.md --json
```

---

## 🔗 Referências Cruzadas
- [[deep-agents-core-customization.md]]
- [[deep-agents-deployment-production.md]]
