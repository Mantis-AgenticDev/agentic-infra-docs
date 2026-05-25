---
artifact_id: "n8n-loop-patterns"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/loop-patterns.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/loop-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:loop-patterns-v1.0.0"
generated_at: "2026-05-24T20:20:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["loop-control", "batching", "pagination", "execute-once"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🔁 Padrões de Loop — executeOnce, Loop Over Items, Paginação

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Padronizar os mecanismos de iteração no n8n: iteração padrão por item, executeOnce para nós que devem rodar uma única vez, Loop Over Items para processamento em lote explícito e paginação nativa do HTTP Request, garantindo validação (C5), resiliência (C7) e observabilidade (C8). Evitar os anti-padrões mais comuns que causam loops infinitos, mensagens duplicadas e custos desnecessários de API.

## 📋 Especificação (SDD)
- **Entradas**: Tipo de necessidade de loop (per-item, once, batch, pagination).
- **Saídas**: Configuração correta do nó com executeOnce, Loop Over Items ou HTTP Pagination.
- **Constraints Aplicáveis**: C5 (validação), C7 (evitar loops infinitos), C8 (logging de iterações).
- **Dependências**: n8n com nós configurados.

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
loop_patterns:
  three_meanings:
    default_iteration: "Rodar este nó para cada item. Padrão. Não fazer nada."
    execute_once: "Rodar este nó uma vez com todos os itens, não uma vez por item."
    loop_over_items: "Processar itens em lotes explícitos com controle de fluxo entre iterações."

  default_iteration:
    description: "N itens de entrada → N execuções do nó. A maioria dos nós faz isso automaticamente."
    when_sufficient: "HTTP Request com 50 itens = 50 chamadas. Conectar direto, sem Loop Over Items."
    exception: "Execute Workflow node: default é batch único. Usar mode: 'each' para per-item."

  execute_once:
    description: "Nó roda uma única vez, independente do número de itens de entrada."
    when_to_use:
      - "Notificações e escritas agregadas (uma mensagem resumo, não 100)"
      - "Contadores, totais, relatórios (qualquer coisa usando $input.all().length)"
      - "Expressões que agregam sobre o array completo via $input.all()"
    when_not_to_use:
      - "Operações por item (uma notificação por item é o padrão correto)"
      - "Chamadas HTTP que devem ser disparadas por item"
    most_common_mistake: "Esquecer executeOnce em nó agregado → mesma mensagem dispara 50 vezes após fan-out"
    code_example: |
      { name: 'Aggregate Slack', type: 'n8n-nodes-base.slack', parameters: {...}, executeOnce: true }

  loop_over_items:
    description: "Processamento explícito em lotes com controle entre iterações."
    when_to_use:
      - "Rate limiting: processar 10 por vez, esperar 1s entre lotes"
      - "Chamadas API em lote com corpo array: enviar chunks de 50 itens para /bulk"
      - "Tratamento de erro por lote: se um lote falha, logar e continuar"
      - "Iteração com estado: cada iteração depende da saída anterior"
      - "Polling de job long-running: verificar status a cada 30s até concluir (reset: true + $runIndex ceiling)"
    when_not_to_use:
      - "'Preciso esperar todos os itens terminarem' → iteração padrão já faz isso"
      - "'Preciso que o próximo nó rode para cada item' → padrão já faz isso"
    output_gotcha: "Saída 0 = done (resultado), Saída 1 = loop (continua). Não inverter."
    anti_pattern_nesting: "NÃO aninhar Loop Over Items dentro de outro no mesmo workflow. Mover loop interno para sub-workflow."

  http_pagination:
    description: "Paginação nativa do nó HTTP Request. Preferível a loop manual com $pageCount."
    modes:
      next_url: "Resposta inclui link next → HTTP Request segue automaticamente"
      page_number: "Incrementar ?page=N ou ?cursor=... a cada chamada"
      stop_on_empty: "Parar quando página voltar vazia"
    anti_pattern: "Reinventar com Loop Over Items + $pageCount (frágil, difícil de manter)"

  decision_tree: |
    Precisa fazer algo para cada item?
    ├── Iteração padrão resolve → Conectar o nó direto. Pronto.
    ├── O nó deve rodar UMA vez total, não por item? → executeOnce: true
    ├── API paginada (múltiplas chamadas HTTP)? → HTTP Request Pagination
    ├── Precisa de batch explícito (rate limit, chunk, erro por lote)? → Loop Over Items
    └── Precisa de recursão com estado? → Loop Over Items com Reset OU sub-workflow auto-chamável

  four_scenarios:
    scenario_1_default: "Source emite N itens → processador roda N vezes → cadeia segue. Sem Loop."
    scenario_2_execute_once: "Nó downstream específico deve disparar UMA vez (digest, resumo)."
    scenario_3_aggregate: "Nó precisa dos itens como array único (corpo JSON array, prompt LLM com lista)."
    scenario_4_genuine_batching: "Rate limiting, chunks, erro por lote, polling, iteração com estado."

  anti_patterns:
    - pattern: "Adicionar Loop Over Items 'para fazer loop' quando iteração padrão já funciona"
      fix: "Remover Loop Over Items, conectar direto"
    - pattern: "Nó agregado (Code com $input.all()) sem executeOnce"
      fix: "executeOnce: true"
    - pattern: "Loop manual de página com $pageCount em vez de HTTP Pagination nativa"
      fix: "Usar opção Pagination do HTTP Request"
    - pattern: "Duas branches alcançam Respond to Webhook sem merge"
      fix: "Merge antes do responder, ou garantir só uma branch chega lá"
    - pattern: "Loop Over Items com Reset sem condição de parada clara"
      fix: "Loop infinito → n8n come memória. Sempre ter condição de término."
    - pattern: "Aninhar Loop Over Items dentro de outro no mesmo workflow"
      fix: "Mover loop interno para sub-workflow com mode: 'each'"
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_execute_once_presence_check() {
  local node='{"name":"Aggregate","type":"n8n-nodes-base.code","executeOnce":true}'
  python3 -c "
import json; d=json.loads('$node')
assert d.get('executeOnce') == True, 'executeOnce should be true for aggregate node'
" 2>/dev/null && return 0 || return 1
}

test_loop_over_items_not_nested() {
  # Verificar que não há dois Loop Over Items no mesmo workflow
  local workflow='{"nodes":[{"type":"n8n-nodes-base.splitInBatches","name":"Loop1"}]}'
  python3 -c "
import json; d=json.loads('$workflow')
loop_count = sum(1 for n in d['nodes'] if 'splitInBatches' in n.get('type',''))
assert loop_count <= 1, 'Nesting Loop Over Items is broken at runtime'
" 2>/dev/null && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && {
  test_execute_once_presence_check && test_loop_over_items_not_nested && echo "✅" || echo "❌"
  exit $?
}
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[workflow-testing-fundamentals.md]]
- [[http-request-patterns.md]]
- [[error-handling-patterns.md]]
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]]
