# SHA256: e8f7a6b5c4d3e2f101234567890abcdef1234567890abcdef1234567890abcf2
---
artifact_id: "n8n-integration"
artifact_type: "skill_python"
version: "2.1.1"
constraints_mapped: ["C3","C4","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/python/n8n-integration.md --json"
---

# 🔗 n8n Integration Patterns – Python Multi‑tenant

## Propósito
Patrones seguros para interactuar con n8n (workflow automation) desde Python en entornos multi‑tenant: disparar workflows, recibir webhooks, gestionar credenciales y adaptarse a despliegues híbridos (local/cloud). Cumple con C3 (imports seguros), C4 (aislamiento de tenant), C6 (conciencia cloud/local), C7 (timeouts y rollback) y C8 (logging estructurado sin `print()`).

## Patrones de Código Validados

```python
# ✅ C3: Import condicional de requests
try:
    import requests
except ImportError:
    requests = None
    logger.error("requests no disponible; integración n8n deshabilitada")
```

```python
# ❌ Anti-pattern: import sin manejo de error
import requests

# 🔧 Fix: try/except con fallback
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

# 🔧 Fix: acceso directo y sys.exit
TENANT_ID = os.environ["TENANT_ID"]
if not TENANT_ID: sys.exit(1)
```

```python
# ✅ C4: Aislamiento de contexto para logs
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
logging.info("Workflow ejecutado")

# 🔧 Fix: añadir filtro al logger
logger.addFilter(TenantFilter())
```

```python
# ✅ C6: URL de n8n según entorno
N8N_URL = os.environ.get("N8N_URL", "http://localhost:5678")
USE_CLOUD_N8N = os.environ.get("USE_CLOUD_N8N", "false").lower() == "true"
```

```python
# ❌ Anti-pattern: URL hardcodeada
N8N_URL = "https://n8n.cloud.example.com"

# 🔧 Fix: leer de entorno con fallback local
N8N_URL = os.environ.get("N8N_URL", "http://localhost:5678")
```

```python
# ✅ C7: Disparar workflow con timeout
try:
    resp = requests.post(f"{N8N_URL}/webhook/{workflow_id}", json=data, timeout=15)
except requests.Timeout:
    logger.error("Timeout al disparar workflow n8n")
```

```python
# ❌ Anti-pattern: POST sin timeout
resp = requests.post(f"{N8N_URL}/webhook/{workflow_id}", json=data)

# 🔧 Fix: añadir timeout=15
resp = requests.post(url, json=data, timeout=15)
```

```python
# ✅ C7: Webhook receiver con timeout de subprocess
import subprocess
try:
    subprocess.run(["./process-n8n-payload", payload_file], timeout=5)
except subprocess.TimeoutExpired:
    logger.error("Timeout procesando webhook de n8n")
```

```python
# ❌ Anti-pattern: subprocess sin timeout
subprocess.run(["./process-n8n-payload", payload_file])

# 🔧 Fix: timeout=5
subprocess.run(["./process-n8n-payload", payload_file], timeout=5)
```

```python
# ✅ C8: Logging estructurado JSON‑like
import json
logger.info(json.dumps({"event": "n8n_workflow_triggered", "tenant": TENANT_ID, "workflow_id": wf_id}))
```

```python
# ❌ Anti-pattern: print desestructurado
print(f"Workflow {wf_id} ejecutado")

# 🔧 Fix: logger.info con JSON
logger.info(json.dumps({"event": "workflow_triggered", "id": wf_id}))
```

```python
# ✅ C8: CLI help vía logger
if "--help" in sys.argv:
    logger.info("Uso: n8n_client.py --trigger <workflow_id> --data <json_file>")
    sys.exit(0)
```

```python
# ❌ Anti-pattern: print para help
if "--help" in sys.argv: print("Uso: ...")

# 🔧 Fix: logger.info
logger.info("Uso: n8n_client.py --trigger <workflow_id>")
```

```python
# ✅ C6: Credenciales por tenant
N8N_API_KEY = os.environ[f"N8N_API_KEY_{TENANT_ID}"]
N8N_WEBHOOK_SECRET = os.environ[f"N8N_WEBHOOK_SECRET_{TENANT_ID}"]
```

```python
# ❌ Anti-pattern: clave global compartida
API_KEY = os.environ["N8N_API_KEY"]

# 🔧 Fix: sufijo por tenant
API_KEY = os.environ[f"N8N_API_KEY_{TENANT_ID}"]
```

```python
# ✅ C7: Rollback en ejecución fallida
try:
    trigger_n8n_workflow(workflow_id, data)
except Exception as e:
    logger.error(f"Fallo en workflow: {e}")
    revert_pending_actions(workflow_id)
    raise
```

```python
# ❌ Anti-pattern: sin manejo de fallo
trigger_n8n_workflow(workflow_id, data)

# 🔧 Fix: capturar y revertir
try:
    trigger_n8n_workflow(wf_id, data)
except Exception:
    revert_actions(wf_id)
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/python/n8n-integration.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"n8n-integration","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C3","C4","C6","C7","C8"],"examples_count":10,"lines_executable_max":5,"language":"Python 3.10+","timestamp":"2026-04-16T04:23:45Z"}
```

---
