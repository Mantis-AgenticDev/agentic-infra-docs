---
artifact_id: "mcp-advanced-features"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/mcp-advanced-features.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/mcp-advanced-features.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:mcp-advanced-v1.0.0"
generated_at: "2026-05-25T01:30:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["tools-mcp-integration", "rag-multi-modal"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🚀 MCP Advanced Features – Conteúdo Estruturado, Elicitação e Multimodal

> **Contrato modular**: Explora recursos avançados do MCP: `structuredContent`, elicitação (`ctx.elicit`), conteúdo multimodal e notificações de progresso.

---

## 🎯 Propósito
Habilitar interações mais ricas entre agentes e servidores MCP, incluindo dados estruturados, solicitações de input adicional e manipulação de imagens.

## 📋 Especificação (SDD)
- **Entradas**: Ferramentas MCP que retornam artefatos, prompts de elicitação, conteúdo multimodal.
- **Saídas**: Respostas enriquecidas e processamento de input do usuário.
- **Constraints**: C1 (schema), C5 (preservação de dados), C7 (tratamento de erros), C8 (logs).
- **Dependências**: `langchain-mcp-adapters`, `mcp`.

---

## 🛡️ Bootstrap (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Extraindo Structured Content
```python
result = await agent.ainvoke({"messages": [{"role": "user", "content": "get data"}]})
for msg in result["messages"]:
    if isinstance(msg, ToolMessage) and msg.artifact:
        structured = msg.artifact["structured_content"]
        mantis_log("INFO", "structured_content", f"Recebido: {structured}")
```

### 2. Interceptor para Appending de Structured Content
```python
async def append_structured(request: MCPToolCallRequest, handler):
    result = await handler(request)
    if result.structuredContent:
        result.content += [TextContent(type="text", text=json.dumps(result.structuredContent))]
    return result
```

### 3. Elicitação – Servidor Pede Mais Dados
```python
# Servidor
@mcp.tool()
async def create_profile(name: str, ctx: Context) -> str:
    result = await ctx.elicit(
        message=f"Forneça detalhes para {name}",
        schema=UserDetails
    )
    if result.action == "accept" and result.data:
        return f"Perfil criado: {result.data}"
    return "Criação cancelada."
```

```python
# Cliente – configurar callback
async def on_elicitation(mcp_context, params, context):
    # Em produção, solicitaria input do usuário
    return ElicitResult(action="accept", content={"email": "user@example.com", "age": 30})

client = MultiServerMCPClient({...}, callbacks=Callbacks(on_elicitation=on_elicitation))
```

### 4. Conteúdo Multimodal (Imagens)
```python
# Acessar blocos padronizados
for msg in result["messages"]:
    if msg.type == "tool":
        for block in msg.content_blocks:
            if block["type"] == "image":
                img_url = block.get("url") or block.get("base64")
                mantis_log("INFO", "image_received", f"Imagem de {len(img_url)} bytes")
```

### 5. Progresso e Logging do Servidor
```python
async def on_progress(progress, total, message, context):
    mantis_log("INFO", "progress", f"{context.server_name}/{context.tool_name}: {message} ({progress}/{total})")

async def on_logging_message(params, context):
    mantis_log(params.level, "mcp_server_log", f"[{context.server_name}] {params.data}")

client = MultiServerMCPClient({...}, callbacks=Callbacks(on_progress=on_progress, on_logging_message=on_logging_message))
```

---

## 🧪 Testes Unitários (TDD)
```python
# Teste de interceptor de structured content
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/mcp-advanced-features.md --json
```

---

## 🔗 Referências Cruzadas
- [[mcp-interceptors-middleware.md]]
