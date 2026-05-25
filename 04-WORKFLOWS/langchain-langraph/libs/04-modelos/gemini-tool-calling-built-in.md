---
artifact_id: "gemini-tool-calling-built-in"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/gemini-tool-calling-built-in.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/gemini-tool-calling-built-in.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:gemini-builtin-tools-v1.0.0"
generated_at: "2026-05-25T07:20:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["google-genai-multimodal", "agents-single"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🔧 Gemini Built‑in Tools – Google Search, Maps, Code Execution e Mais

> **Contrato modular**: Detalha como usar as ferramentas nativas do Gemini (Google Search, Maps, URL Context, Code Execution, Computer Use) como se fossem tools normais do LangChain.

---

## 🎯 Propósito
Enriquecer os agentes MANTIS com capacidades de busca na web, mapas, execução de código e controle de navegador diretamente via Gemini, sem necessidade de APIs externas adicionais.

## 📋 Especificação (SDD)
- **Entradas**: Descrição da ferramenta nativa (`{"google_search": {}}`, etc.).
- **Saídas**: Resposta enriquecida com grounding/citações, resultado de código, etc.
- **Side Effects**: Custo adicional, latência.
- **Constraints**: C1 (formato de tool), C3 (cuidado com dados sensíveis em busca), C7 (tratamento de falha na ferramenta).
- **Dependências**: `langchain-google-genai`.

---

## 🛡️ Bootstrap (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Google Search
```python
model = ChatGoogleGenerativeAI(model="gemini-3.5-flash")
model_with_search = model.bind_tools([{"google_search": {}}])
response = model_with_search.invoke("Quando será o próximo eclipse solar nos EUA?")
# Citações aparecem em content_blocks[].annotations
```

### 2. Google Maps
```python
model_with_maps = model.bind_tools([{"google_maps": {}}])
response = model_with_maps.invoke("Restaurantes italianos perto da Torre Eiffel")
```

### 3. URL Context
```python
model_with_url = model.bind_tools([{"url_context": {}}])
response = model_with_url.invoke("Resuma o conteúdo de https://docs.langchain.com")
```

### 4. Code Execution
```python
model_code = model.bind_tools([{"code_execution": {}}])
response = model_code.invoke("Use Python para calcular 3^3")
# O resultado da execução aparece nos blocos de resposta
```

### 5. Computer Use (Preview)
```python
model_cu = ChatGoogleGenerativeAI(model="gemini-2.5-computer-use-preview-10-2025")
model_cu_tools = model_cu.bind_tools([{"computer_use": {}}])
response = model_cu_tools.invoke("Navegue até example.com")
# Retorna ações como click_at, type_text
```

---

## 🧪 Testes Unitários (TDD)
```python
def test_google_search_bind():
    model = ChatGoogleGenerativeAI(model="gemini-3.5-flash")
    tools = model.bind_tools([{"google_search": {}}])
    assert tools is not None
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/gemini-tool-calling-built-in.md --json
```

---

## 🔗 Referências Cruzadas
- [[google-genai-multimodal.md]]
