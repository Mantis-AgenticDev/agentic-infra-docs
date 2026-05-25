---
artifact_id: "google-genai-multimodal"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/google-genai-multimodal.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/google-genai-multimodal.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:google-genai-multimodal-v1.0.0"
generated_at: "2026-05-25T06:50:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["rag-multi-modal", "file-processing"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🖼️ Google Gemini Multimodal – Imagem, Áudio, Vídeo e PDF

> **Contrato modular**: Focado nos recursos multimodais do Gemini via `ChatGoogleGenerativeAI`, incluindo upload de arquivos, entrada de imagem/áudio/vídeo e geração de imagens/áudio.

---

## 🎯 Propósito
Habilitar agentes MANTIS a processar e gerar conteúdo multimídia usando os modelos Gemini.

## 📋 Especificação (SDD)
- **Entradas**: Arquivos multimídia (URL, base64, upload).
- **Saídas**: Texto descritivo, imagens geradas, áudio gerado.
- **Constraints**: C1 (formatos suportados), C3 (dados sensíveis), C5 (metadados), C7 (timeout de upload), C8 (logs).
- **Dependências**: `langchain-google-genai`, `google-genai`.

---

## 🛡️ Bootstrap (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Entrada de Imagem (URL e Base64)
```python
from langchain.messages import HumanMessage
from langchain_google_genai import ChatGoogleGenerativeAI

model = ChatGoogleGenerativeAI(model="gemini-3.5-flash")
message = HumanMessage(content=[
    {"type": "text", "text": "Descreva esta imagem."},
    {"type": "image", "url": "https://example.com/foto.jpg"}
])
response = model.invoke([message])
```

### 2. Upload de Arquivo e Referência
```python
from google import genai
client = genai.Client()
myfile = client.files.upload(file="/path/to/video.mp4")
# Aguardar processamento...
message = HumanMessage(content=[
    {"type": "text", "text": "Resuma o vídeo."},
    {"type": "file", "file_id": myfile.uri, "mime_type": "video/mp4"}
])
response = model.invoke([message])
```

### 3. Geração de Imagens com `gemini-2.5-flash-image`
```python
model_img = ChatGoogleGenerativeAI(model="gemini-2.5-flash-image")
response = model_img.invoke("Gere uma imagem de um gato usando chapéu.")
# Extrair base64 da resposta
```

### 4. Geração de Áudio (TTS)
```python
model_tts = ChatGoogleGenerativeAI(model="gemini-2.5-flash-preview-tts")
response = model_tts.invoke("Diga 'olá mundo'.")
audio_data = response.additional_kwargs["audio"]
```

---

## 🧪 Testes Unitários (TDD)
```python
def test_image_input():
    msg = HumanMessage(content=[{"type": "image", "url": "http://x.com/i.jpg"}])
    # não invoca API real, apenas testa construção
    assert msg.content[0]["type"] == "image"
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/google-genai-multimodal.md --json
```

---

## 🔗 Referências Cruzadas
- [[rag-multi-modal.md]]
