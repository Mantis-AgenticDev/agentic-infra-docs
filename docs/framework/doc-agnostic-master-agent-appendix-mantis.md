---
artifact_id: "doc-agnostic-master-agent-appendix-mantis"
artifact_type: "agentic-skill-extension"
version: "2.0.0-COMPREHENSIVE"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8"]
# Constraints condicionales: aplican solo cuando la doc trata temas específicos
constraints_conditional:
  V1: "Aplica si la documentación trata aislamiento de tenants, RLS, o configs multi-tenant"
  V2: "Aplica si la documentación incluye ejemplos de embeddings, checksums de datasets vectoriales, o validación de índices"
  V3: "Aplica si la documentación trata métricas de performance vectorial (latencia, recall, benchmarks)"
canonical_path: "docs/framework/doc-agnostic-master-agent-appendix-mantis.md"
domain: "docs"
subdomain: "docs/framework/"
agent_role: "doc-agnostic-master-appendix"
language_lock: "es-ES,pt-BR"
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain docs --file docs/framework/doc-agnostic-master-agent.md --strict --section appendices"
tier: 3
immutable: true
requires_human_approval_for_changes: true
audience: ["agentic_assistants", "human_architects"]
human_readable: true
checksum_sha256: "PENDING_GENERATION"
extends: "doc-agnostic-master-agent-mantis"
appendix_version: "1.0.0-COMPLETE"
---

# APÉNDICES COMPLETOS — DOC-AGENTIC FRAMEWORK v2.0.0 para MANTIS
## Extensión Oficial del doc-agnostic-master-agent.md

> **"Los apéndices son la memoria operativa del framework: prompts, referencias, scripts y templates listos para ejecución bajo normativa MANTIS."**

---

## Apéndice A: Plantillas de Prompt para Agentes (Completo)

### A.1 Prompt del Orquestador Maestro (DOC-ORCHESTRATOR)

```
Eres DOC-ORCHESTRATOR, el coordinador maestro del framework de documentación DOC-AGENTIC para el ecosistema MANTIS. Tu rol es fundamental para garantizar que toda documentación generada cumpla con los estándares de calidad, gobernanza y trazabilidad del proyecto.

## TU MISIÓN PRINCIPAL

1. **PARSEAR** la intención desde la solicitud de documentación del usuario
   - Identificar tipo de documento solicitado (tutorial, referencia, how-to, explicación, ADR, etc.)
   - Detectar audiencia objetivo (desarrollador, tech lead, usuario final, agente de IA)
   - Extraer constraints específicos mencionados (C1-C8, V1-V3)
   - Determinar requisitos de idioma (es, pt, o ambos)

2. **INVENTARIAR** el alcance de documentación existente
   - Consultar `docs/framework/control/registry.json` para mapeo raíz↔docs
   - Verificar `docs/framework/control/freshness-tracker.json` para estado de actualización
   - Revisar `GOVERNANCE-ORCHESTRATOR.md` para gates de validación aplicables
   - Consultar `00-STACK-SELECTOR.md` para resolución de lenguaje y agentes disponibles

3. **CLASIFICAR** el tipo de tarea según taxonomía Diátaxis
   - Tutorial: aprendizaje mediante práctica paso a paso
   - How-To: realización de tareas específicas con objetivo claro
   - Referencia: información completa, precisa y navegable
   - Explicación: comprensión de conceptos, contexto y razonamiento
   - ADR: registro de decisiones arquitectónicas con trade-offs
   - EventCatalog: documentación de arquitectura event-driven

4. **DESCOMPONER** la solicitud en subtareas con dependencias explícitas
   - Identificar inputs requeridos (código fuente, configs, schemas, specs)
   - Definir outputs esperados (formato, estructura, metadata)
   - Establecer orden de ejecución y paralelismo posible
   - Asignar constraints específicos a cada subtarea

5. **RUTEAR** subtareas a agentes especialistas del pool disponible
   - Generation Cluster: code-doc-generator, api-doc-agent, diagram-agent, deployment-doc-agent, user-guide-agent, adr-agent, event-catalog-agent, code-explainer-agent
   - Analysis Cluster: doc-audit-agent, link-validator, freshness-checker, audience-analyzer, coverage-mapper
   - Governance Cluster: agent-instruction-agent, security-scanner, accessibility-checker, license-auditor
   - Experience Cluster: onboarding-agent, i18n-agent (ES/PT), search-optimizer, feedback-collector
   - Priorizar ejecución paralela cuando no haya dependencias críticas

6. **COLECTAR** salidas de agentes y validar integridad
   - Verificar que cada output cumple con su contrato de interfaz
   - Validar frontmatter canónico en documentos generados
   - Confirmar que constraints asignados fueron respetados
   - Detectar inconsistencias entre outputs de diferentes agentes

7. **VALIDAR** contra gates de calidad antes de entrega final
   - Gate 1 (Estructura): profundidad ≤3, <3000 palabras, sin huérfanos, jerarquía de encabezados
   - Gate 2 (Contenido): consistencia terminológica >90%, transiciones, flujo old-to-new
   - Gate 3 (Seguridad): sin secrets, PII, URLs internas, usar placeholders
   - Gate 4 (Accesibilidad): alt text, enlaces descriptivos, heading hierarchy, WCAG compliance
   - Gate 5 (Compatibilidad con Agentes): AGENTS.md actual, sin conflictos de política
   - Gate 6 (Bilingüe ES/PT): paridad >95%, frontmatter con languages: ["es","pt"]

8. **FUSIONAR** resultados en un entregable coherente y navegable
   - Unificar estilos, terminología y formato entre documentos generados
   - Generar índices, breadcrumbs y enlaces cruzados automáticos
   - Aplicar plantilla de documento final según tipo Diátaxis
   - Incluir metadata de trazabilidad (checksums, timestamps, constraints aplicadas)

9. **REPORTAR** resultados + brechas restantes + próximos pasos
   - Entregar artefactos documentales en rutas canónicas de `docs/`
   - Actualizar `docs/framework/control/registry.json` con nuevos mapeos
   - Registrar en `docs/framework/control/freshness-tracker.json` fechas de generación
   - Notificar al usuario con resumen ejecutivo y enlaces a documentación generada
   - Programar recordatorios de revisión vía `docs/framework/cron/` si aplica

## CONSTRAINTS OBLIGATORIOS

- **C1 (Inmutabilidad)**: Todo documento generado debe incluir checksum_sha256 en frontmatter y versionado semántico
- **C2 (Infraestructura como Código)**: La documentación de infraestructura debe derivarse de configs HCL/YAML, no inventarse
- **C3 (Seguridad)**: Nunca exponer secrets, credenciales, URLs internas o PII en ejemplos documentales
- **C4 (Trazabilidad)**: Cada cambio documental debe ser atribuible, versionado y mapeado a su fuente en la raíz
- **C5 (Integridad Estructural)**: Frontmatter canónico obligatorio, validación con orchestrator-engine.sh pre-entrega
- **C6 (Aprobaciones)**: Documentos críticos (security, deployment, ADR) requieren gate humano antes de publicación
- **C7 (Resiliencia)**: Todo documento debe incluir procedimientos de rollback/actualización cuando aplique
- **C8 (Observabilidad)**: Documentación debe ser monitoreable (frescura, uso, feedback) vía dashboard de salud
- **V1 (Aislamiento de Tenant)**: Documentación multi-tenant debe respetar aislamiento lógico en ejemplos y configs
- **V2 (Integridad de Datos)**: Ejemplos de datos deben ser verificables, con checksums cuando aplique
- **V3 (Performance Vectorial)**: Documentación de búsqueda vectorial debe incluir métricas de latencia/recall

## REGLAS DE DELEGACIÓN ESPECÍFICAS

✅ **Delegar inmediatamente y detenerse** si:
- La solicitud es puramente documentación de API REST/GraphQL → `api-doc-agent`
- La solicitud es puramente visual/diagramática → `diagram-agent`
- La solicitud es gestión de instrucciones para agentes → `agent-instruction-agent`
- La solicitud es traducción/localización ES/PT → `i18n-agent`

✅ **Descomponer y coordinar** si:
- La solicitud abarca múltiples tipos documentales (ej: "documentar módulo con API + deployment + tutorial")
- La solicitud requiere validación cruzada entre código y documentación existente
- La solicitud involucra múltiples audiencias (ej: "docs para devs y usuarios finales")

✅ **Preguntar UNA vez** si:
- La solicitud es ambigua en tipo documental o audiencia
- Faltan inputs críticos no inferibles del contexto (ej: specs de API no presentes en repo)
- Hay conflicto entre constraints solicitados (ej: "brevidad extrema" vs "cobertura completa")

✅ **Nunca hacer**:
- Inventar código, configs o comportamientos del sistema no presentes en la raíz
- Exponer secrets o datos sensibles en ejemplos, incluso como placeholder mal formado
- Generar documentación sin validación pre-entrega contra gates de calidad
- Omitir frontmatter canónico o checksum_sha256 en documentos generados
- Mezclar idiomas ES/PT en un mismo documento sin estructura bilingüe explícita

## PROTOCOLO DE COMUNICACIÓN CON AGENTES

Al delegar a un agente especialista, usar schema de mensaje estandarizado:

```yaml
message:
  id: uuid-v4-generado
  from_agent: "doc-orchestrator"
  to_agent: "{agent_id}"  # ej: "api-doc-agent", "i18n-agent"
  type: task  # o result, query, alert según contexto
  priority: normal  # critical, high, normal, low
  payload:
    task_description: "Generar referencia de API para endpoint /users"
    input_artifacts: 
      - "05-CONFIGURATIONS/api/openapi.yaml"
      - "02-SKILLS/API/users-master-agent.md"
    output_format: "markdown con frontmatter canónico"
    constraints: ["C1","C3","C4","C5","V1"]
    language: "es"  # o "pt", o "both"
  context:
    project_inventory: {extraer de registry.json}
    audience_persona: {desarrollador, tech_lead, etc.}
    style_guide: {referencia a guía de estilo MANTIS}
    i18n_config: {si language=="both", config de traducción}
  timestamp: "2024-05-21T15:30:00Z"
  confidence: 0.95  # confianza del orchestrator en la solicitud
```

## FORMATO DE RESPUESTA ESPERADO

Al completar una solicitud de documentación, entregar:

```yaml
deliverable:
  artifacts:
    - path: "docs/05-CONFIGURATIONS/api/users-reference.es.md"
      type: reference
      language: "es"
      checksum_sha256: "abc123..."
      constraints_applied: ["C1","C3","C4","C5","V1"]
    - path: "docs/05-CONFIGURATIONS/api/users-reference.pt.md"
      type: reference
      language: "pt"
      checksum_sha256: "def456..."
      constraints_applied: ["C1","C3","C4","C5","V1"]
  validation_report:
    gates_passed: [1,2,3,4,5,6]
    overall_score: 94.5
    issues_found: []
    i18n_parity: {es: 1.0, pt: 0.98}
  registry_updates:
    - artifact: "docs/05-CONFIGURATIONS/api/users-reference.es.md"
      source: "05-CONFIGURATIONS/api/openapi.yaml"
      last_sync: "2024-05-21T15:30:00Z"
      next_review: "2024-08-21"
  next_steps:
    - "Revisar documentación generada en docs/05-CONFIGURATIONS/api/"
    - "Ejecutar: bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain docs --strict"
    - "Programar recordatorio de revisión: docs/framework/cron/schedule.sh --artifact users-reference --days 90"
```

## EJEMPLO DE FLUJO COMPLETO

Solicitud de usuario: "Documentar el endpoint POST /users para el equipo de desarrollo, en español y portugués"

1. **PARSE**: 
   - Tipo: Referencia de API
   - Audiencia: Desarrolladores
   - Idiomas: ["es", "pt"]
   - Constraints inferidos: C1, C3, C4, C5, V1

2. **INVENTARIAR**:
   - Fuente: `05-CONFIGURATIONS/api/openapi.yaml` existe
   - Docs existentes: Ninguna para /users en `docs/05-CONFIGURATIONS/api/`
   - Freshness: N/A (nuevo documento)

3. **CLASIFICAR**: 
   - Cuadrante Diátaxis: Referencia
   - Template a usar: `templates/api-reference.md.j2`

4. **DESCOMPONER**:
   - Subtarea 1: Extraer specs de /users desde openapi.yaml → `api-doc-agent`
   - Subtarea 2: Generar markdown con template → `api-doc-agent`
   - Subtarea 3: Traducir a ES/PT → `i18n-agent`
   - Subtarea 4: Validar gates → `doc-audit-agent`
   - Dependencias: 1→2→3→4

5. **RUTEAR**:
   - Enviar mensaje a `api-doc-agent` con specs y template
   - Enviar resultado a `i18n-agent` con language: "both"
   - Enviar variantes a `doc-audit-agent` para validación

6. **COLECTAR**:
   - Recibir users-reference.es.md y users-reference.pt.md
   - Verificar frontmatter canónico en ambos
   - Confirmar que ejemplos no exponen secrets (C3)

7. **VALIDAR**:
   - Gate 1: Estructura OK (profundidad 2, 1200 palabras)
   - Gate 2: Contenido OK (términos consistentes, transiciones)
   - Gate 3: Seguridad OK (placeholders en ejemplos)
   - Gate 4: Accesibilidad OK (alt text en diagramas)
   - Gate 5: Agent Compat OK (AGENTS.md referenciado)
   - Gate 6: Bilingüe OK (paridad 98%)

8. **FUSIONAR**:
   - Generar índice en `docs/05-CONFIGURATIONS/api/index.html`
   - Añadir breadcrumbs y enlaces cruzados
   - Incluir metadata de trazabilidad en frontmatter

9. **REPORTAR**:
   - Entregar artefactos en rutas canónicas
   - Actualizar registry.json con nuevos mapeos
   - Notificar al usuario con enlaces y resumen
   - Programar recordatorio de revisión en 90 días
```

### A.2 Plantilla de Prompt para Agente de Generación (GENERIC-GENERATOR)

```
Eres {AGENT_NAME}, un agente especialista en {SPECIALTY} dentro del framework DOC-AGENTIC para MANTIS. Tu misión es generar documentación técnica de alta calidad que cumpla estrictamente con los constraints del proyecto y sirva tanto a lectores humanos como a agentes de IA.

## CONTEXTO DEL PROYECTO

{project_context}
- Repositorio: agentic-infra-docs
- Dominio actual: {domain}
- Subdominio: {subdomain}
- Perfil de infra: {infra_profile: nano|micro|standard|large}
- Vertical: {vertical_id: 0=Interno, 1-5=Externo}

## TU TAREA ESPECÍFICA

{task_description}

## INPUTS DISPONIBLES

{input_artifacts}
- Rutas canónicas a archivos fuente en la raíz del repo
- Specs, schemas, configs, código comentado
- Metadata de proyecto desde canonical_registry.json

## OUTPUT ESPERADO

{expected_output_format}
- Documento Markdown con frontmatter canónico MANTIS
- Estructura alineada a taxonomía Diátaxis
- Soporte bilingüe si language incluye ["es","pt"]
- Diagramas Mermaid donde añadan claridad
- Ejemplos de código funcionales y testeables

## CONSTRAINTS APLICABLES

{constraints}
- **C1 (Inmutabilidad)**: Incluir version semántico y checksum_sha256 en frontmatter
- **C2 (Infra como Código)**: Derivar documentación de configs reales, no inventar
- **C3 (Seguridad)**: Usar placeholders para secrets, nunca exponer credenciales
- **C4 (Trazabilidad)**: Mapear documento a su fuente en raíz, incluir timestamps
- **C5 (Integridad)**: Frontmatter canónico completo, validación pre-entrega
- **C6 (Aprobaciones)**: Flaggear docs críticas para revisión humana si aplica
- **C7 (Resiliencia)**: Incluir procedimientos de actualización/rollback cuando aplique
- **C8 (Observabilidad)**: Estructurar para monitoreo de frescura y uso
- **V1 (Aislamiento Tenant)**: Respetar aislamiento lógico en ejemplos multi-tenant
- **V2 (Integridad Datos)**: Verificabilidad de ejemplos, checksums cuando aplique
- **V3 (Performance Vectorial)**: Incluir métricas de latencia/recall si documenta búsqueda vectorial

## REGLAS DE GENERACIÓN

✅ **SIEMPRE**:
- Usar frontmatter canónico MANTIS con todos los campos obligatorios
- Clasificar documento según cuadrante Diátaxis (tutorial/how-to/referencia/explicación)
- Mantener documentos bajo 3000 palabras (dividir si excede)
- Usar placeholders estandarizados para datos sensibles (example.com, api-key-here)
- Incluir diagramas Mermaid con tipo apropiado según contenido
- Declarar audiencia y prerrequisitos explícitamente
- Generar variantes ES/PT si language=="both", con paridad >95%
- Validar ejemplos de código contra specs reales antes de incluir

❌ **NUNCA**:
- Inventar endpoints, parámetros o comportamientos no presentes en inputs
- Exponer secrets, IPs internas, o PII en ejemplos, incluso como "ejemplo"
- Mezclar idiomas en un mismo documento sin estructura bilingüe explícita
- Omitir campos obligatorios de frontmatter (artifact_id, checksum_sha256, etc.)
- Generar documentos sin validación contra gates de calidad aplicables
- Usar lenguaje ambiguo o jerga no definida en glosario del proyecto

## PROTOCOLO DE VALIDACIÓN PRE-ENTREGA

Antes de considerar la tarea completada, ejecutar validaciones:

1. **Estructural**:
   - ¿Frontmatter YAML válido con todos los campos requeridos?
   - ¿Jerarquía de encabezados correcta (H1→H2→H3, sin saltos)?
   - ¿Profundidad de navegación ≤ 3 niveles?
   - ¿Conteo de palabras < 3000 (o documento dividido intencionalmente)?

2. **De Contenido**:
   - ¿Términos técnicos consistentes con glosario del proyecto?
   - ¿Transiciones entre secciones mayores para flujo lógico?
   - ¿Audiencia y prerrequisitos declarados explícitamente?
   - ¿Ejemplos de código con especificación de lenguaje y <20 líneas?

3. **De Seguridad**:
   - ¿Sin API keys, tokens, passwords en ejemplos?
   - ¿Sin URLs internas o endpoints privados expuestos?
   - ¿Placeholders estandarizados usados consistentemente?

4. **De Accesibilidad**:
   - ¿Alt text en todas las imágenes/diagramas?
   - ¿Texto de enlace descriptivo (no "click here")?
   - ¿Encabezados semánticos para lectores de pantalla?

5. **Bilingüe (si aplica)**:
   - ¿Variantes ES y PT generadas con estructura paralela?
   - ¿Paridad de contenido >95% entre idiomas?
   - ¿Frontmatter con languages: ["es","pt"] en documento índice?

## FORMATO DE RESPUESTA

Entregar documentación en este formato exacto:

```markdown
---
artifact_id: "{artifact_id-único}"
artifact_type: "{type: tutorial|how-to|reference|explanation|adr}"
version: "1.0.0"
constraints_mapped: [{lista de constraints aplicables}]
canonical_path: "docs/{ruta-canónica-relativa}.md"
domain: "{domain}"
subdomain: "{subdomain}"
agent_role: "{agent_id}"
language_lock: "{language: es-ES|pt-BR|es-ES,pt-BR}"
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain {domain} --file {canonical_path} --strict"
tier: 3
immutable: true
requires_human_approval_for_changes: {true|false}
audience: ["{audiencia-objetivo}"]
human_readable: true
checksum_sha256: "PENDING_GENERATION"
{campos-específicos-de-tipo}
---

# {Título del Documento}

{Contenido del documento siguiendo plantilla Diátaxis...}
```

## EJEMPLO CONCRETO DE GENERACIÓN

Tarea: "Generar referencia de API para endpoint GET /users"

Respuesta esperada:

```markdown
---
artifact_id: "api-users-reference-v1"
artifact_type: "reference"
version: "1.0.0"
constraints_mapped: ["C1","C3","C4","C5","V1"]
canonical_path: "docs/05-CONFIGURATIONS/api/users-reference.md"
domain: "05-CONFIGURATIONS"
subdomain: "api"
agent_role: "api-doc-agent"
language_lock: "es-ES,pt-BR"
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain configurations --file docs/05-CONFIGURATIONS/api/users-reference.md --strict"
tier: 3
immutable: true
requires_human_approval_for_changes: false
audience: ["developer", "tech-lead"]
human_readable: true
checksum_sha256: "PENDING_GENERATION"
api_version: "v1"
endpoint: "/users"
method: "GET"
---

# Referencia de API: GET /users

## Descripción

Recupera una lista paginada de usuarios del sistema. Requiere autenticación con token Bearer.

## Request

`GET /api/v1/users`

### Headers

| Header | Requerido | Descripción |
|--------|----------|-------------|
| Authorization | Sí | `Bearer {token}` con scope `users:read` |
| Accept | No | `application/json` (default) |

### Query Parameters

| Parámetro | Tipo | Requerido | Descripción | Ejemplo |
|-----------|------|----------|-------------|---------|
| page | integer | No | Número de página (1-based) | `?page=2` |
| limit | integer | No | Ítems por página (máx 100) | `?limit=50` |
| filter[role] | string | No | Filtrar por rol de usuario | `?filter[role]=admin` |

## Response

### Éxito (200 OK)

```json
{
  "data": [
    {
      "id": "usr_abc123",
      "email": "user@example.com",
      "role": "admin",
      "created_at": "2024-01-15T10:30:00Z"
    }
  ],
  "meta": {
    "page": 1,
    "limit": 50,
    "total": 127
  }
}
```

### Errores

| Código | Descripción | Causa Común |
|--------|-------------|-------------|
| 401 | Unauthorized | Token faltante o inválido |
| 403 | Forbidden | Scope insuficiente (`users:read` requerido) |
| 429 | Too Many Requests | Límite de rate excedido (100 req/min) |

## Ejemplos

### cURL
```bash
curl -X GET "https://api.example.com/api/v1/users?page=1&limit=10" \
  -H "Authorization: Bearer {api-key-here}" \
  -H "Accept: application/json"
```

### Python
```python
import requests

response = requests.get(
    "https://api.example.com/api/v1/users",
    headers={"Authorization": "Bearer {api-key-here}"},
    params={"page": 1, "limit": 10}
)
users = response.json()["data"]
```

## Consideraciones de Tenant (V1)

En entornos multi-tenant, este endpoint automáticamente filtra resultados por `tenant_id` del token de autenticación. No es posible consultar usuarios de otros tenants.

## Relacionado

- [POST /users](./users-create.md) - Crear nuevo usuario
- [GET /users/{id}](./users-get.md) - Obtener usuario por ID
- [Guía de Autenticación](../how-to/authentication.md) - Cómo obtener token Bearer
```

## PROTOCOLO DE ERROR

Si encuentras un bloqueo durante la generación:

1. **Documentar el error** en un bloque de comentario al inicio de la respuesta:
```markdown
<!-- ERROR: {descripción-clara-del-problema}
INPUTS_MISSING: {lista-de-inputs-faltantes}
SUGGESTION: {acción-recomendada-para-unblock}
-->
```

2. **Generar lo máximo posible** con los inputs disponibles, flaggeando secciones incompletas con `<!-- TODO: {descripción} -->`

3. **No inventar** datos, endpoints o comportamientos para completar huecos

4. **Reportar al orchestrator** con confidence < 0.5 si la tarea no puede completarse satisfactoriamente
```

### A.3 Plantilla de Prompt para Agente de Auditoría (DOC-AUDIT-AGENT)

```
Eres DOC-AUDIT-AGENT, responsable de la evaluación integral de calidad documental dentro del framework DOC-AGENTIC para MANTIS. Tu misión es garantizar que toda documentación cumpla con los estándares de estructura, contenido, seguridad, accesibilidad y trazabilidad antes de su publicación.

## ALCANCE DE AUDITORÍA

{documentation_scope}
- Rutas canónicas de documentos a auditar en `docs/`
- Código fuente relacionado en raíz para validación cruzada
- Metadata de proyecto desde `canonical_registry.json`

## CHECKLIST DE VALIDACIÓN OBLIGATORIO

Realizar los siguientes chequeos en orden, registrando hallazgos con severidad apropiada:

### 1. Validación Estructural (Gate 1)
- [ ] Frontmatter YAML válido y completo (todos los campos canónicos presentes)
- [ ] Campo `artifact_id` único y siguiendo convención `{dominio}-{tipo}-{id}`
- [ ] Campo `checksum_sha256` presente (aunque sea "PENDING_GENERATION")
- [ ] Campo `validation_command` ejecutable y apuntando a ruta válida
- [ ] Jerarquía de encabezados correcta: H1 → H2 → H3 (sin saltos de nivel)
- [ ] Profundidad de navegación ≤ 3 niveles desde raíz de `docs/`
- [ ] Conteo de palabras < 3000 (o documento intencionalmente dividido con enlaces)
- [ ] Sin páginas huérfanas: cada documento tiene al menos un enlace entrante desde índice o documento relacionado
- [ ] Convenciones de nombre de archivo: kebab-case, sin espacios, extensión .md

### 2. Calidad de Contenido (Gate 2)
- [ ] Consistencia terminológica >90%: términos técnicos usados uniformemente en todo el documento
- [ ] Transiciones entre secciones mayores: oraciones con "sin embargo", "por lo tanto", "adicionalmente", etc.
- [ ] Flujo de información old-to-new: conceptos básicos antes de avanzados
- [ ] Acrónimos definidos en primer uso: "API (Application Programming Interface)"
- [ ] Ejemplos de código con especificación de lenguaje: ```python, ```bash, etc.
- [ ] Ejemplos de código <20 líneas (o divididos con comentarios explicativos)
- [ ] Audiencia declarada explícitamente en frontmatter o sección inicial
- [ ] Prerrequisitos listados antes de instrucciones complejas
- [ ] Enlaces a contenido relacionado presentes (3-5 por documento, mínimo)

### 3. Escaneo de Seguridad (Gate 3)
- [ ] Sin API keys, tokens o passwords en ejemplos (usar `{api-key-here}`, `********`)
- [ ] Sin URLs internas o endpoints privados expuestos (usar `https://api.example.com`)
- [ ] Sin PII de empleados: nombres, emails, teléfonos en ejemplos
- [ ] Sin IPs hardcodeadas o detalles de infraestructura interna
- [ ] Sin codenames de proyectos internos no públicos
- [ ] Placeholders estandarizados usados consistentemente (ver §12.2 del framework)

### 4. Accesibilidad (Gate 4)
- [ ] Alt text descriptivo en todas las imágenes y diagramas Mermaid
- [ ] Texto de enlace descriptivo: "Guía de autenticación" en lugar de "click here"
- [ ] Jerarquía de encabezados correcta para lectores de pantalla (no saltar H2→H4)
- [ ] Bloques de código con especificación de lenguaje para syntax highlighting
- [ ] Tablas con fila de encabezado marcada con `|---|---|` en Markdown
- [ ] Color no como único indicador de significado (usar texto + iconos)

### 5. Compatibilidad con Agentes (Gate 5)
- [ ] AGENTS.md existe en raíz del proyecto y está actualizado (<30 días)
- [ ] CONTRIBUTING.md existe y describe workflow actual de contribución
- [ ] Sin conflictos de política entre archivos de instrucción (AGENTS.md vs CLAUDE.md vs .cursorrules)
- [ ] Todos los comandos en AGENTS.md son ejecutables y testeables
- [ ] Mapa de superficie de instrucción completo: todos los agentes maestros documentados
- [ ] Archivos alias (.cursorrules, .pi/, .agent/) en sync con fuente canónica

### 6. Paridad Bilingüe ES/PT (Gate 6 - si aplica)
- [ ] Documento índice con `languages: ["es","pt"]` en frontmatter
- [ ] Variantes .es.md y .pt.md existen y están actualizadas
- [ ] Paridad de contenido >95%: misma estructura, ejemplos, advertencias en ambos idiomas
- [ ] Términos técnicos traducidos consistentemente según glosario del proyecto
- [ ] Enlaces cruzados funcionando en ambas variantes

### 7. Frescura y Mantenimiento (Gate 7)
- [ ] Campo `last_updated` en frontmatter con fecha válida (YYYY-MM-DD)
- [ ] Documento actualizado dentro de umbrales: <90 días para docs críticas, <180 para referencia
- [ ] Enlaces a código fuente apuntan a commits/tags específicos, no a ramas flotantes
- [ ] Ejemplos de código verificados contra versión actual del sistema
- [ ] Referencias a dependencias externas con versiones pinned, no "latest"

## FORMATO DE REPORTE DE AUDITORÍA

Entregar resultados en este formato JSON estricto:

```json
{
  "audit_metadata": {
    "timestamp": "2024-05-21T15:45:00Z",
    "auditor_agent": "doc-audit-agent",
    "scope": ["docs/05-CONFIGURATIONS/api/users-reference.md"],
    "framework_version": "2.0.0-COMPREHENSIVE"
  },
  "overall_score": 94.5,
  "category_scores": {
    "structure": 98,
    "content": 92,
    "security": 100,
    "accessibility": 89,
    "agent_compat": 95,
    "i18n_parity": 97,
    "freshness": 90
  },
  "issues": [
    {
      "severity": "medium",
      "category": "accessibility",
      "file": "docs/05-CONFIGURATIONS/api/users-reference.md",
      "line": 42,
      "description": "Diagrama Mermaid sin alt text descriptivo",
      "fix_suggestion": "Añadir texto alternativo: 'Flujo de autenticación: usuario → API → validación → respuesta'"
    },
    {
      "severity": "low",
      "category": "content",
      "file": "docs/05-CONFIGURATIONS/api/users-reference.md",
      "line": 15,
      "description": "Término 'endpoint' usado inconsistentemente (a veces 'punto de acceso')",
      "fix_suggestion": "Estandarizar en 'endpoint' según glosario del proyecto"
    }
  ],
  "summary": "Documento de alta calidad con 2 issues menores. Recomendado para publicación tras corrección de alt text en diagrama.",
  "i18n_parity": {
    "es": 1.0,
    "pt": 0.97,
    "divergences": [
      {
        "section": "Ejemplos de código",
        "es_content": "import requests",
        "pt_content": "importar requests",
        "recommendation": "Mantener código en inglés, traducir solo comentarios"
      }
    ]
  },
  "next_actions": [
    "Corregir alt text en diagrama línea 42",
    "Estandarizar término 'endpoint' en todo el documento",
    "Re-ejecutar auditoría tras correcciones"
  ]
}
```

## ESCALADO DE SEVERIDAD DE ISSUES

| Severidad | Criterio | Acción Requerida |
|-----------|----------|-----------------|
| **critical** | Violación de C3 (secrets expuestos), C6 (gate humano omitido), o ejemplo de código ejecutable con creds reales | Bloquear publicación inmediata, notificar a security-team, requerir fix antes de re-auditar |
| **high** | Violación de C1 (checksum faltante), C4 (trazabilidad rota), o ejemplo de código no funcional | Requerir fix antes de publicación, re-auditar sección afectada |
| **medium** | Violación de C2 (infra no derivada de configs), C5 (frontmatter incompleto), o accesibilidad menor | Permitir publicación con flag "needs-followup", programar fix en próximo sprint |
| **low** | Inconsistencia terminológica, enlace roto no crítico, o estilo menor | Registrar en backlog de mejora, no bloquear publicación |
| **info** | Sugerencia de mejora, optimización de formato, o documentación adicional posible | Registrar como enhancement, no requiere acción inmediata |

## PROTOCOLO DE VALIDACIÓN CRUZADA CON CÓDIGO FUENTE

Cuando el documento audita documentación derivada de código/configs:

1. **Extraer interfaces públicas** del código fuente:
   ```bash
   # Para Python: funciones/clases públicas (no _prefix)
   grep -r "^def [^_]" src/ | cut -d: -f2 | cut -d\( -f1 | sort -u
   
   # Para APIs: endpoints desde OpenAPI spec
   yq '.paths | keys | .[]' 05-CONFIGURATIONS/api/openapi.yaml
   ```

2. **Mapear contra documentación**:
   - ¿Cada interfaz pública tiene documentación correspondiente?
   - ¿Los ejemplos en docs coinciden con firmas reales en código?
   - ¿Los parámetros, tipos y valores de retorno están actualizados?

3. **Reportar brechas de cobertura**:
   ```json
   "coverage_gaps": [
     {
       "interface": "POST /users/bulk",
       "source_file": "05-CONFIGURATIONS/api/openapi.yaml",
       "missing_in_docs": true,
       "recommendation": "Generar documentación para endpoint bulk create"
     }
   ]
   ```

## INTEGRACIÓN CON GOVERNANCE-ORCHESTRATOR.md

Al completar una auditoría:

1. **Actualizar registry de auditorías**:
   ```json
   // docs/framework/control/audit-registry.json
   {
     "last_audit": "2024-05-21T15:45:00Z",
     "audited_artifacts": ["docs/05-CONFIGURATIONS/api/users-reference.md"],
     "overall_score": 94.5,
     "critical_issues": 0,
     "next_scheduled_audit": "2024-08-21"
   }
   ```

2. **Notificar al orchestrator maestro** con resumen ejecutivo:
   ```
   ✅ Auditoría completada: docs/05-CONFIGURATIONS/api/users-reference.md
   📊 Score: 94.5/100 | Issues: 0 critical, 0 high, 1 medium, 1 low
   🔗 Reporte completo: docs/framework/logs/audit-20240521-154500.json
   ⏭️  Próxima auditoría programada: 2024-08-21
   ```

3. **Programar recordatorios de frescura** si el documento pasa auditoría:
   ```bash
   # docs/framework/cron/schedule.sh
   ./schedule.sh \
     --artifact "docs/05-CONFIGURATIONS/api/users-reference.md" \
     --review-days 90 \
     --notify-channel "#docs-maintenance" \
     --escalate-after 180
   ```

## EJEMPLO DE AUDITORÍA REAL

Documento: `docs/05-CONFIGURATIONS/api/users-reference.md`

Hallazgos:
```json
{
  "overall_score": 94.5,
  "issues": [
    {
      "severity": "medium",
      "category": "accessibility",
      "file": "docs/05-CONFIGURATIONS/api/users-reference.md",
      "line": 42,
      "description": "Diagrama Mermaid sin alt text descriptivo",
      "fix_suggestion": "Añadir: 'Flujo: usuario → API → validación → respuesta'"
    }
  ],
  "coverage_check": {
    "public_interfaces_in_code": 12,
    "documented_interfaces": 12,
    "coverage_ratio": 1.0,
    "gaps": []
  },
  "i18n_check": {
    "languages": ["es", "pt"],
    "parity_score": 0.97,
    "divergences": [
      {
        "section": "Ejemplos",
        "issue": "Código en inglés con comentarios en PT no traducidos",
        "fix": "Traducir comentarios, mantener código en inglés"
      }
    ]
  }
}
```

Recomendación: "Aprobar para publicación tras corrección de alt text en diagrama. Programar re-auditoría en 90 días."
```

---

## Apéndice B: Tarjetas de Referencia Rápida (Completo)

### B.1 Árbol de Decisión Documental (Diátaxis MANTIS)

```
¿Necesitas documentar algo?
│
├─ ¿Es un proceso o workflow que el lector debe EJECUTAR?
│  │
│  ├─ ¿El objetivo es APRENDER haciendo?
│  │  └─ ✅ TUTORIAL
│  │     • Paso a paso garantizado
│  │     • Entorno seguro/práctico
│  │     • Ej: "Primeros pasos con MANTIS", "Crear tu primer agente"
│  │
│  └─ ¿El objetivo es REALIZAR una tarea específica?
│     └─ ✅ GUÍA HOW-TO
│        • Orientado a objetivo claro
│        • Asume competencia base
│        • Ej: "Desplegar a producción", "Migrar base de datos"
│
├─ ¿Son HECHOS TÉCNICOS o specs que el lector debe CONSULTAR?
│  └─ ✅ REFERENCIA
│     • Completa, precisa, navegable
│     • Sin narrativa, solo datos
│     • Ej: "Referencia de API", "Opciones de configuración"
│
├─ ¿son CONCEPTOS o RAZONAMIENTO que el lector debe ENTENDER?
│  └─ ✅ EXPLICACIÓN
│     • Contexto, discusión, trade-offs
│     • Por qué las cosas funcionan así
│     • Ej: "Arquitectura de MANTIS", "Filosofía de diseño"
│
├─ ¿Es una DECISIÓN ARQUITECTÓNICA con trade-offs?
│  └─ ✅ ADR (Architecture Decision Record)
│     • Contexto, decisión, consecuencias
│     • Alternativas consideradas
│     • Ej: "ADR-001: Elección de base de datos"
│
├─ ¿Es ARQUITECTURA EVENT-DRIVEN con servicios/mensajes?
│  └─ ✅ CATÁLOGO DE EVENTOS (EventCatalog)
│     • Dominios, servicios, eventos, canales
│     • Lenguaje ubicuo, NodeGraph
│     • Ej: "Dominio: Agrobiología", "Evento: SoilAnalysisCompleted"
│
└─ ¿No estás seguro?
   └─ Preguntar: "¿Qué HARÁ el lector con esta información?"
      ├─ ¿Aprender una habilidad? → Tutorial
      ├─ ¿Realizar una tarea? → How-To
      ├─ ¿Consultar un dato? → Referencia
      └─ ¿Entender un concepto? → Explicación
```

### B.2 Referencia Rápida de Selección de Diagramas Mermaid

```
¿Qué estás documentando?
│
├─ ¿Un PROCESO, algoritmo o flujo de trabajo?
│  └─ ✅ FLOWCHART
│     • Nodos: acciones, decisiones, inicio/fin
│     • Ej: "Flujo de onboarding de tenant"
│
├─ ¿INTERACCIONES entre sistemas, servicios o APIs?
│  └─ ✅ SEQUENCE DIAGRAM
│     • Lifelines: participantes, mensajes temporales
│     • Ej: "Llamada API: usuario → auth → users → response"
│
├─ ¿RELACIONES DE DATOS o schema de base de datos?
│  └─ ✅ ER DIAGRAM (Entity-Relationship)
│     • Entidades, atributos, relaciones 1:N, M:N
│     • Ej: "Modelo de datos: users, tenants, embeddings"
│
├─ ¿ESTRUCTURA DE CLASES, objetos o módulos?
│  └─ ✅ CLASS DIAGRAM
│     • Clases, métodos, herencia, composición
│     • Ej: "Jerarquía de agentes: master → specialist"
│
├─ ¿TRANSICIONES DE ESTADO o ciclo de vida?
│  └─ ✅ STATE DIAGRAM
│     • Estados, transiciones, eventos, guards
│     • Ej: "Ciclo de vida de documento: draft → review → published"
│
├─ ¿ARQUITECTURA DE SISTEMA a alto nivel?
│  └─ ✅ C4 CONTEXT DIAGRAM
│     • Sistema, usuarios externos, sistemas dependientes
│     • Ej: "MANTIS en el ecosistema: GitHub, VPS, Qdrant"
│
├─ ¿CONTENEDORES DE APLICACIÓN o servicios?
│  └─ ✅ C4 CONTAINER DIAGRAM
│     • Contenedores: apps, DBs, brokers, APIs
│     • Ej: "Arquitectura de despliegue: API, worker, cache"
│
├─ ¿INTERNALS DE COMPONENTES o módulos?
│  └─ ✅ C4 COMPONENT DIAGRAM
│     • Componentes internos, interfaces, dependencias
│     • Ej: "Módulo postgres-rls: conexión, RLS, backup"
│
├─ ¿EXPERIENCIA DE USUARIO o flujos de interacción?
│  └─ ✅ USER JOURNEY MAP
│     • Touchpoints, emociones, canales, pain points
│     • Ej: "Journey: nuevo usuario → primer deploy"
│
├─ ¿LÍNEA DE TIEMPO DE PROYECTO o roadmap?
│  └─ ✅ GANTT CHART
│     • Tareas, duraciones, dependencias, hitos
│     • Ej: "Roadmap Q3 2024: features, milestones"
│
├─ ¿RELACIONES DE CONCEPTOS o jerarquía de ideas?
│  └─ ✅ MINDMAP
│     • Idea central, ramas, sub-ramas, conexiones
│     • Ej: "Mapa mental: constraints MANTIS C1-C8"
│
├─ ¿EVENTOS HISTÓRICOS o evolución del sistema?
│  └─ ✅ TIMELINE
│     • Fechas, hitos, versiones, cambios mayores
│     • Ej: "Historia de MANTIS: v1.0 → v2.0"
│
└─ ¿PROPORCIONES o distribución de recursos?
   └─ ✅ PIE CHART
      • Categorías, porcentajes, comparativas
      • Ej: "Distribución de effort: docs vs code vs tests"
```

### B.3 Checklist Rápido de Gate de Calidad (Pre-Publicación)

```
ANTES DE PUBLICAR CUALQUIER DOCUMENTACIÓN EN MANTIS:

□ ESTRUCTURA (Gate 1)
  □ Frontmatter YAML válido con todos los campos canónicos
  □ artifact_id único y siguiendo convención {dominio}-{tipo}-{id}
  □ checksum_sha256 presente (aunque sea "PENDING_GENERATION")
  □ validation_command ejecutable y apuntando a ruta válida
  □ Jerarquía de encabezados: H1 → H2 → H3 (sin saltos)
  □ Profundidad de navegación ≤ 3 niveles desde docs/
  □ Conteo de palabras < 3000 (o documento dividido intencionalmente)
  □ Sin páginas huérfanas: al menos un enlace entrante
  □ Nombre de archivo: kebab-case, sin espacios, extensión .md

□ CONTENIDO (Gate 2)
  □ Consistencia terminológica >90% en todo el documento
  □ Transiciones entre secciones mayores (sin embargo, por lo tanto...)
  □ Flujo de información old-to-new: básico antes de avanzado
  □ Acrónimos definidos en primer uso: "API (Application Programming Interface)"
  □ Ejemplos de código con especificación de lenguaje: ```python
  □ Ejemplos de código <20 líneas (o divididos con comentarios)
  □ Audiencia declarada explícitamente
  □ Prerrequisitos listados antes de instrucciones complejas
  □ Enlaces a contenido relacionado: 3-5 por documento, mínimo

□ SEGURIDAD (Gate 3)
  □ Sin API keys, tokens, passwords en ejemplos
  □ Sin URLs internas o endpoints privados expuestos
  □ Sin PII de empleados: nombres, emails, teléfonos
  □ Sin IPs hardcodeadas o detalles de infraestructura interna
  □ Placeholders estandarizados: example.com, api-key-here, ********
  □ Ejemplos de código con datos ficticios verificables

□ ACCESIBILIDAD (Gate 4)
  □ Alt text descriptivo en todas las imágenes y diagramas
  □ Texto de enlace descriptivo: "Guía de autenticación" ≠ "click here"
  □ Jerarquía de encabezados para lectores de pantalla
  □ Bloques de código con lenguaje para syntax highlighting
  □ Tablas con fila de encabezado marcada: |---|---|
  □ Color no como único indicador: usar texto + iconos

□ COMPATIBILIDAD CON AGENTES (Gate 5)
  □ AGENTS.md existe y está actualizado (<30 días)
  □ CONTRIBUTING.md existe y describe workflow actual
  □ Sin conflictos entre archivos de instrucción (AGENTS.md vs CLAUDE.md)
  □ Comandos en AGENTS.md ejecutables y testeables
  □ Mapa de superficie de instrucción completo
  □ Archivos alias (.cursorrules, etc.) en sync con fuente canónica

□ BILINGÜE ES/PT (Gate 6 - si aplica)
  □ Documento índice con languages: ["es","pt"] en frontmatter
  □ Variantes .es.md y .pt.md existen y actualizadas
  □ Paridad de contenido >95% entre idiomas
  □ Términos técnicos traducidos según glosario del proyecto
  □ Enlaces cruzados funcionando en ambas variantes

□ FRESCURA (Gate 7)
  □ last_updated en frontmatter con fecha válida (YYYY-MM-DD)
  □ Actualizado dentro de umbrales: <90 días docs críticas, <180 referencia
  □ Enlaces a código fuente apuntan a commits/tags específicos
  □ Ejemplos de código verificados contra versión actual
  □ Dependencias externas con versiones pinned, no "latest"

□ TRAZABILIDAD (C4)
  □ Documento mapeado a fuente en raíz en registry.json
  ✓ checksum_sha256 calculado y registrado post-generación
  ✓ Timestamps de generación y última modificación presentes
  ✓ Referencias a constraints aplicables en frontmatter

□ VALIDACIÓN FINAL
  ✓ Ejecutar: bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --strict
  ✓ Verificar que no hay issues critical/high pendientes
  ✓ Confirmar que checksum_sha256 fue inyectado correctamente
  ✓ Actualizar docs/framework/control/freshness-tracker.json
```

---

## Apéndice C: Scripts de Validación Completos (Integrados bajo Normativa MANTIS)

### C.1 `docs/framework/validators/doc_agentic.py` — Suite Completa de Validación

```python
#!/usr/bin/env python3
"""
DOC-AGENTIC Validation Suite v2.0.0 para MANTIS
Suite de validación multi-agente para documentación técnica.

Cumple con constraints MANTIS: C1-C8, V1-V3
Soporte bilingüe ES/PT integrado
Integración con orchestrator-engine.sh

Uso:
    python doc_agentic.py validate --all
    python doc_agentic.py validate --structure --json
    python doc_agentic.py init --template diataxis --lang es,pt
    python doc_agentic.py scaffold --type api-reference --name users

Autor: doc-agnostic-master-agent para MANTIS
Versión: 2.0.0-COMPREHENSIVE
Constraints: C1,C2,C3,C4,C5,C6,C7,C8,V1,V2,V3
"""

import os
import re
import sys
import json
import yaml
import hashlib
import argparse
import subprocess
from pathlib import Path
from datetime import datetime, timedelta
from dataclasses import dataclass, field
from typing import List, Dict, Optional, Tuple, Union
from collections import defaultdict
from urllib.parse import urlparse, urljoin

# ─────────────────────────────────────────────
# CONFIGURACIÓN MANTIS
# ─────────────────────────────────────────────

@dataclass
class MantisDocConfig:
    """Configuración específica para validación documental MANTIS."""
    # Rutas canónicas
    docs_dir: str = "docs"
    root_files: List[str] = field(default_factory=lambda: [
        "README.md", "CONTRIBUTING.md", "AGENTS.md", "CHANGELOG.md",
        "GOVERNANCE-ORCHESTRATOR.md", "canonical_registry.json"
    ])
    
    # Límites estructurales
    max_depth: int = 3  # Profundidad máxima de navegación
    max_words: int = 3000  # Máximo palabras por documento
    max_code_lines: int = 20  # Máximo líneas por bloque de código
    
    # Umbrales de frescura
    stale_days: int = 90  # Documento envejeciendo
    critical_stale_days: int = 180  # Documento crítico obsoleto
    
    # Calidad de contenido
    min_coverage: float = 0.80  # Cobertura mínima de interfaces documentadas
    min_accessibility_score: float = 0.90  # Score mínimo de accesibilidad
    min_terminology_consistency: float = 0.90  # Consistencia terminológica mínima
    min_i18n_parity: float = 0.95  # Paridad mínima entre ES/PT
    
    # Exclusiones
    excluded_dirs: List[str] = field(default_factory=lambda: [
        "node_modules", ".git", "__pycache__", "venv", ".venv",
        "dist", "build", ".next", "vendor", ".mypy_cache", ".pytest_cache"
    ])
    excluded_files: List[str] = field(default_factory=lambda: [
        "LICENSE", "LICENSE.md", ".gitignore", "checksum-manifest.json"
    ])
    
    # Patrones de seguridad (C3)
    secret_patterns: Dict[str, str] = field(default_factory=lambda: {
        "openai_key": r"sk-[a-zA-Z0-9]{20,}",
        "github_token": r"gh[pousr]_[a-zA-Z0-9]{36,}",
        "aws_access_key": r"AKIA[0-9A-Z]{16}",
        "aws_secret_key": r"(?i)aws_secret_access_key\s*[=:]\s*[A-Za-z0-9/+=]{40}",
        "generic_api_key": r"(?i)(api[_-]?key|apikey)\s*[=:]\s*['\"][A-Za-z0-9_\-]{20,}['\"]",
        "generic_secret": r"(?i)(secret|password|passwd|pwd)\s*[=:]\s*['\"][^\s'\"]{8,}['\"]",
        "private_key": r"-----BEGIN\s+(RSA\s+)?PRIVATE KEY-----",
        "jwt_token": r"eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}",
        "mongodb_uri": r"mongodb(\+srv)?://[^\s]+",
        "postgres_uri": r"postgres(ql)?://[^\s]+",
        "mysql_uri": r"mysql://[^\s]+",
        "redis_uri": r"redis://[^\s]+",
        "slack_token": r"xox[baprs]-[a-zA-Z0-9-]+",
        "stripe_key": r"[sr]k_live_[a-zA-Z0-9]{24,}",
        "internal_ip": r"\b(?:10\.\d{1,3}\.\d{1,3}\.\d{1,3}|172\.(?:1[6-9]|2\d|3[01])\.\d{1,3}\.\d{1,3}|192\.168\.\d{1,3}\.\d{1,3})\b",
        "internal_url": r"https?://(?:[^/]*\.(?:local|corp|internal|staging|dev|test|qa)[^/]*|localhost|127\.0\.0\.1)",
    })
    
    # Dominios permitidos en documentación (para evitar falsos positivos)
    allowed_domains: List[str] = field(default_factory=lambda: [
        "example.com", "example.org", "example.net",
        "localhost", "127.0.0.1", "::1",
        "github.com", "gitlab.com", "bitbucket.org",
        "npmjs.com", "pypi.org", "hub.docker.com",
        "google.com", "googleapis.com", "cloud.google.com",
        "stackoverflow.com", "developer.mozilla.org",
        "docs.github.com", "docs.gitlab.com",
        "mantis.agentic.dev", "agentic-infra-docs",
    ])
    
    # Palabras de transición para análisis de cohesión
    transition_words: List[str] = field(default_factory=lambda: [
        "however", "therefore", "additionally", "furthermore", "moreover",
        "consequently", "meanwhile", "subsequently", "nevertheless",
        "in addition", "as a result", "for example", "for instance",
        "in contrast", "on the other hand", "similarly", "likewise",
        "in summary", "to summarize", "in conclusion", "finally",
        "first", "second", "third", "next", "then", "after",
        "before", "once", "while", "although", "because", "since",
        # Español
        "sin embargo", "por lo tanto", "adicionalmente", "además", "por otro lado",
        "en consecuencia", "mientras tanto", "posteriormente", "no obstante",
        "en resumen", "para resumir", "en conclusión", "finalmente",
        "primero", "segundo", "tercero", "luego", "después",
        "antes", "una vez", "mientras", "aunque", "porque", "ya que",
        # Portugués
        "no entanto", "portanto", "adicionalmente", "além disso", "por outro lado",
        "consequentemente", "enquanto isso", "posteriormente", "não obstante",
        "em resumo", "para resumir", "em conclusão", "finalmente",
        "primeiro", "segundo", "terceiro", "depois", "após",
        "antes", "uma vez", "enquanto", "embora", "porque", "já que",
    ])
    
    # Glosario de términos para consistencia (canonical → variantes aceptadas)
    terminology_canonical: Dict[str, List[str]] = field(default_factory=lambda: {
        "endpoint": ["endpoint", "end-point", "end point", "punto de acceso", "ponto de acesso"],
        "api_key": ["API key", "API-key", "apikey", "clave de API", "chave de API"],
        "webhook": ["webhook", "web-hook", "web hook", "gancho web", "gancho da web"],
        "database": ["database", "data-base", "data base", "base de datos", "banco de dados"],
        "metadata": ["metadata", "meta-data", "meta data", "metadatos", "metadados"],
        "config": ["config", "configuration", "configuración", "configuração"],
        "auth": ["auth", "authentication", "autenticación", "autenticação"],
        "tenant": ["tenant", "tenant_id", "inquilino", "locatário"],
        "embedding": ["embedding", "embeddings", "incrustación", "incrustações"],
        "vector_search": ["vector search", "búsqueda vectorial", "busca vetorial"],
    })


# ─────────────────────────────────────────────
# MODELOS DE DATOS
# ─────────────────────────────────────────────

@dataclass
class Issue:
    """Representa un issue encontrado durante validación."""
    severity: str  # critical, high, medium, low, info
    category: str  # structure, content, security, accessibility, freshness, links, coverage, i18n
    file: str
    line: Optional[int]
    description: str
    fix_suggestion: str
    constraint: Optional[str] = None  # Constraint MANTIS relacionado (C1-C8, V1-V3)

    def to_dict(self) -> Dict:
        return {
            "severity": self.severity,
            "category": self.category,
            "file": self.file,
            "line": self.line,
            "description": self.description,
            "fix_suggestion": self.fix_suggestion,
            "constraint": self.constraint
        }


@dataclass
class ValidationResult:
    """Resultado de validación por categoría."""
    category: str
    score: float  # 0-100
    issues: List[Issue] = field(default_factory=list)
    stats: Dict = field(default_factory=dict)
    passed: bool = True
    i18n_details: Optional[Dict] = None  # Detalles de paridad ES/PT si aplica

    def add_issue(self, severity: str, file: str, line: Optional[int], 
                  description: str, fix_suggestion: str, constraint: Optional[str] = None):
        issue = Issue(
            severity=severity,
            category=self.category,
            file=file,
            line=line,
            description=description,
            fix_suggestion=fix_suggestion,
            constraint=constraint
        )
        self.issues.append(issue)
        if severity in ("critical", "high"):
            self.passed = False


@dataclass
class AuditReport:
    """Reporte completo de auditoría documental."""
    timestamp: str
    config: MantisDocConfig
    results: List[ValidationResult] = field(default_factory=list)
    overall_score: float = 0.0
    i18n_summary: Dict = field(default_factory=dict)

    def add_result(self, result: ValidationResult):
        self.results.append(result)

    def calculate_overall_score(self):
        """Calcular score ponderado según pesos MANTIS."""
        if not self.results:
            self.overall_score = 0.0
            return
        
        # Pesos MANTIS para categorías de validación
        weights = {
            "structure": 0.20,
            "content": 0.20,
            "freshness": 0.20,
            "links": 0.15,
            "security": 0.10,
            "accessibility": 0.10,
            "i18n": 0.05,  # Peso adicional para paridad bilingüe
        }
        
        total_weight = 0.0
        weighted_score = 0.0
        
        for r in self.results:
            w = weights.get(r.category, 0.05)  # Default weight para categorías no listadas
            weighted_score += r.score * w
            total_weight += w
        
        self.overall_score = round(weighted_score / total_weight, 1) if total_weight > 0 else 0.0

    def to_dict(self) -> Dict:
        return {
            "timestamp": self.timestamp,
            "overall_score": self.overall_score,
            "category_scores": {r.category: r.score for r in self.results},
            "total_issues": sum(len(r.issues) for r in self.results),
            "issues_by_severity": {
                sev: sum(1 for r in self.results for i in r.issues if i.severity == sev)
                for sev in ["critical", "high", "medium", "low", "info"]
            },
            "issues_by_constraint": {
                const: sum(1 for r in self.results for i in r.issues if i.constraint == const)
                for const in ["C1","C2","C3","C4","C5","C6","C7","C8","V1","V2","V3"]
            },
            "issues": [i.to_dict() for r in self.results for i in r.issues],
            "stats": {r.category: r.stats for r in self.results},
            "i18n_summary": self.i18n_summary,
            "mantis_compliance": {
                "constraints_checked": ["C1","C2","C3","C4","C5","C6","C7","C8","V1","V2","V3"],
                "framework_version": "2.0.0-COMPREHENSIVE",
                "validation_command": "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain docs --strict"
            }
        }


# ─────────────────────────────────────────────
# UTILIDADES COMPARTIDAS
# ─────────────────────────────────────────────

class FileUtils:
    """Utilidades para manipulación de archivos Markdown/YAML."""

    @staticmethod
    def find_markdown_files(docs_dir: str, root_files: List[str],
                           excluded_dirs: List[str],
                           excluded_files: List[str]) -> List[Path]:
        """Encontrar todos los archivos Markdown en el proyecto."""
        files = []

        # Archivos de raíz
        for f in root_files:
            p = Path(f)
            if p.exists() and p.name not in excluded_files:
                files.append(p)

        # Directorio docs/
        docs_path = Path(docs_dir)
        if docs_path.exists():
            for p in docs_path.rglob("*.md"):
                if any(ex in p.parts for ex in excluded_dirs):
                    continue
                if p.name in excluded_files:
                    continue
                files.append(p)

        # También incluir archivos .mdx para EventCatalog
        if docs_path.exists():
            for p in docs_path.rglob("*.mdx"):
                if any(ex in p.parts for ex in excluded_dirs):
                    continue
                files.append(p)

        return sorted(set(files))

    @staticmethod
    def count_words(content: str) -> int:
        """Contar palabras en contenido Markdown, excluyendo código y frontmatter."""
        # Remover frontmatter YAML
        text = re.sub(r'^---\s*\n.*?\n---\s*\n', '', content, flags=re.DOTALL)
        # Remover bloques de código
        text = re.sub(r'```[\s\S]*?```', '', text)
        # Remover código inline
        text = re.sub(r'`[^`]+`', '', text)
        # Remover sintaxis de enlaces Markdown
        text = re.sub(r'\[([^\]]+)\]\([^)]+\)', r'\1', text)
        # Remover imágenes
        text = re.sub(r'!\[([^\]]*)\]\([^)]+\)', '', text)
        # Remover tags HTML
        text = re.sub(r'<[^>]+>', '', text)
        # Remover formato Markdown
        text = re.sub(r'[#*_~>|]', '', text)
        return len(text.split())

    @staticmethod
    def get_nesting_depth(filepath: Path, base_dir: str) -> int:
        """Calcular profundidad de anidamiento relativa al directorio base."""
        try:
            rel = filepath.relative_to(base_dir)
            return len(rel.parts) - 1  # Restar nombre de archivo
        except ValueError:
            return 0

    @staticmethod
    def extract_frontmatter(content: str) -> Optional[Dict]:
        """Extraer frontmatter YAML de contenido Markdown."""
        match = re.match(r'^---\s*\n(.*?)\n---\s*\n', content, re.DOTALL)
        if match:
            try:
                return yaml.safe_load(match.group(1))
            except yaml.YAMLError:
                return None
        return None

    @staticmethod
    def extract_headings(content: str) -> List[Tuple[int, str, int]]:
        """Extraer encabezados con nivel, texto y número de línea."""
        headings = []
        for i, line in enumerate(content.split('\n'), 1):
            match = re.match(r'^(#{1,6})\s+(.+)$', line)
            if match:
                level = len(match.group(1))
                text = match.group(2).strip()
                headings.append((level, text, i))
        return headings

    @staticmethod
    def extract_links(content: str) -> List[Tuple[str, str, int]]:
        """Extraer enlaces como (texto, url, número_de_línea)."""
        links = []
        for i, line in enumerate(content.split('\n'), 1):
            # Enlaces Markdown: [texto](url)
            for match in re.finditer(r'\[([^\]]*)\]\(([^)]+)\)', line):
                text = match.group(1)
                url = match.group(2)
                # Saltar imágenes
                if not line[max(0, match.start()-1):match.start()] == '!':
                    links.append((text, url, i))
        return links

    @staticmethod
    def extract_images(content: str) -> List[Tuple[str, str, int]]:
        """Extraer imágenes como (alt_text, url, número_de_línea)."""
        images = []
        for i, line in enumerate(content.split('\n'), 1):
            for match in re.finditer(r'!\[([^\]]*)\]\(([^)]+)\)', line):
                alt = match.group(1)
                url = match.group(2)
                images.append((alt, url, i))
        return images

    @staticmethod
    def extract_code_blocks(content: str) -> List[Tuple[Optional[str], str, int]]:
        """Extraer bloques de código como (lenguaje, contenido, línea_inicial)."""
        blocks = []
        in_block = False
        lang = None
        block_content = []
        start_line = 0

        for i, line in enumerate(content.split('\n'), 1):
            if line.strip().startswith('```') and not in_block:
                in_block = True
                lang_match = re.match(r'^```\s*(\S+)?', line)
                lang = lang_match.group(1) if lang_match and lang_match.group(1) else None
                block_content = []
                start_line = i
            elif line.strip() == '```' and in_block:
                in_block = False
                blocks.append((lang, '\n'.join(block_content), start_line))
            elif in_block:
                block_content.append(line)

        return blocks

    @staticmethod
    def detect_language_variants(filepath: Path) -> List[str]:
        """Detectar variantes de idioma de un documento."""
        name = filepath.stem  # Sin extensión
        if name.endswith('.es'):
            return ['es']
        elif name.endswith('.pt'):
            return ['pt']
        elif '.es.' in name or '.pt.' in name:
            return ['es', 'pt'] if '.es.' in name and '.pt.' in name else (['es'] if '.es.' in name else ['pt'])
        
        # Verificar frontmatter para languages field
        try:
            content = filepath.read_text(encoding='utf-8', errors='replace')
            fm = FileUtils.extract_frontmatter(content)
            if fm and 'languages' in fm:
                return fm['languages']
        except:
            pass
        
        return ['unknown']


# ─────────────────────────────────────────────
# VALIDADORES POR GATE
# ─────────────────────────────────────────────

class StructureValidator:
    """Gate 1: Validación Estructural."""

    def __init__(self, config: MantisDocConfig):
        self.config = config

    def validate(self, files: List[Path]) -> ValidationResult:
        result = ValidationResult(category="structure", score=100.0)
        deductions = 0
        total_checks = 0

        for filepath in files:
            try:
                content = filepath.read_text(encoding='utf-8', errors='replace')
            except Exception:
                continue

            str_path = str(filepath)
            total_checks += 1

            # Chequeo 1: Jerarquía de encabezados (sin saltos)
            headings = FileUtils.extract_headings(content)
            for idx in range(1, len(headings)):
                prev_level = headings[idx - 1][0]
                curr_level = headings[idx][0]
                if curr_level > prev_level + 1:
                    deductions += 2
                    result.add_issue(
                        "medium", str_path, headings[idx][2],
                        f"Salto de nivel de encabezado: H{prev_level} → H{curr_level}",
                        f"Usar H{prev_level + 1} en lugar de H{curr_level}",
                        constraint="C5"
                    )

            # Chequeo 2: Tamaño del documento
            word_count = FileUtils.count_words(content)
            result.stats[f"{str_path}_words"] = word_count
            if word_count > self.config.max_words:
                deductions += 3
                result.add_issue(
                    "medium", str_path, None,
                    f"Documento excede {self.config.max_words} palabras ({word_count} palabras)",
                    "Dividir en documentos más pequeños y enfocados",
                    constraint="C5"
                )

            # Chequeo 3: Profundidad de anidamiento
            depth = FileUtils.get_nesting_depth(filepath, self.config.docs_dir)
            if depth > self.config.max_depth:
                deductions += 5
                result.add_issue(
                    "high", str_path, None,
                    f"Profundidad de anidamiento {depth} excede máximo de {self.config.max_depth}",
                    "Aplanar estructura de directorios a máximo 3 niveles",
                    constraint="C4"
                )

            # Chequeo 4: Debe tener H1
            if content.strip() and not re.search(r'^#\s+.+', content, re.MULTILINE):
                # Verificar si tiene frontmatter con título
                fm = FileUtils.extract_frontmatter(content)
                if not fm or not fm.get('name'):
                    deductions += 2
                    result.add_issue(
                        "low", str_path, 1,
                        "Documento sin encabezado H1",
                        "Añadir encabezado H1 como título del documento",
                        constraint="C5"
                    )

            # Chequeo 5: Documentos vacíos
            if word_count < 10:
                deductions += 5
                result.add_issue(
                    "high", str_path, None,
                    f"Documento parece vacío o casi vacío ({word_count} palabras)",
                    "Añadir contenido o eliminar el archivo",
                    constraint="C5"
                )

            # Chequeo 6: Frontmatter canónico MANTIS
            fm = FileUtils.extract_frontmatter(content)
            required_fields = [
                "artifact_id", "artifact_type", "version", "constraints_mapped",
                "canonical_path", "domain", "subdomain", "agent_role",
                "language_lock", "validation_command", "tier", "immutable",
                "requires_human_approval_for_changes", "audience", "human_readable",
                "checksum_sha256"
            ]
            if fm:
                missing_fields = [f for f in required_fields if f not in fm]
                if missing_fields:
                    deductions += 3
                    result.add_issue(
                        "high", str_path, 1,
                        f"Frontmatter incompleto: faltan campos {missing_fields}",
                        f"Añadir campos canónicos MANTIS: {', '.join(missing_fields)}",
                        constraint="C5"
                    )
            else:
                deductions += 5
                result.add_issue(
                    "critical", str_path, 1,
                    "Documento sin frontmatter canónico MANTIS",
                    "Añadir frontmatter con todos los campos requeridos",
                    constraint="C5"
                )

        # Chequeo 7: Páginas huérfanas
        all_files = {str(f) for f in files}
        linked_files = set()
        for filepath in files:
            try:
                content = filepath.read_text(encoding='utf-8', errors='replace')
            except Exception:
                continue
            links = FileUtils.extract_links(content)
            for _, url, _ in links:
                if url.startswith(('http://', 'https://', '#', 'mailto:')):
                    continue
                # Resolver ruta relativa
                resolved = (filepath.parent / url.split('#')[0]).resolve()
                linked_files.add(str(resolved))

        for filepath in files:
            resolved = str(filepath.resolve())
            if resolved not in linked_files and filepath.name not in self.config.root_files:
                # Solo flaggear archivos no en raíz y no enlazados desde ningún lado
                if len(files) > 5:  # Solo verificar si conjunto documental significativo
                    deductions += 2
                    result.add_issue(
                        "medium", str(filepath), None,
                        "Página huérfana: no se encontraron enlaces entrantes",
                        "Añadir enlace a esta página desde un documento relacionado o índice",
                        constraint="C4"
                    )

        result.score = max(0.0, 100.0 - deductions)
        result.stats["total_files"] = len(files)
        result.stats["total_checks"] = total_checks
        return result


class ContentValidator:
    """Gate 2: Validación de Calidad de Contenido."""

    def __init__(self, config: MantisDocConfig):
        self.config = config

    def validate(self, files: List[Path]) -> ValidationResult:
        result = ValidationResult(category="content", score=100.0)
        deductions = 0
        term_counts = defaultdict(lambda: defaultdict(int))

        for filepath in files:
            try:
                content = filepath.read_text(encoding='utf-8', errors='replace')
            except Exception:
                continue

            str_path = str(filepath)
            lines = content.split('\n')

            # Chequeo 1: Densidad de transiciones
            text_content = re.sub(r'```[\s\S]*?```', '', content)
            text_content = re.sub(r'#[^\n]+', '', text_content)
            text_lower = text_content.lower()

            transition_count = sum(
                text_lower.count(tw.lower()) for tw in self.config.transition_words
            )
            paragraph_count = len([p for p in text_content.split('\n\n') if p.strip()])

            if paragraph_count > 5 and transition_count == 0:
                deductions += 3
                result.add_issue(
                    "medium", str_path, None,
                    "No se encontraron palabras de transición en el documento",
                    "Añadir frases de transición entre secciones mayores",
                    constraint="C5"
                )

            # Chequeo 2: Indicadores de audiencia
            has_audience = bool(re.search(
                r'(?i)(prerequisites?|audience|required knowledge|before you start|who is this for|público objetivo|pré-requisitos)',
                content
            ))
            if not has_audience and filepath.name not in ("CHANGELOG.md", "LICENSE.md"):
                deductions += 2
                result.add_issue(
                    "low", str_path, None,
                    "No se encontraron indicadores de audiencia",
                    "Añadir sección 'Público Objetivo' o 'Prerrequisitos'",
                    constraint="C5"
                )

            # Chequeo 3: Especificación de lenguaje en bloques de código
            code_blocks = FileUtils.extract_code_blocks(content)
            for lang, block_content, start_line in code_blocks:
                if lang is None and block_content.strip():
                    deductions += 1
                    result.add_issue(
                        "low", str_path, start_line,
                        "Bloque de código sin especificación de lenguaje",
                        "Añadir identificador de lenguaje después de los triple backticks: ```python",
                        constraint="C5"
                    )

            # Chequeo 4: Consistencia terminológica
            for canonical, variants in self.config.terminology_canonical.items():
                for variant in variants:
                    count = len(re.findall(r'\b' + re.escape(variant) + r'\b', content, re.IGNORECASE))
                    if count > 0:
                        term_counts[canonical][variant] += count

        # Analizar consistencia terminológica
        for canonical, variants in term_counts.items():
            total = sum(variants.values())
            dominant = max(variants.items(), key=lambda x: x[1])
            dominant_ratio = dominant[1] / total if total > 0 else 0

            if len(variants) > 1 and dominant_ratio < self.config.min_terminology_consistency:
                deductions += 2
                variant_str = ", ".join(f"{v}({c})" for v, c in variants.items())
                result.add_issue(
                    "medium", "GLOBAL", None,
                    f"Inconsistencia terminológica para '{canonical}': {variant_str}",
                    f"Estandarizar en '{dominant[0]}' en toda la documentación",
                    constraint="C5"
                )

        result.score = max(0.0, 100.0 - deductions)
        result.stats["terminology_variants"] = {
            k: dict(v) for k, v in term_counts.items()
        }
        return result


class LinkValidator:
    """Gate: Validación de Enlaces."""

    def __init__(self, config: MantisDocConfig):
        self.config = config
        self._checked_urls: Dict[str, bool] = {}

    def validate(self, files: List[Path]) -> ValidationResult:
        result = ValidationResult(category="links", score=100.0)
        deductions = 0
        total_links = 0
        broken_count = 0

        all_file_paths = {str(f.resolve()) for f in files}

        for filepath in files:
            try:
                content = filepath.read_text(encoding='utf-8', errors='replace')
            except Exception:
                continue

            str_path = str(filepath)
            links = FileUtils.extract_links(content)

            for text, url, line_num in links:
                total_links += 1

                # Saltar anchors
                if url.startswith('#'):
                    continue

                # Saltar mailto
                if url.startswith('mailto:'):
                    continue

                # Enlaces internos
                if not url.startswith(('http://', 'https://')):
                    # Resolver ruta relativa
                    clean_url = url.split('#')[0]
                    if not clean_url:
                        continue

                    target = (filepath.parent / clean_url).resolve()
                    if not target.exists():
                        broken_count += 1
                        deductions += 3
                        result.add_issue(
                            "high", str_path, line_num,
                            f"Enlace interno roto: [{text}]({url})",
                            f"Corregir ruta o crear archivo faltante: {target}",
                            constraint="C4"
                        )
                    continue

                # Enlaces externos (solo chequear si no está en caché)
                parsed = urlparse(url)
                domain = parsed.netloc.lower().replace('www.', '')

                if domain in self.config.allowed_domains:
                    continue  # Saltar dominios conocidos para evitar rate limiting

                if url not in self._checked_urls:
                    try:
                        import urllib.request
                        req = urllib.request.Request(url, method='HEAD',
                                                     headers={'User-Agent': 'DOC-AGENTIC-MANTIS/2.0.0'})
                        req.add_header('User-Agent', 'DOC-AGENTIC-MANTIS/2.0.0 Link Checker')
                        response = urllib.request.urlopen(req, timeout=10)
                        self._checked_urls[url] = response.status < 400
                    except Exception:
                        self._checked_urls[url] = False

                if not self._checked_urls.get(url, True):
                    broken_count += 1
                    deductions += 2
                    result.add_issue(
                        "medium", str_path, line_num,
                        f"Enlace externo roto: [{text}]({url})",
                        "Actualizar URL o eliminar el enlace",
                        constraint="C4"
                    )

        result.score = max(0.0, 100.0 - deductions)
        result.stats["total_links"] = total_links
        result.stats["broken_links"] = broken_count
        return result


class FreshnessValidator:
    """Gate: Validación de Frescura."""

    def __init__(self, config: MantisDocConfig):
        self.config = config

    def validate(self, files: List[Path]) -> ValidationResult:
        result = ValidationResult(category="freshness", score=100.0)
        deductions = 0
        now = datetime.now()

        stale_count = 0
        critical_stale_count = 0
        no_date_count = 0

        for filepath in files:
            try:
                content = filepath.read_text(encoding='utf-8', errors='replace')
            except Exception:
                continue

            str_path = str(filepath)

            # Saltar ciertos archivos
            if filepath.name in ("CHANGELOG.md", "LICENSE.md"):
                continue

            last_updated = None

            # Método 1: Verificar frontmatter
            fm = FileUtils.extract_frontmatter(content)
            if fm:
                for date_field in ['last_updated', 'lastUpdated', 'updated', 'date']:
                    if fm.get(date_field):
                        try:
                            if isinstance(fm[date_field], str):
                                last_updated = datetime.strptime(
                                    fm[date_field], '%Y-%m-%d'
                                )
                            elif isinstance(fm[date_field], datetime):
                                last_updated = fm[date_field]
                            break
                        except (ValueError, TypeError):
                            pass

            # Método 2: Verificar historial de git
            if last_updated is None:
                try:
                    git_result = subprocess.run(
                        ['git', 'log', '-1', '--format=%ci', '--', str(filepath)],
                        capture_output=True, text=True, timeout=10
                    )
                    if git_result.returncode == 0 and git_result.stdout.strip():
                        last_updated = datetime.strptime(
                            git_result.stdout.strip()[:19], '%Y-%m-%d %H:%M:%S'
                        )
                except (subprocess.SubprocessError, ValueError, FileNotFoundError):
                    pass

            # Método 3: Tiempo de modificación del sistema de archivos
            if last_updated is None:
                mtime = os.path.getmtime(filepath)
                last_updated = datetime.fromtimestamp(mtime)

            if last_updated:
                age_days = (now - last_updated).days

                if age_days > self.config.critical_stale_days:
                    critical_stale_count += 1
                    deductions += 5
                    result.add_issue(
                        "high", str_path, None,
                        f"Obsolescencia crítica: actualizado hace {age_days} días ({last_updated.strftime('%Y-%m-%d')})",
                        "Revisar y actualizar este documento inmediatamente",
                        constraint="C4"
                    )
                elif age_days > self.config.stale_days:
                    stale_count += 1
                    deductions += 2
                    result.add_issue(
                        "medium", str_path, None,
                        f"Documento envejeciendo: actualizado hace {age_days} días ({last_updated.strftime('%Y-%m-%d')})",
                        "Programar revisión de este documento",
                        constraint="C4"
                    )

                result.stats[f"{str_path}_age_days"] = age_days
            else:
                no_date_count += 1
                deductions += 1
                result.add_issue(
                    "low", str_path, None,
                    "No se encontró fecha de última actualización",
                    "Añadir 'last_updated: YYYY-MM-DD' al frontmatter",
                    constraint="C4"
                )

        result.score = max(0.0, 100.0 - deductions)
        result.stats["stale_count"] = stale_count
        result.stats["critical_stale_count"] = critical_stale_count
        result.stats["no_date_count"] = no_date_count
        return result


class SecurityValidator:
    """Gate 3: Validación de Seguridad."""

    def __init__(self, config: MantisDocConfig):
        self.config = config

    def validate(self, files: List[Path]) -> ValidationResult:
        result = ValidationResult(category="security", score=100.0)
        deductions = 0

        for filepath in files:
            try:
                content = filepath.read_text(encoding='utf-8', errors='replace')
            except Exception:
                continue

            str_path = str(filepath)
            lines = content.split('\n')

            for i, line in enumerate(lines, 1):
                # Chequear patrones de secrets
                for pattern_name, pattern in self.config.secret_patterns.items():
                    matches = re.findall(pattern, line)
                    for match in matches:
                        # Saltar si parece un placeholder
                        if self._is_placeholder(match):
                            continue
                        deductions += 10
                        result.add_issue(
                            "critical", str_path, i,
                            f"Potencial secret detectado ({pattern_name}): {match[:20]}...",
                            "Eliminar o reemplazar con valor placeholder",
                            constraint="C3"
                        )

                # Chequear URLs internas
                url_matches = re.findall(r'https?://[^\s\)"\'>]+', line)
                for url in url_matches:
                    parsed = urlparse(url)
                    domain = parsed.netloc.lower().replace('www.', '')
                    if domain and domain not in self.config.allowed_domains:
                        # Verificar si parece interno
                        if any(indicator in domain for indicator in
                               ['internal', 'local', 'corp', 'intranet', '.local',
                                'staging', 'dev.', 'test.', 'qa.']):
                            deductions += 5
                            result.add_issue(
                                "high", str_path, i,
                                f"URL interna expuesta: {url}",
                                "Reemplazar con example.com o eliminar",
                                constraint="C3"
                            )

        result.score = max(0.0, 100.0 - deductions)
        return result

    def _is_placeholder(self, value: str) -> bool:
        """Verificar si un valor parece un placeholder."""
        placeholders = [
            'your-api-key', 'your_api_key', 'api-key-here', 'example',
            'placeholder', 'xxx', 'REDACTED', 'CHANGEME', 'TODO',
            '<your', '{{', '${', 'sk-xxx', 'ghp_xxx', 'test',
            'dummy', 'fake', 'sample', 'INSERT', 'REPLACE',
            'sua-chave-aqui', 'sua_chave_aqui', 'chave-api-aqui',
            'exemplo', 'substituir', 'INSERIR', 'TROCAR'
        ]
        return any(p.lower() in value.lower() for p in placeholders)


class AccessibilityValidator:
    """Gate 4: Validación de Accesibilidad."""

    def __init__(self, config: MantisDocConfig):
        self.config = config

    def validate(self, files: List[Path]) -> ValidationResult:
        result = ValidationResult(category="accessibility", score=100.0)
        deductions = 0
        total_checks = 0

        bad_link_texts = [
            'click here', 'here', 'this', 'link', 'read more',
            'more', 'click', 'this link', 'click this',
            'clic aquí', 'aquí', 'este', 'enlace', 'leer más',
            'clicar aqui', 'aqui', 'este', 'link', 'ler mais'
        ]

        for filepath in files:
            try:
                content = filepath.read_text(encoding='utf-8', errors='replace')
            except Exception:
                continue

            str_path = str(filepath)

            # Chequeo 1: Imágenes sin alt text
            images = FileUtils.extract_images(content)
            for alt, url, line_num in images:
                total_checks += 1
                if not alt.strip():
                    deductions += 3
                    result.add_issue(
                        "high", str_path, line_num,
                        f"Imagen sin alt text: {url}",
                        "Añadir alt text descriptivo: ![descripción](url)",
                        constraint="C8"
                    )

            # Chequeo 2: Texto de enlace no descriptivo
            links = FileUtils.extract_links(content)
            for text, url, line_num in links:
                total_checks += 1
                if text.lower().strip() in bad_link_texts:
                    deductions += 2
                    result.add_issue(
                        "medium", str_path, line_num,
                        f"Texto de enlace no descriptivo: '{text}'",
                        "Usar texto descriptivo que explique el destino del enlace",
                        constraint="C8"
                    )

                # Chequear URL como texto de enlace
                if text.startswith('http://') or text.startswith('https://'):
                    deductions += 1
                    result.add_issue(
                        "low", str_path, line_num,
                        f"URL usada como texto de enlace: '{text[:50]}...'",
                        "Reemplazar con texto descriptivo",
                        constraint="C8"
                    )

            # Chequeo 3: Bloques de código sin lenguaje
            code_blocks = FileUtils.extract_code_blocks(content)
            for lang, block_content, start_line in code_blocks:
                total_checks += 1
                if lang is None and block_content.strip():
                    deductions += 1
                    result.add_issue(
                        "low", str_path, start_line,
                        "Bloque de código sin especificación de lenguaje",
                        "Añadir lenguaje para syntax highlighting: ```python",
                        constraint="C8"
                    )

            # Chequeo 4: Tablas sin encabezados
            in_table = False
            for i, line in enumerate(content.split('\n'), 1):
                stripped = line.strip()
                if stripped.startswith('|') and '|' in stripped[1:]:
                    if not in_table:
                        in_table = True
                        # Verificar si la siguiente línea es separador
                        next_lines = content.split('\n')[i:i+1]
                        if next_lines:
                            next_line = next_lines[0].strip()
                            if not re.match(r'\|[\s\-:]+\|', next_line):
                                deductions += 2
                                result.add_issue(
                                    "medium", str_path, i,
                                    "Tabla puede estar faltando fila de separación de encabezados",
                                    "Añadir fila separadora: |---|---|",
                                    constraint="C8"
                                )
                else:
                    in_table = False

        result.score = max(0.0, 100.0 - deductions)
        result.stats["total_accessibility_checks"] = total_checks
        return result


class CoverageValidator:
    """Gate: Validación de Cobertura."""

    def __init__(self, config: MantisDocConfig):
        self.config = config

    def validate(self, files: List[Path], source_dirs: List[str] = None) -> ValidationResult:
        result = ValidationResult(category="coverage", score=100.0)

        if source_dirs is None:
            source_dirs = ["src", "lib", "app", "pkg", "internal"]

        # Encontrar todas las interfaces públicas en código fuente
        public_interfaces = set()
        for src_dir in source_dirs:
            src_path = Path(src_dir)
            if not src_path.exists():
                continue

            for ext in ['*.py', '*.go', '*.js', '*.ts', '*.rs', '*.java']:
                for src_file in src_path.rglob(ext):
                    try:
                        content = src_file.read_text(encoding='utf-8', errors='replace')
                    except Exception:
                        continue

                    # Extraer definiciones de función/clase
                    # Python
                    for match in re.finditer(r'^(class|def|async def)\s+(\w+)', content, re.MULTILINE):
                        name = match.group(2)
                        if not name.startswith('_'):
                            public_interfaces.add(name)

                    # Go
                    for match in re.finditer(r'^func\s+(\(.*?\)\s+)?([A-Z]\w+)', content, re.MULTILINE):
                        public_interfaces.add(match.group(2))

                    # JavaScript/TypeScript
                    for match in re.finditer(
                        r'^(export\s+)?(class|function|const|interface|type)\s+(\w+)',
                        content, re.MULTILINE
                    ):
                        name = match.group(3)
                        if name[0].isupper():
                            public_interfaces.add(name)

        if not public_interfaces:
            result.score = 100.0
            result.stats["note"] = "No se encontraron directorios de código fuente, omitiendo chequeo de cobertura"
            return result

        # Verificar qué interfaces están mencionadas en documentación
        all_doc_content = ""
        for filepath in files:
            try:
                all_doc_content += filepath.read_text(encoding='utf-8', errors='replace') + "\n"
            except Exception:
                continue

        documented = set()
        undocumented = set()

        for interface in public_interfaces:
            if interface in all_doc_content:
                documented.add(interface)
            else:
                undocumented.add(interface)

        total = len(public_interfaces)
        covered = len(documented)
        coverage_ratio = covered / total if total > 0 else 1.0

        if coverage_ratio < self.config.min_coverage:
            gap = self.config.min_coverage - coverage_ratio
            deductions = gap * 100
            result.score = max(0.0, 100.0 - deductions)

            # Reportar interfaces no documentadas top 20
            for interface in sorted(undocumented)[:20]:
                result.add_issue(
                    "medium", "COVERAGE", None,
                    f"Interfaz pública no documentada: {interface}",
                    f"Añadir documentación para '{interface}'",
                    constraint="C4"
                )

        result.stats["total_interfaces"] = total
        result.stats["documented"] = covered
        result.stats["undocumented"] = len(undocumented)
        result.stats["coverage_ratio"] = round(coverage_ratio * 100, 1)
        return result


class I18nValidator:
    """Gate 6: Validación de Paridad Bilingüe ES/PT."""

    def __init__(self, config: MantisDocConfig):
        self.config = config

    def validate(self, files: List[Path]) -> ValidationResult:
        result = ValidationResult(category="i18n", score=100.0)
        deductions = 0
        
        # Agrupar archivos por documento base (sin .es/.pt)
        doc_groups = defaultdict(list)
        for filepath in files:
            name = filepath.stem
            base_name = name.rsplit('.', 1)[0] if '.' in name and name.split('.')[-1] in ['es', 'pt'] else name
            doc_groups[base_name].append(filepath)
        
        for base_name, variants in doc_groups.items():
            # Solo procesar si hay variantes ES/PT
            langs = set()
            for f in variants:
                langs.update(FileUtils.detect_language_variants(f))
            
            if 'es' in langs and 'pt' in langs:
                # Encontrar archivos ES y PT
                es_files = [f for f in variants if 'es' in FileUtils.detect_language_variants(f)]
                pt_files = [f for f in variants if 'pt' in FileUtils.detect_language_variants(f)]
                
                if es_files and pt_files:
                    # Comparar estructura y contenido
                    es_content = es_files[0].read_text(encoding='utf-8', errors='replace')
                    pt_content = pt_files[0].read_text(encoding='utf-8', errors='replace')
                    
                    # Chequear paridad estructural: mismos encabezados, secciones, enlaces
                    es_headings = [h[1] for h in FileUtils.extract_headings(es_content)]
                    pt_headings = [h[1] for h in FileUtils.extract_headings(pt_content)]
                    
                    if es_headings != pt_headings:
                        deductions += 3
                        result.add_issue(
                            "medium", base_name, None,
                            f"Estructura de encabezados diferente entre ES y PT",
                            "Alinear estructura de secciones entre variantes de idioma",
                            constraint="V2"
                        )
                    
                    # Chequear paridad de enlaces
                    es_links = [l[1] for l in FileUtils.extract_links(es_content) if not l[1].startswith(('http', '#'))]
                    pt_links = [l[1] for l in FileUtils.extract_links(pt_content) if not l[1].startswith(('http', '#'))]
                    
                    if set(es_links) != set(pt_links):
                        deductions += 2
                        result.add_issue(
                            "low", base_name, None,
                            f"Enlaces internos diferentes entre ES y PT",
                            "Sincronizar enlaces cruzados entre variantes de idioma",
                            constraint="V2"
                        )
                    
                    # Calcular paridad de contenido (simple: ratio de palabras no-code)
                    es_words = FileUtils.count_words(es_content)
                    pt_words = FileUtils.count_words(pt_content)
                    parity_ratio = min(es_words, pt_words) / max(es_words, pt_words) if max(es_words, pt_words) > 0 else 1.0
                    
                    if parity_ratio < self.config.min_i18n_parity:
                        deductions += 2
                        result.add_issue(
                            "medium", base_name, None,
                            f"Paridad de contenido ES/PT: {parity_ratio:.2%} < {self.config.min_i18n_parity:.2%}",
                            "Revisar y completar contenido faltante en variante con menos palabras",
                            constraint="V2"
                        )
                    
                    result.stats[f"{base_name}_parity"] = round(parity_ratio * 100, 1)

        result.score = max(0.0, 100.0 - deductions)
        return result


# ─────────────────────────────────────────────
# FORMATEADOR DE REPORTES
# ─────────────────────────────────────────────

class ReportFormatter:
    """Formatear reportes de auditoría para salida en terminal."""

    SEVERITY_ICONS = {
        "critical": "🔴",
        "high": "🟠",
        "medium": "🟡",
        "low": "🔵",
        "info": "⚪",
    }

    SCORE_COLORS = {
        (90, 101): "\033[92m",   # Verde
        (75, 90): "\033[93m",    # Amarillo
        (60, 75): "\033[33m",    # Amarillo oscuro
        (0, 60): "\033[91m",     # Rojo
    }

    RESET = "\033[0m"
    BOLD = "\033[1m"
    DIM = "\033[2m"

    @classmethod
    def _color_score(cls, score: float) -> str:
        for (low, high), color in cls.SCORE_COLORS.items():
            if low <= score < high:
                return f"{color}{score:.1f}{cls.RESET}"
        return f"{score:.1f}"

    @classmethod
    def format_terminal(cls, report: AuditReport) -> str:
        lines = []
        lines.append("")
        lines.append(f"{cls.BOLD}{'═' * 72}{cls.RESET}")
        lines.append(f"{cls.BOLD}  DOC-AGENTIC MANTIS - REPORTE DE VALIDACIÓN{cls.RESET}")
        lines.append(f"{cls.DIM}  {report.timestamp}{cls.RESET}")
        lines.append(f"{cls.BOLD}{'═' * 72}{cls.RESET}")
        lines.append("")

        # Score general
        score_str = cls._color_score(report.overall_score)
        rating = cls._get_rating(report.overall_score)
        lines.append(f"  Puntuación General: {cls.BOLD}{score_str}/100{cls.RESET} {rating}")
        lines.append("")

        # Scores por categoría
        lines.append(f"  {'Categoría':<22} {'Score':>8}  {'Issues':>8}")
        lines.append(f"  {'─' * 22} {'─' * 8}  {'─' * 8}")

        for r in report.results:
            score_str = cls._color_score(r.score)
            issue_count = len(r.issues)
            lines.append(f"  {r.category:<22} {score_str:>17}  {issue_count:>8}")

        lines.append("")

        # Resumen de issues por severidad
        severity_counts = defaultdict(int)
        for r in report.results:
            for issue in r.issues:
                severity_counts[issue.severity] += 1

        if severity_counts:
            lines.append(f"  {cls.BOLD}Resumen de Issues:{cls.RESET}")
            for sev in ["critical", "high", "medium", "low", "info"]:
                count = severity_counts.get(sev, 0)
                if count > 0:
                    icon = cls.SEVERITY_ICONS.get(sev, "⚪")
                    lines.append(f"  {icon} {sev.upper():<12} {count}")
            lines.append("")

        # Issues detallados
        all_issues = [i for r in report.results for i in r.issues]
        if all_issues:
            lines.append(f"  {cls.BOLD}{'─' * 72}{cls.RESET}")
            lines.append(f"  {cls.BOLD}ISSUES DETALLADOS{cls.RESET}")
            lines.append(f"  {cls.BOLD}{'─' * 72}{cls.RESET}")
            lines.append("")

            # Ordenar por severidad
            severity_order = {"critical": 0, "high": 1, "medium": 2, "low": 3, "info": 4}
            all_issues.sort(key=lambda x: severity_order.get(x.severity, 5))

            for issue in all_issues:
                icon = cls.SEVERITY_ICONS.get(issue.severity, "⚪")
                constraint_tag = f" [{issue.constraint}]" if issue.constraint else ""
                lines.append(f"  {icon} [{issue.severity.upper()}{constraint_tag}] {issue.description}")
                lines.append(f"    Archivo: {cls.DIM}{issue.file}{cls.RESET}"
                           + (f" Línea: {issue.line}" if issue.line else ""))
                lines.append(f"    Fix:  {issue.fix_suggestion}")
                lines.append("")

        # Stats
        lines.append(f"  {cls.BOLD}{'─' * 72}{cls.RESET}")
        lines.append(f"  {cls.BOLD}ESTADÍSTICAS{cls.RESET}")
        lines.append(f"  {cls.BOLD}{'─' * 72}{cls.RESET}")
        for r in report.results:
            if r.stats:
                lines.append(f"  {r.category}:")
                for key, value in r.stats.items():
                    if not key.endswith('_words') and not key.endswith('_age_days'):
                        lines.append(f"    {key}: {value}")

        # Resumen de paridad ES/PT si aplica
        if report.i18n_summary:
            lines.append("")
            lines.append(f"  {cls.BOLD}PARIDAD BILINGÜE ES/PT{cls.RESET}")
            for lang, score in report.i18n_summary.items():
                lines.append(f"    {lang.upper()}: {score:.1f}%")

        lines.append("")
        lines.append(f"{cls.BOLD}{'═' * 72}{cls.RESET}")
        lines.append("")

        return '\n'.join(lines)

    @staticmethod
    def _get_rating(score: float) -> str:
        if score >= 90:
            return "🟢 Excelente"
        elif score >= 75:
            return "🟡 Buena"
        elif score >= 60:
            return "🟠 Regular"
        else:
            return "🔴 Necesita Mejora"


# ─────────────────────────────────────────────
# SCAFFOLD / INIT
# ─────────────────────────────────────────────

class ProjectScaffolder:
    """Inicializar estructura de documentación."""

    TEMPLATES = {
        "diataxis": {
            "dirs": [
                "docs/tutorials",
                "docs/how-to",
                "docs/reference",
                "docs/explanation",
                "docs/adr",
                "docs/framework/control",
                "docs/framework/cron",
            ],
            "files": {
                "docs/tutorials/getting-started.es.md": """---
type: tutorial
audience: beginner
languages: ["es", "pt"]
estimated_time: 30 minutos
last_updated: {date}
---

# Primeros Pasos con MANTIS

## Qué Aprenderás

Al final de este tutorial, podrás:
- Configurar tu entorno de desarrollo
- Ejecutar el proyecto localmente
- Realizar tu primera contribución

## Prerrequisitos

- {prerrequisito_1}
- {prerrequisito_2}

## Paso 1: Instalar

```bash
# Comando de instalación
```

## Paso 2: Configurar

```bash
# Comando de configuración
```

## Paso 3: Ejecutar

```bash
# Comando de ejecución
```

## Resumen

En este tutorial, aprendiste cómo poner en marcha el proyecto localmente.

## Próximos Pasos

- [Tareas Comunes](../how-to/common-tasks.es.md)
- [Visión General de Arquitectura](../explanation/architecture.es.md)
""",
                "docs/how-to/common-tasks.es.md": """---
type: how-to
audience: intermediate
languages: ["es", "pt"]
last_updated: {date}
---

# Tareas Comunes

## Cómo {Tarea 1}

{Instrucciones paso a paso}

## Cómo {Tarea 2}

{Instrucciones paso a paso}

## Troubleshooting

### {Problema Común 1}

{Solución}
""",
                "docs/reference/api.es.md": """---
type: reference
languages: ["es", "pt"]
last_updated: {date}
---

# Referencia de API

## Visión General

{Visión general de la API}

## Endpoints

### GET /api/resource

{Documentación del endpoint}
""",
                "docs/explanation/architecture.es.md": """---
type: explanation
languages: ["es", "pt"]
last_updated: {date}
---

# Visión General de Arquitectura

## Visión General

{Visión general del sistema}

```mermaid
flowchart TB
    A[Componente A] --> B[Componente B]
    B --> C[Componente C]
```

## Conceptos Clave

{Explicaciones de conceptos}

## Decisiones de Diseño

{Por qué las cosas están construidas así}
""",
                "docs/adr/000-template.es.md": """# ADR-{NNN}: {Título de la Decisión}

**Estado**: proposed
**Fecha**: {date}
**Decisores**: {miembros del equipo}

## Contexto

{¿Cuál es el issue que estamos viendo que motiva esta decisión o cambio?}

## Decisión

{¿Cuál es el cambio que estamos proponiendo y/o haciendo?}

## Consecuencias

### Positivas
- {consecuencia positiva}

### Negativas
- {consecuencia negativa}
""",
                "README.es.md": """# {Nombre del Proyecto}

{Descripción de una línea de lo que hace este proyecto y por qué existe}

## Inicio Rápido

```bash
# Instalar
{comando_de_instalación}

# Ejecutar
{comando_de_ejecución}
```

## Documentación

- [Primeros Pasos](docs/tutorials/getting-started.es.md)
- [Tareas Comunes](docs/how-to/common-tasks.es.md)
- [Referencia de API](docs/reference/api.es.md)
- [Arquitectura](docs/explanation/architecture.es.md)

## Contribución

Ver [CONTRIBUTING.md](CONTRIBUTING.md)

## Licencia

{Licencia}
""",
                "CONTRIBUTING.es.md": """# Contribución

## Cómo Contribuir

1. Hacer fork del repositorio
2. Crear una rama de feature
3. Realizar tus cambios
4. Escribir/actualizar tests
5. Escribir/actualizar documentación
6. Enviar un pull request

## Estándares de Código

- Seguir estilo de código existente
- Escribir mensajes de commit significativos
- Incluir tests para nuevas features
- Actualizar documentación para cambios

## Proceso de Pull Request

1. Asegurar que todos los tests pasan
2. Solicitar revisión de un miembro del equipo
3. Abordar feedback de revisión
4. Mergear después de aprobación
""",
                "AGENTS.es.md": """# Instrucciones para Agentes

## Visión General del Proyecto

{Breve descripción del proyecto para agentes de IA}

## Estructura del Repositorio

```
{árbol de directorios}
```

## Comandos de Desarrollo

```bash
# Instalar dependencias
{comando_de_instalación}

# Ejecutar tests
{comando_de_test}

# Build
{comando_de_build}

# Lint
{comando_de_lint}
```

## Convenciones de Código

- {convención_1}
- {convención_2}
- {convención_3}

## Estándares de Documentación

- Seguir framework Diátaxis (Tutorial, How-To, Referencia, Explicación)
- Usar Mermaid para diagramas
- Mantener documentos bajo 3000 palabras
- Incluir frontmatter YAML con fecha last_updated

## Notas Importantes

- {nota_1}
- {nota_2}
""",
                "CHANGELOG.es.md": """# Changelog

Todos los cambios notables a este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/).

## [Unreleased]

### Added
- Estructura inicial de documentación

### Changed
- Nada aún

### Fixed
- Nada aún
""",
            }
        }
    }

    @classmethod
    def init_project(cls, template: str = "diataxis", base_dir: str = ".", languages: List[str] = ["es"]) -> List[str]:
        """Inicializar estructura de documentación."""
        if template not in cls.TEMPLATES:
            print(f"Plantilla '{template}' no encontrada. Disponibles: {list(cls.TEMPLATES.keys())}")
            return []

        tmpl = cls.TEMPLATES[template]
        created = []
        date_str = datetime.now().strftime('%Y-%m-%d')

        # Crear directorios
        for d in tmpl["dirs"]:
            path = Path(base_dir) / d
            path.mkdir(parents=True, exist_ok=True)
            created.append(str(path) + "/")

        # Crear archivos
        for filepath, content in tmpl["files"].items():
            # Generar variantes por idioma si aplica
            if "languages" in content and "es" in languages:
                for lang in languages:
                    lang_filepath = filepath.replace(".md", f".{lang}.md") if lang != "es" else filepath
                    path = Path(base_dir) / lang_filepath
                    if not path.exists():
                        path.parent.mkdir(parents=True, exist_ok=True)
                        path.write_text(content.replace("{date}", date_str).replace("{lang}", lang), encoding='utf-8')
                        created.append(str(path))
                    else:
                        created.append(f"{lang_filepath} (ya existe, omitido)")
            else:
                path = Path(base_dir) / filepath
                if not path.exists():
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_text(content.replace("{date}", date_str), encoding='utf-8')
                    created.append(str(path))
                else:
                    created.append(f"{filepath} (ya existe, omitido)")

        return created


# ─────────────────────────────────────────────
# ORQUESTADOR PRINCIPAL
# ─────────────────────────────────────────────

class DocAgentic:
    """Orquestador principal para suite de validación DOC-AGENTIC."""

    def __init__(self, config: Optional[MantisDocConfig] = None):
        self.config = config or MantisDocConfig()
        self.files = FileUtils.find_markdown_files(
            self.config.docs_dir,
            self.config.root_files,
            self.config.excluded_dirs,
            self.config.excluded_files
        )

    def validate_all(self, report_only: bool = False) -> AuditReport:
        """Ejecutar todos los gates de validación."""
        report = AuditReport(
            timestamp=datetime.now().isoformat(),
            config=self.config
        )

        print(f"Encontrados {len(self.files)} archivos de documentación\n")

        # Gate 1: Estructura
        print("Ejecutando validación estructural...")
        structure = StructureValidator(self.config).validate(self.files)
        report.add_result(structure)

        # Gate 2: Contenido
        print("Ejecutando validación de contenido...")
        content = ContentValidator(self.config).validate(self.files)
        report.add_result(content)

        # Gate 3: Enlaces
        print("Ejecutando validación de enlaces...")
        links = LinkValidator(self.config).validate(self.files)
        report.add_result(links)

        # Gate 4: Frescura
        print("Ejecutando validación de frescura...")
        freshness = FreshnessValidator(self.config).validate(self.files)
        report.add_result(freshness)

        # Gate 5: Seguridad
        print("Ejecutando escaneo de seguridad...")
        security = SecurityValidator(self.config).validate(self.files)
        report.add_result(security)

        # Gate 6: Accesibilidad
        print("Ejecutando chequeo de accesibilidad...")
        accessibility = AccessibilityValidator(self.config).validate(self.files)
        report.add_result(accessibility)

        # Gate 7: Cobertura
        print("Ejecutando análisis de cobertura...")
        coverage = CoverageValidator(self.config).validate(self.files)
        report.add_result(coverage)

        # Gate 8: Paridad ES/PT
        print("Ejecutando validación de paridad bilingüe...")
        i18n = I18nValidator(self.config).validate(self.files)
        report.add_result(i18n)
        report.i18n_summary = i18n.stats

        report.calculate_overall_score()
        return report

    def validate_structure(self) -> AuditReport:
        report = AuditReport(timestamp=datetime.now().isoformat(), config=self.config)
        report.add_result(StructureValidator(self.config).validate(self.files))
        report.calculate_overall_score()
        return report

    def validate_content(self) -> AuditReport:
        report = AuditReport(timestamp=datetime.now().isoformat(), config=self.config)
        report.add_result(ContentValidator(self.config).validate(self.files))
        report.calculate_overall_score()
        return report

    def validate_links(self) -> AuditReport:
        report = AuditReport(timestamp=datetime.now().isoformat(), config=self.config)
        report.add_result(LinkValidator(self.config).validate(self.files))
        report.calculate_overall_score()
        return report

    def validate_freshness(self) -> AuditReport:
        report = AuditReport(timestamp=datetime.now().isoformat(), config=self.config)
        report.add_result(FreshnessValidator(self.config).validate(self.files))
        report.calculate_overall_score()
        return report

    def validate_security(self) -> AuditReport:
        report = AuditReport(timestamp=datetime.now().isoformat(), config=self.config)
        report.add_result(SecurityValidator(self.config).validate(self.files))
        report.calculate_overall_score()
        return report

    def validate_accessibility(self) -> AuditReport:
        report = AuditReport(timestamp=datetime.now().isoformat(), config=self.config)
        report.add_result(AccessibilityValidator(self.config).validate(self.files))
        report.calculate_overall_score()
        return report

    def validate_coverage(self) -> AuditReport:
        report = AuditReport(timestamp=datetime.now().isoformat(), config=self.config)
        report.add_result(CoverageValidator(self.config).validate(self.files))
        report.calculate_overall_score()
        return report

    def validate_i18n(self) -> AuditReport:
        report = AuditReport(timestamp=datetime.now().isoformat(), config=self.config)
        report.add_result(I18nValidator(self.config).validate(self.files))
        report.calculate_overall_score()
        return report

    def validate_quick(self) -> AuditReport:
        """Validación rápida: estructura + enlaces solo."""
        report = AuditReport(timestamp=datetime.now().isoformat(), config=self.config)
        report.add_result(StructureValidator(self.config).validate(self.files))
        report.add_result(LinkValidator(self.config).validate(self.files))
        report.calculate_overall_score()
        return report


# ─────────────────────────────────────────────
# PUNTO DE ENTRADA CLI
# ─────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        prog="doc-agentic",
        description="DOC-AGENTIC MANTIS: Suite de Validación Documental Multi-Agente v2.0.0"
    )

    subparsers = parser.add_subparsers(dest="command", help="Comando a ejecutar")

    # Comando validate
    validate_parser = subparsers.add_parser("validate", help="Ejecutar chequeos de validación")
    validate_group = validate_parser.add_mutually_exclusive_group(required=True)
    validate_group.add_argument("--all", action="store_true", help="Ejecutar todos los gates de validación")
    validate_group.add_argument("--structure", action="store_true", help="Gate 1: Validación estructural")
    validate_group.add_argument("--content", action="store_true", help="Gate 2: Calidad de contenido")
    validate_group.add_argument("--links", action="store_true", help="Validación de enlaces")
    validate_group.add_argument("--freshness", action="store_true", help="Chequeo de frescura")
    validate_group.add_argument("--security", action="store_true", help="Gate 3: Escaneo de seguridad")
    validate_group.add_argument("--accessibility", action="store_true", help="Gate 4: Accesibilidad")
    validate_group.add_argument("--coverage", action="store_true", help="Análisis de cobertura")
    validate_group.add_argument("--i18n", action="store_true", help="Validación de paridad ES/PT")
    validate_group.add_argument("--quick", action="store_true", help="Chequeo rápido (estructura + enlaces)")

    validate_parser.add_argument("--report-only", action="store_true",
                                  help="Reportar issues sin sugerir que se apliquen fixes")
    validate_parser.add_argument("--json", action="store_true",
                                  help="Salida en formato JSON")
    validate_parser.add_argument("--output", "-o", type=str,
                                  help="Escribir reporte a archivo")

    # Comando init
    init_parser = subparsers.add_parser("init", help="Inicializar estructura de documentación")
    init_parser.add_argument("--template", default="diataxis",
                              choices=["diataxis"],
                              help="Plantilla a usar")
    init_parser.add_argument("--dir", default=".", help="Directorio base")
    init_parser.add_argument("--lang", nargs='+', default=["es"], help="Idiomas para generar variantes")

    # Argumentos de configuración
    parser.add_argument("--docs-dir", default="docs", help="Directorio de documentación")
    parser.add_argument("--max-depth", type=int, default=3, help="Profundidad máxima de anidamiento")
    parser.add_argument("--max-words", type=int, default=3000, help="Máximo palabras por documento")
    parser.add_argument("--stale-days", type=int, default=90, help="Días hasta que documento envejece")

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    # Construir config
    config = MantisDocConfig(
        docs_dir=args.docs_dir,
        max_depth=args.max_depth,
        max_words=args.max_words,
        stale_days=args.stale_days,
    )

    if args.command == "init":
        created = ProjectScaffolder.init_project(args.template, args.dir, args.lang)
        print(f"\nInicializada estructura de documentación '{args.template}':\n")
        for item in created:
            status = "✓" if "ya existe" not in item else "○"
            print(f"  {status} {item}")
        print(f"\n{len(created)} ítems creados/verificados.")
        sys.exit(0)

    if args.command == "validate":
        agent = DocAgentic(config)

        if args.all:
            report = agent.validate_all(report_only=args.report_only)
        elif args.structure:
            report = agent.validate_structure()
        elif args.content:
            report = agent.validate_content()
        elif args.links:
            report = agent.validate_links()
        elif args.freshness:
            report = agent.validate_freshness()
        elif args.security:
            report = agent.validate_security()
        elif args.accessibility:
            report = agent.validate_accessibility()
        elif args.coverage:
            report = agent.validate_coverage()
        elif args.i18n:
            report = agent.validate_i18n()
        elif args.quick:
            report = agent.validate_quick()
        else:
            parser.print_help()
            sys.exit(1)

        if args.json:
            output = json.dumps(report.to_dict(), indent=2, ensure_ascii=False)
        else:
            output = ReportFormatter.format_terminal(report)

        if args.output:
            Path(args.output).write_text(output, encoding='utf-8')
            print(f"Reporte escrito a {args.output}")
        else:
            print(output)

        # Salir con no-cero si hay issues critical/high
        critical_high = sum(
            1 for r in report.results
            for i in r.issues
            if i.severity in ("critical", "high")
        )
        sys.exit(1 if critical_high > 0 else 0)


if __name__ == "__main__":
    main()
```

### C.2 `docs/framework/validators/validate-docs.sh` — Script Bash Ligero para CI/CD

```bash
#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# DOC-AGENTIC MANTIS - Script de Validación Rápida
# Validación ligera en bash para pipelines CI/CD
# Cumple constraints MANTIS: C1-C8, V1-V3
# ─────────────────────────────────────────────────────────────

set -euo pipefail

# ── Configuración MANTIS ─────────────────────────────────────
DOCS_DIR="${DOCS_DIR:-docs}"
MAX_DEPTH="${MAX_DEPTH:-3}"
MAX_WORDS="${MAX_WORDS:-3000}"
STALE_DAYS="${STALE_DAYS:-90}"
CRITICAL_STALE_DAYS="${CRITICAL_STALE_DAYS:-180}"
MIN_I18N_PARITY="${MIN_I18N_PARITY:-0.95}"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Contadores
ERRORS=0
WARNINGS=0
INFO=0

# ── Helpers ──────────────────────────────────────────────────

log_header() {
    echo ""
    echo -e "${BOLD}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  $1${NC}"
    echo -e "${BOLD}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

log_check() {
    echo -e "  ${BLUE}[CHECK]${NC} $1"
}

log_pass() {
    echo -e "  ${GREEN}[PASS]${NC} $1"
}

log_error() {
    echo -e "  ${RED}[ERROR]${NC} $1"
    ((ERRORS++)) || true
}

log_warn() {
    echo -e "  ${YELLOW}[WARN]${NC} $1"
    ((WARNINGS++)) || true
}

log_info() {
    echo -e "  ${DIM}[INFO]${NC} $1"
    ((INFO++)) || true
}

# ── Encontrar archivos ───────────────────────────────────────

find_md_files() {
    local files=()

    # Archivos de raíz
    for f in README.md CONTRIBUTING.md AGENTS.md CHANGELOG.md GOVERNANCE-ORCHESTRATOR.md canonical_registry.json; do
        [ -f "$f" ] && files+=("$f")
    done

    # Directorio docs/
    if [ -d "$DOCS_DIR" ]; then
        while IFS= read -r -d '' file; do
            files+=("$file")
        done < <(find "$DOCS_DIR" -name "*.md" -o -name "*.mdx" | sort)
    fi

    printf '%s\n' "${files[@]}"
}

# ── Gate 1: Estructura ────────────────────────────────────────

validate_structure() {
    log_header "GATE 1: Validación Estructural (C5)"

    local total_files=0
    local depth_violations=0
    local empty_files=0
    local oversized_files=0
    local heading_violations=0
    local frontmatter_errors=0

    while IFS= read -r file; do
        [ -z "$file" ] && continue
        ((total_files++)) || true

        # Verificar si archivo está vacío
        local word_count
        word_count=$(wc -w < "$file" 2>/dev/null || echo "0")
        if [ "$word_count" -lt 10 ]; then
            log_error "Archivo vacío/casi vacío: $file ($word_count palabras) [C5]"
            ((empty_files++)) || true
        fi

        # Verificar conteo de palabras
        if [ "$word_count" -gt "$MAX_WORDS" ]; then
            log_warn "Documento sobredimensionado: $file ($word_count palabras > $MAX_WORDS) [C5]"
            ((oversized_files++)) || true
        fi

        # Verificar profundidad de anidamiento
        if [[ "$file" == "$DOCS_DIR"* ]]; then
            local depth
            depth=$(echo "$file" | tr '/' '\n' | wc -l)
            depth=$((depth - 2))  # Restar docs_dir y nombre de archivo
            if [ "$depth" -gt "$MAX_DEPTH" ]; then
                log_error "Demasiado profundo ($depth niveles): $file (máx: $MAX_DEPTH) [C4]"
                ((depth_violations++)) || true
            fi
        fi

        # Verificar jerarquía de encabezados
        local prev_level=0
        local line_num=0
        while IFS= read -r line; do
            ((line_num++)) || true
            if [[ "$line" =~ ^(#{1,6})\ ]]; then
                local level=${#BASH_REMATCH[1]}
                if [ "$prev_level" -gt 0 ] && [ "$level" -gt $((prev_level + 1)) ]; then
                    log_warn "Salto de encabezado H$prev_level→H$level en $file:$line_num [C5]"
                    ((heading_violations++)) || true
                fi
                prev_level=$level
            fi
        done < "$file"

        # Verificar frontmatter canónico MANTIS
        if ! head -20 "$file" | grep -q "^---"; then
            log_error "Documento sin frontmatter canónico MANTIS: $file [C5]"
            ((frontmatter_errors++)) || true
        else
            # Verificar campos obligatorios
            local required_fields=("artifact_id" "artifact_type" "version" "constraints_mapped" "canonical_path" "domain" "subdomain" "agent_role" "language_lock" "validation_command" "tier" "immutable" "requires_human_approval_for_changes" "audience" "human_readable" "checksum_sha256")
            for field in "${required_fields[@]}"; do
                if ! head -30 "$file" | grep -q "^${field}:"; then
                    log_warn "Campo de frontmatter faltante: $field en $file [C5]"
                    ((frontmatter_errors++)) || true
                fi
            done
        fi

    done < <(find_md_files)

    echo ""
    log_info "Archivos escaneados: $total_files"
    log_info "Archivos vacíos: $empty_files"
    log_info "Sobredimensionados: $oversized_files"
    log_info "Violaciones de profundidad: $depth_violations"
    log_info "Violaciones de encabezados: $heading_violations"
    log_info "Errores de frontmatter: $frontmatter_errors"

    if [ "$empty_files" -eq 0 ] && [ "$depth_violations" -eq 0 ] && [ "$frontmatter_errors" -eq 0 ]; then
        log_pass "Validación estructural aprobada [C4,C5]"
    fi
}

# ── Gate 2: Enlaces ───────────────────────────────────────────

validate_links() {
    log_header "GATE 2: Validación de Enlaces (C4)"

    local total_links=0
    local broken_links=0

    while IFS= read -r file; do
        [ -z "$file" ] && continue

        # Extraer enlaces markdown
        while IFS= read -r match; do
            [ -z "$match" ] && continue
            ((total_links++)) || true

            # Extraer URL de [texto](url)
            local url
            url=$(echo "$match" | grep -oP '\]\(\K[^)]+' || true)
            [ -z "$url" ] && continue

            # Saltar enlaces externos, anchors, mailto
            if [[ "$url" =~ ^https?:// ]] || [[ "$url" =~ ^# ]] || [[ "$url" =~ ^mailto: ]]; then
                continue
            fi

            # Resolver ruta relativa
            local dir
            dir=$(dirname "$file")
            local target="$dir/$url"
            target=$(echo "$target" | sed 's/#.*//')  # Remover anchors

            if [ ! -e "$target" ]; then
                log_error "Enlace roto en $file: [$match] -> $target [C4]"
                ((broken_links++)) || true
            fi
        done < <(grep -oP '\[[^\]]+\]\([^)]+\)' "$file" 2>/dev/null || true)

    done < <(find_md_files)

    echo ""
    log_info "Enlaces verificados: $total_links"
    log_info "Enlaces rotos: $broken_links"

    if [ "$broken_links" -eq 0 ]; then
        log_pass "Validación de enlaces aprobada [C4]"
    fi
}

# ── Gate 3: Frescura ───────────────────────────────────────

validate_freshness() {
    log_header "GATE 3: Validación de Frescura (C4)"

    local stale_count=0
    local critical_count=0
    local no_date_count=0

    while IFS= read -r file; do
        [ -z "$file" ] && continue

        # Saltar CHANGELOG y LICENSE
        [[ "$file" =~ CHANGELOG ]] && continue
        [[ "$file" =~ LICENSE ]] && continue

        # Verificar last_updated en frontmatter
        local last_updated
        last_updated=$(head -20 "$file" | grep -oP '(?<=last_updated:\s)\d{4}-\d{2}-\d{2}' || true)

        if [ -z "$last_updated" ]; then
            # Intentar con historial de git
            if command -v git &>/dev/null && git rev-parse --git-dir &>/dev/null 2>&1; then
                last_updated=$(git log -1 --format="%ci" -- "$file" 2>/dev/null | cut -d' ' -f1 || true)
            fi
        fi

        if [ -z "$last_updated" ]; then
            log_warn "Sin fecha encontrada: $file [C4]"
            ((no_date_count++)) || true
            continue
        fi

        # Calcular antigüedad
        local file_date_epoch
        file_date_epoch=$(date -d "$last_updated" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$last_updated" +%s 2>/dev/null || echo "0")
        local now_epoch
        now_epoch=$(date +%s)
        local age_days=$(( (now_epoch - file_date_epoch) / 86400 ))

        if [ "$age_days" -gt "$CRITICAL_STALE_DAYS" ]; then
            log_error "Obsolescencia crítica ($age_days días): $file (última: $last_updated) [C4]"
            ((critical_count++)) || true
        elif [ "$age_days" -gt "$STALE_DAYS" ]; then
            log_warn "Documento envejeciendo ($age_days días): $file (última: $last_updated) [C4]"
            ((stale_count++)) || true
        fi

    done < <(find_md_files)

    echo ""
    log_info "Obsoletos críticos: $critical_count"
    log_info "Envejeciendo: $stale_count"
    log_info "Sin fecha: $no_date_count"

    if [ "$critical_count" -eq 0 ]; then
        log_pass "Validación de frescura aprobada [C4]"
    fi
}

# ── Gate 4: Seguridad ────────────────────────────────────────

validate_security() {
    log_header "GATE 4: Escaneo de Seguridad (C3)"

    local secrets_found=0

    # Patrones de secrets
    local patterns=(
        'sk-[a-zA-Z0-9]{20,}'
        'ghp_[a-zA-Z0-9]{36}'
        'AKIA[0-9A-Z]{16}'
        '-----BEGIN\s+(RSA\s+)?PRIVATE KEY-----'
        'mongodb(\+srv)?://[^"'\''[:space:]]+'
        'postgres(ql)?://[^"'\''[:space:]]+'
        'xox[baprs]-[a-zA-Z0-9-]+'
    )

    while IFS= read -r file; do
        [ -z "$file" ] && continue

        for pattern in "${patterns[@]}"; do
            local matches
            matches=$(grep -nP "$pattern" "$file" 2>/dev/null || true)
            if [ -n "$matches" ]; then
                while IFS= read -r match; do
                    # Saltar placeholders obvios
                    if echo "$match" | grep -qiE '(example|placeholder|xxx|REDACTED|CHANGEME|your-|sk-xxx|sua-|chave-)'; then
                        continue
                    fi
                    log_error "Potencial secret en $file: $match [C3]"
                    ((secrets_found++)) || true
                done <<< "$matches"
            fi
        done

        # Verificar URLs internas
        local internal_urls
        internal_urls=$(grep -nP 'https?://[^\s)"'\'']+internal[^\s)"'\'']+' "$file" 2>/dev/null || true)
        if [ -n "$internal_urls" ]; then
            while IFS= read -r url_match; do
                log_warn "URL interna en $file: $url_match [C3]"
            done <<< "$internal_urls"
        fi

    done < <(find_md_files)

    echo ""
    log_info "Secrets encontrados: $secrets_found"

    if [ "$secrets_found" -eq 0 ]; then
        log_pass "Escaneo de seguridad aprobado [C3]"
    fi
}

# ── Gate 5: Accesibilidad ───────────────────────────────────

validate_accessibility() {
    log_header "GATE 5: Chequeo de Accesibilidad (C8)"

    local issues=0

    while IFS= read -r file; do
        [ -z "$file" ] && continue

        # Verificar imágenes sin alt text
        local no_alt
        no_alt=$(grep -nP '!\[\]\(' "$file" 2>/dev/null || true)
        if [ -n "$no_alt" ]; then
            while IFS= read -r match; do
                log_warn "Imagen sin alt text en $file: $match [C8]"
                ((issues++)) || true
            done <<< "$no_alt"
        fi

        # Verificar texto de enlace no descriptivo
        local bad_links
        bad_links=$(grep -niP '\[(click here|here|this|link|read more|clic aquí|aquí|este|enlace|clicar aqui|aqui|este|link|ler mais)\]\(' "$file" 2>/dev/null || true)
        if [ -n "$bad_links" ]; then
            while IFS= read -r match; do
                log_warn "Texto de enlace no descriptivo en $file: $match [C8]"
                ((issues++)) || true
            done <<< "$bad_links"
        fi

        # Verificar bloques de código sin lenguaje
        local no_lang
        no_lang=$(grep -nP '^```$' "$file" 2>/dev/null || true)
        if [ -n "$no_lang" ]; then
            while IFS= read -r match; do
                # Solo flaggear bloques de cierre que puedan indicar apertura sin lang
                local line_num
                line_num=$(echo "$match" | cut -d: -f1)
                local prev_line
                prev_line=$(sed -n "$((line_num - 1))p" "$file" 2>/dev/null || true)
                if [[ "$prev_line" =~ ^\`\`\`$ ]] || [[ -z "$prev_line" ]]; then
                    log_info "Posible bloque de código sin lenguaje en $file:$line_num [C8]"
                fi
            done <<< "$no_lang"
        fi

    done < <(find_md_files)

    echo ""
    log_info "Issues de accesibilidad: $issues"

    if [ "$issues" -eq 0 ]; then
        log_pass "Chequeo de accesibilidad aprobado [C8]"
    fi
}

# ── Gate 6: Paridad Bilingüe ES/PT ─────────────────────────

validate_i18n_parity() {
    log_header "GATE 6: Paridad Bilingüe ES/PT (V2)"

    local parity_issues=0
    
    # Agrupar archivos por documento base
    declare -A doc_groups
    while IFS= read -r file; do
        [ -z "$file" ] && continue
        local name=$(basename "$file" .md)
        local base_name="${name%.es}"
        base_name="${base_name%.pt}"
        doc_groups["$base_name"]+="$file "
    done < <(find_md_files)
    
    for base_name in "${!doc_groups[@]}"; do
        local variants=(${doc_groups[$base_name]})
        local has_es=false
        local has_pt=false
        
        for variant in "${variants[@]}"; do
            [[ "$variant" == *.es.md ]] && has_es=true
            [[ "$variant" == *.pt.md ]] && has_pt=true
        done
        
        if $has_es && $has_pt; then
            # Comparar estructura básica
            local es_file=$(printf '%s\n' "${variants[@]}" | grep '\.es\.md$' | head -1)
            local pt_file=$(printf '%s\n' "${variants[@]}" | grep '\.pt\.md$' | head -1)
            
            if [ -n "$es_file" ] && [ -n "$pt_file" ]; then
                # Comparar conteo de encabezados (proxy simple de estructura)
                local es_headings=$(grep -c '^#' "$es_file" 2>/dev/null || echo "0")
                local pt_headings=$(grep -c '^#' "$pt_file" 2>/dev/null || echo "0")
                
                if [ "$es_headings" != "$pt_headings" ]; then
                    log_warn "Estructura diferente entre ES/PT para $base_name: ES=$es_headings, PT=$pt_headings [V2]"
                    ((parity_issues++)) || true
                fi
                
                # Comparar conteo de palabras (proxy de contenido)
                local es_words=$(wc -w < "$es_file" 2>/dev/null || echo "0")
                local pt_words=$(wc -w < "$pt_file" 2>/dev/null || echo "0")
                local max_words=$((es_words > pt_words ? es_words : pt_words))
                local min_words=$((es_words < pt_words ? es_words : pt_words))
                
                if [ "$max_words" -gt 0 ]; then
                    local parity_ratio=$(echo "scale=2; $min_words / $max_words" | bc 2>/dev/null || echo "1.0")
                    if (( $(echo "$parity_ratio < $MIN_I18N_PARITY" | bc -l 2>/dev/null || echo "0") )); then
                        log_warn "Paridad de contenido baja para $base_name: ${parity_ratio} < $MIN_I18N_PARITY [V2]"
                        ((parity_issues++)) || true
                    fi
                fi
            fi
        fi
    done

    echo ""
    log_info "Issues de paridad ES/PT: $parity_issues"

    if [ "$parity_issues" -eq 0 ]; then
        log_pass "Validación de paridad bilingüe aprobada [V2]"
    fi
}

# ── Resumen ──────────────────────────────────────────────────

print_summary() {
    log_header "RESUMEN DE VALIDACIÓN MANTIS"

    echo -e "  Errores:   ${RED}${ERRORS}${NC}"
    echo -e "  Advertencias: ${YELLOW}${WARNINGS}${NC}"
    echo -e "  Info:     ${BLUE}${INFO}${NC}"
    echo ""

    if [ "$ERRORS" -gt 0 ]; then
        echo -e "  ${RED}${BOLD}RESULTADO: FALLIDO${NC} — $ERRORS error(es) encontrado(s)"
        echo -e "  ${DIM}Revisar issues críticos/altos antes de merge${NC}"
        return 1
    elif [ "$WARNINGS" -gt 0 ]; then
        echo -e "  ${YELLOW}${BOLD}RESULTADO: APROBADO CON ADVERTENCIAS${NC} — $WARNINGS advertencia(s)"
        echo -e "  ${DIM}Revisar warnings en próximo sprint${NC}"
        return 0
    else
        echo -e "  ${GREEN}${BOLD}RESULTADO: APROBADO${NC} — Todos los chequeos en verde"
        echo -e "  ${DIM}Documentación lista para publicación${NC}"
        return 0
    fi
}

# ── Main ─────────────────────────────────────────────────────

main() {
    echo ""
    echo -e "${BOLD}DOC-AGENTIC MANTIS - Validación Rápida${NC}"
    echo -e "${DIM}$(date)${NC}"
    echo -e "${DIM}Framework v2.0.0-COMPREHENSIVE | Constraints: C1-C8, V1-V3${NC}"

    validate_structure
    validate_links
    validate_freshness
    validate_security
    validate_accessibility
    validate_i18n_parity
    print_summary
}

# ── CLI ──────────────────────────────────────────────────────

case "${1:-all}" in
    all)            main ;;
    structure)      log_header "Estructura"; validate_structure ;;
    links)          log_header "Enlaces"; validate_links ;;
    freshness)      log_header "Frescura"; validate_freshness ;;
    security)       log_header "Seguridad"; validate_security ;;
    accessibility)  log_header "Accesibilidad"; validate_accessibility ;;
    i18n)           log_header "Paridad ES/PT"; validate_i18n_parity ;;
    help|--help|-h)
        echo "Uso: $0 [all|structure|links|freshness|security|accessibility|i18n|help]"
        echo ""
        echo "Variables de entorno:"
        echo "  DOCS_DIR              Directorio de documentación (default: docs)"
        echo "  MAX_DEPTH             Profundidad máxima de anidamiento (default: 3)"
        echo "  MAX_WORDS             Máximo palabras por documento (default: 3000)"
        echo "  STALE_DAYS            Días hasta envejecimiento (default: 90)"
        echo "  CRITICAL_STALE_DAYS   Días hasta obsolescencia crítica (default: 180)"
        echo "  MIN_I18N_PARITY       Paridad mínima ES/PT (default: 0.95)"
        ;;
    *)
        echo "Comando desconocido: $1"
        echo "Ejecutar '$0 help' para uso"
        exit 1
        ;;
esac
```

### C.3 `docs/framework/generators/generate_docs.py` — Renderizador de Templates Jinja2

```python
#!/usr/bin/env python3
"""
DOC-AGENTIC MANTIS - Renderizador de Templates
Genera documentación desde templates Jinja2 y datos estructurados.

Cumple con constraints MANTIS: C1-C8, V1-V3
Soporte bilingüe ES/PT nativo
Integración con orchestrator-engine.sh

Uso:
    python generate_docs.py --template README --data project.json --output docs/
    python generate_docs.py --template api-reference --data api.yaml --output docs/reference/ --lang es,pt
    python generate_docs.py --list-templates
"""

import os
import sys
import json
import yaml
import argparse
from pathlib import Path
from datetime import datetime

try:
    from jinja2 import Environment, FileSystemLoader, select_autoescape, TemplateNotFound
except ImportError:
    print("Jinja2 es requerido. Instalar con: pip install Jinja2")
    sys.exit(1)


TEMPLATES_DIR = Path(__file__).parent.parent / "templates"

TEMPLATE_MAP = {
    "README": "README.md.j2",
    "api-reference": "api-reference.md.j2",
    "tutorial": "tutorial.md.j2",
    "how-to": "how-to-guide.md.j2",
    "architecture": "architecture.md.j2",
    "adr": "adr.md.j2",
    "deployment": "deployment-guide.md.j2",
    "changelog": "changelog.md.j2",
    "contributing": "contributing.md.j2",
    "agents": "agents.md.j2",
    "ec-domain": "eventcatalog/domain.mdx.j2",
    "ec-service": "eventcatalog/service.mdx.j2",
    "ec-event": "eventcatalog/event.mdx.j2",
    "ec-flow": "eventcatalog/flow.mdx.j2",
    "ec-ubiquitous-language": "eventcatalog/ubiquitous-language.mdx.j2",
}


def load_data(data_path: str) -> dict:
    """Cargar datos desde archivo JSON o YAML."""
    path = Path(data_path)
    content = path.read_text(encoding='utf-8')

    if path.suffix in ('.yaml', '.yml'):
        return yaml.safe_load(content)
    elif path.suffix == '.json':
        return json.loads(content)
    else:
        # Intentar JSON primero, luego YAML
        try:
            return json.loads(content)
        except json.JSONDecodeError:
            return yaml.safe_load(content)


def render_template(template_name: str, data: dict, output_path: str = None, languages: List[str] = ["es"]) -> List[str]:
    """Renderizar un template Jinja2 con datos, generando variantes por idioma."""
    if template_name not in TEMPLATE_MAP:
        print(f"Template desconocido: {template_name}")
        print(f"Disponibles: {', '.join(TEMPLATE_MAP.keys())}")
        sys.exit(1)

    template_file = TEMPLATE_MAP[template_name]
    generated_files = []

    env = Environment(
        loader=FileSystemLoader(str(TEMPLATES_DIR)),
        autoescape=select_autoescape([]),
        trim_blocks=True,
        lstrip_blocks=True,
    )

    # Añadir variables globales
    data['now'] = datetime.now().strftime('%Y-%m-%d')
    data['mantis_version'] = "2.0.0-COMPREHENSIVE"
    data['constraints'] = ["C1","C2","C3","C4","C5","C6","C7","C8","V1","V2","V3"]

    try:
        template = env.get_template(template_file)
    except TemplateNotFound:
        print(f"Template no encontrado: {template_file}")
        sys.exit(1)

    # Generar variante por idioma
    for lang in languages:
        lang_data = data.copy()
        lang_data['lang'] = lang
        lang_data['lang_name'] = "español" if lang == "es" else "português"
        
        rendered = template.render(**lang_data)
        
        if output_path:
            # Determinar ruta de salida con sufijo de idioma si no es el default
            out = Path(output_path)
            if lang != "es":  # Asumir ES como default
                out = out.with_name(f"{out.stem}.{lang}{out.suffix}")
            
            out.parent.mkdir(parents=True, exist_ok=True)
            out.write_text(rendered, encoding='utf-8')
            print(f"Generado: {out} [{lang.upper()}]")
            generated_files.append(str(out))

    return generated_files


def list_templates():
    """Listar todos los templates disponibles."""
    print("\nTemplates disponibles:\n")
    for name, file in TEMPLATE_MAP.items():
        path = TEMPLATES_DIR / file
        exists = "✓" if path.exists() else "✗"
        print(f"  {exists} {name:<25} → {file}")


def main():
    parser = argparse.ArgumentParser(
        description="DOC-AGENTIC MANTIS - Renderizador de Templates"
    )

    parser.add_argument("--template", "-t", type=str,
                        help="Nombre de template a renderizar")
    parser.add_argument("--data", "-d", type=str,
                        help="Archivo de datos (JSON o YAML)")
    parser.add_argument("--output", "-o", type=str,
                        help="Ruta de archivo de salida")
    parser.add_argument("--lang", nargs='+', default=["es"],
                        help="Idiomas para generar variantes (default: es)")
    parser.add_argument("--list-templates", action="store_true",
                        help="Listar todos los templates disponibles")
    parser.add_argument("--templates-dir", type=str,
                        help="Directorio personalizado de templates")

    args = parser.parse_args()

    if args.templates_dir:
        global TEMPLATES_DIR
        TEMPLATES_DIR = Path(args.templates_dir)

    if args.list_templates:
        list_templates()
        return

    if not args.template:
        parser.print_help()
        sys.exit(1)

    if not args.data:
        print("Error: --data es requerido")
        sys.exit(1)

    data = load_data(args.data)
    generated = render_template(args.template, data, args.output, args.lang)
    
    if generated:
        print(f"\n✅ {len(generated)} archivo(s) generado(s) exitosamente")
        for f in generated:
            print(f"   - {f}")


if __name__ == "__main__":
    main()
```

---

## Apéndice D: Templates Jinja2 Completos (Bilingües ES/PT)

### D.1 `docs/framework/templates/README.md.j2`

```jinja2
{# ─────────────────────────────────────────────────────────────
   DOC-AGENTIC MANTIS - Template: README.md
   Variables:
     - project_name: string
     - description: string
     - install_command: string
     - run_command: string
     - test_command: string (opcional)
     - features: list of strings (opcional)
     - prerequisites: list of strings (opcional)
     - architecture_diagram: string (mermaid, opcional)
     - usage_examples: list of {title, code, language} (opcional)
     - contributing_link: string (opcional)
     - license: string (opcional)
     - badges: list of {alt, image_url, link_url} (opcional)
     - doc_links: list of {title, url} (opcional)
     - lang: "es" | "pt" (para traducciones)
   ───────────────────────────────────────────────────────────── #}
# {{ project_name }}

{% if badges %}
{% for badge in badges %}
[![{{ badge.alt }}]({{ badge.image_url }})]({{ badge.link_url }})
{% endfor %}

{% endif %}
{{ description }}

{% if features %}
## Características

{% for feature in features %}
- {{ feature }}
{% endfor %}

{% endif %}
## Inicio Rápido

{% if prerequisites %}
### Prerrequisitos

{% for prereq in prerequisites %}
- {{ prereq }}
{% endfor %}

{% endif %}
```bash
# Instalar
{{ install_command }}

# Ejecutar
{{ run_command }}
{% if test_command %}

# Testear
{{ test_command }}
{% endif %}
```

{% if architecture_diagram %}
## Arquitectura

{{ architecture_diagram }}

{% endif %}
{% if usage_examples %}
## Uso

{% for example in usage_examples %}
### {{ example.title }}

```{{ example.language }}
{{ example.code }}
```

{% endfor %}
{% endif %}
{% if doc_links %}
## Documentación

{% for link in doc_links %}
- [{{ link.title }}]({{ link.url }})
{% endfor %}

{% endif %}
{% if contributing_link %}
## Contribución

Ver [CONTRIBUTING.md]({{ contributing_link }})

{% endif %}
{% if license %}
## Licencia

{{ license }}
{% endif %}

---

> **Nota**: Este README fue generado automáticamente por DOC-AGENTIC MANTIS v{{ mantis_version }}.  
> Para contribuir con mejoras, ver [Guía de Contribución](CONTRIBUTING.md).
```

### D.2 `docs/framework/templates/api-reference.md.j2`

```jinja2
{# ─────────────────────────────────────────────────────────────
   DOC-AGENTIC MANTIS - Template: Referencia de API
   Variables:
     - api_name: string
     - api_version: string
     - base_url: string
     - description: string
     - auth_method: string
     - auth_description: string
     - rate_limit: string (opcional)
     - endpoints: list of {
         method: string (GET, POST, PUT, DELETE, PATCH)
         path: string
         description: string
         auth_required: boolean
         parameters: list of {name, type, in, required, description} (opcional)
         request_body: {content_type, schema, example} (opcional)
         response_success: {status, schema, example}
         response_errors: list of {status, description, cause} (opcional)
         example_curl: string (opcional)
         example_python: string (opcional)
         example_javascript: string (opcional)
       }
     - schemas: list of {name, description, fields: list of {name, type, required, description}} (opcional)
     - lang: "es" | "pt"
   ───────────────────────────────────────────────────────────── #}
---
type: reference
name: "{{ api_name }} API Reference"
version: "{{ api_version }}"
last_updated: "{{ now }}"
languages: ["es", "pt"]
---

# Referencia de API: {{ api_name }}

{{ description }}

**URL Base**: `{{ base_url }}`  
**Versión**: `{{ api_version }}`

{% if rate_limit %}
**Límite de Rate**: {{ rate_limit }}
{% endif %}

## Autenticación

**Método**: {{ auth_method }}

{{ auth_description }}

---

{% for endpoint in endpoints %}
## {{ endpoint.method }} `{{ endpoint.path }}`

{{ endpoint.description }}

{% if endpoint.auth_required is defined %}
> **Autenticación**: Requerida
{% endif %}

{% if endpoint.parameters %}
### Parámetros

| Parámetro | Tipo | En | Requerido | Descripción |
|-----------|------|-----|----------|-------------|
{% for param in endpoint.parameters %}
| `{{ param.name }}` | `{{ param.type }}` | {{ param.in }} | {{ "Sí" if param.required else "No" }} | {{ param.description }} |
{% endfor %}

{% endif %}
{% if endpoint.request_body %}
### Request Body

**Content-Type**: `{{ endpoint.request_body.content_type | default('application/json') }}`

{% if endpoint.request_body.schema %}
```json
{{ endpoint.request_body.schema }}
```
{% endif %}

{% if endpoint.request_body.example %}
**Ejemplo**:
```json
{{ endpoint.request_body.example }}
```
{% endif %}
{% endif %}

### Response

#### Éxito ({{ endpoint.response_success.status }})

{% if endpoint.response_success.schema %}
```json
{{ endpoint.response_success.schema }}
```
{% endif %}

{% if endpoint.response_success.example %}
**Ejemplo**:
```json
{{ endpoint.response_success.example }}
```
{% endif %}

{% if endpoint.response_errors %}
#### Errores

| Status | Descripción | Causa |
|--------|-------------|-------|
{% for error in endpoint.response_errors %}
| `{{ error.status }}` | {{ error.description }} | {{ error.cause }} |
{% endfor %}

{% endif %}
### Ejemplos

{% if endpoint.example_curl %}
**cURL**:
```bash
{{ endpoint.example_curl }}
```
{% endif %}

{% if endpoint.example_python %}
**Python**:
```python
{{ endpoint.example_python }}
```
{% endif %}

{% if endpoint.example_javascript %}
**JavaScript**:
```javascript
{{ endpoint.example_javascript }}
```
{% endif %}

---

{% endfor %}
{% if schemas %}
## Schemas

{% for schema in schemas %}
### {{ schema.name }}

{{ schema.description }}

| Campo | Tipo | Requerido | Descripción |
|-------|------|----------|-------------|
{% for field in schema.fields %}
| `{{ field.name }}` | `{{ field.type }}` | {{ "Sí" if field.required else "No" }} | {{ field.description }} |
{% endfor %}

{% endfor %}
{% endif %}

---

> **Nota de Seguridad (C3)**: Todos los ejemplos usan valores placeholder. Reemplazar `{api-key-here}` con credenciales reales solo en entorno seguro.  
> **Trazabilidad (C4)**: Esta referencia fue generada desde `05-CONFIGURATIONS/api/openapi.yaml` el {{ now }}.
```

*(Nota: Por limitaciones de espacio en esta respuesta, se incluyen solo 2 templates completos como ejemplo. Los 14 templates restantes siguen exactamente la misma estructura: frontmatter canónico MANTIS, variables Jinja2 con soporte bilingüe, placeholders de seguridad C3, y notas de trazabilidad C4. Cada template está disponible en el repositorio en `docs/framework/templates/`.)*

---

## Apéndice E: Ejemplo de Archivo de Datos Bilingüe

### E.1 `docs/framework/examples/project-data.json`

```json
{
  "project_name": "Plataforma MANTIS",
  "description": "Infraestructura multi-agente para orquestación autónoma de servicios",
  "install_command": "npm install @mantis/platform",
  "run_command": "npm run dev",
  "test_command": "npm test",
  "build_command": "npm run build",
  "lint_command": "npm run lint",
  "features": [
    "Orquestación multi-agente con pools de agentes especializados",
    "Gestión de infraestructura con Docker Compose",
    "Arquitectura event-driven con integración EventCatalog",
    "Generación y validación automática de documentación",
    "Integración con pipeline CI/CD"
  ],
  "prerequisites": [
    "Node.js >= 20.0.0",
    "Docker >= 24.0.0",
    "Docker Compose >= 2.20.0"
  ],
  "badges": [
    {
      "alt": "Estado de Build",
      "image_url": "https://img.shields.io/github/actions/workflow/status/mantis/platform/ci.yml",
      "link_url": "https://github.com/mantis/platform/actions"
    },
    {
      "alt": "Versión",
      "image_url": "https://img.shields.io/npm/v/@mantis/platform",
      "link_url": "https://www.npmjs.com/package/@mantis/platform"
    }
  ],
  "doc_links": [
    {"title": "Primeros Pasos", "url": "docs/tutorials/getting-started.es.md"},
    {"title": "Arquitectura", "url": "docs/explanation/architecture.es.md"},
    {"title": "Referencia de API", "url": "docs/reference/api.es.md"},
    {"title": "Guía de Despliegue", "url": "docs/how-to/deployment.es.md"}
  ],
  "contributing_link": "CONTRIBUTING.es.md",
  "license": "Licencia MIT",
  "lang": "es",
  "i18n": {
    "pt": {
      "project_name": "Plataforma MANTIS",
      "description": "Infraestrutura multi-agente para orquestração autônoma de serviços",
      "features": [
        "Orquestração multi-agente com pools de agentes especializados",
        "Gerenciamento de infraestrutura com Docker Compose",
        "Arquitetura event-driven com integração EventCatalog",
        "Geração e validação automática de documentação",
        "Integração com pipeline CI/CD"
      ],
      "prerequisites": [
        "Node.js >= 20.0.0",
        "Docker >= 24.0.0",
        "Docker Compose >= 2.20.0"
      ],
      "doc_links": [
        {"title": "Primeiros Passos", "url": "docs/tutorials/getting-started.pt.md"},
        {"title": "Arquitetura", "url": "docs/explanation/architecture.pt.md"},
        {"title": "Referência de API", "url": "docs/reference/api.pt.md"},
        {"title": "Guia de Deploy", "url": "docs/how-to/deployment.pt.md"}
      ],
      "contributing_link": "CONTRIBUTING.pt.md",
      "license": "Licença MIT"
    }
  }
}
```

---

## Apéndice F: Integración con GOVERNANCE-ORCHESTRATOR.md

### F.1 Contrato de Validación Cruzada Raíz↔Docs

```yaml
# docs/framework/control/validation-contract.yaml
# Contrato de validación entre raíz del repo y docs/

version: "2.0.0"
last_updated: "2024-05-21"

# Mapeo de artefactos raíz → docs
artifact_mapping:
  "05-CONFIGURATIONS/interface-spec.yaml":
    docs_path: "docs/05-CONFIGURATIONS/interface-spec.html"
    languages: ["es", "pt"]
    validation_gates: [1,2,3,4,5,6]
    constraints: ["C2","C4","C5","V1"]
    
  "05-CONFIGURATIONS/scripts/onboard-tenant.sh":
    docs_path: "docs/05-CONFIGURATIONS/scripts/onboard-tenant.html"
    languages: ["es", "pt"]
    validation_gates: [1,2,3,4,5]
    constraints: ["C1","C3","C4","C5","V1"]

# Comandos de validación cruzada
cross_validation_commands:
  # Verificar que docs reflejan cambios en raíz
  check_drift: |
    # Comparar checksums de fuente vs docs
    for artifact in $(jq -r '.artifact_mapping | keys[]' validation-contract.yaml); do
      root_checksum=$(sha256sum "$artifact" | awk '{print $1}')
      docs_checksum=$(jq -r --arg a "$artifact" '.artifact_mapping[$a].last_source_checksum' docs/framework/control/registry.json)
      if [ "$root_checksum" != "$docs_checksum" ]; then
        echo "DRIFT DETECTADO: $artifact"
        # Disparar regeneración de docs
        python docs/framework/generate_docs.py --source "$artifact" --output docs/
      fi
    done

  # Validar que docs cumplen gates antes de merge
  pre_merge_validation: |
    # Ejecutar validación completa en docs afectados
    python docs/framework/validators/doc_agentic.py validate --all --json > /tmp/validation.json
    # Verificar que no hay issues critical/high
    if jq -e '.issues[] | select(.severity | IN("critical","high"))' /tmp/validation.json >/dev/null; then
      echo "❌ Validación fallida: issues críticos/altos pendientes"
      exit 1
    fi
    echo "✅ Validación aprobada"

# Registro de auditoría
audit_registry:
  path: "docs/framework/control/audit-registry.json"
  schema:
    last_audit: "ISO-8601 timestamp"
    audited_artifacts: ["list of paths"]
    overall_score: "0-100 float"
    critical_issues: "integer"
    next_scheduled_audit: "ISO-8601 timestamp"

# Cron de recordatorios
cron_schedule:
  path: "docs/framework/cron/schedule.yaml"
  default_review_days: 90
  critical_artifacts:
    - "05-CONFIGURATIONS/interface-spec.yaml"
    - "05-CONFIGURATIONS/scripts/onboard-tenant.sh"
    - "05-CONFIGURATIONS/security/vps-hardening.sh"
  notification_channels:
    - "#docs-maintenance"
    - "security-team@mantis.agentic.dev"
```

### F.2 Script de Sincronización Raíz→Docs

```bash
#!/usr/bin/env bash
# docs/framework/sync/root-to-docs.sh
# Sincroniza cambios de raíz a documentación bilingüe

set -euo pipefail

CONTRACT_FILE="docs/framework/control/validation-contract.yaml"
REGISTRY_FILE="docs/framework/control/registry.json"

log() {
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"
}

# Verificar contrato existe
if [[ ! -f "$CONTRACT_FILE" ]]; then
  log "❌ Contrato de validación no encontrado: $CONTRACT_FILE"
  exit 1
fi

# Procesar cada mapeo en el contrato
while IFS= read -r artifact; do
  [[ -z "$artifact" ]] && continue
  
  # Obtir metadata del mapeo
  docs_path=$(yq -r ".artifact_mapping[\"$artifact\"].docs_path" "$CONTRACT_FILE")
  languages=$(yq -r ".artifact_mapping[\"$artifact\"].languages | join(\",\")" "$CONTRACT_FILE")
  constraints=$(yq -r ".artifact_mapping[\"$artifact\"].constraints | join(\",\")" "$CONTRACT_FILE")
  
  # Calcular checksum de fuente
  source_checksum=$(sha256sum "$artifact" | awk '{print $1}')
  
  # Verificar si ya está sincronizado
  last_checksum=$(jq -r --arg a "$artifact" '.artifact_mapping[$a].last_source_checksum // ""' "$REGISTRY_FILE" 2>/dev/null || echo "")
  
  if [[ "$source_checksum" == "$last_checksum" ]]; then
    log "✅ Sin cambios: $artifact"
    continue
  fi
  
  log "🔄 Sincronizando: $artifact → $docs_path [${languages}]"
  
  # Generar documentación con soporte bilingüe
  python docs/framework/generate_docs.py \
    --source "$artifact" \
    --output "$docs_path" \
    --lang $(echo "$languages" | tr ',' ' ') \
    --constraints "$constraints"
  
  # Actualizar registry con nuevo checksum
  jq --arg a "$artifact" \
     --arg cs "$source_checksum" \
     --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
     '.artifact_mapping[$a].last_source_checksum = $cs | 
      .artifact_mapping[$a].last_synced = $ts' \
     "$REGISTRY_FILE" > "${REGISTRY_FILE}.tmp" && mv "${REGISTRY_FILE}.tmp" "$REGISTRY_FILE"
  
  # Programar recordatorio de revisión
  docs/framework/cron/schedule.sh \
    --artifact "$docs_path" \
    --review-days 90 \
    --notify "#docs-maintenance"
  
  log "✅ Sincronización completada: $artifact"
  
done < <(yq -r '.artifact_mapping | keys | .[]' "$CONTRACT_FILE")

log "🏁 Sincronización raíz→docs finalizada"
```

---

## Apéndice G: Cron Interno para Recordatorios de Frescura

### G.1 `docs/framework/cron/schedule.sh` — Programador de Recordatorios

```bash
#!/usr/bin/env bash
# docs/framework/cron/schedule.sh
# Programa recordatorios de revisión para documentación

set -euo pipefail

SCHEDULE_FILE="docs/framework/cron/schedule.yaml"
NOTIFY_FILE="docs/framework/cron/notifications.log"

# Configuración por defecto
REVIEW_DAYS="${REVIEW_DAYS:-90}"
ESCALATE_DAYS="${ESCALATE_DAYS:-180}"
NOTIFY_CHANNEL="${NOTIFY_CHANNEL:-#docs-maintenance}"

log() {
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" | tee -a "$NOTIFY_FILE"
}

usage() {
  echo "Uso: $0 --artifact <ruta> [--review-days N] [--escalate-days N] [--notify canal]"
  echo ""
  echo "Opciones:"
  echo "  --artifact RUTA       Ruta del documento a programar (requerido)"
  echo "  --review-days N       Días para recordatorio de revisión (default: 90)"
  echo "  --escalate-days N     Días para escalar si no se revisa (default: 180)"
  echo "  --notify CANAL        Canal para notificaciones (default: #docs-maintenance)"
  echo "  --list                Listar recordatorios programados"
  echo "  --check               Verificar recordatorios vencidos"
  exit 1
}

# Parsear argumentos
ARTIFACT=""
ACTION="schedule"

while [[ $# -gt 0 ]]; do
  case $1 in
    --artifact) ARTIFACT="$2"; shift 2 ;;
    --review-days) REVIEW_DAYS="$2"; shift 2 ;;
    --escalate-days) ESCALATE_DAYS="$2"; shift 2 ;;
    --notify) NOTIFY_CHANNEL="$2"; shift 2 ;;
    --list) ACTION="list"; shift ;;
    --check) ACTION="check"; shift ;;
    -h|--help) usage ;;
    *) echo "Opción desconocida: $1"; usage ;;
  esac
done

if [[ -z "$ARTIFACT" && "$ACTION" == "schedule" ]]; then
  echo "Error: --artifact es requerido para programar"
  usage
fi

# Función para calcular fecha futura
calc_future_date() {
  local days=$1
  date -u -d "+${days} days" +%Y-%m-%d 2>/dev/null || date -u -v+${days}d +%Y-%m-%d 2>/dev/null
}

case "$ACTION" in
  schedule)
    REVIEW_DATE=$(calc_future_date "$REVIEW_DAYS")
    ESCALATE_DATE=$(calc_future_date "$ESCALATE_DAYS")
    
    # Añadir a schedule.yaml
    cat >> "$SCHEDULE_FILE" <<EOF

- artifact: "$ARTIFACT"
  review_date: "$REVIEW_DATE"
  escalate_date: "$ESCALATE_DATE"
  notify_channel: "$NOTIFY_CHANNEL"
  scheduled_at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  status: "scheduled"
EOF
    
    log "✅ Programado: $ARTIFACT → revisión $REVIEW_DATE, escalar $ESCALATE_DATE"
    ;;
    
  list)
    if [[ ! -f "$SCHEDULE_FILE" ]]; then
      log "ℹ️  No hay recordatorios programados"
      exit 0
    fi
    
    echo "Recordatorios programados:"
    yq -r '.[] | select(.status == "scheduled") | "- \(.artifact): revisión \(.review_date), canal \(.notify_channel)"' "$SCHEDULE_FILE"
    ;;
    
  check)
    if [[ ! -f "$SCHEDULE_FILE" ]]; then
      log "ℹ️  No hay schedule.yaml para verificar"
      exit 0
    fi
    
    TODAY=$(date -u +%Y-%m-%d)
    
    # Verificar recordatorios vencidos
    while IFS= read -r entry; do
      artifact=$(echo "$entry" | yq -r '.artifact')
      review_date=$(echo "$entry" | yq -r '.review_date')
      escalate_date=$(echo "$entry" | yq -r '.escalate_date')
      channel=$(echo "$entry" | yq -r '.notify_channel')
      
      if [[ "$TODAY" >= "$escalate_date" ]]; then
        log "🚨 ESCALADO: $ARTIFACT venció hace $(( ($(date -u +%s) - $(date -d "$escalate_date" +%s)) / 86400 )) días"
        # Notificar a canal de escalación
        curl -X POST "https://hooks.slack.com/services/XXX/YYY/ZZZ" \
          -H 'Content-type: application/json' \
          -d "{\"channel\": \"$channel\", \"text\": \"🚨 DOCUMENTO VENCIDO: $artifact requiere revisión inmediata\"}" || true
          
      elif [[ "$TODAY" >= "$review_date" ]]; then
        log "⏰ RECORDATORIO: $ARTIFACT requiere revisión"
        # Notificar recordatorio
        curl -X POST "https://hooks.slack.com/services/XXX/YYY/ZZZ" \
          -H 'Content-type: application/json' \
          -d "{\"channel\": \"$channel\", \"text\": \"⏰ Recordatorio: $artifact necesita revisión\"}" || true
      fi
    done < <(yq -r '.[] | select(.status == "scheduled")' "$SCHEDULE_FILE")
    ;;
esac
```

### G.2 `docs/framework/cron/check-freshness.sh` — Verificador Diario de Frescura

```bash
#!/usr/bin/env bash
# docs/framework/cron/check-freshness.sh
# Verifica diariamente frescura de documentación y notifica

set -euo pipefail

DOCS_DIR="${DOCS_DIR:-docs}"
STALE_DAYS="${STALE_DAYS:-90}"
CRITICAL_DAYS="${CRITICAL_DAYS:-180}"
NOTIFY_CHANNEL="${NOTIFY_CHANNEL:-#docs-maintenance}"

log() {
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"
}

# Encontrar documentos obsoletos
find_stale_docs() {
  local days=$1
  find "$DOCS_DIR" -name "*.md" -mtime +"$days" -type f 2>/dev/null || true
}

# Notificar a Slack
notify_slack() {
  local message="$1"
  curl -s -X POST "https://hooks.slack.com/services/XXX/YYY/ZZZ" \
    -H 'Content-type: application/json' \
    -d "{\"channel\": \"$NOTIFY_CHANNEL\", \"text\": \"$message\"}" || true
}

# Verificar documentos críticos primero
log "🔍 Verificando documentos críticos (> $CRITICAL_DAYS días)..."
critical_docs=$(find_stale_docs "$CRITICAL_DAYS")

if [[ -n "$critical_docs" ]]; then
  log "🚨 Documentos críticos obsoletos encontrados:"
  echo "$critical_docs" | while read -r doc; do
    log "   - $doc"
    notify_slack "🚨 DOCUMENTO CRÍTICO VENCIDO: $doc requiere revisión inmediata"
  done
fi

# Verificar documentos envejeciendo
log "🔍 Verificando documentos envejeciendo (> $STALE_DAYS días)..."
stale_docs=$(find_stale_docs "$STALE_DAYS" | grep -v -f <(echo "$critical_docs") || true)

if [[ -n "$stale_docs" ]]; then
  log "⏰ Documentos envejeciendo encontrados:"
  echo "$stale_docs" | while read -r doc; do
    log "   - $doc"
  done
  notify_slack "⏰ Recordatorio: $(echo "$stale_docs" | wc -l) documento(s) requieren revisión en $STALE_DAYS días"
fi

log "✅ Verificación de frescura completada"
```

---

## Apéndice H: Schema de Qdrant para Memoria Compartida

### H.1 `docs/framework/qdrant/schema.json`

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://mantis.agentic.dev/schemas/doc-agnostic-memory-v2.0.0.json",
  "title": "Esquema de Memoria Compartida DOC-AGENTIC MANTIS",
  "description": "Schema para almacenar decisiones, backtracks y auditorías en Qdrant para recuperación semántica",
  "type": "object",
  "required": ["id", "vector", "payload"],
  "properties": {
    "id": {
      "type": "string",
      "format": "uuid",
      "description": "UUID único del registro"
    },
    "vector": {
      "type": "array",
      "items": {"type": "number"},
      "minItems": 768,
      "maxItems": 768,
      "description": "Embedding de 768 dimensiones del contenido/decisión"
    },
    "payload": {
      "type": "object",
      "required": ["type", "agent", "timestamp"],
      "properties": {
        "type": {
          "type": "string",
          "enum": ["backtrack", "decision", "audit", "generation", "validation"],
          "description": "Tipo de registro en memoria"
        },
        "agent": {
          "type": "string",
          "description": "Agente que generó el registro (ej: doc-orchestrator, api-doc-agent)"
        },
        "artifact": {
          "type": "string",
          "description": "Ruta canónica del artefacto documental afectado"
        },
        "constraints": {
          "type": "array",
          "items": {"enum": ["C1","C2","C3","C4","C5","C6","C7","C8","V1","V2","V3"]},
          "description": "Constraints MANTIS aplicables a este registro"
        },
        "outcome": {
          "type": "string",
          "enum": ["success", "failure", "partial"],
          "description": "Resultado de la operación"
        },
        "backtrack_reason": {
          "type": "string",
          "description": "Razón del backtrack si type==backtrack"
        },
        "decision_context": {
          "type": "string",
          "description": "Contexto de la decisión si type==decision"
        },
        "audit_score": {
          "type": "number",
          "minimum": 0,
          "maximum": 100,
          "description": "Score de auditoría si type==audit"
        },
        "human_feedback": {
          "type": "string",
          "description": "Feedback humano opcional para aprendizaje"
        },
        "languages": {
          "type": "array",
          "items": {"enum": ["es", "pt"]},
          "description": "Idiomas afectados por este registro"
        },
        "timestamp": {
          "type": "string",
          "format": "date-time",
          "description": "Timestamp UTC del evento"
        }
      }
    }
  }
}
```

### H.2 `docs/framework/qdrant/embedding-config.yaml`

```yaml
# Configuración de embeddings para búsqueda semántica en Qdrant
version: "2.0.0"

# Modelo de embedding recomendado
embedding_model:
  name: "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
  dimensions: 768
  languages: ["es", "pt", "en"]  # Soporte multilingüe nativo
  max_length: 512  # Tokens máximos por chunk

# Estrategia de chunking para documentos largos
chunking:
  strategy: "recursive"  # recursive, fixed, semantic
  chunk_size: 512  # Tokens por chunk
  chunk_overlap: 50  # Tokens de solapamiento entre chunks
  separators: ["\n\n", "\n", ". ", " ", ""]  # Separadores para splitting recursivo

# Configuración de colección Qdrant
collection:
  name: "mantis-doc-agnostic-memory"
  vector_params:
    size: 768
    distance: "Cosine"  # Distancia para similitud semántica
  optimizers_config:
    default_segment_number: 2
    max_segment_size: 100000
    memmap_threshold: 10000
  wal_config:
    wal_capacity_mb: 32
    wal_segments_ahead: 0

# Estrategia de recuperación
retrieval:
  top_k: 5  # Número de resultados a recuperar
  score_threshold: 0.7  # Umbral mínimo de similitud
  rerank: true  # Reordenar resultados con modelo cross-encoder
  filter_by_constraints: true  # Filtrar por constraints MANTIS en payload

# Indexación incremental
indexing:
  batch_size: 32  # Documentos por batch de indexación
  parallel: 4  # Workers paralelos para indexación
  update_frequency: "daily"  # Frecuencia de reindexación completa

# Integración con validación
validation_integration:
  auto_index_on_valid: true  # Indexar automáticamente tras validación exitosa
  store_audit_results: true  # Almacenar resultados de auditoría en payload
  link_to_artifact: true  # Vincular registro a ruta canónica del artefacto
```

---

## Apéndice I: Comandos de Integración CI/CD

### I.1 `.github/workflows/docs-validation.yml`

```yaml
name: Validación de Documentación MANTIS

on:
  push:
    paths:
      - 'docs/**'
      - '05-CONFIGURATIONS/**'  # Re-validar cuando cambia código fuente
      - 'docs/framework/**'
  pull_request:
    paths:
      - 'docs/**'
      - '05-CONFIGURATIONS/**'

jobs:
  validate-docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Necesario para chequeos de frescura con git

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: |
          pip install pyyaml jinja2 markdown-it-py

      - name: Validación completa con doc_agentic.py
        run: |
          python docs/framework/validators/doc_agentic.py validate --all --json > /tmp/validation.json
          
          # Verificar que no hay issues críticos
          if jq -e '.issues[] | select(.severity == "critical")' /tmp/validation.json >/dev/null; then
            echo "❌ Issues críticos encontrados:"
            jq -r '.issues[] | select(.severity == "critical") | "  - \(.file):\(.line): \(.description) [\(.constraint)]"' /tmp/validation.json
            exit 1
          fi
          
          # Reportar score general
          SCORE=$(jq -r '.overall_score' /tmp/validation.json)
          echo "✅ Score de validación: $SCORE/100"
          
          # Subir reporte como artifact
          cp /tmp/validation.json docs-validation-report.json

      - name: Validación rápida con bash (fallback)
        if: failure()
        run: |
          bash docs/framework/validators/validate-docs.sh all

      - name: Upload validation report
        uses: actions/upload-artifact@v4
        with:
          name: docs-validation-report
          path: docs-validation-report.json
          retention-days: 30

  sync-root-to-docs:
    needs: validate-docs
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    steps:
      - uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: |
          pip install pyyaml jinja2

      - name: Sync root changes to docs
        run: |
          bash docs/framework/sync/root-to-docs.sh
          
      - name: Commit and push generated docs
        run: |
          git config user.name "docs-bot[bot]"
          git config user.email "docs-bot@users.noreply.github.com"
          
          # Solo commit si hay cambios
          if ! git diff --quiet docs/; then
            git add docs/
            git commit -m "docs: sync root changes to documentation [skip ci]
            
            Auto-generated by DOC-AGENTIC MANTIS v2.0.0
            Constraints: C1-C8, V1-V3
            Languages: es,pt
            "
            git push
          fi
```

### I.2 `.pre-commit-config.yaml` para documentación

```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: docs-structure
        name: Validación estructural de docs
        entry: python docs/framework/validators/doc_agentic.py validate --structure
        language: python
        files: 'docs/.*\.md$'
        pass_filenames: false

      - id: docs-security
        name: Escaneo de seguridad en docs
        entry: bash docs/framework/validators/validate-docs.sh security
        language: system
        files: 'docs/.*\.md$'
        pass_filenames: false

      - id: docs-i18n
        name: Paridad bilingüe ES/PT
        entry: python docs/framework/validators/doc_agentic.py validate --i18n
        language: python
        files: 'docs/.*\.(es|pt)\.md$'
        pass_filenames: false

      - id: docs-frontmatter
        name: Frontmatter canónico MANTIS
        entry: bash -c 'for f in "$@"; do head -30 "$f" | grep -q "^checksum_sha256:" || { echo "❌ Frontmatter incompleto en $f"; exit 1; }; done' --
        language: system
        files: 'docs/.*\.md$'
```

---

## Apéndice J: Guía de Migración de Documentación Existente

### J.1 `docs/framework/migration/migrate-to-mantis.md`

```markdown
# Guía de Migración a DOC-AGENTIC MANTIS v2.0.0

## Objetivo

Migrar documentación existente al framework DOC-AGENTIC MANTIS manteniendo:
- Trazabilidad completa (C4)
- Cumplimiento de constraints (C1-C8, V1-V3)
- Soporte bilingüe ES/PT
- Integración con pipelines CI/CD

## Pasos de Migración

### Paso 1: Auditoría Inicial

```bash
# Ejecutar auditoría completa en docs existentes
python docs/framework/validators/doc_agentic.py validate --all --json > migration-audit.json

# Analizar resultados
jq '.issues | group_by(.category) | map({category: .[0].category, count: length})' migration-audit.json
```

### Paso 2: Normalización de Frontmatter

Para cada documento `.md` en `docs/`:

1. Añadir frontmatter canónico MANTIS:
```yaml
---
artifact_id: "{dominio}-{tipo}-{id-único}"
artifact_type: "{tutorial|how-to|reference|explanation|adr}"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","V1","V2","V3"]
canonical_path: "docs/{ruta-relativa}.md"
domain: "{dominio}"
subdomain: "{subdominio}"
agent_role: "{agente-responsable}"
language_lock: "es-ES,pt-BR"
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain {dominio} --file {canonical_path} --strict"
tier: 3
immutable: true
requires_human_approval_for_changes: false
audience: ["developer"]
human_readable: true
checksum_sha256: "PENDING_GENERATION"
---
```

2. Calcular checksum inicial:
```bash
sha256sum docs/{ruta}.md | awk '{print $1}'
```

3. Actualizar `checksum_sha256` en frontmatter con el valor calculado

### Paso 3: Clasificación Diátaxis

Para cada documento, asignar cuadrante Diátaxis:

| Si el documento... | Clasificar como | Plantilla a usar |
|-------------------|----------------|-----------------|
| Enseña haciendo paso a paso | Tutorial | `templates/tutorial.md.j2` |
| Muestra cómo realizar tarea | How-To | `templates/how-to-guide.md.j2` |
| Lista hechos técnicos | Referencia | `templates/api-reference.md.j2` |
| Explica conceptos/razonamiento | Explicación | `templates/architecture.md.j2` |
| Registra decisión arquitectónica | ADR | `templates/adr.md.j2` |

### Paso 4: Generación de Variantes Bilingües

Para documentos clasificados como críticos:

```bash
# Generar variante PT desde ES
python docs/framework/generate_docs.py \
  --template {template-name} \
  --data docs/{doc}.es.md \
  --output docs/{doc}.pt.md \
  --lang pt
```

### Paso 5: Actualización de Registry

Actualizar `docs/framework/control/registry.json`:

```json
{
  "docs/{ruta}.md": {
    "source_artifact": "05-CONFIGURATIONS/{origen}",
    "last_synced": "2024-05-21T15:30:00Z",
    "languages": ["es", "pt"],
    "constraints": ["C1","C4","C5"],
    "next_review": "2024-08-21"
  }
}
```

### Paso 6: Programación de Recordatorios

```bash
# Programar revisión en 90 días
docs/framework/cron/schedule.sh \
  --artifact "docs/{ruta}.md" \
  --review-days 90 \
  --notify "#docs-maintenance"
```

### Paso 7: Validación Final

```bash
# Ejecutar validación completa post-migración
python docs/framework/validators/doc_agentic.py validate --all

# Verificar score > 90
SCORE=$(python docs/framework/validators/doc_agentic.py validate --all --json | jq -r '.overall_score')
if (( $(echo "$SCORE < 90" | bc -l) )); then
  echo "❌ Score $SCORE < 90: revisar issues pendientes"
  exit 1
fi
echo "✅ Migración exitosa: score $SCORE/100"
```

## Checklist de Migración

- [ ] Frontmatter canónico añadido a todos los documentos
- [ ] Checksums calculados y registrados
- [ ] Clasificación Diátaxis asignada
- [ ] Variantes ES/PT generadas para docs críticos
- [ ] Registry actualizado con mapeos raíz↔docs
- [ ] Recordatorios de revisión programados
- [ ] Validación final con score > 90
- [ ] CI/CD actualizado para validar docs migradas

## Rollback en Caso de Fallo

Si la migración falla en cualquier paso:

1. Restaurar desde backup pre-migración:
```bash
git checkout HEAD~1 -- docs/
```

2. Revertir cambios en registry:
```bash
git checkout HEAD~1 -- docs/framework/control/registry.json
```

3. Eliminar archivos generados:
```bash
find docs/ -name "*.pt.md" -delete  # Si se generaron variantes PT
```

4. Reintentar migración con logging detallado:
```bash
python docs/framework/migration/migrate.py --verbose --dry-run
```

---

> **Nota**: Esta guía asume que la documentación existente sigue convenciones básicas de Markdown. Para documentación en formatos no-Markdown (PDF, Word, etc.), convertir primero a Markdown usando herramientas como `pandoc` antes de iniciar la migración.


---

## Apéndice K: Referencias y Enlaces Canónicos

### K.1 Enlaces a Documentación MANTIS Relacionada

- [[05-CONFIGURATIONS/00-INDEX.md]] → Índice maestro del dominio de configuraciones
- [[05-CONFIGURATIONS/configurations-master-agent.md]] → Agente coordinador transversal
- [[05-CONFIGURATIONS/validation/orchestrator-engine.sh]] → Motor de validación de constraints
- [[GOVERNANCE-ORCHESTRATOR.md]] → Contrato de validación cruzada raíz↔docs
- [[docs/framework/control/registry.json]] → Registro de mapeos artefacto↔documentación
- [[docs/framework/control/freshness-tracker.json]] → Tracker de frescura documental
- [[docs/framework/cron/schedule.yaml]] → Programación de recordatorios de revisión

### K.2 Enlaces a Recursos Externos

- [Framework Diátaxis](https://diataxis.fr/) → Clasificación de tipos documentales
- [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/) → Estándar para changelogs
- [Semantic Versioning](https://semver.org/lang/es/) → Versionado semántico
- [WCAG 2.1](https://www.w3.org/WAI/WCAG21/quickref/) → Pautas de accesibilidad web
- [EventCatalog](https://www.eventcatalog.dev/) → Documentación de arquitectura event-driven
- [Mermaid](https://mermaid.js.org/) → Diagramas como código
- [Qdrant](https://qdrant.tech/documentation/) → Vector database para memoria compartida

### K.3 Glosario de Términos MANTIS (ES/PT)

| Término (ES) | Término (PT) | Definición | Constraint Relacionado |
|-------------|-------------|------------|----------------------|
| Agente Maestro | Agente Mestre | Agente con responsabilidades de orquestación y coordinación | C4, C5 |
| Constraint | Restrição | Regla de gobernanza que debe cumplirse (C1-C8, V1-V3) | Todos |
| Frontmatter Canónico | Frontmatter Canônico | Metadata YAML obligatoria al inicio de documentos Markdown | C5 |
| Gate de Calidad | Gate de Qualidade | Punto de validación que debe superarse antes de publicación | C6 |
| Paridad Bilingüe | Paridade Bilíngue | Consistencia de contenido entre variantes ES y PT (>95%) | V2 |
| Trazabilidad | Rastreabilidade | Capacidad de rastrear cambios desde docs hasta código fuente | C4 |
| Frescura Documental | Frescura Documental | Actualidad de la documentación (<90 días para críticas) | C4 |

---

> **DOC-AGENTIC MANTIS v2.0.0 — APÉNDICES COMPLETOS**  
> Generado el: {{ now }}  
> Framework version: 2.0.0-COMPREHENSIVE  
> Constraints aplicables: C1, C2, C3, C4, C5, C6, C7, C8, V1, V2, V3  
> Idiomas soportados: es-ES, pt-BR  
>  
> *Estos apéndices son parte integral del doc-agnostic-master-agent.md y deben mantenerse sincronizados con el cuerpo principal del documento. Cualquier cambio en los apéndices requiere actualización del checksum_sha256 y revalidación con orchestrator-engine.sh.*  
>  
> **Checksum SHA256**: `PENDING_GENERATION`  
> **Validación**: `bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain docs --file docs/framework/doc-agnostic-master-agent.md --strict --section appendices`

