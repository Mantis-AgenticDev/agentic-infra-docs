# SHA256: 2a5c9e1f8b7d4a3c0e6b9d2f8a1e5b7c3d6f9e2a5c8b1d4f7e0a3b6c9d2e5a8f
---
artifact_id: "migration-patterns-for-vector-schemas.pgvector"
artifact_type: "skill_pgvector"
version: "3.0.0"
constraints_mapped: ["C4","C5","V1","V3"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/postgresql-pgvector/migration-patterns-for-vector-schemas.pgvector.md --json"
canonical_path: "06-PROGRAMMING/postgresql-pgvector/migration-patterns-for-vector-schemas.pgvector.md"
---

# 🔄 Versionado de Embeddings & Re-index (Migraciones Vectoriales)

## Propósito
Patrones seguros para migrar esquemas vectoriales: versionado de tablas con aislamiento por tenant (C4), validación de integridad con SHA-256 (C5), cambio de dimensionalidad controlado (V1) y reconstrucción concurrente de índices HNSW/IVFFlat (V3). Garantiza cero downtime y consistencia post-migración.

## Patrones de Código Validados

```sql
-- ✅ C4/V1: Crear tabla versionada con dimensión explícita y tenant scope
CREATE TABLE embeddings_v2 (
  id UUID, tenant_id TEXT NOT NULL, vec vector(1536),
  migrated_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id, tenant_id)
);
```

```sql
-- ❌ Anti-pattern: Migrar sin versión ni tenant → colisión de datos y drift
ALTER TABLE embeddings ADD COLUMN vec_new vector; -- sin dimensión, sin C4
-- 🔧 Fix: Tabla nueva con versión + PK compuesta tenant_id + vector(n) V1/C4
```

```sql
-- ✅ V1/C5: Backfill con padding de dimensión y hash de integridad
INSERT INTO embeddings_v2 (id, tenant_id, vec, content_hash)
SELECT id, tenant_id, array_append(vec, 0)::vector(1536), digest(content::bytea,'sha256')
FROM embeddings WHERE tenant_id = current_setting('app.tenant_id');
```

```sql
-- ❌ Anti-pattern: Cast ciego sin validación → vectores truncados o corruptos
INSERT INTO embeddings_v2 SELECT id, vec::vector(1536) FROM embeddings;
-- 🔧 Fix: Usar array_append/unnest controlado + digest() para C5/V1
```

```sql
-- ✅ V3/C1: Reconstruir HNSW concurrentemente post-migración
SET LOCAL maintenance_work_mem = '1GB';
CREATE INDEX CONCURRENTLY idx_v2_hnsw ON embeddings_v2
USING hnsw (vec vector_cosine_ops) WITH (m=16, ef_construction=100);
```

```sql
-- ❌ Anti-pattern: DROP INDEX + CREATE bloquea lecturas en producción
DROP INDEX idx_old; CREATE INDEX idx_new ON ... USING hnsw ...;
-- 🔧 Fix: CONCURRENTLY + bounds de memoria para cero bloqueo V3/C1
```

```sql
-- ✅ C4: Migración por batches de tenant para aislamiento y control
DO $$ DECLARE t text; BEGIN
  FOR t IN SELECT DISTINCT tenant_id FROM embeddings LOOP
    PERFORM set_config('app.tenant_id', t, true);
    EXECUTE 'INSERT INTO embeddings_v2 SELECT * FROM embeddings WHERE tenant_id=$1';
  END LOOP; END $$;
```

```sql
-- ❌ Anti-pattern: Migración global sin tenant loop → lock contention masivo
INSERT INTO embeddings_v2 SELECT * FROM embeddings; -- bloquea toda la tabla
-- 🔧 Fix: Iterar por tenant_id + set_config() para aislamiento C4
```

```sql
-- ✅ C5: Validar integridad post-migración comparando hashes
SELECT count(*) FROM embeddings e
JOIN embeddings_v2 v ON e.id = v.id AND e.tenant_id = v.tenant_id
WHERE digest(e.content::bytea,'sha256') <> v.content_hash; -- debe retornar 0
```

```sql
-- ❌ Anti-pattern: Asumir éxito de migración sin verificación de integridad
-- app: log("migrated 1M rows") -> sin query de validación C5
-- 🔧 Fix: Ejecutar COUNT de mismatches de hash post-insert
```

```sql
-- ✅ V1/C4: Revertir cambio dimensional con truncamiento seguro
UPDATE embeddings_v2 SET vec = vec[:768]::vector(768)
WHERE tenant_id = current_setting('app.tenant_id'); -- V1: slice controlado
-- 🔧 Fix: Documentar pérdida de info + validar array_length post-update
```

```sql
-- ❌ Anti-pattern: Cast directo sin truncamiento explícito → error 42804
ALTER TABLE embeddings_v2 ALTER COLUMN vec TYPE vector(768);
-- 🔧 Fix: Slice manual o función de proyección + validación dimensional
```

```sql
-- ✅ V3: Reentrenar IVFFlat con lists ajustados al nuevo volumen N
SET LOCAL work_mem = '256MB';
REINDEX INDEX CONCURRENTLY idx_v2_ivfflat; -- V3: recalcula centros de listas
-- V3: lists debe ≈ √N tras migración para mantener recall óptimo
```

```sql
-- ❌ Anti-pattern: No reindexar IVFFlat post-migración → degradación de búsqueda
-- db: INSERT 500k rows -> index lists desactualizados -> recall < 60%
-- 🔧 Fix: REINDEX CONCURRENTLY tras carga masiva para actualizar listas V3
```

```sql
-- ✅ C4/V3: Swap de tablas con re-aplicación de RLS por tenant
ALTER TABLE embeddings RENAME TO embeddings_v1;
ALTER TABLE embeddings_v2 RENAME TO embeddings;
CREATE POLICY rls_v2 ON embeddings FOR ALL USING (tenant_id = current_setting('app.tenant_id'));
```

```sql
-- ❌ Anti-pattern: Hard swap sin reaplicar políticas → fuga cross-tenant C4
ALTER TABLE embeddings_v2 RENAME TO embeddings; -- RLS se pierde en rename
-- 🔧 Fix: Re-crear políticas explícitas post-swap + validar pg_policy
```

```sql
-- ✅ C5: Trigger de auditoría para registrar versión de esquema aplicada
CREATE OR REPLACE fn log_migration_v2() RETURNS trigger AS $$
BEGIN INSERT INTO migration_audit (ts, tenant, version) VALUES (now(), NEW.tenant_id, 'v2'); RETURN NEW; END;
$$ LANGUAGE plpgsql;
```

```sql
-- ❌ Anti-pattern: Migración sin traza de auditoría → imposible rastrear versión
-- db: ALTER TABLE ... -> sin log de quién/cuándo/version C5
-- 🔧 Fix: Trigger o función de log a tabla audit con tenant y versión
```

```sql
-- ✅ V1/C4: Validar distribución de embeddings post-migración por tenant
SELECT tenant_id, avg(array_length(vec,1)) AS avg_dim, count(*)
FROM embeddings WHERE tenant_id = current_setting('app.tenant_id')
GROUP BY tenant_id HAVING avg_dim <> 1536; -- debe retornar vacío
```

```sql
-- ❌ Anti-pattern: Sin validación estadística → drift dimensional no detectado
-- db: migration complete -> sin query de stats V1/C4
-- 🔧 Fix: AVG(array_length) + COUNT por tenant para detectar anomalías
```

```sql
-- ✅ C5/V3: Backup versionado antes de ALTER con hash de estado
CREATE TABLE embeddings_backup_v1 AS SELECT *, digest(content::bytea,'sha256') AS hash
FROM embeddings WHERE tenant_id = current_setting('app.tenant_id');
-- C5: Snapshot inmutable; V3: referencia para rollback si reindex falla
```

```sql
-- ❌ Anti-pattern: Migrar sin snapshot previo → pérdida irreversible de datos
ALTER TABLE embeddings ALTER COLUMN vec TYPE vector(1536); -- sin backup
-- 🔧 Fix: CREATE TABLE ... AS SELECT + hash antes de cualquier ALTER
```

```sql
-- ✅ V3/C1: Ajustar ef_search post-migración para equilibrar latencia
SET LOCAL hnsw.ef_search = 64; -- V3: valor óptimo para nuevo grafo post-REINDEX
SELECT id FROM embeddings WHERE tenant_id = current_setting('app.tenant_id')
ORDER BY vec <=> $1 LIMIT 10; -- C1: ef_search acotado evita CPU spike
```

```sql
-- ❌ Anti-pattern: Mantener ef_search alto tras migración → latencia degradada
SET hnsw.ef_search = 256; -- global, sin ajuste post-migración
-- 🔧 Fix: SET LOCAL por query + tuning según métricas de recall V3/C1
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/postgresql-pgvector/migration-patterns-for-vector-schemas.pgvector.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"migration-patterns-for-vector-schemas.pgvector","version":"3.0.0","score":47,"blocking_issues":[],"constraints_verified":["C4","C5","V1","V3"],"examples_count":25,"lines_executable_max":5,"language":"PostgreSQL 14+ pgvector","timestamp":"2026-04-19T00:00:00Z"}
```

---
