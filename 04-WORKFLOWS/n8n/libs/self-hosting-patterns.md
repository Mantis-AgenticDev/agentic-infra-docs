---
artifact_id: "n8n-self-hosting-patterns"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C2","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/self-hosting-patterns.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/self-hosting-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:self-hosting-v1.0.0"
generated_at: "2026-05-24T18:10:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["self-hosting", "docker-deployment", "queue-mode"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🖥️ Padrões de Auto-Hospedagem — Docker Compose, Queue Mode

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Padronizar a implantação de n8n auto-hospedado usando Docker Compose com PostgreSQL, configuração de Queue Mode para escalabilidade e gestão de variáveis de ambiente, garantindo declaração (C2), segurança (C3), validação (C5), resiliência (C7) e observabilidade (C8).

## 📋 Especificação (SDD)
- **Entradas**: Domínio, credenciais de banco, chave de encriptação.
- **Saídas**: `docker-compose.yml` funcional com n8n + PostgreSQL.
- **Constraints Aplicáveis**: C2, C3, C5, C7, C8.

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
self_hosting:
  docker_compose:
    description: "Stack Docker Compose para n8n + PostgreSQL"
    services:
      n8n:
        image: "n8nio/n8n:latest"
        restart: "unless-stopped"
        ports: ["5678:5678"]
        environment:
          N8N_BASIC_AUTH_ACTIVE: "true"
          N8N_BASIC_AUTH_USER: "${N8N_USER}"
          N8N_BASIC_AUTH_PASSWORD: "${N8N_PASSWORD}"
          N8N_HOST: "${N8N_HOST}"
          N8N_PORT: "5678"
          N8N_PROTOCOL: "https"
          NODE_ENV: "production"
          WEBHOOK_URL: "https://${N8N_HOST}/"
          GENERIC_TIMEZONE: "UTC"
          N8N_ENCRYPTION_KEY: "${N8N_ENCRYPTION_KEY}"
          DB_TYPE: "postgresdb"
          DB_POSTGRESDB_HOST: "postgres"
          DB_POSTGRESDB_PORT: "5432"
          DB_POSTGRESDB_DATABASE: "n8n"
          DB_POSTGRESDB_USER: "${POSTGRES_USER}"
          DB_POSTGRESDB_PASSWORD: "${POSTGRES_PASSWORD}"
          EXECUTIONS_DATA_PRUNE: "true"
          EXECUTIONS_DATA_MAX_AGE: "168"
        volumes: ["n8n_data:/home/node/.n8n"]
        depends_on: ["postgres"]
      postgres:
        image: "postgres:15"
        restart: "unless-stopped"
        environment:
          POSTGRES_USER: "${POSTGRES_USER}"
          POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"
          POSTGRES_DB: "n8n"
        volumes: ["postgres_data:/var/lib/postgresql/data"]
        healthcheck:
          test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
          interval: "10s"
          timeout: "5s"
          retries: 5
    volumes: ["n8n_data", "postgres_data"]

  queue_mode:
    description: "Modo fila para escalar workers horizontalmente"
    config:
      main_process: "N8N_QUEUE_MODE=main n8n start"
      worker_process: "N8N_QUEUE_MODE=worker n8n worker"
      redis: "QUEUE_BULL_REDIS_HOST=redis"
      health_check: "QUEUE_HEALTH_CHECK_ACTIVE=true"
    scaling:
      replicas: 3  # Número de workers

  encryption_key:
    description: "Chave de encriptação para credenciais (NUNCA commitar)"
    generation: "openssl rand -hex 32"
    storage: "Variável de ambiente ou arquivo .env (gitignored)"

  resource_requirements:
    low_volume: { cpu: "1 core", ram: "512MB", db: "SQLite" }
    medium_volume: { cpu: "2 cores", ram: "2GB", db: "PostgreSQL" }
    high_volume: { cpu: "4 cores", ram: "4GB", db: "PostgreSQL + Queue Mode" }
    enterprise: { cpu: "8+ cores", ram: "8GB+", db: "PostgreSQL + Queue Mode + Redis" }

  best_practices:
    - "Sempre usar PostgreSQL em produção (nunca SQLite)"
    - "Gerar N8N_ENCRYPTION_KEY única e persistente"
    - "Configurar N8N_HOST e WEBHOOK_URL para o domínio público"
    - "Ativar autenticação básica (N8N_BASIC_AUTH_ACTIVE=true)"
    - "Habilitar execução em fila para workloads > 1000 execuções/dia"
    - "Configurar backup do banco de dados diariamente"
    - "Monitorar uso de disco (execution history) e configurar pruning"
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_docker_compose_has_postgres() {
  grep -q "postgres:" docker-compose.yml 2>/dev/null && return 0 || return 1
}

test_encryption_key_length() {
  local key=$(openssl rand -hex 32 2>/dev/null)
  [[ ${#key} -eq 64 ]] && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && { 
  test_docker_compose_has_postgres && test_encryption_key_length && echo "✅" || echo "❌"
  exit $?
}
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[/05-CONFIGURATIONS/docker-compose/vps1-n8n-uazapi.yml]]
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]]
