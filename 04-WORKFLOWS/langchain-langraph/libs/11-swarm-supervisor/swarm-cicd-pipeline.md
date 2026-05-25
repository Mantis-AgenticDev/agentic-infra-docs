---
artifact_id: "swarm-cicd-pipeline"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/11-swarm-supervisor/swarm-cicd-pipeline.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/11-swarm-supervisor/swarm-cicd-pipeline.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:swarm-cicd-pipeline-v1"
generated_at: "2026-05-27T10:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["swarm-supervisor-patterns", "cicd-pipeline-agents"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks", "workflows-ceo"]
status: "🟢 Novo"
next_review: "2026-08-27"
---

# 🧩 Swarm CI/CD Pipeline — Integração e Entrega Contínua para Enxames

> **Contrato modular**: Artefato filho do Master Agent. Implementa um pipeline de CI/CD completo para projetos swarm/supervisor, com lint, testes, build e deploy automatizado via GitHub Actions.

## 🎯 Propósito

Automatizar a validação e o deploy de enxames multi-agente, garantindo que cada alteração passe por testes de unidade, conformidade de código e empacotamento antes de ser publicada.

## 📋 Especificação (SDD)
- **Entradas**: Código fonte do enxame, `pyproject.toml`, `langgraph.json`
- **Saídas**: Artefato publicado (Docker image, pacote PyPI), relatório de CI
- **Side Effects**: Execução de testes, build de imagem, push para registry
- **Constraints Aplicáveis**: C1, C2, C3, C5, C7, C8
- **Dependências**: `GitHub Actions`, `uv`, `ruff`, `pytest`, `langgraph-cli`

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
```

```yaml
# ═══════════════════════════════════════════════════════════════════════════
# 1. WORKFLOW DE CI (GITHUB ACTIONS)
# ═══════════════════════════════════════════════════════════════════════════
# Arquivo: .github/workflows/ci.yml
name: Swarm CI

on:
  push:
    branches: [ main ]
  pull_request:
  workflow_dispatch:

permissions:
  contents: read

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up Python + uv
        uses: astral-sh/setup-uv@v5
        with:
          python-version: "3.11"
      - name: Install dependencies
        run: uv sync --group test
      - name: Run lint
        run: make lint

  test:
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4
      - name: Set up Python + uv
        uses: astral-sh/setup-uv@v5
        with:
          python-version: "3.11"
      - name: Install dependencies
        run: uv sync --group test
      - name: Run tests
        run: make test

  build:
    runs-on: ubuntu-latest
    needs: test
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - name: Set up Python + uv
        uses: astral-sh/setup-uv@v5
        with:
          python-version: "3.11"
      - name: Build Docker image
        run: langgraph build -t swarm-app:latest
      - name: Push to registry
        run: docker push swarm-app:latest
```

```python
# ═══════════════════════════════════════════════════════════════════════════
# 2. MAKEFILE DE AUTOMAÇÃO
# ═══════════════════════════════════════════════════════════════════════════
MAKEFILE_CONTENT = """
.PHONY: lint format test build

PYTHON_FILES = src/ tests/

lint:
\tuv run ruff check $(PYTHON_FILES)
\tuv run ruff format --diff $(PYTHON_FILES)
\tuv run mypy $(PYTHON_FILES)

format:
\tuv run ruff check --fix $(PYTHON_FILES)
\tuv run ruff format $(PYTHON_FILES)

test:
\tuv run pytest tests/ -v --cov=src

build:
\tlanggraph build -t swarm-app:latest
"""

# ═══════════════════════════════════════════════════════════════════════════
# 3. CONFIGURAÇÃO DE PYPROJECT.TOML
# ═══════════════════════════════════════════════════════════════════════════
PYPROJECT_TEMPLATE = """
[project]
name = "mantis-swarm"
version = "0.1.0"
description = "MANTIS Swarm Multi-Agent System"
requires-python = ">=3.11"
dependencies = [
    "langgraph>=1.0",
    "langgraph-swarm>=0.1",
    "langgraph-supervisor>=0.1",
    "langchain>=1.0",
    "langchain-openai>=1.0",
]

[build-system]
requires = ["setuptools>=73.0"]
build-backend = "setuptools.build_meta"

[tool.ruff]
line-length = 88
target-version = "py311"

[tool.ruff.lint]
select = ["ALL"]
ignore = ["E501", "D100", "D104", "ANN"]

[tool.pytest.ini_options]
testpaths = ["tests"]
"""

# ═══════════════════════════════════════════════════════════════════════════
# 4. VALIDATOR DE PRÉ-COMMIT
# ═══════════════════════════════════════════════════════════════════════════
class PreCommitValidator:
    """Executa validações antes do commit."""
    @staticmethod
    def run_all():
        import subprocess
        commands = [
            ["uv", "run", "ruff", "check", "src/", "tests/"],
            ["uv", "run", "ruff", "format", "--check", "src/", "tests/"],
            ["uv", "run", "pytest", "tests/", "-q"],
        ]
        for cmd in commands:
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode != 0:
                mantis_log("ERROR", "precommit_failed", " ".join(cmd))
                print(result.stderr)
                return False
            mantis_log("INFO", "precommit_pass", " ".join(cmd))
        return True

# ═══════════════════════════════════════════════════════════════════════════
# 5. CONFIGURAÇÃO DE LANGGRAPH.JSON
# ═══════════════════════════════════════════════════════════════════════════
LANGGRAPH_CONFIG = """
{
  "dependencies": ["."],
  "graphs": {
    "swarm_agent": "./src/swarm_app.py:build"
  },
  "env": ".env",
  "python_version": "3.11",
  "image_distro": "wolfi"
}
"""
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from swarm_cicd_pipeline import PreCommitValidator

def test_precommit_validator_structure():
    # Não executa realmente, apenas verifica que o método existe
    assert hasattr(PreCommitValidator, "run_all")

def test_makefile_content():
    from swarm_cicd_pipeline import MAKEFILE_CONTENT
    assert "lint:" in MAKEFILE_CONTENT
    assert "test:" in MAKEFILE_CONTENT
    assert "build:" in MAKEFILE_CONTENT

def test_pyproject_template():
    from swarm_cicd_pipeline import PYPROJECT_TEMPLATE
    assert "mantis-swarm" in PYPROJECT_TEMPLATE
    assert "langgraph-swarm" in PYPROJECT_TEMPLATE
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/11-swarm-supervisor/swarm-cicd-pipeline.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[swarm-supervisor-patterns.md]]
- [[cicd-pipeline-agents.md]]
