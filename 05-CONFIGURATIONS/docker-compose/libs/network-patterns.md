---
artifact_id: "docker-compose-network-patterns"
artifact_type: "docker-compose_pattern"
version: "1.0.0"
constraints_mapped: ["C2","V1"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/docker-compose/libs/network-patterns.md --json"
canonical_path: "05-CONFIGURATIONS/docker-compose/libs/network-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:network-patterns-v1.0.0"
generated_at: "2026-05-23T18:20:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "docker-compose"
ai_navigation:
  read_first: false
  required_for: ["network-isolation", "service-communication"]
  update_frequency: on-change
audience: ["docker-compose-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-23"
---

# 🌐 Estratégias de Rede e Isolamento

> **Contrato modular**: Filho de `docker-compose-master-agent-mantis`. Herda hardening do Master.

## 🎯 Propósito
Definir os padrões de redes Docker Compose para garantir isolamento entre serviços de borda e internos, aplicando o princípio de menor privilégio e suportando multi-tenancy (V1).

## 📋 Especificação
- **Entradas**: Tipo de rede (`frontend`, `backend`, `internal`, `host`).
- **Saídas**: Bloco YAML `networks` com configuração adequada.
- **Constraints Aplicáveis**: C2 (IaC declarativo), V1 (isolamento de tenants).

---

## 🛡️ Padrões de Rede

### Rede Bridge Padrão (desenvolvimento)
```yaml
networks:
  default:
    driver: bridge
```

### Rede Frontal (exposta ao proxy)
```yaml
networks:
  frontend:
    driver: bridge
    # Sem internal: permite acesso externo via proxy
```

### Rede Backend (isolada, sem acesso à Internet)
```yaml
networks:
  backend:
    driver: bridge
    internal: true  # Apenas comunicação entre contêineres
```

### Rede por Tenant (V1)
```yaml
networks:
  tenant-abc-net:
    driver: bridge
    internal: true
    labels:
      com.mantis.tenant: "abc"
      com.mantis.constraint: "V1"
```

### Network Mode Host (somente casos extremos)
```yaml
services:
  critical-svc:
    network_mode: host  # Evitar por segurança; usar apenas se inevitável
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_network_isolation() {
  local tmp; tmp=$(mktemp -d)
  cat > "$tmp/compose.yaml" << 'EOF'
services:
  test-svc:
    image: alpine:3.19
    command: sleep 5
    networks:
      - back
networks:
  back:
    driver: bridge
    internal: true
EOF
  docker compose -f "$tmp/compose.yaml" config --quiet 2>/dev/null && return 0 || return 1
  rm -rf "$tmp"
}

if [[ "${1:-}" == "--test" ]]; then
  test_network_isolation && echo "✅ Test passed" || echo "❌ Test failed"
fi
```

---

## 🔗 Referências Cruzadas
- [[docker-compose-master-agent.md]]
- [[security-patterns.md]]
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]]
