---
artifact_id: "deep-agents-security-best-practices"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-security-best-practices.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-security-best-practices.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-security-v1.0.0"
generated_at: "2026-05-25T20:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-deployment-production", "deep-agents-permissions"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🔐 Deep Agents – Segurança e Boas Práticas

> **Contrato modular**: Artefato filho do Master Agent. Consolida todas as práticas de segurança para Deep Agents: proteção contra prompt injection, isolamento de backends, secret management, rate limiting e sandboxing.

---

## 🎯 Propósito
Garantir que agentes MANTIS operem com segurança em ambientes multi‑tenant, prevenindo vazamento de dados, injeção de comandos e abuso de ferramentas.

## 📋 Especificação (SDD)
- **Entradas**: Configuração de permissões, backends seguros, HITL.
- **Saídas**: Agente configurado com políticas de segurança.
- **Side Effects**: Bloqueio de operações não autorizadas.
- **Constraints Aplicáveis**: C1 (contratos seguros), C3 (proteção de secrets), C4 (isolamento multi‑tenant), C5 (validação de entrada), C7 (fail‑secure), C8 (auditoria).
- **Dependências**: `deepagents`, `langgraph`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    import json, datetime, os
    def mantis_log(level, event, detail=""):
        entry = {"ts": datetime.datetime.utcnow().isoformat() + "Z", "level": level, "tenant": os.getenv("TENANT_ID", "global"), "event": event, "detail": detail, "trace_id": os.getenv("TRACE_ID", "null"), "span_id": os.getenv("SPAN_ID", "null"), "fallback": "true"}
        print(json.dumps(entry), flush=True)
```

### 1. Proteção contra Prompt Injection via Memória Compartilhada

```python
# Memória de organização deve ser read‑only para evitar injeção maliciosa.
permissions = [
    FilesystemPermission(operations=["write"], paths=["/policies/**"], mode="deny"),
    FilesystemPermission(operations=["read", "write"], paths=["/memories/**"], mode="allow"),
]
```

### 2. Validação de Origem com Contexto de Usuário

```python
@dataclass
class Context:
    user_id: str
    user_role: str
    tenant_id: str

@tool
def sensitive_operation(data: str, runtime: ToolRuntime[Context]) -> str:
    if runtime.context.user_role != "admin":
        mantis_log("SECURITY", "unauthorized", f"User {runtime.context.user_id}")
        return "Erro: Acesso negado."
    return perform_operation(data)
```

### 3. Rate Limiting por Usuário

```python
import time
from collections import defaultdict

user_call_times = defaultdict(list)

def check_rate_limit(user_id: str, max_calls_per_minute: int = 10) -> bool:
    now = time.time()
    user_calls = user_call_times[user_id]
    user_calls = [t for t in user_calls if now - t < 60]
    user_call_times[user_id] = user_calls
    if len(user_calls) >= max_calls_per_minute:
        mantis_log("SECURITY", "rate_limited", f"User: {user_id}")
        return False
    user_call_times[user_id].append(now)
    return True
```

### 4. Isolamento de Backends com Composite

```python
# Nunca exponha diretórios sensíveis em FilesystemBackend
backend = CompositeBackend(
    default=StateBackend(),
    routes={
        "/workspace/": FilesystemBackend(root_dir="/safe/project", virtual_mode=True),
    },
)
# Dados internos do agente (/large_tool_results/, /conversation_history/) ficam no StateBackend
```

### 5. Sanitização de Saídas de Ferramentas

```python
import re

def sanitize_tool_output(output: str) -> str:
    """Remove possíveis dados sensíveis da saída."""
    output = re.sub(r'sk-[a-zA-Z0-9]{20,}', '[REDACTED]', output)  # API keys
    output = re.sub(r'\b\d{3}\.\d{3}\.\d{3}-\d{2}\b', '[CPF REDACTED]', output)  # CPF
    output = re.sub(r'[\w\.-]+@[\w\.-]+', '[EMAIL REDACTED]', output)  # Email
    return output

@wrap_tool_call
def sanitize_interceptor(request, handler):
    result = handler(request)
    if isinstance(result, str):
        return sanitize_tool_output(result)
    return result
```

### 6. HITL para Operações Críticas

```python
agent = create_deep_agent(
    model="anthropic:claude-sonnet-4-6",
    tools=[deploy_to_prod, delete_user, send_bulk_email],
    interrupt_on={
        "deploy_to_prod": True,
        "delete_user": {"allowed_decisions": ["approve", "reject"]},
        "send_bulk_email": {"allowed_decisions": ["approve", "reject", "edit"]},
    },
    checkpointer=MemorySaver(),
)
```

### 7. Logs de Auditoria

```python
def audit_log(action: str, user_id: str, detail: str):
    mantis_log("AUDIT", action, json.dumps({
        "user": user_id,
        "detail": detail,
        "timestamp": datetime.datetime.utcnow().isoformat(),
    }))
```

### 8. Configuração de Timeouts para Ferramentas

```python
@tool
async def api_call_with_timeout(url: str) -> str:
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.get(url)
            return response.text
    except httpx.TimeoutException:
        mantis_log("ERROR", "timeout", url)
        return "Erro: Timeout ao acessar API."
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_sanitize_output():
    output = "API key: sk-1234567890abcdef"
    sanitized = sanitize_tool_output(output)
    assert "sk-" not in sanitized

def test_rate_limit():
    assert check_rate_limit("user-1", 10) == True
    for _ in range(10):
        check_rate_limit("user-1", 10)
    assert check_rate_limit("user-1", 10) == False
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-security-best-practices.md --json
```

---

## 🔗 Referências Cruzadas (Wikilinks Mínimos)
- [[deep-agents-permissions.md]]
- [[deep-agents-deployment-production.md]]
- [[langchain-langraph-master-agent.md]]

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-25T20:00:00Z | langchain-langraph-master-agent | Criação inicial: segurança | C1,C3,C4,C5,C7,C8 |
