---

## Archivo 1: `/GOVERNANCE-ORCHESTRATOR.md`


# 🧠 GOVERNANCE ORCHESTRATOR – Sistema Central de Certificación SDD

**Versión:** 1.0.0  
**Ubicación:** Raíz del repositorio  
**Motor asociado:** `05-CONFIGURATIONS/validation/orchestrator-engine.sh`

---

## 📌 1. VISIÓN GENERAL

El **Governance Orchestrator** es el punto único de control que certifica la madurez y el cumplimiento normativo de cualquier artefacto generado (por humanos o IA) dentro del ecosistema SDD. No reemplaza los validadores existentes, sino que los **orquesta**, **enruta** y **consolida** para emitir un veredicto de **Nivel (Tier)** que determina si el archivo puede:

- Pasar a revisión humana (Nivel 1)
- Ser mergeado automáticamente (Nivel 2)
- Ser empaquetado y desplegado sin intervención (Nivel 3)

El sistema opera bajo un **contrato canónico infranqueable** (reglas C1‑C8, multi‑tenancy, no‑regresión, determinismo) y proporciona dos interfaces:

- **Modo interactivo (humano):** Guía paso a paso, preguntas y reporte legible.
- **Modo headless (IA/CI/CD):** Entrada JSON, salida JSON estructurada, sin interacción.

---

## 🧱 2. ARQUITECTURA LÓGICA (4 CAPAS)

### 🔹 Capa 1 – IDENTIDAD Y CONTEXTO
Antes de cualquier validación, el orquestador establece:

- **Tipo de archivo** (extensión real, shebang, contenido).
- **Directorio de destino** (rama del árbol canónico: `02-SKILLS/`, `04-WORKFLOWS/`, etc.).
- **Función declarada** (documentación, patrón, configuración ejecutable, pipeline, etc.).
- **Presencia de metadatos canónicos** (`canonical_path`, `ai_optimized: true`, `constraints_mapped`).

Si no puede determinarse una identidad clara → **RECHAZO INMEDIATO**.

### 🔹 Capa 2 – FILTRO NORMATIVO C1‑C8
Se aplican reglas base obligatorias:

| Regla | Descripción | Consecuencia de fallo |
|-------|-------------|------------------------|
| **C1/C2** | Límites de recursos declarados | Advertencia (puede ser bloqueante según nivel objetivo) |
| **C3** | Cero hardcode de secretos | **BLOQUEO CRÍTICO** |
| **C4** | `tenant_id` presente en queries/policies/labels | **BLOQUEO CRÍTICO** |
| **C5** | Comando de validación declarado + ejemplos | Advertencia bloqueante para Nivel 2+ |
| **C6** | Inferencia cloud‑only (prohibido `localhost` para producción) | Advertencia bloqueante |
| **C7** | Resiliencia declarada (timeouts, retries, healthchecks) | Advertencia bloqueante para Nivel 3 |
| **C8** | Observabilidad estructurada (logs JSON, trace_id) | Advertencia bloqueante para Nivel 3 |

### 🔹 Capa 3 – CERTIFICACIÓN POR NIVELES (TIER)
El orquestador asigna automáticamente uno de tres niveles según la madurez funcional:

| Nivel | Nombre | Umbral mínimo | Acción automática |
|-------|--------|---------------|-------------------|
| 🟢 **NIVEL 1** | SDD Asistida | Sintaxis OK + C1‑C8 base + ≥5 ejemplos + frontmatter válido | Requiere aprobación humana |
| 🟡 **NIVEL 2** | Autogeneración + Entrega | Nivel 1 + 0 placeholders + validador ejecutable + determinismo | Merge automático tras CI gate |
| 🔴 **NIVEL 3** | Auto‑Deploy + ZIP | Nivel 2 + idempotencia + healthcheck/rollback + CI/CD trigger | Pipeline directo, genera ZIP firmado |

### 🔹 Capa 4 – ENRUTAMIENTO Y ACCIÓN
Con base en el **tipo de archivo** y **directorio**, el orquestador decide:

- Qué validadores externos invocar.
- Qué gate de CI/CD aplicar.
- Si debe actualizar `skill-validation-report.json`.
- Si debe generar un ZIP firmado (solo Nivel 3).

---

## 🗺️ 3. MATRIZ DE MAPEO UBICACIÓN × NORMATIVA

| Directorio / Función | Validadores Activados | Normas Críticas | Tier Objetivo |
|----------------------|------------------------|-----------------|---------------|
| `00-CONTEXT/` | `validate-frontmatter.sh`, `check-wikilinks.sh` | Coherencia con `PROJECT_TREE.md` | 1 |
| `01-RULES/` | `verify-constraints.sh`, `audit-secrets.sh` | C1‑C8 explícitos, trazabilidad | 2 |
| `02-SKILLS/` | `check-rls.sh` (si DB), `schema-validator.py` | C4 forzado, `tenant_id` en queries | 1 → 2 |
| `03-AGENTS/` | `audit-secrets.sh`, `check-wikilinks.sh` | C4/C7/C8, tenant awareness | 2 |
| `04-WORKFLOWS/` | `schema-validator.py`, `packager-assisted.sh` | C3/C5/C7, rollback explícito | 2 → 3 |
| `05-CONFIGURATIONS/` | `validate-frontmatter.sh`, `audit-secrets.sh`, linters específicos | C1‑C8 completos, secrets, idempotencia | 2 → 3 |
| `06-PROGRAMMING/` | `shellcheck`, `yamllint`, `terraform fmt` | Sintaxis estricta, zero‑hardcode | 1 → 2 |
| `07-PROCEDURES/` | `check-wikilinks.sh` | Pasos claros, referencias cruzadas | 1 |
| `08-LOGS/` | `schema-validator.py` | JSON, rotación, `tenant_id`/`trace_id` | 3 |

---

## 🔗 4. INTEGRACIÓN CON VALIDADORES EXISTENTES

| Validador | Ubicación | Función en orquestador | Condición de invocación |
|-----------|-----------|------------------------|-------------------------|
| `audit-secrets.sh` | `05-CONFIGURATIONS/validation/` | Detección de hardcode (C3) | Archivos con variables de entorno, `.tf`, `.sh` |
| `check-rls.sh` | `05-CONFIGURATIONS/validation/` | Verificación de RLS (C4) | Archivos en `BASE DE DATOS-RAG/`, configs PostgreSQL |
| `validate-frontmatter.sh` | `05-CONFIGURATIONS/validation/` | Metadatos canónicos | `.md`, `.yaml`, `.json`, `.tf` |
| `check-wikilinks.sh` | `05-CONFIGURATIONS/validation/` | Enlaces internos válidos | `.md`, documentación técnica |
| `verify-constraints.sh` | `05-CONFIGURATIONS/validation/` | Cumplimiento C1‑C6 textual | Todos los ejecutables / configuraciones |
| `schema-validator.py` | `05-CONFIGURATIONS/validation/` | Validación JSON Schema | `.json`, payloads de IA |
| `packager-assisted.sh` | `05-CONFIGURATIONS/scripts/` | Generación de ZIP firmado | Solo Nivel 3, post‑certificación |

---

## 🖥️ 5. MODOS DE OPERACIÓN

### 🧑‍💻 Modo Interactivo (Humano)
```bash
./orchestrator-engine.sh --interactive
```
- Preguntas guiadas: tipo de archivo, carpeta destino, función.
- Muestra validadores que se ejecutarán y por qué.
- Resultado claro con nivel certificado y acciones recomendadas.

### 🤖 Modo Headless (IA / CI/CD)
```bash
./orchestrator-engine.sh --json-input payload.json
```
**Estructura de entrada:**
```json
{
  "file_path": "ruta/al/archivo.ext",
  "file_type": "bash|terraform|yaml|markdown|json",
  "target_folder": "02-SKILLS/BASE DE DATOS-RAG/",
  "function": "query pattern",
  "constraints_declared": ["C1","C3","C4"]
}
```
**Estructura de salida:**
```json
{
  "tier_certified": 2,
  "passed_checks": ["C1","C3","C4","syntax"],
  "blocking_issues": [],
  "warnings": ["C5 missing examples"],
  "recommended_action": "ready_for_merge",
  "next_step": "Run CI gate",
  "sha256": "abc123..."
}
```

---

## 🛡️ 6. BLINDAJE MULTI‑TENANT Y NO‑REGRESIÓN

- **EspoCRM / MySQL:** Si el archivo toca BD, se verifica obligatoriamente:
  - Prefijos de tabla por tenant.
  - `tenant_id` como segundo campo.
  - Índices compuestos iniciando con `tenant_id`.
  - Prohibición de `SELECT *` sin filtro de tenant.
- **Aislamiento de namespace:** Prefijos únicos obligatorios (`mantis-vpsX-`, `tenant_`).
- **No‑regresión:** Si un archivo nuevo modifica un artefacto marcado `✅ COMPLETADO`, el orquestador exige checksum de integridad y declaración de impacto. Si es disruptivo sin plan de rollback → **BLOQUEO**.

---

## ⚠️ 7. RIESGOS Y MITIGACIÓN

| Riesgo | Mitigación |
|--------|------------|
| Falsos negativos por validador genérico | Enrutamiento específico por tipo + whitelist documentada |
| Complejidad de mantenimiento | Arquitectura modular + logs detallados + versionado semántico |
| Regresión en Tier 3 existentes | Gates de no‑modificación + checksums + rollback automático |
| Dependencia de binarios externos | Verificación de PATH al inicio + fallback graceful |

---

## 📅 8. PLAN DE IMPLEMENTACIÓN (RUTA CRÍTICA)

1. **Mapeo de validadores:** Consolidar rutas y flags de cada script.
2. **Desarrollo del motor:** Implementar `orchestrator-engine.sh` con capas y doble interfaz.
3. **Integración CI/CD:** Agregar gate en `.github/workflows/validate-skill.yml` que invoque al orquestador en `pull_request`.

---

## ✅ 9. CONCLUSIÓN

El Governance Orchestrator materializa el **contrato canónico de generación agéntica**. Traduce normas abstractas en decisiones binarias y certificadas, cerrando la brecha entre la generación asistida y la autogeneración autónoma. Su adopción garantiza que cada artefacto que toca producción haya pasado por el mismo escrutinio riguroso y determinista.

---

*Documento mantenido por el equipo de Arquitectura Agéntica. Cualquier modificación debe reflejarse en el motor ejecutable.*


---

