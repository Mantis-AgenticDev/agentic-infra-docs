---
artifact_id: "terraform-project-structure"
artifact_type: "terraform_pattern"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/terraform/libs/project-structure.md --json"
canonical_path: "05-CONFIGURATIONS/terraform/libs/project-structure.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:tf-project-structure-v1.0.0"
generated_at: "2026-05-24T05:05:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "terraform"
ai_navigation:
  read_first: false
  required_for: ["terraform-project-setup", "backend-configuration"]
  update_frequency: on-change
audience: ["terraform-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 📁 Estrutura de Projeto e Configuração do Backend

> **Contrato modular**: Artefato filho de `terraform-master-agent-mantis`.

## 🎯 Propósito
Definir a estrutura canônica de diretórios, a configuração do backend remoto (S3 + DynamoDB) e os providers com autenticação OIDC para projetos Terraform MANTIS (C1, C2, C3).

## 📋 Especificação
- **Entradas**: Provedor cloud, região, configuração de bucket.
- **Saídas**: Estrutura de diretórios, `backend.tf`, `providers.tf`, `versions.tf`.
- **Constraints Aplicáveis**: C1 (imutabilidade), C2 (IaC), C3 (segurança).

---

## 🛡️ Estrutura Recomendada

```
terraform/
├── backend.tf            # Configuração do backend remoto
├── versions.tf           # Pines de providers e Terraform
├── providers.tf          # Configuração dos providers com OIDC
├── variables.tf          # Variáveis globais com validação
├── outputs.tf            # Saídas principais
├── modules/              # Módulos reutilizáveis
│   └── vpc/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
├── envs/                 # Raízes por ambiente (dev, staging, prod)
│   ├── dev/
│   │   ├── main.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   ├── staging/
│   └── prod/
└── policies/             # Políticas OPA/Rego
```

### Backend S3 + DynamoDB
```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "mantis-terraform-state"
    key            = "envs/${terraform.workspace}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    kms_key_id     = "alias/terraform-state-key"
    dynamodb_table = "terraform-state-lock"
  }
}
```

### Providers com OIDC
```hcl
provider "aws" {
  region = var.aws_region
  assume_role_with_web_identity {
    role_arn           = var.terraform_role_arn
    web_identity_token = var.identity_token
  }
}
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_terraform_backend_syntax() {
  local tmp; tmp=$(mktemp -d)
  cat > "$tmp/backend.tf" << 'EOF'
terraform { backend "s3" { bucket = "test" key = "state" region = "us-east-1" } }
EOF
  cd "$tmp" && terraform init -backend=false 2>/dev/null && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { command -v terraform &>/dev/null && test_terraform_backend_syntax && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[terraform-master-agent.md]]
- [[../../docker-compose/libs/security-patterns.md]] — Práticas de segurança complementares
- [[../../pipelines/libs/security-patterns.md]] — OIDC em pipelines
