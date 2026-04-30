---
# FRONTMATTER CANÓNICO OBLIGATORIO
artifact_id: "runbook-template-v1.0.0"
artifact_type: "runbook_template"
version: "1.0.0-COMPREHENSIVE"
constraints_mapped: ["C7","C8"]
canonical_path: "05-CONFIGURATIONS/templates/runbook-template.md"
domain: "05-CONFIGURATIONS"
subdomain: "templates"
agent_role: "runbook-templating"
language_lock: "markdown"
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain templates --file 05-CONFIGURATIONS/templates/runbook-template.md --strict"
tier: 3
immutable: true
requires_human_approval_for_changes: true
audience: ["agentic_assistants"]
human_readable: true
checksum_sha256: "887530d3224f69f722f6dded0e9246dabc8116f25a7e78504cce9bac93513b23"
# FIN FRONTMATTER
---


# Runbook Template — MANTIS AGENTIC ECOSYSTEM v2.0.0

> **⚠️ Instrucciones de uso**: Copiar este archivo a `05-CONFIGURATIONS/observability/runbooks/{incident-name}.md`, reemplazar todos los placeholders `{...}` con valores específicos del incidente, y eliminar esta nota antes de commitear.

---

## 📋 Metadata del Runbook

| Campo | Valor |
|-------|-------|
| **Runbook ID** | `RB-{YYYY}-{NNN}` (ej: `RB-2026-004`) |
| **Título** | `{Descripción clara del incidente}` |
| **Severidad** | `P1` / `P2` / `P3` / `P4` |
| **Dominio afectado** | `05-CONFIGURATIONS/{subdominio}` |
| **Constraint(s) relacionado(s)** | `C7`, `C8`, `V1-V3` (según aplique) |
| **Fecha de creación** | `{YYYY-MM-DD}` |
| **Última actualización** | `{YYYY-MM-DD}` |
| **Owner** | `{equipo o agente responsable}` |
| **Estado** | `DRAFT` / `REVIEW` / `APPROVED` / `DEPRECATED` |

---

## 🎯 Objetivo del Runbook

> Breve descripción del propósito: ¿Qué problema resuelve este procedimiento? ¿Bajo qué condiciones se debe ejecutar?

**Ejemplo**:  
*"Este runbook guía la recuperación ante degradación de búsqueda vectorial (latencia p95 > 500ms) en entornos con índice HNSW. Aplicable cuando la alerta `VectorSearchHighLatencyP95` se dispara y persiste por >5 minutos."*

---

## 🔍 Síntomas y Detección

### Indicadores Clave (KPIs)
| Métrica | Umbral de Alerta | Fuente |
|---------|-----------------|--------|
| `{metric_name}` | `{threshold}` | `{prometheus/grafana/log}` |
| `vector_search_duration_seconds{quantile="0.95"}` | `> 0.5s` | Prometheus |
| `process_resident_memory_bytes` | `> 85% del límite` | Node Exporter |

### Alertas Asociadas
```yaml
- alert: {AlertName}
  severity: {warning|critical}
  expression: {PromQL}
  for: {duration}
```

### Logs de Referencia
```bash
# Comandos para buscar logs relevantes
kubectl logs -l app={service} --since=1h | grep -i "error\|timeout"
journalctl -u {service} --since "10 minutes ago" | tail -100
```

---

## 🧭 Flujo de Diagnóstico Paso a Paso

> **Regla de oro**: Ejecutar pasos en orden. No saltar a remediación sin confirmar diagnóstico.

### Paso 1: Confirmar alcance del incidente
```bash
# Verificar si afecta a un tenant específico o globalmente
curl -s "http://prometheus:9090/api/v1/query?query=up{job=~\"mantis.*\"}" | jq '.data.result[] | {instance, tenant_id}'
```
- [ ] ¿El incidente afecta a `{tenant_id}` específico? → Ir a **Sección A: Aislamiento de Tenant**
- [ ] ¿El incidente es global (todos los tenants)? → Continuar con Paso 2

### Paso 2: Verificar salud de dependencias
```bash
# Checklist de dependencias críticas
- [ ] Base de datos: `pg_isready -h {db_host} -U {db_user}`
- [ ] Caché Redis: `redis-cli -h {redis_host} ping`
- [ ] Vector DB: `curl -f http://{qdrant_host}:6333/readyz`
- [ ] Proxy/Ingress: `curl -f http://localhost/health`
```

### Paso 3: Analizar métricas de rendimiento
```bash
# Consultas Prometheus para diagnóstico rápido
# Latencia por endpoint
histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket{job="mantis-app"}[5m])) by (le, endpoint))

# Tasa de errores 5xx
sum(rate(http_requests_total{status=~"5..", job="mantis-app"}[5m])) / sum(rate(http_requests_total{job="mantis-app"}[5m]))

# Uso de memoria/CPU del servicio vectorial
process_resident_memory_bytes{job=~"qdrant|pgvector"}
rate(process_cpu_seconds_total{job=~"qdrant|pgvector"}[5m]) * 100
```

### Paso 4: Revisar logs estructurados (Loki)
```bash
# Query Loki para errores recientes
{job="mantis-app", level="error"} | json | __error__ != "" | line_format "{{.msg}} ({{.trace_id}})"

# Filtrar por tenant_id si aplica
{job="mantis-app", tenant_id="{specific_tenant}"} |~ "timeout|connection refused"
```

---

## 🛠️ Procedimientos de Remediación

> **⚠️ Advertencia**: Ejecutar solo tras confirmar diagnóstico. Documentar cada comando ejecutado en el log de incidente.

### Escenario A: Degradación de índice vectorial (HNSW/IVFFlat)
```bash
# 1. Verificar estado del índice
psql "$DATABASE_URL" -c "SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'embeddings';"

# 2. Si el índice está corrupto o fragmentado, reindexar (en ventana de mantenimiento)
# ⚠️ Esta operación bloquea escrituras en la tabla
psql "$DATABASE_URL" -c "REINDEX INDEX CONCURRENTLY embeddings_vector_idx;"

# 3. Ajustar parámetros de búsqueda temporalmente (trade-off precisión/velocidad)
# Para HNSW: reducir ef_search para mejorar latencia (pérdida leve de recall)
SET hnsw.ef_search = 64;  # Valor por defecto: 128

# 4. Monitorear métricas post-cambio
# Esperar 2-5 minutos y verificar que latencia p95 < 500ms
```

### Escenario B: Presión de memoria en servicio vectorial
```bash
# 1. Verificar límites actuales del contenedor
docker inspect {container_name} | jq '.[0].HostConfig.Memory'

# 2. Si está cerca del límite, escalar verticalmente (requiere redeploy)
# Actualizar docker-compose.yml:
# deploy.resources.limits.memory: "4G" → "6G"

# 3. Como medida temporal, reducir concurrencia de queries
# En la app: limitar max_concurrent_vector_queries a 50% del valor actual

# 4. Reiniciar servicio con nuevos límites
docker compose up -d --no-deps {service_name}
```

### Escenario C: Fallo de conexión a dependencias
```bash
# 1. Verificar conectividad de red
nc -zv {db_host} 5432
nc -zv {redis_host} 6379

# 2. Si hay timeout, revisar reglas de firewall/security group
# AWS: aws ec2 describe-security-groups --group-ids {sg_id}
# GCP: gcloud compute firewall-rules list --filter="name~'{rule_pattern}'"

# 3. Reiniciar conexión pool de la aplicación (sin downtime)
# Ejemplo para Node.js:
curl -X POST http://localhost:8080/admin/db/reconnect
```

---

## 🔙 Procedimiento de Rollback

> Usar **solo si la remediación empeora el incidente** o no resuelve en <10 minutos.

### Rollback de configuración de índice
```bash
# Restaurar parámetros HNSW anteriores
psql "$DATABASE_URL" -c "SET hnsw.ef_search = 128;"  # Valor original

# Si se ejecutó REINDEX y causó bloqueo, abortar (si es posible)
# ⚠️ No hay rollback automático para REINDEX; requiere restore de backup
```

### Rollback de despliegue
```bash
# Docker Compose: revertir a imagen anterior
docker compose up -d --no-deps {service_name} --force-recreate --no-build

# Kubernetes: rollback de deployment
kubectl rollout undo deployment/{deployment_name} --context={cluster}

# Verificar salud post-rollback
bash 05-CONFIGURATIONS/scripts/health-check.sh --env {environment}
```

### Rollback de estado de base de datos (último recurso)
```bash
# ⚠️ Solo con aprobación de arquitecto y ventana de mantenimiento
# 1. Identificar punto de recuperación válido (antes del incidente)
# 2. Restaurar desde backup S3/GCS
pg_restore -d "$DATABASE_URL" -n tenant_{tenant_id} /backups/{backup_file}.dump

# 3. Validar integridad post-restore
bash 05-CONFIGURATIONS/scripts/backup-verify.sh --env {environment} --backup-path /backups/{backup_file}.dump
```

---

## ✅ Checklist de Validación Post-Remediación

> Completar antes de cerrar el incidente.

- [ ] Latencia p95 de búsqueda vectorial < 500ms (verificar en Grafana)
- [ ] Tasa de errores 5xx < 0.1% en últimos 5 minutos
- [ ] Health check `/health/ready` responde con `status: ok`
- [ ] No hay alertas críticas activas en Alertmanager
- [ ] Logs estructurados no muestran errores recurrentes
- [ ] Métricas de negocio (ej: queries exitosas/min) recuperadas a nivel basal
- [ ] Notificar a stakeholders vía Slack/Email con resumen ejecutivo

---

## 📞 Contactos y Escalamiento

| Rol | Contacto | Canal | Disponibilidad |
|-----|----------|-------|---------------|
| **Owner del servicio** | `{name}@mantis.agentic` | Slack `#{team}` | 24/7 |
| **Arquitecto de turno** | `{architect}@mantis.agentic` | PagerDuty | On-call rota |
| **Soporte de base de datos** | `dba-team@mantis.agentic` | Slack `#dba-alerts` | Business hours |
| **Escalamiento crítico (P1)** | `incident-commander@mantis.agentic` | Teléfono + Slack | 24/7 |

---

## 📚 Referencias y Enlaces Relacionados

- [[interface-spec.yaml]] — Contrato de interfaz Terraform↔Docker↔Agents
- [[vector-alerts.yml]] — Reglas de alerta para degradación vectorial
- [[backup-verify.sh]] — Script de verificación de integridad de backups
- [[disaster-recovery.md]] — Runbook maestro de recuperación de infraestructura
- Grafana Dashboard: [Vector Performance](http://grafana:3000/d/mantis-vector-perf)

---

## 🔄 Historial de Revisiones

| Versión | Fecha | Autor | Cambios | Estado |
|---------|-------|-------|---------|--------|
| `1.0.0` | `{YYYY-MM-DD}` | `{author}` | Creación inicial | `APPROVED` |
| `0.1.0` | `{YYYY-MM-DD}` | `{author}` | Borrador inicial | `DRAFT` |

---

## ⚠️ Anti-Patrones Explícitos (DO NOT)

❌ **Nunca** ejecutar remediation sin confirmar diagnóstico primero  
❌ **Nunca** omitir el checklist post-remediación antes de cerrar incidente  
❌ **Nunca** modificar parámetros de índice en producción sin ventana de mantenimiento aprobada  
❌ **Nunca** usar `DROP INDEX` o `TRUNCATE` sin backup previo y aprobación de arquitecto  
❌ **Nunca** compartir credenciales o secrets en logs, screenshots o canales públicos  

✅ **Siempre** documentar cada comando ejecutado en el log de incidente  
✅ **Siempre** notificar a stakeholders al iniciar y cerrar incidente  
✅ **Siempre** actualizar este runbook si se descubre un paso más efectivo  

---

> **Nota final**: Este runbook es un documento vivo. Si durante la ejecución descubres un paso más efectivo, un síntoma no documentado o un contacto actualizado, **actualízalo inmediatamente** y commitea con mensaje trazable:  
> `chore(runbook): update RB-2026-NNN with improved vector-index recovery steps`


---
