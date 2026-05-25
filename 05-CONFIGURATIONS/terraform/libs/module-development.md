---
artifact_id: "terraform-module-development"
artifact_type: "terraform_pattern"
version: "1.0.0"
constraints_mapped: ["C1","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/terraform/libs/module-development.md --json"
canonical_path: "05-CONFIGURATIONS/terraform/libs/module-development.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:tf-module-dev-v1.0.0"
generated_at: "2026-05-24T05:15:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "terraform"
ai_navigation:
  read_first: false
  required_for: ["module-creation", "terraform-composition"]
  update_frequency: on-change
audience: ["terraform-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🧩 Desenvolvimento de Módulos Reutilizáveis

> **Contrato modular**: Filho de `terraform-master-agent-mantis`.

## 🎯 Propósito
Definir a estrutura e as práticas para criar módulos Terraform reutilizáveis, incluindo composição e testes com Terratest (C1, C5, C8).

## 📋 Especificação
- **Entradas**: Nome do módulo, recursos a serem provisionados.
- **Saídas**: Estrutura de diretórios, `main.tf`, `variables.tf`, `outputs.tf`.
- **Constraints Aplicáveis**: C1 (versionamento), C5 (validação), C8 (testes).

---

## 🛡️ Estrutura do Módulo

```
modules/vpc/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── README.md
└── tests/
    └── module_test.go
```

### Exemplo de `main.tf` com `for_each`
```hcl
resource "aws_subnet" "private" {
  for_each = {
    for idx, cidr in var.private_subnet_cidrs :
    var.availability_zones[idx] => {
      cidr = cidr
      az   = var.availability_zones[idx]
    }
  }
  vpc_id     = aws_vpc.main.id
  cidr_block = each.value.cidr
  availability_zone = each.value.az
}
```

### Teste com Terratest (Go)
```go
func TestVPCModule(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../examples/basic",
    }
    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)
    vpcID := terraform.Output(t, terraformOptions, "vpc_id")
    assert.NotEmpty(t, vpcID)
}
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_module_structure() {
  local dir="${1:-.}"
  [[ -f "$dir/main.tf" && -f "$dir/variables.tf" && -f "$dir/outputs.tf" ]] && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { test_module_structure "modules/vps-base" && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[terraform-master-agent.md]]
- [[../variables-locals-outputs.md]]
- [[/05-CONFIGURATIONS/terraform/modules/README-TEMPLATE.md]]
