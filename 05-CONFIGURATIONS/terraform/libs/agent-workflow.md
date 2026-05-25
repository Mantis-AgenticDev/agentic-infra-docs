---
artifact_id: "terraform-agent-workflow"
artifact_type: "terraform_pattern"
version: "1.0.0"
constraints_mapped: ["C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/terraform/libs/agent-workflow.md --json"
canonical_path: "05-CONFIGURATIONS/terraform/libs/agent-workflow.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:tf-agent-workflow-v1.0.0"
generated_at: "2026-05-24T06:10:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "terraform"
ai_navigation:
  read_first: false
  required_for: ["terraform-agent-execution", "terraform-protocol"]
  update_frequency: on-change
audience: ["terraform-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🤖 Protocolo de Execução do Agente Terraform

> **Contrato modular**: Filho de `terraform-master-agent-mantis`.

## 🎯 Propósito
Documentar o protocolo de execução do terraform-master-agent, incluindo modos de operação, estilo de trabalho, anti-padrões e checklist de geração (C5, C8).

## 📋 Especificação
- **Entradas**: Tarefa solicitada.
- **Saídas**: Artefato HCL com frontmatter válido.
- **Constraints Aplicáveis**: C5 (validação), C8 (qualidade).

---

## 🛡️ Protocolo

### Modos de Operação
- **Modo A (análise)**: propor, não gerar
- **Modo B (geração)**: gerar com constraints

### Consulta de Contexto
1. Ler `00-STACK-SELECTOR.md` para perfil de infra
2. Validar que a rota destino existe
3. Confirmar `constraints_mapped` ⊆ constraints permitidas

### Aplicar Constraints ANTES de Gerar
- C1: Módulos versionados, providers com pines estritos
- C2: Todo em HCL, backend remoto obrigatório
- C3: Secrets como `sensitive = true`, OIDC
- C4: Tags com commit SHA, versionamento de estado
- C5: `terraform validate`, `checkov`, `tfsec`
- C6: Approval gates humanos para prod
- C7: Versionamento de estado para rollback
- C8: Terratest, OPA policies, health checks

### Anti-Padrões (NUNCA)
- ❌ Gerar HCL sem validar constraints primeiro
- ❌ Hardcodear valores de infra
- ❌ Commitar `.tfvars` com secrets
- ❌ Usar `:latest` em providers ou módulos
- ❌ Modificar estado manualmente sem backup

### Checklist de Geração
1. ✅ Frontmatter YAML válido (C5)
2. ✅ `terraform validate` passa
3. ✅ `terraform fmt -check` passa
4. ✅ `checkov` sem CRITICAL
5. ✅ Secrets com `sensitive = true` (C3)
6. ✅ Backend remoto configurado (C2)
7. ✅ `orchestrator-engine --json` retorna `passed: true`
8. ✅ Contexto A2A inicializado (C9)

---

## 🧪 Testes Unitários (TDD)
```bash
test_anti_pattern_no_hardcoded_secrets() {
  grep -r "password\s*=" terraform/ --include="*.tf" --exclude="*.tfvars" && return 1 || return 0
}
[[ "${1:-}" == "--test" ]] && { test_anti_pattern_no_hardcoded_secrets && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[terraform-master-agent.md]]
- [[../constraints-mapping.md]]
- [[../../pipelines/libs/best-practices-anti-patterns.md]]
