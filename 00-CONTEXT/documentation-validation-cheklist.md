# ==============================================================================
# DOCUMENTACIÓN DE NAVEGACIÓN Y APRENDIZAJE PARA ESTUDIANTES
# MANTIS AGENTIC SDD v3.0
# ==============================================================================
# Archivo: documentation-validation-checklist.txt
# Propósito: Guía educativa completa para estudiantes de sistemas que necesitan
#            entender la metodología SDD, los constraints del proyecto, y cómo
#            validar cada componente de la infraestructura agéntica.
# Nivel: AVANZADO - Incluye QUÉ es cada concepto, POR QUÉ es importante, y
#        ALTERNATIVAS disponibles en la industria.
# ==============================================================================

---
# FRONTMATTER YAML (para parseo automático por herramientas)
title: "Guía de Navegación y Aprendizaje IA/Humano - MANTIS AGENTIC"
version: "3.0.0"
last_updated: "2026-04-09"
status: "production"
category: "education-documentation"
validation_status: "passed"
auto_validate: false
spec_version: "SDD v1.0"
description: >
  Documentación educativa completa que explica cada aspecto del proyecto
  MANTIS AGENTIC para estudiantes de sistemas. Incluye conceptos, razones,
  y alternativas para cada tecnología y práctica de validación.
audience: "Estudiantes de sistemas, desarrolladores junior, IAs asistentes"
learning_objectives:
  - "Entender la metodología SDD y su importancia"
  - "Comprender constraints de hardware y su impacto en arquitectura"
  - "Aprender validación de seguridad multi-tenant"
  - "Dominar herramientas de monitorización y debugging"
---

# ==============================================================================
# [SECCIÓN 0] INTRODUCCIÓN PARA ESTUDIANTES
# ==============================================================================

## ¿Qué es este proyecto?

MANTIS AGENTIC es una **infraestructura agéntica multi-tenant** diseñada para
automatizar conversaciones de WhatsApp en pequeños negocios de Brasil.

**Desglosando los términos:**

### Infraestructura Agéntica
- **QUÉ ES:** Sistema donde múltiples "agentes" (programas autónomos) trabajan
  juntos para completar tareas complejas.
- **POR QUÉ:** Permite escalabilidad. Cada agente hace una cosa bien (ej: RAG,
  CRM, notificaciones) en vez de un monolito que hace todo.
- **ALTERNATIVAS:** 
  - Microservicios (más granulares)
  - Monolitos (más simples pero no escalan)
  - Serverless functions (AWS Lambda, Cloudflare Workers)

### Multi-tenant
- **QUÉ ES:** Un solo sistema sirve a múltiples clientes (tenants) manteniendo
  sus datos completamente separados.
- **POR QUÉ:** Es más económico correr 1 servidor para 100 clientes que 100
  servidores separados.
- **ALTERNATIVAS:**
  - Single-tenant: Cada cliente tiene su propio servidor (más seguro, más caro)
  - Database-per-tenant: Cada cliente tiene su propia BD (balance)
  - Schema-per-tenant: Cada cliente tiene su propio schema en misma BD

### Metodología SDD (Specification-Driven Development)
- **QUÉ ES:** Primero defines reglas claras (specs), luego escribes código que
  las cumple, y finalmente validas automáticamente el cumplimiento.
- **POR QUÉ:** Previene bugs, facilita colaboración con IAs, y garantiza
  consistencia en proyectos grandes.
- **ALTERNATIVAS:**
  - TDD (Test-Driven Development): Escribes tests primero
  - BDD (Behavior-Driven Development): Describes comportamiento esperado
  - Waterfall: Plan completo antes de empezar (anticuado)

---

## ¿Qué son los Constraints (C1-C6)?

Los constraints son **restricciones técnicas NO NEGOCIABLES** del proyecto.
Son límites absolutos de hardware, seguridad y arquitectura que NUNCA deben
violarse.

### C1: Máximo 4GB RAM por VPS

**QUÉ SIGNIFICA:**
Cada servidor virtual (VPS) tiene solo 4 GB de memoria RAM disponible.

**POR QUÉ ES IMPORTANTE:**
- El presupuesto del proyecto solo permite VPS económicos
- Exceder RAM causa swap (disco como RAM), que es 1000x más lento
- El servidor puede crashear si se queda sin memoria

**CÓMO VALIDARLO:**
```bash
# Ver RAM total del sistema
free -h

# Ver uso de RAM por contenedor Docker
docker stats --no-stream
```

**ALTERNATIVAS EN LA INDUSTRIA:**
- Kubernetes con auto-scaling (escala automáticamente cuando necesita más RAM)
- Serverless (paga solo por ejecución, RAM ilimitada)
- Clusters con balanceo (distribuye carga entre múltiples servidores)

**EJEMPLO PRÁCTICO:**
Si tienes 3 contenedores (n8n, MySQL, Qdrant) en 4GB de RAM:
- n8n: 1.5 GB
- MySQL: 1.5 GB
- Qdrant: 800 MB
- Sistema operativo: 200 MB
Total = 4 GB ✅

Si agregaras otro contenedor grande, excederías el límite ❌

---

### C2: Máximo 1 vCPU por contenedor crítico

**QUÉ SIGNIFICA:**
Cada contenedor puede usar como máximo 1 núcleo de CPU completo.

**POR QUÉ ES IMPORTANTE:**
- Los VPS solo tienen 1-2 vCPUs totales
- Sin límites, un contenedor puede acaparar toda la CPU
- Otros servicios se quedarían sin recursos y fallarían

**CÓMO VALIDARLO:**
```bash
# Ver límites de CPU configurados
docker inspect <container> --format='{{.HostConfig.NanoCpus}}'

# 1 vCPU = 1000000000 nanocpus
# 0.5 vCPU = 500000000 nanocpus
```

**ALTERNATIVAS EN LA INDUSTRIA:**
- CPU pinning: Asigna CPUs específicos a cada proceso
- cgroups v2: Control más granular de recursos
- Prioridades de procesos (nice values)

**EJEMPLO PRÁCTICO:**
Un contenedor sin límite puede usar 100% de CPU durante un proceso pesado,
dejando sin recursos a MySQL. Resultado: queries lentas, timeouts, usuarios
frustrados.

Con límite de 1 vCPU, ese contenedor nunca puede pasar de 100%, dejando espacio
para otros servicios.

---

### C3: Bases de datos NO expuestas a Internet (0.0.0.0)

**QUÉ SIGNIFICA:**
MySQL y Qdrant solo deben ser accesibles desde el mismo servidor (localhost),
nunca desde Internet.

**POR QUÉ ES IMPORTANTE:**
- Exponer MySQL a Internet invita ataques de fuerza bruta
- Bots escanean constantemente puertos comunes (3306 para MySQL)
- Una sola contraseña débil puede resultar en robo masivo de datos

**CÓMO VALIDARLO:**
```bash
# Ver qué puertos están expuestos
docker ps --format "table {{.Names}}\t{{.Ports}}"

# ✅ CORRECTO (solo localhost):
# mysql  127.0.0.1:3306->3306/tcp

# ❌ INCORRECTO (Internet completo):
# mysql  0.0.0.0:3306->3306/tcp
```

**ALTERNATIVAS EN LA INDUSTRIA:**
- VPNs: Acceso remoto seguro vía túnel encriptado
- Bastion hosts: Servidor intermedio que hace de puerta segura
- Cloud databases con IAM: Autenticación por identidad (AWS RDS, Supabase)

**EJEMPLO PRÁCTICO:**
Imagina que expones MySQL a Internet con contraseña "admin123".
Un bot lo encuentra en 3 horas, entra, descarga todos los datos de clientes,
y los vende en la dark web. Tu negocio está arruinado y puedes ir a la cárcel
por violación de LGPD (ley de protección de datos de Brasil).

Con C3, el bot ni siquiera puede VER el puerto MySQL desde fuera. Está
completamente invisible.

---

### C4: tenant_id OBLIGATORIO en todas las queries, logs, payloads

**QUÉ SIGNIFICA:**
Cada dato en el sistema DEBE tener un identificador único de cliente (tenant_id).
Toda operación (SELECT, INSERT, búsqueda en Qdrant, etc.) DEBE filtrar por
tenant_id.

**POR QUÉ ES IMPORTANTE:**
Es el pilar fundamental del multi-tenancy. Sin esto, un cliente puede ver datos
de otro cliente.

**CÓMO VALIDARLO:**
```sql
-- ❌ INCORRECTO: Sin tenant_id
SELECT * FROM messages WHERE chat_id = '123';

-- ✅ CORRECTO: Con tenant_id
SELECT * FROM messages WHERE tenant_id = 'restaurant_456' AND chat_id = '123';
```

**ALTERNATIVAS EN LA INDUSTRIA:**
- Database-per-tenant: Cada cliente tiene su propia BD (aislamiento perfecto)
- Schema-per-tenant: Cada cliente tiene su schema en misma BD
- Row Level Security (RLS): La BD aplica filtros automáticamente (Supabase)

**EJEMPLO PRÁCTICO:**
Restaurante A (tenant_id: 'restaurant_001') pregunta: "¿Cuántos pedidos tengo?"

Sin tenant_id:
```sql
SELECT COUNT(*) FROM orders;  -- Devuelve 50,000 (todos los restaurantes)
```

Con tenant_id:
```sql
SELECT COUNT(*) FROM orders WHERE tenant_id = 'restaurant_001';  -- Devuelve 120
```

La primera query es un bug crítico que expone datos de competidores.
La segunda es correcta y segura.

---

### C5: Backup diario encriptado con SHA256 de integridad

**QUÉ SIGNIFICA:**
Cada día se debe crear una copia de seguridad de todos los datos, encriptada
con AES-256, y validada con un checksum SHA256.

**POR QUÉ ES IMPORTANTE:**
- Discos fallan (estadística: 2-4% anual)
- Errores humanos borran datos
- Ransomware puede encriptar tu servidor
- Regulaciones (LGPD) requieren capacidad de recuperación

**CÓMO VALIDARLO:**
```bash
# Crear backup encriptado
tar -czf - /var/lib/mysql | openssl enc -aes-256-cbc -salt -out backup.tar.gz.enc

# Generar checksum para verificar integridad
sha256sum backup.tar.gz.enc > backup.tar.gz.enc.sha256

# Verificar integridad antes de restaurar
sha256sum -c backup.tar.gz.enc.sha256
```

**ALTERNATIVAS EN LA INDUSTRIA:**
- Backups automáticos cloud (AWS S3 Glacier, Backblaze B2)
- Replicación en tiempo real (MySQL replication, PostgreSQL streaming)
- Snapshots de disco (LVM snapshots, Btrfs)
- Backup as a Service (Veeam, Duplicati)

**EJEMPLO PRÁCTICO:**
Un desarrollador ejecuta accidentalmente:
```sql
DELETE FROM customers;  -- Sin WHERE clause!
```

Sin backups: Has perdido a todos tus clientes. Negocio cerrado.

Con backups: Restauras el backup de ayer, pierdes solo 24h de datos. Tolerable.

El checksum SHA256 garantiza que el backup no esté corrupto antes de restaurar.

---

### C6: Sin modelos locales (ollama, localai); solo APIs cloud

**QUÉ SIGNIFICA:**
No se permite ejecutar modelos de IA (LLMs) localmente en los VPS. Solo usar
APIs externas (OpenRouter, Claude, GPT).

**POR QUÉ ES IMPORTANTE:**
- Modelos locales (ej. Llama 3 70B) necesitan 40+ GB de RAM
- Consumo de CPU es altísimo (1 vCPU no es suficiente)
- Violación de C1 y C2
- APIs cloud son más baratas que hardware necesario

**CÓMO VALIDARLO:**
```bash
# Buscar imágenes prohibidas
docker images | grep -iE "ollama|localai|llama"

# Buscar procesos sospechosos
ps aux | grep -iE "ollama|text-generation-webui"
```

**ALTERNATIVAS EN LA INDUSTRIA:**
- APIs cloud con modelos propios (OpenAI, Anthropic, Cohere)
- Modelos locales en hardware dedicado (servidores con GPUs A100)
- Modelos pequeños optimizados (DistilBERT, TinyLlama) para casos específicos

**EJEMPLO PRÁCTICO:**
Intentas correr Llama 3 70B localmente:
- Necesita 40 GB RAM (tienes 4 GB) ❌
- Necesita 8+ CPUs (tienes 1 vCPU) ❌
- Genera respuestas en 30 segundos (GPT-4 Turbo: 2 segundos) ❌

Costo en RAM/CPU para correr Llama localmente > Costo de APIs cloud.

La única razón para modelos locales es privacidad extrema (ej. datos médicos,
militares). En este proyecto, las APIs cloud son la opción correcta.

---

# ==============================================================================
# [SECCIÓN 1] NAVEGACIÓN DE DOCUMENTACIÓN POR TECNOLOGÍA
# ==============================================================================

Esta sección te guía a los archivos específicos según la tecnología con la
que estés trabajando. Usa esto como un mapa de navegación.

## [DOCKER] Contenedores y Recursos

### ¿Qué es Docker?
**DEFINICIÓN:** Plataforma que permite ejecutar aplicaciones en "contenedores"
aislados, como cajas separadas que comparten el mismo sistema operativo.

**ANALOGÍA:** Piensa en tu servidor como un edificio. Docker te permite dividir
ese edificio en apartamentos (contenedores) donde cada aplicación vive
independientemente pero comparte recursos (agua, electricidad = CPU, RAM).

**POR QUÉ USARLO:**
- Consistencia: "Funciona en mi máquina" deja de ser excusa
- Aislamiento: Un contenedor que crashea no afecta a otros
- Portabilidad: Mismo contenedor corre en laptop, VPS, o cloud

**ALTERNATIVAS:**
- Máquinas virtuales (VMs): Más pesadas, cada una tiene su propio OS
- LXC/LXD: Contenedores más ligeros pero menos portables
- Kubernetes: Orquestador de contenedores para escala masiva

### Archivos principales:
- **01-RULES/02-RESOURCE-GUARDRAILS.md**
  - Sección: "Límites de Memoria y CPU (RES-001, RES-002)"
  - Explica cómo configurar memory/cpu limits en docker-compose.yml
  
- **01-RULES/01-ARCHITECTURE-RULES.md**
  - Sección: "Puertos Seguros (SEG-005)"
  - Explica por qué no exponer puertos a 0.0.0.0

### Constraints aplicables:
- C1 (4GB RAM)
- C2 (1 vCPU)
- C3 (No exponer BDs)

### Comandos esenciales para aprender:
```bash
# Listar contenedores corriendo
docker ps

# Ver uso de recursos en tiempo real
docker stats

# Ver configuración de un contenedor
docker inspect <nombre_contenedor>

# Ver logs de un contenedor
docker logs <nombre_contenedor>

# Entrar a un contenedor (debugging)
docker exec -it <nombre_contenedor> bash
```

### Ejemplo práctico paso a paso:

**ESCENARIO:** Necesitas verificar que n8n no esté usando más de 1.5 GB RAM.

**PASO 1:** Ver uso actual
```bash
docker stats --no-stream n8n
```
Output esperado:
```
NAME   CPU %   MEM USAGE / LIMIT     MEM %
n8n    5.2%    1.2GiB / 1.5GiB      80%
```

**PASO 2:** Si está cerca del límite, investigar por qué
```bash
docker logs n8n | tail -100
```

**PASO 3:** Si es necesario, aumentar límite (pero sin exceder C1)
```yaml
services:
  n8n:
    deploy:
      resources:
        limits:
          memory: 1800M  # Nuevo límite
```

**PASO 4:** Reiniciar contenedor
```bash
docker-compose up -d n8n
```

---

## [N8N] Workflows y Automatización

### ¿Qué es n8n?
**DEFINICIÓN:** Herramienta de automatización de workflows (flujos de trabajo)
que conecta diferentes servicios sin código.

**ANALOGÍA:** n8n es como un director de orquesta. Coordina cuándo cada
instrumento (servicio) debe tocar: "MySQL, dame datos. Ahora Qdrant, busca
documentos. Ahora GPT, genera respuesta."

**POR QUÉ USARLO:**
- No-code/low-code: Desarrolladores junior pueden crear workflows complejos
- Integración fácil: 200+ nodos predefinidos (HTTP, MySQL, Qdrant, etc.)
- Self-hosted: Controlas tus datos (importante para LGPD)

**ALTERNATIVAS:**
- Zapier (SaaS, más fácil pero datos en cloud de terceros)
- Make.com (similar a Zapier)
- Apache Airflow (más técnico, para data engineers)
- Temporal.io (workflows con código, más flexible)

### Archivos principales:
- **04-WORKFLOWS/sdd-universal-assistant.json**
  - Ejemplo completo de workflow SDD-compliant
  
- **01-RULES/04-API-RELIABILITY-RULES.md**
  - Sección: "Nodos HTTP (API-001)"
  - Explica timeouts y manejo de errores

### Constraints aplicables:
- C4 (tenant_id obligatorio)
- API-001 (timeouts en HTTP requests)

### Conceptos importantes:

#### Nodos (Nodes)
**QUÉ SON:** Bloques funcionales que realizan acciones específicas.

**TIPOS:**
- **Trigger nodes:** Inician el workflow (webhook, schedule, manual)
- **Action nodes:** Realizan acciones (HTTP request, DB query, email)
- **Logic nodes:** Controlan flujo (IF, Switch, Loop)

#### Expresiones
**QUÉ SON:** Código JavaScript que accede a datos del workflow.

**EJEMPLO:**
```javascript
// Acceder a dato del nodo anterior
{{ $json.nombre }}

// Acceder a dato de nodo específico
{{ $node["Qdrant Search"].json.resultados }}

// Usar funciones
{{ new Date().toISOString() }}
```

### Ejemplo práctico paso a paso:

**ESCENARIO:** Crear un nodo HTTP que consulte OpenRouter con timeout y tenant_id.

**PASO 1:** Agregar nodo HTTP Request en n8n

**PASO 2:** Configurar parámetros:
```
URL: https://openrouter.ai/api/v1/chat/completions
Method: POST
Authentication: Bearer Token
Token: {{ $env.OPENROUTER_API_KEY }}
```

**PASO 3:** Agregar timeout en Options:
```
Timeout: 30000  (30 segundos)
```

**PASO 4:** Agregar tenant_id en headers:
```json
{
  "X-Tenant-Id": "{{ $json.tenant_id }}"
}
```

**PASO 5:** Configurar body:
```json
{
  "model": "anthropic/claude-3.5-sonnet",
  "messages": [
    {
      "role": "user",
      "content": "{{ $json.pregunta }}"
    }
  ]
}
```

**PASO 6:** Habilitar "Continue on Fail" para manejo de errores

**PASO 7:** Testear workflow con datos de prueba

---

## [SQL] Bases de Datos Relacionales

### ¿Qué es SQL?
**DEFINICIÓN:** Lenguaje para gestionar bases de datos relacionales (tablas
con filas y columnas).

**ANALOGÍA:** SQL es como Excel con superpoderes. En vez de hojas de cálculo
pequeñas, manejas millones de filas y puedes hacer búsquedas complejas en
milisegundos.

**POR QUÉ USARLO:**
- Datos estructurados: Clientes, pedidos, facturas tienen estructura clara
- ACID: Atomicidad, Consistencia, Aislamiento, Durabilidad (confiable)
- Estándar de la industria: Todo el mundo sabe SQL

**ALTERNATIVAS:**
- NoSQL (MongoDB, DynamoDB): Datos sin estructura fija
- Time-series DBs (InfluxDB, TimescaleDB): Métricas y logs
- Graph DBs (Neo4j): Relaciones complejas

### Archivos principales:
- **01-RULES/06-MULTITENANCY-RULES.md**
  - Sección: "Consultas con tenant_id (MT-001, MT-002)"
  
- **01-RULES/05-CODE-PATTERNS-RULES.md**
  - Sección: "Prepared Statements (PAT-002)"

### Constraints aplicables:
- C4 (tenant_id en TODAS las queries)

### Conceptos importantes:

#### Prepared Statements
**QUÉ SON:** Queries parametrizadas que separan código SQL de datos.

**POR QUÉ USARLOS:**
- Previenen SQL injection (uno de los ataques más comunes)
- Son más rápidos (la BD puede cachear el plan de ejecución)

**EJEMPLO:**
```javascript
// ❌ VULNERABLE a SQL injection
const query = `SELECT * FROM users WHERE email = '${userInput}'`;
// Si userInput = "'; DROP TABLE users; --"  ¡Borra toda la tabla!

// ✅ SEGURO con prepared statement
const query = 'SELECT * FROM users WHERE email = ?';
db.query(query, [userInput]);
// El userInput se trata como dato, nunca como código
```

#### Índices
**QUÉ SON:** Estructuras de datos que aceleran búsquedas en tablas grandes.

**ANALOGÍA:** Un índice en una BD es como el índice de un libro. Sin índice,
la BD debe leer todas las páginas (full table scan). Con índice, va directo
a la página correcta.

**EJEMPLO:**
```sql
-- Crear índice compuesto (tenant_id primero para multi-tenancy)
CREATE INDEX idx_tenant_chat ON messages(tenant_id, chat_id);

-- Query rápida gracias al índice
SELECT * FROM messages WHERE tenant_id = '123' AND chat_id = '456';
-- Sin índice: 5 segundos en tabla de 10M filas
-- Con índice: 0.01 segundos ✅
```

### Ejemplo práctico paso a paso:

**ESCENARIO:** Escribir una query segura para obtener pedidos de un restaurante.

**PASO 1:** Identificar qué datos necesitas
- tenant_id: 'restaurant_789'
- Pedidos de los últimos 7 días

**PASO 2:** Escribir query con tenant_id (C4) y prepared statement (PAT-002)
```sql
SELECT 
  order_id,
  customer_name,
  total_amount,
  created_at
FROM orders
WHERE 
  tenant_id = ?  -- Parámetro 1: Previene ver datos de otros tenants
  AND created_at > NOW() - INTERVAL 7 DAY  -- Últimos 7 días
ORDER BY created_at DESC
LIMIT 100;  -- Límite para no sobrecargar
```

**PASO 3:** Ejecutar con prepared statement en JavaScript/Node.js
```javascript
const query = `
  SELECT order_id, customer_name, total_amount, created_at
  FROM orders
  WHERE tenant_id = ? AND created_at > NOW() - INTERVAL 7 DAY
  ORDER BY created_at DESC
  LIMIT 100
`;

const results = await db.query(query, ['restaurant_789']);
```

**PASO 4:** Verificar que el índice esté optimizado
```sql
EXPLAIN SELECT ... FROM orders WHERE tenant_id = '...' ...;
-- Buscar "Using index" en el output
```

**PASO 5:** Si la query es lenta, crear índice
```sql
CREATE INDEX idx_tenant_date ON orders(tenant_id, created_at);
```

---

## [QDRANT] Base de Datos Vectorial

### ¿Qué es Qdrant?
**DEFINICIÓN:** Base de datos especializada en almacenar y buscar vectores
(arrays de números que representan el "significado" de un texto).

**ANALOGÍA:** Si SQL es una biblioteca donde buscas libros por título exacto,
Qdrant es una biblioteca donde dices "quiero libros sobre aventuras espaciales"
y te devuelve los 10 más relevantes, aunque no contengan esas palabras exactas.

**POR QUÉ USARLO:**
- Búsqueda semántica: Encuentra documentos por significado, no por palabras
- RAG (Retrieval-Augmented Generation): Alimenta LLMs con contexto relevante
- Rápido: Millones de vectores, búsquedas en milisegundos

**ALTERNATIVAS:**
- Pinecone (SaaS, más fácil pero datos en cloud de terceros)
- Weaviate (open source, similar a Qdrant)
- Milvus (más complejo, para big data)
- pgvector (extensión de PostgreSQL)

### Archivos principales:
- **01-RULES/06-MULTITENANCY-RULES.md**
  - Sección: "Filtro Obligatorio (MT-004, MT-005)"

### Constraints aplicables:
- C4 (tenant_id en payload y filtros)

### Conceptos importantes:

#### Vectores (Embeddings)
**QUÉ SON:** Representaciones numéricas del significado de un texto.

**EJEMPLO:**
```javascript
texto1 = "El perro ladra"
vector1 = [0.2, 0.8, 0.1, ..., 0.4]  // 1536 números

texto2 = "El can hace ruido"
vector2 = [0.21, 0.79, 0.11, ..., 0.39]  // Muy similar a vector1

texto3 = "Compré manzanas"
vector3 = [0.9, 0.1, 0.5, ..., 0.2]  // Muy diferente
```

Los vectores similares están "cerca" en espacio multi-dimensional.

#### Similitud Coseno
**QUÉ ES:** Medida de qué tan similar es el "ángulo" entre dos vectores.

**VALORES:**
- 1.0 = Idénticos
- 0.7-0.9 = Muy similares
- 0.5-0.7 = Algo relacionados
- <0.5 = Poco relacionados

#### Payload
**QUÉ ES:** Metadata asociada al vector (tenant_id, source, page, etc.).

**EJEMPLO:**
```json
{
  "id": "doc_123",
  "vector": [0.2, 0.8, ...],
  "payload": {
    "tenant_id": "restaurant_456",
    "text": "Política de devoluciones...",
    "source": "manual.pdf",
    "page": 12
  }
}
```

### Ejemplo práctico paso a paso:

**ESCENARIO:** Buscar documentos relevantes para responder "¿Cuál es la política
de devoluciones?" en un sistema RAG multi-tenant.

**PASO 1:** Generar embedding de la pregunta
```javascript
const pregunta = "¿Cuál es la política de devoluciones?";
const embedding = await openai.embeddings.create({
  model: "text-embedding-3-small",
  input: pregunta
});
const vectorPregunta = embedding.data[0].embedding;  // 1536 números
```

**PASO 2:** Buscar en Qdrant con filtro de tenant_id (C4)
```javascript
const results = await qdrantClient.search('mantis_docs', {
  vector: vectorPregunta,
  limit: 5,  // Top 5 resultados
  filter: {
    must: [
      {
        key: 'tenant_id',
        match: { keyword: 'restaurant_456' }  // Solo docs de este tenant
      }
    ]
  },
  score_threshold: 0.7  // Solo resultados con >70% similitud
});
```

**PASO 3:** Procesar resultados
```javascript
const contexto = results.map(r => r.payload.text).join('\n\n');
console.log(contexto);
// Output:
// "Política de devoluciones: Los clientes pueden devolver productos..."
// "En caso de devolución, se reembolsa el 100% si..."
```

**PASO 4:** Enviar contexto + pregunta al LLM
```javascript
const prompt = `
Contexto de la base de conocimientos:
${contexto}

Pregunta del usuario: ${pregunta}

Responde usando SOLO la información del contexto.
`;

const respuesta = await openai.chat.completions.create({
  model: "gpt-4",
  messages: [{ role: "user", content: prompt }]
});
```

**PASO 5:** Devolver respuesta al usuario
```javascript
console.log(respuesta.choices[0].message.content);
// Output inteligente basado en documentos reales del restaurante
```

---

## [API] Diseño y Validación de APIs

### ¿Qué es una API?
**DEFINICIÓN:** Application Programming Interface - Interfaz que permite que
dos aplicaciones se comuniquen.

**ANALOGÍA:** Una API es como un mesero en un restaurante. Tú (cliente) haces
un pedido, el mesero (API) lo lleva a la cocina (servidor), y te trae la comida
(respuesta). No necesitas saber cómo cocina el chef.

**POR QUÉ USARLAS:**
- Separación de responsabilidades: Frontend y backend independientes
- Reutilización: Una API puede servir a web, mobile, y chatbots
- Escalabilidad: Puedes tener múltiples servidores API

**ALTERNATIVAS:**
- GraphQL: Cliente pide exactamente lo que necesita (menos over-fetching)
- gRPC: Más rápido, binario en vez de JSON, ideal para microservicios
- WebSockets: Conexión bidireccional en tiempo real

### Archivos principales:
- **01-RULES/04-API-RELIABILITY-RULES.md**
  - Sección completa sobre timeouts, retries, fallbacks

### Conceptos importantes:

#### REST (Representational State Transfer)
**QUÉ ES:** Estilo de arquitectura para APIs que usa métodos HTTP estándar.

**MÉTODOS:**
- GET: Leer datos (idempotente, no modifica estado)
- POST: Crear recurso nuevo
- PUT/PATCH: Actualizar recurso existente
- DELETE: Eliminar recurso

**EJEMPLO:**
```
GET /api/v1/restaurants/123          → Obtener restaurante
POST /api/v1/restaurants              → Crear restaurante
PUT /api/v1/restaurants/123           → Actualizar restaurante completo
PATCH /api/v1/restaurants/123         → Actualizar campos específicos
DELETE /api/v1/restaurants/123        → Eliminar restaurante
```

#### Status Codes
**QUÉ SON:** Códigos numéricos que indican el resultado de una petición HTTP.

**CÓDIGOS IMPORTANTES:**
- 200 OK: Éxito
- 201 Created: Recurso creado exitosamente (POST)
- 204 No Content: Éxito sin contenido en respuesta (DELETE)
- 400 Bad Request: Datos inválidos enviados
- 401 Unauthorized: No autenticado (falta token)
- 403 Forbidden: Autenticado pero sin permisos
- 404 Not Found: Recurso no existe
- 429 Too Many Requests: Excedió rate limit
- 500 Internal Server Error: Error del servidor
- 503 Service Unavailable: Servidor sobrecargado o en mantenimiento

#### Rate Limiting
**QUÉ ES:** Límite de cuántas peticiones puede hacer un cliente en un período.

**POR QUÉ:**
- Previene abuso (ataques DDoS)
- Garantiza fair use (todos los clientes tienen recursos)
- Protege la BD de sobrecarga

**EJEMPLO:**
```
X-RateLimit-Limit: 1000       → Límite total
X-RateLimit-Remaining: 999    → Requests restantes
X-RateLimit-Reset: 1234567890 → Timestamp cuando resetea
```

### Ejemplo práctico paso a paso:

**ESCENARIO:** Diseñar un endpoint para crear pedidos con validación completa.

**PASO 1:** Definir ruta y método
```
POST /api/v1/orders
```

**PASO 2:** Definir autenticación
```javascript
// Middleware de autenticación
async function authenticate(req, res, next) {
  const token = req.headers.authorization?.replace('Bearer ', '');
  
  if (!token) {
    return res.status(401).json({ error: 'Token required' });
  }
  
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;  // { user_id, tenant_id, role }
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid token' });
  }
}
```

**PASO 3:** Validar schema del payload
```javascript
const Joi = require('joi');

const orderSchema = Joi.object({
  customer_id: Joi.string().required(),
  items: Joi.array().items(
    Joi.object({
      product_id: Joi.string().required(),
      quantity: Joi.number().integer().min(1).required(),
      price: Joi.number().positive().required()
    })
  ).min(1).required(),
  delivery_address: Joi.string().required(),
  notes: Joi.string().optional()
});

async function validateOrder(req, res, next) {
  const { error } = orderSchema.validate(req.body);
  if (error) {
    return res.status(400).json({ 
      error: 'Validation failed', 
      details: error.details 
    });
  }
  next();
}
```

**PASO 4:** Implementar rate limiting
```javascript
const rateLimit = require('express-rate-limit');

const createOrderLimiter = rateLimit({
  keyGenerator: (req) => req.user.tenant_id,  // Por tenant, no por IP
  max: 100,  // 100 pedidos
  windowMs: 60 * 1000,  // por minuto
  message: 'Too many orders, please try again later'
});
```

**PASO 5:** Implementar el handler con tenant_id (C4)
```javascript
app.post('/api/v1/orders', 
  authenticate, 
  validateOrder, 
  createOrderLimiter, 
  async (req, res) => {
    try {
      const orderData = {
        ...req.body,
        tenant_id: req.user.tenant_id,  // C4: Siempre incluir tenant_id
        created_by: req.user.user_id,
        status: 'pending'
      };
      
      const order = await db.orders.create(orderData);
      
      return res.status(201).json({
        success: true,
        order_id: order.id,
        message: 'Order created successfully'
      });
      
    } catch (error) {
      console.error('Error creating order:', error);
      return res.status(500).json({ 
        error: 'Internal server error',
        request_id: req.id  // Para debugging
      });
    }
  }
);
```

**PASO 6:** Agregar documentación con OpenAPI/Swagger
```yaml
/api/v1/orders:
  post:
    summary: Create a new order
    security:
      - BearerAuth: []
    requestBody:
      required: true
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/CreateOrderRequest'
    responses:
      '201':
        description: Order created successfully
      '400':
        description: Invalid request data
      '401':
        description: Unauthorized
      '429':
        description: Rate limit exceeded
      '500':
        description: Internal server error
```

---

## [MONITORIZACIÓN] Prometheus, Netdata, Zabbix

### ¿Qué es la Monitorización?
**DEFINICIÓN:** Proceso de recolectar, analizar y visualizar métricas de un
sistema para detectar problemas antes de que afecten a usuarios.

**ANALOGÍA:** Monitorización es como los indicadores de un coche (velocímetro,
temperatura, gasolina). Sin ellos, no sabes que algo anda mal hasta que el
motor explota.

**POR QUÉ ES CRÍTICA:**
- Detecta problemas antes de que causen downtime
- Permite optimizar recursos (identificar cuellos de botella)
- Provee datos para decisiones de escalado
- Cumple con SLAs (Service Level Agreements)

**MÉTRICAS ESENCIALES:**
- **CPU:** Procesamiento disponible
- **RAM:** Memoria disponible
- **Disco:** Espacio libre
- **Red:** Ancho de banda y latencia
- **Aplicación:** Requests/segundo, errores, latencia

### Comparación de Herramientas

| Característica | Prometheus + Grafana | Netdata | Zabbix |
|----------------|---------------------|---------|---------|
| **Complejidad** | Media | Baja | Alta |
| **Instalación** | Docker o nativo | Script de 1 línea | Múltiples componentes |
| **Curva de aprendizaje** | Media | Baja | Alta |
| **Uso de recursos** | Bajo-Medio | Muy bajo | Medio |
| **Alertas** | Sí (Alertmanager) | Sí (básicas) | Sí (avanzadas) |
| **Dashboards** | Grafana (muy flexibles) | Incorporados | Incorporados |
| **Retención de datos** | Configurable | 1 hora default | Configurable |
| **Multi-tenant** | Posible | No | Sí |
| **Mejor para** | DevOps, microservicios | Principiantes, debugging | Enterprise, IT ops |

### Prometheus + Grafana

**CUÁNDO USAR:**
- Tienes experiencia con Docker y YAML
- Necesitas alertas personalizadas complejas
- Quieres dashboards muy customizables
- Estás en ecosistema de microservicios/Kubernetes

**VENTAJAS:**
- Estándar de la industria
- Gran comunidad y documentación
- Integraciones con todo (Kubernetes, AWS, etc.)

**DESVENTAJAS:**
- Requiere configuración manual
- Curva de aprendizaje media

**ARQUITECTURA:**
```
[Aplicación] → [Exporter] → [Prometheus] → [Grafana]
                                ↓
                           [Alertmanager]
```

**INSTALACIÓN RÁPIDA:**
```bash
# docker-compose.yml
version: '3'
services:
  prometheus:
    image: prom/prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"
  
  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
```

### Netdata

**CUÁNDO USAR:**
- Eres principiante o quieres algo rápido
- Necesitas debugging en tiempo real
- Valoras facilidad sobre flexibilidad
- Solo monitorizas 1-5 servidores

**VENTAJAS:**
- Instalación de 1 línea
- Dashboard hermoso out-of-the-box
- Recolección cada 1 segundo (muy granular)
- Overhead mínimo (~1-2% CPU, 50-100MB RAM)

**DESVENTAJAS:**
- Retención de datos corta (1 hora default)
- Menos flexible que Prometheus+Grafana
- No ideal para multi-tenant

**INSTALACIÓN RÁPIDA:**
```bash
bash <(curl -Ss https://my-netdata.io/kickstart.sh)
# Listo! Dashboard en http://localhost:19999
```

### Zabbix

**CUÁNDO USAR:**
- Entorno enterprise (>50 servidores)
- Necesitas inventario de hardware
- Quieres reportes automáticos para management
- Ya usas Zabbix en tu empresa

**VENTAJAS:**
- Muy completo (monitorización, inventario, mapas)
- Auto-discovery de dispositivos
- Templates para 1000+ aplicaciones
- Historial de datos ilimitado

**DESVENTAJAS:**
- Complejo de configurar
- Interfaz web anticuada
- Consume más recursos

**ARQUITECTURA:**
```
[Zabbix Agent] → [Zabbix Server] → [Database]
                       ↓
                  [Zabbix Web UI]
```

### Ejemplo práctico paso a paso:

**ESCENARIO:** Configurar alertas para disco >80% usando Netdata.

**PASO 1:** Verificar que Netdata esté corriendo
```bash
systemctl status netdata
# Debería decir "active (running)"
```

**PASO 2:** Ir a configuración de alertas
```bash
cd /etc/netdata/health.d/
```

**PASO 3:** Crear archivo de alerta custom
```bash
nano disk_alerts.conf
```

**PASO 4:** Escribir configuración de alerta
```yaml
# Alerta de disco lleno
alarm: disk_space_critical
   on: disk.space
 calc: $used * 100 / ($avail + $used)
every: 1m
 warn: $this > 80
 crit: $this > 90
 info: Disk space usage is critically high
   to: sysadmin
```

**PASO 5:** Reiniciar Netdata
```bash
systemctl restart netdata
```

**PASO 6:** Verificar que la alerta esté activa
```bash
curl -s http://localhost:19999/api/v1/alarms | jq
```

**PASO 7:** Configurar notificación por email
```bash
nano /etc/netdata/health_alarm_notify.conf
```

```bash
# Email settings
SEND_EMAIL="YES"
DEFAULT_RECIPIENT_EMAIL="admin@example.com"
EMAIL_SENDER="netdata@servidor.com"
```

**PASO 8:** Testear alerta manualmente
```bash
# Llenar disco temporalmente para disparar alerta
dd if=/dev/zero of=/tmp/testfile bs=1M count=5000
```

**PASO 9:** Verificar que recibiste el email de alerta

**PASO 10:** Limpiar archivo de test
```bash
rm /tmp/testfile
```

---

# ==============================================================================
# [SECCIÓN 2] CONSTRAINTS PROFUNDIZADOS CON CASOS DE USO
# ==============================================================================

Esta sección explica cada constraint con ejemplos reales de qué pasa si NO
se respetan.

## Caso de Uso Real: Violación de C1 (4GB RAM)

### ESCENARIO:
Un desarrollador agrega un contenedor de Elasticsearch (motor de búsqueda)
sin configurar límites de memoria.

### ¿QUÉ PASA?

**HORA 0:** Elasticsearch arranca y usa 512 MB RAM (parece bien)

**HORA 1:** Llegan más datos, Elasticsearch crece a 2 GB RAM

**HORA 2:** Un usuario hace una búsqueda compleja, Elasticsearch pide 3 GB RAM

**HORA 2:05:** Sistema operativo no tiene suficiente RAM libre

**HORA 2:06:** Linux OOM Killer (Out Of Memory Killer) se activa

**HORA 2:07:** OOM Killer mata el proceso más grande... ¡MySQL!

**HORA 2:08:** Toda la aplicación cae porque MySQL está muerto

**HORA 2:09:** Clientes en WhatsApp reciben "Error: No podemos responder ahora"

**HORA 2:30:** Te despiertan a las 3 AM para arreglar el desastre

### CÓMO PREVENIR:

```yaml
# docker-compose.yml
services:
  elasticsearch:
    image: elasticsearch:8
    deploy:
      resources:
        limits:
          memory: 1200M  # Límite estricto
    environment:
      - "ES_JAVA_OPTS=-Xms1g -Xmx1g"  # Java heap también limitado
```

### LECCIÓN:
**SIEMPRE** configura límites de memoria. La memoria no usada no cuesta nada,
pero la memoria excedida destruye tu sistema.

---

## Caso de Uso Real: Violación de C3 (BDs expuestas)

### ESCENARIO:
Un junior expone MySQL a 0.0.0.0:3306 "temporalmente para hacer testing remoto".
Olvida cambiarlo antes de ir a producción.

### TIMELINE DEL DESASTRE:

**DÍA 1, 10:00 AM:** Deploy a producción con MySQL expuesto

**DÍA 1, 10:05 AM:** Bots de Shodan detectan puerto 3306 abierto

**DÍA 1, 11:30 AM:** Script automatizado intenta contraseñas comunes:
- admin/admin
- root/password
- mysql/mysql

**DÍA 1, 2:00 PM:** Ataque de fuerza bruta encuentra contraseña débil: "Password123"

**DÍA 1, 2:15 PM:** Atacante tiene acceso completo a MySQL

**DÍA 1, 2:20 PM:** Atacante descarga TODA la base de datos:
- 50,000 registros de clientes
- Números de teléfono
- Historial de pedidos
- Direcciones

**DÍA 1, 2:30 PM:** Atacante borra todas las tablas y deja una nota:
"Send 5 BTC to [address] or your data is gone forever"

**DÍA 2, 9:00 AM:** Te das cuenta del ransomware cuando clientes reportan que
no pueden acceder a sus cuentas

### COSTO REAL:
- Pérdida de todos los datos (si no hay backup)
- Multa de LGPD: Hasta R$ 50 millones (Brasil)
- Reputación destruida
- Posible proceso criminal
- Negocio cerrado

### CÓMO PREVENIR:

```yaml
# docker-compose.yml
services:
  mysql:
    image: mysql:8
    ports:
      - "127.0.0.1:3306:3306"  # Solo localhost, NUNCA 0.0.0.0
```

```bash
# Firewall adicional
sudo ufw deny 3306
sudo ufw status
```

### LECCIÓN:
Bases de datos NUNCA deben ser accesibles desde Internet. Punto. Sin excusas.
Usa VPN o SSH tunneling si necesitas acceso remoto.

---

## Caso de Uso Real: Violación de C4 (tenant_id omitido)

### ESCENARIO:
Un desarrollador hace una query rápida para debugging y olvida incluir tenant_id.

```sql
-- Query de debugging (SIN tenant_id)
SELECT COUNT(*) FROM messages;
```

Todo bien, es solo debugging... ¿O no?

### LO QUE REALMENTE PASÓ:

**VERSIÓN 1 (Copiar/Pegar Inocente):**
```javascript
// Developer copia la query de debugging a producción
app.get('/api/messages/count', async (req, res) => {
  const result = await db.query('SELECT COUNT(*) FROM messages');
  // ❌ Devuelve mensajes de TODOS los tenants
  res.json({ count: result[0].count });
});
```

**RESULTADO:**
- Restaurante A ve: 50,000 mensajes (pensando que son suyos)
- En realidad son mensajes de 100 restaurantes combinados
- Decisiones de negocio basadas en datos incorrectos
- Pérdida de confianza cuando se descubre el error

**VERSIÓN 2 (Más Grave - Leak de Datos):**
```javascript
// Developer olvida tenant_id en endpoint de búsqueda
app.get('/api/messages/search', async (req, res) => {
  const query = `SELECT * FROM messages WHERE content LIKE ?`;
  const results = await db.query(query, [`%${req.query.term}%`]);
  // ❌ Devuelve mensajes de TODOS los tenants
  res.json(results);
});
```

**RESULTADO:**
- Restaurante A busca "promoción"
- Ve mensajes de Restaurante B, C, D... que contienen "promoción"
- Información competitiva sensible expuesta
- Violación masiva de privacidad
- Demanda legal segura

### CÓMO PREVENIR:

**1. Middleware que valida tenant_id:**
```javascript
function requireTenantId(req, res, next) {
  if (!req.user || !req.user.tenant_id) {
    return res.status(403).json({ error: 'tenant_id required' });
  }
  req.tenant_id = req.user.tenant_id;  // Disponible en toda la request
  next();
}

app.use('/api', requireTenantId);  // Aplicar a TODAS las rutas
```

**2. Query helper que siempre incluye tenant_id:**
```javascript
function queryWithTenant(sql, params, tenantId) {
  // Inyectar tenant_id en la query
  const safeSQL = sql.replace('WHERE', `WHERE tenant_id = '${db.escape(tenantId)}' AND`);
  return db.query(safeSQL, params);
}

// Uso
const results = await queryWithTenant(
  'SELECT * FROM messages WHERE content LIKE ?',
  ['%promoción%'],
  req.tenant_id
);
```

**3. Linter que detecta queries sin tenant_id:**
```javascript
// ESLint custom rule
module.exports = {
  rules: {
    'require-tenant-id-in-queries': {
      create(context) {
        return {
          Literal(node) {
            if (typeof node.value === 'string' && 
                /SELECT .* FROM/.test(node.value) &&
                !/tenant_id/.test(node.value)) {
              context.report({
                node,
                message: 'Query must include tenant_id filter'
              });
            }
          }
        };
      }
    }
  }
};
```

### LECCIÓN:
tenant_id no es opcional. Es el fundamento de multi-tenancy. Automatiza la
validación porque confiar solo en desarrolladores no escala.

---

# ==============================================================================
# [SECCIÓN 3] FLUJO DE TRABAJO RECOMENDADO PARA ESTUDIANTES
# ==============================================================================

## Flujo para Implementar una Nueva Feature

### PASO 1: Entender el Requerimiento
**PREGUNTA:** ¿Qué necesita el usuario?
**EJEMPLO:** "Quiero que los clientes puedan cancelar pedidos dentro de 5 minutos"

### PASO 2: Identificar Constraints Aplicables
**PREGUNTA:** ¿Qué constraints C1-C6 aplican?
**EJEMPLO:**
- C4: ✅ Los pedidos tienen tenant_id
- API-001: ✅ Timeout en request de cancelación
- MT-001: ✅ Solo puede cancelar sus propios pedidos

### PASO 3: Leer Documentación Relevante
**ARCHIVOS A REVISAR:**
- 01-RULES/06-MULTITENANCY-RULES.md (para C4)
- 01-RULES/04-API-RELIABILITY-RULES.md (para timeouts)
- Este archivo (documentation-validation-checklist.txt) sección [SQL]

### PASO 4: Diseñar la Solución
**COMPONENTES:**
1. Endpoint API: `POST /api/v1/orders/:id/cancel`
2. Validación: Usuario debe ser dueño del pedido
3. Business logic: Solo si pedido es reciente (<5 min)
4. Base de datos: Update con tenant_id en WHERE

### PASO 5: Implementar con Comentarios de Spec
```javascript
/**
 * Cancel Order Endpoint
 * 
 * Constraints applied:
 * - C4 (MT-001): tenant_id filter in WHERE clause
 * - API-001: 30s timeout configured
 * - PAT-002: Prepared statement to prevent SQL injection
 * 
 * References:
 * - 01-RULES/06-MULTITENANCY-RULES.md#MT-001
 * - 01-RULES/04-API-RELIABILITY-RULES.md#API-001
 */
app.post('/api/v1/orders/:id/cancel', 
  authenticate,
  timeout(30000),  // API-001
  async (req, res) => {
    const { id } = req.params;
    const { tenant_id, user_id } = req.user;
    
    try {
      // Verificar que el pedido exista y pertenezca al tenant (C4)
      const order = await db.query(
        `SELECT * FROM orders 
         WHERE id = ? AND tenant_id = ? AND user_id = ?`,
        [id, tenant_id, user_id]  // PAT-002: Prepared statement
      );
      
      if (!order.length) {
        return res.status(404).json({ error: 'Order not found' });
      }
      
      // Verificar tiempo de creación (<5 min)
      const createdAt = new Date(order[0].created_at);
      const now = new Date();
      const diffMinutes = (now - createdAt) / 1000 / 60;
      
      if (diffMinutes > 5) {
        return res.status(400).json({ 
          error: 'Order can only be cancelled within 5 minutes of creation' 
        });
      }
      
      // Cancelar pedido
      await db.query(
        `UPDATE orders SET status = 'cancelled' 
         WHERE id = ? AND tenant_id = ?`,
        [id, tenant_id]  // C4: Incluir tenant_id en UPDATE también
      );
      
      return res.json({ 
        success: true, 
        message: 'Order cancelled successfully' 
      });
      
    } catch (error) {
      console.error('Error cancelling order:', error);
      return res.status(500).json({ error: 'Internal server error' });
    }
  }
);
```

### PASO 6: Validar Manualmente
**CHECKLIST:**
- [ ] tenant_id en todas las queries ✅
- [ ] Prepared statements usados ✅
- [ ] Timeout configurado ✅
- [ ] Manejo de errores presente ✅
- [ ] Status codes apropiados (404, 400, 500) ✅

### PASO 7: Escribir Tests
```javascript
describe('POST /api/v1/orders/:id/cancel', () => {
  it('should cancel order within 5 minutes', async () => {
    const order = await createTestOrder({ tenant_id: 'test_123' });
    
    const res = await request(app)
      .post(`/api/v1/orders/${order.id}/cancel`)
      .set('Authorization', `Bearer ${testToken}`)
      .expect(200);
    
    expect(res.body.success).toBe(true);
  });
  
  it('should reject cancellation after 5 minutes', async () => {
    const order = await createTestOrder({ 
      tenant_id: 'test_123',
      created_at: new Date(Date.now() - 6 * 60 * 1000)  // 6 min ago
    });
    
    const res = await request(app)
      .post(`/api/v1/orders/${order.id}/cancel`)
      .set('Authorization', `Bearer ${testToken}`)
      .expect(400);
  });
  
  it('should not allow cancelling other tenant orders (C4)', async () => {
    const order = await createTestOrder({ tenant_id: 'other_tenant' });
    
    const res = await request(app)
      .post(`/api/v1/orders/${order.id}/cancel`)
      .set('Authorization', `Bearer ${testToken}`)  // testToken has tenant_id=test_123
      .expect(404);  // No debe encontrar el pedido
  });
});
```

### PASO 8: Ejecutar Validador Automático
```bash
./05-CONFIGURATIONS/scripts/validate-against-specs.sh ./ -report validation.json
```

### PASO 9: Revisar Reporte
```bash
jq '.details.errors' validation.json
# Debe ser: []  (cero errores)
```

### PASO 10: Deploy Gradual
1. Deploy a staging
2. Ejecutar tests de integración
3. Monitorizar métricas (latencia, errores)
4. Si todo bien → Deploy a producción
5. Monitorizar 24h post-deploy

---

# ==============================================================================
# [SECCIÓN 4] TROUBLESHOOTING Y DEBUGGING
# ==============================================================================

## Problema: "Queries lentas en MySQL"

### DIAGNÓSTICO:

**PASO 1:** Identificar queries lentas
```sql
-- Habilitar slow query log
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 1;  -- Queries >1 segundo
SET GLOBAL slow_query_log_file = '/var/log/mysql/slow.log';
```

**PASO 2:** Revisar log
```bash
tail -f /var/log/mysql/slow.log
```

**PASO 3:** Analizar query problemática con EXPLAIN
```sql
EXPLAIN SELECT * FROM messages 
WHERE tenant_id = 'restaurant_123' 
AND created_at > '2026-01-01';
```

**PASO 4:** Interpretar EXPLAIN

| Columna | Valor Malo | Valor Bueno | Significado |
|---------|-----------|-------------|-------------|
| type | ALL | ref, range | ALL = full table scan (lento) |
| rows | 1,000,000 | 100 | Filas escaneadas |
| Extra | Using filesort | Using index | filesort es lento |

**PASO 5:** Crear índice si falta
```sql
CREATE INDEX idx_tenant_date ON messages(tenant_id, created_at);
```

**PASO 6:** Re-ejecutar EXPLAIN
```sql
EXPLAIN SELECT * FROM messages 
WHERE tenant_id = 'restaurant_123' 
AND created_at > '2026-01-01';
-- Ahora debería usar idx_tenant_date
```

### ALTERNATIVAS SI EL PROBLEMA PERSISTE:

**Opción A: Particionar tabla**
```sql
-- Particionar por tenant_id (solo si tienes MUCHOS tenants)
ALTER TABLE messages
PARTITION BY HASH(tenant_id)
PARTITIONS 10;
```

**Opción B: Cachear resultados**
```javascript
const redis = require('redis');
const client = redis.createClient();

async function getMessages(tenantId, startDate) {
  const cacheKey = `messages:${tenantId}:${startDate}`;
  
  // Intentar cache primero
  const cached = await client.get(cacheKey);
  if (cached) return JSON.parse(cached);
  
  // Si no está en cache, buscar en BD
  const results = await db.query(
    'SELECT * FROM messages WHERE tenant_id = ? AND created_at > ?',
    [tenantId, startDate]
  );
  
  // Guardar en cache por 5 minutos
  await client.setex(cacheKey, 300, JSON.stringify(results));
  
  return results;
}
```

**Opción C: Mover datos antiguos a tabla de archivo**
```sql
-- Crear tabla de archivo
CREATE TABLE messages_archive LIKE messages;

-- Mover mensajes >1 año
INSERT INTO messages_archive 
SELECT * FROM messages 
WHERE created_at < DATE_SUB(NOW(), INTERVAL 1 YEAR);

DELETE FROM messages 
WHERE created_at < DATE_SUB(NOW(), INTERVAL 1 YEAR);

-- messages ahora es más pequeña = más rápida
```

---

## Problema: "RAM del VPS llegando a 95%"

### DIAGNÓSTICO:

**PASO 1:** Ver qué está usando RAM
```bash
free -h
docker stats --no-stream
```

**PASO 2:** Identificar culpables
```bash
# Procesos que más usan RAM
ps aux --sort=-%mem | head -10

# Contenedores que más usan RAM
docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}" | sort -k2 -h -r
```

**PASO 3:** Revisar logs por memory leaks
```bash
# Buscar OutOfMemory errors
docker logs mysql 2>&1 | grep -i "out of memory"
docker logs n8n 2>&1 | grep -i "heap"
```

### SOLUCIONES:

**Opción A: Aumentar límites de swap**
```bash
# Crear swap de 2GB (solo emergencia, swap es lento)
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Hacer permanente
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

**Opción B: Reducir cache de MySQL**
```ini
# /etc/mysql/my.cnf
[mysqld]
innodb_buffer_pool_size = 512M  # Era 1G, reducir a 512M
query_cache_size = 0  # Deshabilitar si no se usa
table_open_cache = 64  # Reducir
```

**Opción C: Limpiar logs viejos**
```bash
# Rotar logs de Docker
docker system prune -a --volumes -f

# Limpiar logs del sistema
journalctl --vacuum-time=7d  # Mantener solo últimos 7 días

# Limpiar apt cache
sudo apt-get clean
sudo apt-get autoclean
```

**Opción D: Migrar a VPS con más RAM (último recurso)**
```bash
# Si nada funciona y C1 no es flexible, necesitas más RAM
# Proceso:
1. Crear backup completo
2. Provisionar nuevo VPS (8GB RAM)
3. Restaurar backup
4. Actualizar DNS
5. Monitorizar migración
```

---

## Problema: "Contenedor Docker no arranca"

### DIAGNÓSTICO:

**PASO 1:** Ver estado del contenedor
```bash
docker ps -a | grep <nombre>
```

**PASO 2:** Ver logs de error
```bash
docker logs <nombre> --tail 100
```

**PASO 3:** Inspeccionar configuración
```bash
docker inspect <nombre> | jq '.State'
```

### ERRORES COMUNES:

**Error: "port already in use"**
```bash
# Ver qué está usando el puerto
sudo lsof -i :3306

# Opción A: Matar el proceso
sudo kill -9 <PID>

# Opción B: Cambiar puerto en docker-compose.yml
ports:
  - "3307:3306"  # Cambiar de 3306 a 3307
```

**Error: "no space left on device"**
```bash
# Ver uso de disco
df -h

# Limpiar espacio
docker system prune -a -f --volumes
sudo apt-get autoremove
sudo journalctl --vacuum-size=100M
```

**Error: "health check failed"**
```yaml
# Revisar health check en docker-compose.yml
healthcheck:
  test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s  # Dar más tiempo inicial si BD es grande
```

---

# ==============================================================================
# [SECCIÓN 5] GLOSARIO TÉCNICO COMPLETO
# ==============================================================================

## A

**API (Application Programming Interface)**
- **QUÉ ES:** Conjunto de reglas que permiten comunicación entre aplicaciones
- **EJEMPLO:** Cuando tu app de clima pide datos a servidores de OpenWeather
- **ANALOGÍA:** Un mesero en restaurante (interfaz entre cliente y cocina)

**Autenticación**
- **QUÉ ES:** Proceso de verificar identidad ("¿Quién eres?")
- **EJEMPLOS:** Login con usuario/contraseña, JWT, OAuth, biometría
- **VS AUTORIZACIÓN:** Autenticación verifica identidad, autorización verifica permisos

## B

**Backup**
- **QUÉ ES:** Copia de seguridad de datos
- **TIPOS:**
  - Full: Copia completa de todo
  - Incremental: Solo cambios desde último backup
  - Differential: Cambios desde último full backup

**Bottleneck (Cuello de Botella)**
- **QUÉ ES:** Componente que limita performance del sistema completo
- **EJEMPLO:** CPU al 100% mientras RAM está al 20% → CPU es el bottleneck

## C

**Cache**
- **QUÉ ES:** Almacenamiento temporal de datos frecuentemente accedidos
- **BENEFICIO:** Reduce latencia y carga en DB
- **TIPOS:** L1/L2/L3 cache (CPU), Redis/Memcached (app), CDN (web)

**Container (Contenedor)**
- **QUÉ ES:** Paquete ligero que incluye app + dependencias
- **VS VM:** Contenedores comparten OS, VMs tienen OS separado
- **EJEMPLO:** Docker container con MySQL 8.0

**CPU (Central Processing Unit)**
- **QUÉ ES:** "Cerebro" de la computadora que ejecuta instrucciones
- **MEDICIÓN:** Porcentaje de uso, clock speed (GHz), cores

## D

**Database (Base de Datos)**
- **QUÉ ES:** Sistema organizado para almacenar y recuperar datos
- **TIPOS:**
  - Relational (SQL): MySQL, PostgreSQL
  - NoSQL: MongoDB, Redis, Cassandra
  - Vector: Qdrant, Pinecone, Weaviate

**Docker**
- **QUÉ ES:** Plataforma para crear y correr contenedores
- **COMPONENTES:**
  - Image: Template inmutable
  - Container: Instancia corriendo de una image
  - Volume: Almacenamiento persistente

## E

**Embedding (Vector Embedding)**
- **QUÉ ES:** Representación numérica del significado de texto/imagen
- **EJEMPLO:** "perro" → [0.2, 0.8, 0.1, ..., 0.4] (1536 números)
- **USO:** Búsqueda semántica, RAG, recomendaciones

**Endpoint**
- **QUÉ ES:** URL específica que realiza una función en una API
- **EJEMPLO:** `POST /api/v1/users` (crear usuario)

## F

**Firewall**
- **QUÉ ES:** Sistema que bloquea tráfico de red no autorizado
- **TIPOS:**
  - UFW (Ubuntu): Firewall simple para Linux
  - iptables: Firewall más avanzado
  - Cloud firewall: AWS Security Groups, GCP Firewall Rules

## H

**Hash**
- **QUÉ ES:** Función que convierte datos en string de longitud fija
- **PROPIEDADES:**
  - Determinista: Mismo input → mismo output
  - Irreversible: No puedes obtener input desde hash
  - Sensible: Cambio mínimo en input → hash completamente diferente
- **USOS:** Contraseñas, checksums, blockchain

**Health Check**
- **QUÉ ES:** Verificación automática de que un servicio está funcionando
- **EJEMPLO:** `GET /health` retorna `{"status": "ok"}`

## I

**Idempotente**
- **QUÉ ES:** Operación que produce mismo resultado si se ejecuta múltiples veces
- **EJEMPLOS:**
  - GET request: Leer datos (idempotente)
  - POST request: Crear recurso (NO idempotente)
  - PUT request: Actualizar recurso (idempotente)

**Index (Índice)**
- **QUÉ ES:** Estructura de datos que acelera búsquedas en BD
- **COSTO:** Escrituras más lentas, más espacio en disco
- **BENEFICIO:** Lecturas mucho más rápidas

## J

**JSON (JavaScript Object Notation)**
- **QUÉ ES:** Formato de texto para intercambiar datos
- **EJEMPLO:**
```json
{
  "nombre": "Juan",
  "edad": 30,
  "ciudad": "São Paulo"
}
```

**JWT (JSON Web Token)**
- **QUÉ ES:** Token encriptado que contiene claims (afirmaciones)
- **ESTRUCTURA:** `header.payload.signature`
- **USO:** Autenticación stateless en APIs

## L

**Latency (Latencia)**
- **QUÉ ES:** Tiempo que tarda una operación en completarse
- **MEDICIÓN:** Milisegundos (ms)
- **OBJETIVO:** <100ms para UX buena, <500ms tolerable

**Load Balancer**
- **QUÉ ES:** Distribuye tráfico entre múltiples servidores
- **BENEFICIO:** Alta disponibilidad, mejor performance
- **TIPOS:** Round-robin, least connections, IP hash

## M

**Memory Leak**
- **QUÉ ES:** Bug donde programa no libera memoria que ya no usa
- **SÍNTOMAS:** Uso de RAM crece constantemente hasta crashear
- **DETECCIÓN:** Monitorizar RAM over time

**Metadata**
- **QUÉ ES:** Datos sobre datos
- **EJEMPLO:** Para una foto: fecha, ubicación GPS, cámara usada

**Multi-tenancy**
- **QUÉ ES:** Arquitectura donde múltiples clientes comparten infraestructura
- **TIPOS:**
  - Shared database, shared schema
  - Shared database, separate schemas
  - Separate databases per tenant

## O

**ORM (Object-Relational Mapping)**
- **QUÉ ES:** Librería que traduce entre objetos de código y tablas de BD
- **EJEMPLOS:** Sequelize (Node.js), SQLAlchemy (Python), Prisma
- **BENEFICIO:** Escribes menos SQL, código más portable

## P

**Payload**
- **QUÉ ES:** Datos transmitidos en request/response
- **EJEMPLO:** Body de POST request con datos de nuevo usuario

**Port (Puerto)**
- **QUÉ ES:** Número que identifica un servicio en servidor
- **EJEMPLOS COMUNES:**
  - 80: HTTP
  - 443: HTTPS
  - 3306: MySQL
  - 6333: Qdrant

## Q

**Query**
- **QUÉ ES:** Petición de datos a una base de datos
- **SQL QUERY:** `SELECT * FROM users WHERE age > 18`
- **QDRANT QUERY:** Vector search con filtros

## R

**RAG (Retrieval-Augmented Generation)**
- **QUÉ ES:** Técnica de IA que combina búsqueda de documentos + LLM
- **FLUJO:**
  1. Pregunta del usuario → Embedding
  2. Buscar documentos relevantes (Qdrant)
  3. Documentos + Pregunta → LLM
  4. LLM genera respuesta basada en documentos

**Rate Limiting**
- **QUÉ ES:** Limitar número de requests por período
- **EJEMPLO:** 100 requests/minuto por API key
- **OBJETIVO:** Prevenir abuso, garantizar fair use

**Redis**
- **QUÉ ES:** Base de datos en memoria (muy rápida)
- **USOS:** Cache, sessions, rate limiting, queues
- **CARACTERÍSTICA:** Datos en RAM, no en disco

## S

**Schema**
- **QUÉ ES:** Estructura/formato de datos en BD
- **EJEMPLO:**
```sql
CREATE TABLE users (
  id INT PRIMARY KEY,
  name VARCHAR(255),
  email VARCHAR(255) UNIQUE
);
```

**SSL/TLS**
- **QUÉ ES:** Protocolos de encriptación para comunicación segura
- **USO:** HTTPS (HTTP + TLS)
- **BENEFICIO:** Datos encriptados en tránsito

## T

**Throughput**
- **QUÉ ES:** Cantidad de trabajo procesado por unidad de tiempo
- **EJEMPLO:** 1000 requests/segundo, 500 MB/s de red
- **VS LATENCY:** Throughput = cantidad, Latency = velocidad

**Token**
- **QUÉ ES:** String que representa credenciales o permisos
- **TIPOS:**
  - Access token: Corta duración (1 hora)
  - Refresh token: Larga duración (7 días)
  - API key: Permanente hasta revocación

## V

**Vector**
- **QUÉ ES:** Array de números que representa datos
- **EJEMPLO:** Embedding de texto, features de imagen
- **DIMENSIÓN:** Longitud del array (384, 1536, 3072, etc.)

**VPS (Virtual Private Server)**
- **QUÉ ES:** Servidor virtual con recursos dedicados
- **VS SHARED HOSTING:** VPS = recursos garantizados
- **VS DEDICATED:** Dedicated = servidor físico completo

---

# ==============================================================================
# [SECCIÓN 6] RECURSOS DE APRENDIZAJE ADICIONALES
# ==============================================================================

## Libros Recomendados

**Para Principiantes:**
- "The Phoenix Project" - DevOps en forma de novela
- "Site Reliability Engineering" (SRE Book) - Google's approach

**Para Arquitectura:**
- "Designing Data-Intensive Applications" - Martin Kleppmann
- "Database Internals" - Alex Petrov

**Para Seguridad:**
- "The Web Application Hacker's Handbook" - Stuttard & Pinto
- "OWASP Top 10" (documentation, free online)

## Cursos Online (Gratuitos/Freemium)

**Docker:**
- Docker 101 Tutorial (docker.com)
- Play with Docker (labs.play-with-docker.com)

**Bases de Datos:**
- Stanford CS145: Introduction to Databases
- Use The Index, Luke (use-the-index-luke.com) - SQL performance

**APIs:**
- REST API Tutorial (restfulapi.net)
- Postman Learning Center

**Monitorización:**
- Prometheus Tutorial (prometheus.io/docs)
- Netdata Learn (learn.netdata.cloud)

## Comunidades y Foros

- Stack Overflow (stackoverflow.com) - Q&A técnico
- Reddit r/devops, r/selfhosted
- Discord communities por tecnología

## Herramientas de Práctica

**Simuladores:**
- Katacoda (scenarios interactivos de DevOps)
- LeetCode (algoritmos y SQL)
- HackerRank (coding challenges)

**Playgrounds:**
- DB Fiddle (dbfiddle.uk) - Probar SQL sin instalar nada
- Replit - IDE online para cualquier lenguaje

---

# ==============================================================================
# FIN DE DOCUMENTACIÓN
# ==============================================================================

**Próximos pasos recomendados:**

1. Leer el archivo validation-checklist.md completo
2. Practicar con 1-2 validaciones simples (ej: verificar límites Docker)
3. Implementar una feature pequeña siguiendo el flujo de la Sección 3
4. Hacer preguntas específicas cuando te atasques
5. Contribuir documentando errores que encuentres

**Recuerda:**
- No es necesario memorizarlo todo
- Úsalo como referencia
- La práctica es más importante que la teoría
- Los errores son oportunidades de aprendizaje

**Contacto para feedback:**
Si encuentras errores en esta documentación o tienes sugerencias de mejora,
por favor reporta vía issues en el repositorio.

---

**Firma de la documentación:**
Versión 3.0.0 | Última actualización: 2026-04-09
Generado bajo metodología SDD v1.0 para el proyecto MANTIS AGENTIC
Nivel: AVANZADO (QUÉ + POR QUÉ + ALTERNATIVAS)

---------

## 🔗 Conexiones Estructurales
[[00-CONTEXT/00-INDEX.md]]
