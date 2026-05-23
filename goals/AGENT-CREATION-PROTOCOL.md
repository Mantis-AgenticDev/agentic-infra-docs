---
artifact_id: "goals-agent-creation-protocol"
artifact_type: "protocol"
version: "2.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
canonical_path: "goals/AGENT-CREATION-PROTOCOL.md"
tier: 1
immutable: false
requires_human_approval_for_changes: true
audience: ["human-architects", "orchestrator-engine"]
language_lock: "pt-BR"
prompt_hash: "sha256:agent-creation-protocol-v2.0.0"
generated_at: "2026-05-22T10:30:00Z"
domain: "goals"
subdomain: "docs"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---

# Protocolo de Creación de Nuevos Agentes — MANTIS Agentic

Cada agente del ecosistema MANTIS debe seguir este protocolo para integrarse sin romper la arquitectura. El script `create_agent.py` (Fase 10) automatizará estos pasos.

## 1. Definir el agente

Crear un archivo de definición en el dominio correspondiente siguiendo el template `template_master-agent.md`. El frontmatter debe incluir:

```yaml
agent_role: "nombre-canónico-del-agente"
agent_specialty: "especialidad"
domain: "programming|configurations|docs|agents|workflow|runtime"
skills: ["skill1", "skill2"]
constraints_mapped: ["C1", "C9"]
```

## 2. Registrar en el ecosistema

Ejecutar `init_agent_db.py` para crear su base SQLite:

```bash
python3 goals/scripts/init_agent_db.py --agent-id <agent_id> --domain <domain>
```

Esto crea `goals/agent-db/<domain>/<agent_id>.db` con las tablas estándar.

## 3. Implementar el patrón Singleton

El agente debe usar `AgentDBManager` para acceder a su base:

```python
from goals.libs.agent_db_manager import AgentDBManager

db = AgentDBManager("mi-agente", domain="mi-dominio")
db.log_action("inicio", "Agente iniciado")
```

Nunca acceder directamente a otra base. Si necesita datos de otro agente, usar `RegistryClient` o el CEO del dominio.

## 4. Conectar con el goal registry

Usar `RegistryClient` para leer metas activas y adquirir locks:

```python
from goals.libs.registry_client import RegistryClient

registry = RegistryClient()
goal = registry.get_active_goal("goal-123")
registry.acquire_goal("goal-123", "mi-agente", expected_version=3)
```

## 5. Seguir el contrato C9

Al finalizar una meta, generar `status.json` con `HandoffPackage` y validar con `check_a2a_contract.py`.

## 6. Actualizar el runtime

Si el agente se invoca desde un runtime externo (Hermes, Codex, etc.), crear o actualizar el skill YAML en `runtimes/<runtime>/skills/`.

---

*Documento generado según C1-C9.*
