---
artifact_id: "n8n-data-transformation-patterns"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/data-transformation-patterns.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/data-transformation-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:data-transformation-v1.0.0"
generated_at: "2026-05-24T17:20:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["data-transformation", "set-node", "code-node"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🔄 Padrões de Transformação de Dados — Set Node e Code

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Padronizar a transformação de dados em workflows n8n usando os nós Set e Code (JavaScript/Python), incluindo atribuição de campos, cálculos e formatação, garantindo validação (C5) e observabilidade (C8).

## 📋 Especificação (SDD)
- **Entradas**: Dados de nós anteriores, regras de transformação.
- **Saídas**: Dados transformados no formato canônico `[{ json: {...} }]`.
- **Constraints Aplicáveis**: C5, C8.

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
data_transformation:
  set_node:
    description: "Atribuição declarativa de campos"
    config:
      type: "n8n-nodes-base.set"
      parameters:
        mode: "manual"
        duplicateItem: false
        assignments:
          assignments:
            - name: "fullName"
              value: "={{ $json.firstName }} {{ $json.lastName }}"
              type: "string"
            - name: "timestamp"
              value: "={{ DateTime.now().toISO() }}"
              type: "string"

  code_node_javascript:
    description: "Transformação com JavaScript (Node.js)"
    basic_structure: |
      const results = [];
      for (const item of $input.all()) {
        const data = item.json;
        results.push({
          json: {
            id: data.id,
            processed: true,
            score: calculateScore(data),
            timestamp: new Date().toISOString()
          }
        });
      }
      return results;

  code_node_python:
    description: "Transformação com Python"
    basic_structure: |
      import json
      from datetime import datetime
      results = []
      for item in _input.all():
          data = item.json
          results.append({
              "json": {
                  "id": data.get("id"),
                  "processed": True,
                  "timestamp": datetime.now().isoformat()
              }
          })
      return results

  expression_cheat_sheet:
    current_field: "{{ $json.field }}"
    nested_field: "{{ $json[\"field-name\"] }}"
    node_output: "{{ $('NodeName').item.json.field }}"
    first_item: "{{ $input.first().json }}"
    all_items: "{{ $input.all() }}"
    env_var: "{{ $env.VAR_NAME }}"
    current_datetime: "{{ $now }}"
    current_date: "{{ $today }}"
    run_index: "{{ $runIndex }}"
    item_index: "{{ $itemIndex }}"

  luxon_datetime_examples:
    iso_format: "{{ $now.toISO() }}"
    custom_format: "{{ $now.toFormat('yyyy-MM-dd') }}"
    add_days: "{{ $now.plus({ days: 7 }).toISO() }}"
    start_of_month: "{{ $now.startOf('month').toISO() }}"
    parse_iso: "{{ DateTime.fromISO($json.date) }}"
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_set_node_expression() {
  local expr="{{ $json.firstName }} {{ $json.lastName }}"
  echo "$expr" | grep -q '\$json' && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && { test_set_node_expression && echo "✅" || echo "❌"; exit $?; }
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[code-execution-patterns.md]]
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]]
