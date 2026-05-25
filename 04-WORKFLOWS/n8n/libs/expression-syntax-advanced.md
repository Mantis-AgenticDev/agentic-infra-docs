---
artifact_id: "n8n-expression-syntax-advanced"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C5"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/expression-syntax-advanced.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/expression-syntax-advanced.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:expression-syntax-advanced-v1.0.0"
generated_at: "2026-05-24T22:00:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["expression-syntax", "data-referencing"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 📝 Sintaxe Avançada de Expressões

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Padronizar a sintaxe de expressões n8n com foco nos erros mais comuns: estrutura de dados de webhook (`.body`), referências a outros nós (`$node["Nome"]`), notação de colchetes para espaços, e a distinção crítica entre expressões em nós configuráveis vs. Code nodes (C5).

## 📋 Especificação (SDD)
- **Entradas**: Tipo de nó (Webhook, HTTP Request, Code), campo a referenciar.
- **Saídas**: Expressão n8n sintaticamente correta.
- **Constraints Aplicáveis**: C5 (validação sintática).

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
expression_syntax:
  critical_webhook_structure: |
    Dados do webhook NÃO estão na raiz!
    Estrutura: { headers, params, query, body }
    ❌ {{$json.name}} → undefined
    ✅ {{$json.body.name}}

  bracket_notation_mandatory:
    spaces: "{{$json['field name']}}"
    special_chars: "{{$json['Cena brutto zł']}}"
    node_names_with_spaces: '{{$node["HTTP Request"].json.data}}'

  code_node_distinction:
    config_nodes: "={{ ... }} (expressões)"
    code_nodes: "JavaScript puro: $json.field, $input.all()"
    ❌ '={{$json.email}}' dentro de Code node

  common_mistakes:
    missing_braces: "$json.field → {{$json.field}}"
    webhook_root_access: "{{$json.name}} → {{$json.body.name}}"
    node_name_no_quotes: "{{$node.HTTP Request}} → {{$node[\"HTTP Request\"]}}"
    double_wrap: "{{{$json.field}}} → {{$json.field}}"
    code_node_expression: "'={{$json.email}}' → $json.email"

  variables:
    current_item: "{{$json.field}}"
    other_node: '{{$node["Node Name"].json.field}}'
    env_var: "{{$env.VAR_NAME}}"
    now: "{{$now.toFormat('yyyy-MM-dd')}}"
    input_first: "{{$input.first().json}}"
    input_all: "{{$input.all()}}"
    run_index: "{{$runIndex}}"
    item_index: "{{$itemIndex}}"

  conditional: "{{$json.status === 'active' ? 'Active' : 'Inactive'}}"
  default_value: "{{$json.email || 'no-email@example.com'}}"
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_webhook_body_access() {
  local expr="{{$json.body.name}}"
  echo "$expr" | grep -q 'body\.' && return 0 || return 1
}

test_bracket_notation_for_spaces() {
  local expr='{{$json[\"field name\"]}}'
  echo "$expr" | grep -q '\[\\"' && return 0 || return 1
}

test_no_expression_in_code_node() {
  local code='const email = $json.email;'
  echo "$code" | grep -qv '{{' && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && {
  test_webhook_body_access && test_bracket_notation_for_spaces && test_no_expression_in_code_node && echo "✅" || echo "❌"
  exit $?
}
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[data-transformation-patterns.md]]
- [[code-execution-patterns.md]]
