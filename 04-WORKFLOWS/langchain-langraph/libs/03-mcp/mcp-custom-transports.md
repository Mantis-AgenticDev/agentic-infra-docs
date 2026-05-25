---
artifact_id: "mcp-custom-transports"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/mcp-custom-transports.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/mcp-custom-transports.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:mcp-custom-transports-v1.0.0"
generated_at: "2026-05-25T03:20:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["mcp-enterprise-deployment", "deploy-kubernetes"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🚌 MCP Custom Transports – WebSockets, gRPC e Transporte Alternativo

> **Contrato modular**: Demonstra como implementar transportes personalizados além de stdio e HTTP, como WebSocket e gRPC, preservando o formato JSON‑RPC e o lifecycle MCP.

---

## 🎯 Propósito
Permitir que o ecossistema MANTIS utilize canais de comunicação otimizados para cenários específicos (ex: WebSocket para streaming bidirecional, gRPC para desempenho) mantendo a compatibilidade com o protocolo MCP.

## 📋 Especificação (SDD)
- **Entradas**: Configuração de transporte, conexões de rede.
- **Saídas**: Canal de comunicação funcional para JSON‑RPC.
- **Side Effects**: Conexões persistentes, uso de recursos de rede.
- **Constraints Aplicáveis**: C1 (formato JSON‑RPC), C3 (segurança do canal), C5 (contrato de mensagens), C7 (reconexão), C8 (logs).
- **Dependências**: `websockets`, `grpcio`.

---

## 🛡️ Bootstrap (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Transporte WebSocket
- O WebSocket permite comunicação full-duplex, ideal para servidores que precisam enviar notificações ao cliente a qualquer momento.

**Servidor WebSocket MCP:**
```python
import asyncio
import websockets
from websockets.server import WebSocketServerProtocol

async def mcp_websocket_handler(websocket: WebSocketServerProtocol):
    # Loop de mensagens JSON‑RPC
    async for message in websocket:
        try:
            request = json.loads(message)
            response = await process_mcp_message(request)
            await websocket.send(json.dumps(response))
        except json.JSONDecodeError:
            error = {"jsonrpc": "2.0", "error": {"code": -32700, "message": "Parse error"}}
            await websocket.send(json.dumps(error))
    mantis_log("INFO", "ws_disconnected", "Cliente desconectado")

async def main():
    async with websockets.serve(mcp_websocket_handler, "localhost", 8765):
        mantis_log("INFO", "ws_server_started", "WebSocket MCP server na porta 8765")
        await asyncio.Future()  # run forever

asyncio.run(main())
```

**Cliente WebSocket MCP:**
```python
from websockets import connect

async def ws_client():
    async with connect("ws://localhost:8765/mcp") as ws:
        initialize = {"jsonrpc": "2.0", "method": "initialize", "params": {...}, "id": 1}
        await ws.send(json.dumps(initialize))
        response = await ws.recv()
        print(json.loads(response))
```

### 2. Transporte gRPC
- Define um serviço Protobuf que encapsula JSON‑RPC.

```protobuf
service MCP {
  rpc SendMessage (MCPMessage) returns (MCPMessage);
}

message MCPMessage {
  string jsonrpc = 1;
  // ...
}
```

### 3. Transporte Híbrido: Redis Pub/Sub
- Para comunicação desacoplada em arquiteturas de microserviços.

```python
import redis.asyncio as redis

async def redis_transport():
    r = redis.Redis()
    pubsub = r.pubsub()
    await pubsub.subscribe("mcp:requests")
    async for message in pubsub.listen():
        if message['type'] == 'message':
            request = json.loads(message['data'])
            response = await process(request)
            await r.publish("mcp:responses", json.dumps(response))
```

### 4. Considerações de Segurança (C3)
- Sempre use TLS (wss://, https://, grpcs).
- Valide a origem das conexões WebSocket.
- Autentique via tokens no handshake ou headers.

### 5. Fallback e Reconexão (C7)
- Implemente lógica de retry com backoff exponencial.
- Mantenha um heartbeat para detectar conexões mortas.

---

## 🧪 Testes Unitários (TDD)
```python
@pytest.mark.asyncio
async def test_ws_message():
    # Teste com servidor e cliente mock
    ...
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/mcp-custom-transports.md --json
```

---

## 🔗 Referências Cruzadas
- [[mcp-server-fundamentals.md]]
- [[deploy-kubernetes.md]]
