---
artifact_id: "langchain-deploy-langserve"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/langchain-deploy-langserve.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/langchain-deploy-langserve.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:langchain-deploy-langserve-v1.0.0"
generated_at: "2026-05-26T16:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["langchain-deploy-express"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-26"
---

# 🚀 LangChain Deploy – LangServe API (Python)

> **Contrato modular**: Artefato filho do Master Agent. Ensina a expor chains e agentes LangChain como APIs REST usando LangServe e FastAPI, com streaming, health checks, Docker e deploy no Cloud Run.

---

## 🎯 Propósito
Permitir que o ecossistema MANTIS publique agentes e chains tradicionais como serviços web escaláveis, com documentação automática e tracing integrado.

## 📋 Especificação (SDD)
- **Entradas**: Chains compiladas, configuração FastAPI.
- **Saídas**: Servidor HTTP com endpoints `/invoke`, `/batch`, `/stream`.
- **Side Effects**: Execução de chains no servidor.
- **Constraints Aplicáveis**: C1 (schema de API), C3 (proteção de secrets), C5 (documentação automática), C7 (health checks), C8 (logs e tracing).
- **Dependências**: `langserve`, `fastapi`, `uvicorn`.

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

### 1. Servidor Mínimo com LangServe

```python
from fastapi import FastAPI
from langserve import add_routes
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

app = FastAPI(title="MANTIS LangChain API", version="1.0.0")

summarize_chain = (
    ChatPromptTemplate.from_template("Resuma em 3 frases: {text}")
    | ChatOpenAI(model="gpt-4o-mini", temperature=0)
    | StrOutputParser()
)

qa_chain = (
    ChatPromptTemplate.from_messages([
        ("system", "Responda baseado apenas no contexto fornecido."),
        ("human", "Contexto: {context}\n\nPergunta: {question}"),
    ])
    | ChatOpenAI(model="gpt-4o-mini")
    | StrOutputParser()
)

add_routes(app, summarize_chain, path="/summarize")
add_routes(app, qa_chain, path="/qa")

@app.get("/health")
async def health():
    return {"status": "healthy"}
```

### 2. Health Check Completo com Verificação de LLM

```python
@app.get("/health/detailed")
async def detailed_health():
    checks = {"server": "ok"}
    try:
        await ChatOpenAI(model="gpt-4o-mini", max_tokens=5).ainvoke("ping")
        checks["llm"] = "ok"
    except Exception as e:
        checks["llm"] = f"error: {e}"
    all_ok = all(v == "ok" for v in checks.values())
    return {"status": "healthy" if all_ok else "degraded", "checks": checks}
```

### 3. Dockerfile Otimizado

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD curl -f http://localhost:8000/health || exit 1
CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8000"]
```

### 4. Deploy no Google Cloud Run

```bash
gcloud run deploy mantis-langchain-api \
  --source . \
  --region us-central1 \
  --set-env-vars="OPENAI_API_KEY=$OPENAI_API_KEY,LANGCHAIN_TRACING_V2=true,LANGCHAIN_PROJECT=production" \
  --min-instances=1 \
  --max-instances=10 \
  --memory=1Gi \
  --timeout=60s
```

---

## 🧪 Testes Unitários (TDD)

```python
from fastapi.testclient import TestClient
from server import app

client = TestClient(app)

def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/langchain-deploy-langserve.md --json
```

---

## 🔗 Referências Cruzadas
- [[langchain-deploy-express.md]]
