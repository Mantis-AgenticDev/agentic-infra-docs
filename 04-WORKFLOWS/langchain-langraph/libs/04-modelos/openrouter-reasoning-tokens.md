---
artifact_id: "openrouter-reasoning-tokens"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/openrouter-reasoning-tokens.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/openrouter-reasoning-tokens.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:openrouter-reasoning-v1.0.0"
generated_at: "2026-05-25T07:10:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["multi-model-openrouter-integration", "agents-single"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🧠 OpenRouter Reasoning Tokens – Raciocínio e Pensamento Estruturado

> **Contrato modular**: Explora o uso de reasoning tokens (cadeia de pensamento) via OpenRouter, incluindo controle de esforço, sumarização e extração do raciocínio.

---

## 🎯 Propósito
Permitir que agentes MANTIS invoquem modelos com raciocínio interno (Claude Sonnet, DeepSeek‑R1, o3) para tarefas complexas, obtendo o passo a passo quando necessário.

## 📋 Especificação (SDD)
- **Entradas**: Parâmetros `reasoning` (effort, summary).
- **Saídas**: Resposta final + tokens de raciocínio.
- **Side Effects**: Maior consumo de tokens de saída.
- **Constraints**: C1 (schema de reasoning), C5 (estrutura de content_blocks), C7 (fallback se modelo não suportar), C8 (métricas de reasoning).
- **Dependências**: `langchain-openrouter`.

---

## 🛡️ Bootstrap (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Ativação de Reasoning
```python
model = ChatOpenRouter(
    model="anthropic/claude-sonnet-4.5",
    reasoning={"effort": "high", "summary": "auto"},
)
ai_msg = model.invoke("Qual é a raiz quadrada de 529?")
# Acessar reasoning blocks
for block in ai_msg.content_blocks:
    if block["type"] == "reasoning":
        print(block["reasoning"])
```

### 2. Níveis de Esforço
- `"xhigh"`, `"high"`, `"medium"`, `"low"`, `"minimal"`, `"none"`.

### 3. Sumarização
- `"auto"` (padrão), `"concise"`, `"detailed"`.

### 4. Métricas de Tokens de Reasoning
```python
print(ai_msg.usage_metadata['output_token_details']['reasoning'])
```

---

## 🧪 Testes Unitários (TDD)
```python
def test_reasoning_config():
    m = ChatOpenRouter(model="anthropic/claude-sonnet-4.5", reasoning={"effort": "low"})
    assert m.reasoning["effort"] == "low"
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/openrouter-reasoning-tokens.md --json
```

---

## 🔗 Referências Cruzadas
- [[multi-model-openrouter-integration.md]]
