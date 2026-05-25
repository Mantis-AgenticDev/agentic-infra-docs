---
artifact_id: "custom-auth-authorization"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C2","C3","C4","C5","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/custom-auth-authorization.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/custom-auth-authorization.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:custom-auth-v1"
generated_at: "2026-05-26T12:30:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["langgraph-create-agent", "deep-agents-core-customization"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-07-25"
---

# 🧩 Custom Authentication & Authorization

> **Contrato modular**: Artefato filho do Master Agent. Implementa autenticação customizada no Agent Server usando o objeto `Auth` da SDK, com propagação de identidade e autorização de recursos por proprietário.

## 🎯 Propósito

Permitir que o Agent Server valide tokens JWT ou API keys customizadas, retornando um `MinimalUserDict` que é injetado no `config` do grafo via `langgraph_auth_user`, e aplicar filtros de autorização para isolar recursos por usuário.

## 📋 Especificação (SDD)
- **Entradas**: Headers HTTP (Authorization), configuração do `Auth` em `langgraph.json`
- **Saídas**: Objeto de usuário no `config["configurable"]["langgraph_auth_user"]`, filtro `owner` aplicado
- **Side Effects**: Bloqueio de requisições não autenticadas, recursos privados por usuário
- **Constraints Aplicáveis**: C2 (Validação), C3 (Segurança), C4 (Consentimento), C5 (Integridade), C6 (Multi-tenancy), C7 (Versionamento), C8 (Observabilidade)
- **Dependências**: `langgraph-sdk`, `httpx`, `PyJWT`, `pydantic`, `supabase`

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from langchain_langraph_master_agent import mantis_log
except ImportError:
    import json, datetime, os
    def mantis_log(level, event, detail=""):
        entry = {
            "ts": datetime.datetime.utcnow().isoformat() + "Z",
            "level": level,
            "tenant": os.getenv("TENANT_ID", "global"),
            "event": event,
            "detail": detail,
            "trace_id": os.getenv("TRACE_ID", "null"),
            "span_id": os.getenv("SPAN_ID", "null"),
            "fallback": "true"
        }
        print(json.dumps(entry), flush=True)
    mantis_log("WARN", "bootstrap_fallback", "Master Agent langchain-langraph não encontrado.")

# ─── IMPLEMENTAÇÃO DO MÓDULO ─────────────────────────────────────────────
import os, asyncio
from typing import Optional, Dict, Any
import httpx
import jwt
from pydantic import BaseModel, ValidationError
from langgraph_sdk import Auth

# ═══════════════════════════════════════════════════════════════════════════
# 1. DEFINIÇÃO DO HANDLER DE AUTENTICAÇÃO
# ═══════════════════════════════════════════════════════════════════════════
class UserInfo(BaseModel):
    identity: str
    email: Optional[str] = None
    name: Optional[str] = None
    org_id: Optional[str] = None
    permissions: list = []

auth = Auth()

@auth.authenticate
async def authenticate(request_headers: dict) -> Auth.types.MinimalUserDict:
    """Valida o token e retorna a identidade do usuário."""
    authorization = request_headers.get(b"authorization", b"").decode()
    if not authorization:
        raise Auth.exceptions.HTTPException(status_code=401, detail="Authorization header ausente")

    scheme, token = authorization.split(maxsplit=1)
    if scheme.lower() != "bearer":
        raise Auth.exceptions.HTTPException(status_code=401, detail="Esquema deve ser Bearer")

    user = await validate_token(token)
    if not user:
        raise Auth.exceptions.HTTPException(status_code=401, detail="Token inválido")

    mantis_log("INFO", "user_authenticated", f"Identity: {user['identity']}")
    return {
        "identity": user["identity"],
        "email": user.get("email"),
        "name": user.get("name"),
        "org_id": user.get("org_id"),
        "permissions": user.get("permissions", [])
    }

# ═══════════════════════════════════════════════════════════════════════════
# 2. LÓGICA DE VALIDAÇÃO DE TOKEN (SUPABASE COMO EXEMPLO)
# ═══════════════════════════════════════════════════════════════════════════
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

async def validate_token(token: str) -> Optional[Dict[str, Any]]:
    """Valida JWT contra Supabase (ou outro provedor OAuth2)."""
    if not SUPABASE_URL:
        # Modo local: apenas parsing JWT sem validação de assinatura (desenvolvimento)
        mantis_log("WARN", "token_validation_fallback", "SUPABASE_URL não configurada, usando validação local insegura")
        return _decode_token_locally(token)

    try:
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f"{SUPABASE_URL}/auth/v1/user",
                headers={"Authorization": f"Bearer {token}", "apikey": SUPABASE_SERVICE_KEY}
            )
            if resp.status_code == 200:
                user_data = resp.json()
                return {
                    "identity": user_data["id"],
                    "email": user_data["email"],
                    "name": user_data.get("user_metadata", {}).get("name"),
                }
            mantis_log("WARN", "token_validation_fail", f"Status {resp.status_code}")
            return None
    except Exception as e:
        mantis_log("ERROR", "token_validation_error", str(e))
        return None

def _decode_token_locally(token: str) -> Optional[Dict[str, Any]]:
    """Decodifica JWT sem verificar assinatura (apenas para desenvolvimento)."""
    try:
        payload = jwt.decode(token, options={"verify_signature": False})
        return {
            "identity": payload.get("sub", "unknown"),
            "email": payload.get("email"),
            "name": payload.get("name")
        }
    except Exception:
        return None

# ═══════════════════════════════════════════════════════════════════════════
# 3. HANDLER DE AUTORIZAÇÃO (RESOURCE-LEVEL)
# ═══════════════════════════════════════════════════════════════════════════
@auth.on
async def add_owner(ctx: Auth.types.AuthContext, value: dict) -> dict:
    """Adiciona o proprietário como filtro de acesso ao recurso."""
    filters = {"owner": ctx.user.identity}
    metadata = value.setdefault("metadata", {})
    metadata.update(filters)
    mantis_log("INFO", "resource_owner_set", f"User={ctx.user.identity}")
    return filters

@auth.on
async def authorize_thread_access(ctx: Auth.types.AuthContext, value: dict) -> dict:
    """Garante que apenas o proprietário ou admin possam acessar threads."""
    if ctx.user.permissions and "admin" in ctx.user.permissions:
        return {}  # admin vê tudo
    return {"owner": ctx.user.identity}

# ═══════════════════════════════════════════════════════════════════════════
# 4. INTEGRAÇÃO COM O GRAFO: USO DO langgraph_auth_user
# ═══════════════════════════════════════════════════════════════════════════
def get_auth_user_from_config(config: dict) -> dict:
    """Extrai o usuário autenticado do config para uso no grafo."""
    user = config.get("configurable", {}).get("langgraph_auth_user", {})
    return user

def auth_required(func):
    """Decorador que verifica se o usuário está autenticado antes de executar um nó."""
    async def wrapper(state, config):
        user = get_auth_user_from_config(config)
        if not user.get("identity"):
            raise PermissionError("Usuário não autenticado")
        return await func(state, config)
    return wrapper

# ═══════════════════════════════════════════════════════════════════════════
# 5. CONFIGURAÇÃO DO LANGGRAPH.JSON
# ═══════════════════════════════════════════════════════════════════════════
CONFIG_EXAMPLE = """
{
  "dependencies": ["."],
  "graphs": {
    "agent": "./agent.py:graph"
  },
  "auth": {
    "path": "./security/auth.py:auth"
  }
}
"""
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from unittest.mock import patch, AsyncMock
from custom_auth_authorization import authenticate, validate_token, get_auth_user_from_config

@pytest.mark.asyncio
@patch('custom_auth_authorization.validate_token')
async def test_authenticate_success(mock_validate):
    mock_validate.return_value = {"identity": "user-123", "email": "test@test.com"}
    headers = {b"authorization": b"Bearer valid-token"}
    user = await authenticate(headers)
    assert user["identity"] == "user-123"

@pytest.mark.asyncio
async def test_authenticate_no_header():
    with pytest.raises(Exception) as exc:
        await authenticate({b"authorization": b""})
    assert exc.value.status_code == 401

def test_get_auth_user():
    config = {"configurable": {"langgraph_auth_user": {"identity": "user-1"}}}
    assert get_auth_user_from_config(config)["identity"] == "user-1"

@pytest.mark.asyncio
@patch('httpx.AsyncClient.get')
async def test_validate_token_supabase(mock_get):
    mock_get.return_value.status_code = 200
    mock_get.return_value.json = lambda: {"id": "user-1", "email": "u@t.com"}
    result = await validate_token("valid")
    assert result["identity"] == "user-1"
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/custom-auth-authorization.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[langgraph-create-agent.md]]
- [[lgpd-guard-mantis.md]]
