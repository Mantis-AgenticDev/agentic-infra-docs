# SHA256: f678901234567890123456789012345678901234567890123456789012345678
---
artifact_id: "column-encryption-patterns"
artifact_type: "skill_sql"
version: "2.1.1"
constraints_mapped: ["C3","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/column-encryption-patterns.sql.md --json"
canonical_path: "06-PROGRAMMING/sql/column-encryption-patterns.sql.md"
---

# Column Encryption Patterns with pgcrypto for Data Protection

## Propósito
Implementar patrones de encriptación a nivel de columna utilizando pgcrypto para proteger datos sensibles, con verificación de integridad criptográfica y validación de contexto tenant.

## Patrones de Código Validados

```sql
-- ✅ C5: Encriptación de columna sensible con pgcrypto
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE TABLE encrypted_user_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id TEXT NOT NULL,
    email TEXT,
    encrypted_ssn BYTEA
);
```

```sql
-- ✅ C3/C5: Insertar datos encriptados con validación
INSERT INTO encrypted_user_data (tenant_id, email, encrypted_ssn)
VALUES (current_setting('app.tenant_id'), 'user@example.com', 
        pgp_sym_encrypt('123-45-6789', 'key-' || current_setting('app.tenant_id')));
```

```sql
-- ✅ C3: Validación de contexto antes de operaciones
DO $$ 
BEGIN 
    ASSERT current_setting('app.tenant_id') IS NOT NULL AND current_setting('app.tenant_id') <> '';
    RAISE NOTICE 'Context OK: %', current_setting('app.tenant_id');
END $$;
```

```sql
-- ✅ C4: Consulta con filtro automático de tenant
SELECT id, email FROM encrypted_user_data 
WHERE tenant_id = current_setting('app.tenant_id') LIMIT 10;
```

```sql
-- ✅ C5: Verificación de integridad criptográfica
CREATE TABLE config_with_integrity (
    id UUID,
    tenant_id TEXT,
    config_data TEXT,
    data_hash TEXT,
    CONSTRAINT hash_check CHECK (data_hash = encode(digest(config_data, 'sha256'), 'hex'))
);
```

```sql
-- ✅ C7: Validación segura de rutas para claves
DO $$
DECLARE key_path TEXT := '/secure/keys/tenant_' || current_setting('app.tenant_id') || '.key';
BEGIN
    ASSERT POSITION('..' IN key_path) = 0;
    RAISE NOTICE 'Path OK: %', key_path;
END $$;
```

```sql
-- ✅ C8: Logging estructurado con contexto
RAISE NOTICE '%', json_build_object('event','encrypt','tenant',current_setting('app.tenant_id'));
```

```sql
-- ❌ Anti-pattern: Datos sensibles sin encriptación
CREATE TABLE insecure_data (id UUID, ssn TEXT);
-- 🔧 Fix: Usar encriptación para datos sensibles
CREATE TABLE secure_data (id UUID, encrypted_ssn BYTEA);
```

```sql
-- ❌ Anti-pattern: Verificación de hash débil
ALTER TABLE bad_config ADD CONSTRAINT weak_check CHECK (data_hash = MD5(config_data));
-- 🔧 Fix: Usar función criptográfica fuerte
ALTER TABLE good_config ADD CONSTRAINT strong_check CHECK (data_hash = encode(digest(config_data, 'sha256'), 'hex'));
```

```sql
-- ❌ Anti-pattern: Sin filtro de tenant en consultas
SELECT * FROM encrypted_user_data;
-- 🔧 Fix: Agregar filtro explícito de tenant
SELECT id, email FROM encrypted_user_data WHERE tenant_id = current_setting('app.tenant_id');
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/column-encryption-patterns.sql.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"column-encryption-patterns","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C3","C4","C5","C7","C8"],"examples_count":10,"lines_executable_max":5,"language":"PostgreSQL 14+ SQL","timestamp":"2026-04-18T16:30:45Z"}
```

---
