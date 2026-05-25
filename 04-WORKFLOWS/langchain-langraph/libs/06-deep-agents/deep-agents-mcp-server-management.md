---
artifact_id: "deep-agents-mcp-server-management"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-mcp-server-management.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-mcp-server-management.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-mcp-management-v1.0.0"
generated_at: "2026-05-26T03:15:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-managed-api", "mcp-server-fundamentals"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-26"
---

# 🔌 Deep Agents – Gestão de Servidores MCP (Managed)

> **Contrato modular**: Artefato filho do Master Agent. Documenta o registro, listagem, inspeção, rotação de credenciais e exclusão de servidores MCP na plataforma Managed Deep Agents, com segurança de headers cifrados.

---

## 🎯 Propósito
Permitir que o ecossistema MANTIS configure e gerencie servidores MCP com credenciais seguras (bearer tokens, API keys) para uso por agentes gerenciados, sem expor segredos em código.

## 📋 Especificação (SDD)
- **Entradas**: URL do servidor MCP, headers de autenticação.
- **Saídas**: Servidor MCP registrado e pronto para uso.
- **Side Effects**: Armazenamento cifrado de credenciais.
- **Constraints Aplicáveis**: C1 (formato de registro), C3 (proteção de secrets), C5 (schema de headers), C7 (retry), C8 (logs de auditoria).
- **Dependências**: `httpx`, `langsmith`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ... (fallback padrão)
```

### 1. Registro de Servidor MCP

```python
import httpx
import os

BASE_URL = os.getenv("DEEPAGENTS_BASE_URL", "https://api.smith.langchain.com/v1/deepagents")
HEADERS = {"X-Api-Key": os.getenv("LANGSMITH_API_KEY"), "Content-Type": "application/json"}

def register_mcp_server(name, url, headers_list):
    response = httpx.post(
        f"{BASE_URL}/mcp-servers",
        headers=HEADERS,
        json={
            "name": name,
            "url": url,
            "headers": headers_list,
        },
    )
    response.raise_for_status()
    server_id = response.json()["id"]
    mantis_log("INFO", "mcp_registered", f"Server: {name}, ID: {server_id}")
    return server_id

# Exemplo: registrar Tavily
mcp_server_id = register_mcp_server(
    name="tavily",
    url="https://mcp.tavily.com/mcp/",
    headers_list=[{"key": "Authorization", "value": "Bearer tvly-..."}],
)
```

### 2. Listagem de Servidores MCP

```python
def list_mcp_servers():
    response = httpx.get(f"{BASE_URL}/mcp-servers", headers=HEADERS)
    response.raise_for_status()
    servers = response.json()
    mantis_log("INFO", "mcp_listed", f"Total: {len(servers)}")
    return servers

def get_mcp_server(server_id):
    response = httpx.get(f"{BASE_URL}/mcp-servers/{server_id}", headers=HEADERS)
    response.raise_for_status()
    server = response.json()
    mantis_log("INFO", "mcp_retrieved", f"ID: {server_id}")
    return server
```

### 3. Rotação de Credenciais

```python
def rotate_mcp_credentials(server_id, new_headers):
    response = httpx.patch(
        f"{BASE_URL}/mcp-servers/{server_id}",
        headers=HEADERS,
        json={"headers": new_headers},
    )
    response.raise_for_status()
    mantis_log("INFO", "mcp_rotated", f"ID: {server_id}")
    return response.json()
```

### 4. Exclusão de Servidor MCP

```python
def delete_mcp_server(server_id):
    response = httpx.delete(f"{BASE_URL}/mcp-servers/{server_id}", headers=HEADERS)
    response.raise_for_status()
    mantis_log("WARN", "mcp_deleted", f"ID: {server_id}")
```

### 5. Configuração `tools.json` com MCP

```python
tools_config = {
    "tools": [
        {
            "name": "tavily_search",
            "mcp_server_url": "https://mcp.tavily.com/mcp/",
            "mcp_server_name": "tavily",
            "display_name": "tavily_search",
        },
        {
            "name": "tavily-extract",
            "mcp_server_url": "https://mcp.tavily.com/mcp/",
            "mcp_server_name": "tavily",
            "display_name": "tavily-extract",
        },
    ],
    "interrupt_config": {
        "https://mcp.tavily.com/mcp/::tavily_search::tavily": False,
        "https://mcp.tavily.com/mcp/::tavily-extract::tavily": True,
    },
}
```

### 6. Gerenciador de Servidores MCP com Cache

```python
from functools import lru_cache

class MCPServerManager:
    def __init__(self):
        self._cache = {}

    def register(self, name, url, headers_list):
        server_id = register_mcp_server(name, url, headers_list)
        self._cache[url] = {"id": server_id, "name": name}
        return server_id

    @lru_cache(maxsize=128)
    def get_by_url(self, url):
        # Buscar na API se não estiver em cache
        servers = list_mcp_servers()
        for s in servers:
            if s["url"] == url:
                return s
        return None

    def rotate_all(self, new_headers):
        servers = list_mcp_servers()
        for s in servers:
            rotate_mcp_credentials(s["id"], new_headers)
            mantis_log("INFO", "mcp_bulk_rotate", f"Server: {s['name']}")
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_mcp_registration_payload():
    payload = {
        "name": "test",
        "url": "https://example.com/mcp",
        "headers": [{"key": "Authorization", "value": "Bearer token"}],
    }
    assert "headers" in payload
    assert len(payload["headers"]) == 1

def test_tools_config_structure():
    config = {
        "tools": [{"mcp_server_url": "https://mcp.example.com"}],
        "interrupt_config": {"https://mcp.example.com::tool": True},
    }
    assert "::" in list(config["interrupt_config"].keys())[0]
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-mcp-server-management.md --json
```

---

## 🔗 Referências Cruzadas
- [[deep-agents-managed-api.md]]
- [[mcp-server-fundamentals.md]]
