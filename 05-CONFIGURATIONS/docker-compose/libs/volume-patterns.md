---
artifact_id: "docker-compose-volume-patterns"
artifact_type: "docker-compose_pattern"
version: "1.0.0"
constraints_mapped: ["C1","C2"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/docker-compose/libs/volume-patterns.md --json"
canonical_path: "05-CONFIGURATIONS/docker-compose/libs/volume-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:volume-patterns-v1.0.0"
generated_at: "2026-05-23T18:25:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "docker-compose"
ai_navigation:
  read_first: false
  required_for: ["data-persistence", "compose-generation"]
  update_frequency: on-change
audience: ["docker-compose-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-23"
---

# 💾 Padrões de Volumes e Persistência

> **Contrato modular**: Filho de `docker-compose-master-agent-mantis`.

## 🎯 Propósito
Definir os tipos de volumes disponíveis (named, bind, tmpfs, external) e seus usos canônicos para garantir persistência de dados, desempenho e segurança.

## 📋 Especificação
- **Entradas**: Tipo de persistência (`database`, `cache`, `config`, `shared`).
- **Saídas**: Bloco YAML `volumes` e respectivos mounts nos serviços.
- **Constraints Aplicáveis**: C1 (imutabilidade de artefatos), C2 (IaC).

---

## 🛡️ Padrões de Volume

### Named Volume para Dados Persistentes
```yaml
volumes:
  postgres-data:
    driver: local
services:
  db:
    volumes:
      - postgres-data:/var/lib/postgresql/data
```

### Bind Mount para Configuração (somente leitura)
```yaml
services:
  app:
    volumes:
      - ./config/app.conf:/etc/app/app.conf:ro
```

### tmpfs para Dados Efêmeros
```yaml
services:
  app:
    tmpfs:
      - /tmp:noexec,nosuid,size=64M
```

### Volume Externo (pré-criado)
```yaml
volumes:
  shared-storage:
    external: true
    name: mantis-shared-nfs
services:
  app:
    volumes:
      - shared-storage:/mnt/shared:ro
```

### Bind Mount com Opções de Propagação
```yaml
services:
  app:
    volumes:
      - type: bind
        source: ./data
        target: /app/data
        bind:
          propagation: shared
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_volume_mount_syntax() {
  local tmp; tmp=$(mktemp -d)
  cat > "$tmp/compose.yaml" << 'EOF'
services:
  test-svc:
    image: alpine:3.19
    volumes:
      - test-vol:/data
volumes:
  test-vol:
    driver: local
EOF
  docker compose -f "$tmp/compose.yaml" config --quiet 2>/dev/null && return 0 || return 1
  rm -rf "$tmp"
}

if [[ "${1:-}" == "--test" ]]; then
  test_volume_mount_syntax && echo "✅ Test passed" || echo "❌ Test failed"
fi
```

---

## 🔗 Referências Cruzadas
- [[docker-compose-master-agent.md]]
- [[security-patterns.md]]
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]]
