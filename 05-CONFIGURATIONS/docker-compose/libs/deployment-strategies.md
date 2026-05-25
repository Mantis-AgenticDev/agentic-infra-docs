---
artifact_id: "docker-compose-deployment-strategies"
artifact_type: "docker-compose_pattern"
version: "1.0.0"
constraints_mapped: ["C6","C7"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/docker-compose/libs/deployment-strategies.md --json"
canonical_path: "05-CONFIGURATIONS/docker-compose/libs/deployment-strategies.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deployment-strategies-v1.0.0"
generated_at: "2026-05-23T18:35:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "docker-compose"
ai_navigation:
  read_first: false
  required_for: ["zero-downtime-deployment", "rollback-automation"]
  update_frequency: on-change
audience: ["docker-compose-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-23"
---

# 🚀 Estratégias de Despliegue — Rolling, Blue-Green, Canary, Rollback

> **Contrato modular**: Artefato filho de `docker-compose-master-agent-mantis`. Herda hardening, observability e constraints C1-C9 do Master.

## 🎯 Propósito
Fornecer padrões de atualização sem downtime e scripts de rollback para serviços Docker Compose, garantindo que falhas de deploy não afetem usuários finais (C7).

## 📋 Especificação (SDD)
- **Entradas**: Estratégia desejada (`rolling`, `blue-green`, `canary`), versão atual, nova versão.
- **Saídas**: Configuração YAML de deploy + script bash executável.
- **Side Effects**: Pode reiniciar contêineres em produção (se aplicado).
- **Constraints Aplicáveis**: C6 (aprovação de mudanças críticas), C7 (rollback automatizado).

---

## 🛡️ Padrões de Despliegue

### Rolling Update (Swarm ou Compose com múltiplas réplicas)
```yaml
deploy:
  replicas: 3
  update_config:
    parallelism: 1
    delay: 10s
    failure_action: rollback
    monitor: 60s
    order: start-first
  rollback_config:
    parallelism: 1
    delay: 5s
```

### Blue-Green Manual (VPS Simples)
```bash
#!/usr/bin/env bash
# Script de blue-green para VPS
set -euo pipefail
ENVIRONMENT="${1:-blue}"
VERSION="${2:?}"
COMPOSE_FILE="compose.prod.yaml"
export VERSION
export COMPOSE_PROJECT_NAME="mantis-$ENVIRONMENT"
docker compose -f compose.yaml -f "$COMPOSE_FILE" up -d
# Switch de tráfego após health check
```

### Canary (Proxy com Divisão de Tráfego)
```yaml
labels:
  traefik.http.services.app.loadbalancer.server.port: "4000"
  traefik.http.routers.app.rule: "Host(`api.mantis.org`)"
```

### Rollback Automático (Swarm) / Manual (VPS)
```bash
#!/usr/bin/env bash
# Rollback manual
set -euo pipefail
PREVIOUS_VERSION="${1:?}"
export VERSION="$PREVIOUS_VERSION"
docker compose -f compose.yaml -f compose.prod.yaml up -d
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_rolling_update_syntax() {
  local tmp; tmp=$(mktemp -d)
  cat > "$tmp/compose.yaml" << 'EOF'
services:
  test-svc:
    image: nginx:alpine
    deploy:
      update_config:
        parallelism: 1
        failure_action: rollback
EOF
  docker compose -f "$tmp/compose.yaml" config --quiet 2>/dev/null && return 0 || return 1
  rm -rf "$tmp"
}
[[ "${1:-}" == "--test" ]] && { test_rolling_update_syntax && echo "✅" || echo "❌"; }
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 05-CONFIGURATIONS/docker-compose/libs/deployment-strategies.md --json
```

---

## 🔗 Referências Cruzadas
- [[docker-compose-master-agent.md]]
- [[base-service-template.md]]
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]]



---

## 🔍 Observability
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `deploy_started` | INFO | C6 | `"Strategy=blue-green, Version=1.2.4"` |
| `deploy_rollback_triggered` | ERROR | C7 | `"Health check failed after 60s"` |

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-23T18:35:00Z | docker-compose-master-agent | Criação inicial | C6, C7 |
