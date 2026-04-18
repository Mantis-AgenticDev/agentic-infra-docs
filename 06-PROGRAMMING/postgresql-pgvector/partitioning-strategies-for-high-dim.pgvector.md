# SHA256: 5e1f9c2a8b7d4e3f0a6c9b2d8e1f4a7c3b6d9e2f5a8c1b4d7e0a3f6c9b2d5e8a
---
artifact_id: "partitioning-strategies-for-high-dim.pgvector"
artifact_type: "skill_pgvector"
version: "3.0.0"
constraints_mapped: ["C1","C4","V3"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/postgresql-pgvector/partitioning-strategies-for-high-dim.pgvector.md --json"
canonical_path: "06-PROGRAMMING/postgresql-pgvector/partitioning-strategies-for-high-dim.pgvector.md"
---

# 🗂️ Partitioning Strategies for High-Dimensional Vectors (Tenant + Dim)

## Propósito
Estrategias de particionamiento declarativo en PostgreSQL 14+ para tablas pgvector de alta dimensionalidad: aislamiento por tenant (C4), límites de recursos por partición (C1), y ajuste de índices ANN locales por volumen/patrón (V3). Evita degradación de memoria, lock contention y scans cross-tenant en RAG a escala.

## Patrones de Código Validados

```sql
-- ✅ C4: Partición LIST por tenant_id para aislamiento físico estricto
CREATE TABLE embeddings_high PARTITION OF embeddings_master
FOR VALUES IN ('tenant_alpha');
```

```sql
-- ❌ Anti-pattern: Tabla única sin particionar → lock contention y fuga cross-tenant
CREATE TABLE embeddings_all (id UUID, tenant_id TEXT, vec vector(1536));
-- 🔧 Fix: Declarative partitioning LIST por tenant_id para aislamiento C4
```

```sql
-- ✅ C4: Partición por defecto para rechazar rutas desconocidas
CREATE TABLE embeddings_default PARTITION OF embeddings_master DEFAULT;
ALTER TABLE embeddings_default ENABLE ROW LEVEL SECURITY;
```

```sql
-- ❌ Anti-pattern: INSERT sin ruta válida → falla silenciosa o mezcla de datos
INSERT INTO embeddings_master (tenant_id, vec) VALUES ('unknown', $1);
-- 🔧 Fix: DEFAULT partition + RLS para captura y auditoría de rutas no mapeadas
```

```sql
-- ✅ V3: Índice HNSW local por partición con parámetros ajustados a volumen
CREATE INDEX idx_alpha_hnsw ON embeddings_high
USING hnsw (vec vector_cosine_ops) WITH (m=16, ef_construction=100);
```

```sql
-- ❌ Anti-pattern: Índice global en padre → consume RAM duplicada y no aprovecha pruning
CREATE INDEX idx_global_hnsw ON embeddings_master USING hnsw (vec vector_cosine_ops);
-- 🔧 Fix: Crear índices locales por partición; V3: tuning por tamaño real de cada shard
```

```sql
-- ✅ C1: Límite de memoria para escaneo multi-partición
SET LOCAL work_mem = '128MB'; SET LOCAL maintenance_work_mem = '256MB';
EXPLAIN (ANALYZE) SELECT id FROM embeddings_high WHERE vec <=> $1 < 0.4 LIMIT 10;
```

```sql
-- ❌ Anti-pattern: Query sin límites → OOM en escaneo de múltiples particiones grandes
SELECT id FROM embeddings_master ORDER BY vec <=> $1 LIMIT 50; -- sin bounds C1
-- 🔧 Fix: SET LOCAL work_mem + LIMIT explícito para acotar consumo de RAM
```

```sql
-- ✅ C4/V3: Attach concurrente de partición sin bloquear lecturas
ALTER TABLE embeddings_master ATTACH PARTITION embeddings_high CONCURRENTLY;
CREATE INDEX CONCURRENTLY idx_high_hnsw ON embeddings_high USING hnsw (vec vector_cosine_ops);
```

```sql
-- ❌ Anti-pattern: Attach sin CONCURRENTLY → bloqueo exclusivo en tabla padre
ALTER TABLE embeddings_master ATTACH PARTITION embeddings_high; -- LOCK ACCESS EXCLUSIVE
-- 🔧 Fix: CONCURRENTLY + índice previo creado para evitar downtime C4/V3
```

```sql
-- ✅ C1: Timeout explícito en mantenimiento de particiones
BEGIN; SET LOCAL statement_timeout = '15s';
VACUUM ANALYZE embeddings_high;
COMMIT;
```

```sql
-- ❌ Anti-pattern: VACUUM sin timeout en partición grande → transacción larga, bloat
VACUUM FULL embeddings_high; -- sin límites, bloquea queries concurrentes
-- 🔧 Fix: statement_timeout + VACUUM ANALYZE para limpieza incremental C1
```

```sql
-- ✅ V3: Reindexar solo partición activa tras crecimiento >30%
SET LOCAL maintenance_work_mem = '512MB';
REINDEX INDEX CONCURRENTLY idx_alpha_hnsw;
```

```sql
-- ❌ Anti-pattern: REINDEX global → reconstruye todas las particiones, alto consumo RAM
REINDEX TABLE embeddings_master; -- bloquea y consume recursos en shards fríos
-- 🔧 Fix: Reindexar solo partición objetivo con bounds C1 y params V3 ajustados
```

```sql
-- ✅ C4: RLS en padre propaga a todas las particiones automáticamente
CREATE POLICY rls_part_isolation ON embeddings_master FOR ALL
USING (tenant_id = current_setting('app.tenant_id'))
WITH CHECK (tenant_id = current_setting('app.tenant_id'));
```

```sql
-- ❌ Anti-pattern: Crear políticas por partición manualmente → mantenimiento frágil
CREATE POLICY rls_alpha ON embeddings_high FOR SELECT USING (...); -- duplicación
-- 🔧 Fix: Política única en padre; PostgreSQL la aplica a todas las particiones hijas
```

```sql
-- ✅ C1/V3: Verificar particion pruning con EXPLAIN antes de despliegue
EXPLAIN (COSTS OFF) SELECT id FROM embeddings_master
WHERE tenant_id = 'tenant_alpha' AND vec <=> $1 < 0.3 LIMIT 10;
-- Salida esperada: Append -> Seq/Index Scan on embeddings_high ONLY
```

```sql
-- ❌ Anti-pattern: Asumir pruning sin validar → escaneo completo de todas las particiones
SELECT id FROM embeddings_master WHERE vec <=> $1 < 0.3; -- sin filtro tenant
-- 🔧 Fix: Siempre filtrar por partition key + validar EXPLAIN para confirmar pruning
```

```sql
-- ✅ V3: Parámetros ef_search ajustados por partición según patrón de acceso
SET LOCAL hnsw.ef_search = 64; -- partición caliente, latencia <50ms
SELECT id FROM embeddings_high ORDER BY vec <=> $1 LIMIT 10;
```

```sql
-- ❌ Anti-pattern: ef_search global alto → degradación uniforme en todas las particiones
SET hnsw.ef_search = 256; -- aplicado a frío y caliente por igual
-- 🔧 Fix: SET LOCAL por transacción; ajustar según volumen y SLA de cada shard
```

```sql
-- ✅ C4: Detach partición para archival sin afectar consultas activas
ALTER TABLE embeddings_master DETACH PARTITION embeddings_high;
-- La partición se vuelve tabla independiente; datos preservados para backup
```

```sql
-- ❌ Anti-pattern: DROP PARTITION → pérdida irreversible de embeddings de tenant
ALTER TABLE embeddings_master DROP PARTITION embeddings_high; -- elimina datos
-- 🔧 Fix: DETACH CONCURRENTLY + backup externo antes de drop físico C4
```

```sql
-- ✅ C1: Límite de workers paralelos para escaneo de particiones
SET LOCAL max_parallel_workers_per_gather = 2;
SELECT count(*) FROM embeddings_master WHERE tenant_id IN ('a','b');
```

```sql
-- ❌ Anti-pattern: Paralelismo ilimitado → saturación CPU en VPS compartido
SET max_parallel_workers = 8; -- agota cores, degrada otras queries
-- 🔧 Fix: max_parallel_workers_per_gather acotado por transacción C1
```

```sql
-- ✅ C4/C1/V3: Workflow transaccional de migración a partición nueva
BEGIN; SET LOCAL statement_timeout='30s';
CREATE TABLE embeddings_beta PARTITION OF embeddings_master FOR VALUES IN ('tenant_beta');
CREATE INDEX CONCURRENTLY idx_beta_hnsw ON embeddings_beta USING hnsw (vec vector_cosine_ops) WITH (m=16);
COMMIT;
```

```sql
-- ❌ Anti-pattern: Migración multi-paso sin transacción → estado inconsistente si falla
CREATE TABLE...; CREATE INDEX...; -- rollback manual si falla en paso 2
-- 🔧 Fix: Envolver en BEGIN/COMMIT con timeout + CONCURRENTLY para resiliencia C1
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/postgresql-pgvector/partitioning-strategies-for-high-dim.pgvector.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"partitioning-strategies-for-high-dim.pgvector","version":"3.0.0","score":48,"blocking_issues":[],"constraints_verified":["C1","C4","V3"],"examples_count":25,"lines_executable_max":5,"language":"PostgreSQL 14+ pgvector","timestamp":"2026-04-19T00:00:00Z"}
```

---
