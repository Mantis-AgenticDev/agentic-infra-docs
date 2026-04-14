---
title: "ORQUESTADOR CENTRALIZADO DE GOBERNANZA SDD"
version: "1.1.0"
canonical_path: "/GOVERNANCE-ORCHESTRATOR.md"
ai_optimized: true
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8"]
validation_command: "./05-CONFIGURATIONS/validation/orchestrator-engine.sh --file <path> --mode <interactive|headless> --json"
related_files:
  - "[[05-CONFIGURATIONS/validation/orchestrator-engine.sh]]"
  - "[[05-CONFIGURATIONS/validation/norms-matrix.json]]"
  - "[[05-CONFIGURATIONS/validation/audit-secrets.sh]]"
  - "[[05-CONFIGURATIONS/validation/check-rls.sh]]"
  - "[[05-CONFIGURATIONS/validation/check-wikilinks.sh]]"
  - "[[05-CONFIGURATIONS/validation/schema-validator.py]]"
  - "[[05-CONFIGURATIONS/validation/validate-frontmatter.sh]]"
  - "[[05-CONFIGURATIONS/validation/verify-constraints.sh]]"
  - "[[05-CONFIGURATIONS/scripts/packager-assisted.sh]]"
  - "[[PROJECT_TREE.md]]"
  - "[[01-RULES/00-INDEX.md]]"
  - "[[01-RULES/01-ARCHITECTURE-RULES.md]]"
  - "[[01-RULES/06-MULTITENANCY-RULES.md]]"
  - "[[02-SKILLS/00-INDEX.md]]"
  - "[[05-CONFIGURATIONS/00-INDEX.md]]"
  - "[[SDD-COLLABORATIVE-GENERATION.md]]"
---

# 🧠 ORQUESTADOR CENTRALIZADO DE GOBERNANZA SDD
**Sistema de Certificación Automatizada para Generación Agéntica**

> **Propósito**: Traducir normas C1-C8, requisitos multi-tenant, políticas de no-regresión y estándares de hardening en decisiones binarias, certificadas y ejecutables.
>
> **Alcance**: Todo artefacto generado por IA bajo `agentic-infra-docs/` debe pasar por este orquestador antes de merge o deploy.
>
> **Autoridad**: MiniMax Agent (Senior Auditor) + Matriz de Normas Canónicas [[05-CONFIGURATIONS/validation/norms-matrix.json]]

---

## 📋 METADATOS CANÓNICOS

| Campo | Valor | Referencia |
|-------|-------|-----------|
| `canonical_path` | `/GOVERNANCE-ORCHESTRATOR.md` | [[PROJECT_TREE.md]] |
| `ai_optimized` | `true` | [[01-RULES/09-AGENTIC-OUTPUT-RULES.md]] |
| `constraints_mapped` | `C1-C8` | [[01-RULES/00-INDEX.md]] |
| `validation_command` | `./05-CONFIGURATIONS/validation/orchestrator-engine.sh --file <path> --mode <interactive\|headless>` | [[05-CONFIGURATIONS/validation/orchestrator-engine.sh]] |
| `tier_target` | `3` | [[01-RULES/07-SCALABILITY-RULES.md]] |
| `last_audit` | `2026-04-14` | [[08-LOGS/validation/integrity-report-20260414.json]] |
| `audit_authority` | `MiniMax Agent + norms-matrix.json` | [[05-CONFIGURATIONS/validation/norms-matrix.json]] |

---

## 1. RESUMEN EJECUTIVO

Este documento define el **Orquestador Centralizado de Gobernanza SDD** como el sistema nervioso central que traduce las normas C1-C8, los requisitos multi-tenant, las políticas de no-regresión y los estándares de hardening en decisiones binarias, certificadas y ejecutables.

El orquestador cierra la brecha entre "generación asistida" y "autogeneración autónoma", proporcionando control total sobre la madurez de cada artefacto antes de que toque producción.

### 1.1 Problema que Resuelve

| Problema Actual | Impacto | Solución del Orquestador |
|-----------------|---------|--------------------------|
| Validadores funcionando de forma fragmentada | Falsos positivos/negativos | Punto único de coordinación [[05-CONFIGURATIONS/validation/orchestrator-engine.sh]] |
| Sin criterio unificado para aptitud de archivos | Merge automático de archivos inválidos | Clasificación por tiers certificada (Capa 3) |
| Validaciones genéricas en carpetas con propósitos distintos | Errores por contexto equivocado | Enrutamiento inteligente por tipo/ubicación [[05-CONFIGURATIONS/validation/norms-matrix.json]] |
| Multi-tenancy sin enforcement automático | Fugas de datos LGPD | Verificación obligatoria C4 + `check-rls.sh` |
| Falta de "contrato vivo" entre normas y decisiones | Dependencia de memoria del desarrollador | Traducción normativa → binaria ejecutable |

### 1.2 Objetivos de Control

- **OC-01**: Toda generación de IA debe pasar por `orchestrator-engine.sh` antes de merge [[05-CONFIGURATIONS/validation/orchestrator-engine.sh]]
- **OC-02**: Cada artefacto recibe clasificación de tier (1, 2, 3) basada en madurez funcional (Capa 3)
- **OC-03**: Los tiers 2 y 3 son idempotentes y deterministas (verificación en `calculate_tier_score()`)
- **OC-04**: Los validadores externos se invocan según `norms-matrix.json`, nunca arbitrariamente [[05-CONFIGURATIONS/validation/norms-matrix.json]]
- **OC-05**: El orquestador genera evidencia auditable en formato JSON para CI/CD (`generate_json_report()`)

---

## 2. ARQUITECTURA DEL MOTOR DE DECISIÓN POR CAPAS

### 2.1 Vista General de Capas

```
┌─────────────────────────────────────────────────────────────────┐
│                    CAPA 4: ENRUTAMIENTO Y ACCIÓN                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │ CI/CD GATE   │  │ REPORTE JSON │  │ BLOQUEO      │           │
│  │ [[.github/   │  │ generate_    │  │ exit codes   │           │
│  │ workflows/]] │  │ json_report()│  │ 0-5          │           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
├─────────────────────────────────────────────────────────────────┤
│                    CAPA 3: CERTIFICACIÓN POR NIVELES            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │ TIER 1       │  │ TIER 2       │  │ TIER 3       │           │
│  │ SDD Asistida │  │ Autogeneración│  │ Auto-Deploy  │           │
│  │ ≥5 ejemplos  │  │ ≥10 ejemplos │  │ SHA256+ZIP   │           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
├─────────────────────────────────────────────────────────────────┤
│                    CAPA 2: FILTRO NORMATIVO C1-C8               │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐         │
│  │   C1   │ │   C2   │ │   C3   │ │   C4   │ │   C5   │ ...     │
│  │Resource│ │Limits  │ │Zero-HC │ │TenantID│ │Val.Cmds│         │
│  │[[01-   │ │[[01-   │ │[[audit-│ │[[check-│ │[[validate│        │
│  │RULES/  │ │RULES/  │ │secrets.│ │rls.sh]]│ │-frontmatter.│    │
│  │02-...]]│ │02-...]]│ │sh]]    │ │        │ │sh]]     │        │
│  └────────┘ └────────┘ └────────┘ └────────┘ └────────┘         │
├─────────────────────────────────────────────────────────────────┤
│                    CAPA 1: IDENTIDAD Y CONTEXTO                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │ Tipo archivo │  │ Ubicación    │  │ Función      │           │
│  │ (.sh/.tf...) │  │ (/02-SKILLS) │  │ (pattern/sdd)│           │
│  │ identify_    │  │ identify_    │  │ identify_    │           │
│  │ file_type()  │  │ file_location()│file_function()│           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Capa 1: Identidad y Contexto

**Propósito**: Antes de validar, el motor responde a preguntas fundamentales sobre el artefacto.

| Pregunta | Valores Posibles | Acción si Falla | Función en `orchestrator-engine.sh` |
|----------|------------------|-----------------|-------------------------------------|
| ¿Qué tipo de archivo es? | `.sh`, `.tf`, `.yaml`, `.md`, `.json`, `.yml`, `.py` | RECHAZO INMEDIATO (exit 3) | `identify_file_type()` |
| ¿En qué rama vive? | `00-CONTEXT/`, `01-RULES/`, `02-SKILLS/`, `03-AGENTS/`, `04-WORKFLOWS/`, `05-CONFIGURATIONS/` | RECHAZO INMEDIATO (exit 3) | `identify_file_location()` |
| ¿Qué función cumple? | `documentation`, `pattern`, `configuration`, `agent-definition`, `pipeline` | ADVERTENCIA (no bloqueante) | `identify_file_function()` |
| ¿Tiene metadatos canónicos? | `canonical_path`, `ai_optimized`, `constraints_mapped` presentes | RECHAZO INMEDIATO (exit 3) | `verify_frontmatter()` |

**Regla de Oro C1.1**: Si falta identidad clara → **RECHAZO INMEDIATO**. No avanza a capas inferiores. [[01-RULES/01-ARCHITECTURE-RULES.md]]

**Flujo de Identificación**:

```yaml
identificacion:
  paso_1: Extraer extensión del archivo → identify_file_type()
  paso_2: Identificar directorio padre → identify_file_location()
  paso_3: Clasificar función según PROJECT_TREE.md → identify_file_function()
  paso_4: Verificar presencia de frontmatter canónico → verify_frontmatter()
  paso_5: Si algún paso falla → TERMINAR con código 3 (IDENTITY_MISSING)
```

### 2.3 Capa 2: Filtro Normativo C1-C8 (CON MATRIZ DINÁMICA)

**Propósito**: Aplicar las reglas base de forma obligatoria, sin excepciones, usando `norms-matrix.json` para validación contextual.

#### Matriz de Criticidad Normativa

| Norma | Descripción | Criticidad | Acción si Falla | Función en Script |
|-------|-------------|------------|-----------------|------------------|
| **C1** | Límites de recursos declarados | ALTA | ADVERTENCIA BLOQUEANTE (Tier 2-3) | `check_constraint_c1()` |
| **C2** | Límites de CPU/concurrencia | MEDIA | ADVERTENCIA NO BLOQUEANTE | `check_constraint_c2()` |
| **C3** | Zero Hardcode (${VAR:?}, sensitive=true) | **CRÍTICA** | **BLOQUEO CRÍTICO** (exit 2) | `check_constraint_c3()` + `audit-secrets.sh` |
| **C4** | tenant_id presente/forzado | **CRÍTICA** | **BLOQUEO CRÍTICO** (exit 2) | `check_constraint_c4()` + `check-rls.sh` |
| **C5** | Comando de validación declarado | ALTA | ADVERTENCIA BLOQUEANTE (Tier 2-3) | `check_constraint_c5()` |
| **C6** | Cloud-only inference (no localhost:11434) | ALTA | ADVERTENCIA BLOQUEANTE | `check_constraint_c6()` |
| **C7** | Resiliencia declarada (timeouts, retries) | MEDIA | ADVERTENCIA NO BLOQUEANTE | `check_constraint_c7()` |
| **C8** | Observabilidad (JSON logs, trace_id) | MEDIA | ADVERTENCIA NO BLOQUEANTE | `check_constraint_c8()` |

#### Lógica de Decisión C3/C4 (Ejecutada en `run_capa2_normative()`)

```bash
# Pseudocódigo ejecutado en orchestrator-engine.sh
SI C3_FALLA(archivo) ENTONCES
    → GENERAR_BLOQUEO_CRITICO("Hardcoded detected: " + ubicacion)
    → CHECKS_FAILED+=("c3_zero_hardcode: FAIL")
    → capa2_failed=true
    → DETENER_EJECUCION_PARA_TIER_3
FIN_SI

SI C4_FALLA(archivo) Y (ruta_contiene("DB-RAG") O ruta_contiene("configurations")) ENTONCES
    → GENERAR_BLOQUEO_CRITICO("tenant_id missing: " + ubicacion)
    → CHECKS_FAILED+=("c4_tenant_id: FAIL")
    → capa2_failed=true
    → DETENER_EJECUCION_PARA_TIER_3
FIN_SI
```

#### Integración con norms-matrix.json

La función `run_capa2_normative()` consulta `norms-matrix.json` para aplicar validación contextual:

```bash
# 1. Consultar perfil desde matriz
norms_profile=$(query_norms_profile "$TARGET_FOLDER_CATEGORY" "$TARGET_FILE_TYPE" "$TARGET_FUNCTION")

# 2. Iterar constraints según intensidad del perfil
for constraint in C1 C2 C3 C4 C5 C6 C7 C8; do
    intensity=$(get_constraint_intensity "$norms_profile" "$constraint")
    case "$intensity" in
        "mandatory")  # Bloqueo crítico si falla
        "applicable") # Advertencia para Tier 2-3
        "contextual") # Solo si función lo requiere
        "not_applicable") # Omitir
    esac
done

# 3. Ejecutar validadores externos según lista activa del perfil
active_validators=$(get_active_validators "$norms_profile")
for validator in $active_validators; do
    run_validator "$validator" "$TARGET_FILE"
done
```

[[05-CONFIGURATIONS/validation/norms-matrix.json]]

### 2.4 Capa 3: Certificación por Niveles

**Propósito**: Evaluar madurez funcional y asignar un tier automático basado en puntaje cuantitativo.

#### Definición de Tiers

| Tier | Nombre | Color | Umbral Mínimo | Acción Automática | Uso Típico |
|------|--------|-------|---------------|-------------------|------------|
| 🟢 **1** | SDD Asistida por IA | Verde | Sintaxis OK + C1-C8 base + ≥5 ejemplos + frontmatter válido | Requiere aprobación humana. Se muestra en pantalla/PR. | Skills en progreso, docs técnicos, schemas referenciales, `README` de carpetas. |
| 🟡 **2** | Autogeneración + Entrega Pantalla | Amarillo | Nivel 1 + 0 placeholders + validador ejecutable + ≥10 ejemplos + determinismo | Merge automático tras gate CI. Salida directa de IA. | Scripts bash, configs Docker/Terraform, assertions `promptfoo`, definiciones de agentes, queries SQL con `tenant_id` forzado. |
| 🔴 **3** | Auto-Deploy + ZIP Autónomo | Rojo | Nivel 2 + idempotencia + healthcheck/rollback + CI/CD trigger + SHA256 + namespace aislado | Pipeline directo. Genera ZIP firmado. Deploy sin intervención. | `docker-compose` con healthchecks, workflows n8n con nodos de error, módulos Terraform con RLS, `packager-assisted.sh` outputs. |

#### Algoritmo de Asignación de Tier (`calculate_tier_score()`)

```bash
FUNCION calculate_tier_score() → tier
    score=0

    # === FACTORES QUE SUMAN ===
    SI tiene_sintaxis_valida(archivo) → score += 10
    SI pasa_C1_C8(archivo) → score += checks_passed * 2
    SI tiene_ejemplos(archivo) >= 10 → score += 15
    SI tiene_frontmatter_valido(archivo) → score += 10
    SI tiene_validador_ejecutable(archivo) → score += 15
    SI es_determinista(archivo) → score += 15
    SI tiene_healthcheck(archivo) → score += 10
    SI tiene_namespace_aislado(archivo) → score += 10
    SI tiene_sha256(archivo) → score += 5

    # === FACTORES QUE RESTAN ===
    SI tiene_placeholders(archivo) → score -= placeholder_count * 5

    # === ASIGNACIÓN ===
    SI score >= 80 → FINAL_TIER=3; log_success "🏆 TIER 3"
    SI score >= 50 → FINAL_TIER=2; log_success "🥈 TIER 2"
    SI score >= 20 → FINAL_TIER=1; log_success "🥉 TIER 1"
    SI score < 20 → FINAL_TIER=0; log_error "❌ RECHAZADO"
FIN_FUNCION
```

[[05-CONFIGURATIONS/validation/orchestrator-engine.sh#L1200-L1300]]

### 2.5 Capa 4: Enrutamiento y Acción

**Propósito**: Según el tier asignado y la ubicación, decidir qué validadores invocar y qué acciones tomar.

#### Matriz de Acciones por Tier

| Tier | Invocar Validadores | Gate CI/CD | Generar Reporte | Acción de Merge |
|------|---------------------|------------|------------------|-----------------|
| 1 | Básicos (sintaxis, frontmatter) | NO | JSON + humano | Requiere aprobación manual |
| 2 | Todos los aplicables según `norms-matrix.json` | SI | JSON estructurado | Merge automático tras pass |
| 3 | Todos + `packager-assisted.sh` | SI + firma SHA256 | JSON + SHA256 + manifest | Deploy directo con rollback |

#### Flujo de Enrutamiento (`determine_exit_action()`)

```bash
SI BLOCKING_MESSAGE contiene "C3_FAIL" O "C4_FAIL" → EXIT_CODE=2 (CRITICAL_BLOCK)
SI FINAL_TIER == 0 → EXIT_CODE=1 (VALIDATION_FAILED)
SI FINAL_TIER >= 1 → EXIT_CODE=0 (SUCCESS)

# En modo headless + JSON:
generate_json_report() {
  echo {
    "tier_certified": $FINAL_TIER,
    "next_step": "$(case $FINAL_TIER in 3) echo "deploy_allowed";; 2) echo "merge_allowed";; 1) echo "human_review_required";; *) echo "rejected";; esac)",
    "ci_gate_required": $([ $FINAL_TIER -ge 2 ] && echo "true" || echo "false"),
    "sha256": "$SHA256_CHECKSUM"
  }
}
```

---

## 3. MATRIZ DE MAPEO: UBICACIÓN × FUNCIÓN × NORMATIVA

### 3.1 Matriz Principal (Resumen de norms-matrix.json)

| Directorio | Función | Archivos Predominantes | Validadores Activados | Normas Críticas | Tier Objetivo |
|------------|---------|------------------------|----------------------|-----------------|---------------|
| `00-CONTEXT/` | Docs base, overview | `.md` | `check-wikilinks.sh`, `validate-frontmatter.sh` | Coherencia con `[[PROJECT_TREE.md]]`, frontmatter puro | 1 |
| `01-RULES/` | Normas canónicas | `.md`, `.sh` | `verify-constraints.sh`, `audit-secrets.sh` | C1-C8 explícitos, sin placeholders, trazabilidad | 2 |
| `02-SKILLS/` | Patrones, schemas, queries | `.md`, `.json` | `check-rls.sh` (si DB), `schema-validator.py` | C4 forzado, `tenant_id` en queries/índices, ≥10 ejemplos | 1 → 2 |
| `02-SKILLS/BASE DE DATOS-RAG/` | Queries, configs DB | `.md`, `.sql` | `check-rls.sh --strict` | C4 obligatorio, RLS policies verificadas | 2 |
| `03-AGENTS/` | Definiciones de agentes | `.md`, `.json` | `audit-secrets.sh`, `check-wikilinks.sh` | C4/C7/C8, tenant awareness, error handling | 2 |
| `04-WORKFLOWS/` | JSON n8n, pipelines | `.json` | `schema-validator.py`, `packager-assisted.sh` | C3/C5/C7, nodos de rollback, CI/CD compatible | 2 → 3 |
| `05-CONFIGURATIONS/` | Infra, deploy, scripts | `.sh`, `.tf`, `.yaml`, `.yml` | `validate-frontmatter.sh`, `audit-secrets.sh`, linters | C1-C8 completos, secrets management, healthchecks, idempotencia | 2 → 3 |
| `05-CONFIGURATIONS/validation/` | Scripts de validación | `.sh`, `.py` | Todos menos self | C3/C5/C7, logging estructurado | 3 |
| `06-PROGRAMMING/` | Patrones de código | `.js`, `.py`, `.sql` | Linters según tipo | Sintaxis estricta, `tenant_id` en queries, zero-hardcode | 1 → 2 |
| `07-PROCEDURES/` | Runbooks, checklists | `.md` | `check-wikilinks.sh` | Pasos claros, checks pre/post, referencias cruzadas | 1 |
| `08-LOGS/` | Auditoría, reports | `.json`, `.log` | `schema-validator.py` | Formato JSON, rotación, `tenant_id`/`trace_id` | 3 (si auto-gen) |

[[05-CONFIGURATIONS/validation/norms-matrix.json#matrix_by_location]]

### 3.2 Matriz de Validadores por Tipo de Archivo

| Extensión | shebang/Header | Validadores Específicos | Check Adicional | Frontmatter |
|-----------|----------------|-------------------------|-----------------|-------------|
| `.sh` | `#!/bin/bash -euo pipefail` | `bash -n`, `shellcheck` | JSON via heredoc (`cat <<EOF \| jq .`) | `# ---` comentado |
| `.tf` | N/A (Terraform) | `terraform fmt`, `terraform validate` | Bloques `validation {}`, `sensitive = true` | YAML puro |
| `.yaml` / `.yml` | N/A | `yamllint`, `docker compose config --quiet` | Estructura asserts, sin tabs | YAML puro |
| `.md` | N/A | `check-wikilinks.sh`, `validate-frontmatter.sh` | ≥5 ejemplos ✅/❌/🔧, fences | YAML puro |
| `.json` | N/A | `jq empty`, `schema-validator.py` | Sin trailing commas, schema strict | N/A |
| `.py` | `#!/usr/bin/env python3` | `python3 -m py_compile` | Importaciones válidas | `# ---` comentado |

[[05-CONFIGURATIONS/validation/norms-matrix.json#extension_decision_rules]]

---

## 4. INTEGRACIÓN CON VALIDADORES EXISTENTES

### 4.1 Catálogo de Validadores

El orquestador **no reemplaza**. **Coordina**. Cada validador mantiene su responsabilidad específica.

#### 4.1.1 audit-secrets.sh

| Atributo | Valor |
|----------|-------|
| **URL Raw** | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/audit-secrets.sh` |
| **Propósito** | Detector C3 - Identificar hardcoded secrets |
| **Norma Asociada** | C3 (Zero Hardcode) [[01-RULES/03-SECURITY-RULES.md]] |
| **Cuándo se Invoca** | Siempre que haya archivos con credenciales/env vars |
| **Patrón de Llamada** | `./audit-secrets.sh --file <archivo>` |
| **Códigos de Retorno** | 0 = limpio, 1 = secretos detectados |
| **Dependencias** | `grep`, `sed` |

#### 4.1.2 check-rls.sh

| Atributo | Valor |
|----------|-------|
| **URL Raw** | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/check-rls.sh` |
| **Propósito** | Verificador C4 - Verificar RLS policies en PostgreSQL |
| **Norma Asociada** | C4 (Multi-tenancy) [[01-RULES/06-MULTITENANCY-RULES.md]] |
| **Cuándo se Invoca** | Solo en `02-SKILLS/BASE DE DATOS-RAG/` o configs SQL/PostgreSQL |
| **Patrón de Llamada** | `./check-rls.sh --file <archivo_sql>` |
| **Códigos de Retorno** | 0 = RLS OK, 1 = RLS faltante o incorrecto |
| **Dependencias** | `grep`, archivo SQL |

#### 4.1.3 check-wikilinks.sh

| Atributo | Valor |
|----------|-------|
| **URL Raw** | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/check-wikilinks.sh` |
| **Propósito** | Validador de referencias canónicas en markdown |
| **Norma Asociada** | Coherencia estructural [[01-RULES/05-CODE-PATTERNS-RULES.md]] |
| **Cuándo se Invoca** | En `.md` y docs técnicos |
| **Patrón de Llamada** | `./check-wikilinks.sh --file <markdown>` |
| **Códigos de Retorno** | 0 = links OK, 1 = links rotos o no-canónicos |
| **Dependencias** | `grep`, `find` |

#### 4.1.4 schema-validator.py

| Atributo | Valor |
|----------|-------|
| **URL Raw** | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/schema-validator.py` |
| **Propósito** | Validador JSON Schema |
| **Norma Asociada** | Estructura canónica [[05-CONFIGURATIONS/validation/schemas/skill-input-output.schema.json]] |
| **Cuándo se Invoca** | En `.json` y payloads de IA |
| **Patrón de Llamada** | `python3 schema-validator.py --file <archivo.json>` |
| **Códigos de Retorno** | 0 = válido, 1 = inválido |
| **Dependencias** | Python 3, `jsonschema` |

#### 4.1.5 validate-frontmatter.sh

| Atributo | Valor |
|----------|-------|
| **URL Raw** | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/validate-frontmatter.sh` |
| **Propósito** | Verificador de metadatos canónicos |
| **Norma Asociada** | Frontmatter requerido [[01-RULES/09-AGENTIC-OUTPUT-RULES.md]] |
| **Cuándo se Invoca** | En `.md`, `.yaml`, `.json`, `.tf` |
| **Patrón de Llamada** | `./validate-frontmatter.sh --file <archivo>` |
| **Códigos de Retorno** | 0 = frontmatter OK, 1 = frontmatter inválido o ausente |
| **Dependencias** | `grep`, `sed`, `yq` (opcional) |

#### 4.1.6 verify-constraints.sh

| Atributo | Valor |
|----------|-------|
| **URL Raw** | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/verify-constraints.sh` |
| **Propósito** | Check C1-C6 textual |
| **Norma Asociada** | C1, C2, C3, C4, C5, C6 [[01-RULES/00-INDEX.md]] |
| **Cuándo se Invoca** | En todos los archivos ejecutables/config |
| **Patrón de Llamada** | `./verify-constraints.sh --file <archivo>` |
| **Códigos de Retorno** | 0 = constraints OK, 1 = constraint violado |
| **Dependencias** | `grep`, `sed` |

#### 4.1.7 packager-assisted.sh

| Atributo | Valor |
|----------|-------|
| **URL Raw** | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/scripts/packager-assisted.sh` |
| **Propósito** | Generador de ZIP con checksums |
| **Norma Asociada** | Tier 3 [[01-RULES/07-SCALABILITY-RULES.md]] |
| **Cuándo se Invoca** | Solo en Tier 3, post-certificación |
| **Patrón de Llamada** | `./packager-assisted.sh --source <directorio> --output <zip>` |
| **Códigos de Retorno** | 0 = paquete generado OK, 1 = error |
| **Dependencias** | `zip`, `sha256sum` |

### 4.2 Flujo de Orquestación (ASCII Diagram)

```
┌─────────────────────────────────────────────────────────────────┐
│                    INICIO: archivo recibido                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ IDENTIFICAR TIPO                                                │
│  - Extensión → validador específico                             │
│  - Directorio → normas aplicables                               │
│  Funciones: identify_file_type(), identify_file_location()     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ CAPA 1: IDENTIDAD                                               │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ • Tipo de archivo: ¿Reconocido?                         │    │
│  │ • Ubicación: ¿En PROJECT_TREE?                          │    │
│  │ • Frontmatter: ¿Presente y válido?                      │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                  │
│              ┌───────────────┴───────────────┐                  │
│              │ FALLA → RECHAZO INMEDIATO     │                  │
│              │ Código 3, mensaje: "ID_FAIL"  │                  │
│              └───────────────────────────────┘                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ CAPA 2: NORMATIVA C1-C8 (Matriz Dinámica)                       │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ 1. Consultar norms-matrix.json → perfil de normas       │    │
│  │ 2. Iterar C1-C8 según intensidad (mandatory/applicable) │    │
│  │ 3. Ejecutar validadores externos según lista activa     │    │
│  │ 4. C3/C4 mandatory → bloqueo crítico si falla           │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                  │
│              ┌───────────────┴───────────────┐                  │
│              │ C3 o C4 FALLA → BLOQUEO       │                  │
│              │ Código 2, mensaje: "C3_FAIL"  │                  │
│              │              o "C4_FAIL"      │                  │
│              └───────────────────────────────┘                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ CAPA 3: CERTIFICACIÓN TIER                                      │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ 1. Contar ejemplos (≥5 T1, ≥10 T2)                      │    │
│  │ 2. Verificar determinismo (0 placeholders)              │    │
│  │ 3. Verificar resiliencia (timeouts, retries)            │    │
│  │ 4. Calcular puntaje → asignar TIER_1/2/3                │    │
│  │ 5. Calcular SHA256 para TIER_3                          │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ CAPA 4: ENRUTAMIENTO                                            │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ CASE tier OF                                            │    │
│  │   TIER_1: → Mostrar en PR, requerir approval humano     │    │
│  │   TIER_2: → Merge automático tras CI gate pass          │    │
│  │   TIER_3: → Invoke packager → Deploy con rollback       │    │
│  │ ESAC                                                    │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                  │
│              ┌───────────────┴───────────────┐                  │
│              │ Generar reporte JSON          │                  │
│              │ {tier, passed, failed, sha256}│                  │
│              └───────────────────────────────┘                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    FIN: resultado emitido                       │
│  • Modo interactivo: print_summary()                            │
│  • Modo headless: generate_json_report()                        │
│  • Exit code: 0=SUCCESS, 1=FAIL, 2=CRITICAL, 3=ID_MISSING      │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. DOBLE INTERFAZ: HUMANO VS IA

### 5.1 Modo Terminal Interactivo (Humano)

**Activación**: `./05-CONFIGURATIONS/validation/orchestrator-engine.sh --mode interactive`

#### Flujo de Preguntas Guiadas

```
========================================
  ORQUESTADOR SDD - MODO INTERACTIVO
========================================

1. ¿Qué archivo estás validando?
   > Ruta: _________________________

2. ¿En qué carpeta se ubicará?
   > Opciones: [00-CONTEXT, 01-RULES, 02-SKILLS, 03-AGENTS, 04-WORKFLOWS, 05-CONFIGURATIONS, 06-PROGRAMMING, 07-PROCEDURES]
   > Selección: ___________________

3. ¿Cuál es su función principal?
   > Opciones: [documentation, pattern, configuration, agent-definition, pipeline, skill, script]
   > Selección: ___________________

4. ¿Cuál es el tier objetivo?
   > Opciones: [1-SDD, 2-Autogen, 3-AutoDeploy]
   > Selección: ___________________

========================================
  VALIDADORES A EJECUTAR (según norms-matrix.json)
========================================
   [✓] validate-frontmatter.sh
   [✓] audit-secrets.sh
   [✓] verify-constraints.sh
   [ ] check-rls.sh (solo si DB-RAG)
   [ ] schema-validator.py (solo si JSON)

========================================
  RESULTADO
========================================
   ✅ CERTIFICADO: NIVEL 2
   📋 ACCIÓN: Merge automático tras gate CI

--- DETALLES ---
   Passed: 8/8 checks
   Warnings: 2 (no-bloqueantes)
   SHA256: a3f5c8d9e1b2...
========================================
```

#### Salidas Posibles

| Resultado | Código | Color | Significado | Acción |
|-----------|--------|-------|-------------|--------|
| `✅ CERTIFICADO: TIER_3` | 0 | Verde | Pasa todos los checks | Deploy automático |
| `✅ CERTIFICADO: TIER_2` | 0 | Verde | Pasa checks requeridos | Merge automático |
| `✅ CERTIFICADO: TIER_1` | 0 | Verde | Pasa checks base | Requiere approval humano |
| `⚠️ ADVERTENCIA` | 0 | Amarillo | Fallas menores | Revisar y re-ejecutar |
| `📋 REQUIERE CORRECCIÓN` | 1 | Rojo | Falla bloqueante | Corregir y re-ejecutar |
| `🚫 BLOQUEO CRÍTICO` | 2 | Rojo | C3/C4 violado | Abortar |

### 5.2 Modo Headless (IA / Autogeneración)

**Activación**: `./05-CONFIGURATIONS/validation/orchestrator-engine.sh --mode headless --file <path> --json`

#### Payload de Entrada (JSON)

```json
{
  "file_path": "02-SKILLS/INFRAESTRUCTURA/docker-compose-networking.md",
  "file_type": ".md",
  "target_folder": "02-SKILLS/INFRAESTRUCTURA",
  "function": "documentation",
  "constraints_declared": ["C1", "C2", "C3", "C4", "C5"],
  "expected_tier": 2
}
```

#### Payload de Salida (JSON) - Schema Validado

```json
{
  "orchestrator_version": "1.1.0",
  "timestamp": "2026-04-14T11:49:33Z",
  "file_path": "02-SKILLS/INFRAESTRUCTURA/docker-compose-networking.md",
  "tier_certified": 2,
  "tier_requested": 2,
  "tier_match": true,
  "passed_checks": [
    {"check": "identity_type", "status": "PASS", "details": ".md recognized"},
    {"check": "identity_location", "status": "PASS", "details": "02-SKILLS/INFRAESTRUCTURA valid"},
    {"check": "frontmatter_present", "status": "PASS"},
    {"check": "c1_resources_declared", "status": "PASS"},
    {"check": "c3_zero_hardcode", "status": "PASS"},
    {"check": "c4_tenant_id", "status": "PASS", "details": "tenant_id found in 3 locations"},
    {"check": "examples_count", "status": "PASS", "count": 12, "minimum": 10},
    {"check": "determinism", "status": "PASS", "placeholders": 0}
  ],
  "blocking_issues": [],
  "warnings": [
    {"check": "c7_resilience", "severity": "LOW", "message": "No explicit timeout declared"}
  ],
  "validators_invoked": [
    "validate-frontmatter.sh",
    "audit-secrets.sh",
    "verify-constraints.sh"
  ],
  "sha256": "a3f5c8d9e1b2478...",
  "next_step": "merge_allowed",
  "ci_gate_required": true,
  "human_approval_required": false
}
```

[[05-CONFIGURATIONS/validation/schemas/skill-input-output.schema.json]]

---

## 6. BLINDAJE MULTI-TENANT Y NO-REGRESIÓN

### 6.1 Verificación Multi-Tenant (C4 Enforcement)

Cuando el archivo toca esquemas DB o configs de EspoCRM/MySQL:

#### Reglas Obligatorias

| Componente | Verificación | Fallo si | Función en Script |
|------------|-------------|----------|------------------|
| Tablas | Prefijo `tenant_id` como segundo campo | `CREATE TABLE` sin `tenant_id` | `check_constraint_c4()` + `check-rls.sh` |
| Queries | `WHERE tenant_id = $1` o equivalente | `SELECT *` sin filtro | `check-rls.sh --strict` |
| Índices | Compuestos iniciando con `tenant_id` | Índice sin `tenant_id` | `check-rls.sh` |
| Policies | RLS policy activa por tabla | Sin `CREATE POLICY` | `check-rls.sh` |
| Volumes | Label `tenant_id` presente | Sin label en volúmenes | `verify-constraints.sh` |
| Logs | `tenant_id` en cada entrada | Logs sin aislamiento | `verify-constraints.sh` |

#### Check Automático en `run_capa2_normative()`

```bash
# Si el archivo está en DB-RAG o configurations y es SQL/TF/YAML
if [[ "$TARGET_FOLDER_CATEGORY" == "database-rag" || "$TARGET_FOLDER_CATEGORY" == "configurations" ]]; then
    if ! check_constraint_c4; then
        log_error "🚫 BLOQUEO CRÍTICO: C4 violado"
        BLOCKING_MESSAGE="C4_FAIL: tenant_id missing"
        capa2_failed=true
    fi
fi

# Invocar check-rls.sh si aplica
if [[ "$TARGET_FILE_TYPE" == "sql" || "$TARGET_FILE_TYPE" == "terraform" ]]; then
    run_validator "check-rls.sh" "$TARGET_FILE"
fi
```

[[01-RULES/06-MULTITENANCY-RULES.md]]

### 6.2 Aislamiento de Namespace

#### Prefijos Obligatorios

| Recurso | Prefijo Requerido | Ejemplo | Verificación |
|---------|-------------------|---------|-------------|
| Contenedores | `mantis-vpsX-` | `mantis-vps1-n8n`, `mantis-vps2-uazapi` | `grep -q 'mantis-vps'` |
| Volúmenes | `tenant_` | `tenant_facundo_data` | `grep -q 'tenant_'` |
| Redes | `kb_` | `kb_internal_net` | `grep -q 'kb_'` |
| Bases de datos | `mantis_` | `mantis_espocrm_prod` | `grep -q 'mantis_'` |
| Tablas | `mbt_` | `mbt_contacts`, `mbt_opportunities` | `grep -q 'mbt_'` |

#### Verificación de Colisión en `check_healthcheck_tier3()`

```bash
# Verificar namespace
local namespace_patterns=("mantis-vps" "tenant_" "kb_")
local has_namespace=false
for pattern in "${namespace_patterns[@]}"; do
    if grep -qE "$pattern" "$file" 2>/dev/null; then
        has_namespace=true
        break
    fi
done

if [[ "$has_namespace" == "true" ]]; then
    CHECKS_PASSED+=("tier3_namespace: PASS (prefijo aislado)")
else
    CHECKS_WARNED+=("tier3_namespace: WARN (sin prefijo aislado)")
fi
```

### 6.3 No-Regresión Estructural

#### Reglas de Compatibilidad

| Situación | Requisito | Fallo si |
|-----------|-----------|----------|
| Modifica archivo TIER_3 | Checksum + declaración aditiva/disruptiva | Sin checksum en `calculate_sha256()` |
| Modifica archivo COMPLETADO | Solo aditivo o versionado | Sobrescribe sin versionado |
| Referencia archivo existente | Declarar en `related_files` | Falta declaración en frontmatter |
| Runtime requiere módulo | `depends_on` o fail gracefully | Silent dependency |

### 6.4 Idempotencia y Determinismo

| Requisito | Definición | Verificación en Script |
|-----------|------------|----------------------|
| **Idempotencia** | Ejecutar N veces = mismo estado final | `check_determinism()` - sin timestamps/random |
| **Determinismo** | Mismo input = mismo output | `check_determinism()` - seed fixed |
| **Sin side-effects** | No altera archivos externos | Validación manual pre/post |

---

## 7. ESCENARIOS DE USO

### 7.1 Escenario 1: Skill SDD Nueva

**Input**: Generar skill de `02-SKILLS/AI/gpt-integration.md`

```
ORQUESTADOR: Iniciando validación
    → Identificación: .md, 02-SKILLS/AI, documentation
    → Tier objetivo: 2

    CAPA 1: ✅ Pasada
    CAPA 2:
        → C1: ⚠️ Warns (resources referenced, not hardcoded)
        → C3: ✅ Passed (no secrets)
        → C4: ✅ Passed (tenant_id in frontmatter)
        → C5: ✅ Passed (validation_command declared)
        → C6: ✅ Passed (cloud endpoint declared)
        → C7: ⚠️ Warns (no explicit timeout)
        → C8: ✅ Passed (logging structure present)

    CAPA 3: Calculando tier...
        → Ejemplos: 12 ✅
        → Placeholders: 0 ✅
        → Validador: included ✅
        → Determinismo: ✅

    RESULTADO: TIER_2 CERTIFICADO ✅
    ACCIÓN: Merge automático tras CI gate
    SHA256: c8d3f5a9e2b1...
```

### 7.2 Escenario 2: Docker Compose con Healthchecks

**Input**: `05-CONFIGURATIONS/docker-compose/vps1-n8n-uazapi.yml`

```
ORQUESTADOR: Iniciando validación
    → Identificación: .yml, 05-CONFIGURATIONS/docker-compose, configuration
    → Tier objetivo: 3

    CAPA 1: ✅ Pasada
    CAPA 2:
        → C1: ✅ Passed (memory/cpu limits declared)
        → C3: ✅ Passed (env vars via ${VAR:?})
        → C4: ✅ Passed (tenant_id in labels)
        → C5: ✅ Passed (healthcheck command declared)
        → C6: ✅ Passed (no localhost references)
        → C7: ✅ Passed (restart_policy, depends_on)
        → C8: ✅ Passed (logging driver configured)

    CAPA 3: Calculando tier...
        → Idempotencia: ✅ (restart_policy: always)
        → Healthcheck: ✅ (healthcheck {} present)
        → Rollback: ✅ (version declared)
        → Namespace: ✅ (mantis-vps1 prefix)
        → Checksum: Calculando... a1b2c3d4...

    RESULTADO: TIER_3 CERTIFICADO ✅
    ACCIÓN: Pipeline directo → packager-assisted.sh → Deploy
    SHA256: a1b2c3d4e5f6...
```

### 7.3 Escenario 3: Falla C3 - Hardcoded Secret

**Input**: Archivo con `password = "admin123"`

```
ORQUESTADOR: Iniciando validación
    → Identificación: .tf, 05-CONFIGURATIONS/terraform, configuration
    → Tier objetivo: 3

    CAPA 1: ✅ Pasada
    CAPA 2:
        → C1: ✅ Passed
        → C2: ✅ Passed
        → C3: 🚨 FALLED
            → DETALLE: Hardcoded detected at line 42:
            → password = "admin123"
            → ESPERADO: password = var.db_password
            → FUENTE: audit-secrets.sh

    🚫 BLOQUEO CRÍTICO: C3_FAIL
    CÓDIGO: 2
    MENSAJE: Zero-hardcode violation detected

    ACCIÓN REQUERIDA:
    1. Reemplazar "admin123" con ${DB_PASSWORD:?missing}
    2. Declarar variable en variables.tf
    3. Re-ejecutar orquestador
```

---

## 8. REFERENCIAS CRUZADAS

### 8.1 Documentos Relacionados

| Documento | URL Raw | Rol |
|-----------|---------|-----|
| SDD-COLLABORATIVE-GENERATION.md | `.../SDD-COLLABORATIVE-GENERATION.md` | Contrato de generación IA |
| PROJECT_TREE.md | `.../PROJECT_TREE.md` | Navegación canónica |
| 01-RULES/00-INDEX.md | `.../01-RULES/00-INDEX.md` | Índice de normas C1-C8 |
| 01-RULES/06-MULTITENANCY-RULES.md | `.../01-RULES/06-MULTITENANCY-RULES.md` | Reglas C4 específicas |
| VALIDATOR_DOCUMENTATION.md | `.../05-CONFIGURATIONS/scripts/VALIDATOR_DOCUMENTATION.md` | Documentación de validadores |

### 8.2 URLs de Validadores (Referencia Rápida)

```bash
VALIDATOR_BASE="https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation"

audit-secrets.sh           → ${VALIDATOR_BASE}/audit-secrets.sh
check-rls.sh               → ${VALIDATOR_BASE}/check-rls.sh
check-wikilinks.sh         → ${VALIDATOR_BASE}/check-wikilinks.sh
schema-validator.py        → ${VALIDATOR_BASE}/schema-validator.py
validate-frontmatter.sh    → ${VALIDATOR_BASE}/validate-frontmatter.sh
validate-skill-integrity.sh → ${VALIDATOR_BASE}/validate-skill-integrity.sh
verify-constraints.sh      → ${VALIDATOR_BASE}/verify-constraints.sh
```

### 8.3 Versión y Auditoría

| Campo | Valor |
|-------|-------|
| Versión del Documento | 1.1.0 |
| Fecha de Creación | 2026-04-14 |
| Última Actualización | 2026-04-14 |
| Autor | MiniMax Agent + norms-matrix integration |
| Rol del Autor | Senior Auditor |
| Estado | ACTIVO |

---

## 9. ANEXOS

### Anexo A: Códigos de Error del Orquestador

| Código | Constante | Significado |
|--------|-----------|-------------|
| 0 | `SUCCESS` | Validación exitosa, artefacto certificado |
| 1 | `VALIDATION_FAILED` | Fallas detectadas, requiere corrección |
| 2 | `CRITICAL_BLOCK` | C3 o C4 violado, bloqueo crítico |
| 3 | `IDENTITY_MISSING` | No se pudo identificar el archivo |
| 4 | `VALIDATOR_ERROR` | Error interno de validador |
| 5 | `TIMEOUT` | Ejecución excedió tiempo límite |

### Anexo B: Variables de Entorno del Orquestador

| Variable | Descripción | Requerido |
|----------|-------------|-----------|
| `NORMS_MATRIX_PATH` | Ruta personalizada a norms-matrix.json | No |
| `VALIDATOR_BASE_PATH` | Directorio de validadores | Sí (auto-detectado) |
| `CI_MODE` | `true` si corre en CI | No |
| `NO_COLOR` | Desactivar colores ANSI | No |

### Anexo C: Schema JSON del Reporte

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "required": ["orchestrator_version", "timestamp", "file_path", "tier_certified"],
  "properties": {
    "orchestrator_version": {"type": "string", "pattern": "^\\d+\\.\\d+\\.\\d+$"},
    "timestamp": {"type": "string", "format": "date-time"},
    "file_path": {"type": "string"},
    "tier_certified": {"type": "integer", "enum": [1, 2, 3]},
    "tier_requested": {"type": "integer", "enum": [1, 2, 3]},
    "tier_match": {"type": "boolean"},
    "passed_checks": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["check", "status"],
        "properties": {
          "check": {"type": "string"},
          "status": {"type": "string", "enum": ["PASS", "FAIL", "WARN"]},
          "details": {"type": "string"}
        }
      }
    },
    "blocking_issues": {"type": "array"},
    "warnings": {"type": "array"},
    "validators_invoked": {"type": "array", "items": {"type": "string"}},
    "sha256": {"type": "string"},
    "next_step": {"type": "string"},
    "ci_gate_required": {"type": "boolean"},
    "human_approval_required": {"type": "boolean"}
  }
}
```

---

## ✅ VALIDATED EXAMPLES (≥10) — Para cumplimiento C5

1. ✅ **Deberías ver**: `orchestrator-engine.sh` carga `norms-matrix.json` tras `check_dependencies()`  
   ❌ **Si ves esto**: Error "Matriz no encontrada" sin fallback  
   🔧 **Solución**: Verificar que `05-CONFIGURATIONS/validation/norms-matrix.json` existe y es JSON válido  
   [[05-CONFIGURATIONS/validation/norms-matrix.json]]

2. ✅ **Deberías ver**: `query_norms_profile()` retorna perfil para `02-SKILLS/BASE DE DATOS-RAG/` + `.md` + `skill`  
   ❌ **Si ves esto**: Perfil nulo → fallback genérico aplicado  
   🔧 **Solución**: Agregar entrada en `matrix_by_location` para la ruta específica  
   [[05-CONFIGURATIONS/validation/norms-matrix.json#matrix_by_location]]

3. ✅ **Deberías ver**: `check_constraint_c4()` bloquea archivo DB sin `tenant_id` en queries  
   ❌ **Si ves esto**: Archivo pasa validación sin `WHERE tenant_id=?`  
   🔧 **Solución**: Ejecutar `check-rls.sh --strict` manualmente para diagnóstico  
   [[05-CONFIGURATIONS/validation/check-rls.sh]]

4. ✅ **Deberías ver**: `calculate_tier_score()` asigna TIER_3 a docker-compose con healthcheck + namespace + SHA256  
   ❌ **Si ves esto**: TIER_2 asignado a archivo con healthcheck pero sin SHA256  
   🔧 **Solución**: Ejecutar `calculate_sha256()` antes de tier calculation  
   [[05-CONFIGURATIONS/validation/orchestrator-engine.sh#L1150]]

5. ✅ **Deberías ver**: `generate_json_report()` emite schema válido según Anexo C  
   ❌ **Si ves esto**: JSON con campos faltantes o tipos incorrectos  
   🔧 **Solución**: Validar output con `schema-validator.py --schema skill-input-output.schema.json`  
   [[05-CONFIGURATIONS/validation/schemas/skill-input-output.schema.json]]

6. ✅ **Deberías ver**: `run_validator()` maneja fallback si validador no está en PATH  
   ❌ **Si ves esto**: Script falla con "command not found"  
   🔧 **Solución**: Agregar `command -v <tool> || log_warn "<tool> no encontrado"` en `check_dependencies()`  
   [[05-CONFIGURATIONS/validation/orchestrator-engine.sh#L200]]

7. ✅ **Deberías ver**: Frontmatter YAML puro en `.md`/`.yaml`/`.tf`, comentado en `.sh`  
   ❌ **Si ves esto**: `---` sin comentar en `.sh` → error de sintaxis bash  
   🔧 **Solución**: Usar `# ---` en scripts bash, YAML puro en configs  
   [[01-RULES/09-AGENTIC-OUTPUT-RULES.md]]

8. ✅ **Deberías ver**: `identify_file_location()` reconoce `02-SKILLS/BASE DE DATOS-RAG/` como `database-rag`  
   ❌ **Si ves esto**: Categoría `unknown` → validación genérica aplicada  
   🔧 **Solución**: Agregar caso en `case "$relative_dir"` de `identify_file_location()`  
   [[05-CONFIGURATIONS/validation/orchestrator-engine.sh#L350]]

9. ✅ **Deberías ver**: `check_determinism()` detecta `uuidgen`, `date`, `$RANDOM` como no-determinista  
   ❌ **Si ves esto**: Archivo con `uuidgen` pasa como determinista  
   🔧 **Solución**: Agregar patrón a `non_deterministic_patterns` array  
   [[05-CONFIGURATIONS/validation/orchestrator-engine.sh#L1050]]

10. ✅ **Deberías ver**: `determine_exit_action()` retorna código 2 para C3/C4 fail, 1 para otros fails  
    ❌ **Si ves esto**: Código 0 para archivo con hardcoded secret  
    🔧 **Solución**: Verificar que `BLOCKING_MESSAGE` contiene `C3_FAIL` o `C4_FAIL` antes de exit  
    [[05-CONFIGURATIONS/validation/orchestrator-engine.sh#L1400]]

---

## 🟢 VALIDATION COMMAND

```bash
# Validar este documento con el propio orquestador
./05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --mode headless \
  --file /GOVERNANCE-ORCHESTRATOR.md \
  --json | jq '.tier_certified, .passed_checks | length'

# Esperado: tier_certified=2, passed_checks >= 10

# Validar norms-matrix.json
jq empty 05-CONFIGURATIONS/validation/norms-matrix.json && echo "✅ norms-matrix.json: JSON válido"

# Validar orchestrator-engine.sh sintaxis
bash -n 05-CONFIGURATIONS/validation/orchestrator-engine.sh && echo "✅ orchestrator-engine.sh: sintaxis bash OK"
```

---

<!-- ai:file-end marker — do not remove -->
**Versión 1.1.0 — 2026-04-14 — Mantis-AgenticDev**  
**Autor**:Facundo - MiniMax Agent (Senior Auditor) + Qwen3.6 Plus Integración de norms-matrix.json  
**Estado**: ACTIVO — Listo para producción CI/CD  
**Constraints**: C1-C8 enforced via orchestrator-engine.sh + norms-matrix.json  
**Next Audit**: 2026-05-14
