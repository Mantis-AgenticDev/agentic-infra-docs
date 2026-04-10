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
│   └── 08-SKILLS-REFERENCE.md                ✅ COMPLETADO
│       └── Pointer a skills reutilizables en 02-SKILLS/
│
├── 02-SKILLS/
|    ├── 00-INDEX.md 🆕 PENDIENTE
|    │   
|    ├── skill-domains-mapping.md ✅ COMPLETADO
|    |
|    |
|    ├── AI/
|    |   ├── openrouter-api-integration.md           🆕 PENDIENTE
|    |   ├── mistral-ocr-integration.md              🆕 PENDIENTE
|    |   ├── qwen-integration.md                    🆕 PENDIENTE
|    |   ├── llama-integration.md                   🆕 PENDIENTE
|    |   ├── gemini-integration.md                  🆕 PENDIENTE
|    |   ├── gpt-integration.md                     🆕 PENDIENTE
|    |   ├── deepseek-integration.md                🆕 PENDIENTE
|    |   ├── minimax-integration.md                 🆕 PENDIENTE
|    |   ├── voice-agent-integration.md             🆕 PENDIENTE
|    |   ├── image-gen-api.md                       🆕 PENDIENTE
|    |   └── video-gen-api.md                      🆕 PENDIENTE
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
|    │   │   └── Agentes de monitoreo de salud VPS
|    │   ├── redis-session-management.md 🆕 PENDIENTE
|    │   │   └── Buffer de sesión para contexto de conversación
|    │   └── environment-variable-management.md 🆕 PENDIENTE
|    │       └── Gestión de variables de entorno
|    │
|    ├── 🗄️ BASE DE DATOS-RAG
|    │   ├── qdrant-rag-ingestion.md ✅ COMPLETADO
|    │   │   └── Ingesta de documentos en Qdrant con tenant_id
|    │   ├── mysql-sql-rag-ingestion.md 🆕 PENDIENTE
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
|    │   └── mysql-optimization-4gb-ram.md ✅ COMPLETADO
|    │       └── Optimización MySQL para VPS 4GB
|    │
|    ├── 📱 WHATSAPP-RAG AGENTS
|    │   ├── whatsapp-rag-openrouter.md 🆕 PENDIENTE
|    │   │   └── Patrones para agentes WhatsApp con RAG Qdrant, 
|    |   |       Prisma,Supabase,GoogleDrive, MySql, Sql, Postgre, ChromeDB
|    |   |       en Openrouter,Gpt,Claude,Qwen,DeepSeek, Minimax
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
|    ├── 📧 COMUNICACIÓN (Genérico)
|    │   ├── telegram-bot-integration.md ✅ COMPLETADO
|    │   │   └── Integración con Telegram Bot
|    │   ├── gmail-smtp-integration.md ✅ COMPLETADO
|    │   │   └── Integración con Gmail SMTP
|    │   ├── google-calendar-api-integration.md 🆕 PENDIENTE
|    │   │   └── Integración Google Calendar API
|    │   ├── email-notification-patterns.md 🆕 NUEVO
|    │   |     └── Patrones de notificaciones email
|    │   ├── whatsApp-rag-openRouter 🆕 NUEVO
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
│    |
|    |
|    │
|    └── 🧠 DEPLOYMENT
|        └── multi-channel deploymen.md 🆕 PENDIENTE
|            └── 
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
│
├── 04-WORKFLOWS/
│   ├── 00-INDEX.md                           🆕 PENDIENTE
│   │   └── Índice de todos los workflows
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
│   │
│   ├── scripts/
|   |   ├── validate-against-specs.sh         ✅ COMPLETADO
|   |   |   └── Validar automáticamente que los archivos del repositorio cumplan 
|   |   |        con los constraints absolutos (C1-C6), estructura SDD, tenant-
|   |   |        awareness y límites de recursos antes de commit o despliegue. 
|   |   |      
│   │   ├── 00-INDEX.md                       🆕 PENDIENTE
│   │   │   └── Índice de scripts bash
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
│
├── 08-LOGS/
│   ├── 00-INDEX.md                           🆕 PENDIENTE
│   │   └── Índice de logs (referencia)
│   │
│   └── .gitkeep                              ✅ COMPLETADO
│       └── Archivo vacío para mantener carpeta en Git
│
└── .github/
    └── workflows/
        └── 00-INDEX.md                       🆕 PENDIENTE
            └── Índice de workflows de GitHub Actions (futuro)
---

## 📊 RESUMEN DE ESTADO

Carpeta	            Archivos  Completados	   Archivos Pendientes	  Total% Completado
Raíz	              3	         3	            0 	                  100%
00-CONTEXT/	        5          5	            0                     100%
01-RULES/	          9	         9	            0	                    100%
02-SKILLS/	        20         0	            20	                  0%
03-AGENTS/	        9	         0         	    9	                    0%
04-WORKFLOWS/	      10         0        	    10	                  0%
05-CONFIGURATIONS/	13	       1        	    12	                  0%
06-PROGRAMMING/	    9	         0	            9	                    0%
07-PROCEDURES/	    10	       0        	    10                    0%
08-LOGS/	          1	         1	            2                     50%
TOTAL	              91	       19        	    72                    20,88%


---

## 🎯 PRIORIDADES DE CREACIÓN

### **Fase 1: Cimientos (Semana 1-2)**

Prioridad	Archivo	                    Carpeta                     	Razón
🔴 CRÍTICA	00-INDEX.md	                00-CONTEXT/	                    Índice de contexto para IAs
🔴 CRÍTICA	facundo-core-context.md	    00-CONTEXT/	                    Contexto base del usuario
🔴 CRÍTICA	facundo-infrastructure.md	  00-CONTEXT/	                    Detalle técnico de infra
🔴 CRÍTICA	00-INDEX.md	                01-RULES/	                    Índice de rules para IAs
🔴 CRÍTICA	02-RESOURCE-GUARDRAILS.md	  01-RULES/	                    Límites de recursos 4GB
🔴 CRÍTICA	01-ARCHITECTURE-RULES.md	  01-RULES/	                    Constraints de infraestructura
🟠 ALTA	    03-SECURITY-RULES.md	      01-RULES/	                    Seguridad de VPS
🟠 ALTA	    06-MULTITENANCY-RULES.md	  01-RULES/	                    Aislamiento de datos
🟠 ALTA	    .env.example	              05-CONFIGURATIONS/environment/	Variables de entorno


### **Fase 2: Configuraciones Técnicas (Semana 3-4)**

Prioridad	Archivo	                      Carpeta	                            Razón
🔴 CRÍTICA	vps1-n8n-uazapi.yml	         05-CONFIGURATIONS/docker-compose/	Docker VPS 1
🔴 CRÍTICA	vps2-crm-qdrant.yml	         05-CONFIGURATIONS/docker-compose/	Docker VPS 2
🔴 CRÍTICA	vps3-n8n-uazapi.yml	         05-CONFIGURATIONS/docker-compose/	Docker VPS 3
🔴 CRÍTICA	health-check.sh	             05-CONFIGURATIONS/scripts/	        Health check
🔴 CRÍTICA	backup-mysql.sh	             05-CONFIGURATIONS/scripts/	        Backup MySQL
🟠 ALTA	    04-API-RELIABILITY-RULES.md	 01-RULES/	                        Fiabilidad de APIs
🟠 ALTA	    05-CODE-PATTERNS-RULES.md	   01-RULES/	                        Patrones de código


### **Fase 3: Agentes y Workflows (Semana 5-8)**

Prioridad	Archivo	                           Carpeta	                    Razón
🟠 ALTA	    health-monitor-agent.md	            03-AGENTS/infrastructure/	Agente de monitoreo
🟠 ALTA	    backup-manager-agent.md	            03-AGENTS/infrastructure/	Agente de backup
🟠 ALTA	    alert-dispatcher-agent.md	          03-AGENTS/infrastructure/	Agente de alertas
🟡 MEDIA	  INFRA-001-Monitor-Salud-VPS.json	  04-WORKFLOWS/n8n/       	Workflow monitoreo
🟡 MEDIA	  INFRA-002-Backup-Manager.json	      04-WORKFLOWS/n8n/	        Workflow backup


### **Fase 4: Skills y Procedimientos (Semana 9-12)**

Prioridad	Archivo	                        Carpeta	         Razón
🟡 MEDIA	00-INDEX.md	                    02-SKILLS/	     Índice de skills
🟡 MEDIA	n8n-workflow-patterns.md	      02-SKILLS/	     Patrones n8n
🟡 MEDIA	onboarding-client.md	          07-PROCEDURES/	 Onboarding clientes
🟡 MEDIA	incident-response-checklist.md	07-PROCEDURES/	 Respuesta incidentes
🟡 MEDIA	07-SCALABILITY-RULES.md	        01-RULES/	       Criterios de escalado
🟡 MEDIA	08-SKILLS-REFERENCE.md	        01-RULES/	       Pointer a skills


---

## 📝 NOTAS IMPORTANTES

### **Para IAs en chats nuevos:**

Cuando abras un chat nuevo con cualquier IA (incluyéndome), proporciona:

URL del PROJECT_OVERVIEW.md (visión general)
URL del 00-INDEX.md de la carpeta que vas a trabajar
URLs de los archivos específicos que necesitas


### 🧭 Flujo de Carga Óptimo para IAs (Minimizar Tokens)

Al iniciar un chat nuevo, seguir este orden estricto:

1. **Primero**: Cargar `knowledge-graph.json` (URL raw arriba)
   → Identificar nodos con `priority: "Siempre"` o `"Alta"`
   → Filtrar por `domain` relevante a la tarea

2. **Segundo**: Cargar solo los archivos referenciados por esos nodos
   → Evitar exploración secuencial de carpetas

3. **Tercero**: Usar wikilinks del grafo para navegación profunda
   → Seguir `edges[]` solo si es necesario para contexto adicional

> 💡 **Regla de oro**: Si el grafo indica que un archivo tiene `priority: "Baja"` y no es target de un edge desde tu nodo inicial, **no cargarlo**. Ahorro estimado: 60-80% de tokens por sesión.


### 🧭 Flujo de Carga Óptimo para IAs (Minimizar Tokens)

Al iniciar un chat nuevo, seguir este orden estricto:

1. **Primero**: Cargar `knowledge-graph.json` (URL raw arriba)
   → Identificar nodos con `priority: "Siempre"` o `"Alta"`
   → Filtrar por `domain` relevante a la tarea

2. **Segundo**: Cargar solo los archivos referenciados por esos nodos
   → Evitar exploración secuencial de carpetas

3. **Tercero**: Usar wikilinks del grafo para navegación profunda
   → Seguir `edges[]` solo si es necesario para contexto adicional

> 💡 **Regla de oro**: Si el grafo indica que un archivo tiene `priority: "Baja"` y no es target de un edge desde tu nodo inicial, **no cargarlo**. Ahorro estimado: 60-80% de tokens por sesión.

### **Para mantener actualizado:**

Cada vez que crees un archivo nuevo, actualiza este PROJECT_TREE.md
Cambia el estado de 🆕 a ✅
Actualiza el resumen de estado (% completado)
Haz commit y push del PROJECT_TREE.md también

### **URLs Raw para IAs (cuando el repo sea público):**


Base URL: https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/

Ejemplos:
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/PROJECT_OVERVIEW.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/00-CONTEXT/00-INDEX.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/01-RULES/00-INDEX.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/05-CONFIGURATIONS/docker-compose/vps1-n8n-uazapi.yml
    

---

## 🚀 SIGUIENTES PASOS INMEDIATOS

Orden	Archivo	                    Carpeta	        Estado
1	    00-INDEX.md	                00-CONTEXT/ 	✅ COMPLETADO
2	    facundo-core-context.md	    00-CONTEXT/	  ✅ COMPLETADO
3	    facundo-infrastructure.md	  00-CONTEXT/	  ✅ COMPLETADO
4	    facundo-business-model.md	  00-CONTEXT/  	✅ COMPLETADO
5	    00-INDEX.md	                01-RULES/	    ✅ COMPLETADO
6	    02-RESOURCE-GUARDRAILS.md	  01-RULES/	    ✅ COMPLETADO
7	    01-ARCHITECTURE-RULES.md	  01-RULES/	    ✅ COMPLETADO

---
##    VALIDACIÓN DE ESTRUCTURA

Criterio	                               Estado	         Observación
Separación RULES vs PROCEDURES	            ✅ Correcta	     Rules = constraints, Procedures = pasos
Separación RULES vs SKILLS	                ✅ Correcta	     Rules = qué hacer, Skills = cómo hacer
Separación AGENTS vs WORKFLOWS	            ✅ Correcta	     Agents = especificación, Workflows = implementación
Separación CONFIGURATIONS vs PROGRAMMING	  ✅ Correcta	     Configs = archivos ejecutables, Programming = patrones
INDEX en cada carpeta	                      ✅ Correcta	     Permite navegación autónoma por IA
Numeración de archivos	                    ✅ Correcta	     Orden de carga/prioridad claro
Total de archivos	                          ✅ Optimizado	 91 vs 92 originales (sin inflación)


Última actualización: Abril 08 2026
Próxima revisión: Al completar Fase 1 (Cimientos)
Versión del árbol: 2.4.0 (estructura corregida)




---

*Última actualización: Marzo 2026*
*Próxima revisión: Al completar Fase 1 (Cimientos)*
