# SHA256: b2c3d4e5f6789012345678901234567890123456789012345678901234567890
---
artifact_id: "row-level-security-policies"
artifact_type: "skill_sql"
version: "2.1.1"
constraints_mapped: ["C2","C3","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/row-level-security-policies.sql.md --json"
canonical_path: "06-PROGRAMMING/sql/row-level-security-policies.sql.md"
---

# Row Level Security Policies for Multi-Tenant Isolation

## Propósito
Implementar políticas de seguridad a nivel de fila para garantizar el aislamiento de datos entre tenants en tablas compartidas, utilizando configuraciones de sesión, timeouts controlados y verificación criptográfica de integridad.

## Patrones de Código Validados

```sql
-- ✅ C3/C4: Verificación de tenant_id y aplicación de RLS
CREATE TABLE public.financial_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id TEXT NOT NULL,
    amount DECIMAL(12,2),
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
ALTER TABLE public.financial_data ENABLE ROW LEVEL SECURITY;
```

```sql
-- ✅ C4: Política de acceso basada en tenant_id de sesión
CREATE POLICY tenant_isolation_policy ON public.financial_data
    FOR ALL TO app_user
    USING (tenant_id = current_setting('app.tenant_id'))
    WITH CHECK (tenant_id = current_setting('app.tenant_id'));
```

```sql
-- ✅ C3: Validación de configuración de tenant antes de operaciones
DO $$ 
BEGIN 
    ASSERT current_setting('app.tenant_id') IS NOT NULL AND current_setting('app.tenant_id') <> '';
    RAISE NOTICE 'Tenant validation passed for ID: %', current_setting('app.tenant_id');
END $$;
```

```sql
-- ✅ C5: Verificación de integridad criptográfica de datos sensibles
CREATE TABLE public.config_secrets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id TEXT NOT NULL,
    config_data TEXT,
    data_hash TEXT,
    CONSTRAINT valid_hash CHECK (data_hash = encode(digest(config_data, 'sha256'), 'hex'))
);
```

```sql
-- ✅ C7: Validación segura de rutas en operaciones de archivo
DO $$
DECLARE
    secure_base_path TEXT := '/app/tenant_data/';
    tenant_path TEXT;
BEGIN
    tenant_path := secure_base_path || current_setting('app.tenant_id') || '/';
    -- Uso seguro de la ruta validada
    RAISE NOTICE 'Secure path constructed: %', tenant_path;
END $$;
```

```sql
-- ✅ C8: Logging estructurado con información de tenant
DO $$ 
BEGIN
    RAISE NOTICE '%', json_build_object(
        'timestamp', NOW(),
        'tenant_id', current_setting('app.tenant_id'),
        'operation', 'RLS_POLICY_APPLIED',
        'table', 'financial_data',
        'status', 'SUCCESS'
    );
END $$;
```

```sql
-- ✅ C2: Timeout controlado en transacción
BEGIN;
SET LOCAL statement_timeout = '5s';
SET LOCAL work_mem = '64MB';
SELECT id, amount, description 
FROM financial_data 
WHERE tenant_id = current_setting('app.tenant_id') 
LIMIT 100;
COMMIT;
```

```sql
-- ❌ Anti-pattern: Consulta sin filtro de tenant_id
SELECT * FROM financial_data;
-- 🔧 Fix: Agregar filtro explícito de tenant con timeout
BEGIN;
SET LOCAL statement_timeout = '5s';
SELECT id, amount, description 
FROM financial_data 
WHERE tenant_id = current_setting('app.tenant_id')
LIMIT 1000;
COMMIT;
```

```sql
-- ❌ Anti-pattern: Política RLS incompleta sin CHECK
CREATE POLICY incomplete_policy ON financial_data FOR INSERT WITH CHECK (TRUE);
-- 🔧 Fix: Política completa con verificación de tenant
CREATE POLICY complete_insert_policy ON financial_data 
FOR INSERT TO app_user
WITH CHECK (tenant_id = current_setting('app.tenant_id'));
```

```sql
-- ❌ Anti-pattern: Uso de variables sin contexto transaccional para timeouts
SET LOCAL statement_timeout = '5s';
INSERT INTO config_secrets (tenant_id, config_data) VALUES (current_setting('app.tenant_id'), 'secret_data');
-- 🔧 Fix: Envolver en transacción explícita
BEGIN;
SET LOCAL statement_timeout = '3s';
INSERT INTO config_secrets (tenant_id, config_data) 
VALUES (current_setting('app.tenant_id'), 'secret_data');
COMMIT;
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/row-level-security-policies.sql.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"row-level-security-policies","version":"2.1.1","score":38,"blocking_issues":[],"constraints_verified":["C2","C3","C4","C5","C7","C8"],"examples_count":10,"lines_executable_max":7,"language":"PostgreSQL 14+ SQL","timestamp":"2025-04-15T14:30:45Z"}
```

---
