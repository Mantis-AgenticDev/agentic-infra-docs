---
artifact_id: "mcp-observability-logging"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C5","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/mcp-observability-logging.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/mcp-observability-logging.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:mcp-observability-v1.0.0"
generated_at: "2026-05-25T02:20:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["mcp-client-multi-server", "observability-langsmith"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 📊 MCP Observability & Logging – Tracing, Métricas e Callbacks

> **Contrato modular**: Detalha como instrumentar servidores e clientes MCP usando os callbacks nativos (progresso, logging) e como integrar com o ecossistema de observabilidade MANTIS (V-LOG-02, OpenTelemetry).

---

## 🎯 Propósito
Permitir visibilidade total sobre o funcionamento dos servidores MCP, facilitando diagnóstico de falhas, auditoria e otimização.

## 📋 Especificação (SDD)
- **Entradas**: Eventos de execução (progresso, logs) gerados pelo servidor MCP.
- **Saídas**: Métricas e logs centralizados.
- **Side Effects**: Escrita em sistemas de telemetria.
- **Constraints Aplicáveis**: C1 (formato de log), C5 (estrutura), C8 (observabilidade), C9 (tracing distribuído).
- **Dependências**: `langchain-mcp-adapters`, `opentelemetry`.

---

## 🛡️ Bootstrap (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ... (fallback)
```

### 1. Callbacks de Progresso e Logging no Cliente
```python
from langchain_mcp_adapters.callbacks import Callbacks, CallbackContext

async def on_progress(progress: float, total: float | None, message: str | None, context: CallbackContext):
    mantis_log("INFO", "mcp_progress", f"{context.server_name}/{context.tool_name}: {message} ({progress}/{total})")

async def on_logging_message(params, context: CallbackContext):
    mantis_log(params.level.upper(), "mcp_log", f"[{context.server_name}] {params.data}")

client = MultiServerMCPClient(
    {...},
    callbacks=Callbacks(on_progress=on_progress, on_logging_message=on_logging_message)
)
```

### 2. Integração com OpenTelemetry
```python
from opentelemetry import trace
tracer = trace.get_tracer(__name__)

@mcp.tool()
async def traced_tool(query: str) -> str:
    with tracer.start_as_current_span("mcp_tool_execution") as span:
        span.set_attribute("tool.name", "traced_tool")
        span.set_attribute("query", query)
        try:
            result = await some_operation(query)
            span.set_attribute("status", "success")
            return result
        except Exception as e:
            span.record_exception(e)
            span.set_attribute("status", "error")
            raise
```

### 3. Logs JSONL no Servidor (V-LOG-02)
```python
def server_log(level, event, detail=""):
    entry = {
        "ts": datetime.datetime.utcnow().isoformat() + "Z",
        "level": level,
        "server": "weather_mcp",
        "event": event,
        "detail": detail,
        "trace_id": os.getenv("TRACE_ID", ""),
        "span_id": os.getenv("SPAN_ID", "")
    }
    print(json.dumps(entry), file=sys.stderr)
```

### 4. Métricas com Prometheus
```python
from prometheus_client import Counter, Histogram
mcp_calls = Counter('mcp_tool_calls_total', 'Total calls', ['tool_name'])
mcp_duration = Histogram('mcp_tool_duration_seconds', 'Duration', ['tool_name'])

@mcp.tool()
@mcp_duration.labels(tool_name="get_weather").time()
def get_weather(city: str) -> str:
    mcp_calls.labels(tool_name="get_weather").inc()
    return "sunny"
```

---

## 🧪 Testes Unitários (TDD)
```python
def test_server_log_format():
    # Verificar que o log é JSON válido e contém campos obrigatórios
    ...
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/mcp-observability-logging.md --json
```

---

## 🔗 Referências Cruzadas
- [[observability-langsmith.md]]
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]]
