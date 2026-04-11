---
title: "redis-session-management"
category: "Configuración"
domain: ["generico", "infraestructura", "comunicaciones"]
constraints: ["C1", "C2", "C3", "C4", "C5", "C6"]
priority: "Alta"
version: "1.0.1"
last_updated: "2026-04-15"
ai_optimized: true
tags:
  - sdd/config/redis
  - lang/es
related_files:
  - "01-RULES/06-MULTITENANCY-RULES.md"
  - "01-RULES/03-SECURITY-RULES.md"
  - "00-CONTEXT/facundo-infrastructure.md"
  - "02-SKILLS/INFRAESTRUCTURA/vps-interconnection.md"
  - "02-SKILLS/INFRAESTRUCTURA/ssh-tunnels-remote-services.md"
  - "02-SKILLS/INFRAESTRUCTURA/n8n-concurrency-limiting.md"
---

## 🟢 MODO JUNIOR: Guía de Inicio Rápido

### ✅ Checklist de Prerrequisitos
- [ ] Tener acceso SSH a un VPS Ubuntu 22.04/24.04 con al menos **512 MB de RAM libre** (C1).
- [ ] Tener `ufw` activo y configurado (ver [[02-SKILLS/INFRAESTRUCTURA/ufw-firewall-configuration.md]]).
- [ ] Tener `docker` y `docker-compose` instalados.
- [ ] Conocer la IP interna del VPS donde corren los agentes n8n (ej. `10.0.0.5`).
- [ ] Definir `REDIS_PASSWORD` en `.env` (C3) — ver Ejemplo 1.

### ⏱️ Tiempo Estimado
- **Lectura y comprensión:** 5 minutos.
- **Implementación básica (Docker):** 3 minutos.
- **Verificación y validación:** 2 minutos.

### 🧭 Cómo Usar este Documento
1. Lee **Fundamentos** si no sabes qué es Redis o por qué lo necesitas para tus agentes.
2. Copia y pega el **Ejemplo 1** para levantar Redis en segundos.
3. Aplica el **Ejemplo 3** para integrarlo con n8n.
4. Si algo falla, ve a la tabla de **Troubleshooting**.

### 🆘 ¿Qué hacer si falla?
- No entres en pánico. Redis es robusto y los fallos suelen ser por permisos o memoria.
- Ejecuta el **Comando de Diagnóstico** de la tabla de Troubleshooting.
- Verifica que el puerto `6379` no esté ocupado: `sudo ss -tulpn | grep 6379`.

> 📖 **Glosario**: Ver sección final para definiciones de términos técnicos.

---

## 🎯 Propósito y Alcance

Este documento define la configuración estandarizada de **Redis como gestor de sesiones y caché de corta duración** para los agentes autónomos de MANTIS AGENTIC (n8n, bots de WhatsApp/Telegram, RAG conversacional).

**Propósito Principal:** Proveer una "memoria volátil" compartida para flujos de trabajo multi-paso, evitando la pérdida de contexto por reinicios de n8n, balanceo de carga o timeouts de webhook.

**Alcance Específico:**
- Despliegue de Redis en Docker optimizado para VPS de 2vCPU / 4-8GB RAM (C1/C2).
- Aislamiento de datos mediante claves prefijadas con `tenant_id` (C4).
- Integración con nodos `Redis` de n8n y `ioredis` en Code Node.
- Configuración de TTL (expiración) automática para cumplir con límites de RAM.
- **Exclusiones:** No cubre Redis Cluster, Sentinel o persistencia RDB/AOF para datos críticos (para eso ver [[02-SKILLS/SEGURIDAD/backup-encryption.md]]).

---

## 📐 Fundamentos (De 0 a Intermedio)

### 1. ¿Por qué Redis y no la Memoria de n8n?
n8n guarda el estado de ejecución en su propia base de datos (SQLite/PostgreSQL), pero **solo dentro del mismo workflow**. Si un usuario de WhatsApp inicia una conversación en el workflow "Recepción" y luego el flujo lo deriva a "Reservas", el contexto se pierde.

**Analogía universitaria:** Redis es como el **pizarrón compartido del laboratorio**. Varios investigadores (agentes) pueden anotar avances y leerlos en tiempo real, y se borra al final del día (TTL).

### 2. El Modelo de Datos: Clave-Valor con Prefijos C4
En MANTIS usamos un estricto estándar de nomenclatura para cumplir con la multi-tenencia (C4):
```
tenant_{TENANT_ID}:session_{SESSION_ID}:step
tenant_{TENANT_ID}:cache:menu_{RESTAURANT_ID}
```
**Ejemplo Real:** `tenant_facundo_hotel:session_wa_551199999999:last_intent` → `"booking"`

### 3. Riesgo en VPS Pequeños (C1/C2): Memoria RAM
Redis vive **íntegramente en RAM**. En un VPS de 4GB, no podemos permitir que Redis consuma más de **256MB-512MB** (el resto es para n8n, Qdrant, Postgres).
- **Estrategia MANTIS:** Usar `maxmemory` y `maxmemory-policy volatile-lru` (elimina primero las claves con TTL).

---

## 🏗️ Arquitectura y Límites de Hardware (VPS 2vCPU/4-8GB RAM)

<!-- ai:constraint=C1,C2 -->

| Recurso | Límite Estricto MANTIS | Configuración en Redis |
| :--- | :--- | :--- |
| **RAM** | Máx **384 MB** (para VPS 4GB) / **768 MB** (para VPS 8GB) | `maxmemory 384mb` |
| **CPU** | Máx **1 vCPU** (Redis es single-threaded por naturaleza) | No requiere ajuste extra. Usar `taskset -c 0` si se comparte con procesos críticos. |
| **Conexiones** | Máx **100 clientes simultáneos** (n8n workers + devs) | `maxclients 100` |
| **Persistencia** | **Desactivada** (RDB/AOF) para ahorrar I/O y CPU. | `save ""` (comentado) |
| **Auth** | Requiere contraseña (`requirepass`) inyectada desde `.env` (C3) | `--requirepass ${REDIS_PASSWORD}` |

**Comando de Verificación de Carga:**
```bash
docker stats redis-mantis --no-stream
# Verificar que MEM USAGE / LIMIT no supere el 90%.
```

---

## 🔗 Conexión Local vs Externa / Cross-VPS

### Escenario 1: Local (Mismo VPS - Producción Simple)
- **Contexto:** n8n y Redis están en el mismo Docker Network `mantis_net`.
- **Conexión:** `redis://:PASSWORD@redis-mantis:6379`
- **Seguridad:** El puerto `6379` **NO** se publica en el host (`-p 6379:6379`). Solo accesible dentro de Docker.

### Escenario 2: Cross-VPS (Hotel/Posadas - Baja Latencia)
- **Contexto:** El VPS "Agentes" (n8n) necesita leer sesiones del VPS "Almacén" (Redis).
- **Patrón MANTIS (C3):** **Túnel SSH**.
- **Configuración:**
    1. VPS Agentes crea túnel: `ssh -fN -L 6379:localhost:6379 user@VPS_ALMACEN`
    2. n8n se conecta a `localhost:6379` con contraseña.
- **Beneficio:** El tráfico de sesiones está cifrado y no expone Redis a internet.

### Escenario 3: Externo (Prohibido - C3)
- Redis **NUNCA** debe ser accesible con `bind 0.0.0.0` y sin firewall.

---

## 🛠️ 10 Ejemplos de Configuración (Copy-Paste Validables)

### Ejemplo 1: Despliegue Docker Básico con Límites C1/C2 + Auth C3
**Objetivo**: Levantar Redis optimizado para 4GB de RAM con autenticación.
**Nivel**: 🟢

```yaml
# docker-compose.redis.yml
version: '3.8'
services:
  redis-mantis:
    image: redis:7.2-alpine
    container_name: redis-mantis
    restart: unless-stopped
    # Optimización de CPU C2: Usar solo el primer core
    cpuset: "0"
    # Límite de RAM C1
    mem_limit: 384m
    mem_reservation: 256m
    # Auth C3 + límites + política de eviction
    command: >
      redis-server
      --maxmemory 384mb
      --maxmemory-policy volatile-lru
      --maxclients 100
      --tcp-backlog 128
      --requirepass ${REDIS_PASSWORD}
    environment:
      - REDIS_PASSWORD=${REDIS_PASSWORD}  # Inyectar desde .env, nunca hardcodear
    networks:
      - mantis_net
    volumes:
      # Volumen temporal (tmpfs) para evitar escritura en disco (C1: Ahorro I/O)
      - type: tmpfs
        target: /data
        tmpfs:
          size: 100M
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "$${REDIS_PASSWORD}", "ping"]
      interval: 30s
      timeout: 5s
      retries: 3

networks:
  mantis_net:
    external: true
```

✅ Deberías ver:
```
docker compose -f docker-compose.redis.yml up -d
docker logs redis-mantis | grep "Ready to accept"
# 1:M 10 Apr 10:00:00.001 * Ready to accept connections
```

❌ Si ves esto en su lugar:
`Error response from daemon: network mantis_net not found`

→ Ve a Troubleshooting #1

### Ejemplo 2: Verificar Conexión y Establecer un Valor desde Bash
**Objetivo**: Probar conectividad desde el host o un contenedor n8n.
**Nivel**: 🟢

```bash
# Instalar redis-tools en el host (solo para debug)
sudo apt install redis-tools -y

# Conectar al contenedor con auth (C3)
redis-cli -h 127.0.0.1 -p 6379 -a "$REDIS_PASSWORD" ping
# Alternativa directa dentro del contenedor:
docker exec redis-mantis redis-cli -a "$REDIS_PASSWORD" ping

# Establecer una clave con tenant_id (C4)
docker exec redis-mantis redis-cli -a "$REDIS_PASSWORD" set tenant_facundo_hotel:test "OK"

✅ Deberías ver:
PONG
OK

❌ Si ves esto en su lugar:
Could not connect to Redis at 127.0.0.1:6379: Connection refused

→ Ve a Troubleshooting #2
```

### Ejemplo 3: Configuración del Nodo Redis en n8n
**Objetivo**: Añadir credenciales Redis en n8n para usar en workflows.
**Nivel**: 🟡

```text
1. En n8n, ve a Credenciales > Redis.
2. Completa los campos:
   - Host: redis-mantis (nombre del servicio docker)
   - Port: 6379
   - Database: 0
   - Password: ${REDIS_PASSWORD} (inyectar desde variable de entorno)
   - Key Prefix: (vacío, lo gestionamos manualmente por C4)
3. Guarda y testea.

✅ Deberías ver:
Connection tested successfully

❌ Si ves esto en su lugar:
ECONNREFUSED 127.0.0.1:6379

→ Ve a Troubleshooting #5 (Red de Docker)
```

### Ejemplo 4: Workflow n8n para Guardar Contexto de Conversación (C4)
**Objetivo**: Un agente de WhatsApp guarda el último mensaje del usuario.
**Nivel**: 🟡

> 💡 **Nota**: Este ejemplo requiere instalar `ioredis` en el contenedor n8n o usar el nodo oficial "Redis" de n8n.

```javascript
// Código para un Code Node de n8n (con ioredis instalado)
const Redis = require('ioredis');
const redis = new Redis({
  host: process.env.REDIS_HOST || 'redis-mantis',
  port: 6379,
  password: process.env.REDIS_PASSWORD,
  keyPrefix: `tenant_${$json.tenant_id}:` // Prefijo C4 automático
});

const userId = $json.from; // Número de teléfono
const message = $json.body;

// Guardar con TTL de 10 minutos (600 segundos)
await redis.setex(`session_${userId}:last_msg`, 600, message);

return { success: true, key: `tenant_${$json.tenant_id}:session_${userId}:last_msg` };

✅ Deberías ver:
{ "success": true, "key": "tenant_facundo_hotel:session_551199999999:last_msg" }

❌ Si ves esto en su lugar:
Error: Cannot find module 'ioredis'

→ Instalar en Dockerfile de n8n: RUN npm install ioredis
```

### Ejemplo 5: Implementar un Semáforo para Limitar Concurrencia (Hotel Booking)
**Objetivo**: Evitar que dos agentes procesen la misma reserva al mismo tiempo (Race Condition).
**Nivel**: 🔴

```javascript
const redis = await this.helpers.getRedisClient(); // O usar ioredis como en Ejemplo 4
const lockKey = `tenant_${tenantId}:lock:booking_${bookingId}`;

// Intentar adquirir bloqueo (SET NX = Solo si no existe)
const acquired = await redis.set(lockKey, 'locked', 'EX', 30, 'NX');

if (!acquired) {
  throw new Error('Reserva en proceso por otro agente. Reintente.');
}

try {
  // ... Procesar reserva (consultar Qdrant, enviar email) ...
  return { status: 'ok' };
} finally {
  // Liberar bloqueo
  await redis.del(lockKey);
}

✅ Deberías ver:
{ "status": "ok" }

❌ Si ves esto en su lugar:
Reserva en proceso por otro agente. Reintente.

→ Comportamiento esperado. El segundo agente debe esperar y reintentar (circuit breaker).
```

### Ejemplo 6: Almacenar Menú de Restaurante en Caché (C1 Optimización)
**Objetivo**: Reducir consultas a Qdrant/DB para el menú diario.
**Nivel**: 🟡

```javascript
const redis = await this.helpers.getRedisClient();
const tenantId = $env.TENANT_ID;
const cacheKey = `tenant_${tenantId}:cache:menu_diario`;

// Intentar leer de caché
let menu = await redis.get(cacheKey);

if (!menu) {
  // Simular consulta pesada a Qdrant
  menu = JSON.stringify({ platos: ["Paella", "Ensalada Cesar"] });
  // Guardar en caché por 1 hora (3600s)
  await redis.setex(cacheKey, 3600, menu);
  console.log("Caché actualizada desde origen.");
}

return JSON.parse(menu);

✅ Deberías ver:
{ "platos": ["Paella", "Ensalada Cesar"] }
# En logs: "Caché actualizada desde origen." (solo la primera vez)

❌ Si ves esto en su lugar:
ERR invalid expire time in setex

→ Asegúrate de que el TTL es un número entero.
```

### Ejemplo 7: Auditoría de Sesiones Activas por Tenant (C4/C5)
**Objetivo**: Listar cuántos usuarios tienen conversación abierta ahora mismo.
**Nivel**: 🟡

```bash
# Conectar a Redis y contar claves de sesión con auth
docker exec redis-mantis redis-cli -a "$REDIS_PASSWORD" --scan --pattern "tenant_facundo_hotel:session_*" | wc -l

✅ Deberías ver:
5 (o el número de usuarios activos)

❌ Si ves esto en su lugar:
ERR unknown command '--scan'

→ Redis muy antiguo. Usar `KEYS *` (más lento, cuidado en producción).
```

### Ejemplo 8: Configuración de Healthcheck Avanzado en n8n
**Objetivo**: Un workflow que monitorea la salud de Redis y envía alerta a Telegram.
**Nivel**: 🟡

```json
// Nodo "Execute Command" en n8n
{
  "command": "docker exec redis-mantis redis-cli -a $REDIS_PASSWORD ping | grep PONG"
}
// Si el comando falla (exit code != 0), n8n lanza error y activa un nodo "Telegram Alert".

✅ Deberías ver:
Output: "PONG" (Workflow continúa)

❌ Si ves esto en su lugar:
Error: Command failed: ... (Workflow se va por la ruta de error)

→ Ve a Troubleshooting #9
```

### Ejemplo 9: Limpieza Automática de Sesiones Huérfanas (C5 - Mantenimiento)
**Objetivo**: Script en crontab para forzar limpieza si `volatile-lru` no es suficiente.
**Nivel**: 🟢

```bash
# Añadir a crontab (sudo crontab -e) - versión segura con -print0
0 3 * * * docker exec redis-mantis redis-cli -a "$REDIS_PASSWORD" --scan --pattern "tenant_*:session_*" -print0 | xargs -0 -r docker exec redis-mantis redis-cli -a "$REDIS_PASSWORD" del > /dev/null 2>&1

✅ Deberías ver:
(No hay salida, pero los logs de Redis mostrarán las eliminaciones)

❌ Si ves esto en su lugar:
xargs: unmatched single quote

→ Asegúrate de que el patrón está bien escapado o usa un script aparte.
```

### Ejemplo 10: Aislamiento de Red con Firewall UFW (C3)
**Objetivo**: Bloquear acceso externo al puerto 6379 del host.
**Nivel**: 🟢

```bash
# Denegar tráfico externo al puerto 6379
sudo ufw deny 6379/tcp
sudo ufw reload

# Verificar que el puerto está cerrado desde fuera
nmap -p 6379 <IP_PUBLICA>

✅ Deberías ver:
PORT     STATE  SERVICE
6379/tcp closed redis

❌ Si ves esto en su lugar:
PORT     STATE SERVICE
6379/tcp open  redis

→ Ve a Troubleshooting #4
```

---

## 🐞 10 Eventos/Problemas Críticos y Troubleshooting

| Error Exacto (copiable) | Causa Raíz (lenguaje simple) | Comando de Diagnóstico | Solución Paso a Paso | Constraint Afectado (C#) |
| :--- | :--- | :--- | :--- | :--- |
| `Error response from daemon: network mantis_net not found` | La red Docker externa no existe. | `docker network ls` | 1. Crear la red: `docker network create mantis_net`. 2. Volver a ejecutar `docker compose up -d`. | C5 (Configuración previa) |
| `Could not connect to Redis at 127.0.0.1:6379` | El contenedor no está corriendo o el puerto no está mapeado al host. | `docker ps -a | grep redis` | 1. Verificar estado: `docker logs redis-mantis`. 2. Si está `Exited`, revisar error de memoria. 3. Si usas host, asegurar `-p 127.0.0.1:6379:6379` en docker-compose. | C1 (Memoria insuficiente) |
| `OOM command not allowed when used memory > 'maxmemory'` | Redis alcanzó el límite de `maxmemory` (384mb). | `docker exec redis-mantis redis-cli info memory` | 1. **Inmediato:** Aumentar temporalmente `maxmemory` en caliente: `docker exec redis-mantis redis-cli config set maxmemory 512mb`. 2. **Definitivo:** Aumentar límite en `docker-compose.yml` y recrear. 3. **Estrategia:** Reducir TTL de sesiones. | C1 / C2 |
| `nmap muestra 6379/tcp open` | Docker publicó el puerto en `0.0.0.0` (todas las interfaces) o UFW está mal configurado. | `sudo ss -tulpn | grep 6379` | 1. Si aparece `0.0.0.0:6379`, modificar `docker-compose` para usar `ports: - "127.0.0.1:6379:6379"`. 2. Verificar `ufw status`. 3. **Nunca** exponer a `0.0.0.0`. | C3 (Exposición de datos) |
| `ECONNREFUSED 127.0.0.1:6379` desde dentro de n8n (mismo VPS) | n8n y Redis no están en la misma red Docker. | `docker network inspect mantis_net` | 1. Asegurar que ambos `docker-compose` tienen `networks: - mantis_net`. 2. Verificar que n8n usa `redis-mantis` (nombre del servicio) como host, no `localhost`. | C5 (Interconexión) |
| `TypeError: Cannot find module 'ioredis'` | El nodo "Code" no tiene instalada la librería `ioredis`. | Revisar Dockerfile de n8n o logs del contenedor. | 1. Añadir en Dockerfile: `RUN npm install ioredis`. 2. O usar el nodo oficial "Redis" de n8n sin código personalizado. | C6 (Configuración de entorno) |
| `MISCONF Redis is configured to save RDB snapshots` | Redis intenta escribir en disco (RDB) pero no tiene permisos o espacio. | `docker logs redis-mantis | grep MISCONF` | 1. **Solución MANTIS:** Desactivar persistencia. Añadir `save ""` al comando de arranque. 2. Si necesitas persistencia, montar un volumen con permisos `1000:1000`. | C1 / C5 (I/O Disk) |
| `redis-cli se congela al ejecutar KEYS *` | La base de datos tiene millones de claves y Redis es single-threaded (C2). | `docker exec redis-mantis redis-cli dbsize` | 1. **Nunca usar `KEYS *` en producción.** Usar `SCAN` (Ejemplo 7). 2. Si se congela, matar el cliente (`Ctrl+C`) y el servidor seguirá funcionando. 3. Aumentar `tcp-backlog`. | C2 (Bloqueo de CPU) |
| `Healthcheck: curl: (56) Recv failure: Connection reset by peer` | El healthcheck de Docker no puede conectar porque `redis-cli` está saturado. | `docker inspect redis-mantis | grep -A 10 Health` | 1. Aumentar `timeout` del healthcheck a `10s`. 2. Reducir `interval` a `60s`. 3. Si falla, revisar logs de Redis por errores de memoria. | C1 / C2 |
| `Error: Reserva en proceso por otro agente.` constante. | Un agente falló y dejó el semáforo bloqueado (clave sin TTL). | `docker exec redis-mantis redis-cli -a "$REDIS_PASSWORD" --scan --pattern "*lock*"` | 1. Listar locks: `redis-cli --scan --pattern "*lock*"`. 2. Eliminar manualmente: `redis-cli del tenant_...lock_...`. 3. **Solución de código:** Usar `EX` (TTL) en el bloqueo (Ejemplo 5) para que expire automáticamente. | C4 (Integridad de sesión) |

---

## ✅ Validación SDD y Comandos de Verificación

<!-- ai:constraint=C5 -->

### 1. Verificación de Tenant ID en Claves (C4)
Asegura que no hay datos sin prefijo de tenant.
```bash
# Buscar claves que NO empiecen con "tenant_" (versión robusta con grep)
docker exec redis-mantis redis-cli -a "$REDIS_PASSWORD" --scan --pattern "*" | grep -v "^tenant_" | head -n 10
# Si aparece alguna clave como "test" o "cache", INCUMPLE C4.
# Deben ser "tenant_XXXX:..."
```

### 2. Verificación de Límite de Memoria (C1)
```bash
docker exec redis-mantis redis-cli -a "$REDIS_PASSWORD" info memory | grep used_memory_human
# Debe ser menor que maxmemory_human (384M).
```

### 3. Verificación de Integridad de Configuración (C5)
Compara el checksum del archivo de configuración.
```bash
sha256sum docker-compose.redis.yml > redis_config.sha256
# Guardar este archivo en lugar seguro. Validar semanalmente.
```

### 4. Verificación de Auth Habilitada (C3)
```bash
# Intentar conectar sin contraseña (debe fallar)
docker exec redis-mantis redis-cli ping
# Debe retornar: NOAUTH Authentication required.

# Conectar con contraseña (debe funcionar)
docker exec redis-mantis redis-cli -a "$REDIS_PASSWORD" ping
# Debe retornar: PONG
```

---

## 🔗 Referencias Cruzadas

- **[[01-RULES/06-MULTITENANCY-RULES.md]]** - Reglas de aislamiento de datos (C4).
- **[[02-SKILLS/INFRAESTRUCTURA/n8n-concurrency-limiting.md]]** - Uso avanzado de semáforos.
- **[[02-SKILLS/INFRAESTRUCTURA/vps-interconnection.md]]** - Configuración de túnel SSH para Redis Cross-VPS.
- **[[00-CONTEXT/facundo-infrastructure.md]]** - Topología de VPS de Facundo.
- **[[02-SKILLS/SEGURIDAD/backup-encryption.md]]** - Para persistencia crítica (fuera del alcance de este skill).

---

## 📖 Glosario Técnico

| Término | Significado | Ejemplo en MANTIS |
| :--- | :--- | :--- |
| **Redis** | Base de datos en memoria RAM (rápida) para guardar datos temporales. | "Recuerda que el cliente del hotel preguntó por el menú vegano hace 5 minutos." |
| **Sesión** | Estado temporal de una conversación. | Un usuario de WhatsApp pide una reserva; Redis guarda el paso actual (fecha, hora, personas). |
| **TTL** | Time To Live (Tiempo de Vida). | "Olvida esta conversación si pasan 10 minutos sin respuesta." |
| **tenant_id** | Identificador único del cliente/negocio. | `restaurante_123` o `hotel_456`. **Obligatorio (C4).** |
| **Semáforo (Lock)** | Técnica para asegurar que solo un proceso accede a un recurso a la vez. | Evita que dos agentes procesen la misma reserva simultáneamente. |
| **Volatile-LRU** | Política de eliminación que borra primero las claves que tienen TTL y no se han usado recientemente. | Estrategia para mantener Redis dentro del límite de RAM (C1). |
| **requirepass** | Directiva de Redis que exige autenticación para cualquier comando. | Defensa en profundidad: si un contenedor es comprometido, no puede acceder a datos de otros tenants (C3). |

FIN DEL ARCHIVO
<!-- ai:file-end marker - do not remove -->
Versión 1.0.1 - 2026-04-15 - Mantis-AgenticDev
```
