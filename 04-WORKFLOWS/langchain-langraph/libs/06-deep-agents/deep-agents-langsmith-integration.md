---
artifact_id: "deep-agents-langsmith-integration"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C5","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-langsmith-integration.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-langsmith-integration.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-langsmith-v1.0.0"
generated_at: "2026-05-25T21:45:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-deployment-production"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🔍 Deep Agents – Integração com LangSmith (Tracing, Datasets e Avaliação)

> **Contrato modular**: Artefato filho do Master Agent. Detalha a integração de Deep Agents com LangSmith para tracing automático, datasets de avaliação e feedback humano.

---

## 🎯 Propósito
Garantir visibilidade total sobre a execução dos agentes MANTIS, permitindo depuração, avaliação e melhoria contínua através do LangSmith.

## 📋 Especificação (SDD)
- **Entradas**: Credenciais LangSmith, configuração de tracing.
- **Saídas**: Traces, métricas e avaliações.
- **Side Effects**: Envio de dados para LangSmith.
- **Constraints Aplicáveis**: C1 (schema de trace), C5 (dados de avaliação), C8 (observabilidade), C9 (tracing distribuído).
- **Dependências**: `langsmith`, `deepagents`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Configuração de Tracing Automático

```python
import os
os.environ["LANGCHAIN_TRACING_V2"] = "true"
os.environ["LANGCHAIN_API_KEY"] = "ls__..."
os.environ["LANGCHAIN_PROJECT"] = "mantis-deep-agents"

# A partir daqui, todos os agentes são traceados automaticamente.
agent = create_deep_agent(model="openai:gpt-5.4")
result = agent.invoke({"messages": [{"role": "user", "content": "Teste"}]})
# Trace disponível em https://smith.langchain.com
```

### 2. Criação de Datasets para Avaliação

```python
from langsmith import Client

client = Client()

dataset = client.create_dataset("deep-agent-qa")
client.create_examples(
    inputs=[
        {"question": "Qual é a capital do Brasil?"},
        {"question": "Explique o que é RAG."},
        {"question": "Como criar um subagente?"},
    ],
    outputs=[
        {"answer": "Brasília"},
        {"answer": "RAG é Retrieval Augmented Generation..."},
        {"answer": "Use o parâmetro subagents em create_deep_agent..."},
    ],
    dataset_id=dataset.id,
)
```

### 3. Avaliação Automatizada

```python
from langsmith.evaluation import run_evaluator

def evaluate_agent(question: str, answer: str):
    # Avaliar com métricas customizadas
    return {
        "length": len(answer),
        "has_sources": "fonte" in answer.lower(),
    }

run_evaluator(
    client,
    dataset_name="deep-agent-qa",
    llm_or_chain_factory=lambda: agent,
    evaluation=evaluate_agent,
)
```

### 4. Feedback Humano

```python
# Registrar feedback do usuário sobre uma resposta
await client.create_feedback(
    run_id="run-abc123",
    key="user_satisfaction",
    score=0.8,
    comment="Resposta correta, mas muito longa.",
)
```

### 5. Anotação de Traces com Metadados

```python
from langsmith import traceable

@traceable(metadata={"component": "agent-core", "version": "1.0.0"})
def invoke_agent(agent, query):
    return agent.invoke({"messages": [{"role": "user", "content": query}]})
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_langsmith_env():
    import os
    assert os.getenv("LANGCHAIN_TRACING_V2") == "true"
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-langsmith-integration.md --json
```

---

## 🔗 Referências Cruzadas
- [[deep-agents-deployment-production.md]]
