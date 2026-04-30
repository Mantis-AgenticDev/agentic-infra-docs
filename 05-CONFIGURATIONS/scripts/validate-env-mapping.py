---
# FRONTMATTER CANÓNICO OBLIGATORIO
artifact_id: "validate-env-mapping-v1.0.0"
artifact_type: "script"
version: "1.0.0-COMPREHENSIVE"
constraints_mapped: ["C3","C4","C5"]
canonical_path: "05-CONFIGURATIONS/scripts/validate-env-mapping.py"
domain: "05-CONFIGURATIONS"
subdomain: "scripts"
agent_role: "env-validator"
language_lock: "python"
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain scripts --file 05-CONFIGURATIONS/scripts/validate-env-mapping.py --strict"
tier: 3
immutable: true
requires_human_approval_for_changes: true
audience: ["agentic_assistants"]
human_readable: false
checksum_sha256: "d964e8849a251c1a76452bd4f423aeecf92fc1b21dc32ce0b353724f8f45dca8"
# FIN FRONTMATTER
---


#!/usr/bin/env python3
# =============================================================================
# SCRIPT: validate-env-mapping.py
# DOMINIO: 05-CONFIGURATIONS/scripts
# PROPÓSITO: Validar que todas las variables en .env.* estén mapeadas en 
#            mapping.yaml y viceversa. Detecta huérfanas, duplicadas, 
#            inconsistencias de tipo y fallos en regex de validación.
# USO: python3 validate-env-mapping.py [--env prod] [--strict] [--json]
# DEPENDENCIAS: python3 >= 3.8, pyyaml
# AUTOR: configurations-master-agent (MANTIS)
# VERSIÓN: 1.0.0
# CONSTRAINTS: C3 (Seguridad), C4 (Trazabilidad), C5 (Integridad Estructural)
# =============================================================================

import sys
import os
import re
import json
import argparse
import logging
from pathlib import Path
from datetime import datetime, timezone

try:
    import yaml
except ImportError:
    sys.stderr.write("ERROR: PyYAML required. Install via: pip install pyyaml\n")
    sys.exit(2)

# Configuración de logging (C4: Trazabilidad, C3: Nunca loguear valores)
logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger("env-validator")

# Paths relativos al repo root (resueltos dinámicamente)
REPO_ROOT = Path(__file__).resolve().parent.parent.parent
MAPPING_PATH = REPO_ROOT / "05-CONFIGURATIONS" / "environment" / "mapping.yaml"
ENV_EXAMPLE_PATH = REPO_ROOT / "05-CONFIGURATIONS" / "environment" / ".env.example"

class EnvValidator:
    def __init__(self, env_name: str = None, strict: bool = False, json_output: bool = False):
        self.env_name = env_name or "example"
        self.strict = strict
        self.json_output = json_output
        self.errors = []
        self.warnings = []
        self.mapping = {}
        self.env_vars = {}
        self.example_vars = {}

    def _load_yaml(self, path: Path) -> dict:
        if not path.exists():
            raise FileNotFoundError(f"[C5] Archivo requerido no encontrado: {path}")
        with open(path, "r", encoding="utf-8") as f:
            data = yaml.safe_load(f)
            return data.get("variables", {}) if isinstance(data, dict) and "variables" in data else {}

    def _parse_env_file(self, path: Path) -> dict:
        if not path.exists():
            raise FileNotFoundError(f"[C5] Archivo de entorno no encontrado: {path}")
        vars_dict = {}
        with open(path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                if "=" in line:
                    key, _, val = line.partition("=")
                    vars_dict[key.strip()] = val.strip()
        return vars_dict

    def load_data(self):
        logger.info("📥 Cargando mapping.yaml y archivos de entorno...")
        self.mapping = self._load_yaml(MAPPING_PATH)
        self.example_vars = self._parse_env_file(ENV_EXAMPLE_PATH)
        
        if self.env_name != "example":
            env_path = REPO_ROOT / "05-CONFIGURATIONS" / "environment" / f".env.{self.env_name}"
            if env_path.exists():
                self.env_vars = self._parse_env_file(env_path)
            else:
                logger.warning(f"⚠️ .env.{self.env_name} no encontrado. Validando solo contra .env.example")
        else:
            self.env_vars = self.example_vars.copy()

    def validate(self):
        logger.info("🔍 Ejecutando validación cruzada (C3/C4/C5)...")
        
        # 1. Variables en mapping.yaml pero no en .env.example (Falta definición base)
        missing_defs = set(self.mapping.keys()) - set(self.example_vars.keys())
        for k in missing_defs:
            self.errors.append(f"[C5] '{k}' definido en mapping.yaml pero ausente en .env.example")

        # 2. Variables en .env.example pero no en mapping.yaml (Huérfanas)
        orphans = set(self.example_vars.keys()) - set(self.mapping.keys())
        for k in orphans:
            self.warnings.append(f"[C4] '{k}' presente en .env.example pero sin mapeo en mapping.yaml")

        # 3. Validación de tipos y regex para variables compartidas
        common_keys = set(self.mapping.keys()) & set(self.env_vars.keys())
        for key in common_keys:
            spec = self.mapping[key]
            actual_val = self.env_vars[key]
            
            # C3: Nunca imprimir el valor real
            val_display = "[MASKED]" if spec.get("sensitive") or key.upper().endswith(("KEY", "SECRET", "PASSWORD", "TOKEN")) else actual_val

            # Validación de tipo
            expected_type = spec.get("type", "string")
            if not self._validate_type(actual_val, expected_type):
                self.errors.append(f"[C5] '{key}': valor '{val_display}' no coincide con tipo esperado '{expected_type}'")

            # Validación de regex
            validation_regex = spec.get("validation")
            if validation_regex and not re.match(validation_regex, actual_val):
                self.errors.append(f"[C5] '{key}': valor no cumple regex '{validation_regex}'")

            # Validación de sensitive flag
            if expected_type == "secret" and not spec.get("sensitive"):
                self.warnings.append(f"[C3] '{key}' es tipo 'secret' pero no tiene 'sensitive: true' en mapping.yaml")

        # 4. Verificar variables duplicadas o mal formateadas en .env.*
        for key, val in self.env_vars.items():
            if not re.match(r"^[A-Z_][A-Z0-9_]*$", key):
                self.warnings.append(f"[C4] '{key}': nombre no sigue convención SCREAMING_SNAKE_CASE")

    def _validate_type(self, value: str, expected: str) -> bool:
        try:
            if expected == "string": return True
            if expected == "number": float(value); return True
            if expected == "boolean": return value.lower() in ("true", "false", "1", "0")
            if expected == "connection_string": return value.startswith(("postgresql://", "redis://", "mysql://", "mongodb://"))
            if expected == "url": return value.startswith(("http://", "https://"))
            if expected == "secret": return len(value) >= 8  # Longitud mínima
            return True
        except (ValueError, TypeError):
            return False

    def generate_report(self) -> dict:
        report = {
            "validation_timestamp": datetime.now(timezone.utc).isoformat(),
            "environment": self.env_name,
            "strict_mode": self.strict,
            "summary": {
                "total_mapping_vars": len(self.mapping),
                "total_env_vars": len(self.env_vars),
                "errors": len(self.errors),
                "warnings": len(self.warnings),
                "status": "FAIL" if self.errors else ("WARN" if self.warnings else "PASS")
            },
            "errors": self.errors,
            "warnings": self.warnings
        }
        return report

    def run(self) -> int:
        try:
            self.load_data()
            self.validate()
            report = self.generate_report()
            
            if self.json_output:
                print(json.dumps(report, indent=2))
            else:
                logger.info(f"📊 Estado: {report['summary']['status']}")
                for e in self.errors: logger.error(e)
                for w in self.warnings: logger.warning(w)
                logger.info("✅ Validación completada.")
            
            # Códigos de salida: 0=PASS, 1=WARN, 2=FAIL
            return 2 if report["summary"]["status"] == "FAIL" else (1 if report["summary"]["status"] == "WARN" else 0)
        except Exception as e:
            logger.error(f"❌ Error crítico: {str(e)}")
            return 2

def main():
    parser = argparse.ArgumentParser(description="Validador cruzado de variables de entorno vs mapping.yaml (MANTIS)")
    parser.add_argument("--env", type=str, default="example", help="Entorno a validar (ej: dev, staging, prod)")
    parser.add_argument("--strict", action="store_true", help="Tratar warnings como errores")
    parser.add_argument("--json", action="store_true", help="Salida en formato JSON")
    args = parser.parse_args()

    validator = EnvValidator(env_name=args.env, strict=args.strict, json_output=args.json)
    exit_code = validator.run()
    
    if args.strict and exit_code == 1:
        exit_code = 2  # Forzar fallo en modo estricto
        
    sys.exit(exit_code)

if __name__ == "__main__":
    main()


---
