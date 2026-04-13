---
title: "vps3-n8n-uazapi — Docker Compose VPS3 (Failover)"
version: "1.0.0"
canonical_path: "05-CONFIGURATIONS/docker-compose/vps3-n8n-uazapi.yml"
status: "PRODUCTION_READY"
constraints_mapped: ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8"]
target_servers:
  kvm1: { vcpu: 1, ram_gb: 4, nvme_gb: 50, bandwidth_tb: 4 }
  kvm2: { vcpu: 2, ram_gb: 8, nvme_gb: 100, bandwidth_tb: 8 }
services: ["n8n", "uazapi", "redis", "traefik", "otel-collector"]
network_role: "SPOKE — Failover de VPS1. Misma arquitectura, tenant_ids diferentes o modo standby."
diferencias_vs_vps1:
  - "Puerto n8n expuesto en dominio diferente: n8n-backup.dominio.com"
  - "Subnet Docker: 172.22.0.0/24 (no colisiona con VPS1:172.20 ni VPS2:172.21)"
  - "Redis DB: misma estructura pero instancia independiente"
  - "n8n puede correr workflows de otros tenants o actuar como standby"
  - "uazapi puede conectar números WhatsApp secundarios"
validation_command: |
  grep -cE 'mem_limit|cpus|pids_limit' vps3-n8n-uazapi.yml
  # Esperado: >= 15 líneas con límites definidos
last_updated: "2026-04-13"
related_files:
  - "[[05-CONFIGURATIONS/docker-compose/00-INDEX.md]]"
  - "[[05-CONFIGURATIONS/docker-compose/vps1-n8n-uazapi.yml]]"
  - "[[05-CONFIGURATIONS/docker-compose/vps2-crm-qdrant.yml]]"
  - "[[05-CONFIGURATIONS/validation/validate-skill-integrity.sh]]"
  - "[[02-SKILLS/INFRASTRUCTURA/vps-interconnection.md]]"
  - "[[02-SKILLS/INFRASTRUCTURA/ssh-tunnels-remote-services.md]]"
  - "[[02-SKILLS/INFRAESTRUCTURA/n8n-concurrency-limiting.md]]"
  - "[[02-SKILLS/BASE DE DATOS-RAG/redis-session-management.md]]"
  - "[[01-RULES/07-SCALABILITY-RULES.md]]"
---

# 🔄 VPS3 — Docker Compose: n8n + uazapi + Redis (Failover/Backup)

> **Rol de este VPS en la red MANTIS:** Spoke secundario.
> Arquitectura idéntica a VPS1 pero opera de forma independiente.
> Usa los mismos MySQL y Qdrant de VPS2, accediendo via SSH tunnel.
> Modos de uso: failover activo, tenants adicionales, o standby caliente.

---

## 📐 Fundamentos para Juniors — ¿Por qué existe VPS3?

```
Escenario sin VPS3: Si VPS1 cae...
  WhatsApp de TODOS los clientes → sin respuesta
  n8n → offline
  Resultado: clientes enojados, reputación dañada

Escenario con VPS3:
  VPS1 cae →
  DNS failover o redirección manual →
  VPS3 levanta los mismos workflows →
  Clientes ven degradación máxima de 5 minutos
  Resultado: servicio recuperado, reputación intacta
```

**Tres modos de operación de VPS3:**

| Modo | Cuándo usar | Configuración |
|---|---|---|
| **Failover pasivo** | VPS3 apagado, se enciende solo si VPS1 cae | `docker compose up` manual ante fallo |
| **Tenants adicionales** | VPS1 lleno (3 clientes Full) → VPS3 toma nuevos | TENANT_ID diferente, workflows diferentes |
| **Standby caliente** | VPS3 corriendo con las mismas configuraciones | Mismas env vars, mismo TENANT_ID |

---

## 📊 Distribución de Recursos

### KVM1 (1 vCPU / 4 GB RAM) — Idéntica a VPS1

```
VPS3 KVM1 — 4 GB RAM total
├── n8n            → 1.5 GB RAM  |  0.50 vCPU
├── uazapi         → 0.75 GB RAM |  0.20 vCPU
├── Redis          → 0.25 GB RAM |  0.10 vCPU
├── Traefik        → 0.12 GB RAM |  0.08 vCPU
├── OTEL Collector → 0.12 GB RAM |  0.07 vCPU
└── OS / kernel    → 0.50 GB RAM |  0.05 vCPU
   TOTAL           → 3.24 GB     |  1.00 vCPU  ✅ C1/C2
```

### KVM2 (2 vCPU / 8 GB RAM)

```
VPS3 KVM2 — 8 GB RAM total
├── n8n            → 3.00 GB RAM  |  1.00 vCPU
├── uazapi         → 1.50 GB RAM  |  0.40 vCPU
├── Redis          → 0.50 GB RAM  |  0.20 vCPU
├── Traefik        → 0.25 GB RAM  |  0.15 vCPU
├── OTEL Collector → 0.25 GB RAM  |  0.15 vCPU
└── OS / kernel    → 1.00 GB RAM  |  0.10 vCPU
   TOTAL           → 6.50 GB      |  2.00 vCPU  ✅ C1/C2
```

---

## 📁 Archivo Principal — KVM1 (Default)

```yaml
# ==============================================================================
# 05-CONFIGURATIONS/docker-compose/vps3-n8n-uazapi.yml
# VPS3: n8n + uazapi + Redis + Traefik + OTEL Collector (Failover/Tenants adicionales)
# Rol: SPOKE secundario — idéntico a VPS1 con diferencias de red y dominio
# Target: KVM1 (1 vCPU / 4 GB RAM / 50 GB NVMe)  |  Override: kvm2.override.yml
#
# DIFERENCIAS CLAVE vs VPS1:
#   - Subnet Docker: 172.22.0.0/24 (VPS1 usa 172.20.x, VPS2 usa 172.21.x)
#   - Dominio n8n: n8n-backup.${DOMAIN} (configurable a n8n.${DOMAIN2})
#   - Contenedores prefijados con "mantis-vps3-" para distinguir de VPS1
#   - Redis DB independiente (no compartida con VPS1)
#
# Constraints: C1(RAM) C2(CPU) C3(secrets) C4(tenant) C7(resiliencia) C8(logs)
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
  start_period: 60s

x-networks-default: &networks-default
  networks:
    - mantis-internal-vps3

services:

  # ─────────────────────────────────────────────────────────────────────────
  # TRAEFIK — Reverse Proxy + TLS
  # ─────────────────────────────────────────────────────────────────────────
  traefik:
    image: traefik:v3.0
    container_name: mantis-vps3-traefik
    <<: *restart-default
    <<: *networks-default
    logging: *logging-default

    mem_limit: 128m
    mem_reservation: 64m
    memswap_limit: 128m
    cpus: "0.08"
    pids_limit: 100

    ports:
      - "80:80"
      - "443:443"
      - "127.0.0.1:8081:8080"     # Dashboard en 8081 (8080 puede estar ocupado si VPS1 corre en mismo host)

    environment:
      - TRAEFIK_LOG_LEVEL=${TRAEFIK_LOG_LEVEL:-warn}
      - TRAEFIK_CERTIFICATESRESOLVERS_LETSENCRYPT_ACME_EMAIL=${ACME_EMAIL:?C3: ACME_EMAIL missing}

    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - traefik-certs-vps3:/letsencrypt

    command:
      - "--api.insecure=false"
      - "--api.dashboard=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--providers.docker.network=mantis-internal-vps3"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.web.http.redirections.entryPoint.to=websecure"
      - "--entrypoints.web.http.redirections.entryPoint.scheme=https"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.letsencrypt.acme.tlschallenge=true"
      - "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
      - "--entrypoints.websecure.transport.respondingTimeouts.readTimeout=60s"
      - "--entrypoints.websecure.transport.respondingTimeouts.writeTimeout=60s"
      - "--accesslog=true"
      - "--accesslog.format=json"
      - "--log.format=json"
      - "--metrics.prometheus=true"

    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.traefik-vps3.rule=Host(`traefik.${DOMAIN_VPS3:?C3: DOMAIN_VPS3 missing}`)"
      - "traefik.http.routers.traefik-vps3.tls.certresolver=letsencrypt"
      - "traefik.http.routers.traefik-vps3.middlewares=traefik-auth-vps3"
      - "traefik.http.middlewares.traefik-auth-vps3.basicauth.users=${TRAEFIK_DASHBOARD_AUTH:?C3: TRAEFIK_DASHBOARD_AUTH missing}"

    healthcheck:
      test: ["CMD", "traefik", "healthcheck", "--ping"]
      <<: *healthcheck-base

  # ─────────────────────────────────────────────────────────────────────────
  # REDIS VPS3 — Session Store Independiente
  # Nota: Redis en VPS3 es INDEPENDIENTE del Redis en VPS1.
  # Las sesiones no se comparten entre VPS.
  # Para failover real, las sesiones se perderán al cambiar de VPS
  # (el usuario deberá re-iniciar conversación — comportamiento aceptable).
  # ─────────────────────────────────────────────────────────────────────────
  redis:
    image: redis:7-alpine
    container_name: mantis-vps3-redis
    <<: *restart-default
    <<: *networks-default
    logging: *logging-default

    mem_limit: 256m
    mem_reservation: 128m
    memswap_limit: 256m
    cpus: "0.10"
    pids_limit: 50

    command: >
      redis-server
      --requirepass ${REDIS_PASSWORD:?C3: REDIS_PASSWORD missing}
      --maxmemory 220mb
      --maxmemory-policy volatile-lru
      --save ""
      --appendonly no
      --loglevel warning
      --protected-mode yes
      --bind 0.0.0.0
      --timeout 300
      --tcp-keepalive 60
      --databases 4

    ports:
      - "127.0.0.1:6380:6379"   # Puerto 6380 local (6379 puede estar en uso si VPS1 corre aquí)

    volumes:
      - redis-data-vps3:/data

    healthcheck:
      test: ["CMD", "redis-cli", "-a", "${REDIS_PASSWORD}", "ping"]
      <<: *healthcheck-base
      start_period: 15s

  # ─────────────────────────────────────────────────────────────────────────
  # N8N VPS3 — Orquestador Failover
  # C7: Variable N8N_INSTANCE_ID distingue esta instancia en los logs
  # C4: TENANT_ID puede ser diferente (tenants adicionales) o igual (failover)
  # ─────────────────────────────────────────────────────────────────────────
  n8n:
    image: n8nio/n8n:latest
    container_name: mantis-vps3-n8n
    <<: *restart-default
    <<: *networks-default
    logging: *logging-default

    mem_limit: 1536m
    mem_reservation: 768m
    memswap_limit: 1536m
    cpus: "0.50"
    pids_limit: 150

    depends_on:
      redis:
        condition: service_healthy
      traefik:
        condition: service_healthy

    environment:
      # C3: Credenciales
      N8N_BASIC_AUTH_ACTIVE: "true"
      N8N_BASIC_AUTH_USER: ${N8N_BASIC_AUTH_USER:?C3: N8N_BASIC_AUTH_USER missing}
      N8N_BASIC_AUTH_PASSWORD: ${N8N_BASIC_AUTH_PASSWORD:?C3: N8N_BASIC_AUTH_PASSWORD missing}
      N8N_ENCRYPTION_KEY: ${N8N_ENCRYPTION_KEY:?C3: N8N_ENCRYPTION_KEY missing}
      N8N_USER_MANAGEMENT_JWT_SECRET: ${N8N_JWT_SECRET:?C3: N8N_JWT_SECRET missing}

      # Dominio VPS3 — diferente al de VPS1
      N8N_HOST: ${DOMAIN_VPS3:?C3: DOMAIN_VPS3 missing}
      N8N_PORT: "5678"
      N8N_PROTOCOL: "https"
      WEBHOOK_URL: "https://${DOMAIN_VPS3}/webhook"
      N8N_EDITOR_BASE_URL: "https://${DOMAIN_VPS3}"

      # C7: ID único de instancia — identifica en logs cuál n8n ejecutó qué
      N8N_INSTANCE_ID: "vps3-${TENANT_ID:-default}"

      # BD — SQLite en KVM1 (mismo que VPS1; ver override KVM2 para Postgres)
      DB_TYPE: "sqlite"
      DB_SQLITE_VACUUM_ON_STARTUP: "true"

      # C4: Tenant
      TENANT_ID: ${TENANT_ID:?C4: TENANT_ID missing}

      # C1/C2: Límites operativos
      EXECUTIONS_PROCESS: "main"
      EXECUTIONS_MAX_CONCURRENT: "5"
      EXECUTIONS_DATA_MAX_AGE: "336"
      EXECUTIONS_DATA_PRUNE: "true"
      WEBHOOK_TIMEOUT: "30000"
      NODE_OPTIONS: "--max-old-space-size=1400"

      # Redis VPS3 (local a este VPS)
      QUEUE_BULL_REDIS_HOST: "redis"
      QUEUE_BULL_REDIS_PORT: "6379"
      QUEUE_BULL_REDIS_PASSWORD: ${REDIS_PASSWORD:?C3: REDIS_PASSWORD missing}
      QUEUE_BULL_REDIS_TIMEOUT_THRESHOLD: "10000"

      # C6: Cloud-only inference
      OPENROUTER_API_KEY: ${OPENROUTER_API_KEY:?C3: OPENROUTER_API_KEY missing}

      # ── Conexión a VPS2 (MySQL + Qdrant via SSH tunnel) ────────────────
      # IMPORTANTE: Estos valores son los LOCALES del túnel SSH.
      # El túnel SSH convierte localhost:3306 → VPS2:3306 internamente.
      # Ver 00-INDEX.md sección "Configurar SSH Tunnels" para setup.
      MYSQL_HOST: ${MYSQL_TUNNEL_HOST:-127.0.0.1}   # Local end del túnel
      MYSQL_PORT: ${MYSQL_TUNNEL_PORT:-3306}
      MYSQL_USER: ${MYSQL_USER:?C3: MYSQL_USER missing}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD:?C3: MYSQL_PASSWORD missing}
      MYSQL_DATABASE: ${MYSQL_DATABASE:-mantis_main}

      QDRANT_URL: ${QDRANT_TUNNEL_URL:-http://127.0.0.1:6333}   # Local end del túnel
      QDRANT_API_KEY: ${QDRANT_API_KEY:?C3: QDRANT_API_KEY missing}

      # C8: Logs
      N8N_LOG_LEVEL: ${N8N_LOG_LEVEL:-warn}
      N8N_LOG_OUTPUT: "console"
      N8N_METRICS: "true"
      N8N_METRICS_PREFIX: "mantis_vps3_n8n_"

      N8N_BLOCK_ENV_ACCESS_IN_NODE: "true"
      N8N_VERSION_NOTIFICATIONS_ENABLED: "false"
      N8N_TEMPLATES_ENABLED: "false"
      GENERIC_TIMEZONE: "America/Sao_Paulo"

    volumes:
      - n8n-data-vps3:/home/node/.n8n
      - /etc/localtime:/etc/localtime:ro

    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.n8n-vps3.rule=Host(`${DOMAIN_VPS3}`)"
      - "traefik.http.routers.n8n-vps3.tls.certresolver=letsencrypt"
      - "traefik.http.services.n8n-vps3.loadbalancer.server.port=5678"
      - "traefik.http.routers.n8n-vps3.middlewares=n8n-vps3-ratelimit,n8n-vps3-headers"
      - "traefik.http.middlewares.n8n-vps3-ratelimit.ratelimit.average=100"
      - "traefik.http.middlewares.n8n-vps3-ratelimit.ratelimit.burst=50"
      - "traefik.http.middlewares.n8n-vps3-ratelimit.ratelimit.period=1m"
      - "traefik.http.middlewares.n8n-vps3-headers.headers.stsSeconds=31536000"
      - "traefik.http.middlewares.n8n-vps3-headers.headers.contentTypeNosniff=true"
      - "traefik.http.middlewares.n8n-vps3-headers.headers.browserXssFilter=true"
      - "mantis.tenant=${TENANT_ID}"
      - "mantis.service=n8n"
      - "mantis.vps=vps3"

    healthcheck:
      test: ["CMD-SHELL", "wget -q --spider http://localhost:5678/healthz || exit 1"]
      <<: *healthcheck-base

  # ─────────────────────────────────────────────────────────────────────────
  # UAZAPI VPS3 — WhatsApp Gateway Secundario
  # Puede conectar números WhatsApp diferentes a los de VPS1
  # ─────────────────────────────────────────────────────────────────────────
  uazapi:
    image: uazapi/uazapi:latest
    container_name: mantis-vps3-uazapi
    <<: *restart-default
    <<: *networks-default
    logging: *logging-default

    mem_limit: 768m
    mem_reservation: 384m
    memswap_limit: 768m
    cpus: "0.20"
    pids_limit: 100

    depends_on:
      redis:
        condition: service_healthy

    environment:
      UAZAPI_TOKEN: ${UAZAPI_TOKEN:?C3: UAZAPI_TOKEN missing}
      UAZAPI_MONGO_DB: ${UAZAPI_MONGO_DB:-uazapi_vps3}
      TENANT_ID: ${TENANT_ID:?C4: TENANT_ID missing}
      UAZAPI_WEBHOOK_URL: "http://n8n:5678/webhook/whatsapp"
      UAZAPI_WEBHOOK_SECRET: ${UAZAPI_WEBHOOK_SECRET:?C3: UAZAPI_WEBHOOK_SECRET missing}
      UAZAPI_REDIS_URL: "redis://:${REDIS_PASSWORD}@redis:6379/1"
      UAZAPI_TIMEOUT: "30000"
      LOG_LEVEL: ${LOG_LEVEL:-warn}
      LOG_FORMAT: "json"
      NODE_OPTIONS: "--max-old-space-size=700"

    volumes:
      - uazapi-sessions-vps3:/app/sessions
      - uazapi-media-vps3:/app/media

    labels:
      - "traefik.enable=false"
      - "mantis.tenant=${TENANT_ID}"
      - "mantis.service=uazapi"
      - "mantis.vps=vps3"

    healthcheck:
      test: ["CMD-SHELL", "wget -q --spider http://localhost:3333/health || exit 1"]
      <<: *healthcheck-base

  # ─────────────────────────────────────────────────────────────────────────
  # OTEL COLLECTOR VPS3
  # ─────────────────────────────────────────────────────────────────────────
  otel-collector:
    image: otel/opentelemetry-collector-contrib:latest
    container_name: mantis-vps3-otel
    <<: *restart-default
    <<: *networks-default
    logging: *logging-default

    mem_limit: 128m
    mem_reservation: 64m
    memswap_limit: 128m
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
# RED — Subnet diferente a VPS1 y VPS2
# ─────────────────────────────────────────────────────────────────────────────
networks:
  mantis-internal-vps3:
    driver: bridge
    name: mantis-internal-vps3
    driver_opts:
      com.docker.network.bridge.enable_icc: "false"
      com.docker.network.bridge.enable_ip_masquerade: "true"
    ipam:
      driver: default
      config:
        - subnet: "172.22.0.0/24"   # VPS1: 172.20 | VPS2: 172.21 | VPS3: 172.22

volumes:
  n8n-data-vps3:
    name: "mantis-n8n-data-vps3-${TENANT_ID:-default}"
    labels:
      mantis.tenant: "${TENANT_ID:-default}"
      mantis.service: "n8n"
      mantis.vps: "vps3"
      mantis.backup: "daily"
  uazapi-sessions-vps3:
    name: "mantis-uazapi-sessions-vps3-${TENANT_ID:-default}"
    labels:
      mantis.tenant: "${TENANT_ID:-default}"
      mantis.vps: "vps3"
      mantis.backup: "daily"
  uazapi-media-vps3:
    name: "mantis-uazapi-media-vps3-${TENANT_ID:-default}"
    labels:
      mantis.tenant: "${TENANT_ID:-default}"
      mantis.vps: "vps3"
      mantis.backup: "weekly"
  redis-data-vps3:
    name: "mantis-redis-data-vps3-${TENANT_ID:-default}"
    labels:
      mantis.tenant: "${TENANT_ID:-default}"
      mantis.vps: "vps3"
      mantis.backup: "none"
  traefik-certs-vps3:
    name: "mantis-traefik-certs-vps3"
    labels:
      mantis.service: "traefik"
      mantis.vps: "vps3"
      mantis.backup: "daily"
```

---

## 📁 Override KVM2 — VPS3

```yaml
# 05-CONFIGURATIONS/docker-compose/vps3-n8n-uazapi.kvm2.override.yml
services:
  n8n:
    mem_limit: 3072m
    mem_reservation: 1536m
    memswap_limit: 3072m
    cpus: "1.00"
    environment:
      EXECUTIONS_MAX_CONCURRENT: "10"
      NODE_OPTIONS: "--max-old-space-size=2800"
      DB_TYPE: "postgresdb"
      DB_POSTGRESDB_HOST: ${DB_HOST:?missing}
      DB_POSTGRESDB_PORT: "5432"
      DB_POSTGRESDB_DATABASE: ${DB_NAME:?missing}
      DB_POSTGRESDB_USER: ${DB_USER:?missing}
      DB_POSTGRESDB_PASSWORD: ${DB_PASSWORD:?missing}
      DB_POSTGRESDB_SSL_ENABLED: "true"
  uazapi:
    mem_limit: 1536m
    mem_reservation: 768m
    memswap_limit: 1536m
    cpus: "0.40"
    environment:
      NODE_OPTIONS: "--max-old-space-size=1400"
  redis:
    mem_limit: 512m
    mem_reservation: 256m
    cpus: "0.20"
    command: >
      redis-server
      --requirepass ${REDIS_PASSWORD}
      --maxmemory 460mb
      --maxmemory-policy volatile-lru
      --save "" --appendonly no --loglevel warning
  otel-collector:
    mem_limit: 256m
    mem_reservation: 128m
    cpus: "0.15"
```

---

## 🔑 Variables de Entorno — Template VPS3

```bash
# 05-CONFIGURATIONS/environment/.env.vps3.example

# ── C4: Identidad ────────────────────────────────────────────────────────────
TENANT_ID=restaurante_001         # Igual a VPS1 si es failover, diferente si son tenants distintos

# ── C3: Dominio VPS3 ─────────────────────────────────────────────────────────
DOMAIN_VPS3=n8n-backup.tudominio.com.br
ACME_EMAIL=admin@tudominio.com.br

# ── C3: n8n ──────────────────────────────────────────────────────────────────
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=CAMBIAR_CONTRASEÑA_FUERTE
N8N_ENCRYPTION_KEY=GENERAR_openssl_rand_-hex_32
N8N_JWT_SECRET=GENERAR_openssl_rand_-hex_32

# ── C3: uazapi ───────────────────────────────────────────────────────────────
UAZAPI_TOKEN=CAMBIAR_TOKEN_FUERTE
UAZAPI_WEBHOOK_SECRET=GENERAR_openssl_rand_-hex_24

# ── C3: Redis VPS3 ───────────────────────────────────────────────────────────
REDIS_PASSWORD=GENERAR_openssl_rand_-hex_24

# ── C6: OpenRouter ───────────────────────────────────────────────────────────
OPENROUTER_API_KEY=sk-or-v1-...

# ── Conexión a VPS2 via SSH Tunnel ───────────────────────────────────────────
# ANTES de iniciar VPS3, configurar los túneles SSH (ver 00-INDEX.md)
# Los túneles convierten acceso local en acceso seguro a VPS2
MYSQL_TUNNEL_HOST=127.0.0.1      # Local end del túnel SSH
MYSQL_TUNNEL_PORT=3307            # Puerto local (3307 evita colisión con MySQL local si lo hay)
MYSQL_USER=mantis_app
MYSQL_PASSWORD=MISMA_QUE_VPS2
MYSQL_DATABASE=mantis_main

QDRANT_TUNNEL_URL=http://127.0.0.1:6334   # Puerto local (6334 evita colisión con 6333)
QDRANT_API_KEY=MISMA_QUE_VPS2

# ── C3: Traefik ──────────────────────────────────────────────────────────────
TRAEFIK_DASHBOARD_AUTH=admin:$$2y$$...
TRAEFIK_LOG_LEVEL=warn

# ── C8: Observabilidad ───────────────────────────────────────────────────────
OTEL_TRACES_ENDPOINT=
OTEL_METRICS_ENDPOINT=
OTEL_LOGS_ENDPOINT=
OTEL_AUTH_TOKEN=
ENVIRONMENT=production
```

---

## ✅ Tabla de Validación VPS3 (C5)

| # | Check | Constraint | Comando | ✅ Deberías ver | ❌ Si ves esto | Solución |
|---|---|---|---|---|---|---|
| 1 | Subnet diferente a VPS1/VPS2 | C7 | `grep 'subnet' vps3-n8n-uazapi.yml` | `172.22.0.0/24` | `172.20` o `172.21` | Cambiar a `172.22.0.0/24` — cada VPS usa subnet diferente |
| 2 | Dominio VPS3 diferente a VPS1 | C7 | `grep 'DOMAIN_VPS3' vps3-n8n-uazapi.yml` | `DOMAIN_VPS3` | `DOMAIN` (sin VPS3) | VPS3 necesita su propio dominio/subdominio |
| 3 | Tunnel vars en n8n | C3 | `grep 'TUNNEL' vps3-n8n-uazapi.yml` | `MYSQL_TUNNEL_HOST`, `QDRANT_TUNNEL_URL` | Ausentes | n8n en VPS3 no puede conectar a VPS2 sin configurar tunnels |
| 4 | Redis puerto 6380 en localhost | C3 | `grep '6380' vps3-n8n-uazapi.yml` | `127.0.0.1:6380:6379` | `0.0.0.0:6379` | Redis solo accesible localmente |
| 5 | N8N_INSTANCE_ID configurado | C8 | `grep 'N8N_INSTANCE_ID' vps3-n8n-uazapi.yml` | `vps3-${TENANT_ID}` | Ausente | Sin ID único, los logs de VPS1 y VPS3 son indistinguibles |
| 6 | Contenedores con prefijo vps3 | C8 | `grep 'container_name' vps3-n8n-uazapi.yml` | `mantis-vps3-*` | `mantis-n8n` (sin vps3) | Colisión de nombres si VPS1 y VPS3 corren en mismo host |
| 7 | Límites RAM/CPU declarados | C1/C2 | `grep -cE 'mem_limit\|cpus\|pids_limit' vps3-n8n-uazapi.yml` | `>= 15` | `< 15` | Agregar límites a todos los servicios |
| 8 | Volúmenes con sufijo vps3 | C7 | `grep -c 'vps3' vps3-n8n-uazapi.yml \| grep volumes` | Todos los volúmenes con `vps3` en el nombre | Sin diferenciación | Evita colisión si VPS1 y VPS3 comparten host durante migración |

---

## 🔗 Referencias Cruzadas

- [[05-CONFIGURATIONS/docker-compose/00-INDEX.md]] — Red inter-VPS y SSH tunnels
- [[05-CONFIGURATIONS/docker-compose/vps1-n8n-uazapi.yml]] — Arquitectura base (idéntica)
- [[02-SKILLS/INFRASTRUCTURA/ssh-tunnels-remote-services.md]] — Cómo conectar VPS3 a MySQL/Qdrant en VPS2
- [[01-RULES/07-SCALABILITY-RULES.md]] — Criterios para agregar tenants a VPS3

<!-- ai:file-end marker — do not remove -->
Versión 1.0.0 — 2026-04-13 — Mantis-AgenticDev
