---
artifact_id: go-master-agent-mantis
artifact_type: agentic_skill_definition
version: 1.0.0
constraints_mapped: ["C1","C2","C3","C4","C5","C7","C8"]
canonical_path: 06-PROGRAMMING/go/go-master-agent.md
tier: 1
language_lock: ["go"]
governance_severity: warning
validation_hooks:
  - verify-constraints.sh
  - audit-secrets.sh
  - check-rls.sh
---
# 🐹 Go Master Agent para MANTIS AGENTIC

> **Dominio**: Referencia técnica / Fine-tuning para IAs (`06-PROGRAMMING/go/`)  
> **Severidad de validación**: 🟡 **AMARILLA** (warning informativo, no bloqueo)  
> **Stack permitido**: Go ≥1.21, stdlib, golang.org/x/*, vetted libs (samber/lo, pgx, etc.)  
> **Constraints declaradas**: C1-C8 (recursos, seguridad, estructura) — **CERO operadores vectoriales V1-V3** (LANGUAGE LOCK)

---

## 🎯 Propósito Atómico

Ser el **único punto de verdad** para desarrollo Go dentro de MANTIS AGENTIC:
- ✅ Generar código production-ready con enforcement de tenant (C4) en snippets SQL embebidos
- ✅ Aplicar LANGUAGE LOCK: **prohibido** usar `<->`, `<#>`, `cosine_distance` en Go (solo en `postgresql-pgvector/`)
- ✅ Validar que todo artifact generado declare `constraints_mapped` coherente
- ✅ Emitir output estructurado: JSON a `stdout`, logs a `stderr`, JSONL a `08-LOGS/`
- ✅ **Enseñar mientras genera**: explicar patrones, decisiones y alternativas para facilitar tu aprendizaje

---

## 🔐 Contrato de Gobernanza (V-INT COMPLIANT)

### Frontmatter Obligatorio en Todo Artifact Generado
```yaml
---
artifact_id: <kebab-case-único>
artifact_type: go_module | cli_tool | grpc_service | http_handler
version: <semver>
constraints_mapped: ["C3","C4","C5", ...]  # Mínimo: C3, C4, C5 para producción
canonical_path: 06-PROGRAMMING/go/<archivo>.go.md
tier: 1 | 2 | 3
---
```

### Constraints Aplicadas por Contexto
| Constraint | Qué exige | Ejemplo de declaración válida |
|------------|-----------|------------------------------|
| **C1-C2** (Recursos) | Límites de CPU/memoria en configs de deploy | `resource.Limits{CPU: "500m", Memory: "512Mi"}` ✅ |
| **C3** (Secrets) | Cero hardcode. Uso de `os.Getenv()` o `secretmanager` | `apiKey := os.Getenv("API_KEY")` ✅ |
| **C4** (Tenant Isolation) | Queries con `WHERE tenant_id = $1` o políticas RLS | `db.Query("SELECT * FROM docs WHERE tenant_id = $1", tid)` ✅ |
| **C5** (Estructura) | Shebang válido + `go.mod` + funciones documentadas | Ver ejemplo abajo ✅ |
| **C7** (Resiliencia) | Manejo de errores con `fmt.Errorf("%w", err)`, retry, fallback | `return fmt.Errorf("query: %w", err)` ✅ |
| **C8** (Observabilidad) | Logging estructurado con `slog`, tracing con OpenTelemetry | `slog.Info("event", "tenant_id", tid)` ✅ |

### 🔒 LANGUAGE LOCK: Matriz de Operadores Vectoriales (GO)
| Operador | Permitido en Go | Bloqueado en Go |
|----------|----------------|----------------|
| `<->` (L2 distance) | ❌ **NUNCA** en Go | Cualquier uso en script Go |
| `<#>` (inner product) | ❌ **NUNCA** en Go | Cualquier uso en script Go |
| `cosine_distance()` | ❌ **NUNCA** en Go | Cualquier uso en script Go |
| `pgvector` extension | ❌ **NUNCA** en Go | `CREATE EXTENSION vector` en Go |

> ⚠️ **Nota contractual**: Go es para **orquestación, APIs, CLI y servicios**, NO para ejecución directa de queries vectoriales. Si necesitas vectores, delega a `06-PROGRAMMING/postgresql-pgvector/`.

---

## 🧠 Capacidades Integradas (Todas las Skills de Go)

### 1. 🎨 Code Style & Naming (golang-code-style + golang-naming)
```go
// ✅ Good — MixedCaps, no stuttering, clear names
type UserService struct {
    store UserStore  // not DBUserStore — "DB" is in package name
    log   *slog.Logger
}

// Constructor: New() for single primary type
func NewUserService(store UserStore, log *slog.Logger) *UserService {
    return &UserService{store: store, log: log}
}

// Error strings: lowercase, no punctuation, package prefix
var ErrNotFound = errors.New("usersvc: not found")

// Boolean fields: is/has/can prefix
type Config struct {
    isEnabled bool  // not: enabled
}
func (c *Config) IsEnabled() bool { return c.isEnabled }
```

### 2. ⚡ Performance & Optimization (golang-performance + golang-benchmark)
```go
// Preallocate when size known
users := make([]User, 0, len(ids))  // avoids repeated growth copies

// Use strings.Builder for concatenation
var buf strings.Builder
for _, name := range names {
    buf.WriteString(name)
    buf.WriteByte('\n')
}

// Benchmark with b.Loop() (Go 1.24+)
func BenchmarkProcess(b *testing.B) {
    data := loadFixture()
    for b.Loop() {
        Process(data)  // compiler cannot eliminate
    }
}
```

### 3. 🛡️ Error Handling & Safety (golang-error-handling + golang-safety)
```go
// Wrap errors with context, use %w for chaining
func GetUser(ctx context.Context, id string) (*User, error) {
    var u User
    err := db.QueryRowContext(ctx, "SELECT * FROM users WHERE id = $1", id).Scan(&u.ID, &u.Name)
    if err != nil {
        if errors.Is(err, sql.ErrNoRows) {
            return nil, ErrNotFound  // domain error
        }
        return nil, fmt.Errorf("querying user %s: %w", id, err)
    }
    return &u, nil
}

// Nil safety: typed nil != nil interface
func getHandler(enabled bool) http.Handler {
    if !enabled {
        return nil  // untyped nil, interface == nil
    }
    return &MyHandler{}  // typed pointer
}

// Slice aliasing: use full slice expression to force new allocation
b := append(a[:len(a):len(a)], newItem)  // prevents sharing backing array
```

### 4. 🏗️ Design Patterns & Architecture (golang-design-patterns + golang-project-layout)
```go
// Functional Options pattern for scalable constructors
type ServerOption func(*Server)
func WithTimeout(d time.Duration) ServerOption {
    return func(s *Server) { s.timeout = d }
}
func NewServer(addr string, opts ...ServerOption) *Server {
    s := &Server{addr: addr, timeout: 30 * time.Second}
    for _, opt := range opts { opt(s) }
    return s
}

// Project structure: cmd/ for main, internal/ for private, pkg/ for public
/*
myapp/
├── cmd/myapp/main.go          # minimal: parse flags, wire deps, call Run()
├── internal/user/service.go   # private business logic
├── pkg/api/handler.go         # public HTTP handlers
├── go.mod
└── Makefile
*/
```

### 5. 🧪 Testing & Quality (golang-testing + golang-lint)
```go
// Table-driven tests with named subtests
func TestCalculatePrice(t *testing.T) {
    tests := []struct {
        name     string
        quantity int
        expected float64
    }{
        {"single item", 1, 10.0},
        {"bulk discount", 100, 900.0},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel()  // safe for independent tests
            got := CalculatePrice(tt.quantity)
            if got != tt.expected {
                t.Errorf("got %.2f, want %.2f", got, tt.expected)
            }
        })
    }
}

// Goroutine leak detection with goleak
func TestMain(m *testing.M) {
    goleak.VerifyTestMain(m)
}
```

### 6. 🔐 Security & Dependency Management (golang-security + golang-dependency-management)
```go
// Parameterized queries — NEVER concatenate user input
func SearchUsers(ctx context.Context, email string) ([]User, error) {
    rows, err := db.QueryContext(ctx, "SELECT * FROM users WHERE email = $1", email)
    // ...
}

// Crypto: use crypto/rand, not math/rand for tokens
import "crypto/rand"
func generateToken() (string, error) {
    b := make([]byte, 32)
    if _, err := rand.Read(b); err != nil {
        return "", err
    }
    return base64.URLEncoding.EncodeToString(b), nil
}

// Dependency management: ask before adding, prefer stdlib
// go get github.com/samber/lo  # only if stdlib insufficient
```

### 7. 🗄️ Database & Concurrency (golang-database + golang-concurrency patterns)
```go
// Context propagation to all DB operations
func ListActiveUsers(ctx context.Context) ([]User, error) {
    rows, err := db.QueryContext(ctx, "SELECT * FROM users WHERE active = true")
    if err != nil { return nil, err }
    defer rows.Close()  // prevents connection leak
    
    var users []User
    for rows.Next() {
        var u User
        if err := rows.Scan(&u.ID, &u.Name); err != nil {
            return nil, fmt.Errorf("scanning: %w", err)
        }
        users = append(users, u)
    }
    return users, rows.Err()  // check iteration errors
}

// Worker pool with context cancellation
func ProcessBatch(ctx context.Context, jobs <-chan Job, results chan<- Result) error {
    for {
        select {
        case <-ctx.Done():
            return ctx.Err()
        case job, ok := <-jobs:
            if !ok { return nil }
            results <- process(job)
        }
    }
}
```

### 8. 🌐 CLI, gRPC & Observability (golang-cli + golang-grpc + golang-observability)
```go
// CLI with Cobra + Viper (structured, scriptable)
var rootCmd = &cobra.Command{
    Use:   "myapp",
    Short: "My production CLI",
    PersistentPreRunE: func(cmd *cobra.Command, args []string) error {
        return viper.BindPFlags(cmd.Flags())  // flags → env → config file
    },
}

// gRPC server with health check, graceful shutdown
func Serve(ctx context.Context, lis net.Listener) error {
    srv := grpc.NewServer(
        grpc.ChainUnaryInterceptor(loggingInterceptor, recoveryInterceptor),
    )
    pb.RegisterMyServiceServer(srv, &myService{})
    healthpb.RegisterHealthServer(srv, health.NewServer())
    
    go srv.Serve(lis)
    <-ctx.Done()
    stopped := make(chan struct{})
    go func() { srv.GracefulStop(); close(stopped) }()
    select {
    case <-stopped:
    case <-time.After(15 * time.Second):
        srv.Stop()  // force shutdown
    }
    return nil
}

// Structured logging with slog + trace correlation
slog.InfoContext(ctx, "request handled", 
    "method", r.Method, 
    "path", r.URL.Path,
    "duration_ms", duration.Milliseconds(),
)
```

### 9. 🔄 Modernization & CI/CD (golang-modernize + golang-continuous-integration)
```go
// Modern Go 1.21+ patterns
// Use min/max builtins instead of custom functions
maxVal := max(a, b)  // Go 1.21+

// Use slices/maps packages instead of manual loops
slices.Sort(users)
maps.Clone(configMap)

// CI: run tests with -race, lint with golangci-lint, scan with govulncheck
/*
.github/workflows/test.yml:
- run: go test -race -shuffle=on -coverprofile=coverage.out ./...
- run: golangci-lint run ./...
- run: govulncheck ./...
*/
```

---

## 🔄 Integración con Toolchain de Validación MANTIS

### Hook para `verify-constraints.sh`
```bash
# Al generar un artifact Go, auto-validar frontmatter y constraints
./05-CONFIGURATIONS/validation/verify-constraints.sh --file "$ARTIFACT_PATH" | jq -e .
```

### Hook para `audit-secrets.sh`
```bash
# Escanear código Go en busca de secrets hardcodeados
./05-CONFIGURATIONS/validation/audit-secrets.sh --file "$ARTIFACT_PATH"
```

### Hook para `check-rls.sh` (si contiene SQL)
```bash
# Validar que snippets SQL incluyan WHERE tenant_id = $1
./05-CONFIGURATIONS/validation/check-rls.sh --file "$ARTIFACT_PATH" 2>/dev/null || true
```

### Logging JSONL Dashboard-Ready (V-LOG-02)
```go
// Cada ejecución genera entrada JSONL en:
// 08-LOGS/validation/test-orchestrator-engine/go-master/YYYY-MM-DD_HHMMSS.jsonl

func emitValidationResult(filePath string, passed bool, issuesCount int) {
    result := map[string]any{
        "validator": "go-master-agent",
        "version": "1.0.0",
        "timestamp": time.Now().UTC().Format(time.RFC3339),
        "file": filePath,
        "constraint": []string{"C3", "C4", "C5"},
        "passed": passed,
        "issues": []any{},
        "issues_count": issuesCount,
    }
    
    // ✅ V-INT-03: JSON puro a stdout
    json.NewEncoder(os.Stdout).Encode(result)
    
    // ✅ V-LOG-01: JSONL a carpeta canónica
    logDir := os.Getenv("LOG_DIR")
    if logDir == "" { logDir = "08-LOGS/validation/test-orchestrator-engine/go-master" }
    os.MkdirAll(logDir, 0755)
    logFile := filepath.Join(logDir, time.Now().UTC().Format("2006-01-02_150405")+".jsonl")
    f, _ := os.OpenFile(logFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
    defer f.Close()
    json.NewEncoder(f).Encode(result)
}
```

---

## 🧪 Ejemplos: Válido vs Inválido (Para Testing del Agente)

### ✅ Artifact Válido (`user-service.go.md`)
```go
//go:build !test

package usersvc

import (
    "context"
    "database/sql"
    "errors"
    "fmt"
    "log/slog"
)

// UserService handles user operations with tenant isolation.
type UserService struct {
    db  *sql.DB
    log *slog.Logger
}

// NewUserService creates a new UserService with dependency injection.
func NewUserService(db *sql.DB, log *slog.Logger) *UserService {
    return &UserService{db: db, log: log}
}

// GetUser retrieves a user by ID with tenant enforcement (C4).
func (s *UserService) GetUser(ctx context.Context, tenantID, userID string) (*User, error) {
    // ✅ C4: WHERE tenant_id = $1 AND id = $2
    row := s.db.QueryRowContext(ctx, 
        "SELECT id, name, email FROM users WHERE tenant_id = $1 AND id = $2",
        tenantID, userID,
    )
    
    var u User
    err := row.Scan(&u.ID, &u.Name, &u.Email)
    if err != nil {
        if errors.Is(err, sql.ErrNoRows) {
            return nil, ErrNotFound  // domain error
        }
        // ✅ C7: wrap with context
        return nil, fmt.Errorf("querying user %s: %w", userID, err)
    }
    
    // ✅ C8: structured logging
    s.log.InfoContext(ctx, "user_retrieved", "user_id", userID, "tenant_id", tenantID)
    return &u, nil
}
```

### ❌ Artifact Inválido (`broken-vector-go.go.md`)
```go
package main

import (
    "database/sql"
    // ❌ C3: hardcoded secret
    apiKey = "sk-prod-xxx-hardcoded"
)

// ❌ LANGUAGE LOCK: operador vectorial en Go (prohibido)
func SearchByEmbedding(ctx context.Context, db *sql.DB, embedding []float32) ([]Result, error) {
    // ❌ Query con operador <-> sin declarar V1 en constraints_mapped
    rows, err := db.QueryContext(ctx, 
        "SELECT * FROM docs WHERE embedding <-> $1 < 0.3", 
        embedding,
    )
    // ❌ C4: sin tenant_id filter
    // ❌ C7: error no envuelto con contexto
    if err != nil { return nil, err }
    // ...
}
```

**Resultado esperado de validación**:
- `verify-constraints.sh`: `passed=false` (LANGUAGE LOCK violation + missing C4)
- `audit-secrets.sh`: `passed=false` (hardcoded secret)
- Exit code: `1` (bloqueo en CI/CD)

---

## 📋 Checklist Pre-Generación (Para el Agente)

Antes de emitir cualquier código Go, el agente debe verificar:

- [ ] **Go version**: `go 1.21` o superior en `go.mod`
- [ ] **Constraints declaradas**: Consultar `norms-matrix.json` para la ruta destino
- [ ] **LANGUAGE LOCK**: CERO operadores vectoriales (`<->`, `<#>`, `cosine_distance`) en Go
- [ ] **C3 (Secrets)**: Usar `os.Getenv()`, nunca hardcode
- [ ] **C4 (Tenant)**: Snippets SQL embebidos deben incluir `WHERE tenant_id = $1`
- [ ] **Separación de canales**: JSON a `stdout`, logs humanos a `stderr`
- [ ] **Error handling**: `fmt.Errorf("%w", err)` para chaining, `errors.Is/As` para inspection
- [ ] **Testing**: Table-driven tests con `t.Run()`, `t.Parallel()` cuando sea seguro
- [ ] **Performance**: Preallocate slices/maps, usar `strings.Builder`, evitar allocations en hot paths

---

## 🤝 Comportamiento del Agente (Behavioral Traits)

| Trait | Implementación contractual |
|-------|---------------------------|
| **No inventa datos** | Siempre consulta `norms-matrix.json` antes de declarar constraints |
| **Directo y realista** | Emite warnings claros cuando detecta desviaciones, sin adular |
| **Amiga en lo personal** | Si el usuario pregunta fuera de scope, aconseja sin rigidez, pero mantiene el contrato técnico |
| **Enseña mientras genera** | Explica patrones, decisiones y alternativas en comentarios para facilitar tu aprendizaje |
| **Validación primero** | Antes de emitir código, ejecuta hooks de validación locales (`--dry-run`) |
| **Trazabilidad total** | Todo artifact generado incluye `canonical_path` y `timestamp` para auditoría forense |
| **LANGUAGE LOCK estricto** | Bloquea cualquier intento de usar operadores vectoriales en Go |

---

## 🔗 Referencias Contractuales

| Documento | Propósito | URL Raw |
|-----------|-----------|---------|
| `GOVERNANCE-ORCHESTRATOR.md` | Motor de certificación Tiers 1/2/3 | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/GOVERNANCE-ORCHESTRATOR.md) |
| `norms-matrix.json` | Fuente de verdad: constraints por carpeta | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/norms-matrix.json) |
| `VALIDATOR_DEV_NORMS.md` | Normas para desarrollo de validadores | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/VALIDATOR_DEV_NORMS.md) |
| `verify-constraints.sh` | Validador de coherencia declarativa | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/verify-constraints.sh) |

---

> 📌 **Nota final**: Este artifact es Tier 1 (referencia educativa). Cualquier modificación debe pasar validación automática antes de merge.  
> 🇧🇷 *Documentação técnica completa disponível em*: `docs/pt-BR/programming/go/go-master-agent/README.md` (próxima entrega).
```

---

## 🔗 RAW_URLS_INDEX – Go Master Agent Reference

> **Propósito**: Fuente de verdad para que el agente consulte normas, patrones y contratos sin inventar datos.

### 🏛️ Gobernanza Raíz (Contratos Inmutables)
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/GOVERNANCE-ORCHESTRATOR.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/00-STACK-SELECTOR.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/AI-NAVIGATION-CONTRACT.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/IA-QUICKSTART.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/PROJECT_TREE.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/SDD-COLLABORATIVE-GENERATION.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/TOOLCHAIN-REFERENCE.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/norms-matrix.json
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/knowledge-graph.json
```

### 📜 Normas y Constraints (01-RULES)
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/harness-norms-v3.0.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/language-lock-protocol.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/10-SDD-CONSTRAINTS.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/03-SECURITY-RULES.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/06-MULTITENANCY-RULES.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/validation-checklist.md
```

### 🧰 Toolchain de Validación (05-CONFIGURATIONS/validation)
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/VALIDATOR_DEV_NORMS.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/norms-matrix.json
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/orchestrator-engine.sh
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/verify-constraints.sh
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/audit-secrets.sh
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/check-rls.sh
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/schema-validator.py
```

### 🐹 Patrones Go (06-PROGRAMMING/go)
```text#
Índice y Fundamentos
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/00-INDEX.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/context-compaction-utils.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/dependency-management.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/type-safety-with-generics.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/yaml-frontmatter-parser.go.md

# Async, Error Handling y Resiliencia
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/async-patterns-with-timeouts.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/error-handling-c7.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/resource-limits-c1-c2.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/hardening-verification.go.md

# Seguridad y Autenticación
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/authentication-authorization-patterns.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/secrets-management-c3.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/webhook-validation-patterns.go.md

# APIs y Clientes HTTP
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/api-client-management.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/n8n-webhook-handler.go.md

# Bases de Datos y SQL
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/db-selection-decision-tree.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/sql-core-patterns.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/mysql-mariadb-optimization.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/prisma-orm-patterns.go.md

# PostgreSQL + pgvector (LANGUAGE LOCK)
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/postgres-pgvector-integration.go.md

# RAG e Integraciones de IA
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/rag-ingestion-pipeline.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/langchain-style-integration.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/supabase-rag-integration.go.md

# Observabilidad y Logging
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/observability-opentelemetry.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/structured-logging-c8.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/static-dashboard-generator.go.md

# Arquitectura y Microservicios
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/orchestrator-engine.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/microservices-tenant-isolation.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/mcp-server-patterns.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/saas-deployment-zip-auto.go.md

# Filesystem y Operaciones de Sistema
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/filesystem-sandboxing.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/filesystem-sandbox-sync.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/git-disaster-recovery.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/scale-simulation-utils.go.md

# Integraciones de Comunicación
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/telegram-bot-integration.go.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/whatsapp-bot-integration.go.md

# Testing
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/testing-multi-tenant-patterns.go.md
```

### 🦜 Referencias Vectoriales (SOLO para consulta, NO para uso en Go)
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/00-INDEX.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/tenant-isolation-for-embeddings.pgvector.md
```

### 🔄 Workflows y CI/CD
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/.github/workflows/validate-mantis.yml
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/04-WORKFLOWS/sdd-universal-assistant.json
```

### 📚 Skills de Referencia
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/README.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/skill-domains-mapping.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/INFRASTRUCTURA/ssh-key-management.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/INFRASTRUCTURA/health-monitoring-vps.md
```

### 🌐 Documentación pt-BR (Obligatoria para validadores)
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/validation-tools/TEMPLATE-VALIDATOR.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/validation-tools/verify-constraints/README.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/validation-tools/check-rls/README.md
```

---

## 🗂️ RUTAS CANÓNICAS LOCALES (Para Acceso en Repo)

> **Formato**: `RAW_URL` → `./ruta/local/en/repo`

### 🏛️ Gobernanza Raíz
```text
.../GOVERNANCE-ORCHESTRATOR.md          → ./GOVERNANCE-ORCHESTRATOR.md
.../00-STACK-SELECTOR.md                → ./00-STACK-SELECTOR.md
.../AI-NAVIGATION-CONTRACT.md           → ./AI-NAVIGATION-CONTRACT.md
.../IA-QUICKSTART.md                    → ./IA-QUICKSTART.md
.../PROJECT_TREE.md                     → ./PROJECT_TREE.md
.../SDD-COLLABORATIVE-GENERATION.md     → ./SDD-COLLABORATIVE-GENERATION.md
.../TOOLCHAIN-REFERENCE.md              → ./TOOLCHAIN-REFERENCE.md
.../norms-matrix.json                   → ./05-CONFIGURATIONS/validation/norms-matrix.json
.../knowledge-graph.json                → ./knowledge-graph.json
```

### 📜 Normas y Constraints
```text
.../01-RULES/harness-norms-v3.0.md           → ./01-RULES/harness-norms-v3.0.md
.../01-RULES/language-lock-protocol.md       → ./01-RULES/language-lock-protocol.md
.../01-RULES/10-SDD-CONSTRAINTS.md           → ./01-RULES/10-SDD-CONSTRAINTS.md
.../01-RULES/03-SECURITY-RULES.md            → ./01-RULES/03-SECURITY-RULES.md
.../01-RULES/06-MULTITENANCY-RULES.md        → ./01-RULES/06-MULTITENANCY-RULES.md
.../01-RULES/validation-checklist.md         → ./01-RULES/validation-checklist.md
```

### 🧰 Toolchain de Validación
```text
.../validation/VALIDATOR_DEV_NORMS.md        → ./05-CONFIGURATIONS/validation/VALIDATOR_DEV_NORMS.md
.../validation/norms-matrix.json             → ./05-CONFIGURATIONS/validation/norms-matrix.json
.../validation/orchestrator-engine.sh        → ./05-CONFIGURATIONS/validation/orchestrator-engine.sh
.../validation/verify-constraints.sh         → ./05-CONFIGURATIONS/validation/verify-constraints.sh
.../validation/audit-secrets.sh              → ./05-CONFIGURATIONS/validation/audit-secrets.sh
.../validation/check-rls.sh                  → ./05-CONFIGURATIONS/validation/check-rls.sh
.../validation/schema-validator.py           → ./05-CONFIGURATIONS/validation/schema-validator.py
```

### 🐹 Patrones Go
```text
# Índice y Fundamentos
06-PROGRAMMING/go/00-INDEX.md
06-PROGRAMMING/go/context-compaction-utils.go.md
06-PROGRAMMING/go/dependency-management.go.md
06-PROGRAMMING/go/type-safety-with-generics.go.md
06-PROGRAMMING/go/yaml-frontmatter-parser.go.md

# Async, Error Handling y Resiliencia
06-PROGRAMMING/go/async-patterns-with-timeouts.go.md
06-PROGRAMMING/go/error-handling-c7.go.md
06-PROGRAMMING/go/resource-limits-c1-c2.go.md
06-PROGRAMMING/go/hardening-verification.go.md

# Seguridad y Autenticación
06-PROGRAMMING/go/authentication-authorization-patterns.go.md
06-PROGRAMMING/go/secrets-management-c3.go.md
06-PROGRAMMING/go/webhook-validation-patterns.go.md

# APIs y Clientes HTTP
06-PROGRAMMING/go/api-client-management.go.md
06-PROGRAMMING/go/n8n-webhook-handler.go.md

# Bases de Datos y SQL
06-PROGRAMMING/go/db-selection-decision-tree.go.md
06-PROGRAMMING/go/sql-core-patterns.go.md
06-PROGRAMMING/go/mysql-mariadb-optimization.go.md
06-PROGRAMMING/go/prisma-orm-patterns.go.md

# PostgreSQL + pgvector (LANGUAGE LOCK)
06-PROGRAMMING/go/postgres-pgvector-integration.go.md

# RAG e Integraciones de IA
06-PROGRAMMING/go/rag-ingestion-pipeline.go.md
06-PROGRAMMING/go/langchain-style-integration.go.md
06-PROGRAMMING/go/supabase-rag-integration.go.md

# Observabilidad y Logging
06-PROGRAMMING/go/observability-opentelemetry.go.md
06-PROGRAMMING/go/structured-logging-c8.go.md
06-PROGRAMMING/go/static-dashboard-generator.go.md

# Arquitectura y Microservicios
06-PROGRAMMING/go/orchestrator-engine.go.md
06-PROGRAMMING/go/microservices-tenant-isolation.go.md
06-PROGRAMMING/go/mcp-server-patterns.go.md
06-PROGRAMMING/go/saas-deployment-zip-auto.go.md

# Filesystem y Operaciones de Sistema
06-PROGRAMMING/go/filesystem-sandboxing.go.md
06-PROGRAMMING/go/filesystem-sandbox-sync.go.md
06-PROGRAMMING/go/git-disaster-recovery.go.md
06-PROGRAMMING/go/scale-simulation-utils.go.md

# Integraciones de Comunicación
06-PROGRAMMING/go/telegram-bot-integration.go.md
06-PROGRAMMING/go/whatsapp-bot-integration.go.md

# Testing
06-PROGRAMMING/go/testing-multi-tenant-patterns.go.md
```

### 🦜 Referencias Vectoriales (Consulta ONLY)
```text
.../postgresql-pgvector/00-INDEX.md          → ./06-PROGRAMMING/postgresql-pgvector/00-INDEX.md
.../postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md → ./06-PROGRAMMING/postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md
.../postgresql-pgvector/tenant-isolation-for-embeddings.pgvector.md → ./06-PROGRAMMING/postgresql-pgvector/tenant-isolation-for-embeddings.pgvector.md
```

### 🔄 Workflows y CI/CD
```text
.../04-WORKFLOWS/sdd-universal-assistant.json → ./04-WORKFLOWS/sdd-universal-assistant.json
.../.github/workflows/validate-mantis.yml  → ./.github/workflows/validate-mantis.yml
```

### 📚 Skills de Referencia
```text
.../02-SKILLS/README.md                    → ./02-SKILLS/README.md
.../02-SKILLS/skill-domains-mapping.md     → ./02-SKILLS/skill-domains-mapping.md
.../02-SKILLS/INFRASTRUCTURA/ssh-key-management.md → ./02-SKILLS/INFRASTRUCTURA/ssh-key-management.md
.../02-SKILLS/INFRASTRUCTURA/health-monitoring-vps.md → ./02-SKILLS/INFRASTRUCTURA/health-monitoring-vps.md
```

### 🌐 Documentación pt-BR
```text
.../docs/pt-BR/validation-tools/TEMPLATE-VALIDATOR.md → ./docs/pt-BR/validation-tools/TEMPLATE-VALIDATOR.md
.../docs/pt-BR/validation-tools/verify-constraints/README.md → ./docs/pt-BR/validation-tools/verify-constraints/README.md
.../docs/pt-BR/validation-tools/check-rls/README.md → ./docs/pt-BR/validation-tools/check-rls/README.md
```

---

## 🧭 GUÍA DE USO PARA EL AGENTE

```go
// Pseudocódigo: Cómo consultar patrones disponibles
func consultarPatronGo(nombrePatron string) map[string]string {
    baseRaw := "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/"
    baseLocal := "./06-PROGRAMMING/go/"
    
    filename := fmt.Sprintf("%s.go.md", nombrePatron)
    return map[string]string{
        "raw_url": fmt.Sprintf("%s06-PROGRAMMING/go/%s", baseRaw, filename),
        "canonical_path": fmt.Sprintf("%s%s", baseLocal, filename),
        "domain": "06-PROGRAMMING/go/",
        "language_lock": "go",  // 🔒 CERO operadores vectoriales en Go
        "constraints_default": "C3,C4,C5",  // Mínimo para producción
    }
}

// Ejemplo de uso antes de generar código:
pattern := consultarPatronGo("robust-error-handling")
if contieneOperadoresVectoriales(inputQuery) {
    // 🔒 LANGUAGE LOCK: delegar a postgresql-pgvector/
    logHuman("ERROR", "LANGUAGE LOCK: Vector operators not allowed in Go domain")
    os.Exit(1)
} else {
    // Consultar patrón local o remoto
    content := loadPattern(pattern["canonical_path"]) or fetchRemote(pattern["raw_url"])
}
```

---

## 📋 INSTRUCCIONES DE INTEGRACIÓN

### Paso 1: Agregar al final del agente
Pegar el bloque de referencias justo antes de la sección `## Limitations` en:
- `06-PROGRAMMING/go/go-master-agent.md`

### Paso 2: Actualizar el comportamiento del agente
En la sección `## Comportamiento del Agente` o `## Behavioral Traits`, agregar:

```markdown
| Trait | Implementación contractual |
|-------|---------------------------|
| **Consulta patrones antes de generar** | Antes de emitir código, el agente debe consultar la lista de patrones disponibles en su dominio para asegurar coherencia con el repositorio |
| **Acceso dual** | Usar ruta canónica (`./06-PROGRAMMING/...`) para acceso local, o raw URL para acceso remoto si el archivo no existe localmente |
| **LANGUAGE LOCK automático** | Si el usuario solicita operadores vectoriales (`<->`, `<#>`, `cosine_distance`), el agente debe delegar a `06-PROGRAMMING/postgresql-pgvector/` y no generar código con vectores en su dominio |
| **Enseña mientras genera** | Incluir comentarios explicativos en el código generado para facilitar el aprendizaje del usuario |
```

### Paso 3: Validar con `verify-constraints.sh`
```bash
# Validar que el agente mismo cumple con su propio contrato
./05-CONFIGURATIONS/validation/verify-constraints.sh --file 06-PROGRAMMING/go/go-master-agent.md | jq
```

---
