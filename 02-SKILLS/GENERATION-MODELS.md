---
canonical_path: "/02-SKILLS/GENERATION-MODELS.md"
artifact_id: "generation-models-canonical"
artifact_type: "governance_catalog"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C3", "C5", "C6", "C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 02-SKILLS/GENERATION-MODELS.md --mode headless --json"
tier: 1
immutable: true
requires_human_approval_for_changes: true
related_files:
  - "[[02-SKILLS/00-INDEX.md]]"
  - "[[02-SKILLS/AI/00-INDEX.md]]"
  - "[[01-RULES/08-SKILLS-REFERENCE.md]]"
  - "[[05-CONFIGURATIONS/validation/norms-matrix.json]]"
  - "[[GOVERNANCE-ORCHESTRATOR.md]]"
checksum_sha256: "PENDING_GENERATION"
---

# 📄 02-SKILLS/GENERATION-MODELS.md – REGENERADO COMPLETO v3.0-SELECTIVE

> **Nota para principiantes:** Este documento es el **"catálogo de modelos de generación"** para MANTIS AGENTIC. Define QUÉ modelos de IA pueden usarse para generar código, documentación o configuraciones, y CÓMO validar que sus outputs cumplen con las normas de gobernanza. Si eres nuevo, lee las secciones en orden. Si eres experto, salta al JSON final.  
>  
> **Para IAs:** Este es tu contrato de generación. **GENERAR CON MODELO NO APROBADO O SIN VALIDACIÓN = DEUDA TÉCNICA AUTOMÁTICA**. No inventes, no asumas, no omitas.


# 🤖 GENERATION-MODELS: Catálogo de Modelos de IA para Generación Asistida

<!-- 
【PARA PRINCIPIANTES】¿Qué es este archivo?
Este documento es el "menú de modelos" de MANTIS AGENTIC.
Define QUÉ modelos de IA pueden usarse para generar código, documentación o configuraciones,
y CÓMO validar que sus outputs cumplen con las normas de gobernanza (C1-C8).

Si eres nuevo: lee en orden. 
Si ya conoces el proyecto: usa los wikilinks para ir directo al modelo que necesitas.
-->

> **Instrucción crítica para la IA:** 
> Este documento es tu contrato de generación. 
> **GENERAR CON MODELO NO APROBADO O SIN VALIDACIÓN = DEUDA TÉCNICA AUTOMÁTICA**. 
> No inventes, no asumas, no omitas. Si algo no está claro, DETENER y preguntar.

---

## 【0】🎯 PROPÓSITO Y ALCANCE (Explicado para humanos)

<!-- 
【EDUCATIVO】Este documento responde: "¿Qué modelo de IA debo usar para generar código Go seguro?"
No es una lista de preferencias. Es un sistema de selección que:
• Mapea tareas de generación (código, docs, config) a modelos aprobados
• Define constraints críticas para cada modelo (C3 para secrets, C4 para tenant isolation)
• Proporciona comandos de validación automática para outputs generados
• Sirve como fuente de verdad para agents remotos que consumen `RAW_URLS_INDEX.md`
-->

### 0.1 Principios de Selección de Modelos

```
P1: Task-First → La tarea de generación dicta el modelo, no la preferencia personal.
P2: Constraint-Aware → Cada modelo debe cumplir constraints específicas según el dominio de output.
P3: Validation-Required → Todo output generado debe validarse con `orchestrator-engine.sh` antes de integrarse.
P4: LANGUAGE LOCK Respect → Modelos que generan código deben respetar aislamiento de operadores por lenguaje.
P5: Cost-Optimized → Preferir modelos de bajo coste para tareas simples, reservar modelos premium para razonamiento complejo.
```

### 0.2 Tabla Maestra de Modelos de Generación

| Modelo | Proveedor | Tareas Recomendadas | Constraints Críticas | Coste Relativo | Wikilink Canónico |
|--------|-----------|-------------------|-------------------|---------------|-----------------|
| **Qwen 2.5-72B** | Alibaba Cloud | Código Go/Python, documentación técnica, configs YAML | C3,C5,C6 | 💰 Bajo | `[[02-SKILLS/AI/qwen-integration.md]]` |
| **DeepSeek R1** | DeepSeek | Razonamiento complejo, arquitectura de sistemas, debugging | C3,C5,C6,C7 | 💰💰 Medio | `[[02-SKILLS/AI/deepseek-integration.md]]` |
| **GPT-4o** | OpenAI | Generación de prompts, análisis de negocio, outputs estructurados JSON | C3,C5,C8 | 💰💰💰 Alto | `[[02-SKILLS/AI/gpt-integration.md]]` |
| **Claude 3.5 Sonnet** | Anthropic | Documentación ejecutiva, revisión de código, compliance | C3,C5,C8 | 💰💰💰 Alto | `[[02-SKILLS/AI/claude-integration.md]]` |
| **Llama 3.1-70B** | Meta (local) | Generación offline, prototipado rápido, testing de prompts | C3,C5,C6 | 💰 Muy bajo | `[[02-SKILLS/AI/llama-integration.md]]` |
| **Gemini 1.5 Pro** | Google | Multimodal (texto+imagen), análisis de documentos PDF/OCR | C3,C5,C8 | 💰💰 Medio | `[[02-SKILLS/AI/gemini-integration.md]]` |
| **Minimax** | Minimax | Contexto ultra-largo (~1M tokens), procesamiento iterativo de docs grandes | C3,C5,C6 | 💰💰 Medio | `[[02-SKILLS/AI/minimax-integration.md]]` |

> 💡 **Consejo para principiantes**: No elijas modelo por "el más potente". Elige por tarea + constraint + coste. Qwen es excelente para código, DeepSeek para razonamiento, GPT-4o para JSON estructurado.

---

## 【1】🔐 MODELOS APROBADOS POR DOMINIO DE GENERACIÓN

<!-- 
【EDUCATIVO】Cada dominio de generación tiene modelos recomendados y constraints específicas.
-->

### 1.1 Generación de Código (Go, Python, Bash, SQL, TS)

```
【PROPÓSITO】Generar código fuente que cumpla con patrones canónicos, constraints de seguridad y LANGUAGE LOCK.

【MODELOS RECOMENDADOS】
• **Qwen 2.5-72B** (prioritario): Excelente en código, bajo coste, contexto largo (128K).
• **DeepSeek R1** (para razonamiento complejo): Cuando se necesita arquitectura de sistemas o debugging avanzado.
• **Llama 3.1-70B** (offline/testing): Para prototipado rápido sin dependencia de API externa.

【CONSTRAINTS CRÍTICAS】
• **C3 (Zero Secrets)**: El modelo NUNCA debe generar código con API keys hardcodeadas. Validar con `audit-secrets.sh`.
• **C4 (Tenant Isolation)**: Si el código accede a datos, debe incluir `WHERE tenant_id = $1`. Validar con `check-rls.sh`.
• **C5 (Structural Contract)**: El código debe seguir estructura SDD: frontmatter, secciones canónicas, wikilinks absolutos.
• **LANGUAGE LOCK**: El modelo debe respetar operadores permitidos por lenguaje (ej: no `<->` en Go). Validar con `verify-constraints.sh --check-language-lock`.

【COMANDO DE VALIDACIÓN TÍPICO】
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file generated-code.md --checks C3,C4,C5 --json

【EJEMPLO DE PROMPT CANÓNICO】
"Genera un handler de webhook en Go que:
1. Valide firma HMAC (C3)
2. Inyecte tenant_id desde header X-Tenant-ID (C4)
3. Siga estructura SDD con frontmatter válido (C5)
4. Respete LANGUAGE LOCK: cero operadores pgvector en Go
5. Incluya ≥10 ejemplos ✅/❌/🔧
6. Retorne validation_command ejecutable"

【CHECKLIST POST-GENERACIÓN】
- [ ] Ejecutar `audit-secrets.sh` → 0 secrets detectados
- [ ] Ejecutar `check-rls.sh` (si SQL) → queries con tenant_id
- [ ] Ejecutar `verify-constraints.sh --check-language-lock` → 0 violaciones
- [ ] Ejecutar `orchestrator-engine.sh` → score >= 30, blocking_issues == []
```

### 1.2 Generación de Documentación Técnica

```
【PROPÓSITO】Generar documentación (README, guías, specs) que sea clara, validable y trazable.

【MODELOS RECOMENDADOS】
• **Qwen 2.5-72B**: Excelente en español, estructura técnica, bajo coste.
• **Claude 3.5 Sonnet**: Para documentación ejecutiva o compliance-heavy.
• **GPT-4o**: Para outputs JSON estructurados o integración con herramientas externas.

【CONSTRAINTS CRÍTICAS】
• **C5 (Structural Contract)**: Frontmatter válido, wikilinks canónicos, secciones en orden SDD.
• **C6 (Verifiable Execution)**: Incluir `validation_command` ejecutable y `prompt_hash` para reproducibilidad.
• **C8 (Observability)**: Logging estructurado si la doc incluye ejemplos de código con logs.

【COMANDO DE VALIDACIÓN TÍPICO】
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file generated-doc.md --checks C5,C6 --json

【EJEMPLO DE PROMPT CANÓNICO】
"Genera documentación para skill de integración WhatsApp-RAG que:
1. Siga estructura SDD: Propósito → Implementación → Ejemplos → Validación → Referencias
2. Use wikilinks canónicos: [[02-SKILLS/COMUNICACION/whatsapp-rag-openrouter.md]]
3. Incluya frontmatter con canonical_path, constraints_mapped, validation_command
4. Añada ≥10 ejemplos ✅/❌/🔧 de uso real
5. Documente constraints críticas: C3 (secrets), C4 (tenant isolation)"

【CHECKLIST POST-GENERACIÓN】
- [ ] Frontmatter YAML válido con campos obligatorios
- [ ] Wikilinks absolutos (no relativos)
- [ ] validation_command ejecutable y verificable
- [ ] Score >= 15 (Tier 1) o >= 30 (Tier 2)
```

### 1.3 Generación de Configuración (YAML, JSON, Docker, Terraform)

```
【PROPÓSITO】Generar archivos de configuración que sean seguros, idempotentes y validables.

【MODELOS RECOMENDADOS】
• **Qwen 2.5-72B**: Excelente en YAML/JSON, bajo coste.
• **DeepSeek R1**: Para configuraciones complejas con dependencias cruzadas.
• **Llama 3.1-70B**: Para testing offline de configs sin exponer secrets.

【CONSTRAINTS CRÍTICAS】
• **C3 (Zero Secrets)**: NUNCA generar configs con valores reales de secrets. Usar placeholders: `${VAR:?missing}`.
• **C1 (Resource Limits)**: Incluir límites de CPU/memoria en Docker/Terraform.
• **C5 (Structural Contract)**: Schema JSON/YAML válido, campos obligatorios presentes.
• **C7 (Resilience)**: Configs deben soportar fallback y graceful degradation.

【COMANDO DE VALIDACIÓN TÍPICO】
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file generated-config.yaml --checks C1,C3,C5 --json

【EJEMPLO DE PROMPT CANÓNICO】
"Genera docker-compose.yml para servicio de RAG que:
1. Use variables de entorno para secrets: ${QDRANT_API_KEY:?missing}
2. Incluya resource limits: mem_limit: 512M, cpus: '0.5'
3. Siga schema YAML válido con campos obligatorios
4. Soporte --dry-run para validación sin despliegue
5. Documente constraints aplicadas: C1, C3, C5"

【CHECKLIST POST-GENERACIÓN】
- [ ] Cero secrets hardcodeados (validar con `audit-secrets.sh`)
- [ ] Límites de recursos declarados (C1)
- [ ] Schema YAML/JSON válido (validar con `schema-validator.py`)
- [ ] Soporte para --dry-run o idempotencia
```

---

## 【2】🧭 PROTOCOLO DE GENERACIÓN Y VALIDACIÓN (PASO A PASO)

<!-- 
【EDUCATIVO】Flujo determinista para generar y validar outputs con modelos de IA.
-->

```
┌─────────────────────────────────────────────────────────┐
│ 【PASO 1】IDENTIFICAR TAREA Y DOMINIO                  │
├─────────────────────────────────────────────────────────┤
│ ¿Qué necesitas generar?                                │
│ • Código Go/Python → Sección 【1.1】                   │
│ • Documentación técnica → Sección 【1.2】              │
│ • Configuración YAML/JSON → Sección 【1.3】            │
│ • Otro → Consultar tabla maestra en 【0.2】            │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【PASO 2】SELECCIONAR MODELO APROBADO                  │
├─────────────────────────────────────────────────────────┤
│ Consultar tabla maestra:                               │
│ • Tarea + constraints + coste → modelo recomendado     │
│ • Ej: "Código Go seguro + bajo coste" → Qwen 2.5-72B  │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【PASO 3】CONSTRUIR PROMPT CANÓNICO                    │
├─────────────────────────────────────────────────────────┤
│ Usar plantilla de prompt canónico del dominio:         │
│ • Incluir constraints explícitas (C3, C4, C5, etc.)    │
│ • Especificar formato de output (SDD, JSON, YAML)      │
│ • Solicitar validation_command ejecutable              │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【PASO 4】GENERAR Y VALIDAR AUTOMÁTICAMENTE            │
├─────────────────────────────────────────────────────────┤
│ 1. Ejecutar modelo con prompt canónico                 │
│ 2. Guardar output en archivo con extensión correcta    │
│ 3. Ejecutar: orchestrator-engine.sh --file <output> --json│
│ 4. Verificar: score >= umbral, blocking_issues == []   │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【PASO 5】INTEGRAR O ITERAR                            │
├─────────────────────────────────────────────────────────┤
│ Si validación pasa → integrar en repositorio           │
│ Si validación falla → iterar corrección (máx 3 intentos)│
│ Registrar log de auditoría con prompt_hash, tenant_id  │
└─────────────────────────────────────────────────────────┘
```

### 2.1 Ejemplo de Generación End-to-End

```
【EJEMPLO: Generar handler de webhook en Go】
Tarea: "Necesito un handler de webhook seguro en Go para WhatsApp"

Paso 1 - Identificar dominio:
  • Generación de código Go → Sección 【1.1】 ✅

Paso 2 - Seleccionar modelo:
  • Tabla maestra: Qwen 2.5-72B (código Go, bajo coste) ✅

Paso 3 - Construir prompt canónico:
  • "Genera handler de webhook en Go que:
    1. Valide firma HMAC (C3)
    2. Inyecte tenant_id desde header X-Tenant-ID (C4)
    3. Siga estructura SDD con frontmatter válido (C5)
    4. Respete LANGUAGE LOCK: cero operadores pgvector en Go
    5. Incluya ≥10 ejemplos ✅/❌/🔧
    6. Retorne validation_command ejecutable" ✅

Paso 4 - Generar y validar:
  • Ejecutar Qwen con prompt → guardar en `webhook-handler.go.md`
  • Ejecutar: `orchestrator-engine.sh --file webhook-handler.go.md --checks C3,C4,C5 --json`
  • Resultado: score=38, passed=true, blocking_issues=[] ✅

Paso 5 - Integrar:
  • Commit con mensaje estructurado SDD
  • Registrar log de auditoría: {"event":"code_generated","model":"qwen-2.5-72b","prompt_hash":"sha256:abc123"}

Resultado: ✅ Handler de webhook generado, validado y listo para integración.
```

---

## 【3】📚 GLOSARIO PARA PRINCIPIANTES


<!-- 
【EDUCATIVO】Términos técnicos explicados en lenguaje simple.
-->

| Término | Significado simple | Ejemplo |
|---------|-------------------|---------|
| **Task-First** | Elegir modelo según la tarea, no por preferencia personal | Código Go → Qwen, Razonamiento complejo → DeepSeek |
| **Constraint-Aware** | Cada modelo debe cumplir reglas específicas según el output | Código → C3 (secrets), C4 (tenant), C5 (estructura) |
| **Validation-Required** | Todo output generado debe validarse antes de usarse | Ejecutar `orchestrator-engine.sh` antes de commitear |
| **LANGUAGE LOCK** | Regla que prohíbe ciertos operadores en ciertos lenguajes | No usar `<->` en Go, solo en `postgresql-pgvector/` |
| **Cost-Optimized** | Usar el modelo más barato que cumpla la tarea | Qwen para código simple, GPT-4o solo si es necesario |
| **prompt_hash** | SHA256 del prompt original para reproducibilidad forense | `prompt_hash: "sha256:abc123..."` en frontmatter |
| **validation_command** | Comando ejecutable para validar el output generado | `bash .../orchestrator-engine.sh --file <ruta> --json` |
| **blocking_issue** | Error que impide la integración hasta que se corrige | `C3_VIOLATION: API key hardcodeada` |

---

## 【4】🔗 REFERENCIAS CANÓNICAS (WIKILINKS)

<!-- 
【PARA IA】Estos enlaces deben resolverse usando PROJECT_TREE.md. 
No uses rutas relativas. Usa siempre la forma canónica [[RUTA]].
-->

- `[[02-SKILLS/00-INDEX.md]]` → Índice maestro de skills por dominio
- `[[02-SKILLS/AI/00-INDEX.md]]` → Catálogo de integraciones de IA
- `[[01-RULES/08-SKILLS-REFERENCE.md]]` → Mapeo de habilidades por dominio
- `[[05-CONFIGURATIONS/validation/norms-matrix.json]]` → Mapeo de constraints por carpeta
- `[[GOVERNANCE-ORCHESTRATOR.md]]` → Tiers, validación y certificación
- `[[SDD-COLLABORATIVE-GENERATION.md]]` → Especificación de formato de artefactos
- `[[TOOLCHAIN-REFERENCE.md]]` → Catálogo de herramientas de validación
- `[[01-RULES/validation-checklist.md]]` → Checklist ejecutable de validación

---

## 【5】📦 METADATOS DE EXPANSIÓN (PARA FUTURAS VERSIONES)

<!-- 
【PARA MANTENEDORES】Nuevas secciones deben seguir este formato para no romper compatibilidad.
-->

```json
{
  "expansion_registry": {
    "new_generation_model": {
      "requires_files_update": [
        "02-SKILLS/GENERATION-MODELS.md: add model entry to tabla maestra con proveedor, tareas, constraints, coste, wikilink",
        "02-SKILLS/AI/: create integration file following SDD-COLLABORATIVE-GENERATION.md",
        "01-RULES/08-SKILLS-REFERENCE.md: add model to domain_catalog if new domain",
        "Human approval required: true"
      ],
      "backward_compatibility": "new models must not break existing validation flows; must declare constraints applicability clearly"
    },
    "new_generation_domain": {
      "requires_files_update": [
        "02-SKILLS/GENERATION-MODELS.md: add domain section with propósito, modelos recomendados, constraints críticas, comando de validación, ejemplo de prompt",
        "02-SKILLS/00-INDEX.md: add domain to horizontal/vertical skills catalog",
        "01-RULES/08-SKILLS-REFERENCE.md: add domain to domain_catalog",
        "Human approval required: true"
      ],
      "backward_compatibility": "new domains must not break existing navigation or validation flows; must declare constraints applicability clearly"
    }
  },
  "compatibility_rule": "Nuevas entradas en el catálogo no deben invalidar prompts o validaciones existentes. Cambios breaking requieren major version bump, guía de migración y aprobación humana explícita."
}
```

---

<!-- 
═══════════════════════════════════════════════════════════
🤖 SECCIÓN PARA IA: ÁRBOL JSON ENRIQUECIDO
═══════════════════════════════════════════════════════════
Esta sección contiene metadatos estructurados para consumo automático por agentes de IA.
No está diseñada para lectura humana directa. Los humanos deben usar las secciones 【1】-【5】.

Formato: JSON válido, con comentarios explicativos en claves "doc_*".
Prioridad de ejecución: Los modelos se consultan en orden: código → documentación → configuración.
Dependencias: Cada nodo declara sus archivos requeridos y sus efectos colaterales.
═══════════════════════════════════════════════════════════
-->

```json
{
  "generation_models_metadata": {
    "version": "3.0.0-SELECTIVE",
    "canonical_path": "/02-SKILLS/GENERATION-MODELS.md",
    "artifact_type": "governance_catalog",
    "immutable": true,
    "requires_human_approval_for_changes": true,
    "constraints_primary": ["C3", "C5", "C6", "C8"],
    "total_models_listed": 7,
    "total_domains_covered": 3,
    "llm_optimizations": {
      "oriental_models_friendly": true,
      "delimiters_used": ["【】", "┌─┐", "▼", "✅/❌/🔧"],
      "numbered_sequences": true,
      "stop_conditions_explicit": true
    }
  },
  
  "models_catalog": {
    "qwen_2_5_72b": {
      "provider": "Alibaba Cloud",
      "recommended_for": ["código Go/Python", "documentación técnica", "configs YAML"],
      "critical_constraints": ["C3", "C5", "C6"],
      "relative_cost": "low",
      "wikilink": "[[02-SKILLS/AI/qwen-integration.md]]"
    },
    "deepseek_r1": {
      "provider": "DeepSeek",
      "recommended_for": ["razonamiento complejo", "arquitectura de sistemas", "debugging"],
      "critical_constraints": ["C3", "C5", "C6", "C7"],
      "relative_cost": "medium",
      "wikilink": "[[02-SKILLS/AI/deepseek-integration.md]]"
    },
    "gpt_4o": {
      "provider": "OpenAI",
      "recommended_for": ["generación de prompts", "análisis de negocio", "outputs JSON estructurados"],
      "critical_constraints": ["C3", "C5", "C8"],
      "relative_cost": "high",
      "wikilink": "[[02-SKILLS/AI/gpt-integration.md]]"
    },
    "claude_3_5_sonnet": {
      "provider": "Anthropic",
      "recommended_for": ["documentación ejecutiva", "revisión de código", "compliance"],
      "critical_constraints": ["C3", "C5", "C8"],
      "relative_cost": "high",
      "wikilink": "[[02-SKILLS/AI/claude-integration.md]]"
    },
    "llama_3_1_70b": {
      "provider": "Meta (local)",
      "recommended_for": ["generación offline", "prototipado rápido", "testing de prompts"],
      "critical_constraints": ["C3", "C5", "C6"],
      "relative_cost": "very_low",
      "wikilink": "[[02-SKILLS/AI/llama-integration.md]]"
    },
    "gemini_1_5_pro": {
      "provider": "Google",
      "recommended_for": ["multimodal (texto+imagen)", "análisis de documentos PDF/OCR"],
      "critical_constraints": ["C3", "C5", "C8"],
      "relative_cost": "medium",
      "wikilink": "[[02-SKILLS/AI/gemini-integration.md]]"
    },
    "minimax": {
      "provider": "Minimax",
      "recommended_for": ["contexto ultra-largo (~1M tokens)", "procesamiento iterativo de docs grandes"],
      "critical_constraints": ["C3", "C5", "C6"],
      "relative_cost": "medium",
      "wikilink": "[[02-SKILLS/AI/minimax-integration.md]]"
    }
  },
  
  "generation_domains": {
    "code_generation": {
      "description": "Generar código fuente que cumpla con patrones canónicos, constraints de seguridad y LANGUAGE LOCK",
      "recommended_models": ["qwen_2_5_72b", "deepseek_r1", "llama_3_1_70b"],
      "critical_constraints": ["C3", "C4", "C5", "LANGUAGE_LOCK"],
      "validation_command": "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file generated-code.md --checks C3,C4,C5 --json",
      "canonical_prompt_template": "Genera un handler de webhook en Go que:\n1. Valide firma HMAC (C3)\n2. Inyecte tenant_id desde header X-Tenant-ID (C4)\n3. Siga estructura SDD con frontmatter válido (C5)\n4. Respete LANGUAGE LOCK: cero operadores pgvector en Go\n5. Incluya ≥10 ejemplos ✅/❌/🔧\n6. Retorne validation_command ejecutable"
    },
    "documentation_generation": {
      "description": "Generar documentación (README, guías, specs) que sea clara, validable y trazable",
      "recommended_models": ["qwen_2_5_72b", "claude_3_5_sonnet", "gpt_4o"],
      "critical_constraints": ["C5", "C6", "C8"],
      "validation_command": "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file generated-doc.md --checks C5,C6 --json",
      "canonical_prompt_template": "Genera documentación para skill de integración WhatsApp-RAG que:\n1. Siga estructura SDD: Propósito → Implementación → Ejemplos → Validación → Referencias\n2. Use wikilinks canónicos: [[02-SKILLS/COMUNICACION/whatsapp-rag-openrouter.md]]\n3. Incluya frontmatter con canonical_path, constraints_mapped, validation_command\n4. Añada ≥10 ejemplos ✅/❌/🔧 de uso real\n5. Documente constraints críticas: C3 (secrets), C4 (tenant isolation)"
    },
    "config_generation": {
      "description": "Generar archivos de configuración que sean seguros, idempotentes y validables",
      "recommended_models": ["qwen_2_5_72b", "deepseek_r1", "llama_3_1_70b"],
      "critical_constraints": ["C1", "C3", "C5", "C7"],
      "validation_command": "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file generated-config.yaml --checks C1,C3,C5 --json",
      "canonical_prompt_template": "Genera docker-compose.yml para servicio de RAG que:\n1. Use variables de entorno para secrets: ${QDRANT_API_KEY:?missing}\n2. Incluya resource limits: mem_limit: 512M, cpus: '0.5'\n3. Siga schema YAML válido con campos obligatorios\n4. Soporte --dry-run para validación sin despliegue\n5. Documente constraints aplicadas: C1, C3, C5"
    }
  },
  
  "validation_integration": {
    "orchestrator-engine.sh": {
      "purpose": "Validación integral de outputs generados con scoring y reporte JSON",
      "flags": ["--file", "--mode", "--json", "--checks"],
      "exit_codes": {"0": "passed", "1": "failed"},
      "output_format": "JSON con score, passed, blocking_issues, constraints_applied"
    },
    "audit-secrets.sh": {
      "purpose": "Detectar secrets hardcodeados en outputs generados (C3)",
      "flags": ["--file", "--dir", "--strict", "--json"],
      "exit_codes": {"0": "no_secrets_found", "1": "secrets_detected"},
      "output_format": "JSON con secrets_found, patterns_checked, findings"
    },
    "verify-constraints.sh": {
      "purpose": "Validar constraints y LANGUAGE LOCK en outputs generados",
      "flags": ["--file", "--check-constraint", "--check-language-lock", "--json"],
      "exit_codes": {"0": "compliant", "1": "violation"},
      "output_format": "JSON con constraints_validated, language_lock.violations"
    }
  },
  
  "dependency_graph": {
    "critical_infrastructure": [
      {"file": "02-SKILLS/AI/00-INDEX.md", "purpose": "Catálogo de integraciones de IA", "load_order": 1},
      {"file": "05-CONFIGURATIONS/validation/norms-matrix.json", "purpose": "Mapeo de constraints por carpeta", "load_order": 2},
      {"file": "GOVERNANCE-ORCHESTRATOR.md", "purpose": "Tiers y validación", "load_order": 3},
      {"file": "SDD-COLLABORATIVE-GENERATION.md", "purpose": "Especificación de formato", "load_order": 4}
    ],
    "validation_toolchain": [
      {"file": "05-CONFIGURATIONS/validation/orchestrator-engine.sh", "purpose": "Motor principal de validación", "load_order": 1},
      {"file": "05-CONFIGURATIONS/validation/audit-secrets.sh", "purpose": "Detección de secrets hardcodeados", "load_order": 2},
      {"file": "05-CONFIGURATIONS/validation/verify-constraints.sh", "purpose": "Validación de constraints y LANGUAGE LOCK", "load_order": 3}
    ]
  },
  
  "human_readable_errors": {
    "model_not_approved": "Modelo '{model_name}' no aprobado para generación en GENERATION-MODELS.md. Consultar tabla maestra para modelos válidos.",
    "constraint_not_declared": "Output generado no declara constraints aplicables en frontmatter. Añadir constraints_mapped: [\"C3\",\"C5\",...].",
    "wikilink_not_canonical": "Wikilink '{wikilink}' en output generado no es canónico. Usar forma absoluta: [[RUTA-DESDE-RAÍZ]].",
    "validation_failed": "Validación de output generado '{file}' falló: {error_details}. Consultar [[01-RULES/validation-checklist.md]] para ítems específicos a corregir.",
    "language_lock_violation": "Output generado viola LANGUAGE LOCK: operador '{operator}' prohibido en lenguaje '{language}'. Consultar [[01-RULES/language-lock-protocol.md]].",
    "prompt_hash_missing": "Output generado no incluye prompt_hash en frontmatter. Añadir para reproducibilidad forense (C6)."
  },
  
  "expansion_hooks": {
    "new_generation_model": {
      "requires_files_update": [
        "02-SKILLS/GENERATION-MODELS.md: add model entry to models_catalog with provider, recommended_for, critical_constraints, relative_cost, wikilink",
        "02-SKILLS/AI/: create integration file following SDD-COLLABORATIVE-GENERATION.md",
        "01-RULES/08-SKILLS-REFERENCE.md: add model to domain_catalog if new domain",
        "Human approval required: true"
      ],
      "backward_compatibility": "new models must not break existing validation flows; must declare constraints applicability clearly"
    },
    "new_generation_domain": {
      "requires_files_update": [
        "02-SKILLS/GENERATION-MODELS.md: add domain section to generation_domains with description, recommended_models, critical_constraints, validation_command, canonical_prompt_template",
        "02-SKILLS/00-INDEX.md: add domain to horizontal/vertical skills catalog",
        "01-RULES/08-SKILLS-REFERENCE.md: add domain to domain_catalog",
        "Human approval required: true"
      ],
      "backward_compatibility": "new domains must not break existing navigation or validation flows; must declare constraints applicability clearly"
    }
  },
  
  "validation_metadata": {
    "orchestrator_compatibility": ">=3.0.0-SELECTIVE",
    "schema_version": "generation-models.v3.json",
    "checksum_algorithm": "SHA256",
    "audit_log_format": "JSON Lines with RFC3339 timestamps",
    "pii_scrubbing": "enabled for all logs (C3 + C8 compliance)",
    "reproducibility_guarantee": "Any generation decision can be reproduced identically using this catalog + canonical_prompt_template + prompt_hash"
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
yq eval '.canonical_path' 02-SKILLS/GENERATION-MODELS.md | grep -q "/02-SKILLS/GENERATION-MODELS.md" && echo "✅ Ruta canónica correcta"

# 2. Constraints mapeadas (C3,C5,C6,C8)
yq eval '.constraints_mapped | contains(["C3"]) and contains(["C5"]) and contains(["C6"]) and contains(["C8"])' 02-SKILLS/GENERATION-MODELS.md && echo "✅ C3, C5, C6, C8 declaradas"

# 3. 7 modelos listados en tabla maestra
grep -c "Qwen\|DeepSeek\|GPT-4o\|Claude\|Llama\|Gemini\|Minimax" 02-SKILLS/GENERATION-MODELS.md | awk '{if($1>=7) print "✅ 7 modelos documentados"; else print "⚠️ Faltan modelos: "$1"/7"}'

# 4. 3 dominios de generación cubiertos
grep -c "Generación de Código\|Generación de Documentación\|Generación de Configuración" 02-SKILLS/GENERATION-MODELS.md | awk '{if($1>=3) print "✅ 3 dominios cubiertos"; else print "⚠️ Faltan dominios: "$1"/3"}'

# 5. JSON final parseable
tail -n +$(grep -n '```json' 02-SKILLS/GENERATION-MODELS.md | tail -1 | cut -d: -f1) 02-SKILLS/GENERATION-MODELS.md | sed -n '/```json/,/```/p' | sed '1d;$d' | jq empty && echo "✅ JSON parseable"

# 6. Wikilinks canónicos (sin rutas relativas)
for link in $(grep -oE '\[\[[^]]+\]\]' 02-SKILLS/GENERATION-MODELS.md | tr -d '[]' | sort -u); do
  if [[ "$link" =~ ^\[\[\.\/ || "$link" =~ ^\[\[\.\.\/ ]]; then
    echo "❌ Wikilink relativo: $link"
  else
    [ -f "${link#//}" ] || echo "⚠️ Wikilink no resuelto: $link"
  fi
done
```
````

**Criterio de aceptación:**  
- ✅ Frontmatter válido con `canonical_path: "/02-SKILLS/GENERATION-MODELS.md"`  
- ✅ `constraints_mapped` incluye C3, C5, C6, C8 (seguridad, estructura, trazabilidad, observabilidad)  
- ✅ 7 modelos de IA documentados con proveedor, tareas, constraints y coste  
- ✅ 3 dominios de generación cubiertos (código, documentación, configuración)  
- ✅ Sección JSON final es válida (puede parsearse con `jq .`)  
- ✅ Todos los wikilinks son canónicos (absolutos desde raíz)  

---

> 🎯 **Mensaje final para el lector humano**:  
> Este catálogo es tu brújula de generación. No es estático: evoluciona con el proyecto.  
> **Tarea → Modelo → Prompt → Generación → Validación → Integración**.  
> Si sigues ese flujo, nunca generarás código o docs que no cumplan con gobernanza.  
> La gobernanza no es una carga. Es la libertad de escalar sin miedo a romper.  

---
