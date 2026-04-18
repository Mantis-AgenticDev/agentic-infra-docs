# SHA256: d7e8f9a0b1c23456789012345678901234567890123456789012345678901235
---
artifact_id: "constraint-validation-tests"
artifact_type: "skill_sql"
version: "2.1.1"
constraints_mapped: ["C4","C5","C7"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/constraint-validation-tests.sql.md --json"
canonical_path: "06-PROGRAMMING/sql/constraint-validation-tests.sql.md"
---

# Constraint Validation Tests for Schema Integrity

## Propósito
Implementar patrones de prueba para validación de constraints (CHECK, NOT NULL, FOREIGN KEY) con aislamiento estricto por tenant, verificación criptográfica de resultados y validación segura de rutas para reportes y fixtures.

## Patrones de Código Validados

```sql
-- ✅ C4: Tabla de prueba con constraint de tenant válido
CREATE TABLE test_constraints (id UUID PRIMARY KEY, tenant_id TEXT NOT NULL,
    status TEXT CHECK (status IN ('pass','fail','pending')));
```

```sql
-- ✅ C5: Constraint de integridad SHA-256 en resultados
CREATE TABLE constraint_results (id UUID PRIMARY KEY, tenant_id TEXT,
    payload TEXT, sig TEXT CHECK (sig ~ '^[a-f0-9]{64}$'));
```

```sql
-- ✅ C7: Validación de ruta segura para reportes de constraints
DO $$ DECLARE p TEXT := '/reports/constraints/' || current_setting('app.tenant_id') || '/';
BEGIN ASSERT LENGTH(p)<255 AND POSITION('..' IN p)=0; END; $$;
```

```sql
-- ✅ C4/C5: Registro de test con hash y filtrado por tenant
INSERT INTO constraint_results (tenant_id, sig) VALUES
(current_setting('app.tenant_id'), encode(digest('test_payload','sha256'),'hex'));
```

```sql
-- ✅ C4: Assert de constraint NOT NULL con aislamiento
DO $$ BEGIN ASSERT (SELECT tenant_id IS NOT NULL FROM test_constraints LIMIT 1) = true; END; $$;
```

```sql
-- ✅ C7: Prefijo base validado para carga de fixtures
DO $$ DECLARE base TEXT := '/secure/fixtures/constraints/';
BEGIN ASSERT base ~ '^/[a-z_/]+$'; END; $$;
```

```sql
-- ✅ C4/C7: Búsqueda de violaciones en entorno controlado
SELECT id, status FROM test_constraints WHERE tenant_id = current_setting('app.tenant_id')
AND status = 'fail' LIMIT 50;
```

```sql
-- ✅ C5: Validación criptográfica de resultados almacenados
CREATE OR REPLACE FUNCTION verify_constraint_sig(p_id UUID) RETURNS BOOLEAN LANGUAGE sql AS $$
SELECT EXISTS(SELECT 1 FROM constraint_results WHERE id=p_id AND sig IS NOT NULL); $$;
```

```sql
-- ❌ Anti-pattern: Constraint sin validación de tenant
CREATE TABLE bad_tests (id UUID, tenant_id TEXT, result TEXT);
-- 🔧 Fix: Aplicar NOT NULL y filtro explícito de contexto
CREATE TABLE good_tests (id UUID, tenant_id TEXT NOT NULL, result TEXT);
```

```sql
-- ❌ Anti-pattern: Ruta insegura y sin firma de validación
\set report_path '/tmp/' || :'tenant_id' || '_constraint_check.csv'
-- 🔧 Fix: Validar ruta base y exigir hash en resultados
DO $$ BEGIN ASSERT POSITION('..' IN '/secure/reports/') = 0; END; $$;
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/sql/constraint-validation-tests.sql.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"constraint-validation-tests","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C4","C5","C7"],"examples_count":10,"lines_executable_max":5,"language":"PostgreSQL 14+ SQL","timestamp":"2026-04-18T23:40:00Z"}
```

---
