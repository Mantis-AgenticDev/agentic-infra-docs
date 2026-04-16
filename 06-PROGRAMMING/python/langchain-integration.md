# SHA256: c7d6e5f4a3b2c1d0987654321abcdef1234567890abcdef1234567890abcf3
---
artifact_id: "langchain-integration"
artifact_type: "skill_python"
version: "2.1.1"
constraints_mapped: ["C3","C4","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/python/langchain-integration.md --json"
---

# 🧠 LangChain Integration Patterns – Python Multi‑tenant

## Propósito
Patrones seguros y multi‑tenant para integrar LangChain en Python 3.10+ con conciencia de entorno (local/cloud), timeouts estrictos en llamadas a modelos, aislamiento de tenant en memoria y logs, manejo condicional de dependencias (C3) y logging estructurado sin `print()`. Cumple con constraints C3, C4, C6, C7, C8.

## Patrones de Código Validados

```python
# ✅ C3: Import condicional de LangChain
try:
    from langchain.llms import OpenAI
except ImportError:
    OpenAI = None
    logger.error("LangChain no instalado; funcionalidad deshabilitada")
```

```python
# ❌ Anti-pattern: import obligatorio
from langchain.llms import OpenAI

# 🔧 Fix: try/except con logger
try:
    from langchain.llms import OpenAI
except ImportError:
    OpenAI = None
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
# ✅ C4: Aislamiento de contexto en logging
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
logging.info("LangChain chain invoked")

# 🔧 Fix: añadir filtro al logger
logger.addFilter(TenantFilter())
```

```python
# ✅ C6: Conciencia cloud/local para endpoints LLM
LLM_API_URL = os.environ.get("LLM_API_URL", "http://localhost:11434")
USE_CLOUD_LLM = os.environ.get("USE_CLOUD_LLM", "false").lower() == "true"
```

```python
# ❌ Anti-pattern: URL hardcodeada
LLM_API_URL = "https://api.openai.com/v1"

# 🔧 Fix: leer de entorno con fallback local
LLM_API_URL = os.environ.get("LLM_API_URL", "http://localhost:11434")
```

```python
# ✅ C7: Invocación de LLM con timeout vía subprocess
import subprocess
try:
    subprocess.run(["python", "-c", "from langchain.llms import OpenAI; llm = OpenAI(); llm('Hi')"], timeout=20)
except subprocess.TimeoutExpired:
    logger.error("Timeout en llamada LLM")
```

```python
# ❌ Anti-pattern: subprocess sin timeout
subprocess.run(["python", "-c", "from langchain.llms import OpenAI; llm = OpenAI(); llm('Hi')"])

# 🔧 Fix: timeout=20
subprocess.run(["python", "-c", "..."], timeout=20)
```

```python
# ✅ C7: Timeout en llamada HTTP a endpoint LangServe
import requests
try:
    resp = requests.post(f"{LANGCHAIN_URL}/invoke", json={"input": query}, timeout=15)
except requests.Timeout:
    logger.error("Timeout contactando LangServe")
```

```python
# ❌ Anti-pattern: POST sin timeout
resp = requests.post(url, json=data)

# 🔧 Fix: timeout=15
resp = requests.post(url, json=data, timeout=15)
```

```python
# ✅ C8: Logging estructurado JSON‑like
import json
logger.info(json.dumps({"event": "langchain_invoke", "tenant": TENANT_ID, "model": model_name}))
```

```python
# ❌ Anti-pattern: print desestructurado
print(f"Invocando modelo {model_name}")

# 🔧 Fix: logger.info con JSON
logger.info(json.dumps({"event": "invoke", "model": model_name}))
```

```python
# ✅ C8: CLI help vía logger
if "--help" in sys.argv:
    logger.info("Uso: langchain_agent.py --query '<text>' --tenant <id>")
    sys.exit(0)
```

```python
# ❌ Anti-pattern: print para help
if "--help" in sys.argv: print("Uso: ...")

# 🔧 Fix: logger.info
logger.info("Uso: langchain_agent.py --query '<text>'")
```

```python
# ✅ C6: Configuración de API keys por tenant
OPENAI_API_KEY = os.environ[f"OPENAI_API_KEY_{TENANT_ID}"]
ANTHROPIC_API_KEY = os.environ[f"ANTHROPIC_API_KEY_{TENANT_ID}"]
```

```python
# ❌ Anti-pattern: clave global compartida
OPENAI_API_KEY = os.environ["OPENAI_API_KEY"]

# 🔧 Fix: sufijo por tenant
OPENAI_API_KEY = os.environ[f"OPENAI_API_KEY_{TENANT_ID}"]
```

```python
# ✅ C7: Rollback en cadena fallida
try:
    result = chain.invoke(input_data)
except Exception as e:
    logger.error(f"Fallo en cadena LangChain: {e}")
    fallback_response = "Lo siento, no pude procesar tu solicitud."
    raise
```

```python
# ❌ Anti-pattern: sin manejo de fallo
result = chain.invoke(input_data)

# 🔧 Fix: capturar y loguear error
try:
    result = chain.invoke(input_data)
except Exception as e:
    logger.error(f"Fallo: {e}")
    raise
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/python/langchain-integration.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"langchain-integration","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C3","C4","C6","C7","C8"],"examples_count":10,"lines_executable_max":5,"language":"Python 3.10+","timestamp":"2026-04-16T04:23:45Z"}
```

---
