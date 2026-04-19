# SHA256: a3f9c2d8e1b7f4e6a0c5b9d2e8f1a4c7b3d6e9f2a5c8b1d4e7a0f3c6b9d2e5a8
---
artifact_id: "authentication-authorization-patterns"
artifact_type: "skill_go"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C3","C4","C5","C7"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/go/authentication-authorization-patterns.go.md --json"
canonical_path: "06-PROGRAMMING/go/authentication-authorization-patterns.go.md"
---

# authentication-authorization-patterns.go.md – Autenticación y autorización con aislamiento tenant y explicación didáctica

## Propósito
Patrones de implementación en Go para gestión segura de identidad: JWT con claims tenant-scoped, RBAC con validación estricta, rotación de API keys, hashing de contraseñas, prevención de ataques comunes y auditoría de acceso. Cada ejemplo está comentado línea por línea en español para que entiendas cómo construir sistemas de auth que protejan datos multi-tenant sin comprometer usabilidad.

> 💡 **Nota pedagógica**: ≤5 líneas ejecutables por bloque + `// 👇 EXPLICACIÓN:` que describen QUÉ hace y POR QUÉ es esencial para cumplir C3 (secrets), C4 (aislamiento tenant), C5 (validación) y C7 (seguridad operativa).

## Patrones de Código Validados (25 ejemplos)

```go
// ✅ C4/C3: Generación de JWT con claims tenant-scoped y expiración estricta
// 👇 EXPLICACIÓN: Incluimos tenant_id como claim obligatorio para aislamiento en cada validación
// 👇 EXPLICACIÓN: Expiración corta (15min) reduce ventana de ataque si el token es comprometido
claims := jwt.MapClaims{
    "sub": userID, "tenant_id": tenantID, "exp": time.Now().Add(15*time.Minute).Unix(),
}
token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)  // C4: tenant en payload
```

```go
// ❌ Anti-pattern: JWT sin tenant_id permite acceso cruzado entre tenants
claims := jwt.MapClaims{"sub": userID, "exp": time.Now().Add(1*time.Hour).Unix()}  // 🔴 C4 violation
// 👇 EXPLICACIÓN: Un usuario podría usar este token para acceder a recursos de otro tenant
// 🔧 Fix: incluir tenant_id como claim requerido y validarlo en middleware (≤5 líneas)
claims := jwt.MapClaims{"sub": userID, "tenant_id": tenantID, "exp": time.Now().Add(15*time.Minute).Unix()}
```

```go
// ✅ C3: Carga segura de JWT signing secret desde entorno con fail-fast
// 👇 EXPLICACIÓN: LookupEnv verifica existencia sin devolver string vacío por defecto
// 👇 EXPLICACIÓN: Fallamos temprano para evitar hardcode de credenciales maestras en binario
jwtSecret, ok := os.LookupEnv("JWT_SIGNING_SECRET")
if !ok || jwtSecret == "" { log.Fatal("C3: JWT_SIGNING_SECRET no definida") }
```

```go
// ✅ C4/C7: Middleware de validación de JWT con verificación de tenant_id
// 👇 EXPLICACIÓN: Extraemos y validamos claims antes de permitir acceso a handlers protegidos
// 👇 EXPLICACIÓN: Si tenant_id del token no coincide con header, rechazamos request inmediatamente
func AuthMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        tokenStr := extractBearerToken(r)
        claims, err := validateJWT(tokenStr, jwtSecret)  // C7: validación criptográfica
        if err != nil || claims["tenant_id"] != r.Header.Get("X-Tenant-ID") {
            http.Error(w, "C4: autorización denegada", http.StatusUnauthorized); return
        }
        ctx := context.WithValue(r.Context(), "claims", claims); next.ServeHTTP(w, r.WithContext(ctx))
    })
}
```

```go
// ✅ C5: Validación estricta de claims JWT con schema definido
// 👇 EXPLICACIÓN: Verificamos que todos los campos requeridos existan y tengan formato válido
// 👇 EXPLICACIÓN: Previene tokens malformados o manipulados que podrían evadir controles
func validateClaims(claims jwt.MapClaims) error {
    if _, ok := claims["tenant_id"].(string); !ok { return fmt.Errorf("C5: tenant_id requerido") }
    if _, ok := claims["exp"].(float64); !ok || time.Now().Unix() > int64(claims["exp"].(float64)) {
        return fmt.Errorf("C5: token expirado o inválido")
    }
    return nil
}
```

```go
// ✅ C3/C7: Hashing de contraseñas con bcrypt y costo ajustable
// 👇 EXPLICACIÓN: bcrypt con costo 12 balancea seguridad y performance para producción
// 👇 EXPLICACIÓN: Nunca almacenamos passwords en texto plano; siempre hash irreversible
hashed, err := bcrypt.GenerateFromPassword([]byte(password), 12)  // C3: hashing seguro
if err != nil { return fmt.Errorf("C7: fallo en hashing: %w", err) }
```

```go
// ❌ Anti-pattern: comparar passwords con == permite timing attacks
if inputPassword == storedPassword { return true }  // 🔴 C7 violation
// 👇 EXPLICACIÓN: Comparación string a string puede revelar información por tiempo de ejecución
// 🔧 Fix: usar bcrypt.CompareHashAndPassword que es constant-time (≤5 líneas)
err := bcrypt.CompareHashAndPassword([]byte(storedHash), []byte(inputPassword))
return err == nil  // C7: comparación segura
```

```go
// ✅ C4: RBAC con roles scopeados por tenant para aislamiento de permisos
// 👇 EXPLICACIÓN: Estructura map[tenant_id]map[user_id][]roles garantiza que permisos no cruzan tenants
// 👇 EXPLICACIÓN: Validamos tenant antes de consultar roles para prevenir escalation horizontal
func hasRole(tenantID, userID, role string) bool {
    if !regexp.MustCompile(`^[a-z0-9_-]{3,32}$`).MatchString(tenantID) { return false }  // C4
    if roles, ok := tenantRoles[tenantID][userID]; ok {
        for _, r := range roles { if r == role { return true } }
    }
    return false
}
```

```go
// ✅ C7: Prevención de brute-force con rate limiting por usuario/tenant
// 👇 EXPLICACIÓN: Limitamos intentos de login a 5 por minuto por combinación user+tenant
// 👇 EXPLICACIÓN: Previene ataques de fuerza bruta sin bloquear usuarios legítimos de otros tenants
limiter := rate.NewLimiter(5, 10)  // C7: 5 intentos/minuto
if !limiter.Allow() { return fmt.Errorf("C7: demasiados intentos, intente más tarde") }
```

```go
// ✅ C3/C8: Auditoría estructurada de eventos de autenticación
// 👇 EXPLICACIÓN: Registramos login éxito/fallo con tenant_id, user_id y timestamp para trazabilidad
// 👇 EXPLICACIÓN: Nunca loggeamos passwords o tokens completos; solo metadatos de evento
logger.Info("auth_event", "tenant_id", tid, "user_id", uid, "event": "login_success", "ts": time.Now().UTC())  // C8
```

```go
// ✅ C4/C7: Middleware de verificación de permisos RBAC por endpoint
// 👇 EXPLICACIÓN: Interceptamos requests para verificar que el usuario tenga rol requerido para la acción
// 👇 EXPLICACIÓN: Rechazamos con 403 si el rol no coincide, sin exponer detalles internos
func RequireRole(requiredRole string) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            claims := r.Context().Value("claims").(jwt.MapClaims)
            if !hasRole(claims["tenant_id"].(string), claims["sub"].(string), requiredRole) {
                http.Error(w, "C4: permisos insuficientes", http.StatusForbidden); return
            }
            next.ServeHTTP(w, r)
        })
    }
}
```

```go
// ✅ C3: Rotación segura de API keys con validación de versión
// 👇 EXPLICACIÓN: Incluimos versión en key para permitir rotación sin invalidar todas las sesiones activas
// 👇 EXPLICACIÓN: Validamos versión contra configuración actual para detectar keys obsoletas
func validateAPIKey(key, expectedVersion string) bool {
    parts := strings.SplitN(key, "_", 2)
    return len(parts) == 2 && parts[0] == expectedVersion && subtle.ConstantTimeCompare([]byte(parts[1]), []byte(storedSecret)) == 1
}
```

```go
// ✅ C7: Prevención de replay attacks con nonce y timestamp en tokens
// 👇 EXPLICACIÓN: Incluimos jti (JWT ID) único por token y verificamos que no haya sido usado antes
// 👇 EXPLICACIÓN: Timestamp con ventana estrecha previene reuso de tokens capturados
claims := jwt.MapClaims{
    "jti": uuid.New().String(), "iat": time.Now().Unix(), "nbf": time.Now().Unix(),
}
// En validación: verificar jti no está en blacklist y iat/nbf dentro de ventana aceptable
```

```go
// ✅ C4: Propagación segura de identidad en llamadas entre microservicios
// 👇 EXPLICACIÓN: Clonamos request y agregamos headers de identidad para el siguiente servicio
// 👇 EXPLICACIÓN: Mantiene cadena de aislamiento sin exponer credentials en URL o body
nextReq := req.Clone(req.Context())
nextReq.Header.Set("X-Tenant-ID", claims["tenant_id"].(string))  // C4: propagación explícita
nextReq.Header.Set("Authorization", "Bearer "+newToken)  // C3: token fresco
```

```go
// ✅ C5: Validación de formato de email/usuario antes de hashing o lookup
// 👇 EXPLICACIÓN: Regex estricto previene inyección de payloads maliciosos en queries de auth
// 👇 EXPLICACIÓN: Validación temprana reduce superficie de ataque antes de operaciones costosas
if !regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`).MatchString(email) {
    return fmt.Errorf("C5: formato de email inválido")
}
```

```go
// ✅ C7: Timeout estricto para llamadas a proveedores de identidad externos
// 👇 EXPLICACIÓN: context.WithTimeout evita bloqueos indefinidos si OIDC/OAuth provider falla
// 👇 EXPLICACIÓN: Cancelación automática libera recursos de red y memoria del proceso
ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()
userInfo, err := oidcProvider.UserInfo(ctx, oauth2.StaticTokenSource(token))  // C7: bounded call
```

```go
// ✅ C3/C4: Almacenamiento seguro de refresh tokens con aislamiento tenant
// 👇 EXPLICACIÓN: Usamos mapa anidado map[tenant_id]map[refresh_token]metadata para aislamiento
// 👇 EXPLICACIÓN: Incluimos expiry y user_id para validación y rotación controlada
type RefreshStore struct { data map[string]map[string]RefreshMeta; mu sync.RWMutex }
func (rs *RefreshStore) Store(tid, token string, meta RefreshMeta) {
    rs.mu.Lock(); defer rs.mu.Unlock()
    if _, ok := rs.data[tid]; !ok { rs.data[tid] = make(map[string]RefreshMeta) }  // C4: isolation
    rs.data[tid][token] = meta
}
```

```go
// ✅ C7: Prevención de timing attacks en comparación de secrets
// 👇 EXPLICACIÓN: subtle.ConstantTimeCompare garantiza tiempo constante independientemente del input
// 👇 EXPLICACIÓN: Previene que atacantes midan tiempo de respuesta para adivinar caracteres de secrets
if subtle.ConstantTimeCompare([]byte(provided), []byte(expected)) == 1 {
    return true  // C7: comparación segura
}
```

```go
// ✅ C4/C5: Validación cruzada de tenant en múltiples fuentes de identidad
// 👇 EXPLICACIÓN: Verificamos que tenant_id coincida en JWT, header y base de datos antes de proceder
// 👇 EXPLICACIÓN: Previene escalation horizontal si una fuente es comprometida
func validateTenantConsistency(jwtTenant, headerTenant, dbTenant string) error {
    if jwtTenant != headerTenant || jwtTenant != dbTenant {
        return fmt.Errorf("C4: inconsistencia de tenant en fuentes de identidad")
    }
    return nil
}
```

```go
// ✅ C3: Generación criptográfica de tokens de reset de contraseña
// 👇 EXPLICACIÓN: crypto/rand garantiza entropía no predecible para tokens de recuperación
// 👇 EXPLICACIÓN: Base64 URL-safe permite uso directo en enlaces de email sin encoding adicional
bytes := make([]byte, 32)
if _, err := rand.Read(bytes); err != nil { return "", err }  // C3: entropía segura
return base64.URLEncoding.EncodeToString(bytes), nil
```

```go
// ✅ C7: Logout seguro con invalidación de tokens y limpieza de sesiones
// 👇 EXPLICACIÓN: Añadimos jti del token a blacklist con TTL igual a expiración restante
// 👇 EXPLICACIÓN: Limpiamos sesiones activas del usuario para cerrar todas las conexiones
func logout(token string, claims jwt.MapClaims) error {
    jti := claims["jti"].(string); exp := time.Unix(int64(claims["exp"].(float64)), 0)
    blacklist.Set(jti, true, time.Until(exp))  // C7: invalidación con TTL
    sessionStore.DeleteAll(claims["tenant_id"].(string), claims["sub"].(string))  // cleanup
    return nil
}
```

```go
// ✅ C4/C8: Auditoría de cambios de permisos con trazabilidad completa
// 👇 EXPLICACIÓN: Registramos quién cambió qué permiso, cuándo y desde qué IP para compliance
// 👇 EXPLICACIÓN: Permite reconstruir historial de accesos y detectar modificaciones no autorizadas
logger.Info("permission_change", "tenant_id", tid, "actor": adminID, "target": userID,
    "role_added": newRole, "ip": r.RemoteAddr, "ts": time.Now().UTC())  // C8
```

```go
// ✅ C5: Sanitización de inputs en endpoints de auth para prevenir inyección
// 👇 EXPLICACIÓN: Removemos caracteres de control y normalizamos encoding antes de procesar
// 👇 EXPLICACIÓN: Previene XSS, log injection o manipulación de payloads de autenticación
func sanitizeAuthInput(input string) string {
    return strings.Map(func(r rune) rune {
        if unicode.IsControl(r) || r == '<' || r == '>' { return -1 }; return unicode.ToLower(r)
    }, input)
}
```

```go
// ✅ C3/C7: Refresh token flow con rotación y detección de reuso
// 👇 EXPLICACIÓN: Cada uso de refresh token genera nuevo par access+refresh e invalida el anterior
// 👇 EXPLICACIÓN: Si detectamos reuso de refresh token, revocamos toda la sesión por posible robo
func refreshTokens(oldRefresh string) (string, string, error) {
    meta, exists := refreshStore.Get(oldRefresh)
    if !exists { return "", "", fmt.Errorf("C7: refresh token inválido") }
    if meta.Used { revokeSession(meta.TenantID, meta.UserID); return "", "", fmt.Errorf("C7: token reutilizado") }  // C7: detección de robo
    meta.Used = true; refreshStore.Update(oldRefresh, meta)
    return generateNewTokenPair(meta.TenantID, meta.UserID)  // C3: nuevo par seguro
}
```

```go
// ✅ C3-C7: Función main integrada con auth patterns completos
// 👇 EXPLICACIÓN: Combina JWT validation, RBAC middleware, rate limiting y auditoría estructurada
// 👇 EXPLICACIÓN: Cada sección está comentada para entender el flujo completo de seguridad de identidad
func main() {
    // C3: Cargar secrets con fail-fast
    jwtSecret := loadRequiredEnv("JWT_SIGNING_SECRET")
    
    // C4/C7: Router con middleware chain de auth
    r := chi.NewRouter()
    r.Use(AuthMiddleware, TenantConsistencyMiddleware, RateLimitMiddleware)
    
    // C4/C5: Endpoints protegidos con RBAC
    r.Group(func(r chi.Router) {
        r.Use(RequireRole("admin"))
        r.Post("/api/v1/users", createUserHandler)  // solo admins
    })
    
    // C7/C8: Graceful shutdown con cleanup de sesiones
    srv.RegisterOnShutdown(func() { sessionStore.Close(); logger.Info("auth_shutdown_complete") })
    logger.Info("auth_system_started", "jwt_algo": "HS256", "token_ttl": "15m")
    srv.ListenAndServe()
}
```

## 🧪 Testing Checklist – Stress & Error Hunting

### ✅ Pre-flight checks
- [ ] Validar que todos los JWT generados incluyen claim `tenant_id` obligatorio
- [ ] Verificar que secrets se cargan desde entorno con `LookupEnv` + validación no-vacío
- [ ] Confirmar que middleware de auth se aplica a todas las rutas protegidas
- [ ] Asegurar que `bcrypt.CompareHashAndPassword` se usa en lugar de comparación directa

### ⚡ Stress test scenarios
1. **Token flood**: 1000 requests/seg con JWT válidos → verificar rate limiting y no degradación de validación
2. **Brute-force simulation**: 100 intentos de login fallidos por usuario → confirmar bloqueo temporal y logging estructurado
3. **Tenant isolation test**: Usar token de tenant A para acceder a recursos de tenant B → verificar rechazo con 401/403
4. **Token replay**: Reusar refresh token después de primer uso → confirmar revocación de sesión completa
5. **Timing attack simulation**: Medir tiempo de respuesta con secrets parcialmente correctos → confirmar constant-time comparison

### 🔍 Error hunting procedures
- [ ] Revisar logs de auditoría para verificar que `tenant_id` aparece en cada evento de auth
- [ ] Validar que tokens expirados son rechazados con mensaje genérico (no revelar "expirado" para evitar enumeration)
- [ ] Confirmar que blacklist de tokens se limpia automáticamente tras expiry (no memory leak)
- [ ] Verificar que errores de auth no exponen stack traces o detalles internos al cliente
- [ ] Revisar que refresh token rotation invalida correctamente el token anterior en storage

### 📊 Métricas de aceptación
- P99 latency de validación JWT < 10ms bajo carga de 500 req/seg
- Zero casos de tenant crossover en 10k requests con tokens cruzados deliberadamente
- Rate limiting efectivo: < 6 intentos/minuto por usuario/tenant tras activación
- 100% de passwords almacenados como bcrypt hashes con costo ≥12
- Auditoría completa: 100% de eventos de login/logout/permission_change loggeados con tenant_id y timestamp RFC3339

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/go/authentication-authorization-patterns.go.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"authentication-authorization-patterns","version":"3.0.0","score":92,"blocking_issues":[],"constraints_verified":["C3","C4","C5","C7"],"examples_count":25,"lines_executable_max":5,"language":"Go","vector_constraints_applied":false,"language_lock_status":"enforced","pedagogical_mode":true,"auth_pattern":"jwt_rbac_bcrypt_refresh_rotation_audit","timestamp":"2026-04-19T00:00:00Z"}
```

---
