---
canonical_path: "/01-RULES/02-RESOURCE-GUARDRAILS.md"
artifact_id: "resource-guardrails-canonical"
artifact_type: "governance_rule_set"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C1", "C2", "C5", "C6", "C7"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 01-RULES/02-RESOURCE-GUARDRAILS.md --mode headless --json"
tier: 1
immutable: true
requires_human_approval_for_changes: true
related_files:
  - "[[00-STACK-SELECTOR.md]]"
  - "[[PROJECT_TREE.md]]"
  - "[[GOVERNANCE-ORCHESTRATOR.md]]"
  - "[[05-CONFIGURATIONS/validation/norms-matrix.json]]"
  - "[[01-RULES/harness-norms-v3.0.md]]"
  - "[[06-PROGRAMMING/go/resource-limits-c1-c2.go.md]]"
checksum_sha256: "PENDING_GENERATION"
---

# 📄 01-RULES/02-RESOURCE-GUARDRAILS.md – REGENERADO v3.0-SELECTIVE

> **Nota para principiantes:** Este documento define las reglas inamovibles para límites de recursos (C1) y control de concurrencia/timeouts (C2) en MANTIS AGENTIC. Si eres nuevo, lee las secciones en orden. Si eres experto, salta al JSON final.  
>  
> **Para IAs:** Este es tu contrato de recursos. **VIOLAR C1/C2 = BLOQUEO INMEDIATO**. No inventes, no asumas, no omitas.


# ⚙️ 02-RESOURCE-GUARDRAILS: Contrato de Límites de Recursos y Concurrencia (C1 + C2 Enforcement)

<!-- 
【PARA PRINCIPIANTES】¿Qué es este archivo?
Este documento es el "manual de límites" del proyecto MANTIS AGENTIC.
Define las reglas inamovibles para garantizar que todo componente:
• Respeta límites explícitos de memoria, CPU, pids y tamaño de archivo (C1)
• Gestiona concurrencia y timeouts de forma controlada y predecible (C2)
• Se degrada elegantemente al alcanzar límites, no crashea
• Es auditable en uso de recursos por tenant

Si eres nuevo: lee en orden. 
Si ya conoces el proyecto: usa los wikilinks para ir directo a lo que necesitas.
-->

> **Instrucción crítica para la IA:** 
> Este documento es tu contrato de recursos. 
> **VIOLAR C1/C2 = BLOQUEO INMEDIATO**. 
> No inventes, no asumas, no omitas. Si algo no está claro, DETENER y preguntar.

---

## 【0】🎯 PROPÓSITO Y ALCANCE (Explicado para humanos)

<!-- 
【EDUCATIVO】Este documento responde: "¿Cómo garantizo que mi código no consuma recursos ilimitados ni bloquee el sistema?"
No es una lista de buenas prácticas. Es un sistema de contención que:
• Previene DoS por configuración errónea desde el diseño
• Garantiza que timeouts y límites son explícitos, no implícitos
• Permite degradación elegante al alcanzar límites, no fallos catastróficos
• Audita uso de recursos por tenant para billing y debugging
-->

### 0.1 C1 + C2 – Definiciones Canónicas

```
C1 (Resource Limits): Todo componente debe declarar límites explícitos de:
• Memoria (RAM): ej: 512MB, 1GB
• CPU: ej: 0.5 cores, 2 cores
• PIDs/hilos: ej: máximo 100 procesos hijos
• Tamaño de archivo: ej: logs rotados cada 100MB

✅ Cumplimiento: `mem_limit: 512M` en Docker, `debug.SetMemoryLimit()` en Go, `ulimit -v` en Bash

❌ Violación crítica: Contenedor sin `mem_limit`, bucle infinito sin condición de salida, archivo de log sin rotación

---

C2 (Concurrency & Timeout Control): Todo componente concurrente debe gestionar explícitamente:
• Timeouts de operación: ej: 30s para query DB, 5s para llamada HTTP
• Límites de concurrencia: ej: máximo 10 goroutines paralelas
• Cancelación propagada: ej: context.Done() en Go, asyncio cancellation en Python
• Cleanup garantizado: ej: defer, try/finally, trap EXIT en Bash

✅ Cumplimiento: `context.WithTimeout(ctx, 30*time.Second)`, `asyncio.wait_for(coro, timeout=30)`

❌ Violación crítica: Goroutine sin canal de cancelación, llamada HTTP sin timeout, recurso temporal no liberado en error
```

### 0.2 Mapeo C1+C2 → Herramientas de Validación

| Herramienta | Propósito | Comando de Validación |
|------------|-----------|---------------------|
| `orchestrator-engine.sh` | Validación integral con scoring de C1/C2 | `bash .../orchestrator-engine.sh --file artifact.md --checks C1,C2 --json` |
| `verify-constraints.sh` | Verificar declaración de C1/C2 en frontmatter | `bash .../verify-constraints.sh --file artifact.md --check-constraint C1 --json` |
| `check-rls.sh` | (Para SQL) Validar timeouts en queries | `bash .../check-rls.sh --file query.sql.md --strict --json` |

> 💡 **Consejo para principiantes**: No memorices todos los patrones. Usa `orchestrator-engine.sh --checks C1,C2` para validar automáticamente límites y concurrencia.

---

## 【1】🔒 REGLAS INAMOVIBLES DE RECURSOS (RG-001 a RG-010)

<!-- 
【EDUCATIVO】Estas 10 reglas son contractuales. 
Cualquier violación es blocking_issue en validación.
-->

### RG-001: Límites de Memoria Explícitos (C1-MEM)

```
【REGLA RG-001】Todo componente debe declarar límite de memoria explícito.

✅ Cumplimiento por stack:

【DOCKER ✅】
services:
  app:
    image: myapp:latest
    deploy:
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M

【GO ✅】
import "runtime/debug"

func init() {
    // Limitar memoria a 512MB
    debug.SetMemoryLimit(512 << 20)
}

// O con contexto para operaciones específicas
func processWithLimit(ctx context.Context, data []byte) error {
    if mem := debug.ReadMemStats(); mem.Alloc > 400<<20 {
        return fmt.Errorf("memory limit exceeded")
    }
    // ... procesamiento
}

【PYTHON ✅】
import resource
import sys

def set_memory_limit(mb: int):
    """Establecer límite de memoria en MB (Linux)"""
    soft, hard = resource.getrlimit(resource.RLIMIT_AS)
    resource.setrlimit(resource.RLIMIT_AS, (mb * 1024 * 1024, hard))

# Uso al inicio del script
if sys.platform == "linux":
    set_memory_limit(512)

【BASH ✅】
#!/bin/bash
# Limitar memoria virtual a 512MB
ulimit -v 524288  # en KB

# Validar antes de operación pesada
check_memory() {
    local used=$(free -m | awk '/^Mem:/{print $3}')
    local limit=400
    if [ "$used" -gt "$limit" ]; then
        echo "ERROR: Memory usage ${used}MB > limit ${limit}MB" >&2
        return 1
    fi
}

❌ Violación crítica:
• Docker sin `mem_limit` o `deploy.resources.limits.memory`
• Go sin `debug.SetMemoryLimit()` en producción
• Python sin validación de memoria en procesamiento de datos grandes
• Bash sin `ulimit` en scripts que procesan archivos
```

### RG-002: Límites de CPU y PIDs (C1-CPU)

```
【REGLA RG-002】Todo componente debe declarar límites de CPU y número de procesos/hilos.

✅ Cumplimiento por stack:

【DOCKER ✅】
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '0.5'  # Medio core
        reservations:
          cpus: '0.25'
    pids_limit: 100  # Máximo 100 procesos hijos

【GO ✅】
// Limitar número de goroutines con semáforo
type semaphore chan struct{}

func newSemaphore(n int) semaphore {
    return make(semaphore, n)
}

func (s semaphore) acquire() { s <- struct{}{} }
func (s semaphore) release() { <-s }

// Uso: limitar a 10 goroutines concurrentes
sem := newSemaphore(10)
for _, task := range tasks {
    sem.acquire()
    go func(t Task) {
        defer sem.release()
        process(t)
    }(task)
}

【PYTHON ✅】
from concurrent.futures import ThreadPoolExecutor

# Limitar a 4 hilos concurrentes
with ThreadPoolExecutor(max_workers=4) as executor:
    results = list(executor.map(process_item, items))

【BASH ✅】
#!/bin/bash
# Limitar número de procesos en paralelo
MAX_PARALLEL=4
running=0

for item in "${items[@]}"; do
    process_item "$item" &
    ((running++))
    if [ $running -ge $MAX_PARALLEL ]; then
        wait -n  # Esperar que termine uno
        ((running--))
    fi
done
wait  # Esperar todos los restantes

❌ Violación crítica:
• Contenedor sin `cpus` limit → puede consumir 100% de CPU del host
• Goroutine pool sin límite → agota memoria o file descriptors
• Bucle que lanza procesos sin control de concurrencia
```

### RG-003: Timeouts de Operación Explícitos (C2-TIMEOUT)

```
【REGLA RG-003】Toda operación de I/O, red o computación pesada debe tener timeout explícito.

✅ Cumplimiento por stack:

【GO ✅】
// Timeout para llamada HTTP
ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
defer cancel()

req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
if err != nil { /* manejar error */ }

resp, err := http.DefaultClient.Do(req)
if err != nil {
    if errors.Is(err, context.DeadlineExceeded) {
        log.Warn("request_timeout", "url", url, "timeout", "30s")
        // Fallback degradado
        return cachedResponse, nil
    }
    return nil, err
}

// Timeout para query de base de datos
ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
defer cancel()

rows, err := db.QueryContext(ctx, "SELECT ... WHERE tenant_id = $1", tenantID)

【PYTHON ✅】
import asyncio
import httpx

async def fetch_with_timeout(url: str, timeout: float = 30.0):
    async with httpx.AsyncClient(timeout=httpx.Timeout(timeout)) as client:
        try:
            response = await client.get(url)
            return response.json()
        except asyncio.TimeoutError:
            logger.warning("request_timeout", url=url, timeout=timeout)
            return get_cached_fallback(url)

# Para operaciones síncronas
from requests import Session
session = Session()
session.timeout = 30  # timeout global
response = session.get(url)

【BASH ✅】
#!/bin/bash
# Timeout para comando externo
timeout 30s curl -sSf "$URL" || {
    echo "ERROR: curl timed out after 30s" >&2
    # Fallback: usar cache local si existe
    [ -f "/tmp/cache/${URL_HASH}.json" ] && cat "/tmp/cache/${URL_HASH}.json" || exit 1
}

# Timeout para lectura de archivo grande
timeout 10s tail -n 1000 /var/log/large.log || echo "Warning: log read timed out"

❌ Violación crítica:
• HTTP request sin timeout → puede bloquear indefinidamente
• Query DB sin context.WithTimeout → agota pool de conexiones
• Script Bash que espera input de usuario o proceso externo sin timeout
```

### RG-004: Cancelación Propagada en Concurrencia (C2-CANCEL)

```
【REGLA RG-004】Todo contexto concurrente debe propagar señal de cancelación a sus hijos.

✅ Cumplimiento por stack:

【GO ✅】
func processBatch(ctx context.Context, items []Item) error {
    // Crear contexto derivado con timeout
    ctx, cancel := context.WithTimeout(ctx, 60*time.Second)
    defer cancel()  // Liberar recursos al finalizar
    
    // Propagar cancelación a goroutines hijas
    for _, item := range items {
        select {
        case <-ctx.Done():
            return ctx.Err()  // Propagar cancelación
        default:
            go processItem(ctx, item)  // Pasar ctx a hija
        }
    }
    return nil
}

【PYTHON ✅】
import asyncio
from contextlib import asynccontextmanager

@asynccontextmanager
async def cancellable_task(timeout: float):
    task = asyncio.current_task()
    try:
        await asyncio.wait_for(some_operation(), timeout=timeout)
        yield
    except asyncio.CancelledError:
        # Cleanup antes de propagar
        await cleanup_resources()
        raise  # Propagar cancelación

# Uso con propagación
async def parent_task():
    async with cancellable_task(timeout=30):
        await child_task()  # child_task recibe contexto de cancelación

【BASH ✅】
#!/bin/bash
# Propagar señal SIGTERM a procesos hijos
trap 'kill 0; exit 130' SIGTERM SIGINT

# Ejecutar comando con propagación de cancelación
run_with_cancellation() {
    local cmd="$1"
    $cmd &
    local pid=$!
    
    # Esperar con posibilidad de cancelación externa
    while kill -0 $pid 2>/dev/null; do
        sleep 1
        # Verificar si se recibió señal de cancelación
        if [ -f "/tmp/cancel_${pid}.flag" ]; then
            kill -TERM $pid
            rm -f "/tmp/cancel_${pid}.flag"
            return 130
        fi
    done
    wait $pid
}

❌ Violación crítica:
• Goroutine que ignora `ctx.Done()` → fuga de recursos al cancelar padre
• Tarea asyncio sin manejar `CancelledError` → cleanup no ejecutado
• Script Bash que no propaga SIGTERM a hijos → procesos zombis
```

### RG-005: Cleanup Garantizado en Fallo (C2-CLEANUP)

```
【REGLA RG-005】Todo recurso adquirido debe liberarse explícitamente, incluso en caso de fallo.

✅ Cumplimiento por stack:

【GO ✅】
func processFile(path string) error {
    f, err := os.Open(path)
    if err != nil {
        return err
    }
    defer f.Close()  // Garantizar cierre incluso si hay panic
    
    // Procesar...
    data, err := io.ReadAll(f)
    if err != nil {
        return err  // defer f.Close() se ejecutará igual
    }
    return nil
}

// Para recursos más complejos
func withTempFile(fn func(*os.File) error) error {
    tmp, err := os.CreateTemp("", "process-*")
    if err != nil {
        return err
    }
    defer os.Remove(tmp.Name())  // Limpiar archivo temporal
    defer tmp.Close()
    
    return fn(tmp)  // Si fn falla, cleanup igual se ejecuta
}

【PYTHON ✅】
from contextlib import contextmanager
import tempfile
import os

@contextmanager
def managed_temp_file():
    tmp = tempfile.NamedTemporaryFile(delete=False)
    try:
        yield tmp
    finally:
        tmp.close()
        try:
            os.unlink(tmp.name)  # Limpiar siempre
        except OSError:
            pass  # Ignorar si ya fue borrado

# Uso
with managed_temp_file() as tmp:
    tmp.write(b"data")
    process(tmp.name)
# Archivo temporal borrado automáticamente

【BASH ✅】
#!/bin/bash
set -euo pipefail  # Fallar rápido, no ignorar errores

# Cleanup con trap
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT INT TERM

# Procesar con garantía de cleanup
process_data() {
    echo "data" > "$TMPFILE"
    # Si hay error aquí, trap aún ejecutará rm -f
    transform "$TMPFILE"
}

# Para recursos más complejos
with_lock() {
    local lockfile="$1"
    exec 200>"$lockfile"
    flock -n 200 || { echo "Lock failed" >&2; return 1; }
    # Cleanup automático al salir de la función/subshell
    trap 'flock -u 200; rm -f "$lockfile"' EXIT
    "$@"
}

❌ Violación crítica:
• Abrir archivo/DB/socket sin `defer`/`finally`/`trap` → fuga de recursos
• Crear archivo temporal sin plan de limpieza → disco lleno
• Adquirir lock sin mecanismo de liberación garantizada → deadlock
```

### RG-006: Degradación Elegante al Alcanzar Límites (C1+C2+ C7)

```
【REGLA RG-006】Al alcanzar un límite de recurso, degradar funcionalidad, no crashear.

✅ Patrón de fallback canónico:

【GO ✅】
func fetchWithFallback(ctx context.Context, url string) (Response, error) {
    // Intentar fetch primario con timeout
    ctx, cancel := context.WithTimeout(ctx, 30*time.Second)
    defer cancel()
    
    resp, err := httpGet(ctx, url)
    if err != nil {
        if errors.Is(err, context.DeadlineExceeded) {
            log.Warn("fetch_timeout", "url", url)
            // Fallback: cache local o respuesta parcial
            if cached, ok := getFromCache(url); ok {
                return cached, nil
            }
            return Response{Partial: true}, nil  // Degradación elegante
        }
        return Response{}, err  // Error no recuperable
    }
    return resp, nil
}

【PYTHON ✅】
async def process_with_degradation(items: list, max_concurrent: int = 10):
    semaphore = asyncio.Semaphore(max_concurrent)
    
    async def bounded_process(item):
        async with semaphore:
            try:
                return await process_item(item)
            except asyncio.TimeoutError:
                logger.warning("item_timeout", item_id=item.id)
                return ProcessedItem(item, status="degraded")  # Degradación
            except MemoryError:
                logger.error("memory_exhausted")
                # Fallback: procesar en lotes más pequeños
                return await process_in_batches([item], batch_size=1)
    
    results = await asyncio.gather(
        *(bounded_process(item) for item in items),
        return_exceptions=True
    )
    return [r for r in results if not isinstance(r, Exception)]

【BASH ✅】
#!/bin/bash
# Degradación al alcanzar límite de memoria
process_large_file() {
    local file="$1"
    local mem_limit_mb=400
    
    # Verificar memoria disponible
    local mem_used=$(free -m | awk '/^Mem:/{print $3}')
    if [ "$mem_used" -gt "$mem_limit_mb" ]; then
        echo "WARN: Memory high (${mem_used}MB), using degraded mode" >&2
        # Modo degradado: procesar en chunks más pequeños
        process_in_chunks "$file" --chunk-size 1000
        return $?
    fi
    
    # Modo normal
    process_full "$file"
}

❌ Violación crítica:
• Crashear con panic/exit 1 al alcanzar límite de memoria
• No ofrecer fallback cuando timeout de API externa
• Propagar error de recurso sin intentar degradación primero
```

### RG-007: Auditoría de Uso de Recursos por Tenant (C1+C2+ C8)

```
【REGLA RG-007】El consumo de recursos debe ser auditable por tenant_id para billing y debugging.

✅ Log de auditoría canónico:
```json
{
  "timestamp": "2026-04-19T12:00:00Z",
  "level": "INFO",
  "tenant_id": "cliente_001",
  "event": "resource_usage",
  "resource": {
    "type": "memory|cpu|time|requests",
    "value": 256,
    "unit": "MB|core-seconds|ms|count",
    "limit": 512,
    "percent_used": 50
  },
  "operation": "query_execution|file_processing|api_call",
  "trace_id": "otel-trace-xyz",
  "result": "success|degraded|limit_reached"
}
```

✅ Integración con OpenTelemetry para métricas:
```go
import (
    "go.opentelemetry.io/otel/metric"
)

var resourceUsage metric.Int64Histogram

func init() {
    resourceUsage = meter.Int64Histogram("resource.usage",
        metric.WithDescription("Resource consumption by tenant"),
        metric.WithUnit("{resource_unit}"),
    )
}

func recordUsage(ctx context.Context, tenantID, resourceType string, value int64, limit int64) {
    percent := float64(value) / float64(limit) * 100
    
    resourceUsage.Record(ctx, value,
        metric.WithAttributes(
            attribute.String("tenant_id", tenantID),
            attribute.String("resource_type", resourceType),
            attribute.Float64("percent_used", percent),
        ),
    )
    
    // Alerta si >90% del límite
    if percent > 90 {
        slog.WarnContext(ctx, "resource_limit_warning",
            "tenant_id", tenantID,
            "resource", resourceType,
            "percent", percent,
        )
    }
}
```

✅ Dashboard recomendado:
• Gráfico de uso de memoria/CPU por tenant/hora
• Alerta si tenant excede 90% de límite asignado
• Reporte de degradaciones por límite alcanzado

❌ Violación crítica:
• No loguear uso de recursos por tenant → imposible hacer billing o debugging
• Log que expone valores sensibles junto con métricas de recursos
• Métricas sin `trace_id` → imposible correlacionar con trazas distribuidas
```

### RG-008: Límites Configurables por Tenant (C1 + C4)

```
【REGLA RG-008】Los límites de recursos deben ser configurables por tenant, no hardcodeados globalmente.

✅ Patrón de configuración por tenant:

【GO ✅】
type TenantConfig struct {
    TenantID      string
    MemoryLimitMB int64 `validate:"min=64,max=4096"`
    CPUCoreLimit  float64 `validate:"min=0.1,max=8.0"`
    TimeoutSeconds int `validate:"min=5,max=300"`
    MaxConcurrent int `validate:"min=1,max=100"`
}

func getTenantConfig(tenantID string) (*TenantConfig, error) {
    // Cargar desde DB, cache o secret manager
    config, err := configStore.Get(tenantID)
    if err != nil {
        // Fallback a defaults seguros
        return &TenantConfig{
            TenantID: tenantID,
            MemoryLimitMB: 256,
            CPUCoreLimit: 0.5,
            TimeoutSeconds: 30,
            MaxConcurrent: 10,
        }, nil
    }
    return config, nil
}

// Aplicar límites en runtime
func applyLimits(ctx context.Context, cfg *TenantConfig) context.Context {
    // Aplicar límite de memoria
    debug.SetMemoryLimit(cfg.MemoryLimitMB << 20)
    
    // Crear contexto con timeout configurable
    ctx, cancel := context.WithTimeout(ctx, time.Duration(cfg.TimeoutSeconds)*time.Second)
    
    // Retornar contexto enriquecido con config para propagación
    return context.WithValue(ctx, "tenant_config", cfg)
}

【PYTHON ✅】
from pydantic import BaseModel, Field

class TenantResourceConfig(BaseModel):
    tenant_id: str
    memory_limit_mb: int = Field(ge=64, le=4096, default=256)
    cpu_limit: float = Field(ge=0.1, le=8.0, default=0.5)
    timeout_seconds: int = Field(ge=5, le=300, default=30)
    max_concurrent: int = Field(ge=1, le=100, default=10)

async def get_tenant_config(tenant_id: str) -> TenantResourceConfig:
    # Cargar desde DB/cache
    config = await config_db.get(tenant_id)
    if not config:
        # Defaults seguros
        return TenantResourceConfig(tenant_id=tenant_id)
    return TenantResourceConfig(**config)

【BASH ✅】
#!/bin/bash
# Cargar límites por tenant desde archivo de config
load_tenant_limits() {
    local tenant_id="$1"
    local config_file="/etc/mantis/tenants/${tenant_id}.conf"
    
    # Defaults seguros
    MEMORY_LIMIT_MB=256
    CPU_LIMIT=0.5
    TIMEOUT_SECONDS=30
    MAX_CONCURRENT=10
    
    # Sobrescribir si existe config específico
    if [ -f "$config_file" ]; then
        source "$config_file"  # Archivo con: MEMORY_LIMIT_MB=512, etc.
    fi
    
    # Aplicar límites
    ulimit -v $((MEMORY_LIMIT_MB * 1024))  # en KB
    export DEFAULT_TIMEOUT=$TIMEOUT_SECONDS
}

❌ Violación crítica:
• Hardcodear `mem_limit: 512M` para todos los tenants → no permite planes premium
• Timeout fijo de 30s para todas las operaciones → no adaptable a cargas variables
• No validar rangos de configuración → tenant puede asignarse recursos ilimitados
```

### RG-009: Testing de Límites y Concurrencia (C1+C2+ C6)

```
【REGLA RG-009】Todo componente debe incluir tests que verifiquen comportamiento al alcanzar límites.

✅ Patrón de test canónico:

【GO ✅】
func TestMemoryLimitEnforcement(t *testing.T) {
    // Configurar límite bajo para test
    original := debug.SetMemoryLimit(10 << 20)  // 10MB para test
    defer debug.SetMemoryLimit(original)
    
    // Intentar asignar más memoria del límite
    data := make([]byte, 20<<20)  // 20MB > límite
    if len(data) > 0 {
        // En producción, esto debería fallar o degradar
        // En test, verificamos que el manejo de error es correcto
        t.Log("Memory allocation attempted beyond limit")
    }
}

func TestTimeoutPropagation(t *testing.T) {
    ctx, cancel := context.WithTimeout(context.Background(), 100*time.Millisecond)
    defer cancel()
    
    done := make(chan bool)
    go func() {
        // Operación que debería ser cancelada
        select {
        case <-ctx.Done():
            done <- true
        case <-time.After(1 * time.Second):
            done <- false  // Timeout no propagado → falla test
        }
    }()
    
    if !<-done {
        t.Error("Timeout not propagated to goroutine")
    }
}

【PYTHON ✅】
import pytest
from unittest.mock import patch, MagicMock

@pytest.mark.parametrize("memory_limit_mb", [64, 128, 256])
def test_memory_limit_enforcement(memory_limit_mb):
    with patch('resource.setrlimit') as mock_setrlimit:
        set_memory_limit(memory_limit_mb)
        # Verificar que se llamó con el límite correcto
        mock_setrlimit.assert_called_once_with(
            resource.RLIMIT_AS,
            (memory_limit_mb * 1024 * 1024, mock.ANY)
        )

@pytest.mark.asyncio
async def test_timeout_degradation():
    with patch('httpx.AsyncClient.get') as mock_get:
        mock_get.side_effect = asyncio.TimeoutError()
        
        result = await fetch_with_timeout("https://api.example.com/data")
        
        # Verificar que se usó fallback degradado
        assert result.status == "degraded"
        assert result.partial_data is not None

【BASH ✅】
#!/bin/bash
# Test de timeout enforcement
test_timeout_enforcement() {
    local start=$(date +%s)
    
    # Comando que debería timeoutear
    timeout 2s sleep 10 || true
    
    local end=$(date +%s)
    local duration=$((end - start))
    
    # Verificar que duró ~2s, no 10s
    if [ $duration -gt 3 ]; then
        echo "FAIL: timeout not enforced (took ${duration}s)" >&2
        return 1
    fi
    echo "PASS: timeout enforced within ${duration}s"
    return 0
}

# Ejecutar tests de recursos en CI
run_resource_tests() {
    echo "Running resource limit tests..."
    test_memory_limit_enforcement
    test_timeout_enforcement
    test_concurrency_limit
    # ... más tests
}

❌ Violación crítica:
• No tener tests para límites de memoria/CPU → imposible detectar regresiones
• Tests que no verifican propagación de cancelación → falsos positivos
• Tests de timeout sin aserción de duración → no detectan timeouts ignorados
```

### RG-010: Documentación de Límites en Frontmatter (C5 + C6)

```
【REGLA RG-010】Todo artefacto que declare C1/C2 debe documentar sus límites explícitamente en frontmatter.

✅ Frontmatter canónico con límites:
```yaml
---
canonical_path: "/06-PROGRAMMING/go/webhook-handler.go.md"
constraints_mapped: ["C1", "C2", "C4", "C5", "C8"]
tier: 2

# Límites de recursos documentados (C1)
resource_limits:
  memory_mb: 512
  cpu_cores: 0.5
  max_pids: 100
  max_file_size_mb: 100

# Concurrencia y timeouts (C2)
concurrency:
  max_goroutines: 20
  http_timeout_seconds: 30
  db_query_timeout_seconds: 10
  graceful_shutdown_seconds: 15

# Degradación y fallback
degradation:
  on_memory_limit: "return_cached_response"
  on_timeout: "partial_response_with_warning"
  on_concurrency_limit: "queue_with_backpressure"

# Validación
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/go/webhook-handler.go.md --checks C1,C2 --json"
---
```

✅ Verificación automática:
```bash
# Validar que artifact declara límites si tiene C1/C2
validate_resource_declaration() {
    local file="$1"
    local has_c1=$(yq eval '.constraints_mapped | contains(["C1"])' "$file")
    local has_c2=$(yq eval '.constraints_mapped | contains(["C2"])' "$file")
    
    if [ "$has_c1" = "true" ] || [ "$has_c2" = "true" ]; then
        # Verificar que resource_limits está presente
        if ! yq eval '.resource_limits' "$file" | grep -q .; then
            echo "ERROR: Artifact with C1/C2 must declare resource_limits in frontmatter"
            return 1
        fi
    fi
    return 0
}
```

❌ Violación crítica:
• Declarar `constraints_mapped: ["C1"]` sin `resource_limits` en frontmatter
• Límites documentados que no coinciden con implementación real
• No actualizar frontmatter al cambiar límites en código
```

---

## 【2】🛡️ VALIDACIÓN AUTOMÁTICA DE C1+C2 (Toolchain Integration)

<!-- 
【EDUCATIVO】Estas herramientas permiten validar automáticamente el cumplimiento de C1 y C2.
-->

### 2.1 orchestrator-engine.sh – Validación Integral de Recursos

```bash
# 📍 Ubicación
05-CONFIGURATIONS/validation/orchestrator-engine.sh

# 🎯 Propósito
Validar que artefactos declaran y cumplen límites de recursos (C1) y concurrencia/timeouts (C2).

# 📦 Flags Principales
--file <ruta>              # Artefacto a validar
--checks C1,C2             # Validar específicamente C1 y/o C2
--mode <headless|interactive>  # headless para CI/CD
--json                     # Salida en formato JSON

# ✅ Ejemplo: Validar artifact con C1+C2
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/go/webhook-handler.go.md \
  --checks C1,C2 \
  --mode headless \
  --json

# 📤 Salida Esperada (JSON)
{
  "file": "06-PROGRAMMING/go/webhook-handler.go.md",
  "constraints_checked": ["C1", "C2"],
  "c1_validation": {
    "memory_limit_declared": true,
    "cpu_limit_declared": true,
    "limits_reasonable": true,
    "passed": true
  },
  "c2_validation": {
    "timeouts_declared": true,
    "cancellation_propagated": true,
    "cleanup_guaranteed": true,
    "passed": true
  },
  "score": 38,
  "passed": true,
  "blocking_issues": [],
  "recommendations": [
    "Consider adding graceful_shutdown_seconds for cleaner termination"
  ]
}
```

### 2.2 verify-constraints.sh – Validación de Declaración de C1/C2

```bash
# 📍 Ubicación
05-CONFIGURATIONS/validation/verify-constraints.sh

# 🎯 Propósito
Verificar que artifacts declaran C1/C2 en constraints_mapped cuando aplican.

# ✅ Ejemplo: Validar declaración de C1
bash 05-CONFIGURATIONS/validation/verify-constraints.sh \
  --file 06-PROGRAMMING/python/data-processor.md \
  --check-constraint C1 \
  --json

# 📤 Salida Esperada (JSON)
{
  "file": "06-PROGRAMMING/python/data-processor.md",
  "constraint_checked": "C1",
  "declared_in_frontmatter": true,
  "resource_limits_present": true,
  "limits_reasonable": true,
  "passed": true
}
```

---

## 【3】🧭 PROTOCOLO DE IMPLEMENTACIÓN DE C1+C2 (PASO A PASO)

```
┌─────────────────────────────────────────────────────────┐
│ 【FASE 0】IDENTIFICAR RECURSOS CRÍTICOS                │
├─────────────────────────────────────────────────────────┤
│ 1. Listar operaciones que consumen memoria/CPU/red    │
│ 2. Definir límites por tenant o global según caso     │
│ 3. Documentar en frontmatter: resource_limits, concurrency │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 1】IMPLEMENTAR LÍMITES EXPLÍCITOS (C1)          │
├─────────────────────────────────────────────────────────┤
│ 1. Añadir mem_limit/CPU en Docker o debug.SetMemoryLimit │
│ 2. Validar límites en runtime antes de operaciones pesadas │
│ 3. Loguear uso de recursos por tenant (C8)             │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 2】IMPLEMENTAR CONCURRENCIA Y TIMEOUTS (C2)     │
├─────────────────────────────────────────────────────────┤
│ 1. Añadir context.WithTimeout para operaciones de I/O  │
│ 2. Limitar goroutines/hilos con semáforos o pools      │
│ 3. Propagar cancelación con defer/finally/trap         │
│ 4. Garantizar cleanup con defer/try-finally/trap EXIT  │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 3】IMPLEMENTAR DEGRADACIÓN ELEGANTE (C7)        │
├─────────────────────────────────────────────────────────┤
│ 1. Definir fallbacks para cada tipo de límite          │
│ 2. Retornar respuestas parciales o cacheadas al fallar │
│ 3. Loguear degradaciones con level: WARN + tenant_id   │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 4】VALIDACIÓN AUTOMÁTICA Y TESTS                │
├─────────────────────────────────────────────────────────┤
│ 1. Ejecutar orchestrator-engine.sh --checks C1,C2      │
│ 2. Añadir tests de límite de memoria y timeout         │
│ 3. Verificar que tests fallan si se omiten límites     │
└─────────────────────────────────────────────────────────┘
```

### 3.1 Ejemplo de Traza de Implementación de C1+C2

```
【TRAZA DE IMPLEMENTACIÓN C1+C2】
Tarea: "Handler de webhooks con límites de recursos para multi-tenant"

Fase 0 - Identificación:
  • Recursos críticos: memoria para parsear payload, CPU para validación HMAC, red para callbacks
  • Límites definidos: 512MB RAM, 0.5 CPU, 30s timeout HTTP, 20 concurrent requests por tenant
  • Documentar en frontmatter: resource_limits, concurrency ✅

Fase 1 - Límites explícitos (C1):
  • Añadir deploy.resources.limits en Docker Compose ✅
  • Validar tamaño de payload antes de procesar: if len(payload) > 10MB { return error } ✅
  • Loguear uso de memoria por tenant con OpenTelemetry ✅

Fase 2 - Concurrencia y timeouts (C2):
  • context.WithTimeout(ctx, 30*time.Second) para llamadas HTTP ✅
  • Semaphore para limitar a 20 goroutines por tenant ✅
  • defer cancel() y defer cleanup() para propagar cancelación ✅
  • trap 'cleanup' EXIT en scripts Bash auxiliares ✅

Fase 3 - Degradación elegante (C7):
  • Si timeout HTTP → retornar cached response + warning log ✅
  • Si memoria >90% → procesar en chunks más pequeños ✅
  • Si concurrencia máxima → queue con backpressure + retry-after header ✅

Fase 4 - Validación automática:
  • orchestrator-engine.sh --checks C1,C2 → score=41, passed=true ✅
  • Tests: TestMemoryLimitEnforcement, TestTimeoutPropagation ✅
  • CI/CD: fallar build si tests de recursos no pasan ✅

Resultado: ✅ Handler de webhooks con límites de recursos certificados C1+C2.
```

---

## 【4】📚 GLOSARIO PARA PRINCIPIANTES

<!-- 
【EDUCATIVO】Términos técnicos explicados en lenguaje simple.
-->

| Término | Significado simple | Ejemplo |
|---------|-------------------|---------|
| **C1 (Resource Limits)** | Regla que exige declarar límites de memoria, CPU, etc. | `mem_limit: 512M` en Docker, `debug.SetMemoryLimit(512<<20)` en Go |
| **C2 (Concurrency Control)** | Regla que exige gestionar timeouts y cancelación en operaciones concurrentes | `context.WithTimeout(ctx, 30*time.Second)` |
| **Graceful Degradation** | Reducir funcionalidad al alcanzar límites, no crashear | Retornar respuesta cacheada si API externa timeout |
| **Backpressure** | Mecanismo para frenar entrada de trabajo cuando el sistema está saturado | Queue con límite, rechazar con `Retry-After: 60` |
| **Cleanup Guaranteed** | Liberar recursos (archivos, conexiones) incluso si hay error | `defer f.Close()` en Go, `try/finally` en Python |
| **Resource Audit** | Registrar uso de memoria/CPU por tenant para billing y debugging | Log JSON con `tenant_id`, `resource_type`, `value`, `limit` |
| **Configurable Limits** | Límites que pueden ajustarse por tenant, no hardcodeados | `TenantConfig{MemoryLimitMB: 512}` cargado desde DB |
| **Propagation of Cancellation** | Señal de "detener" que viaja de tarea padre a hijas | `ctx.Done()` en Go, `asyncio.CancelledError` en Python |

---

## 【5】🧪 SANDBOX DE PRUEBA (OPCIONAL)

<!-- 
【PARA DESARROLLADORES】Pega esta sección en un chat nuevo para validar que la IA sigue el protocolo sin contexto previo.
-->

```
【TEST MODE: RESOURCE-GUARDRAILS VALIDATION】
Prompt de prueba: "Generar worker de procesamiento de datos con límites de recursos para multi-tenant"

Respuesta esperada de la IA:
1. Identificar recursos críticos: memoria para cargar datos, CPU para transformación, tiempo de ejecución
2. Declarar en frontmatter: constraints_mapped: ["C1","C2"], resource_limits: {memory_mb: 512, ...}, concurrency: {...}
3. Implementar C1:
   • debug.SetMemoryLimit(512<<20) o equivalente en lenguaje
   • Validar tamaño de input antes de procesar
4. Implementar C2:
   • context.WithTimeout para operaciones de I/O
   • Semaphore para limitar concurrencia por tenant
   • defer/finally para cleanup garantizado
5. Implementar degradación:
   • Fallback a procesamiento en chunks si memoria alta
   • Retornar resultado parcial si timeout
6. Validar con orchestrator-engine.sh --checks C1,C2 → score >= 30
7. Incluir tests: TestMemoryLimitEnforcement, TestTimeoutPropagation

Si la IA omite límites de memoria, no propaga cancelación, o entrega sin validation_command → FALLA DE RECURSOS C1/C2.
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
- `[[01-RULES/harness-norms-v3.0.md]]` → Definición textual de C1-C2
- `[[06-PROGRAMMING/go/resource-limits-c1-c2.go.md]]` → Patrones de límites en Go
- `[[06-PROGRAMMING/python/async-patterns-with-timeouts.md]]` → Patrones de timeouts en Python
- `[[TOOLCHAIN-REFERENCE]]` → Catálogo de herramientas de validación

---

## 【7】📦 METADATOS DE EXPANSIÓN (PARA FUTURAS VERSIONES)

<!-- 
【PARA MANTENEDORES】Nuevas secciones deben seguir este formato para no romper compatibilidad.
-->

```json
{
  "expansion_registry": {
    "new_resource_type": {
      "requires_files_update": [
        "01-RULES/02-RESOURCE-GUARDRAILS.md: add section for new resource (ej: GPU, network bandwidth)",
        "05-CONFIGURATIONS/validation/orchestrator-engine.sh: add check for new resource type",
        "06-PROGRAMMING/: add language-specific patterns for new resource",
        "Human approval required: true"
      ],
      "backward_compatibility": "new resource types must not break existing C1/C2 validation for memory/CPU"
    },
    "new_degradation_strategy": {
      "requires_files_update": [
        "01-RULES/02-RESOURCE-GUARDRAILS.md: document new fallback pattern in RG-006",
        "05-CONFIGURATIONS/templates/: add example template for new strategy",
        "Test suite: add regression test for new degradation path",
        "Human approval required: true"
      ],
      "backward_compatibility": "new strategies must not invalidate existing fallback implementations"
    }
  },
  "compatibility_rule": "Nuevas reglas de recursos no deben invalidar artefactos generados bajo versiones anteriores. Cambios breaking requieren major version bump, guía de migración y aprobación humana explícita."
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
Prioridad de ejecución: Las reglas se aplican en orden RG-001 → RG-010.
Dependencias: Cada nodo declara sus archivos requeridos y sus efectos colaterales.
═══════════════════════════════════════════════════════════
-->

```json
{
  "resource_guardrails_metadata": {
    "version": "3.0.0-SELECTIVE",
    "canonical_path": "/01-RULES/02-RESOURCE-GUARDRAILS.md",
    "artifact_type": "governance_rule_set",
    "immutable": true,
    "requires_human_approval_for_changes": true,
    "constraints_primary": ["C1", "C2"],
    "llm_optimizations": {
      "oriental_models_friendly": true,
      "delimiters_used": ["【】", "┌─┐", "▼", "✅/❌/🔧"],
      "numbered_sequences": true,
      "stop_conditions_explicit": true
    }
  },
  
  "rules_catalog": {
    "RG-001": {"title": "Límites de Memoria Explícitos", "constraint": "C1", "priority": "critical", "blocking_if_violated": true, "validation_tool": "orchestrator-engine.sh --checks C1"},
    "RG-002": {"title": "Límites de CPU y PIDs", "constraint": "C1", "priority": "critical", "blocking_if_violated": true, "validation_tool": "orchestrator-engine.sh --checks C1"},
    "RG-003": {"title": "Timeouts de Operación Explícitos", "constraint": "C2", "priority": "critical", "blocking_if_violated": true, "validation_tool": "orchestrator-engine.sh --checks C2"},
    "RG-004": {"title": "Cancelación Propagada en Concurrencia", "constraint": "C2", "priority": "critical", "blocking_if_violated": true, "validation_tool": "orchestrator-engine.sh --checks C2"},
    "RG-005": {"title": "Cleanup Garantizado en Fallo", "constraint": "C2", "priority": "high", "blocking_if_violated": false, "validation_tool": "manual review + test coverage"},
    "RG-006": {"title": "Degradación Elegante al Alcanzar Límites", "constraint": "C1+C2+C7", "priority": "high", "blocking_if_violated": false, "validation_tool": "degradation test suite"},
    "RG-007": {"title": "Auditoría de Uso de Recursos por Tenant", "constraint": "C1+C2+C8", "priority": "high", "blocking_if_violated": false, "validation_tool": "structured log validation"},
    "RG-008": {"title": "Límites Configurables por Tenant", "constraint": "C1+C4", "priority": "medium", "blocking_if_violated": false, "validation_tool": "config schema validation"},
    "RG-009": {"title": "Testing de Límites y Concurrencia", "constraint": "C1+C2+C6", "priority": "high", "blocking_if_violated": false, "validation_tool": "test coverage check"},
    "RG-010": {"title": "Documentación de Límites en Frontmatter", "constraint": "C5+C6", "priority": "high", "blocking_if_violated": true, "validation_tool": "validate-frontmatter.sh + resource_limits check"}
  },
  
  "validation_integration": {
    "orchestrator-engine.sh": {
      "purpose": "Validación integral de C1 (límites) y C2 (concurrencia/timeouts)",
      "flags": ["--file", "--checks", "--mode", "--json"],
      "exit_codes": {"0": "passed", "1": "failed"},
      "output_format": "JSON con c1_validation, c2_validation, score, blocking_issues"
    },
    "verify-constraints.sh": {
      "purpose": "Validar declaración de C1/C2 en frontmatter",
      "flags": ["--file", "--check-constraint", "--json"],
      "exit_codes": {"0": "passed", "1": "failed"},
      "output_format": "JSON con constraint_checked, declared_in_frontmatter, resource_limits_present"
    }
  },
  
  "dependency_graph": {
    "critical_infrastructure": [
      {"file": "05-CONFIGURATIONS/validation/norms-matrix.json", "purpose": "Mapear C1/C2 como constraints validables", "load_order": 1},
      {"file": "01-RULES/harness-norms-v3.0.md", "purpose": "Definición textual canónica de C1/C2", "load_order": 2},
      {"file": "GOVERNANCE-ORCHESTRATOR.md", "purpose": "Tiers y scoring para validación de recursos", "load_order": 3}
    ],
    "implementation_patterns": [
      {"file": "06-PROGRAMMING/go/resource-limits-c1-c2.go.md", "purpose": "Patrones de límites en Go", "load_order": 1},
      {"file": "06-PROGRAMMING/python/async-patterns-with-timeouts.md", "purpose": "Patrones de timeouts en Python", "load_order": 2},
      {"file": "06-PROGRAMMING/bash/robust-error-handling.md", "purpose": "Cleanup y error handling en Bash", "load_order": 3}
    ]
  },
  
  "human_readable_errors": {
    "memory_limit_missing": "Artefacto con C1 no declara memory_limit en frontmatter. Añadir resource_limits.memory_mb.",
    "timeout_not_declared": "Operación de I/O en '{file}' sin timeout explícito. Añadir context.WithTimeout o equivalente.",
    "cancellation_not_propagated": "Goroutine/hilo en '{file}' no maneja ctx.Done() o CancelledError. Propagar cancelación.",
    "cleanup_missing": "Recurso adquirido en '{file}' sin defer/finally/trap para cleanup garantizado.",
    "no_degradation_fallback": "Componente en '{file}' crashea al alcanzar límite. Implementar fallback degradado.",
    "resource_audit_missing": "Log de uso de recursos en '{file}' no incluye tenant_id o trace_id. Añadir para auditoría.",
    "hardcoded_limits": "Límites hardcodeados en '{file}' sin configuración por tenant. Usar TenantConfig.",
    "tests_missing_for_limits": "No hay tests de límite de memoria/timeout en '{file}'. Añadir TestMemoryLimitEnforcement.",
    "frontmatter_resource_limits_missing": "Frontmatter en '{file}' declara C1/C2 pero omite resource_limits o concurrency. Completar campos."
  },
  
  "expansion_hooks": {
    "new_resource_type": {
      "requires_files_update": [
        "01-RULES/02-RESOURCE-GUARDRAILS.md: add section for new resource (ej: GPU, network)",
        "05-CONFIGURATIONS/validation/orchestrator-engine.sh: add check for new resource",
        "06-PROGRAMMING/: add language-specific patterns",
        "Human approval required: true"
      ],
      "backward_compatibility": "new resource types must not break existing memory/CPU validation"
    },
    "new_degradation_strategy": {
      "requires_files_update": [
        "01-RULES/02-RESOURCE-GUARDRAILS.md: document new fallback in RG-006",
        "05-CONFIGURATIONS/templates/: add example for new strategy",
        "Test suite: add regression test",
        "Human approval required: true"
      ],
      "backward_compatibility": "new strategies must not invalidate existing fallback implementations"
    }
  },
  
  "validation_metadata": {
    "orchestrator_compatibility": ">=3.0.0-SELECTIVE",
    "schema_version": "resource-guardrails.v1.json",
    "checksum_algorithm": "SHA256",
    "audit_log_format": "JSON Lines with RFC3339 timestamps",
    "pii_scrubbing": "enabled for all logs (C3 + C8 compliance)",
    "reproducibility_guarantee": "Any resource limit validation can be reproduced identically using this rule set + orchestrator-engine.sh"
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
yq eval '.canonical_path' 01-RULES/02-RESOURCE-GUARDRAILS.md | grep -q "/01-RULES/02-RESOURCE-GUARDRAILS.md" && echo "✅ Ruta canónica correcta"

# 2. Constraints mapeadas (C1+C2)
yq eval '.constraints_mapped | contains(["C1"]) and contains(["C2"])' 01-RULES/02-RESOURCE-GUARDRAILS.md && echo "✅ C1 y C2 declaradas"

# 3. Reglas presentes
grep -c "RG-0[0-9][0-9]:" 01-RULES/02-RESOURCE-GUARDRAILS.md | awk '{if($1==10) print "✅ 10 reglas de recursos"; else print "⚠️ Faltan reglas"}'

# 4. Ejemplos por lenguaje presentes
grep -q "【GO ✅】\|【PYTHON ✅】\|【BASH ✅】" 01-RULES/02-RESOURCE-GUARDRAILS.md && echo "✅ Ejemplos multi-lenguaje presentes"

# 5. JSON válido
tail -n +$(grep -n '```json' 01-RULES/02-RESOURCE-GUARDRAILS.md | tail -1 | cut -d: -f1) 01-RULES/02-RESOURCE-GUARDRAILS.md | sed -n '/```json/,/```/p' | sed '1d;$d' | jq empty && echo "✅ JSON parseable"

# 6. Wikilinks canónicos
for link in $(grep -oE '\[\[[^]]+\]\]' 01-RULES/02-RESOURCE-GUARDRAILS.md | tr -d '[]' | sort -u); do
  [ -f "${link#//}" ] || echo "⚠️ Wikilink roto: $link"
done
```
````

**Criterio de aceptación:**  
- ✅ Frontmatter válido con `canonical_path: "/01-RULES/02-RESOURCE-GUARDRAILS.md"`  
- ✅ `constraints_mapped` incluye C1 y C2 (fail-fast)  
- ✅ 10 reglas RG-001 a RG-010 documentadas con ejemplos ✅/❌/🔧  
- ✅ Integración con `orchestrator-engine.sh --checks C1,C2` para validación automática  
- ✅ Sección JSON final es válida (puede parsearse con `jq .`)  
- ✅ Todos los wikilinks apuntan a archivos existentes en `PROJECT_TREE.md`  

---

> 🎯 **Mensaje final para el lector humano**:  
> Este contrato es tu garantía de estabilidad. No es opcional.  
> **Límites → Timeouts → Cancelación → Cleanup → Degradación → Auditoría**.  
> Si sigues ese flujo, nunca agotarás recursos ni bloquearás el sistema.  
> La gobernanza no es una carga. Es la libertad de escalar sin miedo a romper.  
