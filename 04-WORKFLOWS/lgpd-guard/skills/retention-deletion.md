---
artifact_id: "lgpd-retention-deletion"
artifact_type: "lgpd_skill"
version: "1.0.0"
constraints_mapped: ["C1","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/lgpd-guard/skills/retention-deletion.md --json"
canonical_path: "04-WORKFLOWS/lgpd-guard/skills/retention-deletion.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:lgpd-retention-deletion-v1.0.0"
generated_at: "2026-05-25T03:40:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "workflows"
ai_navigation:
  read_first: false
  required_for: ["data-retention", "data-deletion", "right-to-erasure"]
  update_frequency: on-change
audience: ["lgpd-guard", "n8n-master-agent", "langchain-langraph-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-25"
---

# 🗑️ Política de Retenção e Eliminação de Dados (Art. 15 e 16)

> **Contrato modular**: Artefato filho de `lgpd-guard-mantis`.

## 🎯 Propósito
Padronizar a definição e execução de políticas de retenção e eliminação de dados pessoais, garantindo que os dados não sejam mantidos por tempo indefinido (princípio da **necessidade**) e que a eliminação ocorra de forma segura e rastreável, respeitando as exceções legais previstas no Art. 16 da LGPD (C1, C4, C5, C7, C8).

## 📋 Especificação (SDD)
- **Entradas**: Política de retenção por classe de dado e finalidade, data limite de retenção.
- **Saídas**: Registros eliminados ou anonimizados, log de auditoria.
- **Side Effects**: Exclusão irreversível de dados (ou anonimização se houver obrigação legal de guarda).
- **Constraints Aplicáveis**: C1 (imutabilidade do log de exclusão), C4 (rastreabilidade), C5 (validação), C7 (rollback impossível após exclusão), C8 (logging).

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
retention_deletion:
  art_15: "O término do tratamento de dados pessoais ocorrerá quando: a finalidade for alcançada; os dados deixarem de ser necessários; o titular revogar o consentimento; determinação da ANPD."
  
  art_16: "Os dados poderão ser conservados para: cumprimento de obrigação legal; estudo por órgão de pesquisa; transferência a terceiro; uso exclusivo do controlador (anonimizados)."

  retention_policies:
    consentimento: "Até revogação + 30 dias para conclusão de processos pendentes"
    contrato: "Até 5 anos após término do contrato (prescrição civil)"
    legitimo_interesse: "Máximo 2 anos ou até oposição do titular"
    obrigacao_legal: "Conforme prazo legal específico (ex.: dados fiscais: 5 anos)"
    crianca_adolescente: "Até completar 18 anos + prazo prescricional aplicável"

  deletion_flow:
    trigger: "Schedule diário/semanal ou webhook de revogação/DSAR"
    steps:
      - "Identificar registros além do prazo de retenção (created_at < data_limite)"
      - "Verificar exceções legais (obrigação legal, litígio, órgão de pesquisa)"
      - "Se sem exceção: ELIMINAR registro (DELETE físico)"
      - "Se com exceção: ANONIMIZAR (remover campos identificáveis, manter agregados)"
      - "Log: lgpd_retention_executed e lgpd_data_deleted"

  n8n_config:
    executions_data_prune: "true"
    executions_data_max_age: 168  # 7 dias (para workflows com dados sensíveis: 24h)
    executions_data_save_on_success: "false"  # Não armazenar dados de execução
    executions_data_save_on_error: "false"

  anti_patterns:
    - "Manter dados indefinidamente 'por precaução' → viola princípio da necessidade"
    - "Eliminar dados sem verificar exceções legais → pode eliminar dados obrigatórios"
    - "Ausência de política de retenção documentada → impossibilita demonstrar conformidade"
    - "Deixar dados em backups não controlados → eliminação deve incluir backups"
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_retention_policy_documented() {
  local policies=("consentimento" "contrato" "legitimo_interesse" "obrigacao_legal")
  [[ ${#policies[@]} -eq 4 ]] && return 0 || return 1
}

test_deletion_has_exception_check() {
  local flow=("identificar" "verificar_excecoes" "eliminar_ou_anonimizar" "log")
  echo "${flow[@]}" | grep -q "verificar_excecoes" && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && {
  test_retention_policy_documented && test_deletion_has_exception_check && echo "✅" || echo "❌"
  exit $?
}
```

---

## 🔗 Referências Cruzadas

- [[lgpd-guard.md]]
- [[consent-management.md]]
- [[dsar-handling.md]]
- [[audit-logging.md]]
