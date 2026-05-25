---
artifact_id: "procedures-operations-langsmith-sop"
artifact_type: "standard_operating_procedure"
version: "2.3.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
canonical_path: "07-PROCEDURES/operations-langsmith-langchain-langraph-sop.md"
tier: 1
immutable: false
requires_human_approval_for_changes: true
audience: ["human-architects","agentic-assistants","orchestrator-engine","devops","sre","platform-engineers"]
language_lock: "pt-BR"
prompt_hash: "sha256:operations-langsmith-sop-v2.3.0"
generated_at: "2026-05-28T11:30:00Z"
domain: "procedures"
subdomain: "operations-langsmith"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---

# 🚀 Procedimento Operacional Padrão — LangChain/LangGraph: Operações LangSmith

**Objetivo**: Estabelecer o fluxo de trabalho completo para deploy, escalonamento, operação, CI/CD, debugging temporal e tracing distribuído da plataforma LangSmith usando as 11 skills do subdomínio `08-operaciones-langsmith` no ecossistema LangChain/LangGraph dentro de `04-WORKFLOWS/langchain-langraph/`.

**Público-alvo**: Arquitetos humanos, agentes mestres, engenheiros de plataforma, DevOps, SREs, operadores de infraestrutura.

---

## 1. Visão Geral do Subdomínio

O subdomínio `08-operaciones-langsmith` contém **11 skills** que cobrem a operação completa da plataforma LangSmith:

| # | Skill | Propósito |
|---|-------|-----------|
| 1 | `time-travel-debugging.md` | Depuração temporal via API do Agent Server |
| 2 | `distributed-tracing-server.md` | Propagação de traces distribuídos |
| 3 | `webhook-integration.md` | Webhooks para notificações de runs |
| 4 | `data-plane-infra.md` | Infraestrutura do Data Plane |
| 5 | `control-plane-management.md` | Gestão da API do Control Plane |
| 6 | `scaling-performance-tuning.md` | Planejamento de capacidade e tuning |
| 7 | `cicd-pipeline-agents.md` | Pipeline CI/CD para agentes |
| 8 | `standalone-deployment.md` | Deploy autônomo com Docker/K8s |
| 9 | `deploy-with-control-plane.md` | Deploy via Control Plane |
| 10 | `langsmith-quick-deploy.md` | Deploy rápido no LangSmith Cloud |
| 11 | `mission-control-operations.md` | Operação via Mission Control |

### 1.1 Conexão com o Ecossistema `goals/`

```mermaid
graph TD
    CEO["🏭 workflows-ceo"] -->|1. Consulta| STACK["00-STACK-SELECTOR.md"]
    STACK -->|2. Resolve motor| LANG["🦜 langchain-langraph-master-agent"]
    LANG -->|3. Seleciona domínio| OPS["08-operaciones-langsmith (11 skills)"]
    OPS -->|4. Gera configuração| ART["Artefacto .md com operações"]
    ART -->|5. Valida| VAL["orchestrator-engine.sh"]
    VAL -->|6. Handoff A2A| STATUS["status.json + trace.json"]
    STATUS -->|7. Consolida| CEO
```

---

## 2. Mapa de Skills e Inter-relações

```mermaid
graph TD
    MASTER["🦜 langchain-langraph-master-agent"]:::foundation

    subgraph "Debugging e Observabilidade"
        TIME["time-travel-debugging.md"]:::debug
        TRACE["distributed-tracing-server.md"]:::debug
        WEBHOOK["webhook-integration.md"]:::debug
    end

    subgraph "Infraestrutura"
        DATA_PLANE["data-plane-infra.md"]:::infra
        CONTROL_PLANE["control-plane-management.md"]:::infra
        SCALING["scaling-performance-tuning.md"]:::infra
    end

    subgraph "Deploy e CI/CD"
        CICD["cicd-pipeline-agents.md"]:::deploy
        STANDALONE["standalone-deployment.md"]:::deploy
        CONTROL_DEPLOY["deploy-with-control-plane.md"]:::deploy
        QUICK_DEPLOY["langsmith-quick-deploy.md"]:::deploy
    end

    subgraph "Operação"
        MISSION["mission-control-operations.md"]:::ops
    end

    MASTER --> TIME
    MASTER --> TRACE
    MASTER --> WEBHOOK
    MASTER --> DATA_PLANE
    MASTER --> CONTROL_PLANE
    MASTER --> SCALING
    MASTER --> CICD
    MASTER --> STANDALONE
    MASTER --> CONTROL_DEPLOY
    MASTER --> QUICK_DEPLOY
    MASTER --> MISSION

    DATA_PLANE --> SCALING
    DATA_PLANE --> CONTROL_PLANE
    CONTROL_PLANE --> CONTROL_DEPLOY
    STANDALONE --> DATA_PLANE
    CICD --> CONTROL_DEPLOY
    CICD --> STANDALONE
    TRACE --> WEBHOOK
    TIME --> DATA_PLANE
    MISSION --> DATA_PLANE
    MISSION --> CONTROL_PLANE

    classDef foundation fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:3px
    classDef debug fill:#16213e,color:#fff,stroke:#E0AF68,stroke-width:2px
    classDef infra fill:#0f3460,color:#fff,stroke:#E0AF68,stroke-width:2px
    classDef deploy fill:#1a1a2e,color:#fff,stroke:#7f7f7f,stroke-width:1px
    classDef ops fill:#16213e,color:#fff,stroke:#E0AF68,stroke-width:2px

    class MASTER foundation
    class TIME,TRACE,WEBHOOK debug
    class DATA_PLANE,CONTROL_PLANE,SCALING infra
    class CICD,STANDALONE,CONTROL_DEPLOY,QUICK_DEPLOY deploy
    class MISSION ops
```

---

## 3. Fluxo de Geração de Configuração de Operações

```mermaid
stateDiagram-v2
    [*] --> Especificação: Requisitos de operação e deploy
    Especificação --> Seleção_de_Skills: Carregar 08-operaciones-langsmith/00-INDEX.md
    Seleção_de_Skills --> Infra: Configurar Data Plane e Control Plane
    Infra --> Scaling: Planejar capacidade e tuning
    Scaling --> Deploy: Selecionar estratégia de deploy
    Deploy --> CI_CD: Configurar pipeline CI/CD
    CI_CD --> Debug: Configurar time travel e tracing
    Debug --> Operação: Configurar Mission Control e webhooks
    Operação --> Validação: orchestrator-engine.sh --json
    Validação --> Aprovado: passed=true
    Validação --> Rejeitado: passed=false
    Rejeitado --> Diagnóstico: Ler issues_by_severity
    Diagnóstico --> Correção: Aplicar fix_hint
    Correção --> Validação
    Aprovado --> Registro: status.json + CHRONICLE.md
    Registro --> [*]
```

---

## 4. Conexão com Outros Domínios

```mermaid
graph LR
    OPS["🚀 08-operaciones-langsmith<br/>11 skills"] --> Master["🦜 langchain-langraph-master-agent"]
    Master --> DB["🗄️ 05-bases-datos<br/>Infra de persistência"]
    Master --> Seguranca["🔒 09-seguridad<br/>Auth e secrets"]
    Master --> Observabilidade["📊 10-observabilidad<br/>Telemetria"]
    Master --> Swarm["🐝 11-swarm-supervisor<br/>Deploy de enxames"]
    Master --> API["⚙️ 12-langgraph-api<br/>Runtime LangGraph"]

    DB -.->|PostgreSQL, Redis| OPS
    Seguranca -.->|Autenticação| OPS
    Observabilidade -.->|Métricas e logs| OPS
    Swarm -.->|Deploy de agentes| OPS
    API -.->|Execução de grafos| OPS

    classDef opsStyle fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:4px
    classDef depStyle fill:#0f3460,color:#fff,stroke:#E0AF68,stroke-width:2px

    class OPS opsStyle
    class Master,DB,Seguranca,Observabilidade,Swarm,API depStyle
```

---

## 5. Estrutura de Diretórios

```
04-WORKFLOWS/langchain-langraph/libs/08-operaciones-langsmith/
├── time-travel-debugging.md              # Time travel via Agent Server API
├── distributed-tracing-server.md         # Propagação de traces
├── webhook-integration.md                # Webhooks e notificações
├── data-plane-infra.md                   # Infra do Data Plane
├── control-plane-management.md           # API do Control Plane
├── scaling-performance-tuning.md         # Planejamento de capacidade
├── cicd-pipeline-agents.md               # Pipeline CI/CD
├── standalone-deployment.md              # Deploy com Docker/K8s
├── deploy-with-control-plane.md          # Deploy via Control Plane
├── langsmith-quick-deploy.md             # Deploy rápido
└── mission-control-operations.md         # Mission Control
```

---

## 6. Exemplos de Código e Padrões

### 6.1 Time Travel Debugging (time-travel-debugging.md)

```python
from langgraph_sdk import get_client

client = get_client(url="https://meu-deploy.langgraph.app")

# Listar checkpoints
states = await client.threads.get_history("thread-123")

# Voltar a um checkpoint específico
result = await client.threads.update_state(
    "thread-123",
    {"topic": "novo topico"},
    checkpoint_id=states[1]["checkpoint_id"]
)

# Re-executar a partir do checkpoint modificado
run = await client.runs.wait(
    "thread-123",
    "agent",
    input=None,
    checkpoint_id=result["checkpoint_id"]
)
```

### 6.2 Distributed Tracing (distributed-tracing-server.md)

```python
from langgraph.pregel.remote import RemoteGraph

remote = RemoteGraph(
    "agent",
    url="https://meu-deploy.langgraph.app",
    distributed_tracing=True
)

# O trace é propagado automaticamente
result = remote.invoke({
    "messages": [{"role": "user", "content": "Olá"}]
})
```

### 6.3 Webhook Integration (webhook-integration.md)

```python
async for chunk in client.runs.stream(
    thread_id="thread-123",
    assistant_id="agent",
    input={"messages": [{"role": "user", "content": "Olá"}]},
    stream_mode="events",
    webhook="https://meu-servidor.com/webhook"
):
    pass  # O webhook será chamado ao final do run
```

### 6.4 Standalone Deployment com Docker (standalone-deployment.md)

```yaml
# docker-compose.yml
services:
  langgraph-api:
    image: meu-agente:latest
    ports:
      - "8123:8000"
    environment:
      REDIS_URI: "redis://redis:6379"
      DATABASE_URI: "postgres://postgres:postgres@postgres:5432/postgres"
      LANGSMITH_API_KEY: "${LANGSMITH_API_KEY}"
    depends_on:
      redis:
        condition: service_healthy
      postgres:
        condition: service_healthy
```

### 6.5 CI/CD Pipeline (cicd-pipeline-agents.md)

```yaml
# .github/workflows/deploy.yml
name: Deploy Agent
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build Docker image
        run: langgraph build -t meu-agente:latest
      - name: Push to registry
        run: docker push meu-agente:latest
      - name: Deploy via Control Plane API
        run: |
          curl -X POST https://api.smith.langchain.com/v1/deployments \
            -H "Authorization: Bearer $LANGSMITH_API_KEY" \
            -d '{"name": "meu-agente", "image_url": "meu-agente:latest"}'
```

---

## 7. Processo de Validação

### 7.1 Comandos de Validação por Artefacto

```bash
# Validação de skill individual
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/08-operaciones-langsmith/standalone-deployment.md \
  --json

# Validação completa do subdomínio 08-operaciones-langsmith
for f in 04-WORKFLOWS/langchain-langraph/libs/08-operaciones-langsmith/*.md; do
  bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file "$f" --json
done
```

### 7.2 Checklist de Validação

| # | Verificação | Constraint | Comando | ✅ Esperado |
|---|---|---|---|---|
| 1 | Frontmatter YAML válido | C5 | `validate-frontmatter.sh` | passed=true |
| 2 | Bootstrap com mantis_log | C8 | `grep 'def mantis_log' <file>` | Encontrado |
| 3 | Testes TDD presentes | C5 | `grep 'def test_' <file>` | ≥3 testes |
| 4 | API keys via env vars | C3 | `audit-secrets.sh` | Zero hardcoded |
| 5 | Healthcheck configurado | C7 | `grep 'health\|/ok' <file>` | Endpoint presente |
| 6 | Timeout/retry em chamadas | C1 | `grep 'retry\|timeout' <file>` | Configurado |
| 7 | Tracing propagado | C8 | `grep 'distributed_tracing\|trace' <file>` | Presente |
| 8 | CI/CD pipeline definido | C7 | `grep 'github.workflows\|deploy.yml' <file>` | Estrutura YAML |

---

## 8. Troubleshooting

| Sintoma | Causa Provável | Diagnóstico | Solução |
|---------|---------------|-------------|---------|
| `Agent Server não inicia` | Redis/Postgres inacessível | `docker-compose logs langgraph-api` | Verificar serviços dependentes |
| `Deploy via Control Plane falha` | API key inválida ou sem permissão | `curl -I https://api.smith.langchain.com` | Verificar credenciais |
| `Time travel não funciona` | Checkpointer não configurado | `client.threads.get_history()` | Compilar grafo com checkpointer |
| `Webhook não recebido` | URL inacessível ou firewall | `curl -X POST <webhook_url>` | Testar conectividade |
| `Autoescalonamento não ocorre` | Métricas não expostas | `kubectl top pods` | Verificar Prometheus |
| `Mission Control não carrega` | Port-forward não ativo | `kubectl get svc -n langsmith` | Executar port-forward |
| `Pipeline CI/CD quebrado` | Secrets não configurados | `gh secret list` | Adicionar secrets no repositório |
| `Scaling inadequado` | N_JOBS_PER_WORKER mal configurado | `kubectl describe deployment` | Ajustar variáveis de ambiente |

---

## 9. Referências Cruzadas

- [[04-WORKFLOWS/langchain-langraph/langchain-langraph-master-agent.md]]
- [[04-WORKFLOWS/langchain-langraph/libs/08-operaciones-langsmith/time-travel-debugging.md]]
- [[04-WORKFLOWS/langchain-langraph/libs/08-operaciones-langsmith/standalone-deployment.md]]
- [[04-WORKFLOWS/langchain-langraph/libs/08-operaciones-langsmith/cicd-pipeline-agents.md]]
- [[04-WORKFLOWS/langchain-langraph/libs/08-operaciones-langsmith/mission-control-operations.md]]
- [[04-WORKFLOWS/langchain-langraph/libs/08-operaciones-langsmith/scaling-performance-tuning.md]]
- [[04-WORKFLOWS/workflows-ceo.md]]
- [[04-WORKFLOWS/00-STACK-SELECTOR.md]]
- [[05-CONFIGURATIONS/validation/orchestrator-engine.sh]]
- [[07-PROCEDURES/a2a-langsmith-langchain-langraph-sop.md]]
- [[07-PROCEDURES/security-langchain-langraph-sop.md]]

---

> **Versão 2.3.0** | Procedimento Operacional Padrão do subdomínio `08-operaciones-langsmith` — MANTIS Agentic.
> Aplicável a partir de 2026-05-28.
