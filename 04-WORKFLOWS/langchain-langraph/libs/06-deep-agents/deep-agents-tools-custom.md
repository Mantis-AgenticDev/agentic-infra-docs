---
artifact_id: "deep-agents-tools-custom"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-tools-custom.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-tools-custom.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-tools-custom-v1.0.0"
generated_at: "2026-05-25T22:45:00Z"
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

# 🛠️ Deep Agents – Ferramentas Customizadas Avançadas

> **Contrato modular**: Artefato filho do Master Agent. Ensina a criar ferramentas robustas e seguras para Deep Agents, com validação Pydantic, operações assíncronas, acesso ao runtime, tratamento de erros e documentação.

---

## 🎯 Propósito
Permitir que agentes MANTIS tenham ferramentas customizadas que seguem as constraints C1‑C9, com validação rigorosa, resiliência e observabilidade.

## 📋 Especificação (SDD)
- **Entradas**: Definição de função, schema Pydantic, configuração de runtime.
- **Saídas**: Ferramenta LangChain compatível com `create_deep_agent`.
- **Side Effects**: Chamadas externas, acesso a estado.
- **Constraints Aplicáveis**: C1 (schema e tipagem), C3 (proteção de dados), C5 (validação), C7 (timeout e retry), C8 (logs).
- **Dependências**: `langchain.tools`, `pydantic`, `httpx`.

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

### 1. Ferramenta com Validação Pydantic

```python
from pydantic import BaseModel, Field, validator
from langchain.tools import tool

class TransferInput(BaseModel):
    from_account: str = Field(..., description="Conta de origem")
    to_account: str = Field(..., description="Conta de destino")
    amount: float = Field(..., gt=0, description="Valor positivo")
    currency: str = Field(default="BRL", pattern=r"^[A-Z]{3}$")

    @validator('to_account')
    def accounts_must_differ(cls, v, values):
        if 'from_account' in values and v == values['from_account']:
            raise ValueError('Contas de origem e destino devem ser diferentes')
        return v

@tool(args_schema=TransferInput)
def transfer_funds(from_account: str, to_account: str, amount: float, currency: str = "BRL") -> str:
    """Realiza transferência entre contas."""
    mantis_log("INFO", "transfer_start", f"De {from_account} para {to_account}, {amount} {currency}")
    try:
        result = execute_transfer(from_account, to_account, amount, currency)
        mantis_log("INFO", "transfer_success", f"ID: {result}")
        return f"Transferência de {amount} {currency} realizada com sucesso."
    except Exception as e:
        mantis_log("ERROR", "transfer_failed", str(e))
        return f"Erro na transferência: {e}"
```

### 2. Ferramenta Assíncrona com Timeout

```python
import asyncio
import httpx

@tool
async def fetch_external_data(url: str, timeout: int = 10) -> str:
    """Busca dados de uma API externa com timeout."""
    try:
        async with httpx.AsyncClient(timeout=timeout) as client:
            response = await client.get(url)
            response.raise_for_status()
            mantis_log("INFO", "fetch_success", url)
            return response.text[:5000]
    except asyncio.TimeoutError:
        mantis_log("ERROR", "timeout", url)
        return f"Erro: tempo limite de {timeout}s excedido."
    except Exception as e:
        mantis_log("ERROR", "fetch_failed", str(e))
        return f"Erro ao acessar API: {e}"
```

### 3. Ferramenta com Acesso ao Runtime

```python
from langchain.tools import ToolRuntime

@dataclass
class Context:
    user_id: str
    tenant_id: str

@tool
async def get_user_data(query: str, runtime: ToolRuntime[Context]) -> str:
    """Busca dados do usuário atual."""
    user_id = runtime.context.user_id
    tenant_id = runtime.context.tenant_id
    mantis_log("INFO", "user_data_access", f"User: {user_id}, Tenant: {tenant_id}")
    data = await database.fetch_user_data(user_id, query)
    return json.dumps(data, default=str)
```

### 4. Ferramenta com Retry e Fallback

```python
from tenacity import retry, stop_after_attempt, wait_exponential

@tool
@retry(stop=stop_after_attempt(3), wait=wait_exponential(min=1, max=10))
def resilient_api_call(endpoint: str, payload: dict) -> str:
    """Chama API externa com retry automático."""
    response = requests.post(endpoint, json=payload, timeout=30)
    response.raise_for_status()
    return response.text
```

### 5. Ferramenta de Banco de Dados Segura

```python
@tool
def sql_query(query: str, readonly: bool = True) -> str:
    """Executa consulta SQL segura (somente SELECT se readonly=True)."""
    if readonly and not query.strip().upper().startswith("SELECT"):
        mantis_log("SECURITY", "blocked_query", query[:100])
        return "Erro: apenas consultas SELECT são permitidas."
    try:
        with engine.connect() as conn:
            result = conn.execute(text(query))
            rows = [dict(row._mapping) for row in result]
            mantis_log("INFO", "sql_success", f"{len(rows)} linhas")
            return json.dumps(rows, default=str)
    except Exception as e:
        mantis_log("ERROR", "sql_failed", str(e))
        return f"Erro SQL: {e}"
```

### 6. Ferramenta com Progresso

```python
@tool
async def generate_report(start_date: str, end_date: str, runtime: ToolRuntime) -> str:
    """Gera relatório com notificações de progresso."""
    total_steps = 10
    for i in range(total_steps):
        await asyncio.sleep(0.5)
        # Em uma implementação real, emitiria progresso via runtime
        mantis_log("INFO", "report_progress", f"Etapa {i+1}/{total_steps}")
    return "Relatório gerado com sucesso."
```

### 7. Boas Práticas de Documentação de Ferramentas

```python
@tool
def search_database(query: str, max_results: int = 5, filters: dict | None = None) -> str:
    """Pesquisa no banco de dados interno.

    Use esta ferramenta quando precisar buscar informações estruturadas
    sobre clientes, produtos ou transações.

    Args:
        query: Termos de busca (mínimo 3 caracteres).
        max_results: Número máximo de resultados (1-20).
        filters: Filtros opcionais no formato {"campo": "valor"}.

    Returns:
        JSON com array de resultados ou mensagem de erro.
    """
    # ... implementação
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_transfer_validation():
    with pytest.raises(ValidationError):
        TransferInput(from_account="A", to_account="A", amount=100)

def test_sql_readonly():
    result = sql_query.invoke({"query": "DELETE FROM users", "readonly": True})
    assert "Erro" in result
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-tools-custom.md --json
```

---

## 🔗 Referências Cruzadas
- [[deep-agents-core-customization.md]]
