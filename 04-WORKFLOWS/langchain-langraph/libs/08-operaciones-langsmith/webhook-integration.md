---
artifact_id: "webhook-integration"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/webhook-integration.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/webhook-integration.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:webhook-integration-v1"
generated_at: "2026-05-26T10:30:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["langgraph-create-agent", "scaling-performance-tuning"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-07-25"
---

# 🧩 Webhook Integration no Agent Server

> **Contrato modular**: Artefato filho do Master Agent. Implementa o padrão de webhooks para notificações assíncronas de conclusão de runs, com segurança, payload e configuração via `langgraph.json`.

## 🎯 Propósito

Permitir que sistemas externos recebam notificações automáticas quando uma execução no Agent Server terminar, utilizando endpoints webhook configuráveis e seguros.

## 📋 Especificação (SDD)
- **Entradas**: `webhook` URL, headers estáticos, restrições de domínio, payload customizado
- **Saídas**: POST com payload do Run ao finalizar, com status e valores
- **Side Effects**: Chamada de endpoint externo, falha se não alcançável
- **Constraints Aplicáveis**: C1 (Resiliência), C3 (Segurança), C5 (Integridade), C8 (Observabilidade)
- **Dependências**: `langgraph-sdk`, `httpx`, `starlette` (para servidor de teste)

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from langchain_langraph_master_agent import mantis_log
except ImportError:
    import json, datetime, os
    def mantis_log(level, event, detail=""):
        entry = {
            "ts": datetime.datetime.utcnow().isoformat() + "Z",
            "level": level,
            "tenant": os.getenv("TENANT_ID", "global"),
            "event": event,
            "detail": detail,
            "trace_id": os.getenv("TRACE_ID", "null"),
            "span_id": os.getenv("SPAN_ID", "null"),
            "fallback": "true"
        }
        print(json.dumps(entry), flush=True)
    mantis_log("WARN", "bootstrap_fallback", "Master Agent langchain-langraph não encontrado.")

# ─── LÓGICA DO MÓDULO ────────────────────────────────────────────────────
import asyncio, re
from typing import Optional, Dict, Any
import httpx
from langgraph_sdk import get_client

# ═══════════════════════════════════════════════════════════════════════════
# 1. CLIENTE DE EXECUÇÃO COM SUPORTE A WEBHOOK
# ═══════════════════════════════════════════════════════════════════════════
class WebhookAwareClient:
    def __init__(self, deployment_url: str, api_key: str, webhook_url: str = None):
        self.client = get_client(url=deployment_url, api_key=api_key)
        self.webhook_url = webhook_url

    async def stream_with_webhook(
        self,
        thread_id: str,
        assistant_id: str,
        input: dict,
        webhook_url: Optional[str] = None,
        webhook_headers: Optional[Dict[str, str]] = None
    ):
        effective_url = webhook_url or self.webhook_url
        if not effective_url:
            raise ValueError("Webhook URL é obrigatória para notificações")

        mantis_log("INFO", "webhook_stream_start", f"Thread={thread_id}, URL={effective_url}")
        async for chunk in self.client.runs.stream(
            thread_id=thread_id,
            assistant_id=assistant_id,
            input=input,
            stream_mode="events",
            webhook=effective_url
        ):
            yield chunk
        mantis_log("INFO", "webhook_stream_end", f"Thread={thread_id}")

# ═══════════════════════════════════════════════════════════════════════════
# 2. PROCESSADOR DE PAYLOAD DE WEBHOOK (LADO RECEPTOR)
# ═══════════════════════════════════════════════════════════════════════════
class WebhookPayload:
    """Modelo do payload recebido."""
    def __init__(self, data: dict):
        self.run_id = data["run_id"]
        self.thread_id = data["thread_id"]
        self.status = data["status"]
        self.values = data.get("values")
        self.error = data.get("error")
        self.webhook_sent_at = data.get("webhook_sent_at")

    def is_success(self) -> bool:
        return self.status == "success"

    def get_error_message(self) -> Optional[str]:
        if self.error:
            return self.error.get("message")
        return None

# ═══════════════════════════════════════════════════════════════════════════
# 3. SERVIDOR DE TESTE DE WEBHOOK (PARA DESENVOLVIMENTO LOCAL)
# ═══════════════════════════════════════════════════════════════════════════
from starlette.applications import Starlette
from starlette.routing import Route
from starlette.responses import JSONResponse
import uvicorn

class WebhookTestServer:
    def __init__(self, port: int = 9999):
        self.port = port
        self.received_payloads = []
        self.app = Starlette(routes=[Route("/webhook", self.handle_webhook, methods=["POST"])])

    async def handle_webhook(self, request):
        payload = await request.json()
        mantis_log("INFO", "webhook_received", f"Run ID={payload.get('run_id')}")
        self.received_payloads.append(WebhookPayload(payload))
        return JSONResponse({"status": "received"})

    def start(self):
        uvicorn.run(self.app, port=self.port, log_level="info")

# ═══════════════════════════════════════════════════════════════════════════
# 4. VALIDADOR DE URL DE WEBHOOK (SEGURANÇA C3)
# ═══════════════════════════════════════════════════════════════════════════
class WebhookURLValidator:
    """
    Implementa as regras de restrição de webhooks do Agent Server:
    - allowed_domains com suporte a wildcards
    - require_https
    - disable_loopback
    - max_url_length
    """
    def __init__(
        self,
        allowed_domains: list = None,
        require_https: bool = True,
        disable_loopback: bool = True,
        max_url_length: int = 2048,
        allowed_ports: set = None
    ):
        self.allowed_domains = allowed_domains or []
        self.require_https = require_https
        self.disable_loopback = disable_loopback
        self.max_url_length = max_url_length
        self.allowed_ports = allowed_ports or {443, 80}

    def validate(self, url: str) -> bool:
        if len(url) > self.max_url_length:
            mantis_log("ERROR", "webhook_url_too_long", f"URL length {len(url)} > {self.max_url_length}")
            return False

        # Parse URL
        from urllib.parse import urlparse
        parsed = urlparse(url)
        if self.require_https and parsed.scheme != "https":
            mantis_log("ERROR", "webhook_https_required", f"Scheme {parsed.scheme} not allowed")
            return False

        if self.disable_loopback:
            hostname = parsed.hostname or ""
            if hostname in ("localhost", "127.0.0.1", "::1"):
                mantis_log("ERROR", "webhook_loopback_blocked", hostname)
                return False

        port = parsed.port or (443 if parsed.scheme == "https" else 80)
        if port not in self.allowed_ports:
            mantis_log("ERROR", "webhook_port_blocked", str(port))
            return False

        # Verificar domínios permitidos (com wildcard)
        if self.allowed_domains:
            hostname = parsed.hostname
            allowed = False
            for pattern in self.allowed_domains:
                regex = re.escape(pattern).replace(r"\*", ".*")
                if re.match(regex, hostname):
                    allowed = True
                    break
            if not allowed:
                mantis_log("ERROR", "webhook_domain_not_allowed", hostname)
                return False

        return True

# ═══════════════════════════════════════════════════════════════════════════
# 5. INTEGRAÇÃO COM LANGGRAPH.JSON (EXEMPLO DE HEADERS ESTÁTICOS)
# ═══════════════════════════════════════════════════════════════════════════
WEBHOOK_CONFIG_EXAMPLE = """
{
  "webhooks": {
    "headers": {
      "X-Custom-Header": "my-value",
      "Authorization": "Bearer ${{ env.LG_WEBHOOK_TOKEN }}"
    },
    "url": {
      "allowed_domains": ["*.mycompany.com"],
      "require_https": true
    }
  }
}
"""
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from webhook_integration import WebhookPayload, WebhookURLValidator

def test_webhook_payload_success():
    payload = WebhookPayload({"run_id": "r1", "thread_id": "t1", "status": "success", "webhook_sent_at": "2026-05-26T10:00:00Z"})
    assert payload.is_success()
    assert payload.get_error_message() is None

def test_webhook_payload_error():
    payload = WebhookPayload({"run_id": "r2", "thread_id": "t2", "status": "error", "error": {"error": "TimeoutError", "message": "Run timed out"}})
    assert not payload.is_success()
    assert payload.get_error_message() == "Run timed out"

def test_url_validator_https():
    v = WebhookURLValidator(allowed_domains=["*.example.com"], require_https=True)
    assert v.validate("https://api.example.com/webhook")
    assert not v.validate("http://api.example.com/webhook")

def test_url_validator_loopback():
    v = WebhookURLValidator(disable_loopback=True)
    assert not v.validate("http://localhost:8000/webhook")
    assert not v.validate("https://127.0.0.1/webhook")

def test_url_validator_domain_wildcard():
    v = WebhookURLValidator(allowed_domains=["*.mycompany.com"])
    assert v.validate("https://sub.mycompany.com/path")
    assert not v.validate("https://other.com/path")
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/webhook-integration.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[langgraph-create-agent.md]]
