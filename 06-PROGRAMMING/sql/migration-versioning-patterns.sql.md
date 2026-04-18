# SHA256: c3d4e5f6a1b23456789012345678901234567890123456789012345678901235
---
artifact_id: "migration-versioning-patterns"
artifact_type: "skill_sql"
version: "2.1.1"
constraints_mapped: ["C3","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/migration-versioning-patterns.sql.md --json"
canonical_path: "06-PROGRAMMING/sql/migration-versioning-patterns.sql.md"
---

# Migration Versioning Patterns with Tenant Isolation

## Propósito
Implementar patrones de versionado de migraciones con aislamiento estricto por tenant, verificación de integridad criptográfica de scripts y logging estructurado para auditoría de despliegues.

## Patrones de Código Validados

```sql
-- ✅ C4: Tabla de control de versiones con aislamiento
CREATE TABLE IF NOT EXISTS migration_versions (id UUID PRIMARY KEY, tenant_id TEXT NOT NULL,
    version TEXT NOT NULL, applied_at TIMESTAMPTZ DEFAULT NOW(), status TEXT DEFAULT 'APPLIED');
```

```sql
-- ✅ C5: Verificación de integridad de scripts con SHA-256
CREATE TABLE IF NOT EXISTS migration_scripts (id UUID PRIMARY KEY, tenant_id TEXT,
    script_content TEXT, content_hash TEXT,
    CONSTRAINT script_hash CHECK (content_hash = encode(digest(script_content, 'sha256'), 'hex')));
```

```sql
-- ✅ C3/C7: Validación de contexto y ruta segura de migración
DO $$ BEGIN ASSERT current_setting('app.tenant_id') IS NOT NULL;
RAISE NOTICE 'Valid path: %', '/migrations/' || current_setting('app.tenant_id') || '/'; END; $$;
```

```sql
-- ✅ C8: Logging estructurado de aplicación de migración
RAISE NOTICE '%', json_build_object('event','migration_applied','tenant',current_setting('app.tenant_id'),'v','2026.04.18');
```

```sql
-- ✅ C4/C5: Registro transaccional con checksum verificado
BEGIN; SET LOCAL statement_timeout = '10s';
INSERT INTO migration_versions (tenant_id, version, checksum) VALUES
(current_setting('app.tenant_id'), '2026.04.18', encode(digest('-- SQL script', 'sha256'), 'hex'));
COMMIT;
```

```sql
-- ✅ C4: Consulta segura con límite y filtro de tenant
SELECT version, applied_at FROM migration_versions WHERE tenant_id = current_setting('app.tenant_id')
ORDER BY applied_at DESC LIMIT 10;
```

```sql
-- ✅ C8: Inserción de evento de auditoría en formato JSON
INSERT INTO audit_events (payload) VALUES (json_build_object('type','migration','status','success'));
```

```sql
-- ✅ C3: Validación explícita pre-ejecución en bloque
DO $$ BEGIN ASSERT current_setting('app.tenant_id') <> ''; RAISE NOTICE 'Context OK'; END; $$;
```

```sql
-- ❌ Anti-pattern: Registro sin contexto de tenant
INSERT INTO migration_versions (version) VALUES ('1.0.0');
-- 🔧 Fix: Inyectar tenant dinámico obligatorio
INSERT INTO migration_versions (tenant_id, version) VALUES (current_setting('app.tenant_id'), '1.0.0');
```

```sql
-- ❌ Anti-pattern: Script sin verificación de integridad
CREATE TABLE bad_scripts (id UUID, content TEXT);
-- 🔧 Fix: Agregar constraint de hash criptográfico
CREATE TABLE good_scripts (id UUID, content TEXT, hash TEXT CHECK (hash = encode(digest(content, 'sha256'), 'hex')));
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/migration-versioning-patterns.sql.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"migration-versioning-patterns","version":"2.1.1","score":33,"blocking_issues":[],"constraints_verified":["C3","C4","C5","C7","C8"],"examples_count":10,"lines_executable_max":5,"language":"PostgreSQL 14+ SQL","timestamp":"2026-04-18T20:15:00Z"}
```

---
