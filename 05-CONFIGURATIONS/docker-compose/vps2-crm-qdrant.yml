---
title: "vps2-crm-qdrant — Docker Compose VPS2"
version: "1.0.0"
canonical_path: "05-CONFIGURATIONS/docker-compose/vps2-crm-qdrant.yml"
status: "PRODUCTION_READY"
constraints_mapped: ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8"]
target_servers:
  kvm1: { vcpu: 1, ram_gb: 4, nvme_gb: 50, bandwidth_tb: 4 }
  kvm2: { vcpu: 2, ram_gb: 8, nvme_gb: 100, bandwidth_tb: 8 }
services: ["espocrm", "mysql", "qdrant", "traefik", "otel-collector"]
network_role: "HUB — BD central accesible solo via SSH tunnel desde VPS1/VPS3"
public_access: "Solo EspoCRM vía HTTPS (puerto 443). MySQL y Qdrant: SOLO red interna."
validation_command: |
  grep -cE 'mem_limit|cpus|pids_limit' vps2-crm-qdrant.yml
  # Esperado: >= 18 líneas con límites definidos
last_updated: "2026-04-13"
related_files:
  - "[[05-CONFIGURATIONS/docker-compose/00-INDEX.md]]"
  - "[[05-CONFIGURATIONS/docker-compose/vps1-n8n-uazapi.yml]]"
  - "[[05-CONFIGURATIONS/docker-compose/vps3-n8n-uazapi.yml]]"
  - "[[05-CONFIGURATIONS/terraform/modules/vps-base/main.tf]]"
  - "[[05-CONFIGURATIONS/validation/validate-skill-integrity.sh]]"
  - "[[05-CONFIGURATIONS/observability/otel-tracing-config.yaml]]"
  - "[[02-SKILLS/INFRASTRUCTURA/espocrm-setup.md]]"
  - "[[02-SKILLS/INFRASTRUCTURA/vps-interconnection.md]]"
  - "[[02-SKILLS/INFRASTRUCTURA/ssh-tunnels-remote-services.md]]"
  - "[[02-SKILLS/BASE DE DATOS-RAG/qdrant-rag-ingestion.md]]"
  - "[[02-SKILLS/BASE DE DATOS-RAG/mysql-sql-rag-ingestion.md]]"
  - "[[02-SKILLS/BASE DE DATOS-RAG/mysql-optimization-4gb-ram.md]]"
  - "[[02-SKILLS/SEGURIDAD/security-hardening-vps.md]]"
  - "[[01-RULES/01-ARCHITECTURE-RULES.md]]"
  - "[[01-RULES/02-RESOURCE-GUARDRAILS.md]]"
  - "[[01-RULES/03-SECURITY-RULES.md]]"
  - "[[01-RULES/06-MULTITENANCY-RULES.md]]"
---

# 🗄️ VPS2 — Docker Compose: EspoCRM + MySQL + Qdrant + Traefik + OTEL

> **Rol de este VPS en la red MANTIS:** Hub de datos central.
> MySQL y Qdrant son **COMPLETAMENTE INACCESIBLES desde internet**.
> Solo se acceden desde VPS1/VPS3 a través de túneles SSH cifrados.
> EspoCRM es el único servicio con acceso HTTPS público (para clientes del CRM).

---

## 📐 Fundamentos para Juniors — ¿Qué hace este servidor?

```
INTERNET
    │
    │ Solo HTTPS:443 → EspoCRM (interfaz web del CRM para clientes)
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│  VPS2 (Hub de datos)                                        │
│                                                              │
│  [Traefik] ─── HTTPS ──→ [EspoCRM]                         │
│                                                              │
│  [MySQL]   ←── SSH Tunnel ─── VPS1 / VPS3                  │
│  [Qdrant]  ←── SSH Tunnel ─── VPS1 / VPS3                  │
│                                                              │
│  NINGÚN puerto de MySQL ni Qdrant tiene salida al internet  │
└─────────────────────────────────────────────────────────────┘
```

**¿Por qué MySQL y Qdrant no son públicos?**
Si alguien en internet puede conectarse directamente a tu MySQL, puede intentar:
- Fuerza bruta de contraseña
- Exploits de versiones vulnerables
- SQL injection desde conexión directa
- Extracción masiva de datos

Los túneles SSH resuelven esto: la única "puerta" que existe al exterior es SSH (puerto 22, protegido con clave, no con contraseña). Todo lo demás es invisible desde internet.

---

## 📊 Distribución de Recursos

### KVM1 (1 vCPU / 4 GB RAM) — Configuración Inicial

```
VPS2 KVM1 — 4 GB RAM total
├── EspoCRM PHP-FPM  → 512 MB RAM  |  0.25 vCPU  ← CRM web para clientes
├── MySQL 8.0        → 1024 MB RAM |  0.30 vCPU  ← BD relacional (EspoCRM + RAG)
├── Qdrant           → 1024 MB RAM |  0.25 vCPU  ← Vector store (RAG)
├── Traefik          → 128 MB RAM  |  0.08 vCPU  ← HTTPS + TLS
├── OTEL Collector   → 96 MB RAM   |  0.07 vCPU  ← observabilidad C8
└── OS / kernel      → 512 MB RAM  |  0.05 vCPU  ← reservado
   TOTAL             → 3.30 GB     |  1.00 vCPU  ✅ dentro de C1/C2

⚠️  ADVERTENCIA KVM1: MySQL + Qdrant compiten por RAM.
    Con muchos tenants activos, considerar KVM2.
    Señal de alerta: docker stats muestra > 80% RAM constantemente.
```

### KVM2 (2 vCPU / 8 GB RAM) — Scale-Up Recomendado para VPS2

```
VPS2 KVM2 — 8 GB RAM total  (CONFIGURACIÓN IDEAL para VPS2)
├── EspoCRM PHP-FPM  → 1024 MB RAM |  0.40 vCPU
├── MySQL 8.0        → 2048 MB RAM |  0.60 vCPU  ← innodb_buffer_pool_size=1.5GB
├── Qdrant           → 2048 MB RAM |  0.70 vCPU  ← más colecciones simultáneas
├── Traefik          → 256 MB RAM  |  0.10 vCPU
├── OTEL Collector   → 192 MB RAM  |  0.10 vCPU
└── OS / kernel      → 1024 MB RAM |  0.10 vCPU
   TOTAL             → 6.59 GB     |  2.00 vCPU  ✅ dentro de C1/C2
```

---

## 📁 Archivo Principal — KVM1 (Default)

```yaml
# ==============================================================================
# 05-CONFIGURATIONS/docker-compose/vps2-crm-qdrant.yml
# VPS2: EspoCRM + MySQL + Qdrant + Traefik + OTEL Collector
# Rol: HUB de datos central de la red MANTIS AGENTIC
# Target: KVM1 (1 vCPU / 4 GB RAM / 50 GB NVMe)  |  Override: ver kvm2.override.yml
# Constraints: C1(RAM) C2(CPU) C3(secrets+no-expose-db) C4(tenant) C7(resiliencia) C8(logs)
# REGLA C3 CRÍTICA: MySQL y Qdrant NUNCA exponen puertos al exterior (0.0.0.0).
#                   Solo accesibles desde la red Docker interna y túneles SSH.
# Versión: 1.0.0 | MANTIS AGENTIC — SDD Hardened
# ==============================================================================

x-logging-default: &logging-default
  driver: json-file
  options:
    max-size: "50m"
    max-file: "3"
    tag: "{{.Name}}/{{.ID}}"

x-restart-default: &restart-default
  restart: unless-stopped

x-healthcheck-base: &healthcheck-base
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 90s   # MySQL y EspoCRM necesitan más tiempo de arranque

x-networks-default: &networks-default
  networks:
    - mantis-internal-vps2

services:

  # ─────────────────────────────────────────────────────────────────────────
  # TRAEFIK — Reverse Proxy + TLS (Let's Encrypt)
  # Único servicio con puertos públicos en VPS2
  # Solo expone EspoCRM. MySQL y Qdrant NO pasan por Traefik.
  # ─────────────────────────────────────────────────────────────────────────
  traefik:
    image: traefik:v3.0
    container_name: mantis-vps2-traefik
    <<: *restart-default
    <<: *networks-default
    logging: *logging-default

    mem_limit: 128m
    mem_reservation: 64m
    memswap_limit: 128m
    cpus: "0.08"
    pids_limit: 100

    ports:
      - "80:80"                      # HTTP → redirect HTTPS
      - "443:443"                    # HTTPS — EspoCRM público
      - "127.0.0.1:8080:8080"       # Dashboard — solo localhost (C3)

    environment:
      - TRAEFIK_LOG_LEVEL=${TRAEFIK_LOG_LEVEL:-warn}
      - TRAEFIK_CERTIFICATESRESOLVERS_LETSENCRYPT_ACME_EMAIL=${ACME_EMAIL:?C3: ACME_EMAIL missing}

    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - traefik-certs-vps2:/letsencrypt

    command:
      - "--api.insecure=false"
      - "--api.dashboard=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--providers.docker.network=mantis-internal-vps2"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.web.http.redirections.entryPoint.to=websecure"
      - "--entrypoints.web.http.redirections.entryPoint.scheme=https"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.letsencrypt.acme.tlschallenge=true"
      - "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
      # C7: Timeouts conservadores para EspoCRM (PHP puede ser lento)
      - "--entrypoints.websecure.transport.respondingTimeouts.readTimeout=90s"
      - "--entrypoints.websecure.transport.respondingTimeouts.writeTimeout=90s"
      - "--entrypoints.websecure.transport.respondingTimeouts.idleTimeout=300s"
      # C8: Logs JSON
      - "--accesslog=true"
      - "--accesslog.format=json"
      - "--log.format=json"
      - "--metrics.prometheus=true"

    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.traefik-vps2.rule=Host(`traefik.${CRM_DOMAIN:?C3: CRM_DOMAIN missing}`)"
      - "traefik.http.routers.traefik-vps2.tls.certresolver=letsencrypt"
      - "traefik.http.routers.traefik-vps2.middlewares=traefik-auth-vps2"
      - "traefik.http.middlewares.traefik-auth-vps2.basicauth.users=${TRAEFIK_DASHBOARD_AUTH:?C3: TRAEFIK_DASHBOARD_AUTH missing}"

    healthcheck:
      test: ["CMD", "traefik", "healthcheck", "--ping"]
      <<: *healthcheck-base

  # ─────────────────────────────────────────────────────────────────────────
  # MYSQL 8.0 — Base de Datos Relacional
  # REGLA C3 ABSOLUTA: Solo bind en 127.0.0.1 dentro del contenedor.
  # VPS1/VPS3 acceden mediante túnel SSH, NO por puerto público.
  #
  # Para junior: imagina que MySQL vive en una caja fuerte.
  # Solo se puede abrir desde adentro de la casa (red Docker interna)
  # o a través de una llave especial (túnel SSH). Nunca desde la calle.
  # ─────────────────────────────────────────────────────────────────────────
  mysql:
    image: mysql:8.0
    container_name: mantis-mysql
    <<: *restart-default
    <<: *networks-default
    logging: *logging-default

    # C1: 1GB RAM para KVM1 (ver mysql-optimization-4gb-ram.md)
    mem_limit: 1024m
    mem_reservation: 512m
    memswap_limit: 1024m   # Sin swap — fallo limpio
    cpus: "0.30"
    pids_limit: 200        # MySQL crea procesos por conexión

    environment:
      # C3: Credenciales desde env — falla si no están
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:?C3: MYSQL_ROOT_PASSWORD missing}
      MYSQL_DATABASE: ${MYSQL_DATABASE:-mantis_main}
      MYSQL_USER: ${MYSQL_USER:?C3: MYSQL_USER missing}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD:?C3: MYSQL_PASSWORD missing}
      # Charset para soporte completo de emojis WhatsApp
      MYSQL_CHARSET: utf8mb4
      MYSQL_COLLATION: utf8mb4_unicode_ci
      # C4: Identificación del tenant en variables de entorno
      TENANT_ID: ${TENANT_ID:?C4: TENANT_ID missing}

    # C3: MySQL NO tiene puertos expuestos al exterior
    # El binding es SOLO dentro de la red Docker interna.
    # Para acceder desde VPS1/VPS3: usar SSH tunnel (ver 00-INDEX.md)
    # ports: []   ← intencionalmente vacío — NO descomentar jamás

    command:
      - "--default-authentication-plugin=mysql_native_password"
      - "--character-set-server=utf8mb4"
      - "--collation-server=utf8mb4_unicode_ci"
      # C1/C2: Optimización para 4GB RAM (ver mysql-optimization-4gb-ram.md)
      - "--innodb_buffer_pool_size=768M"    # 75% de mem_limit
      - "--innodb_log_file_size=128M"
      - "--innodb_flush_method=O_DIRECT"
      - "--max_connections=80"              # C1: 80 × 10MB = 800MB máximo
      - "--sort_buffer_size=2M"             # C1: No usar default 8MB
      - "--read_buffer_size=1M"
      - "--join_buffer_size=2M"
      - "--tmp_table_size=32M"
      - "--max_heap_table_size=32M"
      # C5: Slow query log para auditoría
      - "--slow_query_log=ON"
      - "--slow_query_log_file=/var/log/mysql/slow.log"
      - "--long_query_time=2"
      # C8: Logs de error estructurados
      - "--log-error=/var/log/mysql/error.log"
      # C3: Solo escuchar en todas las interfaces de la red interna
      # (Qdrant y EspoCRM necesitan conectarse por nombre de servicio Docker)
      - "--bind-address=0.0.0.0"
      # ↑ Nota: bind 0.0.0.0 aquí es SEGURO porque no hay `ports:` definidos.
      #   Significa "escuchar en la red Docker interna" no en internet.

    volumes:
      - mysql-data:/var/lib/mysql
      - mysql-logs:/var/log/mysql

    healthcheck:
      test:
        - "CMD"
        - "mysqladmin"
        - "ping"
        - "-h"
        - "localhost"
        - "-u"
        - "root"
        - "-p${MYSQL_ROOT_PASSWORD}"
      interval: 15s
      timeout: 5s
      retries: 5
      start_period: 120s   # MySQL tarda en inicializar la primera vez

  # ─────────────────────────────────────────────────────────────────────────
  # QDRANT — Vector Store para RAG
  # REGLA C3 ABSOLUTA: Puerto 6333/6334 solo en 127.0.0.1
  # VPS1/VPS3 acceden mediante túnel SSH.
  #
  # Para junior: Qdrant es como una biblioteca especializada que guarda
  # el "significado" de los documentos. n8n en VPS1 le pregunta
  # "¿qué documentos son parecidos a esta pregunta?"
  # Como es una biblioteca interna, nadie de afuera puede entrar.
  # ─────────────────────────────────────────────────────────────────────────
  qdrant:
    image: qdrant/qdrant:latest
    container_name: mantis-qdrant
    <<: *restart-default
    <<: *networks-default
    logging: *logging-default

    # C1: 1GB para KVM1 — Qdrant carga índices HNSW en RAM
    mem_limit: 1024m
    mem_reservation: 512m
    memswap_limit: 1024m
    cpus: "0.25"
    pids_limit: 100

    environment:
      # C4: tenant_id como label de colección
      TENANT_ID: ${TENANT_ID:?C4: TENANT_ID missing}
      # C3: API Key desde env
      QDRANT__SERVICE__API_KEY: ${QDRANT_API_KEY:?C3: QDRANT_API_KEY missing}
      # C1/C2: Límites de rendimiento
      QDRANT__SERVICE__MAX_REQUEST_SIZE_MB: "10"
      QDRANT__STORAGE__PERFORMANCE__MAX_SEARCH_THREADS: "2"  # C2: 2 threads máximo KVM1

    # C3: Qdrant expuesto SOLO en localhost del VPS (no en internet)
    # VPS1/VPS3 usan SSH tunnel: ssh -L 6333:localhost:6333 user@vps2
    ports:
      - "127.0.0.1:6333:6333"   # REST API — solo localhost VPS2
      - "127.0.0.1:6334:6334"   # gRPC      — solo localhost VPS2
    # ↑ IMPORTANTE: 127.0.0.1 significa que SOLO el propio VPS2 puede
    #   acceder a estos puertos directamente. VPS1/VPS3 usan túnel SSH.

    volumes:
      - qdrant-storage:/qdrant/storage
      - qdrant-snapshots:/qdrant/snapshots

    healthcheck:
      test:
        - "CMD-SHELL"
        - "curl -sf -H 'api-key: ${QDRANT_API_KEY}' http://localhost:6333/health || exit 1"
      <<: *healthcheck-base

  # ─────────────────────────────────────────────────────────────────────────
  # ESPOCRM — CRM (Única interfaz pública de VPS2)
  # Accesible por clientes finales via HTTPS
  # Conecta a MySQL dentro de la red Docker interna
  # ─────────────────────────────────────────────────────────────────────────
  espocrm:
    image: espocrm/espocrm:latest
    container_name: mantis-espocrm
    <<: *restart-default
    <<: *networks-default
    logging: *logging-default

    # C1: 512MB para KVM1 — PHP-FPM
    mem_limit: 512m
    mem_reservation: 256m
    memswap_limit: 512m
    cpus: "0.25"
    pids_limit: 150         # PHP-FPM spawna worker processes

    depends_on:
      mysql:
        condition: service_healthy
      traefik:
        condition: service_healthy

    environment:
      # C3: Credenciales desde env
      ESPOCRM_DATABASE_HOST: "mysql"        # Nombre del servicio Docker (red interna)
      ESPOCRM_DATABASE_PORT: "3306"
      ESPOCRM_DATABASE_NAME: ${ESPOCRM_DB_NAME:-espocrm_main}
      ESPOCRM_DATABASE_USER: ${ESPOCRM_DB_USER:?C3: ESPOCRM_DB_USER missing}
      ESPOCRM_DATABASE_PASSWORD: ${ESPOCRM_DB_PASSWORD:?C3: ESPOCRM_DB_PASSWORD missing}
      ESPOCRM_ADMIN_USERNAME: ${ESPOCRM_ADMIN_USER:?C3: ESPOCRM_ADMIN_USER missing}
      ESPOCRM_ADMIN_PASSWORD: ${ESPOCRM_ADMIN_PASSWORD:?C3: ESPOCRM_ADMIN_PASSWORD missing}
      ESPOCRM_SITE_URL: "https://${CRM_DOMAIN:?C3: CRM_DOMAIN missing}"
      # C4: tenant_id en la BD de EspoCRM
      TENANT_ID: ${TENANT_ID:?C4: TENANT_ID missing}
      # PHP performance
      PHP_MEMORY_LIMIT: "450M"
      PHP_MAX_EXECUTION_TIME: "30"          # C2: 30s máximo (API-RELIABILITY)
      PHP_UPLOAD_MAX_FILESIZE: "50M"
      PHP_POST_MAX_SIZE: "50M"
      # C8: Logs estructurados
      ESPOCRM_CONFIG_LOG_LEVEL: "WARNING"

    volumes:
      - espocrm-data:/var/www/html/data
      - espocrm-custom:/var/www/html/custom

    labels:
      - "traefik.enable=true"
      # EspoCRM es el ÚNICO router público en VPS2
      - "traefik.http.routers.espocrm.rule=Host(`${CRM_DOMAIN}`)"
      - "traefik.http.routers.espocrm.tls.certresolver=letsencrypt"
      - "traefik.http.services.espocrm.loadbalancer.server.port=80"
      - "traefik.http.routers.espocrm.middlewares=espocrm-ratelimit,espocrm-headers"
      # C7: Rate limiting — protección contra scraping / brute force
      - "traefik.http.middlewares.espocrm-ratelimit.ratelimit.average=60"
      - "traefik.http.middlewares.espocrm-ratelimit.ratelimit.burst=30"
      - "traefik.http.middlewares.espocrm-ratelimit.ratelimit.period=1m"
      # C3: Security headers
      - "traefik.http.middlewares.espocrm-headers.headers.stsSeconds=31536000"
      - "traefik.http.middlewares.espocrm-headers.headers.stsIncludeSubdomains=true"
      - "traefik.http.middlewares.espocrm-headers.headers.contentTypeNosniff=true"
      - "traefik.http.middlewares.espocrm-headers.headers.browserXssFilter=true"
      - "traefik.http.middlewares.espocrm-headers.headers.customFrameOptionsValue=SAMEORIGIN"
      # C4: label de tenant
      - "mantis.tenant=${TENANT_ID}"
      - "mantis.service=espocrm"

    healthcheck:
      test:
        - "CMD-SHELL"
        - "curl -sf http://localhost:80/ | grep -q 'EspoCRM' || exit 1"
      interval: 30s
      timeout: 15s
      retries: 3
      start_period: 180s    # EspoCRM tarda más en arrancar la primera vez

  # ─────────────────────────────────────────────────────────────────────────
  # OTEL COLLECTOR — Observabilidad C8
  # ─────────────────────────────────────────────────────────────────────────
  otel-collector:
    image: otel/opentelemetry-collector-contrib:latest
    container_name: mantis-vps2-otel
    <<: *restart-default
    <<: *networks-default
    logging: *logging-default

    mem_limit: 96m
    mem_reservation: 48m
    memswap_limit: 96m
    cpus: "0.07"
    pids_limit: 50

    environment:
      OTEL_TRACES_ENDPOINT: ${OTEL_TRACES_ENDPOINT:-}
      OTEL_METRICS_ENDPOINT: ${OTEL_METRICS_ENDPOINT:-}
      OTEL_LOGS_ENDPOINT: ${OTEL_LOGS_ENDPOINT:-}
      OTEL_AUTH_TOKEN: ${OTEL_AUTH_TOKEN:-}
      TENANT_ID: ${TENANT_ID:?C4: TENANT_ID missing}
      ENVIRONMENT: ${ENVIRONMENT:-production}

    volumes:
      - ./otel-collector-config.yml:/etc/otelcol-contrib/config.yaml:ro

    ports:
      - "127.0.0.1:4317:4317"
      - "127.0.0.1:4318:4318"

    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:13133/healthz"]
      <<: *healthcheck-base

# ─────────────────────────────────────────────────────────────────────────────
# RED INTERNA VPS2
# ─────────────────────────────────────────────────────────────────────────────
networks:
  mantis-internal-vps2:
    driver: bridge
    name: mantis-internal-vps2
    driver_opts:
      com.docker.network.bridge.enable_icc: "false"
      com.docker.network.bridge.enable_ip_masquerade: "true"
    ipam:
      driver: default
      config:
        - subnet: "172.21.0.0/24"   # Subnet diferente a VPS1 (172.20.0.0/24)

# ─────────────────────────────────────────────────────────────────────────────
# VOLÚMENES
# ─────────────────────────────────────────────────────────────────────────────
volumes:
  mysql-data:
    name: "mantis-mysql-data-${TENANT_ID:-default}"
    labels:
      mantis.tenant: "${TENANT_ID:-default}"
      mantis.service: "mysql"
      mantis.backup: "daily"       # C5: backup diario obligatorio
  mysql-logs:
    name: "mantis-mysql-logs-${TENANT_ID:-default}"
    labels:
      mantis.tenant: "${TENANT_ID:-default}"
      mantis.backup: "weekly"
  qdrant-storage:
    name: "mantis-qdrant-storage-${TENANT_ID:-default}"
    labels:
      mantis.tenant: "${TENANT_ID:-default}"
      mantis.service: "qdrant"
      mantis.backup: "daily"       # C5: snapshots de vectores
  qdrant-snapshots:
    name: "mantis-qdrant-snapshots-${TENANT_ID:-default}"
    labels:
      mantis.tenant: "${TENANT_ID:-default}"
      mantis.backup: "weekly"
  espocrm-data:
    name: "mantis-espocrm-data-${TENANT_ID:-default}"
    labels:
      mantis.tenant: "${TENANT_ID:-default}"
      mantis.service: "espocrm"
      mantis.backup: "daily"
  espocrm-custom:
    name: "mantis-espocrm-custom-${TENANT_ID:-default}"
    labels:
      mantis.tenant: "${TENANT_ID:-default}"
      mantis.backup: "weekly"
  traefik-certs-vps2:
    name: "mantis-traefik-certs-vps2"
    labels:
      mantis.service: "traefik"
      mantis.backup: "daily"
```

---

## 📁 Override KVM2 — Scale-Up VPS2

```yaml
# 05-CONFIGURATIONS/docker-compose/vps2-crm-qdrant.kvm2.override.yml
# Uso: docker compose -f vps2-crm-qdrant.yml -f vps2-crm-qdrant.kvm2.override.yml up -d

services:
  mysql:
    mem_limit: 2048m
    mem_reservation: 1024m
    memswap_limit: 2048m
    cpus: "0.60"
    command:
      - "--default-authentication-plugin=mysql_native_password"
      - "--character-set-server=utf8mb4"
      - "--collation-server=utf8mb4_unicode_ci"
      # KVM2: buffer pool más grande = más datos en RAM = queries más rápidas
      - "--innodb_buffer_pool_size=1500M"
      - "--innodb_log_file_size=256M"
      - "--innodb_flush_method=O_DIRECT"
      - "--max_connections=150"
      - "--innodb_buffer_pool_instances=2"
      - "--sort_buffer_size=4M"
      - "--slow_query_log=ON"
      - "--slow_query_log_file=/var/log/mysql/slow.log"
      - "--long_query_time=1"

  qdrant:
    mem_limit: 2048m
    mem_reservation: 1024m
    memswap_limit: 2048m
    cpus: "0.70"
    environment:
      QDRANT__STORAGE__PERFORMANCE__MAX_SEARCH_THREADS: "4"   # KVM2: 4 threads

  espocrm:
    mem_limit: 1024m
    mem_reservation: 512m
    memswap_limit: 1024m
    cpus: "0.40"
    environment:
      PHP_MEMORY_LIMIT: "900M"

  otel-collector:
    mem_limit: 192m
    mem_reservation: 96m
    cpus: "0.10"
```

---

## 🔑 Variables de Entorno — Template VPS2

```bash
# 05-CONFIGURATIONS/environment/.env.vps2.example
# ==============================================================================
# MANTIS AGENTIC — VPS2 Environment Variables
# NUNCA commitear con valores reales.
# ==============================================================================

# ── C4: Identidad ────────────────────────────────────────────────────────────
TENANT_ID=restaurante_001

# ── C3: Dominio del CRM (único acceso público de VPS2) ───────────────────────
CRM_DOMAIN=crm.tudominio.com.br
ACME_EMAIL=admin@tudominio.com.br

# ── C3: MySQL ────────────────────────────────────────────────────────────────
MYSQL_ROOT_PASSWORD=GENERAR_openssl_rand_-hex_32
MYSQL_DATABASE=mantis_main
MYSQL_USER=mantis_app
MYSQL_PASSWORD=GENERAR_openssl_rand_-hex_24

# ── C3: EspoCRM ──────────────────────────────────────────────────────────────
ESPOCRM_DB_NAME=espocrm_main
ESPOCRM_DB_USER=espocrm_user
ESPOCRM_DB_PASSWORD=GENERAR_openssl_rand_-hex_24
ESPOCRM_ADMIN_USER=admin
ESPOCRM_ADMIN_PASSWORD=CAMBIAR_CONTRASEÑA_FUERTE

# ── C3: Qdrant ───────────────────────────────────────────────────────────────
QDRANT_API_KEY=GENERAR_openssl_rand_-hex_32

# ── C3: Traefik Dashboard ────────────────────────────────────────────────────
TRAEFIK_DASHBOARD_AUTH=admin:$$2y$$...   # htpasswd -nB admin
TRAEFIK_LOG_LEVEL=warn

# ── C8: Observabilidad ───────────────────────────────────────────────────────
OTEL_TRACES_ENDPOINT=
OTEL_METRICS_ENDPOINT=
OTEL_LOGS_ENDPOINT=
OTEL_AUTH_TOKEN=
ENVIRONMENT=production
```

---

## ✅ Tabla de Validación VPS2 (C5)

| # | Check | Constraint | Comando | ✅ Deberías ver | ❌ Si ves esto | Solución |
|---|---|---|---|---|---|---|
| 1 | MySQL sin puertos públicos | C3 | `grep -A3 'mysql:' vps2-crm-qdrant.yml \| grep 'ports'` | Bloque `ports:` vacío o ausente | `0.0.0.0:3306` | Eliminar el puerto público de MySQL INMEDIATAMENTE |
| 2 | Qdrant solo en 127.0.0.1 | C3 | `grep '6333' vps2-crm-qdrant.yml` | `127.0.0.1:6333:6333` | `0.0.0.0:6333` o solo `6333:6333` | Cambiar binding a `127.0.0.1:6333:6333` |
| 3 | Límites C1/C2 declarados | C1/C2 | `grep -cE 'mem_limit\|cpus\|pids_limit' vps2-crm-qdrant.yml` | `>= 18` | `< 18` | Agregar límites a todos los servicios |
| 4 | innodb_buffer_pool ≤ 75% mem_limit | C1 | `grep 'innodb_buffer_pool_size' vps2-crm-qdrant.yml` | `768M` (KVM1) | `> 768M con mem_limit 1024m` | Reducir buffer pool a max 75% del mem_limit |
| 5 | EspoCRM conecta a MySQL por nombre interno | C3 | `grep 'DATABASE_HOST' vps2-crm-qdrant.yml` | `mysql` (nombre servicio Docker) | `IP pública` o `localhost` | Usar nombre del servicio Docker `mysql` |
| 6 | Subnet diferente a VPS1/VPS3 | C7 | `grep 'subnet' vps2-crm-qdrant.yml` | `172.21.0.0/24` | `172.20.0.0/24` (colisión con VPS1) | Cada VPS usa subnet diferente |
| 7 | Healthcheck en MySQL con tiempo largo | C7 | `grep -A5 'healthcheck' vps2-crm-qdrant.yml \| grep 'start_period'` | `120s` o más | `< 60s` | MySQL necesita tiempo para inicializar tablespaces |
| 8 | Traefik habilitado solo para EspoCRM | C3 | `grep 'traefik.enable=true' vps2-crm-qdrant.yml \| wc -l` | `2` (traefik + espocrm) | `> 2` | MySQL, Qdrant NO deben tener `traefik.enable=true` |
| 9 | tenant_id en todos los servicios | C4 | `grep -c 'TENANT_ID' vps2-crm-qdrant.yml` | `>= 5` | `< 5` | Agregar `TENANT_ID: ${TENANT_ID:?C4}` a cada servicio |
| 10 | Backup labels en volúmenes | C5 | `grep -c 'mantis.backup' vps2-crm-qdrant.yml` | `>= 5` | `0` | Agregar labels de backup a todos los volúmenes |

---

## 🔗 Referencias Cruzadas

- [[05-CONFIGURATIONS/docker-compose/00-INDEX.md]] — Índice de red inter-VPS
- [[02-SKILLS/INFRASTRUCTURA/espocrm-setup.md]] — Setup detallado de EspoCRM
- [[02-SKILLS/INFRASTRUCTURA/ssh-tunnels-remote-services.md]] — Configurar acceso desde VPS1/VPS3
- [[02-SKILLS/BASE DE DATOS-RAG/mysql-optimization-4gb-ram.md]] — Tuning MySQL C1
- [[02-SKILLS/BASE DE DATOS-RAG/qdrant-rag-ingestion.md]] — Ingesta RAG en Qdrant
- [[02-SKILLS/SEGURIDAD/backup-encryption.md]] — Backup cifrado MySQL + Qdrant

<!-- ai:file-end marker — do not remove -->
Versión 1.0.0 — 2026-04-13 — Mantis-AgenticDev
