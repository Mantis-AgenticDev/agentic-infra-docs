---
artifact_id: "pipelines-gitlab-ci-patterns"
artifact_type: "pipelines_pattern"
version: "1.0.0"
constraints_mapped: ["C5"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/pipelines/libs/gitlab-ci-patterns.md --json"
canonical_path: "05-CONFIGURATIONS/pipelines/libs/gitlab-ci-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:gitlab-ci-patterns-v1.0.0"
generated_at: "2026-05-24T01:05:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "pipelines"
ai_navigation:
  read_first: false
  required_for: ["gitlab-ci-setup", "gitlab-mr-review"]
  update_frequency: on-change
audience: ["pipelines-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🦊 Padrões GitLab CI

> **Contrato modular**: Filho de `pipelines-master-agent-mantis`.

## 🎯 Propósito
Fornecer alternativas a GitHub Actions usando GitLab CI, incluindo `.gitlab-ci.yml`, MR review e escaneio de segurança (C5).

## 📋 Especificação
- **Entradas**: Projeto GitLab, configurações de runner.
- **Saídas**: `.gitlab-ci.yml` funcional.
- **Constraints Aplicáveis**: C5 (validação).

---

## 🛡️ Estrutura Básica

```yaml
stages:
  - validate
  - test
  - build
  - deploy-staging
  - deploy-production

validate-constraints:
  stage: validate
  script:
    - bash orchestrator-engine.sh --domain all --strict

deploy:production:
  stage: deploy-production
  when: manual  # Gate humano
  environment:
    name: production
```

### MR Review com `/review !ID`
```bash
glab mr view 123
glab mr diff 123
glab mr note 123 --message "✅ validation_command presente no frontmatter"
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_gitlab_ci_syntax() {
  local tmp; tmp=$(mktemp -d)
  cat > "$tmp/.gitlab-ci.yml" << 'EOF'
stages: [test]
test:
  stage: test
  script: echo ok
EOF
  python3 -c "import yaml; yaml.safe_load(open('$tmp/.gitlab-ci.yml'))" && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { test_gitlab_ci_syntax && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[pipelines-master-agent.md]]
- [[../github-actions-fundamentals.md]]
- [[../security-patterns.md]]
