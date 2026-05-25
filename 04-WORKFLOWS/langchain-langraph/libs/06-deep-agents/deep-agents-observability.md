---
artifact_id: "deep-agents-observability"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C5","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-observability.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-observability.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-observability-v1.0.0"
generated_at: "2026-05-25T22:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-langsmith-integration"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 📊 Deep Agents – Observabilidade (Métricas, Logs e Dashboards)

> **Contrato modular**: Artefato filho do Master Agent. Define como instrumentar Deep Agents com métricas Prometheus, logs estruturados (V‑LOG‑02) e dashboards Grafana para monitoramento em produção.

---

## 🎯 Propósito
Garantir que agentes MANTIS sejam observáveis, permitindo detecção de anomalias, análise de desempenho e auditoria.

## 📋 Especificação (SDD)
- **Entradas**: Configuração de métricas e logs.
- **Saídas**: Métricas exportadas, logs estruturados.
- **Side Effects**: Coleta de métricas.
- **Constraints Aplicáveis**: C1 (formato de métrica), C5 (estrutura de log), C8 (observabilidade), C9 (tracing).
- **Dependências**: `prometheus-client`, `opentelemetry`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Métricas de Agente

```python
from prometheus_client import Counter, Histogram, Gauge, start_http_server

agent_invocations = Counter('agent_invocations_total', 'Total de invocações', ['model'])
agent_latency = Histogram('agent_latency_seconds', 'Latência das invocações')
tool_calls = Counter('tool_calls_total', 'Total de chamadas de ferramentas', ['tool_name'])
active_threads = Gauge('active_threads', 'Threads ativas')

start_http_server(8000)

@agent_latency.time()
def instrumented_invoke(agent, input_data, config):
    agent_invocations.labels(model='gpt-5.4').inc()
    return agent.invoke(input_data, config=config)
```

### 2. Logs Estruturados (V‑LOG‑02)

```python
def log_agent_event(event, **kwargs):
    entry = {
        "ts": datetime.datetime.utcnow().isoformat() + "Z",
        "event": event,
        "tenant": os.getenv("TENANT_ID", "global"),
        "trace_id": os.getenv("TRACE_ID", "null"),
        "span_id": os.getenv("SPAN_ID", "null"),
    }
    entry.update(kwargs)
    mantis_log("INFO", event, json.dumps(entry))
```

### 3. Dashboard Grafana (JSON)

```json
{
  "title": "Deep Agents Overview",
  "panels": [
    {"title": "Invocations", "targets": [{"expr": "rate(agent_invocations_total[5m])"}]},
    {"title": "Latency p95", "targets": [{"expr": "histogram_quantile(0.95, rate(agent_latency_seconds_bucket[5m]))"}]},
    {"title": "Tool Calls", "targets": [{"expr": "rate(tool_calls_total[5m])"}]}
  ]
}
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_metrics_registered():
    assert agent_invocations is not None
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-observability.md --json
```

---

## 🔗 Referências Cruzadas
- [[deep-agents-langsmith-integration.md]]
