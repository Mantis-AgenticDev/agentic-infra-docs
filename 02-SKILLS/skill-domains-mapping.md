# skill-domains-mapping.md

> **Mapeo de Dominios de Skills por Agente n8n y LangChain**

**Skill:** SD-001 | **Categoría:** SKILL MAPPING
**Última actualización:** 2026-04-10
**Validación SDD:** Pending
**Refs:** 00-CONTEXT/PROJECT_OVERVIEW.md, 01-RULES/08-SKILLS-REFERENCE.md

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
│   └──────────────────┘  └──────────────────┘  └──────────────────┘      │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Agentes por Zona

### 3.1 Zona: Infraestructura y Servidores

#### SKILL-DOMAIN: INFRA-SERVERS

| Agente | Dominios de Skill | Descripción |
|--------|------------------|-------------|
| `vps-monitor-hostinger-kvm1-telegram-gmail` | INFRA-MONITORING, COM-Telegram, COM-Gmail | Monitoreo de VPS con alertas por Telegram y Gmail |
| `vps-to-vps-monitor-interconection-hostinger` | INFRA-VPS-INTERCONNECTION, COM-Telegram, COM-Gmail | Monitoreo de interconexión entre VPS |
| `reac-agent-controlvps-hostinger-ssh-telegram` | INFRA-SSH, INFRA-DOCKER, COM-Telegram | Control de VPS via SSH con Telegram |
| `vps-shh-telegr-monitor-telegram-gmail` | INFRA-SSH, INFRA-MONITORING, COM-Telegram | Monitoreo SSH con Telegram |
| `interconexion-servidor1-n8n-uazaoi-servidor2-qdrant-espocrm-sql` | INFRA-SSH-TUNNELS, DB-QDRANT, DB-MYSQL, APP-ESPOCRM | Interconexión entre servidores con túneles SSH |

**Skills requeridos en esta zona:**

| Skill ID | Nombre | Documentación |
|----------|--------|--------------|
| INFRA-001 | SSH Key Management | 02-SKILLS/INFRAESTRUCTURA/ssh-key-management.md |
| INFRA-002 | n8n Concurrency Limiting | 02-SKILLS/INFRAESTRUCTURA/n8n-concurrency-limiting.md |
| INFRA-003 | Health Monitoring VPS | 02-SKILLS/INFRAESTRUCTURA/health-monitoring-vps.md |
| INFRA-004 | VPS Interconnection | 02-SKILLS/INFRAESTRUCTURA/vps-interconnection.md |
| INFRA-005 | SSH Tunnels Remote Services | 02-SKILLS/INFRAESTRUCTURA/ssh-tunnels-remote-services.md |
| INFRA-006 | Docker Compose Networking | 02-SKILLS/INFRAESTRUCTURA/docker-compose-networking.md |
| INFRA-007 | UFW Firewall Configuration | 02-SKILLS/INFRAESTRUCTURA/ufw-firewall-configuration.md |
| INFRA-008 | Fail2Ban Configuration | 02-SKILLS/INFRAESTRUCTURA/fail2ban-configuration.md |
| COM-001 | Telegram Bot Integration | 02-SKILLS/COMUNICACION/telegram-bot-integration.md |
| COM-002 | Gmail SMTP Integration | 02-SKILLS/COMUNICACION/gmail-smtp-integration.md |

---

### 3.2 Zona: RAG y Base de Datos

#### SKILL-DOMAIN: DATA-RAG

| Agente | Dominios de Skill | Descripción |
|--------|------------------|-------------|
| `pdf-mistralocr-ragqdrant-openrouter` | DATA-RAG-INGESTION, AI-MISTRAL-OCR, VECTOR-QDRANT, AI-OPENROUTER | Ingesta de PDFs con OCR y vectorización |
| `postgresql-rag-ingestion` | DB-POSTGRESQL, DATA-RAG-INGESTION, VECTOR-QDRANT | RAG desde PostgreSQL |
| `sql-rag-ingestion` | DB-MYSQL, DATA-RAG-INGESTION, VECTOR-QDRANT | RAG desde MySQL/SQL |
| `supabase-rag-ingestion` | DB-SUPABASE, DATA-RAG-INGESTION, VECTOR-QDRANT | RAG desde Supabase |
| `google-drive-qdrant-mistral-ocr-whatsapp` | DATA-GDRIVE, DATA-RAG-INGESTION, AI-MISTRAL-OCR, COM-WhatsApp | RAG con Google Drive y WhatsApp |
| `google-drive-qdrant-openrouter-chat-whatsapp` | DATA-GDRIVE, VECTOR-QDRANT, AI-OPENROUTER, COM-WhatsApp | Chatbot RAG WhatsApp |
| `google-drive-qdrant-openrouter-chat-telegram` | DATA-GDRIVE, VECTOR-QDRANT, AI-OPENROUTER, COM-Telegram | Chatbot RAG Telegram |

**Skills requeridos en esta zona:**

| Skill ID | Nombre | Documentación |
|----------|--------|--------------|
| DATA-001 | Qdrant RAG Ingestion | 02-SKILLS/DATOS/qdrant-rag-ingestion.md |
| DATA-002 | Multi-tenant Data Isolation | 02-SKILLS/DATOS/multi-tenant-data-isolation.md |
| DATA-003 | Google Drive Integration | 02-SKILLS/DATOS/google-drive-integration.md |
| DATA-004 | MySQL RAG | 02-SKILLS/DATOS/mysql-rag-optimization.md |
| DATA-005 | PostgreSQL RAG | 02-SKILLS/DATOS/postgresql-rag-optimization.md |
| DATA-006 | Supabase Integration | 02-SKILLS/DATOS/supabase-rag-integration.md |
| AI-001 | OpenRouter API | 02-SKILLS/AI/openrouter-api-integration.md |
| AI-002 | Mistral OCR Integration | 02-SKILLS/AI/mistral-ocr-integration.md |
| VECTOR-001 | Qdrant Setup & Config | 02-SKILLS/VECTOR/qdrant-setup.md |
| COM-003 | WhatsApp uazapi Integration | 02-SKILLS/COMUNICACION/whatsapp-uazapi-integration.md |

---

### 3.3 Zona: Restaurantes

#### SKILL-DOMAIN: BIZ-RESTAURANT

| Agente | Dominios de Skill | Descripción |
|--------|------------------|-------------|
| `restaurant-openrouter-booking-telegram-calendar-email` | BIZ-RESTAURANT, AI-OPENROUTER, COM-Telegram, COM-Gmail, COM-GCalendar | Reservas con IA |
| `restaurant-order-chatbot-qwen-pos` | BIZ-RESTAURANT, AI-QWEN, POS-INTEGRATION | Chatbot de pedidos |
| `restaurant-whatsapp-llama-customer-service` | BIZ-RESTAURANT, AI-LLAMA, COM-WhatsApp | Atención al cliente |
| `restaurant-whatsapp-ai-google-sheets-booking` | BIZ-RESTAURANT, COM-WhatsApp, DATA-GSHEETS, AI-OPENROUTER | Reservas vía WhatsApp |
| `restaurant-ai-voice-call-telegram-booking` | BIZ-RESTAURANT, AI-VOICE, COM-Telegram | Reservas por voz |
| `pizza-ordering-chatbot-openrouter` | BIZ-RESTAURANT, BIZ-ORDERING, AI-OPENROUTER | Chatbot de pizza |
| `restaurant-whatsapp-telegram-receptionist` | BIZ-RESTAURANT, COM-WhatsApp, COM-Telegram | Recepcionista virtual |
| `restaurant-google-maps-apify-airtable-lead` | BIZ-RESTAURANT, DATA-APIFY, DATA-AIRTABLE | Generación de leads |
| `restaurant-whatsapp-gpt4o-supabase-order` | BIZ-RESTAURANT, COM-WhatsApp, AI-GPT4O, DB-SUPABASE | Pedidos y delivery |
| `restaurant-gemini-google-sheets-reservation` | BIZ-RESTAURANT, AI-GEMINI, DATA-GSHEETS | Gestión de reservas |

**Skills requeridos en esta zona:**

| Skill ID | Nombre | Documentación |
|----------|--------|--------------|
| BIZ-001 | Restaurant Booking System | 02-SKILLS/BUSINESS/restaurant-booking-system.md |
| BIZ-002 | Restaurant Order Management | 02-SKILLS/BUSINESS/restaurant-order-management.md |
| BIZ-003 | POS Integration | 02-SKILLS/BUSINESS/pos-integration.md |
| BIZ-004 | Delivery Management | 02-SKILLS/BUSINESS/delivery-management.md |
| AI-001 | OpenRouter API | 02-SKILLS/AI/openrouter-api-integration.md |
| AI-003 | Qwen3.5 Integration | 02-SKILLS/AI/qwen-integration.md |
| AI-004 | Llama AI Integration | 02-SKILLS/AI/llama-integration.md |
| AI-005 | Voice Agent | 02-SKILLS/AI/voice-agent-integration.md |
| DATA-007 | Google Sheets Integration | 02-SKILLS/DATOS/google-sheets-integration.md |
| DATA-008 | Airtable Integration | 02-SKILLS/DATOS/airtable-integration.md |

---

### 3.4 Zona: Hoteles y Posadas

#### SKILL-DOMAIN: BIZ-HOTEL

| Agente | Dominios de Skill | Descripción |
|--------|------------------|-------------|
| `hotel-gmail-google-sheets-openrouter-booking` | BIZ-HOTEL, COM-Gmail, DATA-GSHEETS, AI-OPENROUTER | Solicitudes de reserva |
| `hotel-guest-journey-gmail-google-sheets` | BIZ-HOTEL, COM-Gmail, DATA-GSHEETS | Automatización del guest journey |
| `hotel-whatsapp-gemini-redis-google-sheets-receptionist` | BIZ-HOTEL, COM-WhatsApp, AI-GEMINI, CACHE-REDIS, DATA-GSHEETS | Recepcionista virtual |
| `hotel-whatsapp-minimax-competitor-rate-qa` | BIZ-HOTEL, COM-WhatsApp, AI-MINIMAX | Monitoreo de competidores |
| `hotel-pre-arrival-openai-google-sheets-slack` | BIZ-HOTEL, AI-OPENAI, DATA-GSHEETS, COM-SLACK | Mensajes pre-llegada |

**Skills requeridos en esta zona:**

| Skill ID | Nombre | Documentación |
|----------|--------|--------------|
| BIZ-010 | Hotel Booking System | 02-SKILLS/BUSINESS/hotel-booking-system.md |
| BIZ-011 | Guest Journey Automation | 02-SKILLS/BUSINESS/guest-journey-automation.md |
| BIZ-012 | Hotel Receptionist Agent | 02-SKILLS/BUSINESS/hotel-receptionist-agent.md |
| BIZ-013 | Competitor Rate Monitoring | 02-SKILLS/BUSINESS/competitor-rate-monitoring.md |
| BIZ-014 | Pre-arrival Communication | 02-SKILLS/BUSINESS/pre-arrival-communication.md |
| AI-001 | OpenRouter API | 02-SKILLS/AI/openrouter-api-integration.md |
| AI-006 | Gemini Integration | 02-SKILLS/AI/gemini-integration.md |
| AI-007 | MiniMax Integration | 02-SKILLS/AI/minimax-integration.md |
| CACHE-001 | Redis Configuration | 02-SKILLS/CACHE/redis-configuration.md |
| COM-004 | Slack Integration | 02-SKILLS/COMUNICACION/slack-integration.md |

---

### 3.5 Zona: Odontología

#### SKILL-DOMAIN: BIZ-DENTAL

| Agente | Dominios de Skill | Descripción |
|--------|------------------|-------------|
| `dental-appointments-google-calendar-email-gpt` | BIZ-DENTAL, COM-Gmail, COM-GCalendar, AI-GPT | Citas con notificaciones |
| `dental-patient-response-gpt-google-sheets` | BIZ-DENTAL, AI-GPT, DATA-GSHEETS | Respuesta automatizada |
| `dental-chatbot-google-calendar-scheduler` | BIZ-DENTAL, COM-GCalendar, AI-OPENROUTER | Agenda de citas |
| `dental-supabase-phone-ai-appointment` | BIZ-DENTAL, DB-SUPABASE, COM-PHONE, AI-OPENROUTER | Sistema de administración |
| `dental-voice-agent-gemini-booking` | BIZ-DENTAL, AI-VOICE, AI-GEMINI | Agenda por voz |

**Skills requeridos en esta zona:**

| Skill ID | Nombre | Documentación |
|----------|--------|--------------|
| BIZ-020 | Dental Appointment System | 02-SKILLS/BUSINESS/dental-appointment-system.md |
| BIZ-021 | Patient Response Automation | 02-SKILLS/BUSINESS/patient-response-automation.md |
| BIZ-022 | Dental Voice Agent | 02-SKILLS/BUSINESS/dental-voice-agent.md |
| BIZ-023 | Dental Admin System | 02-SKILLS/BUSINESS/dental-admin-system.md |
| AI-008 | GPT-3.5/4 Integration | 02-SKILLS/AI/gpt-integration.md |
| COM-005 | SMS Integration | 02-SKILLS/COMUNICACION/sms-integration.md |
| COM-006 | Phone Integration | 02-SKILLS/COMUNICACION/phone-integration.md |

---

### 3.6 Zona: Marketing

#### SKILL-DOMAIN: MKT-SOCIAL

| Agente | Dominios de Skill | Descripción |
|--------|------------------|-------------|
| `instagram-carousel-gdrive-cloudinary-telegram` | MKT-INSTAGRAM, DATA-GDRIVE, MEDIA-CLOUDINARY, COM-Telegram | Carouseles de Instagram |
| `instagram-ai-content-google-sheets-publishing` | MKT-INSTAGRAM, AI-OPENROUTER, DATA-GSHEETS | Contenido automatizado |
| `instagram-reels-workflow-automation` | MKT-INSTAGRAM, MKT-REELS | Workflow de Reels |
| `tiktok-instagram-fb-gemini-video-telegram` | MKT-TIKTOK, MKT-FACEBOOK, AI-GEMINI, AI-VIDEO, COM-Telegram | Videos multicanal |
| `instagram-reel-scenarios-gpt4o-telegram` | MKT-INSTAGRAM, AI-GPT4O, COM-Telegram | Escenarios virales |
| `instagram-ai-image-generation-trends` | MKT-INSTAGRAM, AI-IMAGE-GEN | Generación de imágenes |
| `instagram-reels-google-sheets-deepseek-captions` | MKT-INSTAGRAM, DATA-GSHEETS, AI-DEEPSEEK | Captions con IA |

**Skills requeridos en esta zona:**

| Skill ID | Nombre | Documentación |
|----------|--------|--------------|
| MKT-001 | Instagram Automation | 02-SKILLS/MARKETING/instagram-automation.md |
| MKT-002 | Instagram Reels Creation | 02-SKILLS/MARKETING/instagram-reels-creation.md |
| MKT-003 | TikTok Integration | 02-SKILLS/MARKETING/tiktok-integration.md |
| MKT-004 | Facebook Integration | 02-SKILLS/MARKETING/facebook-integration.md |
| MKT-005 | AI Content Generation | 02-SKILLS/MARKETING/ai-content-generation.md |
| MKT-006 | Image Generation Pipeline | 02-SKILLS/MARKETING/image-generation-pipeline.md |
| MKT-007 | Video Generation Pipeline | 02-SKILLS/MARKETING/video-generation-pipeline.md |
| AI-009 | DeepSeek Integration | 02-SKILLS/AI/deepseek-integration.md |
| AI-010 | Image Gen API (DALL-E/Midjourney) | 02-SKILLS/AI/image-gen-api.md |
| AI-011 | Video Gen API (Sora/Runway) | 02-SKILLS/AI/video-gen-api.md |
| MEDIA-001 | Cloudinary Integration | 02-SKILLS/MEDIA/cloudinary-integration.md |

---

## 4. Árbol de Skills Expandido por Zona

### 4.1 Zona: Infraestructura

```
02-SKILLS/
└── INFRAESTRUCTURA/
    ├── ssh-key-management.md                   ✅ Completado
    ├── ufw-firewall-configuration.md           ✅ Completado
    ├── fail2ban-configuration.md               ✅ Completado
    ├── n8n-concurrency-limiting.md             ✅ Completado
    ├── health-monitoring-vps.md                ✅ Completado
    ├── vps-interconnection.md                  ✅ Completado
    ├── ssh-tunnels-remote-services.md          ✅ Completado
    ├── docker-compose-networking.md            ✅ Completado
    ├── espocrm-setup.md                        ✅ COMPLETADO
    ├── redis-session-management.md             🆕 PENDIENTE
    └── environment-variable-management.md      ⏳ Pendiente
```

### 4.2 Zona: Comunicación

```
02-SKILLS/
└── COMUNICACION/
    ├── telegram-bot-integration.md            ✅ Completado
    ├── gmail-smtp-integration.md              ✅ Completado
    ├── whatsapp-uazapi-integration.md         ⏳ Pendiente
    ├── google-calendar-api-integration.md     ⏳ Pendiente
    ├── email-notification-patterns.md         ⏳ Pendiente
    ├── whatsApp-rag-openRouter                ⏳ Pendiente
    └──                                        ⏳ Pendiente
```

### 4.3 Zona: Datos y RAG

```
02-SKILLS/
└── BASE DE DATOS-RAG/
    ├── qdrant-rag-ingestion.md                 ✅ Completado
    ├── multi-tenant-data-isolation.md          ✅ Completado
    ├── rag-system-updates-all-engines.md       ✅ Completado
    ├── mysql-optimization-4gb-ram.md           ✅ Completado
    ├── pdf-mistralocr-processing.md            ✅ COMPLETADO              
    ├── postgres-prisma-rag.md                  ✅ Completado
    ├── supabase-rag-integration.md             ✅ Completado
    ├── mysql-sql-rag-ingestion.md              🆕 PENDIENTE
    ├── google-drive-qdrant-sync.md             ✅ COMPLETADO
    └── espocrm-api-analytics.md                ✅ Completado
```

### 4.4 Zona: AI

```
02-SKILLS/
└── AI/
    ├── openrouter-api-integration.md           ⏳ Pendiente
    ├── mistral-ocr-integration.md              ⏳ Pendiente
    ├── qwen-integration.md                    ⏳ Pendiente
    ├── llama-integration.md                   ⏳ Pendiente
    ├── gemini-integration.md                  ⏳ Pendiente
    ├── gpt-integration.md                     ⏳ Pendiente
    ├── deepseek-integration.md                ⏳ Pendiente
    ├── minimax-integration.md                 ⏳ Pendiente
    ├── voice-agent-integration.md             ⏳ Pendiente
    ├── image-gen-api.md                       ⏳ Pendiente
    └── video-gen-api.md                      ⏳ Pendiente
```

### 4.5 Zona: Business (Restaurantes, Hoteles, Odontología)

```
02-SKILLS/
└── BUSINESS/
    ├── restaurant-booking-system.md           ⏳ Pendiente
    ├── restaurant-order-management.md          ⏳ Pendiente
    ├── restaurant-delivery-management.md      ⏳ Pendiente
    ├── pos-integration.md                     ⏳ Pendiente
    ├── hotel-booking-system.md               ⏳ Pendiente
    ├── guest-journey-automation.md           ⏳ Pendiente
    ├── hotel-receptionist-agent.md            ⏳ Pendiente
    ├── competitor-rate-monitoring.md          ⏳ Pendiente
    ├── pre-arrival-communication.md           ⏳ Pendiente
    ├── dental-appointment-system.md          ⏳ Pendiente
    ├── patient-response-automation.md         ⏳ Pendiente
    ├── dental-voice-agent.md                 ⏳ Pendiente
    └── dental-admin-system.md                ⏳ Pendiente
```

### 4.6 Zona: Marketing

```
02-SKILLS/
└── MARKETING/
    ├── instagram-automation.md                 ⏳ Pendiente
    ├── instagram-reels-creation.md            ⏳ Pendiente
    ├── tiktok-integration.md                 ⏳ Pendiente
    ├── facebook-integration.md               ⏳ Pendiente
    ├── ai-content-generation.md               ⏳ Pendiente
    ├── image-generation-pipeline.md           ⏳ Pendiente
    └── video-generation-pipeline.md          ⏳ Pendiente
```

### 4.7 Zona: Media

```
02-SKILLS/
└── MEDIA/
    ├── cloudinary-integration.md             ⏳ Pendiente
    ├── video-processing.md                   ⏳ Pendiente
    └── image-optimization.md                 ⏳ Pendiente
```

### 4.8 Zona: Seguridad

```
02-SKILLS/
└── SEGURIDAD/
    ├── backup-encryption.md                    ✅ COMPLETADO  
    ├── rsync-automation.md                     ✅ COMPLETADO         
    ├── security-hardening-vps.md               ✅ COMPLETADO
    ├── 
    └── 
```

---

## 5. Matriz de Dependencias de Skills

Esta matriz muestra qué skills transversales son necesarios para cada zona de negocio:

| Zona de Negocio | WhatsApp | Telegram | Gmail | Google Calendar | Google Drive | Google Sheets | OpenRouter | Qdrant | MySQL | Supabase | Redis |
|-----------------|----------|----------|-------|-----------------|--------------|---------------|------------|--------|-------|----------|-------|
| **Infraestructura** | ⬜ | ✅ | ✅ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **RAG y Datos** | ✅ | ✅ | ⬜ | ⬜ | ✅ | ⬜ | ✅ | ✅ | ✅ | ✅ | ⬜ |
| **Restaurantes** | ✅ | ✅ | ✅ | ✅ | ⬜ | ✅ | ✅ | ⬜ | ⬜ | ✅ | ⬜ |
| **Hoteles** | ✅ | ⬜ | ✅ | ✅ | ⬜ | ✅ | ✅ | ⬜ | ⬜ | ⬜ | ✅ |
| **Odontología** | ⬜ | ⬜ | ✅ | ✅ | ⬜ | ✅ | ✅ | ⬜ | ⬜ | ✅ | ⬜ |
| **Marketing** | ✅ | ✅ | ⬜ | ⬜ | ✅ | ✅ | ✅ | ⬜ | ⬜ | ⬜ | ⬜ |

**Leyenda:**
- ✅ = Requerido
- ⬜ = No requerido

---

## 6. Skill Cards - Templates por Zona

### 6.1 Template: Skill de Comunicación

```markdown
## [SKILL-ID]: [Nombre del Skill]

> [Breve descripción del skill]

**Skill:** [SKILL-ID] | **Categoría:** COMUNICACION
**Última actualización:** YYYY-MM-DD
**Validación SDD:** Pending
**Refs:** [Referencias a otros documentos]

---

### 1. Propósito y Contexto
[Descripción del problema que resuelve y por qué es importante]

### 2. Arquitectura de Integración
[Diagrama de cómo se integra con el ecosistema]

### 3. Configuración
[Pasos detallados de configuración]

### 4. Uso en Workflows n8n
[Ejemplos de nodos y configuraciones]

### 5. Patrones Comunes
[Patrones reutilizables documentados]

### 6. Troubleshooting
[Problemas comunes y soluciones]

### 7. Checklist de Validación
[Lista de verificación para asegurar calidad]
```

### 6.2 Template: Skill de AI

```markdown
## [SKILL-ID]: [Nombre del Skill]

> [Breve descripción del skill]

**Skill:** [SKILL-ID] | **Categoría:** AI
**Última actualización:** YYYY-MM-DD
**Validación SDD:** Pending
**Refs:** [Referencias a otros documentos]

---

### 1. Propósito y Contexto
[Descripción del modelo/API y sus casos de uso]

### 2. Modelos Disponibles
[Lista de modelos soportados con características]

### 3. Límites y Cuotas
[Rate limits, costos, etc.]

### 4. Configuración de API
[Variables de entorno, autenticación]

### 5. Patrones de Uso en n8n
[Ejemplos de prompts, temperaturas, etc.]

### 6. Integración con RAG
[Cómo usar con Qdrant y vectorización]

### 7. Troubleshooting
[Problemas comunes y soluciones]
```

### 6.3 Template: Skill de Negocio

```markdown
## [SKILL-ID]: [Nombre del Skill]

> [Breve descripción del skill]

**Skill:** [SKILL-ID] | **Categoría:** BUSINESS
**Última actualización:** YYYY-MM-DD
**Validación SDD:** Pending
**Refs:** [Referencias a otros documentos]

---

### 1. Propósito y Contexto
[Descripción del proceso de negocio]

### 2. Flujo de Proceso
[Diagrama del flujo de trabajo]

### 3. Agentes que lo Usan
[Lista de agentes mencionados en este documento]

### 4. Skills Dependientes
[Lista de skills transversales requeridos]

### 5. Workflow n8n Recomendado
[Ejemplo de workflow completo]

### 6. Casos de Uso
[Ejemplos específicos por tipo de cliente]

### 7. Mejores Prácticas
[Recommendations basadas en producción]

### 8. Checklist de Validación
[Lista de verificación]
```

---

## 7. Roadmap de Skills Pendientes

### Prioridad Alta (Skills transversales bloqueantes)

| Skill | Dependencias Bloqueadas | Estimado |
|-------|-------------------------|----------|
| WhatsApp uazapi Integration | 8 agentes RAG y negocio | 2 días |
| Google Sheets Integration | 12 agentes negocio | 1 día |
| Google Calendar Integration | 6 agentes odontología/hotel | 1 día |
| OpenRouter API Integration | 15+ agentes con IA | 2 días |
| Qdrant RAG Ingestion | 7 agentes RAG | 3 días |

### Prioridad Media (Skills de negocio)

| Skill | Agentes Impactados | Estimado |
|-------|-------------------|----------|
| Restaurant Booking System | 6 agentes restaurantes | 2 días |
| Hotel Booking System | 3 agentes hoteles | 2 días |
| Dental Appointment System | 4 agentes odontología | 2 días |
| Instagram Automation | 5 agentes marketing | 2 días |

### Prioridad Baja (Skills de optimización)

| Skill | Beneficio | Estimado |
|-------|-----------|----------|
| Competitor Rate Monitoring | 1 agente hoteles | 1 día |
| Video Generation Pipeline | 1 agente marketing | 2 días |
| Voice Agent Integration | 2 agentes (dental, restaurant) | 3 días |

---

## 8. Referencias

- **00-CONTEXT/PROJECT_OVERVIEW.md:** Vista general del proyecto
- **01-RULES/08-SKILLS-REFERENCE.md:** Referencia de skills
- **02-RULES/ARCHITECTURE-RULES.md:** Reglas de arquitectura
- **02-RULES/MULTITENANCY-RULES.md:** Aislamiento multi-tenant

---

**Autor:** MiniMax Agent
**Fecha creación:** 2026-04-10
**Última validación:** Pending SDD Compliance
**Versión:** 1.0.0
