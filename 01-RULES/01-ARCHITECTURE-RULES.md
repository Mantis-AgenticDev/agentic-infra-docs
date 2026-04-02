---
title: "ARCHITECTURE RULES - Agentic Infra Docs"
category: "Infraestructura"
priority: "Alta"
version: "1.0.0"
last_updated: "2026-03"
language: "es"
repository: "agentic-infra-docs"
owner: "Mantis-AgenticDev"
type: "rules"
ia_parser_version: "2.0"
auto_validate: false
compliance_check: "monthly"
validation_script: "scripts/validate-architecture.sh"
tags:
  - architecture
  - vps
  - docker
  - infrastructure
  - constraints
related_files:
  - "02-RESOURCE-GUARDRAILS.md"
  - "03-SECURITY-RULES.md"
  - "05-CONFIGURATIONS/docker-compose/"
---

# ARCHITECTURE RULES

## Metadatos del Documento

- **Categoría:** Infraestructura
- **Prioridad de carga:** Alta
- **Versión:** 1.0.0
- **Última actualización:** Marzo 2026
- **Archivos relacionados:** 02-RESOURCE-GUARDRAILS.md, 03-SECURITY-RULES.md

---

## Regla ARQ-001: Topología de 3 VPS

**Descripción:** La infraestructura base debe usar exactamente 3 VPS en São Paulo, Brasil.

**Configuración obligatoria:**

| VPS   | Servicios              | Capacidad  | Proveedor | Plan |
|-----  |------------------------|------------|-----------|------|
| VPS 1 | n8n, uazapi, Redis     | 3 clientes | Hostinger | KVM1 |
| VPS 2 | EspoCRM, MySQL, Qdrant | 6 clientes | Hostinger | KVM1 |
| VPS 3 | n8n, uazapi            | 3 clientes | Hostinger | KVM1 |

**Justificación:** Separación de concerns permite escalar n8n independientemente del CRM.

**Violación crítica:** Colocar todos los servicios en 1-2 VPS.

---

## Regla ARQ-002: Especificaciones Mínimas por VPS

**Descripción:** Cada VPS debe cumplir especificaciones mínimas para estabilidad.

**Requisitos obligatorios:**

- vCPU: 1 núcleo mínimo
- RAM: 4 GB mínimo
- Disco: 50 GB NVMe mínimo
- Ancho de banda: 4 TB mínimo
- Ubicación: São Paulo, Brasil (latencia < 50ms)
- Acceso: Root SSH con claves

**Violación crítica:** Usar VPS con menos de 4 GB RAM.

---

## Regla ARQ-003: Flujo de Datos Unidireccional

**Descripción:** El flujo de datos debe seguir arquitectura definida sin ciclos.

**Secuencia obligatoria:**

Mensaje WhatsApp entra -> uazapi (VPS 1 o VPS 3)
uazapi notifica -> n8n (VPS 1 o VPS 3)
n8n consulta -> Qdrant + MySQL (VPS 2)
n8n genera respuesta -> OpenRouter (IA externa)
n8n envía respuesta -> uazapi -> WhatsApp
n8n registra interacción -> EspoCRM (VPS 2, solo clientes Full)



**Violación crítica:** n8n escribiendo directo a MySQL sin pasar por EspoCRM.

---

## Regla ARQ-004: Contenedores Docker por VPS

**Descripción:** Límite máximo de contenedores Docker simultáneos por VPS.

**Límites obligatorios:**

| VPS   | Contenedores Máximos | Servicios              |
|-------|----------------------|------------------------|
| VPS 1 | 3                    | n8n, uazapi, Redis     |
| VPS 2 | 3                    | EspoCRM, MySQL, Qdrant |
| VPS 3 | 2                    | n8n, uazapi            |

**Justificación:** 4 GB RAM no soporta más de 3 contenedores estables.

**Violación crítica:** Ejecutar más de 3 contenedores en VPS con 4 GB RAM.

---

## Regla ARQ-005: Comunicación Entre VPS

**Descripción:** La comunicación entre VPS debe usar SSH tunnels o conexiones directas seguras.

**Requisitos obligatorios:**

- VPS 1 y VPS 3 deben conectar a VPS 2 vía IP privada o SSH tunnel
- MySQL (puerto 3306) solo accesible desde IP de VPS 1 y VPS 3
- Qdrant (puerto 6333) solo accesible desde IP de VPS 1 y VPS 3
- Nunca exponer MySQL o Qdrant a internet público

**Violación crítica:** MySQL o Qdrant con puerto abierto a 0.0.0.0.

---

## Regla ARQ-006: Backup Local Externo

**Descripción:** Los backups deben ser extraídos a PC local externo diariamente.

**Requisitos obligatorios:**

- Frecuencia: Diario a las 4:00 AM (America/Sao_Paulo)
- Método: rsync desde PC local hacia VPS 2
- Retención: 7 días mínimo
- Encriptación: Contraseña obligatoria en archivos .tar.gz

**Violación crítica:** Backups solo en VPS sin copia externa.

---

## Regla ARQ-007: Servicios Cloud vs Local

**Descripción:** Priorizar servicios cloud para componentes pesados.

**Decisiones arquitectónicas:**

| Componente | Recomendación       | Justificación                           |
|------------|---------------------|-----------------------------------------|
| Vector DB  | Qdrant Cloud        | 4 GB RAM no soporta Qdrant local pesado |
| IA         | OpenRouter API      | Modelos locales requieren 8+ GB RAM     |
| WhatsApp   | uazapi self-hosted  | No hay alternativa cloud confiable      |
| CRM        | EspoCRM self-hosted | Multi-tenencia requiere control total   |

**Violación crítica:** Intentar correr Ollama o modelos locales en VPS de 4 GB.

---

## Regla ARQ-008: Balance de Carga entre VPS

**Descripción:** Los clientes deben distribuirse equitativamente entre VPS 1 y VPS 3.

**Distribución obligatoria:**

- VPS 1: Máximo 3-4 clientes (n8n + uazapi)
- VPS 3: Máximo 3-4 clientes (n8n + uazapi)
- VPS 2: Central para todos  (6-8 clientes)

**Justificación:** Evitar saturación asimétrica de recursos.

---

## Regla ARQ-009: Red Docker Isolada

**Descripción:** Cada VPS debe usar redes Docker aisladas por servicio.

**Requisitos obligatorios:**

- Crear red Docker específica por stack de servicios
- No usar red bridge por defecto para servicios críticos
- Exponer solo puertos necesarios al host

**Violación crítica:** Todos los contenedores en red bridge default.

+-------+---------------------------+------------------------+
| VPS   | Red Docker                | Servicios              |
+-------+---------------------------+------------------------+
| VPS-1 | n8n-uazapi-network        | n8n, uazapi, Redis     |
| VPS-2 | crm-db-network            | EspoCRM, MySQL, Qdrant |
| VPS-3 | n8n-uazapi-network        | n8n, uazapi            |
+-------+---------------------------+------------------------+

**Comando de creación:**
docker network create --driver bridge n8n-uazapi-network

---

## Regla ARQ-010: Health Check Obligatorio

**Descripción:** Todos los servicios deben tener health check configurado.

**Requisitos obligatorios:**

- n8n: Health endpoint en /healthz
- MySQL: Connection check cada 5 minutos
- Qdrant: Cluster status check cada 5 minutos
- uazapi: WhatsApp session check cada 5 minutos

**Implementación:** Ver 03-AGENTS/infrastructure/health-monitor-agent.md

---

---

## 📦 TEMPLATE COMPLETO: docker-compose.yml POR VPS

### VPS-1 (n8n, uazapi, Redis)

```yaml
version: '3.8'
services:
  n8n:
    image: n8n-io/n8n
    container_name: n8n
    environment:
      - EXECUTIONS_PROCESS=main
      - EXECUTIONS_MAX_CONCURRENT=5
      - WEBHOOK_TIMEOUT=30000
      - MEMORY_LIMIT=1536
    ports:
      - "5678:5678"
    deploy:
      resources:
        limits:
          memory: 1.5G
    networks:
      - n8n-uazapi-network
    restart: unless-stopped

  uazapi:
    image: uazapi/uazapi
    container_name: uazapi
    ports:
      - "8080:8080"
    networks:
      - n8n-uazapi-network
    restart: unless-stopped

  redis:
    image: redis:alpine
    container_name: redis
    networks:
      - n8n-uazapi-network
    restart: unless-stopped

networks:
  n8n-uazapi-network:
    driver: bridge
```

### VPS-2 (EspoCRM, MySQL, Qdrant)

version: '3.8'
services:
  espocrm:
    image: espocrm/espocrm
    container_name: espocrm
    ports:
      - "80:80"
    networks:
      - crm-db-network
    restart: unless-stopped

  mysql:
    image: mysql:8.0
    container_name: mysql
    environment:
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
    volumes:
      - mysql-data:/var/lib/mysql
    networks:
      - crm-db-network
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 1G

  qdrant:
    image: qdrant/qdrant
    container_name: qdrant
    ports:
      - "6333:6333"
    volumes:
      - qdrant-data:/qdrant/storage
    networks:
      - crm-db-network
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 1G

volumes:
  mysql-data:
  qdrant-data:

networks:
  crm-db-network:
    driver: bridge
    
### VPS-3 (n8n, uazapi - failover)

Mismo que VPS-1 sin Redis

**Violación crítica:** Usar red bridge por defecto sin crear red específica.

## Validación de Arquitectura

Checklist de validación antes de deploy:

- [ ] 3 VPS configurados en São Paulo
- [ ] Cada VPS tiene 4 GB RAM mínimo
- [ ] MySQL solo accesible desde VPS 1 y VPS 3
- [ ] Qdrant solo accesible desde VPS 1 y VPS 3
- [ ] Máximo 3 contenedores por VPS
- [ ] Backup local externo configurado
- [ ] Health checks implementados
- [ ] Redes Docker aisladas

---
## 📌 Documentación Específica del Proyecto

Para implementación específica de este proyecto, consultar:
- `00-CONTEXT/facundo-infrastructure.md` (detalles de infraestructura)
- `00-CONTEXT/facundo-core-context.md` (contexto del usuario)

*Versión 1.0.0 - Marzo 2026 - Mantis-AgenticDev*
*Licencia: Creative Commons para uso interno del proyecto*
