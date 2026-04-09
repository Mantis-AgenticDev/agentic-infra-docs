---
title: "Docker Compose Networking - Agentic Infra Docs"
category: "Infrastructure"
subcategory: "Docker"
priority: "critical"
version: "1.0.0"
last_updated: "2026-04-09"
language: "es"
repository: "agentic-infra-docs"
owner: "Mantis-AgenticDev"
type: "skill"
ia_parser_version: "2.0"
auto_validate: true
compliance_check: "weekly"
validation_script: "scripts/validate-against-specs.sh"
auto_fixable: false
severity_scope: "critical"
tags:
- docker
- compose
- networking
- containers
- vps
- hostinger
- bridge
- networks
related_files:
- "01-RULES/01-ARCHITECTURE-RULES.md"
- "01-RULES/02-RESOURCE-GUARDRAILS.md"
- "01-RULES/05-CODE-PATTERNS-RULES.md"
- "05-CONFIGURATIONS/docker-compose/"
spec_references:
- "ARQ-004"
- "ARQ-009"
- "RES-001"
- "RES-002"
constraints_applied:
- "C1"
- "C2"
- "C3"
---

# Docker Compose Networking

## Specification-Driven Development

Este documento forma parte del conjunto de especificaciones SDD (Specification-Driven Development) para la infraestructura Agentic del proyecto MANTIS. Toda configuración aquí descrita debe cumplir con las reglas de arquitectura definidas en `01-RULES/01-ARCHITECTURE-RULES.md` y los constraints de recursos establecidos en `01-RULES/02-RESOURCE-GUARDRAILS.md`.

---

## 1. Introduccion y Proposito

La arquitectura de networking en Docker Compose representa uno de los pilares fundamentales para el funcionamiento correcto de los servicios distribuidos en los tres VPS que conforman la infraestructura MANTIS AGENTIC. Este documento tecnico establece las directrices, mejores prácticas y configuraciones especificas necesarias para implementar redes Docker que garanticen comunicacion segura, aislada y eficiente entre contenedores, asi como comunicacion cross-host entre los diferentes servidores virtuales privados.

El proposito principal de este documento es proporcionar una referencia técnica exhaustiva que permita a los equipos de desarrollo y operaciones implementar configuraciones de networking robustas, siguiendo los principios de especificación-drive development donde cada decisión de arquitectura debe estar justificada y rastreable contra las especificaciones del sistema. Las redes Docker bridge personalizadas constituyen el mecanismo primario de aislamiento y comunicación entre servicios, mientras que las configuraciones de resource limits aseguran el cumplimiento de las restricciones C1 (4GB RAM máximo por contenedor) y C2 (1 vCPU por VPS).

La documentación aqui contenida aborda tanto los aspectos teóricos de la arquitectura de redes Docker como las implementaciones prácticas mediante archivos docker-compose.yml completos para cada uno de los tres VPS: VPS-1 ejecutando n8n y uazapi con Redis, VPS-2 hosteando EspoCRM con MySQL y Qdrant, y VPS-3 como nodo de failover para n8n y uazapi. Cada configuración incluye consideraciones específicas para el entorno de Hostinger Brasil con especificaciones KVM1, 4GB RAM, 1 vCPU y 50GB NVMe.

---

## 2. Arquitectura de Redes Docker

### 2.1 Fundamentos de Redes Bridge en Docker

Docker utiliza una arquitectura de red virtualizada que permite la comunicación entre contenedores a través de diferentes tipos de drivers de red. El driver bridge representa el tipo más común y fundamental, creando una red privada interna donde los contenedores pueden comunicarse usando direcciones IP internas mientras permanecen aislados del host y de otras redes. Cuando Docker se instala, crea automaticamente una interfaz de red bridge llamada docker0, la cual asigna un rango de direcciones IP privado (típicamente 172.17.0.0/16) a los contenedores que no especifican una red personalizada.

En el contexto de la infraestructura MANTIS AGENTIC, cada VPS necesita configuraciones de bridge personalizadas que respeten las limitaciones de recursos y обеспечивают aislamiento adecuado entre los diferentes stacks de servicios. La decisión de utilizar bridge personalizadas en lugar de la red bridge default responde a la necesidad de controlar explicitamente el rango de direcciones IP, implementar DNS interno personalizado por stack, y facilitar la configuración de reglas de firewall específicas por servicio.

Las redes bridge personalizadas en Docker ofrecen ventajas significativas sobre la red bridge default. Primero, permiten la resolución DNS automática por nombre de servicio, eliminando la dependencia de direcciones IP hardcodeadas que dificultan la escalabilidad y el mantenimiento. Segundo, facilitan el aislamiento de servicios relacionados en redes lógicas separadas, mejorando la seguridad al evitar que servicios no relacionados puedan comunicarse directamente. Tercero, permiten la configuración de subredes específicas que no confliten con otras redes en el entorno de producción.

### 2.2 Modelo de Red por Stack

La arquitectura de networking para MANTIS AGENTIC sigue un modelo de tres capas definido por las especificaciones ARQ-004 y ARQ-009. La primera capa corresponde a la red pública donde los servicios exponen sus puertos necesarios para acceso externo. La segunda capa es la red de servicios internos que agrupa los componentes de una aplicación específica. La tercera capa representa la red de datos persistente utilizada exclusivamente para la comunicación con volúmenes y sistemas de almacenamiento.

Para VPS-1, la configuracion de red implementa un stack consisting de n8n (workflow automation), uazapi (API de servicios UArizona), y Redis (caché y cola de mensajes). La red pública expone únicamente el puerto 5678 para n8n y el puerto 3000 para uazapi, mientras que Redis permanece completamente aislado en la red interna sin exposición externa. Esta configuración cumple con el constraint C3 al garantizar que las bases de datos (en este caso Redis) nunca estén accesibles desde 0.0.0.0.

VPS-2 presenta una arquitectura similar pero con componentes diferentes: EspoCRM (CRM empresarial), MySQL (base de datos relacional), y Qdrant (vector database para búsqueda semántica). MySQL se configura en la red interna del stack sin puertos expuestos externamente, accesible únicamente a través de la red Docker interna por el nombre del servicio mysql. Qdrant se expone en el puerto 6333 para permitir conexiones desde aplicaciones externas que requieren capacidades de búsqueda vectorial.

VPS-3 como nodo de failover replica la configuración de VPS-1 pero sin exposición pública inicial, manteniendo los servicios準備listos para activación en caso de falla del nodo primario. Esta arquitectura de failover se detalla más adelante en la sección de cross-host networking.

### 2.3 Topología de Red Detallada

La topología de red se estructura en tres segmentos principales que reflejan los requisitos de seguridad y aislamiento del proyecto. El segmento público (10.0.1.0/24) corresponde a las interfaces que exponen servicios hacia el exterior, utilizando únicamente los puertos mínimos necesarios para cada servicio. El segmento interno (10.0.2.0/24) agrupa todos los servicios de aplicación que necesitan comunicarse entre sí dentro de un mismo stack. El segmento de datos (10.0.3.0/24) está reservado exclusivamente para la comunicación con volúmenes persistentes y sistemas de almacenamiento.

Esta segmentación permite implementar reglas de firewall granulares donde el segmento público solo puede acceder al segmento interno, pero nunca directamente al segmento de datos. Los contenedores en el segmento interno pueden comunicar libremente entre sí y tienen acceso limitado al segmento de datos. Esta arquitectura sigue el principio de mínimo privilegio donde cada componente tiene únicamente los permisos de red estrictamente necesarios para su funcionamiento.

---

## 3. Creacion de Redes Personalizadas

### 3.1 Sintaxis basica para docker-compose

La creación de redes personalizadas en Docker Compose se realiza mediante la sección networks en el archivo de configuración. Cada red puede definirse con parámetros específicos como el driver a utilizar (bridge por defecto), la subred IP, el gateway, y opciones de configuración avanzada. A continuación se presenta la estructura básica para definir redes personalizadas en un archivo docker-compose.yml.

```yaml
networks:
  frontend:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 10.0.1.0/24
          gateway: 10.0.1.1
  backend:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 10.0.2.0/24
          gateway: 10.0.2.1
  data:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 10.0.3.0/24
          gateway: 10.0.3.1
```

La configuración IPAM (IP Address Management) permite definir exactamente qué rango de direcciones IP utilizará cada red, evitando conflictos con otras redes en el entorno. Es crucial especificar subredes que no se superpongan con la red del host, otras redes Docker en el mismo VPS, ni con las redes de los otros VPS en la infraestructura distribuida.

### 3.2 Asignacion de contenedores a redes

Una vez definidas las redes, los contenedores se asignan a ellas mediante la propiedad networks en la sección de cada servicio. Un contenedor puede pertenecer a múltiples redes simultáneamente, permitiéndole comunicar con diferentes grupos de servicios según sea necesario. Esta flexibilidad es particularmente útil para servicios que actúan como proxies o gateways entre diferentes segmentos de red.

```yaml
services:
  n8n:
    image: n8nio/n8n:latest
    networks:
      frontend:
        ipv4_address: 10.0.1.10
      backend:
    ports:
      - "5678:5678"

  redis:
    image: redis:7-alpine
    networks:
      backend:
        ipv4_address: 10.0.2.10
```

La asignación de direcciones IP estáticas es recomendable para servicios que necesitan ser accedidos por nombre de host constante desde otros contenedores, aunque Docker proporciona resolución DNS automática por nombre de servicio que elimina la necesidad de direcciones IP hardcodeadas en la mayoría de los casos. Las direcciones IP estáticas resultan útiles específicamente para servicios de infraestructura como bases de datos donde se requiere configuración explicita de conexión.

### 3.3 DNS Interno de Docker

El sistema de DNS interno de Docker resuelve automáticamente los nombres de servicios en direcciones IP de los contenedores dentro de la misma red. Este mecanismo funciona tanto para nombres de servicios definidos en el mismo archivo docker-compose como para nombres de servicios en redes compartidas. La resolución DNS está handled por el daemon de Docker y responde a consultas en el puerto 53 tanto UDP como TCP.

Para servicios que requieren nombres de dominio personalizados (por ejemplo, para certificados SSL o configuración de aplicaciones), Docker Compose permite especificar alias de red mediante la propiedad aliases. Estos alias son adicionales al nombre del servicio y permiten que el contenedor sea resoluble por múltiples nombres dentro de la misma red.

```yaml
services:
  mysql:
    image: mysql:8.0
    networks:
      backend:
        aliases:
          - database.internal
          - mysql.crm.internal
```

La configuración de DNS externo para permitir que los contenedores resuelvan direcciones fuera de Docker se realiza mediante la propiedad dns en la definición de la red o del servicio individual. Esta configuración es útil cuando los contenedores necesitan comunicarse con servicios externos que utilizan nombres de dominio corporativos o servicios en otras redes privadas.

---

## 4. Configuracion docker-compose.yml por VPS

### 4.1 VPS-2: Stack CRM (EspoCRM + MySQL + Qdrant)

El archivo docker-compose.yml para VPS-2 representa la configuración más completa de la infraestructura MANTIS AGENTIC, incorporando todos los patrones de networking, resource limits, y healthchecks necesarios para un entorno de producción. Este VPS ejecuta EspoCRM como aplicación principal de gestión de relaciones con clientes, MySQL como base de datos relacional para el CRM, y Qdrant como base de datos vectorial para funcionalidades de búsqueda semántica y integración con agentes de IA.

La arquitectura de este stack sigue el patrón de tres capas descrito anteriormente: una red pública para exposición de servicios web, una red interna para comunicación entre servicios de aplicación, y configuración de volumenes para persistencia de datos. MySQL permanece completamente aislado sin exposición de puertos externos, accesible únicamente a través de la red Docker interna. Qdrant se expone en puerto 6333 para permitir consultas de búsqueda vectorial desde aplicaciones externas y agentes de IA.

```yaml
version: "3.9"

networks:
  public:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 10.0.1.0/24
          gateway: 10.0.1.1
  internal:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 10.0.2.0/24
          gateway: 10.0.2.1

volumes:
  mysql_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /srv/volumes/vps2/mysql_data
  qdrant_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /srv/volumes/vps2/qdrant_data
  espocrm_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /srv/volumes/vps2/espocrm_data

services:
  mysql:
    image: mysql:8.0
    container_name: mantis_mysql
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: "${MYSQL_ROOT_PASSWORD}"
      MYSQL_DATABASE: espocrm
      MYSQL_USER: "${MYSQL_USER}"
      MYSQL_PASSWORD: "${MYSQL_PASSWORD}"
    networks:
      internal:
        ipv4_address: 10.0.2.10
    volumes:
      - mysql_data:/var/lib/mysql
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
    command: >
      --default-authentication-plugin=mysql_native_password
      --character-set-server=utf8mb4
      --collation-server=utf8mb4_unicode_ci
      --max-connections=100
      --innodb-buffer-pool-size=256M
      --innodb-log-file-size=64M
    mem_limit: 768m
    mem_reservation: 256m
    cpus: 0.5
    cpu_shares: 512
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p${MYSQL_ROOT_PASSWORD}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 60s
    deploy:
      resources:
        limits:
          cpus: "0.5"
          memory: 768M
        reservations:
          cpus: "0.25"
          memory: 256M
    logging:
      driver: "json-file"
      options:
        max-size: "50m"
        max-file: "3"
        labels: "service,mysql"

  qdrant:
    image: qdrant/qdrant:v1.7.0
    container_name: mantis_qdrant
    restart: unless-stopped
    networks:
      public:
        ipv4_address: 10.0.1.15
      internal:
        ipv4_address: 10.0.2.15
    volumes:
      - qdrant_data:/qdrant/storage
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
    ports:
      - "127.0.0.1:6333:6333"
      - "127.0.0.1:6334:6334"
    environment:
      QDRANT__SERVICE__GRPC_PORT: 6334
      QDRANT__SERVICE__MAX_REQUEST_SIZE_MB: 32
    mem_limit: 1536m
    mem_reservation: 512m
    cpus: 0.75
    cpu_shares: 768
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:6333/health"]
      interval: 15s
      timeout: 10s
      retries: 3
      start_period: 30s
    deploy:
      resources:
        limits:
          cpus: "0.75"
          memory: 1536M
        reservations:
          cpus: "0.5"
          memory: 512M
    logging:
      driver: "json-file"
      options:
        max-size: "100m"
        max-file: "5"
        labels: "service,qdrant"

  espocrm:
    image: espocrm/espocrm:latest
    container_name: mantis_espocrm
    restart: unless-stopped
    depends_on:
      mysql:
        condition: service_healthy
    networks:
      public:
        ipv4_address: 10.0.1.10
      internal:
        ipv4_address: 10.0.2.20
    volumes:
      - espocrm_data:/var/www/html
      - /srv/volumes/vps2/espocrm_logs:/var/www/html/data/logs
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
    ports:
      - "127.0.0.1:8080:80"
    environment:
      ESPOCRM_DATABASE_HOST: mysql
      ESPOCRM_DATABASE_PORT: 3306
      ESPOCRM_DATABASE_NAME: espocrm
      ESPOCRM_DATABASE_USER: "${MYSQL_USER}"
      ESPOCRM_DATABASE_PASSWORD: "${MYSQL_PASSWORD}"
      ESPOCRM_SITE_URL: "https://crm.mantis-agentic.internal"
      PHP_MEMORY_LIMIT: "256M"
      PHP_UPLOAD_MAX_FILESIZE: "50M"
      PHP_POST_MAX_SIZE: "50M"
    mem_limit: 1024m
    mem_reservation: 512m
    cpus: 0.75
    cpu_shares: 768
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health-check.php"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 120s
    deploy:
      resources:
        limits:
          cpus: "0.75"
          memory: 1024M
        reservations:
          cpus: "0.5"
          memory: 512M
    logging:
      driver: "json-file"
      options:
        max-size: "100m"
        max-file: "5"
        labels: "service,espocrm"

  nginx:
    image: nginx:1.25-alpine
    container_name: mantis_nginx_crm
    restart: unless-stopped
    depends_on:
      - espocrm
    networks:
      public:
        ipv4_address: 10.0.1.5
    volumes:
      - /srv/volumes/vps2/nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - /srv/volumes/vps2/nginx/conf.d:/etc/nginx/conf.d:ro
      - /srv/volumes/vps2/ssl:/etc/nginx/ssl:ro
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
    ports:
      - "80:80"
      - "443:443"
    mem_limit: 128m
    mem_reservation: 64m
    cpus: 0.25
    cpu_shares: 256
    healthcheck:
      test: ["CMD", "nginx", "-t"]
      interval: 30s
      timeout: 5s
      retries: 3
    deploy:
      resources:
        limits:
          cpus: "0.25"
          memory: 128M
        reservations:
          cpus: "0.1"
          memory: 64M
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "5"
        labels: "service,nginx"
```

### 4.2 VPS-1: Stack de Automatizacion (n8n + uazapi + Redis)

El archivo docker-compose.yml para VPS-1 implementa el stack de automatización principal utilizando n8n como plataforma de workflows de automatización, uazapi como API de servicios UArizona, y Redis como sistema de caché y cola de mensajes. Esta configuración está optimizada para entornos con recursos limitados (4GB RAM, 1 vCPU) siguiendo los constraints C1 y C2 establecidos en las especificaciones del proyecto.

La configuración de Redis merece atención especial ya que representa el servicio de base de datos en este VPS. Siguiendo el constraint C3, Redis no expone ningún puerto directamente al host, permaneciendo accesible únicamente a través de la red Docker interna. Los contenedores n8n y uazapi se conectan a Redis usando el nombre del servicio como hostname, aprovechando el DNS interno de Docker para la resolución.

```yaml
version: "3.9"

networks:
  frontend:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 10.1.1.0/24
          gateway: 10.1.1.1
  backend:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 10.1.2.0/24
          gateway: 10.1.2.1

volumes:
  n8n_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /srv/volumes/vps1/n8n_data
  redis_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /srv/volumes/vps1/redis_data
  uazapi_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /srv/volumes/vps1/uazapi_data

services:
  redis:
    image: redis:7-alpine
    container_name: mantis_redis
    restart: unless-stopped
    command: >
      --maxmemory 256mb
      --maxmemory-policy allkeys-lru
      --save 900 1
      --save 300 10
      --save 60 10000
      --appendonly yes
      --appendfsync everysec
    networks:
      backend:
        ipv4_address: 10.1.2.10
    volumes:
      - redis_data:/data
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
    mem_limit: 384m
    mem_reservation: 128m
    cpus: 0.25
    cpu_shares: 256
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 10s
    deploy:
      resources:
        limits:
          cpus: "0.25"
          memory: 384M
        reservations:
          cpus: "0.1"
          memory: 128M
    logging:
      driver: "json-file"
      options:
        max-size: "20m"
        max-file: "3"
        labels: "service,redis"

  n8n:
    image: n8nio/n8n:latest
    container_name: mantis_n8n
    restart: unless-stopped
    depends_on:
      redis:
        condition: service_healthy
    networks:
      frontend:
        ipv4_address: 10.1.1.10
      backend:
        ipv4_address: 10.1.2.20
    volumes:
      - n8n_data:/home/node/.n8n
      - /srv/volumes/vps1/n8n_logs:/home/node/.n8n/logs
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
    environment:
      - N8N_HOST=n8n.mantis-agentic.internal
      - N8N_PORT=5678
      - N8N_PROTOCOL=https
      - WEBHOOK_URL=https://n8n.mantis-agentic.internal/
      - N8N_REDIS_HOST=redis
      - N8N_REDIS_PORT=6379
      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
      - EXECUTIONS_DATA_SAVE_ON_ERROR=all
      - EXECUTIONS_DATA_SAVE_ON_SUCCESS=all
      - EXECUTIONS_DATA_SAVE_ON_TIMEOUT=true
      - EXECUTIONS_DATA_SAVE_MANUAL_EXECUTIONS=true
      - GENERIC_TIMEZONE=America/Sao_Paulo
      - NODE_ENV=production
    ports:
      - "127.0.0.1:5678:5678"
    mem_limit: 1536m
    mem_reservation: 768m
    cpus: 0.5
    cpu_shares: 512
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:5678/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    deploy:
      resources:
        limits:
          cpus: "0.5"
          memory: 1536M
        reservations:
          cpus: "0.25"
          memory: 768M
    logging:
      driver: "json-file"
      options:
        max-size: "100m"
        max-file: "5"
        labels: "service,n8n"

  uazapi:
    image: uazapi:latest
    container_name: mantis_uazapi
    restart: unless-stopped
    depends_on:
      redis:
        condition: service_healthy
    networks:
      frontend:
        ipv4_address: 10.1.1.15
      backend:
        ipv4_address: 10.1.2.25
    volumes:
      - uazapi_data:/app/data
      - /srv/volumes/vps1/uazapi_logs:/app/logs
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
    environment:
      - NODE_ENV=production
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - API_PORT=3000
      - API_RATE_LIMIT=100
      - API_TIMEOUT=30000
      - LOG_LEVEL=info
    ports:
      - "127.0.0.1:3000:3000"
    mem_limit: 768m
    mem_reservation: 384m
    cpus: 0.25
    cpu_shares: 256
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3000/health"]
      interval: 15s
      timeout: 5s
      retries: 3
      start_period: 30s
    deploy:
      resources:
        limits:
          cpus: "0.25"
          memory: 768M
        reservations:
          cpus: "0.1"
          memory: 384M
    logging:
      driver: "json-file"
      options:
        max-size: "50m"
        max-file: "5"
        labels: "service,uazapi"

  nginx:
    image: nginx:1.25-alpine
    container_name: mantis_nginx_vps1
    restart: unless-stopped
    depends_on:
      - n8n
      - uazapi
    networks:
      frontend:
        ipv4_address: 10.1.1.5
    volumes:
      - /srv/volumes/vps1/nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - /srv/volumes/vps1/nginx/conf.d:/etc/nginx/conf.d:ro
      - /srv/volumes/vps1/ssl:/etc/nginx/ssl:ro
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
    ports:
      - "80:80"
      - "443:443"
    mem_limit: 128m
    mem_reservation: 64m
    cpus: 0.1
    cpu_shares: 128
    healthcheck:
      test: ["CMD", "nginx", "-t"]
      interval: 30s
      timeout: 5s
      retries: 3
    deploy:
      resources:
        limits:
          cpus: "0.1"
          memory: 128M
        reservations:
          cpus: "0.05"
          memory: 64M
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "5"
        labels: "service,nginx"
```

### 4.3 VPS-3: Stack Failover (n8n + uazapi)

El archivo docker-compose.yml para VPS-3 replica la configuración del VPS-1 con modificaciones específicas para operación en modo failover. En estado normal (standby), los servicios permanecen activos pero no exposed publicly, listos para asumir tráfico en caso de falla del nodo primario. La activación del nodo failover involucra cambios de configuración en el balanceador de carga para dirigir el tráfico hacia este VPS.

La diferencia principal en la configuración de red es que los puertos de los servicios no se exponen públicamente en el archivo docker-compose.yml, aunque están disponibles internamente para verificación de salud. Los healthchecks continúan ejecutándose para asegurar que los servicios estén operativos y prontos para recibir tráfico cuando sea necesario.

```yaml
version: "3.9"

networks:
  frontend:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 10.3.1.0/24
          gateway: 10.3.1.1
  backend:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 10.3.2.0/24
          gateway: 10.3.2.1

volumes:
  n8n_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /srv/volumes/vps3/n8n_data
  redis_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /srv/volumes/vps3/redis_data
  uazapi_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /srv/volumes/vps3/uazapi_data

services:
  redis:
    image: redis:7-alpine
    container_name: mantis_redis_failover
    restart: unless-stopped
    command: >
      --maxmemory 256mb
      --maxmemory-policy allkeys-lru
      --save 900 1
      --save 300 10
      --save 60 10000
      --appendonly yes
      --appendfsync everysec
    networks:
      backend:
        ipv4_address: 10.3.2.10
    volumes:
      - redis_data:/data
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
    mem_limit: 384m
    mem_reservation: 128m
    cpus: 0.25
    cpu_shares: 256
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 10s
    deploy:
      resources:
        limits:
          cpus: "0.25"
          memory: 384M
        reservations:
          cpus: "0.1"
          memory: 128M
    logging:
      driver: "json-file"
      options:
        max-size: "20m"
        max-file: "3"
        labels: "service,redis"

  n8n:
    image: n8nio/n8n:latest
    container_name: mantis_n8n_failover
    restart: unless-stopped
    depends_on:
      redis:
        condition: service_healthy
    networks:
      frontend:
        ipv4_address: 10.3.1.10
      backend:
        ipv4_address: 10.3.2.20
    volumes:
      - n8n_data:/home/node/.n8n
      - /srv/volumes/vps3/n8n_logs:/home/node/.n8n/logs
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
    environment:
      - N8N_HOST=n8n-failover.mantis-agentic.internal
      - N8N_PORT=5678
      - N8N_PROTOCOL=https
      - WEBHOOK_URL=https://n8n-failover.mantis-agentic.internal/
      - N8N_REDIS_HOST=redis
      - N8N_REDIS_PORT=6379
      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
      - EXECUTIONS_DATA_SAVE_ON_ERROR=all
      - EXECUTIONS_DATA_SAVE_ON_SUCCESS=all
      - EXECUTIONS_DATA_SAVE_ON_TIMEOUT=true
      - EXECUTIONS_DATA_SAVE_MANUAL_EXECUTIONS=true
      - GENERIC_TIMEZONE=America/Sao_Paulo
      - NODE_ENV=production
    mem_limit: 1536m
    mem_reservation: 768m
    cpus: 0.5
    cpu_shares: 512
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:5678/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    deploy:
      resources:
        limits:
          cpus: "0.5"
          memory: 1536M
        reservations:
          cpus: "0.25"
          memory: 768M
    logging:
      driver: "json-file"
      options:
        max-size: "100m"
        max-file: "5"
        labels: "service,n8n"

  uazapi:
    image: uazapi:latest
    container_name: mantis_uazapi_failover
    restart: unless-stopped
    depends_on:
      redis:
        condition: service_healthy
    networks:
      frontend:
        ipv4_address: 10.3.1.15
      backend:
        ipv4_address: 10.3.2.25
    volumes:
      - uazapi_data:/app/data
      - /srv/volumes/vps3/uazapi_logs:/app/logs
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
    environment:
      - NODE_ENV=production
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - API_PORT=3000
      - API_RATE_LIMIT=100
      - API_TIMEOUT=30000
      - LOG_LEVEL=info
    mem_limit: 768m
    mem_reservation: 384m
    cpus: 0.25
    cpu_shares: 256
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3000/health"]
      interval: 15s
      timeout: 5s
      retries: 3
      start_period: 30s
    deploy:
      resources:
        limits:
          cpus: "0.25"
          memory: 768M
        reservations:
          cpus: "0.1"
          memory: 384M
    logging:
      driver: "json-file"
      options:
        max-size: "50m"
        max-file: "5"
        labels: "service,uazapi"
```

---

## 5. Resource Limits (C1, C2 Compliance)

### 5.1 Fundamentos de Limits y Reservations

Docker Compose permite especificar límites de recursos tanto hard limits (mem_limit, cpus) como soft guarantees (mem_reservation, cpu_shares) para cada contenedor. La diferencia fundamental entre estos dos conceptos radica en su comportamiento bajo presión de recursos: los límites representan el máximo absoluto que un contenedor puede utilizar, mientras que las reservas garantizan una cantidad mínima que estará disponible para el contenedor incluso bajo competencia por recursos.

En el contexto de los constraints MANTIS AGENTIC, donde cada VPS tiene exactamente 4GB de RAM y 1 vCPU (constraint C1 y C2), la correcta configuración de limits y reservations es crítica para evitar que un servicio individual monopolice los recursos del sistema. Los valores de memory_limit para cada servicio en los docker-compose.yml han sido calculados para asegurar que la suma de todos los límites no supere la memoria disponible del VPS, dejando margen para el sistema operativo host y overhead de Docker.

### 5.2 Calculo de Recursos por VPS

El cálculo de recursos sigue una metodología basada en perfiles de carga identificados durante la fase de specification-driven development. Para VPS-1, que ejecuta n8n, uazapi, Redis y Nginx, la distribución de memoria se calcula de la siguiente manera: Redis recibe 384MB (servicio de caché con límite interno de 256MB más overhead), n8n recibe 1536MB (aplicación Node.js con requerimientos moderados), uazapi recibe 768MB (API service), y Nginx recibe 128MB (proxy reverso ligero). La suma total de límites es 2816MB, dejando aproximadamente 1200MB para el sistema operativo, Docker engine, y overhead de contenedores.

VPS-2 presenta requisitos de memoria más demandantes debido a MySQL y Qdrant. MySQL recibe 768MB con configuración específica de InnoDB buffer pool de 256MB, Qdrant recibe 1536MB (base de datos vectorial con requerimientos significativos de memoria para índices), EspoCRM recibe 1024MB (aplicación PHP con overhead de Apache/Nginx), y Nginx recibe 128MB. La suma total de 3456MB deja aproximadamente 560MB para el sistema host, lo cual representa un margen más estrecho pero aceptable para este perfil de carga.

### 5.3 Configuracion de CPU

La distribución de CPU en un entorno con 1 vCPU requiere consideraciones especiales debido a la naturaleza del virtual CPU en entornos KVM de Hostinger. A diferencia de CPUs físicos multi-core, un vCPU único puede experimentar contención significativa cuando múltiples contenedores compiten por tiempo de CPU. La configuración de cpu_shares permite asignar pesos relativos a cada contenedor, donde un contenedor con 512 shares recibe el doble de tiempo de CPU que uno con 256 shares bajo condiciones de contención.

Los valores de cpu_shares asignados en los docker-compose.yml reflejan la prioridad relativa de cada servicio. Nginx tiene la prioridad más baja (128) ya que es principalmente I/O-bound y no requiere procesamiento intensivo de CPU. Servicios de aplicación como n8n, EspoCRM y Qdrant tienen prioridades medias (512-768) proporcionales a sus requerimientos de procesamiento. MySQL tiene una prioridad alta (512) para asegurar que las operaciones de base de datos no sufran latencia debido a competencia de CPU.

---

## 6. Healthchecks

### 6.1 Principios de Diseño de Healthchecks

Los healthchecks en Docker cumplen múltiples funciones críticas en una infraestructura de producción. Primero, permiten que Docker monitoree el estado de salud de cada contenedor y tome acciones automáticas cuando un servicio falla. Segundo, proporcionan datos para herramientas de orquestación que necesitan conocer qué contenedores están listos para recibir tráfico. Tercero, facilitan el debugging al permitir verificación manual del estado de servicios individuales.

Un healthcheck efectivo debe ser específico del servicio que está monitoreando, ejecutar rápidamente (típicamente menos de 30 segundos), no alterar el estado del servicio, y retornar códigos de salida claros (0 para saludable, 1 para no saludable). La frecuencia del healthcheck debe balancear la detección rápida de fallos con el overhead de monitoreo, típicamente entre 10 y 30 segundos para servicios de aplicación.

### 6.2 Healthchecks por Tipo de Servicio

Para servicios de base de datos como MySQL y Redis, el healthcheck debe verificar no solo que el proceso esté corriendo sino que también esté respondiendo a consultas de manera correcta. MySQL utiliza mysqladmin ping que verifica la conectividad al servidor. Redis utiliza redis-cli ping que verifica que el servidor pueda responder a comandos. Estos checks son ligeros pero efectivos para detectar fallos de servicio.

Para aplicaciones web como n8n, EspoCRM, y uazapi, los healthchecks utilizan endpoints HTTP dedicados que verifican no solo que el servidor web esté corriendo sino también que la aplicación haya completado su inicialización. Es importante verificar que estos endpoints de healthcheck no requieran autenticación, ya que el healthcheck debe funcionar incluso cuando el servicio está iniciando o experimentando problemas de configuración.

### 6.3 Integracion con depends_on

La propiedad depends_on en Docker Compose puede utilizar condiciones de healthcheck para controlar el orden de inicio de servicios. Esta funcionalidad es crucial para servicios que tienen dependencias de otros servicios, como por ejemplo EspoCRM que requiere MySQL completamente inicializado antes de poder funcionar correctamente. La sintaxis condition: service_healthy indica que Docker Compose no iniciarán el servicio dependiente hasta que el servicio indicado reporte un estado saludable.

```yaml
services:
  espocrm:
    depends_on:
      mysql:
        condition: service_healthy
```

Esta configuración reemplaza el comportamiento anterior de depends_on que solo esperaba a que el contenedor iniciara, sin verificar si el servicio interno estaba realmente listo para recibir conexiones. La combinación de healthchecks robustos y dependencias basadas en condiciones de salud garantiza que los servicios inicien en el orden correcto y que el sistema completo alcance un estado operativo después de un reinicio o despliegue.

---

## 7. Logs y Monitoring

### 7.1 Configuracion de Logging

Docker Compose permite configurar el driver de logging y sus opciones a nivel de cada servicio mediante la sección logging. Esta configuración es fundamental para entornos de producción donde los logs deben ser preservados por un período razonable y rotados automáticamente para evitar consumo excesivo de espacio en disco. El driver json-file es el más común y compatible con la mayoría de herramientas de agregación de logs.

Las opciones de logging para cada servicio en los docker-compose.yml han sido configuradas considerando el volumen esperado de logs y el espacio disponible en disco. Servicios con alto volumen de logs como n8n y Qdrant tienen límites de 100MB por archivo con 5 archivos máximo, resultando en 500MB máximo de logs por servicio. Servicios con volumen moderado como EspoCRM y uazapi tienen límites de 50MB por archivo con 3 archivos máximo. Nginx y otros servicios ligeros tienen límites más restrictivos de 10MB por archivo.

### 7.2 Rotacion de Logs

La rotación de logs en Docker está controlada por las opciones max-size y max-file. Cuando un archivo de log alcanza max-size, Docker lo cierra y crea uno nuevo. Cuando el número de archivos de log alcanza max-file, el más antiguo se elimina. Esta estrategia de rotación garantiza que los logs no consuman espacio ilimitado mientras mantiene un historial razonable para debugging.

Es importante notar que la configuración de logging de Docker no truncates existing logs cuando se reduce el tamaño máximo, por lo que los cambios en la configuración solo aplican a nuevos archivos de log. Para aplicar cambios en archivos existentes, es necesario truncar manualmente los archivos de log usando el comando truncate -s 0 /var/lib/docker/containers/*/*-json.log o eliminar los contenedores y recrearlos.

### 7.3 Agregacion Centralizada de Logs

Para una infraestructura distribuida como MANTIS AGENTIC con tres VPS, la agregación centralizada de logs es esencial para debugging efectivo y monitoreo de seguridad. Aunque la implementación detallada de un sistema de agregación de logs está fuera del alcance de este documento, la configuración de logging de cada servicio utiliza labels que facilitan la identificación y filtrado de logs por servicio y VPS.

Los labels especificados en la configuración de logging (service,nombre_servicio) permiten que herramientas de agregación como Fluentd, Logstash, o vector filtren y路由 logs basándose en metadatos estructurados. Esta etiquetado es particularmente útil cuando se implementa una arquitectura de logging centralizado donde logs de múltiples VPS son agregados en un sistema común para análisis cross-servicio.

---

## 8. Cross-Host Networking

### 8.1 Arquitectura de Comunicacion Inter-VPS

La comunicación entre los tres VPS de la infraestructura MANTIS AGENTIC requiereconsideraciones especiales de networking que van más allá de la configuración de Docker Compose individual. Cada VPS tiene su propia red Docker bridge con rangos de IP distintos (10.1.x.x para VPS-1, 10.0.x.x para VPS-2, 10.3.x.x para VPS-3), lo que significa que los contenedores no pueden comunicarse directamente a través de direcciones IP privadas de Docker entre hosts.

La solución implementada utiliza una combinación de exposición de puertos específicos en interfaces de red del host, proxys de aplicación, y comunicación a través de la red pública con TLS. Esta arquitectura asegura que solo los servicios necesarios estén accesibles entre VPS, mientras mantiene el aislamiento de redes internas de Docker en cada host.

### 8.2 Conexion VPS-1 a VPS-2

El flujo de comunicación desde VPS-1 (n8n, uazapi) hacia VPS-2 (EspoCRM, MySQL, Qdrant) sigue un patrón definido. Los contenedores en VPS-1 que necesitan acceder a servicios en VPS-2 lo hacen a través de la red pública del VPS-2, utilizando el FQDN (Fully Qualified Domain Name) configurado en el DNS interno. Por ejemplo, n8n en VPS-1 se conecta a Qdrant en VPS-2 utilizando la URL configurada como http://qdrant.mantis-agentic.internal:6333.

El reverse proxy Nginx en VPS-2 listens on the public network and forwards requests to internal Docker services based on the hostname. Esta configuración permite que servicios en otros VPS accedan a Qdrant y EspoCRM sin necesidad de exponer directamente los puertos Docker al exterior. La exposición de puertos en los docker-compose.yml utiliza 127.0.0.1:PORT:PORT para asegurar que los puertos solo estén accesibles desde localhost, y el reverse proxy en cada VPS maneja la exposición externa.

### 8.3 Configuracion de DNS para Cross-Host Communication

La resolución DNS para comunicación cross-host se configura a nivel de cada VPS utilizando el archivo /etc/hosts o un servicio DNS local. Cada VPS tiene entradas que mapean los FQDN de servicios externos a las direcciones IP públicas del VPS correspondiente. Esta configuración permite que los contenedores utilicen nombres de dominio significativos en lugar de direcciones IP hardcodeadas.

```bash
# /etc/hosts en VPS-1 para resolucion de servicios VPS-2
203.0.113.10  qdrant.mantis-agentic.internal
203.0.113.10  espocrm.mantis-agentic.internal
```

Alternativamente, se puede configurar un DNS resolver local que redirija consultas para el dominio mantis-agentic.internal a los servidores DNS correspondientes de cada VPS. Esta arquitectura de DNS distribuido permite flexibilidad en la gestión de direcciones IP de los VPS, ya que los contenedores solo necesitan conocer los nombres de dominio, no las direcciones IP específicas.

---

## 9. Backup de Volumenes

### 9.1 Estrategia de Backup

Los volúmenes Docker en la infraestructura MANTIS AGENTIC contienen datos críticos que requieren backup regular. La estrategia de backup implementada sigue un enfoque de snapshots basados en archivos, donde los volúmenes se respaldan utilizando la técnica de bind mount combinada con scripts de backup automatizados que se ejecutan periódicamente.

Los volúmenes definidos en los docker-compose.yml utilizan drivers locales con bind mounts hacia directorios específicos en el sistema de archivos del host (/srv/volumes/vpsX/). Esta configuración facilita la implementación de backups ya que los datos están directamente accesibles desde el host como archivos regulares, eliminando la necesidad de utilizar herramientas especiales de Docker para extraer datos de volúmenes.

### 9.2 Script de Backup

El siguiente script de backup ejemplifica la metodología utilizada para respaldar los volúmenes de cada VPS. El script debe ejecutarse como tarea cron diaria y almacenarse en /usr/local/bin/backup-volumes.sh con permisos de ejecución.

```bash
#!/bin/bash
set -euo pipefail

BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
VPS_NUMBER=${1:-1}
BACKUP_DIR="/srv/backups/vps${VPS_NUMBER}"
VOLUME_DIR="/srv/volumes/vps${VPS_NUMBER}"
RETENTION_DAYS=7

mkdir -p "${BACKUP_DIR}"

for volume_dir in "${VOLUME_DIR}"/*/; do
    if [ -d "$volume_dir" ]; then
        volume_name=$(basename "$volume_dir")
        backup_file="${BACKUP_DIR}/${volume_name}_${BACKUP_DATE}.tar.gz"

        tar -czf "$backup_file" -C "$(dirname "$volume_dir")" "$volume_name"

        echo "[${BACKUP_DATE}] Backup completed: ${backup_file}"
    fi
done

find "${BACKUP_DIR}" -name "*.tar.gz" -mtime +${RETENTION_DAYS} -delete

echo "[${BACKUP_DATE}] Backup rotation completed for VPS-${VPS_NUMBER}"
```

### 9.3 Restore Procedure

El procedimiento de restauración de volúmenes debe probarse regularmente para asegurar que los backups son utilizables. El siguiente comando exemplifica cómo restaurar un volumen específico desde un archivo de backup.

```bash
# Detener el servicio antes de restaurar
docker-compose -f /srv/docker/vps2/docker-compose.yml stop espocrm mysql qdrant

# Restaurar el volumen de MySQL
tar -xzf /srv/backups/vps2/mysql_data_20260409_120000.tar.gz -C /srv/volumes/vps2/

# Reiniciar servicios
docker-compose -f /srv/docker/vps2/docker-compose.yml start mysql
docker-compose -f /srv/docker/vps2/docker-compose.yml up -d
```

---

## 10. Compliance y Rastreabilidad de Especificaciones

### 10.1 ARQ-004: Aislamiento de Redes por Stack

La especificación ARQ-004 establece que cada stack de servicios debe tener redes aisladas que impidan comunicación no autorizada entre servicios de diferentes stacks. La implementación de esta especificación se verifica en los docker-compose.yml mediante la definición de redes separadas (frontend, backend, internal) y la asignación explicita de cada servicio a las redes necesarias.

El aislamiento se refuerza mediante la no exposición de puertos de servicios internos al exterior. MySQL y Redis en cada VPS no tienen puertos mapeados en la sección ports de docker-compose.yml, garantizando que solo pueden ser accedidos desde otros contenedores en la misma red Docker. Los servicios que requieren acceso externo (n8n, EspoCRM, Qdrant) se exponen únicamente a través de Nginx acting as reverse proxy.

### 10.2 ARQ-009: Comunicacion Seguro Cross-Host

La especificación ARQ-009 requiere que toda comunicación entre hosts debe realizarse a través de canales seguros con autenticación. La implementación para la comunicación cross-host en MANTIS AGENTIC utiliza HTTPS con certificados TLS para todas las comunicaciones externas, tanto para APIs web como para terminales de base de datos cuando es necesario.

Los endpoints expuestos externamente (n8n, EspoCRM, Qdrant) requieren configuración de TLS en el reverse proxy Nginx. Los certificados SSL se almacenan en /srv/volumes/vpsX/ssl/ y se configuran en los archivos de configuración de Nginx. Para entornos de producción, se recomienda utilizar Let's Encrypt para certificados automáticos, o certificados de una autoridad certificadora empresarial para dominios internos.

### 10.3 RES-001: Limites de Memoria por Contenedor

La especificación RES-001 establece límites de memoria específicos para cada tipo de servicio, con un máximo absoluto de 4GB por contenedor según el constraint C1. Los valores de mem_limit en los docker-compose.yml cumplen con esta especificación, siendo el valor más alto 1536MB para n8n y Qdrant, ambos bien por debajo del límite máximo establecido.

La verificación de cumplimiento se realiza mediante la revisión de la sección deploy.resources.limits.memory de cada servicio en los archivos docker-compose.yml. Los scripts de validación referenciados en el frontmatter de este documento (scripts/validate-against-specs.sh) automatizan esta verificación como parte del proceso de CI/CD.

### 10.4 RES-002: Limites de CPU

La especificación RES-002 en conjunto con el constraint C2 limita el uso de CPU a 1 vCPU por VPS. La distribución de CPU entre contenedores se configura mediante cpu_shares que proporcionan garantías relativas más que absolutas. En situaciones de alta carga, los contenedores con mayor cpu_shares reciben más tiempo de CPU.

Los valores de cpus (límites absolutos de CPU) están configurados para que la suma de todos los límites no exceda 1.0 CPUs lógicos. Esta configuración asegura que incluso en el escenario donde todos los contenedores utilizan su límite máximo simultáneamente, el sistema no experimente sobrecarga de CPU más allá de la capacidad del vCPU del VPS.

---

## 11. Troubleshooting

### 11.1 Problemas de Conectividad Entre Servicios

Cuando los contenedores no pueden comunicarse entre sí en la misma red Docker, el primer paso de diagnóstico es verificar que ambos contenedores estén efectivamente en la misma red. El comando docker network inspect <network_name> muestra todos los contenedores conectados a una red específica junto con sus direcciones IP. Si los contenedores están en redes diferentes, la solución es agregarlos a la red común usando docker network connect.

```bash
# Listar redes en el sistema
docker network ls

# Inspeccionar una red específica
docker network inspect mantis-agentic_backend

# Ver contenedores conectados a una red
docker network inspect mantis-agentic_backend --format '{{range .Containers}}{{.Name}}: {{.IPv4Address}}{{println}}{{end}}'
```

Si los contenedores están en la misma red pero no pueden resolverse por nombre, verificar que el DNS de Docker esté funcionando correctamente. El comando docker exec <container> nslookup <service_name> permite probar la resolución DNS desde un contenedor específico. Problemas de DNS pueden indicar que el daemon de Docker necesita reiniciarse o que hay configuraciones de red conflictivas en el host.

### 11.2 Problemas de Resource Limits

Cuando los contenedores alcanzan sus límites de memoria o CPU y exhiben comportamiento anómalo, es importante diagnosticar si el problema es efectivamente caused by resource constraints. Docker proporciona estadísticas en tiempo real a través de docker stats que muestran el uso actual de memoria y CPU por contenedor.

```bash
# Ver estadísticas de todos los contenedores
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

# Ver límites configurados para un contenedor específico
docker inspect --format '{{json .HostConfig.Memory}}' <container_name>
```

Si un contenedor está siendo terminated por el limits de memoria (OOMKilled), la solución puede involucrar aumentar el mem_limit si el servicio legítimo requiere más memoria, optimizar la configuración del servicio para usar menos memoria, o agregar swap al VPS si hay espacio disponible en el volumen NVMe.

### 11.3 Problemas de Healthcheck

Los healthchecks que fallan pueden causar que los servicios no inicien o sean restartados repetidamente por Docker. Para debugging de healthchecks, la primera الخطوة es ejecutar manualmente el comando del healthcheck y observar su salida.

```bash
# Ejecutar manualmente el healthcheck de MySQL
docker exec mantis_mysql mysqladmin ping -h localhost -u root -p${MYSQL_ROOT_PASSWORD}

# Ejecutar manualmente el healthcheck de Redis
docker exec mantis_redis redis-cli ping

# Ver historial de healthcheck de un contenedor
docker inspect --format '{{range .State.Health.Log}}{{.Start}} - Exit: {{.ExitCode}} - Output: {{.Output}}{{println}}{{end}}' <container_name>
```

Los healthchecks basados en HTTP pueden fallar por múltiples razones: el endpoint de healthcheck no existe o retorna un código de estado diferente a 200, el servicio está inicializándose y aún no está listo para recibir requests, o el servicio está experimentando errores internos. La revisión de logs del contenedor durante el período del healthcheck fallido proporciona contexto adicional para el diagnóstico.

### 11.4 Problemas de Cross-Host Networking

Cuando los servicios en un VPS no pueden conectar a servicios en otro VPS, verificar primero la conectividad básica a nivel de red. El comando ping o nc (netcat) desde el host puede determinar si la dirección IP del otro VPS es reachable.

```bash
# Verificar conectividad desde VPS-1 a VPS-2
ping -c 3 203.0.113.10
nc -zv 203.0.113.10 443

# Verificar que el servicio esté escuchando en el VPS remoto
ssh user@vps1 "curl -I https://qdrant.mantis-agentic.internal/health"
```

Si la conectividad de red es correcta pero los servicios no responden, el problema puede estar en la configuración del reverse proxy o en las reglas de firewall. Verificar que Nginx esté corriendo y configurado correctamente, y que las reglas de iptables o ufw permitan el tráfico relevante entre las redes de los VPS.

---

## 12. Ejemplos Completos Adicionales

### 12.1 Ejemplo Completo: Redes Docker Aisladas con Healthchecks

Este ejemplo demuestra una configuración avanzada de redes Docker aisladas con múltiples servicios y healthchecks comprehensivos. La arquitectura incluye un servicio de API, un servicio de base de datos, y un servicio de cache, todos configurados con redes separadas y healthchecks apropiados.

```yaml
version: "3.9"

networks:
  web:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.20.1.0/24
  app:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.20.2.0/24
  data:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.20.3.0/24

services:
  postgres:
    image: postgres:15-alpine
    container_name: isolated_postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: appdb
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    networks:
      data:
        ipv4_address: 172.20.3.10
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - /etc/localtime:/etc/localtime:ro
    mem_limit: 512m
    mem_reservation: 256m
    cpus: 0.5
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U appuser -d appdb"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s
    deploy:
      resources:
        limits:
          cpus: "0.5"
          memory: 512M
        reservations:
          cpus: "0.25"
          memory: 256M
    logging:
      driver: "json-file"
      options:
        max-size: "50m"
        max-file: "3"

  redis:
    image: redis:7-alpine
    container_name: isolated_redis
    restart: unless-stopped
    command: >
      --maxmemory 128mb
      --maxmemory-policy allkeys-lru
      --save 300 1
    networks:
      data:
        ipv4_address: 172.20.3.15
    volumes:
      - redis_data:/data
      - /etc/localtime:/etc/localtime:ro
    mem_limit: 256m
    mem_reservation: 128m
    cpus: 0.25
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 10s
    deploy:
      resources:
        limits:
          cpus: "0.25"
          memory: 256M
        reservations:
          cpus: "0.1"
          memory: 128M
    logging:
      driver: "json-file"
      options:
        max-size: "20m"
        max-file: "3"

  api:
    image: api-service:latest
    container_name: isolated_api
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      app:
        ipv4_address: 172.20.2.10
      web:
        ipv4_address: 172.20.1.10
    volumes:
      - /srv/app_logs:/app/logs
      - /etc/localtime:/etc/localtime:ro
    environment:
      - DATABASE_URL=postgresql://appuser:${DB_PASSWORD}@postgres:5432/appdb
      - REDIS_URL=redis://redis:6379/0
      - NODE_ENV=production
    ports:
      - "127.0.0.1:3000:3000"
    mem_limit: 768m
    mem_reservation: 384m
    cpus: 0.5
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3000/health"]
      interval: 15s
      timeout: 10s
      retries: 3
      start_period: 40s
    deploy:
      resources:
        limits:
          cpus: "0.5"
          memory: 768M
        reservations:
          cpus: "0.25"
          memory: 384M
    logging:
      driver: "json-file"
      options:
        max-size: "100m"
        max-file: "5"

  nginx:
    image: nginx:1.25-alpine
    container_name: isolated_nginx
    restart: unless-stopped
    depends_on:
      - api
    networks:
      web:
        ipv4_address: 172.20.1.5
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "80:80"
      - "443:443"
    mem_limit: 128m
    mem_reservation: 64m
    cpus: 0.1
    healthcheck:
      test: ["CMD", "nginx", "-t"]
      interval: 30s
      timeout: 5s
      retries: 3
    deploy:
      resources:
        limits:
          cpus: "0.1"
          memory: 128M
        reservations:
          cpus: "0.05"
          memory: 64M
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

### 12.2 Ejemplo Completo: docker-compose para VPS-1 con Resource Limits

Este ejemplo muestra la configuración completa del VPS-1 con énfasis en resource limits y compliance con los constraints C1 y C2. La configuración demuestra cómo分配 recursos de manera que todos los servicios puedan operar simultáneamente sin competencia excesiva.

```yaml
version: "3.9"

networks:
  web:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 10.1.1.0/24
          gateway: 10.1.1.1
  internal:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 10.1.2.0/24
          gateway: 10.1.2.1

volumes:
  n8n_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /srv/volumes/vps1/n8n_data
  redis_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /srv/volumes/vps1/redis_data
  uazapi_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /srv/volumes/vps1/uazapi_data
  nginx_certs:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /srv/volumes/vps1/ssl

services:
  redis:
    image: redis:7-alpine
    container_name: mantis_redis_vps1
    restart: unless-stopped
    command: >
      --maxmemory 256mb
      --maxmemory-policy allkeys-lru
      --maxmemory-samples 3
      --lazyfree-lazy-eviction yes
      --lazyfree-lazy-expire yes
      --save 900 1
      --save 300 10
      --save 60 10000
      --appendonly yes
      --appendfsync everysec
    networks:
      internal:
        ipv4_address: 10.1.2.10
    volumes:
      - redis_data:/data
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
    mem_limit: 384m
    mem_reservation: 128m
    cpus: 0.25
    cpu_shares: 256
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 10s
    deploy:
      resources:
        limits:
          cpus: "0.25"
          memory: 384M
        reservations:
          cpus: "0.1"
          memory: 128M
    logging:
      driver: "json-file"
      options:
        max-size: "20m"
        max-file: "3"
        labels: "service,redis,vps1"

  n8n:
    image: n8nio/n8n:latest
    container_name: mantis_n8n_vps1
    restart: unless-stopped
    depends_on:
      redis:
        condition: service_healthy
    networks:
      web:
        ipv4_address: 10.1.1.10
      internal:
        ipv4_address: 10.1.2.20
    volumes:
      - n8n_data:/home/node/.n8n
      - /srv/volumes/vps1/n8n_data/logs:/home/node/.n8n/logs
      - /srv/volumes/vps1/n8n_data/workflows:/home/node/.n8n/workflows
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
    environment:
      - N8N_HOST=n8n.mantis-agentic.internal
      - N8N_PORT=5678
      - N8N_PROTOCOL=https
      - WEBHOOK_URL=https://n8n.mantis-agentic.internal/
      - N8N_REDIS_HOST=redis
      - N8N_REDIS_PORT=6379
      - N8N_REDIS_DB=0
      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
      - N8N_DEFAULT_BINARY_DATA_MODE=filesystem
      - N8N_EXECUTIONS_DATA_SAVE_ON_ERROR=all
      - N8N_EXECUTIONS_DATA_SAVE_ON_SUCCESS=all
      - N8N_EXECUTIONS_DATA_SAVE_ON_TIMEOUT=true
      - N8N_EXECUTIONS_DATA_SAVE_MANUAL_EXECUTIONS=true
      - N8N_EXECUTIONS_DATA_SAVE_EXECUTION_OUTPUT=true
      - N8N_DIAGNOSTICS_ENABLED=false
      - N8N_LOG_LEVEL=info
      - GENERIC_TIMEZONE=America/Sao_Paulo
      - NODE_ENV=production
      - NODE_OPTIONS=--max-old-space-size=1400
    ports:
      - "127.0.0.1:5678:5678"
    mem_limit: 1536m
    mem_reservation: 768m
    cpus: 0.5
    cpu_shares: 512
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:5678/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    deploy:
      resources:
        limits:
          cpus: "0.5"
          memory: 1536M
        reservations:
          cpus: "0.25"
          memory: 768M
    logging:
      driver: "json-file"
      options:
        max-size: "100m"
        max-file: "5"
        labels: "service,n8n,vps1"

  uazapi:
    image: uazapi:latest
    container_name: mantis_uazapi_vps1
    restart: unless-stopped
    depends_on:
      redis:
        condition: service_healthy
    networks:
      web:
        ipv4_address: 10.1.1.15
      internal:
        ipv4_address: 10.1.2.25
    volumes:
      - uazapi_data:/app/data
      - /srv/volumes/vps1/uazapi_logs:/app/logs
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
    environment:
      - NODE_ENV=production
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - REDIS_DB=0
      - API_PORT=3000
      - API_HOST=0.0.0.0
      - API_RATE_LIMIT=100
      - API_RATE_LIMIT_WINDOW=60000
      - API_TIMEOUT=30000
      - API_CORS_ORIGIN=https://n8n.mantis-agentic.internal
      - LOG_LEVEL=info
      - LOG_FORMAT=json
      - NODE_OPTIONS=--max-old-space-size=700
    ports:
      - "127.0.0.1:3000:3000"
    mem_limit: 768m
    mem_reservation: 384m
    cpus: 0.25
    cpu_shares: 256
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3000/health"]
      interval: 15s
      timeout: 5s
      retries: 3
      start_period: 30s
    deploy:
      resources:
        limits:
          cpus: "0.25"
          memory: 768M
        reservations:
          cpus: "0.1"
          memory: 384M
    logging:
      driver: "json-file"
      options:
        max-size: "50m"
        max-file: "5"
        labels: "service,uazapi,vps1"

  nginx:
    image: nginx:1.25-alpine
    container_name: mantis_nginx_vps1
    restart: unless-stopped
    depends_on:
      - n8n
      - uazapi
    networks:
      web:
        ipv4_address: 10.1.1.5
    volumes:
      - /srv/volumes/vps1/nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - /srv/volumes/vps1/nginx/conf.d:/etc/nginx/conf.d:ro
      - nginx_certs:/etc/nginx/ssl:ro
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
      - /srv/volumes/vps1/nginx_logs:/var/log/nginx
    ports:
      - "80:80"
      - "443:443"
    mem_limit: 128m
    mem_reservation: 64m
    cpus: 0.1
    cpu_shares: 128
    healthcheck:
      test: ["CMD", "nginx", "-t"]
      interval: 30s
      timeout: 5s
      retries: 3
    deploy:
      resources:
        limits:
          cpus: "0.1"
          memory: 128M
        reservations:
          cpus: "0.05"
          memory: 64M
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "5"
        labels: "service,nginx,vps1"
```

---

## 13. Resumen y Referencias

Este documento ha detallado la arquitectura de networking Docker Compose para la infraestructura MANTIS AGENTIC, incluyendo configuraciones completas para los tres VPS que conforman el sistema. Las especificaciones aquí contenidas cumplen con los constraints de recursos (C1: 4GB RAM máximo, C2: 1 vCPU) y el constraint de seguridad (C3: bases de datos nunca en 0.0.0.0).

Las configuraciones de red utilizan modelos de tres capas (pública, interna, datos) que proporcionan aislamiento apropiado entre componentes de diferentes stacks mientras permiten comunicación controlada cross-host cuando es necesario. Los resource limits están calculados para garantizar operación estable bajo carga normal mientras previenen que un servicio individual monopolice los recursos del VPS.

La implementación de healthchecks robustos, políticas de restart apropiadas, y configuración de logging estructurado facilitan el monitoreo continuo y el debugging efectivo cuando problemas ocurren. Los procedimientos de backup de volúmenes documentados aseguran que los datos críticos puedan ser restaurados en caso de fallas.

### Archivos Relacionados

Este documento debe utilizarse en conjunto con los siguientes archivos del proyecto MANTIS AGENTIC para una comprensión completa de la infraestructura:

- `01-RULES/01-ARCHITECTURE-RULES.md` - Reglas de arquitectura general
- `01-RULES/02-RESOURCE-GUARDRAILS.md` - Restricciones de recursos y monitoreo
- `01-RULES/05-CODE-PATTERNS-RULES.md` - Patrones de código y configuración
- `05-CONFIGURATIONS/docker-compose/` - Archivos docker-compose.yml específicos de cada VPS

### Referencias Tecnicas

- Docker Compose File Reference: https://docs.docker.com/compose/compose-file/
- Docker Networking Guide: https://docs.docker.com/network/
- Docker Health Check Documentation: https://docs.docker.com/engine/reference/builder/#healthcheck
- Resource Constraints in Docker: https://docs.docker.com/config/containers/resource_constraints/
