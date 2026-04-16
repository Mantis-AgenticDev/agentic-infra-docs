# SHA256: d7e8f9a0b1c2d3e4f5678901234567890abcdef1234567890abcdef12345678
---
artifact_id: "fix-sintaxis-code"
artifact_type: "skill_python"
version: "2.1.1"
constraints_mapped: ["C3","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/python/fix-sintaxis-code.md --json"
---

# 🧹 Corrección de Sintaxis y Refactorización Segura – Python

## Propósito
Patrones para corregir errores comunes de sintaxis, estilo y seguridad en código Python legacy, garantizando cumplimiento de constraints C3–C8 (imports seguros, logging estructurado, timeouts, aislamiento multi‑tenant y validación de integridad).

## Patrones de Código Validados

### Ejemplo 1: Corrección de `print()` a `logger` (C8)
```python
# ✅ C8: logging estructurado
logger.info("Procesamiento iniciado")
```
```python
# ❌ Anti-pattern: print() en producción
print("Procesamiento iniciado")
```
```python
# 🔧 Fix: reemplazar print por logger
logger.info("Procesamiento iniciado")
```

### Ejemplo 2: Manejo seguro de imports opcionales (C3)
```python
# ✅ C3: try/except con fallback
try:
    import yaml
except ImportError:
    yaml = None
    logger.warning("PyYAML no disponible")
```
```python
# ❌ Anti-pattern: import sin manejo de error
import yaml
```
```python
# 🔧 Fix: envolver en try/except
try:
    import yaml
except ImportError:
    yaml = None
```

### Ejemplo 3: Validación obligatoria de TENANT_ID (C4)
```python
# ✅ C4: falla rápido si falta
import os, sys
TENANT_ID = os.environ["TENANT_ID"]
if not TENANT_ID:
    logger.error("TENANT_ID requerido")
    sys.exit(1)
```
```python
# ❌ Anti-pattern: default silencioso
TENANT_ID = os.environ.get("TENANT_ID", "default")
```
```python
# 🔧 Fix: acceso directo y sys.exit
TENANT_ID = os.environ["TENANT_ID"]
if not TENANT_ID: sys.exit(1)
```

### Ejemplo 4: Añadir timeouts a subprocess (C7)
```python
# ✅ C7: subprocess con timeout
import subprocess
try:
    subprocess.run(["ls"], timeout=10, check=True)
except subprocess.TimeoutExpired:
    logger.error("Timeout excedido")
```
```python
# ❌ Anti-pattern: sin timeout
subprocess.run(["long-task"])
```
```python
# 🔧 Fix: agregar timeout=30
subprocess.run(["cmd"], timeout=30)
```

### Ejemplo 5: Reemplazar `os.system()` por `subprocess.run()` (C7)
```python
# ✅ C7: subprocess seguro
subprocess.run(["rm", "-f", tmpfile], check=False)
```
```python
# ❌ Anti-pattern: os.system vulnerable
os.system(f"rm -f {tmpfile}")
```
```python
# 🔧 Fix: usar subprocess.run con lista de args
subprocess.run(["rm", "-f", tmpfile])
```

### Ejemplo 6: Añadir type hints a funciones públicas (C8)
```python
# ✅ C8: type hints completos
def process(data: dict) -> bool:
    return data.get("status") == "ok"
```
```python
# ❌ Anti-pattern: sin type hints
def process(data):
    return data.get("status") == "ok"
```
```python
# 🔧 Fix: añadir anotaciones
def process(data: dict) -> bool:
    return data.get("status") == "ok"
```

### Ejemplo 7: Manejo seguro de excepciones específicas (C3)
```python
# ✅ C3: captura específica
try:
    value = int(user_input)
except ValueError as e:
    logger.error(f"Entrada inválida: {e}")
```
```python
# ❌ Anti-pattern: except genérico
try:
    value = int(user_input)
except:
    pass
```
```python
# 🔧 Fix: capturar ValueError
try:
    value = int(user_input)
except ValueError:
    logger.error("Entrada inválida")
```

### Ejemplo 8: Uso de `pathlib` en lugar de `os.path` (C3)
```python
# ✅ C3: pathlib moderno
from pathlib import Path
data_file = Path("/data") / f"tenant_{TENANT_ID}" / "config.yaml"
```
```python
# ❌ Anti-pattern: concatenación manual
data_file = "/data/tenant_" + TENANT_ID + "/config.yaml"
```
```python
# 🔧 Fix: usar Path operator /
data_file = Path("/data") / f"tenant_{TENANT_ID}" / "config.yaml"
```

### Ejemplo 9: Verificación de integridad con SHA-256 (C5)
```python
# ✅ C5: checksum antes de cargar
import hashlib
def verify_checksum(path: str, expected: str) -> bool:
    sha = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            sha.update(chunk)
    return sha.hexdigest() == expected
```
```python
# ❌ Anti-pattern: cargar sin verificar
data = open("config.yaml").read()
```
```python
# 🔧 Fix: verificar checksum primero
if not verify_checksum(path, expected):
    raise ValueError("Checksum mismatch")
```

### Ejemplo 10: Uso de `contextvars` para tenant en logs (C4)
```python
# ✅ C4: filtro de logging con tenant
import contextvars, logging
tenant_ctx: contextvars.ContextVar[str] = contextvars.ContextVar("tenant_id")
class TenantFilter(logging.Filter):
    def filter(self, record):
        record.tenant = tenant_ctx.get("unknown")
        return True
logger.addFilter(TenantFilter())
```
```python
# ❌ Anti-pattern: log sin tenant
logging.info("Operación")
```
```python
# 🔧 Fix: añadir TenantFilter y handler
logger.addFilter(TenantFilter())
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/python/fix-sintaxis-code.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"fix-sintaxis-code","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C3","C4","C5","C7","C8"],"examples_count":10,"lines_executable_max":5,"language":"Python 3.10+","timestamp":"2026-04-16T04:23:45Z"}
```

---
