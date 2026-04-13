---
title: "PROJECT TREE - Agentic Infra Docs"
category: "Documentación"
priority: "Siempre"
version: "2.1.0"
last_updated: "2026-04-08"
language: "es"
repository: "agentic-infra-docs"
owner: "Mantis-AgenticDev"
type: "documentation"
ia_parser_version: "2.0"
auto_validate: false
compliance_check: "on-demand"
tags:
  - tree
  - structure
  - navigation
  - project-map
related_files:
  - "README.md"
  - "PROJECT_OVERVIEW.md"
  - "00-CONTEXT/00-INDEX.md"
validation_script: "scripts/validate-project-tree.sh"
validation_status: "passed"
validation_status: "passed"
severity_scope: "low"
---
<!-- IA-NAVIGATION
priority_files:
  - "PROJECT_OVERVIEW.md"
  - "00-CONTEXT/facundo-core-context.md"
  - "01-RULES/00-INDEX.md"
  - "01-RULES/02-RESOURCE-GUARDRAILS.md"
always_keep_in_context:
  - "00-CONTEXT/"
  - "01-RULES/02-RESOURCE-GUARDRAILS.md"
  - "01-RULES/03-SECURITY-RULES.md"
load_strategy: "progressive"
max_tokens_per_session: 8000
-->

---

# 🌳 Árbol Completo del Proyecto - Agentic Infrastructure

**Repositorio:** agentic-infra-docs  
**Owner:** Mantis-AgenticDev (Facundo)  
**Última actualización:** Abril 2026  
**Estado:** 🚧 En desarrollo

---

## LEYENDA DE ESTADOS

| Símbolo | Estado      | Significado                      |
|---------|-------------|----------------------------------|
| ✅      | COMPLETADO  | Archivo creado y subido a GitHub |
| 🆕      | PENDIENTE   | Archivo por crear                |
| 📝      | EN PROGRESO | Archivo siendo editado           |
| 📋      | PLANEADO    | Definido pero no iniciado        |


agentic-infra-docs/
│
├── README.md                                 ✅ COMPLETADO
│   └── Presentación general del repositorio
│
├── .gitignore                                ✅ COMPLETADO
│   └── Reglas para no subir archivos sensibles
│
├── PROJECT_TREE.md                           📝 EN PROGRESO
│   └── Este archivo - mapa del proyecto
│
├── knowledge-graph.json                           📝 EN PROGRESO
|
├── SDD-COLLABORATIVE-GENERATION.md           ✅ COMPLETADO
│   └── Sistema colaborativo IA Humano para generacion archivos internos del proyecto.
│
├── 00-CONTEXT/
│   ├── 00-INDEX.md                           ✅ COMPLETADO
│   │   └── Índice con URLs raw de todos los archivos de contexto
│   │
│   ├── PROJECT_OVERVIEW.md                   ✅ COMPLETADO 
│   │   └── Visión general bilingüe (ES+PT-BR) del proyecto completo
│   │
│   ├── README.md                             ✅ COMPLETADO
│   │   └── Reglas del repositorio, accesible para todas las IAs
│   │
│   ├── facundo-core-context.md               ✅ COMPLETADO 
│   │   └── Contexto base del usuario: dominio, stack, forma de trabajo
│   │
│   ├── facundo-infrastructure.md             ✅ COMPLETADO
│   │   └── Detalle técnico de infraestructura (3 VPS, specs, red)
│   │
│   |── facundo-business-model.md             ✅ COMPLETADO
│   |   └── Modelo de negocio, pricing, SLA, proyecciones financieras
|   |
│   │
│   └── documentation-validation-cheklist.md ✅ COMPLETADO
│       └── Es material educativo de contexto; ayuda a entender el "por qué" 
|           de Reglas, Constraits, Validacion, Referencias
|
|
│
├── 01-RULES/
|   |
|   ├── validation-cheklist.md                ✅ COMPLETADO
|   |   └── Está directamente ligado a las reglas de validación; referencia MT-001, API-001, etc.
|   |
│   ├── 00-INDEX.md                           ✅ COMPLETADO
│   │   └── Índice de todas las rules con URLs raw y flujo de lectura
│   │
│   ├── 01-ARCHITECTURE-RULES.md              ✅ COMPLETADO
│   │   └── Constraints de infraestructura (VPS, Docker, red, servicios)
│   │
│   ├── 02-RESOURCE-GUARDRAILS.md             ✅ COMPLETADO
│   │   └── Límites de recursos para VPS 4GB RAM (memoria, CPU, polling)
│   │
│   ├── 03-SECURITY-RULES.md                  ✅ COMPLETADO
│   │   └── Seguridad de VPS: UFW, SSH, fail2ban, permisos, secretos
│   │
│   ├── 04-API-RELIABILITY-RULES.md           ✅ COMPLETADO
│   │   └── Estándar de fiabilidad para APIs externas (OpenRouter, Telegram, Gmail)
│   │
│   ├── 05-CODE-PATTERNS-RULES.md             ✅ COMPLETADO
│   │   └── Patrones de código para JS, Python, SQL, Docker Compose, Bash
│   │
│   ├── 06-MULTITENANCY-RULES.md              ✅ COMPLETADO
│   │   └── Aislamiento de datos por tenant en MySQL y Qdrant
│   │
│   ├── 07-SCALABILITY-RULES.md               ✅ COMPLETADO
│   │   └── Criterios para escalar clientes por VPS (fases 1-2-3)
│   │
│   ├── 08-SKILLS-REFERENCE.md                ✅ COMPLETADO
│   |   └── Pointer a skills reutilizables en 02-SKILLS/
│   │
│   └── 09-AGENTIC-OUTPUT-RULES.md               ✅ COMPLETADO
│       └── Assitente salidas produccion SDD
|
│
├── 02-SKILLS/
|    ├── 00-INDEX.md ✅ COMPLETADO
|    │   
|    ├── skill-domains-mapping.md ✅ COMPLETADO
|    |
|    ├── GENERATION-MODELS.md     ✅ COMPLETADO
|    |   └── Modelos de generación SDD para MANTIS AGENTIC
|    |
|    ├── 00-INDEX.md ✅ COMPLETADO
|    |
|    ├── AI/
|    |   ├── openrouter-integration.md           ✅ COMPLETADO
|    |   ├── mistral-ocr-integration.md              ✅ COMPLETADO
|    |   ├── qwen-integration.md                    ✅ COMPLETADO
|    |   ├── llama-integration.md                   ✅ COMPLETADO
|    |   ├── gemini-integration.md                 ✅ COMPLETADO
|    |   ├── gpt-integration.md                     ✅ COMPLETADO
|    |   ├── deepseek-integration.md                ✅ COMPLETADO
|    |   ├── minimax-integration.md                 ✅ COMPLETADO
|    |   ├── voice-agent-integration.md             ✅ COMPLETADO
|    |   ├── image-gen-api.md                       ✅ COMPLETADO
|    |   └── video-gen-api.md                      ✅ COMPLETADO
|    |
|    ├── 📡 INFRAESTRUCTURA (Servidores)
|    │   ├── ssh-tunnels-remote-services.md ✅ COMPLETADO
|    │   │   └── Túneles SSH para MySQL, Qdrant entre VPS
|    │   ├── docker-compose-networking.md ✅ COMPLETADO
|    │   │   └── Redes Docker entre VPS
|    |   ├── espocrm-setup.md ✅ COMPLETADO 
|    |   |   └── instalacion espoCRM
|    │   ├── fail2ban-configuration.md ✅ COMPLETADO
|    │   │   └── Protección SSH con fail2ban
|    │   ├── ufw-firewall-configuration.md ✅ COMPLETADO
|    │   │   └── Firewall UFW en VPS
|    │   ├── ssh-key-management.md ✅ COMPLETADO
|    │   │   └── Gestión de claves SSH
|    │   ├── n8n-concurrency-limiting.md ✅ COMPLETADO
|    │   │   └── Limitación de concurrencia en n8n
|    │   ├── health-monitoring-vps.md ✅ COMPLETADO
|    │   │   └── Agentes de monitoreo de salud VPS
|    │   ├── vps-interconnection.md ✅ COMPLETADO
|    │   │   └── Conexión entre VPS 1-2-3   
|    │   ├── redis-session-management.md ✅ COMPLETADO
|    │   │   └── Buffer de sesión para contexto de conversación
|    │   └── environment-variable-management.md ✅ COMPLETADO
|    │       └── Gestión de variables de entorno
|    │
|    ├── 🗄️ BASE DE DATOS-RAG
|    │   ├── qdrant-rag-ingestion.md ✅ COMPLETADO
|    │   │   └── Ingesta de documentos en Qdrant con tenant_id
|    │   ├── mysql-sql-rag-ingestion.md ✅ COMPLETADO
|    │   │   └── MySQL/SQL, RAG Ingestion patterns base de datos
|    │   ├── rag-system-updates-all-engines.md ✅ COMPLETADO
|    │   │   └── Actualizacion reemplazo concatenacion de BD RAG
|    │   ├── multi-tenant-data-isolation.md ✅ COMPLETADO
|    │   │   └── Aislamiento de datos por tenant
|    │   ├── postgres-prisma-rag.md ✅ COMPLETADO
|    │   │   └── PostgreSQL + Prisma para RAG
|    │   ├── supabase-rag-integration.md ✅ COMPLETADO
|    │   │   └── Supabase + RAG patterns
|    │   ├── pdf-mistralocr-processing.md ✅ COMPLETADO
|    │   │   └── PDF parsing con Mistral OCR
|    │   ├── google-drive-qdrant-sync.md ✅ COMPLETADO
|    │   │   └── Sincronización Google Drive → Qdrant
|    │   ├── espocrm-api-analytics.md ✅ COMPLETADO
|    │   │   └── Uso de EspoCRM API para reportes
|    │   ├── airtable-database-patterns.md  ✅ COMPLETADO
|    │   │   └── Uso de Airtable
|    │   ├── google-sheets-as-database.md ✅ COMPLETADO
|    │   │   └── Uso de google shets
|    │   └── mysql-optimization-4gb-ram.md ✅ COMPLETADO
|    │       └── Optimización MySQL para VPS 4GB
|    │
|    ├── 📱 WHATSAPP-RAG AGENTS
|    │   ├── whatsapp-rag-openrouter.md 🆕 PENDIENTE
|    │   │   └── Patrones para agentes WhatsApp con RAG Qdrant, 
|    |   |       Prisma,Supabase,GoogleDrive, MySql, Sql, Postgre,ChromeDB
|    |   |       google Sheets, Airtable DB, en Openrouter,Gpt,Claude,Qwen,DeepSeek, Minimax
|    │   ├── whatsapp-uazapi-integration.md 🆕 PENDIENTE
|    │   │   └── Integración con uazapi
|    │   ├── telegram-bot-integration.md 🆕 PENDIENTE
|    │   │   └── Integración Telegram Bot
|    │   └── multi-channel-routing.md 🆕 NUEVO
|    │       └── Routing WhatsApp + Telegram
|    │
|    ├── 📸 INSTAGRAM-SOCIAL-MEDIA
|    │   ├── instagram-api-integration.md 🆕 NUEVO
|    │   │   └── API de Instagram para automatización
|    │   ├── cloudinary-media-management.md 🆕 NUEVO
|    │   │   └── Cloudinary para imágenes/videos
|    │   ├── ai-image-generation.md 🆕 NUEVO
|    │   │   └── Generación de imágenes con AI
|    │   ├── ai-video-creation.md 🆕 NUEVO
|    │   │   └── Creación de reels con AI
|    │   ├── multi-platform-posting.md 🆕 NUEVO
|    │   │   └── Posting a TikTok, Instagram, FB
|    │   └── social-media-alerts-telegram.md 🆕 NUEVO
|    │       └── Alertas Telegram para social media
|    │
|    ├── 🦷 ODONTOLOGÍA
|    │   ├── dental-appointment-automation.md 🆕 NUEVO
|    │   │   └── Automatización de citas dentales
|    │   ├── voice-agent-dental.md 🆕 NUEVO
|    │   │   └── Voice agent con Gemini AI
|    │   ├── google-calendar-dental.md 🆕 NUEVO
|    │   │   └── Google Calendar para clínicas
|    │   ├── supabase-dental-patient.md 🆕 NUEVO
|    │   │   └── Supabase para gestión de pacientes
|    │   ├── phone-integration-dental.md 🆕 NUEVO
|    │   │   └── Integración telefónica
|    │   └── gmail-smtp-integration.md 🆕 PENDIENTE
|    │       └── Integración Gmail SMTP
|    │
|    ├── 🏨 HOTELES-POSADAS
|    │   ├── hotel-booking-automation.md 🆕 NUEVO
|    │   │   └── Automatización de reservas hoteleras
|    │   ├── hotel-receptionist-whatsapp.md 🆕 NUEVO
|    │   │   └── Recepcionista WhatsApp con Gemini
|    │   ├── hotel-competitor-monitoring.md 🆕 NUEVO
|    │   │   └── Monitoreo de competidores
|    │   ├── hotel-guest-journey.md 🆕 NUEVO
|    │   │   └── Journey del huésped
|    │   ├── hotel-pre-arrival-messages.md 🆕 NUEVO
|    │   │   └── Mensajes pre-llegada
|    │   ├── redis-session-management.md 🆕 NUEVO
|    │   │   └── Redis para sesiones
|    │   └── slack-hotel-integration.md 🆕 NUEVO
|    │       └── Slack para equipos hoteleros
|    │
|    ├── 🍕 RESTAURANTES
|    │   ├── restaurant-booking-ai.md 🆕 NUEVO
|    │   │   └── Sistema de reservas con AI
|    │   ├── restaurant-order-chatbot.md 🆕 NUEVO
|    │   │   └── Chatbot de pedidos con qwen3.5
|    │   ├── restaurant-pos-integration.md 🆕 NUEVO
|    │   │   └── Integración POS
|    │   ├── restaurant-voice-agents.md 🆕 NUEVO
|    │   │   └── Voice agents para restaurantes
|    │   ├── restaurant-menu-management.md 🆕 NUEVO
|    │   │   └── Gestión de menús
|    │   ├── restaurant-delivery-tracking.md 🆕 NUEVO
|    │   │   └── Tracking de delivery
|    │   ├── restaurant-google-maps-leadgen.md 🆕 NUEVO
|    │   │   └── Lead generation desde Google Maps
|    │   ├── apify-web-scraping.md 🆕 NUEVO
|    │   │   └── Web scraping con Apify
|    │   ├── airtable-restaurant-db.md 🆕 NUEVO
|    │   │   └── Patrones Airtable para restaurantes
|    │   └── restaurant-multi-channel-receptionist.md 🆕 NUEVO
|    │       └── Recepcionista multi-canal
|    │
|    ├── 📧 COORPORATE-KB
|    |   ├── corp-kb-ingestion-pipeline.md           🆕
|    |   ├── corp-kb-rag-telegram.md                 🆕
|    |   ├── corp-kb-rag-whatsapp.md                 🆕
|    |   ├── corp-kb-multi-tenant-isolation.md       🆕
|    |   └── corp-kb-content-templates.md            🆕
|    │
|    ├── 📧 COMUNICACIÓN (Genérico)
|    │   ├── telegram-bot-integration.md ✅ COMPLETADO
|    │   │   └── Integración con Telegram Bot
|    │   ├── gmail-smtp-integration.md ✅ COMPLETADO
|    │   │   └── Integración con Gmail SMTP
|    │   ├── google-calendar-api-integration.md ✅ COMPLETADO
|    │   │   └── Integración Google Calendar API
|    │   ├── email-notification-patterns.md 🆕 NUEVO
|    │   |     └── Patrones de notificaciones email
|    │   ├── whatsApp-rag-openRouter ✅ COMPLETADO
|    │   |     └── Patrones de manejo de Rag
|    |   └── whatsapp-uazapi-integration.md 🆕 PENDIENTE
|    │         └── interoperatividad whatsapp y uazapi
|    │     
|    ├── 🔒 SEGURIDAD
|    │   ├── backup-encryption.md ✅ COMPLETADO
|    │   │   └── Encriptación de backups
|    │   ├── rsync-automation.md ✅ COMPLETADO
|    │   │   └── Automatización rsync
|    │   └── security-hardening-vps.md ✅ COMPLETADO
|    │       └── Hardening de VPS
|    │
|    ├── 🧠 N8N-PATTERNS
|    |    ├── n8n-workflow-patterns.md 🆕 PENDIENTE
|    |    │   └── Patrones reutilizables para workflows
|    |    ├── n8n-agent-patterns.md 🆕 NUEVO
|    |    │   └── Patrones de agentes LangChain
|    |    └── n8n-error-handling.md 🆕 NUEVO
|    |         └── Manejo de errores en n8n
|    |
|    ├── 🧠 AGENTIC-ASSISTANCE
|    |   └── ide-cli-integration.md  ✅ COMPLETADO
|    |          └── Integración IDE & CLI para Generación Asistida y Autogeneración SDD
|    │
|    └── 🧠 DEPLOYMENT
|        └── multi-channel-deploymen.md ✅ COMPLETADO
|            
│
|
├── 03-AGENTS/
│   ├── 00-INDEX.md                           🆕 PENDIENTE
│   │   └── Índice de todos los agentes
│   │
│   ├── infrastructure/
│   │   ├── 00-INDEX.md                       🆕 PENDIENTE
│   │   │   └── Índice de agentes de infraestructura
│   │   │
│   │   ├── health-monitor-agent.md           🆕 PENDIENTE
│   │   │   └── Agente de monitoreo de salud de VPS (polling cada 5 min)
│   │   │
│   │   ├── backup-manager-agent.md           🆕 PENDIENTE
│   │   │   └── Agente de gestión de backups (diario 4 AM)
│   │   │
│   │   ├── alert-dispatcher-agent.md         🆕 PENDIENTE
│   │   │   └── Agente de despacho de alertas (Telegram, Gmail, Calendar)
│   │   │
│   │   └── security-hardening-agent.md       🆕 PENDIENTE
│   │       └── Agente de endurecimiento de seguridad (UFW, SSH, fail2ban)
│   │
│   └── clients/
│       ├── 00-INDEX.md                       🆕 PENDIENTE
│       │   └── Índice de agentes de clientes
│       │
│       ├── whatsapp-attention-agent.md       🆕 PENDIENTE
│       │   └── Agente de atención por WhatsApp (uazapi + RAG + OpenRouter)
│       │
│       ├── rag-knowledge-agent.md            🆕 PENDIENTE
│       │   └── Agente de conocimiento RAG (Qdrant + tenant_id)
│       │
│       └── espocrm-analytics-agent.md        🆕 PENDIENTE
│           └── Agente de analytics de EspoCRM (reportes para clientes Full)
|
│
├── 04-WORKFLOWS/
│   ├── 00-INDEX.md                           🆕 PENDIENTE
│   │   └── Índice de todos los workflows
|   |
│   ├── sdd-assisted-generation-loop.json     ✅ COMPLETADO
│   │   └── Ciclo de generación asistida y autogeneración SDD Hardened
|   |
│   │
│   ├── n8n/
│   │   ├── 00-INDEX.md                       🆕 PENDIENTE
│   │   │   └── Índice de workflows de n8n
│   │   │
│   │   ├── INFRA-001-Monitor-Salud-VPS.json  🆕 PENDIENTE
│   │   │   └── Workflow de monitoreo de salud de VPS (cada 5 min)
│   │   │
│   │   ├── INFRA-002-Backup-Manager.json     🆕 PENDIENTE
│   │   │   └── Workflow de gestión de backups (diario 4 AM)
│   │   │
│   │   ├── INFRA-003-Alert-Dispatcher.json   🆕 PENDIENTE
│   │   │   └── Workflow de despacho de alertas
|   |   |
|   |   ├── INFRA-004-Security-Hardening.json   🆕 PENDIENTE
│   │   │   └── Workflow verifica, aplica configuraciones de seguridad en los VPS (cada 6 horas) 
│   │   │
│   │   └── CLIENT-001-WhatsApp-RAG.json      🆕 PENDIENTE
│   │       └── Workflow de atención WhatsApp con RAG
│   │
│   └── diagrams/
│       ├── 00-INDEX.md                       🆕 PENDIENTE
│       │   └── Índice de diagramas
│       │
│       ├── architecture-overview.png         🆕 PENDIENTE
│       │   └── Diagrama de arquitectura de 3 VPS
│       │
│       ├── data-flow.png                     🆕 PENDIENTE
│       │   └── Diagrama de flujo de datos
│       │
│       └── security-architecture.png         🆕 PENDIENTE
│           └── Diagrama de arquitectura de seguridad
|
│
├── 05-CONFIGURATIONS/
│   ├── 00-INDEX.md                           🆕 PENDIENTE
│   │   └── Índice de todas las configuraciones
│   │
│   ├── docker-compose/
│   │   ├── 00-INDEX.md                       🆕 PENDIENTE
│   │   │   └── Índice de archivos docker-compose
│   │   │
│   │   ├── vps1-n8n-uazapi.yml               🆕 PENDIENTE
│   │   │   └── Docker Compose para VPS 1 (n8n + uazapi + Redis)
│   │   │
│   │   ├── vps2-crm-qdrant.yml               🆕 PENDIENTE
│   │   │   └── Docker Compose para VPS 2 (EspoCRM + MySQL + Qdrant)
│   │   │
│   │   └── vps3-n8n-uazapi.yml               🆕 PENDIENTE
│   │       └── Docker Compose para VPS 3 (n8n + uazapi)
|   |
|   |
|   |
│   ├── terraform/                    # 🔹 Módulos IaC reusables
│   │   ├── modules/
│   │   │   ├── vps-base/            # C1/C2: limits, UFW, fail2ban 🆕 PENDIENTE
|   |   |   |   ├── main.tf ✅ COMPLETADO
|   |   |   |   ├── outputs.tf 
|   |   |   |   ├── variables.tf
|   |   |   |   ├── main/
|   |   |   |   ├── output/
|   |   |   |   └── variable/
|   |   |   |   
│   │   │   ├── qdrant-cluster/      # C3: localhost-only, tenant isolation 🆕 PENDIENTE
|   |   |   |   └── main.tf 🆕 PENDIENTE
|   |   |   |   ├── outputs.tf 🆕 PENDIENTE
|   |   |   |   ├── variables.tf 🆕 PENDIENTE
|   |   |   |   ├── main/
|   |   |   |   ├── output/
|   |   |   |   └── variable/
|   |   |   |   
│   │   │   ├── postgres-rls/        # C4: RLS policies, tenant_id enforcement 🆕 PENDIENTE
|   |   |   |   └── main.tf ✅ COMPLETADO
|   |   |   |   ├── outputs.tf 🆕 PENDIENTE
|   |   |   |   ├── variables.tf 🆕 PENDIENTE
|   |   |   |   ├── main/
|   |   |   |   ├── output/
|   |   |   |   └── variable/
|   |   |   |   
│   │   │   ├── openrouter-proxy/    # C6: cloud-only inference routing 🆕 PENDIENTE
|   |   |   |   └── main.tf 🆕 PENDIENTE
|   |   |   |   ├── outputs.tf 🆕 PENDIENTE
|   |   |   |   ├── variables.tf 🆕 PENDIENTE
|   |   |   |   ├── main/
|   |   |   |   ├── output/
|   |   |   |   └── variable/
|   |   |   |   
│   │   │   └── backup-encrypted/    # C5: SHA256 + age encryption 🆕 PENDIENTE
|   |   |       └── main.tf 🆕 PENDIENTE
|   |   |       ├── outputs.tf 🆕 PENDIENTE
|   |   |       ├── variables.tf 🆕 PENDIENTE
|   |   |       ├── main/
|   |   |       ├── output/
|   |   |       └── variable/
|   |   |      
│   │   ├── environments/
│   │   │   ├── dev/terraform.tfvars 🆕 PENDIENTE
│   │   │   ├── prod/terraform.tfvars 🆕 PENDIENTE
│   │   │   └── variables.tf         # Validaciones: min/max, regex, types 🆕 PENDIENTE
|   |   |
│   │   ├── backend.tf               # Remote state (S3/Supabase) + locking ✅ COMPLETADO
│   │   ├── variables.tf ✅ COMPLETADO
│   │   └── outputs.tf               # Outputs tipados para consumo por agentes 🆕 PENDIENTE
│   │
│   ├── pipelines/                    # 🔹 CI/CD ejecutables
│   │   ├── .github/workflows/
│   │   │             ├── validate-skill.yml   # Lint + tests + Promptfoo eval ✅ COMPLETADO
│   │   │             ├── terraform-plan.yml   # Plan + security scan (tfsec/checkov) 🆕 PENDIENTE
│   │   │             └── integrity-check.yml  # Daily: frontmatter, wikilinks, constraints ✅ COMPLETADO
|   |   |
│   │   └── promptfoo/
│   │       ├── config.yaml          # Evaluación de prompts de autogeneración 🆕 PENDIENTE
│   │       ├── test-cases/          # Casos de prueba por modelo (5 mínimos) 🆕 PENDIENTE
│   │       └── assertions/          # Schema validation + linting rules 🆕 PENDIENTE
│   │
│   ├── validation/                   # 🔹 Scripts de integridad centralizados
|   |   ├── schemas/
|   |   |   └── skill-input-output.schema.json ✅ COMPLETADO  
|   |   |          └── Esquema estricto para validar la salida de agentes generadores de código  
|   |   |     
│   │   ├── validate-skill-integrity.sh  # 🎯 Script maestro modular ✅ COMPLETADO
│   │   ├── audit-secrets.sh         # Hardening: detección de hardcoded creds ✅ COMPLETADO
│   │   ├── check-rls.sh             # Hardening: validación de políticas RLS ✅ COMPLETADO
│   │   ├── validate-frontmatter.sh  # SDD: YAML required fields + types ✅ COMPLETADO
│   │   ├── check-wikilinks.sh       # Obsidian: enlaces rotos o inexistentes ✅ COMPLETADO
│   │   ├── verify-constraints.sh    # C1-C6: presencia explícita en ejemplos ✅ COMPLETADO
│   │   └── schema-validator.py      # JSON Schema para outputs de meta-prompting ✅ COMPLETADO
│   │
│   ├── templates/                    # 🔹 Plantillas para autogeneración
│   |   ├── skill-template.md        # Frontmatter + estructura base + 5 ejemplos mínimos ✅ COMPLETADO
│   |   ├── example-template.md      # ✅/❌ + troubleshooting + constraints mapeados ✅ COMPLETADO
│   |   ├── terraform-module-template/ # Estructura mínima de módulo reusable 
|   |   |       └── main.tf ✅ COMPLETADO
|   |   |       ├── outputs.tf 🆕 PENDIENTE
|   |   |       ├── variables.tf 🆕 PENDIENTE
|   |   |       └── README.md 🆕 PENDIENTE
|   |   |
│   |   └── pipeline-template.yml    # GitHub Actions base con jobs esenciales 🆕 PENDIENTE
│   │
│   ├── scripts/
|   |   ├── validate-against-specs.sh         ✅ COMPLETADO
|   |   |   └── Validar automáticamente que los archivos del repositorio cumplan 
|   |   |        con los constraints absolutos (C1-C6), estructura SDD, tenant-
|   |   |        awareness y límites de recursos antes de commit o despliegue. 
|   |   |      
│   │   ├── 00-INDEX.md                       🆕 PENDIENTE
│   │   │   └── Índice de scripts bash
|   |   |
|   |   ├── sync-mantis-graph.sh         # ✅ Existente: sync Obsidian → repo
|   |   |    
|   |   ├── validate-graph-health.py     # ✅ Existente: salud del grafo
|   |   |    
|   |   ├── bootstrap-hardened-repo.sh   # 🔹 Nuevo: inicializa estructura HARDENED
│   │   │
│   │   ├── health-check.sh                   🆕 PENDIENTE
│   │   │   └── Script de health check para VPS (cada 5 min)
│   │   │
│   │   ├── backup-mysql.sh                   🆕 PENDIENTE
│   │   │   └── Script de backup de MySQL (diario 4 AM)
│   │   │
│   │   ├── backup-qdrant.sh                  🆕 PENDIENTE
│   │   │   └── Script de backup de Qdrant (snapshots)
│   │   │
│   │   ├── test-alerts.sh                    🆕 PENDIENTE
│   │   │   └── Script de prueba de alertas (Telegram, Gmail, Calendar)
│   │   │
│   │   └── restore-mysql.sh                  🆕 PENDIENTE
│   │       └── Script de restauración de MySQL
│   │
│   └── environment/
│       ├── 00-INDEX.md                       🆕 PENDIENTE
│       │   └── Índice de archivos de entorno
│       │
│       └── .env.example                      🆕 PENDIENTE
│           └── Ejemplo de variables de entorno (sin valores reales)
|
|
│
├── 06-PROGRAMMING/
│   ├── 00-INDEX.md                           🆕 PENDIENTE
│   │   └── Índice de todos los patrones de programación
│   │
│   ├── python/
│   │   ├── 00-INDEX.md                       🆕 PENDIENTE
│   │   │   └── Índice de patrones Python
│   │   │
│   │   ├── api-call-patterns.md              🆕 PENDIENTE
│   │   │   └── Patrones para llamadas API con requests
│   │   │
│   │   ├── telegram-bot-integration.md       🆕 PENDIENTE
│   │   │   └── Integración con Telegram Bot en Python
│   │   │
│   │   └── google-calendar-api.md            🆕 PENDIENTE
│   │       └── Integración con Google Calendar API en Python
│   │
│   ├── sql/
│   │   ├── 00-INDEX.md                       🆕 PENDIENTE
│   │   │   └── Índice de patrones SQL
│   │   │
│   │   ├── multi-tenant-schema.md            🆕 PENDIENTE
│   │   │   └── Esquema multi-tenant para MySQL
│   │   │
│   │   ├── indexed-queries.md                🆕 PENDIENTE
│   │   │   └── Queries con índices optimizados
│   │   │
│   │   └── backup-restore-commands.md        🆕 PENDIENTE
│   │       └── Comandos SQL para backup y restauración
│   │
│   └── javascript/
│       ├── 00-INDEX.md                       🆕 PENDIENTE
│       │   └── Índice de patrones JavaScript
│       │
│       ├── n8n-function-node-patterns.md     🆕 PENDIENTE
│       │   └── Patrones para Function Node de n8n
│       │
│       └── async-error-handling.md           🆕 PENDIENTE
│           └── Manejo de errores asíncronos en JavaScript
|
|
│
├── 07-PROCEDURES/
│   ├── 00-INDEX.md                           🆕 PENDIENTE
│   │   └── Índice de todos los procedimientos
│   │
│   ├── vps-initial-setup.md                  🆕 PENDIENTE
│   │   └── Procedimiento de configuración inicial de VPS (12 pasos)
│   │
│   ├── onboarding-client.md                  🆕 PENDIENTE
│   │   └── Procedimiento de onboarding de clientes (12 pasos)
│   │
│   ├── incident-response-checklist.md        🆕 PENDIENTE
│   │   └── Checklist de respuesta a incidentes (12 pasos)
│   │
│   ├── backup-restore-test.md                🆕 PENDIENTE
│   │   └── Procedimiento de test de restauración de backup (12 pasos)
│   │
│   ├── scaling-decision-matrix.md            🆕 PENDIENTE
│   │   └── Matriz de decisión para escalar clientes por VPS
│   │
│   ├── fire-drill-test-procedures.md         🆕 PENDIENTE
│   │   └── Procedimientos de test de incendio (5 escenarios)
│   │
│   ├── backup-restore-procedures.md          🆕 PENDIENTE
│   │   └── Procedimientos detallados de backup y restauración (movido desde RULES)
│   │
│   ├── monitoring-alerts-procedures.md       🆕 PENDIENTE
│   │   └── Procedimientos de alertas de monitoreo (movido desde RULES)
│   │
│   └── weekly-checklist-template.md          🆕 PENDIENTE
│       └── Plantilla de checklist semanal para seguimiento
|
|
│
├── 08-LOGS/
│   ├── 00-INDEX.md                           🆕 PENDIENTE
│   │   └── Índice de logs (referencia)
|   |
│   ├── validation/                  # Logs de scripts de integridad
│   │   ├── integrity-report-YYYYMMDD.json 🆕 PENDIENTE
│   │   └── constraint-audit.log 🆕 PENDIENTE
│   ├── generation/                  # Logs de autogeneración por IA
│   |   ├── prompt-execution.log 🆕 PENDIENTE
│   |   └── output-validation.json 🆕 PENDIENTE
│   │
│   └── .gitkeep                              ✅ COMPLETADO
│       └── Archivo vacío para mantener carpeta en Git
|
|
│
└── .github/
    └── workflows/
        └── 00-INDEX.md                       🆕 PENDIENTE
            └── Índice de workflows de GitHub Actions (futuro)
            
            
---


## 📊 RESUMEN DE ESTADO (Verificado - Abril 2026)

| Carpeta | Archivos .md verificados | Archivos base (.gitkeep/.sh/.json) | Total | % Completado | Estado |
|---------|-------------------------|-----------------------------------|-------|--------------|--------|
| **Raíz** | 3 | 0 | 3 | 100% | ✅ Estable |
| **00-CONTEXT/** | 5 | 0 | 5 | 100% | ✅ Estable |
| **01-RULES/** | 10 | 0 | 10 | 100% | ✅ Estable |
| **02-SKILLS/** (total consolidado) | 24 ✅ / 60 🆕 | 2 (.gitkeep) | 86 | **~28.6%** | 🟡 Núcleo base listo, verticalización pendiente |
| ↳ INFRAESTRUCTURA/ | 9 | 0 | 9 | 81.8% | ✅ Listo para uso |
| ↳ BASE DE DATOS-RAG/ | 9 | 0 | 9 | 90% | ✅ Listo para uso |
| ↳ SEGURIDAD/ | 3 | 0 | 3 | 100% | ✅ Listo para uso |
| ↳ COMUNICACIÓN/ | 2 | 0 | 2 | 28.6% | 🟡 Base operativa |
| ↳ AI/ | 0 | 11 | 11 | 0% | ⏳ Estructura base |
| ↳ Verticalización (ODONTO/HOTELES/REST) | 0 | 26 | 26 | 0% | ⏳ Pendiente |
| **04-WORKFLOWS/** | 0 | 1 (sdd-universal-assistant.json) | 1 | 10% | 🟡 Workflow base |
| **05-CONFIGURATIONS/scripts/** | 0 | 2 (.txt + .sh) | 2 | 20% | 🟡 Scripts base |
| **TOTAL GENERAL** | **42 ✅ / 60 🆕** | **7** | **109** | **~41.3%** | 🟢 Núcleo operativo listo, escalamiento en progreso |

> 💡 **Nota metodológica**: 
> - El % se calcula **exclusivamente sobre archivos .md con contenido técnico validado**. 
> - Los archivos base (.gitkeep, .sh, .json) se contabilizan en columna separada para no distorsionar el avance real de documentación.
> - 02-SKILLS/ se muestra consolidado + desglose de subcarpetas críticas para visibilidad de progreso por dominio.
> - **Próximo hito**: Completar `00-INDEX.md` en raíz de 02-SKILLS/ para habilitar navegación autónoma de IAs.
---

## 🎯 PRIORIDADES DE CREACIÓN (Actualizado - Estado Real)

### **✅ FASE 1 CONSOLIDADA: Cimientos Técnicos (Completada)**
| Prioridad | Archivo | Carpeta | Estado | Observación |
|-----------|---------|---------|--------|-------------|
| 🔴 CRÍTICA | 00-INDEX.md a validation-checklist.md | 01-RULES/ | ✅ 10/10 | Constraints C1-C6 documentados |
| 🔴 CRÍTICA | PROJECT_OVERVIEW.md a documentation-validation-cheklist.md | 00-CONTEXT/ | ✅ 5/5 | Contexto de negocio y usuario validado |
| 🟠 ALTA | skill-domains-mapping.md | 02-SKILLS/ | ✅ 1/1 | Controlador de navegación por dominio |

### **✅ FASE 2 CONSOLIDADA: Skills Operativos Base (Completada)**
| Prioridad | Dominio | Archivos .md completados | Estado | Uso inmediato |
|-----------|---------|-------------------------|--------|--------------|
| 🔴 CRÍTICA | INFRAESTRUCTURA | 9/9 (docker, SSH, UFW, fail2ban, monitoreo) | ✅ Listo | Despliegue VPS multi-tenant |
| 🔴 CRÍTICA | BASE DE DATOS-RAG | 9/9 (Qdrant, Prisma, Supabase, OCR, sync) | ✅ Listo | Ingesta RAG con aislamiento tenant_id |
| 🟠 ALTA | COMUNICACION | 2/2 (Telegram Bot RAG, Gmail SMTP) | ✅ Listo | Canales de notificación y respuesta |
| 🟠 ALTA | SEGURIDAD | 3/3 (backup-encryption, rsync, hardening) | ✅ Listo | Hardening y recuperación ante fallos |

### **🟡 FASE 3 EN PROGRESO: Agentes y Workflows (Iniciada)**
| Prioridad | Entregable | Carpeta | Estado | Próximo hito |
|-----------|-----------|---------|--------|--------------|
| 🟠 ALTA | sdd-universal-assistant.json | 04-WORKFLOWS/ | 🟡 1/1 base | Expandir a 5 workflows n8n exportados |
| 🟡 MEDIA | Estructura 03-AGENTS/ | 03-AGENTS/ | ⏳ Pendiente | Definir spec de agentes por vertical |
| 🟡 MEDIA | Scripts de validación | 05-CONFIGURATIONS/scripts/ | 🟡 2/2 base | Agregar validador de frontmatter SDD |

### **⏳ FASE 4 PENDIENTE: Verticalización y Escalamiento**
| Prioridad | Entregable | Carpeta | Dependencia | Estimación |
|-----------|-----------|---------|-------------|------------|
| 🟡 MEDIA | Plantillas verticales (ODONTOLOGIA, HOTELES, RESTAURANTES) | 02-SKILLS/ | Skills base ✅ | Semana 9-10 |
| 🟡 MEDIA | Backend FastAPI MVP (/auth, /generate, /prompts) | 06-PROGRAMMING/ | Rules ✅ + DB-RAG ✅ | Semana 11 |
| 🔴 CRÍTICA | Documentación de onboarding para agencias | 07-PROCEDURES/ | Skills base ✅ | Semana 12 |


---

## 📝 NOTAS IMPORTANTES

### **Para IAs en chats nuevos:**

Cuando abras un chat nuevo con cualquier IA (incluyéndome), proporciona:

URL del PROJECT_OVERVIEW.md (visión general)
URL del 00-INDEX.md de la carpeta que vas a trabajar
URLs de los archivos específicos que necesitas

#### 🧭 Flujo de Carga Óptimo: Grafo → Controlador de Skills → Archivos Específicos

Para minimizar tokens y evitar navegación tentativa, seguir estrictamente:

1. **Cargar primero** `knowledge-graph.json`  
   → Filtrar nodos por `priority: "Siempre"` o `"Alta"`  
   → Identificar `domain` relevante (ej: `SEGURIDAD`, `INFRAESTRUCTURA`)

2. **Cargar segundo** `02-SKILLS/skill-domains-mapping.md`  
   → Usar el **Mapa General de Zonas** para ubicar la categoría técnica  
   → Consultar la **Matriz de Dependencias** para skills transversales requeridos  
   → Verificar estado: ✅ = listo para usar / ⏳ = pendiente (no cargar salvo desarrollo)

3. **Cargar tercero** solo los archivos de skill específicos referenciados  
   → Ej: Si la tarea es "monitoreo VPS + Telegram", cargar solo:  
     - `health-monitoring-vps.md`  
     - `telegram-bot-integration.md`  
   → **No explorar** carpetas completas ni archivos con prioridad "Baja"

> 🎯 **Resultado esperado**: Navegación dirigida por metadata, sin exploración ciega.  
> 💰 **Ahorro estimado**: 70-85% menos tokens en fase de contextualización estructural.


### **Para mantener actualizado:**

Cada vez que crees un archivo nuevo, actualiza este PROJECT_TREE.md
Cambia el estado de 🆕 a ✅
Actualiza el resumen de estado (% completado)
Haz commit y push del PROJECT_TREE.md también

### **URLs Raw para IAs (cuando el repo sea público):**

> 💡 **Instrucción de carga escalonada**: Seguir el orden de prioridad (1→4). No cargar todas las URLs en paralelo.

#### 🔴 PRIORIDAD 1: Navegación Estructural (Cargar PRIMERO - ~800 tokens)
```text
# Grafo estructural: mapeo semántico de nodos/aristas con metadata de prioridad y dominio
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/knowledge-graph.json

# Controlador de dominios: mapa visual de skills, estado y dependencias transversales
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/skill-domains-mapping.md

# Índice visual: árbol completo del repositorio para referencia rápida
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/PROJECT_TREE.md
```
#### 🟠 PRIORIDAD 2: Contexto y Reglas Base (Cargar SEGUNDO - ~1.200 tokens)
```text
# Perfil de usuario, constraints operativos C1-C6 y stack técnico
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/00-CONTEXT/facundo-core-context.md

# Infraestructura: límites de VPS, red, seguridad y arquitectura de despliegue
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/00-CONTEXT/facundo-infrastructure.md

# Índice de reglas: patrones SDD, constraints y checklist de validación
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/00-INDEX.md

# Regla crítica C4: aislamiento multi-tenant (tenant_id obligatorio en TODAS las consultas)
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/06-MULTITENANCY-RULES.md
```

#### 🟡 PRIORIDAD 3: Skills Técnicos por Dominio (Cargar ON-DEMAND según tarea)
```text
# === INFRAESTRUCTURA ===
# Orquestación de contenedores con límites de RAM/CPU (C1/C2)
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/INFRAESTRUCTURA/docker-compose-networking.md
# Limitación de concurrencia en n8n para evitar saturación de VPS
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/INFRAESTRUCTURA/n8n-concurrency-limiting.md

# === BASE DE DATOS-RAG ===
# Ingesta de documentos en Qdrant con metadata de tenant_id (C4)
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/BASE%20DE%20DATOS-RAG/qdrant-rag-ingestion.md
# Estrategia de aislamiento de datos multi-tenant en PostgreSQL/Prisma
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/BASE%20DE%20DATOS-RAG/multi-tenant-data-isolation.md

# === SEGURIDAD ===
# Encriptación de backups con verificación SHA256 (C5)
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/SEGURIDAD/backup-encryption.md
# Hardening de VPS: UFW, fail2ban, SSH, monitoreo de recursos
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/SEGURIDAD/security-hardening-vps.md

# === COMUNICACIÓN ===
# Integración de Telegram Bot con RAG y gestión de tenant_id
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/COMUNICACION/telegram-bot-integration.md
```

#### 🔵 PRIORIDAD 4: Configuraciones y Validación (Cargar SOLO si la tarea lo requiere)
```text
# Script de validación SDD: verifica frontmatter, constraints y ejemplos ejecutables
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/scripts/validate-against-specs.sh

# Workflow base: spec JSON para asistente universal (n8n export)
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/04-WORKFLOWS/sdd-universal-assistant.json

# Documentación de validadores: criterios para aceptar/rechazar outputs de IA
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/scripts/VALIDATOR_DOCUMENTATION.txt
```
**🎯 Regla de oro para IAs:**

    Parsear knowledge-graph.json → filtrar por priority y domain 
    Consultar skill-domains-mapping.md → identificar estado (✅/⏳) y dependencias 
    Cargar SOLO los archivos de Prioridad 3 relevantes a la tarea 
    Usar Prioridad 4 únicamente para validación final o despliegue

**💰 Ahorro estimado:** 75-90% de tokens vs carga secuencial de carpetas completas.

## 🤖 AI-Parsable Manifest (Machine-Friendly)
> **NOTA PARA IA:** Si el tamaño del contexto lo permite, prioriza la carga del archivo externo [`knowledge-graph.json`](./knowledge-graph.json) ya que es la fuente canónica y está más actualizado. El siguiente snippet es una referencia de respaldo para entornos de muy bajo contexto.

---

## 🚀 SIGUIENTES PASOS INMEDIATOS (Priorizados por impacto)

| Orden | Entregable | Carpeta | Tipo | Constraint clave | Estimación |
|-------|-----------|---------|------|-----------------|------------|
| 1 | `00-INDEX.md` para `03-AGENTS/` | 03-AGENTS/ | Spec de agentes | C4 (tenant_id en payloads) | 2h |
| 2 | `00-INDEX.md` para `06-PROGRAMMING/` | 06-PROGRAMMING/ | Spec backend FastAPI | C1/C2 (4GB RAM, 1vCPU) | 3h |
| 3 | `docker-compose.yml` optimizado para backend + DB | 05-CONFIGURATIONS/docker-compose/ | Configuración ejecutable | C1 (75% RAM máx por servicio) | 4h |
| 4 | `validation-checklist.md` para skills verticales | 01-RULES/ | Validación SDD | C5 (checksum + integridad) | 2h |
| 5 | `skill-domains-mapping.md`: actualizar estado de AI/ y DEPLOYMENT/ | 02-SKILLS/ | Mapeo central | C2 (modularidad) | 30 min |
| 6 | Script `sanitize-graph.py` para Obsidian | 05-CONFIGURATIONS/scripts/ | Automatización | C3 (no exponer secretos) | 3h |

> 💡 **Criterio de priorización**: Impacto en reducción de tokens para IAs × dependencia para siguientes fases × esfuerzo estimado.

---

## ✅ VALIDACIÓN DE ESTRUCTURA (Checklist Auditado)

| Criterio | Estado | Evidencia verificable | Observación |
|----------|--------|----------------------|-------------|
| Separación RULES vs PROCEDURES | ✅ Correcta | `01-RULES/` = constraints; `07-PROCEDURES/` = pasos operativos | Rules definen "qué", Procedures definen "cómo" |
| Separación RULES vs SKILLS | ✅ Correcta | `01-RULES/08-SKILLS-REFERENCE.md` apunta a `02-SKILLS/` | Skills implementan rules con ejemplos ejecutables |
| Separación AGENTS vs WORKFLOWS | ✅ Correcta | `03-AGENTS/` (spec) vs `04-WORKFLOWS/` (JSON exportado de n8n) | Agents = definición; Workflows = implementación |
| CONFIGURACIONES vs PROGRAMMING | ✅ Correcta | `05-CONFIGURATIONS/` = archivos ejecutables; `06-PROGRAMMING/` = patrones de código | Configs son copy-paste; Programming es desarrollo |
| INDEX en cada carpeta | ✅ Correcta | Todos los folders nivel-1 tienen `00-INDEX.md` o equivalente | Permite navegación autónoma por IAs |
| Numeración de archivos | ✅ Correcta | Prefijos `00-`, `01-`, `02-` en RULES y PROCEDURES | Orden de carga/prioridad explícito |
| Conteo real vs declarado | ✅ Corregido | Tabla "RESUMEN DE ESTADO" con conteo verificado por URL raw | Elimina inflación de métricas |
| Wikilinks semánticos | ✅ Validado | `knowledge-graph.json` con aristas filtradas por `.md` y `#` | Previene corrupción por fragments de Bash |
| Constraints C1-C6 mapeados | ✅ Auditado | Frontmatter de skills incluye `constraints: [C1, C2, C4]` | Trazabilidad de limits operativos |

**Métricas de calidad estructural**:
- 🎯 Precisión de conteo: 100% (verificado contra URLs raw)
- 🔗 Integridad de wikilinks: 98.7% (2 aristas saneadas en último build)
- 🧭 Navegabilidad para IAs: Alta (grafo + skill-domains-mapping como controladores)
- 🔄 Actualización automática: Activa (script `sync-mantis-graph.sh` a las 03:00 AM)

---

## 🔄 NAVEGACIÓN PARA GENERACIÓN DE DOCUMENTOS

\> \*\*Para IA generadora:\*\* Antes de crear cualquier archivo marcado `🆕 PENDIENTE`, seguir este flujo para garantizar cero reparaciones manuales.

\### Flujo Recomendado por Tipo de Tarea

\| Tipo de Solicitud \| Documento Guía \| Validadores Obligatorios \|
\|------------------\|----------------|--------------------------\|
\| Nueva skill horizontal (AI/, INFRAESTRUCTURA/, etc.) | `[[02-SKILLS/01-GENERATION-MODELS.md]]` | `validate-frontmatter.sh`, `verify-constraints.sh`, `schema-validator.py` |
\| Completar archivo pendiente (`🆕` o `📝`) | `[[SDD-COLLABORATIVE-GENERATION.md]]` | Gate pre-entrega: fences, frontmatter, C1-C6, wikilinks, schema |
\| Generar infraestructura production-ready | `[[02-SKILLS/01-GENERATION-MODELS.md#-modelo-2-sdd-full-automated-hardened--terraform]]` | `tfsec`, `check-rls.sh`, `audit-secrets.sh`, `sha256sum` |

\### Instrucciones Canónicas para IA

1\. \*\*Resolver rutas:\*\* Usar exclusivamente paths desde `[[PROJECT_TREE.md]]` (este archivo). Cero inferencia externa.
2\. \*\*Estructura base:\*\* Aplicar `[[05-CONFIGURATIONS/templates/skill-template.md]]` para todo nuevo `.md`.
3\. \*\*Validación pre-entrega:\*\* Ejecutar gate de `[[SDD-COLLABORATIVE-GENERATION.md#-fase-2-gate-de-validación-pre-entrega-ia--autoverificación]]` antes de mostrar output al humano.
4\. \*\*Constraints:\*\* C1-C6 explícitos en cada bloque de código. C4 (`tenant_id`) obligatorio en queries, logs y payloads.

\> ⚠️ \*\*Si algún validador falla:\*\* Regenerar automáticamente (máx 3 intentos). Si persiste, reportar error exacto con línea y constraint violado.

**Última auditoría**: Abril 2026  
**Próxima revisión**: Al completar `06-PROGRAMMING/00-INDEX.md`  
**Versión del árbol**: 2.5.0 (conteo verificado + fases actualizadas)

Última actualización: Abril 08 2026
Próxima revisión: Al completar Fase 1 (Cimientos)
Versión del árbol: 2.4.0 (estructura corregida)

---
