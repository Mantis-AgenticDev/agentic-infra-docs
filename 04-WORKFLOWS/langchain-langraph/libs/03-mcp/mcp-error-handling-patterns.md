---
artifact_id: "mcp-error-handling-patterns"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/mcp-error-handling-patterns.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/mcp-error-handling-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:mcp-error-handling-v1.0.0"
generated_at: "2026-05-25T04:20:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["mcp-interceptors-middleware", "tools-mcp-integration"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# ⚠️ MCP Error Handling Patterns – Códigos, Retry e Fallback

> **Contrato modular**: Padroniza o tratamento de erros em todas as camadas do MCP, desde erros JSON‑RPC até falhas de rede, definindo códigos canônicos, estratégias de retry e degradação graciosa.

---

## 🎯 Propósito
Garantir que servidores e clientes MCP no ecossistema MANTIS tratem erros de forma previsível, resiliente e rastreável, alinhado às constraints C7 (resiliência) e C8 (observabilidade).

## 📋 Especificação (SDD)
- **Entradas**: Erros gerados durante execução de ferramentas, falhas de comunicação.
- **Saídas**: Respostas de erro JSON‑RPC padronizadas, logs, ações de retry.
- **Side Effects**: Possível incremento de métricas de erro.
- **Constraints Aplicáveis**: C1 (formato de erro), C5 (preservação de contexto), C7 (retry e fallback), C8 (logs).
- **Dependências**: `mcp`, `tenacity`.

---

## 🛡️ Bootstrap (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Códigos de Erro JSON‑RPC Padrão
| Código | Significado |
|--------|-------------|
| -32700 | Parse error |
| -32600 | Invalid Request |
| -32601 | Method not found |
| -32602 | Invalid params |
| -32603 | Internal error |

### 2. Gerando Erros no Servidor
```python
from mcp.server.fastmcp import FastMCP

@mcp.tool()
def risky_operation(value: int) -> str:
    if value < 0:
        mantis_log("ERROR", "invalid_input", f"value={value}")
        raise ValueError("Value must be non-negative")
    return f"Processed {value}"
```

### 3. Interceptor de Retry no Cliente
```python
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type
import httpx

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=1, max=10),
    retry=retry_if_exception_type((httpx.TimeoutException, ConnectionError))
)
async def resilient_mcp_call(tool_name, args):
    return await client.call_tool(tool_name, args)
```

### 4. Circuit Breaker Manual
```python
class CircuitBreaker:
    def __init__(self, failure_threshold=5, recovery_time=60):
        self.failures = 0
        self.threshold = failure_threshold
        self.recovery_time = recovery_time
        self.last_failure_time = None

    async def call(self, func, *args, **kwargs):
        if self.failures >= self.threshold:
            if time.time() - self.last_failure_time < self.recovery_time:
                raise Exception("Circuit breaker aberto")
            else:
                self.failures = 0  # reset
        try:
            result = await func(*args, **kwargs)
            self.failures = 0
            return result
        except Exception as e:
            self.failures += 1
            self.last_failure_time = time.time()
            raise e
```

### 5. Fallback para Ferramentas Indisponíveis
```python
async def call_with_fallback(tool_name, args):
    try:
        return await client.call_tool(tool_name, args)
    except (ConnectionError, TimeoutError) as e:
        mantis_log("WARN", "tool_fallback", f"Ferramenta {tool_name} indisponível, usando fallback")
        # Retorna um valor padrão ou tenta ferramenta equivalente
        if tool_name == "get_weather":
            return "Clima não disponível no momento."
        raise
```

### 6. Tratamento de Erro em Interceptor
```python
async def error_handler_interceptor(request, handler):
    try:
        return await handler(request)
    except PermissionError:
        mantis_log("SECURITY", "permission_denied", request.name)
        return ToolMessage(content="Acesso negado.", tool_call_id=request.id)
    except TimeoutError:
        mantis_log("ERROR", "timeout", request.name)
        return ToolMessage(content="Tempo limite excedido.", tool_call_id=request.id)
```

---

## 🧪 Testes Unitários (TDD)
```python
def test_circuit_breaker_opens():
    cb = CircuitBreaker(failure_threshold=2, recovery_time=60)
    with pytest.raises(Exception):
        cb.call(flaky_func)  # falha duas vezes
        cb.call(flaky_func)
    # terceira tentativa deve levantar "circuit breaker aberto"
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/mcp-error-handling-patterns.md --json
```

---

## 🔗 Referências Cruzadas
- [[mcp-interceptors-middleware.md]]
- [[tools-fallback.md]]
