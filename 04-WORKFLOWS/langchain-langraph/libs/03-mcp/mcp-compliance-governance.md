---
artifact_id: "mcp-compliance-governance"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C4","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/mcp-compliance-governance.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/mcp-compliance-governance.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:mcp-compliance-v1.0.0"
generated_at: "2026-05-25T05:40:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["integration-lgpd", "security-guardrails", "observability-langsmith"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 📋 MCP Compliance & Governance – LGPD, Auditoria e Rastreabilidade

> **Contrato modular**: Alinha os servidores MCP com as exigências de compliance do ecossistema MANTIS, incluindo LGPD, logs de auditoria, consentimento e retenção de dados.

---

## 🎯 Propósito
Garantir que as interações via MCP estejam em conformidade com regulamentações e políticas internas, provendo trilhas de auditoria completas.

## 📋 Especificação (SDD)
- **Entradas**: Requisições MCP, contexto de usuário/tenant.
- **Saídas**: Logs de auditoria, validações de consentimento.
- **Side Effects**: Escrita em trilha de auditoria.
- **Constraints Aplicáveis**: C1 (formato de auditoria), C3 (proteção de dados), C4 (isolamento), C5 (registro íntegro), C7 (não perder logs), C8 (observabilidade), C9 (trace).
- **Dependências**: `sqlalchemy`, `opentelemetry`.

---

## 🛡️ Bootstrap (C3+C8)
```python
# ...
```

### 1. Log de Auditoria por Ferramenta
```python
async def audit_log(tool_name, tenant_id, user_id, args, result_status):
    entry = {
        "ts": datetime.utcnow().isoformat() + "Z",
        "tool": tool_name,
        "tenant_id": tenant_id,
        "user_id": user_id,
        "args": mask_secrets(args),
        "status": result_status,
        "trace_id": os.getenv("TRACE_ID")
    }
    mantis_log("AUDIT", "tool_call", json.dumps(entry))
    # Opcional: persistir em banco
    await db.audit.insert(entry)
```

### 2. Validação de Consentimento (LGPD)
```python
async def check_consent(tenant_id, data_category):
    consent = await db.consent.find_one({"tenant": tenant_id, "category": data_category})
    if not consent or not consent["active"]:
        raise PermissionError("Consentimento não concedido para esta categoria de dados")
```

### 3. Mascaramento de Dados Sensíveis
```python
def mask_pii(text):
    # regex para emails, CPF, etc.
    import re
    text = re.sub(r'[\w\.-]+@[\w\.-]+', '***@***', text)
    text = re.sub(r'\d{3}\.\d{3}\.\d{3}-\d{2}', '***.***.***-**', text)
    return text
```

### 4. Retenção e Expurgo
- Configurar TTL para dados de sessão/logs.
```python
# Excluir logs de auditoria após 5 anos
await db.audit.delete_many({"ts": {"$lt": datetime.utcnow() - timedelta(days=1825)}})
```

### 5. Integração com Tracing Distribuído (C9)
- Cada chamada MCP deve propagar `trace_id` e `span_id`.
```python
from opentelemetry import trace

@mcp.tool()
async def compliant_tool(data: str):
    with trace.get_tracer(__name__).start_as_current_span("compliant_tool") as span:
        span.set_attribute("tenant_id", tenant_id)
        try:
            result = process(data)
            audit_log("compliant_tool", tenant_id, user, {"data": mask_pii(data)}, "success")
            return result
        except Exception as e:
            audit_log("compliant_tool", tenant_id, user, {"data": mask_pii(data)}, "error")
            raise
```

---

## 🧪 Testes Unitários (TDD)
```python
def test_consent_check():
    # mock
    ...
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/mcp-compliance-governance.md --json
```

---

## 🔗 Referências Cruzadas
- [[integration-lgpd.md]]
- [[observability-langsmith.md]]
