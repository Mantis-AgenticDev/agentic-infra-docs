---
spec_version: "1.1.0"
ia_parser_compatible: true
project_id: "MANTIS-AGENTIC-001"
owner: "Facundo"
location: "Rio Grande do Sul, Brasil"
languages: ["es-AR", "pt-BR"]
last_validated: "2026-04-08"  # ← Actualizar fecha real
sdd_compliance: 98%  # ← Se actualizará automáticamente post-validación
output_schema:
  required_fields:
    - workflow_json: "n8n workflow con tenant_id en cada nodo de datos"
    - sql_migration: "migración SQL con WHERE tenant_id = ?"
    - docker_compose: "snippet con memory_limit y cpu_limit"
    - qdrant_config: "collection con filter por tenant_id"
    - validation_log: "JSON con spec_referenced, sha256, checks"
  optional_fields:
    - diagram_ascii: "diagrama de flujo en ASCII ligero (preferido sobre Mermaid)"
    - onboarding_ptbr: "guía de implementação em português"
format_preferences:
  diagram_type: "ascii"  # Preferido sobre mermaid para carga rápida
  max_token_budget: 4000  # Límite para prompts de generación
  language_priority: ["pt-BR", "es-AR", "en-US"]
  code_fences_required: true  # Todos los snippets deben usar `lenguaje`
constraints:
  C1: "max_ram_per_vps: 4GB"
  C2: "max_cpu_per_vps: 1"
  C3: "mysql_qdrant_internal_only: true"
  C4: "tenant_id_required: ALL_QUERIES"
  C5: "backup_daily_04am_aes256_sha256: true"
  C6: "no_local_models_cloud_api_only: true"
references:
  system_prompt_sdd: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/system-prompt-sdd.md"
  architecture_rules: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/01-ARCHITECTURE-RULES.md"
  resource_guardrails: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/02-RESOURCE-GUARDRAILS.md"
  multitenancy_rules: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/06-MULTITENANCY-RULES.md"
---


# 🤖 MANTIS AGENTIC - Infraestructura Agéntica Multi-Tenant

> **Especificación Maestra para Generación Automática de Código**  
> *Este documento NO es para lectura humana únicamente. Es una spec ejecutable para IAs de código.*

## Propósito Técnico (Para IA)

Cuando una IA reciba un prompt de usuario describiendo un cliente (ej: "restaurante en Gramado que necesita agendar reservas por WhatsApp"), debe:

1. **Cargar este README.md** + las specs referenciadas en `references:` del frontmatter
2. **Generar automáticamente**:
   - `workflow.json` para n8n con `tenant_id` en cada nodo que accede a datos
   - `sql-migration-tenant.sql` con `WHERE tenant_id = ?` en todas las queries
   - `docker-compose-snippet.yml` con `memory: "1500M"` para n8n y `cpus: "1.0"`
   - `qdrant-collection.yaml` con `filter: {"must": [{"key": "tenant_id"}]}`
   - `validation-log.json` con `spec_referenced`, `sha256_output`, `validation_checks`

3. **Validar** contra `validate-against-specs.sh` antes de proponer commit
4. **Retornar** solo si todos los checks pasan, o reintentar (máx 2 veces)

## Propósito Humano 

Financiar un laboratorio de microbiología/agrobiología en Rio Grande do Sul mediante servicios de automatización WhatsApp + IA para pequeños negocios locales (restaurantes, odontología, estética, pousadas) en la región de Gramado/Canela.

- **Cliente objetivo:** Pequeños negocios con 1-10 empleados, sin equipo técnico
- **Stack técnico:** Linux (Xubuntu), Docker, n8n, EspoCRM, MySQL, Qdrant, Python, OpenRouter API
- **Modelo:** R$ 297-997/mes por cliente → objetivo R$ 2.500+ netos/mes para laboratorio

**Proposta de valor para clientes**:
- Atendimento 24/7 humanizado via WhatsApp
- Base de conhecimento empresarial para onboarding de funcionários
- Integração com CRM (EspoCRM) para gestão de leads e vendas
- Baixo custo operacional graças a arquitetura leve e eficiente

---

## 📚 Documentación de Validación
- [Checklist de Validación SDD](01-RULES/validation-checklist.md)
  url: https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/validation-checklist.md
- [Guía Educativa para Estudiantes/IA](00-CONTEXT/documentation-validation-checklist.md)
  url: https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/00-CONTEXT/documentation-validation-cheklist.md 

---

## Ejemplos Mínimos Ejecutables (Para Copiar/Pegar en Generación)

### SQL con tenant_id (OBLIGATORIO en toda query)
```sql
-- ✅ CORRECTO
SELECT id, name, phone FROM contacts 
WHERE tenant_id = ? AND active = true;

-- ❌ PROHIBIDO (sin tenant_id)
SELECT id, name, phone FROM contacts WHERE active = true;
```

### Qdrant Filter con tenant_id
```json
{
  "filter": {
    "must": [
      {"key": "tenant_id", "match": {"value": "cliente_123"}},
      {"key": "status", "match": {"value": "active"}}
    ]
  },
  "params": {"shard_key": "cliente_123"}
}
```

### n8n HTTP Request Node con timeout y tenant_id
```json
{
  "parameters": {
    "url": "={{ $json.webhook_url }}",
    "method": "POST",
    "timeout": 30000,
    "options": {
      "headers": {
        "Content-Type": "application/json",
        "tenant_id": "={{ $json.tenant_id }}"
      }
    }
  },
  "name": "httpRequest",
  "type": "n8n-nodes-base.httpRequest"
}
```

### Docker Compose con Resource Limits (C1-C2)
```yaml
services:
  n8n:
    image: n8nio/n8n:latest
    deploy:
      resources:
        limits:
          memory: "1500M"  # ← C1: Máx 1.5GB para n8n
          cpus: "1.0"      # ← C2: 1 vCPU máximo
    environment:
      - MEMORY_LIMIT=1500
      - DB_TYPE=mysql
      - TENANT_ID_REQUIRED=true
```

### Logs Estructurados con tenant_id (C4)
```json
{
  "timestamp": "2026-04-XXT12:00:00Z",
  "tenant_id": "cliente_123",
  "event": "workflow_executed",
  "workflow_id": "whatsapp-reservas-v1",
  "duration_ms": 1250,
  "status": "success"
}
```
**Verificación**
```html
<!-- ✅ CHECKLIST DE VERIFICACIÓN (Para revisión humana, ignorar por IA)
- [ ] Cada ejemplo tiene comentarios ✅ CORRECTO / ❌ PROHIBIDO cuando aplica
- [ ] Todos los ejemplos incluyen tenant_id explícitamente
- [ ] Los valores numéricos coinciden con constraints
-->
```
---

## FLUJO OPENROUTER + SYSTEM PROMPT

### Flujo de Generación Automática vía OpenRouter API

┌─────────────────────────────────────────────────────┐
│  FLUJO DE GENERACIÓN AUTOMÁTICA (OpenRouter API)    │
└─────────────────────────────────────────────────────┘

[Input: Descrição do cliente em pt-BR]
                    │
                    ▼
    ┌───────────────────────────────┐
    │  OpenRouter API +             │
    │  system-prompt-sdd.md         │
    └───────────────────────────────┘
                    │
                    ▼
    ┌───────────────────────────────┐
    │  Carregar specs do frontmatter│
    │  • architecture_rules         │
    │  • resource_guardrails        │
    │  • multitenancy_rules         │
    └───────────────────────────────┘
                    │
                    ▼
    ┌───────────────────────────────┐
    │  GERAR AUTOMATICAMENTE:       │
    │  • workflow.json (n8n)        │
    │  • sql-migration-tenant.sql   │
    │  • docker-compose-snippet.yml │
    │  • qdrant-collection.yaml     │
    │  • validation-log.json        │
    └───────────────────────────────┘
                    │
                    ▼
    ┌───────────────────────────────┐
    │  Executar validate-against-   │
    │  specs.sh                     │
    └───────────────────────────────┘
                    │
        ┌──────────┴──────────┐
        ▼                     ▼
   [✅ Checks OK]      [❌ Checks FAIL]
        │                     │
        ▼                     ▼
[Propor commit]    [Reintentar (máx 2x)]
        │                     │
        └──────────┬──────────┘
                   ▼
        [Retornar JSON estructurado]

Legend:
  • tenant_id: obrigatório em TODAS as queries
  • timeout: 30s máximo por nodo HTTP
  • memory: 1500M máximo para n8n (C1)
  • cpu: 1.0 máximo por container (C2)
    
---

### System Prompt de Referencia (Resumen)

**Cada llamada a OpenRouter DEBE incluir en el system prompt:**
Eres un generador de código SDD para MANTIS AGENTIC. Reglas absolutas:
1. SPEC-FIRST: Cita siempre la spec de origen (ej: 01-RULES/06-MULTITENANCY-RULES.md#L23)
2. TENANT-AWARE: SQL/Qdrant/Logs deben incluir tenant_id en cada acceso a datos
3. HARDWARE-BOUND: Respeta C1-C6: RAM 4GB, CPU 1 vCPU, timeout 30s, backoff exponencial
4. IDEMPOTENTE: Scripts bash con set -euo pipefail + verificación de existencia
5. AUDITABLE: Retorna JSON con spec_referenced, sha256_output, validation_checks
6. PT-BR FIRST: Documentación de usuario final en portugués de Brasil
7. NO SECRETS: Usa ${ENV_VAR} o process.env, nunca hardcodear credenciales
8. ERROR HANDLING: Todo nodo HTTP con timeout + try/catch + fallback

---

## Ejemplo de Input/Output para IA

**Input del usuario (pt-BR):**
Cliente: Pousada Serra Gaúcha, Gramado. 
Necesita: Agendar check-in/check-out por WhatsApp, 
integrar con calendario, enviar recordatorios 24h antes.

**Output esperado de la IA (estructura mínima):**
```json
{
  "spec_referenced": [
    "01-RULES/06-MULTITENANCY-RULES.md#L45",
    "01-RULES/02-RESOURCE-GUARDRAILS.md#L12"
  ],
  "generated_files": {
    "workflow_json": "n8n-nodes-base.httpRequest con tenant_id...",
    "sql_migration": "CREATE TABLE bookings (id INT, tenant_id VARCHAR(32), ...)",
    "docker_snippet": "memory: \"1500M\", cpus: \"1.0\"...",
    "qdrant_config": "filter: {must: [{key: \"tenant_id\"}]}",
    "onboarding_ptbr": "Guía de 5 pasos para equipe da pousada..."
  },
  "validation_checks": {
    "tenant_id_in_all_queries": true,
    "resource_limits_defined": true,
    "timeout_explicit_in_http": true,
    "no_hardcoded_secrets": true,
    "ptbr_copy_natural": true
  },
  "sha256_output": "a1b2c3d4...",
  "next_steps": [
    "Ejecutar scripts/validate-against-specs.sh",
    "Revisar onboarding-pt-BR.md con cliente",
    "Desplegar en VPS-1 con docker-compose --env-file .env"
  ]
}
```
---


## Checklist de Validación Pré-Commit (Ejecutable)

Antes de aceptar cualquier código generado, verificar:

```bash
#!/bin/bash
# scripts/validate-readme-compliance.sh (ejemplo mínimo)

set -euo pipefail

echo "🔍 Validando README.md para SDD compliance..."

# 1. Verificar frontmatter YAML
if ! grep -q "^---$" README.md; then
  echo "❌ Falta frontmatter YAML"
  exit 1
fi

# 2. Verificar tenant_id en ejemplos de código
if ! grep -q "tenant_id" README.md; then
  echo "❌ No se encontró tenant_id en ejemplos"
  exit 1
fi

# 3. Verificar resource limits en snippets Docker
if ! grep -q 'memory: "1500M"' README.md; then
  echo "❌ Falta memory limit para n8n"
  exit 1
fi

# 4. Verificar timeout en ejemplos HTTP
if ! grep -q "timeout.*30000" README.md; then
  echo "❌ Falta timeout explícito en ejemplos HTTP"
  exit 1
fi

# 5. Verificar que no hay secrets hardcodeados
if grep -E "(sk-|ghp_|password=|api_key=)" README.md | grep -v "ENV_VAR\|process.env"; then
  echo "❌ Posibles secrets hardcodeados detectados"
  exit 1
fi

echo "✅ README.md pasó validación SDD básica"
exit 0
```

Nota: Este script es un ejemplo mínimo. El validador completo validate-against-specs.sh 
se creará en el próximo archivo prioritario.

---

## Enlaces Rápidos para IA (Raw URLs)

- PROJECT_TREE: https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/PROJECT_TREE.md
- CONTEXT INDEX: https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/00-CONTEXT/00-INDEX.md
- RULES INDEX: https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/00-INDEX.md
- VALIDATOR SCRIPT: https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/scripts/validate-against-specs.sh
- VALIDATOR CHEKLIST: https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/validation-checklist.md

## Estado de Archivos Referenciados (Para IA)

| Archivo Referenciado | Estado | Acción si No Existe |
|---------------------|--------|---------------------|
| `01-RULES/system-prompt-sdd.md` | ⬜ Pendiente | Usar prompt mínimo inline (ver abajo) |
| `scripts/validate-against-specs.sh` | ✅ Completo | Usar script mínimo del README |
| `04-WORKFLOWS/n8n/INFRA-001-*.json` | ⬜ Pendiente | Generar desde template en `05-CODE-PATTERNS-RULES.md` |
| `03-AGENTS/infrastructure/health-monitor-agent.md` | ⬜ Pendiente | Usar spec mínima en `08-SKILLS-REFERENCE.md` |

> 💡 **Instrucción para IA:** Si un archivo referenciado no existe (404), usar el fallback definido en esta tabla. Nunca inventar contenido; documentar la desviación en `validation-log.json`.

### Prompt Mínimo Fallback (si system-prompt-sdd.md no existe)
```text
Eres un generador de código SDD para MANTIS AGENTIC. Reglas:
1. Cita specs con formato: ARCHIVO.md#LÍNEA
2. Incluye tenant_id en SQL/Qdrant/Logs
3. Respeta: RAM 4GB, CPU 1 vCPU, timeout 30s
4. Scripts bash: set -euo pipefail
5. Output: JSON con spec_referenced, sha256, validation_checks
6. Documentación usuario: pt-BR primero
7. Sin secrets hardcodeados: usar ${ENV_VAR}
8. HTTP nodes: timeout + try/catch + fallback
```

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

## INFRAESTRUTURA (3 VPS - São Paulo)

| VPS   | Serviços               | Capacidade      | Recursos                   |
|-------|------------------------|-----------------|----------------------------|
| VPS-1 | n8n, uazapi, Redis     | 3 clientes Full | 4GB RAM, 1 vCPU, 50GB NVMe |
| VPS-2 | EspoCRM, MySQL, Qdrant | 6 clientes (BD) | 4GB RAM, 1 vCPU, 50GB NVMe |
| VPS-3 | n8n, uazapi (failover) | 3 clientes Full | 4GB RAM, 1 vCPU, 50GB NVMe |

**Constraints absolutos (C1-C6)**: Não negociáveis. Qualquer spec ou código que viole estes limites deve ser rejeitado pelo validador `validate-against-specs.sh`.

---

## ESTRUTURA DE DOCUMENTAÇÃO (SDD-COMPLIANT)
📁 agentic-infra-docs/
├── 📄 README.md                               ← Você está aqui (pt-BR / es-ES)
├── 📁 00-CONTEXT/                             ← Contexto base + constraints
|   ├── documentation-validation-checklist.md  ← Documentacao specificações obrigatória SPEC
│   ├── facundo-core-context.md                ← Perfil, filosofia, objetivos
│   ├── facundo-infrastructure.md              ← Infra técnica + 8 seções críticas
│   ├── facundo-business-model.md              ← Modelo de receita + projeções
│   └── 00-INDEX.md                            ← Índice de navegação para IAs
├── 📁 01-RULES/                               ← Especificações obrigatórias
|   ├── validation-checklist.md                ← Especificações obrigatória SPEC
│   ├── 00-INDEX.md                            ← Navegação + seção code generation
│   ├── 01-ARCHITECTURE-RULES.md               ← Padrões arquiteturais + templates docker
│   ├── 02-RESOURCE-GUARDRAILS.md              ← Limites RAM/CPU/disco + config .env
│   ├── 03-SECURITY-RULES.md                   ← Hardening SSH, fail2ban, .env seguro
│   ├── 04-API-RELIABILITY-RULES.md            ← Timeouts, fallbacks, backoff exponencial
│   ├── 05-CODE-PATTERNS-RULES.md              ← Templates n8n JSON + padrões JS/Python
│   ├── 06-MULTITENANCY-RULES.md               ← Schema SQL com tenant_id obrigatório
│   ├── 07-SCALABILITY-RULES.md                ← Fases 0-4 com triggers acionáveis
│   └── 08-SKILLS-REFERENCE.md                 ← Links validados + estado real de skills
├── 📁 02-SKILLS/                              ← (Em desenvolvimento) Templates executáveis
│   ├── INFRA-001-Monitor-Salud-VPS.json
│   ├── HEALTH-001-Alert-Telegram.sh
│   └── BACKUP-001-MySQL-Qdrant.sh
├── 📁 03-CLIENT-TEMPLATES/                    ← (Futuro) Workflows por segmento
│   ├── restaurante/
│   ├── odontologia/
│   ├── estetica/
│   └── pousada/
├── 🔧 validate-against-specs.sh               ← Validador automático de specs (CRÍTICO)
└── 📄 CONTRIBUTING.md                         ← Guia para contribuições SDD


---

## NAVEGAÇÃO PARA AGENTES DE IA

| Se você é uma IA gerando código...       | Comece por                                           |
|------------------------------------------|------------------------------------------------------|
| Precisa validar uma spec                 | `01-RULES/00-INDEX.md` → `validate-against-specs.sh` → `01-RULES/validation-checklist.md` →  `00-CONTEXT/documentation-validation-checklist.md` |
| Precisa de template docker-compose       | `01-RULES/01-ARCHITECTURE-RULES.md` → `validate-against-specs.sh` → `01-RULES/validation-checklist.md` →  `00-CONTEXT/documentation-validation-checklist.md` |
| Precisa de padrão SQL multi-tenant       | `01-RULES/06-MULTITENANCY-RULES.md` → `validate-against-specs.sh` → `01-RULES/validation-checklist.md` →  `00-CONTEXT/documentation-validation-checklist.md` |
| Precisa de workflow n8n base             | `01-RULES/05-CODE-PATTERNS-RULES.md`                 |
| Precisa entender constraints de recursos | `01-RULES/02-RESOURCE-GUARDRAILS.md`                 |
| Precisa de contexto do usuário           | `00-CONTEXT/facundo-core-context.md`                 |

**Regra de ouro**: Nenhuma geração de código sem spec prévia validada. Se houver conflito entre código e spec, a spec prevalece.

### 🧭 Navegación Eficiente para IAs (Optimización de Tokens)

> **Instrucción crítica**: Antes de explorar cualquier carpeta, **leer primero** el grafo estructural para mapear relaciones y priorizar archivos:
> 
> 🔗 `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/knowledge-graph.json`
>
> **Por qué**: El grafo contiene:
> - `nodes[].priority`: Filtra por "Siempre" > "Alta" > "Media" > "Baja"
> - `nodes[].constraints`: Identifica archivos con C1-C6 aplicados
> - `edges[]`: Navegación semántica sin explorar carpetas vacías
> - `nodes[].domain`: Filtra por vertical (INFRAESTRUCTURA, SEGURIDAD, etc.)
>
> **Ejemplo de query eficiente**:
> ```json
> // Obtener solo archivos de SEGURIDAD con prioridad Alta
> GET /knowledge-graph.json
> → Filtrar: nodes where domain includes "SEGURIDAD" AND priority == "Alta"
> → Seguir edges para dependencias
> ```

---

## SEGURANÇA E CONFORMIDADE

- 🔒 Repositório privado • Acesso por SSH key apenas
- 🔐 Credenciais NUNCA commitadas • Use `.env.example` como template
- 🛡️ UFW + fail2ban + SSH hardening em produção (ver `03-SECURITY-RULES.md`→ `validate-against-specs.sh` → `01-RULES/validation-checklist.md` →  `00-CONTEXT/documentation-validation-checklist.md`)
- 📊 Logging obrigatório: toda execução de workflow gera registro em MySQL com `tenant_id`
- 🔄 Backup diário 04:00 AM: MySQL + Qdrant + configs • Encriptação AES-256 • Checksum SHA256

---

## FLUXO DE TRABALHO SDD

 1. Especificar → 2. Validar spec → 3. Gerar código → 4. Validar código contra spec → 5. Testar → 6. Documentar
 
 
**Ferramentas de validação**:
- `validate-against-specs.sh`: Valida YAML/JSON/SQL contra schemas definidos em `01-RULES/`
- `01-RULES/validation-checklist.md` →  `00-CONTEXT/documentation-validation-checklist.md`
- `docker-compose config`: Valida sintaxe de compose antes de deploy
- `sqlfluff`: Linter SQL com regra personalizada para `tenant_id` obrigatório

**Status do validador**: 🚧 Em desenvolvimento (prioridade crítica)

---

## ROADMAP (Reorientado para Serviços Locais)

| Fase                             | Semanas | Entregáveis                                                                                  | Status          |
|----------------------------------|---------|----------------------------------------------------------------------------------------------|-----------------|
| **Fase 0: Fundamentos SDD**      | 1-2     | `validate-against-specs.sh`, README atualizado, specs críticas validadas                     | ✅ Completado   |
| **Fase 1: MVP Infraestrutura**   | 3-5     | Workflow `INFRA-001-Monitor-Salud-VPS`, Docker Compose com resource limits, backup funcional | ⏸️ Pendente     |
| **Fase 2: Agente WhatsApp Base** | 6-8     | Template n8n para atendimento restaurante (texto + imagem), integração EspoCRM, RAG leve     | ⏸️ Pendente     |
| **Fase 3: Cliente Piloto**       | 9-12    | 1-3 clientes reais em Gramado/Canela, SLA 99%, documentação de onboarding                    | ⏸️ Pendente     |
| **Fase 4: Escala Controlada**    | 13-16   | 6-9 clientes, failover testado, receita recorrente validada                                  | ⏸️ Pendente     |

---

## CONTRIBUIÇÕES (SDD MODE)

1. Leia `01-RULES/00-INDEX.md` antes de qualquer alteração
2. Nenhuma spec nova sem discussão prévia via issue
3. Todo código deve passar por `validate-against-specs.sh` antes do commit
4. Commits devem referenciar a spec validada: `feat: INFRA-001 per 01-ARCHITECTURE-RULES.md#L45`
5. Documentação em pt-BR primeiro, es-ES como secundário

---

## 🔍 NAVEGACIÓN PARA IAs

| Si eres una IA generando código... | Comienza por                                         |
|------------------------------------|------------------------------------------------------|
| Validar una spec                   | `01-RULES/00-INDEX.md` → `validate-against-specs.sh` |
| Cheklist Validation                | `01-RULES/validation-checklist.md` →  `00-CONTEXT/documentation-validation-checklist.md`|
| Template docker-compose            | `01-RULES/01-ARCHITECTURE-RULES.md`                  |
| Patrón SQL multi-tenant            | `01-RULES/06-MULTITENANCY-RULES.md`                  |
| Workflow n8n base                  | `01-RULES/05-CODE-PATTERNS-RULES.md`                 |

**Regla de oro**: Ningún código sin spec previa validada. Si hay conflicto → spec > código.


### 🧭 Navegación Eficiente para IAs (Optimización de Tokens)

> **Instrucción crítica**: Antes de explorar cualquier carpeta, **leer primero** el grafo estructural para mapear relaciones y priorizar archivos:
> 
> 🔗 `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/knowledge-graph.json`
>
> **Por qué**: El grafo contiene:
> - `nodes[].priority`: Filtra por "Siempre" > "Alta" > "Media" > "Baja"
> - `nodes[].constraints`: Identifica archivos con C1-C6 aplicados
> - `edges[]`: Navegación semántica sin explorar carpetas vacías
> - `nodes[].domain`: Filtra por vertical (INFRAESTRUCTURA, SEGURIDAD, etc.)
>
> **Ejemplo de query eficiente**:
> ```json
> // Obtener solo archivos de SEGURIDAD con prioridad Alta
> GET /knowledge-graph.json
> → Filtrar: nodes where domain includes "SEGURIDAD" AND priority == "Alta"
> → Seguir edges para dependencias
> ```


## 🔄 FLUJO SDD

Especificar → Validar spec → Generar código → Validar código → Testear → Documentar

---

```markdown
> **Estado SDD:** 🟡 En transición ( 98% → 100% objetivo)  
> **Última validación automática:** Pendiente (ejecutar `scripts/validate-against-specs.sh`)  
> **Última edición humana:** Facundo - 2026-04-09  
> **Próxima revisión programada:** +14 días  
> **Compatibilidad IA:** ✅ Frontmatter + ASCII diagram + snippets ejecutables  
> **Licencia:** CC BY-SA 4.0 (documentación) / Propietario (código generado)  
> **Raw URL para IA:** https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/README.md  
> **SHA256 (post-edición):** [CALCULAR CON: sha256sum README.md]
```

*Principio SDD: Si hay conflicto entre este texto y el código generado, la spec escrita aquí prevalece. Desviaciones deben documentarse en validation-log.json.*

---

FIN DEL ARCHIVO - README.md

