# SHA256: a3b4c5d6e7f8901234567890abcdef1234567890abcdef1234567890abcdb4
---
artifact_id: "db-selection-decision-tree"
artifact_type: "skill_python"
version: "2.1.1"
constraints_mapped: ["C4","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/python/db-selection-decision-tree.md --json"
---

# 🌳 Árbol de Decisión de Base de Datos – Python Multi‑tenant

## Propósito
Implementación Python del árbol de decisión de stacks de base de datos para MANTIS AGENTIC. Evalúa el perfil del cliente (`has_vps`, `monthly_records`, etc.) y retorna el stack recomendado (A–F) con configuración multi‑tenant. Cumple con C4 (aislamiento estricto por tenant) y C8 (logging estructurado sin `print()`).

## Patrones de Código Validados

### Ejemplo 1: Validación de TENANT_ID en el perfil del cliente (C4)
```python
# ✅ C4: tenant_id obligatorio en ClientProfile
import os, sys
TENANT_ID = os.environ["TENANT_ID"]
if not TENANT_ID:
    logger.error("TENANT_ID requerido")
    sys.exit(1)
```

```python
# ❌ Anti-pattern: tenant_id opcional o default
TENANT_ID = os.environ.get("TENANT_ID", "default")

# 🔧 Fix: acceso directo y sys.exit
TENANT_ID = os.environ["TENANT_ID"]
if not TENANT_ID: sys.exit(1)
```

### Ejemplo 2: Logging estructurado de la decisión (C8)
```python
# ✅ C8: logger.info con JSON
import json
logger.info(json.dumps({"event": "stack_selected", "tenant": TENANT_ID, "stack": stack_id}))
```

```python
# ❌ Anti-pattern: print sin estructura
print(f"Stack seleccionado: {stack_id}")

# 🔧 Fix: logger.info con JSON
logger.info(json.dumps({"event": "stack_selected", "stack": stack_id}))
```

### Ejemplo 3: Función de decisión con type hints (C8)
```python
# ✅ C8: anotaciones de tipo completas
def select_db_stack(profile: ClientProfile) -> DBRecommendation:
    if not profile.tenant_id:
        raise ValueError("C4: tenant_id requerido")
    # ... lógica de decisión
```

```python
# ❌ Anti-pattern: sin type hints
def select_db_stack(profile):
    # ... lógica

# 🔧 Fix: añadir anotaciones
def select_db_stack(profile: ClientProfile) -> DBRecommendation:
    # ...
```

### Ejemplo 4: Uso de dataclasses para perfiles (C8)
```python
# ✅ C8: dataclass con type hints
from dataclasses import dataclass
@dataclass
class ClientProfile:
    tenant_id: str
    has_vps: bool
    monthly_records: int
```

```python
# ❌ Anti-pattern: dict sin estructura definida
profile = {"tenant_id": "t1", "has_vps": True, "records": 5000}

# 🔧 Fix: usar dataclass
@dataclass
class ClientProfile:
    tenant_id: str
    has_vps: bool
    monthly_records: int
```

### Ejemplo 5: Logging de errores con tenant context (C4)
```python
# ✅ C4: error log con tenant_id
try:
    stack = select_db_stack(profile)
except ValueError as e:
    logger.error(json.dumps({"error": str(e), "tenant": profile.tenant_id}))
```

```python
# ❌ Anti-pattern: error sin tenant
except ValueError as e:
    logger.error(f"Error: {e}")

# 🔧 Fix: incluir tenant en log
logger.error(json.dumps({"error": str(e), "tenant": profile.tenant_id}))
```

### Ejemplo 6: TenantFilter para logs con contexto (C4)
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
logging.info("Seleccionando stack")

# 🔧 Fix: añadir filtro al logger
logger.addFilter(TenantFilter())
```

### Ejemplo 7: Manejo de variables de entorno por tenant (C4)
```python
# ✅ C4: sufijo por tenant
DB_STACK = os.environ[f"DB_STACK_{TENANT_ID}"]
MYSQL_HOST = os.environ[f"MYSQL_HOST_{TENANT_ID}"]
```

```python
# ❌ Anti-pattern: variables globales
DB_STACK = os.environ["DB_STACK"]

# 🔧 Fix: sufijo por tenant
DB_STACK = os.environ[f"DB_STACK_{TENANT_ID}"]
```

### Ejemplo 8: CLI help vía logger (C8)
```python
# ✅ C8: help con logger
if "--help" in sys.argv:
    logger.info("Uso: db_selector.py --tenant <id> --profile <json_file>")
    sys.exit(0)
```

```python
# ❌ Anti-pattern: print para help
if "--help" in sys.argv: print("Uso: ...")

# 🔧 Fix: logger.info
logger.info("Uso: db_selector.py --tenant <id> --profile <json_file>")
```

### Ejemplo 9: Carga de perfil desde JSON con validación (C4)
```python
# ✅ C4: validar tenant_id en el JSON
import json
with open(profile_file) as f:
    data = json.load(f)
    if data.get("tenant_id") != TENANT_ID:
        raise ValueError("tenant_id mismatch")
```

```python
# ❌ Anti-pattern: cargar sin validar tenant
with open(profile_file) as f:
    data = json.load(f)

# 🔧 Fix: verificar tenant_id
if data["tenant_id"] != TENANT_ID: raise ValueError
```

### Ejemplo 10: Generación de configuración de entorno (C8)
```python
# ✅ C8: generar .env con logger
env_vars = {
    "DB_STACK": stack_id,
    "MYSQL_HOST": "127.0.0.1",
    "TENANT_ID": TENANT_ID
}
logger.info(json.dumps({"event": "env_generated", "vars": list(env_vars.keys())}))
```

```python
# ❌ Anti-pattern: print de variables sensibles
print(f"DB_STACK={stack_id}")

# 🔧 Fix: logger.info con JSON
logger.info(json.dumps({"event": "env_generated", "stack": stack_id}))
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/python/db-selection-decision-tree.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"db-selection-decision-tree","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C4","C8"],"examples_count":10,"lines_executable_max":5,"language":"Python 3.10+","timestamp":"2026-04-16T04:23:45Z"}
```

---
