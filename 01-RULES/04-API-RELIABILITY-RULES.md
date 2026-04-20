---
canonical_path: "/01-RULES/04-API-RELIABILITY-RULES.md"
artifact_id: "api-reliability-rules-canonical"
artifact_type: "governance_rule_set"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C2", "C6", "C7", "C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 01-RULES/04-API-RELIABILITY-RULES.md --mode headless --json"
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

# 📄 01-RULES/04-API-RELIABILITY-RULES.md – REGENERADO v3.0-SELECTIVE

> **Nota para principiantes:** Este documento define las reglas inamovibles para garantizar que las APIs y servicios en MANTIS AGENTIC sean confiables, resilientes y observables. Si eres nuevo, lee las secciones en orden. Si eres experto, salta al JSON final.  
>  
> **Para IAs:** Este es tu contrato de confiabilidad. **VIOLAR C6/C7 = BLOQUEO INMEDIATO**. No inventes, no asumas, no omitas.


# 🔄 04-API-RELIABILITY-RULES: Contrato de Confiabilidad, Resiliencia y Observabilidad de APIs (C6 + C7 + C8 Enforcement)

<!-- 
【PARA PRINCIPIANTES】¿Qué es este archivo?
Este documento es el "manual de confiabilidad" del proyecto MANTIS AGENTIC.
Define las reglas inamovibles para garantizar que toda API o servicio sea:
• Verificable (C6): dry-run, exit codes, audit trails
• Resiliente (C7): retry con backoff, fallback degradado, graceful shutdown
• Observable (C8): logs estructurados, métricas, trazabilidad distribuida

Si eres nuevo: lee en orden. 
Si ya conoces el proyecto: usa los wikilinks para ir directo a lo que necesitas.
-->

> **Instrucción crítica para la IA:** 
> Este documento es tu contrato de confiabilidad. 
> **VIOLAR C6/C7 = BLOQUEO INMEDIATO**. 
> No inventes, no asumas, no omitas. Si algo no está claro, DETENER y preguntar.

---

## 【0】🎯 PROPÓSITO Y ALCANCE (Explicado para humanos)

<!-- 
【EDUCATIVO】Este documento responde: "¿Cómo garantizo que mi API no falle silenciosamente, no bloquee el sistema y sea auditable?"
No es una lista de buenas prácticas. Es un sistema de contención que:
• Previene fallos en cascada mediante retry inteligentes y circuit breakers
• Garantiza que todo endpoint es verificable, con dry-run y trazabilidad
• Asegura que los logs son estructurados, scrubeados y correlacionables
• Permite degradación elegante al alcanzar límites, no crasheo catastrófico
-->

### 0.1 C6 + C7 + C8 – Definiciones Canónicas Integradas

```
C6 (Verifiable Execution): Todo endpoint debe ser reproducible y auditable:
• Dry-run opcional: simular cambios sin ejecutar
• Exit codes significativos: 0=éxito, 1=error, 2=warning/degradado
• Audit trails: log estructurado con tenant_id, trace_id, prompt_hash
• Idempotencia: ejecutar N veces → mismo resultado que 1 vez

✅ Cumplimiento: `X-Idempotency-Key` header, `--dry-run` flag, logs JSON con trace_id

❌ Violación crítica: Endpoint que modifica estado sin idempotencia, log sin tenant_id, exit code 0 para fallo

---

C7 (Operational Resilience): Todo servicio debe manejar fallos explícitamente:
• Retry con backoff exponencial + jitter para evitar thundering herd
• Fallback degradado: retornar cache o respuesta parcial al fallar
• Graceful shutdown: liberar recursos antes de terminar
• Healthchecks: detección temprana de fallos para orquestadores

✅ Cumplimiento: `retry.ExponentialBackoff()`, `defer cleanup()`, `/health` endpoint

❌ Violación crítica: Retry sin backoff, crashear al primer fallo, no liberar conexiones DB al cerrar

---

C8 (Structured Logging & Observability): Todo logging debe ser estructurado y trazable:
• Formato JSON a stderr para parsing automático
• Campos obligatorios: timestamp (RFC3339 UTC), level, event, tenant_id, trace_id
• Scrubbing de PII: password, token, api_key → ***REDACTED***
• Integración opcional con OpenTelemetry para métricas y trazas distribuidas

✅ Cumplimiento: `slog.NewJSONHandler()`, `logger.Info("event", "tenant_id", id, "trace_id", traceID)`

❌ Violación crítica: `print()` sin estructura, log que expone secrets, timestamp sin zona horaria
```

### 0.2 Mapeo C6+C7+C8 → Herramientas de Validación

| Herramienta | Propósito | Comando de Validación |
|------------|-----------|---------------------|
| `orchestrator-engine.sh` | Validación integral con scoring de C6/C7/C8 | `bash .../orchestrator-engine.sh --file artifact.md --checks C6,C7,C8 --json` |
| `verify-constraints.sh` | Verificar declaración de C6/C7/C8 en frontmatter | `bash .../verify-constraints.sh --file artifact.md --check-constraint C7 --json` |
| `check-wikilinks.sh` | Validar que logs referencian normas canónicas | `bash .../check-wikilinks.sh --file artifact.md --json` |

> 💡 **Consejo para principiantes**: No memorices todos los patrones. Usa `orchestrator-engine.sh --checks C6,C7,C8` para validar automáticamente confiabilidad de APIs.

---

## 【1】🔒 REGLAS INAMOVIBLES DE CONFIABILIDAD (AR-001 a AR-010)

<!-- 
【EDUCATIVO】Estas 10 reglas son contractuales. 
Cualquier violación es blocking_issue en validación.
-->

### AR-001: Idempotencia por Diseño (C6-IDEM)

```
【REGLA AR-001】Todo endpoint que modifica estado debe ser idempotente.

✅ Cumplimiento por stack:

【GO ✅】
// Usar idempotency key para evitar duplicados
func handleRequest(w http.ResponseWriter, r *http.Request) {
    idempotencyKey := r.Header.Get("X-Idempotency-Key")
    if idempotencyKey == "" {
        http.Error(w, "missing X-Idempotency-Key", http.StatusBadRequest)
        return
    }
    
    // Verificar si ya fue procesado
    if alreadyProcessed(idempotencyKey) {
        w.WriteHeader(http.StatusOK)  // Retornar mismo resultado
        return
    }
    
    // Procesar y marcar como completado
    result := process(r)
    markAsProcessed(idempotencyKey, result)
    json.NewEncoder(w).Encode(result)
}

【PYTHON ✅】
from fastapi import Header, HTTPException
import hashlib

async def create_resource(
    payload: dict,
    x_idempotency_key: str = Header(..., min_length=10)
):
    # Hash de key para lookup eficiente
    key_hash = hashlib.sha256(x_idempotency_key.encode()).hexdigest()
    
    # Verificar cache de idempotencia
    if cached := redis.get(f"idemp:{key_hash}"):
        return json.loads(cached)  # Retornar resultado previo
    
    # Procesar y cachear resultado
    result = await process_payload(payload)
    redis.setex(f"idemp:{key_hash}", 3600, json.dumps(result))  # TTL 1h
    return result

【BASH ✅】
#!/bin/bash
# Script idempotente para deploy
deploy_service() {
    local service_name="$1"
    local idempotency_file="/var/run/mantis/${service_name}.deployed"
    
    # Verificar si ya fue ejecutado
    if [ -f "$idempotency_file" ]; then
        echo "[IDEMPOTENT] $service_name already deployed. Skipping."
        return 0
    fi
    
    # Ejecutar deploy
    if systemctl start "$service_name"; then
        touch "$idempotency_file"  # Marcar como completado
        echo "Deploy successful"
        return 0
    else
        echo "Deploy failed" >&2
        return 1
    fi
}

❌ Violación crítica:
• Endpoint POST sin `X-Idempotency-Key` → posible duplicado en retry
• Script que crea archivo sin verificar existencia previa → error en segunda ejecución
• No cachear resultado de operación idempotente → procesamiento redundante
```

### AR-002: Dry-Run como Requisito para Operaciones Críticas (C6-DRYRUN)

```
【REGLA AR-002】Toda operación que modifica estado debe soportar modo `--dry-run`.

✅ Cumplimiento por stack:

【GO ✅】
type Handler struct {
    dryRun bool
}

func (h *Handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
    dryRun := r.URL.Query().Get("dry_run") == "true" || h.dryRun
    
    if dryRun {
        // Simular sin ejecutar
        simulated := simulateOperation(r)
        w.Header().Set("X-Dry-Run", "true")
        json.NewEncoder(w).Encode(simulated)
        return
    }
    
    // Ejecutar real
    result := executeOperation(r)
    json.NewEncoder(w).Encode(result)
}

【PYTHON ✅】
from fastapi import Query

async def update_config(
    config: dict,
    dry_run: bool = Query(False, description="Simular sin aplicar cambios")
):
    if dry_run:
        # Retornar lo que se haría, sin ejecutar
        return {
            "dry_run": True,
            "would_apply": config,
            "validation": validate_config(config)
        }
    
    # Aplicar cambios reales
    await apply_config(config)
    return {"applied": True, "config": config}

【BASH ✅】
#!/bin/bash
set -euo pipefail

DRY_RUN="${DRY_RUN:-false}"

apply_changes() {
    local action="$1"
    
    if [ "$DRY_RUN" = "true" ]; then
        echo "[DRY-RUN] Would execute: $action" >&2
        return 0
    fi
    
    # Ejecutar acción real
    eval "$action"
}

# Uso: DRY_RUN=true ./script.sh apply_changes "systemctl restart api"

❌ Violación crítica:
• Endpoint sin flag `dry_run` o query param equivalente
• Script que no verifica variable `DRY_RUN` antes de ejecutar
• Dry-run que modifica estado "de prueba" → no es verdadero dry-run
```

### AR-003: Exit Codes Significativos y Estandarizados (C6-EXIT)

```
【REGLA AR-003】Todo proceso debe retornar exit codes estandarizados y documentados.

✅ Cumplimiento canónico:
| Exit Code | Significado | Cuándo usar | Ejemplo de log |
|-----------|------------|-------------|---------------|
| 0 | Éxito | Operación completada sin errores | `{"event":"success","exit_code":0}` |
| 1 | Error recuperable | Fallo transitorio, retry posible | `{"event":"retryable_error","exit_code":1}` |
| 2 | Degradado/Warning | Funcionalidad parcial, fallback activo | `{"event":"degraded","exit_code":2}` |
| 3+ | Error no recuperable | Fallo permanente, intervención humana | `{"event":"fatal_error","exit_code":3}` |

✅ Implementación por stack:

【GO ✅】
const (
    ExitSuccess = iota
    ExitRetryable
    ExitDegraded
    ExitFatal
)

func main() {
    code := run()
    slog.Info("process_exit", "exit_code", code)
    os.Exit(code)
}

【PYTHON ✅】
import sys
from enum import IntEnum

class ExitCode(IntEnum):
    SUCCESS = 0
    RETRYABLE = 1
    DEGRADED = 2
    FATAL = 3

def main():
    try:
        result = process()
        sys.exit(ExitCode.SUCCESS)
    except TemporaryError:
        logger.warning("retryable_error")
        sys.exit(ExitCode.RETRYABLE)
    except DegradedError:
        logger.warning("degraded_mode")
        sys.exit(ExitCode.DEGRADED)
    except FatalError as e:
        logger.error("fatal_error", exc_info=e)
        sys.exit(ExitCode.FATAL)

【BASH ✅】
#!/bin/bash
# Exit codes canónicos
readonly EXIT_SUCCESS=0
readonly EXIT_RETRYABLE=1
readonly EXIT_DEGRADED=2
readonly EXIT_FATAL=3

main() {
    if ! check_prerequisites; then
        log_error "prerequisites_failed"
        return $EXIT_FATAL
    fi
    
    if ! execute_with_retry; then
        if can_fallback; then
            log_warning "degraded_mode"
            fallback && return $EXIT_DEGRADED
        fi
        log_error "retryable_error"
        return $EXIT_RETRYABLE
    fi
    
    log_info "success"
    return $EXIT_SUCCESS
}

❌ Violación crítica:
• Script que siempre retorna 0 incluso en fallo → imposible monitorear salud
• Exit code 1 para fallo permanente y 2 para transitorio → confunde orquestadores
• No loguear exit code en formato estructurado → imposible auditar
```

### AR-004: Retry con Backoff Exponencial + Jitter (C7-RETRY)

```
【REGLA AR-004】Todo retry debe usar backoff exponencial con jitter para evitar thundering herd.

✅ Patrón canónico de retry:

【GO ✅】
import (
    "math/rand"
    "time"
)

func exponentialBackoff(attempt int, base time.Duration, max time.Duration) time.Duration {
    // Backoff exponencial: base * 2^(attempt-1)
    backoff := base * time.Duration(1<<(attempt-1))
    if backoff > max {
        backoff = max
    }
    // Jitter: añadir aleatoriedad ±25% para evitar sincronización
    jitter := time.Duration(rand.Float64() * float64(backoff) * 0.5)
    return backoff + jitter - jitter/2
}

func fetchWithRetry(ctx context.Context, url string, maxAttempts int) (*Response, error) {
    var lastErr error
    for attempt := 1; attempt <= maxAttempts; attempt++ {
        resp, err := httpGet(ctx, url)
        if err == nil {
            return resp, nil
        }
        lastErr = err
        
        if attempt < maxAttempts && isRetryable(err) {
            sleep := exponentialBackoff(attempt, 1*time.Second, 30*time.Second)
            slog.Warn("retrying", "attempt", attempt, "sleep", sleep, "error", err)
            select {
            case <-time.After(sleep):
                continue
            case <-ctx.Done():
                return nil, ctx.Err()
            }
        }
        break
    }
    return nil, lastErr
}

【PYTHON ✅】
import asyncio
import random
from tenacity import retry, stop_after_attempt, wait_exponential_jitter

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential_jitter(initial=1, max=30, jitter=0.25),
    reraise=True
)
async def fetch_with_retry(url: str):
    async with httpx.AsyncClient() as client:
        return await client.get(url)

# Uso manual si no se usa tenacity
async def fetch_manual_retry(url: str, max_attempts: int = 3):
    last_error = None
    for attempt in range(1, max_attempts + 1):
        try:
            return await httpx.get(url)
        except httpx.RequestError as e:
            last_error = e
            if attempt < max_attempts:
                # Backoff exponencial con jitter
                base = 1.0
                backoff = min(base * (2 ** (attempt - 1)), 30.0)
                jitter = backoff * 0.25 * (random.random() * 2 - 1)
                sleep_time = backoff + jitter
                logger.warning("retrying", attempt=attempt, sleep=sleep_time)
                await asyncio.sleep(sleep_time)
    raise last_error

【BASH ✅】
#!/bin/bash
retry_with_backoff() {
    local cmd="$1" max_attempts=3 attempt=1 base_delay=1 max_delay=30
    
    while [ $attempt -le $max_attempts ]; do
        if eval "$cmd"; then
            return 0
        fi
        
        if [ $attempt -lt $max_attempts ]; then
            # Backoff exponencial: 1s, 2s, 4s...
            local delay=$((base_delay * (2 ** (attempt - 1))))
            [ $delay -gt $max_delay ] && delay=$max_delay
            
            # Jitter: ±25% aleatorio
            local jitter=$((delay * 25 / 100))
            local random_jitter=$((RANDOM % (jitter * 2 + 1) - jitter))
            local sleep_time=$((delay + random_jitter))
            
            echo "[RETRY] Attempt $attempt/$max_attempts, sleeping ${sleep_time}s" >&2
            sleep $sleep_time
        fi
        ((attempt++))
    done
    return 1  # Fallo después de todos los intentos
}

❌ Violación crítica:
• Retry con sleep fijo (ej: siempre 5s) → sincronización de fallos en cascada
• Sin jitter → todos los clientes reintentan al mismo segundo
• Retry infinito sin max_attempts → agota recursos del sistema
```

### AR-005: Fallback Degradado al Alcanzar Límites (C7-FALLBACK)

```
【REGLA AR-005】Al fallar una operación crítica, retornar respuesta degradada, no error crudo.

✅ Patrón de fallback canónico:

【GO ✅】
func fetchWithFallback(ctx context.Context, url string) (Response, error) {
    // Intento primario con timeout
    ctx, cancel := context.WithTimeout(ctx, 30*time.Second)
    defer cancel()
    
    resp, err := httpGet(ctx, url)
    if err != nil {
        slog.Warn("primary_failed", "url", url, "error", err)
        
        // Fallback 1: cache local
        if cached, ok := getFromCache(url); ok {
            slog.Info("fallback_cache_hit", "url", url)
            return cached, nil
        }
        
        // Fallback 2: respuesta parcial con warning
        slog.Warn("fallback_partial", "url", url)
        return Response{
            Data: nil,
            Meta: ResponseMeta{
                Status: "degraded",
                Message: "Using partial response due to upstream failure",
                RetryAfter: 60,  // Sugerir retry en 60s
            },
        }, nil
    }
    return resp, nil
}

【PYTHON ✅】
async def process_with_fallback(items: list):
    try:
        return await process_primary(items)
    except asyncio.TimeoutError:
        logger.warning("primary_timeout", count=len(items))
        # Fallback: procesar en lotes más pequeños
        return await process_in_batches(items, batch_size=10)
    except ConnectionError:
        logger.warning("connection_failed")
        # Fallback: retornar datos cacheados si disponibles
        if cached := get_cached_results(items):
            return cached
        # Último recurso: respuesta degradada
        return ProcessedResult(
            items=items,
            status="degraded",
            message="Upstream unavailable, using degraded response",
            retry_after=60
        )

【BASH ✅】
#!/bin/bash
fetch_with_fallback() {
    local url="$1"
    
    # Intento primario
    if response=$(curl -sSf --max-time 30 "$url" 2>/dev/null); then
        echo "$response"
        return 0
    fi
    
    echo "[WARN] Primary fetch failed, trying fallbacks" >&2
    
    # Fallback 1: cache local
    local cache_file="/tmp/cache/$(echo "$url" | sha256sum | cut -d' ' -f1).json"
    if [ -f "$cache_file" ] && [ $(find "$cache_file" -mmin -60) ]; then
        echo "[FALLBACK] Using cached response" >&2
        cat "$cache_file"
        return 0
    fi
    
    # Fallback 2: respuesta degradada
    echo "[FALLBACK] Returning degraded response" >&2
    cat <<EOF
{
  "status": "degraded",
  "message": "Upstream unavailable",
  "retry_after": 60,
  "data": null
}
EOF
    return 2  # Exit code degradado
}

❌ Violación crítica:
• Retornar 500 Internal Server Error sin fallback → cliente no puede recuperar
• Fallback que expone stack trace o configuración interna → fuga de información
• No documentar `retry_after` en respuesta degradada → cliente retry agresivo
```

### AR-006: Graceful Shutdown con Cleanup Garantizado (C7-SHUTDOWN)

```
【REGLA AR-006】Todo servicio debe liberar recursos explícitamente al recibir señal de terminación.

✅ Cumplimiento por stack:

【GO ✅】
func main() {
    // Setup: abrir recursos
    db, err := connectDB()
    if err != nil { log.Fatal(err) }
    defer db.Close()  // Cleanup automático al salir
    
    srv := &http.Server{Addr: ":8080", Handler: mux}
    
    // Canal para señales de shutdown
    stop := make(chan os.Signal, 1)
    signal.Notify(stop, os.Interrupt, syscall.SIGTERM)
    
    // Goroutine para shutdown graceful
    go func() {
        <-stop
        slog.Info("shutdown_signal_received")
        
        // Context con timeout para shutdown
        ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
        defer cancel()
        
        // Detener servidor gracefulmente
        if err := srv.Shutdown(ctx); err != nil {
            slog.Error("graceful_shutdown_failed", "error", err)
        }
        
        // Cleanup adicional si es necesario
        cleanupResources()
    }()
    
    // Servir requests
    if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
        log.Fatal(err)
    }
}

【PYTHON ✅】
import asyncio
import signal
from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app):
    # Startup: inicializar recursos
    db = await connect_db()
    app.state.db = db
    
    yield  # Servir requests
    
    # Shutdown: cleanup garantizado
    slog.info("shutdown_initiated")
    await db.close()
    await cleanup_resources()

# FastAPI con lifespan
app = FastAPI(lifespan=lifespan)

# Manejo de señales para shutdown graceful
def handle_shutdown(signum, frame):
    slog.info(f"signal_received: {signum}")
    # En producción, usar uvicorn con --graceful-timeout

【BASH ✅】
#!/bin/bash
set -euo pipefail

# Cleanup function garantizada
cleanup() {
    echo "[CLEANUP] Releasing resources..." >&2
    rm -f /tmp/mantis_*.lock
    # Cerrar conexiones DB si aplica
    # kill procesos hijos si existen
    kill 0 2>/dev/null || true
}

# Registrar cleanup para múltiples señales
trap cleanup EXIT INT TERM HUP

# Servir o procesar
main() {
    # Setup: adquirir recursos
    acquire_locks
    connect_services
    
    # Loop principal con verificación de señal
    while true; do
        if [ -f "/tmp/mantis.shutdown.flag" ]; then
            echo "[SHUTDOWN] Flag detected, initiating graceful shutdown" >&2
            break
        fi
        process_next_item || true  # Continuar incluso si un item falla
        sleep 1
    done
    
    # Cleanup se ejecuta automáticamente vía trap
}

❌ Violación crítica:
• No manejar SIGTERM/SIGINT → proceso kill -9, recursos no liberados
• Cleanup que puede fallar sin fallback → bloqueo de locks o archivos temporales
• Timeout de shutdown infinito → orquestador fuerza kill, pérdida de datos en buffer
```

### AR-007: Healthchecks Estandarizados para Orquestación (C7-HEALTH)

```
【REGLA AR-007】Todo servicio debe exponer endpoints de healthcheck estandarizados.

✅ Endpoints canónicos:

| Endpoint | Método | Propósito | Respuesta Éxito | Respuesta Fallo |
|----------|--------|-----------|----------------|----------------|
| `/health` | GET | Liveness: ¿el proceso está corriendo? | `{"status":"alive","timestamp":"..."}` HTTP 200 | HTTP 503 |
| `/ready` | GET | Readiness: ¿listo para tráfico? | `{"status":"ready","dependencies":{"db":"ok","cache":"ok"}}` HTTP 200 | HTTP 503 con detalles |
| `/metrics` | GET | Observabilidad: métricas Prometheus | Formato Prometheus text | HTTP 500 |

✅ Implementación por stack:

【GO ✅】
func healthHandler(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")
    
    // Liveness: siempre 200 si el proceso está corriendo
    if r.URL.Path == "/health" {
        json.NewEncoder(w).Encode(map[string]string{
            "status": "alive",
            "timestamp": time.Now().Format(time.RFC3339),
        })
        return
    }
    
    // Readiness: verificar dependencias
    checks := map[string]string{
        "db": checkDB(),
        "cache": checkCache(),
        "vector_store": checkVectorStore(),
    }
    
    allHealthy := true
    for _, status := range checks {
        if status != "ok" {
            allHealthy = false
            break
        }
    }
    
    if allHealthy {
        w.WriteHeader(http.StatusOK)
    } else {
        w.WriteHeader(http.StatusServiceUnavailable)
    }
    
    json.NewEncoder(w).Encode(map[string]interface{}{
        "status": map[bool]string{true: "ready", false: "not_ready"}[allHealthy],
        "dependencies": checks,
        "timestamp": time.Now().Format(time.RFC3339),
    })
}

【PYTHON ✅】
from fastapi import FastAPI, status
from fastapi.responses import JSONResponse

app = FastAPI()

@app.get("/health")
async def liveness():
    return {"status": "alive", "timestamp": datetime.utcnow().isoformat()}

@app.get("/ready")
async def readiness():
    checks = {
        "db": await check_database(),
        "cache": await check_redis(),
        "vector_store": await check_qdrant(),
    }
    all_healthy = all(v == "ok" for v in checks.values())
    
    status_code = status.HTTP_200_OK if all_healthy else status.HTTP_503_SERVICE_UNAVAILABLE
    return JSONResponse(
        status_code=status_code,
        content={
            "status": "ready" if all_healthy else "not_ready",
            "dependencies": checks,
            "timestamp": datetime.utcnow().isoformat(),
        }
    )

【BASH ✅】
#!/bin/bash
# Script de healthcheck para orquestadores
check_health() {
    local service_name="$1"
    
    # Liveness: ¿el proceso está corriendo?
    if ! pgrep -f "$service_name" > /dev/null; then
        echo '{"status":"dead","error":"process_not_found"}'
        return 1
    fi
    
    # Readiness: verificar puertos y dependencias
    if ! nc -z localhost 8080; then
        echo '{"status":"not_ready","error":"port_not_listening"}'
        return 1
    fi
    
    # Verificar endpoint /ready si existe
    if response=$(curl -sSf http://localhost:8080/ready 2>/dev/null); then
        echo "$response"
        return 0
    else
        echo '{"status":"not_ready","error":"ready_endpoint_failed"}'
        return 1
    fi
}

❌ Violación crítica:
• Healthcheck que siempre retorna 200 → orquestador no detecta fallos reales
• `/ready` que no verifica dependencias críticas → tráfico enviado a servicio no funcional
• Healthcheck que hace operaciones pesadas (ej: query completa) → degrada rendimiento
```

### AR-008: Logging Estructurado con Correlación Distribuida (C8-LOGGING)

```
【REGLA AR-008】Todo log debe ser JSON estructurado con campos obligatorios para trazabilidad.

✅ Campos obligatorios en cada log:
```json
{
  "timestamp": "2026-04-19T12:00:00Z",  // RFC3339 UTC, obligatorio
  "level": "INFO|WARN|ERROR|DEBUG",     // Nivel estandarizado
  "event": "request_received|query_executed|retry_attempted",  // Nombre canónico del evento
  "tenant_id": "cliente_001",            // Para aislamiento y billing (C4)
  "trace_id": "otel-abc123xyz",          // Para correlación distribuida (OpenTelemetry)
  "span_id": "span-def456",              // Opcional, para trazas detalladas
  "duration_ms": 42,                     // Para métricas de performance
  "status": "success|degraded|failed",   // Resultado de la operación
  "error": null,                         // Solo si level >= ERROR, mensaje sin PII
  "metadata": {}                         // Campos adicionales específicos del evento
}
```

✅ Implementación por stack:

【GO ✅】
import (
    "log/slog"
    "os"
    "time"
)

func initLogger(serviceName string) *slog.Logger {
    return slog.New(slog.NewJSONHandler(os.Stderr, &slog.HandlerOptions{
        Level: slog.LevelInfo,
        ReplaceAttr: func(groups []string, a slog.Attr) slog.Attr {
            // Scrubbing de campos sensibles (C3 + C8)
            sensitive := map[string]bool{
                "password": true, "secret": true, "token": true,
                "api_key": true, "credential": true,
            }
            if sensitive[a.Key] {
                return slog.String(a.Key, "***REDACTED***")
            }
            return a
        },
    }))
}

// Uso en handler
func handleRequest(ctx context.Context, logger *slog.Logger, r *http.Request) {
    tenantID := r.Header.Get("X-Tenant-ID")
    traceID := trace.SpanFromContext(ctx).SpanContext().TraceID().String()
    
    start := time.Now()
    
    logger.InfoContext(ctx, "request_received",
        "tenant_id", tenantID,
        "trace_id", traceID,
        "method", r.Method,
        "path", r.URL.Path,
    )
    
    // ... procesar request ...
    
    duration := time.Since(start).Milliseconds()
    logger.InfoContext(ctx, "request_completed",
        "tenant_id", tenantID,
        "trace_id", traceID,
        "duration_ms", duration,
        "status", "success",
    )
}

【PYTHON ✅】
import logging
import json
import sys
from datetime import datetime, timezone

class StructuredFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        log_entry = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "level": record.levelname,
            "event": getattr(record, "event", record.getMessage()),
            "tenant_id": getattr(record, "tenant_id", None),
            "trace_id": getattr(record, "trace_id", None),
            "duration_ms": getattr(record, "duration_ms", None),
            "status": getattr(record, "status", None),
        }
        
        # Añadir campos extra si existen
        for key, value in record.__dict__.items():
            if key not in ["name", "msg", "args", "levelname", "levelno", "pathname", 
                          "filename", "module", "lineno", "funcName", "created", 
                          "msecs", "relativeCreated", "thread", "threadName", 
                          "processName", "process", "getMessage", "event", 
                          "tenant_id", "trace_id", "duration_ms", "status"]:
                # Scrubbing de campos sensibles
                if key.lower() in ["password", "secret", "token", "api_key"]:
                    log_entry[key] = "***REDACTED***"
                else:
                    log_entry[key] = value
        
        # Solo añadir error si level >= ERROR
        if record.exc_info and record.levelno >= logging.ERROR:
            log_entry["error"] = self.formatException(record.exc_info)
        
        return json.dumps(log_entry)

# Configurar logger
logger = logging.getLogger("mantis")
logger.setLevel(logging.INFO)
handler = logging.StreamHandler(sys.stderr)
handler.setFormatter(StructuredFormatter())
logger.addHandler(handler)

# Uso
logger.info("request_received", extra={
    "event": "request_received",
    "tenant_id": "cliente_001",
    "trace_id": "otel-abc123",
    "method": "POST",
    "path": "/api/v1/query"
})

❌ Violación crítica:
• Log que expone `password` o `api_key` en texto plano → violación C3 + C8
• Timestamp en formato local o sin zona horaria → imposible correlacionar logs distribuidos
• Falta `tenant_id` en logs de operaciones con datos → imposible auditar aislamiento (C4)
• Log sin `trace_id` → imposible correlacionar con trazas de OpenTelemetry
```

### AR-009: Métricas Estandarizadas para Observabilidad (C8-METRICS)

```
【REGLA AR-009】Todo servicio debe exponer métricas en formato Prometheus para monitoreo.

✅ Métricas canónicas obligatorias:
```prometheus
# HELP mantis_request_duration_seconds Duration of API requests in seconds
# TYPE mantis_request_duration_seconds histogram
mantis_request_duration_seconds_bucket{tenant_id="cliente_001",method="POST",status="200",le="0.1"} 120
mantis_request_duration_seconds_bucket{tenant_id="cliente_001",method="POST",status="200",le="0.5"} 150
mantis_request_duration_seconds_bucket{tenant_id="cliente_001",method="POST",status="200",le="1"} 155
mantis_request_duration_seconds_sum{tenant_id="cliente_001",method="POST",status="200"} 45.2
mantis_request_duration_seconds_count{tenant_id="cliente_001",method="POST",status="200"} 155

# HELP mantis_errors_total Total number of errors by type and tenant
# TYPE mantis_errors_total counter
mantis_errors_total{tenant_id="cliente_001",error_type="timeout"} 3
mantis_errors_total{tenant_id="cliente_001",error_type="validation"} 12

# HELP mantis_active_connections Current number of active connections by tenant
# TYPE mantis_active_connections gauge
mantis_active_connections{tenant_id="cliente_001",type="db"} 5
mantis_active_connections{tenant_id="cliente_001",type="http"} 23
```

✅ Implementación por stack:

【GO ✅】
import (
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promauto"
)

var (
    requestDuration = promauto.NewHistogramVec(prometheus.HistogramOpts{
        Name: "mantis_request_duration_seconds",
        Help: "Duration of API requests in seconds",
        Buckets: []float64{0.01, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10},
    }, []string{"tenant_id", "method", "status"})
    
    errorsTotal = promauto.NewCounterVec(prometheus.CounterOpts{
        Name: "mantis_errors_total",
        Help: "Total number of errors by type and tenant",
    }, []string{"tenant_id", "error_type"})
)

// Uso en handler
func instrumentedHandler(w http.ResponseWriter, r *http.Request) {
    tenantID := r.Header.Get("X-Tenant-ID")
    start := time.Now()
    
    // ... procesar request ...
    
    status := "200"  // Determinar status code real
    duration := time.Since(start).Seconds()
    
    requestDuration.WithLabelValues(tenantID, r.Method, status).Observe(duration)
    
    if status >= "500" {
        errorsTotal.WithLabelValues(tenantID, "server_error").Inc()
    }
}

// Exponer métricas en /metrics
http.Handle("/metrics", promhttp.Handler())

❌ Violación crítica:
• No exponer `/metrics` endpoint → imposible monitorear salud del servicio
• Métricas sin etiqueta `tenant_id` → imposible hacer billing o debugging por cliente
• Histogramas con buckets mal definidos → métricas inútiles para alertas
```

### AR-010: Documentación de Contrato de API en Frontmatter (C5 + C6)

```
【REGLA AR-010】Todo artefacto de API debe documentar su contrato en frontmatter.

✅ Frontmatter canónico para APIs:
```yaml
---
canonical_path: "/06-PROGRAMMING/go/webhook-handler.go.md"
artifact_type: "skill_go"
constraints_mapped: ["C2", "C4", "C5", "C6", "C7", "C8"]

# Contrato de API
api_contract:
  endpoint: "/api/v1/webhooks/whatsapp"
  method: "POST"
  idempotent: true
  dry_run_supported: true
  
  # Request
  request:
    headers:
      X-Tenant-ID: { required: true, pattern: "^cli_[a-z0-9]+$" }
      X-Idempotency-Key: { required: true, min_length: 10 }
      Content-Type: { required: true, value: "application/json" }
    body_schema: "jsonschema:webhook-payload-v1.json"
  
  # Response
  response:
    success:
      status: 200
      schema: "jsonschema:webhook-response-v1.json"
    degraded:
      status: 200
      headers: { X-Service-Status: "degraded" }
      schema: "jsonschema:degraded-response-v1.json"
    error:
      status: 4xx|5xx
      schema: "jsonschema:error-response-v1.json"
  
  # Resiliencia
  resilience:
    retry: { max_attempts: 3, backoff: "exponential_jitter", base: "1s", max: "30s" }
    timeout: "30s"
    fallback: "cache_or_partial"
  
  # Observabilidad
  observability:
    metrics: ["mantis_request_duration_seconds", "mantis_errors_total"]
    logs: ["request_received", "request_completed", "retry_attempted"]
    traces: true  # OpenTelemetry enabled

# Validación
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/go/webhook-handler.go.md --checks C6,C7,C8 --json"
---
```

✅ Verificación automática:
```bash
# Validar que artifact de API declara contrato
validate_api_contract() {
    local file="$1"
    local is_api=$(yq eval '.artifact_type | test("skill_")' "$file")
    
    if [ "$is_api" = "true" ]; then
        # Verificar campos obligatorios de api_contract
        required_fields=("endpoint" "method" "request" "response")
        for field in "${required_fields[@]}"; do
            if ! yq eval ".api_contract.$field" "$file" | grep -q .; then
                echo "ERROR: API artifact must declare api_contract.$field in frontmatter"
                return 1
            fi
        done
    fi
    return 0
}
```

❌ Violación crítica:
• Endpoint POST sin declarar `idempotent: true` o justificación
• No documentar `dry_run_supported` si la operación modifica estado
• Contrato de response que no incluye caso `degraded` para fallback
```

---

## 【2】🛡️ VALIDACIÓN AUTOMÁTICA DE C6+C7+C8 (Toolchain Integration)

<!-- 
【EDUCATIVO】Estas herramientas permiten validar automáticamente el cumplimiento de confiabilidad de APIs.
-->

### 2.1 orchestrator-engine.sh – Validación Integral de Confiabilidad

```bash
# 📍 Ubicación
05-CONFIGURATIONS/validation/orchestrator-engine.sh

# 🎯 Propósito
Validar que APIs declaran y cumplen C6 (verificabilidad), C7 (resiliencia) y C8 (observabilidad).

# 📦 Flags Principales
--file <ruta>              # Artefacto a validar
--checks C6,C7,C8          # Validar específicamente confiabilidad de APIs
--mode <headless|interactive>  # headless para CI/CD
--json                     # Salida en formato JSON

# ✅ Ejemplo: Validar artifact de API
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/go/webhook-handler.go.md \
  --checks C6,C7,C8 \
  --mode headless \
  --json

# 📤 Salida Esperada (JSON)
{
  "file": "06-PROGRAMMING/go/webhook-handler.go.md",
  "constraints_checked": ["C6", "C7", "C8"],
  "c6_validation": {
    "idempotency_declared": true,
    "dry_run_supported": true,
    "exit_codes_standardized": true,
    "passed": true
  },
  "c7_validation": {
    "retry_with_backoff": true,
    "fallback_degraded": true,
    "graceful_shutdown": true,
    "healthcheck_endpoint": true,
    "passed": true
  },
  "c8_validation": {
    "structured_logging": true,
    "pii_scrubbing": true,
    "trace_id_included": true,
    "metrics_prometheus": true,
    "passed": true
  },
  "score": 44,
  "passed": true,
  "blocking_issues": [],
  "recommendations": [
    "Consider adding X-Retry-After header in degraded responses"
  ]
}
```

### 2.2 verify-constraints.sh – Validación de Declaración de C6/C7/C8

```bash
# 📍 Ubicación
05-CONFIGURATIONS/validation/verify-constraints.sh

# 🎯 Propósito
Verificar que artifacts declaran C6/C7/C8 en constraints_mapped cuando aplican.

# ✅ Ejemplo: Validar declaración de C7
bash 05-CONFIGURATIONS/validation/verify-constraints.sh \
  --file 06-PROGRAMMING/python/api-handler.md \
  --check-constraint C7 \
  --json

# 📤 Salida Esperada (JSON)
{
  "file": "06-PROGRAMMING/python/api-handler.md",
  "constraint_checked": "C7",
  "declared_in_frontmatter": true,
  "resilience_patterns_present": true,
  "passed": true
}
```

---

## 【3】🧭 PROTOCOLO DE IMPLEMENTACIÓN DE CONFIABILIDAD (PASO A PASO)

```
┌─────────────────────────────────────────────────────────┐
│ 【FASE 0】DEFINIR CONTRATO DE API                      │
├─────────────────────────────────────────────────────────┤
│ 1. Documentar endpoint, method, request/response en frontmatter │
│ 2. Declarar idempotencia, dry-run, timeouts            │
│ 3. Especificar métricas y logs obligatorios            │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 1】IMPLEMENTAR VERIFICABILIDAD (C6)             │
├─────────────────────────────────────────────────────────┤
│ 1. Añadir header X-Idempotency-Key para operaciones que modifican estado │
│ 2. Implementar flag --dry-run o query param dry_run=true │
│ 3. Estandarizar exit codes: 0=success, 1=retryable, 2=degraded │
│ 4. Loguear prompt_hash para reproducibilidad forense   │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 2】IMPLEMENTAR RESILIENCIA (C7)                 │
├─────────────────────────────────────────────────────────┤
│ 1. Retry con exponentialBackoff + jitter para llamadas externas │
│ 2. Fallback degradado: cache o respuesta parcial al fallar │
│ 3. Graceful shutdown con defer/finally/trap para cleanup │
│ 4. Endpoints /health y /ready para orquestación        │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 3】IMPLEMENTAR OBSERVABILIDAD (C8)              │
├─────────────────────────────────────────────────────────┤
│ 1. Logging JSON a stderr con campos obligatorios       │
│ 2. Scrubbing automático de PII/secrets antes de loguear │
│ 3. Incluir tenant_id y trace_id en cada log event      │
│ 4. Exponer métricas Prometheus en /metrics             │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 4】VALIDACIÓN AUTOMÁTICA Y TESTS                │
├─────────────────────────────────────────────────────────┤
│ 1. Ejecutar orchestrator-engine.sh --checks C6,C7,C8   │
│ 2. Añadir tests de idempotencia, retry y fallback      │
│ 3. Verificar que logs son estructurados y scrubeados   │
└─────────────────────────────────────────────────────────┘
```

### 3.1 Ejemplo de Traza de Implementación de Confiabilidad

```
【TRAZA DE IMPLEMENTACIÓN C6+C7+C8】
Tarea: "Handler de webhooks para WhatsApp con alta confiabilidad"

Fase 0 - Contrato de API:
  • Endpoint: POST /api/v1/webhooks/whatsapp, idempotent: true ✅
  • Request: headers X-Tenant-ID, X-Idempotency-Key; body schema webhook-payload-v1.json ✅
  • Response: success 200, degraded 200+X-Service-Status:degraded, error 4xx/5xx ✅
  • Documentar en frontmatter: api_contract, resilience, observability ✅

Fase 1 - Verificabilidad (C6):
  • Implementar verificación de X-Idempotency-Key con cache Redis ✅
  • Añadir query param ?dry_run=true para simular sin ejecutar ✅
  • Estandarizar exit codes: 0=success, 1=retryable, 2=degraded ✅
  • Loguear prompt_hash en cada evento para auditoría ✅

Fase 2 - Resiliencia (C7):
  • Retry con exponentialBackoff + jitter para llamadas a API de WhatsApp ✅
  • Fallback: retornar cached response + header X-Service-Status:degraded ✅
  • Graceful shutdown: trap cleanup EXIT, defer db.Close() en Go ✅
  • Endpoints /health (liveness) y /ready (readiness) para Kubernetes ✅

Fase 3 - Observabilidad (C8):
  • Logging JSON a stderr con slog, campos: timestamp, level, event, tenant_id, trace_id ✅
  • Scrubbing de password/token/api_key → ***REDACTED*** antes de loguear ✅
  • Incluir trace_id de OpenTelemetry en cada log para correlación distribuida ✅
  • Exponer métricas Prometheus: mantis_request_duration_seconds, mantis_errors_total ✅

Fase 4 - Validación automática:
  • orchestrator-engine.sh --checks C6,C7,C8 → score=46, passed=true ✅
  • Tests: TestIdempotency, TestRetryWithBackoff, TestFallbackDegraded ✅
  • CI/CD: fallar build si tests de confiabilidad no pasan ✅

Resultado: ✅ Handler de webhooks con confiabilidad certificada C6+C7+C8.
```

---

## 【4】📚 GLOSARIO PARA PRINCIPIANTES

<!-- 
【EDUCATIVO】Términos técnicos explicados en lenguaje simple.
-->

| Término | Significado simple | Ejemplo |
|---------|-------------------|---------|
| **C6 (Verifiable Execution)** | Regla que exige que todo proceso sea reproducible y auditable | `--dry-run`, exit codes estandarizados, `prompt_hash` en logs |
| **C7 (Operational Resilience)** | Regla que exige manejo explícito de fallos con retry y fallback | `retry.ExponentialBackoff()`, retornar cache si API externa falla |
| **C8 (Structured Logging)** | Regla que exige logs JSON con campos obligatorios para trazabilidad | `{"timestamp":"...","level":"INFO","tenant_id":"cli_001","trace_id":"otel-xyz"}` |
| **Idempotencia** | Ejecutar N veces → mismo resultado que 1 vez, sin efectos secundarios duplicados | `X-Idempotency-Key` header para evitar duplicados en retry |
| **Backoff Exponencial + Jitter** | Esperar cada vez más entre retries, con aleatoriedad para evitar sincronización | 1s, 2s, 4s... ±25% aleatorio |
| **Fallback Degradado** | Retornar respuesta parcial o cacheada al fallar, no error crudo | `{"status":"degraded","retry_after":60}` |
| **Graceful Shutdown** | Liberar recursos (DB, locks, archivos) antes de terminar el proceso | `defer db.Close()` en Go, `trap cleanup EXIT` en Bash |
| **Healthcheck** | Endpoint que orquestadores consultan para saber si el servicio está sano | `/health` → `{"status":"alive"}`, `/ready` → verifica dependencias |
| **Trace ID** | Identificador único que correlaciona logs, métricas y trazas de una request distribuida | `trace_id: "otel-abc123"` en cada log del flujo |
| **PII Scrubbing** | Reemplazar datos personales por `***REDACTED***` en logs para privacidad | `password: "***REDACTED***"` en lugar de valor real |

---

## 【5】🧪 SANDBOX DE PRUEBA (OPCIONAL)

<!-- 
【PARA DESARROLLADORES】Pega esta sección en un chat nuevo para validar que la IA sigue el protocolo sin contexto previo.
-->

```
【TEST MODE: API-RELIABILITY VALIDATION】
Prompt de prueba: "Generar endpoint de consulta RAG con alta confiabilidad para multi-tenant"

Respuesta esperada de la IA:
1. Declarar en frontmatter: constraints_mapped: ["C2","C4","C6","C7","C8"], api_contract con endpoint/method
2. Implementar C6:
   • X-Idempotency-Key para queries que pueden ser retryadas
   • Query param ?dry_run=true para simular sin ejecutar
   • Exit codes: 0=success, 1=retryable, 2=degraded
3. Implementar C7:
   • Retry con exponentialBackoff + jitter para llamadas a vector DB
   • Fallback: retornar resultados cacheados si pgvector timeout
   • Graceful shutdown con cleanup de conexiones DB
   • Endpoints /health y /ready para orquestación
4. Implementar C8:
   • Logging JSON con tenant_id, trace_id, timestamp RFC3339
   • Scrubbing de secrets en logs
   • Métricas Prometheus: mantis_request_duration_seconds, mantis_errors_total
5. Validar con orchestrator-engine.sh --checks C6,C7,C8 → score >= 30
6. Incluir tests: TestIdempotency, TestRetryWithBackoff, TestFallbackDegraded

Si la IA omite idempotencia, no implementa fallback, o entrega sin validation_command → FALLA DE CONFIABILIDAD C6/C7.
```

---

## 【6】🔗 REFERENCIAS CANÓNICAS (WIKILINKS)

<!-- 
【PARA IA】Estos enlaces deben resolverse usando PROJECT_TREE.md. 
No uses rutas relativas. Usa siempre la forma canónica [[RUTA]].
-->

- `[[00-STACK-SELECTOR]]` → Motor de decisión de stack
- `[[PROJECT_TREE]]` → Mapa canónico de rutas
- `[[GOVERNANCE-ORCHESTRATOR]]` → Tiers y validación
- `[[05-CONFIGURATIONS/validation/norms-matrix.json]]` → Mapeo de constraints por carpeta
- `[[01-RULES/harness-norms-v3.0.md]]` → Definición textual de C6/C7/C8
- `[[01-RULES/02-RESOURCE-GUARDRAILS.md]]` → Implementación de C1+C2 (timeouts, límites)
- `[[01-RULES/09-AGENTIC-OUTPUT-RULES.md]]` → Logging estructurado y auditoría
- `[[TOOLCHAIN-REFERENCE]]` → Catálogo de herramientas de validación

---

## 【7】📦 METADATOS DE EXPANSIÓN (PARA FUTURAS VERSIONES)

<!-- 
【PARA MANTENEDORES】Nuevas secciones deben seguir este formato para no romper compatibilidad.
-->

```json
{
  "expansion_registry": {
    "new_reliability_pattern": {
      "requires_files_update": [
        "01-RULES/04-API-RELIABILITY-RULES.md: add pattern with format ## AR-XXX: <TÍTULO>",
        "05-CONFIGURATIONS/validation/orchestrator-engine.sh: add check for new pattern",
        "06-PROGRAMMING/: add language-specific implementation examples",
        "Human approval required: true"
      ],
      "backward_compatibility": "new patterns must not break existing C6/C7/C8 validation for existing artifacts"
    },
    "new_metric_standard": {
      "requires_files_update": [
        "01-RULES/04-API-RELIABILITY-RULES.md: add metric to AR-009 table",
        "05-CONFIGURATIONS/observability/: update Prometheus config examples",
        "Dashboard templates: add new metric to default views",
        "Human approval required: true"
      ],
      "backward_compatibility": "new metrics must be optional for existing services; not required for validation pass"
    }
  },
  "compatibility_rule": "Nuevas reglas de confiabilidad no deben invalidar artefactos generados bajo versiones anteriores. Cambios breaking requieren major version bump, guía de migración y aprobación humana explícita."
}
```

---

<!-- 
═══════════════════════════════════════════════════════════
🤖 SECCIÓN PARA IA: ÁRBOL JSON ENRIQUECIDO
═══════════════════════════════════════════════════════════
Esta sección contiene metadatos estructurados para consumo automático por agentes de IA.
No está diseñada para lectura humana directa. Los humanos deben usar las secciones 【1】-【7】.

Formato: JSON válido, con comentarios explicativos en claves "doc_*".
Prioridad de ejecución: Las reglas se aplican en orden AR-001 → AR-010.
Dependencias: Cada nodo declara sus archivos requeridos y sus efectos colaterales.
═══════════════════════════════════════════════════════════
-->

```json
{
  "api_reliability_metadata": {
    "version": "3.0.0-SELECTIVE",
    "canonical_path": "/01-RULES/04-API-RELIABILITY-RULES.md",
    "artifact_type": "governance_rule_set",
    "immutable": true,
    "requires_human_approval_for_changes": true,
    "constraints_primary": ["C6", "C7", "C8"],
    "llm_optimizations": {
      "oriental_models_friendly": true,
      "delimiters_used": ["【】", "┌─┐", "▼", "✅/❌/🔧"],
      "numbered_sequences": true,
      "stop_conditions_explicit": true
    }
  },
  
  "rules_catalog": {
    "AR-001": {"title": "Idempotencia por Diseño", "constraint": "C6", "priority": "critical", "blocking_if_violated": true, "validation_tool": "orchestrator-engine.sh --checks C6"},
    "AR-002": {"title": "Dry-Run como Requisito", "constraint": "C6", "priority": "high", "blocking_if_violated": false, "validation_tool": "manual review + dry-run test"},
    "AR-003": {"title": "Exit Codes Estandarizados", "constraint": "C6", "priority": "high", "blocking_if_violated": false, "validation_tool": "exit code audit in CI/CD"},
    "AR-004": {"title": "Retry con Backoff Exponencial + Jitter", "constraint": "C7", "priority": "critical", "blocking_if_violated": true, "validation_tool": "orchestrator-engine.sh --checks C7"},
    "AR-005": {"title": "Fallback Degradado al Alcanzar Límites", "constraint": "C7", "priority": "high", "blocking_if_violated": false, "validation_tool": "fallback test suite"},
    "AR-006": {"title": "Graceful Shutdown con Cleanup Garantizado", "constraint": "C7", "priority": "high", "blocking_if_violated": false, "validation_tool": "shutdown test + resource leak detection"},
    "AR-007": {"title": "Healthchecks Estandarizados para Orquestación", "constraint": "C7", "priority": "high", "blocking_if_violated": false, "validation_tool": "health endpoint validation"},
    "AR-008": {"title": "Logging Estructurado con Correlación Distribuida", "constraint": "C8", "priority": "high", "blocking_if_violated": false, "validation_tool": "structured log validator + PII scrubber"},
    "AR-009": {"title": "Métricas Estandarizadas para Observabilidad", "constraint": "C8", "priority": "medium", "blocking_if_violated": false, "validation_tool": "Prometheus metrics validation"},
    "AR-010": {"title": "Documentación de Contrato de API en Frontmatter", "constraint": "C5+C6", "priority": "high", "blocking_if_violated": true, "validation_tool": "validate-frontmatter.sh + api_contract check"}
  },
  
  "validation_integration": {
    "orchestrator-engine.sh": {
      "purpose": "Validación integral de C6 (verificabilidad), C7 (resiliencia), C8 (observabilidad)",
      "flags": ["--file", "--checks", "--mode", "--json"],
      "exit_codes": {"0": "passed", "1": "failed"},
      "output_format": "JSON con c6_validation, c7_validation, c8_validation, score, blocking_issues"
    },
    "verify-constraints.sh": {
      "purpose": "Validar declaración de C6/C7/C8 en frontmatter",
      "flags": ["--file", "--check-constraint", "--json"],
      "exit_codes": {"0": "passed", "1": "failed"},
      "output_format": "JSON con constraint_checked, declared_in_frontmatter, patterns_present"
    }
  },
  
  "dependency_graph": {
    "critical_infrastructure": [
      {"file": "05-CONFIGURATIONS/validation/norms-matrix.json", "purpose": "Mapear C6/C7/C8 como constraints validables", "load_order": 1},
      {"file": "01-RULES/harness-norms-v3.0.md", "purpose": "Definición textual canónica de C6/C7/C8", "load_order": 2},
      {"file": "GOVERNANCE-ORCHESTRATOR.md", "purpose": "Tiers y scoring para validación de APIs", "load_order": 3}
    ],
    "implementation_patterns": [
      {"file": "06-PROGRAMMING/go/webhook-validation-patterns.go.md", "purpose": "Patrones de idempotencia y retry en Go", "load_order": 1},
      {"file": "06-PROGRAMMING/python/robust-error-handling.md", "purpose": "Patrones de fallback y graceful shutdown en Python", "load_order": 2},
      {"file": "06-PROGRAMMING/bash/robust-error-handling.md", "purpose": "Cleanup y error handling en Bash", "load_order": 3}
    ]
  },
  
  "human_readable_errors": {
    "idempotency_missing": "Endpoint POST en '{file}' sin declarar idempotencia. Añadir X-Idempotency-Key header o justificar por qué no aplica.",
    "dry_run_not_supported": "Operación que modifica estado en '{file}' sin soporte para --dry-run. Añadir flag o query param para simulación.",
    "exit_codes_non_standard": "Script en '{file}' usa exit codes no estandarizados. Adoptar: 0=success, 1=retryable, 2=degraded, 3+=fatal.",
    "retry_without_backoff": "Retry en '{file}' sin backoff exponencial o jitter. Implementar exponentialBackoff() para evitar thundering herd.",
    "fallback_missing": "Componente en '{file}' no implementa fallback degradado. Retornar cache o respuesta parcial al fallar, no error crudo.",
    "cleanup_not_guaranteed": "Recurso adquirido en '{file}' sin defer/finally/trap para cleanup en shutdown. Garantizar liberación de recursos.",
    "healthcheck_missing": "Servicio en '{file}' sin endpoints /health o /ready. Añadir para orquestación y monitoreo.",
    "logging_unstructured": "Log en '{file}' no sigue formato JSON estructurado. Usar slog/pydantic-logging con tenant_id y trace_id.",
    "metrics_not_exposed": "Servicio en '{file}' no expone métricas Prometheus en /metrics. Añadir para observabilidad.",
    "api_contract_incomplete": "Frontmatter en '{file}' declara API pero omite api_contract.endpoint o api_contract.request. Completar contrato canónico."
  },
  
  "expansion_hooks": {
    "new_reliability_pattern": {
      "requires_files_update": [
        "01-RULES/04-API-RELIABILITY-RULES.md: add pattern with format ## AR-XXX: <TÍTULO>",
        "05-CONFIGURATIONS/validation/orchestrator-engine.sh: add check for new pattern",
        "06-PROGRAMMING/: add language-specific implementation examples",
        "Human approval required: true"
      ],
      "backward_compatibility": "new patterns must not break existing C6/C7/C8 validation for existing artifacts"
    },
    "new_metric_standard": {
      "requires_files_update": [
        "01-RULES/04-API-RELIABILITY-RULES.md: add metric to AR-009 table",
        "05-CONFIGURATIONS/observability/: update Prometheus config examples",
        "Dashboard templates: add new metric to default views",
        "Human approval required: true"
      ],
      "backward_compatibility": "new metrics must be optional for existing services; not required for validation pass"
    }
  },
  
  "validation_metadata": {
    "orchestrator_compatibility": ">=3.0.0-SELECTIVE",
    "schema_version": "api-reliability-rules.v1.json",
    "checksum_algorithm": "SHA256",
    "audit_log_format": "JSON Lines with RFC3339 timestamps",
    "pii_scrubbing": "enabled for all logs and outputs (C3 + C8 compliance)",
    "reproducibility_guarantee": "Any API reliability validation can be reproduced identically using this rule set + orchestrator-engine.sh"
  }
}
```

---

## ✅ CHECKLIST DE VALIDACIÓN POST-GENERACIÓN

<!-- 
【PARA PRINCIPIANTES】Antes de guardar este archivo, verifica estos puntos.
-->

````markdown
```bash
# 1. Frontmatter válido
yq eval '.canonical_path' 01-RULES/04-API-RELIABILITY-RULES.md | grep -q "/01-RULES/04-API-RELIABILITY-RULES.md" && echo "✅ Ruta canónica correcta"

# 2. Constraints mapeadas (C6+C7+C8)
yq eval '.constraints_mapped | contains(["C6"]) and contains(["C7"]) and contains(["C8"])' 01-RULES/04-API-RELIABILITY-RULES.md && echo "✅ C6, C7 y C8 declaradas"

# 3. Reglas presentes
grep -c "AR-0[0-9][0-9]:" 01-RULES/04-API-RELIABILITY-RULES.md | awk '{if($1==10) print "✅ 10 reglas de confiabilidad"; else print "⚠️ Faltan reglas"}'

# 4. Ejemplos por lenguaje presentes
grep -q "【GO ✅】\|【PYTHON ✅】\|【BASH ✅】" 01-RULES/04-API-RELIABILITY-RULES.md && echo "✅ Ejemplos multi-lenguaje presentes"

# 5. JSON válido
tail -n +$(grep -n '```json' 01-RULES/04-API-RELIABILITY-RULES.md | tail -1 | cut -d: -f1) 01-RULES/04-API-RELIABILITY-RULES.md | sed -n '/```json/,/```/p' | sed '1d;$d' | jq empty && echo "✅ JSON parseable"

# 6. Wikilinks canónicos
for link in $(grep -oE '\[\[[^]]+\]\]' 01-RULES/04-API-RELIABILITY-RULES.md | tr -d '[]' | sort -u); do
  [ -f "${link#//}" ] || echo "⚠️ Wikilink roto: $link"
done
```
````

**Criterio de aceptación:**  
- ✅ Frontmatter válido con `canonical_path: "/01-RULES/04-API-RELIABILITY-RULES.md"`  
- ✅ `constraints_mapped` incluye C6, C7 y C8 (aplicables a APIs)  
- ✅ 10 reglas AR-001 a AR-010 documentadas con ejemplos ✅/❌/🔧  
- ✅ Integración con `orchestrator-engine.sh --checks C6,C7,C8` para validación automática  
- ✅ Sección JSON final es válida (puede parsearse con `jq .`)  
- ✅ Todos los wikilinks apuntan a archivos existentes en `PROJECT_TREE.md`  

---

> 🎯 **Mensaje final para el lector humano**:  
> Este contrato es tu garantía de confiabilidad. No es opcional.  
> **Idempotencia → Retry → Fallback → Shutdown → Logging → Métricas**.  
> Si sigues ese flujo, nunca entregarás una API que falle silenciosamente o bloquee el sistema.  
> La gobernanza no es una carga. Es la libertad de escalar sin miedo a romper.  

**¿Listo para proceder con el siguiente documento: `01-RULES/07-SCALABILITY-RULES.md`?** 🔧
