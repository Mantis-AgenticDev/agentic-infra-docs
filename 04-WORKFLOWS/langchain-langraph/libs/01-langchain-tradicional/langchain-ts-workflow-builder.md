---
artifact_id: "langchain-ts-workflow-builder"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/langchain-ts-workflow-builder.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/langchain-ts-workflow-builder.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:langchain-ts-workflow-builder-v1.0.0"
generated_at: "2026-05-26T17:30:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["langchain-ts-agents-tools"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-26"
---

# 🟦 LangChain TypeScript – Workflow Builder (Chains, Memória e RAG)

> **Contrato modular**: Artefato filho do Master Agent. Implementa chains, memória e RAG do LangChain em TypeScript/Node.js, com LCEL, RunnableSequence, RunnableBranch e streaming.

---

## 🎯 Propósito
Permitir que equipes MANTIS que usam Node.js construam pipelines de LLM tradicionais com tipagem forte e todos os padrões de composição.

## 📋 Especificação (SDD)
- **Entradas**: Modelos `@langchain/openai`, prompts, parsers.
- **Saídas**: Chains executáveis.
- **Side Effects**: Chamadas de API.
- **Constraints Aplicáveis**: C1 (tipagem Zod), C3 (secrets), C5 (schema), C7 (retry), C8 (logs).
- **Dependências**: `@langchain/core`, `@langchain/openai`, `zod`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```typescript
function mantisLog(level: string, event: string, detail: string) {
    console.error(JSON.stringify({ ts: new Date().toISOString(), level, event, detail }));
}
```

### 1. Simple LLM Chain

```typescript
import { ChatOpenAI } from "@langchain/openai";
import { ChatPromptTemplate } from "@langchain/core/prompts";
import { StringOutputParser } from "@langchain/core/output_parsers";

const model = new ChatOpenAI({ modelName: "gpt-4-turbo-preview", temperature: 0.7 });
const prompt = ChatPromptTemplate.fromMessages([
    ["system", "You are a helpful assistant that {task}."],
    ["human", "{input}"],
]);
const chain = prompt.pipe(model).pipe(new StringOutputParser());

const result = await chain.invoke({ task: "summarizes text concisely", input: "Summarize this article: ..." });
```

### 2. Sequential Chain (RunnableSequence)

```typescript
import { RunnableSequence } from "@langchain/core/runnables";

const extractChain = ChatPromptTemplate.fromTemplate("Extract key points: {text}")
    .pipe(model).pipe(new StringOutputParser());
const summarizeChain = ChatPromptTemplate.fromTemplate("Summarize key points: {keyPoints}")
    .pipe(model).pipe(new StringOutputParser());

const fullChain = RunnableSequence.from([
    { keyPoints: extractChain, originalText: (input: any) => input.text },
    { summary: summarizeChain, keyPoints: (input: any) => input.keyPoints },
]);

const result = await fullChain.invoke({ text: "Long article..." });
```

### 3. Branching Chain

```typescript
import { RunnableBranch } from "@langchain/core/runnables";

const classifyChain = ChatPromptTemplate.fromTemplate("Classify: {query} as question, complaint, or feedback")
    .pipe(model).pipe(new StringOutputParser());

const questionChain = ChatPromptTemplate.fromTemplate("Answer: {query}").pipe(model).pipe(new StringOutputParser());
const complaintChain = ChatPromptTemplate.fromTemplate("Empathize: {query}").pipe(model).pipe(new StringOutputParser());

const routingChain = RunnableSequence.from([
    { classification: classifyChain, query: (input: any) => input.query },
    RunnableBranch.from([
        [(input: any) => input.classification.includes("question"), questionChain],
        [(input: any) => input.classification.includes("complaint"), complaintChain],
        ChatPromptTemplate.fromTemplate("Thanks: {query}").pipe(model).pipe(new StringOutputParser()),
    ]),
]);

const answer = await routingChain.invoke({ query: "What is the return policy?" });
```

### 4. RAG com Vector Store

```typescript
import { PineconeStore } from "@langchain/pinecone";
import { OpenAIEmbeddings } from "@langchain/openai";
import { createRetrievalChain } from "langchain/chains/retrieval";
import { createStuffDocumentsChain } from "langchain/chains/combine_documents";

const embeddings = new OpenAIEmbeddings();
const vectorStore = await PineconeStore.fromExistingIndex(embeddings, { pineconeIndex: index });
const retriever = vectorStore.asRetriever({ k: 5 });

const combineDocsChain = await createStuffDocumentsChain({ llm: model, prompt });
const ragChain = await createRetrievalChain({ retriever, combineDocsChain });

const result = await ragChain.invoke({ input: "What is our refund policy?" });
```

### 5. Streaming

```typescript
const stream = await chain.stream({ task: "tells a story", input: "Tell me a story" });
for await (const chunk of stream) {
    process.stdout.write(chunk);
}
```

---

## 🧪 Testes Unitários (TDD)

```typescript
test("simple chain", async () => {
    const chain = ChatPromptTemplate.fromTemplate("Say hello").pipe(model).pipe(new StringOutputParser());
    const result = await chain.invoke({});
    expect(typeof result).toBe("string");
});
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/langchain-ts-workflow-builder.md --json
```

---

## 🔗 Referências Cruzadas
- [[langchain-ts-agents-tools.md]]
