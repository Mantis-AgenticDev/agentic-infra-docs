---
artifact_id: "mcp-multi-tenancy-isolation"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/mcp-multi-tenancy-isolation.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/mcp-multi-tenancy-isolation.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:mcp-multitenant-v1.0.0"
generated_at: "2026-05-25T05:10:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["mcp-oauth2-authentication", "integration-c9-a2a", "deploy-multi-tenant"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🏢 MCP Multi‑Tenancy Isolation – Isolamento de Dados e Ferramentas

> **Contrato modular**: Descreve estratégias para isolar tenants em servidores MCP, garantindo que dados e ferramentas sejam segregados corretamente (C4), com filtros dinâmicos e namespaces.

---

## 🎯 Propósito
Impedir vazamento de dados entre tenants e garantir que cada organização ou unidade de negócio veja apenas suas ferramentas e recursos autorizados.

## 📋 Especificação (SDD)
- **Entradas**: Contexto de tenant (header, token).
- **Saídas**: Ferramentas e recursos filtrados.
- **Side Effects**: Nenhum vazamento.
- **Constraints Aplicáveis**: C1 (contrato de tenant), C3 (proteção de dados), C4 (isolamento estrito), C5 (metadados com tenant_id), C7 (fallback se tenant ausente), C8 (auditoria).
- **Dependências**: `starlette`, `fastmcp`.

---

## 🛡️ Bootstrap (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Propagação de Tenant via Headers/Contexto
```python
# No cliente
headers = {
    "X-Tenant-ID": "acme-corp",
    "Authorization": "Bearer ..."
}
client = MultiServerMCPClient({"svc": {"transport": "http", "url": "...", "headers": headers}})
```

### 2. Middleware de Extração no Servidor
```python
@app.middleware("http")
async def tenant_middleware(request: Request, call_next):
    tenant_id = request.headers.get("X-Tenant-ID", "global")
    request.state.tenant_id = tenant_id
    mantis_log("INFO", "tenant_set", f"Tenant: {tenant_id}")
    response = await call_next(request)
    return response
```

### 3. Filtragem de Ferramentas por Tenant
```python
TENANT_TOOLS = {
    "acme-corp": ["get_inventory", "list_orders"],
    "startup-x": ["get_inventory"],
    "admin": ["*"]
}

def filter_tools_for_tenant(tools, tenant_id):
    allowed = TENANT_TOOLS.get(tenant_id, [])
    if "*" in allowed:
        return tools
    return [t for t in tools if t.name in allowed]

# No momento de expor as ferramentas:
@mcp.list_tools()
async def list_tools(context: Context) -> list[Tool]:
    all_tools = [create_tool(...), ...]
    tenant_id = context.request_context.state.tenant_id
    return filter_tools_for_tenant(all_tools, tenant_id)
```

### 4. Isolamento de Dados nos Recursos
```python
@mcp.resource("reports://{report_id}")
async def get_report(report_id: str, ctx: Context) -> str:
    tenant_id = ctx.request_context.state.tenant_id
    report = await db.get_report(report_id)
    if report.tenant_id != tenant_id:
        mantis_log("SECURITY", "tenant_mismatch", f"Report {report_id} não pertence a {tenant_id}")
        raise PermissionError("Acesso negado")
    return report.content
```

### 5. Armazenamento de Sessão por Tenant (Redis)
```python
def session_key(tenant_id, session_id):
    return f"tenant:{tenant_id}:session:{session_id}"
```

### 6. Logs com Tenant ID
- Todo log (V‑LOG‑02) deve incluir o campo `tenant`.

---

## 🧪 Testes Unitários (TDD)
```python
def test_filter_tools_for_tenant():
    tools = [MockTool("get_inventory"), MockTool("delete_all")]
    filtered = filter_tools_for_tenant(tools, "acme-corp")
    assert len(filtered) == 1
    assert filtered[0].name == "get_inventory"
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/mcp-multi-tenancy-isolation.md --json
```

---

## 🔗 Referências Cruzadas
- [[mcp-oauth2-authentication.md]]
- [[deploy-multi-tenant.md]]
