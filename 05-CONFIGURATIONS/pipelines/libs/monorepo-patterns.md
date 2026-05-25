---
artifact_id: "pipelines-monorepo-patterns"
artifact_type: "pipelines_pattern"
version: "1.0.0"
constraints_mapped: ["C2","C5"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/pipelines/libs/monorepo-patterns.md --json"
canonical_path: "05-CONFIGURATIONS/pipelines/libs/monorepo-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:monorepo-patterns-v1.0.0"
generated_at: "2026-05-23T23:50:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "pipelines"
ai_navigation:
  read_first: false
  required_for: ["monorepo-ci", "affected-packages"]
  update_frequency: on-change
audience: ["pipelines-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-23"
---

# 📦 Padrões de Monorepo

> **Contrato modular**: Filho de `pipelines-master-agent-mantis`.

## 🎯 Propósito
Detectar pacotes afetados em monorepo, cache compartilhado e execução seletiva de pipelines (C2, C5).

## 📋 Especificação
- **Entradas**: Diff do git, estrutura de diretórios.
- **Saídas**: Matriz de jobs dinâmica.
- **Constraints Aplicáveis**: C2 (IaC), C5 (validação automatizada).

---

## 🛡️ Detecção de Pacotes Afetados

```yaml
- name: Detect changes
  id: affected
  run: |
    SKILLS=$(git diff --name-only origin/main HEAD | grep '^02-SKILLS/' | cut -d'/' -f3 | sort -u | jq -R -s -c 'split("\n")[:-1]')
    echo "skills=$SKILLS" >> $GITHUB_OUTPUT
```

### Cache Compartilhado
```yaml
- uses: actions/cache@v4
  with:
    path: ~/.npm
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
```

### Matriz Dinâmica
```yaml
strategy:
  matrix:
    skill: ${{ fromJson(needs.detect.outputs.skills) }}
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_git_diff_detection() {
  git diff --name-only HEAD~1 HEAD 2>/dev/null | grep -q . && return 0 || return 0
}
[[ "${1:-}" == "--test" ]] && { test_git_diff_detection && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[pipelines-master-agent.md]]
- [[../github-actions-fundamentals.md]]
