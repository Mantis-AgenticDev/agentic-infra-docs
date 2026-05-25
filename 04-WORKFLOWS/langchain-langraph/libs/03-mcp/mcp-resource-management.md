---
artifact_id: "mcp-resource-management"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/mcp-resource-management.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/mcp-resource-management.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:mcp-resources-v1.0.0"
generated_at: "2026-05-25T04:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["mcp-server-fundamentals", "rag-vector-stores"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 📁 MCP Resource Management – Exposição e Consumo de Recursos

> **Contrato modular**: Define como expor e consumir recursos no Model Context Protocol, incluindo recursos estáticos, templates dinâmicos, conteúdo binário e integração com agentes.

---

## 🎯 Propósito
Permitir que servidores MCP compartilhem dados estruturados (arquivos, configurações, resultados de API) como recursos legíveis por clientes e agentes, seguindo as constraints MANTIS.

## 📋 Especificação (SDD)
- **Entradas**: Dados a serem expostos (arquivos, strings, blobs).
- **Saídas**: Recursos acessíveis via URI.
- **Side Effects**: Leitura de fontes de dados externas.
- **Constraints Aplicáveis**: C1 (contrato de URI), C3 (não expor dados sensíveis sem autorização), C5 (estrutura de metadados), C7 (fallback se recurso não encontrado), C8 (logs de acesso).
- **Dependências**: `fastmcp`, `mcp`.

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

### 1. Recurso Estático
```python
@mcp.resource("config://app")
def get_app_config() -> str:
    """Retorna a configuração da aplicação (sem secrets)."""
    config = {
        "version": "1.0.0",
        "mode": os.getenv("MODE", "B1"),
        "max_retries": 3
    }
    mantis_log("INFO", "resource_accessed", "config://app")
    return json.dumps(config)
```

### 2. Recurso com Template (URI Dinâmica)
```python
@mcp.resource("docs://{topic}")
def get_documentation(topic: str) -> str:
    """Retorna documentação sobre um tópico específico."""
    docs = {
        "mcp": "Model Context Protocol...",
        "langgraph": "LangGraph é um framework..."
    }
    content = docs.get(topic, "Tópico não encontrado.")
    mantis_log("INFO", "resource_accessed", f"docs://{topic}")
    return content
```

### 3. Recurso Binário (Imagens, PDFs)
```python
@mcp.resource("images://{filename}")
async def get_image(filename: str) -> bytes:
    """Retorna uma imagem do diretório de assets."""
    filepath = os.path.join("assets", filename)
    if not os.path.exists(filepath):
        mantis_log("WARN", "resource_not_found", filename)
        raise ValueError("Imagem não encontrada.")
    with open(filepath, "rb") as f:
        return f.read()
```

### 4. Consumindo Recursos no Cliente
```python
from langchain_mcp_adapters.client import MultiServerMCPClient

client = MultiServerMCPClient({...})

# Carregar todos os recursos de um servidor
blobs = await client.get_resources("server_name")
for blob in blobs:
    mantis_log("INFO", "resource_loaded", f"URI: {blob.metadata['uri']}, MIME: {blob.mimetype}")
    if blob.mimetype.startswith("text"):
        print(blob.as_string())
    else:
        print(f"Conteúdo binário de {len(blob.data)} bytes")
```

### 5. Carregar Recursos Específicos por URI
```python
blobs = await client.get_resources("server_name", uris=["config://app", "docs://mcp"])
```

### 6. Usando Sessão para Carregar Recursos
```python
from langchain_mcp_adapters.resources import load_mcp_resources

async with client.session("server_name") as session:
    blobs = await load_mcp_resources(session, uris=["docs://langgraph"])
```

### 7. Filtragem e Autorização (C3, C4)
- Recursos podem ser filtrados por tenant_id.
```python
@mcp.resource("reports://{tenant_id}/{report_name}")
async def get_report(tenant_id: str, report_name: str) -> str:
    if tenant_id != os.getenv("TENANT_ID"):
        raise PermissionError("Acesso não autorizado")
    return generate_report(report_name)
```

### 8. Metadados e MIME Types
- Sempre defina o `mime_type` correto.
- Exemplo: `@mcp.resource("data://users", mime_type="application/json")`

---

## 🧪 Testes Unitários (TDD)
```python
def test_static_resource():
    result = get_app_config()
    data = json.loads(result)
    assert "version" in data

def test_template_resource():
    result = get_documentation("mcp")
    assert "Model Context Protocol" in result
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/mcp-resource-management.md --json
```

---

## 🔗 Referências Cruzadas
- [[mcp-server-fundamentals.md]]
- [[mcp-client-multi-server.md]]
