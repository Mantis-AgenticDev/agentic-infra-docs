---
file_id: CNT-INDEX-000
file_name: 00-INDEX.md
version: 2.0.0-SDD
created: 2026-04-01
last_updated: 2026-04-01
author: Facundo (Mantis-AgenticDev)
category: CONTEXT_INDEX
priority: CRITICAL
language_primary: pt-BR
language_secondary: es-ES
sdd_mode: true
openrouter_enabled: true
auto_generation_ready: true
ai_navigation:
  start_here: true
  required_before_code_gen: true
  validates_against: 
    - 01-RULES/00-INDEX.md
    - 01-RULES/02-RESOURCE-GUARDRAILS.md
tags:
  - index
  - sdd
  - openrouter
  - ai-navigation
  - context
related_files:
  - facundo-core-context.md
  - facundo-infrastructure.md
  - ../01-RULES/00-INDEX.md
  - ../04-PROMPTS-OPENROUTER/system-prompt-sdd.md
  
---
## 🗺️ 00-INDEX • Mapa de Navegação para IAs (SDD + OpenRouter)

⚠️ REGRA DE OURO SDD: Nenhuma IA gera código sem ler este índice primeiro. Spec > Código. Sempre.

🧭 ONDE COMEÇAR (Ordem Obrigatória para Geração Automática)

|Se você é...	                    |Leia nesta ordem EXATA	                                                                                            |Por quê?                                                                        |
|-----------------------------------|-------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------|
|IA gerando código via OpenRouter	|1. 01-RULES/00-INDEX.md → 2. 04-PROMPTS-OPENROUTER/system-prompt-sdd.md → 3. 01-RULES/05-CODE-PATTERNS-RULES.md	|Garante que o output respeita constraints C1-C6, tenant_id e limites de hardware|
|Humano descrevendo cliente	        |1. README.md → 2. facundo-core-context.md → 3. 04-PROMPTS-OPENROUTER/workflow-generator-pt-BR.md	                |Entende o propósito, as restrições e como formatar a descrição do cliente       |
|Validador SDD	                    |validate-against-specs.sh + 01-RULES/00-INDEX.md	                                                                |Verifica se cada arquivo gerado passa pelos checks automáticos                  |

## 🤖 FLUXO DE GERAÇÃO AUTOMATIZADA VIA OPENROUTER

```mermaid
graph LR
    A[📝 Você descreve o cliente<br/>em pt-BR] --> B[🔌 OpenRouter API]
    B --> C[🧠 System Prompt SDD<br/>+ Specs de referência]
    C --> D[✨ Geração Automática de:]
    D --> D1[📄 workflow.json n8n]
    D --> D2[🗄️ sql-migration-tenant.sql]
    D --> D3[🐳 docker-compose.yml]
    D --> D4[🔍 qdrant-collection.yaml]
    D --> D5[📚 onboarding-pt-BR.md]
    D --> D6[🔧 validation-report.json]
    D1 & D2 & D3 & D4 & D5 & D6 --> E[✅ validate-against-specs.sh]
    E -->|✅ Aprovado| F[📁 03-CLIENT-INSTANCES/cliente-XXX/]
    E -->|❌ Rejeitado| G[🔄 IA reescreve<br/>máx 2 retries]
    F --> H[👁️ Verificação Humana Leve]
    H --> I[🚀 Deploy Automatizado]
    ``
    
    
## ⚙️ PRINCÍPIOS ABSOLUTOS PARA GERAÇÃO VIA API (System Prompt Base)

Estes princípios DEVEM estar no system_prompt de qualquer chamada à OpenRouter:

## SYSTEM PROMPT BASE - GERAÇÃO SDD VIA OPENROUTER

Você é um engenheiro de automação especializado em Specification-Driven Development (SDD) para pequenos negócios no Brasil.

## REGRAS ABSOLUTAS (NUNCA VIOLAR):

1. SPEC-FIRST: Nunca gere código sem citar a spec de origem.
   Formato obrigatório: `01-RULES/06-MULTITENANCY-RULES.md#L23`

2. TENANT-AWARE: Toda query SQL, filtro Qdrant ou log DEVE conter:
   - SQL: `WHERE tenant_id = ?`
   - Qdrant: `"filter": {"must": [{"key": "tenant_id", ...}]}`
   - Logs: `"tenant_id": "cliente_XXX"`

3. HARDWARE-BOUND: Respeite os limites da VPS alvo:
   - RAM total: 4GB → n8n limitado a 1.5GB
   - CPU: 1 vCPU → sem processamento paralelo pesado
   - Timeout HTTP: 30s máximo por nodo
   - Backoff exponencial: 5s → 15s → 45s

4. IDERPOTENTE: Scripts bash devem ser seguros para reexecução:
   ```bash
   #!/bin/bash
   set -euo pipefail
   if [ -f /path/to/marker ]; then exit 0; fi
   # ... lógica ...
   touch /path/to/marker
```

**AUDITÁVEL:** Retorne JSON estruturado com: 
```json
{
  "spec_referenced": "01-RULES/05-CODE-PATTERNS-RULES.md#L45",
  "files_generated": [
    {"path": "02-SKILLS/whatsapp-agent/AGENT-XXX/workflow.json", "sha256": "..."}
  ],
  "validation_checks": ["tenant_id_present", "memory_limit_set", "timeout_defined"],
  "notes_human_reviewer": "Revisar copy da mensagem de boas-vindas"
}
```

PT-BR FIRST: Copy, mensagens de usuário e documentação em português do Brasil.
Espanhol apenas como secundário para documentação técnica.
NO HARDCODED SECRETS: Nunca inclua credenciais no código gerado.
Use sempre: ${ENV_VAR} ou process.env.VAR_NAME
ERROR HANDLING: Todo nodo HTTP deve ter:

    timeout explícito
    try/catch ou equivalente
    fallback configurado (quando aplicável)
    

---

## 🧩 EXEMPLO PRÁTICO: DE DESCRIÇÃO A CÓDIGO

### Entrada (Você descreve):

```text
Cliente: Pizzaria Bella Canela
Segmento: Restaurante delivery
Necessidades:
- Atendimento WhatsApp 24/7 para pedidos
- Cardápio em RAG (PDF + imagens)
- CRM para registrar leads e vendas
- Backup diário dos dados
- Alertas Telegram se cair
```

## Prompt para OpenRouter (montado automaticamente):

[SYSTEM PROMPT BASE acima] + 

CONTEXTO DO CLIENTE:
{
  "tenant_id": "pizzaria-bella-canela-001",
  "segmento": "restaurante_delivery",
  "necessidades": ["whatsapp_24_7", "rag_menu", "crm_leads", "backup_diario", "alertas_telegram"],
  "hardware_target": "vps_kvm1_4gb",
  "language": "pt-BR"
}

SPECS DE REFERÊNCIA:
- 01-RULES/06-MULTITENANCY-RULES.md (isolamento de dados)
- 01-RULES/02-RESOURCE-GUARDRAILS.md (limites de recursos)
- 01-RULES/05-CODE-PATTERNS-RULES.md (padrões de código)

GERE:
1. workflow.json para n8n com:
   - Webhook uazapi → Router por tipo → LLM + RAG → Resposta WhatsApp
   - tenant_id em cada nodo de dados
   - timeout 30s em HTTP Request nodes
2. sql-migration-tenant.sql com:
   - Tabela leads com tenant_id NOT NULL + índice
   - Tabela pedidos com foreign key para leads
3. docker-compose.yml com:
   - memory: "1500M" para n8n
   - networks internas para MySQL/Qdrant
4. qdrant-collection.yaml com:
   - collection_name: "rag_pizzaria_bella_canela_001"
   - payload_schema incluindo tenant_id
5. onboarding-pt-BR.md com:
   - Passo a passo para funcionário novo
   - Exemplos de mensagens em pt-BR

RETORNE no formato JSON especificado no system prompt.

**Saída Esperada (resumo):**

```json
{
  "spec_referenced": "01-RULES/05-CODE-PATTERNS-RULES.md#L45",
  "files_generated": [
    {"path": "02-SKILLS/whatsapp-agent/AGENT-PIZZA-001/workflow.json", "sha256": "a1b2c3..."},
    {"path": "02-SKILLS/whatsapp-agent/AGENT-PIZZA-001/migration.sql", "sha256": "d4e5f6..."},
    {"path": "02-SKILLS/whatsapp-agent/AGENT-PIZZA-001/docker-compose.yml", "sha256": "g7h8i9..."}
  ],
  "validation_checks": [
    "tenant_id_present_in_sql",
    "memory_limit_1500M_in_compose",
    "timeout_30s_in_http_nodes",
    "no_hardcoded_creds",
    "pt-BR_copy_in_onboarding"
  ],
  "notes_human_reviewer": "Revisar tom da mensagem de boas-vindas para mais caloroso. Ajustar RAG para aceitar imagens de cardápio."
}
```

## 📁 ESTRUTURA ESPERADA APÓS GERAÇÃO

02-SKILLS/
├── whatsapp-agent/
│   └── AGENT-RESTAURANTE-BASE/
│       ├── spec.md                    ← Especificação em markdown
│       ├── workflow.json              ← Workflow n8n gerado
│       ├── espocrm-schema.json        ← Campos personalizados CRM
│       ├── qdrant-collection.yaml     ← Config coleção RAG
│       ├── sql-migration-tenant.sql   ← Migração DB com tenant_id
│       ├── docker-compose-snippet.yml ← Trecho para deploy
│       └── onboarding-pt-BR.md        ← Guia para funcionário
│
03-CLIENT-INSTANCES/
└── cliente-001-pizzaria-bella-canela/
    ├── generated/                     ← Código gerado (não editar manualmente)
    │   ├── workflow.json
    │   ├── migration.sql
    │   └── docker-compose.yml
    ├── overrides/                     ← Ajustes manuais pós-geração (se necessário)
    │   └── custom-prompts.md
    ├── deploy/                        ← Scripts de implantação específicos
    │   ├── deploy.sh
    │   └── rollback.sh
    └── validation-log.json            ← Registro da validação SDD
    
    
## ✅ CHECKLIST DE VALIDAÇÃO PRÉ-COMMIT (Para Humanos e IAs)
Antes de qualquer commit, verifique:

- [ ] tenant_id aparece em TODAS as queries SQL? (WHERE tenant_id = ?)
- [ ] tenant_id aparece em TODOS os filtros Qdrant? ("key": "tenant_id")
- [ ] memory: e cpus: definidos em docker-compose.yml? (memory: "1500M")
- [ ] timeout explícito em cada node httpRequest do n8n? (timeout: 30000)
- [ ] Nenhuma credencial hardcoded? (usar ${ENV_VAR} ou process.env)
- [ ] spec_referenced presente no JSON de geração?
- [ ] validate-against-specs.sh retorna exit 0?
- [ ] Copy em pt-BR revisada para tom natural (não robótico)?

    💡 Dica amiga: Se falhar em qualquer item acima, NÃO force o commit. Corrija na spec ou ajuste o prompt de geração. A paciência inicial economiza 80% do tempo de debug futuro.


## 🔗 URLS RAW PARA IAs (Quando o repo for público)

Base: https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/

Índice de Contexto:
→ https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/00-CONTEXT/00-INDEX.md

Specs de Regras:
→ https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/01-RULES/00-INDEX.md
→ https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/01-RULES/06-MULTITENANCY-RULES.md

Prompts para OpenRouter:
→ https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/04-PROMPTS-OPENROUTER/system-prompt-sdd.md

Templates de Skills:
→ https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/02-SKILLS/whatsapp-agent/AGENT-RESTAURANTE-BASE/spec.md


## 🔄 ATUALIZAÇÃO E MANUTENÇÃO

Este arquivo é revisado trimestralmente ou ante mudanças estruturais
Qualquer modificação requer:
Validação contra facundo-core-context.md
Atualização de version e last_updated no frontmatter YAML
Commit com mensagem clara: docs: atualizar 00-INDEX.md para fluxo OpenRouter v2

 🌟 Nota Estratégica: Este índice é a ponte entre sua descrição em linguagem natural e o código gerado.
  Quanto mais clara e estruturada for a descrição do cliente, mais precisa será a geração automática. 
  Invista tempo em descrever bem — o resto a IA faz.

Última atualização: $(date +%Y-%m-%d) • Próxima revisão: +90 dias • Versão: 2.0.0-SDD
last_updated: "{{DATE}}"  # Substituir via script pre-commit ou manualmente
  
