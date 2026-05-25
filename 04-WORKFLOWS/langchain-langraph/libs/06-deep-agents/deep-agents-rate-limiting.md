---
artifact_id: "deep-agents-rate-limiting"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-rate-limiting.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-rate-limiting.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-rate-limiting-v1.0.0"
generated_at: "2026-05-26T00:15:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-deployment-production"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-26"
---

# 🚦 Deep Agents – Rate Limiting e Controle de Concorrência

> **Contrato modular**: Artefato filho do Master Agent. Implementa estratégias de rate limiting, controle de concorrência e filas para agentes MANTIS, garantindo uso justo de recursos e proteção contra abusos.

---

## 🎯 Propósito
Prevenir sobrecarga de APIs, controlar custos e garantir qualidade de serviço em ambientes multi‑tenant.

## 📋 Especificação (SDD)
- **Entradas**: Políticas de limite, configurações de fila.
- **Saídas**: Agente com rate limiting ativo.
- **Side Effects**: Bloqueio ou atraso de requisições.
- **Constraints Aplicáveis**: C1 (limites definidos), C3 (proteção), C5 (métricas), C7 (graceful degradation), C8 (logs).
- **Dependências**: `tenacity`, `redis`, `asyncio`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Rate Limiting por Usuário

```python
import time
from collections import defaultdict

class UserRateLimiter:
    def __init__(self, max_calls_per_minute=20):
        self.max_calls = max_calls_per_minute
        self.user_calls = defaultdict(list)

    def allow(self, user_id: str) -> bool:
        now = time.time()
        calls = [t for t in self.user_calls[user_id] if now - t < 60]
        self.user_calls[user_id] = calls
        if len(calls) >= self.max_calls:
            mantis_log("SECURITY", "rate_limited", f"User: {user_id}")
            return False
        self.user_calls[user_id].append(now)
        return True

limiter = UserRateLimiter(max_calls_per_minute=15)

def rate_limited_invoke(agent, input_data, config):
    user_id = config.get("metadata", {}).get("user_id", "anonymous")
    if not limiter.allow(user_id):
        return {"error": "Rate limit exceeded. Tente novamente em alguns segundos."}
    return agent.invoke(input_data, config=config)
```

### 2. Rate Limiting com Redis (Distribuído)

```python
import redis.asyncio as redis
import asyncio

class DistributedRateLimiter:
    def __init__(self, redis_url="redis://localhost:6379"):
        self.redis = redis.from_url(redis_url)

    async def allow(self, user_id: str, max_calls: int = 20, window: int = 60) -> bool:
        key = f"rate_limit:{user_id}"
        current = await self.redis.get(key)
        if current and int(current) >= max_calls:
            return False
        pipe = self.redis.pipeline()
        pipe.incr(key)
        pipe.expire(key, window)
        await pipe.execute()
        return True

dist_limiter = DistributedRateLimiter()
```

### 3. Controle de Concorrência com Semáforos

```python
import asyncio

class ConcurrencyController:
    def __init__(self, max_concurrent=5):
        self.semaphore = asyncio.Semaphore(max_concurrent)

    async def invoke_with_limit(self, agent, input_data, config):
        async with self.semaphore:
            mantis_log("INFO", "concurrent_call", f"Slots disponíveis: {self.semaphore._value}")
            return await agent.ainvoke(input_data, config=config)

controller = ConcurrencyController(max_concurrent=3)
```

### 4. Fila de Requisições com Backpressure

```python
import asyncio
from collections import deque

class RequestQueue:
    def __init__(self, max_size=100):
        self.queue = deque(maxlen=max_size)
        self.condition = asyncio.Condition()

    async def enqueue(self, request):
        async with self.condition:
            if len(self.queue) >= self.queue.maxlen:
                raise Exception("Fila cheia – backpressure ativado")
            self.queue.append(request)
            self.condition.notify()

    async def dequeue(self):
        async with self.condition:
            while not self.queue:
                await self.condition.wait()
            return self.queue.popleft()
```

### 5. Retry com Backoff Exponencial

```python
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(stop=stop_after_attempt(3), wait=wait_exponential(min=1, max=10))
async def invoke_with_retry(agent, input_data, config):
    return await agent.ainvoke(input_data, config=config)
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_user_rate_limiter():
    limiter = UserRateLimiter(max_calls_per_minute=3)
    assert limiter.allow("user-1") == True
    assert limiter.allow("user-1") == True
    assert limiter.allow("user-1") == True
    assert limiter.allow("user-1") == False
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-rate-limiting.md --json
```

---

## 🔗 Referências Cruzadas
- [[deep-agents-deployment-production.md]]
