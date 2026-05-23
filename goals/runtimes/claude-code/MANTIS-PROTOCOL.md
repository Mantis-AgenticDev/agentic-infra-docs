---
artifact_id: "runtimes-claude-code-protocol"
artifact_type: "protocol"
version: "2.0.0"
canonical_path: "runtimes/claude-code/MANTIS-PROTOCOL.md"
language: "pt-BR"
status: "✅ Estável"
---
# Protocolo MANTIS – Claude Code

## Conexión
Claude Code se conecta al ecosistema MANTIS a través de `connector.py` o directamente vía MCP (`goals/scripts/mcp_server.py`).

## Handshake
1. Lee `registry.db` para obtener metas activas.
2. Usa `PromptBuilder` para generar un prompt mínimo.
3. Escribe su progreso en `agent-db/runtime/claude-code-agent.db`.
4. Al finalizar, genera `status.json` con `HandoffPackage` y libera la meta.

## Rate Limits
Claude recarga diariamente a las 00:00 UTC. Si se excede, pausar y calcular `next_wakeup` a las 00:30 UTC del día siguiente.
