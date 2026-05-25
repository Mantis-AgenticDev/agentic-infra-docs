---
artifact_id: "procedures-configurations-ceo-sop"
artifact_type: "standard_operating_procedure"
version: "2.3.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
canonical_path: "07-PROCEDURES/configurations-ceo-sop.md"
tier: 1
immutable: false
requires_human_approval_for_changes: true
audience: ["human-architects","agentic-assistants","orchestrator-engine","devops","sre"]
language_lock: "pt-BR"
prompt_hash: "sha256:configurations-ceo-sop-v2.3.0"
generated_at: "2026-05-24T11:00:00Z"
domain: "procedures"
subdomain: "configurations"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---

# 🏭 Procedimento Operacional Padrão — Configurations CEO (Fábrica de Produtos)

**Objetivo**: Estabelecer o fluxo completo de trabalho do `configurations-ceo`, abrangendo a governança direta dos subdomínios sem agente próprio (Templates, Scripts, Environment, Observability) e a coordenação dos agentes especialistas (Docker Compose, Pipelines, Terraform). Este SOP é a "fábrica" onde os produtos de configuração do ecossistema MANTIS são projetados, validados e entregues.

**Público-alvo**: Arquitetos humanos, DevOps, SREs, operadores de infraestrutura e todos os agentes mestres que interagem com o domínio `05-CONFIGURATIONS/`.

---

## 1. Visão Geral da Fábrica

O `configurations-ceo` atua em dois modos:

1. **Governança Direta**: Para subdomínios que **não possuem agente próprio** (Templates, Scripts, Environment, Observability), o CEO aplica as regras definidas nas skills de `libs/` e gera/valida os artefatos diretamente.

2. **Coordenação Delegada**: Para subdomínios que **possuem agente próprio** (Docker Compose, Pipelines, Terraform), o CEO prepara delegações usando o protocolo `Task()`, invoca o agente especialista e valida seus outputs.

```mermaid
graph TD
    CEO["🧠 configurations-ceo"]
    
    subgraph "Governança Direta"
        TEMPLATES["📐 Templates"]
        SCRIPTS["📜 Scripts"]
        ENV["🌍 Environment"]
        OBS["📊 Observability"]
    end
    
    subgraph "Coordenação Delegada"
        DC["🐳 docker-compose-master-agent"]
        PL["🚀 pipelines-master-agent"]
        TF["🏗️ terraform-master-agent"]
    end
    
    CEO -->|"Aplica template-standards.md"| TEMPLATES
    CEO -->|"Aplica script-standards.md"| SCRIPTS
    CEO -->|"Aplica environment-standards.md"| ENV
    CEO -->|"Aplica observability-standards.md"| OBS
    
    CEO -->|"Task(docker-compose)"| DC
    CEO -->|"Task(pipelines)"| PL
    CEO -->|"Task(terraform)"| TF
    
    DC -->|"Retorna compose.yaml"| CEO
    PL -->|"Retorna workflow.yml"| CEO
    TF -->|"Retorna tfplan"| CEO
```

---

## 2. Conexão com o Ecossistema `goals/`

Toda atividade do CEO é rastreada via `registry.db` e o contrato A2A (C9). O CEO recebe metas do Orchestrator Engine e as executa conforme o modo de operação.

```mermaid
sequenceDiagram
    participant OE as Orchestrator Engine
    participant REG as registry.db
    participant CEO as configurations-ceo
    participant AGENT as Agente Especialista
    
    OE->>REG: 1. Atribui meta (goal_id, agent, status)
    REG-->>OE: 2. Meta registrada
    OE->>CEO: 3. Adquire meta (CAS)
    CEO->>CEO: 4. Avalia tipo de tarefa
    
    alt Governança Direta
        CEO->>CEO: 5a. Aplica skills de libs/
        CEO->>CEO: 6a. Gera artefato (template, script, env, dashboard)
    else Coordenação Delegada
        CEO->>AGENT: 5b. Task(agente) com contexto
        AGENT-->>CEO: 6b. Artefato gerado
        CEO->>CEO: 7b. Valida output
    end
    
    CEO->>REG: 8. Atualiza status da meta
    CEO->>CEO: 9. Escreve status.json (C9)
    CEO-->>OE: 10. Handoff concluído
```

---

## 3. Fluxo de Trabalho Geral do CEO

```mermaid
stateDiagram-v2
    [*] --> Análise: Meta recebida do Orchestrator
    Análise --> Classificação: Identificar subdomínio alvo
    
    Classificação --> Templates: templates/
    Classificação --> Scripts: scripts/
    Classificação --> Environment: environment/
    Classificação --> Observability: observability/
    Classificação --> DockerCompose: docker-compose/
    Classificação --> Pipelines: pipelines/
    Classificação --> Terraform: terraform/
    
    state Templates {
        [*] --> T_Load: Carregar template-standards.md
        T_Load --> T_Gen: Gerar/validar template
        T_Gen --> T_Val: orchestrator-engine.sh --strict
    }
    
    state Scripts {
        [*] --> S_Load: Carregar script-standards.md
        S_Load --> S_Gen: Gerar script
        S_Gen --> S_Val: shellcheck + orchestrator-engine.sh
    }
    
    state Environment {
        [*] --> E_Load: Carregar environment-standards.md
        E_Load --> E_Gen: Atualizar .env.example / mapping.yaml
        E_Gen --> E_Val: validate-env-mapping.py
    }
    
    state Observability {
        [*] --> O_Load: Carregar observability-standards.md
        O_Load --> O_Gen: Gerar dashboard / alerta
        O_Gen --> O_Val: Prometheus rule test
    }
    
    state DockerCompose {
        [*] --> DC_Task: Task(docker-compose-master-agent)
        DC_Task --> DC_Val: Validar compose.yaml
    }
    
    state Pipelines {
        [*] --> PL_Task: Task(pipelines-master-agent)
        PL_Task --> PL_Val: Validar workflow.yml
    }
    
    state Terraform {
        [*] --> TF_Task: Task(terraform-master-agent)
        TF_Task --> TF_Val: Validar tfplan
    }
    
    Templates --> Registro: status.json
    Scripts --> Registro
    Environment --> Registro
    Observability --> Registro
    DockerCompose --> Registro
    Pipelines --> Registro
    Terraform --> Registro
    
    Registro --> [*]
```

---

## 4. Governança Direta: Subdomínios sem Agente Próprio

### 4.1 Templates

**Objetivo**: Criar e manter templates versionados (Dockerfile, Compose, Terraform, dashboards) que sirvam como base imutável para os agentes especialistas.

```mermaid
graph TD
    A[Solicitação de Template] --> B{Existe template base?}
    B -->|Sim| C[Carregar template existente]
    B -->|Não| D[Criar novo template com cabeçalho padrão]
    C --> E[Personalizar via override, não modificação]
    D --> E
    E --> F[Validar com orchestrator-engine.sh --domain templates --strict]
    F --> G{Passou?}
    G -->|Sim| H[Registrar versão (semver) e atualizar CHANGELOG]
    G -->|Não| I[Corrigir desvios e revalidar]
    I --> F
    H --> J[Disponibilizar para agentes consumidores]
```

**Comandos de validação**:
```bash
# Validar template
bash orchestrator-engine.sh --domain templates --file Templates/novo-template.yml --strict

# Verificar versionamento semântico
grep -P 'version: "\d+\.\d+\.\d+"' Templates/novo-template.yml

# Verificar cabeçalho obrigatório
grep -q "artifact_id:" Templates/novo-template.yml && echo "✅" || echo "❌ Falta artifact_id"
```

---

### 4.2 Scripts

**Objetivo**: Produzir scripts bash padronizados, com logging, tratamento de erros e testes TDD integrados.

```mermaid
graph TD
    A[Solicitação de Script] --> B[Carregar script-standards.md e script-template.sh]
    B --> C[Preencher cabeçalho obrigatório]
    C --> D[Implementar funções com logging e cleanup]
    D --> E[Adicionar testes TDD com flag --test]
    E --> F[Executar shellcheck]
    F --> G{shellcheck passou?}
    G -->|Sim| H[Executar script --test para TDD]
    G -->|Não| I[Corrigir erros de sintaxe]
    I --> F
    H --> J{TDD passou?}
    J -->|Sim| K[Validar com orchestrator-engine.sh --domain scripts --strict]
    J -->|Não| L[Corrigir lógica dos testes]
    L --> H
    K --> M[Registrar no 00-INDEX.md de Scripts/]
```

**Comandos de validação**:
```bash
# Validar com shellcheck
shellcheck Scripts/novo-script.sh

# Executar testes internos
bash Scripts/novo-script.sh --test

# Validar constraints
bash orchestrator-engine.sh --domain scripts --file Scripts/novo-script.sh --strict
```

---

### 4.3 Environment

**Objetivo**: Gerenciar variáveis de ambiente e secrets de forma centralizada e segura.

```mermaid
graph TD
    A[Nova variável necessária] --> B[Adicionar entrada em .env.example com tipo e descrição]
    B --> C[Adicionar entrada em mapping.yaml com consumers e validação]
    C --> D{É sensível?}
    D -->|Sim| E[Marcar sensitive: true e NUNCA commitar valor real]
    D -->|Não| F[Definir valor default em .env.dev]
    E --> G[Configurar no gestor de secrets (Vault/git-crypt)]
    F --> G
    G --> H[Executar validate-env-mapping.py]
    H --> I{Passou?}
    I -->|Sim| J[Notificar agentes consumidores da nova variável]
    I -->|Não| K[Corrigir mapping e revalidar]
    K --> H
```

**Comandos de validação**:
```bash
# Validar mapeamento
python3 Scripts/validate-env-mapping.py

# Verificar secrets expostos
grep -r "sensitive: true" Environment/mapping.yaml | while read line; do
  var=$(echo "$line" | cut -d: -f1)
  grep -q "^$var=.*[a-zA-Z0-9]" Environment/.env.example && echo "⚠️ $var tem valor real em .env.example"
done
```

---

### 4.4 Observability

**Objetivo**: Garantir que todos os serviços tenham métricas, dashboards e alertas configurados desde o dia um.

```mermaid
graph TD
    A[Novo serviço implantado] --> B[Adicionar métricas obrigatórias no código]
    B --> C[Expor endpoint /health/ready profundo]
    C --> D[Adicionar entrada em health-endpoints.yaml]
    D --> E[Criar/atualizar dashboard no Grafana]
    E --> F[Adicionar regras de alerta em critical-alerts.yml]
    F --> G[Testar alertas com test-alerts.sh]
    G --> H{Teste passou?}
    H -->|Sim| I[Registrar no metrics-registry.yaml]
    H -->|Não| J[Ajustar thresholds e revalidar]
    J --> G
```

**Comandos de validação**:
```bash
# Testar health endpoint
curl -f http://localhost:4000/health/ready

# Testar regras de alerta
bash Scripts/test-alerts.sh --rule critical-alerts.yml

# Verificar métricas no Prometheus
curl -s "http://localhost:9090/api/v1/query?query=http_requests_total" | jq '.data.result | length'
```

---

## 5. Coordenação Delegada: Subdomínios com Agente Próprio

### 5.1 Docker Compose

```mermaid
sequenceDiagram
    participant CEO as configurations-ceo
    participant DC as docker-compose-master-agent
    participant TF as terraform-master-agent
    participant VPS
    
    CEO->>TF: Task(terraform): gerar outputs.json com vpc_id, subnet_ids
    TF-->>CEO: outputs.json
    CEO->>CEO: Validar outputs (orchestrator-engine.sh)
    CEO->>DC: Task(docker-compose): gerar compose.yaml usando outputs.json
    DC-->>CEO: compose.yaml
    CEO->>CEO: Validar compose (docker compose config --quiet)
    CEO->>VPS: Executar deploy-all.sh
    VPS-->>CEO: Health checks OK
    CEO->>CEO: Escrever status.json (C9)
```

**Protocolo de delegação**:
```yaml
Task(docker-compose-master-agent):
  prompt: "Gerar compose.yaml para VPS1 usando outputs de Terraform"
  context:
    - "05-CONFIGURATIONS/Terraform/envs/prod/outputs.json"
    - "05-CONFIGURATIONS/Environment/.env.prod"
    - "00-STACK-SELECTOR.md"
  expected_output:
    - "05-CONFIGURATIONS/docker-compose/vps1.yml"
  timeout_minutes: 20
```

---

### 5.2 Pipelines

```mermaid
sequenceDiagram
    participant CEO as configurations-ceo
    participant PL as pipelines-master-agent
    participant GHA as GitHub Actions
    
    CEO->>PL: Task(pipelines): gerar workflow de deploy para VPS1
    PL-->>CEO: deploy-vps1.yml
    CEO->>CEO: Validar workflow (yaml syntax + security scan)
    CEO->>GHA: Commit e push do workflow
    GHA->>GHA: Executar pipeline
    GHA-->>CEO: Resultado do pipeline (sucesso/falha)
    alt Falha
        CEO->>PL: Task(pipelines): diagnosticar e corrigir workflow
    end
    CEO->>CEO: Escrever status.json (C9)
```

**Protocolo de delegação**:
```yaml
Task(pipelines-master-agent):
  prompt: "Gerar workflow de deploy para VPS1 com stages: validate, plan, apply, health-check"
  context:
    - "05-CONFIGURATIONS/docker-compose/vps1.yml"
    - "05-CONFIGURATIONS/Environment/.env.prod"
    - "00-STACK-SELECTOR.md"
  expected_output:
    - ".github/workflows/deploy-vps1.yml"
  timeout_minutes: 25
```

---

### 5.3 Terraform

```mermaid
sequenceDiagram
    participant CEO as configurations-ceo
    participant TF as terraform-master-agent
    participant AWS
    
    CEO->>TF: Task(terraform): gerar plan de infra para ambiente prod
    TF-->>CEO: tfplan + outputs.json
    CEO->>CEO: Validar tfplan (checkov, tfsec, OPA)
    CEO->>CEO: Revisão humana (se prod) ou auto-approve (se dev)
    CEO->>AWS: terraform apply tfplan
    AWS-->>CEO: Infra provisionada
    CEO->>CEO: Escrever status.json (C9)
```

**Protocolo de delegação**:
```yaml
Task(terraform-master-agent):
  prompt: "Gerar plan de infraestrutura para prod com módulo VPS base e backend S3"
  context:
    - "05-CONFIGURATIONS/terraform/envs/prod/main.tf"
    - "05-CONFIGURATIONS/Environment/.env.prod"
    - "00-STACK-SELECTOR.md"
  expected_output:
    - "05-CONFIGURATIONS/terraform/envs/prod/tfplan"
    - "05-CONFIGURATIONS/terraform/envs/prod/outputs.json"
  timeout_minutes: 30
```

---

## 6. Orquestração Multi-Agente (Fluxo Completo)

Quando uma meta exige a participação de múltiplos agentes, o CEO orquestra o fluxo completo:

```mermaid
sequenceDiagram
    participant CEO as configurations-ceo
    participant TF as terraform-master-agent
    participant PL as pipelines-master-agent
    participant DC as docker-compose-master-agent
    participant OBS as observability (CEO)
    
    CEO->>TF: 1. Task(terraform): provisionar infra
    TF-->>CEO: 1. tfplan + outputs.json
    CEO->>CEO: 1. Validar e aplicar (com aprovação se prod)
    
    CEO->>PL: 2. Task(pipelines): criar workflow de build
    PL-->>CEO: 2. build-and-push.yml
    
    CEO->>DC: 3. Task(docker-compose): gerar compose com outputs de TF
    DC-->>CEO: 3. compose.prod.yaml
    
    CEO->>CEO: 4. Executar deploy-all.sh (sequencial: build → push → deploy)
    
    CEO->>OBS: 5. Verificar health checks e métricas
    OBS-->>CEO: 5. Todos serviços saudáveis
    
    CEO->>CEO: 6. Gerar SitRep e notificar stakeholders
    CEO->>CEO: 7. Escrever status.json (C9)
```

---

## 7. Normativas e Regras de Ouro

| Normativa | Descrição | Constraint |
|-----------|-----------|------------|
| **Versionamento Semântico** | Templates e scripts usam semver (MAJOR.MINOR.PATCH) | C1 |
| **Cabeçalho Obrigatório** | Todo artefato deve ter frontmatter YAML com `artifact_id`, `version`, `constraints_mapped` | C5 |
| **Mapping de Variáveis** | Toda variável de ambiente deve estar documentada em `.env.example` e mapeada em `mapping.yaml` | C3, C4 |
| **Protocolo Task()** | Toda delegação a agente especialista deve incluir `prompt`, `context`, `expected_output` e `timeout_minutes` | C6 |
| **Validação Pré-Commit** | `orchestrator-engine.sh --strict` deve passar antes de qualquer commit | C5 |
| **ADR para Decisões Críticas** | Mudanças estruturais devem ser documentadas em Architecture Decision Records | C6 |
| **Health Check Profundo** | Todo serviço deve expor `/health/ready` verificando dependências reais | C8 |
| **Rollback Automático** | Scripts de deploy devem incluir capacidade de rollback com verificação de saúde | C7 |

---

## 8. Troubleshooting

| Sintoma | Causa Provável | Diagnóstico | Solução |
|---------|---------------|-------------|---------|
| `Task()` retorna erro | Agente não encontrado ou timeout | `grep "agent_id" 00-STACK-SELECTOR.md` | Verificar se o agente está registrado; aumentar timeout |
| Template não passa validação | Cabeçalho YAML ausente ou versionamento incorreto | `orchestrator-engine.sh --file template.yml --json` | Adicionar frontmatter completo |
| Script falha em produção | `shellcheck` não foi executado ou `set -euo pipefail` ausente | `shellcheck script.sh` | Corrigir erros e revalidar |
| Variável não encontrada | Não está em `mapping.yaml` ou `.env.example` | `validate-env-mapping.py` | Adicionar entrada no mapping |
| Dashboard não mostra métricas | Prometheus não está scrapeando o serviço | `curl localhost:9090/api/v1/targets` | Verificar configuração do job no `prometheus.yml` |
| Deploy orquestrado falha na fase 3 | Dependência entre agentes não satisfeita | `orchestrator-engine.sh --resolve-deps` | Verificar outputs dos agentes anteriores |

---

## 9. Referências Cruzadas

- [[05-CONFIGURATIONS/configurations-ceo.md]] — CEO do domínio
- [[05-CONFIGURATIONS/libs/00-INDEX.md]] — Índice de skills de governança
- [[05-CONFIGURATIONS/docker-compose/docker-compose-master-agent.md]] — Agente Docker Compose
- [[05-CONFIGURATIONS/pipelines/pipelines-master-agent.md]] — Agente Pipelines
- [[05-CONFIGURATIONS/terraform/terraform-master-agent.md]] — Agente Terraform
- [[05-CONFIGURATIONS/validation/orchestrator-engine.sh]] — Motor de validação
- [[07-PROCEDURES/docker-compose-sop.md]] — SOP de Docker Compose
- [[07-PROCEDURES/pipelines-sop.md]] — SOP de Pipelines
- [[07-PROCEDURES/terraform-sop.md]] — SOP de Terraform
- [[goals/README.md]] — Sistema de metas
- [[01-RULES/harness-norms-v3.0.md]] — Hardening padrão
- [[01-RULES/11-A2A-COMMUNICATION-RULES.md]] — Contrato A2A (C9)

---

> **Versão 2.3.0** | Procedimento Operacional Padrão do CEO de Configurações — MANTIS Agentic.
> Aplicável a partir de 2026-05-24.
