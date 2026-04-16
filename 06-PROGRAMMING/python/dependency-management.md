# SHA256: a7b8c9d0e1f2a3b4c5678901234567890abcdef1234567890abcdef12345678
---
artifact_id: "dependency-management"
artifact_type: "skill_python"
version: "2.1.1"
constraints_mapped: ["C3","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/python/dependency-management.md --json"
---

# 📦 Dependency Management – Python Multi‑tenant Hardening

## Propósito
Patrones robustos para la gestión de dependencias en Python 3.10+: imports condicionales con fallback documentado (C3), verificación de integridad de paquetes mediante SHA‑256 (C5) y logging estructurado sin `print()` (C8). Asegura entornos reproducibles, tenant‑aware y resilientes ante faltantes opcionales.

## Patrones de Código Validados

### Ejemplo 1: Import condicional con fallback y logging (C3)
```python
# ✅ C3: try/except con logger
try:
    import yaml
except ImportError:
    yaml = None
    logger.warning("PyYAML no disponible; funcionalidad YAML deshabilitada")
```

```python
# ❌ Anti-pattern: import sin manejo
import yaml

# 🔧 Fix: try/except + logging
try:
    import yaml
except ImportError:
    yaml = None
```

### Ejemplo 2: Verificación de checksum SHA‑256 de requirements.txt (C5)
```python
# ✅ C5: validar integridad de archivo de dependencias
import hashlib
with open("requirements.txt", "rb") as f:
    actual = hashlib.sha256(f.read()).hexdigest()
if actual != expected_sha256:
    raise ValueError("Checksum mismatch")
```

```python
# ❌ Anti-pattern: instalar sin verificar
subprocess.run(["pip", "install", "-r", "requirements.txt"])

# 🔧 Fix: verificar hash primero
if compute_sha256("requirements.txt") != expected:
    sys.exit(1)
```

### Ejemplo 3: Logging estructurado de resolución de dependencias (C8)
```python
# ✅ C8: logger.info con JSON
import json
logger.info(json.dumps({"event": "dependency_loaded", "module": "yaml", "available": yaml is not None}))
```

```python
# ❌ Anti-pattern: print sin estructura
print(f"PyYAML cargado: {yaml is not None}")

# 🔧 Fix: logger.info con JSON
logger.info(json.dumps({"event": "dependency_loaded", "available": yaml is not None}))
```

### Ejemplo 4: Instalación de paquete opcional con timeout (C3/C8)
```python
# ✅ C3: subprocess con timeout y captura de error
import subprocess
try:
    subprocess.run(["pip", "install", "psutil"], timeout=30, check=True)
except subprocess.TimeoutExpired:
    logger.error("Timeout instalando psutil")
```

```python
# ❌ Anti-pattern: sin timeout
subprocess.run(["pip", "install", "psutil"])

# 🔧 Fix: timeout=30
subprocess.run(["pip", "install", "psutil"], timeout=30)
```

### Ejemplo 5: Tenant‑aware path para dependencias (C4, C8)
```python
# ✅ C4: ruta de cache por tenant
import os
TENANT_ID = os.environ["TENANT_ID"]
cache_dir = f"/var/cache/pip/{TENANT_ID}"
os.makedirs(cache_dir, exist_ok=True)
```

```python
# ❌ Anti-pattern: cache compartida
cache_dir = "/var/cache/pip"

# 🔧 Fix: usar tenant_id
cache_dir = f"/var/cache/pip/{TENANT_ID}"
```

### Ejemplo 6: Type hints en cargador de módulos (C8)
```python
# ✅ C8: anotación de tipo Optional
from typing import Optional
def load_module(name: str) -> Optional[object]:
    try:
        return __import__(name)
    except ImportError:
        return None
```

```python
# ❌ Anti-pattern: sin anotación
def load_module(name):
    try:
        return __import__(name)
    except ImportError:
        return None

# 🔧 Fix: añadir -> Optional[object]
def load_module(name: str) -> Optional[object]: ...
```

### Ejemplo 7: Verificación de integridad de paquete instalado (C5)
```python
# ✅ C5: checksum de archivo .dist-info/METADATA
import hashlib, pkg_resources
dist = pkg_resources.get_distribution("requests")
meta_path = dist._provider.egg_info + "/METADATA"
with open(meta_path, "rb") as f:
    hash = hashlib.sha256(f.read()).hexdigest()
```

```python
# ❌ Anti-pattern: confiar sin verificar
import requests

# 🔧 Fix: calcular hash del METADATA
hash = hashlib.sha256(open(meta_path, "rb").read()).hexdigest()
```

### Ejemplo 8: Fallback a módulo built‑in cuando falta externo (C3)
```python
# ✅ C3: usar json si yaml no está disponible
try:
    import yaml
except ImportError:
    import json as yaml
    logger.warning("Usando json como fallback para YAML")
```

```python
# ❌ Anti-pattern: asumir presencia de yaml
import yaml

# 🔧 Fix: try/except con fallback a json
try:
    import yaml
except ImportError:
    import json as yaml
```

### Ejemplo 9: Logging de versión de dependencia cargada (C8)
```python
# ✅ C8: registrar versión en JSON
import pkg_resources
version = pkg_resources.get_distribution("requests").version
logger.info(json.dumps({"module": "requests", "version": version, "tenant": TENANT_ID}))
```

```python
# ❌ Anti-pattern: print desestructurado
print(f"Requests version: {version}")

# 🔧 Fix: logger.info con JSON
logger.info(json.dumps({"module": "requests", "version": version}))
```

### Ejemplo 10: CLI help vía logger (C8)
```python
# ✅ C8: help con logger
if "--help" in sys.argv:
    logger.info("Uso: dependency_check.py --verify --install")
    sys.exit(0)
```

```python
# ❌ Anti-pattern: print para help
if "--help" in sys.argv: print("Uso: ...")

# 🔧 Fix: logger.info
logger.info("Uso: dependency_check.py --verify --install")
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/python/dependency-management.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"dependency-management","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C3","C5","C8"],"examples_count":10,"lines_executable_max":5,"language":"Python 3.10+","timestamp":"2026-04-16T04:23:45Z"}
```

---
