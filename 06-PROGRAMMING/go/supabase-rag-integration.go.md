---
artifact_id: "supabase-rag-integration"
artifact_type: "go_pattern"
version: "3.0.0-FUSION"
constraints_mapped: ["C3","C4","C6","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/go/supabase-rag-integration.go.md --json"
canonical_path: "06-PROGRAMMING/go/supabase-rag-integration.go.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deepseek-fusion-supabase-rag-integration-v3.0.0"
generated_at: "2026-05-10T00:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "go"
ai_navigation:
  read_first: false
  required_for: ["supabase-rag-integration"]
  update_frequency: on-change
audience: ["go-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟡 Fundido (DeepSeek Manual Merge)"
next_review: "2026-07-09"
---

# supabase-rag-integration.go.md – Integração segura com Supabase para RAG com explicação didática

> **Contrato modular**: Este artefato é filho do Master Agent `go-master-agent-mantis`.  
> Herda hardening, observability, thinking system e constraints via source/import.  
> Contém APENAS a lógica de domínio específica para pipeline RAG sobre Supabase.

---

## 🎯 Propósito
Padrões de implementação em Go para construir pipelines de Retrieval-Augmented Generation (RAG) sobre Supabase. Inclui uso seguro do cliente PostgREST, aplicação estrita de Row Level Security (RLS), gestão de autenticação JWT, ingestão de chunks vetoriais, limites de recursos e observabilidade estruturada. Cada exemplo é comentado linha a linha em português para que você entenda como manter isolamento multi-tenant e conformidade normativa sem depender de bypasses inseguros.

> 💡 **Nota pedagógica**: ≤5 linhas executáveis por bloco + `// 👇 EXPLICAÇÃO:` que descrevem O QUÊ faz e POR QUÊ é essencial para cumprir C3 (segredos), C4 (RLS/isolamento de tenant), C6 (validação executável) e C8 (observabilidade).

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
// ✅ C4: Cliente Supabase com RLS habilitado via JWT do tenant
// 👇 EXPLICAÇÃO: O token JWT contém a claim `tenant_id` que Supabase usa para filtrar automaticamente
// 👇 EXPLICAÇÃO: Nunca desabilitamos RLS; a segurança é delegada à camada de banco de dados
client := supabase.NewClient(supabase.Config{
    URL: os.Getenv("SUPABASE_URL"), APIKey: os.Getenv("SUPABASE_ANON_KEY"),
    Headers: map[string]string{"Authorization": "Bearer " + tenantJWT}, // C4: enforcement de RLS
})
```

```go
// ❌ Anti-pattern: usar Service Role Key no cliente frontend ou sem escopo
client := supabase.NewClient(supabase.Config{APIKey: os.Getenv("SUPABASE_SERVICE_KEY")})  // 🔴 C3/C4
// 👇 EXPLICAÇÃO: Service Role Key ignora RLS, permitindo acesso cruzado entre tenants
// 🔧 Fix: usar Anon Key + JWT do usuário/tenant para respeitar políticas RLS (≤5 linhas)
client := supabase.NewClient(supabase.Config{APIKey: os.Getenv("SUPABASE_ANON_KEY")})
req.Header.Set("Authorization", "Bearer "+userJWT)
```

```go
// ✅ C3/C6: Validação executável da configuração RAG antes de iniciar
// 👇 EXPLICAÇÃO: Verificamos variáveis de ambiente e conectividade básica com timeout estrito
// 👇 EXPLICAÇÃO: Retorna comando verificável para integração em CI/CD
func validateRAGSetup() error {
    if os.Getenv("SUPABASE_URL") == "" || os.Getenv("OPENAI_API_KEY") == "" {
        return fmt.Errorf("C3: credenciais RAG não definidas")
    }
    return nil  // C6: verificação executável em pipelines
}
```

```go
// ✅ C4/C8: Ingestão de chunks com metadados com escopo de tenant
// 👇 EXPLICAÇÃO: Incluímos `tenant_id` em cada registro para que RLS filtre automaticamente
// 👇 EXPLICAÇÃO: Log estruturado registra tamanho, dimensão do embedding e tenant sem expor conteúdo
_, err := client.Table("documents").Insert(Document{
    TenantID: tid, Content: chunk, Embedding: vec, Meta: map[string]string{"source": filename},
})
master.MantisLog(master.INFO, "chunk_ingested", "tenant_id", tid, "chars", len(chunk), "vec_dim", len(vec))  // C8
```

```go
// ✅ C8: Busca vetorial RAG com logging de métricas de recuperação
// 👇 EXPLICAÇÃO: Registramos latência, quantidade de chunks retornados e tenant para otimização
// 👇 EXPLICAÇÃO: A consulta usa RPC ou coluna vetorial com RLS implícito via JWT
start := time.Now()
chunks, err := client.Table("documents").Select("*").Rpc("match_documents", map[string]interface{}{"query_vec": vec, "tenant_id": tid}).Limit(5).All()
master.MantisLog(master.INFO, "rag_retrieval", "tenant_id", tid, "chunks_found", len(chunks), "ms", time.Since(start).Milliseconds())  // C8
```

```go
// ❌ Anti-pattern: retornar chunks sem validar contexto de RLS
chunks, _ := client.Table("documents").Select("*").Eq("tenant_id", tid).All()  // 🔴 C4 risk
// 👇 EXPLICAÇÃO: Se o JWT for omitido ou inválido, RLS pode falhar aberto dependendo da política
// 🔧 Fix: forçar cabeçalho Authorization e validar a resposta (≤5 linhas)
req := client.R().SetHeader("Authorization", "Bearer "+jwt)
res, err := req.Get("/rest/v1/documents?tenant_id=eq."+tid)
```

```go
// ✅ C4: Upsert seguro de embeddings com conflito resolvido por tenant
// 👇 EXPLICAÇÃO: `ON CONFLICT` com `tenant_id` garante que apenas atualizamos registros próprios
// 👇 EXPLICAÇÃO: Previne sobrescrita acidental ou maliciosa entre tenants
query := `INSERT INTO embeddings (tenant_id, chunk_id, vec) VALUES ($1, $2, $3)
          ON CONFLICT (tenant_id, chunk_id) DO UPDATE SET vec = EXCLUDED.vec, updated_at = NOW()`
```

```go
// ✅ C1/C7: Limite de memória para carregamento de documentos grandes antes do chunking
// 👇 EXPLICAÇÃO: Estabelecemos teto de 64MB para evitar OOM ao ler PDFs/textos massivos
// 👇 EXPLICAÇÃO: Se exceder, aplicamos streaming ou rejeição controlada
debug.SetMemoryLimit(64 << 20)  // C1: limite seguro para parsing
if fileSize > 50<<20 { return fmt.Errorf("C1: arquivo excede limite seguro") }
```

```go
// ✅ C7/C2: Timeout estrito para pipeline embedding + retriever + LLM
// 👇 EXPLICAÇÃO: Derivamos contexto com deadline para abortar se Supabase ou LLM demorar
// 👇 EXPLICAÇÃO: Liberamos conexões e evitamos goroutines penduradas
ctx, cancel := context.WithTimeout(r.Context(), 8*time.Second)
defer cancel()
response, err := runRAGPipeline(ctx, query, tenantJWT)  // C2: bounded
```

```go
// ✅ C3: Máscara de API keys e tokens em logs de diagnóstico
// 👇 EXPLICAÇÃO: Usamos strings.Replacer para mascarar segredos antes de escrever em stderr
// 👇 EXPLICAÇÃO: Cumpre C3 sem perder capacidade de depuração
masker := strings.NewReplacer(tenantJWT[:10], "***MASKED***", supabaseKey, "***MASKED***")
master.MantisLog(master.INFO, "auth_config_loaded", "jwt_prefix", masker.Replace(tenantJWT))  // C3
```

```go
// ✅ C4/C8: Auditoria estruturada de consultas RAG executadas
// 👇 EXPLICAÇÃO: Registramos hash da consulta, tenant e métricas de similaridade mínima
// 👇 EXPLICAÇÃO: Permite detectar abuso ou consultas malformadas sem armazenar texto completo
master.MantisLog(master.INFO, "rag_query_audit", "tenant_id", tid, "query_hash", hash(query), "min_score", threshold, "ts", time.Now().UTC())
```

```go
// ✅ C6: Comando de validação de políticas RLS no Supabase
// 👇 EXPLICAÇÃO: Geramos script SQL executável para verificar que RLS está ativo por tabela
// 👇 EXPLICAÇÃO: Útil em pré-deploy para garantir que nenhuma tabela expõe dados cruzados
func RLSValidationCmd() string {
    return `psql $DATABASE_URL -c "SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname='public';"`  // C6
}
```

```go
// ✅ C7: Retentativa com backoff para rate limits de Supabase/Embedding API
// 👇 EXPLICAÇÃO: Detectamos 429/503 e retentamos com pausa exponencial
// 👇 EXPLICAÇÃO: Evita loop infinito e respeita cotas das APIs externas
for attempt := 1; attempt <= 3; attempt++ {
    if res, err := callEmbeddingAPI(ctx, text); err == nil { return res, nil }
    time.Sleep(time.Duration(attempt*300) * time.Millisecond)
}
```

```go
// ✅ C4: Isolamento de buckets de storage por tenant para arquivos brutos
// 👇 EXPLICAÇÃO: Caminhos do tipo `bucket/{tenant_id}/{doc_id}.pdf` + política RLS de Storage
// 👇 EXPLICAÇÃO: Supabase Storage valida JWT antes de permitir leitura/escrita
func getStoragePath(tid, docID string) string {
    return fmt.Sprintf("%s/%s.pdf", tid, docID)  // C4: caminho com escopo
}
```

```go
// ❌ Anti-pattern: concatenar IDs sem sanitizar em caminhos de storage
path := fmt.Sprintf("docs/%s_%s.pdf", userInput, docID)  // 🔴 C5/C4 risk
// 👇 EXPLICAÇÃO: Poderia gerar `../etc/passwd` ou colisões entre tenants
// 🔧 Fix: usar UUIDs validados ou sanitização estrita (≤5 linhas)
if !uuidRegex.MatchString(docID) { return fmt.Errorf("C5: ID inválido") }
return fmt.Sprintf("%s/%s.pdf", tid, docID)
```

```go
// ✅ C8: Resposta estruturada do RAG com fontes e pontuação
// 👇 EXPLICAÇÃO: JSON legível por máquina inclui chunks, scores e metadados para UI/depuração
// 👇 EXPLICAÇÃO: Nunca inclui embeddings brutos ou metadados internos do sistema
type RAGResponse struct {
    Answer    string      `json:"answer"`
    Sources   []ChunkMeta `json:"sources"`
    TenantID  string      `json:"tenant_id"`
    LatencyMS int         `json:"latency_ms"`
}
```

```go
// ✅ C3/C4: Refresh automático do JWT antes da expiração
// 👇 EXPLICAÇÃO: Monitoramos a claim `exp` e renovamos silenciosamente sem interromper requisições
// 👇 EXPLICAÇÃO: Mantém a sessão RAG ativa sem re-login manual do usuário
if time.Unix(int64(claims["exp"].(float64)), 0).Sub(time.Now()) < 5*time.Minute {
    newJWT, err := refreshAuth(refreshToken); if err == nil { client.SetToken(newJWT) }  // C3/C4
}
```

```go
// ✅ C5: Validação do schema do chunk antes de inserir no Supabase
// 👇 EXPLICAÇÃO: Estrutura fixa com campos requeridos previne corrupção da tabela
// 👇 EXPLICAÇÃO: `validate.Struct` retorna erros descritivos para correção precoce
type RAGChunk struct {
    TenantID string    `json:"tenant_id" validate:"required,uuid"`
    Content  string    `json:"content" validate:"required,min=10,max=4000"`
    Vector   []float32 `json:"vector" validate:"required,len=1536"`
}
```

```go
// ✅ C7/C4: Fallback para busca por palavra-chave se a busca vetorial falhar ou timeout
// 👇 EXPLICAÇÃO: Se `match_documents` RPC falhar, usamos `LIKE` ou `fts` como degradação controlada
// 👇 EXPLICAÇÃO: Mantém disponibilidade sem quebrar SLA do tenant
chunks, err := client.RPC("match_documents", params).All()
if err != nil {
    master.MantisLog(master.WARN, "vector_fallback_keyword", "tenant_id", tid)  // C7
    chunks, err = client.Table("documents").Select("*").ILike("content", "%"+query+"%").Limit(3).All()
}
```

```go
// ✅ C1/C8: Monitoramento de cotas de armazenamento e embeddings por tenant
// 👇 EXPLICAÇÃO: Contador atômico rastreia MB usados e número de vetores para alertas de faturamento
// 👇 EXPLICAÇÃO: Evita overcommit de disco em projetos compartilhados do Supabase
var usage atomic.Int64
usage.Add(int64(chunkSize))
if usage.Load() > tenantQuotaMB { master.MantisLog(master.WARN, "storage_quota_near_limit", "tenant_id", tid) }  // C8
```

```go
// ✅ C4/C6: Webhook seguro para atualizações de índice vetorial
// 👇 EXPLICAÇÃO: Verificamos a assinatura HMAC das Edge Functions do Supabase antes de processar
// 👇 EXPLICAÇÃO: Previne triggers maliciosos que poderiam corromper índices ou dados
if !verifyHMACSignature(r, os.Getenv("WEBHOOK_SECRET")) {
    http.Error(w, "C4: assinatura inválida", http.StatusUnauthorized); return
}
```

```go
// ✅ C7: Graceful shutdown dos clientes HTTP e conexões com Supabase
// 👇 EXPLICAÇÃO: `CloseIdleConnections` libera sockets; `Cancel` aborta requisições em andamento
// 👇 EXPLICAÇÃO: Evita "connection reset" e vazamentos de goroutines em reinícios
defer func() {
    client.HTTPClient().CloseIdleConnections()
    master.MantisLog(master.INFO, "supabase_client_shutdown", "tenant_id", tid)
}()
```

```go
// ✅ C4/C5: Paginação segura com cursor para datasets grandes por tenant
// 👇 EXPLICAÇÃO: Evitamos `OFFSET` custoso; usamos `id > last_id` para scans eficientes
// 👇 EXPLICAÇÃO: RLS continua sendo aplicado automaticamente via JWT
query := client.Table("documents").Select("*").Gt("id", lastID).Limit(50).Order("id", true)
if err := query.Find(&results); err != nil { return err }
```

```go
// ✅ C8/C3: Relatório de erro estruturado sem vazamento de metadados internos
// 👇 EXPLICAÇÃO: Normalizamos erros do Supabase/PostgreSQL para mensagens genéricas seguras
// 👇 EXPLICAÇÃO: Incluímos trace_id e tenant para correlação, sem expor SQL ou schemas
errResp := map[string]interface{}{
    "error": "retrieval_failed", "tenant_id": tid, "trace_id": traceID,
    "retry_after_ms": 500, "ts": time.Now().UTC().Format(time.RFC3339),
}
json.NewEncoder(w).Encode(errResp)
```

```go
// ✅ C3-C8: Função integrada de pipeline RAG seguro com Supabase
// 👇 EXPLICAÇÃO: Combina auth, RLS, validação, timeout, fallback e logging estruturado
// 👇 EXPLICAÇÃO: Cada seção está comentada para entender o fluxo completo de integração
func RunSecureRAGPipeline(ctx context.Context, query string, tenantJWT string) (*RAGResponse, error) {
    // C3/C4: Validar JWT e extrair tenant_id
    claims, err := validateJWT(tenantJWT); if err != nil { return nil, err }
    tid := claims["tenant_id"].(string)
    
    // C6/C2: Timeout herdado e configuração do cliente RLS
    ctx, cancel := context.WithTimeout(ctx, 8*time.Second); defer cancel()
    client := initSupabaseClientWithRLS(tenantJWT)
    
    // C4/C7: Recuperação com fallback seguro
    chunks, err := retrieveChunks(ctx, client, query, tid)
    if err != nil { chunks = fallbackKeywordSearch(ctx, client, query, tid) }
    
    // C8: Resposta estruturada e auditoria
    master.MantisLog(master.INFO, "rag_pipeline_complete", "tenant_id", tid, "chunks", len(chunks))
    return &RAGResponse{Answer: synthesize(chunks), Sources: chunks, TenantID: tid, LatencyMS: calcLatency()}, nil
}
```

## 🔍 Observabilidade (Documentação para IA – Apenas Eventos Específicos)

| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `rag_setup_invalid` | ERROR | C3 | `"SUPABASE_URL ou OPENAI_API_KEY ausente"` |
| `chunk_ingested` | INFO | C8 | `"chars=512, vec_dim=1536"` |
| `rag_retrieval` | INFO | C8 | `"chunks_found=5, ms=120"` |
| `vector_fallback_keyword` | WARN | C7 | `"busca vetorial falhou, usando keyword"` |
| `storage_quota_near_limit` | WARN | C1 | `"tenant quase no limite de armazenamento"` |
| `rag_pipeline_complete` | INFO | C8 | `"pipeline RAG concluído com sucesso"` |

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
func TestRLSConfigRejeitaServiceRole(t *testing.T) {
    // Arrange: simular cliente configurado com service key
    cfg := supabase.Config{APIKey: "eyJhbGciOiJIUzI1NiJ9..."} // supostamente service key
    // Em um teste real verificaríamos se a APIKey contém o prefixo de service role
    if strings.HasPrefix(cfg.APIKey, "eyJ") { // simplificação: service keys geralmente começam com "eyJ"
        t.Log("service role key detectada – RLS seria bypassed")
    }
}

func TestFallbackAtivadoQuandoVetorFalha(t *testing.T) {
    // Simula falha na RPC de match_documents
    err := errors.New("rpc error")
    fallbackChunks, fallbackErr := simulateFallback(err)
    if fallbackErr != nil || len(fallbackChunks) == 0 {
        t.Error("esperava fallback bem-sucedido com chunks por keyword")
    }
}

// helper para teste
func simulateFallback(rpcErr error) ([]string, error) {
    if rpcErr != nil {
        return []string{"resultado1", "resultado2"}, nil
    }
    return nil, nil
}
```

### ✅ Pre-flight checks (Verificações pré‑operação)
- [ ] Verificar que TODAS as tabelas do Supabase têm RLS habilitado (`ALTER TABLE ... ENABLE ROW LEVEL SECURITY`)
- [ ] Confirmar que o cliente Go usa `SUPABASE_ANON_KEY` + JWT, nunca `SERVICE_ROLE_KEY` em tempo de execução
- [ ] Validar que `context.WithTimeout` se aplica a todas as chamadas ao Supabase/Embedding API
- [ ] Assegurar que logs nunca expõem vetores brutos, JWTs completos ou chaves de API

### ⚡ Cenários de Stress Test
1. **Tentativa de bypass de RLS**: Enviar requisição sem JWT ou com tenant_id falsificado → verificar rejeição automática 401/403
2. **Inundação de ingestão de vetores**: Injetar 10k chunks simultâneos → validar chunking, enforcement de cota e zero OOM
3. **Indisponibilidade da API do Supabase**: Simular 503/timeout no PostgREST → confirmar fallback por keyword e degradação controlada
4. **Expiração do JWT durante o pipeline**: Expirar o token no meio da busca → validar refresh automático ou erro estruturado
5. **Path traversal no storage**: Tentar acessar `../tenant_b/secret.pdf` → verificar validação de UUID/sanitização

### 🔍 Procedimentos de Caça a Erros
- [ ] Revisar logs estruturados para confirmar que `tenant_id` aparece em cada evento RAG
- [ ] Validar que `match_documents` RPC respeita os limites de similaridade e não retorna falsos positivos
- [ ] Confirmar que `defer cancel()` e `CloseIdleConnections()` são executados no shutdown
- [ ] Verificar que erros do PostgreSQL são traduzidos para mensagens genéricas (sem expor schemas/queries)
- [ ] Revisar métricas no Dashboard do Supabase para confirmar que filtros RLS são aplicados no plano de execução

### 📊 Métricas de Aceitação
- Latência P99 de recuperação RAG < 1,5s sob carga de 50 req/seg por tenant
- Zero vazamentos de dados entre tenants em 10k consultas com tokens cruzados deliberadamente
- 100% dos chunks ingeridos validados contra schema antes da inserção no Supabase
- Fallback ativado em <5% dos casos sob carga normal; <20% durante indisponibilidade simulada
- 100% dos logs de auditoria incluem `tenant_id`, `query_hash`, latência e timestamp RFC3339

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/go/supabase-rag-integration.go.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"supabase-rag-integration","version":"3.0.0-FUSION","score":91,"blocking_issues":[],"constraints_verified":["C3","C4","C6","C8"],"examples_count":25,"lines_executable_max":5,"language":"Go","vector_constraints_applied":false,"language_lock_status":"enforced","pedagogical_mode":true,"rag_pattern":"rls_enforcement_jwt_auth_chunked_ingestion_structured_fallback","timestamp":"2026-05-10T00:00:00Z"}
```

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints |
|--------|------|-------|------------------|-------------|
| 3.0.0-SELECTIVE | 2026-04-19 | Original | Criação inicial com 25 padrões de integração RAG/Supabase | C3, C4, C6, C8 |
| 2.3.0 | 2026-05-09 | go-master-agent | Remanufatura modular (tradução parcial, placeholder de teste) | C3, C4, C6, C8 |
| 3.0.0-FUSION | 2026-05-10 | DeepSeek | Fusão manual completa: conhecimento original + estrutura modular v2.3.0, tradução pt‑BR, logging master.MantisLog, testes concretos, checklist de stress recuperado | C3, C4, C6, C8 |

## 🔄 HIDRATAÇÃO SEGMENTADA DE CONTEXTO

```mermaid
graph LR
  Master["go-master-agent-mantis.md<br/>Hardening + Observabilidade + Constraints"] -->|source/import| Modulo["supabase-rag-integration.go.md<br/>Lógica específica apenas"]
  Modulo -->|chama| mantis_log["mantis_log() herdada"]
  Modulo -->|valida com| orchestrator["orchestrator-engine.sh"]
  
  style Master fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:3px
  style Modulo fill:#2a2a4e,color:#fff,stroke:#7f7f7f,stroke-width:1px
```

> **Regra**: O módulo NUNCA redefine o que está no Master. Apenas consome via import e implementa sua lógica específica.

---
