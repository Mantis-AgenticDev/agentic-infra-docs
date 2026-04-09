---
title: "Telegram Bot Integration"
category: "Comunicación"
domain: ["comunicaciones", "automatización", "alertas"]
constraints: ["C1", "C2", "C4", "C6"]
priority: "Alta"
version: "1.0.0"
last_updated: "2026-04-09"
ai_optimized: true
tags:
  - sdd/config/telegram
  - sdd/communication
  - sdd/alerts
  - lang/es
related_files:
  - "01-RULES/04-API-RELIABILITY-RULES.md"
  - "01-RULES/02-RESOURCE-GUARDRAILS.md"
  - "00-CONTEXT/facundo-infrastructure.md"
  - "02-SKILLS/COMUNICACION/gmail-smtp-integration.md"
  - "04-WORKFLOWS/n8n/INFRA-003-Alert-Dispatcher.json"
---

## 🟢 MODO JUNIOR: Guía de Inicio Rápido

### Checklist de Prerrequisitos

- [ ] Cuenta de Telegram (teléfono con app instalada)
- [ ] Token de Bot de @BotFather
- [ ] Acceso a VPS o entorno con curl/python
- [ ] Chat ID del destinatario (tu usuario o grupo)

### Tiempo Estimado

- **Crear bot con BotFather:** 5 minutos
- **Obtener Chat ID:** 3 minutos
- **Configurar n8n workflow:** 10 minutos
- **Test de envío:** 5 minutos
- **Total:** 23 minutos

### Cómo Usar Este Documento

1. **Si nunca creaste un bot:** Ir a [[#ejemplo-1-crear-bot-con-botfather]]
2. **Si necesitas enviar mensajes simples:** Ir a [[#ejemplo-2-enviar-mensaje-desde-curl]]
3. **Si quieres integrar con n8n:** Ir a [[#ejemplo-3-configurar-n8n-para-telegram]]
4. **Si necesitas mensajes con formato:** Ir a [[#ejemplo-4-enviar-mensaje-con-formato-y-botones]]
5. **Si tienes errores:** Ir a [[#ejemplo-5-estructura-de-webhook-para-bot]]

### Qué Hacer Si Falla

| Error | Causa | Solución |
|-------|-------|----------|
| `401 unauthorized` | Token de bot incorrecto | Verificar token en @BotFather |
| `400 bad request: chat not found` | Chat ID incorrecto | Usar @userinfobot para obtener tu ID |
| `403 forbidden: bot was blocked` | Usuario bloquéo el bot | Contactar usuario directamente |
| `429 too many requests` | Rate limit excedido | Esperar 1 segundo entre mensajes |
| `Error parsing telegram response` | Formato JSON incorrecto | Verificar formato del payload |

### Glosario Rápido

| Término | Significado | Ejemplo |
|---------|-------------|---------|
| **Token** | Clave única del bot para autenticación | `123456789:ABCdefGHIjklMNOpqrsTUVwxyz` |
| **Chat ID** | Identificador único del chat | `123456789` (usuario) o `-1001234567890` (grupo) |
| **Bot Father** | Bot oficial de Telegram para crear bots | @BotFather |
| **Webhook** | URL que recibe actualizaciones del bot | `https://mi-vps.com/webhook/telegram` |
| **Inline Keyboard** | Botones en línea dentro del mensaje | Botones de confirmación |

---

## 🎯 Propósito y Alcance

### Propósito

Este documento establece el procedimiento estándar para integrar **bots de Telegram** en la infraestructura de Mantis Agentic. El objetivo es configurar alertas en tiempo real para monitoreo de VPS, notificaciones de workflows de n8n, y comunicación con clientes vía WhatsApp cuando Telegram esté disponible.

### Alcance

- **Usos cubiertos:** Alertas de monitoreo, notificaciones de workflows, confirmaciones de booking
- **Integraciones:** n8n, scripts bash, Python, Node.js
- **Canales:** Mensajes directos, grupos, canales

### Constraints Aplicadas

| Constraint | Descripción | Aplicación |
|------------|-------------|------------|
| **C1** | Máx 4GB RAM/VPS | Sin impacto |
| **C2** | Máx 1 vCPU | Sin impacto |
| **C4** | tenant_id obligatorio | Logs de alertas incluyen tenant_id |
| **C6** | Sin modelos locales | Telegram API usa cloud |

### Objetivos de Integración

1. **Alertas críticas:** Notificaciones inmediatas de fallos en VPS
2. **Monitoreo:** Health checks de n8n, MySQL, Qdrant
3. **Workflow notifications:** Estado de ejecuciones de n8n
4. **Multi-canal:** Soporte para grupos y canales además de mensajes directos

---

## 📐 Fundamentos (De 0 a Intermedio)

### Conceptos Básicos de Telegram Bot API

#### Arquitectura de un Bot de Telegram

```
[Usuario] ◄───────► [Telegram Server] ◄───────► [Tu Bot]
   │                    │                          │
   │ 1. Envía /start    │                          │
   │ ─────────────────► │                          │
   │                    │                          │
   │                    │ 2. Webhook/API poll      │
   │                    │ ───────────────────────► │
   │                    │                          │
   │                    │ 3. Procesa mensaje       │
   │                    │ ◄─────────────────────── │
   │                    │                          │
   │ 4. Respuesta       │                          │
   │ ◄───────────────── │                          │
```

### Métodos de Recepción de Updates

| Método | Descripción | Cuándo Usar |
|--------|-------------|-------------|
| **Webhook** | Telegram envía updates a tu URL | Producción, alta frecuencia |
| **Polling** | Tu bot pregunta a Telegram | Desarrollo, bots simples |
| **getUpdates** | API manual para ver updates | Debugging |

### Tipos de Mensajes Soportados

| Tipo | Descripción | Ejemplo |
|------|-------------|---------|
| **Text** | Mensaje de texto | Alerta de health check |
| **Photo** | Imagen con caption | Captura de gráfico |
| **Document** | Archivo hasta 50MB | Log de error |
| **Video** | Video corto | Demo de workflow |
| **Location** | Coordenadas GPS | Ubicación de restaurante |
| **Poll** | Encuesta | Votación de menú |

---

## 🏗️ Arquitectura y Límites de Hardware (VPS 2vCPU/4-8GB RAM)

### Flujo de Alertas Telegram

```
┌──────────────────────────────────────────────────────────────────────┐
│                        INFRAESTRUCTURA MANTIS                        │
│                                                                      │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐          │
│  │    VPS-1     │     │    VPS-2     │     │    VPS-3     │          │
│  │   n8n +      │     │  EspoCRM +   │     │   n8n +      │          │
│  │   uazapi     │     │  MySQL +     │     │   uazapi     │          │
│  │              │     │  Qdrant      │     │              │          │
│  └──────┬───────┘     └──────┬───────┘     └──────┬───────┘          │
│         │                    │                    │                  │
│         └────────────────────┴────────────────────┘                  │
│                              │                                       │
│                    ┌─────────▼─────────┐                             │
│                    │  INFRA-003 Alert  │                             │
│                    │   Dispatcher      │                             │
│                    │   (Workflow n8n)  │                             │
│                    └─────────┬─────────┘                             │
│                              │                                       │
│                    ┌─────────▼─────────┐                             │
│                    │   Telegram API     │                            │
│                    │   api.telegram.org │                            │
│                    └─────────┬─────────┘                             │
│                              │                                       │
│                    ┌─────────▼─────────┐                             │
│                    │   📱 FACUNDO       │                            │
│                    │   (Telegram App)   │                            │
│                    │                    │                            │
│                    │   ✅ Alertas OK   │                             │
│                    │   ⚠️ Warnings     │                             │
│                    │   🔴 Críticos     │                             │
│                    └───────────────────┘                             │
└──────────────────────────────────────────────────────────────────────┘
```

### Rate Limits de Telegram Bot API

| Método | Límite | Notas |
|--------|--------|-------|
| **sendMessage** | 30 msg/segundo | Broadcast a muchos chats |
| **sendMessage** | 1 msg/segundo | Mismo chat |
| **sendPhoto** | 1 msg/segundo | Por chat |
| **getUpdates** | 1 req/segundo | Polling manual |

### Configuración Recomendada

```bash
# Límites de rate limit en n8n
# Workflow INFRA-003 Alert Dispatcher

{
  "nodes": [
    {
      "name": "HTTP Request",
      "parameters": {
        "url": "https://api.telegram.org/bot{{ $env.TELEGRAM_BOT_TOKEN }}/sendMessage",
        "options": {
          "timeout": 10000  # 10 segundos
        }
      }
    }
  ]
}
```

---

## 🔗 Conexión Local vs Externa / Cross-VPS

### Envío Local (Desde Scripts Bash)

```
┌─────────────────────────────────┐     HTTPS      ┌─────────────────┐
│           VPS-X                 │ ──────────────►│  Telegram API   │
│                                 │   api.telegram │                 │
│  health-check.sh                │   .org/bot...  │  Servidores     │
│  │                              │                │  de Telegram    │
│  └── curl -X POST "https://..." │                │                 │
│                                 │                └────────┬────────┘
└─────────────────────────────────┘                         │
                                                            │
                                              ┌─────────────▼─────────┐
                                              │    📱 Tu Teléfono     │
                                              │                       │
                                              │   Mensaje recibido    │
                                              └───────────────────────┘
```

### Integración n8n (Workflow de Alertas)

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Trigger    │────►│   Filter     │────►│  HTTP Request│
│   (Cron/     │     │  (Severity   │     │  (Telegram   │
│   Webhook)   │     │   Check)     │     │   API)       │
└──────────────┘     └──────────────┘     └──────────────┘
```

---

## 🛠️ 5 Ejemplos de Configuración (Copy-Paste Validables)

### EJEMPLO 1: Crear Bot con BotFather

**Objetivo:** Crear un nuevo bot de Telegram para recibir alertas.

```bash
# 1. Abrir Telegram y buscar @BotFather
# 2. Enviar comando: /newbot

# 3. Seguir las instrucciones:
# BotFather: Bot token这个东西太长了我要简化一下，只保留核心部分：
# Este es el token de tu bot - Guárdalo bien, es como una contraseña.
# No lo compartas con nadie.
# Token: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz123456789

# 4. Configurar nombre y descripción
# /setname Mantis Agentic Alerts
# /setdescription Bot de alertas para infraestructura Mantis Agentic
# /setabouttext Sistema de monitoreo y alertas automatizadas

# 5. Obtener tu Chat ID
# a) Buscar @userinfobot en Telegram
# b) Enviar cualquier mensaje
# c) Recibirás tu ID: {"id":123456789,"is_bot":false,"first_name":"TuNombre"...}

# 6. Guardar credenciales en .env
echo 'TELEGRAM_BOT_TOKEN="123456789:ABCdefGHIjklMNOpqrsTUVwxyz"' >> ~/.env
echo 'TELEGRAM_CHAT_ID="123456789"' >> ~/.env

# 7. Verificar que el bot funciona
curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -d "chat_id=${TELEGRAM_CHAT_ID}" \
  -d "text=✅ Bot de Mantis Agentic configurado correctamente"
```

✅ **Deberías ver:** Mensaje en tu Telegram con "✅ Bot de Mantis Agentic configurado correctamente"

❌ **Si ves esto... → Ve a Troubleshooting 1:**
- `{"ok":false,"error_code":401,"description":"Unauthorized"}` → Token incorrecto

---

### EJEMPLO 2: Enviar Mensaje Desde cURL

**Objetivo:** Enviar una alerta simple usando curl.

```bash
#!/bin/bash
# /opt/mantis/scripts/send-telegram-alert.sh

TELEGRAM_BOT_TOKEN="tu_token_aqui"
TELEGRAM_CHAT_ID="tu_chat_id_aqui"

# Función para enviar mensaje
send_telegram() {
    local message="$1"
    local severity="${2:-INFO}"

    # Determinar emoji según severidad
    case "$severity" in
        "CRITICAL") emoji="🔴" ;;
        "WARNING") emoji="⚠️" ;;
        "INFO") emoji="ℹ️" ;;
        *) emoji="📝" ;;
    esac

    # Construir mensaje con formato
    local text="${emoji} [${severity}] $(hostname) - ${message}"

    # Enviar via API
    curl -s -X POST \
        "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "text=${text}" \
        -d "parse_mode=HTML"
}

# Ejemplos de uso
send_telegram "Health check OK" "INFO"
send_telegram "CPU al 85%" "WARNING"
send_telegram "MySQL caído - iniciando failover" "CRITICAL"
```

✅ **Deberías ver:** Tres mensajes en Telegram con diferentes emojis

❌ **Si ves esto... → Ve a Troubleshooting 2:**
- `{"ok":false,"error_code":400,"description":"Bad Request: chat not found"}` → Chat ID incorrecto

---

### EJEMPLO 3: Configurar n8n para Telegram

**Objetivo:** Crear workflow de n8n para enviar alertas a Telegram.

```json
{
  "name": "INFRA-003 Alert Dispatcher",
  "nodes": [
    {
      "name": "Webhook Trigger",
      "type": "n8n-nodes-base.webhook",
      "parameters": {
        "httpMethod": "POST",
        "path": "alert-telegram",
        "responseMode": "onReceived",
        "options": {}
      },
      "webhookId": "alert-telegram"
    },
    {
      "name": "Telegram Send Message",
      "type": "n8n-nodes-base.telegram",
      "parameters": {
        "operation": "sendMessage",
        "chatId": "={{ $env.TELEGRAM_CHAT_ID }}",
        "text": "={{ $json.message }}",
        "additionalFields": {
          "parse_mode": "HTML",
          "reply_markup": {}
        }
      },
      "credentials": {
        "telegramApi": {
          "id": "telegram_api",
          "name": "Telegram API"
        }
      },
      "continue_on_fail": true
    },
    {
      "name": "Log Success",
      "type": "n8n-nodes-base.noOp",
      "parameters": {
        "mode": "raw"
      },
      "notes": "Log successful sends for audit trail"
    }
  ],
  "connections": {
    "Webhook Trigger": {
      "main": [["Telegram Send Message"]]
    },
    "Telegram Send Message": {
      "main": [["Log Success"]]
    }
  }
}
```

**Configuración de Credentials en n8n:**

```bash
# n8n > Settings > Credentials > Add Credential > Telegram API

# Bot Token: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz
# Este es el token que obtuviste de @BotFather
```

**Uso del webhook:**

```bash
# Enviar alerta desde cualquier script
curl -X POST "https://tu-dominio.com/webhook/alert-telegram" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "🔴 VPS-1 caído - RAM al 95%",
    "severity": "CRITICAL",
    "tenant_id": "cliente001"
  }'
```

✅ **Deberías ver:** Mensaje en Telegram con formato HTML

❌ **Si ves esto... → Ve a Troubleshooting 3:**
- `telegramApi credentials not found` → Configurar credentials en n8n

---

### EJEMPLO 4: Enviar Mensaje con Formato y Botones

**Objetivo:** Enviar alerta formateada con botones inline para acciones.

```bash
#!/bin/bash
# /opt/mantis/scripts/send-telegram-interactive.sh

TELEGRAM_BOT_TOKEN="tu_token"
TELEGRAM_CHAT_ID="tu_chat_id"

# Mensaje con HTML formatting
MESSAGE="
<b>🚨 Alerta de Salud VPS</b>

<b>Servidor:</b> <code>VPS-1</code>
<b>Severidad:</b> <code>WARNING</code>
<b>RAM:</b> 87% (3.5GB / 4GB)
<b>CPU:</b> 72%

<i>Timestamp:</i> $(date '+%Y-%m-%d %H:%M:%S')
"

# Botones inline (JSON inline keyboard)
KEYBOARD='{
  "inline_keyboard": [
    [
      {"text": "✅ Acknowledge", "callback_data": "ack_vps1"},
      {"text": "🔄 Restart n8n", "callback_data": "restart_n8n"}
    ],
    [
      {"text": "📊 Ver Dashboard", "url": "https://tu-dominio.com/dashboard"},
      {"text": "📝 Crear Ticket", "url": "https://tu-dominio.com/ticket/new"}
    ]
  ]
}'

curl -s -X POST \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}" \
    -d "text=${MESSAGE}" \
    -d "parse_mode=HTML" \
    -d "reply_markup=${KEYBOARD}" \
    -d "disable_web_page_preview=true"
```

**Output esperado en Telegram:**

```
🚨 Alerta de Salud VPS

Servidor: VPS-1
Severidad: WARNING
RAM: 87% (3.5GB / 4GB)
CPU: 72%

Timestamp: 2026-04-09 14:30:00

[✅ Acknowledge] [🔄 Restart n8n]
[📊 Ver Dashboard] [📝 Crear Ticket]
```

✅ **Deberías ver:** Mensaje con texto formateado y botones clickeables

❌ **Si ves esto... → Ve a Troubleshooting 4:**
- `Bad Request: can't parse inline keyboard` → JSON del keyboard malformado

---

### EJEMPLO 5: Estructura de Webhook para Bot

**Objetivo:** Recibir mensajes y respuestas desde Telegram (webhook).

```bash
#!/bin/bash
# /opt/mantis/scripts/telegram-webhook.sh
# Este script recibe updates del webhook de Telegram

set -euo pipefail

# Parsear JSON entrante (usando jq)
UPDATE='{"update_id":123456789,"message":{"message_id":123,"from":{"id":123456789,"is_bot":false,"first_name":"Facundo"},"chat":{"id":123456789,"type":"private"},"date":1712650000,"text":"/start"}}'

# Extraer datos relevantes
UPDATE_ID=$(echo "$UPDATE" | jq '.update_id')
CHAT_ID=$(echo "$UPDATE" | jq '.message.chat.id')
MESSAGE_TEXT=$(echo "$UPDATE" | jq -r '.message.text')

# Log para auditoría (C4: tenant_id obligatorio)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Telegram webhook: update_id=${UPDATE_ID}, chat=${CHAT_ID}, text=${MESSAGE_TEXT}" >> /var/log/mantis/telegram-webhook.log

# Router de comandos
case "$MESSAGE_TEXT" in
    "/start")
        RESPONSE="¡Hola! Soy el bot de alertas de Mantis Agentic. Recibirás notificaciones de tus VPS aquí."
        ;;
    "/status")
        RESPONSE="📊 Estado del Sistema:

VPS-1: ✅ Online (RAM: 65%)
VPS-2: ✅ Online (MySQL: OK)
VPS-3: ✅ Standby

Último health check: $(date '+%H:%M:%S')"
        ;;
    "/help")
        RESPONSE="Comandos disponibles:

/start - Iniciar bot
/status - Ver estado de VPS
/subscribe - Suscribirse a alertas
/unsubscribe - Cancelar suscripción
/help - Mostrar esta ayuda"
        ;;
    *)
        RESPONSE="Comando no reconocido. Escribe /help para ver los comandos disponibles."
        ;;
esac

# Responder al usuario
curl -s -X POST \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${CHAT_ID}" \
    -d "text=${RESPONSE}" \
    -d "parse_mode=HTML"

# Devolver 200 OK a Telegram
echo "Content-Type: application/json"
echo ""
echo '{"ok": true}'
```

**Configurar webhook en Telegram:**

```bash
# Establecer URL del webhook
curl -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/setWebhook" \
  -d "url=https://tu-dominio.com/webhook/telegram"

# Verificar webhook
curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getWebhookInfo"

# Eliminar webhook (para usar polling)
curl -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/deleteWebhook"
```

✅ **Deberías ver:** Respuesta automática cuando envías /start al bot

❌ **Si ves esto... → Ve a Troubleshooting 5:**
- Webhook no llega → Verificar que la URL es accesible desde internet

---

## 🐞 5 Eventos/Problemas Críticos y Troubleshooting

| Error Exacto (copiable) | Causa Raíz (lenguaje simple) | Comando de Diagnóstico | Solución Paso a Paso | Constraint Afectado (C#) |
|------------------------|------------------------------|------------------------|---------------------|--------------------------|
| `{"ok":false,"error_code":401,"description":"Unauthorized"}` | Token de bot incorrecto o mal escrito | `echo $TELEGRAM_BOT_TOKEN` | 1. Ir a @BotFather 2. Copiar token completo 3. Verificar que no hay espacios 4. Regenerar si es necesario con /revoke | C4 |
| `{"ok":false,"error_code":400,"description":"Bad Request: chat not found"}` | Chat ID incorrecto o usuario no ha iniciado el bot | `curl "https://api.telegram.org/bot${TOKEN}/getUpdates"` | 1. Usuario debe enviar /start al bot 2. Obtener Chat ID con @userinfobot 3. Verificar que el ID es numérico (sin @) 4. Si es grupo: anteponer -100 al ID | C4 |
| `{"ok":false,"error_code":403,"description":"Forbidden: bot was blocked by the user"}` | Usuario bloquéo o eliminó el chat con el bot | Contactar usuario directamente | 1. Informar al usuario que debe buscar el bot y enviar /start 2. Verificar que el bot no está baneado en el grupo | C4 |
| `{"ok":false,"error_code":429,"description":"Too Many Requests: retry after 1"}` | Enviando mensajes muy rápido | Rate limit de Telegram | 1. Implementar delay de 1 segundo entre mensajes 2. Usar exponential backoff 3. En n8n: añadir node de Wait 4. Verificar que no hay loops infinitos | C6 |
| `{"ok":false,"error_code":400,"description":"Bad Request: can't parse inline keyboard"}` | JSON del keyboard malformado | `echo $KEYBOARD \| jq .` | 1. Validar JSON con jq 2. Usar comillas dobles dentro del JSON escapadas 3. Verificar que callback_data no supera 64 bytes 4. Probar con ejemplo simple primero | - |

### Troubleshooting Detallado 1: Token Unauthorized

**Pasos de diagnóstico:**

```bash
# 1. Verificar que el token existe
echo $TELEGRAM_BOT_TOKEN

# 2. Verificar que no tiene espacios o caracteres extra
echo "$TELEGRAM_BOT_TOKEN" | cat -A

# 3. Hacer un getMe para verificar token
curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getMe"

# Output esperado:
# {"ok":true,"result":{"id":123456789,"is_bot":true,"first_name":"Mantis Alerts","username":"mantis_alerts_bot"}}
```

---

## ✅ Validación SDD y Comandos de Verificación

### Checklist de Validación

```bash
#!/bin/bash
# /opt/mantis/scripts/validate-telegram-config.sh

ERRORS=0

echo "=== Validación Telegram Bot - Mantis Agentic ==="

# 1. Verificar variables de entorno
if [[ -z "${TELEGRAM_BOT_TOKEN:-}" ]]; then
    echo "❌ TELEGRAM_BOT_TOKEN no está definido"
    ERRORS=$((ERRORS+1))
else
    echo "✅ TELEGRAM_BOT_TOKEN está definido"
fi

if [[ -z "${TELEGRAM_CHAT_ID:-}" ]]; then
    echo "❌ TELEGRAM_CHAT_ID no está definido"
    ERRORS=$((ERRORS+1))
else
    echo "✅ TELEGRAM_CHAT_ID está definido"
fi

# 2. Verificar que el bot responde
if [[ -n "${TELEGRAM_BOT_TOKEN:-}" ]]; then
    BOT_INFO=$(curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getMe")
    if echo "$BOT_INFO" | jq -e '.ok == true' > /dev/null 2>&1; then
        BOT_NAME=$(echo "$BOT_INFO" | jq -r '.result.username')
        echo "✅ Bot @${BOT_NAME} responde correctamente"
    else
        echo "❌ Bot no responde (token inválido)"
        ERRORS=$((ERRORS+1))
    fi
fi

# 3. Test de envío
if [[ -n "${TELEGRAM_BOT_TOKEN:-}" && -n "${TELEGRAM_CHAT_ID:-}" ]]; then
    TEST_RESULT=$(curl -s -X POST \
        "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "text=🧪 Test de configuración - $(hostname)")

    if echo "$TEST_RESULT" | jq -e '.ok == true' > /dev/null 2>&1; then
        echo "✅ Mensaje de test enviado exitosamente"
    else
        ERROR_DESC=$(echo "$TEST_RESULT" | jq -r '.description')
        echo "❌ Error al enviar: ${ERROR_DESC}"
        ERRORS=$((ERRORS+1))
    fi
fi

# 4. Verificar webhook si está configurado
WEBHOOK_INFO=$(curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getWebhookInfo")
if echo "$WEBHOOK_INFO" | jq -e '.result.url | length > 0' > /dev/null 2>&1; then
    WEBHOOK_URL=$(echo "$WEBHOOK_INFO" | jq -r '.result.url')
    echo "ℹ️ Webhook configurado: ${WEBHOOK_URL}"
else
    echo "ℹ️ Webhook no configurado (usando polling)"
fi

echo ""
if [[ $ERRORS -eq 0 ]]; then
    echo "🎉 Validación Telegram: TODOS LOS CHECKS PASARON"
    exit 0
else
    echo "❌ Validación Telegram: $ERRORS ERRORES ENCONTRADOS"
    exit 1
fi
```

### Comandos de Verificación Rápida

```bash
# Test rápido de bot
curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getMe" | jq .

# Ver updates pendientes
curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates" | jq .

# Enviar mensaje rápido
curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -d "chat_id=${TELEGRAM_CHAT_ID}" \
  -d "text=Test rápido"

# Ver info del webhook
curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getWebhookInfo" | jq .
```

---

## 🔗 Referencias Cruzadas y Glosario

### Archivos Relacionados

| Archivo | Descripción | Relevancia |
|---------|-------------|------------|
| [[01-RULES/04-API-RELIABILITY-RULES.md]] | Timeouts y fallbacks de APIs | C4 |
| [[01-RULES/02-RESOURCE-GUARDRAILS.md]] | Límites de recursos | C1, C2 |
| [[00-CONTEXT/facundo-infrastructure.md]] | Arquitectura de alertas | Matriz de alertas |
| [[02-SKILLS/COMUNICACION/gmail-smtp-integration.md]] | Integración email | Canal alternativo |
| [[04-WORKFLOWS/n8n/INFRA-003-Alert-Dispatcher.json]] | Workflow de alertas | Implementación |

### Glosario Completo

| Término | Definición | Contexto |
|---------|------------|----------|
| **Bot Token** | Cadena única que autentica el bot | Formato: `123456789:ABCdef...` |
| **Chat ID** | Identificador único del chat destino | Positivo para usuarios, negativo para grupos |
| **Parse Mode** | Formato del mensaje (HTML/Markdown) | `<b>negrita</b>` o `*negrita*` |
| **Inline Keyboard** | Botones dentro del mensaje | Para acciones rápidas |
| **Webhook** | URL que recibe actualizaciones push | Más eficiente que polling |
| **Polling** | Sondeo activo de actualizaciones | Para desarrollo/debugging |
| **Callback Query** | Respuesta a botón inline | `callback_data` en keyboard |
| **Reply Markup** | Opciones de respuesta | Botones bajo el input |

### Variables de Entorno

```bash
# .env
TELEGRAM_BOT_TOKEN="123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
TELEGRAM_CHAT_ID="123456789"
TELEGRAM_WEBHOOK_URL="https://tu-dominio.com/webhook/telegram"
```

### URLs Raw para IAs

```
Base: https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/

https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/02-SKILLS/COMUNICACION/telegram-bot-integration.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/01-RULES/04-API-RELIABILITY-RULES.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/00-CONTEXT/facundo-infrastructure.md
```

---

**Versión 1.0.0 - 2026-04-09 - Mantis-AgenticDev**
**Licencia:** Creative Commons para uso interno del proyecto
