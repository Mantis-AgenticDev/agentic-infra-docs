---
artifact_id: "n8n-data-tables-patterns"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C1","C4","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/data-tables-patterns.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/data-tables-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:data-tables-v1.0.0"
generated_at: "2026-05-24T19:20:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["state-management", "dedup", "lookup-tables", "audit-trails"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🗄️ Padrões de Data Tables — Armazenamento Tabular Local

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Padronizar o uso de Data Tables do n8n para armazenamento de estado local, tabelas de lookup, trilhas de auditoria e deduplicação com lógica em nível de linha, garantindo imutabilidade de schema (C1), rastreabilidade (C4), validação estrutural (C5) e logging (C8).

## 📋 Especificação (SDD)
- **Entradas**: Definição de colunas (tipos primitivos), regras de negócio para dedup e lookup.
- **Saídas**: Workflow n8n com nós Data Table configurados e validados.
- **Side Effects**: Persistência de dados no banco interno do n8n.
- **Constraints Aplicáveis**: C1 (schema versionado), C4 (IDs de domínio), C5 (validação de colunas), C8 (audit trail).
- **Dependências**: n8n auto-hospedado ou Cloud.

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
data_tables:
  non_negotiables:
    - "Colunas do sistema (id, createdAt, updatedAt) NUNCA devem ser declaradas ou escritas."
    - "Apenas tipos primitivos em colunas. Dados aninhados usam string + sufixo _object."
    - "Verificar colunas via get_workflow_details após create/update (evitar UI quirk 'Currently no items exist')."
    - "Formato de armazenamento ≠ formato de interface. Parsear campos _object antes de retornar."

  storage_rules:
    nested_data: "JSON.stringify() na escrita, JSON.parse() na leitura"
    column_suffix: "_object (contrato para leitores)"
    domain_ids: "arxivId, stripeCustomerId (NUNCA usar auto-id como chave cross-system)"
    casing: "camelCase para combinar com createdAt/updatedAt"

  operations:
    insert: "Sempre adiciona nova linha."
    upsert: "Adiciona se novo, atualiza se existe. Requer matchType e filtro."
    update: "Modifica linhas que correspondem ao filtro."
    get: "Busca linhas (suporta orderBy, limit, returnAll)."
    deleteRows: "Remove linhas que correspondem ao filtro."
    rowExists: "Verificação booleana para ramificação de dedup."

  patterns:
    dedup_by_external_id: |
      [Source: { arxivId, ... }]
         ↓
      [Data Table Get: filter arxivId eq $json.arxivId, limit 1]
         ↓
      [IF: result has items?]
         ├── Yes → [Skip]
         └── No  → [Process] → [Data Table Insert: { arxivId, ...rest }]
    lookup_tables: "[Data Table Get: filter country eq $json.country, limit 1] → Use campos da linha retornada."
    audit_trail: "[Workflow event] → [Data Table Insert: { userId, eventType, payloadSummary }]"

  ui_quirk:
    symptom: "UI mostra 'Currently no items exist' no modo manual."
    fix: "Apertar o botão de reload no parâmetro de colunas. Sem perda de dados."

  anti_patterns:
    - "Usar Set node antes de Insert (mapear diretamente nos slots do Data Table)."
    - "Declarar id, createdAt, updatedAt em create_data_table (causa erros)."
    - "Armazenar dados críticos da aplicação (usar um DB real)."
    - "Assumir que auto-id é estável entre instâncias."
    - "Assumir cascata de chave estrangeira (n8n não faz)."
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_data_table_no_system_columns() {
  local schema='{"columns":[{"name":"arxivId","type":"string"}]}'
  python3 -c "
import json; d=json.loads('$schema')
assert not any(c['name'] in ('id','createdAt','updatedAt') for c in d['columns'])
" 2>/dev/null && return 0 || return 1
}

test_object_suffix_convention() {
  local col="keyInsights_object"
  [[ "$col" == *_object ]] && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && {
  test_data_table_no_system_columns && test_object_suffix_convention && echo "✅" || echo "❌"
  exit $?
}
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[api-integration-patterns.md]]
- [[error-handling-patterns.md]]
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]]
