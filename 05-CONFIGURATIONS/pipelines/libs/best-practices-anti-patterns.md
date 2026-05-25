---
artifact_id: "pipelines-best-practices-anti-patterns"
artifact_type: "pipelines_pattern"
version: "1.0.0"
constraints_mapped: ["C7"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/pipelines/libs/best-practices-anti-patterns.md --json"
canonical_path: "05-CONFIGURATIONS/pipelines/libs/best-practices-anti-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:best-practices-v1.0.0"
generated_at: "2026-05-24T00:15:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "pipelines"
ai_navigation:
  read_first: false
  required_for: ["pipeline-quality", "anti-pattern-avoidance"]
  update_frequency: on-change
audience: ["pipelines-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# ✅ Boas Práticas e Anti-Padrões

> **Contrato modular**: Filho de `pipelines-master-agent-mantis`.

## 🎯 Propósito
Listar as práticas recomendadas e os anti-padrões críticos para pipelines CI/CD, com foco em resiliência (C7).

## 📋 Especificação
- **Entradas**: Tipo de pipeline.
- **Saídas**: Checklist de validação.
- **Constraints Aplicáveis**: C7 (rollback automatizado).

---

## 🛡️ Recomendações

### ✅ DO
- Separar concerns em workflows distintos
- Cache de dependências + paralelismo
- OIDC + secrets scoped por ambiente
- Timeouts + retries com backoff
- Health checks profundos como gate de produção

### ❌ DON'T
- Hardcodear secrets em YAML
- Recompilar artefatos em cada ambiente
- Omitir `timeout-minutes` em jobs
- Usar `actions/checkout@v4` sem SHA pinning
- Executar deploy de produção sem health check profundo

### Retry com Backoff
```yaml
- uses: nick-fields/retry-action@v2
  with:
    timeout_minutes: 15
    max_attempts: 4
    retry_wait_seconds: 30
    command: ./deploy.sh production
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_anti_pattern_no_latest_tag() {
  grep -r 'uses:.*@v[0-9]' .github/workflows/ | grep -v '@[a-f0-9]\{40\}' && return 1 || return 0
}
[[ "${1:-}" == "--test" ]] && { test_anti_pattern_no_latest_tag && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[pipelines-master-agent.md]]
- [[../../docker-compose/libs/references/docker-best-practices.md]]
