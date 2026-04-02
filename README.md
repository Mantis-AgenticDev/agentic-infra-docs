---
# METADADOS PARA NAVEGAÇÃO DE IA / METADATA FOR AI NAVIGATION
project: MANTIS AGENTIC
methodology: Specification-Driven Development (SDD)
version: 2.0.0-SDD
language_priority: pt-BR > es-ES
target_audience: pequenos_negocios_gramado_canela_RS
infrastructure: multi-tenant_whatsapp_agents_rag_crm
validation_required: true
spec_first: true
constraints: C1-C6_non_negotiable
ai_navigation:
  - start_here: 00-INDEX.md
  - rules: 01-RULES/
  - skills: 02-SKILLS/ (em desenvolvimento)
  - context: 00-CONTEXT/
  - validate: validate-against-specs.sh
---

# MANTIS AGENTIC • Infraestrutura Agéntica Multi-Tenant para Atendimento WhatsApp

**Proprietário**: Mantis-AgenticDev (Facundo)  
**Localização**: Gramado / Canela / Porto Alegre, Rio Grande do Sul, Brasil  
**Idiomas**: Português (BR) • Español (ES)  
**Versão**: 2.0.0-SDD  
**Estado**: 🚧 Desenvolvimento Ativo (Privado)  
**Metodologia**: Specification-Driven Development (SDD) • Spec > Código  

---

## 🎯 PROPÓSITO DO PROJETO

Infraestrutura multi-tenant para automação de atendimento via WhatsApp com IA + RAG + CRM, destinada a **pequenos negócios locais** (restaurantes, odontologia, estética, pousadas, delivery, pizzerias) na região de Gramado e Canela, RS.

**Objetivo financeiro**: Gerar receita recorrente (R$ 2.500+/mês líquidos) para capitalizar laboratório de microbiologia/agrobiologia em área rural — estratégia de ponte financeira.

**Proposta de valor para clientes**:
- Atendimento 24/7 humanizado via WhatsApp
- Base de conhecimento empresarial para onboarding de funcionários
- Integração com CRM (EspoCRM) para gestão de leads e vendas
- Baixo custo operacional graças a arquitetura leve e eficiente

---

## 🤖 ARQUITETURA DE AGENTES

[Cliente WhatsApp] 
       ↓
[UazAPI Webhook] → [n8n Orchestrator] → [Redis Buffer + Dedup]
       ↓                                    ↓
[Router por Tipo]                   [LLM + Tools Externas]
(texto/áudio/imagem)                (EspoCRM, Qdrant, Google Sheets)
       ↓                                    ↓
[Output Parser Estruturado] → [Resposta WhatsApp + Logging]
       ↓
[Atualização CRM + RAG Index]


**Padrões críticos**:
- `tenant_id` obrigatório em TODAS as consultas SQL/Qdrant (C4)
- Timeout máximo 30s por nodo HTTP, 90s por workflow (C2)
- Memory guard: n8n limitado a 1.5GB RAM (C1)
- Backup diário 04:00 AM com encriptação AES-256 + checksum SHA256 (C5)

---

## 🏗️ INFRAESTRUTURA (3 VPS - São Paulo)

| VPS   | Serviços               | Capacidade      | Recursos                   |
|-------|------------------------|-----------------|----------------------------|
| VPS-1 | n8n, uazapi, Redis     | 3 clientes Full | 4GB RAM, 1 vCPU, 50GB NVMe |
| VPS-2 | EspoCRM, MySQL, Qdrant | 6 clientes (BD) | 4GB RAM, 1 vCPU, 50GB NVMe |
| VPS-3 | n8n, uazapi (failover) | 3 clientes Full | 4GB RAM, 1 vCPU, 50GB NVMe |

**Constraints absolutos (C1-C6)**: Não negociáveis. Qualquer spec ou código que viole estes limites deve ser rejeitado pelo validador `validate-against-specs.sh`.

---

## 📚 ESTRUTURA DE DOCUMENTAÇÃO (SDD-COMPLIANT)
📁 agentic-infra-docs/
├── 📄 README.md                    ← Você está aqui (pt-BR / es-ES)
├── 📁 00-CONTEXT/                  ← Contexto base + constraints
│   ├── facundo-core-context.md     ← Perfil, filosofia, objetivos
│   ├── facundo-infrastructure.md   ← Infra técnica + 8 seções críticas
│   ├── facundo-business-model.md   ← Modelo de receita + projeções
│   └── 00-INDEX.md                 ← Índice de navegação para IAs
├── 📁 01-RULES/                    ← Especificações obrigatórias
│   ├── 00-INDEX.md                 ← Navegação + seção code generation
│   ├── 01-ARCHITECTURE-RULES.md    ← Padrões arquiteturais + templates docker
│   ├── 02-RESOURCE-GUARDRAILS.md   ← Limites RAM/CPU/disco + config .env
│   ├── 03-SECURITY-RULES.md        ← Hardening SSH, fail2ban, .env seguro
│   ├── 04-API-RELIABILITY-RULES.md ← Timeouts, fallbacks, backoff exponencial
│   ├── 05-CODE-PATTERNS-RULES.md   ← Templates n8n JSON + padrões JS/Python
│   ├── 06-MULTITENANCY-RULES.md    ← Schema SQL com tenant_id obrigatório
│   ├── 07-SCALABILITY-RULES.md     ← Fases 0-4 com triggers acionáveis
│   └── 08-SKILLS-REFERENCE.md      ← Links validados + estado real de skills
├── 📁 02-SKILLS/                   ← (Em desenvolvimento) Templates executáveis
│   ├── INFRA-001-Monitor-Salud-VPS.json
│   ├── HEALTH-001-Alert-Telegram.sh
│   └── BACKUP-001-MySQL-Qdrant.sh
├── 📁 03-CLIENT-TEMPLATES/         ← (Futuro) Workflows por segmento
│   ├── restaurante/
│   ├── odontologia/
│   ├── estetica/
│   └── pousada/
├── 🔧 validate-against-specs.sh    ← Validador automático de specs (CRÍTICO)
└── 📄 CONTRIBUTING.md              ← Guia para contribuições SDD


---

## 🔍 NAVEGAÇÃO PARA AGENTES DE IA

| Se você é uma IA gerando código...       | Comece por                                           |
|------------------------------------------|------------------------------------------------------|
| Precisa validar uma spec                 | `01-RULES/00-INDEX.md` → `validate-against-specs.sh` |
| Precisa de template docker-compose       | `01-RULES/01-ARCHITECTURE-RULES.md`                  |
| Precisa de padrão SQL multi-tenant       | `01-RULES/06-MULTITENANCY-RULES.md`                  |
| Precisa de workflow n8n base             | `01-RULES/05-CODE-PATTERNS-RULES.md`                 |
| Precisa entender constraints de recursos | `01-RULES/02-RESOURCE-GUARDRAILS.md`                 |
| Precisa de contexto do usuário           | `00-CONTEXT/facundo-core-context.md`                 |

**Regra de ouro**: Nenhuma geração de código sem spec prévia validada. Se houver conflito entre código e spec, a spec prevalece.

---

## 🔐 SEGURANÇA E CONFORMIDADE

- 🔒 Repositório privado • Acesso por SSH key apenas
- 🔐 Credenciais NUNCA commitadas • Use `.env.example` como template
- 🛡️ UFW + fail2ban + SSH hardening em produção (ver `03-SECURITY-RULES.md`)
- 📊 Logging obrigatório: toda execução de workflow gera registro em MySQL com `tenant_id`
- 🔄 Backup diário 04:00 AM: MySQL + Qdrant + configs • Encriptação AES-256 • Checksum SHA256

---

## 🔄 FLUXO DE TRABALHO SDD

 1. Especificar → 2. Validar spec → 3. Gerar código → 4. Validar código contra spec → 5. Testar → 6. Documentar
 
 
**Ferramentas de validação**:
- `validate-against-specs.sh`: Valida YAML/JSON/SQL contra schemas definidos em `01-RULES/`
- `docker-compose config`: Valida sintaxe de compose antes de deploy
- `sqlfluff`: Linter SQL com regra personalizada para `tenant_id` obrigatório

**Status do validador**: 🚧 Em desenvolvimento (prioridade crítica)

---

## 📈 ROADMAP (Reorientado para Serviços Locais)

| Fase                             | Semanas | Entregáveis                                                                                  | Status          |
|----------------------------------|---------|----------------------------------------------------------------------------------------------|-----------------|
| **Fase 0: Fundamentos SDD**      | 1-2     | `validate-against-specs.sh`, README atualizado, specs críticas validadas                     | 🔄 Em andamento |
| **Fase 1: MVP Infraestrutura**   | 3-5     | Workflow `INFRA-001-Monitor-Salud-VPS`, Docker Compose com resource limits, backup funcional | ⏸️ Pendente     |
| **Fase 2: Agente WhatsApp Base** | 6-8     | Template n8n para atendimento restaurante (texto + imagem), integração EspoCRM, RAG leve     | ⏸️ Pendente     |
| **Fase 3: Cliente Piloto**       | 9-12    | 1-3 clientes reais em Gramado/Canela, SLA 99%, documentação de onboarding                    | ⏸️ Pendente     |
| **Fase 4: Escala Controlada**    | 13-16   | 6-9 clientes, failover testado, receita recorrente validada                                  | ⏸️ Pendente     |

---

## 🤝 CONTRIBUIÇÕES (SDD MODE)

1. Leia `01-RULES/00-INDEX.md` antes de qualquer alteração
2. Nenhuma spec nova sem discussão prévia via issue
3. Todo código deve passar por `validate-against-specs.sh` antes do commit
4. Commits devem referenciar a spec validada: `feat: INFRA-001 per 01-ARCHITECTURE-RULES.md#L45`
5. Documentação em pt-BR primeiro, es-ES como secundário

---

> **Nota estratégica**: Este projeto é uma ponte financeira. O sucesso na prestação de serviços para pequenos negócios locais viabiliza o laboratório de microbiologia/agrobiologia de longo prazo. Priorize estabilidade, simplicidade e suporte em português para o mercado de Gramado/Canela.

*Última atualização: $(date +%Y-%m-%d) • Próxima revisão: +14 dias*

---

## 📄 VERSIÓN EN ESPAÑOL (RESUMEN EJECUTIVO)

# MANTIS AGENTIC • Infraestructura Agéntica Multi-Tenant para Atención WhatsApp

**Propietario**: Mantis-AgenticDev (Facundo)  
**Ubicación**: Gramado / Canela / Porto Alegre, Rio Grande do Sul, Brasil  
**Idiomas**: Português (BR) • Español (ES)  
**Versión**: 2.0.0-SDD  
**Estado**: 🚧 Desarrollo Activo (Privado)  
**Metodología**: Specification-Driven Development (SDD) • Spec > Código  

## 🎯 PROPÓSITO

Infraestructura multi-tenant para automatización de atención vía WhatsApp con IA + RAG + CRM, destinada a **pequeños negocios locales** (restaurantes, odontología, estética, pousadas, delivery, pizzerías) en la región de Gramado y Canela, RS.

**Objetivo financiero**: Generar ingresos recurrentes (R$ 2.500+/mes netos) para capitalizar laboratorio de microbiología/agrobiología en área rural — estrategia de puente financiero.

## 🔍 NAVEGACIÓN PARA IAs

| Si eres una IA generando código... | Comienza por                                         |
|------------------------------------|------------------------------------------------------|
| Validar una spec                   | `01-RULES/00-INDEX.md` → `validate-against-specs.sh` |
| Template docker-compose            | `01-RULES/01-ARCHITECTURE-RULES.md`                  |
| Patrón SQL multi-tenant            | `01-RULES/06-MULTITENANCY-RULES.md`                  |
| Workflow n8n base                  | `01-RULES/05-CODE-PATTERNS-RULES.md`                 |

**Regla de oro**: Ningún código sin spec previa validada. Si hay conflicto → spec > código.

## 🔄 FLUJO SDD

Especificar → Validar spec → Generar código → Validar código → Testear → Documentar


*Última actualización: $(date +%Y-%m-%d)*
