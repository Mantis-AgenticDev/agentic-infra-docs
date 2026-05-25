---
artifact_id: "deep-agents-cost-optimization"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-cost-optimization.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-cost-optimization.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-cost-opt-v1.0.0"
generated_at: "2026-05-26T00:00:00Z"
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

# 💰 Deep Agents – Otimização de Custos e Tokens

> **Contrato modular**: Artefato filho do Master Agent. Estratégias para reduzir custos operacionais de Deep Agents, incluindo escolha de modelos, caching, prompt compression, model right‑sizing e monitoramento de gastos.

---

## 🎯 Propósito
Garantir que agentes MANTIS operem dentro de orçamentos controlados, minimizando desperdício de tokens sem sacrificar a qualidade das respostas.

## 📋 Especificação (SDD)
- **Entradas**: Configuração de modelos, políticas de cache, limites de tokens.
- **Saídas**: Agentes otimizados para custo.
- **Side Effects**: Redução de chamadas de API.
- **Constraints Aplicáveis**: C1 (limites configuráveis), C5 (qualidade preservada), C7 (fallback para modelos mais baratos), C8 (métricas de custo).
- **Dependências**: `deepagents`, `langchain`, `redis`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    import json, datetime, os
    def mantis_log(level, event, detail=""):
        entry = {"ts": datetime.datetime.utcnow().isoformat() + "Z", "level": level, "tenant": os.getenv("TENANT_ID", "global"), "event": event, "detail": detail, "trace_id": os.getenv("TRACE_ID", "null"), "span_id": os.getenv("SPAN_ID", "null"), "fallback": "true"}
        print(json.dumps(entry), flush=True)
```

### 1. Escolha de Modelo por Complexidade da Tarefa

```python
from deepagents import create_deep_agent
from langchain.chat_models import init_chat_model

class CostOptimizedAgent:
    def __init__(self):
        self.cheap_model = init_chat_model("openai:gpt-4.1-mini", temperature=0)
        self.premium_model = init_chat_model("anthropic:claude-sonnet-4-6", temperature=0.3)

    def get_agent(self, task_complexity: str):
        if task_complexity == "simple":
            return create_deep_agent(model=self.cheap_model)
        else:
            return create_deep_agent(model=self.premium_model)

optimizer = CostOptimizedAgent()
agent = optimizer.get_agent("simple")
```

### 2. Cache de Respostas com Redis

```python
import redis
import hashlib

redis_client = redis.Redis(host='localhost', port=6379, decode_responses=True)

def cached_agent_invoke(agent, query, thread_id, ttl=3600):
    cache_key = f"agent:{thread_id}:{hashlib.md5(query.encode()).hexdigest()}"
    cached = redis_client.get(cache_key)
    if cached:
        mantis_log("INFO", "cache_hit", cache_key)
        return json.loads(cached)
    result = agent.invoke({"messages": [{"role": "user", "content": query}]})
    redis_client.setex(cache_key, ttl, json.dumps(result, default=str))
    return result
```

### 3. Prompt Compression com Resumo

```python
from langchain.agents.middleware.summarization import SummarizationMiddleware

agent = create_deep_agent(
    model="openai:gpt-5.4",
    middleware=[
        SummarizationMiddleware(
            model="openai:gpt-4.1-mini",  # Modelo barato para resumos
            max_tokens=6000,
            max_summary_tokens=1000,
        ),
    ],
)
```

### 4. Two‑Tier: Modelo Barato para Preview, Caro para Final

```python
@tool
def two_tier_response(query: str) -> str:
    """Gera resposta com fallback de modelo."""
    cheap_llm = init_chat_model("openai:gpt-4.1-mini")
    expensive_llm = init_chat_model("anthropic:claude-sonnet-4-6")

    preview = cheap_llm.invoke(query)
    if "não sei" in preview.content.lower() or len(preview.content) < 50:
        mantis_log("INFO", "fallback_premium", "Usando modelo premium")
        return expensive_llm.invoke(query).content
    return preview.content
```

### 5. Monitoramento de Custos por Thread

```python
from dataclasses import dataclass, field

@dataclass
class CostTracker:
    total_tokens: int = 0
    total_cost: float = 0.0
    calls: int = 0

    def record(self, usage_metadata):
        input_tokens = usage_metadata.get("input_tokens", 0)
        output_tokens = usage_metadata.get("output_tokens", 0)
        self.total_tokens += input_tokens + output_tokens
        # Preços aproximados (exemplo)
        cost = input_tokens * 0.000003 + output_tokens * 0.000015
        self.total_cost += cost
        self.calls += 1

tracker = CostTracker()
result = agent.invoke(...)
if hasattr(result["messages"][-1], 'usage_metadata'):
    tracker.record(result["messages"][-1].usage_metadata)
```

### 6. Limite de Tokens por Sessão

```python
session_limits = {}

def enforce_token_limit(thread_id, max_tokens=10000):
    if thread_id not in session_limits:
        session_limits[thread_id] = 0
    if session_limits[thread_id] >= max_tokens:
        raise Exception("Limite de tokens da sessão excedido")
    session_limits[thread_id] += 1

def instrumented_invoke(agent, input, config):
    thread_id = config["configurable"]["thread_id"]
    enforce_token_limit(thread_id)
    result = agent.invoke(input, config=config)
    return result
```

### 7. Uso de Skills para Reduzir Contexto Inicial

```python
# Skills são carregadas on‑demand, reduzindo tokens no prompt inicial.
agent = create_deep_agent(
    model="openai:gpt-5.4",
    skills=["/skills/"],
    # Apenas descrições são carregadas no início; o conteúdo completo só quando necessário.
)
```

### 8. Métricas e Alertas de Custo

```python
from prometheus_client import Counter, Gauge

tokens_consumed = Counter('agent_tokens_total', 'Total de tokens consumidos', ['model'])
estimated_cost = Gauge('agent_estimated_cost_usd', 'Custo estimado em USD')

def track_token_usage(model_name, usage_metadata):
    tokens = usage_metadata.get("total_tokens", 0)
    tokens_consumed.labels(model=model_name).inc(tokens)
    cost = tokens * 0.00001  # Estimativa
    estimated_cost.inc(cost)
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_cost_tracker():
    tracker = CostTracker()
    tracker.record({"input_tokens": 100, "output_tokens": 50})
    assert tracker.total_tokens == 150
    assert tracker.calls == 1

def test_cache_key():
    import hashlib
    key = hashlib.md5("test".encode()).hexdigest()
    assert len(key) == 32
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-cost-optimization.md --json
```

---

## 🔗 Referências Cruzadas (Wikilinks Mínimos)
- [[deep-agents-deployment-production.md]]
- [[langchain-langraph-master-agent.md]]

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-26T00:00:00Z | langchain-langraph-master-agent | Criação inicial: otimização de custos | C1,C5,C7,C8 |
