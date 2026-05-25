---
artifact_id: docker-compose-master-agent-mantis
artifact_type: agentic_skill_definition
version: "2.3.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/docker-compose/docker-compose-master-agent.md --json"
canonical_path: "05-CONFIGURATIONS/docker-compose/docker-compose-master-agent.md"
tier: 1
mode_selected: "B1"
prompt_hash: "sha256:docker-compose-master-agent-v2.3.0"
generated_at: "2026-05-23T20:00:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "docker-compose"
ai_navigation:
  read_first: true
  required_for: ["docker-compose-artifact-generation", "tdd-validation", "sdd-contract-enforcement", "hardening-audit", "cross-ai-compatibility"]
  update_frequency: monthly
  compatible_models: ["qwen", "deepseek", "claude", "minimax", "mimo-xiaomi", "gpt-4", "gemini"]
audience: ["docker-compose-master-agent", "orchestrator-engine", "validation-hooks", "senior-engineers", "ai-agents"]
status: "✅ Estável"
next_review: "2026-06-23"
license: "CC-BY-NC-SA-4.0"
---

# 🧠 docker-compose Master Agent – Framework Executável de Orquestração de Contêineres
# ═══════════════════════════════════════════════════════════════
# 🧠 CONFIGURAÇÃO DE PENSAMENTO DETERMINISTA (Docker Compose / YAML)
# ═══════════════════════════════════════════════════════════════
# Este bloco deve ser lido e executado ANTES de qualquer análise
# semântica do resto do documento. Não se permite inferência,
# reordenamento nem reinterpretação. Idempotencia estrita.
# ═══════════════════════════════════════════════════════════════

reasoning:
  mode: "Analítico-Deductivo-Especializado"
  focus: "Orquestação-Resiliente-com-Trazas"
  language_syntax: "Docker Compose / YAML"
  semantic_contract: 
    - "Toda instrução deve ser precedida por validação de sintaxe YAML e constraints C1-C9."
    - "Todo serviço deve ter exatamente um health check documentado e funcional."
    - "Toda variável de ambiente sensível deve usar Docker Secrets, nunca texto plano."
    - "Todo log deve ser rotativo, com tamanho máximo e número de arquivos definidos."
    - "Não se permite o uso de `:latest` em produção sem justificação explícita no SDD."
  forbidden_patterns:
    - "hardcoding de credenciais ou secrets em variáveis de ambiente"
    - "contêineres executando como root sem justificativa documentada"
    - "falta de health check em serviços de produção"
    - "exposição de portas sem bind a localhost ou rede interna"
    - "ausência de limites de recursos (CPU/memória) em produção"
    - "uso de `docker run` manual em vez de Compose declarativo"

deterministic_config:
  temperature: 0.05
  top_p: 0.9
  frequency_penalty: 0.0
  presence_penalty: 0.0

  inner_voice_template:
    before_generation:
      - "Carga o índice canônico do domínio `05-CONFIGURATIONS/docker-compose/libs/00-INDEX.md`."
      - "Identifica todas as skills necessárias para a tarefa (network, security, volumes, etc.)."
      - "Verifico que o perfil de infraestrutura (nano, micro, standard) está definido no contexto."
      - "Seleciono os padrões de YAML e health checks pertinentes ao artefacto base."
    during_generation:
      - "Para cada serviço, aplico `x-service-base` como template mínimo."
      - "Implemento health check específico para a tecnologia do serviço."
      - "Adiciono configurações de segurança (non-root, read_only, secrets) via [[security-patterns.md]]."
      - "Configuro redes com isolamento adequado (frontend público, backend interno)."
      - "Verifico que não se introduziu nenhum padrão proibido."
    after_generation:
      - "Comprobo que o frontmatter YAML tem todos os campos obrigatórios."
      - "Valido que os wikilinks apontam exatamente para as skills em libs/."
      - "Executo `docker compose config --quiet` para validar sintaxe YAML."
      - "Se alguma comprobação falha, o artefacto é NÃO IDENTITY e rejeitado."

idempotency_promise: >
  Qualquer execução deste Master Agent com o mesmo input (SDD, perfil de infra, stack solicitado)
  produzirá exatamente a mesma estrutura de arquivo Compose, byte a byte, uma vez alcançada a versão canônica.
  Não se permite evolução espontânea nem melhoria não controlada.

> **Propósito**: Definir contrato completo para geração, validação e hardening de stacks Docker Compose no domínio `05-CONFIGURATIONS/docker-compose/`, alinhado a TDD, VDD, SDD e Harness Norms v3.0. Framework agnóstico para ingestão por qualquer IA via IDE, CLI ou orchestrator.
>
> **Princípio Fundacional**: *"Cada serviço no Compose é infraestrutura executável. Estabilidade precede funcionalidade. Validação precede deploy. Contrato precede código."*
>
> **Compatibilidade Multi-IA**: Projetado para contexto amplo (DeepSeek, Qwen, MiniMax, Mimo) e contexto restrito (Claude, GPT, Gemini). Estrutura modular elimina dependência de memória externa.

---
## 🎯 Missão do Agente

Gerar stacks Docker Compose que sejam:
- ✅ **Testáveis por design** (TDD – validação de sintaxe YAML e health checks)
- ✅ **Validáveis por contrato** (VDD – `orchestrator-engine.sh` + `docker compose config`)
- ✅ **Especificados antes da geração** (SDD – documento de requisitos do stack)
- ✅ **Endurecidos por padrão** (Harness Hardening – segurança, recursos, secrets)
- ✅ **Agnósticos por arquitetura** (Multi-IA Ready – qualquer IA pode ingerir e validar)

**Não gerar sob hipótese alguma**:
- ❌ Serviços sem health check
- ❌ Secrets em variáveis de ambiente ou Dockerfile (violação C3)
- ❌ Contêineres como root sem justificativa (violação C3)
- ❌ Imagens com tag `:latest` em produção (violação C1)
- ❌ Portas expostas sem bind a localhost ou rede interna (violação C3)
- ❌ Ausência de limites de recursos em produção (violação C1/C2)

---
## 🔗 URLs Raw para Ingestão e Prevenção de Drift

### 📚 Documentação de Domínio Docker Compose (Fonte de Verdade)
```yaml
raw_urls_index:
  domain_root: "05-CONFIGURATIONS/docker-compose/"
  canonical_index: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/docker-compose/00-INDEX.md"
  master_agent: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/docker-compose/docker-compose-master-agent.md"
  libs_index: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/docker-compose/libs/00-INDEX.md"
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
  --index 05-CONFIGURATIONS/docker-compose/00-INDEX.md \
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
  "agent_id": "docker-compose-master-agent",
  "trace_id": "<trace_id>",
  "span_id": "<span_id>",
  "parent_span_id": "<parent_span_id>",
  "status": "completed|failed",
  "output_ref": "05-CONFIGURATIONS/docker-compose/<arquivo-gerado>.yml",
  "next_agent_hint": "pipelines-master-agent|terraform-master-agent",
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

Este Master Agent referencia skills em `libs/` sob demanda. Cada skill é carregada apenas quando o SDD da tarefa a exige.

| Skill | Arquivo | Quando Carregar |
|-------|---------|----------------|
| Template Base | [[libs/base-service-template.md]] | Sempre (define `x-service-base`) |
| Health Checks | [[libs/healthcheck-patterns.md]] | Ao definir serviços com dependências |
| Redes | [[libs/network-patterns.md]] | Ao projetar topologia de comunicação |
| Volumes | [[libs/volume-patterns.md]] | Ao precisar de persistência |
| Segurança | [[libs/security-patterns.md]] | Sempre (aplicado via `x-service-base`) |
| Deploy | [[libs/deployment-strategies.md]] | Ao configurar atualizações sem downtime |
| Build de Imagens | [[libs/image-building.md]] | Ao gerar Dockerfiles |
| Logging/Observabilidade | [[libs/logging-observability.md]] | Ao configurar monitoramento |
| Múltiplos Ambientes | [[libs/environment-strategies.md]] | Ao separar dev/staging/prod |
| Troubleshooting | [[libs/troubleshooting.md]] | Apenas em diagnóstico de falhas |
| Validação | [[libs/validation-scripts.md]] | Ao final de cada geração |
| Stack Full | [[libs/stack-templates/full-stack-mantis.md]] | Ao gerar stack completo |
| Microserviços | [[libs/stack-templates/microservices-messaging.md]] | Ao gerar arquitetura de microserviços |

---
## 🛡️ Hardening (Harness Norms v3.0 – Docker Compose)

O hardening mínimo para qualquer serviço MANTIS é definido em [[libs/base-service-template.md]] e [[libs/security-patterns.md]]. Em resumo:
- `user: "1001:1001"` (non-root)
- `cap_drop: [ALL]` + `cap_add: [NET_BIND_SERVICE]`
- `read_only: true` com `tmpfs` para diretórios de escrita
- `security_opt: [no-new-privileges:true]`
- Secrets via Docker Secrets (`/run/secrets/`), nunca em `environment:`

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
- [[/05-CONFIGURATIONS/observability/grafana/dashboards/core-docker-compose.json]]

---
## 🧪 Testes Unitários (TDD)

### Validação de Sintaxe YAML
```bash
test_compose_syntax() {
  local compose_file="${1:?}"
  docker compose -f "$compose_file" config --quiet 2>/dev/null && return 0 || return 1
}
```

### Validação de Health Check
```bash
test_healthcheck_present() {
  local compose_file="${1:?}" service="${2:?}"
  docker compose -f "$compose_file" config 2>/dev/null | \
    python3 -c "import sys,json,yaml; d=yaml.safe_load(sys.stdin); assert 'healthcheck' in d['services']['$service']"
}
```

### Execução Condicional
```bash
if [[ "${1:-}" == "--test" ]]; then
  test_compose_syntax "compose.prod.yaml" && echo "✅ Test passed" || echo "❌ Test failed"
  exit $?
fi
```

---
## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 05-CONFIGURATIONS/docker-compose/<artefacto>.yml \
  --json \
  --check-secrets \
  --check-structural \
  --check-resource-limits \
  --check-error-handling \
  --check-observability
```

---
## 🔗 Grafo de Inter-relações: Domínio docker-compose MANTIS

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

    MASTER["🧠 docker-compose-master-agent.md<br/>(Fonte de Verdade)"]:::foundation

    BASE["🧱 base-service-template.md<br/>x-service-base anchor"]:::foundation
    HEALTH["🩺 healthcheck-patterns.md"]:::foundation
    SECURITY["🛡️ security-patterns.md"]:::security
    NETWORK["🌐 network-patterns.md"]:::operations
    VOLUMES["💾 volume-patterns.md"]:::operations
    DEPLOY["🚀 deployment-strategies.md"]:::operations
    IMAGE["🏗️ image-building.md"]:::operations
    LOGGING["📊 logging-observability.md"]:::operations
    ENV["🌍 environment-strategies.md"]:::operations

    TROUBLE["🔧 troubleshooting.md"]:::references
    VALIDATION["✅ validation-scripts.md"]:::references
    FULL_STACK["🏢 full-stack-mantis.md"]:::templates
    MICROSERVICES["🔀 microservices-messaging.md"]:::templates
    SEC_REF["🔐 security-checklist.md"]:::references
    OPT_REF["⚡ optimization-guide.md"]:::references
    BEST_REF["📘 docker-best-practices.md"]:::references

    MASTER --> BASE
    MASTER --> HEALTH
    MASTER --> SECURITY
    MASTER --> NETWORK
    MASTER --> VOLUMES
    MASTER --> DEPLOY
    MASTER --> IMAGE
    MASTER --> LOGGING
    MASTER --> ENV
    
    BASE --> SECURITY
    BASE --> HEALTH
    SECURITY --> NETWORK
    NETWORK --> VOLUMES
    DEPLOY --> HEALTH
    IMAGE --> SECURITY
    LOGGING --> HEALTH
    
    FULL_STACK --> BASE
    FULL_STACK --> NETWORK
    MICROSERVICES --> NETWORK
    MICROSERVICES --> SECURITY
    
    TROUBLE --> HEALTH
    TROUBLE --> NETWORK
    VALIDATION --> SECURITY
    VALIDATION --> IMAGE

    style MASTER fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:4px
```

---

## 🧭 Fluxo de Trabalho do Agente Docker Compose

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
    [*] --> Especificação: Requisitos do stack + perfil de infra
    Especificação --> Seleção_de_Skills: Carregar libs/00-INDEX.md
    Seleção_de_Skills --> Geração: Aplicar x-service-base + health checks
    Geração --> Segurança: Adicionar hardening (non-root, secrets, read_only)
    Segurança --> Rede: Configurar redes e isolamento
    Rede --> Volumes: Configurar persistência
    Volumes --> Validação: docker compose config + orchestrator-engine.sh
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
        "file": "05-CONFIGURATIONS/docker-compose/...",
        "passed": true,
        "constraints_checked": ["C1","C2","C3","C7","C8"],
        "performance_ms": 89.3
      }
    end note

    classDef process fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:2px
    class Especificação,Seleção_de_Skills,Geração,Segurança,Rede,Volumes,Validação,Aprovado,Rejeitado,Diagnóstico,Correção,Registro process
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
    Master["🧠 docker-compose-master-agent.md<br/>Domínio: docker-compose"] --> Core["🧠 mantis-core-context.md<br/>Constraints C1-C8"]
    Master --> Rules["📜 harness-norms-v3.0.md<br/>Hardening padrão"]
    Master --> Orchestrator["⚙️ orchestrator-engine/main.go<br/>Validação automatizada"]
    Master --> Pipelines["🚀 pipelines-master-agent<br/>CI/CD e deploy"]
    Master --> Terraform["🏗️ terraform-master-agent<br/>Infraestrutura como código"]
    Master --> Pgvector["🔷 postgresql-pgvector-master-agent<br/>Config de DB e pgvector"]
    
    Core -.->|Define contrato C1-C8| Master
    Rules -.->|Especifica hardening mínimo| Master
    Orchestrator -.->|Valida artefatos via JSON| Master
    Pipelines -.->|Recebe Compose para deploy| Master
    Terraform -.->|Provisiona recursos externos| Master
    Pgvector -.->|Fornece config de DB| Master
    
    style Master fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:4px
    style Core fill:#16213e,color:#fff,stroke:#7f7f7f,stroke-width:1px
    style Rules fill:#16213e,color:#fff,stroke:#7f7f7f,stroke-width:1px
    style Orchestrator fill:#16213e,color:#fff,stroke:#7f7f7f,stroke-width:1px
    style Pipelines fill:#0f3460,color:#fff,stroke:#7f7f7f,stroke-width:1px,stroke-dasharray: 3 3
    style Terraform fill:#0f3460,color:#fff,stroke:#7f7f7f,stroke-width:1px,stroke-dasharray: 3 3
    style Pgvector fill:#0f3460,color:#fff,stroke:#7f7f7f,stroke-width:1px,stroke-dasharray: 3 3
```

---

## 🔄 Protocolo de Handoff para Outros Domínios (LANGUAGE LOCK)

### Quando Delegar (Regra Imutável)
- 🚫 Docker Compose NUNCA gera código de outros domínios sem handoff JSON.
- ✅ Docker Compose PODE gerar stacks completos, validação estática, wrappers seguros e logging.

### Regras de Handoff (Validáveis)
1. Incluir `tenant_id` no payload (C4)
2. Especificar `timeout_seconds` (C1)
3. Documentar `expected_output` (C5)
4. Zero hardcode de secrets (C3)
5. Registrar handoff em log estruturado (C8)

### Handoffs Típicos
| Domínio Destino | Quando | Artefacto Entregue |
|----------------|--------|-------------------|
| `pipelines-master-agent` | Após gerar Compose | `compose.prod.yaml` + `.env.production` |
| `terraform-master-agent` | Para recursos externos | Volumes externos, redes, VPS |
| `postgresql-pgvector-master-agent` | Para config de DB | `init-vector.sql`, conexões |

---
## 📊 Métricas de Qualidade
| Métrica | Meta | Ferramenta |
|---------|------|-----------|
| Pass Rate em Validação | ≥95% | `orchestrator-engine --json` |
| Sintaxe YAML Válida | 100% | `docker compose config --quiet` |
| Cobertura de Health Checks | 100% dos serviços | `docker inspect` |
| Zero Secrets em Produção | 100% | `audit-secrets.sh` |
| Imagens com Tag Pinada | 100% | `grep sha256` |

---
## 🚫 Anti-Padrões
- ❌ `image: nginx:latest` em produção
- ❌ `environment: DB_PASSWORD=supersecreto`
- ❌ `user: root` sem justificativa
- ❌ `ports: "8080:8080"` sem bind a localhost
- ❌ Serviço sem `healthcheck`
- ❌ `deploy.resources` sem limites

---
## 📋 Checklist de Geração
1. ✅ Frontmatter YAML válido (C5)
2. ✅ `x-service-base` aplicado a todos os serviços
3. ✅ Health check configurado para cada tecnologia
4. ✅ Secrets via Docker Secrets, nunca em env (C3)
5. ✅ Redes com isolamento adequado (C2, V1)
6. ✅ `docker compose config --quiet` passa
7. ✅ `orchestrator-engine --json` retorna `passed: true`
8. ✅ Contexto A2A inicializado (C9)
9. ✅ `status.json` escrito com schema completo

---
## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal |
|--------|------|-------|------------------|
| 2.3.0 | 2026-05-23T20:00:00Z | docker-compose-master-agent | Refatoração modular: skills extraídas para libs/ |
| 2.0.0 | 2026-05-07T00:00:00Z | docker-compose-master-agent | Versão monolítica inicial |
