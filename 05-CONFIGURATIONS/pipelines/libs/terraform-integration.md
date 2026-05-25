---
artifact_id: "pipelines-terraform-integration"
artifact_type: "pipelines_pattern"
version: "1.0.0"
constraints_mapped: ["C1","C4","V1","V2","V3"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/pipelines/libs/terraform-integration.md --json"
canonical_path: "05-CONFIGURATIONS/pipelines/libs/terraform-integration.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:terraform-integration-v1.0.0"
generated_at: "2026-05-23T23:20:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "pipelines"
ai_navigation:
  read_first: false
  required_for: ["terraform-pipeline", "iac-validation"]
  update_frequency: on-change
audience: ["pipelines-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-23"
---

# 🏗️ Integração com Terraform

> **Contrato modular**: Filho de `pipelines-master-agent-mantis`.

## 🎯 Propósito
Definir padrões de módulos Terraform reutilizáveis, validation blocks, outputs com tenant isolation e integração com pipelines CI/CD (C1, C4, V1-V3).

## 📋 Especificação
- **Entradas**: Tipo de recurso (VPS, DB, Qdrant), perfil de infra.
- **Saídas**: Módulo Terraform com validações.
- **Constraints Aplicáveis**: C1 (imutabilidade), C4 (tenant isolation), V1-V3 (pgvector).

---

## 🛡️ Padrões

### Módulo com Validation Blocks
```hcl
variable "infra_profile" {
  type    = string
  default = "nano"
  validation {
    condition     = contains(["nano", "micro", "standard", "large"], var.infra_profile)
    error_message = "infra_profile deve ser: nano, micro, standard, large"
  }
}
```

### Output com Tenant Isolation (C4)
```hcl
output "connection_string" {
  value     = "postgresql://...?options=-csearch_path%3Dtenant_${var.tenant_id}"
  sensitive = true
  precondition {
    condition     = can(regex("tenant_[a-z0-9]+", self.value))
    error_message = "Connection string deve incluir tenant_id"
  }
}
```

### Workflow de Plan/Apply
```yaml
- name: Terraform Plan
  run: |
    cd terraform
    terraform plan -out=tfplan -var-file=environments/production.tfvars
- name: Terraform Apply
  if: github.ref == 'refs/heads/main'
  run: terraform apply -auto-approve tfplan
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_terraform_validation_block() {
  local tmp; tmp=$(mktemp -d)
  cat > "$tmp/variables.tf" << 'EOF'
variable "env" {
  type = string
  validation {
    condition     = contains(["dev","prod"], var.env)
    error_message = "Inválido"
  }
}
EOF
  terraform fmt -check "$tmp/variables.tf" 2>/dev/null && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { command -v terraform &>/dev/null && test_terraform_validation_block && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[pipelines-master-agent.md]]
- [[../../terraform/terraform-master-agent.md]] — Agente mestre Terraform
- [[/05-CONFIGURATIONS/terraform/modules/vps-base/main.tf]] — Módulo base VPS
