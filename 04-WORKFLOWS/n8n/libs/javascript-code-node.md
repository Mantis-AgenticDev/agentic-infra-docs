---
artifact_id: "n8n-javascript-code-node"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/javascript-code-node.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/javascript-code-node.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:javascript-code-node-v1.0.0"
generated_at: "2026-05-24T22:40:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["javascript-code", "production-patterns"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 💻 JavaScript Code Node — Guia de Produção

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Padronizar o uso avançado do nó Code JavaScript no n8n, com foco em padrões de produção: acumulação entre iterações com SplitInBatches, correção de pairedItem, referências estáveis a nós, e prevenção de erros sutis que só aparecem em produção (C5, C7, C8).

## 📋 Especificação (SDD)
- **Entradas**: Dados de nós anteriores, modo de execução.
- **Saídas**: Array `[{json: {...}}]` processado.
- **Constraints Aplicáveis**: C5 (validação), C7 (resiliência), C8 (logging).

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
javascript_code_node:
  modes:
    all_items: "Recomendado para 95% dos casos. $input.all()."
    each_item: "Casos especializados. $input.item."

  production_gotchas:
    split_in_batches_loop_semantics: |
      main[0] = done (dispara UMA vez após todos os lotes)
      main[1] = each batch (corpo do loop)
      Sempre adicionar Limit 1 após done.
    
    cross_iteration_accumulation: |
      $('Node Inside Loop').all() retorna APENAS itens da ÚLTIMA iteração.
      Fix: usar $getWorkflowStaticData('global') para acumular.
      ANTES do loop: staticData.results = []; return $input.all();
      DENTRO do loop: staticData.results.push(processed);
      DEPOIS do loop: ler staticData.results.

    paired_item_for_new_outputs: |
      Quando criar novos itens que não mapeiam 1:1 com entrada,
      incluir pairedItem: { item: i } para evitar erro paired_item_no_info.

    correct_node_reference: |
      ❌ $('HTTP Request').json
      ✅ $('HTTP Request').first().json
      ✅ $('HTTP Request').all()

    float_precision_comparison: |
      ❌ if (newPrice !== oldPrice)
      ✅ if (Math.round(newPrice * 100) !== Math.round(oldPrice * 100))

  best_practices:
    - "Validar input: if (!items || items.length === 0) return [];"
    - "Try-catch para chamadas HTTP com $helpers.httpRequest()"
    - "Preferir map/filter sobre loops manuais"
    - "Filtrar cedo, processar tarde"
    - "Nomes descritivos de variáveis"
    - "Debug com console.log() (aparece no console do navegador)"

  builtins:
    http_request: "$helpers.httpRequest({method, url, headers}) — sem auth"
    datetime_luxon: "DateTime.now(), .toFormat(), .plus(), .minus()"
    jmespath: "$jmespath(data, 'users[*].name')"
    not_available: ["$helpers.httpRequestWithAuthentication", "$env (quando N8N_BLOCK_ENV_ACCESS_IN_NODE=true)", "require()"]

  anti_patterns:
    - "Código vazio ou sem return → workflow falha"
    - "Usar sintaxe de expressão ({{ }}) dentro de Code node"
    - "return objeto em vez de array"
    - "Acesso sem optional chaining (?. ) → crash"
    - "Acessar webhook sem .body"
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_javascript_paired_item() {
  node -e "
const result = [{json: {id: 1}, pairedItem: {item: 0}}];
console.assert(result[0].pairedItem.item === 0, 'Must have pairedItem');
console.log('OK');
" 2>/dev/null && return 0 || return 1
}

test_javascript_node_reference() {
  node -e "
const data = {first: () => ({json: {id: 1}}), all: () => []};
console.assert(data.first().json.id === 1, 'Must use .first()');
console.log('OK');
" 2>/dev/null && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && {
  test_javascript_paired_item && test_javascript_node_reference && echo "✅" || echo "❌"
  exit $?
}
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[code-execution-patterns.md]]
- [[python-code-node.md]]
- [[loop-patterns.md]]
