---
artifact_id: "model-selection-strategy"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/model-selection-strategy.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/model-selection-strategy.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:model-selection-v1.0.0"
generated_at: "2026-05-25T08:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["agents-swarm-routing", "cost-optimization"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# ⚖️ Model Selection Strategy – Matriz de Decisão para Escolha de Modelos

> **Contrato modular**: Define uma estratégia sistemática para que os agentes MANTIS escolham o modelo de IA mais adequado com base em critérios como custo, latência, capacidade multimodal e complexidade da tarefa.

---

## 🎯 Propósito
Evitar o uso indiscriminado de modelos caros ou lentos, otimizando recursos e garantindo a melhor experiência.

## 📋 Especificação (SDD)
- **Entradas**: Tipo de tarefa, requisitos de multimodalidade, orçamento.
- **Saídas**: Nome do modelo e configuração.
- **Side Effects**: Nenhum.
- **Constraints**: C1 (matriz de decisão), C5 (documentação), C7 (fallback para modelo padrão).
- **Dependências**: Nenhuma.

---

## 🛡️ Bootstrap (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Matriz de Decisão
| Critério | Modelo Recomendado | Alternativa de Baixo Custo |
|----------|-------------------|----------------------------|
| Texto simples | `deepseek-chat` | `qwen-flash` |
| Raciocínio complexo | `anthropic/claude-sonnet-4.5` | `deepseek-reasoner` |
| Multimodal (imagem) | `openai/gpt-4o` | `qwen-vl-max` |
| Áudio/Vídeo | `google/gemini-3.5-flash` | `qwen-vl-max` |
| Busca na web integrada | `gemini-3.5-flash` (Search) | – |
| Tarefas de código | `openai/gpt-4.1` | `deepseek-chat` |
| Baixíssimo custo | `meta-llama/llama-4-maverick` | `qwen-flash` |

### 2. Função de Seleção
```python
def select_model(task_type: str, budget: str = "balanced") -> str:
    if task_type == "reasoning" and budget == "high":
        return "anthropic/claude-sonnet-4.5"
    elif task_type == "multimodal":
        return "openai/gpt-4o"
    else:
        return "deepseek-chat"  # padrão econômico
```

### 3. Fallback Dinâmico
- Se o modelo selecionado falhar, tentar o próximo da lista ordenada por prioridade.

---

## 🧪 Testes Unitários (TDD)
```python
def test_selection():
    assert select_model("reasoning", "high") == "anthropic/claude-sonnet-4.5"
    assert select_model("text") == "deepseek-chat"
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/model-selection-strategy.md --json
```

---

## 🔗 Referências Cruzadas
- [[multi-model-openrouter-integration.md]]
- [[cost-optimization.md]]
