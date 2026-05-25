---
artifact_id: "n8n-debugging-patterns"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/debugging-patterns.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/debugging-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:debugging-patterns-v1.0.0"
generated_at: "2026-05-24T21:50:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["workflow-debugging", "failure-diagnosis"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🐞 Diagnóstico Sistemático de Falhas

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Padronizar o diagnóstico de falhas em workflows n8n, seguindo uma ordem de verificações baratas para caras: parâmetros, assumptions, paths, upstream data stripping, item context loss, drift e bugs genuínos (C5, C8).

## 📋 Especificação (SDD)
- **Entradas**: Sintoma reportado, workflow ID, execution ID.
- **Saídas**: Causa raiz identificada e correção aplicada.
- **Constraints Aplicáveis**: C5 (validação), C8 (logging de diagnóstico).

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
debugging:
  non_negotiable: "Acreditar no usuário. 'Não está funcionando' significa algo não está como esperado."

  cheap_checks_ordered:
    parameter_misconfig: "Re-fetch via get_node_types, comparar com get_workflow_details"
    stale_assumptions: "Perguntar versão do n8n e quando atualizou o plugin de skills"
    paths_misconfigured: "Inspecionar connections object, verificar output index e merge input"
    upstream_data_stripped: "Rastrear referências $json.x até a fonte. Checar nós que substituem json."
    item_context_lost: "Checar downstream de Aggregate/Execute Once/Split Out para referências .item"
    logical_errors: "Trace data via get_execution passo a passo"
    drift: "Versão do n8n + versão do plugin de skills"
    genuine_bug: "Ler fonte do n8n, GitHub issues, workaround"

  step_by_step:
    confirm_symptom: "O que esperava? O que aconteceu? Mensagem de erro? Quando funcionou pela última vez?"
    check_execution: "get_execution: qual nó falhou? input? mensagem de erro?"
    refetch_workflow: "get_workflow_details: confirmar estado atual"
    refetch_node_types: "get_node_types: comparar shape de parâmetros"
    test_with_pinned: "prepare_test_pin_data + test_workflow: isolar 'workflow quebrado?' de 'input estranho?'"
    read_source: "github.com/n8n-io/n8n: código é a verdade"
    suspect_drift: "Versão da instância + versão do plugin"
    report_or_workaround: "community.n8n.io, GitHub issues, workaround documentado"
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_diagnosis_order() {
  local steps=("confirm_symptom" "check_execution" "refetch_workflow" "refetch_node_types" "test_with_pinned" "read_source" "suspect_drift" "report_or_workaround")
  [[ "${steps[0]}" == "confirm_symptom" && "${steps[7]}" == "report_or_workaround" ]] && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && { test_diagnosis_order && echo "✅" || echo "❌"; exit $?; }
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[error-handling-advanced.md]]
- [[workflow-testing-fundamentals.md]]
- [[connections-patterns.md]]
