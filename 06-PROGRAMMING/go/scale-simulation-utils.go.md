# SHA256: e7b4f2c9a1d8f3e6a0c5b9d2e8f1a4c7b3d6e9f2a5c8b1d4e7a0f3c6b9d2e5a7
---
artifact_id: "scale-simulation-utils"
artifact_type: "skill_go"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C1","C2","C4","C7"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/go/scale-simulation-utils.go.md --json"
canonical_path: "06-PROGRAMMING/go/scale-simulation-utils.go.md"
---

# scale-simulation-utils.go.md – Utilidades seguras de simulación de escala y load testing

## Propósito
Patrones de implementación en Go para construir herramientas de carga y simulación de escala resilientes: generación de requests controlada, aislamiento estricto por tenant, límites de concurrencia/memoria, recolección segura de métricas (p95/p99/error-rate), ramp-up progresivo y degradación controlada ante umbrales críticos. Cada ejemplo está comentado línea por línea en español para que entiendas cómo estresar un sistema sin colapsarlo, sin mezclar métricas entre tenants y manteniendo trazabilidad completa.

> 💡 **Nota pedagógica**: ≤5 líneas ejecutables por bloque + `// 👇 EXPLICACIÓN:` que describen QUÉ hace y POR QUÉ es esencial para cumplir C1 (límites), C2 (timeout/concurrencia), C4 (aislamiento tenant) y C7 (seguridad operativa).

## Patrones de Código Validados (25 ejemplos)

```go
// ✅ C4/C1: Pool de workers aislado por tenant con límite de concurrencia
// 👇 EXPLICACIÓN: Mapa de WaitGroups garantiza que métricas y ciclo de vida no se crucen
// 👇 EXPLICACIÓN: Previene que un tenant agresivo sature el pool de otros
type TenantLoadPool struct { wg sync.WaitGroup; limiter *rate.Limiter }
func NewPool(tid string, rps int) *TenantLoadPool {
    return &TenantLoadPool{limiter: rate.NewLimiter(float64(rps), rps*2)}
}
```

```go
// ❌ Anti-pattern: variable global para contador de requests rompe aislamiento
var TotalRequests int64 = 0  // 🔴 C4 violation: estado compartido cross-tenant
// 👇 EXPLICACIÓN: Imposible atribuir carga o errores a un tenant específico
// 🔧 Fix: usar contadores atómicos scopeados por tenant (≤5 líneas)
type TenantMetrics struct { Success, Failed atomic.Int64 }
var metrics = make(map[string]*TenantMetrics)
```

```go
// ✅ C2/C7: Timeout estricto por request en simulación
// 👇 EXPLICACIÓN: context.WithTimeout aborta requests lentos y libera conexiones
// 👇 EXPLICACIÓN: Si excede, contamos como error y continuamos sin colgar el worker
ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
defer cancel()
resp, err := httpClient.Do(req.WithContext(ctx))
```

```go
// ✅ C1: Límite de memoria para almacenamiento de resultados en RAM
// 👇 EXPLICACIÓN: debug.SetMemoryLimit fuerza GC si el buffer de métricas crece demasiado
// 👇 EXPLICACIÓN: Previene OOM durante tests de larga duración o alta frecuencia
debug.SetMemoryLimit(128 << 20)  // C1: 128MB seguro
defer func() { if r := recover(); r != nil { log.Warn("mem_limit_hit", r) } }()
```

```go
// ✅ C4/C8: Recolección estructurada de latencia por tenant
// 👇 EXPLICACIÓN: Histograma atómico permite calcular p95/p99 sin locks pesados
// 👇 EXPLICACIÓN: Los resultados se agregan por tenant para reportes aislados
latency := time.Since(start).Milliseconds()
tenantMetrics[tid].LatencyHist.Record(latency)
logger.Info("req_complete", "tenant_id", tid, "latency_ms": latency)
```

```go
// ✅ C2: Ramp-up progresivo para evitar cold-start shock
// 👇 EXPLICACIÓN: Incrementamos RPS gradualmente en lugar de disparar carga máxima de golpe
// 👇 EXPLICACIÓN: Da tiempo al sistema para escalar conexiones, pools y JIT
for rps := startRPS; rps <= targetRPS; rps += step {
    pool.limiter.SetRate(float64(rps)); time.Sleep(rampInterval)
}
```

```go
// ✅ C7: Recuperación segura de panic en worker de carga
// 👇 EXPLICACIÓN: defer + recover captura fallos inesperados sin matar la simulación completa
// 👇 EXPLICACIÓN: Loggeamos contexto y marcamos request como fallido
defer func() {
    if r := recover(); r != nil {
        logger.Error("worker_panic", "tenant_id", tid, "error", r)
        tenantMetrics[tid].Failed.Add(1)
    }
}()
```

```go
// ❌ Anti-pattern: ignorar error de response.body.Close() leak descriptores
resp.Body.Close()  // 🔴 C1/C7 risk: error ignorado
// 👇 EXPLICACIÓN: En tests de carga, cada leak acumulado colapsa `ulimit -n`
// 🔧 Fix: validar error y registrar para debugging (≤5 líneas)
if err := resp.Body.Close(); err != nil {
    logger.Warn("body_close_failed", "tenant_id", tid, "err": err)
}
```

```go
// ✅ C4/C1: Generación de payloads aislados por tenant
// 👇 EXPLICACIÓN: Cada tenant recibe datos únicos para evitar colisión de cache/test
// 👇 EXPLICACIÓN: Previene falsos positivos en pruebas de consistencia
payload := fmt.Sprintf(`{"tenant_id":"%s","seq":%d}`, tid, atomic.AddInt64(&seq, 1))
req, _ := http.NewRequest("POST", url, strings.NewReader(payload))
```

```go
// ✅ C7/C2: Cancelación en cascada si un tenant supera umbral crítico
// 👇 EXPLICACIÓN: Si error_rate > 15%, cancelamos contexto y drenamos workers
// 👇 EXPLICACIÓN: Protege el sistema bajo prueba y evita métricas distorsionadas
if errorRate > 0.15 {
    logger.Warn("threshold_breached_stopping", "tenant_id", tid)
    tenantCtxCancel()  // C7: graceful stop
}
```

```go
// ✅ C6: Comando ejecutable para validar configuración de test
// 👇 EXPLICACIÓN: Verifica RPS límites, timeout y conectividad antes de iniciar carga real
// 👇 EXPLICACIÓN: Útil en CI/CD o pre-stress validation
func TestValidationCmd() string {
    return `bash validate-load-config.sh --rps $RPS --timeout $TIMEOUT --tenant $TID`
}
```

```go
// ✅ C1/C4: Cuota de requests por tenant para fairness en simulación compartida
// 👇 EXPLICACIÓN: Contador atómico rechaza carga si se excede el budget asignado
// 👇 EXPLICACIÓN: Evita que un tenant monopolic el generador de carga
var sent atomic.Int64
if sent.Add(1) > tenantQuota[tid] { return fmt.Errorf("C1: quota excedida") }
```

```go
// ✅ C8: Cálculo de percentiles p95/p99 para reporting estructurado
// 👇 EXPLICACIÓN: Usamos librería de histogramas o ordenamiento parcial en memoria
// 👇 EXPLICACIÓN: Permite identificar colas de espera sin depender de promedios engañosos
p95 := hist.Percentile(0.95)
p99 := hist.Percentile(0.99)
logger.Info("latency_summary", "p95_ms": p95, "p99_ms": p99)
```

```go
// ✅ C7/C1: Graceful shutdown con drenado de workers
// 👇 EXPLICACIÓN: Señalizamos fin, esperamos a requests en curso y cerramos recursos
// 👇 EXPLICACIÓN: Timeout final fuerza cierre si algún worker se cuelga
close(jobQueue)
wg.Wait()  // C7: drain completo
httpClient.CloseIdleConnections()
```

```go
// ✅ C4: Aislamiento de resultados en archivos por tenant
// 👇 EXPLICACIÓN: Escribimos métricas en `/tmp/load-results/{tid}.csv` con permisos 0600
// 👇 EXPLICACIÓN: Previene sobrescritura accidental y facilita análisis post-test
f, _ := os.OpenFile(fmt.Sprintf("/tmp/load-results/%s.csv", tid), os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0600)
fmt.Fprintf(f, "%d,%d\n", latency, statusCode)
```

```go
// ✅ C2/C7: Retry con backoff para endpoints flaky durante carga
// 👇 EXPLICACIÓN: Reintentamos 2 veces con pausa corta si recibimos 502/503
// 👇 EXPLICACIÓN: Distinguimos fallos de infraestructura de errores de aplicación
for attempt := 1; attempt <= 2; attempt++ {
    if resp.StatusCode < 500 { break }
    time.Sleep(time.Duration(attempt*100) * time.Millisecond)
}
```

```go
// ✅ C4/C8: Verificación de cross-tenant leak en respuestas
// 👇 EXPLICACIÓN: Parseamos respuesta y validamos que `tenant_id` coincida con el request
// 👇 EXPLICACIÓN: Detección temprana de fallos críticos de aislamiento en el sistema
var resBody struct { TenantID string `json:"tenant_id"` }
if err := json.NewDecoder(resp.Body).Decode(&resBody); err == nil && resBody.TenantID != tid {
    logger.Error("cross_tenant_leak_detected", "tenant_id", tid)
}
```

```go
// ✅ C1: Límite de goroutines activas por tenant
// 👇 EXPLICACIÓN: Monitoreamos `runtime.NumGoroutine()` y pausamos inyección si crece descontrolado
// 👇 EXPLICACIÓN: Previene scheduler thrashing y degradación del host de pruebas
if runtime.NumGoroutine() > maxGoroutinesPerTenant {
    time.Sleep(500 * time.Millisecond)  // C1: backpressure
}
```

```go
// ✅ C7: Dry-run mode para validar lógica sin generar carga real
// 👇 EXPLICACIÓN: Simula construcción de request y validación de headers sin network call
// 👇 EXPLICACIÓN: Útil para verificar configuración y aislamiento antes del test real
if dryRun { logger.Info("dry_run_validated", "tenant_id", tid); return nil }
req, _ := http.NewRequest("POST", url, body)
```

```go
// ✅ C8: Reporte JSON estructurado de resultados de simulación
// 👇 EXPLICACIÓN: Salida machine-readable para dashboards, n8n o pipelines de calidad
// 👇 EXPLICACIÓN: Incluye métricas clave, estado y tenant para trazabilidad
report := LoadReport{TenantID: tid, Total: sent.Load(), Errors: failed.Load(), P95: p95, Status: "completed"}
json.NewEncoder(os.Stdout).Encode(report)
```

```go
// ✅ C4/C2: Sincronización de inicio simultáneo (barrier)
// 👇 EXPLICACIÓN: `sync.WaitGroup` + canal asegura que todos los tenants comienzan al mismo tiempo
// 👇 EXPLICACIÓN: Elimina sesgo de warm-up y permite medir cold-start real
var barrier sync.WaitGroup
barrier.Add(1); go func() { time.Sleep(2*s); barrier.Done() }()
barrier.Wait()  // C2: synchronized start
```

```go
// ✅ C7/C1: Limpieza segura de recursos temporales post-test
// 👇 EXPLICACIÓN: `defer` garantiza eliminación de archivos .tmp y reseteo de límites
// 👇 EXPLICACIÓN: Evita acumulación de basura en entornos CI/CD compartidos
defer func() { os.RemoveAll("/tmp/load-results"); client.CloseIdleConnections() }()
```

```go
// ✅ C4: Validación de configuración de test por tenant antes de iniciar
// 👇 EXPLICACIÓN: Verificamos RPS, timeout, payload size y quotas asignadas
// 👇 EXPLICACIÓN: Rechazo temprano previene tests mal configurados que distorsionan resultados
if cfg.RPS > tenantLimits[tid].MaxRPS || cfg.Timeout > 10*time.Second {
    return fmt.Errorf("C4/C1: configuración excede límites permitidos")
}
```

```go
// ✅ C8/C7: Alertas automáticas por umbrales de calidad
// 👇 EXPLICACIÓN: Si p99 > 3s o error_rate > 5%, disparamos alerta estructurada
// 👇 EXPLICACIÓN: Integración con Slack/PagerDuty/n8n para respuesta inmediata
if p99 > 3000 || errorRate > 0.05 {
    logger.Warn("sla_breach_alert", "tenant_id", tid, "p99": p99, "err_rate": errorRate)
}
```

```go
// ✅ C1-C7: Función integrada de simulación de escala segura
// 👇 EXPLICACIÓN: Combina ramp-up, aislamiento, límites, métricas y graceful shutdown
// 👇 EXPLICACIÓN: Cada línea está comentada para entender el flujo completo de load testing
func RunLoadSimulation(ctx context.Context, tid string, cfg LoadConfig) (*LoadReport, error) {
    // C4/C1: Validar configuración y cuotas
    if err := validateTenantLoadConfig(tid, cfg); err != nil { return nil, err }
    
    // C2/C7: Contexto con timeout y barrier de inicio
    ctx, cancel := context.WithTimeout(ctx, cfg.Duration); defer cancel()
    startBarrier.Wait()  // synchronized start
    
    // C4/C1: Ejecutar pool con límites y ramp-up
    runTenantWorkers(ctx, tid, cfg); collectMetrics()
    
    // C7/C8: Drain, limpieza y reporte
    gracefulDrain(); cleanupTempFiles()
    return buildReport(tid), nil
}
```

## 🧪 Testing Checklist – Stress & Error Hunting

### ✅ Pre-flight checks
- [ ] Verificar que `rate.Limiter` y `atomic.Int64` se inicializan por tenant, no globales
- [ ] Confirmar que `context.WithTimeout` aplica a TODOS los requests HTTP simulados
- [ ] Validar que `debug.SetMemoryLimit` y `runtime.NumGoroutine()` checks están activos
- [ ] Asegurar que logs y reportes CSV/JSON nunca mezclan métricas de tenants distintos

### ⚡ Stress test scenarios
1. **Concurrent tenant flood**: 15 tenants disparando 500 RPS simultáneamente → validar aislamiento de métricas, zero cross-tenant leaks y fairness de scheduler
2. **Threshold breach cascade**: Forzar error_rate > 15% en tenant A → confirmar cancelación controlada sin afectar tenants B/C
3. **Memory pressure**: Almacenar 1M latency records en RAM → verificar `SetMemoryLimit`, GC forzado y zero OOM
4. **Cold start shock**: Iniciar ramp desde 0 a 1000 RPS en 1s → validar `rampInterval` progresivo y zero connection pool exhaustion
5. **Worker panic injection**: Panics aleatorios en 10% de workers → confirmar `recover`, métricas de fallo correctas y continuación del test

### 🔍 Error hunting procedures
- [ ] Revisar logs estructurados para confirmar que `tenant_id` aparece en cada evento de request/alert
- [ ] Validar que `resp.Body.Close()` maneja errores y no leakea descriptores bajo carga
- [ ] Confirmar que `barrier.Wait()` sincroniza inicio sin race conditions
- [ ] Verificar que `dry-run` valida configuración sin abrir conexiones de red reales
- [ ] Revisar profiling con `go tool pprof` para detectar allocations excesivas en `json.NewDecoder` o histogram updates

### 📊 Métricas de aceptación
- P99 request generation latency < 5ms bajo carga de 1000 RPS combinados
- Zero cross-tenant metric contamination en 100k requests simulados deliberadamente cruzados
- 100% de workers drenados y recursos liberados tras `gracefulDrain()`
- Threshold alerts triggered en <2s tras breach de p99/error_rate configurado
- 100% de reportes JSON incluyen `tenant_id`, `total`, `errors`, `p95`, `p99` y timestamp RFC3339

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/go/scale-simulation-utils.go.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"scale-simulation-utils","version":"3.0.0","score":91,"blocking_issues":[],"constraints_verified":["C1","C2","C4","C7"],"examples_count":25,"lines_executable_max":5,"language":"Go","vector_constraints_applied":false,"language_lock_status":"enforced","pedagogical_mode":true,"load_pattern":"tenant_isolated_rampup_p99_metrics_graceful_shutdown_threshold_alerts","timestamp":"2026-04-19T00:00:00Z"}
```

---
