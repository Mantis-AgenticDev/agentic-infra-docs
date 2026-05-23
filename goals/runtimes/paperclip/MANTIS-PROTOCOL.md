---
artifact_id: "runtimes-paperclip-protocol"
artifact_type: "protocol"
version: "2.0.0"
canonical_path: "runtimes/paperclip/MANTIS-PROTOCOL.md"
language: "pt-BR"
status: "✅ Estável"
---
# Protocolo MANTIS – Paperclip

## Conexión
Paperclip se conecta al ecosistema MANTIS a través de `connector.py`.

## Handshake
1. Lee `registry.db` para obtener metas activas del equipo de documentación.
2. Divide la meta en sub-tareas para los agentes docs usando el `team_orchestrator.py` (Fase 6).
3. Cada agente docs escribe en su propia DB y genera su `status.json`.
4. Paperclip consolida los resultados y libera la meta principal.

## Rate Limits
Paperclip se rige por el proveedor subyacente (Antigravity/Google).
