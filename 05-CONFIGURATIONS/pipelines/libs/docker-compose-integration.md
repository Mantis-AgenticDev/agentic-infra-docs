---
artifact_id: "pipelines-docker-compose-integration"
artifact_type: "pipelines_pattern"
version: "1.0.0"
constraints_mapped: ["C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/pipelines/libs/docker-compose-integration.md --json"
canonical_path: "05-CONFIGURATIONS/pipelines/libs/docker-compose-integration.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:dcintegration-v1.0.0"
generated_at: "2026-05-23T23:30:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "pipelines"
ai_navigation:
  read_first: false
  required_for: ["compose-deployment-pipeline", "vps-health-check"]
  update_frequency: on-change
audience: ["pipelines-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-23"
---

# 🐳 Integração com Docker Compose

> **Contrato modular**: Filho de `pipelines-master-agent-mantis`. Complementa as skills de [[../../docker-compose/libs/00-INDEX.md|docker-compose/libs/]].

## 🎯 Propósito
Definir como os pipelines interagem com stacks Docker Compose, incluindo health checks robustos, deploys em VPS e builds multi-arquitetura (C8).

## 📋 Especificação
- **Entradas**: Nome do VPS, arquivo Compose, tag da imagem.
- **Saídas**: Workflow de deploy funcional.
- **Constraints Aplicáveis**: C8 (qualidade de entrega com health checks).

---

## 🛡️ Padrões

### Health Check Robusto no Compose
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8080/health/ready"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

### Workflow de Deploy a VPS
```yaml
- name: Copiar para VPS
  uses: appleboy/scp-action@v0.1.7
  with:
    host: ${{ secrets.VPS_HOST }}
    key: ${{ secrets.SSH_KEY }}
    source: compose.prod.yml
    target: /opt/mantis
- name: Deploy
  uses: appleboy/ssh-action@v0.1.7
  with:
    host: ${{ secrets.VPS_HOST }}
    key: ${{ secrets.SSH_KEY }}
    script: |
      cd /opt/mantis
      docker compose -f compose.prod.yml up -d --wait
      bash health-check.sh
```

### Build Multi-Arquitetura
```yaml
- uses: docker/build-push-action@v5
  with:
    platforms: linux/amd64,linux/arm64
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_healthcheck_syntax() {
  local tmp; tmp=$(mktemp -d)
  cat > "$tmp/compose.yml" << 'EOF'
services:
  svc:
    image: alpine
    healthcheck:
      test: ["CMD", "true"]
      interval: 10s
EOF
  docker compose -f "$tmp/compose.yml" config --quiet 2>/dev/null && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { command -v docker &>/dev/null && test_healthcheck_syntax && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[pipelines-master-agent.md]]
- [[../../docker-compose/libs/healthcheck-patterns.md]]
- [[../../docker-compose/libs/deployment-strategies.md]]
