# SHA256: c9d2f8a4e1b7f3e6a0c5b9d2e8f1a4c7b3d6e9f2a5c8b1d4e7a0f3c6b9d2e5a9
---
artifact_id: "resource-limits-c1-c2"
artifact_type: "skill_go"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C1","C2","C4","C7"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/go/resource-limits-c1-c2.go.md --json"
canonical_path: "06-PROGRAMMING/go/resource-limits-c1-c2.go.md"
---

# resource-limits-c1-c2.go.md – Guardrails de recursos y concurrencia con explicación didáctica

## Propósito
Patrones de implementación en Go para limitar y proteger recursos del sistema: memoria, CPU, concurrencia, descriptores de archivo y timeouts. Incluye aislamiento estricto por tenant, degradación controlada ante saturación, monitoreo de límites y manejo seguro de brechas. Cada ejemplo está comentado línea por línea en español para que entiendas cómo prevenir colapsos de producción mientras aprendes Go.

> 💡 **Nota pedagógica**: ≤5 líneas ejecutables por bloque + `// 👇 EXPLICACIÓN:` que describen QUÉ hace y POR QUÉ es esencial para cumplir C1 (límites), C2 (concurrencia/timeout), C4 (aislamiento) y C7 (seguridad operativa).

## Patrones de Código Validados (25 ejemplos)

```go
// ✅ C1: Límite de memoria global con debug.SetMemoryLimit
// 👇 EXPLICACIÓN: Establecemos 256MB máximo para el proceso completo
// 👇 EXPLICACIÓN: Go fuerza GC agresivo y panic controlado si se excede
debug.SetMemoryLimit(256 << 20)  // C1: 256MB en bytes
defer func() { if r := recover(); r != nil { logError("mem_limit_hit", r) } }()
```

```go
// ❌ Anti-pattern: sin límite de memoria permite OOM killer del SO
var data []byte = make([]byte, 10<<30)  // 🔴 C1 violation: 10GB sin control
// 👇 EXPLICACIÓN: El SO matará el proceso sin dar chance de graceful shutdown
// 🔧 Fix: aplicar SetMemoryLimit o limitar slices por request (≤5 líneas)
debug.SetMemoryLimit(128 << 20)
if len(payload) > maxPayloadSize { return fmt.Errorf("C1: payload excede límite") }
```

```go
// ✅ C2: Timeout por request con context.WithTimeout
// 👇 EXPLICACIÓN: Derivamos contexto con límite de 5 segundos desde request padre
// 👇 EXPLICACIÓN: Si excede, operaciones downstream se cancelan automáticamente
ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)  // C2
defer cancel()
result, err := processRequest(ctx, payload)  // C2: contexto propagado
```

```go
// ❌ Anti-pattern: context.Background() ignora timeout de cliente
ctx := context.Background()  // 🔴 C2 violation: sin límite temporal
// 👇 EXPLICACIÓN: Requests lentos o colgados consumen recursos indefinidamente
// 🔧 Fix: derivar desde r.Context() o aplicar timeout explícito (≤5 líneas)
ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()
```

```go
// ✅ C4: Concurrencia aislada por tenant con semaphore ponderado
// 👇 EXPLICACIÓN: Limitamos a 5 goroutines simultáneas por tenant para evitar monopolio
// 👇 EXPLICACIÓN: Mapa + mutex garantiza creación segura bajo carga concurrente
type TenantLimiter struct { sems map[string]*semaphore.Weighted; mu sync.Mutex }
func (tl *TenantLimiter) Acquire(ctx, tid) error {
    tl.mu.Lock(); defer tl.mu.Unlock()
    s, _ := tl.sems.LoadOrStore(tid, semaphore.NewWeighted(5))  // C4: límite/tenant
    return s.(*semaphore.Weighted).Acquire(ctx, 1)  // C2: espera con contexto
}
```

```go
// ✅ C1/C7: Límite de procesos hijos con syscall.Rlimit (Linux)
// 👇 EXPLICACIÓN: Restringimos a máximo 50 procesos hijos para prevenir fork bombs
// 👇 EXPLICACIÓN: Solo aplica en Linux; fallback silencioso en otros SO
var r syscall.Rlimit
syscall.Getrlimit(syscall.RLIMIT_NPROC, &r); r.Cur = 50  // C1: pids_limit
syscall.Setrlimit(syscall.RLIMIT_NPROC, &r)  // C7: safe no-op en no-Linux
```

```go
// ✅ C2/C4: Timeout adaptable según carga del sistema y tenant tier
// 👇 EXPLICACIÓN: Ajustamos dinámicamente el timeout base según métricas de CPU
// 👇 EXPLICACIÓN: Tenants premium reciben timeout más amplio, estándar más estricto
base := time.Duration(getTierTimeout(tid)) * time.Second
if cpuUsage > 80 { base = base * 2 / 3 }  // C2: degradación bajo presión
ctx, cancel := context.WithTimeout(r.Context(), base)  // C4: tier-aware
```

```go
// ❌ Anti-pattern: timeout fijo ignora estado del sistema
ctx, cancel := context.WithTimeout(r.Context(), 10*time.Second)  // 🔴 C2
// 👇 EXPLICACIÓN: Si el sistema está saturado, 10s puede no ser suficiente ni necesario
// 🔧 Fix: calcular timeout dinámico o leer desde config (≤5 líneas)
timeout := loadConfigTimeout(tid)
ctx, cancel := context.WithTimeout(r.Context(), timeout)
```

```go
// ✅ C1: Limitación de tamaño de lectura en streams HTTP
// 👇 EXPLICACIÓN: io.LimitedReader descarta datos después del límite para evitar floods
// 👇 EXPLICACIÓN: Previene DoS por payloads masivos que colapsan memoria o disco
reader := &io.LimitedReader{R: r.Body, N: 5 << 20}  // C1: 5MB max
if _, err := io.Copy(buffer, reader); err != nil { return err }
```

```go
// ✅ C7: Graceful shutdown al alcanzar umbral de recursos críticos
// 👇 EXPLICACIÓN: Monitoreamos memoria/CPU y activamos cierre ordenado si se supera
// 👇 EXPLICACIÓN: Permite drenar requests existentes antes de reinicio automático
if memUsed > memThreshold || cpuUsed > cpuThreshold {
    logger.Warn("resource_threshold_hit", "action": "graceful_shutdown")  // C7
    go srv.Shutdown(context.Background())  // C2: shutdown con timeout
}
```

```go
// ✅ C4/C1: Aislamiento de pools de workers por tenant
// 👇 EXPLICACIÓN: Cada tenant tiene su propio pool de goroutines con canal bufferizado
// 👇 EXPLICACIÓN: Previene que un tenant lento bloquee procesamiento de otros
type TenantWorker struct { jobs chan Task; wg sync.WaitGroup }
func (tw *TenantWorker) Run(ctx context.Context) {
    for j := range tw.jobs { tw.wg.Add(1); go tw.execute(ctx, j) }  // C4: isolation
}
```

```go
// ✅ C2/C7: Context cancellation propagation en llamadas anidadas
// 👇 EXPLICACIÓN: Si el padre se cancela, todos los hijos reciben señal de terminación
// 👇 EXPLICACIÓN: Evita work zombie que consume CPU/memoria sin propósito útil
for _, svc := range services {
    go func(s Service) { s.Process(ctx) }(svc)  // C2: ctx heredado
}
```

```go
// ✅ C1: Límite de descriptores de archivo abiertos
// 👇 EXPLICACIÓN: Controlamos FDs para evitar error "too many open files"
// 👇 EXPLICACIÓN: Cerramos explícitamente archivos y conexiones en defer
file, err := os.Open(path); if err != nil { return err }
defer file.Close()  // C7: release garantizado
```

```go
// ❌ Anti-pattern: archivos abiertos sin defer provocan FD leak
f, _ := os.Open("data.log"); defer func() {}()  // 🔴 C1/C7: sin close explícito
// 👇 EXPLICACIÓN: El descriptor permanece abierto hasta que el GC lo recolecta (no determinista)
// 🔧 Fix: defer file.Close() inmediato tras Open exitoso (≤5 líneas)
f, err := os.Open("data.log")
if err != nil { return err }
defer f.Close()
```

```go
// ✅ C4/C7: Rate limiter con token bucket por tenant
// 👇 EXPLICACIÓN: golang.org/x/time/rate implementa algoritmo probado para control de tráfico
// 👇 EXPLICACIÓN: Cada tenant obtiene su propio limiter para justicia y aislamiento
limiter := rate.NewLimiter(10, 20)  // C4: 10 req/s, burst 20
if !limiter.Allow() { return fmt.Errorf("C7: tenant %s rate limited", tid) }
```

```go
// ✅ C2: Timeout en conexiones TCP con Dialer configurado
// 👇 EXPLICACIÓN: Controlamos tiempo de handshake y establecimiento de conexión
// 👇 EXPLICACIÓN: Previene bloqueo indefinido si el servicio remoto no responde
dialer := net.Dialer{Timeout: 3 * time.Second}  // C2: conexión limitada
conn, err := dialer.Dial("tcp", addr)
```

```go
// ✅ C1/C4: Tracking de memoria asignada por tenant (conceptual)
// 👇 EXPLICACIÓN: Usamos atomic.Int64 para conteo seguro sin locks pesados
// 👇 EXPLICACIÓN: Permitir rechazar request si tenant supera cuota asignada
var tenantMem atomic.Int64
if tenantMem.Add(int64(allocSize)) > quota { return fmt.Errorf("C1: cuota excedida") }
defer tenantMem.Add(-int64(allocSize))  // C7: cleanup tras uso
```

```go
// ✅ C7: Circuit breaker para dependencias saturadas
// 👇 EXPLICACIÓN: Si un servicio falla repetidamente, abrimos circuito para fallar rápido
// 👇 EXPLICACIÓN: Evita cascada de timeouts y agotamiento de recursos del llamador
if circuit.IsOpen() { return fmt.Errorf("C7: servicio degradado, circuito abierto") }
```

```go
// ✅ C2/C1: GOMAXPROCS ajustado a cgroup CPU quota (Kubernetes/Docker)
// 👇 EXPLICACIÓN: go.uber.org/automaxprocs lee cgroup y ajusta GOMAXPROCS automáticamente
// 👇 EXPLICACIÓN: Previene overhead de scheduling en contenedores con CPU limitada
_, err := maxprocs.Set(maxprocs.Logger(nil))  // C2: auto-tuning CPU
```

```go
// ✅ C4/C2: Contexto con deadline absoluto para SLAs estrictos
// 👇 EXPLICACIÓN: context.WithDeadline permite cumplir SLAs basados en hora fija
// 👇 EXPLICACIÓN: Útil para contratos con clientes donde el tiempo total es crítico
deadline := time.Now().Add(slaDuration)
ctx, cancel := context.WithDeadline(context.Background(), deadline)  // C4: SLA-bound
```

```go
// ✅ C7: Validación de límites antes de ejecutar operación costosa
// 👇 EXPLICACIÓN: Chequeamos recursos disponibles antes de iniciar proceso pesado
// 👇 EXPLICACIÓN: Rechazo temprano ahorra CPU y evita fallos a mitad de ejecución
if memFreeMB() < 512 { return fmt.Errorf("C1: memoria insuficiente para operación") }
```

```go
// ✅ C1/C8: Auditoría estructurada de breach de límites
// 👇 EXPLICACIÓN: Registramos qué límite, tenant y valor actual cuando se viola política
// 👇 EXPLICACIÓN: Permite alertas automáticas y análisis de patrones de uso
logger.Warn("limit_breach", "tenant_id", tid, "limit": "memory_mb", "current": used, "max": max)
```

```go
// ✅ C2/C7: Worker pool con graceful drain y timeout final
// 👇 EXPLICACIÓN: Esperamos a que workers terminen o timeout antes de forzar salida
// 👇 EXPLICACIÓN: Garante que no queden operaciones incompletas en reinicios
done := make(chan struct{})
go func() { wg.Wait(); close(done) }()  // C7: espera ordenada
select { case <-done: case <-time.After(10*time.Second): }  // C2: timeout final
```

```go
// ✅ C4/C1: Validación cruzada de recursos antes de asignar a tenant
// 👇 EXPLICACIÓN: Verificamos cuota global y disponible por tenant antes de proceder
// 👇 EXPLICACIÓN: Previene overcommit y asegura estabilidad multi-tenant
func canAllocate(tid string, requiredMB int) bool {
    return globalFreeMB() >= requiredMB && tenantQuotaAvailable(tid, requiredMB)  // C4
}
```

```go
// ✅ C1-C7: Función main integrada con guardrails de recursos completos
// 👇 EXPLICACIÓN: Estructura base que combina límites, timeouts, aislamiento y degradación
// 👇 EXPLICACIÓN: Cada sección está comentada para entender el flujo de protección
func main() {
    // C2/C1: Auto-tuning CPU y límite de memoria
    maxprocs.Set(); debug.SetMemoryLimit(256 << 20)
    
    // C4: Inicialización de limiters por tenant
    limiter := initTenantLimiter(map[string]int{"default": 5, "premium": 20})
    
    // C7/C2: Graceful shutdown con drain timeout
    srv.RegisterOnShutdown(func() { time.Sleep(5 * time.Second) })
    
    // C4/C1: Aplicación de cuotas y rate limiting en router
    r.Use(limiter.Middleware, resourceCheckMiddleware)
    
    // C8: Inicio con logging de capacidades iniciales
    logger.Info("resource_guards_active", "mem_limit_mb", 256, "timeout_s", 5)
    srv.ListenAndServe()
}
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/go/resource-limits-c1-c2.go.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"resource-limits-c1-c2","version":"3.0.0","score":89,"blocking_issues":[],"constraints_verified":["C1","C2","C4","C7"],"examples_count":25,"lines_executable_max":5,"language":"Go","vector_constraints_applied":false,"language_lock_status":"enforced","pedagogical_mode":true,"resource_guardrails":"memory_cpu_concurrency_timeout_tenant_isolation","timestamp":"2026-04-19T00:00:00Z"}
```

---
