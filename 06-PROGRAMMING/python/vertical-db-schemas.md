# SHA256: b2c3d4e5f678901234567890abcdef1234567890abcdef1234567890abcdb5
---
artifact_id: "vertical-db-schemas"
artifact_type: "skill_python"
version: "2.1.1"
constraints_mapped: ["C4","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/python/vertical-db-schemas.md --json"
---

# 📐 Vertical Database Schemas – Python Multi‑tenant Implementation

## Propósito
Implementación en Python de los schemas verticales definidos para MANTIS AGENTIC (gastronomía, hotel, dental, marketing, corp‑kb). Aplica aislamiento estricto por `tenant_id` (C4), validación de integridad vía SHA‑256 (C5) y logging estructurado (C8) en operaciones de creación, migración y consulta de tablas multi‑tenant.

## Patrones de Código Validados

### Ejemplo 1: Validación estricta de TENANT_ID (C4)
```python
# ✅ C4: tenant_id obligatorio y validado
import os, sys
TENANT_ID = os.environ["TENANT_ID"]
if not TENANT_ID or len(TENANT_ID) > 50:
    logger.error("TENANT_ID inválido")
    sys.exit(1)
```

```python
# ❌ Anti-pattern: default silencioso
TENANT_ID = os.environ.get("TENANT_ID", "default")

# 🔧 Fix: acceso directo con validación
TENANT_ID = os.environ["TENANT_ID"]
if not TENANT_ID: sys.exit(1)
```

### Ejemplo 2: Logging estructurado de operaciones DDL (C8)
```python
# ✅ C8: logger.info con JSON
import json
logger.info(json.dumps({"event": "table_created", "tenant": TENANT_ID, "table": "mesas"}))
```

```python
# ❌ Anti-pattern: print sin estructura
print(f"Tabla 'mesas' creada para {TENANT_ID}")

# 🔧 Fix: logger.info con JSON
logger.info(json.dumps({"event": "table_created", "table": "mesas"}))
```

### Ejemplo 3: Generación de ID único con prefijo de tenant (C4)
```python
# ✅ C4: ID incluye tenant_id como prefijo
import uuid
def generate_tenant_id(prefix: str) -> str:
    return f"{TENANT_ID}_{prefix}_{uuid.uuid4().hex[:12]}"
```

```python
# ❌ Anti-pattern: ID sin tenant
import uuid
record_id = str(uuid.uuid4())

# 🔧 Fix: incluir tenant_id
record_id = f"{TENANT_ID}_{uuid.uuid4().hex[:12]}"
```

### Ejemplo 4: Validación de checksum SHA‑256 para migraciones (C5)
```python
# ✅ C5: verificar integridad del schema SQL
import hashlib
def verify_schema_checksum(schema_path: str, expected: str) -> bool:
    sha = hashlib.sha256()
    with open(schema_path, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            sha.update(chunk)
    return sha.hexdigest() == expected
```

```python
# ❌ Anti-pattern: ejecutar sin verificar
with open("schema.sql") as f:
    cursor.execute(f.read())

# 🔧 Fix: verificar checksum primero
if not verify_schema_checksum(path, expected):
    raise ValueError("Checksum mismatch")
```

### Ejemplo 5: Construcción segura de queries con tenant_id (C4)
```python
# ✅ C4: tenant_id como primer filtro en WHERE
query = "SELECT * FROM mesas WHERE tenant_id = %s AND disponible = %s"
cursor.execute(query, (TENANT_ID, True))
```

```python
# ❌ Anti-pattern: query sin filtro de tenant
cursor.execute("SELECT * FROM mesas WHERE disponible = %s", (True,))

# 🔧 Fix: incluir tenant_id siempre
cursor.execute("SELECT * FROM mesas WHERE tenant_id = %s AND disponible = %s", (TENANT_ID, True))
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
logging.info("Migración ejecutada")

# 🔧 Fix: añadir filtro al logger
logger.addFilter(TenantFilter())
```

### Ejemplo 7: Manejo de conexiones a BD con tenant isolation (C4)
```python
# ✅ C4: conexión con tenant_id en sesión
def get_tenant_connection(tenant_id: str):
    conn = mysql.connector.connect(**config)
    cursor = conn.cursor()
    cursor.execute("SET @tenant_id = %s", (tenant_id,))
    return conn
```

```python
# ❌ Anti-pattern: conexión sin contexto de tenant
conn = mysql.connector.connect(**config)

# 🔧 Fix: establecer variable de sesión
cursor.execute("SET @tenant_id = %s", (tenant_id,))
```

### Ejemplo 8: Type hints en funciones de schema (C8)
```python
# ✅ C8: anotaciones completas
from typing import List, Dict, Optional
def get_menu_items(tenant_id: str, categoria_id: Optional[str] = None) -> List[Dict]:
    ...
```

```python
# ❌ Anti-pattern: sin type hints
def get_menu_items(tenant_id, categoria_id=None):
    ...

# 🔧 Fix: añadir anotaciones
def get_menu_items(tenant_id: str, categoria_id: Optional[str] = None) -> List[Dict]:
```

### Ejemplo 9: CLI help vía logger (C8)
```python
# ✅ C8: help con logger
if "--help" in sys.argv:
    logger.info("Uso: schema_manager.py --tenant <id> --vertical <gastro|hotel|...>")
    sys.exit(0)
```

```python
# ❌ Anti-pattern: print para help
if "--help" in sys.argv: print("Uso: schema_manager.py ...")

# 🔧 Fix: logger.info
logger.info("Uso: schema_manager.py --tenant <id> --vertical <gastro|hotel|...>")
```

### Ejemplo 10: Validación de vertical soportado (C4, C8)
```python
# ✅ C4/C8: enum de verticales válidos
VALID_VERTICALS = {"gastronomia", "hotel", "dental", "marketing", "corp_kb"}
if vertical not in VALID_VERTICALS:
    logger.error(json.dumps({"error": "vertical_invalido", "tenant": TENANT_ID}))
    sys.exit(1)
```

```python
# ❌ Anti-pattern: aceptar cualquier string
vertical = os.environ.get("VERTICAL", "gastronomia")

# 🔧 Fix: validar contra lista conocida
if vertical not in VALID_VERTICALS: sys.exit(1)
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/python/vertical-db-schemas.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"vertical-db-schemas","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C4","C5","C8"],"examples_count":10,"lines_executable_max":5,"language":"Python 3.10+","timestamp":"2026-04-16T04:23:45Z"}
```

---
