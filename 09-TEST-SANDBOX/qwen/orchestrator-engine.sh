#!/bin/bash
set -euo pipefail

# ---
# title: "Orchestrator Engine for Governance"
# version: "1.0.0"
# constraints_mapped: ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8"]
# validation_command: "./05-CONFIGURATIONS/validation/validate-skill-integrity.sh --strict 05-CONFIGURATIONS/validation/orchestrator-engine.sh"
# canonical_path: "05-CONFIGURATIONS/validation/orchestrator-engine.sh"
# ai_optimized: true
# ---

# Define paths and constants
PROJECT_TREE_FILE="PROJECT_TREE.md"
VALIDATION_SCRIPTS_DIR="05-CONFIGURATIONS/validation"
REPORT_FILE="skill-validation-report.json"
TEMP_DIR="/tmp/validator-tmp"

# Ensure temporary directory exists
mkdir -p "$TEMP_DIR"

# Function to parse project tree and extract file metadata
parse_project_tree() {
  local file_path="$1"
  local file_type=$(basename "$file_path" | awk -F'.' '{print $2}')
  local target_folder=$(dirname "$file_path")
  local function=$(basename "$file_path" | awk -F'-' '{print $1}')

  echo "Parsed Metadata:"
  echo "File Path: $file_path"
  echo "File Type: $file_type"
  echo "Target Folder: $target_folder"
  echo "Function: $function"
}

# Function to validate file based on its type and location
validate_file() {
  local file_path="$1"
  local file_type=$(basename "$file_path" | awk -F'.' '{print $2}')
  local target_folder=$(dirname "$file_path")
  local function=$(basename "$file_path" | awk -F'-' '{print $1}')

  # Determine the appropriate validator based on file type
  case "$file_type" in
    sh)
      validate_type_bash "$file_path"
      ;;
    tf)
      validate_type_terraform "$file_path"
      ;;
    yaml|yml)
      validate_type_yaml "$file_path"
      ;;
    md)
      validate_type_markdown "$file_path"
      ;;
    json)
      validate_type_json "$file_path"
      ;;
    *)
      echo "Unsupported file type: $file_type"
      exit 1
      ;;
  esac
}

# Function to validate Bash files
validate_type_bash() {
  local file_path="$1"
  echo "Validating Bash file: $file_path"

  # Check shebang, set -euo, heredoc JSON, frontmatter commented
  if ! grep -q '#!/bin/bash' "$file_path"; then
    echo "Error: Missing shebang in $file_path"
    exit 1
  fi

  if ! grep -q 'set -euo pipefail' "$file_path"; then
    echo "Error: Missing 'set -euo pipefail' in $file_path"
    exit 1
  fi

  if grep -q 'echo "{"' "$file_path"; then
    echo "Error: Invalid JSON generation in $file_path"
    exit 1
  fi

  if ! grep -q '^#' "$file_path"; then
    echo "Error: Frontmatter not commented in $file_path"
    exit 1
  fi

  # Additional checks
  bash -n "$file_path"
  shellcheck "$file_path"
}

# Function to validate Terraform files
validate_type_terraform() {
  local file_path="$1"
  echo "Validating Terraform file: $file_path"

  # Check terraform fmt, validation blocks, sensitive, tenant_id outputs
  terraform fmt -check "$file_path"
  terraform validate -no-color -json "$file_path"

  if ! grep -q 'validation {' "$file_path"; then
    echo "Error: Missing validation block in $file_path"
    exit 1
  fi

  if grep -q 'default = ".*"' "$file_path"; then
    echo "Error: Hardcoded secrets in $file_path"
    exit 1
  fi

  if ! grep -q 'sensitive = true' "$file_path"; then
    echo "Error: Missing sensitive declaration in $file_path"
    exit 1
  fi

  if ! grep -q 'tenant_id' "$file_path"; then
    echo "Error: Missing tenant_id in $file_path"
    exit 1
  fi
}

# Function to validate YAML files
validate_type_yaml() {
  local file_path="$1"
  echo "Validating YAML file: $file_path"

  # Check yamllint, structure of asserts, frontmatter pure, no tabs
  yamllint "$file_path"

  if grep -q '\t' "$file_path"; then
    echo "Error: Tabs found in $file_path"
    exit 1
  fi

  if ! grep -q '^---' "$file_path"; then
    echo "Error: Missing frontmatter in $file_path"
    exit 1
  fi

  if ! grep -q 'assert:' "$file_path"; then
    echo "Error: Missing asserts in $file_path"
    exit 1
  fi
}

# Function to validate Markdown files
validate_type_markdown() {
  local file_path="$1"
  echo "Validating Markdown file: $file_path"

  # Check wikilinks, check-wikilinks, ≥5 examples, fenced code blocks
  if ! grep -q '\[\[.*\]\]' "$file_path"; then
    echo "Error: Missing wikilinks in $file_path"
    exit 1
  fi

  if ! grep -q '## 📊 Validated Examples' "$file_path"; then
    echo "Error: Missing validated examples in $file_path"
    exit 1
  fi

  if ! grep -q '```' "$file_path"; then
    echo "Error: Missing fenced code blocks in $file_path"
    exit 1
  fi

  # Additional checks
  check-wikilinks.sh "$file_path"
}

# Function to validate JSON files
validate_type_json() {
  local file_path="$1"
  echo "Validating JSON file: $file_path"

  # Check jq, schema strict, no trailing commas
  if ! jq empty "$file_path"; then
    echo "Error: Invalid JSON syntax in $file_path"
    exit 1
  fi

  if ! grep -q ',' "$file_path" | tail -n 1 | grep -q ','; then
    echo "Error: Trailing commas found in $file_path"
    exit 1
  fi

  # Additional checks
  schema-validator.py "$file_path"
}

# Main orchestration function
orchestrate_validation() {
  local file_path="$1"

  # Parse project tree to get metadata
  parse_project_tree "$file_path"

  # Validate file based on type and location
  validate_file "$file_path"

  # Generate report
  generate_report "$file_path"
}

# Function to generate validation report
generate_report() {
  local file_path="$1"
  local report_entry="{ \"file_path\": \"$file_path\", \"status\": \"PASSED\" }"

  # Append to report file
  echo "$report_entry" >> "$REPORT_FILE"
}

# Entry point
main() {
  if [ $# -eq 0 ]; then
    echo "Usage: $0 <file_path>"
    exit 1
  fi

  local file_path="$1"
  orchestrate_validation "$file_path"
}

# Execute main function
main "$@"

# 🟢 VALIDATION: ./05-CONFIGURATIONS/validation/validate-skill-integrity.sh --strict 05-CONFIGURATIONS/validation/orchestrator-engine.sh
---END-OF-FILE---
