---
artifact_id: "mcp-security-best-practices"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/mcp-security-best-practices.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/mcp-security-best-practices.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:mcp-security-v1.0.0"
generated_at: "2026-05-25T02:10:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["mcp-enterprise-deployment", "security-guardrails", "tools-mcp-integration"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🔐 MCP Security Best Practices – Autenticação, Autorização e Proteção

> **Contrato modular**: Centraliza as práticas de segurança para servidores e clientes MCP, abrangendo autenticação, autorização, validação de entrada, proteção contra ataques e isolamento multi-tenant.

---

## 🎯 Propósito
Garantir que todas as integrações MCP no ecossistema MANTIS sigam um padrão de segurança robusto, evitando vazamento de dados, injeção de comandos e acesso não autorizado.

## 📋 Especificação (SDD)
- **Entradas**: Requisições MCP, configurações de segurança.
- **Saídas**: Mecanismos de proteção aplicados.
- **Side Effects**: Bloqueio de requisições maliciosas, logs de segurança.
- **Constraints Aplicáveis**: C1 (contrato de segurança), C3 (proteção de secrets), C4 (isolamento de tenant), C5 (validação de schemas), C7 (resiliência sob ataque), C8 (auditoria).
- **Dependências**: `httpx`, `starlette`, `pydantic`.

---

## 🛡️ Bootstrap (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ... (fallback)
```

### 1. Autenticação via Headers e Custom Auth
```python
from httpx import Auth

class TenantBearerAuth(Auth):
    def __init__(self, token_getter):
        self.token_getter = token_getter
    def auth_flow(self, request):
        token = self.token_getter()
        request.headers["Authorization"] = f"Bearer {token}"
        request.headers["X-Tenant-ID"] = os.getenv("TENANT_ID", "global")
        yield request

client = MultiServerMCPClient({
    "secure_svc": {
        "transport": "http",
        "url": "https://api.mantis.internal/mcp",
        "auth": TenantBearerAuth(lambda: os.getenv("MCP_AUTH_TOKEN"))
    }
})
```

### 2. Validação de Origin (C3)
```python
ALLOWED_ORIGINS = ["https://app.mantis.local", "http://localhost:3000"]

def check_origin(request):
    origin = request.headers.get("Origin")
    if origin and origin not in ALLOWED_ORIGINS:
        mantis_log("SECURITY", "origin_blocked", f"Origem: {origin}")
        raise HTTPException(status_code=403, detail="Origin not allowed")
```

### 3. Proteção contra Injeção de Prompt
- Nunca confie cegamente no conteúdo retornado por recursos MCP externos.
- Sanitize saídas que serão inseridas em prompts:
```python
def sanitize_for_prompt(text: str) -> str:
    # Remove possíveis instruções maliciosas
    dangerous_patterns = ["<|im_start|>", "ignore previous instructions"]
    for pattern in dangerous_patterns:
        text = text.replace(pattern, "[FILTERED]")
    return text
```

### 4. Isolamento Multi‑Tenant (C4)
- Cada ferramenta deve verificar e propagar `tenant_id`.
- Exemplo com interceptor:
```python
async def tenant_isolation_interceptor(request: MCPToolCallRequest, handler):
    tenant = request.runtime.context.get("tenant_id")
    if not tenant:
        raise PermissionError("tenant_id ausente")
    # Adicionar tenant aos argumentos
    new_args = {**request.args, "tenant_id": tenant}
    modified_request = request.override(args=new_args)
    return await handler(modified_request)
```

### 5. Rate Limiting no Lado do Servidor
```python
from slowapi import Limiter
limiter = Limiter(key_func=lambda: "global")

@app.post("/mcp")
@limiter.limit("100/minute")
async def mcp_endpoint(request: Request):
    ...
```

### 6. Proteção de Dados Sensíveis em Logs (C3)
- Nunca logue secrets, tokens ou dados pessoais.
- Use mascaramento:
```python
def mask_secrets(data: dict) -> dict:
    if "api_key" in data:
        data["api_key"] = "***"
    return data
```

### 7. Lista de Verificação de Segurança
- ✅ Transporte criptografado (TLS) em produção.
- ✅ Autenticação em todos os endpoints.
- ✅ Validação de entrada rigorosa.
- ✅ Filtragem de ferramentas por perfil de usuário.
- ✅ Logs de auditoria para todas as chamadas administrativas.

---

## 🧪 Testes Unitários (TDD)
```python
def test_origin_validation_rejects():
    request = Mock(headers={"Origin": "http://evil.com"})
    with pytest.raises(HTTPException):
        check_origin(request)
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/mcp-security-best-practices.md --json
```

---

## 🔗 Referências Cruzadas
- [[mcp-enterprise-deployment.md]]
- [[security-guardrails.md]]
