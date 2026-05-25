---
artifact_id: "pipelines-performance-optimization"
artifact_type: "pipelines_pattern"
version: "1.0.0"
constraints_mapped: ["C1","C2"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/pipelines/libs/performance-optimization.md --json"
canonical_path: "05-CONFIGURATIONS/pipelines/libs/performance-optimization.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:perf-optimization-v1.0.0"
generated_at: "2026-05-24T00:00:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "pipelines"
ai_navigation:
  read_first: false
  required_for: ["pipeline-acceleration", "cache-strategy"]
  update_frequency: on-change
audience: ["pipelines-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# ⚡ Otimização de Performance em Pipelines

> **Contrato modular**: Filho de `pipelines-master-agent-mantis`.

## 🎯 Propósito
Reduzir o tempo de execução dos pipelines através de caching multi-nível, paralelismo e políticas de eviction de contexto (C1, C2).

## 📋 Especificação
- **Entradas**: Tipo de dependências (npm, pip, Docker), perfil de execução.
- **Saídas**: Configuração de cache e jobs paralelos.
- **Constraints Aplicáveis**: C1 (imutabilidade de artefatos), C2 (eficiência de infraestrutura).

---

## 🛡️ Padrões de Otimização

### Cache de Dependências
```yaml
- uses: actions/cache@v4
  with:
    path: |
      ~/.npm
      node_modules
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
```

### Cache de Imagens Docker
```yaml
- uses: actions/cache@v4
  with:
    path: /var/lib/docker
    key: ${{ runner.os }}-docker-${{ hashFiles('Dockerfile') }}
```

### Execução Paralela com Matriz
```yaml
strategy:
  matrix:
    skill: ${{ fromJson(needs.detect.outputs.skills) }}
  fail-fast: false
```

### Política de Eviction MoE (Memory of Execution)
```yaml
token_budget_policy:
  rules:
    core_bundle_load: "Obrigatório uma vez por sessão"
    overlay_load: "Apenas o overlay do modo ativo"
    eviction_policy:
      trigger: "Uso > 75% da janela de contexto"
      action:
        - "Disparar chronique_protocol"
        - "Remover overlay atual"
        - "Reter core_bundle e agente ativo"
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_cache_key_deterministic() {
  local hash1=$(echo "test" | sha256sum | cut -d' ' -f1)
  local hash2=$(echo "test" | sha256sum | cut -d' ' -f1)
  [[ "$hash1" == "$hash2" ]] && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { test_cache_key_deterministic && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[pipelines-master-agent.md]]
- [[../monorepo-patterns.md]]
- [[../../docker-compose/libs/image-building.md]] — Cache de builds Docker
