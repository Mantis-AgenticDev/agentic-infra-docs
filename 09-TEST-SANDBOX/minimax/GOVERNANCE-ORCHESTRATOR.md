# ORQUESTADOR CENTRALIZADO DE GOBERNANZA SDD
**Sistema de Certificación Automatizada para Generación Agéntica**

| Metadato | Valor |
|----------|-------|
| `canonical_path` | `/GOVERNANCE-ORCHESTRATOR.md` |
| `ai_optimized` | `true` |
| `constraints_mapped` | `C1-C8` |
| `validation_command` | `./05-CONFIGURATIONS/validation/orchestrator-engine.sh --file <path> --mode <interactive\|headless>` |
| `tier_target` | `3` |
| `last_audit` | `2026-04-14` |
| `audit_authority` | |MiniMax Agent Senior Auditor|

---

## 1. RESUMEN EJECUTIVO

Este documento define el **Orquestador Centralizado de Gobernanza SDD** como el sistema nervioso central que traduce las normas C1-C8, los requisitos multi-tenant, las políticas de no-regresión y los estándares de hardening en decisiones binarias, certificadas y ejecutables.

El orquestador cierra la brecha entre "generación asistida" y "autogeneración autónoma", proporcionando control total sobre la madurez de cada artefacto antes de que toque producción.

### 1.1 Problema que Resuelve

| Problema Actual | Impacto | Solución del Orquestador |
|-----------------|---------|--------------------------|
| Validadores funcionando de forma fragmentada | Falsos positivos/negativos | Punto único de coordinación |
| Sin criterio unificado para aptitud de archivos | Merge automático de archivos inválidos | Clasificación por tiers certificada |
| Validaciones genéricas en carpetas con propósitos distintos | Errores por contexto equivocado | Enrutamiento inteligente por tipo/ubicación |
| Multi-tenancy sin enforcement automático | Fugas de datos LGPD | Verificación obligatoria C4 |
| Falta de "contrato vivo" entre normas y decisiones | Dependencia de memoria del desarrollador | Traducción normativa → binaria |

### 1.2 Objetivos de Control

- **OC-01**: Toda generación de IA debe pasar por el orquestador antes de merge
- **OC-02**: Cada artefacto recibe clasificación de tier (1, 2, 3) basada en madurez funcional
- **OC-03**: Los tiers 2 y 3 son idempotentes y deterministas
- **OC-04**: Los validadores externos se invocan según matriz de mapeo, nunca arbitrariamente
- **OC-05**: El orquestador genera evidencia auditable en formato JSON para CI/CD

---

## 2. ARQUITECTURA DEL MOTOR DE DECISIÓN POR CAPAS

### 2.1 Vista General de Capas

```
┌─────────────────────────────────────────────────────────────────┐
│                    CAPA 4: ENRUTAMIENTO Y ACCIÓN                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │ CI/CD GATE   │  │ REPORTE JSON │  │ BLOQUEO      │           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
├─────────────────────────────────────────────────────────────────┤
│                    CAPA 3: CERTIFICACIÓN POR NIVELES            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │ TIER 1       │  │ TIER 2       │  │ TIER 3       │           │
│  │ SDD Asistida ogeneración│  │ │  │ Aut Auto-Deploy  │         │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
├─────────────────────────────────────────────────────────────────┤
│                    CAPA 2: FILTRO NORMATIVO C1-C8               │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐         │
│  │   C1   │ │   C2   │ │   C3   │ │   C4   │ │   C5   │ ...     │
│  │Resource│ │Limits  │ │Zero-HC │ │TenantID│ │Val.Cmds│         │
│  └────────┘ └────────┘ └────────┘ └────────┘ └────────┘         │
├─────────────────────────────────────────────────────────────────┤
│                    CAPA 1: IDENTIDAD Y CONTEXTO                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │ Tipo archivo │  │ Ubicación    │  │ Función      │           │
│  │ (.sh/.tf...) │  │ (/02-SKILLS) │  │ (pattern/sdd)│           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Capa 1: Identidad y Contexto

**Propósito**: Antes de validar, el motor responde a preguntas fundamentales sobre el artefacto.

| Pregunta | Valores Posibles | Acción si Falla |
|----------|------------------|-----------------|
| ¿Qué tipo de archivo es? | `.sh`, `.tf`, `.yaml`, `.md`, `.json`, `.yml`, `.py` | RECHAZO INMEDIATO |
| ¿En qué rama vive? | `00-CONTEXT/`, `01-RULES/`, `02-SKILLS/`, `03-AGENTS/`, `04-WORKFLOWS/`, `05-CONFIGURATIONS/` | RECHAZO INMEDIATO |
| ¿Qué función cumple? | `documentation`, `pattern`, `configuration`, `agent-definition`, `pipeline` | ADVERTENCIA |
| ¿Tiene metadatos canónicos? | `canonical_path`, `ai_optimized`, `constraints_mapped` presentes | RECHAZO INMEDIATO |

**Regla de Oro C1.1**: Si falta identidad clara → **RECHAZO INMEDIATO**. No avanza a capas inferiores.

**Flujo de Identificación**:

```yaml
identificacion:
  paso_1: Extraer extensión del archivo
  paso_2: Identificar directorio padre
  paso_3: Clasificar función según PROJECT_TREE.md
  paso_4: Verificar presencia de frontmatter canónico
  paso_5: Si algún paso falla → TERMINAR con código 1
```

### 2.3 Capa 2: Filtro Normativo C1-C8

**Propósito**: Aplicar las reglas base de forma obligatoria, sin excepciones.

#### Matriz de Criticidad Normativa

| Norma | Descripción | Criticidad | Acción si Falla |
|-------|-------------|------------|-----------------|
| **C1** | Límites de recursos declarados | ALTA | ADVERTENCIA BLOQUEANTE |
| **C2** | Límites de recursos referenciados | MEDIA | ADVERTENCIA NO BLOQUEANTE |
| **C3** | Zero Hardcode (${VAR:?}, sensitive=true) | **CRÍTICA** | **BLOQUEO CRÍTICO** |
| **C4** | tenant_id presente/forzado | **CRÍTICA** | **BLOQUEO CRÍTICO** |
| **C5** | Comando de validación declarado | ALTA | ADVERTENCIA BLOQUEANTE |
| **C6** | Cloud-only inference (no localhost:11434) | ALTA | ADVERTENCIA BLOQUEANTE |
| **C7** | Resiliencia declarada (timeouts, retries) | MEDIA | ADVERTENCIA NO BLOQUEANTE |
| **C8** | Observabilidad (JSON logs, trace_id) | MEDIA | ADVERTENCIA NO BLOQUEANTE |

#### Lógica de Decisión C3/C4

```
SI C3_FALLA(archivo) ENTONCES
    → GENERAR_BLOQUEO_CRITICO("Hardcoded detected: " + ubicacion)
    → DETENER_EJECUCION
FIN_SI

SI C4_FALLA(archivo) ENTONCES
    → GENERAR_BLOQUEO_CRITICO("tenant_id missing: " + ubicacion)
    → DETENER_EJECUCION
FIN_SI
```

### 2.4 Capa 3: Certificación por Niveles

**Propósito**: Evaluar madurez funcional y asignar un tier automático.

#### Definición de Tiers

| Tier | Nombre | Color | Umbral Mínimo | Acción Automática | Uso Típico |
|------|--------|-------|---------------|-------------------|------------|
| 🟢 **1** | SDD Asistida por IA | Verde | Sintaxis OK + C1-C8 base + ≥5 ejemplos + frontmatter válido | Requiere aprobación humana. Se muestra en pantalla/PR. | Skills en progreso, docs técnicos, schemas referenciales, `README` de carpetas. |
| 🟡 **2** | Autogeneración + Entrega Pantalla | Amarillo | Nivel 1 + 0 placeholders + validador ejecutable + ≥10 ejemplos + determinismo | Merge automático tras gate CI. Salida directa de IA. | Scripts bash, configs Docker/Terraform, assertions `promptfoo`, definiciones de agentes, queries SQL con `tenant_id` forzado. |
| 🔴 **3** | Auto-Deploy + ZIP Autónomo | Rojo | Nivel 2 + idempotencia + healthcheck/rollback + CI/CD trigger + SHA256 + namespace aislado | Pipeline directo. Genera ZIP firmado. Deploy sin intervención. | `docker-compose` con healthchecks, workflows n8n con nodos de error, módulos Terraform con RLS, `packager-assisted.sh` outputs. |

#### Algoritmo de Asignación de Tier

```
FUNCION asignar_tier(archivo) → tier
    puntaje = 0

    # Factores que aumentan puntaje
    SI tiene_sintaxis_valida(archivo) → puntaje += 10
    SI pasa_C1_C8(archivo) → puntaje += 20
    SI tiene_ejemplos(archivo) >= 10 → puntaje += 15
    SI tiene_frontmatter_valido(archivo) → puntaje += 10
    SI tiene_validador_ejecutable(archivo) → puntaje += 15
    SI es_determinista(archivo) → puntaje += 15
    SI tiene_healthcheck(archivo) → puntaje += 10
    SI tiene_idempotencia(archivo) → puntaje += 10
    SI tiene_sha256(archivo) → puntaje += 10
    SI tiene_namespace_aislado(archivo) → puntaje += 10

    # Factores que disminuyen puntaje
    SI tiene_placeholders(archivo) → puntaje -= 25
    SI tiene_hardcoded(archivo) → puntaje -= 50
    SI falta_tenant_id(archivo) → puntaje -= 50

    # Asignación basada en puntaje
    SI puntaje >= 80 → RETORNAR "TIER_3"
    SI puntaje >= 50 → RETORNAR "TIER_2"
    SI puntaje >= 20 → RETORNAR "TIER_1"
    RETORNAR "RECHAZADO"
FIN_FUNCION
```

### 2.5 Capa 4: Enrutamiento y Acción

**Propósito**: Según el tier asignado y la ubicación, decidir qué validadores invocar y qué acciones tomar.

#### Matriz de Acciones por Tier

| Tier | Invocar Validadores | Gate CI/CD | Generar Reporte | Acción de Merge |
|------|---------------------|------------|------------------|-----------------|
| 1 | Basicos (sintaxis, frontmatter) | NO | JSON + humano | Requiere aprobación manual |
| 2 | Todos los aplicables | SI | JSON estructurado | Merge automático tras pass |
| 3 | Todos + packager | SI + firma | JSON + SHA256 + manifest | Deploy directo con rollback |

---

## 3. MATRIZ DE MAPEO: UBICACIÓN × FUNCIÓN × NORMATIVA

### 3.1 Matriz Principal

| Directorio | Función | Archivos Predominantes | Validadores Activados | Normas Críticas | Tier Objetivo |
|------------|---------|------------------------|----------------------|-----------------|---------------|
| `00-CONTEXT/` | Docs base, overview | `.md` | `check-wikilinks.sh`, `validate-frontmatter.sh` | Coherencia con `PROJECT_TREE.md`, frontmatter puro | 1 |
| `01-RULES/` | Normas canónicas | `.md`, `.sh` | `verify-constraints.sh`, `audit-secrets.sh` | C1-C8 explícitos, sin placeholders, trazabilidad | 2 |
| `02-SKILLS/` | Patrones, schemas, queries | `.md`, `.json` | `check-rls.sh` (si DB), `schema-validator.py` | C4 forzado, `tenant_id` en queries/índices, ≥10 ejemplos | 1 → 2 |
| `02-SKILLS/BASE DE DATOS-RAG/` | Queries, configs DB | `.md`, `.sql` | `check-rls.sh` | C4 obligatorio, RLS policies verificadas | 2 |
| `03-AGENTS/` | Definiciones de agentes | `.md`, `.json` | `audit-secrets.sh`, `check-wikilinks.sh` | C4/C7/C8, tenant awareness, error handling | 2 |
| `04-WORKFLOWS/` | JSON n8n, pipelines | `.json` | `schema-validator.py`, `packager-assisted.sh` | C3/C5/C7, nodos de rollback, CI/CD compatible | 2 → 3 |
| `05-CONFIGURATIONS/` | Infra, deploy, scripts | `.sh`, `.tf`, `.yaml`, `.yml` | `validate-frontmatter.sh`, `audit-secrets.sh`, linters | C1-C8 completos, secrets management, healthchecks, idempotencia | 2 → 3 |
| `05-CONFIGURATIONS/validation/` | Scripts de validación | `.sh`, `.py` | Todos menos self | C3/C5/C7, logging estructurado | 3 |
| `06-PROGRAMMING/` | Patrones de código | `.js`, `.py`, `.sql` | Linters según tipo | Sintaxis estricta, `tenant_id` en queries, zero-hardcode | 1 → 2 |
| `07-PROCEDURES/` | Runbooks, checklists | `.md` | `check-wikilinks.sh` | Pasos claros, checks pre/post, referencias cruzadas | 1 |
| `08-LOGS/` | Auditoría, reports | `.json`, `.log` | `schema-validator.py` | Formato JSON, rotación, `tenant_id`/`trace_id` | 3 (si auto-gen) |

### 3.2 Matriz de Validadores por Tipo de Archivo

| Extensión | shebang/Header | Validadores Específicos | Check Adicional | Frontmatter |
|-----------|----------------|-------------------------|-----------------|-------------|
| `.sh` | `#!/bin/bash -euo pipefail` | `bash -n`, `shellcheck` | JSON via heredoc | `# ---` comentado |
| `.tf` | N/A (Terraform) | `terraform fmt`, `terraform validate` | Bloques `validation {}`, `sensitive = true` | YAML |
| `.yaml` / `.yml` | N/A | `yamllint` | Estructura asserts, sin tabs | YAML puro |
| `.md` | N/A | `check-wikilinks.sh`, `validate-frontmatter.sh` | ≥5 ejemplos ✅/❌/🔧, fences | YAML |
| `.json` | N/A | `jq empty`, `schema-validator.py` | Sin trailing commas, schema strict | N/A |
| `.py` | `#!/usr/bin/env python3` | `python3 -m py_compile` | Importaciones válidas | `# ---` comentado |

---

## 4. INTEGRACIÓN CON VALIDADORES EXISTENTES

### 4.1 Catálogo de Validadores

El orquestador **no reemplaza**. **Coordina**. Cada validador mantiene su responsabilidad específica.

#### 4.1.1 audit-secrets.sh

| Atributo | Valor |
|----------|-------|
| **URL Raw** | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/audit-secrets.sh` |
| **Propósito** | Detector C3 - Identificar hardcoded secrets |
| **Norma Asociada** | C3 (Zero Hardcode) |
| **Cuándo se Invoca** | Siempre que haya archivos con credenciales/env vars |
| **Patrón de Llamada** | `./audit-secrets.sh --path <archivo>` |
| **Códigos de Retorno** | 0 = limpio, 1 = secretos detectados |
| **Dependencias** | `grep`, `sed` |

#### 4.1.2 check-rls.sh

| Atributo | Valor |
|----------|-------|
| **URL Raw** | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/check-rls.sh` |
| **Propósito** | Verificador C4 - Verificar RLS policies en PostgreSQL |
| **Norma Asociada** | C4 (Multi-tenancy) |
| **Cuándo se Invoca** | Solo en `02-SKILLS/BASE DE DATOS-RAG/` o configs SQL/PostgreSQL |
| **Patrón de Llamada** | `./check-rls.sh --config <archivo_sql>` |
| **Códigos de Retorno** | 0 = RLS OK, 1 = RLS faltante o incorrecto |
| **Dependencias** | `psql`, `grep`, archivo SQL |

#### 4.1.3 check-wikilinks.sh

| Atributo | Valor |
|----------|-------|
| **URL Raw** | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/check-wikilinks.sh` |
| **Propósito** | Validador de referencias canónicas en markdown |
| **Norma Asociada** | Coherencia estructural |
| **Cuándo se Invoca** | En `.md` y docs técnicos |
| **Patrón de Llamada** | `./check-wikilinks.sh --file <markdown>` |
| **Códigos de Retorno** | 0 = links OK, 1 = links rotos o no-canónicos |
| **Dependencias** | `grep`, `find` |

#### 4.1.4 schema-validator.py

| Atributo | Valor |
|----------|-------|
| **URL Raw** | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/schema-validator.py` |
| **Propósito** | Validador JSON Schema |
| **Norma Asociada** | Estructura canónica |
| **Cuándo se Invoca** | En `.json` y payloads de IA |
| **Patrón de Llamada** | `python3 schema-validator.py --schema <schema.json> --data <archivo.json>` |
| **Códigos de Retorno** | 0 = válido, 1 = inválido |
| **Dependencias** | Python 3, `jsonschema` |

#### 4.1.5 validate-frontmatter.sh

| Atributo | Valor |
|----------|-------|
| **URL Raw** | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/validate-frontmatter.sh` |
| **Propósito** | Verificador de metadatos canónicos |
| **Norma Asociada** | Frontmatter requerido |
| **Cuándo se Invoca** | En `.md`, `.yaml`, `.json`, `.tf` |
| **Patrón de Llamada** | `./validate-frontmatter.sh --file <archivo>` |
| **Códigos de Retorno** | 0 = frontmatter OK, 1 = frontmatter inválido o ausente |
| **Dependencias** | `grep`, `sed`, `yq` (opcional) |

#### 4.1.6 validate-skill-integrity.sh

| Atributo | Valor |
|----------|-------|
| **URL Raw** | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/validate-skill-integrity.sh` |
| **Propósito** | Verificador de integridad de skills |
| **Norma Asociada** | Todas (validación integral) |
| **Cuándo se Invoca** | En todo archivo bajo `02-SKILLS/` |
| **Patrón de Llamada** | `./validate-skill-integrity.sh --skill <path>` |
| **Códigos de Retorno** | 0 = integridad OK, 1 = falla en validación |
| **Dependencias** | Todos los otros validadores |

#### 4.1.7 verify-constraints.sh

| Atributo | Valor |
|----------|-------|
| **URL Raw** | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/verify-constraints.sh` |
| **Propósito** | Check C1-C6 textual |
| **Norma Asociada** | C1, C2, C3, C4, C5, C6 |
| **Cuándo se Invoca** | En todos los archivos ejecutables/config |
| **Patrón de Llamada** | `./verify-constraints.sh --file <archivo>` |
| **Códigos de Retorno** | 0 = constraints OK, 1 = constraint violado |
| **Dependencias** | `grep`, `sed` |

#### 4.1.8 packager-assisted.sh

| Atributo | Valor |
|----------|-------|
| **URL Raw** | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/scripts/packager-assisted.sh` |
| **Propósito** | Generador de ZIP con checksums |
| **Norma Asociada** | Tier 3 |
| **Cuándo se Invoca** | Solo en Tier 3, post-certificación |
| **Patrón de Llamada** | `./packager-assisted.sh --source <directorio> --output <zip>` |
| **Códigos de Retorno** | 0 = paquete generado OK, 1 = error |
| **Dependencias** | `zip`, `sha256sum` |

#### 4.1.9 validate-against-specs.sh

| Atributo | Valor |
|----------|-------|
| **URL Raw** | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/scripts/validate-against-specs.sh` |
| **Propósito** | Validador contra especificaciones |
| **Norma Asociada** | Todas |
| **Cuándo se Invoca** | Pre-merge, pre-deploy |
| **Patrón de Llamada** | `./validate-against-specs.sh --target <archivo>` |
| **Códigos de Retorno** | 0 = match OK, 1 = specs no cumplidas |
| **Dependencias** | `grep`, `diff`, validadores específicos |

### 4.2 Flujo de Orquestación

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
│              │ Código 1, mensaje: "ID_FAIL"  │                  │
│              └───────────────────────────────┘                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ CAPA 2: NORMATIVA C1-C8                                         │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ invoke verify-constraints.sh --file <archivo>           │    │
│  │ invoke audit-secrets.sh --path <archivo>                │    │
│  │ invoke validate-frontmatter.sh --file <archivo>         │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                  │
│              ┌───────────────┴───────────────┐                  │
│              │ C3 o C4 FALLA → BLOQUEO       │                  │
│              │ Código 1, mensaje: "C3_FAIL"  │                  │
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
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. DOBLE INTERFAZ: HUMANO VS IA

### 5.1 Modo Terminal Interactivo (Humano)

**Activación**: `./orchestrator-engine.sh --mode interactive`

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
  VALIDADORES A EJECUTAR
========================================
   [✓] validate-frontmatter.sh
   [✓] audit-secrets.sh
   [✓] verify-constraints.sh
   [ ] check-rls.sh (solo si DB)
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

**Activación**: `./orchestrator-engine.sh --mode headless --file <path> --json`

#### Payload de Entrada (JSON)

```json
{
  "file_path": "02-SKILLS/INFRASTRUCTURA/docker-compose-networking.md",
  "file_type": ".md",
  "target_folder": "02-SKILLS/INFRASTRUCTURA",
  "function": "documentation",
  "constraints_declared": ["C1", "C2", "C3", "C4", "C5"],
  "expected_tier": 2
}
```

#### Payload de Salida (JSON)

```json
{
  "orchestrator_version": "1.0.0",
  "timestamp": "2026-04-14T11:49:33Z",
  "file_path": "02-SKILLS/INFRASTRUCTURA/docker-compose-networking.md",
  "tier_certified": 2,
  "tier_requested": 2,
  "tier_match": true,
  "passed_checks": [
    {"check": "identity_type", "status": "PASS", "details": ".md recognized"},
    {"check": "identity_location", "status": "PASS", "details": "02-SKILLS/INFRASTRUCTURA valid"},
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

---

## 6. BLINDAJE MULTI-TENANT Y NO-REGRESIÓN

### 6.1 Verificación Multi-Tenant

Cuando el archivo toca esquemas DB o configs de EspoCRM/MySQL:

#### Reglas Obligatorias

| Componente | Verificación | Fallo si |
|------------|-------------|----------|
| Tablas | Prefijo `tenant_id` como segundo campo | `CREATE TABLE` sin `tenant_id` |
| Queries | `WHERE tenant_id = $1` o equivalente | `SELECT *` sin filtro |
| Índices | Compuestos iniciando con `tenant_id` | Índice sin `tenant_id` |
| Policies | RLS policy activa por tabla | Sin `CREATE POLICY` |
| Volumes | Label `tenant_id` presente | Sin label en volúmenes |
| Logs | `tenant_id` en cada entrada | Logs sin aislamiento |

#### Check Automático check-rls.sh

```
SI archivo ∈ {*.sql, *-rls.tf, espocrm-*.yml} ENTONCES
    SI check-rls.sh retorna 1 ENTONCES
        → GENERAR_BLOQUEO_CRITICO("RLS_FAIL: Multi-tenant violation")
        → DETENER_EJECUCION
    FIN_SI
FIN_SI
```

### 6.2 Aislamiento de Namespace

#### Prefijos Obligatorios

| Recurso | Prefijo Requerido | Ejemplo |
|---------|-------------------|---------|
| Contenedores | `mantis-vpsX-` | `mantis-vps1-n8n`, `mantis-vps2-uazapi` |
| Volúmenes | `tenant_` | `tenant_facundo_data` |
| Redes | `kb_` | `kb_internal_net` |
| Bases de datos | `mantis_` | `mantis_espocrm_prod` |
| Tablas | `mbt_` | `mbt_contacts`, `mbt_opportunities` |

#### Verificación de Colisión

```
SI archivo ∈ {docker-compose.yml, terraform/*.tf} ENTONCES
    PARA CADA nombre_recurso EN archivo
        SI nombre_recurso ∉ prefijos_permitidos ENTONCES
            → GENERAR_BLOQUEO("NAMESPACE_FAIL: " + nombre_recurso)
        FIN_SI
        SI artifact_existe(nombre_recurso) AND artifact.estado == "COMPLETADO" ENTONCES
            → GENERAR_BLOQUEO("COLLISION_FAIL: " + nombre_recurso + " exists")
        FIN_SI
    FIN_PARA
FIN_SI
```

### 6.3 No-Regresión Estructural

#### Reglas de Compatibilidad

| Situación | Requisito | Fallo si |
|-----------|-----------|----------|
| Modifica archivo TIER_3 | Checksum + declaración aditiva/disruptiva | Sin checksum |
| Modifica archivo COMPLETADO | Solo aditivo o versionado | Sobrescribe |
| Referencia archivo existente | Declarar en `related_files` | Falta declaración |
| Runtime requiere módulo | `depends_on` o fail gracefully | Silent dependency |

#### Check de Integridad

```
SI archivo.modifica(artefacto_existente) ENTONCES
    SI artefacto_existente.tier == 3 ENTONCES
        SI NO tiene_checksum(archivo) ENTONCES
            → GENERAR_BLOQUEO("NO_REGRESSION: Tier-3 artifact without checksum")
        FIN_SI
    FIN_SI

    SI artefacto_existente.estado == "COMPLETADO" ENTONCES
        SI NO es_aditivo(archivo) Y NO es_versionado(archivo) ENTONCES
            → GENERAR_BLOQUEO("NO_REGRESSION: Modifies COMPLETADO artifact")
        FIN_SI
    FIN_SI
FIN_SI
```

### 6.4 Idempotencia y Determinismo

| Requisito | Definición | Verificación |
|-----------|------------|---------------|
| **Idempotencia** | Ejecutar N veces = mismo estado final | Run twice, compare output |
| **Determinismo** | Mismo input = mismo output | Seed fixed, no timestamps |
| **Sin side-effects** | No altera archivos externos | File diff pre/post |

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

```
VALIDATOR_BASE="https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation"

audit-secrets.sh           → ${VALIDATOR_BASE}/audit-secrets.sh
check-rls.sh               → ${VALIDATOR_BASE}/check-rls.sh
check-wikilinks.sh         → ${VALIDATOR_BASE}/check-wikilinks.sh
schema-validator.py         → ${VALIDATOR_BASE}/schema-validator.py
validate-frontmatter.sh    → ${VALIDATOR_BASE}/validate-frontmatter.sh
validate-skill-integrity.sh → ${VALIDATOR_BASE}/validate-skill-integrity.sh
verify-constraints.sh      → ${VALIDATOR_BASE}/verify-constraints.sh
```

### 8.3 Versión y Auditoría

| Campo | Valor |
|-------|-------|
| Versión del Documento | 1.0.0 |
| Fecha de Creación | 2026-04-14 |
| Última Actualización | 2026-04-14 |
| Autor | MiniMax Agent |
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
| `ORCHESTRATOR_MODE` | `interactive` o `headless` | Sí |
| `ORCHESTRATOR_STRICT` | `true` para bloq. warnings | No |
| `ORCHESTRATOR_REPORT` | Path para reporte JSON | No |
| `VALIDATOR_BASE_PATH` | Directorio de validadores | Sí |
| `CI_MODE` | `true` si corre en CI | No |

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

**FIN DEL DOCUMENTO**
