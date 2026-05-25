---
artifact_id: "mcp-oauth2-authentication"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/mcp-oauth2-authentication.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/mcp-oauth2-authentication.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:mcp-oauth2-v1.0.0"
generated_at: "2026-05-25T05:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["mcp-enterprise-deployment", "security-guardrails"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🔐 MCP OAuth2 Authentication – Fluxos de Autenticação e Autorização

> **Contrato modular**: Define como implementar autenticação OAuth2 em servidores e clientes MCP, protegendo endpoints e garantindo que apenas clientes autorizados possam invocar ferramentas e acessar recursos.

---

## 🎯 Propósito
Permitir que servidores MCP no ecossistema MANTIS adotem OAuth2 (Authorization Code, Client Credentials) para autenticação de clientes, integrando com provedores de identidade corporativos.

## 📋 Especificação (SDD)
- **Entradas**: Configuração de OAuth2 (client ID, secret, endpoints).
- **Saídas**: Tokens de acesso validados, headers de autorização propagados.
- **Side Effects**: Chamadas ao provedor de identidade, renovação de tokens.
- **Constraints Aplicáveis**: C1 (contrato de autenticação), C3 (proteção de secrets), C4 (tenant isolation), C5 (formato de token), C7 (retry em falhas de autenticação), C8 (logs de auditoria).
- **Dependências**: `httpx`, `oauthlib`, `python-jose`.

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

### 1. Fluxo Client Credentials (Servidor → Servidor)
```python
import httpx
from oauthlib.oauth2 import BackendApplicationClient
from oauthlib.oauth2.rfc6749.tokens import BearerToken

async def get_client_credentials_token():
    client = BackendApplicationClient(client_id=os.getenv("OAUTH_CLIENT_ID"))
    async with httpx.AsyncClient() as http_client:
        token_response = await http_client.post(
            os.getenv("OAUTH_TOKEN_URL"),
            data={
                "grant_type": "client_credentials",
                "client_id": os.getenv("OAUTH_CLIENT_ID"),
                "client_secret": os.getenv("OAUTH_CLIENT_SECRET"),
                "scope": "mcp:tools"
            }
        )
        token_response.raise_for_status()
        token = token_response.json()
        mantis_log("INFO", "token_obtained", f"Expires in {token.get('expires_in')}s")
        return token["access_token"]

# Uso em headers do MultiServerMCPClient
client = MultiServerMCPClient({
    "secure": {
        "transport": "http",
        "url": "https://mcp.internal/mcp",
        "headers": {"Authorization": f"Bearer {await get_client_credentials_token()}"}
    }
})
```

### 2. Validação de Token no Servidor
```python
from jose import jwt, JWTError
import os

async def validate_token(token: str):
    try:
        payload = jwt.decode(
            token,
            os.getenv("OAUTH_PUBLIC_KEY"),
            algorithms=["RS256"],
            audience="mcp-server"
        )
        mantis_log("INFO", "token_valid", f"Subject: {payload.get('sub')}")
        return payload
    except JWTError as e:
        mantis_log("SECURITY", "invalid_token", str(e))
        raise HTTPException(status_code=401, detail="Token inválido")
```

### 3. Middleware de Autenticação no Servidor HTTP
```python
from starlette.middleware.base import BaseHTTPMiddleware

class OAuth2Middleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        auth_header = request.headers.get("Authorization")
        if not auth_header or not auth_header.startswith("Bearer "):
            mantis_log("SECURITY", "missing_auth", "Sem token")
            return JSONResponse(status_code=401, content={"detail": "Token ausente"})
        token = auth_header.split(" ")[1]
        try:
            payload = await validate_token(token)
            request.state.tenant_id = payload.get("tenant_id", "global")
        except Exception:
            return JSONResponse(status_code=401, content={"detail": "Token inválido"})
        return await call_next(request)
```

### 4. Renovação Automática de Token
```python
from datetime import datetime, timedelta

class TokenManager:
    def __init__(self):
        self.token = None
        self.expires_at = datetime.min

    async def get_token(self):
        if datetime.utcnow() >= self.expires_at:
            self.token = await get_client_credentials_token()
            # Assume que o token tem campo expires_in
            self.expires_at = datetime.utcnow() + timedelta(seconds=3500)
            mantis_log("INFO", "token_renewed", "Token renovado")
        return self.token
```

### 5. Propagação de Tenant (C4)
- O payload do token deve conter `tenant_id`.
- O middleware extrai e injeta nos handlers.

---

## 🧪 Testes Unitários (TDD)
```python
@pytest.mark.asyncio
async def test_token_validation():
    valid_token = create_test_token()
    payload = await validate_token(valid_token)
    assert payload["sub"] == "test-client"
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/mcp-oauth2-authentication.md --json
```

---

## 🔗 Referências Cruzadas
- [[mcp-security-best-practices.md]]
- [[mcp-enterprise-deployment.md]]
