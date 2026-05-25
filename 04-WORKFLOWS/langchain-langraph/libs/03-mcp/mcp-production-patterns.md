---
artifact_id: "mcp-production-patterns"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/mcp-production-patterns.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/mcp-production-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:mcp-production-patterns-v1.0.0"
generated_at: "2026-05-25T03:40:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deploy-docker", "deploy-kubernetes", "cost-optimization"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🏭 MCP Production Patterns – Cache, Rate Limiting, Failover e Escalabilidade

> **Contrato modular**: Consolida padrões de produção para servidores MCP, incluindo cache de ferramentas, rate limiting, estratégias de failover e dimensionamento horizontal.

---

## 🎯 Propósito
Garantir que os servidores MCP no ecossistema MANTIS operem de forma confiável sob carga, com baixa latência e alta disponibilidade.

## 📋 Especificação (SDD)
- **Entradas**: Configuração de cache, políticas de rate limit, arquitetura de deploy.
- **Saídas**: Servidor MCP otimizado para produção.
- **Side Effects**: Uso de Redis, balanceadores de carga.
- **Constraints Aplicáveis**: C1 (contratos), C2 (reprodutibilidade), C3 (segurança), C4 (isolamento), C5 (estrutura), C7 (resiliência), C8 (métricas), C9 (tracing).
- **Dependências**: `redis`, `fastapi`, `slowapi`.

---

## 🛡️ Bootstrap (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Cache de Lista de Ferramentas
- A lista de ferramentas raramente muda; cache com TTL reduz latência.
```python
from functools import lru_cache
import time

@lru_cache(maxsize=1)
def get_cached_tools():
    return [{"name": "add", "description": "Soma dois números"}]

# Invalidar cache quando ferramentas mudarem
def invalidate_tool_cache():
    get_cached_tools.cache_clear()
```

### 2. Rate Limiting por Tenant
```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=lambda: get_remote_address)

@app.post("/mcp")
@limiter.limit("100/minute")
async def mcp_endpoint(request: Request):
    ...
```

### 3. Estratégia de Failover com Múltiplos Servidores
```python
# Cliente pode tentar servidores alternativos
servers = [
    {"url": "http://mcp1.internal/mcp", "weight": 1},
    {"url": "http://mcp2.internal/mcp", "weight": 1},
]

async def call_with_failover(tool_name, args):
    for server in servers:
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(server["url"], json={...}, timeout=5.0)
                return response.json()
        except Exception:
            mantis_log("WARN", "failover", f"Falha em {server['url']}, tentando próximo")
    raise Exception("Todos os servidores MCP falharam")
```

### 4. Dimensionamento Horizontal (Stateless)
- Projete o servidor MCP para ser stateless; armazene estado da sessão em Redis.
- Use um balanceador de carga (Nginx, Traefik) na frente de múltiplas instâncias.

### 5. Health Check e Readiness
```python
@app.get("/health")
async def health():
    return {"status": "ok", "timestamp": datetime.utcnow().isoformat()}

@app.get("/ready")
async def ready():
    # Verificar dependências (Redis, DB)
    if redis_client.ping():
        return {"status": "ready"}
    raise HTTPException(status_code=503)
```

### 6. Métricas de Negócio
```python
from prometheus_client import Counter, generate_latest

TOOL_CALLS = Counter('mcp_tool_calls', 'Total de chamadas de ferramentas', ['tool', 'tenant'])

@mcp.tool()
def business_tool(input: str) -> str:
    TOOL_CALLS.labels(tool='business_tool', tenant=tenant_id).inc()
    # ...
```

### 7. Logging Centralizado
- Todos os logs devem ir para stderr e serem coletados por um agente (Loki, Elastic).
- Formato JSONL consistente (V-LOG-02).

---

## 🧪 Testes Unitários (TDD)
```python
def test_health_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/mcp-production-patterns.md --json
```

---

## 🔗 Referências Cruzadas
- [[mcp-enterprise-deployment.md]]
- [[cost-optimization.md]]
