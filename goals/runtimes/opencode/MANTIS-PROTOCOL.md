---
artifact_id: "runtimes-opencode-protocol"
artifact_type: "protocol"
version: "2.0.0"
canonical_path: "runtimes/opencode/MANTIS-PROTOCOL.md"
language: "pt-BR"
status: "✅ Estável"
---
# Protocolo MANTIS – OpenCode

## Conexión
OpenCode se conecta al ecosistema MANTIS a través de `connector.py`.

## Handshake
1. Lee `registry.db` para obtener metas activas.
2. Usa `PromptBuilder` para generar un prompt mínimo.
3. Escribe su progreso en `agent-db/runtime/opencode-agent.db`.
4. Al finalizar, genera `status.json` con `HandoffPackage` y libera la meta.

## Rate Limits
OpenCode no tiene límites propios; se rige por el proveedor subyacente. Si se usa con OpenAI, aplicar política ChatGPT.
