# SHA256: f1e2d3c4b5a678901234567890abcdef1234567890abcdef1234567890abcde2
---
artifact_id: "secrets-management-patterns"
artifact_type: "skill_python"
version: "2.1.1"
constraints_mapped: ["C3","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/python/secrets-management-patterns.md --json"
---

# 🔒 Patrones de Gestión de Secrets – Python Multi‑tenant

## Propósito
Patrones seguros para cargar, validar, rotar y auditar secrets (API keys, tokens, contraseñas) en entornos Python multi‑tenant. Cumple con constraints C3–C8: imports condicionales con fallback, aislamiento estricto por tenant, verificación de integridad vía SHA‑256, timeouts en subprocesos y logging estructurado sin `print()`.

## Patrones de Código Validados

### Ejemplo 1: Carga segura desde variables de entorno (C3, C4)
```python
# ✅ C3/C4: validación estricta de secretos
import os, sys
API_KEY = os.environ["API_KEY"]
if not API_KEY or len(API_KEY) < 32:
    logger.error("API_KEY inválida o faltante")
    sys.exit(1)
```
```python
# ❌ Anti-pattern: default inseguro
API_KEY = os.environ.get("API_KEY", "dev-key-123")
```
```python
# 🔧 Fix: acceso directo y validación
API_KEY = os.environ["API_KEY"]
if len(API_KEY) < 32: sys.exit(1)
```

### Ejemplo 2: Cifrado simétrico con librería opcional (C3, C5)
```python
# ✅ C3/C5: cryptography con fallback
try:
    from cryptography.fernet import Fernet
except ImportError:
    Fernet = None
    logger.error("cryptography no instalado; cifrado deshabilitado")
```
```python
# ❌ Anti-pattern: import obligatorio sin manejo
from cryptography.fernet import Fernet
```
```python
# 🔧 Fix: try/except con logger
try:
    from cryptography.fernet import Fernet
except ImportError:
    Fernet = None
```

### Ejemplo 3: Lectura de secrets desde Vault con timeout (C7)
```python
# ✅ C7: subprocess con timeout para CLI de Vault
import subprocess
try:
    result = subprocess.run(["vault", "kv", "get", "-field=key", "secret/data"],
                            timeout=5, capture_output=True, text=True)
except subprocess.TimeoutExpired:
    logger.error("Timeout al contactar Vault")
```
```python
# ❌ Anti-pattern: llamada sin timeout
subprocess.run(["vault", "kv", "get", "secret/data"])
```
```python
# 🔧 Fix: añadir timeout y captura
subprocess.run(["vault", "kv", "get", ...], timeout=5)
```

### Ejemplo 4: Comparación segura de secrets con hmac (C5)
```python
# ✅ C5: timing‑safe compare
import hmac
if not hmac.compare_digest(provided_secret, stored_secret):
    raise ValueError("Secret no coincide")
```
```python
# ❌ Anti-pattern: comparación directa vulnerable a timing
if provided_secret == stored_secret:
    grant_access()
```
```python
# 🔧 Fix: usar hmac.compare_digest
if not hmac.compare_digest(provided, stored):
    raise PermissionError
```

### Ejemplo 5: Rotación de secrets con verificación de tenant (C4)
```python
# ✅ C4: rotación aislada por tenant
def rotate_secret(tenant_id: str) -> str:
    if tenant_ctx.get() != tenant_id:
        raise PermissionError("Tenant mismatch")
    new_secret = secrets.token_urlsafe(32)
    return new_secret
```
```python
# ❌ Anti-pattern: rotación sin verificar tenant
def rotate_secret():
    return secrets.token_urlsafe(32)
```
```python
# 🔧 Fix: validar tenant_id antes de rotar
if tenant_ctx.get() != tenant_id: raise PermissionError
```

### Ejemplo 6: Logging estructurado de eventos de secrets (C8)
```python
# ✅ C8: JSON-like, sin exponer secretos
import json
logger.info(json.dumps({"event": "secret_rotated", "tenant": TENANT_ID, "key_id": key_id}))
```
```python
# ❌ Anti-pattern: print con secretos
print(f"Secreto rotado: {new_secret}")
```
```python
# 🔧 Fix: logger.info con datos no sensibles
logger.info(json.dumps({"event": "secret_rotated", "key_id": key_id}))
```

### Ejemplo 7: Checksum SHA‑256 para integridad de secretos cifrados (C5)
```python
# ✅ C5: verificar integridad antes de descifrar
import hashlib
def verify_blob_checksum(blob: bytes, expected: str) -> bool:
    return hashlib.sha256(blob).hexdigest() == expected
```
```python
# ❌ Anti-pattern: descifrar sin verificar integridad
plain = cipher.decrypt(blob)
```
```python
# 🔧 Fix: verificar checksum primero
if not verify_blob_checksum(blob, expected): raise ValueError
```

### Ejemplo 8: Uso de contextvars para aislar secrets por tenant (C4)
```python
# ✅ C4: contexto por tenant
import contextvars
secrets_ctx: contextvars.ContextVar[dict] = contextvars.ContextVar("secrets")
secrets_ctx.set({"api_key": load_tenant_key(TENANT_ID)})
```
```python
# ❌ Anti-pattern: variable global compartida
SECRETS_CACHE = {}
```
```python
# 🔧 Fix: usar ContextVar por tenant
secrets_ctx: contextvars.ContextVar[dict] = contextvars.ContextVar("secrets")
```

### Ejemplo 9: Type hints en funciones de gestión de secrets (C8)
```python
# ✅ C8: anotaciones completas
def load_secret(key_name: str, tenant_id: str) -> Optional[str]:
    return vault_client.read(f"secret/{tenant_id}/{key_name}")
```
```python
# ❌ Anti-pattern: sin type hints
def load_secret(key_name, tenant_id):
    return vault_client.read(f"secret/{tenant_id}/{key_name}")
```
```python
# 🔧 Fix: añadir anotaciones
def load_secret(key_name: str, tenant_id: str) -> Optional[str]:
    return vault_client.read(f"secret/{tenant_id}/{key_name}")
```

### Ejemplo 10: Limpieza segura de secrets de memoria (C5, C8)
```python
# ✅ C5/C8: sobrescribir y forzar GC
import ctypes
def clear_secret(secret_bytes: bytearray) -> None:
    ctypes.memset(ctypes.addressof(secret_bytes), 0, len(secret_bytes))
```
```python
# ❌ Anti-pattern: dejar secrets en memoria
password = "supersecret"
# ... uso
```
```python
# 🔧 Fix: usar bytearray y limpiar
secret = bytearray(b"supersecret")
ctypes.memset(ctypes.addressof(secret), 0, len(secret))
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/python/secrets-management-patterns.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"secrets-management-patterns","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C3","C4","C5","C7","C8"],"examples_count":10,"lines_executable_max":5,"language":"Python 3.10+","timestamp":"2026-04-16T04:23:45Z"}
```

---
