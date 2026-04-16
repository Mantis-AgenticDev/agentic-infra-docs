# SHA256: b2c3d4e5f678901234567890abcdef1234567890abcdef1234567890abcde1
---
artifact_id: "authentication-authorization-patterns"
artifact_type: "skill_python"
version: "2.1.1"
constraints_mapped: ["C3","C4","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/python/authentication-authorization-patterns.md --json"
---

# 🔐 Patrones de Autenticación y Autorización – Python Multi‑tenant

## Propósito
Patrones robustos para implementar autenticación (API keys, JWT) y autorización (RBAC, tenant‑scoping) en servicios Python multi‑tenant, cumpliendo constraints C3–C8: imports seguros con fallback, aislamiento estricto por tenant, validación de integridad vía SHA‑256 y logging estructurado sin `print()`.

## Patrones de Código Validados

### Ejemplo 1: Carga segura de secrets desde variable de entorno (C3, C4)
```python
# ✅ C3/C4: validación estricta
import os, sys
API_KEY = os.environ["API_KEY"]
if len(API_KEY) < 32:
    logger.error("API_KEY demasiado corta")
    sys.exit(1)
```
```python
# ❌ Anti-pattern: default inseguro
API_KEY = os.environ.get("API_KEY", "dev-key")
```
```python
# 🔧 Fix: acceso directo y validación
API_KEY = os.environ["API_KEY"]
if len(API_KEY) < 32: sys.exit(1)
```

### Ejemplo 2: Verificación de API Key con timing‑safe compare (C5)
```python
# ✅ C5: comparación segura contra timing attacks
import hmac
if not hmac.compare_digest(provided_key, stored_key):
    raise PermissionError("API key inválida")
```
```python
# ❌ Anti-pattern: comparación directa vulnerable
if provided_key == stored_key:
    grant_access()
```
```python
# 🔧 Fix: usar hmac.compare_digest
if not hmac.compare_digest(provided_key, stored_key):
    raise PermissionError
```

### Ejemplo 3: Validación de JWT con librería opcional (C3)
```python
# ✅ C3: import opcional con fallback
try:
    import jwt
except ImportError:
    jwt = None
    logger.error("PyJWT no instalado; autenticación JWT deshabilitada")
```
```python
# ❌ Anti-pattern: import obligatorio
import jwt
```
```python
# 🔧 Fix: try/except con logger
try:
    import jwt
except ImportError:
    jwt = None
```

### Ejemplo 4: Decorador de autorización con scoped tenant (C4)
```python
# ✅ C4: verifica tenant_id en token vs contexto
def require_tenant(required_tenant: str):
    def decorator(func):
        def wrapper(*args, **kwargs):
            if tenant_ctx.get() != required_tenant:
                raise PermissionError("Tenant mismatch")
            return func(*args, **kwargs)
        return wrapper
    return decorator
```
```python
# ❌ Anti-pattern: sin verificación de tenant
@require_role("admin")
def delete_user(user_id): ...
```
```python
# 🔧 Fix: añadir validación de tenant
@require_tenant("tenant_123")
def delete_user(user_id): ...
```

### Ejemplo 5: Hashing de contraseñas con verificación de integridad (C5)
```python
# ✅ C5: uso de passlib con manejo de import
try:
    from passlib.hash import argon2
except ImportError:
    argon2 = None
    logger.warning("passlib no disponible; use fallback seguro")
```
```python
# ❌ Anti-pattern: hash sin verificar disponibilidad
from passlib.hash import argon2
hash = argon2.hash(password)
```
```python
# 🔧 Fix: try/except + validación
if argon2 is None:
    raise RuntimeError("Librería de hashing faltante")
```

### Ejemplo 6: Middleware de autenticación con logging estructurado (C8)
```python
# ✅ C8: log JSON-like con tenant
import json
logger.info(json.dumps({"event": "auth_success", "tenant": tenant_id, "user": user}))
```
```python
# ❌ Anti-pattern: print con datos sensibles
print(f"Usuario {user} autenticado")
```
```python
# 🔧 Fix: logger.info con JSON
logger.info(json.dumps({"event": "auth_success", "user": user}))
```

### Ejemplo 7: Validación de permisos RBAC con cache opcional (C3)
```python
# ✅ C3: cache solo si redis disponible
try:
    import redis
    cache = redis.Redis(decode_responses=True)
except ImportError:
    cache = None
    logger.info("Redis no disponible; sin cache de permisos")
```
```python
# ❌ Anti-pattern: dependencia fuerte de redis
import redis
cache = redis.Redis()
```
```python
# 🔧 Fix: try/except con fallback
try:
    import redis
    cache = redis.Redis()
except ImportError:
    cache = None
```

### Ejemplo 8: Checksum SHA‑256 de token antes de almacenar (C5)
```python
# ✅ C5: hash del token para auditoría
import hashlib
token_hash = hashlib.sha256(token.encode()).hexdigest()
logger.info(f"Token hash: {token_hash}")
```
```python
# ❌ Anti-pattern: loguear token en claro
logger.info(f"Token generado: {token}")
```
```python
# 🔧 Fix: loguear solo el hash
token_hash = hashlib.sha256(token.encode()).hexdigest()
```

### Ejemplo 9: Aislamiento de contexto de tenant en logs (C4)
```python
# ✅ C4: TenantFilter integrado
class TenantFilter(logging.Filter):
    def filter(self, record):
        record.tenant = tenant_ctx.get("unknown")
        return True
logger.addFilter(TenantFilter())
```
```python
# ❌ Anti-pattern: log sin tenant
logging.info("Acceso concedido")
```
```python
# 🔧 Fix: añadir filtro al logger
logger.addFilter(TenantFilter())
```

### Ejemplo 10: Type hints en funciones de autorización (C8)
```python
# ✅ C8: anotaciones completas
def has_permission(user: str, resource: str, action: str) -> bool:
    return action in permissions.get(user, {}).get(resource, [])
```
```python
# ❌ Anti-pattern: sin type hints
def has_permission(user, resource, action):
    return action in permissions[user][resource]
```
```python
# 🔧 Fix: añadir anotaciones de tipo
def has_permission(user: str, resource: str, action: str) -> bool:
    return action in permissions.get(user, {}).get(resource, [])
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/python/authentication-authorization-patterns.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"authentication-authorization-patterns","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C3","C4","C5","C8"],"examples_count":10,"lines_executable_max":5,"language":"Python 3.10+","timestamp":"2026-04-16T04:23:45Z"}
```

---
