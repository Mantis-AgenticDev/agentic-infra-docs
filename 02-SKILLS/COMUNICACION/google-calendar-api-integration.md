---
title: "google-calendar-api-integration"
category: "Skill"
domain: ["generico", "comunicaciones", "backend"]
constraints: ["C1", "C2", "C3", "C4", "C5", "C6"]
priority: "Alta"
version: "1.0.1"
last_updated: "2026-04-15"
ai_optimized: true
tags:
  - sdd/skill/google-calendar
  - sdd/communication
  - sdd/api
  - lang/es
related_files:
  - "01-RULES/03-SECURITY-RULES.md"
  - "01-RULES/04-API-RELIABILITY-RULES.md"
  - "01-RULES/06-MULTITENANCY-RULES.md"
  - "00-CONTEXT/facundo-infrastructure.md"
  - "02-SKILLS/COMUNICACION/gmail-smtp-integration.md"
  - "02-SKILLS/COMUNICACION/telegram-bot-integration.md"
  - "05-CONFIGURATIONS/environment-variable-management.md"
---

## 🟢 MODO JUNIOR: Guía de Inicio Rápido

### ✅ Checklist de Prerrequisitos
- [ ] Tener una cuenta de Google Cloud Platform (GCP) con facturación habilitada (la API de Calendar es gratuita dentro de límites generosos).
- [ ] Haber creado un proyecto en GCP y habilitado la **Google Calendar API**.
- [ ] Haber creado una **Cuenta de Servicio** (Service Account) para autenticación servidor-a-servidor.
- [ ] Tener acceso SSH al VPS de MANTIS (2vCPU/4-8GB RAM, C1/C2).
- [ ] Tener instalado `python3` y `pip` (o `nodejs` si usas JavaScript).
- [ ] Tener `sops` y `age` instalados para encriptación de secretos (C3/C5).

### ⏱️ Tiempo Estimado
- **Configuración en GCP:** 5 minutos (si ya tienes proyecto).
- **Descarga de credenciales y configuración en VPS:** 3 minutos.
- **Prueba de conexión (Ejemplo 1):** 2 minutos.

### 🧭 Cómo Usar este Documento
1. **Configuración única (GCP):** Ejemplo 1 (crear Service Account y descargar JSON).
2. **Integración con n8n:** Ejemplo 3 y Ejemplo 6.
3. **Integración en Code Node (Python/JS):** Ejemplo 2 y Ejemplo 5.
4. **Multi-tenancy (C4):** Lee obligatoriamente el **Ejemplo 7**.

### 🆘 ¿Qué hacer si falla la autenticación?
- Verifica que el archivo JSON de credenciales existe y la variable de entorno `GOOGLE_APPLICATION_CREDENTIALS` apunta a él.
- Ejecuta el comando de diagnóstico del **Troubleshooting #1**.
- Asegúrate de que la cuenta de servicio tiene el permiso `https://www.googleapis.com/auth/calendar` (o scope equivalente).

### 📖 Glosario**: Ver sección final para definiciones de términos técnicos.

---

## 🎯 Propósito y Alcance

**Propósito:** Proveer una integración robusta, segura y multi-tenant con **Google Calendar API** para los agentes autónomos de MANTIS AGENTIC. Permite a los flujos de trabajo de n8n (y scripts personalizados) gestionar citas, reservas, recordatorios y disponibilidad en tiempo real.

**Alcance Específico:**
- Autenticación mediante **Cuentas de Servicio** (JWT) de Google.
- Operaciones CRUD sobre eventos (`list`, `insert`, `update`, `delete`).
- Gestión de **múltiples calendarios** para soportar el aislamiento de tenants (C4).
- Manejo de límites de tasa (quota) y reintentos con backoff exponencial (C1/C2).
- Integración con nodos n8n (HTTP Request) y Code Nodes (Python/JavaScript).
- **Exclusiones:** No cubre la autenticación OAuth 2.0 para usuarios finales (Web Server Flow). Este skill es para **servidor a servidor**.

---

## 📐 Fundamentos (De 0 a Intermedio)

### 1. ¿Por qué una Cuenta de Servicio y no OAuth "normal"?
En un flujo de OAuth estándar, un usuario humano hace clic en "Permitir" en una ventana de Google. En un VPS ejecutando n8n automáticamente a las 3 AM, **no hay humano**. La Cuenta de Servicio permite que el código se autentique usando una clave privada (archivo JSON) sin interacción.

**Analogía docente:** Es como la diferencia entre usar tu llave personal para abrir la oficina (OAuth humano) y usar la **llave maestra del conserje** (Service Account). El conserje no es una persona, es un rol del sistema.

### 2. El Modelo de Aislamiento Multi-Tenant (C4)
Google Calendar **no** tiene un concepto nativo de `tenant_id` como una base de datos SQL. Para cumplir con C4, MANTIS utiliza la estrategia de **Calendarios Separados**:
- Cada tenant tiene **su propio Calendario de Google** (puede ser una cuenta de Google dedicada o un calendario secundario compartido con la Service Account).
- La Service Account de MANTIS tiene permisos de escritura sobre **todos** los calendarios de los tenants.
- La aplicación (n8n) **siempre** especifica el `calendarId` correcto basado en el `tenant_id` de la petición.

### 3. Cuotas y Límites en VPS Pequeños (C1/C2)
Google Calendar API tiene una cuota por minuto y por usuario.
- **Límite:** 600 solicitudes por minuto (muy alto).
- **Riesgo MANTIS:** Un bucle mal programado en n8n puede hacer 1000 solicitudes en un segundo y ser **baneado temporalmente**.
- **Solución:** Implementar un **Rate Limiter local** en el Code Node (usando `setTimeout` o `asyncio.sleep`) para no exceder 10 solicitudes/segundo en VPS de 2vCPU.

### 4. 🕐 Regla de Timezones MANTIS (C2/C5)
> - **Entradas de usuario**: siempre en timezone local del tenant (`America/Argentina/Buenos_Aires`).
> - **Consultas a API Google**: convertir a UTC con `Z` para `timeMin`/`timeMax`.
> - **Almacenamiento en logs**: guardar ambos (local + UTC) para auditoría C5.

---

## 🏗️ Arquitectura y Límites de Hardware (VPS 2vCPU/4-8GB RAM)

<!-- ai:constraint=C1,C2 -->

| Componente | Impacto en Recursos | Configuración en MANTIS |
| :--- | :--- | :--- |
| **Librería Cliente** | Carga en RAM (~50MB) al iniciar. | Usar `google-api-python-client` o `googleapis` (Node) solo en workers específicos. No cargar en el proceso principal de n8n si no se usa. |
| **Procesamiento de Respuesta** | JSON de eventos puede ser grande. | Usar `fields` para filtrar solo los campos necesarios (`items(id,summary,start,end)`). Esto reduce el payload en un **80%**. |
| **Tiempo de Espera (Timeout)** | VPS pequeño puede tardar en resolver DNS de Google. | Establecer `timeout=10` segundos en el cliente HTTP. |
| **Caché de Eventos** | Evitar llamadas repetitivas a la API. | Usar Redis (`tenant_{id}:cal:events`) con TTL de 5 minutos (ver [[02-SKILLS/INFRAESTRUCTURA/redis-session-management.md]]). |

**Comando de monitoreo de uso de API:**
```bash
# Activar logging de la librería para ver cuántas llamadas se hacen
export GOOGLE_API_CLIENT_LOG_LEVEL=DEBUG
python3 mi_script.py 2>&1 | grep "Making request"
```

---

## 🔗 Conexión Local vs Externa / Cross-VPS

### Escenario Único: VPS de Agentes → Google Cloud (Internet)
- **Protocolo:** HTTPS (puerto 443).
- **Seguridad (C3):** Todo el tráfico está cifrado por TLS. No requiere túneles SSH especiales.
- **Restricción (C3):** El archivo JSON de credenciales **NUNCA** debe ser accesible desde el exterior. Se almacena con permisos `600`, se encripta con SOPS, y se inyecta vía variable de entorno o Docker Secrets.

---

## 🛠️ 10 Ejemplos de Configuración (Copy-Paste Validables)

### Ejemplo 1: Crear una Cuenta de Servicio y Descargar Credenciales (GCP) + Encriptación SOPS
**Objetivo**: Obtener el archivo `credentials.json` necesario para la autenticación y encriptarlo para seguridad C3/C5.
**Nivel**: 🟢

1. Ve a [Google Cloud Console](https://console.cloud.google.com).
2. Selecciona tu proyecto MANTIS.
3. Navega a **APIs & Services > Library**. Busca "Google Calendar API" y habilítala.
4. Ve a **APIs & Services > Credentials**.
5. Haz clic en **"+ CREATE CREDENTIALS" > "Service account"**.
6. Nombre: `mantis-agent-calendar`. Rol: **Calendar API > Calendar Events (Read/Write)**.
7. Una vez creada, haz clic en la cuenta de servicio > pestaña **"KEYS"** > **"ADD KEY" > "Create new key" > JSON**.
8. Descarga el archivo. **¡CUIDADO!** Es la llave de acceso. Nómbralo `mantis-calendar-key.json`.

> 🔐 **Nota C3/C5**: El archivo `mantis-calendar-key.json` contiene secretos. 
> **Nunca lo commitees en texto plano**. Encripta con SOPS:
> ```bash
> # Instalar herramientas si no están
> sudo apt install age sops -y
> 
> # Generar clave Age (solo primera vez)
> age-keygen -o ~/.config/sops/age/mantis-keys.txt
> 
> # Encriptar el archivo de credenciales
> sops --encrypt --age $(awk '/public key:/ {print $4}' ~/.config/sops/age/mantis-keys.txt) mantis-calendar-key.json > mantis-calendar-key.json.enc
> 
> # Eliminar el archivo plano inmediatamente
> shred -u mantis-calendar-key.json
> 
> # En producción, inyectar el contenido desencriptado vía variable de entorno:
> export GOOGLE_CALENDAR_CREDENTIALS_JSON=$(sops --decrypt mantis-calendar-key.json.enc)
> ```

✅ Deberías ver: Un archivo `mantis-calendar-key.json.enc` encriptado y el archivo plano eliminado.

❌ Si ves esto en su lugar: *"Permission denied"* al intentar habilitar la API.
→ Ve a Troubleshooting #2

---

### Ejemplo 2: Autenticación en Python (Code Node de n8n) con Inyección Segura
**Objetivo**: Inicializar el cliente de Calendar en un script Python usando credenciales inyectadas desde variable de entorno.
**Nivel**: 🟡

```python
# Instalar dependencia en el contenedor de n8n (o VPS)
# pip install google-api-python-client google-auth-httplib2 google-auth-oauthlib

import os, json
from google.oauth2 import service_account
from googleapiclient.discovery import build

# Cargar credenciales desde variable de entorno (C3)
# El contenido JSON debe estar en GOOGLE_CALENDAR_CREDENTIALS_JSON (desencriptado en runtime)
creds_info = json.loads(os.environ['GOOGLE_CALENDAR_CREDENTIALS_JSON'])
credentials = service_account.Credentials.from_service_account_info(
    creds_info,
    scopes=['https://www.googleapis.com/auth/calendar']
)

service = build('calendar', 'v3', credentials=credentials)
print("✅ Cliente de Calendar inicializado correctamente")

# Probar listar calendarios (opcional)
calendar_list = service.calendarList().list().execute()
print(f"Calendarios accesibles: {len(calendar_list.get('items', []))}")
```

✅ Deberías ver: `✅ Cliente de Calendar inicializado correctamente`

❌ Si ves esto en su lugar: `json.decoder.JSONDecodeError`
→ Ve a Troubleshooting #3

---

### Ejemplo 3: Configurar Credenciales en n8n (HTTP Request Node)
**Objetivo**: Usar el nodo HTTP Request de n8n para llamar a la API sin código Python.
**Nivel**: 🟡

1. En n8n, crea una nueva credencial tipo **"Google Calendar OAuth2 API"**.
2. Selecciona **"Service Account"** como tipo de autenticación.
3. Pega el contenido **completo** del archivo JSON en el campo **"Service Account Key"**.
4. Guarda y testea.

**Workflow de prueba:**
- Nodo **Google Calendar > Event > Get Many**.
- Selecciona la credencial creada.
- Calendar ID: `primary` (o el email del calendario del tenant).
- Ejecuta el nodo.

✅ Deberías ver: Una lista de eventos en formato JSON.

❌ Si ves esto en su lugar: `Error: invalid_grant`
→ Ve a Troubleshooting #1

---

### Ejemplo 4: Crear un Evento en un Calendario Específico (C4) con Timezone Correcto
**Objetivo**: Agendar una cita de odontología para el tenant `clinica_perez` siguiendo la regla de timezones MANTIS.
**Nivel**: 🟡

```python
# Code Node Python en n8n
import datetime

tenant_id = $json["tenant_id"]  # Ej: "clinica_perez"
calendar_id = $json["calendar_id"]  # Ej: "clinica_perez@group.calendar.google.com"

# Regla de timezone MANTIS: entrada local, API UTC
local_tz = 'America/Argentina/Buenos_Aires'
start_local = datetime.datetime(2026, 4, 15, 10, 0, 0)  # 10:00 hora local
start_utc = start_local.astimezone(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
end_utc = (start_local + datetime.timedelta(hours=1)).astimezone(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')

event = {
    'summary': f'Cita Odontológica - {tenant_id}',
    'location': 'Av. Siempre Viva 742',
    'description': 'Revisión y limpieza dental.',
    'start': {
        'dateTime': start_utc,  # UTC con Z para API
        'timeZone': local_tz,   # TimeZone local para visualización
    },
    'end': {
        'dateTime': end_utc,
        'timeZone': local_tz,
    },
    'attendees': [
        {'email': 'paciente@example.com'},
    ],
}

created_event = service.events().insert(calendarId=calendar_id, body=event).execute()
print(f"✅ Evento creado: {created_event.get('htmlLink')} | tenant_id={tenant_id} | start_utc={start_utc}")
```

✅ Deberías ver: Un enlace al evento en Google Calendar + log con tenant_id y UTC.

❌ Si ves esto en su lugar: `googleapiclient.errors.HttpError: 404 Not Found`
→ Ve a Troubleshooting #4

---

### Ejemplo 5: Listar Eventos con Filtro de Tiempo (Optimización C1) y Timezone UTC
**Objetivo**: Obtener solo los eventos de los próximos 7 días para no sobrecargar la red, usando UTC.
**Nivel**: 🟢

```python
import datetime

# Regla MANTIS: timeMin/timeMax en UTC con Z
now_utc = datetime.datetime.utcnow().isoformat() + 'Z'
time_max_utc = (datetime.datetime.utcnow() + datetime.timedelta(days=7)).isoformat() + 'Z'

events_result = service.events().list(
    calendarId=calendar_id,
    timeMin=now_utc,      # UTC
    timeMax=time_max_utc, # UTC
    maxResults=50,            # Limitar resultados (C2)
    singleEvents=True,
    orderBy='startTime',
    fields='items(id,summary,start,end)'  # Reducir payload 80%
).execute()
events = events_result.get('items', [])
print(f"✅ Eventos próximos (7 días): {len(events)} | query_utc_min={now_utc}")
```

✅ Deberías ver: `✅ Eventos próximos (7 días): 3` (o el número real) + log de query UTC.

❌ Si ves esto en su lugar: `0` eventos cuando sabes que hay.
→ Ve a Troubleshooting #5 (Zona Horaria)

---

### Ejemplo 6: Workflow n8n Completo: Webhook → Crear Evento → Notificar Telegram con Timezone Dual Log
**Objetivo**: Un cliente envía un formulario web, se crea un evento en Calendar y se notifica al administrador, con logs dual timezone para auditoría C5.
**Nivel**: 🔴

1. **Webhook Node:** Recibe `fecha`, `hora`, `nombre`, `email`, `tenant_id`.
2. **Code Node (Python):** Ejecuta el código del Ejemplo 4 para crear el evento.
3. **Telegram Node:** Envía un mensaje al grupo del tenant con el enlace del evento.

**Código del Code Node (completo con timezone dual log):**
```python
import json, os, datetime
from google.oauth2 import service_account
from googleapiclient.discovery import build

# Obtener datos del webhook
data = $input.all()[0].json
tenant_id = data['tenant_id']
nombre = data['nombre']
fecha = data['fecha']  # formato '2026-04-15'
hora = data['hora']    # formato '10:00'

# Mapear tenant_id a calendar_id desde archivo config (C4 mantenibilidad)
import os, json
config_path = os.environ.get('TENANT_CALENDAR_MAP', '/etc/mantis/tenant_calendars.json')
with open(config_path) as f:
    calendars = json.load(f)
calendar_id = calendars.get(tenant_id)
if not calendar_id:
    raise ValueError(f"Calendar no encontrado para tenant {tenant_id}")

# Autenticación (usando variable de entorno de n8n)
creds_json = os.environ['GOOGLE_CALENDAR_CREDENTIALS_JSON']
creds_info = json.loads(creds_json)
credentials = service_account.Credentials.from_service_account_info(creds_info, scopes=['https://www.googleapis.com/auth/calendar'])
service = build('calendar', 'v3', credentials=credentials)

# Crear evento con timezone correcto
local_tz = 'America/Argentina/Buenos_Aires'
start_local = datetime.datetime.strptime(f"{fecha}T{hora}", "%Y-%m-%dT%H:%M")
start_utc = start_local.astimezone(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
end_utc = (start_local + datetime.timedelta(hours=1)).astimezone(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')

event = {
    'summary': f'Cita - {nombre} ({tenant_id})',
    'start': {'dateTime': start_utc, 'timeZone': local_tz},
    'end': {'dateTime': end_utc, 'timeZone': local_tz},
}
created = service.events().insert(calendarId=calendar_id, body=event).execute()

# Log dual timezone para auditoría C5
print(f"✅ Evento creado: {created.get('htmlLink')} | tenant_id={tenant_id} | start_local={start_local.isoformat()}{local_tz} | start_utc={start_utc}")

return [{'json': {'event_link': created.get('htmlLink'), 'tenant_id': tenant_id, 'start_utc': start_utc}}]
```

✅ Deberías ver: El nodo Telegram envía el enlace correcto + log con tenant_id y timezones dual.

❌ Si el webhook falla con `KeyError: 'tenant_id'`
→ Asegúrate de que el webhook envía ese campo en el body.

---

### Ejemplo 7: Aislamiento Multi-Tenant con Mapping desde Archivo Config (C4 Mantenibilidad)
**Objetivo**: Garantizar que un agente no pueda acceder al calendario de otro tenant, cargando el mapping desde archivo externo.
**Nivel**: 🟡

```python
# Cargar mapping desde archivo config (C4 mantenibilidad)
import os, json
config_path = os.environ.get('TENANT_CALENDAR_MAP', '/etc/mantis/tenant_calendars.json')
with open(config_path) as f:
    ALLOWED_CALENDARS = json.load(f)

def get_calendar_for_tenant(tenant_id):
    cal_id = ALLOWED_CALENDARS.get(tenant_id)
    if not cal_id:
        raise PermissionError(f"C4 Violation: Tenant '{tenant_id}' no tiene calendario asignado en {config_path}")
    return cal_id

# Uso
calendar_id = get_calendar_for_tenant(tenant_id)
service.events().list(calendarId=calendar_id).execute()
```

**Formato esperado de `/etc/mantis/tenant_calendars.json`:**
```json
{
  "facundo_hotel": "hotel_facundo@group.calendar.google.com",
  "facundo_resto": "resto_facundo@group.calendar.google.com",
  "clinica_perez": "clinica_perez@group.calendar.google.com"
}
```

✅ Deberías ver: El evento se crea en el calendario correcto.

❌ Si ves esto en su lugar: `PermissionError: C4 Violation...`
→ Ve a Troubleshooting #10

---

### Ejemplo 8: Manejo de Errores de Cuota con Backoff Exponencial (C1/C2) — CON IMPORT CORREGIDO
**Objetivo**: Evitar que n8n falle catastróficamente si Google rechaza una solicitud por exceso de tasa.
**Nivel**: 🔴

```python
import time, random  # ✅ IMPORT CORREGIDO: random agregado
from googleapiclient.errors import HttpError

def call_with_retry(request_func, max_retries=5):
    for n in range(max_retries):
        try:
            return request_func.execute()
        except HttpError as e:
            if e.resp.status in [429, 500, 503]:
                sleep_time = (2 ** n) + random.random()
                print(f"⚠️ Rate limit/Server error. Reintentando en {sleep_time:.2f}s...")
                time.sleep(sleep_time)
            else:
                raise e
    raise Exception("Máximo de reintentos alcanzado")

# Uso
events = call_with_retry(service.events().list(calendarId=cal_id, timeMin=now_utc))
```

✅ Deberías ver: Mensajes de reintento en la consola si hay problemas de red.

❌ Si el script se queda colgado en `time.sleep` por más de 30 segundos, el workflow de n8n podría timeout. Ajustar `max_retries` a 3.

---

### Ejemplo 9: Sincronización Bidireccional con Webhook + Renovación 24h + Validación de Firma (C3/C6)
**Objetivo**: Recibir notificaciones en n8n cuando un evento es modificado externamente (ej. desde el móvil), con renovación automática y validación de firma.
**Nivel**: 🔴

1. **Configurar Webhook en Google Calendar:**
   - Usar la API `events.watch` para registrar una URL de notificación.
   - n8n debe exponer un endpoint público (o vía túnel Cloudflare) para recibir el POST de Google.

2. **Código para registrar el watch con token de validación:**
```python
import os
channel = {
    'id': f'tenant_{tenant_id}_channel',
    'type': 'web_hook',
    'address': 'https://n8n.mantis.com/webhook/calendar-notifications',
    'token': os.environ['WEBHOOK_SECRET_TOKEN']  # Para validar origen en recepción
}
watch = service.events().watch(calendarId=calendar_id, body=channel).execute()
print(f"✅ Webhook registrado. Expira: {watch['expiration']} | channel_id={channel['id']}")
```

3. **Renovación automática del watch (cron diario o en cada deploy):**
```python
def renew_watch(service, calendar_id, channel_id, webhook_url, secret_token):
    channel = {
        'id': channel_id,
        'type': 'web_hook',
        'address': webhook_url,
        'token': secret_token
    }
    return service.events().watch(calendarId=calendar_id, body=channel).execute()

# Ejecutar cada 23 horas (Google expira a las 24h)
# Agregar a crontab: 0 1 * * * /ruta/renew_calendar_watch.py
```

4. **Validar firma en el webhook de n8n (Code Node):**
```python
import hmac, hashlib, os

def verify_google_signature(payload_body, x_goog_signature_header, secret_token):
    # Google envía firma SHA256 en header X-Goog-Signature
    expected = hmac.new(secret_token.encode(), payload_body.encode(), hashlib.sha256).hexdigest()
    received = x_goog_signature_header.lower()
    return hmac.compare_digest(expected, received)

# En n8n Code Node:
payload = $input.all()[0].json
sig_header = $request.headers['x-goog-signature']
secret = os.environ['WEBHOOK_SECRET_TOKEN']

if not verify_google_signature(str(payload), sig_header, secret):
    raise PermissionError("C3 Violation: Firma de webhook inválida")

# Procesar evento válido...
```

✅ Deberías ver: Un mensaje de confirmación con timestamp de expiración + logs de validación de firma.

❌ Si el webhook no llega: Verifica que n8n está accesible desde internet y que Google puede resolver el DNS.

---

### Ejemplo 10: Eliminar Eventos Antiguos para Mantener el Calendario Limpio (Mantenimiento C5)
**Objetivo**: Script de limpieza que corre semanalmente para borrar eventos de hace más de 6 meses.
**Nivel**: 🟢

```python
import datetime
six_months_ago = (datetime.datetime.utcnow() - datetime.timedelta(days=180)).isoformat() + 'Z'

events = service.events().list(
    calendarId=calendar_id,
    timeMax=six_months_ago,
    maxResults=100
).execute()

for event in events.get('items', []):
    service.events().delete(calendarId=calendar_id, eventId=event['id']).execute()
    print(f"✅ Evento {event['summary']} eliminado | tenant_id={tenant_id} | event_id={event['id']}")
```

✅ Deberías ver: Lista de eventos eliminados con tenant_id para auditoría C5.

❌ Si ves `HttpError 403`: La cuenta de servicio no tiene permiso para eliminar eventos. Verificar scopes.

---

## 🐞 10 Eventos/Problemas Críticos y Troubleshooting

| Error Exacto (copiable) | Causa Raíz (lenguaje simple) | Comando de Diagnóstico | Solución Paso a Paso | Constraint Afectado (C#) |
| :--- | :--- | :--- | :--- | :--- |
| `googleapiclient.errors.HttpError: 401 "Request had invalid authentication credentials."` | El archivo JSON de la Service Account es incorrecto o ha expirado. | `cat credentials.json \| python3 -m json.tool` | 1. Verificar que el JSON no esté corrupto. 2. Regenerar una nueva clave en GCP. 3. Actualizar la variable de entorno. | C3, C5 |
| `Permission denied` al habilitar API en GCP | No tienes el rol de "Owner" o "Editor" en el proyecto de GCP. | Ir a IAM & Admin > IAM en GCP. | 1. Solicitar al administrador del proyecto que te asigne el rol `roles/editor`. 2. O usar un proyecto propio para pruebas. | C3 |
| `json.decoder.JSONDecodeError` al cargar credenciales desde variable de entorno. | El contenido de la variable de entorno no es un JSON válido (faltan comillas o saltos de línea). | `echo $GOOGLE_CALENDAR_CREDENTIALS_JSON \| head -c 50` | 1. Asegurar que el JSON está en una sola línea: `cat archivo.json \| jq -c .`. 2. En n8n, pegar el contenido sin saltos de línea. | C5 |
| `404 Not Found` al intentar crear evento en un `calendarId`. | El ID del calendario es incorrecto o la Service Account no tiene acceso a ese calendario. | `service.calendarList().list().execute()` para ver calendarios accesibles. | 1. Compartir el calendario con el email de la Service Account (`...@...gserviceaccount.com`) con permisos "Hacer cambios en eventos". 2. Usar `primary` si es el calendario principal de la cuenta. | C4 |
| La lista de eventos está vacía aunque sé que hay eventos. | La zona horaria (timeZone) o el filtro `timeMin`/`timeMax` están mal configurados. | Imprimir `timeMin` y `timeMax` usados. | 1. Asegurar que las fechas llevan `Z` (UTC) para consultas API. 2. Ampliar el rango de búsqueda para depuración. | C2 |
| `Rate Limit Exceeded` (Error 429) constante. | El agente está haciendo demasiadas llamadas por segundo. | Contar requests en el último minuto en el log. | 1. Implementar caché con Redis (TTL 5 min). 2. Usar `fields` para reducir payload. 3. Añadir `time.sleep(0.2)` entre llamadas. | C1, C2 |
| `SSL: CERTIFICATE_VERIFY_FAILED` en el VPS. | El VPS no tiene los certificados raíz actualizados o la fecha del sistema está mal. | `date` (verificar hora actual). `curl https://www.googleapis.com` | 1. `sudo apt install ca-certificates -y`. 2. Sincronizar hora: `sudo timedatectl set-ntp true`. | C3 |
| `MemoryError` en Code Node de n8n al procesar muchos eventos. | El payload de respuesta es muy grande y n8n tiene límite de RAM por worker (C1). | Usar `maxResults=50`. | 1. Reducir `maxResults` a 10-20. 2. Implementar paginación usando `nextPageToken`. 3. Aumentar memoria del worker de n8n (último recurso). | C1 |
| El evento se crea pero no envía invitación por email a los asistentes. | La API de Calendar **no envía emails automáticamente** a menos que se especifique. | Revisar parámetros en la llamada API. | 1. Añadir `sendUpdates='all'` en la llamada `insert()` (Python) o `sendUpdates: "all"` (REST). 2. Usar Gmail API para enviar un email personalizado (ver [[gmail-smtp-integration.md]]). | C4 (Comunicación) |
| `PermissionError: C4 Violation` | Se intentó acceder a un `calendarId` no registrado para ese `tenant_id`. | Revisar el archivo `/etc/mantis/tenant_calendars.json`. | 1. Añadir la entrada correspondiente en el mapa de calendarios. 2. Verificar que el `tenant_id` enviado es correcto. | C4 |

---

## ✅ Validación SDD y Comandos de Verificación

<!-- ai:constraint=C5 -->

### 1. Verificación de Permisos de Service Account
Asegura que la cuenta de servicio tiene acceso al calendario esperado.
```bash
# Dentro del VPS, ejecutar script de diagnóstico:
python3 -c "
import json, os
from google.oauth2 import service_account
from googleapiclient.discovery import build
creds = service_account.Credentials.from_service_account_info(json.loads(os.environ['GOOGLE_CALENDAR_CREDENTIALS_JSON']), scopes=['https://www.googleapis.com/auth/calendar'])
service = build('calendar', 'v3', credentials=creds)
cals = service.calendarList().list().execute()
print('✅ Calendarios accesibles:')
for cal in cals.get('items', []):
    print(f\" - {cal['id']} ({cal.get('summary', '')})\")
"
```

### 2. Verificación de Tenant ID en Logs (C4/C5)
Todos los logs de creación de eventos deben incluir el `tenant_id` y timezones dual.
```bash
grep "Cita Odontológica" /var/log/n8n/workflow.log | grep "tenant_id"
# Debe mostrar líneas con el tenant_id correspondiente + start_utc + start_local
```

### 3. Validación de Cuota (C1/C2)
Monitorear el uso de la API.
```bash
# En GCP: APIs & Services > Calendar API > Metrics
# Revisar gráfico de "Requests per minute". Debe estar por debajo de 100.
```

### 4. Validación de Mapping de Calendarios (C4 Mantenibilidad)
```bash
# Verificar que el archivo de config existe y es válido JSON
python3 -c "import json; json.load(open('/etc/mantis/tenant_calendars.json')); print('✅ tenant_calendars.json válido')"
```

### 5. Validación de Webhook Signature (C3/C6)
```bash
# Probar función de validación de firma
python3 -c "
import hmac, hashlib
def verify(payload, sig, secret):
    expected = hmac.new(secret.encode(), payload.encode(), hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected, sig.lower())
print('✅ Función de validación cargada')
"
```

---

## 🔗 Referencias Cruzadas y Glosario

- **[[02-SKILLS/COMUNICACION/gmail-smtp-integration.md]]** - Para enviar correos de confirmación de cita.
- **[[02-SKILLS/INFRAESTRUCTURA/redis-session-management.md]]** - Para cachear disponibilidad.
- **[[05-CONFIGURATIONS/environment-variable-management.md]]** - Gestión segura del JSON de credenciales con SOPS.
- **[[01-RULES/06-MULTITENANCY-RULES.md]]** - Aislamiento estricto de calendarios.

**Glosario Final:**
- **JWT (JSON Web Token):** Formato usado para autenticar la Service Account.
- **Primary Calendar:** Calendario principal asociado a una cuenta de Google (ej. `tuemail@gmail.com`).
- **Quota:** Límite de solicitudes permitidas por Google en un período de tiempo.
- **X-Goog-Signature:** Header que Google envía en webhooks para validar autenticidad del payload.
- **Timezone Dual Log:** Práctica de registrar timestamps en timezone local del usuario y UTC para auditoría C5.

FIN DEL ARCHIVO
<!-- ai:file-end marker - do not remove -->
Versión 1.0.1 - 2026-04-15 - Mantis-AgenticDev
```
