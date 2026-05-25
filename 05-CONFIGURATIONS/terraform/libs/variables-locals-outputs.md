---
artifact_id: "terraform-variables-locals-outputs"
artifact_type: "terraform_pattern"
version: "1.0.0"
constraints_mapped: ["C4","C5"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/terraform/libs/variables-locals-outputs.md --json"
canonical_path: "05-CONFIGURATIONS/terraform/libs/variables-locals-outputs.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:tf-vars-locals-outputs-v1.0.0"
generated_at: "2026-05-24T05:10:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "terraform"
ai_navigation:
  read_first: false
  required_for: ["variable-definition", "local-computation", "output-exposure"]
  update_frequency: on-change
audience: ["terraform-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 📐 Variáveis, Locals e Outputs

> **Contrato modular**: Filho de `terraform-master-agent-mantis`.

## 🎯 Propósito
Padronizar a declaração de variáveis com validação robusta, o uso de `locals` para valores computados e `outputs` com tenant isolation (C4, C5).

## 📋 Especificação
- **Entradas**: Tipo da variável (string, number, bool, object).
- **Saídas**: Blocos HCL com validação e documentação.
- **Constraints Aplicáveis**: C4 (trazabilidade), C5 (validação automatizada).

---

## 🛡️ Padrões

### Variável com Validação
```hcl
variable "environment" {
  description = "Ambiente de deploy"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Deve ser dev, staging ou prod."
  }
}
```

### Locals para Convenções
```hcl
locals {
  name_prefix = "${var.project}-${var.environment}"
  common_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
```

### Output com Tenant Isolation
```hcl
output "connection_string" {
  value     = "postgresql://...?options=-csearch_path%3Dtenant_${var.tenant_id}"
  sensitive = true
  precondition {
    condition     = can(regex("tenant_[a-z0-9]+", self.value))
    error_message = "Connection string deve incluir tenant_id (C4)"
  }
}
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_variable_validation_block() {
  local tmp; tmp=$(mktemp -d)
  cat > "$tmp/vars.tf" << 'EOF'
variable "env" {
  type    = string
  validation {
    condition     = contains(["dev","prod"], var.env)
    error_message = "Inválido"
  }
}
EOF
  terraform fmt -check "$tmp/vars.tf" 2>/dev/null && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { command -v terraform &>/dev/null && test_variable_validation_block && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[terraform-master-agent.md]]
- [[../project-structure.md]]
- [[/01-RULES/10-SDD-CONSTRAINTS.md]]
