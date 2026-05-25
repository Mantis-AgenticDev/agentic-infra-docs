---
artifact_id: "database-connection-pooling"
artifact_type: "workflow_skill"
version: "2.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/database-connection-pooling.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/database-connection-pooling.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:db-pooling-v2.0.0"
generated_at: "2026-05-25T12:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["postgresql-pgvector-enterprise", "cost-optimization"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Refundado"
next_review: "2026-06-24"
---

# 🏊 Database Connection Pooling – Resiliência e Performance com PgBouncer, SQLAlchemy e Circuit Breaker

> **Contrato modular**: Estratégias completas de pooling, retry, circuit breaker e timeouts para conexões de banco de dados, garantindo resiliência e monitoramento.

---

## 🎯 Propósito
Evitar exaustão de conexões e latência excessiva ao acessar bases de dados, usando PgBouncer, SQLAlchemy pool, tenacity e circuit breaker.

## 📋 Especificação (SDD)
- **Entradas**: Configuração de pool, parâmetros de retry.
- **Saídas**: Conexões gerenciadas e resilientes.
- **Side Effects**: Alocação de recursos de rede.
- **Constraints Aplicáveis**: C1 (limites de pool), C3 (segurança), C7 (fallback e retry), C8 (métricas).
- **Dependências**: `sqlalchemy`, `tenacity`, `circuitbreaker`, `prometheus-client`.

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

### 1. Configuração de Pool com SQLAlchemy
```python
from sqlalchemy import create_engine
from sqlalchemy.pool import QueuePool

engine = create_engine(
    "postgresql+psycopg://user:pass@localhost/mantis",
    poolclass=QueuePool,
    pool_size=10,
    max_overflow=5,
    pool_pre_ping=True,   # Verifica se a conexão está viva antes de usar
    pool_recycle=3600,    # Recicla conexões a cada 1 hora
    echo=False
)
```

### 2. Retry com Backoff Exponencial usando Tenacity
```python
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type
from sqlalchemy.exc import OperationalError

@retry(
    retry=retry_if_exception_type(OperationalError),
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=1, max=10)
)
def execute_with_retry(query):
    with engine.connect() as conn:
        return conn.execute(text(query))
```

### 3. Circuit Breaker com `pybreaker`
```python
import pybreaker

db_breaker = pybreaker.CircuitBreaker(fail_max=5, reset_timeout=30)

@db_breaker
def protected_query(query):
    return execute_with_retry(query)

# Fallback
def query_with_fallback(query):
    try:
        return protected_query(query)
    except pybreaker.CircuitBreakerError:
        mantis_log("WARN", "circuit_open", "Usando cache local")
        return cached_results.get(query, [])
```

### 4. Configuração do PgBouncer (Docker Compose)
```yaml
  pgbouncer:
    image: edoburu/pgbouncer
    environment:
      DB_USER: admin
      DB_PASSWORD: secret
      DB_HOST: postgres
      DB_NAME: mantis
      POOL_MODE: transaction
      MAX_CLIENT_CONN: 100
      DEFAULT_POOL_SIZE: 20
    ports:
      - "6432:6432"
```

### 5. Métricas de Pool com Prometheus
```python
from prometheus_client import Gauge, Histogram

pool_size_metric = Gauge('db_pool_size', 'Tamanho atual do pool')
pool_checked_out = Gauge('db_pool_checked_out', 'Conexões em uso')
query_duration = Histogram('db_query_duration_seconds', 'Duração das queries')

def instrumented_query(query):
    pool = engine.pool
    pool_size_metric.set(pool.size())
    pool_checked_out.set(pool.checkedout())
    with query_duration.time():
        return engine.execute(query)
```

---

## 🧪 Testes Unitários (TDD)
```python
def test_retry():
    with pytest.raises(OperationalError):
        @retry(stop=stop_after_attempt(2))
        def flaky():
            raise OperationalError("test", {}, BaseException())
        flaky()
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/database-connection-pooling.md --json
```

---

## 🔗 Referências Cruzadas
- [[postgresql-pgvector-enterprise.md]]
