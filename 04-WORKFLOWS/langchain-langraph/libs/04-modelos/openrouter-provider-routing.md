---
artifact_id: "openrouter-provider-routing"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/openrouter-provider-routing.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/openrouter-provider-routing.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:openrouter-routing-v1.0.0"
generated_at: "2026-05-25T06:10:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["multi-model-openrouter-integration", "cost-optimization"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🚦 OpenRouter Provider Routing – Seleção de Provedor, Custo e Latência

> **Contrato modular**: Ensina a controlar qual provedor executa o modelo, otimizando por custo, throughput ou latência, além de impor políticas de coleta de dados.

---

## 🎯 Propósito
Dar aos agentes MANTIS o poder de escolher o melhor provedor para cada requisição, garantindo desempenho e conformidade com restrições de custo e privacidade.

## 📋 Especificação (SDD)
- **Entradas**: Configuração `openrouter_provider`.
- **Saídas**: Requisições roteadas para provedores específicos.
- **Side Effects**: Redução de custo, variação de latência.
- **Constraints**: C1 (ordem e fallback), C3 (proteção de dados), C7 (fallback automático).
- **Dependências**: `langchain-openrouter`.

---

## 🛡️ Bootstrap (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Ordenação de Provedores
```python
model = ChatOpenRouter(
    model="anthropic/claude-sonnet-4.5",
    openrouter_provider={
        "order": ["Anthropic", "Google"],
        "allow_fallbacks": True,
    },
)
```

### 2. Restringir Provedores (Only/Ignore)
```python
# Apenas OpenAI e Azure
model = ChatOpenRouter(
    model="openai/gpt-4o",
    openrouter_provider={"only": ["OpenAI", "Azure"]},
)
# Excluir DeepInfra
model = ChatOpenRouter(
    model="meta-llama/llama-4-maverick",
    openrouter_provider={"ignore": ["DeepInfra"]},
)
```

### 3. Ordenação por Throughput ou Latência
```python
# Prefere maior tokens/segundo
model = ChatOpenRouter(model="openai/gpt-4o", openrouter_provider={"sort": "throughput"})
# Prefere menor latência
model = ChatOpenRouter(model="openai/gpt-4o", openrouter_provider={"sort": "latency"})
```

### 4. Política de Coleta de Dados
```python
model = ChatOpenRouter(
    model="anthropic/claude-sonnet-4.5",
    openrouter_provider={"data_collection": "deny"},
)
```

### 5. Filtro por Quantização (Modelos Abertos)
```python
model = ChatOpenRouter(
    model="meta-llama/llama-4-maverick",
    openrouter_provider={"quantizations": ["fp16", "bf16"]},
)
```

### 6. Combinação de Opções
```python
model = ChatOpenRouter(
    model="openai/gpt-4o",
    openrouter_provider={
        "order": ["OpenAI", "Azure"],
        "allow_fallbacks": False,
        "require_parameters": True,
        "data_collection": "deny",
    },
)
```

---

## 🧪 Testes Unitários (TDD)
```python
def test_provider_config():
    m = ChatOpenRouter(model="a", openrouter_provider={"sort": "throughput"})
    assert "throughput" in str(m.openrouter_provider)
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/openrouter-provider-routing.md --json 
```

---

## 🔗 Referências Cruzadas
- [[multi-model-openrouter-integration.md]]
- [[cost-optimization.md]]
