---
artifact_id: "mcp-typescript-node-implementation"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/mcp-typescript-node-implementation.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/mcp-typescript-node-implementation.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:mcp-ts-node-v1.0.0"
generated_at: "2026-05-25T04:30:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["langchain-dependencies-management", "deploy-docker"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🟦 MCP TypeScript/Node.js Implementation – Servidores e Clientes com SDK JS

> **Contrato modular**: Guia completo para implementar servidores e clientes MCP usando o SDK oficial para Node.js/TypeScript, integrando com LangChain.js e ferramentas zod para schema.

---

## 🎯 Propósito
Permitir que o ecossistema MANTIS utilize a stack TypeScript para construir servidores MCP robustos e type‑safe, com suporte a transporte stdio e HTTP.

## 📋 Especificação (SDD)
- **Entradas**: Definição de ferramentas, recursos e prompts em TypeScript.
- **Saídas**: Servidor MCP em execução.
- **Side Effects**: Processos Node.js.
- **Constraints Aplicáveis**: C1 (tipagem estrita), C3 (não expor secrets), C5 (schema zod), C7 (tratamento de erros), C8 (logs via stderr).
- **Dependências**: `@modelcontextprotocol/sdk`, `zod`, `typescript`.

---

## 🛡️ Bootstrap (C3+C8)
```typescript
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

// Logger seguro: sempre stderr
function mantisLog(level: string, event: string, detail: string) {
    const entry = { ts: new Date().toISOString(), level, event, detail };
    console.error(JSON.stringify(entry));
}
```

### 1. Servidor Mínimo com Ferramenta
```typescript
const server = new McpServer({ name: "MANTIS Tools", version: "1.0.0" });

server.registerTool(
    "ping",
    { description: "Verifica se o servidor está ativo" },
    async () => {
        mantisLog("INFO", "ping", "Ferramenta chamada");
        return { content: [{ type: "text", text: "pong" }] };
    }
);

async function main() {
    const transport = new StdioServerTransport();
    await server.connect(transport);
    console.error("MCP Server running on stdio");
}
main();
```

### 2. Ferramenta com Schema Zod
```typescript
server.registerTool(
    "add",
    {
        description: "Soma dois números",
        inputSchema: {
            a: z.number().describe("Primeiro número"),
            b: z.number().describe("Segundo número"),
        },
    },
    async ({ a, b }) => {
        const result = a + b;
        mantisLog("INFO", "add", `${a}+${b}=${result}`);
        return { content: [{ type: "text", text: String(result) }] };
    }
);
```

### 3. Recursos e Prompts
```typescript
server.registerResource(
    "config://app",
    "Configuração da aplicação",
    async () => ({
        contents: [{ uri: "config://app", text: JSON.stringify({ version: "1.0.0" }) }],
    })
);

server.registerPrompt(
    "code_review",
    {
        description: "Template para revisão de código",
        arguments: {
            language: z.string().describe("Linguagem"),
            focus: z.string().optional().default("security"),
        },
    },
    async ({ language, focus }) => ({
        messages: [
            { role: "system", content: `Você é um revisor ${language}.` },
            { role: "user", content: `Revise o código com foco em ${focus}.` },
        ],
    })
);
```

### 4. Transporte HTTP (Streamable)
- Requer um wrapper HTTP; a SDK oficial fornece `StreamableHTTPServerTransport`.
- Exemplo conceitual:
```typescript
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import express from "express";

const app = express();
app.post("/mcp", async (req, res) => {
    // Configurar transporte streamable...
});
app.listen(8000);
```

### 5. Cliente MCP (TypeScript)
```typescript
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";

const transport = new StdioClientTransport({
    command: "node",
    args: ["build/server.js"],
});
const client = new Client({ name: "MANTIS Client", version: "1.0.0" });
await client.connect(transport);

const tools = await client.listTools();
console.log(tools);
```

### 6. Integração com LangChain.js
```typescript
import { MultiServerMCPClient } from "@langchain/mcp-adapters";
import { createAgent } from "langchain";

const client = new MultiServerMCPClient({
    math: { transport: "stdio", command: "node", args: ["math_server.js"] },
});
const tools = await client.getTools();
const agent = createAgent({ model: "openai:gpt-4.1", tools });
```

---

## 🧪 Testes Unitários (TDD)
```typescript
import { describe, it } from "node:test";
import assert from "node:assert";

describe("Ferramenta add", () => {
    it("deve somar corretamente", async () => {
        // Teste com mock do servidor...
    });
});
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/mcp-typescript-node-implementation.md --json
```

---

## 🔗 Referências Cruzadas
- [[mcp-server-fundamentals.md]]
- [[langchain-dependencies-management.md]]
