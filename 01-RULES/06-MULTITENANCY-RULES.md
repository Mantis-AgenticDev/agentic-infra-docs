---
title: "MULTITENANCY RULES - Agentic Infra Docs"
category: "Datos"
priority: "Alta"
version: "1.0.0"
last_updated: "2026-03"
language: "es"
repository: "agentic-infra-docs"
owner: "Mantis-AgenticDev"
type: "rules"
ia_parser_version: "2.0"
auto_validate: true
compliance_check: "daily"
validation_script: "scripts/validate-multitenancy.sh"
auto_fixable: false
severity_scope: "critical"
rules_count: 10
requires_confirmation: false
tags:
  - multitenancy
  - data-isolation
  - tenant-id
  - mysql
  - qdrant
related_files:
  - "03-SECURITY-RULES.md"
  - "02-SKILLS/multi-tenant-data-isolation.md"
  - "06-PROGRAMMING/sql/multi-tenant-schema.md"
---

# MULTITENANCY RULES

## Metadatos del Documento

- **Categoría:** Datos
- **Prioridad de carga:** Alta
- **Versión:** 1.0.0
- **Última actualización:** Marzo 2026
- **Archivos relacionados:** 03-SECURITY-RULES.md

---

## Regla MT-001: tenant_id en Todas las Tablas

**Descripción:** Campo tenant_id obligatorio en todas las tablas de MySQL.

**Requisitos obligatorios:**

- Tipo: VARCHAR(50) o INT según diseño
- NOT NULL
- INDEX obligatorio
- Validado en cada consulta

**Ejemplo de schema:**
```sql
CREATE TABLE mensajes (
  id INT PRIMARY KEY AUTO_INCREMENT,
  tenant_id VARCHAR(50) NOT NULL,
  telefono VARCHAR(20) NOT NULL,
  mensaje TEXT,
  fecha DATETIME,
  INDEX idx_tenant_fecha (tenant_id, fecha)
);
```
**Violación crítica:** Tabla sin tenant_id.

---

## Regla MT-002: Colecciones Separadas en Qdrant

**Descripción:** Cada tenant debe tener colección separada o filtro estricto.

**Opción A (Recomendada):** Colección por tenant

rag_cliente_001
rag_cliente_002
rag_cliente_003

**Opción B:** Colección única con filtro por payload

```json
{
  "filter": {
    "must": [
      { "key": "tenant_id", "match": { "value": "cliente_001" } }
    ]
  }
}
```

---

## Regla MT-003: Filtros Obligatorios en Consultas

**Descripción:** Toda consulta debe incluir filtro por tenant_id.

**SQL obligatorio:**

```sql
SELECT * FROM mensajes WHERE tenant_id = ?;
```

**Qdrant obligatorio:**

```json
{
  "filter": {
    "must": [
      { "key": "tenant_id", "match": { "value": "cliente_001" } }
    ]
  }
}
```

**Violación crítica:** Consulta sin filtro tenant_id.

---

## Regla MT-004: Validación de tenant_id en Cada Request

**Descripción:** tenant_id debe ser validado en cada request entrante.

**Requisitos:**

Extraer tenant_id de token o header
Validar que tenant existe en base de datos
Rechazar request si tenant_id inválido
Log de acceso por tenant para auditoría

**Flujo obligatorio:**

1. Request entra con tenant_id
2. Validar tenant_id en tabla de clientes
3. Si válido: procesar request
4. Si inválido: retornar error 403
5. Loguear acceso (éxito o fallo)

---

## Regla MT-005: Nunca Exponer Datos Entre Tenants

**Descripción:** Datos de un cliente nunca deben ser visibles para otro.

**Prohibido explícitamente:**

Queries sin filtro tenant_id
Endpoints que retornen datos de múltiples tenants
Logs que incluyan datos de otros tenants
Debug mode que exponga datos crudos

**Violación crítica:** Cliente A puede ver mensajes de Cliente B.

---

## Regla MT-006: tenant_id en Logs de Auditoría

**Descripción:** Todos los logs deben incluir tenant_id para auditoría.

**Formato de log obligatorio:**

```json
{
  "timestamp": "2026-03-31T10:00:00Z",
  "tenant_id": "cliente_001",
  "action": "message_received",
  "status": "success",
  "details": "WhatsApp message processed"
}
```

---

## Regla MT-007: Backup por Tenant

**Descripción:** Backups deben permitir restauración por tenant individual.

**Requisitos:**

mysqldump debe incluir tenant_id en nombres de tablas o filtros
Qdrant snapshots por colección (una por tenant)
Restauración individual de tenant sin afectar otros

---

## Regla MT-008: Límites por Tenant

**Descripción:** Cada tenant debe tener límites de recursos definidos.

**Límites recomendados:**

Recurso	              Límite por Tenant	   Justificación
Mensajes/día	         1000	           Evitar abuso
Vectores Qdrant	         10000	           Limitar uso de RAM
Almacenamiento MySQL	 500 MB	           Limitar uso de disco
Requests API/min	     30	               Rate limiting

---

## Regla MT-009: tenant_id en EspoCRM

**Descripción:** EspoCRM debe usar tenant_id para separación de datos.

**Implementación:**

Usar equipos (teams) de EspoCRM por tenant
Configurar permisos por equipo
Validar tenant_id en cada consulta a EspoCRM API

---

## Regla MT-010: Test de Aislamiento Obligatório

**Descripción:** Test de aislamiento entre tenants debe ser ejecutado mensualmente.

**Test obligatorio:**

Crear tenant de test A y B
Insertar datos en tenant A
Intentar acceder a datos de A desde contexto de B
Verificar que acceso es denegado
Log de resultado del test

**Frecuencia:** Primer sábado de cada mes.

---

## 📌 Implementación Específica

Para límites específicos por tenant en este proyecto:
- Consultar `00-CONTEXT/facundo-infrastructure.md` sección "LÍMITES POR TENANT"

---

## Checklist de Validación de Multi-Tenencia

- [ ] tenant_id en todas las tablas MySQL
- [ ] tenant_id en payload de Qdrant
- [ ] Filtros tenant_id en todas las consultas
- [ ] Validación de tenant_id en cada request
- [ ] Logs incluyen tenant_id
- [ ] Backups permiten restauración por tenant
- [ ] Test de aislamiento ejecutado mensualmente
- [ ] EspoCRM configurado con teams por tenant

Versión 1.0.0 - Marzo 2026 - Mantis-AgenticDev
Licencia: Creative Commons para uso interno del proyecto
