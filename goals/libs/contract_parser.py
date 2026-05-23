---
artifact_id: "goals-libs-contract-parser"
artifact_type: "library"
version: "2.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
canonical_path: "goals/libs/contract_parser.py"
tier: 2
immutable: false
language_lock: "python3"
prompt_hash: "sha256:contract-parser-v2.0.0"
generated_at: "2026-05-22T06:45:00Z"
domain: "goals"
subdomain: "libs"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Parsea y valida los archivos trace.json y status.json según los esquemas C9.
"""

import json
import jsonschema
from pathlib import Path
from typing import Dict, Optional

class ContractParser:
    def __init__(self, schemas_dir: str = "goals/schemas"):
        self.schemas_dir = Path(schemas_dir)
        self.status_schema = self._load_schema("status.schema.json")
        self.trace_schema = self._load_schema("trace.schema.json")

    def _load_schema(self, filename: str) -> Dict:
        schema_path = self.schemas_dir / filename
        if not schema_path.exists():
            raise FileNotFoundError(f"Esquema no encontrado: {schema_path}")
        with open(schema_path, "r", encoding="utf-8") as f:
            return json.load(f)

    def validate_status(self, status_path: str) -> bool:
        with open(status_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        jsonschema.validate(instance=data, schema=self.status_schema)
        return True

    def validate_trace(self, trace_path: str) -> bool:
        with open(trace_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        jsonschema.validate(instance=data, schema=self.trace_schema)
        return True

    def check_cross_consistency(self, trace_path: str, status_path: str) -> bool:
        with open(trace_path, "r") as f:
            trace = json.load(f)
        with open(status_path, "r") as f:
            status = json.load(f)
        if trace["trace_id"] != status["trace_id"]:
            raise ValueError("trace_id inconsistente entre trace.json y status.json")
        return True
