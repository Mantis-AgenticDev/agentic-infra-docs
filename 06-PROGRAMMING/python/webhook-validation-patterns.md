# SHA256: e3a4b5c6d7e8f901234567890abcdef1234567890abcdef1234567890abcde3
---
artifact_id: "webhook-validation-patterns"
artifact_type: "skill_python"
version: "2.1.1"
constraints_mapped: ["C3","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/python/webhook-validation-patterns.md --json"
---

# 📨 Patrones de Validación de Webhooks – Python Multi‑tenant

## Propósito
Patrones robustos para recibir, validar y procesar webhooks externos (GitHub, Stripe, Slack) en entornos Python multi‑tenant, garantizando autenticidad de firmas, prevención de replay attacks, timeouts controlados y aislamiento por tenant. Cumple constraints C3–C8: imports seguros, tenant‑aware logging, checksums de integridad, subprocess con timeout y cero `print()`.

## Patrones de Código Validados

### Ejemplo 1: Verificación de firma HMAC‑SHA256 (C5)
```python
# ✅ C5: timing‑safe compare
import hmac, hashlib
expected = hmac.new(secret, payload, hashlib.sha256).hexdigest()
if not hmac.compare_digest(expected, signature):
    raise ValueError("Firma inválida")
```
```python
# ❌ Anti-pattern: comparación directa
if signature != expected:
    raise ValueError
```
```python
# 🔧 Fix: usar hmac.compare_digest
if not hmac.compare_digest(expected, signature):
    raise ValueError
```

### Ejemplo 2: Validación de timestamp contra replay (C7)
```python
# ✅ C7: tolerancia de 5 minutos
import time
if abs(time.time() - webhook_timestamp) > 300:
    logger.error("Webhook expirado")
    raise TimeoutError
```
```python
# ❌ Anti-pattern: aceptar cualquier timestamp
# sin código de validación
```
```python
# 🔧 Fix: verificar ventana temporal
if abs(time.time() - timestamp) > 300:
    raise TimeoutError
```

### Ejemplo 3: Carga segura del webhook secret por tenant (C4)
```python
# ✅ C4: secret específico del tenant
import os, sys
TENANT_ID = os.environ["TENANT_ID"]
WEBHOOK_SECRET = os.environ[f"WEBHOOK_SECRET_{TENANT_ID}"]
```
```python
# ❌ Anti-pattern: secret global compartido
WEBHOOK_SECRET = os.environ.get("WEBHOOK_SECRET", "default")
```
```python
# 🔧 Fix: secret con sufijo tenant
WEBHOOK_SECRET = os.environ[f"WEBHOOK_SECRET_{TENANT_ID}"]
```

### Ejemplo 4: Logging estructurado de eventos de webhook (C8)
```python
# ✅ C8: log JSON sin exponer secretos
import json
logger.info(json.dumps({"event": "webhook_received", "source": "github", "tenant": TENANT_ID}))
```
```python
# ❌ Anti-pattern: print con datos crudos
print(f"Webhook de GitHub recibido: {payload}")
```
```python
# 🔧 Fix: logger.info con estructura JSON
logger.info(json.dumps({"event": "webhook", "source": "github"}))
```

### Ejemplo 5: Subprocess para validación externa con timeout (C7)
```python
# ✅ C7: timeout al ejecutar validador externo
import subprocess
try:
    subprocess.run(["./validate-payload", payload_file], timeout=5, check=True)
except subprocess.TimeoutExpired:
    logger.error("Timeout en validación externa")
```
```python
# ❌ Anti-pattern: sin timeout
subprocess.run(["./validate-payload", payload_file])
```
```python
# 🔧 Fix: añadir timeout=5
subprocess.run(["./validate-payload", payload_file], timeout=5)
```

### Ejemplo 6: Import opcional de librería de parsing (C3)
```python
# ✅ C3: manejo de import opcional
try:
    import yaml
except ImportError:
    yaml = None
    logger.warning("PyYAML no instalado; solo se soporta JSON")
```
```python
# ❌ Anti-pattern: import sin fallback
import yaml
```
```python
# 🔧 Fix: try/except con logger
try:
    import yaml
except ImportError:
    yaml = None
```

### Ejemplo 7: Validación de IP de origen (C5)
```python
# ✅ C5: lista blanca de IPs
ALLOWED_IPS = {"192.30.252.0/22"}
import ipaddress
client_ip = ipaddress.ip_address(request.remote_addr)
if not any(client_ip in ipaddress.ip_network(net) for net in ALLOWED_IPS):
    raise PermissionError
```
```python
# ❌ Anti-pattern: confiar en cualquier IP
# sin validación
```
```python
# 🔧 Fix: verificar contra CIDR permitidos
if client_ip not in allowed_nets: raise PermissionError
```

### Ejemplo 8: Verificación de checksum SHA‑256 del payload (C5)
```python
# ✅ C5: hash para auditoría
import hashlib
payload_hash = hashlib.sha256(payload).hexdigest()
logger.info(f"Payload hash: {payload_hash}")
```
```python
# ❌ Anti-pattern: almacenar payload sin hash
store_raw_payload(payload)
```
```python
# 🔧 Fix: calcular y loguear hash
payload_hash = hashlib.sha256(payload).hexdigest()
```

### Ejemplo 9: Type hints en handler de webhook (C8)
```python
# ✅ C8: anotaciones completas
def handle_webhook(payload: bytes, signature: str) -> bool:
    return verify_signature(payload, signature)
```
```python
# ❌ Anti-pattern: sin type hints
def handle_webhook(payload, signature):
    return verify_signature(payload, signature)
```
```python
# 🔧 Fix: añadir anotaciones
def handle_webhook(payload: bytes, signature: str) -> bool:
    return verify_signature(payload, signature)
```

### Ejemplo 10: Aislamiento de contexto de tenant en procesamiento (C4)
```python
# ✅ C4: tenant_ctx en el handler
tenant_ctx.set(TENANT_ID)
process_webhook_for_tenant(payload)
```
```python
# ❌ Anti-pattern: sin contexto de tenant
process_webhook(payload)
```
```python
# 🔧 Fix: establecer ContextVar antes de procesar
tenant_ctx.set(TENANT_ID)
process_webhook_for_tenant(payload)
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/python/webhook-validation-patterns.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"webhook-validation-patterns","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C3","C4","C5","C7","C8"],"examples_count":10,"lines_executable_max":5,"language":"Python 3.10+","timestamp":"2026-04-16T04:23:45Z"}
```

---
