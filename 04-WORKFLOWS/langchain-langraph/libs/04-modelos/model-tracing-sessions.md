---
artifact_id: "model-tracing-sessions"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C5","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/model-tracing-sessions.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/model-tracing-sessions.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:model-tracing-v1.0.0"
generated_at: "2026-05-25T06:30:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["multi-model-openrouter-integration", "observability-langsmith"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🔍 Model Tracing & Sessions – Rastreabilidade com OpenRouter e LangSmith

> **Contrato modular**: Explica como usar `session_id` e `trace` para agrupar requisições, correlacionar com o tracing distribuído (C9) e exportar telemetria.

---

## 🎯 Propósito
Vincular cada chamada de modelo a um contexto de negócio (workflow, tenant) para auditoria e depuração.

## 📋 Especificação (SDD)
- **Entradas**: `session_id`, `trace` dict.
- **Saídas**: Metadados de rastreamento propagados para OpenRouter e LangSmith.
- **Constraints**: C5 (formato de trace), C8 (logs enriquecidos), C9 (trace_id consistente).
- **Dependências**: `langchain-openrouter`, `langsmith`.

---

## 🛡️ Bootstrap (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Agrupamento com `session_id`
```python
model = ChatOpenRouter(
    model="anthropic/claude-sonnet-4.5",
    session_id="workflow-abc-123",
)
# Pode ser sobrescrito por chamada:
model.invoke("...", session_id="workflow-abc-123-step-1")
```

### 2. Metadados de Trace
```python
model = ChatOpenRouter(
    model="anthropic/claude-sonnet-4.5",
    trace={
        "trace_id": "trace-789",
        "span_name": "summarize",
        "parent_span_id": os.getenv("SPAN_ID"),
    },
)
```

### 3. Integração com LangSmith e C9
- O `trace_id` do OpenRouter deve corresponder ao `trace_id` do agente MANTIS.
- Configure `LANGSMITH_TRACING=true` e `LANGSMITH_API_KEY`.

### 4. Exemplo Completo
```python
os.environ["LANGCHAIN_TRACING_V2"] = "true"
os.environ["LANGCHAIN_API_KEY"] = "ls__..."
os.environ["OPENROUTER_API_KEY"] = "sk-or-..."
model = ChatOpenRouter(
    model="anthropic/claude-sonnet-4.5",
    session_id="task-42",
    trace={"trace_id": "abc", "span_name": "agent_step"},
)
```

---

## 🧪 Testes Unitários (TDD)
```python
def test_session_id():
    m = ChatOpenRouter(model="a", session_id="s1")
    assert m.session_id == "s1"
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/model-tracing-sessions.md --json
```

---

## 🔗 Referências Cruzadas
- [[multi-model-openrouter-integration.md]]
- [[observability-langsmith.md]]
