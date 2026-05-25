---
artifact_id: "n8n-control-flow-patterns"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/control-flow-patterns.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/control-flow-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:control-flow-v1.0.0"
generated_at: "2026-05-24T17:30:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["conditional-logic", "branching", "looping", "merging"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🔀 Padrões de Controle de Fluxo — IF, Switch, Merge, Split, Loop

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Padronizar os nós de controle de fluxo em workflows n8n: ramificação condicional (IF), roteamento multi-branch (Switch), combinação de dados (Merge), processamento em lote (SplitInBatches) e loops, garantindo validação (C5) e observabilidade (C8).

## 📋 Especificação (SDD)
- **Entradas**: Dados a serem roteados, condições de ramificação.
- **Saídas**: Dados roteados para os caminhos corretos.
- **Constraints Aplicáveis**: C5, C8.

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
control_flow:
  if_node:
    description: "Ramificação condicional baseada em regras"
    config:
      type: "n8n-nodes-base.if"
      typeVersion: 2
      parameters:
        conditions:
          options:
            caseSensitive: true
            typeValidation: "strict"
          conditions:
            - leftValue: "={{ $json.status }}"
              rightValue: "active"
              operator: { type: "string", operation: "equals" }
          combinator: "and"

  switch_node:
    description: "Roteamento multi-branch por valor de campo"
    config:
      type: "n8n-nodes-base.switch"
      parameters:
        mode: "rules"
        rules:
          values:
            - outputKey: "order"
              conditions:
                conditions:
                  - leftValue: "={{ $json.type }}"
                    rightValue: "order"
                    operator: { type: "string", operation: "equals" }
            - outputKey: "refund"
              conditions:
                conditions:
                  - leftValue: "={{ $json.type }}"
                    rightValue: "refund"
                    operator: { type: "string", operation: "equals" }
        fallbackOutput: "extra"

  split_batches:
    description: "Processamento de itens em lotes"
    config:
      type: "n8n-nodes-base.splitInBatches"
      typeVersion: 3
      parameters:
        batchSize: 10
        options:
          reset: false

  merge_node:
    description: "Combinação de dados de múltiplas branches"
    config:
      type: "n8n-nodes-base.merge"
      parameters:
        mode: "combine"
        mergeByFields:
          values:
            - field1: "id"
              field2: "userId"
        options: {}
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_if_condition_structure() {
  local json='{"conditions":{"conditions":[{"leftValue":"={{ $json.status }}","rightValue":"active","operator":{"type":"string","operation":"equals"}}],"combinator":"and"}}'
  python3 -c "
import json; d=json.loads('$json')
assert 'conditions' in d['conditions']
assert d['conditions']['combinator'] in ('and','or')
" 2>/dev/null && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && { test_if_condition_structure && echo "✅" || echo "❌"; exit $?; }
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[workflow-patterns-basic.md]]
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]]
