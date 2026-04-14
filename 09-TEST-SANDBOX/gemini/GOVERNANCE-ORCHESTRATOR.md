### 1. Archivo: `GOVERNANCE-ORCHESTRATOR.md`
**Ubicación:** Raíz del repositorio (`/GOVERNANCE-ORCHESTRATOR.md`)
---
title: "Governance Orchestrator: Motor Centralizado de Certificación SDD"
type: "architecture-document"
status: "active"
version: "1.0.0"
description: "Documento oficial de arquitectura, matriz de reglas y flujos de decisión del Orquestador de Gobernanza de Mantis."
---

# 📄 ORQUESTADOR CENTRALIZADO DE GOBERNANZA SDD

## 🎯 1. CONTEXTO Y PROBLEMA ACTUAL
La base de infraestructura, validadores y normas (C1-C8) operaba de forma fragmentada. Cada validador funcionaba aislado sin un criterio unificado para decidir si un archivo generado por IA era apto para revisión humana, merge automático o despliegue autónomo. 

**Este Orquestador es un único punto de control que:**
1. Se ejecuta por terminal con guía humana paso a paso.
2. Funciona en modo headless para que las IA lo consuman como regla canónica infranqueable.
3. Clasifica, valida y certifica cada archivo según su ubicación, tipo y función.
4. Orquesta los validadores existentes (`audit-secrets.sh`, `check-rls.sh`, etc.) sin duplicar lógica.
5. Bloquea la integración si no se cumple el umbral de madurez definido.

---

## 🧠 2. ARQUITECTURA DEL MOTOR DE DECISIÓN POR CAPAS

El orquestador es un **sistema de certificación automatizada** con 4 capas lógicas:

### 🔹 CAPA 1: IDENTIDAD Y CONTEXTO
Resuelve la identidad del archivo (`.sh`, `.tf`, `.yaml`, `.md`, etc.), su rama en el árbol (`02-SKILLS/`, `05-CONFIGURATIONS/`, etc.) y su función.
*Si falta identidad clara o ruta canónica → **RECHAZO INMEDIATO**.*

### 🔹 CAPA 2: FILTRO NORMATIVO C1-C8
Aplica las reglas base de forma obligatoria:
- **C1/C2**: Límites de recursos.
- **C3**: Cero hardcode (`${VAR:?missing}`, `sensitive = true`).
- **C4**: `tenant_id` obligatorio para multi-tenancy.
- **C5**: Comandos de validación y ejemplos explícitos.
- **C6**: Inferencia cloud-only (prohibido `localhost`).
- **C7**: Resiliencia (timeouts, retries).
- **C8**: Observabilidad (JSON logs, `trace_id`).
*Fallo en C3 o C4 → **BLOQUEO CRÍTICO**.*

### 🔹 CAPA 3: CERTIFICACIÓN POR NIVELES
Evalúa la madurez funcional y asigna un tier automático:

| Nivel | Nombre | Umbral Mínimo | Acción Automática |
|-------|--------|---------------|-------------------|
| 🟢 **NIVEL 1** | SDD Asistida por IA | Sintaxis OK + C1-C8 base + ≥5 ejemplos + frontmatter | Requiere aprobación humana (PR). |
| 🟡 **NIVEL 2** | Autogeneración | Nivel 1 + 0 placeholders + validador + ≥10 ejemplos | Merge automático tras gate CI. |
| 🔴 **NIVEL 3** | Auto-Deploy Autónomo| Nivel 2 + idempotencia + healthcheck + namespace | Pipeline directo. Genera ZIP. |

### 🔹 CAPA 4: ENRUTAMIENTO Y ACCIÓN
Decide qué validadores externos invocar, qué gate de CI/CD aplicar y genera el `skill-validation-report.json`.

---

## 🗺️ 3. MATRIZ CANÓNICA DE APLICACIÓN DE NORMAS C1-C8

### 🔹 Regla Maestra de Precedencia
```text
SI (archivo en 05-CONFIGURATIONS/ O 04-WORKFLOWS/) → C1-C8 COMPLETOS (Tier 2-3)
SINO SI (archivo en 02-SKILLS/BASE DE DATOS-RAG/ O INFRAESTRUCTURA/) → C4 obligatorio + C1-C3/C7 según función
SINO SI (archivo es .md en 00-CONTEXT/ O 01-RULES/ O 07-PROCEDURES/) → C5/C8 + frontmatter válido (Tier 1)
SINO → Validación mínima (sintaxis + wikilinks)
```

### 📊 Tabla Detallada: Ruta × Extensión × Función × Normas

| Ruta Canónica | Extensión | C1 | C2 | C3 | C4 | C5 | C6 | C7 | C8 | Tier Objetivo | Validadores Activos |
|--------------|-----------|----|----|----|----|----|----|----|----|--------------|-------------------|
| `00-CONTEXT/` | `.md` | ⚪ | ⚪ | ⚪ | ⚪ | 🟢 | ⚪ | ⚪ | 🟡 | 1 | `check-wikilinks`, `validate-frontmatter` |
| `01-RULES/` | `.md` | ⚪ | ⚪ | 🟢 | 🟢 | 🟢 | 🟢 | ⚪ | ⚪ | 2 | `verify-constraints`, `audit-secrets` |
| `02-SKILLS/INFRAESTRUCTURA/` | `.md` | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 | 🟢 | 2 | `verify-constraints`, `audit-secrets` |
| `02-SKILLS/BASE DE DATOS-RAG/` | `.md` (+ SQL) | 🟡 | 🟡 | 🟢 | 🔴 | 🟢 | ⚪ | ⚪ | 🟢 | 2 | `check-rls`, `schema-validator` |
| `03-AGENTS/` | `.md` | 🟢 | 🟢 | 🟢 | 🔴 | 🟢 | 🟢 | 🟢 | 🟢 | 2 | `audit-secrets`, `verify-constraints` |
| `04-WORKFLOWS/` | `.json` | 🟢 | 🟢 | 🟢 | 🔴 | 🟢 | 🟢 | 🟢 | 🟢 | 3 | `schema-validator`, `packager-assisted` |
| `05-CONFIGURATIONS/docker-compose/`| `.yml` | 🔴 | 🔴 | 🔴 | 🔴 | 🟢 | ⚪ | 🔴 | 🔴 | 3 | `docker config`, `audit-secrets` |
| `05-CONFIGURATIONS/terraform/*/` | `.tf` | 🔴 | 🔴 | 🔴 | 🔴 | 🔴 | 🟢 | 🟢 | 🟢 | 3 | `terraform fmt/validate`, `audit-secrets` |
| `05-CONFIGURATIONS/scripts/` | `.sh` | 🟢 | 🟢 | 🔴 | 🔴 | 🟢 | ⚪ | 🔴 | 🔴 | 2→3 | `shellcheck`, `audit-secrets` |

*(Leyenda: 🔴 Obligatorio estricto | 🟢 Aplicable con validación | 🟡 Contextual | ⚪ No aplicable)*

---

## 🎯 4. REGLAS DE DECISIÓN POR EXTENSIÓN

- **`.md`**: C4 es obligatorio si la ruta contiene `BASE DE DATOS-RAG` o `INFRAESTRUCTURA`. Ejemplos ≥10 para Tier 2+.
- **`.yml` / `.yaml`**: C1/C2 obligatorios (mem_limit, etc.). C3 sin hardcode. Validado por `yq` y Docker.
- **`.tf`**: Bloques de validación requeridos. `sensitive = true` obligatorio. `tenant_id` obligatorio.
- **`.sh`**: Shebang estricto (`set -euo pipefail`). Frontmatter comentado. C3 estricto (`${VAR:?missing}`).
- **`.json`**: Schema strictness (`jq`). `tenant_id` en payloads. Cero secretos en texto plano.

---

## 🛡️ 5. BLINDAJE Y NO-REGRESIÓN
- **Multi-tenant Estricto:** Bloqueo automático de queries sin `tenant_id` o `shared_db` sin RLS.
- **Idempotencia:** Mismo input → mismo output. Cero alteración de estado no intencionada.
- **Aislamiento:** Exige prefijos únicos (`mantis-`, `tenant_`).

## 📋 6. CHECKLIST PARA IA (Incluir en Prompts)
```text
Antes de generar:
1. Resuelve la ruta canónica en PROJECT_TREE.md.
2. Aplica matriz C1-C8 por tipo y ubicación.
3. Determina tier objetivo (1, 2, 3) y cantidad de ejemplos (5 o 10).
4. Asegura cero hardcode y la inyección del tenant_id si aplica.
5. Emite comandos de validación ejecutables.
Si falta contexto, emite: "⚠️ BLOQUEADO: falta [X]. Esperando contexto."
```

---
