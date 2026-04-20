---
canonical_path: "/01-RULES/06-MULTITENANCY-RULES.md"
artifact_id: "multitenancy-rules-canonical"
artifact_type: "governance_rule_set"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C4", "C5", "C6", "C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 01-RULES/06-MULTITENANCY-RULES.md --mode headless --json"
tier: 1
immutable: true
requires_human_approval_for_changes: true
related_files:
  - "[[00-STACK-SELECTOR.md]]"
  - "[[AI-NAVIGATION-CONTRACT.md]]"
  - "[[GOVERNANCE-ORCHESTRATOR.md]]"
  - "[[05-CONFIGURATIONS/validation/norms-matrix.json]]"
  - "[[05-CONFIGURATIONS/validation/check-rls.sh]]"
  - "[[06-PROGRAMMING/sql/row-level-security-policies.sql.md]]"
checksum_sha256: "PENDING_GENERATION"
---

# 📄 01-RULES/06-MULTITENANCY-RULES.md – REGENERADO v3.0-SELECTIVE

> **Nota para principiantes:** Este documento define las reglas inamovibles para aislamiento multi-tenant en MANTIS AGENTIC. Si eres nuevo, lee las secciones en orden. Si eres experto, salta al JSON final.  
>  
> **Para IAs:** Este es tu contrato de aislamiento. **VIOLAR C4 = BLOQUEO INMEDIATO**. No inventes, no asumas, no omitas.


# 🔐 06-MULTITENANCY-RULES: Contrato de Aislamiento Multi-Tenant (C4 Enforcement)

<!-- 
【PARA PRINCIPIANTES】¿Qué es este archivo?
Este documento es el "contrato de aislamiento" del proyecto MANTIS AGENTIC.
Define las reglas inamovibles para garantizar que los datos de cada cliente (tenant) 
nunca se mezclen con los de otro.

Si eres nuevo: lee en orden. 
Si ya conoces el proyecto: usa los wikilinks para ir directo a lo que necesitas.
-->

> **Instrucción crítica para la IA:** 
> Este documento es tu contrato de aislamiento. 
> **VIOLAR C4 = BLOQUEO INMEDIATO**. 
> No inventes, no asumas, no omitas. Si algo no está claro, DETENER y preguntar.

---

## 【0】🎯 PROPÓSITO Y ALCANCE (Explicado para humanos)

<!-- 
【EDUCATIVO】Este documento responde: "¿Cómo garantizo que el Cliente A nunca vea datos del Cliente B?"
No es solo una lista de reglas. Es un sistema de contención que:
• Previene fuga de datos entre tenants desde el diseño
• Garantiza que cada query, log y API request respete el aislamiento
• Permite auditoría forense de accesos por tenant
-->

### 0.1 C4: Tenant Isolation – Definición Canónica

```
C4 (Tenant Isolation): Todo acceso a datos debe estar scoped por tenant_id.
Ninguna query, API response, log o cache puede exponer datos de un tenant a otro.

✅ Cumplimiento: WHERE tenant_id = $1 en cada query, payload filtering en Qdrant, tenant-scoped logs
❌ Violación: SELECT * FROM messages sin WHERE tenant_id, logs con datos de múltiples tenants
```

### 0.2 Mapeo C4 → Herramientas de Validación

| Herramienta | Propósito | Comando de Validación |
|------------|-----------|---------------------|
| `check-rls.sh` | Validar que queries SQL incluyen `WHERE tenant_id = ?` | `bash 05-CONFIGURATIONS/validation/check-rls.sh --file query.sql.md --json` |
| `verify-constraints.sh` | Verificar que artifacts declaran C4 en constraints_mapped | `bash 05-CONFIGURATIONS/validation/verify-constraints.sh --file artifact.md --json` |
| `orchestrator-engine.sh` | Validación integral con scoring y reporte JSON | `bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file artifact.md --json` |

> 💡 **Consejo para principiantes**: No memorices todas las reglas. Usa `check-rls.sh` para validar queries SQL automáticamente.

---

## 【1】🔒 REGLAS INAMOVIBLES DE AISLAMIENTO (MT-001 a MT-010)

<!-- 
【EDUCATIVO】Estas 10 reglas son contractuales. 
Cualquier violación es blocking_issue en validación.
-->

### MT-001: tenant_id Obligatorio en Todas las Tablas

```
【REGLA MT-001】Campo tenant_id obligatorio en todas las tablas de datos.

✅ Cumplimiento:
• Tipo: VARCHAR(50) o UUID, NOT NULL
• INDEX obligatorio: INDEX idx_tenant (tenant_id)
• FOREIGN KEY a tabla tenants si aplica
• Validado en cada consulta: WHERE tenant_id = ?

❌ Violación crítica:
• Tabla sin campo tenant_id
• tenant_id nullable o sin índice
• Query sin filtro WHERE tenant_id = ?

【EJEMPLO SQL ✅】
CREATE TABLE messages (
  id UUID PRIMARY KEY,
  tenant_id VARCHAR(50) NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  INDEX idx_tenant_created (tenant_id, created_at)
);

SELECT * FROM messages 
WHERE tenant_id = $1 AND created_at > $2
ORDER BY created_at DESC 
LIMIT 50;

【EJEMPLO SQL ❌】
-- NUNCA USAR: falta filtro tenant_id
SELECT * FROM messages WHERE created_at > $1;
```

### MT-002: Aislamiento en Bases de Datos Vectoriales (Qdrant/pgvector)

```
【REGLA MT-002】Cada tenant debe tener aislamiento estricto en búsqueda vectorial.

✅ Opción A (Recomendada): Colección/índice por tenant
• Qdrant: collection_name = "rag_{tenant_id}"
• pgvector: tabla embeddings con WHERE tenant_id = $1

✅ Opción B: Filtro estricto en payload
• Qdrant filter: { "must": [{ "key": "tenant_id", "match": { "value": "{tenant_id}" } }] }
• pgvector: WHERE tenant_id = $1 en cada query vectorial

❌ Violación crítica:
• Query vectorial sin filtro tenant_id
• Colección compartida sin filtering por payload

【EJEMPLO QDRANT ✅】
{
  "collection_name": "rag_cliente_001",
  "filter": {
    "must": [
      { "key": "tenant_id", "match": { "value": "cliente_001" } }
    ]
  }
}

【EJEMPLO PGVECTOR ✅】
SELECT id, content, embedding <=> $1 AS similarity
FROM embeddings
WHERE tenant_id = $2
ORDER BY similarity ASC
LIMIT 10;
```

### MT-003: Validación de tenant_id en Cada Request Entrante

```
【REGLA MT-003】Todo request API debe validar tenant_id antes de procesar.

✅ Flujo obligatorio:
1. Extraer tenant_id de header (X-Tenant-ID) o token JWT claims
2. Validar que tenant_id existe en tabla tenants y está activo
3. Inyectar tenant_id en contexto de ejecución (no confiar en input del usuario)
4. Rechazar request con 403 si tenant_id inválido
5. Loguear acceso con tenant_id para auditoría (C8)

❌ Violación crítica:
• Procesar request sin validar tenant_id
• Usar tenant_id de query params sin validación
• Loguear datos sensibles de otros tenants

【EJEMPLO MIDDLEWARE GO ✅】
func tenantMiddleware(next http.Handler) http.Handler {
  return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
    tenantID := r.Header.Get("X-Tenant-ID")
    if tenantID == "" {
      http.Error(w, "missing tenant_id", http.StatusBadRequest)
      return
    }
    if !tenantExists(tenantID) { // Validar en DB/cache
      http.Error(w, "invalid tenant_id", http.StatusForbidden)
      return
    }
    ctx := context.WithValue(r.Context(), "tenant_id", tenantID)
    next.ServeHTTP(w, r.WithContext(ctx))
  })
}
```

### MT-004: Nunca Exponer Datos Entre Tenants

```
【REGLA MT-004】Datos de un tenant nunca deben ser visibles para otro.

✅ Cumplimiento:
• Queries siempre scoped por tenant_id
• APIs retornan solo datos del tenant autenticado
• Logs scrubbed: ***REDACTED*** para datos de otros tenants
• Debug mode deshabilitado en producción

❌ Violación crítica:
• Endpoint que retorna datos de múltiples tenants sin autorización
• Log que incluye contenido de mensajes de otro tenant
• Error message que expone IDs de otros tenants

【EJEMPLO API RESPONSE ✅】
{
  "data": [/* solo mensajes del tenant autenticado */],
  "meta": {
    "tenant_id": "cliente_001",
    "count": 10
  }
}

【EJEMPLO LOG ✅ (C8 + C4)】
{
  "timestamp": "2026-04-19T12:00:00Z",
  "tenant_id": "cliente_001",
  "event": "message_processed",
  "status": "success",
  "details": {
    "message_id": "***REDACTED***",
    "tokens_used": 42
  }
}
```

### MT-005: tenant_id en Logs de Auditoría (C4 + C8)

```
【REGLA MT-005】Todos los logs deben incluir tenant_id para trazabilidad forense.

✅ Formato de log canónico:
{
  "timestamp": "2026-04-19T12:00:00Z",  // RFC3339 UTC
  "level": "INFO|WARN|ERROR",
  "tenant_id": "cliente_001",            // Obligatorio
  "event": "query_executed",
  "query_hash": "sha256:abc123...",      // Para auditoría sin exponer query
  "rows_affected": 10,
  "duration_ms": 42
}

✅ Scrubbing de PII (C3 + C8):
• Campos sensibles: password, token, api_key, content → ***REDACTED***
• tenant_id siempre visible para auditoría

❌ Violación crítica:
• Log sin tenant_id
• Log que expone contenido de mensajes de otros tenants
• Log con secrets hardcodeados

【EJEMPLO LOGGING GO ✅ (C8)】
logger := slog.New(slog.NewJSONHandler(os.Stderr, &slog.HandlerOptions{
  ReplaceAttr: func(groups []string, a slog.Attr) slog.Attr {
    if a.Key == "content" || a.Key == "password" {
      return slog.String(a.Key, "***REDACTED***")
    }
    return a
  },
}))
logger.Info("query_executed", 
  "tenant_id", tenantID,
  "query_hash", sha256sum(query),
  "rows_affected", rows,
)
```

### MT-006: Backups y Restauración por Tenant

```
【REGLA MT-006】Backups deben permitir restauración individual por tenant.

✅ Cumplimiento:
• MySQL: mysqldump con WHERE tenant_id = 'X' o tablas separadas
• Qdrant: snapshot por colección (una por tenant)
• Metadata de backup: incluir tenant_id, timestamp, checksum

✅ Restauración segura:
• Validar tenant_id antes de restaurar
• No sobrescribir datos de otros tenants
• Log de restauración con tenant_id para auditoría

❌ Violación crítica:
• Backup que mezcla datos de múltiples tenants sin metadata
• Restauración que sobrescribe datos de otro tenant

【EJEMPLO BACKUP MYSQL ✅】
#!/bin/bash
TENANT_ID="$1"
mysqldump --where="tenant_id='$TENANT_ID'" \
  --single-transaction \
  mantis_db \
  messages embeddings interactions \
  | gzip > backup_${TENANT_ID}_$(date +%Y%m%d).sql.gz

# Metadata adjunta
echo "{\"tenant_id\":\"$TENANT_ID\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"checksum\":\"$(sha256sum backup_*.sql.gz)\"}" > backup_${TENANT_ID}.meta.json
```

### MT-007: Límites de Recursos por Tenant (C1 + C4)

```
【REGLA MT-007】Cada tenant debe tener límites de recursos definidos y enforceados.

✅ Límites recomendados (ajustables por plan):
| Recurso | Límite por Tenant | Herramienta de Enforcement |
|---------|-----------------|---------------------------|
| Requests API/min | 30 | Rate limiter con tenant_id como key |
| Mensajes/día | 1000 | Counter en Redis con TTL 24h |
| Vectores Qdrant | 10000 | Quota en colección por tenant |
| Almacenamiento MySQL | 500 MB | Quota por schema o tabla partitioned |
| Tokens LLM/día | 50000 | Counter con tenant_id + modelo |

✅ Enforcement automático:
• Retornar 429 Too Many Requests cuando se excede límite
• Log de límite excedido con tenant_id para auditoría
• Notificación al tenant antes de bloqueo (opcional)

❌ Violación crítica:
• Límites globales sin scoping por tenant (un tenant puede agotar recursos de otros)
• No loguear excedentes de límite

【EJEMPLO RATE LIMITING GO ✅】
type TenantLimiter struct {
  limit int
  burst int
  store *redis.Client
}

func (l *TenantLimiter) Allow(tenantID string) bool {
  key := fmt.Sprintf("rate_limit:%s", tenantID)
  count, _ := l.store.Get(context.Background(), key).Int()
  if count >= l.limit {
    return false // 429 Too Many Requests
  }
  l.store.Incr(context.Background(), key)
  l.store.Expire(context.Background(), key, 60*time.Second)
  return true
}
```

### MT-008: tenant_id en EspoCRM y Sistemas Externos

```
【REGLA MT-008】Integraciones con sistemas externos deben respetar aislamiento por tenant.

✅ Cumplimiento para EspoCRM:
• Usar Teams de EspoCRM mapeados a tenant_id
• Configurar permisos: Team solo ve sus propios records
• Validar tenant_id en cada llamada a EspoCRM API
• Log de integración con tenant_id para auditoría

✅ Cumplimiento para otras integraciones (n8n, WhatsApp, Telegram):
• Inyectar tenant_id en payload de webhooks
• Validar tenant_id en respuestas de APIs externas
• Nunca exponer tenant_id de otro cliente en logs o errores

❌ Violación crítica:
• Webhook que procesa datos de múltiples tenants sin validación
• Error message que expone tenant_id de otro cliente

【EJEMPLO WEBHOOK VALIDATION ✅】
func validateWebhookTenant(payload WebhookPayload, expectedTenant string) error {
  if payload.TenantID != expectedTenant {
    return fmt.Errorf("tenant mismatch: expected %s, got %s", expectedTenant, payload.TenantID)
  }
  // Validar firma HMAC para integridad
  if !verifyHMAC(payload.Signature, payload.Body, webhookSecret) {
    return errors.New("invalid signature")
  }
  return nil
}
```

### MT-009: Test de Aislamiento Obligatorio

```
【REGLA MT-009】Test de aislamiento entre tenants debe ejecutarse automáticamente en CI/CD.

✅ Test obligatorio (ejecutar en cada merge a main):
1. Crear tenants de test: tenant_A, tenant_B
2. Insertar datos sensibles en tenant_A
3. Intentar acceder a datos de tenant_A desde contexto de tenant_B
4. Verificar que acceso es denegado (403 o rows=0)
5. Log de resultado del test con tenant_id de ambos

✅ Frecuencia:
• CI/CD: en cada pull request que modifique queries o APIs
• Producción: primer sábado de cada mes (automatizado)

❌ Violación crítica:
• Test de aislamiento no ejecutado en CI/CD
• Test que pasa pero no valida denial de acceso

【EJEMPLO TEST GO ✅】
func TestTenantIsolation(t *testing.T) {
  tenantA := "test_tenant_a"
  tenantB := "test_tenant_b"
  
  // Insertar dato en tenant A
  db.Exec("INSERT INTO messages (tenant_id, content) VALUES ($1, $2)", tenantA, "secret_A")
  
  // Intentar acceder desde contexto de tenant B
  rows, err := db.Query("SELECT content FROM messages WHERE tenant_id = $1", tenantB)
  if err != nil { t.Fatal(err) }
  defer rows.Close()
  
  // Verificar que no se retornan datos de tenant A
  if rows.Next() {
    t.Errorf("isolation breach: tenant B accessed tenant A data")
  }
}
```

### MT-010: Auditoría Forense de Accesos por Tenant

```
【REGLA MT-010】Todos los accesos a datos deben ser auditables por tenant_id.

✅ Cumplimiento:
• Log estructurado JSON a stderr con tenant_id en cada evento
• Query hash (SHA256) en lugar de query completa para auditoría sin exposición
• Retención de logs: 90 días para debug, 7 años para compliance
• Exportación a SIEM/OpenTelemetry para monitoreo centralizado

✅ Campos obligatorios en log de auditoría:
{
  "timestamp": "2026-04-19T12:00:00Z",  // RFC3339 UTC
  "tenant_id": "cliente_001",            // Obligatorio (C4)
  "event": "query_executed|api_call|auth_attempt",
  "actor": "user:facundo|agent:qwen-3.5",
  "resource": "messages:select|embeddings:upsert",
  "result": "success|denied|error",
  "query_hash": "sha256:abc123...",      // Para reproducibilidad sin exposición
  "duration_ms": 42,
  "trace_id": "otel-trace-xyz"           // Para correlación distribuida
}

❌ Violación crítica:
• Log sin tenant_id
• Log que expone query completa con datos sensibles
• Log sin timestamp RFC3339 o sin trace_id para correlación

【EJEMPLO AUDIT LOGGING ✅ (C4 + C8)】
func auditLog(ctx context.Context, event string, resource string, result string) {
  tenantID := ctx.Value("tenant_id").(string)
  traceID := trace.SpanFromContext(ctx).SpanContext().TraceID().String()
  
  slog.InfoContext(ctx, event,
    "tenant_id", tenantID,
    "resource", resource,
    "result", result,
    "trace_id", traceID,
    // Nunca loguear datos sensibles directamente
  )
}
```

---

## 【2】🛡️ VALIDACIÓN AUTOMÁTICA DE C4 (Toolchain Integration)

<!-- 
【EDUCATIVO】Estas herramientas permiten validar automáticamente el cumplimiento de C4.
Úsalas en CI/CD y pre-commit para prevenir deuda técnica.
-->

### 2.1 check-rls.sh – Validación de Tenant Isolation en SQL

```bash
# 📍 Ubicación
05-CONFIGURATIONS/validation/check-rls.sh

# 🎯 Propósito
Validar que queries SQL incluyen cláusulas de aislamiento por tenant_id (C4).

# 📦 Flags Principales
--file <ruta>              # Archivo SQL a validar
--dir <directorio>         # Validar directorio de queries SQL
--tenant-column <nombre>   # Nombre de la columna de tenant (default: tenant_id)
--strict                   # Modo estricto: fallar si falta tenant_id en cualquier query SELECT/UPDATE/DELETE
--json                     # Salida en formato JSON

# ✅ Ejemplo: Validar query individual
bash 05-CONFIGURATIONS/validation/check-rls.sh \
  --file 06-PROGRAMMING/sql/crud-with-tenant-enforcement.sql.md \
  --tenant-column tenant_id \
  --json

# 📤 Salida Esperada (JSON)
{
  "file": "06-PROGRAMMING/sql/user-queries.sql.md",
  "queries_analyzed": 5,
  "queries_with_tenant_filter": 5,
  "queries_without_tenant_filter": 0,
  "findings": [],
  "passed": true,
  "recommendation": "✅ Todas las queries incluyen filtro por tenant_id. Isolación multi-tenant verificada."
}

# ⚠️ Patrones Válidos vs Inválidos
| Query ✅ Válida | Query ❌ Inválida | Corrección 🔧 |
|----------------|-----------------|--------------|
| `SELECT * FROM users WHERE tenant_id = $1` | `SELECT * FROM users` | Agregar `WHERE tenant_id = $1` |
| `UPDATE orders SET status = $2 WHERE id = $1 AND tenant_id = $3` | `UPDATE orders SET status = $2 WHERE id = $1` | Agregar `AND tenant_id = $3` |
```

### 2.2 verify-constraints.sh – Validación de Declaración de C4

```bash
# 📍 Ubicación
05-CONFIGURATIONS/validation/verify-constraints.sh

# 🎯 Propósito
Validar que artifacts declaran C4 en constraints_mapped cuando aplican.

# ✅ Ejemplo: Validar artifact Markdown
bash 05-CONFIGURATIONS/validation/verify-constraints.sh \
  --file 06-PROGRAMMING/python/langchain-integration.md \
  --check-constraint C4 \
  --json

# 📤 Salida Esperada (JSON)
{
  "file": "06-PROGRAMMING/python/langchain-integration.md",
  "constraint_checked": "C4",
  "declared_in_frontmatter": true,
  "applies_to_domain": true,
  "passed": true
}
```

### 2.3 orchestrator-engine.sh – Validación Integral con Scoring

```bash
# 📍 Ubicación
05-CONFIGURATIONS/validation/orchestrator-engine.sh

# 🎯 Propósito
Validación completa con scoring, incluyendo C4 enforcement.

# ✅ Ejemplo: Validar artifact para Tier 2
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/sql/crud-with-tenant-enforcement.sql.md \
  --mode headless \
  --json

# 📤 Criterios de Aceptación para C4
| Tier | C4 Enforcement Requerido | blocking_issue si falla |
|------|-------------------------|------------------------|
| 1    | Advertencia si falta C4 en frontmatter | No (solo warning) |
| 2    | C4 obligatorio si artifact accede a datos | ✅ Sí (blocking) |
| 3    | C4 + audit logging + tenant-scoped backup | ✅ Sí (blocking) |
```

---

## 【3】🧭 PROTOCOLO DE IMPLEMENTACIÓN DE C4 (PASO A PASO)

<!-- 
【EDUCATIVO】Este es el flujo determinista para implementar aislamiento multi-tenant.
Mismos inputs → mismos outputs. Si algo no está claro, DETENER y preguntar.
-->

```
┌─────────────────────────────────────────────────────────┐
│ 【FASE 0】DISEÑO DE SCHEMA CON tenant_id               │
├─────────────────────────────────────────────────────────┤
│ 1. Añadir tenant_id VARCHAR(50) NOT NULL a todas las tablas │
│ 2. Crear INDEX idx_tenant (tenant_id) en cada tabla    │
│ 3. Definir FOREIGN KEY a tabla tenants si aplica       │
│ 4. Documentar en frontmatter: constraints_mapped: ["C4"]│
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 1】VALIDACIÓN DE QUERIES CON check-rls.sh       │
├─────────────────────────────────────────────────────────┤
│ 1. Ejecutar: check-rls.sh --dir 06-PROGRAMMING/sql/ --json │
│ 2. Corregir queries sin WHERE tenant_id = ?            │
│ 3. Re-ejecutar hasta passed: true                      │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 2】INTEGRACIÓN CON MIDDLEWARE DE VALIDACIÓN     │
├─────────────────────────────────────────────────────────┤
│ 1. Implementar tenantMiddleware en API layer           │
│ 2. Validar tenant_id en cada request entrante          │
│ 3. Inyectar tenant_id en contexto de ejecución         │
│ 4. Loguear accesos con tenant_id (C8)                  │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 3】TEST DE AISLAMIENTO EN CI/CD                 │
├─────────────────────────────────────────────────────────┤
│ 1. Añadir test de aislamiento a suite de tests         │
│ 2. Ejecutar en cada pull request que modifique queries │
│ 3. Fallar build si test de aislamiento no pasa         │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 4】AUDITORÍA FORENSE CON LOGS ESTRUCTURADOS     │
├─────────────────────────────────────────────────────────┤
│ 1. Configurar logging estructurado JSON a stderr       │
│ 2. Incluir tenant_id en cada log event                 │
│ 3. Scrubear PII/secrets antes de loguear (C3 + C8)     │
│ 4. Exportar logs a SIEM/OpenTelemetry para monitoreo   │
└─────────────────────────────────────────────────────────┘
```

### 3.1 Ejemplo de Traza de Implementación de C4

```
【TRAZA DE IMPLEMENTACIÓN C4】
Tarea: "Añadir aislamiento multi-tenant a módulo de mensajes"

Fase 0 - Diseño de schema:
  • Añadir tenant_id VARCHAR(50) NOT NULL a tabla messages ✅
  • Crear INDEX idx_tenant_created (tenant_id, created_at) ✅
  • Documentar en frontmatter: constraints_mapped: ["C4", "C5"] ✅

Fase 1 - Validación de queries:
  • Ejecutar check-rls.sh --dir 06-PROGRAMMING/sql/ --json
  • Corregir 2 queries sin WHERE tenant_id = ? ✅
  • Re-ejecutar: passed: true, queries_with_tenant_filter: 10/10 ✅

Fase 2 - Middleware de validación:
  • Implementar tenantMiddleware en Go ✅
  • Validar tenant_id desde header X-Tenant-ID ✅
  • Inyectar tenant_id en context.Context ✅
  • Loguear accesos con tenant_id (C8) ✅

Fase 3 - Test de aislamiento:
  • Añadir TestTenantIsolation a suite de tests ✅
  • Ejecutar en CI/CD: test pasa ✅
  • Configurar fallo de build si test no pasa ✅

Fase 4 - Auditoría forense:
  • Configurar slog JSON handler a stderr ✅
  • Incluir tenant_id en cada log event ✅
  • Scrubear contenido de mensajes en logs ✅
  • Exportar logs a OpenTelemetry ✅

Resultado: ✅ Módulo de mensajes con aislamiento multi-tenant certificado C4.
```

---

## 【4】📚 GLOSARIO PARA PRINCIPIANTES

<!-- 
【EDUCATIVO】Términos técnicos explicados en lenguaje simple.
-->

| Término | Significado simple | Ejemplo |
|---------|-------------------|---------|
| **tenant_id** | Identificador único de cada cliente en el sistema | `cliente_001`, `agricola-x`, `restaurante-y` |
| **C4 (Tenant Isolation)** | Regla que garantiza que los datos de un cliente nunca se mezclen con los de otro | `WHERE tenant_id = $1` en cada query |
| **RLS (Row-Level Security)** | Mecanismo de base de datos que filtra filas por tenant_id automáticamente | PostgreSQL RLS policies |
| **Scrubbear PII** | Reemplazar datos personales por `***REDACTED***` en logs | Log: `content=***REDACTED***` en lugar de contenido real |
| **Query hash** | SHA256 de una query para auditoría sin exponer la query completa | `query_hash: "sha256:abc123..."` |
| **Rate limiting por tenant** | Límite de requests/API calls específico para cada cliente | 30 requests/min por tenant_id |
| **Audit log** | Registro estructurado de accesos a datos para trazabilidad forense | JSON con timestamp, tenant_id, event, result |
| **FOREIGN KEY tenant_id** | Relación de base de datos que vincula tablas a la tabla de tenants | `FOREIGN KEY (tenant_id) REFERENCES tenants(tenant_id)` |

---

## 【5】🧪 SANDBOX DE PRUEBA (OPCIONAL)

<!-- 
【PARA DESARROLLADORES】Pega esta sección en un chat nuevo para validar que la IA sigue el protocolo sin contexto previo.
-->

```
【TEST MODE: MULTITENANCY-RULES VALIDATION】
Prompt de prueba: "Validar query SQL para módulo de mensajes multi-tenant"

Respuesta esperada de la IA:
1. Identificar que la tarea requiere aislamiento multi-tenant (C4)
2. Consultar 01-RULES/06-MULTITENANCY-RULES.md para reglas MT-001 a MT-010
3. Validar query con check-rls.sh:
   • Verificar que incluye WHERE tenant_id = ?
   • Verificar que tenant_id tiene índice
   • Verificar que no expone datos de otros tenants
4. Si query es válida → retornar con frontmatter: constraints_mapped: ["C4", "C5"]
5. Si query es inválida → retornar error estructurado:
   "❌ BLOCKING_ISSUE: query sin filtro tenant_id. Corrección: agregar WHERE tenant_id = $1"
6. Incluir validation_command: check-rls.sh --file <query> --json

Si la IA retorna query sin WHERE tenant_id, omite validación con check-rls.sh, 
o no declara C4 en constraints_mapped → FALLA DE AISLAMIENTO C4.
```

---

## 【6】🔗 REFERENCIAS CANÓNICAS (WIKILINKS)

<!-- 
【PARA IA】Estos enlaces deben resolverse usando PROJECT_TREE.md. 
No uses rutas relativas. Usa siempre la forma canónica [[RUTA]].
-->

- `[[00-STACK-SELECTOR]]` → Motor de decisión: ruta → lenguaje → constraints
- `[[AI-NAVIGATION-CONTRACT]]` → Reglas inamovibles: C4 es fail-fast
- `[[GOVERNANCE-ORCHESTRATOR]]` → Tiers: C4 obligatorio para Tier 2+
- `[[05-CONFIGURATIONS/validation/norms-matrix.json]]` → Mapeo C4 por carpeta
- `[[05-CONFIGURATIONS/validation/check-rls.sh]]` → Validación automática de tenant_id en SQL
- `[[06-PROGRAMMING/sql/row-level-security-policies.sql.md]]` → Patrones RLS para PostgreSQL
- `[[06-PROGRAMMING/go/microservices-tenant-isolation.go.md]]` → Patrones de aislamiento en Go

---

## 【7】📦 METADATOS DE EXPANSIÓN (PARA FUTURAS VERSIONES)

<!-- 
【PARA MANTENEDORES】Nuevas secciones deben seguir este formato para no romper compatibilidad.
-->

```json
{
  "expansion_registry": {
    "new_multitenancy_rule": {
      "requires_files_update": [
        "01-RULES/06-MULTITENANCY-RULES.md: add rule with format ## MT-XXX: <TÍTULO>",
        "05-CONFIGURATIONS/validation/check-rls.sh: update validation logic if rule affects SQL",
        "norms-matrix.json: update constraint mapping if rule introduces new requirement",
        "GOVERNANCE-ORCHESTRATOR.md: update tier definitions if rule affects validation",
        "Human approval required: true"
      ],
      "backward_compatibility": "new rules must not invalidate existing artifacts that comply with current C4 definition"
    },
    "new_database_support": {
      "requires_files_update": [
        "01-RULES/06-MULTITENANCY-RULES.md: add section for new DB (ej: MongoDB, DynamoDB)",
        "05-CONFIGURATIONS/validation/check-rls.sh: add support for new DB query syntax",
        "06-PROGRAMMING/: add language-specific patterns for new DB",
        "Human approval required: true"
      ],
      "backward_compatibility": "new database support must not break existing SQL/PostgreSQL patterns"
    }
  },
  "compatibility_rule": "Nuevas reglas de multi-tenencia no deben invalidar artefactos generados bajo versiones anteriores. Cambios breaking requieren major version bump, guía de migración y aprobación humana explícita."
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
Prioridad de ejecución: Las reglas se aplican en orden MT-001 → MT-010.
Dependencias: Cada nodo declara sus archivos requeridos y sus efectos colaterales.
═══════════════════════════════════════════════════════════
-->

```json
{
  "multitenancy_rules_metadata": {
    "version": "3.0.0-SELECTIVE",
    "canonical_path": "/01-RULES/06-MULTITENANCY-RULES.md",
    "artifact_type": "governance_rule_set",
    "immutable": true,
    "requires_human_approval_for_changes": true,
    "constraint_primary": "C4",
    "llm_optimizations": {
      "oriental_models_friendly": true,
      "delimiters_used": ["【】", "┌─┐", "▼", "✅/❌/🔧"],
      "numbered_sequences": true,
      "stop_conditions_explicit": true
    }
  },
  
  "rules_catalog": {
    "MT-001": {
      "title": "tenant_id Obligatorio en Todas las Tablas",
      "constraint": "C4",
      "priority": "critical",
      "blocking_if_violated": true,
      "validation_tool": "check-rls.sh",
      "applicable_domains": ["sql", "postgresql-pgvector", "mysql"],
      "doc_description": "Campo tenant_id NOT NULL + INDEX obligatorio en todas las tablas de datos."
    },
    "MT-002": {
      "title": "Aislamiento en Bases de Datos Vectoriales",
      "constraint": "C4",
      "priority": "critical",
      "blocking_if_violated": true,
      "validation_tool": "verify-constraints.sh --check-vector-tenant",
      "applicable_domains": ["postgresql-pgvector", "qdrant"],
      "doc_description": "Colección por tenant o filtro estricto por tenant_id en payload."
    },
    "MT-003": {
      "title": "Validación de tenant_id en Cada Request",
      "constraint": "C4",
      "priority": "critical",
      "blocking_if_violated": true,
      "validation_tool": "orchestrator-engine.sh --check-tenant-middleware",
      "applicable_domains": ["go", "python", "javascript"],
      "doc_description": "Extraer, validar e inyectar tenant_id en contexto de ejecución."
    },
    "MT-004": {
      "title": "Nunca Exponer Datos Entre Tenants",
      "constraint": "C4",
      "priority": "critical",
      "blocking_if_violated": true,
      "validation_tool": "audit-secrets.sh + manual review",
      "applicable_domains": ["ALL"],
      "doc_description": "Queries, APIs, logs y errores nunca exponen datos de otros tenants."
    },
    "MT-005": {
      "title": "tenant_id en Logs de Auditoría",
      "constraint": "C4 + C8",
      "priority": "high",
      "blocking_if_violated": false,
      "validation_tool": "orchestrator-engine.sh --check-logging",
      "applicable_domains": ["go", "python", "javascript"],
      "doc_description": "Todos los logs incluyen tenant_id para trazabilidad forense."
    },
    "MT-006": {
      "title": "Backups y Restauración por Tenant",
      "constraint": "C4 + C7",
      "priority": "high",
      "blocking_if_violated": false,
      "validation_tool": "manual audit + packager-assisted.sh",
      "applicable_domains": ["bash", "terraform"],
      "doc_description": "Backups permiten restauración individual sin afectar otros tenants."
    },
    "MT-007": {
      "title": "Límites de Recursos por Tenant",
      "constraint": "C1 + C4",
      "priority": "medium",
      "blocking_if_violated": false,
      "validation_tool": "orchestrator-engine.sh --check-rate-limits",
      "applicable_domains": ["go", "python", "redis"],
      "doc_description": "Cada tenant tiene límites de recursos enforceados automáticamente."
    },
    "MT-008": {
      "title": "tenant_id en EspoCRM y Sistemas Externos",
      "constraint": "C4",
      "priority": "high",
      "blocking_if_violated": true,
      "validation_tool": "verify-constraints.sh --check-external-integrations",
      "applicable_domains": ["espocrm", "n8n", "webhooks"],
      "doc_description": "Integraciones externas respetan aislamiento por tenant_id."
    },
    "MT-009": {
      "title": "Test de Aislamiento Obligatorio",
      "constraint": "C4 + C6",
      "priority": "high",
      "blocking_if_violated": true,
      "validation_tool": "go test -run TestTenantIsolation",
      "applicable_domains": ["testing", "ci-cd"],
      "doc_description": "Test de aislamiento ejecutado en CI/CD y mensualmente en producción."
    },
    "MT-010": {
      "title": "Auditoría Forense de Accesos por Tenant",
      "constraint": "C4 + C8",
      "priority": "high",
      "blocking_if_violated": false,
      "validation_tool": "orchestrator-engine.sh --check-audit-logs",
      "applicable_domains": ["logging", "observability"],
      "doc_description": "Todos los accesos a datos son auditables por tenant_id con logs estructurados."
    }
  },
  
  "validation_integration": {
    "check-rls.sh": {
      "purpose": "Validar tenant_id en queries SQL",
      "flags": ["--file", "--dir", "--tenant-column", "--strict", "--json"],
      "exit_codes": {"0": "passed", "1": "failed"},
      "output_format": "JSON con queries_analyzed, queries_with_tenant_filter, findings"
    },
    "verify-constraints.sh": {
      "purpose": "Validar declaración de C4 en frontmatter",
      "flags": ["--file", "--check-constraint", "--json"],
      "exit_codes": {"0": "passed", "1": "failed"},
      "output_format": "JSON con constraint_checked, declared_in_frontmatter, passed"
    },
    "orchestrator-engine.sh": {
      "purpose": "Validación integral con scoring y C4 enforcement",
      "flags": ["--file", "--mode", "--json", "--checks"],
      "exit_codes": {"0": "passed", "1": "failed"},
      "output_format": "JSON con score, passed, blocking_issues, constraints_applied"
    }
  },
  
  "dependency_graph": {
    "critical_infrastructure": [
      {"file": "05-CONFIGURATIONS/validation/norms-matrix.json", "purpose": "Mapear C4 como fail-fast constraint", "load_order": 1},
      {"file": "05-CONFIGURATIONS/validation/check-rls.sh", "purpose": "Validación automática de tenant_id en SQL", "load_order": 2},
      {"file": "06-PROGRAMMING/sql/row-level-security-policies.sql.md", "purpose": "Patrones RLS para PostgreSQL", "load_order": 3}
    ],
    "implementation_patterns": [
      {"file": "06-PROGRAMMING/go/microservices-tenant-isolation.go.md", "purpose": "Patrones de aislamiento en Go", "load_order": 1},
      {"file": "06-PROGRAMMING/python/testing-multi-tenant-patterns.md", "purpose": "Patrones de testing multi-tenant", "load_order": 2}
    ]
  },
  
  "human_readable_errors": {
    "missing_tenant_id_column": "Tabla '{table}' no tiene campo tenant_id. Agregar: tenant_id VARCHAR(50) NOT NULL, INDEX idx_tenant (tenant_id).",
    "query_without_tenant_filter": "Query en archivo '{file}' no incluye WHERE tenant_id = ?. Agregar filtro para cumplir C4.",
    "tenant_validation_missing": "Request handler en '{file}' no valida tenant_id. Implementar tenantMiddleware antes de procesar datos.",
    "log_without_tenant_id": "Log en '{file}' no incluye tenant_id. Agregar campo tenant_id para auditoría forense (C4 + C8).",
    "isolation_test_failed": "Test de aislamiento falló: tenant_B accedió a datos de tenant_A. Revisar queries y middleware de validación."
  },
  
  "expansion_hooks": {
    "new_database_support": {
      "requires_files_update": [
        "01-RULES/06-MULTITENANCY-RULES.md: add section for new DB with tenant_id patterns",
        "05-CONFIGURATIONS/validation/check-rls.sh: add parser for new DB query syntax",
        "06-PROGRAMMING/: add language-specific patterns for new DB",
        "Human approval required: true"
      ],
      "backward_compatibility": "new database support must not break existing SQL/PostgreSQL patterns"
    },
    "new_tenant_strategy": {
      "requires_files_update": [
        "01-RULES/06-MULTITENANCY-RULES.md: document new strategy (ej: schema-per-tenant)",
        "05-CONFIGURATIONS/validation/: add validation logic for new strategy",
        "GOVERNANCE-ORCHESTRATOR.md: update tier definitions if strategy affects validation",
        "Human approval required: true"
      ],
      "backward_compatibility": "new strategies must not invalidate existing artifacts that use current tenant_id approach"
    }
  },
  
  "validation_metadata": {
    "orchestrator_compatibility": ">=3.0.0-SELECTIVE",
    "schema_version": "multitenancy-rules.v1.json",
    "checksum_algorithm": "SHA256",
    "audit_log_format": "JSON Lines with RFC3339 timestamps",
    "pii_scrubbing": "enabled for all logs (C3 + C8 compliance)",
    "reproducibility_guarantee": "Any tenant isolation validation can be reproduced identically using this rule set + check-rls.sh"
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
# 1. Verificar que el frontmatter es YAML válido
yq eval '.canonical_path' 01-RULES/06-MULTITENANCY-RULES.md
# Esperado: "/01-RULES/06-MULTITENANCY-RULES.md"

# 2. Verificar que constraints_mapped incluye C4 (crítico)
yq eval '.constraints_mapped | contains(["C4"])' 01-RULES/06-MULTITENANCY-RULES.md
# Esperado: true

# 3. Verificar que las 10 reglas MT-001 a MT-010 están presentes
grep -c "MT-0[0-9][0-9]:" 01-RULES/06-MULTITENANCY-RULES.md | awk '{if($1==10) print "✅ 10 reglas presentes"; else print "⚠️ Faltan reglas"}'

# 4. Verificar que check-rls.sh está referenciado para validación SQL
grep -q "check-rls.sh" 01-RULES/06-MULTITENANCY-RULES.md && echo "✅ Validación automática documentada"

# 5. Validar que la sección JSON final es parseable
tail -n +$(grep -n '```json' 01-RULES/06-MULTITENANCY-RULES.md | tail -1 | cut -d: -f1) 01-RULES/06-MULTITENANCY-RULES.md | \
  sed -n '/```json/,/```/p' | sed '1d;$d' | jq empty && echo "✅ JSON válido"

# 6. Validar con orchestrator (simulación mental)
# - ¿El archivo está en 01-RULES/? → SÍ
# - ¿El lenguaje es markdown con reglas de gobernanza? → SÍ
# - ¿Constraints aplicables según norms-matrix.json? → C4 mandatory → SÍ
# - ¿validation_command es ejecutable? → SÍ, apunta a orchestrator-engine.sh
```
````

**Criterio de aceptación:**  
- ✅ Frontmatter válido con `canonical_path: "/01-RULES/06-MULTITENANCY-RULES.md"`  
- ✅ `constraints_mapped` incluye C4 (fail-fast) + C5, C6, C8  
- ✅ 10 reglas MT-001 a MT-010 documentadas con ejemplos ✅/❌/🔧  
- ✅ Integración con `check-rls.sh` para validación automática de SQL  
- ✅ Sección JSON final es válida (puede parsearse con `jq .`)  
- ✅ Todos los wikilinks apuntan a archivos existentes en `PROJECT_TREE.md`  

---

> 🎯 **Mensaje final para el lector humano**:  
> Este contrato es tu garantía de aislamiento. No es opcional.  
> **tenant_id → WHERE → FILTER → LOG → AUDIT**.  
> Si sigues ese flujo, nunca mezclarás datos de clientes.  
> La gobernanza no es una carga. Es la libertad de escalar sin miedo a romper. 
