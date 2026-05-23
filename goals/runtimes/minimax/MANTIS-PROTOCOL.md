---
artifact_id: "runtimes-minimax-protocol"
artifact_type: "protocol"
version: "2.0.0"
canonical_path: "runtimes/minimax/MANTIS-PROTOCOL.md"
language: "pt-BR"
status: "✅ Estável"
---
# Protocolo MANTIS – Minimax

## Conexión
Minimax se conecta al ecosistema MANTIS a través de `connector.py`.

## Handshake
1. Lee `registry.db` para obtener metas activas.
2. Usa `PromptBuilder` para generar un prompt mínimo.
3. Escribe su progreso en `agent-db/runtime/minimax-agent.db`.
4. Al finalizar, genera `status.json` con `HandoffPackage` y libera la meta.

## Rate Limits
Minimax recarga diariamente a las 00:00 hora de Beijing (16:00 UTC). Si se excede, pausar y calcular `next_wakeup` a las 18:00 UTC del mismo día.
