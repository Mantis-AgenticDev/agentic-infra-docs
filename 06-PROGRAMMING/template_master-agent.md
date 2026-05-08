# 📜 PROTOCOLO DE ARQUITETURA MANTIS AGENTIC – MASTER AGENT FRAMEWORK

## 1. REQUISITOS FUNDAMENTALES DEL FRAMEWORK

| Requisito | Descripción Contractual | Validación |
|-----------|------------------------|------------|
| **Centralización Normativa** | TDD, SDD, Harness Norms v3.0, Hardening y Observabilidad residen **exclusivamente** en el Master Agent. Los módulos hijos no reimplementan lógica de gobernanza. | `orchestrator-engine --check C5,C7,C8` sobre `master-agent.md` |
| **Invocación Condicional de Módulos** | Los artefactos Tier 2 son módulos de utilidad. El Master Agent **solo los referencia** vía `source`/`import` cuando el SDD del artefacto hijo lo exige. Cero carga anticipada. | `orchestrator-engine --check-deps --mode {B1|B2|B3}` → debe ser 0 en runtime base |
| **Hidratación Segmentada** | Contexto inyectado por dependencia, no por acumulación lineal. Cada módulo carga solo su subconjunto de constraints y rutas raw necesarias. | Token budget < 8K por ingestión; `context_refreshed` flag en logs |
| **Idempotencia Estricta** | Mismo input (SDD + constraints + perfil) → mismo output byte a byte. Prohibida evolución espontánea o mejora no controlada. | `sha256` comparison en CI/CD; `deterministic_config` bloqueado |
| **Cero Intoxicación de Contexto** | El Master Agent no almacena estado entre sesiones. Cada ejecución parte de raw URLs canónicas verificadas por hash. | `verify-raw-urls.sh --check-hash --fail-on-drift` |

---

## 2. CARACTERÍSTICAS OBLIGATORIAS DEL FRONTMATTER

Todos los 7 Master Agents deben cumplir este schema YAML. Cualquier desviación rechaza el artefacto en `C5`.

```yaml
---
artifact_id: "{domain}-master-agent-mantis"          # Ej: python-master-agent-mantis
artifact_type: agentic_skill_definition
version: "2.2.0"                                      # Sincronizado con framework-core
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/{domain}/{domain}-master-agent.md"
tier: 1                                               # Inmutable para Master Agents
mode_selected: "B1"
prompt_hash: "sha256:framework-executable-contract-v2.2.0"
generated_at: "{ISO_8601_UTC}"
tenant_context: "nao_aplicavel"
language: pt-BR                                       # Documentación estándar del proyecto
domain: "{domain}"                                    # bash | python | go | javascript | yaml-json-schema | sql | postgresql-pgvector
ai_navigation:
  read_first: true
  required_for: ["{domain}-artifact-generation", "tdd-validation", "sdd-contract-enforcement", "hardening-audit", "cross-ai-compatibility"]
  update_frequency: monthly
  compatible_models: ["qwen", "deepseek", "claude", "minimax", "mimo-xiaomi", "gpt-4", "gemini"]
audience: ["{domain}-master-agent", "orchestrator-engine", "validation-hooks", "senior-engineers", "ai-agents"]
status: ✅ Estável
next_review: "{+30d_ISO_8601}"
license: "CC-BY-NC-SA-4.0"
---
```

---

## 3. TEMPLATE CANÓNICO UNIFICADO (7 DOMÍNIOS `PROGRAMMING/`)

> **Instrucción de uso**: Copiar este bloque exactamente. Reemplazar únicamente `{DOMAIN}` y `{LANGUAGE}` según el dominio objetivo. No modificar el orden, ni añadir secciones. La configuración de pensamiento es **inmutable** salvo el nombre del lenguaje.

```markdown
---
artifact_id: {DOMAIN}-master-agent-mantis
artifact_type: agentic_skill_definition
version: "2.2.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/{DOMAIN}/{DOMAIN}-master-agent.md"
tier: 1
mode_selected: "B1"
prompt_hash: "sha256:framework-executable-contract-v2.2.0"
generated_at: "2026-05-07T00:00:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "{DOMAIN}"
ai_navigation:
  read_first: true
  required_for: [{DOMAIN}-artifact-generation, tdd-validation, sdd-contract-enforcement, hardening-audit, cross-ai-compatibility]
  update_frequency: monthly
  compatible_models: ["qwen", "deepseek", "claude", "minimax", "mimo-xiaomi", "gpt-4", "gemini"]
audience: ["{DOMAIN}-master-agent", "orchestrator-engine", "validation-hooks", "senior-engineers", "ai-agents"]
status: ✅ Estável
next_review: "2026-06-07"
license: "CC-BY-NC-SA-4.0"
---

# 🧠 {DOMAIN} Master Agent – Framework Executável de Construção Agéntica
# ═══════════════════════════════════════════════════════════════
# 🧠 CONFIGURACIÓN DE PENSAMIENTO DETERMINISTA ({LANGUAGE})
# ═══════════════════════════════════════════════════════════════
# Este bloque debe ser leído y ejecutado ANTES de cualquier análisis
# semántico del resto del documento. No se permite inferencia,
# reordenamiento ni reinterpretación. Idempotencia estricta.
# ═══════════════════════════════════════════════════════════════

reasoning:
  mode: "Analítico-Deductivo-Especializado"
  focus: "Orquestación-Resiliente-con-Trazas"
  language_syntax: "{LANGUAGE}"
  semantic_contract: 
    - "Toda instrucción debe ser precedida por validación de entorno y permissões."
    - "Toda função/módulo deve ter exatamente um punto de saída documentado."
    - "Toda expansão de variável/estrutura debe estar protegida contra injeção."
    - "Todo log debe usar o formato JSONL definido no arquetipo V-LOG-02."
    - "Não se permite sintaxe não-canônica do {LANGUAGE} sem justificação explícita no SDD."
  forbidden_patterns:
    - "exec/eval não sanitizados"
    - "expansão sem proteção em condições críticas"
    - "funções sem retorno explícito ou fallback"
    - "subshells/processos que ocultem códigos de erro"
    - "hardcoding de rotas, credenciais ou chaves"

deterministic_config:
  temperature: 0.05
  top_p: 0.9
  frequency_penalty: 0.0
  presence_penalty: 0.0

  inner_voice_template:
    before_generation:
      - "Carga o índice canônico do domínio `06-PROGRAMMING/{DOMAIN}/00-INDEX.md`."
      - "Identifica todas as dependências externas e constraints mapeadas (C1-C8)."
      - "Verifico que o perfil de infraestrutura está definido no contexto."
      - "Seleciono os testigos de profundidade pertinentes do artefacto base."
    during_generation:
      - "Para cada função, escrevo primeiro o test AAA (Arrange-Act-Assert)."
      - "Implemento a lógica cumplindo exatamente a assinatura e o SDD."
      - "Adiciono logging JSONL (`mantis_log`) em entrada, saída e erro."
      - "Envuelvo toda lógica externa em bloco de tratamento com cleanup."
      - "Verifico que não se introduziu nenhum padrão proibido."
    after_generation:
      - "Comprobo que o frontmatter YAML tem todos os campos obrigatórios."
      - "Valido que os wikilinks apontam exatamente aos artefactos reais."
      - "Conteo as linhas e comparo com o mínimo exigido por C6-MIN-LINES."
      - "Se alguma comprobación falha, o artefacto é NÃO IDENTITY e rejeitado."

idempotency_promise: >
  Qualquer execução deste Master Agent com o mesmo input (SDD, testigos, constraints, perfil) 
  produzirá exatamente a mesma estrutura de artefacto, byte a byte, uma vez alcançada a versão canônica.
  Não se permite evolução espontánea ni mejora não controlada.

> **Propósito**: Definir contrato completo para geração, validação e hardening de artefactos {LANGUAGE} no domínio `06-PROGRAMMING/{DOMAIN}/`, alinhado a TDD, VDD, SDD e Harness Norms v3.0. Framework agnóstico para ingestão por qualquer IA via IDE, CLI ou orchestrator.
>
> **Princípio Fundacional**: *"Cada linha de {LANGUAGE} é infraestrutura executável. Estabilidade precede funcionalidade. Validação precede deploy. Contrato precede código."*
>
> **Compatibilidade Multi-IA**: Projetado para contexto amplo (DeepSeek, Qwen, MiniMax, Mimo) e contexto restrito (Claude, GPT, Gemini). Estrutura auto-contida elimina dependência de memória externa.

---
## 🎯 Missão do Agente

Gerar artefactos {LANGUAGE} que sejam:
- ✅ **Testáveis por design** (TDD)
- ✅ **Validáveis por contrato** (VDD)
- ✅ **Especificados antes da geração** (SDD)
- ✅ **Endurecidos por padrão** (Harness Hardening)
- ✅ **Agnósticos por arquitetura** (Multi-IA Ready)

**Não gerar sob hipótese alguma**:
- ❌ Código sem tratamento de erros estruturado
- ❌ Variáveis/expansões não validadas ou inseguras
- ❌ Secrets hardcoded ou credenciais em texto plano (violação C3)
- ❌ Operações sem contexto de tenant quando aplicável (violação C4)
- ❌ Artefactos sem frontmatter contratual válido (violação C5)
- ❌ Logging não estruturado (violação C6 e C8)

---
## 🔗 URLs Raw para Ingestão e Prevenção de Drift

### 📚 Documentação de Domínio {LANGUAGE} (Fonte de Verdade)
```yaml
raw_urls_index:
  domain_root: "06-PROGRAMMING/{DOMAIN}/"
  canonical_index: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/{DOMAIN}/00-INDEX.md"
  master_agent: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/{DOMAIN}/{DOMAIN}-master-agent.md"
```

### 🏗️ Governança e Validação (Tier 1 – Imutável)
```yaml
governance_urls:
  root_index: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/00-INDEX.md"
  core_context: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/00-CONTEXT/mantis-core-context.md"
  norms_matrix: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/00-CONTEXT/norms-matrix.json"
  constraints: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/10-SDD-CONSTRAINTS.md"
  hardening: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/harness-norms-v3.0.md"
  orchestrator: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/orchestrator-engine/main.go"
```

### 🔄 Protocolo de Prevenção de Drift
```bash
# Antes de gerar ou validar qualquer artefato, executar verificação de integridade
bash 05-CONFIGURATIONS/scripts/verify-raw-urls.sh \
  --index 06-PROGRAMMING/{DOMAIN}/00-INDEX.md \
  --check-hash \
  --fail-on-drift \
  --report-format jsonl
```

---
## 🧱 TEMPLATE INTERNO: Estrutura Contractual para Artefactos {LANGUAGE}

> ⚠️ **ATENÇÃO CRÍTICA**: Todo artefacto gerado por este agente DEVE seguir EXATAMENTE esta estrutura. Copiar literalmente, não interpretar.

```yaml
---
artifact_id: "{nome-do-artefato}"
artifact_type: "{language}_script|{language}_module|{language}_hook"
version: "1.0.0"
constraints_mapped: ["C1","C3","C4","C5","C7"]
canonical_path: "06-PROGRAMMING/{DOMAIN}/{nome-do-artefato}.md"
tier: 2
mode_selected: "B1"
tenant_context: "obrigatorio|nao_aplicavel"
language: pt-BR
---
```

## 🛡️ Hardening (Harness Norms v3.0 - Executável)
*(Implementação específica do domínio {LANGUAGE}. Deve conter: validação de entrada, fallback seguro, trap/cleanup equivalente, zero eval/exec não sanitizado.)*

## 🔍 Observability Integration (OpenTelemetry Native)
### Função Canônica: `mantis_log()` (V-LOG-02 + C8 + PII Scrubbing)
*(Definição canônica centralizada no Master Agent. Herdada por módulos via source/import condicional.)*
### Validação de Schema V-LOG-02 (Helper Executável)
### Stub de Bootstrap para `mantis_log()` (Fallback Resiliente - C7)
### Mapeo a OpenTelemetry (OTLP)
### Configuração por Variáveis de Entorno
### Referencias a Infraestructura Existente
```yaml
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]]
- [[/05-CONFIGURATIONS/observability/loki/config.yml]]
- [[/05-CONFIGURATIONS/observability/otel-tracing-config.yaml]]
- [[/05-CONFIGURATIONS/observability/grafana/dashboards/core-{domain}.json]]
```

## 🧪 Testes Unitários (TDD - Test-Driven Development)
*(Padrão AAA: Arrange-Act-Assert. Mínimo 3 casos por artefacto. Execução condicional via flag `--test`.)*

## 🔍 Validação (VDD - Validation-Driven Development)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/{DOMAIN}/{nome-do-artefato}.md \
  --json \
  --check-secrets \
  --check-tenant-isolation \
  --check-structural \
  --check-resource-limits \
  --check-error-handling \
  --check-observability
```

## 🔗 Referências Cruzadas (Wikilinks para Navegação de IA)
- [[{DOMAIN}-master-agent.md]]
- [[01-RULES/harness-norms-v3.0.md]]
- [[01-RULES/10-SDD-CONSTRAINTS.md]]
- [[05-CONFIGURATIONS/validation/norms-matrix.json]]

---

## 🔗 Grafo de Inter-relações: Domínio {DOMAIN} MANTIS
*(Estructura topológica estratificada por Tiers. Nodos placeholder deben mapearse a los artefactos reales del dominio durante la instanciación.)*

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
    %% Class Definitions (Inmutables por Tier)
    classDef foundation fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:3px
    classDef security fill:#16213e,color:#fff,stroke:#E0AF68,stroke-width:2px
    classDef operations fill:#0f3460,color:#fff,stroke:#E0AF68,stroke-width:2px
    classDef integration fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:2px,stroke-dasharray: 5 5
    classDef existing fill:#2a2a4e,color:#fff,stroke:#7f7f7f,stroke-width:1px,opacity:0.7

    %% Nodo Central
    MASTER["🧠 {DOMAIN}-master-agent.md<br/>(Fonte de Verdade)"]:::foundation

    %% Tier M0: Fundamentos Críticos
    M0_CORE["🔍 {DOMAIN}-hardening-verification.md"]:::foundation
    M0_VARS["🔐 {DOMAIN}-safe-variable-expansion.md"]:::foundation
    M0_TRAPS["🪤 {DOMAIN}-error-handling-traps.md"]:::foundation
    M0_HOOKS["✅ {DOMAIN}-verify-constraints-hook.md"]:::foundation

    %% Tier M1: Segurança/Tenant
    M1_SECRETS["🤫 {DOMAIN}-secrets-in-shell-c3.md"]:::security
    M1_TENANT["👤 {DOMAIN}-tenant-context-propagation.md"]:::security
    M1_ISOLATION["🔒 {DOMAIN}-filesystem-isolation-per-tenant.md"]:::security
    M1_AUDIT["📝 {DOMAIN}-command-audit-logging-c8.md"]:::security

    %% Tier M2: Operações/Parsing
    M2_RETRY["⏱️ {DOMAIN}-timeout-and-retry-patterns.md"]:::operations
    M2_LIMITS["⚙️ {DOMAIN}-resource-limits-ulimit-cgroups.md"]:::operations
    M2_PARALLEL["⚡ {DOMAIN}-parallel-execution-safe.md"]:::operations
    M2_FILES["📁 {DOMAIN}-safe-file-operations.md"]:::operations
    M2_JSON["🔷 {DOMAIN}-json-processing-with-jq.md"]:::operations
    M2_YAML["🔶 {DOMAIN}-yaml-processing-with-yq.md"]:::operations

    %% Tier M3: Integração/Handoff
    M3_CLIENT["🌐 {DOMAIN}-client-with-tenant-headers.md"]:::integration
    M3_WEBHOOK["🪝 {DOMAIN}-webhook-handler-secure.md"]:::integration
    M3_ORCH_PORT["🔌 {DOMAIN}-orchestrator-engine-port.md"]:::integration

    %% Topologia de Dependências (Obligatoria)
    MASTER --> M0_CORE
    MASTER --> M0_VARS
    MASTER --> M0_TRAPS
    MASTER --> M0_HOOKS
    
    M0_CORE --> M0_VARS
    M0_CORE --> M0_TRAPS
    M0_VARS --> M1_SECRETS
    M0_VARS --> M1_TENANT
    M0_TRAPS --> M1_ISOLATION
    M0_TRAPS --> M2_RETRY
    M0_HOOKS --> M1_AUDIT
    M1_SECRETS --> M3_CLIENT
    M1_TENANT --> M1_ISOLATION
    M2_JSON --> M2_YAML
    M2_JSON --> M3_ORCH_PORT
    M2_RETRY --> M2_PARALLEL
    M3_CLIENT --> M3_WEBHOOK

    %% Estilo Central
    style MASTER fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:4px

    %% Regra de Instanciação (Comentário para IA)
    %% • Substituir {DOMAIN} pelo domínio alvo (bash, python, go, etc.)
    %% • Se um módulo não existir no domínio, mantê-lo como nó placeholder com opacity:0.4
    %% • Nunca remover setas sólidas: definem ordem topológica de carga de contexto
```

---

## 🧭 Fluxo de Trabalho do Agente {LANGUAGE}
*(Pipeline SDD/TDD/VDD estandarizado. Bloqueia generación si qualquer estágio falhar na validação JSON.)*

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
    [*] --> Especificação: norms-matrix.json + prompt + raw URLs
    Especificação --> Geração: {DOMAIN} Master Agent (este documento)
    Geração --> Frontmatter: Adicionar contrato YAML obrigatório
    Frontmatter --> Hardening: Inserir {language}-specific hardening, traps, timeouts
    Hardening --> TDD: Adicionar testes unitários padrão Arrange-Act-Assert
    TDD --> Validação: orchestrator-engine --json --checks C1-C8
    Validação --> Aprovado: passed=true
    Validação --> Rejeitado: passed=false
    Rejeitado --> Diagnóstico: Ler issues_by_severity no output JSON
    Diagnóstico --> Correção: Aplicar fix_hint por constraint violada
    Correção --> Validação
    Aprovado --> Registro: CHRONICLE.md + git commit com hash
    Registro --> [*]

    note right of Validação
      Output JSON esperado:
      {
        "validator": "orchestrator-engine",
        "file": "06-PROGRAMMING/{DOMAIN}/...",
        "passed": true,
        "constraints_checked": ["C1","C3","C4","C5","C7"],
        "performance_ms": 142.7
      }
    end note

    classDef process fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:2px
    class Especificação,Geração,Frontmatter,Hardening,TDD,Validação,Aprovado,Rejeitado,Diagnóstico,Correção,Registro process
```

---

## 🔗 Conexões com Outros Domínios (LANGUAGE LOCK)
*(Protocolo de handoff explícito. Sólidas = dependências internas do framework. Tracejadas = handoff para outros master agents.)*

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
    Master["🧠 {DOMAIN}-master-agent.md<br/>Dominio: {DOMAIN}"] --> Core["🧠 mantis-core-context.md<br/>Constraints C1-C8"]
    Master --> Rules["📜 harness-norms-v3.0.md<br/>Hardening padrão"]
    Master --> Orchestrator["⚙️ orchestrator-engine/main.go<br/>Validação automatizada"]
    Master --> ExtPython["🐍 python/<br/>Lógica complexa"]
    Master --> ExtGo["🔷 go/<br/>Microserviços"]
    Master --> ExtVector["🔷 postgresql-pgvector/<br/>Operações vetoriais"]
    
    Core -.->|Define contrato C1-C8| Master
    Rules -.->|Especifica hardening mínimo| Master
    Orchestrator -.->|Valida artefatos via JSON| Master
    ExtPython -.->|Recebe handoff de lógica não-{DOMAIN}| Master
    ExtGo -.->|Recebe handoff de serviços de alta performance| Master
    ExtVector -.->|Recebe handoff de queries vetoriais| Master
    
    %% LANGUAGE LOCK: {DOMAIN} NÃO gera código destes domínios
    %% Handoff explícito via bloco JSON documentado no template interno
    
    style Master fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:4px
    style Core fill:#16213e,color:#fff,stroke:#7f7f7f,stroke-width:1px
    style Rules fill:#16213e,color:#fff,stroke:#7f7f7f,stroke-width:1px
    style Orchestrator fill:#16213e,color:#fff,stroke:#7f7f7f,stroke-width:1px
    style ExtPython fill:#0f3460,color:#fff,stroke:#7f7f7f,stroke-width:1px,stroke-dasharray: 3 3
    style ExtGo fill:#0f3460,color:#fff,stroke:#7f7f7f,stroke-width:1px,stroke-dasharray: 3 3
    style ExtVector fill:#0f3460,color:#fff,stroke:#7f7f7f,stroke-width:1px,stroke-dasharray: 3 3
```

---

### 📐 Mapeo de Instanciación por Dominio (Para los 7 Master Agents)

| Placeholder | `bash` | `python` | `go` | `javascript` | `yaml-json-schema` | `sql` | `postgresql-pgvector` |
|-------------|--------|----------|------|--------------|-------------------|-------|----------------------|
| `{DOMAIN}` | `bash` | `python` | `go` | `javascript` | `yaml-json-schema` | `sql` | `postgresql-pgvector` |
| `{LANGUAGE}` | `Bash` | `Python` | `Go` | `JavaScript/TypeScript` | `YAML/JSON` | `SQL` | `PLpgSQL/SQL` |
| `M2_JSON`/`M2_YAML` | `json-processing-with-jq.md`<br>`yaml-processing-with-yq.md` | `pydantic-schema-validator.md`<br>`toml-config-parser.md` | `go-json-unmarshal.md`<br>`yaml-decoder-strict.md` | `json-ajv-validation.md`<br>`yaml-parser-safe.md` | `schema-draft7-validator.md`<br>`json-path-query.md` | `jsonb-operators.md`<br>`yaml-to-sql-migration.md` | `vector-json-metadata.md`<br>`pg-yaml-config.md` |
| `Ext*` Handoffs | `python`, `go`, `postgresql-pgvector` | `bash`, `go`, `sql` | `bash`, `python`, `postgresql-pgvector` | `python`, `bash`, `sql` | `bash`, `python`, `sql` | `bash`, `go`, `postgresql-pgvector` | `bash`, `python`, `go` |

---


## 🔄 Protocolo de Handoff para Outros Domínios (LANGUAGE LOCK)
### Quando Delegar (Regra Imutável)
- 🚫 {LANGUAGE} NUNCA gera código de domínios externos sem handoff JSON.
- ✅ {LANGUAGE} PODE gerar orquestração, validação estática, wrappers seguros e logging.
### Regras de Handoff (Validáveis)
1. Incluir `tenant_id` no payload (C4)
2. Especificar `timeout_seconds` (C1)
3. Documentar `expected_output` (C5)
4. Zero hardcode de secrets (C3)
5. Registrar handoff em log estruturado (C8)

## 📊 Métricas de Qualidade do Agente {LANGUAGE}
| Métrica | Meta | Como Medir | Ferramenta |
|---------|------|-----------|-----------|
| Pass Rate em Validação | ≥95% | `orchestrator-engine --json` | orchestrator-engine |
| Tempo Médio de Validação | ≤200ms | `performance_ms` nos logs | Prometheus/Grafana |
| Taxa de Handoff Correto | 100% | Auditoria de blocos `HANDOFF_JSON` | audit-handoff-hook.sh |
| Zero Secrets em Produção | 100% | `audit-secrets.sh` | audit-secrets.sh |

## 🚫 Anti-Padrões – O Que Nunca Gerar (Lista Executável)
*(Específico do domínio {LANGUAGE}. Proibido: eval não sanitizado, variáveis sem proteção, logs textuais, ausência de trap/cleanup.)*

## 📋 Checklist de Geração – Antes de Commit (Executável)
1. ✅ Frontmatter YAML válido (C5)
2. ✅ Hardening mínimo aplicado (C7)
3. ✅ Validação de tenant presente (se aplicável) (C4)
4. ✅ `mantis_log()` implementada e validada (C8)
5. ✅ Tests TDD passam (`--test` flag)
6. ✅ `orchestrator-engine --json` retorna `passed: true`

## 🗓️ Integração com CHRONICLE.md (Auditoria Distribuída)
### Formato de Registro Padrão (JSONL)
```json
{"timestamp":"2026-05-07T00:00:00Z","event":"artifact_regenerated","artifact_id":"{domain}-master-agent-mantis","version":"2.2.0","author":"{domain}-master-agent","constraints":["C1","C2","C3","C4","C5","C6","C7","C8"],"validation_passed":true,"hash":"sha256:framework-executable-contract-v2.2.0","next_review":"2026-06-07","ai_compatibility":["qwen","deepseek","claude","minimax","mimo-xiaomi"],"notes":"Template canônico padronizado para 7 domínios PROGRAMMING"}
```
### Comandos de Consulta Úteis
```bash
grep '"artifact_id":"{domain}-master-agent-mantis"' CHRONICLE.md | jq -s
bash 05-CONFIGURATIONS/scripts/verify-chronicle-hashes.sh --artifact {domain}-master-agent-mantis
```

## 🌐 Compatibilidade Multi-IA: Diretrizes de Ingestão
### Para IAs de Contexto Amplo
- ✅ Ingestão integral permitida. Mermaid e YAML renderizáveis nativamente.
### Para IAs de Contexto Restrito
- ⚠️ Priorizar: Frontmatter, Template Interno, Anti-Padrões, Bloco de Pensamento.
### Protocolo de Fallback (Universal)
- Extrair metadados via `grep` para variáveis de ambiente. Validar constraints via `orchestrator-engine` headless.
```

---

### 📌 Notas de Aplicação para os 7 Domínios `PROGRAMMING/`
| Domínio | `{DOMAIN}` | `{LANGUAGE}` | Variação Permitida |
|---------|------------|--------------|-------------------|
| Bash | `bash` | Bash | `semantic_contract` focado em POSIX, `set -Eeuo pipefail`, `IFS`, `trap` |
| Python | `python` | Python | `semantic_contract` focado em `typing`, `pydantic`, `pytest`, `venv` |
| Go | `go` | Go | `semantic_contract` focado em `go vet`, `context`, `defer`, `structs` |
| JavaScript | `javascript` | JavaScript/TypeScript | `semantic_contract` focado em `ESLint`, `try/catch`, `async/await`, `modules` |
| YAML/JSON | `yaml-json-schema` | YAML/JSON | `semantic_contract` focado em `ajv`, `schema validation`, `strict types` |
| SQL | `sql` | SQL | `semantic_contract` focado em `parameterized queries`, `transactions`, `RLS` |
| PostgreSQL-PgVector | `postgresql-pgvector` | SQL/PLpgSQL | `semantic_contract` focado em `vectors`, `hnsw/ivfflat`, `pgvector` functions |

Protocolo e template validados sob normas MANTIS AGENTIC v2.2.0. Prontos para padronização imediata dos 7 Master Agents.
