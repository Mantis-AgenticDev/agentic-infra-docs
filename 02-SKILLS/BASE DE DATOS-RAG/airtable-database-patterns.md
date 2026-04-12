---
title: "airtable-database-patterns"
category: "Skill"
domain: ["generico", "backend", "database", "multi-tenant", "rag"]
constraints: ["C1", "C2", "C3", "C4", "C5", "C6"]
priority: "Alta"
version: "1.0.0"
last_updated: "2026-04-10"
ai_optimized: true
tags:
  - sdd/skill/airtable
  - sdd/skill/database
  - sdd/skill/multi-tenant
  - sdd/skill/n8n
  - sdd/skill/restaurantes
  - sdd/skill/leads
  - sdd/skill/rag
  - lang/es
related_files:
  - "01-RULES/06-MULTITENANCY-RULES.md"
  - "01-RULES/02-RESOURCE-GUARDRAILS.md"
  - "01-RULES/04-API-RELIABILITY-RULES.md"
  - "00-CONTEXT/facundo-infrastructure.md"
  - "02-SKILLS/BASE DE DATOS-RAG/google-sheets-as-database.md"
  - "02-SKILLS/BASE DE DATOS-RAG/mysql-sql-rag-ingestion.md"
  - "02-SKILLS/BASE DE DATOS-RAG/db-selection-decision-tree.md"
  - "02-SKILLS/RESTAURANTES/restaurant-google-maps-leadgen.md"
  - "02-SKILLS/RESTAURANTES/restaurant-booking-ai.md"
---

## 🎯 Propósito y Alcance

Airtable como **base de datos relacional visual** para agentes MANTIS AGENTIC en clientes que necesitan más estructura que Google Sheets pero sin infraestructura de servidor. Es el motor de persistencia ideal para restaurantes con catálogos de menú complejos, pipelines de leads con múltiples campos, y operaciones donde el cliente quiere ver y editar sus datos sin conocimientos técnicos.

### ¿Qué es Airtable para un desarrollador?

Para un junior: Airtable es como Google Sheets pero con tipos de campo reales (fecha, select, attachment, relación) y una API REST bien diseñada.

Para un senior: Airtable es una base de datos relacional NoSQL hosteada, con modelo de datos por `Base → Table → Record → Field`, API REST paginada con cursor, webhooks nativos, y un plan gratuito con 1.000 records por base y 100 API calls/mes que en producción real necesitará plan Team mínimo.

```
Modelo de datos Airtable vs SQL:
─────────────────────────────────────────────────
Base (Workspace)    ←→   Database / Schema
Table               ←→   Tabla
Record              ←→   Fila (con ID único: recXXXXXXXXXXXXXX)
Field               ←→   Columna (con tipo estricto)
View                ←→   SELECT personalizado (no modifica datos)
Linked Record Field ←→   Foreign Key visual (bidireccional)
Formula Field       ←→   Columna calculada (computed column)
Lookup Field        ←→   JOIN desnormalizado (read-only)
```

### Cuándo usar Airtable (Árbol de Decisión)

```
Cliente nuevo → ¿Qué necesita?
       │
       ├── Catálogo de productos/menú con imágenes + categorías
       │   └── ✅ Airtable (campos de tipo Attachment + Single Select)
       │
       ├── Pipeline de leads con etapas visuales (Kanban)
       │   └── ✅ Airtable (vista Kanban nativa + campo Status)
       │
       ├── Relaciones entre entidades (pedidos ↔ clientes ↔ productos)
       │   └── ✅ Airtable (Linked Records)
       │
       ├── El cliente quiere editar datos sin programar
       │   └── ✅ Airtable (interfaz visual + permisos por vista)
       │
       ├── > 50.000 registros/mes o queries complejas
       │   └── ❌ MySQL (ver mysql-sql-rag-ingestion.md)
       │
       └── Sin presupuesto para plan pago y > 1.000 registros
           └── ❌ Google Sheets (ver google-sheets-as-database.md)
```

### Límites Técnicos Críticos (Memorizar Antes de Producción)

| Límite | Plan Free | Plan Team | Plan Business | Consecuencia |
|---|---|---|---|---|
| Records por base | 1.000 | 50.000 | 125.000 | Error al intentar insertar más |
| API calls/mes | 100 | 5.000/mes por workspace | Ilimitado | HTTP 429 sin aviso previo |
| Tamaño attachment | 2GB total | 20GB | 100GB | Error al subir archivos grandes |
| Requests/seg | 5 req/s | 5 req/s | 10 req/s | Throttle silencioso + 429 |
| Registros por response (paginación) | 100 | 100 | 100 | Siempre paginar |
| Webhooks | 2 por base | 10 por base | 50 por base | Limita triggers automáticos |
| Retención audit log | 2 semanas | 6 meses | 3 años | C5: backup propio obligatorio |

**Regla para el ZIP generator:**
```
Plan Free   → Solo para demos y clientes con < 500 registros/mes
Plan Team   → Clientes reales (R$ 54/mes aprox en 2026)
Plan Business → Clientes con equipos o volumen alto
```

**Fuera de alcance:**
- Búsqueda semántica vectorial (→ Qdrant)
- Transacciones ACID (→ MySQL)
- Datos sensibles LGPD sin RLS (→ Supabase)
- Más de 50.000 records activos (→ MySQL)

---

## 📐 Fundamentos (Nivel Básico)

### Conceptos que el Junior DEBE entender antes de escribir código

**1. El ID de Airtable no es tuyo — es de Airtable**

```python
# ❌ NUNCA generes el ID tú mismo
record = {"id": "mi-uuid-generado", "fields": {"nombre": "João"}}

# ✅ Airtable genera el ID en el INSERT — usa el que retorna
result = airtable.create("Clientes", {"nombre": "João"})
record_id = result["id"]  # algo como "recXXXXXXXXXXXXXX"
```

**2. Los campos son por nombre, no por posición**

```python
# ❌ NO existe "columna B" en Airtable
fila[1]  # INCORRECTO — no hay índices de columna

# ✅ Accedes por nombre de campo exacto (case-sensitive)
record["fields"]["Nome do Cliente"]   # CORRECTO
record["fields"]["nome do cliente"]   # INCORRECTO — diferente case
```

**3. tenant_id es un campo como cualquier otro (C4)**

```python
# En Airtable, tenant_id es un campo Text en la tabla
# DEBE ser el primer campo creado en TODA tabla (C4)
# Nombre del campo: "tenant_id" (snake_case, minúsculas)

record["fields"]["tenant_id"]  # C4: SIEMPRE presente
```

**4. La paginación es por cursor, no por offset**

```python
# ❌ NO existe LIMIT/OFFSET como en SQL
# ✅ Airtable usa cursor (offset token) para paginar
response = airtable.get_all_records(
    table="Reservas",
    params={"pageSize": 100}  # máximo 100 por página
)
# Si hay más: response["offset"] contiene el token para la siguiente página
```

**5. Los Linked Records son arrays de IDs**

```python
# Cuando un campo es "Linked Record" (FK), su valor es una lista de IDs
record["fields"]["cliente_id"]  # → ["recABC123", "recDEF456"]
# Para FK 1:1, será lista de un elemento: ["recABC123"]
```

### Anatomía de un Record en Airtable

```json
{
  "id": "recXXXXXXXXXXXXXX",
  "createdTime": "2026-04-10T14:30:00.000Z",
  "fields": {
    "tenant_id":      "restaurante_001",
    "nombre":         "João Silva",
    "telefone":       "5551999887766",
    "data_reserva":   "2026-04-15",
    "hora":           "20:30",
    "pessoas":        4,
    "status":         "Confirmada",
    "canal":          "WhatsApp",
    "notas":          "Aniversário"
  }
}
```

### Tipos de Campo Airtable y sus Equivalentes SQL

```
Airtable Field Type    SQL Equivalente    Notas para el developer
───────────────────    ───────────────    ───────────────────────
Single line text       VARCHAR(255)       Máximo ~100.000 chars en práctica
Long text              TEXT               Soporta Markdown
Number                 DECIMAL / INT      Especificar precision en la config
Currency               DECIMAL(10,2)      Agrega símbolo automáticamente
Date                   DATE               Guardar como "YYYY-MM-DD"
Date + time            DATETIME           Formato ISO 8601
Checkbox               BOOLEAN            TRUE/FALSE
Single select          ENUM               Lista predefinida de opciones
Multiple select        SET / JSON array   Lista de strings
Linked record          FOREIGN KEY        Array de record IDs
Lookup                 JOIN (read-only)   Se calcula de linked records
Formula                COMPUTED COLUMN    Calculado por Airtable
Attachment             BLOB / file URL    URLs temporales (~2h de validez)
Email                  VARCHAR + validación
Phone                  VARCHAR
URL                    VARCHAR + validación
```

---

## 🏗️ Arquitectura y Hardware Limitado (VPS 2vCPU/4-8GB)

### Airtable No Consume RAM del VPS (Igual que Sheets)

```
VPS-1 con n8n ejecutando agente restaurante:
├── n8n process:         800MB RAM (workflows)
├── Redis (sesiones):    200MB RAM
├── OS + red:            400MB RAM
└── Airtable API calls:  ~3-8MB por request (solo JSON en tránsito)

Total: ~1.4GB — dentro de C1 (máx 1.5GB para n8n)

Pico de 10 reservas simultáneas:
10 × 8MB JSON = 80MB adicional temporal ← MANEJABLE ✅
```

### Throttle en VPS con Múltiples Clientes (C2)

```
Problema real: 3 clientes restaurante comparten el mismo VPS-1
cada uno con ~5 mensajes WhatsApp/minuto en hora pico

3 clientes × 5 mensajes × 2 llamadas Airtable = 30 req/min
Límite Airtable: 5 req/seg = 300 req/min → OK ✅

Pero si son 10 clientes:
10 × 5 × 2 = 100 req/min → todavía OK

Riesgo real: burst simultáneo (almuerzo de sábado)
Si 5 clientes mandan 20 mensajes en 10 segundos:
5 × 20 × 2 / 10s = 20 req/s → SUPERA el límite de 5 req/s ❌
```

**Mitigación en n8n:**
```javascript
// En nodo Function de n8n antes de cada llamada Airtable
// C2: Throttle para no superar 5 req/s
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
await delay(250); // 4 req/s máximo (con margen de seguridad)
```

### Docker: No hay contenedor Airtable

```yaml
# docker-compose.yml — Solo configurar credenciales en n8n
services:
  n8n:
    environment:
      # C3: Credenciales desde env vars, NUNCA hardcodeadas
      - AIRTABLE_API_TOKEN=${AIRTABLE_API_TOKEN}
    deploy:
      resources:
        limits:
          memory: 1500M   # C1
          cpus: "1.0"     # C2
```

---

## 🔗 Conexión y Autenticación

### Setup de Token de API (Una Vez por Proyecto)

```bash
# PASO 1: Crear Personal Access Token (PAT) en Airtable
# https://airtable.com/create/tokens
# Scopes necesarios:
#   - data.records:read
#   - data.records:write
#   - schema.bases:read
#   - webhook:manage (si se usan webhooks)

# PASO 2: Agregar al .env (C3: NUNCA al código fuente)
echo "AIRTABLE_API_TOKEN=patXXXXXXXXXXXXXX.XXXXXXXX" >> .env

# PASO 3: ID de cada Base por tenant (C4)
# El Base ID está en la URL: airtable.com/appXXXXXXXXXXXXXX/...
echo "AIRTABLE_BASE_RESTAURANTE_001=appXXXXXXXXXXXXXX" >> .env
echo "AIRTABLE_BASE_HOTEL_002=appYYYYYYYYYYYYYY" >> .env
echo "AIRTABLE_BASE_DENTAL_003=appZZZZZZZZZZZZZZ" >> .env

# PASO 4: Verificar acceso
curl -s "https://api.airtable.com/v0/meta/bases" \
  -H "Authorization: Bearer ${AIRTABLE_API_TOKEN}" \
  | python3 -m json.tool | grep '"name"'
```

### Variables de Entorno Completas

```bash
# .env.airtable — Una Base por tenant (C4: aislamiento)
# C3: .env en .gitignore

# Token compartido entre tenants (un token puede acceder múltiples Bases)
AIRTABLE_API_TOKEN=patXXXXXXXXXXXXXX.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# Base IDs por tenant (C4: cada tenant tiene su Base propia)
AIRTABLE_BASE_RESTAURANTE_001=appABC123DEF456GH
AIRTABLE_BASE_HOTEL_002=appIJK789LMN012OP
AIRTABLE_BASE_DENTAL_003=appQRS345TUV678WX

# Rate limiting (C2)
AIRTABLE_MAX_REQUESTS_PER_SEC=4      # 80% del límite de 5/s
AIRTABLE_RETRY_DELAY_MS=500
AIRTABLE_MAX_RETRIES=3
AIRTABLE_PAGE_SIZE=100               # Máximo permitido

# Nombres de tablas (consistentes entre todas las Bases)
AIRTABLE_TABLE_RESERVAS=Reservas
AIRTABLE_TABLE_CLIENTES=Clientes
AIRTABLE_TABLE_MENU=Menu
AIRTABLE_TABLE_PEDIDOS=Pedidos
AIRTABLE_TABLE_LEADS=Leads
AIRTABLE_TABLE_CONFIG=Config
```

### Cliente Python Reutilizable con Retry y C4

```python
# airtable_client.py
import os
import time
import requests
from typing import Optional

class AirtableClient:
    """
    Cliente Airtable con:
    C3: Token desde env var, nunca hardcodeado
    C4: tenant_id validado, Base ID por tenant
    C2: Rate limiting 4 req/s integrado
    Retry exponencial para 429 y 5xx (API-RELIABILITY-RULES)
    """

    BASE_URL = "https://api.airtable.com/v0"

    def __init__(self, tenant_id: str):
        # C4: tenant_id obligatorio
        if not tenant_id:
            raise ValueError("tenant_id required (C4)")

        self.tenant_id    = tenant_id
        self._last_req    = 0.0
        self._min_interval = 1.0 / float(
            os.environ.get("AIRTABLE_MAX_REQUESTS_PER_SEC", 4)
        )

        # C3: Token desde env var
        self.token = os.environ.get("AIRTABLE_API_TOKEN")
        if not self.token:
            raise ValueError(
                "AIRTABLE_API_TOKEN not set (C3: use env vars)"
            )

        # C4: Base ID específico del tenant
        env_key     = f"AIRTABLE_BASE_{tenant_id.upper()}"
        self.base_id = os.environ.get(env_key)
        if not self.base_id:
            raise ValueError(
                f"Base ID not found for tenant '{tenant_id}'. "
                f"Set env var {env_key} (C4)"
            )

        self.headers = {
            "Authorization": f"Bearer {self.token}",
            "Content-Type":  "application/json"
        }

    def _throttle(self):
        """C2: Rate limit automático entre requests."""
        elapsed = time.time() - self._last_req
        if elapsed < self._min_interval:
            time.sleep(self._min_interval - elapsed)
        self._last_req = time.time()

    def _request(
        self,
        method: str,
        path: str,
        payload: dict = None,
        params: dict = None,
        max_retries: int = 3
    ) -> dict:
        """
        Request HTTP con retry exponencial.
        API-RELIABILITY-RULES: backoff en 429 y 5xx.
        C2: timeout=30s obligatorio.
        """
        url   = f"{self.BASE_URL}/{self.base_id}/{path}"
        delay = float(os.environ.get("AIRTABLE_RETRY_DELAY_MS", 500)) / 1000

        for attempt in range(max_retries + 1):
            self._throttle()
            resp = requests.request(
                method,
                url,
                headers=self.headers,
                json=payload,
                params=params,
                timeout=30   # C2: timeout obligatorio
            )

            if resp.status_code in (429, 500, 503) and attempt < max_retries:
                wait = delay * (2 ** attempt)
                print(
                    f"[{self.tenant_id}] Airtable {resp.status_code} — "
                    f"retry {attempt+1}/{max_retries} en {wait:.1f}s"
                )
                time.sleep(wait)
                continue

            resp.raise_for_status()
            return resp.json()

        raise RuntimeError(f"Max retries exceeded for {method} {path}")

    # ── CRUD ────────────────────────────────────────────────────────

    def create(self, table: str, fields: dict) -> dict:
        """INSERT: Crea un record. C4: tenant_id en fields."""
        if "tenant_id" not in fields:
            raise ValueError(
                f"tenant_id missing in fields for table '{table}' (C4)"
            )
        if fields["tenant_id"] != self.tenant_id:
            raise ValueError(
                f"tenant_id mismatch: expected {self.tenant_id} (C4)"
            )
        return self._request("POST", table, {"fields": fields})

    def get(self, table: str, record_id: str) -> dict:
        """SELECT por ID. Verifica tenant_id en el resultado (C4)."""
        record = self._request("GET", f"{table}/{record_id}")
        if record.get("fields", {}).get("tenant_id") != self.tenant_id:
            raise PermissionError(
                f"Record {record_id} does not belong to tenant "
                f"{self.tenant_id} (C4)"
            )
        return record

    def update(self, table: str, record_id: str, fields: dict) -> dict:
        """UPDATE parcial (PATCH). C4: nunca modifica tenant_id."""
        fields.pop("tenant_id", None)  # Proteger tenant_id contra cambio
        return self._request("PATCH", f"{table}/{record_id}", {"fields": fields})

    def delete(self, table: str, record_id: str) -> dict:
        """
        DELETE físico. Usar solo si realmente se quiere borrar.
        Para soft-delete: usar update con status='cancelado'.
        C4: Verifica ownership antes de borrar.
        """
        self.get(table, record_id)  # Verifica tenant_id (C4)
        return self._request("DELETE", f"{table}/{record_id}")

    def list_records(
        self,
        table: str,
        filter_formula: str = None,
        sort: list = None,
        max_records: int = 1000,
        fields: list = None
    ) -> list[dict]:
        """
        SELECT con filtro. Pagina automáticamente.
        C4: SIEMPRE incluye filtro por tenant_id.
        C1: max_records=1000 como hard limit.
        """
        # C4: Inyectar filtro de tenant_id en TODA consulta
        tenant_filter = f"{{tenant_id}}='{self.tenant_id}'"
        if filter_formula:
            final_filter = f"AND({tenant_filter}, {filter_formula})"
        else:
            final_filter = tenant_filter

        params = {
            "filterByFormula": final_filter,
            "pageSize":        min(100, int(
                os.environ.get("AIRTABLE_PAGE_SIZE", 100)
            ))
        }
        if sort:
            for i, s in enumerate(sort):
                params[f"sort[{i}][field]"]     = s["field"]
                params[f"sort[{i}][direction]"] = s.get("direction", "asc")
        if fields:
            for i, f in enumerate(fields):
                params[f"fields[{i}]"] = f

        all_records = []
        offset      = None

        while len(all_records) < max_records:
            if offset:
                params["offset"] = offset

            response = self._request("GET", table, params=params)
            records  = response.get("records", [])
            all_records.extend(records)

            offset = response.get("offset")
            if not offset:
                break   # No hay más páginas

        return all_records[:max_records]

    def find_one(
        self,
        table: str,
        filter_formula: str
    ) -> Optional[dict]:
        """SELECT un registro. C4: tenant_id siempre incluido."""
        records = self.list_records(table, filter_formula, max_records=1)
        return records[0] if records else None
```

---

## 📘 Guía de Estructura de Bases y Tablas

### Schema por Vertical

#### Restaurante

```
Base: "Restaurante [Nombre]" (una Base por tenant — C4)
│
├── Tabla: Reservas
│   tenant_id        Text        PRIMER campo — C4
│   Nome             Text
│   Telefone         Phone
│   Data Reserva     Date
│   Hora             Single select  ["12:00","12:30","13:00",..."22:00","22:30"]
│   Pessoas          Number (integer)
│   Mesa             Text        Asignada por staff
│   Status           Single select  ["Pendente","Confirmada","Cancelada","Concluída"]
│   Canal            Single select  ["WhatsApp","Telegram","Web","Telefone"]
│   Notas            Long text
│   Cliente         Linked → Clientes   (FK 1:1)
│
├── Tabla: Clientes
│   tenant_id        Text        C4
│   Nome             Text
│   Telefone         Phone
│   Email            Email
│   Visitas          Number      Incrementar en cada reserva
│   Última Visita    Date
│   Preferências     Long text
│   Reservas         Linked → Reservas   (FK 1:N, backlink)
│
├── Tabla: Menu
│   tenant_id        Text        C4
│   Nome             Text
│   Categoria        Single select  ["Entradas","Pratos","Bebidas","Sobremesas"]
│   Preço            Currency (BRL)
│   Disponível       Checkbox    TRUE = aparece en el bot
│   Descrição        Long text
│   Imagem           Attachment
│   Ordem Display    Number      Para ordenar en el bot
│   Alérgenos        Multiple select  ["Glúten","Lactose","Frutos do mar",...]
│
├── Tabla: Pedidos
│   tenant_id        Text        C4
│   Cliente          Linked → Clientes
│   Itens            Long text   JSON array de items pedidos
│   Total            Currency (BRL)
│   Status           Single select  ["Recebido","Preparando","Pronto","Entregue","Cancelado"]
│   Canal            Single select
│   Endereço Entrega Text        Solo si es delivery
│   Created At       Created time   Auto-generado por Airtable
│
└── Tabla: Config
    tenant_id        Text        C4
    Chave            Text        Snake_case: horario_abertura, mensagem_boas_vindas
    Valor            Long text
    Atualizado Em    Last modified time   Auto-generado

──────────────────────────────────────────────────────

Restaurante — Tabla Leads (pipeline de captación):
│
└── Tabla: Leads (para agente de Google Maps + Apify)
    tenant_id        Text        C4
    Nome Empresa     Text
    Telefone         Phone
    Email            Email
    Endereço         Text
    Cidade           Text
    Rating Google    Number
    Avaliações       Number
    Tem WhatsApp     Checkbox
    Status Pipeline  Single select  ["Novo","Contato Feito","Interessado",
                                    "Demo Agendada","Fechado","Descartado"]
    Fonte            Single select  ["Google Maps","Indicação","Apify","Manual"]
    Notas            Long text
    Data Contato     Date
    Responsável      Text
```

#### Hotel/Posada

```
Base: "Hotel [Nombre]"
├── Huéspedes (id, tenant_id, nombre, telefono, email,
│              checkin, checkout, habitacion, adultos,
│              ninos, status, canal, total_usd, notas)
├── Habitaciones (id, tenant_id, numero, tipo, capacidad,
│                 precio_noche, disponible, amenities, descripcion)
├── Mensajes Programados (id, tenant_id, huesped_id→Huéspedes,
│                         tipo, enviado, canal, contenido)
└── Config (tenant_id, chave, valor)
```

#### Odontología

```
Base: "Clínica [Nombre]"
├── Pacientes (id, tenant_id, nombre, telefono, email,
│              cpf, convenio, alergias, notas_medicas)
├── Citas (id, tenant_id, paciente→Pacientes, dentista,
│          fecha, hora, duracion_min, tratamiento,
│          status, sala, recordatorio_enviado)
└── Tratamientos (id, tenant_id, nombre, duracion_min,
                  precio, descripcion, sesiones)
```

### Diagrama de Relaciones (Restaurante)

```
Clientes ──1:N──→ Reservas
    │                 │
    │                 └── Status: Pendente→Confirmada→Concluída
    │
    └──1:N──→ Pedidos
                  │
                  └── Itens (JSON de IDs de Menu)

Menu ─────────────────────────────────────────
     ↑ Referenciado en Pedidos.Itens (no linked record)
     (Airtable Linked Record en Pedidos es opcional;
      para simplicidad usar JSON array de nombres+precios)
```

---

## 🛠️ 10 Ejemplos

### A-1: INSERT — Nueva Reserva de Restaurante

```python
# airtable_ejemplo_01_crear_reserva.py
import uuid
from datetime import datetime, timezone

def crear_reserva_airtable(
    tenant_id: str,     # C4
    nombre:    str,
    telefone:  str,
    data:      str,     # YYYY-MM-DD
    hora:      str,     # HH:MM — debe existir en Single Select
    pessoas:   int,
    canal:     str = "WhatsApp",
    notas:     str = ""
) -> dict:
    """
    Crea una reserva en Airtable.
    C4: tenant_id en fields — validado por AirtableClient.create().
    Retorna record_id de Airtable para usar en confirmación.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    client = AirtableClient(tenant_id=tenant_id)

    fields = {
        "tenant_id":    tenant_id,       # C4: PRIMER campo
        "Nome":         nombre,
        "Telefone":     telefone,
        "Data Reserva": data,
        "Hora":         hora,
        "Pessoas":      pessoas,
        "Status":       "Pendente",
        "Canal":        canal,
        "Notas":        notas
    }

    record = client.create("Reservas", fields)

    # C5: Log estructurado
    import json
    print(json.dumps({
        "timestamp":    datetime.now(timezone.utc).isoformat(),
        "tenant_id":    tenant_id,       # C4
        "event":        "reserva_created",
        "airtable_id":  record["id"],
        "data":         data,
        "hora":         hora,
        "canal":        canal
    }))

    return {
        "id":        record["id"],
        "tenant_id": tenant_id,          # C4
        "status":    "Pendente",
        "data":      data,
        "hora":      hora,
        "mensagem":  f"Reserva recebida para {data} às {hora} ✅"
    }

# Uso
res = criar_reserva_airtable(
    tenant_id = "restaurante_001",
    nome      = "João Silva",
    telefone  = "5551999887766",
    data      = "2026-04-15",
    hora      = "20:30",
    pessoas   = 4,
    canal     = "WhatsApp"
)
print(f"Airtable ID: {res['id']}")
# Output: "Airtable ID: recXXXXXXXXXXXXXX"
```

---

### A-2: READ con Filtro — Reservas del Día

```python
# airtable_ejemplo_02_reservas_del_dia.py
def get_reservas_del_dia(
    tenant_id: str,   # C4
    data:      str    # YYYY-MM-DD
) -> list[dict]:
    """
    Lista reservas activas de un día.
    C4: AirtableClient.list_records() inyecta filtro tenant_id automáticamente.
    C1: max_records=200 — suficiente para cualquier restaurante.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    client = AirtableClient(tenant_id=tenant_id)

    # Fórmula Airtable: IS_{data} usando campo Date
    # DATESTR() convierte campo Date a string "YYYY-MM-DD"
    formula = (
        f"AND("
        f"  DATESTR({{Data Reserva}})='{data}', "
        f"  {{Status}}!='Cancelada'"
        f")"
    )

    records = client.list_records(
        table          = "Reservas",
        filter_formula = formula,
        sort           = [{"field": "Hora", "direction": "asc"}],
        max_records    = 200    # C1: límite razonable
    )

    return [
        {
            "id":       r["id"],
            "tenant_id": r["fields"].get("tenant_id"),   # C4
            "nome":      r["fields"].get("Nome", ""),
            "telefone":  r["fields"].get("Telefone", ""),
            "hora":      r["fields"].get("Hora", ""),
            "pessoas":   r["fields"].get("Pessoas", 0),
            "mesa":      r["fields"].get("Mesa", ""),
            "status":    r["fields"].get("Status", ""),
            "canal":     r["fields"].get("Canal", "")
        }
        for r in records
    ]

# Uso
reservas = get_reservas_del_dia("restaurante_001", "2026-04-15")
print(f"Total reservas hoje: {len(reservas)}")
for r in reservas:
    print(f"  {r['hora']} — {r['nome']} × {r['pessoas']} pessoas — {r['status']}")
```

---

### A-3: UPDATE — Confirmar Reserva y Asignar Mesa

```python
# airtable_ejemplo_03_confirmar_reserva.py
def confirmar_reserva(
    tenant_id:  str,   # C4
    record_id:  str,
    mesa:       str
) -> dict:
    """
    Actualiza status → 'Confirmada' y asigna mesa.
    AirtableClient.get() verifica tenant_id antes de actualizar (C4).
    PATCH en Airtable = UPDATE parcial (no sobreescribe campos no enviados).
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    client = AirtableClient(tenant_id=tenant_id)

    # get() ya verifica que el record pertenece al tenant (C4)
    current = client.get("Reservas", record_id)
    if current["fields"].get("Status") == "Cancelada":
        raise ValueError(
            f"No se puede confirmar una reserva cancelada: {record_id}"
        )

    updated = client.update("Reservas", record_id, {
        "Status": "Confirmada",
        "Mesa":   mesa
    })

    return {
        "tenant_id":  tenant_id,        # C4
        "record_id":  record_id,
        "status":     "Confirmada",
        "mesa":       mesa,
        "nome":       updated["fields"].get("Nome")
    }
```

---

### A-4: UPSERT — Registrar o Actualizar Cliente (CRM)

```python
# airtable_ejemplo_04_upsert_cliente.py
def upsert_cliente_airtable(
    tenant_id:    str,    # C4
    telefone:     str,
    nome:         str,
    preferencias: str = ""
) -> dict:
    """
    Crea cliente si no existe, actualiza visitas si ya existe.
    C4: Búsqueda incluye tenant_id automáticamente en list_records().
    Airtable no tiene UPSERT nativo — implementar con find_one + create/update.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    from datetime import datetime

    client  = AirtableClient(tenant_id=tenant_id)
    today   = datetime.utcnow().strftime("%Y-%m-%d")

    # Buscar por teléfono (C4 ya incluido por list_records)
    formula  = f"{{Telefone}}='{telefone}'"
    existing = client.find_one("Clientes", formula)

    if existing:
        visitas = int(existing["fields"].get("Visitas", 0)) + 1
        update_fields = {
            "Nome":          nome,
            "Visitas":       visitas,
            "Última Visita": today
        }
        if preferencias:
            update_fields["Preferências"] = preferencias

        updated = client.update("Clientes", existing["id"], update_fields)
        return {
            "action":    "updated",
            "tenant_id": tenant_id,        # C4
            "id":        existing["id"],
            "visitas":   visitas
        }

    # Cliente nuevo
    record = client.create("Clientes", {
        "tenant_id":     tenant_id,        # C4
        "Nome":          nome,
        "Telefone":      telefone,
        "Visitas":       1,
        "Última Visita": today,
        "Preferências":  preferencias
    })
    return {
        "action":    "created",
        "tenant_id": tenant_id,            # C4
        "id":        record["id"]
    }
```

---

### A-5: Pipeline de Leads — Google Maps + Apify → Airtable

```python
# airtable_ejemplo_05_leads_pipeline.py
def registrar_lead_google_maps(
    tenant_id:      str,     # C4
    nome_empresa:   str,
    telefone:       str,
    endereco:       str,
    cidade:         str,
    rating_google:  float,
    avaliacoes:     int,
    tem_whatsapp:   bool,
    fonte:          str = "Google Maps"
) -> dict:
    """
    Inserta lead captado por Apify desde Google Maps.
    C4: tenant_id en cada lead.
    Verifica duplicado por telefone antes de insertar.
    Para usar en el agente restaurant-google-maps-leadgen.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    client = AirtableClient(tenant_id=tenant_id)

    # Anti-duplicado: verificar si el teléfono ya existe para este tenant (C4)
    formula   = f"{{Telefone}}='{telefone}'"
    existing  = client.find_one("Leads", formula)

    if existing:
        return {
            "action":    "skipped_duplicate",
            "tenant_id": tenant_id,        # C4
            "id":        existing["id"],
            "telefone":  telefone
        }

    record = client.create("Leads", {
        "tenant_id":      tenant_id,       # C4
        "Nome Empresa":   nome_empresa,
        "Telefone":       telefone,
        "Endereço":       endereco,
        "Cidade":         cidade,
        "Rating Google":  rating_google,
        "Avaliações":     avaliacoes,
        "Tem WhatsApp":   tem_whatsapp,
        "Status Pipeline":"Novo",
        "Fonte":          fonte,
        "Data Contato":   __import__("datetime").datetime.utcnow().strftime("%Y-%m-%d")
    })

    return {
        "action":    "created",
        "tenant_id": tenant_id,            # C4
        "id":        record["id"],
        "empresa":   nome_empresa
    }

def avanzar_lead_pipeline(
    tenant_id:   str,    # C4
    record_id:   str,
    nuevo_status: str,
    notas:       str = ""
) -> dict:
    """
    Avanza un lead en el pipeline de ventas.
    Statuses válidos: Novo → Contato Feito → Interessado →
                      Demo Agendada → Fechado | Descartado
    """
    STATUSES_VALIDOS = [
        "Novo", "Contato Feito", "Interessado",
        "Demo Agendada", "Fechado", "Descartado"
    ]
    if nuevo_status not in STATUSES_VALIDOS:
        raise ValueError(
            f"Status inválido: '{nuevo_status}'. "
            f"Válidos: {STATUSES_VALIDOS}"
        )

    client = AirtableClient(tenant_id=tenant_id)
    fields = {"Status Pipeline": nuevo_status}
    if notas:
        fields["Notas"] = notas

    updated = client.update("Leads", record_id, fields)
    return {
        "tenant_id": tenant_id,           # C4
        "id":        record_id,
        "status":    nuevo_status
    }
```

---

### A-6: READ Menú para Bot WhatsApp (con Cache)

```python
# airtable_ejemplo_06_menu_con_cache.py
import json, time

# Cache simple en memoria (reemplazar por Redis en producción - ver redis-session-management.md)
_menu_cache: dict[str, tuple[list, float]] = {}
MENU_CACHE_TTL = 300  # 5 minutos (C1: evitar llamadas repetidas a Airtable)

def get_menu_disponivel(
    tenant_id:  str,     # C4
    categoria:  str = None,
    force_refresh: bool = False
) -> list[dict]:
    """
    Lee menú disponible con cache de 5 minutos.
    C1: Cache evita hits a Airtable en cada mensaje WhatsApp.
    C4: Cache key incluye tenant_id para no mezclar menús.
    C2: Sin cache, 100 mensajes/min = 100 req Airtable → supera límite.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    # C4: Cache key con tenant_id para aislamiento
    cache_key = f"{tenant_id}:menu"
    if categoria:
        cache_key += f":{categoria}"

    # Verificar cache (C1: evitar requests innecesarios)
    if not force_refresh and cache_key in _menu_cache:
        cached_data, cached_at = _menu_cache[cache_key]
        if time.time() - cached_at < MENU_CACHE_TTL:
            return cached_data

    client = AirtableClient(tenant_id=tenant_id)

    formula = "{Disponível}=TRUE()"
    if categoria:
        formula = f"AND({formula}, {{Categoria}}='{categoria}')"

    records = client.list_records(
        table          = "Menu",
        filter_formula = formula,
        sort           = [
            {"field": "Categoria",     "direction": "asc"},
            {"field": "Ordem Display", "direction": "asc"}
        ],
        fields=["tenant_id", "Nome", "Categoria", "Preço",
                "Descrição", "Alérgenos", "Ordem Display"]
    )

    menu = [
        {
            "id":         r["id"],
            "tenant_id":  r["fields"].get("tenant_id"),  # C4
            "nome":       r["fields"].get("Nome", ""),
            "categoria":  r["fields"].get("Categoria", ""),
            "preco":      float(r["fields"].get("Preço", 0)),
            "descricao":  r["fields"].get("Descrição", ""),
            "alergenos":  r["fields"].get("Alérgenos", []),
            "ordem":      int(r["fields"].get("Ordem Display") or 999)
        }
        for r in records
    ]

    # Guardar en cache (C1)
    _menu_cache[cache_key] = (menu, time.time())
    return menu

def formatar_menu_whatsapp(tenant_id: str) -> str:
    """Formata el menú para enviar por WhatsApp."""
    itens  = get_menu_disponivel(tenant_id)
    if not itens:
        return "Cardápio indisponível no momento."

    cats   = {}
    for item in itens:
        cat = item["categoria"]
        cats.setdefault(cat, []).append(item)

    texto = "🍽️ *Nosso Cardápio*\n\n"
    for cat, items in cats.items():
        texto += f"*{cat}*\n"
        for i in items:
            alerg = f" ⚠️ {', '.join(i['alergenos'])}" if i["alergenos"] else ""
            texto += f"• {i['nome']} — R$ {i['preco']:.2f}{alerg}\n"
            if i["descricao"]:
                texto += f"  _{i['descricao']}_\n"
        texto += "\n"
    return texto
```

---

### A-7: Webhook Airtable → n8n (Notificación de Cambio de Status)

```python
# airtable_ejemplo_07_webhook_setup.py
import os, requests

def registrar_webhook_airtable(
    tenant_id:    str,   # C4
    n8n_url:      str,   # URL del webhook en n8n
    tabla:        str = "Reservas",
    eventos:      list = None
) -> dict:
    """
    Registra un webhook en Airtable para notificar a n8n
    cuando cambia el status de una reserva.
    C3: n8n_url debe ser interna o protegida, no pública sin auth.
    C4: Los payloads del webhook incluirán tenant_id del campo.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    if eventos is None:
        eventos = ["tableData.changed"]

    token   = os.environ["AIRTABLE_API_TOKEN"]
    base_id = os.environ[f"AIRTABLE_BASE_{tenant_id.upper()}"]

    # Obtener table ID desde la metadata
    meta = requests.get(
        f"https://api.airtable.com/v0/meta/bases/{base_id}/tables",
        headers={"Authorization": f"Bearer {token}"},
        timeout=30    # C2
    ).json()

    table_id = next(
        (t["id"] for t in meta.get("tables", []) if t["name"] == tabla),
        None
    )
    if not table_id:
        raise ValueError(f"Tabla '{tabla}' no encontrada en base de {tenant_id}")

    # Registrar webhook
    resp = requests.post(
        f"https://api.airtable.com/v0/bases/{base_id}/webhooks",
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type":  "application/json"
        },
        json={
            "notificationUrl": n8n_url,
            "specification": {
                "options": {
                    "filters": {
                        "fromSources":       ["client"],
                        "dataTypes":         ["tableData"],
                        "recordChangeScope": table_id
                    }
                }
            }
        },
        timeout=30    # C2
    )
    resp.raise_for_status()

    return {
        "tenant_id":  tenant_id,    # C4
        "webhook_id": resp.json().get("id"),
        "tabla":      tabla,
        "n8n_url":    n8n_url
    }

# Handler en n8n para procesar el webhook de Airtable
WEBHOOK_HANDLER_N8N_CODE = """
// Nodo Function en n8n: procesar notificación de Airtable
const payload = $input.first().json;

// Extraer cambios del payload de Airtable
const cambios = payload.changedTablesById || {};

for (const [tableId, tableChanges] of Object.entries(cambios)) {
    const records = tableChanges.changedRecordsById || {};
    for (const [recordId, changes] of Object.entries(records)) {
        const currentFields = changes.current?.cellValuesByFieldId || {};
        // Nota: los field IDs en el webhook son diferentes a los nombres
        // Mapear IDs → nombres usando la metadata de la Base
    }
}

// C4: Extraer tenant_id del campo en el record
// (el webhook no incluye tenant_id directamente, hay que buscarlo)
return [{ json: { webhook_payload: payload } }];
"""
```

---

### A-8: Paginación Completa — Exportar Todos los Leads para RAG

```python
# airtable_ejemplo_08_exportar_leads_rag.py
def exportar_leads_para_rag(
    tenant_id: str    # C4
) -> list[dict]:
    """
    Exporta todos los leads de Airtable como chunks de texto
    para indexar en Qdrant como conocimiento del agente.
    Útil para que el bot responda "¿ya contactamos a esta empresa?"
    C4: tenant_id en cada chunk.
    C6: Embeddings se generan externamente con OpenRouter.
    Pagina automáticamente (list_records maneja la paginación).
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    import uuid, hashlib

    client  = AirtableClient(tenant_id=tenant_id)

    # Obtener todos los leads (paginación automática en list_records)
    records = client.list_records(
        table          = "Leads",
        filter_formula = "{Status Pipeline}!='Descartado'",
        fields         = ["tenant_id", "Nome Empresa", "Telefone",
                          "Cidade", "Rating Google", "Status Pipeline",
                          "Tem WhatsApp", "Notas"],
        max_records    = 5000    # C1: límite explícito
    )

    chunks = []
    for r in records:
        f     = r["fields"]
        texto = (
            f"Empresa: {f.get('Nome Empresa', '')}\n"
            f"Telefone: {f.get('Telefone', '')}\n"
            f"Cidade: {f.get('Cidade', '')}\n"
            f"Status no pipeline: {f.get('Status Pipeline', '')}\n"
            f"Rating Google: {f.get('Rating Google', '')}\n"
            f"Tem WhatsApp: {'Sim' if f.get('Tem WhatsApp') else 'Não'}\n"
        )
        if f.get("Notas"):
            texto += f"Notas: {f.get('Notas')}\n"

        chunk_id = str(uuid.uuid4())
        chunks.append({
            "id":           chunk_id,
            "tenant_id":    tenant_id,             # C4
            "source_type":  "airtable_leads",
            "source_id":    r["id"],               # Airtable record ID
            "text":         texto,
            "content_hash": hashlib.sha256(texto.encode()).hexdigest(),
            "metadata": {
                "airtable_table": "Leads",
                "empresa":        f.get("Nome Empresa"),
                "status":         f.get("Status Pipeline")
            }
        })

    # Siguiente paso: pasar a generate_embeddings_batch() → Qdrant
    # Ver qdrant-rag-ingestion.md
    return chunks
```

---

### A-9: Config Dinámica del Agente (Mensajes, Horarios, Políticas)

```python
# airtable_ejemplo_09_config_agente.py
import time

_config_cache: dict[str, tuple[dict, float]] = {}

def get_config_agente(
    tenant_id:      str,   # C4
    force_refresh:  bool = False
) -> dict:
    """
    Lee toda la configuración del agente desde tabla Config.
    Cache de 10 minutos (el dueño puede cambiar mensajes en Airtable
    y el bot los refleja sin redeploy).
    C4: Cache key con tenant_id.
    C1: Una sola llamada para toda la config, no una por clave.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    cache_key = f"{tenant_id}:config"
    if not force_refresh and cache_key in _config_cache:
        data, ts = _config_cache[cache_key]
        if time.time() - ts < 600:  # 10 minutos
            return data

    client  = AirtableClient(tenant_id=tenant_id)
    records = client.list_records(
        table   = "Config",
        fields  = ["tenant_id", "Chave", "Valor"]
    )

    config = {
        # Defaults razonables si el cliente no configuró algo
        "horario_abertura":      "12:00",
        "horario_fechamento":    "22:00",
        "mensagem_boas_vindas":  "Olá! Bem-vindo! 😊",
        "mensagem_fora_horario": "Estamos fechados agora. Horário: {abertura}-{fechamento}",
        "capacidade_maxima":     "10",
        "dias_operacao":         "Seg-Dom",
        "politica_cancelamento": "Cancelar até 2h antes sem custo."
    }

    for r in records:
        f = r["fields"]
        chave = f.get("Chave", "").strip()
        valor = f.get("Valor", "").strip()
        if chave and valor:
            config[chave] = valor

    _config_cache[cache_key] = (config, time.time())
    return config

def set_config_agente(
    tenant_id: str,   # C4
    chave:     str,
    valor:     str
) -> dict:
    """
    Actualiza o crea una clave de configuración.
    Invalida el cache del tenant.
    C4: Busca por chave dentro del tenant.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    client   = AirtableClient(tenant_id=tenant_id)
    formula  = f"{{Chave}}='{chave}'"
    existing = client.find_one("Config", formula)

    if existing:
        result = client.update("Config", existing["id"], {"Valor": valor})
    else:
        result = client.create("Config", {
            "tenant_id": tenant_id,    # C4
            "Chave":     chave,
            "Valor":     valor
        })

    # Invalidar cache
    _config_cache.pop(f"{tenant_id}:config", None)

    return {
        "tenant_id": tenant_id,        # C4
        "chave":     chave,
        "valor":     valor,
        "action":    "updated" if existing else "created"
    }
```

---

### A-10: Backup Completo de Base Airtable a JSON (C5)

```python
# airtable_ejemplo_10_backup.py
def backup_airtable_tenant(
    tenant_id:  str,         # C4
    backup_dir: str = "/backups/airtable"
) -> dict:
    """
    Descarga todas las tablas de la Base del tenant a JSON.
    C5: SHA256 por archivo + manifest de backup.
    C4: Solo datos del tenant (cada tenant tiene su Base).
    Ejecutar como cron a las 04:00 AM — cron: '0 4 * * *'
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    import json, hashlib, os
    from pathlib import Path
    from datetime import datetime, timezone

    client    = AirtableClient(tenant_id=tenant_id)
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    path      = Path(backup_dir) / tenant_id
    path.mkdir(parents=True, exist_ok=True)

    TABLAS = [
        "Reservas", "Clientes", "Menu", "Pedidos",
        "Leads", "Config", "Huéspedes", "Habitaciones",
        "Pacientes", "Citas", "Tratamientos"
    ]

    manifest = {
        "timestamp":  datetime.now(timezone.utc).isoformat(),
        "tenant_id":  tenant_id,                # C4
        "base_id":    client.base_id,
        "tablas":     {}
    }

    total_records = 0

    for tabla in TABLAS:
        try:
            records = client.list_records(tabla, max_records=10000)
            if not records:
                continue

            data     = json.dumps(records, ensure_ascii=False, indent=2)
            sha256   = hashlib.sha256(data.encode()).hexdigest()
            filename = f"{tabla.lower()}_{timestamp}.json"
            filepath = path / filename

            filepath.write_text(data, encoding="utf-8")
            (path / f"{filename}.sha256").write_text(
                f"{sha256}  {filename}\n"
            )

            manifest["tablas"][tabla] = {
                "records":  len(records),
                "file":     filename,
                "sha256":   sha256[:16] + "..."
            }
            total_records += len(records)

        except Exception as e:
            # La tabla puede no existir en este vertical
            manifest["tablas"][tabla] = {"error": str(e)}

    # Guardar manifest (C5)
    manifest_path = path / f"manifest_{timestamp}.json"
    manifest_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2)
    )

    # C5: Log estructurado
    print(json.dumps({
        "timestamp":    datetime.now(timezone.utc).isoformat(),
        "tenant_id":    tenant_id,              # C4
        "event":        "airtable_backup_completed",
        "total_records": total_records,
        "tablas_ok":    sum(1 for v in manifest["tablas"].values() if "error" not in v)
    }))

    return {
        "tenant_id":     tenant_id,             # C4
        "total_records": total_records,
        "manifest":      str(manifest_path),
        "timestamp":     timestamp
    }
```

---

---

## 🐞 10 Errores Comunes y Soluciones

| # | Error Exacto | Causa Raíz | Comando de Diagnóstico | Solución Paso a Paso |
|---|---|---|---|---|
| 1 | `requests.exceptions.HTTPError: 403 Client Error: Forbidden` en cualquier request | El Personal Access Token no tiene los scopes necesarios o expiró | `curl -s "https://api.airtable.com/v0/meta/whoami" -H "Authorization: Bearer $AIRTABLE_API_TOKEN" \| python3 -m json.tool` → si retorna `{"error":{"type":"AUTHENTICATION_REQUIRED"}}` el token es inválido | 1. Ir a `airtable.com/create/tokens`<br>2. Verificar que el token tiene scopes: `data.records:read`, `data.records:write`, `schema.bases:read`<br>3. Verificar que la Base está en el "access" del token (Airtable PAT tiene scope por Base)<br>4. Regenerar token si expiró y actualizar `.env`<br>5. Nunca compartir el token entre entornos dev/prod — crear tokens separados |
| 2 | `HTTPError: 422 Unprocessable Entity: {"error":{"type":"INVALID_VALUE_FOR_FIELD"}}` al crear record | El valor del campo no coincide con el tipo configurado en Airtable. Ej: enviar "20:30" a un campo tipo `Number`, o un string a un campo `Single select` que no tiene esa opción | `curl -s "https://api.airtable.com/v0/meta/bases/{BASE_ID}/tables" -H "Authorization: Bearer $TOKEN" \| python3 -m json.tool \| grep -A5 '"name"'` → ver tipos de campo | 1. Verificar en Airtable UI el tipo exacto de cada campo<br>2. Para `Single select`: el valor DEBE existir en las opciones configuradas — agregar la opción nueva en Airtable antes de enviarla desde código<br>3. Para campos `Date`: formato obligatorio `"YYYY-MM-DD"` (no `"15/04/2026"`)<br>4. Para campos `Number`: enviar `int` o `float`, nunca string `"4"`<br>5. Para `Checkbox`: enviar `True`/`False` Python, nunca `"TRUE"` string |
| 3 | `HTTPError: 429 Too Many Requests` en picos de carga | Superando el límite de 5 requests/segundo de Airtable | `grep "429" n8n.log \| tail -20` — ver frecuencia y horario de los errores | 1. El `AirtableClient` ya tiene retry con backoff — verificar que se está usando<br>2. Reducir `AIRTABLE_MAX_REQUESTS_PER_SEC` a 3 en `.env`<br>3. Implementar cache en memoria o Redis para lecturas frecuentes (menú, config) con TTL 5-10 minutos<br>4. En n8n: agregar nodo `Wait` de 300ms antes de cada nodo Airtable en loops<br>5. Si es persistente: considerar Plan Business (10 req/s) o migrar datos de solo lectura a MySQL |
| 4 | El filtro `filterByFormula` retorna 0 registros aunque existen datos en Airtable | La fórmula Airtable tiene error de sintaxis silencioso o el nombre del campo tiene un espacio/acento no escapado | Probar la fórmula directamente en Airtable UI: abrir tabla → "Filter" → escribir la fórmula → ver si filtra | 1. Nombres de campo con espacios DEBEN ir entre llaves: `{Nome do Cliente}` no `Nome do Cliente`<br>2. Strings en la fórmula con comillas simples: `{Status}='Confirmada'` (no comillas dobles)<br>3. Fechas: `IS_AFTER({Data Reserva}, '2026-04-01')` — formato americano con apóstrofos<br>4. Para debug: imprimir la fórmula antes de enviar y validarla en la UI de Airtable<br>5. `AND()` y `OR()` son funciones: `AND({A}='x', {B}='y')` — no operadores `&&` |
| 5 | Los Linked Records retornan arrays de IDs (`["recABC123"]`) pero se necesitan los datos del record relacionado | Airtable no hace JOIN automático — los linked fields solo retornan el ID, no los campos del record relacionado | `print(record["fields"]["Cliente"])` → muestra `["recXXX"]` en vez del nombre del cliente | 1. Para obtener datos del record relacionado: hacer un segundo request `client.get("Clientes", record_id)`<br>2. Para N records relacionados: hacer N requests (con throttle C2) o usar `list_records` con fórmula por ID: `RECORD_ID()='recXXX'`<br>3. Alternativa: usar campo `Lookup` en Airtable que desnormaliza el dato — configurable en UI sin código<br>4. Para RAG/reportes donde se necesitan los datos: pre-cargar la tabla completa en memoria y hacer el "join" en Python<br>5. Evitar linked records para datos simples — duplicar el campo (ej: guardar nombre Y id del cliente) |
| 6 | `KeyError: 'AIRTABLE_BASE_RESTAURANTE_001'` aunque el tenant existe | El tenant_id tiene guión `-` pero la env var tiene guión bajo `_`, o el `.upper()` no coincide | `python3 -c "import os; print([k for k in os.environ if 'AIRTABLE_BASE' in k])"` | 1. La env var usa el `tenant_id.upper()` con guión bajo: `restaurante-001` → `AIRTABLE_BASE_RESTAURANTE-001` (con guión) — inconsistente<br>2. Estandarizar tenant_ids sin guiones: `restaurante_001` → `AIRTABLE_BASE_RESTAURANTE_001` siempre<br>3. En el `AirtableClient.__init__`: `env_key = f"AIRTABLE_BASE_{tenant_id.upper().replace('-', '_')}"` para normalizar<br>4. Documentar la convención en el onboarding: tenant_ids siempre con `_` (guión bajo), nunca `-` (guión) |
| 7 | Después de `client.update()` los datos en Airtable no cambiaron | Se está usando `PUT` (reemplaza todo el record) cuando se debería usar `PATCH` (actualiza solo los campos enviados), o se envió `fields={}` vacío | `print(resp.status_code, resp.json())` después del update — si retorna 200 pero sin cambios, verificar el payload enviado | 1. Verificar que el método es `PATCH` (update parcial) no `PUT` (reemplazo total)<br>2. El `AirtableClient.update()` ya usa `PATCH` — si se hace request directo, verificar el método HTTP<br>3. Si los fields están vacíos `{}`: Airtable retorna 200 sin cambios — agregar validación: `if not fields: raise ValueError("Nothing to update")`<br>4. Verificar nombres de campo: `"Nome"` (Airtable) vs `"nome"` (Python) — case-sensitive |
| 8 | Datos de un tenant aparecen en consultas de otro tenant (violación C4) | Se está usando `requests.get()` directo a la API en vez del `AirtableClient`, y no se está filtrando por `tenant_id` manualmente | `grep -rn "api.airtable.com" *.py \| grep -v "AirtableClient\|airtable_client"` → buscar llamadas directas | 1. CRÍTICO: auditar todo el código que llama a la API de Airtable<br>2. Solo usar `AirtableClient` — nunca llamadas `requests` directas en el código de aplicación<br>3. El `AirtableClient.list_records()` inyecta `tenant_id` automáticamente en `filterByFormula`<br>4. Cada Base es de un tenant (C4 por diseño) — si se comparten Bases, agregar filtro manual `{tenant_id}='{tenant_id}'` en TODA fórmula<br>5. Agregar test de aislamiento antes de cada deploy |
| 9 | `requests.exceptions.JSONDecodeError` al procesar attachments | Los campos `Attachment` de Airtable retornan objetos con URLs temporales (~2 horas de validez). Si se guarda la URL y se usa después de 2h, falla | `print(record["fields"]["Imagem"])` → ver estructura completa del attachment | 1. Los attachments de Airtable tienen URL temporales — NO guardar la URL, guardar el `id` del attachment<br>2. Para mostrar imagen en WhatsApp: obtener la URL fresca en el momento de enviar (siempre leer el record antes de usar la URL)<br>3. Para guardar permanentemente: descargar el archivo y subir a Google Drive o Cloudinary (ver `cloudinary-media-management.md`)<br>4. Estructura del campo: `[{"id": "attXXX", "url": "https://...", "filename": "foto.jpg", "size": 12345}]` — acceder siempre con `attachment[0]["url"]` después de verificar que la lista no está vacía |
| 10 | El backup falla con `RequestException: Connection timeout` en el nodo de `/backups` | La tabla tiene > 5.000 records y la paginación completa tarda más del timeout configurado de 30s | `time python3 -c "from airtable_client import AirtableClient; c=AirtableClient('X'); print(len(c.list_records('Leads', max_records=10000)))"` → medir tiempo real | 1. Si la tabla tiene > 10.000 records: el backup completo puede tardar > 30s — aumentar `timeout` solo para el proceso de backup: `requests.get(..., timeout=120)`<br>2. Dividir backup por fecha: filtrar `IS_AFTER({Created}, '2026-04-01')` para hacer backups incrementales<br>3. Programar backup en horario de baja actividad (04:00 AM, cron: `0 4 * * *`)<br>4. Para tablas que crecen indefinidamente: implementar archivado mensual — mover records a tabla `Leads_2026_Q1` y limpiar la principal<br>5. Si es estructural (> 50K records/mes): migrar a MySQL (ver `mysql-sql-rag-ingestion.md`) |

---

## ✅ Validación SDD y Comandos de Prueba

### Script de Validación Completo

```bash
#!/bin/bash
# validate-airtable-database.sh
# Verifica cumplimiento SDD C1-C5 para integración Airtable
set -euo pipefail

TENANT="${1:-test_tenant_001}"
PASS=0; FAIL=0

check() {
    local desc="$1"; local cmd="$2"; local expected="$3"; local constraint="$4"
    result=$(eval "$cmd" 2>/dev/null || echo "ERROR")
    if echo "$result" | grep -qiP "$expected"; then
        echo "✅ ${constraint}: ${desc}"; ((PASS++))
    else
        echo "❌ ${constraint} FAIL: ${desc} | Obtenido: ${result:0:100}"; ((FAIL++))
    fi
}

echo "═══ VALIDACIÓN AIRTABLE DATABASE PATTERNS ═══ tenant: $TENANT"

# C3: Token configurado como env var
check "AIRTABLE_API_TOKEN configurado" \
    "[ -n \"${AIRTABLE_API_TOKEN:-}\" ] && echo 'ok'" "ok" "C3"

# C3: Token válido (llamada real a la API)
check "Token válido en Airtable API" \
    "curl -s 'https://api.airtable.com/v0/meta/whoami' \
     -H 'Authorization: Bearer ${AIRTABLE_API_TOKEN:-}' \
     | python3 -c 'import json,sys; d=json.load(sys.stdin); print(\"ok\" if \"id\" in d else \"fail\")'" \
    "ok" "C3"

# C4: Base ID configurado para el tenant
check "Base ID configurado para tenant $TENANT" \
    "python3 -c \"
import os
key = 'AIRTABLE_BASE_${TENANT^^}'
print('ok' if os.environ.get(key) else 'missing')
\"" "ok" "C4"

# C4: AirtableClient rechaza tenant_id vacío
check "AirtableClient rechaza tenant_id vacío" \
    "python3 -c \"
from airtable_client import AirtableClient
try:
    AirtableClient(tenant_id='')
    print('FAIL')
except ValueError as e:
    print('ok' if 'C4' in str(e) else 'FAIL')
\"" "ok" "C4"

# C4: list_records inyecta tenant_id en fórmula
check "list_records incluye tenant_id en filterByFormula" \
    "python3 -c \"
import os; os.environ['AIRTABLE_BASE_TEST']='appTEST'
from airtable_client import AirtableClient
# No podemos testear sin token real, verificar en código
import inspect, airtable_client
src = inspect.getsource(airtable_client.AirtableClient.list_records)
print('ok' if 'tenant_filter' in src and 'tenant_id' in src else 'FAIL')
\"" "ok" "C4"

# C2: Rate limiting configurado
check "Rate limit <= 5 req/s configurado" \
    "python3 -c \"
import os
v = float(os.environ.get('AIRTABLE_MAX_REQUESTS_PER_SEC', 4))
print('ok' if v <= 5 else 'fail')
\"" "ok" "C2"

# C5: Directorio de backup existe
check "Directorio /backups/airtable existe" \
    "[ -d /backups/airtable ] && echo 'ok' || echo 'missing'" "ok" "C5"

# C4: No hay requests directos sin filtro tenant_id
echo ""
echo "─── Verificación C4 en código fuente ───"
DIRECT_CALLS=$(grep -rn "api.airtable.com" . \
    --include="*.py" \
    | grep -v "airtable_client.py\|__pycache__\|test_" \
    | grep -v "AirtableClient" 2>/dev/null | wc -l)

if [ "$DIRECT_CALLS" -gt 0 ]; then
    echo "⚠️ $DIRECT_CALLS llamadas directas a api.airtable.com detectadas (posible C4 violation)"
    grep -rn "api.airtable.com" . --include="*.py" \
        | grep -v "airtable_client.py\|__pycache__" | head -5
    ((FAIL++))
else
    echo "✅ C4: Solo se usa AirtableClient para llamadas a la API"
    ((PASS++))
fi

echo ""
echo "═══════════════════════════════════════════"
echo "RESULTADO: ✅ $PASS pasaron | ❌ $FAIL fallaron"
[ $FAIL -eq 0 ] && \
    echo "🎉 Airtable Database Patterns cumple todos los constraints SDD" && \
    exit 0 || exit 1
```

### Test de Aislamiento Multi-Tenant

```python
# test_airtable_isolation.py
"""
Verifica C4: un tenant no puede ver datos de otro.
Requiere dos Bases configuradas: TEST_TENANT_A y TEST_TENANT_B.
"""
import os

def test_isolation():
    for var in ["AIRTABLE_BASE_TEST_TENANT_A", "AIRTABLE_BASE_TEST_TENANT_B"]:
        if not os.environ.get(var):
            print(f"⚠️ Skip: {var} no configurado")
            return

    from airtable_client import AirtableClient

    client_a = AirtableClient(tenant_id="test_tenant_a")
    client_b = AirtableClient(tenant_id="test_tenant_b")

    # Insertar en tenant_a
    record_a = client_a.create("Config", {
        "tenant_id": "test_tenant_a",
        "Chave":     "test_isolation_key",
        "Valor":     "secreto_del_tenant_a"
    })
    record_id_a = record_a["id"]

    # Buscar desde tenant_b — NO debe encontrar el record de tenant_a
    # (porque list_records inyecta tenant_id del cliente B)
    results_b = client_b.list_records("Config",
        filter_formula=f"{{Chave}}='test_isolation_key'"
    )
    ids_b = [r["id"] for r in results_b]

    assert record_id_a not in ids_b, (
        f"❌ AISLAMIENTO ROTO (C4): tenant_b encontró record de tenant_a: "
        f"{record_id_a}"
    )
    print("✅ Aislamiento tenant_a/tenant_b correcto en Airtable (C4)")

    # Intentar get() directo desde tenant_b — debe lanzar PermissionError
    try:
        client_b.get("Config", record_id_a)
        assert False, "❌ AISLAMIENTO ROTO: get() no verificó tenant_id"
    except PermissionError:
        print("✅ AirtableClient.get() rechaza acceso cross-tenant (C4)")

    # Limpiar
    client_a.delete("Config", record_id_a)
    print("✅ Cleanup completado")
    print("\n🎉 Todos los tests de aislamiento Airtable pasaron")

if __name__ == "__main__":
    test_isolation()
```

### Checklist para ZIP Generator

```markdown
## Checklist Airtable para Auto-Deploy (ZIP Generator)

Cuando el sistema genera un ZIP con Airtable como BD:

### Variables de entorno a incluir en .env.example
- [ ] AIRTABLE_API_TOKEN=pat... (instrucción: crear en airtable.com/create/tokens)
- [ ] AIRTABLE_BASE_{TENANT_ID}=app... (instrucción: obtener de la URL de la Base)
- [ ] AIRTABLE_MAX_REQUESTS_PER_SEC=4
- [ ] AIRTABLE_RETRY_DELAY_MS=500

### Archivos a incluir en el ZIP
- [ ] airtable_client.py (este skill)
- [ ] scripts/setup_airtable_schema.py (crear tablas y campos automáticamente)
- [ ] scripts/validate-airtable-database.sh (este script de validación)
- [ ] README_AIRTABLE.md con instrucciones de:
  - Crear cuenta Airtable (link)
  - Crear token con scopes correctos
  - Crear Base y obtener el ID
  - Compartir Base con el service account (si aplica)

### Schema a crear automáticamente (via API de Metadata)
- [ ] Tabla Reservas con campos tipados correctamente
- [ ] Tabla Clientes con campo Telefone como Phone
- [ ] Tabla Menu con Preço como Currency y Disponível como Checkbox
- [ ] Tabla Config con Chave y Valor como Text
- [ ] Campo tenant_id como primer campo en TODAS las tablas (C4)

### Validaciones post-setup
- [ ] Token válido: curl whoami retorna id
- [ ] Base accesible: list tables retorna > 0 tablas
- [ ] tenant_id en primera columna de cada tabla
- [ ] Rate limiting: AIRTABLE_MAX_REQUESTS_PER_SEC <= 5
```

---

## 🔗 Referencias Cruzadas

- [[01-RULES/06-MULTITENANCY-RULES.md]] — MT-001 (tenant_id), MT-003 (filtros), MT-008 (límites por tenant)
- [[01-RULES/02-RESOURCE-GUARDRAILS.md]] — RES-002 (C2: throttle 5 req/s), RES-004 (polling mínimo)
- [[01-RULES/04-API-RELIABILITY-RULES.md]] — Retry backoff exponencial, timeout 30s
- [[00-CONTEXT/facundo-infrastructure.md]] — Airtable es BD cloud sin consumo en VPS
- [[02-SKILLS/BASE DE DATOS-RAG/google-sheets-as-database.md]] — Alternativa más simple, sin tipos de campo
- [[02-SKILLS/BASE DE DATOS-RAG/mysql-sql-rag-ingestion.md]] — Migrar a MySQL cuando > 50K records/mes
- [[02-SKILLS/BASE DE DATOS-RAG/rag-system-updates-all-engines.md]] — Sync Airtable → Qdrant para RAG
- [[02-SKILLS/BASE DE DATOS-RAG/supabase-rag-integration.md]] — Alternativa cloud con más capacidad y RLS
- [[02-SKILLS/RESTAURANTES/restaurant-google-maps-leadgen.md]] — Usa tabla Leads de este skill
- [[02-SKILLS/RESTAURANTES/restaurant-booking-ai.md]] — Usa tabla Reservas de este skill
- [[02-SKILLS/INFRAESTRUCTURA/redis-session-management.md]] — Cache para reducir calls a Airtable API

**Skills pendientes que usan este archivo:**
- `02-SKILLS/BASE DE DATOS-RAG/db-selection-decision-tree.md` — Árbol que referencia cuándo elegir Airtable
- `02-SKILLS/BASE DE DATOS-RAG/vertical-db-schemas.md` — Schemas completos por vertical
- `02-SKILLS/BASE DE DATOS-RAG/zip-package-db-templates.md` — ZIP generator incluye `airtable_client.py`
- `02-SKILLS/RESTAURANTES/apify-web-scraping.md` — Apify inserta leads vía `registrar_lead_google_maps()`
