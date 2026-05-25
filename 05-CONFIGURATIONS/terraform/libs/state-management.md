---
artifact_id: "terraform-state-management"
artifact_type: "terraform_pattern"
version: "1.0.0"
constraints_mapped: ["C1","C7"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/terraform/libs/state-management.md --json"
canonical_path: "05-CONFIGURATIONS/terraform/libs/state-management.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:tf-state-mgmt-v1.0.0"
generated_at: "2026-05-24T05:20:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "terraform"
ai_navigation:
  read_first: false
  required_for: ["state-operations", "state-recovery"]
  update_frequency: on-change
audience: ["terraform-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🗃️ Gestão de Estado

> **Contrato modular**: Filho de `terraform-master-agent-mantis`.

## 🎯 Propósito
Documentar os comandos essenciais de gestão de estado, migração de backend, recuperação contra corrupção e desbloqueio forçado (C1, C7).

## 📋 Especificação
- **Entradas**: Caminho do estado, tipo de operação.
- **Saídas**: Comandos `terraform state *` com explicações.
- **Constraints Aplicáveis**: C1 (imutabilidade do estado), C7 (rollback).

---

## 🛡️ Comandos Essenciais

### Listar e Inspecionar
```bash
terraform state list
terraform state show aws_instance.web
terraform show -json | jq '.values.root_module.resources'
```

### Migração de Backend
```bash
terraform init -migrate-state
```

### Recuperação de Estado
```bash
terraform state pull > backup-$(date +%Y%m%d%H%M%S).tfstate
# ... selecionar versão do S3 e fazer push
terraform state push recovered.tfstate
```

### Desbloqueio Forçado
```bash
terraform force-unlock <LOCK_ID>
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_state_commands_exist() {
  terraform state list --help &>/dev/null && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { command -v terraform &>/dev/null && test_state_commands_exist && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[terraform-master-agent.md]]
- [[../project-structure.md]] — Configuração do backend
- [[../../pipelines/libs/terraform-integration.md]] — Integração com pipelines
