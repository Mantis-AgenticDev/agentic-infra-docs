---
artifact_id: "n8n-sub-workflows-advanced"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C2","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/sub-workflows-advanced.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/sub-workflows-advanced.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:sub-workflows-advanced-v1.0.0"
generated_at: "2026-05-24T21:40:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["sub-workflow-architecture", "reusable-functions"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🧩 Sub-Workflows Avançados — Middleware, Stateful e Search-Before-Build

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Padronizar padrões avançados de sub-workflows: middleware para APIs, stateful deliberado (repository pattern), fire-and-forget para observações assíncronas, e o protocolo search-before-build para evitar duplicação (C2, C5, C8).

## 📋 Especificação (SDD)
- **Entradas**: Necessidade de reutilização, tipo de lógica (stateless/stateful).
- **Saídas**: Sub-workflow extraído com contrato de entrada/saída documentado.
- **Constraints Aplicáveis**: C2 (declarativo), C5 (validação), C8 (logging).

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
sub_workflows_advanced:
  middleware_pattern: |
    Webhook → [Subworkflow: Verify JWT] → [Subworkflow: Rate limit]
      → IF (all ok) → Main handler → Respond 200
      → ELSE → Respond with 4xx from middleware

  stateless_vs_stateful:
    stateless: "Input → Output. Sem I/O externo. Padrão para lógica pura."
    stateful_deliberate: "Lê/escreve estado externo atrás de contrato limpo. Repository pattern."
    accidental_state: "Nomeado como puro mas escreve em log. AMBUSCA callers."

  fire_and_forget: |
    Execute Workflow com waitForSubWorkflow: false
    Caller continua imediatamente. Sub-workflow roda em background.
    Útil para audit log, métricas, notificações não-críticas.

  search_before_build:
    protocol: |
      1. search_workflows com queries relevantes
      2. Se candidatos, fetch get_workflow_details nos top 1-3
      3. Confirmar fit lendo inputs/outputs
      4. Se existe → usar. Se não → construir com prefixo.

  naming: "Prefixo verbal: Subworkflow:, Customer:, Tool:"
  inputs: "Define Below com campos tipados (workflowInputs.values)"
  outputs: "Forma natural, não forma de armazenamento. Parse _object antes de retornar."
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_sub_workflow_naming_convention() {
  local name="Subworkflow: Parse RFC2822 date"
  [[ "$name" == Subworkflow:* ]] && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && { test_sub_workflow_naming_convention && echo "✅" || echo "❌"; exit $?; }
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[sub-workflow-patterns.md]]
- [[error-handling-advanced.md]]
