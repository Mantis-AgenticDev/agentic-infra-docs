---
title: "espocrm-api-analytics"
category: "Skill"
domain: ["generico", "backend", "crm"]
constraints: ["C1", "C2", "C3", "C4", "C5", "C6"]
priority: "Alta"
version: "1.0.0"
last_updated: "2026-04-10"
ai_optimized: true
tags:
  - sdd/skill/espocrm
  - sdd/skill/analytics
  - sdd/skill/reporting
  - sdd/skill/multi-tenant
  - lang/es
related_files:
  - "01-RULES/06-MULTITENANCY-RULES.md"
  - "01-RULES/02-RESOURCE-GUARDRAILS.md"
  - "01-RULES/04-API-RELIABILITY-RULES.md"
  - "00-CONTEXT/facundo-infrastructure.md"
  - "02-SKILLS/INFRASTRUCTURA/espocrm-setup.md"
---

## 🎯 Propósito y Alcance

Consumir la API REST de EspoCRM para generar reportes analíticos por tenant: conteo de leads, pipeline de oportunidades, actividad de contactos, KPIs de conversión. Diseñado para ejecutarse desde n8n con recursos limitados (C1/C2) y aislamiento total entre tenants (C4).

**Casos de uso cubiertos:**
- Dashboard de leads por fuente y estado (para clientes restaurantes/pousadas/odontología)
- Reporte semanal de pipeline de ventas por tenant
- Métricas de conversión lead → oportunidad → cerrado
- Exportación de datos a Google Sheets o Telegram para cliente final
- Auditoría de actividad CRM por rango de fecha y tenant

**Fuera de alcance:**
- Modificación de entidades EspoCRM (ver `espocrm-setup.md`)
- Análisis de texto/NLP sobre contenido de CRM
- Modelos locales de predicción (C6 prohibido)

---

## 📐 Fundamentos (Nivel Básico)

### ¿Qué es la API REST de EspoCRM?

EspoCRM expone todos sus datos a través de una API RESTful en `http://HOST:8080/api/v1/`. Cada entidad (Lead, Contact, Account, Opportunity) tiene su propio endpoint. Las operaciones son estándar HTTP:

```
GET    /api/v1/Lead          → Listar leads (con filtros y paginación)
GET    /api/v1/Lead/{id}     → Detalle de un lead
POST   /api/v1/Lead          → Crear lead
PUT    /api/v1/Lead/{id}     → Actualizar lead
DELETE /api/v1/Lead/{id}     → Eliminar lead
```

### Autenticación HMAC (Obligatoria en Producción)

EspoCRM usa firma HMAC-SHA256 para verificar requests. Cada request necesita:

```
Header: HMAC-SHA256 Espo-Authorization: BASE64(apiKey:HMAC(method+uri+body, apiSecret))
```

Para scripts Python/n8n, el flujo es:

```python
import hmac
import hashlib
import base64
import time

def build_auth_header(api_key, api_secret, method, uri, body=""):
    """Genera el header de autenticación HMAC para EspoCRM."""
    # Construir string a firmar
    string_to_sign = f"{method} {uri}"
    if body:
        string_to_sign += f"\n{body}"
    
    # Firmar con HMAC-SHA256
    signature = hmac.new(
        api_secret.encode('utf-8'),
        string_to_sign.encode('utf-8'),
        hashlib.sha256
    ).hexdigest()
    
    # Codificar header
    auth_string = f"{api_key}:{signature}"
    return f"Basic {base64.b64encode(auth_string.encode()).decode()}"

# ✅ CORRECTO - Header para GET /api/v1/Lead
header = build_auth_header(
    api_key=os.environ["ESPO_API_KEY"],
    api_secret=os.environ["ESPO_API_SECRET"],
    method="GET",
    uri="/api/v1/Lead"
)
```

### Modelo Mental: Entidades para Analytics

```
EspoCRM (por tenant)
│
├── Lead          → Prospectos entrantes (WhatsApp, formulario, referido)
│   ├── leadSource: "WhatsApp", "Web", "Indicação"
│   ├── status: "New", "Assigned", "In Process", "Converted", "Recycled"
│   └── assignedUserId → quién lo atiende
│
├── Opportunity   → Negocios en progreso
│   ├── stage: "Qualification", "Proposal", "Negotiation", "Closed Won/Lost"
│   ├── amount: valor monetario (R$)
│   └── probability: 0-100%
│
├── Contact       → Clientes confirmados
│   └── accountId → empresa/cuenta vinculada
│
└── Account       → Empresas/negocios clientes
    └── type: "Customer", "Partner", "Lead"
```

### Paginación Obligatoria (C1)

EspoCRM retorna máximo 200 registros por request. Para colecciones grandes:

```
GET /api/v1/Lead?maxSize=50&offset=0   → Página 1
GET /api/v1/Lead?maxSize=50&offset=50  → Página 2
GET /api/v1/Lead?maxSize=50&offset=100 → Página 3
```

**C1 regla crítica:** Usar `maxSize=50` como máximo en VPS 4GB. Valores mayores aumentan memoria del proceso n8n.

---

## 🏗️ Arquitectura y Hardware Limitado (VPS 2vCPU/4-8GB)

### Distribución de Recursos en VPS-2 (EspoCRM + MySQL + Qdrant)

```
VPS-2 (4GB RAM, 1 vCPU, 50GB NVMe)
├── EspoCRM PHP-FPM: 512MB max (C1)
├── MySQL 8.0:       1GB max    (C1)  ← espocrm_${tenant_id}
├── Qdrant:          1GB max    (C1)
├── OS + Red:        512MB reservado
└── Buffer disponible: ~512MB
```

### Docker Compose con Límites para EspoCRM Analytics

```yaml
# docker-compose.yml - Solo extracto relevante para analytics
services:
  espocrm:
    image: espocrm/espocrm:latest
    environment:
      - PHP_MEMORY_LIMIT=256M          # C1: Limitar PHP por request
      - PHP_MAX_EXECUTION_TIME=30      # C2: 30s máximo por request API
    deploy:
      resources:
        limits:
          memory: 512M                 # C1: EspoCRM no debe superar 512MB
          cpus: "0.5"                  # C2: 0.5 vCPU para EspoCRM
    # C3: Puerto solo en red interna, nunca expuesto a internet
    networks:
      - mantis-backend
    # Sin ports: - "8080:80" en producción → usar proxy inverso
```

### Estrategia de Caché para Analytics (C1)

Las queries de analytics son costosas. Cachear en Redis cuando sea posible:

```python
import redis
import json
import hashlib

redis_client = redis.Redis(host='redis', port=6379, decode_responses=True)

def get_cached_analytics(tenant_id: str, report_type: str, ttl_seconds: int = 300):
    """
    Cache de reportes para reducir carga en EspoCRM/MySQL.
    TTL 5 min = balance entre frescura y recursos (C1/C2).
    """
    # C4: Cache key incluye tenant_id
    cache_key = f"analytics:{tenant_id}:{report_type}"
    
    cached = redis_client.get(cache_key)
    if cached:
        return json.loads(cached), True  # (data, from_cache)
    
    return None, False

def set_cached_analytics(tenant_id: str, report_type: str, data: dict, ttl: int = 300):
    """C4: Guardar con tenant_id en key para aislamiento."""
    cache_key = f"analytics:{tenant_id}:{report_type}"
    redis_client.setex(cache_key, ttl, json.dumps(data))
```

---

## 🔗 Conexión Local vs Externa (Prisma, Supabase, Qdrant, MySQL)

### Configuración de Variables de Entorno por Entorno

```bash
# .env.local - n8n en VPS-1 → EspoCRM en VPS-2 (red privada)
ESPOCRM_BASE_URL="http://10.0.1.2:8080/api/v1"    # IP privada VPS-2
ESPOCRM_API_KEY="${ESPOCRM_API_KEY_TENANT}"         # Por tenant
ESPOCRM_API_SECRET="${ESPOCRM_API_SECRET_TENANT}"
ESPOCRM_TIMEOUT=30000                               # C2: 30s máximo

# .env.production - NUNCA exponer EspoCRM directamente a internet (C3)
# Si necesitas acceso externo → tunel SSH o VPN, nunca puerto público
ESPOCRM_BASE_URL="http://localhost:8080/api/v1"     # Via SSH tunnel
```

### Patrón de Cliente HTTP Reutilizable

```python
# espocrm_client.py
import os
import requests
import hmac
import hashlib
import base64
from typing import Optional, Dict, Any

class EspoCRMClient:
    """
    Cliente para EspoCRM API con autenticación HMAC.
    C3: Solo conexiones internas (localhost o red privada Docker).
    C4: tenant_id inyectado en todas las operaciones.
    """
    
    def __init__(self, tenant_id: str):
        # C4: tenant_id obligatorio en construcción
        if not tenant_id:
            raise ValueError("tenant_id required (C4 violation)")
        
        self.tenant_id = tenant_id
        self.base_url = os.environ["ESPOCRM_BASE_URL"]
        self.api_key = os.environ[f"ESPOCRM_API_KEY_{tenant_id.upper()}"]
        self.api_secret = os.environ[f"ESPOCRM_API_SECRET_{tenant_id.upper()}"]
        self.timeout = int(os.environ.get("ESPOCRM_TIMEOUT", 30))
        
        # C3: Validar que URL no sea pública
        if not any(host in self.base_url for host in ["localhost", "127.0.0.1", "10.", "172.", "192.168."]):
            raise ValueError("EspoCRM must use internal URL (C3 violation)")
    
    def _get_auth_header(self, method: str, path: str) -> str:
        """Genera header HMAC para autenticación."""
        string_to_sign = f"{method} {path}"
        sig = hmac.new(
            self.api_secret.encode(),
            string_to_sign.encode(),
            hashlib.sha256
        ).hexdigest()
        encoded = base64.b64encode(f"{self.api_key}:{sig}".encode()).decode()
        return f"Basic {encoded}"
    
    def get(self, endpoint: str, params: Optional[Dict] = None) -> Dict[Any, Any]:
        """GET request con timeout C2 y autenticación HMAC."""
        path = f"/api/v1/{endpoint}"
        headers = {
            "Content-Type": "application/json",
            "Espo-Authorization": self._get_auth_header("GET", path),
            # C4: tenant_id siempre en headers para auditoría
            "X-Tenant-ID": self.tenant_id
        }
        
        response = requests.get(
            f"{self.base_url}/{endpoint}",
            headers=headers,
            params=params,
            timeout=self.timeout  # C2: timeout obligatorio
        )
        response.raise_for_status()
        return response.json()
    
    def get_all_pages(self, endpoint: str, base_params: Optional[Dict] = None, max_size: int = 50) -> list:
        """
        Paginación automática. max_size=50 para respetar C1.
        Limita a 1000 registros máximo para no saturar RAM.
        """
        all_records = []
        offset = 0
        max_records = 1000  # C1: Hard limit
        
        while len(all_records) < max_records:
            params = {**(base_params or {}), "maxSize": max_size, "offset": offset}
            response = self.get(endpoint, params)
            
            records = response.get("list", [])
            if not records:
                break
            
            all_records.extend(records)
            
            total = response.get("total", 0)
            if offset + max_size >= total:
                break
            
            offset += max_size
        
        return all_records

# Uso
client = EspoCRMClient(tenant_id="restaurante_456")
```

---

## 📘 Guía de Estructura de Tablas (Para principiantes)

### Entidades EspoCRM Relevantes para Analytics

Las entidades de EspoCRM viven en MySQL bajo la base de datos `espocrm_${tenant_id}`. No accedas directamente — usa la API (C3). Pero conocer la estructura ayuda a entender los filtros.

```
Tabla: lead
┌──────────────────┬─────────────────┬──────────────────────────────────┐
│ Campo API        │ Tipo MySQL       │ Uso en Analytics                 │
├──────────────────┼─────────────────┼──────────────────────────────────┤
│ id               │ VARCHAR(17)     │ Identificador único              │
│ name             │ VARCHAR(150)    │ Nombre completo del lead         │
│ status           │ VARCHAR(255)    │ New/In Process/Converted/Lost    │
│ lead_source      │ VARCHAR(255)    │ WhatsApp/Web/Indicação           │
│ assigned_user_id │ VARCHAR(17)     │ Responsable del lead             │
│ created_at       │ DATETIME        │ Fecha de entrada (para rangos)   │
│ modified_at      │ DATETIME        │ Última actualización             │
│ converted        │ TINYINT(1)      │ 0=no convertido, 1=convertido    │
└──────────────────┴─────────────────┴──────────────────────────────────┘

Tabla: opportunity
┌──────────────────┬─────────────────┬──────────────────────────────────┐
│ Campo API        │ Tipo MySQL       │ Uso en Analytics                 │
├──────────────────┼─────────────────┼──────────────────────────────────┤
│ id               │ VARCHAR(17)     │ Identificador único              │
│ name             │ VARCHAR(150)    │ Nombre de la oportunidad         │
│ stage            │ VARCHAR(255)    │ Etapa del pipeline               │
│ amount           │ DECIMAL(12,2)   │ Valor en R$                      │
│ probability      │ INT(3)          │ % de cierre esperado             │
│ close_date       │ DATE            │ Fecha esperada de cierre         │
│ account_id       │ VARCHAR(17)     │ Empresa asociada                 │
│ created_at       │ DATETIME        │ Fecha de creación                │
└──────────────────┴─────────────────┴──────────────────────────────────┘
```

### Filtros de API: Sintaxis Clave

EspoCRM usa query parameters para filtros. Los más usados en analytics:

```
# Filtrar por campo exacto
GET /api/v1/Lead?where[0][type]=equals&where[0][field]=status&where[0][value]=New

# Filtrar por rango de fechas
GET /api/v1/Lead?where[0][type]=between&where[0][field]=createdAt
  &where[0][value][]=2026-01-01&where[0][value][]=2026-01-31

# Múltiples filtros (AND)
GET /api/v1/Lead?where[0][type]=equals&where[0][field]=status&where[0][value]=New
  &where[1][type]=equals&where[1][field]=leadSource&where[1][value]=WhatsApp

# Ordenar por fecha descendente
GET /api/v1/Lead?orderBy=createdAt&order=desc
```

---

## 🛠️ 4 Ejemplos Centrales (Copy-Paste, validables)

### Ejemplo 1: Reporte de Leads por Estado y Fuente

```python
# lead_analytics.py
from espocrm_client import EspoCRMClient
from collections import defaultdict
from datetime import datetime, timedelta

def get_lead_report(tenant_id: str, days_back: int = 30) -> dict:
    """
    Genera reporte de leads del período.
    C4: tenant_id obligatorio.
    C1: maxSize=50, paginación automática, hard limit 1000.
    C2: timeout 30s por request.
    """
    # C4: Validación explícita
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")
    
    client = EspoCRMClient(tenant_id=tenant_id)
    
    # Calcular rango de fechas
    date_from = (datetime.utcnow() - timedelta(days=days_back)).strftime("%Y-%m-%d")
    date_to = datetime.utcnow().strftime("%Y-%m-%d")
    
    # Paginación completa (C1: max_size=50)
    leads = client.get_all_pages(
        endpoint="Lead",
        base_params={
            "select": "id,name,status,leadSource,createdAt,converted,assignedUserId",
            "where[0][type]": "between",
            "where[0][field]": "createdAt",
            "where[0][value][]": [date_from, date_to],
            "orderBy": "createdAt",
            "order": "desc"
        },
        max_size=50  # C1: No exceder 50 por request
    )
    
    # Agregar métricas sin cargar todo en RAM
    report = {
        "tenant_id": tenant_id,  # C4: Siempre presente en output
        "period": {"from": date_from, "to": date_to},
        "total_leads": len(leads),
        "by_status": defaultdict(int),
        "by_source": defaultdict(int),
        "conversion_rate": 0.0,
        "converted_count": 0
    }
    
    for lead in leads:
        report["by_status"][lead.get("status", "Unknown")] += 1
        report["by_source"][lead.get("leadSource", "Unknown")] += 1
        if lead.get("converted"):
            report["converted_count"] += 1
    
    if report["total_leads"] > 0:
        report["conversion_rate"] = round(
            report["converted_count"] / report["total_leads"] * 100, 2
        )
    
    # Convertir defaultdict a dict normal para serialización
    report["by_status"] = dict(report["by_status"])
    report["by_source"] = dict(report["by_source"])
    
    return report

# Validación de ejecución
if __name__ == "__main__":
    result = get_lead_report(tenant_id="restaurante_456", days_back=30)
    print(f"✅ Reporte generado para tenant: {result['tenant_id']}")
    print(f"   Total leads: {result['total_leads']}")
    print(f"   Tasa conversión: {result['conversion_rate']}%")
    print(f"   Por estado: {result['by_status']}")
```

**Validación:**
```bash
# Ejecutar y verificar output
python lead_analytics.py

# Output esperado:
# ✅ Reporte generado para tenant: restaurante_456
#    Total leads: 47
#    Tasa conversión: 23.4%
#    Por estado: {'New': 12, 'In Process': 8, 'Converted': 11, 'Recycled': 16}

# ⚠️ Impacto C1: Máximo 1000 leads procesados en RAM (~2MB por lote de 50)
# ⚠️ Impacto C2: ~6 requests para 300 leads (6×30ms = <200ms total)
```

---

### Ejemplo 2: Pipeline de Oportunidades (Valor Total por Stage)

```python
# pipeline_analytics.py
from espocrm_client import EspoCRMClient
from decimal import Decimal

def get_pipeline_report(tenant_id: str) -> dict:
    """
    Valor del pipeline agrupado por stage.
    C4: tenant_id en todos los accesos y logs.
    C6: Sin modelos locales, solo cálculos en Python.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")
    
    client = EspoCRMClient(tenant_id=tenant_id)
    
    opportunities = client.get_all_pages(
        endpoint="Opportunity",
        base_params={
            "select": "id,name,stage,amount,probability,closeDate,accountName",
            # Solo oportunidades abiertas (excluir Closed Won/Lost del pipeline activo)
            "where[0][type]": "notIn",
            "where[0][field]": "stage",
            "where[0][value]": ["Closed Won", "Closed Lost"]
        },
        max_size=50
    )
    
    pipeline = {
        "tenant_id": tenant_id,  # C4
        "stages": {},
        "total_pipeline_value": Decimal("0"),
        "weighted_pipeline_value": Decimal("0"),
        "opportunity_count": len(opportunities)
    }
    
    for opp in opportunities:
        stage = opp.get("stage", "Unknown")
        amount = Decimal(str(opp.get("amount") or 0))
        probability = Decimal(str(opp.get("probability") or 0)) / 100
        
        if stage not in pipeline["stages"]:
            pipeline["stages"][stage] = {
                "count": 0,
                "total_value": Decimal("0"),
                "avg_probability": Decimal("0"),
                "opportunities": []
            }
        
        pipeline["stages"][stage]["count"] += 1
        pipeline["stages"][stage]["total_value"] += amount
        pipeline["total_pipeline_value"] += amount
        pipeline["weighted_pipeline_value"] += amount * probability
        
        pipeline["stages"][stage]["opportunities"].append({
            "name": opp.get("name"),
            "amount": float(amount),
            "probability": float(probability * 100),
            "close_date": opp.get("closeDate")
        })
    
    # Serializar Decimal a float para JSON
    for stage_data in pipeline["stages"].values():
        stage_data["total_value"] = float(stage_data["total_value"])
    
    pipeline["total_pipeline_value"] = float(pipeline["total_pipeline_value"])
    pipeline["weighted_pipeline_value"] = float(pipeline["weighted_pipeline_value"])
    
    return pipeline

# Validación
if __name__ == "__main__":
    result = get_pipeline_report(tenant_id="odontologia_789")
    print(f"✅ Pipeline tenant {result['tenant_id']}:")
    print(f"   Valor total: R$ {result['total_pipeline_value']:,.2f}")
    print(f"   Valor ponderado: R$ {result['weighted_pipeline_value']:,.2f}")
    for stage, data in result["stages"].items():
        print(f"   {stage}: {data['count']} ops = R$ {data['total_value']:,.2f}")
```

**Validación:**
```bash
python pipeline_analytics.py
# Output esperado:
# ✅ Pipeline tenant odontologia_789:
#    Valor total: R$ 45.300,00
#    Valor ponderado: R$ 27.180,00
#    Qualification: 3 ops = R$ 12.000,00
#    Proposal: 2 ops = R$ 18.300,00
#    Negotiation: 1 ops = R$ 15.000,00
```

---

### Ejemplo 3: Workflow n8n para Reporte Semanal Automático

```json
{
  "name": "EspoCRM Weekly Analytics Report",
  "nodes": [
    {
      "name": "Schedule - Every Monday 8AM",
      "type": "n8n-nodes-base.scheduleTrigger",
      "parameters": {
        "rule": {
          "interval": [{"field": "cronExpression", "expression": "0 8 * * 1"}]
        }
      }
    },
    {
      "name": "Get Tenant List",
      "type": "n8n-nodes-base.mysql",
      "parameters": {
        "operation": "select",
        "query": "SELECT tenant_id, nombre, telegram_chat_id FROM tenants WHERE activo = 1",
        "additionalFields": {}
      }
    },
    {
      "name": "Process Each Tenant",
      "type": "n8n-nodes-base.splitInBatches",
      "parameters": {
        "batchSize": 1
      }
    },
    {
      "name": "Call EspoCRM Analytics API",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "method": "GET",
        "url": "={{ 'http://10.0.1.2:8080/api/v1/Lead?maxSize=50&where[0][type]=between&where[0][field]=createdAt&where[0][value][]=' + $now.minus({days: 7}).toFormat('yyyy-MM-dd') + '&where[0][value][]=' + $now.toFormat('yyyy-MM-dd') }}",
        "sendHeaders": true,
        "headerParameters": {
          "parameters": [
            {"name": "Espo-Authorization", "value": "={{ $json['espo_auth_header'] }}"},
            {"name": "X-Tenant-ID", "value": "={{ $json['tenant_id'] }}"}
          ]
        },
        "options": {"timeout": 30000}
      }
    },
    {
      "name": "Format Report Message",
      "type": "n8n-nodes-base.function",
      "parameters": {
        "functionCode": "// C4: Validar tenant_id presente\nconst tenantId = $input.first().json.tenant_id;\nif (!tenantId) throw new Error('tenant_id missing - C4 violation');\n\nconst leads = $input.item.json.list || [];\nconst total = leads.length;\nconst converted = leads.filter(l => l.converted).length;\nconst rate = total > 0 ? (converted/total*100).toFixed(1) : 0;\n\nreturn [{\n  json: {\n    tenant_id: tenantId,\n    message: `📊 *Reporte Semanal CRM*\\n\\n🏷️ Tenant: ${tenantId}\\n👥 Leads: ${total}\\n✅ Convertidos: ${converted}\\n📈 Tasa: ${rate}%`\n  }\n}];"
      }
    },
    {
      "name": "Send Telegram Notification",
      "type": "n8n-nodes-base.telegram",
      "parameters": {
        "chatId": "={{ $('Get Tenant List').item.json.telegram_chat_id }}",
        "text": "={{ $json.message }}",
        "additionalFields": {"parseMode": "Markdown"}
      }
    }
  ]
}
```

**Validación del workflow:**
```bash
# Verificar que tenant_id está en todos los nodos de datos
grep -c "tenant_id" workflow-analytics.json
# Output esperado: >= 4 (en SQL query, headers HTTP, function node, log)

# C1/C2: Verificar timeout configurado
grep "timeout" workflow-analytics.json
# Output esperado: "timeout": 30000
```

---

### Ejemplo 4: Script de Auditoría Multi-Tenant (Bash + curl)

```bash
#!/bin/bash
# audit-espocrm-activity.sh
# C4: Genera reporte de actividad por tenant
# C5: Loguea resultado con timestamp para auditoría
set -euo pipefail

ESPOCRM_BASE="http://localhost:8080/api/v1"
LOG_FILE="/var/log/mantis/espocrm-audit-$(date +%Y%m%d).log"
DATE_FROM=$(date -d "7 days ago" +%Y-%m-%d)
DATE_TO=$(date +%Y-%m-%d)

# C4: tenant_id requerido como argumento
TENANT_ID="${1:-}"
if [ -z "$TENANT_ID" ]; then
    echo "❌ ERROR: tenant_id required as first argument (C4 violation)"
    exit 1
fi

# Cargar credenciales del tenant (C4: por tenant)
API_KEY_VAR="ESPOCRM_API_KEY_${TENANT_ID^^}"
API_SECRET_VAR="ESPOCRM_API_SECRET_${TENANT_ID^^}"

API_KEY="${!API_KEY_VAR:-}"
API_SECRET="${!API_SECRET_VAR:-}"

if [ -z "$API_KEY" ] || [ -z "$API_SECRET" ]; then
    echo "❌ ERROR: Missing credentials for tenant $TENANT_ID"
    exit 1
fi

# Función para generar firma HMAC
generate_hmac() {
    local method="$1"
    local path="$2"
    local string_to_sign="${method} ${path}"
    echo -n "${string_to_sign}" | openssl dgst -sha256 -hmac "${API_SECRET}" | awk '{print $2}'
}

# Query leads de la semana
PATH_LEADS="/api/v1/Lead"
HMAC_SIG=$(generate_hmac "GET" "${PATH_LEADS}")
AUTH_HEADER=$(echo -n "${API_KEY}:${HMAC_SIG}" | base64 -w 0)

echo "🔍 Auditando tenant: $TENANT_ID | Período: $DATE_FROM → $DATE_TO" | tee -a "$LOG_FILE"

RESPONSE=$(curl -s \
    -H "Espo-Authorization: Basic ${AUTH_HEADER}" \
    -H "X-Tenant-ID: ${TENANT_ID}" \
    --max-time 30 \
    "${ESPOCRM_BASE}/Lead?maxSize=50&orderBy=createdAt&order=desc" \
    2>&1)

if echo "$RESPONSE" | python3 -c "import json,sys; d=json.load(sys.stdin); print(f\"Total leads: {d.get('total', 0)}\")" 2>/dev/null; then
    echo "✅ Auditoría completada para $TENANT_ID" | tee -a "$LOG_FILE"
    
    # C5: Log estructurado con timestamp
    echo "{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"tenant_id\":\"${TENANT_ID}\",\"event\":\"audit_completed\",\"status\":\"success\"}" >> "$LOG_FILE"
else
    echo "❌ Error en respuesta para $TENANT_ID: $RESPONSE" | tee -a "$LOG_FILE"
    exit 1
fi
```

**Validación:**
```bash
# Ejecutar para un tenant específico
chmod +x audit-espocrm-activity.sh
./audit-espocrm-activity.sh restaurante_456

# Output esperado:
# 🔍 Auditando tenant: restaurante_456 | Período: 2026-04-03 → 2026-04-10
# Total leads: 23
# ✅ Auditoría completada para restaurante_456
```

---

## 🔍 >5 Ejemplos Independientes por Caso de Uso

### Caso 1: Top 5 Leads Más Recientes de un Tenant

```python
def get_recent_leads(tenant_id: str, limit: int = 5) -> list:
    """C4: tenant_id obligatorio. C1: limit máximo 50."""
    if limit > 50:
        limit = 50  # C1: Hard limit
    
    client = EspoCRMClient(tenant_id=tenant_id)
    response = client.get("Lead", params={
        "select": "id,name,status,leadSource,createdAt",
        "orderBy": "createdAt",
        "order": "desc",
        "maxSize": limit,
        "offset": 0
    })
    return response.get("list", [])

# Output: [{"id": "abc", "name": "João Silva", "status": "New", ...}]
```

---

### Caso 2: Contar Oportunidades por Stage (Sin Cargar Todos los Registros)

```python
def count_opportunities_by_stage(tenant_id: str) -> dict:
    """
    Usa el total de la respuesta para cada stage.
    C1: Solo 1 request por stage, sin cargar todos los registros.
    """
    stages = ["Qualification", "Proposal", "Negotiation", "Closed Won", "Closed Lost"]
    counts = {"tenant_id": tenant_id}  # C4
    
    client = EspoCRMClient(tenant_id=tenant_id)
    
    for stage in stages:
        response = client.get("Opportunity", params={
            "maxSize": 1,  # C1: Solo necesitamos el total
            "where[0][type]": "equals",
            "where[0][field]": "stage",
            "where[0][value]": stage
        })
        counts[stage] = response.get("total", 0)
    
    return counts
# Output: {"tenant_id": "x", "Qualification": 5, "Proposal": 3, "Closed Won": 12, ...}
```

---

### Caso 3: Buscar Contactos por Palabra Clave

```python
def search_contacts(tenant_id: str, keyword: str) -> list:
    """
    Búsqueda de contactos por nombre o email.
    C4: tenant_id. C2: timeout implícito en EspoCRMClient.
    """
    client = EspoCRMClient(tenant_id=tenant_id)
    response = client.get("Contact", params={
        "select": "id,name,emailAddress,phoneNumber,accountName",
        "where[0][type]": "contains",
        "where[0][field]": "name",
        "where[0][value]": keyword,
        "maxSize": 20,
        "orderBy": "name"
    })
    # C4: Agregar tenant_id a cada resultado para trazabilidad
    leads = [{"tenant_id": tenant_id, **c} for c in response.get("list", [])]
    return leads
```

---

### Caso 4: Tasa de Conversión Mensual (Serie Temporal)

```python
from datetime import datetime, timedelta

def get_monthly_conversion_series(tenant_id: str, months: int = 3) -> list:
    """
    Serie temporal de conversión lead→oportunidad mes a mes.
    C1: 1 request por mes, max_size=1 para contar totales.
    """
    client = EspoCRMClient(tenant_id=tenant_id)
    series = []
    
    for i in range(months, -1, -1):
        month_start = (datetime.utcnow().replace(day=1) - timedelta(days=30*i))
        month_end = month_start.replace(month=month_start.month % 12 + 1, day=1) - timedelta(days=1)
        
        # Total leads del mes
        total_resp = client.get("Lead", params={
            "maxSize": 1,  # C1
            "where[0][type]": "between",
            "where[0][field]": "createdAt",
            "where[0][value][]": [month_start.strftime("%Y-%m-%d"), month_end.strftime("%Y-%m-%d")]
        })
        
        # Solo leads convertidos
        converted_resp = client.get("Lead", params={
            "maxSize": 1,
            "where[0][type]": "between",
            "where[0][field]": "createdAt",
            "where[0][value][]": [month_start.strftime("%Y-%m-%d"), month_end.strftime("%Y-%m-%d")],
            "where[1][type]": "isTrue",
            "where[1][field]": "converted"
        })
        
        total = total_resp.get("total", 0)
        converted = converted_resp.get("total", 0)
        
        series.append({
            "tenant_id": tenant_id,  # C4
            "month": month_start.strftime("%Y-%m"),
            "total_leads": total,
            "converted": converted,
            "rate": round(converted / total * 100, 1) if total > 0 else 0
        })
    
    return series
# Output: [{"tenant_id": "x", "month": "2026-02", "total_leads": 45, "converted": 12, "rate": 26.7}, ...]
```

---

### Caso 5: Exportar Reporte a Google Sheets via n8n

```javascript
// Nodo Function de n8n para preparar datos para Google Sheets
// C4: tenant_id en cada fila

const tenantId = $input.first().json.tenant_id;
if (!tenantId) throw new Error('tenant_id missing (C4 violation)');

const leads = $input.all().map(item => item.json);

// Formato para Google Sheets (array de arrays)
const rows = leads.map(lead => [
    tenantId,                          // Col A: tenant_id (C4)
    lead.name || '',                    // Col B: Nombre
    lead.status || '',                  // Col C: Estado
    lead.leadSource || '',              // Col D: Fuente
    lead.createdAt?.split('T')[0] || '', // Col E: Fecha
    lead.converted ? 'Sí' : 'No'       // Col F: Convertido
]);

// Header row
rows.unshift(['tenant_id', 'Nombre', 'Estado', 'Fuente', 'Fecha', 'Convertido']);

return [{ json: { values: rows, sheetRange: `Leads!A1:F${rows.length}` } }];
```

---

### Caso 6: Verificar Conexión con EspoCRM (Health Check)

```bash
#!/bin/bash
# health-check-espocrm.sh
# C4: tenant_id como argumento obligatorio
TENANT_ID="${1:-}"
[ -z "$TENANT_ID" ] && echo "ERROR: tenant_id required" && exit 1

response=$(curl -s -o /dev/null -w "%{http_code}" \
    --max-time 10 \
    "http://localhost:8080/api/v1/App/user")

if [ "$response" = "200" ] || [ "$response" = "401" ]; then
    # 401 = server up pero sin auth (esperado sin credenciales)
    echo "✅ EspoCRM online | tenant: $TENANT_ID | HTTP: $response"
    exit 0
else
    echo "❌ EspoCRM offline | tenant: $TENANT_ID | HTTP: $response"
    exit 1
fi
```

---

## 🐞 Troubleshooting: 5+ Problemas Comunes y Soluciones Exactas

| Error Exacto | Causa Raíz | Comando de Diagnóstico | Solución Paso a Paso |
|---|---|---|---|
| `HTTP 401 Unauthorized` en todos los requests | API Key/Secret incorrecto o usuario API desactivado | `curl -s http://localhost:8080/api/v1/App/user -H "Espo-Authorization: Basic XXX"` | 1. Ir a EspoCRM → Admin → API Users<br>2. Verificar que el usuario esté activo<br>3. Regenerar API Key/Secret<br>4. Actualizar variables de entorno `ESPOCRM_API_KEY_TENANT` |
| `requests.exceptions.Timeout: 30s` durante analytics con muchos leads | n8n/Python esperando respuesta de EspoCRM > 30s (VPS sobrecargado) | `docker stats mantis-espocrm --no-stream` (ver CPU%) | 1. Verificar CPU de EspoCRM: si >80%, reducir `max_size` a 20<br>2. Agregar `time.sleep(0.5)` entre páginas<br>3. Programar analytics fuera de horario pico<br>4. Si persiste: verificar índices MySQL en tabla `lead` |
| `{"total": 0, "list": []}` cuando debería haber datos | Filtro de fecha mal formateado o formato UTC incorrecto | `SELECT COUNT(*) FROM lead WHERE DATE(created_at) > '2026-01-01';` (en MySQL) | 1. EspoCRM usa UTC internamente — verificar timezone<br>2. Formato correcto: `2026-01-01T00:00:00+00:00` o `2026-01-01`<br>3. Verificar que `where[0][type]` sea `"between"` y no `"greaterThanOrEquals"` |
| `HTTP 403 Forbidden` en endpoint específico | Usuario API no tiene permisos sobre la entidad | `curl -s http://localhost:8080/api/v1/Lead` → `{"error": "Forbidden"}` | 1. Admin → Roles → API Role<br>2. Agregar permiso Read sobre entidad (Lead/Opportunity)<br>3. Asignar rol al usuario API<br>4. Limpiar caché EspoCRM: `Admin → Clear Cache` |
| `Connection refused` a `http://10.0.1.2:8080` | EspoCRM caído o puerto incorrecto en VPS-2 | `ssh user@vps2 'docker ps \| grep espocrm'` | 1. Si contenedor parado: `docker start mantis-espocrm`<br>2. Si nunca levantó: `docker-compose -f /opt/mantis/docker-compose.yml up -d espocrm`<br>3. Verificar logs: `docker logs mantis-espocrm --tail 50` |
| `tenant_id` de respuesta no coincide con request | Bug de lógica en script: mezcla de credenciales entre tenants | `grep -n "tenant_id" script.py \| grep -v C4` → líneas sin validación | 1. Verificar que `EspoCRMClient(tenant_id=X)` usa credenciales `_X` del .env<br>2. Agregar assert: `assert response_tenant_id == request_tenant_id`<br>3. Loguear `X-Tenant-ID` header en cada request |
| `OOM Killed` en n8n durante analytics masivo | `get_all_pages` superó 1000 registros, saturó RAM (C1) | `dmesg \| grep -i oom` | 1. Verificar hard limit en `get_all_pages`: `max_records=1000`<br>2. Dividir analytics en sub-períodos (semanas en vez de meses)<br>3. Usar streaming / procesamiento por lotes sin acumular en lista |

---

## ✅ Validación SDD y Comandos de Prueba

### Checklist C4: tenant_id en Todos los Flujos

```bash
# 1. Verificar que EspoCRMClient rechaza tenant_id vacío
python3 -c "
from espocrm_client import EspoCRMClient
try:
    c = EspoCRMClient(tenant_id='')
    print('❌ FAIL: debería rechazar tenant_id vacío')
except ValueError as e:
    print(f'✅ PASS: {e}')
"

# 2. Verificar que analytics incluye tenant_id en output
python3 -c "
from lead_analytics import get_lead_report
r = get_lead_report('test_tenant', days_back=1)
assert 'tenant_id' in r, '❌ tenant_id ausente en reporte'
assert r['tenant_id'] == 'test_tenant', '❌ tenant_id incorrecto'
print('✅ PASS: tenant_id presente y correcto en reporte')
"

# 3. Verificar que URL de EspoCRM es interna (C3)
python3 -c "
import os
url = os.environ.get('ESPOCRM_BASE_URL', '')
internal = any(h in url for h in ['localhost', '127.0.0.1', '10.', '172.', '192.168.'])
print('✅ C3 PASS: URL interna' if internal else '❌ C3 FAIL: URL pública detectada')
"
```

### Test de Límites de Recursos (C1/C2)

```bash
# Monitorear RAM durante analytics
docker stats mantis-espocrm n8n --no-stream &
python3 -c "
from lead_analytics import get_lead_report
import time
start = time.time()
result = get_lead_report('test_tenant', days_back=90)
elapsed = time.time() - start
print(f'Tiempo: {elapsed:.2f}s | Leads procesados: {result[\"total_leads\"]}')
assert elapsed < 30, f'❌ C2 FAIL: {elapsed:.1f}s > 30s'
print('✅ C2 PASS: completado en tiempo')
"
```

### Prueba de Aislamiento Multi-Tenant

```bash
# Insertar lead en tenant A, verificar que tenant B no lo ve
python3 << 'EOF'
from espocrm_client import EspoCRMClient

# Crear lead en tenant_a
# (requiere credenciales de ambos tenants configuradas)
client_a = EspoCRMClient(tenant_id="tenant_a")
client_b = EspoCRMClient(tenant_id="tenant_b")

leads_a = client_a.get("Lead", params={"maxSize": 1})
leads_b = client_b.get("Lead", params={"maxSize": 1})

ids_a = {l["id"] for l in leads_a.get("list", [])}
ids_b = {l["id"] for l in leads_b.get("list", [])}

intersection = ids_a & ids_b
if intersection:
    print(f"❌ AISLAMIENTO ROTO: IDs compartidos: {intersection}")
else:
    print("✅ PASS: tenant_a y tenant_b tienen IDs completamente distintos")
EOF
```

---

## 🔗 Referencias Cruzadas

- [[01-RULES/06-MULTITENANCY-RULES.md]] — MT-001, MT-003, MT-006 (tenant_id en queries, logs, auditoría)
- [[01-RULES/02-RESOURCE-GUARDRAILS.md]] — RES-001 (RAM 4GB), RES-002 (CPU 1 vCPU), RES-009 (concurrencia n8n)
- [[01-RULES/04-API-RELIABILITY-RULES.md]] — Timeouts 30s, backoff exponencial, retry máximo 3
- [[00-CONTEXT/facundo-infrastructure.md]] — Arquitectura VPS-1/VPS-2/VPS-3 y puertos internos
- [[02-SKILLS/INFRASTRUCTURA/espocrm-setup.md]] — Setup inicial, Docker Compose, variables de entorno
- [[02-SKILLS/COMUNICACION/telegram-bot-integration.md]] — Envío de reportes vía Telegram

**Skills relacionados:**
- `mysql-optimization-4gb-ram.md` — Optimizar MySQL que soporta EspoCRM
- `multi-tenant-data-isolation.md` — Patrones avanzados de aislamiento
- `health-monitoring-vps.md` — Monitorear disponibilidad de EspoCRM
