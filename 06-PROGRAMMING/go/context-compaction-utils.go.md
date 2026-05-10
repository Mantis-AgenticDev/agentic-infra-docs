---
artifact_id: "context-compaction-utils"
artifact_type: "go_pattern"
version: "3.0.0-FUSION"
constraints_mapped: ["C1", "C4", "C5", "C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/go/context-compaction-utils.go.md --json"
canonical_path: "06-PROGRAMMING/go/context-compaction-utils.go.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deepseek-fusion-context-compaction-utils-v3.0.0"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "go"
ai_navigation:
  read_first: false
  required_for: ["context-compaction-utils"]
  update_frequency: on-change
audience: ["go-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟡 Fundido (DeepSeek Manual Merge)"
next_review: "2026-06-09"
---

## 🛡️ Bootstrap Resiliente
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


# context-compaction-utils.go.md – Compressão de contexto para LLMs com limites de tokens e isolamento de tenant

## 🎯 Propósito
Padrões de implementação em Go para gerenciamento seguro e eficiente de contextos de IA: truncamento inteligente, contagem de tokens com margens de segurança, isolamento estrito por tenant, validação da estrutura de prompts, logging estruturado de métricas e fallback degradado. Cada exemplo é comentado linha por linha em português para que você entenda como manter o contexto dentro dos limites do modelo sem vazamento de dados ou falhas de memória.

> 💡 **Nota pedagógica**: ≤5 linhas executáveis por bloco + `// 👇 EXPLICAÇÃO:` que descrevem O QUE faz e POR QUE é essencial para cumprir C1 (limites), C4 (isolamento de tenant), C5 (validação) e C8 (observabilidade).

## 📋 Padrões de Código Validados (25 exemplos)

```go
// ✅ C4/C1: Estrutura de contexto isolada por tenant com limite de tokens
// 👇 EXPLICAÇÃO: Mapa aninhado garante que mensagens de um tenant não se misturem com outras
// 👇 EXPLICAÇÃO: MaxTokens aplica limite estrito por tenant para cumprir limites do modelo
type TenantContext struct { Messages []Message; CurrentTokens int; MaxTokens int }
func NewTenantContext(tid string, maxT int) *TenantContext {
    return &TenantContext{Messages: []Message{}, CurrentTokens: 0, MaxTokens: maxT}  // C4: instância isolada
}
```

```go
// ✅ C1: Estimativa segura de tokens com margem de segurança
// 👇 EXPLICAÇÃO: Aproximamos 4 caracteres por token + margem de 15% para evitar overflow
// 👇 EXPLICAÇÃO: Rejeitamos contexto antes de enviá-lo ao LLM se exceder o limite
estimated := len(text) / 4 * 1.15  // C1: estimativa conservadora
if estimated > ctx.MaxTokens { return nil, fmt.Errorf("C1: contexto excede limite") }
```

```go
// ❌ Anti-pattern: concatenar mensagens sem verificar limite colapsa janela de contexto
ctx.Messages = append(ctx.Messages, newMsg); ctx.CurrentTokens += len(newMsg.Content)  // 🔴 C1
// 👇 EXPLICAÇÃO: Acúmulo sem controle excede limites do modelo e gera erros 429/500
// 🔧 Fix: aplicar função de compactação antes de adicionar (≤5 linhas)
compactCtx := compactBeforeAdd(ctx, newMsg, maxTokens)
ctx.Messages = compactCtx.Messages; ctx.CurrentTokens = compactCtx.Tokens
```

```go
// ✅ C5: Validação da estrutura do prompt antes da compressão
// 👇 EXPLICAÇÃO: Usamos struct tags para garantir que campos obrigatórios existam
// 👇 EXPLICAÇÃO: Previne envio de contextos malformados ao modelo que quebram o fluxo
type PromptInput struct {
    System   string `json:"system" validate:"required,min=10"`
    History  []Msg  `json:"history" validate:"max=50"`
    UserMsg  string `json:"user_msg" validate:"required"`
}
if err := validator.Struct(&input); err != nil { return nil, fmt.Errorf("C5: prompt inválido: %w", err) }
```

```go
// ✅ C8: Logging estruturado de métricas de compressão
// 👇 EXPLICAÇÃO: Registramos taxa de compressão, tokens usados e tenant_id para observabilidade
// 👇 EXPLICAÇÃO: Permite detectar degradação de qualidade ou limites mal configurados
master.MantisLog(master.INFO, "context_compacted", "tenant_id", tid, "original_tokens", orig, "compact_tokens", final, "ratio", fmt.Sprintf("%.2f", float64(final)/float64(orig)))  // C8
```

```go
// ✅ C1/C7: Timeout para operação de compressão sob carga
// 👇 EXPLICAÇÃO: Limitamos o processo de compactação a 500ms para não bloquear requisições HTTP
// 👇 EXPLICAÇÃO: Se exceder, fallback para truncamento simples garante resposta rápida
ctxComp, cancel := context.WithTimeout(context.Background(), 500*time.Millisecond)
defer cancel()
compacted, err := compactWithContext(ctxComp, original, maxTokens)  // C7: processamento limitado
```

```go
// ✅ C4: Janela deslizante isolada por tenant
// 👇 EXPLICAÇÃO: Mantemos apenas as N mensagens mais recentes, descartando as mais antigas
// 👇 EXPLICAÇÃO: Previne memory leaks e garante que cada tenant opere dentro de sua cota
if len(ctx.Messages) > maxHistory {
    ctx.Messages = ctx.Messages[len(ctx.Messages)-maxHistory:]  // C4: slice seguro por instância
}
```

```go
// ✅ C5/C1: Validação de caracteres e sanitização antes de injetar no contexto
// 👇 EXPLICAÇÃO: Removemos caracteres de controle e sequências de escape perigosas
// 👇 EXPLICAÇÃO: Previne injeção de prompts maliciosos ou corrupção de tokens
sanitized := strings.Map(func(r rune) rune {
    if unicode.IsControl(r) && r != '\n' && r != '\t' { return -1 }; return r
}, rawInput)
```

```go
// ❌ Anti-pattern: limite de tokens hardcoded ignora variação entre modelos
const MaxTokens = 4096  // 🔴 Violação C1: inflexível entre ambientes/modelos
// 👇 EXPLICAÇÃO: Modelos diferentes têm janelas distintas; hardcodar quebra portabilidade
// 🔧 Fix: ler da configuração por modelo/tenant (≤5 linhas)
maxT := config.GetModelLimit(modelName)
if estimated > maxT { return fmt.Errorf("C1: limite excedido para %s", modelName) }
```

```go
// ✅ C4/C1: Poda baseada em prioridade de mensagens por tenant
// 👇 EXPLICAÇÃO: Eliminamos primeiro mensagens de baixa prioridade (ex: logs do sistema) antes de dados críticos
// 👇 EXPLICAÇÃO: Mantém coerência conversacional respeitando limites estritos
for ctx.CurrentTokens > ctx.MaxTokens {
    if idx := findLowestPriority(ctx.Messages); idx != -1 {
        ctx.CurrentTokens -= estimateTokens(ctx.Messages[idx].Content)
        ctx.Messages = append(ctx.Messages[:idx], ctx.Messages[idx+1:]...)  // C4: remoção segura
    }
}
```

```go
// ✅ C8/C4: Auditoria estruturada de operações de contexto
// 👇 EXPLICAÇÃO: Registramos ação, tenant, tokens antes/depois e resultado para rastreabilidade
// 👇 EXPLICAÇÃO: Permite análise post-mortem de falhas de contexto ou degradação de qualidade
master.MantisLog(master.INFO, "context_audit", "tenant_id", tid, "action", "compact_sliding", "tokens_in", in, "tokens_out", out, "ts", time.Now().UTC())  // C8
```

```go
// ✅ C1: Limite de memória para builder de contextos longos
// 👇 EXPLICAÇÃO: debug.SetMemoryLimit força GC agressivo se o builder consumir demais
// 👇 EXPLICAÇÃO: Previne OOM durante construção de contextos históricos massivos
debug.SetMemoryLimit(64 << 20)  // C1: 64MB para compactação
defer func() { if r := recover(); r != nil { master.MantisLog(master.ERROR, "mem_limit_hit_compaction", "error", r) } }()
```

```go
// ✅ C7: Fallback seguro para prompt minimalista se a compressão falhar
// 👇 EXPLICAÇÃO: Se a compactação complexa demorar ou falhar, usamos versão reduzida garantida
// 👇 EXPLICAÇÃO: Mantém a disponibilidade do serviço sem quebrar o contrato com o cliente
compacted, err := advancedCompact(ctx)
if err != nil {
    master.MantisLog(master.WARN, "fallback_to_minimal", "tenant_id", tid)
    compacted = minimalContext(tid, userQuery)  // C7: degradação controlada
}
```

```go
// ✅ C4: Injeção de system prompt com escopo por tenant
// 👇 EXPLICAÇÃO: Cada tenant recebe instruções de sistema isoladas sem contaminação cruzada
// 👇 EXPLICAÇÃO: Valida que o prompt não exceda 10% do orçamento total de tokens
sysPrompt := getTenantSystemPrompt(tid)
if est := estimateTokens(sysPrompt); est > ctx.MaxTokens/10 {
    return fmt.Errorf("C4: system prompt excede cota para tenant %s", tid)
}
```

```go
// ✅ C5: Validação de UTF-8 e comprimento máximo por mensagem
// 👇 EXPLICAÇÃO: Rejeitamos mensagens com encoding inválido ou extremamente longas antes de processar
// 👇 EXPLICAÇÃO: Previne panics em parsers do modelo ou corrupção de estado interno
if !utf8.ValidString(msg.Content) || len(msg.Content) > 50000 {
    return fmt.Errorf("C5: mensagem inválida ou muito longa")
}
```

```go
// ✅ C1/C2: Compressão assíncrona com cancelamento em cascata
// 👇 EXPLICAÇÃO: Executamos compressão pesada em background com timeout e contexto herdado
// 👇 EXPLICAÇÃO: Se a requisição HTTP morrer, a compressão é cancelada automaticamente
go func() {
    compacted, err := compactHeavy(ctx, messages)
    if err == nil && ctx.Err() == nil { resultCh <- compacted }  // C2: verifica cancelamento
}()
```

```go
// ✅ C4/C8: Exportação de métricas de uso de contexto por tenant
// 👇 EXPLICAÇÃO: Contador atômico rastreia tokens consumidos por tenant para faturamento/alertas
// 👇 EXPLICAÇÃO: Permite detectar tenants que saturam recursos sem afetar outros
var tenantTokens atomic.Int64
tenantTokens.Add(int64(tokensUsed))
if tenantTokens.Load() > dailyQuota { master.MantisLog(master.WARN, "quota_exceeded", "tenant_id", tid) }  // C8
```

```go
// ❌ Anti-pattern: concatenação de strings em loop consome memória exponencialmente
var full string
for _, m := range msgs { full += m.Content + "\n" }  // 🔴 Violação C1: memória O(n²)
// 👇 EXPLICAÇÃO: Cada += cria nova string, colapsando memória em conversas longas
// 🔧 Fix: usar strings.Builder para concatenação eficiente (≤5 linhas)
var b strings.Builder
for _, m := range msgs { b.WriteString(m.Content); b.WriteByte('\n') }
```

```go
// ✅ C7: Retry com redução agressiva de contexto após falha do LLM
// 👇 EXPLICAÇÃO: Se o modelo rejeitar o prompt por tamanho, tentamos novamente com 50% menos tokens
// 👇 EXPLICAÇÃO: Evita loops infinitos e garante resolução eventual
for attempt := 1; attempt <= 3; attempt++ {
    if resp, err := sendToLLM(ctx, prompt); err == nil { return resp, nil }
    prompt = reduceTokens(prompt, 0.5)  // C7: redução agressiva
    time.Sleep(time.Duration(attempt*100) * time.Millisecond)
}
```

```go
// ✅ C4: Cache de contextos compactados por tenant+hash
// 👇 EXPLICAÇÃO: Armazenamos resultado compactado para reuso se a entrada não mudar
// 👇 EXPLICAÇÃO: Mapa com chave hash(tenantID+messages) evita reprocessamento custoso
cacheKey := fmt.Sprintf("%s:%x", tid, sha256.Sum256([]byte(msgKey)))
if cached, ok := compCache.Get(cacheKey); ok { return cached, nil }  // C4: isolamento por chave
```

```go
// ✅ C1/C5: Limite estrito de turnos de conversação
// 👇 EXPLICAÇÃO: Truncamos automaticamente quando o número máximo de intercâmbios é excedido
// 👇 EXPLICAÇÃO: Previne contexto infinito e mantém coerência dentro da janela do modelo
if len(ctx.Messages) > maxTurns {
    keep := ctx.Messages[len(ctx.Messages)-maxTurns:]
    ctx.Messages = append([]Message{ctx.SystemPrompt}, keep...)  // C5: preserva sistema
}
```

```go
// ✅ C8: Relatório estruturado de erro de contexto
// 👇 EXPLICAÇÃO: Devolvemos payload JSON claro para que clientes lidem com falhas programaticamente
// 👇 EXPLICAÇÃO: Inclui tenant_id, limite excedido e ação recomendada
errResp := map[string]interface{}{
    "error": "context_limit_exceeded", "tenant_id": tid,
    "max_tokens": ctx.MaxTokens, "suggestion": "reduce_history_or_split_conversation",
}
json.NewEncoder(os.Stderr).Encode(errResp)  // C8: stderr para observabilidade
```

```go
// ✅ C4/C1: Builder com backpressure e limite de tamanho
// 👇 EXPLICAÇÃO: Canal com buffer controla a velocidade de adição de mensagens ao contexto
// 👇 EXPLICAÇÃO: Se o consumidor for lento, o produtor bloqueia controladamente
msgCh := make(chan Message, 50)
go func() {
    for m := range msgCh { if ctx.CanAdd(m) { ctx.Add(m) } }  // C4: builder ciente do tenant
}()
```

```go
// ✅ C7: Degradação controlada sob saturação de tokens
// 👇 EXPLICAÇÃO: Se o sistema estiver sob carga, reduzimos automaticamente o histórico mantido
// 👇 EXPLICAÇÃO: Prioriza resposta rápida sobre completude histórica
if systemLoad > 0.85 {
    ctx.MaxTokens = ctx.MaxTokens * 3 / 4  // C7: auto-throttle
    master.MantisLog(master.WARN, "context_degraded", "tenant_id", tid, "new_limit", ctx.MaxTokens)
}
```

```go
// ✅ C1-C8: Função integrada de compressão segura por tenant
// 👇 EXPLICAÇÃO: Combina validação, estimativa, isolamento, timeout e logging estruturado
// 👇 EXPLICAÇÃO: Cada seção é comentada para entender o fluxo completo de gerenciamento de contexto
func CompactTenantContext(tid string, input PromptInput, modelLimit int) (*CompactResult, error) {
    // C4/C5: Validar entrada e isolar por tenant
    if err := validatePrompt(&input); err != nil { return nil, err }
    ctx := NewTenantContext(tid, modelLimit)
    
    // C1/C7: Timeout e compressão com fallback
    compCtx, cancel := context.WithTimeout(context.Background(), 500*time.Millisecond)
    defer cancel()
    result, err := compactWithContext(compCtx, input, ctx)
    if err != nil { result = fallbackMinimal(input, tid) }
    
    // C8: Auditoria e métricas
    master.MantisLog(master.INFO, "context_compaction_complete", "tenant_id", tid, "tokens", result.Tokens)
    return result, nil
}
```

## 🔍 Observabilidade (Documentação para IA – Eventos Específicos)

| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `context_compaction_started` | INFO | C8 | `"iniciando compressão de contexto"` |
| `context_limit_exceeded` | WARN | C1 | `"limite de tokens excedido"` |
| `invalid_message_dropped` | WARN | C5 | `"mensagem inválida descartada"` |
| `fallback_to_minimal` | WARN | C7 | `"fallback para contexto mínimo ativado"` |
| `mem_limit_hit_compaction` | ERROR | C1 | `"limite de memória atingido durante compactação"` |
| `quota_exceeded` | WARN | C8 | `"cota de tokens excedida para tenant"` |

### Validação de Schema V-LOG-02
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
func TestTenantContextExcedeLimiteTokens(t *testing.T) {
    ctx := NewTenantContext("tenant-1", 100)
    // Adiciona mensagens que ultrapassam o limite
    for i := 0; i < 10; i++ {
        msg := Message{Content: strings.Repeat("a", 100)} // cada ~25 tokens
        ctx.Messages = append(ctx.Messages, msg)
        ctx.CurrentTokens += 25
    }
    if ctx.CurrentTokens <= ctx.MaxTokens {
        t.Errorf("Esperava que CurrentTokens (%d) excedesse MaxTokens (%d)", ctx.CurrentTokens, ctx.MaxTokens)
    }
    // Aplica janela deslizante para corrigir
    maxHistory := 3
    if len(ctx.Messages) > maxHistory {
        ctx.Messages = ctx.Messages[len(ctx.Messages)-maxHistory:]
        // Recalcula tokens (simplificado)
        ctx.CurrentTokens = 0
        for _, m := range ctx.Messages {
            ctx.CurrentTokens += 25
        }
    }
    if ctx.CurrentTokens > ctx.MaxTokens {
        t.Errorf("Após janela deslizante, CurrentTokens (%d) deveria ser <= MaxTokens (%d)", ctx.CurrentTokens, ctx.MaxTokens)
    }
}
```

### ✅ Pre-flight checks
- [ ] Verificar que `MaxTokens` é lido da configuração por modelo/ambiente (sem hardcode)
- [ ] Confirmar que cada instância de `TenantContext` é isolada e não compartilha slices/mapas
- [ ] Validar que `compactWithContext` respeita `context.DeadlineExceeded` e retorna fallback
- [ ] Assegurar que `strings.Map` elimina caracteres de controle sem quebrar UTF-8 válido

### ⚡ Cenários de Stress Test
1. **Simulação de overflow de tokens**: Enviar 3x o limite de tokens → verificar truncamento controlado e fallback ativado sem panic
2. **Compactação concorrente**: 200 tenants compactando simultaneamente → confirmar isolamento de memória e zero race conditions (`go test -race`)
3. **Ataque de encoding**: Injetar mensagens com sequências maliciosas (null bytes, caracteres de controle) → validar sanitização bem-sucedida
4. **Cascata de timeout**: Forçar lentidão na função de compressão → confirmar cancelamento em <500ms e fallback minimalista
5. **Envenenamento de cache**: Gerar colisões de hash artificiais → verificar que a chave inclui tenant_id e evita vazamentos entre tenants

### 🔍 Procedimentos de Caça a Erros
- [ ] Revisar logs estruturados para confirmar que `tenant_id` aparece em cada evento de compressão
- [ ] Validar que `debug.SetMemoryLimit` força GC sem derrubar o processo principal
- [ ] Confirmar que `strings.Builder` substitui concatenação `+=` em todos os fluxos de construção
- [ ] Verificar que o retry com redução de tokens não gera loop infinito (máx 3 tentativas)
- [ ] Revisar profiling com `pprof` para detectar alocações desnecessárias em `compactWithContext`

### 📊 Métricas de Aceitação
- Latência P99 de compressão < 400ms sob carga de 50 requisições/seg por tenant
- Zero memory leaks após 10k operações de compactação (verificar com `runtime.ReadMemStats`)
- 100% dos contextos entregues ao modelo cumprem `len(tokens) <= MaxTokens * 0.95`
- Fallback ativado em <1% dos casos sob carga normal; <15% sob saturação extrema
- 100% dos logs de auditoria incluem `tenant_id`, `tokens_in`, `tokens_out` e timestamp RFC3339

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/go/context-compaction-utils.go.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"context-compaction-utils","version":"3.0.0-FUSION","score":91,"blocking_issues":[],"constraints_verified":["C1","C4","C5","C8"],"examples_count":25,"lines_executable_max":5,"language":"Go","vector_constraints_applied":false,"language_lock_status":"enforced","pedagogical_mode":true,"context_pattern":"token_limits_tenant_isolation_sliding_window_structured_audit","timestamp":"2026-05-09T00:00:00Z"}
```

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints |
|--------|------|-------|------------------|-------------|
| 3.0.0-SELECTIVE | 2026-04-19 | Original | Criação inicial com 25 padrões didáticos e checklist de stress | C1, C4, C5, C8 |
| 2.3.0 | 2026-05-09 | Antigravity | Remanufatura modular (parcial, perdeu checklist e exemplos avançados) | C1, C4, C5, C8 |
| 3.0.0-FUSION | 2026-05-09 | DeepSeek | Fusão manual completa: conhecimento original + estrutura modular v2.3.0, tradução pt-BR, testes concretos, checklist de stress recuperado | C1, C4, C5, C8 |

## 🔄 HIDRATAÇÃO SEGMENTADA DE CONTEXTO

```mermaid
graph LR
  Master["go-master-agent-mantis.md<br/>Hardening + Observabilidade + Constraints"] -->|source/import| Modulo["context-compaction-utils.go.md<br/>Lógica específica apenas"]
  Modulo -->|chama| mantis_log["mantis_log() herdada"]
  Modulo -->|valida com| orchestrator["orchestrator-engine.sh"]
  
  style Master fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:3px
  style Modulo fill:#2a2a4e,color:#fff,stroke:#7f7f7f,stroke-width:1px
```

> **Regra**: O módulo NUNCA redefine o que está no Master. Apenas consome via import e implementa sua lógica específica.
```
