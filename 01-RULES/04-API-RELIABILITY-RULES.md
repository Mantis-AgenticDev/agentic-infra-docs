---
title: "API RELIABILITY RULES - Agentic Infra Docs"
category: "APIs"
priority: "Media"
version: "1.0.0"
last_updated: "2026-03"
language: "es"
repository: "agentic-infra-docs"
owner: "Mantis-AgenticDev"
type: "rules"
ia_parser_version: "2.0"
auto_validate: true
compliance_check: "weekly"
validation_script: "scripts/validate-api-timeouts.sh"
auto_fixable: false
severity_scope: "critical"
rules_count: 10
tags:
  - api
  - reliability
  - timeout
  - openrouter
  - error-handling
related_files:
  - "05-CODE-PATTERNS-RULES.md"
  - "02-SKILLS/rest-api-openrouter-qdrant-supabase.md"
---

# API RELIABILITY RULES

## Metadatos del Documento

- **Categoría:** APIs
- **Prioridad de carga:** Media
- **Versión:** 1.0.0
- **Última actualización:** Marzo 2026
- **Archivos relacionados:** 05-CODE-PATTERNS-RULES.md

---

## Regla API-001: Timeout Obligatorio en Todas las APIs

**Descripción:** Toda llamada API externa debe incluir timeout.

**Timeout estándar:** 5 segundos

**Excepciones:**

| API             | Timeout     | Justificación        |
|-----------------|-------------|----------------------|
| OpenRouter      | 10 segundos | IA puede tardar más  |
| Qdrant Cloud    | 5 segundos  | Vector search rápido |
| Telegram Bot    | 5 segundos  | Notificación simple  |
| Gmail SMTP      | 10 segundos | Envío de email       |
| Google Calendar | 5 segundos  | Creación de evento   |

**Violación crítica:** Llamada API sin timeout definido.

---

## Regla API-002: Manejo de Errores Obligatorio

**Descripción:** Toda llamada API debe tener try-catch o equivalente.

**Requisitos obligatorios:**

- Capturar excepciones de red
- Capturar errores HTTP (4xx, 5xx)
- Retornar error estructurado con causa y acción sugerida
- Nunca exponer stack trace completo a usuarios

**Estructura de error recomendada:**

```json
{
  "success": false,
  "error": "HTTP 503",
  "cause": "OpenRouter service unavailable",
  "action": "Retry in 30 seconds"
}
```
---

## Regla API-003: OpenRouter Configuración

**Descripción:** OpenRouter es el proveedor principal de IA.

**Configuración obligatoria:**

Parámetro	            Valor
Base URL	            https://openrouter.ai/api/v1
Header Authorization	Bearer {API_KEY}
Header HTTP-Referer	    URL del proyecto
Header X-Title	        agentic-infra-docs

**Modelos preferidos:**

Caso de Uso   	   Caso de Uso	Modelo	          Costo Relativo
Coding	            anthropic/claude-3.5-sonnet 	Alto
Rápido	            google/gemini-2.0-flash-lite	Bajo
Económico	        openai/gpt-4o-mini          	Medio
RAG	                moonshotai/kimi-k2           	Medio

---

## Regla API-004: No Llamadas Duplicadas

**Descripción:** Evitar llamadas API duplicadas en mismo contexto.

**Requisitos obligatorios:**

Cachear respuestas cuando sea posible (TTL 5 minutos)
Validar si dato ya existe antes de llamar API
Usar idempotencia en operaciones de escritura

**Violación:** Llamar OpenRouter 2 veces para misma pregunta en menos de 1 minuto.

---

## Regla API-005: Validación de Entradas Antes de Enviar

**Descripción:** Validar inputs antes de enviar a APIs externas.

**Validaciones mínimas:**

Strings no vacíos
Longitud máxima definida (ej: 4000 caracteres para prompts)
Caracteres especiales escapados
tenant_id presente en todos los payloads

---

## Regla API-006: Registro de Errores Sin Secrets

**Descripción:** Logs de errores nunca deben incluir secrets.

**Prohibido en logs:**

API keys completas (mostrar solo últimos 4 caracteres)
Tokens de acceso
Passwords
Datos sensibles de clientes

**Permitido en logs:**

Código de error HTTP
Timestamp
Endpoint llamado (sin query params sensibles)
tenant_id (para auditoría)

---

## Regla API-007: Reintentos con Backoff Exponencial

**Descripción:** Reintentos deben usar backoff exponencial.

**Configuración recomendada:**

Intento	    Delay	      Máximo de Intentos
1	         0 segundos	        -
2	         5 segundos	        -
3	        15 segundos     	-
4	        45 segundos	   Máximo alcanzado

**Fórmula:** delay = base_delay * (2 ^ (intent_number - 1))

### Reintentos con Backoff Exponencial (API-007)

**Configuración en workflows n8n:**

| Intento | Delay  | Máximo Intentos |
|---------|--------|-----------------|
| 1       | 0 seg  | -               |
| 2       | 5 seg  | -               |
| 3       | 15 seg | -               |
| 4       | 45 seg | Máximo alcanzado|

**Fórmula:** delay = 5 * (2 ^ (intento - 1))

---

## Regla API-008: Circuit Breaker para APIs Críticas

**Descripción:** Implementar circuit breaker para APIs críticas.

**Configuración recomendada:**

Parámetro	           Valor
Failure threshold	   5 fallos consecutivos
Recovery timeout	  60 segundos
Half-open requests	   1

**APIs críticas:** OpenRouter, Qdrant Cloud, MySQL.

---

## Regla API-009: Rate Limiting Respetado

**Descripción:** Respetar rate limits de todas las APIs externas.

**Límites conocidos:**

API	             Rate Limit	            Acción si excede
OpenRouter	     Variable por modelo	Esperar y reintentar
Qdrant Cloud	 100 req/min	        Queue requests
Telegram Bot	  30 msg/seg	        Batch messages
Gmail SMTP	     100 emails/día	        Queue para próximo día

---

## Regla API-010: Fallback para APIs Críticas

**Descripción:** APIs críticas deben tener fallback configurado.

**Fallbacks recomendados:**

API Primaria	       Fallback	           Caso de Uso
OpenRouter Claude	OpenRouter Gemini	Si Claude unavailable
Qdrant Cloud	    Error + log	        No hay fallback vector DB
Telegram Bot	    Gmail SMTP	        Si Telegram down, enviar email

---

## Plantilla de Llamada API (JavaScript/n8n)

```javascript

try {
  const response = await fetch(url, {
    method: 'POST',
    headers: { 
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${API_KEY}`
    },
    body: JSON.stringify(data),
    signal: AbortSignal.timeout(5000)
  });

  if (!response.ok) {
    return { 
      success: false, 
      error: `HTTP ${response.status}`,
      action: 'Retry in 30 seconds'
    };
  }

  return { success: true, data: await response.json() };
} catch (error) {
  return { 
    success: false, 
    error: error.message,
    action: 'Check network connectivity'
  };
}
```

---

## Checklist de Validación de APIs

- [ ] Todas las APIs tienen timeout definido
- [ ] Todas las APIs tienen manejo de errores
- [ ] Secrets no están en código
- [ ] Logs no exponen API keys
- [ ] Reintentos con backoff exponencial
- [ ] Rate limits respetados
- [ ] Fallbacks configurados para APIs críticas


Versión 1.0.0 - Marzo 2026 - Mantis-AgenticDev
Licencia: Creative Commons para uso interno del proyecto

