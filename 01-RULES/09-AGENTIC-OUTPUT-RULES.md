---
canonical_path: "/01-RULES/09-AGENTIC-OUTPUT-RULES.md"
artifact_id: "agentic-output-rules-canonical"
artifact_type: "governance_rule_set"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 01-RULES/09-AGENTIC-OUTPUT-RULES.md --mode headless --json"
tier: 1
immutable: true
requires_human_approval_for_changes: true
related_files:
  - "[[00-STACK-SELECTOR.md]]"
  - "[[SDD-COLLABORATIVE-GENERATION.md]]"
  - "[[GOVERNANCE-ORCHESTRATOR.md]]"
  - "[[AI-NAVIGATION-CONTRACT.md]]"
  - "[[05-CONFIGURATIONS/validation/norms-matrix.json]]"
  - "[[05-CONFIGURATIONS/validation/orchestrator-engine.sh]]"
checksum_sha256: "PENDING_GENERATION"
---

# 📄 01-RULES/09-AGENTIC-OUTPUT-RULES.md – REGENERADO v3.0-SELECTIVE

> **Nota para principiantes:** Este documento define **CÓMO** deben entregar sus resultados los agentes de IA en MANTIS AGENTIC. No dicta el contenido técnico, sino el formato, los metadatos, las validaciones previas y las salvaguardas de seguridad que garantizan que cualquier output sea consumible, auditable y seguro por humanos y sistemas. Si eres nuevo, lee las secciones en orden. Si eres experto, salta al JSON final.  
>  
> **Para IAs:** Este es tu contrato de entrega. **OUTPUT SIN ESTRUCTURA CANÓNICA = RECHAZO AUTOMÁTICO**. No inventes, no asumas, no omitas.


# 🤖 09-AGENTIC-OUTPUT-RULES: Contrato de Formato, Validación y Entrega de Salidas de IA

<!-- 
【PARA PRINCIPIANTES】¿Qué es este archivo?
Este documento es el "protocolo de empaque" para todo lo que genera una IA en el proyecto.
Define las reglas inamovibles para garantizar que cada output sea:
• Determinista (misma entrada + contexto → misma estructura de salida)
• Validable automáticamente (sin intervención manual para checks básicos)
• Seguro por defecto (sin secrets, sin suposiciones, con fallbacks)
• Auditable (metadatos, trazabilidad, versionado)

Si eres nuevo: lee en orden. 
Si ya conoces el proyecto: usa los wikilinks para ir directo a lo que necesitas.
-->

> **Instrucción crítica para la IA:** 
> Este documento es tu contrato de entrega. 
> **OUTPUT SIN ESTRUCTURA CANÓNICA = RECHAZO AUTOMÁTICO**. 
> No inventes, no asumas, no omitas. Si algo no está claro, DETENER y preguntar.

---

## 【0】🎯 PROPÓSITO Y ALCANCE (Explicado para humanos)

<!-- 
【EDUCATIVO】Este documento responde: "¿Cómo debe empacar y entregar la IA su trabajo para que sea útil y seguro?"
No es una guía de redacción. Es un sistema de contención estructural que:
• Garantiza que todo output sigue la especificación SDD sin desviaciones
• Exige que cada entrega declare explícitamente sus constraints, tier y comando de validación
• Previene alucinaciones mediante reglas de fallback y verificación de contexto
• Asegura que logs, errores y metadatos son estructurados, scrubeados y trazables
-->

### 0.1 Principios de Salida Agéntica

```
P1: SDD-Compliant → Todo output sigue la estructura SDD-COLLABORATIVE-GENERATION sin excepciones.
P2: Explicit Over Implicit → Nunca asumir contexto, defaults o constraints no declaradas.
P3: Tier-Aware Delivery → El formato de salida está dictado por el modo confirmado (A1-B3).
P4: Validation-First → Nunca entregar sin incluir `validation_command` ejecutable para Tier ≥ 2.
P5: Safe-By-Default → Rechazar solicitudes ambiguas, aplicar fallback a Tier 1, scrubear PII/secrets.
P6: Audit-Ready → Cada output lleva `prompt_hash`, `timestamp`, `mode_selected`, `trace_id`.
```

---

## 【1】🔒 REGLAS INAMOVIBLES DE SALIDA (AOR-001 a AOR-010)

<!-- 
【EDUCATIVO】Estas 10 reglas son contractuales. 
Cualquier violación genera `blocking_issue` o `output_rejected` en el pipeline.
-->

### AOR-001: SDD-Compliant Structure Enforcement

```
【REGLA AOR-001】Todo output debe seguir estrictamente la estructura SDD definida en [[SDD-COLLABORATIVE-GENERATION]].

✅ Cumplimiento:
• Frontmatter YAML válido con campos obligatorios por Tier
• Secciones en orden: Propósito → Implementación/Configuración → Ejemplos → Validación → Referencias
• JSON tree final parseable por `jq`
• Cero secciones adicionales no declaradas en la plantilla

❌ Violación crítica:
• Output sin frontmatter o con orden de secciones alterado
• JSON final con sintaxis inválida o claves inconsistentes
• Añadir "Notas personales" o "Comentarios informales" fuera de bloques canónicos
```

### AOR-002: Explicit Constraint Mapping

```
【REGLA AOR-002】Las constraints aplicables se declaran explícitamente y se heredan de [[norms-matrix.json]].

✅ Cumplimiento:
• `constraints_mapped: ["C1","C3",...]` en frontmatter
• `inherited_from: "[[05-CONFIGURATIONS/validation/norms-matrix.json]]"`
• Nunca inventar constraints fuera de C1-C8 y V1-V3
• Documentar justificación si se omiten constraints permitidas (ej: `excluded: ["C2"]`)

❌ Violación crítica:
• `constraints_mapped: ["C9"]` o constraint no mapeada
• Omitir constraint mandatory según la ruta destino
• Declarar `V1/V2/V3` en output que no apunta a dominio vectorial
```

### AOR-003: Tier-Gated Delivery Format

```
【REGLA AOR-003】El formato de entrega está determinado estrictamente por el Tier confirmado.

✅ Cumplimiento:
| Tier | Formato Requerido | Elementos Obligatorios |
|------|------------------|------------------------|
| 1    | Markdown + notas | Frontmatter, wikilinks canónicos, nota "Requiere revisión humana" |
| 2    | Código + metadatos | ≥10 ejemplos ✅/❌/🔧, `validation_command`, checksum SHA256 |
| 3    | Paquete ZIP simulado | `manifest.json`, `deploy.sh`, `rollback.sh`, `healthcheck.sh`, `README-DEPLOY.md` |

❌ Violación crítica:
• Entregar código Tier 2 en formato de pantalla sin `validation_command`
• Declarar `tier: 3` pero omitir `deploy.sh` o `manifest.json`
• Entregar sin nota de estado de revisión según Tier
```

### AOR-004: Metadata Injection & Traceability

```
【REGLA AOR-004】Todo output inyecta metadatos canónicos para trazabilidad forense.

✅ Cumplimiento (Frontmatter obligatorio):
• `prompt_hash`: SHA256 del prompt original
• `generated_at`: RFC3339 UTC
• `mode_selected`: A1|A2|A3|B1|B2|B3 confirmado
• `validation_command`: ruta + flags ejecutables
• `checksum_sha256`: hash del contenido generado

❌ Violación crítica:
• Output sin `prompt_hash` o `generated_at`
• `validation_command` con ruta inexistente o flags inválidos
• Metadatos inconsistentes entre frontmatter y contenido real
```

### AOR-005: Zero Implicit Assumptions

```
【REGLA AOR-005】Nunca asumir contexto, variables de entorno, secrets o estados del sistema.

✅ Cumplimiento:
• Declarar explícitamente: `requires_env: ["DB_PASSWORD", "API_KEY"]`
• Incluir fallback seguro: `if [ -z "$VAR" ]; then echo "ERROR: $VAR missing" >&2; exit 1; fi`
• Documentar supuestos: `assumptions: ["PostgreSQL 14+", "tenant_id en header X-Tenant-ID"]`
• Si falta contexto crítico → fallback a Tier 1 con nota: `"⚠️ Contexto insuficiente. Ajuste parámetros y reintente."`

❌ Violación crítica:
• Código que usa `$DB_PASS` sin validación ni fallback
• Asumir `tenant_id` disponible sin validarlo
• Generar configuración con valores placeholder que parecen reales
```

### AOR-006: Validation-First Handoff

```
【REGLA AOR-006】Nunca entregar sin incluir comando de validación ejecutable y verificado.

✅ Cumplimiento:
• Para Tier ≥ 2: `validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file <ruta> --mode headless --json"`
• El comando debe ser copiable/ejecutable sin modificaciones
• Incluir expectativa de éxito: `"score >= 30 | blocking_issues: []"`
• Si el output no pasa validación mental → iterar antes de entregar

❌ Violación crítica:
• Entregar código sin `validation_command`
• Comando con sintaxis inválida o ruta relativa
• Declarar "validado" sin ejecutar gate pre-entrega
```

### AOR-007: Safe Error & Fallback Reporting

```
【REGLA AOR-007】Los errores y rechazos deben estructurarse, no exponer stack traces internos.

✅ Cumplimiento:
• Formato de rechazo: 
  ```
  ❌ BLOCKING_ISSUE: <descripción técnica clara>
  🔧 Sugerencia: <acción correctiva específica>
  📖 Referencia: [[wikilink-canónico]]
  ```
• Fallback automático a Tier 1 si la solicitud es ambigua o fuera de alcance
• Log estructurado con `level: WARN|ERROR`, `event: "output_rejected"`, `tenant_id`, `trace_id`

❌ Violación crítica:
• Responder con "No sé cómo hacerlo" sin fallback estructurado
• Exponer trazas de pila, paths internos o configuración del host
• Rechazar sin ofrecer ruta de corrección o referencia normativa
```

### AOR-008: Observability & PII Scrubbing (C6 + C8)

```
【REGLA AOR-008】Todo output incluye logging estructurado y scrubbing automático de datos sensibles.

✅ Cumplimiento:
• Logs en JSON a stderr con `timestamp`, `level`, `event`, `tenant_id`, `trace_id`
• Scrubbing de campos sensibles: `password`, `secret`, `token`, `api_key`, `email` → `***REDACTED***`
• Ejemplo de log canónico:
  ```json
  {"timestamp":"2026-04-19T12:00:00Z","level":"INFO","tenant_id":"cli_001","event":"output_delivered","trace_id":"otel-abc","tier":2,"validation_score":42}
  ```

❌ Violación crítica:
• Log que expone credenciales o PII en texto plano
• Formato de log inconsistente o sin zona horaria UTC
• Omitir `trace_id` o `tenant_id` en logs de auditoría
```

### AOR-009: LANGUAGE LOCK Boundary Enforcement in Outputs

```
【REGLA AOR-009】Los outputs nunca deben sugerir o incluir operadores fuera de los dominios permitidos.

✅ Cumplimiento:
• Si el output es para `go/`, `sql/`, `python/`, etc. → cero operadores pgvector (`<->`, `<=>`, `<#>`)
• Si el output incluye queries vectoriales → redirigir a `06-PROGRAMMING/postgresql-pgvector/`
• Validación mental de `verify-constraints.sh --check-language-lock` antes de entregar
• Documentar advertencia si el usuario solicita operadores fuera de dominio

❌ Violación crítica:
• Generar `SELECT embedding <=> $1` en archivo `.go.md` o `.sql.md` genérico
• Sugerir `USING hnsw` en carpeta que no soporta pgvector
• Omitir advertencia de LANGUAGE LOCK cuando se detecta solicitud ambigua
```

### AOR-010: Deterministic Idempotency

```
【REGLA AOR-010】Mismo prompt + mismo contexto = misma estructura de output, sin variaciones aleatorias.

✅ Cumplimiento:
• Orden de secciones fijo, numeración determinista, ejemplos consistentes
• Cero "quizás", "podría ser", "depende" sin fallback explícito
• Si hay múltiples soluciones válidas → presentar la canónica primero, alternativas después con `alternatives: [...]`
• Re-ejecución mental del flujo produce idéntico JSON tree y frontmatter

❌ Violación crítica:
• Output que cambia estructura, orden o ejemplos en regeneraciones idénticas
• Uso de frases subjetivas sin anclar en norma canónica
• Faltar campos obligatorios en frontmatter por "variación estilística"
```

---

## 【2】📦 ESTÁNDARES DE METADATOS Y FORMATO DE ENTREGA

<!-- 
【EDUCATIVO】Estructura exacta que debe tener cada nivel de output.
-->

### 2.1 Frontmatter Canónico por Tier

```yaml
---
# COMUNES A TODOS
canonical_path: "/ruta/canónica/exacta/desde/raíz.md"
artifact_id: "identificador-único"
artifact_type: "skill_go|documentation|config_docker|etc"
version: "1.0.0"
constraints_mapped: ["C3","C4","C5"]
inherited_from: "[[05-CONFIGURATIONS/validation/norms-matrix.json]]"
prompt_hash: "sha256:..."
generated_at: "2026-04-19T12:00:00Z"
mode_selected: "A2"
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file <ruta> --json"

# TIER 2
tier: 2
examples_count: 12
checksum_sha256: "sha256:..."

# TIER 3
tier: 3
bundle_required: true
bundle_contents: ["manifest.json", "deploy.sh", "rollback.sh", "healthcheck.sh", "README-DEPLOY.md"]
deployment_target: "vps1|client_x|internal_cluster"
---
```

### 2.2 Bloques de Código y Wikilinks

```
✅ Reglas de fences:
• Declarar lenguaje: ```bash, ```python, ```go, ```sql, ```json, ```yaml
• Máximo 5 líneas ejecutables por bloque (expansión en ejemplos separados)
• Incluir comentario `// 👇 EXPLICACIÓN:` o `# 👇 EXPLICACIÓN:` cuando aplique

✅ Reglas de wikilinks:
• Forma absoluta: `[[00-STACK-SELECTOR]]`, `[[PROJECT_TREE.md]]`
• Prohibido: `../`, `./`, `#ancla`, rutas relativas
• Resolver siempre contra `PROJECT_TREE.md`
```

---

## 【3】🛡️ PROTOCOLO DE VALIDACIÓN PRE-ENTREGA

<!-- 
【EDUCATIVO】Flujo que la IA DEBE ejecutar antes de mostrar cualquier output.
-->

```
┌─────────────────────────────────────────────────────────┐
│ 【PASO 1】VERIFICAR CONTEXTO Y MODO                    │
├─────────────────────────────────────────────────────────┤
│ • ¿mode_selected confirmado? Sí → continuar            │
│ • ¿ruta canónica definida en 00-STACK-SELECTOR? Sí → sí│
│ • ¿falta contexto crítico? → fallback a Tier 1 + nota  │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【PASO 2】VALIDAR ESTRUCTURA SDD                       │
├─────────────────────────────────────────────────────────┤
│ • Frontmatter YAML válido + campos obligatorios        │
│ • Secciones en orden canónico                          │
│ • JSON tree final parseable                            │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【PASO 3】VALIDAR CONSTRAINTS Y LANGUAGE LOCK          │
├─────────────────────────────────────────────────────────┤
│ • constraints_mapped ⊆ norms-matrix[carpeta].allowed   │
│ • constraints_mandatory ⊆ constraints_mapped           │
│ • Cero operadores prohibidos para el stack destino     │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【PASO 4】EJECUTAR GATE MENTAL CON ORCHESTRATOR        │
├─────────────────────────────────────────────────────────┤
│ • Simular: orchestrator-engine.sh --file ... --json    │
│ • Esperar: score >= 30, blocking_issues == []          │
│ • Si falla → iterar corrección (máx 3 intentos)        │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【PASO 5】ENTREGAR SEGÚN TIER + AUDITAR                │
├─────────────────────────────────────────────────────────┤
│ • Formato exacto según Tier                            │
│ • Incluir validation_command + checksum                │
│ • Log estructurado con prompt_hash, tenant_id, trace_id│
└─────────────────────────────────────────────────────────┘
```

---

## 【4】📚 GLOSARIO PARA PRINCIPIANTES

| Término | Significado simple | Ejemplo |
|---------|-------------------|---------|
| **SDD-Compliant** | Sigue la estructura exacta de frontmatter + secciones + JSON | No omitir secciones, no reordenar |
| **Tier-Gated** | El formato de salida depende del modo confirmado (A1-B3) | A2 → código + validation_command |
| **Validation-First** | Nunca entregar sin incluir comando de validación ejecutable | `orchestrator-engine.sh --file ... --json` |
| **Zero Implicit** | Nunca asumir variables, contexto o estados del sistema | Validar `$VAR` antes de usarla |
| **PII Scrubbing** | Reemplazar datos sensibles por `***REDACTED***` en logs/output | `token: "***REDACTED***"` |
| **Deterministic** | Mismo input + contexto → misma estructura de output | Sin variaciones aleatorias ni subjetividad |
| **LANGUAGE LOCK** | Regla que prohíbe operadores fuera de dominios permitidos | `<->` solo en `postgresql-pgvector/` |
| **Fallback a Tier 1** | Si falta contexto o hay ambigüedad → entregar documentación, no código | `"⚠️ Contexto insuficiente. Propuesta inicial:"` |

---

## 【5】🧪 SANDBOX DE PRUEBA (OPCIONAL)

```
【TEST MODE: AGENTIC-OUTPUT-VALIDATION】
Prompt de prueba: "Generar script de despliegue automático para agente RAG de cliente agrícola"

Respuesta esperada de la IA:
1. Confirmar modo: humano responde "B3" → mode_selected=B3, tier=3
2. Resolver ruta: 05-CONFIGURATIONS/docker-compose/ o deploy/ → constraints C1-C8
3. Aplicar AOR-001 a AOR-010: estructura SDD, metadata completa, zero implicit, validation_command, LANGUAGE LOCK
4. Validar mental con orchestrator-engine.sh → score >= 45, blocking_issues: []
5. Entregar formato Tier 3: ZIP simulado con manifest.json, deploy.sh, rollback.sh, healthcheck.sh, README
6. Incluir log de auditoría estructurado y checksum SHA256
7. Si falta contexto (ej: credenciales DB) → fallback a Tier 1 con nota y requerimiento explícito

Si la IA entrega sin validation_command, omite checksum, usa rutas relativas, o no respeta Tier 3 → RECHAZO DE OUTPUT.
```

---

## 【6】🔗 REFERENCIAS CANÓNICAS (WIKILINKS)

- `[[00-STACK-SELECTOR]]` → Motor de decisión de stack
- `[[SDD-COLLABORATIVE-GENERATION]]` → Especificación de formato SDD
- `[[GOVERNANCE-ORCHESTRATOR]]` → Tiers y validación
- `[[AI-NAVIGATION-CONTRACT]]` → Reglas de navegación y modo
- `[[05-CONFIGURATIONS/validation/norms-matrix.json]]` → Mapeo de constraints
- `[[05-CONFIGURATIONS/validation/orchestrator-engine.sh]]` → Motor de validación
- `[[01-RULES/language-lock-protocol.md]]` → Aislamiento de operadores
- `[[PROJECT_TREE]]` → Mapa canónico de rutas

---

## 【7】📦 METADATOS DE EXPANSIÓN (PARA FUTURAS VERSIONES)

```json
{
  "expansion_registry": {
    "new_output_format": {
      "requires_files_update": [
        "01-RULES/09-AGENTIC-OUTPUT-RULES.md: add format spec to Section 【2】",
        "GOVERNANCE-ORCHESTRATOR.md: update tier definitions if format changes delivery",
        "SDD-COLLABORATIVE-GENERATION.md: update template if structural change",
        "orchestrator-engine.sh: add validation flags for new format",
        "Human approval required: true"
      ],
      "backward_compatibility": "new formats must not break existing Tier 1/2/3 validation gates"
    },
    "new_scanning_rule": {
      "requires_files_update": [
        "01-RULES/09-AGENTIC-OUTPUT-RULES.md: add rule with format ## AOR-XXX: <TÍTULO>",
        "05-CONFIGURATIONS/validation/: add pre-output check if rule affects validation",
        "CI/CD: integrate new gate in output pipeline",
        "Human approval required: true"
      ],
      "backward_compatibility": "new rules must apply only to new generations, not retroactively invalidate outputs"
    }
  },
  "compatibility_rule": "Nuevas reglas de output no deben invalidar artefactos generados bajo versiones anteriores. Cambios breaking requieren major version bump, guía de migración y aprobación humana explícita."
}
```

---

<!-- 
═══════════════════════════════════════════════════════════
🤖 SECCIÓN PARA IA: ÁRBOL JSON ENRIQUECIDO
═══════════════════════════════════════════════════════════
Esta sección contiene metadatos estructurados para consumo automático por agentes de IA.
No está diseñada para lectura humana directa. Los humanos deben usar las secciones 【1】-【7】.

Formato: JSON válido, con comentarios explicativos en claves "doc_*".
Prioridad de ejecución: Las reglas se aplican en orden AOR-001 → AOR-010.
Dependencias: Cada nodo declara sus archivos requeridos y sus efectos colaterales.
═══════════════════════════════════════════════════════════
-->

```json
{
  "agentic_output_metadata": {
    "version": "3.0.0-SELECTIVE",
    "canonical_path": "/01-RULES/09-AGENTIC-OUTPUT-RULES.md",
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
    "AOR-001": {"title": "SDD-Compliant Structure Enforcement", "constraint": "C5", "priority": "critical", "blocking_if_violated": true, "validation_tool": "validate-frontmatter.sh + SDD spec check"},
    "AOR-002": {"title": "Explicit Constraint Mapping", "constraint": "C4, C5", "priority": "critical", "blocking_if_violated": true, "validation_tool": "norms-matrix.json subset validation"},
    "AOR-003": {"title": "Tier-Gated Delivery Format", "constraint": "C6", "priority": "critical", "blocking_if_violated": true, "validation_tool": "GOVERNANCE-ORCHESTRATOR.md tier check"},
    "AOR-004": {"title": "Metadata Injection & Traceability", "constraint": "C6, C8", "priority": "high", "blocking_if_violated": true, "validation_tool": "frontmatter field audit"},
    "AOR-005": {"title": "Zero Implicit Assumptions", "constraint": "C3, C7", "priority": "high", "blocking_if_violated": false, "validation_tool": "context gap detection + fallback trigger"},
    "AOR-006": {"title": "Validation-First Handoff", "constraint": "C6", "priority": "critical", "blocking_if_violated": true, "validation_tool": "orchestrator-engine.sh --dry-run"},
    "AOR-007": {"title": "Safe Error & Fallback Reporting", "constraint": "C7, C8", "priority": "high", "blocking_if_violated": false, "validation_tool": "error format parser + PII scrubber"},
    "AOR-008": {"title": "Observability & PII Scrubbing", "constraint": "C8", "priority": "high", "blocking_if_violated": false, "validation_tool": "structured log validator"},
    "AOR-009": {"title": "LANGUAGE LOCK Boundary Enforcement", "constraint": "C5", "priority": "critical", "blocking_if_violated": true, "validation_tool": "verify-constraints.sh --check-language-lock"},
    "AOR-010": {"title": "Deterministic Idempotency", "constraint": "C5, C6", "priority": "medium", "blocking_if_violated": false, "validation_tool": "output diff against baseline"}
  },
  
  "tier_delivery_matrix": {
    "tier_1": {
      "applicable_modes": ["A1", "B1"],
      "format": "screen_editor",
      "required_elements": ["frontmatter", "canonical_wikilinks", "human_review_note"],
      "optional_elements": ["validation_command", "checksum"],
      "min_score": 15,
      "blocking_on_fail": false
    },
    "tier_2": {
      "applicable_modes": ["A2", "B2"],
      "format": "code_with_validation",
      "required_elements": ["frontmatter", ">=10 examples", "validation_command", "checksum_sha256"],
      "optional_elements": ["lint_config", "test_instructions"],
      "min_score": 30,
      "blocking_on_fail": true
    },
    "tier_3": {
      "applicable_modes": ["A3", "B3"],
      "format": "zip_with_manifest",
      "required_elements": ["frontmatter", "manifest.json", "deploy.sh", "rollback.sh", "healthcheck.sh", "README-DEPLOY.md", "checksums.sha256"],
      "optional_elements": ["migration_script", "monitoring_config"],
      "min_score": 45,
      "blocking_on_fail": true
    }
  },
  
  "validation_integration": {
    "validate-frontmatter.sh": {"purpose": "Validar estructura YAML y campos obligatorios", "exit_codes": {"0": "valid", "1": "invalid"}},
    "verify-constraints.sh": {"purpose": "Validar constraints y LANGUAGE LOCK", "exit_codes": {"0": "compliant", "1": "violation"}},
    "orchestrator-engine.sh": {"purpose": "Scoring integral y validación final", "flags": ["--file", "--mode", "--json", "--checks"], "exit_codes": {"0": "passed", "1": "failed"}},
    "audit-secrets.sh": {"purpose": "Detectar secrets hardcodeados o expuestos", "exit_codes": {"0": "clean", "1": "found"}}
  },
  
  "dependency_graph": {
    "critical_infrastructure": [
      {"file": "SDD-COLLABORATIVE-GENERATION.md", "purpose": "Especificación de formato estructural", "load_order": 1},
      {"file": "GOVERNANCE-ORCHESTRATOR.md", "purpose": "Definición de Tiers y formatos de entrega", "load_order": 2},
      {"file": "05-CONFIGURATIONS/validation/norms-matrix.json", "purpose": "Mapeo de constraints por carpeta", "load_order": 3},
      {"file": "01-RULES/language-lock-protocol.md", "purpose": "Aislamiento de operadores", "load_order": 4}
    ],
    "output_templates": [
      {"file": "05-CONFIGURATIONS/templates/skill-template.md", "purpose": "Plantilla base para outputs", "load_order": 1}
    ],
    "validation_toolchain": [
      {"file": "05-CONFIGURATIONS/validation/orchestrator-engine.sh", "purpose": "Motor principal de validación", "load_order": 1},
      {"file": "05-CONFIGURATIONS/validation/verify-constraints.sh", "purpose": "Validación de LANGUAGE LOCK", "load_order": 2},
      {"file": "05-CONFIGURATIONS/validation/check-wikilinks.sh", "purpose": "Validación de enlaces canónicos", "load_order": 3}
    ]
  },
  
  "human_readable_errors": {
    "structure_non_compliant": "Estructura de output no cumple SDD en '{file}'. Faltan secciones o frontmatter inválido. Consulte [[SDD-COLLABORATIVE-GENERATION]].",
    "constraint_mapping_invalid": "Constraints declaradas '{declared}' no coinciden con permitidas para '{path}'. Consulte [[norms-matrix.json]].",
    "tier_format_mismatch": "Formato de entrega no corresponde a Tier {declared}. Consulte [[GOVERNANCE-ORCHESTRATOR.md]].",
    "metadata_incomplete": "Frontmatter en '{file}' omite campos obligatorios: {missing_fields}. Añadir prompt_hash, generated_at, validation_command.",
    "implicit_assumption_detected": "Output asume '{variable}' sin validación ni fallback. Añadir chequeo explícito o documentar en assumptions.",
    "validation_command_missing": "Output Tier {tier} sin validation_command ejecutable. Añadir comando canónico de orchestrator-engine.sh.",
    "error_format_invalid": "Rechazo o error no sigue formato canónico ❌ BLOCKING_ISSUE / 🔧 Sugerencia / 📖 Referencia.",
    "pii_exposed": "Log o output expone '{field}' en texto plano. Aplicar scrubbing a ***REDACTED***.",
    "language_lock_violation": "Operador '{op}' prohibido en output para stack '{lang}'. Consulte [[01-RULES/language-lock-protocol.md]].",
    "non_deterministic_output": "Estructura de output varía en regeneración idéntica. Fijar orden de secciones, numeración y ejemplos canónicos."
  },
  
  "expansion_hooks": {
    "new_output_format": {
      "requires_files_update": [
        "01-RULES/09-AGENTIC-OUTPUT-RULES.md: add format spec to Section 【2】",
        "GOVERNANCE-ORCHESTRATOR.md: update tier definitions",
        "SDD-COLLABORATIVE-GENERATION.md: update template",
        "orchestrator-engine.sh: add validation flags",
        "Human approval required: true"
      ],
      "backward_compatibility": "new formats must not break existing Tier 1/2/3 validation gates"
    },
    "new_scanning_rule": {
      "requires_files_update": [
        "01-RULES/09-AGENTIC-OUTPUT-RULES.md: add rule with format ## AOR-XXX: <TÍTULO>",
        "05-CONFIGURATIONS/validation/: add pre-output check",
        "CI/CD: integrate new gate in output pipeline",
        "Human approval required: true"
      ],
      "backward_compatibility": "new rules must apply only to new generations, not retroactively invalidate outputs"
    }
  },
  
  "validation_metadata": {
    "orchestrator_compatibility": ">=3.0.0-SELECTIVE",
    "schema_version": "agentic-output-rules.v1.json",
    "checksum_algorithm": "SHA256",
    "audit_log_format": "JSON Lines with RFC3339 timestamps",
    "pii_scrubbing": "enabled for all logs and outputs (C3 + C8 compliance)",
    "reproducibility_guarantee": "Any agentic output can be regenerated identically using this rule set + SDD template + prompt_hash"
  }
}
```

---

## ✅ CHECKLIST DE VALIDACIÓN POST-GENERACIÓN

<!-- 
【PARA PRINCIPIANTES】Antes de guardar este archivo, verifica estos puntos.
-->

`````markdown
```bash
# 1. Frontmatter válido
yq eval '.canonical_path' 01-RULES/09-AGENTIC-OUTPUT-RULES.md | grep -q "/01-RULES/09-AGENTIC-OUTPUT-RULES.md" && echo "✅ Ruta canónica correcta"

# 2. Constraints mapeadas
yq eval '.constraints_mapped | length' 01-RULES/09-AGENTIC-OUTPUT-RULES.md | grep -q "8" && echo "✅ 8 constraints declaradas"

# 3. Reglas presentes
grep -c "AOR-0[0-9][0-9]:" 01-RULES/09-AGENTIC-OUTPUT-RULES.md | awk '{if($1==10) print "✅ 10 reglas de output"; else print "⚠️ Faltan reglas"}'

# 4. Matriz de Tiers presente
grep -q "tier_delivery_matrix\|Tier-Gated Delivery" 01-RULES/09-AGENTIC-OUTPUT-RULES.md && echo "✅ Matriz de Tiers documentada"

# 5. JSON válido
tail -n +$(grep -n '```json' 01-RULES/09-AGENTIC-OUTPUT-RULES.md | tail -1 | cut -d: -f1) 01-RULES/09-AGENTIC-OUTPUT-RULES.md | sed -n '/```json/,/```/p' | sed '1d;$d' | jq empty && echo "✅ JSON parseable"

# 6. Wikilinks canónicos
for link in $(grep -oE '\[\[[^]]+\]\]' 01-RULES/09-AGENTIC-OUTPUT-RULES.md | tr -d '[]' | sort -u); do
  [ -f "${link#//}" ] || echo "⚠️ Wikilink roto: $link"
done
```
````

> 🎯 **Mensaje final**: Este protocolo es tu garantía de entrega. No es negociable.  
> **Estructura → Constraints → Validación → Formato Tier → Auditoría**.  
> Si sigues ese flujo, nunca entregarás un output que rompa la cadena de confianza.  
> La gobernanza no es una carga. Es la libertad de automatizar sin miedo a romper.  
