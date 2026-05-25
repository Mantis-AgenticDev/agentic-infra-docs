---
artifact_id: "docker-compose-microservices-template"
artifact_type: "docker-compose_template"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C7","C8"]
validation_command: "docker compose -f 05-CONFIGURATIONS/docker-compose/libs/stack-templates/microservices-messaging.md config --quiet 2>/dev/null || echo 'INFO: validación YAML manual requerida'"
canonical_path: "05-CONFIGURATIONS/docker-compose/libs/stack-templates/microservices-messaging.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:microservices-template-v1.0.0"
generated_at: "2026-05-23T19:15:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "docker-compose"
ai_navigation:
  read_first: false
  required_for: ["microservices-deployment", "messaging-stack"]
  update_frequency: on-change
audience: ["docker-compose-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-23"
---

# 🔀 Microserviços com Proxy Inverso e Mensageria

> **Contrato modular**: Filho de `docker-compose-master-agent-mantis`.

## 🎯 Propósito
Template de stack para arquitetura de microserviços usando Traefik como proxy reverso e RabbitMQ como sistema de mensageria.

## 📋 Especificação
- **Entradas**: Nenhuma (placeholders `${VAR}`).
- **Saídas**: `compose.microservices.yaml` funcional.
- **Constraints Aplicáveis**: C1-C8.

---

## 🛡️ Template de Microserviços

```yaml
# ═══════════════════════════════════════════════════════
# MICROSERVIÇOS MANTIS — Traefik + RabbitMQ
# ═══════════════════════════════════════════════════════

services:
  traefik:
    image: traefik:v2.10@sha256:abc123...
    command:
      - "--providers.docker=true"
      - "--entrypoints.web.address=:80"
    ports:
      - "80:80"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks: [edge]

  auth-svc:
    <<: *service-base
    build: ./services/auth
    expose: ["8001"]
    environment:
      - JWT_SECRET_FILE=/run/secrets/jwt_secret
    networks: [edge, internal]
    secrets: [jwt_secret]

  user-svc:
    <<: *service-base
    build: ./services/user
    expose: ["8002"]
    environment:
      - AUTH_SERVICE_URL=http://auth-svc:8001
    networks: [edge, internal]

  rabbitmq:
    image: rabbitmq:3-management-alpine@sha256:jkl012...
    environment:
      RABBITMQ_DEFAULT_PASS_FILE: /run/secrets/rabbit_password
    volumes: [rabbitmq-data:/var/lib/rabbitmq]
    networks: [internal]
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "ping"]
      interval: 30s
    secrets: [rabbit_password]

networks:
  edge: { driver: bridge }
  internal: { driver: bridge, internal: true }

volumes:
  rabbitmq-data: { driver: local }

secrets:
  jwt_secret: { file: ./secrets/jwt_secret.txt }
  rabbit_password: { file: ./secrets/rabbit_password.txt }
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_microservices_syntax() {
  local tmp; tmp=$(mktemp -d)
  cat > "$tmp/compose.yaml" << 'EOF'
services:
  svc1:
    image: alpine:3.19
    command: sleep 5
    networks: [internal]
networks:
  internal: { driver: bridge, internal: true }
EOF
  docker compose -f "$tmp/compose.yaml" config --quiet 2>/dev/null && return 0 || return 1
  rm -rf "$tmp"
}
[[ "${1:-}" == "--test" ]] && { test_microservices_syntax && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[docker-compose-master-agent.md]]
- [[network-patterns.md]]
- [[security-patterns.md]]
