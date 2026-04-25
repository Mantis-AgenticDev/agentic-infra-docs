---
artifact_id: sql-master-agent-mantis
artifact_type: agentic_skill_definition
version: 1.0.0
constraints_mapped: ["C1","C2","C3","C4","C5","C7","C8"]
canonical_path: 06-PROGRAMMING/sql/sql-master-agent.md
tier: 1
language_lock: ["sql","postgresql","mysql"]
governance_severity: warning
validation_hooks:
  - verify-constraints.sh
  - audit-secrets.sh
  - check-rls.sh
---
# 🗄️ SQL Master Agent para MANTIS AGENTIC

> **Dominio**: Referencia técnica / Fine-tuning para IAs (`06-PROGRAMMING/sql/`)  
> **Severidad de validación**: 🟡 **AMARILLA** (warning informativo, no bloqueo)  
> **Stack permitido**: SQL estándar, PostgreSQL, MySQL, SQLite, SQL Server (ANSI SQL 2016+)  
> **Constraints declaradas**: C1-C8 (recursos, seguridad, estructura) — **CERO operadores vectoriales V1-V3** (LANGUAGE LOCK)

---

## 🎯 Propósito Atómico

Ser el **único punto de verdad** para desarrollo SQL dentro de MANTIS AGENTIC:
- ✅ Generar queries production-ready con enforcement de tenant (C4) y aislamiento multi-tenant
- ✅ Aplicar LANGUAGE LOCK: **prohibido** usar `<->`, `<#>`, `cosine_distance` en SQL estándar (solo en `postgresql-pgvector/`)
- ✅ Validar que todo artifact generado declare `constraints_mapped` coherente
- ✅ Emitir output estructurado: JSON a `stdout`, logs a `stderr`, JSONL a `08-LOGS/`
- ✅ **Enseñar mientras genera**: explicar patrones de optimización, decisiones de índices y alternativas para facilitar tu aprendizaje

---

## 🔐 Contrato de Gobernanza (V-INT COMPLIANT)

### Frontmatter Obligatorio en Todo Artifact Generado
```yaml
---
artifact_id: <kebab-case-único>
artifact_type: sql_query | sql_migration | sql_pattern | sql_optimization
version: <semver>
constraints_mapped: ["C3","C4","C5", ...]  # Mínimo: C3, C4, C5 para producción
canonical_path: 06-PROGRAMMING/sql/<archivo>.sql.md
tier: 1 | 2 | 3
---
```

### Constraints Aplicadas por Contexto
| Constraint | Qué exige | Ejemplo de declaración válida |
|------------|-----------|------------------------------|
| **C1-C2** (Recursos) | Límites de tiempo de ejecución, uso de índices | `SET statement_timeout = '30s'` ✅ |
| **C3** (Secrets) | Cero hardcode de credenciales. Uso de placeholders | `WHERE api_key = $1` ✅ |
| **C4** (Tenant Isolation) | Queries con `WHERE tenant_id = $1` o políticas RLS | `SELECT * FROM docs WHERE tenant_id = $1` ✅ |
| **C5** (Estructura) | SQL válido ANSI + `canonical_path` coherente | Ver ejemplo abajo ✅ |
| **C7** (Resiliencia) | Manejo de errores con transacciones, rollback | `BEGIN; ...; COMMIT;` o `ROLLBACK;` ✅ |
| **C8** (Observabilidad) | Logging estructurado de queries, tracing con OpenTelemetry | `/* trace_id: abc123 */ SELECT ...` ✅ |

### 🔒 LANGUAGE LOCK: Matriz de Operadores Vectoriales (SQL)
| Operador | Permitido en SQL estándar | Bloqueado en SQL estándar |
|----------|-------------------------|-------------------------|
| `<->` (L2 distance) | ❌ **NUNCA** en SQL estándar | Cualquier uso en script SQL |
| `<#>` (inner product) | ❌ **NUNCA** en SQL estándar | Cualquier uso en script SQL |
| `cosine_distance()` | ❌ **NUNCA** en SQL estándar | Cualquier uso en script SQL |
| `pgvector` extension | ❌ **NUNCA** en SQL estándar | `CREATE EXTENSION vector` en SQL |

> ⚠️ **Nota contractual**: SQL estándar es para **consultas relacionales, transacciones y optimización**, NO para ejecución de queries vectoriales. Si necesitas vectores, delega a `06-PROGRAMMING/postgresql-pgvector/`.

---

## 🧠 Capacidades Integradas (Todas las Skills de SQL)

### 1. 🎨 Modern SQL Features & ANSI Compliance
```sql
-- SQL estándar con características modernas (ANSI SQL 2016+)
WITH RECURSIVE org_chart AS (
  SELECT id, name, manager_id, 1 AS level
  FROM employees
  WHERE manager_id IS NULL
  UNION ALL
  SELECT e.id, e.name, e.manager_id, oc.level + 1
  FROM employees e
  INNER JOIN org_chart oc ON e.manager_id = oc.id
)
SELECT * FROM org_chart ORDER BY level, name;

-- Window functions para análisis
SELECT 
  user_id,
  order_date,
  amount,
  SUM(amount) OVER (PARTITION BY user_id ORDER BY order_date) AS running_total,
  ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY order_date DESC) AS rn
FROM orders
WHERE tenant_id = $1;  -- ✅ C4: tenant isolation
```

### 2. ⚡ Query Optimization & Index Strategies
```sql
-- Índices estratégicos con CONCURRENTLY (PostgreSQL)
CREATE INDEX CONCURRENTLY idx_orders_tenant_created 
ON orders(tenant_id, created_at DESC) 
WHERE status = 'active';

-- Query optimizada con EXPLAIN ANALYZE
EXPLAIN ANALYZE
SELECT o.id, o.total, u.name
FROM orders o
JOIN users u ON o.user_id = u.id
WHERE o.tenant_id = $1
  AND o.created_at > NOW() - INTERVAL '30 days'
ORDER BY o.created_at DESC
LIMIT 20;

-- Evitar N+1 con JOINs eficientes
SELECT u.id, u.name, COUNT(o.id) AS order_count
FROM users u
LEFT JOIN orders o ON u.id = o.user_id AND o.tenant_id = $1
WHERE u.tenant_id = $1
GROUP BY u.id, u.name
HAVING COUNT(o.id) > 0;
```

### 3. 🛡️ Multi-Tenant Isolation & RLS Policies
```sql
-- Row-Level Security (PostgreSQL) para aislamiento multi-tenant
CREATE POLICY tenant_isolation_policy ON documents
  FOR ALL
  USING (tenant_id = current_setting('app.current_tenant_id')::uuid);

-- Query con enforcement explícito de tenant (C4)
SELECT * FROM documents
WHERE tenant_id = $1  -- ✅ Parámetro obligatorio
  AND status = 'published'
ORDER BY created_at DESC
LIMIT 50;

-- Validación de tenant en transacciones
BEGIN;
SET LOCAL app.current_tenant_id = $1;
-- Queries within transaction automatically filtered by RLS
COMMIT;
```

### 4. 🧪 Testing Patterns & Validation Queries
```sql
-- Queries de validación para testing de calidad de datos
-- Completitud: verificar NULLs en campos críticos
SELECT COUNT(*) AS null_count
FROM users
WHERE tenant_id = $1
  AND (email IS NULL OR name IS NULL);

-- Unicidad: detectar duplicados
SELECT email, COUNT(*) AS dup_count
FROM users
WHERE tenant_id = $1
GROUP BY email
HAVING COUNT(*) > 1;

-- Consistencia: validar rangos de valores
SELECT COUNT(*) AS invalid_count
FROM orders
WHERE tenant_id = $1
  AND (total_amount < 0 OR total_amount > 1000000);
```

### 5. 🔄 Migration Patterns & Zero-Downtime Strategies
```sql
-- Migración con patrón expand-contract (PostgreSQL)
-- Fase 1: EXPAND (backward compatible)
ALTER TABLE users ADD COLUMN email_verified BOOLEAN DEFAULT FALSE;
CREATE INDEX CONCURRENTLY idx_users_email_verified ON users(email_verified) WHERE email_verified = true;

-- Fase 2: MIGRATE DATA (en batches para evitar locks)
DO $$
DECLARE
  batch_size INT := 10000;
  rows_updated INT;
BEGIN
  LOOP
    UPDATE users
    SET email_verified = (email_confirmation_token IS NOT NULL)
    WHERE tenant_id = $1  -- ✅ C4: tenant isolation en migración
      AND email_verified IS NULL
      AND id IN (
        SELECT id FROM users 
        WHERE tenant_id = $1 
          AND email_verified IS NULL 
        LIMIT batch_size
      );
    
    GET DIAGNOSTICS rows_updated = ROW_COUNT;
    EXIT WHEN rows_updated = 0;
    COMMIT;
    PERFORM pg_sleep(0.1);  -- Evitar saturación
  END LOOP;
END $$;

-- Fase 3: CONTRACT (después de deploy de código)
ALTER TABLE users DROP COLUMN email_confirmation_token;
```

### 6. 🔐 Security Hardening & SQL Injection Prevention
```sql
-- Parámetros preparados para prevenir inyección SQL
-- ✅ Correcto: placeholders $1, $2, etc.
SELECT * FROM users 
WHERE tenant_id = $1 
  AND email = $2;

-- ❌ Incorrecto: concatenación directa (vulnerable)
-- EXECUTE format('SELECT * FROM users WHERE email = %L', user_input);

-- Validación de input con CHECK constraints
CREATE TABLE users (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL,
  email TEXT NOT NULL CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT fk_users_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id)
);

-- Encriptación de datos sensibles (PostgreSQL pgcrypto)
INSERT INTO users (tenant_id, email, password_hash)
VALUES ($1, $2, crypt($3, gen_salt('bf')));  -- bcrypt hashing
```

### 7. 🗄️ Database Performance & Connection Management
```sql
-- Configuración de pool de conexiones (PostgreSQL)
-- En aplicación: max_connections, pool_size, timeout
-- En DB: shared_buffers, work_mem, effective_cache_size

-- Query con timeout para evitar bloqueos prolongados
SET statement_timeout = '30s';
SET lock_timeout = '10s';

SELECT * FROM large_table
WHERE tenant_id = $1
  AND created_at > NOW() - INTERVAL '7 days';

-- Uso de materialized views para queries complejas
CREATE MATERIALIZED VIEW tenant_order_summary AS
SELECT 
  tenant_id,
  DATE_TRUNC('day', created_at) AS order_date,
  COUNT(*) AS order_count,
  SUM(total_amount) AS daily_revenue
FROM orders
GROUP BY tenant_id, DATE_TRUNC('day', created_at);

-- Refresh concurrent para evitar locks
REFRESH MATERIALIZED VIEW CONCURRENTLY tenant_order_summary;
```

### 8. 📊 Analytics & Business Intelligence Queries
```sql
-- Cohort analysis para retención de usuarios
WITH user_cohorts AS (
  SELECT 
    tenant_id,
    user_id,
    DATE_TRUNC('month', created_at) AS cohort_month,
    ROW_NUMBER() OVER (PARTITION BY tenant_id, user_id ORDER BY created_at) AS activity_month
  FROM user_activities
  WHERE tenant_id = $1
)
SELECT 
  cohort_month,
  activity_month - cohort_month AS months_since_signup,
  COUNT(DISTINCT user_id) AS active_users
FROM user_cohorts
GROUP BY cohort_month, months_since_signup
ORDER BY cohort_month, months_since_signup;

-- Funnel analysis para conversión
WITH funnel_steps AS (
  SELECT 
    tenant_id,
    user_id,
    event_name,
    created_at,
    ROW_NUMBER() OVER (PARTITION BY tenant_id, user_id ORDER BY created_at) AS step_order
  FROM events
  WHERE tenant_id = $1
    AND event_name IN ('view_product', 'add_to_cart', 'checkout', 'purchase')
)
SELECT 
  event_name,
  COUNT(DISTINCT user_id) AS users_at_step,
  ROUND(100.0 * COUNT(DISTINCT user_id) / 
    FIRST_VALUE(COUNT(DISTINCT user_id)) OVER (ORDER BY MIN(created_at)), 2) AS conversion_rate
FROM funnel_steps
GROUP BY event_name
ORDER BY MIN(created_at);
```

---

## 🔄 Integración con Toolchain de Validación MANTIS

### Hook para `verify-constraints.sh`
```bash
# Al generar un artifact SQL, auto-validar frontmatter y constraints
./05-CONFIGURATIONS/validation/verify-constraints.sh --file "$ARTIFACT_PATH" | jq -e .
```

### Hook para `audit-secrets.sh`
```bash
# Escanear código SQL en busca de secrets hardcodeados
./05-CONFIGURATIONS/validation/audit-secrets.sh --file "$ARTIFACT_PATH"
```

### Hook para `check-rls.sh`
```bash
# Validar que queries incluyan WHERE tenant_id = $1 o políticas RLS
./05-CONFIGURATIONS/validation/check-rls.sh --file "$ARTIFACT_PATH"
```

### Logging JSONL Dashboard-Ready (V-LOG-02)
```sql
-- Cada ejecución genera entrada JSONL en:
-- 08-LOGS/validation/test-orchestrator-engine/sql-master/YYYY-MM-DD_HHMMSS.jsonl

-- Ejemplo de logging estructurado en aplicación (no en SQL puro)
-- En Python/Go/JS: log_query(query, tenant_id, duration, result_count)
```

---

## 🧪 Ejemplos: Válido vs Inválido (Para Testing del Agente)

### ✅ Artifact Válido (`tenant-isolation-query.sql.md`)
```sql
---
artifact_id: tenant-isolation-query
artifact_type: sql_query
version: 1.0.0
constraints_mapped: ["C3","C4","C5"]
canonical_path: 06-PROGRAMMING/sql/tenant-isolation-query.sql.md
tier: 1
---
# Query con aislamiento multi-tenant y optimización

## ✅ C4: tenant_id obligatorio en WHERE
SELECT o.id, o.total, u.name
FROM orders o
JOIN users u ON o.user_id = u.id
WHERE o.tenant_id = $1  -- ✅ Parámetro obligatorio
  AND u.tenant_id = $1  -- ✅ Consistencia en JOIN
  AND o.status = 'completed'
ORDER BY o.created_at DESC
LIMIT 50;

## ✅ C5: Query válido ANSI SQL + índices sugeridos
-- Índices recomendados:
-- CREATE INDEX idx_orders_tenant_status ON orders(tenant_id, status) WHERE status = 'completed';
-- CREATE INDEX idx_users_tenant_id ON users(tenant_id, id);
```

### ❌ Artifact Inválido (`broken-vector-sql.sql.md`)
```sql
---
artifact_id: broken-vector-sql
artifact_type: sql_query
version: 1.0.0
constraints_mapped: ["C5"]  # ❌ Falta C3 y C4
canonical_path: 06-PROGRAMMING/sql/broken-vector-sql.sql.md
tier: 1
---
# Query con violaciones de constraints

## ❌ C3: Secret hardcodeado en query
SELECT * FROM config 
WHERE api_key = 'sk-prod-xxx-hardcoded';  -- ❌ Nunca hardcodear

## ❌ C4: Sin tenant_id filter
SELECT * FROM documents 
WHERE status = 'published';  -- ❌ Falta WHERE tenant_id = $1

## ❌ LANGUAGE LOCK: Operador vectorial en SQL estándar (prohibido)
SELECT * FROM embeddings 
WHERE vector_column <-> $1 < 0.3;  -- ❌ Operadores vectoriales solo en postgresql-pgvector/
```

**Resultado esperado de validación**:
- `verify-constraints.sh`: `passed=false` (missing C3, C4 + LANGUAGE LOCK violation)
- `audit-secrets.sh`: `passed=false` (hardcoded secret)
- `check-rls.sh`: `passed=false` (missing tenant isolation)
- Exit code: `1` (bloqueo en CI/CD para producción, warning para referencia)

---

## 📋 Checklist Pre-Generación (Para el Agente)

Antes de emitir cualquier query SQL, el agente debe verificar:

- [ ] **SQL válido**: Sintaxis ANSI SQL 2016+ compatible con PostgreSQL/MySQL
- [ ] **Constraints declaradas**: Consultar `norms-matrix.json` para la ruta destino
- [ ] **LANGUAGE LOCK**: CERO operadores vectoriales (`<->`, `<#>`, `cosine_distance`) en SQL estándar
- [ ] **C3 (Secrets)**: Usar placeholders `$1`, `$2`, nunca hardcode
- [ ] **C4 (Tenant)**: Queries para producción deben incluir `WHERE tenant_id = $1` o políticas RLS
- [ ] **Separación de canales**: JSON a `stdout`, logs humanos a `stderr`
- [ ] **Optimización**: Sugerir índices, evitar SELECT *, usar LIMIT para paginación
- [ ] **Testing**: Incluir queries de validación cuando aplique
- [ ] **Migraciones**: Seguir patrón expand-contract para cambios de esquema

---

## 🤝 Comportamiento del Agente (Behavioral Traits)

| Trait | Implementación contractual |
|-------|---------------------------|
| **No inventa datos** | Siempre consulta `norms-matrix.json` antes de declarar constraints |
| **Directo y realista** | Emite warnings claros cuando detecta desviaciones, sin adular |
| **Amiga en lo personal** | Si el usuario pregunta fuera de scope, aconseja sin rigidez, pero mantiene el contrato técnico |
| **Enseña mientras genera** | Explica patrones de optimización, decisiones de índices y alternativas en comentarios para facilitar tu aprendizaje |
| **Validación primero** | Antes de emitir query, ejecuta hooks de validación locales (`check-rls.sh --dry-run`) |
| **Trazabilidad total** | Todo artifact generado incluye `canonical_path` y `timestamp` para auditoría forense |
| **LANGUAGE LOCK estricto** | Bloquea cualquier intento de usar operadores vectoriales en SQL estándar |

---

## 🔗 Referencias Contractuales

| Documento | Propósito | URL Raw |
|-----------|-----------|---------|
| `GOVERNANCE-ORCHESTRATOR.md` | Motor de certificación Tiers 1/2/3 | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/GOVERNANCE-ORCHESTRATOR.md) |
| `norms-matrix.json` | Fuente de verdad: constraints por carpeta | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/norms-matrix.json) |
| `VALIDATOR_DEV_NORMS.md` | Normas para desarrollo de validadores | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/VALIDATOR_DEV_NORMS.md) |
| `verify-constraints.sh` | Validador de coherencia declarativa | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/verify-constraints.sh) |
| `check-rls.sh` | Validador de aislamiento multi-tenant en SQL | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/check-rls.sh) |

---

> 📌 **Nota final**: Este artifact es Tier 1 (referencia educativa). Cualquier modificación debe pasar validación automática antes de merge.  
> 🇧🇷 *Documentação técnica completa disponível em*: `docs/pt-BR/programming/sql/sql-master-agent/README.md` (próxima entrega).
```

---

## 🔗 RAW_URLS_INDEX – Patrones SQL Disponibles

> **Propósito**: Fuente de verdad para que el agente consulte patrones, normas y contratos sin inventar datos.

### 🏛️ Gobernanza Raíz (Contratos Inmutables)
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/GOVERNANCE-ORCHESTRATOR.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/00-STACK-SELECTOR.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/AI-NAVIGATION-CONTRACT.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/IA-QUICKSTART.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/PROJECT_TREE.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/SDD-COLLABORATIVE-GENERATION.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/TOOLCHAIN-REFERENCE.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/norms-matrix.json
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/knowledge-graph.json
```

### 📜 Normas y Constraints (01-RULES)
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/harness-norms-v3.0.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/language-lock-protocol.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/10-SDD-CONSTRAINTS.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/03-SECURITY-RULES.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/06-MULTITENANCY-RULES.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/validation-checklist.md
```

### 🧰 Toolchain de Validación (05-CONFIGURATIONS/validation)
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/VALIDATOR_DEV_NORMS.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/norms-matrix.json
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/orchestrator-engine.sh
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/verify-constraints.sh
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/audit-secrets.sh
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/check-rls.sh
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/schema-validator.py
```

### 🗄️ Patrones SQL Core (06-PROGRAMMING/sql)
```text
# Auditoría y Logging
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/audit-logging-triggers.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/audit-trail-ia-generated.sql.md

# Backup y Recuperación
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/backup-restore-tenant-scoped.sql.md

# Seguridad y Encriptación
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/column-encryption-patterns.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/permission-scoping-for-ia.sql.md

# Contexto e IA
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/context-injection-for-ia.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/ia-query-validation-gate.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/mcp-sql-tool-definitions.json.md

# Testing e Integración
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/integration-test-fixtures.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/join-patterns-rls-aware.sql.md

# Migraciones y Rollback
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/rollback-automation-patterns.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/schema-diff-validation.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/tenant-context-injection.sql.md

# Patrones de Testing Unitario (subdirectorio)
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/unit-test-patterns/01-clean-rls-compliant.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/unit-test-patterns/02-missing-where-tenant.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/unit-test-patterns/03-bypass-comment.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/unit-test-patterns/04-edge-special-chars.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/unit-test-patterns/05-multi-violations.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/unit-test-patterns/06-large-stress.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/unit-test-patterns/07-missing-file-error.sql.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/unit-test-patterns/08-context-exception.sql.md
```

### 🦜 Referencias Vectoriales (SOLO para consulta, NO para uso en SQL estándar)
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/00-INDEX.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/tenant-isolation-for-embeddings.pgvector.md
```

### 🔄 Workflows y CI/CD
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/.github/workflows/validate-mantis.yml
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/04-WORKFLOWS/sdd-universal-assistant.json
```

### 📚 Skills de Referencia
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/README.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/skill-domains-mapping.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/INFRASTRUCTURA/ssh-key-management.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/INFRASTRUCTURA/health-monitoring-vps.md
```

### 🌐 Documentación pt-BR (Obligatoria para validadores)
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/validation-tools/TEMPLATE-VALIDATOR.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/validation-tools/verify-constraints/README.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/validation-tools/check-rls/README.md
```

---

## 🗂️ RUTAS CANÓNICAS LOCALES – Patrones SQL (Para Acceso en Repo)

> **Formato**: `RAW_URL` → `./ruta/local/en/repo`

### 🗄️ Patrones SQL Core
```text
# Auditoría y Logging
06-PROGRAMMING/sql/audit-logging-triggers.sql.md
06-PROGRAMMING/sql/audit-trail-ia-generated.sql.md

# Backup y Recuperación
06-PROGRAMMING/sql/backup-restore-tenant-scoped.sql.md

# Seguridad y Encriptación
06-PROGRAMMING/sql/column-encryption-patterns.sql.md
06-PROGRAMMING/sql/permission-scoping-for-ia.sql.md

# Contexto e IA
06-PROGRAMMING/sql/context-injection-for-ia.sql.md
06-PROGRAMMING/sql/ia-query-validation-gate.sql.md
06-PROGRAMMING/sql/mcp-sql-tool-definitions.json.md

# Testing e Integración
06-PROGRAMMING/sql/integration-test-fixtures.sql.md
06-PROGRAMMING/sql/join-patterns-rls-aware.sql.md

# Migraciones y Rollback
06-PROGRAMMING/sql/rollback-automation-patterns.sql.md
06-PROGRAMMING/sql/schema-diff-validation.sql.md
06-PROGRAMMING/sql/tenant-context-injection.sql.md

# Patrones de Testing Unitario (subdirectorio)
06-PROGRAMMING/sql/unit-test-patterns/01-clean-rls-compliant.sql.md
06-PROGRAMMING/sql/unit-test-patterns/02-missing-where-tenant.sql.md
06-PROGRAMMING/sql/unit-test-patterns/03-bypass-comment.sql.md
06-PROGRAMMING/sql/unit-test-patterns/04-edge-special-chars.sql.md
06-PROGRAMMING/sql/unit-test-patterns/05-multi-violations.sql.md
06-PROGRAMMING/sql/unit-test-patterns/06-large-stress.sql.md
06-PROGRAMMING/sql/unit-test-patterns/07-missing-file-error.sql.md
06-PROGRAMMING/sql/unit-test-patterns/08-context-exception.sql.md
```

### 🦜 Referencias Vectoriales (Consulta ONLY)
```text
06-PROGRAMMING/postgresql-pgvector/00-INDEX.md
06-PROGRAMMING/postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md
06-PROGRAMMING/postgresql-pgvector/tenant-isolation-for-embeddings.pgvector.md
```

### 🔄 Workflows y CI/CD
```text
04-WORKFLOWS/sdd-universal-assistant.json
.github/workflows/validate-mantis.yml
```

### 📚 Skills de Referencia
```text
02-SKILLS/README.md
02-SKILLS/skill-domains-mapping.md
02-SKILLS/INFRASTRUCTURA/ssh-key-management.md
02-SKILLS/INFRASTRUCTURA/health-monitoring-vps.md
```

### 🌐 Documentación pt-BR
```text
docs/pt-BR/validation-tools/TEMPLATE-VALIDATOR.md
docs/pt-BR/validation-tools/verify-constraints/README.md
docs/pt-BR/validation-tools/check-rls/README.md
```

---

## 🧭 GUÍA DE USO PARA EL AGENTE SQL

```sql
-- Pseudocódigo: Cómo consultar patrones disponibles en SQL
-- (Implementado en el agente, no en SQL puro)

-- Ejemplo de validación de constraints antes de emitir query
-- En aplicación host (Python/Go/JS):
function validarConstraintsSQL(artifactPath) {
  const fm = extractFrontmatter(artifactPath);
  const declared = fm.constraints_mapped;
  const matrix = loadJSON('./05-CONFIGURATIONS/validation/norms-matrix.json');
  const allowed = getAllowedConstraints(matrix, artifactPath);
  
  const issues = [];
  for (const c of declared) {
    if (!allowed.includes(c)) {
      issues.push(`constraint '${c}' not allowed for path ${artifactPath}`);
    }
  }
  return issues;
}

-- Ejemplo de detección de LANGUAGE LOCK en query SQL
function contieneOperadoresVectoriales(query) {
  return /<->[^a-zA-Z]|<#>[^a-zA-Z]|cosine_distance|l2_distance|hamming_distance/.test(query);
}

-- Uso en el agente:
if (contieneOperadoresVectoriales(inputQuery)) {
  console.error("LANGUAGE LOCK: Vector operators not allowed in SQL domain. Use postgresql-pgvector/");
  process.exit(1);
} else {
  // Generar query SQL estándar con tenant isolation
  const query = `SELECT * FROM docs WHERE tenant_id = $1 AND status = 'active'`;
}
```

---

## 📋 INSTRUCCIONES DE INTEGRACIÓN (Actualizadas)

### Paso 1: Agregar al final del agente
Pegar los bloques de referencias justo antes de la sección `## Limitations` en:
- `06-PROGRAMMING/sql/sql-master-agent.md`

### Paso 2: Actualizar el comportamiento del agente
En la sección `## Comportamiento del Agente` o `## Behavioral Traits`, agregar:

```markdown
| Trait | Implementación contractual |
|-------|---------------------------|
| **Consulta patrones antes de generar** | Antes de emitir query SQL, el agente debe consultar la lista de patrones disponibles en `06-PROGRAMMING/sql/` para asegurar coherencia con el repositorio |
| **Acceso dual** | Usar ruta canónica (`./06-PROGRAMMING/sql/...`) para acceso local, o raw URL para acceso remoto si el archivo no existe localmente |
| **LANGUAGE LOCK automático** | Si el usuario solicita operadores vectoriales (`<->`, `<#>`, `cosine_distance`), el agente debe delegar a `06-PROGRAMMING/postgresql-pgvector/` y NO generar queries con vectores en su dominio |
| **Enseña mientras genera** | Incluir comentarios explicativos en las queries generadas para facilitar el aprendizaje del usuario |
| **Valida constraints antes de emitir** | Ejecutar `validarConstraintsSQL()` antes de emitir cualquier artifact para asegurar coherencia con `norms-matrix.json` |
```

### Paso 3: Validar con `verify-constraints.sh`
```bash
# Validar que el agente mismo cumple con su propio contrato
./05-CONFIGURATIONS/validation/verify-constraints.sh --file 06-PROGRAMMING/sql/sql-master-agent.md | jq
```

---
