---
title: "Gmail SMTP Integration"
category: "Comunicación"
domain: ["comunicaciones", "automatización", "email"]
constraints: ["C1", "C2", "C4", "C5", "C6"]
priority: "Alta"
version: "1.0.0"
last_updated: "2026-04-09"
ai_optimized: true
tags:
  - sdd/config/gmail
  - sdd/communication
  - sdd/email
  - lang/es
related_files:
  - "01-RULES/04-API-RELIABILITY-RULES.md"
  - "01-RULES/03-SECURITY-RULES.md"
  - "01-RULES/02-RESOURCE-GUARDRAILS.md"
  - "00-CONTEXT/facundo-infrastructure.md"
  - "02-SKILLS/COMUNICACION/telegram-bot-integration.md"
---

## 🟢 MODO JUNIOR: Guía de Inicio Rápido

### Checklist de Prerrequisitos

- [ ] Cuenta de Google con 2FA habilitado
- [ ] Acceso a https://myaccount.google.com
- [ ] Navegador para configurar OAuth2
- [ ] Acceso a VPS o servidor para instalar dependencias

### Tiempo Estimado

- **Configurar OAuth2 en Google:** 10 minutos
- **Instalar dependencias (msmtp/mutt/ssmtp):** 5 minutos
- **Configurar cliente SMTP:** 5 minutos
- **Test de envío:** 3 minutos
- **Total:** 23 minutos

### Cómo Usar Este Documento

1. **Si nunca configuraste SMTP de Gmail:** Ir a [[#ejemplo-1-configurar-oauth2-y-smtp-básico]]
2. **Si quieres enviar desde bash:** Ir a [[#ejemplo-2-enviar-email-desde-bash]]
3. **Si integras con n8n:** Ir a [[#ejemplo-3-configurar-n8n-para-email]]
4. **Si necesitas verificar entregabilidad:** Ir a [[#ejemplo-4-configurar-dkim-y-dmarc]]
5. **Si tienes errores de autenticación:** Ir a [[#ejemplo-5-solucionar-errores-comunes]]

### Qué Hacer Si Falla

| Error | Causa | Solución |
|-------|-------|----------|
| `SMTP authentication failed` | Contraseña de app incorrecta o revocada | Generar nueva contraseña de app |
| `530 5.7.1 Authentication required` | Servidor no permite relay sin auth | Configurar credenciales correctas |
| `Connection timed out` | Firewall bloqueando puerto 587 | `sudo ufw allow 587/tcp` |
| `535-5.7.8 Username and Password not accepted` | Método de auth obsoleto | Usar OAuth2 o contraseña de app |
| `Message rejected due to policy` | DMARC/SPF del destino rechaza | Verificar configuración sender |

### Glosario Rápido

| Término | Significado | Ejemplo |
|---------|-------------|---------|
| **OAuth2** | Protocolo de autorización moderno de Google | Más seguro que password |
| **App Password** | Contraseña especial para apps menos seguras | 16 caracteres sin espacios |
| **SMTP** | Protocolo para enviar emails | Puerto 587 (TLS) |
| **SPF** | Registros DNS que autorizan servidores | `v=spf1 include:_spf.google.com ~all` |
| **DKIM** | Firma digital que autentica el emisor | Selector google._domainkey |
| **DMARC** | Política que combina SPF y DKIM | `v=DMARC1; p=quarantine` |

---

## 🎯 Propósito y Alcance

### Propósito

Este documento establece el procedimiento estándar para configurar el **envío de emails via Gmail SMTP** en la infraestructura de Mantis Agentic. El objetivo es garantizar notificaciones email confiables para confirmaciones de booking, alertas de sistemas y comunicación con clientes en odontología, hoteles y restaurantes.

### Alcance

- **Usos cubiertos:** Confirmaciones de cita, alertas de health check, notificaciones de booking
- **Integraciones:** Scripts bash, n8n, Python, aplicaciones web
- **Límites Gmail:** 500 emails/día, 100 destinatarios/día (cuenta gratuita)

### Constraints Aplicadas

| Constraint | Descripción | Aplicación |
|------------|-------------|------------|
| **C1** | Máx 4GB RAM/VPS | Sin impacto en SMTP |
| **C2** | Máx 1 vCPU | Sin impacto en SMTP |
| **C4** | tenant_id obligatorio | Logs incluyen tenant_id de origen |
| **C5** | Backup diario + SHA256 | Configuraciones de email en backup |
| **C6** | Sin modelos locales | Email usa API cloud |

### Objetivos de Configuración

1. **Autenticación segura:** OAuth2 en lugar de password
2. **Deliverabilidad:** Configuración SPF, DKIM, DMARC
3. **Logging:** Auditoría de emails enviados con tenant_id
4. **Respaldo:** Configuración encriptada en backups

---

## 📐 Fundamentos (De 0 a Intermedio)

### Conceptos Básicos de Email SMTP

#### Cómo Funciona el Envío de Email

```
┌─────────────┐     SMTP (587)     ┌─────────────┐     SMTP      ┌─────────────┐
│   Tu VPS     │ ────────────────► │ Gmail SMTP  │ ────────────► │ Destinatario│
│              │    auth OAuth2     │   Server    │              │  (Cliente)  │
│  Script o    │                   │             │              │             │
│  n8n         │                   │ smtp.gmail  │              │ @gmail o    │
│              │                   │ .com        │              │ @empresa    │
└─────────────┘                   └─────────────┘              └─────────────┘
                                        │
                                        ▼
                              ┌─────────────────┐
                              │  Verificación   │
                              │  SPF + DKIM +   │
                              │  DMARC          │
                              └─────────────────┘
```

### Puertos SMTP de Gmail

| Puerto | Cifrado | Uso | Recomendación |
|--------|---------|-----|---------------|
| **587** | STARTTLS | Submission estándar | ✅ Recomendado |
| **465** | SMTPS (SSL) | Legacy | Alternativa |
| **25** | Ninguno | Bloqueado por ISPs | ❌ No usar |

### Métodos de Autenticación

| Método | Seguridad | Requisitos | Recomendación |
|--------|-----------|------------|---------------|
| **Password simple** | Baja | Solo email + password | ❌ No recomendado |
| **App Password** | Media | 2FA + password de 16 chars | ⚠️ Aceptable para scripts |
| **OAuth2** | Alta | Proyecto Google Cloud | ✅ Recomendado |

---

## 🏗️ Arquitectura y Límites de Hardware (VPS 2vCPU/4-8GB RAM)

### Flujo de Emails en Mantis Agentic

```
┌──────────────────────────────────────────────────────────────────────┐
│                        INFRAESTRUCTURA MANTIS                         │
│                                                                      │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐       │
│  │  Cliente      │     │  n8n o       │     │  VPS-2       │       │
│  │  WhatsApp    │────►│  Script      │────►│  ESPOSCRM   │       │
│  │              │     │              │     │              │       │
│  └──────────────┘     └──────┬───────┘     └──────────────┘       │
│                              │                                     │
│                    ┌─────────▼─────────┐                           │
│                    │   Email Client    │                           │
│                    │   (msmtp/mutt)    │                           │
│                    └─────────┬─────────┘                           │
│                              │                                     │
│                    ┌─────────▼─────────┐                           │
│                    │   Gmail SMTP     │                           │
│                    │   smtp.gmail.com │                           │
│                    │   Puerto 587     │                           │
│                    │   OAuth2 Auth    │                           │
│                    └─────────┬─────────┘                           │
│                              │                                     │
│                              ▼                                     │
│                    ┌─────────────────┐                             │
│                    │  📧 Destinatario│                             │
│                    │                  │                             │
│                    │  Confirmación    │                             │
│                    │  de cita/rest/   │                             │
│                    │  hotel           │                             │
│                    └─────────────────┘                             │
└──────────────────────────────────────────────────────────────────────┘
```

### Límites de Envío

| Recurso | Límite Gmail Gratuito | Gmail Workspace |
|---------|----------------------|----------------|
| Emails/día | 500 | 2000 (Basic) / 2000+ (Business) |
| Destinatarios/día | 100 | 100 (Basic) / 2000+ (Business) |
| Tamaño adjunto | 25 MB | 50 MB (Business) |
| Bandeja entrada | 15 GB | 30 GB+ |

### Configuración Recomendada para VPS 4GB RAM

```bash
# /etc/msmtprc - Configuración ligera para VPS
defaults
auth on
tls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt

account gmail
host smtp.gmail.com
port 587
from tu-email@gmail.com
user tu-email@gmail.com
passwordeval gpg2 -q --for-your-eyes-only --no-tty -d ~/.msmtp-gmail.gpg
```

---

## 🔗 Conexión Local vs Externa / Cross-VPS

### Envío Local (Desde Scripts)

```
┌─────────────────────────────────┐     SMTP/587  ┌─────────────────┐
│           VPS-X                  │ ─────────────►│  Gmail SMTP    │
│                                 │   TLS/OAuth2   │                │
│  /opt/mantis/scripts/           │               │  smtp.gmail   │
│  send-email.sh                  │               │  .com          │
│  │                              │               │                │
│  └── msmtp -t destination@email │               └───────┬────────┘
│                                 │                       │
└─────────────────────────────────┘                       ▼
                                                    ┌─────────────┐
                                                    │  Destinatario│
                                                    │  📧          │
                                                    └─────────────┘
```

### Integración n8n (Workflow de Email)

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Trigger     │────►│   Prepare    │────►│  Email Send  │
│   (Webhook)   │     │   Template   │     │  (Gmail SMTP)│
│               │     │              │     │              │
└──────────────┘     └──────────────┘     └──────────────┘
```

---

## 🛠️ 5 Ejemplos de Configuración (Copy-Paste Validables)

### EJEMPLO 1: Configurar OAuth2 y SMTP Básico

**Objetivo:** Configurar autenticación OAuth2 para Gmail con Project Google Cloud.

```bash
#!/bin/bash
# /opt/mantis/scripts/setup-gmail-oauth2.sh
# Configurar OAuth2 para Gmail SMTP

set -euo pipefail

echo "=== Configuración Gmail OAuth2 - Mantis Agentic ==="

# PASO 1: Crear Proyecto en Google Cloud Console
# 1. Ir a: https://console.cloud.google.com/
# 2. Crear proyecto nuevo: "mantis-agentic-email"
# 3. Habilitar Gmail API:
#    - Ir a APIs y Servicios > Biblioteca
#    - Buscar "Gmail API"
#    - Habilitar

# PASO 2: Configurar OAuth Consent Screen
# 1. Ir a: APIs y Servicios > Pantalla de consentimiento OAuth
# 2. Tipo: External
# 3. Nombre app: Mantis Agentic Email
# 4. Emails de prueba: agregar tu email personal

# PASO 3: Crear OAuth Client ID
# 1. Ir a: APIs y Servicios > Credenciales
# 2. Crear ID de cliente OAuth 2.0
# 3. Tipo: Aplicación de escritorio
# 4. Nombre: mantis-email-client
# 5. Descargar JSON -> guardar como ~/.gmail-oauth2/client_secret.json

# PASO 4: Generar tokens con goauth
sudo apt install golang-go -y
GO111MODULE=on go install github.com/tg/../../../go/bin/goauth@latest

# Configurar con tu client_secret.json
echo "Iniciando autenticación OAuth2..."
echo "1. Se abrirá navegador para autorizar"
echo "2. Copiar código de autorización cuando se solicite"

~/.local/bin/goauth \
  --client-id=$(jq -r '.installed.client_id' ~/.gmail-oauth2/client_secret.json) \
  --client-secret=$(jq -r '.installed.client_secret' ~/.gmail-oauth2/client_secret.json) \
  --auth-url="https://accounts.google.com/o/oauth2/auth" \
  --token-url="https://oauth2.googleapis.com/token" \
  --redirect-url="http://localhost:1"

# Guardar token
echo "Guardando token..."
echo "token" > ~/.gmail-oauth2/token.json
chmod 600 ~/.gmail-oauth2/token.json

echo "✅ OAuth2 configurado"
echo "Token guardado en ~/.gmail-oauth2/token.json"
```

**Alternativa simple (App Password):**

```bash
# Si OAuth2 es muy complejo, usar App Password
# 1. Ir a: https://myaccount.google.com/security
# 2. Activar Verificación en 2 pasos
# 3. Ir a: Contraseñas de aplicaciones
# 4. Seleccionar app: Correo
# 5. Seleccionar dispositivo: Otro (nombre personalizado)
# 6. Copiar contraseña de 16 caracteres

# Guardar en archivo seguro
echo "tu-app-password-de-16-caracteres" | gpg2 -c > ~/.gmail-app-password.gpg
chmod 600 ~/.gmail-app-password.gpg
```

✅ **Deberías ver:** Archivo de credenciales guardado

❌ **Si ves esto... → Ve a Troubleshooting 1:**
- `Error: invalid_client` → Client ID/Secret incorrectos

---

### EJEMPLO 2: Enviar Email Desde Bash

**Objetivo:** Enviar email simple usando msmtp.

```bash
#!/bin/bash
# /opt/mantis/scripts/send-email.sh

# Variables (cargar desde .env si existe)
GMAIL_USER="${GMAIL_USER:-tu-email@gmail.com}"
GMAIL_APP_PASSWORD="${GMAIL_APP_PASSWORD:-xxxx xxxx xxxx xxxx}"

# Destinatario y contenido
TO="${1:-destinatario@ejemplo.com}"
SUBJECT="${2:-Test de Email}"
BODY="${3:-Este es un mensaje de prueba desde Mantis Agentic."}"

# Función para enviar email
send_email() {
    local to="$1"
    local subject="$2"
    local body="$3"
    local tenant_id="${4:-unknown}"

    # Crear archivo temporal con email
    EMAIL_FILE=$(mktemp)

    cat > "$EMAIL_FILE" <<EOF
To: $to
From: $GMAIL_USER
Subject: $subject
Content-Type: text/plain; charset=UTF-8
X-Tenant-ID: $tenant_id
Date: $(date -R)

$body

--
Enviado desde Mantis Agentic
VPS: $(hostname)
Timestamp: $(date '+%Y-%m-%d %H:%M:%S')
EOF

    # Enviar via msmtp
    echo "$body" | msmtp \
        --host=smtp.gmail.com \
        --port=587 \
        --tls \
        --tls-starttls \
        --auth=on \
        --user="$GMAIL_USER" \
        --passwordeval="echo $GMAIL_APP_PASSWORD" \
        "$to"

    # Log de auditoría
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Email enviado: to=${to}, subject=${subject}, tenant_id=${tenant_id}" >> /var/log/mantis/email.log

    # Limpiar
    rm -f "$EMAIL_FILE"
}

# Ejemplos de uso
send_email "cliente@ejemplo.com" "Confirmación de Cita" "Su cita ha sido confirmada para mañana a las 10:00" "cliente001"
send_email "alertas@tu-dominio.com" "⚠️ Alerta VPS-1" "RAM al 85%" "sistema"
```

**Instalar msmtp:**

```bash
sudo apt update
sudo apt install msmtp msmtp-mta -y

# Configurar /etc/msmtprc
sudo tee /etc/msmtprc > /dev/null <<EOF
# Gmail SMTP configuration
defaults
auth on
tls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
tls_starttls on

account gmail
host smtp.gmail.com
port 587
from tu-email@gmail.com
user tu-email@gmail.com
passwordeval "cat ~/.gmail-app-password.gpg | gpg2 -q --decrypt"

account default : gmail
EOF

sudo chmod 600 /etc/msmtprc
```

✅ **Deberías ver:** Email recibido en la bandeja de entrada del destinatario

❌ **Si ves esto... → Ve a Troubleshooting 2:**
- `send-mail: authorization failed (534...)` → App password incorrecta o revocada

---

### EJEMPLO 3: Configurar n8n para Email

**Objetivo:** Crear workflow de n8n para enviar emails con templates.

```json
{
  "name": "Email Confirmation Workflow",
  "nodes": [
    {
      "name": "Webhook Trigger",
      "type": "n8n-nodes-base.webhook",
      "parameters": {
        "httpMethod": "POST",
        "path": "send-email-confirmation",
        "responseMode": "onReceived"
      },
      "webhookId": "email-confirmation"
    },
    {
      "name": "Set Email Data",
      "type": "n8n-nodes-base.set",
      "parameters": {
        "mode": "raw",
        "assignments": {
          "assignments": [
            {
              "name": "to",
              "value": "={{ $json.email }}"
            },
            {
              "name": "subject",
              "value": "={{ $json.tipo === 'cita' ? '✅ Confirmación de Cita - ' + $json.cliente : '✅ Reserva Confirmada' }}"
            },
            {
              "name": "tenant_id",
              "value": "={{ $json.tenant_id }}"
            }
          ]
        },
        "options": {}
      }
    },
    {
      "name": "Email Node",
      "type": "n8n-nodes-base.emailSend",
      "parameters": {
        "operation": "send",
        "to": "={{ $json.to }}",
        "subject": "={{ $json.subject }}",
        "text": "={{ $json.mensaje }}",
        "fromEmail": "={{ $env.GMAIL_USER }}",
        "credentials": {
          "smtp": {
            "id": "gmail_smtp",
            "name": "Gmail SMTP"
          }
        }
      },
      "credentials": {
        "smtp": {
          "id": "gmail_smtp",
          "name": "Gmail SMTP",
          "type": "smtp",
          "data": {
            "host": "smtp.gmail.com",
            "port": 587,
            "secure": false,
            "user": "={{ $env.GMAIL_USER }}",
            "password": "={{ $env.GMAIL_APP_PASSWORD }}"
          }
        }
      }
    },
    {
      "name": "Log to File",
      "type": "n8n-nodes-base.writeBinaryFile",
      "parameters": {
        "fileName": "/var/log/mantis/email-audit.log",
        "data": "={{ JSON.stringify($json) }}"
      }
    }
  ],
  "connections": {
    "Webhook Trigger": {
      "main": [["Set Email Data"]]
    },
    "Set Email Data": {
      "main": [["Email Node"]]
    },
    "Email Node": {
      "main": [["Log to File"]]
    }
  }
}
```

**Configurar credentials en n8n:**

```bash
# n8n > Settings > Credentials > Add SMTP

# Host: smtp.gmail.com
# Port: 587
# User: tu-email@gmail.com
# Password: tu-app-password-de-16-caracteres
# From Email: tu-email@gmail.com
```

**Llamar al webhook:**

```bash
curl -X POST "https://tu-dominio.com/webhook/send-email-confirmation" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "cliente@ejemplo.com",
    "tipo": "cita",
    "cliente": "Dr. Silva",
    "mensaje": "Su cita ha sido confirmada para el 15/04/2026 a las 10:00.\n\nGracias por confiar en nosotros.",
    "tenant_id": "clinica_silva_001"
  }'
```

✅ **Deberías ver:** Email con asunto "✅ Confirmación de Cita - Dr. Silva"

❌ **Si ves esto... → Ve a Troubleshooting 3:**
- `Email was not sent` → Credenciales incorrectas en n8n

---

### EJEMPLO 4: Configurar DKIM y DMARC

**Objetivo:** Configurar registros DNS para mejorar entregabilidad.

```bash
#!/bin/bash
# /opt/mantis/scripts/setup-email-auth.sh
# Configurar SPF, DKIM y DMARC para dominio

set -euo pipefail

DOMAIN="${1:-tu-dominio.com}"
VPS_IP="${2:-186.234.x.10}"

echo "=== Configuración de Autenticación Email ==="
echo "Dominio: $DOMAIN"
echo "VPS IP: $VPS_IP"

# NOTA: Estos cambios se hacen en el panel DNS de tu registrador
# (GoDaddy, Namecheap, Cloudflare, etc.)

echo ""
echo "=== 1. REGISTRO SPF ==="
echo "Tipo: TXT"
echo "Nombre: @"
echo "Valor:"
cat <<EOF
v=spf1 include:_spf.google.com ip4:${VPS_IP} ~all
EOF

echo ""
echo "=== 2. ACTIVAR DKIM EN GMAIL ==="
echo "1. Ir a: https://admin.google.com/ac/apps/othersettings/gmail"
echo "2. Autenticar email"
echo "3. Copiar registro TXT generado (selector: google._domainkey)"
echo ""
echo "Tipo: TXT"
echo "Nombre: google._domainkey.${DOMAIN}"
echo "Valor: (lo proporciona Google)"

echo ""
echo "=== 3. REGISTRO DMARC ==="
echo "Tipo: TXT"
echo "Nombre: _dmarc.${DOMAIN}"
echo "Valor:"
cat <<EOF
v=DMARC1; p=quarantine; rua=mailto:dmarc-reports@${DOMAIN}; pct=100
EOF

echo ""
echo "=== RESUMEN ==="
echo "SPF: Autoriza servidores de Google + tu VPS"
echo "DKIM: Firma digital de Google"
echo "DMARC: Política de cuarentena para emails no autenticados"
echo ""
echo "⚠️ Los cambios DNS pueden tardar hasta 48 horas en propagarse"
```

**Validar configuración:**

```bash
# Instalar herramientas de verificación
sudo apt install dnsutils opendkim-tools -y

# Verificar SPF
dig TXT $DOMAIN +short

# Verificar DKIM (después de configurar)
dig TXT google._domainkey.$DOMAIN +short

# Verificar DMARC
dig TXT _dmarc.$DOMAIN +short

# Test de headers de email (después de enviar)
# Recibirás los headers completos, verificar:
# Authentication-Results: spf=pass, dkim=pass, dmarc=pass
```

✅ **Deberías ver:** `dkim=pass` en los headers de emails recibidos

❌ **Si ves esto... → Ve a Troubleshooting 4:**
- `dkim=fail` → Registro DKIM no propagado o incorrecto

---

### EJEMPLO 5: Solucionar Errores Comunes

**Objetivo:** Guía de troubleshooting para errores frecuentes.

```bash
#!/bin/bash
# /opt/mantis/scripts/troubleshoot-gmail.sh
# Diagnóstico de problemas comunes

echo "=== Troubleshooting Gmail SMTP ==="

# 1. Verificar conectividad
echo ""
echo "1. Verificando conectividad a smtp.gmail.com..."
if timeout 5 nc -zv smtp.gmail.com 587 2>&1; then
    echo "✅ Conexión exitosa"
else
    echo "❌ No se puede conectar a smtp.gmail.com:587"
    echo "   Solución: Verificar firewall con sudo ufw allow 587/tcp"
fi

# 2. Verificar credenciales
echo ""
echo "2. Verificando credenciales..."
if [[ -z "${GMAIL_USER:-}" ]]; then
    echo "⚠️ GMAIL_USER no está definido"
else
    echo "✅ GMAIL_USER definido: ${GMAIL_USER}"
fi

if [[ -z "${GMAIL_APP_PASSWORD:-}" ]]; then
    echo "⚠️ GMAIL_APP_PASSWORD no está definido"
else
    echo "✅ GMAIL_APP_PASSWORD definido (長度: ${#GMAIL_APP_PASSWORD})"
fi

# 3. Test de envío simple
echo ""
echo "3. Test de envío simple..."
if command -v msmtp &> /dev/null; then
    echo "test@test.com" | msmtp --debug -v 2>&1 | head -20 || \
    echo "❌ Error en test de envío"
else
    echo "⚠️ msmtp no está instalado"
fi

# 4. Verificar logs
echo ""
echo "4. Últimos logs de email..."
if [[ -f /var/log/mantis/email.log ]]; then
    tail -10 /var/log/mantis/email.log
else
    echo "⚠️ No existe log de email"
fi

# 5. Verificar permisos
echo ""
echo "5. Verificando permisos de archivos sensibles..."
if [[ -f ~/.gmail-app-password.gpg ]]; then
    PERMS=$(stat -c %a ~/.gmail-app-password.gpg)
    if [[ "$PERMS" == "600" ]]; then
        echo "✅ Permisos correctos: $PERMS"
    else
        echo "❌ Permisos incorrectos: $PERMS (debería ser 600)"
        echo "   Solución: chmod 600 ~/.gmail-app-password.gpg"
    fi
fi
```

**Errores comunes y soluciones:**

| Error | Causa | Solución |
|-------|-------|----------|
| `SMTP authentication failed` | App password incorrecta | Regenerar en myaccount.google.com |
| `530 5.7.1 Authentication required` | Falta --auth=on | Agregar flag en msmtp |
| `Connection timed out (port 587)` | Firewall bloqueando | `sudo ufw allow 587/tcp` |
| `SSL handshake failed` | Certificados expirados | `sudo apt install ca-certificates` |
| `Message rejected` | Límite diario excedido | Esperar 24 horas o usar cuenta secundaria |

✅ **Deberías ver:** Diagnóstico completo del estado de Gmail SMTP

❌ **Si persiste el problema...**
- Revisar: https://support.google.com/mail/answer/7126229
- Verificar: https://accounts.google.com/DisplayUnlockCaptcha

---

## 🐞 5 Eventos/Problemas Críticos y Troubleshooting

| Error Exacto (copiable) | Causa Raíz (lenguaje simple) | Comando de Diagnóstico | Solución Paso a Paso | Constraint Afectado (C#) |
|------------------------|------------------------------|------------------------|---------------------|--------------------------|
| `smtp启蒙.ssl_certificate.verify')` | Certificado SSL de Gmail no verificado | `openssl s_client -connect smtp.gmail.com:587` | 1. Actualizar certificados: `sudo apt update && sudo apt install ca-certificates` 2. Verificar: `sudo update-ca-certificates` 3. En msmtp: agregar `tls_trust_file /etc/ssl/certs/ca-certificates.crt` | C4 |
| `535-5.7.8 Username and Password not accepted` | Contraseña de app vencida o auth obsoleto | `echo $GMAIL_APP_PASSWORD` | 1. Ir a myaccount.google.com/security 2. Si 2FA no está activo, activarlo 3. Ir a "Contraseñas de aplicaciones" 4. Generar nueva contraseña de 16 caracteres 5. Actualizar en .env y encriptar con gpg | C4 |
| `530 5.7.1 Authentication required` | Servidor SMTP no tiene auth habilitado | `msmtp --version` | 1. Agregar al /etc/msmtprc: `auth on` 2. Agregar: `tls_starttls on` 3. Agregar: `port 587` 4. Verificar que hay `account gmail` definido | C4 |
| `Connection refused (port 587)` | Firewall bloqueando puerto 587 | `sudo ufw status \| grep 587` | 1. Verificar estado UFW: `sudo ufw status` 2. Si bloqueado: `sudo ufw allow 587/tcp` 3. Recargar: `sudo ufw reload` 4. Verificar que no hay otro servicio en puerto 587 | C3 |
| `Message was rejected due to SPF/DKIM/DMARC policy` | Email no pasa autenticación del destino | Ver headers en email recibido | 1. Verificar SPF: `dig TXT tu-dominio.com` 2. Activar DKIM en Google Admin 3. Configurar DMARC 4. Esperar propagación DNS (24-48h) 5. Test: enviar a test@google.com | C5 |

### Troubleshooting Detallado 1: Certificado SSL

**Pasos de diagnóstico:**

```bash
# 1. Verificar conectividad SSL
openssl s_client -connect smtp.gmail.com:587 -starttls smtp 2>&1 | head -30

# 2. Verificar certificados instalados
ls -la /etc/ssl/certs/ca-certificates.crt

# 3. Actualizar certificados
sudo apt update
sudo apt install --reinstall ca-certificates
sudo update-ca-certificates

# 4. Test con curl
curl -v smtp://smtp.gmail.com:587 2>&1 | head -20
```

---

## ✅ Validación SDD y Comandos de Verificación

### Checklist de Validación

```bash
#!/bin/bash
# /opt/mantis/scripts/validate-gmail-config.sh

ERRORS=0

echo "=== Validación Gmail SMTP - Mantis Agentic ==="

# 1. Verificar variables de entorno
if [[ -z "${GMAIL_USER:-}" ]]; then
    echo "❌ GMAIL_USER no está definido"
    ERRORS=$((ERRORS+1))
else
    echo "✅ GMAIL_USER definido: ${GMAIL_USER}"
fi

if [[ -z "${GMAIL_APP_PASSWORD:-}" ]]; then
    echo "❌ GMAIL_APP_PASSWORD no está definido"
    ERRORS=$((ERRORS+1))
else
    echo "✅ GMAIL_APP_PASSWORD definido"
fi

# 2. Verificar que msmtp está instalado
if command -v msmtp &> /dev/null; then
    MSPMTP_VERSION=$(msmtp --version | head -1)
    echo "✅ msmtp instalado: ${MSMTP_VERSION}"
else
    echo "❌ msmtp no está instalado"
    ERRORS=$((ERRORS+1))
fi

# 3. Verificar conectividad
if timeout 5 nc -zv smtp.gmail.com 587 2>&1 | grep -q "succeeded"; then
    echo "✅ smtp.gmail.com:587 accesible"
else
    echo "❌ smtp.gmail.com:587 no accesible"
    ERRORS=$((ERRORS+1))
fi

# 4. Verificar archivo de configuración
if [[ -f /etc/msmtprc ]]; then
    MSPMTP_PERMS=$(stat -c %a /etc/msmtprc)
    if [[ "$MSMTP_PERMS" == "600" ]]; then
        echo "✅ /etc/msmtprc permisos correctos"
    else
        echo "⚠️ /etc/msmtprc permisos: ${MSMTP_PERMS} (recomendado 600)"
    fi
fi

# 5. Test de envío (a sí mismo)
if command -v msmtp &> /dev/null && [[ -n "${GMAIL_USER:-}" ]]; then
    echo "Enviando email de test..."
    TEST_RESULT=$(echo "Test de validación - $(date)" | msmtp "${GMAIL_USER}" 2>&1)
    if [[ $? -eq 0 ]]; then
        echo "✅ Email de test enviado exitosamente"
    else
        echo "❌ Error al enviar: ${TEST_RESULT}"
        ERRORS=$((ERRORS+1))
    fi
fi

echo ""
if [[ $ERRORS -eq 0 ]]; then
    echo "🎉 Validación Gmail: TODOS LOS CHECKS PASARON"
    exit 0
else
    echo "❌ Validación Gmail: $ERRORS ERRORES ENCONTRADOS"
    exit 1
fi
```

### Comandos de Verificación Rápida

```bash
# Verificar configuración
msmtp --version
msmtp --version | grep TLS

# Test de conexión SSL
openssl s_client -connect smtp.gmail.com:587 -starttls smtp 2>&1 | head -20

# Enviar email de prueba
echo "Test $(date)" | msmtp -v tu-email@gmail.com

# Ver logs de email
tail -50 /var/log/mantis/email.log 2>/dev/null || echo "No existe log"

# Ver estado de autenticación
curl -v smtp://smtp.gmail.com:587 2>&1 | grep -E "(AUTH|235|530)"
```

---

## 🔗 Referencias Cruzadas y Glosario

### Archivos Relacionados

| Archivo | Descripción | Relevancia |
|---------|-------------|------------|
| [[01-RULES/04-API-RELIABILITY-RULES.md]] | Timeouts y fallbacks | C4 |
| [[01-RULES/03-SECURITY-RULES.md]] | Hardening de seguridad | C4, C5 |
| [[01-RULES/02-RESOURCE-GUARDRAILS.md]] | Límites de recursos | C1, C2 |
| [[00-CONTEXT/facundo-infrastructure.md]] | Arquitectura de notificaciones | Matriz de canales |
| [[02-SKILLS/COMUNICACION/telegram-bot-integration.md]] | Canal alternativo | Telegram |

### Glosario Completo

| Término | Definición | Contexto |
|---------|------------|----------|
| **SMTP** | Simple Mail Transfer Protocol - protocolo para envío de email | Puerto 587 (TLS) |
| **OAuth2** | Protocolo de autorización moderno de Google | Más seguro que password |
| **App Password** | Contraseña especial de 16 caracteres para apps | Requiere 2FA |
| **SPF** | Sender Policy Framework - verifica servidores autorizados | `_spf.google.com` |
| **DKIM** | DomainKeys Identified Mail - firma digital | `google._domainkey` |
| **DMARC** | Domain-based Message Authentication - política combinada | `p=quarantine` |
| **msmtp** | Cliente SMTP ligero para Linux | Alternativa a sendmail |
| **STARTTLS** | Upgrade de conexión plana a cifrada | Puerto 587 |
| **MUA** | Mail User Agent - cliente de email | Thunderbird, Outlook |
| **MTA** | Mail Transfer Agent - servidor de email | Postfix, Exim |

### Variables de Entorno

```bash
# .env
GMAIL_USER="tu-email@gmail.com"
GMAIL_APP_PASSWORD="xxxx xxxx xxxx xxxx"
GMAIL_OAUTH2_CLIENT_ID="tu-client-id.apps.googleusercontent.com"
GMAIL_OAUTH2_CLIENT_SECRET="tu-secret"
```

### URLs Raw para IAs

```
Base: https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/

https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/02-SKILLS/COMUNICACION/gmail-smtp-integration.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/01-RULES/04-API-RELIABILITY-RULES.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/00-CONTEXT/facundo-infrastructure.md
```

---

**Versión 1.0.0 - 2026-04-09 - Mantis-AgenticDev**
**Licencia:** Creative Commons para uso interno del proyecto
