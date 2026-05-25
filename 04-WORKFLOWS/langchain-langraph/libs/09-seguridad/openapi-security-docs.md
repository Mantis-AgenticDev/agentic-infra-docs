---
artifact_id: "openapi-security-docs"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C2","C3","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/openapi-security-docs.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/openapi-security-docs.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:openapi-security-v1"
generated_at: "2026-05-26T12:45:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["custom-auth-authorization", "deploy-with-control-plane"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-07-25"
---

# 🧩 OpenAPI Security Documentation

> **Contrato modular**: Artefato filho do Master Agent. Customiza a documentação OpenAPI do Agent Server para refletir os esquemas de segurança implementados (OAuth2, API Key, etc.).

## 🎯 Propósito

Garantir que a documentação interativa (`/docs`) do Agent Server exiba corretamente os requisitos de autenticação, permitindo que consumidores da API entendam e testem a segurança.

## 📋 Especificação (SDD)
- **Entradas**: Configuração de `auth.openapi` no `langgraph.json`
- **Saídas**: Esquema OpenAPI customizado com `securitySchemes` e `security`
- **Side Effects**: Atualização da UI do Swagger/ReDoc
- **Constraints Aplicáveis**: C2, C3, C5, C8
- **Dependências**: `PyYAML`, `langgraph.json`

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

# ─── LÓGICA DO MÓDULO ────────────────────────────────────────────────────
import yaml, json
from typing import Dict, Any, Optional
from dataclasses import dataclass, field

# ═══════════════════════════════════════════════════════════════════════════
# 1. MODELOS DE CONFIGURAÇÃO DE SEGURANÇA
# ═══════════════════════════════════════════════════════════════════════════
@dataclass
class OAuth2Flow:
    authorizationUrl: str
    tokenUrl: Optional[str] = None
    scopes: Dict[str, str] = field(default_factory=dict)

@dataclass
class SecurityScheme:
    type: str  # apiKey, http, oauth2, openIdConnect
    name: Optional[str] = None
    in_: Optional[str] = None  # header, query, cookie
    scheme: Optional[str] = None  # bearer
    bearerFormat: Optional[str] = None  # JWT
    flows: Optional[Dict[str, OAuth2Flow]] = None
    openIdConnectUrl: Optional[str] = None

class OpenAPISecurityBuilder:
    """Constrói a seção de segurança do OpenAPI."""
    def __init__(self):
        self.security_schemes = {}
        self.global_security = []

    def add_api_key(self, name: str = "X-API-Key", location: str = "header", description: str = "API Key") -> 'OpenAPISecurityBuilder':
        self.security_schemes["ApiKeyAuth"] = {
            "type": "apiKey",
            "in": location,
            "name": name,
            "description": description
        }
        self.global_security.append({"ApiKeyAuth": []})
        mantis_log("INFO", "security_scheme_added", "ApiKeyAuth")
        return self

    def add_bearer_jwt(self) -> 'OpenAPISecurityBuilder':
        self.security_schemes["BearerAuth"] = {
            "type": "http",
            "scheme": "bearer",
            "bearerFormat": "JWT"
        }
        self.global_security.append({"BearerAuth": []})
        mantis_log("INFO", "security_scheme_added", "BearerAuth")
        return self

    def add_oauth2_implicit(self, authorization_url: str, scopes: Dict[str, str]) -> 'OpenAPISecurityBuilder':
        self.security_schemes["OAuth2"] = {
            "type": "oauth2",
            "flows": {
                "implicit": {
                    "authorizationUrl": authorization_url,
                    "scopes": scopes
                }
            }
        }
        self.global_security.append({"OAuth2": list(scopes.keys())})
        mantis_log("INFO", "security_scheme_added", "OAuth2 Implicit")
        return self

    def add_oauth2_client_credentials(self, token_url: str, scopes: Dict[str, str]) -> 'OpenAPISecurityBuilder':
        self.security_schemes["OAuth2"] = {
            "type": "oauth2",
            "flows": {
                "clientCredentials": {
                    "tokenUrl": token_url,
                    "scopes": scopes
                }
            }
        }
        self.global_security.append({"OAuth2": list(scopes.keys())})
        mantis_log("INFO", "security_scheme_added", "OAuth2 Client Credentials")
        return self

    def build_openapi_fragment(self) -> dict:
        return {
            "components": {
                "securitySchemes": self.security_schemes
            },
            "security": self.global_security
        }

    def to_langgraph_config(self) -> dict:
        """Formato compatível com langgraph.json -> auth.openapi."""
        return {
            "auth": {
                "openapi": {
                    "securitySchemes": self.security_schemes,
                    "security": self.global_security
                }
            }
        }

# ═══════════════════════════════════════════════════════════════════════════
# 2. GERADOR DE LANGGRAPH.JSON COM SEGURANÇA
# ═══════════════════════════════════════════════════════════════════════════
class LangGraphConfigWithSecurity:
    """Gera ou atualiza langgraph.json com as definições de segurança."""
    @staticmethod
    def merge_security(existing_config: dict, security_builder: OpenAPISecurityBuilder) -> dict:
        config = existing_config.copy()
        if "auth" not in config:
            config["auth"] = {}
        config["auth"]["openapi"] = security_builder.build_openapi_fragment()
        return config

    @staticmethod
    def save(config: dict, path: str = "langgraph.json"):
        with open(path, "w") as f:
            json.dump(config, f, indent=2)
        mantis_log("INFO", "config_saved", path)

# ═══════════════════════════════════════════════════════════════════════════
# 3. VALIDADE DO ESQUEMA DE SEGURANÇA
# ═══════════════════════════════════════════════════════════════════════════
class SecuritySchemaValidator:
    @staticmethod
    def validate(openapi_fragment: dict) -> bool:
        schemes = openapi_fragment.get("components", {}).get("securitySchemes", {})
        security = openapi_fragment.get("security", [])
        if not schemes or not security:
            return False
        for sec in security:
            for key in sec:
                if key not in schemes:
                    mantis_log("ERROR", "invalid_security_ref", key)
                    return False
        return True

# ═══════════════════════════════════════════════════════════════════════════
# 4. EXEMPLOS DE USO
# ═══════════════════════════════════════════════════════════════════════════
EXAMPLE_API_KEY = """
{
  "auth": {
    "path": "./auth.py:auth",
    "openapi": {
      "securitySchemes": {
        "apiKeyAuth": {
          "type": "apiKey",
          "in": "header",
          "name": "X-API-Key"
        }
      },
      "security": [
        {"apiKeyAuth": []}
      ]
    }
  }
}
"""

EXAMPLE_OAUTH2 = """
{
  "auth": {
    "path": "./auth.py:auth",
    "openapi": {
      "securitySchemes": {
        "OAuth2": {
          "type": "oauth2",
          "flows": {
            "implicit": {
              "authorizationUrl": "https://auth.example.com/authorize",
              "scopes": {
                "me": "Read user info",
                "threads": "Manage threads"
              }
            }
          }
        }
      },
      "security": [
        {"OAuth2": ["me", "threads"]}
      ]
    }
  }
}
"""
```

## 🧪 Testes Unitários (TDD)
```python
from openapi_security_docs import OpenAPISecurityBuilder, SecuritySchemaValidator, LangGraphConfigWithSecurity

def test_build_api_key():
    builder = OpenAPISecurityBuilder().add_api_key()
    fragment = builder.build_openapi_fragment()
    assert "ApiKeyAuth" in fragment["components"]["securitySchemes"]
    assert fragment["security"][0] == {"ApiKeyAuth": []}

def test_build_oauth2():
    builder = OpenAPISecurityBuilder().add_oauth2_implicit("https://auth.example.com/auth", {"read": "Read"})
    fragment = builder.build_openapi_fragment()
    assert "OAuth2" in fragment["components"]["securitySchemes"]

def test_validator():
    builder = OpenAPISecurityBuilder().add_bearer_jwt()
    fragment = builder.build_openapi_fragment()
    assert SecuritySchemaValidator.validate(fragment)

def test_merge_config():
    existing = {"graphs": {"agent": "./agent.py:graph"}}
    builder = OpenAPISecurityBuilder().add_api_key()
    config = LangGraphConfigWithSecurity.merge_security(existing, builder)
    assert "auth" in config
    assert "openapi" in config["auth"]
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/openapi-security-docs.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[custom-auth-authorization.md]]
- [[deploy-with-control-plane.md]]
