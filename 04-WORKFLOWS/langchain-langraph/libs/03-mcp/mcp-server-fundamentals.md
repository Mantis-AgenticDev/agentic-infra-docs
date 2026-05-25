---
artifact_id: "mcp-server-fundamentals"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/mcp-server-fundamentals.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/mcp-server-fundamentals.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:mcp-server-fundamentals-v1.0.0"
generated_at: "2026-05-25T01:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: true
  required_for: ["mcp-client-multi-server", "mcp-interceptors-middleware", "mcp-advanced-features", "mcp-enterprise-deployment"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🧩 MCP Server Fundamentals – Criação de Servidores com FastMCP e Transportes

> **Contrato modular**: Artefato filho do Master Agent. Fornece a base canônica para construir servidores MCP em Python usando FastMCP, expondo ferramentas, recursos e prompts, com suporte a transporte stdio e HTTP.

---

## 🎯 Propósito
Capacitar o ecossistema MANTIS a criar servidores MCP padronizados que exponham funcionalidades como ferramentas para agentes LangChain/LangGraph, seguindo as constraints C1‑C9.

## 📋 Especificação (SDD)
- **Entradas**: Definição de ferramentas (funções Python com type hints), recursos (dados) e prompts.
- **Saídas**: Servidor MCP em execução, capaz de responder a clientes via stdio ou HTTP.
- **Side Effects**: Processo em segundo plano, consumo de recursos.
- **Constraints Aplicáveis**: C1 (tipagem e contratos), C3 (proteção de chamadas), C5 (schema de ferramentas), C7 (resiliência), C8 (logs), C9 (rastreio de sessões).
- **Dependências**: `fastmcp`, `mcp`, `pydantic`.

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

### 1. Servidor Mínimo com FastMCP
```python
from fastmcp import FastMCP

mcp = FastMCP("MANTIS Tools")

@mcp.tool()
def ping() -> str:
    """Verifica se o servidor está ativo."""
    mantis_log("INFO", "ping", "Ferramenta ping acionada")
    return "pong"

if __name__ == "__main__":
    mcp.run(transport="stdio")
```

### 2. Ferramentas com Parâmetros Tipados
```python
@mcp.tool()
def add(a: int, b: int) -> int:
    """Soma dois números inteiros.

    Args:
        a: Primeiro número
        b: Segundo número
    """
    result = a + b
    mantis_log("INFO", "add", f"{a}+{b}={result}")
    return result
```

### 3. Recursos – Dados Estruturados Expostos
```python
@mcp.resource("config://app")
def get_app_config() -> str:
    """Retorna a configuração atual da aplicação (C3: sem secrets)."""
    config = {"version": "1.0.0", "mode": os.getenv("MODE", "B1")}
    mantis_log("INFO", "resource_config", str(config))
    return json.dumps(config)
```

### 4. Prompts – Templates Reutilizáveis
```python
@mcp.prompt()
def review_code(language: str, focus: str) -> str:
    """Template de prompt para revisão de código."""
    return f"""Revise o seguinte código {language} com foco em {focus}.
Aponte problemas de segurança, desempenho e conformidade com MANTIS C1-C9."""
```

### 5. Transporte HTTP
```python
# Para rodar como HTTP:
mcp.run(transport="http", host="0.0.0.0", port=8000)
# Recomendado apenas em redes internas seguras (C3).
```

### 6. Validação com Pydantic
```python
from pydantic import BaseModel, Field

class WeatherInput(BaseModel):
    city: str = Field(description="Nome da cidade")
    country: str = Field(default="BR", description="Código do país")

@mcp.tool()
def get_weather(input: WeatherInput) -> str:
    """Obtém o clima para uma cidade."""
    mantis_log("INFO", "weather", f"Consultando {input.city}, {input.country}")
    return f"Clima em {input.city}: ensolarado, 28°C"
```

### 7. Boas Práticas de Logging (C8)
- Sempre escreva logs para stderr em servidores stdio.
```python
import sys
print("Log de depuração", file=sys.stderr)
```

### 8. Estrutura de Projeto Recomendada
```
mcp_server/
├── pyproject.toml
├── README.md
└── src/
    └── server.py
```

---

## 🧪 Testes Unitários (TDD)
```python
def test_ping_tool():
    result = ping()
    assert result == "pong"

def test_add_tool():
    assert add(2, 3) == 5
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/mcp-server-fundamentals.md --json
```

---

## 🔗 Referências Cruzadas
- [[langchain-langraph-master-agent.md]]
- [[mcp-client-multi-server.md]]
