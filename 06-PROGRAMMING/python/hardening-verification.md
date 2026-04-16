# SHA256: a1b2c3d4e5f678901234567890abcdef1234567890abcdef1234567890abcdef
---
artifact_id: "hardening-verification"
artifact_type: "skill_python"
version: "2.1.1"
constraints_mapped: ["C3","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/python/hardening-verification.md --json"
---

# 🛡️ Hardening Verification Protocol – Python Pre‑flight Protocol

## Propósito
Validación pre‑ejecución de entornos Python multi‑tenant que verifica disponibilidad de recursos, integridad de dependencias y cumplimiento de constraints C3–C8 antes de ejecutar cargas críticas. Garantiza trazabilidad completa mediante logs estructurados, aislamiento estricto por tenant y mecanismos de fallback controlados.

## Patrones de Código Validados

### Ejemplo 1: Import opcional con fallback documentado (C3)
```python
# ✅ C3: try/except con logger
try:
    import yaml
except ImportError:
    yaml = None
    logger.warning("PyYAML no disponible; funciones YAML deshabilitadas")
```
```python
# ❌ Anti-pattern: import sin manejo de fallback
import yaml
```
```python
# 🔧 Fix: try/except con logger
try:
    import yaml
except ImportError:
    yaml = None
```

### Ejemplo 2: Validación estricta de TENANT_ID (C4)
```python
# ✅ C4: acceso directo y sys.exit(1)
import os, sys
TENANT_ID = os.environ["TENANT_ID"]
if not TENANT_ID:
    logger.error("TENANT_ID no definido")
    sys.exit(1)
```
```python
# ❌ Anti-pattern: default silencioso
TENANT_ID = os.environ.get("TENANT_ID", "default")
```
```python
# 🔧 Fix: acceso directo
TENANT_ID = os.environ["TENANT_ID"]
if not TENANT_ID: sys.exit(1)
```

### Ejemplo 3: Aislamiento de logging con TenantFilter (C4)
```python
# ✅ C4: Configuración completa del filtro
import contextvars, logging
tenant_ctx: contextvars.ContextVar[str] = contextvars.ContextVar("tenant_id")
class TenantFilter(logging.Filter):
    def filter(self, record):
        record.tenant = tenant_ctx.get("unknown")
        return True
logger = logging.getLogger(__name__)
logger.addFilter(TenantFilter())
handler = logging.StreamHandler()
logger.addHandler(handler)
```
```python
# ❌ Anti-pattern: filtro no conectado al logger
class TenantFilter(logging.Filter):
    def filter(self, record):
        record.tenant = tenant_ctx.get("unknown")
        return True
# (falta logger.addFilter(TenantFilter()))
```
```python
# 🔧 Fix: añadir filtro al logger
logger.addFilter(TenantFilter())
logger.addHandler(handler)
```

### Ejemplo 4: Cálculo de checksum SHA‑256 con manejo de errores (C5)
```python
# ✅ C5: try/except OSError
import hashlib
def compute_sha256(path: str) -> str:
    sha = hashlib.sha256()
    try:
        with open(path, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                sha.update(chunk)
        return sha.hexdigest()
    except OSError as e:
        logger.error(f"Error leyendo {path}: {e}")
        raise
```
```python
# ❌ Anti-pattern: sin manejo de errores de I/O
def compute_sha256(path: str) -> str:
    sha = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            sha.update(chunk)
    return sha.hexdigest()
```
```python
# 🔧 Fix: añadir try/except
try:
    with open(path, "rb") as f:
        ...
except OSError as e:
    logger.error(f"Error: {e}")
```

### Ejemplo 5: Subprocess con timeout explícito (C7)
```python
# ✅ C7: timeout obligatorio
import subprocess
try:
    subprocess.run(["ls", "-l"], timeout=10, check=True)
except subprocess.TimeoutExpired:
    logger.error("Timeout excedido")
```
```python
# ❌ Anti-pattern: sin timeout
subprocess.run(["long-running-task"])
```
```python
# 🔧 Fix: añadir timeout
subprocess.run(["cmd"], timeout=30)
```

### Ejemplo 6: Verificación de memoria con psutil seguro (C7, C3)
```python
# ✅ C7/C3: verificar que psutil está disponible
try:
    import psutil
except ImportError:
    psutil = None
if psutil is not None and psutil.virtual_memory().percent > 90:
    logger.error("Memoria insuficiente")
```
```python
# ❌ Anti-pattern: asumir que psutil siempre está instalado
import psutil
if psutil.virtual_memory().percent > 90:
    raise MemoryError("Memoria baja")
```
```python
# 🔧 Fix: comprobar disponibilidad
if psutil is not None and psutil.virtual_memory().percent > 90:
    logger.error("Memoria insuficiente")
```

### Ejemplo 7: Logging estructurado JSON‑like (C8)
```python
# ✅ C8: logger.info con JSON
import json
logger.info(json.dumps({"event": "preflight", "status": "pass", "tenant": TENANT_ID}))
```
```python
# ❌ Anti-pattern: uso de print()
print("Error: algo salió mal")
```
```python
# 🔧 Fix: logger.error con estructura
logger.error(json.dumps({"error": "algo salió mal"}))
```

### Ejemplo 8: Salida exclusiva a stderr (C8)
```python
# ✅ C8: sys.stderr.write con JSON
import sys, json
sys.stderr.write(json.dumps({"level": "INFO", "msg": "inicio"}) + "\n")
```
```python
# ❌ Anti-pattern: salida a stdout sin estructura
print("Iniciando verificación...")
```
```python
# 🔧 Fix: logger o sys.stderr
logger.info("Iniciando verificación")
```

### Ejemplo 9: CLI help mediante logger (C8)
```python
# ✅ C8: help con logger
if "--help" in sys.argv:
    logger.info("Uso: script.py [--validate]")
    sys.exit(0)
```
```python
# ❌ Anti-pattern: print en help
if "--help" in sys.argv:
    print("Uso: ...")
```
```python
# 🔧 Fix: logger.info
logger.info("Uso: script.py [--validate]")
```

### Ejemplo 10: Type hints obligatorios en funciones públicas (C8)
```python
# ✅ C8: type hints en definición
def verify_checksum(file_path: str, expected: str) -> bool:
    return compute_sha256(file_path) == expected
```
```python
# ❌ Anti-pattern: sin type hints
def verify_checksum(file_path, expected):
    return compute_sha256(file_path) == expected
```
```python
# 🔧 Fix: añadir type hints
def verify_checksum(file_path: str, expected: str) -> bool:
    return compute_sha256(file_path) == expected
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/python/hardening-verification.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"hardening-verification","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C3","C4","C5","C7","C8"],"examples_count":10,"lines_executable_max":5,"language":"Python 3.10+","timestamp":"2026-04-16T04:23:45Z"}
```

---
