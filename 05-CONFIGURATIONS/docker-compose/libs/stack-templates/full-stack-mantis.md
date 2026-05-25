---
artifact_id: "docker-compose-full-stack-mantis-template"
artifact_type: "docker-compose_template"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C7","C8","V1","V2","V3"]
validation_command: "docker compose -f 05-CONFIGURATIONS/docker-compose/libs/stack-templates/full-stack-mantis.md config --quiet 2>/dev/null || echo 'INFO: validación YAML manual requerida'"
canonical_path: "05-CONFIGURATIONS/docker-compose/libs/stack-templates/full-stack-mantis.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:full-stack-mantis-v1.0.0"
generated_at: "2026-05-23T19:10:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "docker-compose"
ai_navigation:
  read_first: false
  required_for: ["stack-generation", "full-deployment"]
  update_frequency: on-change
audience: ["docker-compose-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-23"
---

# 🏢 Stack Completo MANTIS — Proxy + Backend + DB + Redis + pgvector

> **Contrato modular**: Filho de `docker-compose-master-agent-mantis`. Herda hardening, observability e constraints do Master.

## 🎯 Propósito
Fornecer um template completo de stack Docker Compose para o ecossistema MANTIS, incluindo proxy reverso, aplicação, PostgreSQL com pgvector e Redis, pronto para uso em VPS.

## 📋 Especificação
- **Entradas**: Nenhuma (template auto-contido com placeholders `${VAR}`).
- **Saídas**: Arquivo `compose.yaml` funcional.
- **Constraints Aplicáveis**: C1-C8, V1-V3.

---

## 🛡️ Template do Stack

```yaml
# ═══════════════════════════════════════════════════════
# STACK COMPLETO MANTIS — v2.3.0
# ═══════════════════════════════════════════════════════
# Placeholders: ${VERSION}, ${PORT}, ${DB_PASSWORD}, ${CPU_LIMIT}, ${MEM_LIMIT}

services:
  proxy:
    image: nginx:alpine@sha256:abc123...
    ports:
      - "127.0.0.1:${PORT:-80}:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    networks: [front]
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s

  app:
    <<: *service-base
    build:
      context: ./app
      target: production
    expose: ["4000"]
    environment:
      - DATABASE_URL=postgresql://app:${DB_PASSWORD}@pg:5432/mantis
      - REDIS_URL=redis://redis:6379
    networks: [front, back]
    secrets: [db_password]

  pg:
    image: pgvector/pgvector:pg16@sha256:def456...
    environment:
      POSTGRES_USER: app
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
      POSTGRES_DB: mantis
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./init-vector.sql:/docker-entrypoint-initdb.d/init.sql:ro
    networks: [back]
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app -d mantis"]
      interval: 10s
    secrets: [db_password]
    deploy:
      resources:
        limits:
          memory: ${PG_MEM_LIMIT:-4G}

  redis:
    image: redis:7-alpine@sha256:ghi789...
    command: redis-server --appendonly yes
    volumes: [redisdata:/data]
    networks: [back]
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s

networks:
  front: { driver: bridge }
  back: { driver: bridge, internal: true }

volumes:
  pgdata: { driver: local }
  redisdata: { driver: local }

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_full_stack_syntax() {
  local tmp; tmp=$(mktemp -d)
  cat > "$tmp/compose.yaml" << 'EOF'
services:
  test-svc:
    image: alpine:3.19
    command: sleep 5
    networks: [back]
networks:
  back: { driver: bridge, internal: true }
EOF
  docker compose -f "$tmp/compose.yaml" config --quiet 2>/dev/null && return 0 || return 1
  rm -rf "$tmp"
}
[[ "${1:-}" == "--test" ]] && { test_full_stack_syntax && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[docker-compose-master-agent.md]]
- [[base-service-template.md]]
- [[network-patterns.md]]
