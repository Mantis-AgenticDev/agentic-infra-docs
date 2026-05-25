---
artifact_id: "mcp-enterprise-deployment"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/mcp-enterprise-deployment.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/mcp-enterprise-deployment.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:mcp-enterprise-v1.0.0"
generated_at: "2026-05-25T01:40:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deploy-docker", "deploy-kubernetes", "security-guardrails"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🏭 MCP Enterprise Deployment – Segurança, Sessões e Versionamento

> **Contrato modular**: Aborda os aspectos críticos de produção: validação de Origin, sessões stateful, versionamento de protocolo e transporte customizado.

---

## 🎯 Propósito
Garantir que servidores MCP em produção atendam a requisitos de segurança, escalabilidade e compatibilidade, seguindo as especificações do protocolo e as constraints MANTIS.

## 📋 Especificação (SDD)
- **Entradas**: Configuração de deploy (HTTP, stdio), políticas de segurança.
- **Saídas**: Servidor MCP pronto para produção.
- **Side Effects**: Gerenciamento de sessões, logs de segurança.
- **Constraints**: C1 (versionamento), C2 (reprodutibilidade), C3 (proteção contra rebinding), C4 (isolamento de tenant), C5 (estrutura de respostas), C7 (resiliência), C8 (logs), C9 (trace).
- **Dependências**: `mcp`, `httpx`.

---

## 🛡️ Bootstrap (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Validação de Origin (C3)
```python
from starlette.middleware.base import BaseHTTPMiddleware

class OriginValidationMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        origin = request.headers.get("Origin")
        if origin and origin not in ["http://localhost:3000", "https://app.mantis.local"]:
            mantis_log("ERROR", "invalid_origin", f"Origem bloqueada: {origin}")
            return Response(status_code=403)
        return await call_next(request)
```

### 2. Sessões Stateful com MCP‑Session‑Id
```python
# O servidor deve retornar um Session-Id na inicialização
@app.post("/mcp")
async def initialize(request: Request):
    session_id = str(uuid.uuid4())
    response = JSONResponse(content=initialize_result.dict())
    response.headers["MCP-Session-Id"] = session_id
    return response

# Validar em chamadas subsequentes
session_id = request.headers.get("MCP-Session-Id")
if not session_id or session_id not in active_sessions:
    return JSONResponse(status_code=404)
```

### 3. Versionamento do Protocolo
```python
MCP_PROTOCOL_VERSION = "2025-11-25"

@app.middleware("http")
async def add_version_header(request: Request, call_next):
    response = await call_next(request)
    response.headers["MCP-Protocol-Version"] = MCP_PROTOCOL_VERSION
    return response
```

### 4. Transporte Customizado (exemplo WebSocket)
- Embora não seja padrão, é possível implementar um transporte customizado respeitando o formato JSON‑RPC e o lifecycle do MCP.

### 5. Boas Práticas de Segurança
- Bind apenas em localhost para servidores locais.
- Use HTTPS com certificados válidos em produção.
- Implemente rate limiting.
- Armazene tokens de sessão de forma segura (HTTPOnly, Secure).

### 6. Exemplo de Dockerfile
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY . .
RUN pip install -r requirements.txt
CMD ["python", "server.py"]
```

---

## 🧪 Testes Unitários (TDD)
```python
def test_origin_validation():
    middleware = OriginValidationMiddleware(app)
    # Testar com origin inválido...
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/mcp-enterprise-deployment.md --json
```

---

## 🔗 Referências Cruzadas
- [[mcp-server-fundamentals.md]]
- [[security-guardrails.md]]
