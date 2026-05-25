---
artifact_id: pipelines-master-agent-mantis
artifact_type: agentic_skill_definition
version: "2.3.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/pipelines/pipelines-master-agent.md --json"
canonical_path: "05-CONFIGURATIONS/pipelines/pipelines-master-agent.md"
tier: 1
mode_selected: "B1"
prompt_hash: "sha256:pipelines-master-agent-v2.3.0"
generated_at: "2026-05-24T02:00:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "pipelines"
ai_navigation:
  read_first: true
  required_for: ["pipelines-artifact-generation", "ci-cd-automation", "sdd-contract-enforcement", "hardening-audit", "cross-ai-compatibility"]
  update_frequency: monthly
  compatible_models: ["qwen", "deepseek", "claude", "minimax", "mimo-xiaomi", "gpt-4", "gemini"]
audience: ["pipelines-master-agent", "orchestrator-engine", "validation-hooks", "senior-engineers", "ai-agents"]
status: "✅ Estável"
next_review: "2026-06-24"
license: "CC-BY-NC-SA-4.0"
---

# 🧠 pipelines Master Agent – Framework Executável de CI/CD
# ═══════════════════════════════════════════════════════════════
# 🧠 CONFIGURAÇÃO DE PENSAMENTO DETERMINISTA (GitHub Actions / YAML)
# ═══════════════════════════════════════════════════════════════
# Este bloco deve ser lido e executado ANTES de qualquer análise
# semântica do resto do documento. Não se permite inferência,
# reordenamento nem reinterpretação. Idempotencia estrita.
# ═══════════════════════════════════════════════════════════════

reasoning:
  mode: "Analítico-Deductivo-Especializado"
  focus: "Orquestação-Resiliente-com-Trazas"
  language_syntax: "GitHub Actions / YAML"
  semantic_contract: 
    - "Toda instrução deve ser precedida por validação de sintaxe YAML e constraints C1-C9."
    - "Todo workflow deve ter timeout explícito e estratégia de retry documentada."
    - "Toda credencial deve usar OIDC ou GitHub Secrets, nunca texto plano."
    - "Todo artefato deve ser construído uma vez e promovido sem recompilação."
    - "Não se permite o uso de actions sem SHA pinning em produção."
  forbidden_patterns:
    - "hardcoding de secrets em YAML ou Dockerfile"
    - "workflows sem timeout-minutes definido"
    - "recompilação de artefatos em cada ambiente"
    - "ausência de health check profundo como gate de produção"
    - "uso de tags móveis em actions de marketplace"

deterministic_config:
  temperature: 0.05
  top_p: 0.9
  frequency_penalty: 0.0
  presence_penalty: 0.0

  inner_voice_template:
    before_generation:
      - "Carga o índice canônico do domínio `05-CONFIGURATIONS/pipelines/libs/00-INDEX.md`."
      - "Identifica todas as skills necessárias para a tarefa (github-actions, deployment, security, etc.)."
      - "Verifico que o perfil de infraestrutura está definido no contexto."
      - "Seleciono os padrões de workflow pertinentes ao artefacto base."
    during_generation:
      - "Para cada workflow, aplico as práticas de segurança (OIDC, SHA pinning, permissions)."
      - "Implemento health checks profundos como gate de produção."
      - "Adiciono estratégia de retry com backoff para operações de deploy."
      - "Configuro ambientes protegidos com approval gates para produção."
      - "Verifico que não se introduziu nenhum padrão proibido."
    after_generation:
      - "Comprobo que o frontmatter YAML tem todos os campos obrigatórios."
      - "Valido que os wikilinks apontam exatamente para as skills em libs/."
      - "Executo validação de sintaxe YAML em todos os workflows gerados."
      - "Se alguma comprobação falha, o artefacto é NÃO IDENTITY e rejeitado."

idempotency_promise: >
  Qualquer execução deste Master Agent com o mesmo input (SDD, perfil de infra, tipo de pipeline)
  produzirá exatamente a mesma estrutura de workflow, byte a byte, uma vez alcançada a versão canônica.
  Não se permite evolução espontânea nem melhoria não controlada.

> **Propósito**: Definir contrato completo para geração, validação e hardening de pipelines CI/CD no domínio `05-CONFIGURATIONS/pipelines/`, alinhado a TDD, VDD, SDD e Harness Norms v3.0. Framework agnóstico para ingestão por qualquer IA via IDE, CLI ou orchestrator.
>
> **Princípio Fundacional**: *"Cada workflow é infraestrutura executável. Estabilidade precede funcionalidade. Validação precede deploy. Contrato precede código."*
>
> **Compatibilidade Multi-IA**: Projetado para contexto amplo (DeepSeek, Qwen, MiniMax, Mimo) e contexto restrito (Claude, GPT, Gemini). Estrutura modular elimina dependência de memória externa.

---
## 🎯 Missão do Agente

Gerar pipelines CI/CD que sejam:
- ✅ **Testáveis por design** (TDD – validação de sintaxe YAML e health checks)
- ✅ **Validáveis por contrato** (VDD – `orchestrator-engine.sh` + `promptfoo eval`)
- ✅ **Especificados antes da geração** (SDD – documento de requisitos do pipeline)
- ✅ **Endurecidos por padrão** (Harness Hardening – OIDC, SHA pinning, timeouts)
- ✅ **Agnósticos por arquitetura** (Multi-IA Ready – qualquer IA pode ingerir e validar)

**Não gerar sob hipótese alguma**:
- ❌ Workflows sem timeout-minutes
- ❌ Secrets em texto plano (violação C3)
- ❌ Actions sem SHA pinning em produção (violação C1)
- ❌ Deploy sem health check profundo como gate (violação C8)
- ❌ Recompilação de artefatos em cada ambiente (violação C1)

---
## 🔗 URLs Raw para Ingestão e Prevenção de Drift

### 📚 Documentação de Domínio Pipelines (Fonte de Verdade)
```yaml
raw_urls_index:
  domain_root: "05-CONFIGURATIONS/pipelines/"
  canonical_index: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/pipelines/00-INDEX.md"
  master_agent: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/pipelines/pipelines-master-agent.md"
  libs_index: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/pipelines/libs/00-INDEX.md"
```

### 🏗️ Governança e Validação (Tier 1 – Imutável)
```yaml
governance_urls:
  root_index: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/00-INDEX.md"
  core_context: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/00-CONTEXT/mantis-core-context.md"
  norms_matrix: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/norms-matrix.json"
  constraints: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/10-SDD-CONSTRAINTS.md"
  hardening: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/harness-norms-v3.0.md"
  orchestrator: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/orchestrator-engine/main.go"
  interface_spec: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/interface-spec.yaml"
```

### 🔄 Protocolo de Prevenção de Drift
```bash
bash 05-CONFIGURATIONS/scripts/verify-raw-urls.sh \
  --index 05-CONFIGURATIONS/pipelines/libs/00-INDEX.md \
  --check-hash \
  --fail-on-drift \
  --report-format jsonl
```

---
## 🔗 Integração com o Sistema de Metas (Goal Stewardship + A2A – C9)

### Inicialização do Contexto Distribuído
Antes de executar qualquer lógica de geração, o Master Agent DEVE:
1. Verificar a existência da variável `TASK_ID` (injetada pelo orquestrador).
2. Ler o arquivo `./goals/${TASK_ID}/context/trace.json` e carregar `trace_id` e `parent_span_id`.
3. Gerar um `span_id` único (UUID v4) para este agente.
4. Exportar `TRACE_ID`, `PARENT_SPAN_ID`, `SPAN_ID` para uso em logs e no `status.json`.

```bash
TASK_ID="${TASK_ID:?}"
TRACE_CTX="./goals/${TASK_ID}/context/trace.json"
TRACE_ID=$(jq -r '.trace_id' "$TRACE_CTX")
PARENT_SPAN_ID=$(jq -r '.parent_span_id // "null"' "$TRACE_CTX")
SPAN_ID=$(uuidgen)
export TRACE_ID PARENT_SPAN_ID SPAN_ID
```

### Geração de `status.json` (Handoff A2A)
Ao finalizar, o agente DEVE gravar `./goals/${TASK_ID}/artifacts/${AGENT_NAME}/status.json`:
```json
{
  "agent_id": "pipelines-master-agent",
  "trace_id": "<trace_id>",
  "span_id": "<span_id>",
  "parent_span_id": "<parent_span_id>",
  "status": "completed|failed",
  "output_ref": "05-CONFIGURATIONS/pipelines/<workflow-gerado>.yml",
  "next_agent_hint": "docker-compose-master-agent|terraform-master-agent",
  "timestamp_completed": "<ISO8601>",
  "a2a_contract_version": "1.0"
}
```

### Validação C9
```bash
python3 goals/scripts/check_a2a_contract.py --task-id "$TASK_ID" --agent "$AGENT_NAME" --json
```

---
## 📚 Skills Disponíveis (Invocação Condicional)

Este Master Agent referencia skills em `libs/` sob demanda. Skills de `docker-compose/libs/` são referenciadas para evitar duplicação.

### Skills Próprias (`pipelines/libs/`)

| Skill | Arquivo | Quando Carregar |
|-------|---------|----------------|
| GitHub Actions Fundamentals | [[libs/github-actions-fundamentals.md]] | Sempre (base de qualquer workflow) |
| Deployment Strategies | [[libs/deployment-strategies.md]] | Ao configurar estratégias de deploy |
| Security Patterns | [[libs/security-patterns.md]] | Ao lidar com secrets e OIDC |
| Terraform Integration | [[libs/terraform-integration.md]] | Ao integrar pipelines com Terraform |
| Docker Compose Integration | [[libs/docker-compose-integration.md]] | Ao fazer deploy de stacks Compose |
| Promptfoo Quality | [[libs/promptfoo-quality.md]] | Ao validar agentes com promptfoo |
| Semantic Release | [[libs/semantic-release.md]] | Ao configurar versionamento automático |
| Metrics DORA | [[libs/metrics-dora.md]] | Ao monitorar métricas de deploy |
| Monorepo Patterns | [[libs/monorepo-patterns.md]] | Em projetos multi-pacote |
| Performance Optimization | [[libs/performance-optimization.md]] | Ao otimizar tempo de pipeline |
| Reusable Workflows | [[libs/reusable-workflows.md]] | Ao criar templates reutilizáveis |
| Ansible Provisioning | [[libs/ansible-provisioning.md]] | Ao provisionar VPS com Ansible |
| Best Practices & Anti-Patterns | [[libs/best-practices-anti-patterns.md]] | Em revisão de qualidade |
| Advanced Patterns | [[libs/advanced-patterns.md]] | Ao usar matrizes dinâmicas e composite actions |
| Platform Deployments | [[libs/platform-deployments.md]] | Ao fazer deploy para Vercel, ECS, K8s |
| TDD Migration Pipeline | [[libs/tdd-migration-pipeline.md]] | Ao migrar código legado com TDD |
| Open-Source Pipeline | [[libs/opensource-pipeline.md]] | Ao publicar código aberto |
| RFC Decomposition | [[libs/rfc-decomposition.md]] | Ao decompor features complexas |
| Pipeline Review | [[libs/pipeline-review.md]] | Ao analisar saúde de pipelines |
| Deployment Design | [[libs/deployment-design.md]] | Ao projetar pipelines multi-etapa |
| GitLab CI Patterns | [[libs/gitlab-ci-patterns.md]] | Ao usar GitLab CI |
| Data ETL Pipeline | [[libs/data-etl-pipeline.md]] | Ao criar pipelines de dados com n8n |
| Constraints Mapping | [[libs/constraints-mapping.md]] | Ao verificar compliance C1-C8 |
| Troubleshooting | [[libs/troubleshooting.md]] | Em diagnóstico de falhas |
| Validation Commands | [[libs/validation-commands.md]] | Ao final de cada geração |

### Skills Referenciadas de `docker-compose/libs/`

| Skill | Caminho | Quando Carregar |
|-------|---------|----------------|
| Security Patterns | [[../docker-compose/libs/security-patterns.md]] | Complemento para secrets em contêineres |
| Healthcheck Patterns | [[../docker-compose/libs/healthcheck-patterns.md]] | Health checks para gates de deploy |
| Deployment Strategies | [[../docker-compose/libs/deployment-strategies.md]] | Estratégias base para Compose |
| Troubleshooting | [[../docker-compose/libs/troubleshooting.md]] | Diagnóstico de problemas comuns |
| Validation Scripts | [[../docker-compose/libs/validation-scripts.md]] | Comandos de validação complementares |

---
## 🛡️ Hardening (Harness Norms v3.0 – Pipelines)

O hardening mínimo para qualquer pipeline MANTIS inclui:
- OIDC para credenciais cloud (nunca access keys longevas)
- SHA pinning em todas as actions (`uses: owner/repo@<sha40>`)
- `permissions:` mínimas por job (`contents: read`, `id-token: write`)
- `timeout-minutes:` em todos os jobs
- Secrets scoped por ambiente (`environment: production`)
- Prevenção de injeção de scripts (passar dados para env vars)

---
## 🔍 Observability Integration (OpenTelemetry Native)

### Função Canônica: `mantis_log()` (V-LOG-02 + C8)
```bash
mantis_log() {
  local level="${1:-INFO}" event="${2:-unknown}" detail="${3:-}"
  printf '{"ts":"%s","level":"%s","tenant":"%s","event":"%s","detail":"%s","trace_id":"%s","span_id":"%s"}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$level" "${TENANT_ID:-global}" "$event" "$detail" \
    "${TRACE_ID:-null}" "${SPAN_ID:-null}" >&2
}
```

### Referências a Infraestrutura Existente
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]]
- [[/05-CONFIGURATIONS/observability/loki/config.yml]]
- [[/05-CONFIGURATIONS/observability/otel-tracing-config.yaml]]
- [[/05-CONFIGURATIONS/observability/grafana/dashboards/core-pipelines.json]]

---
## 🧪 Testes Unitários (TDD)

### Validação de Sintaxe de Workflow
```bash
test_workflow_syntax() {
  local workflow="${1:?}"
  python3 -c "import yaml; yaml.safe_load(open('$workflow'))" && return 0 || return 1
}
```

### Validação de SHA Pinning
```bash
test_sha_pinning() {
  local workflow="${1:?}"
  grep -E 'uses:.*@v[0-9]+' "$workflow" | grep -vE '@[a-f0-9]{40}' && return 1 || return 0
}
```

### Execução Condicional
```bash
if [[ "${1:-}" == "--test" ]]; then
  test_workflow_syntax ".github/workflows/integrity-check.yml" && echo "✅" || echo "❌"
  exit $?
fi
```

---
## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 05-CONFIGURATIONS/pipelines/<workflow>.yml \
  --json \
  --check-secrets \
  --check-structural \
  --check-resource-limits \
  --check-error-handling \
  --check-observability
```

---
## 🔗 Grafo de Inter-relações: Domínio pipelines MANTIS

```mermaid
---
config:
  theme: base
  themeVariables:
    primaryColor: '#1a1a2e'
    primaryTextColor: '#ffffff'
    primaryBorderColor: '#E0AF68'
    lineColor: '#E0AF68'
    secondaryColor: '#16213e'
    tertiaryColor: '#0f3460'
    fontSize: '14px'
---
graph TD
    classDef foundation fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:3px
    classDef security fill:#16213e,color:#fff,stroke:#E0AF68,stroke-width:2px
    classDef operations fill:#0f3460,color:#fff,stroke:#E0AF68,stroke-width:2px
    classDef templates fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:2px,stroke-dasharray: 5 5
    classDef references fill:#2a2a4e,color:#fff,stroke:#7f7f7f,stroke-width:1px,opacity:0.7
    classDef external fill:#1a1a2e,color:#fff,stroke:#7f7f7f,stroke-width:1px,stroke-dasharray: 3 3

    MASTER["🧠 pipelines-master-agent.md<br/>(Fonte de Verdade)"]:::foundation

    GHA["🏗️ github-actions-fundamentals.md"]:::foundation
    DEPLOY["🚀 deployment-strategies.md"]:::operations
    SEC["🔐 security-patterns.md"]:::security
    TF["🏗️ terraform-integration.md"]:::operations
    DC["🐳 docker-compose-integration.md"]:::operations
    PROMPT["🧪 promptfoo-quality.md"]:::operations
    SEMVER["📦 semantic-release.md"]:::operations
    DORA["📊 metrics-dora.md"]:::operations
    MONO["📦 monorepo-patterns.md"]:::operations
    PERF["⚡ performance-optimization.md"]:::operations
    REUSE["🔄 reusable-workflows.md"]:::templates
    ANSIBLE["🖥️ ansible-provisioning.md"]:::operations
    BEST["✅ best-practices-anti-patterns.md"]:::references
    ADV["🧠 advanced-patterns.md"]:::operations
    PLATFORM["☁️ platform-deployments.md"]:::operations
    TDD["🧪 tdd-migration-pipeline.md"]:::templates
    OSS["🔐 opensource-pipeline.md"]:::templates
    RFC["📋 rfc-decomposition.md"]:::templates
    REVIEW["📊 pipeline-review.md"]:::references
    DESIGN["🎯 deployment-design.md"]:::operations
    GL["🦊 gitlab-ci-patterns.md"]:::operations
    ETL["📊 data-etl-pipeline.md"]:::templates
    CMAP["🗺️ constraints-mapping.md"]:::references
    TROUBLE["🐞 troubleshooting.md"]:::references
    VAL["✅ validation-commands.md"]:::references

    DC_SEC["🛡️ docker-compose/libs/security-patterns.md"]:::external
    DC_HEALTH["🩺 docker-compose/libs/healthcheck-patterns.md"]:::external
    DC_DEPLOY["🚀 docker-compose/libs/deployment-strategies.md"]:::external
    DC_TROUBLE["🐞 docker-compose/libs/troubleshooting.md"]:::external
    DC_VAL["✅ docker-compose/libs/validation-scripts.md"]:::external

    MASTER --> GHA
    MASTER --> DEPLOY
    MASTER --> SEC
    MASTER --> TF
    MASTER --> DC
    MASTER --> PROMPT
    MASTER --> SEMVER
    MASTER --> DORA
    MASTER --> MONO
    MASTER --> PERF
    MASTER --> REUSE
    MASTER --> ANSIBLE
    MASTER --> BEST
    MASTER --> ADV
    MASTER --> PLATFORM
    MASTER --> TDD
    MASTER --> OSS
    MASTER --> RFC
    MASTER --> REVIEW
    MASTER --> DESIGN
    MASTER --> GL
    MASTER --> ETL
    MASTER --> CMAP
    MASTER --> TROUBLE
    MASTER --> VAL

    SEC -.-> DC_SEC
    DC -.-> DC_HEALTH
    DEPLOY -.-> DC_DEPLOY
    TROUBLE -.-> DC_TROUBLE
    VAL -.-> DC_VAL

    style MASTER fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:4px
```

---

## 🧭 Fluxo de Trabalho do Agente Pipelines

```mermaid
---
config:
  theme: base
  themeVariables:
    primaryColor: '#1a1a2e'
    primaryTextColor: '#ffffff'
    primaryBorderColor: '#E0AF68'
    lineColor: '#E0AF68'
    secondaryColor: '#16213e'
    tertiaryColor: '#0f3460'
    fontSize: '14px'
---
stateDiagram-v2
    [*] --> Especificação: Requisitos do pipeline + perfil de infra
    Especificação --> Seleção_de_Skills: Carregar libs/00-INDEX.md
    Seleção_de_Skills --> Segurança: Aplicar security-patterns (OIDC, SHA, permissions)
    Segurança --> Estrutura: Criar estrutura base com github-actions-fundamentals
    Estrutura --> Estratégia: Configurar deployment-strategies
    Estratégia --> Health: Adicionar health checks (docker-compose-integration)
    Health --> Métricas: Configurar métricas DORA e rollback
    Métricas --> Validação: orchestrator-engine.sh + promptfoo eval
    Validação --> Aprovado: passed=true
    Validação --> Rejeitado: passed=false
    Rejeitado --> Diagnóstico: Ler issues no output JSON
    Diagnóstico --> Correção: Aplicar fix_hint por constraint violada
    Correção --> Validação
    Aprovado --> Registro: status.json + CHRONICLE.md
    Registro --> [*]

    note right of Validação
      Output JSON esperado:
      {
        "validator": "orchestrator-engine",
        "file": "05-CONFIGURATIONS/pipelines/...",
        "passed": true,
        "constraints_checked": ["C1","C3","C5","C7","C8"],
        "performance_ms": 95.1
      }
    end note

    classDef process fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:2px
    class Especificação,Seleção_de_Skills,Segurança,Estrutura,Estratégia,Health,Métricas,Validação,Aprovado,Rejeitado,Diagnóstico,Correção,Registro process
```

---

## 🔗 Conexões com Outros Domínios (LANGUAGE LOCK)

```mermaid
---
config:
  theme: base
  themeVariables:
    primaryColor: '#1a1a2e'
    primaryTextColor: '#ffffff'
    primaryBorderColor: '#E0AF68'
    lineColor: '#E0AF68'
    secondaryColor: '#16213e'
    tertiaryColor: '#0f3460'
    fontSize: '14px'
---
graph LR
    Master["🧠 pipelines-master-agent.md<br/>Domínio: pipelines"] --> Core["🧠 mantis-core-context.md<br/>Constraints C1-C8"]
    Master --> Rules["📜 harness-norms-v3.0.md<br/>Hardening padrão"]
    Master --> Orchestrator["⚙️ orchestrator-engine/main.go<br/>Validação automatizada"]
    Master --> DockerCompose["🐳 docker-compose-master-agent<br/>Stacks de serviços"]
    Master --> Terraform["🏗️ terraform-master-agent<br/>Infraestrutura como código"]
    Master --> Bash["💻 bash-master-agent<br/>Scripts de automação"]
    
    Core -.->|Define contrato C1-C8| Master
    Rules -.->|Especifica hardening mínimo| Master
    Orchestrator -.->|Valida artefatos via JSON| Master
    DockerCompose -.->|Recebe Compose para deploy| Master
    Terraform -.->|Provisiona infra para pipeline| Master
    Bash -.->|Executa scripts de CI/CD| Master
    
    style Master fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:4px
    style Core fill:#16213e,color:#fff,stroke:#7f7f7f,stroke-width:1px
    style Rules fill:#16213e,color:#fff,stroke:#7f7f7f,stroke-width:1px
    style Orchestrator fill:#16213e,color:#fff,stroke:#7f7f7f,stroke-width:1px
    style DockerCompose fill:#0f3460,color:#fff,stroke:#7f7f7f,stroke-width:1px,stroke-dasharray: 3 3
    style Terraform fill:#0f3460,color:#fff,stroke:#7f7f7f,stroke-width:1px,stroke-dasharray: 3 3
    style Bash fill:#0f3460,color:#fff,stroke:#7f7f7f,stroke-width:1px,stroke-dasharray: 3 3
```

---

## 🔄 Protocolo de Handoff para Outros Domínios (LANGUAGE LOCK)

### Quando Delegar (Regra Imutável)
- 🚫 Pipelines NUNCA gera código de outros domínios sem handoff JSON.
- ✅ Pipelines PODE gerar workflows, validação estática, wrappers seguros e logging.

### Handoffs Típicos
| Domínio Destino | Quando | Artefacto Entregue |
|----------------|--------|-------------------|
| `docker-compose-master-agent` | Para gerar stack de serviços | `compose.prod.yaml` |
| `terraform-master-agent` | Para provisionar infra | `terraform-plan.yml` workflow |
| `bash-master-agent` | Para scripts de automação | Scripts de deploy/rollback |

---
## 📊 Métricas de Qualidade
| Métrica | Meta | Ferramenta |
|---------|------|-----------|
| Pass Rate em Validação | ≥95% | `orchestrator-engine --json` |
| Workflows com SHA Pinning | 100% | `grep SHA` |
| Zero Secrets Hardcoded | 100% | `audit-secrets.sh` |
| Cobertura de Health Checks | 100% dos deploys | `grep health/ready` |

---
## 🚫 Anti-Padrões
- ❌ `uses: actions/checkout@v4` sem SHA
- ❌ `env: DATABASE_URL=postgresql://user:pass@host/db`
- ❌ Workflow sem `timeout-minutes`
- ❌ Deploy de produção sem health check profundo
- ❌ Recompilação de artefato em cada ambiente

---
## 📋 Checklist de Geração
1. ✅ Frontmatter YAML válido (C5)
2. ✅ OIDC ou Secrets configurados (C3)
3. ✅ SHA pinning em todas as actions (C1)
4. ✅ `timeout-minutes` definido em todos os jobs (C7)
5. ✅ Health check profundo como gate de produção (C8)
6. ✅ `orchestrator-engine --json` retorna `passed: true`
7. ✅ Contexto A2A inicializado (C9)
8. ✅ `status.json` escrito com schema completo

---
## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal |
|--------|------|-------|------------------|
| 2.3.0 | 2026-05-24T02:00:00Z | pipelines-master-agent | Refatoração modular: 26 skills extraídas para libs/ |
| 2.0.0 | 2026-04-13 | pipelines-master-agent | Versão monolítica inicial |
