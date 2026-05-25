---
artifact_id: "database-observability-monitoring"
artifact_type: "workflow_skill"
version: "2.0.0"
constraints_mapped: ["C1","C5","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/database-observability-monitoring.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/database-observability-monitoring.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:db-observability-v2.0.0"
generated_at: "2026-05-25T12:20:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["observability-langsmith", "postgresql-pgvector-enterprise"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Refundado"
next_review: "2026-06-24"
---

# 📊 Database Observability & Monitoring – Métricas, Tracing e Dashboards

> **Contrato modular**: Instrumentação completa de operações de banco de dados com Prometheus, OpenTelemetry, logging estruturado (V‑LOG‑02) e dashboards Grafana.

---

## 🎯 Propósito
Garantir visibilidade total sobre a performance e saúde das bases de dados, detectando anomalias, latência e gargalos.

## 📋 Especificação (SDD)
- **Entradas**: Conexões de banco, queries.
- **Saídas**: Métricas, traces, logs.
- **Side Effects**: Coleta de métricas e envio para coletor.
- **Constraints Aplicáveis**: C1 (formato de métrica), C5 (estrutura de log), C8 (observabilidade), C9 (tracing).
- **Dependências**: `prometheus-client`, `opentelemetry`, `sqlalchemy`.

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

### 1. Métricas Prometheus para PostgreSQL
```python
from prometheus_client import Gauge, Histogram, Counter, start_http_server

# Métricas de conexão
pg_connections_active = Gauge('pg_connections_active', 'Conexões ativas', ['database'])
pg_connections_idle = Gauge('pg_connections_idle', 'Conexões ociosas', ['database'])
pg_query_duration = Histogram('pg_query_duration_seconds', 'Duração das queries', ['query_type'])
pg_errors = Counter('pg_errors_total', 'Total de erros', ['error_type'])

def collect_pool_metrics(engine):
    pool = engine.pool
    pg_connections_active.labels(database='mantis').set(pool.checkedout())
    pg_connections_idle.labels(database='mantis').set(pool.size() - pool.checkedout())

@pg_query_duration.labels(query_type='select').time()
def instrumented_select(query):
    try:
        with engine.connect() as conn:
            return conn.execute(text(query))
    except Exception as e:
        pg_errors.labels(error_type=type(e).__name__).inc()
        raise

start_http_server(8000)
```

### 2. Tracing com OpenTelemetry
```python
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

trace.set_tracer_provider(TracerProvider())
trace.get_tracer_provider().add_span_processor(BatchSpanProcessor(OTLPSpanExporter()))
tracer = trace.get_tracer(__name__)

def traced_query(query):
    with tracer.start_as_current_span("db_query") as span:
        span.set_attribute("query", query)
        span.set_attribute("tenant", os.getenv("TENANT_ID", "global"))
        result = engine.execute(text(query))
        span.set_attribute("rows", result.rowcount)
        return result
```

### 3. Logging Estruturado (V‑LOG‑02)
```python
def log_query(query, duration_ms, status="success"):
    mantis_log("INFO", "db_query", json.dumps({
        "query": query[:200],
        "duration_ms": duration_ms,
        "status": status,
        "tenant": os.getenv("TENANT_ID")
    }))
```

### 4. Dashboard Grafana (JSON de exemplo)
```json
{
  "title": "Database Overview",
  "panels": [
    {"title": "Active Connections", "targets": [{"expr": "pg_connections_active{database='mantis'}"}]},
    {"title": "Query Duration", "targets": [{"expr": "rate(pg_query_duration_seconds_sum[5m])"}]},
    {"title": "Error Rate", "targets": [{"expr": "rate(pg_errors_total[5m])"}]}
  ]
}
```

---

## 🧪 Testes Unitários (TDD)
```python
def test_metrics_registered():
    assert pg_connections_active is not None
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/database-observability-monitoring.md --json
```

---

## 🔗 Referências Cruzadas
- [[observability-langsmith.md]]
