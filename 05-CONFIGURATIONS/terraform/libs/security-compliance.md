---
artifact_id: "terraform-security-compliance"
artifact_type: "terraform_pattern"
version: "1.0.0"
constraints_mapped: ["C3","C5"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/terraform/libs/security-compliance.md --json"
canonical_path: "05-CONFIGURATIONS/terraform/libs/security-compliance.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:tf-security-compliance-v1.0.0"
generated_at: "2026-05-24T05:40:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "terraform"
ai_navigation:
  read_first: false
  required_for: ["policy-as-code", "security-scanning"]
  update_frequency: on-change
audience: ["terraform-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🔐 Segurança e Compliance em IaC

> **Contrato modular**: Filho de `terraform-master-agent-mantis`. Complementa [[../../docker-compose/libs/references/security-checklist.md]].

## 🎯 Propósito
Aplicar políticas de segurança como código (OPA/Rego), escaneamento com Checkov/tfsec/Terrascan e validação de conformidade CIS/NIST (C3, C5).

## 📋 Especificação
- **Entradas**: Caminho dos arquivos Terraform.
- **Saídas**: Relatórios de segurança, políticas Rego.
- **Constraints Aplicáveis**: C3 (secrets, cifrado), C5 (validação automatizada).

---

## 🛡️ Ferramentas e Políticas

### Checkov
```bash
checkov -d terraform/ --framework terraform --check CKV_AWS_*
```

### tfsec
```bash
tfsec terraform/ --minimum-severity HIGH
```

### Política OPA/Rego (exemplo)
```rego
deny[msg] {
  resource := input.resource.aws_s3_bucket[name]
  not resource.server_side_encryption_configuration
  msg := sprintf("S3 bucket '%s' must have encryption enabled", [name])
}
```

### Princípios de Segurança
| Princípio | Implementação |
|-----------|---------------|
| Secrets nunca em texto plano | `sensitive = true`, OIDC |
| Cifrado do estado | S3 + KMS |
| Mínimo privilégio | IAM roles granulares |
| Auditoria contínua | Checkov no CI/CD |

---

## 🧪 Testes Unitários (TDD)
```bash
test_opa_policy_exists() {
  [[ -f terraform/policies/aws_s3_encryption.rego ]] && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { test_opa_policy_exists && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[terraform-master-agent.md]]
- [[../../docker-compose/libs/references/security-checklist.md]]
- [[../../pipelines/libs/security-patterns.md]]
