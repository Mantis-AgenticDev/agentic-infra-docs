---
artifact_id: "mcp-go-implementation"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/mcp-go-implementation.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/mcp-go-implementation.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:mcp-go-v1.0.0"
generated_at: "2026-05-25T04:40:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deploy-docker", "deploy-kubernetes"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🐹 MCP Go Implementation – Servidores com o SDK Go

> **Contrato modular**: Guia prático para construir servidores MCP em Go usando o SDK oficial `github.com/modelcontextprotocol/go-sdk/mcp`, com ferramentas, recursos e transporte stdio.

---

## 🎯 Propósito
Habilitar a criação de servidores MCP de alta performance em Go, aproveitando tipagem forte e concorrência nativa, para o ecossistema MANTIS.

## 📋 Especificação (SDD)
- **Entradas**: Estruturas de ferramentas, função handler.
- **Saídas**: Servidor MCP compilado.
- **Side Effects**: Processo em execução.
- **Constraints Aplicáveis**: C1 (tipos e contratos), C3 (segurança), C5 (schema), C7 (timeout e cancelamento), C8 (logs).
- **Dependências**: `go 1.24+`, `github.com/modelcontextprotocol/go-sdk/mcp`.

---

## 🛡️ Bootstrap (C3+C8)
```go
package main

import (
    "context"
    "encoding/json"
    "log"
    "os"
)

func mantisLog(level, event, detail string) {
    entry := map[string]string{
        "ts":     time.Now().UTC().Format(time.RFC3339),
        "level":  level,
        "event":  event,
        "detail": detail,
        "tenant": os.Getenv("TENANT_ID"),
    }
    b, _ := json.Marshal(entry)
    log.Println(string(b))  // log printa para stderr
}
```

### 1. Servidor Mínimo
```go
package main

import (
    "context"
    "log"
    "github.com/modelcontextprotocol/go-sdk/mcp"
)

func main() {
    server := mcp.NewServer(&mcp.Implementation{
        Name:    "MANTIS Go Server",
        Version: "1.0.0",
    }, nil)

    mcp.AddTool(server, &mcp.Tool{
        Name:        "ping",
        Description: "Verifica se o servidor está ativo",
    }, func(ctx context.Context, req *mcp.CallToolRequest) (*mcp.CallToolResult, any, error) {
        return &mcp.CallToolResult{
            Content: []mcp.Content{&mcp.TextContent{Text: "pong"}},
        }, nil, nil
    })

    if err := server.Run(context.Background(), &mcp.StdioTransport{}); err != nil {
        log.Fatal(err)
    }
}
```

### 2. Ferramenta com Parâmetros Tipados
```go
type AddInput struct {
    A int `json:"a" jsonschema:"Primeiro número"`
    B int `json:"b" jsonschema:"Segundo número"`
}

mcp.AddTool(server, &mcp.Tool{
    Name:        "add",
    Description: "Soma dois números",
}, func(ctx context.Context, req *mcp.CallToolRequest, input AddInput) (*mcp.CallToolResult, any, error) {
    result := input.A + input.B
    mantisLog("INFO", "add", fmt.Sprintf("%d+%d=%d", input.A, input.B, result))
    return &mcp.CallToolResult{
        Content: []mcp.Content{&mcp.TextContent{Text: strconv.Itoa(result)}},
    }, nil, nil
})
```

### 3. Recursos
```go
type Config struct {
    Version string `json:"version"`
    Mode    string `json:"mode"`
}

server.RegisterResource(mcp.Resource{
    URI:         "config://app",
    Name:        "Configuração",
    Description: "Configuração da aplicação",
}, func(ctx context.Context, req *mcp.ReadResourceRequest) (*mcp.ReadResourceResult, error) {
    config := Config{Version: "1.0.0", Mode: os.Getenv("MODE")}
    data, _ := json.Marshal(config)
    return &mcp.ReadResourceResult{
        Contents: []mcp.ResourceContent{
            &mcp.TextResourceContent{
                ResourceContent: mcp.ResourceContent{URI: "config://app"},
                Text:            string(data),
            },
        },
    }, nil
})
```

### 4. Tratamento de Erros e Timeout
```go
func resilientHandler(ctx context.Context, req *mcp.CallToolRequest) (*mcp.CallToolResult, error) {
    ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
    defer cancel()

    // lógica...
    select {
    case <-ctx.Done():
        return nil, fmt.Errorf("operação cancelada: %w", ctx.Err())
    default:
        return result, nil
    }
}
```

### 5. Cliente MCP em Go
```go
import (
    "github.com/modelcontextprotocol/go-sdk/mcp"
)

client, err := mcp.NewClient(&mcp.Implementation{Name: "cli", Version: "1.0"}, &mcp.StdioClientTransport{
    Command: "go",
    Args:    []string{"run", "./server.go"},
})
defer client.Close()
tools, _ := client.ListTools(context.Background())
```

---

## 🧪 Testes Unitários (TDD)
```go
func TestAddTool(t *testing.T) {
    handler := addHandler
    req := mcp.CallToolRequest{}
    result, _, err := handler(context.Background(), &req, AddInput{A: 2, B: 3})
    if err != nil {
        t.Fatal(err)
    }
    if result.Content[0].Text != "5" {
        t.Errorf("esperado 5, obteve %s", result.Content[0].Text)
    }
}
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/mcp-go-implementation.md --json
```

---

## 🔗 Referências Cruzadas
- [[mcp-server-fundamentals.md]]
- [[deploy-kubernetes.md]]
