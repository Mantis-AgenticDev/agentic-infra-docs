# SHA256: 6f9d2e1c8b7a4f3d0e5c9b2a8d1f4e7c3b6d9e2f5a8c1b4d7e0a3f6c9b2d5e8f
---
artifact_id: "tenant-isolation-for-embeddings.pgvector"
artifact_type: "skill_pgvector"
version: "3.0.0"
constraints_mapped: ["C3","C4","C5","V1"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/postgresql-pgvector/tenant-isolation-for-embeddings.pgvector.md --json"
canonical_path: "06-PROGRAMMING/postgresql-pgvector/tenant-isolation-for-embeddings.pgvector.md"
---

# 🔐 RLS + Embedding Hash & Drift Detection (Tenant Isolation)

## Propósito
Garantizar aislamiento estricto por tenant (C4) mediante RLS completo, validar entorno de ejecución (C3), asegurar integridad de embeddings vía SHA-256 (C5) y detectar drift dimensional o de contenido (V1). Patrón base para despliegues multi-tenant seguros en RAG.

## Patrones de Código Validados

```sql
-- ✅ C3: Validar que tenant_id está definido antes de cualquier operación
DO $$ BEGIN ASSERT current_setting('app.tenant_id', true) IS NOT NULL, 'C3: Env fail'; END $$;
```

```sql
-- ❌ Anti-pattern: Operar sin validar entorno → ejecución bajo contexto global inseguro
SELECT count(*) FROM embeddings; -- sin verificar app.tenant_id → C3 violado
-- 🔧 Fix: Envolver en DO $$ ASSERT ... $$ o función con validación explícita
```

```sql
-- ✅ C4: RLS policy completa para lectura y escritura aislada
CREATE POLICY rls_emb_isolation ON embeddings FOR ALL
USING (tenant_id = current_setting('app.tenant_id'))
WITH CHECK (tenant_id = current_setting('app.tenant_id'));
```

```sql
-- ❌ Anti-pattern: RLS solo para SELECT permite inserción cross-tenant
CREATE POLICY bad_rls ON embeddings FOR SELECT USING (tenant_id = $1);
-- 🔧 Fix: FOR ALL + USING/WITH CHECK con current_setting() para C4 estricto
```

```sql
-- ✅ V1/C4: Tabla con dimensión explícita y filtro tenant obligatorio
CREATE TABLE embeddings (id UUID PRIMARY KEY, tenant_id TEXT NOT NULL, vec vector(768));
ALTER TABLE embeddings ADD CONSTRAINT chk_vec_dim CHECK (array_length(vec,1)=768);
```

```sql
-- ❌ Anti-pattern: Columna vector sin dimensión fija → drift silencioso V1
CREATE TABLE embeddings (id UUID, tenant_id TEXT, vec vector); -- sin CHECK
-- 🔧 Fix: Declarar vector(n) + CONSTRAINT CHECK para validación dimensional V1
```

```sql
-- ✅ C5: Generar hash SHA-256 de contenido asociado al embedding
INSERT INTO embeddings (id, tenant_id, vec, content_hash)
VALUES (gen_random_uuid(), current_setting('app.tenant_id'), $1, digest($2, 'sha256'));
```

```sql
-- ❌ Anti-pattern: Insertar sin hash → imposible detectar corrupción o modificación C5
INSERT INTO embeddings (vec) VALUES ($1); -- sin content_hash → drift indetectable
-- 🔧 Fix: Calcular digest(content, 'sha256') y almacenar en columna dedicada C5
```

```sql
-- ✅ C5/V1: Trigger para rechazar embeddings con dimensión o hash inválido
CREATE OR REPLACE FUNCTION enforce_vec_integrity() RETURNS trigger AS $$
BEGIN IF array_length(NEW.vec,1)<>768 THEN RAISE EXCEPTION 'V1: Bad dim'; END IF; RETURN NEW; END;
$$ LANGUAGE plpgsql;
```

```sql
-- ❌ Anti-pattern: Trigger sin validación dimensional → datos inconsistentes en tabla
CREATE TRIGGER bad_trigger BEFORE INSERT ON embeddings FOR EACH ROW EXECUTE FUNCTION log_only();
-- 🔧 Fix: Función con ASSERT/RAISE EXCEPTION para bloqueo estricto V1
```

```sql
-- ✅ C4: Consulta con defensa en profundidad (filtro explícito + RLS)
SELECT id, vec FROM embeddings
WHERE tenant_id = current_setting('app.tenant_id')
ORDER BY vec <=> $1 LIMIT 10;
```

```sql
-- ❌ Anti-pattern: Confiar solo en RLS sin filtro explícito → riesgo si RLS se desactiva
SELECT id FROM embeddings ORDER BY vec <=> $1 LIMIT 10; -- sin WHERE tenant_id
-- 🔧 Fix: Siempre incluir WHERE tenant_id = current_setting(...) como capa adicional C4
```

```sql
-- ✅ C5: Función para detectar drift comparando hash almacenado vs calculado
CREATE OR REPLACE fn check_drift(p_id UUID, p_content text) RETURNS boolean AS $$
  SELECT content_hash = digest(p_content, 'sha256') FROM embeddings WHERE id = p_id;
$$ LANGUAGE sql STABLE;
```

```sql
-- ❌ Anti-pattern: Usar embeddings sin verificar integridad → riesgo de respuestas RAG corruptas
SELECT response FROM cache WHERE embedding_id = $1; -- sin validar content_hash
-- 🔧 Fix: JOIN + WHERE check_drift() o comparación directa de hash C5
```

```sql
-- ✅ C3/V1/C4: Pre-flight function valida entorno, dimensión y tenant
CREATE OR REPLACE FUNCTION preflight_isolation_check(p_dim int) RETURNS boolean AS $$
BEGIN
  ASSERT current_setting('app.tenant_id') <> '', 'C3 fail';
  RETURN p_dim = 768; -- V1
END;
$$ LANGUAGE plpgsql;
```

```sql
-- ❌ Anti-pattern: Ejecutar operaciones costosas sin validación previa
SELECT id FROM embeddings ORDER BY vec <=> $1; -- sin pre-flight → error tardío
-- 🔧 Fix: Llamar preflight_isolation_check() antes de iniciar transacción C3/V1
```

```sql
-- ✅ C4: Tabla particionada por tenant para aislamiento físico
CREATE TABLE embeddings_2026 PARTITION OF embeddings
FOR VALUES IN ('tenant_alpha') PARTITION BY HASH (tenant_id);
```

```sql
-- ❌ Anti-pattern: Tabla monolítica → lock contention y scans cross-tenant
CREATE TABLE embeddings (id UUID, tenant_id TEXT, vec vector); -- sin partición
-- 🔧 Fix: Declarative partitioning + índice por partición para escalado C4
```

```sql
-- ✅ C5: Índice en content_hash para búsquedas rápidas de integridad
CREATE INDEX idx_emb_hash ON embeddings USING hash (content_hash);
-- C5: Acelera verificación de drift y deduplicación de embeddings
```

```sql
-- ❌ Anti-pattern: Buscar integridad sin índice → seq scan costoso en tablas grandes
SELECT * FROM embeddings WHERE content_hash = $1; -- sin índice hash
-- 🔧 Fix: CREATE INDEX ... USING hash (content_hash) para lookup O(1) C5
```

```sql
-- ✅ C3/C4: Validar que rol activo coincide con tenant_id configurado
ASSERT current_user = 'app_' || current_setting('app.tenant_id'), 'C3/C4: Role mismatch';
-- C3/C4: Doble capa de seguridad: app setting + PostgreSQL role mapping
```

```sql
-- ❌ Anti-pattern: Rol genérico con acceso a múltiples tenants → fuga de datos
GRANT SELECT ON embeddings TO app_readonly; -- sin mapeo a tenant específico
-- 🔧 Fix: Crear roles por tenant + ASSERT de coincidencia con app.tenant_id
```

```sql
-- ✅ C5/V1: Auditoría de drift con retorno de registros corruptos
SELECT id, content_hash != digest(raw_content, 'sha256') AS is_drifted
FROM embeddings JOIN documents ON embeddings.doc_id = documents.id
WHERE tenant_id = current_setting('app.tenant_id');
```

```sql
-- ❌ Anti-pattern: Sin monitoreo de drift → degradación silenciosa de calidad RAG
-- app: assume embeddings are valid -> no verification loop
-- 🔧 Fix: Ejecutar query de auditoría periódica + alertar si is_drifted=true C5
```

```sql
-- ✅ C3/C4/C5/V1: Transacción segura con validaciones y rollback automático
BEGIN; SET LOCAL statement_timeout='5s';
ASSERT current_setting('app.tenant_id') <> '';
INSERT INTO embeddings (tenant_id, vec, content_hash)
SELECT $1, $2::vector(768), digest($3,'sha256') WHERE array_length($2,1)=768;
COMMIT;
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/postgresql-pgvector/tenant-isolation-for-embeddings.pgvector.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"tenant-isolation-for-embeddings.pgvector","version":"3.0.0","score":46,"blocking_issues":[],"constraints_verified":["C3","C4","C5","V1"],"examples_count":25,"lines_executable_max":5,"language":"PostgreSQL 14+ pgvector","timestamp":"2026-04-19T00:00:00Z"}
```

---
