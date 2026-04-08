---
title: "Resource Guardrails - Agentic Infra Docs"
category: "Reglas"
priority: "Alta"
version: "1.0.0"
last_updated: "2026-04-05"
language: "es"
repository: "agentic-infra-docs"
owner: "Mantis-AgenticDev"
type: "rules"
ia_parser_version: "2.0"
auto_validate: true
compliance_check: "daily"
validation_script: "scripts/check-resources.sh"
auto_fixable: true
severity_scope: "critical"
tags:
  - resource-limits
  - docker
  - monitoring
  - tenant-id
  - C1
  - C2
related_files:
  - "01-RULES/01-ARCHITECTURE-RULES.md"
  - "00-CONTEXT/facundo-infrastructure.md"
  - "05-CONFIGURATIONS/docker/docker-compose.yml"
---

# RESOURCE GUARDRAILS

## Metadatos del Documento

- **Categoría:** Recursos
- **Prioridad de carga:** Siempre
- **Versión:** 1.0.0
- **Última actualización:** Marzo 2026
- **Archivos relacionados:** 01-ARCHITECTURE-RULES.md

---

## Regla RES-001: Límite de RAM Total

**Descripción:** Hardware limitado a 4 GB RAM total por VPS.

**Límites obligatorios:**

| Recurso      | Límite | Acción si excede                  |
|--------------|--------|-----------------------------------|
| RAM Total    | 4 GB   | No iniciar nuevos contenedores    |
| RAM n8n      | 1.5 GB | Limitar concurrencia de workflows |
| RAM MySQL    | 1 GB   | Ajustar buffer_pool_size          |
| RAM Qdrant   | 1 GB   | Limitar tamaño de colecciones     |
| RAM Sistema  | 0.5 GB | Reservado para OS                 |

**Comando Docker recomendado:**
```bash
docker run --memory="1.5g" --memory-swap="1.5g" n8n
```
**Violación crítica:** Intentar cargar modelos de IA locales (Ollama, LM Studio)

---

## Regla RES-002: Límite de CPU

**Descripción:** CPU limitada a 1 núcleo por VPS.

**Límites obligatorios:**

|Recurso	   |  Límite	     | Umbral de Alerta         |
|------------|---------------|------ -------------------|
|CPU Total	 | 1 núcleo	     | 80% sostenido por 5 min  |
|CPU n8n	   | 0.5 núcleo	   | 70% sostenido por 5 min  |
|CPU MySQL	 | 0.3 núcleo	   | 60% sostenido por 5 min  |
|CPU Qdrant	 | 0.2 núcleo	   | 50% sostenido por 5 min  |

**Acción correctiva:** Reducir concurrencia de workflows en n8n.

---

## Regla RES-003: Límite de Disco

**Descripción:** Disco limitado a 50 GB NVMe por VPS.

**Límites obligatorios:**

|Recurso	           | Límite	       | Umbral de Alerta    |
|--------------------|---------------|---------------------|
|Disco Total	       | 50 GB	       | 80% usado (40 GB)   |
|Disco MySQL	       | 20 GB	       | 70% usado (14 GB)   |
|Disco Qdrant        | 15 GB	       | 70% usado (10.5 GB) |
|Disco Logs	         | 5 GB	         | 80% usado (4 GB)    |
|Disco Backup Temp   | 10 GB	       | 50% usado (5 GB)    |

**Acción correctiva:** Rotar logs y limpiar backups temporales.

---

## Regla RES-004: Polling Mínimo Entre Consultas

**Descripción:** Evitar polling agresivo para conservar recursos.

**Límites obligatorios:**

|Tipo de Polling	     | Intervalo Mínimo	       |Justificación                       |
|----------------------|-------------------------|------------------------------------|
|Health Check VPS	     | 5 minutos	             | Equilibrio entre detección y carga |
|Backup Status	       | 1 hora	                 | Backup es proceso largo            |
|Alertas de Recursos   | 5 minutos	             | Coherente con health check         |
|WhatsApp Webhooks	   | Push (no polling)	     | uazapi usa webhooks                |

**Violación crítica:** Polling cada menos de 30 segundos.

---

## Regla RES-005: Máximo de Servicios Simultáneos

**Descripción:** Límite de servicios Docker simultáneos por VPS.

**Límites obligatorios:**

|VPS	      | Servicios	Máximos	   | Configuración          |
|-----------|----------------------|------------------------|
|VPS	1	    |     3	               | n8n, uazapi, Redis     |
|VPS	2	    |     3	               | EspoCRM, MySQL, Qdrant |
|VPS	3	    |     2	               | n8n, uazapi            |

**Violación crítica:** Ejecutar más servicios de los especificados.

---

## Regla RES-006: No Procesamiento Local Pesado

**Descripción:** Evitar procesamiento local de imagen, video o modelos grandes.

**Prohibido explícitamente:**

- Modelos de IA locales (Ollama, LM Studio, similares)
- Indexación vectorial local masiva
- Procesamiento de video en tiempo real
- Procesamiento de imagen batch grande

**Permitido:**

- APIs cloud (OpenRouter, Qdrant Cloud)
- Procesamiento por lotes pequeños (menos de 100 items)
- Transcripción de audio vía Deepgram API

---
    
## Regla RES-007: No Websockets Persistentes

**Descripción:** Evitar websockets persistentes que consuman memoria.

**Recomendación:** Preferir polling controlado o webhooks.

**Excepción:** uazapi requiere websocket para WhatsApp (no modificable).

---

## Regla RES-008: No Bucles Infinitos

**Descripción:** Todos los bucles deben tener límite máximo de iteraciones.

**Requisitos obligatorios:**

- Máximo 100 iteraciones por bucle en workflows
- Timeout máximo de 30 segundos por ejecución
- Reintentos máximo 3 veces con backoff exponencial

**Ejemplo de violación:** Bucle while sin condición de salida.

---

## Regla RES-009: Límite de Concurrencia en n8n

**Descripción:** n8n debe tener concurrencia limitada para evitar saturación.

**Configuración obligatoria:**

EXECUTIONS_PROCESS=main
EXECUTIONS_MAX_CONCURRENT=5
WEBHOOK_TIMEOUT=30000

**Justificación:** 5 ejecuciones concurrentes máximo para 4 GB RAM.

### Configuración de n8n para 4GB RAM (RES-009)

**Variables de entorno obligatorias en .env:**


| Variable                      | Valor            | Justificación            |
|-------------------------------|------------------|--------------------------|
| EXECUTIONS_PROCESS            | main             | Evita overhead de queue  |
| EXECUTIONS_MAX_CONCURRENT     | 5                | Máximo para 4GB RAM      |
| WEBHOOK_TIMEOUT               | 30000            | 30 segundos máximo       |
| MEMORY_LIMIT                  | 1536             | 1.5GB para n8n           |


---

## Regla RES-010: Monitoreo de Recursos Obligatorio

**Descripción:** Todos los VPS deben tener monitoreo de recursos activo.

**Métricas obligatorias:**

- RAM usada (porcentaje y MB)
- CPU usada (porcentaje)
- Disco usado (porcentaje y GB)
- Estado de contenedores Docker

**Frecuencia:** Cada 5 minutos mínimo.
**Alertas:** Ver 09-MONITORING-ALERTS.md

---

## Regla RES-011: tenant_id en métricas de monitoreo

| ID      | Regla                        | Descripción                                                                                              | Validación                                  |
|---------|------------------------------|----------------------------------------------------------------------------------------------------------|---------------------------------------------|
| RES-011 | tenant_id en logs y métricas | Toda métrica de recurso (CPU, RAM, disco) debe incluir `tenant_id` como label para aislamiento y billing | `check-resources.sh --verify-tenant-labels` |

**Ejemplo Docker Compose:**
```yaml
services:
  n8n:
    labels:
      - "monitoring.tenant_id=${TENANT_ID}"
    environment:
      - TENANT_ID=${TENANT_ID}
```

**Ejemplo Prometheus:**
```prompkl
container_cpu_usage_seconds_total{tenant_id="facundo_agro"}
```

---

## Umbrales de Alerta de Recursos

|Recurso	    | Advertencia	    | Crítico	         | Acción                    |
|-------------|-----------------|------------------|---------------------------|
|RAM	        | 85% por 5 min	  | 90% por 5 min	   | Reducir workflows activos |
|CPU	        | 80% sostenido	  | 90% sostenido	   | Limitar concurrencia      |
|Disco	      | 80%	            | 90%         	   | Limpiar logs y backups    |

---

## Checklist de Validación de Recursos

- [ ] Cada VPS tiene 4 GB RAM confirmado
- [ ] Límites de memoria Docker configurados
- [ ] Polling mínimo de 5 minutos implementado
- [ ] No hay modelos locales instalados
- [ ] Concurrencia de n8n limitada a 5
- [ ] Monitoreo de recursos activo
- [ ] Umbrales de alerta configurados

Versión 1.0.0 - Marzo 2026 - Mantis-AgenticDev
Licencia: Creative Commons para uso interno del proyecto



## 🔗 Conexiones Estructurales (Auto-generado)
[[README.md]]
[[01-RULES/00-INDEX.md]]
[[01-RULES/03-SECURITY-RULES.md]]
