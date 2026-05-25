---
artifact_id: "openrouter-multimodal-inputs"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/openrouter-multimodal-inputs.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/openrouter-multimodal-inputs.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:openrouter-multimodal-v1.0.0"
generated_at: "2026-05-25T07:00:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["multi-model-openrouter-integration", "rag-multi-modal"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🎥 OpenRouter Multimodal Inputs – Imagens, Áudio, Vídeo e PDFs

> **Contrato modular**: Demonstra como enviar entradas multimodais (imagem, áudio, vídeo, PDF) via `ChatOpenRouter`, aproveitando a compatibilidade com modelos como GPT‑4o, Gemini e Claude.

---

## 🎯 Propósito
Permitir que agentes MANTIS processem conteúdos além de texto, utilizando a API unificada do OpenRouter para modelos com capacidades visuais e auditivas.

## 📋 Especificação (SDD)
- **Entradas**: URLs ou dados base64 de imagens, áudios, vídeos, PDFs.
- **Saídas**: Respostas textuais do modelo.
- **Side Effects**: Custo adicional de tokens para mídia.
- **Constraints Aplicáveis**: C1 (formato de mensagem), C3 (não enviar dados sensíveis sem criptografia), C5 (metadados do conteúdo), C7 (tratamento de tipos não suportados), C8 (logs).
- **Dependências**: `langchain-openrouter`, `httpx`.

---

## 🛡️ Bootstrap (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    import json, datetime, os
    def mantis_log(level, event, detail=""):
        entry = {"ts": datetime.datetime.utcnow().isoformat() + "Z", "level": level, "tenant": os.getenv("TENANT_ID", "global"), "event": event, "detail": detail, "trace_id": os.getenv("TRACE_ID", "null"), "span_id": os.getenv("SPAN_ID", "null"), "fallback": "true"}
        print(json.dumps(entry), flush=True)
```

### 1. Imagem via URL
```python
from langchain.messages import HumanMessage
model = ChatOpenRouter(model="openai/gpt-4o")
message = HumanMessage(content=[
    {"type": "text", "text": "Descreva esta imagem."},
    {"type": "image", "url": "https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/Gfp-wisconsin-madison-the-nature-boardwalk.jpg/2560px-Gfp-wisconsin-madison-the-nature-boardwalk.jpg"}
])
response = model.invoke([message])
mantis_log("INFO", "image_url", "Imagem processada")
```

### 2. Imagem via Base64
```python
import base64, httpx
image_data = base64.b64encode(httpx.get("https://picsum.photos/200/300", follow_redirects=True).content).decode("utf-8")
message = HumanMessage(content=[
    {"type": "text", "text": "Descreva a imagem."},
    {"type": "image", "base64": image_data, "mime_type": "image/jpeg"}
])
```

### 3. Áudio (Base64)
```python
audio_bytes = open("audio.wav", "rb").read()
audio_base64 = base64.b64encode(audio_bytes).decode()
message = HumanMessage(content=[
    {"type": "text", "text": "Transcreva este áudio."},
    {"type": "audio", "base64": audio_base64, "mime_type": "audio/wav"}
])
```

### 4. Vídeo e PDF (similar, usando `type: "video"` e `type: "file"`)
```python
# PDF como file
message = HumanMessage(content=[
    {"type": "text", "text": "Resuma este documento."},
    {"type": "file", "url": "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf", "mime_type": "application/pdf"}
])
```

### 5. Verificação de Suporte do Modelo
```python
MODELS_WITH_VISION = ["gpt-4o", "claude-sonnet", "gemini"]
if not any(m in model.model_name for m in MODELS_WITH_VISION):
    mantis_log("WARN", "multimodal_unsupported", f"Modelo {model.model_name} pode não suportar visão")
```

---

## 🧪 Testes Unitários (TDD)
```python
def test_multimodal_message_structure():
    msg = HumanMessage(content=[{"type": "image", "url": "http://example.com/img.jpg"}])
    assert msg.content[0]["type"] == "image"
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/openrouter-multimodal-inputs.md --json
```

---

## 🔗 Referências Cruzadas
- [[multi-model-openrouter-integration.md]]
- [[rag-multi-modal.md]]
