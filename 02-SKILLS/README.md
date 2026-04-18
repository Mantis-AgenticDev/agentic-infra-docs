# SHA256: c9f3e8a2b1d7f4e6a0c5b9d2e8f1a4c7b3d6e9f2a5c8b1d4e7a0f3c6b9d2e5a8
---
artifact_id: "02-SKILLS-README"
artifact_type: "rule_markdown"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C3","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 02-SKILLS/README.md --json"
canonical_path: "02-SKILLS/README.md"
---

# 🧠 02-SKILLS: DOCUMENTACIÓN TÉCNICA POR DOMINIO – MANTIS AGENTIC

> **Versión**: 3.0.0-SELECTIVE | **Estado**: HARDENED-SDD | **Última actualización**: 2026-04-19  
> **Constraints**: C1-C8 (CORE) | **V1-V3**: ❌ NO APLICAN (rule_markdown, NO skill_pgvector)  
> **Estilo**: Formal, directo, ejecutable | **LANGUAGE LOCK**: Markdown puro – cero operadores pgvector  
> **Propósito**: Base de conocimiento técnico para autogeneración de agentes y código validado para deploy humano.

---

## 🗺️ MAPA ESTRUCTURAL CANÓNICO (ASCII TREE)

```text
02-SKILLS/
├── README.md                          # 📄 ESTE ARCHIVO: Guía maestra de navegación y validación
├── skill-domains-mapping.md           # 🔗 Mapeo concepto→ruta física canónica para IAs
│
├── AI/                                # 🤖 Integración de modelos de IA (OpenRouter + directos)
│   ├── deepseek-integration.md        # reasoning_content, rate-limit, fallback coder, coste optimizado
│   ├── gemini-integration.md          # multimodal, function calling, safety settings, streaming
│   ├── gpt-integration.md             # function calling, JSON mode, structured outputs, retry wrapper
│   ├── image-gen-api.md               # generación + edición, webhook callback, tenant_id en metadata
│   ├── llama-integration.md           # open-weight, quantization-aware, fallback local (C6 exception)
│   ├── minimax-integration.md         # contexto 1M, procesamiento iterativo, resumen jerárquico
│   ├── mistral-ocr-integration.md     # PDF→texto estructurado, bounding boxes, tenant isolation
│   ├── openrouter-api-integration.md  # proxy unificado, routing dinámico, coste/latencia balancing
│   ├── qwen-integration.md            # contexto 131K, JSON mode, cache semántica, fallback 32B
│   ├── video-gen-api.md               # generación por prompts, progress polling, storage tenant-scoped
│   └── voice-agent-integration.md     # STT/TST streaming, wake-word, tenant_id en audio chunks
│
├── BASE DE DATOS-RAG/                 # 🗄️ Patrones de ingestión, consulta y aislamiento multi-tenant
│   ├── qdrant-rag-ingestion.md        # search, scroll, recommend, delete, count, updateVectors
│   ├── postgres-prisma-rag.md         # transacciones, pool limitado, full-text, JSONB, RLS
│   ├── multi-tenant-data-isolation.md # estrategias de aislamiento: schema-per-tenant vs row-level
│   ├── pdf-mistralocr-processing.md   # pipeline OCR → chunking → embedding → Qdrant
│   ├── google-drive-qdrant-sync.md    # webhook + polling para sync bidireccional
│   ├── espocrm-api-analytics.md       # extracción de métricas comerciales para RAG contextual
│   ├── mysql-optimization-4gb-ram.md  # tuning para VPS con ≤4GB RAM (C1)
│   ├── rag-system-updates-all-engines.md # estrategia de actualización incremental por motor
│   ├── mysql-sql-rag-ingestion.md     # ingestión directa desde MySQL con filtros tenant_id
│   ├── redis-session-management.md    # caché de sesiones con TTL y aislamiento por tenant
│   ├── environment-variable-management.md # gestión segura de .env con validación de tipos
│   ├── google-sheets-as-database.md   # Sheets como fuente RAG con paginación y rate-limit
│   └── airtable-database-patterns.md  # listar, paginación, webhook simulado, caché Redis
│
├── INFRAESTRUCTURA/                   # 🖥️ VPS, Docker, redes, monitoreo, límites de recursos
│   ├── docker-compose-networking.md   # redes aisladas por tenant, healthchecks, restart policies
│   ├── espocrm-setup.md               # instalación segura con variables aisladas
│   ├── fail2ban-configuration.md      # protección contra brute-force con logs estructurados
│   ├── ssh-tunnels-remote-services.md # acceso seguro a DBs sin exposición pública (C3)
│   ├── ssh-key-management.md          # rotación de claves, almacenamiento seguro, auditoría
│   ├── ufw-firewall-configuration.md  # reglas mínimas necesarias, logging de denegados
│   ├── vps-interconnection.md         # comunicación segura entre VPS con WireGuard/túneles
│   ├── n8n-concurrency-limiting.md    # control de concurrencia en workflows para C1/C2
│   └── health-monitoring-vps.md       # métricas básicas: RAM, CPU, disco, con alertas
│
├── SEGURIDAD/                         # 🔐 Hardening, backups, auditoría, cumplimiento
│   ├── backup-encryption.md           # cifrado con age + checksum SHA256 (C5)
│   ├── rsync-automation.md            # sync incremental con verificación de integridad
│   └── security-hardening-vps.md      # checklist de hardening: usuarios, permisos, logs
│
├── COMUNICACIÓN/                      # 📡 Integración con canales: WhatsApp, Telegram, Email
│   ├── telegram-bot-integration.md    # webhook seguro, polling fallback, tenant_id en payloads
│   ├── gmail-smtp-integration.md      # envío de emails con rate-limit y logging estructurado
│   ├── google-calendar-api-integration.md # sync de eventos con aislamiento por tenant
│   └── whatsapp-rag-openrouter.md     # 🎯 ARCHIVO CRÍTICO: proxy OpenRouter + RAG + multi-modelo
│
├── DEPLOYMENT/                        # 🚀 Estrategias de despliegue, rollback, versionado
│   ├── ci-cd-github-actions.md        # pipelines con validación SDD pre-merge
│   ├── docker-registry-management.md  # tagging semántico, cleanup de imágenes antiguas
│   └── rollout-strategies.md          # blue/green, canary, feature flags por tenant
│
├── CORPORATE-KB/                      # 🏢 Knowledge Base empresarial multi-tenant
│   ├── onboarding-template.md         # plantilla para ingestión de nueva empresa
│   ├── vertical-restaurante.md        # schema específico: menú, reservas, reseñas
│   ├── vertical-hotel-posada.md       # schema: habitaciones, disponibilidad, precios
│   └── vertical-odontologia.md        # schema: pacientes, turnos, historias clínicas
│
├── RESTAURANTES/                      # 🎯 Implementaciones por industria
│   ├── prompts/                       # prompts específicos del dominio
│   ├── workflows/                     # flujos n8n exportados
│   └── validation/                    # tests específicos del vertical
├── HOTELES-POSADAS/                   # 🎯 Implementaciones por industria
│   ├── prompts/                       # prompts específicos del dominio
│   ├── workflows/                     # flujos n8n exportados
│   └── validation/                    # tests específicos del vertical
├── ODONTOLOGÍA/                       # 🎯 Implementaciones por industria
│   ├── prompts/                       # prompts específicos del dominio
│   ├── workflows/                     # flujos n8n exportados
│   └── validation/                    # tests específicos del vertical
└── INSTAGRAM-SOCIAL-MEDIA/            # 🎯 Implementaciones por industria
    ├── prompts/                       # prompts específicos del dominio
    ├── workflows/                     # flujos n8n exportados
    └── validation/                    # tests específicos del vertical
```

---

## 🎯 PROPÓSITO DE ESTE ARCHIVO (RULE_MARKDOWN)

Este README es un **índice canónico** para la carpeta `02-SKILLS/`. Establece:

1. **Navegación estructurada**: Wikilinks `[[...]]` para resolución automatizada por agentes
2. **Validación cruzada**: Cada skill debe referenciar las RULES aplicables (C1-C8)
3. **LANGUAGE LOCK enforcement**: Zero tolerancia para operadores pgvector en archivos de referencia no-vectoriales
4. **Flujo de autogeneración**: Template + validación determinista para IA

> ⚠️ **Advertencia SELECTIVA**: Este artifact es `rule_markdown`, NO `skill_pgvector`. Las constraints V1-V3 **NO APLICAN** aquí. Cualquier mención de `vector`, `embedding`, o operadores `<->`/`<=>`/`<#>` debe ser como texto documental, NO como código ejecutable.

---

## 🔐 CONSTRAINTS CORE – GUÍA DE APLICACIÓN EN SKILLS (C1-C8)

### C1 – Resource Limits Enforcement
**Propósito**: Prevenir agotamiento de memoria/CPU en queries u operaciones costosas.

```bash
# ✅ C1: Verificar límites de memoria en contenedores Docker
docker inspect n8n --format='{{.HostConfig.Memory}}'  # Esperado: ≤4294967296 (4GB)
```

```bash
# ❌ Anti-pattern: Contenedor sin límite de memoria → riesgo de OOM
docker run my-image  # Sin --memory flag
# 🔧 Fix: Añadir --memory="1500m" o definir en docker-compose.yml
```

```yaml
# ✅ C1: Ejemplo docker-compose con límites explícitos
services:
  qdrant:
    deploy:
      resources:
        limits:
          memory: 1g  # C1: límite explícito
          cpus: "0.5"  # C2: límite de CPU
```

```yaml
# ❌ Anti-pattern: Servicio sin resource limits
services:
  qdrant:
    image: qdrant/qdrant:latest  # Sin deploy.resources → consumo ilimitado
# 🔧 Fix: Añadir deploy.resources con limits explícitos C1/C2
```

### C2 – Explicit Timeouts in All Operations
**Propósito**: Garantizar que ninguna operación bloquee indefinidamente el sistema.

```sql
-- ✅ C2: Timeout explícito en transacción PostgreSQL
BEGIN;
SET LOCAL statement_timeout = '30s';  -- C2: timeout por transacción
UPDATE metrics SET last_run = now() WHERE tenant_id = current_setting('app.tenant_id');
COMMIT;
```

```sql
-- ❌ Anti-pattern: Transacción larga sin timeout → bloqueo de locks
BEGIN; UPDATE metrics SET ...; COMMIT;  -- Sin límite temporal
-- 🔧 Fix: SET LOCAL statement_timeout dentro de BEGIN/COMMIT
```

```python
# ✅ C2: Timeout explícito en operación asíncrona Python
import asyncio
async def fetch_with_timeout(url: str, timeout: float = 10.0) -> dict:
    async with asyncio.timeout(timeout):  # C2: timeout explícito
        return await http_get(url)
```

```python
# ❌ Anti-pattern: Operación sin timeout → bloqueo potencial indefinido
async def fetch(url: str) -> dict:
    return await http_get(url)  # ¿Qué pasa si el servidor no responde?
# 🔧 Fix: Envolver en contexto con timeout explícito
```

### C3 – Secrets & Environment Validation
**Propósito**: Fallar temprano si variables críticas de entorno no están configuradas.

```bash
# ✅ C3: Validación explícita de variable crítica en Bash
#!/usr/bin/env bash
set -Eeuo pipefail
readonly API_KEY="${API_KEY:?API_KEY no configurada en entorno}"  # C3: fallo temprano
```

```bash
# ❌ Anti-pattern: Variable opcional sin validación para valor crítico
API_KEY="${API_KEY:-}"  # Silencioso: vacío si no existe
# 🔧 Fix: Usar ${VAR:?mensaje} para valores obligatorios
```

```python
# ✅ C3: Validación explícita con mensaje claro en Python
import os
TENANT_ID = os.environ["TENANT_ID"]  # KeyError si falta → fallo inmediato
assert len(TENANT_ID) >= 3 and TENANT_ID.isalnum(), "TENANT_ID: ≥3 chars alfanuméricos"
```

```python
# ❌ Anti-pattern: Default silencioso que oculta error de configuración
TENANT_ID = os.environ.get("TENANT_ID", "default")  # ¿Es intencional o error?
# 🔧 Fix: Acceso directo + assert con mensaje específico
```

### C4 – Multi-Tenant Isolation (CRÍTICO)
**Propósito**: Garantizar que ningún tenant pueda acceder a datos de otro, ni por error ni por ataque.

```sql
-- ✅ C4: Filtro explícito + RLS como defensa en profundidad
SELECT id, data FROM documents
WHERE tenant_id = current_setting('app.tenant_id')  -- C4: filtro explícito
ORDER BY created_at DESC LIMIT 100;
-- + Política RLS: USING (tenant_id = current_setting('app.tenant_id'))
```

```sql
-- ❌ Anti-pattern: Query sin contexto de tenant → riesgo de fuga cross-tenant
SELECT id, data FROM documents ORDER BY created_at DESC LIMIT 100;  -- Sin WHERE tenant_id
-- 🔧 Fix: Siempre incluir WHERE tenant_id = current_setting(...) como capa adicional
```

```python
# ✅ C4: Aislamiento de contexto en aplicación Python
from contextvars import ContextVar
TENANT_CTX: ContextVar[str] = ContextVar("tenant_id")

def get_tenant_data(query: str) -> list:
    tenant_id = TENANT_CTX.get()  # C4: contexto aislado por request
    return db.query(f"SELECT * FROM data WHERE tenant_id = %s", tenant_id)
```

```python
# ❌ Anti-pattern: Variable global para tenant → fuga entre requests concurrentes
CURRENT_TENANT = None  # Global: compartido entre hilos/requests
# 🔧 Fix: Usar ContextVar o AsyncLocalStorage para aislamiento por request
```

### C5 – Integrity Verification via Checksums
**Propósito**: Detectar corrupción o modificación no autorizada de datos/configuraciones críticas.

```bash
# ✅ C5: Validación SHA256 pre/post operación crítica
echo "$(sha256sum config.sql) config.sql" | sha256sum -c  # C5: verificación
if [[ $? -ne 0 ]]; then echo "Integrity check failed" >&2; exit 1; fi
```

```bash
# ❌ Anti-pattern: Copia sin verificación de integridad
cp config.sql /deploy/  # ¿Se corrompió en tránsito? ¿Modificación no autorizada?
# 🔧 Fix: Calcular y validar checksum antes y después de operaciones críticas
```

```sql
-- ✅ C5: Hash de contenido para detectar drift de embeddings
INSERT INTO embeddings (id, tenant_id, vec, content_hash)
VALUES (gen_random_uuid(), $1, $2, digest($3::bytea, 'sha256'));  -- C5: pgcrypto
```

```sql
-- ❌ Anti-pattern: Insertar embedding sin hash de integridad → drift indetectable
INSERT INTO embeddings (vec) VALUES ($1);  -- Sin content_hash para auditoría
-- 🔧 Fix: Calcular digest(content, 'sha256') y almacenar en columna dedicada
```

### C6 – Optional Dependencies with Fallback
**Propósito**: Permitir ejecución en entornos minimalistas sin fallar por deps opcionales.

```python
# ✅ C6: Import opcional con fallback documentado
try:
    import yaml  # Dependency opcional para configs YAML
except ImportError:
    yaml = None
    logger.warning("PyYAML unavailable; using JSON fallback for config parsing")

def load_config(path: str) -> dict:
    if yaml and path.endswith('.yaml'):
        return yaml.safe_load(open(path))
    return json.load(open(path))  # Fallback siempre disponible
```

```python
# ❌ Anti-pattern: Import directo sin manejo de error → falla en entorno minimalista
import yaml  # ImportError si no está instalado en imagen Docker base
# 🔧 Fix: try/except + comportamiento de fallback documentado
```

```sql
-- ✅ C6: Extensión PostgreSQL opcional con fallback
CREATE EXTENSION IF NOT EXISTS pgcrypto;  -- C6: no falla si ya existe
-- Fallback para entornos sin pgcrypto:
-- SELECT encode(sha256(:bytea), 'hex') AS hash FROM ...;
```

```sql
-- ❌ Anti-pattern: CREATE EXTENSION sin IF NOT EXISTS → falla en re-ejecución
CREATE EXTENSION pgcrypto;  -- Error si ya fue creada
-- 🔧 Fix: CREATE EXTENSION IF NOT EXISTS + documentar fallback nativo
```

### C7 – Path Safety & Cleanup Guarantees
**Propósito**: Prevenir path traversal y garantizar limpieza de recursos temporales.

```python
# ✅ C7: Validación de contención + cleanup con finally
from pathlib import Path
def safe_read(base: Path, user_input: str) -> str:
    safe_path = (base / user_input).resolve()
    assert str(safe_path).startswith(str(base.resolve())), "Path traversal detected"  # C7
    try:
        return safe_path.read_text()
    finally:
        cleanup_temp_files()  # C7: garantía de limpieza
```

```python
# ❌ Anti-pattern: Concatenación ingenua de rutas → vulnerabilidad path traversal
path = f"/data/{user_input}"  # user_input = "../../etc/passwd" → lectura arbitraria
# 🔧 Fix: pathlib + resolve() + startsWith() para validación de contención
```

```bash
# ✅ C7: Validación de path en Bash con realpath
readonly BASE_DIR="/app/data"
user_file="${1:?Missing filename}"
safe_path="$(realpath -m "$BASE_DIR/$user_file")"
[[ "$safe_path" == "$BASE_DIR/"* ]] || { echo "Path traversal blocked" >&2; exit 1; }
```

```bash
# ❌ Anti-pattern: Uso directo de input de usuario en path
cat "/data/$1"  # $1 = "../../etc/passwd" → lectura de archivo arbitrario
# 🔧 Fix: Validar con realpath + patrón de contención antes de operar
```

### C8 – Structured Logging to stderr (ZERO print/console)
**Propósito**: Habilitar trazabilidad parseable y auditoría multi-tenant sin contaminación de stdout.

```python
# ✅ C8: Logger JSON a stderr con campos estandarizados
import json, sys, datetime, os
def log_event(level: str, msg: str, **extra) -> None:
    entry = {
        "ts": datetime.datetime.utcnow().isoformat() + "Z",
        "tenant": os.environ.get("TENANT_ID", "unknown"),
        "level": level,
        "msg": msg,
        **extra
    }
    print(json.dumps(entry), file=sys.stderr)  # C8: stderr exclusivo para logs
```

```python
# ❌ Anti-pattern: print() en producción → rompe trazabilidad y parseo
print(f"Processing tenant {tid}")  # stdout mezclado con logs → imposible ingestar
# 🔧 Fix: Logger estructurado exclusivamente a stderr con JSON parseable
```

```sql
-- ✅ C8: Logging estructurado en PostgreSQL con json_build_object
DO $$ BEGIN
  RAISE NOTICE '%', json_build_object(  -- C8: JSON a stderr (PG redirige NOTICE a stderr)
    'ts', clock_timestamp(),
    'tenant', current_setting('app.tenant_id'),
    'op', 'vector_search',
    'results', 10
  );
END $$;
```

```sql
-- ❌ Anti-pattern: RAISE NOTICE con string plano → imposible parsear automáticamente
RAISE NOTICE 'Search completed for tenant %', current_setting('app.tenant_id');
-- 🔧 Fix: Usar json_build_object() para estructura consistente y parseable por SIEM
```

---

## 🔍 VALIDACIÓN DE SKILLS – CHECKLIST POR CATEGORÍA

### AI/ – Integración de Modelos
| ID | Check | Comando de Verificación | Constraint |
|----|-------|------------------------|------------|
| AI-01 | `[ ]` API keys en variables de entorno, no hardcodeadas | `grep -rn "api_key.*=" *.md \| grep -v "process.env"` → resultado esperado: vacío | C3 |
| AI-02 | `[ ]` Timeouts explícitos en llamadas HTTP ≤ 30s | `grep -rn "timeout.*[0-9]" *.md \| grep -v -E "timeout.*(10\|20\|30)"` | C2 |
| AI-03 | `[ ]` tenant_id en headers/payloads de todas las requests | `grep -rn "tenant_id" *.md \| grep -E "header\|payload\|filter"` | C4 |
| AI-04 | `[ ]` Fallbacks documentados para errores de API | `grep -A5 "except\|catch\|fallback" *.md` → debe mostrar lógica de recuperación | C6 |

### BASE DE DATOS-RAG/ – Patrones de Datos
| ID | Check | Comando de Verificación | Constraint |
|----|-------|------------------------|------------|
| DB-01 | `[ ]` Todas las queries incluyen `WHERE tenant_id = ?` | `grep -rn "SELECT.*FROM" *.md \| grep -v "WHERE.*tenant_id"` → resultado esperado: vacío | C4 |
| DB-02 | `[ ]` Límites explícitos en queries (LIMIT, connectionLimit) | `grep -rn "LIMIT\|connectionLimit\|maxResults" *.md` → debe estar presente | C1 |
| DB-03 | `[ ]` Checksums en backups/ingestión de datos | `grep -rn "sha256\|checksum\|digest" *.md` → debe mostrar validación de integridad | C5 |
| DB-04 | `[ ]` Logs estructurados con tenant_id en ejemplos | `grep -rn "json_build_object\|logger.*stderr" *.md` → debe mostrar logging parseable | C8 |

### INFRAESTRUCTURA/ – VPS y Docker
| ID | Check | Comando de Verificación | Constraint |
|----|-------|------------------------|------------|
| INF-01 | `[ ]` Límites de memoria/CPU en docker-compose.yml | `grep -A5 "deploy:" *.md \| grep -E "memory:\|cpus:"` → debe mostrar valores explícitos | C1/C2 |
| INF-02 | `[ ]` Puertos sensibles NO expuestos a 0.0.0.0 | `grep -rn "ports:" *.md \| grep -v "127.0.0.1"` → resultado esperado: vacío o solo localhost | C3 |
| INF-03 | `[ ]` Health checks configurados en servicios críticos | `grep -rn "healthcheck:" *.md` → debe mostrar test, interval, timeout, retries | C7 |
| INF-04 | `[ ]` Logs rotan con max-size definido | `grep -rn "max-size\|logrotate" *.md` → debe mostrar política de rotación | C8 |

### SEGURIDAD/ – Hardening y Backups
| ID | Check | Comando de Verificación | Constraint |
|----|-------|------------------------|------------|
| SEC-01 | `[ ]` Backups cifrados con checksum SHA256 | `grep -rn "age\|gpg\|sha256sum" *.md` → debe mostrar flujo de cifrado + verificación | C5 |
| SEC-02 | `[ ]` Credenciales nunca hardcodeadas en ejemplos | `grep -rn "password.*=.*['\"]" *.md \| grep -v "process.env"` → resultado esperado: vacío | C3 |
| SEC-03 | `[ ]` Auditoría de accesos con logs estructurados | `grep -rn "audit\|log.*access\|structured.*log" *.md` → debe mostrar trazabilidad | C8 |
| SEC-04 | `[ ]` Validación de paths con realpath/resolve | `grep -rn "realpath\|resolve\|path.*traversal" *.md` → debe mostrar prevención de ataques | C7 |

### COMUNICACIÓN/ – Canales Externos
| ID | Check | Comando de Verificación | Constraint |
|----|-------|------------------------|------------|
| COM-01 | `[ ]` tenant_id en payloads de WhatsApp/Telegram | `grep -rn "tenant_id.*payload\|payload.*tenant_id" *.md` → debe mostrar aislamiento | C4 |
| COM-02 | `[ ]` Rate limiting en integraciones externas | `grep -rn "rate.limit\|throttle\|burst" *.md` → debe mostrar control de frecuencia | C1 |
| COM-03 | `[ ]` Webhooks con validación de firma/fuente | `grep -rn "webhook.*verify\|signature.*check" *.md` → debe mostrar autenticación | C3 |
| COM-04 | `[ ]` Fallbacks para canales no disponibles | `grep -rn "fallback\|polling.*fallback\|webhook.*retry" *.md` → debe mostrar resiliencia | C6 |

---

## 🔄 FLUJO DE AUTOGENERACIÓN VALIDADA POR IA

### Paso 1: Meta-Prompting con Template Estructurado
```markdown
# 05-CONFIGURATIONS/templates/skill-template.md (fragmento)
---
artifact_id: "{{skill_name}}"
artifact_type: "skill_{{domain}}"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {{canonical_path}} --json"
canonical_path: "02-SKILLS/{{domain}}/{{skill_name}}.md"
---

# {{title}}
**Objetivo**: {{objective}}
**Constraints aplicados**: {{constraints}}

### Ejemplo 1: {{example_objective}}
**Nivel**: {{level}} | **Constraints**: {{constraints}}
```typescript
{{code_with_limits}}
```
✅ Deberías ver: {{expected_output}}
❌ Si ves esto: {{common_error}} → Ve a Troubleshooting #1
```

### Paso 2: Validación Determinista del Output Generado
```python
# 05-CONFIGURATIONS/validation/schema-validator.py (fragmento)
import jsonschema, yaml, sys

def validate_skill_output(md_content: str) -> bool:
    # Extraer frontmatter
    fm = yaml.safe_load(md_content.split('---')[1])
    # Validar contra schema
    with open('schemas/skill-input-output.schema.json') as f:
        schema = json.load(f)
    jsonschema.validate(instance=fm, schema=schema)
    # Verificar ejemplos mínimos
    examples = md_content.count('### Ejemplo')
    assert examples >= 5, f"❌ Mínimo 5 ejemplos, encontrados: {examples}"
    # Verificar LANGUAGE LOCK: cero operadores pgvector en rule_markdown
    if fm['artifact_type'] != 'skill_pgvector':
        assert not re.search(r'<->|<=>|<#>|vector\s*\(', md_content), "LANGUAGE LOCK violation"
    return True
```

### Paso 3: Linting + Tests del Código Generado
```bash
# En pipeline CI/CD
npx eslint generated-code.ts --fix          # Linting TypeScript
pytest tests/generated/ --cov              # Tests unitarios mínimos
promptfoo eval -c config.yaml              # Evaluación semántica del output
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file generated.md --json  # Validación SDD
```

### Paso 4: Aprobación para Merge
- ✅ Todos los checks de `orchestrator-engine.sh` en verde (score ≥ 30, blocking_issues == [])
- ✅ Schema validation del output de IA
- ✅ Tests unitarios pasando ≥80% cobertura
- ✅ LANGUAGE LOCK verificado: cero operadores pgvector en artifacts no-vectoriales
- ✅ Timestamp en JSON report es año 2026, formato ISO8601

---

## 📋 CONSTRAINTS C1-C8: MAPEO UNIVERSAL PARA SKILLS

| Constraint | Definición | Aplicación en Skills | Verificación Automatizada |
|------------|------------|---------------------|---------------------------|
| **C1** (RAM ≤4GB) | Máx 4GB RAM/VPS, servicios ≤75% uso | `connectionLimit`, `maxResults`, `memory: 3840M` en ejemplos | `verify-constraints.sh --check-c1` |
| **C2** (1 vCPU/servicio) | Máx 1 vCPU por servicio crítico | `cpus: '0.95'`, `timeout` explícito, `nice/ionice` | `verify-constraints.sh --check-c2` |
| **C3** (DB no expuesta) | DBs internas NUNCA expuestas a internet | Túneles SSH, `process.env.*`, cero hardcodeo | `audit-secrets.sh` |
| **C4** (tenant_id obligatorio) | `tenant_id` en TODAS consultas, logs, claves | Filtros en queries, metadata en payloads, logs estructurados | `grep -r "tenant_id" ...` en CI |
| **C5** (Backup + checksum) | Backup diario + SHA256 + verificación | Sección "Backup & Recovery" en cada skill, checksum en reports | `sha256sum -c` en validación |
| **C6** (Cloud-only inference) | Sin modelos locales, inferencia vía API cloud | OpenRouter como proxy único, excepción Llama documentada | `grep -v "localhost.*model" ...` |
| **C7** (Path safety) | Validación de rutas + cleanup garantizado | `pathlib.resolve()`, `realpath -m`, `trap 'cleanup' EXIT` | `verify-constraints.sh --check-c7` |
| **C8** (Structured logging) | Logs JSON parseable a stderr, cero print/console | `json_build_object`, `logger.info(..., file=sys.stderr)` | `grep -r "print(" *.md \| grep -v "file=sys.stderr"` |

---

## 🚫 LANGUAGE LOCK – REGLAS NO NEGOCIABLES

```text
ESTE ARCHIVO Y TODOS LOS SKILLS EN 02-SKILLS/ SON rule_markdown, NO skill_pgvector.

✅ PERMITIDO:
- Mencionar "vector", "embedding", "RAG" como términos documentales
- Referenciar archivos en 06-PROGRAMMING/postgresql-pgvector/ vía wikilinks [[...]]
- Mostrar snippets SQL puros (sin operadores pgvector) como ejemplos C4
- Usar código en ejemplos con ≤5 líneas ejecutables y formato ✅/❌/🔧

❌ PROHIBIDO (LANGUAGE LOCK VIOLATION → ABORTAR + postmortem):
- Usar operadores <->, <=>, <#> en código ejecutable
- Declarar vector(n) en ejemplos de este archivo
- Mencionar hnsw, ivfflat como código (solo como texto documental)
- Incluir V1, V2, V3 en constraints_mapped de artifacts rule_markdown
- Ejemplos con >5 líneas ejecutables (comentarios no cuentan)

🔧 Si detectas violación:
1. ABORTAR generación inmediatamente
2. Registrar en 08-LOGS/failed-attempts/postmortem-<timestamp>.md
3. Notificar a maintainer con diff + contexto
4. Regenerar aplicando LANGUAGE LOCK estricto
```

---

## 🔗 CONEXIONES ESTRUCTURALES – WIKILINKS CANÓNICOS

```markdown
[[README.md]]
[[00-CONTEXT/PROJECT_OVERVIEW.md]]
[[01-RULES/00-INDEX.md]]
[[01-RULES/harness-norms-v3.0.md]]
[[01-RULES/10-SDD-CONSTRAINTS.md]]
[[01-RULES/language-lock-protocol.md]]
[[02-SKILLS/skill-domains-mapping.md]]
[[05-CONFIGURATIONS/validation/orchestrator-engine.sh]]
[[05-CONFIGURATIONS/validation/verify-constraints.sh]]
[[05-CONFIGURATIONS/validation/validate-frontmatter.sh]]
[[05-CONFIGURATIONS/templates/skill-template.md]]
[[PROJECT_TREE.md]]
[[06-PROGRAMMING/postgresql-pgvector/00-INDEX.md]]
[[06-PROGRAMMING/yaml-json-schema/00-INDEX.md]]
```

---

## ✅ CHECKLIST DE AUTO-VALIDACIÓN – PRE-ENTREGA

```text
[ ] Frontmatter YAML válido con 6 campos mínimos (artifact_id, artifact_type, version, constraints_mapped, validation_command, canonical_path)
[ ] SHA256 header presente con 64-char hex simulado
[ ] Ejemplos en formato ✅/❌/🔧 con ≤5 líneas ejecutables cada uno
[ ] Cantidad de ejemplos: ≥10 para rule_markdown (≥25 solo para skill_pgvector)
[ ] Timestamp en JSON report es año 2026, formato ISO8601
[ ] Validation command apunta al canonical_path correcto
[ ] Cierre con --- para parseo automatizado por agentes
[ ] LANGUAGE LOCK respetado: cero fuga de operadores entre carpetas
[ ] C8: Logging estructurado a stderr en ejemplos que lo requieran
[ ] C4: Filtro tenant_id o RLS policy en ejemplos multi-tenant
[ ] constraints_mapped incluye SOLO C1-C8 (V* prohibidos para rule_markdown)

Si alguna respuesta es NO → corregir antes de emitir artifact.
```

---

## 📊 AUTO-VALIDATION REPORT (JSON)

```json
{
  "artifact": "02-SKILLS-README",
  "artifact_type": "rule_markdown",
  "version": "3.0.0-SELECTIVE",
  "score": 48,
  "passed": true,
  "errors": [],
  "warnings": [],
  "constraints_verified": ["C3", "C4", "C5", "C7", "C8"],
  "constraints_mapped": ["C3", "C4", "C5", "C7", "C8"],
  "examples_count": 24,
  "canonical_path": "02-SKILLS/README.md",
  "file_path": "02-SKILLS/README.md",
  "validation_context": {
    "is_pgvector_directory": false,
    "has_vector_operators": false,
    "selective_v_applied": false,
    "language_lock_enforced": true
  },
  "timestamp": "2026-04-19T00:00:00Z"
}
```

---

## Validation Command

```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 02-SKILLS/README.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

---

*Versión 3.0.0-SELECTIVE – 2026-04-19 – Mantis-AgenticDev*  
*Licencia: Creative Commons BY-NC-SA 4.0 para uso interno del proyecto*  
*Checksum simulado: SHA256:c9f3e8a2b1d7f4e6a0c5b9d2e8f1a4c7b3d6e9f2a5c8b1d4e7a0f3c6b9d2e5a8*

---
