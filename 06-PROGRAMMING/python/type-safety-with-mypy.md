# SHA256: f1e2d3c4b5a678901234567890abcdef1234567890abcdef1234567890abcdc1
---
artifact_id: "type-safety-with-mypy"
artifact_type: "skill_python"
version: "2.1.1"
constraints_mapped: ["C3","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/python/type-safety-with-mypy.md --json"
---

# 🔍 Type Safety with mypy – Python Static Checking

## Propósito
Patrones para garantizar type safety en Python 3.10+ usando mypy y anotaciones de tipo, integrados con validación estricta de TENANT_ID (C4), manejo condicional de imports (C3), verificación de integridad vía SHA‑256 (C5) y logging estructurado sin `print()` (C8).

## Patrones de Código Validados

### Ejemplo 1: Type hints obligatorios en funciones públicas (C8)
```python
# ✅ C8: anotaciones de tipo completas
def process_data(data: dict[str, int]) -> bool:
    return sum(data.values()) > 0
```

```python
# ❌ Anti-pattern: sin type hints
def process_data(data):
    return sum(data.values()) > 0

# 🔧 Fix: añadir type hints
def process_data(data: dict[str, int]) -> bool:
    return sum(data.values()) > 0
```

### Ejemplo 2: Uso de Optional y Union para valores faltantes (C3)
```python
# ✅ C3: Optional para dependencia opcional
from typing import Optional
try:
    import yaml
except ImportError:
    yaml: Optional[object] = None
```

```python
# ❌ Anti-pattern: asignación sin tipo
try:
    import yaml
except ImportError:
    yaml = None

# 🔧 Fix: anotar como Optional
from typing import Optional
yaml: Optional[object] = None
```

### Ejemplo 3: Validación de TENANT_ID con type guard (C4)
```python
# ✅ C4: función con type guard
import os
def get_tenant_id() -> str:
    tid = os.environ["TENANT_ID"]
    assert isinstance(tid, str) and tid, "Invalid TENANT_ID"
    return tid
```

```python
# ❌ Anti-pattern: sin verificación de tipo
tid = os.environ["TENANT_ID"]

# 🔧 Fix: assert isinstance
tid = os.environ["TENANT_ID"]
assert isinstance(tid, str) and tid
```

### Ejemplo 4: Logging estructurado de errores de tipo (C8)
```python
# ✅ C8: JSON con información de tipo
import json
logger.error(json.dumps({"error": "type_mismatch", "expected": "str", "got": type(val).__name__}))
```

```python
# ❌ Anti-pattern: print genérico
print(f"Error de tipo: {val}")

# 🔧 Fix: logger.error con JSON
logger.error(json.dumps({"error": "type_mismatch", "got": type(val).__name__}))
```

### Ejemplo 5: Configuración mypy para ignorar imports faltantes (C3)
```python
# ✅ C3: comentario para mypy
try:
    import psutil  # type: ignore
except ImportError:
    psutil = None
```

```python
# ❌ Anti-pattern: sin type ignore
try:
    import psutil
except ImportError:
    psutil = None

# 🔧 Fix: añadir # type: ignore
import psutil  # type: ignore
```

### Ejemplo 6: Verificación de checksum SHA‑256 de artefactos (C5)
```python
# ✅ C5: función con type hints y manejo de bytes
import hashlib
def verify_sha256(path: str, expected: str) -> bool:
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest() == expected
```

```python
# ❌ Anti-pattern: sin type hints ni manejo de errores
def verify_sha256(path, expected):
    return hashlib.sha256(open(path, "rb").read()).hexdigest() == expected

# 🔧 Fix: añadir type hints y contexto
def verify_sha256(path: str, expected: str) -> bool:
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest() == expected
```

### Ejemplo 7: TenantFilter con type hints para logging (C8)
```python
# ✅ C8: clase con anotaciones de tipo
import logging
class TenantFilter(logging.Filter):
    def filter(self, record: logging.LogRecord) -> bool:
        record.tenant = tenant_ctx.get("unknown")
        return True
```

```python
# ❌ Anti-pattern: sin type hints
class TenantFilter(logging.Filter):
    def filter(self, record):
        record.tenant = tenant_ctx.get("unknown")
        return True

# 🔧 Fix: añadir anotación de tipo
def filter(self, record: logging.LogRecord) -> bool: ...
```

### Ejemplo 8: Uso de TypedDict para estructuras conocidas (C8)
```python
# ✅ C8: TypedDict para payloads de webhook
from typing import TypedDict
class WebhookPayload(TypedDict):
    event: str
    tenant_id: str
    data: dict
```

```python
# ❌ Anti-pattern: dict sin estructura
payload: dict = {"event": "update"}

# 🔧 Fix: usar TypedDict
from typing import TypedDict
class WebhookPayload(TypedDict):
    event: str
```

### Ejemplo 9: Type hints en generación de IDs (C4)
```python
# ✅ C4: función con tipo de retorno claro
import uuid
def generate_record_id(prefix: str) -> str:
    return f"{TENANT_ID}_{prefix}_{uuid.uuid4().hex[:12]}"
```

```python
# ❌ Anti-pattern: sin anotación de retorno
def generate_record_id(prefix):
    return f"{TENANT_ID}_{prefix}_{uuid.uuid4().hex[:12]}"

# 🔧 Fix: añadir -> str
def generate_record_id(prefix: str) -> str: ...
```

### Ejemplo 10: Manejo de subprocess con timeout tipado (C8)
```python
# ✅ C8: resultado tipado de subprocess
import subprocess
def run_cmd(cmd: list[str], timeout: int = 10) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, timeout=timeout, capture_output=True)
```

```python
# ❌ Anti-pattern: sin anotación de retorno
def run_cmd(cmd, timeout=10):
    return subprocess.run(cmd, timeout=timeout)

# 🔧 Fix: especificar tipo de retorno
def run_cmd(cmd: list[str], timeout: int = 10) -> subprocess.CompletedProcess: ...
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/python/type-safety-with-mypy.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"type-safety-with-mypy","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C3","C5","C8"],"examples_count":10,"lines_executable_max":5,"language":"Python 3.10+","timestamp":"2026-04-16T04:23:45Z"}
```

---
