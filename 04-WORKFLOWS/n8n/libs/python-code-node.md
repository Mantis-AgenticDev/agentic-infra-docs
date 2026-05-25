---
artifact_id: "n8n-python-code-node"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/python-code-node.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/python-code-node.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:python-code-node-v1.0.0"
generated_at: "2026-05-24T22:30:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["python-code", "python-transformations"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🐍 Python Code Node (Beta) — Guia Completo

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Padronizar o uso do nó Code em Python no n8n, cobrindo modos de execução (All Items vs Each Item), acesso a dados (`_input.all()`, `_input.first()`, `_input.item`), formato de retorno obrigatório, limitações de bibliotecas externas e antipadrões comuns (C5, C8).

## 📋 Especificação (SDD)
- **Entradas**: Dados de nós anteriores, modo de execução selecionado.
- **Saídas**: Array de objetos `[{json: {...}}]` processados.
- **Constraints Aplicáveis**: C5 (validação de código), C8 (logging de erros).
- **Dependências**: n8n com Python Code node habilitado (beta).

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
python_code_node:
  recommendation: "Usar JavaScript para 95% dos casos. Python apenas para bibliotecas padrão específicas."
  
  modes:
    run_once_all_items:
      description: "Código executa UMA vez independente do número de itens. Recomendado."
      data_access: "_input.all()"
      best_for: ["Agregação", "Filtragem", "Processamento em lote", "Transformações"]
    run_once_each_item:
      description: "Código executa SEPARADAMENTE para cada item. Casos especializados."
      data_access: "_input.item"
      best_for: ["Lógica item-específica", "Operações independentes", "Validação por item"]

  python_beta_vs_native:
    beta:
      helpers: ["_input", "_json", "_node", "_now", "_today", "_jmespath()"]
      import: "from datetime import datetime"
      recommended: true
    native:
      helpers: []  # Sem _input, _now, etc.
      variables: ["_items", "_item"]
      use_when: "Python puro sem helpers n8n"

  critical_webhook_structure: |
    Dados de webhook estão sob _json["body"], NÃO na raiz.
    ❌ name = _json["name"]
    ✅ name = _json["body"]["name"]
    ✅ name = _json.get("body", {}).get("name")

  return_format_mandatory: |
    SEMPRE retornar lista de dicionários com chave "json".
    ✅ return [{"json": {"field": value}}]
    ✅ return [{"json": item["json"]} for item in _input.all()]
    ❌ return {"json": {"field": value}}  # dict sem lista
    ❌ return [{"field": value}]  # sem chave json

  standard_library_only:
    available: ["json", "datetime", "re", "base64", "hashlib", "urllib.parse", "math", "random", "statistics"]
    not_available: ["requests", "pandas", "numpy", "scipy", "BeautifulSoup"]
    workaround_http: "Usar nó HTTP Request antes do Code node"
    workaround_data_analysis: "Usar statistics ou JavaScript"

  common_patterns:
    aggregation: |
      all_items = _input.all()
      total = sum(item["json"].get("amount", 0) for item in all_items)
      return [{"json": {"total": total, "count": len(all_items)}}]
    filtering: |
      items = _input.all()
      valid = [item for item in items if item["json"].get("amount", 0) > 0]
      return [{"json": item["json"]} for item in valid]
    regex_extraction: |
      import re
      emails = []
      for item in _input.all():
          text = item["json"].get("text", "")
          emails.extend(re.findall(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}', text))
      return [{"json": {"emails": list(set(emails)), "count": len(set(emails))}}]
    statistics: |
      from statistics import mean, median, stdev
      values = [item["json"].get("value", 0) for item in _input.all()]
      if values:
          return [{"json": {"mean": mean(values), "median": median(values), "stdev": stdev(values) if len(values) > 1 else 0}}]

  anti_patterns:
    - "import requests → ModuleNotFoundError. Usar HTTP Request node."
    - "Sem return → workflow falha silenciosamente."
    - "return dict em vez de lista → próximo nó quebra."
    - "Acesso direto _json['campo'] sem .get() → KeyError."
    - "Acessar webhook na raiz (_json['email']) em vez de _json['body']['email']."
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_python_return_format() {
  python3 -c "
result = [{'json': {'id': 1}}]
assert isinstance(result, list) and 'json' in result[0]
print('OK')
" 2>/dev/null && return 0 || return 1
}

test_python_no_external_imports() {
  python3 -c "
try:
    import requests
    print('FAIL')
except ModuleNotFoundError:
    print('OK')
" 2>/dev/null && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && {
  test_python_return_format && test_python_no_external_imports && echo "✅" || echo "❌"
  exit $?
}
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[code-execution-patterns.md]]
- [[javascript-code-node.md]]
- [[expression-syntax-advanced.md]]
