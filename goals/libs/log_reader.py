---
artifact_id: "goals-libs-log-reader"
artifact_type: "library"
version: "2.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
canonical_path: "goals/libs/log_reader.py"
tier: 2
immutable: false
language_lock: "python3"
prompt_hash: "sha256:log-reader-v2.0.0"
generated_at: "2026-05-22T07:00:00Z"
domain: "goals"
subdomain: "libs"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Lee logs del dominio goals/ de forma estructurada, con rotación automática.
"""

from pathlib import Path
from typing import List, Dict

class LogReader:
    def __init__(self, log_dir: str = "goals/logs"):
        self.log_dir = Path(log_dir)

    def read_latest(self, log_name: str, lines: int = 50) -> List[str]:
        log_path = self.log_dir / log_name
        if not log_path.exists():
            return []
        with open(log_path, "r", encoding="utf-8") as f:
            all_lines = f.readlines()
        return all_lines[-lines:]

    def search(self, keyword: str, log_name: str = None) -> List[str]:
        results = []
        if log_name:
            files = [self.log_dir / log_name]
        else:
            files = self.log_dir.glob("*.log")
        for log_file in files:
            if not log_file.exists():
                continue
            with open(log_file, "r", encoding="utf-8") as f:
                for line in f:
                    if keyword.lower() in line.lower():
                        results.append(line.strip())
        return results
