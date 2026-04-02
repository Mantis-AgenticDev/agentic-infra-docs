---
title: "CODE PATTERNS RULES - Agentic Infra Docs"
category: "Código"
priority: "Media"
version: "1.0.0"
last_updated: "2026-03"
language: "es"
repository: "agentic-infra-docs"
owner: "Mantis-AgenticDev"
type: "rules"
ia_parser_version: "2.0"
auto_validate: false
compliance_check: "on-demand"
validation_script: "scripts/lint-code.sh"
auto_fixable: true
severity_scope: "warning"
rules_count: 8
tags:
  - code
  - patterns
  - javascript
  - python
  - sql
  - templates
related_files:
  - "04-API-RELIABILITY-RULES.md"
  - "06-PROGRAMMING/"
---

# CODE PATTERNS RULES

## Metadatos del Documento

- **Categoría:** Código
- **Prioridad de carga:** Media
- **Versión:** 1.0.0
- **Última actualización:** Marzo 2026
- **Archivos relacionados:** 04-API-RELIABILITY-RULES.md

---

## Patrón JS-001: Async/Await con Try/Catch

**Descripción:** Todo código JavaScript debe usar async/await con try/catch.

**Plantilla obligatoria:**

```javascript
async function functionName(params) {
  try {
    const result = await someAsyncOperation(params);
    return { success: true, result };
  } catch (error) {
    return { 
      success: false, 
      error: error.message,
      timestamp: new Date().toISOString()
    };
  }
}
```

**Violación:** Callbacks anidados o promesas sin catch.

---

## Patrón JS-002: Fetch con Timeout

**Descripción:** Todo fetch debe incluir AbortSignal.timeout.

**Plantilla obligatoria:**

```javascript
const response = await fetch(url, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(data),
  signal: AbortSignal.timeout(5000)
});
```
**Violación:** Fetch sin timeout definido.

---

## Patrón JS-003: Retorno de Objetos Pequeños

**Descripción:** Retornar objetos pequeños y serializables.

**Requisitos:**

Evitar buffers grandes en memoria
Evitar objetos circulares
Incluir solo campos necesarios

**Ejemplo correcto:**

```javascript
return { success: true, id: 123, status: 'completed' };
```

**Ejemplo incorrecto:**

```javascript
return { success: true, fullResponse: hugeObject, buffer: largeBuffer };
```

---

## Patrón PY-001: Requests con Timeout

**Descripción:** Todo requests en Python debe incluir timeout.

**Plantilla obligatoria:**

```python
import requests

try:
    response = requests.post(url, json=data, timeout=5)
    response.raise_for_status()
    return {"success": True, "data": response.json()}
except requests.exceptions.RequestException as e:
    return {"success": False, "error": str(e)}
```
    
**Violación:** requests sin timeout.

---

## Patrón PY-002: Manejo de Excepciones Específico

**Descripción:** Capturar excepciones específicas, no Exception genérico.

**Ejemplo correcto:**

```python
except requests.exceptions.Timeout:
    return {"success": False, "error": "Request timeout"}
except requests.exceptions.ConnectionError:
    return {"success": False, "error": "Connection failed"}
```
    
**Ejemplo incorrecto:**

```python
except Exception:
    return {"success": False, "error": "Something went wrong"}
```

---

## Patrón SQL-001: Índices en Campos de Búsqueda

**Descripción:** Incluir índices en campos de búsqueda frecuente.

**Índices obligatorios:**

```sql
CREATE INDEX idx_clientes_telefono ON clientes(telefono);
CREATE INDEX idx_mensajes_tenant_fecha ON mensajes(tenant_id, fecha);
CREATE INDEX idx_clientes_tenant ON clientes(tenant_id);
```

**Violación:** Tablas grandes sin índices en campos de WHERE.

---

## Patrón SQL-002: Consultas con Filtros

**Descripción:** Evitar consultas sin filtros en tablas grandes.

**Ejemplo correcto:**

```sql
SELECT * FROM mensajes WHERE tenant_id = ? AND fecha > ?;
```

**Ejemplo incorrecto:**

```sql
SELECT * FROM mensajes;
```

---

## Patrón SQL-003: Prepared Statements Obligatórios

**Descripción:** Usar prepared statements para evitar SQL injection.

**Ejemplo correcto:**

```python
cursor.execute("SELECT * FROM clientes WHERE telefono = ?", (telefono,))
```

**Ejemplo incorrecto:**

```python
cursor.execute(f"SELECT * FROM clientes WHERE telefono = '{telefono}'")
```

---

## Patrón DOCKER-001: Límites de Memoria

**Descripción:** Todo contenedor Docker debe tener límites de memoria.

**Ejemplo docker-compose.yml:**

```yaml
services:
  n8n:
    image: n8n-io/n8n
    deploy:
      resources:
        limits:
          memory: 1.5G
        reservations:
          memory: 1G
```
         
---

## Patrón BASH-001: Error Handling en Scripts

**Descripción:** Scripts bash deben tener error handling.

**Plantilla obligatoria:**

```bash
#!/bin/bash
set -euo pipefail

# Script content
command || echo "Error: command failed" >&2
```

**Directivas obligatorias:**

set -e (exit on error)
set -u (error on undefined variable)
set -o pipefail (pipeline fails if any command fails)

---

## Patrón N8N-001: Function Node Estructurado

**Descripción:** Function nodes en n8n deben retornar estructura consistente.

**Plantilla obligatoria:**

```javascript
try {
  const inputData = items[0].json;
  
  // Process data
  const result = processData(inputData);
  
  return [{ json: { success: true, result } }];
} catch (error) {
  return [{ json: { success: false, error: error.message } }];
}
```

---

## 📦 TEMPLATE COMPLETO: Workflow n8n JSON

### Estructura Base para Cualquier Workflow

```json
{
  "name": "INFRA-XXX-Nombre-Descriptivo",
  "nodes": [
    {
      "parameters": {},
      "name": "Start",
      "type": "n8n-nodes-base.start",
      "typeVersion": 1,
      "position": [250, 300]
    },
    {
      "parameters": {
        "method": "POST",
        "url": "={{ $env.OPENROUTER_API_URL }}",
        "sendHeaders": {
          "parameters": [
            {
              "name": "Authorization",
              "value": "Bearer {{ $env.OPENROUTER_API_KEY }}"
                          }
          ]
        },
        "sendBody": {
          "parameters": [
            {
              "name": "model",
              "value": "anthropic/claude-3.5-sonnet"
            }
          ]
        },
        "options": {
          "timeout": 10000
        }
      },
      "name": "HTTP Request",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4,
      "position": [450, 300]
    },
    {
      "parameters": {
        "jsCode": "try {\n  const inputData = items[0].json;\n  const result = processData(inputData);\n  return [{ json: { success: true, result } }];\n} catch (error) {\n  return [{ json: { success: false, error: error.message } }];\n}"
      },
      "name": "Function",
      "type": "n8n-nodes-base.function",
      "typeVersion": 2,
      "position": [650, 300]
    }
  ],
  "pinData": {},
  "connections": {
    "Start": {
      "main": [
        [
          {
            "node": "HTTP Request",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "HTTP Request": {
      "main": [
        [
          {
            "node": "Function",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  },
  "active": false,
  "settings": {
    "executionOrder": "v1"
  },
  "versionId": "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",
  "meta": {
    "instanceId": "XXXXXXXXXXXXXXXX"
  },
  "tags": [
    {
      "name": "infraestructura"
    },
    {
      "name": "tenant_id"
    }
  ]
}
```

### Reglas para Generar Workflows:

|Elemento	       |Regla	                   |Ejemplo                          |
|------------------|---------------------------|---------------------------------|
|Nombre	           |INFRA-XXX o CLIENTE-XXX	   |INFRA-001-Monitor-Salud-VPS      |
|HTTP Request	   |Timeout obligatorio	       |timeout: 10000                   |
|Function Node	   |Try/catch siempre	       |Ver plantilla arriba             |
|Credentials	   |Usar variables de entorno  |{{ $env.API_KEY }}               |
|Tags	           |Incluir tenant_id	       |["infraestructura", "tenant_id"] |

**Violación crítica:** Workflow sin timeout en HTTP Request nodes.


## Checklist de Validación de Código

- [ ] JavaScript usa async/await con try/catch
- [ ] Fetch incluye timeout
- [ ] Python usa requests con timeout
- [ ] SQL usa prepared statements
- [ ] Índices creados en campos de búsqueda
- [ ] Docker tiene límites de memoria
- [ ] Bash tiene set -euo pipefail
- [ ] n8n Function nodes retornan estructura consistente

Versión 1.1.0 - Marzo 2026 - Mantis-AgenticDev
Licencia: Creative Commons para uso interno del proyecto

