---
artifact_id: "langchain-ts-agents-tools"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/langchain-ts-agents-tools.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/langchain-ts-agents-tools.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:langchain-ts-agents-tools-v1.0.0"
generated_at: "2026-05-26T17:45:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["langchain-ts-workflow-builder"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-26"
---

# 🤖 LangChain TypeScript – Agentes e Ferramentas

> **Contrato modular**: Artefato filho do Master Agent. Implementa agentes LangChain em TypeScript: definição de ferramentas com Zod, `createToolCallingAgent`, `AgentExecutor`, memória conversacional e streaming de eventos.

---

## 🎯 Propósito
Permitir que equipes MANTIS usem agentes autônomos em Node.js com ferramentas validadas por schema e capacidade de manter contexto.

## 📋 Especificação (SDD)
- **Entradas**: Modelo, ferramentas, prompt.
- **Saídas**: Agente executável.
- **Side Effects**: Chamadas de ferramentas.
- **Constraints Aplicáveis**: C1 (schema Zod), C3 (secrets), C5 (resposta), C7 (limite de iterações), C8 (logs).
- **Dependências**: `langchain`, `@langchain/core`, `zod`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```typescript
function mantisLog(level: string, event: string, detail: string) {
    console.error(JSON.stringify({ ts: new Date().toISOString(), level, event, detail }));
}
```

### 1. Definição de Ferramentas com Zod

```typescript
import { tool } from "@langchain/core/tools";
import { z } from "zod";

const calculator = tool(
    async ({ expression }) => {
        try {
            const result = Function(`"use strict"; return (${expression})`)();
            return String(result);
        } catch (e) {
            return `Error: invalid expression "${expression}"`;
        }
    },
    {
        name: "calculator",
        description: "Evaluate a mathematical expression. Input: a math expression string.",
        schema: z.object({ expression: z.string().describe("Math expression like '2 + 2'") }),
    },
);

const weatherLookup = tool(
    async ({ city }) => {
        const data: Record<string, string> = { "New York": "72F, sunny", "London": "58F, cloudy" };
        return data[city] ?? `No weather data for ${city}`;
    },
    {
        name: "weather",
        description: "Get current weather for a city.",
        schema: z.object({ city: z.string().describe("City name") }),
    },
);

const tools = [calculator, weatherLookup];
```

### 2. Criação do Agente com AgentExecutor

```typescript
import { ChatOpenAI } from "@langchain/openai";
import { createToolCallingAgent, AgentExecutor } from "langchain/agents";
import { ChatPromptTemplate, MessagesPlaceholder } from "@langchain/core/prompts";

const llm = new ChatOpenAI({ modelName: "gpt-4o-mini" });
const prompt = ChatPromptTemplate.fromMessages([
    ["system", "You are a helpful assistant. Use tools when needed."],
    new MessagesPlaceholder("chat_history"),
    ["human", "{input}"],
    new MessagesPlaceholder("agent_scratchpad"),
]);

const agent = createToolCallingAgent({ llm, tools, prompt });
const executor = new AgentExecutor({
    agent,
    tools,
    verbose: true,
    maxIterations: 10,
    returnIntermediateSteps: true,
});

const result = await executor.invoke({
    input: "What's 25 * 4, and what's the weather in Tokyo?",
    chat_history: [],
});

console.log(result.output);
// "25 * 4 = 100. The weather in Tokyo is 80F and humid."
```

### 3. Agente com Memória Conversacional

```typescript
import { ChatMessageHistory } from "@langchain/community/stores/message/in_memory";
import { RunnableWithMessageHistory } from "@langchain/core/runnables";

const messageHistory = new ChatMessageHistory();
const agentWithHistory = new RunnableWithMessageHistory({
    runnable: executor,
    getMessageHistory: (_sessionId) => messageHistory,
    inputMessagesKey: "input",
    historyMessagesKey: "chat_history",
});

await agentWithHistory.invoke({ input: "My name is Alice" }, { configurable: { sessionId: "user-1" } });
const res = await agentWithHistory.invoke({ input: "What's my name?" }, { configurable: { sessionId: "user-1" } });
console.log(res.output); // "Your name is Alice!"
```

### 4. Streaming de Eventos do Agente

```typescript
const eventStream = executor.streamEvents(
    { input: "Calculate 15% tip on $85", chat_history: [] },
    { version: "v2" },
);

for await (const event of eventStream) {
    if (event.event === "on_chat_model_stream") {
        process.stdout.write(event.data.chunk.content ?? "");
    } else if (event.event === "on_tool_start") {
        console.log(`\n[Calling tool: ${event.name}]`);
    } else if (event.event === "on_tool_end") {
        console.log(`[Tool result: ${event.data.output}]`);
    }
}
```

### 5. Bind Direto de Ferramentas

```typescript
import { HumanMessage } from "@langchain/core/messages";

const modelWithTools = llm.bindTools(tools);
const response = await modelWithTools.invoke([new HumanMessage("What's 42 * 17?")]);

if (response.tool_calls && response.tool_calls.length > 0) {
    for (const tc of response.tool_calls) {
        console.log(`Tool: ${tc.name}, Args: ${JSON.stringify(tc.args)}`);
        const toolResult = await tools.find((t) => t.name === tc.name)!.invoke(tc.args);
        console.log(`Result: ${toolResult}`);
    }
}
```

### 6. Troubleshooting

```typescript
// ❌ Max iterations reached → increase maxIterations or improve system prompt.
// ❌ Tool not found → verify tools array passed to both createToolCallingAgent and AgentExecutor.
// ❌ Missing agent_scratchpad → add new MessagesPlaceholder("agent_scratchpad").
```

---

## 🧪 Testes Unitários (TDD)

```typescript
test("calculator tool", async () => {
    const result = await calculator.invoke({ expression: "2 + 2" });
    expect(result).toContain("4");
});
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/langchain-ts-agents-tools.md --json
```

---

## 🔗 Referências Cruzadas
- [[langchain-ts-workflow-builder.md]]
