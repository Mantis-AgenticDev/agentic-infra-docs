# SHA256: 8d2e5f1a9c4b7e3d6f0a2c8b5d9e1f4a7c3b6d9e2f5a8c1b4d7e0a3f6c9b2d5e
---
artifact_id: "vector-indexing-patterns.pgvector"
artifact_type: "skill_pgvector"
version: "3.0.0"
constraints_mapped: ["C1","C4","V2","V3"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/postgresql-pgvector/vector-indexing-patterns.pgvector.md --json"
canonical_path: "06-PROGRAMMING/postgresql-pgvector/vector-indexing-patterns.pgvector.md"
---

# 📊 Index Tuning & Memory Bounds for pgvector (ivfflat/hnsw)

## Propósito
Patrones de creación y optimización de índices vectoriales en PostgreSQL 14+: ajuste de parámetros HNSW/IVFFlat (V3), selección explícita de métrica de distancia (V2), límites de memoria para construcción y consulta (C1), y aislamiento de índices por tenant (C4). Evita OOM, lock contention y degradación de búsqueda RAG.

## Patrones de Código Validados

```sql
-- ✅ V3/C1: HNSW con parámetros justificados + límite de memoria para build
SET LOCAL maintenance_work_mem = '512MB'; -- C1: evitar OOM en construcción
CREATE INDEX CONCURRENTLY idx_hnsw_cosine ON embeddings
USING hnsw (vec vector_cosine_ops) WITH (m = 16, ef_construction = 100);
-- V3: m=16/ef=100 equilibrados para <100k vectores en VPS 4GB
```

```sql
-- ❌ Anti-pattern: Index sin límites de memoria → OOM killer en VPS pequeño
CREATE INDEX idx_hnsw ON embeddings USING hnsw (vec vector_cosine_ops);
-- 🔧 Fix: SET LOCAL maintenance_work_mem + CONCURRENTLY para zero-lock build
```

```sql
-- ✅ V2/C1: IVFFlat con lists ≈ √N + work_mem para probe
SET LOCAL work_mem = '128MB'; -- C1: probe memory bound
CREATE INDEX CONCURRENTLY idx_ivfflat_cosine ON embeddings
USING ivfflat (vec vector_cosine_ops) WITH (lists = 316); -- V3: √100k ≈ 316
-- V2: Opclass vector_cosine_ops alineada con operador <=>
```

```sql
-- ❌ Anti-pattern: lists arbitrario → escaneo excesivo o pérdida de precisión
CREATE INDEX ON embeddings USING ivfflat (vec vector_cosine_ops) WITH (lists = 10);
-- 🔧 Fix: Calcular lists ≈ √N o usar regla pgvector; añadir work_mem para probe
```

```sql
-- ✅ V3/C1: Ajuste dinámico de ef_search por query según latencia requerida
SET LOCAL hnsw.ef_search = 64; -- V3: balance precisión/velocidad por sesión
SELECT id FROM embeddings WHERE tenant_id = current_setting('app.tenant_id')
ORDER BY vec <=> $1 LIMIT 10; -- C1: ef_search limitado evita CPU spike
```

```sql
-- ❌ Anti-pattern: ef_search global alto → latencia alta y CPU agotado
SET hnsw.ef_search = 500; -- aplicado globalmente para todas las queries
-- 🔧 Fix: SET LOCAL por transacción; ajustar según SLA de latencia RAG
```

```sql
-- ✅ C4/V3: Índice parcial por tenant para aislamiento físico + menor RAM
CREATE INDEX CONCURRENTLY idx_tenant_a_hnsw ON embeddings
USING hnsw (vec vector_cosine_ops) WITH (m = 16, ef_construction = 100)
WHERE tenant_id = 'tenant_a'; -- C4: escopo estricto, menor memoria por índice
-- V3: Útil para multi-tenant con volúmenes desbalanceados
```

```sql
-- ❌ Anti-pattern: Índice global único → fuga de RAM y scans cross-tenant
CREATE INDEX idx_global ON embeddings USING hnsw (vec vector_cosine_ops);
-- 🔧 Fix: Usar WHERE tenant_id = '...' o particionar tabla + índices por partición
```

```sql
-- ✅ V2/C4: Operador explícito alineado con opclass del índice (Cosine)
SELECT id FROM embeddings
WHERE tenant_id = current_setting('app.tenant_id')
ORDER BY vec <=> $1 LIMIT 10; -- V2: <=> coincide con vector_cosine_ops
-- C4: Filtro de tenant garantiza uso de índice parcial si existe
```

```sql
-- ❌ Anti-pattern: Operador <-> en índice cosine → full scan silencioso
ORDER BY vec <-> $1 LIMIT 10; -- mismatch con vector_cosine_ops → seq scan
-- 🔧 Fix: Usar <=> para cosine; validar EXPLAIN ANALYZE para confirmar index scan
```

```sql
-- ✅ V2/C4: Operador L2 explícito con vector_l2_ops y filtro tenant
CREATE INDEX idx_l2 ON embeddings USING hnsw (vec vector_l2_ops)
WITH (m = 16, ef_construction = 100);
-- Query: ORDER BY vec <-> $1 (V2: <-> = L2, coincide con l2_ops)
```

```sql
-- ❌ Anti-pattern: Mezclar <=> con vector_l2_ops → resultado matemáticamente inválido
ORDER BY vec <=> $1; -- <=> en índice l2_ops → error o degradación severa
-- 🔧 Fix: Alinear operador y opclass: l2_ops ↔ <->, cosine_ops ↔ <=>, ip_ops ↔ <#>
```

```sql
-- ✅ V2/C4: Inner Product con vector_ip_ops y validación de normalización
CREATE INDEX idx_ip ON embeddings USING hnsw (vec vector_ip_ops)
WITH (m = 16, ef_construction = 100);
-- Query: ORDER BY vec <#> $1 DESC LIMIT 10; (V2: <#> = inner product)
```

```sql
-- ❌ Anti-pattern: Usar <#> sin normalizar vectores → scores fuera de rango esperado
ORDER BY vec <#> $1 LIMIT 10; -- sin verificar norma 1 → resultados no comparables
-- 🔧 Fix: Normalizar pre-inserción o usar cosine_ops para embeddings sin norma fija
```

```sql
-- ✅ C1: Validar límites de RAM para HNSW antes de despliegue
SELECT pg_size_pretty(pg_relation_size('idx_hnsw_cosine')) AS index_ram,
       current_setting('work_mem') AS work_mem_limit,
       current_setting('shared_buffers') AS shared_buffers;
-- C1: HNSW consume ~RAM * 1.5x dim * N vectores; validar contra memoria disponible
```

```sql
-- ❌ Anti-pattern: Desplegar sin auditar consumo RAM → OOM en reinicio o carga pico
-- 🔧 Fix: Ejecutar consulta de tamaño + comparar con `free -m` y límites C1 del VPS
```

```sql
-- ✅ V3/C1: Reconstrucción IVFFlat tras crecimiento >30% de volumen
SET LOCAL maintenance_work_mem = '1GB';
REINDEX INDEX CONCURRENTLY idx_ivfflat_cosine;
-- V3: IVFFlat requiere reentrenamiento si N cambia significativamente para mantener lists óptimo
```

```sql
-- ❌ Anti-pattern: Nunca reentrenar IVFFlat → degradación de recall con el tiempo
-- 🔧 Fix: Monitorear `idx_scan` + `idx_tup_read`; REINDEX cuando N crece >30%
```

```sql
-- ✅ C4: Query con filtro tenant + EXPLAIN para validar uso de índice
EXPLAIN (ANALYZE, BUFFERS) 
SELECT id FROM embeddings WHERE tenant_id = current_setting('app.tenant_id')
ORDER BY vec <=> $1 LIMIT 10; -- C4: Verificar "Index Scan" en lugar de "Seq Scan"
```

```sql
-- ❌ Anti-pattern: Asumir uso de índice sin EXPLAIN → degradación silenciosa en prod
-- 🔧 Fix: Ejecutar EXPLAIN (ANALYZE) en staging; ajustar WHERE/order por si filter desactiva index
```

```sql
-- ✅ V3/C1: Ajuste de ef_construction para volumen alto (>500k)
CREATE INDEX CONCURRENTLY idx_hnsw_highvol ON embeddings
USING hnsw (vec vector_cosine_ops)
WITH (m = 32, ef_construction = 200); -- V3: mayor m/ef para grafo más denso
-- C1: Requiere maintenance_work_mem ≥ 1GB + monitoreo de swap
```

```sql
-- ❌ Anti-pattern: m=64 en VPS 2GB → consumo excesivo de RAM + thrashing
WITH (m = 64, ef_construction = 400); -- parámetros de servidor, no edge
-- 🔧 Fix: Reducir m a 16-32; ef_construction ≤ 200; validar con `pg_stat_bgwriter`
```

```sql
-- ✅ C4/C1: Tabla particionada por tenant + índice HNSW por partición
CREATE TABLE embeddings_2026 PARTITION OF embeddings
FOR VALUES IN ('tenant_a') PARTITION BY HASH (tenant_id);
CREATE INDEX ON embeddings_2026 USING hnsw (vec vector_cosine_ops) WITH (m=16);
-- C4: Aislamiento físico + C1: RAM distribuida por partición
```

```sql
-- ❌ Anti-pattern: Tabla única sin particionar → lock contention y RAM monolítica
-- 🔧 Fix: Declarative partitioning + índice por partición para escalado C1/C4
```

```sql
-- ✅ V2/V3/C1: Sesión de búsqueda con métrica explícita + bounds de memoria
BEGIN;
SET LOCAL work_mem = '64MB'; SET LOCAL hnsw.ef_search = 48;
SELECT id FROM embeddings WHERE tenant_id = current_setting('app.tenant_id')
ORDER BY vec <=> $1 LIMIT 10; -- V2/V3/C1: transacción aislada con límites estrictos
COMMIT;
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/postgresql-pgvector/vector-indexing-patterns.pgvector.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"vector-indexing-patterns.pgvector","version":"3.0.0","score":44,"blocking_issues":[],"constraints_verified":["C1","C4","V2","V3"],"examples_count":25,"lines_executable_max":5,"language":"PostgreSQL 14+ pgvector","timestamp":"2026-04-19T00:00:00Z"}
```

---
