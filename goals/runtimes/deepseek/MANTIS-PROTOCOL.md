---
artifact_id: "runtimes-deepseek-protocol"
artifact_type: "protocol"
version: "2.0.0"
canonical_path: "runtimes/deepseek/MANTIS-PROTOCOL.md"
language: "pt-BR"
status: "✅ Estável"
---
# Protocolo MANTIS – DeepSeek

## Conexión
DeepSeek se conecta al ecosistema MANTIS a través de `connector.py`, que traduce metas del `registry.db` a prompts y viceversa.

## Handshake
1. DeepSeek lee `registry.db` para obtener metas activas asignadas a `deepseek-web`.
2. Cada meta se convierte en un prompt mínimo con `PromptBuilder`.
3. DeepSeek ejecuta la tarea y escribe su progreso en `agent-db/runtime/deepseek-web.db`.
4. Al finalizar, `HandoffPackage` escribe el `status.json` C9 y actualiza el registry.

## Rate Limits
DeepSeek recarga diariamente a las 00:00 UTC. Si se excede, pausar la meta y calcular `next_wakeup` con `QuotaParser`.

## Observaciones
DeepSeek actúa como auditor del ecosistema. Tiene acceso de lectura a todas las bases para generar informes, pero nunca escribe en bases ajenas.
