---
canonical_path: "/02-SKILLS/README.md"
artifact_id: "skills-readme-canonical"
artifact_type: "governance_readme"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C5", "C6"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 02-SKILLS/README.md --mode headless --json"
tier: 1
immutable: true
requires_human_approval_for_changes: true
related_files:
  - "[[02-SKILLS/00-INDEX.md]]"
  - "[[02-SKILLS/skill-domains-mapping.md]]"
  - "[[02-SKILLS/GENERATION-MODELS.md]]"
  - "[[01-RULES/08-SKILLS-REFERENCE.md]]"
  - "[[PROJECT_TREE.md]]"
checksum_sha256: "PENDING_GENERATION"
---

# 📄 02-SKILLS/README.md – REGENERADO COMPLETO v3.0-SELECTIVE

> **Nota para principiantes:** Este documento es la **puerta de entrada** a la sección `02-SKILLS/` en MANTIS AGENTIC. Explica QUÉ son las skills, CÓMO navegar por el árbol estructural canónico, y CÓMO validar que una skill está lista para uso en producción. Si eres nuevo, lee en orden. Si eres experto, salta al JSON final.  
>  
> **Para IAs:** Este es tu mapa de bienvenida. **RECOMENDAR SKILL NO INDEXADA O SIN VALIDACIÓN = RIESGO DE INCONSISTENCIA**. No inventes, no asumas, no omitas.


# 🧠 02-SKILLS/README: Puerta de Entrada al Catálogo de Habilidades MANTIS

<!-- 
【PARA PRINCIPIANTES】¿Qué es este archivo?
Este documento es la "bienvenida" a la sección 02-SKILLS/ en MANTIS AGENTIC.
Te enseña:
• QUÉ son las skills y por qué importan
• CÓMO navegar por el mapa estructural canónico (ASCII tree)
• CÓMO validar que una skill está lista para uso en producción
• DÓNDE encontrar ayuda si tienes dudas

Si eres nuevo: lee en orden. 
Si ya conoces el proyecto: usa los wikilinks para ir directo a lo que necesitas.
-->

> **Instrucción crítica para la IA:** 
> Este documento es tu mapa de bienvenida. 
> **RECOMENDAR SKILL NO INDEXADA O SIN VALIDACIÓN = RIESGO DE INCONSISTENCIA**. 
> No inventes, no asumas, no omitas. Si algo no está claro, DETENER y preguntar.

---

## 【0】🎯 BIENVENIDA A 02-SKILLS/ (Explicado para humanos)

<!-- 
【EDUCATIVO】Este documento responde: "¿Dónde encuentro skills para resolver mi problema?"
No es un manual técnico. Es una guía de navegación que:
• Presenta la arquitectura de skills en MANTIS AGENTIC
• Conecta necesidades de negocio con soluciones técnicas validadas
• Proporciona flujos de descubrimiento: necesidad → skill → validación → integración
• Sirve como punto de entrada para agents remotos que consumen `RAW_URLS_INDEX.md`
-->

### 0.1 ¿Qué es una Skill en MANTIS AGENTIC?

```
【DEFINICIÓN】
Una skill es un patrón reutilizable que resuelve una necesidad específica de dominio.
Puede ser:
• Horizontal: Técnica, reutilizable en cualquier industria (ej: `qwen-integration.md`)
• Vertical: Empaquetada para un negocio específico (ej: `restaurant-booking-ai.md`)

【CARACTERÍSTICAS CANÓNICAS】
• Frontmatter válido con `canonical_path`, `constraints_mapped`, `validation_command`
• Estructura SDD: Propósito → Implementación → Ejemplos → Validación → Referencias
• ≥10 ejemplos ✅/❌/🔧 para Tier ≥ 2
• Wikilinks canónicos: `[[RUTA/DESDE/RAÍZ.md]]`, nunca relativos
• JSON tree final parseable por `jq` para agents remotos

【ESTADO DE UNA SKILL】
| Estado | Significado | ¿Listo para producción? |
|--------|------------|------------------------|
| ✅ Listo | Validada con score >= umbral y blocking_issues == [] | Sí |
| 🟡 En proceso | Validación pendiente o warnings menores | No, requiere revisión humana |
| 🔧 Estructura lista | Carpeta con estructura base (.gitkeep) lista para poblar | No, falta contenido |
| 🆕 Nuevo | Skill recién añadida, sin validación inicial | No, requiere validación completa |
```

---

## 🗺️ MAPA ESTRUCTURAL CANÓNICO (ASCII TREE)

<!-- 
【PARA PRINCIPIANTES】Este es el mapa visual de toda la sección 02-SKILLS/.
Usa este árbol para navegar: cada rama es un dominio, cada hoja es una skill.
Los emojis indican tipo: 🤖 IA, 🗄️ DB/RAG, 🖥️ Infra, 🔐 Seguridad, 📡 Comunicación, 🚀 Deploy, 🏢 KB, 🎯 Vertical.
-->

```text
02-SKILLS/
├── README.md                          # 📄 ESTE ARCHIVO: Guía maestra de navegación y validación
├── skill-domains-mapping.md           # 🔗 Mapeo concepto→ruta física canónica para IAs
│
├── AI/                                # 🤖 Integración de modelos de IA (OpenRouter + directos)
│   ├── deepseek-integration.md        # reasoning_content, rate-limit, fallback coder, coste optimizado
│   ├── gemini-integration.md          # multimodal, function calling, safety settings, streaming
│   ├── gpt-integration.md             # function calling, JSON mode, structured outputs, retry wrapper
│   ├── image-gen-api.md               # generación + edición, webhook callback, tenant_id en metadata
│   ├── llama-integration.md           # open-weight, quantization-aware, fallback local (C6 exception)
│   ├── minimax-integration.md         # contexto 1M, procesamiento iterativo, resumen jerárquico
│   ├── mistral-ocr-integration.md     # PDF→texto estructurado, bounding boxes, tenant isolation
│   ├── openrouter-api-integration.md  # proxy unificado, routing dinámico, coste/latencia balancing
│   ├── qwen-integration.md            # contexto 131K, JSON mode, cache semántica, fallback 32B
│   ├── video-gen-api.md               # generación por prompts, progress polling, storage tenant-scoped
│   └── voice-agent-integration.md     # STT/TST streaming, wake-word, tenant_id en audio chunks
│
├── BASE DE DATOS-RAG/                 # 🗄️ Patrones de ingestión, consulta y aislamiento multi-tenant
│   ├── qdrant-rag-ingestion.md        # search, scroll, recommend, delete, count, updateVectors
│   ├── postgres-prisma-rag.md         # transacciones, pool limitado, full-text, JSONB, RLS
│   ├── multi-tenant-data-isolation.md # estrategias de aislamiento: schema-per-tenant vs row-level
│   ├── pdf-mistralocr-processing.md   # pipeline OCR → chunking → embedding → Qdrant
│   ├── google-drive-qdrant-sync.md    # webhook + polling para sync bidireccional
│   ├── espocrm-api-analytics.md       # extracción de métricas comerciales para RAG contextual
│   ├── mysql-optimization-4gb-ram.md  # tuning para VPS con ≤4GB RAM (C1)
│   ├── rag-system-updates-all-engines.md # estrategia de actualización incremental por motor
│   ├── mysql-sql-rag-ingestion.md     # ingestión directa desde MySQL con filtros tenant_id
│   ├── redis-session-management.md    # caché de sesiones con TTL y aislamiento por tenant
│   ├── environment-variable-management.md # gestión segura de .env con validación de tipos
│   ├── google-sheets-as-database.md   # Sheets como fuente RAG con paginación y rate-limit
│   └── airtable-database-patterns.md  # listar, paginación, webhook simulado, caché Redis
│
├── INFRAESTRUCTURA/                   # 🖥️ VPS, Docker, redes, monitoreo, límites de recursos
│   ├── docker-compose-networking.md   # redes aisladas por tenant, healthchecks, restart policies
│   ├── espocrm-setup.md               # instalación segura con variables aisladas
│   ├── fail2ban-configuration.md      # protección contra brute-force con logs estructurados
│   ├── ssh-tunnels-remote-services.md # acceso seguro a DBs sin exposición pública (C3)
│   ├── ssh-key-management.md          # rotación de claves, almacenamiento seguro, auditoría
│   ├── ufw-firewall-configuration.md  # reglas mínimas necesarias, logging de denegados
│   ├── vps-interconnection.md         # comunicación segura entre VPS con WireGuard/túneles
│   ├── n8n-concurrency-limiting.md    # control de concurrencia en workflows para C1/C2
│   └── health-monitoring-vps.md       # métricas básicas: RAM, CPU, disco, con alertas
│
├── SEGURIDAD/                         # 🔐 Hardening, backups, auditoría, cumplimiento
│   ├── backup-encryption.md           # cifrado con age + checksum SHA256 (C5)
│   ├── rsync-automation.md            # sync incremental con verificación de integridad
│   └── security-hardening-vps.md      # checklist de hardening: usuarios, permisos, logs
│
├── COMUNICACIÓN/                      # 📡 Integración con canales: WhatsApp, Telegram, Email
│   ├── telegram-bot-integration.md    # webhook seguro, polling fallback, tenant_id en payloads
│   ├── gmail-smtp-integration.md      # envío de emails con rate-limit y logging estructurado
│   ├── google-calendar-api-integration.md # sync de eventos con aislamiento por tenant
│   └── whatsapp-rag-openrouter.md     # 🎯 ARCHIVO CRÍTICO: proxy OpenRouter + RAG + multi-modelo
│
├── DEPLOYMENT/                        # 🚀 Estrategias de despliegue, rollback, versionado
│   ├── ci-cd-github-actions.md        # pipelines con validación SDD pre-merge
│   ├── docker-registry-management.md  # tagging semántico, cleanup de imágenes antiguas
│   └── rollout-strategies.md          # blue/green, canary, feature flags por tenant
│
├── CORPORATE-KB/                      # 🏢 Knowledge Base empresarial multi-tenant
│   ├── onboarding-template.md         # plantilla para ingestión de nueva empresa
│   ├── vertical-restaurante.md        # schema específico: menú, reservas, reseñas
│   ├── vertical-hotel-posada.md       # schema: habitaciones, disponibilidad, precios
│   └── vertical-odontologia.md        # schema: pacientes, turnos, historias clínicas
│
├── RESTAURANTES/                      # 🎯 Implementaciones por industria
│   ├── prompts/                       # prompts específicos del dominio
│   ├── workflows/                     # flujos n8n exportados
│   └── validation/                    # tests específicos del vertical
├── HOTELES-POSADAS/                   # 🎯 Implementaciones por industria
│   ├── prompts/                       # prompts específicos del dominio
│   ├── workflows/                     # flujos n8n exportados
│   └── validation/                    # tests específicos del vertical
├── ODONTOLOGÍA/                       # 🎯 Implementaciones por industria
│   ├── prompts/                       # prompts específicos del dominio
│   ├── workflows/                     # flujos n8n exportados
│   └── validation/                    # tests específicos del vertical
└── INSTAGRAM-SOCIAL-MEDIA/            # 🎯 Implementaciones por industria
    ├── prompts/                       # prompts específicos del dominio
    ├── workflows/                     # flujos n8n exportados
    └── validation/                    # tests específicos del vertical
```

> 💡 **Consejo para principiantes**: Usa este mapa ASCII como brújula. Cada rama es un dominio, cada hoja es una skill. Si buscas "WhatsApp + RAG", ve a `COMUNICACIÓN/whatsapp-rag-openrouter.md`. Si necesitas "aislar datos por cliente", ve a `BASE DE DATOS-RAG/multi-tenant-data-isolation.md`.

---

## 【1】🧭 CÓMO NAVEGAR POR 02-SKILLS/

<!-- 
【EDUCATIVO】Flujos de descubrimiento para encontrar la skill correcta.
-->

### 1.1 Flujo: Necesidad de Negocio → Skill Técnica

```
┌─────────────────────────────────────────────────────────┐
│ 【PASO 1】IDENTIFICAR NECESIDAD DE NEGOCIO             │
├─────────────────────────────────────────────────────────┤
│ Ejemplos:                                               │
│ • "Quiero agente de reservas por WhatsApp"              │
│ • "Necesito gestión de pacientes con privacidad"        │
│ • "Quiero generar contenido para Instagram con IA"      │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【PASO 2】CONSULTAR MAPA ASCII + SKILL-DOMAINS-MAPPING │
├─────────────────────────────────────────────────────────┤
│ 1. Usar mapa ASCII arriba para ubicar dominio          │
│ 2. Ir a: [[02-SKILLS/skill-domains-mapping.md]]        │
│ 3. Buscar necesidad → identificar skills horizontales  │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【PASO 3】VALIDAR SKILLS REQUERIDAS                    │
├─────────────────────────────────────────────────────────┤
│ Para cada skill identificada:                          │
│ • Verificar estado en [[02-SKILLS/00-INDEX.md]]        │
│ • Ejecutar: orchestrator-engine.sh --file <skill> --json│
│ • Confirmar: score >= umbral, blocking_issues == []    │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【PASO 4】INTEGRAR O ITERAR                            │
├─────────────────────────────────────────────────────────┤
│ Si validación pasa → integrar skill en tu flujo        │
│ Si validación falla → iterar corrección (máx 3 intentos)│
│ Registrar log de auditoría con tenant_id y trace_id    │
└─────────────────────────────────────────────────────────┘
```

### 1.2 Flujo: Desarrollo Técnico → Skill Horizontal

```
┌─────────────────────────────────────────────────────────┐
│ 【PASO 1】IDENTIFICAR TAREA TÉCNICA                    │
├─────────────────────────────────────────────────────────┤
│ Ejemplos:                                               │
│ • "Necesito integrar Qwen para generación de código"    │
│ • "Quiero conectar Qdrant para búsqueda vectorial"      │
│ • "Necesito validar secrets en mi código"               │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【PASO 2】USAR MAPA ASCII PARA UBICAR DOMINIO          │
├─────────────────────────────────────────────────────────┤
│ • Código/IA → Rama `AI/` en mapa ASCII                 │
│ • DB/RAG → Rama `BASE DE DATOS-RAG/`                   │
│ • Infra → Rama `INFRAESTRUCTURA/`                      │
│ • Comunicación → Rama `COMUNICACIÓN/`                  │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【PASO 3】VALIDAR Y USAR SKILL                         │
├─────────────────────────────────────────────────────────┤
│ • Verificar constraints_mapped en frontmatter          │
│ • Ejecutar validation_command de la skill              │
│ • Confirmar que cumple LANGUAGE LOCK si genera código  │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【PASO 4】ADAPTAR A TU CONTEXTO                        │
├─────────────────────────────────────────────────────────┤
│ • Copiar skill a tu proyecto                           │
│ • Adaptar tenant_id, secrets, timeouts según contexto  │
│ • Validar adaptación con orchestrator-engine.sh        │
└─────────────────────────────────────────────────────────┘
```

---

## 【2】📚 DOMINIOS HORIZONTALES (Cimientos Técnicos)

<!-- 
【EDUCATIVO】Skills reutilizables en cualquier industria. Referencia rápida desde mapa ASCII.
-->

### 2.1 `AI/` – Modelos de Inteligencia Artificial 🤖

```
【PROPÓSITO】Catálogo de proveedores de IA, sus límites de coste, estrategias de fallback y modos de integración.

【SKILLS DESTACADAS (desde mapa ASCII)】
• `[[02-SKILLS/AI/qwen-integration.md]]` → Contexto 131K, JSON mode, cache semántica, fallback 32B
• `[[02-SKILLS/AI/deepseek-integration.md]]` → Reasoning_content, rate-limit, fallback coder
• `[[02-SKILLS/AI/openrouter-api-integration.md]]` → Proxy unificado, routing dinámico, balancing coste/latencia

【CUÁNDO USAR】
• "Necesito un agente conversacional barato" → qwen-integration.md
• "Necesito razonamiento complejo" → deepseek-integration.md + fallback a qwen
• "Quiero balancear coste/rendimiento" → openrouter-api-integration.md

【CONSTRAINTS CRÍTICAS】
• **C3 (Zero Secrets)**: API keys NUNCA en código. Usar variables de entorno.
• **C4 (Tenant Isolation)**: Aislamiento de prompts y respuestas por tenant_id.
• **C8 (Observability)**: Logging estructurado de costes, latencia y errores.
```

### 2.2 `BASE DE DATOS-RAG/` – Información y Búsqueda Semántica 🗄️

```
【PROPÓSITO】Gestión de información estructurada y no estructurada. Incluye RAG, aislamiento multi-tenant, optimización para servidores pequeños.

【SKILLS DESTACADAS (desde mapa ASCII)】
• `[[02-SKILLS/BASE DE DATOS-RAG/qdrant-rag-ingestion.md]]` → search, scroll, recommend, delete, count, updateVectors
• `[[02-SKILLS/BASE DE DATOS-RAG/multi-tenant-data-isolation.md]]` → Estrategias: schema-per-tenant vs row-level
• `[[02-SKILLS/BASE DE DATOS-RAG/postgres-prisma-rag.md]]` → Transacciones, pool limitado, full-text, JSONB, RLS

【CUÁNDO USAR】
• "Necesito RAG para documentos PDF" → pdf-mistralocr-processing.md + qdrant-rag-ingestion.md
• "Quiero sincronizar Google Drive con mi vector DB" → google-drive-qdrant-sync.md
• "Necesito aislar datos de múltiples clientes" → multi-tenant-data-isolation.md

【CONSTRAINTS CRÍTICAS】
• **C4 (Tenant Isolation)**: TODO acceso a datos debe incluir `WHERE tenant_id = $1`.
• **V1 (Vector Dimensions)**: Declarar dimensiones del embedding y modelo en queries vectoriales.
• **C3 (Zero Secrets)**: Credenciales de DB NUNCA en código.
```

### 2.3 `INFRAESTRUCTURA/` – Servidores, Redes y Contenedores 🖥️

```
【PROPÓSITO】Configuración y mantenimiento de servidores VPS, redes, contenedores y monitoreo.

【SKILLS DESTACADAS (desde mapa ASCII)】
• `[[02-SKILLS/INFRAESTRUCTURA/vps-interconnection.md]]` → Comunicación segura entre VPS con WireGuard/túneles
• `[[02-SKILLS/INFRAESTRUCTURA/docker-compose-networking.md]]` → Redes aisladas por tenant, healthchecks
• `[[02-SKILLS/INFRAESTRUCTURA/health-monitoring-vps.md]]` → Métricas básicas: RAM, CPU, disco, con alertas

【CUÁNDO USAR】
• "Necesito conectar 3 VPS de forma segura" → vps-interconnection.md + ssh-tunnels-remote-services.md
• "Quiero monitorear mis servidores" → health-monitoring-vps.md + fail2ban-configuration.md
• "Necesito gestionar sesiones de agentes" → redis-session-management.md

【CONSTRAINTS CRÍTICAS】
• **C1 (Resource Limits)**: Definir límites de CPU/RAM por contenedor.
• **C3 (Zero Secrets)**: Credenciales SSH, API keys NUNCA hardcodeadas.
• **C7 (Resilience)**: Healthchecks y graceful shutdown para todos los servicios.
```

---

## 【3】🏢 DOMINIOS VERTICALES (Soluciones por Industria)

<!-- 
【EDUCATIVO】Skills empaquetadas para negocios específicos. Se construyen sobre skills horizontales.
-->

> 📌 **Nota**: Estas carpetas contienen la estructura base (`prompts/`, `workflows/`, `validation/`) lista para ser poblada. Evita duplicar lógica horizontal; importa las skills técnicas y adapta solo los flujos de negocio.

### 3.1 `RESTAURANTES/` – Pedidos, Reservas y Menús 🎯

```
【PROPÓSITO】Gestión de pedidos, reservas, menús dinámicos y fidelización mediante asistentes conversacionales.

【ESTRUCTURA (desde mapa ASCII)】
├── prompts/                       # Prompts específicos del dominio
├── workflows/                     # Flujos n8n exportados
└── validation/                    # Tests específicos del vertical

【FLUJO RECOMENDADO】
1. Consultar mapa ASCII → Rama `RESTAURANTES/`
2. Importar skills horizontales: whatsapp-rag-openrouter.md, postgres-prisma-rag.md
3. Adaptar prompts y workflows a flujos de restaurante
4. Validar con orchestrator-engine.sh antes de desplegar

【CONSTRAINTS CRÍTICAS】
• **C3 (Zero Secrets)**: API keys de WhatsApp, POS y proveedores de IA protegidas.
• **C4 (Tenant Isolation)**: Datos de pedidos y clientes separados por restaurante.
• **C7 (Resilience)**: Fallback a pedido manual si el chatbot falla o el POS se cae.
```

### 3.2 `ODONTOLOGÍA/` – Citas, Pacientes y Privacidad 🎯

```
【PROPÓSITO】Gestión de agendas médicas, recordatorios automáticos y cumplimiento de privacidad de datos del paciente.

【ESTRUCTURA (desde mapa ASCII)】
├── prompts/                       # Prompts específicos del dominio
├── workflows/                     # Flujos n8n exportados
└── validation/                    # Tests específicos del vertical

【FLUJO RECOMENDADO】
1. Consultar mapa ASCII → Rama `ODONTOLOGÍA/`
2. Importar skills horizontales: google-calendar-api-integration.md, multi-tenant-data-isolation.md
3. Adaptar prompts a flujos clínicos y normativas de privacidad
4. Validar con auditoría de seguridad antes de usar con datos reales

【CONSTRAINTS CRÍTICAS】
• **C4 (Tenant Isolation - CRÍTICO)**: Los datos de salud son sensibles. Aislamiento estricto obligatorio.
• **C8 (Observability)**: Auditoría de quién accedió a los datos de qué paciente (logs con scrubbing).
• **C3 (Zero Secrets)**: Credenciales de calendario, DB y email altamente protegidas.
```

---

## 【4】🛠️ CÓMO VALIDAR UNA SKILL

<!-- 
【EDUCATIVO】Pasos para asegurar que una skill está lista para uso en producción.
-->

### 4.1 Checklist Rápido de Validación

```bash
# 1. Verificar frontmatter válido
yq eval '.canonical_path' skill.md | grep -q "^/" && echo "✅ canonical_path absoluto"

# 2. Verificar constraints mapeadas
yq eval '.constraints_mapped' skill.md | grep -q "C3\|C4\|C5" && echo "✅ Constraints declaradas"

# 3. Ejecutar validación automática
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file skill.md --json > result.json

# 4. Verificar resultado
jq -e '.passed == true and .blocking_issues == []' result.json && echo "✅ Skill validada" || echo "❌ Skill requiere corrección"

# 5. Verificar LANGUAGE LOCK si genera código
bash 05-CONFIGURATIONS/validation/verify-constraints.sh --file skill.md --check-language-lock --json
```

### 4.2 Interpretación de Resultados

| Campo en JSON | Significado | Acción Recomendada |
|--------------|------------|-------------------|
| `score` | Puntuación de calidad (0-100) | Tier 1: ≥15, Tier 2: ≥30, Tier 3: ≥45 |
| `passed` | ¿La skill pasó validación? | Si `false`, revisar `blocking_issues` |
| `blocking_issues` | Errores que impiden entrega | Corregir antes de integrar |
| `warnings` | Advertencias no blocking | Considerar para mejora continua |
| `language_lock_violations` | Operadores prohibidos usados | Mover a dominio canónico o corregir |

---

## 【5】🆘 CÓMO OBTENER AYUDA

<!-- 
【EDUCATIVO】Recursos para resolver dudas sobre skills.
-->

### 5.1 Recursos Internos

```
• [[02-SKILLS/00-INDEX.md]] → Índice maestro con estado de todas las skills
• [[02-SKILLS/skill-domains-mapping.md]] → Mapeo de necesidades de negocio a skills técnicas
• [[02-SKILLS/GENERATION-MODELS.md]] → Catálogo de modelos de IA para generación asistida
• [[01-RULES/08-SKILLS-REFERENCE.md]] → Catálogo de habilidades por dominio
• [[01-RULES/validation-checklist.md]] → Checklist ejecutable de validación
```

### 5.2 Herramientas de Validación

```
• `orchestrator-engine.sh` → Validación integral con scoring y reporte JSON
• `verify-constraints.sh` → Validación de constraints y LANGUAGE LOCK
• `audit-secrets.sh` → Detección de secrets hardcodeados (C3)
• `check-rls.sh` → Validación de aislamiento multi-tenant en SQL (C4)
```

### 5.3 Soporte Humano

```
• Crear issue en GitHub con etiqueta `skill-question`
• Incluir: canonical_path de la skill, error específico, pasos para reproducir
• Consultar `[[GOVERNANCE-ORCHESTRATOR.md]]` para proceso de aprobación de cambios
```

---

## 【6】📦 METADATOS DE EXPANSIÓN (PARA FUTURAS VERSIONES)

<!-- 
【PARA MANTENEDORES】Nuevas secciones deben seguir este formato para no romper compatibilidad.
-->

```json
{
  "expansion_registry": {
    "new_horizontal_domain": {
      "requires_files_update": [
        "02-SKILLS/README.md: add domain entry to mapa ASCII + sección correspondiente con propósito, skills destacadas, cuándo usar, constraints",
        "02-SKILLS/<new-domain>/: create folder with 00-INDEX.md and initial skills",
        "02-SKILLS/00-INDEX.md: add domain to horizontal_skills_catalog",
        "01-RULES/08-SKILLS-REFERENCE.md: add domain to domain_catalog",
        "Human approval required: true"
      ],
      "backward_compatibility": "new domains must not break existing navigation or validation flows; must declare constraints applicability clearly"
    },
    "new_vertical_industry": {
      "requires_files_update": [
        "02-SKILLS/README.md: add industry entry to mapa ASCII + sección correspondiente con propósito, estructura, flujo recomendado, constraints",
        "02-SKILLS/<industry>/: create folder with prompts/, workflows/, validation/ subfolders",
        "02-SKILLS/skill-domains-mapping.md: add industry to business-to-skills mapping",
        "Human approval required: true"
      ],
      "backward_compatibility": "new industries must import horizontal skills rather than duplicating logic; must follow SDD format for new prompts/workflows"
    }
  },
  "compatibility_rule": "Nuevas entradas en el README no deben invalidar wikilinks existentes o flujos de navegación. Cambios breaking requieren major version bump, guía de migración y aprobación humana explícita."
}
```

---

<!-- 
═══════════════════════════════════════════════════════════
🤖 SECCIÓN PARA IA: ÁRBOL JSON ENRIQUECIDO
═══════════════════════════════════════════════════════════
Esta sección contiene metadatos estructurados para consumo automático por agentes de IA.
No está diseñada para lectura humana directa. Los humanos deben usar las secciones 【1】-【6】.

Formato: JSON válido, con comentarios explicativos en claves "doc_*".
Prioridad de ejecución: Los dominios se consultan en orden: horizontales → verticales.
Dependencias: Cada nodo declara sus archivos requeridos y sus efectos colaterales.
═══════════════════════════════════════════════════════════
-->

```json
{
  "skills_readme_metadata": {
    "version": "3.0.0-SELECTIVE",
    "canonical_path": "/02-SKILLS/README.md",
    "artifact_type": "governance_readme",
    "immutable": true,
    "requires_human_approval_for_changes": true,
    "constraints_primary": ["C5", "C6"],
    "total_horizontal_domains": 6,
    "total_vertical_domains": 4,
    "ascii_map_included": true,
    "llm_optimizations": {
      "oriental_models_friendly": true,
      "delimiters_used": ["【】", "┌─┐", "▼", "✅/❌/🔧"],
      "numbered_sequences": true,
      "stop_conditions_explicit": true
    }
  },
  
  "ascii_map_reference": {
    "description": "Mapa estructural canónico en formato ASCII para navegación visual",
    "root": "02-SKILLS/",
    "horizontal_domains": ["AI/", "BASE DE DATOS-RAG/", "INFRAESTRUCTURA/", "SEGURIDAD/", "COMUNICACIÓN/", "DEPLOYMENT/"],
    "vertical_domains": ["RESTAURANTES/", "HOTELES-POSADAS/", "ODONTOLOGÍA/", "INSTAGRAM-SOCIAL-MEDIA/"],
    "corporate_kb": ["CORPORATE-KB/"],
    "entry_files": ["README.md", "skill-domains-mapping.md"]
  },
  
  "navigation_flows": {
    "business_need_to_skill": {
      "description": "Flujo para descubrir skills desde necesidad de negocio",
      "steps": [
        "Identificar necesidad de negocio",
        "Consultar mapa ASCII + skill-domains-mapping.md",
        "Validar skills requeridas con orchestrator-engine.sh",
        "Integrar o iterar corrección"
      ],
      "entry_point": "[[02-SKILLS/skill-domains-mapping.md]]"
    },
    "technical_task_to_skill": {
      "description": "Flujo para descubrir skills desde tarea técnica",
      "steps": [
        "Identificar tarea técnica",
        "Usar mapa ASCII para ubicar dominio horizontal",
        "Validar y usar skill específica",
        "Adaptar a contexto propio"
      ],
      "entry_point": "Mapa ASCII en este README"
    }
  },
  
  "horizontal_domains_summary": {
    "ai_llms": {
      "path": "02-SKILLS/AI/",
      "description": "Catálogo de proveedores de IA, límites de coste, estrategias de fallback",
      "featured_skills": ["qwen-integration.md", "deepseek-integration.md", "openrouter-api-integration.md"],
      "critical_constraints": ["C3", "C4", "C8"],
      "wikilink": "[[02-SKILLS/AI/]]"
    },
    "base_de_datos_rag": {
      "path": "02-SKILLS/BASE DE DATOS-RAG/",
      "description": "Gestión de información estructurada y no estructurada, RAG, aislamiento multi-tenant",
      "featured_skills": ["qdrant-rag-ingestion.md", "multi-tenant-data-isolation.md", "postgres-prisma-rag.md"],
      "critical_constraints": ["C3", "C4", "V1"],
      "wikilink": "[[02-SKILLS/BASE DE DATOS-RAG/]]"
    },
    "infraestructura": {
      "path": "02-SKILLS/INFRAESTRUCTURA/",
      "description": "Configuración y mantenimiento de servidores VPS, redes, contenedores",
      "featured_skills": ["vps-interconnection.md", "docker-compose-networking.md", "health-monitoring-vps.md"],
      "critical_constraints": ["C1", "C3", "C7"],
      "wikilink": "[[02-SKILLS/INFRAESTRUCTURA/]]"
    }
  },
  
  "vertical_domains_summary": {
    "restaurantes": {
      "path": "02-SKILLS/RESTAURANTES/",
      "description": "Gestión de pedidos, reservas, menús dinámicos y fidelización",
      "structure": ["prompts/", "workflows/", "validation/"],
      "critical_constraints": ["C3", "C4", "C7"],
      "wikilink": "[[02-SKILLS/RESTAURANTES/]]"
    },
    "odontologia": {
      "path": "02-SKILLS/ODONTOLOGÍA/",
      "description": "Gestión de agendas médicas, recordatorios y cumplimiento de privacidad",
      "structure": ["prompts/", "workflows/", "validation/"],
      "critical_constraints": ["C4", "C8"],
      "wikilink": "[[02-SKILLS/ODONTOLOGÍA/]]"
    }
  },
  
  "validation_quickstart": {
    "commands": [
      "yq eval '.canonical_path' skill.md | grep -q \"^/\" && echo \"✅ canonical_path absoluto\"",
      "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file skill.md --json > result.json",
      "jq -e '.passed == true and .blocking_issues == []' result.json && echo \"✅ Skill validada\""
    ],
    "result_interpretation": {
      "score": "Puntuación de calidad (0-100). Tier 1: ≥15, Tier 2: ≥30, Tier 3: ≥45",
      "passed": "¿La skill pasó validación? Si false, revisar blocking_issues",
      "blocking_issues": "Errores que impiden entrega. Corregir antes de integrar",
      "language_lock_violations": "Operadores prohibidos usados. Mover a dominio canónico o corregir"
    }
  },
  
  "help_resources": {
    "internal_docs": [
      "[[02-SKILLS/00-INDEX.md]] → Índice maestro con estado de todas las skills",
      "[[02-SKILLS/skill-domains-mapping.md]] → Mapeo de necesidades de negocio a skills técnicas",
      "[[02-SKILLS/GENERATION-MODELS.md]] → Catálogo de modelos de IA para generación asistida",
      "[[01-RULES/08-SKILLS-REFERENCE.md]] → Catálogo de habilidades por dominio",
      "[[01-RULES/validation-checklist.md]] → Checklist ejecutable de validación"
    ],
    "validation_tools": [
      "orchestrator-engine.sh → Validación integral con scoring y reporte JSON",
      "verify-constraints.sh → Validación de constraints y LANGUAGE LOCK",
      "audit-secrets.sh → Detección de secrets hardcodeados (C3)",
      "check-rls.sh → Validación de aislamiento multi-tenant en SQL (C4)"
    ],
    "human_support": "Crear issue en GitHub con etiqueta `skill-question`. Incluir: canonical_path, error específico, pasos para reproducir"
  },
  
  "dependency_graph": {
    "critical_infrastructure": [
      {"file": "02-SKILLS/00-INDEX.md", "purpose": "Índice maestro de skills con estado global", "load_order": 1},
      {"file": "02-SKILLS/skill-domains-mapping.md", "purpose": "Mapeo de necesidades de negocio a skills técnicas", "load_order": 2},
      {"file": "01-RULES/08-SKILLS-REFERENCE.md", "purpose": "Catálogo de habilidades por dominio", "load_order": 3},
      {"file": "05-CONFIGURATIONS/validation/norms-matrix.json", "purpose": "Mapeo de constraints por carpeta", "load_order": 4}
    ],
    "validation_toolchain": [
      {"file": "05-CONFIGURATIONS/validation/orchestrator-engine.sh", "purpose": "Motor principal de validación", "load_order": 1},
      {"file": "05-CONFIGURATIONS/validation/verify-constraints.sh", "purpose": "Validación de constraints y LANGUAGE LOCK", "load_order": 2},
      {"file": "05-CONFIGURATIONS/validation/audit-secrets.sh", "purpose": "Detección de secrets hardcodeados", "load_order": 3}
    ]
  },
  
  "human_readable_errors": {
    "skill_not_found": "Skill '{skill_name}' no encontrada en 02-SKILLS/. Consultar mapa ASCII o [[02-SKILLS/00-INDEX.md]] para skills disponibles.",
    "wikilink_not_canonical": "Wikilink '{wikilink}' no es canónico. Usar forma absoluta: [[RUTA-DESDE-RAÍZ]].",
    "constraint_not_applicable": "Constraint '{constraint}' no aplicable para skill '{skill}'. Consulte [[norms-matrix.json]] para mapeo por carpeta.",
    "validation_failed": "Validación de '{skill}' falló: {error_details}. Consulte [[01-RULES/validation-checklist.md]] para ítems específicos a corregir.",
    "language_lock_violation": "Violación de LANGUAGE LOCK: operador '{operator}' prohibido en skill '{skill}'. Consulte [[01-RULES/language-lock-protocol.md]].",
    "status_mismatch": "Estado de skill '{skill}' marcado como ✅ Listo pero validación no pasa. Ejecutar validation_command para verificar."
  },
  
  "expansion_hooks": {
    "new_horizontal_domain": {
      "requires_files_update": [
        "02-SKILLS/README.md: add domain entry to ascii_map_reference + horizontal_domains_summary with path, description, featured_skills, critical_constraints, wikilink",
        "02-SKILLS/<new-domain>/: create folder with 00-INDEX.md and initial skills",
        "02-SKILLS/00-INDEX.md: add domain to horizontal_skills_catalog",
        "01-RULES/08-SKILLS-REFERENCE.md: add domain to domain_catalog",
        "Human approval required: true"
      ],
      "backward_compatibility": "new domains must not break existing navigation or validation flows; must declare constraints applicability clearly"
    },
    "new_vertical_industry": {
      "requires_files_update": [
        "02-SKILLS/README.md: add industry entry to ascii_map_reference + vertical_domains_summary with path, description, structure, critical_constraints, wikilink",
        "02-SKILLS/<industry>/: create folder with prompts/, workflows/, validation/ subfolders",
        "02-SKILLS/skill-domains-mapping.md: add industry to business-to-skills mapping",
        "Human approval required: true"
      ],
      "backward_compatibility": "new industries must import horizontal skills rather than duplicating logic; must follow SDD format for new prompts/workflows"
    }
  },
  
  "validation_metadata": {
    "orchestrator_compatibility": ">=3.0.0-SELECTIVE",
    "schema_version": "skills-readme.v3.json",
    "checksum_algorithm": "SHA256",
    "audit_log_format": "JSON Lines with RFC3339 timestamps",
    "pii_scrubbing": "enabled for all logs (C3 + C8 compliance)",
    "reproducibility_guarantee": "Any skill navigation can be reproduced identically using this README + ascii_map_reference + canonical wikilinks"
  }
}
```

---

## ✅ CHECKLIST DE VALIDACIÓN POST-GENERACIÓN

<!-- 
【PARA PRINCIPIANTES】Antes de guardar este archivo, verifica estos puntos.
-->
````markdown
```bash
# 1. Frontmatter válido
yq eval '.canonical_path' 02-SKILLS/README.md | grep -q "/02-SKILLS/README.md" && echo "✅ Ruta canónica correcta"

# 2. Constraints mapeadas (C5+C6)
yq eval '.constraints_mapped | contains(["C5"]) and contains(["C6"])' 02-SKILLS/README.md && echo "✅ C5 y C6 declaradas"

# 3. Mapa ASCII presente y completo
grep -q "🗺️ MAPA ESTRUCTURAL CANÓNICO" 02-SKILLS/README.md && echo "✅ Mapa ASCII incluido"
grep -c "AI/\|BASE DE DATOS-RAG/\|INFRAESTRUCTURA/\|SEGURIDAD/\|COMUNICACIÓN/\|DEPLOYMENT/" 02-SKILLS/README.md | awk '{if($1>=6) print "✅ 6 dominios horizontales en mapa"; else print "⚠️ Faltan dominios en mapa: "$1"/6"}'

# 4. 4 dominios verticales en mapa ASCII
grep -c "RESTAURANTES/\|HOTELES-POSADAS/\|ODONTOLOGÍA/\|INSTAGRAM-SOCIAL-MEDIA/" 02-SKILLS/README.md | awk '{if($1>=4) print "✅ 4 dominios verticales en mapa"; else print "⚠️ Faltan dominios en mapa: "$1"/4"}'

# 5. JSON final parseable
tail -n +$(grep -n '```json' 02-SKILLS/README.md | tail -1 | cut -d: -f1) 02-SKILLS/README.md | sed -n '/```json/,/```/p' | sed '1d;$d' | jq empty && echo "✅ JSON parseable"

# 6. Wikilinks canónicos (sin rutas relativas)
for link in $(grep -oE '\[\[[^]]+\]\]' 02-SKILLS/README.md | tr -d '[]' | sort -u); do
  if [[ "$link" =~ ^\[\[\.\/ || "$link" =~ ^\[\[\.\.\/ ]]; then
    echo "❌ Wikilink relativo: $link"
  else
    [ -f "${link#//}" ] || echo "⚠️ Wikilink no resuelto: $link"
  fi
done
```
````

**Criterio de aceptación:**  
- ✅ Frontmatter válido con `canonical_path: "/02-SKILLS/README.md"`  
- ✅ `constraints_mapped` incluye C5 y C6 (estructura + trazabilidad)  
- ✅ Mapa ASCII estructural canónico incluido con 6 dominios horizontales + 4 verticales  
- ✅ Cada dominio documentado con propósito, skills destacadas y constraints críticas  
- ✅ Sección JSON final es válida (puede parsearse con `jq .`)  
- ✅ Todos los wikilinks son canónicos (absolutos desde raíz)  

---

> 🎯 **Mensaje final para el lector humano**:  
> Este README es tu puerta de entrada con mapa visual. No es estático: evoluciona con el proyecto.  
> **Mapa → Necesidad → Descubrimiento → Validación → Integración**.  
> Si sigues ese flujo, nunca te perderás en las skills ni integrarás patrones no validados.  
> La gobernanza no es una carga. Es la libertad de escalar sin miedo a romper.  

---
