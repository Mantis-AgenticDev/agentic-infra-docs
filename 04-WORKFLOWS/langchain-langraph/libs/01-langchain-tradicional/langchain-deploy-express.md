---
artifact_id: "langchain-deploy-express"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/langchain-deploy-express.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/langchain-deploy-express.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:langchain-deploy-express-v1.0.0"
generated_at: "2026-05-26T16:15:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["langchain-deploy-langserve"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-26"
---

# 🌐 LangChain Deploy – Express API (Node.js/TypeScript)

> **Contrato modular**: Artefato filho do Master Agent. Ensina a expor chains e agentes LangChain como APIs REST usando Express em Node.js/TypeScript, com streaming SSE, health checks e Docker.

---

## 🎯 Propósito
Permitir que equipes MANTIS que usam Node.js publiquem chains como serviços web, com suporte a streaming e monitoramento.

## 📋 Especificação (SDD)
- **Entradas**: Chains compiladas, modelo.
- **Saídas**: Servidor Express com endpoints REST e SSE.
- **Side Effects**: Execução no servidor.
- **Constraints Aplicáveis**: C1 (schema), C3 (secrets), C5 (health), C7 (retry), C8 (logs).
- **Dependências**: `express`, `@langchain/core`, `@langchain/openai`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```typescript
function mantisLog(level: string, event: string, detail: string) {
    console.error(JSON.stringify({ ts: new Date().toISOString(), level, event, detail }));
}
```

### 1. Servidor Express com Chain

```typescript
import express from "express";
import { ChatOpenAI } from "@langchain/openai";
import { ChatPromptTemplate } from "@langchain/core/prompts";
import { StringOutputParser } from "@langchain/core/output_parsers";

const app = express();
app.use(express.json());

const model = new ChatOpenAI({ modelName: "gpt-4o-mini" });
const chain = ChatPromptTemplate.fromTemplate("Resuma: {text}")
    .pipe(model).pipe(new StringOutputParser());

app.post("/api/summarize", async (req, res) => {
    try {
        const result = await chain.invoke({ text: req.body.text });
        res.json({ result });
    } catch (error: any) {
        mantisLog("ERROR", "summarize_failed", error.message);
        res.status(500).json({ error: error.message });
    }
});
```

### 2. Streaming Endpoint (SSE)

```typescript
app.post("/api/summarize/stream", async (req, res) => {
    res.setHeader("Content-Type", "text/event-stream");
    res.setHeader("Cache-Control", "no-cache");

    const stream = await chain.stream({ text: req.body.text });
    for await (const chunk of stream) {
        res.write(`data: ${JSON.stringify({ chunk })}\n\n`);
    }
    res.write("data: [DONE]\n\n");
    res.end();
});
```

### 3. Health Check com Verificação de LLM

```typescript
app.get("/health", async (_req, res) => {
    const checks: Record<string, string> = { server: "ok" };
    try {
        await model.invoke("ping");
        checks.llm = "ok";
    } catch (e: any) {
        checks.llm = `error: ${e.message}`;
    }
    const allOk = Object.values(checks).every((v) => v === "ok");
    res.status(allOk ? 200 : 503).json({ status: allOk ? "healthy" : "degraded", checks });
});
```

### 4. Dockerfile Multi‑Stage

```dockerfile
FROM node:20-slim AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --production=false
COPY . .
RUN npm run build

FROM node:20-slim
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=5s CMD curl -f http://localhost:8000/health || exit 1
CMD ["node", "dist/server.js"]
```

---

## 🧪 Testes Unitários (TDD)

```typescript
test("health endpoint", async () => {
    const response = await fetch("http://localhost:8000/health");
    expect(response.status).toBe(200);
});
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/langchain-deploy-express.md --json
```

---

## 🔗 Referências Cruzadas
- [[langchain-deploy-langserve.md]]
