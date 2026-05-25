---
artifact_id: "mcp-state-management-sessions"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C4","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/mcp-state-management-sessions.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/mcp-state-management-sessions.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:mcp-state-sessions-v1.0.0"
generated_at: "2026-05-25T03:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["mcp-enterprise-deployment", "agents-swarm-coordination", "integration-c9-a2a"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🧠 MCP State Management & Sessions – Sessões Persistentes e Estado Distribuído

> **Contrato modular**: Detalha o gerenciamento de sessões no protocolo MCP, incluindo sessões stateful, ciclo de vida, armazenamento de estado e correlação com tracing distribuído (C9).

---

## 🎯 Propósito
Capacitar o ecossistema MANTIS a implementar servidores MCP que mantenham estado entre chamadas, essencial para workflows longos e agentes que precisam de contexto contínuo.

## 📋 Especificação (SDD)
- **Entradas**: Requisições MCP com `MCP-Session-Id`, configuração de armazenamento.
- **Saídas**: Estado persistido e recuperável entre chamadas.
- **Side Effects**: Criação e destruição de sessões; possíveis escritas em banco.
- **Constraints Aplicáveis**: C1 (contrato de sessão), C3 (segurança do token), C4 (isolamento de tenant), C5 (schema de estado), C7 (resiliência), C8 (logs), C9 (trace_id vinculado à sessão).
- **Dependências**: `mcp`, `redis`, `postgresql`.

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

### 1. Sessões Stateful no Servidor (Streamable HTTP)
- O servidor atribui um `MCP-Session-Id` no `InitializeResult`.
- O cliente deve enviar esse ID em todas as requisições subsequentes.
- O servidor mantém um mapa de sessões com estado.

```python
import uuid
from starlette.requests import Request

active_sessions: dict[str, dict] = {}

@app.post("/mcp")
async def handle_request(request: Request):
    session_id = request.headers.get("MCP-Session-Id")
    if not session_id:
        # Nova sessão durante Initialize
        if is_initialize_request(request):
            session_id = str(uuid.uuid4())
            active_sessions[session_id] = {"created_at": datetime.utcnow(), "state": {}}
            response = JSONResponse(content=initialize_result.dict())
            response.headers["MCP-Session-Id"] = session_id
            return response
        else:
            raise HTTPException(status_code=400, detail="MCP-Session-Id requerido")
    # Validar sessão
    if session_id not in active_sessions:
        raise HTTPException(status_code=404, detail="Sessão não encontrada")
    # Processar requisição...
```

### 2. Armazenamento de Estado com Redis
```python
import redis.asyncio as redis

redis_client = redis.Redis(host='localhost', port=6379, decode_responses=True)

async def save_session_state(session_id: str, state: dict, ttl: int = 3600):
    await redis_client.setex(f"mcp:session:{session_id}", ttl, json.dumps(state))
    mantis_log("INFO", "session_state_saved", f"Session {session_id}")

async def load_session_state(session_id: str) -> dict:
    data = await redis_client.get(f"mcp:session:{session_id}")
    if data:
        return json.loads(data)
    return {}
```

### 3. Exemplo: Ferramenta com Estado Acumulativo
```python
@mcp.tool()
async def add_to_cart(item: str, quantity: int, ctx: Context) -> str:
    session_id = ctx.session_id
    cart = await load_session_state(session_id)
    cart_items = cart.get("items", [])
    cart_items.append({"item": item, "quantity": quantity})
    cart["items"] = cart_items
    await save_session_state(session_id, cart)
    mantis_log("INFO", "cart_updated", f"Session {session_id}: {item} x{quantity}")
    return f"Carrinho: {cart_items}"
```

### 4. Ciclo de Vida da Sessão
- **Criação**: Durante `InitializeRequest` sem session ID.
- **Uso**: Todas as chamadas com header `MCP-Session-Id`.
- **Expiração**: Após TTL configurado ou quando o cliente envia HTTP DELETE.
- **Terminação explícita**:
```python
@app.delete("/mcp")
async def terminate_session(request: Request):
    session_id = request.headers.get("MCP-Session-Id")
    if session_id and session_id in active_sessions:
        del active_sessions[session_id]
        await redis_client.delete(f"mcp:session:{session_id}")
        mantis_log("INFO", "session_terminated", session_id)
    return Response(status_code=204)
```

### 5. Correlação com Tracing (C9)
- O `trace_id` e `span_id` devem ser propagados junto com a sessão.
```python
# No cliente, ao criar sessão, armazenar trace_id
async with client.session("math") as session:
    # o interceptor pode adicionar headers de tracing
    tools = await load_mcp_tools(session)
    # todas as chamadas na sessão compartilham o trace
```

### 6. Isolamento Multi‑Tenant (C4)
```python
# Cada tenant pode ter um namespace de sessões separado
session_key = f"tenant:{tenant_id}:session:{session_id}"
```

---

## 🧪 Testes Unitários (TDD)
```python
@pytest.mark.asyncio
async def test_session_creation():
    response = await client.post("/mcp", json=initialize_request)
    assert response.status_code == 200
    assert "MCP-Session-Id" in response.headers

@pytest.mark.asyncio
async def test_session_state_persistence():
    # Criar sessão, adicionar estado, verificar persistência
    ...
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/mcp-state-management-sessions.md --json
```

---

## 🔗 Referências Cruzadas
- [[mcp-enterprise-deployment.md]]
- [[integration-c9-a2a.md]]
