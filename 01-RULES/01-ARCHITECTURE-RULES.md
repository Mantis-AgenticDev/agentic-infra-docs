---
canonical_path: "/01-RULES/01-ARCHITECTURE-RULES.md"
artifact_id: "architecture-rules-canonical"
artifact_type: "governance_rule_set"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C1", "C2", "C5", "C6", "C7", "C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 01-RULES/01-ARCHITECTURE-RULES.md --mode headless --json"
tier: 1
immutable: true
requires_human_approval_for_changes: true
related_files:
  - "[[00-STACK-SELECTOR.md]]"
  - "[[PROJECT_TREE.md]]"
  - "[[GOVERNANCE-ORCHESTRATOR.md]]"
  - "[[05-CONFIGURATIONS/validation/norms-matrix.json]]"
  - "[[01-RULES/language-lock-protocol.md]]"
  - "[[SDD-COLLABORATIVE-GENERATION.md]]"
checksum_sha256: "PENDING_GENERATION"
---

# 📄 01-RULES/01-ARCHITECTURE-RULES.md – REGENERADO v3.0-SELECTIVE

> **Nota para principiantes:** Este documento es el "contrato arquitectónico" de MANTIS AGENTIC. Define cómo se estructuran, validan y entregan los componentes del sistema. Si eres nuevo, lee las secciones en orden. Si eres experto, salta al JSON final.  
>  
> **Para IAs:** Este es tu contrato de diseño. **VIOLAR REGLAS ARQUITECTÓNICAS = DEUDA TÉCNICA AUTOMÁTICA**. No inventes, no asumas, no omitas.


# 🏗️ 01-ARCHITECTURE-RULES: Contrato de Diseño y Estructura Canónica

<!-- 
【PARA PRINCIPIANTES】¿Qué es este archivo?
Este documento es el "plano maestro" del proyecto MANTIS AGENTIC.
Define las reglas inamovibles para garantizar que toda arquitectura sea:
• Determinista (misma ruta → mismo stack → misma validación)
• Modular (sin acoplamiento cruzado no autorizado)
• Validable (cada componente pasa gates automáticos antes de integrarse)

Si eres nuevo: lee en orden. 
Si ya conoces el proyecto: usa los wikilinks para ir directo a lo que necesitas.
-->

> **Instrucción crítica para la IA:** 
> Este documento es tu contrato de diseño. 
> **VIOLAR REGLAS ARQUITECTÓNICAS = DEUDA TÉCNICA AUTOMÁTICA**. 
> No inventes, no asumas, no omitas. Si algo no está claro, DETENER y preguntar.

---

## 【0】🎯 PROPÓSITO Y ALCANCE (Explicado para humanos)

<!-- 
【EDUCATIVO】Este documento responde: "¿Cómo diseño un componente que encaje perfectamente en MANTIS?"
No es una lista de preferencias. Es un sistema estructural que:
• Garantiza que la ruta canónica dicta el stack (no al revés)
• Previene acoplamiento indebido entre lenguajes o dominios
• Exige validación automática antes de integrar cualquier artefacto
• Asegura que observabilidad, límites de recursos y resiliencia son requisitos de diseño, no parches posteriores
-->

### 0.1 Principios Arquitectónicos Canónicos

```
P1: Route-First Design → La ubicación canónica (PROJECT_TREE.md) determina lenguaje, constraints y formato.
P2: LANGUAGE LOCK → Operadores y constraints vectoriales están aislados por dominio; nunca se filtran.
P3: Validation-First → Todo artefacto pasa gate pre-generación y scoring post-generación antes de entregar.
P4: Tiered Delivery → El modo operativo (A1-B3) dicta el nivel de madurez (1/2/3) y formato de salida.
P5: Separation of Concerns → Cada stack cumple su dominio; las integraciones cruzadas son explícitas y auditables.
P6: Observability by Design → C6 (ejecución verificable) y C8 (logging estructurado) son arquitectónicos, no opcionales.
```

---

## 【1】🔒 REGLAS INAMOVIBLES DE ARQUITECTURA (ARC-001 a ARC-010)

<!-- 
【EDUCATIVO】Estas 10 reglas son contractuales. 
Cualquier violación genera `blocking_issue` o `debt_technical_flag` en validación.
-->

### ARC-001: Route-First Design (Ruta → Stack → Constraints)

```
【REGLA ARC-001】El diseño siempre comienza por la ruta canónica, nunca por el lenguaje preferido.

✅ Cumplimiento:
1. Identificar función del artefacto (ej: "webhook de validación")
2. Consultar [[PROJECT_TREE.md]] → ruta canónica: `06-PROGRAMMING/javascript/`
3. Consultar [[00-STACK-SELECTOR.md]] → lenguaje: TypeScript, constraints: C3,C4,C5,C8
4. Aplicar frontmatter con `canonical_path` exacto antes de escribir código

❌ Violación crítica:
• Escribir código en Go porque "es más rápido", aunque la ruta indica JavaScript
• Usar ruta inventada como `src/webhooks/` en lugar de ruta canónica
• Frontmatter con `canonical_path` que no coincide con ubicación real del archivo

【EJEMPLO FLUJO ✅】
Tarea: "Validador de firma HMAC para webhooks"
→ PROJECT_TREE.md → 06-PROGRAMMING/javascript/
→ 00-STACK-SELECTOR.md → TypeScript, C3,C4,C5,C8
→ Plantilla: skill-template.md → webhook-validation-patterns.ts.md
→ Frontmatter: canonical_path: "/06-PROGRAMMING/javascript/webhook-validation-patterns.ts.md"

【EJEMPLO FLUJO ❌】
Tarea: "Validador de firma HMAC para webhooks"
→ IA elige Go por preferencia → archivo en `06-PROGRAMMING/go/`
→ Violación ARC-001: stack no coincide con dominio canónico
```

### ARC-002: LANGUAGE LOCK Enforcement (Aislamiento de Operadores)

```
【REGLA ARC-002】Los operadores y constraints están aislados por dominio; nunca se filtran entre stacks.

✅ Cumplimiento:
• `06-PROGRAMMING/go/` → cero operadores pgvector (`<->`, `<=>`, `<#>`)
• `06-PROGRAMMING/sql/` → cero constraints V1-V3
• `06-PROGRAMMING/postgresql-pgvector/` → único dominio para búsqueda vectorial
• `verify-constraints.sh --check-language-lock` se ejecuta en validación automática

❌ Violación crítica:
• Importar `github.com/pgvector/pgvector-go` en artefacto Go
• Usar `vector(1536)` en query SQL estándar
• Declarar `constraints_mapped: ["V1"]` en carpeta no vectorial

【EJEMPLO LANGUAGE LOCK ✅】
Go: `import "database/sql"` (sin drivers vectoriales)
SQL: `SELECT id, content FROM embeddings WHERE tenant_id = $1` (sin `<=>`)
pgvector: `SELECT id, embedding <=> $1 FROM vectors WHERE tenant_id = $2` (con V1,V2,V3)

【EJEMPLO LANGUAGE LOCK ❌】
Go: `SELECT embedding <-> $1 FROM vectors` ← 🚫 VIOLACIÓN ARC-002 + C4
```

### ARC-003: Tiered Delivery Contract (Modo → Tier → Formato)

```
【REGLA ARC-003】El formato de entrega está determinado por el modo operativo confirmado, no por preferencia.

✅ Mapeo canónico:
| Modo | Tier | Formato | Validación Requerida |
|------|------|---------|---------------------|
| A1/B1 | 1 | Pantalla/Editor | C5, C6 (estructura + trazabilidad) |
| A2/B2 | 2 | Código + validation_command | C1-C8 completos + lint |
| A3/B3 | 3 | ZIP con manifest + deploy.sh | C1-C8 + bundle + checksums |

✅ Cumplimiento:
• Incluir `tier: N` en frontmatter según modo confirmado en [[IA-QUICKSTART.md]]
• Entregar exactamente el formato especificado para el Tier
• Incluir `validation_command` ejecutable para Tier 2+

❌ Violación crítica:
• Entregar código Tier 2 en formato de pantalla sin `validation_command`
• Declarar `mode_selected: B3` pero entregar sin bundle ni manifest.json
• Saltar validación pre-entrega por "prisa de entrega"
```

### ARC-004: Constraint Mapping by Domain (Carpeta → Normas)

```
【REGLA ARC-004】Las constraints aplicables están mapeadas canónicamente por carpeta en [[norms-matrix.json]].

✅ Cumplimiento:
• `constraints_mapped` en frontmatter ⊆ `constraints_allowed` de la carpeta
• `constraints_mandatory` de la carpeta ⊆ `constraints_mapped` del artefacto
• Nunca inventar constraints fuera de C1-C8 y V1-V3

❌ Violación crítica:
• Declarar `constraints_mapped: ["C9"]` (no existe)
• Omitir `C4` en carpeta que lo requiere como mandatory
• Usar constraints vectoriales en dominio que las prohíbe

【EJEMPLO MAPEO ✅】
Carpeta: `06-PROGRAMMING/go/`
→ norms-matrix.json: allowed=[C1-C8], mandatory=[C3,C4,C5,C8], denied=[V1,V2,V3]
→ Artefacto: constraints_mapped: ["C3","C4","C5","C8","C7"] ✅ (subconjunto válido)
```

### ARC-005: Validation-First Workflow (Pre-Gate → Generar → Post-Validar)

```
【REGLA ARC-005】Ningún artefacto se integra sin pasar gates de validación automáticos.

✅ Flujo arquitectónico obligatorio:
1. Pre-gate: verificar ruta, lenguaje, constraints declaradas, LANGUAGE LOCK
2. Generación: aplicar plantilla SDD, ≥10 ejemplos ✅/❌/🔧 para Tier 2+
3. Post-validación: `orchestrator-engine.sh --json` → score ≥ mínimo, `blocking_issues: []`
4. Entrega: formato según Tier + checksums + audit log

❌ Violación crítica:
• Integrar código sin ejecutar `orchestrator-engine.sh`
• Aceptar score < 30 para Tier 2 "porque funciona localmente"
• Omitir `prompt_hash` o `generated_at` en frontmatter
```

### ARC-006: Separation of Concerns & Modularity

```
【REGLA ARC-006】Cada stack cumple su dominio; las integraciones cruzadas son explícitas y auditables.

✅ Cumplimiento:
• Go: microservicios, alta concurrencia, binarios estáticos
• Python: IA/ML, LangChain, prototipado rápido
• Bash: glue code, orquestación, validación de sistema
• TypeScript/JS: webhooks, n8n, frontend, bots
• SQL/pgvector: consultas relacionales y vectoriales aisladas
• YAML/Schema: validación estructural y configuración

✅ Integraciones cruzadas permitidas:
• Python → pgvector: queries vectoriales con tenant_id
• Go → SQL: queries parametrizadas con C4
• Bash → Go: ejecución con timeout + checksum
• JS → Go: webhooks con firma HMAC

❌ Violación crítica:
• Mezclar lógica de IA en scripts Bash de orquestación
• Hardcodear queries vectoriales en capa de API Go
• Acoplar configuración de infraestructura directamente en código de negocio
```

### ARC-007: Resource Limits & Concurrency (C1 + C2)

```
【REGLA ARC-007】Los límites de recursos y gestión de concurrencia son requisitos de diseño, no parches.

✅ Cumplimiento por stack:
| Stack | Límite Típico | Mecanismo de Control |
|-------|--------------|---------------------|
| Go | `debug.SetMemoryLimit(512 << 20)`, `context.WithTimeout` | `errgroup`, semáforos, `atomic.Value` |
| Python | `asyncio.TimeoutError`, `multiprocessing.Pool` | `concurrent.futures`, `uvloop` |
| Bash | `ulimit -v`, `timeout 30s comando` | `set -o pipefail`, `trap cleanup EXIT` |
| Docker | `mem_limit: 512M`, `cpus: 0.5`, `pids_limit: 100` | Healthchecks, restart policies |

✅ Patrón arquitectónico:
• Definir límites en diseño, no en runtime improvisado
• Loguear excedentes con `level: WARN` + `tenant_id`
• Fallback degradado si se alcanza límite (C7)

❌ Violación crítica:
• Loop `while True` sin sleep o condición de salida
• Goroutine sin canal de cancelación o timeout
• Docker container sin `mem_limit` en producción
```

### ARC-008: Observability & Auditability by Design (C6 + C8)

```
【REGLA ARC-008】Todo componente debe ser ejecutable, auditable y trazable por diseño.

✅ Cumplimiento:
• Logging estructurado JSON a stderr con `trace_id`, `tenant_id`, `timestamp` RFC3339
• Comandos con `--dry-run`, exit codes significativos, `trap` para cleanup
• `prompt_hash` en frontmatter para reproducibilidad forense
• Scrubbing automático de PII/secrets antes de loguear

✅ Patrón de log canónico:
```json
{
  "timestamp": "2026-04-19T12:00:00Z",
  "level": "INFO",
  "tenant_id": "cliente_001",
  "event": "validation_passed",
  "trace_id": "otel-trace-abc123",
  "artifact": "/06-PROGRAMMING/go/webhook.go.md",
  "score": 42,
  "prompt_hash": "sha256:xyz789..."
}
```

❌ Violación crítica:
• `print()` o `console.log()` en lugar de logger estructurado
• Timestamp en formato local o sin zona horaria
• Log que incluye `password` o `api_key` en texto plano
```

### ARC-009: Immutable Core vs Extensible Edges

```
【REGLA ARC-009】El núcleo de gobernanza es inmutable; los patrones de implementación son extensibles.

✅ Núcleo inmutable (`immutable: true`):
• `00-STACK-SELECTOR.md`
• `IA-QUICKSTART.md`
• `AI-NAVIGATION-CONTRACT.md`
• `GOVERNANCE-ORCHESTRATOR.md`
• `SDD-COLLABORATIVE-GENERATION.md`
• `norms-matrix.json`
• `language-lock-protocol.md`

✅ Bordes extensibles (`immutable: false`):
• `06-PROGRAMMING/<lenguaje>/` (nuevos patrones)
• `02-SKILLS/` (nuevos dominios)
• `05-CONFIGURATIONS/templates/` (nuevas plantillas)

✅ Regla de extensión:
• Nuevo stack → actualizar `PROJECT_TREE.md` + `00-STACK-SELECTOR.md` + `norms-matrix.json`
• Nuevo dominio → añadir carpeta en `02-SKILLS/` + actualizar índices
• Nueva constraint → requiere major version bump + migración guiada

❌ Violación crítica:
• Modificar núcleo inmutable sin aprobación humana + major version bump
• Añadir stack sin declarar LANGUAGE LOCK rules
• Romper compatibilidad con artefactos Tier 2 existentes sin guía de migración
```

### ARC-010: Documentation as Executable Contract

```
【REGLA ARC-010】La documentación es código ejecutable: frontmatter, wikilinks y JSON tree son contratos validables.

✅ Cumplimiento:
• Frontmatter YAML válido con campos obligatorios por Tier
• Wikilinks canónicos: `[[RUTA/DESDE/RAÍZ.md]]`, nunca `../` o `./`
• JSON tree final parseable por `jq` con metadatos para agentes
• `validation_command` en frontmatter apunta a script existente y ejecutable

✅ Verificación automática:
```bash
# Validar frontmatter
yq eval '.canonical_path' artifact.md
# Validar wikilinks
bash 05-CONFIGURATIONS/validation/check-wikilinks.sh --file artifact.md --json
# Validar JSON tree
tail -n +$(grep -n '```json' artifact.md | tail -1 | cut -d: -f1) artifact.md | \
  sed -n '/```json/,/```/p' | sed '1d;$d' | jq empty
```

❌ Violación crítica:
• Frontmatter con YAML inválido o campos faltantes
• Wikilink `[[../otra-carpeta]]` que rompe resolución canónica
• JSON tree con sintaxis inválida o claves inconsistentes
```

---

## 【2】🛡️ VALIDACIÓN AUTOMÁTICA DE REGLAS ARQUITECTÓNICAS

<!-- 
【EDUCATIVO】Estas herramientas permiten validar automáticamente el cumplimiento de ARC-001 a ARC-010.
-->

| Herramienta | Regla Validada | Comando |
|------------|---------------|---------|
| `validate-frontmatter.sh` | ARC-001, ARC-003, ARC-010 | `bash .../validate-frontmatter.sh --file artifact.md --level 2 --json` |
| `check-wikilinks.sh` | ARC-001, ARC-010 | `bash .../check-wikilinks.sh --file artifact.md --json` |
| `verify-constraints.sh` | ARC-002, ARC-004 | `bash .../verify-constraints.sh --file artifact.md --check-language-lock --json` |
| `orchestrator-engine.sh` | ARC-005, ARC-007, ARC-008 | `bash .../orchestrator-engine.sh --file artifact.md --mode headless --json` |

---

## 【3】🧭 PROTOCOLO DE DISEÑO ARQUITECTÓNICO (PASO A PASO)

```
┌─────────────────────────────────────────────────────────┐
│ 【FASE 0】DEFINIR FUNCIÓN Y RUTA CANÓNICA              │
├─────────────────────────────────────────────────────────┤
│ 1. Describir función del componente                    │
│ 2. Consultar PROJECT_TREE.md → ruta canónica           │
│ 3. Registrar canonical_path en frontmatter             │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 1】RESOLVER STACK Y CONSTRAINTS                 │
├─────────────────────────────────────────────────────────┤
│ 1. Consultar 00-STACK-SELECTOR.md → lenguaje permitido │
│ 2. Consultar norms-matrix.json → constraints allowed/mandatory │
│ 3. Declarar constraints_mapped en frontmatter          │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 2】APLICAR PLANTILLA Y GENERAR                  │
├─────────────────────────────────────────────────────────┤
│ 1. Cargar skill-template.md                            │
│ 2. Generar contenido con ≥10 ejemplos ✅/❌/🔧         │
│ 3. Incluir sección de validación con command ejecutable│
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 3】VALIDACIÓN PRE-ENTREGA                       │
├─────────────────────────────────────────────────────────┤
│ 1. Ejecutar validate-frontmatter.sh                    │
│ 2. Ejecutar check-wikilinks.sh                         │
│ 3. Ejecutar verify-constraints.sh --check-language-lock│
│ 4. Corregir fallos hasta passed: true                  │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 4】SCORING Y ENTREGA POR TIER                   │
├─────────────────────────────────────────────────────────┤
│ 1. Ejecutar orchestrator-engine.sh --json              │
│ 2. Verificar score >= mínimo, blocking_issues == []    │
│ 3. Entregar formato según Tier (pantalla/código/ZIP)   │
│ 4. Registrar audit log con prompt_hash + checksum      │
└─────────────────────────────────────────────────────────┘
```

---

## 【4】📚 GLOSARIO PARA PRINCIPIANTES

| Término | Significado simple | Ejemplo |
|---------|-------------------|---------|
| **Route-First** | La ruta canónica decide el stack, no el gusto del desarrollador | `06-PROGRAMMING/go/` → Go, siempre |
| **LANGUAGE LOCK** | Regla que aísla operadores y constraints por dominio | `<->` solo en `postgresql-pgvector/` |
| **Tiered Delivery** | Formato de entrega dictado por modo operativo | A2 → código + validation_command |
| **Validation Gate** | Paso automático que bloquea artefactos inválidos | `orchestrator-engine.sh` retorna `blocking_issues: ["C3_VIOLATION"]` |
| **Canonical Path** | Ruta absoluta desde raíz del repositorio | `/06-PROGRAMMING/python/langchain-integration.md` |
| **JSON Tree** | Sección final con metadatos estructurados para IAs | Parseable por `jq`, usado para routing automático |
| **Observability by Design** | Logs y trazabilidad integrados en arquitectura, no añadidos después | `slog` JSON a stderr con `trace_id` obligatorio |

---

## 【5】🧪 SANDBOX DE PRUEBA (OPCIONAL)

```
【TEST MODE: ARCHITECTURE-RULES VALIDATION】
Prompt de prueba: "Diseñar componente de validación de webhooks para cliente agrícola"

Respuesta esperada de la IA:
1. Identificar función → validar firmas HMAC en entrada de webhooks
2. Consultar PROJECT_TREE.md → ruta: 06-PROGRAMMING/javascript/
3. Consultar 00-STACK-SELECTOR.md → lenguaje: TypeScript, constraints: C3,C4,C5,C8
4. Declarar frontmatter con canonical_path exacto y tier: 2
5. Generar con ≥10 ejemplos ✅/❌/🔧 de validación HMAC
6. Ejecutar validación pre-entrega: frontmatter, wikilinks, LANGUAGE LOCK
7. Ejecutar orchestrator-engine.sh → score ≥ 30, blocking_issues: []
8. Entregar código + validation_command + checksum

Si la IA elige Go por preferencia, omite constraints, o entrega sin validation_command → FALLA DE ARQUITECTURA.
```

---

## 【6】🔗 REFERENCIAS CANÓNICAS (WIKILINKS)

- `[[00-STACK-SELECTOR]]` → Motor de decisión de stack
- `[[PROJECT_TREE]]` → Mapa canónico de rutas
- `[[GOVERNANCE-ORCHESTRATOR]]` → Tiers y validación
- `[[05-CONFIGURATIONS/validation/norms-matrix.json]]` → Mapeo de constraints
- `[[01-RULES/language-lock-protocol.md]]` → Aislamiento de operadores
- `[[SDD-COLLABORATIVE-GENERATION]]` → Especificación de formato
- `[[TOOLCHAIN-REFERENCE]]` → Catálogo de herramientas de validación

---

## 【7】📦 METADATOS DE EXPANSIÓN

```json
{
  "expansion_registry": {
    "new_architectural_principle": {
      "requires_files_update": [
        "01-RULES/01-ARCHITECTURE-RULES.md: add principle with format ## ARC-XXX: <TÍTULO>",
        "GOVERNANCE-ORCHESTRATOR.md: update tier definitions if principle affects validation",
        "05-CONFIGURATIONS/validation/: add tooling if principle requires new validation",
        "Human approval required: true"
      ],
      "backward_compatibility": "new principles must not invalidate existing artifacts that comply with current architecture contract"
    }
  },
  "compatibility_rule": "Nuevos principios arquitectónicos no deben romper el flujo Route-First → Stack → Constraints → Validation. Cambios breaking requieren major version bump."
}
```

---

<!-- 
═══════════════════════════════════════════════════════════
🤖 SECCIÓN PARA IA: ÁRBOL JSON ENRIQUECIDO
═══════════════════════════════════════════════════════════
-->

```json
{
  "architecture_rules_metadata": {
    "version": "3.0.0-SELECTIVE",
    "canonical_path": "/01-RULES/01-ARCHITECTURE-RULES.md",
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
    "ARC-001": {"title": "Route-First Design", "constraint": "C5", "priority": "critical", "blocking_if_violated": true, "validation_tool": "validate-frontmatter.sh + PROJECT_TREE.md resolution"},
    "ARC-002": {"title": "LANGUAGE LOCK Enforcement", "constraint": "C5", "priority": "critical", "blocking_if_violated": true, "validation_tool": "verify-constraints.sh --check-language-lock"},
    "ARC-003": {"title": "Tiered Delivery Contract", "constraint": "C6", "priority": "high", "blocking_if_violated": true, "validation_tool": "orchestrator-engine.sh --mode headless"},
    "ARC-004": {"title": "Constraint Mapping by Domain", "constraint": "C5", "priority": "high", "blocking_if_violated": true, "validation_tool": "norms-matrix.json subset check"},
    "ARC-005": {"title": "Validation-First Workflow", "constraint": "C6", "priority": "critical", "blocking_if_violated": true, "validation_tool": "orchestrator-engine.sh + pre-gate scripts"},
    "ARC-006": {"title": "Separation of Concerns", "constraint": "C7", "priority": "high", "blocking_if_violated": false, "validation_tool": "manual review + dependency graph check"},
    "ARC-007": {"title": "Resource Limits & Concurrency", "constraint": "C1, C2", "priority": "high", "blocking_if_violated": false, "validation_tool": "orchestrator-engine.sh --checks C1,C2"},
    "ARC-008": {"title": "Observability by Design", "constraint": "C6, C8", "priority": "high", "blocking_if_violated": false, "validation_tool": "orchestrator-engine.sh --checks C6,C8"},
    "ARC-009": {"title": "Immutable Core vs Extensible Edges", "constraint": "C5", "priority": "medium", "blocking_if_violated": false, "validation_tool": "frontmatter immutable flag + approval workflow"},
    "ARC-010": {"title": "Documentation as Executable Contract", "constraint": "C5, C6", "priority": "high", "blocking_if_violated": true, "validation_tool": "validate-frontmatter.sh + check-wikilinks.sh + JSON parse"}
  },
  "validation_integration": {
    "validate-frontmatter.sh": {"purpose": "Validar estructura YAML y campos obligatorios", "exit_codes": {"0": "valid", "1": "invalid"}},
    "check-wikilinks.sh": {"purpose": "Validar wikilinks canónicos", "exit_codes": {"0": "canonical", "1": "relative_or_broken"}},
    "verify-constraints.sh": {"purpose": "Validar constraints y LANGUAGE LOCK", "exit_codes": {"0": "compliant", "1": "violation"}},
    "orchestrator-engine.sh": {"purpose": "Scoring integral y validación final", "exit_codes": {"0": "passed", "1": "failed"}}
  },
  "dependency_graph": {
    "critical_infrastructure": [
      {"file": "PROJECT_TREE.md", "purpose": "Resolver rutas canónicas", "load_order": 1},
      {"file": "00-STACK-SELECTOR.md", "purpose": "Determinar lenguaje por ruta", "load_order": 2},
      {"file": "05-CONFIGURATIONS/validation/norms-matrix.json", "purpose": "Mapear constraints por carpeta", "load_order": 3},
      {"file": "GOVERNANCE-ORCHESTRATOR.md", "purpose": "Tiers y formatos de entrega", "load_order": 4}
    ],
    "validation_toolchain": [
      {"file": "05-CONFIGURATIONS/validation/orchestrator-engine.sh", "purpose": "Motor principal de validación", "load_order": 1},
      {"file": "05-CONFIGURATIONS/validation/verify-constraints.sh", "purpose": "Validación de LANGUAGE LOCK", "load_order": 2},
      {"file": "05-CONFIGURATIONS/validation/validate-frontmatter.sh", "purpose": "Validación de frontmatter", "load_order": 3}
    ]
  },
  "human_readable_errors": {
    "route_first_violation": "Ruta '{path}' no coincide con stack '{language}'. Consulte [[PROJECT_TREE.md]] y [[00-STACK-SELECTOR.md]].",
    "language_lock_violation": "Operador '{op}' prohibido en lenguaje '{lang}'. Consulte [[01-RULES/language-lock-protocol.md]].",
    "tier_format_mismatch": "Formato de entrega no coincide con Tier {tier}. Consulte [[GOVERNANCE-ORCHESTRATOR.md]] para especificación.",
    "constraint_subset_violation": "Constraints declaradas '{declared}' no son subconjunto de permitidas '{allowed}' en [[norms-matrix.json]].",
    "validation_gate_bypass": "Artefacto integrado sin pasar orchestrator-engine.sh. Ejecute: {validation_command}",
    "immutable_core_modified": "Archivo '{file}' es inmutable. Requiere aprobación humana + major version bump."
  },
  "validation_metadata": {
    "orchestrator_compatibility": ">=3.0.0-SELECTIVE",
    "schema_version": "architecture-rules.v1.json",
    "reproducibility_guarantee": "Any architecture validation can be reproduced identically using this rule set + toolchain"
  }
}
```

---

## ✅ CHECKLIST DE VALIDACIÓN POST-GENERACIÓN

````markdown
```bash
# 1. Frontmatter válido
yq eval '.canonical_path' 01-RULES/01-ARCHITECTURE-RULES.md | grep -q "/01-RULES/01-ARCHITECTURE-RULES.md" && echo "✅ Ruta canónica correcta"

# 2. Constraints mapeadas
yq eval '.constraints_mapped | length' 01-RULES/01-ARCHITECTURE-RULES.md | grep -q "6" && echo "✅ 6 constraints declaradas"

# 3. Reglas presentes
grep -c "ARC-0[0-9][0-9]:" 01-RULES/01-ARCHITECTURE-RULES.md | awk '{if($1==10) print "✅ 10 reglas arquitectónicas"; else print "⚠️ Faltan reglas"}'

# 4. JSON válido
tail -n +$(grep -n '```json' 01-RULES/01-ARCHITECTURE-RULES.md | tail -1 | cut -d: -f1) 01-RULES/01-ARCHITECTURE-RULES.md | sed -n '/```json/,/```/p' | sed '1d;$d' | jq empty && echo "✅ JSON parseable"
```
````

> 🎯 **Mensaje final**: Este plano es tu garantía estructural. No es negociable.  
> **Ruta → Stack → Constraints → Validación → Entrega**.  
> Si sigues ese flujo, nunca romperás la arquitectura.  
