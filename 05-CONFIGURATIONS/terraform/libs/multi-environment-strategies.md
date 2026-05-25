---
artifact_id: "terraform-multi-environment-strategies"
artifact_type: "terraform_pattern"
version: "1.0.0"
constraints_mapped: ["C2","C6"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/terraform/libs/multi-environment-strategies.md --json"
canonical_path: "05-CONFIGURATIONS/terraform/libs/multi-environment-strategies.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:tf-multi-env-v1.0.0"
generated_at: "2026-05-24T05:30:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "terraform"
ai_navigation:
  read_first: false
  required_for: ["multi-environment-setup", "workspace-management"]
  update_frequency: on-change
audience: ["terraform-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🌍 Estratégias Multi‑Ambiente

> **Contrato modular**: Filho de `terraform-master-agent-mantis`.

## 🎯 Propósito
Padronizar a separação de ambientes (dev, staging, prod) usando diretórios isolados, workspaces do Terraform e Terraform Stacks (v1.13+), garantindo isolamento de estado e aprovação de mudanças (C2, C6).

## 📋 Especificação
- **Entradas**: Nome do ambiente, perfil de infra.
- **Saídas**: Estrutura de diretórios `envs/` ou configuração de workspaces.
- **Constraints Aplicáveis**: C2 (IaC declarativo), C6 (aprovação de mudanças críticas).

---

## 🛡️ Estratégias

### Separação por Diretórios (recomendado para prod)
```
envs/
├── dev/
│   ├── main.tf
│   ├── terraform.tfvars
│   └── backend.tf        # key: envs/dev/terraform.tfstate
├── staging/
└── prod/
```

### Workspaces (para ambientes efêmeros)
```bash
terraform workspace new feature-auth
terraform workspace select feature-auth
```

### Terraform Stacks (v1.13+)
```hcl
# deployments.tfdeploy.hcl
deployment "production" {
  inputs = {
    aws_region    = "us-east-1"
    name_prefix   = "mantis-prod"
    instance_type = "t3.large"
  }
}
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_env_directory_structure() {
  local env="${1:-dev}"
  [[ -d "envs/$env" && -f "envs/$env/main.tf" ]] && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { test_env_directory_structure "dev" && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[terraform-master-agent.md]]
- [[../project-structure.md]]
- [[../../pipelines/libs/deployment-design.md]] — Gates de aprovação
