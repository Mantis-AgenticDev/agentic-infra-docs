# ---
# artifact_id: "goals-mcp-dockerfile"
# artifact_type: "dockerfile"
# version: "2.0.1"
# constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
# canonical_path: "goals/mcp-deploy/Dockerfile"
# tier: 2
# immutable: false
# language_lock: "dockerfile"
# prompt_hash: "sha256:dockerfile-v2.0.1"
# generated_at: "2026-05-23T14:10:00Z"
# domain: "goals"
# subdomain: "mcp-deploy"
# status: "✅ Estável"
# license: "CC-BY-NC-SA-4.0"
# ---
# Imagen ligera para el servidor MCP de MANTIS GOALS.
# Construir: docker build -t mantisagenticdev/mantis-goals:latest -f goals/mcp-deploy/Dockerfile .

FROM python:3.12-slim

LABEL org.opencontainers.image.title="MANTIS GOALS MCP Server"
LABEL org.opencontainers.image.description="Servidor MCP autocontenido para coordinación de agentes"
LABEL org.opencontainers.image.authors="Mantis-AgenticDev"
LABEL org.opencontainers.image.version="2.0.1"

# Instalar solo lo necesario
RUN apt-get update && \
    apt-get install -y --no-install-recommends sqlite3 curl && \
    rm -rf /var/lib/apt/lists/*

# Directorio de trabajo
WORKDIR /app

# Copiar dependencias primero (cacheo de capas)
COPY goals/mcp-deploy/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# Copiar todo el dominio goals/
COPY goals/ /app/goals/

# Crear carpetas de datos (se montarán como volúmenes en producción)
RUN mkdir -p /app/data/agent-db /app/data/logs /app/data/backups

# Variables de entorno con valores por defecto (API Key se fuerza en docker-compose)
ENV MANTIS_DB_PATH=/app/data/registry.db
ENV MANTIS_AGENT_DB_DIR=/app/data/agent-db
ENV MANTIS_LOG_DIR=/app/data/logs
ENV MANTIS_BACKUP_DIR=/app/data/backups
ENV MANTIS_PORT=8080

# Crear usuario no-root para seguridad
RUN useradd -m -u 1000 mantis && chown -R mantis:mantis /app
USER mantis

# Puerto HTTP
EXPOSE 8080

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Punto de entrada
CMD ["python3", "/app/goals/mcp-deploy/server.py"]
