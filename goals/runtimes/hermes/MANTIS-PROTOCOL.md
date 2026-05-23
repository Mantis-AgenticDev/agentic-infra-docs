---
artifact_id: "runtimes-hermes-protocol"
artifact_type: "protocol"
version: "2.0.0"
canonical_path: "runtimes/hermes/MANTIS-PROTOCOL.md"
language: "pt-BR"
status: "✅ Estável"
---
# Protocolo MANTIS – Hermes

## Conexión
Hermes se conecta al ecosistema MANTIS a través del `connector.py`, que traduce metas del `registry.db` a skills de Hermes y viceversa.

## Handshake
1. Hermes lee `registry.db` para obtener metas activas asignadas.
2. Cada meta se convierte en un prompt con `PromptBuilder` (libs/prompt_builder.py).
3. Hermes ejecuta la skill correspondiente al agente asignado.
4. Al finalizar, `HandoffPackage` escribe el `status.json` C9 y actualiza el registry.

## Rate Limits
Respetar `rate_limit` de config.yaml. Si se excede, pausar la meta y calcular `next_wakeup` con `QuotaParser`.

## Skills
Cada agente MANTIS debe tener un archivo YAML en `skills/` describiendo su capacidad.
