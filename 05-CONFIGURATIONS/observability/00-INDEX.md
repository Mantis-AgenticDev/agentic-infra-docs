---
# FRONTMATTER CANÓNICO OBLIGATORIO
artifact_id: "00-INDEX-observability-index-v1.0.0"
artifact_type: "directory_index"
version: "1.0.0-COMPREHENSIVE"
constraints_mapped: ["C4","C5","C8","V3"]
canonical_path: "05-CONFIGURATIONS/observability/00-INDEX.md"
domain: "05-CONFIGURATIONS"
subdomain: "observability"
agent_role: "observability-coordinator"
language_lock: "markdown"
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain observability --file 05-CONFIGURATIONS/observability/00-INDEX.md --strict"
tier: 3
immutable: true
requires_human_approval_for_changes: true
audience: ["agentic_assistants", "sre_team"]
human_readable: true
checksum_sha256: "23de8258e892257e388b17e751cc26b0ca559d05195aba57aa2148255f6d2aa6"
# FIN FRONTMATTER
---
```

```markdown
# 📊 05-CONFIGURATIONS/observability/ — Índice de Observabilidad

> **Propósito**: Punto de entrada canónico y referencia técnica para toda la pila de monitoreo del ecosistema MANTIS. Mapea dashboards, reglas de alerta, agregación de logs, runbooks y estándares de métricas. Garantiza trazabilidad (C4), integridad estructural (C5) y observabilidad desde el día 1 (C8, V3).

## 🗺️ Mapa de Componentes

| Componente | Ruta Canónica | Propósito | Constraints | Estado | Validación |
|------------|---------------|-----------|-------------|--------|------------|
| **Dashboards Grafana** | `grafana/dashboards/` | Paneles de infra, app, base de datos y vectores | C4, C8, V3 | ✅ REAL | `grafana-cli`, API JSON |
| `vector-performance.json` | `grafana/dashboards/vector-performance.json` | Métricas HNSW/IVFFlat: latencia p95/p99, recall, memoria | V3, C8 | ✅ REAL | `jq empty`, Grafana import |
| **Alertas Prometheus** | `alerts/` | Reglas de umbral para degradación y fallos críticos | C7, C8, V3 | ✅ REAL | `promtool check rules` |
| `vector-alerts.yml` | `alerts/vector-alerts.yml` | Alertas específicas para búsqueda vectorial | V3, C7, C8 | ✅ REAL | `promtool check rules` |
| **Agregación de Logs** | `loki/` | Configuración de Loki, Promtail y retención | C4, C8 | ✅ REAL | `loki -verify-config` |
| `loki-config.yml` | `loki/config.yml` | Límites de cardinalidad, shipper, retención 30d | C4, C8 | ✅ REAL | `yq`, `loki` CLI |
| **Runbooks** | `runbooks/` | Procedimientos de diagnóstico, remediación y rollback | C7, C8 | ✅ REAL | `markdownlint`, checklist |
| `disaster-recovery.md` | `runbooks/disaster-recovery.md` | Recuperación de infraestructura completa (IaC → Datos → Apps) | C7, C8 | ✅ REAL | `orchestrator-engine.sh` |

## 📏 Estándares de Métricas (RED / USE)

Todos los servicios deben exponer métricas alineadas a estos estándares:

| Método | Métricas Obligatorias | Fuente | Ejemplo PromQL |
|--------|----------------------|--------|----------------|
| **RED** (Aplicaciones) | Rate, Errors, Duration | App `/metrics` | `rate(http_requests_total[5m])` |
| **USE** (Infra/DB) | Utilization, Saturation, Errors | Node Exporter, pg_stat | `node_memory_MemAvailable_bytes` |
| **Vector** (V3) | Latencia p95/p99, Recall, Índice size | Qdrant/pgvector exporter | `histogram_quantile(0.95, rate(qdrant_search_duration_seconds_bucket[5m]))` |

### Reglas de Etiquetado (C4: Trazabilidad)
- **Obligatorios**: `environment`, `service`, `tenant_id`, `instance`
- **Prohibidos (alta cardinalidad)**: `request_id`, `trace_id`, `user_email`, `sql_query`
- **Formato**: `snake_case`, sin espacios ni caracteres especiales.

## 🛡️ Validación y Provisionado

### Comandos de Auditoría
```bash
# Validar reglas de Prometheus
promtool check rules 05-CONFIGURATIONS/observability/alerts/*.yml

# Verificar configuración de Loki
loki -verify-config -config.file=05-CONFIGURATIONS/observability/loki/config.yml

# Validar dashboards JSON
for f in 05-CONFIGURATIONS/observability/grafana/dashboards/*.json; do
  jq empty "$f" || echo "❌ JSON inválido: $f"
done

# Validación integral con orchestrator
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain observability --strict
```

### Provisionado Automático
Grafana y Alertmanager se configuran vía archivos de provisioning en `05-CONFIGURATIONS/grafana/provisioning/`. No modificar dashboards manualmente en la UI; todos los cambios deben ser commiteados y aplicados por CI/CD.

## ⚠️ Anti-Patrones Explícitos (DO NOT)

❌ Crear alertas sin `for` o con `group_wait: 0s` (causa spam de notificaciones)  
❌ Usar `trace_id` o `request_id` como label indexado en Prometheus/Loki  
❌ Modificar dashboards en Grafana UI sin exportar a JSON y commitear  
❌ Omitir `runbook_url` en anotaciones de alertas críticas  
❌ Hardcodear umbrales sin justificación por perfil de infra (nano vs large)  

✅ **Siempre** validar reglas con `promtool` antes de aplicar  
✅ **Siempre** usar `external_labels` coherentes en Prometheus  
✅ **Siempre** vincular alertas a runbooks actualizados  
✅ **Siempre** documentar cambios en métricas/dashboards con CHANGELOG  

## 🔗 Enlaces Canónicos Relacionados
- [[../00-INDEX.md]] → Índice maestro del dominio `05-CONFIGURATIONS/`
- [[../templates/observability-template.yaml]] → Plantilla base de stack de monitoreo
- [[../configurations-master-agent.md]] → Agente coordinador transversal
- [[https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/]] → Docs oficiales Prometheus
- [[https://grafana.com/docs/grafana/latest/dashboards/provisioning/]] → Docs oficiales Grafana

---
*Documento generado automáticamente por `generate-index.sh` v1.0.0 | Mantenido por `observability-coordinator` | Constraints: C4, C5, C8, V3*

---
