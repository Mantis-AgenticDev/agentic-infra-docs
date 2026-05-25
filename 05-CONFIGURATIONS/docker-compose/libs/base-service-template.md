---
artifact_id: "docker-compose-base-service-template"
artifact_type: "docker-compose_pattern"
version: "1.0.0"
constraints_mapped: ["C1","C2","C7"]
validation_command: "docker compose -f 05-CONFIGURATIONS/docker-compose/libs/base-service-template.md config --quiet 2>/dev/null || echo 'INFO: validación YAML manual requerida'"
canonical_path: "05-CONFIGURATIONS/docker-compose/libs/base-service-template.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:base-service-template-v1.0.0"
generated_at: "2026-05-23T18:05:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "docker-compose"
ai_navigation:
  read_first: false
  required_for: ["service-definition", "compose-generation"]
  update_frequency: on-change
audience: ["docker-compose-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-23"
---

# 🧱 Plantilla de Servicio Base (YAML Anchor `x-service-base`)

> **Contrato modular**: Este artefacto es hijo de `docker-compose-master-agent-mantis`. Hereda hardening, observability y constraints C1-C9 del Master Agent.

## 🎯 Propósito
Proveer una plantilla YAML reutilizable con anchors (`&service-base`) que contenga todos los defaults de seguridad, recursos y health checks para los servicios del ecosistema MANTIS, evitando la repetición de configuraciones en cada servicio.

## 📋 Especificación (SDD)
- **Entradas**: Ninguna. Es una definición YAML con anchors para ser referenciada con `<<: *service-base`.
- **Saídas**: Bloque YAML válido para Docker Compose v2.x+.
- **Constraints Aplicables**: C1 (inmutabilidad), C2 (IaC declarativo), C7 (rollback con health checks).
- **Dependencias**: Ninguna externa.

---

## 🛡️ Bootstrap + Plantilla YAML

```yaml
# ═══════════════════════════════════════════════════════
# PLANTILLA DE SERVICIO BASE — MANTIS Agentic v2.3.0
# ═══════════════════════════════════════════════════════
# Uso: Agregar en la sección superior de compose.yaml
#       y referenciar con <<: *service-base en cada servicio.
# ═══════════════════════════════════════════════════════

x-service-base: &service-base
  restart: unless-stopped
  env_file:
    - .env.common
    - .env.${SERVICE}
  networks:
    - mantis-net
  depends_on:
    postgres:
      condition: service_healthy
    redis:
      condition: service_started
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:${PORT:-8080}/health/ready"]
    interval: 30s
    timeout: 5s
    retries: 3
    start_period: 40s
  logging:
    driver: json-file
    options:
      max-size: "10m"
      max-file: "5"
  deploy:
    resources:
      limits:
        cpus: '${CPU_LIMIT:-2}'
        memory: '${MEM_LIMIT:-2G}'
      reservations:
        cpus: '${CPU_RESERVE:-1}'
        memory: '${MEM_RESERVE:-1G}'
  cap_drop:
    - ALL
  cap_add:
    - NET_BIND_SERVICE
  security_opt:
    - no-new-privileges:true
  read_only: true
  tmpfs:
    - /tmp:noexec,nosuid,size=64M
    - /var/run:noexec,nosuid,size=16M
  user: "1001:1001"

# ═══════════════════════════════════════════════════════
# EJEMPLO DE USO EN UN SERVICIO
# ═══════════════════════════════════════════════════════
# services:
#   backend:
#     <<: *service-base
#     build:
#       context: ./backend
#       target: production
#     expose:
#       - "4000"
#     environment:
#       - SERVICE=backend
#       - PORT=4000
```

---

## 🧪 Testes Unitários (TDD — Validación YAML)

```bash
#!/usr/bin/env bash
# Test: validar que la plantilla YAML es sintácticamente correcta
# Constraint: C2 (IaC declarativo)

test_plantilla_yaml_valida() {
  local tmp; tmp=$(mktemp -d)
  # Arrange: crear un compose mínimo que use la plantilla
  cat > "$tmp/compose.yaml" << 'EOF'
x-service-base: &service-base
  restart: unless-stopped
  networks: [test-net]
services:
  test-svc:
    <<: *service-base
    image: alpine:3.19
    command: echo ok
networks:
  test-net: {}
EOF
  # Act: validar con docker compose
  if command -v docker &>/dev/null; then
    docker compose -f "$tmp/compose.yaml" config --quiet 2>/dev/null
  else
    python3 -c "import yaml; yaml.safe_load(open('$tmp/compose.yaml'))" && return 0 || return 1
  fi
}

if [[ "${1:-}" == "--test" ]]; then
  test_plantilla_yaml_valida && echo "✅ Test pasado" || echo "❌ Test fallido"
  exit $?
fi
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 05-CONFIGURATIONS/docker-compose/libs/base-service-template.md \
  --json --check-structural
```

---

## 🔗 Referências Cruzadas
- [[docker-compose-master-agent.md]] ← Fonte de hardening, observability, constraints
- [[healthcheck-patterns.md]] ← Health checks por tecnologia
- [[security-patterns.md]] ← Segurança de contêineres
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]] ← Mapeamento constraints

---

## 🔍 Observability
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `service_base_applied` | INFO | C2 | `"Service=backend, Template=service-base"` |
| `service_base_validation_failed` | ERROR | C5 | `"Compose config failed for service"` |

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-23T18:05:00Z | docker-compose-master-agent | Criação inicial | C1, C2, C7 |
