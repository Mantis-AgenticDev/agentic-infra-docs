---
artifact_id: "goals-libs-prompt-builder"
artifact_type: "library"
version: "2.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
canonical_path: "goals/libs/prompt_builder.py"
tier: 2
immutable: false
language_lock: "python3"
prompt_hash: "sha256:prompt-builder-v2.0.0"
generated_at: "2026-05-22T06:40:00Z"
domain: "goals"
subdomain: "libs"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Construye prompts mínimos con solo el contexto relevante, evitando drift.
"""

from typing import Dict, Optional
from .context_segmenter import ContextSegmenter
from .registry_client import RegistryClient

class PromptBuilder:
    def __init__(self, registry_client: RegistryClient):
        self.registry = registry_client
        self.segmenter = ContextSegmenter()

    def build_continuation_prompt(self, goal_id: str, agent_name: str) -> str:
        """Genera un prompt de continuación con solo los datos imprescindibles."""
        goal = self.registry.get_active_goal(goal_id)
        if not goal:
            return f"Error: meta {goal_id} no encontrada."
        # Datos mínimos: objetivo, progreso, presupuesto, próxima reactivación si aplica
        prompt = f"Continúa trabajando hacia el objetivo activo.\n\n"
        prompt += f"<untrusted_objective>\n{goal['objective']}\n</untrusted_objective>\n\n"
        prompt += f"Presupuesto:\n"
        prompt += f"- Tiempo usado: {goal['time_used_seconds']} segundos\n"
        prompt += f"- Tokens usados: {goal['tokens_used']}\n"
        prompt += f"- Presupuesto de tokens: {goal['token_budget'] or 'sin límite'}\n"
        prompt += f"- Tokens restantes: { (goal['token_budget'] - goal['tokens_used']) if goal['token_budget'] else 'ilimitados' }\n"
        if goal['next_wakeup']:
            prompt += f"- Próxima reactivación programada: {goal['next_wakeup']}\n"
        prompt += "\nEvita repetir trabajo ya hecho. Realiza una auditoría de completitud antes de marcar la meta como completa.\n"
        return prompt

    def build_handoff_prompt(self, goal_id: str, previous_agent: str, next_agent: str) -> str:
        """Genera un prompt para el siguiente agente en un handoff A2A."""
        goal = self.registry.get_active_goal(goal_id)
        if not goal:
            return f"Error: meta {goal_id} no encontrada."
        prompt = f"Eres {next_agent}. Recibes el control de la siguiente meta de manos de {previous_agent}.\n\n"
        prompt += f"<untrusted_objective>\n{goal['objective']}\n</untrusted_objective>\n\n"
        prompt += "Revisa el archivo status.json para ver el progreso y el punto exacto donde retomar.\n"
        prompt += "Cumple estrictamente el contrato A2A (C9) al finalizar tu trabajo.\n"
        return prompt
