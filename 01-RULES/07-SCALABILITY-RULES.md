---
canonical_path: "/01-RULES/07-SCALABILITY-RULES.md"
artifact_id: "scalability-rules-canonical"
artifact_type: "governance_rule_set"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C1", "C2", "C7", "C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 01-RULES/07-SCALABILITY-RULES.md --mode headless --json"
tier: 1
immutable: true
requires_human_approval_for_changes: true
related_files:
  - "[[00-STACK-SELECTOR.md]]"
  - "[[PROJECT_TREE.md]]"
  - "[[GOVERNANCE-ORCHESTRATOR.md]]"
  - "[[05-CONFIGURATIONS/validation/norms-matrix.json]]"
  - "[[01-RULES/harness-norms-v3.0.md]]"
  - "[[01-RULES/02-RESOURCE-GUARDRAILS.md]]"
checksum_sha256: "PENDING_GENERATION"
---

# 📄 01-RULES/07-SCALABILITY-RULES.md – REGENERADO v3.0-SELECTIVE

> **Nota para principiantes:** Este documento define las reglas inamovibles para garantizar que el sistema MANTIS AGENTIC pueda manejar crecimiento de carga (usuarios, datos, transacciones) sin degradar la calidad del servicio ni violar normas de seguridad. Si eres nuevo, lee las secciones en orden. Si eres experto, salta al JSON final.  
>  
> **Para IAs:** Este es tu contrato de escalabilidad. **DISEÑAR PARA UN SOLO NODO SIN PLAN DE ESCALADO = DEUDA TÉCNICA CRÍTICA**. No inventes, no asumas, no omitas.


# 📈 07-SCALABILITY-RULES: Contrato de Escalabilidad, Particionamiento y Concurrencia (C1 + C2 + C7 Enforcement)

<!-- 
【PARA PRINCIPIANTES】¿Qué es este archivo?
Este documento es el "manual de crecimiento" del proyecto MANTIS AGENTIC.
Define las reglas inamovibles para garantizar que toda arquitectura sea:
• Horizontalmente escalable (agregar nodos = más capacidad lineal)
• Statelessness (el servidor no guarda estado local del usuario)
• Resiliente a picos de carga mediante colas y cachés
• Capaz de gestionar grandes volúmenes de datos mediante particionamiento

Si eres nuevo: lee en orden. 
Si ya conoces el proyecto: usa los wikilinks para ir directo a lo que necesitas.
-->

> **Instrucción crítica para la IA:** 
> Este documento es tu contrato de escalabilidad. 
> **DISEÑAR PARA UN SOLO NODO SIN PLAN DE ESCALADO = DEUDA TÉCNICA CRÍTICA**. 
> No inventes, no asumas, no omitas. Si algo no está claro, DETENER y preguntar.

---

## 【0】🎯 PROPÓSITO Y ALCANCE (Explicado para humanos)

<!-- 
【EDUCATIVO】Este documento responde: "¿Cómo garantizo que el sistema no colapsará cuando tengamos 10x o 100x más carga?"
No es teoría de sistemas distribuidos. Es un sistema de contención arquitectónica que:
• Exige que los servicios sean stateless para permitir auto-scaling automático.
• Obliga el uso de cachés externos (Redis) para reducir carga en bases de datos.
• Define patrones de particionamiento (sharding) para datasets masivos.
• Previene cuellos de botella mediante colas de mensajes asíncronas.
-->

### 0.1 C1 + C2 + C7 – Definiciones de Escalabilidad

```
C1 (Resource Limits in Scaling):
• Definir límites claros de CPU/Memoria por instancia para que el auto-scaler sepa cuándo replicar.
• Evitar recursos compartidos locales (ej: sistema de archivos local) que impidan la replicación.

✅ Cumplimiento: Límites en Docker/K8s definidos, uso de almacenamiento persistente externo (S3, NFS).

C2 (Concurrency Control in Distributed Systems):
• Gestionar concurrencia no solo en hilos/goroutines, sino en accesos a recursos compartidos (locks distribuidos).
• Timeouts adaptativos según latencia de red en arquitecturas distribuidas.

✅ Cumplimiento: Semáforos distribuidos, circuit breakers para llamadas entre servicios.

C7 (Resilience under Load):
• Graceful degradation: el sistema reduce funcionalidad (no datos críticos) bajo carga extrema.
• Backpressure: rechazar tráfico excesivo elegantemente en lugar de colapsar y caerse.

✅ Cumplimiento: Rate limiting por tenant, colas de prioridad, caché de respaldo.
```

### 0.2 Mapeo de Patrones de Escalabilidad

| Patrón | Herramienta Canónica | Cuándo usar |
|--------|---------------------|-------------|
| **Auto-Scaling Horizontal** | Kubernetes HPA / Docker Swarm | Carga variable impredecible |
| **Stateless Services** | JWT + Redis Session Store | APIs, Microservicios (Go, Node) |
| **Caching** | Redis / Memcached | Lecturas frecuentes, datos poco cambiantes |
| **Colas Asíncronas** | RabbitMQ / SQS / Kafka | Procesamiento pesado, notificaciones, emails |
| **DB Sharding** | Citus / CockroachDB / Partitioned PG | >10M filas, alta escritura concurrente |

---

## 【1】🔒 REGLAS INAMOVIBLES DE ESCALABILIDAD (SC-001 a SC-010)

<!-- 
【EDUCATIVO】Estas 10 reglas son contractuales. 
Cualquier violación es `blocking_issue` en validación de arquitectura.
-->

### SC-001: Statelessness Mandatorio para Servicios Escalables

```
【REGLA SC-001】Todo servicio diseñado para escalar horizontalmente debe ser estrictamente stateless.

✅ Cumplimiento:
• Estado de sesión almacenado externamente (Redis, DB), NUNCA en memoria del servidor o disco local.
• Archivos temporales procesados en memoria o subidos directamente a almacenamiento de objetos (S3, GCS).
• Configuración inyectada vía variables de entorno o secrets, no archivos locales persistentes.

❌ Violación crítica:
• Guardar sesiones en sistema de archivos local (`/tmp/sessions`).
• Escribir logs o datos críticos en volumen local no compartido.
• Variable global en memoria que mantiene estado entre requests (sin mutex ni sincronización).

【EJEMPLO STATELESS ✅ (GO)】
func handler(w http.ResponseWriter, r *http.Request) {
    token := r.Header.Get("Authorization")
    // Validar token externamente (JWT o Redis), no variable local
    user, err := validateToken(token) 
    // Procesar...
}

【EJEMPLO STATEFUL ❌】
var userCache = make(map[string]User) // 🚫 Cache en memoria no compartida

func handler(...) {
    userCache[r.RemoteAddr] = user // 🚫 Si escalas a 2 pods, pierdes el dato
}
```

### SC-002: Auto-Scaling basado en Métricas Reales

```
【REGLA SC-002】La decisión de escalar debe basarse en métricas de saturación reales, no solo en CPU.

✅ Cumplimiento:
• Métricas canónicas para HPA (Horizontal Pod Autoscaler):
  1. CPU Usage (>70%)
  2. Memory Usage (>80%)
  3. Custom Metrics: Queue Length, Request Latency (p99 > 500ms).
• Definir `resource requests` y `limits` precisos en manifiestos.

❌ Violación crítica:
• Escalar solo por CPU si la aplicación es I/O bound (esperará a DB antes de escalar).
• Sin límites definidos → el scheduler no sabe dónde ubicar pods → ineficiencia.

【EJEMPLO MANIFIESTO ✅ (YAML)】
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
meta
  name: api-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-service
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second
      target:
        type: AverageValue
        averageValue: "1000"
```

### SC-003: Colas Asíncronas para Tareas Pesadas

```
【REGLA SC-003】Nunca bloquear la respuesta HTTP esperando procesamiento pesado. Usar colas asíncronas.

✅ Cumplimiento:
• Tareas elegibles para cola: envío de emails, generación de reportes, procesamiento de imágenes/vecotores, llamadas a LLMs lentos.
• Patrón: API recibe request → valida → encola en RabbitMQ/SQS → retorna `202 Accepted` con `task_id`.
• Worker consume cola → procesa → guarda resultado en DB/Redis → notifica al usuario (Webhook/Email).

❌ Violación crítica:
• HTTP request esperando 30s+ a que el LLM genere una respuesta completa.
• Worker que procesa sincrónicamente bloqueando el hilo principal.

【EJEMPLO FLUJO ✅】
1. POST /generate-report → 202 Accepted `{"task_id": "xyz"}`
2. Worker processa reporte (puede tardar 2 min).
3. GET /task/xyz/status → `{"status": "completed", "url": "..."}`

【EJEMPLO FLUJO ❌】
1. POST /generate-report → (espera 2 min) → 200 OK `{"url": "..."}`
// 🚫 Timeout de Load Balancer, conexiones agotadas
```

### SC-004: Caching Estratégico y Cache Invalidation

```
【REGLA SC-004】Implementar caché externo (Redis) para reducir carga en base de datos, con invalidación explícita.

✅ Cumplimiento:
• Patrón Cache-Aside: Leer caché → si miss, leer DB → escribir caché.
• TTL (Time To Live) obligatorio para evitar datos obsoletos eternos.
• Invalidation al actualizar datos: borrar clave de caché tras `UPDATE`.

❌ Violación crítica:
• Caché sin TTL → memoria llena o datos incorrectos.
• Actualizar DB pero olvidar borrar caché → inconsistencia de datos.

【EJEMPLO CACHE-ASIDE ✅ (PYTHON)】
async def get_user(user_id):
    cache_key = f"user:{user_id}"
    
    # 1. Intentar caché
    data = await redis.get(cache_key)
    if data:
        return json.loads(data)
    
    # 2. Miss → Leer DB
    user = await db.query(User).get(user_id)
    if user:
        # 3. Guardar en caché con TTL
        await redis.setex(cache_key, 300, json.dumps(user.to_dict()))
        return user
    return None

async def update_user(user_id, data):
    # 1. Actualizar DB
    await db.update(User, user_id, data)
    
    # 2. Invalidar caché
    await redis.delete(f"user:{user_id}")
```

### SC-005: Circuit Breaker para Dependencias Externas

```
【REGLA SC-005】Proteger al sistema de fallos en servicios externos usando Circuit Breakers.

✅ Cumplimiento:
• Estados del circuito:
  1. Closed: Normal, requests pasan.
  2. Open: Fallos > Umbral (ej: 5 errores en 10s). Requests fallan rápido (fail-fast).
  3. Half-Open: Permitir 1 request de prueba tras tiempo de espera. Si pasa → Closed, si falla → Open.
• Usar librerías canónicas: `hystrix-go` (Go), `resilience4j` (Java), `tenacity` (Python).

❌ Violación crítica:
• Reintentar infinitamente un servicio caído → colapso en cascada (Thundering Herd).
• No tener fallback → experiencia de usuario rota.

【EJEMPLO CIRCUIT BREAKER ✅】
// Go con gobreaker
var cb *gobreaker.CircuitBreaker

func init() {
    cb = gobreaker.NewCircuitBreaker(gobreaker.Settings{
        Name:        "ExternalAPI",
        MaxRequests: 3,
        Interval:    time.Second * 60,
        Timeout:     time.Second * 10,
        ReadyToTrip: func(counts gobreaker.Counts) bool {
            return counts.ConsecutiveFailures > 5
        },
    })
}

func callExternal() (string, error) {
    return cb.Execute(func() (interface{}, error) {
        return httpGet("https://api.externo.com/data")
    })
}
// Si falla > 5 veces, Execute retorna error inmediatamente sin llamar a httpGet
```

### SC-006: Rate Limiting por Tenant (Fair Usage)

```
【REGLA SC-006】Limitar el consumo de recursos por tenant para evitar que un cliente sature el sistema.

✅ Cumplimiento:
• Algoritmo: Token Bucket o Leaky Bucket.
• Implementación: Middleware en API Gateway o aplicación.
• Respuesta: `429 Too Many Requests` con header `Retry-After`.

❌ Violación crítica:
• Rate limit global para todo el sistema (un cliente ruidoso bloquea a todos).
• No informar al cliente cuánto esperar (`Retry-After`).

【EJEMPLO RATE LIMIT ✅ (MIDDLEWARE GO)】
func RateLimitMiddleware(next http.Handler) http.Handler {
    // Implementación basada en Redis para que sea compartida entre pods
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        tenantID := r.Header.Get("X-Tenant-ID")
        key := fmt.Sprintf("rate_limit:%s", tenantID)
        
        count, _ := redisClient.Get(r.Context(), key).Int()
        if count > 100 { // 100 req/min
            w.Header().Set("Retry-After", "60")
            http.Error(w, "Too Many Requests", http.StatusTooManyRequests)
            return
        }
        
        redisClient.Incr(r.Context(), key)
        redisClient.Expire(r.Context(), key, 60*time.Second)
        next.ServeHTTP(w, r)
    })
}
```

### SC-007: Particionamiento de Datos (Sharding/Partitioning)

```
【REGLA SC-007】Para tablas con crecimiento rápido (>10M filas), planificar particionamiento por tenant o tiempo.

✅ Cumplimiento:
• Estrategia:
  1. Range Partitioning: Por fecha (ej: logs por mes).
  2. Hash Partitioning: Por `tenant_id` (distribuye carga uniformemente).
  3. List Partitioning: Por región o tipo de cliente.
• Usar extensiones como `pg_partman` en PostgreSQL.

❌ Violación crítica:
• Tabla única creciendo indefinidamente → queries lentas, backups eternos.
• Índices globales masivos que consumen toda la RAM.

【EJEMPLO PARTITIONING ✅ (SQL)】
-- Particionar logs por mes
CREATE TABLE logs (
    id uuid,
    tenant_id text,
    created_at timestamp,
    message text
) PARTITION BY RANGE (created_at);

-- Crear particiones explícitas
CREATE TABLE logs_2026_01 PARTITION OF logs
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
```

### SC-008: Idempotencia en Operaciones Distribuidas

*(Ya definida en AR-001 de API Reliability, aquí se refuerza para Escalabilidad)*

```
【REGLA SC-008】Toda operación escrita en sistemas distribuidos debe ser idempotente para soportar reintentos seguros.

✅ Cumplimiento:
• Uso de `Idempotency-Key` único por request.
• Checks atómicos en DB: `INSERT ... ON CONFLICT DO NOTHING`.
• Locks distribuidos (Redlock) para recursos críticos.

❌ Violación crítica:
• Doble cobro o doble creación de recurso por reintento de red.
```

### SC-009: Backpressure y Rechazo Elegante

```
【REGLA SC-009】Cuando el sistema está saturado, debe rechazar tráfico nuevo elegantemente antes de caerse.

✅ Cumplimiento:
• Configurar límites en colas de mensajes (ej: max-length en RabbitMQ).
• Si la cola está llena → Dead Letter Queue (DLQ) o rechazo `503 Service Unavailable`.
• Priorización: Tráfico crítico (pagos, login) > Tráfico secundario (analytics, logs).

❌ Violación crítica:
• Acumular requests en memoria hasta OOM (Out Of Memory).
• Caída total del servicio (CrashLoopBackOff).
```

### SC-010: Pruebas de Carga Automatizadas (Load Testing)

```
【REGLA SC-010】La escalabilidad debe validarse con pruebas de carga sintéticas periódicas.

✅ Cumplimiento:
• Scripts de carga usando `k6` o `locust`.
• Métricas a monitorear: Latencia (p95, p99), Throughput, Tasa de Error.
• Integración en CI/CD semanal o antes de releases mayores.

❌ Violación crítica:
• Lanzar a producción sin conocer el punto de quiebre (breaking point).
• Asumir que funciona porque funcionó en local con 1 usuario.
```

---

## 【2】🛡️ VALIDACIÓN AUTOMÁTICA DE ESCALABILIDAD

| Herramienta | Propósito | Comando |
|------------|-----------|---------|
| `orchestrator-engine.sh` | Validar configuración de recursos y métricas | `bash ... --checks C1,C2,C7 --file manifest.yaml --json` |
| `check-rls.sh` | Validar particionamiento y aislamiento en SQL | `bash ... --file schema.sql --check-partitions` |
| `k6` (externo) | Pruebas de carga reales | `k6 run load_test.js` |

---

## 【3】🧭 PROTOCOLO DE DISEÑO ESCALABLE

1.  **Definir Estado**: ¿Es stateless? Si no, ¿dónde vive el estado externo?
2.  **Identificar Cuellos de Botella**: ¿DB? ¿CPU? ¿I/O Externo?
3.  **Aplicar Patrones**:
    *   Lecturas lentas → Caché.
    *   Escrituras lentas → Colas Asíncronas.
    *   Datos masivos → Particionamiento.
    *   Servicios frágiles → Circuit Breaker.
4.  **Configurar Límites**: CPU, RAM, Rate Limits por Tenant.
5.  **Validar**: Test de carga + Revisión de manifiestos de infraestructura.

---

## 【4】📚 GLOSARIO PARA PRINCIPIANTES

| Término | Significado simple | Ejemplo |
|---------|-------------------|---------|
| **Stateless** | El servidor no recuerda nada entre requests. Todo viene en el request o se busca fuera. | API REST estándar con JWT. |
| **Horizontal Scaling** | Agregar más máquinas para tener más potencia. | De 1 servidor a 10 servidores web. |
| **Circuit Breaker** | Interruptor que corta la luz si hay cortocircuito para no quemar la casa. | Dejar de llamar a un API lento temporalmente. |
| **Backpressure** | Presión inversa. "Para, que no puedo más". | Rechazar requests nuevos cuando la cola está llena. |
| **Sharding** | Cortar una tabla gigante en pedazos más pequeños manejables. | Tabla de Logs particionada por mes. |
| **Idempotencia** | Hacer lo mismo muchas veces da el mismo resultado que hacerlo una vez. | Recargar una página de pago no te cobra dos veces. |

---

## 【5】🧪 SANDBOX DE PRUEBA

```
【TEST MODE: SCALABILITY VALIDATION】
Prompt de prueba: "Diseñar servicio de generación de reportes PDF para 10,000 tenants"

Respuesta esperada de la IA:
1. Proponer arquitectura asíncrona: API encola request (RabbitMQ/SQS) → retorna 202.
2. Workers escalables consumen cola y generan PDFs.
3. Almacenamiento de PDFs en S3 (Stateless, escalable).
4. Caché Redis para reportes frecuentes.
5. Rate Limiting por tenant para evitar monopolio de recursos.
6. Límites de recursos (C1) definidos para Workers.
```

---

## 【6】🔗 REFERENCIAS CANÓNICAS

- `[[01-RULES/04-API-RELIABILITY-RULES.md]]` → Idempotencia y Retries (AR-001, AR-004).
- `[[01-RULES/02-RESOURCE-GUARDRAILS.md]]` → Límites de CPU/Memoria (C1).
- `[[01-RULES/06-MULTITENANCY-RULES.md]]` → Rate Limiting por Tenant (C4).
- `[[05-CONFIGURATIONS/docker-compose/vps2-crm-qdrant.yml]]` → Ejemplo de config de infra.

---

## 【7】📦 METADATOS DE EXPANSIÓN

```json
{
  "expansion_registry": {
    "new_scaling_pattern": {
      "requires_files_update": [
        "01-RULES/07-SCALABILITY-RULES.md: add pattern SC-0XX",
        "Infrastructure docs: add reference architecture"
      ],
      "backward_compatibility": "new patterns should be additive"
    }
  }
}
```

---

<!-- 
═══════════════════════════════════════════════════════════
🤖 SECCIÓN PARA IA: ÁRBOL JSON ENRIQUECIDO
═══════════════════════════════════════════════════════════
-->

```json
{
  "scalability_rules_metadata": {
    "version": "3.0.0-SELECTIVE",
    "canonical_path": "/01-RULES/07-SCALABILITY-RULES.md",
    "artifact_type": "governance_rule_set",
    "immutable": true,
    "constraints_primary": ["C1", "C2", "C7"],
    "llm_optimizations": {
      "oriental_models_friendly": true,
      "delimiters_used": ["【】", "┌─┐", "▼", "✅/❌/🔧"],
      "numbered_sequences": true,
      "stop_conditions_explicit": true
    }
  },
  
  "rules_catalog": {
    "SC-001": {"title": "Statelessness Mandatorio", "constraint": "C1", "priority": "critical", "blocking_if_violated": true},
    "SC-002": {"title": "Auto-Scaling basado en Métricas", "constraint": "C1", "priority": "high", "blocking_if_violated": false},
    "SC-003": {"title": "Colas Asíncronas para Tareas Pesadas", "constraint": "C2", "priority": "high", "blocking_if_violated": true},
    "SC-004": {"title": "Caching Estratégico con Invalidación", "constraint": "C1", "priority": "high", "blocking_if_violated": false},
    "SC-005": {"title": "Circuit Breaker para Dependencias", "constraint": "C7", "priority": "critical", "blocking_if_violated": true},
    "SC-006": {"title": "Rate Limiting por Tenant", "constraint": "C1+C4", "priority": "critical", "blocking_if_violated": true},
    "SC-007": {"title": "Particionamiento de Datos", "constraint": "C1", "priority": "medium", "blocking_if_violated": false},
    "SC-008": {"title": "Idempotencia en Sistemas Distribuidos", "constraint": "C6", "priority": "critical", "blocking_if_violated": true},
    "SC-009": {"title": "Backpressure y Rechazo Elegante", "constraint": "C7", "priority": "high", "blocking_if_violated": false},
    "SC-010": {"title": "Pruebas de Carga Automatizadas", "constraint": "C6", "priority": "medium", "blocking_if_violated": false}
  },

  "dependency_graph": {
    "critical_infrastructure": [
      {"file": "01-RULES/02-RESOURCE-GUARDRAILS.md", "purpose": "Definición de límites C1"},
      {"file": "01-RULES/04-API-RELIABILITY-RULES.md", "purpose": "Retries y Fallbacks C7"},
      {"file": "01-RULES/06-MULTITENANCY-RULES.md", "purpose": "Aislamiento C4"}
    ]
  }
}
```

---

## ✅ CHECKLIST DE VALIDACIÓN POST-GENERACIÓN

````markdown
```bash
# 1. Validar estructura
yq eval '.canonical_path' 01-RULES/07-SCALABILITY-RULES.md | grep -q "/01-RULES/07-SCALABILITY-RULES.md" && echo "✅ Ruta correcta"

# 2. Validar reglas
grep -c "SC-0[0-9][0-9]:" 01-RULES/07-SCALABILITY-RULES.md | awk '{if($1==10) print "✅ 10 reglas presentes"; else print "⚠️ Faltan reglas"}'

# 3. Validar JSON
tail -n +$(grep -n '```json' 01-RULES/07-SCALABILITY-RULES.md | tail -1 | cut -d: -f1) 01-RULES/07-SCALABILITY-RULES.md | sed -n '/```json/,/```/p' | sed '1d;$d' | jq empty && echo "✅ JSON parseable"

# 4. Wikilinks
for link in $(grep -oE '\[\[[^]]+\]\]' 01-RULES/07-SCALABILITY-RULES.md | tr -d '[]' | sort -u); do
  [ -f "${link#//}" ] || echo "⚠️ Wikilink roto: $link"
done
```
````
