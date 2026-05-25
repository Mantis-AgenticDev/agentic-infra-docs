---
artifact_id: "pipelines-github-actions-fundamentals"
artifact_type: "pipelines_pattern"
version: "1.0.0"
constraints_mapped: ["C3","C5"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/pipelines/libs/github-actions-fundamentals.md --json"
canonical_path: "05-CONFIGURATIONS/pipelines/libs/github-actions-fundamentals.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:gha-fundamentals-v1.0.0"
generated_at: "2026-05-23T23:05:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "pipelines"
ai_navigation:
  read_first: false
  required_for: ["workflow-creation", "github-actions-setup"]
  update_frequency: on-change
audience: ["pipelines-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-23"
---

# 🏗️ Fundamentos de GitHub Actions

> **Contrato modular**: Artefato filho de `pipelines-master-agent-mantis`. Herda hardening e constraints do Master.

## 🎯 Propósito
Fornecer a estrutura canônica de workflows GitHub Actions, tipos de steps, gestão de secrets/variáveis e configuração de ambientes protegidos (C3, C5).

## 📋 Especificação
- **Entradas**: Nome do workflow, gatilhos, jobs necessários.
- **Saídas**: Arquivo YAML de workflow válido.
- **Constraints Aplicáveis**: C3 (secrets nunca em texto plano), C5 (validação automatizada).

---

## 🛡️ Estrutura Base de Workflow

```yaml
name: Nome Descritivo do Pipeline

on:  # Disparadores
  push:
    branches: [main, develop]
    paths: ['src/**', 'package.json']
  pull_request:
    branches: [main]
  workflow_dispatch:

env:
  NODE_ENV: production

jobs:
  build:
    runs-on: ubuntu-latest
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11  # SHA imutável
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
```

### Tipos de Steps
| Tipo | Sintaxe | Uso |
|------|---------|-----|
| Action marketplace | `uses: owner/repo@ref` | Ações pré-construídas |
| Shell command | `run: comando` | Scripts personalizados |
| Composite action | `uses: ./.github/actions/setup` | Reutilização interna |
| Reusable workflow | `uses: ./.github/workflows/template.yml` | Orquestração complexa |

### Gestão de Secrets e Variáveis
```yaml
# Secrets (sensíveis, cifrados)
- env:
    AWS_KEY: ${{ secrets.AWS_ACCESS_KEY_ID }}
# Variáveis (não sensíveis)
- env:
    API_ENDPOINT: ${{ vars.API_ENDPOINT }}
# Scoped por ambiente
jobs:
  deploy-production:
    environment:
      name: production
```

**Regras de segurança**: Nunca hardcodear credenciais. Usar OIDC sempre que possível. Secrets rotativos a cada 90 dias.

---

## 🧪 Testes Unitários (TDD)
```bash
test_workflow_syntax() {
  local tmp; tmp=$(mktemp -d)
  cat > "$tmp/workflow.yml" << 'EOF'
name: test
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps: [run: echo ok]
EOF
  python3 -c "import yaml; yaml.safe_load(open('$tmp/workflow.yml'))" && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { test_workflow_syntax && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[pipelines-master-agent.md]]
- [[../docker-compose/libs/security-patterns.md]] — Patterns de secrets complementares
- [[/05-CONFIGURATIONS/validation/orchestrator-engine/main.go]]
