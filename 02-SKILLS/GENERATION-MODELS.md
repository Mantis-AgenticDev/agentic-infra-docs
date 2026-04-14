---
ai_optimized: true
version: "v1.0.0"
constraints: ["C1", "C2", "C3", "C4", "C5", "C6"]
purpose: "Modelos de generación SDD para MANTIS AGENTIC. Flujos colaborativo y full-automated con validación C1-C6, navegación IA y documentación para todos los niveles de experiencia."
tags: ["generation", "sdd", "workflow", "terraform", "validation", "human-ai", "deployment", "hardening"]
ai_provider: "qwen"
related_files:
  - "[[../README.md]]"
  - "[[../PROJECT_TREE.md]]"
  - "[[../../README.md]]"
  - "[[../../knowledge-graph.json]]"
  - "[[skill-domains-mapping.md]]"
  - "[[../../01-RULES/00-INDEX.md]]"
  - "[[../../01-RULES/01-ARCHITECTURE-RULES.md]]"
  - "[[../../05-CONFIGURATIONS/validation/validate-skill-integrity.sh]]"
  - "[[../../05-CONFIGURATIONS/validation/audit-secrets.sh]]"
  - "[[../../05-CONFIGURATIONS/validation/check-rls.sh]]"
  - "[[../../05-CONFIGURATIONS/validation/validate-frontmatter.sh]]"
  - "[[../../05-CONFIGURATIONS/validation/check-wikilinks.sh]]"
  - "[[../../05-CONFIGURATIONS/validation/verify-constraints.sh]]"
  - "[[../../05-CONFIGURATIONS/validation/schema-validator.py]]"
  - "[[../../05-CONFIGURATIONS/validation/schemas/skill-input-output.schema.json]]"
  - "[[../../05-CONFIGURATIONS/templates/skill-template.md]]"
  - "[[../../05-CONFIGURATIONS/terraform/modules/vps-base/main.tf]]"
  - "[[../../05-CONFIGURATIONS/terraform/modules/postgres-rls/main.tf]]"
  - "[[../../05-CONFIGURATIONS/pipelines/.github/workflows/validate-skill.yml]]"
  - "[[../../05-CONFIGURATIONS/pipelines/.github/workflows/integrity-check.yml]]"
---

# 🤖 MODELOS DE GENERACIÓN SDD - MANTIS AGENTIC

> 📌 **Para IA**: Este documento define los flujos de generación de skills. Usa `ai_optimized: true` para parsear bloques ASCII, validar contra `skill-input-output.schema.json`, y ejecutar validadores en orden: `validate-frontmatter.sh` → `audit-secrets.sh` → `check-rls.sh` → `verify-constraints.sh` → `schema-validator.py`.

## 🧭 Navegación Complementaria
Para ejecutar el flujo completo de generación → validación → producción:
[[AI-NAVIGATION-CONTRACT.md]] — Proporciona rutas canónicas, constraints por tipo de archivo, y validación automatizada vía `orchestrator-engine.sh`.

---

## 🧭 Navegación Rápida (Humanos + IA)

| Nivel | Enlace | Propósito |
|-------|--------|-----------|
| 🏠 **Inicio del Proyecto** | `[[../../README.md]]` | Visión general, stack, objetivos |
| 🌳 **Estructura Canónica** | `[[../PROJECT_TREE.md]]` | Mapa de archivos y rutas raw |
| 🕸️ **Grafo de Conocimiento** | `[[../../knowledge-graph.json]]` | Dependencias entre módulos |
| 🗺️ **Mapeo de Dominios** | `[[skill-domains-mapping.md]]` | Asignación de skills por industria |
| 🛡️ **Reglas de Arquitectura** | `[[../../01-RULES/01-ARCHITECTURE-RULES.md]]` | Constraints C1-C6 detallados |
| 🧪 **Validadores** | `[[../../05-CONFIGURATIONS/validation/]]` | Scripts de integridad SDD |
| 📦 **Plantillas** | `[[../../05-CONFIGURATIONS/templates/skill-template.md]]` | Estructura base para generación |
| 🚀 **Infra como Código** | `[[../../05-CONFIGURATIONS/terraform/]]` | Módulos Terraform hardenizados |

---

## 🎯 Propósito de Este Documento

Este archivo define **dos modelos de generación** para skills en MANTIS AGENTIC:

1. **🔹 Modelo Colaborativo Humano-IA**: Flujo guiado donde la IA pregunta, valida y entrega código listo para copiar/pegar. Ideal para juniors, prototipado rápido y equipos sin perfil DevOps.
2. **🔹 Modelo Full-Automated (Hardened + Terraform)**: Flujo cero-toque donde la IA genera un ZIP con infraestructura, validaciones y deploy listo. Ideal para expertos, producción enterprise y auditoría regulatoria.

Ambos modelos garantizan:
- ✅ Cumplimiento de constraints C1-C6 en cada artefacto generado
- ✅ Validación automática contra `skill-input-output.schema.json`
- ✅ Cero credenciales hardcodeadas (C3)
- ✅ Aislamiento multi-tenant obligatorio (C4)
- ✅ Auditoría de integridad con SHA256 (C5)
- ✅ Inferencia cloud-only o excepción documentada (C6)

---

## 🔹 MODELO 1: SDD COLABORATIVO HUMANO-IA
*Flujo guiado: IA pregunta → Humano responde → IA valida → Entrega lista para copiar/pegar*

### 🎯 Público Objetivo
| Nivel | Perfil | Beneficio Clave |
|-------|--------|----------------|
| 👶 Junior | Sin experiencia en DevOps/IA | La IA guía cada paso, valida en tiempo real y entrega código seguro sin configuración manual |
| 👨‍💻 Intermedio | Conoce bash/Docker pero no hardening | La IA aplica constraints C1-C6 automáticamente, evita errores comunes de seguridad |
| 👨‍🔧 Experto | DevOps/SRE con experiencia | La IA acelera el boilerplate, mantiene consistencia estructural y genera auditoría C5 lista para compliance |

### 🔄 Flujo Detallado con Herramientas Disponibles

```ascii
┌─────────────────────────────────────────────────────────────────┐
│  🧭 INICIO: Humano solicita skill vía prompt natural            │
│  Ej: "Necesito un agente WhatsApp para reservas de restaurante" │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│  🤖 FASE 1: INTERROGATORIO CONTEXTUAL (IA → Humano)             │
│  ─────────────────────────────────────────────────────────      │
│  IA pregunta secuencialmente (validación en tiempo real):       │
│                                                                   │
│  [1] ¿Tipo de negocio?                                          │
│      ├─ Restaurante → carga:                                    │
│      │  • [[../RESTAURANTES/restaurant-order-chatbot.md]]      │
│      │  • [[../RESTAURANTES/restaurant-booking-ai.md]]         │
│      │  • [[../AI/qwen-integration.md]] (modelo base)          │
│      ├─ Clínica → carga:                                        │
│      │  • [[../ODONTOLOGÍA/dental-appointment-automation.md]]  │
│      │  • [[../AI/gemini-integration.md]] (multimodal)         │
│      └─ Hotel → carga:                                          │
│      │  • [[../HOTELES-POSADAS/hotel-booking-automation.md]]   │
│      │  • [[../COMUNICACION/whatsapp-rag-openrouter.md]]       │
│                                                                   │
│  [2] ¿Volumen estimado? (consultas/día)                         │
│      ├─ <100 → Selecciona DB ligera:                            │
│      │  • [[../BASE-DE-DATOS-RAG/google-sheets-as-database.md]]│
│      │  • Qdrant lite mode (mem_limit: 512MB)                  │
│      ├─ 100-1k → Selecciona DB estándar:                        │
│      │  • [[../BASE-DE-DATOS-RAG/mysql-optimization-4gb-ram.md]]│
│      │  • Qdrant estándar + Redis cache                        │
│      └─ >1k → Selecciona DB cluster:                            │
│      │  • [[../BASE-DE-DATOS-RAG/postgres-prisma-rag.md]]      │
│      │  • Qdrant cluster + Redis + connection pooling          │
│                                                                   │
│  [3] ¿Canales requeridos?                                       │
│      ├─ WhatsApp → integra:                                     │
│      │  • [[../COMUNICACION/whatsapp-rag-openrouter.md]]       │
│      │  • [[../INFRAESTRUCTURA/ssh-tunnels-remote-services.md]]│
│      ├─ Telegram → integra:                                     │
│      │  • [[../COMUNICACION/telegram-bot-integration.md]]      │
│      │  • [[../INFRAESTRUCTURA/fail2ban-configuration.md]]     │
│      └─ Multi-canal → carga:                                    │
│         • [[../COMUNICACION/multi-channel-routing.md]]         │
│         • [[../INFRAESTRUCTURA/docker-compose-networking.md]]  │
│                                                                   │
│  [4] ¿Datos sensibles? (PII, historial médico, pagos)          │
│      ├─ Sí → activa hardening:                                  │
│      │  • [[../../05-CONFIGURATIONS/validation/audit-secrets.sh]]│
│      │  • [[../SEGURIDAD/backup-encryption.md]]                │
│      │  • [[../SEGURIDAD/security-hardening-vps.md]]           │
│      └─ No → modo estándar                                      │
│                                                                   │
│  [5] ¿Requiere inferencia local?                               │
│      ├─ Sí → usa:                                               │
│      │  • [[../AI/llama-integration.md]] + C6_exception_documented│
│      │  • [[../../01-RULES/06-MULTITENANCY-RULES.md]] (excepción)│
│      └─ No → cloud-only:                                        │
│         • [[../AI/openrouter-api-integration.md]]              │
│         • [[../AI/qwen-integration.md]]                        │
│         • [[../AI/gemini-integration.md]]                      │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│  🔍 FASE 2: VALIDACIÓN AUTOMÁTICA (IA → Repositorio)           │
│  ─────────────────────────────────────────────────────────      │
│  IA ejecuta en background (sin mostrar al humano):              │
│                                                                   │
│  1. Lee [[../PROJECT_TREE.md]] → identifica archivos relevantes│
│  2. Carga [[../../05-CONFIGURATIONS/templates/skill-template.md]]│
│     → estructura base con frontmatter obligatorio               │
│  3. Aplica constraints C1-C6 según respuestas:                  │
│     • C1: Calcula RAM necesaria → ajusta docker-compose         │
│       - Usa: [[../INFRAESTRUCTURA/n8n-concurrency-limiting.md]]│
│       - Valida: [[../../05-CONFIGURATIONS/validation/verify-constraints.sh]]│
│     • C2: Define cpu_limit por servicio                         │
│       - Usa: [[../INFRAESTRUCTURA/health-monitoring-vps.md]]   │
│     • C3: Genera .env.example con variables, cero hardcode      │
│       - Valida: [[../../05-CONFIGURATIONS/validation/audit-secrets.sh]]│
│     • C4: Inyecta tenant_id en todas las queries DB             │
│       - Usa: [[../BASE-DE-DATOS-RAG/multi-tenant-data-isolation.md]]│
│       - Valida: [[../../05-CONFIGURATIONS/validation/check-rls.sh]]│
│     • C5: Incluye sha256sum en scripts de backup                │
│       - Usa: [[../SEGURIDAD/backup-encryption.md]]             │
│     • C6: Selecciona proveedor cloud o documenta excepción      │
│       - Valida: grep -r 'c6_exception_documented'              │
│  4. Ejecuta validadores locales en orden:                       │
│     a) [[../../05-CONFIGURATIONS/validation/validate-frontmatter.sh]]│
│        → verifica campos: ai_optimized, version, constraints    │
│     b) [[../../05-CONFIGURATIONS/validation/check-wikilinks.sh]]│
│        → confirma que todos los [[enlaces]] existen             │
│     c) [[../../05-CONFIGURATIONS/validation/audit-secrets.sh]] │
│        → 0 coincidencias con patrones de credenciales           │
│     d) [[../../05-CONFIGURATIONS/validation/check-rls.sh]]     │
│        → todas las políticas SQL tienen tenant_id               │
│     e) [[../../05-CONFIGURATIONS/validation/verify-constraints.sh]]│
│        → C1-C6 explícitos en ejemplos                           │
│     f) python3 [[../../05-CONFIGURATIONS/validation/schema-validator.py]]│
│        → outputs cumplen [[../../05-CONFIGURATIONS/validation/schemas/skill-input-output.schema.json]]│
│  5. Genera checksum SHA256 del output final (C5 audit)          │
│     - Comando: sha256sum generated_skill.md > generated_skill.sha256│
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│  📦 FASE 3: ENTREGA EN PANTALLA (IA → Humano)                  │
│  ─────────────────────────────────────────────────────────      │
│  IA muestra bloque listo para copiar/pegar:                     │
│                                                                   │
│  ┌─ 🗂️ ESTRUCTURA GENERADA ─────────────────────────────┐      │
│  │  restaurante-whatsapp-rag/                               │      │
│  │  ├── docker-compose.yml          [C1/C2 limits]          │      │
│  │  │   • mem_limit: 1g (n8n)                              │      │
│  │  │   • cpu_quota: 100000 (1 vCPU)                       │      │
│  │  │   • networks: [mantis-internal]                      │      │
│  │  ├── .env.example                [C3 zero-hardcode]     │      │
│  │  │   • OPENROUTER_API_KEY="${OPENROUTER_API_KEY}"      │      │
│  │  │   • DB_PASSWORD="${DB_PASSWORD}"                    │      │
│  │  │   • TENANT_ID="${TENANT_ID}"                        │      │
│  │  ├── skills/                                           │      │
│  │  │   ├── whatsapp-rag-openrouter.md  [C4 tenant_id]    │      │
│  │  │   │   • prompt_template: "Consulta reserva para {{tenant_id}}"│      │
│  │  │   │   • tenant_filter: "WHERE tenant_id = :tenant_id"│      │
│  │  │   ├── mysql-optimization-4gb-ram.md                 │      │
│  │  │   │   • shared_buffers: 512MB                       │      │
│  │  │   │   • max_connections: 50                         │      │
│  │  │   └── qdrant-rag-ingestion.md                       │      │
│  │  │       • collection_name: "rest_{tenant_id}"         │      │
│  │  │       • RLS policy: USING (tenant_id = current_setting(...))│      │
│  │  ├── validation/                                       │      │
│  │  │   ├── pre-deploy-check.sh      [C5 SHA256]          │      │
│  │  │   │   • sha256sum -c generated_skill.sha256         │      │
│  │  │   └── skill-output.json        [schema validated]   │      │
│  │  │       • validado contra skill-input-output.schema.json    │      │
│  │  └── README-deploy.md             [pasos 1-2-3]        │      │
│  │      • git clone, cp, validate, docker-compose up      │      │
│  └────────────────────────────────────────────────────────┘      │
│                                                                   │
│  ┌─ ⚙️ COMANDOS LISTOS PARA EJECUTAR ───────────────────┐      │
│  │  # 1. Clonar base                                      │      │
│  │  git clone https://github.com/Mantis-AgenticDev/agentic-infra-docs│      │
│  │  cd agentic-infra-docs                                │      │
│  │                                                       │      │
│  │  # 2. Aplicar configuración generada                   │      │
│  │  mkdir -p projects/restaurante-whatsapp-rag          │      │
│  │  cp generated/restaurante-whatsapp-rag/* projects/...│      │
│  │                                                       │      │
│  │  # 3. Validar antes de deploy (CRÍTICO)               │      │
│  │  cd projects/restaurante-whatsapp-rag                │      │
│  │  ../../05-CONFIGURATIONS/validation/validate-skill-integrity.sh .│      │
│  │  # → Debe retornar: status: passed                   │      │
│  │                                                       │      │
│  │  # 4. Desplegar                                        │      │
│  │  docker-compose up -d                                 │      │
│  │                                                       │      │
│  │  # 5. Post-deploy health check                        │      │
│  │  curl -s http://localhost:3000/health | jq           │      │
│  └────────────────────────────────────────────────────────┘      │
│                                                                   │
│  ✅ Checklist de validación incluido (C1-C6):                    │
│  • [✓] C1: RAM total ≤ 3.8GB (margen 200MB SO)                  │
│  • [✓] C2: Cada servicio ≤ 1.0 vCPU                             │
│  • [✓] C3: 0 credenciales hardcodeadas detectadas               │
│  • [✓] C4: Todas las queries filtran por tenant_id              │
│  • [✓] C5: Checksum SHA256 generado y verificable               │
│  • [✓] C6: Inferencia cloud-only (o excepción documentada)      │
│                                                                   │
│  📚 Recursos adicionales por nivel:                             │
│  👶 Junior:                                                       │
│    • Lee: [[../../00-CONTEXT/documentation-validation-cheklist.md]]│
│    • Usa: IA para explicar cada comando con --help             │
│  👨‍💻 Intermedio:                                                  │
│    • Modifica: docker-compose.yml para ajustar límites         │
│    • Ejecuta: audit-secrets.sh manualmente para aprender       │
│  👨‍🔧 Experto:                                                    │
│    • Extiende: Agrega módulos Terraform desde [[../../05-CONFIGURATIONS/terraform/]]│
│    • Auditoría: Integra con CI/CD vía [[../../05-CONFIGURATIONS/pipelines/.github/workflows/]]│
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│  🎯 RESULTADO: Humano copia, pega y despliega en <5 min         │
│  • Cero configuración manual de límites, secretos o RLS         │
│  • Todo validado contra constraints C1-C6                       │
│  • Reproducible: mismo input → mismo output determinista        │
│  • Audit-ready: checksum SHA256 para trazabilidad (C5)          │
└─────────────────────────────────────────────────────────────────┘
```

### 🛠️ Herramientas Utilizadas en Modelo 1

| Herramienta | Ruta | Función en el Flujo | Nivel Recomendado |
|-------------|------|-------------------|------------------|
| `validate-frontmatter.sh` | `05-CONFIGURATIONS/validation/` | Verifica estructura YAML obligatoria | Junior+ |
| `check-wikilinks.sh` | `05-CONFIGURATIONS/validation/` | Confirma que todos los enlaces Obsidian existen | Junior+ |
| `audit-secrets.sh` | `05-CONFIGURATIONS/validation/` | Detecta credenciales hardcodeadas (C3) | Intermedio+ |
| `check-rls.sh` | `05-CONFIGURATIONS/validation/` | Valida políticas RLS con tenant_id (C4) | Intermedio+ |
| `verify-constraints.sh` | `05-CONFIGURATIONS/validation/` | Confirma presencia explícita de C1-C6 | Experto |
| `schema-validator.py` | `05-CONFIGURATIONS/validation/` | Valida outputs contra JSON Schema (C5) | Experto |
| `skill-template.md` | `05-CONFIGURATIONS/templates/` | Plantilla base para generación estructurada | Todos |
| `PROJECT_TREE.md` | Raíz | Mapa canónico para resolución de rutas | Todos |

---

## 🔹 MODELO 2: SDD FULL-AUTOMATED (HARDENED + TERRAFORM)
*Flujo cero-toque: IA genera ZIP con infraestructura, validaciones y deploy listo*

### 🎯 Público Objetivo
| Nivel | Perfil | Beneficio Clave |
|-------|--------|----------------|
| 👶 Junior | Sin experiencia en IaC | La IA entrega ZIP con todo configurado; solo ejecuta 5 comandos |
| 👨‍💻 Intermedio | Conoce Terraform básico | La IA aplica hardening avanzado (UFW, fail2ban, RLS) automáticamente |
| 👨‍🔧 Experto | DevOps/SRE con experiencia en cloud | La IA genera infraestructura audit-ready, con locking remoto, encryption y rollback automático |

### 🔄 Flujo Detallado con Herramientas Disponibles

```ascii
┌─────────────────────────────────────────────────────────────────┐
│  🚀 INICIO: Humano solicita skill + "modo production"           │
│  Ej: "Genera agente WhatsApp para restaurante con deploy en AWS"│
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│  🤖 FASE 1: INTERROGATORIO + INFERENCIA AUTOMÁTICA              │
│  ─────────────────────────────────────────────────────────      │
│  IA pregunta mínimo esencial y deduce el resto:                 │
│                                                                 │
│  [1] ¿Proveedor cloud? (AWS/GCP/Azure/On-prem)                  │
│      ├─ AWS → carga módulos:                                    │
│      │  • [[../../05-CONFIGURATIONS/terraform/modules/vps-base/]]│
│      │  • EKS templates + RDS + CloudWatch                       │
│      │  • Backend: S3 + DynamoDB lock (C5)                      │
│      ├─ GCP → carga módulos:                                    │
│      │  • Cloud Run + Cloud SQL + Cloud Monitoring              │
│      │  • Secret Manager para C3                                │
│      └─ On-prem → carga:                                        │
│         • docker-compose + Ansible playbooks                    │
│         • UFW/fail2ban para hardening (C3)                      │
│                                                                 │
│  [2] ¿SLA requerido? (99.9% / 99.99% / best-effort)             │
│      ├─ 99.99% → activa:                                        │
│      │  • Multi-AZ deployment                                   │
│      │  • Auto-scaling groups (C2: cpu_limit dinámico)          │
│      │  • Health checks cada 30s + alertas Telegram/Gmail       │
│      │  • [[../INFRAESTRUCTURA/health-monitoring-vps.md]]       │
│      └─ best-effort → single-node con:                          │
│         • Backup diario encriptado (C5)                         │
│         • [[../SEGURIDAD/rsync-automation.md]]                  │
│                                                                 │
│  [3] ¿Presupuesto mensual estimado?                             │
│      ├─ <$50 → usa:                                             │
│      │  • Spot instances + Qdrant lite                          │
│      │  • [[../BASE-DE-DATOS-RAG/mysql-optimization-4gb-ram.md]]│
│      └─ >$200 → activa:                                         │
│         • Reserved instances + Qdrant cluster                   │
│         • Redis cache + connection pooling                      │
│         • [[../INFRAESTRUCTURA/n8n-concurrency-limiting.md]]    │
│                                                                 │
│  → IA infiere automáticamente:                                  │
│     • Tamaño de DB según volumen estimado                       │
│     • Estrategia de backup según criticidad                     │
│     • Configuración de red (VPC, subnets, security groups)      │
│     • Políticas de IAM mínimas (principle of least privilege)   │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│  🔧 FASE 2: GENERACIÓN HARDENED (IA → Terraform + Validadores)  │
│  ─────────────────────────────────────────────────────────      │
│  IA ejecuta pipeline interno (sin intervención humana):         │
│                                                                 │
│  1. Selecciona módulos Terraform según respuestas:              │
│     • terraform/modules/vps-base/          → C1/C2 limits       │
│       - memory = var.ram_limit_mb * 1024 * 1024                 │
│       - cpu_quota = var.cpu_limit * 100000                      │
│     • terraform/modules/postgres-rls/      → C4 tenant isolation│
│       - ALTER TABLE ... ENABLE ROW LEVEL SECURITY               │
│       - CREATE POLICY ... USING (tenant_id = ...)               │
│     • terraform/modules/backup-encrypted/  → C5 SHA256+age      │
│       - age -r ${BACKUP_PUB_KEY} -o backup.tar.gz.age           │
│       - sha256sum backup.tar.gz.age > backup.sha256             │
│     • terraform/modules/openrouter-proxy/  → C6 cloud routing   │
│       - endpoint: https://openrouter.ai/api/v1                  │
│       - fallback_models: [qwen, deepseek, claude]               │
│                                                                 │
│  2. Genera variables.tf con validaciones estrictas:             │
│     variable "ram_limit_mb" {                                   │
│       type = number                                             │
│       validation {                                              │
│         condition = var.ram_limit_mb <= 4096                    │
│         error_message = "C1: RAM máxima 4096MB"                 │
│       }                                                         │
│     }                                                           │
│     variable "tenant_id" {                                      │
│       type = string                                             │
│       validation {                                              │
│         condition = can(regex("^[a-z0-9-]{8,36}$", var.tenant_id))│
│         error_message = "C4: tenant_id inválido"                │
│       }                                                         │
│     }                                                           │
│                                                                 │
│  3. Aplica hardening automático:                                │
│     • UFW rules:                                                │
│       - ufw default deny incoming                               │
│       - ufw allow from ${TRUSTED_CIDR} to any port 22           │
│       - [[../INFRAESTRUCTURA/ufw-firewall-configuration.md]]    │
│     • fail2ban:                                                 │
│       - enabled = true, maxretry = 3, bantime = 1h              │
│       - [[../INFRAESTRUCTURA/fail2ban-configuration.md]]        │
│     • SSH:                                                      │
│       - PasswordAuthentication no                               │
│       - AllowUsers ${ADMIN_USER}                                │
│       - [[../INFRAESTRUCTURA/ssh-key-management.md]]            │
│     • Docker:                                                   │
│       - --read-only, --cap-drop=ALL                             │
│       - --security-opt no-new-privileges:true                   │
│       - [[../INFRAESTRUCTURA/docker-compose-networking.md]]     │
│                                                                 │
│  4. Ejecuta validación cruzada en memoria:                      │
│     a) ./verify-constraints.sh --strict → confirma C1-C6        │
│     b) ./audit-secrets.sh → 0 coincidencias con patrones de keys│
│     c) ./check-rls.sh → todas las políticas tienen tenant_id    │
│     d) python3 schema-validator.py → outputs cumplen schema     │
│     e) tfsec/checkov scan → 0 critical findings en Terraform    │
│                                                                 │
│  5. Genera artefactos firmados:                                 │
│     • infrastructure.zip (terraform + docker-compose + scripts) │
│     • validation-report.json (checksum SHA256 de cada archivo)  │
│     • deploy-checklist.md (pasos 1-2-3 con rollback automático) │
│     • audit-trail.log (registro de validaciones ejecutadas)     │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│  📦 FASE 3: ENTREGA ZIP + INSTRUCCIONES MÍNIMAS                 │
│  ─────────────────────────────────────────────────────────      │
│  IA muestra enlace de descarga y comando único:                 │
│                                                                 │
│  ┌─ 🗂️ CONTENIDO DEL ZIP (infrastructure-v1.0.0.zip)     ───┐   │
│  │  ├── terraform/                                          │    │
│  │  │   ├── main.tf              [C1/C2/C3/C4/C5/C6]        │    │
│  │  │   │   • resource "docker_container" con limits        │    │
│  │  │   │   • resource "postgresql_policy" con RLS          │    │
│  │  │   │   • provider "openrouter" con fallback            │    │
│  │  │   ├── variables.tf         [validaciones estrictas]   │    │
│  │  │   │   • validation blocks para C1, C4, environment    │    │
│  │  │   ├── outputs.tf           [tipados para agentes]     │    │
│  │  │   │   • output "vps_endpoint" { value = ... }         │    │
│  │  │   │   • output "db_connection" { sensitive = true }   │    │
│  │  │   ├── backend.tf           [S3 + DynamoDB lock]       │    │
│  │  │   │   • encrypt = true (C5)                           │    │
│  │  │   │   • dynamodb_table = "mantis-state-lock"          │    │
│  │  │   └── modules/             [vps-base, postgres-rls,   │    │
│  │  │         backup-encrypted, openrouter-proxy]           │    │
│  │  ├── docker-compose/                                     │    │
│  │  │   ├── vps1-n8n-uazapi.yml  [mem_limit, cpu_quota]     │    │
│  │  │   │   • services.n8n.mem_limit: "1g"                  │    │
│  │  │   │   • services.n8n.deploy.resources.limits.cpus: "1.0"│    │
│  │  │   ├── vps2-crm-qdrant.yml  [RLS, network aislado]     │    │
│  │  │   │   • networks.mantis-internal.internal: true       │    │
│  │  │   │   • services.qdrant.command: ["--disable-telemetry"]│    │
│  │  │   └── vps3-n8n-uazapi.yml  [réplica escalable]        │    │
│  │  │       • deploy.replicas: ${var.scale_factor}          │    │
│  │  ├── scripts/                                            │    │
│  │  │   ├── bootstrap-hardened-repo.sh  [inicialización]    │    │
│  │  │   │   • git clone, cp, validate, deploy               │    │
│  │  │   ├── pre-deploy-validation.sh   [C1-C6 check]        │    │
│  │  │   │   • Ejecuta todos los validadores en orden        │    │
│  │  │   └── rollback.sh                [blue/green swap]    │    │
│  │  │       • docker service update --detach=false          │    │
│  │  │       • swap de aliases DNS/ingress                   │    │
│  │  ├── validation/                                         │    │
│  │  │   ├── skill-input-output.schema.json [schema base]          │    │
│  │  │   └── integrity-report.json    [SHA256 audit]         │    │
│  │  │       • {"files": {"main.tf": "abc123...", ...}}      │    │
│  │  ├── .env.example               [C3: zero hardcode]      │    │
│  │  │   • # Nunca commitar este archivo con valores reales  │    │
│  │  │   • OPENROUTER_API_KEY="${OPENROUTER_API_KEY}"        │    │
│  │  │   • DB_PASSWORD="${DB_PASSWORD}"                      │    │
│  │  └── README-deploy.md           [pasos 1-2-3]            │    │
│  │      • curl, unzip, sha256sum -c, terraform init/apply│       │
│  └───────────────────────────────────────────────────────--─┘    │
│                                                                   │
│  ┌─ ⚡ COMANDO ÚNICO DE DEPLOY ─────────────────────────┐    │
│  │  # 1. Descargar y extraer                              │    │
│  │  curl -sL https://mantis.agentic.dev/zip/... -o infra.zip│    │
│  │  unzip infra.zip -d mantis-deploy && cd mantis-deploy │    │
│  │                                                       │    │
│  │  # 2. Validar integridad (C5)                          │    │
│  │  sha256sum -c validation/integrity-report.json        │    │
│  │  # → Debe retornar: OK para todos los archivos        │    │
│  │  # → Si falla: NO proceder, contactar soporte         │    │
│  │                                                       │    │
│  │  # 3. Inicializar Terraform (con locking remoto)      │    │
│  │  terraform init -backend-config="env=prod"           │    │
│  │  # → Usa S3 + DynamoDB para state locking (C5)        │    │
│  │                                                       │    │
│  │  # 4. Plan + Apply con aprobación explícita           │    │
│  │  terraform plan -out=tfplan -var-file=prod.tfvars    │    │
│  │  terraform apply tfplan                              │    │
│  │  # → Requiere confirmación manual antes de aplicar   │    │
│  │                                                       │    │
│  │  # 5. Post-deploy: health check automático            │    │
│  │  ./scripts/pre-deploy-validation.sh --post            │    │
│  │  # → Ejecuta: curl /health, validate-skill-integrity.sh│    │
│  │  # → Si falla: ejecuta rollback.sh automáticamente   │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                   │
│  ✅ Validaciones incluidas en el ZIP (C1-C6):                    │
│  • [✓] tfsec/checkov scan → 0 critical findings                 │
│  • [✓] audit-secrets.sh → 0 credenciales expuestas              │
│  • [✓] check-rls.sh → 100% de políticas con tenant_id           │
│  • [✓] schema-validator.py → outputs cumplen skill-output.schema│
│  • [✓] rollback.sh probado en staging → swap <30s               │
│  • [✓] integrity-report.json → SHA256 de cada archivo (C5)      │
│                                                                   │
│  📚 Recursos adicionales por nivel:                             │
│  👶 Junior:                                                       │
│    • Lee: README-deploy.md paso a paso                          │
│    • Usa: --dry-run en terraform plan para ver cambios         │
│    • Pregunta: "¿Qué hace este comando?" a la IA               │
│  👨‍💻 Intermedio:                                                  │
│    • Modifica: prod.tfvars para ajustar límites por tenant     │
│    • Ejecuta: tfsec manualmente para aprender seguridad IaC    │
│    • Extiende: Agrega módulos desde terraform/modules/         │
│  👨‍🔧 Experto:                                                    │
│    • Auditoría: Integra con SIEM vía CloudWatch/Stackdriver    │
│    • Compliance: Genera reporte SOC2/ISO27001 desde validation/│
│    • Auto-remediation: Configura Lambda/Cloud Function para rollback automático│
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│  🎯 RESULTADO: Humano ejecuta 5 comandos → producción en <10 min│
│  • Infraestructura hardenizada C1-C6 desde el minuto 1          │
│  • Cero configuración manual de seguridad, límites o RLS        │
│  • Reproducible: mismo input → mismo ZIP determinista + checksum│
│  • Audit-ready: todos los artefactos firmados con SHA256 (C5)   │
│  • Rollback automático si health check falla (C1/C2)            │
└─────────────────────────────────────────────────────────────────┘
```

### 🛠️ Herramientas Utilizadas en Modelo 2

| Herramienta | Ruta | Función en el Flujo | Nivel Recomendado |
|-------------|------|-------------------|------------------|
| `terraform init/plan/apply` | `05-CONFIGURATIONS/terraform/` | Orquestación de infraestructura con locking remoto | Intermedio+ |
| `tfsec` / `checkov` | Pipeline CI/CD | Security scan de código Terraform (C3) | Experto |
| `age` encryption | `05-CONFIGURATIONS/terraform/modules/backup-encrypted/` | Cifrado asimétrico de backups (C5) | Experto |
| `docker-compose` con limits | `05-CONFIGURATIONS/docker-compose/` | Límites de recursos por servicio (C1/C2) | Intermedio+ |
| `validate-skill-integrity.sh` | `05-CONFIGURATIONS/validation/` | Validación maestra pre/post deploy | Todos |
| `rollback.sh` | Scripts generados | Blue/green swap automático en fallo | Experto |
| `integrity-report.json` | Validation output | Auditoría SHA256 de todos los artefactos (C5) | Experto |

---

## 🔗 Integración con el Ecosistema MANTIS

### Desde `skill-template.md`
```markdown
## 🔄 ¿Cómo se genera esta skill?
- Modo colaborativo: `[[GENERATION-MODELS.md#-modelo-1-sdd-colaborativo-humano-ia]]`
- Modo production: `[[GENERATION-MODELS.md#-modelo-2-sdd-full-automated-hardened--terraform]]`
- Validadores requeridos: `[[../../05-CONFIGURATIONS/validation/]]`
```

### Desde `00-INDEX.md`
```markdown
## 🤖 Flujos de Generación
- `[[GENERATION-MODELS.md]]`: Modelos colaborativo y full-automated con validación C1-C6
```

### Desde `PROJECT_TREE.md`
```markdown
## 🧭 Navegación por Rol
- 👶 Junior: Comienza en `[[02-SKILLS/GENERATION-MODELS.md#-modelo-1-sdd-colaborativo-humano-ia]]`
- 👨‍🔧 Experto: Ve directo a `[[02-SKILLS/GENERATION-MODELS.md#-modelo-2-sdd-full-automated-hardened--terraform]]`
```

### Desde `README.md` raíz
```markdown
## 🚀 Generación de Skills
- ¿Eres nuevo? Usa el [Modelo Colaborativo](02-SKILLS/GENERATION-MODELS.md#-modelo-1-sdd-colaborativo-humano-ia)
- ¿Necesitas producción enterprise? Usa el [Modelo Full-Automated](02-SKILLS/GENERATION-MODELS.md#-modelo-2-sdd-full-automated-hardened--terraform)
```

---

## 🧪 Validación Automatizada de Este Documento

Este archivo está diseñado para ser parseado por IA. Para validar su integridad:

```bash
# 1. Frontmatter obligatorio
./05-CONFIGURATIONS/validation/validate-frontmatter.sh 02-SKILLS/GENERATION-MODELS.md

# 2. Wikilinks válidos
./05-CONFIGURATIONS/validation/check-wikilinks.sh 02-SKILLS/GENERATION-MODELS.md

# 3. Constraints C1-C6 presentes
./05-CONFIGURATIONS/validation/verify-constraints.sh 02-SKILLS/GENERATION-MODELS.md

# 4. Ejemplos JSON cumplen schema (si los hubiera)
python3 05-CONFIGURATIONS/validation/schema-validator.py \
  05-CONFIGURATIONS/validation/schemas/skill-input-output.schema.json \
  02-SKILLS/GENERATION-MODELS.md
```

**Criterio de éxito**: Todos los comandos retornan `status: passed` o código de salida `0`.

---

## 📚 Glosario Rápido (Para Juniors)

| Término | Significado | Ejemplo en MANTIS |
|---------|-------------|------------------|
| **SDD** | Specification-Driven Development: desarrollar siguiendo una especificación formal | `skill-template.md` define estructura obligatoria |
| **C1-C6** | Constraints de hardening: límites de recursos, seguridad, multi-tenant, auditoría | `C4: tenant_id obligatorio en todas las queries` |
| **RLS** | Row-Level Security: aislamiento de datos a nivel de fila en DB | `CREATE POLICY ... USING (tenant_id = ...)` |
| **SHA256** | Checksum criptográfico para verificar integridad de archivos | `sha256sum backup.tar.gz > backup.sha256` |
| **Hardening** | Endurecimiento de seguridad: reducir superficie de ataque | UFW deny-by-default, fail2ban, SSH key-only |
| **IaC** | Infrastructure as Code: definir infraestructura en archivos versionables | Terraform modules en `05-CONFIGURATIONS/terraform/` |

---

## 🔄 Actualización y Mantenimiento

Este documento debe actualizarse cuando:
- ✅ Se agregue un nuevo validador a `05-CONFIGURATIONS/validation/`
- ✅ Se modifique `skill-input-output.schema.json`
- ✅ Se agregue un nuevo módulo Terraform o skill horizontal
- ✅ Cambie el flujo de generación (ej: nuevo modelo "modo educativo")

**Procedimiento de actualización:**
1. Modificar este archivo siguiendo `skill-template.md`
2. Ejecutar `validate-skill-integrity.sh` para validar cambios
3. Commit con mensaje estructurado: `docs(SDD-MODELS): actualizar flujo para nuevo validador X`
4. Push → CI/CD ejecutará `integrity-check.yml` automáticamente

---

> 📝 **Nota Final para IA**: Este documento es auto-referencial. Al generarlo, aplica los mismos validadores que describe: frontmatter, wikilinks, constraints C1-C6, schema validation y checksum SHA256. Mantén la estructura ASCII para legibilidad humana y machine-parsable.

---

**Última actualización**: `$(date -u +"%Y-%m-%dT%H:%M:%SZ")`  
**Versión**: `v1.0.0`  
**Validado contra**: `skill-input-output.schema.json` ✅  
**Checksum**: `$(sha256sum 02-SKILLS/GENERATION-MODELS.md | awk '{print $1}')`
```
