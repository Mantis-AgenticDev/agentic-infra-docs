---
artifact_id: "docker-compose-security-patterns"
artifact_type: "docker-compose_pattern"
version: "1.0.0"
constraints_mapped: ["C3"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/docker-compose/libs/security-patterns.md --json"
canonical_path: "05-CONFIGURATIONS/docker-compose/libs/security-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:security-patterns-v1.0.0"
generated_at: "2026-05-23T18:30:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "docker-compose"
ai_navigation:
  read_first: false
  required_for: ["container-hardening", "compose-security"]
  update_frequency: on-change
audience: ["docker-compose-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-23"
---

# 🛡️ Segurança de Contêineres

> **Contrato modular**: Filho de `docker-compose-master-agent-mantis`.

## 🎯 Propósito
Garantir que todos os serviços executem com o princípio de menor privilégio, sem secrets hardcoded, e com filesystem somente leitura (C3).

## 📋 Especificação
- **Entradas**: Nome do serviço.
- **Saídas**: Bloco YAML com configurações de segurança.
- **Constraints Aplicáveis**: C3 (secretos nunca em texto plano).

---

## 🛡️ Configurações de Segurança

### Usuário Non-Root + Drop Capacidades
```yaml
services:
  app:
    user: "1001:1001"
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE  # Apenas se porta < 1024
    security_opt:
      - no-new-privileges:true
```

### Filesystem Somente Leitura
```yaml
services:
  app:
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,size=64M
      - /var/run:noexec,nosuid,size=16M
```

### Gestão de Secrets
```yaml
services:
  app:
    secrets:
      - db_password
    environment:
      - DB_PASSWORD_FILE=/run/secrets/db_password  # Arquivo, nunca env var
secrets:
  db_password:
    file: ./secrets/db_password.txt  # Fora do repositório
```

### Perfil Seccomp Personalizado
```yaml
services:
  app:
    security_opt:
      - seccomp=./profiles/app-seccomp.json
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_security_no_root() {
  local tmp; tmp=$(mktemp -d)
  cat > "$tmp/compose.yaml" << 'EOF'
services:
  test-svc:
    image: alpine:3.19
    command: id
    user: "1001:1001"
    cap_drop: [ALL]
    read_only: true
EOF
  docker compose -f "$tmp/compose.yaml" config --quiet 2>/dev/null && return 0 || return 1
  rm -rf "$tmp"
}

if [[ "${1:-}" == "--test" ]]; then
  test_security_no_root && echo "✅ Test passed" || echo "❌ Test failed"
fi
```

---

## 🔗 Referências Cruzadas
- [[docker-compose-master-agent.md]]
- [[base-service-template.md]]
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]]
