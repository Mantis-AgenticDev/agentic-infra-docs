---
artifact_id: "docker-compose-environment-strategies"
artifact_type: "docker-compose_pattern"
version: "1.0.0"
constraints_mapped: ["C2","C6"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/docker-compose/libs/environment-strategies.md --json"
canonical_path: "05-CONFIGURATIONS/docker-compose/libs/environment-strategies.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:environment-strategies-v1.0.0"
generated_at: "2026-05-23T18:50:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "docker-compose"
ai_navigation:
  read_first: false
  required_for: ["multi-environment-setup", "compose-override"]
  update_frequency: on-change
audience: ["docker-compose-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-23"
---

# 🌍 Estratégias de Múltiplos Ambientes

> **Contrato modular**: Filho de `docker-compose-master-agent-mantis`.

## 🎯 Propósito
Gerenciar configurações de development, staging e production usando arquivos compose sobrepostos e variáveis de ambiente, garantindo reprodutibilidade e segurança entre ambientes (C2, C6).

## 📋 Especificação
- **Entradas**: Nome do ambiente (`dev`, `staging`, `prod`).
- **Saídas**: Estrutura de arquivos compose + comandos de deploy.
- **Constraints Aplicáveis**: C2 (IaC declarativo), C6 (aprovação de mudanças críticas).

---

## 🛡️ Estrutura de Arquivos

### compose.yaml (base comum)
```yaml
services:
  app:
    image: registry.mantis.org/app:${VERSION:-latest}
    restart: unless-stopped
```

### compose.override.yaml (desenvolvimento, auto-carregado)
```yaml
services:
  app:
    build:
      target: development
    volumes:
      - ./src:/app/src
    ports:
      - "4000:4000"
    command: npm run dev
```

### compose.prod.yaml (produção)
```yaml
services:
  app:
    deploy:
      replicas: 3
      update_config:
        failure_action: rollback
    environment:
      - NODE_ENV=production
    logging:
      driver: json-file
      options:
        max-size: "10m"
```

### Comandos de Deploy por Ambiente
```bash
# Desenvolvimento (auto-carrega override.yaml)
docker compose up -d

# Staging
docker compose -f compose.yaml -f compose.staging.yaml --env-file .env.staging up -d

# Produção
docker compose -f compose.yaml -f compose.prod.yaml --env-file .env.production up -d
```

### .env.example (variáveis obrigatórias documentadas)
```bash
VERSION=latest
PORT=4000
CPU_LIMIT=2
MEM_LIMIT=2G
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_env_override_syntax() {
  local tmp; tmp=$(mktemp -d)
  cat > "$tmp/compose.yaml" << 'EOF'
services:
  test-svc:
    image: alpine:3.19
    command: env
EOF
  cat > "$tmp/compose.override.yaml" << 'EOF'
services:
  test-svc:
    environment:
      - TEST_VAR=hello
EOF
  cd "$tmp" && docker compose config --quiet 2>/dev/null && return 0 || return 1
  rm -rf "$tmp"
}
[[ "${1:-}" == "--test" ]] && { test_env_override_syntax && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[docker-compose-master-agent.md]]
- [[deployment-strategies.md]]
- [[security-patterns.md]]
