---
artifact_id: "runtimes-codex-protocol"
artifact_type: "protocol"
version: "2.0.0"
canonical_path: "runtimes/codex/MANTIS-PROTOCOL.md"
language: "pt-BR"
status: "✅ Estável"
---
# Protocolo MANTIS – Codex

## Conexión
Codex CLI tiene soporte nativo de goals, pero se integra con el ecosistema MANTIS a través de `connector.py`.

## Handshake
1. Codex CLI lee `registry.db` para obtener metas activas (si no usa sus propios goals).
2. Usa `PromptBuilder` para generar un prompt mínimo.
3. Escribe su progreso en `agent-db/runtime/codex-agent.db`.
4. Al finalizar, genera `status.json` con `HandoffPackage` y libera la meta.

## Rate Limits
Codex usa los límites de OpenAI (ChatGPT Plus/Pro). Si se agota la cuota, pausar y calcular `next_wakeup` con `QuotaParser`.
