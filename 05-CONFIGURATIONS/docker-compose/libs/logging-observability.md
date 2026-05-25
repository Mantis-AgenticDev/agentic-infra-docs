---
artifact_id: "docker-compose-logging-observability"
artifact_type: "docker-compose_pattern"
version: "1.0.0"
constraints_mapped: ["C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/docker-compose/libs/logging-observability.md --json"
canonical_path: "05-CONFIGURATIONS/docker-compose/libs/logging-observability.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:logging-observability-v1.0.0"
generated_at: "2026-05-23T18:45:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "docker-compose"
ai_navigation:
  read_first: false
  required_for: ["logging-configuration", "metrics-exposure"]
  update_frequency: on-change
audience: ["docker-compose-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-23"
---

# 📊 Logging e Observabilidade

> **Contrato modular**: Filho de `docker-compose-master-agent-mantis`.

## 🎯 Propósito
Configurar logging rotativo nos contêineres e expor métricas para Prometheus/Grafana, garantindo rastreabilidade e diagnóstico rápido (C8).

## 📋 Especificação
- **Entradas**: Nome do serviço, labels OCI desejadas.
- **Saídas**: Bloco `logging` YAML + labels de monitoramento.
- **Constraints Aplicáveis**: C8 (qualidade de entrega com testes e observabilidade).

---

## 🛡️ Configurações de Logging

### JSON File com Rotação
```yaml
services:
  app:
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "5"
        labels: "service,env,version"
        env: "NODE_ENV,VERSION"
```

### Labels OCI para Rastreabilidade
```yaml
services:
  app:
    labels:
      org.opencontainers.image.source: "https://github.com/Mantis-AgenticDev/agentic-infra-docs"
      org.opencontainers.image.version: "${VERSION}"
      com.mantis.team: "core"
      com.mantis.constraint-mapping: "C1,C2,C3,C4,C5,C6,C7,C8,V1,V2,V3"
```

### Exposição de Métricas (Prometheus)
```yaml
services:
  app:
    ports:
      - "127.0.0.1:9090:9090"  # Métricas apenas local
    labels:
      prometheus.io/scrape: "true"
      prometheus.io/port: "9090"
      prometheus.io/path: "/metrics"
```

### Health Check como Smoke Test
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:${PORT}/health/ready"]
  interval: 30s
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_logging_config_syntax() {
  local tmp; tmp=$(mktemp -d)
  cat > "$tmp/compose.yaml" << 'EOF'
services:
  test-svc:
    image: alpine:3.19
    command: echo ok
    logging:
      driver: json-file
      options:
        max-size: "10m"
EOF
  docker compose -f "$tmp/compose.yaml" config --quiet 2>/dev/null && return 0 || return 1
  rm -rf "$tmp"
}
[[ "${1:-}" == "--test" ]] && { test_logging_config_syntax && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[docker-compose-master-agent.md]]
- [[healthcheck-patterns.md]]
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]]
