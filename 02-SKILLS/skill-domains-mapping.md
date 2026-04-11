---
ai_optimized: true
file_type: skill-mapping
version: 2.1.0
last_updated: 2026-04-15
author: Qwen (Orquestadora Técnica MANTIS AGENTIC)
constraints: [C2, C4, C5]
priority: Siempre
domain: SKILLS-ROOT
wikilinks:
  - "[[PROJECT_TREE.md]]"           # Referencia visual
  - "[[knowledge-graph.json]]"      # Grafo semántico (Carga prioritaria si el contexto lo permite)
  - "[[01-RULES/08-SKILLS-REFERENCE.md]]"
---
## 1. Propósito y Contexto

Este documento mapea los agentes n8n utilizados en producción con los dominios de skill necesarios para construirlos, basándose en el árbol de conocimientos existente y los patrones documentados.

La categorización sigue la estructura multi-tenant del proyecto, donde cada zona de negocio (restaurantes, hoteles, odontología, marketing, infraestructura) requiere skills específicos que se combinan con skills transversales (comunicación, RAG, base de datos).

---

## 2. Mapa General de Zonas de Skills

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    ZONAS DE SKILLS DEL PROYECTO                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                    SKILLS TRANSVERSALES                         │   │
│   │  (Aplicables a todas las zonas)                                 │   │
│   │                                                                 │   │
│   │  ├── COMUNICACIÓN                                               │   │
│   │  │   ├── WhatsApp (uazapi)                                      │   │
│   │  │   ├── Telegram Bot                                           │   │
│   │  │   ├── Gmail SMTP                                             │   │
│   │  │   └── Google Calendar                                        │   │
│   │  │                                                              │   │
│   │  ├── AI & LLM                                                   │   │
│   │  │   ├── OpenRouter API                                         │   │
│   │  │   ├── Gemini AI                                              │   │
│   │  │   ├── Mistral OCR                                            │   │
│   │  │   └── Qwen3.5                                                │   │
│   │  │                                                              │   │
│   │  └── ALMACENAMIENTO                                             │   │
│   │      ├── Google Drive                                           │   │
│   │      ├── Google Sheets                                          │   │
│   │      └── Cloudinary                                             │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│   ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐      │
│   │    INFRAESTRUC.  │  │    RAG & DATOS   │  │    MARKETING     │      │
│   │                  │  │                  │  │                  │      │
│   │  • VPS Control   │  │  • Qdrant RAG    │  │  • Instagram     │      │
│   │  • SSH Tunneling │  │  • PDF Ingestion │  │  • TikTok        │      │
│   │  • Docker        │  │  • PostgreSQL    │  │  • AI Content    │      │
│   │  • Monitoring    │  │  • Supabase      │  │  • Image Gen     │      │
│   │  • Fail2Ban      │  │  • MySQL         │  │  • Video Gen     │      │
│   └──────────────────┘  └──────────────────┘  └──────────────────┘      │
│                                                                         │
│   ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐      │
│   │   RESTAURANTES   │  │     HOTELES      │  │   ODONTOLOGÍA    │      │
│   │                  │  │                  │  │                  │      │
│   │  • Reservations  │  │  • Bookings      │  │  • Appointments  │      │
│   │  • Order System  │  │  • Guest Journey │  │  • Patient Care  │      │
│   │  • POS Integr.   │  │  • Rate Monitor  │  │  • Voice Agent   │      │
│   │  • Delivery      │  │  • Pre-arrival   │  │  • SMS/Notif.    │      │
│   └──────────────────┘  └──────────────────┘  └──────────────────┘      |
|   ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐      │
│   │  BD CONOCIMIENTO │  │                  │  │                  │      │
│   │                  │  │                  │  │                  │      │
│   │  • Data RAG Ing. │  │  •               │  │  •               │      │
│   │  • DB Qdrant     │  │  •               │  │  •               │      │
│   │  • Telegram Bot  │  │  •               │  │  •               │      │
│   │  • Whatsapp Agent│  │  •               │  │  •               │      │
│   └──────────────────┘  └──────────────────┘  └──────────────────┘      |
│                                                                         |
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

# 🗺️ 2. Mapa General de Zonas de Skills (Versión Autoritativa)

> ⚠️ **Instrucción crítica para IAs**: Este archivo es la **única fuente de verdad** para navegación entre dominios de skills.  
> - **No mezcles** skills de diferentes carpetas.  
> - **No asumas** que un skill está en una carpeta por su nombre; verifica siempre la ruta en esta tabla.  
> - Para tareas que requieren múltiples skills, consulta la **Matriz de Dependencias Transversales** (sección 3), no el árbol de carpetas.

---

## 📁 Mapeo de Zonas → Carpetas → Skills (Estructura Verificada)

| 🎯 Zona / Dominio | 📂 Ruta Exacta en Repo | 📄 Skills Contenidos (nombre de archivo) | ✅/🆕 Estado | 🔗 Dependencias Cruzadas (no mezclar carpetas) |
|-------------------|------------------------|------------------------------------------|--------------|-----------------------------------------------|
| **🤖 Integración de Modelos AI** | `02-SKILLS/AI/` | `openrouter-api-integration.md`<br>`mistral-ocr-integration.md`<br>`qwen-integration.md`<br>`llama-integration.md`<br>`gemini-integration.md`<br>`gpt-integration.md`<br>`deepseek-integration.md`<br>`minimax-integration.md`<br>`voice-agent-integration.md`<br>`image-gen-api.md`<br>`video-gen-api.md` | 🆕 0/11 | BASE DE DATOS-RAG (para contexto), COMUNICACIÓN (para output) |
| **📡 Infraestructura (Servidores)** | `02-SKILLS/INFRAESTRUCTURA/` | `ssh-tunnels-remote-services.md` ✅<br>`docker-compose-networking.md` ✅<br>`espocrm-setup.md` ✅<br>`fail2ban-configuration.md` ✅<br>`ufw-firewall-configuration.md` ✅<br>`ssh-key-management.md` ✅<br>`n8n-concurrency-limiting.md` ✅<br>`health-monitoring-vps.md` ✅<br>`vps-interconnection.md` ✅<br>`redis-session-management.md` 🆕<br>`environment-variable-management.md` 🆕 | ✅ 9/11 | SEGURIDAD (hardening), BASE DE DATOS-RAG (conexiones) |
| **🗄️ Base de Datos + RAG** | `02-SKILLS/BASE DE DATOS-RAG/` | `qdrant-rag-ingestion.md` ✅<br>`mysql-sql-rag-ingestion.md` 🆕<br>`rag-system-updates-all-engines.md` ✅<br>`multi-tenant-data-isolation.md` ✅<br>`postgres-prisma-rag.md` ✅<br>`supabase-rag-integration.md` ✅<br>`pdf-mistralocr-processing.md` ✅<br>`google-drive-qdrant-sync.md` ✅<br>`espocrm-api-analytics.md` ✅<br>`mysql-optimization-4gb-ram.md` ✅ | ✅ 9/10 | INFRAESTRUCTURA (conexiones), AI (para prompts de ingestión) |
| **📱 WhatsApp RAG Agents** | `02-SKILLS/WHATSAPP-RAG AGENTS/` | `whatsapp-rag-openrouter.md` 🆕<br>`whatsapp-uazapi-integration.md` 🆕<br>`telegram-bot-integration.md` 🆕<br>`multi-channel-routing.md` 🆕 | 🆕 0/4 | AI (modelos), BASE DE DATOS-RAG (contexto), COMUNICACIÓN (canales) |
| **📸 Instagram + Social Media** | `02-SKILLS/INSTAGRAM-SOCIAL-MEDIA/` | `instagram-api-integration.md` 🆕<br>`cloudinary-media-management.md` 🆕<br>`ai-image-generation.md` 🆕<br>`ai-video-creation.md` 🆕<br>`multi-platform-posting.md` 🆕<br>`social-media-alerts-telegram.md` 🆕 | 🆕 0/6 | AI (generación), COMUNICACIÓN (alertas), DEPLOYMENT (rollout) |
| **🦷 Vertical: Odontología** | `02-SKILLS/ODONTOLOGÍA/` | `dental-appointment-automation.md` 🆕<br>`voice-agent-dental.md` 🆕<br>`google-calendar-dental.md` 🆕<br>`supabase-dental-patient.md` 🆕<br>`phone-integration-dental.md` 🆕<br>`gmail-smtp-integration.md` 🆕 | 🆕 0/7 | COMUNICACIÓN (SMTP/Calendar), BASE DE DATOS-RAG (pacientes), AI (voice) |
| **🏨 Vertical: Hoteles/Posadas** | `02-SKILLS/HOTELES-POSADAS/` | `hotel-booking-automation.md` 🆕<br>`hotel-receptionist-whatsapp.md` 🆕<br>`hotel-competitor-monitoring.md` 🆕<br>`hotel-guest-journey.md` 🆕<br>`hotel-pre-arrival-messages.md` 🆕<br>`redis-session-management.md` 🆕<br>`slack-hotel-integration.md` 🆕 | 🆕 0/8 | WhatsApp RAG Agents, COMUNICACIÓN, INFRAESTRUCTURA (Redis) |
| **🍕 Vertical: Restaurantes** | `02-SKILLS/RESTAURANTES/` | `restaurant-booking-ai.md` 🆕<br>`restaurant-order-chatbot.md` 🆕<br>`restaurant-pos-integration.md` 🆕<br>`restaurant-voice-agents.md` 🆕<br>`restaurant-menu-management.md` 🆕<br>`restaurant-delivery-tracking.md` 🆕<br>`restaurant-google-maps-leadgen.md` 🆕<br>`apify-web-scraping.md` 🆕<br>`airtable-restaurant-db.md` 🆕<br>`restaurant-multi-channel-receptionist.md` 🆕 | 🆕 0/11 | AI (chatbot/voice), BASE DE DATOS-RAG (menús), COMUNICACIÓN (pedidos) |
| **📧 Comunicación (Genérico)** | `02-SKILLS/COMUNICACIÓN/` | `telegram-bot-integration.md` ✅<br>`gmail-smtp-integration.md` ✅<br>`google-calendar-api-integration.md` 🆕<br>`email-notification-patterns.md` 🆕<br>`whatsApp-rag-openRouter.md` 🆕<br>`whatsapp-uazapi-integration.md` 🆕 | ✅ 2/7 | INFRAESTRUCTURA (SMTP), SEGURIDAD (encriptación de mensajes) |
| **🔒 Seguridad** | `02-SKILLS/SEGURIDAD/` | `backup-encryption.md` ✅<br>`rsync-automation.md` ✅<br>`security-hardening-vps.md` ✅ | ✅ 3/3 | INFRAESTRUCTURA (VPS), BASE DE DATOS-RAG (backup de vectores) |
| **🧠 Patrones n8n** | `02-SKILLS/N8N-PATTERNS/` | `n8n-workflow-patterns.md` 🆕<br>`n8n-agent-patterns.md` 🆕<br>`n8n-error-handling.md` 🆕 | 🆕 0/3 | INFRAESTRUCTURA (concurrencia), AI (agentes LangChain) |
| **🚀 Deployment** | `02-SKILLS/DEPLOYMENT/` | `multi-channel-deployment.md` 🆕 | 🆕 0/1 | INFRAESTRUCTURA, SEGURIDAD, N8N-PATTERNS |
| **📁 Root de Skills** | `02-SKILLS/` | `00-INDEX.md` 🆕<br>`skill-domains-mapping.md` ✅ | ✅ 1/2 | — |

> 💡 **Convención de estados**:  
> - ✅ = Skill completado, validado y listo para uso en producción  
> - 🆕 = Skill pendiente de desarrollo (estructura definida, contenido por escribir)  
> - ⏳ = En progreso (no aplica en esta versión; se usará cuando haya WIP)

---

## 🔗 Matriz de Dependencias Transversales (Para Tareas Multi-Skill)

> ⚠️ **Importante**: Esta matriz indica **qué skills se combinan para una tarea**, pero **NO implica que los archivos estén en la misma carpeta**.  
> Las IAs deben cargar cada skill desde su ruta exacta según la tabla anterior.

| 🎯 Tarea Tipo | Skills Requeridos (cargar desde sus carpetas originales) | Constraint Crítico |
|---------------|----------------------------------------------------------|-------------------|
| **Agente WhatsApp con RAG** | 1. `AI/openrouter-api-integration.md`<br>2. `BASE DE DATOS-RAG/qdrant-rag-ingestion.md`<br>3. `WHATSAPP-RAG AGENTS/whatsapp-rag-openrouter.md`<br>4. `COMUNICACIÓN/telegram-bot-integration.md` (para fallback) | C4 (tenant_id en todos los payloads) |
| **Monitoreo de VPS + Alertas** | 1. `INFRAESTRUCTURA/health-monitoring-vps.md`<br>2. `SEGURIDAD/rsync-automation.md`<br>3. `COMUNICACIÓN/telegram-bot-integration.md` | C1 (máx 75% RAM por servicio) |
| **Vertical Odontología: Citas + Voz** | 1. `ODONTOLOGÍA/dental-appointment-automation.md`<br>2. `ODONTOLOGÍA/voice-agent-dental.md`<br>3. `AI/gemini-integration.md`<br>4. `COMUNICACIÓN/google-calendar-api-integration.md` | C4 (aislamiento de datos de pacientes) |
| **Generación de Contenido Social** | 1. `INSTAGRAM-SOCIAL-MEDIA/ai-image-generation.md`<br>2. `AI/image-gen-api.md`<br>3. `INSTAGRAM-SOCIAL-MEDIA/multi-platform-posting.md`<br>4. `SEGURIDAD/backup-encryption.md` (para assets) | C2 (1 vCPU por job de generación) |
| **Deploy Multi-Canal** | 1. `DEPLOYMENT/multi-channel-deployment.md`<br>2. `INFRAESTRUCTURA/docker-compose-networking.md`<br>3. `SEGURIDAD/security-hardening-vps.md`<br>4. `N8N-PATTERNS/n8n-error-handling.md` | C5 (checksum + rollback automático) |

---

## 3. Agentes por Zona de Trabajo (Fuente Autoritativa)

> ⚠️ **Instrucción crítica para IAs**: 
> - Cada agente referencia skills desde sus **rutas físicas canónicas** listadas en las tablas de esta sección.
> - **Nunca asumas** carpetas por dominio conceptual (ej: `DATA-GSHEETS`, `CACHE-REDIS` son conceptos, NO carpetas).
> - Para tareas multi-skill, carga cada archivo desde su ruta exacta. Si una ruta devuelve 404, detén y reporta en `validation-log.json`.

> 🗺️ **Mapeo de Dominios Conceptuales → Rutas Físicas Reales**:
> | Dominio Conceptual | Ruta Física Canónica | Nota |
> |-------------------|---------------------|------|
> | `DATA-GSHEETS` / `DATA-GDRIVE` | `02-SKILLS/BASE DE DATOS-RAG/google-drive-qdrant-sync.md` | Reutilizar patrón de sync Google Workspace |
> | `CACHE-REDIS` | `02-SKILLS/INFRAESTRUCTURA/redis-session-management.md` | Skill de infraestructura, no vertical |
> | `COM-WhatsApp` | `02-SKILLS/COMUNICACIÓN/whatsapp-uazapi-integration.md` | 🆕 Pendiente |
> | `COM-GCalendar` | `02-SKILLS/COMUNICACIÓN/google-calendar-api-integration.md` | 🆕 Pendiente |
> | `COM-SLACK` | `02-SKILLS/HOTELES-POSADAS/slack-hotel-integration.md` | Skill verticalizado (ajustar genérico si aplica) |
> | `COM-PHONE` | `02-SKILLS/ODONTOLOGÍA/phone-integration-dental.md` | Skill verticalizado |
> | `POS-INTEGRATION` | `02-SKILLS/RESTAURANTES/restaurant-pos-integration.md` | 🆕 Pendiente |
> | `VECTOR-QDRANT` | `02-SKILLS/BASE DE DATOS-RAG/qdrant-rag-ingestion.md` | Cubierto por skill de ingestión |

> ⚙️ **Nota técnica para URLs raw**:
> - `BASE DE DATOS-RAG` → Codificación: `BASE%20DE%20DATOS-RAG`
> - `COMUNICACIÓN` → Codificación: `COMUNICACI%C3%93N`
> - **Regla**: Usa siempre la ruta con espacios/acentos en markdown. Los scripts de sync se encargan de la codificación URL.

> 🏷️ **Convención de Nomenclatura para Agentes**:
> - Formato: `{zona}-{funcion}-{canal1}-{canal2}` (máx 5 segmentos)
> - Separador: guión medio `-` exclusivamente
> - Ejemplo válido: `corp-kb-onboarding-telegram`
> - Agentes con >5 segmentos se consideran legacy; usar alias corto en specs.

---

### 3.1 Zona: Infraestructura y Servidores

#### SKILL-DOMAIN: INFRA-SERVERS

| Agente | Dominios Conceptuales | Descripción |
|--------|------------------|-------------|
| `vps-monitor-hostinger-kvm1-telegram-gmail` | INFRA-MONITORING, COM-Telegram, COM-Gmail | Monitoreo de VPS con alertas por Telegram y Gmail |
| `vps-to-vps-monitor-interconection-hostinger` | INFRA-VPS-INTERCONNECTION, COM-Telegram, COM-Gmail | Monitoreo de interconexión entre VPS |
| `reac-agent-controlvps-hostinger-ssh-telegram` | INFRA-SSH, INFRA-DOCKER, COM-Telegram | Control de VPS vía SSH con Telegram |
| `interconexion-servidor1-n8n-uazapi-servidor2-qdrant-espocrm-sql` | INFRA-SSH-TUNNELS, DB-QDRANT, DB-MYSQL, APP-ESPOCRM | Interconexión entre servidores con túneles SSH |

**Skills requeridos (rutas canónicas verificadas):**

| Skill ID | Nombre | Ruta Canónica | Estado | Constraints |
|----------|--------|--------------|--------|------------|
| INFRA-001 | SSH Key Management | `02-SKILLS/INFRAESTRUCTURA/ssh-key-management.md` | ✅ | C3 |
| INFRA-002 | n8n Concurrency Limiting | `02-SKILLS/INFRAESTRUCTURA/n8n-concurrency-limiting.md` | ✅ | C1, C2 |
| INFRA-003 | Health Monitoring VPS | `02-SKILLS/INFRAESTRUCTURA/health-monitoring-vps.md` | ✅ | C1 |
| INFRA-004 | VPS Interconnection | `02-SKILLS/INFRAESTRUCTURA/vps-interconnection.md` | ✅ | C3 |
| INFRA-005 | SSH Tunnels Remote Services | `02-SKILLS/INFRAESTRUCTURA/ssh-tunnels-remote-services.md` | ✅ | C3 |
| INFRA-006 | Docker Compose Networking | `02-SKILLS/INFRAESTRUCTURA/docker-compose-networking.md` | ✅ | C1, C2 |
| INFRA-007 | UFW Firewall Configuration | `02-SKILLS/INFRAESTRUCTURA/ufw-firewall-configuration.md` | ✅ | C3 |
| INFRA-008 | Fail2Ban Configuration | `02-SKILLS/INFRAESTRUCTURA/fail2ban-configuration.md` | ✅ | C3 |
| COM-001 | Telegram Bot Integration | `02-SKILLS/COMUNICACIÓN/telegram-bot-integration.md` | ✅ | C3 |
| COM-002 | Gmail SMTP Integration | `02-SKILLS/COMUNICACIÓN/gmail-smtp-integration.md` | ✅ | C3 |

> 💡 **Skills transversales para esta zona**: `COM-001`, `COM-002` (ya listados en tabla). No buscar en otras carpetas.

---

### 3.2 Zona: RAG y Base de Datos

#### SKILL-DOMAIN: DATA-RAG

| Agente | Dominios Conceptuales | Descripción |
|--------|------------------|-------------|
| `pdf-mistralocr-ragqdrant-openrouter` | DATA-RAG-INGESTION, AI-MISTRAL-OCR, VECTOR-QDRANT, AI-OPENROUTER | Ingesta de PDFs con OCR y vectorización |
| `postgresql-rag-ingestion` | DB-POSTGRESQL, DATA-RAG-INGESTION, VECTOR-QDRANT | RAG desde PostgreSQL |
| `sql-rag-ingestion` | DB-MYSQL, DATA-RAG-INGESTION, VECTOR-QDRANT | RAG desde MySQL/SQL |
| `supabase-rag-ingestion` | DB-SUPABASE, DATA-RAG-INGESTION, VECTOR-QDRANT | RAG desde Supabase |
| `google-drive-qdrant-mistral-ocr-whatsapp` | DATA-GDRIVE, DATA-RAG-INGESTION, AI-MISTRAL-OCR, COM-WhatsApp | RAG con Google Drive y WhatsApp |
| `google-drive-qdrant-openrouter-chat-whatsapp` | DATA-GDRIVE, VECTOR-QDRANT, AI-OPENROUTER, COM-WhatsApp | Chatbot RAG WhatsApp |
| `google-drive-qdrant-openrouter-chat-telegram` | DATA-GDRIVE, VECTOR-QDRANT, AI-OPENROUTER, COM-Telegram | Chatbot RAG Telegram |

**Skills requeridos (rutas canónicas verificadas):**

| Skill ID | Nombre | Ruta Canónica | Estado | Constraints |
|----------|--------|--------------|--------|------------|
| DATA-001 | Qdrant RAG Ingestion | `02-SKILLS/BASE DE DATOS-RAG/qdrant-rag-ingestion.md` | ✅ | C4 |
| DATA-002 | Multi-tenant Data Isolation | `02-SKILLS/BASE DE DATOS-RAG/multi-tenant-data-isolation.md` | ✅ | C4 |
| DATA-003 | Google Drive Qdrant Sync | `02-SKILLS/BASE DE DATOS-RAG/google-drive-qdrant-sync.md` | ✅ | C3 |
| DATA-004 | MySQL Optimization 4GB RAM | `02-SKILLS/BASE DE DATOS-RAG/mysql-optimization-4gb-ram.md` | ✅ | C1 |
| DATA-005 | PostgreSQL Prisma RAG | `02-SKILLS/BASE DE DATOS-RAG/postgres-prisma-rag.md` | ✅ | C4 |
| DATA-006 | Supabase RAG Integration | `02-SKILLS/BASE DE DATOS-RAG/supabase-rag-integration.md` | ✅ | C4 |
| DATA-007 | PDF MistralOCR Processing | `02-SKILLS/BASE DE DATOS-RAG/pdf-mistralocr-processing.md` | ✅ | C6 |
| DATA-008 | EspoCRM API Analytics | `02-SKILLS/BASE DE DATOS-RAG/espocrm-api-analytics.md` | ✅ | C3 |
| AI-001 | OpenRouter API Integration | `02-SKILLS/AI/openrouter-api-integration.md` | 🆕 | C6 |
| AI-002 | Mistral OCR Integration | `02-SKILLS/AI/mistral-ocr-integration.md` | 🆕 | C6 |

> 💡 **Skills transversales para esta zona**: `COM-001` (Telegram), `COM-003` (WhatsApp 🆕). Cargar desde `COMUNICACIÓN/`.

---

### 3.3 Zona: Restaurantes

#### SKILL-DOMAIN: BIZ-RESTAURANT

| Agente | Dominios Conceptuales | Descripción |
|--------|------------------|-------------|
| `restaurant-openrouter-booking-telegram-calendar-email` | BIZ-RESTAURANT, AI-OPENROUTER, COM-Telegram, COM-Gmail, COM-GCalendar | Reservas con IA |
| `restaurant-order-chatbot-qwen-pos` | BIZ-RESTAURANT, AI-QWEN, POS-INTEGRATION | Chatbot de pedidos |
| `restaurant-whatsapp-llama-customer-service` | BIZ-RESTAURANT, AI-LLAMA, COM-WhatsApp | Atención al cliente |
| `restaurant-whatsapp-ai-google-sheets-booking` | BIZ-RESTAURANT, COM-WhatsApp, DATA-GSHEETS, AI-OPENROUTER | Reservas vía WhatsApp |
| `restaurant-ai-voice-call-telegram-booking` | BIZ-RESTAURANT, AI-VOICE, COM-Telegram | Reservas por voz |
| `restaurant-whatsapp-telegram-receptionist` | BIZ-RESTAURANT, COM-WhatsApp, COM-Telegram | Recepcionista virtual |
| `restaurant-google-maps-apify-airtable-lead` | BIZ-RESTAURANT, DATA-APIFY, DATA-AIRTABLE | Generación de leads |
| `restaurant-whatsapp-gpt4o-supabase-order` | BIZ-RESTAURANT, COM-WhatsApp, AI-GPT4O, DB-SUPABASE | Pedidos y delivery |

**Skills requeridos (carpeta RESTAURANTES):**

| Skill ID | Nombre | Ruta Canónica | Estado | Constraints |
|----------|--------|--------------|--------|------------|
| REST-001 | Restaurant Booking AI | `02-SKILLS/RESTAURANTES/restaurant-booking-ai.md` | 🆕 | C4 |
| REST-002 | Restaurant Order Chatbot | `02-SKILLS/RESTAURANTES/restaurant-order-chatbot.md` | 🆕 | C4, C6 |
| REST-003 | Restaurant POS Integration | `02-SKILLS/RESTAURANTES/restaurant-pos-integration.md` | 🆕 | C3 |
| REST-004 | Restaurant Voice Agents | `02-SKILLS/RESTAURANTES/restaurant-voice-agents.md` | 🆕 | C6 |
| REST-005 | Restaurant Menu Management | `02-SKILLS/RESTAURANTES/restaurant-menu-management.md` | 🆕 | C4 |
| REST-006 | Restaurant Delivery Tracking | `02-SKILLS/RESTAURANTES/restaurant-delivery-tracking.md` | 🆕 | C4 |
| REST-007 | Restaurant Google Maps Leadgen | `02-SKILLS/RESTAURANTES/restaurant-google-maps-leadgen.md` | 🆕 | C3 |
| REST-008 | Apify Web Scraping | `02-SKILLS/RESTAURANTES/apify-web-scraping.md` | 🆕 | C3 |
| REST-009 | Airtable Restaurant DB | `02-SKILLS/RESTAURANTES/airtable-restaurant-db.md` | 🆕 | C4 |
| REST-010 | Restaurant Multi-Channel Receptionist | `02-SKILLS/RESTAURANTES/restaurant-multi-channel-receptionist.md` | 🆕 | C4 |

> 💡 **Skills transversales**: `AI-003` (Qwen 🆕), `AI-004` (Llama 🆕), `AI-001` (OpenRouter 🆕), `DATA-GSHEETS` (reutilizar `BASE DE DATOS-RAG/google-drive-qdrant-sync.md`), `COM-003` (WhatsApp 🆕).

---

### 3.4 Zona: Hoteles y Posadas

#### SKILL-DOMAIN: BIZ-HOTEL

| Agente | Dominios Conceptuales | Descripción |
|--------|------------------|-------------|
| `hotel-gmail-google-sheets-openrouter-booking` | BIZ-HOTEL, COM-Gmail, DATA-GSHEETS, AI-OPENROUTER | Solicitudes de reserva |
| `hotel-guest-journey-gmail-google-sheets` | BIZ-HOTEL, COM-Gmail, DATA-GSHEETS | Automatización del guest journey |
| `hotel-whatsapp-gemini-redis-google-sheets-receptionist` | BIZ-HOTEL, COM-WhatsApp, AI-GEMINI, CACHE-REDIS, DATA-GSHEETS | Recepcionista virtual |
| `hotel-whatsapp-minimax-competitor-rate-qa` | BIZ-HOTEL, COM-WhatsApp, AI-MINIMAX | Monitoreo de competidores |
| `hotel-pre-arrival-openai-google-sheets-slack` | BIZ-HOTEL, AI-OPENAI, DATA-GSHEETS, COM-SLACK | Mensajes pre-llegada |

**Skills requeridos (carpeta HOTELES-POSADAS):**

| Skill ID | Nombre | Ruta Canónica | Estado | Constraints |
|----------|--------|--------------|--------|------------|
| HOTEL-001 | Hotel Booking Automation | `02-SKILLS/HOTELES-POSADAS/hotel-booking-automation.md` | 🆕 | C4 |
| HOTEL-002 | Hotel Receptionist WhatsApp | `02-SKILLS/HOTELES-POSADAS/hotel-receptionist-whatsapp.md` | 🆕 | C4, C6 |
| HOTEL-003 | Hotel Competitor Monitoring | `02-SKILLS/HOTELES-POSADAS/hotel-competitor-monitoring.md` | 🆕 | C3 |
| HOTEL-004 | Hotel Guest Journey | `02-SKILLS/HOTELES-POSADAS/hotel-guest-journey.md` | 🆕 | C4 |
| HOTEL-005 | Hotel Pre-Arrival Messages | `02-SKILLS/HOTELES-POSADAS/hotel-pre-arrival-messages.md` | 🆕 | C3 |
| HOTEL-006 | Redis Session Management | `02-SKILLS/INFRAESTRUCTURA/redis-session-management.md` | 🆕 | C1, C2 |
| HOTEL-007 | Slack Hotel Integration | `02-SKILLS/HOTELES-POSADAS/slack-hotel-integration.md` | 🆕 | C3 |

> 💡 **Skills transversales**: `AI-006` (Gemini 🆕), `AI-007` (MiniMax 🆕), `CACHE-REDIS` (ver `INFRAESTRUCTURA/redis-session-management.md`), `DATA-GSHEETS` (reutilizar `BASE DE DATOS-RAG/google-drive-qdrant-sync.md`).

---

### 3.5 Zona: Odontología

#### SKILL-DOMAIN: BIZ-DENTAL

| Agente | Dominios Conceptuales | Descripción |
|--------|------------------|-------------|
| `dental-appointments-google-calendar-email-gpt` | BIZ-DENTAL, COM-Gmail, COM-GCalendar, AI-GPT | Citas con notificaciones |
| `dental-patient-response-gpt-google-sheets` | BIZ-DENTAL, AI-GPT, DATA-GSHEETS | Respuesta automatizada |
| `dental-chatbot-google-calendar-scheduler` | BIZ-DENTAL, COM-GCalendar, AI-OPENROUTER | Agenda de citas |
| `dental-supabase-phone-ai-appointment` | BIZ-DENTAL, DB-SUPABASE, COM-PHONE, AI-OPENROUTER | Sistema de administración |
| `dental-voice-agent-gemini-booking` | BIZ-DENTAL, AI-VOICE, AI-GEMINI | Agenda por voz |

**Skills requeridos (carpeta ODONTOLOGÍA):**

| Skill ID | Nombre | Ruta Canónica | Estado | Constraints |
|----------|--------|--------------|--------|------------|
| DENTAL-001 | Dental Appointment Automation | `02-SKILLS/ODONTOLOGÍA/dental-appointment-automation.md` | 🆕 | C4 |
| DENTAL-002 | Voice Agent Dental | `02-SKILLS/ODONTOLOGÍA/voice-agent-dental.md` | 🆕 | C6 |
| DENTAL-003 | Google Calendar Dental | `02-SKILLS/ODONTOLOGÍA/google-calendar-dental.md` | 🆕 | C3 |
| DENTAL-004 | Supabase Dental Patient | `02-SKILLS/ODONTOLOGÍA/supabase-dental-patient.md` | 🆕 | C4 |
| DENTAL-005 | Phone Integration Dental | `02-SKILLS/ODONTOLOGÍA/phone-integration-dental.md` | 🆕 | C3 |
| DENTAL-006 | Gmail SMTP Integration (vertical) | `02-SKILLS/ODONTOLOGÍA/gmail-smtp-integration.md` | 🆕 | C3 |

> 💡 **Skills transversales**: `AI-008` (GPT 🆕), `AI-006` (Gemini 🆕), `COM-GCalendar` (ver `COMUNICACIÓN/google-calendar-api-integration.md`), `DATA-GSHEETS` (reutilizar `BASE DE DATOS-RAG/google-drive-qdrant-sync.md`).

---

### 3.6 Zona: Marketing + Social Media

#### SKILL-DOMAIN: MKT-SOCIAL

| Agente | Dominios Conceptuales | Descripción |
|--------|------------------|-------------|
| `instagram-carousel-gdrive-cloudinary-telegram` | MKT-INSTAGRAM, DATA-GDRIVE, MEDIA-CLOUDINARY, COM-Telegram | Carouseles de Instagram |
| `instagram-ai-content-google-sheets-publishing` | MKT-INSTAGRAM, AI-OPENROUTER, DATA-GSHEETS | Contenido automatizado |
| `instagram-reels-workflow-automation` | MKT-INSTAGRAM, MKT-REELS | Workflow de Reels |
| `tiktok-instagram-fb-gemini-video-telegram` | MKT-TIKTOK, MKT-FACEBOOK, AI-GEMINI, AI-VIDEO, COM-Telegram | Videos multicanal |
| `instagram-ai-image-generation-trends` | MKT-INSTAGRAM, AI-IMAGE-GEN | Generación de imágenes |

**Skills requeridos (carpeta INSTAGRAM-SOCIAL-MEDIA):**

| Skill ID | Nombre | Ruta Canónica | Estado | Constraints |
|----------|--------|--------------|--------|------------|
| SOCIAL-001 | Instagram API Integration | `02-SKILLS/INSTAGRAM-SOCIAL-MEDIA/instagram-api-integration.md` | 🆕 | C3 |
| SOCIAL-002 | Cloudinary Media Management | `02-SKILLS/INSTAGRAM-SOCIAL-MEDIA/cloudinary-media-management.md` | 🆕 | C3 |
| SOCIAL-003 | AI Image Generation | `02-SKILLS/INSTAGRAM-SOCIAL-MEDIA/ai-image-generation.md` | 🆕 | C6 |
| SOCIAL-004 | AI Video Creation | `02-SKILLS/INSTAGRAM-SOCIAL-MEDIA/ai-video-creation.md` | 🆕 | C6 |
| SOCIAL-005 | Multi-Platform Posting | `02-SKILLS/INSTAGRAM-SOCIAL-MEDIA/multi-platform-posting.md` | 🆕 | C3 |
| SOCIAL-006 | Social Media Alerts Telegram | `02-SKILLS/INSTAGRAM-SOCIAL-MEDIA/social-media-alerts-telegram.md` | 🆕 | C4 |

> 💡 **Skills transversales**: `MEDIA-CLOUDINARY` (ver `INSTAGRAM-SOCIAL-MEDIA/cloudinary-media-management.md`), `AI-006` (Gemini 🆕), `AI-009` (DeepSeek 🆕), `AI-010/011` (Image/Video Gen 🆕).

---

### 3.7 Zona: Base de Datos Interna Empresarial 🆕

#### SKILL-DOMAIN: CORP-KB

> 🎯 **Propósito**: Permitir a nuevos empleados encontrar respuestas de forma autónoma vía WhatsApp/Telegram, reduciendo tiempo de capacitación.
> 📚 **Contenido típico**: Documentación de procesos, descripciones de puestos, FAQs, guías de uso de herramientas, políticas internas.
> 🔐 **Constraint crítico**: C4 (aislamiento multi-tenant: cada empresa ve solo su KB).

| Agente | Dominios Conceptuales | Descripción |
|--------|------------------|-------------|
| `corp-kb-rag-telegram-onboarding` | CORP-KB, COM-Telegram, DATA-RAG-INGESTION | Onboarding de empleados vía Telegram con RAG corporativo |
| `corp-kb-rag-whatsapp-faq` | CORP-KB, COM-WhatsApp, DATA-RAG-INGESTION | FAQs corporativas accesibles por WhatsApp |
| `corp-kb-multi-tenant-isolation` | CORP-KB, MULTI-TENANT, DB-QDRANT | Aislamiento de KB por tenant_id en Qdrant |
| `corp-kb-ingestion-pdf-docs` | CORP-KB, AI-MISTRAL-OCR, DATA-RAG-INGESTION | Ingesta automatizada de manuales y políticas en PDF |

**Skills requeridos (carpeta CORPORATE-KB):**

| Skill ID | Nombre | Ruta Canónica | Estado | Constraints |
|----------|--------|--------------|--------|------------|
| CORP-001 | Corporate KB Ingestion Pipeline | `02-SKILLS/CORPORATE-KB/corp-kb-ingestion-pipeline.md` | 🆕 | C4, C5 |
| CORP-002 | Corporate KB RAG Telegram | `02-SKILLS/CORPORATE-KB/corp-kb-rag-telegram.md` | 🆕 | C4 |
| CORP-003 | Corporate KB RAG WhatsApp | `02-SKILLS/CORPORATE-KB/corp-kb-rag-whatsapp.md` | 🆕 | C4 |
| CORP-004 | Corporate KB Multi-Tenant Isolation | `02-SKILLS/CORPORATE-KB/corp-kb-multi-tenant-isolation.md` | 🆕 | C4, C5 |
| CORP-005 | Corporate KB Content Templates | `02-SKILLS/CORPORATE-KB/corp-kb-content-templates.md` | 🆕 | C4 |

> 💡 **Skills transversales reutilizables**: `DATA-001` (`BASE DE DATOS-RAG/qdrant-rag-ingestion.md` ✅), `COM-001` (`COMUNICACIÓN/telegram-bot-integration.md` ✅), `COM-003` (`COMUNICACIÓN/whatsapp-uazapi-integration.md` 🆕), `AI-002` (`AI/mistral-ocr-integration.md` 🆕).
> ⚠️ **Implementación**: Crear carpeta con `.gitkeep`. Aplicar `tenant_id` en TODOS los ejemplos de queries a Qdrant. NO copiar skills transversales; referenciar por ruta canónica.

---


## 4. Estructura de Skills por Zona (Sin Árboles Mezclados)

> ⚠️ **Regla estricta**: Cada zona lista SOLO los archivos que existen en su carpeta canónica. 
> Para skills transversales, consultar la tabla de la Sección 2.

### 4.1 Zona: Infraestructura

02-SKILLS/INFRAESTRUCTURA/
├── ssh-key-management.md                   ✅
├── ufw-firewall-configuration.md           ✅
├── fail2ban-configuration.md               ✅
├── n8n-concurrency-limiting.md             ✅
├── health-monitoring-vps.md                ✅
├── vps-interconnection.md                  ✅
├── ssh-tunnels-remote-services.md          ✅
├── docker-compose-networking.md            ✅
├── espocrm-setup.md                        ✅
├── redis-session-management.md             ✅
└── environment-variable-management.md      ✅

### 4.2 Zona: Comunicación

02-SKILLS/COMUNICACIÓN/
├── telegram-bot-integration.md            ✅
├── gmail-smtp-integration.md              ✅
├── google-calendar-api-integration.md     ✅
├── email-notification-patterns.md         🆕
├── whatsApp-rag-openRouter.md             ✅
└── whatsapp-uazapi-integration.md         🆕

### 4.3 Zona: Base de Datos + RAG

02-SKILLS/BASE DE DATOS-RAG/
├── qdrant-rag-ingestion.md                 ✅
├── multi-tenant-data-isolation.md          ✅
├── rag-system-updates-all-engines.md       ✅
├── mysql-optimization-4gb-ram.md           ✅
├── pdf-mistralocr-processing.md            ✅
├── postgres-prisma-rag.md                  ✅
├── supabase-rag-integration.md             ✅
├── mysql-sql-rag-ingestion.md              ✅
├── google-drive-qdrant-sync.md             ✅
└── espocrm-api-analytics.md                ✅

### 4.4 Zona: AI

02-SKILLS/AI/
├── openrouter-api-integration.md           🆕
├── mistral-ocr-integration.md              🆕
├── qwen-integration.md                     🆕
├── llama-integration.md                    🆕
├── gemini-integration.md                   🆕
├── gpt-integration.md                      🆕
├── deepseek-integration.md                 🆕
├── minimax-integration.md                  🆕
├── voice-agent-integration.md              🆕
├── image-gen-api.md                        🆕
└── video-gen-api.md                        🆕

### 4.5 Zona: Vertical - Restaurantes

02-SKILLS/RESTAURANTES/
├── restaurant-booking-ai.md                🆕
├── restaurant-order-chatbot.md             🆕
├── restaurant-pos-integration.md           🆕
├── restaurant-voice-agents.md              🆕
├── restaurant-menu-management.md           🆕
├── restaurant-delivery-tracking.md         🆕
├── restaurant-google-maps-leadgen.md       🆕
├── apify-web-scraping.md                   🆕
├── airtable-restaurant-db.md               🆕
└── restaurant-multi-channel-receptionist.md 🆕

### 4.6 Zona: Vertical - Hoteles/Posadas

02-SKILLS/HOTELES-POSADAS/
├── hotel-booking-automation.md             🆕
├── hotel-receptionist-whatsapp.md          🆕
├── hotel-competitor-monitoring.md          🆕
├── hotel-guest-journey.md                  🆕
├── hotel-pre-arrival-messages.md           🆕
├── redis-session-management.md             🆕
└── slack-hotel-integration.md              🆕

### 4.7 Zona: Vertical - Odontología

02-SKILLS/ODONTOLOGÍA/
├── dental-appointment-automation.md        🆕
├── voice-agent-dental.md                   🆕
├── google-calendar-dental.md               🆕
├── supabase-dental-patient.md              🆕
├── phone-integration-dental.md             🆕
└── gmail-smtp-integration.md               🆕

### 4.8 Zona: Marketing + Social Media

02-SKILLS/INSTAGRAM-SOCIAL-MEDIA/
├── instagram-api-integration.md            🆕
├── cloudinary-media-management.md          🆕
├── ai-image-generation.md                  🆕
├── ai-video-creation.md                    🆕
├── multi-platform-posting.md               🆕
└── social-media-alerts-telegram.md         🆕

### 4.9 Zona: Seguridad

02-SKILLS/SEGURIDAD/
├── backup-encryption.md                    ✅
├── rsync-automation.md                     ✅
└── security-hardening-vps.md               ✅

### 4.10 Zona: Corporate Knowledge Base 🆕

02-SKILLS/CORPORATE-KB/
├── .gitkeep                                ✅ (estructura base)
├── corp-kb-ingestion-pipeline.md           🆕
├── corp-kb-rag-telegram.md                 🆕
├── corp-kb-rag-whatsapp.md                 🆕
├── corp-kb-multi-tenant-isolation.md       🆕
└── corp-kb-content-templates.md            🆕

---

## 5. Matriz de Dependencias Transversales (Skills Reutilizables)

| Skill Transversal | Carpeta Canónica | Usado en Zonas | Constraint Crítico |
|------------------|-----------------|----------------|-------------------|
| `telegram-bot-integration.md` | `COMUNICACIÓN/` | Infra, RAG, Restaurantes, Hoteles, Odontología, Marketing, CORP-KB | C4 (tenant_id en payloads) |
| `gmail-smtp-integration.md` | `COMUNICACIÓN/` | Infra, Restaurantes, Hoteles, Odontología | C3 (no exponer credenciales) |
| `qdrant-rag-ingestion.md` | `BASE DE DATOS-RAG/` | RAG, CORP-KB | C4 (aislamiento por tenant_id) |
| `openrouter-api-integration.md` | `AI/` | RAG, Restaurantes, Hoteles, Odontología, Marketing, CORP-KB | C2 (1 vCPU por job de inferencia) |
| `redis-session-management.md` | `INFRAESTRUCTURA/` | Hoteles, Restaurantes | C1 (máx 75% RAM por servicio) |
| `backup-encryption.md` | `SEGURIDAD/` | Todas las zonas | C5 (checksum SHA256 + verificación) |
| `multi-tenant-data-isolation.md` | `BASE DE DATOS-RAG/` | Todas las zonas multi-tenant | C4 (obligatorio en TODAS las queries) |

> 💡 **Regla de oro**: Si un skill aparece en múltiples zonas, **siempre se carga desde su carpeta canónica**. Nunca se duplica ni se mueve.

---

## 6. Templates de Skills por Categoría (SDD-Compliant)

### 6.1 Template: Skill de Infraestructura/Comunicación
```markdown
---
ai_optimized: true
file_type: skill
version: 1.0.0
last_updated: {{DATE}}
author: {{AUTHOR}}
constraints: [C1, C2, C3, C4, C5, C6]
priority: Alta
domain: {{DOMINIO}}
wikilinks:
  - "[[PROJECT_TREE.md]]"
  - "[[knowledge-graph.json]]"
  - "[[01-RULES/08-SKILLS-REFERENCE.md]]"
---

## {{SKILL-ID}}: {{Nombre del Skill}}

> {{Breve descripción en 1 línea}}

**Categoría:** {{CATEGORÍA}} | **Ruta:** `{{RUTA_CANÓNICA}}`
**Estado:** ✅ Completado / 🆕 Pendiente | **Validación SDD:** {{ESTADO}}

---

### 1. Propósito y Contexto
{{Descripción del problema que resuelve y por qué es importante}}

### 2. Arquitectura de Integración
{{Diagrama ASCII o descripción de cómo se integra con el ecosistema}}

### 3. Configuración (Copy-Paste)
{{Bloques de código ejecutables en Ubuntu 22.04/24.04}}
{{Explicar riesgos de sudo, incluir rollback}}

### 4. Uso en Workflows n8n
{{Ejemplos de nodos, configuraciones JSON, variables de entorno}}

### 5. Patrones Comunes + Ejemplos Validables
{{5 ejemplos con "✅ Deberías ver" / "❌ Si ves esto"}}

### 6. Troubleshooting Ejecutable
{{5 diagnósticos con comandos bash/Python que el usuario puede ejecutar}}

### 7. Checklist de Validación SDD
- [ ] Frontmatter YAML completo
- [ ] Constraints C1-C6 mapeados explícitamente
- [ ] tenant_id en todos los ejemplos (si aplica C4)
- [ ] Wikilinks semánticos válidos
- [ ] 5 ejemplos + 5 troubleshooting ejecutables

<!-- ai:file-end -->


### 6.2 Template: Skill de AI/RAG

---
ai_optimized: true
file_type: skill
version: 1.0.0
last_updated: {{DATE}}
author: {{AUTHOR}}
constraints: [C1, C2, C4, C6]
priority: Alta
domain: {{DOMINIO}}
wikilinks:
  - "[[knowledge-graph.json]]"
  - "[[01-RULES/06-MULTITENANCY-RULES.md]]"
---

## {{SKILL-ID}}: {{Nombre del Skill}}

> {{Descripción del modelo/API y caso de uso principal}}

**Categoría:** {{CATEGORÍA}} | **Ruta:** `{{RUTA_CANÓNICA}}`
**Modelos Soportados:** {{LISTA}} | **Rate Limits:** {{LÍMITES}}

---

### 1. Propósito y Contexto
{{Por qué este modelo/API es relevante para MANTIS AGENTIC}}

### 2. Configuración de API (Variables de Entorno)
{{.env template con explicación de cada variable}}
{{Advertencia: nunca commitear secrets}}

### 3. Patrones de Uso en n8n
{{Ejemplos de prompts, temperaturas, max_tokens, stop_sequences}}

### 4. Integración con RAG (Qdrant + tenant_id)
{{Cómo vectorizar, consultar y filtrar por tenant_id}}

### 5. Ejemplos Validables (5)
{{Cada ejemplo con: input → output esperado → cómo verificar}}

### 6. Troubleshooting (5)
{{Problemas comunes + comandos de diagnóstico ejecutables}}

### 7. Checklist de Validación SDD
- [ ] C6 aplicado: inferencia vía API cloud, no local
- [ ] C4 aplicado: tenant_id en todas las queries a Qdrant
- [ ] Rate limits documentados y respetados en ejemplos
- [ ] Costos estimados por 1k tokens (si aplica)

<!-- ai:file-end -->


### 6.3 Template: Skill de Negocio/Vertical

---
ai_optimized: true
file_type: skill
version: 1.0.0
last_updated: {{DATE}}
author: {{AUTHOR}}
constraints: [C2, C4, C5]
priority: Media
domain: {{VERTICAL}}
wikilinks:
  - "[[skill-domains-mapping.md]]"
  - "[[01-RULES/06-MULTITENANCY-RULES.md]]"
---

## {{SKILL-ID}}: {{Nombre del Skill}}

> {{Descripción del proceso de negocio que automatiza}}

**Vertical:** {{RESTAURANTES/HOTELES/ODONTOLOGÍA/CORP-KB}} | **Ruta:** `{{RUTA_CANÓNICA}}`
**Agentes que lo usan:** {{LISTA_DE_AGENTES}}

---

### 1. Propósito y Contexto de Negocio
{{Qué problema del cliente resuelve y por qué es prioritario}}

### 2. Flujo de Proceso (Diagrama ASCII)
{{Paso 1 → Paso 2 → ... → Resultado}}

### 3. Skills Transversales Requeridos
{{Lista de skills de otras carpetas que se reutilizan, con rutas canónicas}}

### 4. Workflow n8n Recomendado (JSON snippet)
{{Ejemplo mínimo viable exportable desde n8n}}

### 5. Casos de Uso por Tipo de Cliente
{{Ej: "Restaurante pequeño" vs "Cadena de hoteles"}}

### 6. Ejemplos Validables (5)
{{Cada ejemplo con: escenario → input → output esperado → cómo verificar}}

### 7. Checklist de Validación SDD
- [ ] C4 aplicado: tenant_id en todas las queries a DB
- [ ] Skills transversales referenciados por ruta canónica (no copiados)
- [ ] Ejemplos adaptados al contexto de la vertical
- [ ] Checklist incluye validación de aislamiento multi-tenant

<!-- ai:file-end -->

---

## 7. Roadmap de Skills Pendientes (Priorizado por Impacto)

### 🔴 Prioridad Crítica (Bloquean despliegue multi-tenant)

Skill	Carpeta	Dependencias Bloqueadas	Estimado	Constraint
`whatsapp-uazapi-integration.md`	`COMUNICACIÓN/`	8 agentes RAG + verticales	2 días	C3 (túneles SSH)
`openrouter-api-integration.md`	`AI/`	15+ agentes con inferencia	2 días	C6 (API cloud)
`corp-kb-multi-tenant-isolation.md`	`CORPORATE-KB/`	Onboarding de empleados	3 días	C4 (tenant_id)
`qdrant-rag-ingestion.md` (validación final)	`BASE DE DATOS-RAG/`	Todos los agentes RAG	1 día	C4 + C5

### 🟠 Prioridad Alta (Habilitan verticales)

Skill	Carpeta	Agentes Impactados	Estimado
`restaurant-booking-ai.md`	`RESTAURANTES/`	6 agentes restaurantes	2 días
`hotel-receptionist-whatsapp.md`	`HOTELES-POSADAS/`	3 agentes hoteles	2 días
`dental-appointment-automation.md`	`ODONTOLOGÍA/`	4 agentes odontología	2 días
`corp-kb-rag-telegram.md`	`CORPORATE-KB/`	Onboarding vía Telegram	2 días

### 🟡 Prioridad Media (Optimizaciones)

Skill	Carpeta	Beneficio	Estimado
`redis-session-management.md`	`INFRAESTRUCTURA/`	Sesiones persistentes en VPS 4GB	1 día
`ai-image-generation.md`	`INSTAGRAM-SOCIAL-MEDIA/`	Contenido visual automatizado	2 días
`corp-kb-content-templates.md`	`CORPORATE-KB/`	Acelerar ingestión de manuales	1 día

---

## 8. Referencias y Enlaces de Navegación

Documento	Propósito	URL Raw
`PROJECT_TREE.md`	Índice visual del repositorio	[Ver](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/PROJECT_TREE.md)
`knowledge-graph.json`	Grafo estructural para navegación semántica	[Ver](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/knowledge-graph.json)
`01-RULES/08-SKILLS-REFERENCE.md`	Especificación SDD para desarrollo de skills	[Ver](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/08-SKILLS-REFERENCE.md)
`01-RULES/06-MULTITENANCY-RULES.md`	Reglas de aislamiento multi-tenant (C4)	[Ver](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/06-MULTITENANCY-RULES.md)

---

## 🧭 Reglas de Navegación para IAs (No Ignorar)

1. **Nunca busques un skill por nombre en carpetas equivocadas**.  
   Ej: `telegram-bot-integration.md` existe en `COMUNICACIÓN/` ✅, pero también está listado como 🆕 en `WHATSAPP-RAG AGENTS/` y `ODONTOLOGÍA/`.  
   → **Siempre carga desde la ruta canónica**: `02-SKILLS/COMUNICACIÓN/telegram-bot-integration.md`.

2. **Para tareas multi-skill**, usa la Matriz de Dependencias para identificar qué archivos cargar, pero **resuelve cada ruta desde la tabla "Mapeo de Zonas"**.

3. **Si un skill aparece como 🆕 en múltiples zonas**, significa que es una plantilla verticalizada.  
   Ej: `gmail-smtp-integration.md` está en `COMUNICACIÓN/` (genérico ✅) y en `ODONTOLOGÍA/` (vertical 🆕).  
   → Carga el genérico primero, luego adapta con la vertical si es necesario.

4. **Los archivos con typo o naming inconsistente** (ej: `multi-channel-deploymen.md`) serán corregidos en el próximo commit.  
   → Mientras tanto, usa la ruta exacta listada en esta tabla.

5. **Prioridad de carga**:  
   ```text
   1. knowledge-graph.json (mapeo semántico)
   2. skill-domains-mapping.md (esta tabla)
   3. PROJECT_TREE.md (referencia visual)
   4. Skills específicos (solo los requeridos por la tarea)
   
---

Autor: Facundo (validado por Qwen - Orquestadora Técnica)
Fecha de generación: 2026-04-15
Versión del mapeo: 2.1.0
Próxima revisión: Al completar 02-SKILLS/CORPORATE-KB/
Constraint aplicado: C2 (organización modular), C4 (tenant_id en metadata), C5 (integridad de rutas)
<!-- ai:file-end -->
---

