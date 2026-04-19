#!/usr/bin/env python3
#---
#!/usr/bin/env python3
"""
schema-validator.py – JSON Schema validation for MANTIS AGENTIC artifacts
HARNESS NORMS v3.0-SELECTIVE compliant | Report-only mode (no auto-fixes)
Usage: python schema-validator.py --schema <path> --instance <path> [--json]
"""

import sys
import os
import glob
import json
import argparse
from jsonschema import validate, ValidationError  # ✅ Removed unused Draft202012Validator
# ✅ Removed unused: from pathlib import Path

# =============================================================================
# C8: Structured logging to stderr (ZERO print to stdout for logs)
# =============================================================================
def log(level: str, msg: str, **extra) -> None:
    """Log structured JSON to stderr for auditability (C8 compliance)."""
    entry = {
        "ts": __import__("datetime").datetime.utcnow().isoformat() + "Z",
        "level": level,
        "msg": msg,
        "script": "schema-validator.py",
        **extra
    }
    print(json.dumps(entry), file=sys.stderr)


# =============================================================================
# Schema Loading & Validation
# =============================================================================
def load_schema(schema_path: str) -> dict:
    """Load JSON Schema from file with basic error handling."""
    try:
        with open(schema_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except FileNotFoundError:
        log("ERROR", f"Schema file not found: {schema_path}")
        sys.exit(2)
    except json.JSONDecodeError as e:
        log("ERROR", f"Invalid JSON in schema: {schema_path} - {e}")
        sys.exit(2)


def validate_instance(instance_path: str, schema: dict) -> tuple[bool, list]:
    """
    Validate a JSON instance against a schema.
    Returns: (passed: bool, errors: list)
    """
    try:
        with open(instance_path, 'r', encoding='utf-8') as f:
            instance = json.load(f)
    except FileNotFoundError:
        return False, [f"Instance file not found: {instance_path}"]
    except json.JSONDecodeError as e:
        return False, [f"Invalid JSON in instance: {instance_path} - {e}"]
    
    errors = []
    try:
        validate(instance=instance, schema=schema)
        log("INFO", f"Validation passed: {instance_path}")
        return True, []
    except ValidationError as e:
        errors.append({
            "path": list(e.path),
            "message": e.message,
            "schema_path": list(e.schema_path)
        })
        log("WARNING", f"Validation failed: {instance_path} - {e.message}")
        return False, errors


# =============================================================================
# CLI Entry Point
# =============================================================================
def main():
    parser = argparse.ArgumentParser(
        description="Validate JSON artifacts against MANTIS schemas (C5 integrity)"
    )
    parser.add_argument("--schema", required=True, help="Path to JSON Schema file")
    parser.add_argument("--instance", required=True, help="Path to JSON instance to validate")
    parser.add_argument("--json", action="store_true", help="Output machine-readable JSON report")
    
    args = parser.parse_args()
    
    schema = load_schema(args.schema)
    passed, errors = validate_instance(args.instance, schema)
    
    # C8: Structured output
    report = {
        "validator": "schema-validator.py",
        "schema": args.schema,
        "instance": args.instance,
        "passed": passed,
        "errors": errors,
        "timestamp": __import__("datetime").datetime.utcnow().isoformat() + "Z"
    }
    
    if args.json:
        print(json.dumps(report))
    else:
        status = "✅ PASSED" if passed else "❌ FAILED"
        print(f"{status} | Errors: {len(errors)}")
        for err in errors:
            print(f"  • {' -> '.join(str(p) for p in err['path'])}: {err['message']}")
    
    # Exit code for CI/CD integration (but workflow has exit 0 → report-only)
    sys.exit(0 if passed else 1)


if __name__ == "__main__":
    main()
