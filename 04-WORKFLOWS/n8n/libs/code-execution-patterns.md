---
artifact_id: "n8n-code-execution-patterns"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/code-execution-patterns.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/code-execution-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:code-execution-v1.0.0"
generated_at: "2026-05-24T15:40:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["javascript-code", "python-code", "data-transformation"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 💻 Execução de Código em Workflows — JavaScript e Python

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Padronizar o uso dos nós Code (JavaScript e Python) em workflows n8n, incluindo padrões de transformação de dados, chamadas a APIs, tratamento de erros e boas práticas de qualidade (C5, C8).

## 📋 Especificação (SDD)
- **Entradas**: Dados de nós anteriores, lógica de processamento.
- **Saídas**: Dados transformados no formato `[{ json: {...} }]`.
- **Constraints Aplicáveis**: C5 (validação de código), C8 (logging e tratamento de erros).

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
code_execution:
  javascript:
    available_apis: ["Node.js built-ins", "Lodash", "Luxon", "n8n helpers ($input, $json)"]
    
    basic_structure: |
      const items = $input.all();
      const processedItems = items.map(item => {
        const inputData = item.json;
        return {
          json: {
            processed: inputData.field.toUpperCase(),
            timestamp: new Date().toISOString()
          }
        };
      });
      return processedItems;

    patterns:
      filtering: |
        const items = $input.all();
        return items.filter(item => item.json.status === 'active');

      aggregation: |
        const items = $input.all();
        const grouped = _.groupBy(items, item => item.json.category);
        return [{ json: { summary: Object.keys(grouped).map(c => ({ category: c, count: grouped[c].length })) } }];

      api_calls_async: |
        const items = $input.all();
        const results = [];
        for (const item of items) {
          const response = await fetch(`https://api.example.com/data/${item.json.id}`);
          const data = await response.json();
          results.push({ json: { original: item.json, enriched: data } });
        }
        return results;

      error_handling: |
        const items = $input.all();
        return items.map(item => {
          try {
            const result = JSON.parse(item.json.data);
            return { json: { parsed: result } };
          } catch (error) {
            return { json: { error: error.message, original: item.json.data } };
          }
        });

  python:
    available_libraries: ["json", "datetime", "re", "requests", "NumPy", "Pandas (se instalado)"]
    
    basic_structure: |
      items = _input.all()
      processed_items = []
      for item in items:
          input_data = item['json']
          processed_items.append({
              'json': {
                  'processed': input_data['field'].upper(),
                  'timestamp': datetime.now().isoformat()
              }
          })
      return processed_items

  complexity_rating:
    simple: 1  # map/filter simples
    api_with_error: 2  # chamadas API com tratamento
    multi_step_async: 3  # operações assíncronas multi-passo
    complex_algorithms: 4  # algoritmos com bibliotecas externas
    performance_critical: 5  # considerar custom node
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_code_node_output_format() {
  local js_code='const items = [{json: {field: "test"}}]; return items.map(i => ({json: {processed: i.json.field.toUpperCase()}}));'
  node -e "
const fn = new Function('$input', 'return (' + \`$js_code\` + ')');
const result = fn({all: () => [{json: {field: 'test'}}]});
console.assert(Array.isArray(result), 'Must return array');
console.assert(result[0].json.processed === 'TEST', 'Must process data');
" 2>/dev/null && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && { test_code_node_output_format && echo "✅" || echo "❌"; exit $?; }
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[workflow-structure-fundamentals.md]]
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]]
