---
artifact_id: docker-compose-master-agent-mantis
artifact_type: agentic-skill-definition
version: 2.0.0-COMPREHENSIVE
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","V1","V2","V3"]
canonical_path: 05-CONFIGURATIONS/docker-compose/docker-compose-master-agent.md
domain: 05-CONFIGURATIONS
subdomain: docker-compose
agent_role: docker-compose-master
language_lock: es-ES
validation_command: orchestrator-engine.sh --domain docker-compose --strict
tier: 3
immutable: true
requires_human_approval_for_changes: true
audience: ["agentic_assistants"]
human_readable: false
checksum_sha256: "PENDING_GENERATION"
---

# docker-compose-master-agent — Agente Maestro de Orquestación de Contenedores MANTIS v2.0.0

## 1. Resumen Ejecutivo

Soy el agente maestro especialista en **Docker Compose, orquestación de contenedores, construcción de imágenes seguras y despliegue de aplicaciones multi-servicio** del ecosistema MANTIS. Mi responsabilidad abarca la definición, optimización y validación de stacks de servicios en entornos de desarrollo, staging y producción, garantizando que cada contenedor cumpla con las constraints MANTIS (C1‑C8, V1‑V3).

**Alcance dentro del dominio `05-CONFIGURATIONS/docker-compose/`:**
- Archivos `docker-compose.yml` para VPS (vps1, vps2, vps3) y entornos multi-nodo
- Configuraciones de redes, volúmenes, secretos, health checks y políticas de seguridad
- Integración con agentes: `pipelines-master-agent`, `terraform-master-agent`, `postgresql-pgvector-rag-master-agent`
- Validación automatizada de Dockerfiles y stacks con `dockerfile-validator` y `orchestrator-engine.sh`
- Patrones de despliegue: rolling updates, blue-green, canary, feature flags

**Objetivo:** Proporcionar un marco robusto, seguro y reproducible para desplegar todo el ecosistema MANTIS sobre infraestructura VPS auto-gestionada, con mínima intervención manual, máxima observabilidad y trazabilidad completa.

**Principio fundamental:** Este agente es auto-contenido: todas las habilidades, patrones y conocimientos necesarios para resolver tareas de Docker Compose están definidos dentro de este documento. No requiere carga externa de contexto para operar.

## 2. Principios Rectores

| Principio | Descripción | Aplicación en MANTIS |
|-----------|-------------|---------------------|
| **Declarativo y reproducible** | Todo el stack se define en YAML; `docker compose up` reconstruye el entorno completo | Un solo archivo = entorno completo; sin comandos manuales |
| **Seguridad por diseño** | Contenedores sin privilegios, filesystems de solo lectura, capacidades mínimas, secretos nunca en texto plano | `USER nonroot`, `cap_drop: ALL`, `read_only: true`, Docker Secrets |
| **Eficiencia en capas** | Imágenes construidas con multi-stage builds, optimización de caché, `.dockerignore` exhaustivo | Build rápido, imágenes pequeñas, despliegue ágil |
| **Observabilidad** | Health checks profundos, logging rotativo, etiquetas para Prometheus/Grafana | `/health/ready`, `max-size: 10m`, labels `com.mantis.team` |
| **Inmutabilidad de artefactos** | Imágenes versionadas con tags semánticos + SHA; se promueven sin reconstrucción | `myapp:1.2.3-abc123`, promoted via registry, never rebuilt |
| **Rolling updates controlados** | Actualizaciones sin downtime con `update_config` o scripts blue-green | Zero downtime deployments con rollback automático |
| **Cero contexto creciente** | El agente no acumula contexto; pasa rutas, no contenidos | Pipe paths only; context window stays flat |
| **Auto-contención** | Todas las habilidades están definidas en este documento | No external skill loading required |

## 3. Arquitectura de Servicios con Docker Compose

### 3.1 Estructura del Archivo Compose (v2.x+)

```yaml
# Formato moderno: sin campo `version` (Compose v2.40.3+)

services:
  nombre-servicio:
    image: repositorio/imagen:tag@sha256:abc123...  # Pin por digest para inmutabilidad (C1)
    build:
      context: ./ruta
      dockerfile: Dockerfile
      target: production  # Multi-stage build target
      args:
        NODE_ENV: production
    container_name: nombre-contenedor
    restart: unless-stopped
    ports:
      - "127.0.0.1:8080:8080"  # Bind a localhost por defecto (seguridad)
    expose:
      - "8080"  # Solo para comunicación interna entre servicios
    environment:
      - VARIABLE=valor  # No sensibles
    env_file:
      - .env.common  # Variables compartidas
      - .env.${SERVICE}  # Variables específicas
    secrets:
      - db_password  # Sensibles: montar como archivo en /run/secrets
    volumes:
      - tipo:origen:destino:opciones  # Named volumes preferidos para persistencia
    networks:
      - red-frontend
      - red-backend
    depends_on:
      otro-servicio:
        condition: service_healthy  # Esperar health check, no solo inicio
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health/ready"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s  # Tiempo para inicialización
    logging:
      driver: json-file
      options:
        max-size: "10m"  # Rotación de logs (C8)
        max-file: "3"
    deploy:
      resources:
        limits:
          cpus: '2'  # Límites de recursos (C1/C2)
          memory: 2G
        reservations:
          cpus: '0.5'
          memory: 512M
      update_config:
        parallelism: 1  # Rolling update: 1 a la vez
        delay: 10s
        failure_action: rollback  # Rollback automático (C7)
    cap_drop:
      - ALL  # Drop todas las capacidades (seguridad)
    cap_add:
      - NET_BIND_SERVICE  # Solo si puerto < 1024
    security_opt:
      - no-new-privileges:true  # Prevenir escalada de privilegios
    read_only: true  # Filesystem de solo lectura
    tmpfs:
      - /tmp:noexec,nosuid,size=64M  # Temporal en memoria
    user: "1001:1001"  # Ejecutar como non-root

networks:
  red-frontend:
    driver: bridge
  red-backend:
    driver: bridge
    internal: true  # Sin acceso a Internet (aislamiento)

volumes:
  volumen-datos:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /mnt/external  # Bind a volumen externo si es necesario

secrets:
  db_password:
    file: ./secrets/db_password.txt  # Montar como archivo, no env var
```

### 3.2 Patrones de Definición de Servicios

#### Patrón 1: Aplicación Full-Stack (Frontend + Backend + DB + Caché)

```yaml
services:
  proxy:
    image: nginx:alpine@sha256:abc123...
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    networks:
      - public
    depends_on:
      - backend
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s

  frontend:
    build:
      context: ./frontend
      target: production
    expose:
      - "3000"
    environment:
      - API_URL=http://backend:4000
      - NODE_ENV=production
    networks:
      - public
    healthcheck:
      test: ["CMD", "wget", "--spider", "http://localhost:3000/health"]
      interval: 30s
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 512M

  backend:
    build:
      context: ./backend
      target: production
    expose:
      - "4000"
    environment:
      - DATABASE_URL=postgresql://postgres:${DB_PASSWORD}@db:5432/mantis
      - REDIS_URL=redis://cache:6379
    networks:
      - public
      - private
    depends_on:
      db:
        condition: service_healthy
      cache:
        condition: service_started
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:4000/health/ready"]
      interval: 30s
      timeout: 5s
      retries: 3
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 1G

  db:
    image: postgres:15-alpine@sha256:def456...
    container_name: mantis-db
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password  # Secret como archivo
      POSTGRES_DB: mantis
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    networks:
      - private
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped
    secrets:
      - db_password
    deploy:
      resources:
        limits:
          memory: 2G

  cache:
    image: redis:7-alpine@sha256:ghi789...
    networks:
      - private
    command: redis-server --appendonly yes
    volumes:
      - redis-data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
    restart: unless-stopped

networks:
  public:
    driver: bridge
  private:
    driver: bridge
    internal: true  # Aislamiento: sin acceso externo

volumes:
  postgres-data:
    driver: local
  redis-data:
    driver: local

secrets:
  db_password:
    file: ./secrets/db_password.txt  # Archivo externo, no commiteado
```

#### Patrón 2: Microservicios con Proxy Inverso y Mensajería

```yaml
services:
  traefik:
    image: traefik:v2.10@sha256:abc123...
    command:
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--entrypoints.web.address=:80"
    ports:
      - "80:80"
      - "8080:8080"  # Dashboard (solo desarrollo)
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - edge
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.api.rule=Host(`traefik.local`)"

  auth-svc:
    build: ./services/auth
    expose:
      - "8001"
    environment:
      - DATABASE_URL=postgresql://db:5432/auth_db
      - JWT_SECRET_FILE=/run/secrets/jwt_secret
    networks:
      - edge
      - internal
    depends_on:
      db:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8001/health"]
      interval: 30s
    secrets:
      - jwt_secret

  user-svc:
    build: ./services/user
    expose:
      - "8002"
    environment:
      - AUTH_SERVICE_URL=http://auth-svc:8001
      - DATABASE_URL=postgresql://db:5432/user_db
    networks:
      - edge
      - internal
    depends_on:
      - auth-svc
      - db
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8002/health"]
      interval: 30s

  db:
    image: postgres:15-alpine@sha256:def456...
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - internal
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
    secrets:
      - db_password

  rabbitmq:
    image: rabbitmq:3-management-alpine@sha256:jkl012...
    environment:
      RABBITMQ_DEFAULT_USER: admin
      RABBITMQ_DEFAULT_PASS_FILE: /run/secrets/rabbit_password
    volumes:
      - rabbitmq-data:/var/lib/rabbitmq
    networks:
      - internal
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "ping"]
      interval: 30s
    secrets:
      - rabbit_password

networks:
  edge:
    driver: bridge
  internal:
    driver: bridge
    internal: true  # Sin acceso a Internet

volumes:
  db-data:
  rabbitmq-data:

secrets:
  db_password:
    file: ./secrets/db_password.txt
  jwt_secret:
    file: ./secrets/jwt_secret.txt
  rabbit_password:
    file: ./secrets/rabbit_password.txt
```

### 3.3 Estrategias de Red y Comunicación

| Estrategia | Configuración | Caso de Uso |
|------------|--------------|-------------|
| **Red bridge por defecto** | Sin configuración explícita | Desarrollo, servicios que se comunican entre sí |
| **Redes personalizadas** | `networks: { frontend: {}, backend: { internal: true } }` | Aislamiento: frontend público, backend privado |
| **Red interna (`internal: true`)** | `driver: bridge, internal: true` | Bases de datos, colas de mensajes: sin acceso externo |
| **Alias de red** | `networks: { backend: { aliases: [api-v1, api.internal] } }` | Múltiples nombres para un servicio (versionado) |
| **Red `host`** | `network_mode: host` | Casos extremos de rendimiento (evitar por seguridad) |
| **Network isolation por tenant** | Redes separadas por tenant_id | Multi-tenancy con aislamiento de datos (V1) |

**Reglas de comunicación:**
- Los servicios se comunican por nombre de servicio (service discovery automático)
- Solo los servicios de borde (proxy, frontend) exponen puertos al host
- El resto usa `expose` para comunicación interna entre redes
- `depends_on` con `condition: service_healthy` garantiza orden de inicio seguro

### 3.4 Volúmenes y Persistencia

```yaml
volumes:
  # Named volume (preferido para datos persistentes)
  postgres-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /mnt/external/postgres  # Bind a volumen externo si es necesario

  # tmpfs para datos temporales en memoria
  cache-tmp:
    driver: local
    driver_opts:
      type: tmpfs
      device: tmpfs
      o: "size=100M,uid=1001"

  # External volume (creado fuera de Compose)
  shared-storage:
    external: true
    name: mantis-shared-nfs

services:
  app:
    volumes:
      # Named volume para persistencia
      - postgres-data:/var/lib/postgresql/data
      
      # Bind mount para configuración de solo lectura
      - ./config/app.conf:/etc/app/app.conf:ro
      
      # tmpfs para datos temporales
      - type: tmpfs
        target: /app/cache
        tmpfs:
          size: 100M
      
      # External volume para almacenamiento compartido
      - shared-storage:/mnt/shared:ro
```

**Reglas de volúmenes:**
- Usar named volumes para datos persistentes (bases de datos, logs)
- Bind mounts solo para configuración de solo lectura o desarrollo
- tmpfs para cachés, sesiones, datos efímeros
- External volumes para almacenamiento compartido entre múltiples stacks
- Siempre especificar `--chown` en `COPY` para que los archivos pertenezcan al usuario non-root

### 3.5 Health Checks — Patrones por Tecnología

```yaml
# HTTP/API (Node.js, Python, Go, etc.)
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8080/health/ready"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s

# PostgreSQL
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U postgres -d mantis"]
  interval: 10s
  timeout: 5s
  retries: 5
  start_period: 30s

# Redis
healthcheck:
  test: ["CMD", "redis-cli", "ping"]
  interval: 10s
  timeout: 3s
  retries: 5

# RabbitMQ
healthcheck:
  test: ["CMD", "rabbitmq-diagnostics", "ping"]
  interval: 30s
  timeout: 10s
  retries: 5

# MongoDB
healthcheck:
  test: ["CMD", "mongosh", "--eval", "db.adminCommand('ping')"]
  interval: 10s
  timeout: 5s
  retries: 5

# Custom script (para health checks profundos)
healthcheck:
  test: ["CMD", "node", "/app/healthcheck.js"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 60s
```

**Health check profundo (`/health/ready`):**
```javascript
// Ejemplo Node.js: verificar dependencias reales
app.get('/health/ready', async (req, res) => {
  try {
    await db.authenticate();  // Verificar conexión a DB
    await redis.ping();       // Verificar conexión a cache
    await vectorStore.ping(); // Verificar conexión a pgvector (V1-V3)
    res.status(200).json({ status: 'ok', timestamp: new Date() });
  } catch (err) {
    logger.error('Health check failed:', err);
    res.status(503).json({ status: 'degraded', error: err.message });
  }
});
```

### 3.6 Múltiples Entornos: Development, Staging, Production

**Estructura de archivos:**
```
05-CONFIGURATIONS/docker-compose/
├── compose.yaml              # Base configuration (común a todos)
├── compose.override.yaml     # Development overrides (auto-loaded)
├── compose.staging.yaml      # Staging overrides
├── compose.prod.yaml         # Production overrides
├── .env.example              # Variables requeridas (sin valores)
├── .env.development          # Variables de desarrollo
├── .env.staging              # Variables de staging
├── .env.production           # Variables de producción (no commitear)
└── scripts/
    ├── health-check.sh       # Verificar servicios post-deploy
    ├── deploy.sh             # Script de despliegue
    └── rollback.sh           # Script de rollback
```

**compose.override.yaml (desarrollo):**
```yaml
services:
  backend:
    build:
      target: development  # Multi-stage: usar etapa de desarrollo
    volumes:
      - ./backend:/app     # Hot reload: montar código fuente
      - /app/node_modules  # Preservar node_modules del contenedor
    ports:
      - "4000:4000"        # Exponer puerto para acceso local
      - "9229:9229"        # Debugger de Node.js
    environment:
      - NODE_ENV=development
      - DEBUG=app:*
    command: npm run dev   # Ejecutar en modo desarrollo
```

**compose.prod.yaml (producción):**
```yaml
services:
  backend:
    image: registry.mantis.org/mantis-backend:${VERSION:-latest}  # Imagen pre-construida
    restart: always
    environment:
      - NODE_ENV=production
    deploy:
      replicas: 3  # Escalar a 3 instancias
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
      update_config:
        parallelism: 1  # Rolling update: 1 a la vez
        delay: 10s
        failure_action: rollback  # Rollback automático si falla
      rollback_config:
        parallelism: 1
        delay: 5s
    logging:
      driver: json-file
      options:
        max-size: "10m"  # Rotación de logs
        max-file: "5"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:4000/health/ready"]
      interval: 30s
      timeout: 10s
      retries: 3
```

**Comandos de despliegue por entorno:**
```bash
# Desarrollo (auto-carga compose.override.yaml)
docker compose up -d

# Staging
docker compose -f compose.yaml -f compose.staging.yaml --env-file .env.staging up -d

# Producción
docker compose -f compose.yaml -f compose.prod.yaml --env-file .env.production up -d

# Validar configuración antes de desplegar
docker compose -f compose.yaml -f compose.prod.yaml config --quiet && echo "✅ Configuración válida"
```

### 3.7 Escalado y Perfiles de Servicio

**Escalado manual:**
```bash
# Escalar un servicio a N instancias
docker compose up -d --scale backend=5

# Escalar múltiples servicios
docker compose up -d --scale backend=3 --scale worker=2
```

**Perfiles de servicio (activación condicional):**
```yaml
services:
  app:
    profiles: ["production", "staging"]  # Siempre activo en prod/staging
    # ... configuración ...

  debug-tools:
    profiles: ["development"]  # Solo en desarrollo
    image: debug-tools:latest
    ports:
      - "9229:9229"
    command: npm run debug

  monitoring:
    profiles: ["production"]  # Solo en producción
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
```

**Activar con perfil:**
```bash
# Desarrollo con herramientas de debug
docker compose --profile development up -d

# Producción con monitoreo
docker compose --profile production up -d

# Múltiples perfiles
docker compose --profile production --profile monitoring up -d
```

## 4. Construcción y Optimización de Imágenes

### 4.1 Elección de Imagen Base — Jerarquía 2025

| Imagen Base | Tamaño | Caso de Uso | Seguridad |
|-------------|--------|-------------|-----------|
| **Wolfi/Chainguard** (`cgr.dev/chainguard/*`) | ~50MB | Producción crítica, compliance (SOC2, HIPAA) | ✅ Zero-CVE goal, SBOM incluido, firmado |
| **Alpine** (`alpine:3.19`) | ~7MB | Producción general, tamaño crítico | ✅ Minimal, pero verificar CVEs |
| **Distroless** (`gcr.io/distroless/*`) | ~2MB | Máxima seguridad, sin shell | ✅ Sin shell, solo binarios necesarios |
| **Slim** (`node:20-slim`) | ~200MB | Compatibilidad con Debian, debugging | ⚠️ Más paquetes = más superficie de ataque |
| **Standard** (`node:20`) | ~1GB | Solo desarrollo, nunca producción | ❌ Demasiado grande, muchos CVEs potenciales |

**Reglas estrictas:**
- Nunca usar `:latest` en producción; siempre versión exacta + digest SHA256
- Preferir Wolfi/Chainguard para aplicaciones críticas (zero-CVE goal)
- Usar Alpine para equilibrio tamaño/compatibilidad
- Distroless para máxima seguridad (sin shell, solo runtime)
- Documentar elección de base image en comentarios del Dockerfile

### 4.2 Multi-Stage Builds — Separar Build y Runtime

**Ejemplo Node.js:**
```dockerfile
# ==================== Etapa de Build ====================
FROM node:20-alpine@sha256:abc123... AS builder

WORKDIR /app

# Copiar manifiestos de dependencias primero (optimizar caché)
COPY package*.json ./

# Instalar dependencias (incluyendo dev para build)
RUN npm ci --ignore-scripts

# Copiar código fuente y construir
COPY . .
RUN npm run build

# Eliminar dependencias de desarrollo
RUN npm prune --production

# ==================== Etapa de Producción ====================
FROM cgr.dev/chainguard/node:latest@sha256:def456... AS production

# Crear usuario non-root (seguridad)
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 -G nodejs

WORKDIR /app

# Copiar solo lo necesario para runtime
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/package.json ./

# Cambiar a usuario non-root
USER nodejs

# Health check profundo
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health/ready', (r) => process.exit(r.statusCode === 200 ? 0 : 1))"

EXPOSE 3000

# Usar exec form para manejo correcto de señales
CMD ["node", "dist/index.js"]
```

**Beneficios:**
- Imagen final ~90% más pequeña (sin herramientas de build)
- Mayor seguridad (menos paquetes = menos vulnerabilidades)
- Despliegue más rápido (menor tamaño de descarga)
- Reproducibilidad garantizada (pinned versions + multi-stage)

### 4.3 Orden de Capas y Optimización de Caché

**Regla de oro:** Copiar archivos que cambian menos frecuente primero.

```dockerfile
# ✅ ÓPTIMO: Orden por frecuencia de cambio (menos → más)
FROM node:20-alpine@sha256:abc123...

# 1. Dependencias del sistema (cambian raramente)
RUN apk add --no-cache dumb-init curl

# 2. Crear usuario non-root (cambia raramente)
RUN addgroup -g 1001 -S appuser && adduser -S appuser -u 1001 -G appuser

# 3. Establecer directorio de trabajo
WORKDIR /app

# 4. Copiar manifiestos de dependencias (cambian ocasionalmente)
COPY package*.json ./

# 5. Instalar dependencias (caché si package*.json no cambia)
RUN npm ci --only=production

# 6. Copiar código fuente (cambia frecuentemente)
COPY --chown=appuser:appuser . .

# 7. Cambiar a usuario non-root
USER appuser

CMD ["dumb-init", "node", "index.js"]
```

**❌ ANTI-PATRÓN:** Copiar código antes de dependencias
```dockerfile
# ❌ MALO: Invalida caché en cada cambio de código
FROM node:20-alpine
WORKDIR /app
COPY . .                    # ← Cualquier cambio invalida capas siguientes
RUN npm install             # ← Se reinstala siempre
CMD ["node", "index.js"]
```

### 4.4 `.dockerignore` — Excluir Archivos Innecesarios

```gitignore
# Version control
.git
.gitignore

# Dependencias (se reinstalan en contenedor)
node_modules
.pnpm-store
__pycache__
*.pyc

# Build outputs
dist
build
.next
out
coverage
.nyc_output

# Development files
.env*.local
*.log
logs/
tmp/

# IDE
.idea
.vscode
*.swp
*.swo

# Docker
Dockerfile*
docker-compose*
.docker

# Documentation
*.md
docs/
README.md

# Tests (a menos que se necesiten en contenedor)
__tests__
*.test.ts
*.spec.ts
jest.config.*

# Secrets (NUNCA incluir)
*.key
*.pem
credentials.json
secrets/
```

### 4.5 Reducción de Tamaño de Imagen

**Técnicas efectivas:**
```dockerfile
# ✅ Combinar comandos RUN para reducir capas y limpiar en la misma capa
RUN apk add --no-cache --virtual .build-deps build-base python3 && \
    npm ci --only=production && \
    apk del .build-deps && \
    rm -rf /var/cache/apk/*

# ✅ Usar --no-install-recommends en Alpine/Debian
RUN apk add --no-cache --no-install-recommends curl ca-certificates

# ✅ Eliminar dependencias de build en la misma capa
RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential && \
    npm run build && \
    apt-get remove -y build-essential && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# ✅ Usar npm ci en lugar de npm install (más rápido, determinista)
COPY package*.json ./
RUN npm ci --only=production --ignore-scripts

# ✅ Multi-stage para eliminar herramientas de build de la imagen final
FROM node:20-alpine AS builder
# ... build con herramientas ...
FROM cgr.dev/chainguard/node:latest AS production
COPY --from=builder /app/dist ./dist  # Solo el resultado, no las herramientas
```

### 4.6 Etiquetas y Metadatos para Trazabilidad

```dockerfile
LABEL org.opencontainers.image.source="https://github.com/Mantis-AgenticDev/agentic-infra-docs"
LABEL org.opencontainers.image.description="MANTIS Backend Service"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.revision="${GIT_COMMIT}"
LABEL org.opencontainers.image.created="${BUILD_TIMESTAMP}"
LABEL com.mantis.team="core"
LABEL com.mantis.constraint-mapping="C1,C2,C3,C4,C5,C6,C7,C8,V1,V2,V3"
LABEL com.mantis.validation-command="orchestrator-engine.sh --domain docker-compose --strict"
```

**Beneficios:**
- Trazabilidad completa: commit, versión, timestamp
- Integración con herramientas de monitoreo (Prometheus, Grafana)
- Auditoría de compliance: qué constraints aplica cada imagen
- Debugging rápido: saber exactamente qué está corriendo

## 5. Seguridad en Imágenes y Contenedores

### 5.1 Principio de Mínimo Privilegio

```yaml
services:
  app:
    # Ejecutar como usuario non-root
    user: "1001:1001"
    
    # Drop todas las capacidades, agregar solo las necesarias
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE  # Solo si puerto < 1024
    
    # Filesystem de solo lectura
    read_only: true
    
    # Directorios temporales en memoria (tmpfs)
    tmpfs:
      - /tmp:noexec,nosuid,size=64M
      - /var/run:noexec,nosuid,size=16M
    
    # Prevenir escalada de privilegios
    security_opt:
      - no-new-privileges:true
    
    # Filtrado de syscalls (seccomp)
    security_opt:
      - seccomp=default  # O perfil personalizado
```

**Verificación post-deploy:**
```bash
# Verificar que el contenedor no corre como root
docker exec mantis-app whoami  # Debe retornar: appuser (no root)

# Verificar capacidades
docker exec mantis-app capsh --print  # Debe mostrar: Current: =

# Verificar filesystem de solo lectura
docker exec mantis-app touch /test  # Debe fallar: Read-only file system
```

### 5.2 Gestión de Secretos — Nunca en Texto Plano

**❌ NUNCA hacer esto:**
```yaml
# ❌ MALO: Secret en variable de entorno (visible en docker inspect)
services:
  app:
    environment:
      - DB_PASSWORD=supersecreto123  # ← Expuesto en logs, inspect, etc.

# ❌ MALO: Secret en Dockerfile (queda en historial de capas)
FROM node:20-alpine
ENV API_KEY=abc123  # ← Visible con docker history
```

**✅ CORRECTO: Usar Docker Secrets o archivos montados**
```yaml
# compose.prod.yaml
services:
  app:
    secrets:
      - db_password
      - jwt_secret
    environment:
      - DB_PASSWORD_FILE=/run/secrets/db_password  # Montar como archivo

secrets:
  db_password:
    file: ./secrets/db_password.txt  # Archivo externo, no commiteado
  jwt_secret:
    file: ./secrets/jwt_secret.txt

# En la aplicación: leer desde archivo, no env var
const fs = require('fs');
const DB_PASSWORD = fs.readFileSync('/run/secrets/db_password', 'utf8').trim();
```

**Flujo de trabajo para secrets:**
1. Crear archivo `./secrets/db_password.txt` con el valor (fuera del repo)
2. Agregar `secrets/` a `.gitignore`
3. Definir secret en `compose.prod.yaml` con `file:`
4. Montar como archivo en `/run/secrets/` en el contenedor
5. Leer desde archivo en la aplicación, no desde variable de entorno

### 5.3 Escaneo de Vulnerabilidades — Integración en Pipeline

**Herramientas recomendadas:**
- **Trivy**: Escaneo de imágenes, filesystem, configs
- **Docker Scout**: Integrado en Docker, SBOM, recomendaciones
- **Grype**: Escaneo de SBOM, integración CI/CD
- **hadolint**: Linting de Dockerfiles

**Comandos de escaneo:**
```bash
# Escanear imagen con Trivy
trivy image --severity HIGH,CRITICAL registry.mantis.org/mantis-backend:1.2.3

# Escanear Dockerfile con hadolint
hadolint Dockerfile.prod

# Escanear filesystem con Trivy (buscar secrets)
trivy fs --scanners secret .

# Generar SBOM con Syft
syft registry.mantis.org/mantis-backend:1.2.3 -o spdx-json > sbom.json

# Escanear SBOM con Grype (más rápido que escanear imagen)
grype sbom:sbom.json
```

**Integración en pipeline GitHub Actions:**
```yaml
# .github/workflows/security-scan.yml
name: Security Scan

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Build image
        run: docker build -t mantis-backend:${{ github.sha }} .
      
      - name: Scan with Trivy
        run: |
          trivy image --severity HIGH,CRITICAL --exit-code 1 \
            mantis-backend:${{ github.sha }}
      
      - name: Generate SBOM
        run: syft mantis-backend:${{ github.sha }} -o spdx-json > sbom.json
      
      - name: Upload SBOM artifact
        uses: actions/upload-artifact@v4
        with:
          name: sbom
          path: sbom.json
      
      - name: Scan SBOM with Grype
        run: grype sbom:sbom.json --fail-on high
```

### 5.4 Firmado de Imágenes y Docker Content Trust

**Habilitar Docker Content Trust:**
```bash
# Habilitar verificación de firmas
export DOCKER_CONTENT_TRUST=1

# Generar claves de firma
docker trust key generate mantis-signer

# Agregar firmante a repositorio
docker trust signer add --key mantis-signer.pub mantis-signer registry.mantis.org/mantis-backend

# Push de imagen firmada
docker push registry.mantis.org/mantis-backend:1.2.3

# Pull solo de imágenes firmadas (falla si no está firmada)
docker pull registry.mantis.org/mantis-backend:1.2.3
```

**Verificación de firma:**
```bash
# Verificar firma de imagen
docker trust inspect --pretty registry.mantis.org/mantis-backend:1.2.3

# Verificar SBOM firmado (Chainguard)
cosign download sbom cgr.dev/chainguard/node:latest
```

### 5.5 Cumplimiento CIS Docker Benchmark

**Ejecutar auditoría automática:**
```bash
# Usar docker-bench-security (contenedor)
docker run --rm --net host --pid host --userns host \
  --cap-add audit_control \
  -v /var/lib:/var/lib:ro \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  docker/docker-bench-security

# Revisar reporte y corregir hallazgos
cat output/docker-bench-security.log | grep -E "WARN|INFO"
```

**Hallazgos críticos comunes y soluciones:**
| Hallazgo CIS | Solución |
|--------------|----------|
| **5.4**: No ejecutar como root | Agregar `USER nonroot` en Dockerfile |
| **5.9**: No usar `--privileged` | Drop capacidades con `cap_drop: ALL` |
| **5.12**: No montar Docker socket | Usar Docker-in-Docker o API remota |
| **5.16**: No exponer puertos innecesarios | Bind a `127.0.0.1` o usar redes internas |
| **5.25**: Restringir tráfico entre contenedores | Usar `internal: true` en redes backend |
| **5.31**: No usar `:latest` | Pin versión exacta + digest SHA256 |

## 6. Despliegue y Estrategias de Actualización

### 6.1 Despliegue en VPS con `docker compose`

**Flujo estándar (orquestado por `pipelines-master-agent`):**
```bash
#!/usr/bin/env bash
# scripts/deploy-vps.sh
set -euo pipefail

VPS_HOST="${1:?Usage: deploy-vps.sh <vps-host>}"
COMPOSE_FILE="${2:?Usage: deploy-vps.sh <host> <compose-file>}"
ENV_FILE="${3:-.env.production}"

echo "🔄 Desplegando a $VPS_HOST con $COMPOSE_FILE"

# 1. Copiar archivos al VPS
scp -i ~/.ssh/mantis_deploy \
  compose.yaml $COMPOSE_FILE $ENV_FILE \
  deploy@$VPS_HOST:/opt/mantis/

# 2. Ejecutar despliegue remoto vía SSH
ssh -i ~/.ssh/mantis_deploy deploy@$VPS_HOST bash << 'EOF'
  cd /opt/mantis
  
  # Cargar variables de entorno
  set -a
  [ -f .env.production ] && source .env.production
  set +a
  
  # Validar configuración
  docker compose -f compose.yaml -f '"$COMPOSE_FILE"' config --quiet || exit 1
  
  # Pull de nuevas imágenes (sin reconstruir)
  docker compose -f compose.yaml -f '"$COMPOSE_FILE"' pull
  
  # Detener servicios antiguos (graceful shutdown)
  docker compose -f compose.yaml -f '"$COMPOSE_FILE"' down --timeout 30
  
  # Iniciar nuevos servicios
  docker compose -f compose.yaml -f '"$COMPOSE_FILE"' up -d
  
  # Esperar health checks
  sleep 30
  bash scripts/health-check.sh || exit 1
  
  echo "✅ Despliegue exitoso"
EOF

# 3. Notificar éxito
echo "✅ Despliegue completado en $VPS_HOST"
```

### 6.2 Rolling Updates sin Downtime (Docker Swarm)

**Configuración en `compose.prod.yaml`:**
```yaml
services:
  backend:
    deploy:
      replicas: 3  # Múltiples instancias para zero downtime
      update_config:
        parallelism: 1        # Actualizar 1 instancia a la vez
        delay: 10s            # Esperar 10s entre actualizaciones
        failure_action: rollback  # Rollback automático si falla
        monitor: 60s          # Monitorear 60s antes de continuar
        order: start-first    # Iniciar nueva antes de detener antigua
      rollback_config:
        parallelism: 1
        delay: 5s
        failure_action: pause
        order: stop-first
```

**Comando de actualización:**
```bash
# Actualizar servicio en Swarm
docker service update \
  --image registry.mantis.org/mantis-backend:1.2.4 \
  --update-parallelism 1 \
  --update-delay 10s \
  --update-failure-action rollback \
  mantis-backend
```

### 6.3 Blue-Green Deployment en VPS Simples

**Script `scripts/deploy-blue-green.sh`:**
```bash
#!/usr/bin/env bash
# Blue-Green deployment para VPS sin Swarm
set -euo pipefail

ENVIRONMENT="${1:?Usage: deploy-blue-green.sh <blue|green>}"
VERSION="${2:?Usage: deploy-blue-green.sh <env> <version>}"
COMPOSE_FILE="compose.prod.yaml"

echo "🔄 Desplegando $VERSION a entorno $ENVIRONMENT"

# 1. Preparar directorio del entorno
mkdir -p /opt/mantis/$ENVIRONMENT
cd /opt/mantis/$ENVIRONMENT

# 2. Copiar archivos de configuración
cp /opt/mantis/compose.yaml .
cp /opt/mantis/$COMPOSE_FILE .
cp /opt/mantis/.env.production .

# 3. Desplegar stack en puerto alternativo
export VERSION=$VERSION
export COMPOSE_PROJECT_NAME=mantis-$ENVIRONMENT
export APP_PORT=808$([ "$ENVIRONMENT" = "blue" ] && echo "1" || echo "2")

docker compose -f compose.yaml -f $COMPOSE_FILE up -d

# 4. Esperar rollout y health checks
sleep 30
bash /opt/mantis/scripts/health-check.sh --port $APP_PORT || exit 1

# 5. Switch de tráfico (actualizar proxy inverso)
echo "🔀 Cambiando tráfico a $ENVIRONMENT (puerto $APP_PORT)"
/opt/mantis/scripts/switch-proxy.sh --target $ENVIRONMENT --port $APP_PORT

# 6. Monitoreo post-deploy (5 minutos)
echo "👁️ Monitoreando 5 minutos..."
sleep 300

# 7. Verificar métricas de error
ERROR_RATE=$(curl -sf "http://localhost:9090/api/v1/query?query=sum(rate(http_requests_total{status=~\"5..\"}[5m]))/sum(rate(http_requests_total[5m]))" | jq -r '.data.result[0].value[1]')

if (( $(echo "$ERROR_RATE > 0.01" | bc -l) )); then
  echo "❌ Error rate $ERROR_RATE > 1% — ejecutando rollback"
  /opt/mantis/scripts/switch-proxy.sh --target $([ "$ENVIRONMENT" = "blue" ] && echo "green" || echo "blue")
  exit 1
fi

# 8. Limpieza del entorno anterior (opcional, después de 24h)
# docker compose -f compose.yaml -f $COMPOSE_FILE down

echo "✅ Despliegue exitoso a $ENVIRONMENT"
```

### 6.4 Rollback — Estrategias y Comandos

**Rollback automático (Swarm):**
```yaml
# Ya configurado en update_config.failure_action: rollback
# Docker maneja el rollback automáticamente si health check falla
```

**Rollback manual (VPS simples):**
```bash
#!/usr/bin/env bash
# scripts/rollback.sh
set -euo pipefail

PREVIOUS_VERSION="${1:?Usage: rollback.sh <previous-version>}"
COMPOSE_FILE="compose.prod.yaml"

echo "🔙 Ejecutando rollback a $PREVIOUS_VERSION"

# 1. Actualizar variable de versión
export VERSION=$PREVIOUS_VERSION

# 2. Pull de imagen anterior
docker compose -f compose.yaml -f $COMPOSE_FILE pull

# 3. Reiniciar servicios con versión anterior
docker compose -f compose.yaml -f $COMPOSE_FILE up -d

# 4. Verificar health checks
sleep 30
bash scripts/health-check.sh || exit 1

# 5. Notificar rollback
curl -X POST "$SLACK_WEBHOOK" \
  -H 'Content-type: application/json' \
  --data "{
    \"text\": \"🔙 Rollback ejecutado\\n*Versión*: $PREVIOUS_VERSION\\n*Commit*: $(git rev-parse HEAD)\\n*Motivo*: Health check fallido\"
  }"

echo "✅ Rollback completado"
```

**Rollback de base de datos (migraciones):**
```sql
-- migrations/V20260429__add_tenant_rls.undo.sql
-- Rollback de política RLS (V1)
DROP POLICY IF EXISTS tenant_isolation_policy ON embeddings;
DROP POLICY IF EXISTS tenant_isolation_policy ON queries;

-- Nota: Las migraciones deben ser aditivas siempre que sea posible
-- Para cambios destructivos, mantener versión anterior disponible
```

## 7. Testing y Calidad en el Stack

### 7.1 Health Checks como Pruebas de Humo Post-Deploy

**Endpoint `/health/ready` profundo:**
```python
# backend/health.py (Python/FastAPI)
from fastapi import FastAPI, HTTPException, status
from app.dependencies import get_db, get_redis, get_vector_store

app = FastAPI()

@app.get("/health/ping")
async def ping():
    """Shallow health check: solo verifica que el proceso corre."""
    return {"status": "ok", "timestamp": datetime.utcnow()}

@app.get("/health/ready")
async def readiness():
    """Deep health check: verifica dependencias reales para gate de producción."""
    checks = {
        "database": await check_db_connection(get_db()),
        "cache": await check_redis_connection(get_redis()),
        "vector_store": await check_vector_store_connection(get_vector_store()) if settings.ENABLE_PGVECTOR else "disabled",
    }
    
    all_healthy = all(v is True for v in checks.values() if v != "disabled")
    status_code = status.HTTP_200_OK if all_healthy else status.HTTP_503_SERVICE_UNAVAILABLE
    
    return JSONResponse(
        content={"status": "ok" if all_healthy else "degraded", "checks": checks, "timestamp": datetime.utcnow()},
        status_code=status_code
    )

async def check_db_connection(db):
    try:
        await db.execute("SELECT 1")
        return True
    except Exception as e:
        logger.error(f"DB check failed: {e}")
        return False
# ... similar para redis, vector_store
```

**Verificación en pipeline:**
```bash
# scripts/verify-deployment.sh
#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:?Usage: verify-deployment.sh <base-url>}"
MAX_ATTEMPTS=12
SLEEP_SECONDS=10

echo "🔍 Verificando salud de despliegue en $BASE_URL"

for i in $(seq 1 $MAX_ATTEMPTS); do
  STATUS=$(curl -sf "$BASE_URL/health/ready" | jq -r '.status' 2>/dev/null || echo "unreachable")
  
  if [ "$STATUS" = "ok" ]; then
    echo "✅ Deep health check passed después de $((i * SLEEP_SECONDS))s"
    exit 0
  fi
  
  echo "⚠️ Intento $i/$MAX_ATTEMPTS: status=$STATUS — reintentando en ${SLEEP_SECONDS}s"
  sleep "$SLEEP_SECONDS"
done

echo "❌ Deep health check falló después de $((MAX_ATTEMPTS * SLEEP_SECONDS))s — ejecutando rollback"
/opt/mantis/scripts/rollback.sh "$PREVIOUS_VERSION"
exit 1
```

### 7.2 Pruebas de Integración con Stack Efímero

**Perfil de test en `compose.test.yaml`:**
```yaml
services:
  app-tests:
    profiles: ["test"]
    build:
      context: .
      target: test  # Etapa de test con herramientas de testing
    command: npm run test:integration
    environment:
      - DATABASE_URL=postgresql://postgres:test@db-test:5432/test_db
      - REDIS_URL=redis://redis-test:6379
    depends_on:
      db-test:
        condition: service_healthy
      redis-test:
        condition: service_started
    networks:
      - test-network

  db-test:
    profiles: ["test"]
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: test_db
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: test
    tmpfs: /var/lib/postgresql/data  # Datos efímeros en memoria
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - test-network

  redis-test:
    profiles: ["test"]
    image: redis:7-alpine
    command: redis-server --appendonly yes
    tmpfs: /data  # Datos efímeros
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
    networks:
      - test-network

networks:
  test-network:
    driver: bridge
    internal: true
```

**Ejecutar tests de integración:**
```bash
# Ejecutar stack de test y correr pruebas
docker compose -f compose.yaml -f compose.test.yaml --profile test up --abort-on-container-exit

# Limpiar recursos post-test
docker compose -f compose.yaml -f compose.test.yaml --profile test down -v
```

### 7.3 Validación de Archivos Compose y Dockerfiles

**Comandos de validación:**
```bash
# Validar sintaxis de Compose
docker compose -f compose.yaml -f compose.prod.yaml config --quiet && echo "✅ Compose válido"

# Validar Dockerfile con hadolint
hadolint Dockerfile.prod

# Validar con dockerfile-validator (script MANTIS)
bash 05-CONFIGURATIONS/validation/dockerfile-validator/scripts/dockerfile-validate.sh Dockerfile.prod

# Validar constraints C1-C8 con orchestrator-engine.sh
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain docker-compose --file compose.prod.yaml --strict
```

**Reporte de validación (ejemplo):**
```
## Dockerfile Validation Report
- Target: Dockerfile.prod
- Command: bash scripts/dockerfile-validate.sh Dockerfile.prod
- Overall result: PASS

### Critical
- None

### High
- None

### Medium
- Consider using distroless base image for smaller attack surface

### Low
- Add LABEL for com.mantis.version for better observability

### Recommended Fixes
- Add: LABEL org.opencontainers.image.version="1.2.3"

### References Used
- references/optimization_guide.md

### Fallbacks Used
- None
```

## 8. Monitoreo y Observabilidad

### 8.1 Configuración de Logging

```yaml
services:
  app:
    logging:
      driver: json-file
      options:
        max-size: "10m"    # Rotar log cada 10MB
        max-file: "5"      # Mantener 5 archivos rotados
        labels: "service,env,version"  # Incluir labels en logs
        env: "NODE_ENV,VERSION"        # Incluir variables en logs
```

**Consulta de logs:**
```bash
# Ver logs en tiempo real
docker compose logs -f backend

# Ver logs de un período específico
docker compose logs --since 1h backend

# Buscar en logs
docker compose logs backend | grep -i "error"

# Exportar logs para análisis externo
docker compose logs --timestamps backend > backend-$(date +%Y%m%d).log
```

### 8.2 Métricas y Integración con Prometheus

**Exponer métricas en la aplicación:**
```javascript
// backend/metrics.js (Node.js + Prometheus client)
const client = require('prom-client');

// Crear registry
const register = new client.Registry();
client.collectDefaultMetrics({ register });

// Métricas custom
const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.3, 0.5, 1, 3, 5],
  registers: [register],
});

// Middleware para medir requests
app.use((req, res, next) => {
  const end = httpRequestDuration.startTimer();
  res.on('finish', () => {
    end({ method: req.method, route: req.route?.path || req.path, status_code: res.statusCode });
  });
  next();
});

// Endpoint para scraping por Prometheus
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});
```

**Configuración de Prometheus en `compose.monitoring.yaml`:**
```yaml
services:
  prometheus:
    image: prom/prometheus:v2.45.0
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.enable-lifecycle'  # Recargar config sin restart
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:10.0.0
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}
    volumes:
      - grafana-data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
    networks:
      - monitoring
    depends_on:
      - prometheus

networks:
  monitoring:
    driver: bridge

volumes:
  prometheus-data:
  grafana-data:
```

### 8.3 Marcadores de Despliegue en Grafana

**Anotaciones automáticas post-deploy:**
```bash
# scripts/notify-grafana.sh
#!/usr/bin/env bash
set -euo pipefail

GRAFANA_URL="${GRAFANA_URL:-http://grafana:3000}"
GRAFANA_API_KEY="${GRAFANA_API_KEY:?Set GRAFANA_API_KEY}"
VERSION="${1:?Usage: notify-grafana.sh <version>}"
COMMIT="${2:-$(git rev-parse HEAD)}"

curl -X POST "$GRAFANA_URL/api/annotations" \
  -H "Authorization: Bearer $GRAFANA_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"time\": $(date +%s)000,
    \"timeEnd\": $(date +%s)000,
    \"tags\": [\"deployment\", \"mantis-backend\"],
    \"text\": \"🚀 Despliegue $VERSION ($COMMIT)\",
    \"title\": \"MANTIS Backend Deployment\"
  }"

echo "✅ Marcador de despliegue enviado a Grafana"
```

**Dashboard de despliegues en Grafana:**
- Filtrar por tag `deployment`
- Correlacionar métricas de error rate, latency con timestamps de despliegue
- Alertar si error rate > 1% dentro de 5 minutos post-deploy

## 9. Mapeo de Constraints MANTIS — Aplicación en Docker Compose

| Código | Descripción | Aplicación en Docker Compose | Herramienta de Validación |
|--------|-------------|-----------------------------|--------------------------|
| **C1** | Inmutabilidad de artefactos | Imágenes versionadas con tag semántico + SHA256; promovidas sin reconstrucción | `docker image inspect`, `sha256sum` |
| **C2** | Infraestructura como código | Todo el stack declarado en YAML; no cambios manuales en VPS | `docker compose config --quiet` |
| **C3** | Secretos nunca en texto plano | Docker Secrets o archivos montados; nunca en env vars o Dockerfile | `audit-secrets.sh`, `trivy fs --scanners secret` |
| **C4** | Trazabilidad de cambios | Etiquetas OCI, commit SHA en imagen, logs estructurados con trace_id | `docker image inspect --format '{{.Config.Labels}}'` |
| **C5** | Validación automatizada de integridad | `docker compose config`, `dockerfile-validator`, `orchestrator-engine.sh` | Scripts de validación en pipeline |
| **C6** | Aprobación de cambios críticos | Entornos protegidos en pipeline, manual gates para production | GitHub/GitLab Environment protection rules |
| **C7** | Rollback automatizado | `update_config.failure_action: rollback`, scripts de rollback con health checks | `rollback.sh`, Prometheus alerts |
| **C8** | Calidad de entrega con pruebas | Health checks como smoke tests, stack de test efímero, promptfoo para agentes | `verify-deployment.sh`, `promptfoo eval` |
| **V1** | Aislamiento de tenants (pgvector) | Redes separadas por tenant_id, volúmenes dedicados, políticas RLS en DB | `check-rls.sh`, `verify-constraints.sh --check-tenant-isolation` |
| **V2** | Validación de integridad de datos | Health checks de DB, backups con verificación, checksums de volúmenes | `pg_verify`, `sha256sum` en backups |
| **V3** | Performance de búsqueda vectorial | Recursos asignados a pgvector/Redis, límites de CPU/memoria, índices HNSW/IVFFlat | `EXPLAIN ANALYZE`, Prometheus metrics |

## 10. Comandos Esenciales y Troubleshooting

### 10.1 Comandos de Gestión Diaria

```bash
# Levantar stack
docker compose up -d

# Detener stack (graceful shutdown)
docker compose down --timeout 30

# Reconstruir imágenes (solo si cambió Dockerfile)
docker compose build --no-cache

# Ver estado de servicios
docker compose ps
docker compose ps -a  # Incluir detenidos

# Seguir logs en tiempo real
docker compose logs -f backend
docker compose logs --tail=100 -f backend  # Últimas 100 líneas

# Ejecutar comando en contenedor en ejecución
docker compose exec backend sh
docker compose exec -u root backend sh  # Como root (solo debugging)

# Ejecutar tarea puntual (ej: migraciones)
docker compose run --rm backend npm run migrate

# Escalar servicio
docker compose up -d --scale backend=3

# Validar configuración sin aplicar
docker compose config --quiet && echo "✅ Configuración válida"
```

### 10.2 Troubleshooting Común

| Problema | Causa Probable | Solución | Comando de Diagnóstico |
|----------|---------------|----------|----------------------|
| **Servicios no se comunican** | Red incorrecta o nombre mal escrito | Verificar `docker compose exec servicio ping otro`; asegurar misma red | `docker network ls`, `docker network inspect mantis-private` |
| **Volúmenes no persisten** | Montaje erróneo o permisos | Revisar `docker volume ls`; verificar `uid/gid` del usuario en contenedor | `docker volume inspect postgres-data`, `docker exec backend id` |
| **Health check nunca pasa** | `start_period` corto o dependencia no lista | Aumentar `start_period`; verificar comando de health check | `docker inspect backend --format='{{.State.Health}}'` |
| **Imagen se reconstruye siempre** | `COPY . .` antes de `COPY package.json` | Reordenar capas: dependencias primero, código después | `docker history mantis-backend:latest` |
| **Contenedor muere inmediatamente** | Comando incorrecto o falta de manejo de señales | Verificar logs; usar `exec form` en CMD; manejar SIGTERM | `docker compose logs backend`, `docker inspect backend --format='{{.Config.Cmd}}'` |
| **No se puede escribir en filesystem** | Faltan `tmpfs` para directorios de escritura | Agregar `tmpfs: /tmp, /var/run` para escritura temporal | `docker exec backend touch /test` (debe fallar si read_only) |
| **Error de permisos en volumen** | Usuario en contenedor no coincide con propietario del volumen | Usar `--chown` en `COPY`; especificar `user: "1001:1001"` | `docker exec backend ls -la /data` |

### 10.3 Diagnóstico Avanzado

```bash
# Inspeccionar contenedor en detalle
docker inspect backend --format='{{json .Config}}' | jq

# Ver uso de recursos en tiempo real
docker stats backend

# Ejecutar shell de debugging en contenedor nuevo
docker compose run --rm --entrypoint sh backend

# Ver logs del daemon Docker (host)
journalctl -u docker --since "1 hour ago" | grep -i error

# Verificar conectividad de red entre servicios
docker compose exec backend ping db
docker compose exec backend nslookup db  # Verificar service discovery

# Verificar variables de entorno en contenedor
docker compose exec backend env | grep -i secret  # No debería mostrar secretos
```

## 11. Plantillas de Uso Frecuente

### 11.1 Plantilla de Servicio Base (Reutilizable)

```yaml
# 05-CONFIGURATIONS/docker-compose/templates/service-base.yaml
# Usar con YAML anchors (&) y aliases (*) para reutilización

x-service-base: &service-base
  restart: unless-stopped
  env_file:
    - .env.common
    - .env.${SERVICE}
  networks:
    - mantis-net
  depends_on:
    postgres:
      condition: service_healthy
    redis:
      condition: service_started
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:${PORT}/health/ready"]
    interval: 30s
    timeout: 5s
    retries: 3
    start_period: 40s
  logging:
    driver: json-file
    options:
      max-size: "10m"
      max-file: "5"
  deploy:
    resources:
      limits:
        cpus: '${CPU_LIMIT:-2}'
        memory: '${MEM_LIMIT:-2G}'
      reservations:
        cpus: '${CPU_RESERVE:-1}'
        memory: '${MEM_RESERVE:-1G}'
  cap_drop:
    - ALL
  cap_add:
    - NET_BIND_SERVICE
  security_opt:
    - no-new-privileges:true
  read_only: true
  tmpfs:
    - /tmp:noexec,nosuid,size=64M
    - /var/run:noexec,nosuid,size=16M
  user: "1001:1001"

# Uso en compose.yaml:
services:
  backend:
    <<: *service-base
    build:
      context: ./backend
      target: production
    expose:
      - "4000"
    environment:
      - SERVICE=backend
      - PORT=4000
```

### 11.2 Stack Completo con PostgreSQL + pgvector + Redis + Aplicación

```yaml
# compose.vector-stack.yaml
services:
  proxy:
    image: nginx:alpine@sha256:abc123...
    ports:
      - "127.0.0.1:80:80"  # Bind a localhost; usar proxy externo para exponer
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    networks:
      - front
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s

  app:
    build:
      context: ./app
      target: production
    expose:
      - "3000"
    environment:
      - DATABASE_URL=postgresql://app:${DB_PASSWORD}@pg:5432/mantis
      - REDIS_URL=redis://redis:6379
      - ENABLE_PGVECTOR=true
    networks:
      - front
      - back
    depends_on:
      pg:
        condition: service_healthy
      redis:
        condition: service_started
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health/ready"]
      interval: 30s
    secrets:
      - db_password

  pg:
    image: pgvector/pgvector:pg16@sha256:def456...
    environment:
      POSTGRES_USER: app
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
      POSTGRES_DB: mantis
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./init-vector.sql:/docker-entrypoint-initdb.d/init-vector.sql:ro  # Crear extensión pgvector
    networks:
      - back
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app -d mantis && psql -U app -d mantis -c 'SELECT extname FROM pg_extension WHERE extname = \"vector\";' | grep -q vector"]
      interval: 10s
      timeout: 5s
      retries: 5
    secrets:
      - db_password
    deploy:
      resources:
        limits:
          memory: 4G  # pgvector requiere más memoria para índices

  redis:
    image: redis:7-alpine@sha256:ghi789...
    command: redis-server --appendonly yes
    volumes:
      - redisdata:/data
    networks:
      - back
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s

networks:
  front:
    driver: bridge
  back:
    driver: bridge
    internal: true  # Aislamiento: sin acceso a Internet

volumes:
  pgdata:
    driver: local
  redisdata:
    driver: local

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

### 11.3 Stack de Desarrollo con Hot Reload

```yaml
# compose.override.yaml (auto-loaded en desarrollo)
services:
  app:
    build:
      context: ./app
      target: development  # Etapa de desarrollo con herramientas
    volumes:
      - ./app/src:/app/src  # Hot reload: montar código fuente
      - /app/node_modules   # Preservar node_modules del contenedor
    ports:
      - "3000:3000"         # Exponer para acceso local
      - "9229:9229"         # Debugger de Node.js
    environment:
      - NODE_ENV=development
      - DEBUG=app:*
      - WATCHPACK_POLLING=true  # Para hot reload en Docker
    command: npm run dev
    healthcheck:
      disable: true  # Deshabilitar health check en desarrollo

  pg:
    ports:
      - "5432:5432"  # Exponer para herramientas locales (pgAdmin, DBeaver)
    environment:
      - POSTGRES_PASSWORD=dev  # Contraseña de desarrollo (no sensible)
    volumes:
      - ./init-dev.sql:/docker-entrypoint-initdb.d/init.sql:ro  # Datos de prueba

  redis:
    ports:
      - "6379:6379"  # Exponer para Redis Insight o CLI local
```

## 12. Validación Automática con `dockerfile-validator`

### 12.1 Flujo Determinista de Validación

```bash
#!/usr/bin/env bash
# 05-CONFIGURATIONS/validation/dockerfile-validator/scripts/dockerfile-validate.sh
set -euo pipefail

TARGET="${1:?Usage: dockerfile-validate.sh <Dockerfile>}"
SKILL_DIR="05-CONFIGURATIONS/validation/dockerfile-validator"

# 1. Preflight: verificar archivos
test -f "$TARGET" || { echo "❌ Dockerfile no encontrado: $TARGET"; exit 1; }
test -f "$SKILL_DIR/references/security_checklist.md" || { echo "❌ Referencias faltantes"; exit 1; }

# 2. Leer Dockerfile (primeras 220 líneas para análisis rápido)
sed -n '1,220p' "$TARGET" > /tmp/dockerfile-head.txt

# 3. Ejecutar validadores externos si están disponibles
HADOLINT_AVAILABLE=$(command -v hadolint >/dev/null && echo "yes" || echo "no")
TRIVY_AVAILABLE=$(command -v trivy >/dev/null && echo "yes" || echo "no")

if [ "$HADOLINT_AVAILABLE" = "yes" ]; then
  hadolint "$TARGET" > /tmp/hadolint.out 2>&1 || true
fi

if [ "$TRIVY_AVAILABLE" = "yes" ]; then
  trivy config "$TARGET" --format json > /tmp/trivy-config.out 2>&1 || true
fi

# 4. Clasificar hallazgos por severidad (estándar MANTIS)
CRITICAL=0; HIGH=0; MEDIUM=0; LOW=0

# Critical: secrets hardcodeados, root runtime sin justificación
if grep -qiE "^[[:space:]]*(ENV|ARG)[[:space:]].*(password|secret|token|api[_-]?key)[[:space:]]*=" "$TARGET"; then
  echo "🔴 CRITICAL: Posible secret hardcodeado en Dockerfile"
  ((CRITICAL++))
fi

if grep -qiE "^[[:space:]]*USER[[:space:]]+(root|0(:0)?)$" "$TARGET" && ! grep -q "justification" "$TARGET"; then
  echo "🔴 CRITICAL: Ejecución como root sin justificación"
  ((CRITICAL++))
fi

# High: :latest tags, missing healthcheck, missing non-root user
if grep -qiE "^[[:space:]]*FROM[[:space:]]+.*:latest" "$TARGET"; then
  echo "🟡 HIGH: Uso de tag :latest (usar versión específica)"
  ((HIGH++))
fi

if ! grep -qiE "^[[:space:]]*HEALTHCHECK[[:space:]]+" "$TARGET"; then
  echo "🟡 HIGH: Falta HEALTHCHECK en Dockerfile"
  ((HIGH++))
fi

if ! grep -qiE "^[[:space:]]*USER[[:space:]]+[a-z]" "$TARGET"; then
  echo "🟡 HIGH: Falta USER non-root en Dockerfile"
  ((HIGH++))
fi

# Medium: layer caching anti-patterns, missing .dockerignore
if grep -A5 "COPY . \." "$TARGET" | grep -q "RUN npm install"; then
  echo "🟢 MEDIUM: Posible anti-patrón de caché: copiar código antes de dependencias"
  ((MEDIUM++))
fi

# Low: style suggestions
if ! grep -qiE "LABEL org.opencontainers.image" "$TARGET"; then
  echo "🔵 LOW: Agregar labels OCI para trazabilidad"
  ((LOW++))
fi

# 5. Reporte final
echo ""
echo "## Dockerfile Validation Report"
echo "- Target: $TARGET"
echo "- Overall result: $([ $CRITICAL -eq 0 ] && echo "PASS" || echo "FAIL")"
echo ""
echo "### Critical: $CRITICAL"
echo "### High: $HIGH"
echo "### Medium: $MEDIUM"
echo "### Low: $LOW"

# 6. Código de salida
if [ $CRITICAL -gt 0 ]; then
  exit 2  # FAIL crítico
elif [ $HIGH -gt 0 ]; then
  exit 1  # FAIL alto
else
  exit 0  # PASS o warnings menores
fi
```

### 12.2 Ejemplo de Reporte de Validación

```
## Dockerfile Validation Report
- Target: Dockerfile.prod
- Command: bash scripts/dockerfile-validate.sh Dockerfile.prod
- Overall result: PASS

### Critical: 0
- None

### High: 1
- 🟡 HIGH: Falta HEALTHCHECK en Dockerfile

### Medium: 0
- None

### Low: 2
- 🟢 LOW: Agregar labels OCI para trazabilidad
- 🟢 LOW: Considerar usar distroless base image

### Recommended Fixes
- Agregar: HEALTHCHECK --interval=30s --timeout=3s CMD curl -f http://localhost:3000/health/ready || exit 1
- Agregar: LABEL org.opencontainers.image.version="1.2.3"

### References Used
- references/security_checklist.md
- references/optimization_guide.md

### Fallbacks Used
- None
```

## 13. Integración con Otros Agentes MANTIS

| Agente | Integración con docker-compose-master-agent | Punto de Contacto |
|--------|--------------------------------------------|------------------|
| **pipelines-master-agent** | Invoca builds de imágenes, escaneo de seguridad, despliegue remoto usando archivos Compose generados | `validation_command`, `deploy.sh` |
| **terraform-master-agent** | Define infraestructura base (VPS, redes, volúmenes externos); Compose referencia recursos externos | Volúmenes externos, redes pre-creadas |
| **postgresql-pgvector-rag-master-agent** | Usa servicios de DB definidos por Compose; configuraciones de conexión y volúmenes deben coincidir | `DATABASE_URL`, volúmenes `pgdata`, políticas RLS |
| **configurations-master-agent** | Delega creación y validación de subdominio `docker-compose/` a este agente | `canonical_path`, `domain: 05-CONFIGURATIONS` |
| **orchestrator-engine.sh** | Validación runtime de constraints C1-C8, V1-V3 aplicadas a archivos Compose | `--domain docker-compose --strict` |

**Flujo de orquestación típico:**
```
1. User solicita: "Generar stack para VPS1 con backend + pgvector"
2. configurations-master-agent delega a docker-compose-master-agent
3. docker-compose-master-agent:
   - Consulta 00-STACK-SELECTOR.md para resolver {language} y perfil de infra
   - Genera compose.yaml + compose.prod.yaml con patrones validados
   - Incluye validation_command y checksum_sha256 en frontmatter
4. pipelines-master-agent:
   - Ejecuta docker compose config --quiet para validar sintaxis
   - Ejecuta dockerfile-validator para Dockerfiles asociados
   - Despliega a VPS vía SSH con scripts de health check y rollback
5. orchestrator-engine.sh valida constraints C1-C8 post-generación
```

## 14. Referencias Dentro del Dominio `05-CONFIGURATIONS/docker-compose/`

| Archivo / Carpeta | Estado | Descripción |
|-------------------|--------|-------------|
| `compose.yaml` | REAL | Configuración base común a todos los entornos |
| `compose.override.yaml` | REAL | Overrides para desarrollo (auto-loaded) |
| `compose.staging.yaml` | PLANNED | Overrides para staging |
| `compose.prod.yaml` | REAL | Overrides para producción |
| `vps1.yml` | REAL | Stack específico para VPS1 (nano profile) |
| `vps2.yml` | REAL | Stack específico para VPS2 (micro profile) |
| `vps3.yml` | PLANNED | Stack específico para VPS3 (standard profile) |
| `Dockerfile` | REAL | Dockerfile base para aplicación principal |
| `Dockerfile.prod` | REAL | Dockerfile optimizado para producción |
| `scripts/deploy.sh` | REAL | Script de despliegue a VPS |
| `scripts/rollback.sh` | REAL | Script de rollback automático |
| `scripts/health-check.sh` | REAL | Verificación post-deploy de servicios |
| `scripts/switch-proxy.sh` | PLANNED | Cambio de tráfico para blue-green |
| `secrets/` | REAL | Directorio para archivos de secretos (no commitear) |
| `references/security_checklist.md` | REAL | Guía de seguridad para imágenes y contenedores |
| `references/optimization_guide.md` | REAL | Guía de optimización de builds y tamaño de imagen |
| `references/docker_best_practices.md` | REAL | Mejores prácticas generales de Docker |
| `.env.example` | REAL | Plantilla de variables de entorno requeridas |
| `.dockerignore` | REAL | Archivos a excluir del contexto de build |

## 15. Estilo de Trabajo del Agente — Protocolo de Ejecución

```markdown
## 🤖 Estilo de Trabajo — docker-compose-master-agent

### Al recibir una tarea:

1. **Evaluar modo**:
   - ¿Es análisis/diagnóstico? → Modo A (proponer, no generar)
   - ¿Es generación de artefactos? → Modo B (generar con constraints)

2. **Consultar contexto**:
   - Leer `00-STACK-SELECTOR.md` para resolver `{language}`, perfil de infra, vertical
   - Validar que la ruta destino existe en `PROJECT_TREE.md`
   - Confirmar que `constraints_mapped` ⊆ constraints permitidas para la carpeta

3. **Aplicar constraints ANTES de generar**:
   - C1: Usar imágenes con tag semántico + SHA256, no reconstruir en cada entorno
   - C2: Todo en YAML; no comandos manuales en VPS
   - C3: Secrets como archivos montados, nunca en env vars o Dockerfile
   - C4: Incluir labels OCI con commit SHA para trazabilidad
   - C5: Incluir `validation_command` en frontmatter para validación automática
   - C6: Despliegues a production solo vía pipeline con approval gates
   - C7: Configurar `failure_action: rollback` o scripts de rollback
   - C8: Health checks profundos como smoke tests post-deploy
   - V1-V3: Aislamiento de tenants, validación de datos, performance de pgvector

4. **Generar con validación integrada**:
   - Incluir `validation_command: orchestrator-engine.sh --domain docker-compose --strict`
   - Agregar `checksum_sha256: "PENDING_GENERATION"` para trazabilidad
   - Usar formato parseable por IA: YAML con anchors, tablas Markdown, JSON embebido

5. **Entregar con formato estructurado**:
   ```markdown
   ### ✅ Artefacto Generado: {path}
   
   **Validación**: `orchestrator-engine.sh --domain docker-compose --file {path} --strict`
   
   **Checksum**: `sha256sum {path} | awk '{print $1}'`
   
   **Próximos pasos**:
   - [ ] Commit con mensaje trazable
   - [ ] Actualizar `canonical_registry.json`
   - [ ] Ejecutar pipeline de validación
   - [ ] Generar checksum final y actualizar frontmatter
   ```

### Ante ambigüedad:
- **Preguntar antes de asumir**: "¿Confirmás que este servicio debe usar red interna o pública?"
- **Documentar decisiones**: "Resolví profile=micro porque la tarea menciona VPS2"
- **Registrar AUDIT_FLAG**: Si se usa override, agregar `AUDIT_FLAG=network_override_accepted`

### Anti-patrones (NUNCA):
- ❌ Generar compose sin validar constraints primero
- ❌ Hardcodear valores de infra (mem_limit, cpu_quota)
- ❌ Ignorar LANGUAGE_LOCK para operadores pgvector en servicios de DB
- ❌ Omitir `validation_command` en frontmatter de nuevos archivos
- ❌ Usar `:latest` en imágenes de producción
- ❌ Exponer puertos innecesarios (`ports: "8080:8080"` en lugar de `"127.0.0.1:8080:8080"`)
```

## 16. Ejemplos de Uso — Casos Reales con Respuestas Esperadas

### 16.1 Caso: Crear stack para VPS1 con backend + pgvector

**Solicitud de Usuario**:  
> "Necesito el docker-compose para la VPS1 que incluya el backend, la base de datos con pgvector y Redis. Quiero que use las imágenes que están en nuestro registro privado."

**Respuesta en Modo B**:

```yaml
### ✅ Artefacto Generado: 05-CONFIGURATIONS/docker-compose/vps1.yml

# Stack para VPS1 (nano profile: 1 vCPU, 4GB RAM)
# Generado por docker-compose-master-agent v2.0.0
# Constraints: C1,C2,C3,C4,C5,C6,C7,C8,V1,V2,V3

services:
  backend:
    image: registry.mantis.org/mantis-backend:${VERSION:-1.2.3}@sha256:abc123...
    container_name: mantis-backend
    restart: unless-stopped
    expose:
      - "4000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://app:${DB_PASSWORD}@pg:5432/mantis
      - REDIS_URL=redis://redis:6379
      - ENABLE_PGVECTOR=true
    networks:
      - front
      - back
    depends_on:
      pg:
        condition: service_healthy
      redis:
        condition: service_started
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:4000/health/ready"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 40s
    deploy:
      resources:
        limits:
          cpus: '1'  # nano profile: 1 vCPU
          memory: 1G  # nano profile: 1GB para app
        reservations:
          cpus: '0.5'
          memory: 512M
    secrets:
      - db_password
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,size=64M
      - /var/run:noexec,nosuid,size=16M
    user: "1001:1001"

  pg:
    image: pgvector/pgvector:pg16@sha256:def456...
    container_name: mantis-pg
    environment:
      POSTGRES_USER: app
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
      POSTGRES_DB: mantis
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./init-vector.sql:/docker-entrypoint-initdb.d/init-vector.sql:ro
    networks:
      - back
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app -d mantis && psql -U app -d mantis -c 'SELECT extname FROM pg_extension WHERE extname = \"vector\";' | grep -q vector"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s
    deploy:
      resources:
        limits:
          memory: 2G  # pgvector requiere más memoria
    secrets:
      - db_password

  redis:
    image: redis:7-alpine@sha256:ghi789...
    container_name: mantis-redis
    command: redis-server --appendonly yes
    volumes:
      - redisdata:/data
    networks:
      - back
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5
    deploy:
      resources:
        limits:
          memory: 256M

networks:
  front:
    driver: bridge
  back:
    driver: bridge
    internal: true  # Aislamiento: sin acceso a Internet

volumes:
  pgdata:
    driver: local
  redisdata:
    driver: local

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

**Validación**:  
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain docker-compose --file 05-CONFIGURATIONS/docker-compose/vps1.yml --strict
```

**Checksum**:  
```bash
sha256sum 05-CONFIGURATIONS/docker-compose/vps1.yml | awk '{print $1}'
# PENDING_GENERATION → actualizar post-commit
```

**Próximos pasos**:  
- [ ] Crear archivo `./secrets/db_password.txt` con la contraseña (fuera del repo)
- [ ] Agregar `secrets/` a `.gitignore` si no está ya
- [ ] Ejecutar `docker compose -f compose.yaml -f vps1.yml config --quiet` para validar sintaxis
- [ ] Desplegar a VPS1 con `scripts/deploy.sh vps1.example.com vps1.yml`

---

*Agente docker-compose-master-agent v2.0.0-COMPREHENSIVE listo para operar en el ecosistema MANTIS.*  
*Auto-contenido: todas las habilidades, patrones y conocimientos necesarios están definidos en este documento.*  
*Gobernanza: immutable=true, requires_human_approval_for_changes=true, checksum_sha256 para trazabilidad.*  
*Optimizado para ingestión de IA: estructura YAML/JSON-parseable, tablas de decisión, anti-patrones declarativos.*
```
