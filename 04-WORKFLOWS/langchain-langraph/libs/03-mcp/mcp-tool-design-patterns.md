---
artifact_id: "mcp-tool-design-patterns"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/mcp-tool-design-patterns.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/mcp-tool-design-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:mcp-tool-design-patterns-v1.0.0"
generated_at: "2026-05-25T02:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["mcp-server-fundamentals", "tools-mcp-integration", "agents-swarm-architecture"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🛠️ MCP Tool Design Patterns – Escalabilidade, Validação e Boas Práticas

> **Contrato modular**: Este artefato cataloga padrões de design para criação de ferramentas MCP robustas, reutilizáveis e seguras, cobrindo nomenclatura, schemas, validação de entrada, tratamento de erros e operações assíncronas.

---

## 🎯 Propósito
Fornecer um guia canônico para projetar ferramentas MCP que se comportem de forma determinística, segura e de fácil manutenção no ecossistema MANTIS.

## 📋 Especificação (SDD)
- **Entradas**: Requisitos da ferramenta, definição de parâmetros.
- **Saídas**: Ferramenta MCP implementada com schema explícito e tratamento de falhas.
- **Side Effects**: Pode alterar estado externo (banco de dados, APIs) se documentado.
- **Constraints Aplicáveis**: C1 (contrato e tipagem), C3 (proteção de dados sensíveis), C5 (estrutura de saída), C7 (resiliência e idempotência), C8 (rastreabilidade).
- **Dependências**: `fastmcp`, `pydantic`, `asyncio`.

---

## 🛡️ Bootstrap (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    import json, datetime, os
    def mantis_log(level, event, detail=""):
        entry = {"ts": datetime.datetime.utcnow().isoformat() + "Z", "level": level, "tenant": os.getenv("TENANT_ID", "global"), "event": event, "detail": detail, "trace_id": os.getenv("TRACE_ID", "null"), "span_id": os.getenv("SPAN_ID", "null"), "fallback": "true"}
        print(json.dumps(entry), flush=True)
```

### 1. Nomenclatura e Descrições
- Use verbos no infinitivo: `get_forecast`, `calculate_risk`, `search_documents`.
- Descrições devem ser claras e incluir o propósito e efeitos colaterais.
- Exemplo:
```python
@mcp.tool()
def delete_user(user_id: str, soft: bool = True) -> str:
    """Remove um usuário do sistema.

    Args:
        user_id: Identificador único do usuário.
        soft: Se True, apenas desativa; False remove permanentemente.
    """
    ...
```

### 2. Schemas com Pydantic (C1, C5)
Sempre use modelos Pydantic para validação e documentação automática.
```python
from pydantic import BaseModel, Field, validator

class TransferInput(BaseModel):
    from_account: str = Field(..., description="Conta de origem")
    to_account: str = Field(..., description="Conta de destino")
    amount: float = Field(..., gt=0, description="Valor positivo")
    currency: str = Field(default="BRL", pattern=r"^[A-Z]{3}$")

    @validator('from_account', 'to_account')
    def accounts_must_differ(cls, v, values, **kwargs):
        if 'to_account' in values and v == values['to_account']:
            raise ValueError('from_account e to_account devem ser diferentes')
        return v

@mcp.tool()
async def transfer_funds(input: TransferInput) -> str:
    """Realiza transferência entre contas."""
    mantis_log("INFO", "transfer_start", f"De {input.from_account} para {input.to_account}, valor {input.amount}")
    # lógica...
    return f"Transferência de {input.amount} {input.currency} realizada."
```

### 3. Operações Assíncronas e Timeout (C7)
Ferramentas que fazem chamadas externas devem ser assíncronas e ter timeout.
```python
import asyncio

@mcp.tool()
async def fetch_external_data(url: str) -> str:
    try:
        async with httpx.AsyncClient() as client:
            response = await asyncio.wait_for(client.get(url), timeout=10.0)
            response.raise_for_status()
            mantis_log("INFO", "fetch_success", url)
            return response.text
    except asyncio.TimeoutError:
        mantis_log("ERROR", "timeout", url)
        return "Erro: tempo limite excedido."
```

### 4. Idempotência e Retry
Para ferramentas com efeitos colaterais, implemente idempotência (ex: token de idempotência) ou retry com segurança.
```python
@mcp.tool()
async def process_payment(order_id: str, idempotency_key: str) -> str:
    # Verificar se já processado
    if cache.exists(f"payment:{idempotency_key}"):
        return cache.get(f"payment:{idempotency_key}")
    try:
        result = await payment_gateway.charge(order_id)
        cache.set(f"payment:{idempotency_key}", result, ttl=3600)
        return result
    except Exception as e:
        mantis_log("ERROR", "payment_failed", str(e))
        return f"Falha no pagamento: {e}"
```

### 5. Ferramentas de Longa Duração e Progresso
Use notificações de progresso para manter o cliente informado.
```python
@mcp.tool()
async def generate_report(start_date: str, end_date: str, ctx: Context) -> str:
    total_steps = 10
    for i in range(total_steps):
        # ... trabalho
        await ctx.report_progress(progress=i+1, total=total_steps, message=f"Etapa {i+1}")
    return "Relatório gerado."
```

### 6. Tratamento de Erros e Mensagens Amigáveis
```python
@mcp.tool()
def divide(a: float, b: float) -> float:
    """Divide dois números."""
    if b == 0:
        mantis_log("WARN", "division_by_zero", f"{a}/{b}")
        raise ValueError("Divisão por zero não é permitida.")
    return a / b
```

### 7. Filtragem Dinâmica de Ferramentas (C3)
No cliente, filtre ferramentas sensíveis baseado no tenant.
```python
def filter_tools(tools, tenant_id):
    if tenant_id != "admin":
        return [t for t in tools if not t.name.startswith("admin_")]
    return tools
```

---

## 🧪 Testes Unitários (TDD)
```python
def test_transfer_validation():
    with pytest.raises(ValidationError):
        TransferInput(from_account="A", to_account="A", amount=100)

def test_divide_by_zero():
    with pytest.raises(ValueError):
        divide(1, 0)
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/mcp-tool-design-patterns.md --json
```

---

## 🔗 Referências Cruzadas
- [[mcp-server-fundamentals.md]]
- [[tools-mcp-integration.md]]
