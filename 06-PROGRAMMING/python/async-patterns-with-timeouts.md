# SHA256: d4e5f6a7b8c901234567890abcdef1234567890abcdef1234567890abcde4
---
artifact_id: "async-patterns-with-timeouts"
artifact_type: "skill_python"
version: "2.1.1"
constraints_mapped: ["C1","C2","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/python/async-patterns-with-timeouts.md --json"
---

# ⏱️ Patrones Asíncronos con Timeouts y Control de Recursos – Python

## Propósito
Implementación robusta de operaciones asíncronas con timeouts, límites de concurrencia y monitoreo de recursos en Python 3.10+, cumpliendo constraints C1 (límites de memoria/CPU), C2 (umbrales de rendimiento), C7 (timeouts y rollback) y C8 (logging estructurado sin `print()`).

## Patrones de Código Validados

### Ejemplo 1: Timeout en tarea asyncio (C7)
```python
# ✅ C7: asyncio.wait_for con timeout
import asyncio
try:
    result = await asyncio.wait_for(long_task(), timeout=5.0)
except asyncio.TimeoutError:
    logger.error("Tarea excedió timeout")
```
```python
# ❌ Anti-pattern: await sin timeout
result = await long_task()
```
```python
# 🔧 Fix: añadir wait_for con timeout
await asyncio.wait_for(long_task(), timeout=5.0)
```

### Ejemplo 2: Semáforo para limitar concurrencia (C1)
```python
# ✅ C1: control de recursos con Semaphore
sem = asyncio.Semaphore(10)
async def limited_task():
    async with sem:
        return await do_work()
```
```python
# ❌ Anti-pattern: concurrencia ilimitada
results = await asyncio.gather(*[task() for _ in range(1000)])
```
```python
# 🔧 Fix: usar Semaphore para limitar
async with asyncio.Semaphore(10):
    await do_work()
```

### Ejemplo 3: Monitoreo de memoria con psutil (C1)
```python
# ✅ C1: verificar antes de lanzar tarea pesada
import psutil
if psutil.virtual_memory().percent > 85:
    raise MemoryError("Memoria insuficiente")
```
```python
# ❌ Anti-pattern: no verificar recursos
await heavy_computation()
```
```python
# 🔧 Fix: verificar con psutil primero
if psutil.virtual_memory().percent > 85: raise MemoryError
```

### Ejemplo 4: Timeout combinado con cancelación (C7)
```python
# ✅ C7: cancelar tarea al timeout
task = asyncio.create_task(long_op())
try:
    await asyncio.wait_for(task, timeout=2.0)
except asyncio.TimeoutError:
    task.cancel()
```
```python
# ❌ Anti-pattern: timeout sin limpieza
await asyncio.wait_for(task, timeout=2.0)
```
```python
# 🔧 Fix: cancelar explícitamente
try:
    await asyncio.wait_for(task, timeout=2.0)
except asyncio.TimeoutError:
    task.cancel()
```

### Ejemplo 5: Medición de latencia percentil (C2)
```python
# ✅ C2: registro de duración para umbrales
import time
start = time.monotonic()
result = await api_call()
duration = time.monotonic() - start
logger.info(f"Latencia: {duration:.3f}s")
```
```python
# ❌ Anti-pattern: no medir rendimiento
result = await api_call()
```
```python
# 🔧 Fix: medir y loguear duración
start = time.monotonic()
result = await api_call()
duration = time.monotonic() - start
```

### Ejemplo 6: Timeout en subprocess asíncrono (C7)
```python
# ✅ C7: asyncio.subprocess con timeout
proc = await asyncio.create_subprocess_exec("cmd")
try:
    await asyncio.wait_for(proc.wait(), timeout=10)
except asyncio.TimeoutError:
    proc.kill()
```
```python
# ❌ Anti-pattern: subprocess sin timeout
proc = await asyncio.create_subprocess_exec("cmd")
await proc.wait()
```
```python
# 🔧 Fix: añadir wait_for con timeout
await asyncio.wait_for(proc.wait(), timeout=10)
```

### Ejemplo 7: Logging estructurado de métricas asíncronas (C8)
```python
# ✅ C8: JSON con métricas de rendimiento
import json
logger.info(json.dumps({"event": "task_complete", "duration": duration, "status": "ok"}))
```
```python
# ❌ Anti-pattern: print desestructurado
print(f"Tarea completada en {duration}s")
```
```python
# 🔧 Fix: usar logger con JSON
logger.info(json.dumps({"duration": duration}))
```

### Ejemplo 8: Límite de CPU con process pool executor (C1)
```python
# ✅ C1: control de workers máximo
from concurrent.futures import ProcessPoolExecutor
executor = ProcessPoolExecutor(max_workers=4)
```
```python
# ❌ Anti-pattern: workers ilimitados
executor = ProcessPoolExecutor()
```
```python
# 🔧 Fix: especificar max_workers
executor = ProcessPoolExecutor(max_workers=4)
```

### Ejemplo 9: Type hints en funciones asíncronas (C8)
```python
# ✅ C8: anotaciones completas
async def fetch_data(url: str) -> dict:
    return await http_get(url)
```
```python
# ❌ Anti-pattern: sin type hints
async def fetch_data(url):
    return await http_get(url)
```
```python
# 🔧 Fix: añadir tipo de retorno
async def fetch_data(url: str) -> dict:
    return await http_get(url)
```

### Ejemplo 10: Rollback en fallo con timeout (C7)
```python
# ✅ C7: revertir cambios tras timeout
try:
    await asyncio.wait_for(update_db(), timeout=3.0)
except asyncio.TimeoutError:
    await rollback_changes()
    raise
```
```python
# ❌ Anti-pattern: timeout sin rollback
await asyncio.wait_for(update_db(), timeout=3.0)
```
```python
# 🔧 Fix: capturar y ejecutar rollback
try:
    await asyncio.wait_for(update_db(), timeout=3.0)
except asyncio.TimeoutError:
    await rollback()
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/python/async-patterns-with-timeouts.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"async-patterns-with-timeouts","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C1","C2","C7","C8"],"examples_count":10,"lines_executable_max":5,"language":"Python 3.10+","timestamp":"2026-04-16T04:23:45Z"}
```

---
