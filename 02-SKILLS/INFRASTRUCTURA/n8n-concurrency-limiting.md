# n8n-concurrency-limiting.md

> **Limitación de Concurrencia en n8n para Evitar Saturación de VPS**

**Skill:** INFRA-002 | **Categoría:** INFRAESTRUCTURA
**Última actualización:** 2026-04-10
**Validación SDD:** Pending
**Refs:** 02-RESOURCE-GUARDRAILS.md, 02-SKILLS/00-INDEX.md

---

## 1. Propósito y Contexto

Este skill documenta los patrones y configuraciones necesarios para limitar la concurrencia de workflows en n8n, evitando que los VPS con 4GB RAM y 1 vCPU se saturen durante picos de procesamiento.

La limitación de concurrencia es **crítica** porque:

- **C1 (Resource Guardrails):** Cada VPS tiene máximo 4GB RAM y 1 vCPU
- **C2 (Resource Guardrails):** n8n está limitado a 1.5GB RAM
- **C6 (Architecture Rules):** Solo APIs cloud (OpenRouter), sin modelos locales

Sin control de concurrencia, un flujo con múltiples nodos HTTP puede generar 50+ conexiones simultáneas, agotando memoria y CPU, causando timeouts en cascada y pérdida de mensajes de WhatsApp.

---

## 2. Arquitectura de Control de Concurrencia

### 2.1 Diagrama de Flujo de Control

```
┌─────────────────────────────────────────────────────────────────┐
│                    ARQUITECTURA DE CONCURRENCIA                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   [WhatsApp/Telegram]                                           │
│         │                                                       │
│         ▼                                                       │
│   ┌───────────┐    ┌──────────────┐    ┌────────────────────┐   │
│   │  Webhook  │───▶│ n8n Queue    │───▶│ Semaphore/Limit    │   │
│   │  Entry    │    │ (Redis)      │    │ (1-3 concurrent)   │   │
│   └───────────┘    └──────────────┘    └────────────────────┘   │
│                                               │                 │
│         ┌─────────────────────────────────────┼───────────┐     │
│         ▼                   ▼                             ▼     │    
│   ┌───────────┐      ┌───────────┐             ┌───────────┐    │    
│   │  Workflow │      │  Workflow │             │  Workflow │    │    
│   │  Worker 1 │      │  Worker 2 │             │  Worker 3 │    │    
│   └───────────┘      └───────────┘             └───────────┘    │    
│         │                   │                   │               │
│         └───────────────────┴───────────────────┘               │
│                           │                                     │    
│                           ▼                                     │    
│                  ┌──────────────────┐                           │    
│                  │  Response Queue  │                           │    
│                  │  (FIFO Buffer)   │                           │    
│                  └──────────────────┘                           │    
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Componentes del Sistema de Control

| Componente | Función | Límite Recomendado |
|------------|---------|-------------------|
| **n8n Queue (Redis)** | Buffer de mensajes entrantes | 100 items max |
| **Semaphore** | Control de ejecución simultánea | 2-3 workers |
| **Timeout Global** | Mata workflows colgados | 90 segundos |
| **Timeout por Nodo** | Mata nodos HTTP lentos | 30 segundos |
| **Memory Guard** | Monitorea uso de RAM | 1.5GB límite |
| **Retry Queue** | Cola de reintentos con backoff | 3 intentos máx |

---

## 3. Patrones de Implementación

### 3.1 Patrón 1: Semaphore con Redis (Recomendado)

Este patrón usa Redis como mecanismo de locking distribuido para limitar ejecuciones concurrentes.

```yaml
# docker-compose.yml - Configuración con límites de memoria
version: '3.8'

services:
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n_main
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - EXECUTIONS_MODE=queue
      - EXECUTIONS_PROCESS=main
      - EXECUTIONS_TIMEOUT=90
      - EXECUTIONS_TIMEOUT_MAX=90
      - NODE_FUNCTION_ALLOW_EXTERNAL=*
      - EXECUTIONS_DATA_SAVE_ON_ERROR=all
      - EXECUTIONS_DATA_SAVE_ON_SUCCESS=none
      - GENERIC_TIMEZONE=America/Sao_Paulo
    deploy:
      resources:
        limits:
          memory: 1536M
          cpus: '1'
        reservations:
          memory: 512M
          cpus: '0.5'
    volumes:
      - n8n_data:/home/node/.n8n
      - /var/run/docker.sock:/var/run/docker.sock
    networks:
      - n8n_network
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:5678/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3

  redis:
    image: redis:7-alpine
    container_name: n8n_redis
    restart: unless-stopped
    command: redis-server --maxmemory 256mb --maxmemory-policy allkeys-lru
    deploy:
      resources:
        limits:
          memory: 256M
    networks:
      - n8n_network

volumes:
  n8n_data:
    driver: local

networks:
  n8n_network:
    driver: bridge
```

### 3.2 Patrón 2: Limit Node en Workflow n8n

Para workflows específicos, usar el nodo "Limit" integrado de n8n.

```json
{
  "name": "Workflow con Control de Concurrencia",
  "nodes": [
    {
      "name": "Webhook Entry",
      "type": "n8n-nodes-base.webhook",
      "typeVersion": 1,
      "parameters": {
        "httpMethod": "POST",
        "path": "whatsapp-webhook"
      },
      "position": [250, 300]
    },
    {
      "name": "Deduplicación",
      "type": "n8n-nodes-base.set",
      "typeVersion": 2,
      "parameters": {
        "mode": "manual",
        "duplicateItem": false
      },
      "position": [450, 300]
    },
    {
      "name": "Limitar Concurrencia",
      "type": "n8n-nodes-base.limit",
      "typeVersion": 1,
      "parameters": {
        "limit": 2,
        "interval": 1,
        "downloadLimit": 100,
        "downloadUnit": "megabytes"
      },
      "position": [650, 300]
    },
    {
      "name": "Procesar Mensaje",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 3,
      "parameters": {
        "url": "={{ $env.OPENROUTER_API_URL }}/chat/completions",
        "method": "POST",
        "sendHeaders": true,
        "headerParameters": {
          "parameters": [
            {
              "name": "Authorization",
              "value": "Bearer {{ $env.OPENROUTER_API_KEY }}"
            }
          ]
        },
        "sendBody": true,
        "bodyParameters": {
          "parameters": [
            {
              "name": "model",
              "value": "={{ $env.OPENROUTER_MODEL }}"
            },
            {
              "name": "messages",
              "value": "={{ $json.messages }}"
            }
          ]
        },
        "options": {
          "timeout": 30000
        }
      },
      "position": [850, 300]
    }
  ],
  "connections": {
    "Webhook Entry": {
      "main": [[{"node": "Deduplicación", "type": "main", "index": 0}]]
    },
    "Deduplicación": {
      "main": [[{"node": "Limitar Concurrencia", "type": "main", "index": 0}]]
    },
    "Limitar Concurrencia": {
      "main": [[{"node": "Procesar Mensaje", "type": "main", "index": 0}]]
    }
  }
}
```

### 3.3 Patrón 3: Queue con BullMQ (Avanzado)

Para arquitecturas distribuidas con múltiples workers n8n.

```yaml
# docker-compose.bullmq.yml
version: '3.8'

services:
  n8n_worker_1:
    image: n8nio/n8n:latest
    container_name: n8n_worker_1
    restart: unless-stopped
    command: n8n worker
    environment:
      - EXECUTIONS_MODE=queue
      - EXECUTIONS_PROCESS=main
      - QUEUE_BULLMQ_REDIS_HOST=redis_bullmq
      - QUEUE_BULLMQ_REDIS_PORT=6379
      - EXECUTIONS_TIMEOUT=90
      - GENERIC_TIMEZONE=America/Sao_Paulo
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
    depends_on:
      - redis_bullmq
      - n8n_main
    networks:
      - n8n_network

  n8n_worker_2:
    image: n8nio/n8n:latest
    container_name: n8n_worker_2
    restart: unless-stopped
    command: n8n worker
    environment:
      - EXECUTIONS_MODE=queue
      - EXECUTIONS_PROCESS=main
      - QUEUE_BULLMQ_REDIS_HOST=redis_bullmq
      - QUEUE_BULLMQ_REDIS_PORT=6379
      - EXECUTIONS_TIMEOUT=90
      - GENERIC_TIMEZONE=America/Sao_Paulo
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
    depends_on:
      - redis_bullmq
      - n8n_main
    networks:
      - n8n_network

  redis_bullmq:
    image: redis:7-alpine
    container_name: redis_bullmq
    restart: unless-stopped
    command: redis-server --maxmemory 512mb --maxmemory-policy allkeys-lru --save 60 1 --appendonly yes
    deploy:
      resources:
        limits:
          memory: 512M
    networks:
      - n8n_network

  n8n_main:
    image: n8nio/n8n:latest
    container_name: n8n_main
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - EXECUTIONS_MODE=queue
      - EXECUTIONS_PROCESS=main
      - QUEUE_BULLMQ_REDIS_HOST=redis_bullmq
      - QUEUE_BULLMQ_REDIS_PORT=6379
      - GENERIC_TIMEZONE=America/Sao_Paulo
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
    volumes:
      - n8n_data:/home/node/.n8n
    networks:
      - n8n_network

volumes:
  n8n_data:

networks:
  n8n_network:
    driver: bridge
```

### 3.4 Patrón 4: Memory Guard con Script

Script bash para monitorear uso de memoria de n8n y matar procesos si excede 1.5GB.

```bash
#!/bin/bash
# HEALTH-002-MemoryGuard.sh - Monitor de memoria n8n
# Ref: 02-RESOURCE-GUARDRAILS.md

set -euo pipefail

# Configuración
readonly CONTAINER_NAME="n8n_main"
readonly MEMORY_LIMIT_MB=1536
readonly CHECK_INTERVAL=30
readonly LOG_FILE="/var/log/n8n-memory-guard.log"

# Funciones de logging
log_message() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$LOG_FILE"
}

# Obtener uso de memoria actual
get_memory_usage() {
    docker stats "$CONTAINER_NAME" --no-stream --format "{{.MemUsage}}" | \
    awk '{print $1}' | sed 's/MiB//' | sed 's/GiB/*1024/g' | bc
}

# Verificar y limitar concurrencia
check_memory_and_throttle() {
    local current_mem
    current_mem=$(get_memory_usage)

    log_message "INFO" "Memoria actual: ${current_mem}MB (Límite: ${MEMORY_LIMIT_MB}MB)"

    if (( $(echo "$current_mem > $MEMORY_LIMIT_MB" | bc -l) )); then
        log_message "WARN" "Límite de memoria excedido. Reduciendo concurrencia..."

        # Pausar workflows activos
        docker pause "$CONTAINER_NAME" || true

        # Esperar que baje la memoria
        sleep 60

        # Reanudar si memoria bajó
        local new_mem
        new_mem=$(get_memory_usage)
        if (( $(echo "$new_mem < $MEMORY_LIMIT_MB" | bc -l) )); then
            docker unpause "$CONTAINER_NAME"
            log_message "INFO" "n8n reanudado. Memoria: ${new_mem}MB"
        else
            log_message "ERROR" "Memoria aún alta (${new_mem}MB). Ejecutando restart..."
            docker restart "$CONTAINER_NAME"
        fi
    fi
}

# Contador de workflows activos
count_active_workflows() {
    docker exec "$CONTAINER_NAME" n8n execute list --active 2>/dev/null | \
    grep -c "running" || echo 0
}

# Main loop
main() {
    log_message "INFO" "Iniciando Memory Guard para $CONTAINER_NAME"

    while true; do
        check_memory_and_throttle

        local active_count
        active_count=$(count_active_workflows)
        log_message "INFO" "Workflows activos: $active_count"

        if [ "$active_count" -gt 10 ]; then
            log_message "WARN" "Demasiados workflows activos: $active_count. Esperando..."
            sleep 30
        fi

        sleep "$CHECK_INTERVAL"
    done
}

# Trap para limpieza
trap 'log_message "INFO" "Deteniendo Memory Guard"; exit 0' SIGTERM SIGINT

main
```

### 3.5 Patrón 5: Rate Limiting con API Gateway

Para limitarRequests por segundo desde el exterior.

```nginx
# /etc/nginx/conf.d/n8n-rate-limit.conf
# Ref: 04-API-RELIABILITY-RULES.md

limit_req_zone $binary_remote_addr zone=whatsapp_api:10m rate=5r/s;
limit_conn_zone $binary_remote_addr zone=conn_limit:10m;

upstream n8n_backend {
    server 127.0.0.1:5678;
    keepalive 32;
}

server {
    listen 443 ssl http2;
    server_name n8n-api.example.com;

    ssl_certificate /etc/letsencrypt/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/privkey.pem;

    # Rate limiting por IP
    limit_req zone=whatsapp_api burst=20 nodelay;
    limit_conn conn_limit 10;

    # Timeouts para evitar colgados
    proxy_connect_timeout 30s;
    proxy_send_timeout 90s;
    proxy_read_timeout 90s;

    # Buffers para respuestas grandes
    proxy_buffer_size 128k;
    proxy_buffers 4 256k;
    proxy_busy_buffers_size 256k;

    location / {
        proxy_pass http://n8n_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Health check
        health_check interval=30s fails=3 passes=2;
    }

    location /webhook/ {
        # Límite más estricto para webhooks
        limit_req zone=whatsapp_api burst=5 nodelay;
        proxy_pass http://n8n_backend;
        proxy_request_buffering off;
    }
}
```

---

## 4. Ejemplos Prácticos

### Ejemplo 1: WhatsApp Agent con Límite de 3 Mensajes Simultáneos

**Caso de uso:** Chatbot de restaurante con 3 clientes concurrentes máximo.

```json
{
  "name": "WhatsApp-Restaurant-Chatbot",
  "nodes": [
    {
      "name": "Webhook Entrada",
      "type": "n8n-nodes-base.webhook",
      "typeVersion": 2,
      "parameters": {
        "httpMethod": "POST",
        "path": "restaurant-booking"
      },
      "position": [100, 300]
    },
    {
      "name": "Validar Tenant",
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "parameters": {
        "jsCode": "// Validar tenant_id del mensaje\nconst tenantId = $input.first().json.tenant_id;\n\nif (!tenantId) {\n  throw new Error('tenant_id requerido (Ref: 06-MULTITENANCY-RULES.md#L12)');
n}\n\nreturn $input.all();"
      },
      "position": [300, 300]
    },
    {
      "name": "Acquire Semaphore",
      "type": "n8n-nodes-base.redis",
      "typeVersion": 1,
      "parameters": {
        "operation": "set",
        "property": "semaphore",
        "key": "={{ $json.tenant_id }}-semaphore",
        "value": "={{ $json.message_id }}",
        "ttl": 60,
        "options": {
          "host": "={{ $env.REDIS_HOST }}",
          "port": "={{ $env.REDIS_PORT }}"
        }
      },
      "position": [500, 300]
    },
    {
      "name": "Enviar a OpenRouter",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4,
      "parameters": {
        "url": "https://openrouter.ai/api/v1/chat/completions",
        "method": "POST",
        "sendHeaders": true,
        "headerParameters": {
          "parameters": [
            {"name": "Authorization", "value": "Bearer {{ $env.OPENROUTER_API_KEY }}"},
            {"name": "HTTP-Referer", "value": "{{ $env.SITE_URL }}"},
            {"name": "X-Title", "value": "Restaurant-Chatbot"}
          ]
        },
        "contentType": "json",
        "bodyParameters": {
          "parameters": [
            {"name": "model", "value": "openai/gpt-4o"},
            {"name": "messages", "value": "=[{\"role\": \"user\", \"content\": {{ $json.message }} }]"},
            {"name": "max_tokens", "value": 500},
            {"name": "temperature", "value": 0.7}
          ]
        },
        "options": {
          "timeout": 30000,
          "retryOnTimeout": true,
          "maxRetries": 3
        }
      },
      "position": [700, 300]
    },
    {
      "name": "Liberar Semaphore",
      "type": "n8n-nodes-base.redis",
      "typeVersion": 1,
      "parameters": {
        "operation": "del",
        "property": "semaphore",
        "key": "={{ $('Validar Tenant').item.json.tenant_id }}-semaphore",
        "options": {
          "host": "={{ $env.REDIS_HOST }}",
          "port": "={{ $env.REDIS_PORT }}"
        }
      },
      "position": [900, 300]
    },
    {
      "name": "Responder WhatsApp",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4,
      "parameters": {
        "url": "={{ $env.UAZAPI_WEBHOOK_URL }}/send",
        "method": "POST",
        "contentType": "json",
        "bodyParameters": {
          "parameters": [
            {"name": "phone", "value": "={{ $json.phone }}"},
            {"name": "message", "value": "={{ $json.response }}"},
            {"name": "tenant_id", "value": "={{ $('Validar Tenant').item.json.tenant_id }}"}
          ]
        },
        "options": {
          "timeout": 15000
        }
      },
      "position": [1100, 300]
    }
  ],
  "connections": {
    "Webhook Entrada": {
      "main": [[{"node": "Validar Tenant", "type": "main", "index": 0}]]
    },
    "Validar Tenant": {
      "main": [[{"node": "Acquire Semaphore", "type": "main", "index": 0}]]
    },
    "Acquire Semaphore": {
      "main": [[{"node": "Enviar a OpenRouter", "type": "main", "index": 0}]]
    },
    "Enviar a OpenRouter": {
      "main": [[{"node": "Liberar Semaphore", "type": "main", "index": 0}]]
    },
    "Liberar Semaphore": {
      "main": [[{"node": "Responder WhatsApp", "type": "main", "index": 0}]]
    }
  },
  "settings": {
    "executionOrder": "v1",
    "saveDataErrorExecution": "all",
    "saveDataSuccessExecution": "none",
    "saveDataProgressExecution": "none",
    "timeout": 90
  }
}
```

### Ejemplo 2: RAG Ingestion con Cola de Prioridad

**Caso de uso:** Ingesta de documentos PDF con límite de 2 procesos simultáneos.

```json
{
  "name": "PDF-RAG-Ingestion-Queue",
  "nodes": [
    {
      "name": "Trigger Google Drive",
      "type": "n8n-nodes-base.googleDriveTrigger",
      "typeVersion": 1,
      "parameters": {
        "events": ["file.created", "file.modified"],
        "watchFolders": true,
        "folderIds": ["{{ $env.GOOGLE_DRIVE_FOLDER_ID }}"]
      },
      "position": [100, 300]
    },
    {
      "name": "Verificar Tipo Archivo",
      "type": "n8n-nodes-base.switch",
      "typeVersion": 2,
      "parameters": {
        "dataType": "string",
        "valueComparisonMode": "includes",
        "switches": {
          "cases": [
            {
              "operation": "includes",
              "value": ".pdf"
            }
          ]
        },
        "defaultOutput": "default"
      },
      "position": [300, 300]
    },
    {
      "name": "Adquirir Slot",
      "type": "n8n-nodes-base.redis",
      "typeVersion": 1,
      "parameters": {
        "operation": "incr",
        "property": "rag_concurrent_slots",
        "options": {
          "host": "={{ $env.REDIS_HOST }}",
          "port": "={{ $env.REDIS_PORT }}"
        }
      },
      "position": [500, 300]
    },
    {
      "name": "Check Límite",
      "type": "n8n-nodes-base.switch",
      "typeVersion": 2,
      "parameters": {
        "dataType": "number",
        "valueComparisonMode": "greaterThan",
        "switches": {
          "cases": [
            {
              "operation": "greaterThan",
              "value": 2
            }
          ]
        },
        "fallbackOutput": "continue"
      },
      "position": [700, 300]
    },
    {
      "name": "Esperar Slot",
      "type": "n8n-nodes-base.wait",
      "typeVersion": 1,
      "parameters": {
        "amount": 120,
        "unit": "seconds"
      },
      "position": [900, 500]
    },
    {
      "name": "OCR con Mistral",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4,
      "parameters": {
        "url": "https://api.mistral.ai/v1/ocr",
        "method": "POST",
        "sendHeaders": true,
        "headerParameters": {
          "parameters": [
            {"name": "Authorization", "value": "Bearer {{ $env.MISTRAL_API_KEY }}"}
          ]
        },
        "contentType": "multipart-form-data",
        "bodyParameters": {
          "parameters": [
            {"name": "file", "value": "={{ $json.file_url }}"},
            {"name": "model", "value": "mistral-ocr-latest"}
          ]
        },
        "options": {
          "timeout": 120000
        }
      },
      "position": [1100, 300]
    },
    {
      "name": "Indexar en Qdrant",
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "parameters": {
        "jsCode": "// Indexar en Qdrant con tenant_id\n// Ref: 06-MULTITENANCY-RULES.md#L15\n\nconst tenantId = $env.TENANT_ID;\nconst ocrText = $input.first().json.text;\nconst fileName = $input.first().json.name;\n\nconst embedding = await fetch('https://api.mistral.ai/v1/embeddings', {\n  method: 'POST',\n  headers: {\n    'Authorization': `Bearer ${$env.MISTRAL_API_KEY}`,\n    'Content-Type': 'application/json'\n  },\n  body: JSON.stringify({\n    model: 'mistral-embed',\n    inputs: [ocrText]\n  })\n}).then(r => r.json());\n\nreturn [{\n  json: {\n    id: $json.id,\n    vector: embedding.data[0].embedding,\n    payload: {\n      text: ocrText,\n      filename: fileName,\n      tenant_id: tenantId,\n      indexed_at: new Date().toISOString()\n    }\n  }\n}];"
      },
      "position": [1300, 300]
    },
    {
      "name": "Liberar Slot",
      "type": "n8n-nodes-base.redis",
      "typeVersion": 1,
      "parameters": {
        "operation": "decr",
        "property": "rag_concurrent_slots",
        "options": {
          "host": "={{ $env.REDIS_HOST }}",
          "port": "={{ $env.REDIS_PORT }}"
        }
      },
      "position": [1500, 300]
    }
  ],
  "connections": {
    "Trigger Google Drive": {
      "main": [[{"node": "Verificar Tipo Archivo", "type": "main", "index": 0}]]
    },
    "Verificar Tipo Archivo": {
      "main": [[{"node": "Adquirir Slot", "type": "main", "index": 0}]]
    },
    "Adquirir Slot": {
      "main": [[{"node": "Check Límite", "type": "main", "index": 0}]]
    },
    "Check Límite": {
      "main": [[{"node": "Esperar Slot", "type": "main", "index": 0}]],
      "fallback": [[{"node": "OCR con Mistral", "type": "main", "index": 0}]]
    },
    "Esperar Slot": {
      "main": [[{"node": "OCR con Mistral", "type": "main", "index": 0}]]
    },
    "OCR con Mistral": {
      "main": [[{"node": "Indexar en Qdrant", "type": "main", "index": 0}]]
    },
    "Indexar en Qdrant": {
      "main": [[{"node": "Liberar Slot", "type": "main", "index": 0}]]
    }
  }
}
```

### Ejemplo 3: Health Check con Auto-Scaling Artificial

**Caso de uso:** Monitoreo de salud VPS con limitación automática.

```json
{
  "name": "VPS-Health-Monitor",
  "nodes": [
    {
      "name": "Trigger Cron",
      "type": "n8n-nodes-base.scheduleTrigger",
      "typeVersion": 2,
      "parameters": {
        "rule": {
          "interval": [
            {"field": "minutes", "hours": [{"field": "minute", "minuteInterval": 5}}]
          }
        }
      },
      "position": [100, 300]
    },
    {
      "name": "Check n8n Health",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4,
      "parameters": {
        "url": "http://localhost:5678/healthz",
        "method": "GET",
        "options": {
          "timeout": 5000
        }
      },
      "position": [300, 200]
    },
    {
      "name": "Check Redis",
      "type": "n8n-nodes-base.redis",
      "typeVersion": 1,
      "parameters": {
        "operation": "ping",
        "options": {
          "host": "={{ $env.REDIS_HOST }}",
          "port": "={{ $env.REDIS_PORT }}"
        }
      },
      "position": [300, 400]
    },
    {
      "name": "Check MySQL",
      "type": "n8n-nodes-base.mySql",
      "typeVersion": 2,
      "parameters": {
        "operation": "executeQuery",
        "query": "SELECT 1",
        "options": {
          "host": "={{ $env.MYSQL_HOST }}",
          "port": "={{ $env.MYSQL_PORT }}",
          "database": "={{ $env.MYSQL_DATABASE }}"
        }
      },
      "position": [300, 600]
    },
    {
      "name": "Agregar Métricas",
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "parameters": {
        "jsCode": "// Agregar métricas de salud\nconst memoryUsage = await require('os').cpus();\nconst memUsed = process.memoryUsage();\n\nreturn [{\n  json: {\n    timestamp: new Date().toISOString(),\n    n8n_status: $input.item(0).json.status || 'unknown',\n    redis_status: $input.item(1).json.value || 'unknown',\n    mysql_status: $input.item(2).json.length > 0 ? 'ok' : 'error',\n    memory_used_mb: Math.round(memUsed.heapUsed / 1024 / 1024),\n    memory_total_mb: Math.round(memUsed.heapTotal / 1024 / 1024),\n    active_workflows: $input.item(0).json.activeExecutions || 0\n  }\n}];"
      },
      "position": [500, 400]
    },
    {
      "name": "Alertar si Crítico",
      "type": "n8n-nodes-base.switch",
      "typeVersion": 2,
      "parameters": {
        "dataType": "number",
        "valueComparisonMode": "greaterThan",
        "switches": {
          "cases": [
            {
              "operation": "greaterThan",
              "value": 1200
            }
          ]
        },
        "fallbackOutput": "default"
      },
      "position": [700, 400]
    },
    {
      "name": "Enviar Alerta Telegram",
      "type": "n8n-nodes-base.telegramBot",
      "typeVersion": 1,
      "parameters": {
        "chatId": "{{ $env.TELEGRAM_ALERT_CHAT_ID }}",
        "text": "=⚠️ ALERTA VPS\\nMemoria: {{ $json.memory_used_mb }}MB\\nWorkflows: {{ $json.active_workflows }}",
        "additionalFields": {
          "parse_mode": "Markdown"
        }
      },
      "position": [900, 600]
    }
  ],
  "connections": {
    "Trigger Cron": {
      "main": [[
        {"node": "Check n8n Health", "type": "main", "index": 0},
        {"node": "Check Redis", "type": "main", "index": 0},
        {"node": "Check MySQL", "type": "main", "index": 0}
      ]]
    },
    "Check n8n Health": {
      "main": [[{"node": "Agregar Métricas", "type": "main", "index": 0}]]
    },
    "Check Redis": {
      "main": [[{"node": "Agregar Métricas", "type": "main", "index": 0}]]
    },
    "Check MySQL": {
      "main": [[{"node": "Agregar Métricas", "type": "main", "index": 0}]]
    },
    "Agregar Métricas": {
      "main": [[{"node": "Alertar si Crítico", "type": "main", "index": 0}]]
    },
    "Alertar si Crítico": {
      "main": [[{"node": "Enviar Alerta Telegram", "type": "main", "index": 0}]]
    }
  }
}
```

### Ejemplo 4: Batch Processing con Chunking

**Caso de uso:** Procesamiento de 100+ reservas de restaurante por lote.

```json
{
  "name": "Restaurant-Booking-Batch",
  "nodes": [
    {
      "name": "Trigger Spreadsheet",
      "type": "n8n-nodes-base.googleSheetsTrigger",
      "typeVersion": 4,
      "parameters": {
        "events": ["rowAdded"],
        "documentId": "{{ $env.BOOKINGS_SHEET_ID }}"
      },
      "position": [100, 300]
    },
    {
      "name": "Split Batch",
      "type": "n8n-nodes-base.splitInBatches",
      "typeVersion": 3,
      "parameters": {
        "batchSize": 10,
        "options": {}
      },
      "position": [300, 300]
    },
    {
      "name": "Loop Over Items",
      "type": "n8n-nodes-base.splitInBatches",
      "typeVersion": 3,
      "parameters": {
        "batchSize": 1,
        "options": {
          "reset": false
        }
      },
      "position": [500, 300]
    },
    {
      "name": "Process Booking",
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "parameters": {
        "jsCode": "// Procesar reserva individual\nconst booking = $input.item().json;\n\n// Verificar disponibilidad con AI\nconst response = await fetch('https://openrouter.ai/api/v1/chat/completions', {\n  method: 'POST',\n  headers: {\n    'Authorization': `Bearer ${$env.OPENROUTER_API_KEY}`,\n    'Content-Type': 'application/json'\n  },\n  body: JSON.stringify({\n    model: 'openai/gpt-4o-mini',\n    messages: [{\n      role: 'user',\n      content: `Verificar disponibilidad para ${booking.date} às ${booking.time} para ${booking.guests} pessoas. Restaurante: ${booking.restaurant_name}`\n    }],\n    max_tokens: 50\n  })\n}).then(r => r.json());\n\nreturn [{\n  json: {\n    ...booking,\n    status: 'processed',\n    ai_response: response.choices[0].message.content,\n    processed_at: new Date().toISOString()\n  }\n}];"
      },
      "position": [700, 300]
    },
    {
      "name": "Wait Between Requests",
      "type": "n8n-nodes-base.wait",
      "typeVersion": 1,
      "parameters": {
        "amount": 2,
        "unit": "seconds"
      },
      "position": [900, 300]
    }
  ],
  "connections": {
    "Trigger Spreadsheet": {
      "main": [[{"node": "Split Batch", "type": "main", "index": 0}]]
    },
    "Split Batch": {
      "main": [[{"node": "Loop Over Items", "type": "main", "index": 0}]]
    },
    "Loop Over Items": {
      "main": [[{"node": "Process Booking", "type": "main", "index": 0}]]
    },
    "Process Booking": {
      "main": [[{"node": "Wait Between Requests", "type": "main", "index": 0}]]
    },
    "Wait Between Requests": {
      "main": [[{"node": "Loop Over Items", "type": "main", "index": 0}]]
    }
  },
  "settings": {
    "executionOrder": "v1",
    "saveDataErrorExecution": "all",
    "saveDataSuccessExecution": "none",
    "timeout": 300
  }
}
```

### Ejemplo 5: Failover con Circuit Breaker

**Caso de uso:** Redirección automática cuando Qdrant está saturado.

```json
{
  "name": "Qdrant-Circuit-Breaker",
  "nodes": [
    {
      "name": "Search Query",
      "type": "n8n-nodes-base.webhook",
      "typeVersion": 2,
      "parameters": {
        "httpMethod": "POST",
        "path": "rag-search"
      },
      "position": [100, 300]
    },
    {
      "name": "Try Qdrant Primary",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4,
      "parameters": {
        "url": "={{ $env.QDRANT_URL }}/collections/documents/points/search",
        "method": "POST",
        "contentType": "json",
        "bodyParameters": {
          "parameters": [
            {"name": "vector", "value": "={{ $json.query_vector }}"},
            {"name": "limit", "value": 5},
            {"name": "filter", "value": "{\"should\": [{\"key\": \"tenant_id\", \"match\": {\"value\": \"{{ $json.tenant_id }}\"}}}]}"}
          ]
        },
        "options": {
          "timeout": 10000,
          "onError": "continueErrorOutput"
        }
      },
      "position": [300, 200]
    },
    {
      "name": "Catch Error",
      "type": "n8n-nodes-base.errorTrigger",
      "typeVersion": 2,
      "parameters": {},
      "position": [500, 200]
    },
    {
      "name": "Try Qdrant Secondary",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4,
      "parameters": {
        "url": "={{ $env.QDRANT_SECONDARY_URL }}/collections/documents/points/search",
        "method": "POST",
        "contentType": "json",
        "bodyParameters": {
          "parameters": [
            {"name": "vector", "value": "={{ $('Search Query').item.json.query_vector }}"},
            {"name": "limit", "value": 5}
          ]
        },
        "options": {
          "timeout": 15000
        }
      },
      "position": [700, 200]
    },
    {
      "name": "Merge Results",
      "type": "n8n-nodes-base.merge",
      "typeVersion": 2,
      "parameters": {
        "mode": "multiplexer",
        "mergeType": "choose",
        "propertyName": "results"
      },
      "position": [900, 300]
    },
    {
      "name": "Record Circuit State",
      "type": "n8n-nodes-base.redis",
      "typeVersion": 1,
      "parameters": {
        "operation": "set",
        "key": "circuit_state",
        "value": "=={{ $json.success ? 'closed' : 'open' }}",
        "ttl": 300,
        "options": {
          "host": "={{ $env.REDIS_HOST }}",
          "port": "={{ $env.REDIS_PORT }}"
        }
      },
      "position": [900, 500]
    }
  ],
  "connections": {
    "Search Query": {
      "main": [[{"node": "Try Qdrant Primary", "type": "main", "index": 0}]]
    },
    "Try Qdrant Primary": {
      "main": [[{"node": "Merge Results", "type": "main", "index": 0}]],
      "error": [[{"node": "Catch Error", "type": "main", "index": 0}]]
    },
    "Catch Error": {
      "main": [[{"node": "Try Qdrant Secondary", "type": "main", "index": 0}]]
    },
    "Try Qdrant Secondary": {
      "main": [[{"node": "Merge Results", "type": "main", "index": 1}]]
    },
    "Merge Results": {
      "main": [[{"node": "Record Circuit State", "type": "main", "index": 0}]]
    }
  }
}
```

---

## 5. Problemas Habituales y Soluciones

### Problema 1: Workflows Colgados por Timeout Insuficiente

**Síntoma:** Workflows se quedan en estado "running" indefinidamente, consumiendo memoria.

**Causa raíz:** Nodos HTTP sin timeout configurado esperan respuesta indefinidamente.

**Solución:** Configurar timeouts agresivos en todos los nodos HTTP.

```bash
# Verificar workflows colgados
docker exec n8n_main n8n execute list --active

# Matar workflow colgado manualmente
docker exec n8n_main n8n execute stop --id <workflow_id>

# Script de cleanup automático
#!/bin/bash
# cleanup-stuck-workflows.sh

STUCK_MINUTES=10
WORKFLOW_IDS=$(docker exec n8n_main n8n execute list --active --json | \
    jq -r '.[] | select(.startedAt < now - '$(($STUCK_MINUTES * 60))') | .id')

for id in $WORKFLOW_IDS; do
    echo "Deteniendo workflow colgado: $id"
    docker exec n8n_main n8n execute stop --id "$id"
done
```

**Ref:** 02-RESOURCE-GUARDRAILS.md#L8 (timeout 30s por nodo)

---

### Problema 2: Memory Leak en n8n por Datos Acumulados

**Síntoma:** Uso de memoria crece progresivamente hasta agotar los 1.5GB.

**Causa raíz:** `saveDataSuccessExecution: all` guarda todos los datos de ejecución en disco.

**Solución:** Configurar saveDataSuccessExecution a "none" o "lastNodeData".

```yaml
# En workflow settings
settings:
  saveDataErrorExecution: "all"      # ✅ Mantener para debugging
  saveDataSuccessExecution: "none"   # ✅ Reducir uso de disco
  saveExecutionProgress: false         # ✅ Desactivar progresión
  saveDataManualExecutions: false     # ✅ Solo ejecuciones automáticas
```

**Script de limpieza de datos antiguos:**

```bash
#!/bin/bash
# cleanup-execution-data.sh
# Ref: 02-RESOURCE-GUARDRAILS.md

set -euo pipefail

readonly N8N_DATA_DIR="/path/to/n8n_data"
readonly DAYS_TO_KEEP=7

echo "Limpiando ejecuciones antiguas (> $DAYS_TO_KEEP días)..."

find "$N8N_DATA_DIR/execution_data" -type f -mtime +"$DAYS_TO_KEEP" -delete 2>/dev/null || true

# Mostrar espacio liberado
du -sh "$N8N_DATA_DIR/execution_data"

echo "Limpieza completada."
```

---

### Problema 3: Saturación de Redis por Cola de Mensajes

**Síntoma:** Redis usa más de 256MB de RAM, empieza a evictar keys con allkeys-lru.

**Causa raíz:** Mensajes de WhatsApp se acumulan en cola cuando n8n está lento.

**Solución:** Configurar TTL en cola y límite máximo de mensajes.

```bash
# Configuración redis optimizada
redis-server \
  --maxmemory 256mb \
  --maxmemory-policy allkeys-lru \
  --maxmemory-samples 3 \
  --activerehashing yes \
  --lazyfree-lazy-eviction yes \
  --lazyfree-lazy-expansion yes
```

```javascript
// En n8n - Configurar TTL en mensajes
const messageKey = `queue:${tenantId}:${messageId}`;

// Solo agregar si cola no está saturada
const queueLength = await redis.llen('message_queue');
if (queueLength < 100) {
  await redis.set(messageKey, JSON.stringify(message), 'EX', 3600);
  await redis.rpush('message_queue', messageKey);
} else {
  throw new Error('Cola saturada, mensaje rechazado');
}
```

---

### Problema 4: Race Condition en Semaphore

**Síntoma:** A veces más de N workflows se ejecutan simultáneamente.

**Causa raíz:** Check y set no son atómicos (TOCTOU: Time-of-check to time-of-use).

**Solución:** Usar comando SETNX atómico de Redis.

```javascript
// ❌ WRONG - Race condition
const current = await redis.get('semaphore');
if (current < MAX_CONCURRENT) {
  await redis.incr('semaphore');  // Otro proceso puede entrar aquí
}

// ✅ CORRECT - Atómico con SETNX
const acquired = await redis.set('semaphore', '1', 'NX', 'EX', 60);
if (acquired === 'OK') {
  // Ejecutar workflow
  await redis.del('semaphore');
} else {
  // Esperar y reintentar
  await new Promise(r => setTimeout(r, 1000));
}
```

```json
// Nodo Redis en n8n usando SETNX
{
  "name": "Acquire Lock",
  "type": "n8n-nodes-base.redis",
  "parameters": {
    "operation": "set",
    "key": "={{ 'semaphore_' + $json.tenant_id }}",
    "value": "={{ $json.execution_id }}",
    "ttl": 60,
    "onlySetIfNotExists": true,
    "options": {
      "host": "={{ $env.REDIS_HOST }}",
      "port": "={{ $env.REDIS_PORT }}"
    }
  }
}
```

---

### Problema 5: Backoff Insuficiente en Reintentos

**Síntoma:** Reintentos inmediatos saturan la API y empeoran el problema.

**Causa raíz:** Configuración de retry sin exponential backoff.

**Solución:** Implementar backoff exponencial con jitter.

```javascript
// Función de retry con exponential backoff
async function fetchWithRetry(url, options, maxRetries = 3) {
  const baseDelay = 1000; // 1 segundo

  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      const response = await fetch(url, options);
      if (response.ok) return response.json();

      if (attempt === maxRetries) {
        throw new Error(`Max retries exceeded for ${url}`);
      }

      // Backoff exponencial: 1s, 2s, 4s, 8s...
      const delay = baseDelay * Math.pow(2, attempt);

      // Jitter: agregar randomness ±25%
      const jitter = delay * 0.25 * (Math.random() - 0.5);
      const actualDelay = delay + jitter;

      console.log(`Retry ${attempt + 1}/${maxRetries} en ${actualDelay}ms`);
      await new Promise(r => setTimeout(r, actualDelay));

    } catch (error) {
      if (attempt === maxRetries) throw error;
    }
  }
}
```

```json
// Nodo HTTP con retry y backoff
{
  "name": "API Call with Retry",
  "type": "n8n-nodes-base.httpRequest",
  "parameters": {
    "url": "https://api.example.com/data",
    "method": "GET",
    "options": {
      "timeout": 30000,
      "retryOnTimeout": true,
      "maxRetries": 3
    }
  },
  "continueOnFail": true
}
```

```yaml
# N8N_EXECUTION_TIMEOUT con backoff en variable de entorno
EXECUTIONS_TIMEOUT=90
EXECUTIONS_RETRY: true
EXECUTIONS_RETRY_WAIT: 5000  # 5 segundos base
```

---

## 6. Checklist de Validación

| # | Verificación | Estado | Ref |
|---|--------------|--------|-----|
| 1 | Timeout global de workflow configurado (90s) | ⬜ | C2 |
| 2 | Timeout por nodo HTTP configurado (30s) | ⬜ | 02-RESOURCE-GUARDRAILS.md#L8 |
| 3 | Límite de memoria en docker-compose (1536M) | ⬜ | C1 |
| 4 | saveDataSuccessExecution = "none" | ⬜ | Problema 2 |
| 5 | Semaphore/cola con límite configurado | ⬜ | Patrón 1-2 |
| 6 | Retry con exponential backoff | ⬜ | Problema 5 |
| 7 | Health check configurado | ⬜ | Ejemplo 3 |
| 8 | Script cleanup de ejecuciones colgadas | ⬜ | Problema 1 |
| 9 | Monitoring de memoria activo | ⬜ | Patrón 4 |
| 10 | Circuit breaker en APIs externas | ⬜ | Ejemplo 5 |

---

## 7. Referencias

- **02-RESOURCE-GUARDRAILS.md:** Límites de RAM 4GB, CPU 1 vCPU, timeout 30s
- **04-API-RELIABILITY-RULES.md:** Retry con backoff, circuit breaker
- **06-MULTITENANCY-RULES.md:** Aislamiento de datos por tenant
- **docker-compose-networking.md:** Configuración de redes Docker
- **ssh-tunnels-remote-services.md:** Acceso a servicios remotos

---

**Autor:** Facundo
**Fecha creación:** 2026-04-10
**Última validación:** Pending SDD Compliance
**Versión:** 1.0.0

## 🔗 Conexiones Estructurales (Auto-generado)
[[01-RULES/02-RESOURCE-GUARDRAILS.md]]
[[01-RULES/06-MULTITENANCY-RULES.md]]
[[02-SKILLS/INFRASTRUCTURA/health-monitoring-vps.md]]
[[04-WORKFLOWS/n8n/INFRA-001-Base-Workflow.json]]
