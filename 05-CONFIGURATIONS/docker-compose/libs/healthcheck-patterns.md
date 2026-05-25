---
artifact_id: "docker-compose-healthcheck-patterns"
artifact_type: "docker-compose_pattern"
version: "1.0.0"
constraints_mapped: ["C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/docker-compose/libs/healthcheck-patterns.md --json"
canonical_path: "05-CONFIGURATIONS/docker-compose/libs/healthcheck-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:healthcheck-patterns-v1.0.0"
generated_at: "2026-05-23T18:15:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "docker-compose"
ai_navigation:
  read_first: false
  required_for: ["service-healthcheck-definition", "compose-generation"]
  update_frequency: on-change
audience: ["docker-compose-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-23"
---

# 🩺 Health Checks por Tecnologia

> **Contrato modular**: Artefato filho de `docker-compose-master-agent-mantis`. Herda hardening e constraints do Master.

## 🎯 Propósito
Fornecer uma coleção canônica de configurações de health check para as tecnologias usadas no ecossistema MANTIS, garantindo a detecção rápida de falhas e a integração com orquestração (C8).

## 📋 Especificação
- **Entradas**: Nome da tecnologia (ex: `postgresql`, `redis`, `http-api`).
- **Saídas**: Bloco YAML `healthcheck` válido para Docker Compose.
- **Constraints Aplicáveis**: C8 (qualidade de entrega com testes de sanidade).

---

## 🛡️ Coleção de Health Checks

### HTTP/API (Node.js, Python, Go, etc.)
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:${PORT:-8080}/health/ready"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

### PostgreSQL (com verificação de extensão pgvector)
```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-app} -d ${POSTGRES_DB:-mantis}"]
  interval: 10s
  timeout: 5s
  retries: 5
  start_period: 30s
```

### PostgreSQL com pgvector (valida extensão)
```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U app -d mantis && psql -U app -d mantis -c 'SELECT extname FROM pg_extension WHERE extname = ''vector'';' | grep -q vector"]
  interval: 10s
  timeout: 5s
  retries: 5
  start_period: 40s
```

### Redis
```yaml
healthcheck:
  test: ["CMD", "redis-cli", "ping"]
  interval: 10s
  timeout: 3s
  retries: 5
```

### RabbitMQ
```yaml
healthcheck:
  test: ["CMD", "rabbitmq-diagnostics", "ping"]
  interval: 30s
  timeout: 10s
  retries: 5
```

### MongoDB
```yaml
healthcheck:
  test: ["CMD", "mongosh", "--eval", "db.adminCommand('ping')"]
  interval: 10s
  timeout: 5s
  retries: 5
```

### Custom Script (para verificações profundas)
```yaml
healthcheck:
  test: ["CMD", "node", "/app/healthcheck.js"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 60s
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_healthcheck_yaml_syntax() {
  local tmp; tmp=$(mktemp -d)
  cat > "$tmp/compose.yaml" << 'EOF'
services:
  test-svc:
    image: alpine:3.19
    command: sleep 3600
    healthcheck:
      test: ["CMD", "true"]
      interval: 10s
EOF
  docker compose -f "$tmp/compose.yaml" config --quiet 2>/dev/null && return 0 || return 1
  rm -rf "$tmp"
}

if [[ "${1:-}" == "--test" ]]; then
  test_healthcheck_yaml_syntax && echo "✅ Test passed" || echo "❌ Test failed"
fi
```

---

## 🔗 Referências Cruzadas
- [[docker-compose-master-agent.md]]
- [[security-patterns.md]]
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]]
