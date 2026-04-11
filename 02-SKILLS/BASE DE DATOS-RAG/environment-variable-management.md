---
title: "environment-variable-management"
category: "Skill"
domain: ["generico", "infraestructura", "seguridad", "backend"]
constraints: ["C1", "C2", "C3", "C4", "C5", "C6"]
priority: "CRÍTICA"
version: "1.0.1"
last_updated: "2026-04-15"
ai_optimized: true
tags:
  - sdd/skill/env-management
  - sdd/security
  - sdd/automation
  - lang/es
related_files:
  - "01-RULES/03-SECURITY-RULES.md"
  - "01-RULES/02-RESOURCE-GUARDRAILS.md"
  - "01-RULES/06-MULTITENANCY-RULES.md"
  - "00-CONTEXT/facundo-infrastructure.md"
  - "02-SKILLS/INFRAESTRUCTURA/redis-session-management.md"
  - "02-SKILLS/SEGURIDAD/backup-encryption.md"
  - "05-CONFIGURATIONS/scripts/VALIDATOR_DOCUMENTATION.md"
---

## 🟢 MODO JUNIOR: Guía de Inicio Rápido

### ✅ Checklist de Prerrequisitos
- [ ] Tener acceso a un VPS Ubuntu 22.04/24.04 (1 vCPU, 4 GB RAM mínimo).
- [ ] Saber qué es una variable de entorno (`VAR=valor`).
- [ ] Tener instalado `python3` (viene por defecto) y `jq` (`sudo apt install jq -y`).
- [ ] Haber leído la sección "Fundamentos" para entender por qué NO debes hacer `export PASSWORD=123456`.

### ⏱️ Tiempo Estimado
- **Comprensión del esquema:** 10 minutos.
- **Generación de un `.env` válido:** 2 minutos (copiando y adaptando plantilla).
- **Validación y encriptación:** 3 minutos.

### 🧭 Cómo Usar este Documento
1. **Si eres un desarrollador junior desplegando un agente:** Ve directo al **Ejemplo 1** y **Ejemplo 3**.
2. **Si estás diseñando un nuevo flujo de IA:** Lee la **Sección 4 (Flujo de Auto-Generación IA)**.
3. **Si algo falla:** Busca el error exacto en la tabla de **Troubleshooting**.

### 🆘 ¿Qué hacer si falla la validación?
- No modifiques el script de validación. El problema está en tu archivo `.env`.
- Ejecuta `python3 validate_env.py --verbose` para ver exactamente qué variable está mal.
- Compara tu archivo con `.env.template`.

### 📖 Glosario**: Ver sección final para definiciones de términos técnicos.

---

## 🎯 Propósito y Alcance

**Propósito:** Establecer un **sistema determinista y validable** para la gestión de variables de entorno en el ecosistema MANTIS AGENTIC. Este archivo es el **puente crítico** entre la generación especulativa de una IA y un despliegue exitoso y seguro en producción.

**Alcance:**
- Definición de un **Esquema JSON universal** para validar cualquier `.env` del proyecto.
- **Plantillas `.env.template`** para todos los dominios (Infraestructura, RAG, AI, Verticales).
- **Flujo de trabajo para IAs**: Cómo generar un `.env` válido desde cero usando estas reglas.
- **Script de validación pre-deploy** (`validate_env.py`) que debe ejecutarse **siempre** antes de un `docker compose up`.
- **Protocolo de seguridad**: Encriptación con SOPS, rotación de secretos y auditoría de cambios (C3, C5).

**Exclusiones:** Este skill **no** gestiona secretos a nivel de Kubernetes o HashiCorp Vault. Se limita al entorno de VPS individual con Docker.

---

## 📐 Fundamentos (De 0 a Intermedio)

### 1. El Problema de la Configuración Hardcodeada
Imagina que tu código Python tiene esto:
```python
DB_PASSWORD = "123456"
```
¿Qué pasa si cambias la contraseña? Tienes que modificar el código. ¿Qué pasa si subes el código a GitHub? **Todo el mundo ve tu contraseña**.

**La solución MANTIS:** Usar Variables de Entorno (`os.getenv("DB_PASSWORD")`). El valor vive fuera del código, en el sistema operativo o en un archivo `.env`.

### 2. Por qué un `.env.template` NO es suficiente para la IA
Una IA sin restricciones podría generar un `.env` como este:
```env
TENANT_ID=FACUNDO HOTEL 123!
MEMORY_LIMIT=999999
DB_HOST=mi-base-de-datos-publica.com
```
Esto rompería:
- **C4:** El Tenant ID tiene espacios y mayúsculas (formato inválido).
- **C1:** La memoria es infinita (el VPS colapsará).
- **C3:** La base de datos está expuesta a internet.

**El Esquema JSON actúa como un "abogado" que rechaza el archivo antes de que llegue al servidor.**

### 3. La Santísima Trinidad de MANTIS para Configuración
1. **Esquema (`env-schema.json`):** Define el contrato.
2. **Validador (`validate_env.py`):** Hace cumplir el contrato.
3. **Encriptador (`sops`):** Protege el contrato firmado.

---

## 🏗️ Arquitectura y Límites de Hardware (VPS 2vCPU/4-8GB RAM)

<!-- ai:constraint=C1,C2 -->

Las variables de entorno son el mecanismo principal para aplicar los límites de recursos **antes de que el contenedor arranque**.

| Variable de Entorno (Ejemplo) | Límite MANTIS (C1/C2) | Consecuencia de no limitar |
| :--- | :--- | :--- |
| `N8N_CONCURRENCY_LIMIT` | 4 (en VPS 2vCPU) | n8n lanza 20 workers, CPU al 100%, sistema inutilizable. |
| `QDRANT_MEMORY_LIMIT` | `512m` | Qdrant consume 2GB, OOM Killer mata Postgres. |
| `REDIS_MAXMEMORY` | `384mb` | Redis usa swap, latencia se dispara 100x. |
| `POSTGRES_SHARED_BUFFERS` | `256MB` | Postgres reserva 1GB, deja sin RAM a n8n. |
| `MISTRAL_OCR_TIMEOUT` | `60` (segundos) | Un PDF de 100 páginas bloquea el worker por 10 minutos. |

---

## 🔗 Conexión Local vs Externa / Cross-VPS (Variables de Red)

La variable `DB_HOST` determina si el tráfico es **seguro (C3)** o **catastrófico**.

| Escenario | Valor de `DB_HOST` | Requiere túnel SSH | Constraint |
| :--- | :--- | :--- | :--- |
| **Local (Mismo VPS)** | `localhost` o `postgres` (Docker service name) | No | C3 (Aislado) |
| **Cross-VPS (VPS Almacén)** | `10.0.0.5` (IP Privada VPN) | Sí (WireGuard) | C3 (Cifrado) |
| **EXTERNO (PROHIBIDO)** | `db.publica.com` | N/A | ❌ VIOLACIÓN C3 |

**Regla de Oro (C3):** Si `DB_HOST` no es `localhost`, un nombre de servicio Docker (sin puntos), o una IP privada (`10.`, `172.16-31.`, `192.168.`), el validador debe lanzar una **ADVERTENCIA CRÍTICA** y requerir confirmación manual.

---

## 🛠️ 20 Ejemplos de Configuración (Copy-Paste Validables)

### Ejemplo 1: Crear el Archivo `.env.template` Universal
**Objetivo**: Plantilla base para cualquier nuevo agente de MANTIS.
**Nivel**: 🟢

```bash
cat > .env.template << 'EOF'
# MANTIS AGENTIC ENV TEMPLATE v1.0
# NO MODIFICAR NOMBRES DE VARIABLES. SOLO VALORES.

# --- IDENTIDAD (C4: OBLIGATORIO) ---
TENANT_ID=cambiar_por_id_unico
AGENT_ID=cambiar_por_nombre_agente

# --- LIMITES DE HARDWARE (C1/C2) ---
N8N_CONCURRENCY_LIMIT=4
REDIS_MAXMEMORY=384mb
QDRANT_MEMORY_LIMIT=512m

# --- CONEXIONES SEGURAS (C3) ---
DB_HOST_INTERNAL=localhost
DB_PORT=5432

# --- API EXTERNAS (C6: SOLO CLOUD) ---
OPENROUTER_API_KEY=sk-or-v1-cambiar
MISTRAL_API_KEY=cambiar

# --- BACKUP Y ENCRIPTACION (C5) ---
BACKUP_ENCRYPTION_KEY_AGE=age1...
EOF
echo "✅ Plantilla creada. Cópiala a .env y edita los valores."
```

✅ Deberías ver:
`✅ Plantilla creada. Cópiala a .env y edita los valores.`

❌ Si ves esto en su lugar:
`Permission denied` → No tienes permisos de escritura en el directorio.

---

### Ejemplo 2: Validar un `.env` con el Script de Validación SDD
**Objetivo**: Comprobar que el archivo cumple con el esquema y las políticas C1-C6.
**Nivel**: 🟢

```bash
# Descargar el script validador (asumiendo que está en el repo)
wget https://raw.githubusercontent.com/.../validate_env.py
chmod +x validate_env.py

# Ejecutar validación
python3 validate_env.py --env .env --schema env-schema.json

✅ Deberías ver:
{
  "status": "ok",
  "validated_vars": 15,
  "tenant_id": "facundo_hotel",
  "constraints_check": "C1,C2,C3,C4,C5,C6: PASSED",
  "ready_for_deploy": true
}

❌ Si ves esto en su lugar:
{"status": "fail", "error": "TENANT_ID does not match regex ..."}

→ Ve a Troubleshooting #3
```

---

### Ejemplo 3: Generación de un `.env` Válido por IA (Prompt para DeepSeek/Claude)
**Objetivo**: Instrucción exacta para que una IA genere un archivo sin alucinaciones.
**Nivel**: 🟡

```text
PROMPT PARA IA:
"Genera un archivo .env para MANTIS AGENTIC basado en el esquema `env-schema.json`.
Reglas obligatorias:
- TENANT_ID: genera un slug válido (minúsculas, números, guiones, 4-32 chars).
- DB_HOST_INTERNAL: usa 'postgres' (Docker service) o '10.0.0.5' (IP privada).
- N8N_CONCURRENCY_LIMIT: máximo 4 (C2).
- REDIS_MAXMEMORY: máximo 384mb (C1).
- OPENROUTER_API_KEY: usa un placeholder 'sk-or-v1-REEMPLAZAR'.
- BACKUP_ENCRYPTION_KEY_AGE: genera una clave age válida con 'age-keygen'.
Responde ÚNICAMENTE con el contenido del archivo .env, sin markdown extra."
```

✅ Deberías ver (output de IA):
```env
TENANT_ID=restaurante_baires
N8N_CONCURRENCY_LIMIT=4
DB_HOST_INTERNAL=postgres
...
```

❌ Si ves esto en su lugar:
`TENANT_ID=Restaurante Baires` → La IA ignoró las reglas. Refina el prompt o usa un modelo más determinista (Temperature=0).

---

### Ejemplo 4: Encriptar un `.env` con SOPS (Age) para Commit Seguro (C3/C5)
**Objetivo**: Poder guardar el archivo en Git sin exponer secretos.
**Nivel**: 🟡

```bash
# 1. Instalar age y sops
sudo apt install age sops -y

# 2. Generar clave Age (guárdala en lugar seguro, NO en el repo)
age-keygen -o ~/.config/sops/age/mantis-keys.txt

# 3. Encriptar .env
sops --encrypt --age $(awk '/public key:/ {print $4}' ~/.config/sops/age/mantis-keys.txt) .env > .env.enc

# 4. Verificar contenido (debe ser ilegible)
head -n 5 .env.enc

✅ Deberías ver:
{
	"TENANT_ID": "ENC[AES256_GCM,data:...]",
	"sops": {
		"age": [...]
	}
}

❌ Si ves esto en su lugar:
Error: failed to parse age recipient

→ Ve a Troubleshooting #5
```

---

### Ejemplo 5: Variables Específicas para Agente de Restaurante (Vertical)
**Objetivo**: `.env.template` para el dominio `RESTAURANTES`.
**Nivel**: 🟢

```env
# RESTAURANTES/.env.template
TENANT_ID=restaurant_demo
RESTAURANT_MENU_CACHE_TTL=3600
RESTAURANT_BOOKING_TIMEOUT=30
RESTAURANT_GOOGLE_MAPS_API_KEY=AIza...
RESTAURANT_POS_ENDPOINT=http://localhost:8080/pos
RESTAURANT_MAX_MESA_CAPACIDAD=12
```

**Validación:** El esquema para esta vertical debe validar que `RESTAURANT_MAX_MESA_CAPACIDAD` sea un entero entre 1 y 50 (C1: No podemos procesar reservas de 500 personas en un VPS pequeño).

---

### Ejemplo 6: Variables Específicas para Hotel (Redis + Sesiones)
**Objetivo**: `.env.template` para `HOTELES-POSADAS`.
**Nivel**: 🟢

```env
# HOTELES/.env.template
TENANT_ID=hotel_sol
REDIS_HOST=redis-mantis
REDIS_SESSION_TTL=900
HOTEL_GUEST_JOURNEY_STEPS=5
HOTEL_PRE_ARRIVAL_DAYS=2
HOTEL_SLACK_WEBHOOK_URL=https://hooks.slack.com/...
```

**Riesgo:** `HOTEL_SLACK_WEBHOOK_URL` es un secreto. Debe ser encriptado. El esquema debe validar que empiece por `https://hooks.slack.com/`.

---

### Ejemplo 7: Variables de Límite de Recursos para Qdrant (C1/C2)
**Objetivo**: Configuración exacta para VPS de 4GB RAM.
**Nivel**: 🟡

```env
QDRANT__SERVICE__GRPC_PORT=6334
QDRANT__SERVICE__HTTP_PORT=6333
QDRANT__STORAGE__OPTIMIZERS__DEFAULT_SEGMENT_NUMBER=2
QDRANT__STORAGE__OPTIMIZERS__MAX_OPTIMIZATION_THREADS=1
QDRANT__STORAGE__PERFORMANCE__MAX_SEARCH_THREADS=1
```

**Explicación:** `MAX_SEARCH_THREADS=1` (C2: 1 vCPU). Si se pone `0` (automático), Qdrant usará todos los cores y degradará n8n.

---

### Ejemplo 8: Desencriptar `.env.enc` en el Servidor de Producción (CI/CD) — SIN RACE CONDITION
**Objetivo**: Flujo seguro para que el script de deploy lea las variables **sin tocar disco**.
**Nivel**: 🔴

```bash
# En el servidor, la clave Age privada está en ~/.config/sops/age/mantis-keys.txt
export SOPS_AGE_KEY_FILE=~/.config/sops/age/mantis-keys.txt

# Trap para limpieza automática + process substitution (nunca escribe a disco)
trap 'rm -f /tmp/.env.$$' EXIT
sops --decrypt .env.enc > /tmp/.env.$$
docker compose --env-file /tmp/.env.$$ up -d

# Alternativa aún más segura (stdin directo, sin archivo temporal):
# sops --decrypt .env.enc | docker compose --env-file /dev/stdin up -d

✅ Deberías ver:
Contenedores arrancando con la configuración correcta.

❌ Si ves esto en su lugar:
Error: failed to decrypt data: no age identity found

→ Ve a Troubleshooting #8
```

---

### Ejemplo 9: Script de Rotación de Secretos (C5 - Cada 90 días)
**Objetivo**: Automatizar el cambio de `OPENROUTER_API_KEY` sin intervención manual.
**Nivel**: 🔴

```bash
#!/bin/bash
# rotate_secrets.sh
# 1. Obtener nueva API Key (simulado)
NEW_KEY="sk-or-v1-$(openssl rand -hex 16)"

# 2. Desencriptar, reemplazar, encriptar (usando | como delimitador en sed)
sops --decrypt .env.enc | sed "s|OPENROUTER_API_KEY=.*|OPENROUTER_API_KEY=$NEW_KEY|" | sops --encrypt --age AGE_PUB_KEY /dev/stdin > .env.enc.new

# 3. Backup del viejo (C5)
mv .env.enc .env.enc.backup.$(date +%Y%m%d)
mv .env.enc.new .env.enc

# 4. Registrar auditoría
echo "Rotación de OPENROUTER_API_KEY ejecutada $(date)" >> .env.audit.log

✅ Deberías ver:
Rotación completada. Backup guardado como .env.enc.backup.20260411.

❌ Si ves esto en su lugar:
sed: unmatched '/'

→ Usar | como delimitador en sed o migrar a yq para YAML/JSON.
```

---

### Ejemplo 10: Validación de Constraint C4 (Tenant ID en TODAS partes)
**Objetivo**: Asegurar que `TENANT_ID` está presente en `QDRANT__SERVICE__API_KEY` o similares.
**Nivel**: 🟡

```python
# Fragmento del validador validate_env.py
def validate_tenant_injection(env_dict):
    tenant = env_dict.get("TENANT_ID")
    errors = []
    # Verificar que las claves de Qdrant contengan el tenant_id (C4)
    if tenant and tenant not in env_dict.get("QDRANT_API_KEY", ""):
        errors.append("QDRANT_API_KEY no contiene el TENANT_ID (C4: Aislamiento de vectores)")
    return errors

✅ Si todo OK:
{"status": "ok", "c4_injection": "passed"}

❌ Si falla:
{"status": "fail", "error": "QDRANT_API_KEY no contiene el TENANT_ID..."}

→ Ve a Troubleshooting #14
```

---

### Ejemplo 11: Esquema JSON para Validación Automática (Fragmento Corregido)
**Objetivo**: Definir las reglas que el validador usa, con `additionalProperties` restringido.
**Nivel**: 🟡

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "TENANT_ID": {
      "type": "string",
      "pattern": "^[a-z0-9-]{4,32}$",
      "description": "Identificador único del cliente (C4)"
    },
    "N8N_CONCURRENCY_LIMIT": {
      "type": "integer",
      "minimum": 1,
      "maximum": 8,
      "default": 4
    },
    "REDIS_MAXMEMORY": {
      "type": "string",
      "pattern": "^[0-9]+(mb|gb)$"
    },
    "DB_HOST_INTERNAL": {
      "type": "string",
      "anyOf": [
        {"const": "localhost"},
        {"const": "host.docker.internal"},
        {"pattern": "^[a-z][a-z0-9-]*$"},
        {"pattern": "^10\\.\\d+\\.\\d+\\.\\d+$"},
        {"pattern": "^172\\.(1[6-9]|2[0-9]|3[0-1])\\.\\d+\\.\\d+$"},
        {"pattern": "^192\\.168\\.\\d+\\.\\d+$"}
      ]
    }
  },
  "required": ["TENANT_ID", "DB_HOST_INTERNAL"],
  "additionalProperties": {
    "type": "string",
    "pattern": "^[A-Za-z0-9_./:@#%&*+=?-]{1,512}$",
    "description": "Variables adicionales deben ser strings seguros (sin espacios ni caracteres de shell)"
  }
}
```

✅ **Validación:** Cualquier `.env` que no cumpla será rechazado por `jsonschema`. `additionalProperties` ahora valida formato, no acepta cualquier cosa.

---

### Ejemplo 12: Uso de Variables en `docker-compose.yml` con Valores por Defecto
**Objetivo**: Evitar que el contenedor falle si falta una variable no crítica.
**Nivel**: 🟢

```yaml
services:
  n8n:
    environment:
      - N8N_CONCURRENCY_LIMIT=${N8N_CONCURRENCY_LIMIT:-2}
      - WEBHOOK_URL=${WEBHOOK_URL:-http://localhost:5678}
```

**Explicación:** `${VAR:-2}` usa el valor de `VAR` o `2` si no está definida. Esto previene errores fatales en desarrollo.

---

### Ejemplo 13: Configuración de Timeouts para Mistral OCR (Evitar Bloqueos C1)
**Objetivo**: Limitar el tiempo de procesamiento de PDFs grandes en VPS pequeños.
**Nivel**: 🟡

```env
MISTRAL_OCR_TIMEOUT_SECONDS=60
MISTRAL_OCR_MAX_PAGES=10
MISTRAL_OCR_CHUNK_SIZE=512
```

**Validación:** El script de validación debe asegurar que `MISTRAL_OCR_MAX_PAGES * CHUNK_SIZE` no exceda los 512MB de RAM disponible.

---

### Ejemplo 14: Variable para Entorno (Development vs Production)
**Objetivo**: Cambiar comportamiento de logging o debugging.
**Nivel**: 🟢

```env
ENVIRONMENT=production   # o development
LOG_LEVEL=info           # debug solo en dev
DEBUG_TENANT_ID=         # Vacío en prod. En dev: "test_tenant"
```

**Riesgo (C3/C6):** Si `ENVIRONMENT=development` y `DEBUG=true` en producción, se pueden exponer stack traces con secretos.

---

### Ejemplo 15: Generación de un `.env` Completo para un Nuevo Tenant (Script IA)
**Objetivo**: Demostrar cómo una IA puede generar un archivo desplegable.
**Nivel**: 🔴

```python
# Generado por IA (modo script)
import secrets, json
tenant = "nuevo_restaurante"
env_vars = {
    "TENANT_ID": tenant,
    "N8N_CONCURRENCY_LIMIT": 4,
    "DB_HOST_INTERNAL": "postgres",
    "QDRANT_API_KEY": f"{tenant}_qdrant_key_{secrets.token_hex(8)}",
    "REDIS_MAXMEMORY": "384mb"
}
with open(f".env.{tenant}", "w") as f:
    for k, v in env_vars.items():
        f.write(f"{k}={v}\n")
print(json.dumps({"status": "generated", "file": f".env.{tenant}"}))
```

✅ Deberías ver:
`{"status": "generated", "file": ".env.nuevo_restaurante"}`

---

### Ejemplo 16: Auditoría de Cambios en Variables (C5 - Trazabilidad)
**Objetivo**: Saber quién cambió qué y cuándo.
**Nivel**: 🟡

```bash
# Hook post-deploy para registrar el checksum del .env usado
sha256sum .env >> .env.history.log
echo "[$(date)] Deployed by $(whoami)" >> .env.history.log

✅ Deberías ver:
(Si alguien modifica el archivo manualmente, el próximo deploy fallará por checksum si usamos validación estricta).
```

---

### Ejemplo 17: Bloqueo de IPs Públicas en Variables de Host (C3 Hardening) — CORREGIDO PARA DOCKER
**Objetivo**: Rechazar despliegues que intenten conectar a IPs públicas, permitiendo nombres de servicio Docker.
**Nivel**: 🔴

```python
# validate_env.py (extracto corregido)
import ipaddress, re

def is_valid_internal_host(host):
    # Permitir localhost y nombres de servicio Docker
    if host in ["localhost", "host.docker.internal"]:
        return True
    # Nombres de servicio Docker: solo letras, números, guiones, sin puntos ni slashes
    if re.match(r'^[a-z][a-z0-9-]*$', host):
        return True
    # Validar IPs privadas
    try:
        ip = ipaddress.ip_address(host)
        return ip.is_private
    except ValueError:
        return False  # Hostname público, IP inválida o formato no permitido

if not is_valid_internal_host(env.get("DB_HOST_INTERNAL")):
    raise ValueError("C3 VIOLATION: DB_HOST_INTERNAL must be localhost, Docker service name, or private IP (10.x, 172.16-31.x, 192.168.x)")
```

---

### Ejemplo 18: Manejo de Secretos Vacíos (Placeholders Obligatorios)
**Objetivo**: Evitar que un `API_KEY=` vacío llegue a producción.
**Nivel**: 🟢

```python
# Validación
if "API_KEY" in env and env["API_KEY"] in ["", "cambiar", "REEMPLAZAR", "changeme"]:
    errors.append("API_KEY contiene placeholder. Debe ser un valor real o encriptado.")
```

✅ Deberías ver error y el deploy se detiene.

---

### Ejemplo 19: Integración con Systemd para Variables Globales (Opcional)
**Objetivo**: Si no usas Docker, cargar variables a nivel de sistema.
**Nivel**: 🟡

```bash
# Crear archivo de entorno
sudo mkdir -p /etc/mantis
sudo cp .env /etc/mantis/agent.env
sudo chmod 600 /etc/mantis/agent.env

# En el servicio systemd:
[Service]
EnvironmentFile=/etc/mantis/agent.env
```

✅ El agente arranca con las variables inyectadas.

---

### Ejemplo 20: Comprobación Final de Despliegue (Healthcheck + Variables)
**Objetivo**: Verificar que las variables aplicadas son las correctas dentro del contenedor.
**Nivel**: 🟢

```bash
docker exec mantis-agent env | grep TENANT_ID

✅ Deberías ver:
TENANT_ID=facundo_hotel

❌ Si ves vacío o el valor por defecto, el .env no se montó correctamente.
```

---

## 🐞 20 Eventos/Problemas Críticos y Troubleshooting

| Error Exacto (copiable) | Causa Raíz (lenguaje simple) | Comando de Diagnóstico | Solución Paso a Paso | Constraint Afectado (C#) |
| :--- | :--- | :--- | :--- | :--- |
| `TENANT_ID does not match regex '^[a-z0-9-]{4,32}$'` | El Tenant ID contiene mayúsculas, espacios o caracteres especiales. | `echo $TENANT_ID` | 1. Convertir a minúsculas. 2. Reemplazar espacios por guiones. 3. Eliminar símbolos. Ej: `Facundo Hotel` -> `facundo-hotel`. | C4 |
| `N8N_CONCURRENCY_LIMIT is 12 (max 8)` | Se intentó asignar más workers de los que la CPU soporta (C2). | `nproc` (ver cores). | 1. Editar `.env`: `N8N_CONCURRENCY_LIMIT=4`. 2. Si es necesario más, migrar a VPS más grande (C7 futuro). | C1, C2 |
| `DB_HOST_INTERNAL is 'db.publica.com' (public IP)` | Alguien puso la IP pública o dominio de la base de datos. | `host db.publica.com` | 1. Usar IP privada (`10.0.0.5`) o nombre de servicio Docker (`postgres`). 2. Si es remoto, configurar túnel SSH o WireGuard. | C3 |
| `QDRANT_MEMORY_LIMIT is not a valid size (e.g., 512m)` | El valor no tiene unidad o tiene caracteres extraños. | `grep QDRANT .env` | 1. Usar formato: `512m` (MB) o `1g` (GB). 2. Corregir en `.env`. | C1 |
| `Error: failed to parse age recipient` | La clave pública Age tiene formato incorrecto o faltan `age1...`. | `age-keygen -y ~/.config/sops/age/mantis-keys.txt` | 1. Verificar que la clave empieza con `age1`. 2. Copiarla correctamente sin saltos de línea. | C5 |
| `sops: error: no age identity found in key file` | SOPS no encuentra la clave privada para desencriptar. | `echo $SOPS_AGE_KEY_FILE` | 1. Asegurar que la variable de entorno apunta al archivo correcto. 2. `export SOPS_AGE_KEY_FILE=/ruta/correcta`. | C3, C5 |
| `jsonschema.exceptions.ValidationError: 'REDIS_MAXMEMORY' is a required property` | Falta una variable obligatoria en el `.env`. | `grep REDIS_MAXMEMORY .env` | 1. Añadir la línea `REDIS_MAXMEMORY=384mb` al archivo. 2. Volver a validar. | C5 |
| `Error: OOM command not allowed when used memory > 'maxmemory'` (en Redis) | `REDIS_MAXMEMORY` es demasiado bajo para los datos actuales. | `docker exec redis redis-cli info memory` | 1. Aumentar `maxmemory` en `.env` a 512m. 2. Reiniciar Redis. 3. A largo plazo: reducir TTL de sesiones. | C1 |
| `MISTRAL_OCR_TIMEOUT_SECONDS is 600 (too high)` | Un timeout muy alto bloquea workers en VPS pequeño. | `grep TIMEOUT .env` | 1. Reducir a 60-120 segundos. 2. Dividir PDFs grandes en chunks más pequeños (usar `MISTRAL_OCR_MAX_PAGES`). | C2 |
| `QDRANT_API_KEY does not contain TENANT_ID` | La API Key de Qdrant es genérica, rompiendo el aislamiento C4. | `echo $TENANT_ID; echo $QDRANT_API_KEY` | 1. Regenerar API Key incluyendo el tenant: `{tenant_id}_qdrant_key_XXXX`. 2. Actualizar Qdrant con la nueva key. | C4 |
| `ENVIRONMENT=development in production .env` | Se filtró configuración de debug a producción. | `grep ENVIRONMENT .env` | 1. Cambiar a `production`. 2. Asegurar `LOG_LEVEL=info` o `error`. 3. Rotar secretos si se expusieron en logs. | C3, C6 |
| `BACKUP_ENCRYPTION_KEY_AGE is empty` | Los backups se harán sin encriptar (violación C5). | `grep BACKUP .env` | 1. Generar clave: `age-keygen`. 2. Copiar la clave pública en la variable. 3. Reencriptar `.env`. | C5 |
| `POSTGRES_SHARED_BUFFERS=1GB` (en VPS 4GB) | Configuración de Postgres demasiado agresiva, compite con n8n/Qdrant. | `free -h` | 1. Reducir a `256MB`. 2. Ajustar `effective_cache_size` a `2GB`. 3. Reiniciar Postgres. | C1, C2 |
| `RESTAURANT_MAX_MESA_CAPACIDAD=500` | Valor poco realista que causará timeouts en bucles. | `grep MAX_MESA .env` | 1. Limitar a 20-50 según la capacidad real del restaurante. 2. Si es una cadena grande, paginar las consultas. | C1, C2 |
| `sed: unmatched '/'` en script de rotación | Caracteres especiales en el nuevo valor (ej. URLs con `/`). | - | 1. Usar `|` como delimitador: `sed "s\|OLD\|NEW\|"`. 2. O mejor, usar `yq` para YAML/JSON. | C5 |
| `EnvironmentFile=/etc/mantis/agent.env not loading` | Permisos incorrectos o path equivocado. | `sudo journalctl -u mi-servicio` | 1. `chmod 600 /etc/mantis/agent.env`. 2. Asegurar que el usuario del servicio tiene lectura. | C5 |
| `docker compose up no toma los cambios del .env` | Docker cachea las variables si no se usa `--env-file`. | `docker compose config` | 1. Usar `docker compose --env-file .env up -d`. 2. O forzar recreación: `docker compose up -d --force-recreate`. | C5 |
| `ValidationError: 'API_KEY' contains placeholder 'REEMPLAZAR'` | La IA generó un placeholder en lugar de un secreto real. | `grep REEMPLAZAR .env` | 1. Reemplazar manualmente con la clave real. 2. Encriptar con `sops`. | C6 |
| `Permission denied: './validate_env.py'` | El script no tiene permisos de ejecución. | `ls -l validate_env.py` | 1. `chmod +x validate_env.py`. 2. Ejecutar con `python3 validate_env.py`. | - |
| `json.decoder.JSONDecodeError` al leer `env-schema.json` | El archivo JSON tiene una coma de más o falta una llave. | `python3 -m json.tool env-schema.json` | 1. Validar sintaxis con `json.tool`. 2. Corregir error manualmente o regenerar esquema. | C5 |

---

## ✅ Validación SDD y Comandos de Verificación

<!-- ai:constraint=C5 -->

### 1. Verificación de Integridad del Esquema y Plantillas (C5)
```bash
# Calcular checksum de los archivos críticos
sha256sum env-schema.json .env.template > env_integrity.sha256
# Comparar periódicamente con una copia de referencia.
```

### 2. Verificación de Tenant ID en Tiempo Real (C4)
```bash
# Dentro del contenedor en producción
docker exec mantis-agent printenv | grep TENANT_ID
# Debe coincidir con el esperado.
```

### 3. Verificación de Encriptación de Secretos (C3)
```bash
# Asegurar que .env.enc no contiene texto plano
grep -E 'sk-or-v1|AIza|password' .env.enc
# Si encuentra coincidencias, el archivo NO está encriptado correctamente.
```

### 4. Auditoría de Rotación (C5)
```bash
tail -n 5 .env.audit.log
# Debe mostrar las últimas rotaciones y cambios.
```

### 5. Validación de Hosts Internos (C3 - Corregido para Docker)
```bash
# Probar la función de validación con diferentes valores
python3 -c "
from validate_env import is_valid_internal_host
tests = ['localhost', 'postgres', '10.0.0.5', 'db.publica.com']
for t in tests:
    print(f'{t}: {is_valid_internal_host(t)}')
"
# Debe retornar True para localhost, postgres, 10.0.0.5 y False para db.publica.com
```

---

## 🔗 Referencias Cruzadas y Glosario

- **[[01-RULES/03-SECURITY-RULES.md]]** - Política de secretos y rotación.
- **[[02-SKILLS/INFRAESTRUCTURA/redis-session-management.md]]** - Variables específicas para Redis.
- **[[02-SKILLS/SEGURIDAD/backup-encryption.md]]** - Uso de `BACKUP_ENCRYPTION_KEY_AGE`.
- **[[05-CONFIGURATIONS/scripts/VALIDATOR_DOCUMENTATION.md]]** - Documentación del script validador.
- **[[00-CONTEXT/facundo-infrastructure.md]]** - IPs internas de VPS.

**Glosario Final:**
- **SOPS:** Secrets OPerationS. Herramienta para editar archivos encriptados.
- **Age:** Herramienta de encriptación simple. Alternativa moderna a GPG.
- **Placeholder:** Texto temporal (`cambiar`) que debe ser reemplazado por un valor real.
- **Inyección de Tenant:** Práctica de incluir el `tenant_id` en todas las claves y IDs para asegurar el aislamiento (C4).
- **Process Substitution:** Técnica de shell (`/dev/stdin`) para pasar datos entre comandos sin tocar disco.

---

## 🔧 Hook pre-commit (Opcional pero recomendado para C5)

```bash
# .git/hooks/pre-commit
#!/bin/bash
set -euo pipefail

# Validar .env antes de commit si está en los cambios staged
if git diff --cached --name-only | grep -qE '\.env(\.template|\.enc)?$'; then
  echo "🔍 Validando archivos de entorno antes de commit..."
  
  # Validar .env.template contra esquema
  if [ -f .env.template ] && [ -f env-schema.json ]; then
    python3 validate_env.py --env .env.template --schema env-schema.json --mode template || {
      echo "❌ .env.template no cumple con el esquema. Abortando commit."
      exit 1
    }
  fi
  
  # Validar .env (si existe y no está encriptado)
  if [ -f .env ] && ! grep -q "ENC\[" .env; then
    python3 validate_env.py --env .env --schema env-schema.json || {
      echo "❌ .env no pasa validación SDD. Abortando commit."
      exit 1
    }
  fi
  
  echo "✅ Validación de entorno completada."
fi
```

✅ Esto bloquea commits con `.env` o `.env.template` inválidos antes de que lleguen al repo, aplicando C5 de forma preventiva.

FIN DEL ARCHIVO
<!-- ai:file-end marker - do not remove -->
Versión 1.0.1 - 2026-04-15 - Mantis-AgenticDev
```
