---
title: "SCALABILITY RULES - Agentic Infra Docs"
category: "Escalabilidad"
priority: "Baja"
version: "1.1.0"
last_updated: "2026-04-08"
language: "es"
repository: "agentic-infra-docs"
owner: "Mantis-AgenticDev"
type: "rules"
ia_parser_version: "2.0"
auto_validate: false
compliance_check: "monthly"
validation_script: "scripts/check-capacity.sh"
auto_fixable: false
severity_scope: "info"
rules_count: 10
requires_confirmation: true
tags:
  - scalability
  - growth
  - capacity
  - phases
  - criteria
related_files:
  - "01-ARCHITECTURE-RULES.md"
  - "02-RESOURCE-GUARDRAILS.md"
  - "07-PROCEDURES/scaling-decision-matrix.md"
---

# SCALABILITY RULES

## Metadatos del Documento

- **Categoría:** Escalabilidad
- **Prioridad de carga:** Baja
- **Versión:** 1.0.0
- **Última actualización:** Marzo 2026
- **Archivos relacionados:** 01-ARCHITECTURE-RULES.md

---

## Regla ESC-001: Configuración Inicial Conservadora

**Descripción:** Iniciar con configuración conservadora de clientes.

**Configuración inicial obligatoria:**

| VPS       | Clientes Iniciales | Servicios              |
|-----------|--------------------|------------------------|
| VPS 1     | 3                  | n8n, uazapi, Redis     |
| VPS 2     | 6                  | EspoCRM, MySQL, Qdrant |
| VPS 3     | 3                  | n8n, uazapi            |
| **Total** | **6 clientes**     | -                      |

**Principio:** "Mejor 6 meses completado que 4 meses abandonado por burnout."

---

## Regla ESC-002: Configuración Máxima con KVM1

**Descripción:** Máximo de clientes posible con VPS KVM1 (4 GB RAM).

**Configuración máxima:**

| VPS       | Clientes Máximos       | Servicios              |
|-----------|------------------------|------------------------|
| VPS 1     | 4                      | n8n, uazapi, Redis     |
| VPS 2     | 8                      | EspoCRM, MySQL, Qdrant |
| VPS 3     | 4                      | n8n, uazapi            |
| **Total** | **8 clientes**         | -                      |

**Ingreso neto objetivo:** R$ 2.860/mes (8 clientes Full).

---

## Regla ESC-003: Criterios para Escalar de 3 a 4 Clientes

**Descripción:** Escalar solo si todos los criterios se cumplen.

**Criterios obligatorios (todos deben ser verdaderos):**

| Criterio                | Umbral              | Período |
|-------------------------|---------------------|---------|
| RAM promedio            | menos de 70%        | 30 días |
| CPU pico                | menos de 80%        | 30 días |
| Respuesta WhatsApp      | menos de 5 segundos | 30 días |
| Incidentes críticos     | 0                   | 30 días |
| Backup exitoso          | 100%                | 30 días |
| Quejas de clientes      | 0                   | 30 días |

**Violación:** Escalar si algún criterio no se cumple.

---

## Regla ESC-004: Fases de Escalabilidad

**Descripción:** Escalabilidad debe seguir fases definidas.

| Fase    | Período | Clientes | Objetivo                     |
|---------|---------|----------|------------------------------|
| Fase 1  | Mes 1-4 | 6        | Validar infraestructura base |
| Fase 2  | Mes 5-8 | 8        | Máximo con KVM1              |
| Fase 3  | Mes 9+  | 8+       | Upgrade a KVM2 o más VPS     |

---

## Regla ESC-005: Criterios para Fase 3 (Upgrade)

**Descripción:** Upgrade a KVM2 o más VPS solo si hay demanda confirmada.

**Criterios obligatorios:**

| Criterio                       | Umbral                          |
|--------------------------------|---------------------------------|
| Lista de espera de clientes    | Sí, confirmada                  |
| Ingreso neto confirmado        | Más de R$ 3.000/mes por 60 días |
| RAM consistentemente           | Más de 75% en KVM1              |

**Decisión:** Solo upgrade si todos los criterios se cumplen.

---

## Regla ESC-006: Principio de Estabilidad

**Descripción:** La estabilidad vende más que la velocidad.

**Principio fundamental:**

"La estabilidad vende más que la velocidad. Tu laboratorio merece cimientos sólidos, tanto en el campo como en la nube."

**Aplicación:**

- No escalar por presión de ventas
- Validar 30 días antes de cada escalón
- Priorizar retención sobre adquisición

---

## Regla ESC-007: Monitoreo Pre-Escalado

**Descripción:** Monitoreo intensivo 30 días antes de escalar.

**Métricas a monitorear diariamente:**

- RAM promedio y pico
- CPU promedio y pico
- Tiempo de respuesta WhatsApp
- Tasa de error de APIs
- Estado de backups

**Acción:** Si alguna métrica excede umbral, pausar escalado.

### Ejemplo de evaluación de carga por tenant para decisión de escalado (C4)
```sql
-- spec_referenced: 06-MULTITENANCY-RULES.md#MT-003
-- constraints_applied: [C4, ESC-003]
-- Evaluar métricas por tenant antes de autorizar Fase 2/3
SELECT 
    tenant_id,
    COUNT(id) as monthly_interactions,
    AVG(CASE WHEN response_time_ms > 5000 THEN 1 ELSE 0 END) as latency_violation_rate
FROM interaction_logs
WHERE created_at >= NOW() - INTERVAL 30 DAY
GROUP BY tenant_id
HAVING latency_violation_rate > 0.05; -- >5% mensajes lentos = NO escalar
```

---

## Regla ESC-008: Comunicación de Escalado a Clientes

**Descripción:** Clientes deben ser notificados de cambios de infraestructura.

**Requisitos:**

- Notificar 7 días antes de mantenimiento
- Ventana de mantenimiento: 2 AM - 4 AM
- Canal: Email + WhatsApp
- Contenido: Qué cambia, impacto esperado, contacto de soporte

---

## Regla ESC-009: Rollback Plan Obligatório

**Descripción:** Todo escalado debe tener plan de rollback.

**Requisitos del rollback plan:**

- Tiempo máximo de rollback: 1 hora
- Procedimiento documentado en 07-PROCEDURES/
- Test de rollback ejecutado antes de escalar
- Contacto de emergencia definido

---

## Regla ESC-010: Revisión Post-Escalado

**Descripción:** Revisión obligatoria 7 días después de escalar.

**Checklist de revisión:**

- [ ] RAM estable en nuevos límites
- [ ] CPU estable en nuevos límites
- [ ] Respuesta WhatsApp dentro de SLA
- [ ] 0 incidentes críticos
- [ ] Backups 100% exitosos
- [ ] 0 quejas de clientes

**Acción:** Si algún item falla, considerar rollback.

---

## Matriz de Decisión de Escalado

| Condición                              | Acción                       |
|----------------------------------------|------------------------------|
| Todos los criterios verdes por 30 días | Proceder a escalar           |
| 1-2 criterios amarillos                | Esperar 15 días más          |
| 1+ criterios rojos                     | No escalar, investigar causa |
| Incidente crítico en últimos 30 días   | No escalar, resolver primero |

---

## Checklist de Validación de Escalabilidad

- [ ] Configuración inicial de 6 clientes
- [ ] Todos los criterios de escalado verificados por 30 días
- [ ] Monitoreo intensivo activo
- [ ] Plan de rollback documentado y testeado
- [ ] Clientes notificados con 7 días de anticipación
- [ ] Revisión post-escalado agendada para 7 días después

---

*Versión 1.1.0 - Abril 2026 - Mantis-AgenticDev*
*Licencia: Creative Commons para uso interno del proyecto*

## 🔗 Conexiones Estructurales (Auto-generado)
[[README.md]]
[[01-RULES/00-INDEX.md]]
[[01-RULES/01-ARCHITECTURE-RULES.md]]
[[01-RULES/02-RESOURCE-GUARDRAILS.md]]
