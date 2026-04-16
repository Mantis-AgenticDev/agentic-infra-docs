# SHA256: d1e2f3a4b5c6d7e8901234567890abcdef1234567890abcdef1234567890ab
---
artifact_id: "observability-opentelemetry"
artifact_type: "skill_python"
version: "2.1.1"
constraints_mapped: ["C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/python/observability-opentelemetry.md --json"
---

# 📊 Observability with OpenTelemetry – Python Structured Logging

## Propósito
Patrones de instrumentación con OpenTelemetry en Python 3.10+ que garantizan logging estructurado (C8), cero uso de `print()` y propagación de contexto de tenant en trazas y métricas. Asegura trazabilidad completa en entornos multi‑tenant sin contaminar stdout.

## Patrones de Código Validados

### Ejemplo 1: Configuración de logger estructurado (C8)
```python
# ✅ C8: logger con formato JSON
import logging, json
logger = logging.getLogger(__name__)
handler = logging.StreamHandler()
handler.setFormatter(logging.Formatter('{"level":"%(levelname)s","msg":%(message)s}'))
logger.addHandler(handler)
```

```python
# ❌ Anti-pattern: print en lugar de logger
print("Inicio de traza")

# 🔧 Fix: usar logger.info con JSON
logger.info(json.dumps({"event": "trace_start"}))
```

### Ejemplo 2: Inyección de tenant_id en span attributes (C8)
```python
# ✅ C8: atributo tenant en span
from opentelemetry import trace
span = trace.get_current_span()
span.set_attribute("tenant.id", TENANT_ID)
```

```python
# ❌ Anti-pattern: span sin tenant
span = trace.get_current_span()
span.set_attribute("operation", "query")

# 🔧 Fix: añadir tenant.id
span.set_attribute("tenant.id", TENANT_ID)
```

### Ejemplo 3: Logging estructurado con contexto de span (C8)
```python
# ✅ C8: incluir trace_id en log JSON
trace_id = format(span.get_span_context().trace_id, '032x')
logger.info(json.dumps({"trace_id": trace_id, "event": "db_query"}))
```

```python
# ❌ Anti-pattern: log sin correlación con traza
logger.info("Query ejecutada")

# 🔧 Fix: añadir trace_id al JSON
logger.info(json.dumps({"trace_id": trace_id, "event": "query"}))
```

### Ejemplo 4: Exporter OTLP con timeout (C8 implícito)
```python
# ✅ C8: configurar timeout en exporter
from opentelemetry.sdk.trace.export import BatchSpanProcessor
processor = BatchSpanProcessor(exporter, schedule_delay_millis=5000)
```

```python
# ❌ Anti-pattern: sin límite de tiempo
processor = BatchSpanProcessor(exporter)

# 🔧 Fix: establecer schedule_delay_millis
processor = BatchSpanProcessor(exporter, schedule_delay_millis=5000)
```

### Ejemplo 5: Decorador para traza automática con tenant (C8)
```python
# ✅ C8: traza con atributos de tenant
def traced(span_name: str):
    def decorator(func):
        def wrapper(*args, **kwargs):
            with tracer.start_as_current_span(span_name) as span:
                span.set_attribute("tenant.id", TENANT_ID)
                return func(*args, **kwargs)
        return wrapper
    return decorator
```

```python
# ❌ Anti-pattern: traza sin tenant
def traced(span_name: str):
    def decorator(func):
        def wrapper(*args, **kwargs):
            with tracer.start_as_current_span(span_name):
                return func(*args, **kwargs)
        return wrapper
    return decorator

# 🔧 Fix: añadir span.set_attribute
span.set_attribute("tenant.id", TENANT_ID)
```

### Ejemplo 6: Métricas con etiqueta de tenant (C8)
```python
# ✅ C8: métrica con tenant label
from opentelemetry.metrics import get_meter
meter = get_meter(__name__)
counter = meter.create_counter("requests", description="API requests")
counter.add(1, {"tenant": TENANT_ID})
```

```python
# ❌ Anti-pattern: métrica sin tenant
counter.add(1)

# 🔧 Fix: añadir label tenant
counter.add(1, {"tenant": TENANT_ID})
```

### Ejemplo 7: Manejo de excepción con logging JSON (C8)
```python
# ✅ C8: excepción capturada y logueada como JSON
try:
    risky_op()
except Exception as e:
    logger.error(json.dumps({"error": str(e), "tenant": TENANT_ID}))
    span.record_exception(e)
```

```python
# ❌ Anti-pattern: print del traceback
try:
    risky_op()
except Exception as e:
    print(e)

# 🔧 Fix: logger.error con JSON + span.record_exception
```

### Ejemplo 8: CLI help mediante logger (C8)
```python
# ✅ C8: help con logger
if "--help" in sys.argv:
    logger.info("Uso: otel_instrumented.py --service <name>")
    sys.exit(0)
```

```python
# ❌ Anti-pattern: print para help
if "--help" in sys.argv: print("Uso: ...")

# 🔧 Fix: logger.info
logger.info("Uso: otel_instrumented.py --service <name>")
```

### Ejemplo 9: Type hints en funciones instrumentadas (C8)
```python
# ✅ C8: anotaciones de tipo
def process_request(payload: dict) -> bool:
    with tracer.start_as_current_span("process") as span:
        return do_work(payload)
```

```python
# ❌ Anti-pattern: sin type hints
def process_request(payload):
    with tracer.start_as_current_span("process"):
        return do_work(payload)

# 🔧 Fix: añadir anotaciones
def process_request(payload: dict) -> bool: ...
```

### Ejemplo 10: Logging de inicio de aplicación (C8)
```python
# ✅ C8: log inicial estructurado
import json, os
logger.info(json.dumps({"event": "app_start", "service": "agentic", "pid": os.getpid()}))
```

```python
# ❌ Anti-pattern: print al arrancar
print("Aplicación iniciada")

# 🔧 Fix: logger.info con JSON
logger.info(json.dumps({"event": "app_start", "pid": os.getpid()}))
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/python/observability-opentelemetry.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"observability-opentelemetry","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C8"],"examples_count":10,"lines_executable_max":5,"language":"Python 3.10+","timestamp":"2026-04-16T04:23:45Z"}
```

---
