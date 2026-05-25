---
artifact_id: "gemini-thinking-safety"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/gemini-thinking-safety.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/gemini-thinking-safety.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:gemini-thinking-safety-v1.0.0"
generated_at: "2026-05-25T07:30:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["google-genai-multimodal", "gemini-tool-calling-built-in"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🧠🧯 Gemini Thinking & Safety – Controle de Raciocínio e Bloqueios

> **Contrato modular**: Demonstra como ajustar o nível de pensamento dos modelos Gemini (thinking_level/thinking_budget) e configurar safety settings para evitar bloqueios indesejados.

---

## 🎯 Propósito
Permitir que os agentes MANTIS controlem a profundidade do raciocínio do Gemini e ajustem os limiares de segurança de acordo com o domínio da aplicação.

## 📋 Especificação (SDD)
- **Entradas**: Parâmetros `thinking_level` (Gemini 3+) ou `thinking_budget` (2.5), `safety_settings`.
- **Saídas**: Respostas com ou sem raciocínio visível.
- **Constraints**: C1 (valores permitidos), C3 (conteúdo bloqueado), C7 (tratamento de bloqueio de segurança).
- **Dependências**: `langchain-google-genai`.

---

## 🛡️ Bootstrap (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Thinking Level (Gemini 3+)
```python
model = ChatGoogleGenerativeAI(model="gemini-3.5-flash", thinking_level="low")
```

### 2. Thinking Budget (Gemini 2.5)
```python
model = ChatGoogleGenerativeAI(model="gemini-2.5-flash", thinking_budget=1024)
```

### 3. Visualização de Pensamentos
```python
model = ChatGoogleGenerativeAI(model="gemini-3.5-flash", include_thoughts=True)
response = model.invoke("Quantos 'o's tem em Google?")
# Pensamentos aparecem nos blocos de conteúdo
print(response.usage_metadata['output_token_details']['reasoning'])
```

### 4. Thought Signatures
- Assinaturas são propagadas automaticamente para manter contexto multi‑turno.
- Atenção ao reconstruir mensagens manualmente (não perca as assinaturas).

### 5. Safety Settings
```python
from langchain_google_genai import ChatGoogleGenerativeAI, HarmBlockThreshold, HarmCategory

model = ChatGoogleGenerativeAI(
    model="gemini-3.5-flash",
    safety_settings={
        HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT: HarmBlockThreshold.BLOCK_NONE,
    }
)
```

---

## 🧪 Testes Unitários (TDD)
```python
def test_thinking_level():
    m = ChatGoogleGenerativeAI(model="gemini-3.5-flash", thinking_level="medium")
    assert m.thinking_level == "medium"
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/gemini-thinking-safety.md --json
```

---

## 🔗 Referências Cruzadas
- [[gemini-tool-calling-built-in.md]]
