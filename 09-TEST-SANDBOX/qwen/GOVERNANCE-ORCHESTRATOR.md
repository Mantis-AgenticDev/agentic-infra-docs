# 📄 PROPUESTA ARQUITECTÓNICA: ORQUESTADOR CENTRALIZADO DE GOBERNANZA SDD
**Documento para Revisión de Equipo de IT / Arquitectura Agéntica**
**Ubicación Propuesta:** Raíz del repositorio (`/GOVERNANCE-ORCHESTRATOR.md`) + Motor ejecutable en `05-CONFIGURATIONS/validation/orchestrator-engine.sh`

---

## 🎯 1. CONTEXTO Y PROBLEMA ACTUAL

Hemos construido una base de infraestructura, validadores y normas robustas, pero operan de forma fragmentada. Actualmente:
- Cada validador (`audit-secrets.sh`, `check-rls.sh`, `validate-frontmatter.sh`, etc.) funciona aislado.
- No existe un criterio unificado para decidir si un archivo generado por IA es apto para: revisión humana, merge automático, o despliegue autónomo con ZIP.
- Las validaciones genéricas generan falsos positivos cuando se aplican a carpetas con propósitos distintos.
- El multi-tenancy de EspoCRM/MySQL requiere enforcement estricto que no depende de la memoria del desarrollador.
- Falta un "contrato vivo" que traduzca las normas C1-C8 en decisiones binarias certificadas por nivel de madurez.

**Necesitamos un único punto de control que:**
1. Se ejecute por terminal con guía humana paso a paso.
2. Funcione en modo headless para que las IA lo consuman como regla canónica infranqueable.
3. Clasifique, valide y certifique cada archivo según su ubicación, tipo y función.
4. Orqueste los validadores existentes sin duplicar lógica.
5. Bloquee la integración si no cumple el umbral definido.

---

## 🧠 2. ARQUITECTURA DEL MOTOR DE DECISIÓN POR CAPAS

El orquestador no es un script más. Es un **sistema de certificación automatizada** con 4 capas lógicas:

### 🔹 CAPA 1: IDENTIDAD Y CONTEXTO

Antes de validar, el motor responde:
- ¿Qué tipo de archivo es? (`.sh`, `.tf`, `.yaml`, `.md`, `.json`, `.yml`)
- ¿En qué rama del árbol vive? (`02-SKILLS/`, `04-WORKFLOWS/`, `05-CONFIGURATIONS/`, etc.)
- ¿Qué función cumple? (Documentación, patrón, configuración ejecutable, definición de agente, pipeline)
- ¿Tiene metadatos canónicos? (`canonical_path`, `ai_optimized: true`, `constraints_mapped`)

Si falta identidad clara → **RECHAZO INMEDIATO**. No avanza.

### 🔹 CAPA 2: FILTRO NORMATIVO C1-C8

Aplica las reglas base de forma obligatoria, sin excepciones:
- **C1/C2**: Límites de recursos declarados o referenciados explícitamente.
- **C3**: Cero hardcode. Uso de `${VAR:?missing}`, `sensitive = true`, o gestión externa de secretos.
- **C4**: `tenant_id` presente, referenciado o forzado en queries/policies/labels.
- **C5**: Comando de validación declarado + ejemplos de éxito/fallo.
- **C6**: Inferencia cloud-only. Prohibido `localhost` para IA en producción.
- **C7**: Resiliencia declarada (timeouts, retries, healthchecks, circuit breakers).
- **C8**: Observabilidad estructurada (JSON logs, `trace_id`, integración OTEL).

Si falla en C3 o C4 → **BLOQUEO CRÍTICO**. Si falla en otros → **ADVERTENCIA BLOQUEANTE** según nivel objetivo.

### 🔹 CAPA 3: CERTIFICACIÓN POR NIVELES (El núcleo de la decisión)

El motor evalúa madurez funcional y asigna un tier automático:

| Nivel | Nombre | Umbral Mínimo | Acción Automática | Uso Típico |
|-------|--------|---------------|-------------------|------------|
| 🟢 **NIVEL 1** | SDD Asistida por IA | Sintaxis OK + C1-C8 base + ≥5 ejemplos + frontmatter válido | Requiere aprobación humana. Se muestra en pantalla/PR. | Skills en progreso, docs técnicos, schemas referenciales, `README` de carpetas. |
| 🟡 **NIVEL 2** | Autogeneración + Entrega Pantalla | Nivel 1 + 0 placeholders residuales + validador ejecutable + ≥10 ejemplos + determinismo | Merge automático tras gate CI. Salida directa de IA. | Scripts bash, configs Docker/Terraform, assertions `promptfoo`, definiciones de agentes, queries SQL con `tenant_id` forzado. |
| 🔴 **NIVEL 3** | Auto-Deploy + ZIP Autónomo | Nivel 2 + idempotencia + healthcheck/rollback + CI/CD trigger + manifiesto/SHA256 + namespace aislado | Pipeline directo. Genera ZIP firmado. Deploy sin intervención. | `docker-compose` con healthchecks, workflows n8n con nodos de error, módulos Terraform con RLS, `packager-assisted.sh` outputs. |

### 🔹 CAPA 4: ENRUTAMIENTO Y ACCIÓN

Según el tier asignado y la ubicación del archivo, el orquestador decide:
- ¿Qué validadores externos invocar? (`audit-secrets.sh`, `check-rls.sh`, `schema-validator.py`, etc.)
- ¿Qué gate de CI/CD aplicar?
- ¿Generar reporte JSON? ¿Actualizar `skill-validation-report.json`?
- ¿Bloquear merge si es nivel inferior al esperado?

---

## 🗺️ 3. MATRIZ DE MAPEO: UBICACIÓN × FUNCIÓN × NORMATIVA APLICABLE

| Directorio / Función | Tipo de Archivo Predominante | Validadores Externos Activados | Normas Críticas | Tier Objetivo |
|----------------------|-----------------------------|-------------------------------|----------------|---------------|
| `00-CONTEXT/` | Docs base, overview, contextos | `check-wikilinks.sh`, `validate-frontmatter.sh` | Coherencia con `PROJECT_TREE.md`, frontmatter puro | 1 |
| `01-RULES/` | Normas canónicas, constraints | `verify-constraints.sh`, `audit-secrets.sh` | C1-C8 explícitos, sin placeholders, trazabilidad | 2 |
| `02-SKILLS/` | Patrones, schemas, queries, decision trees | `check-rls.sh` (si DB), `schema-validator.py` | C4 forzado, `tenant_id` en queries/índices, ≥10 ejemplos | 1 → 2 |
| `03-AGENTS/` | Definiciones de agentes, lógica | `audit-secrets.sh`, `check-wikilinks.sh` | C4/C7/C8, tenant awareness, error handling explícito | 2 |
| `04-WORKFLOWS/` | JSON n8n, pipelines, diagramas | `schema-validator.py`, `packager-assisted.sh` | C3/C5/C7, nodos de rollback, CI/CD compatibility | 2 → 3 |
| `05-CONFIGURATIONS/` | Infra, deploy, env, scripts | `validate-frontmatter.sh`, `audit-secrets.sh`, `docker/terraform lint` | C1-C8 completos, secrets management, healthchecks, idempotencia | 2 → 3 |
| `06-PROGRAMMING/` | Patrones de código (JS, Python, SQL) | `shellcheck`/`yamllint`/`terraform fmt` según tipo | Sintaxis estricta, `tenant_id` en queries, zero-hardcode | 1 → 2 |
| `07-PROCEDURES/` | Runbooks, checklists, SOPs | `check-wikilinks.sh` | Pasos claros, checks pre/post, referencias cruzadas | 1 |
| `08-LOGS/` | Auditoría, reports, traces | `schema-validator.py` | Formato JSON, rotación, `tenant_id`/`trace_id` | 3 (si auto-generado) |

---

## 🔗 4. INTEGRACIÓN CON VALIDADORES EXISTENTES

El orquestador **no reemplaza**. **Coordina**:

| Validador Actual | Rol en el Orquestador | Cuándo se Llama |
|------------------|----------------------|-----------------|
| `audit-secrets.sh` | Detector C3 | Siempre que haya archivos con credenciales/env vars |
| `check-rls.sh` | Verificador C4 en DB | Solo en `02-SKILLS/BASE DE DATOS-RAG/` o configs SQL/PostgreSQL |
| `validate-frontmatter.sh` | Verificador de metadatos | En `.md`, `.yaml`, `.json`, `.tf` |
| `check-wikilinks.sh` | Validador de referencias | En `.md` y docs técnicos |
| `verify-constraints.sh` | Check C1-C6 textual | En todos los archivos ejecutables/config |
| `schema-validator.py` | Validador JSON Schema | En `.json` y payloads de IA |
| `packager-assisted.sh` | Generador ZIP/checksum | Solo en Tier 3, post-certificación |
| `VALIDATOR_DOCUMENTATION.md` | Guía de referencia | Consumida por el motor para mapear reglas a tipos de archivo |

El orquestador lee el tipo de archivo, consulta la matriz de mapeo, llama a los validadores correspondientes, consolida resultados y emite el tier final.

---

## 🖥️ 5. DOBLE INTERFAZ: HUMANO VS IA

### 🧑‍💻 Modo Terminal Interactivo (Humano)

- Inicia con preguntas guiadas: `¿Qué tipo de archivo estás validando?`, `¿En qué carpeta se ubicará?`, `¿Cuál es su función principal?`
- Muestra en tiempo real qué validadores se ejecutarán y por qué.
- Devuelve resultado claro: `✅ CERTIFICADO: NIVEL 2`, `⚠️ REQUIERE CORRECCIÓN: Falta tenant_id en queries 3 y 5`, `📋 ACCIÓN: Ejecuta ./05-CONFIGURATIONS/scripts/packager-assisted.sh`
- Genera log legible para auditoría humana.

### 🤖 Modo Headless (IA / Autogeneración)

- Recibe payload JSON con: `file_path`, `file_type`, `target_folder`, `function`, `constraints_declared`.
- Ejecuta en silencio. Sin prompts, sin preguntas.
- Retorna JSON estructurado con: `tier_certified`, `passed_checks`, `blocking_issues`, `recommended_action`, `sha256`, `next_step`.
- Compatible con CI/CD gates y pipeline de autogeneración.

---

## 🛡️ 6. BLINDAJE MULTI-TENANT Y NO-REGRESIÓN

- **EspoCRM / MySQL**: Si el archivo toca esquemas DB o configs de CRM, el orquestador activa verificación obligatoria de prefijos de tabla, `tenant_id` como segundo campo, índices compuestos iniciando con `tenant_id`, y RLS policies. Si detecta `SELECT *` o `shared_db` sin aislamiento, bloquea automáticamente.
- **Aislamiento de Namespace**: Exige prefijos únicos (`mantis-vpsX-`, `tenant_`, `kb_`). Prohíbe colisión con artefactos existentes marcados como `✅ COMPLETADO`.
- **No-Regresión Estructural**: Si un archivo nuevo modifica o referencia un archivo Tier 3 existente, el orquestador exige checksum de integridad y declara explícitamente si es aditivo o disruptivo. Si es disruptivo sin plan de rollback → bloqueo.
- **Idempotencia & Determinismo**: Mismo input → mismo output. Ejecutar el motor dos veces no altera estado ni genera duplicados.

---

## 📅 7. PLAN DE IMPLEMENTACIÓN (RUTA CRÍTICA)

**Mapeo de Validadores**: Consolidar rutas, flags de ejecución y condiciones de activación de cada script existente.
**Desarrollo del Motor**: Implementar `orchestrator-engine.sh` con lógica de capas, doble interfaz y reporte JSON.
**Integración CI/CD**: Agregar gate en `.github/workflows/validate-skill.yml` que llame al orquestador en `pull_request` y `push`.

---

## ⚠️ 8. RIESGOS IDENTIFICADOS Y MITIGACIÓN

| Riesgo | Impacto | Mitigación |
|--------|---------|------------|
| Falsos negativos por validador genérico | Merge de archivos inválidos | Ruteo específico por tipo + whitelist de excepciones documentadas |
| Complejidad de mantenimiento | Motor se vuelve monolítico | Arquitectura modular interna + logs detallados + versión semántica |
| Regresión en Tier 3 existentes | Downtime o corrupción de deploy | Gates de no-modificación + checksums + rollback automático |
| Dependencia de binarios externos (`yq`, `terraform`, `shellcheck`) | Fallos en CI/CD o local | Verificación de PATH al inicio + fallback graceful con advertencia clara |

---

## ✅ 9. CONCLUSIÓN Y PRÓXIMOS PASOS

Este orquestador no es un script más. Es el **sistema nervioso central** que traduce nuestras normas (C1-C8, multi-tenant, no-regresión, hardening) en decisiones binarias, certificadas y ejecutables. Cierra la brecha entre "generación asistida" y "autogeneración autónoma", y nos da control total sobre la madurez de cada artefacto antes de que toque producción.

---

### 🛠️ ANEXO: DETALLES TÉCNICOS Y EJEMPLOS

#### 🧩 MATRIZ DE ENRUTAMIENTO DE VALIDADORES

El problema actual es que el validador maestro aplica las mismas reglas a todo. La solución es un **enrutador por tipo**:

| Tipo | Validador | Reglas clave | Fallo automático si |
|------|-----------|--------------|---------------------|
| `.sh` | `validate-type-bash.sh` | Shebang, `set -euo`, heredoc JSON, `#` en frontmatter | Falta `set -euo`, `echo "{"`, frontmatter sin comentar |
| `.tf` | `validate-type-terraform.sh` | `terraform fmt`, `validation {}`, `sensitive`, `tenant_id` outputs | Indentación errónea, secrets en default, sin `validation` |
| `.yaml/.yml` | `validate-type-yaml.sh` | `yamllint`, estructura asserts, frontmatter puro, sin tabs | Tabs, frontmatter comentado, asserts vacíos |
| `.md` | `validate-type-markdown.sh` | Wikilinks canónicos, `check-wikilinks`, ≥5 ejemplos, fences | Links rotos, <5 ejemplos, código sin fence |
| `.json` | `validate-type-json.sh` | `jq empty`, schema strict, sin trailing commas | Sintaxis inválida, campos requeridos faltantes |

Esto elimina los falsos positivos. Cada archivo va a su validador específico. El validador maestro solo orquesta y reporta consolidado.

#### 🧠 ANÁLISIS DE RIESGO CRÍTICO & BLINDAJE

| Riesgo | Probabilidad sin contrato | Probabilidad con contrato | Impacto |
|--------|--------------------------|--------------------------|---------|
| Fuga de datos multi-tenant (EspoCRM/MySQL) | Media-Alta (error humano/junior) | Baja (RLS + prefijos + validador C4) | Multas LGPD, pérdida de clientes |
| Corrupción de estructura existente | Media (sobrescritura accidental) | Casi nula (no-regresión + prefijos + gates) | Downtime, rollbacks costosos |
| Alucinación de IA en configs críticos | Alta (sin validación tipo-specific) | Baja (validador enrutado + determinismo) | Deploy fallido, debugging ciego |
| Fallo en autogeneración ZIP | Media (metadatos faltantes) | Baja (manifest + checksums + CI/CD gate) | Entrega inválida, soporte manual |

**Blindaje real**: No es más validación. Es **validación inteligente + aislamiento estructural + contrato de generación**. Si un archivo no cumple el contrato, no se mergea. Punto.

---

### 📜 CONTRATO CANÓNICO DE GENERACIÓN AI (REGLAS INFRANQUEABLES)

Estas son las normas que la IA debe internalizar como "leyes físicas" del repositorio. Si no puede cumplirlas, debe abortar y reportar:

1. **Navegación canónica obligatoria**: Todo se resuelve desde `PROJECT_TREE.md`. Cero inferencia externa.
2. **Frontmatter por extensión**: `.sh` = comentado; `.tf/.yaml/.md` = YAML puro. Sin excepciones.
3. `tenant_id` es axiomático: Segundo campo en tablas, filtro obligatorio en queries, label en volúmenes, atributo en logs. Sin él, el archivo se descarta.
4. **Cero hardcode**: `${VAR:?missing}`, `sensitive = true`, o referencia a vault. Si ves un string que parece secreto, es error bloqueante.
5. **Determinismo + Idempotencia**: Mismo input → mismo output. Ejecutar dos veces no corrompe.
6. **Validación autocontenida**: Cada archivo incluye su comando de verificación exacto y ≥5 ejemplos de éxito/fallo/solución.
7. **Aislamiento estricto**: Prefijos únicos, redes internas, puertos localhost, RLS o schema separation. Prohibido "compartir por defecto".
8. **Cloud-only inference**: Prohibido `localhost:11434` o modelos locales en configs de prod. Solo endpoints públicos validados.
9. **No-regresión estructural**: Nuevo archivo no modifica, sobrescribe ni rompe artefactos `✅ COMPLETADO`. Si requiere ajuste, debe ser aditivo o versionado.
10. **Deploy-ready o falla explícita**: Si no pasa validación automática, el archivo no se entrega. Se reporta el error exacto y se detiene.

---

### 📊 Validated Examples (≥10)

1. ✅ Deberías ver: `tenant_id` validado con regex `^tenant-[a-z0-9_-]+$`
   ❌ Si ves esto: `tenant_id = "admin"` o sin formato
   🔧 Solución: Usar `TF_VAR_tenant_id="tenant-restaurante01"`

2. ✅ Deberías ver: `sensitive = true` en `qdrant_api_key`
   ❌ Si ves esto: `default = "sk-qdrant-123"`
   🔧 Solución: Remover default, inyectar vía `TF_VAR_qdrant_api_key`

3. ✅ Deberías ver: `storage_gb` entre 5 y 40
   ❌ Si ves esto: `storage_gb = 100`
   🔧 Solución: Ajustar a `40` (límite C1 por VPS)

4. ✅ Deberías ver: `memory_mb` ≤ 2048
   ❌ Si ves esto: `memory_mb = 4096`
   🔧 Solución: Qdrant no debe competir con n8n/uazapi por RAM

5. ✅ Deberías ver: `listen_port` en rango interno
   ❌ Si ves esto: `listen_port = 8080`
   🔧 Solución: Usar `6333` y exponer solo en red Docker interna

6. ✅ Deberías ver: `cloud_inference_endpoint` sin localhost
   ❌ Si ves esto: `https://127.0.0.1:8000`
   🔧 Solución: Forzar `openrouter.ai` o `dashscope.aliyuncs.com` (C6)

7. ✅ Deberías ver: Frontmatter comentado con `#`
   ❌ Si ves esto: `---` sin comentar al inicio
   🔧 Solución: Comentar todas las líneas YAML para compatibilidad `terraform fmt`

8. ✅ Deberías ver: `validation {}` blocks activos
   ❌ Si ves esto: Variables sin validación
   🔧 Solución: Agregar `validation { condition = ... }` por cada variable crítica

9. ✅ Deberías ver: Wikilinks canónicos en ejemplos
   ❌ Si ves esto: `[[AWS/vpc]]` o rutas inventadas
   🔧 Solución: Referenciar solo `01-RULES/` y `02-SKILLS/` existentes

10. ✅ Deberías ver: `terraform validate -no-color -json`
    ❌ Si ves esto: `terraform validate variables.tf`
    🔧 Solución: Ejecutar siempre desde la raíz del módulo, no por archivo

# 🟢 VALIDATION: ./05-CONFIGURATIONS/validation/validate-skill-integrity.sh --strict /GOVERNANCE-ORCHESTRATOR.md
---END-OF-FILE---
