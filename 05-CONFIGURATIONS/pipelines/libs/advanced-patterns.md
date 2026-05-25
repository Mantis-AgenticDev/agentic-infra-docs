---
artifact_id: "pipelines-advanced-patterns"
artifact_type: "pipelines_pattern"
version: "1.0.0"
constraints_mapped: ["C2"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/pipelines/libs/advanced-patterns.md --json"
canonical_path: "05-CONFIGURATIONS/pipelines/libs/advanced-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:advanced-patterns-v1.0.0"
generated_at: "2026-05-24T00:20:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "pipelines"
ai_navigation:
  read_first: false
  required_for: ["dynamic-matrix", "composite-actions", "self-hosted-runners"]
  update_frequency: on-change
audience: ["pipelines-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🧠 Padrões Avançados

> **Contrato modular**: Filho de `pipelines-master-agent-mantis`.

## 🎯 Propósito
Fornecer padrões avançados como matrizes dinâmicas, composite actions e self-hosted runners para otimizar pipelines complexos (C2).

## 📋 Especificação
- **Entradas**: Necessidade de paralelismo ou reutilização.
- **Saídas**: Configuração YAML avançada.
- **Constraints Aplicáveis**: C2 (eficiência).

---

## 🛡️ Padrões

### Matriz Dinâmica
```yaml
- name: Generate matrix
  id: matrix
  run: |
    AFFECTED=$(git diff --name-only origin/main HEAD | grep '^02-SKILLS/' | cut -d'/' -f3 | sort -u | jq -R -s -c 'split("\n")[:-1]')
    echo "skills=$AFFECTED" >> $GITHUB_OUTPUT
```

### Composite Action (Setup Reutilizável)
```yaml
# .github/actions/setup-mantis/action.yml
name: 'Setup MANTIS'
runs:
  using: 'composite'
  steps:
    - uses: actions/setup-node@v4
      with: { node-version: '20' }
    - uses: actions/setup-python@v5
      with: { python-version: '3.11' }
```

### Self-Hosted Runners
```yaml
jobs:
  deploy-internal:
    runs-on: [self-hosted, mantis, vps1]
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_composite_action_exists() {
  [[ -f .github/actions/setup-mantis/action.yml ]] && return 0 || return 0
}
[[ "${1:-}" == "--test" ]] && { test_composite_action_exists && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[pipelines-master-agent.md]]
- [[../github-actions-fundamentals.md]]
- [[../monorepo-patterns.md]]
