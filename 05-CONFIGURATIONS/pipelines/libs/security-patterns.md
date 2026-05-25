---
artifact_id: "pipelines-security-patterns"
artifact_type: "pipelines_pattern"
version: "1.0.0"
constraints_mapped: ["C3"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/pipelines/libs/security-patterns.md --json"
canonical_path: "05-CONFIGURATIONS/pipelines/libs/security-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:pipeline-security-v1.0.0"
generated_at: "2026-05-23T23:15:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "pipelines"
ai_navigation:
  read_first: false
  required_for: ["pipeline-security", "secret-management"]
  update_frequency: on-change
audience: ["pipelines-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-23"
---

# 🔐 Segurança em Pipelines

> **Contrato modular**: Filho de `pipelines-master-agent-mantis`. Complementa [[../../docker-compose/libs/security-patterns.md]] com práticas específicas de CI/CD.

## 🎯 Propósito
Garantir que secrets, credenciais e configurações sensíveis nunca estejam em texto plano nos pipelines, usando OIDC, pinning por SHA e permissões mínimas (C3).

## 📋 Especificação
- **Entradas**: Tipo de segredo (AWS, Docker, API keys).
- **Saídas**: Configuração YAML segura para GitHub Actions.
- **Constraints Aplicáveis**: C3.

---

## 🛡️ Práticas Obrigatórias

### OIDC em vez de credenciais longevas
```yaml
- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsRole
    aws-region: us-east-1
```

### Pinning de Actions por SHA
```yaml
# ✅ SHA imutável
- uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11
# ❌ Tag móvel
- uses: actions/checkout@v4
```

### Permissões mínimas por job
```yaml
permissions:
  contents: read
  id-token: write
```

### Prevenção de injeção de scripts
```yaml
# ✅ Passar para variável de ambiente
- run: echo "Título: $TITLE"
  env:
    TITLE: ${{ github.event.issue.title }}
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_no_hardcoded_secrets() {
  local tmp; tmp=$(mktemp -d)
  cat > "$tmp/workflow.yml" << 'EOF'
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: echo "safe"
EOF
  grep -qE '(password|secret|token).*=' "$tmp/workflow.yml" && return 1 || return 0
}
[[ "${1:-}" == "--test" ]] && { test_no_hardcoded_secrets && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[pipelines-master-agent.md]]
- [[../../docker-compose/libs/security-patterns.md]] — Segurança em contêineres
- [[/05-CONFIGURATIONS/validation/audit-secrets.sh]] — Scanner de secrets
