---
file_id: FAC-INFRA-002
file_name: facundo-infrastructure.md
version: 1.1.0  # ← Incrementar
created: 2026-04-01
last_updated: 2026-04-01
author: Facundo (Mantis-AgenticDev)
category: INFRASTRUCTURE
priority: CRITICAL
tokens_estimate: 2400  # ← Aumentar
related_files:
  - ../01-RULES/01-ARCHITECTURE-RULES.md
  - ../01-RULES/02-RESOURCE-GUARDRAILS.md
  - ../01-RULES/03-SECURITY-RULES.md
  - ../04-WORKFLOWS/INFRA-001-Monitor-Salud-VPS.json
  - ../04-WORKFLOWS/INFRA-002-Backup-Manager.json  # ← NUEVO
  - ../04-WORKFLOWS/INFRA-003-Alert-Dispatcher.json  # ← NUEVO
  - ../04-WORKFLOWS/INFRA-004-Security-Hardening.json  # ← NUEVO
  - ../03-AGENTS/infrastructure/health-monitor-agent.md  # ← NUEVO
  - ../03-AGENTS/infrastructure/backup-manager-agent.md  # ← NUEVO
  - ../03-AGENTS/infrastructure/alert-dispatcher-agent.md  # ← NUEVO
ai_navigation:
  read_after: facundo-core-context.md
  required_for: [deployment, troubleshooting, scaling, monitoring]  # ← Añadir monitoring
  update_frequency: monthly
  validation_rules:
    - all VPS must match ARQ-002 specs
    - backup workflow must be executable
    - health checks must return within 30s
    - ALL 4 agent workflows must be deployed and tested  # ← NUEVO
    - Telegram alerts must reach Facundo in < 2 min  # ← NUEVO
---

# FACUNDO INFRASTRUCTURE - MANTIS AGENTIC

## 🏗️ ARQUITECTURA FÍSICA - TOPOLOGÍA DE 3 VPS

+-------+---------------------------+------------------+------------+
| VPS   | Servicios                 | Capacidad        | Ubicación  |
+-------+---------------------------+------------------+------------+
| VPS-1 | n8n, uazapi, Redis        | 3 clientes Full  | São Paulo  |
| VPS-2 | EspoCRM, MySQL, Qdrant    | 6 clientes (BD)  | São Paulo  |
| VPS-3 | n8n, uazapi (failover)    | 3 clientes Full  | São Paulo  |
+-------+---------------------------+------------------+------------+

### Especificaciones Obligatorias por VPS (ARQ-002)

+------------------+---------------------+----------------------------------+
| Recurso          | Mínimo Requerido    | Herramienta de Validación        |
+------------------+---------------------+----------------------------------+
| vCPU             | 1 núcleo            | lscpu | grep "^CPU(s):"          |
| RAM              | 4 GB                | free -h | grep "^Mem:"           |
| Disco            | 50 GB NVMe          | df -h / | awk 'NR==2{print $2}'  |
| Ancho de banda   | 4 TB/mes            | Panel del proveedor (Hostinger)  |
| Latencia objetivo| < 50ms a BR-South   | mtr -c 100 cliente.example.com   |
| Acceso           | SSH keys only       | ssh -i clave.priv user@vps       |
+------------------+---------------------+----------------------------------+

---

## 🔁 ESTRATEGIA DE BACKUP Y RECUPERACIÓN

### Política de Backup (SLA Contractual)

+----------------+----------------------+----------------------------------+
| Tipo de Backup | Frecuencia           | Retención / Ubicación            |
+----------------+----------------------+----------------------------------+
| MySQL (VPS-2)  | Diario 04:00 AM      | 7 días local + 30 días externo   |
| Qdrant (VPS-2) | Diario 04:30 AM      | 7 días local + snapshot cloud    |
| n8n workflows  | On-change + diario   | Git repo privado + backup S3     |
| Configs VPS    | Semanal              | Repositorio de infra como código |
| Logs críticos  | Rotación diaria      | 14 días local, envío a SIEM      |
+----------------+----------------------+----------------------------------+

### Proceso de Restauración Crítica (< 60 minutos)

[DETECCIÓN DE FALLA]
        │
        ▼
+---------------------+
| 1. Alerta automática|
| (health-check fail) |
+---------------------+
        │
        ▼
+---------------------+     +---------------------+
| 2. Notificación a   |---->| 3. Evaluación de    |
| Facundo (Telegram)  |     | impacto por servicio|
+---------------------+     +---------------------+
        │
        ▼
+---------------------+
| 4. Decisión:        |
| - Failover a VPS-3  |
| - Restaurar backup  |
| - Escalar a cloud   |
+---------------------+
        │
        ▼
+---------------------+
| 5. Ejecución con    |
| checklist validado  |
+---------------------+
        │
        ▼
[Servicio restaurado + post-mortem obligatorio]

---

## 📊 MONITOREO Y ALERTAS TEMPRANAS

### Métricas Críticas y Umbrales de Alerta

+------------------+------------------+------------------+------------------------------+
| Métrica          | Umbral Warning   | Umbral Critical  |     Acción Automática        |
+------------------+------------------+------------------+------------------------------+
| RAM usage (VPS)  | > 75% (3.0 GB)   | > 90% (3.6 GB)   | Reducir concurrencia n8n     |
| CPU load (1min)  | > 0.8            | > 0.95           | Pausar workflows no críticos |
| Disco usado      | > 80% (40 GB)    | > 95% (47.5 GB)  | Rotar logs + alertar         |
| MySQL connections| > 40             | > 48             | Rechazar nuevas conexiones   |
| Qdrant latency   | > 200ms          | > 500ms          | Fallback a cache local       |
| n8n queue depth  | > 20             | > 50             | Escalar a VPS-3 temporal     |
+------------------+------------------+------------------+------------------------------+

### Herramientas de Monitoreo Implementadas

- `htop` + `iotop` para diagnóstico manual en terminal
- `docker stats` con logging a archivo rotativo
- Script personalizado `health-check.sh` ejecutado cada 5 min vía cron
- Webhook a Telegram para alertas críticas (sin dependencia externa)

---

## 🤖 AGENTES DE ALERTA TEMPRANA (n8n Workflows)

Estos agentes ejecutan **decisiones autónomas** basadas en las métricas. Son irreemplazables porque garantizan 
tiempo de respuesta < 2 minutos sin intervención humana.

### INFRA-001: Health Monitor Agent

| Atributo            |                  Especificación                     |
|---------------------|-----------------------------------------------------|
| **Workflow**        | `04-WORKFLOWS/n8n/INFRA-001-Monitor-Salud-VPS.json` |
| **Frecuencia**      | Cada 5 minutos (cron)                               |
| **Ejecución**       | VPS-1 (primario) y VPS-3 (failover)                 |

**Acciones Obligatorias:**

| Condición                                  | Acción Automática                             |            Canal            |
|--------------------------------------------|-----------------------------------------------|-----------------------------|
| RAM > 90% por 5 min                        | Alertar + Reducir concurrencia n8n            | Telegram + Log              |
| CPU > 0.95 sostenido                       | Alertar + Pausar workflows no críticos        | Telegram + Email            |
| Disco > 95%                                | Alertar + Rotar logs forzado                  | Telegram + Calendar         |
| Servicio caído                             | Alertar + Intentar restart automático (1 vez) | Telegram + Email + Calendar |
| Health check falla 2 ciclos consecutivos   | Alertar + Failover a VPS-3                    | Telegram (URGENTE) + Email  |

**Formato de Alerta Telegram (obligatorio):**

🚨 ALERTA CRÍTICA - [VPS-X]
Métrica: [RAM/CPU/DISCO/SERVICIO]
Valor: [actual] > umbral [X]
Acción tomada: [descripción]
Timestamp: [ISO 8601]

### INFRA-002: Backup Manager Agent

| Atributo           |                Especificación                    |
|--------------------|--------------------------------------------------|
| **Workflow**       | `04-WORKFLOWS/n8n/INFRA-002-Backup-Manager.json` |
| **Frecuencia**     | Diario 04:00 AM (VPS-2)                          |

**Acciones Obligatorias:**

| Evento                   |             Acción Automática                |           Canal             |
|--------------------------|----------------------------------------------|-----------------------------|
| Backup exitoso           | Registrar en log + checksum SHA256           | Log local                   |
| Backup fallido (1 vez)   | Reintentar 1 vez después de 10 min           | Telegram (warning)          |
| Backup fallido (2 veces) | ALERTA CRÍTICA + ejecución manual forzosa    | Telegram + Email + Calendar |
| Checksum mismatch        | ALERTA CRÍTICA + marcar backup como corrupto | Telegram + Email + Calendar |

**Verificación Obligatoria Post-Backup:**
```bash
# Generar checksum
sha256sum backup.tar.gz.enc > backup.tar.gz.enc.sha256

# Verificar
sha256sum -c backup.tar.gz.enc.sha256
```

### INFRA-003: Alert Dispatcher Agent

**Atributo	Especificación**

Workflow    04-WORKFLOWS/n8n/INFRA-003-Alert-Dispatcher.json
Disparo     Webhook desde INFRA-001 o INFRA-002

**Matriz de Envío Obligatoria:**

|Severidad	|Telegram	    |Email	            |Google Calendar  |Log |
|-----------|---------------|-------------------|-----------------|----|
|CRITICAL	|✅ Inmediato	|✅ Inmediato	    |✅ Crear evento  |✅  |
|WARNING	|✅ Inmediato	|✅ Diario resumen	|❌	              |✅  |
|INFO	    |❌	            |✅ Semanal resumen	|❌	              |✅  |


**Formato de Evento en Google Calendar:**

text
Título: [CRÍTICA] [VPS-X] - [Métrica]
Fecha: [timestamp]
Descripción: 
- Métrica: [valor]
- Acción tomada: [descripción]
- Checksum: [SHA256]
- Enlace a log: [URL]
Duración: 1 hora (bloqueo automático)


### INFRA-004: Security Hardening Agent

**Atributo	Especificación**

Workflow	04-WORKFLOWS/n8n/INFRA-004-Security-Hardening.json
Frecuencia	Cada 6 horas


**Acciones Obligatorias:**

|Detección	                             |Acción Automática                          |
|----------------------------------------|-------------------------------------------|
|Intentos SSH fallidos > 5 desde IP	     |Ban IP en fail2ban + reporte               |
|Puerto no autorizado abierto	         |Alertar + intentar cerrar vía UFW          |
|.env expuesto en logs	                 |ALERTA CRÍTICA + rotar todas las keys      |
|Usuario root login detectado	         |Alertar + deshabilitar si no es emergencia |

---

## 🔄 INTEGRACIÓN CON AGENTES

**Los workflows de n8n (04-WORKFLOWS/n8n/) son la implementación ejecutable de estos agentes.**

|Agente	             |Workflow	      |              Agente Especificación                 |
|--------------------|----------------|----------------------------------------------------|
|Health Monitor	     |INFRA-001	      |03-AGENTS/infrastructure/health-monitor-agent.md    |
|Backup Manager	     |INFRA-002	      |03-AGENTS/infrastructure/backup-manager-agent.md    |
|Alert Dispatcher    |INFRA-003	      |03-AGENTS/infrastructure/alert-dispatcher-agent.md  |
|Security Hardening	 |INFRA-004	      |03-AGENTS/infrastructure/security-hardening-agent.md|

**Validación Obligatoria:** 
Cada workflow debe ser probado en entorno de staging antes de pasar a producción.

---

## 📊 DASHBOARD DE MONITOREO (Opcional pero Recomendado)

|Métrica	             |    Herramienta	        |Frecuencia Actualización|
|------------------------|--------------------------|------------------------|
|RAM/CPU histórico	     |htop + logs	            |Tiempo real             |
|Tasa de éxito backups	 |Log de INFRA-002	        |Diario                  |
|Incidentes por tenant	 |Logs de auditoría	        |Semanal                 |
|Latencia WhatsApp	     |n8n execution logs	    |Por workflow            |
|Alertas enviadas	     |Historial Telegram/Email	|Tiempo real             |

---

## 🔐 SEGURIDAD Y AISLAMIENTO

### Reglas de Firewall (UFW) - Obligatorias

+----------------+------------------+------------------+------------------------+
| Puerto/Servicio| Acceso Permitido | Acceso Denegado  |     Justificación      |
+----------------+------------------+------------------+------------------------+
| SSH (22)       | IPs whitelisted  | 0.0.0.0/0        | Prevención brute-force |
| MySQL (3306)   | VPS-1, VPS-3     | Internet público | Aislamiento de BD      |
| Qdrant (6333)  | VPS-1, VPS-3     | Internet público | Protección de vectores |
| HTTP (80/443)  | Público          | -                | Webhooks WhatsApp      |
| Redis (6379)   | localhost only   | Externo          | Cache interno n8n      |
+----------------+------------------+------------------+------------------------+

### Validación de tenant_id en Consultas

```sql
-- EJEMPLO OBLIGATORIO: Toda query debe incluir tenant_id
SELECT * FROM interactions 
WHERE tenant_id = ? AND created_at > ?
ORDER BY created_at DESC LIMIT 50;

-- VALIDACIÓN EN CÓDIGO (pseudo):
if not query.contains("tenant_id"):
    raise SecurityError("Query missing tenant_id filter")
```

---

## 🚨 PROTOCOLO DE RECUPERACIÓN ANTE DESASTRES

**Escenarios y Respuestas Predefinidas**
+---------------------------+------------------------------------------+
| Escenario                 | Respuesta Inmediata                      |
+---------------------------+------------------------------------------+
| Caída de VPS-1            | Redirigir tráfico a VPS-3 (n8n failover) |
| Corrupción de MySQL       | Restaurar último backup validado + replay|
| Ataque DDoS a webhook     | Activar rate-limiting + IP ban temporal  |
| Pérdida de acceso SSH     | Usar consola de emergencia del proveedor |
| Fallo de backup automático| Alerta crítica + ejecución manual forzosa|
+---------------------------+------------------------------------------+

**Checklist Post-Recuperación (Obligatorio)**

- [ ] Validar integridad de datos restaurados (checksum)
- [ ] Verificar que tenant_id sigue aislado correctamente
- [ ] Ejecutar health-check completo de todos los servicios
- [ ] Documentar causa raíz en log de incidentes
- [ ] Actualizar procedimientos si se identificó gap

---

## 💡 INNOVACIÓN CON ESTABILIDAD - GUÍA DE DECISIÓN

    "Antes de implementar cualquier nueva funcionalidad, responder:"

+------------------------------------------+----------------------------------+
| Pregunta de Validación                   |      Criterio de Aprobación      |
+------------------------------------------+----------------------------------+
| ¿Aumenta el uso de RAM > 200 MB?         | Requiere optimización previa     |
| ¿Añade dependencia externa nueva?        | Debe tener fallback local        |
| ¿Modifica flujo de datos crítico?        | Requiere testing en staging      |
| ¿Cambia política de backup/seguridad?    | Revisión obligatoria por Facundo |
| ¿Impacta latencia para el usuario final? | Máximo +50ms aceptable           |
+------------------------------------------+----------------------------------+

---

## ✅ CHECKLIST DE VALIDACIÓN DE AGENTES

Antes de dar por implementada la infraestructura:

| Agente             | Workflow  | Probado | Fecha | Observaciones |
|--------------------|-----------|---------|-------|---------------|
| Health Monitor     | INFRA-001 | ⬜      |       |               |
| Backup Manager     | INFRA-002 | ⬜      |       |               |
| Alert Dispatcher   | INFRA-003 | ⬜      |       |               |
| Security Hardening | INFRA-004 | ⬜      |       |               |

**Pruebas obligatorias:**
- [ ] Simular RAM > 90% → alerta Telegram recibida en < 2 min
- [ ] Forzar fallo backup → alerta crítica + reintento
- [ ] Simular SSH fail > 5 intentos → IP baneada en fail2ban
- [ ] Health check falla 2 veces → failover a VPS-3

### Ejemplo de respuesta esperada del agente

**Para INFRA-003:**

Ejemplo de Alerta Telegram (INFRA-003)
🚨 ALERTA CRÍTICA - VPS-2
Métrica: RAM
Valor: 3.7 GB > umbral 3.6 GB
Acción tomada: Reducción de concurrencia n8n
Timestamp: 2026-04-01T14:30:00-03:00
Checksum: a3f5c8e2...


FIN DEL ARCHIVO - facundo-infrastructure.md
