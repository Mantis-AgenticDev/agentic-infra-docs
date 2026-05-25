---
artifact_id: "terraform-libs-index"
artifact_type: "index"
version: "1.0.0"
constraints_mapped: ["C5"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/terraform/libs/00-INDEX.md --json"
canonical_path: "05-CONFIGURATIONS/terraform/libs/00-INDEX.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:terraform-libs-index-v1.0.0"
generated_at: "2026-05-24T05:00:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "terraform"
ai_navigation:
  read_first: true
  required_for: ["terraform-skill-loading", "terraform-agent-modular"]
  update_frequency: on-change
audience: ["terraform-master-agent", "orchestrator-engine"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 📚 Índice de Skills — terraform/libs/

| Skill | Propósito | Constraints |
|-------|-----------|-------------|
| [[project-structure.md]] | Estrutura de diretórios, backend remoto, providers e autenticação | C1, C2, C3 |
| [[variables-locals-outputs.md]] | Variáveis com validação, locals computados, outputs com tenant isolation | C4, C5 |
| [[module-development.md]] | Desenvolvimento de módulos reutilizáveis, composição, Terratest | C1, C5, C8 |
| [[state-management.md]] | Gestão de estado: comandos, migração, recuperação, desbloqueio | C1, C7 |
| [[multi-environment-strategies.md]] | Estratégias multi‑ambiente: diretórios, workspaces, Terraform Stacks | C2, C6 |
| [[ci-cd-pipeline.md]] | Pipeline de CI/CD com GitHub Actions, detecção de drift, revisão de planos | C5, C6, C8 |
| [[security-compliance.md]] | Políticas OPA/Rego, Checkov, tfsec, Terrascan | C3, C5 |
| [[drift-detection-remediation.md]] | Detecção e remediação de drift, categorias de severidade | C7, C8 |
| [[constraints-mapping.md]] | Mapeamento de constraints C1-C8 aplicadas a Terraform | C5 |
| [[validation-commands.md]] | Catálogo de comandos de validação do domínio | C5 |
| [[troubleshooting.md]] | Diagnóstico e solução de problemas comuns com Terraform | C8 |
| [[agent-workflow.md]] | Protocolo de execução do agente terraform | C5, C8 |

> **Nota**: Skills de segurança e validação podem referenciar [[../../docker-compose/libs/security-patterns.md]] e [[../../pipelines/libs/security-patterns.md]] quando aplicável.

