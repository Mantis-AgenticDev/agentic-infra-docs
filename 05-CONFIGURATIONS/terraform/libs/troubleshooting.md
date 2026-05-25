---
artifact_id: "terraform-troubleshooting"
artifact_type: "terraform_pattern"
version: "1.0.0"
constraints_mapped: ["C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/terraform/libs/troubleshooting.md --json"
canonical_path: "05-CONFIGURATIONS/terraform/libs/troubleshooting.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:tf-troubleshooting-v1.0.0"
generated_at: "2026-05-24T06:05:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "terraform"
ai_navigation:
  read_first: false
  required_for: ["terraform-debugging", "failure-diagnosis"]
  update_frequency: on-change
audience: ["terraform-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🐞 Troubleshooting de Terraform

> **Contrato modular**: Filho de `terraform-master-agent-mantis`. Complementa [[../../docker-compose/libs/troubleshooting.md]] e [[../../pipelines/libs/troubleshooting.md]].

## 🎯 Propósito
Diagnosticar e resolver falhas comuns em projetos Terraform (C8).

## 📋 Especificação
- **Entradas**: Sintoma da falha.
- **Saídas**: Comando de diagnóstico + solução.
- **Constraints Aplicáveis**: C8.

---

## 🛡️ Problemas Comuns

| Sintoma | Causa | Diagnóstico | Solução |
|---------|-------|-------------|---------|
| `terraform init` falha | Backend inacessível | `aws s3 ls s3://bucket` | Verificar credenciais, rede |
| `terraform plan` mostra drift inesperado | Mudança manual na console | `terraform plan -refresh-only` | Avaliar e corrigir HCL |
| `terraform apply` timeout | Estado bloqueado | `terraform force-unlock` | Verificar locks no DynamoDB |
| `Provider produced inconsistent result` | Bug do provider | `terraform providers lock` | Atualizar versão do provider |
| `Resource not found` no apply | Recurso deletado manualmente | `terraform refresh` | Reimportar recurso |
| `Invalid count argument` | `count` ou `for_each` com valor inválido | `terraform console` | Verificar variáveis de entrada |
| `Error acquiring state lock` | Lock não liberado | `aws dynamodb scan --table-name terraform-state-lock` | `terraform force-unlock` |
| `Plan shows destroy/create` | `for_each` com chaves instáveis | `terraform show -json` | Usar chaves estáveis |

---

## 🧪 Testes Unitários (TDD)
```bash
test_troubleshooting_table_complete() {
  grep -q "terraform init.*falha" "$0" && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { test_troubleshooting_table_complete && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[terraform-master-agent.md]]
- [[../state-management.md]]
- [[../../docker-compose/libs/troubleshooting.md]]
