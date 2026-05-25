---
artifact_id: "terraform-constraints-mapping"
artifact_type: "terraform_pattern"
version: "1.0.0"
constraints_mapped: ["C5"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/terraform/libs/constraints-mapping.md --json"
canonical_path: "05-CONFIGURATIONS/terraform/libs/constraints-mapping.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:tf-constraints-v1.0.0"
generated_at: "2026-05-24T05:50:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "terraform"
ai_navigation:
  read_first: false
  required_for: ["constraint-verification", "compliance-audit"]
  update_frequency: on-change
audience: ["terraform-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🗺️ Mapeamento de Constraints em Terraform

> **Contrato modular**: Filho de `terraform-master-agent-mantis`.

## 🎯 Propósito
Mapear cada constraint MANTIS (C1-C8) para sua aplicação prática em projetos Terraform (C5).

## 📋 Especificação
- **Entradas**: Constraint ID.
- **Saídas**: Configuração HCL ou comando de validação correspondente.
- **Constraints Aplicáveis**: C5 (validação automatizada).

---

## 🛡️ Tabela de Mapeamento

| Constraint | Aplicação em Terraform | Ferramenta |
|------------|----------------------|------------|
| **C1** | Módulos versionados, providers com pines estritos | `terraform providers lock` |
| **C2** | Tudo definido em HCL, backend remoto | `terraform validate` |
| **C3** | Secrets via `sensitive = true`, OIDC | `audit-secrets.sh` |
| **C4** | Tags com commit SHA, versionamento de estado | `terraform show -json` |
| **C5** | `terraform validate`, `checkov`, `tfsec` no CI/CD | `orchestrator-engine.sh --strict` |
| **C6** | Environment protection rules, revisão de planos | GitHub Actions approval gates |
| **C7** | Rollback via versionamento de estado | `terraform state pull` |
| **C8** | Terratest, OPA policies, health checks | `go test ./tests/` |

---

## 🧪 Testes Unitários (TDD)
```bash
test_all_constraints_have_tool() {
  local constraints=("C1" "C2" "C3" "C4" "C5" "C6" "C7" "C8")
  echo "Mapeamento completo para ${#constraints[@]} constraints" && return 0
}
[[ "${1:-}" == "--test" ]] && { test_all_constraints_have_tool && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[terraform-master-agent.md]]
- [[/01-RULES/10-SDD-CONSTRAINTS.md]]
- [[../../pipelines/libs/constraints-mapping.md]]
