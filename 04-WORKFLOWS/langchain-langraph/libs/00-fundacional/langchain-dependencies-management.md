---
artifact_id: "langchain-dependencies-management"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C5","C7"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/langchain-dependencies-management.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/langchain-dependencies-management.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:langchain-deps-v1.0.0"
generated_at: "2026-05-24T23:45:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deploy-docker", "deploy-kubernetes", "integration-configurations"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 📦 LangChain Dependencies Management – Versionamento e Instalação Correta

> **Contrato modular**: Fornece as regras de dependências para projetos LangChain/LangGraph/D Agents, garantindo estabilidade semântica e conformidade com C1 (interfaces) e C2 (versionamento).

---

## 🎯 Propósito
Evitar erros de versionamento e garantir que os agentes MANTIS usem a stack LTS 1.0 com as integrações corretas, minimizando breaking changes e vulnerabilidades.

## 📋 Especificação (SDD)
- **Entradas**: Requisitos do projeto, stack desejada (LangGraph ou Deep Agents).
- **Saídas**: Conjunto mínimo de dependências `pyproject.toml`/`package.json` válidas.
- **Side Effects**: Instalação de pacotes; influencia a reprodutibilidade.
- **Constraints Aplicáveis**: C1 (contrato de versão), C2 (reprodutibilidade), C5 (estrutura de projeto), C7 (estabilidade).
- **Dependências**: `pip`, `npm`, `poetry`.

---

## 🛡️ Bootstrap (C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    import json, datetime, os
    def mantis_log(level, event, detail=""):
        entry = {"ts": datetime.datetime.utcnow().isoformat() + "Z", "level": level, "tenant": os.getenv("TENANT_ID", "global"), "event": event, "detail": detail, "trace_id": os.getenv("TRACE_ID", "null"), "span_id": os.getenv("SPAN_ID", "null"), "fallback": "true"}
        print(json.dumps(entry), flush=True)
```

### 1. Stack Mínima LangGraph (Python)
```toml
# pyproject.toml
[tool.poetry.dependencies]
python = "^3.10"
langchain = "^1.0"
langgraph = "^1.0"
langsmith = "^0.3.0"
langchain-anthropic = "^1.0"  # ou outro modelo
```

### 2. Stack Mínima LangGraph (TypeScript)
```json
{
  "dependencies": {
    "@langchain/core": "^1.0.0",
    "langchain": "^1.0.0",
    "@langchain/langgraph": "^1.0.0",
    "langsmith": "^0.3.0",
    "@langchain/anthropic": "^1.0.0"
  }
}
```

### 3. Deep Agents Stack
```toml
[tool.poetry.dependencies]
python = "^3.10"
deepagents = "latest"
langchain = "^1.0"
langsmith = "^0.3.0"
```

### 4. Regras de Versionamento
| Pacote | Estratégia | Exemplo |
|--------|-----------|---------|
| `langchain`, `langgraph` | Minor automático (semver) | `>=1.0,<2.0` |
| `langsmith` | Minor automático | `>=0.3.0` |
| Integrações dedicadas (`langchain-openai`) | Latest | `^1.0` |
| `langchain-community` | Pin exato de minor | `>=0.4.0,<0.5.0` |
| `deepagents` | Pin em versão testada | `==0.2.1` em produção |

### 5. Variáveis de Ambiente Obrigatórias (C3)
```bash
export LANGSMITH_API_KEY="ls__..."
export LANGSMITH_PROJECT="mantis-agentic"
export ANTHROPIC_API_KEY="sk-ant-..."
# Provedores adicionais conforme necessário
```

### 6. Erros Comuns e Correções
- **Usar `langchain-community` sem pin**: mudanças quebram em minor → pin `>=0.4.0,<0.5.0`.
- **Não instalar `@langchain/core` em monorepos TypeScript**: adicionar explicitamente.
- **Python <3.10**: LangChain 1.0 não suporta; atualizar runtime.
- **Import obsoleto de `langchain_community`**: preferir `langchain-tavily`, `langchain-chroma` etc.

---

## 🧪 Testes Unitários
```python
def test_dependencies():
    import langchain
    assert langchain.__version__ >= "1.0"

def test_environment():
    import os
    assert "LANGSMITH_API_KEY" in os.environ
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/langchain-dependencies-management.md \
  --json --check-structural --check-error-handling
```

---

## 🔗 Referências Cruzadas
- [[langchain-langraph-master-agent.md]]
- [[/05-CONFIGURATIONS/validation/orchestrator-engine/main.go]]

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal |
|--------|------|-------|------------------|
| 1.0.0 | 2026-05-24T23:45:00Z | langchain-langraph-master-agent | Criação inicial: gestão de dependências |
