---
ai_optimized: true
version: "v1.0.0"
constraints: ["C1", "C2", "C3", "C4", "C5", "C6"]
purpose: "Estrategia de despliegue multi-canal con alta disponibilidad, aislamiento por tenant y rollback determinista para MANTIS AGENTIC."
tags: ["deployment", "blue-green", "canary", "tenant-scoped", "rollout", "hardening", "ci-cd"]
related_files:
  - "[[../00-INDEX.md]]"
  - "[[../../05-CONFIGURATIONS/validation/validate-skill-integrity.sh]]"
  - "[[../../01-RULES/06-MULTITENANCY-RULES.md]]"
  - "[[../../01-RULES/04-API-RELIABILITY-RULES.md]]"
  - "[[../../05-CONFIGURATIONS/pipelines/.github/workflows/validate-skill.yml]]"
---

# 🚀 DESPLIEGUE MULTI-CANAL & ROLLOUT CONTROL

## 📋 Overview & Alcance
Este documento define los patrones de despliegue para agentes, APIs y pipelines de datos en entornos con recursos limitados (C1: ≤4GB RAM, C2: 1vCPU/servicio). Se prioriza **cero tiempo de inactividad**, **aislamiento estricto por tenant** (C4), **auditoría pre/post** (C5) y **gestión segura de secretos** (C3). Los despliegues se ejecutan mediante tres estrategias canónicas:

| Estrategia | Uso Recomendado | Consumo de Recursos | Rollback |
|------------|-----------------|---------------------|----------|
| **Blue/Green** | Migraciones mayores, cambios de esquema DB, actualización de infraestructura base | 2x temporal (mitigado escalando idle a 0.1 vCPU) | Instantáneo (swap de alias DNS/routing) |
| **Canary** | Nuevos modelos IA, ajustes de prompts, optimización de RAG, features experimentales | 1x + 5-25% tráfico extra | Gradual (revert % → 0) |
| **Tenant-Scoped** | Onboarding de nuevos clientes, pruebas A/B por industria, cumplimiento normativo | Escalado por grupo | Aislado (solo afecta al grupo target) |

## 🛡️ Mapeo de Constraints en Despliegue
| Constraint | Implementación en Rollout | Verificación Automática |
|------------|---------------------------|-------------------------|
| **C1: RAM≤4GB** | Límites `mem_limit` en Docker, `swapoff` controlado, connection pools ≤30 | `docker stats`, `validate-skill-integrity.sh` |
| **C2: 1vCPU** | `cpus: '1.0'`, `nice 10` para workers, concurrencia n8n ≤5 | `cpu-quota` cgroups, `EXECUTIONS_MAX_CONCURRENT` |
| **C3: Zero Hardcode** | Inyección vía `docker --env-file`, GitHub Actions secrets, `age` encryption | `audit-secrets.sh` en pre-deploy |
| **C4: tenant_id** | Routing por header `X-Tenant-ID`, políticas RLS activadas pre-swap, validación de payload | `check-rls.sh`, middleware de routing |
| **C5: Backup+SHA256** | Snapshot pre-despliegue, verificación checksum post-rollback, logs firmados | `sha256sum`, `backup-encryption.md` |
| **C6: Cloud-Only** | Fallback a OpenRouter/Qwen cloud, zero inferencia local excepto Llama con excepción documentada | `grep -r 'local.*inference'`, validación C6 en schema |

---

## 📦 15 EJEMPLOS DE DESPLIEGUE MULTI-CANAL

| # | Canal/Contexto | Estrategia | Configuración Clave | Cumplimiento C1-C6 | Trigger de Rollback |
|---|----------------|------------|---------------------|--------------------|---------------------|
| 1 | **WhatsApp + OpenRouter** | Canary 5%→100% | `WEIGHT_BLUE=95 WEIGHT_GREEN=5` en nginx | C1/C2: pool≤20, C3: env var, C4: tenant header | Latencia >3s o error rate >2% |
| 2 | **Telegram Bot + Qwen** | Blue/Green | `docker-compose -f dc-blue.yml -f dc-green.yml up -d` | C1: 512MB/container, C5: snapshot pre-swap | Health check `/ping` falla 3x consecutivas |
| 3 | **Email Campaign (Gmail SMTP)** | Tenant-Scoped | Cola Redis separada por `tenant_id`, rate limit 50/h | C2: 0.5 vCPU worker, C3: OAuth token rotado | Bounce rate >5% o quota API excedida |
| 4 | **Voice Agent (STT/TTS)** | Canary | Chunking 2s, WebSocket keep-alive, buffer 64KB | C1: 768MB STT, C6: cloud STT/TTS only | Jitter >150ms o pérdida de frames >3% |
| 5 | **CRM Sync (EspoCRM)** | Blue/Green | Migración schema con `prisma migrate deploy --skip-generate` | C4: RLS pre-activa, C5: checksum DB dump | Foreign key violation o timeout >15s |
| 6 | **RAG Ingestion Pipeline** | Tenant-Scoped | Qdrant collection por tenant, ingest rate 100 docs/min | C1: mem_limit 1GB, C3: API keys en vault | Index corruption detectada o OOM kill |
| 7 | **Image Gen API** | Canary | Batch size=1, retry=3, timeout=45s | C2: 1vCPU, C6: OpenRouter routing | Coste >$0.05/img o fallo de safety filter |
| 8 | **Video Gen Batch** | Scheduled Blue/Green | Cron 02:00 UTC, swap 01:30, monitor 04:00 | C1/C2: auto-scale down idle, C5: artifact hash | GPU timeout o codec fallback fail |
| 9 | **Multi-tenant DB Migration** | Tenant-Scoped | `SET LOCAL app.current_tenant_id = ...`, advisory lock | C4: RLS obligatorio, C5: backup encriptado | Lock wait >30s o constraint violation |
| 10 | **Webhook Router (n8n)** | Canary | Split traffic 10% nuevo flow, metricas Prometheus | C2: `EXECUTIONS_MAX_CONCURRENT=3` | Queue backlog >500 o memory >80% |
| 11 | **Calendar Sync (GCal)** | Blue/Green | OAuth refresh token rotation, delta sync | C3: `GCLIENT_SECRET` masked, C6: cloud API | Sync drift >5min o quota exceeded 429 |
| 12 | **PDF OCR Pipeline** | Tenant-Scoped | Mistral OCR chunked, temp dir `/tmp/ocr_$TENANT` | C1: cleanup 24h, C5: hash output | Parse error rate >10% o disk >85% |
| 13 | **Social Media Auto-Post** | Canary | Dry-run 24h, publish 10%, monitor engagement | C2: 0.25 vCPU scheduler, C4: tenant filter | API ban o hashtag shadowban detectado |
| 14 | **Health Monitor & Auto-Scale** | Tenant-Scoped | Cron check 30s, scale down if CPU<20% 1h | C1: alert RAM>3.5GB, C3: webhook secrets | Fallback a modo degradado si escala >2 |
| 15 | **Fallback Router (Cloud→Cache)** | Blue/Green | Redis cache TTL 1h, fallback si 503 >3 | C6: cloud primary, C5: cache integrity hash | Cache miss rate >40% o stale data >2h |

---

## 🔧 15 PROBLEMAS RESUELTOS (DEPLOYMENT & OPS)

| # | Problema | Causa Raíz | Solución Aplicada | Constraint Afectado |
|---|----------|------------|-------------------|---------------------|
| 1 | **OOM Kill en VPS 4GB** | PostgreSQL + n8n + Qdrant sin límites | `docker-compose` con `mem_limit: 1g`, `shm_size: 256m`, tune `shared_buffers=512MB` | C1 |
| 2 | **Fuga de datos cross-tenant** | Query sin `WHERE tenant_id` en migración | Activar `ENABLE ROW LEVEL SECURITY`, middleware inyecta `app.current_tenant_id` | C4 |
| 3 | **Rate Limit API IA agotado** | Picos de tráfico no throttleados | Implementar `token_bucket` por tenant, retry exponencial, fallback a modelo económico | C2, C6 |
| 4 | **Secretos expuestos en logs CI** | `echo $API_KEY` en debug mode | GitHub Actions `secret::mask`, `set +x` en bash, auditoría `audit-secrets.sh` | C3 |
| 5 | **Deploy bloqueado en "pending"** | Health check timeout 10s, app init 15s | Aumentar `healthcheck.start_period: 20s`, readiness probe separado de liveness | C1, C2 |
| 6 | **Deadlock en migración DB** | Transacciones largas sin advisory lock | `pg_advisory_xact_lock(hashtext('migrate_v2'))`, transacciones por tenant | C4, C5 |
| 7 | **Firma Webhook inválida** | Desfase horario >2s entre servidor y proveedor | `chrony` sync, validación `X-Hub-Signature-256`, tolerancia ±30s | C3, C6 |
| 8 | **Índice RAG corrupto post-deploy** | Escritura concurrente durante ingestión | Lock de colección, verificación `sha256sum` de chunks, restore desde backup | C5 |
| 9 | **Latencia Voice >2s** | Buffering síncrono, chunk size 10s | Streaming WebSocket, chunk 1.5s, overlap 200ms, QoS `DSCP=46` | C2, C6 |
| 10 | **n8n Workflow OOM** | Array de 50k objetos en memoria | `splitInBatches`, procesamiento chunked, `NODE_FUNCTION_ALLOW_BUILTIN` restricted | C1 |
| 11 | **DNS TTL 3600s bloquea canary** | Propagación lenta, tráfico viejo sigue | Pre-warm DNS, usar ALB/Ingress routing, TTL 60s en entorno staging | C2, C6 |
| 12 | **SSL expira sin alerta** | Certbot no renew automático | Cron `certbot renew --quiet`, webhook Slack on failure, monitor 30d pre-expiry | C3, C5 |
| 13 | **Onboarding tenant falla idempotencia** | Script corre 2x, duplica schema | `CREATE TABLE IF NOT EXISTS`, `UPSERT` con `ON CONFLICT`, lock por tenant_id | C4, C5 |
| 14 | **Logs explotan en tráfico alto** | `console.log` sin sampling en prod | Estructurado JSON, `loglevel=warn`, sampling 10% info, rotación 7d | C1, C2 |
| 15 | **Rollback falla por schema drift** | DB nueva incompatible con código viejo | Migraciones `UP/DOWN` simétricas, backward-compatible DDL, pin versión schema | C5 |

---

## 🔄 Procedimiento de Rollout Determinista

### 1. Pre-Despliegue (Checklist Obligatorio)
```bash
# 1. Validación SDD completa
./05-CONFIGURATIONS/validation/validate-skill-integrity.sh 02-SKILLS/ predeploy-report.json 0 1

# 2. Backup encriptado + SHA256
pg_dump -U $DB_USER -d $DB_NAME | age -r $BACKUP_PUB_KEY -o backup_$(date +%F).sql.age
sha256sum backup_*.sql.age > backup_$(date +%F).sha256

# 3. Verificación de secretos y RLS
./05-CONFIGURATIONS/validation/audit-secrets.sh . secrets-predeploy.json 0 1
./05-CONFIGURATIONS/validation/check-rls.sh . rls-predeploy.json 0 1
```

### 2. Ejecución Canary (Ejemplo Nginx Routing)
```nginx
upstream blue { server blue_app:3000; }
upstream green { server green_app:3000 backup; }

map $http_x_tenant_id $canary_weight {
    default 95;
    "~^rest-.*" 5;  # 5% tráfico nuevo para restaurantes
    "~^odonto-.*" 10; # 10% para odontología
}

server {
    listen 80;
    location / {
        proxy_pass http://blue;
        # Canary logic via weighted round-robin o API gateway
    }
}
```

### 3. Rollback Inmediato
```bash
#!/usr/bin/env bash
set -euo pipefail
# Swap de aliases DNS / Docker labels
docker service update --detach=false \
  --label-add rollout.status=rollback \
  --env-add VERSION=$(cat .rollback_version) \
  mantis-agentic-app

# Verificar integridad post-rollback
sha256sum -c backup_*.sha256
./05-CONFIGURATIONS/validation/validate-skill-integrity.sh . post-rollback.json 0 1
```

---

## 📊 Validación Post-Despliegue & Auditoría
| Métrica | Umbral de Éxito | Herramienta | Acción si falla |
|---------|----------------|-------------|-----------------|
| Error Rate HTTP | < 1.5% | Prometheus/Grafana | Canary → 0%, rollback automático |
| Latencia P95 | < 2000ms | n8n metrics / OpenTelemetry | Escalar workers o reducir concurrencia (C2) |
| RAM Max | ≤ 3.6GB (90%) | `docker stats`, cgroups | Kill idle pods, activar fallback |
| Tenant Isolation | 0 leaks cross-tenant | `check-rls.sh`, query audit | Revert deploy, patch RLS, rotar keys |
| Checksum Integrity | 100% match | `sha256sum -c` | Restaurar backup, investigar corrupción |

**Regla de Operación:** 
- Ningún despliegue se considera estable hasta 24h de monitoreo continuo con métricas dentro de umbral.
- Todos los artefactos generados deben registrar `audit_metadata.output_sha256` y `ci_cd_ready: true`.
- Las excepciones a C1/C2/C6 requieren aprobación documentada y `C6_exception_documented: true` o `resource_bypass_justified` en frontmatter.

---

## 🔗 Cross-References & Navegación
- Validación Estructural: `[[../../05-CONFIGURATIONS/validation/validate-skill-integrity.sh]]`
- Auditoría de Secretos: `[[../../05-CONFIGURATIONS/validation/audit-secrets.sh]]`
- RLS & Multi-Tenant: `[[../../05-CONFIGURATIONS/validation/check-rls.sh]]`
- Plantilla SDD: `[[../../05-CONFIGURATIONS/templates/skill-template.md]]`
- Pipeline CI/CD: `[[../../05-CONFIGURATIONS/pipelines/.github/workflows/validate-skill.yml]]`
- Reglas de Arquitectura: `[[../../01-RULES/01-ARCHITECTURE-RULES.md]]`
- Índice Maestro: `[[../00-INDEX.md]]`

> 📝 *Documento generado bajo especificación SDD. Estrategias validadas en entornos ≤4GB RAM/1vCPU con aislamiento multi-tenant. Última revisión estructural: v1.0.0. Mantener sincronizado con cada rollout a producción.*
