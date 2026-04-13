---
ai_optimized: true
version: "v1.0.0"
constraints: ["C1", "C2", "C3", "C4", "C5", "C6"]
purpose: "Flujo de generación SDD asistida colaborativa Humano-IA para completar documentos pendientes del repositorio. Incluye validación pre-entrega, navegación canónica para IA y guías por nivel de experiencia."
tags: ["sdd", "collaborative-generation", "validation-gate", "hardening", "human-ai", "workflow", "pending-files"]
ai_provider: "qwen"
related_files:
  - "[[README.md]]"
  - "[[PROJECT_TREE.md]]"
  - "[[knowledge-graph.json]]"
  - "[[00-CONTEXT/PROJECT_OVERVIEW.md]]"
  - "[[01-RULES/00-INDEX.md]]"
  - "[[05-CONFIGURATIONS/templates/skill-template.md]]"
  - "[[05-CONFIGURATIONS/validation/validate-skill-integrity.sh]]"
  - "[[05-CONFIGURATIONS/validation/schemas/skill-input-output.schema.json]]"
---

# 🔄 FLUJO SDD ASISTIDA COLABORATIVA HUMANO-IA
> Generación de documentos pendientes con validación pre-entrega, navegación canónica y hardening C1-C6

---

## 🧭 Mapa de Navegación Canónica (Para IA)
*Instrucción crítica: Toda IA generadora debe resolver rutas exclusivamente desde estos paths. Cero inferencia externa. Cero alucinación.*

| Recurso | Ruta Canónica | Función en Generación |
|---------|---------------|----------------------|
| 🌳 Árbol de Estado | `[[PROJECT_TREE.md]]` | Identifica archivos `🆕 PENDIENTE`, `📝 EN PROGRESO`, `✅ COMPLETADO` |
| 📜 Reglas Base | `[[01-RULES/00-INDEX.md]]` → `01-ARCHITECTURE-RULES.md` a `08-SKILLS-REFERENCE.md` | Constraints obligatorios, patrones de código, límites de recursos |
| 📦 Plantilla Maestra | `[[05-CONFIGURATIONS/templates/skill-template.md]]` | Estructura frontmatter, secciones obligatorias, mapeo C1-C6 |
| 🛡️ Validadores | `[[05-CONFIGURATIONS/validation/]]` | `validate-frontmatter.sh`, `audit-secrets.sh`, `check-rls.sh`, `verify-constraints.sh` |
| 🔍 Schema Output | `[[05-CONFIGURATIONS/validation/schemas/skill-input-output.schema.json]]` | Validación determinista de bloques JSON generados |
| 🕸️ Grafo de Dependencias | `[[knowledge-graph.json]]` | Resolución de referencias cruzadas y orden de generación |
| 📖 Contexto Negocio/Infra | `[[00-CONTEXT/facundo-business-model.md]]`, `[[00-CONTEXT/facundo-infrastructure.md]]` | Parámetros reales de VPS, SLA, pricing, stack tecnológico |

---

## 🎯 Objetivo del Flujo
Garantizar que **cualquier documento generado para completar pendientes** pase por un **gate de validación automática pre-entrega**. El humano solo recibe código ya verificado, fences cerrados, frontmatter válido, constraints explícitos y enlaces canónicos funcionales. Cero iteraciones por faltantes estructurales.

---

## 🔄 Flujo Colaborativo con Gate de Validación Pre-Entrega

```ascii
┌─────────────────────────────────────────────────────────────────┐
│  🧭 INICIO: Humano solicita documento pendiente                │
│  Ej: "Genera 03-AGENTS/clients/whatsapp-attention-agent.md"     │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│  🤖 FASE 1: RESOLUCIÓN CANÓNICA (IA → Repositorio)             │
│  ─────────────────────────────────────────────────────────      │
│  1. Lee PROJECT_TREE.md → confirma estado "🆕 PENDIENTE"       │
│  2. Carga obligatoriamente:                                     │
│     • [[05-CONFIGURATIONS/templates/skill-template.md]]         │
│     • [[01-RULES/01-ARCHITECTURE-RULES.md]]                    │
│     • [[01-RULES/06-MULTITENANCY-RULES.md]]                    │
│  3. Identifica dependencias en knowledge-graph.json            │
│  4. Determina dominio: CLIENTS → aplica patterns de [[02-SKILLS/COMUNICACION/]]│
│  5. Carga contexto infra: 3 VPS, 4GB RAM, Qdrant, MySQL, n8n   │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│  📝 FASE 2: GENERACIÓN ESTRUCTURAL (IA → Borrador Interno)     │
│  ─────────────────────────────────────────────────────────      │
│  IA construye documento en memoria siguiendo:                   │
│  • Frontmatter YAML obligatorio (ai_optimized, version, etc.)  │
│  • Secciones canónicas: Overview, Constraint Mapping, Config,  │
│    Ejemplos (≥5), Validación, Artifacts, Cross-References      │
│  • Fences de código: ```bash, ```json, ```sql, ```yaml         │
│  • Wikilinks Obsidian resolubles desde raíz                    │
│  • Constraints C1-C6 explícitos en cada bloque de código       │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│  🛡️ GATE DE VALIDACIÓN PRE-ENTREGA (IA → Autoverificación)    │
│  ─────────────────────────────────────────────────────────      │
│  ANTES de mostrar al humano, IA ejecuta internamente:           │
│                                                                   │
│  [✓] 1. Frontmatter YAML:                                       │
│      • Apertura/cierre --- correcto                             │
│      • ai_optimized: true, constraints: ["C1".."C6"]            │
│      • version semántica, tags no vacíos                        │
│                                                                   │
│  [✓] 2. Fence Integrity:                                        │
│      • grep -c '```' → par (apertura/cierre)                    │
│      • Lenguaje declarado: bash, json, sql, yaml, tf            │
│      • Cero fences anidados o truncados                         │
│                                                                   │
│  [✓] 3. Constraint Mapping:                                     │
│      • C1: timeout, memory_limit, shm_size presentes            │
│      • C2: cpu_limit, concurrency, nice/renice si aplica        │
│      • C3: process.env, ${VAR}, age -r, cero hardcode           │
│      • C4: tenant_id, RLS, X-Tenant-ID, ctx.tenant              │
│      • C5: sha256sum, audit_hash, backup encryption             │
│      • C6: openrouter/api.cloud, excepción documentada si local │
│                                                                   │
│  [✓] 4. Wikilinks & Rutas:                                      │
│      • Resolución desde [[PROJECT_TREE.md]]                     │
│      • Cero enlaces rotos o relativos ambiguos                  │
│      • Alias permitidos: [[ruta.md|texto legible]]              │
│                                                                   │
│  [✓] 5. Schema Validation:                                      │
│      • Bloques JSON cumplen [[.../skill-input-output.schema.json]]    │
│      • Campos obligatorios: tenant_id, constraints_verified, etc│
│                                                                   │
│  [❌] SI ALGÚN CHECK FALLA → IA REGENERA AUTOMÁTICAMENTE        │
│      • Aplica corrección puntual                               │
│      • Re-ejecuta gate completo                                │
│      • Máximo 3 iteraciones → si persiste, reporta error exacto│
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│  📦 FASE 3: ENTREGA VALIDADA AL HUMANO                         │
│  ─────────────────────────────────────────────────────────      │
│  IA muestra documento completo con:                             │
│  • ✅ Badge de validación: "GATE PASSED (5/5 checks)"          │
│  • 📝 Contenido listo para copiar/pegar                         │
│  • 🔗 Comandos de verificación post-guardado                    │
│  • 📊 Checklist de constraints cumplidos                        │
│                                                                   │
│  Ejemplo de salida:                                             │
│  ┌─ 📄 AGENTE WHATSAPP ATENCIÓN (validado) ───────────┐       │
│  │  ---                                               │       │
│  │  ai_optimized: true                                │       │
│  │  version: "v1.0.0"                                 │       │
│  │  constraints: ["C1","C2","C3","C4","C5","C6"]      │       │
│  │  ...                                               │       │
│  │  ## 🛡️ Constraint Mapping                          │       │
│  │  • C1: mem_limit: 512m, timeout_ms: 30000          │       │
│  │  • C4: WHERE tenant_id = :tenant_id                │       │
│  │  ...                                               │       │
│  │  ```json                                           │       │
│  │  { "tenant_id": "...", "model_provider": "..." }   │       │
│  │  ```                                               │       │
│  └────────────────────────────────────────────────────┘       │
│                                                                   │
│  📋 Comandos post-guardado (para humano):                       │
│  # 1. Guardar en ruta canónica                                  │
│  mkdir -p 03-AGENTS/clients                                     │
│  nano 03-AGENTS/clients/whatsapp-attention-agent.md             │
│                                                                   │
│  # 2. Verificar integridad local                                │
│  ./05-CONFIGURATIONS/validation/validate-skill-integrity.sh .   │
│  python3 05-CONFIGURATIONS/validation/schema-validator.py \     │
│    05-CONFIGURATIONS/validation/schemas/skill-input-output.schema.json .│
│                                                                   │
│  # 3. Commit & Push                                             │
│  git add 03-AGENTS/clients/whatsapp-attention-agent.md          │
│  git commit -m "feat(AGENT): generar whatsapp-attention-agent"  │
│  git push origin main                                           │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🗺️ Mapa de Pendientes & Fuentes Canónicas

| Directorio Pendiente | Archivos Clave | Fuente Canónica para IA | Validadores Obligatorios |
|----------------------|----------------|-------------------------|--------------------------|
| `03-AGENTS/` | `health-monitor-agent.md`, `backup-manager-agent.md`, `whatsapp-attention-agent.md`, `rag-knowledge-agent.md` | `[[02-SKILLS/AI/]]`, `[[05-CONFIGURATIONS/templates/skill-template.md]]`, `[[01-RULES/07-SCALABILITY-RULES.md]]` | `validate-frontmatter.sh`, `verify-constraints.sh`, `schema-validator.py` |
| `04-WORKFLOWS/n8n/` | `INFRA-001-Monitor-Salud-VPS.json`, `CLIENT-001-WhatsApp-RAG.json` | `[[02-SKILLS/N8N-PATTERNS/]]`, `[[01-RULES/05-CODE-PATTERNS-RULES.md]]`, `[[00-CONTEXT/facundo-infrastructure.md]]` | `check-wikilinks.sh`, `audit-secrets.sh`, JSON schema n8n |
| `05-CONFIGURATIONS/docker-compose/` | `vps1-n8n-uazapi.yml`, `vps2-crm-qdrant.yml`, `vps3-n8n-uazapi.yml` | `[[02-SKILLS/INFRAESTRUCTURA/docker-compose-networking.md]]`, `[[01-RULES/02-RESOURCE-GUARDRAILS.md]]` | `verify-constraints.sh` (C1/C2), `audit-secrets.sh` (C3) |
| `05-CONFIGURATIONS/terraform/modules/` | `qdrant-cluster/`, `openrouter-proxy/`, `backup-encrypted/` | `[[05-CONFIGURATIONS/terraform/modules/vps-base/main.tf]]`, `[[05-CONFIGURATIONS/templates/terraform-module-template/]]` | `tfsec`/`checkov`, `verify-constraints.sh` |
| `05-CONFIGURATIONS/pipelines/promptfoo/` | `config.yaml`, `test-cases/`, `assertions/` | `[[01-RULES/04-API-RELIABILITY-RULES.md]]`, `[[05-CONFIGURATIONS/validation/schemas/]]` | `schema-validator.py`, `integrity-check.yml` |
| `05-CONFIGURATIONS/environment/` | `.env.example`, `00-INDEX.md` | `[[01-RULES/03-SECURITY-RULES.md]]`, `[[02-SKILLS/INFRAESTRUCTURA/environment-variable-management.md]]` | `audit-secrets.sh` (zero hardcode) |

---

## 📊 Guía por Nivel de Experiencia

| Nivel | Rol en el Flujo | Qué Hace | Qué NO Hace |
|-------|----------------|----------|-------------|
| 👶 **Junior** | Solicitante & Validador Visual | Pide documento, copia/pega, ejecuta comandos de verificación post-guardado | Modifica constraints, omite validadores, hardcodea variables |
| 👨‍💻 **Intermedio** | Revisor & Integrador | Inspección fences, ejecuta validadores manualmente, ajusta límites C1/C2 según métricas reales | Ignora gate pre-entrega, mergea sin `validate-skill-integrity.sh` |
| 👨‍🔧 **Experto** | Arquitecto & Auditor | Extiende plantillas, modifica `skill-input-output.schema.json`, integra validadores en CI/CD, revisa `knowledge-graph.json` | Bypassea C4/C6 sin documentación, genera sin resolución canónica |

---

## 🔒 Normativas de Hardening Aplicadas en Cada Generación

| Constraint | Verificación Automática | Ejemplo de Implementación Requerida |
|------------|------------------------|-----------------------------------|
| **C1: RAM≤4GB** | `grep -E 'mem_limit|memory|shm_size|timeout'` | `mem_limit: 512m`, `EXECUTIONS_MAX_CONCURRENT=5` |
| **C2: 1vCPU** | `grep -E 'cpu_limit|cpus|nice|rate_limit'` | `cpu_quota: 100000`, `cpu_period: 100000` |
| **C3: Zero Hardcode** | `audit-secrets.sh` + regex placeholders | `process.env.API_KEY`, `${DB_PASS}`, `age -r` |
| **C4: tenant_id** | `check-rls.sh` + `grep -i 'tenant'` | `WHERE tenant_id = :tenant_id`, `X-Tenant-ID` header |
| **C5: SHA256 Audit** | `sha256sum` en artefactos + `audit_metadata` | `output_sha256: "a1b2c3..."`, backup encriptado |
| **C6: Cloud-Only** | `grep -i 'openrouter|api\.openai|cloud'` | `c6_exception_documented: true` si usa local |

---

## 🔗 Integración con Ecosistema

- **Desde `README.md` raíz**: Enlazar como `[[SDD-COLLABORATIVE-GENERATION.md]]` para onboarding de nuevos contributors/IA.
- **Desde `PROJECT_TREE.md`**: Agregar nota: `⚠️ Pendientes deben generarse vía flujo SDD Asistida (ver documento raíz)`.
- **Desde `knowledge-graph.json`**: Registrar este archivo como nodo `generation_workflow` con aristas a `template`, `validators`, `rules`.
- **Desde CI/CD**: `integrity-check.yml` ejecutará `validate-skill-integrity.sh` sobre este documento para mantener coherencia estructural.

---

## 🧪 Validación de Este Documento (Auto-Referencial)

```bash
# 1. Frontmatter obligatorio
./05-CONFIGURATIONS/validation/validate-frontmatter.sh ./SDD-COLLABORATIVE-GENERATION.md

# 2. Wikilinks canónicos
./05-CONFIGURATIONS/validation/check-wikilinks.sh ./SDD-COLLABORATIVE-GENERATION.md

# 3. Constraints C1-C6
./05-CONFIGURATIONS/validation/verify-constraints.sh ./SDD-COLLABORATIVE-GENERATION.md --strict

# 4. Schema (si contiene bloques JSON)
python3 05-CONFIGURATIONS/validation/schema-validator.py \
  05-CONFIGURATIONS/validation/schemas/skill-input-output.schema.json \
  ./SDD-COLLABORATIVE-GENERATION.md
```
**Criterio de Éxito**: Todos retornan `passed` / exit code `0`. Si alguno falla, este documento se considera inválido y debe regenerarse.

---

## 📝 Procedimiento de Actualización
1. Modificar estructura siguiendo `skill-template.md`
2. Ejecutar gate de validación interno (fase 2 del flujo)
3. Commit estructurado: `docs(SDD-GEN): actualizar flujo colaborativo para nuevos pendientes`
4. Push → CI/CD ejecuta `integrity-check.yml` automáticamente

---

> 📌 **Nota Final para IA**: Este documento es la **única fuente de verdad** para generar pendientes sin alucinaciones. Resolver todas las rutas desde `PROJECT_TREE.md`. Aplicar `skill-template.md` como estructura base. Ejecutar gate pre-entrega antes de cualquier output. Cero atajos. Cero asunciones. SDD hardening es no negociable.

**Última actualización**: `$(date -u +"%Y-%m-%dT%H:%M:%SZ")`  
**Versión**: `v1.0.0`  
**Validado contra**: `skill-input-output.schema.json` ✅  
**Checksum**: `$(sha256sum ./SDD-COLLABORATIVE-GENERATION.md 2>/dev/null | awk '{print $1}')`
