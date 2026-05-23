---
artifact_id: "runtimes-antigravity-protocol"
artifact_type: "protocol"
version: "2.0.0"
canonical_path: "runtimes/antigravity/MANTIS-PROTOCOL.md"
language: "pt-BR"
status: "✅ Estável"
---
# Protocolo MANTIS – Antigravity

## Conexión
Antigravity se conecta al ecosistema MANTIS a través de `connector.py`.

## Handshake
1. Lee `registry.db` para obtener metas activas.
2. Usa `PromptBuilder` para generar un prompt mínimo.
3. Escribe su progreso en `agent-db/runtime/antigravity-agent.db`.
4. Al finalizar, genera `status.json` con `HandoffPackage` y libera la meta.

## Rate Limits
- Sprint: 5 horas (20-25 requests). Si se agota, pausar 5h 10m.
- Marathon (Pro): 7 días. Si se agota, pausar hasta el lunes siguiente 00:00 UTC.
