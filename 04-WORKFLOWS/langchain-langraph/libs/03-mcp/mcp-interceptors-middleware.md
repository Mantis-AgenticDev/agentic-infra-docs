---
artifact_id: "mcp-interceptors-middleware"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/mcp-interceptors-middleware.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/mcp-interceptors-middleware.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:mcp-interceptors-v1.0.0"
generated_at: "2026-05-25T01:20:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["mcp-advanced-features", "agents-swarm-coordination"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# ⛓️ MCP Interceptors & Middleware – Contexto, Retry e Comandos

> **Contrato modular**: Detalha o uso de interceptors para injetar contexto de runtime (tenant, user), modificar requisições, implementar retry e retornar `Command` para alterar o fluxo do grafo.

---

## 🎯 Propósito
Elevar a integração MCP de um simples encadeamento de ferramentas para uma camada inteligente que participa do ciclo de vida do agente, permitindo autorização dinâmica, resiliência e controle de fluxo.

## 📋 Especificação (SDD)
- **Entradas**: Ferramentas MCP, contexto do agente (state, config, store).
- **Saídas**: Ferramentas executadas com modificações, possíveis `Command` para o grafo.
- **Side Effects**: Alterações no estado do agente, logs enriquecidos.
- **Constraints**: C1 (contrato do interceptor), C3 (injeção segura de credenciais), C5 (preservação de schema), C7 (retry), C8 (logs), C9 (trace).
- **Dependências**: `langchain-mcp-adapters`, `langgraph`.

---

## 🛡️ Bootstrap (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Interceptor de Injeção de Contexto
```python
from langchain_mcp_adapters.interceptors import MCPToolCallRequest

async def inject_tenant_context(request: MCPToolCallRequest, handler):
    runtime = request.runtime
    tenant_id = runtime.context.get("tenant_id", "global")
    modified_args = {**request.args, "tenant_id": tenant_id}
    modified_request = request.override(args=modified_args)
    mantis_log("INFO", "interceptor_ctx", f"Injetado tenant_id={tenant_id} em {request.name}")
    return await handler(modified_request)

client = MultiServerMCPClient({...}, tool_interceptors=[inject_tenant_context])
```

### 2. Interceptor de Retry com Backoff Exponencial
```python
import asyncio

async def retry_interceptor(request: MCPToolCallRequest, handler, max_retries=3, delay=1.0):
    last_error = None
    for attempt in range(max_retries):
        try:
            return await handler(request)
        except Exception as e:
            last_error = e
            mantis_log("WARN", "retry", f"Tentativa {attempt+1} falhou para {request.name}: {e}")
            if attempt < max_retries - 1:
                await asyncio.sleep(delay * (2 ** attempt))
    raise last_error
```

### 3. Retornando Command para Atualizar Estado
```python
from langgraph.types import Command

async def track_completion(request: MCPToolCallRequest, handler):
    result = await handler(request)
    if request.name == "submit_order":
        mantis_log("INFO", "order_completed", "Redirecionando para summary_agent")
        return Command(update={"messages": [result], "task_status": "completed"}, goto="summary_agent")
    return result
```

### 4. Interceptor de Fallback
```python
async def fallback_interceptor(request: MCPToolCallRequest, handler):
    try:
        return await handler(request)
    except TimeoutError:
        mantis_log("ERROR", "timeout", f"{request.name} excedeu tempo")
        return ToolMessage(content="Serviço temporariamente indisponível.", tool_call_id=request.id)
    except ConnectionError:
        mantis_log("ERROR", "connection_error", request.name)
        return ToolMessage(content="Não foi possível conectar ao serviço.", tool_call_id=request.id)
```

---

## 🧪 Testes Unitários (TDD)
```python
# Teste do retry (mock)
@pytest.mark.asyncio
async def test_retry_interceptor():
    call_count = 0
    async def flaky_handler(req):
        nonlocal call_count
        call_count += 1
        if call_count < 3:
            raise ConnectionError("fail")
        return "ok"
    result = await retry_interceptor(MockRequest(), flaky_handler)
    assert result == "ok"
    assert call_count == 3
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/mcp-interceptors-middleware.md --json
```

---

## 🔗 Referências Cruzadas
- [[mcp-client-multi-server.md]]
- [[agents-swarm-coordination.md]]
