---
canonical_path: "/01-RULES/08-SKILLS-REFERENCE.md"
artifact_id: "skills-reference-canonical"
artifact_type: "governance_rule_set"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 01-RULES/08-SKILLS-REFERENCE.md --mode headless --json"
tier: 1
immutable: true
requires_human_approval_for_changes: true
related_files:
  - "[[00-STACK-SELECTOR.md]]"
  - "[[02-SKILLS/00-INDEX.md]]"
  - "[[06-PROGRAMMING/00-INDEX.md]]"
  - "[[GOVERNANCE-ORCHESTRATOR.md]]"
  - "[[05-CONFIGURATIONS/validation/norms-matrix.json]]"
  - "[[PROJECT_TREE.md]]"
checksum_sha256: "PENDING_GENERATION"
---

# 📄 01-RULES/08-SKILLS-REFERENCE.md – REGENERADO v3.0-SELECTIVE

> **Nota para principiantes:** Este documento es el "catálogo maestro de habilidades" de MANTIS AGENTIC. Conecta necesidades de negocio/dominio (`02-SKILLS/`) con implementaciones técnicas (`06-PROGRAMMING/`), garantizando que cada patrón siga las normas de gobernanza antes de usarse. Si eres nuevo, lee las secciones en orden. Si eres experto, salta al JSON final.  
>  
> **Para IAs:** Este es tu índice de descubrimiento de skills. **USAR SKILL NO MAPEADA O NO VALIDADA = RIESGO DE INTEGRACIÓN**. No inventes, no asumas, no omitas.


# 🧠 08-SKILLS-REFERENCE: Catálogo Canónico de Habilidades por Dominio

<!-- 
【PARA PRINCIPIANTES】¿Qué es este archivo?
Este documento es el "puente" entre el negocio y la técnica en MANTIS AGENTIC.
Define cómo descubrir, validar y mapear skills de dominio (IA, DB/RAG, Infra, etc.) 
a patrones de código implementables, respetando siempre las normas de gobernanza.

Si eres nuevo: lee en orden. 
Si ya conoces el proyecto: usa los wikilinks para ir directo a lo que necesitas.
-->

> **Instrucción crítica para la IA:** 
> Este documento es tu índice de descubrimiento de skills. 
> **USAR SKILL NO MAPEADA O NO VALIDADA = RIESGO DE INTEGRACIÓN**. 
> No inventes, no asumas, no omitas. Si algo no está claro, DETENER y preguntar.

---

## 【0】🎯 PROPÓSITO Y ALCANCE (Explicado para humanos)

<!-- 
【EDUCATIVO】Este documento responde: "¿Qué habilidades técnicas existen, dónde están, y cómo las uso correctamente?"
No es una lista de tutoriales. Es un sistema de trazabilidad que:
• Garantiza que cada skill de dominio tiene una implementación canónica en `06-PROGRAMMING/`
• Previene la creación de patrones duplicados o fuera de norma
• Exige que cada skill declare constraints, stack primario y perfil de validación
• Permite descubrimiento automatizado por agentes remotos sin ambigüedad
-->

### 0.1 Principios de Referencia de Skills

```
P1: Domain-First → El dominio de negocio dicta la skill; la skill dicta el stack técnico.
P2: Single Source of Truth → Cada skill vive en `02-SKILLS/` y referencia exactamente una implementación en `06-PROGRAMMING/`.
P3: Constraint Inheritance → Las constraints de la implementación se heredan automáticamente a la skill de dominio.
P4: Validation-Gate → Ninguna skill se integra sin pasar scoring del toolchain.
P5: Tiered Mapping → La complejidad de la skill determina si se entrega como documentación (Tier 1), código (Tier 2) o paquete (Tier 3).
```

---

## 【1】🔒 REGLAS INAMOVIBLES DE SKILLS (SKR-001 a SKR-010)

<!-- 
【EDUCATIVO】Estas 10 reglas son contractuales. 
Cualquier violación genera `blocking_issue` o `debt_technical_flag` en validación.
-->

### SKR-001: Mapeo One-to-One entre Dominio e Implementación

```
【REGLA SKR-001】Cada skill de dominio debe apuntar a exactamente una implementación canónica.

✅ Cumplimiento:
• Skill en `02-SKILLS/<dominio>/nombre-skill.md` → `implements: [[06-PROGRAMMING/<stack>/pattern.md]]`
• Si no existe implementación → crear siguiendo `skill-template.md`, actualizar `06-PROGRAMMING/00-INDEX.md`
• Nunca referenciar rutas relativas o archivos externos al repositorio

❌ Violación crítica:
• Skill sin campo `implements:` o con ruta inventada
• Múltiples implementaciones para la misma skill sin versionado claro
• Referenciar `../otra-carpeta` en lugar de wikilink canónico
```

### SKR-002: Constraint Inheritance Automática

```
【REGLA SKR-002】Las constraints aplicables se heredan desde `norms-matrix.json` según la carpeta de implementación.

✅ Cumplimiento:
• Extraer `constraints_allowed` y `constraints_mandatory` de `norms-matrix.json` para la ruta destino
• Declarar en frontmatter de la skill: `inherited_constraints: ["C3","C4","C5"]`
• Si la skill agrega constraints específicas, deben ser subconjunto de las permitidas

❌ Violación crítica:
• Skill que declara `C9` o constraint no mapeada en `norms-matrix.json`
• Omitir constraint mandatory (ej: `C4` en skill que accede a DB multi-tenant)
• Declarar `V1/V2/V3` en skill que apunta a stack no vectorial
```

### SKR-003: LANGUAGE LOCK Declaration Explícita

```
【REGLA SKR-003】Toda skill debe declarar explícitamente qué operadores y constraints están permitidos/prohibidos.

✅ Cumplimiento:
• Frontmatter: `language_lock: { allow: [...], deny: [...] }`
• Alinear con `01-RULES/language-lock-protocol.md` y `00-STACK-SELECTOR.md`
• Documentar justificación si se solicita excepción temporal (requiere aprobación humana)

❌ Violación crítica:
• Skill que sugiere usar `<->` en implementación Go o SQL genérico
• No declarar `deny_constraints` cuando la skill accede a dominios sensibles
• Excepción aplicada sin `approval_id` y `expiry_date` en metadatos
```

### SKR-004: Tiered Complexity Mapping

```
【REGLA SKR-004】La entrega de una skill está determinada por su nivel de madurez y complejidad operativa.

✅ Mapeo canónico:
| Complejidad Skill | Tier | Formato de Entrega | Ejemplo |
|------------------|------|-------------------|---------|
| Documentación/Guía | 1 | Markdown + diagramas | `02-SKILLS/INFRASTRUCTURA/vps-interconnection.md` |
| Código Reutilizable | 2 | Pattern + validation_command | `06-PROGRAMMING/go/webhook-validation.go.md` |
| Paquete Desplegable | 3 | ZIP + deploy.sh + manifest | `02-SKILLS/DEPLOYMENT/multi-channel-deployment.md` |

✅ Cumplimiento:
• Declarar `target_tier: 1|2|3` en frontmatter
• Entregar exactamente el formato especificado para el tier
• Incluir `validation_command` si tier ≥ 2

❌ Violación crítica:
• Entregar guía Tier 1 como código ejecutable sin validación
• Declarar `target_tier: 3` pero omitir `manifest.json` o `deploy.sh`
```

### SKR-005: Validation Pre-Integration Gate

```
【REGLA SKR-005】Ninguna skill se registra como "validada" sin pasar el toolchain completo.

✅ Cumplimiento:
• Ejecutar `orchestrator-engine.sh --file <skill_path> --json`
• Score ≥ umbral según tier, `blocking_issues: []`, `language_lock_violations: 0`
• Registrar resultado en `02-SKILLS/00-INDEX.md` con `validation_status: "passed"`

❌ Violación crítica:
• Marcar skill como `ready: true` sin ejecutar validación
• Ignorar `blocking_issues` por "urgencia de entrega"
• Actualizar índice sin sincronizar checksum del artefacto
```

### SKR-006: Cross-Domain Dependency Declaration

```
【REGLA SKR-006】Toda dependencia entre dominios debe declararse explícitamente y auditarse.

✅ Cumplimiento:
• Frontmatter: `depends_on: ["[[02-SKILLS/AI/qwen-integration.md]]", "[[06-PROGRAMMING/sql/rls.md]]"]`
• Validar que dependencias no forman ciclos circulares
• Documentar contrato de interfaz (input/output, headers, timeouts)

❌ Violación crítica:
• Skill que usa API externa sin declarar dependencia en `depends_on`
• Dependencia circular: A → B → A sin mecanismo de fallback
• No validar que dependencias externas cumplen `C3` (secrets) y `C7` (resiliencia)
```

### SKR-007: Versioning & Deprecation Cycle

```
【REGLA SKR-007】Las skills usan SemVer y siguen un ciclo de deprecación documentado.

✅ Cumplimiento:
• Frontmatter: `version: "1.2.0"`, `deprecation: { status: "active|deprecated|archived", replacement: "[[ruta]]" }`
• Cambios breaking → major version bump + guía de migración
• Skills deprecated permanecen 90 días accesibles, luego se archivan

❌ Violación crítica:
• Modificar skill sin actualizar `version` en frontmatter
• Eliminar skill activa sin período de deprecación o anuncio
• No proporcionar `replacement` para skills deprecated
```

### SKR-008: Human-in-the-Loop Approval

```
【REGLA SKR-008】Nuevas skills o cambios mayores requieren aprobación explícita de `governance-owner`.

✅ Cumplimiento:
• PR con checklist de validación completado
• Aprobación de al menos 2 revisores con rol `governance-owner`
• Merge solo tras `score >= umbral` y `blocking_issues: []`

❌ Violación crítica:
• Auto-merge sin revisión humana
• Bypass de CI/CD para "pruebas rápidas"
• No documentar decisión de aprobación en historial de commit
```

### SKR-009: Auditability & Usage Traceability

```
【REGLA SKR-009】El uso de cada skill debe ser trazable para auditoría y mejora continua.

✅ Cumplimiento:
• Log de invocación: `{"skill_id": "qwen-rag-integration", "invoked_by": "agent:deepseek-3.5", "timestamp": "...", "tier": 2}`
• Retención: 90 días debug, 7 años compliance
• Dashboard de uso: skills más invocadas, fallos, tiempo de validación

❌ Violación crítica:
• Skill usada sin registro de auditoría
• No correlacionar fallos con versión específica de skill
• Log que expone `prompt_hash` o datos sensibles del invocador
```

### SKR-010: Discovery Over Creation

```
【REGLA SKR-010】Siempre buscar en `02-SKILLS/00-INDEX.md` antes de crear nueva skill.

✅ Flujo de descubrimiento:
1. Consultar índice por dominio → `grep -r "webhook" 02-SKILLS/`
2. Si existe → validar que está `validation_status: "passed"`
3. Si no → crear siguiendo `skill-template.md`, actualizar índice, ejecutar validación
4. Documentar `created_for` y `use_cases` en frontmatter

❌ Violación crítica:
• Crear skill duplicada con nombre ligeramente distinto
• No actualizar `02-SKILLS/00-INDEX.md` tras añadir nueva skill
• Referenciar skill obsoleta sin verificar `deprecation.status`
```

---

## 【2】🗂️ CATÁLOGO DE DOMINIOS Y SKILLS CANÓNICAS

<!-- 
【EDUCATIVO】Mapeo oficial de dominios de negocio a rutas técnicas y constraints.
-->

| Dominio | Ruta Canónica | Stack Primario | Constraints Inheritadas | Validation Profile | Ejemplo de Skill |
|---------|--------------|---------------|------------------------|-------------------|-----------------|
| **IA / LLMs** | `02-SKILLS/AI/` | Python, TS, Go | C3, C4, C5, C8 | `tier2-code` | `qwen-integration.md` |
| **DB / RAG** | `02-SKILLS/BASE DE DATOS-RAG/` | Python, SQL, pgvector | C3, C4, C5, V1-V3 | `tier2-code` / `tier3-deploy` | `rag-query-with-tenant.md` |
| **Comunicaciones** | `02-SKILLS/COMUNICACION/` | TS, Bash, Go | C3, C4, C5, C7 | `tier2-code` | `whatsapp-rag-openrouter.md` |
| **Infraestructura** | `02-SKILLS/INFRASTRUCTURA/` | Bash, YAML, Terraform | C1, C3, C5, C7 | `tier1-doc` / `tier3-deploy` | `vps-interconnection.md` |
| **Seguridad** | `02-SKILLS/SEGURIDAD/` | Bash, Python | C3, C4, C5, C8 | `tier2-code` | `security-hardening-vps.md` |
| **Despliegue** | `02-SKILLS/DEPLOYMENT/` | Bash, YAML, Go | C1-C8 | `tier3-deploy` | `multi-channel-deployment.md` |
| **Corporativo** | `02-SKILLS/CORPORATE-KB/` | Markdown, YAML | C5, C6 | `tier1-doc` | `knowledge-base-template.md` |

> 💡 **Consejo para principiantes**: No busques "cómo hacer X". Busca "qué skill cubre X en `02-SKILLS/`". La skill ya contiene la implementación validada.

---

## 【3】🔗 INTEGRACIÓN CON PROGRAMMING Y VALIDACIÓN

<!-- 
【EDUCATIVO】Cómo se conecta una skill de dominio con su implementación técnica.
-->

### 3.1 Flujo de Integración Canónica

```mermaid
graph LR
    A[Negocio/Dominio] --> B[02-SKILLS/ skill.md]
    B --> C{Implementación existe?}
    C -->|Sí| D[06-PROGRAMMING/ pattern.md]
    C -->|No| E[Generar con skill-template.md]
    E --> D
    D --> F[Validar: orchestrator-engine.sh]
    F --> G{Pasa gate?}
    G -->|Sí| H[Actualizar 00-INDEX.md + 02-SKILLS/00-INDEX.md]
    G -->|No| I[Iterar corrección (máx 3)]
    H --> J[Entrega por Tier]
```

### 3.2 Mapeo de Constraints por Dominio (Resumen)

| Dominio | Constraints Mandatory | Prohibiciones Explícitas | Validador Principal |
|---------|----------------------|-------------------------|-------------------|
| IA/LLMs | C3, C4, C5, C8 | Hardcode de API keys, logs sin scrubbing | `audit-secrets.sh` |
| DB/RAG | C4, C5, V1 (si vector) | Queries sin `tenant_id`, índices sin justificación | `check-rls.sh`, `verify-constraints.sh` |
| Comunicaciones | C3, C4, C5, C7 | Webhooks sin firma, timeouts infinitos | `orchestrator-engine.sh --checks C3,C7` |
| Infraestructura | C1, C3, C5, C7 | Límites de recursos no declarados, secrets en Dockerfiles | `validate-frontmatter.sh`, `audit-secrets.sh` |
| Seguridad | C3, C4, C5, C8 | Patrones de detección obsoletos, logs expuestos | `audit-secrets.sh`, `orchestrator-engine.sh` |
| Despliegue | C1-C8 | Scripts no idempotentes, sin rollback | `packager-assisted.sh`, `orchestrator-engine.sh` |

---

## 【4】🧭 PROTOCOLO DE DESCUBRIMIENTO Y USO (PASO A PASO)

```
┌─────────────────────────────────────────────────────────┐
│ 【FASE 0】IDENTIFICAR DOMINIO Y NECESIDAD              │
├─────────────────────────────────────────────────────────┤
│ 1. Describir necesidad de negocio ("necesito RAG para WhatsApp") │
│ 2. Consultar 02-SKILLS/00-INDEX.md por dominio         │
│ 3. Verificar validation_status: "passed" y deprecation: "active" │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 1】RESOLVER STACK Y IMPLEMENTACIÓN              │
├─────────────────────────────────────────────────────────┤
│ 1. Leer campo implements: en skill → ruta de patrón     │
│ 2. Consultar 00-STACK-SELECTOR.md → stack permitido    │
│ 3. Cargar norms-matrix.json → constraints inheritadas  │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 2】VALIDACIÓN PRE-USO                           │
├─────────────────────────────────────────────────────────┤
│ 1. Ejecutar orchestrator-engine.sh --file <skill> --json│
│ 2. Verificar score ≥ umbral, blocking_issues: []       │
│ 3. Validar LANGUAGE LOCK con verify-constraints.sh     │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 3】INTEGRACIÓN Y ADAPTACIÓN                     │
├─────────────────────────────────────────────────────────┤
│ 1. Extender skill con extends: [[ruta-original]]       │
│ 2. Adaptar tenant_id, secrets, timeouts según contexto │
│ 3. Declarar depends_on si se añaden nuevas dependencias│
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 4】ENTREGA Y AUDITORÍA                          │
├─────────────────────────────────────────────────────────┤
│ 1. Validar artefacto final con toolchain completo      │
│ 2. Registrar uso en log de auditoría con skill_id      │
│ 3. Actualizar índices si hay versión nueva o deprecación│
└─────────────────────────────────────────────────────────┘
```

### 4.1 Ejemplo de Traza de Uso de Skill

```
【TRAZA DE USO DE SKILL】
Necesidad: "Integrar Qwen para generación de respuestas en WhatsApp"

Fase 0 - Descubrimiento:
  • Consultar 02-SKILLS/ → dominio: IA + Comunicaciones
  • Encontrar: [[02-SKILLS/AI/qwen-integration.md]] → validation_status: "passed" ✅
  • Encontrar: [[02-SKILLS/COMUNICACION/whatsapp-rag-openrouter.md]] → passed ✅

Fase 1 - Resolución:
  • Skill 1 implements: [[06-PROGRAMMING/python/qwen-client.md]] → Python, C3,C4,C5,C8
  • Skill 2 implements: [[06-PROGRAMMING/javascript/whatsapp-webhook.ts.md]] → TS, C3,C4,C5,C7

Fase 2 - Validación:
  • orchestrator-engine.sh --file qwen-client.md → score=38, passed=true ✅
  • verify-constraints.sh --check-language-lock → passed ✅

Fase 3 - Integración:
  • Crear skill nueva: [[02-SKILLS/COMUNICACION/qwen-whatsapp-rag.md]]
  • Frontmatter: extends: [[qwen-integration.md]], extends: [[whatsapp-rag-openrouter.md]]
  • Adaptar tenant_id injection, rotación de API key, fallback a modelo secundario ✅

Fase 4 - Entrega:
  • Validar artefacto → score=42, blocking_issues=[] ✅
  • Log auditoría: {"skill_id": "qwen-whatsapp-rag", "version": "1.0.0", "invoked_by": "agent:facundo"} ✅

Resultado: ✅ Skill integrada, validada y auditada sin reinventar patrones.
```

---

## 【5】📚 GLOSARIO PARA PRINCIPIANTES

| Término | Significado simple | Ejemplo |
|---------|-------------------|---------|
| **Skill** | Patrón reutilizable que resuelve una necesidad de dominio específico | `qwen-integration.md`, `vps-interconnection.md` |
| **Domain Mapping** | Conexión entre necesidad de negocio y ruta técnica en `02-SKILLS/` | IA → `02-SKILLS/AI/`, DB → `02-SKILLS/BASE DE DATOS-RAG/` |
| **Constraint Inheritance** | Las reglas de seguridad/calidad se heredan automáticamente desde `norms-matrix.json` | Skill de DB hereda `C4` y `V1` |
| **Tiered Mapping** | Nivel de entrega según complejidad y madurez | Guía=1, Código=2, Paquete=3 |
| **Validation Gate** | Paso automático que bloquea skills no conformes | `orchestrator-engine.sh` retorna `blocking_issues` |
| **Deprecation Cycle** | Proceso controlado para retirar skills obsoletas | `status: "deprecated"`, 90 días gracia, `replacement` obligatoria |
| **Audit Trace** | Registro inmutable de uso de skill para compliance | JSON con `skill_id`, `version`, `timestamp`, `invoked_by` |
| **Discovery Over Creation** | Buscar antes de crear, evitar duplicados | `grep -r "keyword" 02-SKILLS/` antes de generar nuevo archivo |

---

## 【6】🧪 SANDBOX DE PRUEBA (OPCIONAL)

```
【TEST MODE: SKILLS-REFERENCE VALIDATION】
Prompt de prueba: "Implementar skill de backup encriptado para VPS de cliente agrícola"

Respuesta esperada de la IA:
1. Consultar 02-SKILLS/ → dominio: Infraestructura / Seguridad
2. Encontrar: [[02-SKILLS/SEGURIDAD/backup-encryption.md]] → validar status y constraints
3. Mapear a implementación: [[05-CONFIGURATIONS/scripts/backup-mysql.sh]] o crear nueva
4. Aplicar SKR-002 a SKR-010: constraints inheritadas, LANGUAGE LOCK, tier mapping, validation
5. Ejecutar toolchain: audit-secrets.sh → verify-constraints.sh → orchestrator-engine.sh
6. Si pasa → registrar en índice, entregar con validation_command + checksum
7. Si falla → iterar corrección, no entregar sin gate passed

Si la IA crea skill desde cero sin buscar en índice, omite constraints, o entrega sin validación → FALLA DE SKILL.
```

---

## 【7】🔗 REFERENCIAS CANÓNICAS (WIKILINKS)

- `[[00-STACK-SELECTOR]]` → Motor de decisión de stack
- `[[02-SKILLS/00-INDEX.md]]` → Índice agregador de skills por dominio
- `[[06-PROGRAMMING/00-INDEX.md]]` → Implementaciones técnicas canónicas
- `[[GOVERNANCE-ORCHESTRATOR]]` → Tiers y validación
- `[[05-CONFIGURATIONS/validation/norms-matrix.json]]` → Mapeo de constraints por carpeta
- `[[01-RULES/language-lock-protocol.md]]` → Aislamiento de operadores
- `[[PROJECT_TREE]]` → Mapa canónico de rutas
- `[[TOOLCHAIN-REFERENCE]]` → Catálogo de herramientas de validación

---

## 【8】📦 METADATOS DE EXPANSIÓN (PARA FUTURAS VERSIONES)

```json
{
  "expansion_registry": {
    "new_skill_domain": {
      "requires_files_update": [
        "02-SKILLS/: create domain folder with 00-INDEX.md",
        "01-RULES/08-SKILLS-REFERENCE.md: add domain to catalog table",
        "00-STACK-SELECTOR.md: add routing rules for domain patterns",
        "05-CONFIGURATIONS/validation/norms-matrix.json: map constraints",
        "Human approval required: true"
      ],
      "backward_compatibility": "new domains must not break existing skill discovery or constraint inheritance"
    },
    "new_skill_versioning_policy": {
      "requires_files_update": [
        "01-RULES/08-SKILLS-REFERENCE.md: update SKR-007 if deprecation cycle changes",
        "CI/CD pipelines: enforce semver and migration guide requirement",
        "Human approval required: true"
      ],
      "backward_compatibility": "new versioning rules must provide grace period for existing skills"
    }
  },
  "compatibility_rule": "Nuevas skills no deben invalidar integraciones existentes que cumplan SKR-001 a SKR-010. Cambios breaking requieren major version bump, guía de migración y aprobación humana explícita."
}
```

---

<!-- 
═══════════════════════════════════════════════════════════
🤖 SECCIÓN PARA IA: ÁRBOL JSON ENRIQUECIDO
═══════════════════════════════════════════════════════════
Esta sección contiene metadatos estructurados para consumo automático por agentes de IA.
No está diseñada para lectura humana directa. Los humanos deben usar las secciones 【1】-【8】.

Formato: JSON válido, con comentarios explicativos en claves "doc_*".
Prioridad de ejecución: Las reglas se aplican en orden SKR-001 → SKR-010.
Dependencias: Cada nodo declara sus archivos requeridos y sus efectos colaterales.
═══════════════════════════════════════════════════════════
-->

```json
{
  "skills_reference_metadata": {
    "version": "3.0.0-SELECTIVE",
    "canonical_path": "/01-RULES/08-SKILLS-REFERENCE.md",
    "artifact_type": "governance_rule_set",
    "immutable": true,
    "requires_human_approval_for_changes": true,
    "llm_optimizations": {
      "oriental_models_friendly": true,
      "delimiters_used": ["【】", "┌─┐", "▼", "✅/❌/🔧"],
      "numbered_sequences": true,
      "stop_conditions_explicit": true
    }
  },
  
  "rules_catalog": {
    "SKR-001": {"title": "One-to-One Domain-to-Implementation Mapping", "constraint": "C5", "priority": "critical", "blocking_if_violated": true, "validation_tool": "index consistency check"},
    "SKR-002": {"title": "Constraint Inheritance", "constraint": "C4, C5", "priority": "critical", "blocking_if_violated": true, "validation_tool": "norms-matrix.json subset validation"},
    "SKR-003": {"title": "LANGUAGE LOCK Declaration", "constraint": "C5", "priority": "critical", "blocking_if_violated": true, "validation_tool": "verify-constraints.sh --check-language-lock"},
    "SKR-004": {"title": "Tiered Complexity Mapping", "constraint": "C6", "priority": "high", "blocking_if_violated": true, "validation_tool": "GOVERNANCE-ORCHESTRATOR.md tier check"},
    "SKR-005": {"title": "Validation Pre-Integration Gate", "constraint": "C6", "priority": "critical", "blocking_if_violated": true, "validation_tool": "orchestrator-engine.sh --mode headless"},
    "SKR-006": {"title": "Cross-Domain Dependency Declaration", "constraint": "C5, C7", "priority": "high", "blocking_if_violated": false, "validation_tool": "dependency graph cycle detection"},
    "SKR-007": {"title": "Versioning & Deprecation Cycle", "constraint": "C5", "priority": "medium", "blocking_if_violated": false, "validation_tool": "frontmatter semver + deprecation field check"},
    "SKR-008": {"title": "Human-in-the-Loop Approval", "constraint": "C6", "priority": "high", "blocking_if_violated": true, "validation_tool": "PR review + governance-owner sign-off"},
    "SKR-009": {"title": "Auditability & Usage Traceability", "constraint": "C8", "priority": "high", "blocking_if_violated": false, "validation_tool": "structured log validation"},
    "SKR-010": {"title": "Discovery Over Creation", "constraint": "C5, C6", "priority": "medium", "blocking_if_violated": false, "validation_tool": "02-SKILLS/00-INDEX.md search verification"}
  },
  
  "domain_catalog": {
    "ia_llms": {"path": "02-SKILLS/AI/", "primary_stack": ["python", "go", "typescript"], "mandatory_constraints": ["C3", "C4", "C5", "C8"], "validation_profile": "tier2-code"},
    "db_rag": {"path": "02-SKILLS/BASE DE DATOS-RAG/", "primary_stack": ["python", "sql", "postgresql-pgvector"], "mandatory_constraints": ["C3", "C4", "C5", "V1"], "validation_profile": "tier2-code"},
    "comunicaciones": {"path": "02-SKILLS/COMUNICACION/", "primary_stack": ["typescript", "bash", "go"], "mandatory_constraints": ["C3", "C4", "C5", "C7"], "validation_profile": "tier2-code"},
    "infraestructura": {"path": "02-SKILLS/INFRASTRUCTURA/", "primary_stack": ["bash", "yaml", "hcl_terraform"], "mandatory_constraints": ["C1", "C3", "C5", "C7"], "validation_profile": "tier1-doc"},
    "seguridad": {"path": "02-SKILLS/SEGURIDAD/", "primary_stack": ["bash", "python"], "mandatory_constraints": ["C3", "C4", "C5", "C8"], "validation_profile": "tier2-code"},
    "despliegue": {"path": "02-SKILLS/DEPLOYMENT/", "primary_stack": ["bash", "yaml", "go"], "mandatory_constraints": ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8"], "validation_profile": "tier3-deploy"},
    "corporativo": {"path": "02-SKILLS/CORPORATE-KB/", "primary_stack": ["markdown", "yaml"], "mandatory_constraints": ["C5", "C6"], "validation_profile": "tier1-doc"}
  },
  
  "validation_integration": {
    "orchestrator-engine.sh": {"purpose": "Scoring integral y validación final de skill", "flags": ["--file", "--mode", "--json", "--checks"], "exit_codes": {"0": "passed", "1": "failed"}},
    "verify-constraints.sh": {"purpose": "Validación de constraints y LANGUAGE LOCK", "flags": ["--file", "--check-language-lock", "--json"], "exit_codes": {"0": "compliant", "1": "violation"}},
    "check-rls.sh": {"purpose": "Validación de tenant isolation en skills DB/RAG", "flags": ["--file", "--strict", "--json"], "exit_codes": {"0": "compliant", "1": "violation"}},
    "validate-frontmatter.sh": {"purpose": "Validación de estructura YAML y campos de skill", "flags": ["--file", "--level", "--json"], "exit_codes": {"0": "valid", "1": "invalid"}}
  },
  
  "dependency_graph": {
    "critical_infrastructure": [
      {"file": "02-SKILLS/00-INDEX.md", "purpose": "Índice agregador de skills por dominio", "load_order": 1},
      {"file": "06-PROGRAMMING/00-INDEX.md", "purpose": "Implementaciones técnicas canónicas", "load_order": 2},
      {"file": "05-CONFIGURATIONS/validation/norms-matrix.json", "purpose": "Mapeo de constraints por carpeta", "load_order": 3},
      {"file": "01-RULES/language-lock-protocol.md", "purpose": "Aislamiento de operadores", "load_order": 4}
    ],
    "skill_templates": [
      {"file": "05-CONFIGURATIONS/templates/skill-template.md", "purpose": "Plantilla base para nuevas skills", "load_order": 1},
      {"file": "GOVERNANCE-ORCHESTRATOR.md", "purpose": "Tiers y formatos de entrega", "load_order": 2}
    ],
    "validation_toolchain": [
      {"file": "05-CONFIGURATIONS/validation/orchestrator-engine.sh", "purpose": "Motor principal de validación", "load_order": 1},
      {"file": "05-CONFIGURATIONS/validation/audit-secrets.sh", "purpose": "Detección de secrets en skills", "load_order": 2},
      {"file": "05-CONFIGURATIONS/validation/packager-assisted.sh", "purpose": "Empaquetado de skills Tier 3", "load_order": 3}
    ]
  },
  
  "human_readable_errors": {
    "skill_mapping_missing": "Skill '{skill_id}' no declara campo implements: o ruta no canónica. Añadir implements: [[06-PROGRAMMING/<stack>/pattern.md]].",
    "constraint_inheritance_violation": "Skill '{skill_id}' declara constraints no permitidas para stack '{stack}'. Consulte [[norms-matrix.json]].",
    "language_lock_undeclared": "Skill '{skill_id}' no declara language_lock. Añadir allow/deny según [[language-lock-protocol.md]].",
    "tier_mismatch": "Skill '{skill_id}' declara target_tier: {declared} pero formato de entrega corresponde a Tier {actual}. Consulte [[GOVERNANCE-ORCHESTRATOR.md]].",
    "validation_bypass": "Skill '{skill_id}' marcada como passed sin ejecutar orchestrator-engine.sh. Ejecutar validación antes de merge.",
    "dependency_undeclared": "Skill '{skill_id}' usa '{dep}' sin declararlo en depends_on. Añadir dependencia explícita para auditoría.",
    "versioning_violation": "Modificación en skill '{skill_id}' sin actualizar version en frontmatter o sin guía de migración para cambios breaking.",
    "discovery_skipped": "Skill nueva '{skill_id}' creada sin consultar 02-SKILLS/00-INDEX.md. Verificar duplicados antes de crear."
  },
  
  "expansion_hooks": {
    "new_skill_domain": {
      "requires_files_update": [
        "02-SKILLS/: create folder with 00-INDEX.md",
        "01-RULES/08-SKILLS-REFERENCE.md: add to domain_catalog",
        "norms-matrix.json: map constraints",
        "00-STACK-SELECTOR.md: add routing",
        "Human approval required: true"
      ],
      "backward_compatibility": "new domains must not break existing discovery or constraint inheritance"
    },
    "new_skill_validation_tool": {
      "requires_files_update": [
        "05-CONFIGURATIONS/validation/: create tool",
        "01-RULES/08-SKILLS-REFERENCE.md: integrate in validation_integration",
        "CI/CD: add to skill validation pipeline",
        "Human approval required: true"
      ],
      "backward_compatibility": "new tools must support existing skill formats via optional flags"
    }
  },
  
  "validation_metadata": {
    "orchestrator_compatibility": ">=3.0.0-SELECTIVE",
    "schema_version": "skills-reference.v1.json",
    "checksum_algorithm": "SHA256",
    "audit_log_format": "JSON Lines with RFC3339 timestamps",
    "pii_scrubbing": "enabled for all logs (C3 + C8 compliance)",
    "reproducibility_guarantee": "Any skill discovery and integration can be reproduced identically using this reference + 02-SKILLS/00-INDEX.md"
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
yq eval '.canonical_path' 01-RULES/08-SKILLS-REFERENCE.md | grep -q "/01-RULES/08-SKILLS-REFERENCE.md" && echo "✅ Ruta canónica correcta"

# 2. Constraints mapeadas
yq eval '.constraints_mapped | length' 01-RULES/08-SKILLS-REFERENCE.md | grep -q "8" && echo "✅ 8 constraints declaradas"

# 3. Reglas presentes
grep -c "SKR-0[0-9][0-9]:" 01-RULES/08-SKILLS-REFERENCE.md | awk '{if($1==10) print "✅ 10 reglas de skills"; else print "⚠️ Faltan reglas"}'

# 4. Catálogo de dominios presente
grep -q "🗂️ CATÁLOGO DE DOMINIOS" 01-RULES/08-SKILLS-REFERENCE.md && echo "✅ Catálogo de dominios presente"

# 5. JSON válido
tail -n +$(grep -n '```json' 01-RULES/08-SKILLS-REFERENCE.md | tail -1 | cut -d: -f1) 01-RULES/08-SKILLS-REFERENCE.md | sed -n '/```json/,/```/p' | sed '1d;$d' | jq empty && echo "✅ JSON parseable"

# 6. Wikilinks canónicos
for link in $(grep -oE '\[\[[^]]+\]\]' 01-RULES/08-SKILLS-REFERENCE.md | tr -d '[]' | sort -u); do
  [ -f "${link#//}" ] || echo "⚠️ Wikilink roto: $link"
done
```
````
> 🎯 **Mensaje final para el lector humano**:  
> Este catálogo es tu brújula de dominio. No es estático: evoluciona con las necesidades.  
> **Dominio → Skill → Implementación → Validación → Entrega**.  
> Si sigues ese flujo, nunca reinventarás lo que ya existe ni entregarás patrones no validados.  
> La gobernanza no es una carga. Es la libertad de escalar sin miedo a romper.  
