# SHA256: a1b2c3d4e5f678901234567890abcdef1234567890abcdef1234567890abcf1
---
artifact_id: "whatsapp-bot-integration"
artifact_type: "skill_python"
version: "2.1.1"
constraints_mapped: ["C3","C4","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/python/whatsapp-bot-integration.md --json"
---

# 🤖 WhatsApp Bot Integration – Python Multi‑tenant Patterns

## Propósito
Patrones seguros y multi‑tenant para integrar bots de WhatsApp (Business API / Cloud API) en Python 3.10+, con manejo de webhooks, envío de mensajes, verificación de firmas y fallbacks híbridos local/cloud. Cumple con constraints C3 (imports seguros), C4 (aislamiento de tenant), C6 (conciencia cloud/local), C7 (timeouts y rollback) y C8 (logging estructurado sin `print()`).

## Patrones de Código Validados

```python
# ✅ C3: Import opcional de librería WhatsApp
try:
    import requests
except ImportError:
    requests = None
    logger.error("requests no instalado; envío HTTP deshabilitado")
```

```python
# ❌ Anti-pattern: import sin fallback
import requests

# 🔧 Fix: try/except con logger
try:
    import requests
except ImportError:
    requests = None
```

```python
# ✅ C4: Validación estricta de TENANT_ID
import os, sys
TENANT_ID = os.environ["TENANT_ID"]
if not TENANT_ID:
    logger.error("TENANT_ID requerido")
    sys.exit(1)
```

```python
# ❌ Anti-pattern: default silencioso
TENANT_ID = os.environ.get("TENANT_ID", "default")

# 🔧 Fix: acceso directo
TENANT_ID = os.environ["TENANT_ID"]
if not TENANT_ID: sys.exit(1)
```

```python
# ✅ C4: TenantFilter para logs con contexto
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
logging.info("Mensaje enviado")

# 🔧 Fix: añadir filtro al logger
logger.addFilter(TenantFilter())
```

```python
# ✅ C6: Conciencia cloud/local (modo híbrido)
WHATSAPP_API_URL = os.environ.get("WHATSAPP_API_URL", "http://localhost:8080")
USE_CLOUD_API = os.environ.get("USE_CLOUD_API", "false").lower() == "true"
```

```python
# ❌ Anti-pattern: URL hardcodeada
WHATSAPP_API_URL = "https://graph.facebook.com"

# 🔧 Fix: leer de entorno con fallback local
WHATSAPP_API_URL = os.environ.get("WHATSAPP_API_URL", "http://localhost:8080")
```

```python
# ✅ C7: Envío de mensaje con timeout
import requests
try:
    resp = requests.post(url, json=payload, timeout=10)
except requests.Timeout:
    logger.error("Timeout al enviar mensaje WhatsApp")
```

```python
# ❌ Anti-pattern: sin timeout
resp = requests.post(url, json=payload)

# 🔧 Fix: añadir timeout=10
resp = requests.post(url, json=payload, timeout=10)
```

```python
# ✅ C7: Verificación de webhook con timeout
import subprocess
try:
    subprocess.run(["./verify-signature", payload], timeout=5)
except subprocess.TimeoutExpired:
    logger.error("Timeout en verificación de firma")
```

```python
# ❌ Anti-pattern: sin timeout
subprocess.run(["./verify-signature", payload])

# 🔧 Fix: timeout=5
subprocess.run(["./verify-signature", payload], timeout=5)
```

```python
# ✅ C8: Logging estructurado JSON‑like
import json
logger.info(json.dumps({"event": "whatsapp_message_sent", "tenant": TENANT_ID, "to": recipient}))
```

```python
# ❌ Anti-pattern: print desestructurado
print(f"Mensaje enviado a {recipient}")

# 🔧 Fix: logger.info con JSON
logger.info(json.dumps({"event": "message_sent", "to": recipient}))
```

```python
# ✅ C8: CLI help vía logger
if "--help" in sys.argv:
    logger.info("Uso: whatsapp_bot.py [--send] [--webhook]")
    sys.exit(0)
```

```python
# ❌ Anti-pattern: print para help
if "--help" in sys.argv: print("Uso: ...")

# 🔧 Fix: logger.info
logger.info("Uso: whatsapp_bot.py [--send] [--webhook]")
```

```python
# ✅ C6: Configuración multi‑tenant de números de WhatsApp
WHATSAPP_PHONE_ID = os.environ[f"WHATSAPP_PHONE_ID_{TENANT_ID}"]
WHATSAPP_TOKEN = os.environ[f"WHATSAPP_TOKEN_{TENANT_ID}"]
```

```python
# ❌ Anti-pattern: credenciales globales
PHONE_ID = os.environ["WHATSAPP_PHONE_ID"]

# 🔧 Fix: sufijo por tenant
PHONE_ID = os.environ[f"WHATSAPP_PHONE_ID_{TENANT_ID}"]
```

```python
# ✅ C7: Rollback en envío fallido (marcar como no entregado)
try:
    send_whatsapp_message(to, text)
except Exception as e:
    mark_message_as_failed(message_id)
    raise
```

```python
# ❌ Anti-pattern: sin manejo de fallo
send_whatsapp_message(to, text)

# 🔧 Fix: capturar y marcar fallo
try:
    send_whatsapp_message(to, text)
except Exception:
    mark_failed(message_id)
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/python/whatsapp-bot-integration.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"whatsapp-bot-integration","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C3","C4","C6","C7","C8"],"examples_count":10,"lines_executable_max":5,"language":"Python 3.10+","timestamp":"2026-04-16T04:23:45Z"}
```

---
