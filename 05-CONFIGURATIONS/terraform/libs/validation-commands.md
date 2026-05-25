---
artifact_id: "terraform-validation-commands"
artifact_type: "terraform_pattern"
version: "1.0.0"
constraints_mapped: ["C5"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/terraform/libs/validation-commands.md --json"
canonical_path: "05-CONFIGURATIONS/terraform/libs/validation-commands.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:tf-validation-v1.0.0"
generated_at: "2026-05-24T06:00:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "terraform"
ai_navigation:
  read_first: false
  required_for: ["terraform-validation", "compliance-check"]
  update_frequency: on-change
audience: ["terraform-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# ✅ Comandos de Validação do Domínio Terraform

> **Contrato modular**: Filho de `terraform-master-agent-mantis`.

## 🎯 Propósito
Catalogar todos os comandos de validação disponíveis para o domínio `terraform/`, garantindo que todo artefato gerado passe pelas verificações de integridade (C5).

## 📋 Especificação
- **Entradas**: Caminho do módulo ou arquivo a validar.
- **Saídas**: Código de saída 0 (válido) ou relatório de erros.
- **Constraints Aplicáveis**: C5 (validação automatizada).

---

## 🛡️ Comandos de Validação

### Validação de Sintaxe
```bash
terraform validate
terraform fmt -recursive -check
```

### Validação de Segurança
```bash
checkov -d terraform/ --framework terraform --compact
tfsec terraform/ --minimum-severity HIGH
```

### Validação de Políticas OPA
```bash
conftest test terraform/ --policy terraform/policies
```

### Validação de Pines de Providers
```bash
grep -r "version\s*=" terraform/versions.tf | grep -v "~>"
```

### Validação de Secrets Hardcoded
```bash
grep -r "password\s*=" terraform/ --include="*.tf" --exclude="*.tfvars"
```

### Validação MANTIS
```bash
bash orchestrator-engine.sh --domain terraform --strict
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_terraform_validate() {
  cd terraform/ && terraform init -backend=false 2>/dev/null && terraform validate && cd - && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { command -v terraform &>/dev/null && test_terraform_validate && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[terraform-master-agent.md]]
- [[../security-compliance.md]]
- [[../../docker-compose/libs/validation-scripts.md]]
