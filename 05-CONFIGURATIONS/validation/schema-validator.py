#!/usr/bin/env python3
#---
# metadata_version: 1.0
# sdd_compliant: true
# ai_parser_compatible: true
# purpose: "Validador JSON Schema programático para outputs IA (CI/CD & pre-commit)"
# constraint: "C5: Determinismo, C1-C6 compliance, estructura tipada"
# dependencies: "jsonschema>=4.0.0"
# ---
import json
import sys
import os
import glob
from jsonschema import validate, ValidationError, Draft202012Validator
from pathlib import Path

def load_schema(schema_path):
    with open(schema_path, 'r') as f:
        return json.load(f)

def extract_json_blocks(md_file):
    blocks = []
    in_code = False
    current_json = ""
    with open(md_file, 'r', encoding='utf-8') as f:
        for line in f:
            if line.strip().startswith("```json"):
                in_code = True
                current_json = ""
            elif line.strip() == "```" and in_code:
                in_code = False
                try:
                    blocks.append(json.loads(current_json.strip()))
                except json.JSONDecodeError:
                    pass
            elif in_code:
                current_json += line
    return blocks

def validate_file(md_file, schema):
    blocks = extract_json_blocks(md_file)
    if not blocks:
        return True, 0, []
    
    errors = []
    for i, block in enumerate(blocks):
        try:
            validate(instance=block, schema=schema)
        except ValidationError as e:
            errors.append(f"[{md_file}] Ejemplo {i+1}: {e.message}")
    return len(errors) == 0, len(blocks), errors

def main():
    if len(sys.argv) < 3:
        print("Uso: schema-validator.py <schema.json> <archivo_o_directorio> [--strict]")
        sys.exit(2)

    schema_path = sys.argv[1]
    target = sys.argv[2]
    strict = "--strict" in sys.argv
    schema = load_schema(schema_path)

    files = [target] if os.path.isfile(target) else glob.glob(f"{target}/**/*.md", recursive=True)
    total_ok, total_fail = 0, 0
    all_errors = []

    for f in files:
        ok, count, errs = validate_file(f, schema)
        if ok:
            total_ok += 1
        else:
            total_fail += 1
            all_errors.extend(errs)

    report = {
        "validator": "schema-validator.py",
        "schema_used": schema_path,
        "files_validated": len(files),
        "passed": total_ok,
        "failed": total_fail,
        "errors": all_errors,
        "status": "passed" if (total_fail == 0 or not strict) else "failed"
    }

    with open("schema-validation-report.json", "w") as out:
        json.dump(report, out, indent=2, ensure_ascii=False)

    print(f"📦 Validación Schema: {total_ok}/{len(files)} OK | {total_fail} FALLOS")
    if strict and total_fail > 0:
        for e in all_errors: print(f"  ❌ {e}")
        sys.exit(1)
    sys.exit(0)

if __name__ == "__main__":
    main()
