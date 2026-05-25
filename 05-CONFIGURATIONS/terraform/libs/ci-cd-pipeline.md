---
artifact_id: "terraform-ci-cd-pipeline"
artifact_type: "terraform_pattern"
version: "1.0.0"
constraints_mapped: ["C5","C6","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/terraform/libs/ci-cd-pipeline.md --json"
canonical_path: "05-CONFIGURATIONS/terraform/libs/ci-cd-pipeline.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:tf-cicd-v1.0.0"
generated_at: "2026-05-24T05:35:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "terraform"
ai_navigation:
  read_first: false
  required_for: ["terraform-pipeline", "drift-detection", "plan-review"]
  update_frequency: on-change
audience: ["terraform-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🚀 Pipeline de CI/CD para Terraform

> **Contrato modular**: Filho de `terraform-master-agent-mantis`.

## 🎯 Propósito
Padronizar o pipeline de validação, planejamento e aplicação de infraestrutura com GitHub Actions, incluindo detecção programada de drift e revisão paralela de planos (C5, C6, C8).

## 📋 Especificação
- **Entradas**: Ambiente alvo, credenciais OIDC.
- **Saídas**: Workflow de GitHub Actions funcional.
- **Constraints Aplicáveis**: C5 (validação automatizada), C6 (aprovação), C8 (qualidade).

---

## 🛡️ Estrutura do Pipeline

```yaml
name: Terraform Plan & Apply
on:
  pull_request: { paths: ['terraform/**'] }
  push: { branches: [main], paths: ['terraform/**'] }

jobs:
  validate:
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - run: terraform validate
      - run: terraform fmt -check -recursive

  security-scan:
    steps:
      - uses: bridgecrewio/checkov-action@master
      - uses: aquasecurity/tfsec-action@v1.0.0

  plan:
    needs: [validate, security-scan]
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with: { role-to-assume: ${{ secrets.TERRAFORM_ROLE_ARN }} }
      - run: terraform plan -out=tfplan

  apply:
    needs: [plan]
    if: github.ref == 'refs/heads/main'
    environment:
      name: production
    steps:
      - run: terraform apply -auto-approve tfplan
```

### Detecção de Drift
```bash
terraform plan -refresh-only -out=drift.out
terraform show -json drift.out | jq '.resource_changes[] | select(.change.actions != ["no-op"])'
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_workflow_has_security_scan() {
  grep -q "security-scan" .github/workflows/terraform-plan.yml && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { test_workflow_has_security_scan && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[terraform-master-agent.md]]
- [[../../pipelines/libs/github-actions-fundamentals.md]]
- [[../../pipelines/libs/security-patterns.md]]
