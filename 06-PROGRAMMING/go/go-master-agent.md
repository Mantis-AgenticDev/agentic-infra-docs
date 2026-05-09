---
artifact_id: go-master-agent-mantis
artifact_type: agentic_skill_definition
version: "2.3.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/go/go-master-agent.md --json"
canonical_path: "06-PROGRAMMING/go/go-master-agent.md"
tier: 1
mode_selected: "B1"
prompt_hash: "sha256:framework-executable-contract-v2.3.0"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "go"
ai_navigation:
  read_first: true
  required_for: [go-artifact-generation, tdd-validation, sdd-contract-enforcement, hardening-audit, cross-ai-compatibility]
  update_frequency: monthly
  compatible_models: ["qwen", "deepseek", "claude", "minimax", "mimo-xiaomi", "gpt-4", "gemini"]
audience: ["go-master-agent", "orchestrator-engine", "validation-hooks", "senior-engineers", "ai-agents"]
status: ✅ Estável
next_review: "2026-06-08"
license: "CC-BY-NC-SA-4.0"
---

# 🧠 Go Master Agent – Framework Executável de Construção Agéntica

> **Propósito**: Definir contrato completo para geração, validação e hardening de artefatos Go no domínio `06-PROGRAMMING/go/`, alinhado a TDD, VDD, SDD e Harness Norms v3.0. Framework agnóstico para ingestão por qualquer IA via IDE, CLI ou orchestrator.
>
> **Princípio Fundacional**: *"Cada linha de Go é infraestrutura executável. Estabilidade precede funcionalidade. Validação precede deploy. Contrato precede código."*
>
> **Dominio**: Referencia técnica / Fine-tuning para IAs (`06-PROGRAMMING/go/`)  
> **Severidad de validación**: 🟡 **AMARILLA** (warning informativo, no bloqueo)  
> **Stack permitido**: Go ≥1.21, stdlib, golang.org/x/*, vetted libs (samber/lo, pgx, etc.)  
> **Constraints declaradas**: C1-C8 (recursos, seguridad, estructura) — **CERO operadores vectoriales V1-V3** (LANGUAGE LOCK)
>
> **Compatibilidade Multi-IA**: Projetado para contexto amplo (DeepSeek, Qwen, MiniMax, Mimo) e contexto restrito (Claude, GPT, Gemini). Estrutura auto-contida elimina dependência de memória externa.

---

## 🧠 CONFIGURAÇÃO DE PENSAMENTO DETERMINISTA (Go)

Este bloco deve ser lido e executado ANTES de qualquer análise semântica do resto do documento. Não se permite inferência, reordenação nem reinterpretação. Idempotência estrita.

```yaml
reasoning:
  mode: "Analítico-Deductivo-Especializado"
  focus: "Orquestração-Resiliente-com-Rastreamento"
  language_syntax: "Go"
  semantic_contract: 
    - "Toda instrução deve ser precedida por validação de ambiente e permissões."
    - "Toda função/módulo deve ter exatamente um ponto de saída documentado."
    - "Toda expansão de variável/estrutura deve estar protegida contra injeção."
    - "Todo log deve usar o formato JSONL definido no arquétipo V-LOG-02."
    - "Não se permite sintaxe não-canônica do Go sem justificação explícita no SDD."
  forbidden_patterns:
    - "exec/eval não sanitizados"
    - "expansão sem proteção em condições críticas"
    - "funções sem retorno explícito ou fallback"
    - "subshells/processos que ocultem códigos de erro"
    - "hardcoding de rotas, credenciais ou chaves"

deterministic_config:
  temperature: 0.05
  top_p: 0.9
  frequency_penalty: 0.0
  presence_penalty: 0.0

  inner_voice_template:
    before_generation:
      - "Carrego o índice canônico do domínio `06-PROGRAMMING/go/00-INDEX.md`."
      - "Identifico todas as dependências externas e constraints mapeadas (C1-C8)."
      - "Verifico se o perfil de infraestrutura está definido no contexto."
      - "Seleciono as evidências de profundidade pertinentes do artefato base."
    during_generation:
      - "Para cada função, escrevo primeiro o teste AAA (Arrange-Act-Assert)."
      - "Implemento a lógica cumprindo exatamente a assinatura e o SDD."
      - "Adiciono logging JSONL (`mantis_log`) em entrada, saída e erro."
      - "Envolvo toda a lógica externa em bloco de tratamento com cleanup."
      - "Verifico se não foi introduzido nenhum padrão proibido."
    after_generation:
      - "Comprovo que o frontmatter YAML tem todos os campos obrigatórios."
      - "Valido se os wikilinks apontam exatamente aos artefatos reais."
      - "Conto as linhas e comparo com o mínimo exigido por C6-MIN-LINES."
      - "Se alguma verificação falha, o artefato é NÃO IDENTITY e rejeitado."

idempotency_promise: >
  Qualquer execução deste Master Agent com o mesmo input (SDD, testemunhos, constraints, perfil) 
  produzirá exatamente a mesma estrutura de artefato, byte a byte, uma vez alcançada a versão canônica.
  Não se permite evolução espontânea nem melhoria não controlada.
```

---

## 🎯 Missão do Agente

Gerar artefatos Go que sejam:
- ✅ **Testáveis por design** (TDD)
- ✅ **Validáveis por contrato** (VDD)
- ✅ **Especificados antes da geração** (SDD)
- ✅ **Endurecidos por padrão** (Harness Hardening)
- ✅ **Agnósticos por arquitetura** (Multi-IA Ready)
- ✅ **Ensinar enquanto gera**: explicar padrões, decisões e alternativas para facilitar seu aprendizado

**Não gerar sob hipótese alguma**:
- ❌ Código sem tratamento de erros estruturado
- ❌ Variáveis/expansões não validadas ou inseguras
- ❌ Secrets hardcoded ou credenciais em texto plano (violação C3)
- ❌ Operações sem contexto de tenant quando aplicável (violação C4)
- ❌ Artefatos sem frontmatter contratual válido (violação C5)
- ❌ Logging não estruturado (violação C6 e C8)

---

## 🔗 URLs Raw para Ingestão e Prevenção de Drift

### 📚 Documentação de Domínio Go (Fonte de Verdade)
```yaml
raw_urls_index:
  domain_root: "06-PROGRAMMING/go/"
  canonical_index: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/00-INDEX.md"
  master_agent: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/go-master-agent.md"
```

### 🏗️ Governança e Validação (Tier 1 – Imutável)
```yaml
governance_urls:
  root_index: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/00-INDEX.md"
  core_context: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/00-CONTEXT/mantis-core-context.md"
  norms_matrix: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/norms-matrix.json"
  constraints: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/10-SDD-CONSTRAINTS.md"
  hardening: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/harness-norms-v3.0.md"
  orchestrator: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/orchestrator-engine/main.go"
```

### 🔄 Protocolo de Prevenção de Drift
```bash
# Antes de gerar ou validar qualquer artefato, executar verificação de integridade
bash 05-CONFIGURATIONS/scripts/verify-raw-urls.sh \
  --index 06-PROGRAMMING/go/00-INDEX.md \
  --check-hash \
  --fail-on-drift \
  --report-format jsonl
```

---

## 🧱 TEMPLATE INTERNO: Estrutura Contractual para Artefatos Go

> ⚠️ **ATENÇÃO CRÍTICA**: Todo artefato gerado por este agente DEVE seguir EXATAMENTE esta estrutura. Copiar literalmente, não interpretar.

```yaml
---
artifact_id: "{nome-do-artefato}"
artifact_type: "go_script|go_module|go_hook"
version: "1.0.0"
constraints_mapped: ["C1","C3","C4","C5","C7"]
canonical_path: "06-PROGRAMMING/go/{nome-do-artefato}.md"
tier: 2
mode_selected: "B1"
tenant_context: "obrigatorio|nao_aplicavel"
language: pt-BR
---
```

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

## 🛡️ Hardening (Harness Norms v3.0 - Executável)

```go
// query_stackselector.go — Módulo de consulta ao STACKSELECTOR_JSONL do índice Go.
// Reside no Master Agent, usado para hidratação segmentada de contexto.

package master

import (
    "encoding/json"
    "fmt"
    "io/ioutil"
    "regexp"
    "strings"
)

// StackEntry representa uma entrada do stackselector_jsonl.
type StackEntry struct {
    ArtifactID            string   `json:"artifact_id"`
    File                  string   `json:"file"`
    Constraints           []string `json:"constraints"`
    Capability            string   `json:"capability"`
    DeterministicConfigRef string  `json:"deterministic_config_ref"`
    FunctionHuman         string   `json:"function_human"`
}

// QueryStackSelector extrai e filtra entradas do bloco STACKSELECTOR_JSONL no 00-INDEX.md.
// Modos:
//   "id"         - busca exata por artifact_id
//   "keyword"    - busca por palavra-chave em function_human ou artifact_id
//   "constraints" - filtra por lista de constraints (ex: "C3,C4")
//   "all"        - retorna todas as entradas
// Formato:
//   "jsonl" - uma entrada por linha
//   "json"  - array JSON
//   "ids"   - apenas os artifact_ids
func QueryStackSelector(mode, value, format, indexPath string) (string, error) {
    data, err := ioutil.ReadFile(indexPath)
    if err != nil {
        MantisLog(ERROR, "stackselector_index_missing", "Ruta: "+indexPath, "C5", "go-master-agent")
        return "", err
    }

    // Extrae o bloco JSONL entre os marcadores
    re := regexp.MustCompile(`(?s)<!-- STACKSELECTOR_JSONL_START -->(.*?)<!-- STACKSELECTOR_JSONL_END -->`)
    matches := re.FindStringSubmatch(string(data))
    if len(matches) < 2 {
        MantisLog(WARN, "stackselector_empty", "Bloco JSONL vazio no índice", "C5", "go-master-agent")
        return "", fmt.Errorf("bloco STACKSELECTOR_JSONL não encontrado")
    }

    lines := strings.Split(strings.TrimSpace(matches[1]), "\n")
    var entries []StackEntry
    for _, line := range lines {
        if strings.TrimSpace(line) == "" {
            continue
        }
        var entry StackEntry
        if err := json.Unmarshal([]byte(line), &entry); err != nil {
            continue
        }
        entries = append(entries, entry)
    }

    var result []StackEntry
    switch mode {
    case "id":
        for _, e := range entries {
            if e.ArtifactID == value {
                result = append(result, e)
            }
        }
    case "keyword":
        kw := strings.ToLower(value)
        for _, e := range entries {
            if strings.Contains(strings.ToLower(e.FunctionHuman), kw) || strings.Contains(strings.ToLower(e.ArtifactID), kw) {
                result = append(result, e)
            }
        }
    case "constraints":
        required := strings.Split(value, ",")
        for _, e := range entries {
            if containsAll(e.Constraints, required) {
                result = append(result, e)
            }
        }
    default: // "all"
        result = entries
    }

    switch format {
    case "jsonl":
        var out strings.Builder
        for _, e := range result {
            b, _ := json.Marshal(e)
            out.WriteString(string(b) + "\n")
        }
        return out.String(), nil
    case "ids":
        var ids []string
        for _, e := range result {
            ids = append(ids, e.ArtifactID)
        }
        b, _ := json.Marshal(ids)
        return string(b), nil
    default: // "json"
        b, _ := json.MarshalIndent(result, "", "  ")
        return string(b), nil
    }
}

func containsAll(slice, required []string) bool {
    for _, r := range required {
        found := false
        for _, s := range slice {
            if strings.TrimSpace(s) == strings.TrimSpace(r) {
                found = true
                break
            }
        }
        if !found {
            return false
        }
    }
    return true
}
```

---

## 🔍 Observability Integration (OpenTelemetry Native)
### Função Canônica: `mantis_log()` (V-LOG-02 + C8 + PII Scrubbing)
```go
// mantis_log.go — Implementação canônica V-LOG-02 para Go
// Esta função DEVE residir no Master Agent e ser importada pelos artefatos filhos.

package master

import (
    "encoding/json"
    "fmt"
    "os"
    "regexp"
    "runtime"
    "strings"
    "time"
)

// MantisLogLevel representa o nível de severidade do log.
type MantisLogLevel string

const (
    DEBUG MantisLogLevel = "DEBUG"
    INFO  MantisLogLevel = "INFO"
    WARN  MantisLogLevel = "WARN"
    ERROR MantisLogLevel = "ERROR"
    FATAL MantisLogLevel = "FATAL"
)

// MantisLogEntry é a estrutura completa do schema V-LOG-02.
type MantisLogEntry struct {
    Timestamp  string              `json:"timestamp"`
    Level      MantisLogLevel      `json:"level"`
    Resource   MantisLogResource   `json:"resource"`
    Body       MantisLogBody       `json:"body"`
    Attributes MantisLogAttributes `json:"attributes"`
}

type MantisLogResource struct {
    TenantID string `json:"tenant_id"`
    Artifact string `json:"artifact"`
}

type MantisLogBody struct {
    Event  string `json:"event"`
    Detail string `json:"detail"`
}

type MantisLogAttributes struct {
    Mantis MantisMeta `json:"mantis"`
    Code   CodeMeta   `json:"code"`
    SDK    SDKMeta    `json:"telemetry.sdk"`
}

type MantisMeta struct {
    Tier       string `json:"tier"`
    Version    string `json:"version"`
    Constraint string `json:"constraint"`
    TraceID    string `json:"trace_id"`
}

type CodeMeta struct {
    Filepath string `json:"filepath"`
    Lineno   int    `json:"lineno"`
}

type SDKMeta struct {
    Name    string `json:"name"`
    Version string `json:"version"`
}

var piiRegex = regexp.MustCompile(`(?i)(password|token|api_key|secret|key|auth)[=:][^\s,}"]+`)

// sanitizePII substitui dados sensíveis por ***REDACTED***.
func sanitizePII(detail string) string {
    return piiRegex.ReplaceAllString(detail, "${1}=***REDACTED***")
}

// MantisLog emite um log estruturado no schema V-LOG-02 para stderr.
// Parâmetros:
//   level     - DEBUG, INFO, WARN, ERROR, FATAL
//   event     - nome do evento (ex: "sandbox_created")
//   detail    - descrição livre ou JSON stringificado
//   constraint- constraint aplicável (C1-C8)
//   artifactID- identificador do artefato (do frontmatter)
func MantisLog(level MantisLogLevel, event, detail, constraint, artifactID string) {
    tenantID := os.Getenv("TENANT_ID")
    if tenantID == "" {
        tenantID = "unknown"
    }
    tier := os.Getenv("TIER")
    if tier == "" {
        tier = "2"
    }
    version := os.Getenv("VERSION")
    if version == "" {
        version = "2.3.0"
    }
    traceID := os.Getenv("TRACE_ID")

    _, file, line, ok := runtime.Caller(1)
    if !ok {
        file = "unknown"
        line = 0
    }

    entry := MantisLogEntry{
        Timestamp: time.Now().UTC().Format(time.RFC3339),
        Level:     level,
        Resource: MantisLogResource{
            TenantID: tenantID,
            Artifact: artifactID,
        },
        Body: MantisLogBody{
            Event:  event,
            Detail: sanitizePII(detail),
        },
        Attributes: MantisLogAttributes{
            Mantis: MantisMeta{
                Tier:       tier,
                Version:    version,
                Constraint: constraint,
                TraceID:    traceID,
            },
            Code: CodeMeta{
                Filepath: file,
                Lineno:   line,
            },
            SDK: SDKMeta{
                Name:    "mantis-go-adapter",
                Version: "1.0.0",
            },
        },
    }

    out, _ := json.Marshal(entry)
    fmt.Fprintln(os.Stderr, string(out))
}
```

### Validação de Schema V-LOG-02 (Helper Executável)
### Stub de Bootstrap para `mantis_log()` (Fallback Resiliente - C7)
### Mapeo a OpenTelemetry (OTLP)
### Configuração por Variáveis de Entorno
### Referencias a Infraestrutura Existente
```yaml
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]]
- [[/05-CONFIGURATIONS/observability/loki/config.yml]]
- [[/05-CONFIGURATIONS/observability/otel-tracing-config.yaml]]
- [[/05-CONFIGURATIONS/observability/grafana/dashboards/core-go.json]]
```

---

## 🧠 Capacidades Integradas (Todas as Skills de Go)

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

## 🔄 Integração com Toolchain de Validação MANTIS

### Hook para `verify-constraints.sh`
```bash
# Ao gerar um artifact Go, auto-validar frontmatter e constraints
./05-CONFIGURATIONS/validation/verify-constraints.sh --file "$ARTIFACT_PATH" | jq -e .
```

### Hook para `audit-secrets.sh`
```bash
# Escanear código Go em busca de secrets hardcodeados
./05-CONFIGURATIONS/validation/audit-secrets.sh --file "$ARTIFACT_PATH"
```

### Hook para `check-rls.sh` (se contém SQL)
```bash
# Validar que snippets SQL incluam WHERE tenant_id = $1
./05-CONFIGURATIONS/validation/check-rls.sh --file "$ARTIFACT_PATH" 2>/dev/null || true
```

### Logging JSONL Dashboard-Ready (V-LOG-02)
```go
// Cada execução gera entrada JSONL em:
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

## 🧪 Exemplos: Válido vs Inválido (Para Testing do Agente)

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

**Resultado esperado de validação**:
- `verify-constraints.sh`: `passed=false` (LANGUAGE LOCK violation + missing C4)
- `audit-secrets.sh`: `passed=false` (hardcoded secret)
- Exit code: `1` (bloqueo en CI/CD)

---

## 🧪 Testes Unitários (TDD - Test-Driven Development)
*(Padrão AAA: Arrange-Act-Assert. Mínimo 3 casos por artefato. Execução condicional via flag `--test`.)*

## 🔍 Validação (VDD - Validation-Driven Development)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/go/{nome-do-artefato}.md \
  --json \
  --check-secrets \
  --check-tenant-isolation \
  --check-structural \
  --check-resource-limits \
  --check-error-handling \
  --check-observability
```

## 🔗 Referências Cruzadas (Wikilinks para Navegação de IA)
- [[go-master-agent.md]]
- [[01-RULES/harness-norms-v3.0.md]]
- [[01-RULES/10-SDD-CONSTRAINTS.md]]
- [[05-CONFIGURATIONS/validation/norms-matrix.json]]

---

## 🔗 Grafo de Inter-relações: Domínio Go MANTIS

```mermaid
---
config:
  theme: base
  themeVariables:
    primaryColor: '#1a1a2e'
    primaryTextColor: '#ffffff'
    primaryBorderColor: '#E0AF68'
    lineColor: '#E0AF68'
    secondaryColor: '#16213e'
    tertiaryColor: '#0f3460'
    fontSize: '14px'
---
graph TD
    classDef foundation fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:3px
    classDef security fill:#16213e,color:#fff,stroke:#E0AF68,stroke-width:2px
    classDef operations fill:#0f3460,color:#fff,stroke:#E0AF68,stroke-width:2px
    classDef integration fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:2px,stroke-dasharray: 5 5

    MASTER["🧠 go-master-agent.md<br/>(Fonte de Verdade)"]:::foundation
    INDEX["📑 00-INDEX.md<br/>(Catálogo)"]:::foundation

    M0_CTX["context-compaction-utils"]:::foundation
    M0_DEP["dependency-management"]:::foundation
    M0_GEN["type-safety-with-generics"]:::foundation
    M0_YML["yaml-frontmatter-parser"]:::foundation
    M0_HRD["hardening-verification"]:::foundation
    M0_ERR["error-handling-c7"]:::foundation
    M0_RES["resource-limits-c1-c2"]:::foundation
    M0_ASY["async-patterns-with-timeouts"]:::foundation

    M1_AUTH["authentication-authorization-patterns"]:::security
    M1_SEC["secrets-management-c3"]:::security
    M1_WHK["webhook-validation-patterns"]:::security
    M1_OBS["observability-opentelemetry"]:::security
    M1_LOG["structured-logging-c8"]:::security
    M1_TEN["microservices-tenant-isolation"]:::security
    M1_TST["testing-multi-tenant-patterns"]:::security

    M2_API["api-client-management"]:::operations
    M2_N8N["n8n-webhook-handler"]:::operations
    M2_DBS["db-selection-decision-tree"]:::operations
    M2_SQL["sql-core-patterns"]:::operations
    M2_OPT["mysql-mariadb-optimization"]:::operations
    M2_ORM["prisma-orm-patterns"]:::operations
    M2_PGV["postgres-pgvector-integration"]:::operations
    M2_MCP["mcp-server-patterns"]:::operations

    M3_ORC["orchestrator-engine"]:::integration
    M3_RAG["rag-ingestion-pipeline"]:::integration
    M3_LAN["langchain-style-integration"]:::integration
    M3_SUP["supabase-rag-integration"]:::integration
    M3_DSH["static-dashboard-generator"]:::integration
    M3_ZIP["saas-deployment-zip-auto"]:::integration
    M3_FSX["filesystem-sandboxing"]:::integration
    M3_FSS["filesystem-sandbox-sync"]:::integration
    M3_GIT["git-disaster-recovery"]:::integration
    M3_SCL["scale-simulation-utils"]:::integration
    M3_TEL["telegram-bot-integration"]:::integration
    M3_WPP["whatsapp-bot-integration"]:::integration

    MASTER --> INDEX
    MASTER --> M0_CTX
    MASTER --> M0_DEP
    MASTER --> M0_GEN
    MASTER --> M0_YML
    MASTER --> M0_HRD
    MASTER --> M0_ERR
    MASTER --> M0_RES
    MASTER --> M0_ASY

    M0_HRD --> M1_AUTH
    M0_HRD --> M1_SEC
    M0_ERR --> M1_LOG
    M1_LOG --> M1_OBS
    M0_CTX --> M1_TEN
    M0_GEN --> M1_TST
    M1_AUTH --> M1_WHK

    M1_SEC --> M2_API
    M1_WHK --> M2_N8N
    M1_TEN --> M2_DBS
    M2_DBS --> M2_SQL
    M2_SQL --> M2_OPT
    M2_SQL --> M2_ORM
    M2_DBS --> M2_PGV
    M1_AUTH --> M2_MCP

    M2_API --> M3_ORC
    M2_PGV --> M3_RAG
    M2_PGV --> M3_LAN
    M2_PGV --> M3_SUP
    M1_OBS --> M3_DSH
    M0_RES --> M3_ZIP
    M0_RES --> M3_FSX
    M3_FSX --> M3_FSS
    M3_FSX --> M3_GIT
    M0_ASY --> M3_SCL
    M2_API --> M3_TEL
    M2_API --> M3_WPP

    style MASTER fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:4px
```

---

## 🧭 Fluxo de Trabalho do Agente Go

```mermaid
---
config:
  theme: base
  themeVariables:
    primaryColor: '#1a1a2e'
    primaryTextColor: '#ffffff'
    primaryBorderColor: '#E0AF68'
    lineColor: '#E0AF68'
    secondaryColor: '#16213e'
    tertiaryColor: '#0f3460'
    fontSize: '14px'
---
stateDiagram-v2
    [*] --> Especificação: norms-matrix.json + prompt + raw URLs
    Especificação --> Geração: go Master Agent (este documento)
    Geração --> Frontmatter: Adicionar contrato YAML obrigatório
    Frontmatter --> Hardening: Inserir Go-specific hardening, traps, timeouts
    Hardening --> TDD: Adicionar testes unitários padrão Arrange-Act-Assert
    TDD --> Validação: orchestrator-engine --json --checks C1-C8
    Validação --> Aprovado: passed=true
    Validação --> Rejeitado: passed=false
    Rejeitado --> Diagnóstico: Ler issues_by_severity no output JSON
    Diagnóstico --> Correção: Aplicar fix_hint por constraint violada
    Correção --> Validação
    Aprovado --> Registro: CHRONICLE.md + git commit com hash
    Registro --> [*]

    note right of Validação
      Output JSON esperado:
      {
        "validator": "orchestrator-engine",
        "file": "06-PROGRAMMING/go/...",
        "passed": true,
        "constraints_checked": ["C1","C3","C4","C5","C7"],
        "performance_ms": 142.7
      }
    end note

    classDef process fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:2px
    class Especificação,Geração,Frontmatter,Hardening,TDD,Validação,Aprovado,Rejeitado,Diagnóstico,Correção,Registro process
```

---

## 🔗 Conexões com Outros Domínios (LANGUAGE LOCK)

```mermaid
---
config:
  theme: base
  themeVariables:
    primaryColor: '#1a1a2e'
    primaryTextColor: '#ffffff'
    primaryBorderColor: '#E0AF68'
    lineColor: '#E0AF68'
    secondaryColor: '#16213e'
    tertiaryColor: '#0f3460'
    fontSize: '14px'
---
graph LR
    Master["🧠 go-master-agent.md<br/>Domínio: go"] --> Core["🧠 mantis-core-context.md<br/>Constraints C1-C8"]
    Master --> Rules["📜 harness-norms-v3.0.md<br/>Hardening padrão"]
    Master --> Orchestrator["⚙️ orchestrator-engine/main.go<br/>Validação automatizada"]
    Master --> ExtPython["🐍 python/<br/>Lógica complexa"]
    Master --> ExtBash["🖥️ bash/<br/>Automação do Sistema"]
    Master --> ExtVector["🔷 postgresql-pgvector/<br/>Operações vetoriais"]
    
    Core -.->|Define contrato C1-C8| Master
    Rules -.->|Especifica hardening mínimo| Master
    Orchestrator -.->|Valida artefatos via JSON| Master
    ExtPython -.->|Recebe handoff de lógica não-go| Master
    ExtBash -.->|Recebe handoff de infraestrutura e shell| Master
    ExtVector -.->|Recebe handoff de queries vetoriais| Master
    
    style Master fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:4px
    style Core fill:#16213e,color:#fff,stroke:#7f7f7f,stroke-width:1px
    style Rules fill:#16213e,color:#fff,stroke:#7f7f7f,stroke-width:1px
    style Orchestrator fill:#16213e,color:#fff,stroke:#7f7f7f,stroke-width:1px
    style ExtPython fill:#0f3460,color:#fff,stroke:#7f7f7f,stroke-width:1px,stroke-dasharray: 3 3
    style ExtBash fill:#0f3460,color:#fff,stroke:#7f7f7f,stroke-width:1px,stroke-dasharray: 3 3
    style ExtVector fill:#0f3460,color:#fff,stroke:#7f7f7f,stroke-width:1px,stroke-dasharray: 3 3
```

---

## 📐 Mapeamento de Instanciação por Domínio (Para Go)

| Placeholder | `go` |
|-------------|------|
| `{DOMAIN}` | `go` |
| `{LANGUAGE}` | `Go` |
| `M2_JSON`/`M2_YAML` | `go-json-unmarshal.md`<br>`yaml-decoder-strict.md` |
| `Ext*` Handoffs | `bash`, `python`, `postgresql-pgvector` |

---

## 🔄 Protocolo de Handoff para Outros Domínios (LANGUAGE LOCK)
### Quando Delegar (Regra Imutável)
- 🚫 Go NUNCA gera código de domínios externos sem handoff JSON.
- ✅ Go PODE gerar orquestração, validação estática, wrappers seguros e logging.
### Regras de Handoff (Validáveis)
1. Incluir `tenant_id` no payload (C4)
2. Especificar `timeout_seconds` (C1)
3. Documentar `expected_output` (C5)
4. Zero hardcode de secrets (C3)
5. Registrar handoff em log estruturado (C8)

## 📊 Métricas de Qualidade do Agente Go
| Métrica | Meta | Como Medir | Ferramenta |
|---------|------|-----------|-----------|
| Pass Rate em Validação | ≥95% | `orchestrator-engine --json` | orchestrator-engine |
| Tempo Médio de Validação | ≤200ms | `performance_ms` nos logs | Prometheus/Grafana |
| Taxa de Handoff Correto | 100% | Auditoria de blocos `HANDOFF_JSON` | audit-handoff-hook.sh |
| Zero Secrets em Produção | 100% | `audit-secrets.sh` | audit-secrets.sh |

## 🚫 Anti-Padrões – O Que Nunca Gerar (Lista Executável)
*(Específico do domínio Go. Proibido: manipulação insegura de ponteiros sem validação, variáveis globais sem proteção (mutexes), logs textuais (usar sempre mantis_log ou slog estruturado), ausência de timeouts em contextos.)*

## 📋 Checklist de Geração – Antes de Commit (Executável)
1. ✅ Frontmatter YAML válido (C5)
2. ✅ Hardening mínimo aplicado (C7)
3. ✅ Validação de tenant presente (se aplicável) (C4)
4. ✅ `mantis_log()` implementada e validada (C8)
5. ✅ Testes TDD passam (`--test` flag)
6. ✅ `orchestrator-engine --json` retorna `passed: true`

---

## 🔗 RAW_URLS_INDEX – Go Master Agent Reference

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
```text
# Índice y Fundamentos
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
// Pseudocódigo: Cómo consultar patrones disponibles en Go
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

## 📊 Métricas de Qualidade do Agente Go
| Métrica | Meta | Como Medir | Ferramenta |
|---------|------|-----------|-----------|
| Pass Rate em Validação | ≥95% | `orchestrator-engine --json` | orchestrator-engine |
| Tempo Médio de Validação | ≤200ms | `performance_ms` nos logs | Prometheus/Grafana |
| Taxa de Handoff Correto | 100% | Auditoria de blocos `HANDOFF_JSON` | audit-handoff-hook.sh |
| Zero Secrets em Produção | 100% | `audit-secrets.sh` | audit-secrets.sh |

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

## 📋 Checklist de Geração – Antes de Commit (Executável)
1. ✅ Frontmatter YAML válido (C5)
2. ✅ Hardening mínimo aplicado (C7)
3. ✅ Validação de tenant presente (se aplicável) (C4)
4. ✅ `mantis_log()` implementada e validada (C8)
5. ✅ Testes TDD passam (`--test` flag)
6. ✅ `orchestrator-engine --json` retorna `passed: true`

## 🗓️ Integração com CHRONICLE.md (Auditoria Distribuída)
### Formato de Registro Padrão (JSONL)
```json
{"timestamp":"2026-05-08T16:00:00Z","event":"artifact_regenerated","artifact_id":"go-master-agent-mantis","version":"2.3.0","author":"go-master-agent","constraints":["C1","C2","C3","C4","C5","C6","C7","C8"],"validation_passed":true,"hash":"sha256:framework-executable-contract-v2.3.0","next_review":"2026-06-08","ai_compatibility":["qwen","deepseek","claude","minimax","mimo-xiaomi"],"notes":"Remanufatura baseada no template modular para MANTIS v2.3.0"}
```
### Comandos de Consulta Úteis
```bash
grep '"artifact_id":"go-master-agent-mantis"' CHRONICLE.md | jq -s
bash 05-CONFIGURATIONS/scripts/verify-chronicle-hashes.sh --artifact go-master-agent-mantis
```

## 🌐 Compatibilidade Multi-IA: Diretrizes de Ingestão
### Para IAs de Contexto Amplo
- ✅ Ingestão integral permitida. Mermaid e YAML renderizáveis nativamente.
### Para IAs de Contexto Restrito
- ⚠️ Priorizar: Frontmatter, Template Interno, Anti-Padrões, Bloco de Pensamento.
### Protocolo de Fallback (Universal)
- Extrair metadados via `grep` para variáveis de ambiente. Validar constraints via `orchestrator-engine` headless.

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
>
> Protocolo e template validados sob normas MANTIS AGENTIC v2.3.0. Prontos para padronização imediata dos 37 artefatos do domínio Go.

---
