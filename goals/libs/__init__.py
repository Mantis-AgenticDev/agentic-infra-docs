---
artifact_id: "goals-libs-init"
artifact_type: "library"
version: "2.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
canonical_path: "goals/libs/__init__.py"
tier: 2
immutable: false
language_lock: "python3"
prompt_hash: "sha256:libs-init-v2.0.0"
generated_at: "2026-05-22T06:15:00Z"
domain: "goals"
subdomain: "libs"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Librerías autocontenidas para segmentación de contexto e hidratación bajo demanda.
"""

from .registry_client import RegistryClient
from .context_segmenter import ContextSegmenter
from .prompt_builder import PromptBuilder
from .contract_parser import ContractParser
from .quota_parser import QuotaParser
from .handoff_package import HandoffPackage
from .log_reader import LogReader

__all__ = [
    "RegistryClient",
    "ContextSegmenter",
    "PromptBuilder",
    "ContractParser",
    "QuotaParser",
    "HandoffPackage",
    "LogReader",
]
"""
