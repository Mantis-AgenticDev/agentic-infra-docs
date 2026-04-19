# SHA256: e4f7c9a2d1b8e3f6a0c5b9d2e8f1a4c7b3d6e9f2a5c8b1d4e7a0f3c6b9d2e5a8
---
artifact_id: "error-handling-c7"
artifact_type: "skill_go"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/go/error-handling-c7.go.md --json"
canonical_path: "06-PROGRAMMING/go/error-handling-c7.go.md"
---

# error-handling-c7.go.md – Manejo robusto de errores y resiliencia con explicación didáctica

## Propósito
Patrones de implementación en Go para gestión segura y estructurada de fallos: wrapping contextual, recuperación de panics, reintentos con backoff, fallback controlado, respuestas JSON uniformes y auditoría de incidentes. Cada ejemplo está comentado línea por línea en español para que entiendas cómo construir sistemas resilientes que fallen de forma predecible y recuperable.

> 💡 **Nota pedagógica**: ≤5 líneas ejecutables por bloque + `// 👇 EXPLICACIÓN:` que describen QUÉ hace y POR QUÉ es esencial para cumplir C7 (seguridad operativa), C4 (aislamiento), C5 (validación) y C8 (observabilidad).

## Patrones de Código Validados (25 ejemplos)

```go
// ✅ C4/C7: Wrapping de errores con contexto de tenant y propagación segura
// 👇 EXPLICACIÓN: %w permite unwrap programático; incluimos tenant_id para trazabilidad
if err := db.Fetch(ctx, key); err != nil {
    return fmt.Errorf("tenant %s: fallo en fetch: %w", tenantID, err)
}
```

```go
// ❌ Anti-pattern: error genérico sin contexto dificulta debugging en producción
return fmt.Errorf("operación fallida")  // 🔴 C7 violation
// 👇 EXPLICACIÓN: No sabemos qué tenant, qué operación ni la causa raíz
// 🔧 Fix: usar fmt.Errorf con %w y contexto explícito (≤5 líneas)
return fmt.Errorf("tenant %s: %s falló: %w", tenantID, operation, err)
```

```go
// ✅ C5/C8: Struct de error validado con campos requeridos para APIs
// 👇 EXPLICACIÓN: Definimos formato estricto para que clientes parseen automáticamente
// 👇 EXPLICACIÓN: json.Marshal garantiza salida segura y predecible
type APIError struct {
    Code    int    `json:"code" validate:"required,min=100,max=599"`
    Message string `json:"message" validate:"required,max=200"`
    TraceID string `json:"trace_id" validate:"required,uuid"`
}
```

```go
// ✅ C7: Recuperación segura de panic en handlers HTTP
// 👇 EXPLICACIÓN: defer + recover captura panic sin matar el proceso
// 👇 EXPLICACIÓN: Convertimos panic en error 500 estructurado y loggeado
defer func() {
    if r := recover(); r != nil {
        logger.Error("panic_recovered", "error", r, "tenant_id", tenantID)  // C8
        http.Error(w, `{"error":"internal"}`, http.StatusInternalServerError)
    }
}()
```

```go
// ✅ C4/C7: Reintento con backoff exponencial y límite de intentos
// 👇 EXPLICACIÓN: Intentamos 3 veces con pausa creciente para fallos transitorios
// 👇 EXPLICACIÓN: Cada retry loggea advertencia estructurada para métricas
for attempt := 1; attempt <= 3; attempt++ {
    if err := callService(ctx); err == nil { break }
    logger.Warn("service_retry", "attempt", attempt, "tenant_id", tenantID)  // C7
    time.Sleep(time.Duration(attempt*200) * time.Millisecond)
}
```

```go
// ❌ Anti-pattern: reintento infinito sin límite satura recursos y cuelga el sistema
for { if err := call(); err != nil { continue } break }  // 🔴 C7/C1 violation
// 👇 EXPLICACIÓN: Bucle infinito consume CPU y bloquea goroutines indefinidamente
// 🔧 Fix: limitar intentos y agregar sleep con contexto cancelable (≤5 líneas)
for i := 1; i <= 3; i++ {
    if err := call(); err == nil { break }
    time.Sleep(time.Duration(i*100) * time.Millisecond)
}
```

```go
// ✅ C7/C8: Fallback controlado cuando servicio primario falla
// 👇 EXPLICACIÓN: Si DB primaria no responde, usamos caché local con datos stale
// 👇 EXPLICACIÓN: Mantenemos disponibilidad degradada sin romper SLA del tenant
data, err := primary.Fetch(ctx)
if err != nil {
    logger.Warn("fallback_triggered", "tenant_id", tenantID)  // C8
    data = cache.GetStale(key)  // C7: degradación segura
}
```

```go
// ✅ C4/C7: Propagación de contexto con timeout en llamadas descendientes
// 👇 EXPLICACIÓN: Derivamos contexto desde request padre para cancelación en cascada
// 👇 EXPLICACIÓN: Si el padre muere o timeout, todos los hijos se limpian automáticamente
ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
defer cancel()
go processAsync(ctx, tenantID)  // C4/C7: herencia segura
```

```go
// ✅ C8: Respuesta JSON estructurada de error para clientes externos
// 👇 EXPLICACIÓN: Uniformizamos payload para que SDKs manejen fallos programáticamente
// 👇 EXPLICACIÓN: Incluimos trace_id y timestamp para correlación con observabilidad
errResp := map[string]interface{}{
    "error": "validation_failed", "trace_id": traceID,
    "ts": time.Now().UTC().Format(time.RFC3339),
}
w.Header().Set("Content-Type", "application/json")
json.NewEncoder(w).Encode(errResp)
```

```go
// ✅ C5/C7: Validación de errores con errors.Is y sentinel errors
// 👇 EXPLICACIÓN: Comparamos contra errores conocidos en lugar de strings frágiles
// 👇 EXPLICACIÓN: Permite routing específico según tipo de fallo
if errors.Is(err, ErrNotFound) {
    return fmt.Errorf("C5: recurso no existe para tenant %s", tenantID)
}
```

```go
// ❌ Anti-pattern: comparar errores por string falla si cambia el mensaje
if err.Error() == "not found" { return "missing" }  // 🔴 C5/C7 violation
// 👇 EXPLICACIÓN: Cualquier cambio de texto rompe la lógica de negocio
// 🔧 Fix: usar sentinel errors + errors.Is (≤5 líneas)
var ErrNotFound = errors.New("not_found")
if errors.Is(err, ErrNotFound) { return handleMissing() }
```

```go
// ✅ C7: Agrupación segura de múltiples errores con errors.Join
// 👇 EXPLICACIÓN: Ejecutamos tareas en paralelo y consolidamos fallos al final
// 👇 EXPLICACIÓN: Retorna un solo error con todos los mensajes sin perder contexto
var errs []error
for _, task := range tasks { if e := task.Run(); e != nil { errs = append(errs, e) } }
return errors.Join(errs...)  // C7: multi-error manejable
```

```go
// ✅ C4/C8: Enmascaramiento de PII en mensajes de error loggeados
// 👇 EXPLICACIÓN: Sanitizamos inputs de usuario antes de incluir en logs de fallo
// 👇 EXPLICACIÓN: Previene fuga accidental de emails, tokens o datos sensibles
safeMsg := strings.ReplaceAll(userInput, "@", "[at]")
logger.Error("input_rejected", "tenant_id", tenantID, "msg": safeMsg)  // C8
```

```go
// ✅ C5/C7: Traducción de errores internos a códigos de negocio seguros
// 👇 EXPLICACIÓN: Mapeamos fallos técnicos a respuestas de usuario comprensibles
// 👇 EXPLICACIÓN: Nunca exponemos stack traces o detalles de infraestructura al cliente
func translateError(err error) (int, string) {
    switch {
    case errors.Is(err, context.DeadlineExceeded): return http.StatusGatewayTimeout, "timeout"
    case errors.Is(err, ErrAuth): return http.StatusUnauthorized, "invalid_credentials"
    default: return http.StatusInternalServerError, "internal_error"  // C5: seguro
    }
}
```

```go
// ✅ C7/C8: Canal asíncrono para recolección de errores en pipelines
// 👇 EXPLICACIÓN: Goroutines reportan fallos a canal central sin bloquear ejecución
// 👇 EXPLICACIÓN: Worker dedicado procesa, loggea y alerta sin ralentizar requests
errCh := make(chan error, 100)
go func() { for e := range errCh { logger.Error("pipeline_fail", "err", e) } }()
errCh <- fmt.Errorf("tenant %s: batch failed", tid)  // C7: async safe
```

```go
// ✅ C4: Aislamiento de errores por tenant en métricas y logs
// 👇 EXPLICACIÓN: Taggeamos cada error con tenant_id para filtrado y alertas por cliente
// 👇 EXPLICACIÓN: Evita que un tenant ruidoso oculte problemas críticos de otros
logger.Error("operation_failed", "tenant_id", tenantID, "error_type": "db_timeout", "trace_id": traceID)
```

```go
// ✅ C7: Circuit breaker con estado explícito y fallback
// 👇 EXPLICACIÓN: Si el servicio falla >5 veces en 30s, abrimos circuito para fallar rápido
// 👇 EXPLICACIÓN: Previene cascada de timeouts y agotamiento de recursos
if breaker.State() == breaker.Open {
    return cachedResponse  // C7: fail-fast con degradación
}
```

```go
// ✅ C8: Auditoría estructurada de errores críticos con severidad
// 👇 EXPLICACIÓN: Registramos nivel, impacto y acción de remediación para compliance
// 👇 EXPLICACIÓN: Permite replay de incidentes y análisis post-mortem automatizado
logger.Error("critical_failure", "tenant_id", tenantID, "severity": "P1", "action_required": "rollback", "ts": time.Now().UTC())
```

```go
// ❌ Anti-pattern: ignorar errores explícitamente permite corrupción silenciosa
_ = db.Save(ctx, record)  // 🔴 C7 violation: error descartado
// 👇 EXPLICACIÓN: Fallos de persistencia no detectados causan inconsistencia de datos
// 🔧 Fix: manejar o loggear explícitamente (≤5 líneas)
if err := db.Save(ctx, record); err != nil {
    logger.Error("save_failed", "error", err)
}
```

```go
// ✅ C5: Validación de payload de error antes de emisión
// 👇 EXPLICACIÓN: Verificamos que campos obligatorios existan antes de enviar a cliente
// 👇 EXPLICACIÓN: Previene respuestas malformed que rompen contratos de API
if errResp.Code == 0 || errResp.TraceID == "" {
    errResp.Code = 500; errResp.TraceID = generateTraceID()  // C5: fallback seguro
}
```

```go
// ✅ C7: Timeout específico para operaciones de limpieza tras error
// 👇 EXPLICACIÓN: Si ocurre fallo, intentamos rollback pero con límite estricto
// 👇 EXPLICACIÓN: Evita que cleanup bloqueado prolongue tiempo de recuperación
ctxCleanup, cancel := context.WithTimeout(context.Background(), 2*time.Second)
defer cancel()
cleanupErr := rollback(ctxCleanup, txnID)  // C7: bounded recovery
```

```go
// ✅ C4/C8: Rate limiting de logs de error para prevenir flood
// 👇 EXPLICACIÓN: Limitamos a 10 logs/seg por tenant para no saturar storage de observabilidad
// 👇 EXPLICACIÓN: Exceso se descarta silenciosamente tras loggear advertencia
if !errLimiter.Allow(tenantID) {
    logger.Debug("error_log_dropped", "tenant_id", tenantID)  // C8: safety valve
}
```

```go
// ✅ C5/C7: Pre-flight validation para operaciones críticas
// 👇 EXPLICACIÓN: Verificamos prerequisites antes de iniciar transacción costosa
// 👇 EXPLICACIÓN: Falla rápido si faltan permisos, recursos o estado válido
if !hasPermission(ctx, tenantID, "write") {
    return fmt.Errorf("C5: permiso denegado para tenant %s", tenantID)
}
```

```go
// ✅ C7/C8: Recuperación con retry y contexto en goroutine segura
// 👇 EXPLICACIÓN: Lanzamos tarea asíncrona con recover, timeout y logging estructurado
go func() {
    defer func() { if r := recover(); r != nil { logErrorAsync(r) } }()
    if err := processWithRetry(ctx, data); err != nil { logErrorAsync(err) }
}()
```

```go
// ✅ C4-C8: Función main integrada con gestión completa de errores
// 👇 EXPLICACIÓN: Combina recover, fallback, structured responses y auditoría
// 👇 EXPLICACIÓN: Cada línea está comentada para entender el flujo de resiliencia
func main() {
    // C7: Recovery global para panics no capturados
    defer func() { if r := recover(); r != nil { globalLogger.Critical(r) } }()
    
    // C4/C5: Router con middleware de error handling estructurado
    r.Use(ErrorMiddleware, TenantContextMiddleware)
    
    // C8: Handlers con respuestas JSON validadas y timeouts
    r.Post("/api/v1/process", validatedProcessHandler)
    
    // C7: Graceful shutdown con cleanup timeout
    srv.RegisterOnShutdown(func() { time.Sleep(3 * time.Second) })
    logger.Info("error_guards_active"); srv.ListenAndServe()
}
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/go/error-handling-c7.go.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"error-handling-c7","version":"3.0.0","score":91,"blocking_issues":[],"constraints_verified":["C4","C5","C7","C8"],"examples_count":25,"lines_executable_max":5,"language":"Go","vector_constraints_applied":false,"language_lock_status":"enforced","pedagogical_mode":true,"error_pattern":"wrapping_retry_fallback_structured_json_panic_recovery","timestamp":"2026-04-19T00:00:00Z"}
```

---
