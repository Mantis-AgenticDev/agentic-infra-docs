---
artifact_id: "runtimes-qwen-protocol"
artifact_type: "protocol"
version: "2.0.0"
canonical_path: "runtimes/qwen/MANTIS-PROTOCOL.md"
language: "pt-BR"
status: "✅ Estável"
---
# Protocolo MANTIS – Qwen

## Conexión
Qwen se conecta al ecosistema MANTIS a través de `connector.py`.

## Handshake
1. Lee `registry.db` para obtener metas activas.
2. Usa `PromptBuilder` para generar un prompt mínimo.
3. Escribe su progreso en `agent-db/runtime/qwen-agent.db`.
4. Al finalizar, genera `status.json` con `HandoffPackage` y libera la meta.

## Rate Limits
Qwen recarga diariamente a las 00:00 UTC. Si se agota la cuota, pausar la meta y establecer `next_wakeup` con `QuotaParser`.
