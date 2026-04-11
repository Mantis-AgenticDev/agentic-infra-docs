---
title: "google-sheets-as-database"
category: "Skill"
domain: ["generico", "backend", "database", "rag", "multi-tenant"]
constraints: ["C1", "C2", "C3", "C4", "C5", "C6"]
priority: "Alta"
version: "1.0.0"
last_updated: "2026-04-10"
ai_optimized: true
tags:
  - sdd/skill/google-sheets
  - sdd/skill/database
  - sdd/skill/multi-tenant
  - sdd/skill/n8n
  - sdd/skill/hoteles
  - sdd/skill/restaurantes
  - sdd/skill/rag
  - lang/es
related_files:
  - "01-RULES/06-MULTITENANCY-RULES.md"
  - "01-RULES/02-RESOURCE-GUARDRAILS.md"
  - "01-RULES/04-API-RELIABILITY-RULES.md"
  - "00-CONTEXT/facundo-infrastructure.md"
  - "02-SKILLS/BASE DE DATOS-RAG/mysql-sql-rag-ingestion.md"
  - "02-SKILLS/BASE DE DATOS-RAG/rag-system-updates-all-engines.md"
  - "02-SKILLS/RESTAURANTES/restaurant-booking-ai.md"
  - "02-SKILLS/HOTELES-POSADAS/hotel-receptionist-whatsapp.md"
  - "02-SKILLS/COMUNICACION/gmail-smtp-integration.md"
---

## 🎯 Propósito y Alcance

Google Sheets como **base de datos operativa** para agentes MANTIS AGENTIC en clientes sin infraestructura propia (sin VPS, sin servidor dedicado). Es el motor de persistencia para verticales de restaurantes, hoteles y odontología cuando el cliente solo tiene una cuenta Google Workspace.

**Cuándo usar Google Sheets como BD (árbol de decisión):**

```
Cliente nuevo solicitando agente WhatsApp
         │
         ▼
¿Tiene VPS propio o contratado?
         │
    No ──┴── Sí → usar MySQL/Qdrant (ver mysql-sql-rag-ingestion.md)
         │
         ▼
¿Volumen esperado de registros?
         │
    < 5.000/mes ──┬── > 5.000/mes → Supabase (ver supabase-rag-integration.md)
         │        │
         │        └── > 50.000/mes → MySQL obligatorio
         ▼
¿Necesita búsqueda semántica RAG?
         │
    No ──┴── Sí → Google Sheets + Qdrant cloud (híbrido)
         │
         ▼
✅ Google Sheets como BD principal
   (reservas, menú, pacientes, pedidos)
```

**Casos de uso cubiertos:**
- Reservas de restaurante (mesas, horarios, contactos)
- Gestión de huéspedes de hotel/posada (check-in, check-out, preferencias)
- Agenda de citas odontológicas (pacientes, tratamientos, fechas)
- Catálogo de menú con precios dinámicos
- Seguimiento de pedidos y delivery
- Pipeline de leads desde WhatsApp
- Pre-mensajes de llegada para hoteles
- Base de conocimiento simple (FAQs sin vectorización)
- Historial de conversaciones por cliente
- Billing y consumo por tenant

**Límites técnicos que el developer DEBE conocer:**

| Límite | Valor | Consecuencia si se supera |
|---|---|---|
| Celdas por hoja | 10.000.000 | API retorna error 429/500 |
| Requests API/minuto | 300 por proyecto | Throttling silencioso |
| Requests API/minuto/usuario | 60 | Error 429 |
| Tamaño de respuesta | 10MB por request | Timeout en n8n |
| Filas por hoja recomendado | 10.000 | Degradación de performance |
| Hojas por spreadsheet | 200 | Límite de organización |
| Columnas por hoja | 18.278 (ZZZ) | Límite de columnas |

**Fuera de alcance:**
- Búsqueda semántica vectorial (usar Qdrant)
- Transacciones ACID (usar MySQL/PostgreSQL)
- Joins complejos entre hojas (usar MySQL)
- Datos de más de 50.000 registros/mes (usar Supabase)
- Información médica sensible con LGPD estricta (usar Supabase con RLS)

---

## 📐 Fundamentos (Nivel Básico)

### Google Sheets como BD: Modelo Mental

```
Base de datos relacional          Google Sheets equivalente
─────────────────────────         ─────────────────────────
Base de datos          ←→         Spreadsheet (archivo)
Tabla                  ←→         Hoja (Sheet/Tab)
Fila                   ←→         Row (fila numerada)
Columna                ←→         Column (A, B, C...)
PRIMARY KEY            ←→         Columna A con UUID o timestamp
tenant_id              ←→         Columna B — SIEMPRE presente (C4)
INDEX                  ←→         No existe → filtrar en código
FK (foreign key)       ←→         Columna con ID referenciado
SELECT                 ←→         sheets.values.get()
INSERT                 ←→         sheets.values.append()
UPDATE                 ←→         sheets.values.update() en fila específica
DELETE                 ←→         sheets.values.clear() + reorganizar
```

### Estructura de Spreadsheet por Vertical

```
Spreadsheet: "MANTIS_restaurante_001"
│
├── Sheet: "reservas"
│   A: id | B: tenant_id | C: fecha | D: hora | E: nombre
│   F: telefono | G: personas | H: mesa | I: estado | J: notas
│
├── Sheet: "menu"
│   A: id | B: tenant_id | C: categoria | D: item | E: precio
│   F: disponible | G: descripcion | H: imagen_url
│
├── Sheet: "clientes"
│   A: id | B: tenant_id | C: telefono | D: nombre | E: email
│   F: visitas | G: ultima_visita | H: preferencias
│
├── Sheet: "pedidos"
│   A: id | B: tenant_id | C: cliente_id | D: items_json
│   E: total | F: estado | G: created_at | H: canal
│
└── Sheet: "config"
    A: clave | B: valor | C: tenant_id | D: updated_at
    (horarios, capacidad, mensajes, configuración del agente)
```

### Autenticación: Service Account vs OAuth

```
Service Account (RECOMENDADO para n8n/backend):
├── No requiere usuario humano logueado
├── Funciona 24/7 sin expiración de sesión
├── Un service account puede acceder a múltiples spreadsheets
└── El spreadsheet debe estar compartido con el email del SA

OAuth (solo para acceso en nombre de usuario):
├── Requiere que el usuario autorice cada N días
├── Token expira → agente se cae
└── NO usar para agentes automáticos en producción
```

### Convención de Columnas Obligatorias (C4)

```
REGLA ABSOLUTA: Las primeras 3 columnas de TODA hoja son:
Columna A: id          → UUID v4 generado en el momento del INSERT
Columna B: tenant_id   → C4: NUNCA puede faltar
Columna C: created_at  → ISO 8601 en UTC: "2026-04-10T14:30:00Z"

Resto de columnas: específicas de la hoja

VERIFICACIÓN: Si una hoja no tiene estas 3 columnas en ese orden,
el validador SDD la rechaza.
```

---

## 🏗️ Arquitectura y Hardware Limitado (VPS 2vCPU/4-8GB)

### Google Sheets NO consume RAM del VPS

A diferencia de MySQL o Qdrant, Google Sheets vive en la nube de Google. El VPS solo ejecuta n8n que hace las llamadas HTTP a la Sheets API. Impacto real en VPS:

```
Operación n8n → Sheets API
├── RAM por request en n8n: ~2-5MB (solo el JSON de respuesta)
├── CPU: mínimo (solo serialización JSON)
├── Red: ~50-200KB por operación típica
└── Latencia: 200-800ms por request (depende de red)

Comparación con MySQL local:
├── MySQL consume 512MB-1GB de RAM constante en VPS
├── Google Sheets: 0MB de RAM en VPS (está en cloud de Google)
└── Tradeoff: latencia mayor pero sin consumo de recursos locales
```

### Throttling: El Riesgo Real en VPS (C2)

El peligro no es RAM sino la cuota de API. Con 5 clientes enviando mensajes simultáneos en WhatsApp:

```
5 clientes × 3 requests Sheets por mensaje = 15 req/min
Límite: 60 req/min/usuario → OK ✅

10 clientes pico = 30 req/min → OK ✅
20 clientes pico = 60 req/min → LÍMITE ⚠️ → cache con Redis
50 clientes pico = 150 req/min → SUPERA → error 429 ❌
```

**Mitigación C1/C2:**
```javascript
// Implementar en n8n Function node
// Delay entre requests para no superar cuota
const SHEETS_RATE_LIMIT_MS = 200; // 5 req/s máximo
await new Promise(r => setTimeout(r, SHEETS_RATE_LIMIT_MS));
```

### Docker Compose: Google Sheets no requiere contenedor

```yaml
# No hay contenedor para Google Sheets.
# La única configuración necesaria es en n8n:
services:
  n8n:
    environment:
      # Credentials de Google se configuran en n8n UI
      # NO hardcodear en docker-compose (C3)
      - GOOGLE_SERVICE_ACCOUNT_EMAIL=${GOOGLE_SA_EMAIL}
      - GOOGLE_PRIVATE_KEY=${GOOGLE_PRIVATE_KEY}
    deploy:
      resources:
        limits:
          memory: 1500M  # C1: n8n procesa respuestas JSON de Sheets
          cpus: "1.0"    # C2
```

---

## 🔗 Conexión: Credenciales y Configuración

### Setup de Service Account (Una Vez por Proyecto)

```bash
# PASO 1: Crear proyecto en Google Cloud Console
# https://console.cloud.google.com/

# PASO 2: Habilitar APIs necesarias
gcloud services enable sheets.googleapis.com
gcloud services enable drive.googleapis.com

# PASO 3: Crear Service Account
gcloud iam service-accounts create mantis-sheets-agent \
    --display-name="MANTIS Sheets Agent" \
    --description="Service account para acceso a Google Sheets"

# PASO 4: Descargar credenciales JSON
gcloud iam service-accounts keys create ./credentials/sheets-sa.json \
    --iam-account=mantis-sheets-agent@{PROJECT_ID}.iam.gserviceaccount.com

# PASO 5: Extraer campos para .env (C3: NUNCA subir el JSON a git)
cat sheets-sa.json | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(f'GOOGLE_SA_EMAIL={d[\"client_email\"]}')
print(f'GOOGLE_PRIVATE_KEY_ID={d[\"private_key_id\"]}')
# La private_key tiene \n — codificar en base64 para .env
import base64
pk_b64 = base64.b64encode(d['private_key'].encode()).decode()
print(f'GOOGLE_PRIVATE_KEY_B64={pk_b64}')
"

# PASO 6: Agregar al .env (C3: .env en .gitignore)
echo "GOOGLE_SA_EMAIL=mantis-sheets-agent@{PROJECT_ID}.iam.gserviceaccount.com" >> .env
echo "GOOGLE_SPREADSHEET_ID_TENANT001={ID_DEL_SPREADSHEET}" >> .env
```

### Variables de Entorno por Tenant (C4)

```bash
# .env — Un spreadsheet por tenant (C4: aislamiento)
# C3: NUNCA exponer en logs ni en código fuente

# Service Account (compartida entre tenants)
GOOGLE_SA_EMAIL=mantis-sheets-agent@proyecto.iam.gserviceaccount.com
GOOGLE_PRIVATE_KEY_B64=<base64 de la private key>

# Spreadsheet ID por tenant (C4: cada tenant tiene su propio archivo)
SHEETS_ID_RESTAURANTE_001=1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgVE2upms
SHEETS_ID_HOTEL_002=1abc...xyz
SHEETS_ID_DENTAL_003=1def...uvw

# Nombres de hojas (pueden ser iguales en todos los spreadsheets)
SHEET_RESERVAS=reservas
SHEET_CLIENTES=clientes
SHEET_MENU=menu
SHEET_CONFIG=config

# Rate limiting
SHEETS_MAX_REQUESTS_PER_MINUTE=50   # Dejar margen bajo el límite de 60
SHEETS_RETRY_DELAY_MS=500
SHEETS_MAX_RETRIES=3
```

### Cliente Python Reutilizable

```python
# sheets_client.py
# Cliente centralizado con retry, rate limiting y C4 enforcement
import os
import time
import base64
import json
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

class SheetsClient:
    """
    Cliente Google Sheets con:
    C3: Credenciales solo de env vars, nunca hardcodeadas
    C4: tenant_id validado en construcción
    C2: Rate limiting integrado
    Retry automático con backoff exponencial (API-RELIABILITY-RULES)
    """

    SCOPES = [
        "https://www.googleapis.com/auth/spreadsheets",
        "https://www.googleapis.com/auth/drive.readonly"
    ]

    def __init__(self, tenant_id: str):
        # C4: tenant_id obligatorio
        if not tenant_id:
            raise ValueError("tenant_id required (C4)")

        self.tenant_id   = tenant_id
        self._last_req   = 0.0
        self._min_interval = 60.0 / int(
            os.environ.get("SHEETS_MAX_REQUESTS_PER_MINUTE", 50)
        )  # C2: throttle automático

        # C3: Credenciales desde env, nunca hardcodeadas
        sa_email  = os.environ["GOOGLE_SA_EMAIL"]
        pk_b64    = os.environ["GOOGLE_PRIVATE_KEY_B64"]
        pk        = base64.b64decode(pk_b64).decode("utf-8")

        creds = service_account.Credentials.from_service_account_info(
            {
                "type":                        "service_account",
                "client_email":                sa_email,
                "private_key":                 pk,
                "token_uri":                   "https://oauth2.googleapis.com/token",
            },
            scopes=self.SCOPES
        )
        self.service = build("sheets", "v4", credentials=creds)
        self.sheets  = self.service.spreadsheets()

        # C4: Spreadsheet ID específico del tenant
        env_key         = f"SHEETS_ID_{tenant_id.upper()}"
        self.sheet_id   = os.environ.get(env_key)
        if not self.sheet_id:
            raise ValueError(
                f"Spreadsheet ID not found for tenant '{tenant_id}'. "
                f"Set env var {env_key} (C4)"
            )

    def _throttle(self):
        """C2: Esperar entre requests para respetar rate limit de la API."""
        elapsed = time.time() - self._last_req
        if elapsed < self._min_interval:
            time.sleep(self._min_interval - elapsed)
        self._last_req = time.time()

    def _execute_with_retry(self, request, max_retries: int = 3):
        """
        Ejecuta un request con retry exponencial.
        Regla API-004: backoff en 429 y 5xx.
        """
        delay = float(os.environ.get("SHEETS_RETRY_DELAY_MS", 500)) / 1000

        for attempt in range(max_retries + 1):
            try:
                self._throttle()
                return request.execute()
            except HttpError as e:
                status = e.resp.status
                if status in (429, 500, 503) and attempt < max_retries:
                    wait = delay * (2 ** attempt)  # backoff exponencial
                    print(
                        f"[{self.tenant_id}] Sheets API {status} — "
                        f"retry {attempt+1}/{max_retries} en {wait:.1f}s"
                    )
                    time.sleep(wait)
                else:
                    raise
        raise RuntimeError("Max retries exceeded")

    def read(self, sheet_name: str, range_: str = "A:Z") -> list[list]:
        """Lee un rango de una hoja. Retorna lista de listas."""
        full_range = f"{sheet_name}!{range_}"
        result = self._execute_with_retry(
            self.sheets.values().get(
                spreadsheetId=self.sheet_id,
                range=full_range,
                valueRenderOption="UNFORMATTED_VALUE"
            )
        )
        return result.get("values", [])

    def append(self, sheet_name: str, row: list) -> dict:
        """Agrega una fila al final de la hoja."""
        return self._execute_with_retry(
            self.sheets.values().append(
                spreadsheetId=self.sheet_id,
                range=f"{sheet_name}!A:A",
                valueInputOption="USER_ENTERED",
                insertDataOption="INSERT_ROWS",
                body={"values": [row]}
            )
        )

    def update_row(self, sheet_name: str, row_number: int, row: list) -> dict:
        """Actualiza una fila específica por número de fila (1-indexed)."""
        range_ = f"{sheet_name}!A{row_number}:Z{row_number}"
        return self._execute_with_retry(
            self.sheets.values().update(
                spreadsheetId=self.sheet_id,
                range=range_,
                valueInputOption="USER_ENTERED",
                body={"values": [row]}
            )
        )

    def find_row(
        self,
        sheet_name: str,
        column_index: int,
        value: str
    ) -> tuple[int, list] | tuple[None, None]:
        """
        Busca una fila por valor en una columna.
        C4: Para buscar por tenant_id usar column_index=1 (columna B, 0-indexed).
        Retorna (row_number, row_data) o (None, None) si no encuentra.
        """
        rows = self.read(sheet_name)
        for i, row in enumerate(rows):
            if len(row) > column_index and str(row[column_index]) == str(value):
                return i + 1, row  # row_number es 1-indexed en Sheets API
        return None, None

    def find_rows_by_tenant(self, sheet_name: str) -> list[tuple[int, list]]:
        """
        C4: Retorna todas las filas del tenant actual.
        Columna B (index 1) = tenant_id por convención.
        """
        rows = self.read(sheet_name)
        result = []
        for i, row in enumerate(rows):
            if len(row) > 1 and str(row[1]) == self.tenant_id:
                result.append((i + 1, row))
        return result
```

---

## 📘 Guía de Estructura de Hojas (Para Principiantes)

### Schema: Restaurante

```
Hoja: "reservas"
Col  Campo           Tipo        Ejemplo                 Notas
A    id              UUID        550e8400-e29b...        Generado en INSERT
B    tenant_id       string      restaurante_001         C4: SIEMPRE col B
C    created_at      datetime    2026-04-10T14:30:00Z    UTC obligatorio
D    fecha           date        2026-04-15              YYYY-MM-DD
E    hora            time        20:30                   HH:MM
F    nombre          string      João Silva
G    telefono        string      5551999887766           Con código país
H    personas        int         4
I    mesa            string      Mesa 7                  O null si no asignada
J    estado          string      confirmada              pendiente/confirmada/
                                                         cancelada/completada
K    notas           string      Cumpleaños              Libre
L    canal           string      whatsapp                whatsapp/telegram/web

Hoja: "menu"
A    id              UUID
B    tenant_id       string      C4
C    created_at      datetime
D    categoria       string      Pratos principais
E    nombre          string      Frango grelhado
F    precio          float       38.90
G    disponible      boolean     TRUE                    TRUE/FALSE
H    descripcion     string      Frango com ervas...
I    imagen_url      string      https://drive.google...
J    orden           int         1                       Para ordenar display

Hoja: "clientes"
A    id              UUID
B    tenant_id       string      C4
C    created_at      datetime
D    telefono        string      5551999887766           UK junto a tenant_id
E    nombre          string      João Silva
F    email           string      joao@email.com
G    visitas         int         3
H    ultima_visita   datetime    2026-04-08T20:30:00Z
I    preferencias    string      Mesa perto da janela    Libre
J    notas_internas  string      VIP                     Solo para staff

Hoja: "config"
A    clave           string      horario_apertura        Snake case
B    valor           string      12:00                   Valor del config
C    tenant_id       string      C4 — aunque sea config
D    updated_at      datetime    2026-04-10T10:00:00Z
Ejemplos de claves:
    horario_apertura, horario_cierre, capacidad_maxima,
    mensaje_bienvenida, mensaje_espera, mensaje_completo,
    dias_operacion, telefono_reservas, politica_cancelacion
```

### Schema: Hotel/Posada

```
Hoja: "huespedes"
A    id | B tenant_id | C created_at | D nombre | E telefono
F    email | G checkin_fecha | H checkout_fecha | I habitacion
J    adultos | K ninos | K estado | L canal | M notas | N total_usd

Hoja: "habitaciones"
A    id | B tenant_id | C created_at | D numero | E tipo
F    capacidad | G precio_noche | H disponible | I amenities_json
J    piso | K descripcion | L imagen_url

Hoja: "mensajes_programados"
A    id | B tenant_id | C created_at | D huesped_id | E tipo
(tipo: pre_llegada_48h, pre_llegada_24h, bienvenida, checkout_reminder)
F    enviado | G enviado_at | H canal | I contenido_custom
```

### Schema: Odontología

```
Hoja: "pacientes"
A    id | B tenant_id | C created_at | D nombre | E telefono
F    email | G fecha_nacimiento | H cpf_cnpj | I convenio
J    notas_medicas | K alergias | L ultima_consulta

Hoja: "citas"
A    id | B tenant_id | C created_at | D paciente_id | E dentista
F    fecha | G hora | H duracion_min | I tratamiento | J estado
(estado: agendada/confirmada/cancelada/completada/no_show)
K    sala | L notas | M recordatorio_enviado

Hoja: "tratamientos"
A    id | B tenant_id | C created_at | D nombre | E duracion_min
F    precio | G descripcion | H requiere_anestesia | I sesiones
```

---

## 🛠️ 15 Ejemplos

### E-1: INSERT — Nueva Reserva de Restaurante

```python
# ejemplo_01_insert_reserva.py
import uuid
from datetime import datetime, timezone

def crear_reserva(
    tenant_id: str,     # C4
    fecha:     str,     # YYYY-MM-DD
    hora:      str,     # HH:MM
    nombre:    str,
    telefono:  str,
    personas:  int,
    canal:     str = "whatsapp",
    notas:     str = ""
) -> dict:
    """
    Crea una nueva reserva en Google Sheets.
    C4: tenant_id en columna B de toda fila.
    Retorna el ID generado para confirmación al cliente.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    client     = SheetsClient(tenant_id=tenant_id)
    reserva_id = str(uuid.uuid4())
    now        = datetime.now(timezone.utc).isoformat()

    # Orden de columnas: id, tenant_id, created_at, fecha, hora,
    # nombre, telefono, personas, mesa, estado, notas, canal
    fila = [
        reserva_id,
        tenant_id,      # C4: columna B siempre
        now,
        fecha,
        hora,
        nombre,
        telefono,
        personas,
        "",             # mesa: sin asignar todavía
        "pendiente",    # estado inicial
        notas,
        canal
    ]

    result = client.append("reservas", fila)

    # C5: Log estructurado
    print(__import__("json").dumps({
        "timestamp": now,
        "tenant_id": tenant_id,       # C4
        "event":     "reserva_created",
        "id":        reserva_id,
        "fecha":     fecha,
        "hora":      hora,
        "canal":     canal
    }))

    return {
        "id":        reserva_id,
        "tenant_id": tenant_id,       # C4
        "estado":    "pendiente",
        "mensaje":   f"Reserva confirmada para {fecha} às {hora}"
    }

# Uso
resultado = crear_reserva(
    tenant_id = "restaurante_001",
    fecha     = "2026-04-15",
    hora      = "20:30",
    nombre    = "João Silva",
    telefono  = "5551999887766",
    personas  = 4,
    canal     = "whatsapp"
)
print(f"Reserva criada: {resultado['id']}")
```

---

### E-2: READ — Consultar Disponibilidad por Fecha y Hora

```python
# ejemplo_02_consultar_disponibilidad.py
def consultar_disponibilidad(
    tenant_id: str,   # C4
    fecha:     str,
    hora:      str
) -> dict:
    """
    Verifica si hay mesas disponibles para fecha+hora.
    C4: Solo lee filas del tenant indicado.
    C1: Lee hoja completa una sola vez, filtra en memoria.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    client = SheetsClient(tenant_id=tenant_id)

    # Leer config para saber capacidad máxima
    config_rows = client.find_rows_by_tenant("config")   # C4
    capacidad   = 10  # default
    for _, row in config_rows:
        if len(row) > 0 and row[0] == "capacidad_maxima":
            capacidad = int(row[1])
            break

    # Leer reservas del tenant (C4: find_rows_by_tenant filtra por tenant_id)
    reservas = client.find_rows_by_tenant("reservas")

    # Contar reservas activas para fecha+hora solicitada
    reservas_en_turno = [
        r for _, r in reservas
        if len(r) > 9
        and str(r[3]) == fecha           # col D: fecha
        and str(r[4]) == hora            # col E: hora
        and str(r[9]) not in ("cancelada", "no_show")  # col J: estado
    ]

    disponible   = len(reservas_en_turno) < capacidad
    libres       = capacidad - len(reservas_en_turno)

    return {
        "tenant_id":  tenant_id,          # C4
        "fecha":      fecha,
        "hora":       hora,
        "disponible": disponible,
        "lugares_libres": max(0, libres),
        "reservas_activas": len(reservas_en_turno)
    }

# Uso
disp = consultar_disponibilidad("restaurante_001", "2026-04-15", "20:30")
if disp["disponible"]:
    print(f"✅ Disponível: {disp['lugares_libres']} lugares")
else:
    print("❌ Lotado para esse horário")
```

---

### E-3: UPDATE — Confirmar Reserva y Asignar Mesa

```python
# ejemplo_03_confirmar_reserva.py
def confirmar_reserva(
    tenant_id:  str,   # C4
    reserva_id: str,
    mesa:       str
) -> dict:
    """
    Actualiza estado de reserva a 'confirmada' y asigna mesa.
    C4: Verifica que la reserva pertenece al tenant antes de actualizar.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    client = SheetsClient(tenant_id=tenant_id)
    rows   = client.read("reservas")

    # Buscar por ID (col A) Y verificar tenant_id (col B) — C4
    target_row = None
    for i, row in enumerate(rows):
        if (len(row) > 1
                and str(row[0]) == reserva_id
                and str(row[1]) == tenant_id):    # C4: doble verificación
            target_row = (i + 1, row)             # i+1 = número de fila real
            break

    if not target_row:
        raise ValueError(
            f"Reserva {reserva_id} não encontrada para tenant {tenant_id} (C4)"
        )

    row_num, row_data = target_row

    # Construir fila actualizada (mantener valores existentes)
    updated = list(row_data) + [""] * (12 - len(row_data))  # padding
    updated[8]  = mesa           # col I: mesa
    updated[9]  = "confirmada"   # col J: estado

    client.update_row("reservas", row_num, updated)

    return {
        "tenant_id":  tenant_id,     # C4
        "reserva_id": reserva_id,
        "mesa":       mesa,
        "estado":     "confirmada"
    }
```

---

### E-4: READ con Filtros Múltiples — Reservas del Día

```python
# ejemplo_04_reservas_del_dia.py
def get_reservas_del_dia(
    tenant_id: str,   # C4
    fecha:     str    # YYYY-MM-DD
) -> list[dict]:
    """
    Lista todas las reservas activas de un día específico.
    C4: Solo reservas del tenant indicado.
    Ordenadas por hora ascendente.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    client  = SheetsClient(tenant_id=tenant_id)
    rows    = client.read("reservas")

    # Header en fila 1 — saltar si la primera fila es encabezado
    data_rows = rows[1:] if rows and rows[0][0] == "id" else rows

    reservas_hoy = []
    for row in data_rows:
        if len(row) < 10:
            continue
        if (str(row[1]) == tenant_id          # C4: col B
                and str(row[3]) == fecha      # col D: fecha
                and str(row[9]) not in ("cancelada",)):   # col J
            reservas_hoy.append({
                "id":       row[0],
                "tenant_id": row[1],          # C4
                "hora":     row[4],
                "nombre":   row[5],
                "telefono": row[6],
                "personas": row[7],
                "mesa":     row[8] if len(row) > 8 else "",
                "estado":   row[9],
                "canal":    row[11] if len(row) > 11 else ""
            })

    # Ordenar por hora
    reservas_hoy.sort(key=lambda r: r["hora"])
    return reservas_hoy

# Uso desde n8n Function node
reservas = get_reservas_del_dia("restaurante_001", "2026-04-15")
print(f"Total reservas hoje: {len(reservas)}")
for r in reservas:
    print(f"  {r['hora']} — {r['nombre']} × {r['personas']} — Mesa: {r['mesa']}")
```

---

### E-5: UPSERT — Registrar o Actualizar Cliente (CRM Ligero)

```python
# ejemplo_05_upsert_cliente.py
def upsert_cliente(
    tenant_id:    str,   # C4
    telefono:     str,
    nombre:       str,
    canal:        str = "whatsapp",
    preferencias: str = ""
) -> dict:
    """
    Crea cliente si no existe, actualiza si ya existe (por teléfono + tenant_id).
    Incrementa contador de visitas en cada llamada.
    C4: La búsqueda siempre incluye tenant_id para no cruzar clientes.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    import uuid
    from datetime import datetime, timezone

    client   = SheetsClient(tenant_id=tenant_id)
    rows     = client.read("clientes")
    now      = datetime.now(timezone.utc).isoformat()

    # Buscar por telefono (col D) dentro del tenant (col B) — C4
    existing_row_num = None
    existing_row     = None
    for i, row in enumerate(rows):
        if (len(row) > 3
                and str(row[1]) == tenant_id    # C4: col B
                and str(row[3]) == telefono):   # col D: telefono
            existing_row_num = i + 1
            existing_row     = row
            break

    if existing_row_num:
        # UPDATE: incrementar visitas y actualizar ultima_visita
        updated = list(existing_row) + [""] * (10 - len(existing_row))
        visitas_actuales  = int(updated[6]) if updated[6] else 0
        updated[4]  = nombre                    # actualizar nombre
        updated[6]  = visitas_actuales + 1      # col G: visitas
        updated[7]  = now                       # col H: ultima_visita
        if preferencias:
            updated[8]  = preferencias          # col I: preferencias

        client.update_row("clientes", existing_row_num, updated)
        return {
            "action":    "updated",
            "tenant_id": tenant_id,             # C4
            "telefono":  telefono,
            "visitas":   visitas_actuales + 1
        }
    else:
        # INSERT: cliente nuevo
        cliente_id = str(uuid.uuid4())
        fila = [
            cliente_id,
            tenant_id,        # C4: col B
            now,              # col C: created_at
            telefono,         # col D
            nombre,           # col E
            "",               # col F: email
            1,                # col G: visitas = 1
            now,              # col H: ultima_visita
            preferencias,     # col I
            ""                # col J: notas_internas
        ]
        client.append("clientes", fila)
        return {
            "action":    "created",
            "tenant_id": tenant_id,             # C4
            "id":        cliente_id,
            "telefono":  telefono
        }
```

---

### E-6: READ — Leer Config del Tenant (Mensajes del Agente)

```python
# ejemplo_06_leer_config.py
def get_config(
    tenant_id: str,   # C4
    clave:     str
) -> str | None:
    """
    Lee un valor de configuración del tenant.
    La hoja 'config' almacena mensajes, horarios, políticas.
    C4: Filtrar por tenant_id en cada lectura.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    client = SheetsClient(tenant_id=tenant_id)
    rows   = client.read("config")

    for row in rows:
        if (len(row) > 2
                and str(row[0]) == clave        # col A: clave
                and str(row[2]) == tenant_id):  # col C: tenant_id (C4)
            return str(row[1])                  # col B: valor

    return None

def get_all_config(tenant_id: str) -> dict:
    """Retorna todas las configs del tenant como dict. C4."""
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    client = SheetsClient(tenant_id=tenant_id)
    rows   = client.read("config")
    config = {}

    for row in rows:
        if (len(row) > 2
                and str(row[2]) == tenant_id):  # C4
            config[str(row[0])] = str(row[1])

    return config

# Uso en agente WhatsApp
config = get_all_config("restaurante_001")
mensaje_bienvenida = config.get(
    "mensaje_bienvenida",
    "Olá! Bem-vindo ao nosso restaurante! 🍽️"
)
horario = config.get("horario_apertura", "12:00")
```

---

### E-7: DELETE LÓGICO — Cancelar Reserva

```python
# ejemplo_07_cancelar_reserva.py
def cancelar_reserva(
    tenant_id:  str,   # C4
    reserva_id: str,
    motivo:     str = ""
) -> dict:
    """
    DELETE lógico: cambia estado a 'cancelada' en vez de borrar la fila.
    Regla: NUNCA eliminar filas físicamente en Google Sheets (pierde auditoría).
    C4: Verifica ownership antes de cancelar.
    C5: Log de la cancelación.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    from datetime import datetime, timezone
    client = SheetsClient(tenant_id=tenant_id)
    rows   = client.read("reservas")

    for i, row in enumerate(rows):
        if (len(row) > 1
                and str(row[0]) == reserva_id
                and str(row[1]) == tenant_id):   # C4: verificar ownership
            row_num = i + 1
            updated = list(row) + [""] * (13 - len(row))
            updated[9]  = "cancelada"            # col J: estado
            if motivo:
                updated[10] = f"Cancelada: {motivo}"  # col K: notas
            # Col L: timestamp de cancelación (si existe)
            if len(updated) > 12:
                updated[12] = datetime.now(timezone.utc).isoformat()

            client.update_row("reservas", row_num, updated)

            # C5: Audit log
            print(__import__("json").dumps({
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "tenant_id": tenant_id,          # C4
                "event":     "reserva_cancelada",
                "id":        reserva_id,
                "motivo":    motivo
            }))

            return {
                "tenant_id":  tenant_id,         # C4
                "reserva_id": reserva_id,
                "estado":     "cancelada"
            }

    raise ValueError(
        f"Reserva {reserva_id} não encontrada para tenant {tenant_id} (C4)"
    )
```

---

### E-8: READ — Menú Disponible para Mostrar al Cliente

```python
# ejemplo_08_get_menu.py
def get_menu_disponible(
    tenant_id:  str,     # C4
    categoria:  str = None
) -> list[dict]:
    """
    Retorna items del menú disponibles (disponible=TRUE).
    C4: Solo items del tenant.
    C1: Filtra en memoria, no hace múltiples requests a la API.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    client = SheetsClient(tenant_id=tenant_id)
    rows   = client.read("menu")

    # Saltar header si existe
    data = rows[1:] if rows and rows[0][0] == "id" else rows

    items = []
    for row in data:
        if len(row) < 7:
            continue
        if str(row[1]) != tenant_id:       # C4: col B
            continue
        disponible = str(row[6]).upper() in ("TRUE", "1", "SIM", "YES")
        if not disponible:
            continue
        if categoria and str(row[3]) != categoria:  # col D: categoria
            continue

        items.append({
            "id":          row[0],
            "tenant_id":   row[1],         # C4
            "categoria":   row[3],
            "nombre":      row[4],
            "precio":      float(row[5]) if row[5] else 0.0,
            "descripcion": row[7] if len(row) > 7 else "",
            "orden":       int(row[9]) if len(row) > 9 and row[9] else 999
        })

    # Ordenar por categoria y luego por orden
    items.sort(key=lambda x: (x["categoria"], x["orden"]))
    return items

# Uso: formatear menú para WhatsApp
menu = get_menu_disponible("restaurante_001")
categorias = {}
for item in menu:
    cat = item["categoria"]
    if cat not in categorias:
        categorias[cat] = []
    categorias[cat].append(item)

texto = "🍽️ *Nosso Cardápio*\n\n"
for cat, items in categorias.items():
    texto += f"*{cat}*\n"
    for item in items:
        texto += f"• {item['nombre']} — R$ {item['precio']:.2f}\n"
    texto += "\n"
```

---

### E-9: BATCH READ — Dashboard Diario del Restaurante

```python
# ejemplo_09_dashboard_diario.py
def get_dashboard_diario(
    tenant_id: str,   # C4
    fecha:     str    # YYYY-MM-DD
) -> dict:
    """
    Lee múltiples hojas en paralelo para armar dashboard.
    C1: Una sola lectura por hoja (no múltiples requests).
    C4: tenant_id en todos los filtros.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    import concurrent.futures

    client = SheetsClient(tenant_id=tenant_id)

    # Leer reservas y clientes en paralelo (C2: reduce latencia total)
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as executor:
        f_reservas = executor.submit(client.read, "reservas")
        f_clientes = executor.submit(client.read, "clientes")

    reservas_raw = f_reservas.result()
    clientes_raw = f_clientes.result()

    # Filtrar por tenant_id (C4) y fecha
    reservas_hoy = [
        r for r in reservas_raw
        if len(r) > 9
        and str(r[1]) == tenant_id         # C4
        and str(r[3]) == fecha
        and str(r[9]) != "cancelada"
    ]

    total_clientes = len([
        c for c in clientes_raw
        if len(c) > 1 and str(c[1]) == tenant_id  # C4
    ])

    return {
        "tenant_id":         tenant_id,            # C4
        "fecha":             fecha,
        "reservas_total":    len(reservas_hoy),
        "reservas_confirm":  len([r for r in reservas_hoy if r[9] == "confirmada"]),
        "reservas_pendient": len([r for r in reservas_hoy if r[9] == "pendiente"]),
        "personas_esperadas": sum(
            int(r[7]) for r in reservas_hoy if r[7]
        ),
        "total_clientes_bd": total_clientes,
        "canales": {
            "whatsapp": len([r for r in reservas_hoy if len(r)>11 and r[11]=="whatsapp"]),
            "telegram": len([r for r in reservas_hoy if len(r)>11 and r[11]=="telegram"]),
            "web":      len([r for r in reservas_hoy if len(r)>11 and r[11]=="web"])
        }
    }
```

---

### E-10: Workflow n8n — Crear Reserva desde Webhook WhatsApp

```json
{
  "name": "WhatsApp Reserva → Google Sheets",
  "nodes": [
    {
      "name": "Webhook WhatsApp",
      "type": "n8n-nodes-base.webhook",
      "parameters": {
        "path": "whatsapp-reserva",
        "responseMode": "responseNode"
      }
    },
    {
      "name": "Extraer Datos del Mensaje",
      "type": "n8n-nodes-base.function",
      "parameters": {
        "functionCode": "// C4: extraer tenant_id del webhook o config\nconst tenantId = $input.first().json.tenant_id\n  || $env.TENANT_ID_DEFAULT;\n\nif (!tenantId) throw new Error('tenant_id missing (C4)');\n\nconst mensaje = $input.first().json.message?.body || '';\n\n// Parsear datos de la reserva del mensaje\n// (vendrán estructurados del agente LLM)\nconst datos = $input.first().json.parsed_data || {};\n\nreturn [{ json: {\n  tenant_id: tenantId,\n  fecha:     datos.fecha,\n  hora:      datos.hora,\n  nombre:    datos.nombre,\n  telefono:  $input.first().json.from,\n  personas:  datos.personas || 2,\n  canal:     'whatsapp'\n}}];"
      }
    },
    {
      "name": "Verificar Disponibilidad → Sheets",
      "type": "n8n-nodes-base.googleSheets",
      "parameters": {
        "operation": "read",
        "spreadsheetId": "={{ $env['SHEETS_ID_' + $json.tenant_id.toUpperCase()] }}",
        "sheetName": "reservas",
        "options": {
          "headerRow": true
        }
      }
    },
    {
      "name": "Evaluar y Crear Reserva",
      "type": "n8n-nodes-base.function",
      "parameters": {
        "functionCode": "// C4: tenant_id en cada operación\nconst tenantId = $('Extraer Datos del Mensaje').first().json.tenant_id;\nconst reservas = $input.all();\n\n// Filtrar por tenant + fecha + hora (C4)\nconst conflictos = reservas.filter(r =>\n  r.json.tenant_id === tenantId &&\n  r.json.fecha     === $('Extraer Datos del Mensaje').first().json.fecha &&\n  r.json.hora      === $('Extraer Datos del Mensaje').first().json.hora &&\n  !['cancelada','no_show'].includes(r.json.estado)\n);\n\nconst capacidad = 10; // leer de config en producción\nconst disponible = conflictos.length < capacidad;\n\nreturn [{ json: {\n  tenant_id:  tenantId,\n  disponible: disponible,\n  ocupados:   conflictos.length,\n  libres:     Math.max(0, capacidad - conflictos.length)\n}}];"
      }
    },
    {
      "name": "INSERT Reserva → Sheets",
      "type": "n8n-nodes-base.googleSheets",
      "parameters": {
        "operation": "append",
        "spreadsheetId": "={{ $env['SHEETS_ID_' + $('Extraer Datos del Mensaje').first().json.tenant_id.toUpperCase()] }}",
        "sheetName": "reservas",
        "columns": {
          "mappingMode": "defineBelow",
          "value": {
            "id":         "={{ $now.toMillis().toString() + '-' + $randomInt(1000,9999) }}",
            "tenant_id":  "={{ $('Extraer Datos del Mensaje').first().json.tenant_id }}",
            "created_at": "={{ $now.toISO() }}",
            "fecha":      "={{ $('Extraer Datos del Mensaje').first().json.fecha }}",
            "hora":       "={{ $('Extraer Datos del Mensaje').first().json.hora }}",
            "nombre":     "={{ $('Extraer Datos del Mensaje').first().json.nombre }}",
            "telefono":   "={{ $('Extraer Datos del Mensaje').first().json.telefono }}",
            "personas":   "={{ $('Extraer Dados del Mensaje').first().json.personas }}",
            "estado":     "pendiente",
            "canal":      "whatsapp"
          }
        }
      }
    }
  ]
}
```

---

### E-11: Gestión de Habitaciones Hotel — Check-In

```python
# ejemplo_11_hotel_checkin.py
def registrar_checkin(
    tenant_id:        str,   # C4
    nombre:           str,
    telefono:         str,
    habitacion:       str,
    fecha_checkout:   str,
    adultos:          int = 1,
    ninos:            int = 0,
    notas:            str = ""
) -> dict:
    """
    Registra check-in de huésped y marca habitación como ocupada.
    C4: tenant_id en toda operación.
    Actualiza dos hojas en secuencia: huespedes + habitaciones.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    import uuid
    from datetime import datetime, timezone

    client     = SheetsClient(tenant_id=tenant_id)
    huesped_id = str(uuid.uuid4())
    now        = datetime.now(timezone.utc).isoformat()
    fecha_hoy  = now[:10]   # YYYY-MM-DD

    # INSERT en hoja huespedes
    fila_huesped = [
        huesped_id,
        tenant_id,          # C4
        now,
        nombre,
        telefono,
        "",                 # email
        fecha_hoy,          # checkin_fecha
        fecha_checkout,
        habitacion,
        adultos,
        ninos,
        "activo",           # estado
        "whatsapp",         # canal
        notas,
        0                   # total_usd: se calculará al checkout
    ]
    client.append("huespedes", fila_huesped)

    # Marcar habitación como NO disponible
    rows = client.read("habitaciones")
    for i, row in enumerate(rows):
        if (len(row) > 4
                and str(row[1]) == tenant_id      # C4
                and str(row[3]) == habitacion):   # col D: numero
            updated        = list(row)
            updated[7]     = "FALSE"              # col H: disponible = FALSE
            client.update_row("habitaciones", i + 1, updated)
            break

    return {
        "tenant_id":  tenant_id,    # C4
        "huesped_id": huesped_id,
        "habitacion": habitacion,
        "checkin":    fecha_hoy,
        "checkout":   fecha_checkout
    }
```

---

### E-12: Programar Mensaje Pre-Llegada (Hotel)

```python
# ejemplo_12_hotel_pre_llegada.py
def programar_mensajes_pre_llegada(
    tenant_id: str   # C4
) -> int:
    """
    Revisa huéspedes con check-in en las próximas 48h y 24h
    y programa mensajes si no fueron enviados aún.
    Diseñado para ejecutarse como cron cada hora.
    C4: Solo procesa huéspedes del tenant.
    C1: Lee hoja una vez, procesa en memoria.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    from datetime import datetime, timezone, timedelta
    import uuid

    client    = SheetsClient(tenant_id=tenant_id)
    now       = datetime.now(timezone.utc)
    en_48h    = (now + timedelta(hours=48)).strftime("%Y-%m-%d")
    en_24h    = (now + timedelta(hours=24)).strftime("%Y-%m-%d")

    # Leer huéspedes y mensajes programados
    huespedes     = client.find_rows_by_tenant("huespedes")       # C4
    mensajes_prog = client.find_rows_by_tenant("mensajes_programados")  # C4

    # IDs que ya tienen mensajes programados
    ya_programados = set()
    for _, msg in mensajes_prog:
        if len(msg) > 3 and str(msg[3]) in ("pre_llegada_48h", "pre_llegada_24h"):
            ya_programados.add(str(msg[3]) + "_" + str(msg[2]))  # tipo_huesped_id

    programados = 0
    for _, h in huespedes:
        if len(h) < 12 or str(h[11]) != "activo":
            continue
        huesped_id = str(h[0])
        checkin    = str(h[6])  # col G: checkin_fecha

        for tipo, fecha_target in [("pre_llegada_48h", en_48h),
                                    ("pre_llegada_24h", en_24h)]:
            clave = f"{tipo}_{huesped_id}"
            if checkin == fecha_target and clave not in ya_programados:
                msg_id = str(uuid.uuid4())
                fila_msg = [
                    msg_id,
                    tenant_id,          # C4
                    now.isoformat(),
                    huesped_id,
                    tipo,
                    "FALSE",            # enviado
                    "",                 # enviado_at
                    "whatsapp",         # canal
                    ""                  # contenido_custom
                ]
                client.append("mensajes_programados", fila_msg)
                programados += 1

    return programados
```

---

### E-13: Cita Odontológica — Verificar Conflicto de Agenda

```python
# ejemplo_13_dental_verificar_agenda.py
def verificar_conflicto_cita(
    tenant_id:    str,   # C4
    dentista:     str,
    fecha:        str,
    hora:         str,
    duracion_min: int
) -> dict:
    """
    Verifica si el dentista tiene citas solapadas en el horario solicitado.
    C4: Solo citas del tenant indicado.
    Lógica de solapamiento: [hora_inicio, hora_inicio + duracion).
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    from datetime import datetime

    def hora_to_min(h: str) -> int:
        """Convierte 'HH:MM' a minutos desde medianoche."""
        parts = h.split(":")
        return int(parts[0]) * 60 + int(parts[1])

    client       = SheetsClient(tenant_id=tenant_id)
    citas        = client.find_rows_by_tenant("citas")   # C4

    nueva_inicio = hora_to_min(hora)
    nueva_fin    = nueva_inicio + duracion_min

    conflictos = []
    for _, cita in citas:
        if len(cita) < 11:
            continue
        if (str(cita[4]) != dentista          # col E: dentista
                or str(cita[5]) != fecha      # col F: fecha
                or str(cita[10]) in ("cancelada", "no_show")):  # col K: estado
            continue

        cita_inicio = hora_to_min(str(cita[6]))  # col G: hora
        dur_cita    = int(cita[7]) if cita[7] else 30  # col H: duracion_min
        cita_fin    = cita_inicio + dur_cita

        # Verificar solapamiento
        if nueva_inicio < cita_fin and nueva_fin > cita_inicio:
            conflictos.append({
                "id":        cita[0],
                "hora":      cita[6],
                "duracion":  cita[7],
                "paciente":  cita[3] if len(cita) > 3 else ""
            })

    return {
        "tenant_id":      tenant_id,     # C4
        "disponible":     len(conflictos) == 0,
        "conflictos":     conflictos,
        "hora_solicitada": hora,
        "dentista":       dentista
    }
```

---

### E-14: Exportar Datos RAG como Texto para Ingesta en Qdrant

```python
# ejemplo_14_sheets_to_rag.py
def exportar_menu_para_rag(
    tenant_id: str   # C4
) -> list[dict]:
    """
    Exporta el menú de Google Sheets como chunks de texto
    para ingestar en Qdrant como base de conocimiento del restaurante.
    Puente entre Google Sheets (BD operativa) y Qdrant (RAG).
    C4: tenant_id en todos los chunks generados.
    C6: Embeddings se generan externamente vía OpenRouter.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    import uuid, hashlib

    client = SheetsClient(tenant_id=tenant_id)
    items  = get_menu_disponible(tenant_id)   # Ejemplo E-8

    chunks = []
    for item in items:
        # Construir texto descriptivo del item para embedding
        texto = (
            f"Prato: {item['nombre']}\n"
            f"Categoria: {item['categoria']}\n"
            f"Preço: R$ {item['precio']:.2f}\n"
        )
        if item.get("descripcion"):
            texto += f"Descrição: {item['descripcion']}\n"

        chunk_id = str(uuid.uuid4())
        chunks.append({
            "id":              chunk_id,
            "tenant_id":       tenant_id,              # C4
            "source_type":     "google_sheets",
            "source_id":       f"menu_{item['id']}",
            "text":            texto,
            "token_count":     len(texto.split()) * 2, # aproximación
            "content_hash":    hashlib.sha256(texto.encode()).hexdigest(),
            "metadata": {
                "sheet":      "menu",
                "item_id":    item["id"],
                "categoria":  item["categoria"],
                "precio":     item["precio"]
            }
        })

    return chunks

# Uso: integrar con el pipeline RAG
chunks = exportar_menu_para_rag("restaurante_001")
print(f"Chunks para ingestar en Qdrant: {len(chunks)}")
# → pasar a generate_embeddings_batch() → insert en Qdrant
# Ver qdrant-rag-ingestion.md para el paso siguiente
```

---

### E-15: Backup Diario de Sheets a JSON Local (C5)

```python
# ejemplo_15_backup_sheets.py
def backup_tenant_sheets(
    tenant_id: str,          # C4
    backup_dir: str = "/backups/sheets"
) -> dict:
    """
    Descarga todas las hojas del tenant a JSON local.
    C5: Backup diario con checksum SHA256.
    C4: Solo datos del tenant indicado.
    Ejecutar como cron a las 04:00 AM (ver C5 en RESOURCE-GUARDRAILS).
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    import json
    import hashlib
    import os
    from datetime import datetime, timezone
    from pathlib import Path

    client    = SheetsClient(tenant_id=tenant_id)
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    backup    = {}

    HOJAS = ["reservas", "clientes", "menu", "config",
             "huespedes", "habitaciones", "mensajes_programados",
             "citas", "pacientes", "pedidos"]

    for hoja in HOJAS:
        try:
            rows = client.read(hoja)
            # C4: Filtrar solo filas del tenant (col B = tenant_id)
            # (el client ya hace esto pero doble check para backup)
            rows_tenant = [
                r for r in rows
                if len(r) > 1 and str(r[1]) == tenant_id
            ] if rows else []

            backup[hoja] = rows_tenant
        except Exception as e:
            # Hoja puede no existir para este vertical — no es error crítico
            backup[hoja] = []

    # Serializar y calcular SHA256 (C5)
    backup_data   = json.dumps(backup, ensure_ascii=False, indent=2)
    sha256        = hashlib.sha256(backup_data.encode()).hexdigest()

    # Guardar archivo
    path = Path(backup_dir) / tenant_id
    path.mkdir(parents=True, exist_ok=True)
    file_path = path / f"backup_{timestamp}.json"
    file_path.write_text(backup_data, encoding="utf-8")

    # Guardar checksum (C5)
    checksum_path = path / f"backup_{timestamp}.sha256"
    checksum_path.write_text(
        f"{sha256}  backup_{timestamp}.json\n"
    )

    # C5: Log estructurado del backup
    log = {
        "timestamp":  datetime.now(timezone.utc).isoformat(),
        "tenant_id":  tenant_id,                          # C4
        "event":      "sheets_backup_completed",
        "file":       str(file_path),
        "sha256":     sha256[:16] + "...",
        "hojas":      {h: len(backup[h]) for h in backup}
    }
    print(json.dumps(log))

    return {
        "tenant_id":    tenant_id,    # C4
        "file":         str(file_path),
        "sha256":       sha256,
        "total_rows":   sum(len(v) for v in backup.values()),
        "timestamp":    timestamp
    }
```

---

---

## 🐞 15 Errores Comunes y Soluciones

| # | Error Exacto | Causa Raíz | Comando de Diagnóstico | Solución Paso a Paso |
|---|---|---|---|---|
| 1 | `HttpError 403: The caller does not have permission` | El Spreadsheet no está compartido con el Service Account email | `cat credentials/sheets-sa.json \| python3 -c "import json,sys; d=json.load(sys.stdin); print(d['client_email'])"` | 1. Copiar el email del SA (termina en `.iam.gserviceaccount.com`)<br>2. Abrir el Spreadsheet en Google Drive<br>3. Clic en "Compartilhar" → pegar el email del SA<br>4. Dar permiso "Editor" (no solo "Leitor")<br>5. NO activar "Notificar pessoas" (es un robot) |
| 2 | `HttpError 429: Quota exceeded for quota metric 'read_requests'` | Superando 60 requests/minuto del usuario o 300/minuto del proyecto | Contar requests en logs: `grep "Sheets API" n8n.log \| grep "$(date +%H:%M)" \| wc -l` | 1. Agregar `time.sleep(1.5)` entre requests en loops<br>2. Implementar caché local de lecturas frecuentes (config, menú) en Redis con TTL 5 minutos<br>3. Reducir `SHEETS_MAX_REQUESTS_PER_MINUTE` en `.env` a 40<br>4. Si el problema es estructural: migrar a MySQL (ver `mysql-sql-rag-ingestion.md`) |
| 3 | `HttpError 400: Unable to parse range: reservas!A:Z` | El nombre de la hoja tiene acento o espacio y la codificación falla | `python3 -c "from googleapiclient.discovery import build; ..."` con el nombre exacto de la hoja | 1. Renombrar la hoja en Sheets: evitar acentos y espacios<br>2. Usar nombres simples: `reservas`, `clientes`, `menu` (sin mayúsculas, sin especiales)<br>3. Si ya tiene nombre con acento: en la API usar comillas simples: `'Reservações'!A:Z`<br>4. Estandarizar en el código: `sheet_name = sheet_name.replace(" ", "_").lower()` |
| 4 | Los datos leídos no coinciden con lo que hay en la hoja — faltan filas o columnas | La API retorna filas vacías como listas cortas o las omite completamente | `print(len(rows), [len(r) for r in rows[:5]])` para ver longitudes reales | 1. Agregar padding: `row = row + [""] * (12 - len(row))` antes de acceder por índice<br>2. Nunca acceder `row[8]` sin verificar `len(row) > 8`<br>3. Google Sheets omite celdas vacías al final de la fila — es comportamiento esperado, no bug<br>4. Usar `valueRenderOption="UNFORMATTED_VALUE"` para valores numéricos correctos |
| 5 | `KeyError: 'SHEETS_ID_RESTAURANTE_001'` en el `SheetsClient` | Variable de entorno no configurada para el tenant solicitado | `python3 -c "import os; print([k for k in os.environ if 'SHEETS_ID' in k])"` | 1. Verificar nombre exacto del tenant en la variable: es case-sensitive<br>2. El tenant `"restaurante_001"` necesita `SHEETS_ID_RESTAURANTE_001` (todo en mayúsculas)<br>3. Verificar que `.env` fue cargado: `python3 -c "from dotenv import load_dotenv; load_dotenv(); import os; print(os.environ.get('SHEETS_ID_RESTAURANTE_001'))"`<br>4. En n8n: verificar que la env var está en el environment del container Docker |
| 6 | UPDATE actualiza la fila equivocada — los datos de otro cliente se sobrescriben | `find_row()` retorna el primer match sin verificar `tenant_id` (violación C4) | Buscar en código: `grep -n "find_row\|update_row" *.py \| grep -v "tenant_id"` | 1. CRÍTICO: auditar inmediatamente toda función `find_row()` y `update_row()`<br>2. Toda búsqueda de fila DEBE incluir verificación de tenant_id en columna B<br>3. Patrón correcto: `if row[0] == record_id AND row[1] == tenant_id`<br>4. Agregar test de aislamiento: insertar en tenant_A, intentar modificar desde tenant_B → debe fallar |
| 7 | `ValueError: invalid literal for int() with base 10: 'TRUE'` al leer columna booleana | Google Sheets almacena checkboxes como `"TRUE"/"FALSE"` string, no boolean nativo | `print(type(row[6]), repr(row[6]))` para ver el tipo real | 1. Normalizar en código: `disponible = str(row[6]).upper() in ("TRUE", "1", "SIM", "YES")`<br>2. Para números: `precio = float(str(row[5]).replace(",", ".")) if row[5] else 0.0`<br>3. Para fechas: `fecha = str(row[3]).strip()` — pueden venir con espacios<br>4. Documentar en el schema de la hoja qué tipo se espera en cada columna |
| 8 | Los mensajes de WhatsApp llegan pero ninguna reserva aparece en Sheets | n8n ejecuta el nodo Sheets con éxito (HTTP 200) pero `valueInputOption` incorrecto hace que los datos se inserten como texto no parseado | Verificar el spreadsheet directamente en Google Drive — abrir y ver si las filas tienen datos | 1. Cambiar `valueInputOption` de `"RAW"` a `"USER_ENTERED"` en el nodo n8n de Sheets<br>2. `RAW` inserta texto literal (fechas como string, no reconoce fórmulas)<br>3. `USER_ENTERED` permite que Sheets interprete fechas, números y booleanos correctamente<br>4. Revisar que el campo `range` del nodo Sheets sea `"reservas!A:A"` para append |
| 9 | Duplicados: la misma reserva aparece 2 o 3 veces en la hoja | Timeout en n8n causa retry automático del webhook, insertando múltiples veces | `SELECT id, COUNT(*) FROM reservas GROUP BY id HAVING COUNT(*) > 1` — no aplica en Sheets, buscar manualmente | 1. Implementar idempotencia: antes del INSERT, buscar si ya existe un registro con el mismo `telefono + fecha + hora + tenant_id`<br>2. Si existe → retornar el existente sin insertar<br>3. Configurar timeout más largo en n8n: `WEBHOOK_TIMEOUT=60000` (60s)<br>4. En n8n: deshabilitar retry automático en el nodo Sheets para inserts |
| 10 | `HttpError 500: Internal error encountered` de forma intermitente | Fallo transitorio de la API de Google (ocurre ~0.1% de los requests) — la API de Sheets no tiene 100% de SLA en plan gratuito | `curl -s "https://www.googlestatus.com/api.json" \| python3 -m json.tool \| grep -A2 "Google Sheets"` | 1. El retry con backoff exponencial del `SheetsClient` ya cubre esto<br>2. Verificar que `max_retries=3` y `delay=500ms` están configurados<br>3. Si es frecuente (> 5 veces/día): verificar el status de la API en `status.cloud.google.com`<br>4. Como último recurso: reducir carga o migrar a MySQL para operaciones críticas |
| 11 | La búsqueda por nombre de cliente retorna resultados de otros tenants | `client.read()` trae todas las filas y el filtro de tenant_id no se aplica en la búsqueda posterior | `grep -n "read(" *.py \| grep -v "find_rows_by_tenant"` — buscar lecturas sin filtro C4 | 1. Reemplazar `client.read(hoja)` + filtro manual por `client.find_rows_by_tenant(hoja)` siempre<br>2. La función `find_rows_by_tenant` filtra por columna B (tenant_id) automáticamente<br>3. Audit completo: toda llamada a `read()` debe ser seguida inmediatamente de un filtro `if row[1] == tenant_id`<br>4. Agregar test: `assert all(r['tenant_id'] == tenant_id for r in results)` |
| 12 | Las fechas insertadas desde Python aparecen en formato incorrecto en Sheets (`44927` en vez de `2026-04-15`) | Google Sheets almacena fechas internamente como números de serie. Sin `valueInputOption="USER_ENTERED"` inserta el número | Abrir Sheets y ver si la celda muestra un número en vez de fecha | 1. Asegurarse de usar siempre `valueInputOption="USER_ENTERED"` (no `RAW`)<br>2. Para fechas: insertar como string `"2026-04-15"` (Sheets lo parsea como fecha automáticamente)<br>3. Para timestamps: usar `"2026-04-15T14:30:00"` — Sheets lo reconoce<br>4. Si la celda ya tiene formato de número: seleccionar columna → Formato → Número → Fecha |
| 13 | `MemoryError` en VPS durante lectura de hoja con 50.000+ filas | `client.read()` descarga todas las filas en RAM de una vez; a 50K filas la respuesta pesa > 50MB | `docker stats n8n --no-stream` durante la operación | 1. C1: Si la hoja supera 10.000 filas → migrar esa hoja a MySQL<br>2. Como mitigación temporal: leer por rangos específicos `"reservas!A1:L1000"` y procesar en páginas<br>3. Agregar límite en el schedule de backup: `rows[:5000]` — no intentar backupear hojas enormes<br>4. Implementar limpieza mensual: archivar reservas completadas > 6 meses en una hoja `"reservas_archivo_YYYY"` |
| 14 | El Service Account funciona en dev pero falla en producción con `HttpError 401` | La Private Key tiene saltos de línea (`\n`) que se corrompen al pasarla como variable de entorno sin codificación | `echo $GOOGLE_PRIVATE_KEY_B64 \| base64 -d \| head -3` — debe mostrar `-----BEGIN RSA PRIVATE KEY-----` | 1. Codificar la key en base64 al guardar: `base64 -w 0 <(cat key.json \| python3 -c "import json,sys; print(json.load(sys.stdin)['private_key'])")`<br>2. En el código Python: decodificar antes de usar: `pk = base64.b64decode(os.environ['GOOGLE_PRIVATE_KEY_B64']).decode()`<br>3. NUNCA usar la private key directamente como env var con saltos de línea — siempre base64<br>4. Verificar en Docker: `docker exec n8n env \| grep GOOGLE_PRIVATE` — confirmar que no está truncada |
| 15 | Los datos del menú en Qdrant (RAG) están desactualizados — el agente responde con precios viejos | El pipeline de sync Sheets → Qdrant no se ejecuta automáticamente cuando el dueño actualiza el menú en Sheets | Ver fecha del último chunk en Qdrant: `client.scroll(collection, with_payload=True, limit=5)` → ver `updated_at` en payload | 1. Implementar webhook de Google Drive: cuando el spreadsheet cambia → trigger en n8n → re-ingestar la hoja menú en Qdrant<br>2. Como alternativa más simple: cron diario a las 06:00 AM que ejecuta `exportar_menu_para_rag()` (Ejemplo E-14) + re-ingesta en Qdrant<br>3. En el agente WhatsApp: verificar precios consultando Sheets en tiempo real (E-8) en vez de solo confiar en el RAG para datos que cambian frecuentemente<br>4. Agregar `content_hash` al chunk de Qdrant y comparar antes de re-insertar (ver `rag-system-updates-all-engines.md`, sección Qdrant Ejemplo Q-5) |

---

## ✅ Validación SDD y Comandos de Prueba

### Script de Validación Completo

```bash
#!/bin/bash
# validate-google-sheets-db.sh
# Verifica que la integración Sheets cumple C1-C5
set -euo pipefail

TENANT="${1:-test_tenant_001}"
PASS=0; FAIL=0

check() {
    local desc="$1"; local cmd="$2"; local expected="$3"; local constraint="$4"
    result=$(eval "$cmd" 2>/dev/null || echo "ERROR")
    if echo "$result" | grep -qiP "$expected"; then
        echo "✅ ${constraint}: ${desc}"; ((PASS++))
    else
        echo "❌ ${constraint} FAIL: ${desc} | Obtenido: ${result:0:80}"; ((FAIL++))
    fi
}

echo "═══ VALIDACIÓN GOOGLE SHEETS AS DATABASE ═══ tenant: $TENANT"

# C3: Service Account configurado (no hardcodeado)
check "GOOGLE_SA_EMAIL configurado como env var" \
    "[ -n \"${GOOGLE_SA_EMAIL:-}\" ] && echo 'ok'" "ok" "C3"

check "Private Key en base64, no en texto plano" \
    "echo \"${GOOGLE_PRIVATE_KEY_B64:-}\" | base64 -d | head -1" \
    "BEGIN.*PRIVATE KEY" "C3"

# C4: Spreadsheet ID por tenant
check "Spreadsheet ID configurado para tenant" \
    "python3 -c \"import os; k='SHEETS_ID_${TENANT^^}'; print('ok' if os.environ.get(k) else 'missing')\"" \
    "ok" "C4"

# C4: Validación en SheetsClient
check "SheetsClient rechaza tenant_id vacío" \
    "python3 -c \"
from sheets_client import SheetsClient
try:
    SheetsClient(tenant_id='')
    print('FAIL')
except ValueError as e:
    print('ok' if 'C4' in str(e) else 'FAIL')
\"" "ok" "C4"

# C2: Rate limiting configurado
check "SHEETS_MAX_REQUESTS_PER_MINUTE <= 55" \
    "python3 -c \"import os; v=int(os.environ.get('SHEETS_MAX_REQUESTS_PER_MINUTE',50)); print('ok' if v<=55 else 'fail')\"" \
    "ok" "C2"

# C5: Directorio de backup existe
check "Directorio /backups/sheets existe" \
    "[ -d /backups/sheets ] && echo 'ok' || echo 'missing'" "ok" "C5"

# C4: Código no tiene read() sin filtro de tenant_id
echo ""
echo "─── Verificación C4 en código fuente ───"
if find . -name "*.py" -exec grep -l "client.read\|sheets.values" {} \; 2>/dev/null \
    | xargs grep -l "for.*row in" 2>/dev/null \
    | xargs grep -L "tenant_id" 2>/dev/null \
    | grep -v "__pycache__\|test_" | head -5; then
    echo "⚠️ Archivos con posible lectura sin filtro tenant_id — revisar"
    ((FAIL++))
else
    echo "✅ C4: Lecturas de Sheets incluyen filtro tenant_id"
    ((PASS++))
fi

echo ""
echo "═══════════════════════════════════════════"
echo "RESULTADO: ✅ $PASS pasaron | ❌ $FAIL fallaron"
[ $FAIL -eq 0 ] && echo "🎉 Google Sheets DB cumple todos los constraints SDD" && exit 0 || exit 1
```

### Test de Aislamiento Multi-Tenant

```python
# test_sheets_isolation.py
"""
Verifica que tenant_A no puede ver ni modificar datos de tenant_B.
Ejecutar antes de cada deploy con clientes nuevos.
"""
def test_isolation():
    # Asumir que ambos tenants tienen spreadsheets configurados
    import os

    tenant_a = "test_tenant_a"
    tenant_b = "test_tenant_b"

    if not os.environ.get(f"SHEETS_ID_{tenant_a.upper()}"):
        print("⚠️ Skip: SHEETS_ID_TEST_TENANT_A no configurado")
        return

    from sheets_client import SheetsClient
    import uuid
    from datetime import datetime, timezone

    client_a = SheetsClient(tenant_id=tenant_a)
    client_b = SheetsClient(tenant_id=tenant_b)

    # Insertar registro en tenant_a
    test_id = str(uuid.uuid4())
    now     = datetime.now(timezone.utc).isoformat()
    client_a.append("config", [
        test_id,
        tenant_a,                    # C4: tenant_a
        "test_isolation_key",
        "valor_secreto_tenant_a",
        now
    ])

    # Buscar desde tenant_b — NO debe encontrar el registro de tenant_a
    rows_b = client_b.find_rows_by_tenant("config")   # C4: filtra por tenant_b
    ids_b  = [r[0] for _, r in rows_b]

    assert test_id not in ids_b, (
        f"❌ AISLAMIENTO ROTO: tenant_b puede ver registro de tenant_a (id={test_id})"
    )
    print("✅ Aislamiento tenant_a/tenant_b correcto en Google Sheets (C4)")

    # Limpiar: cancelar el registro de prueba
    all_rows = client_a.read("config")
    for i, row in enumerate(all_rows):
        if str(row[0]) == test_id:
            updated = list(row)
            if len(updated) > 3:
                updated[3] = "DELETED_TEST"
            client_a.update_row("config", i + 1, updated)
            break

    print("✅ Cleanup completado")

if __name__ == "__main__":
    test_isolation()
```

---

## 🔗 Referencias Cruzadas

- [[01-RULES/06-MULTITENANCY-RULES.md]] — MT-001 a MT-010 (tenant_id en toda operación)
- [[01-RULES/02-RESOURCE-GUARDRAILS.md]] — RES-002 (C2: throttle API), RES-004 (polling mínimo)
- [[01-RULES/04-API-RELIABILITY-RULES.md]] — Retry con backoff, timeout 30s, circuit breaker
- [[00-CONTEXT/facundo-infrastructure.md]] — Stack VPS; Sheets es BD cloud sin consumo local
- [[02-SKILLS/BASE DE DATOS-RAG/mysql-sql-rag-ingestion.md]] — Migrar a MySQL cuando Sheets supere 10K filas/mes
- [[02-SKILLS/BASE DE DATOS-RAG/rag-system-updates-all-engines.md]] — Sync Sheets → Qdrant para RAG
- [[02-SKILLS/BASE DE DATOS-RAG/supabase-rag-integration.md]] — Alternativa cloud con más capacidad
- [[02-SKILLS/COMUNICACION/gmail-smtp-integration.md]] — Notificaciones de reservas por email
- [[02-SKILLS/RESTAURANTES/restaurant-booking-ai.md]] — Agente que usa este skill
- [[02-SKILLS/HOTELES-POSADAS/hotel-receptionist-whatsapp.md]] — Agente que usa este skill
- [[02-SKILLS/INFRAESTRUCTURA/redis-session-management.md]] — Cache de lecturas Sheets para reducir cuota API

**Skills pendientes que usan este archivo:**
- `02-SKILLS/BASE DE DATOS-RAG/db-selection-decision-tree.md` — Árbol de decisión que referencia a este skill
- `02-SKILLS/BASE DE DATOS-RAG/vertical-db-schemas.md` — Schemas completos que usan estas hojas
- `02-SKILLS/BASE DE DATOS-RAG/zip-package-db-templates.md` — Templates de ZIP que incluyen sheets configuradas
- `02-SKILLS/AGENTES/whatsapp-rag-openrouter.md` — Consume `get_config()` y `upsert_cliente()` de este skill
