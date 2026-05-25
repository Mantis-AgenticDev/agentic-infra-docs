---
artifact_id: "deep-agents-error-handling"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-error-handling.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-error-handling.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-error-handling-v1.0.0"
generated_at: "2026-05-25T19:45:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-core-customization"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# ⚠️ Deep Agents – Tratamento de Erros e Resiliência

> **Contrato modular**: Artefato filho do Master Agent. Cobre padrões de tratamento de erros em ferramentas, retry, fallback, circuit breaker e recuperação de falhas.

---

## 🎯 Propósito
Garantir que agentes MANTIS sejam resilientes a falhas em ferramentas e APIs, recuperando-se graciosamente e mantendo a integridade do estado.

## 📋 Especificação (SDD)
- **Entradas**: Configuração de retry, estratégias de fallback.
- **Saídas**: Agente que lida com erros sem quebrar.
- **Side Effects**: Logs de erro, tentativas de retry.
- **Constraints Aplicáveis**: C1 (schema de erro), C5 (mensagens de erro), C7 (retry e fallback), C8 (logs).
- **Dependências**: `tenacity`, `deepagents`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Ferramenta com Tratamento de Erro

```python
from langchain.tools import tool

@tool
def risky_operation(query: str) -> str:
    """Operação que pode falhar."""
    try:
        result = perform_external_call(query)
        return f"Sucesso: {result}"
    except Exception as e:
        mantis_log("ERROR", "tool_failed", str(e))
        return f"Erro: {str(e)}"
```

### 2. Retry com Tenacity

```python
from tenacity import retry, stop_after_attempt, wait_exponential

@tool
@retry(stop=stop_after_attempt(3), wait=wait_exponential(min=1, max=10))
def resilient_api_call(url: str) -> str:
    response = requests.get(url, timeout=10)
    response.raise_for_status()
    return response.text
```

### 3. Fallback Automático

```python
@tool
def search_with_fallback(query: str) -> str:
    try:
        return primary_search(query)
    except Exception:
        mantis_log("WARN", "fallback", "Usando busca secundária")
        return secondary_search(query)
```

### 4. Circuit Breaker

```python
import pybreaker

db_breaker = pybreaker.CircuitBreaker(fail_max=3, reset_timeout=30)

@tool
def protected_db_query(query: str) -> str:
    @db_breaker
    def execute():
        return database.execute(query)
    return execute()
```

### 5. Recuperação de Estado com Checkpointer

```python
# Se um agente falhar, o estado está salvo no checkpointer.
# Pode-se retomar a execução do ponto de falha.
config = {"configurable": {"thread_id": "recovery-1"}}
try:
    result = agent.invoke({...}, config=config)
except Exception:
    state = agent.get_state(config)
    mantis_log("INFO", "recovery", f"Estado salvo em {state.next}")
    # Retomar com Command
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_retry_decorator():
    @retry(stop=stop_after_attempt(2))
    def flaky():
        raise Exception("fail")
    with pytest.raises(Exception):
        flaky()
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-error-handling.md --json
```

---

## 🔗 Referências Cruzadas
- [[deep-agents-core-customization.md]]
```

---

**Progreso: 25/45 artefactos generados.** Pasamos la mitad del bloque Deep Agents. Continuo con el siguiente lote inmediatamente. 🚀
