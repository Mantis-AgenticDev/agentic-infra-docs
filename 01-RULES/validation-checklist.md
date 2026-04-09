---
title: "Checklist de Validación SDD para MANTIS AGENTIC"
version: "3.0.0"
last_updated: "2026-04-09"
status: "production"
category: "validation"
validation_status: "passed"
auto_validate: true
spec_version: "SDD v1.0"
tenant_id_enforcement: "obligatorio"
constraints_applied: ["C1", "C2", "C3", "C4", "C5", "C6"]
description: >
  Checklist de validación manual y automatizada para componentes de infraestructura agéntica.
  Versión ampliada con 4 ejemplos por área, secciones de API y monitorización de VPS.
  Diseñado para estudiantes de sistemas con explicaciones detalladas (nivel avanzado).
related_docs:
  - "01-RULES/01-ARCHITECTURE-RULES.md"
  - "01-RULES/02-RESOURCE-GUARDRAILS.md"
  - "01-RULES/03-SECURITY-RULES.md"
  - "01-RULES/04-API-RELIABILITY-RULES.md"
  - "01-RULES/06-MULTITENANCY-RULES.md"
  - "05-CONFIGURATIONS/scripts/validate-against-specs.sh"
---

# Checklist de Validación SDD – MANTIS AGENTIC v3.0

Este documento proporciona una guía exhaustiva para verificar que cualquier componente (Docker, n8n, SQL, Qdrant, EspoCRM, Supabase, RAG, APIs, y monitorización) cumple con los constraints y reglas definidas en la metodología SDD del proyecto.

**Instrucciones de uso:**
- Marque `[x]` cuando el ítem haya sido verificado.
- Los ejemplos están diseñados para ejecutarse en un entorno Ubuntu 22.04+ con las herramientas estándar instaladas.
- Todos los checks referencian una regla específica (`REF:`) y los constraints aplicables (`C1-C6`).
- **Nivel de explicación:** Avanzado - incluye QUÉ es cada validación, POR QUÉ es importante, y ALTERNATIVAS cuando aplica.

---

## 📚 Glosario para Estudiantes

Antes de comenzar, es importante entender estos conceptos clave:

- **Constraint (C1-C6):** Restricción técnica no negociable del proyecto. Son límites absolutos de hardware, seguridad y arquitectura.
- **tenant_id:** Identificador único de cliente que permite que múltiples negocios usen la misma infraestructura sin mezclar sus datos.
- **Multi-tenancy:** Arquitectura donde varios clientes (tenants) comparten la misma aplicación pero sus datos están completamente aislados.
- **SDD (Specification-Driven Development):** Metodología donde primero defines reglas claras y luego validas que el código las cumple.
- **VPS (Virtual Private Server):** Servidor virtual con recursos dedicados (RAM, CPU, disco).

---

## 1. Validación de Docker y Contenedores

**¿Qué validamos aquí?** Los contenedores Docker son como "cajas" donde corren nuestras aplicaciones. Debemos garantizar que cada caja no consuma más recursos de los permitidos y que estén configuradas de forma segura.

**¿Por qué es importante?** Si un contenedor consume toda la RAM o CPU, puede hacer que el servidor entero colapse, afectando a todos los clientes.

### 1.1 Límites de Memoria y CPU (Constraints C1, C2)

**Objetivo:** Garantizar que ningún contenedor exceda 4 GB de RAM ni consuma más de 1 vCPU completa de manera no controlada.

| ID | Check | Comando / Ejemplo de Verificación | REF |
|:---|:------|:----------------------------------|:----|
| DOCK-01 | `[ ]` Todos los contenedores de servicios principales (n8n, mysql, qdrant) tienen límite de memoria definido. | **Comando de verificación:** <br/> `docker inspect <container> --format='{{.HostConfig.Memory}}'` <br/><br/> **Valor esperado:** ≤ `4294967296` bytes (4 GB). <br/><br/> **Ejemplo docker-compose.yml:** <br/> ```yaml<br/>services:<br/>  n8n:<br/>    deploy:<br/>      resources:<br/>        limits:<br/>          memory: 1500M<br/>``` <br/><br/> **¿Por qué?** Sin límites, un contenedor podría consumir toda la RAM del servidor. <br/><br/> **Alternativa:** Usar `--memory="1500m"` en `docker run` si no usas docker-compose. | ARQ-001, RES-001 |
| DOCK-02 | `[ ]` Los contenedores de servicios principales tienen límite de CPU definido. | **Comando de verificación:** <br/> `docker inspect <container> --format='{{.HostConfig.NanoCpus}}'` <br/><br/> **Valor esperado:** ≤ `1000000000` nanocpus (1 vCPU). <br/><br/> **Ejemplo docker-compose.yml:** <br/> ```yaml<br/>deploy:<br/>  resources:<br/>    limits:<br/>      cpus: "1.0"<br/>``` <br/><br/> **¿Por qué?** Limitar CPU evita que un proceso acapare todo el procesador y afecte otros servicios. <br/><br/> **Alternativa:** `--cpus="0.5"` para límites menores. | ARQ-002, RES-002 |
| DOCK-03 | `[ ]` Verificar consumo actual de recursos en tiempo real. | **Comando de verificación:** <br/> `docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"` <br/><br/> **Ejemplo de salida esperada:** <br/> ```<br/>NAME        CPU %     MEM USAGE<br/>n8n-main    15.3%     1.2GiB / 1.5GiB<br/>mysql       5.2%      800MiB / 2GiB<br/>``` <br/><br/> **¿Por qué?** Permite ver el consumo real vs. los límites configurados. <br/><br/> **Alternativa:** Usar `ctop` (herramienta visual) para monitoreo interactivo. | RES-001 |
| DOCK-04 | `[ ]` Validar que los límites persistan después de reiniciar contenedores. | **Comando de verificación:** <br/> ```bash<br/>docker restart <container><br/>sleep 5<br/>docker inspect <container> --format='Memory: {{.HostConfig.Memory}} | CPUs: {{.HostConfig.NanoCpus}}'<br/>``` <br/><br/> **¿Por qué?** Asegura que los límites estén en el archivo de configuración y no sean temporales. <br/><br/> **Alternativa:** Revisar directamente el `docker-compose.yml` o el comando `docker run` original. | ARQ-001 |

### 1.2 Exposición de Puertos Sensibles (Constraint C3)

**Objetivo:** Evitar que bases de datos o Qdrant sean accesibles desde la red pública (Internet).

**¿Por qué es crítico?** Exponer MySQL o Qdrant al público permite ataques de fuerza bruta, inyección SQL o robo de datos vectoriales.

| ID | Check | Comando / Ejemplo de Verificación | REF |
|:---|:------|:----------------------------------|:----|
| DOCK-05 | `[ ]` El puerto 3306 (MySQL) NO está expuesto a `0.0.0.0` o `::`. | **Comando de verificación:** <br/> `docker ps --format "table {{.Names}}\t{{.Ports}}" | grep 3306` <br/><br/> **✅ Permitido (bind a localhost):** <br/> `127.0.0.1:3306->3306/tcp` <br/><br/> **❌ Prohibido (bind a todas las interfaces):** <br/> `0.0.0.0:3306->3306/tcp` <br/><br/> **Ejemplo docker-compose seguro:** <br/> ```yaml<br/>ports:<br/>  - "127.0.0.1:3306:3306"<br/>``` <br/><br/> **¿Por qué?** `0.0.0.0` significa "accesible desde cualquier IP", incluyendo atacantes externos. <br/><br/> **Alternativa:** No exponer el puerto y usar redes internas de Docker (`networks`). | SEG-005 |
| DOCK-06 | `[ ]` El puerto 6333 (Qdrant HTTP) NO está expuesto a `0.0.0.0` o `::`. | **Comando de verificación:** <br/> `docker ps --format "table {{.Names}}\t{{.Ports}}" | grep 6333` <br/><br/> **✅ Permitido:** `127.0.0.1:6333->6333/tcp` <br/><br/> **✅ Mejor alternativa:** No exponer el puerto (comunicación solo dentro de Docker). <br/><br/> **Ejemplo de red interna Docker:** <br/> ```yaml<br/>services:<br/>  qdrant:<br/>    networks:<br/>      - internal<br/>networks:<br/>  internal:<br/>    internal: true<br/>``` <br/><br/> **¿Por qué?** Las redes internas de Docker bloquean completamente el acceso externo. | SEG-005 |
| DOCK-07 | `[ ]` Verificar que UFW (firewall) esté bloqueando puertos sensibles. | **Comando de verificación:** <br/> `sudo ufw status numbered | grep -E "3306|6333|5432"` <br/><br/> **Ejemplo de salida segura:** <br/> ```<br/>[1] 3306                   DENY IN     Anywhere<br/>[2] 6333                   DENY IN     Anywhere<br/>``` <br/><br/> **¿Por qué?** Incluso si Docker está bien configurado, UFW añade una capa extra de seguridad a nivel de sistema operativo. <br/><br/> **Alternativa:** `iptables -L -n | grep -E "3306|6333"` si no usas UFW. | SEG-001 |
| DOCK-08 | `[ ]` Escanear puertos abiertos desde una máquina externa. | **Comando de verificación (desde otra máquina):** <br/> `nmap -p 3306,6333,5432 <IP_DEL_SERVIDOR>` <br/><br/> **Ejemplo de salida segura:** <br/> ```<br/>PORT     STATE    SERVICE<br/>3306/tcp filtered mysql<br/>6333/tcp filtered qdrant<br/>``` <br/><br/> **¿Por qué?** Simula un ataque real para verificar que los puertos estén realmente bloqueados. <br/><br/> **Alternativa:** Usar `nmap -sS` (SYN scan) para escaneo más sigiloso. | SEG-005 |

### 1.3 Imágenes Prohibidas (Constraint C6)

**Objetivo:** Bloquear el despliegue de modelos de IA locales no autorizados como Ollama o LocalAI.

**¿Por qué?** Los modelos locales consumen mucha RAM/CPU y podrían violar límites de recursos. Además, no están auditados para multi-tenancy.

| ID | Check | Comando / Ejemplo de Verificación | REF |
|:---|:------|:----------------------------------|:----|
| DOCK-09 | `[ ]` No existe ninguna imagen de `ollama/ollama` en el sistema. | **Comando de verificación:** <br/> `docker image ls | grep -i ollama` <br/><br/> **Resultado esperado:** Sin salida (vacío). <br/><br/> **¿Por qué?** Ollama corre modelos LLM localmente, violando C6. <br/><br/> **Alternativa para auditoría completa:** <br/> `docker image ls --format "{{.Repository}}:{{.Tag}}" | grep -iE "ollama|localai|text-generation-webui"` | SEG-012 |
| DOCK-10 | `[ ]` No hay contenedores ejecutándose con nombres que contengan `localai` o `text-generation-webui`. | **Comando de verificación:** <br/> `docker ps --format "table {{.Names}}\t{{.Image}}" | grep -iE "localai|text-generation"` <br/><br/> **Resultado esperado:** Vacío. <br/><br/> **¿Por qué?** Estas son plataformas comunes para ejecutar LLMs locales. <br/><br/> **Alternativa:** `docker ps -a` para incluir contenedores detenidos. | SEG-012 |
| DOCK-11 | `[ ]` Verificar que docker-compose.yml no contenga referencias a modelos locales. | **Comando de verificación:** <br/> `grep -iE "ollama|localai|llama\.cpp|oobabooga" docker-compose.yml` <br/><br/> **Resultado esperado:** Sin coincidencias. <br/><br/> **¿Por qué?** Previene que alguien agregue estos servicios en el futuro. <br/><br/> **Alternativa:** Usar un pre-commit hook con este grep para validación automática. | SEG-012 |
| DOCK-12 | `[ ]` Auditar volúmenes de Docker para detectar modelos descargados. | **Comando de verificación:** <br/> ```bash<br/>docker volume ls --format "{{.Name}}"<br/>for vol in $(docker volume ls -q); do<br/>  docker run --rm -v $vol:/data alpine find /data -name "*.gguf" -o -name "*.bin" 2>/dev/null<br/>done<br/>``` <br/><br/> **¿Por qué?** Los modelos locales se guardan como archivos `.gguf` o `.bin`. <br/><br/> **Alternativa:** Usar `du -sh /var/lib/docker/volumes/*/` para detectar volúmenes grandes sospechosos. | SEG-012 |

### 1.4 Logs y Persistencia

**Objetivo:** Garantizar que los logs estén centralizados y los datos críticos persistan correctamente.

| ID | Check | Comando / Ejemplo de Verificación | REF |
|:---|:------|:----------------------------------|:----|
| DOCK-13 | `[ ]` Los logs de contenedores están rotando correctamente (max 10MB por archivo). | **Comando de verificación:** <br/> `docker inspect <container> --format='{{.HostConfig.LogConfig}}'` <br/><br/> **Configuración esperada en docker-compose:** <br/> ```yaml<br/>logging:<br/>  driver: "json-file"<br/>  options:<br/>    max-size: "10m"<br/>    max-file: "3"<br/>``` <br/><br/> **¿Por qué?** Sin rotación, los logs pueden llenar el disco. <br/><br/> **Alternativa:** Usar `syslog` o `journald` para logs centralizados. | RES-010 |
| DOCK-14 | `[ ]` Los volúmenes de datos críticos están montados correctamente. | **Comando de verificación:** <br/> `docker volume ls` <br/> `docker volume inspect mysql_data` <br/><br/> **Ejemplo de salida esperada:** <br/> ```json<br/>{<br/>  "Mountpoint": "/var/lib/docker/volumes/mysql_data/_data",<br/>  "Driver": "local"<br/>}<br/>``` <br/><br/> **¿Por qué?** Si los datos están en el contenedor, se pierden al eliminarlo. <br/><br/> **Alternativa:** Usar bind mounts (`./mysql:/var/lib/mysql`) para mayor control. | ARQ-003 |
| DOCK-15 | `[ ]` Verificar que los backups de volúmenes se estén realizando. | **Comando de verificación:** <br/> ```bash<br/>tar -czf mysql_backup_$(date +%Y%m%d).tar.gz -C /var/lib/docker/volumes/mysql_data/_data .<br/>ls -lh mysql_backup_*.tar.gz<br/>``` <br/><br/> **¿Por qué?** Los volúmenes deben respaldarse regularmente según C5. <br/><br/> **Alternativa:** Usar herramientas como `duplicity` para backups encriptados automáticos. | SEG-009 |
| DOCK-16 | `[ ]` Comprobar que los health checks estén funcionando. | **Comando de verificación:** <br/> `docker ps --format "table {{.Names}}\t{{.Status}}"` <br/><br/> **Ejemplo de configuración en docker-compose:** <br/> ```yaml<br/>healthcheck:<br/>  test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]<br/>  interval: 30s<br/>  timeout: 10s<br/>  retries: 3<br/>``` <br/><br/> **¿Por qué?** Los health checks permiten detectar contenedores que "parecen" correr pero están fallando. <br/><br/> **Alternativa:** Usar `docker inspect <container> | jq '.[].State.Health'`. | RES-011 |

---

## 2. Validación de Workflows n8n

**¿Qué validamos aquí?** Los workflows de n8n son flujos de trabajo automatizados que conectan diferentes servicios. Debemos asegurar que sean eficientes, seguros y respeten el multi-tenancy.

**¿Por qué es importante?** Un workflow mal configurado puede exponer datos de un cliente a otro o consumir recursos excesivos.

### 2.1 Estructura JSON y Metadatos SDD

| ID | Check | Ejemplo de Verificación (Inspección de archivo `.json`) | REF |
|:---|:------|:-------------------------------------------------------|:----|
| N8N-01 | `[ ]` El archivo JSON contiene el campo `meta.sdd_version`. | **Comando de verificación:** <br/> `jq '.meta.sdd_version' workflow.json` <br/><br/> **Valor esperado:** `"1.0"` o superior. <br/><br/> **¿Por qué?** Permite rastrear qué versión de las reglas SDD se usó al crear el workflow. <br/><br/> **Alternativa:** Usar `grep -o '"sdd_version":"[^"]*"' workflow.json` si no tienes jq. | SDD-01 |
| N8N-02 | `[ ]` El campo `meta.validation_status` está presente y es `"passed"`. | **Comando de verificación:** <br/> `jq '.meta.validation_status' workflow.json` <br/><br/> **¿Por qué?** Indica que el workflow fue validado antes de desplegarse. <br/><br/> **Alternativa:** Crear un script que valide y actualice este campo automáticamente. | SDD-01 |
| N8N-03 | `[ ]` El workflow tiene documentación en el campo `meta.description`. | **Comando de verificación:** <br/> `jq '.meta.description' workflow.json` <br/><br/> **Ejemplo esperado:** <br/> `"Workflow para procesar mensajes de WhatsApp con RAG multi-tenant"` <br/><br/> **¿Por qué?** Facilita que otros desarrolladores entiendan el propósito del workflow. <br/><br/> **Alternativa:** Agregar comentarios en los nodos críticos del workflow. | SDD-02 |
| N8N-04 | `[ ]` Verificar que no haya nodos duplicados innecesarios. | **Comando de verificación:** <br/> ```bash<br/>jq '.nodes[] | "\(.type)|\(.name)"' workflow.json | sort | uniq -c | sort -rn<br/>``` <br/><br/> **¿Por qué?** Nodos duplicados aumentan complejidad y consumo de recursos. <br/><br/> **Alternativa:** Usar el editor visual de n8n para revisar el flujo. | RES-007 |

### 2.2 Nodos HTTP y Timeouts (API Reliability)

| ID | Check | Ejemplo de Verificación | REF |
|:---|:------|:------------------------|:----|
| N8N-05 | `[ ]` Todos los nodos `HTTP Request` tienen un timeout explícito ≤ 30000 ms. | **Comando de verificación:** <br/> `jq '.nodes[] | select(.type == "n8n-nodes-base.httpRequest") | {name: .name, timeout: .parameters.options.timeout}' workflow.json` <br/><br/> **Valor esperado:** `30000` (30 segundos) o menor. <br/><br/> **¿Por qué?** Sin timeout, una API lenta puede bloquear el workflow indefinidamente. <br/><br/> **Alternativa:** Configurar timeouts globales en n8n vía variables de entorno. | API-001 |
| N8N-06 | `[ ]` Los nodos `HTTP Request` hacia APIs externas incluyen manejo de errores con `Continue on Fail` o un nodo `Error Trigger`. | **Comando de verificación:** <br/> `jq '.nodes[] | select(.type == "n8n-nodes-base.httpRequest") | {name: .name, continueOnFail: .continueOnFail}' workflow.json` <br/><br/> **Valor esperado:** `true` <br/><br/> **¿Por qué?** Si una API externa falla, el workflow debe continuar o manejarlo gracefully. <br/><br/> **Alternativa:** Conectar un nodo `Error Trigger` para logging centralizado. | API-002 |
| N8N-07 | `[ ]` Verificar que las llamadas HTTP incluyan retry con backoff exponencial. | **Comando de verificación:** <br/> `jq '.nodes[] | select(.type == "n8n-nodes-base.httpRequest") | .parameters.options.retry' workflow.json` <br/><br/> **Configuración esperada:** <br/> ```json<br/>{<br/>  "retry": {<br/>    "maxRetries": 3,<br/>    "waitBetweenRetries": 1000<br/>  }<br/>}<br/>``` <br/><br/> **¿Por qué?** Las APIs externas pueden tener fallos temporales (rate limits, timeouts momentáneos). <br/><br/> **Alternativa:** Implementar retry custom con nodo `Code`. | API-003 |
| N8N-08 | `[ ]` Validar que las URLs de API estén parametrizadas (no hardcodeadas). | **Comando de verificación:** <br/> `jq '.nodes[] | select(.type == "n8n-nodes-base.httpRequest") | .parameters.url' workflow.json | grep -v "{{"` <br/><br/> **Resultado esperado:** Vacío (todas las URLs deben usar variables como `{{ $env.API_BASE_URL }}`). <br/><br/> **¿Por qué?** URLs hardcodeadas dificultan migración entre entornos (dev/staging/prod). <br/><br/> **Alternativa:** Usar nodo `Set` inicial con todas las configuraciones de ambiente. | PAT-001 |

### 2.3 Aislamiento Multi-tenant (Constraint C4)

| ID | Check | Ejemplo de Verificación | REF |
|:---|:------|:------------------------|:----|
| N8N-09 | `[ ]` Todos los nodos que consultan Qdrant incluyen un filtro obligatorio por `tenant_id`. | **Comando de verificación:** <br/> `jq '.nodes[] | select(.type | contains("Qdrant")) | .parameters.filter' workflow.json` <br/><br/> **Debe contener:** <br/> ```json<br/>{"must":[{"key":"tenant_id","match":{"keyword":"={{ $json.tenant_id }}"}}]}<br/>``` <br/><br/> **¿Por qué?** Sin este filtro, un cliente podría ver datos de otro cliente en búsquedas RAG. <br/><br/> **Alternativa:** Crear un nodo template "Qdrant Seguro" pre-configurado con el filtro. | MT-004 |
| N8N-10 | `[ ]` Los nodos que ejecutan queries SQL utilizan parámetros de consulta (`queryParams`) en lugar de concatenación de strings. | **Comando de verificación:** <br/> `jq '.nodes[] | select(.type == "n8n-nodes-base.mySql") | .parameters.query' workflow.json` <br/><br/> **✅ Correcto:** <br/> `"SELECT * FROM users WHERE tenant_id = :tenant_id"` <br/><br/> **❌ Incorrecto (SQL injection vulnerable):** <br/> `"SELECT * FROM users WHERE tenant_id = '" + $json.tenant_id + "'"` <br/><br/> **¿Por qué?** La concatenación permite ataques de SQL injection. <br/><br/> **Alternativa:** Usar ORMs que manejan esto automáticamente. | PAT-002 |
| N8N-11 | `[ ]` Verificar que tenant_id esté presente en TODOS los payloads de salida. | **Comando de verificación:** <br/> ```bash<br/>jq '.nodes[] | select(.type | contains("Set") or contains("Function")) | .parameters' workflow.json | grep -o "tenant_id"<br/>``` <br/><br/> **¿Por qué?** Cada dato que pasa por el workflow debe llevar su tenant_id para trazabilidad. <br/><br/> **Alternativa:** Usar un nodo "Validator" al inicio que verifique presencia de tenant_id. | MT-001 |
| N8N-12 | `[ ]` Auditar que no existan referencias cruzadas entre tenants en logs. | **Comando de verificación:** <br/> ```bash<br/># Revisar logs de ejecución<br/>grep -E "tenant_id.*tenant_id" /var/lib/docker/volumes/n8n_data/_data/logs/*.log<br/>``` <br/><br/> **Resultado esperado:** Solo un tenant_id por línea de log. <br/><br/> **¿Por qué?** Detecta bugs donde se mezclan datos de distintos tenants. <br/><br/> **Alternativa:** Implementar structured logging con campos separados. | MT-002 |

### 2.4 Performance y Optimización

| ID | Check | Ejemplo de Verificación | REF |
|:---|:------|:------------------------|:----|
| N8N-13 | `[ ]` Los nodos de código (Function/Code) no ejecutan loops largos sin paginación. | **Revisión manual:** Buscar `for` loops que procesen >100 items sin `slice()`. <br/><br/> **Ejemplo problemático:** <br/> ```javascript<br/>for (let i=0; i<items.length; i++) {<br/>  // procesamiento pesado<br/>}<br/>``` <br/><br/> **Ejemplo correcto:** <br/> ```javascript<br/>const batchSize = 50;<br/>for (let i=0; i<items.length; i+=batchSize) {<br/>  const batch = items.slice(i, i+batchSize);<br/>}<br/>``` <br/><br/> **¿Por qué?** Procesar miles de items de golpe puede agotar la RAM del contenedor. <br/><br/> **Alternativa:** Usar nodos `Split In Batches`. | RES-003 |
| N8N-14 | `[ ]` Verificar que no haya llamadas síncronas innecesarias (usar async/await). | **Revisión en nodos Code:** <br/> ```javascript<br/>// ❌ Incorrecto (bloquea el event loop)<br/>const result = heavyOperation();<br/><br/>// ✅ Correcto<br/>const result = await heavyOperationAsync();<br/>``` <br/><br/> **¿Por qué?** Node.js es single-threaded; operaciones síncronas bloquean todo. <br/><br/> **Alternativa:** Usar workers threads para operaciones CPU-intensive. | RES-004 |
| N8N-15 | `[ ]` Auditar que las credenciales estén en variables de entorno, no hardcodeadas. | **Comando de verificación:** <br/> `jq -r '.nodes[].credentials' workflow.json | grep -v "null"` <br/><br/> **¿Por qué?** Las credenciales hardcodeadas son un riesgo de seguridad. <br/><br/> **Alternativa:** Usar el sistema de credentials de n8n o variables de entorno. | SEG-002 |
| N8N-16 | `[ ]` Comprobar que los workflows tengan activación condicional (no siempre activos). | **Comando de verificación:** <br/> `jq '.active' workflow.json` <br/><br/> **¿Por qué?** Workflows siempre activos consumen recursos aunque no se usen. <br/><br/> **Alternativa:** Usar webhooks con validación de firma para activación bajo demanda. | RES-006 |

---

## 3. Validación de SQL (MySQL / PostgreSQL / Supabase)

**¿Qué validamos aquí?** Las consultas SQL son el corazón del aislamiento de datos. Cada query debe respetar tenant_id y usar buenas prácticas de seguridad.

**¿Por qué es importante?** Una sola query sin tenant_id puede exponer datos de todos los clientes.

### 3.1 Multi-tenencia en Queries (Constraint C4)

| ID | Check | Ejemplo de Verificación (Auditoría de código o logs) | REF |
|:---|:------|:-----------------------------------------------------|:----|
| SQL-01 | `[ ]` Toda sentencia `SELECT`, `UPDATE`, `DELETE` incluye una cláusula `WHERE tenant_id = ?`. | **✅ Correcto:** <br/> `SELECT * FROM interactions WHERE tenant_id = ? AND chat_id = ?;` <br/><br/> **❌ Incorrecto:** <br/> `SELECT * FROM interactions WHERE chat_id = 'user123';` <br/><br/> **Comando de auditoría:** <br/> `grep -n "SELECT.*FROM" *.sql | grep -v "WHERE.*tenant_id"` <br/><br/> **¿Por qué?** Omitir tenant_id permite ver datos de otros clientes. <br/><br/> **Alternativa:** Usar Views que incluyan automáticamente el filtro de tenant_id. | MT-001 |
| SQL-02 | `[ ]` No se utiliza `SELECT *` sin un límite explícito (`LIMIT`) o sin un filtro de tenant_id altamente selectivo. | **Ejemplo de verificación:** <br/> `grep -n "SELECT \* FROM" queries.sql` debe ir acompañado de `WHERE tenant_id` y un `LIMIT` razonable. <br/><br/> **✅ Correcto:** <br/> `SELECT * FROM messages WHERE tenant_id = ? LIMIT 100;` <br/><br/> **❌ Incorrecto:** <br/> `SELECT * FROM messages;` <br/><br/> **¿Por qué?** `SELECT *` sin límites puede devolver millones de filas y agotar memoria. <br/><br/> **Alternativa:** Especificar solo columnas necesarias: `SELECT id, content, created_at FROM...`. | PAT-004 |
| SQL-03 | `[ ]` Verificar que los índices incluyan tenant_id como primera columna. | **Comando de verificación:** <br/> ```sql<br/>SHOW INDEX FROM interactions WHERE Column_name = 'tenant_id';<br/>``` <br/><br/> **Ejemplo de índice correcto:** <br/> `CREATE INDEX idx_tenant_chat ON interactions(tenant_id, chat_id);` <br/><br/> **¿Por qué?** Índices sin tenant_id hacen que las queries sean lentas en tablas grandes. <br/><br/> **Alternativa:** Usar índices compuestos comenzando con tenant_id. | RES-005 |
| SQL-04 | `[ ]` Auditar que no existan foreign keys que crucen tenants. | **Comando de verificación:** <br/> ```sql<br/>SELECT <br/>  TABLE_NAME, CONSTRAINT_NAME, REFERENCED_TABLE_NAME<br/>FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE<br/>WHERE REFERENCED_TABLE_NAME IS NOT NULL;<br/>``` <br/><br/> **Revisión manual:** Cada FK debe validar tenant_id en ambas tablas. <br/><br/> **¿Por qué?** Un FK sin validación de tenant puede crear relaciones entre datos de distintos clientes. <br/><br/> **Alternativa:** Usar triggers que validen tenant_id antes de INSERTs/UPDATEs. | MT-003 |

### 3.2 Conexiones Seguras

| ID | Check | Comando / Ejemplo de Verificación | REF |
|:---|:------|:----------------------------------|:----|
| SQL-05 | `[ ]` El usuario de aplicación no es `root` ni tiene privilegios `GRANT ALL`. | **Comando de verificación:** <br/> `mysql -e "SHOW GRANTS FOR 'app_user'@'%';"` <br/><br/> **Privilegios esperados:** Solo `SELECT, INSERT, UPDATE, DELETE` sobre la base de datos específica. <br/><br/> **Ejemplo de creación segura de usuario:** <br/> ```sql<br/>CREATE USER 'app_user'@'%' IDENTIFIED BY 'strong_password';<br/>GRANT SELECT, INSERT, UPDATE, DELETE ON mantis_db.* TO 'app_user'@'%';<br/>``` <br/><br/> **¿Por qué?** Un usuario con privilegios de admin puede modificar la estructura de la BD o ver otros schemas. <br/><br/> **Alternativa:** Usar usuarios diferentes para lectura vs. escritura (read replica pattern). | SEG-003 |
| SQL-06 | `[ ]` La conexión desde la aplicación utiliza SSL/TLS (`ssl-mode=REQUIRED`). | **Revisar string de conexión:** <br/> `mysql://user:pass@host/db?ssl-mode=REQUIRED` <br/><br/> **Comando de verificación desde MySQL:** <br/> ```sql<br/>SHOW VARIABLES LIKE 'have_ssl';<br/>``` <br/><br/> **Valor esperado:** `YES` <br/><br/> **¿Por qué?** Sin SSL, las credenciales y datos viajan en texto plano por la red. <br/><br/> **Alternativa:** Configurar certificados mutuos (mTLS) para máxima seguridad. | SEG-004 |
| SQL-07 | `[ ]` Verificar que las contraseñas de BD no estén en código fuente. | **Comando de auditoría:** <br/> ```bash<br/>grep -rn "mysql://.*:.*@" *.js *.py *.json<br/>``` <br/><br/> **Resultado esperado:** Vacío (usar variables de entorno). <br/><br/> **Ejemplo seguro:** <br/> ```javascript<br/>const dbUrl = process.env.DATABASE_URL;<br/>``` <br/><br/> **¿Por qué?** Las credenciales en código pueden filtrarse en commits de git. <br/><br/> **Alternativa:** Usar secretos manejados por Docker Swarm, Kubernetes, o HashiCorp Vault. | SEG-002 |
| SQL-08 | `[ ]` Comprobar que la BD tenga configurado max_connections adecuado. | **Comando de verificación:** <br/> ```sql<br/>SHOW VARIABLES LIKE 'max_connections';<br/>``` <br/><br/> **Valor recomendado:** 50-100 para VPS de 4GB RAM. <br/><br/> **Cálculo:** `max_connections = (RAM disponible para MySQL) / (RAM por conexión)` <br/><br/> **¿Por qué?** Demasiadas conexiones pueden agotar la RAM. <br/><br/> **Alternativa:** Usar connection pooling en la aplicación para reusar conexiones. | RES-001 |

### 3.3 Prepared Statements y Seguridad

| ID | Check | Comando / Ejemplo de Verificación | REF |
|:---|:------|:----------------------------------|:----|
| SQL-09 | `[ ]` Todas las queries usan prepared statements (parámetros), no concatenación. | **❌ Vulnerable a SQL Injection:** <br/> ```javascript<br/>const query = `SELECT * FROM users WHERE email = '${userInput}'`;<br/>``` <br/><br/> **✅ Seguro:** <br/> ```javascript<br/>const query = 'SELECT * FROM users WHERE email = ?';<br/>db.query(query, [userInput]);<br/>``` <br/><br/> **¿Por qué?** Concatenación permite inyección de código SQL malicioso. <br/><br/> **Alternativa:** Usar ORMs como Sequelize, TypeORM, o Prisma que manejan esto automáticamente. | PAT-002 |
| SQL-10 | `[ ]` Verificar que no existan queries dinámicas inseguras. | **Comando de auditoría:** <br/> ```bash<br/>grep -rn "query.*+.*\$\|query.*\`\${" *.js<br/>``` <br/><br/> **¿Por qué?** Template literals con interpolación directa son peligrosos. <br/><br/> **Alternativa:** Usar query builders como Knex.js. | SEG-006 |
| SQL-11 | `[ ]` Auditar que las migraciones de BD incluyan validación de tenant_id. | **Ejemplo de migración segura:** <br/> ```sql<br/>ALTER TABLE messages ADD CONSTRAINT fk_tenant <br/>  FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;<br/>``` <br/><br/> **¿Por qué?** Las constraints a nivel de BD son la última línea de defensa. <br/><br/> **Alternativa:** Usar triggers para validaciones complejas. | MT-002 |
| SQL-12 | `[ ]` Comprobar que los logs de BD no expongan datos sensibles. | **Comando de verificación:** <br/> ```bash<br/>tail -100 /var/log/mysql/error.log | grep -i "password\|token\|secret"<br/>``` <br/><br/> **Resultado esperado:** Vacío. <br/><br/> **¿Por qué?** Los logs pueden contener queries completas con credenciales. <br/><br/> **Alternativa:** Configurar `log_error_verbosity=2` en MySQL para logs menos detallados. | SEG-008 |

### 3.4 Performance de Queries

| ID | Check | Comando / Ejemplo de Verificación | REF |
|:---|:------|:----------------------------------|:----|
| SQL-13 | `[ ]` Usar EXPLAIN para identificar queries lentas. | **Comando de verificación:** <br/> ```sql<br/>EXPLAIN SELECT * FROM messages WHERE tenant_id = 'abc' AND created_at > NOW() - INTERVAL 7 DAY;<br/>``` <br/><br/> **Buscar en output:** `type` debe ser `ref` o `range`, no `ALL` (full table scan). <br/><br/> **¿Por qué?** Full table scans son extremadamente lentos en tablas grandes. <br/><br/> **Alternativa:** Usar `EXPLAIN ANALYZE` para métricas más detalladas. | RES-005 |
| SQL-14 | `[ ]` Verificar que las queries críticas tengan índices adecuados. | **Comando de verificación:** <br/> ```sql<br/>SHOW INDEX FROM messages;<br/>``` <br/><br/> **Índices recomendados:** <br/> - `(tenant_id, created_at)` para queries temporales <br/> - `(tenant_id, chat_id)` para búsquedas por chat <br/><br/> **¿Por qué?** Sin índices, cada query escanea toda la tabla. <br/><br/> **Alternativa:** Usar herramientas como `pt-query-digest` para analizar slow queries. | RES-005 |
| SQL-15 | `[ ]` Auditar que no existan N+1 queries en el código de aplicación. | **Ejemplo de N+1 problem:** <br/> ```javascript<br/>// ❌ Hace 1 + N queries<br/>const users = await db.query('SELECT * FROM users WHERE tenant_id = ?', [tid]);<br/>for (let user of users) {<br/>  user.messages = await db.query('SELECT * FROM messages WHERE user_id = ?', [user.id]);<br/>}<br/>``` <br/><br/> **✅ Solución con JOIN:** <br/> ```sql<br/>SELECT u.*, m.* FROM users u <br/>LEFT JOIN messages m ON u.id = m.user_id <br/>WHERE u.tenant_id = ?;<br/>``` <br/><br/> **¿Por qué?** N+1 queries sobrecargan la BD innecesariamente. <br/><br/> **Alternativa:** Usar ORM con eager loading (ej. `User.findAll({ include: ['messages'] })`). | RES-007 |
| SQL-16 | `[ ]` Comprobar que existan índices parciales para queries frecuentes. | **Ejemplo de índice parcial:** <br/> ```sql<br/>CREATE INDEX idx_active_messages ON messages(tenant_id, created_at) <br/>WHERE deleted_at IS NULL;<br/>``` <br/><br/> **¿Por qué?** Índices parciales son más pequeños y rápidos para casos específicos. <br/><br/> **Alternativa:** Usar covering indexes que incluyan todas las columnas necesarias. | RES-005 |

---

## 4. Validación de Qdrant

**¿Qué validamos aquí?** Qdrant es la base de datos vectorial para RAG. Debemos garantizar que los vectores estén correctamente aislados por tenant y que las búsquedas sean eficientes.

**¿Por qué es importante?** Sin aislamiento, un cliente podría obtener documentos privados de otro cliente en las respuestas RAG.

### 4.1 Aislamiento de Datos Vectoriales (Constraint C4)

| ID | Check | Ejemplo de Verificación | REF |
|:---|:------|:------------------------|:----|
| QDR-01 | `[ ]` Cada punto (vector) insertado contiene un payload con el campo `tenant_id`. | **Payload de ejemplo correcto:** <br/> ```json<br/>{<br/>  "text": "Manual de producto v2.0",<br/>  "tenant_id": "restaurant_123",<br/>  "source": "docs/manual.pdf"<br/>}<br/>``` <br/><br/> **Comando de verificación:** <br/> ```bash<br/>curl -X POST http://localhost:6333/collections/mantis_docs/points/scroll \<br/>  -H 'Content-Type: application/json' \<br/>  -d '{"limit": 10}' | jq '.result.points[].payload.tenant_id'<br/>``` <br/><br/> **¿Por qué?** Sin tenant_id en el payload, no hay forma de filtrar por cliente. <br/><br/> **Alternativa:** Usar colecciones separadas por tenant (más costoso pero más seguro). | MT-004 |
| QDR-02 | `[ ]` Todas las consultas de búsqueda (`/points/search`) incluyen un filtro `must` por `tenant_id`. | **Filtro JSON requerido:** <br/> ```json<br/>{<br/>  "filter": {<br/>    "must": [<br/>      {<br/>        "key": "tenant_id",<br/>        "match": { "keyword": "restaurant_123" }<br/>      }<br/>    ]<br/>  }<br/>}<br/>``` <br/><br/> **Comando de auditoría en código:** <br/> `grep -rn "points/search" *.js | grep -v "tenant_id"` <br/><br/> **¿Por qué?** Sin filtro, la búsqueda devuelve vectores de todos los clientes. <br/><br/> **Alternativa:** Crear un wrapper/función que siempre agregue el filtro automáticamente. | MT-005 |
| QDR-03 | `[ ]` Verificar que no existan puntos sin tenant_id en colecciones productivas. | **Comando de verificación:** <br/> ```bash<br/>curl -X POST http://localhost:6333/collections/mantis_docs/points/scroll \<br/>  -H 'Content-Type: application/json' \<br/>  -d '{<br/>    "filter": {<br/>      "must_not": [<br/>        {"key": "tenant_id", "match": {"keyword": "*"}}<br/>      ]<br/>    },<br/>    "limit": 100<br/>  }' | jq '.result.points | length'<br/>``` <br/><br/> **Resultado esperado:** `0` <br/><br/> **¿Por qué?** Puntos sin tenant_id son datos huérfanos que pueden filtrarse. <br/><br/> **Alternativa:** Script de limpieza periódica que elimine puntos sin tenant_id. | MT-007 |
| QDR-04 | `[ ]` Auditar que los batch upserts validen tenant_id antes de insertar. | **Ejemplo de validación en código:** <br/> ```javascript<br/>function validatePoints(points) {<br/>  return points.every(p => p.payload.tenant_id && p.payload.tenant_id.length > 0);<br/>}<br/><br/>if (!validatePoints(batchPoints)) {<br/>  throw new Error('All points must have tenant_id');<br/>}<br/>``` <br/><br/> **¿Por qué?** Inserciones masivas son propensas a olvidar validaciones. <br/><br/> **Alternativa:** Usar JSON Schema validation en el endpoint de inserción. | MT-004 |

### 4.2 Configuración de Colecciones

| ID | Check | Ejemplo de Verificación | REF |
|:---|:------|:------------------------|:----|
| QDR-05 | `[ ]` La dimensión del vector coincide con el modelo de embedding utilizado. | **Comando de verificación:** <br/> `curl -s http://localhost:6333/collections/mantis_docs | jq '.result.config.params.vectors.size'` <br/><br/> **Ejemplos de dimensiones comunes:** <br/> - `text-embedding-3-small` (OpenAI) → 1536 <br/> - `text-embedding-3-large` (OpenAI) → 3072 <br/> - `all-MiniLM-L6-v2` → 384 <br/><br/> **¿Por qué?** Dimensiones incorrectas causan errores al insertar vectores. <br/><br/> **Alternativa:** Crear colección con creación dinámica basada en el primer vector. | ARQ-005 |
| QDR-06 | `[ ]` La métrica de distancia es `Cosine`. | **Comando de verificación:** <br/> `curl -s http://localhost:6333/collections/mantis_docs | jq '.result.config.params.vectors.distance'` <br/><br/> **Valor esperado:** `"Cosine"` <br/><br/> **¿Por qué?** Cosine similarity es estándar para embeddings de texto (invariante a magnitud). <br/><br/> **Alternativas:** <br/> - `Euclidean`: Para embeddings normalizados. <br/> - `Dot`: Para máxima velocidad (si vectores están normalizados). | ARQ-006 |
| QDR-07 | `[ ]` Verificar que la colección tenga índices HNSW configurados correctamente. | **Comando de verificación:** <br/> `curl -s http://localhost:6333/collections/mantis_docs | jq '.result.config.hnsw_config'` <br/><br/> **Configuración recomendada:** <br/> ```json<br/>{<br/>  "m": 16,<br/>  "ef_construct": 100,<br/>  "full_scan_threshold": 10000<br/>}<br/>``` <br/><br/> **¿Por qué?** <br/> - `m=16`: Balance entre precisión y velocidad. <br/> - `ef_construct=100`: Calidad del índice al insertar. <br/><br/> **Alternativa:** Ajustar `m` más alto (32-64) para mayor precisión en colecciones grandes. | ARQ-007 |
| QDR-08 | `[ ]` Comprobar que existan snapshots periódicos de la colección. | **Comando de creación de snapshot:** <br/> ```bash<br/>curl -X POST http://localhost:6333/collections/mantis_docs/snapshots<br/>``` <br/><br/> **Listar snapshots:** <br/> ```bash<br/>curl http://localhost:6333/collections/mantis_docs/snapshots | jq<br/>``` <br/><br/> **¿Por qué?** Los snapshots permiten recuperación ante corrupción de datos. <br/><br/> **Alternativa:** Configurar backup automático con cron job diario. | SEG-009 |

### 4.3 Performance y Optimización

| ID | Check | Ejemplo de Verificación | REF |
|:---|:------|:------------------------|:----|
| QDR-09 | `[ ]` Las búsquedas usan un `limit` razonable (≤100 resultados). | **Comando de auditoría en código:** <br/> `grep -rn "points/search" *.js | grep -o '"limit":[0-9]*' | sort -u` <br/><br/> **Valores recomendados:** <br/> - RAG conversacional: 5-10 resultados <br/> - Búsqueda exploratoria: 20-50 resultados <br/><br/> **¿Por qué?** Límites altos aumentan latencia y uso de RAM innecesariamente. <br/><br/> **Alternativa:** Implementar paginación para búsquedas extensas. | RES-009 |
| QDR-10 | `[ ]` Verificar que se esté usando `score_threshold` para filtrar resultados irrelevantes. | **Ejemplo de búsqueda con threshold:** <br/> ```json<br/>{<br/>  "limit": 10,<br/>  "score_threshold": 0.7<br/>}<br/>``` <br/><br/> **¿Por qué?** Sin threshold, se devuelven resultados con baja similitud que confunden al LLM. <br/><br/> **Alternativa:** Implementar re-ranking con un modelo cross-encoder después de la búsqueda inicial. | API-004 |
| QDR-11 | `[ ]` Auditar que los embeddings se estén generando en lotes (batch), no uno por uno. | **❌ Ineficiente:** <br/> ```javascript<br/>for (let doc of documents) {<br/>  const embedding = await generateEmbedding(doc.text);<br/>}<br/>``` <br/><br/> **✅ Eficiente:** <br/> ```javascript<br/>const texts = documents.map(d => d.text);<br/>const embeddings = await generateEmbeddingsBatch(texts);<br/>``` <br/><br/> **¿Por qué?** APIs de embeddings son más rápidas y baratas en batch. <br/><br/> **Alternativa:** Usar colas (Bull, RabbitMQ) para procesar embeddings asíncronamente. | RES-008 |
| QDR-12 | `[ ]` Comprobar que el tamaño de payload no sea excesivo (≤10KB por punto). | **Comando de verificación:** <br/> ```bash<br/>curl -X POST http://localhost:6333/collections/mantis_docs/points/scroll \<br/>  -d '{"limit":100}' | jq '.result.points[].payload' | wc -c<br/>``` <br/><br/> **¿Por qué?** Payloads grandes aumentan uso de RAM y latencia de búsqueda. <br/><br/> **Alternativa:** Guardar solo metadatos en Qdrant, texto completo en MySQL. | RES-010 |

### 4.4 Monitoreo y Health Checks

| ID | Check | Ejemplo de Verificación | REF |
|:---|:------|:------------------------|:----|
| QDR-13 | `[ ]` Verificar que el endpoint de health check responda correctamente. | **Comando de verificación:** <br/> `curl -s http://localhost:6333/healthz` <br/><br/> **Respuesta esperada:** `{"status":"ok"}` <br/><br/> **¿Por qué?** Permite monitoreo automatizado de disponibilidad. <br/><br/> **Alternativa:** Integrar con Prometheus usando el endpoint `/metrics`. | RES-011 |
| QDR-14 | `[ ]` Auditar métricas de uso de memoria de Qdrant. | **Comando de verificación:** <br/> `curl -s http://localhost:6333/collections/mantis_docs | jq '.result.points_count, .result.vectors_count, .result.indexed_vectors_count'` <br/><br/> **¿Por qué?** Permite detectar crecimientos anómalos en el número de vectores. <br/><br/> **Alternativa:** Configurar alertas cuando `points_count` crezca >20% en 24h. | RES-012 |
| QDR-15 | `[ ]` Verificar tiempos de respuesta de búsquedas. | **Comando de benchmark:** <br/> ```bash<br/>time curl -X POST http://localhost:6333/collections/mantis_docs/points/search \<br/>  -d '{<br/>    "vector": [0.1, 0.2, ...],  # 1536 dims<br/>    "limit": 10,<br/>    "filter": {"must": [{"key": "tenant_id", "match": {"keyword": "test"}}]}<br/>  }'<br/>``` <br/><br/> **Latencia esperada:** <100ms para colecciones <1M puntos. <br/><br/> **¿Por qué?** Latencias altas afectan experiencia de usuario en RAG conversacional. <br/><br/> **Alternativa:** Usar herramientas como `hey` o `wrk` para load testing. | API-005 |
| QDR-16 | `[ ]` Comprobar que exista un plan de escalado vertical/horizontal. | **Pregunta de revisión:** ¿Qué pasa si la colección supera 10M vectores? <br/><br/> **Opciones de escalado:** <br/> - Vertical: Migrar a VPS con más RAM <br/> - Horizontal: Sharding por tenant_id en múltiples instancias Qdrant <br/><br/> **¿Por qué?** Qdrant puede manejar 100M+ vectores pero requiere planificación. <br/><br/> **Alternativa:** Usar Qdrant Cloud para escalado automático. | ESC-001 |

---

## 5. Validación de RAG (Ingesta y Recuperación)

**¿Qué validamos aquí?** El sistema RAG (Retrieval-Augmented Generation) combina búsqueda vectorial con LLMs. Debemos garantizar que la ingesta sea correcta y las búsquedas eficientes.

**¿Por qué es importante?** RAG mal configurado produce respuestas irrelevantes o expone datos de otros clientes.

### 5.1 Ingesta de Documentos

| ID | Check | Ejemplo de Verificación | REF |
|:---|:------|:------------------------|:----|
| RAG-01 | `[ ]` Los documentos se dividen en chunks de tamaño apropiado (500-1000 tokens). | **Ejemplo de chunking correcto:** <br/> ```python<br/>from langchain.text_splitter import RecursiveCharacterTextSplitter<br/><br/>splitter = RecursiveCharacterTextSplitter(<br/>    chunk_size=1000,  # caracteres, ~250 tokens<br/>    chunk_overlap=200,  # 20% overlap<br/>    separators=["\n\n", "\n", ". ", " "]<br/>)<br/>chunks = splitter.split_text(document)<br/>``` <br/><br/> **¿Por qué?** <br/> - Chunks pequeños (<200 tokens): Pierden contexto. <br/> - Chunks grandes (>2000 tokens): Exceden límite de embeddings. <br/><br/> **Alternativa:** Usar chunking semántico con modelos como `sentence-transformers`. | RES-008 |
| RAG-02 | `[ ]` Cada chunk incluye metadatos suficientes para reconstrucción (source, page, tenant_id). | **Payload de ejemplo:** <br/> ```json<br/>{<br/>  "text": "El artículo 5 establece...",<br/>  "tenant_id": "restaurant_123",<br/>  "source": "manual_empleados.pdf",<br/>  "page": 12,<br/>  "chunk_index": 3,<br/>  "total_chunks": 45<br/>}<br/>``` <br/><br/> **¿Por qué?** Metadatos permiten mostrar fuente al usuario y debugging. <br/><br/> **Alternativa:** Guardar metadata extendido en MySQL, solo IDs en Qdrant. | RAG-001 |
| RAG-03 | `[ ]` Verificar que el overlap entre chunks sea consistente (10-20%). | **¿Por qué tener overlap?** Evita que información importante se corte entre chunks. <br/><br/> **Comando de validación en código:** <br/> ```python<br/>assert chunk_overlap / chunk_size >= 0.1  # mínimo 10%<br/>assert chunk_overlap / chunk_size <= 0.3  # máximo 30%<br/>``` <br/><br/> **Alternativa:** Usar chunking por párrafos naturales en lugar de caracteres fijos. | RES-008 |
| RAG-04 | `[ ]` Auditar que los documentos PDF se estén procesando correctamente (sin caracteres corruptos). | **Comando de verificación:** <br/> ```python<br/>import fitz  # PyMuPDF<br/>doc = fitz.open("document.pdf")<br/>text = doc[0].get_text()<br/>assert "�" not in text  # Detecta caracteres corruptos<br/>``` <br/><br/> **¿Por qué?** PDFs escaneados o con fuentes no estándar pueden tener encoding issues. <br/><br/> **Alternativa:** Usar OCR (Tesseract) para PDFs escaneados. | RAG-002 |

### 5.2 Generación de Embeddings

| ID | Check | Ejemplo de Verificación | REF |
|:---|:------|:------------------------|:----|
| RAG-05 | `[ ]` Los embeddings se generan con el modelo documentado (ej. `text-embedding-3-small`). | **Comando de auditoría en código:** <br/> `grep -rn "text-embedding" *.js *.py` <br/><br/> **¿Por qué?** Cambiar modelo de embeddings requiere re-indexar toda la colección. <br/><br/> **Alternativa:** Guardar `embedding_model` en metadata de Qdrant para trazabilidad. | ARQ-005 |
| RAG-06 | `[ ]` Verificar que los embeddings estén normalizados si se usa distancia Dot. | **Comando de verificación:** <br/> ```python<br/>import numpy as np<br/>norm = np.linalg.norm(embedding)<br/>assert 0.99 < norm < 1.01  # Debe estar normalizado<br/>``` <br/><br/> **¿Por qué?** Dot product sin normalización da resultados incorrectos. <br/><br/> **Alternativa:** Usar Cosine distance que normaliza automáticamente. | ARQ-006 |
| RAG-07 | `[ ]` Auditar que no se estén generando embeddings duplicados. | **Comando de verificación en Qdrant:** <br/> ```bash<br/>curl -X POST http://localhost:6333/collections/mantis_docs/points/scroll \<br/>  -d '{"limit": 1000}' | jq -r '.result.points[].payload.text' | sort | uniq -d<br/>``` <br/><br/> **¿Por qué?** Duplicados desperdician espacio y pueden sesgar búsquedas. <br/><br/> **Alternativa:** Usar hashing de contenido para detectar duplicados antes de insertar. | RES-010 |
| RAG-08 | `[ ]` Comprobar que los embeddings se cacheen para textos repetidos. | **Ejemplo de implementación:** <br/> ```python<br/>import hashlib<br/>from functools import lru_cache<br/><br/>@lru_cache(maxsize=1000)<br/>def get_embedding_cached(text_hash):<br/>    return generate_embedding(text)<br/>``` <br/><br/> **¿Por qué?** Reduce costos de API y latencia. <br/><br/> **Alternativa:** Usar Redis para cache distribuido entre workers. | RES-006 |

### 5.3 Recuperación y Ranking

| ID | Check | Ejemplo de Verificación | REF |
|:---|:------|:------------------------|:----|
| RAG-09 | `[ ]` Las búsquedas usan `topK` entre 3-10 resultados. | **Comando de auditoría en código:** <br/> `grep -rn "topK.*[0-9]" *.js | grep -v -E "topK.*(3|4|5|6|7|8|9|10)"` <br/><br/> **¿Por qué?** <br/> - topK muy bajo (1-2): Puede perder contexto relevante. <br/> - topK muy alto (>20): Ruido confunde al LLM. <br/><br/> **Alternativa:** Hacer topK dinámico basado en score threshold. | RES-009 |
| RAG-10 | `[ ]` Verificar que se esté usando re-ranking con score threshold (>0.7). | **Ejemplo de implementación:** <br/> ```python<br/>results = qdrant.search(query_vector, limit=20)<br/>filtered = [r for r in results if r.score > 0.7]<br/>top_results = filtered[:5]  # Re-rank y limitar<br/>``` <br/><br/> **¿Por qué?** Score threshold elimina resultados irrelevantes. <br/><br/> **Alternativa:** Usar modelos cross-encoder para re-ranking más preciso. | API-004 |
| RAG-11 | `[ ]` Auditar que los resultados incluyan suficiente contexto para el LLM. | **Revisión manual:** ¿Los chunks devueltos tienen sentido por sí solos? <br/><br/> **Ejemplo problemático:** Chunk que empieza "...por lo tanto, el artículo establece" (falta contexto previo). <br/><br/> **Solución:** Incluir chunk anterior/posterior en el payload. <br/><br/> **Alternativa:** Usar "parent document retrieval" que devuelve documentos completos. | RAG-003 |
| RAG-12 | `[ ]` Comprobar que las búsquedas híbridas (vector + keyword) estén habilitadas si aplica. | **Ejemplo de búsqueda híbrida en Qdrant:** <br/> ```json<br/>{<br/>  "query": "política de devoluciones",<br/>  "filter": {<br/>    "must": [<br/>      {"key": "tenant_id", "match": {"keyword": "shop_456"}},<br/>      {"key": "text", "match": {"text": "devoluciones"}}<br/>    ]<br/>  }<br/>}<br/>``` <br/><br/> **¿Por qué?** Búsquedas híbridas combinan ventajas de similitud semántica y keyword matching. <br/><br/> **Alternativa:** Usar BM25 + vector search con RRF (Reciprocal Rank Fusion). | RAG-004 |

### 5.4 Integración con LLM

| ID | Check | Ejemplo de Verificación | REF |
|:---|:------|:------------------------|:----|
| RAG-13 | `[ ]` El prompt incluye instrucciones claras de cómo usar el contexto recuperado. | **Ejemplo de prompt correcto:** <br/> ```<br/>Contexto recuperado de la base de conocimientos:<br/>{context}<br/><br/>Responde la pregunta usando SOLO la información del contexto anterior.<br/>Si el contexto no contiene la respuesta, di "No tengo información sobre eso".<br/><br/>Pregunta: {question}<br/>``` <br/><br/> **¿Por qué?** Sin instrucciones claras, el LLM puede "alucinar" información. <br/><br/> **Alternativa:** Usar few-shot examples de respuestas correctas basadas en contexto. | RAG-005 |
| RAG-14 | `[ ]` Verificar que el contexto no exceda el límite del modelo (ej. 4096 tokens para GPT-3.5). | **Comando de verificación:** <br/> ```python<br/>import tiktoken<br/>enc = tiktoken.encoding_for_model("gpt-3.5-turbo")<br/>total_tokens = len(enc.encode(prompt + context))<br/>assert total_tokens < 4000  # Dejar espacio para respuesta<br/>``` <br/><br/> **¿Por qué?** Exceder el límite trunca el contexto o causa error. <br/><br/> **Alternativa:** Usar modelos con mayor context window (Claude 3, GPT-4 Turbo). | RES-002 |
| RAG-15 | `[ ]` Auditar que las respuestas incluyan citas o referencias a las fuentes. | **Ejemplo de formato de respuesta:** <br/> ```<br/>Según el Manual de Empleados (página 12), las vacaciones se...<br/><br/>Fuentes consultadas:<br/>- manual_empleados.pdf (página 12, chunk 3)<br/>``` <br/><br/> **¿Por qué?** Las citas aumentan confiabilidad y permiten verificación. <br/><br/> **Alternativa:** Usar structured output del LLM con campos `answer` y `sources`. | RAG-006 |
| RAG-16 | `[ ]` Comprobar que exista fallback cuando no hay resultados relevantes. | **Ejemplo de lógica de fallback:** <br/> ```python<br/>if not results or max(r.score for r in results) < 0.7:<br/>    return {<br/>        "answer": "No encontré información relevante sobre tu pregunta.",<br/>        "suggestion": "Intenta reformular o pregunta a un humano."<br/>    }<br/>``` <br/><br/> **¿Por qué?** Respuestas forzadas sin contexto generan frustración. <br/><br/> **Alternativa:** Escalar a agente humano automáticamente. | RAG-007 |

---

## 6. Validación de EspoCRM

**¿Qué validamos aquí?** EspoCRM es el sistema CRM donde se gestionan leads y clientes. Debemos garantizar que la integración API sea segura y respete multi-tenancy.

**¿Por qué es importante?** El CRM contiene datos sensibles de clientes que deben estar protegidos y aislados.

### 6.1 Configuración de API

| ID | Check | Ejemplo de Verificación | REF |
|:---|:------|:------------------------|:----|
| ESPO-01 | `[ ]` La API key de EspoCRM no está hardcodeada en el código. | **Comando de auditoría:** <br/> `grep -rn "X-Api-Key" *.js *.json | grep -v "process.env"` <br/><br/> **Resultado esperado:** Vacío. <br/><br/> **Ejemplo seguro:** <br/> ```javascript<br/>const headers = {<br/>  'X-Api-Key': process.env.ESPOCRM_API_KEY<br/>};<br/>``` <br/><br/> **¿Por qué?** API keys en código pueden filtrarse en repositorios. <br/><br/> **Alternativa:** Usar secrets management (Vault, AWS Secrets Manager). | SEG-002 |
| ESPO-02 | `[ ]` Todas las peticiones incluyen `tenant_id` en headers custom. | **Ejemplo de header correcto:** <br/> ```javascript<br/>const headers = {<br/>  'X-Api-Key': apiKey,<br/>  'X-Tenant-Id': tenantId  // Custom header<br/>};<br/>``` <br/><br/> **¿Por qué?** Permite auditoría y filtrado a nivel de CRM. <br/><br/> **Alternativa:** Incluir tenant_id en el payload de cada request. | MT-009 |
| ESPO-03 | `[ ]` Verificar que se esté usando HTTPS para todas las llamadas al CRM. | **Comando de verificación:** <br/> `grep -rn "http://" *.js | grep espocrm` <br/><br/> **Resultado esperado:** Vacío (solo HTTPS). <br/><br/> **¿Por qué?** HTTP transmite datos en texto plano. <br/><br/> **Alternativa:** Configurar certificado SSL/TLS en el servidor EspoCRM. | SEG-004 |
| ESPO-04 | `[ ]` Auditar que las respuestas de API tengan rate limiting configurado. | **Verificar en headers de respuesta:** <br/> ```bash<br/>curl -I https://crm.example.com/api/v1/Lead<br/>X-RateLimit-Limit: 1000<br/>X-RateLimit-Remaining: 999<br/>``` <br/><br/> **¿Por qué?** Previene abuso de la API. <br/><br/> **Alternativa:** Implementar rate limiting en nginx/Caddy antes de EspoCRM. | API-006 |

### 6.2 Operaciones CRUD

| ID | Check | Ejemplo de Verificación | REF |
|:---|:------|:------------------------|:----|
| ESPO-05 | `[ ]` Los filtros de búsqueda incluyen tenant_id en el WHERE. | **Ejemplo de request correcto:** <br/> ```javascript<br/>const searchParams = {<br/>  where: [<br/>    {<br/>      type: 'equals',<br/>      attribute: 'assignedUserId',<br/>      value: userId<br/>    },<br/>    {<br/>      type: 'equals',<br/>      attribute: 'customTenantId',  // Campo custom<br/>      value: tenantId<br/>    }<br/>  ]<br/>};<br/>``` <br/><br/> **¿Por qué?** Sin filtro, se obtienen leads de todos los clientes. <br/><br/> **Alternativa:** Configurar roles en EspoCRM con acceso limitado por tenant. | MT-009 |
| ESPO-06 | `[ ]` Verificar que los campos custom para tenant_id estén creados en todas las entidades. | **Comando de verificación en EspoCRM:** <br/> Admin → Entity Manager → Lead → Fields → Buscar "tenant_id" <br/><br/> **¿Por qué?** Sin campo custom, no hay forma de almacenar tenant_id. <br/><br/> **Alternativa:** Usar "teams" de EspoCRM para aislamiento nativo. | MT-010 |
| ESPO-07 | `[ ]` Auditar que no se estén creando registros sin tenant_id. | **Ejemplo de validación pre-insert:** <br/> ```javascript<br/>function validateLead(lead) {<br/>  if (!lead.customTenantId) {<br/>    throw new Error('tenant_id is required');<br/>  }<br/>}<br/>``` <br/><br/> **¿Por qué?** Registros sin tenant_id son datos huérfanos. <br/><br/> **Alternativa:** Configurar validación en EspoCRM vía Formula. | MT-001 |
| ESPO-08 | `[ ]` Comprobar que los webhooks de EspoCRM incluyan tenant_id en el payload. | **Ejemplo de payload de webhook esperado:** <br/> ```json<br/>{<br/>  "event": "Lead.created",<br/>  "data": {<br/>    "id": "abc123",<br/>    "name": "Juan Pérez",<br/>    "customTenantId": "restaurant_789"<br/>  }<br/>}<br/>``` <br/><br/> **¿Por qué?** Los webhooks alimentan otros sistemas que necesitan tenant_id. <br/><br/> **Alternativa:** Procesar webhooks en n8n y agregar tenant_id desde metadata. | MT-009 |

### 6.3 Sincronización de Datos

| ID | Check | Ejemplo de Verificación | REF |
|:---|:------|:------------------------|:----|
| ESPO-09 | `[ ]` La sincronización bidireccional (CRM ↔ App) preserva tenant_id. | **Test de integración:** <br/> 1. Crear lead en App con tenant_id=X <br/> 2. Verificar en CRM que tenga customTenantId=X <br/> 3. Actualizar lead en CRM <br/> 4. Verificar en App que siga teniendo tenant_id=X <br/><br/> **¿Por qué?** Sincronización puede sobrescribir tenant_id accidentalmente. <br/><br/> **Alternativa:** Hacer tenant_id read-only después de creación. | MT-011 |
| ESPO-10 | `[ ]` Verificar que existan logs de auditoría de modificaciones. | **Comando de verificación en EspoCRM:** <br/> Admin → Stream → Habilitar para Lead <br/><br/> **¿Por qué?** Permite rastrear quién modificó qué dato y cuándo. <br/><br/> **Alternativa:** Exportar logs a sistema externo (ELK, Loki). | SEG-008 |
| ESPO-11 | `[ ]` Auditar que las eliminaciones (soft delete) mantengan tenant_id. | **Verificar en BD de EspoCRM:** <br/> ```sql<br/>SELECT id, deleted, custom_tenant_id <br/>FROM lead <br/>WHERE deleted = 1 <br/>LIMIT 10;<br/>``` <br/><br/> **¿Por qué?** Registros eliminados pueden necesitar recuperación. <br/><br/> **Alternativa:** Implementar papelera de reciclaje con TTL de 30 días. | MT-001 |
| ESPO-12 | `[ ]` Comprobar que la sincronización maneje conflictos correctamente. | **Escenario de prueba:** <br/> 1. Modificar mismo lead simultáneamente en App y CRM <br/> 2. Verificar que última modificación gane (last-write-wins) <br/> 3. O que se genere alerta de conflicto <br/><br/> **¿Por qué?** Conflictos no manejados causan pérdida de datos. <br/><br/> **Alternativa:** Usar versioning con timestamps para merge inteligente. | ARQ-009 |

### 6.4 Seguridad y Permisos

| ID | Check | Ejemplo de Verificación | REF |
|:---|:------|:------------------------|:----|
| ESPO-13 | `[ ]` Los roles de EspoCRM tienen permisos mínimos necesarios. | **Revisión en EspoCRM:** <br/> Admin → Roles → API User → Verificar permisos <br/><br/> **Permisos recomendados:** <br/> - Lead: create, read, edit <br/> - Account: read only <br/> - User: no access <br/><br/> **¿Por qué?** Principio de mínimo privilegio reduce riesgo. <br/><br/> **Alternativa:** Crear roles específicos por tipo de integración. | SEG-003 |
| ESPO-14 | `[ ]` Verificar que las API keys tengan expiración configurada. | **¿Por qué?** API keys permanentes son riesgos de seguridad. <br/><br/> **Alternativa:** Rotar API keys cada 90 días automáticamente. | SEG-007 |
| ESPO-15 | `[ ]` Auditar que los logs de acceso a API estén habilitados. | **Comando de verificación:** <br/> Revisar archivos en `data/logs/` de EspoCRM <br/><br/> **¿Por qué?** Permite detectar accesos no autorizados. <br/><br/> **Alternativa:** Enviar logs a SIEM (Security Information and Event Management). | SEG-008 |
| ESPO-16 | `[ ]` Comprobar que exista 2FA habilitado para usuarios admin. | **Verificación:** <br/> Admin → Authentication → 2-Factor Authentication: Enabled <br/><br/> **¿Por qué?** 2FA previene takeover de cuentas admin. <br/><br/> **Alternativa:** Usar SSO con proveedor que soporte 2FA. | SEG-011 |

---

## 7. Validación de Supabase

**¿Qué validamos aquí?** Supabase provee PostgreSQL como servicio con Row Level Security (RLS). Debemos garantizar que las políticas RLS estén correctamente configuradas para multi-tenancy.

**¿Por qué es importante?** Sin RLS, cualquier usuario autenticado podría ver datos de otros tenants.

### 7.1 Row Level Security (RLS)

| ID | Check | Ejemplo de Verificación | REF |
|:---|:------|:------------------------|:----|
| SUP-01 | `[ ]` RLS está habilitado en TODAS las tablas que contienen datos de tenants. | **Comando de verificación en Supabase:** <br/> ```sql<br/>SELECT tablename, rowsecurity <br/>FROM pg_tables <br/>WHERE schemaname = 'public';<br/>``` <br/><br/> **Resultado esperado:** `rowsecurity = true` para todas las tablas de datos. <br/><br/> **Ejemplo de habilitación:** <br/> ```sql<br/>ALTER TABLE messages ENABLE ROW LEVEL SECURITY;<br/>``` <br/><br/> **¿Por qué?** Sin RLS, las políticas no se aplican. <br/><br/> **Alternativa:** Usar schemas separados por tenant (más complejo). | MT-010 |
| SUP-02 | `[ ]` Cada tabla tiene una política que filtra por `tenant_id`. | **Ejemplo de política RLS:** <br/> ```sql<br/>CREATE POLICY tenant_isolation_policy ON messages<br/>  FOR ALL<br/>  USING (tenant_id = current_setting('app.current_tenant_id')::uuid);<br/>``` <br/><br/> **Comando de verificación:** <br/> ```sql<br/>SELECT * FROM pg_policies WHERE tablename = 'messages';<br/>``` <br/><br/> **¿Por qué?** La política garantiza que solo se vean datos del tenant actual. <br/><br/> **Alternativa:** Usar `auth.uid()` si cada tenant tiene usuarios Supabase separados. | MT-011 |
| SUP-03 | `[ ]` Verificar que las políticas RLS cubran SELECT, INSERT, UPDATE, DELETE. | **Ejemplo de políticas completas:** <br/> ```sql<br/>CREATE POLICY select_own_tenant ON messages<br/>  FOR SELECT USING (tenant_id = current_setting('app.current_tenant_id')::uuid);<br/><br/>CREATE POLICY insert_own_tenant ON messages<br/>  FOR INSERT WITH CHECK (tenant_id = current_setting('app.current_tenant_id')::uuid);<br/>``` <br/><br/> **¿Por qué?** Cada operación necesita su política. <br/><br/> **Alternativa:** Usar `FOR ALL` para cubrir todas las operaciones con una sola política. | MT-011 |
| SUP-04 | `[ ]` Auditar que `current_setting('app.current_tenant_id')` se esté configurando correctamente. | **Ejemplo de configuración en conexión:** <br/> ```javascript<br/>const { data, error } = await supabase.rpc('set_tenant_id', {<br/>  tenant_id: 'restaurant_123'<br/>});<br/><br/>// Función en Supabase<br/>CREATE OR REPLACE FUNCTION set_tenant_id(tenant_id text)<br/>RETURNS void AS $$<br/>BEGIN<br/>  PERFORM set_config('app.current_tenant_id', tenant_id, false);<br/>END;<br/>$$ LANGUAGE plpgsql SECURITY DEFINER;<br/>``` <br/><br/> **¿Por qué?** Si no se configura, las políticas RLS fallan. <br/><br/> **Alternativa:** Usar JWT claims con tenant_id y extraerlo en RLS. | MT-011 |

### 7.2 Conexiones y Autenticación

| ID | Check | Ejemplo de Verificación | REF |
|:---|:------|:------------------------|:----|
| SUP-05 | `[ ]` Las conexiones usan service_role key solo en backend, nunca en frontend. | **Comando de auditoría:** <br/> `grep -rn "service_role" *.html *.js | grep -v "server\|backend"` <br/><br/> **Resultado esperado:** Vacío. <br/><br/> **¿Por qué?** service_role key bypasea RLS y es extremadamente poderosa. <br/><br/> **Alternativa:** Usar anon key en frontend y backend con service_role solo para operaciones admin. | SEG-002 |
| SUP-06 | `[ ]` Verificar que JWT de Supabase incluya tenant_id en los claims. | **Comando de verificación:** <br/> ```javascript<br/>const { data: { user } } = await supabase.auth.getUser();<br/>console.log(user.app_metadata.tenant_id);<br/>``` <br/><br/> **¿Por qué?** Permite extraer tenant_id automáticamente en RLS. <br/><br/> **Alternativa:** Usar función trigger para agregar tenant_id al JWT. | MT-011 |
| SUP-07 | `[ ]` Auditar que las conexiones directas a PostgreSQL estén bloqueadas. | **Verificación en Supabase Dashboard:** <br/> Settings → Database → Connection Pooling: Enabled <br/> Direct connections: Disabled <br/><br/> **¿Por qué?** Conexiones directas bypasean pooling y pueden agotar conexiones. <br/><br/> **Alternativa:** Usar Supavisor (pooler de Supabase). | ARQ-007 |
| SUP-08 | `[ ]` Comprobar que exista rate limiting en APIs de Supabase. | **Verificación:** <br/> Supabase aplica rate limiting automático en plan Pro (100 req/s). <br/><br/> **¿Por qué?** Previene abuso de la API. <br/><br/> **Alternativa:** Implementar rate limiting custom en edge functions. | API-006 |

### 7.3 Realtime y Subscripciones

| ID | Check | Ejemplo de Verificación | REF |
|:---|:------|:------------------------|:----|
| SUP-09 | `[ ]` Las subscripciones Realtime incluyen filtro por tenant_id. | **Ejemplo de subscription correcto:** <br/> ```javascript<br/>const subscription = supabase<br/>  .channel('messages')<br/>  .on(<br/>    'postgres_changes',<br/>    {<br/>      event: '*',<br/>      schema: 'public',<br/>      table: 'messages',<br/>      filter: `tenant_id=eq.${tenantId}`  // CRÍTICO<br/>    },<br/>    (payload) => console.log(payload)<br/>  )<br/>  .subscribe();<br/>``` <br/><br/> **¿Por qué?** Sin filtro, se reciben updates de todos los tenants. <br/><br/> **Alternativa:** Configurar políticas RLS que también apliquen a Realtime. | MT-011 |
| SUP-10 | `[ ]` Verificar que RLS aplique también a queries de Realtime. | **Test de verificación:** <br/> 1. Subscribirse a tabla con RLS habilitado <br/> 2. Insertar registro de otro tenant <br/> 3. Verificar que NO se reciba en la subscription <br/><br/> **¿Por qué?** Realtime debe respetar RLS igual que queries normales. <br/><br/> **Alternativa:** Documentación oficial de Supabase confirma que RLS aplica a Realtime. | MT-011 |
| SUP-11 | `[ ]` Auditar que las subscripciones tengan cleanup correcto (unsubscribe). | **Ejemplo de cleanup correcto:** <br/> ```javascript<br/>useEffect(() => {<br/>  const subscription = supabase.channel('messages').subscribe();<br/>  <br/>  return () => {<br/>    subscription.unsubscribe();  // CRÍTICO<br/>  };<br/>}, []);<br/>``` <br/><br/> **¿Por qué?** Subscripciones sin cleanup causan memory leaks. <br/><br/> **Alternativa:** Usar librerías como `react-query` que manejan cleanup automáticamente. | RES-006 |
| SUP-12 | `[ ]` Comprobar que el número de canales concurrentes esté limitado. | **Límite de Supabase:** <br/> - Free: 100 concurrent channels <br/> - Pro: 500 concurrent channels <br/><br/> **Monitoreo:** <br/> Settings → Database → Realtime → Active channels <br/><br/> **¿Por qué?** Exceder límite causa errores en nuevas subscripciones. <br/><br/> **Alternativa:** Usar single channel con multiplexing por tenant_id. | RES-011 |

### 7.4 Storage y Files

| ID | Check | Ejemplo de Verificación | REF |
|:---|:------|:------------------------|:----|
| SUP-13 | `[ ]` Los buckets de Storage tienen políticas que incluyen tenant_id en el path. | **Ejemplo de política de bucket:** <br/> ```sql<br/>CREATE POLICY "Users can upload to their tenant folder" ON storage.objects<br/>  FOR INSERT WITH CHECK (<br/>    bucket_id = 'documents' AND<br/>    (storage.foldername(name))[1] = current_setting('app.current_tenant_id')<br/>  );<br/>``` <br/><br/> **Estructura de folders:** <br/> `documents/restaurant_123/invoice_001.pdf` <br/><br/> **¿Por qué?** Previene que un tenant acceda archivos de otro. <br/><br/> **Alternativa:** Usar buckets separados por tenant (más costoso). | MT-011 |
| SUP-14 | `[ ]` Verificar que los archivos tengan metadata con tenant_id. | **Ejemplo de upload con metadata:** <br/> ```javascript<br/>const { data, error } = await supabase.storage<br/>  .from('documents')<br/>  .upload(`${tenantId}/file.pdf`, file, {<br/>    metadata: { tenant_id: tenantId }  // Custom metadata<br/>  });<br/>``` <br/><br/> **¿Por qué?** Metadata permite auditoría y filtrado. <br/><br/> **Alternativa:** Almacenar metadata en tabla separada con foreign key al archivo. | MT-009 |
| SUP-15 | `[ ]` Auditar que las URLs firmadas incluyan expiración corta. | **Ejemplo de URL firmada segura:** <br/> ```javascript<br/>const { data } = await supabase.storage<br/>  .from('documents')<br/>  .createSignedUrl(`${tenantId}/file.pdf`, 300);  // 5 minutos<br/>``` <br/><br/> **¿Por qué?** URLs sin expiración pueden compartirse indefinidamente. <br/><br/> **Alternativa:** Usar políticas RLS en vez de URLs firmadas cuando sea posible. | SEG-007 |
| SUP-16 | `[ ]` Comprobar que exista límite de tamaño de archivo (upload size limit). | **Configuración en Supabase:** <br/> Settings → Storage → Max file size: 50MB <br/><br/> **¿Por qué?** Archivos grandes pueden agotar disco y ancho de banda. <br/><br/> **Alternativa:** Implementar validación de tamaño en cliente antes de upload. | RES-010 |

---

## 8. Validación de APIs y Manejo de API (NUEVA SECCIÓN)

**¿Qué validamos aquí?** Las APIs son la capa de comunicación entre servicios. Debemos garantizar que sean seguras, confiables y respeten límites de recursos.

**¿Por qué es importante?** APIs mal diseñadas pueden exponer datos, causar denegación de servicio o violar SLAs.

### 8.1 Validación de Endpoints REST

| ID | Check | Ejemplo de Verificación | REF |
|:---|:------|:------------------------|:----|
| API-01 | `[ ]` Todos los endpoints requieren autenticación (excepto health checks públicos). | **Comando de auditoría:** <br/> ```bash<br/>curl -X GET https://api.example.com/v1/users<br/>``` <br/><br/> **Respuesta esperada:** <br/> ```json<br/>{<br/>  "error": "Unauthorized",<br/>  "statusCode": 401<br/>}<br/>``` <br/><br/> **¿Por qué?** Endpoints sin auth son puertas abiertas a datos sensibles. <br/><br/> **Alternativa:** Usar API Gateway con autenticación centralizada. | SEG-001 |
| API-02 | `[ ]` Los endpoints incluyen tenant_id en headers o payload (no en URL). | **❌ Inseguro (tenant_id en URL):** <br/> `GET /api/v1/restaurant_123/orders` <br/><br/> **✅ Seguro (tenant_id en header):** <br/> ```bash<br/>curl -H "X-Tenant-Id: restaurant_123" \<br/>     -H "Authorization: Bearer TOKEN" \<br/>     https://api.example.com/v1/orders<br/>``` <br/><br/> **¿Por qué?** tenant_id en URL puede filtrarse en logs de servidor web. <br/><br/> **Alternativa:** Incluir tenant_id en JWT claims y extraerlo del token. | MT-009 |
| API-03 | `[ ]` Verificar que los métodos HTTP sean correctos (GET/POST/PUT/DELETE). | **Auditoría de coherencia:** <br/> - GET: Solo lectura, no modifica estado <br/> - POST: Crear recursos <br/> - PUT/PATCH: Actualizar recursos existentes <br/> - DELETE: Eliminar recursos <br/><br/> **❌ Incorrecto:** <br/> `GET /api/v1/users/delete/123` (debería ser DELETE) <br/><br/> **¿Por qué?** Verbos incorrectos confunden a consumidores de la API. <br/><br/> **Alternativa:** Usar herramientas de linting de OpenAPI. | PAT-005 |
| API-04 | `[ ]` Auditar que las respuestas tengan status codes apropiados. | **Status codes recomendados:** <br/> - 200: Éxito (GET, PUT) <br/> - 201: Recurso creado (POST) <br/> - 204: Éxito sin contenido (DELETE) <br/> - 400: Bad request <br/> - 401: No autenticado <br/> - 403: No autorizado <br/> - 404: No encontrado <br/> - 500: Error interno <br/><br/> **Comando de test:** <br/> ```bash<br/>curl -w "%{http_code}" -o /dev/null -s https://api.example.com/v1/nonexistent<br/>``` <br/><br/> **Resultado esperado:** `404` <br/><br/> **¿Por qué?** Status codes correctos permiten manejo de errores apropiado. <br/><br/> **Alternativa:** Usar librerías que manejen status codes automáticamente (Express, FastAPI). | API-007 |

### 8.2 Rate Limiting y Throttling

| ID | Check | Ejemplo de Verificación | REF |
|:---|:------|:------------------------|:----|
| API-05 | `[ ]` Todos los endpoints tienen rate limiting configurado. | **Ejemplo de configuración en nginx:** <br/> ```nginx<br/>limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;<br/><br/>location /api/ {<br/>    limit_req zone=api_limit burst=20 nodelay;<br/>}<br/>``` <br/><br/> **Headers de respuesta esperados:** <br/> ```<br/>X-RateLimit-Limit: 10<br/>X-RateLimit-Remaining: 9<br/>X-RateLimit-Reset: 1234567890<br/>``` <br/><br/> **¿Por qué?** Previene abuso de API y ataques DDoS. <br/><br/> **Alternativa:** Usar servicios como Cloudflare Rate Limiting o AWS API Gateway. | API-006 |
| API-06 | `[ ]` Verificar que el rate limiting sea por tenant_id, no solo por IP. | **Ejemplo de implementación:** <br/> ```javascript<br/>const rateLimit = require('express-rate-limit');<br/><br/>const limiter = rateLimit({<br/>  keyGenerator: (req) => req.headers['x-tenant-id'],  // Por tenant<br/>  max: 100,  // 100 requests<br/>  windowMs: 60 * 1000  // por minuto<br/>});<br/>``` <br/><br/> **¿Por qué?** Limitar por IP afecta a todos los tenants detrás de un mismo proxy/NAT. <br/><br/> **Alternativa:** Usar múltiples niveles: global (por IP) + por tenant + por endpoint. | API-006 |
| API-07 | `[ ]` Auditar que existan diferentes límites para endpoints críticos vs. no críticos. | **Ejemplo de configuración diferenciada:** <br/> ```javascript<br/>// Endpoints de lectura: 1000 req/min<br/>app.get('/api/v1/orders', rateLimitRead, handler);<br/><br/>// Endpoints de escritura: 100 req/min<br/>app.post('/api/v1/orders', rateLimitWrite, handler);<br/>``` <br/><br/> **¿Por qué?** Lecturas son menos costosas que escrituras. <br/><br/> **Alternativa:** Usar tiers de límites según plan del cliente (Free/Pro/Enterprise). | API-006 |
| API-08 | `[ ]` Comprobar que se retorne error 429 (Too Many Requests) cuando se exceda el límite. | **Comando de test:** <br/> ```bash<br/>for i in {1..20}; do<br/>  curl -w "%{http_code}\n" -s https://api.example.com/v1/test<br/>done<br/>``` <br/><br/> **Resultado esperado:** Primeras 10 requests → 200, siguientes → 429 <br/><br/> **Respuesta 429 esperada:** <br/> ```json<br/>{<br/>  "error": "Too Many Requests",<br/>  "retryAfter": 60  // segundos<br/>}<br/>``` <br/><br/> **¿Por qué?** Clientes deben saber cuándo pueden reintentar. <br/><br/> **Alternativa:** Implementar exponential backoff en el cliente. | API-006 |

### 8.3 Autenticación y Tokens

| ID | Check | Ejemplo de Verificación | REF |
|:---|:------|:------------------------|:----|
| API-09 | `[ ]` Los tokens JWT tienen expiración configurada (max 24 horas). | **Ejemplo de generación de token:** <br/> ```javascript<br/>const jwt = require('jsonwebtoken');<br/><br/>const token = jwt.sign(<br/>  { tenant_id: 'restaurant_123', user_id: 'user_456' },<br/>  process.env.JWT_SECRET,<br/>  { expiresIn: '1h' }  // CRÍTICO: Expiración de 1 hora<br/>);<br/>``` <br/><br/> **Comando de validación:** <br/> ```javascript<br/>const decoded = jwt.verify(token, secret);<br/>console.log(decoded.exp);  // Timestamp de expiración<br/>``` <br/><br/> **¿Por qué?** Tokens sin expiración pueden usarse indefinidamente si se filtran. <br/><br/> **Alternativa:** Usar refresh tokens con expiración más larga (7 días) y access tokens cortos (15 min). | SEG-007 |
| API-10 | `[ ]` Verificar que los tokens incluyan tenant_id en los claims. | **Payload de JWT esperado:** <br/> ```json<br/>{<br/>  "sub": "user_456",<br/>  "tenant_id": "restaurant_123",<br/>  "role": "admin",<br/>  "iat": 1234567890,<br/>  "exp": 1234571490<br/>}<br/>``` <br/><br/> **¿Por qué?** Permite validar tenant_id en cada request sin consultar BD. <br/><br/> **Alternativa:** Almacenar tenant_id en session storage si no usas JWT. | MT-009 |
| API-11 | `[ ]` Auditar que los secrets de JWT no estén hardcodeados. | **Comando de auditoría:** <br/> `grep -rn "jwt.sign" *.js | grep -v "process.env"` <br/><br/> **Resultado esperado:** Vacío. <br/><br/> **✅ Correcto:** <br/> ```javascript<br/>const secret = process.env.JWT_SECRET;<br/>``` <br/><br/> **¿Por qué?** Secrets hardcodeados pueden filtrarse en repositorios. <br/><br/> **Alternativa:** Usar servicios de secrets management (HashiCorp Vault, AWS Secrets Manager). | SEG-002 |
| API-12 | `[ ]` Comprobar que exista revocación de tokens (blacklist o whitelist). | **Ejemplo de implementación con Redis:** <br/> ```javascript<br/>// Revocar token<br/>await redis.setex(`revoked:${tokenId}`, expirationTime, 'true');<br/><br/>// Validar si está revocado<br/>const isRevoked = await redis.get(`revoked:${tokenId}`);<br/>if (isRevoked) {<br/>  throw new Error('Token has been revoked');<br/>}<br/>``` <br/><br/> **¿Por qué?** Permite invalidar tokens antes de su expiración natural (ej. logout, compromiso de seguridad). <br/><br/> **Alternativa:** Usar tokens de corta duración (15 min) y refresh tokens para minimizar ventana de riesgo. | SEG-007 |

### 8.4 Validación de Payloads y Sanitización

| ID | Check | Ejemplo de Verificación | REF |
|:---|:------|:------------------------|:----|
| API-13 | `[ ]` Todos los endpoints validan schema de payloads entrantes. | **Ejemplo con JSON Schema:** <br/> ```javascript<br/>const Ajv = require('ajv');<br/>const ajv = new Ajv();<br/><br/>const schema = {<br/>  type: 'object',<br/>  properties: {<br/>    email: { type: 'string', format: 'email' },<br/>    age: { type: 'integer', minimum: 0 }<br/>  },<br/>  required: ['email']<br/>};<br/><br/>const validate = ajv.compile(schema);<br/>if (!validate(payload)) {<br/>  return res.status(400).json({ errors: validate.errors });<br/>}<br/>``` <br/><br/> **¿Por qué?** Previene payloads malformados que causan errores o exploits. <br/><br/> **Alternativa:** Usar librerías como Joi, Yup, o Zod para validación más expresiva. | API-008 |
| API-14 | `[ ]` Verificar que se saniticen inputs para prevenir XSS e inyección. | **Ejemplo de sanitización:** <br/> ```javascript<br/>const DOMPurify = require('isomorphic-dompurify');<br/><br/>// Sanitizar HTML<br/>const cleanHtml = DOMPurify.sanitize(userInput);<br/><br/>// Escapar para SQL (mejor usar prepared statements)<br/>const escaped = mysql.escape(userInput);<br/>``` <br/><br/> **¿Por qué?** Inputs sin sanitizar permiten XSS, SQL injection, y otros ataques. <br/><br/> **Alternativa:** Usar ORMs y template engines que saniticen automáticamente. | SEG-006 |
| API-15 | `[ ]` Auditar que los límites de tamaño de payload estén configurados. | **Ejemplo en Express:** <br/> ```javascript<br/>app.use(express.json({ limit: '1mb' }));  // Max 1MB por request<br/>``` <br/><br/> **¿Por qué?** Payloads muy grandes pueden causar DDoS o agotar memoria. <br/><br/> **Alternativa:** Configurar límite en nginx/Caddy antes de llegar a la app. | RES-010 |
| API-16 | `[ ]` Comprobar que las respuestas filtren campos sensibles. | **Ejemplo de filtrado:** <br/> ```javascript<br/>// ❌ Incorrecto: Devuelve campos sensibles<br/>res.json(user);<br/><br/>// ✅ Correcto: Solo campos públicos<br/>const { password, apiKey, ...publicUser } = user;<br/>res.json(publicUser);<br/>``` <br/><br/> **¿Por qué?** Respuestas con campos sensibles pueden filtrar credenciales. <br/><br/> **Alternativa:** Usar DTOs (Data Transfer Objects) o serializers. | SEG-008 |

---

## 9. Validación de Agentes de Monitorización de VPS (NUEVA SECCIÓN)

**¿Qué validamos aquí?** Los agentes de monitorización supervisan salud, performance y seguridad del VPS. Debemos garantizar que estén configurados correctamente y no consuman recursos excesivos.

**¿Por qué es importante?** Sin monitorización, no detectamos problemas hasta que es demasiado tarde (server caído, disco lleno, intrusión).

### 9.1 Prometheus + Grafana

**¿Qué es?** Prometheus recolecta métricas de sistemas y aplicaciones. Grafana visualiza esas métricas en dashboards.

**¿Por qué usarlo?** Es el estándar de facto para monitorización en contenedores Docker y Kubernetes.

**¿Alternativas?** Netdata (más simple, all-in-one), Zabbix (más enterprise), Datadog/New Relic (SaaS).

| ID | Check | Ejemplo de Verificación | REF |
|:---|:------|:------------------------|:----|
| PROM-01 | `[ ]` Prometheus está instalado y corriendo en el VPS. | **Comando de verificación:** <br/> `docker ps | grep prometheus` <br/><br/> **O si está instalado nativo:** <br/> `systemctl status prometheus` <br/><br/> **Acceso a UI:** <br/> `http://localhost:9090` <br/><br/> **¿Por qué?** Prometheus es el cerebro del sistema de monitorización. <br/><br/> **Alternativa:** Usar Prometheus managed en la nube (AWS Managed Prometheus, Grafana Cloud). | RES-011 |
| PROM-02 | `[ ]` Los exporters necesarios están configurados (node_exporter, cadvisor, mysql_exporter). | **Exporters recomendados para este proyecto:** <br/> - `node_exporter`: Métricas del OS (CPU, RAM, disco, red) <br/> - `cadvisor`: Métricas de contenedores Docker <br/> - `mysql_exporter`: Métricas de MySQL <br/> - `qdrant`: Endpoint `/metrics` nativo <br/><br/> **Comando de verificación:** <br/> ```bash<br/>curl -s http://localhost:9100/metrics | head  # node_exporter<br/>curl -s http://localhost:8080/metrics | head  # cadvisor<br/>``` <br/><br/> **¿Por qué?** Sin exporters, Prometheus no tiene qué recolectar. <br/><br/> **Alternativa:** Usar Telegraf como agente unificado de recolección. | RES-011 |
| PROM-03 | `[ ]` Verificar que los jobs de scraping estén configurados en `prometheus.yml`. | **Ejemplo de configuración:** <br/> ```yaml<br/>scrape_configs:<br/>  - job_name: 'node'<br/>    static_configs:<br/>      - targets: ['localhost:9100']<br/>  <br/>  - job_name: 'cadvisor'<br/>    static_configs:<br/>      - targets: ['localhost:8080']<br/>  <br/>  - job_name: 'mysql'<br/>    static_configs:<br/>      - targets: ['localhost:9104']<br/>``` <br/><br/> **Comando de validación:** <br/> `curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health}'` <br/><br/> **Resultado esperado:** Todos los targets con `health: "up"` <br/><br/> **¿Por qué?** Jobs configuran qué métricas recolectar y cada cuánto. <br/><br/> **Alternativa:** Usar service discovery (Consul, etcd) para auto-detectar targets. | RES-011 |
| PROM-04 | `[ ]` Comprobar que Grafana esté conectado a Prometheus como data source. | **Pasos de verificación en Grafana:** <br/> 1. Ir a Configuration → Data Sources <br/> 2. Verificar que exista Prometheus con URL `http://prometheus:9090` <br/> 3. Hacer clic en "Test" → Debe decir "Data source is working" <br/><br/> **Comando de verificación vía API:** <br/> ```bash<br/>curl -u admin:admin http://localhost:3000/api/datasources | jq<br/>``` <br/><br/> **¿Por qué?** Grafana necesita conectarse a Prometheus para visualizar métricas. <br/><br/> **Alternativa:** Usar Grafana Cloud que conecta automáticamente. | RES-012 |

### 9.2 Netdata

**¿Qué es?** Netdata es un sistema de monitorización all-in-one con dashboard web incorporado. Recolecta métricas cada segundo con overhead mínimo.

**¿Por qué usarlo?** Es el más fácil de instalar y usar para principiantes. No requiere configuración compleja.

**¿Alternativas?** Prometheus+Grafana (más flexible pero más complejo), Zabbix (para entornos enterprise).

| ID | Check | Ejemplo de Verificación | REF |
|:---|:------|:------------------------|:----|
| NETD-01 | `[ ]` Netdata está instalado y accesible vía web. | **Comando de instalación:** <br/> ```bash<br/>bash <(curl -Ss https://my-netdata.io/kickstart.sh)<br/>``` <br/><br/> **Comando de verificación:** <br/> `systemctl status netdata` <br/><br/> **Acceso a dashboard:** <br/> `http://VPS_IP:19999` <br/><br/> **¿Por qué?** Netdata corre como daemon del sistema. <br/><br/> **Alternativa:** Instalar vía Docker: `docker run -d --name=netdata netdata/netdata`. | RES-011 |
| NETD-02 | `[ ]` Verificar que Netdata esté recolectando métricas de Docker. | **En el dashboard de Netdata:** <br/> Ir a "Applications" → Debe aparecer sección "Docker containers" <br/><br/> **Comando de verificación:** <br/> ```bash<br/>curl -s http://localhost:19999/api/v1/charts | jq '.charts | keys[] | select(contains("docker"))'<br/>``` <br/><br/> **¿Por qué?** Permite monitorear cada contenedor individualmente. <br/><br/> **Alternativa:** Habilitar plugin manualmente en `/etc/netdata/python.d.conf`. | RES-011 |
| NETD-03 | `[ ]` Auditar que Netdata tenga alertas configuradas para métricas críticas. | **Archivo de configuración:** `/etc/netdata/health.d/` <br/><br/> **Ejemplo de alerta:** <br/> ```yaml<br/> alarm: disk_space_usage<br/>    on: disk.space<br/>  calc: $used * 100 / ($avail + $used)<br/> every: 1m<br/>  warn: $this > 80<br/>  crit: $this > 90<br/>  info: disk space usage<br/>``` <br/><br/> **Comando de verificación:** <br/> `curl -s http://localhost:19999/api/v1/alarms | jq '.alarms[] | select(.status != "CLEAR")'` <br/><br/> **¿Por qué?** Alertas proactivas previenen downtime. <br/><br/> **Alternativa:** Integrar con servicios de notificación (Slack, email, PagerDuty). | RES-012 |
| NETD-04 | `[ ]` Comprobar que Netdata esté configurado con autenticación si es accesible desde Internet. | **Configuración recomendada en `/etc/netdata/netdata.conf`:** <br/> ```ini<br/>[web]<br/>  bind to = 127.0.0.1  # Solo localhost<br/>``` <br/><br/> **Si necesitas acceso remoto:** <br/> ```ini<br/>[web]<br/>  allow connections from = 10.0.0.0/8  # Solo red privada<br/>``` <br/><br/> **O usar reverse proxy con autenticación:** <br/> ```nginx<br/>location /netdata/ {<br/>    auth_basic "Restricted";<br/>    auth_basic_user_file /etc/nginx/.htpasswd;<br/>    proxy_pass http://localhost:19999/;<br/>}<br/>``` <br/><br/> **¿Por qué?** Netdata sin auth expone métricas sensibles del sistema. <br/><br/> **Alternativa:** Usar Netdata Cloud que maneja autenticación automáticamente. | SEG-001 |

### 9.3 Zabbix

**¿Qué es?** Zabbix es una plataforma de monitorización enterprise con capacidades avanzadas de alertas, inventario y reportes.

**¿Por qué usarlo?** Para entornos con muchos servidores que necesitan monitorización centralizada y reportes detallados.

**¿Alternativas?** Prometheus+Grafana (más moderno), Nagios (más antiguo), PRTG (Windows-centric).

| ID | Check | Ejemplo de Verificación | REF |
|:---|:------|:------------------------|:----|
| ZBX-01 | `[ ]` Zabbix Server está instalado y corriendo. | **Instalación vía Docker:** <br/> ```bash<br/>docker run -d --name zabbix-server \<br/>  -e DB_SERVER_HOST="mysql-server" \<br/>  -e MYSQL_USER="zabbix" \<br/>  -e MYSQL_PASSWORD="zabbix_pwd" \<br/>  -p 10051:10051 \<br/>  zabbix/zabbix-server-mysql<br/>``` <br/><br/> **Comando de verificación:** <br/> `docker logs zabbix-server | grep "server started"` <br/><br/> **¿Por qué?** Zabbix Server procesa métricas de los agentes. <br/><br/> **Alternativa:** Instalación nativa vía APT/YUM en Ubuntu/CentOS. | RES-011 |
| ZBX-02 | `[ ]` Zabbix Agent está instalado en cada VPS a monitorear. | **Instalación del agente:** <br/> ```bash<br/>docker run -d --name zabbix-agent \<br/>  -e ZBX_HOSTNAME="vps-saopaulo-1" \<br/>  -e ZBX_SERVER_HOST="zabbix-server" \<br/>  -p 10050:10050 \<br/>  zabbix/zabbix-agent<br/>``` <br/><br/> **Comando de verificación:** <br/> `zabbix_agentd -t agent.ping` <br/><br/> **Respuesta esperada:** `agent.ping [m|1]` <br/><br/> **¿Por qué?** El agente recolecta métricas del VPS y las envía al servidor. <br/><br/> **Alternativa:** Usar Zabbix Proxy para entornos distribuidos geográficamente. | RES-011 |
| ZBX-03 | `[ ]` Verificar que los hosts estén registrados en Zabbix con templates apropiados. | **En Zabbix UI:** <br/> Configuration → Hosts → Verificar que aparezcan todos los VPS <br/><br/> **Templates recomendados:** <br/> - Template OS Linux <br/> - Template App MySQL <br/> - Template App Docker <br/><br/> **Comando vía API:** <br/> ```bash<br/>curl -X POST -H "Content-Type: application/json" \<br/>  -d '{"jsonrpc":"2.0","method":"host.get","params":{"output":"extend"},"id":1,"auth":"TOKEN"}' \<br/>  http://zabbix-server/api_jsonrpc.php<br/>``` <br/><br/> **¿Por qué?** Templates definen qué métricas recolectar y qué triggers crear. <br/><br/> **Alternativa:** Crear templates custom para aplicaciones específicas. | RES-011 |
| ZBX-04 | `[ ]` Comprobar que las alertas (triggers) estén configuradas y funcionando. | **Triggers críticos recomendados:** <br/> - CPU usage > 90% por 5 minutos <br/> - RAM usage > 90% <br/> - Disk usage > 85% <br/> - MySQL no responde <br/> - Docker container stopped <br/><br/> **Test de trigger:** <br/> 1. Simular condición (ej. llenar disco) <br/> 2. Verificar que se active alerta en Monitoring → Problems <br/><br/> **Integración con notificaciones:** <br/> Administration → Media Types → Email/Slack/Telegram <br/><br/> **¿Por qué?** Alertas permiten respuesta rápida a incidentes. <br/><br/> **Alternativa:** Usar webhooks para integrar con sistemas de ticketing (Jira, ServiceNow). | RES-012 |

### 9.4 Métricas Comunes a Monitorear (Todas las Herramientas)

| ID | Check | Ejemplo de Verificación | REF |
|:---|:------|:------------------------|:----|
| MON-01 | `[ ]` Uso de CPU no debe exceder 80% sostenido. | **Comando de verificación:** <br/> `top -bn1 | grep "Cpu(s)"` <br/><br/> **O en contenedores Docker:** <br/> `docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}"` <br/><br/> **¿Por qué?** CPU al 100% causa lentitud y timeouts. <br/><br/> **Alternativa:** Configurar alerta cuando avg(CPU_5min) > 80%. | RES-001 |
| MON-02 | `[ ]` Uso de RAM no debe exceder 85% para dejar margen de cache. | **Comando de verificación:** <br/> `free -m | awk 'NR==2{printf "Memory Usage: %.2f%%\n", $3*100/$2 }'` <br/><br/> **¿Por qué?** Linux usa RAM libre para cache; < 15% libre es crítico. <br/><br/> **Alternativa:** Monitorear `available` en vez de `free` (más preciso). | RES-001 |
| MON-03 | `[ ]` Uso de disco no debe exceder 80% en ninguna partición. | **Comando de verificación:** <br/> `df -h | awk '$5+0 > 80 {print $0}'` <br/><br/> **¿Por qué?** Disco lleno causa errores en escritura de logs, BD, etc. <br/><br/> **Alternativa:** Configurar log rotation y limpieza automática de archivos temporales. | RES-010 |
| MON-04 | `[ ]` Latencia de red debe ser < 100ms a servicios externos críticos. | **Comando de verificación:** <br/> ```bash<br/>ping -c 10 api.openai.com | tail -1 | awk '{print $4}' | cut -d'/' -f2<br/>``` <br/><br/> **¿Por qué?** Alta latencia afecta experiencia de usuario en RAG. <br/><br/> **Alternativa:** Usar `mtr` para traceroute continuo. | API-005 |

---

## 10. Checklist de Despliegue Final

**Antes de poner en producción un nuevo componente, verificar:**

| Paso | Check | Herramienta |
|:-----|:------|:------------|
| 1 | `[ ]` Ejecutar script de validación SDD | `./validate-against-specs.sh` |
| 2 | `[ ]` Revisar todos los checks marcados en este documento | Manual |
| 3 | `[ ]` Verificar que tenant_id esté en TODOS los flujos de datos | grep -r "tenant_id" |
| 4 | `[ ]` Comprobar que los límites de recursos estén configurados | docker inspect, docker-compose.yml |
| 5 | `[ ]` Validar que no haya puertos expuestos a 0.0.0.0 | docker ps, ufw status |
| 6 | `[ ]` Ejecutar tests de integración | Jest, Pytest, Postman |
| 7 | `[ ]` Configurar monitorización y alertas | Prometheus/Netdata/Zabbix |
| 8 | `[ ]` Documentar cambios y actualizar README | Git commit |
| 9 | `[ ]` Crear backup antes del deploy | ./backup.sh |
| 10 | `[ ]` Deploy gradual (1 VPS → validar → resto) | Manual |

---

## 📚 Recursos Adicionales para Estudiantes

### Glosarios y Conceptos

- **API (Application Programming Interface):** Interfaz que permite que dos aplicaciones se comuniquen.
- **Docker:** Plataforma para ejecutar aplicaciones en contenedores aislados.
- **JWT (JSON Web Token):** Token encriptado que contiene información del usuario para autenticación.
- **Multi-tenancy:** Arquitectura donde múltiples clientes comparten la misma infraestructura.
- **n8n:** Herramienta de automatización de workflows (flujos de trabajo).
- **Qdrant:** Base de datos vectorial para búsquedas semánticas.
- **RAG (Retrieval-Augmented Generation):** Técnica de IA que combina búsqueda de documentos con generación de texto.
- **RLS (Row Level Security):** Seguridad a nivel de filas en bases de datos (Postgres/Supabase).
- **SDD (Specification-Driven Development):** Metodología donde defines reglas primero, luego validas el código.
- **tenant_id:** Identificador único de cliente para aislar datos en sistemas multi-tenant.

### Comandos Útiles de Referencia Rápida

```bash
# Docker
docker ps                          # Listar contenedores activos
docker stats                       # Uso de recursos en tiempo real
docker logs <container>            # Ver logs de un contenedor
docker inspect <container>         # Detalles de configuración

# Sistema
top                                # Procesos y uso de CPU/RAM
df -h                              # Uso de disco
netstat -tlnp                      # Puertos abiertos
ufw status                         # Estado del firewall

# Base de datos
mysql -u user -p -e "SHOW DATABASES;"  # Listar bases de datos
psql -U user -d db -c "\dt"            # Listar tablas en PostgreSQL

# Validación
curl -I https://api.example.com    # Headers de respuesta HTTP
jq '.field' file.json              # Parsear JSON
grep -r "pattern" .                # Buscar texto en archivos
```

---

**Fin del Checklist de Validación SDD v3.0**

**Siguiente paso:** Leer el archivo complementario `documentation-validation-checklist.txt` para entender cómo navegar la documentación del proyecto y aplicar estas validaciones en contexto.

**Nota importante para estudiantes:** Este checklist es extenso porque cubre TODOS los aspectos de un sistema productivo. No es necesario memorizarlo todo. Úsalo como referencia y consulta la sección relevante cuando trabajes en ese componente específico.
