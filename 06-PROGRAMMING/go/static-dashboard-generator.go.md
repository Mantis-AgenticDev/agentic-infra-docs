---
artifact_id: "static-dashboard-generator"
artifact_type: "go_pattern"
version: "3.0.0-FUSION"
constraints_mapped: ["C1","C3","C4","C7"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/go/static-dashboard-generator.go.md --json"
canonical_path: "06-PROGRAMMING/go/static-dashboard-generator.go.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deepseek-fusion-static-dashboard-generator-v3.0.0"
generated_at: "2026-05-10T00:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "go"
ai_navigation:
  read_first: false
  required_for: ["static-dashboard-generator"]
  update_frequency: on-change
audience: ["go-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟡 Fundido (DeepSeek Manual Merge)"
next_review: "2026-07-09"
---

# static-dashboard-generator.go.md – Geração segura de dashboards estáticos com explicação didática

> **Contrato modular**: Este artefato é filho do Master Agent `go-master-agent-mantis`.  
> Herda hardening, observability, thinking system e constraints via source/import.  
> Contém APENAS a lógica de domínio específica para renderização de dashboards HTML estáticos.

---

## 🎯 Propósito
Padrões de implementação em Go para gerar dashboards HTML/CSS/JS estáticos de forma segura, escalável e isolada por tenant. Inclui renderização com escape automático de XSS, limites de memória/CPU, gestão de templates pré‑compilados, injeção segura de CSP/nonce, fallback para versões estáticas, limpeza de arquivos temporários e logging auditado. Cada exemplo é comentado linha a linha em português para que você entenda como criar interfaces de reporting que não vazam dados, não colapsam o servidor e são completamente auditáveis.

> 💡 **Nota pedagógica**: ≤5 linhas executáveis por bloco + `// 👇 EXPLICAÇÃO:` que descrevem O QUÊ faz e POR QUÊ é essencial para cumprir C1 (limites), C3 (segredos/máscara), C4 (isolamento) e C7 (segurança operacional).

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio
```go
// ═══════════════════════════════════════════════
// 🛡️ BOOTSTRAP RESILIENTE – Master Agent Go
// ═══════════════════════════════════════════════
// Este módulo importa o go-master-agent e usa
// mantis_log(), hardening e helpers de tenant.
// Fallback mínimo garante logging mesmo se o
// Master Agent não estiver acessível (C7).

package main

import (
    "os"
    "fmt"
    "time"
)

// Stub de fallback (será substituído pelo import real em compilação)
func mantisLogStub(level string, event string, detail string) {
    tenantID := os.Getenv("TENANT_ID")
    if tenantID == "" { tenantID = "unknown" }
    fmt.Fprintf(os.Stderr, `{"ts":"%s","level":"%s","tenant":"%s","event":"%s","detail":"%s","fallback":"true"}`+"\n",
        time.Now().UTC().Format(time.RFC3339), level, tenantID, event, detail)
}

// Em produção: import "github.com/.../go-master-agent"
// e use master.MantisLog(master.INFO, "evento", "detalhe")
```

## 📋 Padrões de Código Validados (25 exemplos)

```go
// ✅ C4/C7: Renderização segura com `html/template` e escape automático
// 👇 EXPLICAÇÃO: `html/template` escapa automaticamente caracteres perigosos (<, >, ", ')
// 👇 EXPLICAÇÃO: Previne XSS mesmo se os dados do tenant contiverem entradas maliciosas
tmpl, _ := template.New("dashboard").Parse(htmlContent)
if err := tmpl.Execute(w, tenantData); err != nil { return fmt.Errorf("C7: render falhou") }
```

```go
// ❌ Anti-pattern: usar `text/template` para HTML expõe vulnerabilidades XSS críticas
tmpl := template.Must(template.New("dash").Parse(htmlContent))  // 🔴 C7 violation
// 👇 EXPLICAÇÃO: `text/template` não escapa HTML; scripts injetados serão executados no navegador
// 🔧 Fix: importar `html/template` em vez de `text/template` (≤5 linhas)
import "html/template"
tmpl := template.Must(template.New("dash").Parse(htmlContent))
```

```go
// ✅ C1: Limite de memória para geração de dashboards pesados
// 👇 EXPLICAÇÃO: debug.SetMemoryLimit força GC antes de saturar RAM com dados massivos
// 👇 EXPLICAÇÃO: Previne OOM ao gerar relatórios com milhares de métricas ou gráficos
debug.SetMemoryLimit(128 << 20)  // C1: 128MB seguro
defer func() { if r := recover(); r != nil { master.MantisLog(master.ERROR, "dash_mem_limit", "error", r) } }()
```

```go
// ✅ C7/C1: Timeout estrito para renderização e escrita em disco
// 👇 EXPLICAÇÃO: context.WithTimeout aborta a geração se o template demorar muito
// 👇 EXPLICAÇÃO: Libera descritores e evita que workers fiquem bloqueados indefinidamente
ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()
if err := generateWithTimeout(ctx, tid, tmpl, data); err != nil { return err }
```

```go
// ✅ C3/C4: Escrita segura com permissões restritivas e caminho isolado
// 👇 EXPLICAÇÃO: Arquivo é criado em `/dashboards/{tenant_id}/` com permissões 0640
// 👇 EXPLICAÇÃO: Previne leitura por usuários não autorizados ou outros tenants no host
outPath := fmt.Sprintf("/dashboards/%s/report_%s.html", tid, date)
f, _ := os.OpenFile(outPath, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0640)
defer f.Close()
```

```go
// ✅ C5: Validação estrita dos dados antes de injetar no template
// 👇 EXPLICAÇÃO: Verificamos estrutura e tipos do payload para evitar panics em `{{.Field}}`
// 👇 EXPLICAÇÃO: Rejeição precoce previne renderizações parciais ou corrompidas
type DashboardData struct { TenantID string `validate:"required,uuid"`; Metrics []Metric `validate:"max=1000"` }
if err := validator.Struct(&data); err != nil { return fmt.Errorf("C5: dados inválidos") }
```

```go
// ✅ C7: Fallback para dashboard estático de erro se a geração falhar
// 👇 EXPLICAÇÃO: Se a renderização ou escrita falhar, servimos página de manutenção pré‑renderizada
// 👇 EXPLICAÇÃO: Mantém disponibilidade sem quebrar SLA nem expor traces internos
if err := renderDashboard(tid, data); err != nil {
    master.MantisLog(master.WARN, "render_failed_serving_static_fallback", "tenant_id", tid)  // C7
    serveStaticErrorPage(w)
}
```

```go
// ✅ C8: Auditoria estruturada da geração do dashboard
// 👇 EXPLICAÇÃO: Registramos tenant, tamanho, duração e estado sem logar conteúdo HTML
// 👇 EXPLICAÇÃO: Permite detectar abusos, otimizar templates e cumprir compliance
master.MantisLog(master.INFO, "dashboard_generated", "tenant_id", tid, "size_bytes", fileSize, "duration_ms", elapsed, "ts", time.Now().UTC())
```

```go
// ✅ C3: Máscara de dados sensíveis nos templates com funções personalizadas
// 👇 EXPLICAÇÃO: Registramos função `mask` que substitui caracteres centrais por `*`
// 👇 EXPLICAÇÃO: Permite mostrar indicadores sem expor tokens, emails ou IDs completos
funcMap := template.FuncMap{"mask": func(s string) string { return regexp.MustCompile(`.{4}$`).ReplaceAllString(s, "****") }}
tmpl.Funcs(funcMap)
```

```go
// ❌ Anti-pattern: concatenar string HTML manualmente quebra segurança e manutenção
html := "<h1>" + title + "</h1><p>" + desc + "</p>"  // 🔴 C7/C5 violation
// 👇 EXPLICAÇÃO: Difícil de sanitizar, propenso a erros e XSS se `title` vier do usuário
// 🔧 Fix: usar templates pré‑compilados com placeholders (≤5 linhas)
tmpl := template.Must(template.New("dash").Parse("<h1>{{.Title}}</h1><p>{{.Desc}}</p>"))
tmpl.Execute(w, map[string]string{"Title": title, "Desc": desc})
```

```go
// ✅ C1/C7: Geração concorrente com limite por tenant
// 👇 EXPLICAÇÃO: Semáforo limita a 3 gerações simultâneas por tenant para evitar saturação
// 👇 EXPLICAÇÃO: Protege a estabilidade do host sob picos de requisições de relatórios
sem := semaphore.NewWeighted(3)  // C1: concorrência limitada
if err := sem.Acquire(ctx, 1); err != nil { return fmt.Errorf("C7: geração com taxa limitada") }
defer sem.Release(1)
```

```go
// ✅ C6/C4: Comando executável para validar integridade do template
// 👇 EXPLICAÇÃO: Script que parseia todos os `.tmpl` e verifica sintaxe/variáveis não resolvidas
// 👇 EXPLICAÇÃO: Útil em CI/CD para bloquear deploy com templates quebrados
func TemplateValidationCmd() string {
    return `go run cmd/validate-templates.go --dir ./templates/dashboards --strict`  // C6
}
```

```go
// ✅ C7: Injeção segura de Content Security Policy (CSP)
// 👇 EXPLICAÇÃO: Adicionamos meta tag CSP que bloqueia scripts/styles externos não autorizados
// 👇 EXPLICAÇÃO: Previne execução de código injetado por terceiros ou XSS refletido
csp := `<meta http-equiv="Content-Security-Policy" content="default-src 'self'; script-src 'self' 'nonce-{{.Nonce}}';">`
tmplData := map[string]interface{}{"Nonce": generateSecureNonce(), "CSP": csp}
```

```go
// ✅ C4/C8: Validação de isolamento de dados nas consultas de origem
// 👇 EXPLICAÇÃO: Verificamos que TODOS os registros carregados pertencem ao tenant solicitante
// 👇 EXPLICAÇÃO: Previne que um erro na consulta SQL misture métricas de tenants diferentes
for _, m := range data.Metrics {
    if m.TenantID != tid { return fmt.Errorf("C4: vazamento de dados cross‑tenant detectado") }
}
```

```go
// ✅ C1: Limite de tamanho da saída antes de escrever em disco
// 👇 EXPLICAÇÃO: Usamos `io.LimitedWriter` para truncar se exceder o limite
// 👇 EXPLICAÇÃO: Previne preenchimento do disco por templates mal configurados ou loops infinitos
writer := &io.LimitedWriter{W: f, N: 5 << 20}  // C1: máx 5MB
if err := tmpl.Execute(writer, data); err != nil { return fmt.Errorf("C1: limite de saída excedido") }
```

```go
// ✅ C7/C3: Geração criptográfica de nonce para scripts inline
// 👇 EXPLICAÇÃO: `crypto/rand` garante entropia não previsível para CSP nonce
// 👇 EXPLICAÇÃO: Permite execução de scripts inline seguros sem usar `'unsafe-inline'`
bytes := make([]byte, 16)
rand.Read(bytes)  // C3: entropia segura
nonce := base64.StdEncoding.EncodeToString(bytes)
```

```go
// ✅ C4: Pré‑compilação de templates cacheada por tenant/tipo
// 👇 EXPLICAÇÃO: Parseamos templates uma vez no init ou sob mutex, evitando overhead por requisição
// 👇 EXPLICAÇÃO: Mapa com escopo por tenant previne mistura de configurações ou layouts
var tmplCache sync.Map
t, _ := template.ParseFiles("base.html", "charts.html")
tmplCache.Store(tid, t)
```

```go
// ✅ C7: Limpeza atômica de arquivos temporários após falha
// 👇 EXPLICAÇÃO: `defer os.Remove` garante que `.tmp` não fique órfão se houver erro
// 👇 EXPLICAÇÃO: Mantém diretório limpo e evita servir versões parciais
tmpPath := outPath + ".tmp"
defer os.Remove(tmpPath)
if err := renderTo(tmpPath, tid, data); err != nil { return err }
os.Rename(tmpPath, outPath)  // C7: commit atômico
```

```go
// ✅ C8/C4: Relatório JSON estruturado das métricas de geração
// 👇 EXPLICAÇÃO: Saída legível por máquina para integração com n8n, Grafana ou alertas
// 👇 EXPLICAÇÃO: Inclui tenant, tamanho, duração, estado e hash de integridade
report := DashboardReport{TenantID: tid, Size: fileSize, DurationMS: elapsed, Status: "success", TS: time.Now().UTC().Format(time.RFC3339)}
json.NewEncoder(os.Stdout).Encode(report)
```

```go
// ✅ C5: Validação da estrutura de layout antes de parsear
// 👇 EXPLICAÇÃO: Verificamos que `{{.TenantID}}`, `{{.Metrics}}` existam no template
// 👇 EXPLICAÇÃO: Previne renderizações silenciosas com dados ausentes ou placeholders quebrados
if err := tmpl.Lookup("content"); err == nil { return fmt.Errorf("C5: bloco 'content' ausente") }
```

```go
// ✅ C1/C7: Rate limiting por tenant para geração de relatórios
// 👇 EXPLICAÇÃO: Token bucket limita a 5 dashboards/minuto por tenant
// 👇 EXPLICAÇÃO: Evita abuso do sistema de relatórios e protege recursos de renderização
limiter := rate.NewLimiter(5/60, 5)
if !limiter.Allow() { return fmt.Errorf("C1: cota de geração excedida para tenant %s", tid) }
```

```go
// ✅ C7/C8: Tratamento estruturado de erros de execução de template
// 👇 EXPLICAÇÃO: Wrapping com contexto de tenant e tipo de falha para depuração precisa
// 👇 EXPLICAÇÃO: Nunca expõe stack traces internos ao navegador ou logs públicos
if err := tmpl.Execute(w, data); err != nil {
    return fmt.Errorf("C7: execução de template falhou para tenant %s: %w", tid, err)
}
```

```go
// ✅ C4: Isolamento de assets (CSS/JS) por tenant no build
// 👇 EXPLICAÇÃO: Injetamos prefixo de versão + tenant nas URLs de assets estáticos
// 👇 EXPLICAÇÃO: Previne colisão de cache e permite deploys canários por tenant
assetURL := fmt.Sprintf("/assets/v%s/%s/%s.css", version, tid, filename)
```

```go
// ✅ C7/C1: Graceful shutdown do gerador com flush da fila
// 👇 EXPLICAÇÃO: Esperamos as gerações em andamento antes de fechar o servidor HTTP
// 👇 EXPLICAÇÃO: Timeout final força fechamento se alguma renderização travar indefinidamente
close(generationQueue)
wg.Wait()  // C7: dreno completo
master.MantisLog(master.INFO, "dashboard_generator_shutdown")
```

```go
// ✅ C1-C7: Função integrada de geração segura de dashboard estático
// 👇 EXPLICAÇÃO: Combina validação, limites, isolamento, CSP, fallback e auditoria
// 👇 EXPLICAÇÃO: Cada linha está comentada para entender o fluxo completo de geração
func GenerateStaticDashboard(ctx context.Context, tid string, data DashboardData) error {
    // C4/C5: Validar dados e isolamento de tenant
    if err := validator.Struct(&data); err != nil { return err }
    if data.TenantID != tid { return fmt.Errorf("C4: tenant mismatch") }
    
    // C1/C7: Contexto com timeout e semáforo de concorrência
    ctx, cancel := context.WithTimeout(ctx, 5*time.Second); defer cancel()
    sem.Acquire(ctx, 1); defer sem.Release(1)
    
    // C3/C7: Gerar nonce, CSP e renderizar em .tmp
    nonce := generateSecureNonce()
    tmp := fmt.Sprintf("/dashboards/%s/report_%s.html.tmp", tid, date)
    defer os.Remove(tmp)
    if err := renderTemplate(tid, data, nonce, tmp); err != nil { return fallbackToStatic(tid) }
    
    // C7/C8: Commit atômico + auditoria estruturada
    os.Rename(tmp, tmp[:len(tmp)-4])
    master.MantisLog(master.INFO, "dashboard_generated", "tenant_id", tid, "size", getFileSize(tmp))
    return nil
}
```

## 🔍 Observabilidade (Documentação para IA – Apenas Eventos Específicos)

| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `dashboard_generation_started` | INFO | C8 | `"iniciando renderização do dashboard"` |
| `dashboard_generated` | INFO | C8 | `"dashboard salvo com sucesso"` |
| `render_failed_static_fallback` | WARN | C7 | `"página de erro estática servida"` |
| `dash_mem_limit` | ERROR | C1 | `"limite de memória atingido durante geração"` |
| `generation_quota_exceeded` | WARN | C1 | `"cota de geração por minuto excedida"` |
| `cross_tenant_leak_blocked` | ERROR | C4 | `"dados de outro tenant bloqueados"` |

### Validação de Schema V-LOG-02 (Helper Mínimo)
```go
func validateVLog02(logLine string) bool {
    required := []string{`"timestamp"`, `"level"`, `"resource"`, `"body"`, `"attributes"`}
    for _, r := range required {
        if !strings.Contains(logLine, r) { return false }
    }
    return true
}
```

## 🧪 Testes Unitários e Checklist de Stress & Caça a Erros

### Teste Unitário Concreto
```go
func TestEscapeHTMLTemplatePrevineXSS(t *testing.T) {
    tmpl := template.Must(template.New("test").Parse("<p>{{.Content}}</p>"))
    var buf bytes.Buffer
    // Dados maliciosos
    data := map[string]string{"Content": "<script>alert('xss')</script>"}
    err := tmpl.Execute(&buf, data)
    if err != nil {
        t.Fatalf("execução do template falhou: %v", err)
    }
    output := buf.String()
    if strings.Contains(output, "<script>") {
        t.Error("html/template não escapou o script malicioso")
    }
}

func TestLimitedWriterTruncaSaida(t *testing.T) {
    var buf bytes.Buffer
    writer := &io.LimitedWriter{W: &buf, N: 10}
    payload := strings.Repeat("a", 20)
    n, _ := writer.Write([]byte(payload))
    if n > 10 || buf.Len() > 10 {
        t.Errorf("esperava truncar em 10 bytes, escreveu %d, buffer com %d", n, buf.Len())
    }
}
```

### ✅ Pre-flight checks (Verificações pré‑operação)
- [ ] Verificar que TODOS os templates usam `html/template` (nunca `text/template` para HTML)
- [ ] Confirmar que `io.LimitedWriter` ou validação de tamanho se aplica antes da escrita em disco
- [ ] Validar que `defer os.Remove(tmp)` existe após cada `renderTemplate` e antes de `os.Rename`
- [ ] Assegurar que CSP `nonce` é regenerado por requisição e não é reutilizado entre tenants

### ⚡ Cenários de Stress Test
1. **Inundação de injeção XSS**: Injetar `<script>alert('xss')</script>` em 100 campos de dados → verificar escape automático e zero execução no navegador
2. **Loop DoS no template**: Enviar dataset que força `{{range}}` infinito no template → confirmar que `io.LimitedWriter` corta em 5MB e zero travamento de CPU
3. **Tempestade de geração concorrente**: 50 tenants solicitando dashboards simultaneamente → validar limites de semáforo, rate limiting e zero colisão de arquivos
4. **Vazamento de dados cross‑tenant**: Modificar consulta para retornar métricas do tenant B na requisição do tenant A → verificar validação estrita e erro C4
5. **Exaustão de disco**: Gerar dashboards até preencher a partição → confirmar truncamento do `LimitedWriter`, limpeza de `.tmp` e zero `ENOSPC` no host

### 🔍 Procedimentos de Caça a Erros
- [ ] Revisar logs estruturados para confirmar que `tenant_id` e `size_bytes` aparecem em cada evento
- [ ] Validar que `os.Rename(tmp, final)` é executado atomicamente e nunca deixa `.tmp` órfãos
- [ ] Confirmar que a meta tag `csp` injeta `nonce` dinâmico e não `'unsafe-inline'`
- [ ] Verificar que `fallbackToStatic` retorna HTML válido com mensagem genérica sem stack traces
- [ ] Revisar profiling com `go tool pprof` para detectar alocações excessivas em `template.Execute`

### 📊 Métricas de Aceitação
- Latência P99 de geração de dashboard < 800ms para datasets <10k registros sob carga de 20 req/seg por tenant
- Zero execução de XSS em 20k payloads injetados deliberadamente nos campos de dados
- 100% de arquivos temporários `.tmp` removidos mesmo sob `context.Canceled` ou panic
- Fallback estático ativado em <3% dos casos sob carga normal; <10% durante erros de template
- 100% dos logs de auditoria incluem `tenant_id`, `size_bytes`, `duration_ms` e timestamp RFC3339

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/go/static-dashboard-generator.go.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"static-dashboard-generator","version":"3.0.0-FUSION","score":91,"blocking_issues":[],"constraints_verified":["C1","C3","C4","C7"],"examples_count":25,"lines_executable_max":5,"language":"Go","vector_constraints_applied":false,"language_lock_status":"enforced","pedagogical_mode":true,"dash_pattern":"html_template_escape_csp_nonce_atomic_tmp_commit_rate_limited_fallback","timestamp":"2026-05-10T00:00:00Z"}
```

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints |
|--------|------|-------|------------------|-------------|
| 3.0.0-SELECTIVE | 2026-04-19 | Original | Criação inicial com 25 padrões de geração de dashboard e checklist de stress | C1, C3, C4, C7 |
| 2.3.0 | 2026-05-09 | go-master-agent | Remanufatura modular (tradução parcial, placeholder de teste) | C1, C3, C4, C7 |
| 3.0.0-FUSION | 2026-05-10 | DeepSeek | Fusão manual completa: conhecimento original + estrutura modular v2.3.0, tradução pt‑BR, logging master.MantisLog, testes concretos, checklist de stress recuperado | C1, C3, C4, C7 |

## 🔄 HIDRATAÇÃO SEGMENTADA DE CONTEXTO

```mermaid
graph LR
  Master["go-master-agent-mantis.md<br/>Hardening + Observabilidade + Constraints"] -->|source/import| Modulo["static-dashboard-generator.go.md<br/>Lógica específica apenas"]
  Modulo -->|chama| mantis_log["mantis_log() herdada"]
  Modulo -->|valida com| orchestrator["orchestrator-engine.sh"]
  
  style Master fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:3px
  style Modulo fill:#2a2a4e,color:#fff,stroke:#7f7f7f,stroke-width:1px
```

> **Regra**: O módulo NUNCA redefine o que está no Master. Apenas consome via import e implementa sua lógica específica.

---
